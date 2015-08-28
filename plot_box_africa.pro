;Plots 24-hr variation in backscatter given location of a box
;pixels inside box are averaged with missing values ignored

set_plot, 'PS'
device, filename='africa_diurnal_backscatter.ps', /landscape


;latitude and longitude bounds
lat_min = -3
lat_max = 5
lon_min = 10
lon_max = 29
;convert to grid index
xmin = fix((lon_min + 180.) / 0.25)
xmax = fix((lon_max + 180.) / 0.25)
ymin = fix((90. - lat_max) / 0.25)
ymax = fix((90. - lat_min) / 0.25)

;day_range
day_range = '031-060'
year = '2015'

;directory
directory = '/Volumes/RapidSCAT/processed_output/'

;images
xdim = 1440ULL
ydim = 720ULL
h_image = fltarr(xdim,ydim)
v_image = fltarr(xdim,ydim)

;averaged data
h_val = fltarr(24)
v_val = fltarr(24)


h_files = strarr(24)
v_files = strarr(24)
;make file names
for i=0, 23 do begin
	h_files[i] = directory + 'RapidSCAT_pow_' + year +'_'+ day_range + 'D_' + strtrim(string(i,format='(I02)'),2) + 'HR_h.flt'
	v_files[i] = directory + 'RapidSCAT_pow_' + year +'_'+ day_range + 'D_' + strtrim(string(i,format='(I02)'),2) + 'HR_v.flt'

;	print, h_files[i]
;	print, v_files[i]
endfor


;calculate averages
for i=0, 23 do begin
	openr, h_lun, h_files[i], /get_lun
	readu, h_lun, h_image
	free_lun, h_lun

	openr, v_lun, v_files[i], /get_lun
	readu, v_lun, v_image
	free_lun, v_lun

	hbox = h_image[xmin:xmax, ymin:ymax]
	vbox = v_image[xmin:xmax, ymin:ymax]	

	index = where(hbox gt 0, count)
	if (count gt 0) then h_val[i] = mean(hbox[index])
	index = where(vbox gt 0, count)
	if (count gt 0) then v_val[i] = mean(vbox[index])

endfor



;create plot
hour = indgen(24)
@plot01
PLOT, hour, h_val, title='Africa RapidSCAT backscatter Day31-60', xtitle='Hour', ytitle='Backscatter power', psym=4, linestyle=0, yrange=[0.16,0.26]
OPLOT, hour, v_val, psym=5, linestyle=0

;annotation
xyouts, 10, 0.25, 'H Polarization'
xyouts, 10, 0.18, 'V Polarization'

device, /close

end
