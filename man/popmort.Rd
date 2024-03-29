% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_document.R
\name{popmort}
\alias{popmort}
\title{Population mortality rates in Finland 1951 - 2013 in 101 age groups and
by gender. This is an example of a population hazard table as used in 
\pkg{popEpi}; for the general help page, see \code{\link{pophaz}}.}
\format{
\code{data.table} with columns
\itemize{
 \item \code{sex} gender coded as male, female (0, 1)
 \item \code{year} calendar year
 \item \code{agegroup} - coded 0 to 100; one-year age groups
 \item \code{haz} the average population mortality rate per person-year 
 (d/(pyrs), where d is the number of deaths and pyrs is the person-years)
}
}
\source{
Statistics Finland
}
\description{
Population mortality rates in Finland 1951 - 2013 in 101 age groups and
by gender. This is an example of a population hazard table as used in 
\pkg{popEpi}; for the general help page, see \code{\link{pophaz}}.
}
\seealso{
\code{\link{pophaz}}

Other popEpi data: 
\code{\link{ICSS}},
\code{\link{meanpop_fi}},
\code{\link{sibr}},
\code{\link{sire}},
\code{\link{stdpop101}},
\code{\link{stdpop18}}
}
\concept{popEpi data}
