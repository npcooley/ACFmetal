/* ============================================================================
 * ACFmetal.h
 * 
 * public interface for C functions
 * author: nicholas cooley
 * maintainer: nicholas cooley
 * 
 * naming convention
 * R functions are never pre-ended with `r_`
 * C functions will be pre-pended with `c_` when they may conflict with
 * R namespace objects
 * ObjC functions will be pre-pended with `objc` when they may conflict with
 * a C function name
 * i.e. if it makes sense that a C and an ObjC function share a name, but there's
 * no equivalent R function that shares that name we'll name them
 * `function` and `objc_function`
 * if there *is* an equivalent R function the naming hierarchy will be
 * `function` for the R function, `c_function` for the C function, and
 * `objc_function` for the objc function
 * ========================================================================= */

// header guard ... prevents attempts to duplicate symbols by the compiler
#ifndef ACFMETAL_H
#define ACFMETAL_H

#include <Rinternals.h>
#include <R_ext/Visibility.h>
// required for 'uint64_t' etc...
#include <stdint.h>
#include <stddef.h>

/* ============================================================================
 * types, constants, and their helpers
 * ========================================================================= */

// type definitions, these can appear in various 
typedef enum {
  // METAL_TYPE_HALF = 0,      // "half" - 16-bit float
  METAL_TYPE_FLOAT = 1,     // "single" - 32-bit float
  METAL_TYPE_DOUBLE = 2,    // "double" - 64-bit float
  METAL_TYPE_INT8 = 3,      // "byte" - 8-bit signed int
  METAL_TYPE_INT16 = 4,     // "short" - 16-bit signed int
  METAL_TYPE_INT = 5,       // "integer" - 32-bit signed int
  METAL_TYPE_INT64 = 6,     // "long" - 64-bit signed int
  METAL_TYPE_UINT8 = 7,     // "ubyte" - 8-bit unsigned int
  METAL_TYPE_UINT16 = 8,    // "ushort" - 16-bit unsigned int
  METAL_TYPE_UINT = 9,      // "unsigned" - 32-bit unsigned int
  METAL_TYPE_UINT64 = 10    // "ulong" - 64-bit unsigned int
} MetalType;

// metal storage modes
typedef enum {
  METAL_STORAGE_SHARED = 0,   // unified CPU/GPU memory
  METAL_STORAGE_MANAGED = 1,  // managed memory (synced)
  METAL_STORAGE_PRIVATE = 2   // GPU-only memory
} MetalStorageMode;

// container for contexts, just pointers for the queue and the device, these
// get passed around together
typedef struct {
  void* device;
  void* queue;
} MetalContext;

// container for something else, I've forgotten already
typedef struct {
  void* pipeline;
  void* device;
} MetalKernel;

typedef struct {
  void* device;
  void* queue;
  void* pipeline;
} SimpleContext;

/* ============================================================================
 * buffers.c
 * ========================================================================= */

void metal_convert_r_numeric_to_buffer(const double* r_data,
                                       void* metal_buffer,
                                       size_t length,
                                       MetalType type);
void metal_convert_r_int_to_buffer(const int* r_data,
                                   void* metal_buffer,
                                   size_t length,
                                   MetalType type);
void metal_convert_buffer_to_r(const void* metal_buffer,
                               double* r_data,
                               size_t length,
                               MetalType type);

/* ============================================================================
 * buffers.m
 * ========================================================================= */

void* metal_create_buffer(void* device,
                          size_t length,
                          int storage_mode);
void* metal_buffer_contents(void* buffer);
size_t metal_buffer_length(void* buffer);

/* ============================================================================
 * command.c
 * ========================================================================= */

SEXP c_metal_make_queue(void* queue);
attribute_visible SEXP c_metal_make_context(SEXP device_ptr);
void* c_metal_get_queue(SEXP queue_ptr);
void metal_wait_for_completion(void* command_buffer);

/* ============================================================================
 * command.m
 * ========================================================================= */

void* objc_metal_create_queue(void* device);
void* objc_metal_create_queue_with_max_buffers(void* device,
                                               uint32_t max_command_buffer_count);
void* objc_metal_command_buffer_create(void* queue);
void objc_metal_command_buffer_commit(void* command_buffer);
void objc_metal_command_buffer_wait(void* command_buffer);
int objc_metal_command_buffer_status(void* command_buffer);
const char* objc_metal_command_buffer_error_string(void* command_buffer);
void objc_metal_queue_wait_idle(void* queue);
// driver of the simple runner C function
void* create_and_commit_commandbuffer(void* queue,
                                      void* pipeline,
                                      void* output_buffer,
                                      size_t num_threadgroups[3],
                                      size_t threads_per_threadgroup[3],
                                      void** arg_buffers,
                                      void** arg_scalars,
                                      size_t* arg_scalar_sizes,
                                      int* is_scalar,
                                      int num_args);


/* ============================================================================
 * devices.c
 * ========================================================================= */

attribute_visible SEXP c_metal_get_all_devices(void);
attribute_visible SEXP c_metal_devices_default(void);
attribute_visible SEXP c_metal_device_information(SEXP device_ptr);

/* ============================================================================
 * devices.m
 * ========================================================================= */

// general device interrogation
void* objc_metal_devices_default(void);
void** objc_metal_get_all_devices(size_t* count);

// general device information
const char* metal_device_name(void* device);
uint64_t metal_device_registry_id(void* device);
int metal_device_has_unified_memory(void* device);
int metal_device_is_low_power(void* device);
int metal_device_is_headless(void* device);
int metal_device_is_removable(void* device);

// memory limits
uint64_t metal_device_recommended_max_working_set_size(void* device);
uint64_t metal_device_max_buffer_length(void* device);
uint64_t metal_device_current_allocated_size(void* device);

// threading limits
void metal_device_max_threads_per_threadgroup(void* device,
                                              size_t* width,
                                              size_t* height,
                                              size_t* depth);
size_t metal_device_max_threadgroup_memory_length(void* device);

// performance monitoring
void metal_device_sample_timestamps(void* device,
                                    uint64_t* cpu_timestamp,
                                    uint64_t* gpu_timestamp);
int metal_device_supports_counter_sampling(void* device,
                                           int sampling_point);

// physical slot information
int metal_device_location(void* device);
uint64_t metal_device_location_number(void* device);
uint64_t metal_device_peer_group_id(void* device);
uint32_t metal_device_peer_index(void* device);
uint32_t metal_device_peer_count(void* device);

/* ============================================================================
 * libraries_functions_pipelines.c
 * ========================================================================= */

attribute_visible SEXP metal_get_library_pointer(SEXP filepath,
                                                 SEXP device_ptr);
attribute_visible SEXP metal_get_function_pointers(SEXP lib_ptr,
                                                   SEXP fun_names);

/* ============================================================================
 * libraries_functions_pipelines.m
 * ========================================================================= */

void* metal_load_library(void* device,
                         const char* path,
                         char** error_msg);
void* metal_get_function_from_library(void* library,
                                      const char* name,
                                      char** error_msg);
void* metal_create_compute_pipeline(void* device,
                                    void* function,
                                    char** error_msg);

/* ============================================================================
 * runners.c
 * ========================================================================= */

attribute_visible SEXP metal_simple_runner(SEXP args);

/* ============================================================================
 * utils.c
 * ========================================================================= */

void objc_inclusive_finalizer(SEXP ptr);
void metal_device_finalizer(SEXP device_exp);
void metal_context_finalizer(SEXP context_exp);
void metal_command_queue_finalizer(SEXP queue_exp);
void metal_library_finalizer(SEXP library_exp);
void metal_pipeline_finalizer(SEXP pipeline_exp);
void metal_buffer_finalizer(SEXP buffer_exp);
MetalType metal_parse_type(const char* type_str);
size_t metal_get_element_size(MetalType type);
const char* metal_type_name(MetalType type);

/* ============================================================================
 * utils.m
 * ========================================================================= */

void objc_release_obj(void* obj);
void objc_retain_obj(void* obj);
void metal_release_buffer(void* buffer);
void metal_release_command_buffer(void* command_buffer);
void metal_release_command_queue(void* command_queue);
void metal_release_device(void* device);
void metal_release_library(void* library);
void metal_release_function(void* function);
void metal_release_pipeline(void* pipeline);

// end header guard
#endif
