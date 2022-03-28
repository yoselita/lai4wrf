#!/bin/bash
########################################################################################
# Scripts used:
# 	1. download_LAI.sh + get_LAI.py
# 	2. calculate_monthly_mean.sh
# 	3. remap2LAI.sh + to_cf.ncl + read_grid.py
# 	4. mean_LAI_per_category.ncl
# 	5. plot_LAI_montly_means_per_cat.py
# Input data and files:
#	1. geo_em.d01.nc file - output from WPS
# 	2. LAI from MPTABLE.TBL, in csv format - columns(months)  x raws(categories)
#	3. LAI from VEGPARM.TBL, in csv format - columns(min,max) x raws(categories)
#	4. LAI list of land use categories - LU_CATS.txt
########################################################################################

start_year=2004
start_month=01
end_year=2013
end_month=12

export wrkdir=`pwd`
export rawdata="${wrkdir}/data"
export means="${wrkdir}/LAI_means/"
export table_data="${wrkdir}/table/"

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

cd $wrkdir
# Calculate monthly means, output will be located in $means
./calculate_monthly_mean.sh

cd $wrkdir
# Remapping
./remap2LAI.sh geo_em.d01.nc mean_LAI_01_v01.nc

cd $wrkdir
# Calculating the mean LAI per each of 21 category
ncl 'path2means="'${means}'"' 'LUfile="remapped_LU.nc"' 'data_version="v01"' meanLAIperCAT.ncl
[ -d ${table_data} ] || mkdir ${table_data} 
mv *.csv *.txt ${table_data}/

cd ${table_data}
# Plot LAI table output
python3 ../plot_LAI_montly_means_per_cat.py




