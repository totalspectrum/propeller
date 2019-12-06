{{4D Systems (c) 2007   All rights reserved  Authors: Atilla Aknar         Steve McManusRedistribution of unmodified code is permitted,          This Object is used to control the uOLED-96-PROP display directly from a user program writtenin SPIN or Propeller ASM.(NO SERIAL COMMS REQUIRED).The INIT routine must be the first methode called.This object is intended as a shell or template with the methods representing theprimatives required to build more complex commands.The best and most useful example of this is the Put_Pixel method. It may be implemented as shown belowor the "Write_cmd" method primatives may be used to build a Put_Pixel command with fewer methode callsand thus faster execution. The Put-Pixel method, as implemented here, helps to ilustrate the sequenceof commands required to write to the display screen.The accompanying demonstration SPIN program shows how to call methods in this object to implement thegraphics and text commands seen in the GOLDELOX and PICASO controlled uOLED and uLCD displays from 4D Systems. }}CON'*------------------------------------------------------------------------*'*  General definitions                                                   *'*------------------------------------------------------------------------*  ON       =  1  OFF      =  0  INPUT    =  1  OUTPUT   =  0  ENABLE   =  1  DISABLE  =  0  SET      =  1  CLEAR    =  0'*------------------------------------------------------------------------*'*  OLED Interface (PINS)                                                        *'*------------------------------------------------------------------------*  CS_OLED         =  8               ' OLED Chip Select Signal  RESETPIN_OLED   =  9               ' OLED Reset Signal  D_C             =  10              ' Data/Command  WR_OLED         =  11              ' OLED Write Signal  RD_OLED         =  12              ' OLED Read Signal  CS_VHI          =  13              ' OLED VCC Enable'*------------------------------------------------------------------------*'*  OLED-96 Registers                                                     *'*------------------------------------------------------------------------*  SET_COLUMN_ADDRESS    =       $15  SET_ROW_ADDRESS       =       $75  CONTRAST_RED          =       $81  CONTRAST_GREEN        =       $82  CONTRAST_BLUE         =       $83  CONTRAST_MASTER       =       $87  CONTRAST_RED_2ND      =       $8A  CONTRAST_GREEN_2ND    =       $8B  CONTRAST_BLUE_2ND     =       $8C  REMAP_COLOUR_SETTINGS =       $A0  DISPLAY_START_LINE    =       $A1  DISPLAY_OFFSET        =       $A2  DISPLAY_NORMAL        =       $A4  DISPLAY_ALL_ON        =       $A5  DISPLAY_ALL_OFF       =       $A6  DISPLAY_INVERSE       =       $A7  DUTY_CYCLE            =       $A8  MASTER_CONFIGURE      =       $AD  DISPLAY_OFF           =       $AE  DISPLAY_ON            =       $AF  POWERSAVE_MODE        =       $B0  PHASE_PRECHARGE       =       $B1  CLOCK_FREQUENCY       =       $B3  SET_GRAYSCALE_LUT     =       $B8  RESET_GRAYSCALE_LUT   =       $B9  PRECHARGE_VOLTAGE_RGB =       $BB  SET_VCOMH             =       $BE  OLED_NOP              =       $E3  LOCK_COMMAND          =       $FD  DRAW_LINE             =       $21  DRAW_RECTANGLE        =       $22  COPY_AREA             =       $23  DIM_WINDOW            =       $24  CLEAR_WINDOW          =       $25  FILL_ENABLE_DISABLE   =       $26  SCROLL_SETUP          =       $27  STOP_SCROLL           =       $2E  START_SCROLL          =       $2F  _256_COLOURS          =       $32  _65K_COLOURS          =       $72'*-------------------------------------------------------------------------*'*  Screen Related definitions                                             *'*-------------------------------------------------------------------------*  X_RES            =               96  Y_RES            =               64  MAXCOLOUR        =               $FFFF  MAX_TEXTROWS     =               25  BLACK            =               $0000  WHITE            =               $FFFF  RED              =               $F800  GREEN            =               $07E0  BLUE             =               $001F  YELLOW           =               RED | GREENOBJ  DELAY   : "Clock"DATfont_8x8      byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000              byte %00110000,%00110000,%00110000,%00110000,%00110000,%00000000,%00110000,%00000000              byte %01101100,%01101100,%01101100,%00000000,%00000000,%00000000,%00000000,%00000000              byte %01101100,%01101100,%11111110,%01101100,%11111110,%01101100,%01101100,%00000000              byte %00110000,%01111100,%11000000,%01111000,%00001100,%11111000,%00110000,%00000000              byte %00000000,%11000110,%11001100,%00011000,%00110000,%01100110,%11000110,%00000000              byte %00111000,%01101100,%00111000,%01110110,%11011100,%11001100,%01110110,%00000000              byte %01100000,%01100000,%11000000,%00000000,%00000000,%00000000,%00000000,%00000000              byte %00011000,%00110000,%01100000,%01100000,%01100000,%00110000,%00011000,%00000000              byte %01100000,%00110000,%00011000,%00011000,%00011000,%00110000,%01100000,%00000000              byte %00000000,%01100110,%00111100,%11111111,%00111100,%01100110,%00000000,%00000000              byte %00000000,%00110000,%00110000,%11111100,%00110000,%00110000,%00000000,%00000000              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00110000,%00110000,%01100000              byte %00000000,%00000000,%00000000,%11111100,%00000000,%00000000,%00000000,%00000000              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00110000,%00110000,%00000000              byte %00000100,%00001100,%00011000,%00110000,%01100000,%11000000,%10000000,%00000000              byte %01111100,%11000110,%11001110,%11011110,%11110110,%11100110,%01111100,%00000000              byte %00110000,%01110000,%00110000,%00110000,%00110000,%00110000,%11111100,%00000000              byte %01111000,%11001100,%00001100,%00111000,%01100000,%11001100,%11111100,%00000000              byte %01111000,%11001100,%00001100,%00111000,%00001100,%11001100,%01111000,%00000000              byte %00011100,%00111100,%01101100,%11001100,%11111110,%00001100,%00011110,%00000000              byte %11111100,%11000000,%11111000,%00001100,%00001100,%11001100,%01111000,%00000000              byte %00111000,%01100000,%11000000,%11111000,%11001100,%11001100,%01111000,%00000000              byte %11111100,%11001100,%00001100,%00011000,%00110000,%00110000,%00110000,%00000000              byte %01111000,%11001100,%11001100,%01111000,%11001100,%11001100,%01111000,%00000000              byte %01111000,%11001100,%11001100,%01111100,%00001100,%00011000,%01110000,%00000000              byte %00000000,%00110000,%00110000,%00000000,%00000000,%00110000,%00110000,%00000000              byte %00000000,%00110000,%00110000,%00000000,%00000000,%00110000,%00110000,%01100000              byte %00011000,%00110000,%01100000,%11000000,%01100000,%00110000,%00011000,%00000000              byte %00000000,%00000000,%11111100,%00000000,%00000000,%11111100,%00000000,%00000000              byte %01100000,%00110000,%00011000,%00001100,%00011000,%00110000,%01100000,%00000000              byte %01111000,%11001100,%00001100,%00011000,%00110000,%00000000,%00110000,%00000000              byte %01111100,%11000110,%11011110,%11011110,%11011110,%11000000,%01111000,%00000000              byte %00110000,%01111000,%11001100,%11001100,%11111100,%11001100,%11001100,%00000000              byte %11111100,%01100110,%01100110,%01111100,%01100110,%01100110,%11111100,%00000000              byte %00111100,%01100110,%11000000,%11000000,%11000000,%01100110,%00111100,%00000000              byte %11111000,%01101100,%01100110,%01100110,%01100110,%01101100,%11111000,%00000000              byte %01111110,%01100000,%01100000,%01111000,%01100000,%01100000,%01111110,%00000000              byte %01111110,%01100000,%01100000,%01111000,%01100000,%01100000,%01100000,%00000000              byte %00111100,%01100110,%11000000,%11000000,%11001110,%01100110,%00111110,%00000000              byte %11001100,%11001100,%11001100,%11111100,%11001100,%11001100,%11001100,%00000000              byte %01111000,%00110000,%00110000,%00110000,%00110000,%00110000,%01111000,%00000000              byte %00011110,%00001100,%00001100,%00001100,%11001100,%11001100,%01111000,%00000000              byte %11100110,%01100110,%01101100,%01111000,%01101100,%01100110,%11100110,%00000000              byte %01100000,%01100000,%01100000,%01100000,%01100000,%01100000,%01111110,%00000000              byte %11000110,%11101110,%11111110,%11111110,%11010110,%11000110,%11000110,%00000000              byte %11000110,%11100110,%11110110,%11011110,%11001110,%11000110,%11000110,%00000000              byte %00111000,%01101100,%11000110,%11000110,%11000110,%01101100,%00111000,%00000000              byte %11111100,%01100110,%01100110,%01111100,%01100000,%01100000,%11110000,%00000000              byte %01111000,%11001100,%11001100,%11001100,%11011100,%01111000,%00011100,%00000000              byte %11111100,%01100110,%01100110,%01111100,%01101100,%01100110,%11100110,%00000000              byte %01111000,%11001100,%11100000,%01111000,%00011100,%11001100,%01111000,%00000000              byte %11111100,%00110000,%00110000,%00110000,%00110000,%00110000,%00110000,%00000000              byte %11001100,%11001100,%11001100,%11001100,%11001100,%11001100,%11111100,%00000000              byte %11001100,%11001100,%11001100,%11001100,%11001100,%01111000,%00110000,%00000000              byte %11000110,%11000110,%11000110,%11010110,%11111110,%11101110,%11000110,%00000000              byte %11000110,%11000110,%01101100,%00111000,%00111000,%01101100,%11000110,%00000000              byte %11001100,%11001100,%11001100,%01111000,%00110000,%00110000,%01111000,%00000000              byte %11111110,%00000110,%00001100,%00011000,%00110000,%01100000,%11111110,%00000000              byte %01111000,%01100000,%01100000,%01100000,%01100000,%01100000,%01111000,%00000000              byte %11000000,%01100000,%00110000,%00011000,%00001100,%00000110,%00000010,%00000000              byte %01111000,%00011000,%00011000,%00011000,%00011000,%00011000,%01111000,%00000000              byte %00010000,%00111000,%01101100,%11000110,%00000000,%00000000,%00000000,%00000000              byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%11111111              byte %00110000,%00110000,%00011000,%00000000,%00000000,%00000000,%00000000,%00000000              byte %00000000,%00000000,%01111000,%00001100,%01111100,%11001100,%01110110,%00000000              byte %11100000,%01100000,%01100000,%01111100,%01100110,%01100110,%11011100,%00000000              byte %00000000,%00000000,%01111000,%11001100,%11000000,%11001100,%01111000,%00000000              byte %00011100,%00001100,%00001100,%01111100,%11001100,%11001100,%01110110,%00000000              byte %00000000,%00000000,%01111000,%11001100,%11111100,%11000000,%01111000,%00000000              byte %00111000,%01101100,%01100000,%11110000,%01100000,%01100000,%11110000,%00000000              byte %00000000,%00000000,%01110110,%11001100,%11001100,%01111100,%00001100,%11111000              byte %11100000,%01100000,%01101100,%01110110,%01100110,%01100110,%11100110,%00000000              byte %00110000,%00000000,%01110000,%00110000,%00110000,%00110000,%01111000,%00000000              byte %00001100,%00000000,%00001100,%00001100,%00001100,%11001100,%11001100,%01111000              byte %11100000,%01100000,%01100110,%01101100,%01111000,%01101100,%11100110,%00000000              byte %01110000,%00110000,%00110000,%00110000,%00110000,%00110000,%01111000,%00000000              byte %00000000,%00000000,%11001100,%11111110,%11111110,%11010110,%11000110,%00000000              byte %00000000,%00000000,%11111000,%11001100,%11001100,%11001100,%11001100,%00000000              byte %00000000,%00000000,%01111000,%11001100,%11001100,%11001100,%01111000,%00000000              byte %00000000,%00000000,%11011100,%01100110,%01100110,%01111100,%01100000,%11110000              byte %00000000,%00000000,%01110110,%11001100,%11001100,%01111100,%00001100,%00011110              byte %00000000,%00000000,%11011100,%01110110,%01100110,%01100000,%11110000,%00000000              byte %00000000,%00000000,%01111100,%11000000,%01111000,%00001100,%11111000,%00000000              byte %00010000,%00110000,%01111100,%00110000,%00110000,%00110100,%00011000,%00000000              byte %00000000,%00000000,%11001100,%11001100,%11001100,%11001100,%01110110,%00000000              byte %00000000,%00000000,%11001100,%11001100,%11001100,%01111000,%00110000,%00000000              byte %00000000,%00000000,%11000110,%11010110,%11111110,%11111110,%01101100,%00000000              byte %00000000,%00000000,%11000110,%01101100,%00111000,%01101100,%11000110,%00000000              byte %00000000,%00000000,%11001100,%11001100,%11001100,%01111100,%00001100,%11111000              byte %00000000,%00000000,%11111100,%10011000,%00110000,%01100100,%11111100,%00000000              byte %00011100,%00110000,%00110000,%11100000,%00110000,%00110000,%00011100,%00000000              byte %00011000,%00011000,%00011000,%00000000,%00011000,%00011000,%00011000,%00000000              byte %11100000,%00110000,%00110000,%00011100,%00110000,%00110000,%11100000,%00000000              byte %01110110,%11011100,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000              byte %00000000,%01100110,%01100110,%01100110,%01100110,%01100110,%01011100,%10000000font_5x7      byte $00,$00,$00,$00,$00,$00,$00,$00  ' space              byte $02,$02,$02,$02,$02,$00,$02,$00  '  "!"              byte $36,$12,$24,$00,$00,$00,$00,$00  '  """              byte $00,$14,$3E,$14,$3E,$14,$00,$00  '  "#"              byte $08,$3C,$0A,$1C,$28,$1E,$08,$00  '  "$"              byte $22,$22,$10,$08,$04,$22,$22,$00  '  "%"              byte $04,$0A,$0A,$04,$2A,$12,$2C,$00  '  "&"              byte $18,$10,$08,$00,$00,$00,$00,$00  '  "'"              byte $20,$10,$08,$08,$08,$10,$20,$00  '  "("              byte $02,$04,$08,$08,$08,$04,$02,$00  '  ")"              byte $00,$08,$2A,$1C,$1C,$2A,$08,$00  '  "*"              byte $00,$08,$08,$3E,$08,$08,$00,$00  '  "+"              byte $00,$00,$00,$00,$00,$06,$04,$02  '  ","              byte $00,$00,$00,$3E,$00,$00,$00,$00  '  "-"              byte $00,$00,$00,$00,$00,$06,$06,$00  '  "."              byte $20,$20,$10,$08,$04,$02,$02,$00  '  "/"              byte $1C,$22,$32,$2A,$26,$22,$1C,$00  '  "0"              byte $08,$0C,$08,$08,$08,$08,$1C,$00  '  "1"              byte $1C,$22,$20,$10,$0C,$02,$3E,$00  '  "2"              byte $1C,$22,$20,$1C,$20,$22,$1C,$00  '  "3"              byte $10,$18,$14,$12,$3E,$10,$10,$00  '  "4"              byte $3E,$02,$1E,$20,$20,$22,$1C,$00  '  "5"              byte $18,$04,$02,$1E,$22,$22,$1C,$00  '  "6"              byte $3E,$20,$10,$08,$04,$04,$04,$00  '  "7"              byte $1C,$22,$22,$1C,$22,$22,$1C,$00  '  "8"              byte $1C,$22,$22,$3C,$20,$10,$0C,$00  '  "9"              byte $00,$06,$06,$00,$06,$06,$00,$00  '  ":"              byte $00,$06,$06,$00,$06,$06,$04,$02  '  ";"              byte $20,$10,$08,$04,$08,$10,$20,$00  '  "<"              byte $00,$00,$3E,$00,$3E,$00,$00,$00  '  "="              byte $02,$04,$08,$10,$08,$04,$02,$00  '  ">"              byte $1C,$22,$20,$10,$08,$00,$08,$00  '  "?"              byte $1C,$22,$2A,$2A,$1A,$02,$3C,$00  '  "@"              byte $08,$14,$22,$22,$3E,$22,$22,$00  '  "A"              byte $1E,$22,$22,$1E,$22,$22,$1E,$00  '  "B"              byte $18,$24,$02,$02,$02,$24,$18,$00  '  "C"              byte $0E,$12,$22,$22,$22,$12,$0E,$00  '  "D"              byte $3E,$02,$02,$1E,$02,$02,$3E,$00  '  "E"              byte $3E,$02,$02,$1E,$02,$02,$02,$00  '  "F"              byte $1C,$22,$02,$02,$32,$22,$1C,$00  '  "G"              byte $22,$22,$22,$3E,$22,$22,$22,$00  '  "H"              byte $3E,$08,$08,$08,$08,$08,$3E,$00  '  "I"              byte $20,$20,$20,$20,$20,$22,$1C,$00  '  "J"              byte $22,$12,$0A,$06,$0A,$12,$22,$00  '  "K"              byte $02,$02,$02,$02,$02,$02,$3E,$00  '  "L"              byte $22,$36,$2A,$2A,$22,$22,$22,$00  '  "M"              byte $22,$22,$26,$2A,$32,$22,$22,$00  '  "N"              byte $1C,$22,$22,$22,$22,$22,$1C,$00  '  "O"              byte $1E,$22,$22,$1E,$02,$02,$02,$00  '  "P"              byte $1C,$22,$22,$22,$2A,$12,$2C,$00  '  "Q"              byte $1E,$22,$22,$1E,$0A,$12,$22,$00  '  "R"              byte $1C,$22,$02,$1C,$20,$22,$1C,$00  '  "S"              byte $3E,$08,$08,$08,$08,$08,$08,$00  '  "T"              byte $22,$22,$22,$22,$22,$22,$1C,$00  '  "U"              byte $22,$22,$22,$14,$14,$08,$08,$00  '  "V"              byte $22,$22,$22,$2A,$2A,$2A,$14,$00  '  "W"              byte $22,$22,$14,$08,$14,$22,$22,$00  '  "X"              byte $22,$22,$14,$08,$08,$08,$08,$00  '  "Y"              byte $3E,$20,$10,$08,$04,$02,$3E,$00  '  "Z"              byte $3E,$06,$06,$06,$06,$06,$3E,$00  '  "["              byte $02,$02,$04,$08,$10,$20,$20,$00  '  "\"              byte $3E,$30,$30,$30,$30,$30,$3E,$00  '  "]"              byte $00,$00,$08,$14,$22,$00,$00,$00  '  "^"              byte $00,$00,$00,$00,$00,$00,$00,$7F  '  "_"              byte $10,$08,$18,$00,$00,$00,$00,$00  '  "`"              byte $00,$00,$1C,$20,$3C,$22,$3C,$00  '  "a"              byte $02,$02,$1E,$22,$22,$22,$1E,$00  '  "b"              byte $00,$00,$3C,$02,$02,$02,$3C,$00  '  "c"              byte $20,$20,$3C,$22,$22,$22,$3C,$00  '  "d"              byte $00,$00,$1C,$22,$3E,$02,$3C,$00  '  "e"              byte $18,$24,$04,$1E,$04,$04,$04,$00  '  "f"              byte $00,$00,$1C,$22,$22,$3C,$20,$1C  '  "g"              byte $02,$02,$1E,$22,$22,$22,$22,$00  '  "h"              byte $08,$00,$0C,$08,$08,$08,$1C,$00  '  "i"              byte $10,$00,$18,$10,$10,$10,$12,$0C  '  "j"              byte $02,$02,$22,$12,$0C,$12,$22,$00  '  "k"              byte $0C,$08,$08,$08,$08,$08,$1C,$00  '  "l"              byte $00,$00,$36,$2A,$2A,$2A,$22,$00  '  "m"              byte $00,$00,$1E,$22,$22,$22,$22,$00  '  "n"              byte $00,$00,$1C,$22,$22,$22,$1C,$00  '  "o"              byte $00,$00,$1E,$22,$22,$1E,$02,$02  '  "p"              byte $00,$00,$3C,$22,$22,$3C,$20,$20  '  "q"              byte $00,$00,$3A,$06,$02,$02,$02,$00  '  "r"              byte $00,$00,$3C,$02,$1C,$20,$1E,$00  '  "s"              byte $04,$04,$1E,$04,$04,$24,$18,$00  '  "t"              byte $00,$00,$22,$22,$22,$32,$2C,$00  '  "u"              byte $00,$00,$22,$22,$22,$14,$08,$00  '  "v"              byte $00,$00,$22,$22,$2A,$2A,$36,$00  '  "w"              byte $00,$00,$22,$14,$08,$14,$22,$00  '  "x"              byte $00,$00,$22,$22,$22,$3C,$20,$1C  '  "y"              byte $00,$00,$3E,$10,$08,$04,$3E,$00  '  "z"              byte $38,$0C,$0C,$06,$0C,$0C,$38,$00  '  "{"              byte $08,$08,$08,$08,$08,$08,$08,$08  '  "|"              byte $0E,$18,$18,$30,$18,$18,$0E,$00  '  "}"              byte $00,$2C,$1A,$00,$00,$00,$00,$00  '  "~"              byte $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F   '  --         PUB InitOLED'' Initializes the display registers to their "NORMAL" values.'' This method should not be changed or experimented with until you understand the'' inter-workings of the display's registers.'' '' If you make changes to this method, you risk rendering the display'' unusable for normal operation. Failure to heed this warning could cause'' permanent damage to the display controller.   DIRA := %00000000_00000000_00111111_11111111   ' Set Pins Direction 0 : Input, 1 : Output       '  OUTA[7..0] := $00                             ' data=0 on Pins 7:0 (DIRA LSB)  OUTA[RD_OLED] := 1                          OUTA[D_C] := 1  OUTA[WR_OLED] := 1  OUTA[CS_OLED] := 1        Reset_OLED  PowerUp_Seq    Write_cmd(DISPLAY_NORMAL)                      ' Normal display     Write_cmd(CLOCK_FREQUENCY)                     ' clock & frequency  Write_cmd($f0)     Write_cmd(DISPLAY_OFFSET)                      'Set display offset  Write_cmd($00)                                 '0 hex start     Write_cmd(DUTY_CYCLE)                          ' Duty  Write_cmd(63)                                  ' 63+1     Write_cmd(MASTER_CONFIGURE)                    ' Set Master Configuration  Write_cmd($8e)     Write_cmd(DISPLAY_START_LINE)                  'Set display start line  Write_cmd($00)                                 ' 00 hex start     Write_cmd(REMAP_COLOUR_SETTINGS)               ' Set Re-map Color/Depth  Write_cmd(_65K_COLOURS)                        ' 65K 8bit R->G->B     Write_cmd(CONTRAST_MASTER)                     ' Set master contrast  Write_cmd($0f)     Write_cmd(CONTRAST_RED)                        ' Set contrast current for A   Write_cmd($ff)    Write_cmd(CONTRAST_GREEN)                      ' Set contrast current for B   Write_cmd($ff)    Write_cmd(CONTRAST_BLUE)                       ' Set contrast current for C   Write_cmd($ff)    Write_cmd(PRECHARGE_VOLTAGE_RGB)               ' Set pre-charge voltage of color A B C  Write_cmd($3E)'  Write_cmd($1c)  Write_cmd(SET_VCOMH)                           ' Set VcomH  Write_cmd($3E)     Write_cmd(POWERSAVE_MODE)                      ' Power saving mode  Write_cmd($00)     Write_cmd(PHASE_PRECHARGE)                     ' Set pre & dis_charge  Write_cmd($11)     Write_cmd(DISPLAY_ON)                          ' Display on  Set_Full_Screen                                ' Set screen boundries'  Clear_Screen  PUB Write_cmd (cmd)'' Shifts out one byte of either register address of data placed on pins 7 through 0  OUTA[D_C] := 0  OUTA[CS_OLED] := 0  OUTA[WR_OLED] := 0  OUTA[7..0] := cmd.byte[0]                      ' pins 7:0   OUTA[WR_OLED] := 1  OUTA[CS_OLED] := 1  OUTA[D_C] := 1PUB PowerDown_Seq'' Used to power down the screen electronics without disturbing the screen data written to GRAM'' Can be used instead of a screensaver to prolong the life of the display and/or conserve power  Write_cmd(DISPLAY_OFF)  OUTA[CS_VHI] := 0                              ' Disable OLED VCC  DELAY.PauseMSec(100)PUB PowerUp_Seq'' Powers on the screen electronics and displays any screen data previously written to GRAM'' You can continue to write to GRAM (the screen) while the display is powered down and on PowerUp,'' the latest screen data will be displayed.  Write_cmd(DISPLAY_OFF)  OUTA[CS_VHI] := 1                              ' Enable OLED VCC  DELAY.PauseMSec(100)PUB Reset_OLED'' Resets the display registers to their default values. If you call this methode, you must call'' InitOLED method. Equavalent to removing power from the display, without the risk of damaging the'' screen electronics. Use the PowerDown_Seq before removing power from the display.  OUTA[RESETPIN_OLED] := 0  DELAY.PauseMSec(100)  OUTA[RESETPIN_OLED] := 1PUB Set_GRAM_Access(xStart, xEnd, yStart, yEnd)'' Sets the upper-left (xStart, yStart) and the lower-right (xEnd, yEnd) corners of the area of'' Graphic RAM that may be written to  Write_cmd(SET_COLUMN_ADDRESS)  Write_cmd(xStart)  Write_cmd(xEnd)  Write_cmd(SET_ROW_ADDRESS)  Write_cmd(yStart)  Write_cmd(yEnd)  PUB Set_Full_Screen  Set_GRAM_Access (0, 95, 0, 63)PUB Write_Start_GRAM'' Required before any write operation to GRAM  OUTA[D_C] := 1  OUTA[CS_OLED] := 0PUB Write_Stop_GRAM  OUTA[CS_OLED] := 1PUB Write_GRAM_Byte(byteData)'' Writes one byte of color data to the screen memory. Only useful in 256 color mode.  OUTA[WR_OLED] := 0  OUTA[7..0] := byteData.byte[0]  OUTA[WR_OLED] := 1PUB Write_GRAM_Word(wordData)'' Writes two bytes of color data to the screen memory. Two bytes required for 16 bit'' 65K color mode  OUTA[WR_OLED] := 0  OUTA[7..0] := wordData.byte[1]                 ' MSB  OUTA[WR_OLED] := 1  OUTA[WR_OLED] := 0  OUTA[7..0] := wordData.byte[0]                 ' LSB  OUTA[WR_OLED] := 1PUB Set_Contrast (Value)  Write_cmd(CONTRAST_MASTER)                     ' Set master contrast 0 to 15, default = 15  Write_cmd($0f and Value)PUB Set_Contrast_RGB (RCont, GCont, BCont)  Write_cmd(CONTRAST_RED)                        ' Set contrast current for Red, default = 255   Write_cmd(RCont)    Write_cmd(CONTRAST_GREEN)                      ' Set contrast current for Green, default = 255   Write_cmd(GCont)    Write_cmd(CONTRAST_BLUE)                       ' Set contrast current for Blue, default = 255   Write_cmd(BCont)PUB PutPixel (X,Y, R,G,B)'' Writes 2 bytes (16 bits) of color data to the upper-left corner (X,Y) of the area in'' Graphic RAM defined by the Set_GRAM_Access method.'' Puts a single pixel of colour R,G,B at screen coordinates X,Y  R := ((R >> 3)<<11)|((G >> 2)<<5)|(B >> 3)     ' Convert R,G,B to 16 bit color  Set_GRAM_Access (X, 95, Y, 63)                  '  OUTA[D_C] := 1  OUTA[CS_OLED] := 0  OUTA[WR_OLED] := 0  OUTA[7..0] := R.byte[1]                        ' MSB  OUTA[WR_OLED] := 1  OUTA[WR_OLED] := 0  OUTA[7..0] := R.byte[0]                        ' LSB  OUTA[WR_OLED] := 1  OUTA[CS_OLED] := 1PUB PutChar(Char,X,Y,FONT, R,G,B) | row,col''Where: X : Text Column (0-11 for 8x8 font, 0-15 for 5x7 font) ''       Y : Text Row (0-7 for 8x8 & 5x7 fonts)   Char := (Char - " ") << 3   if FONT                                              ' font 1 8x8       X <<= 3                                           ' x 8      Y <<= 3                                           ' x 8      repeat row from 0 to 7         repeat col from 0 to 7            if font_8x8[Char+row] & $80 >> col               PutPixel(X+col,Y+row, R,G,B)   else                                                 ' font 0 5x7      X *= 6                                            ' x 6      Y *= 8                                            ' x 7      repeat row from 0 to 7         repeat col from 1 to 6            if font_5x7[Char+row] & $01 << col               PutPixel(X+col,Y+row, R,G,B)               PUB PutText (X,Y,FONT, R,G,B, STR) | Temp''Where: X : Text Column (0-11 for 8x8 font, 0-15 for 5x7 font)''       Y : Text Row (0-7 for 8x8 & 5x7 fonts)  repeat strsize(STR)    PutChar((byte[STR++]),X++,Y,FONT, R,G,B)     if FONT        if X > 95 / 8          X := 0          Y += 1     elseif X > 95 / 6       X := 0       Y += 1PUB Line (X1,Y1,X2,Y2, R,G,B)'' Inbuilt graphics command using the Write_cmd method to shift out the command and data required'' by the display controllerR := R >> 2                                     ' Only need the top 5 bits for REDG := G >> 2                                     ' Only need the top 6 bits for GREENB := B >> 2                                     ' Only need the top 5 bits for BLUE  Write_cmd(DRAW_LINE)                          ' Draw Line mode  Write_cmd(X1)                                 ' set x1  Write_cmd(Y1)                                 ' set y1  Write_cmd(X2)                                 ' set x2  Write_cmd(Y2)                                 ' set y2  Write_cmd(R)                                  ' set Line colour red  Write_cmd(G)                                  ' set Line colour green  Write_cmd(B)                                  ' set Line colour blue  DELAY.PauseMSec(1)  PUB Rectangle (X1,Y1,X2,Y2,FILL, R,G,B)'' Inbuilt graphics command using the Write_cmd method to shift out the command and data required'' by the display controller'' Note that although the inbuilt command supports seperate fill and outline colors,this method'' uses the supplied RGB values for both. *** Nothing to prevent you from creating a new methode that'' implements the outline color capability, right?***  R := R >> 2                                   ' Only need the top 5 bits for RED  G := G >> 2                                   ' Only need the top 6 bits for GREEN  B := B >> 2                                   ' Only need the top 5 bits for BLUE  Write_cmd(FILL_ENABLE_DISABLE)                ' Solid or Empty rectangel  if(FILL)    Write_cmd(0)                                ' FILL = 1 (TRUE) : Empty  else    Write_cmd(1)                                ' FILL = 0 (FALSE) : Solid           Write_cmd(DRAW_RECTANGLE)                     ' Draw Rectangle mode  Write_cmd(X1)                                 ' set x1  Write_cmd(Y1)                                 ' set y1  Write_cmd(X2)                                 ' set x2  Write_cmd(Y2)                                 ' set y2  Write_cmd(R)                                  ' set outline colour red  Write_cmd(G)                                  ' set outline colour green  Write_cmd(B)                                  ' set outline colour blue  Write_cmd(R)                                  ' set fill colour red  Write_cmd(G)                                  ' set fill colour green  Write_cmd(B)                                  ' set fill colour blue  DELAY.PauseMSec(1)PUB Copy (x1s, y1s, x2s, y2s, x1d, y1d)'' Copies a part of the screen from one screen location to another.'' where:''      x1s = Top Left horizontal location of source''      y1s = Top Left vertical location of source''      x2s = Bottom Right horizontal location of source''      y2s = Bottom Right vertical location of source''      x1d = Top Left horizontal location of destination''      y1d = Top Left vertical location of destination  Write_cmd(COPY_AREA)                          ' Copy mode  Write_cmd(x1s)                                ' set x1s  Write_cmd(y1s)                                ' set y1s  Write_cmd(x2s)                                ' set x2s  Write_cmd(y2s)                                ' set y2s  Write_cmd(x1d)                                ' set x1d  Write_cmd(y1d)                                ' set y1d  DELAY.PauseMSec(1)  PUB DimWindow (x1, y1, x2, y2)'' This command will dim the window area specified by a'' starting point (x1, y1) and the ending point (x2, y2).'' After executing this command, the selected window area will become darker as a result.  Write_cmd(DIM_WINDOW)                         ' Dim Window mode  Write_cmd(x1)                                 ' set x1s  Write_cmd(y1)                                 ' set y1s  Write_cmd(x2)                                 ' set x2s  Write_cmd(y2)                                 ' set y2s  DELAY.PauseMSec(1)  PUB ScrollSetup (horizontal, vertical, lineStart, lines2scroll, interval)'' This command sets up the parameters required for horizontal and vertical scrolling.'' where:''      horizontal: Set number of columns as horizontal scroll offset''                  range: 0dec..95dec (no horizontal scroll if set to 0)''''      lineStart:  Define start line address''''      lines2scroll: Set number of lines to be horizontally scrolled''                    note: lineStart+lines2scroll <= 64''''      vertical: Set number of lines as vertical scroll offset''                range: 0dec..63dec (no vertical scroll if set to 0)''''      interval: Set time interval between each scroll step''                0 = 6 frames''                1 = 10 frames''                2 = 100 frames''                3 = 200 frames          Write_cmd(SCROLL_SETUP)                       ' Scroll Setup mode  Write_cmd(horizontal)                         ' set horizontal  Write_cmd(lineStart)                          ' set lineStart  Write_cmd(lines2scroll)                       ' set lines2scroll  Write_cmd(vertical)                           ' set vertical  Write_cmd(interval)                           ' set interval PUB ScrollStart'' This command activates the scrolling function according to the settings made'' by ScrollSetup(,,,) method.  Write_cmd(START_SCROLL)                       ' Start the Scrolling Function    PUB ScrollStop'' This command deactivates the scrolling function.  Write_cmd(STOP_SCROLL)                        ' Stop the Scrolling FunctionPUB CLS'' Using the Rectangle methode above, draws a black rectangle (solid) the size of the active screen'' to clear all data from the screen (screen erase).                                  Rectangle (0,0,95,63,0, 0,0,0)                ' Draws a Black rectangle (filled) from screen min(0,0) to screen max(95,63)    PUB Circle (X,Y,Rad,FILL, R,G,B)'' The code for this method is not "missing".'' This is the first challenge...implement a Circle function'' using the supplied prematives above.