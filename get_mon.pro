Function get_mon, day
	mon = fix(day/30)
	if (mon eq 12) then mon = 11
	return, mon
End
