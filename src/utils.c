/* ============================================================================
 * utils.c
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * utility C functions
 * ========================================================================= */

#include <Rinternals.h>
#include <string.h>
#include <stdlib.h>
#include "ACFmetal.h"

/* ============================================================================
 * SECTION: finalizers - generic or otherwise
 * ========================================================================= */

// generic finalizer with a generic release function
void objc_inclusive_finalizer(SEXP ptr) {
  void* obj = R_ExternalPtrAddr(ptr);
  if (obj) {
    objc_release_obj(obj);
    R_ClearExternalPtr(ptr);
  }
}

// finalizer for a device pointer
void metal_device_finalizer(SEXP device_exp) {
  void* ptr = R_ExternalPtrAddr(device_exp);
  if (ptr) {
    metal_release_device(ptr);
    R_ClearExternalPtr(device_exp);
  }
}

// finalizer for a context pointer
void metal_context_finalizer(SEXP ptr) {
  MetalContext* ctx = (MetalContext*)R_ExternalPtrAddr(ptr);
  if (ctx) {
    if (ctx->queue)  objc_release_obj(ctx->queue);
    if (ctx->device) objc_release_obj(ctx->device);
    free(ctx);
    R_ClearExternalPtr(ptr);
  }
}

// finalizer for a queue pointer
void metal_command_queue_finalizer(SEXP queue_exp) {
  void* ptr = R_ExternalPtrAddr(queue_exp);
  if (ptr) {
    metal_release_command_queue(ptr);
    R_ClearExternalPtr(queue_exp);
  }
}

// finalizer for a library pointer
void metal_library_finalizer(SEXP library_exp) {
  void* ptr = R_ExternalPtrAddr(library_exp);
  if (ptr) {
    metal_release_library(ptr);
    R_ClearExternalPtr(library_exp);
  }
}

// finalizer for a kernel pointer
void metal_pipeline_finalizer(SEXP pipeline_exp) {
  void* ptr = R_ExternalPtrAddr(pipeline_exp);
  if (ptr) {
    metal_release_pipeline(ptr);
    R_ClearExternalPtr(pipeline_exp);
  }
}

// finalizer for buffers
void metal_buffer_finalizer(SEXP buffer_exp) {
  void* ptr = R_ExternalPtrAddr(buffer_exp);
  if (ptr) {
    metal_release_buffer(ptr);
    R_ClearExternalPtr(buffer_exp);
  }
}

/* ============================================================================
 * SECTION: types and conversions
 * ========================================================================= */

// Parse type string to MetalType enum
MetalType metal_parse_type(const char* type_str) {
  if (strcmp(type_str, "half") == 0) {
    // return METAL_TYPE_HALF;
    Rf_warning("type '%s' is not implemented, defaulting to float", type_str);
    return METAL_TYPE_FLOAT;
  } else if (strcmp(type_str, "float") == 0) {
    return METAL_TYPE_FLOAT;
  } else if (strcmp(type_str, "double") == 0) {
    return METAL_TYPE_DOUBLE;
  } else if (strcmp(type_str, "char") == 0) {
    return METAL_TYPE_INT8;
  } else if (strcmp(type_str, "short") == 0) {
    return METAL_TYPE_INT16;
  } else if (strcmp(type_str, "int") == 0) {
    return METAL_TYPE_INT;
  } else if (strcmp(type_str, "long") == 0) {
    return METAL_TYPE_INT64;
  } else if (strcmp(type_str, "uchar") == 0) {
    return METAL_TYPE_UINT8;
  } else if (strcmp(type_str, "ushort") == 0) {
    return METAL_TYPE_UINT16;
  } else if (strcmp(type_str, "uint") == 0) {
    return METAL_TYPE_UINT;
  } else if (strcmp(type_str, "ulong") == 0) {
    return METAL_TYPE_UINT64;
  } else {
    // Unknown type - warn and default to float
    Rf_warning("Unknown type string '%s', defaulting to float", type_str);
    return METAL_TYPE_FLOAT;
  }
}

// Get element size in bytes for a MetalType
size_t metal_get_element_size(MetalType type) {
  switch (type) {
  // case METAL_TYPE_HALF:
  //   return 2;
  case METAL_TYPE_FLOAT:
    return sizeof(float);
  case METAL_TYPE_DOUBLE:
    return sizeof(double);
  case METAL_TYPE_INT8:
  case METAL_TYPE_UINT8:
    return 1;
  case METAL_TYPE_INT16:
  case METAL_TYPE_UINT16:
    return 2;
  case METAL_TYPE_INT:
  case METAL_TYPE_UINT:
    return 4;
  case METAL_TYPE_INT64:
  case METAL_TYPE_UINT64:
    return 8;
  default:
    return 0;
  }
}

// Get human-readable type name for error messages
const char* metal_type_name(MetalType type) {
  switch (type) {
  // case METAL_TYPE_HALF:    return "half"; // not currently supported
  case METAL_TYPE_FLOAT:   return "float";
  case METAL_TYPE_DOUBLE:  return "double";
  case METAL_TYPE_INT8:    return "int8";
  case METAL_TYPE_INT16:   return "int16";
  case METAL_TYPE_INT:     return "int32";
  case METAL_TYPE_INT64:   return "int64";
  case METAL_TYPE_UINT8:   return "uint8";
  case METAL_TYPE_UINT16:  return "uint16";
  case METAL_TYPE_UINT:    return "uint32";
  case METAL_TYPE_UINT64:  return "uint64";
  default:                 return "unknown";
  }
}

