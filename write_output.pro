;writes current image to file.  averages total value.  Uses flag to determine if it's hh or hv

PRO write_output, out_dir, total_image, count_image, current_year, current_mon, is_hh

	mon_string = strarr(12)
	mon_string[0] = '001-030D'
	mon_string[1] = '031-060D'
	mon_string[2] = '061-090D'
	mon_string[3] = '091-120D'
	mon_string[4] = '121-150D'
	mon_string[5] = '151-180D'
	mon_string[6] = '181-210D'
	mon_string[7] = '211-240D'
	mon_string[8] = '241-270D'
	mon_string[9] = '271-300D'
	mon_string[10] = '301-330D'
	mon_string[11] = '331-365D'

	;ignore initial image where year and month are 0
	if (current_year eq 0) then return

	;will overwite outfile

	out_val_file = strarr(24)
	out_count_file = strarr(24)

	if(is_hh) then begin
		for i=0, 23 do begin
			out_val_file[i] = out_dir + '/RapidSCAT_pow_' + strtrim(string(current_year,format='(I4)'),2) + '_' + mon_string[current_mon] + '_' + strtrim(string(i,format='(I02)'),2) + 'HR_h.flt'
			out_count_file[i] = out_dir + '/RapidSCAT_count_' + strtrim(string(current_year,format='(I4)'),2) + '_' + mon_string[current_mon] + '_' + strtrim(string(i,format='(I02)'),2) + 'HR_h.flt'
		endfor
	endif else begin
		for i=0, 23 do begin
			out_val_file[i] = out_dir + '/RapidSCAT_pow_' + strtrim(string(current_year,format='(I4)'),2) + '_' + mon_string[current_mon] + '_' + strtrim(string(i,format='(I02)'),2) + 'HR_v.flt'
			out_count_file[i] = out_dir + '/RapidSCAT_count_' + strtrim(string(current_year,format='(I4)'),2) + '_' + mon_string[current_mon] + '_' + strtrim(string(i,format='(I02)'),2) + 'HR_v.flt'
		endfor
	endelse

	for i=0, 23 do begin
		hr_total_image = total_image[*,*,i]
		hr_count_image = count_image[*,*,i]
		index = where(hr_count_image gt 0, count)
		;If no valid pulses, do not write output file
		if(count gt 0) then begin
			openw, val_lun, out_val_file[i], /get_lun
			openw, count_lun, out_count_file[i], /get_lun
			hr_total_image[index] = hr_total_image[index] / hr_count_image[index]

			writeu, val_lun, float(hr_total_image)
			writeu, count_lun, hr_count_image

			free_lun, val_lun, count_lun
		endif
	endfor

End
