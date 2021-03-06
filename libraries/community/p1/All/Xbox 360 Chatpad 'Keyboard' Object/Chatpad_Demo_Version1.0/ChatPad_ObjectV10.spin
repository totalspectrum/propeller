''************************************
''*    ChatPad Object Version 1.0    *
''************************************

''*  This object is an extension of the full-duplex serial object.
''*  The Xbox 360 ChatPad requires an initialization command sent at 19.2Kbaud.
''*  After initialization, the Propeller must keep the ChatPad "awake"
''*  by periodically (every few seconds) sending the ChatPad a 5-byte message.
''*  The ChatPad (when awake) will transmit every 70mS or so an 8-byte status
''*  message. When an operator presses one of the ChatPad keys it will send
''*  a different 8-byte message (distinguished by its 2-byte header) that
''*  contains that key's keycode.The keycodes are extracted by the object,
''*  and used to identify the equivalent ascii character. Only the decoded
''*  ascii characters are placed in the receive buffer and made available via
''*  the rx() method. The repetitive 70mS-period status messages are simply
''*  discarded. As this object will automatically send to the ChatPad the
''*  periodic "stay awake" messages, and provides only ascii characters to
''*  the output circular rx_buffer, the underlying complexity of the ChatPad
''*  interface is hidden. The ChatPad object from the programmer's perspective
''*  appears as a receive-only device !

''*  Object functions:
''*
''*  1) Init() spin code called internally by Start() will send the 'initialization'
''*     message to the ChatPad repeatedly (if necessary) until the expected 12-byte
''*     response is detected.
''*  2) Cog code, every few seconds, will send a 5-byte "stay awake" message
''*     to the ChatPad.
''*  3) Cog code will analysis the received serial data from the ChatPad, looking
''*     for the 'keycode' message which begins with "B4 C5". Once detected,
''*     keycode info must be extracted, and the correct replacement ascii character
''*     determined. Only this character will be added to the publicly accessible
''*     rx_buffer().
     
{ '==============================================================================

       To:ChatRxPin               From: ChatTxPin
                                                 ┌──── Tested with separate 3.3v regulator
            Chat                            Chat   
        Gnd  Tx       Audio Plug             Rx   +3v
       ‣‣       -shield      ‣‣   
                           -ring(spk?)
                             -tip (mic?)

  Internal to the ChatPad, the 7 electrical connections above are routed to the
  PCB board via a 7-pin connector:

      pin 1 : shield
      pin 2 : ring   (speaker ~250 ohms)
      pin 3 : tip    (microphone) 
      pin 4 : pwr gnd
      pin 5 : chatTx  ( to ChatRxPin @ Propeller)
      pin 6 : chatRx  ( from ChatTxPin @ Propeller)
      pin 7 : pwr +3.3v

  NOTE:  Please confirm speaker & microphone connections.
         I have not yet experimented with them, so proceed with caution.

'==================================================================================
    
}
 
'' RX:

' SPIN code (method: rx) is used to retrieve incoming data
' from the rx_tail index position of the rx_buffer() provided
' there is data to retrieve (rx_tail <> rx_head). If data
' is present in buffer, the rx_tail index is afterwards advanced
' toward the rx_head index value.

' ASSEM code running in a separate COG will always add newly
' received data bytes to the rx_head index position of rx_buffer().
' It is the programmer's responsibility to fetch newly received
' characters in a timely manner using SPIN code methods, rx or rxtime.
' The rx_head index value will be advanced following the addition of
' a new data byte, pointing to the next available buffer location. 

''
''   Byte-Out      Serial-In
''      ^             |
''      |             v
''    SPIN (rx)     ASSEM
''      ^             |
''      |             v
'' (  rx_tail+ --> rx_head+  )        :=  RX_BUFFER()
''[tail chases head in endless loop]
''

''TX:

' Tests have successfully transmitted upto 115200 baud.

' SPIN code (method: tx) is used to write a new data byte
' to the tx_head index position of the tx_buffer(). If this
' write would cause the NEXT tx_head index to equal the
' current tx_tail index value the write operation will be
' delayed until the data byte at the tx_tail position has
' been serially transmitted.

' It is possible at low baud rates to call the tx method from
' SPIN code at a rate faster than the ASSEM transmit code is
' transmitting its data bytes. The tx_buffer() will fill up
' and the SPIN method, tx, will be forced to wait for an available
' slot within the tx_buffer() to place its data byte cargo.
' Note that SPIN instructions following the .tx method call will not
' be executed during this wait. SPIN code execution could be slowed
' to a rate limited by the rate at which data is being serially transmitted.
' The programmer is advised to be aware of the time required to transmit
' a byte at the selected baud rate and to proportionately adjust the
' frequency at which characters are being feed to the tx method.
 
' ASSEM code running in a separate COG will transmit the
' data byte located at the tx_tail index position of the tx_buffer()
' provided tx_tail <> tx_head (there is actually data in buffer to send).

''
''    Serial-Out    Byte-In
''      ^             |
''      |             v
''    ASSEM          SPIN (tx)
''      ^             |
''      |             v
'' (  tx_tail+ --->  tx_head+ )       :=  TX_BUFFER()
''[tail chases head in endless loop]
''
                        
' Note: the open drain/source configuration may be of value
' when more than one device must share a common serial transmit
' line.   

CON

  BufferSize = 256   'Legal values:  16, 32, 64, 128, 256
  TermChar  = 13     'Carriage Return

 'The following pins were useful during development
 'They have been commented out as these pin #s are used for X-Y PSD reads
 ' TestPin2 = 2           
 ' TestPin3 = 3
 ' TestPin4 = 4
 ' TestPin5 = 5
 ' TestPin6 = 6
 ' TestPin7 = 7
  
VAR

  long  cog                     'cog flag/id


  '========= START OF COG PARAMETER LIST ===========
  
                                
  long  rx_head                 
  long  rx_tail
  long  tx_head
  long  tx_tail

  long  rx_pin
  long  tx_pin
  long  rxtx_mode

  long  bit_ticks
  
  long  buffer_ptr0             'pre-load with pointer to rx_buffer[] buffer before calling cognew() !!
 
  long  obj_addr 'Pre-load with "@@0," the address at which this object starts.
                 'The object start address will be added to all hub location
                 'addresses identified with a "@" prefix to obtain their true
                 'run-time memory locations. "@abc" refers only to the offset
                 'from the start of the object to variable "abc" when treated
                 'as a constant (not as part of an expression at run-time).
  

 '=========== END OF COG PARAMETER LIST =============
  
 'note that variables in VAR block are sorted by object compiler by type !!
 'longs are placed first in memory, followed by words, then bytes.
 'if lists are being copied from hub to cog, and the cog expects variables
 'to be in a certain order, be careful that variable types are not mixed
 'within this list !!
  
  byte  rx_buffer[BufferSize]   'transmit and receive buffers
  byte  tx_buffer[BufferSize]  

  byte  stringsize              'added by GP
  
 '@@@@@@@@@@@@@@@ CHAT PAD SPECIFIC VARIABLES @@@@@@@@@@@@@@@@@@@@

  Byte c_byte
 
  Long chatcnt
  Long LastAwakeTime
  Long AwakePeriod
  Long ChatRecCnt

  Long SpChar
  Long KeyChar
  Long LastChar
    
  Long HighNib
  Long LowNib
  Long KeyIndex

CON  'Parallax Serial Terminal Constants
''
''     Parallax Serial Terminal
''    Control Character Constants
''─────────────────────────────────────
  CS = 16  ''CS: Clear Screen      
  CE = 11  ''CE: Clear to End of line     
  CB = 12  ''CB: Clear lines Below 

  HM =  1  ''HM: HoMe cursor       
  PC =  2  ''PC: Position Cursor in x,y          
  PX = 14  ''PX: Position cursor in X         
  PY = 15  ''PY: Position cursor in Y         

  NL = 13  ''NL: New Line        
  LF = 10  ''LF: Line Feed       
  ML =  3  ''ML: Move cursor Left          
  MR =  4  ''MR: Move cursor Right         
  MU =  5  ''MU: Move cursor Up          
  MD =  6  ''MD: Move cursor Down
  TB =  9  ''TB: TaB          
  BS =  8  ''BS: BackSpace          
           
  BP =  7  ''BP: BeeP speaker  

     
DAT 'ChatPad Messages & Keycode Maps 

InitMessage  byte $87,$02,$8C,$1F,$CC,0
AwakeMessage byte $87,$02,$8C,$1B, $D0, 0

KeyMap_Def    byte "7654321uytrewqjhgfdsanbvcxz^",MR,"m. ",ML,"ΩΣπ,",NL,"p098",BS,"l++oik",0
KeyMap_Caps   byte "7654321UYTREWQJHGFDSANBVCXZ^",MR,"M. ",ML,"ΩΣπ,",NL,"P098",BS,"L++OIK",0
KeyMap_Green  byte "7654321&^%#Ê@!'/÷}{s~<|_><`^",MR,">? ",ML,"ΩΣπ:",NL,")098",BS,"]++(*[",0
KeyMap_Orange byte "7654321úýÞ$éåì",$22,"\g£ðßáñ+-çÆæ^",MR,"µ¿ ",ML,"ΩΣπ;",NL,"=098",BS,"ø++óí",0
 
   
PUB start(rxpin, txpin) : okay | baudrate

'' Start serial driver - starts a cog
'' returns false if no cog available
''
'' mode bit 0 = invert rx
'' mode bit 1 = invert tx
'' mode bit 2 = open-drain/source tx
'' mode bit 3 = ignore tx echo on rx

'NOTE:  The meaning of 'inverted' requires explanation. The 'non-inverted' mode
'       of operation (bit0 or bit1 cleared) actually requires the use of an external
'       polarity-inverting RS232 converter chip !

'       'Invert' best describes the polarity at the the Propeller pin of the data
'       bit's logic. If byte=01H were transmitted, for example, its non-inverted bit0
'       logic level would be HIGH (1). If mode bit1 (invert tx) = 0 (FALSE), then the
'       bit0 logic level at the propeller's tx_pin would also be HIGH (1). The external
'       RS232 converter chip performs a final polarity inversion, generating a
'       negative-voltage output during bit0's bit interval corresponding to an
'       RS232 'LOGIC 1' state.

  stop  'spin method call

  'dira[TestPin7]~~  'TEST ONLY: Set TestPin to Output
   
  longfill(@rx_head, 0, 4)     'zero pointers to both rx & tx buffers heads & tails
                               'this assures rx_head = rx_tail, and tx_head = tx_tail
                               'a condition corresponding to buffers 'empty'
  
 'longmove(@rx_pin, @rxpin, 3) 'copy 1st three start() parameters
  rx_pin := rxpin  'parameter #1
  tx_pin := txpin  'parameter #2
  rxtx_mode := 0   'specify tx/rx pin mode
  baudrate := 19200  'default ChatPad baudrate
  
  bit_ticks := clkfreq / baudrate   'calculate clock cycles per serial bit interval

  buffer_ptr0 := @rx_buffer   'save rx_buffer address to buffer_ptr0 for reference by cog.
 
  'Note: par = rx_head within assembly routine
  '      cog = ID# of cog started + 1
  '      okay = return value for start() routine,
  '      cognew return -1 if no cog available, so after +1, cog =0 (FALSE), okay = FALSE

  obj_addr := @@0  'pre-load this hub variable with this object's start address
                   'this start-address is added to all @variable references within cog code
                   'to obtain their true run-time memory locations.
  okay := cog := cognew(@entry, @rx_head) + 1

  Init   'sends initialization messsage to ChatPad
         'AwakeCheck() must be called with 4 seconds of Init() to keep ChatPad awake !!
         
PUB stop

'' Stop serial driver - frees a cog

  if cog                    'TRUE = non-zero
    cogstop(cog~ - 1)       'stop cog with ID# 'cog-1', then post-clear cog to zero (FALSE)
    
  longfill(@rx_head, 0, 9)  'write 9 longs with zero value, starting at hub location rx_head.


PUB Init

  'Send initialization message to ChatPad until it responds !!
  '=========================================================
    repeat
       'quit
       str(@InitMessage)
       chatcnt :=0
       repeat
         if ((rxtime(1000)) => 0)    'returns -1 if no byte received in 1000 mS
            chatcnt := chatcnt + 1
            if chatcnt == 12
              quit 'EXPECTED REPLY LENGTH DETECTED !
         else  
            quit 'TIMEOUT - NO BYTE RECEIVED AFTER 1 SECOND ! 
       if chatcnt == 12
          quit

    tx("I")  'this byte (which is not in the InitMessage above) will be detected by the
             'serial transmit code within the cog and used to switch the chat_awake_state to "1"
             'indicating to the cog that receive data from the Chatpad should not be filtered.
             'Filtering identifies all 8-byte 'keycode' messages from the Chatpad and extracts from
             'them data bytes used to determine the specific keyboard characters selected.
    
    AwakePeriod := 160_000_000  'every two seconds !
    LastAwakeTime := cnt  'now

    ChatRecCnt := 0  'initially
    LastChar := 0


PUB rxcheck : rxbyte

'' Check if byte received (never waits)
'' returns -1 if no byte received, else $00..$FF if byte received

  rxbyte--                          'post decrement to -1 default "empty buffer" response
  if rx_tail <> rx_head             'if rx_buffer is not empty, then
    rxbyte := rx_buffer[rx_tail]    '  fetch byte from rx_tail index position of buffer
    rx_tail := (rx_tail + 1) & Constant(BufferSize-1) '$100-1=$FF
             '  advance rx_tail index value, rolling over if necessary


PUB rxtime(ms) : rxbyte | t

'' Wait ms milliseconds for a byte to be received
'' returns -1 if no byte received, $00..$FF if byte

 'CNT is SIGNED. The (CNT - t) result (see instruction below) is almost always positive.
 'CNT always advances from NEGX(-2,127,483,649) to POSX (+2,127,483,647) rolling
 'over at POSX back to NEGX (&H7FFFFFFF(POSX) + 1  -> &H80000000(NEGX)).

 'Consider the case in which POSX is incremented by 1 to NEGX,
 'Let's determine the difference:  NEGX - POSX  = ?

 ' NEGX :  &80 00 00 00
 '-POSX : -&7F FF FF FF
 '======================
 '  ?

 'Subtraction would require taking the 2's complement of POSX and adding it
 'to NEGX. The 2s complement is formed by first inverting each bit of a
 '32-bit value then adding one.

 'So,  2sComp(POSX)  = &80 00 00 01

 'Adding to NEGX yields:  &1 00 00 00 01. Discard bit-32 (overflow bit) and
 'you have a positive 1 as our result, the difference of NEGX-POSX at CNT rollover.
 'SO, for small differences between CNT values, the result is always positive.

 'So what happens if we wait so long that CNT is allowed to return to a positive
 'value before the expression (CNT - t) is first evaluated ? What will be the
 'sign of this difference ?

 ' '1' :  &00 00 00 01    'example value of CNT approximately 26.6 seconds after t:=cnt statement.
 '-POSX: -&7F FF FF FF    'value of CNT written to variable 't' when CNT = POSX 
 '=====================
 '  ?  :  &80 00 00 02    'equivalent to NEGX+2 : -2,127,483,647
 
 'This shows that the expression (CNT-t), if evaluated more infrequently than every
 '26.6 seconds, may return a negative difference result. It is important to be aware
 'of this 'loophole' and code appropriately.
  
 '------------------------------
  
 'capture start time in 't'
 'wait until TRUE:  char received OR time 'ms' (in milliseconds) has elapsed
 ' 
  t := cnt
  repeat until (rxbyte := rxcheck) => 0 or (cnt - t) / (clkfreq / 1000) > ms
    
PUB rx : rxbyte

'' Receive byte (will wait indefinitely for a received byte !)
'' returns $00..$FF

'return only after a character has been received
  repeat while (rxbyte := rxcheck) < 0


PUB tx(txbyte)

''Send byte (may wait for room in buffer)
 
 'Wait until the tx_head index (when advanced) will not equal the current tx_tail index value.
 'That will prevent data that has not yet been transmitted by the COG from being overwritten
 'by new data.

 'The COG continually grabs a data byte at the tx_buffer's tx_tail index location,
 'serially transmits this byte, then increments the tx_tail pointer value, PROVIDED the
 ' tx_tail index <> tx_head index value, i.e., provided there is something to transmit.
 
 'Bitwise And (&) has higher precedence than "Not Equal" operation
 'So if tx_head = 255, tx_head+1 = 256 ($100), after AND with &FF rolls over to $00
 '--------------------------------------------------------------------------------
 'The 'repeat' code below prevents the writing of a new byte of data to the
 'tx_head position if, following the write, the incremented tx_head pointer
 'would point to the yet-to-be-transmitted data at the current tx_tail position.
 'In effect, if the tx_head pointer has "caught up with" the tx_tail pointer,
 'we must wait for the tx_tail pointer to be advanced ahead of us by the cog as it
 'transmits more serial data, opening up room for us within the buffer to write
 'the new data to be transmitted (and to further advance the tx_head pointer).
 '-------------------------------------------------------------------------------- 
  repeat until (tx_tail <> (tx_head + 1) & Constant(BufferSize-1))  '$100-1 = $FF
  
  tx_buffer[tx_head] := txbyte    'NEW DATA TO TRANSMIT WRITTEN TO TX_HEAD POSITION
  
  tx_head := (tx_head + 1) & Constant(BufferSize-1)  '$100-1 = $FF

 'Waits at most 40 mS (if echo mode enabled) for a received char reply (echo).
 'At 300 baud, allowing 11 bits per byte, about 36.7 mS of transmission time
 'is required per character.  
  if rxtx_mode & %1000
     rxtime(1)


PUB str(stringptr)

'' Send string                    
   
  repeat strsize(stringptr)   'NOTE: strsize() counts bytes to the 1st null character.
    tx(byte[stringptr++])    

   
DAT 'Cog Entry

'***********************************
'* Assembly language serial driver *
'***********************************

                        org
' Entry
'
' Note: PAR holds the address of rx_head, a variable in hub memory.
'       It was assigned by the COGNEW spin instruction within the Start method
'       The entry portion of this assembly language program accesses
'       a string of consecutive long variables, beginning at the hub location, rx_head.
 
'       par             = rx_head
'       par + 1         = rx_tail
'       par + 2         = tx_head
'       par + 3         = tx_tail

'       par + 4         = rx_pin
'       par + 5         = tx_pin
'       par + 6         = rxtx_mode

'       par + 7         = bit_ticks


' The  "<<2" portion multiplies "#4" by 4 (the number of bytes per long-type variable).

entry                   mov     t1,par         'get hub address of parameter list
                        add     t1,#4 << 2     'skip past heads and tails variable addresses ...
                                               '(ADVANCE 4 LONGS)
                                                      
                        rdlong  t2,t1          'get rx_pin data value (HUB INSTRUCTION: 7 to 22 cycles)
                        mov     rxmask,#1
                        shl     rxmask,t2      'rxmask: only set bit corresponds to rx_pin# position 

                        add     t1,#4          'get tx_pin address (ADVANCE 1 LONG)
                        rdlong  t2,t1          'get tx_pin data value (HUB INSTRUCTION)
                        mov     txmask,#1      
                        shl     txmask,t2      'txmask: only set bit corresponds to tx_pin# position 

                        add     t1,#4          'get rxtx_mode address (ADVANCE 1 LONG)
                        rdlong  rxtxmode,t1    'get rxtx_mode data value

                        add     t1,#4          'get bit_ticks address  (ADVANCE 1 LONG)
                        rdlong  bitticks,t1    'get bit_ticks data value

                        add     t1,#4          'get address of HUB rx_buffer() from HUB buffer_ptr0 variable
                        rdlong  rxbuff,t1      'save address data to COG ram variable, rxbuff
                        
                        mov     txbuff,rxbuff
                        add     txbuff,#BufferSize   'Add 32 bytes to rxbuff addr -> to get tx_buffer start addr.
                                                     'NOTE: these are BYTE arrays.


                       'THEORY:  Pass cog the object start address (@@0), then have the cog
                       '         add this value to each of its pre-initialized hub address pointers.
                       '         These hub address pointers (identified with the "@" prefix) are actually
                       '         just offsets from the object's start address at compile time. By adding
                       '         the object start address, their true run-time hub memory location
                       '         is determined.
                        
                        add     t1, #4   'get hub address to obj_addr variable
                        rdlong  t2, t1   'rdlong returns in t2 the pre-loaded obj start addr "@@0"
                        
                       'pInitMessage   Long  @InitMessage
                       'pAwakeMessage  Long  @AwakeMessage
                       'pKeyMap_Def    Long  @KeyMap_Def
                       'pKeyMap_Caps   Long  @KeyMap_Caps
                       'pKeyMap_Green  Long  @KeyMap_Green
                       'pKeyMap_Orange Long  @KeyMap_Orange

                        add    pInitMessage,  t2  'run-time addr == offset-addr + obj-address
                        add    pAwakeMessage, t2
                        add    pKeyMap_Def,   t2
                        add    pKeyMap_Caps,  t2
                        add    pKeyMap_Green, t2
                        add    pKeyMap_Orange,t2

                        mov    chat_awake_state, #0     'initialization required if == 0
                        mov    cChatRecCnt, #0          'zero
                        mov    cKeyChar, #0             'zero 

                        mov    awake_cnt, cnt      
                        add    awake_cnt, two_seconds   'send 1st awake message in 2 seconds !
                                                        'this allows time for initialization
                                                        
'SERIAL MODE CONTROL                                             
' mode bit 0 = invert rx
' mode bit 1 = invert tx
' mode bit 2 = open-drain/source tx
' mode bit 3 = ignore tx echo on rx

                        test    rxtxmode,#%100  wz    'Z=1, for zero result of AND operation
                        test    rxtxmode,#%010  wc    'C=1, for odd# of high(1) bits in AND result.

' Z = NOT-OPEN
' z=1 (zero result of AND operation), if bit2(open-drain enabled)= 0 (FALSE).

' C = INVERTED
' c=1 if bit1 (invert tx) = TRUE, the AND result: 010 would have an odd # of high bits.

' if_Z_ne_C is TRUE, either:  (z=0,c=1) OR  (z=1,c=0) is TRUE,
' and the default output level of the 'tx_pin' pin is HIGH (regardless of whether the pin
' is initially defined to be an input or output type ).

' The conditional "if_Z_ne_C" effects the outa OR operation, which determines
' the High/Low default state of the tx_pin WHEN IT'S USED AS AN OUTPUT. For the
' non-open-drain/source case (z=1), the tx_pin is always in the output state.
' For the open-drain/source case (z=0), the tx_pin is only placed in the output state
' when a polarity opposite to that achieved by the pin's pullup/pulldown resistor
' is required.

' (z=1,c=0): non-open, non-inverted --> tx_pin off (or mark) state HIGH (data logic '1')
' (z=1,c=1): non-open, inverted     --> tx_pin off (or mark) state is LOW

' (z=0,c=1): open-source, inverted  --> data LOW polarity is HIGH 
'              --> when data LOW:       -> output state: actively driven HIGH  
'              --> when data HIGH:      -> input state : pulldown R to LOW 
' (z-0,c=0): open-drain, non-inverted --> data LOW polarity is LOW )
'              --> when data LOW:       -> output state: actively driven LOW             
'              --> when data HIGH:      -> input state : pullup R to HIGH
  
' At startup the outa register = all-zero, so by default all output signal levels are LOW.
' For open-source/drain case, the 'data LOW' state is achieved by setting the pin to be an output.
' Whatever level (HIGH or LOW) that was written to the OUTA register during startup will
' be made available at the tx_pin when its becomes an output. This is determined by whether
' the tx_pin was defined as 'inverted' or 'non-inverted.' If 'inverted', a 'data LOW' state
' will cause an output HIGH level at the tx_pin. An external pullup or pulldown resistor
' determines the polarity of the tx_pin signal when the 'data HIGH' state is specified as
' the tx_pin is configured as an input (Hi-Z) at this time.

' Note an RS232 chip is assumed to invert the 'non-inverted' HIGH logic level to a negative
' voltage (the mark state polarity for RS232 signalling)

        if_z_ne_c       or      outa,txmask  'if not-open & not-inverted, set tx_pin default HIGH.
                                             'if open & inverted, set 'data LOW' output default HIGH. 
        if_z            or      dira,txmask  'if NOT open-drain, make tx_pin an output
 
                        mov     txcode,#transmit 'initialize ping-pong multitasking

                        jmp     #receive_low
'
'----------------------------------------------------
DAT 'Receive
'----------------------------------------------------
                                                       
'------------------------------------------------------------------
'NEW: TEST FOR MARK (NO-SIGNAL) STATE IF STOP-BIT WAS NOT DETECTED

receive_high            jmpret  rxcode,txcode         'run a chunk of transmit code, then return
                                                      'txcode is the 'GOTO' address
                                                      'rxcode is loaded with PC+1, return address.     

                        'or      outa, TestMask5  'TEST ONLY: HIGH WHILE RX CODE
         
                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                                                      'bit 0 = rx invert, if set -> z=0,
                                                      'if cleared (not inverted) -> z=1
                                                      
                        test    rxmask,ina      wc    'c=1 if odd# of high(1) bits in result.
                                                      'rxmask has a single bit set, if ina's
                                                      'corresponding bit is also set (rx_pin),
                                                      'the AND result will yield a value with
                                                      'a single bit set. That's an odd # of bits so,
                                                      'c=1 if rx_pin=1
                                                      
        if_z_ne_c      jmp     #receive_high         'If not inverted (z=1), mark state = HIGH
                                                      'If z=1 (non-inverted mode) and c=0 (rx_pin=LOW(non-mark)),
                                                      '   then retest rx_pin until mark state (after tx code detour).
                                                      'If z=0 (inverted mode) and c=1 (rx_pin=HIGH(non-mark)),
                                                      '   then retest rx_pin until mark state (after tx code detour)  
                                                      'ELSE execute some transmit code before
                                                      '     retesting for start bit's leading edge

'-------------------------------------------------------------------
'TEST FOR LEADING EDGE OF START-BIT AT RECEIVE PIN
'AFTER EACH FAILURE TO DETECT START-BIT SWITCH TO TX CODE

receive_low             jmpret  rxcode,txcode  'run a chunk of transmit code, then return here
                                               'txcode is the 'GOTO' address
                                               'rxcode is auto-loaded with PC+1, the ret addr.     

                        'or      outa, TestMask5  'TEST ONLY: HIGH WHILE RX CODE
         
                        test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                                                      'bit 0 = rx-invert, if set -> z=0,
                                                      'if cleared (not inverted) -> z=1
                                                      
                        test    rxmask,ina      wc    'c=1 if odd# of high(1) bits in result.
                                                      'rxmask has a single bit set, if ina's
                                                      'corresponding bit is also set (rx_pin),
                                                      'the AND result will yield a value with
                                                      'a single bit set. That's an odd# so,
                                                      'c=1 if rx_pin=1
                                                      
        if_z_eq_c       jmp     #receive_low  'If not inverted mode (z=1), mark state = HIGH
                                              'If z=1 (non-inverted mode) and c=1 (rx_pin = HIGH(mark)),
                                              '   then retest rx_pin again until start-state detected
                                              '   (after tx code detour)
                                              'If z=0 (inverted mode) and c=0 (rx_pin = LOW(mark)),
                                              '   then retest rx_pin again until start-state detected
                                              '   (after tx code detour).  
                                              'ELSE rx_pin = 'START' polarity so prepare to
                                              '   handle incoming stream of data bits .....


'-----------------------------------------------------------------------------                                                      
'********  THE LEADING EDGE OF THE START BIT HAS BEEN DETECTED !!! ***********

           mov     rxcnt,cnt             'Capture sys counter value
          
           mov     bitticks_half,bitticks
           shr     bitticks_half,#1      'divide by two for half-a-bit duration                          

           add     rxcnt,bitticks_half   'Add an initial offset in time equal
                                         'to half-a-bit: from start-bit leading edge
                                         'to center-of-start-bit.              

           sub     rxcnt, #200           'correct for late data bit sampling time
                                         'at highest baud rate (115.2k)
           
           mov     rxbits,#9             'ready to receive byte

           '---------- ORIGINAL CODE ----------                             
           'mov     rxbits,#9             'ready to receive byte
           'mov     rxcnt,bitticks
           'shr     rxcnt,#1              'divide by two for half-a-bit duration                          
           'add     rxcnt,cnt             'Add an initial offset in time equal
                                         'to half-a-bit: from start-bit leading edge
                                         'to center-of-start-bit.              

         '############# TEST ONLY !!!  ##############
       
           'or      outa, TestMask2   'Set TestPin2 HIGH  -debug only
           'andn    outa, TestMask3   'Set TestPin3 LOW   -always reset following new start bit detect

           'andn    outa, TestMask4   'RX PIN - SAMPLED DATA
                                     ' - SET LOW AFTER START BIT DETECT
                    
         '###########################################

'-----------------------------
' CALC NEXT CENTER-OF-BIT TIME

:bit                    add     rxcnt,bitticks  'Advance time-target to a full bit period
                                                'NOTE: a half-bit interval was initially
                                                'added from the leading edge of start-bit
                                                'so the first rx_pin data sampling will occur
                                                'halfway thru bit-0 (1.5 bits from leading
                                                'edge of start bit).
                                                      
'----------------------------------------------------------------
'TEST FOR CENTER-OF-BIT TIME

:wait                   jmpret  rxcode,txcode  'run a chuck of transmit code, then return
                                               'txcode holds 'GOTO' address
                                               'rxcode auto-loaded with PC+1, the ret addr

                        'or      outa, TestMask5  'TEST ONLY: HIGH WHILE RX CODE
         
                        mov     t1,rxcnt       'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0    wc    'C=1, if t1 <= #0  (t1 = rxcnt - cnt)
                                               'So, cnt >= rxcnt causes t1 <=0, and C=1
        if_nc           jmp     #:wait

'----------------------------------------------------------------
'READ RX_PIN INPUT

                        
                        test    rxmask,ina      wc    'Receive bit on rx pin
                                                      'C=1, if AND result has odd # of bits
                                                      'Since rxmask has only 1 bit set, if
                                                      'corresponding bit of INA is set, AND
                                                      'result will have 1 bit set (odd) and C=1
                                                      'In summary: C = rx_pin input
                                                      
                        rcr     rxdata,#1             'C-> rxdata
                                                      'By stuffing the received bits into the
                                                      'highest bit of rxdata, the correct bit
                                                      'order is restored. This is because bit 0
                                                      'is received first in a serial packet                                                       'to 

                '#########   TEST ONLY !! #############
                        'andn    outa, TestMask2   'Set TestPin LOW  - debug only
                   
                        'test    rxbits, #1      wz     'z=1, if bit0 of rxbits ==0 (even)
                 'if_nz  or      outa, TestMask3        'if odd cnt, set pin3 = high
                 'if_z   andn    outa, TestMask3        'if even cnt, set pin3 = low 

                 'if_c   or      outa, TestMask4        'if rx_pin =1, set pin4 = high
                 'if_nc  andn    outa, TestMask4        'if even cnt, set pin4 = low 


                '######################################
                                                      
                        djnz    rxbits,#:bit          '9 BITS SAMPLED YET ?

'----------------------------------------------------------------
'PROCESS RECEIVED BYTE

                        shr     rxdata,#32-9  'justify and trim received byte
                                              'shift right remaining bits until bit 0
                                              'of rxdata holds bit 0 of received byte

                        'NOTE:  b7-b0 will hold data, b8 will hold stop-bit
                                                                              
                        and     rxdata,#$1FF          'zero all but lower 9-bits
                                      
                        test    rxtxmode,#%001  wz    'if rx inverted, invert byte
                                                      'Z=1 if bit0=0 (data not inverted)
        if_nz           xor     rxdata,#$1FF          'if Z=0(data inverted),
                                                      '  INVERT DATA BITS & STOP BIT

'--------------------------------------------------------------------------------
'NEW: TEST FOR CORRECT STOP-BIT POLARITY 

'   If stop-bit (bit 8 of rxdata) polarity is not high,
'   then don't write rxdata to the rx_buffer() !!  It is likely corrupt.
'   Note, if inverted mode was selected, rxdata was just bitwise inverted,
'   so the "bit-8 equals HIGH" polarity test would also be valid for this mode.

                        test   rxdata, #$100  wz      'z=1 if bit8=0 (stop-bit not high)
        if_z            jmp    #receive_high          'skip buffer write if stop-bit not high
                                                      'NOTE: Since STOP-BIT is not HIGH we will
                                                      'branch to 'receive_high' and loop until
                                                      'rx_pin=HIGH(mark state) BEFORE testing for
                                                      'next start-bit leading edge (rx_pin=LOW)


'--------------------------------------------------------------------------------
DAT 'CHAT PAD FILTER

'   Newly received byte from ChatPad is stored in variable 'rxdata'. If chat_awake_state =1,
'   the leading byte of the 8-byte 'keycode' message from the Chatpad must be identified.
'   This byte is $B4. Then the 4th byte (SpChar) and 5th message bytes (KeyChar) must be extracted.
'   From KeyChar, its high & low nibble are used to form an index into a KeyMap character
'   lookup table in hub memory. The SpChar value is used to select the appropriate KeyMap
'   lookup table.

                        cmp  chat_awake_state, #0   wz   'z=1 if chat_awake_state == 0     
         if_z           jmp  #Write_Byte_To_Rx_Buf   'don't filter received chat data if ChatPad uninitialized

                        mov  cTestByte, rxdata    'Stop bit test above ensures rxdata > $FF at entry

                       'rxdata will always have bit-8 set high (stop bit)
                       'RxBufWriteTest below will only allow  rxdata values <= $FF to be forwarded
                       'to the rx_buffer.
                       
                        and  cTestByte, #$FF      'Preserve only low 8 bits for data processing below

                        cmp  cTestByte, #$B4  wz  'z=1 if rxdata == $B4 (lead byte of message)
         if_z           mov  cChatRecCnt, #8      'load counter with # of bytes to process     

                        cmps  cChatRecCnt, #0 wc  'c=1 if cChatRecCnt =< #0 (c=0 if > 0)
         if_c           jmp   #receive_low        'wait to receive next byte ....
                                                  '   all bytes in message have already been processed               

                        cmp   cChatRecCnt, #5 wz  'z=1 if cChatRecCnt == 5
         if_z           mov   cSpChar, cTestByte

                        cmp   cChatRecCnt, #4 wz  'z=1 if cChatRecCnt == 4
         if_nz          jmp   #:ChatRecCntDown    'ignore remaining bytes of message ...

'--------------- Process KeyCode -----------------                                       

                       'Preserve last char value 
                        mov  cLastChar, cKeyChar  'store previous KeyChar value first (initialized to 0)
                        mov  cKeyChar, cTestByte  'then overwrite with newly received KeyChar value

                       'Reject repeats of same key value
                        cmp  cKeyChar, cLastChar wz  'z=1 if cKeyChar==cLastChar
         if_z           jmp  #:ChatRecCntDown     'repeated char, so we will NOT write this byte to rx_buffer               

                       'Reject KeyChar == 0
                        cmp  cKeyChar, #0  wz     'z=1 if cKeyChar==0
         if_z           jmp  #:ChatRecCntDown     'current KeyChar ==0, so reject, do NOT write to rx_buffer

                       'To be here: cKeyChar<>0 & cKeyChar<>cLastChar    
                       '---------------------------------------------
                        mov  cHighNib, cTestByte
                        shr  cHighNib, #4
                        
                        mov  cLowNib, cTestByte
                        and  cLowNib, #$F

                       'KeyIndex := 7*(HighNib-1) + LowNib - 1   
                        mov  cKeyIndex, cHighNib
                        shl  cKeyIndex, #3         '8*HighNib
                        sub  cKeyIndex, cHighNib   '8*HighNib - HighNib = 7*HighNib
                        add  cKeyIndex, cLowNib    '7*HighNib + LowNib
                        sub  cKeyIndex, #8         '7*HighNib -7 + LowNib -1  
                                                   'KeyIndex = 7*(HighNib - 1) + LowNib - 1

                       'Select appropriate keymap table
                        mov  message_addr, pKeyMap_Def                   'default keymap 
                        cmp  cSpChar, #1   wz      'z=1 if cSpChar == 1  'keymap capitals
         if_z           mov  message_addr, pKeyMap_Caps
                        cmp  cSpChar, #2   wz      'z=1 if cSpChar == 2  'keymap green
         if_z           mov  message_addr, pKeyMap_Green
                        cmp  cSpChar, #4   wz      'z=1 if cSpChar == 4  'keymap orange
         if_z           mov  message_addr, pKeyMap_Orange

                       
                       'Read ascii char from table at index location
                        add  message_addr, cKeyIndex   'add offset into keymap lookup table
                        mov  message_cnt, #1
                        rdbyte rxdata, message_addr    'lookup ascii character
                                              
                        cmp  cSpChar, #8   wz     'z=1 if cSpChar == 8  'keymap people
         if_nz          jmp  #:ChatRecCntDown     'skip special 'people' keys

                       'Processing of special 'People' keys
                       '----------------------------------
                       ' "u" := MU 'move cursor up
                       ' "d" := MD 'move cursor down
                       ' "l" := ML 'move cursor left
                       ' "r" := MR 'move cursor right
                       ' "p" := BP 'PC beep
                       ' "c" := CS 'clear screen
                       ' "e" := CE 'clear to end of current line
                       ' "b" := CB 'clear lines below current line
                        cmp  rxdata, #"u"  wz
          if_z          mov  rxdata, #MU              
                        cmp  rxdata, #"d"  wz
          if_z          mov  rxdata, #MD              
                        cmp  rxdata, #"l"  wz
          if_z          mov  rxdata, #ML              
                        cmp  rxdata, #"r"  wz
          if_z          mov  rxdata, #MR              
                        cmp  rxdata, #"p"  wz
          if_z          mov  rxdata, #BP              
                        cmp  rxdata, #"c"  wz
          if_z          mov  rxdata, #CS              
                        cmp  rxdata, #"e"  wz
          if_z          mov  rxdata, #CE              
                        cmp  rxdata, #"b"  wz
          if_z          mov  rxdata, #CB              
       
                                         
:ChatRecCntDown         sub   cChatRecCnt, #1     'count down thru all 8 bytes of message ..    
                        
'-----------------------------------------------------------------------------------------------
'Only a table lookup operation will set rxdata to be <= $FF, and allow data passage to rx_buffer

:RxBufWriteTest         cmp   rxdata, #$FF   wc   'c=1 if rxdata =< $FF (write to rx_buffer)
                                                  'c=0 if rxdata  > $FF (skip buffer write)
         if_nc          jmp     #receive_low      'wait to receive next byte ....
                                                  'do not write byte to rx_buffer ! 
                                                                    
'--------------------------------------------------------------------------------
'WRITE BYTE TO CURRENT RX_HEAD INDEX WITHIN RX_BUFFER() & ADVANCE RX_HEAD INDEX
        
 Write_Byte_To_Rx_Buf   rdlong  t2,par                'After: t2 holds current rx_head value (rx_buffer INDEX)
                                                      'par = address of rx_head HUB variable
                                                      
                        add     t2,rxbuff             't2 = rxbuff + t2, t2 now holds address to current head
                                                      'position within circular buffer rx_buffer().
                                                      'rxbuff previously loaded with rx_buffer(0) address.
                                                      
                        wrbyte  rxdata,t2             'HUB WRITE INSTR:  rxdata -> head pos within rx_buffer()
                        sub     t2,rxbuff             'Afterwards: t2 = rx_buffer INDEX value (again)

                        add     t2,#1                 'Increment Head INDEX 
                        and     t2,#BufferSize-1      'Rollover to zero if > 31 (only 32 byte buffer)
                        wrlong  t2,par                'HUB WRITE INSTR: par = address of rx_head,
                                                      'write new INDEX value (t2) to rx_head HUB address (par)

                        jmp     #receive_low          'byte done, wait to receive next byte ....
                                                      'branch to 'receive_low' and test for START-BIT
                                                      'leading edge as a valid stop-bit was detected.
'
'-------------------------------------------------------------------
DAT 'Transmit
'-------------------------------------------------------------------
                                                      
'------------------------------------------------------
'TEST FOR PRESENCE OF DATA TO BE SENT WITHIN TX_BUFFER()

transmit                jmpret  txcode,rxcode 'run a chunk of receive code, then return
                                              'rxcode holds the 'GOTO' address
                                              'txcode is aut0-loaded with PC+1, the ret addr

                        'andn    outa, TestMask5   'SET LOW WHILE TX CODE
                      
                        mov     t1,par                'check for head <> tail

                        add     t1,#2 << 2            'advance two longs to tx_head
                        rdlong  t2,t1                 'read into t2 the contents of HUB var tx_head

                        add     t1,#1 << 2            'advance one long to tx_tail
                        rdlong  t3,t1                 'read into t3 the contents of HUB var tx_tail

                        cmp     t2,t3           wz    'if t2=t3 (tx_head = tx_tail), z=1 (buffer empty)
        if_nz           call    #Transmit_TxBuf       'if tx_buffer() not empty (z=0), transmit byte.

   'ok...nothing in tx_buffer to send... but, anything in message buffer to send ?
   '-------------------------------------------------------------------------------
DAT  'AWAKE MESSAGE PROCESSING
   
                     'send new awake message if necessary
                     '-----------------------------------           
                        mov     t1,awake_cnt   'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0    wc    'C=1, if t1 <= #0  (t1 = awake_cnt - cnt)
                                               'So, cnt >= awake_cnt causes t1 <= 0, and C=1
        if_nc           jmp     #skip_awake_message  'not yet time to send new awake_message !

                      'prepare to send new message
                      '---------------------------
                        mov    message_addr, pAwakeMessage   'hub address of message to send
                        mov    message_cnt, #5  'bytes to send

                        mov    awake_cnt, cnt
                        add    awake_cnt, two_seconds   'reset timer for next awake message tx

   'test to see if all bytes of current message have been transmitted ....
   '---------------------------------------------------------------------- 
skip_awake_message      cmp     message_cnt, #0   wz  'if message_cnt == 0, z=1 (nothing to tx)    
            if_z        jmp     #transmit             'nothing to send at this time ...

                        rdbyte  txdata, message_addr
                        call    #Transmit_Byte        'send data byte to ChatPad
                                
                        add     message_addr, #1  'advance message pointer by 1 byte
                        sub     message_cnt, #1
                        
                        jmp     #transmit
                        
      
'@@@@@@@@@@@@@@@@@@@@@@@@@@@  SINGLE-BYTE TRANSMIT @@@@@@@@@@@@@@@@@@@@@@@@@@@@
DAT 'Transmit_TxBuf Routine
                       
'---------------------------------------------------------------------------        
'GET BYTE FROM TX_TAIL POSITION WITHIN TX_BUFFER() AND ADVANCE TX_TAIL INDEX

't3 must have been preloaded with tx_tail value prior to calling this routine

Transmit_TxBuf          add     t3,txbuff             't3 == next hub_addr to transmit (tx_buffer + tx_tail_index)
                        rdbyte  txdata,t3             'txdata == value @ tx_tail_index within tx_buffer()
                        sub     t3,txbuff             't3 == tx_tail_index (tx_tail_index + tx_buffer - tx_buffer)

                        add     t3,#1                 'incr t3 (tx_tail_index)
                        and     t3,#BufferSize-1      'rollover index if necessary: limit 0 to BufferSize-1 
                        wrlong  t3,t1                 'write new tx_tail_index to HUB address t1 (tx_tail)

          '@@@@ SPECIAL CHAT PAD CODE TO ENABLE RX FILTERING @@@@
                        mov     cTxTestByte, txdata
                        and     cTxTestByte, #$FF
                        cmp     cTxTestByte, #"I"  wz  'z=1 if cTxTestByte=="I"
              if_z      mov     Chat_Awake_State, #1   'Initialization Successful. Start Rx Filter.          
          '@@@@@ END SPECIAL CHAT PAD CODE @@@@@@@@@@@@              
                        
                        call    #Transmit_Byte
Transmit_TxBuf_RET      ret

 


'-------------------------
DAT 'Transmit_Byte Routine                          
'-------------------------

     '-----------------------------
     'PREPARE TO SEND DATA BITS ...

Transmit_Byte           'or      outa, TestMask6       'TEST ONLY - SET HIGH AT TX BYTE
               
                        or      txdata,#$100          'get ready to transmit byte: STOP BIT is bit8 = 1
                        shl     txdata,#2             'bits 1-0 are both zero ( START BIT + SPACE-BIT)
                        or      txdata,#1             'set SPACE-BIT to 1 (same polarity as stop bit)
                        mov     txbits,#11            'START + 8-BITS + STOP + 1-SPACE
                       
                        mov     txcnt,cnt             'preload current system count value

     '----------------------
     'TRANSMIT NEXT DATA BIT

:bit                    test    rxtxmode,#%100  wz    'z=1 if bit2=0 (NOT open drain)
                        test    rxtxmode,#%010  wc    'c=1 if bit1=1 ( tx inverted )
        if_z_and_c      xor     txdata,#1             'if inverted & not open-drain, INVERT BITS
        
                        shr     txdata,#1       wc    'C = shift out next data bit ...LSB first !
                                                              
        if_z            muxc    outa,txmask           'if z=1 (NOT open drain), then tx_pin = C
        if_nz           muxnc   dira,txmask           'if z=0 (open drain/source), then
                                                      '    if C=0 (DATA BIT LOW) then
                                                      '       tx_pin = output type
                                                      '       NOTE: inverted mode sets out level HIGH
                                                      '             non-inverted mode sets out level LOW        
                                                      '    else (DATA BIT HIGH)
                                                      '       tx_pin = input type
                                                      '         Pulled to V+ or GND by
                                                      '         external pullup or pulldown resistor.
                       
                        add     txcnt,bitticks        'ready next cnt

     '-------------------------
     'TEST FOR END-OF-BIT TIME

:wait                   jmpret  txcode,rxcode         'run a chunk of receive code, then return
                                                      'rxcode holds 'GOTO' address
                                                      'txcode auto-loaded with PC+1, the ret addr

                        'andn    outa, TestMask5   'SET LOW WHILE TX CODE
                                   
                        mov     t1,txcnt              'check if bit transmit period done
                        sub     t1,cnt
                        cmps    t1,#0           wc    'C=1 if t1 <= #0, t1 = txcnt - cnt
                                                      'if cnt >= txcnt, then t1 <= #0, and C = 1
        if_nc           jmp     #:wait                'do receive code then return and retest

                        djnz    txbits,#:bit          'another bit to transmit?

                        'andn    outa, TestMask6       'TEST ONLY - SET LOW AT TX BYTE
                        
Transmit_Byte_RET       ret                           'byte transmission complete ...


'---------------------------------------------------------------------------------
DAT 'Initialized data

'The cog will have its hub pointer variables pre-loaded with the "offset-from-object-start addresses"
'At cog startup, these offsets will be added to the object's start address to obtain true run-time addresses.
'The object's start address is obtained from the hub variable obj_addr, pre-loaded with "@@0".

pInitMessage   Long  @InitMessage
pAwakeMessage  Long  @AwakeMessage
pKeyMap_Def    Long  @KeyMap_Def
pKeyMap_Caps   Long  @KeyMap_Caps
pKeyMap_Green  Long  @KeyMap_Green
pKeyMap_Orange Long  @KeyMap_Orange      

two_seconds    Long  160_000_000
'---------------------------------------------------------------------------------
DAT 'Uninitialized data
'
 
t1                      res     1
t2                      res     1
t3                      res     1

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxbuff                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

txmask                  res     1
txbuff                  res     1
txdata                  res     1
txbits                  res     1
txcnt                   res     1
txcode                  res     1

syncmask                res     1

bufptr                  res     1

message_addr            res     1
message_cnt             res     1 
awake_cnt               res     1
chat_awake_state        res     1   '0 =  not awake, requires initialization,
                                    '1 =  awake, sending keyboard data ... 

cTxTestByte             res     1

'----- used by keycode filter ------
cChatRecCnt             res     1
cSpChar                 res     1
cKeyChar                res     1
cTestByte               res     1
cHighNib                res     1
cLowNib                 res     1
cKeyIndex               res     1
cLastChar               res     1

bufcnt                  res     1
bufptr_temp             res     1
long_temp               res     1

WriteLong               res     1
bitticks_half           res     1

FIT   'always test that cog code will fit

        
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