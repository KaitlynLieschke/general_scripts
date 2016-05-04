; USING http://www.acd.ucar.edu.au/mopitt/avg_krnls_app.pdf
;
;NOTE: in pdf the midpoints are used rather than the edges
; due to how the AK is defined

FUNCTION ppbv_to_molecs_per_cm2, edges, ppbv
N = n_elements(ppbv)

;P[i] - P[i+1] = pressure differences
inds=indgen(N)

;THERE should be N+1 pressure edges since we have the ppbv for each
;slab
diffs= edges[inds] - edges[inds+1]

t = (2.12e13)*diffs*ppbv

return, t
end
