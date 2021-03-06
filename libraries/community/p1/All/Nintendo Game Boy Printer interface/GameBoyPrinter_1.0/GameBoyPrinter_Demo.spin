{{
┌──────────────────────────────────────────────────────────┐
│ Nintendo Game Boy Printer                                │
│ Object Demonstration Code                                │
│                                                          │
│ Author: Joe Grand                                        │
│ Copyright (c) 2011 Grand Idea Studio, Inc.               │
│ Web: http://www.grandideastudio.com                      │ 
│                                                          │
│ Distributed under a Creative Commons                     │
│ Attribution 3.0 United States license                    │
│ http://creativecommons.org/licenses/by/3.0/us/           │
└──────────────────────────────────────────────────────────┘

Program Description:

This program demonstrates the Game Boy Printer object, which provides the
communication interface to a Nintendo Game Boy Printer.

The object is inspired by furrtek's GBLink/PC interface project
(http://furrtek.free.fr/index.php?p=crea&a=gbpcable&i=2) and Reversing the Game Boy
Printer page (http://furrtek.free.fr/index.php?p=crea&a=gbprinter).

The SIN pin (serial input TO Propeller) must be pulled up to VCC via a 15k resistor.
Refer to the LRFCam project on Grand Idea Studio's Laser Range Finder page
(http://www.grandideastudio.com/portfolio/laser-range-finder/) for a hardware
connection example.   


Revisions:
1.0 (November 30, 2011): Initial release
 
}}


CON
  _clkmode = xtal1 + pll16x
'  _xinfreq = 5_000_000            ' 80MHz
  _xinfreq = 6_000_000            ' 96MHz overclock
  _stack   = 50                   ' Ensure we have this minimum stack space available

  GBPInPin      = 27              ' SPI master interface, IN from Gameboy printer (GBP)
  GBPOutPin     = 26              '                       OUT to printer
  GBPClkPin     = 22              '                       CLOCK to printer


OBJ
  gbp           : "GameBoyPrinter"    ' Nintendo Game Boy Printer interface


PUB main
  gbp.start(GBPInPin, GBPOutPin, GBPClkPin)   ' Start Game Boy Printer object

  ' GBP horizontal resolution of 160 pixels @ 2 bit/pixel greyscale
  ' Each tile = 8 pixels * 8 pixels 
  ' 20 tiles horizontal per band
  ' 2 bands per buffer
  gbp.printbuffer(@GBP_Nintendo, 1)           ' Print a sample image
  'gbp.printbuffer(@GBP_Gradient, 1)           ' Print a sample image
  'gbp.printbuffer(@GBP_Gameboy, 1)            ' Print a sample image

  
DAT     ' Hard-coded image data for testing/demonstration purposes
GBP_Nintendo   ' Nintendo logo
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FE, $FF, $FE, $FE
  byte $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE
  byte $FF, $FF, $FF, $FF, $1C, $FF, $3E, $1C
  byte $0C, $1C, $04, $0C, $0C, $04, $24, $04
  byte $FF, $FF, $FF, $FF, $63, $FF, $07, $63
  byte $43, $23, $63, $3F, $02, $62, $02, $62
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $F7, $FE, $03, $01, $11, $00
  byte $FF, $FF, $FF, $FF, $FF, $FF, $8F, $FF
  byte $47, $8F, $05, $03, $00, $8E, $C8, $8C
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $7F, $9F, $0E, $04, $E0, $46
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $E7, $FF, $41, $03, $21, $01
  byte $FF, $FF, $FF, $FF, $F8, $FF, $F0, $F8
  byte $F0, $F8, $E0, $F8, $C0, $80, $18, $00
  byte $FF, $FF, $FF, $FF, $FF, $FF, $7F, $FF
  byte $7E, $FF, $6D, $F3, $61, $C0, $44, $8C
  byte $FF, $FF, $FF, $FF, $BF, $FF, $BF, $1F
  byte $5F, $0F, $0F, $1F, $9F, $FF, $3F, $7F
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FE, $FE, $FE, $FE, $FE, $FE, $FE, $FE
  byte $FE, $FE, $FF, $FF, $FF, $FF, $FF, $FF
  byte $24, $10, $30, $10, $30, $18, $3C, $18
  byte $18, $3C, $FF, $FF, $FF, $FF, $FF, $FF
  byte $02, $62, $02, $62, $02, $62, $42, $22
  byte $02, $62, $FF, $FF, $FF, $FF, $FF, $FF
  byte $19, $30, $19, $30, $19, $30, $19, $30
  byte $11, $38, $FF, $FF, $FF, $FF, $FF, $FF
  byte $4C, $88, $4C, $88, $4C, $88, $48, $8C
  byte $CC, $8E, $FF, $FF, $FF, $FF, $FF, $FF
  byte $06, $00, $FA, $04, $7A, $E4, $A2, $44
  byte $06, $0C, $FF, $FF, $FF, $FF, $FF, $FF
  byte $20, $31, $21, $30, $20, $31, $21, $31
  byte $61, $31, $FF, $FF, $FF, $FF, $FF, $FF
  byte $00, $18, $00, $18, $00, $18, $98, $00
  byte $C0, $80, $FF, $FF, $FF, $FF, $FF, $FF
  byte $04, $8C, $84, $0C, $04, $8C, $48, $84
  byte $61, $C0, $FF, $FF, $FF, $FF, $FF, $FF
  byte $7F, $3F, $7F, $3F, $7F, $3F, $3F, $7F
  byte $7F, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

GBP_Gradient  ' Horizontal gradient w/ black margins
  byte $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $3F, $00, $3F, $00, $00, $3F, $00, $3F
  byte $3F, $3F, $3F, $3F, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FC, $00, $FC, $00, $00, $FC, $00, $FC
  byte $FC, $FC, $FC, $FC, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $3F, $00, $3F, $00, $00, $3F, $00, $3F
  byte $3F, $3F, $3F, $3F, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FF, $00, $FF, $00, $00, $FF, $00, $FF
  byte $FF, $FF, $FF, $FF, $00, $00, $00, $00
  byte $FC, $00, $FC, $00, $00, $FC, $00, $FC
  byte $FC, $FC, $FC, $FC, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF  

GBP_Gameboy  ' Game Boy logo
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FE, $FF
  byte $FC, $FE, $FC, $F8, $F9, $F1, $E3, $F3
  byte $FF, $FF, $FF, $FF, $FF, $FF, $77, $8F
  byte $0E, $07, $87, $7E, $FC, $FE, $FE, $FC
  byte $FF, $FF, $FF, $FF, $FF, $FF, $BF, $7E
  byte $3C, $3E, $1E, $3C, $18, $3C, $18, $3C
  byte $FF, $FF, $FF, $FF, $FF, $FF, $77, $FB
  byte $F1, $73, $61, $73, $21, $63, $20, $43
  byte $FF, $FF, $FF, $FF, $FF, $FF, $7B, $87
  byte $81, $03, $83, $3F, $3F, $3F, $37, $0F
  byte $FF, $FF, $FF, $FF, $FF, $FF, $bb, $C7
  byte $C3, $83, $D9, $83, $C1, $9B, $82, $83
  byte $FF, $FF, $FF, $FF, $FF, $FF, $DE, $E3
  byte $C3, $80, $25, $98, $19, $3C, $78, $3C
  byte $FF, $FF, $FF, $FF, $FF, $FF, $bb, $7D
  byte $71, $39, $03, $33, $23, $87, $CF, $87
  byte $FF, $FF, $AF, $D5, $FB, $D5, $FB, $D5
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $E3, $F3, $F7, $E3, $E3, $F3, $F0, $F3
  byte $F0, $F8, $FA, $FC, $FF, $FF, $FF, $FF
  byte $F9, $FC, $9C, $08, $88, $18, $5b, $91
  byte $03, $13, $07, $33, $FF, $FF, $FF, $FF
  byte $3d, $98, $3A, $19, $93, $19, $D1, $93
  byte $C3, $93, $A7, $D3, $FF, $FF, $FF, $FF
  byte $48, $03, $18, $0B, $80, $1B, $B3, $18
  byte $33, $B8, $B1, $FA, $FF, $FF, $FF, $FF
  byte $0F, $07, $37, $0F, $3F, $7F, $03, $7F
  byte $01, $03, $07, $03, $FF, $FF, $FF, $FF
  byte $83, $82, $38, $91, $3C, $99, $A8, $11
  byte $01, $03, $8B, $07, $FF, $FF, $FF, $FF
  byte $79, $3C, $7D, $38, $78, $39, $4B, $31
  byte $81, $03, $cb, $87, $FF, $FF, $FF, $FF
  byte $8F, $CF, $8F, $DF, $CF, $9F, $CF, $9F
  byte $CF, $9F, $FF, $9F, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

      