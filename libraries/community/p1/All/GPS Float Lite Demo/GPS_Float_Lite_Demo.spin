{{
┌───────────────────────────────┬───────────────────┬────────────────────┐
│ GPS_Float_Lite_Demo.spin v1.0 │ Author: I.Kövesdi │ Rel.: 24. jan 2009 │  
├───────────────────────────────┴───────────────────┴────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │ 
│  This Parallax Serial Terminal (PST) demo application introduces the   │
│ 'GPS_Str_NMEA_Lite.spin v1.0' and the 'GPS_Float_Lite.spin v1.0' driver│
│  objects.                                                              │
│  The 'GPS_Str_NMEA_Lite' driver interfaces the Propeller to a GPS      │
│ receiver. This NMEA-0183 parser captures and decodes RMC and GGA type  │
│ sentences of the GPS Talker device in a robust way.                    │                
│  The 'GPS_Float' driver object bridges a SPIN program to the strings   │
│ and longs provided by the basic 'GPS_Str_NMEA_Lite' driver and         │
│ translates them into long and float values and checks errors wherever  │
│ appropriate.                                                           │
│  These 2 'Lite' objects have standard version at Obex, too.            │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│   NMEA is an acronym for the "National Marine Electronics Association" │
│ that devise, control and publish a set of universal standards for      │
│ navigation instruments' communication. These standards are available in│
│ a few different versions, NMEA-0183 is the most prevalent, and any     │
│ marine and GPS instrument manufactured after about 1990 should be      │
│ compatible with NMEA-0183.                                             │
│  NMEA-2000 is a newer version of this standard that has simplified the │
│ interconnectivity requirements for instruments. While NMEA-0183 is only│
│ a single-Talker multi-Listener serial data inerterface, NMEA-2000 is a │
│ a multi-Talker, multi-Listener, no single Controller 'Open' network    │
│ system. It provides a stable high-speed communication protocol using   │
│ Controller Area Network (CAN) bus technology, especially  adapted for  │
│ the marine environment. To date very few NMEA-2000 devices, in         │
│ comparison with NMEA-0183 devices, exist. Of course over the ensuing   │
│ years, NMEA-2000 will eventually replace NMEA-0183, although existing  │
│ NMEA-0183 devices will remain installed and in-use for decades to come!│                                                 
│  Navigation and satellite information come from an NMEA-0183 GPS Talker│                                                                 
│ device in various formats usually with much useful redundancy. GPS     │
│ units usually send 3 to 6 sentences per second at 4_800 baud. Time and │
│ navigation data is contained at least in one or two of them, although  │
│ you may wait for a particular sentence sometimes for a couple of       │
│ seconds. The  currently released drivers are designed to capture and   │
│ merge all information from all recognized NMEA sentences. For example, │
│ UTC time, latitude and longitude data arrive in RMC, GGA and GLL       │
│ sentences, as well. To use only one sentence type for a given piece of │
│ data would be an unnecessary waste of already available resources, The │
│ position, speed and all other information is stored/merged at a common │
│ DAT place. This collection of data is refreshed partially, but always, │
│ from each of these sentences, meanwhile time stamps of the time of last│
│ reception is recorded with the critical and valid navigation data. By  │
│ this, the  responsiveness of the drivers is at the maximum and you can │
│ fully exploit the capabilities of your GPS.                            │     
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│ -These drivers have standard version, too. They are are realesed in the│
│ 'GPS_Float_Demo' application simultaneously with this Lite demo.       │
│ -The pinout for the Propeller / GPS connection is defined in the       │
│ 'GPS_Float_Lite' objects.                                              │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘  
}}


CON

_CLKMODE         = XTAL1 + PLL16x
_XINFREQ         = 5_000_000


OBJ

DBG            : "FullDuplexSerialPlus"
GPS            : "GPS_Float_Lite"
FS             : "FloatString"
  


PUB Init | oK1, oK2
'-------------------------------------------------------------------------
'-----------------------------------┌──────┐------------------------------
'-----------------------------------│ Init │------------------------------
'-----------------------------------└──────┘------------------------------
'-------------------------------------------------------------------------
''     Action: -Starts those drivers that will launch a COG directly or
''              implicitly
''             -Checks for a succesfull start
''             -If so : Calls demo procedure
'' Parameters: None                                 
''    Results: None                     
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: FullDuplexSerialPlus-------->DBG.Start
''             GPS_Float_Lite-------------->GPS.Init
''             Receive_GPS_Data                                                
'-------------------------------------------------------------------------

WAITCNT(CLKFREQ * 6 + CNT)

'Start FullDuplexSerialPlus Driver for debug. The Driver will launch a
'COG for serial communication with Parallax Serial Terminal
oK1 := DBG.Start(31, 30, 0, 57600)

DBG.Str(STRING(16, 1, 10, 13))
DBG.Str(STRING("  GPS Float Lite Demo v1.0 started...", 10, 13))

WAITCNT(CLKFREQ * 2 + CNT)

'Start GPS_Float_Lite object
oK2 := GPS.Init             'Connection pins are defined in the driver

IF NOT (oK1 AND oK2)        'Some error occured
  IF oK1                    'We have at least the debug terminal
    DBG.Str(STRING(10, 13))
    DBG.Str(STRING("Some error occurred. Check System!", 10, 13))
    DBG.Stop
  IF oK2
    GPS.Stop
    
  REPEAT                    'Until Power Off or Reset
  
Receive_GPS_Data
'-------------------------------------------------------------------------


PRI Receive_GPS_Data | i, j, k, fv
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ Receive_GPS_Data │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
'     Action: Receives and displays GPS data                                                   
' Parameters: Number of repetitions (Approx. duration in seconds)
'    Results: None                     
'+Reads/Uses: None                                               
'    +Writes: None                                    
'      Calls: GPS_Str_Float_Lite----->GPS.(most of the procedures)
'             FullDuplexSerialPlus--->DBG.Str
'                                     DBG.Dec
'             FloatString------------>FS.FloatToString   
'-------------------------------------------------------------------------

REPEAT   
  DBG.Str(STRING(16, 1))
  i := GPS.Long_Day
  j := GPS.Long_Month
  k := GPS.Long_Year
  IF (i<>-1) AND (j<>-1) AND (k<>-1)
    DBG.Str(STRING(" Day Month Year(AD) as LONGs : "))
    DBG.Dec(i) 
    DBG.Str(STRING("  ")) 
    DBG.Dec(j) 
    DBG.Str(STRING("  "))
    DBG.Dec(k) 
    DBG.Str(STRING(10, 13))
  i := GPS.Long_Hour
  j := GPS.Long_Minute
  k := GPS.Long_Second
  IF (i<>-1) AND (j<>-1) AND (k<>-1)    
    DBG.Str(STRING(" UTC Hour Min. Sec. as LONGs : "))
    DBG.Dec(i) 
    DBG.Str(STRING("  ")) 
    DBG.Dec(j) 
    DBG.Str(STRING("  "))
    DBG.Dec(k) 
    DBG.Str(STRING(10, 13))

  FS.SetPrecision(7)
  DBG.Str(STRING(" Latitude in degres as FLOAT : "))
  fv := GPS.Float_Latitude_Deg
  IF fv <> floatNaN
    DBG.Str(FS.FloatToString(fv))   
  ELSE
    DBG.Str(STRING("--.----"))  
  DBG.Str(STRING(10, 13))
          
  DBG.Str(STRING("Longitude in degres as FLOAT : "))
  fv := GPS.Float_Longitude_Deg
  IF fv <> floatNaN
    DBG.Str(FS.FloatToString(fv))   
  ELSE
    DBG.Str(STRING("---.----"))  
  DBG.Str(STRING(10, 13))

  FS.SetPrecision(5)
  DBG.Str(STRING("Speed Over Gnd [knots] FLOAT : "))
  fv := GPS.Float_Speed_Over_Ground
  IF fv <> floatNaN
    DBG.Str(FS.FloatToString(fv))   
  ELSE
    DBG.Str(STRING("---.--"))  
  DBG.Str(STRING(10, 13))
          
  DBG.Str(STRING("Course Over Gnd [degs] FLOAT : "))
  fv := GPS.Float_Course_Over_Ground
  IF fv <> floatNaN
    DBG.Str(FS.FloatToString(fv))   
  ELSE
    DBG.Str(STRING("---.--"))  
  DBG.Str(STRING(10, 13))
                    
  DBG.Str(STRING("Magn. Variation [degs] FLOAT : "))
  fv := GPS.Float_Mag_Var_Deg
  IF fv <> floatNaN
    DBG.Str(FS.FloatToString(fv))
  ELSE
    DBG.Str(STRING("--.-"))  
  DBG.Str(STRING(10, 13))
           
  DBG.Str(STRING("Alt. at Mean Sea Lev.  FLOAT : "))
  fv := GPS.Float_Altitude_Above_MSL
  IF fv <> floatNaN
    DBG.Str(FS.FloatToString(fv))
    DBG.Str(STRING(" "))
    DBG.Str(GPS.Str_Altitude_Unit)
  ELSE
    DBG.Str(STRING("-----.--"))  
  DBG.Str(STRING(10, 13))

  DBG.Str(STRING(" MSL relative to WGS84 FLOAT : "))
  fv := GPS.Float_Geoid_Height
  IF fv <> floatNaN
    DBG.Str(FS.FloatToString(fv))
    DBG.Str(STRING(" "))
    DBG.Str(GPS.Str_Geoid_Height_U)
  ELSE
    DBG.Str(STRING("---.-"))  
  DBG.Str(STRING(10, 13))

  WAITCNT(CLKFREQ / 2 + CLKFREQ / 4 + CNT)
    
'-------------------------------------------------------------------------


DAT

floatNaN       LONG $7FFF_FFFF                 'NaN code


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