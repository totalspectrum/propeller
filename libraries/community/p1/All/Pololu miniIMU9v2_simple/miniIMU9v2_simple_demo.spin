{{ miniIMU9v2_simple_demo.spin
┌─────────────────────────────────────┬──────────────┬──────────┬────────────┐
│ Pololu miniIMU-9 v2 drver demo      │ BR           │ (C)2016  │ 29Jul2016  │
├─────────────────────────────────────┴──────────────┴──────────┴────────────┤
│ Demo of driver object for interfacing with the Pololu miniIMU-9 v2         │
│ 9 DOF accelerometer, magnetometer, gyro module.  Output to serial terminal │
│                                                                            │
│ See end of file for terms of use.                                          │
└────────────────────────────────────────────────────────────────────────────┘
}}
con
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  
obj
  pst  : "parallax serial terminal"                            
  imu  : "miniIMU9v2_simple"


pub go | tmp,x,y,z

 'initialize ser and i2c objects
  pst.start(115200)
  imu.setupx(11,12)

  'turn on acel, set 50Hz update, all 3 axes on (ctrl1 register)
  imu.writeReg(imu#acc_adr,imu#ctrl1,%0101_0111) 
     
  'set high resolution mode (note: ctrl1 "low power" bit must be 0 for hi res mode)
  imu.writeReg(imu#acc_adr,imu#ctrl4,%0000_1000) 

  'set magnetometer/compass update rate to 15Hz
  imu.writeReg(imu#mag_adr,imu#ctrlr,%0000_0000)        'set to continuous conversion mode
'  imu.writeReg(imu#mag_adr,imu#ctrla,%0001_0100)        'set update rate
'  imu.writeReg(imu#mag_adr,imu#ctrlm,%0110_0000)        'set sensitivity

  'turn on gyro, set 380Hz update, 20 cutoff?
  imu.writeReg(imu#gyr_adr,imu#ctrl1,%1000_1111) 

  repeat

    'read accelerometer registers & axes
    pst.clear
    pst.str(string("miniIMU9 v2 demo",13))
    pst.str(string("********************************",13))
    pst.str(string("ACEL  ctrl1="))
    pst.bin(imu.readreg(imu#acc_adr,imu#ctrl1),8)
    pst.str(string("    ctrl4="))
    pst.bin(imu.readreg(imu#acc_adr,imu#ctrl4),8)
    pst.newline
    pst.str(string("ax=       ay=       az=       norm=     stat=     ",13))
    x:= imu.readacc(imu#accx1)
    y:= imu.readacc(imu#accy1)
    z:= imu.readacc(imu#accz1)
    pst.PositionX(0)
    pst.dec(x)
    pst.PositionX(10)
    pst.dec(y)
    pst.PositionX(20)
    pst.dec(z)
    pst.PositionX(30)
    pst.dec(norm(x,y,z))
    pst.PositionX(40)
    pst.bin(imu.readreg(imu#acc_adr,imu#astat),8)
    pst.PositionX(50)
    if (||x > 200) or (||y > 200)
      pst.str(string("TILT!"))
    pst.newline

    'read magnetometer registers & axes
    pst.str(string("********************************",13))
    pst.str(string("MAG  ctrla="))
    pst.bin(imu.readreg(imu#mag_adr,imu#ctrla),8)
    pst.str(string("     ctrlm="))
    pst.bin(imu.readreg(imu#mag_adr,imu#ctrlm),8)
    pst.str(string("     ctrlr="))
    pst.bin(imu.readreg(imu#mag_adr,imu#ctrlr),8)
    imu.updatemag
    pst.newline
    pst.str(string("mx=       my=       mz=       stat",13))
    x:= imu.readmx
    y:= imu.readmy
    z:= imu.readmz
    pst.PositionX(0)
    pst.dec(x)
    pst.PositionX(10)
    pst.dec(y)
    pst.PositionX(20)
    pst.dec(z)
    pst.PositionX(30)
    pst.bin(imu.readreg(imu#mag_adr,imu#mstat),8)
    pst.newline

    'read gyro registers & axes
    pst.str(string("********************************",13))
    pst.str(string("GYRO  ctrl1="))
    pst.bin(imu.readreg(imu#gyr_adr,imu#ctrl1),8)
    pst.str(string("    ctrl4="))
    pst.bin(imu.readreg(imu#gyr_adr,imu#ctrl4),8)
    pst.newline
    pst.str(string("gx=       gy=       gz=       stat=     ",13))
    x:= imu.readgyr(imu#accx1)
    y:= imu.readgyr(imu#accy1)
    z:= imu.readgyr(imu#accz1)
    pst.PositionX(0)
    pst.dec(x)
    pst.PositionX(10)
    pst.dec(y)
    pst.PositionX(20)
    pst.dec(z)
    pst.PositionX(30)
    pst.bin(imu.readreg(imu#gyr_adr,imu#astat),8)
   waitcnt(clkfreq/2+cnt)


pub norm(x,y,z)
''compute vector norm of acel outputs

  return ^^(x*x+y*y+z*z)


dat
{{
┌────────────────────────────────────────────────────────────────────────────┐
│                              TERMS OF USE: MIT License                     │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy│ 
│of this software and associated documentation files (the "Software"), to    │
│deal in the Software without restriction, including without limitation the  │
│rights to use, copy, modify, merge, publish, distribute, sublicense, and/or │
│sell copies of the Software, and to permit persons to whom the Software is  │
│furnished to do so, subject to the following conditions:                    │
│The above copyright notice and this permission notice shall be included in  │
│all copies or substantial portions of the Software.                         │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  │
│IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE │
│AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         │
│DEALINGS IN THE SOFTWARE.                                                   │
└────────────────────────────────────────────────────────────────────────────┘
}}