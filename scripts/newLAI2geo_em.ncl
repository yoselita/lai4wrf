;***********************************************************************************************
; This script reades montlhy mean LAI observational data remapped to
; the WRF grid, converts ushort data format to float, and changes LAI12M
; varaiable in geo_em file. 
;  
; To run the script:
; ncl test.ncl 'month="07"' 'geo_file = "geo_em_filename"' 'filename = "remapped_LAI_filename"'
;***********************************************************************************************
begin
  
  ; Read argument "Month"
  if (.not.isvar("month")) then
    month = "01"
  end if

  ; Loading geo info from the geo_em file
  if (.not.isvar("geoem_file")) then
    geo_file = "geo_em.d01"
  end if
  file_geo  = addfile(geo_file + ".nc","r")
  ; Reading LAI from the geo_em file
  LAI_geo   = file_geo->LAI12M(:,toint(month)-1,:,:)
  delete(file_geo)

  ; Loading info from the file with remapped LAI
  if (.not.isvar("filename")) then
    filename = "remapped_mean_LAI_"+month+"_v01"
  end if
  file_remapped  = addfile(filename + ".nc","r")
  ; Reading LAI from the remapped file
  LAI_raw = file_remapped->LAI

  ; Converting LAI from ushort to float
  LAI_float = tofloat(LAI_raw)

  ; Gettring the correct values
  LAI = LAI_float*LAI_raw@scale_factor + LAI_raw@add_offset

  ; Filling the missing values with the values from LAI obtained from MODIS
  LAI_filled = where(ismissing(LAI),LAI_geo,LAI)

  ; Writing new data into geo_em file
  finput  = addfile(geo_file+".nc","w")
  finput->LAI12M(:,toint(month)-1,:,:)=LAI_filled
  
end
