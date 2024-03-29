#' @title Marginal piecewise parametric relative survival curve
#' @author Joonas Miettinen
#' @description Fit a marginal relative survival curve based on a \code{relpois} fit
#' @param object a \code{relpois} object
#' @details
#' Estimates a marginal curve, i.e. the average of all
#' possible individual curves. 
#' 
#' Only supported when the reserved \code{FOT} variable was used in \code{relpois}.
#' Computes a curve for each unique combination of covariates (e.g. 4 sets) 
#' and returns a weighted average curve based on the counts
#' of subjects for each combination (e.g. 1000, 125, 50, 25 respectively). 
#' Fairly fast when only categorical variables have been used, otherwise
#' go get a cup of coffee.
#' 
#' If delayed entry is present in data due to period analysis limiting,
#' the marginal curve is constructed only for those whose follow-up started
#' in the respective period.
#' @return
#' A `data.table` of relative survival curves.
#' @export 
#' @family relpois functions
#' 
#' @import data.table
#' @import Epi
#' @import stats
#' 
#' @examples
#' \donttest{
#' ## use the simulated rectal cancer cohort
#' data("sire", package = "popEpi")
#' ab <- c(0,45,55,65,70,Inf)
#' sire$agegr <- cut(sire$dg_age, breaks = ab, right = FALSE)
#'
#' BL <- list(fot= seq(0,10,1/12))
#' pm <- data.frame(popEpi::popmort)
#' x <- lexpand(sire, breaks=BL, pophaz=pm, 
#'              birth = bi_date, 
#'              entry = dg_date, exit = ex_date, 
#'              status  = status %in% 1:2)
#' 
#' rpm <- relpois(x, formula = lex.Xst %in% 1:2 ~ -1+ FOT + agegr, 
#'                fot.breaks=c(0,0.25,0.5,1:8,10))
#' pmc <- rpcurve(rpm)
#'
#' ## compare with non-parametric estimates
#' names(pm) <- c("sex", "per", "age", "haz")
#' x$agegr <- cut(x$dg_age, c(0,45,55,65,75,Inf), right = FALSE)
#' st <- survtab(fot ~ adjust(agegr), data = x, weights = "internal",
#'               pophaz = pm)
#'
#'
#' plot(st, y = "r.e2.as")
#' lines(y = pmc$est, x = pmc$Tstop, col="red")
#' }
#' 
#' 
#' 

rpcurve <- function(object) {
  
  ## appease R CMD CHECK
  Tstart <- FOT <- uni_id <- uni_n <- uni_w <- 
    lo <- hi <- lex.Xst <- est <- fot <- pop.haz <- delta <- 
    Tstop <- Tstar <- lex.id <- fot <- lex.multi <- pyrs <- NULL
  
  ## sanity checks -------------------------------------------------------------
  if (!inherits(object, "relpois")) {
    stop("object does not have class 'relpois'; see ?relpois")
  }
  
  if (!"FOT" %in% all.vars(object$formula)) {
    stop("No FOT variable in model formula; see Details in ?rpcurve")
  }
  
  
  ## collate surv.ints, breaks, deltas -----------------------------------------
  fot_levels <- as.factor(sort(as.character(unique(object$model$FOT))))
  fb <- sort(object$fot.breaks)
  fb <- data.table(Tstart = fb[-length(fb)], Tstop = fb[-1])
  fb[, FOT := fot_levels]
  fb[, delta := Tstop-Tstart]
  n_ints <- nrow(fb)
  
  ## model data / model matrix construction ------------------------------------
  modmat <- data.table(object$data)
  if (!"lex.multi" %in% names(modmat)) {
    setkey(modmat, lex.id, fot)
    modmat[, lex.multi := 1:.N, by = lex.id]
  }
  setkey(modmat, lex.id, lex.multi)
  modmat <- unique(modmat, by = "lex.id")
  modmat <- modmat[fot == 0] ## with period data, only non-delayed entries used
  modmat <- modmat[rep(1:.N, each = n_ints)]
  IDs <- modmat$lex.id
  n_matrows <- length(IDs)
  
  setcolsnull(modmat, keep = c(all.vars(object$formula)))
  setcolsnull(modmat, "FOT")
  modmat <- cbind(fb[, list(FOT=FOT, lex.dur = delta)], modmat)
  modmat[, "lex.Xst_factor" := factor(levels(as.factor(lex.Xst))[1])]
  modmat[, "lex.Xst" := NULL]
  data.table::setnames(modmat, "lex.Xst_factor", "lex.Xst")
  modmat[, "order" := 1:.N]
  
  ## unique sets of covariates only
  umodmat <- unique(modmat, by = setdiff(names(modmat), c("lex.dur","lex.Xst","order")))
  umodmat[, uni_id := rep(1:(nrow(umodmat)/n_ints), each=n_ints)]
    
  setkeyv(umodmat, setdiff(names(modmat), c("lex.dur","lex.Xst","order","uni_id")))
  setkeyv(modmat, setdiff(names(modmat), c("lex.dur","lex.Xst","order","uni_id")))
  
  uni_n <- umodmat[modmat, list(uni_n = .N / n_ints), by = "uni_id"][["uni_n"]]
  uni_n <- rep(uni_n, times = nrow(umodmat) / length(uni_n))
  data.table::set(umodmat, j = "uni_n", value = uni_n)
  
  setkeyv(umodmat, c("uni_id", "order"))
  mean_weights <- umodmat$uni_n
  IDs <- umodmat$uni_id
  
  setcolsnull(umodmat, delete=c("order","uni_id","uni_n"))
  
  modmat <- stats::model.matrix(object, data=umodmat)
  mmattrs <- attributes(modmat)
  mmattrs$dimnames <- mmattrs$dim <- NULL

  
  ## (unique covariate) subject-specific curve fits ----------------------------
  l <- split(data.table(modmat), IDs)
  l <- lapply(l, as.matrix)
  attrsetter <- function(obj) {
    mostattributes(obj) <- c(attributes(obj), mmattrs)
    obj
  }
  l <- lapply(l, attrsetter)

  epicumgetter <- function(x, ...) {
    Epi::ci.cum(ctr.mat = x, ..., alpha = 1-0.95, Exp = TRUE, ci.Exp = TRUE)
  }
  
  tab <- lapply(l, epicumgetter, obj=object, intl = fb$delta); rm(l)

  ## collate & compute relative survivals --------------------------------------
  tab <- lapply(tab, as.data.table)
  tab <- rbindlist(tab)
  setnames(tab, names(tab), c("est", "lo", "hi", "SE"))
  fot_values <- rep(fot_levels, times = nrow(tab) / length(fot_levels))
  data.table::set(tab, j = "FOT", value = fot_values)
  tab[, "uni_id" := IDs]
  tab[, "uni_w"  := mean_weights]
  Haz2RS <- function(x) {
    sum(exp(-x)*tab$uni_w)/n_matrows
  }
  tab <- tab[, lapply(list(est=est,lo=lo,hi=hi), `-`)]
  tab <- tab[, lapply(list(est=est,lo=lo,hi=hi), exp)]
  tab[, `:=`(est=est*mean_weights,lo=lo*mean_weights,hi=hi*mean_weights)]
  data.table::set(tab, j = "FOT", value = fot_values)
  tab <- tab[, lapply(list(est=est, lo=lo, hi=hi), sum), by = "FOT"]
  tab <- tab[
    j = lapply(list(est=est, lo=lo, hi=hi), function(x) {
      x / (n_matrows / n_ints)
    }), 
    by = "FOT"
    ]

  setkeyv(tab, "FOT")
  setkeyv(fb, "FOT")
  tab <- fb[tab, on = "FOT"]
  
  ## disabled CI computation in 0.2.2 due to lack of testing & certainty of 
  ## correctness
  setcolsnull(tab, c("lo", "hi"))
  
  setattr(tab, "class", c("data.table", "data.frame"))
  if (!return_DT()) setDFpe(tab)
  tab[]
}

#' @title Relative Poisson family object
#' @author Karri Seppa
#' @description A family object for GLM fitting of relative Poisson models
#' @format 
#' A list very similar to that created by \code{poisson()}.
#' @export
#' @family relpois functions
RPL <- data.table::copy(stats::poisson())
RPL$link <- "glm relative survival model with Poisson error"
RPL$linkfun <- function(mu, d.exp) log(mu - d.exp)
RPL$linkinv <- function(eta, d.exp) d.exp + exp(eta)

