###### -- create a context from a device --------------------------------------
# author: nicholas cooley
# maintainer: nicholas cooley

###### -- NOTES ---------------------------------------------------------------
# give a device pointer, return a list with original device pointer, and the
# pointer to the queue that Metal creates for that device

###### -- FUNCTION ------------------------------------------------------------

metal_make_context <- function(device_ptr) {
  if (!is(object = device_ptr,
          class2 = "externalptr")) {
    stop ("function takes in a pointer to a Metal device")
  }
  
  res <- .Call("c_metal_make_context",
               device_ptr,
               PACKAGE = "ACFmetal")
  return(res)
}
