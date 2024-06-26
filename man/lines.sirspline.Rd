% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/S3_definitions.R
\name{lines.sirspline}
\alias{lines.sirspline}
\title{lines method for sirspline-object}
\usage{
\method{lines}{sirspline}(x, conf.int = TRUE, print.levels = NA, select.spline, ...)
}
\arguments{
\item{x}{an object returned by function sirspline}

\item{conf.int}{logical; default TRUE draws also the 95 confidence intervals}

\item{print.levels}{name(s) to be plotted. Default plots all levels.}

\item{select.spline}{select which spline variable (a number or a name) is plotted.}

\item{...}{arguments passed on to lines()}
}
\value{
Always returns `NULL` invisibly.
This function is called for its side effects.
}
\description{
Plot SIR spline lines with R base graphics
}
\details{
In \code{lines.sirspline} most of graphical parameters is user 
adjustable.
Desired spline variable can be selected with \code{select.spline} and only one
can be plotted at a time. The spline variable can include 
several levels, e.g. gender (these are the levels of \code{print}
from \code{sirspline}). All levels are printed by default, but a
specific level can be selected using argument
\code{print.levels}. Printing the levels separately enables  e.g. to
give different colours for each level.
}
\seealso{
Other sir functions: 
\code{\link{plot.sirspline}()},
\code{\link{sir}()},
\code{\link{sir_exp}()},
\code{\link{sir_ratio}()},
\code{\link{sirspline}()}
}
\author{
Matti Rantanen
}
\concept{sir functions}
