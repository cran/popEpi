% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sir_utils.R
\name{sir_ratio}
\alias{sir_ratio}
\title{Confidence intervals for the ratio of two SIRs/SMRs}
\usage{
sir_ratio(
  x,
  y,
  digits = 3,
  alternative = "two.sided",
  conf.level = 0.95,
  type = "exact"
)
}
\arguments{
\item{x}{a sir-object or a vector of two; observed and expected cases.}

\item{y}{a sir-object or a vector of two; observed and expected cases.}

\item{digits}{number of digits in the output}

\item{alternative}{The null-hypothesis test: (default:) \code{two.sided}, \code{less}, \code{greater}}

\item{conf.level}{the type-I error in confidence intervals, default 0.95 for 95\% CI.}

\item{type}{How the binomial confidence intervals are calculated (default:) \code{exact} or \code{asymptotic}.}
}
\value{
A vector length of three: sir_ratio, and lower and upper confidence intervals.
}
\description{
Calculate ratio of two SIRs/SMRs and the confidence intervals of the ratio.
}
\details{
Function works with pooled sir-objects i.e. the \code{print} argument in \code{sir} is ignored.
Also \code{x} and \code{y} can be a vector of two where first index is the
observed cases and second is expected cases (see examples).
Note that the ratio of two SIR's is only applicable when the age distributions are similar
in both populations.

\strong{Formula}

The observed number of first sir \code{O1} is considered as a Binomial variable with sample 
size of \code{O1+O2}. The confidence intervals for Binomial proportion \code{A} 
is solved using \code{exact} or \code{asymptotic} 
method. Now the CI for ratio \code{O1/O2} is \code{B = A/(1 - A)}. And further the CI for SIR/SMR 
is B*E2/E1. (Ederer and Mantel)
}
\note{
Parameter \code{alternative} is always \code{two.sided} when parameter 
\code{type} is set to \code{asymptotic}.
}
\examples{
## Ratio for sir-object and the same values given manually:


## create example dataset
dt1 <- data.frame(obs = rep(c(5,7), 10),
                  pyrs = rep(c(250,300,350,400), 5),
                  var = 1:20)
Ref <- data.frame(obs = rep(c(50,70,80,100), 5),
                 pyrs = rep(c(2500,3000,3500,4000), 5),
                 var = 1:20)
## sir using the function
s1 <- sir(coh.data = dt1, coh.obs = obs, coh.pyrs = pyrs, 
          ref.data = Ref, ref.obs = obs, ref.pyrs = pyrs,
          adjust = var)

## Ratio is simply 1:
sir_ratio(s1, c(120, 150))

}
\references{
Statistics with Confidence: Confidence Intervals and Statistical Guidelines, 
Douglas Altman, 2000. ISBN: 978-0-727-91375-3
}
\seealso{
\code{\link{sir}}
\href{../doc/sir.html}{A SIR calculation vignette}

Other sir functions: 
\code{\link{lines.sirspline}()},
\code{\link{plot.sirspline}()},
\code{\link{sir}()},
\code{\link{sir_exp}()},
\code{\link{sirspline}()}
}
\author{
Matti Rantanen
}
\concept{sir functions}
