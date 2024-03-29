% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/S3_definitions.R
\name{plot.sir}
\alias{plot.sir}
\title{Plot method for sir-object}
\usage{
\method{plot}{sir}(
  x,
  conf.int = TRUE,
  ylab,
  xlab,
  xlim,
  main,
  eps = 0.2,
  abline = TRUE,
  log = FALSE,
  left.margin,
  ...
)
}
\arguments{
\item{x}{an object returned by function \code{sir}}

\item{conf.int}{default TRUE draws confidence intervals}

\item{ylab}{overwrites default y-axis label}

\item{xlab}{overwrites default x-axis label}

\item{xlim}{x-axis minimum and maximum values}

\item{main}{optional plot title}

\item{eps}{error bar vertical bar height (works only in 'model' or 'univariate')}

\item{abline}{logical; draws a grey line in SIR = 1}

\item{log}{logical; SIR is not in log scale by default}

\item{left.margin}{adjust left marginal of the plot to fit long variable names}

\item{...}{arguments passed on to plot(), segment and lines()}
}
\value{
Always returns `NULL` invisibly.
This function is called for its side effects.
}
\description{
Plot SIR estimates with error bars
}
\details{
Plot SIR estimates and confidence intervals 
\itemize{
 \item univariate - plots SIR with univariate confidence intervals
 \item model - plots SIR with Poisson modelled confidence intervals
}

\strong{Customize}
Normal plot parameters can be passed to \code{plot}. These can be a vector when plotting error bars:
\itemize{
 \item \code{pch} - point type
 \item \code{lty} - line type
 \item \code{col} - line/point colour 
 \item \code{lwd} - point/line size
}

\strong{Tips for plotting splines}
It's possible to use \code{plot} to first draw the 
confidence intervals using specific line type or colour and then plotting 
again the estimate using \code{lines(... , conf.int = FALSE)} with different 
settings. This works only when \code{plot.type} is 'splines'.
}
\examples{
\donttest{
# Plot SIR estimates
# plot(sir.by.gender, col = c(4,2), log=FALSE, eps=0.2, lty=1, lwd=2, pch=19,  
#      main = 'SIR by gender', abline=TRUE)
}
}
\seealso{
\code{\link{sir}},  \code{\link{sirspline}}
}
\author{
Matti Rantanen
}
