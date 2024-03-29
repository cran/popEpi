% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/S3_definitions.R
\name{print.aggre}
\alias{print.aggre}
\title{Print an \code{aggre} Object}
\usage{
\method{print}{aggre}(x, subset = NULL, ...)
}
\arguments{
\item{x}{an \code{aggre} object}

\item{subset}{a logical condition to subset results table by
before printing; use this to limit to a certain stratum. E.g.
\code{subset = sex == "male"}}

\item{...}{arguments passed to \code{print.data.table}; try e.g.
\code{top = 2} for numbers of rows in head and tail printed 
if the table is large, 
\code{nrow = 100} for number of rows to print, etc.}
}
\value{
Always returns `NULL` invisibly.
This function is called for its side effects.
}
\description{
Print method function for \code{aggre} objects; see
\code{\link{as.aggre}} and \code{\link{aggre}}.
}
\author{
Joonas Miettinen
}
