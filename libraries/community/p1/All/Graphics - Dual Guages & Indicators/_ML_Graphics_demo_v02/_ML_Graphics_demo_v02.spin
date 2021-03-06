''***************************************
''*  Gage Demo                          *
''*  Author: Michael Lord               *
''*  Copyright (c) 2011 Michael Lord    *               
''*  See end of file for terms of use.  *               
''***************************************
{{    This code was written by Michael Lord 650-219-6467 and inspired by code that
      the Sea Scouts used written by Gregg Erickson. My contribution is to turn it
      into an object the is more universal. 

      If you want to improve this object such as setting scale range to Constants to make it easy to use,
      or other things,
      you can email the improved version to me with a note. I will test the improved ver and replace this one
      with it if  it seems to work.

      Mike@electronicdesignservice.com
      650-219-6467

 }}
 
CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  '_stack = ($3000 + $3000 + 100) >> 2   'accomodate display memory and stack

  _stack = ($4000 +342) >> 2          ' Set Stack large enough for display and variables



  x_tiles = 16
  y_tiles = 12

  paramcount = 14       
  bitmap_base = $2000
  display_base = $5000

  lines = 5
  thickness = 2


   Guage1X =-70                        ' Gauge1 X Location 
   Guage1Y = 37                        ' Gauge1 Y Location 
   Guage1R = 57                         ' Gauge1 Radius, e.g. diameter


  
   Guage2X = 70                        ' Gauge2 X Location 
   Guage2Y = 37                        ' Gauge2 Y Location 
   Guage2R = 57                         ' Gauge2 Radius, e.g. diameter
  
   Title1X  =  -70                      ' Amps Title X Location
   Title1Y  =  -30                        ' Amps Title Y Location

   Title2X  =  75                        ' Volts Title X Location
   Title2Y  =  -30                        ' Volts Title Y Location


  
  Scale=   4                          ' Number x 200 = Maximum Gauge Scale
  GaugeScale=16_777_216               ' 2?? 256
  

  TvPin       =   24     'Pin for TV    Control Prop

      
  
VAR

  long  mousex, mousey

  long  tv_status     '0/1/2 = off/visible/invisible           read-only
  long  tv_enable     '0/? = off/on                            write-only
  long  tv_pins       '%ppmmm = pins                           write-only
  long  tv_mode       '%ccinp = chroma,interlace,ntsc/pal,swap write-only
  long  tv_screen     'pointer to screen (words)               write-only
  long  tv_colors     'pointer to colors (longs)               write-only               
  long  tv_hc         'horizontal cells                        write-only
  long  tv_vc         'vertical cells                          write-only
  long  tv_hx         'horizontal cell expansion               write-only
  long  tv_vx         'vertical cell expansion                 write-only
  long  tv_ho         'horizontal offset                       write-only
  long  tv_vo         'vertical offset                         write-only
  long  tv_broadcast  'broadcast frequency (Hz)                write-only
  long  tv_auralcog   'aural fm cog                            write-only

  word  screen[x_tiles * y_tiles]
  long  colors[64]

  byte  x[lines]
  byte  y[lines]
  byte  xs[lines]
  byte  ys[lines]


'Confirmed Vars
 ' Long   GuageVal[5]       '0 is guage1 display value
                           '1 is guage2 display value
                           '2 is indicator1
                           '3 is indicator2
                           '4 is basepin for tv

  
  ' long stack1[250] 
   long CogNr

   Long  OldGuage1Val
   Long  OldGuage2Val





OBJ

  tv    : "tv"
  gr    : "graphics"
  Num   : "Numbers"                   ' Create string bytes for display






         
'==================================================================
PUB Main_Program | index1, index2, inc1, inc2 ,  A_Val, B_Val, indicator1, indicator2
'==================================================================
'This is the main object in the running program that generates the values to display

   initialize                 

  Indicator1 := 2
  Indicator2 := 516 
  index1 := 100
  index2 := 10
  Inc1  := 5
  Inc2  := 4
             ' A_Val  := 100
              'B_Val  := 100


      repeat
             
      
    
              index1 := index1 + Inc1
                if  index1 > 600 
                    Inc1 := ( -5 )
                    Indicator1 := 2 
                elseif  index1 < 3   
                    Inc1 := (  5 )
                    Indicator1 := 1 
                   
                       
              index2 :=  index2 + Inc2
                if  index2 > 600 
                    Inc2 := ( -4 )
                    
                elseif  index2 < 3   
                    Inc2 := (  4 )
                    
  
              A_Val  := index1
              B_Val  := index2
   
              DiaplayGauges( A_Val, B_Val, indicator1, indicator2 )
              
           '   waitcnt(clkfreq  + cnt)
         
'==================================================================
PUB DiaplayGauges( A_Val, B_Val, indicator1, indicator2 ) | i, j, k, kk, dx, dy, pp, pq, rr, numx ,index1, index2, inc1, inc2
'==================================================================



           '-------- start display ------------------------------ 



      
         'clear bitmap
          gr.clear


            '------------------draw Max Watts box with text-----------------
          gr.colorwidth(1,14)
          '' Draw a box with round/square corners, according to pixel width 
          gr.box(40,-90,80,26)     'box(x, y, box_width, box_height) 

          gr.textmode(1,1,6,5)       'textmode(x_scale, y_scale, spacing, justification)  
          gr.colorwidth(2,0)          'colorwidth(c, w)  color and width
          gr.text(80,-55, @MaxWatts)  ' text(x, y, string_ptr) 
 
          gr.textmode(2,2,6,5)       'textmode(x_scale, y_scale, spacing, justification)  
          gr.colorwidth(2,1)          'colorwidth(c, w)  color and width
          gr.text(75,-77,Num.ToStr(Indicator2,%000_000_000_0_0_000100_01010))   ' text(x, y, string_ptr)





                  ' ----------------numchr1  ------------------------
          gr.textmode(1,1,6,5)       'textmode(x_scale, y_scale, spacing, justification)  
          gr.colorwidth(2,0)          'colorwidth(c, w)  color and width

          gr.text(-90,-60, @LightFactor)  ' text(x, y, string_ptr) 
          gr.text(-20,-60,Num.ToStr(Indicator2,%000_000_000_0_0_000100_01010))   ' text(x, y, string_ptr)

          gr.text(-95,-75, @TempFactor)  ' text(x, y, string_ptr) 
          gr.text(-20,-75,Num.ToStr(Indicator2,%000_000_000_0_0_000100_01010))   ' text(x, y, string_ptr)

          gr.text(-95,-90, @DutyCycle)  ' text(x, y, string_ptr) 
          gr.text(-20,-90,Num.ToStr(Indicator2,%000_000_000_0_0_000100_01010))   ' text(x, y, string_ptr)



                                     

            '-----------Draw Static Titles ---------------------
             'draw title box
              gr.textmode(1,1,6,5)          'Set text properties
              gr.colorwidth(2,0)            'Set text color and width
              gr.text(Title1X,Title1Y,@Amps) 'Write Pitch Label
              gr.text(Title2X,Title2Y,@Volts)     'Write Roll Label



           '----------Draw Static Part of Gauges ------------------------------
           '(note: 1 degree is about 23 ticks for angle calculation ) ----------

              gr.color(2)
              gr.arc(Guage1X,Guage1Y,Guage1R,Guage1R,0,23,360,0)           'Draw Port Dial 
              gr.arc(Guage2X,Guage2Y,Guage2R,Guage2R,0,23,360,0)           'Draw Starboard Dial
              repeat i from -100 to 200 step 10
                    gr.arc(Guage1X,Guage1Y,Guage1R,Guage1R,23*i,23,1,0)        'Draw Port Rotational Ticks
                    gr.arc(Guage1X,Guage1Y,Guage1R-5,Guage1R-5,23*i,23,1,1)
                    gr.arc(Guage2X,Guage2Y,Guage2R,Guage2R,23*i,23,1,0)        'Draw Starbard Rotational Ticks
                    gr.arc(Guage2X,Guage2Y,Guage2R-5,Guage2R-5,23*i,23,1,1)
                 if i//50==0
                     gr.arc(Guage1X,Guage1Y,Guage1R,Guage1R,23*i,23,1,0)      'Draw Port Large Ticks
                     gr.arc(Guage1X,Guage1Y,Guage1R-10,Guage1R-10,23*i,23,1,1)
                     gr.arc(Guage2X,Guage2Y,Guage2R,Guage2R,23*i,23,1,0)      'Draw Starboard Large Tick
                     gr.arc(Guage2X,Guage2Y,Guage2R-10,Guage2R-10,23*i,23,1,1)







    '-----Clear Old Needle and Numbers with Background Color---

           gr.color(0)
           gr.box(Guage2X-30,Guage2Y+10,50,30)  ' Clear RPM Numbers
           gr.box(Guage1X-30,Guage1Y+10,50,30)

           gr.box(Guage2X-25,Guage2Y-25,57,10)  ' Clear Revolutin Odometer
           gr.box(Guage1X-25,Guage1Y-25,57,10)

                                     ' Clear Shift Count
           gr.box(Guage2X-25,Guage2Y-45,50,20)
           gr.box(Guage1X-25,Guage1Y-45,50,20)

   
           gr.colorwidth(0,0)               ' Clear Needle
           gr.arc(Guage1X,Guage1Y,Guage1R-16,Guage1R-16,23*(200-(||OldGuage1Val)/2),23,4,3)      'Draw Starboard Needle
           gr.arc(Guage2X,Guage2Y,Guage2R-16,Guage2R-16,23*(200-(||OldGuage2Val)/2),23,4,3)
           OldGuage2Val:=B_Val 
           OldGuage1Val:=A_Val

   
      

    '------ Draw Needles-----


                 if A_Val>0
                      gr.colorwidth(1,0)
                 else
                      gr.colorwidth(2,0)                                                      'Set Gauge Color and Thickness
            gr.arc(Guage1X,Guage1Y,Guage1R-16,Guage1R-16,23*(200-(||A_Val)/2),23,4,3)      'Draw Starboard Needle
                if B_Val >0
                      gr.colorwidth(1,0)
                else
                      gr.colorwidth(2,0)

             gr.arc(Guage2X,Guage2Y,Guage2R-16,Guage2R-16,23*(200-(||B_Val )/2),23,4,3)

   
    
      
     '---- Gauge Pivot Pins ---
    
             gr.colorwidth(1,12)            'Thick pivot pin like real gauge
             gr.plot(Guage1X,Guage1Y)          'Draw Port Pivot
             gr.plot(Guage2X,Guage2Y)          'Draw Starboard Pivot
         
  
    '---- Gauge Values Numbers ---

                if B_Val >200
                      gr.colorwidth(2,0)
                else
                      gr.colorwidth(1,0)
            gr.textmode(2,3,6,5)
            gr.text(Guage2X-5,Guage2Y+25,Num.ToStr(B_Val ,%000_000_000_0_0_000100_01010)) 'Convert and Post Starboard Revolutions
            gr.finish
                                                            'Set Gauge Color and Thickness
                 if A_Val>200
                      gr.colorwidth(2,0)
                 else
                      gr.colorwidth(1,0)
            gr.text(Guage1X-5,Guage1Y+25,Num.ToStr(A_Val,%000_000_000_0_0_000100_01010)) 'Convert and Post Starboard Revolutions
            gr.finish



            '------------------draw Status box with text-----------------
          gr.colorwidth(1,14)
          '' Draw a box with round/square corners, according to pixel width 
          gr.box(-40,70,80,26)     'box(x, y, box_width, box_height) 
          gr.textmode(2,2,6,5)      'textmode(x_scale, y_scale, spacing, justification) 
          gr.colorwidth(2,0)        'colorwidth(c, w)  color and width  
              if Indicator1 == 1
                    gr.text(0,85,@Testing)             ' text(x, y, string_ptr)
              elseif Indicator1 == 2
                    gr.text(0,85,@Idle)
              elseif Indicator1 == 3
                    gr.text(90,-72,@Failed)
 


          'copy bitmap to display
          gr.copy(display_base)
          'increment counter that makes everything change
          k++

         
'==================================================================
PUB Initialize   |   dx , i,  dy  
'==================================================================




   'tvparams[2] := (GuageVal[4]  & $38) << 1 | (GuageVal[4]  & 4 == 4) & %0101 
   'tvparams[2] := ( 24  & $38) << 1 | ( 24  & 4 == 4) & %0101 
   tvparams[2] := ( TvPin  & $38) << 1 | ( TvPin & 4 == 4) & %0101 


''''constants that need def
   OldGuage1Val := 0
   OldGuage2Val := 0 



  'start tv
  longmove(@tv_status, @tvparams, paramcount)
  tv_screen := @screen
  tv_colors := @colors
  tv.start(@tv_status)

  'init colors
  repeat i from 0 to 63
    colors[i] := $00001010 * (i+4) & $F + $2B060C02

  'init tile screen
  repeat dx from 0 to tv_hc - 1
    repeat dy from 0 to tv_vc - 1
      screen[dy * tv_hc + dx] := display_base >> 6 + dy + dx * tv_vc + ((dy & $3F) << 10)
    
  'start and setup graphics
  gr.start
  gr.setup(16, 12, 128, 96, bitmap_base)

  Num.init                                  'Start Numbers conversion object









          
'==================================================================
DAT
'==================================================================

tvparams                long    0               'status
                        long    1               'enable
                        long    0               'pins            %001_0101    21     35 
                        long    %0000           'mode
                        long    0               'screen
                        long    0               'colors
                        long    x_tiles         'hc
                        long    y_tiles         'vc
                        long    10              'hx
                        long    1               'vx
                        long    0               'ho
                        long    0               'vo
                        long    0               'broadcast
                        long    0               'auralcog


                        
'pchip                   byte    "Propeller",0           'text

pitch                   byte    "Pitch",0         'text
roll                    byte    "Roll",0         'text

numchr1                 Byte     "519" ,0

Testing                 Byte     "Testing" ,0 
Passed                  Byte     "Passed" ,0 
Failed                  Byte     "Failed" ,0 
Amps                    Byte     "Amps" ,0 
Volts                   Byte     "Volts" ,0 
Watts                   Byte     "Watts" ,0
Complete                Byte     "Complete" ,0 

LightFactor             Byte     "Light Factor" ,0
TempFactor              Byte     "Temp Factor" ,0 
DutyCycle               Byte     "Duty Cycle" ,0 
MaxWatts                Byte     "Maximum Watts" ,0 
Idle                    Byte     "Idle" ,0



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