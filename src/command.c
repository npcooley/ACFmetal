/* ============================================================================
 * command.c
 * author: nicholas cooley
 * maintainer: nicholas cooley
 *
 * C layer for Metal command queue creation and management.
 *
 * this file contains the R-callable entry points for queue operations and
 * the R object wrappers (make/get/finalizer) for queue and command buffer
 * external pointers.
 *
 * the queue is bundled with the device into a context object at the R level
 * so users don't need to manage two separate pointers. the context is what
 * gets passed around in R code -- the queue and device are retrieved from
 * it internally as needed.
 * ========================================================================= */

#include <Rinternals.h>
#include <stdlib.h>
#include <TargetConditionals.h>
#include "ACFmetal.h"

/* ============================================================================
 * SECTION: queue creation
 * ========================================================================= */

/* ============================================================================
 * NOTES:
 * ========================================================================= */

SEXP c_metal_make_queue(void* queue) {
  if (!queue) {
    Rf_error("cannot wrap NULL queue pointer");
  }
  SEXP queue_ptr = PROTECT(R_MakeExternalPtr(queue, R_NilValue, R_NilValue));
  R_RegisterCFinalizer(queue_ptr, objc_inclusive_finalizer);
  UNPROTECT(1);
  return queue_ptr;
}

void* c_metal_get_queue(SEXP queue_ptr) {
  void* queue = R_ExternalPtrAddr(queue_ptr);
  if (!queue) {
    Rf_error("invalid or released queue pointer");
  }
  return queue;
}

/* ============================================================================
 * SECTION: context creation
 * ========================================================================= */

SEXP c_metal_make_context(SEXP device_ptr) {
  void* device = R_ExternalPtrAddr(device_ptr);
  if (!device) {
    Rf_error("invalid device pointer");
  }
  
  /* allocate the context struct on the heap
   * the struct itself is plain C memory -- malloc/free
   * the two pointers inside it are ObjC objects -- CFRetain/CFRelease */
  MetalContext* ctx = (MetalContext*)malloc(sizeof(MetalContext));
  if (!ctx) {
    Rf_error("failed to allocate MetalContext");
  }
  
  /* retain the device independently so the context owns its own reference
   * this means the caller's device external pointer can be GC'd without
   * affecting the context -- both now hold a retain on the same device */
  objc_retain_obj(device);
  ctx->device = device;
  
  /* create the queue on the retained device */
  ctx->queue = objc_metal_create_queue(device);
  if (!ctx->queue) {
    objc_release_obj(ctx->device);
    free(ctx);
    Rf_error("failed to create Metal command queue");
  }
  
  /* wrap the struct pointer -- metal_context_finalizer releases both
   * ObjC objects and frees the struct */
  SEXP context = PROTECT(R_MakeExternalPtr(ctx, R_NilValue, R_NilValue));
  R_RegisterCFinalizer(context, metal_context_finalizer);
  setAttrib(context, R_ClassSymbol, mkString("metalContext"));
  
  UNPROTECT(1);
  return context;
}

/* ============================================================================
 * SECTION: command buffer management
 * ========================================================================= */

void metal_wait_for_completion(void* command_buffer) {
  objc_metal_command_buffer_wait(command_buffer);
}
