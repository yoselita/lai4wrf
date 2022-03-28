#!/bin/bash

# Load conda enviroment with ncl, cdo and nco
source activate NCLtoPY 

#-----------------------------------------------------------------------------------------------------------------
# Define source and destination files
source_file=$1				# File which is to be interpolated (observational file)
destination_file=$2			# File to which grid the source file will be interpolated (e.g. geo_em file)
#-----------------------------------------------------------------------------------------------------------------
# Create cf-conform file to extract correct information on grids:
if [ ! -f destination.grid ]; then 	
	echo "Creating destination.grid"
	ncl 'file_in="'${destination_file}'"' 'file_out="destination.nc"' to_cf.ncl
	# Define destination.grid:
	python3 read_grid.py destination.nc
	mv info.grid destination.grid; rm destination.nc 
fi

# Creating weights
if [ ! -f weights.nc ]; then 
	echo "Creating weight file before interolating"	
	cdo gencon,destination.grid ${means}/${source_file} weights.nc
fi
# Remapping
if [ ! -f remapped_$source_file ]; then 
	echo "Intepolating"		
	cdo remap,destination.grid,weights.nc ${means}/${source_file} remapped_$source_file
fi
