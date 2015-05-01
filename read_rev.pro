;READS one revolution file and parse and ingest the needed data
;Quality is checked here and only sigma_0 values that pass the quality check are returned

;overlapped values from previous and next revolutions at beginning and end of data are discarded

;sigma0_hh, sigma0_vv, lon_hh, lon_vv, day_hh, day_vv are pass by reference variable names
;whose value will contain the parsed data (after filtering for quality)
;all <variable>_hh should have the same number of elements
;same for all <variable>_vv


PRO read_rev, file_name, start_time, end_time, sigma0_hh, sigma0_vv, inc_rad_hh, inc_rad_vv, lon_hh, lon_vv, lat_hh, lat_vv, day_hh, day_vv, year_hh, year_vv

	if (not hdf_ishdf(file_name)) then begin
		print, 'Invalid HDF file:', file_name
		return
	endif

	undefine, sigma0_hh
	undefine, sigma0_vv
	undefine, lon_hh
	undefine, lon_vv
	undefine, lat_hh
	undefine, lat_vv
	undefine, day_hh
	undefine, day_vv
	undefine, year_hh
	undefine, year_vv


	;Get frame_time from VData
	hdf_file_id = hdf_open(file_name, /read)
	vd_id = hdf_vd_getid(hdf_file_id, -1)
	frame_time_handle = hdf_vd_attach(hdf_file_id, vd_id, /read)
	nframes = hdf_vd_read(frame_time_handle, frame_time)
	hdf_vd_detach,frame_time_handle

	frame_time = string(frame_time)  ;Cast to type string (original 2D byte type)
	;Create frame_mask to mask out repeated frames using start_time and end_time
	frame_mask = create_frame_mask(start_time, end_time, frame_time)
	if (n_elements(frame_mask) ne nframes) then begin
		print, 'Fatal error creating frame mask.  nframes and frame_mask size do not match'
		exit
	endif
	;expand frame_mask to 100 x n_frames
	frame_mask_expanded = rebin(reform(frame_mask,1,nframes),100,nframes)

	;start SDS interface
	sd_interface = hdf_sd_start(file_name, /read)

	;Create measurement_mask, hh_mask, and vv_mask from sigma0_mode_flag
	sds_id = hdf_sd_nametoindex(sd_interface, 'sigma0_mode_flag')
	sds_data_id = hdf_sd_select(sd_interface, sds_id)
	hdf_sd_getdata, sds_data_id, sigma0_mode_flag

	process_sigma0_mode_flag, sigma0_mode_flag, measure_mask, hh_mask, vv_mask

	;Create	quality_mask
	sds_id = hdf_sd_nametoindex(sd_interface, 'sigma0_qual_flag')
	sds_data_id = hdf_sd_select(sd_interface, sds_id)
	hdf_sd_getdata, sds_data_id, sigma0_qual_flag

	quality_mask = create_quality_mask(sigma0_qual_flag)


	;Create frequency mask
	sds_id = hdf_sd_nametoindex(sd_interface, 'frequency_shift')
	sds_data_id = hdf_sd_select(sd_interface, sds_id)
	hdf_sd_getdata, sds_data_id, frequency_shift

	frequency_mask = create_frequency_mask(frequency_shift)
	

	;Generate output data
	hh_index = where(measure_mask and quality_mask and frequency_mask and frame_mask_expanded and hh_mask, hh_count)
	vv_index = where(measure_mask and quality_mask and frequency_mask and frame_mask_expanded and vv_mask, vv_count)

	if (hh_count + vv_count gt 0) then begin
		;we have valid data, read data from HDF file
		sds_id = hdf_sd_nametoindex(sd_interface, 'cell_sigma0')
		sds_data_id = hdf_sd_select(sd_interface, sds_id)
		hdf_sd_getdata, sds_data_id, cell_sigma0
		sds_id = hdf_sd_nametoindex(sd_interface, 'cell_lon')
		sds_data_id = hdf_sd_select(sd_interface, sds_id)
		hdf_sd_getdata, sds_data_id, cell_lon
		sds_id = hdf_sd_nametoindex(sd_interface, 'cell_lat')
		sds_data_id = hdf_sd_select(sd_interface, sds_id)
		hdf_sd_getdata, sds_data_id, cell_lat

		;incidence angle correction
		sds_id = hdf_sd_nametoindex(sd_interface, 'cell_incidence')
		sds_data_id = hdf_sd_select(sd_interface, sds_id)
		hdf_sd_getdata, sds_data_id, cell_incidence
		cell_incidence_rad = float(cell_incidence)/18000. * !PI

		;create year and day arrays from frame_time
		frame_year = intarr(nframes)
		frame_day = intarr(nframes)
		for i=0, nframes-1 do begin
			parse_time, frame_time[i], year, day, hour, minute, second, second_dec
			frame_year[i] = year
			frame_day[i] = day
		endfor


		if (hh_count gt 0) then begin
			;We have valid pulses for hh polarization
			sigma0_hh = cell_sigma0[hh_index]
			inc_rad_hh = cell_incidence_rad[hh_index]
			lon_hh = cell_lon[hh_index]
			lat_hh = cell_lat[hh_index]
			day_hh = intarr(hh_count)
			day_hh[*] = frame_day[hh_index/100] ; dividing by 100 casts it to the right dimension within nframes, since 100 is xdim, and hh_index is taken as 1D index
			year_hh = intarr(hh_count)
			year_hh[*] = frame_year[hh_index/100]
		endif

		if (vv_count gt 0) then begin
			;We have valid pulses for vv polarization
			sigma0_vv = cell_sigma0[vv_index]
			inc_rad_vv = cell_incidence_rad[vv_index]
			lon_vv = cell_lon[vv_index]
			lat_vv = cell_lat[vv_index]
			day_vv = intarr(vv_count)
			day_vv[*] = frame_day[vv_index/100] ; dividing by 100 casts it to the right dimension within nframes, since 100 is xdim, and vv_index is taken as 1D index
			year_vv = intarr(vv_count)
			year_vv[*] = frame_year[vv_index/100]
		endif

	endif

	;end SDS interface
	hdf_sd_end, sd_interface
	;close hdf file
	hdf_close, hdf_file_id

End
