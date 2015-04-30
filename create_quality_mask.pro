Function create_quality_mask, sigma0_qual_flag

	array_size = size(sigma0_qual_flag)
	xdim = array_size[1]
	ydim = array_size[2]

	quality_mask = bytarr(xdim,ydim)

	index = where(not(sigma0_qual_flag) and 1, count)

	if (count gt 0) then quality_mask[index] = 1

	return, quality_mask

End
