;This procedure takes an input directory, finds all the RapidSCAT L1B revolution files in them
;And bins all the pulses and puts the daily global images into the output directory
;RapidSCAT files are assumed to start with RS_ for file name


PRO process_directory, in_dir, revtime_file, out_dir

	;!EXCEPT = 2  ;verbose reporting on math errors

	;Test if in_dir and out_dir exists
	if(not(file_test(in_dir, /directory) and file_test(out_dir, /directory))) then begin
		print, 'Fatal Error:  input or output directory not valid.', in_dir, out_dir
		exit
	endif

	if(not(file_test(revtime_file))) then begin
		print, 'Fatal Error: revtime file cannot be found.', revtime_file
		exit
	endif

	print, "Processing RapidSCAT L1B data with indir ", in_dir, "and outdir ", out_dir
	print, systime()


	input_files = file_search(in_dir + '/RS_*')
	if (n_elements(input_files) eq 0) then begin
		print, 'No input files found in ', in_dir
		exit
	endif
	n_infiles = n_elements(input_files)


	;Read revtime file
	;//we are assuming that we added 2 lines of string to the csv file so that read_csv parses it as string
	revtime_data = read_csv(revtime_file)
	nrevs = n_elements(revtime_data.(0))-2

	revnum = fix((revtime_data.(0))[2:nrevs-1])
	start_time = (revtime_data.(1))[2:nrevs-1]	
	end_time = (revtime_data.(2))[2:nrevs-1]	
	note = (revtime_data.(4))[2:nrevs-1]


	;Create image for current total and count
	;0.25deg x 0.25 deg
	power_total_hh = fltarr(1440,720,24)
	power_total_vv = fltarr(1440,720,24)
	pulse_count_hh = bytarr(1440,720,24)
	pulse_count_vv = bytarr(1440,720,24)
	current_year_hh = 0
	current_year_vv = 0
	;current_day_hh = 0
	;current_day_vv = 0
	current_mon_hh = 0  ;Month here is defined as (Julian day / 30)  where the division is integer division
	current_mon_vv = 0  ;Therefore, the last month has 35 - 36 days, this is used to tell when to reset our averaging

	;Cycle through each input revolution file.  Based on the naming convention, files should be in chronological order

	for i_file=0, n_infiles-1 do begin
		cur_file = input_files[i_file]
		cur_rev = fix(strmid(cur_file,strlen(in_dir)+1+6,5))
		
		rev_index = where(revnum eq cur_rev, count)
		if (count ne 1) then begin
			print, 'ERROR!  rev number matching error ', cur_file, cur_rev, '   n matches: ', count
			exit
		endif

		if (strmid(note[rev_index],0,3) eq 'BAD') then begin
			print, 'Bad rev at rev#', cur_rev, '  skipping...'
			continue
		endif

		;process file
		read_rev, cur_file, start_time[rev_index], end_time[rev_index], sigma0_hh, sigma0_vv, inc_rad_hh, inc_rad_vv, lon_hh, lon_vv, lat_hh, lat_vv, day_hh, day_vv, year_hh, year_vv, local_hr_hh, local_hr_vv

		;Process hh pulses
		n_h_pulse = n_elements(sigma0_hh)
		for i=0, n_h_pulse-1 do begin
			;x_ind = fix(lon_hh[i] * 0.01 / 0.25)   ; Longitude is stored as integer in units of 0.01 degrees from 0 to 360 deg
			;y_ind = fix((90 - lat_hh[i] * 0.01) / 0.25) ; Latitude is stored as integer in units of 0.01 degrees from -90 to 90 deg
			;apparently documentation is wrong, lon and lat are read out as floating points
			x_ind = fix(lon_hh[i] / 0.25)
			y_ind = fix((90 - lat_hh[i]) / 0.25) 
			if (x_ind eq 1440) then x_ind = 0  ; wrap end points
			if (x_ind lt 720) then x_ind += 720 else x_ind -=720   ; change to -180 to 180 degree format
			if (y_ind eq 720) then y_ind = 0  ; wrap end points
			
			if ((day_hh[i]/30 ne current_mon_hh) or (year_hh[i] ne current_year_hh)) then begin
				;Reached new mon, write output, and reset
				write_output, out_dir, power_total_hh, pulse_count_hh, current_year_hh, current_mon_hh, 1  ;1 because this is h polarization

				;after writing output of previous collected data, reset to new mon and add our current pulse
				power_total_hh[*] = 0
				pulse_count_hh[*] = 0

				current_year_hh = year_hh[i]
				current_mon_hh = day_hh[i]/30
			endif

			power_total_hh[x_ind,y_ind,local_hr_hh] += (10.^ (sigma0_hh[i] / 1000))/cos(inc_rad_hh[i])
			pulse_count_hh[x_ind,y_ind,local_hr_hh] += 1

		endfor			


		;Process vv pulses
		n_v_pulse = n_elements(sigma0_vv)
		for i=0, n_v_pulse-1 do begin
			;x_ind = fix(lon_vv[i] * 0.01 / 0.25)   ; Longitude is stored as integer in units of 0.01 degrees from 0 to 360 deg
			;y_ind = fix((90 - lat_vv[i] * 0.01) / 0.25) ; Latitude is stored as integer in units of 0.01 degrees from -90 to 90 deg
			;apparently documentation is wrong, lon and lat are read out as floating points
			x_ind = fix(lon_vv[i] / 0.25)  
			y_ind = fix((90 - lat_vv[i]) / 0.25) 
			if (x_ind eq 1440) then x_ind = 0  ; wrap end points
			if (x_ind lt 720) then x_ind += 720 else x_ind -=720   ; change to -180 to 180 degree format
			if (y_ind eq 720) then y_ind = 0  ; wrap end points
			
			if ((day_vv[i]/30 ne current_mon_vv) or (year_vv[i] ne current_year_vv)) then begin
				;Reached new mon, write output, and reset
				write_output, out_dir, power_total_vv, pulse_count_vv, current_year_vv, current_mon_vv, 0  ;0 because this is v polarization

				;after writing output of previous collected data, reset to new mon and add our current pulse
				power_total_vv[*] = 0
				pulse_count_vv[*] = 0

				current_year_vv = year_vv[i]
				current_mon_vv = day_vv[i]/30
			endif

			power_total_vv[x_ind,y_ind,local_hr_vv] += (10.^ (sigma0_vv[i] / 1000))/cos(inc_rad_vv[i])
			pulse_count_vv[x_ind,y_ind,local_hr_vv] += 1

		endfor			

		;Flush the remaining cache
		write_output, out_dir, power_total_hh, pulse_count_hh, current_year_hh, current_mon_hh, 1  ;1 because this is h polarization
		write_output, out_dir, power_total_vv, pulse_count_vv, current_year_vv, current_mon_vv, 0  ;0 because this is v polarization

	endfor

	print, 'Finished processing directory.', systime()

End
