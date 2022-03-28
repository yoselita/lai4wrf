#!/bin/bash

# Load conda enviroment with ncl, cdo and nco
source activate NCLtoPY

#-----------------------------------------------------------------------------------------------------------------
# Define source and destination files
source_file=$1				# File to which grid the source file will be interpolated (e.g. geo_em file)
destination_file=$2			# File which is to be interpolated (observational file) 

#-----------------------------------------------------------------------------------------------------------------
# Create cf-conform file to extract correct information on the source grid (WRF):
if [ ! -f source.grid ]; then 	
	ncl 'file_in="'$source_file'"' 'file_out="source.nc"' to_cf.ncl
	# Define destination.grid:
	python3 read_grid.py source.nc
	mv info.grid source.grid
fi

# setting the grid info on the file to be interpolated
cdo setgrid,source.grid source.nc modelData_setgrid.nc

if [ ! -f destination.grid ]; then 	
	cdo griddes ${means}/${destination_file} > destination.grid
fi

if [ ! -f weights.nc ]; then 
        export CDO_GRIDSEARCH_RADIUS="0.04" 		
	cdo gennn,destination.grid modelData_setgrid.nc weights.nc
fi
# Remapping
if [ ! -f remapped_$source_file ]; then 	
	cdo remap,destination.grid,weights.nc -selname,lco modelData_setgrid.nc remapped_LU.nc
fi

			
