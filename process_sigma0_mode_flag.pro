PRO process_sigma0_mode_flag, mode_flag, measure_mask, hh_mask, vv_mask

	array_size = size(mode_flag)
	xdim = array_size[1]
	ydim = array_size[2]

	measure_mask = bytarr(xdim,ydim)
	hh_mask = bytarr(xdim,ydim)
	vv_mask = bytarr(xdim,ydim)

	index = where(not(mode_flag) and 1, count)
	if (count gt 0) then measure_mask[index] = 1

	index = where(mode_flag and 2^2, count, complement=comp_index, ncomplement=ncomp)
	if (count gt 0) then vv_mask[index] = 1
	if (ncomp gt 0) then hh_mask[comp_index] = 1

End
