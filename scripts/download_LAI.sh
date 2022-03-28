#*******************************************************************************************
# This script runs the python script get_LAI.py that downloads montly LAI obseravtional 
# monthly data from c3s database. 
#
# To run the script 2 arguments are necessary to provide:
# nohup ./download_LAI.sh <year> <month>
# 
# NOTE: For months < 10, put 0 before (i.e. 01 instead of 1)
#
#*******************************************************************************************


# Set conda envirment with python, cdo, nco, ncl
source activate <env_name>] 

# Read argumentas and folders (adjust if necessary)
YEAR=$1
MONTH=$2
domain_boundaries="75, -50, 20, 70"
homedir=`pwd`
datadir="${homedir}/data"
mkdir -p ${datadir}

# Updating the script for downloading data directly from c3s
sed -e "s/YEAR/${YEAR}/g;s/MONTH/${MONTH}/g;s/'AREA'/${domain_boundaries}/g;" get_LAI.py > get_LAI-${YEAR}${MONTH}.py
python get_LAI-${YEAR}${MONTH}.py

# Moving downloaded data to the data folder and cleaning the folder
mv ${YEAR}${MONTH}_download.tar.gz ${datadir}/
rm get_LAI-${YEAR}${MONTH}.py
exit 0
