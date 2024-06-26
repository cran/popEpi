


#' @title Compute Mean Survival Times Using Extrapolation
#' @description Computes mean survival times based on survival estimation up to
#' a point in follow-up time (e.g. 10 years), 
#' after which survival is extrapolated
#' using an appropriate hazard data file (\code{pophaz}) to yield the "full"
#' survival curve. The area under the full survival curve is the mean survival.
#' @author Joonas Miettinen
#' @param formula a \code{formula}, e.g. \code{FUT ~ V1} or 
#' \code{Surv(FUT, lex.Xst) ~ V1}.
#' Supplied in the same way as to \code{\link{survtab}}, see that help
#' for more info.
#' @param data a \code{Lexis} data set; see \code{\link[Epi]{Lexis}}.
#' @param adjust variables to adjust estimates by, e.g. \code{adjust = "agegr"}.
#' \link[=flexible_argument]{Flexible input}.
#' @param weights weights to use to adjust mean survival times. See the
#' \link[=direct_standardization]{dedicated help page} for more details on 
#' weighting. \code{survmean}
#' computes curves separately by all variables to adjust by, computes mean
#' survival times, and computes weighted means of the mean survival times.
#' See Examples.
#' @param breaks a list of breaks defining the time window to compute 
#' observed survival in, and the intervals used in estimation. E.g.
#' \code{list(FUT = 0:10)} when \code{FUT} is the follow-up time scale in your
#' data.
#' @param pophaz a data set of population hazards passed to 
#' \code{\link{survtab}} (see the 
#' \link[=pophaz]{dedicated help page} and the help page of
#' \code{survtab} for more information). Defines the 
#' population hazard in the time window where observed survival is estimated.
#' @param e1.breaks \code{NULL} or a list of breaks defining the time 
#' window to compute 
#' \strong{expected} survival in, and the intervals used in estimation. E.g.
#' \code{list(FUT = 0:100)} when \code{FUT} is the follow-up time scale in your
#' data to extrapolate up to 100 years from where the observed survival
#' curve ends. \strong{NOTE:} the breaks on the survival time scale
#' MUST include the breaks supplied to argument \code{breaks}; see Examples.
#' If \code{NULL}, uses decent defaults (maximum follow-up time of 50 years).
#' @param e1.pophaz Same as \code{pophaz}, except this defines the 
#' population hazard in the time window where \strong{expected} 
#' survival is estimated. By default uses the same data as 
#' argument \code{pophaz}.
#' @param r either a numeric multiplier such as \code{0.995}, \code{"auto"}, or
#' \code{"autoX"} where \code{X} is an integer;
#' used to determine the relative survival ratio (RSR) persisting after where 
#' the estimated observed survival curve ends. See Details.
#' @param surv.method passed to \code{survtab}; see that help for more info.
#' @param subset a logical condition; e.g. \code{subset = sex == 1}; 
#' subsets the data before computations
#' @param verbose \code{logical}; if \code{TRUE}, the function is returns
#' some messages and results along the run, which may be useful in debugging
#' @details
#' \strong{Basics}
#' 
#' \code{survmean} computes mean survival times. For median survival times
#' (i.e. where 50 % of subjects have died or met some other event)
#' use \code{\link{survtab}}.
#' 
#' The mean survival time is simply the area under the survival curve.
#' However, since full follow-up rarely happens, the observed survival curves
#' are extrapolated using expected survival: E.g. one might compute observed
#' survival till up to 10 years and extrapolate beyond that 
#' (till e.g. 50 years) to yield an educated guess on the full observed survival
#' curve. 
#' 
#' The area is computed by trapezoidal integration of the area under the curve.
#' This function also computes the "full" expected survival curve from
#' T = 0 till e.g. T = 50 depending on supplied arguments. The
#' expected mean survival time is the area under the 
#' mean expected survival curve.
#' This function returns the mean expected survival time to be compared with 
#' the mean survival time and for computing years of potential life lost (YPLL).
#' 
#' Results can be formed by strata and adjusted for e.g. age by using
#' the \code{formula} argument as in \code{survtab}. See also Examples.
#' 
#' \strong{Extrapolation tweaks}
#' 
#' Argument \code{r} controls the relative survival ratio (RSR) assumed to
#' persist beyond the time window where observed survival is computed
#' (defined by argument \code{breaks}; e.g. up to \code{FUT = 10}).
#' The RSR is simply \code{RSR_i = p_oi / p_ei} for a time interval \code{i}, 
#' i.e. the observed divided by the expected 
#' (conditional, not cumulative) probability of surviving from the beginning of
#' a time interval till its end. The cumulative product of \code{RSR_i}
#' over time is the (cumulative) relative survival curve. 
#' 
#'
#' If \code{r} is numeric, e.g. \code{r = 0.995}, that RSR level is assumed
#' to persist beyond the observed survival curve. 
#' Numeric \code{r} should be \code{> 0} and expressed at the annual level
#' when using fractional years as the scale of the time variables.
#' E.g. if RSR is known to be \code{0.95} at the month level, then the
#' annualized RSR is \code{0.95^12}. This enables correct usage of the RSR
#' with survival intervals of varying lengths. When using day-level time 
#' variables (such as \code{Dates}; see \code{as.Date}), numeric \code{r}
#' should be expressed at the day level, etc.
#' 
#' If \code{r = "auto"} or \code{r = "auto1"}, this function computes
#' RSR estimates internally and automatically uses the \code{RSR_i}
#' in the last survival interval in each stratum (and adjusting group)
#' and assumes that to persist beyond the observed survival curve.
#' Automatic determination of \code{r} is a good starting point,
#' but in situations where the RSR estimate is uncertain it may produce poor
#' results. Using \code{"autoX"} such as \code{"auto6"} causes \code{survmean}
#' to use the mean of the estimated RSRs in the last X survival intervals, 
#' which may be more stable.
#' Automatic determination will not use values \code{>1} but set them to 1. 
#' Visual inspection of the produced curves is always recommended: see
#' Examples.
#' 
#' One may also tweak the accuracy and length of extrapolation and 
#' expected survival curve computation by using 
#' \code{e1.breaks}. By default this is whatever was supplied to \code{breaks}
#' for the survival time scale, to which
#' 
#' \code{c(seq(1/12, 1, 1/12), seq(1.2, 1.8, 0.2), 2:19, seq(20, 50, 5))}
#' 
#' is added after the maximum value, e.g. with \code{breaks = list(FUT = 0:10)}
#' we have 
#' 
#' \code{..., 10+1/12, ..., 11, 11.2, ..., 2, 3, ..., 19, 20, 25, ... 50}
#' 
#' as the \code{e1.breaks}. Supplying \code{e1.breaks} manually requires
#' the breaks over time survival time scale supplied to argument \code{breaks}
#' to be reiterated in \code{e1.breaks}; see Examples. \strong{NOTE}: the
#' default extrapolation breaks assume the time scales in the data to be 
#' expressed as fractional years, meaning this will work extremely poorly
#' when using e.g. day-level time scales (such as \code{Date} variables). 
#' Set the extrapolation breaks manually in such cases.
#' @md
#' @return 
#' Returns a \code{data.frame} or \code{data.table} (depending on
#' \code{getOptions("popEpi.datatable")}; see \code{?popEpi}) containing the
#' following columns:
#' - `est`: The estimated mean survival time
#' - `exp`: The computed expected survival time
#' - `obs`: Counts of subjects in data
#' - `YPLL`: Years of Potential Life Lost, computed as
#'   (`(exp - est) * obs`) --- though your time data may be in e.g. days,
#'   this column will have the same name regardless.
#' The returned data also has columns named according to the variables
#' supplied to the right-hand-side of the formula.
#' @examples
#' 
#' library(Epi)
#' ## take 500 subjects randomly for demonstration
#' data(sire)
#' sire <- sire[sire$dg_date < sire$ex_date, ]
#' set.seed(1L)
#' sire <- sire[sample(x = nrow(sire), size = 500),]
#' 
#' ## NOTE: recommended to use factor status variable
#' x <- Lexis(entry = list(FUT = 0, AGE = dg_age, CAL = get.yrs(dg_date)),
#'            exit = list(CAL = get.yrs(ex_date)),
#'            data = sire,
#'            exit.status = factor(status, levels = 0:2,
#'                                 labels = c("alive", "canD", "othD")),
#'            merge = TRUE)
#' 
#' ## phony variable
#' set.seed(1L)
#' x$group <- rbinom(nrow(x), 1, 0.5)
#' ## age group
#' x$agegr <- cut(x$dg_age, c(0,45,60,Inf), right=FALSE)
#' 
#' ## population hazards data  set
#' pm <- data.frame(popEpi::popmort)
#' names(pm) <- c("sex", "CAL", "AGE", "haz")
#' 
#' ## breaks to define observed survival estimation
#' BL <- list(FUT = seq(0, 10, 1/12))
#' 
#' ## crude mean survival
#' sm1 <- survmean(Surv(FUT, lex.Xst != "alive") ~ 1,
#'                 pophaz = pm, data = x, weights = NULL,
#'                 breaks = BL)
#'                 
#' sm1 <- survmean(FUT ~ 1,
#'                 pophaz = pm, data = x, weights = NULL,
#'                 breaks = BL)             
#' \donttest{
#' ## mean survival by group                 
#' sm2 <- survmean(FUT ~ group,
#'                 pophaz = pm, data = x, weights = NULL,
#'                 breaks = BL)
#'                 
#' ## ... and adjusted for age using internal weights (counts of subjects)      
#' ## note: need also longer extrapolation here so that all curves
#' ## converge to zero in the end.
#' eBL <- list(FUT = c(BL$FUT, 11:75))
#' sm3 <- survmean(FUT ~ group + adjust(agegr),
#'                 pophaz = pm, data = x, weights = "internal",
#'                 breaks = BL, e1.breaks = eBL)
#' }

#' ## visual inspection of how realistic extrapolation is for each stratum;
#' ## solid lines are observed + extrapolated survivals;
#' ## dashed lines are expected survivals
#' plot(sm1)
#' \donttest{
#' ## plotting object with both stratification and standardization
#' ## plots curves for each strata-std.group combination
#' plot(sm3)
#' 
#' ## for finer control of plotting these curves, you may extract
#' ## from the survmean object using e.g.
#' attributes(sm3)$survmean.meta$curves
#' 
#' 
#' #### using Dates
#' 
#' x <- Lexis(entry = list(FUT = 0L, AGE = dg_date-bi_date, CAL = dg_date),
#'            exit = list(CAL = ex_date),
#'            data = sire[sire$dg_date < sire$ex_date, ],
#'            exit.status = factor(status, levels = 0:2, 
#'                                 labels = c("alive", "canD", "othD")), 
#'            merge = TRUE)
#' ## phony group variable
#' set.seed(1L)
#' x$group <- rbinom(nrow(x), 1, 0.5)
#' 
#'                   
#' ## NOTE: population hazard should be reported at the same scale
#' ## as time variables in your Lexis data.
#' data(popmort, package = "popEpi")
#' pm <- data.frame(popmort)
#' names(pm) <- c("sex", "CAL", "AGE", "haz")
#' ## from year to day level
#' pm$haz <- pm$haz/365.25 
#' pm$CAL <- as.Date(paste0(pm$CAL, "-01-01")) 
#' pm$AGE <- pm$AGE*365.25 
#' 
#' BL <- list(FUT = seq(0, 8, 1/12)*365.25)
#' eBL <- list(FUT = c(BL$FUT, c(8.25,8.5,9:60)*365.25))
#' smd <- survmean(FUT ~ group, data = x, 
#'                 pophaz = pm, verbose = TRUE, r = "auto5",
#'                 breaks = BL, e1.breaks = eBL)     
#' plot(smd)
#' }
#' 

#' 
#' @export
#' @family survmean functions
#' @family main functions
#' 

survmean <- function(formula, data, adjust = NULL, weights = NULL, 
                     breaks=NULL, pophaz = NULL, 
                     e1.breaks = NULL, e1.pophaz = pophaz, r = "auto", 
                     surv.method = "hazard", subset = NULL, verbose = FALSE) {
  pt <- proc.time()
  TF__ <- environment()
  PF__ <- parent.frame(1L)
  
  attr_form <- copy(formula)
  
  surv.method <- match.arg(surv.method, c("hazard", "lifetable"))
  
  ## appease R CMD CHECK (due to using vars in DT[] only)
  r.e2 <- last.p.e2 <- surv <- survmean_type <- est <- Tstart <- Tstop <- 
    lex.id <- surv.int <- delta <- surv.exp <- obs <- NULL
  
  checkLexisData(data, check.breaks = FALSE)
  checkPophaz(data, pophaz, haz.name = "haz")
  checkPophaz(data, e1.pophaz, haz.name = "haz")
  pophaz <- setDT(copy(pophaz))
  e1.pophaz <- setDT(copy(e1.pophaz))
  
  if (is.numeric(r) && r < 0L) stop("numeric r must be > 0, e.g. r = 0.95")
  if (is.character(r)) {
    if (substr(r, 1, 4) != "auto") {
      stop("character string r must start with 'auto'; e.g. `auto` and ",
           "`auto5` are accepted.")
    }
    if (r == "auto") r <- "auto1"
    
    auto_ints <- regmatches(r, regexec("\\d+", text = r))
    auto_ints <- as.integer(auto_ints)
    r <- "auto"
  }
  
  tscales_all <- attr(data, "time.scales")
  breaks_old <- attr(data, "breaks")
  
  
  
  ## breaks --------------------------------------------------------------------
  
  if (!is.null(breaks_old)) checkBreaksList(data, breaks_old)
  if (is.null(breaks)) breaks <- breaks_old
  
  checkBreaksList(data, breaks)
  
  ## hmm - will later on set breaks on the found survival scale
  if (!is.null(e1.breaks))  checkBreaksList(data, e1.breaks)
  
  ## prep & subset data --------------------------------------------------------
  subset <- substitute(subset)
  subset <- evalLogicalSubset(data, subset)
  
  x <- setDT(data[subset, ])
  forceLexisDT(x, breaks = breaks_old, allScales = tscales_all)
  
  ## ensure variables to merge pophaz datas by are kept ------------------------
  ## NOTE: temp var names avoid conflicts down the line
  avoid <- unique(c(names(data), names(x), names(pophaz), names(e1.pophaz)))
  
  pophaz_vars <- c(names(pophaz), names(e1.pophaz))
  pophaz_vars <- setdiff(pophaz_vars, c(tscales_all, "haz"))
  pophaz_vars <- intersect(pophaz_vars, names(x))
  pophaz_vars_tmp <- makeTempVarName(names = avoid, pre = pophaz_vars)
  if (!length(pophaz_vars)) {
    pophaz_vars_tmp <- NULL
  } else {
    pophaz_vars_wh <- which(pophaz_vars %in% names(pophaz))
    if (sum(pophaz_vars_wh)) {
      setnames(pophaz, old = pophaz_vars[pophaz_vars_wh], 
               new = pophaz_vars_tmp[pophaz_vars_wh])
    }
    pophaz_vars_wh <- which(pophaz_vars %in% names(e1.pophaz))
    if (sum(pophaz_vars_wh)) {
      setnames(e1.pophaz, old = pophaz_vars[pophaz_vars_wh], 
               new = pophaz_vars_tmp[pophaz_vars_wh])
    }
    x[, (pophaz_vars_tmp) := copy(.SD), .SDcols = pophaz_vars]
  }
  
  ## determine printing & adjusting vars ---------------------------------------
  adSub <- substitute(adjust)
  foList <- usePopFormula(formula, adjust = adSub, data = x, enclos = PF__, 
                          Surv.response = "either")
  
  ## will avoid conflicts using temp names for tabulating variables
  adjust_vars <- names(foList$adjust)
  print_vars <- names(foList$print)
  by_vars <- c(print_vars, adjust_vars)
  
  avoid <- unique(c(names(data), names(x), names(pophaz), names(e1.pophaz)))
  adjust_vars_tmp <- makeTempVarName(names = avoid, pre = adjust_vars)
  if (!length(adjust_vars)) adjust_vars_tmp <- NULL
  avoid <- unique(c(names(data), names(x), names(pophaz), names(e1.pophaz)))
  print_vars_tmp <- makeTempVarName(names = avoid, pre = print_vars)
  if (!length(print_vars)) print_vars_tmp <- NULL
  by_vars_tmp  <- c(print_vars_tmp, adjust_vars_tmp)
  
  
  lex_vars <- c("lex.id", tscales_all, "lex.dur", "lex.Cst", "lex.Xst")
  setcolsnull(x, keep = c(lex_vars, pophaz_vars_tmp), soft = FALSE)
  if (length(adjust_vars) > 0L) x[, (adjust_vars_tmp) := foList$adjust]
  if (length(print_vars) > 0L) x[, (print_vars_tmp) := foList$print]
  
  ## formula for survtab: we estimate survivals by all levels of both
  ## print and adjust; adjusting here means computing directly adjusted
  ## estimates of the mean survival time, so mean survival times are
  ## weighted later on.
  
  formula <- paste0(deparse(formula[[2L]]), " ~ ")
  if (length(c(adjust_vars_tmp, print_vars_tmp)) > 0L) {
    formula <- paste0(formula, paste0(c(print_vars_tmp, adjust_vars_tmp), 
                                      collapse = " + "))
  } else {
    formula <- paste0(formula, "1")
  }
  formula <- as.formula(formula)
  
  ## detect survival time scale ------------------------------------------------
  tscale_surv <- detectSurvivalTimeScale(lex = x, values = foList$y$time)
  
  ## check weights & adjust ----------------------------------------------------
  test_obs <- x[, .(obs=.N),  keyby=eval(TF__$by_vars_tmp)]
  if (length(by_vars)) setnames(test_obs, by_vars_tmp, by_vars)
  if (length(weights) && !length(adjust_vars)) {
    weights <- NULL
    warning("Replaced weights with NULL due to not supplying variables to ",
            "adjust by.")
  }
  mwDTtest <- makeWeightsDT(test_obs, values = list("obs"), print = print_vars,
                            adjust = adjust_vars, weights = weights, 
                            internal.weights.values = "obs")
  if (length(by_vars)) setnames(test_obs, by_vars, by_vars_tmp)
  
  ## figure out extrapolation breaks -------------------------------------------
  ## now that the survival time scale is known this can actually be done.
  
  if (is.null(e1.breaks)) {
    e1.breaks <- copy(breaks[tscale_surv])
    addBreaks <- max(e1.breaks[[tscale_surv]]) + 
      c(seq(0,1,1/12), seq(1.2, 1.8, 0.2), 2:19, seq(20, 50, 5))
    e1.breaks[[tscale_surv]] <- unique(c(e1.breaks[[tscale_surv]], addBreaks))
    
    checkBreaksList(x, e1.breaks)
  }
  if (!tscale_surv %in% names(e1.breaks)) {
    stop("The survival time scale must be included in the list of breaks ",
         "to extrapolate by ('e1.breaks').")
  }
  if (!all(breaks[[tscale_surv]] %in% e1.breaks[[tscale_surv]])) {
    stop("The vector of breaks in 'breaks' for the survival time scale MUST",
         "be a subset of the breaks for the survival time scale in ",
         "'e1.breaks'. E.g. the former could be 0:10 and the latter 0:100.")
  }
  
  if (verbose) {
    cat("Time taken by prepping data:", timetaken(pt), "\n")
  }
  
  
  ## compute observed survivals ------------------------------------------------
  ## NOTE: do not adjust here; adjust in original formula means weighting
  ## the mean survival time results.
  
  st <- survtab(formula, data = x, breaks = breaks, 
                pophaz = pophaz,
                relsurv.method = "e2",
                surv.type = "surv.rel", 
                surv.method = surv.method)
  
  st_keep_vars <- c(by_vars_tmp, "Tstop", "r.e2", "surv.obs")
  all_names_present(
    st,  st_keep_vars, 
    msg = paste0("Internal error: expected to have variables ",
                 "%%VARS%% after computing observed survivals ",
                 "but didn't. Blame the package maintainer if you ",
                 "see this.")
  )
  setcolsnull(st, keep = st_keep_vars, colorder = TRUE)
  setDT(st)
  setkeyv(st, c(by_vars_tmp, "Tstop"))
  st[, "Tstart" := c(0, Tstop[-.N]), by = eval(by_vars_tmp)]
  
  ## decumulate for later cumulation
  st[, c("r.e2", "surv.obs") := lapply(.SD, function(col) col/c(1, col[-.N])), 
     by = eval(by_vars_tmp),
     .SDcols = c("r.e2", "surv.obs")
     ]
  
  
  if (verbose) {
    cat("Time taken by estimating relative survival curves:", 
        timetaken(pt), "\n")
  }
  
  ## compute overall expected survival -----------------------------------------
  ## 1) take only those individuals that were diagnosed in the time window
  ##    defined by breaks list in argument 'breaks'
  pt <- proc.time()
  setkeyv(x, c("lex.id", tscale_surv))
  tol <- .Machine$double.eps^0.5
  xe <- unique(x, by = key(x))[x[[tscale_surv]] < TF__$tol, ] ## pick rows with entry to FU
  
  if (length(breaks) > 1L) {
    ## e.g. a period window was defined and we only use subjects
    ## entering follow-up in the time window.
    breaks_drop_tmp <- setdiff(names(breaks), tscale_surv)
    breaks_drop_tmp <- breaks[breaks_drop_tmp]
    breaks_drop_tmp <- lapply(breaks_drop_tmp, range)
    
    expr <- mapply(function(ch, ra) {
      paste0("between(", ch, ", ", ra[1], ", ", ra[2] - tol, ", incbounds = TRUE)")
    }, ch = names(breaks_drop_tmp), ra = breaks_drop_tmp, SIMPLIFY = FALSE)
    
    expr <- lapply(expr, function(e) eval(parse(text = e), envir = xe))
    setDT(expr)
    expr <- expr[, rowSums(.SD)]  == ncol(expr)
    xe <- xe[expr, ]
  }
  
  xe <- x[lex.id %in% unique(xe[["lex.id"]])]
  forceLexisDT(xe, breaks = breaks_old, allScales = tscales_all, key = FALSE)
  
  ## 2) compute Ederer I expected survival curves from T = 0 till e.g. T = 100
  e1 <- comp_e1(xe, breaks = e1.breaks, pophaz = e1.pophaz, immortal = TRUE, 
                survScale = tscale_surv, by = by_vars_tmp, id = "lex.id")
  setnames(e1, tscale_surv, "Tstop")
  e1[, "Tstart" := c(0, Tstop[-.N]), by = eval(by_vars_tmp)]
  e1[, "surv.int" := cut(Tstart, breaks = e1.breaks[[tscale_surv]], 
                         right = FALSE, labels = FALSE)]
  e1[, "delta" := Tstop - Tstart]
  
  ## decumulate for later cumulation
  e1[, "surv.exp" := surv.exp/c(1, surv.exp[-.N]), by = eval(by_vars_tmp)]
  
  if (verbose) {
    cat("Time taken by computing overall expected survival curves:", 
        timetaken(pt), "\n")
  }
  
  ## compute counts of subjects ------------------------------------------------
  ## these correspond to the counts of patients for which expected survival
  ## was computed. If observed survival is e.g. a period estimated curve,
  ## we only use subjects entering follow-up in the period window.
  N_subjects <- xe[!duplicated(lex.id)][, 
                                        list(obs=.N), 
                                        keyby=eval(by_vars_tmp)
                                        ]
  
  ## combine all estimates into one data set -----------------------------------
  pt <- proc.time()
  
  st[, "surv.int" := cut(Tstart, breaks = e1.breaks[[tscale_surv]], 
                         right = FALSE, labels = FALSE)]
  
  x <- merge(e1, st[, .SD, .SDcols = c(by_vars_tmp, "surv.int", "r.e2", "surv.obs")], 
             by = c(by_vars_tmp,"surv.int"), all = TRUE)
  setkeyv(x, c(by_vars_tmp, "surv.int"))
  
  ## extrapolation RSR definition ----------------------------------------------
  if (is.numeric(r)) {
    ## manually given RSR for extrapolated part of the obs.surv curve
    ## here it is assumed that r is annualized
    set(x, j = "last.p.e2", value = r^x[["delta"]]) 
    
    
  } else {
    ## add last non-NA values as separate column
    
    st <- st[, .SD[(.N-TF__$auto_ints+1):.N], by = eval(by_vars_tmp)]
    
    st[, "delta" := Tstop - Tstart]
    st[, "r.e2" := r.e2^(1/delta)] ## "annualized" RSRs
    
    ## mean annualized RSR in last N intervas by strata
    st <- st[, .(last.p.e2 = mean(r.e2)), by = eval(by_vars_tmp)]
    st[, "last.p.e2" := pmin(1, last.p.e2)]
    if (verbose) {
      cat("Using following table of mean RSR estimates",
          "(scaled to RSRs applicable to a time interval one",
          "unit of time wide, e.g. one year or one day)",
          "based on", auto_ints, "interval(s) from the end of the relative",
          "survival curve by strata: \n")
      prST <- data.table(st)
      setnames(prST, c(by_vars_tmp, "last.p.e2"), c(by_vars, "RSR"))
      print(prST)
    }
    
    if (length(by_vars_tmp)) {
      x <- merge(x, st, by = by_vars_tmp, all = TRUE)
    } else {
      set(x, j = "last.p.e2", value = st$last.p.e2)
    }
    x[, "last.p.e2" := last.p.e2^(delta)] ## back to non-annualized RSRs
    ## enforce RSR in extrapolated part of observed curve to at most 1
    x[, "last.p.e2" := pmin(last.p.e2, 1)]
  }
  
  x[is.na(r.e2), "r.e2" := last.p.e2]
  x[, "surv" := r.e2*surv.exp]
  # setnames(x, "surv.obs", "surv")
  # x[is.na(surv), "surv" := surv.exp*last.p.e2]
  
  ## cumulate again
  setkeyv(x, c(by_vars_tmp, "surv.int"))
  x[, c("surv", "surv.exp") := lapply(.SD, cumprod),
    .SDcols = c("surv", "surv.exp"), by = eval(by_vars_tmp)]
  
  x2 <- copy(x)
  x[, "surv.exp" := NULL]
  x2[, "surv" := NULL]
  setnames(x2, "surv.exp", "surv")
  x <- rbind(x, x2)
  x[, "survmean_type" := rep(c("est", "exp"), each = nrow(x2))]
  
  setcolsnull(
    x, 
    keep = c(by_vars_tmp, "survmean_type", 
             "surv.int", "Tstart", "Tstop", 
             "delta", "surv", "surv.exp"),
    colorder = TRUE
  )
  
  ## check curve convergence to zero -------------------------------------------
  ## a good integration is based on curves that get very close to 
  ## zero in the end
  mi <- x[, .(surv = round(min(surv),4)*100), 
          keyby = eval(c(by_vars_tmp, "survmean_type"))]
  
  if (any(mi$surv > 1)) {
    warning("One or several of the curves used to compute mean survival times ",
            "or expected mean survival times was > 1 % at the lowest point. ",
            "Mean survival estimates may be significantly biased. To avoid ",
            "this, supply breaks to 'e1.breaks' which make the curves longer ",
            ", e.g. e1.breaks = list(FUT = 0:150) where time scale FUT ",
            "is the survival time scale (yours may have a different name).")
  }
  mi[, "surv" := paste0(formatC(surv, digits = 2, format = "f"), " %")]
  mi[, "survmean_type" := factor(survmean_type, c("est", "exp"),
                                 c("Observed", "Expected"))]
  setnames(mi, c("survmean_type", "surv"), 
           c("Obs./Exp. curve", "Lowest value"))
  if (length(by_vars)) setnames(mi, by_vars_tmp, by_vars)
  if (verbose) {
    cat("Lowest points in observed / expected survival curves by strata:\n")
    print(mi)
  }
  
  ## integrating by trapezoid areas --------------------------------------------
  ## trapezoid area: WIDTH*(HEIGHT1 + HEIGHT2)/2
  ## so we compute "average interval survivals" for each interval t_i
  ## and multiply with interval length.
  
  setkeyv(x, c(by_vars_tmp, "survmean_type",  "Tstop"))
  sm <- x[, .(survmean = sum(delta*(surv + c(1, surv[-.N]))/2L)), 
          keyby = c(by_vars_tmp, "survmean_type")]
  
  ## cast ----------------------------------------------------------------------
  
  sm <- cast_simple(sm, columns = "survmean_type", 
                    rows = by_vars_tmp, values = "survmean")
  
  ## add numbers of subjects, compute YPLL -------------------------------------
  setkeyv(sm, by_vars_tmp); setkeyv(N_subjects, by_vars_tmp)
  sm[, "obs" := N_subjects$obs]
  sm[, "YPLL" := (exp-est)*obs]
  
  
  ## adjusting -----------------------------------------------------------------
  
  sm <- makeWeightsDT(sm, values = list(c("est", "exp", "obs", "YPLL")),
                      print = print_vars_tmp, adjust = adjust_vars_tmp,
                      weights = weights, internal.weights.values = "obs")
  if (length(adjust_vars)) {
    vv <- c("est", "exp", "obs", "YPLL")
    sm[, c("est", "exp") := lapply(.SD, function(col) col*sm$weights), 
       .SDcols = c("est", "exp")]
    sm <- sm[, lapply(.SD, sum), .SDcols = vv, by = eval(print_vars_tmp)]
  }
  
  if (verbose) {
    cat("Time taken by final touches:", timetaken(pt), "\n")
  }
  
  ## final touch ---------------------------------------------------------------
  if (length(print_vars)) setnames(sm, print_vars_tmp, print_vars)
  
  at <- list(call = match.call(), 
             formula = attr_form,
             print = print_vars, 
             adjust = adjust_vars, 
             tprint = print_vars_tmp, 
             tadjust = adjust_vars_tmp,
             breaks = breaks, 
             e1.breaks = e1.breaks, 
             survScale = tscale_surv,
             curves = copy(x))
  setattr(sm, "class", c("survmean","data.table", "data.frame"))
  setattr(sm, "survmean.meta", at)
  if (!return_DT()) setDFpe(sm)
  return(sm[])
}

