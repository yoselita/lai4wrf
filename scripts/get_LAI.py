#*****************************************************************************
# Python script that downloads LAI data from C3S database 
#  
# The script uses Climate Data Store Application Program Interface (CDS API)
# 
# Manual how to insall and enable it, please check: 
#  https://cds.climate.copernicus.eu/api-how-to
# 
# NOTE: If to donwoad data for Europe, 'area':[75, -50, 20, 70,]
# For other regions this needs to be adapted
#*****************************************************************************

import cdsapi

c = cdsapi.Client()

c.retrieve(
    'satellite-lai-fapar',
    {
        'variable': 'lai',
        'satellite': 'spot',
        'sensor': 'vgt',
        'horizontal_resolution': '1km',
        'product_version': 'V1',
        'year': 'YEAR',
        'month':  'MONTH',
        'nominal_day': [
            '10', '20', '28',
            '30', '31',
        ],
        'format': 'tgz',
    },
    'YEARMONTH_download.tar.gz')
