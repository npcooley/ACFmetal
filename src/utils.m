/* ============================================================================
 * utils.m
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * generic objC functions
 * 
 * R does not have tools to interface directly with objC, so if i need to dive
 * into objC tools inside a C function, particularly if it has an R entry point
 * those accessors *should* be here
 * ========================================================================= */

// import is objC specific, include can be used for straight C
#import <Metal/Metal.h>
#import <Foundation/Foundation.h>

#include "ACFmetal.h"

/* ============================================================================
 * SECTION: generic retain / release functions - must be matched!
 * ========================================================================= */

// release an object
void objc_release_obj(void* obj) {
  if (obj) {
    CFRelease(obj);
  }
}

// retain an object
void objc_retain_obj(void* obj) {
  if (obj) {
    CFRetain(obj);
  }
}

/* ============================================================================
 * SECTION: release functions - for internal use in finalizer calls
 * ========================================================================= */

// release a buffer
void metal_release_buffer(void* buffer) {
    if (buffer) {
        CFRelease(buffer);
    }
}

// release a command buffer
void metal_release_command_buffer(void* command_buffer) {
    if (!command_buffer) {
      return;
    }
    CFRelease(command_buffer);
}

// release a command queue
void metal_release_command_queue(void* queue) {
    if (queue) {
        CFRelease(queue);
    }
}

// release a device
void metal_release_device(void* device) {
    if (device) {
        CFRelease(device);
    }
}

// release a library
void metal_release_library(void* library) {
    if (library) {
        CFRelease(library);
    }
}

// release a function
void metal_release_function(void* function) {
    if (function) {
        CFRelease(function);
    }
}

// release a pipeline
void metal_release_pipeline(void* pipeline) {
    if (pipeline) {
        CFRelease(pipeline);
    }
}
