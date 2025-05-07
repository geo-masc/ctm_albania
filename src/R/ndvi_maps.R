library(terra)
library(ggplot2)
library(sf)
library(dplyr)
library(rosm)
library(ggspatial)
library(prettymapr)
library(raster)

setwd("C:/Users/schwieder/Desktop/Albanien/")

rst_files <- list.files("planet/" , pattern = "*.tif", full.names = TRUE)
# Initialisiere das Mosaik mit dem ersten Raster
mosaic_raster <- rast(rst_files[1])

# Schleife über die restlichen Raster-Dateien
for (i in 2:length(rst_files)) {
  r <- rast(rst_files[i])
  mosaic_raster <- mosaic(mosaic_raster, r, fun = "mean")  # oder "max", "min", etc.
}

# Speichern
writeRaster(mosaic_raster, "planet/20250321_planet_mosaic.tif", overwrite = TRUE)

writeRaster(mosaic_raster, "planet/20250321_planet_mosaic.tif",
            datatype = "INT2S", overwrite = TRUE,
            gdal = c("COMPRESS=LZW"))


writeRaster(mosaic_raster, "planet/20250321_planet_mosaic_COG.tif", overwrite = TRUE, gdal = c("TILED=YES", "COMPRESS=LZW"))


#rst <- rast("20250321_094412_54_24bd_3B_AnalyticMS_SR_8b_clip_file_format.tif")
#plot(rst)

rst <- mosaic_raster
# NDVI berechnen
ndvi <- (rst$nir - rst$red) / (rst$nir + rst$red)

# Optional: Wertebereich begrenzen
ndvi[ndvi < -1] <- NA
ndvi[ndvi > 1] <- NA

group_files <- list.files(path = "moodle/", pattern = "*.gpkg", full.names = TRUE)

for (i in 1:length(group_files)){

  print(paste("Prepare map for group", group_files[i]))

  # AOI laden (GeoPackage als sf-Objekt)
  aoi <- st_read(group_files[i])
  
  aoi_aligned <- st_transform(aoi, crs(rst))

  # NDVI clippen auf AOI
  ndvi_crop <- crop(ndvi, vect(aoi_aligned)) |> mask(vect(aoi_aligned))

  # Raster in Dataframe umwandeln
  ndvi_wgs84 <- project(ndvi_crop, "EPSG:4326")
  
  # 2. Convert raster to dataframe for ggplot
  ndvi_df <- as.data.frame(ndvi_wgs84, xy = TRUE, na.rm = TRUE)
  colnames(ndvi_df)[3] <- "NDVI"  # assume it's a single-layer NDVI raster
  #ndvi_df <- as.data.frame(ndvi_crop, xy = TRUE, na.rm = TRUE)
  #colnames(ndvi_df)[3] <- "NDVI"  # umbenennen
  
  # Expand the bounding box by 10%
  expand_bbox <- function(bbox, factor = 0.1) {
    x_range <- bbox["xmax"] - bbox["xmin"]
    y_range <- bbox["ymax"] - bbox["ymin"]
    
    bbox["xmin"] <- bbox["xmin"] - factor * x_range
    bbox["xmax"] <- bbox["xmax"] + factor * x_range
    bbox["ymin"] <- bbox["ymin"] - factor * y_range
    bbox["ymax"] <- bbox["ymax"] + factor * y_range
    
    bbox
  }
  
  # Create expanded bbox
  original_bbox <- st_bbox(ndvi_wgs84)
  expanded_bbox <- expand_bbox(original_bbox, factor = 0.1)
  
  # Convert to sf for annotation_map_tile
  expanded_sf <- st_as_sf(st_as_sfc(expanded_bbox))
  
  ndvi_plot <- ggplot() +
    annotation_map_tile(type = "osm", data = expanded_sf) +
    geom_raster(data = ndvi_df, aes(x = x, y = y, fill = NDVI), alpha = 1) +
    scale_fill_viridis_c(option = "D", name = "NDVI", na.value = NA) +
    coord_sf(xlim = c(expanded_bbox["xmin"], expanded_bbox["xmax"]),
             ylim = c(expanded_bbox["ymin"], expanded_bbox["ymax"]),
             expand = FALSE) +
    theme_minimal() +
    labs(title = paste("NDVI Group",as.character(i)), x = "Easting", y = "Northing")

  #ndvi_plot <- ggplot() +
  #  geom_raster(data = ndvi_df, aes(x = x, y = y, fill = NDVI)) +
  #  scale_fill_gradientn(colors = c("brown", "yellow", "green"), na.value = NA,
  #                       name = "NDVI", limits = c(0, 1)) +
  #  geom_sf(data = aoi_aligned, fill = NA, color = "black", linewidth = 0.7) +
  #  coord_sf() +
  #  theme_minimal() +
  #  labs(title = paste("NDVI Group",as.character(i)), x = "Easting", y = "Northing")
  
  ggsave(plot = ndvi_plot, filename = paste0("full_ndvi_ggplot_group_", as.character(i), ".pdf"), width = 8.27, height = 11.69, units = "in", dpi = 300)
  

}



ndvi_wgs84 <- project(ndvi_crop, "EPSG:4326")

# 2. Convert raster to dataframe for ggplot
ndvi_df <- as.data.frame(ndvi_wgs84, xy = TRUE, na.rm = TRUE)
colnames(ndvi_df)[3] <- "NDVI"  # assume it's a single-layer NDVI raster

# 3. Create plot
ggplot() +
  # OSM basemap
  annotation_map_tile(type = "osm", zoomin = -1) +
  
  # NDVI raster overlay
  geom_raster(data = ndvi_df, aes(x = x, y = y, fill = NDVI), alpha = 0.6) +
  scale_fill_viridis_c(option = "D", direction = -1, na.value = NA) +
  
  # Set coordinate system
  coord_sf(xlim = range(ndvi_df$x), ylim = range(ndvi_df$y), expand = FALSE) +
  
  # Add extras
  theme_minimal() +
  labs(title = "NDVI over OSM", fill = "NDVI")



bbox_sf <- st_as_sf(st_as_sfc(st_bbox(ndvi_wgs84)))

# 4. Plot using ggplot
ggplot() +
  # OSM background (uses bbox from sf object)
  annotation_map_tile(type = "osm", zoomin = -1, data = bbox_sf) +
  
  # NDVI raster as semi-transparent layer
  geom_raster(data = ndvi_df, aes(x = x, y = y, fill = NDVI), alpha = 0.6) +
  scale_fill_viridis_c(option = "D", name = "NDVI", na.value = NA) +
  
  # Proper coords from sf
  coord_sf(xlim = range(ndvi_df$x), ylim = range(ndvi_df$y), expand = FALSE) +
  
  theme_minimal() +
  labs(title = "NDVI over OpenStreetMap Background")



# Expand the bounding box by 10%
expand_bbox <- function(bbox, factor = 0.1) {
  x_range <- bbox["xmax"] - bbox["xmin"]
  y_range <- bbox["ymax"] - bbox["ymin"]
  
  bbox["xmin"] <- bbox["xmin"] - factor * x_range
  bbox["xmax"] <- bbox["xmax"] + factor * x_range
  bbox["ymin"] <- bbox["ymin"] - factor * y_range
  bbox["ymax"] <- bbox["ymax"] + factor * y_range
  
  bbox
}

# Create expanded bbox
original_bbox <- st_bbox(ndvi_wgs84)
expanded_bbox <- expand_bbox(original_bbox, factor = 0.2)

# Convert to sf for annotation_map_tile
expanded_sf <- st_as_sf(st_as_sfc(expanded_bbox))

ggplot() +
  annotation_map_tile(type = "osm", data = expanded_sf) +
  geom_raster(data = ndvi_df, aes(x = x, y = y, fill = NDVI), alpha = 0.8) +
  scale_fill_viridis_c(option = "D", name = "NDVI", na.value = NA) +
  coord_sf(xlim = c(expanded_bbox["xmin"], expanded_bbox["xmax"]),
           ylim = c(expanded_bbox["ymin"], expanded_bbox["ymax"]),
           expand = FALSE) +
  theme_minimal() +
  labs(title = paste("NDVI Group",as.character(i)), x = "Easting", y = "Northing")

