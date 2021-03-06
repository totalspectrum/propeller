{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐               
│ Quadrature Encoder (4 channel)                                                                                              │
│                                                                                                                             │
│ Author: Richard Schultz                                                                                                     │                              
│ Updated: 26 June 2008                                                                                                       │
│ Designed For: P8X32A                                                                                                        │
│                                                                                                                             │
│ Copyright (c) 2010 Richard F. Schultz                                                                                       │              
│ See end of file for terms of use.                                                                                           │               
│                                                                                                                             │
│ Program Info:                                                                                                               │
│                                                                                                                             │
│ 6 additional objects are used from the object exchange and have been modified to varying degrees or gutted and              │                                                                                                             │
│ incorporated into the main program. All are prefixed by "qdro_"                                                             │
│                                                                                                                             │
│                                                                                                                             │
│ RFS                                                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘


QDRO   VER.1.0
----

QDRO IS A 4 AXIS QUADRATURE ENCODER DISPLAY DESIGNED FOR USE WITH LINEAR AND ROTARY 
ENCODERS.  THE ENCODERS MUST WORK WITH 5 VOLTS.

THE STARTUP SCREEN DISPLAYS BOTH ABSOLUTE AND RELATIVE READOUTS.  

BOTH ABSOLUTE AND RELATIVE READOUTS CAN BE EDITED.  THE FOLLOWING ATTRIBUTES MAY BE CHANGED:

        UNITS (COUNTS, DEGREES, INCHES, AND MILLIMETERS)
        DECIMAL PLACES (0-4), SIGN (+/-)
        CALIBRATION (UNITS PER STEP)
        OFFSET

THE RELATIVE READOUTS ARE SLAVED TO THE ABSOLUTE READOUTS THROUGH THE ENCODER COUNTERS.
CHANGING ENCODER COUNTER VALUES WILL AFFECT BOTH ABSOLUTE AND RELATIVE READOUTS.

}}


CON

  _clkmode        = xtal1 + pll16x                                                  
  _xinfreq        = 5_000_000 
  _stack          = 100  ' may get rid of this
  positive_chr    = "+"  ' + or - signs precedes number
  decimal_chr     = "."  ' sets decimal point character
  thousands_chr   = 0    ' sets thousands separator character ie. 1,000,000
  thousandths_chr = 0    ' sets thousandths separator character ie. 1.000,000
 

OBJ

  text    : "qdro_vga_text"
  encoder : "qdro_rotary_Encoder"
  kb      : "qdro_keyboard"      
  i2c     : "qdro_basic_I2C_Driver"
  fm      : "qdro_float32"       
  cogs    : "qdro_sparecogs"


VAR

  long                eepromaddress                ' address within eeprom to begin r/w
  long                offset[8]                    ' offset from working or absolute values  
  long                cpu[8]                       ' counts per unit for x,y,z,a axes, abs + rel
  long                sign[8]                      ' '+1.0 or -1.0'  change sign of readout         
  long                units[8]                     ' address pointer for counts, in, mm, deg label 
  long                pos[4]                       ' main memory buffer of 4 encoder results
  long                cal_x[4]                     ' x axis calibration for cnt, deg, in, mm 
  long                cal_y[4]                     ' y axis calibration for cnt, deg, in, mm
  long                cal_z[4]                     ' z axis calibration for cnt, deg, in, mm
  long                cal_a[4]                     ' a axis calibration for cnt, deg, in, mm
  long                dp_cnt                       ' decimal point for counts
  long                dp_deg                       ' decimal point for degrees
  long                dp_in                        ' decimal point for inches
  long                dp_mm                        ' decimal point for millimeters  
  long                readout[8]                   ' calculated position to display  
  long                size                         ' # of digits in the # input routine (0-9)     
  long                index, index1, index2      
  long                number_of_cogs               ' number of free cogs (0-7)                       
  long                begin                        ' start count
  long                end                          ' end count
  long                fp_number                    ' floating point number
  long                new_cpu                      ' new counts per unit value  
  long                p, digits, exponent, integer ' from float_to_string routine
  long                tens, zeros,  precision      ' from float_to_string routine 
  long                units_to_move                ' # units ie mm's to move in calibration of axis
  long                title                        ' address pointer for title string data
  long                temp_cpu                     ' temporarily holds current cpu[axis]
  long                temp_units                   ' temporarily holds current units[axis] 
  long                value                        ' holds number of decimal points
  long                in_cal[4]                    ' holds all inch calibration values for x,y,z,a axes
  long                mm_cal[4]                    ' holds all mm calibration values for x,y,z,a axes
  long                file_type[6]                 ' pointer for mill, lathe, or blank
  long                file_default[6]              ' holds value for default-file yes/no
  
  byte                d_p[8]                       ' # of decimal points (0-4)
  byte                display_type                 ' mill or lathe screen (1 or 2)    
  byte                axis                         ' x,y,z,a axis (0-3)
  byte                display                      ' readout(display) (0-7)
  byte                cog                          ' id of newly started cog (0-7)
  byte                input                        ' key pressed on keyboard      
  byte                keypress                     ' key pressed on keyboard
  byte                block                        ' holds # of eepromaddress 128 byte block
  byte                file_number                  ' # of the file to be saved or written
  byte                buffer[128]                  ' i2c read/write buffer 
  byte                float_string[20]             ' needed by float to format routine in floatstring
  byte                total_digits                 ' used in edit # method, total digits to display (0-9)
  byte                decimal_point                ' used in edit # method, number of decimal points (0-9)
  byte                flag
  byte                sign_character[8]            ' holds sign character (+ or -) 
  byte                startup_screen               ' switch for starting up in display mode ( = 1)
  byte                password[3]                  ' contains entered password     

'==================================================================================================                                      

' Paramaters          number, address, fp_number
'                     left, top, width, height, color

' Local variables     row, column, starttime, c, n, wz, i. a, b, c, d, ptr
'                     dp, pos_sign, neg_sign

' Returns             stringptr
'
'==================================================================================================


DAT
                       
 cnt_ptr        byte      "cnt", 0
 deg_ptr        byte      "deg", 0 
 in_ptr         byte      " in", 0
 mm_ptr         byte      " mm", 0
 
 lathe          byte      "LATHE",0
 mill           byte      "MILL ",0
 blank          byte      "-----",0

 read           byte      "   READ FILE #",0
 write          byte      " WRITE TO FILE #",0
 delete         byte      "   DELETE FILE #",0 
 default        byte      "MAKE FILE # DEFAULT",0
 
 default_no     byte      "---",0
 default_yes    byte      "-X-",0

 sys_password   byte      "555",0
  
 abs_x          byte      "ABS. X/X AXIS",0
 abs_y          byte      "ABS. Y/Z1 AXIS",0
 abs_z          byte      "ABS. Z/Z2 AXIS",0
 abs_a          byte      "ABS. A/A AXIS",0
 rel_x          byte      "REL. X/X AXIS",0
 rel_y          byte      "REL. Y/Z1 AXIS",0
 rel_z          byte      "REL. Z/Z2 AXIS",0
 rel_a          byte      "REL. A/A AXIS",0

 x_axis         byte      "X AXIS", 0
 y_axis         byte      "Y AXIS", 0
 z_axis         byte      "Z AXIS", 0
 a_axis         byte      "A AXIS", 0
 
 divisors       long      1.0, 10.0, 100.0, 1_000.0, 10_000.0, 100_000.0 
                long      1_000_000.0, 10_000_000.0

' floatstring DAT

        long                1e+38, 1e+37, 1e+36, 1e+35, 1e+34, 1e+33, 1e+32, 1e+31
        long  1e+30, 1e+29, 1e+28, 1e+27, 1e+26, 1e+25, 1e+24, 1e+23, 1e+22, 1e+21
        long  1e+20, 1e+19, 1e+18, 1e+17, 1e+16, 1e+15, 1e+14, 1e+13, 1e+12, 1e+11
        long  1e+10, 1e+09, 1e+08, 1e+07, 1e+06, 1e+05, 1e+04, 1e+03, 1e+02, 1e+01
  tenf  long  1e+00, 1e-01, 1e-02, 1e-03, 1e-04, 1e-05, 1e-06, 1e-07, 1e-08, 1e-09
        long  1e-10, 1e-11, 1e-12, 1e-13, 1e-14, 1e-15, 1e-16, 1e-17, 1e-18, 1e-19
        long  1e-20, 1e-21, 1e-22, 1e-23, 1e-24, 1e-25, 1e-26, 1e-27, 1e-28, 1e-29
        long  1e-30, 1e-31, 1e-32, 1e-33, 1e-34, 1e-35, 1e-36, 1e-37, 1e-38

  teni  long  1, 10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000, 100_000_000, 1_000_000_000

        byte "yzafpnum"
  metri byte 0
        byte "kMGTPEZY"



''
''=================================================================================================
''                        START OBJECTS / INITIALIZE VARIABLES
''=================================================================================================
''

PUB Start_qdro

  initialize_variables

   
'' Start the DRO_ROTARY_ENCODER program, passing to it the startpin (start pin where the
'' first encoder is connected), number of encoders, number of encoders needing the
'' delta feature, and the address of the buffer of longs in main memory where each
'' encoder's position (and delta position, if any) is to be stored.
  
  encoder.start(0, 4, 0, @pos)

'' Start Floating Point math routines (float32)
  
  fm.start
  
'' Start the KEYBOARD program passing to it the dpin and cpin pin numbers, the lock setup,
'' and the auto-repeat setup
 
  kb.startx(26, 27, %1_111_110, %11_11100)

'' Start the modified VGA_TEXT program passing to it the basepin number

  text.start(16)

'' Start the BASIC_I2C_DRIVER eeprom read/write program passing to it the SCL pin number

  i2c.initialize(28)                   ' initialize basic_i2c_driver
  i2c.start(28)                        ' start basic_i2c_driver

'' Display mill screen on startup
  
  display_type   := 1                  ' mill screen is default
  startup_screen := 1                  ' 1 = display mode, 0 = menu mode

'' Begin program
                                           
  repeat 
    \main_menu                         ' return from abort command in menu tree
 

PUB Initialize_variables

'' pos    = position of encoder
'' cpu    = counts per unit i.e. 5080 counts per inch, 200 counts per mm
'' offset = offset of particular axis
'' sign   = used to change the sign (+/-) of an encoder
'' d_p    = decimal point
  
  repeat index from 0 to 7 step 1
    d_p[index]     := 4
    offset[index]  := 0.0
    sign[index]    := 1.0
    cpu[index]     := 5080.0
    units[index]   := @in_ptr

  repeat index from 0 to 3 step 1
    pos[index] := 0


'' Setup default 'units' # of decimal points 

  dp_cnt := 0
  dp_deg := 2
  dp_in  := 4
  dp_mm  := 3   

'' Set up default steps/unit table

'     x           y           z           a
' --------    --------    --------    --------
  cal_x[0] := cal_y[0] := cal_z[0] := cal_a[0] := 1.0       ' cnt
  cal_x[1] := cal_y[1] := cal_z[1] := cal_a[1] := 1.0       ' deg
  cal_x[2] := cal_y[2] := cal_z[2] := cal_a[2] := 5080.0    ' in
  cal_x[3] := cal_y[3] := cal_z[3] := cal_a[3] := 200.0     ' mm

'' initialize file table with no entries and no default file

  repeat index from 0 to 5 step 1
    file_type[index] := @blank
    file_default[index] := @default_no 

''
''=================================================================================================
''                                 MENU SELECTION - LEVEL 1  (black)
''=================================================================================================
''

PUB Main_menu  

'' Choices: 1-display readouts, 2-zero encoders, 3-set scale,
'' 4-program options, 5-axis setup, 6-file (store/retrieve),
'' 7-special functions
 
  main_menu_screen

  if startup_screen == 1               ' startup in display mode     
    paint_black_screen                                           
    if display_type == 1               ' display mill screen                
      mill_screen                                                
    if display_type == 2               ' display lathe screen               
      lathe_screen
    startup_screen := 0                ' now turn off startup in display mode                                               
    axis_units_screen                  ' display the axis scale labels 
    display_results                    ' display the readout results
    
  repeat
    input := kb.getkey
    case input     
      $31:                             ' 1 ... display readouts
        paint_black_screen                                   
        if display_type == 1    
          mill_screen                  ' display mill screen
        else
          lathe_screen                 ' display lathe screen 
        axis_units_screen              ' display the axis scale labels
        display_results                ' display the readout results
      $32:                             ' 2 ... zero enc. menu
        zero_encoders_menu
      $33:                             ' 3 ... set scale, ie inches/mm
        change_scale_menu 
      $34:                             ' 4 ... program options menu
        program_options_menu   
      $35:                             ' 5 ... axis setup menu
        axis_setup_menu
      $36:                             ' 6 ... file menu
        file_menu
      $37:                             ' 7 ... special functions menu
        special_functions_menu
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen

''
''=================================================================================================
''                                 MENU SELECTION - LEVEL 2  (blue)
''=================================================================================================
''

PUB Zero_encoders_menu          

'' From menu level - 1, main_menu - 2
'' Choices: zero 1-abs + rel readouts, 2-zero abs readouts, 3-zero rel readouts

  zero_encoders_screen  
  repeat
    input := kb.getkey
    case input     
      $31:                             ' 1 ... zero abs. + rel. readouts
        Zero_all_encoders_menu
        main_menu_screen
        zero_encoders_screen  
      $32:                             ' 2 ... zero abs. readouts
        zero_abs_encoders_menu
        main_menu_screen
        zero_encoders_screen        
      $33:                             ' 3 ... zero rel. readouts
        zero_rel_encoders_menu
        main_menu_screen
        zero_encoders_screen                                
      $30:                             ' 0 ... to main_menu
        abort 
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        zero_encoders_screen

PUB Change_scale_menu

'' From menu level - 1, main_menu - 3
'' Choices: 1=mm->in abs + rel, 2=mm->in abs, 3=mm->in rel
'' 4=in->mm abs + rel, 5=in->mm abs, 6=in->mm rel

  in_cal[0] := cal_x[2]                ' save all inch calibration values in in_cal[0-3]
  in_cal[1] := cal_y[2]                ' for axes x,y,z,a
  in_cal[2] := cal_z[2]
  in_cal[3] := cal_a[2]

  mm_cal[0] := cal_x[3]                ' save all mm calibration values in mm_cal[0-3]
  mm_cal[1] := cal_y[3]                ' for axes x,y,z,a
  mm_cal[2] := cal_z[3]
  mm_cal[3] := cal_a[3]

  change_scale_screen  
  repeat
    text.str(string($A,8,$B,3,$C,2))   ' print units[0-7]
    text.str(units[0])
    text.str(string($A,14,$B,3,$C,2))
    text.str(units[1])
    text.str(string($A,20,$B,3,$C,2))
    text.str(units[2])
    text.str(string($A,26,$B,3,$C,2))
    text.str(units[3])
    text.str(string($A,8,$B,4,$C,2))
    text.str(units[4])
    text.str(string($A,14,$B,4,$C,2))
    text.str(units[5])
    text.str(string($A,20,$B,4,$C,2))
    text.str(units[6])
    text.str(string($A,26,$B,4,$C,2))
    text.str(units[7])
 
    if kb.gotkey 
      input := kb.getkey
      case input
        $31:                           ' 1 ... mm -> in, abs. + rel.
          repeat index from 0 to 7
            if units[index] == @mm_ptr
              units[index] := @in_ptr
              d_p[index] := dp_in
              offset[index] := fm.fdiv(offset[index],25.4)
              if index < 4
                cpu[index] := in_cal[index]
              else
                cpu[index] := in_cal[index-4]                
        $32:                           ' 2 ... mm -> in, abs.
          repeat index from 0 to 3
            if units[index] == @mm_ptr
              units[index] := @in_ptr
              d_p[index] := dp_in
              offset[index] := fm.fdiv(offset[index],25.4)
              cpu[index] := in_cal[index]
        $33:                           ' 3 ... mm -> in, rel.
          repeat index from 4 to 7
            if units[index] == @mm_ptr
              units[index] := @in_ptr
              d_p[index] := dp_in
              offset[index] := fm.fdiv(offset[index],25.4)
              cpu[index] := in_cal[index-4]
        $34:                           ' 4 ... in -> mm, abs. + rel.
           repeat index from 0 to 7
            if units[index] == @in_ptr
              units[index] := @mm_ptr
              d_p[index] := dp_mm
              offset[index] := fm.fmul(offset[index],25.4)
              if index < 4
                cpu[index] := mm_cal[index]
              else
                cpu[index] := mm_cal[index-4]     
        $35:                           ' 5 ... in -> mm, abs
          repeat index from 0 to 3
            if units[index] == @in_ptr
              units[index] := @mm_ptr
              d_p[index] := dp_mm
              offset[index] := fm.fmul(offset[index],25.4)
              cpu[index] := mm_cal[index]
        $36:                           ' 6 ... in -> mm, rel
          repeat index from 4 to 7
            if units[index] == @in_ptr
              units[index] := @mm_ptr
              d_p[index] := dp_mm
              offset[index] := fm.fmul(offset[index],25.4)
              cpu[index] := mm_cal[index-4]
        $30:                           ' 0 ... to main_menu
          abort    
        other:                         ' ..... wrong command
          wrong_command_screen
  '        main_menu_screen            ' refresh screen
          change_scale_screen
                                    


PUB Program_options_menu        

'' From menu level - 1, main_menu - 4
'' Choices: 1-calibrate x,y,z,a axis, 2-show # free cogs.

  program_options_screen  
  repeat
    input := kb.getkey
    case input
      $31:                             ' 1 ... show calibration table
        calibration_table_menu
        main_menu_screen
        program_options_screen        
      $32:                             ' 2 ... calibrate x,y,z,a axis
        calibrate_axis_menu
        main_menu_screen
        program_options_screen
      $33:                             ' 3 ... set units decimal point
        units_decimal_point_menu
        main_menu_screen
        program_options_screen        
      $34:                             ' 4 .... mill / lathe screen
        mill_lathe_selection_menu
        main_menu_screen
        program_options_screen              
      $35:                             ' 5 ... restart system 
        restart_menu
        main_menu_screen
        program_options_screen        
      $36:                             ' 6 ... show number of cogs free        
        number_of_cogs := cogs.freestring
        number_of_cogs_screen
        main_menu_screen
        program_options_screen          
      $30:                             ' 0 ... to main_menu
        abort  
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        program_options_screen

       
PUB Axis_setup_menu             

'' From menu level - 1, main_menu - 5
'' Choices: absolute axis 1-x, 2-y, 3-z, 4-a and
'' relative axis 5-x, 6-y, 7-z, 8-a.
'' Variable set + passed to setup_axis_menu(title, encoder (axis) #, and display #)

  axis_setup_screen   
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... abs X axis
        title := @abs_x
        axis := 0
        display := 0
        setup_axis_menu                
      $32:                             ' 2 ... abs Y (Z1) axis        
        title := @abs_y
        axis := 1
        display := 1
        setup_axis_menu      
      $33:                             ' 3 ... abs Z (Z2) axis        
        title := @abs_z
        axis := 2
        display := 2
        setup_axis_menu
      $34:                             ' 4 ... abs A axis
        title := @abs_a
        axis := 3
        display := 3
        setup_axis_menu
      $35:                             ' 5 ... rel X axis        
        title := @rel_x
        axis := 0
        display := 4
        setup_axis_menu
      $36:                             ' 6 ... rel Y (Z1) axis        
        title := @rel_y
        axis := 1
        display := 5
        setup_axis_menu
      $37:                             ' 7 ... rel Z (Z2) axis        
        title := @rel_z
        axis := 2
        display := 6
        setup_axis_menu
      $38:                             ' 8 ... rel A axis        
        title := @rel_a
        axis := 3
        display := 7
        setup_axis_menu
      $30:                             ' 0 ... to main_menu
        abort  
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        axis_setup_screen

        
PUB File_menu                   

'' From menu level - 1, main_menu - 6
'' Choices: 1-write + 2-read setup files

  eepromAddress := $8000
'  read_file_table
  file_screen  
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... write file       
        write_file_menu
        main_menu_screen
        file_screen
      $32:                             ' 2 ... read file      
        read_file_menu
        main_menu_screen
        file_screen
      $33:                             ' 3 ... delete file                             
        delete_file_menu
        main_menu_screen
        file_screen       
      $34:                             ' 4 ... set default file                             
        default_file_menu
        main_menu_screen
        file_screen
      $35:                             ' 5 ... enter password                             
        password_menu                  ' then w/r system default file
        main_menu_screen
        file_screen               
      $30:                             ' 0 ... to main_menu
        abort         
      other:                           ' ..... wrong command
        wrong_command_screen
'        main_menu_screen              ' refresh screen
        file_screen


PUB Special_functions_menu      

'' From menu level - 1, main_menu - 7
'' Choices: 1-mill and 2-lathe special functions

  special_functions_screen  
  repeat
    input := kb.getkey
    case input
      $31:                             ' 1 ... mill special functions
        not_implemented_screen
        abort 
      $32:                             ' 2 ... lathe special functions
        not_implemented_screen
        abort 
      $30:                             ' 0 ... to main_menu
        abort  
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        special_functions_screen


''
''=================================================================================================
''                                 MENU SELECTION - LEVEL 3  (green)
''=================================================================================================
''
''
''-------------------------------------
''   FROM ZERO ENCODERS
''-------------------------------------
''

PUB Zero_all_encoders_menu      

'' From menu level - 2, zero_encoders_menu - 1
'' Choices:  1-yes or 2-no

  Zero_all_encoders_screen  
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... yes --> zero all encoders
        encoder.stop
        repeat index from 0 to 3       ' set abs. + rel. readouts to zero
          pos[index] := 0                                                  
          offset[index] := offset[index+4] := 0.0
        encoder.start(0, 4, 0, @pos)
        return
      $32:                             ' 2 ... no --> return to zero_encoders_menu
        return
      $39:                             ' 9 ... up one menu level
        return
      $30:                             ' 0 ... to main_menu
        abort                   
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        zero_encoders_screen
        zero_all_encoders_screen


PUB Zero_abs_encoders_menu      

'' From menu level - 2, zero_encoders_menu - 2
'' Choices:  1-yes or 2-no

  Zero_abs_encoders_screen
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... yes --> zero abs. encoders
        encoder.stop
        repeat index from 0 to 3       ' set absolute readouts to zero
          pos[index] := 0                                                  
          offset[index] := 0.0
          offset[index+4] := readout[index+4] ' save relative readouts into offset value
        encoder.start(0, 4, 0, @pos)
        return
      $32:                             ' 2 ... no --> return to zero_encoders_menu
        return
      $39:                             ' 9 ... up one menu level
        return
      $30:                             ' 0 ... to main_menu
        abort          
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        zero_encoders_screen    
        zero_all_encoders_screen


PUB Zero_rel_encoders_menu      

'' From menu level - 2, zero_encoders_menu - 3
'' Choices:  1-yes or 2-no

  Zero_rel_encoders_screen  
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... yes --> zero rel. encoders
        encoder.stop 
        repeat index from 4 to 7       ' set relative readouts to zero                                                                    
          offset[index] := fm.fmul(fm.fsub(readout[index],offset[index]),-1.0)                                
        encoder.start(0, 4, 0, @pos)
        return
      $32:                             ' 2 ... no --> return to zero_encoders_menu
        return
      $39:                             ' 9 ... up one menu level
        return                       
      $30:                             ' 0 ... to main_menu
        abort          
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        zero_encoders_screen    
        zero_all_encoders_screen
        
''
''-------------------------------------
''   FROM PROGRAM OPTIONS
''-------------------------------------
''

PUB Calibration_table_menu

'' From menu level - 2, program_options_menu - 1

  calibration_table_screen  
  repeat
    input := kb.getkey
    case input    
      $39:                             ' 9 ... up one menu level
        return
      $30:                             ' 0 ... to main_menu
        abort          
      other:                           ' ..... wrong command
        wrong_command_screen
'        main_menu_screen              ' refresh screen
'        program_options_screen
        calibration_table_screen


PUB Calibrate_axis_menu         

'' From menu level - 2, program_options_menu - 2
'' Choices: 1-x, 2-y, 3-z, 4-a

  calibrate_axis_screen   
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... X axis      
        axis := display := 0           ' set x axis to '0'
        title := @x_axis               ' axis title
        temp_cpu := cpu[axis]          ' save cpu[axis] in case of 'return with no save'
        temp_units := units[axis]      ' ditto    
        units[axis] := units[axis+4] := @in_ptr ' default units value
        units_to_move := 1.0           ' default is to move 1 unit
        begin := (pos[axis])           ' beginning value startup default
        end := 0.0                     ' end value startup default
        cpu[axis] := 0.0               ' cpu value startup default            
        axis_calibrate_menu            ' go to axis_calibrate_menu to retrieve cpu 
        if units[display]     == @cnt_ptr      ' load calibration table for x,y,z,+ a axes
          cal_x[0] := cpu[axis+4] := cpu[axis]                ' with values for cnt, deg, in, + mm
        elseif units[display] == @deg_ptr
          cal_x[1] := cpu[axis+4] := cpu[axis]          
        elseif units[display] == @in_ptr
          cal_x[2] := cpu[axis+4] := cpu[axis]
          cal_x[3] := fm.fdiv(cal_x[2],25.4)
        elseif units[display] == @mm_ptr
          cal_x[3] := cpu[axis+4] := cpu[axis]
          cal_x[2] := fm.fmul(cal_x[3],25.4)               
        main_menu_screen
        program_options_screen        
        calibrate_axis_screen        
      $32:                             ' 2 ... Y (Z1) axis
        axis := display := 1           ' set y axis to '1'
        title := @y_axis
        temp_cpu := cpu[axis]
        temp_units := units[axis]       
        units[axis] := @in_ptr
        units_to_move := 1.0
        begin := (pos[axis])
        end := 0.0
        cpu[axis] := 0.0        
        axis_calibrate_menu
        if units[display]     == @cnt_ptr
          cal_y[0] := cpu[axis+4] := cpu[axis]
        elseif units[display] == @deg_ptr
          cal_y[1] := cpu[axis+4] := cpu[axis]
        elseif units[display] == @in_ptr
          cal_y[2] := cpu[axis+4] := cpu[axis]
          cal_y[3] := fm.fdiv(cal_y[2],25.4)
        elseif units[display] == @mm_ptr
          cal_y[3] := cpu[axis+4] := cpu[axis]
          cal_y[2] := fm.fmul(cal_y[3],25.4)       
        main_menu_screen
        program_options_screen        
        calibrate_axis_screen
      $33:                             ' 3 ... Z (Z2) axis
        axis := display := 2           ' set z axis to '2'
        title := @z_axis
        temp_cpu := cpu[axis]
        temp_units := units[axis]       
        units[axis] := @in_ptr
        units_to_move := 1.0
        begin := (pos[axis])
        end := 0.0
        cpu[axis] := 0.0        
        axis_calibrate_menu
        if units[display]     == @cnt_ptr
          cal_z[0] := cpu[axis+4] := cpu[axis]
        elseif units[display] == @deg_ptr
          cal_z[1] := cpu[axis+4] := cpu[axis]
        elseif units[display] == @in_ptr
          cal_z[2] := cpu[axis+4] := cpu[axis]
          cal_z[3] := fm.fdiv(cal_z[2],25.4)
        elseif units[display] == @mm_ptr
          cal_z[3] := cpu[axis+4] := cpu[axis]
          cal_z[2] := fm.fmul(cal_z[3],25.4)        
        main_menu_screen
        program_options_screen        
        calibrate_axis_screen        
      $34:                             ' 4 ... A axis
        axis := display := 3           ' set a axis to '3'
        title := @a_axis
        temp_cpu := cpu[axis]
        temp_units := units[axis]       
        units[axis] := @in_ptr
        units_to_move := 1.0
        begin := (pos[axis])
        end := 0.0
        cpu[axis] := 0.0        
        axis_calibrate_menu
        if units[display]     == @cnt_ptr
          cal_a[0] := cpu[axis+4] := cpu[axis]
        elseif units[display] == @deg_ptr
          cal_a[1] := cpu[axis+4] := cpu[axis]
        elseif units[display] == @in_ptr
          cal_a[2] := cpu[axis+4] := cpu[axis]
          cal_a[3] := fm.fdiv(cal_a[2],25.4)
        elseif units[display] == @mm_ptr
          cal_a[3] := cpu[axis+4] := cpu[axis]
          cal_a[2] := fm.fmul(cal_a[3],25.4)        
        main_menu_screen
        program_options_screen
        calibrate_axis_screen                      
      $39:                             ' 9 ... up one menu level
        return                
      $30:                             ' 0 ... to main_menu
        abort  
      other:                           '.....  wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        program_options_screen
        calibrate_axis_screen


PUB Units_decimal_point_menu

'' From menu level-2, program_options_menu - 3
'' Defaults are cnt-0, deg-2, in-4, mm-3

  units_decimal_point_screen
  total_digits := 1
  decimal_point := 0
  
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... set # decimal points for 'counts'
        decimal_point_num_menu
        if input <> $39          
          dp_cnt := value                  
        main_menu_screen                  
        program_options_screen  
        units_decimal_point_screen    
      $32:                             ' 2 ... set # decimal points for 'degrees'
        decimal_point_num_menu
        if input <> $39                          
          dp_deg := value
        main_menu_screen
        program_options_screen  
        units_decimal_point_screen
      $33:                             ' 3 ... set # decimal points for 'inches'
        decimal_point_num_menu
        if input <> $39 
          dp_in := value
        main_menu_screen
        program_options_screen  
        units_decimal_point_screen
      $34:                             ' 4 ... set # decimal points for 'millimeters'
        decimal_point_num_menu
        if input <> $39                ' if input <> '9' then ...
          dp_mm := value               ' dp_mm = value
        main_menu_screen
        program_options_screen  
        units_decimal_point_screen        
      $39:                             ' 9 ... up one menu level            
        return                      
      $30:                             ' 0 ... to main_menu
        abort                   
      other:                           ' ..... wrong command
        wrong_command_screen           
        main_menu_screen               ' refresh screen
        program_options_screen
        units_decimal_point_screen
  
        
PUB Mill_lathe_selection_menu   

'' From menu level - 2, program_options_menu - 4
'' Choices:  1-mill or 2-lathe display screen

  mill_lathe_selection_screen  
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... set mill screen
        display_type := 1
        return
      $32:                             ' 2 ... set lathe screen
        display_type := 2
        return
      $39:                             ' 9 ... up one menu level
        return    
      $30:                             ' 0 ... to main_menu
        abort    
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        mill_lathe_selection_screen
          

PUB Restart_menu                

'' From menu level - 2, program_options_menu - 5
'' Choices:  1-yes or 2-no

  restart_screen  
  repeat
    input := kb.getkey
    case input     
      $31:                             ' 1 ... yes --> restart the system
         reboot_screen
         reboot
      $32:                             ' 2 ... no --> return to program_options_menu
        return
      $39:                             ' 9 ... up one menu level
        return         
      $30:                             ' 0 ... to main_menu
        abort          
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        restart_screen

''
''-------------------------------------
''   FROM AXIS SETUP 
''-------------------------------------
''

PUB Setup_axis_menu             

'' From menu level - 2, axis_setup_menu - 1
'' Choices: 1-units, 2-decimal places, 3-sign, 4-offset, 5-zero
''  
  setup_axis_screen

  repeat

    text.str(string($A,21,$B,8))       ' display encoder value in selected units
    text.str(floattoformat(fm.fmul(fm.fdiv(fm.ffloat(pos[axis]),cpu[display]),sign[display]),9,d_p[display]))

    text.str(string($A,21,$B,9))       ' display offset
    text.str(floattoformat(offset[display],9,d_p[display]))
           
    readout[display] :=  fm.fmul(fm.fdiv(fm.ffloat(pos[axis]),cpu[display]),sign[display])         
    readout[display] := fm.fadd(readout[display],offset[display])    
    text.str(string($A,21,$B,10))      ' display readout in selected units    
    text.str(floattoformat(readout[display],9,d_p[display]))
            
    text.out($C)                       ' reset color to box default
    text.out(5)
    
    if kb.gotkey                       ' breakout of endless display loop if key is pressed 
      input := kb.getkey
      case input
        $31:                           ' 1 ... set units to cnt, deg, in., or mm
          units_menu          
          if display == 0                        ' x abs axis
            if units[display]     == @cnt_ptr    ' set cpu[display] based on type of
              cpu[display] := cal_x[0]           ' units[display]
            elseif units[display] == @deg_ptr
              cpu[display] := cal_x[1]
            elseif units[display] == @in_ptr
              cpu[display] := cal_x[2]
            elseif units[display] == @mm_ptr
              cpu[display] := cal_x[3]              
          if display == 1                        ' y abs axis
            if units[display]     == @cnt_ptr
              cpu[display] := cal_y[0]
            elseif units[display] == @deg_ptr
              cpu[display] := cal_y[1]
            elseif units[display] == @in_ptr
              cpu[display] := cal_y[2]
            elseif units[display] == @mm_ptr
              cpu[display] := cal_y[3]              
          if display == 2                        ' z abs axis
            if units[display]     == @cnt_ptr
              cpu[display] := cal_z[0]
            elseif units[display] == @deg_ptr
              cpu[display] := cal_z[1]
            elseif units[display] == @in_ptr
              cpu[display] := cal_z[2]
            elseif units[display] == @mm_ptr
              cpu[display] := cal_z[3]              
          if display == 3                        ' a abs axis
            if units[display]     == @cnt_ptr
              cpu[display] := cal_a[0]
            elseif units[display] == @deg_ptr
              cpu[display] := cal_a[1]
            elseif units[display] == @in_ptr
              cpu[display] := cal_a[2]
            elseif units[display] == @mm_ptr
              cpu[display] := cal_a[3]             
          if display == 4                        ' x rel axis
            if units[display]     == @cnt_ptr
              cpu[display] := cal_x[0]
            elseif units[display] == @deg_ptr
              cpu[display] := cal_x[1]
            elseif units[display] == @in_ptr
              cpu[display] := cal_x[2]
            elseif units[display] == @mm_ptr
              cpu[display] := cal_x[3]              
          if display == 5                        ' y rel axis
            if units[display]     == @cnt_ptr
              cpu[display] := cal_y[0]
            elseif units[display] == @deg_ptr
              cpu[display] := cal_y[1]
            elseif units[display] == @in_ptr
              cpu[display] := cal_y[2]
            elseif units[display] == @mm_ptr
              cpu[display] := cal_y[3]              
          if display == 6                        ' z rel axis
            if units[display]     == @cnt_ptr
              cpu[display] := cal_z[0]
            elseif units[display] == @deg_ptr
              cpu[display] := cal_z[1]
            elseif units[display] == @in_ptr
              cpu[display] := cal_z[2]
            elseif units[display] == @mm_ptr
              cpu[display] := cal_z[3]             
          if display == 7                        ' a rel axis
            if units[display]     == @cnt_ptr
              cpu[display] := cal_a[0]
            elseif units[display] == @deg_ptr
              cpu[display] := cal_a[1]
            elseif units[display] == @in_ptr
              cpu[display] := cal_a[2]
            elseif units[display] == @mm_ptr
              cpu[display] := cal_a[3]                       
          main_menu_screen
'          axis_setup_screen        
          setup_axis_screen                 
        $32:                           ' 2 ... set # of decimal places to display
          decimal_point_num_menu       ' save decimal point # into value
          if input <> $39              ' if input <> '9' (return) then ...
            d_p[display] := value      ' set d_p[display] = value
          main_menu_screen
'          axis_setup_screen        
          setup_axis_screen                 
        $33:                           ' 3 ... set sign of readout, + or -
          sign_menu
          main_menu_screen
'          axis_setup_screen        
          setup_axis_screen          
        $34:                           ' 4 ... set encoder value
          total_digits := 9
          decimal_point := d_p[display]
          encoder.stop                 ' stop encoder cog
          get_input
          if input == $0D           
            if display < 4
              pos[display] := fm.fround(fm.fmul(fp_number,cpu[display]))
            else
              pos[display-4] := fm.fround(fm.fmul(fp_number,cpu[display]))
          encoder.start(0, 4, 0, @pos) ' restart encoder cog and read new pos[axis]   
          main_menu_screen             ' values into encoder counters 
'          axis_setup_screen          
          setup_axis_screen                          
        $35:                           ' 5 ... set offset value
          total_digits := 9
          decimal_point := d_p[display]
          get_input
          if input == $0D              ' RETURN
            offset[display] := fp_number  
          main_menu_screen
'          axis_setup_screen          
          setup_axis_screen
        $38:                           ' 8 ... view display screen
          paint_black_screen                                   
          if display_type == 1    
            mill_screen                ' display mill screen
          else
            lathe_screen               ' display lathe screen 
          axis_units_screen            ' display the axis scale labels
          display_results              ' display the readout results                           
        $39:                           ' 9 ... up one menu level
          main_menu_screen
          axis_setup_menu                                
        $30:                           ' 0 ... to main_menu
          abort                    
        other:                         ' ..... wrong command
          wrong_command_screen
          main_menu_screen             ' refresh screen
          axis_setup_screen
          setup_axis_screen 

''
''-------------------------------------
''   FILE READ/WRITE FUNCTIONS 
''-------------------------------------
''

PUB Password_menu

  password[3] := 0                     ' zero terminator for string
  password_screen
  repeat index from 0 to 2             ' enter 3 digit password
    input := kb.getkey
    case input
      $30..$39:                        ' input # 0-9
        password[index] := input       ' store password
        if index == 0                  ' print '*' in position 1
          text.str(string($A,12,$B,5))
          text.out($2A)
        if index == 1                  ' print '*' in position 2
          text.str(string($A,13,$B,5))
          text.out($2A)
        if index == 2                  ' print '*' in position 3
          text.str(string($A,14,$B,5))
          text.out($2A)

  pause(400)
  if strcomp(@password,@sys_password)  ' compare input with sys password 
    system_default_file_menu           ' proceed to r/w sys default file
  else                                 ' wrong password
    input := "*"                       ' wrong command, print '*'
    wrong_command_screen
    return
    

PUB System_default_file_menu

  system_default_file_screen
  repeat
    input := kb.getkey
    case input
      $31:
        eepromAddress := $8600
        read_file
        return
      $32:
        eepromAddress := $8700                
        write_file
        return
      $39:                           ' 9 ... up one menu level
        return                                        
      $30:                           ' 0 ... to main_menu
        abort                    
      other:                           ' ..... wrong command
        wrong_command_screen
'        main_menu_screen              ' refresh screen
'        file_screen
        system_default_file_screen
      

PUB Write_file_menu

'' From menu level - 2, File_menu - 1
'' Choices: write to a file # 1-8

  read_file_table
  title := @write
  file_select_screen
 
  repeat
    input := kb.getkey                     
    case input    
      $31:                             ' 1 ...
        file_number := 0
        over_write_file_menu
        eepromAddress := $8100                
        write_file
'        main_menu_screen
'        file_screen
         file_select_screen
      $32:                             ' 2 ...
        file_number := 1
        over_write_file_menu
        eepromAddress := $8200                
        write_file
'        main_menu_screen
'        file_screen
        file_select_screen
      $33:                             ' 3 ...
         file_number := 2
         over_write_file_menu
         eepromAddress := $8300                  
         write_file         
'        main_menu_screen
'        file_screen
        file_select_screen
      $34:                             ' 4 ...
         file_number := 3
         over_write_file_menu
         eepromAddress := $8400                  
         write_file         
'        main_menu_screen
'        file_screen
        file_select_screen
      $35:                             ' 5 ...
         file_number := 4
         over_write_file_menu
         eepromAddress := $8500                  
         write_file         
'        main_menu_screen
'        file_screen
        file_select_screen
      $36:                             ' 6 ...
        file_number := 5
        over_write_file_menu
        eepromAddress := $8600                
        write_file
'        main_menu_screen
'        file_screen
        file_select_screen       
      $39:                             ' 9 ... up one menu level
        return               
      $30:                             ' 0 ... to main_menu
        abort         
      other:                           ' ..... wrong command
        wrong_command_screen
'        main_menu_screen              ' refresh screen
'        file_screen
        file_select_screen
  

PUB Read_file_menu

'' From menu level - 2, File_menu - 2
'' Choices: read from files # 1-8

  read_file_table
  title := @read 
  file_select_screen
   
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... read file # 1      
        eepromAddress := $8100
        read_file
'        main_menu_screen
'        file_screen
        file_select_screen
      $32:                             ' 2 ... read file # 2   
        eepromAddress := $8200
        read_file
'        main_menu_screen
'        file_screen
        file_select_screen
      $33:                             ' 3 ... read file # 3
        eepromAddress := $8300
        read_file
'        main_menu_screen
'        file_screen
        file_select_screen
      $34:                             ' 4 ... read file # 4
        eepromAddress := $8400
        read_file
'        main_menu_screen
'        file_screen
        file_select_screen
      $35:                             ' 5 ... read file # 5
        eepromAddress := $8500
        read_file
'        main_menu_screen
'        file_screen
        file_select_screen
      $36:                             ' 6 ... read file # 6
         eepromAddress := $8600
         read_file
'        main_menu_screen
'        file_screen
        file_select_screen
      $39:                             ' 9 ... up one menu level
        return               
      $30:                             ' 0 ... to main_menu
        abort         
      other:                           ' ..... wrong command
        wrong_command_screen
'        main_menu_screen              ' refresh screen
'        file_screen
        file_select_screen


PUB Delete_file_menu

'' From menu level - 2, File_menu - 3
'' Choices: delete a file # 1-8

  read_file_table
  title := @delete 
  file_select_screen
      
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... delete file # 1
        file_number := 0
        erase_file_menu
        
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $32:                             ' 2 ... delete file # 2
        file_number := 1
        erase_file_menu
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $33:                             ' 3 ... delete file # 3
        file_number := 2
        erase_file_menu
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $34:                             ' 4 ... delete file # 4
        file_number := 3
        erase_file_menu
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $35:                             ' 5 ... delete file # 5
        file_number := 4
        erase_file_menu
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $36:                             ' 6 ... delete file # 6
        file_number := 5
        erase_file_menu
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $39:                             ' 9 ... up one menu level
        return               
      $30:                             ' 0 ... to main_menu
        abort         
      other:                           ' ..... wrong command
        wrong_command_screen
'        main_menu_screen              ' refresh screen
'        file_screen
        file_select_screen


PUB Default_file_menu

'' From menu level - 2, File_menu - 4
'' Choices: set a file # 1-8 as default

  read_file_table
  title := @default 
  file_select_screen
  
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... make file # 1 startup default
        repeat index from 0 to 5 step 1
          file_default[index] := @default_no      
        file_default[0] := @default_yes        
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $32:                             ' 2 ... make file # 2 startup default 
        repeat index from 0 to 5 step 1
          file_default[index] := @default_no      
        file_default[1] := @default_yes        
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $33:                             ' 3 ... make file # 3 startup default 
        repeat index from 0 to 5 step 1
          file_default[index] := @default_no      
        file_default[2] := @default_yes
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $34:                             ' 4 ... make file # 4 startup default 
        repeat index from 0 to 5 step 1
          file_default[index] := @default_no      
        file_default[3] := @default_yes
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $35:                             ' 5 ... make file # 5 startup default 
        repeat index from 0 to 5 step 1
          file_default[index] := @default_no      
        file_default[4] := @default_yes
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $36:                             ' 6 ... make file # 6 startup default 
        repeat index from 0 to 5 step 1
          file_default[index] := @default_no      
        file_default[5] := @default_yes
        write_file_table
'        main_menu_screen
'        file_screen
        file_select_screen
      $39:                             ' 9 ... up one menu level
        return               
      $30:                             ' 0 ... to main_menu
        abort         
      other:                           ' ..... wrong command
        wrong_command_screen
'        main_menu_screen              ' refresh screen
'        file_screen
        file_select_screen


       
''
''=================================================================================================
''                                 MENU SELECTION - LEVEL 4  (violet)     
''=================================================================================================
''


PUB Axis_calibrate_menu 

'' From menu level - 3, calibrate_axis_menu - 1-4
'' Choices: 1-select units (mm,in,deg,cnt), 2-# of units to move in calibrating axis,
'' 3-set the counter to zero, 4-move axis and set end count, 5-edit counts per unit,
'' 6-save edit changes + return, 7-up one menu level + do not save edit changes
'' axis = 0-3 representing actual encoder axis x,y,z,a
'' CPU is counts per unit, ie counts per inch or mm.
 
  axis_calibrate_screen
  end := 0                             ' holds stop pos[x] encoder integer value   
  repeat
    text.str(string($A,26,$B,4,$C,1))
    text.str(units[axis])              ' display units ie in,mm,deg,cnt
    text.str(string($A,7,$B,5,$C,1))           
    text.str(units[axis])              ' display units
    text.str(string($A,21,$B,5,$C,6))
    text.str(floattoformat(units_to_move,8,0)) ' display # of units_to_move in calibration
    text.str(string($A,21,$B,6))
    text.str(floattoformat(fm.fabs(fm.ffloat(pos[axis] - begin)),8,0)) ' display start counter value
    text.str(string($A,12,$B,8,$C,1))
    text.str(units[axis])              ' display units
    text.str(string($A,21,$B,8,$C,6))
    text.str(floattoformat(cpu[axis],8,0))     ' display counts per unit, may be edited value            
    text.str(string($A,17,$B,9,$C,1))
    text.str(units[axis])              ' display units
    text.str(string($A,21,$B,7,$C,6))          

    if kb.gotkey                       ' breakout of endless loop if key is pressed 
      input := kb.getkey
      case input
        $31:                           ' 1 ... select units...cnt,deg,in,mm)
          units_menu
          units[axis+4] := units[axis] ' relative = absolute units
          d_p[axis+4] := d_p[axis]     ' relative = absolute d_p
          axis_calibrate_screen          
        $32:                           ' 2 ... # in/mm/deg/cnt to move in calibration
          total_digits := 7
          decimal_point := 0          
          get_input                    ' update units_to_move on 'return + save'
          if input == $0D              ' set units_to_move on 'enter', ignore on 'esc'
            units_to_move := fp_number
          cpu[axis] := 0.0             ' set counts per unit to zero          
          axis_calibrate_screen          
        $33:                           ' 3 ... set the starting point value to zero
          begin := (pos[axis])
          axis_calibrate_screen                     
        $34:                           ' 4 ... set the stopping point value
          end := fm.fabs(fm.ffloat(pos[axis] - begin))
          cpu[axis] :=  fm.fdiv(end,units_to_move)    ' counts per unit (cpu) calibration
          axis_calibrate_screen          
        $35:                           ' 5 ... edit counts per unit
          total_digits := 7            ' set # digits and decimal point
          decimal_point := 0
          get_input
          if input == $0D              ' set cpu[axis] on 'enter', ignore on 'esc'
            cpu[axis] := fm.fdiv(fp_number,units_to_move) ' update cpu[axis] on 'return + save'
          axis_calibrate_screen          
        $36:                           ' 6 ... save cpu results and return
          return
        $39:                           ' 9 ... up one menu level, no save        
          cpu[axis] := temp_cpu        ' restore original values
          units[axis] := temp_units
          return           
        $30:                           ' 0 ... to main_menu, no save
          cpu[axis] := temp_cpu        ' restore original values
          units[display] := temp_units        
          abort
        other:                         ' ..... wrong command
          wrong_command_screen         
          main_menu_screen             ' refresh screen
          program_options_screen
          calibrate_axis_screen
          axis_calibrate_screen  


PUB Sign_menu

'' From menu level - 3, setup_axis_menu - 3
'' Choices: 1-positive, 2-negative
   
  sign_screen               
  repeat
    input := kb.getkey
    case input   
      $31:                             ' 1 ... positive sign
        sign[display] := 1.0
        return
      $32:                             ' 2 ... negative sign
        sign[display] := -1.0
        return
      $39:                             ' 9 ... up one menu level
        return       
      $30:                             ' 0 ... to main_menu
        abort    
      other:                           ' ..... wrong command
        wrong_command_screen
        main_menu_screen               ' refresh screen
        axis_setup_screen        
        setup_axis_menu
        sign_screen


PUB Decimal_point_num_menu

'' From menu level - 3, units_decimal_point_menu - 1,2,3,+ 4
'' From menu level - 3, setup_axis_menu - 2 
'' Choices: 1-zero, 2-one,3-two,4-three, 5-four

  decimal_point_num_screen  
  repeat
    input := kb.getkey
    case input    
      $31:                             ' 1 ... zero
        value := 0
        return
      $32:                             ' 2 ... one
        value := 1                         
        return
      $33:                             ' 3 ... two
        value := 2
        return
      $34:                             ' 4 ... three
        value := 3
        return
      $35:                             ' 5 ... four  
        value := 4
        return       
      $39:                             ' 9 ... up one menu level            
        return                      
      $30:                             ' 0 ... to main_menu
        abort                   
      other:                           ' ..... wrong command
        wrong_command_screen           
        main_menu_screen               ' refresh screen
        program_options_screen
        units_decimal_point_screen
        decimal_point_num_screen


PUB Over_write_file_menu


  if file_type[file_number] == @blank
    if display_type == 1
      file_type[file_number] := @mill
    else
      file_type[file_number] := @lathe   
    write_file_table    
    return    
  else
    over_write_file_screen
    repeat
      input := kb.getkey
      case input
        $31:                           ' 1 ... yes, overwrite
          if display_type == 1
            file_type[file_number] := @mill
          else
            file_type[file_number] := @lathe        
          write_file_table          
          return
        $32:                           ' 2 ... no, do not overwrite
          return
        $39:                           ' 9 ... up one menu level
          return
        $30:                           ' 0 ... to main_menu 
          abort
        other:                         ' ..... wrong command
          wrong_command_screen
'        main_menu_screen              ' refresh screen
'        file_screen
          file_select_screen
          over_write_file_screen


PUB Erase_file_menu

'' From menu level - 2, program_options_menu - 5
'' Choices:  1-yes or 2-no

  erase_file_screen  
  repeat
    input := kb.getkey
    case input     
      $31:                             ' 1 ... yes 
        file_type[file_number] := @blank
        file_default[file_number] := @default_no
        return
      $32:                             ' 2 ... no 
        return
      $39:                             ' 9 ... up one menu level
        return         
      $30:                             ' 0 ... to main_menu
        abort          
      other:                           ' ..... wrong command
        wrong_command_screen
'        main_menu_screen              ' refresh screen
        file_screen
        file_select_screen
        erase_file_screen


''
''=================================================================================================
''                                 MENU SELECTION - LEVEL 5  (blue)     
''=================================================================================================
''

PUB Units_menu

'' From menu level - 4, Axis_calibrate_menu - 1
'' Choices: 1-degrees, 2-inches, 3-millimeters, 4-counts 

  Units_screen
     
  repeat
    input := kb.getkey
    case input
      $31:                             ' 1 ... counts
        units[display] := @cnt_ptr     ' units 'counts' label for a given display
        d_p[display] := dp_cnt         ' counts dec. pt. for a given display          
        return         
      $32:                             ' 2 ... degrees
        units[display] := @deg_ptr    
        d_p[display] := dp_deg                 
        return
      $33:                             ' 3 ... inches
        units[display] := @in_ptr     
        d_p[display] := dp_in                   
        return
      $34:                             ' 4 ... millimeters
        units[display] := @mm_ptr     
        d_p[display] := dp_mm                  
        return        
      $39:                             ' 9 ... up one menu level       
        return                      
      $30:                             ' 0 ... to main_menu
        abort                   
      other:                           ' ..... wrong command
        wrong_command_screen        
        main_menu_screen               ' refresh screen
        program_options_screen
        calibrate_axis_screen
        axis_calibrate_screen        
        units_screen
    
''
''================================================================================================
''                 KEYBOARD ASCII NUMERIC INPUT + CONVERT TO FLOATING POINT NUMBER
''================================================================================================
''

PUB Get_input | a, b, c, d, ptr

'' From menu level - 3, setup_axis_menu - 4 + 5
'' From menu level - 4, axis_calibrate_menu - 5
''
'' Get keyboard input for a numeric string, allow backspacing and entry of '+/./-'.
'' Convert the entry to an ascii string for display.  Also convert the numeric ascii
'' string to a floating point number.
''
'' Local variables:  a, b, c, d - (4 bytes each) provide 16 sequential 
'' bytes of buffer space for the decFixed procedure.  The 16 bytes of buffer 
'' space are referenced as @a[p], where p is the pointer (or index)
'' into the buffer.  ptr - pointer (index) into buffer space starting at @a

  size := total_digits                 ' # digits minus 2 for sign and decimal point
  flag := 0
  get_input_screen  
  ptr := @a                            ' start address of the 16 byte buffer
  bytefill( @a," ",size)               ' fill buffer + 1 with spaces first
  ptr[size+1] := 0                     ' place 0 terminator at end of buffer                                              
  ptr := @a                            ' reset p to start of buffer
  byte[ptr] := "•"                     ' load a  DOT into the first buffer position
  get_input_print_ascii(@a)            ' print the buffer

  repeat                               ' repeat forever
    input := kb.getkey                 ' wait for keyboard input
    case input                         ' match keyboard input to case values                  
      $30..$39, "+", "-", ".":         ' value 0-9,+,-,. ... are valid input for the numeric string
        if ptr < @a + size             ' load keyboard input into buffer, move DOT up 1 position
          byte[ptr++] := input         ' load keypress into current buffer position, increment position
          if ptr == @a + size     
            byte[ptr] := 0             ' load z string 0 terminator into current buffer position
          else
            byte[ptr] := "•"           ' load DOT into current buffer position         
        get_input_print_ascii(@a)
      $C8:                             ' backspace key 
        if ptr < @a + size  
          byte[ptr] := " "             ' clear position
            if ptr > @a
              byte[--ptr] := "•"       ' decrement buffer position and load DOT 
            if ptr == @a
              byte[ptr] := "•"         ' if at first buffer position load DOT
        if ptr == @a + size 
          byte[--ptr] := "•"           ' load DOT at highest buffer position      
        get_input_print_ascii(@a)
      $0D:                             ' ENTER key ... terminataes buffer entry and
        byte[ptr] := 0                 ' load z string 0 terminator at buffer + 1 position
        convert_ascii_string_to_fp(@a) ' convert ascii string to floating point         
        return        
      $CB:                             ' esc ... previous menu
        return
      other:
        wrong_command_screen           ' wrong command
        main_menu_screen
'        program_options_screen
'        calibrate_axis_screen
        axis_calibrate_screen
        get_input_screen               ' redisplay results screen
        get_input_print_ascii(@a)         

  
PUB Get_input_print_ascii(number)

'' From get_input
''
'' Print the entered ascii numeric string as an ascii string
'' The string grows longer as additional numbers are added up to size-2
'' The -2 is for sign '+/-' and decimal point '.')
'' Prints results on get_input_screen

  text.str(string($C,1,1,$A,11,$B,6))  ' set position to print  
  text.str(number)

 
PUB Convert_ascii_string_to_fp(address) | c, d, dp, pos_sign, neg_sign  

'' From get_input
''
'' Convert number in printable ascii string format to a floating point format

  d        := false
  dp       := 0
  pos_sign := false
  neg_sign := false

'' Parse the ascii string

  repeat while c := byte[address++]
    case c                        
      $30..$39:                        ' if numeral then add to result value
        result := result * 10 + (c - "0")
          if d                         ' if decimal point is true then...
            dp := dp + 1               ' count the number of decimal places
      $2E:                             ' decimal point        
        d := true                      ' set true if decimal point encountered
      $2B:                             ' positive sign        
        pos_sign := true               ' set true if positive sign encountered
      $2D:                             ' negative sign        
        neg_sign := true               ' set true if negative sign encountered       
  fp_number := fm.fdiv(fm.ffloat(result),divisors[dp])
  if neg_sign                          ' if neg_sign true then negate the number
    fp_number := fm.fneg(fp_number)  

''
''=================================================================================================
''                                     DISPLAY RESULTS
''=================================================================================================
''


PUB Display_screen              

'' Format the DRO display screen. 
'' Print labels and headings.  '$C,x' sets color. Foreground and background 
'' colors available are at the end of the program named VGA_text.spin, DAT section,
'' under the palette heading. '$A,x' sets X position. '$B,x' sets Y positions.
 
  text.out($C)                         ' set default color
  text.out(0)
  text.str(string($A,1,08,$B,2,$9F,$A,31,$9E,$A,1,08,$B,12,$9D,$A,31,$9C)) ' corners
  repeat index1 from 4 to 10 step 2    ' left T
    text.out($B)
    text.out(index1)
    text.out($A)
    text.out(0)
    text.out($95)      
  repeat index1 from 4 to 10 step 2    ' right T
    text.out($B)
    text.out(index1)
    text.out($A)
    text.out(31)
    text.out($94)
  repeat index1 from 2 to 12 step 2    ' horizontal lines
    text.out($B)
    text.out(index1)
    repeat index2 from 1 to 30
      text.out($A)
      text.out(index2)
      text.out($90)      
  repeat index1 from 3 to 11 step 2    ' vertical lines
    text.out($B)
    text.out(index1)
    text.out($A)
    text.out(0)
    text.str(string($91,$A,3,$91,$A,17,$91,$A,31,$91))
  repeat index1 from 5 to 11 step 2    ' vertical lines
    text.out($B)
    text.out(index1)
    text.out($A)
    text.out(13)
    text.out($91)
    text.out($A)
    text.out(27)
    text.out($91)
  text.str(string($A,3,$B,2,$97,$A,17,$97))  ' T
  text.str(string($A,13,$B,4,$97,$A,27,$97)) ' T
  text.str(string($A,3,$B,12,$96,$A,13,$96,$A,17,$96,$A,27,$96)) ' upside down T
  text.str(string($A,3,$B,4,$92,$A,17,$92))
  repeat index1 from 6 to 10 step 2  ' +
    text.out($B)
    text.out(index1)
    text.str(string($A,3,$92,$A,13,$92,$A,17,$92,$A,27,$92))    
  text.out($B)
  text.out(0)      
  text.str(string($A,1,08,$C,1,"‣▶      QUAD DRO - ",$A,30,"◀‣"))
  text.str(string($A,1,$B,3,$C,1,$05,$05,$A,4,"  ABSOLUTE",$A,18,"  RELATIVE"))
  text.str(string($A,1,$B,14,$C,1,"0▶ MENU",$A,10,"1▶ ZERO",$A,20,"2▶ SET XYZA"))

  
PUB Mill_screen                 

'' Add title and axis labels to formatted screen

  display_screen
  text.out($B)
  text.out(0)
  text.str(string($A,19,$C,1,"MILL"))
  text.str(string($A,1,$B,5,"X "))              
  text.str(string($A,1,$B,7,"Y "))                                              
  text.str(string($A,1,$B,9,"Z "))                       
  text.str(string($A,1,$B,11,"A "))


PUB Lathe_screen                

'' Add title and axis labels to formatted screen

  display_screen  
  text.out($B)
  text.out(0)
  text.str(string($A,19,$C,1,"LATHE"))
  text.str(string($A,1,$B,5,"X "))  
  text.str(string($A,1,$B,7,"Z1"))                                            
  text.str(string($A,1,$B,9,"Z2"))                    
  text.str(string($A,1,$B,11,"A "))

 
PUB Display_results

'' For Jenix scales, resolution is 0.005mm or 0.00019685 in. per step
'' Other linear and rotary scales may also be used, but
'' must be properly calibrated
''
'' formula ==>    readout := (pos * scale * sign) + offset
''
'' readout - number displayed on the screen
'' pos     - quadrature encoder absolute position 
'' scale   - calibration factor (counter, degrees, mm + inches)
'' sign    - change readout to + or -
'' offset  - distance manually set from absolute encoder position

'' Read and display each encoder's abs. + rel. position.
'' Repeat forever unless interrupted by a '0' key press.
'' If '0' key pressed...abort to 'main_menu'. 

  repeat

    readout[0] := fm.fadd(fm.fmul(fm.fdiv(fm.ffloat(pos[0]),cpu[0]),sign[0]),offset[0])
    text.str(string($A,4,$B,5))
    text.str(floattoformat(readout[0],9,d_p[0]))

    readout[1] := fm.fadd(fm.fmul(fm.fdiv(fm.ffloat(pos[1]),cpu[1]),sign[1]),offset[1])
    text.str(string($A,4,$B,7))
    text.str(floattoformat(readout[1],9,d_p[1]))

    readout[2] := fm.fadd(fm.fmul(fm.fdiv(fm.ffloat(pos[2]),cpu[2]),sign[2]),offset[2])
    text.str(string($A,4,$B,9))
    text.str(floattoformat(readout[2],9,d_p[2]))

    readout[3] := fm.fadd(fm.fmul(fm.fdiv(fm.ffloat(pos[3]),cpu[3]),sign[3]),offset[3])
    text.str(string($A,4,$B,11))
    text.str(floattoformat(readout[3],9,d_p[3]))

    readout[4] := fm.fadd(fm.fmul(fm.fdiv(fm.ffloat(pos[0]),cpu[4]),sign[4]),offset[4])
    text.str(string($A,18,$B,5))
    text.str(floattoformat(readout[4],9,d_p[4]))

    readout[5] := fm.fadd(fm.fmul(fm.fdiv(fm.ffloat(pos[1]),cpu[5]),sign[5]),offset[5])
    text.str(string($A,18,$B,7))
    text.str(floattoformat(readout[5],9,d_p[5]))

    readout[6] := fm.fadd(fm.fmul(fm.fdiv(fm.ffloat(pos[2]),cpu[6]),sign[6]),offset[6])
    text.str(string($A,18,$B,9))
    text.str(floattoformat(readout[6],9,d_p[6]))
    
    readout[7] := fm.fadd(fm.fmul(fm.fdiv(fm.ffloat(pos[3]),cpu[7]),sign[7]),offset[7])
    text.str(string($A,18,$B,11))
    text.str(floattoformat(readout[7],9,d_p[7]))

    if kb.gotkey                       ' breakout of endless display loop if key is pressed
      input := kb.getkey
      case input      
        $30:                           ' 0 ... abort to menu_main
          abort
        $31:                           ' 1 ... zero all encoders
          Zero_all_encoders_menu
          paint_black_screen                                   
          if display_type == 1    
            mill_screen                ' display mill screen
          else
            lathe_screen               ' display lathe screen 
          axis_units_screen            ' display the axis scale labels
          display_results              ' display the readout results
        $32:                           ' 2 ... set xyza value
          axis_setup_menu
        other:                         ' ..... wrong command
          wrong_command_screen
          paint_black_screen                                   
          if display_type == 1         ' display mill screen
            mill_screen
          if display_type == 2         ' display lathe screen
            lathe_screen           
          axis_units_screen
          display_results


PUB Axis_units_screen

'' Load the unit, ie. cnt, deg, in, mm into the display

  text.str(string($C,1,$A,14,$B,5))    ' X absolute
  text.str(units[0])
  text.str(string($C,1,$A,14,$B,7))    ' Y absolute
  text.str(units[1])
  text.str(string($C,1,$A,14,$B,9))    ' Z absolute
  text.str(units[2])
  text.str(string($C,1,$A,14,$B,11))   ' A absolute
  text.str(units[3])
  text.str(string($C,1,$A,28,$B,5))    ' X relative
  text.str(units[4])
  text.str(string($C,1,$A,28,$B,7))    ' Y relative
  text.str(units[5])
  text.str(string($C,1,$A,28,$B,9))    ' Z relative 
  text.str(units[6])
  text.str(string($C,1,$A,28,$B,11))   ' A relative
  text.str(units[7])

''
''=================================================================================================
''                                     MISC. METHODS
''=================================================================================================
''

''
''-------------------------------------
''   CREATE A DISPLAY BOX 
''-------------------------------------
''

PUB Box(left, top, width, height, color) | row, column

'' Paints a box of specified size and back ground color

  text.out($C)                         ' set color
  text.out(color)
  text.out($A)                         ' set top left corner
  text.out(left)
  text.out($B)
  text.out(top)

  repeat row from top to top + height
    text.out($B)
    text.out(row)
    repeat column from left to left + width
      text.out($A)
      text.out(column)
      text.out(" ")                    ' print background color only

''
''-------------------------------------
''   I2C EEPROM 
''-------------------------------------
''                                            

PUB Write_file_table

'' Write file table to page 0 of eeprom

  eepromAddress := $8000
  longmove(@buffer+4,@file_type,6)
  longmove(@buffer+28,@file_default,6)
  writeit


PUB Read_file_table

'' Read file table from page 0 of eeprom

  eepromAddress := $8000
  readit
  longmove(@file_type,@buffer+4,6)
  longmove(@file_default,@buffer+28,6)

  
PUB Write_file

'' Write_buffer will write to eepromAddress location

'' Write to memory
   
  longmove(@buffer+0, @offset,8)       ' load long values into buffer      
  longmove(@buffer+32,@cpu,8)       
  longmove(@buffer+64,@sign,8)
  longmove(@buffer+96,@units,8)  
  writeit                              ' write buffer data to page of eeprom                           
  
'' Write to next page of memory

  eepromAddress := eepromAddress + $80 ' next page of eeprom            
  longmove(@buffer+1,  @pos,4)         ' load long and byte values into buffer
  longmove(@buffer+17, @cal_x,4)
  longmove(@buffer+33, @cal_y,4)
  longmove(@buffer+49, @cal_z,4)
  longmove(@buffer+65, @cal_a,4)
  longmove(@buffer+81, @dp_cnt,1)
  longmove(@buffer+85, @dp_deg,1)
  longmove(@buffer+89, @dp_in,1)
  longmove(@buffer+93, @dp_mm,1)
  bytemove(@buffer+97, @d_p,8)
  bytemove(@buffer+105,@display_type,1)     
  writeit                              ' write buffer data to next page of eeprom
  

PUB Read_file
 

'' Fill read buffer with data saved at eepromAddress location

'' Read page of memory
 
  readit                               ' read buffer data to page of eeprom                                       ' read 1st page of data into buffer  
  longmove(@offset,@buffer+0,8)        ' move buffer data into variables
  longmove(@cpu,   @buffer+32,8)  
  longmove(@sign,  @buffer+64,8)
  longmove(@units, @buffer+96,8)                          
  
'' Read the next page of memory
  
  eepromAddress := eepromAddress + $80 ' next page of eeprom                                             
  readit                               ' read buffer data to next page of eeprom                                       ' read 2nd page into buffer  
  encoder.stop                         ' stop encoder cog      
  longmove(@pos,   @buffer+1,4)        ' move buffer data into variables
  encoder.start(0,4,0,@pos)            ' restart encoder cog using the new 'pos' data
  longmove(@cal_x, @buffer+17,4)  
  longmove(@cal_y, @buffer+33,4)
  longmove(@cal_z, @buffer+49,4)
  longmove(@cal_a, @buffer+65,4)
  longmove(@dp_cnt,@buffer+81,1)
  longmove(@dp_deg,@buffer+85,1)
  longmove(@dp_in, @buffer+89,1)
  longmove(@dp_mm, @buffer+93,1)
  bytemove(@d_p,   @buffer+97,8)
  bytemove(@display_type,@buffer+105,1)

   
PRI ReadIt

'' Method that calls i2c_driver to read string from eeprom

  if i2c.Readpage(i2c#BootPin, i2c#EEPROM, eepromAddress, @buffer, 128)
    EEPROM_error_screen                ' an error occurred during the read
    

PRI WriteIt | startTime

'' Method that calls i2c_driver to write string to eeprom

  if i2c.Writepage(i2c#BootPin, i2c#EEPROM, eepromAddress, @buffer, 128)
    EEPROM_error_screen                ' an error occured during the write  
        
  startTime := cnt                     ' prepare to check for a timeout
    
  repeat while i2c.WriteWait(i2c#BootPin, i2c#EEPROM, eepromAddress)
    if cnt - startTime > clkfreq / 10
      EEPROM_error_screen              ' waited more than a 1/10 second for the write to finish


''
''-------------------------------------
''   PAUSE
''-------------------------------------
''

PUB Pause(ms) | c

'' Pause routine, with settable duration
'' ms = millisecond = 1000 = 1 second pause
''
  c := cnt
  repeat until (ms-- == 0)
    waitcnt(c += clkfreq / 1000)    

''
''=================================================================================================
''                                 MENU SELECTION SCREENS - LEVEL 1 (black)
''=================================================================================================
''

PUB Main_menu_screen

  paint_black_screen
  text.out($C)
  text.out(01)
  text.str(string($A,8,"‣▶ MAIN MENU ◀‣")) 
  text.str(string($A,1,$B,3,"1▶ DISPLAY READOUTS"))                                 
  text.str(string($A,1,$B,4,"2▶ ZERO ENCODERS"))
  text.str(string($A,1,$B,5,"3▶ CHANGE SCALE - MM/IN"))  
  text.str(string($A,1,$B,6,"4▶ PROGRAM OPTIONS"))
  text.str(string($A,1,$B,7,"5▶ X-Y-Z-A AXIS SETUP"))
  text.str(string($A,1,$B,8,"6▶ READ OR SAVE SETTINGS"))
  text.str(string($A,1,$B,9,"7▶ SPECIAL FUNCTIONS"))
'  text.str(string($A,4,$B,14,"(non-commercial use only)"))

''
''=================================================================================================
''                                 MENU SELECTION SCREENS - LEVEL 2 (blue)
''=================================================================================================
''

PUB Zero_encoders_screen

  box(7,1,18,8,4)                      ' box(left, top, width, height, color)

  text.str(string($A,7,$B,2,"‣▶ ZERO ENCODERS ◀‣"))  
  text.str(string($A,8,$B,4,"1▶ ABS. + REL."))
  text.str(string($A,8,$B,5,"2▶ ABSOLUTE"))
  text.str(string($A,8,$B,6,"3▶ RELATIVE"))
  text.str(string($A,8,$B,8,"0▶ MAIN MENU"))
    
      
PUB  Change_scale_screen

'' Display change scale (mm/in) screen

  box(0,0,30,13,4)                     ' box(left, top, width, height, color)
  
  text.str(string($A,1,08,$B,1,"‣▶    CHANGE SCALE - MM/IN   ◀‣"))
  text.str(string($A,1,$B,3,"ABS▶ X:",$A,12,"Y:",$A,18,"Z:",$A,24,"A:"))      
  text.str(string($A,1,$B,4,"REL▶ X:",$A,12,"Y:",$A,18,"Z:",$A,24,"A:"))
  text.str(string($A,4,$B,7,$90,$90,$90,$90,$90,$90,$90))
  text.str(string($A,4,$B,6,"MM → IN"))
  text.str(string($A,20,$B,7,$90,$90,$90,$90,$90,$90,$90))
  text.str(string($A,20,$B,6,"IN → MM"))
  text.str(string($A,12,$B,7,$90,$90,$90,$90,$90,$90,$90))    
  text.str(string($A,13,$B,6,"AXIS"))   
  text.str(string($A,9,$B,8,"1▶ ABS/REL ◀4"))
  text.str(string($A,9,$B,9,"2▶   ABS   ◀5"))
  text.str(string($A,9,$B,10,"3▶   REL   ◀6"))
  text.str(string($A,9,$B,12,$C,4,"0▶ MAIN MENU"))
  

PUB Program_options_screen

  box(6,1,23,11,4)                     ' box(left, top, width, height, color)

  text.str(string($A,6,$B,2,"‣▶  PROGRAM OPTIONS   ◀‣"))
  text.str(string($A,7,$B,4,"1▶ CALIBRATION TABLE"))    
  text.str(string($A,7,$B,5,"2▶ CALIBRATE XYZA AXIS"))
  text.str(string($A,7,$B,6,"3▶ UNITS DECIMAL POINT"))  
  text.str(string($A,7,$B,7,"4▶ MILL / LATHE SCREEN"))
  text.str(string($A,7,$B,8,"5▶ RESTART SYSTEM"))
  text.str(string($A,7,$B,9,"6▶ COG UTILIZATION")) 
  text.str(string($A,7,$B,11,"0▶ MAIN MENU"))


PUB Axis_setup_screen

  box(7,1,15,11,4)                     ' box(left, top, width, height, color)

  text.str(string($A,7,$B,2,"‣▶ AXIS SETUP ◀‣"))
  text.str(string($A,8,$B,4,"ABS  AXIS  REL"))
  text.str(string($A,8,$B,5,$90,$90,$90,$20,$20,$90,$90))
  text.str(string($A,15,$B,5,$90,$90,$20,$20,$90,$90,$90))  
  text.str(string($A,8,$B,6," 1▶    X   ◀5"))
  text.str(string($A,8,$B,7," 2▶    Y   ◀6"))
  text.str(string($A,8,$B,8," 3▶    Z   ◀7"))
  text.str(string($A,8,$B,9," 4▶    A   ◀8"))   
  text.str(string($A,9,$B,11,"0▶ MAIN MENU"))


PUB File_screen                 

'' File read/write screen

  box(2,1,27,10,4)                      ' box(left, top, width, height, color)
  
  text.str(string($A,2,$B,2,"‣▶   READ/WRITE SETTINGS  ◀‣"))
  text.str(string($A,3,$B,4,"1▶ SAVE SETTINGS TO A FILE"))
  text.str(string($A,3,$B,5,"2▶ READ FILE SETTINGS"))
  text.str(string($A,3,$B,6,"3▶ DELETE A FILE"))
  text.str(string($A,3,$B,7,"4▶ SET A FILE AS DEFAULT"))
  text.str(string($A,3,$B,8,"5▶ SYSTEM DEFAULT SETUP"))
  text.str(string($A,3,$B,10,"0▶ MAIN MENU"))   


PUB Special_functions_screen

  box(7,1,22,7,4)                      ' box(left, top, width, height, color)
  
  text.str(string($A,7,$B,2,"‣▶ SPECIAL FUNCTIONS ◀‣"))
  text.str(string($A,8,$B,4,"1▶ MILL"))
  text.str(string($A,8,$B,5,"2▶ LATHE"))    
  text.str(string($A,8,$B,7,"0▶ MAIN MENU"))   

  
''
''=================================================================================================
''                                 MENU SELECTION SCREENS - LEVEL 3 (green)
''=================================================================================================
''

''
''-------------------------------------
''   ZERO ALL ENCODERS SCREENS
''-------------------------------------
''

PUB Zero_all_encoders_screen

  box(1,2,23,8,5)                      ' box(left, top, width, height, color)
  
  text.str(string($A,1,$B,3,"‣▶ ZERO ALL ENCODERS? ◀‣"))  
  text.str(string($A,2,$B,5,"1▶ YES"))
  text.str(string($A,2,$B,6,"2▶ NO"))
  text.str(string($A,2,$B,8,"9▶ PREV. MENU"))   
  text.str(string($A,2,$B,9,"0▶ MAIN MENU"))
  

PUB Zero_abs_encoders_screen

  box(1,2,24,8,5)                      ' box(left, top, width, height, color)

  text.str(string($A,1,$B,3,"‣▶ ZERO ABS. ENCODERS? ◀‣"))  
  text.str(string($A,2,$B,5,"1▶ YES"))
  text.str(string($A,2,$B,6,"2▶ NO"))
  text.str(string($A,2,$B,8,"9▶ PREV. MENU"))  
  text.str(string($A,2,$B,9,"0▶ MAIN MENU"))


PUB Zero_rel_encoders_screen

  box(1,2,24,8,5)                      ' box(left, top, width, height, color)

  text.str(string($A,1,$B,3,"‣▶ ZERO REL. ENCODERS? ◀‣"))  
  text.str(string($A,2,$B,5,"1▶ YES"))
  text.str(string($A,2,$B,6,"2▶ NO"))
  text.str(string($A,2,$B,8,"9▶ PREV. MENU"))  
  text.str(string($A,2,$B,9,"0▶ MAIN MENU"))

''
''-------------------------------------
''   PROGRAM OPTIONS SCREEN
''-------------------------------------
''

PUB Calibration_table_screen

  box(1,1,31,15,5)                     ' box(left, top, width, height, color)
                                                        
  text.str(string($A,1,08,$B,1,"‣▶   AXIS CALIBRATION TABLE   ◀‣"))
  text.str(string($A,9,$B,3,"(STEPS / UNIT)"))
  text.str(string($A,5,$B,5,"CNT",$A,12,"DEG",$A,19,"IN",$A,26,"MM"))
  text.str(string($A,3,$B,6,$90,$90,$90,$90,$90,$90,$A,10,$90,$90,$90,$90,$90,$90))
  text.str(string($A,17,$B,6,$90,$90,$90,$90,$90,$90,$A,24,$90,$90,$90,$90,$90,$90))
  text.str(string($A,1,$B,7,"X",$A,1,$B,8,"Y",$A,1,$B,9,"Z",$A,1,$B,10,"A"))
  
  text.str(string($A,3,$B,7))
  text.str(floattoformat(cal_x[0],6,0))
  text.str(string($A,10,$B,7))  
  text.str(floattoformat(cal_x[1],6,0))
  text.str(string($A,17,$B,7))  
  text.str(floattoformat(cal_x[2],6,0))
  text.str(string($A,24,$B,7))  
  text.str(floattoformat(cal_x[3],6,0))
  text.str(string($A,3,$B,8))
  text.str(floattoformat(cal_y[0],6,0))
  text.str(string($A,10,$B,8))  
  text.str(floattoformat(cal_y[1],6,0))
  text.str(string($A,17,$B,8))  
  text.str(floattoformat(cal_y[2],6,0))
  text.str(string($A,24,$B,8))  
  text.str(floattoformat(cal_y[3],6,0))
  text.str(string($A,3,$B,9))
  text.str(floattoformat(cal_z[0],6,0))
  text.str(string($A,10,$B,9))  
  text.str(floattoformat(cal_z[1],6,0))
  text.str(string($A,17,$B,9))  
  text.str(floattoformat(cal_z[2],6,0))
  text.str(string($A,24,$B,9))  
  text.str(floattoformat(cal_z[3],6,0))
  text.str(string($A,3,$B,10))
  text.str(floattoformat(cal_a[0],6,0))
  text.str(string($A,10,$B,10))  
  text.str(floattoformat(cal_a[1],6,0))
  text.str(string($A,17,$B,10))  
  text.str(floattoformat(cal_a[2],6,0))
  text.str(string($A,24,$B,10))  
  text.str(floattoformat(cal_a[3],6,0))  
  text.str(string($C,5))
  text.str(string($A,1,$B,12,"9▶ PREV. MENU"))  
  text.str(string($A,1,$B,13,"0▶ MAIN MENU"))
  

PUB Calibrate_axis_screen

  box(1,1,26,12,5)                     ' box(left, top, width, height, color)

  text.str(string($A,1,$B,2,"‣▶    CALIBRATE AXIS     ◀‣"))
  text.str(string($A,13,$B,4,"COUNTS  / UNIT"))
  text.str(string($A,13,$B,5,$90,$90,$90,$90,$90,$90,$90))
  text.str(string($A,23,$B,5,$90,$90,$90,$90))       
  text.str(string($A,2,$B,6,"1▶ X AXIS",$A,20,$C,1," /     "))
  text.str(string($A,13))
  text.str(floattoformat(cpu[0],7,0))
  text.str(string($A,23,$C,1))
  text.str(units[0])  
  text.str(string($A,2,$B,7,$C,5,"2▶ Y AXIS",$A,20,$C,1," /     "))
  text.str(string($A,13))
  text.str(floattoformat(cpu[1],7,0))
  text.str(string($A,23,$C,1))
  text.str(units[1])      
  text.str(string($A,2,$B,8,$C,5,"3▶ Z AXIS",$A,20,$C,1," /     "))
  text.str(string($A,13))
  text.str(floattoformat(cpu[2],7,0))
  text.str(string($A,23,$C,1))
  text.str(units[2])    
  text.str(string($A,2,$B,9,$C,5,"4▶ A AXIS",$A,20,$C,1," /     "))
  text.str(string($A,13))
  text.str(floattoformat(cpu[3],7,0))
  text.str(string($A,23,$C,1))
  text.str(units[3])  
  text.str(string($A,2,$B,11,$C,5,"9▶ PREV. MENU"))  
  text.str(string($A,2,$B,12,"0▶ MAIN MENU"))


PUB Units_decimal_point_screen

'' Display units # decimal points screen

  box(4,2,24,10,5)                     ' box(left, top, width, height, color)
  
  text.str(string($A,4,$B,3,"‣▶ UNITS DECIMAL POINT ◀‣"))  
  text.str(string($A,5,$B,5,"1▶ COUNTS"))
  text.str(string($A,26,$B,5))
  text.str(floattoformat(fm.ffloat(dp_cnt),2,0)) ' convert decimal point value to floating
  text.str(string($C,5))                         ' point number and print
  text.str(string($A,5,$B,6,"2▶ DEGREES"))
  text.str(string($A,26,$B,6))
  text.str(floattoformat(fm.ffloat(dp_deg),2,0))
  text.str(string($C,5))    
  text.str(string($A,5,$B,7,"3▶ INCHES"))
  text.str(string($A,26,$B,7))
  text.str(floattoformat(fm.ffloat(dp_in),2,0))
  text.str(string($C,5))   
  text.str(string($A,5,$B,8,"4▶ MILLIMETERS"))
  text.str(string($A,26,$B,8))
  text.str(floattoformat(fm.ffloat(dp_mm),2,0))
  text.str(string($C,5))  
  text.str(string($A,5,$B,10,"9▶ PREV. MENU"))  
  text.str(string($A,5,$B,11,"0▶ MAIN MENU"))
  
  
PUB Mill_lathe_selection_screen 

'' Display mill or lathe screen

  box(7,2,18,8,5)                      'box(left, top, width, height, color)
  
  text.str(string($A,7,$B,3,"‣▶ SELECT SCREEN ◀‣"))  
  text.str(string($A,8,$B,5,"1▶ MILL"))
  text.str(string($A,8,$B,6,"2▶ LATHE"))
  text.str(string($A,8,$B,8,"9▶ PREV. MENU"))   
  text.str(string($A,8,$B,9,"0▶ MAIN MENU"))


PUB Restart_screen

'' Restart (reboot system) screen

  box(7,2,20,8,5)                      'box(left, top, width, height, color)
  
  text.str(string($A,7,$B,3,"‣▶ RESTART SYSTEM? ◀‣"))  
  text.str(string($A,8,$B,5,"1▶ YES"))
  text.str(string($A,8,$B,6,"2▶ NO"))
  text.str(string($A,8,$B,8,"9▶ PREV. MENU"))    
  text.str(string($A,8,$B,9,"0▶ MAIN MENU"))


PUB Number_of_cogs_screen

'' Displays # of COGS used and free

  box(7,6,19,4,5)                      ' box(left, top, width, height, color)

  text.str(string($A,7,$B,7,"‣▶ # OF COGS FREE ◀‣"))
  text.str(string($A,12,$B,9,$C,2))   
  text.str(number_of_cogs)

  pause(2000) ' pause 2 seconds

''
''-------------------------------------
''   SETUP ABS/REL AXIS SCREEN
''-------------------------------------
''

PUB Setup_axis_screen

'' Display = 0-7  

  box(1,0,29,14,5)                     ' box(left, top, width, height, color)

  text.str(string($A,1,$B,1,"‣▶ SETUP -                  ◀‣"))
  text.str(string($A,12,$B,1))
  text.str(title)
  text.str(string($A,2,$B,3,"•• STEPS/UNIT"))
  text.str(string($A,21,$B,3))
  text.str(floattoformat(cpu[display],9,1))
  text.out($C)
  text.out(5)
  text.str(string($A,2,$B,4,"•• UNITS/STEP"))
  text.str(string($A,21,$B,4,$C,1))
  text.str(floattoformat(fm.fdiv(1.0,cpu[display]),9,6))
  text.out($C)
  text.out(5)
  text.str(string($A,2,$B,5,"1▶ UNITS"))
  text.str(string($A,21,$B,5))
  text.str(string($C,1,"         "))
  text.str(string($A,27))
  text.str(units[display])
  text.out($C)
  text.out(5) 
  text.str(string($A,2,$B,6,"2▶ DECIMAL PLACES"))
  text.str(string($A,21,$B,6))
  text.str(floattoformat(fm.ffloat(d_p[display]),9,0))  
  text.out($C)
  text.out(5)      
  text.str(string($A,2,$B,7,"3▶ SIGN"))
  text.str(string($A,21,$B,7,$C,1,"         "))
  text.str(string($A,29,$B,7))
  if sign[display] ==1.0
    sign_character[display] := "+"
  else
    sign_character[display] := "-"  
  text.out(sign_character[display])
  text.out($C)
  text.out(5)  
  text.str(string($A,2,$B,8,"4▶ ENCODER VALUE"))
  text.str(string($A,21,$B,8))
  text.out($C)
  text.out(5) 
  text.str(string($A,2,$B,9,"5▶ OFFSET VALUE"))
  text.out($C)
  text.out(5)  
  text.str(string($A,2,$B,10,"•• READOUT VALUE"))
  text.str(string($A,21,$B,10))
  text.str(string($A,2,$B,11,"8▶ VIEW DISPLAY SCREEN"))  
  text.str(string($A,2,$B,12,"9▶ PREV. MENU"))  
  text.str(string($A,2,$B,13,"0▶ MAIN MENU"))
 

PUB File_select_screen

  box(1,0,25,14,5) ' box(left, top, width, height, color)

  text.str(string($A,1,$B,1,"‣▶",$A,25,"◀‣")) 
  text.str(string($A,2,$B,3,"FILE #",$A,11,"TYPE ",$A,19,"DEFAULT"))
  
  text.str(string($A,2,$B,4,$90,$90,$90,$90,$90,$90))
  text.str(string($A,10,$90,$90,$90,$90,$90,$90,$90))
  text.str(string($A,19,$90,$90,$90,$90,$90,$90,$90))
  
  text.str(string($A,4,$B,5,"1▶"))  
  text.str(string($A,4,$B,6,"2▶"))
  text.str(string($A,4,$B,7,"3▶"))
  text.str(string($A,4,$B,8,"4▶"))
  text.str(string($A,4,$B,9,"5▶"))  
  text.str(string($A,4,$B,10,"6▶"))
    
  text.str(string($A,4,$B,12,"9▶ PREV. MENU"))  
  text.str(string($A,4,$B,13,"0▶ MAIN MENU"))

  text.str(string($A,5,$B,1))          ' set up position of heading to display
  text.str(title)                      ' print axis heading X,Y,Z, or A  

  text.str(string($A,11,$B,5,$C,2))
  text.str(file_type[0])
  text.str(string($A,21))
  text.str(file_default[0])
  
  text.str(string($A,11,$B,6))
  text.str(file_type[1])
  text.str(string($A,21))
  text.str(file_default[1])

  text.str(string($A,11,$B,7))
  text.str(file_type[2])
  text.str(string($A,21))
  text.str(file_default[2])

  text.str(string($A,11,$B,8))
  text.str(file_type[3])
  text.str(string($A,21))
  text.str(file_default[3])

  text.str(string($A,11,$B,9))
  text.str(file_type[4])
  text.str(string($A,21))
  text.str(file_default[4])

  text.str(string($A,11,$B,10))
  text.str(file_type[5])
  text.str(string($A,21))
  text.str(file_default[5])

  text.str(string($C,6))        


PUB System_default_file_screen

  box(3,2,24,8,5)                      ' box(left, top, width, height, color)

  text.str(string($A,3,$B,3,"‣▶ SYSTEM DEFAULT FILE ◀‣"))
  text.str(string($A,4,$B,5,"1▶ READ SETTINGS"))
  text.str(string($A,4,$B,6,"2▶ SAVE SETTINGS"))  
  text.str(string($A,4,$B,8,"9▶ PREV. MENU"))  
  text.str(string($A,4,$B,9,"0▶ MAIN MENU"))


PUB Password_screen

  box(3,2,19,6,5)                      ' box(left, top, width, height, color)

  text.str(string($A,3,$B,3,"‣▶ ENTER PASSWORD ◀‣"))
  text.str(string($A,4,$B,5,"        ...   "))  


''
''=================================================================================================
''                                 MENU SELECTION SCREENS - LEVEL 4 (violet)
''=================================================================================================
''

PUB Axis_calibrate_screen

  box(1,1,28,13,6)                     ' box(left, top, width, height, color)

  text.str(string($A,1,$B,2,"‣▶           CALIBRATE     ◀‣"))
  text.str(string($A,7,$B,2))                         
  text.str(title)                                      
  text.str(string($A,2,$B,4,"1▶ SET UNITS"))
  text.str(string($A,21,$B,4,$C,1,"        ",$C,6))
  text.str(string($A,2,$B,5,"2▶ #     TO MOVE"))
  text.str(string($A,21,$B,5,$C,1,"        ",$C,6))
  text.str(string($A,2,$B,6,"3▶ ZERO COUNTER"))
  text.str(string($A,2,$B,7,"4▶ MOVE, SET STOP"))
  text.str(string($A,2,$B,8,"•• COUNTS/     ")) 
  text.str(string($A,2,$B,9,"5▶ EDIT COUNTS/   "))  
  text.str(string($A,2,$B,10,"6▶ SAVE RESULTS"))  
  text.str(string($A,2,$B,12,"9▶ PREV. MENU"))  
  text.str(string($A,2,$B,13,"0▶ MAIN MENU"))


PUB Sign_screen

'' Select sign screen
'' Sign is either 1.0 or -1.0

  box(5,1,17,8,4)                      ' box(left, top, width, height, color)
  
  text.str(string($A,5,$B,2,"‣▶ SELECT SIGN ◀‣"))
  text.str(string($A,6,$B,4,"1▶ +"))
  text.str(string($A,6,$B,5,"2▶ -"))
  text.str(string($A,6,$B,7,"9▶ PREV. MENU"))  
  text.str(string($A,6,$B,8,"0▶ MAIN MENU"))
        

PUB Decimal_point_num_screen

  box(2,3,19,11,6)                     ' box(left, top, width, height, color)

  text.str(string($A,2,$B,4,"‣▶ # OF DEC. PTS. ◀‣"))
  text.str(string($A,3,$B,6,"1▶ ZERO"))    
  text.str(string($A,3,$B,7,"2▶ ONE"))
  text.str(string($A,3,$B,8,"3▶ TWO"))  
  text.str(string($A,3,$B,9,"4▶ THREE"))
  text.str(string($A,3,$B,10,"5▶ FOUR"))
  text.str(string($A,3,$B,12,"9▶ PREV. MENU"))    
  text.str(string($A,3,$B,13,"0▶ MAIN MENU"))       

          
PUB Over_write_file_screen

  box(2,2,20,8,6)                      ' box(left, top, width, height, color)

  text.str(string($A,2,$B,3,"‣▶ OVERWRITE FILE? ◀‣"))  
  text.str(string($A,3,$B,5,"1▶ YES"))
  text.str(string($A,3,$B,6,"2▶ NO"))
  text.str(string($A,3,$B,8,"9▶ PREV. MENU"))  
  text.str(string($A,3,$B,9,"0▶ MAIN MENU"))


PUB Erase_file_screen

  box(2,2,17,8,6) ' box(left, top, width, height, color)

  text.str(string($A,2,$B,3,"‣▶ DELETE FILE? ◀‣"))  
  text.str(string($A,3,$B,5,"1▶ YES"))
  text.str(string($A,3,$B,6,"2▶ NO"))
  text.str(string($A,3,$B,8,"9▶ PREV. MENU"))  
  text.str(string($A,3,$B,9,"0▶ MAIN MENU"))

''
''=================================================================================================
''                                 MENU SELECTION SCREENS - LEVEL 5 (blue)
''=================================================================================================
''

PUB Units_screen

'' Select units screen
'' Units are counts, inches, degrees, and millimeters

  box(5,1,21,10,4)                     ' box(left, top, width, height, color)
  
  text.str(string($A,5,$B,2,"‣▶   SELECT UNITS   ◀‣"))
  text.str(string($A,6,$B,4,"1▶ COUNTS"))
  text.str(string($A,6,$B,5,"2▶ DEGREES"))
  text.str(string($A,6,$B,6,"3▶ INCHES"))
  text.str(string($A,6,$B,7,"4▶ MILLIMETERS"))
  text.str(string($A,6,$B,9,"9▶ PREV. MENU"))  
  text.str(string($A,6,$B,10,"0▶ MAIN MENU"))     
 
'' 
''=================================================================================================
''                                 MISC. SCREENS
''=================================================================================================
''

PUB Get_input_screen

  box(2,3,25,8,4)                      ' box(left, top, width, height, color)  

  text.str(string($A,2,$B,4,"‣▶     ENTER NUMBER     ◀‣"))
  text.str(string($A,3,$B,8,"←▶ BACKSPACE"))
  text.str(string($A,3,$B,9,"ENTER▶ RETURN WITH SAVE"))    
  text.str(string($A,3,$B,10,"ESC▶ RETURN WITHOUT SAVE"))  


PUB Wrong_command_screen

'' Prompts when invalid command

  box(4,4,20,4,7)                      ' box(left, top, width, height, color)
  
  text.str(string($A,4,$B,5,"‣▶ INVALID COMMAND ◀‣"))
  text.str(string($A,12,$B,7,"▶   ◀"))  
  text.str(string($A,14,$B,7))
  text.out(input)  
  pause(1200)                   'wait 2 seconds


PUB Not_implemented_screen

'' Menu selection not yet implemented

  box(4,6,25,2,7)                      ' box(left, top, width, height, color)
  
  text.str(string($A,4,$B,7,"‣▶ TASK NOT IMPLEMENTED ◀‣"))  
  pause(800)                                                       


PUB EEPROM_read_write_screen

'' EEPROM read/write completed screen

  box(6,8,20,4,7)                      'box(left, top, width, height, color)
  
  text.str(string($A,6,$B,9,"‣▶ FILE READ/WRITE ◀‣"))
  text.str(string($A,6,$B,11,"    PLEASE WAIT...   "))
  pause(800)    


PUB EEPROM_error_screen

'' EEPROM_error on read or write

  box(4,2,26,4,7)                      ' box(left, top, width, height, color)
  
  text.str(string($A,4,$B,3,"‣▶ FILE READ/WRITE ERROR ◀‣"))
  text.str(string($A,4,$B,5,"        TRY AGAIN          "))
  pause(1200)


PUB Reboot_screen

'' Yes/no.  Resets all encoders to 0
'' Loads default values for all other variables

  box(8,9,20,4,7)                      'box(left, top, width, height, color) 
  
  text.str(string($A,9,$B,10,"‣▶ SYSTEM RESTART ◀‣"))
  text.str(string($A,9,$B,12,"   PLEASE WAIT..."))
  pause(1200)

''
''-------------------------------------
''   PAINT SCREENS
''-------------------------------------
''

PUB Paint_black_screen          

'' Paint red on black screen
'' Same as clear screen with home to x-0 y-0
 
  text.out($103)                                                                

{
PUB Paint_blue_screen           

'' Paint yellow on dark blue screen

  text.out($104)


PUB Paint_green_screen         

'' Paint yellow on dark green screen

  text.out($105)


PUB Paint_violet_screen         

'' Paint yellow on violet screen

  text.out($106)


PUB Paint_magenta_screen         

'' Paint yellow on magenta screen

  text.out($107)
}

''=================================================================================================
''                                      FLOAT TO FORMAT
''              Stripped down and imbedded version of floatstring.spin by Parallax
''
''                           ************************************
''                           * Floating-Point <-> Strings v 1.1 *
''                           * Single-precision IEEE-754        *
''                           * (C) 2006 Parallax, Inc.          *
''                           ************************************
''
''                           v1.0 - 01 May 2006 - original version
''                           v1.1 - 12 Jul 2006 - added FloatToFormat routine
''=================================================================================================
''

PUB FloatToFormat(single, width, dp) : stringptr | n, w2

'' Convert floating-point number to formatted string
'' Taken from floatstring.spin object
''
''  entry:
''      Single = floating-point number
''      width = width of field
''      dp = number of decimal points
''
''  exit:
''      StringPtr = pointer to resultant z-string
''
''  asterisks are displayed for format errors 
''  leading blank fill is used

  stringptr := p := @float_string      ' get string pointer
                                       
  w2 := width  :=  width #> 1 <# 9     ' width must be 1 to 9, dp must be 0 to width-1
  dp := dp #> 0 <# (width - 2)
  if dp > 0
    w2--
  if single & $8000_0000 or positive_chr
    w2--
                                       
  n := fm.FRound(fm.FMul(single & $7FFF_FFFF , fm.FFloat(teni[dp])))  ' get positive scaled integer value

  if n => teni[w2]                          
    repeat while width
      if --width == dp
        byte[p++] := decimal_chr
      else
        byte[p++] := "*"               ' if format error, display asterisks
    byte[p]~
  else                                 ' store formatted number
    p += width + 2                     ' add two spaces for color of output
    byte[p]~
    repeat width
      byte[--p] := n // 10 + "0"
      n /= 10                                        
      if --dp == 0
        byte[--p] := decimal_chr
      if n == 0 and dp < 0
        quit
          
    if single & $80000000              ' store sign
      byte[--p] := "-"
      repeat while p <> stringptr
        byte[--p] := " "
      byte[p] := $0C                   ' fill first two bytes of string with color output code
      byte[p+1] := $03        
    elseif positive_chr
      byte[--p] := positive_chr
      repeat while p <> stringptr
        byte[--p] := " "
      byte[p] := $0C                   ' fill first two bytes of string with color output code
      byte[p+1] := $02 


PRI AddDigits(leading) | i

  
  repeat i := leading                  ' add leading digits
    AddDigit   
    if thousands_chr                   ' add any thousands separator between thousands 
      i--
      if i and not i // 3
        byte[p++] := thousands_chr  
  if digits                            ' if trailing digits, add decimal character
    AddDecimal    
    repeat while digits                ' then add trailing digits      
      if thousandths_chr               ' add any thousandths separator between thousandths
        if i and not i // 3
          byte[p++] := thousandths_chr
      i++
      AddDigit


PRI AddDigit

  
  if zeros                             ' if leading zeros, add "0" 
    byte[p++] := "0"
    zeros--                            ' if more digits, add current digit and prepare next
  elseif digits
    byte[p++] := integer / tens + "0"
    integer //= tens
    tens /= 10
    digits--  
  else                                 ' if no more digits, add "0"
    byte[p++] := "0"


PRI AddDecimal

  if decimal_chr
    byte[p++] := decimal_chr
  else
    byte[p++] := "."
                    

'' =========================================== END ================================================


{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                 │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation   │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,   │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the        │
│Software is furnished to do so, subject to the following conditions:                                                         │         
│                                                                                                                             │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the         │
│Software.                                                                                                                    │
│                                                                                                                             │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE         │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR        │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,  │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                        │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}} 

 