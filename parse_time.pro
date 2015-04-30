;Parses the 21-char time string used in RapidSCAT
PRO parse_time, time_string, year, day, hour, minute, second, second_decimal

	if (strlen(time_string) ne 21) then begin
		print, 'ERROR!  parse_time input time string is not correct length:"', time_string,'"'
		return
	endif

	year = fix(strmid(time_string,0,4))
	day = fix(strmid(time_string,5,3))
	hour = fix(strmid(time_string,9,2))
	minute = fix(strmid(time_string,12,2))
	second = fix(strmid(time_string,15,2))
	second_decimal = fix(strmid(time_string,18,3))

End
