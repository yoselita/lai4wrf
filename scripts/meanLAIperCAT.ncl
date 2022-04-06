;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; geogrid_to_cf.ncl
; command syntax:
;   ncl 'path2means="./output/"' 'LUfile="remapped_LU.nc"' 'data_version="1.0.1"' mean_LAI_per_category.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
begin

; Read arguments
if (.not.isvar("path2means")) then
	path2means="./monthly_means/"
end if
if (.not.isvar("data_version")) then
	data_version="1.0.1"
end if

if (.not.isvar("data_version")) then
	LUfile="remapped_LU.nc"
end if

; Define months
months=(/"01","02","03","04","05","06","07","08","09","10","11","12"/)

; Define short and longname categories
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

; Allocate all arrays
LAI_avg        = new((/dimsizes(LU_cats),dimsizes(months)/),"float",-999)
LAI_avg_std    = LAI_avg
LAI_max        = LAI_avg
ngrids_per_cat = new((/dimsizes(LU_cats)/),"string","nan")

;Load the land use map 
LU_file     = addfile(LUfile,"r") 
LU          = LU_file->lco(:,:)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Calculating
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Loop over months
do i = 0, dimsizes(months)-1, 1
  month=months(i)
  print("Calculating for the month: " + month)
  LAI_file     = addfile(path2means + "mean_LAI_" + month + ".nc","r") 
  LAI_max_file = addfile(path2means + "max_LAI_"  + month + ".nc","r") 

  
  ; Load variables
  LAI_raw     = LAI_file->LAI(0,:,:)
  LAI_max_raw = LAI_max_file->LAI(0,:,:)


  LAI = LAI_raw * LAI_raw@scale_factor + LAI_raw@add_offset
  LAI@_FillValue    = default_fillvalue("float")
  LAI@missing_value = default_fillvalue("float")

  LAI_maximum = LAI_max_raw * LAI_max_raw@scale_factor + LAI_max_raw@add_offset
  LAI_maximum@_FillValue    = default_fillvalue("float")
  LAI_maximum@missing_value = default_fillvalue("float")


  ; Loop over categories
  do cat = 1,dimsizes(LU_cats),1
   print("	Calculating LAI for the category " + cat + "-" + LU_categories(cat-1))
   LaiLu    = LU
   LaiLuMax = LU
   LaiLu    = where(LU.eq.cat,LAI,default_fillvalue("float"))
   LaiLuMax = where(LU.eq.cat,LAI_maximum,default_fillvalue("float"))

   ; Calculate statistics per category
   LAI_avg(cat-1,i)     = avg(LaiLu) 
   LAI_avg_std(cat-1,i) = stddev(LaiLu) 
   LAI_max(cat-1,i)     = max(LaiLuMax)  
   delete(LaiLu)
   delete(LaiLuMax)   
   
   ; Calculate percentage of grids per category
   ngrids = num(.not.ismissing(LU))
   ngrids_cat = num(LU.eq.cat)
   precentage_cat = 100*(tofloat(ngrids_cat)/tofloat(ngrids))
   ngrids_per_cat(cat-1) = sprintf("%5.2f", precentage_cat)

  end do
end do

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing data out in a csv/txt format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print("Writing data into the tables")
nrows = dimsizes(LAI_avg(:,0))
LAIavg = new(nrows, string)  
LAIstd = new(nrows, string)     
LAImax = new (nrows, string) 
do i = 0, nrows-1
   LAIavg(i) = str_concat (sprintf("%16.2f", LAI_avg(i,:)))
   LAIstd(i) = str_concat (sprintf("%16.2f", LAI_avg_std(i,:)))
   LAImax(i) = str_concat (sprintf("%16.2f", LAI_max(i,:)))
end do  
asciiwrite ("LAI_avg_v"+data_version+".csv", LAIavg)
asciiwrite ("LAI_avg_std_v"+data_version+".csv", LAIstd)
asciiwrite ("LAI_max_v"+data_version+".csv", LAImax)
asciiwrite ("Ngrids_per_cat.txt", ngrids_per_cat)
end

