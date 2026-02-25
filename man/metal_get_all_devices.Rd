\name{metal_get_all_devices}
\alias{metal_get_all_devices}
\title{Metal Device Information}
\description{
Return information on all Metal capable devices.
}
\usage{
metal_get_all_devices()
}
\value{
A list containing device information.
}
\details{
A helper function for finding information about Metal capable devices.
}
\examples{
res <- metal_get_all_devices()
}
\seealso{
\code{\link{metal_is_available}}, \code{\link{metal_devices_default}}
}