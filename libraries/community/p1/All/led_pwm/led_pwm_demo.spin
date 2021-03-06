{{
┌──────────────────────────────────────────┐
│ led_pwm_demo v1.0                        │
│ Author: Colin Fox <greenenergy@gmail.com>│
│ Copyright (c) 2011 Colin Fox             │
│ See end of file for terms of use.        │
└──────────────────────────────────────────┘
}}

_xinfreq = 5_000_000
_clkmode = xtal1 + pll16x

CON
_numleds = 8
_firstled = 16
_maxbright = 64
_delay = 16

VAR
  long numleds_, firstled_, persistence_, leds[_numleds]    'these must appear in this order

OBJ

  led          : "led_pwm"

PUB Main
  repeat
    Steady(1, 5)
    Pingpong(10)
    Pulse(3)

PUB Steady(bright, numsecs) | x
  {{
  This function sets all the LEDs to bright brightness for numsecs seconds.
  }}

  numleds_ := _numleds
  firstled_ := _firstled
  persistence_ := 0

  led.start(@numleds_)

  repeat x from 0 to _numleds-1
    leds[x] := bright

  waitcnt((clkfreq * numsecs) + cnt)

  led.stop


PUB Pingpong(numpings) | x, maxbright
  {{
   This function uses the decay feature of the led_pwm driver. Step through each LED and
   set the brightness to maximum, wait a small amount, then set the next. Changing the persistence
   value will alter how long it takes for the LED to turn off.
   The persistence value is only read when the function starts, so changing persistence on the fly has
   no effect.
  }}

  numleds_ := _numleds
  firstled_ := _firstled
  persistence_ := 8

  maxbright := 64

  led.start(@numleds_)

  repeat numpings

    repeat x from 0 to _numleds-1
      leds[x] := maxbright
      waitcnt(clkfreq/_delay + cnt)                     ' The delay is after each are set, so they are individual

    repeat x from _numleds-1 to 0
      leds[x] := maxbright
      waitcnt(clkfreq/_delay + cnt)

  led.stop

PUB Pulse(numpulses) | x, bright, maxbright
  {{
  This function disables the automatic decay of the led_pwm driver and instead controls
  the brightness manually, setting all LEDs to the same brightness value, then waiting a
  small delay. Changing the step value will alter how fast the pulsing happens.
  }}

  numleds_ := _numleds
  firstled_ := _firstled
  persistence_ := 0

  maxbright := 64

  led.start(@numleds_)

  repeat numpulses

    repeat bright from 0 to maxbright step 2
      repeat x from 0 to _numleds-1
        leds[x] := bright
      waitcnt(clkfreq/_delay + cnt)                     ' The delay is after all are set, so they are uniform

    repeat bright from maxbright to 0 step 2
      repeat x from 0 to _numleds-1
        leds[x] := bright
      waitcnt(clkfreq/_delay + cnt)

  led.stop

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
