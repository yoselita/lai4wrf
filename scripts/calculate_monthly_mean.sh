#!/bin/bash
########################################################################################
# This script calaculates monthly mean LAI over various years.
# Downloaded data are whole globe, so we cut domain to avoid possible memory issues
# The filename format of the data should be:
# "c3s_LAI_${year}${month}${nominal_day}000000_GLOBE_VGT_${data_version}.nc"
#
# NOTE: adjust the filename format in the raw 33 is using different data source
########################################################################################
source activate <env_name>

# Define all years and months for which data are available
domain_boundaries="-50,70,20,75"		# define domain boudaries: lon_west,lon_east,lat_south,lat_north
years=`seq start_year end_year`		# define start and end year of your downloaded data
months=`seq -w 1 12`
data_version=$1				# adjust data version if necessary. 

# Define input and output directory
wrkdir=`pwd`
datadir="${wrkdir}/data/"
outdir="${wrkdir}/monthly_means/"
merged="${wrkdir}/merged/"
means="${wrkdir}/LAI_means/"
[ -d ${outdir} ] || mkdir ${outdir}
[ -d ${merged} ] || mkdir ${merged}
[ -d ${means} ] || mkdir ${means}

# Eneter the data directory
cd ${datadir}

# Calculate montlhy mean per each year
for year in ${years}; do
   for month in ${months}; do
    	# Mergening files per month per year
		raw_files="*c3s_LAI_${year}${month}*000000_GLOBE_VGT_V${data_version}.nc" # If different name, has to be adjusted
		if [ ! -f ${outdir}/mean_${year}${month}.nc ]; then 			
			for file in ${raw_files}; do	
				if [ ! -f cut_${file} ]; then			 
					cdo sellonlatbox,${domain_boundaries} -select,name=LAI ${file} cut_${file}
				fi
			done
			cdo mergetime cut_${raw_files} merged_${year}${month}.nc; rm cut_${raw_files}
		fi		
	fi

    	# Calculating montlhy mean per each year
	if [ ! -f ${outdir}/mean_${year}${month}.nc ]; then
		cdo timmean merged_${year}${month}.nc ${outdir}/mean_${year}${month}.nc
		rm merged_${year}${month}.nc 
	else
		cdo -select,name=LAI ${outdir}/mean_${year}${month}.nc ${outdir}/out_${year}${month}.nc
		mv ${outdir}/out_${year}${month}.nc ${outdir}/mean_${year}${month}.nc
		echo "File ${outdir}/mean_${year}${month}.nc exists, extracting only LAI or skipping!"
	fi
   done
done

# Calculate montlhy mean and maximum over the defined period of years
for month in ${months}; do
	# Merging files per month
	filenames="mean_*_${month}.nc"
	cdo mergetime ${outdir}/${filenames} ${merged}/merged_LAI_${month}.nc
	# Calculation mean and max over defined period of years
	cdo timmean   ${merged}/merged_LAI_${month}.nc ${means}/mean_LAI_${month}.nc
	cdo timmax    ${merged}/merged_LAI_${month}.nc ${means}/max_LAI_${month}.nc
done

