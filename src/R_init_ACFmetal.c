/* ============================================================================
 * Package initialization and registration
 * glhf
 * ========================================================================= */

/* ============================================================================
 * Rdefines.h is needed for the SEXP typedef, for the error(), INTEGER(),
 * GET_DIM(), LOGICAL(), NEW_INTEGER(), PROTECT() and UNPROTECT() macros,
 * and for the NA_INTEGER constant symbol.
 * ========================================================================= */

#include <Rdefines.h>
#include <R_ext/Rdynload.h>
#include <Rinternals.h>
#include "ACFmetal.h"

/* ============================================================================
 * Aidan's code block definitions
 * 
 * help with formatting, repetitions, and interpretability
 * RFUNCTION_DEF(name, n) without the dot
 * #name == stringify 'name' from the macro definition
 * &name == get the memory address (pointer) of the function
 * DL_FUNC == type cast; cast the function pointer to R's expected type
 * ## == Token Pasting == Joins two tokens == x##y gives xy
 * 
 * ACFmetal currently does not use .C, but if it ever needs to just
 * uncomment that line
 * ========================================================================= */

// Define .Call definition for simpler formatting
#define CALL_DEF(name, n) {#name, (DL_FUNC) &name, n}
// Define .C definition for simpler formatting
// #define C_DEF(name, n)  {#name, (DL_FUNC) &name, n}
// Define .External definition for simpler formatting
#define EXTERNAL_DEF(name, n) {#name, (DL_FUNC) &name, n}

/* ============================================================================
 * .Call Function Registration Table
 * ========================================================================= */

static const R_CallMethodDef callMethods[] = {
  CALL_DEF(c_metal_devices_default, 0),
  CALL_DEF(c_metal_get_all_devices, 0),
  CALL_DEF(c_metal_device_information, 1),
  CALL_DEF(c_metal_make_context, 1),
  CALL_DEF(metal_get_library_pointer, 2),
  CALL_DEF(metal_get_function_pointers, 2),
  {NULL, NULL, 0}
};

/* ============================================================================
 * .External Function Registration Table
 * ========================================================================= */

static const R_ExternalMethodDef externalMethods[] = {
  EXTERNAL_DEF(metal_simple_runner, -1),
  {NULL, NULL, 0}
};

/* ============================================================================
 * .C Function Registration Table -- currently unused
 * ========================================================================= */

/* ============================================================================
 * Package Initialization
 * ========================================================================= */

void R_init_ACFmetal(DllInfo *info) {
  
  // initialize symbols, defined in a "shared.c" file
  // currently not used
  //ACFmetal_init_symbols();
  
  // Register C and External entry points
  R_registerRoutines(info, NULL, callMethods, NULL, externalMethods);
  R_useDynamicSymbols(info, FALSE);
}


