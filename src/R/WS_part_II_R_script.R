# Load required R packages
library(renv)
renv::restore()

library(dplyr)    # for data manipulation
library(terra)    # for handling spatial raster data
library(randomForest)  # for Random Forest classification
library(sf) # for spatial objects
library(tidyverse)

# Set working directory
# --> adjust to your local path
setwd(".../Summerschool_GEO_WB6_2025/")


# Agricultural mask from CORINE land cover 2018
agri_mask <- rast("data/raster/corine_2018_albania_10m_agri_mask.tif")

# Load spatial extent 
# --> adjust to your group
group_extent <- st_read("data/vector/group_.gpkg")

# Load raster stack and crop to group extent
raster_group <-   terra::rast("data/raster/WS_part_II_raster_stack.tif") %>% terra::crop(vect(group_extent))
raster_group

# Set names of raster layers to match feature names in training data
load("data/R/raster_band_names.RData")
names(raster_group) <- band_names

# Set random seed for reproducibility
set.seed(123)

# Load pre-trained CTM (Crop Type Mapping) model
load("data/R/CTM_model_BRB.RData")

# Show variable importance
importance(rf_model)
varImpPlot(rf_model)


# Predict crop types for the entire raster stack
print('Predict tile.')

# Get unique class values for prediction
load("backup/train_samples.RData")
class_values <- sort(unique(train_vals[,505]))

predicted_raster_terra <- terra::predict(
  raster_group, 
  model=rf_model, 
  na.rm=TRUE,
  #mask=agri_mask,  # Optional masking to agricultural areas
  format="GTiff",
  factors=class_values,
  categorical=TRUE  
)

# Reclassify predictions if needed
if (is.numeric(predicted_raster_terra[])) {
  rcl_matrix <- cbind(1:length(class_values), class_values)
  predicted_raster_terra <- classify(predicted_raster_terra, rcl_matrix)
}


# Save prediction results
# --> adjust name to your group
writeRaster(predicted_raster_terra, 
            "results/WS_part_II_prediction_CTM_BRB_group_X.tif", 
            datatype="INT2U",  
            overwrite=TRUE)


#### End of file


