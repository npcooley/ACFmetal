###### -- basic functions -----------------------------------------------------
# Author: Nicholas Cooley
# Maintainer: Nicholas Cooley

###### -- NOTES ---------------------------------------------------------------
# i typically do not like including multiple R functions in the same file, but
# it seems to make sense specifically for functions that have no inputs
# and / or are just wrappers for lower language functions

###### -- FUNLIST -------------------------------------------------------------
# metal_devices_default()
# metal_get_all_devices()
# metal_is_available()
# metal_device_information()

metal_devices_default <- function() {
  res <-.Call("c_metal_devices_default",
              PACKAGE = "ACFmetal")
  return(res)
}

metal_get_all_devices <- function() {
  res <- .Call("c_metal_get_all_devices",
               PACKAGE = "ACFmetal")
  return(res)
}

metal_is_available <- function(verbose = FALSE) {
  default_device <- .Call("c_metal_devices_default",
                          PACKAGE = "ACFmetal")
  avl <- length(default_device) > 0
  if (avl && verbose) {
    message("A default metal device is present.")
  } else if (!avl && verbose) {
    message("No metal device is present.")
  }
  invisible(avl)
}

metal_device_information <- function(device_ptr) {
  res <- .Call("c_metal_device_information",
               device_ptr,
               PACKAGE = "ACFmetal")
  return(res)
}

