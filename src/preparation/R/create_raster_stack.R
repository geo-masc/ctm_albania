raster_dir <- ("C:/Users/schwieder/Desktop/X0067_Y0041")


# # List all raster files that start with "2022"
raster_files <- list.files(path = raster_dir, pattern = "^2023.*\\.tif$", full.names = TRUE)

# # Define the expected order
band_order <- c("BLU", "GRN", "RED", "NIR", "SW1", "SW2_", "NDV_", "NDW_", "SAV_")

# # Filter and reorder the list based on band names
ordered_files <- unlist(sapply(band_order, function(band) {
 grep(paste0(band), raster_files, value = TRUE)
}))

test <- rast("C:/Users/schwieder/Desktop/X0067_Y0041/20230101-20231231_001-365_HL_TSA_LNDLG_NDW_TSI.tif")
# # Check if the ordering is correct
print(ordered_files)

# # Load the rasters and select only the required bands
raster_list <- lapply(ordered_files, function(file) {
   rast(file)[[12:67]]  # Load only bands 12 to 67
})

# # Merge all rasters into a single SpatRaster
raster_stack <- do.call(c, raster_list)
raster_stack <- rast(raster_stack) 

terra::writeRaster(raster_stack, "C:/Users/schwieder/Desktop/Albanien/moodle/WS_part_I_raster_stack_BRB.tif", overwrite = T)

