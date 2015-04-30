Function create_frequency_mask, frequency_shift

	array_size = size(frequency_shift)
	xdim = array_size[1]
	ydim = array_size[2]

	frequency_mask = bytarr(xdim,ydim)

	index = where(frequency_shift lt 5000, count)
	if (count gt 0) then frequency_mask[index] = 1

	return, frequency_mask


End
