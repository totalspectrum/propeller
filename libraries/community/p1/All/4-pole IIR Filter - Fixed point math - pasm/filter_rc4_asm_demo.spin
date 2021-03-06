{{ filter_rc4_asm_demo.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ IIR Integer Filter Demo (asm) v0.1  │ BR             │ (C)2009             │  5Dec2009     │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│                                                                                            │
│ Demo of a 4-element recursive Infinite Impulse Response (IIR) filter, implemented in PASM  │
│ using integer math.                                                                        │
│                                                                                            │
│ Demo calculates filter frequency response via direct simulation with the help of the       │
│ prop's built-in math tables and a handy sin function courtesy of Ariba.  It also simulates │
│ filter impulse response and step response.                                                 │
│                                                                                            │
│ pst setup to use PLX-DAQ (enables easy plot of raw data vs filtered output).    Works      │
│ fine with pst, also...just not as easy to plot the data.                                   │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}


CON
  _clkmode        = xtal1 + pll16x    ' System clock → 80 MHz
  _xinfreq        = 5_000_000

  
var
   long in,out                   'filter output must be located adjacent to input
   long ticks
   

OBJ   
  pst   : "Parallax Serial Terminal"
  filter: "filter_rc4_asm"     

  
PUB Init|coeffPtr

  'fire up serial terminal
  waitcnt(clkfreq * 5 + cnt)
  pst.start(57600)
  pst.Str(String("MSG,Initializing...",13))
  pst.Str(String("LABEL,x_meas,x_filt,ticks",13))
  pst.Str(String("CLEARDATA",13))

  'start timer cog to measure how long filter takes to process data
  cognew( @entry, @in )                              

    coeffPtr:=filter.synth_low_pass(200,8)           '2^4 = 16, 2^6=64, 2^8=256
'   coeffPtr:=filter.synth_high_pass(15,8)
'   coeffPtr:=filter.synth_band_stop(63,8,63,25)     'synthesize band stop filter      'FIXME: unstable!?
'   coeffPtr:=filter.synth_band_pass(63,8,63,25)     'synthesize band pass filter 
'   coeffPtr:=filter.synth_fslp(31,6)                'synthesize four stage low pass filter 
  
{   pst.Str(String("a0="))
    pst.Dec(long[coeffPtr][0])
    pst.Str(String(13))
    pst.Str(String("a1="))
    pst.Dec(long[coeffPtr][1])
    pst.Str(String(13))
    pst.Str(String("a2="))
    pst.Dec(long[coeffPtr][2])
    pst.Str(String(13))
    pst.Str(String("a3="))
    pst.Dec(long[coeffPtr][3])
    pst.Str(String(13))
    pst.Str(String("b1="))
    pst.Dec(long[coeffPtr][4])
    pst.Str(String(13))
    pst.Str(String("b2="))
    pst.Dec(long[coeffPtr][5])
    pst.Str(String(13))
    pst.Str(String("b3="))
    pst.Dec(long[coeffPtr][6])
    pst.Str(String(13))
    pst.Str(String("b4="))
    pst.Dec(long[coeffPtr][7])
    pst.Str(String(13))        
    pst.Str(String("normExp="))
    pst.Dec(long[coeffPtr][16])
    pst.Str(String(13))              }
  
  filter.start(@in)     
  main

Pub Main| iter, mark, xmeas, xfilt, value, random

'======================================================
'Filter response to sinusoidal inputs (poor man's Bode)
'======================================================
mark := random := cnt
repeat  iter from 1 to 40 step 2                 'simulate 20 frequencies, highest frequency is nearly Nyquist freq
  repeat value from 0 to 359 step 4              'take 90 samples per frequency
    mark += clkfreq/50                           'output data at 50 samples/sec
    pst.Str(String("DATA, "))                    'data header for PLX-DAQ
    xmeas := sin(value*iter,200)                 'thanks Ariba
'   xmeas += iter * random? >> 28                'add some noise to the measurements
    in := xmeas
    xfilt := out

    pst.Dec(xmeas)
    pst.Str(String(", "))
    pst.Dec(xfilt)
    pst.Str(String(", "))
    pst.Dec(ticks)
    pst.Str(String(13))
    waitcnt(mark)                                'wait for it...

'=================================
'Filter impulse and step responses
'=================================
mark := random := cnt
repeat  iter from 1 to 150                      
    mark += clkfreq/50                           
    pst.Str(String("DATA, "))                    
    if iter < 50
      xmeas := 1                                      'let the filter chill for a moment....
    elseif iter < 100
      xmeas := 1+ impulse_fun(iter, 51, 200)          'input impulse function
    else
      xmeas := step_fun(iter,101,200)                 'input step function

    in := xmeas
    xfilt := out
'
    pst.Dec(xmeas)
    pst.Str(String(", "))
    pst.Dec(xfilt)
    pst.Str(String(", "))
    pst.Dec(ticks)
    pst.Str(String(13))
    waitcnt(mark)                                


PUB sin(degree, mag) : s | c,z,angle
''Returns scaled sine of an angle: rtn = mag * sin(degree)
'Function courtesy of forum member Ariba
'http://forums.parallax.com/forums/default.aspx?f=25&m=268690

  angle //= 360
  angle := (degree*91)~>2 ' *22.75
  c := angle & $800
  z := angle & $1000
  if c
    angle := -angle
  angle |= $E000>>1
  angle <<= 1
  s := word[angle]
  if z
    s := -s
  return (s*mag)~>16       ' return sin = -range..+range


pub cos(degree, mag) : s
''Returns scaled cosine of an angle: rtn = mag * cos(degree)

  return sin(degree+90,mag)

  
pub impulse_fun(i,trigger,mag):x_rtn
''Returns impulse function. i = current sample index
''                          trigger = sample index on which impulse is triggered
''                          mag = magnitude of impulse
    if i==trigger
      return mag
    else
      return 0


pub step_fun(i,trigger,mag):x_rtn
''Returns step function. i = current sample index
''                       trigger = sample index on which step is triggered
''                       mag = magnitude of impulse
    if i < trigger
      return 0
    else
      return mag


DAT
'--------------------------
'timer to estimate how long filter takes to process data
'--------------------------
           org        
entry      mov     inPtr,par               'get pointer for filter data input location
           mov     outPtr,par
           add     outPtr,#8               'set pointer for timer output location

loop1      rdlong  t1,inPtr                'get new filter data input                               
           cmps    t1,nul       wz         'check for nul input
      if_z jmp     #loop1                  'if nul, disregard...loop back
           mov     t2,cnt
loop2      rdlong  t1,inPtr                'get new filter data input                               
           cmps    t1,nul       wz         'check for nul input
     if_nz jmp     #loop2                  'if NOT nul, disregard...loop back
           mov     t3,cnt
           sub     t2,t3
           wrlong  t2,outPtr
           jmp     #loop1
'--------------------------                                                                            
'initialized data
'--------------------------                                                                           
nul        long    negx
'uninitialized data
inPtr      res     1                      
outPtr     res     1                      
t1         res     1                      
t2         res     1                      
t3         res     1


DAT

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}    