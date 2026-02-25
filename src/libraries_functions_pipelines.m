/* ============================================================================
 * libraries_functions_pipelines.m
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * Objective C functions for libraries, metal functions, and pipelines
 * ========================================================================= */

// import is objC specific
#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

// include can be used for straight C
#include <string.h>
#include "ACFmetal.h"

// .error property of NSError conflicts with R's error thingy
#ifdef error
#undef error
#endif

// get a pointer for a library file that can be used later
void* metal_load_library(void* device,
                         const char* path,
                         char** error_msg) {
  if (!device) {
    if (error_msg) {
      *error_msg = strdup("device pointer is NULL");
    }
    return NULL;
  }
  if (!path) {
    if (error_msg) {
      *error_msg = strdup("library path is NULL");
    }
    return NULL;
  }

  id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;

  NSString* ns_path = [NSString stringWithUTF8String:path];
  NSURL* url = [NSURL fileURLWithPath:ns_path];

  NSError* ns_error = nil;
  id<MTLLibrary> library = [mtl_device newLibraryWithURL:url error:&ns_error];

  if (!library) {
    if (error_msg) {
      if (ns_error) {
        *error_msg = strdup([[ns_error localizedDescription] UTF8String]);
      } else {
        *error_msg = strdup("failed to load library: unknown error");
      }
    }
    return NULL;
  }

  return (__bridge_retained void*)library;
}

// get a pointer for a function inside a library that can be used later
void* metal_get_function_from_library(void* library,
                                      const char* name,
                                      char** error_msg) {
  if (!library) {
    if (error_msg) {
      *error_msg = strdup("library pointer is NULL");
    }
    return NULL;
  }
  if (!name) {
    if (error_msg) {
      *error_msg = strdup("function name is NULL");
    }
    return NULL;
  }

  id<MTLLibrary> mtl_library = (__bridge id<MTLLibrary>)library;

  NSString* ns_name = [NSString stringWithUTF8String:name];
  id<MTLFunction> function = [mtl_library newFunctionWithName:ns_name];

  if (!function) {
    if (error_msg) {
      /* Metal gives no NSError here -- construct a useful message from name */
      NSString* msg = [NSString stringWithFormat:
                       @"function '%s' not found in library -- "
                       @"check the kernel name matches the 'kernel void' "
                       @"declaration in the .metal source", name];
      *error_msg = strdup([msg UTF8String]);
    }
    return NULL;
  }

  return (__bridge_retained void*)function;
}

// create a compute pipeline from a device pointer and a function pointer
void* metal_create_compute_pipeline(void* device,
                                    void* function,
                                    char** error_msg) {
  if (!device) {
    if (error_msg) {
      *error_msg = strdup("device pointer is NULL");
    }
    return NULL;
  }
  if (!function) {
    if (error_msg) {
      *error_msg = strdup("function pointer is NULL");
    }
    return NULL;
  }

  id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
  id<MTLFunction> mtl_function = (__bridge id<MTLFunction>)function;

  NSError* ns_error = nil;
  id<MTLComputePipelineState> pipeline =
      [mtl_device newComputePipelineStateWithFunction:mtl_function
                                               error:&ns_error];

  if (!pipeline) {
    if (error_msg) {
      if (ns_error) {
        *error_msg = strdup([[ns_error localizedDescription] UTF8String]);
      } else {
        *error_msg = strdup("failed to create compute pipeline: unknown error");
      }
    }
    return NULL;
  }

  return (__bridge_retained void*)pipeline;
}
