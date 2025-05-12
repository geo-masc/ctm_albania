library(renv)
renv::restore()

library(terra)
library(sf)


# Set working directory
# --> adjust to your local path
setwd(".../Summerschool_GEO-WB6_2025/")

# read raster data
rst <- terra::rast("data/raster/planet/20250321_planet_mosaic_COG.tif")

# align projections
group_extent <- st_read("data/vector/group_.gpkg") %>% 
  st_transform(crs(rst))

# crop to group extent and calculate NDVI
raster_group <-   rst %>% 
  terra::crop(vect(group_extent)) %>% 
  { 
    ndvi <- (.[["nir"]] - .[["red"]]) / (.[["nir"]] + .[["red"]])
    names(ndvi) <- "NDVI"
    c(., ndvi)  # combine original raster with NDVI
  }

plot(raster_group)



#### perform unsupervised classification

r_values <- values(raster_group)

# delete NA values
valid_idx <- complete.cases(r_values)
r_values_valid <- r_values[valid_idx, ]

# K-means Clustering --> define number of classes
set.seed(42) # --> set seed to ensure the possibilty to replicate
kmeans_result <- kmeans(r_values_valid, centers = , iter.max = 100, nstart = 10)

# Create a new raster with k-means results
classified <- raster_group[[1]]  # nur für Rasterstruktur
classified[] <- NA
classified[valid_idx] <- kmeans_result$cluster

# plot result
plot(classified, main = "K-means classification group ")

##### Extract mean values per class

# calculate mean values per cluster
means <- zonal(raster_group, classified, fun = "mean", na.rm = TRUE)
print(means)
