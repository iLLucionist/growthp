#############################################################################
#
# GROWTH POTENTIAL
# ----------------
#
# Reference implementation of the growth potential algorithm in R.
#
#  ==> SEE INSTRUCTIONS ONLINE AT GITHUB.
#      https://github.com/iLLucionist/growthr
#
#  ==> SEE PROVIDED 'example.R' FOR HOW TO USE THIS LIBRARY.
#
# Licensed under the MIT License.
# Copyright 2021 L. Maxim Laurijssen.
#
#############################################################################


# This will contains all exported functions
growthr = list()


# Aggregate to the level specified in the provided nesting column.
# For instance, if the nesting column in the data represents teams,
# you will get a row for every team in the nesting column, and every row
# has the team means for all the scores (columns) in the data.
#
# Parameters:
#   data: a data.frame with ONLY the nesting column(teams) and
#     columns that are used in the algorithm. Please remove all other columns.
#   nesting: the name of the variable / column that has the nesting entries.
#     Typically, this would be a column with team names.
#
# Returns: a data.frame with aggregated means per entry in nesting variable.
growthr$aggregate = function(data, nesting) {
  nesting_column = data[[nesting]]
  # Calculate one mean per entry in nesting variable
  data = data[, !(names(data) %in% c(nesting))]
  return(aggregate(data, mean, by=list(nesting = nesting_column), na.rm=TRUE))
}


# Count how large every entry in the nesting is. For instance, if the nesting
# column in the data represents teams, you will get a row with for every team
# in the nesting column with the name of the team and how many members
# there are in that team.
#
# Parameters:
#   data: data.frame also used in the aggregation function (see above).
#   nesting: the name of the variable / column that has the nesting entries.
#     Typically, this would be a column with team names.
#
# Returns: data.frame with a row per entry in nesting (e.g., teams).
#   Every row contains the number of times the entry occurs. In other words,
#   this gives you team sizes.
growthr$count_nesting = function(data, nesting) {
  return(as.data.frame(table(data$team)))
}


# This calculates the comparison standard that is used to compare all entries
# in the nesting. For instance, if the nesting column in the data represents
# teams, this function will calculate the nth percentile as specified in
# the percentile argument (.90th percentile by default = top 10%). This
# benchmark can then be provided to calculate all growth potentials using
# the 'growth' function.
#
# Provide the names of variables (column names) in the flip argument as 
# a vector (e.g., c('a', 'b', ...)). 'Flipping' means that the LOWER
# percentile (10 percent cutoff) will be used instead of the HIGHER percentile
# (90 percent cutoff). This should be used for variables that you want
# to score low on (e.g., burnout, red tape).
#
# Parameters:
#   aggregated: output of growthr$aggregate (see above).
#   flip: names of variables / columns you want teams to score LOW on
#     instead of high (e.g., red tape, burnout).
#   percentile: percentile score to use, which defaults to .10 (=.90).
#
# Returns: data.frame with four rows: values at low and high end,
#   a flip column indicating whether a benchmark value is flipped, and
#   the benchmark values themselves (after flipping).
growthr$benchmark = function(aggregated, flip=c(), percentile = .10) {
  # Remove nesting column because it is not numeric
  data = aggregated[, !(names(aggregated) %in% c('nesting'))]
  # Calculate the low and high (.10 and .90, by default) quantile scores
  quantiles = apply(data, 2, quantile, probs=c(percentile, 1 - percentile),
                    na.rm=T)
  flip = colnames(quantiles) %in% flip
  mask = rbind(flip, 1 - flip)
  benchmark = rbind(quantiles, flip = flip,
                    benchmark = colSums(quantiles * mask))
  return(benchmark)
}


# This function actually calculates the growth potentials for all the entries
# in the nesting. If the nesting variable represents teams, this function
# will return a data.frame with for every team a row, and every row contains
# how much growth potential there is compared to the comparison standard
# (i.e., reference value) in the benchmark.
#
# Importantly, this function automatically gives entries that EXCEED the
# benchmark the value 0. This is because teams, for instance, that meet or
# exceed the benchmark already realized their full growth potential, relatively.
#
# Parameters:
#   aggregated: output of growthr$aggregate (see above).
#   benchmark: output of growthr$benchmark (see above).
#
# Returns: data.frame with a row per team, with every row containing
#   the growth potentials for that team on all variables / columns.
growthr$growth = function(aggregated, benchmark) {
  # Make a data.frame with the numbers we benchmark values that we
  # will subtract from the aggregated scores
  subtract = do.call(rbind, replicate(nrow(aggregated),
                                      benchmark[4, ], simplify=FALSE))
  # Subtract from aggregated values and take absolute values.
  # Take absolute values because of "flipped" scores.
  compared = abs(aggregated[, -1] - subtract)
  # Assign entries that exceed the benchmark the value 0.
  # They do not have growth potential, because they already met or exceeded it.
  decide = function(x, b, f) if(!f) x >= b else !(x >= b)
  excellent = mapply(decide, aggregated[,-1], benchmark[4, ], benchmark[3, ])
  compared = compared * !excellent
  return(data.frame(nesting=aggregated$nesting, compared))
}


# Because every variable has it's own mean and standard deviation, growth
# potential distributions differ. Although absolute values may be compared
# if the original variables share the same measurement scale, it can be desired
# to remove the influence of varying spreads by standardizing to the
# z-distribution. This is optional and not used now to keep things easy.
#
# Parameters:
#   growth: output of growthr$growth (see above).
#
# Returns: data.frame with standardized growth potentials (z-values).
growthr$standardize_growth = function(growth) {
  # Means and SDs of growth potentials
  means = apply(growth[, -1], 2, mean, na.rm=TRUE)
  sds = apply(growth[, -1], 2, sd, na.rm=TRUE)
  # Function to standardize
  z = function( x, m, s ) (m - x) / s
  # Standardize every variable / column using its respective mean and SD.
  zgrowth = mapply(z, growth[, -1], means, sds)
  colnames(zgrowth) <- colnames(growth[,-1])
  zgrowth = data.frame(nesting=growth$nesting, zgrowth)
  # Set excellent values (scores exceeding benchmark) to 0.
  zgrowth[, -1][growth[, -1] == 0] <- 0
  return(zgrowth)
}


# This runs a multivariate regression model for all specified dvs
# simultaneously. The results of this regression model is used as input
# to weight all growth potentials, and to make a recommended actions list.
#
# IMPORTANT: specify ivs and dvs as a text variable and use a space character
# between every variable. Example: "choice value" for ivs.
# Or "burnout jobsat" for dvs.
#
# You can look at each regression indepedently by executing this command:
# > summary(growth$g_regression_model(...))
# And replace dots (e.g., ...) with the arguments to the function.
#
# Parameters:
#   aggregated: output of growthr$aggregate (see above).
#   ivs: space separated variable / column names of independent variables
#   dvs: space separated variable / column names of dependent variables
#
# Returns: a linear model fit object (use summary function to inspect it)
growthr$regression_model = function(aggregated, ivs, dvs) {
  # Make vector with iv names and vector with dv names
  ivs = strsplit(ivs, ' ')[[1]]
  dvs = strsplit(dvs, ' ')[[1]]
  
  # Make formula and run regression
  model = lm(formula(paste('cbind(',
                   paste(dvs, collapse=','),
                   ') ~ ',
                   paste(ivs, collapse=' + '))), data=aggregated)
  
  # Attach iv and dv names
  attr(model, 'ivs') <- ivs
  attr(model, 'dvs') <- dvs

  return(model)
}


# This will make the model table that is used as weights for calculating
# weighted growth potentials. Importantly, it averages for every iv
# all the iv's coefficients per dv. It also takes the absolute value of these
# averages.
#
# Parameters:
#   model: output of growthr$regression_model (see above).
#
# Returns: data.frame with all statistics required to then weigh
# all growth potentials. This is the basis for the recommended actions list.
growthr$model_table = function(model) {
  # For every dv, make a data.frame with tehse columns:
  #   name: name of iv
  #   b: coefficient
  #   b.abs: absolute coffecient
  #   direction: the sign of b (plus or minus)
  #   is.sig: * (star) when p < .05, otherwise no star
  #   rank: rank of coefficient
  results <- setNames(lapply(summary(model), function(dv) {
    effects <- dv$coefficients[-1, 4]
    coefs <- dv$coefficients[-1, 1]
    setNames(data.frame(
      var <- attr(model, 'ivs'),
      coefalssig <- round(coefs, 3),
      abscoef = abs(round(coefs,3)),
      richting <- ifelse(coefs < 0, "-", "+"),
      sig <- ifelse(effects < .05, "*", ""),
      rank <- rank(ifelse(effects < 0.05, -abs(round(coefs, 3)), NA))
    ), c("name", "b", "b.abs", "direction", "is.sig", "rank"))
  }), attr(model, 'dvs'))
  
  # Make one large table with all effects for all regression
  by.dv = results
  by.dv = do.call(rbind, by.dv)
  
  # data.frame with average effects per iv over all dvs
  name_column = by.dv$name
  by.iv = aggregate(by.dv[, c(3, 6)],
                    mean, by=list(iv = name_column), na.rm=TRUE)

  return(list(by.iv=by.iv, by.dv=by.dv))
}


# This will weigh all growth potentials for all teams using the model table.
# In effect, it multiplies all growth potentials with the average coefficient
# for independent variables.
#
# Parameters:
#   growth: output of growthr$growth (see above).
#   ivtable: list element 'by.iv' from growthr$model_table (see example).
#     For example, let's say tbl = growthr$model_table(my_model).
#     Then: growthr$weighted_growth(tbl$by.iv)
#
# Returns: data.frame with all weighed growths for all teams.
growthr$weighted_growth = function(growth, ivtable) {
  ivs = unlist(unname(ivtable[1]))
  
  multiply = setNames(data.frame(t(ivtable$by.iv[,2])),
                      ivtable$by.iv[,1])
  multiply = do.call(rbind, replicate(nrow(growth), multiply, simplify=FALSE))
  wgrowth = data.frame(nesting=growth$nesting, growth[, ivs] * multiply)
  return(wgrowth)
}


# This will rank the weighted growth potentials within each team.
# It will also provide the relative contribution of every weighted
# growth potential compared to all summed weighted growth potentials per team.
# Think of this as the "proportion explained variance" of each weighted
# growth potential, or the "size of the slice of the whole pie".
#
# Parameters:
#   wgrowth: output of growthr$ranked_growth(wgrowth)
#
# Returns: list with an entry with relative contribution of each
#   weighted growth potential per team ($relative) and list with the ranks
#   of each weighted growth potential per team ($ranks). Ranks are ordered
#   from highest relative weighted growth potential to smallest.
growthr$ranked_growth = function(wgrowth) {
  sums = rowSums(wgrowth[, -1])
  relative = wgrowth[, -1] / sums
  ranks = data.frame(t(apply(-relative, 1, rank)))
  
  relative = data.frame(wgrowth$nesting, relative)
  ranks = data.frame(wgrowth$nesting, ranks)
  
  return(list(relative=relative, ranks=ranks))
}


# Use this function to get all the output for a particular nesting entry
# (e.g., team) necessary to make a recommended actions list. You can lookup
# by number (row number in original data) or by name of nesting entry
# (e.g., team name).
#
# Parameters:
#   nesting_name: name or row number of nesting entry / team
#   aggregated: output of growthr$aggregate (see above).
#   growth: output of growthr$growth (see above).
#   ranks: output of growthr$ranks (see above).
#
# Returns: list with entries with respective output for nesting entry
#   (e.g., team). Use this as input for growthr$recommend.
growthr$lookup = function(nesting_name, aggregated, growth, ranks) {
  if (!is.numeric(nesting_name)) {
    row = which(growth$nesting == nesting_name)
  } else {
    row = nesting_name
    nesting_name = growth[row, "nesting"]
  }
  
  scores = aggregated[row, -1]
  growth = growth[row, -1]
  relative = ranks$relative[row, -1]
  ranks = ranks$ranks[row, -1]

  return(list(name=nesting_name, row=row, scores=scores, growth=growth, ranks=ranks, relative=relative))  
}


# Prints the growth potential's recommend action list (and scores) to
# screen.
#
# Parameters:
#   lookup: output from growthr$lookup (see above).
#   benchmark: output from growthr$benchmark (see above).
growthr$recommend = function(lookup, benchmark) {
  # Title
  cat("Recommendation for:\n  ", lookup$name, " (#", lookup$row, ")", sep='', "\n\n")
  
  cat("Scores\t\t(Score - Benchmark - Growth):\n", sep='')
  
  x = colnames(lookup$scores)
  
  for(y in x) {
    score = format(round(lookup$scores[,y], 1), nsmall = 1)
    ref = format(round(benchmark[4,y], 1), nsmall = 1)
    growth = format(round(lookup$growth[,y], 1), nsmall = 1)
    cat("  ", y, ":\t\t", score, " - ", ref, " - ", growth, "\n", sep = '')
  }
  
  ranks = data.frame(name=names(lookup$ranks),
                     rank=as.vector(unname(unlist(t(lookup$ranks)))))
  ranks = ranks[order(ranks$rank), ]
  
  cat("\nRecommended actions:\n", sep='')
  
  for(x in 1:nrow(ranks)) {
    relative = round(lookup$relative[,ranks[x, "name"]] * 100, 0)
    cat("  ", ranks[x, "name"], " (", relative,"%)", "\n", sep="")
  }
  
  cat("\n  NOTE. Ranked most to least influential on all outcomes.\n\n",sep="")
}


# Does everything for you. Use $recommend afterwards to get recommendations.
#
# Parameters:
#   data: data.frame to use. ONLY INCLUDE columns required (nesting, ivs, dvs)
#   nesting: name of column that has nesting values
#   flip: name of variables / columns you want nesting entries (teams) to score
#      low on (e.g., red tape, burnout)
#   ivs: space separated string of ivs (e.g., "iv1 iv2 iv3")
#   dvs: space separated string of dvs (E.g., "dv1 dv2 dv3")
growthr$i_am_lazy = function(data, nesting, flip, ivs, dvs) {
  data.agg = growthr$aggregate(data, nesting)
  benchmark = growthr$benchmark(data.agg, flip)
  growth = growthr$growth(data.agg, benchmark)
  model = growthr$regression_model(data.agg, ivs, dvs)
  model_tables = growthr$model_table(model)
  wgrowth = growthr$weighted_growth(growth, model_tables$by.iv)
  ranks = growthr$ranked_growth(wgrowth)
  
  return(list(
    data=data,
    nesting=nesting,
    flip=flip,
    ivs=ivs,
    dvs=dvs,
    aggregated=data.agg,
    benchmark=benchmark,
    growth=growth,
    model=model,
    model_tables=model_tables,
    wgrowth=wgrowth,
    ranks=ranks,
    lookup = function(nesting_name) {
      return(growthr$lookup(nesting_name, data.agg, growth, ranks))
    },
    recommend=function(nesting_name) {
      lookup = growthr$lookup(nesting_name, data.agg, growth, ranks)
      return(growthr$recommend(lookup, benchmark))
    }
  ))
}
