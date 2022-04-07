Set od programs and scripts used for processing LAI observational data for WRF
=============

A) Steps and scripts to process the 2D map data (run ./get_LAI_tabels.sh):

1. Download LAI
	./download_LAI.sh <year> <month> (note: for month < 10, put 0 before the integer)
	the scripts calls get_LAI.py. After downloading, untar the data.
	
2. Calculate monthly mean values over a selected period
	./calculate_monthly_mean.sh

3. Remap LAI data to the WRF grid
	./remap2WRF.sh <LAI file - output from step2> <geo_em file>
	  the script uses to_cf.ncl and read_grid.py to get all the information necessary for the interpolation
	  to_cf.ncl creates a cf conform file from a geo_em file obtained after running geogrig.exe in WPS
	  read_grid.py is a script shared within the CORDEX comunity that calculates corners of all grid cells, which ensures the correct interpolations

4. Read the new LAI and replace the default LAI in geo_em file with the new values
	ncl 'month="month with 0 before for months < 10"' 'geo_file = "<geo_em file>"' 'filename = "<output from step3>"' newLAI2geo_em.ncl
	
B) Steps and scripts to process the table data (run ./get_LAI_maps.sh):

1. The same as the step 1 in processing the 2D map data
2. The same as the step 3 in processing the 2D map data
3. Remap WRF land use data to 1km grid of LAI data
	./remap2LAI.sh <geo_em file> <LAI file - output from step2>
	the script uses to_cf.ncl and read_grid.py to get all the information necessary for the interpolation
	to_cf.ncl creates a cf conform file with land use from a geo_em file obtained after running geogrig.exe in WPS
	read_grid.py calculated corners of all grid cells of the WRF grid, which ensures the correct interpolations
4. Calculate mean LAI per land use category
 	ncl 'path2means="'<path to output from step2>'"' 'LUfile="<output from step3>"' 'data_version="<version of the LAI data>"' meanLAIperCAT.ncl
	
Scripts to plot table data and LAI maps:
1. Plot  LAI2D maps:
	python3 plot_2D_LAI.py <geo_em.nc_old_LAI> <geo_em.nc_new_LAI>
	
	Necessary input:<br/>
		&emsp;geo_em.nc_default_LAI	- original output after running ./geogrid.exe<br/>
		&emsp;geo_em.nc_new_LAI	- (output from step A.4)<br/>

2. Plot table data:
	python3 plot_LAI_montly_means_per_cat.py <data1_version> <data2_version> (arguments optional)
	
	Necessary input: <br/>
	    &emsp; LU_CATS.txt 		- List of category names <br/>
		&emsp; LAI_MPTBL.csv 		- LAI from MPTABLE.TBL from WRF <br/>
		&emsp; LAI_VEGTBL.csv  	- LAI from VERGPARM.TBL from WRF <br/>
		&emsp; LAI_avg_v1.0.1.csv	- LAI means (output from step B.4) <br/>
		&emsp; LAI_avg_std_v1.0.1.csv	- LAI maximum values (output from step B.4) <br/>
		&emsp; LAI_max_v1.0.1.csv	- LAI mean LAI per categories standard deviation (output from step B.4) <br/>
		&emsp; Ngrids_per_cat.txt	- Percentage of the category within the indicated domain (output from step B.4) <br/>
	Optional input: <br/>
		&emsp; LAI_avg_v03.csv	- LAI means v03 (other set of LAI data) <br/>
		&emsp; LAI_avg_std_v03.csv	- LAI maximum values v03 (other set of LAI data) <br/>
		&emsp; LAI_max_v03.csv	- LAI mean LAI per categories standard deviation v03 (other set of LAI data) <br/>

		

	
