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



# Load raster stack and crop to group extent
raster_stack <-   terra::rast("data/raster/WS_part_I_raster_stack_BRB.tif")

# Set names of raster layers to match feature names in training data
load("data/R/raster_band_names.RData")
names(raster_stack) <- band_names
raster_stack

IACS <- st_read("data/vector/IACS_CTM_BRB_2023.gpkg")
head(IACS)

ggplot(data = IACS) +
  geom_sf(aes(fill = as.character(CTMmajority))) +
  scale_fill_viridis_d() +  # Optional: nice discrete color scale
  labs(title = "IACS data with crop type map codes",
       fill = "CTM Class") +
  theme_minimal()

# Set random seed for reproducibility
set.seed(143)

# Random sampling per class for model training
samples_train <- IACS %>%
  drop_na() %>% 
  group_by(CTMmajority) %>%
  slice_sample(n = 100) %>%
  st_centroid() %>% 
  mutate(dataset = "train") 
  
# Random sampling per class for model validation
samples_valid <- IACS %>%
  drop_na() %>% 
  filter(!row_number() %in% samples_train$field_id) %>%  
  group_by(CTMmajority) %>%
  slice_sample(n = 100) %>%
  st_centroid() %>% 
  mutate(dataset = "valid") 


# Extract raster values for training
# --> this might take a while
train_vals <- terra::extract(raster_stack, vect(samples_train), ID = FALSE) %>%
  bind_cols(samples_train$CTMmajority) %>% 
  rename(Class = ...505) %>% 
  drop_na()

# backup path to file
# save(train_vals, file = "train_samples.RData")
# load("backup/train_samples.RData") 


# Extract raster values for validation
# --> this might take a while
valid_vals <- terra::extract(raster_stack, vect(samples_valid)) %>%
  bind_cols(samples_valid$CTMmajority) %>% 
  select(-ID) %>% 
  rename(Class = ...506) %>% 
  drop_na()


# backup path to file
# save(valid_vals, file = "valid_samples.RData")
# load( "backup/valid_samples.RData")

# Train Random Forest model
print('Train model.')
rf_model <- randomForest(x = train_vals[, 1:504], y = as.factor(train_vals[, 505]), 
                         ntree = 500, mtry = sqrt(504), importance = TRUE)

############################ Apply model to unseen data ########################

# backup path to model
# load("CTM_model.RData")

## Validate model performance
# Make predictions on validation set
predictions <- predict(rf_model, valid_vals[, 1:504])
actual_labels <- as.factor(valid_vals[, 505])

# Calculate and display confusion matrix
conf_matrix <- table(Predicted = predictions, Actual = actual_labels)
conf_matrix

# Calculate and print accuracy
accuracy <- sum(predictions == actual_labels) / length(actual_labels)
print(paste("Overall Accuracy:", round(accuracy * 100, 2), "%"))

# Producer's Accuracy (Recall pro tatsächliche Klasse)
producers_accuracy <- diag(conf_matrix) / colSums(conf_matrix)
print("Classwise producer's Accuracy:")
print(round(producers_accuracy * 100, 2))

# User's Accuracy (Precision pro vorhergesagte Klasse)
users_accuracy <- diag(conf_matrix) / rowSums(conf_matrix)
print("Classwise user's Accuracy:")
print(round(users_accuracy * 100, 2))

# Show variable importance
importance(rf_model)
varImpPlot(rf_model)


################## Apply model to raster stack and predict map #################

# Get unique class values for prediction
class_values <- sort(unique(train_vals[,505]))

# Predict crop types for the entire raster stack
print('Predict tile.')
predicted_raster_terra <- terra::predict(
  raster_stack, 
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
writeRaster(predicted_raster_terra, 
            "WS_part_I_prediction_CTM_BRB.tif", 
            datatype="INT2U",  
            overwrite=TRUE)



### End of file

