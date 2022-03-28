#!/bin/bash
########################################################################################
# This script calaculates monthly mean LAI over various years.
# The filename format of the data should be:
# "*LAI_${year}${month}*000000_GLOBE_VGT_V1_area_subset.nc"
# or
# "*c3s_LAI_${year}${month}*000000_GLOBE_VGT_V1.0.1.nc"
########################################################################################
source activate <env_name>] 

data_version=$1

# Define all years and months for which data are available
domain_boundaries="75, -50, 20, 70"
years=`seq 2004 2013`
months=`seq -w 1 12`

# Define input and output directory
wrkdir=`pwd`
datadir="${wrkdir}/data/"
outdir="${wrkdir}/monthly_means/"
final_output="${wrkdir}/LAI_means/"
[ -d ${outdir} ] || mkdir ${outdir}
[ -d ${final_output} ] || mkdir ${final_output}

# Eneter the data directory
cd ${datadir}

# Calculate montlhy mean per each year
for year in ${years}; do
   for month in ${months}; do
    	# Mergening files per month per year
    	# Downloaded data for some reason for 2007, 2010, 2011 are downloaded for whole globe, 
    	# cutting while downloading does not work for these years
    	# Therfore we cut the domain so we can megre with the rest of the years
	if [ ${year} == "2007" ] || [ ${year} == "2010" ] || [ ${year} == "2011" ] ; then
		raw_files="*c3s_LAI_${year}${month}*000000_GLOBE_VGT_V1.0.1.nc"
		if [ ! -f ${outdir}/mean_${year}${month}.nc ]; then 			
			for file in ${raw_files}; do	
				if [ ! -f cut_${file} ]; then			 
					cdo -select,name=LAI ${file} var_${file}
					cdo sellonlatbox,${domain_boundaries} var_${file} cut_${file}
					rm var_${file}
				fi
			done
			cdo mergetime cut_${raw_files} merged_${year}${month}.nc
		fi
	else
		files="*LAI_${year}${month}*000000_GLOBE_VGT_V1_area_subset.nc"
		if [ ! -f ${outdir}/mean_${year}${month}.nc ]; then
			for file in ${files}; do
				cdo -select,name=LAI ${file} var_${file}
			done
			cdo mergetime var_${files} merged_${year}${month}.nc
			rm var_${files}
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
	cdo mergetime ${outdir}/${filenames} ${final_output}/merged_LAI_${month}.nc
	
	# Calculation mean and max over defined period of years
	cdo timmean   ${final_output}/merged_LAI_${month}.nc ${final_output}/mean_LAI_${month}_v01.nc
	cdo timmax    ${final_output}/merged_LAI_${month}.nc ${final_output}/max_LAI_${month}_v01.nc
done

