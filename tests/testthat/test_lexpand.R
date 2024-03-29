testthat::context("lexpand sanity checks")


testthat::test_that("lexpand arguments can be passed as symbol, expression, character name of variable, and symbol of a character variable", {
  popEpi:::skip_normally()
  sr <- copy(sire)[dg_date < ex_date, ][1:100,]
  sr[, id := as.character(1:.N)]
  
  x <- lexpand(sr, fot = c(0, Inf), 
               birth = "bi_date", entry = dg_date, exit = "ex_date", 
               status = status %in% 1:2, id = "id")
  
  x2 <- lexpand(sr, fot = c(0, Inf), 
               birth = bi_date, entry = "dg_date", exit = ex_date, 
               status = status %in% 1:2, id = id)
  
  
  x3 <- lexpand(sr, fot = c(0, Inf), 
                birth = bi_date, entry = dg_date, exit = ex_date, 
                status = status %in% 1:2, id = id)
  
  testthat::expect_identical(x, x2)
  testthat::expect_identical(x, x3)
})



testthat::test_that("original total pyrs equals pyrs after splitting w/ large number of breaks", {
  popEpi:::skip_normally()
  x <- copy(sire)[dg_date < ex_date, ]
  x[, fot := get.yrs(ex_date, year.length = "actual") - get.yrs(dg_date, year.length = "actual")]
  totpyrs <- x[, sum(fot)]
  
  x <- lexpand(sire, birth  = bi_date, entry = dg_date, exit = ex_date,
               status = status %in% 1:2,
               breaks=list(fot= seq(0,20,1/12), age= c(0:100, Inf), per= c(1960:2014)))
  setDT(x)
  totpyrs_split <- x[, sum(lex.dur)]
  
  testthat::expect_equal(totpyrs, totpyrs_split, tolerance = 1e-05)
})



testthat::test_that("pp not added to data if pp = FALSE but pop.haz is", {
  x <- lexpand(sire[dg_date < ex_date, ][0:100], 
               birth  = bi_date, entry = dg_date, exit = ex_date,
               status = status %in% 1:2,
               breaks=list(fot=0:5), 
               pophaz=data.table(popEpi::popmort), 
               pp = FALSE)
  testthat::expect_equal(intersect(names(x), c("pp", "pop.haz")),  "pop.haz")
  testthat::expect_true(!any(is.na(x$pop.haz)))
})



testthat::test_that("lexpand produces the same results with internal/external dropping", {
  popEpi:::skip_normally()
  x <- lexpand(sire[dg_date < ex_date, ], 
               birth  = bi_date, entry = dg_date, exit = ex_date,
               status = status %in% 1:2,
               breaks=list(fot=0:5), pophaz=data.table(popEpi::popmort), 
               pp = TRUE, drop = TRUE)
  x2 <-lexpand(sire[dg_date < ex_date, ], 
               birth  = bi_date, entry = dg_date, exit = ex_date,
               status = status %in% 1:2,
               breaks=list(fot=0:5), pophaz=data.table(popEpi::popmort), 
               pp = TRUE, drop = FALSE)
  x2 <-popEpi:::intelliDrop(x2, breaks = list(fot=0:5), dropNegDur = TRUE)
  setDT(x)
  setDT(x2)
  popEpi:::doTestBarrage(dt1 = x, dt2 = x2, allScales = c("fot", "per", "age"))
})


testthat::test_that("lexpanding with aggre.type = 'unique' works", {
  popEpi:::skip_normally()
  
  BL <- list(fot = 0:5, age = seq(0,100, 5))
  ag1 <- lexpand(sire[dg_date < ex_date, ], 
                 breaks = BL, status = status,
                 birth = bi_date, entry = dg_date, exit = ex_date)
  setDT(ag1)
  ag1 <- ag1[, list(pyrs = sum(lex.dur), from0to1 = sum(lex.Xst == 1L)), 
           keyby = list(fot = popEpi:::cutLow(fot, BL$fot), 
                        age = popEpi:::cutLow(age, BL$age))]
  ag2 <- lexpand(sire[dg_date < ex_date, ], 
                 breaks = BL, status = status,
                 birth = bi_date, entry = dg_date, exit = ex_date,
                 aggre = list(fot, age), aggre.type = "unique")
  setDT(ag2)
  testthat::expect_equal(ag1$pyrs, ag2$pyrs)
  testthat::expect_equal(ag1$from0to1, ag2$from0to1)
  
})

testthat::test_that("lexpanding with aggre.type = 'cartesian' works; no time scales used", {
  popEpi:::skip_normally()
  
  BL <- list(fot = c(0,Inf))
  ag1 <- lexpand(sire[dg_date < ex_date, ], 
                 breaks = BL, status = status, entry.status = 0L,
                 birth = bi_date, entry = dg_date, exit = ex_date)
  setDT(ag1)
  forceLexisDT(ag1, breaks = BL, allScales = c("fot", "per", "age"))
  
  e <- quote(list(sex = factor(sex, 0:1, c("m", "f")),
            period = cut(get.yrs(dg_date), get.yrs(as.Date(paste0(seq(1970, 2015, 5), "-01-01"))))))
  ag1[, c("sex", "period") := eval(e)]
  ceejay <- do.call(CJ, lapply(ag1[, list(sex, period)], function(x) {if (is.factor(x)) levels(x) else unique(x)}))
  setkey(ceejay, sex, period); setkey(ag1, sex, period)
  ag1 <- ag1[ceejay, list(pyrs = sum(lex.dur), 
                          from0to1 = sum(lex.Xst == 1L)), by = .EACHI]
  ag1[is.na(pyrs), pyrs := 0]
  ag1[is.na(from0to1), from0to1 := 0]
  
  ag2 <- lexpand(sire[dg_date < ex_date, ],
                 breaks = BL, 
                 status = status, entry.status = 0L,
                 birth = bi_date, entry = dg_date, exit = ex_date,
                 aggre = list(sex = factor(sex, 0:1, c("m", "f")),
                              period = cut(get.yrs(dg_date), get.yrs(as.Date(paste0(seq(1970, 2015, 5), "-01-01"))))), 
                 aggre.type = "cartesian")
  
  setDT(ag2)
  setkeyv(ag1, c("sex", "period"))
  setkeyv(ag2, c("sex", "period"))
  testthat::expect_equal(sum(ag1$pyrs), sum(ag2$pyrs))
  testthat::expect_equal(sum(ag1$from0to1), sum(ag2$from0to1))
  testthat::expect_equal(ag1$pyrs, ag2$pyrs)
  testthat::expect_equal(ag1$from0to1, ag2$from0to1)
  
})

testthat::test_that("lexpanding with aggre.type = 'cartesian' works; only time scales used", {
  popEpi:::skip_normally()
  
  BL <- list(fot = 0:5, age = seq(0,100, 5))
  ag1 <- lexpand(sire[dg_date < ex_date, ], 
                 breaks = BL, status = status, entry.status = 0L,
                 birth = bi_date, entry = dg_date, exit = ex_date)
  setDT(ag1)
  forceLexisDT(ag1, breaks = BL, allScales = c("fot", "per", "age"))
  
  ag3 <- aggre(ag1, by = list(fot, age), type = "cartesian")
  setDT(ag3)
  
  ag4 <- aggre(ag1, by = list(fot, age), type = "unique")
  setDT(ag4)
  
  ag1[, `:=`(fot = try2int(popEpi:::cutLow(fot, c(BL$fot, Inf))), 
             age = try2int(popEpi:::cutLow(age, c(BL$age, Inf))))]
  ceejay <- do.call(CJ, lapply(BL, function(x) x[-length(x)]))
  setkey(ceejay, fot, age); setkey(ag1, fot, age)
  ag1 <- ag1[ceejay, list(pyrs = sum(lex.dur), 
                          from0to1 = sum(lex.Xst == 1L)), by = .EACHI]
  ag1[is.na(pyrs), pyrs := 0]
  ag1[is.na(from0to1), from0to1 := 0]
  
  ag2 <- lexpand(sire[dg_date < ex_date, ],
                 breaks = list(fot = 0:5, age = seq(0,100, 5)), 
                 status = status, entry.status = 0L,
                 birth = bi_date, entry = dg_date, exit = ex_date,
                 aggre = list(fot, age), aggre.type = "cartesian")
  
  setDT(ag2)
  setkeyv(ag1, c("fot", "age"))
  setkeyv(ag2, c("fot", "age"))
  setkeyv(ag3, c("fot", "age"))
  testthat::expect_equal(sum(ag1$pyrs), sum(ag3$pyrs))
  testthat::expect_equal(sum(ag1$from0to1), sum(ag3$from0to1))
  testthat::expect_equal(ag1$pyrs, ag3$pyrs)
  testthat::expect_equal(ag1$from0to1, ag3$from0to1)
  
  testthat::expect_equal(sum(ag1$pyrs), sum(ag2$pyrs))
  testthat::expect_equal(sum(ag1$from0to1), sum(ag2$from0to1))
  testthat::expect_equal(ag1$pyrs, ag2$pyrs)
  testthat::expect_equal(ag1$from0to1, ag2$from0to1)
  
})


testthat::test_that("lexpanding and aggregating to years works", {
  ag1 <- lexpand(sire[dg_date < ex_date, ], 
                 breaks = list(per=2000:2014), status = status,
                 birth = bi_date, entry = dg_date, exit = ex_date)
  setDT(ag1)
  ag1[, `:=`(per = as.integer(popEpi:::cutLow(per, 2000:2014)))]
  ag1 <- ag1[, list(pyrs = sum(lex.dur), from0to1 = sum(lex.Xst == 1L)), keyby = per]
  
  ag2 <- lexpand(sire[dg_date < ex_date, ], 
                 breaks = list(per = 2000:2014), status = status,
                 birth = bi_date, entry = dg_date, exit = ex_date,
                 aggre = list(per), aggre.type = "unique")
  setDT(ag2)
  ag3 <- lexpand(sire[dg_date < ex_date, ], 
                 breaks = list(per = 2000:2014, age = c(seq(0,100,5),Inf), fot = c(0:10, Inf)), 
                 status = status,
                 birth = bi_date, entry = dg_date, exit = ex_date,
                 aggre = list(y = per), aggre.type = "unique")
  setDT(ag3)
  testthat::expect_equal(ag1$pyrs, ag2$pyrs)
  testthat::expect_equal(ag1$from0to1, ag2$from0to1)
  testthat::expect_equal(ag1$pyrs, ag3$pyrs)
  testthat::expect_equal(ag1$from0to1, ag3$from0to1)
  
})

# Aggre check (to totpyrs) -----------------------------------------------------

testthat::test_that("lexpand aggre produces correct results", {
  popEpi:::skip_normally()
  x <- copy(sire)[dg_date < ex_date, ]
  x[, fot := get.yrs(ex_date, year.length = "actual") - get.yrs(dg_date, year.length = "actual")]
  totpyrs <- x[, sum(fot)]
  counts <- x[, .N, by = .(status)]
  
  x <- lexpand(sire[dg_date < ex_date, ], 
               birth = bi_date, entry = dg_date, exit = ex_date,
               breaks=list(fot=c(0,5,10,50,Inf), age=c(seq(0,85,5),Inf), per = 1993:2013), 
               status=status, aggre = list(fot, age, per))
  setDT(x)
  row_length <- x[,list( length(unique(age)), length(unique(per)), length(unique(fot)))]
  
  testthat::expect_equal( x[,sum(pyrs)], totpyrs, tolerance = 0.001)
  testthat::expect_equal( x[,sum(from0to0)], counts[1,N])
  testthat::expect_equal( x[,sum(from0to1)], counts[2,N])
  testthat::expect_equal( x[,sum(from0to2)], counts[3,N]) 
  #expect_equal( prod(row_length), x[,.N]) 
})

testthat::test_that('lexpand aggre: multistate column names correct', {
  
  x <- lexpand(sire[dg_date < ex_date, ][0:100], 
               birth = bi_date, entry = dg_date, exit = ex_date,
               breaks=list(fot=c(0,5,10,50,Inf), age=c(seq(0,85,5),Inf), 
                           per = 1993:2013), 
               status=status, aggre = list(fot, age, per))
  
  testthat::expect_equal(intersect(names(x), c('from0to0','from0to1','from0to2')), 
               c('from0to0','from0to1','from0to2'))  
})


# overlapping time lines --------------------------------------------------

testthat::test_that('lexpansion w/ overlapping = TRUE/FALSE produces double/undoubled pyrs', {
  popEpi:::skip_normally()
  
  sire2 <- copy(sire)[dg_date < ex_date, ][1:100]
  sire2[, dg_yrs := get.yrs(dg_date, "actual")]
  sire2[, ex_yrs := get.yrs(ex_date, "actual")]
  sire2[, bi_yrs := get.yrs(bi_date, "actual")]
  sire2[, id := 1:.N]
  sire2 <- sire2[rep(1:.N, each=2)]
  
  sire2[seq(2,.N, by=2), dg_yrs := (ex_yrs + dg_yrs)/2L]
  sire2[, dg_age := dg_yrs-bi_yrs]
  
  x <- lexpand(sire2, birth = "bi_yrs", entry = "bi_yrs", event="dg_yrs", 
               exit = "ex_yrs", status="status", entry.status = 0L, id = "id", 
               overlapping = TRUE)
  setDT(x)
  testthat::expect_equal(x[, sum(lex.dur), keyby=lex.id]$V1, sire2[, sum(ex_yrs-bi_yrs), keyby=id]$V1)  
  
  x <- lexpand(sire2, birth = "bi_yrs", entry = "bi_yrs", event="dg_yrs", 
               exit = "ex_yrs", status="status", entry.status = 0L, id = "id", 
               overlapping = FALSE)
  setDT(x)
  testthat::expect_equal(x[, sum(lex.dur), keyby=lex.id]$V1, 
               sire2[!duplicated(id), sum(ex_yrs-bi_yrs), keyby=id]$V1)  
})



testthat::test_that("different specifications of time vars work with event defined and overlapping=FALSE", {
  
  dt <- data.table(bi_date = as.Date('1949-01-01'), 
                   dg_date = as.Date(paste0(1999:2000, "-01-01")), 
                   start = as.Date("1997-01-01"),
                   end = as.Date('2002-01-01'), 
                   status = c(1,2), id=1)
  
  ## birth -> entry -> event -> exit
  x1 <- lexpand(data = dt, subset = NULL, 
                birth = bi_date, entry = start, exit = end, event = dg_date, 
                id = id, overlapping = FALSE,  entry.status = 0, status = status,
                merge = FALSE)
  testthat::expect_equal(x1$lex.dur, c(2,1,2))
  testthat::expect_equal(x1$age, c(48,50,51))
  testthat::expect_equal(x1$lex.Cst, 0:2)
  testthat::expect_equal(x1$lex.Xst, c(1,2,2))
  
  ## birth -> entry = event -> exit
  testthat::expect_error(
    lexpand(data = dt, subset = NULL, 
            birth = bi_date, entry = dg_date, exit = end, event = dg_date,
            id = id, overlapping = FALSE,  entry.status = 0, status = status,
            merge = FALSE), 
    regexp = paste0("some rows have simultaneous 'entry' and 'event', ",
                    "which is not supported with overlapping = FALSE; ",
                    "perhaps separate them by one day?")
    )
  
  ## birth = entry -> event -> exit
  x3 <- lexpand(data = dt, subset = NULL, 
                birth = bi_date, entry = bi_date, exit = end, event = dg_date,
                id = id, overlapping = FALSE, entry.status = 0, status = status,
                merge = FALSE)
  testthat::expect_equal(x3$lex.dur, c(50,1,2))
  testthat::expect_equal(x3$age, c(0,50,51))
  testthat::expect_equal(x3$lex.Cst, 0:2)
  testthat::expect_equal(x3$lex.Xst, c(1,2,2))
  
  ## birth -> entry -> event = exit
  testthat::expect_error(
    lexpand(data = dt, subset = NULL, 
            birth = bi_date, entry = dg_date, exit = end, event = end,
            id = id, overlapping = FALSE,  entry.status = 0, status = status,
            merge = FALSE), 
    regexp = paste0("subject\\(s\\) defined by lex.id had several rows ",
                    "where 'event' time had the same value, which is not ",
                    "supported with overlapping = FALSE; perhaps separate ",
                    "them by one day?")
  )
  
  ## birth = entry -> event -> exit
  x6 <- lexpand(data = dt, subset = NULL, 
                birth = bi_date, entry = bi_date, exit = end, event = dg_date,
                id = id, overlapping = FALSE,  entry.status = 0, status = status,
                merge = FALSE)
  testthat::expect_equal(x6$lex.dur, c(50,1,2))
  testthat::expect_equal(x6$age, c(0,50,51))
  testthat::expect_equal(x6$lex.Cst, 0:2)
  testthat::expect_equal(x6$lex.Xst, c(1,2,2))
  
})


testthat::test_that("lexpand drops persons outside breaks window correctly", {
  popEpi:::skip_normally()
  
  dt <- data.table(bi_date = as.Date('1949-01-01'), 
                   dg_date = as.Date(paste0(2000, "-01-01")), 
                   start = as.Date("1997-01-01"),
                   end = as.Date('2002-01-01'), 
                   status = c(2), id=1)
  
  ## by age
  x1 <- lexpand(data = dt, subset = NULL, 
                birth = bi_date, entry = start, exit = end, event = dg_date, 
                id = id, overlapping = FALSE,  entry.status = 0, status = status,
                merge = FALSE, breaks = list(age = 50:55))
  testthat::expect_equal(x1$age, c(50, 51, 52))
  
  ## by period
  x1 <- lexpand(data = dt, subset = NULL, 
                birth = bi_date, entry = start, exit = end, event = dg_date, 
                id = id, overlapping = FALSE,  entry.status = 0, status = status,
                merge = FALSE, breaks = list(per = 2000:2005))
  testthat::expect_equal(x1$per, c(2000, 2001))
  
  
  ## by fot
  x1 <- lexpand(data = dt, subset = NULL, 
                birth = bi_date, entry = start, exit = end, event = dg_date, 
                id = id, overlapping = FALSE,  entry.status = 0, status = status,
                merge = FALSE, breaks = list(fot = 2:5))
  testthat::expect_equal(x1$fot, c(2, 3, 4))
})

