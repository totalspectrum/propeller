{{ ******************************************************************************
   * SPIN timing test code                                                      *
   * James Burrows Feb 2008                                                     *
   * Version 1.0                                                                *
   ******************************************************************************
   ┌──────────────────────────────────────────┐
   │ Copyright (c) <2008> <James Burrows>     │               
   │   See end of file for terms of use.      │               
   └──────────────────────────────────────────┘

   this object provides the PUBLIC functions:
    -> N/A
  
   this object provides the PRIVATE functions:
    -> N/A
  
   this object uses the following sub OBJECTS:
    -> N/A   

   Blinks an LED every time the CNT exceed's its target.  Copes with CNT roleover.

   Assumes a LED on PIN 16.
    
}}

CON
    _clkmode        = xtal1 + pll16x
    _xinfreq        = 5_000_000


VAR
    long  blinkLastDeadline
    long  blinkDelay    


PUB start
    ' make the PIN an output
    dira[16]~~

    ' Turn it on for 1 second as a test....
    outa[16]~~
    waitcnt(clkfreq+cnt)
    outa[16]~
    
    ' setup a 1/4 second delay...
    blinkDelay := clkfreq / 4
    blinkLastDeadline := cnt + blinkDelay

    ' repeat it
    repeat
        ' wait for target time to be exceeded
        if cnt-blinkLastDeadline > blinkDelay
            ' toggle the pin state...
            !outa[16]     

        ' increment the blinker deadline  
        if cnt-blinkLastDeadline > blinkDelay
            ' setup next 1/4 second delay
            blinkLastDeadline := cnt + blinkDelay


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