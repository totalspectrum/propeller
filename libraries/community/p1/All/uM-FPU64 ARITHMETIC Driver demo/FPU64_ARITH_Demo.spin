{{
┌────────────────────────────┬───────────────────┬───────────────────────┐
│ FPU64_ARITH_Demo.spin v1.1 │ Author: I.Kövesdi │ Release: 30 Nov 2011  │
├────────────────────────────┴───────────────────┴───────────────────────┤
│                    Copyright (c) 2011 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This is a PST application to demonstrate an ARITHMETIC driver object  │
│ for the uM-FPU64 with 2-wire SPI connection.                           │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  The FPU64_ARITH_Driver used in this demo is based upon the core       │
│ FPU64_SPI_Driver v1.1, which is enhanced here with many arithmetic     │
│ functions. It facilitates the use of the uM-FPU64 from SPIN code       │
│ ditrectly.                                                             │
│  The uM-FPU64 floating point coprocessor supports 64-bit IEEE 754      │
│ compatible floating point and integer operations, as well as 32-bit    │
│ IEEE 754 compatible floating point and integer operations.             │
│  Advanced instructions are provided for fast data transfer, matrix     │
│ operations, FFT calculations, serial input/output, NMEA sentence       │
│ parsing, string handling, digital input/output, analog input, and      │
│ control of local devices.                                              │
│  Local device support includes: RAM, 1-Wire, I2C, SPI, UART, counter,  │
│ servo controller, and LCD devices. A built-in real-time clock and      │
│ foreground/background processing is also provided. The uM-FPU64 can    │
│ act as a complete subsystem controller for sensor networks, robotic    │
│ subsystems, IMUs, and other applications.                              │
│  The chip is available in 28-PIN DIP package, too.                     │
│                                                                        │    
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  The ARITH driver is a member of a family of drivers for the uM-FPU64  │
│ with 2-wire SPI connection. The family has been placed on OBEX:        │
│                                                                        │
│  FPU64_SPI     (Core driver of the FPU64 family)                       │
│ *FPU64_ARITH   (Basic arithmetic operations)                           │
│  FPU64_MATRIX  (Basic and advanced matrix operations)                  │
│  FPU64_FFT     (FFT with advanced options as, e.g. ZOOM FFT)     (soon)│
│                                                                        │
│  The procedures and functions of these drivers can be cherry picked and│
│ used together to build application specific uM-FPU64 drivers.          │
│  Other specialized drivers, as GPS, MEMS, IMU, MAGN, NAVIG, ADC, DSP,  │
│ ANN, STR are in preparation with similar cross-compatibility features  │
│ around the instruction set and with the user defined function ability  │
│ of the uM-FPU64.                                                       │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
}}


CON

_CLKMODE = XTAL1 + PLL16X
_XINFREQ = 5_000_000

{
Schematics
                                                3V3 
                                               (REG)                                                           
                                                 │                   
P   │                                     10K    │
  A0├1────────────────────────────┳───────────┫
R   │                              │             │
  A1├2────────────────────┐       │             │
O   │                      │       │             │
  A2├3────┳──────┐                          │
P   │       │      17     16       1             │
            │    ┌──┴──────┴───────┴──┐          │                             
          1K    │ SIN   SCLK   /MCLR │          │                
            │    │                    │          │  LED
            └──18┤SOUT            AVDD├28──┳─────╋────┐
                 │                 VDD├13──┼─────┫      │
                 │      uM-FPU64      │     0u1       │
                 │    (28 PIN DIP)    │    │     │      │
                 │                    │               │
            ┌──15┤/SS                 │   GND   GND     │ 
            ┣───9┤SEL                 │                 │
            ┣──14┤SERIN          /BUSY├10─────────────┘
            ┣──27┤AVSS                │        200 
            ┣───8┤VSS     VCAP        │         
            │    └──────────┬─────────┘
            │              20               
            │               │                             
            │                6u2 tantalum   
            │               │               
                                     6u2: 6.2 microF       
           GND             GND         0u1: 100 nF, close to the VDD pins

The SEL pin(9) of the FPU64 is tied to LOW to select SPI mode at Reset and
must remain LOW during operation. In this Demo the 2-wire SPI connection
was used, where the SOUT pin(18) and SIN pin(17) were connected through a
1K resistor and the A2 DIO pin(3) of the Propeller was connected to the SIN
pin(17) of the FPU. Since in this demo only one uM-FPU64 chip is used, the
SPI Slave Select pin(15) of the FPU64 is tied to ground.
}

'                            Interface lines
'            On Propeller                           On FPU64
'-----------------------------------  ------------------------------------
'Sym.   A#/IO       Function            Sym.  P#/IO        Function
'-------------------------------------------------------------------------
_FCLR = 0 'Out  FPU Master Clear   -->  MCLR  1  In   Master Clear
_FCLK = 1 'Out  FPU SPI Clock      -->  SCLK 16  In   SPI Clock Input     
_FDIO = 2 ' Bi  FPU SPI In/Out     -->  SIN  17  In   SPI Data In 
'       └───────────────via 1K     <--  SOUT 18 Out   SPI Data Out


OBJ

PST     : "Parallax Serial Terminal"   'From Parallax Inc.
                                       'v1.0
                                       
FPU     : "FPU64_ARITH_Driver"         'v1.1

  
VAR

LONG  okay, fpu64, char
LONG  strPtr, strPtr2
LONG  cog_ID
LONG  cntr, time, dTime
LONG  floatVal
LONG  dfloatVal[2]
LONG  dfloatVal2[2]
LONG  dfloatRes[2]
LONG  dlongVal[2]
LONG  dlongVal2[2]
LONG  dlongRes[2]


DAT '------------------------Start of SPIN code---------------------------

  
PUB Start_Application | addrCOG_ID_                                                     
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Start_Application │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: -Starts driver objects
''             -Makes a MASTER CLEAR of the FPU and
''             -Calls demo procedures
'' Parameters: None
''     Result: None
''+Reads/Uses: /fpu64, Hardware constants from CON section
''    +Writes: fpu64,
''      Calls: FullDuplexSerialPlus->PST.Start
''             FPU_SPI_Driver ------>FPU.StartCOG
''                                   FPU.StopCOG 
''             FPU_Demo, FPU_Demo_Lite 
'-------------------------------------------------------------------------
'Start FullDuplexSerialPlus PST terminal
PST.Start(57600)
  
WAITCNT(4 * CLKFREQ + CNT)

PST.Char(PST#CS)
PST.Str(STRING("Demo of uM-FPU64 ARITH Driver started..."))
PST.Char(PST#NL)

WAITCNT(CLKFREQ + CNT)

addrCOG_ID_ := @cog_ID

fpu64 := FALSE

'FPU Master Clear...
PST.Str(STRING(10, "FPU64 Master Clear..."))
OUTA[_FCLR]~~ 
DIRA[_FCLR]~~
OUTA[_FCLR]~
WAITCNT(CLKFREQ + CNT)
OUTA[_FCLR]~~
DIRA[_FCLR]~

fpu64 := FPU.StartDriver(_FDIO, _FCLK, addrCOG_ID_)

PST.Chars(PST#NL, 2)  

IF fpu64

  PST.Str(STRING("FPU64_ARITH_Diver started in COG "))
  PST.Dec(cog_ID)
  PST.Chars(PST#NL, 2)
  WAITCNT(CLKFREQ + CNT)

  FPU64_ARITH_Demo

  PST.Char(PST#NL)
  PST.Str(STRING("FPU64_ARITH_Driver demo terminated normally."))

  FPU.StopDriver
   
ELSE

  PST.Char(PST#NL)
  PST.Str(STRING("FPU64_ARITH_Driver start failed!"))
  PST.Chars(PST#NL, 2)
  PST.Str(STRING("Device not detected! Check hardware and try again..."))

WAITCNT(CLKFREQ + CNT)
  
PST.Stop  
'--------------------------End of Start_Application-----------------------    


PRI FPU64_ARITH_Demo | i, r, c
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ FPU64_ARITH_Demo │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates some uM-FPU64 features by calling 
'             FPU64_SPI_Driver procedures
' Parameters: None
'     Result: None
'+Reads/Uses: /okay, char, Some constants from the FPU object
'    +Writes: okay, char
'      Calls: FullDuplexSerialPlus->PST.Str
'                                   PST.Dec
'                                   PST.Hex
'                                   PST.Bin   
'             FPU64_SPI_Driver ---->FPU. Many of the procedures
'       Note: Emphasize is on 64-bit features 
'-------------------------------------------------------------------------
PST.Char(PST#CS) 
PST.Str(STRING("----uM-FPU64 with 2-wire SPI connection----"))
PST.Char(PST#NL)

WAITCNT(CLKFREQ + CNT)

okay := FALSE
okay := Fpu.Reset
PST.Char(PST#NL)   
IF okay
  PST.Str(STRING("FPU Software Reset done..."))
  PST.Char(PST#NL)
ELSE
  PST.Str(STRING("FPU Software Reset failed..."))
  PST.Char(PST#NL)
  PST.Str(STRING("Please check hardware and restart..."))
  PST.Char(PST#NL)
  REPEAT

WAITCNT(CLKFREQ + CNT)

char := FPU.ReadSyncChar
PST.Char(PST#NL)
PST.Str(STRING("Response to _SYNC: $"))
PST.Hex(char, 2)
IF (char == FPU#_SYNC_CHAR)
  PST.Str(STRING("    (OK)"))
  PST.Char(PST#NL)  
ELSE
  PST.Str(STRING("   Not OK!"))   
  PST.Char(PST#NL)
  PST.Str(STRING("Please check hardware and restart..."))
  PST.Char(PST#NL)
  REPEAT

PST.Char(PST#NL)
PST.Str(STRING("   Version String: "))
FPU.WriteCmd(FPU#_VERSION)
FPU.Wait
PST.Str(FPU.ReadStr) 

PST.Char(PST#NL)
PST.Str(STRING("     Version Code: $"))
FPU.WriteCmd(FPU#_LREAD0)
PST.Hex(FPU.ReadReg, 8) 
  
PST.Char(PST#NL)
PST.Str(STRING(" Clock Ticks / ms: "))
PST.Dec(FPU.ReadInterVar(FPU#_TICKS))
PST.Char(PST#NL) 

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("Conversions from STRING to 64-bit DFLOAT"))
PST.Chars(PST#NL, 2)

strPtr := STRING("1.12345678901234")

FPU.STR_To_F64(strPtr, @dfloatVal)

PST.Str(STRING("'1.12345678901234' as 64-bit DFLOAT:"))
PST.Chars(PST#NL, 2)

PST.Str(FPU.F64_To_STR(@dfloatVal, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("Conversions from STRING to 32-bit FLOAT"))
PST.Chars(PST#NL, 2)

strPtr := STRING("1.1234567")

floatVal := FPU.STR_To_F32(strPtr)

PST.Str(STRING("'1.1234567' as 32-bit FLOAT:"))
PST.Chars(PST#NL, 2)

PST.Str(FPU.F32_To_STR(floatVal, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DFLOAT negation"))
PST.Chars(PST#NL, 2)

strPtr := STRING("1.12345678901234")

FPU.STR_To_F64(strPtr, @dfloatVal)

FPU.F64_Neg(@dfloatVal)

PST.Str(STRING(" Input : 1.12345678901234 as 64-bit DFLOAT"))
PST.Chars(PST#NL, 2)

PST.Str(STRING("Output : "))
PST.Str(FPU.F64_To_STR(@dfloatVal, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DFLOAT reciprocal"))
PST.Chars(PST#NL, 2)

strPtr := STRING("1.12345678901234")
FPU.STR_To_F64(strPtr, @dfloatVal)

FPU.F64_INV(@dfloatVal, @dfloatRes)

PST.Str(STRING(" Input : 1.12345678901234 as 64-bit DFLOAT"))
PST.Chars(PST#NL, 2)

PST.Str(STRING("Output : "))
PST.Str(FPU.F64_To_STR(@dfloatRes, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DFLOAT addition"))
PST.Chars(PST#NL, 2)

strPtr := STRING("-1.12345678901234")
FPU.STR_To_F64(strPtr, @dfloatVal)

strPtr2 := STRING("9.87654321098765")
FPU.STR_To_F64(strPtr2, @dfloatVal2)

FPU.F64_ADD(@dfloatVal, @dfloatVal2, @dfloatRes)

PST.Str(strPtr)
PST.Char(PST#NL)
PST.Str(STRING("+"))
PST.Char(PST#NL)
PST.Str(strPtr2)
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
PST.Str(FPU.F64_To_STR(@dfloatRes, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DFLOAT subtraction"))
PST.Chars(PST#NL, 2)

strPtr := STRING("11.12345678901234")
FPU.STR_To_F64(strPtr, @dfloatVal)

strPtr2 := STRING("9.87654321098765")
FPU.STR_To_F64(strPtr2, @dfloatVal2)

FPU.F64_SUB(@dfloatVal, @dfloatVal2, @dfloatRes)

PST.Str(strPtr)
PST.Char(PST#NL)
PST.Str(STRING("-"))
PST.Char(PST#NL)
PST.Str(strPtr2)
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
PST.Str(FPU.F64_To_STR(@dfloatRes, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DFLOAT multiplication"))
PST.Chars(PST#NL, 2)

strPtr := STRING("9.8765432109876")
FPU.STR_To_F64(strPtr, @dfloatVal)

strPtr2 := STRING("-1.12345678901234")
FPU.STR_To_F64(strPtr2, @dfloatVal2)

FPU.F64_MUL(@dfloatVal, @dfloatVal2, @dfloatRes)

PST.Str(strPtr)
PST.Char(PST#NL)
PST.Str(STRING("*"))
PST.Char(PST#NL)
PST.Str(strPtr2)
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
PST.Str(FPU.F64_To_STR(@dfloatRes, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DFLOAT divison"))
PST.Chars(PST#NL, 2)

strPtr := STRING("9.8765432109876")
FPU.STR_To_F64(strPtr, @dfloatVal)

strPtr2 := STRING("-1.12345678901234")
FPU.STR_To_F64(strPtr2, @dfloatVal2)

FPU.F64_DIV(@dfloatVal, @dfloatVal2, @dfloatRes)

PST.Str(strPtr)
PST.Char(PST#NL)
PST.Str(STRING("/"))
PST.Char(PST#NL)
PST.Str(strPtr2)
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
PST.Str(FPU.F64_To_STR(@dfloatRes, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DLONG negation"))
PST.Chars(PST#NL, 2)

strPtr := STRING("-998877665544332211")

FPU.STR_To_L64(strPtr, @dlongVal)

FPU.L64_Neg(@dlongVal)

PST.Str(STRING(" Input : -998877665544332211 as 64-bit DLONG"))
PST.Chars(PST#NL, 2)

PST.Str(STRING("Output : "))
PST.Str(FPU.L64_To_STR(@dlongVal, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DLONG addition"))
PST.Chars(PST#NL, 2)

strPtr := STRING("-12345678987654321")
FPU.STR_To_L64(strPtr, @dlongVal)

strPtr2 := STRING("98765432123456789")
FPU.STR_To_L64(strPtr2, @dlongVal2)

FPU.L64_ADD(@dlongVal, @dlongVal2, @dlongRes)

PST.Str(strPtr)
PST.Char(PST#NL)
PST.Str(STRING("+"))
PST.Char(PST#NL)
PST.Str(strPtr2)
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
PST.Str(FPU.L64_To_STR(@dlongRes, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DLONG subtraction"))
PST.Chars(PST#NL, 2)

strPtr := STRING("112233445566778899")
FPU.STR_To_L64(strPtr, @dlongVal)

strPtr2 := STRING("98765432123456789")
FPU.STR_To_L64(strPtr2, @dlongVal2)

FPU.L64_SUB(@dlongVal, @dlongVal2, @dlongRes)

PST.Str(strPtr)
PST.Char(PST#NL)
PST.Str(STRING("-"))
PST.Char(PST#NL)
PST.Str(strPtr2)
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
PST.Str(FPU.L64_To_STR(@dlongRes, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DLONG multiplication"))
PST.Chars(PST#NL, 2)

strPtr := STRING("-123456789")
FPU.STR_To_L64(strPtr, @dlongVal)

strPtr2 := STRING("987654321")
FPU.STR_To_L64(strPtr2, @dlongVal2)

FPU.L64_MUL(@dlongVal, @dlongVal2, @dlongRes)

PST.Str(strPtr)
PST.Char(PST#NL)
PST.Str(STRING("*"))
PST.Char(PST#NL)
PST.Str(strPtr2)
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
PST.Str(FPU.L64_To_STR(@dlongRes, 0))
PST.Char(PST#NL)

QueryReboot

PST.Char(PST#CS)    
PST.Str(STRING("64-bit DLONG division"))
PST.Chars(PST#NL, 2)

strPtr := STRING("998877665544332211")
FPU.STR_To_L64(strPtr, @dlongVal)

strPtr2 := STRING("987654321")
FPU.STR_To_L64(strPtr2, @dlongVal2)

FPU.L64_DIV(@dlongVal, @dlongVal2, @dlongRes)

PST.Str(strPtr)
PST.Char(PST#NL)
PST.Str(STRING("/"))
PST.Char(PST#NL)
PST.Str(strPtr2)
PST.Char(PST#NL)
PST.Str(STRING("="))
PST.Char(PST#NL)
PST.Str(FPU.L64_To_STR(@dlongRes, 0))
PST.Chars(PST#NL, 2)

'Calculate reminder
FPU.L64_MUL(@dlongVal2, @dlongRes, @dlongRes)
FPU.L64_SUB(@dlongVal, @dlongRes, @dlongRes)

PST.Str(STRING("64-bit DLONG modulo"))  
PST.Char(PST#NL) 
PST.Str(FPU.L64_To_STR(@dlongRes, 0))
PST.Char(PST#NL)

QueryReboot
'------------------------End of FPU64_ARITH_Demo--------------------------


PRI QueryReboot | done, r
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ QueryReboot │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Queries to reboot or to finish
' Parameters: None                                
'    Returns: None                
'+Reads/Uses: PST#NL, PST#PX                     (OBJ/CON)
'    +Writes: None                                    
'      Calls: "Parallax Serial Terminal"--------->PST.Str
'                                                 PST.Char 
'                                                 PST.RxFlush
'                                                 PST.CharIn
'------------------------------------------------------------------------
PST.Char(PST#NL)
PST.Str(STRING("[R]eboot or press any other key to continue..."))
PST.Char(PST#NL)
done := FALSE
REPEAT UNTIL done
  PST.RxFlush
  r := PST.CharIn
  IF ((r == "R") OR (r == "r"))
    PST.Char(PST#PX)
    PST.Char(0)
    PST.Char(32)
    PST.Char(PST#NL) 
    PST.Str(STRING("Rebooting..."))
    WAITCNT((CLKFREQ / 10) + CNT) 
    REBOOT
  ELSE
    done := TRUE
'----------------------------End of QueryReboot---------------------------


DAT '---------------------------MIT License------------------------------- 


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}