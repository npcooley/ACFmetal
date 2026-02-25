/* ============================================================================
 * buffers.m
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * Objective C interface to Metal API buffer functions
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

/* ============================================================================
 * SECTION: general buffer tools
 * ========================================================================= */

// create a buffer 
void* metal_create_buffer(void* device,
                          size_t length,
                          int storage_mode) {
  if (!device) {
    return NULL;
  }
  id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
  
  // METAL_STORAGE defs in the ACFmetal.h header file
  MTLResourceOptions options;
  switch (storage_mode) {
  case METAL_STORAGE_SHARED:
    options = MTLResourceStorageModeShared;
    break;
  case METAL_STORAGE_MANAGED:
    options = MTLResourceStorageModeManaged;
    break;
  case METAL_STORAGE_PRIVATE:
    options = MTLResourceStorageModePrivate;
    break;
  default:
    options = MTLResourceStorageModeShared;
  }
  
  id<MTLBuffer> buffer = [mtl_device newBufferWithLength:length options:options];
  if (!buffer) {
    return NULL;
  }
  
  return (__bridge_retained void*)buffer;
}

// return a buffer's contents
void* metal_buffer_contents(void* buffer) {
  if (!buffer) {
    return NULL;
  }
  id<MTLBuffer> mtl_buffer = (__bridge id<MTLBuffer>)buffer;
  return [mtl_buffer contents];
}

// get buffer size
size_t metal_buffer_length(void* buffer) {
  if (!buffer) {
    return 0;
  }
  id<MTLBuffer> mtl_buffer = (__bridge id<MTLBuffer>)buffer;
  return [mtl_buffer length];
}


