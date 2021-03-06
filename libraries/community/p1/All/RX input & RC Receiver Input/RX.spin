{{
*****************************************
* RX version 1.3                        *
* Author: Rich Harman                   *
* Copyright (c) 2009 Rich Harman        *
* See end of file for terms of use.     *
*****************************************


*****************************************************************
 Read RC inputs on 6 pins, output same values on 6 more pins
*****************************************************************
 Coded by Rich Harman  15 Jul 2009
*****************************************************************
 Thanks go to SamMishal for his help getting the counters to work
*****************************************************************

Theory of Operation:

Launch three cogs using the object RX.spin which in turn each start
two counters.

This approach does NOT need the pulses to arrive on the pins in any
certain order, nor does it require the pins to be all connected.

Whatever pulse is received on pin 1 is then sent out to pin 7 and
so on.

}}

VAR

  byte cog[3]
  long stack[60]
  long uS

PUB Start (pins_array_address, pulsewidth_array_address)|i

  uS := clkfreq/1_000_000

  Stop   'call the stop method to stop cogs tha may be already started
  repeat i from 0 to 2
     cog[i] := cognew(readPins(@long[pins_array_address][i*2], @long[pulsewidth_array_address][i*2]), @ stack[i*20]) + 1

PUB Stop | i
    repeat i from 0 to 2
      if cog[i]
        cogstop(cog[i]~ -1)

PUB readPins (pins_address, pulsewidth_address)| i,p1,p2, synCnt, active1, active2

  repeat i from 0 to 1
     spr[8+i]  := %01000 << 26 + long[pins_address][i]   'set the mode and pin for ctra/b
     spr[10+i] := 1                                      ' set frqa/b

  p1 := long[pins_address][0]
  p2 := long[pins_address][1]
  dira[p1]~
  dira[p2]~
  long[pulsewidth_address][0]~                          'add these lines to the code to make sure the count is zeroed
  long[pulsewidth_address][1]~

  active1 := false
  active2 := false

  synCnt := clkfreq/4 + cnt
  repeat until synCnt =< cnt                            ' wait 1/4 second to check if pins are hooked up to a signal
    if ina[p1] == 1
      active1 := true
    if ina[p2] == 1
      active2 := true

  repeat

      if active1 == true
        waitPEQ(0 , |< p1,0)                               'wait for low state - don't want to start counting when high
        phsa~                                              'counter set to zero
        waitPEQ(|< p1 , |< p1,0)                           'wait for high
        waitPEQ(0 , |< p1,0)                               'wait for low state i.e. pulse ended
          long[pulsewidth_address][0] := phsa/uS


      if active2 == true
        waitPEQ(0   , |< p2,0)
        phsb~
        waitPEQ(|< p2, |< p2, 0)
        waitPEQ(0   , |< p2,0)
          long[pulsewidth_address][1] := phsb/uS



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
│ARISING FROM,     OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
