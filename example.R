##############################################################################
#
# TLDR
#
###############################################################################
# 0 - Load data.frame, only keep columns needed for algorithm, which are
#     nesting column (i.e., teams), ivs, and dvs.
#
# ...
#
# 1-3 - Change as necessary and run this:
#growthp = growthr$i_am_lazy(data, nesting="team",
#                          flip=c('obstacles', 'redtape', 'burnout'),
#                          ivs='choice obstacles redtape value',
#                          dvs="jobsat engage burnout")
# 4 - Get recommendations using either nesting entry's name or row number
#     in original data:
# growthp$recommend(40)




##############################################################################
#
# 0 - PREPARATION
#
##############################################################################
# Enter here the complete file location of 'growthr.R'.
# NOTE! In R, use forward slashes ('/') to separate directories.
# On Windows, you can also use two backslashes ('\\') to separate directories.

# =================> !!!!!!!!!!! <==================
# !!! CHANGE FOLDER LOCATION !!!
source('/where/growthp/folder/is/growthp/growthp.R')
# =================> !!!!!!!!!!! <==================

# Set your working directory from where you will read files
# NOTE! In R, use forward slashes ('/') to separate directories.
# On Windows, you can also use two backslashes ('\\') to separate directories.

# =================> !!!!!!!!!!! <==================
# !!! CHANGE FOLDER LOCATION !!!
setwd('/where/your/data/is')
# =================> !!!!!!!!!!! <==================

# Load a dataset
data = read.csv("my_data.csv", sep=",", quote='"', dec=".")

# (OPTIONAL)
# Select only respondents that have finished the survey (Qualtrics)
# and who provided consent. Remove empty teamnames

# =================> !!!!!!!!!!! <==================
# !!! CHANGE TO YOUR NEEDS !!!
data = data[ which( data$Finished == 1 & data$consent == 1 & data$teamname != ""), ]
# =================> !!!!!!!!!!! <==================

# (NOT OPTIONAL)
# Select the subset of variables that will be used to feed the
# growth potential algorithm.

# =================> !!!!!!!!!!! <==================
# !!! CHANGE WITH VARIABLES YOU WANT TO USE !!!
use_variables = c('teamname', 'g_jaut', 'g_hindq', 'g_redtape', 'g_conc', 'jobsat_5', 'g_engage', 'g_exhaust')
# =================> !!!!!!!!!!! <==================

# Select readable names to make interpreting output easier.

# =================> !!!!!!!!!!! <==================
# !!! CHANGE WITH NAMES YOU WANT TO USE !!!
rename_variables = c('team', 'choice', 'obstacles', 'redtape', 'value', 'jobsat', 'engage', 'burnout')
# =================> !!!!!!!!!!! <==================

# The name of the nesting variable. Here, we will be working with teams.

# =================> !!!!!!!!!!! <==================
# !!! CHANGE WITH NESTING NAME YOU CHOSE IN RENAME VARIABLES !!!
# =================> !!!!!!!!!!! <==================
nesting = "team"

# Make a data.frame with only the data we need and rename this data.frame
data = data[ , use_variables ]
colnames(data) <- rename_variables




##############################################################################
#
# 1 - BENCHMARK
#
##############################################################################


# Aggregate to the team level
data.agg = growthr$aggregate(data, nesting)

# Get the benchmark.
# Specify variables you would want to score low on (instead of high).

# =================> !!!!!!!!!!! <==================
# !!! CHANGE WITH NAMES YOU WANT TO FLIP !!!
flip = c('obstacles', 'redtape', 'burnout')
# =================> !!!!!!!!!!! <==================

benchmark = growthr$benchmark(data.agg, flip)




##############################################################################
#
# 2 - COMPARE
#
##############################################################################

# Calculate the growth potentials and standardize them.
# This automatically takes care of teams that exceed the benchmark.
# These teams are given the value 0 (no growth potential).
growth = growthr$growth(data.agg, benchmark)




##############################################################################
#
# 3 - RANK
#
##############################################################################

# Calculate the regression model

# =================> !!!!!!!!!!! <==================
# !!! CHANGE WITH IVS AND DVS YOU WANT TO USE !!!
model = growthr$regression_model(data.agg, ivs='choice obstacles redtape value', dvs="jobsat engage burnout")
# =================> !!!!!!!!!!! <==================

# Make the table with the weighted coefficients that are then used to
# weigh growth potentials of all teams.
model_tables = growthr$model_table(model)
# Weigh all growth potentials for all teams. This is then used
# to make recommended action lists.
wgrowth = growthr$weighted_growth(growth, model_tables$by.iv)
# Rank the weighed growth potentials.
ranks = growthr$ranked_growth(wgrowth)




##############################################################################
#
# 4 - RECOMMEND
#
##############################################################################

# Lookup a nesting's entry. You can use an entry's (team) name directly,
# or use a row number in the original data.

# =================> !!!!!!!!!!! <==================
# !!! CHANGE TO YOUR NEEDS !!!
lookup = growthr$lookup(10, data.agg, growth, ranks)
# =================> !!!!!!!!!!! <==================

# Now print the recommendation to screen
growthr$recommend(lookup, benchmark)