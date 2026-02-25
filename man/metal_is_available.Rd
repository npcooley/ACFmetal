\name{metal_is_available}
\alias{metal_is_available}
\title{Is Metal Available?}
\description{
Return a logical indicating whether Metal is available.
}
\usage{
metal_is_available(verbose = FALSE)
}
\arguments{
  \item{verbose}{
    Logical; indicating whether the function should return a message or not.
  }
}
\value{
A logical indicating whether Metal is available.
}
\details{
A convenience wrapper for determining whether Metal is available in the current environment.
}
\examples{
res <- metal_is_available()
}
\seealso{
\code{\link{metal_get_all_devices}}, \code{\link{metal_devices_default}}
}