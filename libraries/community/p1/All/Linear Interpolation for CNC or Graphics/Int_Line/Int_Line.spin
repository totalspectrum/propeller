{{

By Don Starkey
Email: Don@StarkeyMail.com
Ver. 1.0,  11/26/2011

    My 3D implementation of Bresenham's line algorithm
    Ref. http://free.pages.at/easyfilter/bresenham.html

This code is the starting point for a 3D linear interpolation motion profile for a home-brew CNC machine. (CNC Codes G00 & G01)

The Bresenham algorithm calculates X,Y & Z steps of an straight line between two endpoints in 3-dimensional space.

There is no code for controlling the step rate along the path. (Currently working on this) so it is not yet ready for prime-time.
 
I also have written a 2D Circular Interpolation again using the Bresenham algorithm that calculates X & Y steps of an approximate circle or arc.
 


   I/O P16 - X-Axis Step Pin    ' Should be a contiguous block of pins
   I/O P17 - X-Axis Directin Pin
   I/O P18 - Y-Axis Step Pin
   I/O P19 - Y-Axis Directin Pin
   I/O P20 - Z-Axis Directin Pin  
   I/O P21 - Z-Axis Directin Pin 

   I/O P28 - SCL I2C
   I/O P39 - SDA I2C
   I/O P30 - Serial Communications
   I/O P31 - Serial Communications Also Bridge pin for timer operations.

}}
CON                  
    _CLKMODE    = XTAL1 + PLL16X                         
    _XINFREQ    = 5_000_000

    StepXPin    = 16+0 ' Must be a contiguous block of 6 pins
'   DirXPin     = 16+1
'   StepYPin    = 16+2
'   DirYPin     = 16+3
'   StepZPin    = 16+4
'   DirZPin     = 16+5


VAR

' Dont rearrange the order of these variables as the PASM code need to know them in order
    long    s_Status    ' +0 Linear Interpolation Status
                        ' Status of 0 = idle, awaiting a value from Spin program
                        ' Status of 1 = in PASM code, moving in interpolation mode
    long    s_FromX     ' +4  From X Coordinate
    long    s_FromY     ' +8  From Y Coordinate
    long    s_FromZ     ' +12 From Z Coordinate 
    long    s_ToX       ' +16 To X Coordinate
    long    s_ToY       ' +20 To Y Coordinate
    long    s_ToZ       ' +24 To Z Coordinate  
    long    s_Spare1    ' +28 
    long    s_Spare2    ' +32 
    long    s_Speed     ' +36 Speed of movement (Not implemented)
    long    s_XAt       ' +40 Current location of X Axis
    long    s_YAt       ' +44 Current location of Y Axis
    long    s_ZAt       ' +48 Current location of Z Axis
    
long latch' +52 ' Debugging variables, can be deleted
OBJ

     ser: "Parallax Serial Terminal"
     
PUB CircularInterpolation
     ser.start(115200) 

    StepPinX := StepXPin            ' Define the base pin for Step & Direction outputs

    cognew(@LinearInt,@s_Status)
    waitcnt(clkfreq+cnt)

'waitcnt(clkfreq+cnt)
   Linear(-1000,-200,-30,1000,200,30)


PUB Linear (From_X,From_Y, From_Z,To_X,To_Y,To_Z)

' Enter with From_X, From_Y & From_Z = starting point (integers)
' Enter with To_X, To_Y & To_Z ending point (integers)
                                        
    s_FromX := From_X
    s_FromY := From_Y                                  
    s_FromZ := From_Z                                  
    s_ToX := To_X
    s_ToY := To_Y
    s_ToZ := To_Z


    waitcnt(clkfreq+cnt)


    ser.str(string("line "))
    ser.dec(from_x)
    ser.str(string(","))
    ser.dec(from_y)
    ser.str(string(","))
    ser.dec(from_z)

    ser.str(string(" to "))
    ser.dec(to_x)
    ser.str(string(","))
    ser.dec(to_y)
    ser.str(string(","))
    ser.dec(to_z)
    ser.char(13)
    ser.char(13)
         
             
    s_Status := 1
    repeat while s_Status

         if latch

           ser.dec(s_XAt)
           ser.str(string(","))
           ser.dec(s_YAt)
           ser.str(string(","))
           ser.dec(s_ZAt)
           ser.char(13)

            latch:=0
     
    
dat

' My 3D implementation of Bresenham's line algorithm
' Ref. http://free.pages.at/easyfilter/bresenham.html

                        org     0
LinearInt

                        sub     StepPinX,#1
                        mov     tmp1,StepPinX
                        mov     StepPinX,#1                 ' Make bitmask for Output Pins
                        shl     StepPinX,tmp1
                        
                        mov     DirPinX,StepPinX
                        shl     DirPinX,#1
                        
                        mov     StepPinY,StepPinX
                        shl     StepPinY,#2
                        
                        mov     DirPinY,StepPinX
                        shl     DirPinY,#3

                        mov     StepPinZ,StepPinX
                        shl     StepPinZ,#4
                        
                        mov     DirPinZ,StepPinX
                        shl     DirPinZ,#5
                        
                        ' Set bitmask for X-Axis Step & Direction Pins
                        mov     tmp2,StepPinX                        
                        or      tmp2,DirPinX
                        or      tmp2,StepPinY
                        or      tmp2,DirPinY  
                        or      tmp2,StepPinZ
                        or      tmp2,DirPinZ  

                        mov     outa,#0
                        mov     tmp2,#$3f
                        shl     tmp2,tmp1
                        mov     dira,tmp2                   ' Set output pins for OUTPUT
                        mov     Sign,#0

                        ' Save addresses of pass-through variables
                        mov     tmp1,par
                        mov     StatusAt,tmp1                 ' +0      Linear Interpolation Status (0=stopped, 1=moving)
                        add     tmp1,#4                                                  
                        mov     FromXAt,tmp1                  ' +4      From X Coordinate
                        add     tmp1,#4
                        mov     FromYAt,tmp1                  ' +8      From Y Coordinate
                        add     tmp1,#4
                        mov     FromZAt,tmp1                  ' +12     From Z Coordinate
                        add     tmp1,#4
                        mov     ToXAt,tmp1                    ' +16     To X Coordinate
                        add     tmp1,#4
                        mov     ToYAt,tmp1                    ' +20     To Y Coordinate
                        add     tmp1,#4
                        mov     ToZAt,tmp1                    ' +24     To Z Coordinate
                        add     tmp1,#16
                        mov     XCurAt,tmp1                   ' +40     X Current Location in counts     
                        add     tmp1,#4                         
                        mov     YCurAt,tmp1                   ' +44     Y Current Location in counts
                        add     tmp1,#4                         
                        mov     ZCurAt,tmp1                   ' +48     Z Current Location in counts
                        

add tmp1,#4            ' debugging statement, can be removed
mov latchat,tmp1  '+52 ' debugging statement, can be removed



Disable
                        rdlong  tmp1, StatusAt wz             ' Status of 0 = idle, awaiting SPIN
            if_z        jmp     #Disable                    ' SPIN sets to a Status of 1 to command moving in Circ. Int. Mode

                                                            
                        ' Read Pass-Through Variables
                        rdlong  PStatus,StatusAt            ' Load the values from shared memory
                        rdlong  FromX, FromXAt
                        rdlong  FromY, FromYAt
                        rdlong  FromZ, FromZAt
                        rdlong  ToX, ToXAt    
                        rdlong  ToY, ToYAt    
                        rdlong  ToZ, ToZAt    

                        mov     tmp2,ToX
                        subs    tmp2,FromX
                        abs     tmp2,tmp2
                        add     tmp2,tmp2
                        mov     A0,tmp2

                        mov     tmp2,ToY
                        subs    tmp2,FromY
                        abs     tmp2,tmp2
                        add     tmp2,tmp2
                        mov     A1,tmp2

                        mov     tmp2,ToZ
                        subs    tmp2,FromZ
                        abs     tmp2,tmp2
                        add     tmp2,tmp2
                        mov     A2,tmp2

                        mov     C0,ToX
                        mov     C1,ToY
                        mov     C2,ToZ

                        mov     XCur,FromX
                        mov     YCur,FromY
                        mov     ZCur,FromZ

                        mov     Sign,#0                     ' Direction bit for Step & Direction output
                        cmps    FromX,ToX wc                ' Set Sign of slope
                        mov     S0,NegOne
            if_c        mov     S0,#1
            if_c        or      Sign,DirPinX
                        cmps    FromY,ToY wc
                        mov     S1,NegOne
            if_c        mov     S1,#1
            if_c        or      Sign,DirPinY
                        cmps    FromZ,ToZ wc
                        mov     S2,NegOne
            if_c        mov     S2,#1
            if_c        or      Sign,DirPinZ
                        mov     outa,Sign                   ' set direction bits, these don't change for this move

                        ' Find dominant axis
                        cmp     A1,A0 wc                    ' C Set if SValue1 < SValue2 (Y<X)
            if_c        jmp     #XY
                        cmp     A2,A1 wc
            if_c        mov     index0,#1                   ' Y>X & Y>Z so Y = Dominant
            if_c        mov     index1,#0
            if_c        mov     index2,#2
            if_c        jmp     #DomFound
            
                        mov     index0,#2                   ' Y>X & Z>Y so Z = Dominant
                        mov     index1,#0
                        mov     index2,#1
                        jmp     #DomFound

XY                      cmp     A2,A0 wc                    ' C Set if (Z<X)
            if_c        mov     index0,#0                   ' X>Y & X>Z so Z = Dominant
            if_c        mov     index1,#1
            if_c        mov     index2,#2
            if_c        jmp     #DomFound

                        mov     index0,#2                   ' X<Z & X>Y so Z = Dominant
                        mov     index1,#0
                        mov     index2,#1
DomFound
                        
                        ' Calculate D(index)=A(index)-(A(index0)/2)
                        mov     index,index1
                        call    #Calc0        
                        mov     index,index2
                        call    #Calc0        

LoopStart               ' Calculate the points along the vector
                        cmp     PStatus,#1 wz               ' Are we looping
        if_z            jmp     #NotDone
        
Done                    wrlong  zeromask,StatusAt           ' Done with move, clear status
                        mov     PStatus,#0
                        mov     outa,#0                     ' Release control of outputs
                        jmp     #Disable

NotDone
'===================================================================================                                
                        wrlong  XCur,XCurAt                 ' Write Output  
                        wrlong  YCur,YCurAt  
                        wrlong  ZCur,ZCurAt

' Debugging variable, can be removed
wrlong negone,latchat ' set a "latch" flag so that the SPIN code can hold up processing until it is written to the serial port then cleared to release the hold.

                        subs    FromX,XCur wz               ' Set up which pins get strobed for STEP pulse
        if_nz           mov     tmp1,StepPinX            
                        subs    FromY,YCur wz
        if_nz           or      tmp1,StepPinY            
                        subs    FromZ,ZCur wz
        if_nz           or      tmp1,StepPinZ            
                          
                        or      tmp1,Sign      
                        mov     outa,tmp1
                        call    #Pulse
                        
                        mov     FromX,XCur
                        mov     FromY,YCur
                        mov     FromZ,ZCur
'===================================================================================                                

                        ' See if we have arrived at the endpoint
                        mov     pointer,#XCur               
                        mov     index,index0
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        mov     tmp2,tmp1
                        mov     pointer,#C0                 
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        cmps    tmp1,tmp2 wz
        if_z            jmp     #Done

                        ' Calculate the next point along the vector
                        mov     pointer,#D0                 
                        mov     index,index1
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        cmps    ZeroMask,tmp1 wc              ' Set C if move needed
                        
                        ' Cur(index)=Cur(index)+S(index)
                        ' D(index)=D(index)-A(Index0)
        if_c            call    #Calc1                  ' Calculate move for axis

                        mov     pointer,#D0                 
                        mov     index,index2
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        cmps    ZeroMask,tmp1 wc              ' Set C if move needed
                        
                        ' Cur(index)=Cur(index)+S(index)
                        ' D(index)=D(index)-A(Index0)
        if_c            call    #Calc1                  ' Calculate move for axis
                        
                        ' Cur(Index0)=Cur(Index0)+S(Index0)
                        ' D(Index)=D(Index)+A(Index)
                        mov     pointer,#S0                 ' Current_Position(0) = Current_Position(0)+s(0)
                        mov     index,index0
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        mov     tmp2,tmp1                       ' Save S(e)
                        mov     pointer,#XCur               
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        adds    tmp1,tmp2
                        call    #Writet12Index                ' Write indexed tmp1 into variable @Pointer(Index)


                        mov     index,index1
                        call    #Calc2
                        mov     index,index2
                        call    #Calc2

                        jmp     #LoopStart
                                

ReadIndex2t1            ' Read an indexed variable @Pointer(index) into variable tmp1
                        
                        add     Pointer,index               ' Add index longs to viriable array address
                        movs    RI2t1,Pointer
                        nop
                        
RI2t1                   mov       tmp1,0-0
ReadIndex2t1_Ret        ret                          

Writet12Index           ' Write tmp1 to previuous indexed variable @Pointer(index)
                        movd    Wt12I,Pointer
                        nop                        
Wt12I                   mov     tmp1,tmp1
Writet12Index_Ret       ret                        


Calc0                   ' Calculate D(index)=A(index)-(A(Index0)/2)
                        mov     tmp3,index
                        mov     index,index0
                        mov     pointer,#A0
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        shr     tmp1,#1
                        mov     tmp2,tmp1                        
                        mov     pointer,#A0
                        mov     index,tmp3
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        subs    tmp1,tmp2
                        mov     pointer,#D0
                        add     pointer,index
                        call    #Writet12Index      
Calc0_ret               ret


                        ' Cur(index)=Cur(index)+S(index)
                        ' D(index)=D(index)-A(Index0)
Calc1                   ' Enter with Index set
                        mov     Pointer,#S0                 ' Current_Position(index) = Current_Position(index)+s(index)
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        mov     tmp2,tmp1
                        mov     Pointer,#XCur                 
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        adds    tmp1,tmp2                                                
                        call    #Writet12Index                ' Write indexed tmp1 into variable @Pointer(Index)

                        mov     Pointer,#A0                 ' D(index) = D(index)-A(0)
                        mov     tmp3,index
                        mov     index,index0
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        mov     index,tmp3
                        mov     tmp2,tmp1
                        mov     Pointer,#D0                 ' D(index) = D(index)-A(0)
                        call    #ReadIndex2t1                 ' Read indexed variable @Pointer(Index) into variable tmp1
                        subs    tmp1,tmp2                                                
                        call    #Writet12Index                ' Write indexed tmp1 into variable @Pointer(Index)
Calc1_ret               ret

                        ' D(Index)=D(Index)+A(Index)
Calc2                   ' Enter with Index set
                        mov     Pointer,#A0                 ' D(index)=D(index)+a(index)
                        call    #ReadIndex2t1
                        mov     tmp2,tmp1
                        mov     Pointer,#D0
                        call    #ReadIndex2t1
                        adds    tmp1,tmp2
                        call    #Writet12Index                ' Write indexed tmp1 into variable @Pointer(Index)
Calc2_Ret               ret


Pulse 
                        mov     tmp1,PulseTime
Pulse1                  djnz    tmp1,#Pulse1
                        mov     outa,Sign
                        mov     tmp1,PulseTime
Pulse1a                 djnz    tmp1,#Pulse1a
                        
pulse2                                                                     
                        rdlong  tmp1,latchat wz

' Check "latch" flag so that the SPIN code can hold up processing until it is written to the serial port then cleared to release the hold.
if_nz  jmp  #pulse2         ' debugging statement, this is used to

Pulse_ret               ret


PulseTime       long        $2ff        ' a time delay while strobing the step pin
ZeroMask        long        $0000_0000      
NegOne          long        $FFFF_FFFF
                                       
StepPinX        long    1   ' X-Axis Stepper Motor Step Pin
DirPinX         long    1   ' X-Axis Stepper Motor Direction Pin
StepPinY        long    1   ' Y-Axis Stepper Motor Step Pin
DirPinY         long    1   ' Y-Axis Stepper Motor Direction Pin
StepPinZ        long    1   ' Z-Axis Stepper Motor Step Pin
DirPinZ         long    1   ' Z-Axis Stepper Motor Direction Pin

StepPins        res     1   

tmp1            res     1   ' Temporary Variable
tmp2            res     1   ' Temporary Variable
tmp3            res     1   ' Temporary Variable

Pointer         res     1   ' Pointer to array starting address
Index           res     1   ' Index to variabe within the array

' Addresses of Pass-Through Variables
StatusAt        res     1   ' Address of Circular Interpolation Status Long
FromXAt         res     1   ' Address of From X Coordinate Long
FromYAt         res     1   ' Address of From Y Coordinate Long
FromZAt         res     1   ' Address of From Z Coordinate Long
ToXAt           res     1   ' Address of To X Coordinate Long
ToYAt           res     1   ' Address of To Y Coordinate Long
ToZAt           res     1   ' Address of To Z Coordinate Long
XCurAt          res     1   ' Address of current X Position
YCurAt          res     1   ' Address of current Y Position
ZCurAt          res     1   ' Address of current Z Position

' Values read from Pass-Through Variables
PStatus         res     1   ' Value of the status long

FromX           res     1   ' Value of From X Coordinate
FromY           res     1   ' Value of From Y Coordinate
FromZ           res     1   ' Value of From Z Coordinate

ToX             res     1   ' Value of To X,Coordinate
ToY             res     1   ' Value of To Y Coordinate
ToZ             res     1   ' Value of To Z Coordinate

XCur            res     1   ' Current X Coordinate
YCur            res     1   ' Current Y Coordinate
ZCur            res     1   ' Current Z Coordinate

'Calculated Variables
A0              res     1
A1              res     1
A2              res     1
C0              res     1   ' Endpoint of move along X
C1              res     1   ' Endpoint of move along Y
C2              res     1   ' Endpoint of move along Z
D0              res     1
D1              res     1
D2              res     1
S0              res     1   
S1              res     1   
S2              res     1   

index0          res     1
index1          res     1
index2          res     1
Sign            res     1   ' Sign Bit Status for Step & Direction Moves

' debugging variables
latchat res 1

                fit     496

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