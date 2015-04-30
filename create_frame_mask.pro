;This function creates a 1D array of frame mask to mask out repeated frames using time strings
FUNCTION create_frame_mask, start_time, end_time, frame_time

	n_frames = n_elements(frame_time)

	if (n_frames lt 1000) then begin
		print, 'WARNING: number of frames seem very small', n_frames
	endif

	frame_mask = bytarr(n_frames)
	frame_mask[*] = 1B

	;move from beginning and set duplicates to 0 until we find non-duplicate
	parse_time, start_time, start_year, start_day, start_hour, start_minute, start_second, start_second_dec
	parse_time, end_time, end_year, end_day, end_hour, end_minute, end_second, end_second_dec

	for i=0, n_frames-1 do begin
		parse_time, frame_time[i], year, day, hour, minute, second, second_dec
		if (year lt start_year) then begin
			frame_mask[i] = 0
			continue
		endif
		if (day lt start_day) then begin
			frame_mask[i] = 0
			continue
		endif
		if (hour lt start_hour) then begin
			frame_mask[i] = 0
			continue
		endif
		if (minute lt start_minute) then begin
			frame_mask[i] = 0
			continue
		endif
		if (second lt start_second) then begin
			frame_mask[i] = 0
			continue
		endif
		if (second_dec lt start_second_dec) then begin
			frame_mask[i] = 0
			continue
		endif

		;If we reach this point, that means current frame is later than start time, so we don't set mask to 0 and break out of loop
		break
	endfor

	;move from end and set duplicates to 0 until we find non-duplicates
	for i=n_frames-1, 0, -1 do begin
		parse_time, frame_time[i], year, day, hour, minute, second, second_dec
		if (year gt end_year) then begin
			frame_mask[i] = 0
			continue
		endif
		if (day gt end_day) then begin
			frame_mask[i] = 0
			continue
		endif
		if (hour gt end_hour) then begin
			frame_mask[i] = 0
			continue
		endif
		if (minute gt end_minute) then begin
			frame_mask[i] = 0
			continue
		endif
		if (second gt end_second) then begin
			frame_mask[i] = 0
			continue
		endif
		if (second_dec gt end_second_dec) then begin
			frame_mask[i] = 0
			continue
		endif

		;If we reach this point, that means current frame is earlier than end time, so we don't set mask to 0 and break out of loop
		break
	endfor

	return, frame_mask

End
