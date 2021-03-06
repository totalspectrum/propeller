{{File: PropBOE Servos.spin

Controls up to fourteen servos with options for individual and/or
group servo control.  Also capable of adding and removing servos
from the list, and each servo has its own individual ramp setting.
All servos initially default to no ramping.

Methods that set the servo's control signal accept parameters ranging
from -1000 to 1000 which maps to pulse durations from 0.5 ms to 2.5 ms.
In this scheme, the value 0 calls for the center pulse duration of
1.5 ms.  For Parallax Standard servos, you can also think about the
values as tenths of degrees counterclockwise of center (positive values)
or clockwise of center (negative values).

StartSequence method will launch a second cog and use it for the
duration of the sequence.

Uses one additional cog, which is automatically launched with any
call to a method with set in its name.

See end of file for author, version,
copyright and terms of use.
 

TO-DO      Reduce stack sizes to minimum
           required.

BUGS       Please send bug reports,
&          questions, suggestions, 
UPDATES    and improved versions of this
           object to alindsay@parallax.com.
           Check learn.parallax.com
           periodically for updated versions.                    
}}

CON

  CTR = 8                                    ' CTRA spr array index
  FRQ = 10                                   ' FRQA spr array index
  PHS = 12                                   ' PHSA spr array index

DAT

  cog              long     0
  cogB             long     0
  stack            long     0[128]
  stackB           long     0[128]
  lockID           long     0
                                 
  us               long     0
  center           long     0
  frame            long     0
  cycleEnd         long     0
  pulse            long     0[15]
  pinList          long    -1[15]
  pulseList        long     0[15]               
  stepList         long  2000[15]
  enableMask       long     0
  removeMask       long     0
  servoCnt         long    -1
  _pinList         long    -1[15]   
  _pulseList       long     0[15]                               
  _stepList        long  2000[15]                                   
  _enableMask      long    -1
  _removeMask      long     0                     
  _servoCnt        long    -1
  pstCog           long     0
  directions       long     0
  lastPin          long     0
  lastPinList      long     -1[15]               '''changed from 0 to -1 on 2012.03.20

OBJ

  time   :   "Timing"  

PUB Set(pin, usFromCenter) | i
{{Set a standard servo to a certain position or a continuous rotation servo to a certain
speed.

Parameters
  pin          - I/O pin sending the servo control signal
  usFromCenter - Microseconds added to (or subtracted from) the 1.5 ms pulse center signal.
}}

  ifnot cog
    Start
    
  if (i := GetIndex(pin)) > servoCnt
    New(pin, usFromCenter)
  else
    repeat until not lockset(lockID)  
    pulseList[i] := usFromCenter
    enableMask |= |< i
    lockclr(lockID)

  lastPin := pin  

PUB Setup(pin, usFromCenter, usStepPerPulse)
{{Set a standard servo to a certain position or a continuous rotation servo to a certain
speed, and specify a maximum change per control pulse (every 50th of a second).  After a
call to this method, any method that sets a control pulse duration will set a target duration
and the object will step to that target value.

Parameters
  pin            - I/O pin sending the servo control signal
  usFromCenter   - Microseconds added to (or subtracted from) the 1.5 ms pulse center signal.
  usStepPerPulse - Maximum change to control pulse duration with each repetition in microseconds.
}}

  ifnot cog
    Start

  Set(pin, usFromCenter)
  StepSize(pin, usStepPerPulse)

  lastPin := pin

PUB Update(usFromCenter)
{{Update the servo's control signal duration.

Parameters
  usFromCenter   - Microseconds added to (or subtracted from) the 1.5 ms pulse center signal.
}}

  Set(lastPin, usFromCenter)

PUB StepSize(pin, usStepPerPulse) | i
{{Specify a maximum change per control pulse (every 50th of a second).  After a
call to this method, any method that sets the control signal pulse duration will set a target
duration and the object will step to that target value.

Parameters
  pin            - I/O pin sending the servo control signal
  usFromCenter   - Microseconds added to (or subtracted from) the 1.5 ms pulse center signal.
  usStepPerPulse - Maximim change to control pulse duration with each repetition in microseconds.
}}
  ifnot cog
    Start

  if (i := GetIndex(pin)) > servoCnt
    return
  else
    repeat until not lockset(lockID)
    stepList[i] := usStepPerPulse
    enableMask |= |< i
    lockclr(lockID)

  lastPin := pin  

PUB Disable(pin) | i
{{Stop the series of control pulses delivered to a given servo.  A call to a method
that starts with Set will restart the control pulses.

Parameters
  pin          - I/O pin sending the servo control signal
}}

  if (i := GetIndex(pin)) > servoCnt
    return
  else
    repeat until not lockset(lockID)
    enableMask &= (! (|< i))
    lockclr(lockID)

PUB Enable(pin) | i
{{Restart the series of control pulses delivered to a given servo after disable has
been called.

Parameters
  pin - I/O pin sending the servo control signal
}}

  if (i := GetIndex(pin)) > servoCnt
    return
  else
    repeat until not lockset(lockID)
    enableMask |= (|< i)
    lockclr(lockID)

PUB Remove(pin) | i, temp
{{Stop the series of control pulses delivered to a given servo.

Parameters
  pin          - I/O pin sending the servo control signal
}}

  if (i := GetIndex(pin)) > servoCnt
    return
  else
    repeat until not lockset(lockID)
    removeMask |= (|< i)
    lockclr(lockID)
    RemoveBtwn

PUB SetList(pinListAddr, usFromCenterListAddr) | i
{{Set the pulse durations in control signals to a group of servos using
the address of a list of pins and the address of a corresponding list of
pulse durations.

Parameters
  pinListAddr            - The adress of a list of long variables that store
                           pin values (0 to 31).  This list must be terminated 
                           with a negative value.
  usFromCenterListAddr - The address of a list of long variables that store
                         servo control signal pulse duration values.  
}}

  ifnot cog
    Start
    
  i := 0
  repeat while long[pinListAddr][i] > -1
    Set(long[pinListAddr][i], long[usFromCenterListAddr][i])
    i++
  longmove(@lastPinList, pinListAddr, i)   

PUB SetupList(pinListAddr, usFromCenterListAddr, usStepPerPulseListAddr) | i
{{Set up the pulse durations and step limits in control signals to a group
of servos using the address of a list of pins, the address of a corresponding
list of pulse durations, and the address of a list of corresponding maximum
pulse duration change values.

Parameters
  pinListAddr            - The adress of a list of long variables that store
                           pin values (0 to 31).  This list must be terminated 
                           with a negative value.
  usFromCenterListAddr   - The address of a list of long variables that store
                           servo control signal pulse duration values.  
  usStepPerPulseListAddr - The address of a list of values, each storing the
                           maximim change to control pulse duration with each
                           repetition in microseconds.
}}

  ifnot cog
    Start
    
  i := 0
  repeat while long[pinListAddr][i] > -1
    Set(long[pinListAddr][i], long[usFromCenterListAddr][i])
    StepSize(long[pinListAddr][i], long[usStepPerPulseListAddr][i])
    i++

  longmove(@lastPinList, pinListAddr, i)   
  
PUB UpdateList(usFromCenterListAddr)
{{Updates servo control signal pulse durations stored in a list of long variables
at a given address after a call to either SetList or SetupList.  

Parameters
  usFromCenterListAddr   - The address of a list of long variables that store
                           servo control signal pulse duration values.  
}}

  ifnot cog
    Start

  SetList(@lastPinList, usFromCenterListAddr)

PUB UpdateStepSizeList(pinListAddr, usStepPerPulseListAddr) | i
{{Updates the step size list after a call to either SetList or SetupList.

Parameters
  pinListAddr            - The adress of a list of long variables that store
                           pin values (0 to 31).  This list must be terminated 
                           with a negative value.
  usStepPerPulseListAddr - The address of a list of values, each storing the
                           maximim change to control pulse duration with each
                           repetition in microseconds.
}}
  ifnot cog
    Start

  i := 0
  repeat
    StepSize(long[pinListAddr][i], long[usStepPerPulseListAddr][i])
  until long[pinListAddr][i++] < 0

  longmove(@lastPinList, pinListAddr, i)   

PUB DisableList(pinListAddr) | i 
{{Stops the pulses in a control signal to a list of servos.  This is useful
for saving power when the servos do not need to be actively holding a
position or rotating.

Parameters
  pinListAddr - The adress of a list of long variables that store
                pin values (0 to 31).  This list must be terminated with a
                negative value.
}}
  i := 0
  repeat while long[pinListAddr][i] > -1
    Disable(long[pinListAddr][i])
    i++

PUB RemoveList(pinListAddr) | i
{{Removes a list of servos that are receiving control signals and sets
their I/O pins to input.  In contrast to DisableList, this method completely removes
servos from the list and sets the I/O pins that were sending control signals to
input.  After this method is called, the list of servos receiving control signals
will be shorter, and more servos can be added (up to a total of 14 per instance of
this object).

Parameters
  pinListAddr - The adress of a list of long variables that store
                pin values (0 to 31).  This list must be terminated with a
                negative value.
}}
  i := 0
  repeat while long[pinListAddr][i] > -1
    Remove(long[pinListAddr][i])
    i++

  longmove(@lastPinList, @pinList, 15)
  
PUB Sequence(listAddr) | base, i, left, right, ms, temp

{{Execute a sequence of positions separated by delays
with long values stored in either a DAT block or variable
array.   

Parameters
  listAddr  - The list address points to the start of the
              sequence.

''Sequence Example
  OBJ                                                     
    system : "Propeller Board of Education"               
    servo  : "PropBOE Servos.spin"                        
    time   : "Timing"                                     
                                                          
  DAT                                                     
    pins  long   16,     17,     18,   -1                 
    A     long   500,     0,   -500                       
    B     long     0,  -500,    500                       
    C     long  -500,   500,      0

    ' Sequence List                        
    seq   long  @seq, @pins                               
          long  @A, 2000, @B, 2000, @C, 2000, -1          
                                                          
  PUB Go                                                  
    system.Clock(80_000_000)                              
    servo.Sequence(@seq)          ' Execute sequence!                       
    servo.DisableList(@pins)

Sequence Setup Notes
    The sequence must be long variables
    containing these elements in this order:
    1) Address of sequence name
    2) Address of pin list (-1 terminated)
    3) Address of first position list
    4) First ms hold time
    5) Address of second position list
    6) Second ms hold time
       ...
    n)   Address of nth position list
    n+1) nth ms hold time
    n+2) -1 to terminate  
}}
   
  base := listAddr - long[listAddr]                        ' base = object starting address*

  SetList(base+long[listAddr][1], base+long[listAddr][2])  ' Pin list, first position list
  time.Pause(long[listAddr][3])                            ' first pause

  i := 4                                                   ' Initialize local variable
  repeat                                                   ' Loop through rest of positions/pauses
    if (temp := long[listAddr][i]) < 0                     ' If element at listAddr is -1
      quit                                                 ' ..it means no more maneuvers so quit
    UpdateList(base + long[listAddr][i])                   ' Next maneuver in sequence
    time.Pause(long[listAddr][i+1])                        ' Pause till maneuver is done
    i += 2                                                 ' Increment index

'' * Must add base to the address of the maneuver within the object because those addresses are
''   generated at compile time and only indicate their offset from the start of the object.

PUB StartSequence(listAddr) : success

{{Use another cog to execute a sequence of positions
with long values stored in either a DAT block or
variable array.  Frees your program to perform other
tasks while another cog walks through the sequence
of positions.

This method uses another cog for the duration of the
sequence.
   
The sequence can be interrupted (and its cog stopped)
at any time by calling the StopSequence method.


Parameters
  listAddr  - Starting address of longs in either a DAT
              block or variable array that contain a
              list of addresses of maneuvers.  Each
              maneuver is three longs containing left
              and right servo speeds and the number of
              milliseconds to execute the maneuver.
              The list of maneuver addresses must start
              with its own address and end with -1. The
              values in between are addresses to maneuvers.
                  
Returns
  success       - Nonzero if cog was available,
                  zero if no cog available.

NOTE: See sequence method for how to build a sequence
      of servo positions.                                      
                  
''StartSequence Example
  OBJ                                             
    system : "Propeller Board of Education"       
    servo  : "PropBOE Servos.spin"                
    time   : "Timing"                             
    pst    : "Parallax Serial Terminal Plus"      
                                                  
  DAT                                             
    pins  long   16,     17,     18,   -1         
    A     long   500,     0,   -500               
    B     long     0,  -500,    500               
    C     long  -500,   500,      0               
                                                  
    ' Sequence List                        
    seq   long  @seq, @pins                       
          long  @A, 2000, @B, 2000, @C, 2000, -1  
                                                  
  PUB Go | i                                      
    system.Clock(80_000_000)                      
                                                  
    servo.StartSequence(@seq)                     
                                                  
    repeat i from 0 to 60                         
      pst.Dec(i)                                  
      pst.NewLine                                 
      time.Pause(100)                             
                                                  
    pst.Str(String("All done!"))                  
    servo.DisableList(@pins)
}}

  ' Pass SetForget method call to new cog and return nonzero if cog was available
  ' zero if no cog available.
  success := cogB := cognew(SetForget(listAddr), @stackB) + 1
  
PRI SetForget(listAddr)

  Sequence(listAddr)                                       ' Call sequence method
  cogstop(cogB - 1)                                         ' Stop cog when done

  
PUB StopSequence
{{Allows you to stop the maneuver being executed by
the cog that the StartSequence method lunched.
}}

  cogstop(cog - 1)                                         ' Remember to subtract one
                                                           ' since Start added one.

PUB Start : okay
{{
Your code does not need to call this method to Start the servo control
process.  It automatically Starts with the first call to any method,
that Starts with Set. (Set, SetList, etc.)
}}

  us       := clkfreq / 1_000_000            ' 1 microsecond
  center   := 1500 * us                      ' Center pulse = 1.5 ms
  frame    := 2700 * us                      ' Pulse frame to 2.7 ms
  cycleEnd := 1100 * us                      ' (2.7 ms * 7) + 1.1 ms = 20 ms

  lockID := locknew
  okay := cog := cognew(servos, @stack) + 1  ' Launch Servos method into new cog

PUB Stop
''Stop servos object and free the cog
  if cog
    cogstop(cog~ - 1)

PUB Status : success
{{Returns nonzero of servo process has been launched
into a cog.
}}
      

PRI GetIndex(pin) : index

  index := -1
  repeat
    index++
  until pinList[index] == pin or pinList[index] < 0

PRI New(pin, usFromCenter) 

  if servoCnt < 13
    repeat until not lockset(lockID)
    pinList[servoCnt+2] := -1                    ' Must clamp pin index
    pulseList[servoCnt+1] := usfromCenter          ' 
    pinList[servoCnt+1]   := pin
    servoCnt++
    enableMask |= |< servoCnt
    lockclr(lockID)

PRI servos | t, i, ch

  t := cnt
  repeat
    i := -1
    repeat until i == 13
      repeat ch from 0 to 1
        if ++i =< _servoCnt
          outa[_pinList[i]]~
          dira[_pinList[i]]~~
          spr[CTR + ch] := (%000100 << 26) & $FFFFFF00 | _pinList[i]
          spr[FRQ + ch] := spr[PHS + ch] := 1
          pulse[i] += ((_pulseList[i] - pulse[i]) #> -_stepList[i] <# _stepList[i])
          if ((_enableMask >> i) & 1)
            spr[PHS + ch] := -((pulse[i] #> -1000 <# 1000) * us + center)
      waitcnt(t += frame)
    repeat until not lockset(lockID)
    longmove(@_pinlist, @pinList, 48)
    lockclr(lockID)     
    waitcnt(t += cycleEnd)

PRI RemoveBtwn | i, pin

  repeat while removeMask
    i := (>| removeMask) - 1
    longmove(@pinList+(4*i), @pinList+(4*(i+1)), 15-i-1)
    longmove(@pulseList+(4*i), @pulseList+(4*(i+1)), 15-i-1)
    longmove(@stepList+(4*i), @stepList+(4*(i+1)), 15-i-1)
    dira[i]~
    removeMask &= !(|< i)
    servoCnt--

DAT
{{
Author: Andy Lindsay
Version: 0.85
Date:   2012.02.23
Copyright (c) 2012 Parallax Inc.

┌──────────────────────────────────────────────────────────────────────────────────────┐
│TERMS OF USE: MIT License                                                             │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                           
│                                                                                      │                                              
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                               
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}      