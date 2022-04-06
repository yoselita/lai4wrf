#!/bin/bash -l
########################################################################################
# Scripts used:
# 	1. download_LAI.sh + get_LAI.py
# 	2. calculate_monthly_mean.sh
# 	3. remap2WRF.sh mean + to_cf.ncl + read_grid.py
#	4. newLAI2geo_em.ncl
#	5. plot_2D_LAI.py 
# Input data and files:
#	1. geo_em.d01.nc file - output from WPS
########################################################################################

# Activate conda enviroment with NCL, cdo, nco, Ngl, Nio, numpy
source activate NCLtoPY

# Define start/end year/month, and the version the LAI observational data
export start_year=1999
export start_month=01
export end_year=2013
export end_month=12
export data_version="1.0.1"

# Define what to do
export download_data="false"
export calculate_means="false" 	# input needed: ${datadir}/*c3s_LAI_${year}${month}*000000_GLOBE_VGT_V${data_version}.nc
export remap_data="true"		# input needed: ${means}/mean_LAI_${month}*.nc geo_em.d01.nc
export newLAI2wrf="false"		# input needed: geo_em.d01.nc, remapped_mean_LAI_${month}.nc
export plot_LAI="false"		# input needed: geo_em.d01_default_LAI.nc (i.e. renamed geo_em.d01.nc), geo_em.d01_new_LAI.nc

# Define all the directories where the script will be run and data stored
export wrkdir=`pwd`
export datadir="${wrkdir}/data"
export means="${wrkdir}/LAI_means/"
export map_data="${wrkdir}/2Dmaps/"
[ -d ${datadir} ] || mkdir ${datadir} 
[ -d ${means} ] || mkdir ${means} 
[ -d ${map_data} ] || mkdir ${map_data} 

# Define sequences of years and months
years=$(seq $start_year $end_year)
months=$(seq -w $start_month $end_month)

# Download data and untar the files
if [ ${download_data} == "true" ]; then
   cd $wrkdir
   for year in ${years}; do
      for month in ${months}; do 
         ./download_LAI.sh ${year} ${month}
         tar -zxvf *.tar.gz
         [ -d tar_files ] || mkdir tar_files
         mv *.tar.gz tar_files/
    done
  done
fi

# Calculate monthly means, output will be located in $means
if [ ${calculate_means} == "true" ]; then
   cd $wrkdir
   ./calculate_monthly_mean.sh ${data_version}
fi

# Remapping
if [ ${remap_data} == "true" ]; then
   cd $wrkdir
   for month in ${months}; do 
      ./remap2WRF.sh mean_LAI_${month}.nc geo_em.d01.nc	${means}
   done
   mv weights.nc destination.grid remapped_mean_LAI_*.nc ${map_data}/
fi

# Implement new LAI information into the geo_em file (overwriting LAI12M variable)
if [ ${newLAI2wrf} == "true" ]; then
   cd $wrkdir
   cp geo_em.d01.nc geo_em.d01_default_LAI.nc 
   for month in ${months}; do 
      ncl 'month="'${month}'"' 'geo_file = "geo_em.d01.nc"' 'filename = "'${map_data}'/remapped_mean_LAI_'${month}'.nc"' newLAI2geo_em.ncl
   done
fi

# Plotting new and old LAI maps, and the difference between them
if [ ${plot_LAI} == "true" ]; then
   cd $wrkdir
   cp geo_em.d01.nc geo_em.d01_new_LAI.nc
   python3 plot_2D_LAI.py geo_em.d01_new_LAI.nc geo_em.d01_default_LAI.nc
fi
mv *.pdf geo_em.d01_new_LAI.nc geo_em.d01_default_LAI.nc ${map_data}/
