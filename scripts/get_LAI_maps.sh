#!/bin/bash
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

export start_year=2004
export start_month=01
export end_year=2013
export end_month=12
export data_version="v01"

export wrkdir=`pwd`
export rawdata="${wrkdir}/data"
export means="${wrkdir}/LAI_means/"
export map_data="${wrkdir}/2Dmaps/"

years=$(seq $start_year $end_year)
months=$(seq -w $start_month $end_month)

for year in ${years}; do
   for month in ${months}; do 
   	./download_LAI.sh ${year} ${month}
   done
done

# Data will be located in $datadir folder. Untar the files
cd $datadir
tar -cxvf *.tar
[ -d tar_files ] || mkdir tar_files
mv *.tar tar_files/

# Calculate monthly means, output will be located in $means
cd $wrkdir
./calculate_monthly_mean.sh ${data_version}

cd $wrkdir
# Remapping
for month in ${months}; do 
   	./remap2WRF.sh mean_LAI_${month}_${data_version}.nc geo_em.d01.nc	
done
[ -d ${map_data} ] || mkdir ${map_data} 
mv remapped_mean_LAI_*.nc ${map_data}/

# Implement new files into the geo_em file
cp geo_em.d01.nc geo_em.d01_default_LAI.nc 
for month in ${months}; do 
	ncl 'month="'${month}'"' 'geo_file = "geo_em.d01.nc"' 'filename = "'${map_data}'/remapped_mean_LAI_01_v'${month}'.nc"' newLAI2geo_em.ncl
done

cd $wrkdir
# Plotting new and old LAI maps
mv geo_em.d01.nc geo_em.d01_new_LAI.nc
python3 plot_2D_LAI.py geo_em.d01_default_LAI.nc geo_em.d01_new_LAI.nc
