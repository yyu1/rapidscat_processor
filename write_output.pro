;writes current image to file.  averages total value.  Uses flag to determine if it's hh or hv

PRO write_output, out_dir, total_image, count_image, current_year, current_day, is_hh

	;ignore initial image where year and day are 0
	if (current_year eq 0) then return

	;will overwite outfile

	if(is_hh) then begin
		out_val_file = out_dir + '/RapidSCAT_pow_' + strtrim(string(current_year,format='(I4)'),2) + '_' + strtrim(string(current_day,format='(I03)'),2) + '_h.flt'
		out_count_file = out_dir + '/RapidSCAT_count_' + strtrim(string(current_year,format='(I4)'),2) + '_' + strtrim(string(current_day,format='(I03)'),2) + '_h.byt'
	endif else begin
		out_val_file = out_dir + '/RapidSCAT_pow_' + strtrim(string(current_year,format='(I4)'),2) + '_' + strtrim(string(current_day,format='(I03)'),2) + '_v.flt'
		out_count_file = out_dir + '/RapidSCAT_count_' + strtrim(string(current_year,format='(I4)'),2) + '_' + strtrim(string(current_day,format='(I03)'),2) + '_v.byt'
	endelse


	index = where(count_image gt 0, count)
	;If no valid pulses, do not write output file
	if(count gt 0) then begin
		openw, val_lun, out_val_file, /get_lun
		openw, count_lun, out_count_file, /get_lun
		total_image[index] = total_image[index] / count_image[index]

		writeu, val_lun, float(total_image)
		writeu, count_lun, count_image

		free_lun, val_lun, count_lun
	endif

End
