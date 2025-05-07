library(renv)

renv::activate()
renv::status()
renv::install(c('terra', 'randomForest', 'ggplot2', 'tidyverse', 'sf', 'dplyr', 'rosm', 'ggspatial'))

renv::snapshot()

renv::restore()
