###### -- compile a single .metallib from one or more metal files -------------
# given a list of metal files, compile them all into a single metallib
# author: nicholas cooley
# maintainer: nicholas cooley

###### -- NOTES ---------------------------------------------------------------
# metallib as a function may end up being deprecated by apple in favor of metal-tt
# this is not necessarily a major concern, but something to note *just in case*

# this function is just managing inputs / outputs and calling a command line
# utility, there's no reason to get all fancy and do anything else

###### -- FUNCTION ------------------------------------------------------------

metal_functions_to_library <- function(metal_files,
                                       library_file,
                                       verbose = FALSE) {
  # overhead checking
  check1 <- vapply(X = metal_files,
                   FUN = function(x) {
                     file.exists(x)
                   },
                   FUN.VALUE = vector(mode = "logical",
                                      length = 1))
  check2 <- grepl(pattern = "\\.metal$",
                  x = metal_files)
  if (!all(check1 & check2)) {
    stop("all input files must exist and possess a '.metal' extension")
  }
  
  # create our argument string for system2
  # xcrun -sdk macosx metal function.metal -o kernel.metallib
  argstring <- paste("-sdk macosx metal",
                     paste0(metal_files,
                            collapse = " "),
                     "-o",
                     library_file)
  
  # create our library
  # it's not clear that `wait` actually does anything...
  output <- system2(command = "xcrun",
                    args = argstring,
                    wait = TRUE)
  
  # collect kernel names
  function_info <- do.call(rbind,
                           strsplit(x = system2(command = "xcrun",
                                                args = paste("metal-nm",
                                                             library_file),
                                                stdout = TRUE),
                                    split = " "))
  # the last column is the function declarations
  # kern_names <- kern_names[, ncol(kern_names)]
  # print(output)
  if (verbose) {
    cat("Complete!\n")
  }
  invisible(function_info)
}
