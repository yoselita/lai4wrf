;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; geogrid_to_cf.ncl
; command syntax:
;   ncl 'file_in="file_in.nc"' 'file_out="wrfout.nc"' "domain="d01"' to_cf.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; procedure to process the attributes in creating CF compliant WRF output
procedure assignVarAttCoord(x:numeric)
begin
  ; assign the default missing value
  MissingValue = default_fillvalue("float")
  x!0 = "rlat"
  x!1 = "rlon"
  x@_FillValue = MissingValue
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; start the primary wrfout_to_cf.ncl program
begin
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; configuration settings
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  limS_N  = (/0,9999/)
  limW_E  = (/0,9999/)

  ; set default values for file_in, dir_in, and file_out, if not specified
  if (.not.isvar("file_in")) then
    print("file_in not given, cannot continue")
  end if
  if (.not.isvar("file_out")) then
    print("file_out not given, cannot continue")
  end if
  if (.not.isvar("domain")) then
   domain="d01"
  end if
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;set the flags for selecting variables to be included 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; set the netcdf file global attributes
  fileAtt                = True
  fileAtt@creation_date  = systemfunc("date")
  fileAtt@institution    = "UCAN-IFCA"
  fileAtt@notes          = "Created with NCL script: to_cf.ncl"
  fileAtt@source         = file_in
  fileAtt@output         = file_out
  fileAtt@Conventions    = "CF 1.6, Standard Name Table v19"

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; open the input netcdf file (wrfout file)
  wrfout = addfile(file_in,"r")    
 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; two-dimensional mapping variables
  if (file_in.eq."geo_em."+domain+".nc") then
    lat = todouble(wrfout->XLAT_M(0,:,:))        
    lon = todouble(wrfout->XLONG_M(0,:,:))       
  else if (file_in.eq."source.nc") then
    lat = todouble(wrfout->XLAT(:,:))        
    lon = todouble(wrfout->XLONG(:,:))       
  else
    lat = todouble(wrfout->XLAT(0,:,:))        
    lon = todouble(wrfout->XLONG(0,:,:))      
  end if
  end if
    delete_VarAtts(lat,-1)
    DimLat = dimsizes(lat)
    nS_N = DimLat(0)               		
    nW_E = DimLat(1)               		
    lat@long_name = "Latitude"
    lat@standard_name = "latitude"
    lat@units = "degrees_north"
    assignVarAttCoord(lat) 

    delete_VarAtts(lon,-1)
    lon@long_name = "Longitude"
    lon@standard_name = "longitude"
    lon@units = "degrees_east"
    assignVarAttCoord(lon)      
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; two-dimensional surface/soil variables
  lco = wrfout->LU_INDEX(0,:,:)      	;land mask (1 - land, 0 - water)
     delete_VarAtts(lco,-1)
     lco@long_name = "Land mask"
     lco@standard_name = "land_mask"
     lco@units = ""
     lco@notes = "1=land, 0=water"
     assignVarAttCoord(lco)    
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;check the limits for the output arrays, set 9999 to end of dataset
  if (limS_N(1) .eq. 9999) then 
    limS_N(1) = nS_N-1
  end if
  if (limW_E(1) .eq. 9999) then 
    limW_E(1) = nW_E-1
  end if  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; write post-processed WRF data to netCDF file
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; create empty output file
  if (fileexists(file_out)) then
    system("rm " + file_out )
  end if
  wrfpost = addfile(file_out,"c")   

  ; create the global attributes
  fileattdef(wrfpost, fileAtt)

  ; -two-dimensional mapping variables
  wrfpost->lat=lat
  wrfpost->lon=lon
  wrfpost->lco=lco
end

