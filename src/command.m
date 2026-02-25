/* ============================================================================
 * command.m
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * objective-c functions for Metal command queue and command buffer creation
 * and management
 *
 * the command queue is the persistent channel through which work is submitted
 * to the GPU. it sits between the device (hardware) and the transient
 * command buffers that carry encoded work. one queue is sufficient for most
 * use cases -- queues are relatively heavyweight objects and are intended to
 * be created once and reused across many dispatches.
 *
 * the objects in the per-dispatch submission chain are:
 *
 *   queue (persistent) 
 *     -> commandBuffer (transient, one per dispatch)
 *       -> computeCommandEncoder (transient, encodes kernel + args)
 *         -> endEncoding
 *       -> commit
 *     -> waitUntilCompleted
 *
 * the queue always lives across calls
 * the commandbuffer and commandencoder are always transient across calls
 * buffers holding data may or may not be transient, this is entirely dependent
 * upon use cases and compute workflows
 * ========================================================================= */

#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

#include "ACFmetal.h"

/* ============================================================================
 * SECTION: queue creation
 * ========================================================================= */

/* ============================================================================
 * NOTES:
 * these functions create a MTLCommandQueue, and send it to the C
 * layer as a pointer with (__bridge_retained void*)
 * because casting is performed with (__bridge_retained void*)
 * they will need to be released from the C layer with objc_release_obj()
 * ========================================================================= */


// create a basic bog-standard MTLCommandQueue
void* objc_metal_create_queue(void* device) {
  // return NULL if device does not exist
  if (!device) {
    return NULL;
  }
  id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
  id<MTLCommandQueue> queue = [mtl_device newCommandQueue];
  // return NULL if queue creation fails
  if (!queue) {
    return NULL;
  }
  return (__bridge_retained void*)queue;
}

// create a MTLCommandQueue with a max buffer cap differing from the internal
// cap, which is typically 64
void* objc_metal_create_queue_with_max_buffers(void* device,
                                               uint32_t max_command_buffer_count) {
  // return NULL of the device does not exist
  if (!device) {
    return NULL;
  }
  id<MTLDevice> mtl_device = (__bridge id<MTLDevice>)device;
  id<MTLCommandQueue> queue = nil;
  
  // if provided zero as the max, return the typical system cap
  if (max_command_buffer_count == 0) {
    queue = [mtl_device newCommandQueue];
  } else {
    queue = [mtl_device newCommandQueueWithMaxCommandBufferCount:max_command_buffer_count];
  }
  
  // return NULL if creation fails
  if (!queue) {
    return NULL;
  }
  return (__bridge_retained void*)queue;
}

/* ============================================================================
 * SECTION: command buffer management
 * ========================================================================= */

/* ============================================================================
 * NOTES: 
 * command buffers are transient -- created from the queue, encoded into,
 * committed, waited on, and discarded. they are not meant to be held
 * across dispatches.
 *
 * these functions are provided here because the command buffer lifecycle
 * is tightly coupled to the queue, but the runner function is where they
 * will actually be called in sequence.
 * 
 * again, releasing with objc_release_obj() will be required...
 * 
 * MTLCommandBufferStatus enum values:
 *   0 == not enqueued
 *   1 == enqueued
 *   2 == committed
 *   3 == scheduled
 *   4 == completed
 *   5 == error
 *   non-standard:
 *   -1 == invalid buffer
 * ========================================================================= */

// create a new MTLCommandBuffer
// Metal auto-releases this internally, but we retain it here to protect it
// across scopes 
void* objc_metal_command_buffer_create(void* queue) {
  // return NULL if queue is invalid
  if (!queue) {
    return NULL;
  }
  id<MTLCommandQueue> mtl_queue = (__bridge id<MTLCommandQueue>)queue;
  id<MTLCommandBuffer> command_buffer = [mtl_queue commandBuffer];
  // return NULL if commandBuffer creation fails
  if (!command_buffer) {
    return NULL;
  }
  return (__bridge_retained void*)command_buffer;
}

// commit the command buffer for execution
// brief function placement guide:
// endEncoding -> commit buffer -> wait
void objc_metal_command_buffer_commit(void* command_buffer) {
  // return nothing if the command buffer is invalid
  if (!command_buffer) {
    return;
  }
  id<MTLCommandBuffer> mtl_buffer = (__bridge id<MTLCommandBuffer>)command_buffer;
  [mtl_buffer commit];
}

// block the calling thread until execution of the commands in the command
// buffer has completed, asynchronous execution would use 'addCompletedHandler'
// commit -> wait -> read results from output buffers
void objc_metal_command_buffer_wait(void* command_buffer) {
  // return nothing if the command buffer is invalid
  if (!command_buffer) {
    return;
  }
  id<MTLCommandBuffer> mtl_buffer = (__bridge id<MTLCommandBuffer>)command_buffer;
  [mtl_buffer waitUntilCompleted];
}

// check for command buffer status, check for 5 (error code), allows for
// detection of GPU side failures; C layer can pass those on to R as an error
// to prevent the need to check for garbage results
int objc_metal_command_buffer_status(void* command_buffer) {
  // return -1 if command buffer is invalid
  if (!command_buffer) {
    return -1;
  }
  id<MTLCommandBuffer> mtl_buffer = (__bridge id<MTLCommandBuffer>)command_buffer;
  return (int)mtl_buffer.status;
}

// return a string value of the error string from the command buffer
// returns NULL for invalid buffers AND absence of an error string
// returned string must be passed to Rf_error before buffer is released
const char* objc_metal_command_buffer_error_string(void* command_buffer) {
  // return NULL if the command buffer is invalid
  if (!command_buffer) {
    return NULL;
  }
  //undefine R's error macro to avoid conflicts with NSError .error property
#ifdef error
#undef error
#endif
  
  id<MTLCommandBuffer> mtl_buffer = (__bridge id<MTLCommandBuffer>)command_buffer;
  if (mtl_buffer.error) {
    return [[mtl_buffer.error localizedDescription] UTF8String];
  }
  return NULL;
}

/* ============================================================================
 * SECTION: synchronization utilities
 * ========================================================================= */

/* ============================================================================
 * NOTES:
 * queue level tools to ensure synchronization
 * ========================================================================= */

// a queue level flush, submit an empty queue and wait for it to return
// a bit overkill, but ensures a clean barrier without holding commandBuffer
// references
void objc_metal_queue_wait_idle(void* queue) {
  // if queue is invalid, return nothing
  if (!queue) {
    return;
  }
  @autoreleasepool {
    id<MTLCommandQueue> mtl_queue = (__bridge id<MTLCommandQueue>)queue;
    id<MTLCommandBuffer> sync_buffer = [mtl_queue commandBuffer];
    [sync_buffer commit];
    [sync_buffer waitUntilCompleted];
  }
}

/* ============================================================================
 * SECTION: creation and commitment
 * ========================================================================= */

// this may end up being specific to the simple runner function
// runner has deparsed queue and pipeline from the MetalContext type
// and managed the buffers, scalars, threads, and threadgroups
// this function constructs and commits a command buffer in a single shot
void* create_and_commit_commandbuffer(void* queue,
                                      void* pipeline,
                                      void* output_buffer,
                                      size_t num_threadgroups[3],
                                      size_t threads_per_threadgroup[3],
                                      void** arg_buffers,
                                      void** arg_scalars,
                                      size_t* arg_scalar_sizes,
                                      int* is_scalar,
                                      int num_args) {
  
  id<MTLCommandQueue> mtl_queue = (__bridge id<MTLCommandQueue>)queue;
  id<MTLComputePipelineState> mtl_pipeline = (__bridge id<MTLComputePipelineState>)pipeline;
  id<MTLBuffer> mtl_output = (__bridge id<MTLBuffer>)output_buffer;
  
  // Create command buffer
  id<MTLCommandBuffer> commandBuffer = [mtl_queue commandBuffer];
  if (!commandBuffer) return NULL;
  
  // Create compute encoder
  id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
  if (!encoder) return NULL;
  
  [encoder setComputePipelineState:mtl_pipeline];
  
  // Set output buffer at index 0
  [encoder setBuffer:mtl_output offset:0 atIndex:0];
  
  // Now set remaining arguments at indices starting from 1
  // Use is_scalar array to determine whether each arg is a buffer or scalar
  int buffer_idx = 0;
  int scalar_idx = 0;
  
  for (int i = 0; i < num_args; i++) {
    int metal_index = i + 1;  // Metal indices start at 1 (0 is output)
    
    if (is_scalar[i]) {
      // This is a scalar argument
      [encoder setBytes:arg_scalars[scalar_idx] 
      length:arg_scalar_sizes[scalar_idx] 
      atIndex:metal_index];
      scalar_idx++;
    } else {
      // This is a buffer argument
      id<MTLBuffer> arg_buffer = (__bridge id<MTLBuffer>)arg_buffers[buffer_idx];
      [encoder setBuffer:arg_buffer offset:0 atIndex:metal_index];
      buffer_idx++;
    }
  }
  
  // Dispatch
  MTLSize threadgroupSize = MTLSizeMake(threads_per_threadgroup[0],
                                        threads_per_threadgroup[1],
                                        threads_per_threadgroup[2]);
  MTLSize threadgroupCount = MTLSizeMake(num_threadgroups[0],
                                         num_threadgroups[1],
                                         num_threadgroups[2]);
  
  [encoder dispatchThreadgroups:threadgroupCount threadsPerThreadgroup:threadgroupSize];
  
  [encoder endEncoding];
  [commandBuffer commit];
  
  return (__bridge_retained void*)commandBuffer;
}
