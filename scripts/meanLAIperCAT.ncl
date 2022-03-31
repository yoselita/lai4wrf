;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; geogrid_to_cf.ncl
; command syntax:
;   ncl 'path2means="./output/"' 'LUfile="LU_1km.nc"' 'data_version="v01"' mean_LAI_per_category.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
begin
if (.not.isvar("path2means")) then
	path2means="./data/monthly_means/"
end if
if (.not.isvar("data_version")) then
	data_version="v01"
end if
LUfile="remapped_LU.nc"
LU_cats=(/"ENF", "EBF", "DNF", "DBF", "MF", "CS", "OS", "WS", "S", "G", \
	"PW", "C", "UB", "C/NVM", "SI", "BSV", "W", "WT", "MT", "BT", "L"/)
	
LU_categories=(/"Evergreen Needleleaf Forest", \
        "Evergreen Broadleaf Forest", \
        "Deciduous Needleleaf Forest", \
        "Deciduous Broadleaf Forest", \
        "Mixed Forests", \
        "Closed Shrublands", \
        "Open Shrublands", \
        "Woody Savannas", \
        "Savannas", \
        "Grasslands", \
        "Permanent Wetlands", \
        "Croplands", \
        "Urban and Built-Up", \
        "Cropland/Natural Vegetation Mosaic", \
        "Snow and Ice", \
        "Barren or Sparsely Vegetated", \
        "Water", \
        "Wooded Tundra", \
        "Mixed Tundra", \
        "Barren Tundra", \
        "Lakes"/)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; open the input netcdf file (wrfout file)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
months=(/"01","02","03","04","05","06","07","08","09","10","11","12"/)
LAI_avg        = new((/dimsizes(LU_cats),dimsizes(months)/),"float")
LAI_max        = LAI_avg
LAI_avg_std    = LAI_avg
LAI_max_std    = LAI_avg
LAI_stat       = new((/dimsizes(LU_cats),dimsizes(months),30/),"float")
ngrids_per_cat = new((/dimsizes(LU_cats)/),"string")

; loop over months
do i = 0, dimsizes(months)-1, 1
  month=months(i)
  LAI_file     = addfile(path2means + "mean_LAI_" + month + "_v01.nc","r") 
  LAI_max_file = addfile(path2means + "max_LAI_"  + month + "_v01.nc","r") 
  LU_file      = addfile(LUfile,"r") 
  
  ; load variables
  LAI_raw     = LAI_file->LAI(0,:,:)
  LAI_max_raw = LAI_max_file->LAI(0,:,:)
  LU          = LU_file->lco(:,:)

  LAI = LAI_raw * LAI_raw@scale_factor + LAI_raw@add_offset
  LAI@_FillValue    = default_fillvalue("float")
  LAI@missing_value = default_fillvalue("float")

  LAImax = LAI_max_raw * LAI_max_raw@scale_factor + LAI_max_raw@add_offset
  LAImax@_FillValue    = default_fillvalue("float")
  LAImax@missing_value = default_fillvalue("float")


  ; claculate means per category
  do cat = 1,dimsizes(LU_cats)
   LaiLu    = LU
   LaiLuMax = LU
   LaiLu    = where(LU.eq.cat,LAI,default_fillvalue("float"))
   LaiLuMax = where(LU.eq.cat,LAImax,default_fillvalue("float"))
   LAI_stat(cat-1,i,:)  = stat_dispersion(LaiLu, False)  
   LAI_avg(cat-1,i)     = avg(LaiLu)  
   LAI_avg_std(cat-1,i) = stddev(LaiLu)  
   LAI_max(cat-1,i)     = max(LaiLuMax)  
   LAI_max_std(cat-1,i) = stddev(LaiLuMax) 
   delete(LaiLu)
   delete(LaiLuMax)   
   
   ; Calculate percentage of grids per category
   ngrids = num(.not.ismissing(LU))
   ngrids_cat = num(LU.eq.cat)
   precentage_cat = 100*(tofloat(ngrids_cat)/tofloat(ngrids))
   ngrids_per_cat(cat-1) = sprintf("%5.2f", precentage_cat) + "%, " + LU_categories(cat-1)

  end do
end do
  median = LAI_stat(:,:,8)
  std    = LAI_stat(:,:,2)

  ; write out results in csv files
  option        = True
  option@row    = False
  option@fout   = "LAI_avg_"+data_version+".csv"
  write_matrix (LAI_avg, "16f14.2", option)

  option@fout   = "LAI_avg_std_"+data_version+".csv"
  write_matrix (LAI_avg_std, "16f14.2", option)

  option@fout   = "LAI_max_"+data_version+".csv"
  write_matrix (LAI_max, "16f14.2", option)

  option@fout   = "LAI_max_std_"+data_version+".csv"
  write_matrix (LAI_max_std, "16f14.2", option)

  option@fout   = "LAI_median_"+data_version+".csv"
  write_matrix (median, "16f14.2", option)

  option@fout   = "LAI_stat_std_"+data_version+".csv"
  write_matrix (std, "16f14.2", option)
  
  ; Write out percentage of grids per category
  asciiwrite("Ngrids_per_cat.txt",ngrids_per_cat)

  ; Write out results in nc files
  outnc = "LAI_stat.nc"
  if (isfilepresent(outnc)) then
    system("rm " + outnc )
  end if
  outnc_file = addfile(outnc,"c")
  outnc_file->LAI_stat=LAI_stat

end

