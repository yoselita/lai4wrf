import Ngl,Nio
import numpy as np
import sys
import os

# Python script to be run with 'python3 plot_domain.py argument1 argument2'
# 	argument1= geo_em.nc file, also works with relative or absolute paths
# 	argument2= projection (works with lat-lon and mercator)
# output is a pdf file, located in the working directory

# ------------------------------------------------
# Reading arguments input and projection 
# ------------------------------------------------
months = np.arange(0,12,1)
month_names = ['January','February','March','April','May','June',\
               'July','August','September','October','November','December']
domain = 'EUR11'
varname = 'LAI12M'
projection= 'lat-lon' 	#lat-lon, mercator, lambert	

if len(sys.argv) < 2:
	print("Input not given, cannot continue")
	exit()
elif len(sys.argv) < 3:
	fname=sys.argv[1]  		# geo_em.d01.nc
elif len(sys.argv) < 4:
	fname=sys.argv[1]  		# geo_em.d01.nc
	fname1=sys.argv[2]  		# geo_em.d01.nc
else:
	fname=sys.argv[1]  		# geo_em.d01.nc
	fname1=sys.argv[2]  		# geo_em.d01.nc


# ------------------------------------------------
# Louading file and reading variables, lat/lon
# ------------------------------------------------
file  = Nio.open_file(fname, "r")
var   = file.variables[varname][0,:,:,:]
lat2d = file.variables["XLAT_M"][0,:,:]
lon2d = file.variables["XLONG_M"][0,:,:]
nlon  = lon2d.shape[0]
nlat  = lat2d.shape[1]

if fname1:
    file1  = Nio.open_file(fname1, "r")
    var1   = file1.variables[varname][0,:,:,:]
    delta  = var-var1

# ------------------------------------------------
# Setting the resources
# ------------------------------------------------
# Map resources
mpres = Ngl.Resources()
mpres.mpGeophysicalLineColor      = "Black"
mpres.mpNationalLineColor         = "Black"
mpres.mpUSStateLineColor          = "Black"
mpres.mpGridLineColor             = "Grey"
mpres.mpLimbLineColor             = "Black"
mpres.mpPerimLineColor            = "Black"
mpres.mpGeophysicalLineThicknessF = 1.0
mpres.mpGridLineThicknessF        = 1.0
mpres.mpLimbLineThicknessF        = 1.0
mpres.mpNationalLineThicknessF    = 1.0
mpres.mpOutlineBoundarySets       = "AllBoundaries"
mpres.mpDataBaseVersion           = "mediumres"             
mpres.mpDataSetName               = "Earth..4"
mpres.pmTickMarkDisplayMode       = "always" 
# Map resources for rotated grids
if 'lat-lon' in projection.lower():
	if domain == 'SAM':
		rlat, rlon = 70.6-90,180+123.94
	elif domain == 'EUR11':
		rlat, rlon = 90-39.25,18
	elif domain == 'ALP3':
		rlat, rlon = 90-39.25,18
	else:
		print("Domain not recognized, exiting ...")
		exit()
	mpres.mpProjection    = "CylindricalEquidistant"	# for lat-lon projection for SAM domain
	mpres.mpCenterLonF    = rlon 				# 180-$STAND_LON; for lat-lon projection                  
	mpres.mpCenterLatF    = rlat	   			# $POLE_LAT-90.; for lat-lon projection
elif 'mercator' in projection.lower():
	mpres.mpProjection    = "Mercator"  
else:
	print("Projection not recognized, exiting ...")
	exit()
mpres.mpLimitMode     	      = "Corners"    
mpres.mpLeftCornerLatF       = lat2d[0,0] 
mpres.mpLeftCornerLonF       = lon2d[0,0]
mpres.mpRightCornerLatF      = lat2d[nlon-1,nlat-1]      
mpres.mpRightCornerLonF      = lon2d[nlon-1,nlat-1]
mpres.mpGridAndLimbOn        = False              
mpres.mpGridSpacingF         = 16               
mpres.mpGridLineDashPattern  = 5                 
mpres.tfDoNDCOverlay         = True    
#General resources
res = mpres
res.nglDraw           = False
res.nglFrame          = False
res.nglMaximize       = True  
# Labelbar resources  
res.lbLabelBarOn       = False
res.lbOrientation      = "Horizontal"
res.lbLabelPosition    = "Bottom"
res.lbBoxMinorExtentF  = 0.15
res.lbLabelFontHeightF = 0.01 
res.lbTitleOn          = False
#res.lbBoxEndCapStyle   = "TriangleHighEnd" 
# Thickmark resources    
res.tmXBOn = False 
res.tmXTOn = False  
res.tmYLOn = False  
res.tmYROn = False 
# Contour resources    
res.cnFillOn             = True   
res.cnFillMode           = "RasterFill"          
res.cnLinesOn            = False            
res.cnLineLabelsOn       = False   
# Special resources    
res_single                      = res
res_single.cnLevelSelectionMode = "ManualLevels"	      
res_single.cnFillPalette        = "WhiteBlueGreenYellowRed" 
res_single.cnMinLevelValF       = 0.			
res_single.cnMaxLevelValF       = 6.5
res_single.cnLevelSpacingF      = 0.25
res_single.nglSpreadColors      = False 


# ------------------------------------------------
# Plotting
# ------------------------------------------------

# Panel resources
pnlres = Ngl.Resources()
pnlres.nglFrame = False
pnlres.nglPanelLabelBar = True
pnlres.lgLabelFontHeightF = .02
pnlres.txString = "new-old"
pnlres.txFontHeightF = 0.02

txres = Ngl.Resources()
txres.txFontHeightF = 0.020

#output = os.path.splitext(os.path.basename(fname))[1]

outname = fname.split("_")[2]
wks     = Ngl.open_wks("pdf","monthly_LAI_"+outname)
plot = []
for month in months:
    res_single.tiMainString = month_names[month]
    p = Ngl.contour_map(wks,var[month,:,:],res_single)
    plot.append(p) 
# Paneling
Ngl.panel(wks,plot[0:12],[3,4],pnlres)
Ngl.text_ndc(wks,outname + " LAI",0.5,0.975,txres)
Ngl.frame(wks)


if fname1:
    outname = fname1.split("_")[2]
    wks1     = Ngl.open_wks("pdf","monthly_LAI_"+outname) 
    plot_var1 = []
    for month in months:
        res_single.tiMainString = month_names[month]
        p1 = Ngl.contour_map(wks1,var1[month,:,:],res_single)
        plot_var1.append(p1)
    # Paneling 
    Ngl.panel(wks1,plot_var1[0:12],[3,4],pnlres)
    Ngl.text_ndc(wks1,outname + " LAI",0.5,0.975,txres)
    Ngl.frame(wks1)

    outname = fname.split("_")[2]+"-"+fname1.split("_")[2]
    wks_diff = Ngl.open_wks("pdf","monthly_diff_LAI") 
    plot_diff = []
    res_diff                      = res
    res_diff.lbBoxEndCapStyle     = "TriangleBothEnds" 
    res_diff.cnLevelSelectionMode = "ManualLevels"	      
    res_diff.cnFillPalette        = "temp_diff_18lev" 
    res_diff.cnMinLevelValF       = -3			
    res_diff.cnMaxLevelValF       = 3
    res_diff.cnLevelSpacingF      = 0.1
    res_diff.nglSpreadColors      = False
    for month in months:	
        res_diff.tiMainString = month_names[month]
        p_diff = Ngl.contour_map(wks_diff,delta[month,:,:],res_diff)
        plot_diff.append(p_diff)
    # Paneling 
    Ngl.panel(wks_diff,plot_diff[0:12],[3,4],pnlres)
    Ngl.text_ndc(wks_diff,"LAI (" + outname + ")",0.5,0.975,txres)
    Ngl.frame(wks_diff) 
Ngl.end()
 

