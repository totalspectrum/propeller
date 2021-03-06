{{

  Stepper Motor Driver PASM Program
  Don Starkey  Don@StarkeyMail.com
  
  Uses a step & direction type motor driver.

  Current version 1.0 11/14/2010


  Pass parameters to this program while disabled.
  Re-enable to apply parameters and start motion
  

   I/O 16, Pin 21 - Step Pin
   I/O 17, Pin 22 - Direction Pin (Must be 1 Pin ABOVE than Step Pin)  
                                      
   I/O 20, Pin 25 - Home Switch, Active LOW                            

   I/O 28, Pin 37 - SCL I2C
   I/O 39, Pin 38 - SDA I2C
   I/O 30, Pin 39 - Serial Communications
   I/O 31, Pin 40 - Serial Communications
}}

CON
    _CLKMODE    =   XTAL1 + PLL16X                       
    _XINFREQ    =   5_000_000

  
PUB Start (Step_Pin,OT_Pin,Freq_Addr,STable) | stalled

''RETURNS: Nothing

' Usage: Start(Step_Pin,Home_Switch_Pin,@Parameter_TableAddress,@StepTable) to initialize routine

' Motion parameters are stored in the SPIN code that calls this program
' Once this program is loaded into a cog, it is controlled by changing the variables in the main SPIN program

' To execute a move:

'   1. Set the enable flag to 0
'   2. Set the frequency in steps/second when moving at full speed
'   3. Set the distance to move as a positive or negative RELATIVE distance.
'   4. Set the enable flag to 1 to start the move
'   5. Monitor the moving bit( bit 3) of the flags to determine if the move has finished


    StepPin := Step_Pin
    OverTravelMask := |< (OT_Pin)
    
    Addr_STable:=STable                 ' Address of Step Table in shared memory
    Segments:=long[STable-4]            ' Number of segments in step table
    RampSteps:=2*long[STable-4]         ' Distance necessary to ramp-Up & Ramp-Down

    cognew(@StepDrive, Freq_Addr)       ' Start low level driver, pass it the address of the parameter table


'**************************
'* Stepper Driver Routine *
'**************************

DAT
{{
        Enter with: 
  Frequency     ' +0  Step Speed in Hz.
  Distance      ' +4  Step Distance in Steps
  StepEnable    ' +8 Enable Stepper Routine
                '      0=disabled, Disable Step/Direction Outputs
                '      1=Enabled, Drive Stepper & Honor Home Switch = Over travel if moving in positive Direction

  StepFlags     ' +12 Stepper Flags
                '         Flag:Bit 0 =
                '         Flag:Bit 1 = Over travel Condition Exists
                '         Flag:Bit 2 = 
                '         Flag:Bit 3 = Moving, 1=Moving, 0=Stopped

  MotorAt       ' +16 Real-Time Motor Position in steps
        
        This routine checks for changes made to these external parameters
        only when disabled. Make adjustments to parameters when disabled.
        re-enable to begin the move. }}

                        org     0
StepDrive
                        mov     t0,#3                   ' Set port mask for step & direction outputs             
                        shl     t0,StepPin
                        mov     StepDirMask, t0         ' Port for Output

                        mov     t2,Par
                        mov     Addr_Freq,t2            ' +0 Frequency
                        add     t2,#4
                        mov     Addr_Dist,t2            ' +4 Distance
                        add     t2,#4
                        mov     Addr_Enable,t2          ' +8 Enable
                        add     t2,#4
                        mov     Addr_Flags,t2           ' +12 Flags
                        add     t2,#4
                        mov     Addr_Motor_At,t2        ' +16 Real-time location of motor
                        mov     output,#0
                        
Disable

                        mov     dira,#0                 ' Disable Outputs
                        mov     outa,#0

                        rdlong  flags,Addr_Flags
                        and     flags,#%10              ' Clear all but over travel flag
                        wrlong  flags,Addr_Flags
                        
                        mov     Index,#0                
                        mov     Count,#0
                        mov     Index_Dir,#1
                        rdlong  Motor_At,Addr_Motor_At
                        
                        rdlong  Freq,Addr_Freq          ' +0 Frequency Of Stepper Drive @ Maximum Speed                   
                        rdlong  Dist,Addr_Dist          ' +4 Distance To Travel +/- direction
                        
                        'turn negative distance in positive
                        cmps    dist,#0 wc
              if_nc     mov     dir,#1
              if_c      mov     dir,NegOne              ' Set direction bit to 1 or -1
              if_c      xor     dist,NegOne             ' change sign of distance from - to +
              if_c      add     dist,#1         '          
                        mov     WholeDist,dist
 
                        cmp     dist,RampSteps wz, wc
                        mov     TravLength,Dist
              if_ae     sub     TravLength,RampSteps
              if_b      mov     TravLength,#0
              
              if_a      shl     dist,#1                 ' Make sure we don't cause a short move
              if_be     shr     dist,#1                 ' Divide distance by two for short move checking (1/2 ramping up, 1/2 ramping down)
              
                        mov     state,#0
                        mov     LastMove,Cnt            ' Save time of last move to check for end of movement

Go
                        rdlong  Enable,Addr_Enable wz   '+8 -  Enable / Disabled ?
              if_z      jmp     #Disable                ' Yes, Loop until enabled 

                        mov     outa,output             ' Take control of output pins
                        mov     dira,StepDirMask
                        

                        rdlong  freq,Addr_Freq wz       ' Can change frequency on the fly
              if_z      jmp     #Go                     ' If enabled but freq=0 wait

                        cmp     state,#0 wz
              if_nz     jmp     #ReadTable
              
                        mov     state,#1                ' we are moving now
                        mov     StartTime,cnt           ' Seed the timer
ReadTable                  
                        call    #ReadSTable             ' Get acceleration value from step table
                        
'==============================================================================================================
'==================================== Stepper Motion Profile Starts Here ======================================
'==============================================================================================================

                        mov     LastMove,Cnt            ' Save time of last move to check for end of movement
                        or      flags,#%1000            ' Set Flag that we are moving

                        ' Check for overtravel in negative direction
                        cmp     dir,#1 wz
               if_z     jmp      #NoOverTravel          ' only check over travel in negative direction
              
                        mov     t2,ina
                        and     t2,OverTravelMask wz
               if_nz    jmp     #NoOvertravel

                        'Overtravel Occured
                        mov      Enable,#0
                        wrlong   Enable,Addr_Enable     ' Set enabled to 0 to signal over travel
                         
                        mov     Flags,#%10              ' Over travel Flag Bit              
                        jmp     #StopMe

NoOverTravel
                        
                        call    #StepMotor              ' Move 1 step
                        
                        ' delay for TimeDone clock cycles                        
                        add     StartTime,TimeDone
                        waitcnt StartTime,#0            ' wait for some time
                        mov     StartTime,cnt 
                        
                        adds    Index,Index_Dir                        

                        cmp     Index_Dir,#1 wz
            if_nz       jmp     #notForward

                        cmp     count,dist wz,wc         ' Short move, switch to ramping down                        
            if_e        mov     Index_Dir,NegOne         ' change index direction to -1
            if_a        jmp     #StopMe

                        cmp     Index,Segments wz
            if_nz       jmp     #UpdateMem
                        mov     Index_Dir,#0             ' Signal to traverse
NotForward  
                        cmp     Index_Dir,#0 wz          ' Traverse move?
            if_nz       jmp     #Reverse

                        cmp     TravLength,#0 wz
            if_nz       sub     TravLength,#1
            if_nz       jmp     #UpdateMem
                        mov     Index_Dir,NegOne         
            
Reverse
                        cmp     index,#0 wz
            if_nz       jmp     #UpdateMem

 
StopMe
                        mov     t2,#1
                        cmp     t2,WholeDist wc         ' Must be a distance > 1
                        and     WholeDist,#1 wz         ' If odd distance, add additional step
            if_c_and_nz call    #StepMotor

                        mov     state,#0
                        wrlong  ZeroMask,Addr_Freq      ' set freq to 0 to signal done
                        mov     Enable,#0
                        jmp     #UpdateMem


ReadSTable              ' harvest value from Step table
                        mov     t4,index
                        shl     t4,#2                   ' 4-bytes per long
                        mov     t5,Addr_STable
                        add     t5,t4
                        rdlong  delay,t5
                        
                        mov     MX0,delay
                        mov     MY0,OneInch
                        call    #Multiply
                         
                        mov     MX0,Freq
                        call    #Divide

                        mov     TimeDone,MY0

ReadSTable_Ret          ret


StepMotor               ' Move motor
                        ' Set direction bit
                        mov     Output,dir          ' Dir = -1 or 1
                        xor     output,NegOne       ' Invert
                        and     output,#2           ' Result = 0 or 2 if neg direction
                        shl     output,StepPin      ' Direction Bit

                        mov     outa,output             ' Update the port with the direction bit
                        mov     O2,#1
                        shl     O2,StepPin
                        or      output,O2               ' Turn step bit ON
                        mov     outa,output

                        mov     e4,dlytime
dly                     djnz    e4,#dly

                        xor     output,O2               ' turn off step bit 
                        mov     outa,output             ' Turn step bit OFF

                        ' Update absolute motor position
                        add     Motor_At,Dir
                        wrlong  Motor_At,Addr_Motor_At
                        add     count,#1
                        wrlong  Flags,Addr_Flags       ' +12 Flags

StepMotor_ret           ret

UpdateMem     ' Write changed values back to shared memory
                        wrlong  Enable,Addr_Enable        ' Set Enabled to 0
                        Jmp     #Go


'32 bit UNSIGNED routine divide that yields a 32 bit quotient and remainder.
'Y0 (QUOTIENT) = Y0/X0, Y1 = REMAINDER

Divide                mov     Mt1,#32 
                      mov     My1,#0  

:loop                 rcl      My0,#1  wc                                  
                                                                                                 
                      rcl      My1,#1    
                                                                            

                      cmpsub  My1,Mx0   wc,wr                  
                  
                      djnz    Mt1, #:loop
           
                      rcl     My0, #1    
                                         
                                              
Divide_ret            ret
                        

'UNSIGNED multiplier routine that multiplies two 32-bit values to yield a 64-bit product:
' MY0 = MY0 * MX0, with MY1 holding higher bits of result


Multiply              mov my1, #0                      
                      mov mt1, #32     
                      shr my0,#1 wc    

:loop                 if_c    add my1,mx0 wc    

                      shr my1,#1 wc   
                      rcr my0,#1 wc    
                                      
                      djnz mt1,#:loop 

Multiply_ret          ret             

'Define Cog's constants/variables
ZeroMask                long    0
OneMask                 long    1
DlyTime                 long    $F
NegOne                  long    $FFFFFFFF               ' Output state
OneInch                 long    1000                    ' 1000 stepper counts per inch               
OverTravelMask          long    1                       ' Input Mask For Home Switch  Over travel
StepPin                 long    0                       ' Output pin for Stepper Pulse
Addr_Motor_At           long    0                       ' Address of Current Motor Position (in step) Variable

Addr_Freq               long    0                       ' Address of +0 Frequency variable
Addr_Dist               long    0                       ' Address of +4 Distance Variable
Addr_Enable             long    0                       ' Address of +8 Enable Variable
Addr_Flags              long    0                       ' Address of +12 Flags Variable
Addr_STable             long    0                       ' Address of Step Table
Segments                long    0                       ' Number of segments in Step table
RampSteps               long    0                       ' Distance necessary to ramp-Up & Ramp-Down


StepDirMask             res     1                       ' Step/Direction Pin Mask for OUTA
Freq                    res     1
dist                    res     1

state                   res     1        
dir                     res     1                       ' Direction Bit 0 for positive distances, 1 for negative distances
Index_Dir               res     1                       ' Direction of index. +1 for Accel, 0 for traverse, -1 for decel
StartTime               res     1
Delay                   res     1
LastMove                res     1
Output                  res     1                       ' Output state
Flags                   res     1

Index                   res     1                       ' Table Index
Count                   res     1                       ' Count  
WholeDist               res     1                       ' Whole Distance for the move

Motor_At                res     1                       ' Local copy of Current Motor Position (in step)
TravLength              res     1                       ' Length of traverse
TimeDone                res     1                       ' CNT value when done with this timed delay
    
Enable                  res     1                       ' Routine Enabled

T0                      res     1                       ' Temporary variable for interface
T1                      res     1                       ' Temp 1
T2                      res     1                       ' Temp 2
T3                      res     1                       ' Temp 3
T4                      res     1                       ' Temp 4
T5                      res     1                       ' Temp 5

O1                      res     1                       ' Temp for output routine
O2                      res     1                       ' Temp for output routine
O3                      res     1                       ' Temp for output routine
E4
MY0                     res     1                       ' Used in Multiplication & division subroutines
MY1                     res     1                       ' Used in Multiplication & division subroutines
MT1                     res     1                       ' Used in Multiplication & division subroutines
MX0                     res     1                       ' Used in Multiplication & division subroutines


        fit 496         ' Make sure it fits within a cog's memory space

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

