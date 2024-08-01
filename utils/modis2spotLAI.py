##############################################################
# This script fills gaps in SPOT LAI data with data from MODIS
# Contact: milovacj@unican.es
#
# to run: python modis2spotLAI.py geo_em_spot geo_em_modis
##############################################################

# Loading packages
import xarray as xr 
import numpy as np
import os
import sys

# Check if the correct number of arguments is provided
if len(sys.argv) != 3:
    print("Usage: modis2spotLAI.py geo_em_spot geo_em_modis")
    sys.exit(1)

# Assign arguments to variables
file_spot = sys.argv[1]
file_modis = sys.argv[2]
file_lai_updated=f'./filled_{file_spot}'

# Open files
ds_spot = xr.open_dataset(f'{file_spot}')
ds_modis = xr.open_dataset(f'{file_modis}')

# Filling the gaps in SPOT LAI data with existing data in MODIS
ds_spot['LAI12M'].data[np.where(ds_spot['LAI12M'].data==0.)] = ds_modis['LAI12M'].data[ds_spot['LAI12M'].data==0.]

# Saving the file
if os.path.exists(f'{file_lai_updated}'):
    os.remove(f'{file_lai_updated}')
ds_spot.to_netcdf(f'{file_lai_updated}')
