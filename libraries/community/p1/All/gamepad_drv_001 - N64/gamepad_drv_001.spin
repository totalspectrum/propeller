' NES 64 Controller: gamepad_drv_001
' Using: CJ's N64 Controller Driver version 1.2 
' AUTHOR: Jeff Ledger
'
' Notes: Front Triggers are Start/Select - C buttons double as arrows
'
' This is intended to be drop-in compatible with any game
' which uses the game_drv_001 code.
'
CON  N64Controller = 6  ' Adjust to the location of your N64 Controller


OBJ
  N64    : "N64_v1.2" 
     
PUB start : okay

  N64.start(N64Controller)     

PUB stop

PUB read : joy_bits | a

' NES bit encodings -- Provided as reference
'  NES_RIGHT  = %00000001
'  NES_LEFT   = %00000010
'  NES_DOWN   = %00000100
'  NES_UP     = %00001000
'  NES_START  = %00010000
'  NES_SELECT = %00100000
'  NES_B      = %01000000
'  NES_A      = %10000000
  
  joy_bits := %00000000

  a:=N64.A
  if a==1                'Nintendo64 A = A
      joy_bits := %10000000

  a:=N64.B
  if a==1                'Nintendo64 B = B
      joy_bits := %01000000

  a:=N64.L
  if a==1                'Nintendo64 L = Select
      joy_bits := %00100000

  a:=N64.R
  if a==1                'Nintendo64 R = Start
      joy_bits := %00010000     

  a:=N64.ST
  if a==1            'Nintendo64 Start = Start
      joy_bits := %00010000   

  a:=N64.DR
  if a==1            'Right Arrow
     joy_bits := %00000001

  a:=N64.CR
  if a==1            'Right Arrow
     joy_bits := %00000001

  a:=N64.CL
  if a==1             'Left Arrow
     joy_bits := %00000010

  a:=N64.DL
  if a==1             'Left Arrow
     joy_bits := %00000010

  a:=N64.CD
  if a==1             'Down Arrow
     joy_bits := %00000100

  a:=N64.DD
  if a==1             'Down Arrow
     joy_bits := %00000100

  a:=N64.CU
  if a==1               'Up Arrow
     joy_bits := %00001000
 
  a:=N64.DU
  if a==1               'Up Arrow
     joy_bits := %00001000


PUB button(WhichOne)
{{ Return value:     true or false                                          }}
  if WhichOne == read
    return true
  else
    return false