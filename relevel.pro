; $Id$
;-----------------------------------------------------------------------
;+
; NAME:
;        RELEVEL
;
; PURPOSE:
;        rebin a partial column vector into new pressure layers
;
; CATEGORY:
;
; CALLING SEQUENCE:
;        RELEVEL, fromedges, toedges, data
;
; INPUTS:
;        fromedges : model pressure level edges from the ground up
;        toedges : instrument pressure level edges from the ground up
;        data : count of molecules in each pressure layer(from the ground up)
;          data may also be molecules/cm2
;
; OUTPUTS:
;        returns the data mapped to 'toedges' pressure levels
;
; NOTES:
;        from and to levels are ascending height pressure levels
;        which means the pressures will be descending
;        HANDLING OF MISMATCHED TOP AND BOTTOM PRESSURE EDGES:
;        1) Bottom model edge(fromlevels) is HIGHER than bottom instrument(tolevels)
;          edge:
;            Extend fromlevel down to match tolevel base and insert molecules
;             to keep the vmr equal within the bottom model slab
;        2) Bottom model edge is LOWER than bottom instrument edge:
;            Remove molecules from first slab to keep the vmr equal
;        3) Top model edge is different to top instrument edge:
;            Molecule's unchanged, top slab vmr will change when it is 
;              'stretched' or 'contracted' to match the instrument top slab
;
; EXAMPLE:
;        relevel, model.pedges, instrument.pedges, model.pcol_co2
;
; MODIFICATION HISTORY:
;        created by jwg366@uowmail.edu.au, 24 Jul 2014: VERSION 1.00
;
;-----------------------------------------------------------------------

FUNCTION relevel, fromlevels1, tolevels1, data1, $
  keepvmr=keepvmr
 
N = n_elements(tolevels1)
M = n_elements(fromlevels1) 
z = dblarr(N-1) & cumsum=dblarr(N)
 
; Rename so as not to alter the input variables
data=data1
tolevels=tolevels1
fromlevels=fromlevels1
 
; HANDLE PROBLEM of model P0 different to instument P0:
;
; extend or retract bottom model slab to match the surface pressure and then
; increase or reduce molecule count so that the bottom slab VMR remains stable
if tolevels[0] ne fromlevels[0] then begin
  
  ; work out how many molecules to add
  molecs_per_hPa = data[0] / (fromlevels[0] - fromlevels[1])
  extra_hPa = tolevels[0] - fromlevels[0]
  extra_molecules = molecs_per_hPa * extra_hPa
  
  ; extend(retract) the first layer and add(subtract) the extra molecules to(from) it
  if keyword_set(keepvmr) then data[0] = data[0] + extra_molecules
  fromlevels[0] = tolevels[0]
endif

; for each edge in the tolevels vector, work out how many molecules below it
; only go up to N-2 and we can handle the final edge(N-1) explicitly
for i=1, N-2 do begin
 
  ; find fraction below current tolevel and above preceding fromlevel
  cur = tolevels[i]
  belowi=(where(fromlevels gt cur))[-1]
  abovei=(where(fromlevels le cur))[0]
  below = fromlevels[belowi]
  above = fromlevels[abovei]
 
  ; if an edge is the same pressure in from and to levels we don't need any fraction
  if above eq cur then begin
    cumsum[i] = total(data[indgen(abovei)])
    z[i-1] = cumsum[i]-cumsum[i-1]
    continue
  endif
  
  ; in case top model layer is lower than top instrument layers
  if abovei eq -1 then above = 0 
  
  ; need to handle when the instrument edges go higher than the model top edge
  ; assume slabs above top edge are empty
  if belowi eq M-1 then begin
    cumsum[i]=total(data)
    z[i-1] = cumsum[i]-cumsum[i-1]
    continue
  endif

  ; fraction of pressure space
  ; multiplied by volume within fromlevel 
  fraction = (below - cur)/(below - above)
  frac = fraction * data[belowi]
 
  ; handle leading edge case
  if belowi eq 0 then cumsum[i] = frac
  
  ; general case
  if belowi gt 0 then cumsum[i] = total(data[indgen(belowi)]) + frac
 
  ; rebin data by subtracting prior cumulative sum from current one
  z[i-1] = cumsum[i]-cumsum[i-1]
endfor

; handle final edge
cumsum[-1] = total(data)
z[-1] = cumsum[-1]-cumsum[-2]

return, z
end
