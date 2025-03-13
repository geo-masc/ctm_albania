library(dplyr)
library(terra)
library(randomForest)


# read data
new_df <- read.csv2("/home/schwieder/projects/ctm_albania/data/2018_2023_combined_2023_valid_feats.csv")
raster_stack <- rast("/home/schwieder/projects/ctm_albania/mnt/mowing/albania/ger/raster_stack.tif")
# Read the legend file
legend_data <- read.table("/home/schwieder/projects/ctm_albania/data/CTM_GER_LegendEN_rst_v201.clr", sep = ",",
                         col.names = c("code", "R", "G", "B", "A", "class"))



set.seed(123)  # Set seed for reproducibility

# Create two mutually exclusive samples
train_df <- new_df %>% 
  slice_sample(prop = 0.01)  # 40% of data

valid_df <- new_df %>% 
  anti_join(train_df)  %>%   # Remove all rows that are in sample1
  slice_sample(prop = 0.01)  
  

rf_model <- randomForest(x = train_df[, 1:504], y = as.factor(train_df[, 505]), 
                         ntree = 50, mtry = sqrt(504), importance = TRUE)

predictions <- predict(rf_model, valid_df[, 1:504])
actual_labels <- as.factor(valid_df[, 505])

# Compute accuracy
accuracy <- sum(predictions == actual_labels) / length(actual_labels)
print(paste("Validation Accuracy:", round(accuracy * 100, 2), "%"))

# Variable importance
importance(rf_model)
varImpPlot(rf_model)

# Confusion matrix
table(Predicted = predictions, Actual = actual_labels)
names(raster_stack) <- names(train_df)[1:504]

raster_stack <- app(raster_stack, fun = function(x) { 
  x[is.na(x)] <- -9999  # Replace NA with mean
  return(x) 
})

# Ensure the model and raster stack have matching predictors
predicted_raster <- predict(raster_stack, rf_model, na.rm = TRUE)
# Alternative prediction approach
predicted_raster_terra <- terra::predict(raster_stack, model=rf_model, na.rm=TRUE, format="GTiff")

plot(predicted_raster)

# Save the predicted raster
writeRaster(predicted_raster, "predicted_rf.tif", overwrite = TRUE)



rf <- randomForest::randomForest(x = train_df[,1:504], y=train_df$X3001.000000, ntree = 50)
rf_pred <- predict(rf, valid_df[,1:504])

# Create a color vector from RGB values
colors <- rgb(legend_data$R/255, legend_data$G/255, legend_data$B/255)
names(colors) <- legend_data$code

# Create a plot with custom legend
plot(predicted_raster, 
     col = colors,
     legend = FALSE)

# Add custom legend
legend("topright", 
       legend = legend_data$class,
       fill = colors,
       title = "Land Cover Classes",
       cex = 0.7)



# all_feats <- read.delim("C:/Users/schwieder/Data/Albanien/combined/2018_2023_combined_2023_valid_feats", sep = " " )
# lables <- read.delim("C:/Users/schwieder/Data/Albanien/combined/2018_2023_combined_2023_valid_labels", sep = " " )
# raster_dir <- ("C:/Users/schwieder/Data/Albanien/X0057_Y0053")



# # List all raster files that start with "2022"
# raster_files <- list.files(path = raster_dir, pattern = "^2022.*\\.tif$", full.names = TRUE)

# # Define the expected order
# band_order <- c("BLU", "GRN", "RED", "NIR", "SW1", "SW2_", "NDV_", "NDW_", "SAV_")

# # Filter and reorder the list based on band names
# ordered_files <- unlist(sapply(band_order, function(band) {
#   grep(paste0(band), raster_files, value = TRUE)
# }))

# # Check if the ordering is correct
# print(ordered_files)

# # Load the rasters and select only the required bands
# raster_list <- lapply(ordered_files, function(file) {
#   rast(file)[[12:67]]  # Load only bands 12 to 67
# })

# # Merge all rasters into a single SpatRaster
# raster_stack <- do.call(c, raster_list)
# raster_stack <- rast(raster_stack) 

# # create column name string
# column_names <- c(
#   paste0("BLU_", 12:67),
#   paste0("GRN_", 12:67),
#   paste0("RED_", 12:67),
#   paste0("NIR_", 12:67),
#   paste0("SW1_", 12:67),
#   paste0("SW2_", 12:67),
#   paste0("NDV_", 12:67),
#   paste0("NDW_", 12:67),
#   paste0("SAV_", 12:67),
#   "DEM_ASP",
#   "DEM_ELE", 
#   "DEM_SLP",
#   "DEM_TWI",
#   paste0("SOIL_MOIST_", sprintf("%02d", 1:12)),
#   paste0("RAD_", sprintf("%02d", 1:12)),
#   paste0("RSMS_", 13:16),
#   paste0(rep(c("S1_RVI_", "S1_VH_", "S1_VHVV_", "S1_VV_"), each=12), 
#          rep(sprintf("%02d", 1:12), 4)),
#   paste0("TAMM_", c(sprintf("%02d", 1:12), 13:16))
# )

# # assign column names
# colnames(all_feats)<-column_names

# # select time series of visible bands and indices
# features <- all_feats %>%
#   select(matches("^(BLU|GRN|RED|NIR|SW1|SW2|NDV|NDW|SAV)_\\d+$"))

# new_df <- cbind(features, lables)


