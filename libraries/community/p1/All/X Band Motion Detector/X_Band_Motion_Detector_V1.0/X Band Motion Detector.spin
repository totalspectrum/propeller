{{
*****************************************
* X Band Motion Detector v1.0           *
* Author: Parallax Staff                *
* Copyright (c) 2009 Parallax           *
* See end of file for terms of use.     *
*****************************************
}}


VAR                                          ' Variables block

  byte enPin, outPin                         ' I/O pins
  long ticks, enPinFlag                      ' 

PUB Enable(pin)

  enPin     := pin
  enPinFlag := true

PUB Disable

  Low(enPin)

PUB Out(pin)

  outPin := pin
  dira[outPin]~

PUB GetCycles(msCount) : cycles | t

  if enPinFlag
    High(EnPin)
    
  ctra[30..26] := %01010                     'ctrb module to POSEDGE detector         
  ctra[5..0] := outPin
  frqa := 1                                  'Add 1 for each cycle
  t := cnt
  phsa~                                      'Start the count at -3000
  waitcnt(t+=(msCount * (clkfreq/1000)))
  cycles := ticks := phsa

  if enPinFlag
    Low(EnPin)
  
PRI High(pin)

  outa[enPin]~~
  dira[enPin]~~

PRI Low(pin)

  outa[enPin]~
  dira[enPin]~~

DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}