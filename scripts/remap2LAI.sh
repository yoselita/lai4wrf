#!/bin/bash

# Load conda enviroment with ncl, cdo and nco
source activate NCLtoPY

#-----------------------------------------------------------------------------------------------------------------
# Define source and destination files
source_file=$1				# File to which grid the source file will be interpolated (e.g. geo_em file)
destination_file=$2			# File which is to be interpolated (observational file) 
#-----------------------------------------------------------------------------------------------------------------

# Setting the path to the calculated mean LAI
export wrkdir=`pwd`
if [ -z "$3" ];  then
    export means_path="./LAI_means/"
else 
    means_path=$3
fi

# Create cf-conform file to extract correct information on the source grid (WRF):
if [ ! -f source.grid ]; then 	
	echo "Creating source.grid"
	ncl 'file_in="'$source_file'"' 'file_out="source.nc"' to_cf.ncl
	# Define source.grid:
	python3 read_grid.py source.nc
	mv info.grid source.grid
fi

# Setting correct grid information readable by cdo to the wrf file
if [ ! -f modelData_setgrid.nc ]; then 	
	cdo setgrid,source.grid source.nc modelData_setgrid.nc
	rm source.nc source.grid
fi

# Define destination.grid:
if [ ! -f destination.grid ]; then 
	echo "Creating destination.grid"		
	cdo griddes ${means_path}/${destination_file} > destination.grid
fi

# Creating weights
if [ ! -f weights.nc ]; then 
	echo "Creating weight file before interpolating"	
        export CDO_GRIDSEARCH_RADIUS="0.04" 		
	cdo gennn,destination.grid modelData_setgrid.nc weights.nc
fi
# Remapping
if [ ! -f remapped_LU.nc ]; then 
	echo "Interpolating"			
	cdo remap,destination.grid,weights.nc -selname,lco modelData_setgrid.nc remapped_LU.nc
	rm modelData_setgrid.nc
fi
