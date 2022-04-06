#!/bin/bash -l
#SBATCH --job-name=mLAI
#SBATCH --output=mLAI%j.out
#SBATCH --error=mLAI%j.error
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=1
#SBATCH --time=10:00:00
#SBATCH --mail-user=milovacj@unican.es
#SBATCH --reservation=meteo

#######################################################################################################
# Scripts used:
# 	1. download_LAI.sh + get_LAI.py
# 	2. calculate_monthly_mean.sh
# 	3. remap2LAI.sh + to_cf.ncl + read_grid.py
# 	4. mean_LAI_per_category.ncl
# 	5. plot_LAI_montly_means_per_cat.py
#
# Input data and files:
#	1. geo_em.d01.nc  -> output file from WPS
# 	2. LAI_MPTBL.csv  -> LAI from MPTABLE.TBL, in csv format - columns(months)  x raws(categories)
#	3. LAI_VEGTBL.csv -> LAI from VEGPARM.TBL, in csv format - columns(min,max) x raws(categories)
#	4. LU_CATS.txt:   -> LAI list of land use categories
#######################################################################################################
source activate NCLtoPY

# Define start/end year/month, and the version the LAI observational data
export start_year=1999
export start_month=01
export end_year=2013
export end_month=12
export data_version="1.0.1"

# Define what to do
export download_data="false"
export calculate_means="false"		# input needed: ${datadir}/*c3s_LAI_${year}${month}*000000_GLOBE_VGT_V${data_version}.nc
export remap_data="true"		# input needed: geo_em.d01.nc, ${means}/mean_LAI_${month}*.nc
export LAIperCAT="true"			# input needed: remapped_LU.nc, ${means}/mean_LAI_${month}*.nc
export plot_LAI="true"			# input needed (minimum): LU_CATS.txt,LAI_MPTBL.csv,LAI_VEGTBL.csv,LAI_avg_1.0.1.csv,LAI_avg_std_1.0.1.csv, LAI_max_1.0.1.csv

# Define all the directories where the scritp will be run and data stored
export wrkdir=`pwd`
export datadir="${wrkdir}/data"			
export means="${wrkdir}/LAI_means/"
export table_data="${wrkdir}/table_output/"
[ -d ${datadir} ] || mkdir ${datadir} 
[ -d ${means} ] || mkdir ${means} 
[ -d ${table_data} ] || mkdir ${table_data} 

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

# Calculate monthly mean LAI, output located in ${means}
if [ ${calculate_means} == "true" ]; then
   cd $wrkdir
   ./calculate_monthly_mean.sh ${data_version}
fi

# Remapping
if [ ${remap_data} == "true" ]; then
   cd $wrkdir
   for month in ${months}; do 
      ./remap2LAI.sh geo_em.d01.nc mean_LAI_01.nc ${means}
   done
fi

# Calculating the mean LAI per each land use category
if [ ${LAIperCAT} == "true" ]; then
   cd $wrkdir
   ncl 'path2means="'${means}'"' 'LUfile="remapped_LU.nc"' 'data_version="'${data_version}'"' meanLAIperCAT.ncl
   mv *.csv *.txt ${table_data}/
fi

# Plot LAI table output
if [ ${plot_LAI} == "true" ]; then
   cd ${table_data}
   python3 ../plot_LAI_monthly_means_per_cat.py ${data_version} 01
fi
