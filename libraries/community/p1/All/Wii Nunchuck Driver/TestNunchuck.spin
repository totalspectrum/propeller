{{
Wii Nunchuck Driver Demo Object v1.0
By Pat Daderko (DogP)

Based on a Wii nunchuck example project from John Abshier, which was based on code originally by João Geada

This demo object repeatedly polls the Wii Nunchuck and writes the data to the serial port (at 115200bps),
reusing the pins used for programming.

Note there is no yaw, as that can't be determined from the accelerometers.  This also limits the pitch
to 180 degrees and will cause incorrect roll readings when the pitch is between 180 deg and 360 deg.

Also note that the Nunchuck can't be constantly read, or bad data will be returned.

See other notes in the driver object.     

Diagram below is showing the pinout looking into the connector (which plugs into the Wii Remote)
 _______ 
| 1 2 3 |
|       |
| 6 5 4 |
|_-----_|

1 - SDA 
2 - 
3 - VCC
4 - SCL 
5 - 
6 - GND

This is an I2C peripheral, and requires a pullup resistor on the SDA line
If using a prop board with an I2C EEPROM, this can be connected directly to pin 28 (SCL) and pin 29 (SDA)
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

OBJ
  Nun : "Nunchuck"
  uart : "Extended_FDSerial"
  
PUB init
   uart.start(31, 30, 0, 115200) 'start UART at 115200 on programming pins
   Nun.init(28,29) 'initialize I2C Nunchuck on existing I2C pins
   mainLoop 'run main app

PUB mainLoop
    repeat
      Nun.readNunchuck 'read data from Nunchuck

      'output data read to serial port
      uart.dec(Nun.joyX)
      uart.tx(44)
      uart.dec(Nun.joyY)
      uart.tx(44)
      uart.dec(Nun.accelX)
      uart.tx(44)
      uart.dec(Nun.accelY)
      uart.tx(44)
      uart.dec(Nun.accelZ)
      uart.tx(44)
      uart.dec(Nun.pitch)
      uart.tx(44)
      uart.dec(Nun.roll)
      uart.tx(44)
      uart.dec(Nun.buttonC)
      uart.tx(44)
      uart.dec(Nun.buttonZ)
      uart.tx(13)            
      waitcnt(clkfreq/64 + cnt) 'wait for a short period (important when using nunchuck, or will return bad data)
