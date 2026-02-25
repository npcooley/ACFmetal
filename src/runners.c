/* ============================================================================
 * runners.c
 * 
 * author: nicholas cooley
 * maintainer: nicholas cooley
 * ========================================================================= */

#include <stdlib.h>
#include <string.h>
#include "ACFmetal.h"

/* ============================================================================
 * .External() includes the function name in the first position of the singly
 * linked list / pairlist (C-structure / R-structure), while .Call does not?
 * 
 * CAR(args) = Contents of Address Register = the current element
 * initially the head of the list
 * CDR(args) = Contents of Decrement Register = the rest of the list
 * everything not in the first train car
 * 
 * arg order
 * 0 == fun name
 * 1 == 
 * ========================================================================= */

SEXP metal_simple_runner(SEXP args) {
  // Called via .External, so args is a pairlist
  // Structure: function_name, kernel, arg_defs, arg1, arg2, ...
  
  // skip the first position off the rip -- this is just the function name
  // and skipping is not necessary with .Call() --maybe?--
  args = CDR(args);
  
  // first argument: MetalContext (device + queue)
  SEXP context_ctr = CAR(args);
  args = CDR(args);
  // get kernel resources
  // extract device, queue, and pipeline from your structs
  MetalContext* ctx = (MetalContext*)R_ExternalPtrAddr(context_ctr);
  if (!ctx) {
    Rf_error("invalid context pointer");
  }
  void* device = ctx->device;
  void* queue = ctx->queue;
  // void* pipeline = kernel->pipeline;
  
  
  SEXP pipeline_precursor = CAR(args);
  args = CDR(args);
  
  void* function_ptr = R_ExternalPtrAddr(pipeline_precursor);
  if (!function_ptr) {
    Rf_error("invalid function pointer");
  }
  
  char* error_msg = NULL;
  void* pipeline = metal_create_compute_pipeline(device,
                                                 function_ptr,
                                                 &error_msg);
  if (!pipeline) {
    if (error_msg) {
      char* msg = error_msg;
      strncpy(msg, error_msg, sizeof(msg) - 1);
      free(error_msg);
      Rf_error("failed to create pipeline: %s", msg);
    }
    Rf_error("failed to create pipeline: unknown error");
  }
    
  // assign the pass types -- must always be this position
  SEXP obj_type_key = CAR(args);
  args = CDR(args);
  
  // the current argument is now the template vector
  // we need it's length, but anything else right now
  SEXP output_template = CAR(args);
  
  if (TYPEOF(output_template) != REALSXP && TYPEOF(output_template) != INTSXP) {
    Rf_error("First argument must be output vector (numeric or integer)");
  }
  
  int output_length = LENGTH(output_template);
  
  // First type in arg_types must be a buffer type, not special keyword
  const char* first_type = CHAR(STRING_ELT(obj_type_key, 0));
  if (strcmp(first_type, "WORKDIMS") == 0 || strcmp(first_type, "THREADGROUPS") == 0) {
    Rf_error("First argument must be output buffer, not %s", first_type);
  }
  
  // get buffer size and type
  MetalType output_type = metal_parse_type(first_type);
  // size_t output_element_size = metal_get_element_size(output_type);
  // Create GPU output buffer
  // size_t output_size = output_length * output_element_size;
  // get device object -- these don't need to be defined yet ...
  // SEXP context_exp = getAttrib(kernel_exp, metalContextSymbol);
  // void* device = metal_get_context(context_exp);
  
  // i don't need this here?
  // void* output_buffer = metal_create_buffer(device, output_size, METAL_STORAGE_SHARED);
  
  // now we need to scroll through the rest of the args and keywords simultaneously
  int total_args = length(obj_type_key);
  int has_workdims = 0;
  int has_threadgroups = 0;
  int workdims_index = -1;
  int threadgroups_index = -1;
  int buffer_count = 1; // output buffer
  int scalar_count = 0;
  
  // First pass: count buffers vs scalars, find metadata args
  SEXP args_temp = args;
  for (int i = 0; i < total_args; i++) {
    const char* type_str = CHAR(STRING_ELT(obj_type_key, i));
    
    if (strcmp(type_str, "WORKDIMS") == 0) {
      has_workdims = 1;
      workdims_index = i;
      args_temp = CDR(args_temp);
    } else if (strcmp(type_str, "THREADGROUPS") == 0) {
      has_threadgroups = 1;
      threadgroups_index = i;
      args_temp = CDR(args_temp);
    } else {
      // Check if this is a buffer or scalar based on length
      SEXP arg = CAR(args_temp);
      if (LENGTH(arg) == 1) {
        scalar_count++;
      } else {
        buffer_count++;
      }
      args_temp = CDR(args_temp);
    }
  }
  
  // work dims set to 0, 0, 0 ... if not present in his catch, set to the length
  // of the dummy vector
  size_t work_dims[3] = {0, 0, 0};
  
  if (has_workdims) {
    // Navigate to WORKDIMS argument
    SEXP args_temp = args;
    for (int i = 0; i < workdims_index; i++) {
      args_temp = CDR(args_temp);
    }
    SEXP workdims_arg = CAR(args_temp);
    
    // Validate
    if (TYPEOF(workdims_arg) != REALSXP && TYPEOF(workdims_arg) != INTSXP) {
      Rf_error("WORKDIMS argument must be numeric or integer vector");
    }
    if (LENGTH(workdims_arg) != 3) {
      Rf_error("WORKDIMS must be a vector of length 3");
    }
    
    // Extract values
    if (TYPEOF(workdims_arg) == REALSXP) {
      work_dims[0] = (size_t)REAL(workdims_arg)[0];
      work_dims[1] = (size_t)REAL(workdims_arg)[1];
      work_dims[2] = (size_t)REAL(workdims_arg)[2];
    } else {
      work_dims[0] = (size_t)INTEGER(workdims_arg)[0];
      work_dims[1] = (size_t)INTEGER(workdims_arg)[1];
      work_dims[2] = (size_t)INTEGER(workdims_arg)[2];
    }
  } else {
    // Infer from output length (1D)
    work_dims[0] = output_length;
    work_dims[1] = 1;
    work_dims[2] = 1;
  }
  
  // threadgroup default might eventually need to be set to a device specific 
  // default, but for now this should be ok?
  size_t threadgroup_size[3] = {256, 1, 1};
  
  if (has_threadgroups) {
    // Navigate to THREADGROUPS argument
    SEXP args_temp = args;
    for (int i = 0; i < threadgroups_index; i++) {
      args_temp = CDR(args_temp);
    }
    SEXP threadgroups_arg = CAR(args_temp);
    
    // Validate
    if (TYPEOF(threadgroups_arg) != REALSXP && TYPEOF(threadgroups_arg) != INTSXP) {
      Rf_error("THREADGROUPS argument must be numeric or integer vector");
    }
    if (LENGTH(threadgroups_arg) != 3) {
      Rf_error("THREADGROUPS must be a vector of length 3");
    }
    
    // Extract values
    if (TYPEOF(threadgroups_arg) == REALSXP) {
      threadgroup_size[0] = (size_t)REAL(threadgroups_arg)[0];
      threadgroup_size[1] = (size_t)REAL(threadgroups_arg)[1];
      threadgroup_size[2] = (size_t)REAL(threadgroups_arg)[2];
    } else {
      threadgroup_size[0] = (size_t)INTEGER(threadgroups_arg)[0];
      threadgroup_size[1] = (size_t)INTEGER(threadgroups_arg)[1];
      threadgroup_size[2] = (size_t)INTEGER(threadgroups_arg)[2];
    }
  } else {
    // Smart defaults based on dimensionality
    if (work_dims[2] > 1) {
      // 3D kernel
      threadgroup_size[0] = 8;
      threadgroup_size[1] = 8;
      threadgroup_size[2] = 4;
    } else if (work_dims[1] > 1) {
      // 2D kernel
      threadgroup_size[0] = 16;
      threadgroup_size[1] = 16;
      threadgroup_size[2] = 1;
    }
    // else: already set to {256, 1, 1} for 1D
  }
  
  // this may need to become more complex in the future, but for now it stays
  // simple
  size_t num_threadgroups[3];
  num_threadgroups[0] = (work_dims[0] + threadgroup_size[0] - 1) / threadgroup_size[0];
  num_threadgroups[1] = (work_dims[1] + threadgroup_size[1] - 1) / threadgroup_size[1];
  num_threadgroups[2] = (work_dims[2] + threadgroup_size[2] - 1) / threadgroup_size[2];
  
  // Allocate arrays for buffers and scalars
  void** input_buffers = (void**)malloc(buffer_count * sizeof(void*));
  void** scalar_values = (void**)malloc(scalar_count * sizeof(void*));
  size_t* scalar_sizes = (size_t*)malloc(scalar_count * sizeof(size_t));
  int* is_scalar = (int*)malloc((buffer_count - 1 + scalar_count) * sizeof(int));  // Track type for each arg after output
  
  if (!input_buffers || !scalar_values || !scalar_sizes || !is_scalar) {
    if (input_buffers) free(input_buffers);
    if (scalar_values) free(scalar_values);
    if (scalar_sizes) free(scalar_sizes);
    if (is_scalar) free(is_scalar);
    Rf_error("Failed to allocate argument arrays");
  }
  
  
  // Second pass: process arguments into buffers and scalars
  args_temp = args;
  int buffer_idx = 0;
  int scalar_idx = 0;
  int arg_position = 0;  // Position in is_scalar array (excludes output)
  
  for (int i = 0; i < total_args; i++) {
    const char* type_str = CHAR(STRING_ELT(obj_type_key, i));
    
    // Skip special keywords
    if (strcmp(type_str, "WORKDIMS") == 0 || 
        strcmp(type_str, "THREADGROUPS") == 0) {
      args_temp = CDR(args_temp);
      continue;
    }
    
    SEXP arg = CAR(args_temp);
    MetalType arg_type = metal_parse_type(type_str);
    size_t arg_element_size = metal_get_element_size(arg_type);
    
    // Validate argument type
    if (TYPEOF(arg) != REALSXP && TYPEOF(arg) != INTSXP) {
      // Cleanup and error
      for (int j = 0; j < buffer_idx; j++) {
        metal_release_buffer(input_buffers[j]);
      }
      for (int j = 0; j < scalar_idx; j++) {
        free(scalar_values[j]);
      }
      free(input_buffers);
      free(scalar_values);
      free(scalar_sizes);
      free(is_scalar);
      Rf_error("Argument %d must be numeric or integer vector", i + 1);
    }
    
    size_t arg_length = LENGTH(arg);
    
    // Determine if this is a scalar (length == 1) or buffer (length > 1)
    if (arg_length == 1) {
      // Handle as scalar
      // Only track non-output args in is_scalar
      if (i > 0) {
        is_scalar[arg_position++] = 1;
      }
      
      scalar_sizes[scalar_idx] = arg_element_size;
      scalar_values[scalar_idx] = malloc(arg_element_size);
      
      if (!scalar_values[scalar_idx]) {
        for (int j = 0; j < buffer_idx; j++) {
          metal_release_buffer(input_buffers[j]);
        }
        for (int j = 0; j < scalar_idx; j++) {
          free(scalar_values[j]);
        }
        free(input_buffers);
        free(scalar_values);
        free(scalar_sizes);
        free(is_scalar);
        Rf_error("Failed to allocate scalar value for argument %d", i + 1);
      }
      
      // Convert R value to Metal type
      if (TYPEOF(arg) == REALSXP) {
        metal_convert_r_numeric_to_buffer(REAL(arg), scalar_values[scalar_idx], 1, arg_type);
      } else if (TYPEOF(arg) == INTSXP) {
        metal_convert_r_int_to_buffer(INTEGER(arg), scalar_values[scalar_idx], 1, arg_type);
      }
      
      scalar_idx++;
    } else {
      // Handle as buffer
      // Only track non-output args in is_scalar
      if (i > 0) {
        is_scalar[arg_position++] = 0;
      }
      
      size_t arg_size = arg_length * arg_element_size;
      
      input_buffers[buffer_idx] = metal_create_buffer(device, arg_size, 
                                                      METAL_STORAGE_SHARED);
      if (!input_buffers[buffer_idx]) {
        for (int j = 0; j < buffer_idx; j++) {
          metal_release_buffer(input_buffers[j]);
        }
        for (int j = 0; j < scalar_idx; j++) {
          free(scalar_values[j]);
        }
        free(input_buffers);
        free(scalar_values);
        free(scalar_sizes);
        free(is_scalar);
        Rf_error("Failed to create buffer for argument %d", i + 1);
      }
      
      // Upload data
      void* buffer_ptr = metal_buffer_contents(input_buffers[buffer_idx]);
      
      if (TYPEOF(arg) == REALSXP) {
        metal_convert_r_numeric_to_buffer(REAL(arg), buffer_ptr, arg_length, arg_type);
      } else if (TYPEOF(arg) == INTSXP) {
        metal_convert_r_int_to_buffer(INTEGER(arg), buffer_ptr, arg_length, arg_type);
      }
      
      buffer_idx++;
    }
    
    args_temp = CDR(args_temp);
  }
  
  /* ==========================================================================
   * 1 == Create command buffer
   * 2 == Encode commands (attach buffers, set arguments)
   * 3 == Commit command buffer
   * 4 == Wait for completion
   * 5 == Read results from buffers
   * 6 == Release command buffer    ← AFTER reading results
   * 7 == Release buffers
   * ======================================================================= */
  
  // total_args_for_kernel: all non-output buffers and scalars
  int total_args_for_kernel = (buffer_count - 1) + scalar_count;
  
  void* command_buffer = create_and_commit_commandbuffer(queue,
                                                         pipeline,
                                                         input_buffers[0],  // Output buffer
                                                         num_threadgroups,
                                                         threadgroup_size,
                                                         input_buffers + 1,  // Input buffers (skip output)
                                                         scalar_values,      // Scalar values
                                                         scalar_sizes,       // Scalar sizes
                                                         is_scalar,          // Type indicator for each arg
                                                         total_args_for_kernel);
  
  if (!command_buffer) {
    // We're here because metal_execute_kernel_v2() FAILED
    for (int i = 0; i < buffer_count; i++) {
      metal_release_buffer(input_buffers[i]);
    }
    for (int i = 0; i < scalar_count; i++) {
      free(scalar_values[i]);
    }
    // release the compute pipeline
    metal_release_pipeline(pipeline);
    // free other objects and error
    free(input_buffers);
    free(scalar_values);
    free(scalar_sizes);
    free(is_scalar);
    Rf_error("Failed to execute kernel");
  }
  
  // wait for completion
  metal_wait_for_completion(command_buffer);
  
  // release the compute pipeline
  metal_release_pipeline(pipeline);
  
  // Download from first buffer (output)
  SEXP result = PROTECT(allocVector(REALSXP, output_length));
  void* output_ptr = metal_buffer_contents(input_buffers[0]);
  metal_convert_buffer_to_r(output_ptr, REAL(result), output_length, output_type);
  
  // release command buffer
  metal_release_command_buffer(command_buffer);
  
  // Cleanup buffers and scalars
  for (int i = 0; i < buffer_count; i++) {
    metal_release_buffer(input_buffers[i]);
  }
  for (int i = 0; i < scalar_count; i++) {
    free(scalar_values[i]);
  }
  free(input_buffers);
  free(scalar_values);
  free(scalar_sizes);
  free(is_scalar);
  
  UNPROTECT(1);
  return result;
  
}
