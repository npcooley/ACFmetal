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

# this is a large rewrite of the underlying runner going from inferring things
# to ingesting a specific set of args


###### -- FUNCTION ------------------------------------------------------------

simple_metal_wrapper <- function(metal_context,
                                 fun_ptr,
                                 arg_types,
                                 arg_list,
                                 work_dims = NULL,
                                 threadgroup_dims = NULL,
                                 threads_per_threadgroup = 256L) {
  
  # hard coded types because it's cheaper than pulling the data object
  type_mode <- c('float',
                 'double',
                 'char',
                 'short',
                 'int',
                 'long',
                 'uchar',
                 'ushort',
                 'uint',
                 'ulong')
  
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
  if (length(arg_types) != length(arg_list)) {
    stop("length of 'arg_types' must equal the number of elements in 'arg_list'")
  }
  if (any(!(arg_types %in% type_mode))) {
    bad_types <- arg_types[!(arg_types %in% type_mode)]
    stop("unrecognized type(s): ",
         paste0("'", bad_types, "'", collapse = ", "),
         "; accepted types are: ",
         paste0("'", type_mode, "'", collapse = ", "))
  }
  
  # pause these guardrails for a second,
  # if ((is.null(work_dims) & !is.null(threadgroup_dims)) |
  #     (!is.null(work_dims) & is.null(threadgroup_dims))) {
  #   stop("if one of 'work_dims' or 'threadgroup_dims' is specified, so must the other")
  # }
  # if (!is.null(work_dims)) {
  #   if (length(work_dims) != 3 |
  #       length(threadgroup_dims) != 3 |
  #       !is.integer(work_dims) |
  #       !is.integer(threadgroup_dims)) {
  #     stop("'work_dims' and 'threadgroup_dims' must both be integers of length three if either is supplied")
  #   }
  # }
  
  # the simple runner makes A LOT of assumptions to remain 'simple'
  # chief among them are:
  # the first buffer argument is the output buffer,
  # after that buffer order needs to be matched to the [[buffer(n)]] argument
  # order in the metal kernel function
  # [[identity attributes]] mixed in with [[binding attributes]] will likely
  # cause a problem ?
  res <- .Call("metal_simple_runner",
               metal_context,
               fun_ptr,
               arg_types,
               arg_list,
               work_dims,
               threadgroup_dims,
               threads_per_threadgroup,
               PACKAGE = "ACFmetal")
  
}


