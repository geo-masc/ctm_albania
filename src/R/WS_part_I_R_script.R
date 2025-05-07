# Load required R packages
library(renv)
renv::restore()
library(dplyr)    # for data manipulation
library(terra)    # for handling spatial raster data
library(randomForest)  # for Random Forest classification
library(sf) # for spatial objects
library(tidyverse)

# Set working directory
setwd("C:/Users/schwieder/Desktop/Albanien/moodle/")

# Load pre-trained CTM (Crop Type Mapping) model
load("CTM_model.RData")

### Read input data
# Features from combined 2018-2023 dataset
new_df <- read.csv2("2018_2023_combined_2023_valid_feats.csv", header = T)
new_df <- new_df %>%
  rename(class = X3001.000000)
head(new_df)
# Agricultural mask from CORINE land cover 2018
agri_mask <- rast("corine_2018_albania_10m_agri_mask.tif")

# Load extent of your group
group_extent <- st_read("group_I.gpkg")

# Load raster stack and crop to group extent
raster_group <-   terra::rast("WS_part_II_raster_stack.tif") %>% terra::crop(vect(group_extent))
raster_group

# Load color legend for visualization
legend_data <- read.table("CTM_legend.clr", sep = ",",
                          col.names = c("code", "R", "G", "B", "A", "class"))

# Set names of raster layers to match feature names in training data
names(raster_group) <- names(new_df)[1:504]

# Set random seed for reproducibility
set.seed(123)

# Split data into training (70%) and validation (30%) sets
train_df <- new_df %>% 
  slice_sample(prop = 0.7)

valid_df <- new_df %>% 
  anti_join(train_df) %>%   # Remove training samples from validation
  slice_sample(prop = 0.3)  


long_df <- valid_df %>%
  mutate(row = row_number()) %>%
  pivot_longer(
    cols = -c(row, class),
    names_to = "variable",
    values_to = "value"
  )

long_df <- long_df %>%
  separate(variable, into = c("band", "time"), sep = "_", convert = TRUE)


ggplot(long_df, aes(x = time, y = value, group = row)) +
  geom_line(alpha = 0.3) +  # zeigt jede Einzelserie leicht transparent
  stat_summary(fun = mean, geom = "line", aes(group = class, color = class), size = 1.2) +  # Mittelwert je Klasse
  facet_wrap(~band, scales = "free_y") +
  theme_minimal() +
  labs(title = "Zeitreihen pro Band und Klasse", x = "Zeitpunkt", y = "Wert")


##
## !! WE SKIP THIS PART !! CTM model is pre-loaded)
## Train Random Forest model
##print('Train model.')
##rf_model <- randomForest(x = train_df[, 1:504], y = as.factor(train_df[, 505]), 
##                         ntree = 500, mtry = sqrt(504), importance = TRUE)

## Validate model performance
# Make predictions on validation set
predictions <- predict(rf_model, valid_df[, 1:504])
actual_labels <- as.factor(valid_df[, 505])

# Calculate and print accuracy
accuracy <- sum(predictions == actual_labels) / length(actual_labels)
print(paste("Validation Accuracy:", round(accuracy * 100, 2), "%"))

# Show variable importance
importance(rf_model)
varImpPlot(rf_model)

# Display confusion matrix
table(Predicted = predictions, Actual = actual_labels)

# Get unique class values for prediction
class_values <- sort(unique(train_df[,505]))

# Predict crop types for the entire raster stack
print('Predict tile.')
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

# Visualize results
plot(predicted_raster_terra)

# Save prediction results
writeRaster(predicted_raster_terra, 
            "C:/Users/schwieder/Desktop/Albanien/moodle/results/WS_part_I_prediction_CTM.tif", 
            datatype="INT2U",  
            overwrite=TRUE)


# Create color-coded map
# Convert RGB values to R color codes
colors <- rgb(legend_data$R/255, legend_data$G/255, legend_data$B/255)
names(colors) <- legend_data$code

# Plot with custom colors
plot(predicted_raster_terra, 
     col = colors,
     legend = FALSE)

# Set up the plotting layout with extra space on the right
par(mar = c(5, 4, 4, 8))  # Increase right margin for legend

# Create the plot
plot(predicted_raster_terra, 
     col = colors,
     legend = FALSE)

# Add legend outside the plot area
legend(x = par("usr")[2]- 0.05, # Right side of plot
       y = mean(par("usr")[4:4]), # Middle of y-axis
       legend = legend_data$class,
       fill = colors,
       title = "Land Cover Classes",
       cex = 0.7,
       xpd = TRUE,  # Allow plotting outside the plot region
       bty = "n")   # No box around legend

# Add legend with class names
legend("topright", 
       legend = legend_data$class,
       fill = colors,
       title = "Land Cover Classes",
       cex = 0.7)




library(tidyverse)

# Set sample size per class
n_per_class <- 10

# Add row ID and sample within each class
sampled_df <- valid_df %>%
  mutate(row_id = row_number()) %>%
  rename(class = X3001.000000) %>%
  group_by(class) %>%
  sample_n(n_per_class) %>%
  ungroup()

# Convert to long format for plotting
long_df <- sampled_df %>%
  pivot_longer(
    cols = -c(row_id, class),
    names_to = "variable",
    values_to = "value"
  ) %>%
  separate(variable, into = c("band", "time"), sep = "_", convert = TRUE)

# Plot
ggplot(long_df, aes(x = time, y = value, group = row_id)) +
  geom_line(alpha = 0.5) +
  facet_wrap(~ band, scales = "free_y") +
  labs(title = "Sampled Time Series per Spectral Band",
       x = "Time", y = "Value") +
  theme_minimal()

