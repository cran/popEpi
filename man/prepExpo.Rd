% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/splitting_utility_functions.R
\name{prepExpo}
\alias{prepExpo}
\title{Prepare Exposure Data for Aggregation}
\usage{
prepExpo(
  lex,
  freezeScales = "work",
  cutScale = "per",
  entry = min(get(cutScale)),
  exit = max(get(cutScale)),
  by = "lex.id",
  breaks = NULL,
  freezeDummy = NULL,
  subset = NULL,
  verbose = FALSE,
  ...
)
}
\arguments{
\item{lex}{a \code{\link[Epi]{Lexis}} object with ONLY periods of exposure
as rows; one or multiple rows per subject allowed}

\item{freezeScales}{a character vector naming \code{Lexis} time scales of exposure
which should be frozen in periods where no exposure occurs (in the gap
time periods)}

\item{cutScale}{the \code{Lexis} time scale along which the subject-specific
ultimate entry and exit times are specified}

\item{entry}{an expression; the time of entry to follow-up which may be earlier, at, or after
the first time of exposure in \code{freezeScales}; evaluated separately
for each unique combination of \code{by}, so e.g. with 
\code{entry = min(Var1)} and \code{by = "lex.id"} it 
sets the \code{lex.id}-specific minima of \code{Var1} to be the original times
of entry for each \code{lex.id}}

\item{exit}{the same as \code{entry} but for the ultimate exit time per unique
combination of \code{by}}

\item{by}{a character vector indicating variable names in \code{lex},
the unique combinations of which identify separate subjects for which
to fill gaps in the records from \code{entry} to \code{exit};
for novices of \code{{\link{data.table}}}, this is passed to a 
\code{data.table}'s \code{by} argument.}

\item{breaks}{a named list of breaks; 
e.g. \code{list(work = 0:20,per = 1995:2015)}; passed on to 
\code{\link{splitMulti}} so see that function's help for more details}

\item{freezeDummy}{a character string; specifies the name for a dummy variable
that this function will create and add to output which 
identifies rows where the \code{freezeScales} are frozen and where not
(\code{0} implies not frozen, \code{1} implies frozen);
if \code{NULL}, no dummy is created}

\item{subset}{a logical condition to subset data by before computations;
e.g. \code{subset = sex == "male"}}

\item{verbose}{logical; if \code{TRUE}, the function is chatty and returns
some messages and timings during its run.}

\item{...}{additional arguments passed on to \code{\link{splitMulti}}}
}
\value{
Returns a \code{Lexis} object that has been split if \code{breaks} is specified.
The resulting time is also a \code{data.table} if 
\code{options("popEpi.datatable") == TRUE} (see: \code{?popEpi})
}
\description{
\code{prepExpo} uses a \code{Lexis} object of periods of exposure
to fill gaps between the periods and overall entry and exit times without
accumulating exposure time in periods of no exposure, and splits the
result if requested.
}
\details{
\code{prepExpo} is a convenience function for the purpose of eventually aggregating 
person-time and events in categories of not only normally progressing 
\code{Lexis} time scales but also some time scales which should not
progress sometimes. For example a person may work at a production facility
only intermittently, meaning exposure time (to work-related substances 
for example) should not progress outside of periods of work. This allows for
e.g. a correct aggregation of person-time and events by categories of cumulative
time of exposure.

Given a \code{Lexis} object containing rows (time lines)
where a subject is exposed to something (and NO periods without exposure),
fills any gaps between exposure periods for each unique combination of \code{by}
and the subject-specific "ultimate" \code{entry} and \code{exit} times,
"freezes" the cumulative exposure times in periods of no exposure,
and splits data using \code{breaks} passed to \code{\link{splitMulti}}
if requested. Results in a (split) \code{Lexis} object where \code{freezeScales}
do not progress in time periods where no exposure was recorded in \code{lex}.

This function assumes that \code{entry} and \code{exit} arguments are the
same for each row within a unique combination of variables named in \code{by}.
E.g. with \code{by = "lex.id"} only each \code{lex.id} has a unique value
for \code{entry} and \code{exit} at most.

The supplied \code{breaks} split the data using \code{splitMulti}, with
the exception that breaks supplied concerning any frozen time scales
ONLY split the rows where the time scales are not frozen. E.g.
with \code{freezeScales = "work"}, 
\code{breaks = list(work = 0:10, cal = 1995:2010)} splits all rows over
\code{"cal"} but only non-frozen rows over \code{"work"}.

Only supports frozen time scales that advance and freeze contemporaneously:
e.g. it would not currently be possible to take into account the cumulative
time working at a facility and the cumulative time doing a single task
at the facility, if the two are not exactly the same. On the other hand
one might use the same time scale for different exposure types, supply them
as separate rows, and identify the different exposures using a dummy variable.
}
