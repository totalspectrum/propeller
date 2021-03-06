{{
────────────────────────────────────────────────────────────────────────────────────────
File: FullDuplexParallel.spin
Version: 1.0
Copyright (c) 2010 Terry E. Trapp, KE4PJW
Copyright (c) 2008 Parallax, Inc.
See end of file for terms of use. 


This is the FullDuplexParallel object v1.0. It is based on the FullDuplexSerial object v1.1
from the Propeller Tool's Library folder with modified documentation and methods for
converting text strings into numeric values in several bases. It interfaces the propeller
with the FTDI UM245 Parallel FIFO. The UM245 allows for high performance I/O to a PC.

────────────────────────────────────────────────────────────────────────────────────────
}}
  
CON                                          ''
''Parallax Serial Terminal Control Character Constants
''────────────────────────────────────────────────────
  HOME     =   1                             ''HOME     =   1          
  CRSRXY   =   2                             ''CRSRXY   =   2          
  CRSRLF   =   3                             ''CRSRLF   =   3          
  CRSRRT   =   4                             ''CRSRRT   =   4          
  CRSRUP   =   5                             ''CRSRUP   =   5          
  CRSRDN   =   6                             ''CRSRDN   =   6          
  BELL     =   7                             ''BELL     =   7          
  BKSP     =   8                             ''BKSP     =   8          
  TAB      =   9                             ''TAB      =   9          
  LF       =   10                            ''LF       =   10         
  CLREOL   =   11                            ''CLREOL   =   11         
  CLRDN    =   12                            ''CLRDN    =   12         
  CR       =   13                            ''CR       =   13         
  CRSRX    =   14                            ''CRSRX    =   14         
  CRSRY    =   15                            ''CRSRY    =   15         
  CLS      =   16                            ''CLS      =   16          


VAR

  long  cog                     'cog flag/id

  long  rx_head                 '10 contiguous longs
  long  rx_tail
  long  tx_head
  long  tx_tail
  long  rxf_pin
  long  rd_pin
  long  txe_pin
  long  wr_pin
  long  data_pin
  long  buffer_ptr
                     
  byte  rx_buffer[256]           'transmit and receive buffers
  byte  tx_buffer[256]  


PUB start(RXFpin, RDpin, TXEpin, WRpin, Dpin) : okay
  {{
  Starts serial driver in a new cog

    RXFpin - RXF# pin on UM245 - Low when data avaliable for read from the FIFO.
    RDpin  - RD# pin on UM245 - Enables the current FIFO data byte on D0...D7 when low. 
    TXEpin - TXE# pin on UM245 - Low when low, data can be written into the FIFO.
    WRpin  - WR pin on UM245 - Writes the data on the D0...D7 pins into the transmit FIFO on transition from high to low.
    Dpin   - D0 pin on UM245 - The 8 data pins should be connected in consecutive pin order on the prop starting with Dpin.
             Example: Dpin = 8
              Prop    UM245                 
              --------------
              P8  <-> D0
              P9  <-> D1
              P10 <-> D2
              P11 <-> D3
              P12 <-> D4
              P13 <-> D5
              P14 <-> D6
              P15 <-> D7
                      
    okay - returns false if no cog is available.
  }}

  stop
  longfill(@rx_head, 0, 4)
  longmove(@rxf_pin, @rxfpin, 4)
  buffer_ptr := @rx_buffer
  okay := cog := cognew(@entry, @rx_head) + 1


PUB stop

  '' Stops serial driver - frees a cog

  if cog
    cogstop(cog~ - 1)
  longfill(@rx_head, 0, 10)


PUB tx(txbyte)

  '' Sends byte (may wait for room in buffer)

  repeat until (tx_tail <> (tx_head + 1) & $FF)
  tx_buffer[tx_head] := txbyte
  tx_head := (tx_head + 1) & $FF
  'rx

PUB rx : rxbyte

  '' Receives byte (may wait for byte)
  '' rxbyte returns $00..$FF

  repeat while (rxbyte := rxcheck) < 0

PUB rxflush

  '' Flush receive buffer

  repeat while rxcheck => 0
    
PUB rxcheck : rxbyte

  '' Check if byte received (never waits)
  '' rxbyte returns -1 if no byte received, $00..$FF if byte

  rxbyte--
  if rx_tail <> rx_head
    rxbyte := rx_buffer[rx_tail]
    rx_tail := (rx_tail + 1) & $FF

PUB rxtime(ms) : rxbyte | t

  '' Wait ms milliseconds for a byte to be received
  '' returns -1 if no byte received, $00..$FF if byte

  t := cnt
  repeat until (rxbyte := rxcheck) => 0 or (cnt - t) / (clkfreq / 1000) > ms

PUB str(stringptr)

  '' Send zero terminated string that starts at the stringptr memory address

  repeat strsize(stringptr)
    tx(byte[stringptr++])

PUB getstr(stringptr) | index
    '' Gets zero terminated string and stores it, starting at the stringptr memory address
    index~
    repeat until ((byte[stringptr][index++] := rx) == 13)
    byte[stringptr][--index]~
PUB rxhead : i
    i := @rx_head

PUB dec(value) | i

'' Prints a decimal number

  if value < 0
    -value
    tx("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      tx(value / i + "0")
      value //= i
      result~~
    elseif result or i == 1
      tx("0")
    i /= 10


PUB GetDec : value | tempstr[11]

    '' Gets decimal character representation of a number from the terminal
    '' Returns the corresponding value

    GetStr(@tempstr)
    value := StrToDec(@tempstr)    

PUB StrToDec(stringptr) : value | char, index, multiply

    '' Converts a zero terminated string representation of a decimal number to a value

    value := index := 0
    repeat until ((char := byte[stringptr][index++]) == 0)
       if char => "0" and char =< "9"
          value := value * 10 + (char - "0")
    if byte[stringptr] == "-"
       value := - value
       
PUB bin(value, digits)

  '' Sends the character representation of a binary number to the terminal.

  value <<= 32 - digits
  repeat digits
    tx((value <-= 1) & 1 + "0")

PUB GetBin : value | tempstr[11]

  '' Gets binary character representation of a number from the terminal
  '' Returns the corresponding value
   
  GetStr(@tempstr)
  value := StrToBin(@tempstr)    
   
PUB StrToBin(stringptr) : value | char, index

  '' Converts a zero terminated string representaton of a binary number to a value
   
  value := index := 0
  repeat until ((char := byte[stringptr][index++]) == 0)
     if char => "0" and char =< "1"
        value := value * 2 + (char - "0")
  if byte[stringptr] == "-"
     value := - value
   
PUB hex(value, digits)

  '' Print a hexadecimal number

  value <<= (8 - digits) << 2
  repeat digits
    tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB GetHex : value | tempstr[11]

    '' Gets hexadecimal character representation of a number from the terminal
    '' Returns the corresponding value

    GetStr(@tempstr)
    value := StrToHex(@tempstr)    

PUB StrToHex(stringptr) : value | char, index

    '' Converts a zero terminated string representaton of a hexadecimal number to a value

    value := index := 0
    repeat until ((char := byte[stringptr][index++]) == 0)
       if (char => "0" and char =< "9")
          value := value * 16 + (char - "0")
       elseif (char => "A" and char =< "F")
          value := value * 16 + (10 + char - "A")
       elseif(char => "a" and char =< "f")   
          value := value * 16 + (10 + char - "a")
    if byte[stringptr] == "-"
       value := - value

DAT

'***********************************
'* Assembly language serial driver *
'***********************************

                        org
'
'
' Entry
'
entry                   mov     t1,par                'get structure address
                        add     t1,#4 << 2            'skip past heads and tails

                        rdlong  t2,t1                 'get rxf_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                 'get rd_pin
                        rdlong  t2,t1
                        mov     rdmask,#1
                        shl     rdmask,t2
                        
                        add     t1,#4                 'get txe_pin
                        rdlong  t2,t1
                        mov     txemask,#1
                        shl     txemask,t2

                        add     t1,#4                 'get wr_pin
                        rdlong  t2,t1
                        mov     wrmask,#1
                        shl     wrmask,t2

                        add     t1,#4                 'get data_pin
                        rdlong  t2,t1
                        mov     datapin, t2
                                                      'get datamask                                
                        mov     datamask,#$FF         'turn 8 LSBits on
                        shl     datamask, t2          'shift byte to proper address on prop pins  

                        add     t1,#4                 'get buffer_ptr
                        rdlong  rxbuff,t1
                        mov     txbuff,rxbuff
                        add     txbuff,#256

                        or      outa,rdmask
                        or      dira,rdmask

                        or      dira,wrmask
                        mov     txcode,#transmit      'initialize ping-pong multitasking
'
'
' Receive
'
receive                 jmpret  rxcode,txcode         'run chunk of tx code, then return

                        test    rxmask,ina      wz     ' Is RXF# low? Set Z flag if it is
        if_nz           jmp     #receive               ' If Z not set, jump to receive label
                        
                        xor     outa, rdmask          ' Set RD# low

                        mov     rxdata, ina           ' Read pins set for input
                        or      outa, rdmask          ' Set RD# high
                        
                        shr     rxdata, datapin       ' Shift data so that the LSB corisponds with D0

                                                      ' Save received byte and inc head
                        rdlong  t2,par                ' Assign the value of rx_head to t2
                        add     t2,rxbuff             ' Increment t2 by the address location of rxbuff
                        wrbyte  rxdata,t2             ' Write byte from the rxdata into the address located at t2's value (rx_head + rxbuff)
                        sub     t2,rxbuff             ' Decrement t2 by the address location of rxbuff
                                                      ' Increment rx_head
                        add     t2,#1                 ' Increment t2 by 1 bit (same as rx_head + 1)
                        and     t2,#$FF               ' Perform AND operation on t2's value with $FF (if > $FF then rollerover)
                        wrlong  t2,par                ' Write long value of t2 in to the address location of par
                        jmp     #receive              ' byte done, receive next byte
'
'
' Transmit
'
transmit                jmpret  txcode,rxcode         'run chunk of rx code, then return

                                                      ' check for head <> tail 
                        mov     t1,par                ' Get address of rx_head assign it to t2
                        add     t1,#2 << 2            ' Increment t1 by 8 bytes. Result is address of tx_head
                        rdlong  t2,t1                 ' Copy value of tx_head into t2
                        add     t1,#1 << 2            ' Increment t1 by 8 bytes. Result is address of tx_tail
                        rdlong  t3,t1                 ' Copy value of tx_tail into t3
                        cmp     t2,t3           wz    ' Compare tx_tail and tx_head
        if_z            jmp     #transmit             ' Jump to transmit when tx_tail == tx_head
                                                      ' get byte and inc tail 
                        add     t3,txbuff             ' add address of txbuff to value of tx_tail
                        rdbyte  txdata,t3             ' Read byte from the tail of the buffer into txdata
                        sub     t3,txbuff             ' Subtract address of txbuff (Result is tx_tail)
                                                      ' Increment tx_tail
                        add     t3,#1                 ' Increment t3 by 1 bit (same as tx_tail + 1) 
                        and     t3,#$FF               ' Perform AND operation on t3's value with $FF (if > $FF then rollerover) 
                        wrlong  t3,t1                 ' Write long value of t3 into address tx_tail


writebyte

                        test    txemask,ina      wz   ' Is RXF# low? Set Z flag if it is                 
        if_nz           jmp     #writebyte            ' If Z not set, jump to receive label
                        
                        muxnz outa, datamask          ' Set all I/O pins low         
                        or    outa, txdata            ' Write byte to Parallel FIFO
                        or    dira, datamask          ' Set parallel I/O pins for output
                        shl txdata, datapin           ' Shift data so that the LSB corisponds with D0
                        or    outa, wrmask            ' Set WR high    
                        muxnz outa, wrmask            ' Set WR low
                        muxnz dira, datamask          ' Set parallel I/O pins for input

                        jmp     #transmit             ' byte done, transmit next byte
'
'
' Uninitialized data
'
t1                      res     1
t2                      res     1
t3                      res     1

datamask                res     1
datapin                 res     1

rxmask                  res     1
rdmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1


txemask                 res     1
wrmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

{{
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}