testthat::context("utility functions")

testthat::test_that("subsetting in ltable works and ltable has no side effects", {
  popEpi:::skip_normally()
  
  sr <- popEpi::sire[1:100, ]
  set.seed(1L)
  sr[, sex := rbinom(.N, 1, prob = 0.5)]
  sr[c(1, 50), sex := NA]
  
  setkeyv(sr, "bi_date")
  old_sr <- copy(sr)
  
  lt1 <- ltable(sr, by = "sex", subset = sex == 0, na.rm = TRUE)
  lt2 <- ltable(sr, by = "sex", subset = sex == 1, na.rm = TRUE)
  lt3 <- ltable(sr, by = "sex", na.rm = TRUE)
  
  testthat::expect_equal(lt3$obs, c(lt1[1, ]$obs, lt2[2, ]$obs))
  testthat::expect_true(all.equal(sr, old_sr))
  
})



testthat::test_that("ltable works with NA values", {
  
  popEpi:::skip_normally()
  
  sr <- setDT(popEpi::sire[1:100, ])
  set.seed(1L)
  sr[, sex := rbinom(.N, 1, prob = 0.5)]
  sr[c(1, 50), sex := NA]
  
  lt1 <- ltable(sr, by = "sex", na.rm = FALSE)
  lt2 <- ltable(sr, by = "sex", na.rm = TRUE)
  
  testthat::expect_equal(lt1[!is.na(sex),], lt2)
  
})



testthat::test_that("evalPopArg produces intended results",{
  set.seed(1L)
  dt <- data.table(a = rbinom(10, 100, 0.25), b = 1:2, c = 1:5)
  
  tf <- function(x=dt, arg) {
    
    as <- substitute(arg)
    byTab <- evalPopArg(x, arg = as, enclos = parent.frame(1L))
    
    x[, list(sum = sum(a)), by = byTab]
    
  }
  
  ## symbol
  t1 <- tf(arg=b)
  
  ## name string
  t2 <- tf(arg="b")
  
  testthat::expect_equal(t1$sum, c(127, 131))
  testthat::expect_equal(t1, t2)
  
  ## list of symbols / expressions
  t3 <- tf(arg=list(b, c))
  
  ## name strings
  t4 <- tf(arg=c("b", "c"))
  
  ## object containing name strings
  byVars <- c("b", "c")
  t5 <- tf(arg=byVars)
  
  testthat::expect_equal(t4$sum, c(22,24,26,31,21, 31,32,27,26,18))
  testthat::expect_equal(t4, t3)
  testthat::expect_equal(t4, t5)
  
  ## list of symbols / expressions
  t6 <- tf(arg=list(var1 = b,c, cut(c,3)))
  testthat::expect_equal(names(t6), c("var1", "c", "cut", "sum"))
  
  
  ## NULL object
  byVars <- NULL
  t7 <- tf(arg=byVars)
  t8 <- tf(arg=NULL)
  testthat::expect_equal(t7, t8)
  
  ## a list of predetermined values
  byList <- as.list(dt[, list(b, var1 = c)])
  t9 <- tf(arg=byList)
  
  ## list without any names
  byList <- list(dt$b, dt$c)
  t10<- tf(arg=byList)
  
  ## partially named list
  byList <- list(var1 = dt$b, dt$c)
  t11<- tf(arg=byList)
  
  testthat::expect_equal(t9$sum, t10$sum)
  testthat::expect_equal(t10$sum, t11$sum)
  testthat::expect_equal(names(t11), c("var1", "BV2", "sum"))
  
  
  t12 <- tf(arg=list(V0=dt$b, dt$c))
  byList <- list(V0 = dt$b, dt$c)
  t13 <- tf(arg=byList)
  testthat::expect_equal(t12, t13)
  
  ## pre-substituted list
  bl <- substitute(byList)
  t14 <- tf(arg = bl)
  testthat::expect_equal(t12, t14)
  
  ## pre-substituted vector of names
  nv <- c("a", "b")
  nvs <- substitute(nv)
  t15a <- tf(arg = nv)
  t15b <- tf(arg = nvs)
  testthat::expect_equal(t15a, t15b)
  
  ## nested functions
  tf2 <- function(a, x = dt) {
    tf(x = x, arg = a)
  }
  
  nv <- c("a", "b")
  nvs <- substitute(nv)
  t15a <- tf2(a = nv)
  t15b <- tf2(a = nvs)
  testthat::expect_equal(t15a, t15b)
})


testthat::test_that("cutLowMerge merges succesfully what is intended", {
  popEpi:::skip_normally()
  all_names_present(popEpi::popmort, c("sex", "year", "agegroup", "haz"))
  all_names_present(popEpi::sire, c("sex", "bi_date", "dg_date", "ex_date", "status"))
  
  pm <- copy(popEpi::popmort)
  pm[, haz := rbinom(.N, 100, 0.5)/1e5L]
  
  sr <- popEpi::sire[1:100,]
  setDT(sr)
  sr1 <- lexpand(sr, birth = bi_date, entry = dg_date, exit = ex_date,
                 status = status, fot = seq(0, 5, 1/12))
  sr1 <- data.table(sr1)
  setattr(sr1, "class", c("Lexis", "data.table", "data.frame"))
  
  sr1[, year := per + 0.5*lex.dur]
  sr1[, agegroup := age + 0.5*lex.dur]
  
  sr2 <- cutLowMerge(sr1, pm,
                     by.x = c("sex", "per", "age"), 
                     by.y = c("sex", "year", "agegroup"),
                     all.x = TRUE, all.y = FALSE, old.nums = TRUE)
  
  sr3 <- copy(sr2)
  sr3[, haz := NULL]
  
  sr4 <- lexpand(sr, birth = bi_date, entry = dg_date, exit = ex_date,
                 status = status, fot = seq(0, 5, 1/12), pophaz = pm, pp = FALSE)
  testthat::expect_equal(sr1, sr3, check.attributes = FALSE)
  testthat::expect_equal(sr2$haz*1e5L, sr4$pop.haz*1e5L, check.attributes = FALSE)
  
  sr1[, year := popEpi:::cutLow(year, breaks = sort(unique(pm$year)))]
  sr1[, agegroup := popEpi:::cutLow(agegroup, breaks = sort(unique(pm$agegroup)))]
  
  sr5 <- merge(sr1, pm, by = c("sex", "year", "agegroup"))
  setDT(sr5)
  setkey(sr5, lex.id, fot)
  
  testthat::expect_equal(sr4$haz*1e5L, sr5$pop.haz*1e5L, check.attributes = FALSE)
})

testthat::test_that("detectEvents works as intended", {
  popEpi:::skip_normally()
  x <- sire[dg_date<ex_date,]
  x <- lexpand(x, birth = bi_date, entry = dg_date, exit = ex_date,
               status = status %in% 1:2, pophaz = data.table(popEpi::popmort),
               breaks = list(fot = seq(0,5,1/12), per = c(2007,2012), age = c(50,90)),
               drop = TRUE)
  ## this will only work with drop = TRUE.
  setkeyv(x, c("lex.id", "fot", "per", "age"))
  
  ## this leaves observations cut short due to age or period censoring to
  ## really be censoring.
  x[, event := detectEvents(x, breaks = attr(x, "breaks")["fot"], by = "lex.id")]
  
  x[, alt.event := 0L]
  x[!duplicated(lex.id, fromLast = TRUE), alt.event := 2L]
  x[lex.Cst != lex.Xst, alt.event := 1L]
  x[fot+lex.dur == 5L, alt.event := 0L]
  
  testthat::expect_equal(x$event, x$alt.event)
  
})

testthat::test_that("comp_pp_weighted_figures produces intended results", {
  set.seed(1L)
  x <- sire[dg_date < ex_date,][sample(x = .N, size = 5L, replace = FALSE),]
  x <- lexpand(x, birth = bi_date, entry = dg_date, exit = ex_date,
               status = status %in% 1:2, pophaz = data.table(popEpi::popmort),
               breaks = list(fot = seq(0,20,1/12), per = 1993:2013, age = 0:200))
  x[, event := detectEvents(x, breaks = attr(x, "breaks"), by = "lex.id")]
  
  l <- comp_pp_weighted_figures(lex = x, haz = "pop.haz", pp = "pp", event.ind = "event", by = "lex.id")
  x[, names(l) := l]
  
  testthat::expect_equal(x[event %in% 1:2, pp], x[event %in% 1:2, from0to0.pp + from0to1.pp])
  testthat::expect_equal(x[event %in% 1:2, sum(pp)], x[, sum(from0to0.pp + from0to1.pp)])
  testthat::expect_equal(x[, lex.dur*pp], x$ptime.pp)
  testthat::expect_equal(x[, lex.dur*pp*pop.haz], x$d.exp.pp)
  testthat::expect_equal(x[event == 1L, pp^2], x[event == 1L,]$from0to1.pp.2)
  
})


testthat::test_that("evalPopFormula & usePopFormula output is stable", {
  evalPopFormula <- popEpi:::evalPopFormula
  usePopFormula <- popEpi:::usePopFormula
  
  x <- sire[1:5, ]
  x[, "status" := c(1,1,0,1,1)]
  x[, "sex" := c(1,0,1,0,1)]
  x <- lexpand(x, birth = bi_date, entry = dg_date, exit = ex_date,
               status = status)
  
  f1a <- Surv(fot, lex.Xst) ~ 1
  f1b <- Surv(fot, event = lex.Xst) ~ 1
  f2 <- Surv(fot, lex.Xst) ~ sex
  f3 <- Surv(fot, lex.Xst) ~ sex + adjust(factor(sex + 1))
  f4 <- Surv(fot, lex.Xst) ~ adjust(factor(sex + 1))
  f5 <- lex.Xst ~ 1
  f6 <- lex.Xst ~ sex
  f7 <- lex.Xst ~ sex + adjust(factor(sex + 1))
  f8 <- lex.Xst ~ adjust(factor(sex + 1))
  f9 <- lex.Xst ~ factor(sex)
  
  TF <- environment()
  
  res <- data.table(time = rep(0, 5), status = c(1,1,0,1,1), sex = c(1,0,1,0,1))
  res[["factor(sex + 1)"]] <- factor(res$sex + 1)
  res$lex.Xst <- as.integer(c(1,1,0,1,1))
  
  
  ## evalPopFormula
  r1a <- evalPopFormula(f1a, data = x, enclos = TF, Surv.response = TRUE)
  r1b <- evalPopFormula(f1b, data = x, enclos = TF, Surv.response = TRUE)
  setattr(r1a, "formula", attr(r1b, "formula"))
  testthat::expect_equal(r1a, r1b)
  testthat::expect_equal(data.table(r1a), res[, list(time, status)])
  
  r5 <- evalPopFormula(f5, data = x, enclos = parent.frame(1L), Surv.response = FALSE)
  r6 <- evalPopFormula(f6, data = x, enclos = parent.frame(1L), Surv.response = FALSE)
  testthat::expect_equal(r5$lex.Xst, c(1,1,0,1,1))
  testthat::expect_equal(data.table(r6), res[, list(lex.Xst, sex)])
  
  ## model-type naming of columns
  r9 <- evalPopFormula(f9, data = x, enclos = parent.frame(1L), Surv.response = FALSE)
  testthat::expect_equal(data.table(r9), res[, list(lex.Xst, "factor(sex)" = factor(sex))])
  
  ## multiple variables, model-type naming of columns with adjust
  r3 <- evalPopFormula(f3, data = x, enclos = parent.frame(1L), Surv.response = TRUE)
  testthat::expect_equivalent(r3, res[, .SD, .SDcols = names(r3)])
  
  
  #### only the survival time scale as response
  fa <- fot ~ 1
  fb <- fot ~ sex
  fc <- fot ~ sex + adjust(factor(sex + 1))
  fd <- fot ~ adjust(factor(sex + 1))
  
  ra <- evalPopFormula(fa, data = x, enclos = TF, Surv.response = "either")
  testthat::expect_equivalent(ra, x[, .(fot, lex.Xst)])
  rb <- evalPopFormula(fb, data = x, enclos = parent.frame(1L), Surv.response = FALSE)
  testthat::expect_equivalent(rb, x[, .(fot, sex)])
  rc <- evalPopFormula(fc, data = x, enclos = parent.frame(1L), Surv.response = "either")
  testthat::expect_equivalent(rc, x[, .(fot, lex.Xst, sex, factor(sex + 1))])
  rd <- evalPopFormula(fd, data = x, enclos = TF, Surv.response = FALSE)
  testthat::expect_equivalent(rd, x[, .(fot, factor(sex + 1))])
  
  ## usePopFormula
  
  r3 <- usePopFormula(f3, data = x, enclos = parent.frame(2L), Surv.response = TRUE)
  testthat::expect_equivalent(r3, 
                    list(y = res[, list(time, status)], 
                         print = res[, list(sex)], 
                         adjust = res[, "factor(sex + 1)", with = FALSE],
                         formula = f3) 
  )
  r4 <- usePopFormula(f4, data = x, enclos = parent.frame(2L), Surv.response = TRUE)
  testthat::expect_equivalent(r4, 
                    list(y = res[, list(time, status)], 
                         print = NULL, 
                         adjust = res[, "factor(sex + 1)", with = FALSE],
                         formula = f4) 
  )
  r6 <- usePopFormula(f6, data = x, enclos = parent.frame(2L), Surv.response = FALSE)
  testthat::expect_equivalent(r6, 
                    list(y = res[, list(lex.Xst)], 
                         print = res[, list(sex)], 
                         adjust = NULL,
                         formula = f6) 
  )
  
  r7 <- usePopFormula(f7, data = x, enclos = parent.frame(2L), Surv.response = FALSE)
  testthat::expect_equivalent(r7, 
                    list(y = res[, list(lex.Xst)], 
                         print = res[, list(sex)], 
                         adjust = res[, "factor(sex + 1)", with = FALSE],
                         formula = f7) 
  )
  r8 <- usePopFormula(f8, data = x, enclos = parent.frame(2L), Surv.response = FALSE)
  testthat::expect_equivalent(r8, 
                    list(y = res[, list(lex.Xst)], 
                         print = NULL, 
                         adjust = res[, "factor(sex + 1)", with = FALSE],
                         formula = f8) 
  )
  r9 <- usePopFormula(lex.Xst ~ sex, data = x, adjust = quote(factor(sex + 1)),
                      enclos = parent.frame(2L), Surv.response = FALSE) 
  testthat::expect_equivalent(r9, 
                    list(y = res[, list(lex.Xst)], 
                         print = res[, list(sex)], 
                         adjust = res[, "factor(sex + 1)", with = FALSE],
                         formula = lex.Xst ~ sex)
  )
  testthat::expect_equal(lapply(r9, names), list(y = "lex.Xst", print = "sex", adjust = "factor(sex + 1)", formula = NULL))
  
  r9 <- usePopFormula(lex.Xst ~ as.numeric(sex), data = x, adjust = quote(list(factor(sex + 1), factor(sex - 1))),
                      enclos = parent.frame(2L), Surv.response = FALSE) 
  
  testthat::expect_equal(lapply(r9, names), list(y = "lex.Xst", print = "as.numeric(sex)", 
                                       adjust = c("factor(sex + 1)", "factor(sex - 1)"), formula = NULL))
  
  
  ra <- usePopFormula(fa, data = x, 
                      adjust = quote(list(factor(sex + 1), factor(sex - 1))),
                      enclos = parent.frame(2L), Surv.response = FALSE) 
  
  testthat::expect_equal(lapply(ra, names), 
               list(y = "fot", print = NULL, 
                    adjust = c("factor(sex + 1)", "factor(sex - 1)"), 
                    formula = NULL))
  
  
  rb <- usePopFormula(fb, data = x, 
                      adjust = quote(list(factor(sex + 1), factor(sex - 1))),
                      enclos = parent.frame(2L), Surv.response = FALSE) 
  testthat::expect_equal(lapply(rb, names), 
               list(y = "fot", print = "sex", 
                    adjust = c("factor(sex + 1)", "factor(sex - 1)"), 
                    formula = NULL))
  
  rc <- usePopFormula(fc, data = x, 
                      adjust = NULL,
                      enclos = parent.frame(2L), Surv.response = "either") 
  testthat::expect_equal(lapply(rc, names), 
               list(y = c("time", "status"), print = "sex", 
                    adjust = "factor(sex + 1)", 
                    formula = NULL))
  
  rd <- usePopFormula(fd, data = x, 
                      adjust = NULL,
                      enclos = parent.frame(2L), Surv.response = FALSE) 
  testthat::expect_equal(lapply(rd, names), 
               list(y = "fot", print = NULL, 
                    adjust = "factor(sex + 1)", 
                    formula = NULL))
  
  ## usePopFormula with "either" response
  useForms <- paste0("f", 2:9)
  useForms <- c("f1a", "f1a", useForms)
  useForms <- intersect(useForms, ls())
  TF <- environment()
  l <- list()
  for (k in seq_along(useForms)) {
    l[[k]] <- usePopFormula(get(useForms[k], envir = TF), data = x, 
                            adjust = NULL,
                            enclos = TF, Surv.response = "either") 
  }
  
  
  
  
})





testthat::test_that("fractional years computation works", {
  library("data.table")
  c <- paste0("2004-", c("01-01", "07-01", "12-31", "02-01"))
  D <- as.Date(c)
  
  testthat::expect_equal(get.yrs(c), get.yrs(D))
  
  yl <- 365.242199
  my <- year(D) + (yday(D) - 1L)/yl
  
  testthat::expect_equal(as.numeric(get.yrs(D)), my)
  
  yl <- ifelse(is_leap_year(year(D)), 366L, 365L)
  my <- year(D) + (yday(D) - 1L)/yl
  
  testthat::expect_equal(as.numeric(get.yrs(D, year.length = "actual")), my)
})





testthat::test_that("subsetDTorDF works as intended", {
  
  dt <- data.table::data.table(a = 1:5, b = 5:1)
  df <- data.frame(a = 1:5, b = 5:1)
  
  sub <- c(TRUE, TRUE, FALSE, FALSE, TRUE)
  col_nms <- rep("a", 50)
  settings <- list(
    list(subset = sub, select = NULL),
    list(subset = NULL, select = col_nms),
    list(subset = NULL, select = NULL),
    list(subset = sub, select = col_nms)
  )
  
  expected_df <- list(
    df[sub, ],
    df[, col_nms],
    df,
    df[sub, col_nms]
  )
  expected_dt <- list(
    dt[sub, ],
    dt[, .SD, .SDcols = col_nms],
    dt,
    dt[sub, .SD, .SDcols = col_nms]
  )
  
  unused <- lapply(seq_along(settings), function(i) {
    set <- settings[[i]]
    set[["data"]] <- dt
    sub_dt <- do.call(subsetDTorDF, set)
    set[["data"]] <- df
    sub_df <- do.call(subsetDTorDF, set)
    
    exp_df <- expected_df[[i]]
    exp_dt <- expected_dt[[i]]
    
    list(sub_dt = sub_dt, exp_dt = exp_dt, sub_df = sub_df, exp_df = exp_df)
    testthat::expect_equal(
      data.frame(sub_dt),
      data.frame(exp_dt)
    )
    testthat::expect_equal(
      sub_df,
      exp_df
    )
  })
  
  
})

















