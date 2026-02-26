###### -- peform a simple compute pipeline on a metal device ------------------
# author: nicholas cooley
# maintainer: nicholas cooley

###### -- NOTES ---------------------------------------------------------------
# R wrapper for metal_simple_runner
# requires:
# metalContext
# function pointer
# arg_types vector
# various inputs
# returns:
# the output buffer

###### -- DESIGN CONSIDERATIONS -----------------------------------------------

# i don't know if i'm the right person to be doing this, but no one else is
# so we're all going to live with my sins ¯\_(ツ)_/¯
# 
# in trying to make this make a bit more sense than it does in the BiocMetal
# implementation, the arg type checking and compiler directive mess have been
# dropped, it doesn't exactly feel entirely streamlined, but it's better...

# Resource binding attributes (what slot a parameter maps to):
# 
# [[buffer(n)]] — binds to a buffer at index n
# [[texture(n)]] — binds to a texture at index n
# [[sampler(n)]] — binds to a sampler at index n

# Thread position / identity attributes (built-in values the GPU provides automatically):
# 
# [[thread_position_in_grid]] — the global thread ID across the entire dispatch
# [[thread_position_in_threadgroup]] — local ID within the threadgroup
# [[threadgroup_position_in_grid]] — which threadgroup this thread belongs to
# [[threads_per_threadgroup]] — size of the threadgroup
# [[threads_per_grid]] — total number of threads dispatched
# [[thread_index_in_threadgroup]] — flattened 1D index within the threadgroup


###### -- FUNCTION ------------------------------------------------------------

simple_metal_wrapper <- function(metal_context,
                                 fun_ptr,
                                 arg_types,
                                 ...) {
  # containerize the buffer vectors
  vals <- list(...)
  # hard coded types because it's cheaper than pulling the data object
  type_mode <- c('float', 'double', 'char', 'short',
                 'int', 'long', 'uchar', 'ushort',
                 'uint', 'ulong', 'WORKDIMS', 'THREADGROUPS')
  
  if (!is(object = fun_ptr,
          class2 = "externalptr")) {
    stop ("'fun_ptr' must be an externalptr object")
  }
  if (length(arg_types) < 1) {
    stop ("all supplied vectors require an explicit type")
  }
  if (!is(object = arg_types,
          class2 = "character")) {
    stop ("vector types must be assigned with a character vectors")
  }
  if (length(arg_types) != length(vals)) {
    stop ("all supplied vectors require an explicit type")
  }
  if (any(!(arg_types %in% type_mode))) {
    stop("unrecognized type; only",
         paste0("'",
                type_mode,
                "'",
                collapse = ", "),
         "are currently accepted")
  }
  # the simple runner makes A LOT of assumptions to remain 'simple'
  # chief among them are:
  # the first buffer argument is the output buffer,
  # after that buffer order needs to be matched to the [[buffer(n)]] argument
  # order in the metal kernel function
  # [[identity attributes]] mixed in with [[binding attributes]] will likely
  # cause a problem ?
  res <- .External("metal_simple_runner",
                   metal_context,
                   fun_ptr,
                   arg_types,
                   ...,
                   PACKAGE = "ACFmetal")
  
}


