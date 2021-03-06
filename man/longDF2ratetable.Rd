% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utility_functions.R
\name{longDF2ratetable}
\alias{longDF2ratetable}
\title{\strong{Experimental}: Coerce a long-format \code{data.frame} to a \code{ratetable} object}
\usage{
longDF2ratetable(DF, value.var = "haz", by.vars = setdiff(names(DF),
  value.var))
}
\arguments{
\item{DF}{a \code{data.frame}}

\item{value.var}{name of values variable in quotes}

\item{by.vars}{names vector of variables by which to create (array) dimensions}
}
\description{
Coerces a long-format \code{data.frame} of population hazards
to an array, and in turn to a \code{\link[survival]{ratetable}},
which can be used in e.g. \pkg{survival}'s expected survival computations
and \pkg{relsurv}'s relative survival computations.
}
\seealso{
\code{\link[survival]{ratetable}}, 
\code{\link{as.data.table.ratetable}}, 
\code{\link{as.data.frame.ratetable}}
}
\author{
Joonas Miettinen
}
