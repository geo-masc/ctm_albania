#!/bin/bash

#te=$(gdalinfo /mnt/mowing/albania/level2/X0092_Y0084/20200124_LEVEL2_SEN2A_BOA.tif | \
#    grep "Corner Coordinates:" -A 5 | \
#    awk '/Lower Left/ {ll_x=$3; ll_y=$4} /Upper Right/ {ur_x=$3; ur_y=$4} \
#    END {printf "%s %s %s %s", ll_x, ll_y, ur_x, ur_y}' | \
#    sed 's/[(),]//g')
#proj=$(gdalsrsinfo -o proj4 /mnt/mowing/albania/level2/X0092_Y0084/20200124_LEVEL2_SEN2A_BOA.tif)
#
#
## Perform the resampling and clipping
#gdalwarp -tr 10 10 \
#         -te $te \
#         -t_srs "$proj" \
#         -r near \
#         -cutline /home/schwieder/projects/ctm_albania/data/vector/FORCE_Albanien_3035.gpkg \
#         -crop_to_cutline \
#         -tap \
#         -of GTiff \
#         -co COMPRESS=LZW \
#         /mnt/mowing/albania/mask/corine_2018_albania.tif \
#         /mnt/mowing/albania/mask/corine_2018_albania_10m_3035.tif



gdal_calc.py \
    --calc="1*numpy.logical_or.reduce((A==11,A==12,A==13,A==14,A==15,A==16,A==17,A==18,A==19,A==20,A==21))" \
    --outfile=/mnt/mowing/albania/mask/corine_2018_albania_10m_3035_binary_.tif \
    -A /mnt/mowing/albania/mask/corine_2018_albania_10m_3035.tif \
    --type=Byte \
    --co="COMPRESS=LZW" \
    --NoDataValue=0