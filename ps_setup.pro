; $Id$
;-----------------------------------------------------------------------
;+
; NAME:
;        PS_SETUP
;
; PURPOSE:
;        This program should simplify opening, using, and closing
;        PostScript files. The program is designed to provide fast and 
;        basic PostScript support rather than fully customized
;        configurations of PostScript files. PS_SETUP can
;        open, close and preview files. It asks for user confirmation
;        before overwriting a file. By default it loads Helvetica fonts in
;        a size that works for most applications. It also sets page margins 
;        which word well for tall and narrow plot areas. PS_SETUP previews the
;        PostScript file after closing it. PS_SETUP saves the prior
;        plotting state before opening a file, and restores it after
;        closing the file. e.g. If the system was plotting to an
;        X-window before opening a file, the system will plot to
;        X-windows after PS_SETUP has closed the file. Prior font
;        setting are restored as well.
;
; CATEGORY:
;
; CALLING SEQUENCE:
;        PS_SETUP[, Keywords]
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;        FILENAME - (string) specify the PostScript filename when
;                   opening a file. Must be used with /OPEN
;        OPEN     - (boolean) Set this keyword to open the file. Must
;                   be used with FILENAME
;        CLOSE    - (boolean) Set this keyword to close the file and
;                   preview it
;        NOVIEW   - (boolean) Set this keyword to prevent viewing the
;                   file after it is closed. Can only be used with
;                   /CLOSE
;        OVERWRITE - (boolean) Set to overwrite a preexisting file
;                    named FILENAME without runtime user input. Use
;                    with /OPEN.
;        XSIZE    - (float) Horizontal size of the plot area in
;                   inches. Use with /OPEN. Default = 6.5
;        YSIZE    - (float) Vertical size of the plot area in
;                   inches. Use with /OPEN. Default = 9
;        XOFFSET  - (float) Horizontal offset of the plot area from
;                   the edge of the page in inches. Use with /OPEN. Default = 1
;        YOFFSET  - (float) Vertical offset of the plot area from
;                   the edge of the page in inches. Use with /OPEN. Default = 1
;        LANDSCAPE - (boolean) Set this keyword to use landscape page
;                    orientation. Use with /OPEN. Default = PORTRAIT
;        PORTRAIT  - (boolean) Set this keyword to use portrait page
;                    orientation. Use with /OPEN. Default = PORTRAIT
;        CHARSIZE - (float) Size of characters. Use with
;                   /OPEN. Default = 1.2
;        PSOPEN   - (boolean) Returns 1 if PostScript file
;                   successfully opened, 0 otherwise.
;        _EXTRA   - Other Keywords are passed to DEVICE
;
; OUTPUTS:
;
; SUBROUTINES:
;
; REQUIREMENTS:
;
; NOTES:
;
; EXAMPLE:
;        PS_SETUP, filename='file.ps', /open, /landscape
;        PLOT, findgen(10), /color
;        PS_SETUP, /close
;
; MODIFICATION HISTORY:
;        cdh, 07 Aug 2007: VERSION 1.00
;
;-
; Copyright (C) 2007, Christopher Holmes, Harvard University
; This software is provided as is without any warranty
; whatsoever. It may be freely used, copied or distributed
; for non-commercial purposes. This copyright notice must be
; kept with any copy of this software. If this software shall
; be used commercially or sold as part of a larger package,
; please contact the author.
; Bugs and comments should be directed to cdh@io.as.harvard.edu
; with subject "IDL routine ps_setup"
;-----------------------------------------------------------------------


pro ps_setup, Filename=Filename, Open=Open, Close=Close, noView=noView, $
      xsize=xsize, ysize=ysize, yoffset=yoffset, xoffset=xoffset, $
      landscape=landscape, portrait=portrait, PSOpen=PSOpen, $
      charsize=charsize, Overwrite=Overwrite, _Extra=_Extra
 
   ;====================================================================  
   ; Set up a system variable with status of Postscript file
   ;====================================================================  
 
   ; Save current plot settings in a system variable to restore later
   ; Test to see whether MY_P already exists
   DefSysV, '!MY_PSInfo', Exists=Exists
      
   ; Make Structure with necessary information
   PSInfo = CREATE_STRUCT( 'PSOpen', 0, 'PSFile', '', 'PSave', !P ) 
 
   ; If !MY_P doesn't exist, then define it
   if ( not Exists ) then DefSysV, '!MY_PSInfo', PSInfo
      
   ;====================================================================  
   ; Set up PostScript, if OPEN Keyword is set and Filename given
   ;====================================================================  
 
   ; Check whether a postscript filename is given
   if Keyword_Set( Open ) and Keyword_Set( Filename ) then  begin
 
      ; Check whether file exists
      FileExists = File_Test( Filename )
      
      ; Default is to ask user to overwrite a file
      if not Keyword_Set( Overwrite ) then Overwrite = 0

      if ( FileExists and not Overwrite ) then begin
         
         ; Print a warning
         print, ''
         print, 'WARNING! Output file already exists: ', Filename
         
         ; Initialize variable as string
         overwrite = ''
         
         ; Prompt user whether to continue
         read, overwrite, prompt='Overwrite existing file? (default: no) '
 
         ; Check if user said yes, exit otherwise
         if ( (overwrite ne 'y'  ) and $ 
              (overwrite ne 'Y'  ) and $
              (overwrite ne 'yes') ) then return
         
      endif
 
      ; Plot dimensions
      if not Keyword_Set( xsize   ) then xsize = 6.5
      if not Keyword_Set( ysize   ) then ysize = 9
      if not Keyword_Set( yoffset ) then yoffset = 1
      if not Keyword_Set( xoffset ) then xoffset = 1
      if not Keyword_Set( landscape ) then portrait = 1
 
      ; Set output plot and device settings
      set_plot, 'ps' 
      device, /color, bits=8, filename=Filename, $
         xsize=xsize, ysize=ysize, /inches, yoffset=yoffset, $
         xoffset=xoffset, landscape=landscape, portrait=portrait, $
         _Extra=_Extra
 
      ; Use PS Fonts
      !P.font = 0
 
      ; Default font size
      if not Keyword_Set( charsize ) then charsize = 1.2
      !P.charsize = charsize
 
      ; Use Helvetica Font
      device, /helvetica, /isolatin1
 
      ; Set page margins
      multipanel, /off, /reset
      multipanel, omargin=[0.0, 0.11, 0.1, 0.0]
 
      ; Set flags for open psfile
      !MY_PSInfo.PSOpen = 1
      PSOpen = 1
 
      ; Store open filename
      !MY_PSInfo.PSFile = Filename
 
   endif
 
   ; Display a non-fatal error if OPEN is set, but no filename is given 
   if Keyword_Set( OPEN ) and not Keyword_Set( Filename ) then begin
 
      print, ''
      print, 'No Filename! Cannot Open Postscript!! '
      print, ''
 
      !MY_PSInfo.PSOpen = 0
 
   endif
 
 
   ;====================================================================  
   ; Close PostScript if CLOSE keyword is set
   ;====================================================================  
 
   if Keyword_Set( CLOSE ) and ( !MY_PSInfo.PSOpen ) then begin
 
      ; Restore System Plot State
      !P = !MY_PSInfo.PSave
      
      ; Close PS file
      device, /close
      set_plot, 'x'
         
      ; View the PS file, unless NOVIEW is set
      if not Keyword_set( noView ) then $
         spawn, 'ghostview '+!MY_PSInfo.psFile
 
      ; Set Flags for closed PS file
      !MY_PSInfo.PSOpen = 0
      PSOpen = 0
 
   endif
 
end
