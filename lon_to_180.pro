Function lon_to_180, input_lon
	return_val = ((input_lon + 180) mod 360) - 180

	return, return_val
End
