###### -- get a function pointer from a metal library -------------------------
# given a file path to a metal library and a character vector 
# return a named list of function pointers
# author: nicholas cooley
# maintainer: nicholas cooley

###### -- NOTES ---------------------------------------------------------------
# we can let the pointer to the library be spun up and destroyed as this
# function completes, but we need the pointers to the metal functions to remain
# instantiated until we remove them from the workspace, at which time their
# finalizers will remove them
# 
# because 'library_pointer' gets exposed to the garbage collector as soon as
# this function ends, it's finalizer call in the C function should take care of
# it immediately

###### -- FUNCTION ------------------------------------------------------------

metal_functions_from_library <- function(library_filepath,
                                         device_ptr,
                                         fun_names) {
  
  if (!file.exists(library_filepath)) {
    stop ("'library_filepath' must be a regular file")
  }
  if (!is(object = device_ptr,
          class2 = "externalptr")) {
    stop ("'device_ptr' must be an externalptr object")
  }
  if (length(fun_names) < 1) {
    stop ("'fun_names' must be a character vector of length 1 or greater")
  }
  if (!is(object = fun_names,
          class2 = "character")) {
    stop ("'fun names' must be a character vector of length 1 or greater")
  }
  
  # returns an externalptr
  library_pointer <- .Call("metal_get_library_pointer",
                           library_filepath,
                           device_ptr,
                           PACKAGE = "ACFmetal")
  
  if (!is(object = library_pointer,
          class2 = "externalptr")) {
    stop ("'metal_get_library_pointer' failed to return an externalptr")
  }
  
  # returns a list of externalptrs
  res <- .Call("metal_get_function_pointers",
               library_pointer,
               fun_names,
               PACKAGE = "ACFmetal")
  names(res) <- fun_names
  return(res)
}
