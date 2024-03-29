% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utility_functions.R
\name{try2int}
\alias{try2int}
\title{Attempt coercion to integer}
\source{
\href{https://stackoverflow.com/questions/3476782/how-to-check-if-the-number-is-integer}{Stackoverflow thread}
}
\usage{
try2int(obj, tol = .Machine$double.eps^0.5)
}
\arguments{
\item{obj}{a numeric vector}

\item{tol}{tolerance; if each numeric value in \code{obj} deviate from
the corresponding integers at most the value of \code{tol}, they are considered
to be integers; e.g. by default \code{1 + .Machine$double.eps} is considered
to be an integer but \code{1 + .Machine$double.eps^0.49} is not.}
}
\value{
An `integer` vector if no information is lost in coercion; else `numeric` 
vector.
}
\description{
Attempts to convert a numeric object to integer, 
but won't if loss of information is imminent (if values after decimal
are not zero for even one value in \code{obj})
}
\author{
James Arnold
}
