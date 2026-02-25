###### -- Package Hooks -------------------------------------------------------
# Package initialization and cleanup

###### -- NOTES ---------------------------------------------------------------
# This file contains:
# .onLoad hooks
# .onUnload hooks
# .onAttach hooks
# globalVariable calls

# Global variable declarations
# call anything in data ... this still seems strange, but
# ¯\_(ツ)_/¯
# utils::globalVariables(c("metal_types"))

# caching for device capability look ups
.ACFmetal_cache <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Package initialization happens here
  # C symbols are already registered via R_init_ACFmetal
  # Could add version checks, capability detection, etc.
  # For now, keep it simple
  invisible()
}

.onUnload <- function(libpath) {
  # Cleanup when package is unloaded
  # Metal objects are cleaned up by finalizers
  library.dynam.unload("ACFmetal", libpath)
  invisible()
}

.onAttach <- function(libname, pkgname) {
  # Message shown when package is attached (library() call)
  # Only use this for important user-facing messages
  metal_status <- metal_is_available()
  
  if (metal_status) {
    packageStartupMessage("ACFmetal ",
                          utils::packageVersion("ACFmetal"),
                          " - Metal GPU acceleration is available")
    
  }
  
  # .onAttach returns NULL by default, calling invisible here suppresses
  # the default output
  invisible()
}
