{{
┌─────────────────────────────┬────────────────────┬─────────────────────┐
│   FPU64_ARITH_Driver v1.1   │ Author: I. Kövesdi │  Rel.: 30 Nov 2011  │
├─────────────────────────────┴────────────────────┴─────────────────────┤
│                    Copyright (c) 2011 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This is a driver object for the uM-FPU64 floating point coprocessor   │
│ using 2-wire SPI protocol for communication with the Propeller.        │                          
│  This driver focuses on simple  arithmetic operations. It inherits the │
│ the version number of the latest FPU64_SPI_Driver, from which it is    │
│ expanded.                                                              │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│                                                                        │
│  The FPU64_ARITH_Driver  is based upon the core FPU64_SPI_Driver v1.1, │
│ which is enhanced here with basic arithmetic functions. This driver    │
│ facilitates the use of simple arithmetics with the uM-FPU64 from SPIN  │
│ code directly.                                  │                      │
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
│  The data burst transfer rate of the 2-wire SPI is about 200 Kbyte/sec │
│ when the Propeller runs at 80 MHz.                                     │
│  This ARITH driver is a member of a family of drivers for the uM-FPU64 │
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

#1,  _INIT, _RST, _CHECK, _WAIT                                   '1-4
#5,  _WRTBYTE, _WRTCMDBYTE, _WRTCMD2BYTES, _WRTCMD3BYTES          '5-8
#9,  _WRTCMD4BYTES, _WRTCMDREG, _WRTCMDRNREG, _WRTCMDSTRING       '9-12
#13, _RDBYTE, _RDREG, _RDSTRING                                   '13-15
#16, _WRTCMDDREG, _WRTCMDRNDREG                                   '16-17
#18, _WRTREGS, _RDREGS                                            '18-19
'These are the enumerated PASM command No.s (_INIT=1, _RST=2,etc..)They
'should be in harmony with the Cmd_Table of the PASM program in the DAT
'section of this object

_MAXSTRL   = 32        'Max string length
_FTOAD     = 40_000    'FTOA delay max 500 us
  
'uM-FPU64 opcodes and indexes---------------------------------------------
_NOP       = $00       'No Operation
_SELECTA   = $01       'Select register A  
_SELECTX   = $02       'Select register X

_CLR       = $03       'Reg[nn] = 0
_CLRA      = $04       'Reg[A] = 0
_CLRX      = $05       'Reg[X] = 0, X = X + 1
_CLR0      = $06       'Reg[0] = 0

_COPY      = $07       'Reg[nn] = Reg[mm]
_COPYA     = $08       'Reg[nn] = Reg[A]
_COPYX     = $09       'Reg[nn] = Reg[X], X = X + 1
_LOAD      = $0A       'Reg[0] = Reg[nn]
_LOADA     = $0B       'Reg[0] = Reg[A]
_LOADX     = $0C       'Reg[0] = Reg[X], X = X + 1
_ALOADX    = $0D       'Reg[A] = Reg[X], X = X + 1
_XSAVE     = $0E       'Reg[X] = Reg[nn], X = X + 1
_XSAVEA    = $0F       'Reg[X] = Reg[A], X = X + 1
_COPY0     = $10       'Reg[nn] = Reg[0]
_LCOPYI    = $11       'Copy immediate value of signed byte as (d)long
                       'into Reg
_SWAP      = $12       'Swap Reg[nn] and Reg[mm]
_SWAPA     = $13       'Swap Reg[A] and Reg[nn]
  
_LEFT      = $14       'Left parenthesis
_RIGHT     = $15       'Right parenthesis
  
_FWRITE    = $16       'Write 32-bit float to Reg[nn]
_FWRITEA   = $17       'Write 32-bit float to Reg[A]
_FWRITEX   = $18       'Write 32-bit float to Reg[X], X = X + 1
_FWRITE0   = $19       'Write 32-bit float to Reg[0]

_FREAD     = $1A       'Read 32-bit float from Reg[nn]
_FREADA    = $1B       'Read 32-bit float from Reg[A]
_FREADX    = $1C       'Read 32-bit float from Reg[X], X = X + 1
_FREAD0    = $1D       'Read 32-bit float from Reg[0]

_ATOF      = $1E       'Convert ASCII string to float, store in Reg[0]
_FTOA      = $1F       'Convert float in Reg[A] to ASCII string.
  
_FSET      = $20       'Reg[A] = Reg[nn] 

_FADD      = $21       'Reg[A] = Reg[A] + Reg[nn]
_FSUB      = $22       'Reg[A] = Reg[A] - Reg[nn]
_FSUBR     = $23       'Reg[A] = Reg[nn] - Reg[A]
_FMUL      = $24       'Reg[A] = Reg[A] * Reg[nn]
_FDIV      = $25       'Reg[A] = Reg[A] / Reg[nn]
_FDIVR     = $26       'Reg[A] = Reg[nn] / Reg[A]
_FPOW      = $27       'Reg[A] = Reg[A] ** Reg[nn]
_FCMP      = $28       'Float compare Reg[A] - Reg[nn]
  
_FSET0     = $29       'Reg[A] = Reg[0]
_FADD0     = $2A       'Reg[A] = Reg[A] + Reg[0]
_FSUB0     = $2B       'Reg[A] = Reg[A] - Reg[0]
_FSUBR0    = $2C       'Reg[A] = Reg[0] - Reg[A]
_FMUL0     = $2D       'Reg[A] = Reg[A] * Reg[0]
_FDIV0     = $2E       'Reg[A] = Reg[A] / Reg[0]
_FDIVR0    = $2F       'Reg[A] = Reg[0] / Reg[A]
_FPOW0     = $30       'Reg[A] = Reg[A] ** Reg[0]
_FCMP0     = $31       'Float compare Reg[A] - Reg[0]  

_FSETI     = $32       'Reg[A] = float(bb)
_FADDI     = $33       'Reg[A] = Reg[A] + float(bb)
_FSUBI     = $34       'Reg[A] = Reg[A] - float(bb)
_FSUBRI    = $35       'Reg[A] = float(bb) - Reg[A]
_FMULI     = $36       'Reg[A] = Reg[A] * float(bb)
_FDIVI     = $37       'Reg[A] = Reg[A] / float(bb) 
_FDIVRI    = $38       'Reg[A] = float(bb) / Reg[A]
_FPOWI     = $39       'Reg[A] = Reg[A] ** bb
_FCMPI     = $3A       'Float compare Reg[A] - float(bb)
  
_FSTATUS   = $3B       'Float status of Reg[nn]
_FSTATUSA  = $3C       'Float status of Reg[A]
_FCMP2     = $3D       'Float compare Reg[nn] - Reg[mm]

_FNEG      = $3E       'Reg[A] = -Reg[A]
_FABS      = $3F       'Reg[A] = | Reg[A] |
_FINV      = $40       'Reg[A] = 1 / Reg[A]
_SQRT      = $41       'Reg[A] = sqrt(Reg[A])    
_ROOT      = $42       'Reg[A] = root(Reg[A], Reg[nn])
_LOG       = $43       'Reg[A] = log(Reg[A])
_LOG10     = $44       'Reg[A] = log10(Reg[A])
_EXP       = $45       'Reg[A] = exp(Reg[A])
_EXP10     = $46       'Reg[A] = exp10(Reg[A])
_SIN       = $47       'Reg[A] = sin(Reg[A])
_COS       = $48       'Reg[A] = cos(Reg[A])
_TAN       = $49       'Reg[A] = tan(Reg[A])
_ASIN      = $4A       'Reg[A] = asin(Reg[A])
_ACOS      = $4B       'Reg[A] = acos(Reg[A])
_ATAN      = $4C       'Reg[A] = atan(Reg[A])
_ATAN2     = $4D       'Reg[A] = atan2(Reg[A], Reg[nn])
_DEGREES   = $4E       'Reg[A] = degrees(Reg[A])
_RADIANS   = $4F       'Reg[A] = radians(Reg[A])
_FMOD      = $50       'Reg[A] = Reg[A] MOD Reg[nn]
_FLOOR     = $51       'Reg[A] = floor(Reg[A])
_CEIL      = $52       'Reg[A] = ceil(Reg[A])
_ROUND     = $53       'Reg[A] = round(Reg[A])
_FMIN      = $54       'Reg[A] = min(Reg[A], Reg[nn])
_FMAX      = $55       'Reg[A] = max(Reg[A], Reg[nn])
  
_FCNV      = $56       'Reg[A] = conversion(nn, Reg[A])
  _F_C       = 0       '├─>F to C
  _C_F       = 1       '├─>C to F
  _IN_MM     = 2       '├─>in to mm
  _MM_IN     = 3       '├─>mm to in
  _IN_CM     = 4       '├─>in to cm
  _CM_IN     = 5       '├─>cm to in
  _IN_M      = 6       '├─>in to m
  _M_IN      = 7       '├─>m to in
  _FT_M      = 8       '├─>ft to m
  _M_FT      = 9       '├─>m to ft
  _YD_M      = 10      '├─>yd to m
  _M_YD      = 11      '├─>m to yd
  _MI_KM     = 12      '├─>mi to km
  _KM_MI     = 13      '├─>km to mi
  _NMI_M     = 14      '├─>nmi to m
  _M_NMI     = 15      '├─>m to nmi
  _ACR_M2    = 16      '├─>acre to m2
  _M2_ACR    = 17      '├─>m2 to acre
  _OZ_G      = 18      '├─>oz to g
  _G_OZ      = 19      '├─>g to oz
  _LB_KG     = 20      '├─>lb to kg
  _KG_LB     = 21      '├─>kg to lb
  _USGAL_L   = 22      '├─>USgal to l
  _L_USGAL   = 23      '├─>l to USgal
  _UKGAL_L   = 24      '├─>UKgal to l
  _L_UKGAL   = 25      '├─>l to UKgal
  _USOZFL_ML = 26      '├─>USozfl to ml
  _ML_USOZFL = 27      '├─>ml to USozfl
  _UKOZFL_ML = 28      '├─>UKozfl to ml
  _ML_UKOZFL = 29      '├─>ml to UKozfl
  _CAL_J     = 30      '├─>cal to J
  _J_CAL     = 31      '├─>J to cal
  _HP_W      = 32      '├─>hp to W
  _W_HP      = 33      '├─>W to hp
  _ATM_KP    = 34      '├─>atm to kPa
  _KP_ATM    = 35      '├─>kPa to atm
  _MMHG_KP   = 36      '├─>mmHg to kPa
  _KP_MMHG   = 37      '├─>kPa to mmHg
  _DEG_RAD   = 38      '├─>degrees to radians
  _RAD_DEG   = 39      '└─>radians to degrees    

_FMAC      = $57       'Reg[A] = Reg[A] + (Reg[nn] * Reg[mm])
_FMSC      = $58       'Reg[A] = Reg[A] - (Reg[nn] * Reg[mm])

_LOADBYTE  = $59       'Reg[0] = float(signed bb)
_LOADUBYTE = $5A       'Reg[0] = float(unsigned byte)
_LOADWORD  = $5B       'Reg[0] = float(signed word)
_LOADUWORD = $5C       'Reg[0] = float(unsigned word)
  
_LOADE     = $5D       'Reg[0] = 2.7182818             
_LOADPI    = $5E       'Reg[0] = 3.1415927
  
_FCOPYI    = $5F       'Copy immediate value of signed byte as float into
                       'Reg

_FLOAT     = $60       'Reg[A] = float(Reg[A])     :LONG to float  
_FIX       = $61       'Reg[A] = fix(Reg[A])       :float to LONG
_FIXR      = $62       'Reg[A] = fix(round(Reg[A])):rounded float to lng
_FRAC      = $63       'Reg[A] = fraction(Reg[A])  
_FSPLIT    = $64       'Reg[A] = int(Reg[A]), Reg[0] = frac(Reg[A])
  
_SELECTMA  = $65       'Select matrix A
_SELECTMB  = $66       'Select matrix B
_SELECTMC  = $67       'Select matrix C
_LOADMA    = $68       'Reg[0] = matrix A[bb, bb]
_LOADMB    = $69       'Reg[0] = matrix B[bb, bb]
_LOADMC    = $6A       'Reg[0] = matrix C[bb, bb]
_SAVEMA    = $6B       'Matrix A[bb, bb] = Reg[0] Please correct TFM!                     
_SAVEMB    = $6C       'Matrix B[bb, bb] = Reg[0] Please correct TFM!                         
_SAVEMC    = $6D       'Matrix C[bb, bb] = Reg[0] Please correct TFM!

_MOP       = $6E       'Matrix operation
  '-------------------------For each r(ow), c(olumn)--------------------
  _SCALAR_SET  = 0     '├─>MA[r, c] = Reg[0]
  _SCALAR_ADD  = 1     '├─>MA[r, c] = MA[r, c] + Reg[0]
  _SCALAR_SUB  = 2     '├─>MA[r, c] = MA[r, c] - Reg[0]
  _SCALAR_SUBR = 3     '├─>MA[r, c] = Reg[0] - MA[r, c] 
  _SCALAR_MUL  = 4     '├─>MA[r, c] = MA[r, c] * Reg[0]
  _SCALAR_DIV  = 5     '├─>MA[r, c] = MA[r, c] / Reg[0]
  _SCALAR_DIVR = 6     '├─>MA[r, c] = Reg[0] / MA[r, c]
  _SCALAR_POW  = 7     '├─>MA[r, c] = MA[r, c] ** Reg[0]
  _EWISE_SET   = 8     '├─>MA[r, c] = MB[r, c]
  _EWISE_ADD   = 9     '├─>MA[r, c] = MA[r, c] + MB[r, c]
  _EWISE_SUB   = 10    '├─>MA[r, c] = MA[r, c] - MB[r, c]                                 
  _EWISE_SUBR  = 11    '├─>MA[r, c] = MB[r, c] - MA[r, c]
  _EWISE_MUL   = 12    '├─>MA[r, c] = MA[r, c] * MB[r, c]
  _EWISE_DIV   = 13    '├─>MA[r, c] = MA[r, c] / MB[r, c]
  _EWISE_DIVR  = 14    '├─>MA[r, c] = MB[r, c] / MA[r, c]
  _EWISE_POW   = 15    '├─>MA[r, c] = MA[r, c] ** MB[r, c]
  '---------------------│-----------------------------------------------
  _MX_MULTIPLY = 16    '├─>MA = MB * MC 
  _MX_IDENTITY = 17    '├─>MA = I = Identity matrix (Diag. of ones)
  _MX_DIAGONAL = 18    '├─>MA = Reg[0] * I
  _MX_TRANSPOSE= 19    '├─>MA = Transpose of MB
  '---------------------│-----------------------------------------------
  _MX_COUNT    = 20    '├─>Reg[0] = Number of elements in MA 
  _MX_SUM      = 21    '├─>Reg[0] = Sum of elements in MA
  _MX_AVE      = 22    '├─>Reg[0] = Average of elements in MA
  _MX_MIN      = 23    '├─>Reg[0] = Minimum of elements in MA 
  _MX_MAX      = 24    '├─>Reg[0] = Maximum of elements in MA
  '---------------------│------------------------------------------------
  _MX_COPYAB   = 25    '├─>MB = MA 
  _MX_COPYAC   = 26    '├─>MC = MA
  _MX_COPYBA   = 27    '├─>MA = MB 
  _MX_COPYBC   = 28    '├─>MC = MB
  _MX_COPYCA   = 29    '├─>MA = MC 
  _MX_COPYCB   = 30    '├─>MB = MC
  '---------------------│-----------------------------------------------
  _MX_DETERM   = 31    '├─>Reg[0]=Determinant of MA (for 2x2 OR 3x3 MA)
  _MX_INVERSE  = 32    '├─>MA = Inverse of MB (for 2x2 OR 3x3 MB)
  '---------------------│-----------------------------------------------
  _MX_ILOADRA  = 33    '├─>Indexed Load Registers to MA
  _MX_ILOADRB  = 34    '├─>Indexed Load Registers to MB
  _MX_ILOADRC  = 35    '├─>Indexed Load Registers to MC
  _MX_ILOADBA  = 36    '├─>Indexed Load MB to MA
  _MX_ILOADCA  = 37    '├─>Indexed Load MC to MA 
  _MX_ISAVEAR  = 38    '├─>Indexed Load MA to Registers
  _MX_ISAVEAB  = 39    '├─>Indexed Load MA to MB
  _MX_ISAVEAC  = 40    '└─>Indexed Load MA to MC

_FFT       = $6F       'FFT operation
  _FIRST_STAGE = 0     '├─>Mode : First stage 
  _NEXT_STAGE  = 1     '├─>Mode : Next stage 
  _NEXT_LEVEL  = 2     '├─>Mode : Next level
  _NEXT_BLOCK  = 3     '├─>Mode : Next block
'-----------------------│-------------------------------------------------
  _BIT_REVERSE = 4     '├─>Mode : Pre-processing bit reverse sort 
  _PRE_ADJUST  = 8     '├─>Mode : Pre-processing for inverse FFT
  _POST_ADJUST = 16    '└─>Mode : Post-processing for inverse FFT
  
_WRIND     = $70       'Write register block
_RDIND     = $71       'Read register block
'Data types
  _INT8        = $08
  _UINT8       = $09
  _INT16       = $0A
  _UINT16      = $0B
  _LONG32      = $0C
  _FLOAT32     = $0D
  _LONG64      = $0E
  _FLOAT64     = $0F
  
_DWRITE    = $72       'Write 64-bit register value
_DREAD     = $73       'Read 64-bit register value

_LBIT      = $74       'Bit clear/set/toggle/test

_SETIND    = $77       'Set indirect pointer value
  _INC         = $80   'Auto-increment the pointer when used
  _DMA         = $10   'DMA buffer pointer
  _REG_LONG    = $00   'Register, LONG integer data
  _REG_FLOAT   = $01   'Register, Floating point data
  _INC_LONG    = $80   'Incremented LONG integer
  _INC_FLOAT   = $81   'Incremented FLOAT
'-------------------------------------------------------------------------    
  _MEM_INT8    = $08
  _MEM_UINT8   = $09
  _MEM_INT16   = $0A
  _MEM_UINT16  = $0B
  _MEM_LONG32  = $0C
  _MEM_FLOAT32 = $0D
  _MEM_LONG64  = $0E
  _MEM_FLOAT64 = $0F
  
_ADDIND    = $78       'Add to indirect pointer value
_COPYIND   = $79       'Copy using indirect pointers

_LOADIND   = $7A       'Reg[0] = indirect(reg[nn]) 
_SAVEIND   = $7B       'Indirect(reg[nn]) = reg[A]
_INDA      = $7C       'Select A using Reg[nn]
_INDX      = $7D       'Select X using Reg[nn]

_FCALL     = $7E       'Call function in Flash memory
_EVENT     = $7F       'Event setup 
  
_RET       = $80       'Return from function
_BRA       = $81       'Unconditional branch
_BRACC     = $82       'Conditional branch
_JMP       = $83       'Unconditional jump
_JMPCC     = $84       'Conditional jump
_TABLE     = $85       'Table lookup
_FTABLE    = $86       'Floating point reverse table lookup
_LTABLE    = $87       'LONG integer reverse table lookup
_POLY      = $88       'Reg[A] = nth order polynomial
_GOTO      = $89       'Computed goto
_RETCC     = $8A       'Conditional return from function
 
_LWRITE    = $90       'Write 32-bit LONG integer to Reg[nn]
_LWRITEA   = $91       'Write 32-bit LONG integer to Reg[A]
_LWRITEX   = $92       'Write 32-bit LONG integer to Reg[X], X = X + 1
_LWRITE0   = $93       'Write 32-bit LONG integer to Reg[0]

_LREAD     = $94       'Read 32-bit LONG integer from Reg[nn] 
_LREADA    = $95       'Read 32-bit LONG integer from Reg[A]
_LREADX    = $96       'Read 32-bit LONG integer from Reg[X], X = X + 1   
_LREAD0    = $97       'Read 32-bit LONG integer from Reg[0]

_LREADBYTE = $98       'Read lower 8 bits of Reg[A]
_LREADWORD = $99       'Read lower 16 bits Reg[A]
  
_ATOL      = $9A       'Convert ASCII to LONG integer
_LTOA      = $9B       'Convert LONG integer to ASCII

_LSET      = $9C       'reg[A] = reg[nn]
_LADD      = $9D       'reg[A] = reg[A] + reg[nn]
_LSUB      = $9E       'reg[A] = reg[A] - reg[nn]
_LMUL      = $9F       'reg[A] = reg[A] * reg[nn]
_LDIV      = $A0       'reg[A] = reg[A] / reg[nn]
_LCMP      = $A1       'Signed LONG compare reg[A] - reg[nn]
_LUDIV     = $A2       'reg[A] = reg[A] / reg[nn]
_LUCMP     = $A3       'Unsigned LONG compare of reg[A] - reg[nn]
_LTST      = $A4       'LONG integer status of reg[A] AND reg[nn] 
_LSET0     = $A5       'reg[A] = reg[0]
_LADD0     = $A6       'reg[A] = reg[A] + reg[0]
_LSUB0     = $A7       'reg[A] = reg[A] - reg[0]
_LMUL0     = $A8       'reg[A] = reg[A] * reg[0]
_LDIV0     = $A9       'reg[A] = reg[A] / reg[0]
_LCMP0     = $AA       'Signed LONG compare reg[A] - reg[0]
_LUDIV0    = $AB       'reg[A] = reg[A] / reg[0]
_LUCMP0    = $AC       'Unsigned LONG compare reg[A] - reg[0]
_LTST0     = $AD       'LONG integer status of reg[A] AND reg[0] 
_LSETI     = $AE       'reg[A] = LONG(bb)
_LADDI     = $AF       'reg[A] = reg[A] + LONG(bb)
_LSUBI     = $B0       'reg[A] = reg[A] - LONG(bb)
_LMULI     = $B1       'Reg[A] = Reg[A] * LONG(bb)
_LDIVI     = $B2       'Reg[A] = Reg[A] / LONG(bb); Remainder in Reg0

_LCMPI     = $B3       'Signed LONG compare Reg[A] - LONG(bb)
_LUDIVI    = $B4       'Reg[A] = Reg[A] / unsigned LONG(bb)
_LUCMPI    = $B5       'Unsigned LONG compare Reg[A] - uLONG(bb)
_LTSTI     = $B6       'LONG integer status of Reg[A] AND uLONG(bb)
_LSTATUS   = $B7       'LONG integer status of Reg[nn]
_LSTATUSA  = $B8       'LONG integer status of Reg[A]
_LCMP2     = $B9       'Signed LONG compare Reg[nn] - Reg[mm]
_LUCMP2    = $BA       'Unsigned LONG compare Reg[nn] - Reg[mm]
  
_LNEG      = $BB       'Reg[A] = -Reg[A]
_LABS      = $BC       'Reg[A] = | Reg[A] |
_LINC      = $BD       'Reg[nn] = Reg[nn] + 1
_LDEC      = $BE       'Reg[nn] = Reg[nn] - 1
_LNOT      = $BF       'Reg[A] = NOT Reg[A]

_LAND      = $C0       'reg[A] = reg[A] AND reg[nn]
_LOR       = $C1       'reg[A] = reg[A] OR reg[nn]
_LXOR      = $C2       'reg[A] = reg[A] XOR reg[nn]
_LSHIFT    = $C3       'reg[A] = reg[A] shift reg[nn]
_LMIN      = $C4       'reg[A] = min(reg[A], reg[nn])
_LMAX      = $C5       'reg[A] = max(reg[A], reg[nn])
_LONGBYTE  = $C6       'reg[0] = LONG(signed byte bb)
_LONGUBYTE = $C7       'reg[0] = LONG(unsigned byte bb)
_LONGWORD  = $C8       'reg[0] = LONG(signed word wwww)
_LONGUWORD = $C9       'reg[0] = LONG(unsigned word wwww)

_LSHIFTI   = $CA        'reg[A] = reg[A] shift bb
_LANDI     = $CB        'reg[A] = reg[A] AND bb
_LORI      = $CC        'reg[A] = reg[A] OR bb

_SETSTATUS = $CD       'Set status byte

_SEROUT    = $CE       'Serial output
_SERIN     = $CF       'Serial Input

_DIGIO     = $D0       'Digital I/O
_ADCMODE   = $D1       'Set A/D trigger mode
_ADCTRIG   = $D2       'A/D manual trigger
_ADCSCALE  = $D3       'ADCscale[ch] = B
_ADCLONG   = $D4       'reg[0] = ADCvalue[ch]
_ADCLOAD   = $D5       'reg[0] = float(ADCvalue[ch]) * ADCscale[ch]
_ADCWAIT   = $D6       'wait for next A/D sample
_TIMESET   = $D7       'time = reg[0]
_TIMELONG  = $D8       'reg[0] = time (LONG)
_TICKLONG  = $D9       'reg[0] = ticks (LONG)
_DEVIO     = $DA       'Device I/O
_DELAY     = $DB       'Delay in milliseconds
_RTC       = $DC       'Real-time clock
_SETARGS   = $DD       'Set FCALL argument mode

_EXTSET    = $E0       'external input count = reg[0]
_EXTLONG   = $E1       'reg[0] = external input counter (LONG)
_EXTWAIT   = $E2       'wait for next external input
_STRSET    = $E3       'Copy string to string buffer
_STRSEL    = $E4       'Set selection point
_STRINS    = $E5       'Insert string at selection point
_STRCMP    = $E6       'Compare string with string buffer
_STRFIND   = $E7       'Find string and set selection point
_STRFCHR   = $E8       'Set field separators
_STRFIELD  = $E9       'Find field and set selection point
_STRTOF    = $EA       'Convert string selection to float
_STRTOL    = $EB       'Convert string selection to LONG
_READSEL   = $EC       'Read string selection
_STRBYTE   = $ED       'Insert 8-bit byte at selection point
_STRINC    = $EE       'increment selection point
_STRDEC    = $EF       'decrement selection point  
 
_SYNC      = $F0       'Get synchronization character 
  _SYNC_CHAR = $5C     '└─>Synchronization character(Decimal 92)
    
_READSTAT  = $F1       'Read status byte 
_READSTR   = $F2       'Read string from string buffer    
_VERSION   = $F3       'Copy version string to string buffer
_IEEEMODE  = $F4       'Set IEEE mode (default)
_PICMODE   = $F5       'Set PIC mode    
_CHECKSUM  = $F6       'Calculate checksum for uM-FPU   

_TRACEOFF  = $F8       'Turn debug trace off
_TRACEON   = $F9       'Turn debug trace on
_TRACESTR  = $FA       'Send string to debug trace buffer
_TRACEREG  = $FB       'Send register value to trace buffer

_READVAR   = $FC       'Read internal variable, store in Reg[0]
  _A_REG     = 0       '├─>Reg[0] = A register
  _X_REG     = 1       '├─>Reg[0] = X register
  _MA_REG    = 2       '├─>Reg[0] = MA register
  _MA_ROWS   = 3       '├─>Reg[0] = MA rows
  _MA_COLS   = 4       '├─>Reg[0] = MA columns
  _MB_REG    = 5       '├─>Reg[0] = MB register
  _MB_ROWS   = 6       '├─>Reg[0] = MB rows
  _MB_COLS   = 7       '├─>Reg[0] = MB columns
  _MC_REG    = 8       '├─>Reg[0] = MC register
  _MC_ROWS   = 9       '├─>Reg[0] = MC rows
  _MC_COLS   = 10      '├─>Reg[0] = MC columns
  _INTMODE   = 11      '├─>Reg[0] = Internal mode word
  _STATBYTE  = 12      '├─>Reg[0] = Last status byte
  _TICKS     = 13      '├─>Reg[0] = Clock ticks per milisecond
  _STRL      = 14      '├─>Reg[0] = Current length of string buffer
  _STR_SPTR  = 15      '├─>Reg[0] = String selection starting point
  _STR_SLEN  = 16      '├─>Reg[0] = String selection length
  _STR_SASC  = 17      '├─>Reg[0] = ASCII char at string selection point
  _INSTBUF   = 18      '├─>Reg[0] = Number of bytes in instr. buffer
  _REVNO     = 19      '├─>Reg[0] = Silicon revision number
  _DEVTYPE   = 20      '└─>Reg[0] = Device type

_SETREAD   = $FD       'This instruction should be used by the foreground
                       'process prior to any read instruction  

_RESET     = $FF       'NOP (but 9 consecutive $FF bytes cause a reset
                       'in SPI protocol)
'Status register bits
_ZERO_BIT  = %0000_0001     'Zero bit mask of the status register  
_SIGN_BIT  = %0000_0010     'Sign bit mask of the status register
_NAN_BIT   = %0000_0100     'Not-a-Number bit mask of the status reg.
_INF_BIT   = %0000_1000     'Infinity bit mask of the status register                         


VAR

LONG   ownCOG
LONG   command, par1, par2, par3, par4, par5

BYTE   str[_MAXSTRL]   'The holder of strings. StartDriver passes the 
                       'address of this byte array to the PASM code when
                       'it calls the COG/#_INIT procedure


DAT '------------------------Start of SPIN code---------------------------


PUB StartDriver(dio_Pin, clk_Pin, addrCogID_) : oKay
'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ StartDriver │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: -Starts a COG to run uMFPU_Driver
''             -Initializes FPU
''             -Makes a hardware test of the FPU           
'' Parameters: -Propeller pin to the DIO line of the FPU
''             -Propeller pin to the CLK line of the FPU
''             -HUB address of COG ID
''     Result: oKay as boolean
''     Effect: Driver in COG is initialised
''+Reads/Uses: CON/_INIT
''    +Writes: command, ownCOG, par1, par2, par3 
''      Calls: DoCommand>>activates COG/#Init
''       Note: The COG/#Init procedure initialises and checks the FPU
'-------------------------------------------------------------------------
StopDriver                           'Stop previous copy of this driver,
                                     'if any
command~
ownCOG := COGNEW(@uMFPU64, @command) 'Try to start a COG with a PASM
                                     'program from label uMFPU64. It
                                     'passes the adress of HUB/VAL/LONG
                                     'command variabble to the PASM code.
                                     'command must be followed with the
                                     'par1, ..., par5 variables. 
                                     
                                     'If sussesfull then
                                     '  ownCOG = actual COG No.
                                     'else
                                     '  ownCOG = -1

LONG[addrCogID_] := ownCOG++         'Use, then increment ownCOG
                                       
IF (ownCOG)                          'if ownCOG is not zero then
                                     'Own COG has been started.
  par1 := dio_Pin                    'Initialize PASM Driver with passing 
  par2 := clk_Pin                    'the DIO and CLK pins and the pointer
  par3 := @str                       'to the HUB/str BYTE array
                  
  DoCommand(_INIT)           'Trigger COG/#Init procedure
  
  oKay := par1               'Signal back FPU state (from par1)
      
ELSE                         'Else Own COG has not been started

  oKay := FALSE              'Signal back error
 
RETURN oKay                  'if oKay then the driver started and
                             'initialized in OwnCOG and FPU seems to be
                             'present.
'----------------------------End of StartDriver---------------------------


PUB StopDriver                                          
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ StopDriver │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Stops uMFPU_Driver PASM code by freeing its COG
'' Parameters: None
''     Result: None
''     Effect: COG of driver is released
''+Reads/Uses: ownCOG                                  VAR/LONG
''    +Writes: command, ownCOG                         VAR/LONG
''      Calls: None
''       Note: Own COG (to stop) is identified via ownCOG global variable 
'-------------------------------------------------------------------------
command~                             'Clear "command" register
                                     'Here you can initiate a shut off
                                     'PASM routine if necessary 

IF (ownCOG)                          'if ownCOG is not zero then
                                     'it is running so we can stop it
                                     
                                     'Actual COG ID is one less! 
  COGSTOP(ownCOG~ - 1)               'Stop Own COG, then clear ownCOG
'-------------------------------End of StopDriver-------------------------


DAT 'Conversions


PUB L32_To_F32(l32)                             
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ L32_To_F32 │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a 32-bit LONG value to 32-bit FLOAT              
'' Parameters: 32-bit LONG value
''     Result: 32-bit FLOAT approximation of the LONG argument
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_LWRITEA, l32)
WriteCmd(_FLOAT)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'----------------------------End of L32_To_F32----------------------------


PUB F32_To_L32(f32)                             
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ F32_To_L32 │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a 32-bi FLOAT value to 32-bit LONG                            
'' Parameters: 32-bit FLOAT
''     Result: 32-bit LONG approximation of the FLOAT
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32)
WriteCmd(_FIXR)
Wait
WriteCmd(_LREADA)
RESULT := ReadReg
'----------------------------End of F32_To_L32----------------------------


PUB F32_To_F64(f32, f64_)                             
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ F32_To_F64 │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a 32-bit FLOAT value to 64-bit DFLOAT              
'' Parameters: -32-bit FLOAT value
''             -Address of 64-bit DFLOAT
''     Result: 64-bit DFLOAT format of the 32-bit FLOAT argument in the
''             given address 
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 255       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 255)
WriteCmdLONG(_FWRITEA, f32)
Wait
WriteCmdByte(_DREAD, 255) 
LONG [f64_][0] := ReadReg
LONG [f64_][1] := ReadReg
'-----------------------------End of F32_To_F64---------------------------


PUB F64_To_F32(f64_)                             
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ F64_To_F32 │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Converts a 64-bit dFLOAT value to 32-bit FLOAT              
'' Parameters: -Pointer to  a 64-bit DFLOAT value
''     Result: 32-bit FLOAT format of the 64-bit DFLOAT argument at the
''             given address 
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 255       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 255)
WriteCmdRnDLONG(_DWRITE, 255, LONG [f64_][0], LONG [f64_][1])
Wait
WriteCmd(_FREADA) 
RESULT := ReadReg
'-----------------------------End of F64_To_F32---------------------------


PUB F32_To_STR(f32, format)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ F32_To_STR │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a 32-bit FLOAT into a string 
'' Parameters: -32-bit FLOAT value
''             -Format code in FPU convention
''     Result: Pointer to string in HUB
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:127
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32) 
RESULT := ReadRaFLOATAsStr(format) 
'------------------------------End of F32_To_STR--------------------------


PUB L32_To_STR(l32, format)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ L32_To_STR │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a 32-bit LONG into a string 
'' Parameters: -32-bit LONG value
''             -Format code in FPU convention
''     Result: Pointer to string in HUB
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:127
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_LWRITEA, l32) 
RESULT := ReadRaLONGAsStr(format) 
'------------------------------End of L32_To_STR--------------------------


PUB F64_To_STR(f64_, format)
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ F64_To_STR │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a 64-bit DFLOAT into a string 
'' Parameters: -Pointer to a 64-bit DFLOAT value
''             -Format code in FPU convention
''     Result: Pointer to string in HUB
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:255
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 255)
WriteCmdRnDLONG(_DWRITE, 255, LONG [f64_][0], LONG [f64_][1])  
RESULT := ReadRaFLOATAsStr(format) 
'-----------------------------End of F64_To_STR---------------------------


PUB L64_To_STR(l64_, format)
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ L64_To_STR │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a 64-bit DLONG into a string 
'' Parameters: -Pointer to a 64-bit DLONG value
''             -Format code in FPU convention
''     Result: Pointer to string in HUB
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:255
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 255)
WriteCmdRnDLONG(_DWRITE, 255, LONG [l64_][0], LONG [l64_][1])  
RESULT := ReadRaLONGAsStr(format) 
'-----------------------------End of L64_To_STR---------------------------


PUB STR_To_F32(strPtr_)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ STR_To_F32 │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a string into a 32-bit FLOAT
'' Parameters: Pointer to string
''     Result: 32-bit FLOAT
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:0
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 0)
WriteCmdStr(_ATOF, strPtr_) 
Wait
WriteCmd(_FREADA)
RESULT := ReadReg 
'-----------------------------End of STR_To_F32---------------------------


PUB STR_To_L32(strPtr_)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ STR_To_L32 │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a string into a 32-bit LONG 
'' Parameters: Pointer to string
''     Result: 32-bit LONG 
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:0
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 0)
WriteCmdStr(_ATOL, strPtr_) 
Wait
WriteCmd(_LREADA)
RESULT := ReadReg 
'-----------------------------End of STR_To_L32---------------------------


PUB STR_To_F64(strPtr_, f64_)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ STR_To_F64 │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a string into a 64-bit DFLOAT
'' Parameters: -Pointer to string
''             -Pointer to 64_bit DFLOAT
''     Result: None
''     Effect: 64-bit DFLOAT filled at second address parameter
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:0
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 128)
WriteCmdStr(_ATOF, strPtr_) 
Wait
WriteCmdByte(_DREAD, 128)
LONG [f64_][0] := ReadReg
LONG [f64_][1] := ReadReg
'------------------------------End of STR_To_F64--------------------------


PUB STR_To_L64(strPtr_, l64_)
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ STR_To_L64 │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''    Action: Converts a string into a 64-bit DLONG
'' Parameters: -Pointer to string
''             -Pointer to 64_bit DLONG
''     Result: None
''     Effect: 64-bit DLONG filled at second address parameter
''+Reads/Uses: /FPUMAT:FPU CONs                
''    +Writes: FPU Reg:0
''      Calls: FPU Read/Write procedures    
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 128)
WriteCmdStr(_ATOL, strPtr_) 
Wait
WriteCmdByte(_DREAD, 128)
LONG [l64_][0] := ReadReg
LONG [l64_][1] := ReadReg
'------------------------------End of STR_To_F64--------------------------


DAT '32-bit FLOAT operations


PUB F32_NEG(f32)                                                  
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_NEG │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Negates a 32-bit FLOAT value                           
'' Parameters: 32-bit FLOAT value
''     Result: Negated 32-bit FLOAT value
''+Reads/Uses: None
''    +Writes: None       
''      Calls: None
''       Note: No check for NaN argument 
'-------------------------------------------------------------------------
RESULT := f32 ^ $8000_0000                                 'Flip sign  bit 
'-------------------------------------------------------------------------


PUB F32_INV(f32)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_INV │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Takes reciprocal of a 32-bit FLOAT value                           
'' Parameters: Float Value
''     Result: 32-bit reciprocal of argument
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127       
''      Calls: FPU Read/Write procedures
''       Note: No check for zero or NaN argument 
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32)
WriteCmd(_FINV)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------End of F32_INV-----------------------------


PUB F32_ADD(f32_a, f32_b)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_ADD │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Adds two 32-bit FLOAT values                           
'' Parameters: Float values
''     Result: Sum of float values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: No checks for NaN arguments 
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_FADD, 126)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------END of F32_ADD-----------------------------


PUB F32_SUB(f32_a, f32_b)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_SUB │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Subtracts two float values                           
'' Parameters: Float values
''     Result: Difference between float values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: fA-fB, no checks for NaN arguments
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_FSUB, 126)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------End of F32_SUB-----------------------------


PUB F32_MUL(f32_a, f32_b)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_MUL │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies two float values                           
'' Parameters: Float values
''     Result: Multiplication result of float values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: No checks for NaN arguments
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_FMUL, 126)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------End of F32_MUL-----------------------------


PUB F32_DIV(f32_a, f32_b)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F32_DIV │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Divides two float values                              
'' Parameters: Float values
''     Result: Ratio of float values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: fA/fB, no checks for NaN arguments or for a zero fB
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_FDIV, 126)
Wait
WriteCmd(_FREADA)
RESULT := ReadReg
'------------------------------End of F32_DIV-----------------------------
       

DAT '32-bit FLOAT comparisons


PUB F32_EQ(f32_a, f32_b, f32_eps) | status                                   
'-------------------------------------------------------------------------
'--------------------------------┌────────┐-------------------------------
'--------------------------------│ F32_EQ │-------------------------------
'--------------------------------└────────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Checks equality of two 32-bit FLOATs within epsilon                                             
'' Parameters: -Value1
''             -Value2
''             -Epsilon    
''     Result: TRUE if (ABS(Value1-Value2) < Epsilon) else FALSE
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: With Epsilon=0.0 you can test "true" equality. However,
''             that is sometimes misleading in floating point calculations
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_FSUB, 127)
WriteCmd(_FABS)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_eps)
WriteCmd(_FABS)   
WriteCmdByte(_FCMP, 126)
Wait   
WriteCmd(_READSTAT)
status := ReadByte
RESULT := NOT (status & _SIGN_BIT)
'-------------------------------End of F32_EQ-----------------------------


PUB F32_GT(f32_a, f32_b, f32_eps) | status                                   
'-------------------------------------------------------------------------
'--------------------------------┌────────┐-------------------------------
'--------------------------------│ F32_GT │-------------------------------
'--------------------------------└────────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Checks "greater or not" of two 32-bit FLOATs within margin                                                   
'' Parameters: -Value1
''             -Value2
''             -Epsilon    
''     Result: TRUE if (Value1-Value2)>Epsilon else FALSE
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:127, 126       
''      Calls: FPU Read/Write procedures
''       Note: You can use eps=0.0
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_b)
WriteCmdByte(_SELECTA, 126)
WriteCmdLONG(_FWRITEA, f32_a)
WriteCmdByte(_FSUB, 127)
WriteCmdByte(_SELECTA, 127)
WriteCmdLONG(_FWRITEA, f32_eps)
WriteCmd(_FABS)   
WriteCmdByte(_FCMP, 126)
Wait   
WriteCmd(_READSTAT)
status := ReadByte
RESULT := status & _SIGN_BIT           'Sign bit in FPU's status byte
'-------------------------------End of F32_GT-----------------------------


DAT '64-bit DFLOAT operations           


PUB F64_NEG(f64_)                                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F64_NEG │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Negates a 64-bit DFLOAT value                          
'' Parameters: Pointer to 64-bit DFLOAT value
''     Result: Negated 64-bit DFLOAT value
''     Effect: 64-bit DFLOAT negated in place
''+Reads/Uses: None
''    +Writes: None       
''      Calls: None
''       Note: No check for NaN argument 
'-------------------------------------------------------------------------
LONG [f64_][0] := (LONG [f64_][0]) ^ $8000_0000           'Flip sign  bit
'-------------------------------------------------------------------------


PUB F64_INV(f64_, resf64_)                       
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F64_INV │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Takes reciprocal of a 64-bit DFLOAT value                          
'' Parameters: Pointer to 64-bit DFLOAT Value
''     Result: 64-bit reciprocal of argument
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:255       
''      Calls: FPU Read/Write procedures
''       Note: No check for zero or NaN argument 
'-------------------------------------------------------------------------
WriteCmdByte(_SELECTA, 255)
WriteCmdRnDLONG(_DWRITE, 255, LONG [f64_][0], LONG [f64_][1])
WriteCmd(_FINV)
Wait
WriteCmdByte(_DREAD, 255)
LONG [resf64_][0] := ReadReg
LONG [resf64_][1] := ReadReg
'------------------------------End of F64_INV-----------------------------


PUB F64_ADD(f64_a_, f64_b_, f64_res_)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F64_ADD │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Adds two 64-bit DFLOAT values                           
'' Parameters: 64-bit DFLOAT values
''     Result: 64-bit DFLOAT Sum of DFLOAT values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures
''       Note: No checks for NaN arguments 
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 254, LONG [f64_a_][0], LONG [f64_a_][1])
WriteCmdRnDLONG(_DWRITE, 255, LONG [f64_b_][0], LONG [f64_b_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmdByte(_FADD, 254)
Wait
WriteCmdByte(_DREAD, 255)
LONG [f64_res_][0] := ReadReg
LONG [f64_res_][1] := ReadReg
'------------------------------END of F64_ADD-----------------------------


PUB F64_SUB(f64_a_, f64_b_, f64_res_)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F64_SUB │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Subtracts two 64-bit DFLOAT values                           
'' Parameters: 64-bit DFLOAT values
''     Result: 64-bit DFLOAT difference of DFLOAT values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures
''       Note: No checks for NaN arguments 
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 255, LONG [f64_a_][0], LONG [f64_a_][1])
WriteCmdRnDLONG(_DWRITE, 254, LONG [f64_b_][0], LONG [f64_b_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmdByte(_FSUB, 254)
Wait
WriteCmdByte(_DREAD, 255)
LONG [f64_res_][0] := ReadReg
LONG [f64_res_][1] := ReadReg
'------------------------------END of F64_SUB-----------------------------


PUB F64_MUL(f64_a_, f64_b_, f64_res_)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F64_MUL │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies two 64-bit DFLOAT values                           
'' Parameters: 64-bit DFLOAT values
''     Result: 64-bit DFLOAT product of DFLOAT values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures
''       Note: No checks for NaN arguments 
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 254, LONG [f64_a_][0], LONG [f64_a_][1])
WriteCmdRnDLONG(_DWRITE, 255, LONG [f64_b_][0], LONG [f64_b_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmdByte(_FMUL, 254)
Wait
WriteCmdByte(_DREAD, 255)
LONG [f64_res_][0] := ReadReg
LONG [f64_res_][1] := ReadReg
'------------------------------END of F64_MUL-----------------------------


PUB F64_DIV(f64_a_, f64_b_, f64_res_)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ F64_DIV │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Divides two 64-bit DFLOAT values                           
'' Parameters: 64-bit DFLOAT values
''     Result: 64-bit DFLOAT ratio of DFLOAT values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures
''       Note: No checks for NaN arguments 
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 255, LONG [f64_a_][0], LONG [f64_a_][1])
WriteCmdRnDLONG(_DWRITE, 254, LONG [f64_b_][0], LONG [f64_b_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmdByte(_FDIV, 254)
Wait
WriteCmdByte(_DREAD, 255)
LONG [f64_res_][0] := ReadReg
LONG [f64_res_][1] := ReadReg
'------------------------------END of F64_DIV-----------------------------


DAT '64-bit DLONG operations            


PUB L64_NEG(l64_)                                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ L64_NEG │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Negates a 64-bit DLONG value                          
'' Parameters: Pointer to 64-bit DLONG value
''     Result: None
''     Effect: 64-bit DLONG negated in place
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 255, LONG [l64_][0], LONG [l64_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmd(_LNEG)
Wait
WriteCmdByte(_DREAD, 255)
LONG [l64_][0] := ReadReg
LONG [l64_][1] := ReadReg
'----------------------------End of L64_NEG-------------------------------


PUB L64_ADD(l64_a_, l64_b_, l64_res_)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ L64_ADD │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Adds two 64-bit DLONG values                           
'' Parameters: 64-bit DLONG values
''     Result: 64-bit DLONG Sum of DLONG values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures 
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 254, LONG [l64_a_][0], LONG [l64_a_][1])
WriteCmdRnDLONG(_DWRITE, 255, LONG [l64_b_][0], LONG [l64_b_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmdByte(_LADD, 254)
Wait
WriteCmdByte(_DREAD, 255)
LONG [l64_res_][0] := ReadReg
LONG [l64_res_][1] := ReadReg
'------------------------------END of L64_ADD-----------------------------


PUB L64_SUB(l64_a_, l64_b_, l64_res_)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ L64_SUB │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Subtracts two 64-bit DLONG values                           
'' Parameters: 64-bit DLONG values
''     Result: 64-bit DLONG difference of DLONG values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 255, LONG [l64_a_][0], LONG [l64_a_][1])
WriteCmdRnDLONG(_DWRITE, 254, LONG [l64_b_][0], LONG [l64_b_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmdByte(_LSUB, 254)
Wait
WriteCmdByte(_DREAD, 255)
LONG [l64_res_][0] := ReadReg
LONG [l64_res_][1] := ReadReg
'------------------------------END of L64_SUB-----------------------------


PUB L64_MUL(l64_a_, l64_b_, l64_res_)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ L64_MUL │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Multiplies two 64-bit DLONG values                           
'' Parameters: 64-bit DLONG values
''     Result: 64-bit DLONG product of DLONG values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures 
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 254, LONG [l64_a_][0], LONG [l64_a_][1])
WriteCmdRnDLONG(_DWRITE, 255, LONG [l64_b_][0], LONG [l64_b_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmdByte(_LMUL, 254)
Wait
WriteCmdByte(_DREAD, 255)
LONG [l64_res_][0] := ReadReg
LONG [l64_res_][1] := ReadReg
'------------------------------END of L64_MUL-----------------------------


PUB L64_DIV(l64_a_, l64_b_, l64_res_)                                 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ L64_DIV │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Divides two 64-bit DLONG values                           
'' Parameters: 64-bit DLONG values
''     Result: 64-bit DLONG ratio of DLONG values
''+Reads/Uses: /FPU CONs
''    +Writes: FPU Reg:254, 255       
''      Calls: FPU Read/Write procedures 
'-------------------------------------------------------------------------
WriteCmdRnDLONG(_DWRITE, 255, LONG [l64_a_][0], LONG [l64_a_][1])
WriteCmdRnDLONG(_DWRITE, 254, LONG [l64_b_][0], LONG [l64_b_][1])
WriteCmdByte(_SELECTA, 255)
WriteCmdByte(_LDIV, 254)
Wait
WriteCmdByte(_DREAD, 255)
LONG [l64_res_][0] := ReadReg
LONG [l64_res_][1] := ReadReg
'------------------------------END of L64_DIV-----------------------------


DAT 'Core FPU64 procedures


PUB Reset                                 
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ Reset │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Initiates a Software Reset of the FPU                                                 
'' Parameters: None                      
''     Result: TRUE if reset was succesfull else FALSE
''+Reads/Uses: CON/_RST
''    +Writes: HUB/VAR/LONG command, par1        
''      Calls: DoCommand>>activates #Rst (in COG)
'-------------------------------------------------------------------------
DoCommand(_RST)

RESULT := par1               'Read back FPU's READY status
'-------------------------------End of Reset------------------------------                                                                    


PUB CheckReady                            
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ CheckReady │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Checks for an empty instruction buffer of the FPU. It
''             returns the result immediately and does not wait for that
''             "READY" state unlike the Wait command, which does wait                             
'' Parameters: None                      
''     Result: TRUE if FPU is idle else FALSE
''+Reads/Uses: CON/_CHECK    
''    +Writes: HUB/VAR/par1        
''      Calls: DoCommand>>activates #CheckForReady (in COG)
'-------------------------------------------------------------------------
DoCommand(_CHECK)
 
RESULT := par1
'-----------------------------End of CheckReady---------------------------


PUB Wait                                   
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Wait │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Waits for FPU ready                             
'' Parameters: None                      
''     Result: None 
''+Reads/Uses: CON/_WAIT    
''    +Writes: None        
''      Calls: DoCommand>>activates #WaitForReady (in COG)
'-------------------------------------------------------------------------
DoCommand(_WAIT)
'--------------------------------End of Wait------------------------------


PUB ReadSyncChar                                              
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ ReadSyncChar │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Reads syncronization character from FPU                             
'' Parameters: None                      
''     Result: Sync Char response of FPU (should be $5C=dec 92 if FPU OK)  
''+Reads/Uses: CON/_SYNC    
''    +Writes: None        
''      Calls: -WriteCmd
''             -ReadByte
''       Note: No Wait here before the read operation
'-------------------------------------------------------------------------
WriteCmd(_SYNC)

RESULT := ReadByte
'----------------------------End of ReadSyncChar--------------------------


PUB ReadInterVar(index)                                            
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ ReadInterVar │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads an Internal Variable from FPU                           
'' Parameters: Index of variable        
''     Result: Selected Internal variable of FPU
''+Reads/Uses: HUB/CON/_SETREAD, _READVAR, _LREAD0   
''    +Writes: None        
''      Calls: -WriteCmdByte
''             -Wait
''             -WriteCmd
''             -ReadReg
'-------------------------------------------------------------------------
writeCmd(_SETREAD)
WriteCmdByte(_READVAR, index)
Wait
WriteCmd(_LREAD0)
RESULT := ReadReg                
'-----------------------------End of ReadInterVar-------------------------


PUB ReadRaFloatAsStr(format)
'-------------------------------------------------------------------------
'----------------------------┌──────────────────┐-------------------------
'----------------------------│ ReadRaFloatAsStr │-------------------------
'----------------------------└──────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Reads the FLOAT value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB/BYTE[_MAXSTRL] str                           
'' Parameters: Format of string in FPU convention        
''     Result: Pointer to string HUB/str
''+Reads/Uses: CON/_FTOA, _FTOAD   
''    +Writes: None        
''      Calls: -WriteCmdByte
''             -Wait
''             -ReadStr
''       Note: _MAXSTRL = 32 in this version 
'-------------------------------------------------------------------------
WriteCmdByte(_FTOA, format)
WAITCNT(_FTOAD + CNT)
Wait
RESULT := ReadStr
'-------------------------End of ReadRaFloatAsStr-------------------------


PUB ReadRaLongAsStr(format)
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ ReadRaLongAsStr │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Reads the LONG value from Reg[A] as string into the string
''             buffer of the FPU then loads it into HUB/BYTE[_MAXSTRL] str                          
'' Parameters: Format of string in FPU convention        
''     Result: Pointer to string HUB/str
''+Reads/Uses: CON/_LTOA, _FTOAD   
''    +Writes: None        
''      Calls: -WriteCmdByte
''             -Wait
''             -ReadStr
'-------------------------------------------------------------------------
WriteCmdByte(_LTOA, format)
WAITCNT(_FTOAD + CNT)
Wait
RESULT := ReadStr
'--------------------------End of ReadRaLongAsStr-------------------------


PUB WriteCmd(cmd)                                    
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ WriteCmd │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte to FPU                           
'' Parameters: Command byte                       
''     Result: None
''+Reads/Uses: CON/_WRTBYTE    
''    +Writes: VAR/LONG/par1        
''      Calls: DoCommand>>activates #WrtByte (in COG)
'-------------------------------------------------------------------------
par1 := cmd

DoCommand(_WRTBYTE)
'------------------------------End of WriteCmd----------------------------


PUB WriteCmdByte(cmd, byt)                            
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ WriteCmdByte │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus a Data byte to FPU          
'' Parameters: -Command byte
''             -Data byte
''     Result: None
''+Reads/Uses: CON/_WRTCMDBYTE  
''    +Writes: VAR/LONG/par1, par2        
''      Calls: DoCommand>>activates #WrtCmdByte (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := byt

DoCommand(_WRTCMDBYTE)
'----------------------------End of WriteCmdByte--------------------------


PUB WriteCmd2Bytes(cmd, b1, b2)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd2Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 2 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1, 2
''     Result: None
''+Reads/Uses: CON/_WRTCMD2BYTES  
''    +Writes: VAR/LONG/par1, par2, par3        
''      Calls: DoCommand>>activates #WrtCmd2Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2

DoCommand(_WRTCMD2BYTES)
'---------------------------End of WriteCmd2Bytes-------------------------


PUB WriteCmd3Bytes(cmd, b1, b2, b3)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd3Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 3 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1...3
''     Result: None
''+Reads/Uses: CON/_WRTCMD3BYTES  
''    +Writes: VAR/LONG/par1, par2, par3, par4        
''      Calls: DoCommand>>activates #WrtCmd3Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2
par4 := b3

DoCommand(_WRTCMD3BYTES)
'--------------------------End of WriteCmd3Bytes--------------------------


PUB WriteCmd4Bytes(cmd, b1, b2, b3, b4)                            
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmd4Bytes │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte plus 4 Data bytes to FPU          
'' Parameters: -Command byte
''             -Data bytes 1...4
''     Result: None
''+Reads/Uses: CON/_WRTCMD4BYTES  
''    +Writes: VAR/LONG/par1, par2, par3, par4, par5        
''      Calls: DoCommand>>activates #WrtCmd4Bytes (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := b1
par3 := b2
par4 := b3
par5 := b4

DoCommand(_WRTCMD4BYTES)
'--------------------------End of WriteCmd4Bytes--------------------------


PUB WriteCmdLong(cmd, longVal)                            
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WriteCmdLong │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte plus a 32-bit LONG value to FPU          
'' Parameters: -Command byte
''             -32-bit LONG value
''     Result: None
''+Reads/Uses: CON/_WRTCMDREG  
''    +Writes: VAR/LONG/par1, par2        
''      Calls: DoCommand>>activates #WrtCmdReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := longVal

DoCommand(_WRTCMDREG)
'--------------------------End of WriteCmdLONG----------------------------


PUB WriteCmdDLong(cmd, longValMSL, longValLSL)                            
'-------------------------------------------------------------------------
'----------------------------┌───────────────┐----------------------------
'----------------------------│ WriteCmdDLong │----------------------------
'----------------------------└───────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a command byte plus a 64-bit DLONG value to FPU          
'' Parameters: -Command byte
''             -32-bit LONG value: Most Significant LONG of DLONG
''             -32-bit LONG value: Least Significant LONG of DLONG
''     Result: None
''+Reads/Uses: CON/_WRTCMDDREG  
''    +Writes: VAR/LONG/par1, par2, par3        
''      Calls: DoCommand>>activates #WrtCmdDReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := longValMSL
par3 := longValLSL

DoCommand(_WRTCMDDREG)
'---------------------------End of WriteCmdDLong--------------------------


PUB WriteCmdRnLong(cmd, regN, longVal)
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ WriteCmdRnLong │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + LONG data to FPU                          
'' Parameters: -Command byte
''             -RegNo byte
''             -LONG (32-bit) data                      
''     Result: None
''+Reads/Uses: CON/_WRTCMDRNREG   
''    +Writes: VAR/LONG/par1, par2, par3        
''      Calls: DoCommand>>activates  #WrtCmdRnReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := regN
par3 := longVal

DoCommand(_WRTCMDRNREG)
'--------------------------End of WriteCmdRnLong--------------------------


PUB WriteCmdRnDLong(cmd, regN, longValMSL, longValLSL)
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ WriteCmdRnDLong │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + RegNo byte + DLONG data to FPU                          
'' Parameters: -Command byte
''             -RegNo byte
''             -LONG (32-bit) data for MSL of 64-bit DLONG
''             -LONG (32-bit) data for LSL of 64-bit DLONG        
''     Result: None
''+Reads/Uses: CON/_WRTCMDRNREG   
''    +Writes: VAR/LONG/par1, par2, par3        
''      Calls: DoCommand>>activates #WrtCmdRnReg (in COG)
'-------------------------------------------------------------------------
par1 := cmd
par2 := regN
par3 := longValMSL
par4 := longValLSL

DoCommand(_WRTCMDRNDREG)
'--------------------------End of WriteCmdRnDLong-------------------------


PUB WriteCmdStr(cmd, strPtr)
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ WriteCmdStr │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a Command byte + a String into FPU                          
'' Parameters: -Command byte
''             -Pointer to HUB/String                      
''     Result: None
''+Reads/Uses: CON/_WRTCMDSTRING     
''    +Writes: VAR/LONG/par1, par2       
''      Calls: DoCommand>>activates #WrtCmdString (in COG)
''       Note: No need for counter byte, zero terminates string
'-------------------------------------------------------------------------
par1 := cmd
par2 := strPtr

DoCommand(_WRTCMDSTRING)
'-----------------------------End of WriteCmdStr--------------------------


PUB WriteRegs(fromHUBAddr_, cntr, startFPUReg)
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ WriteRegs │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Writes a 32-bit data array into FPU                          
'' Parameters: -Pointer to HUB address of data array
''             -Counter byte
''             -Register from where 32-bit data array is stored in FPU                
''     Result: None
''+Reads/Uses: CON/_WRTREGS     
''    +Writes: par1, par2, par3         
''      Calls: #WrtRegs (in COG)
''       Note: Cntr byte is the # of 32-bit data
'-------------------------------------------------------------------------
par1 := fromHUBAddr_
par2 := cntr
par3 := startFPUReg
DoCommand(_WRTREGS)
'------------------------------End of WriteRegs---------------------------


PUB ReadByte                                              
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadByte │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads a byte from FPU                           
'' Parameters: None                      
''     Result: Byte from FPU
''+Reads/Uses: CON/_RDBYTE
''    +Writes: VAR/LONG/par1        
''      Calls: DoCommand>>activates #RByte (in COG)
'-------------------------------------------------------------------------
DoCommand(_RDBYTE)

RESULT := par1               'Get fpuByte from par1
'------------------------------End of ReadByte----------------------------


PUB ReadReg                                             
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadReg │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a 32-bit Register from FPU                           
'' Parameters: None                      
''     Result: 32-bit LONG from FPU
''+Reads/Uses: CON/_RDREG    
''    +Writes: VAR/LONG/par1        
''      Calls: DoCommand>>activates #RdReg (in COG)
''       Note: To read 64-bit FPU registers, use this twice
'-------------------------------------------------------------------------
DoCommand(_RDREG)

RESULT := par1               'Get 32-bit register data from par1
'------------------------------End of ReadReg-----------------------------


PUB ReadStr                                             
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ ReadStr │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Reads a String from FPU                           
'' Parameters: None                      
''     Result: Pointer to HUB/str where the string from the FPU is copied
''+Reads/Uses: -CON/_SETREAD, _RDSTRING
''             -Pointer to VAR/BYTE[_MAXSTRL] str    
''    +Writes: None        
''      Calls: DoCommand>>activates #RdString (in COG)
'-------------------------------------------------------------------------
WriteCmd(_SETREAD)

DoCommand(_RDSTRING)

RESULT := @str               'Pointer to HUB/str
'-------------------------------------------------------------------------


PUB ReadRegs(fromFPUReg , cntr, startHUBAddress_)
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ ReadRegs │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Reads a 32-bit data array from the FPU                          
'' Parameters: -FPU register # from where 32-bit data array is read
''             -Counter byte
''             -HUB address from where 32-bit data array is stored                
''     Result: None
''+Reads/Uses: CON/_RDREGS     
''    +Writes: par1, par2, par3         
''      Calls: #RdRegs (in COG)
''       Note: Cntr byte is the # of 32-bit data
'-------------------------------------------------------------------------
WriteCmd(_SETREAD)

par1 := fromFPUReg
par2 := cntr
par3 := startHUBAddress_
DoCommand(_RDREGS)
'------------------------------End of ReadRegs----------------------------


PRI DoCommand(cmd)
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ DoCommand │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: -Initiates a PASM routine via the command register in HUB
''             -Waits for the completition of PASM routine             
'' Parameters: Code of command                      
''     Result: Directly none, PASM routine is performed
''+Reads/Uses: None    
''    +Writes: command        
''      Calls: Corresponding PASM routines in COG
''       Note: Waits until command register is zeroed by the PASM code
'-------------------------------------------------------------------------
command := cmd
REPEAT WHILE command
'-----------------------------End of DoCommand----------------------------


DAT '-------------------------Start of PASM code-------------------------- 
'-------------------------------------------------------------------------
'-------------DAT section for PASM program and COG registers--------------
'-------------------------------------------------------------------------

uMFPU64  ORG             0             'Start of PASM code

Get_Command                            'Entry label of fetch command loop

RDLONG   r1,             PAR WZ        'Read "command" register from HUB
IF_Z     JMP             #Get_Command  'Wait for a nonzero value

                                       'If dropped here, then command
                                       'received

ADD      r1,             #Cmd_Table-1  'Add it to the value of
                                       '#Cmd_Table-1

JMP      r1                            'Jump to command in Cmd_Table
                                       'JMP counts jumps in register units    
                                     
Cmd_Table                              'Command dispatch table
JMP      #Init                         '(Init=command No.1)
JMP      #Rst                          '(Reset=command No.2)
JMP      #CheckForReady                '(Check=command No.3)
JMP      #WaitForReady                 '(Wait=command No.4)
JMP      #WrtByte                      '(WrtByte=command No. 5)
JMP      #WrtCmdByte                   '(WrtCmdByte=command No. 6)
JMP      #WrtCmd2Bytes                 '(WrtCmd2Bytes=command No. 7)
JMP      #WrtCmd3Bytes                 '(WrtCmd3Bytes=command No. 8)
JMP      #WrtCmd4Bytes                 '(WrtCmd4Bytes=command No. 9)
JMP      #WrtCmdReg                    '(WrtCmdReg=command No. 10)
JMP      #WrtCmdRnReg                  '(WrtCmdRnReg=command No. 11)
JMP      #WrtCmdString                 '(WrtCmdString=command No. 12)
JMP      #RByte                        '(RByte=command No. 13)
JMP      #RdReg                        '(RdReg=command No. 14)
JMP      #RdString                     '(RdString=command No. 15)
JMP      #WrtCmdDreg                   '(WrtCmdDReg=command No. 16)
JMP      #WrtCmdRnDreg                 '(WrtCmdRnDReg=command No. 17)
JMP      #WrtRegs                      '(WrtRegs=command No. 18)
JMP      #RdRegs                       '(WrtRegs=command No. 19)

Done                                   'Common return point of commands
   
'Command has been sent to the FPU and in the case of Read operations the
'actual data readings has been finished. Signal this back to the SPIN code
'of this driver by clearing the "command" register, then jump back to the
'entry point of this PASM code and fetch the next command.

WRLONG   _Zero,          PAR           'Write 0 to HUB/VAR/LONG command    
JMP      #Get_Command                  'Get next command

'Note that "command" is cleared usually after it is sent with the
'following attached data, not when it is actually finished by the FPU.
'Exceptions to this are the Read operations - e.g. RByte, RdReg, RdRegs,
'RdSring - where the command register is cleared only after the fully
'finished data reading. In other words, you can send several processing
'commands plus write data one after the other to the FPU that has a 256
'bytes instruction buffer. If you send many commands quickly you should
'check the instruction buffer sometimes (e.g. after 256 bytes sent) to
'prevent overflow. FPU can perform autonomously some kind of tasks, e.g.
'driving digital lines and/or sending serial data depending on the values
'in its internal registers and timers. However, in a usual programming
'situation sometimes you would like to get back some results from it.
'Before any read operation you should wait for all sent commands to be
'executed. For that task there is the #WaitForReady procedure. The
'#CheckForReady procedure will just return the "NOT BUSY" status of the
'FPU. TRUE means that FPU is ready (Idling) and can do a read operation
'immediately. FALSE means the FPU is busy with processing commands. In
'this case you can send a command to it, but you have to wait with a Read
'operation.   


DAT 'Init
'-------------------------------------------------------------------------
'---------------------------------┌──────┐--------------------------------
'---------------------------------│ Init │--------------------------------
'---------------------------------└──────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: -Initializes DIO and CLK Pin Masks
'             -Stores HUB addresses of parameters.
'             -Preforms a simple FPU ready TEST (DIO line is LOW?)
' Parameters: -HUB/LONG/dio, clk, @str
'             -COG/par
'     Result: HUB/par1 (Flag of success)  
'+Reads/Uses: None
'    +Writes: -COG/dio_Mask, clk_Mask
'             -COG/par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'             -COG/par5_Addr_, str_Addr_
'             -COG/r1, r2
'      Calls: None
'-------------------------------------------------------------------------
Init

MOV      r1,             PAR           'Get HUB memory address of "command"

ADD      r1,             #4            'r1 now points to "par1" in HUB 
MOV      par1_Addr_,     r1            'Store this address
RDLONG   r2,             r1            'Load DIO pin No. from HUB into r2
MOV      dio_Mask, #1                  'Setup DIO pin mask 
SHL      dio_Mask, r2
ANDN     OUTA,           dio_Mask      'Pre-Set Data pin LOW
ANDN     DIRA,           dio_Mask      'Set Data pin as INPUT 

ADD      r1,             #4            'r1 now points to "par2" in HUB       
MOV      par2_Addr_,     r1            'Store this address
RDLONG   r2,             r1            'Load CLK pin No. from HUB into r2
MOV      clk_Mask, #1                  'Setup CLK pin mask
SHL      clk_Mask, r2
ANDN     OUTA,           clk_Mask      'Pre-Set Clock pin LOW (Idle)
OR       DIRA,           clk_Mask      'Set Clock pin as an OUTPUT

ADD      r1,             #4            'r1 now points to "par3" in HUB       
MOV      par3_Addr_,     r1            'Store this address
RDLONG   str_Addr_,      r1            'Read pointer to str char array

ADD      r1,             #4            'r1 now points to "par4" in HUB        
MOV      par4_Addr_,     r1            'Store this address
ADD      r1,             #4            'r1 now points to "par5" in HUB       
MOV      par5_Addr_,     r1            'Store this address                              

'Check DIO line for FPU ready
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary then not LOW, not ready
IF_C     MOV r1,         #0            'Prepare to send FALSE back 
IF_C     JMP #:Signal                  'Send it

NEG      r1,             #1            'Prepare to send TRUE back

:Signal  
WRLONG   r1,             par1_Addr_    'Send back result of DIO line test
  
JMP      #Done         
'-------------------------------End of Init-------------------------------


DAT 'Rst
'-------------------------------------------------------------------------
'----------------------------------┌─────┐--------------------------------
'----------------------------------│ Rst │--------------------------------
'----------------------------------└─────┘--------------------------------
'-------------------------------------------------------------------------
'     Action: Does a Software Reset of FPU
' Parameters: None
'     Result: "Okay" in HUB/VAR/LONG/par1
'+Reads/Uses: -CON/_RESET
'             -COG/_Reset_Delay
'             -COG/dio_Mask, par1_Addr_
'    +Writes: COG/r1, r4, time
'      Calls: #Write_Byte
'       Note: #Write_Byte and descendants use r2, r3
'-------------------------------------------------------------------------
Rst

MOV      r1,             #_RESET       'Byte to send
MOV      r4,             #10           '10 times

:Loop
CALL     #Write_Byte                   'Write byte to FPU 
DJNZ     r4,             #:Loop        'Repeat Loop 10 times 

MOV      r1,             #0            'Write a 0 byte to enforce DIO LOW
CALL     #Write_Byte

'Wait for a  Reset Delay of 10 msec
MOV      time,           CNT           'Find the current time
ADD      time,           _Reset_Delay  'Prepare a 10 msec Reset Delay
WAITCNT  time,           #0            'Wait for 10 msec

'Check DIO for FPU ready
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary (DIO not LOW) 
IF_C     MOV r1,         #0            'Not ready, send FALSE back
IF_C     JMP #:Signal

NEG      r1,             #1            'Ready, send TRUE back

:Signal  
WRLONG   r1,             par1_Addr_  

JMP      #Done
'--------------------------------End of Rst-------------------------------


DAT 'CheckForReady
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ CheckForReady │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Checks for an empty instruction buffer of the FPU. It
'             returns immediately with the result and does not wait for
'             that state unlike the WaitForReady command, which does.
' Parameters: None
'     Result: True OR false in par1 according to FPU's ready status
'+Reads/Uses: COG/dio_Mask, _Data_Period
'    +Writes: COG/time, CARRY flag
'      Calls: None
'       Note: -This routine is especially useful when you have more than
'             one FPU in your system. If you use the "WaitForReady" (as
'             "Wait" in SPIN) procedure then your main program will really
'             wait and wait... for the busy FPU. However, If you use this 
'             ( as "CheckReady" in SPIN) procedure then you have back the  
'             control immediately. If the checked FPU is busy this routine
'             will respond with FALSE and you may delegate the pending
'             computing task to an other FPU. Idling FPU will respond with
'             TRUE. In this way you can feed with tasks several FPUs
'             parallely.
'             -Prop is fast enough at 80 MHz to check DIO line before FPU
'             is able to rise DIO line in response to a received command.
'             That is why a Data Period Delay is inserted before the
'             check.
'             -You can send commands and data one after the other without
'             checking the "availability" of the FPU since it has a 256
'             bytes instruction buffer. However, before you read any data
'             back from the FPU you have to wait for all of its previous
'             instructions to be completed.
'-------------------------------------------------------------------------
CheckForReady

ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT

'Insert Data Period Delay 
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us Data Period Delay
WAITCNT  time,           #0            'Wait for 1.6 usec  

'Check DIO line for FPU ready, i.e. available
TEST     dio_Mask,       INA WC        'Read DIO state into 'C' flag
                                       'If Cary (DIO not LOW)
IF_C     MOV r1,         #0            'Not ready, send FALSE (busy) back
IF_C     JMP #:Signal                  'since the are unprocessed
                                       'instructions in the FPU. You can
                                       'send new processing commands but
                                       'not Read commands

NEG      r1,             #1            'DIO is LOW, i.e. FPU's instruction
                                       'buffer is empty and you can send a
                                       'Read commands or processing 
                                       'commands, as well. 

:Signal  
WRLONG   r1,             par1_Addr_  

JMP      #Done    
'--------------------------End of CheckForReady---------------------------


DAT 'WaitForReady
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WaitForReady │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Waits for a LOW DIO, i.e for a ready FPU with empty
'             instruction buffer
' Parameters: None
'     Result: None 
'+Reads/Uses: None
'    +Writes: None
'      Calls: #Wait_4_Ready
'-------------------------------------------------------------------------
WaitForReady
                                     
CALL     #Wait_4_Ready

JMP      #Done          
'-----------------------------End of WaitForReady-------------------------

                                      
DAT 'WrtByte 
'-------------------------------------------------------------------------
'--------------------------------┌─────────┐------------------------------
'--------------------------------│ WrtByte │------------------------------
'--------------------------------└─────────┘------------------------------
'-------------------------------------------------------------------------
'      Action: Sends a byte to FPU 
'  Parameters: Byte to send in HUB/par1 (LS byte of a 32-bit value)
'      Result: None 
' +Reads/Uses: COG/par1_Addr_
'     +Writes: COG/r1
'       Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtByte

RDLONG   r1,             par1_Addr_    'Load byte from HUB
CALL     #Write_Byte                   'Write it to FPU
   
JMP      #Done        
'------------------------------End of WrtByte-----------------------------


DAT 'WrtCmdByte 
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ WrtCmdByte │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus Data byte sequence to FPU
' Parameters: -Command byte in HUB/par1
'             -Data byte    in HUB/par2
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_
'    +Writes: COG/r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmdByte

'Send an 8 bit Command + 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'----------------------------End of WrtCmdByte----------------------------


DAT 'WrtCmd2Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd2Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 2 Data bytes to FPU
' Parameters: -Command byte in HUB/VAR/LONG/par1
'             -Data bytes   in HUB/VAR/LONG/par2, par3
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: COG/r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd2Bytes

'Send an 8 bit Command + 2 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmd2Bytes---------------------------


DAT 'WrtCmd3Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd3Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 3 Data bytes to FPU
' Parameters: -Command byte in HUB/par1
'             -Data bytes   in HUB/par2, par3, par4
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'    +Writes: COG/r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd3Bytes

'Send an 8 bit Command + 3 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par4_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmd3Bytes---------------------------


DAT 'WrtCmd4Bytes
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmd4Bytes │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus 4 Data bytes to FPU
' Parameters: -Command byte in HUB/VAR/LONG/par1
'             -Data bytes   in HUB/VAR/LONG/par2, par3, par4, par5
'     Result: None                                                                                             
'+Reads/Uses: -COG/par1_Addr_,par2_Addr_,par3_Addr_
'             -COG/par4_Addr_ ,par5_Addr
'    +Writes: COG/r1          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmd4Bytes

'Send an 8 bit Command + 3 x 8 bit data sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load 1st Data byte from par2
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par3_Addr_    'Load 2nd Data byte from par3
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par4_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
RDLONG   r1,             par5_Addr_    'Load 3nd Data byte from par4
CALL     #Write_Byte                   'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmd4Bytes---------------------------


DAT 'WrtCmdReg
'-------------------------------------------------------------------------
'------------------------------┌───────────┐------------------------------
'------------------------------│ WrtCmdReg │------------------------------
'------------------------------└───────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus a 32-bit Register sequence to FPU
' Parameters: -Command byte          in HUB/par1
'             -32-bit Register value in HUB/par2
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdReg

'Send an 8 bit Command + 32-bit Register sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par2_Addr_    'Load 32-bit Reg. value from par2
CALL     #Write_Register               'and write it to FPU
  
JMP      #Done
'----------------------------End of WrtCmdReg-----------------------------


DAT 'WrtCmdDReg
'-------------------------------------------------------------------------
'-----------------------------┌────────────┐------------------------------
'-----------------------------│ WrtCmdDReg │------------------------------
'-----------------------------└────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte plus a 64-bit Register sequence to FPU
' Parameters: -Command byte          in HUB/par1
'             -32-bit Register value in HUB/par2 MSL register
'             -32-bit Register value in HUB/par3 LSL register
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdDReg

'Send an 8 bit Command + 32-bit Register sequence to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par2_Addr_    'Load 32-bit Reg. value from par2
CALL     #Write_Register               'and write it to FPU
RDLONG   r4,             par3_Addr_    'Load 32-bit Reg. value from par3
CALL     #Write_Register               'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmdDReg-----------------------------


DAT 'WrtCmdRnReg
'-------------------------------------------------------------------------
'-----------------------------┌─────────────┐-----------------------------
'-----------------------------│ WrtCmdRnReg │-----------------------------
'-----------------------------└─────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + Reg[n] byte + 32-bit data to FPU
' Parameters: -Command byte in HUB/par1
'             -Reg[n] byte  in HUB/par2
'             -32-bit data  in HUB/par3
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_,par2_Addr_,par3_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdRnReg

'Send Command byte + Reg[n] byte + 32-bit data to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load Reg[n] from par2
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par3_Addr_    'Load 32-bit Reg. value from par3
CALL     #Write_Register               'and write it to FPU
  
JMP      #Done
'---------------------------End of WrtCmdRnReg----------------------------


DAT 'WrtCmdRnDReg
'-------------------------------------------------------------------------
'----------------------------┌──────────────┐-----------------------------
'----------------------------│ WrtCmdRnDReg │-----------------------------
'----------------------------└──────────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + Reg[n] byte + 64-bit data to FPU
' Parameters: -Command byte in HUB/par1
'             -Reg[n] byte  in HUB/par2
'             -32-bit data  in HUB/par3
'             -32-bit data  in HUB/par4
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_, par4_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtCmdRnDReg

'Send Command byte + Reg[n] byte + 32-bit data to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r1,             par2_Addr_    'Load Reg[n] from par2
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par3_Addr_    'Load 32-bit Reg. value from par3
CALL     #Write_Register               'and write it to FPU
RDLONG   r4,             par4_Addr_    'Load 32-bit Reg. value from par4
CALL     #Write_Register               'and write it to FPU
  
JMP      #Done
'----------------------------End of WrtCmdRnDReg--------------------------


DAT 'WrtCmdString
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ WrtCmdString │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a Command byte + String to FPU
' Parameters: - Command byte      in HUB/par1
'             - Pointer to String in HUB/par2
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_
'    +Writes: COG/r1, r4          
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
WrtCmdString

'Send Command byte + String (array of Chars then 0) to FPU
RDLONG   r1,             par1_Addr_    'Load FPU Command from par1
CALL     #Write_Byte                   'Write it to FPU
RDLONG   r4,             par2_Addr_    'Load pointer to HUB/Str from par2

'Write String from HUB to FPU
:Loop
RDBYTE   r1,             r4 WZ         'Read character from HUB
CALL     #Write_Byte                   'Write char or zero to FPU
                                       'If char was not zero  
IF_NZ    ADD r4,         #1            'Increment pointer to HUB memory
IF_NZ    JMP #:Loop                    'Read next byte 
  
JMP      #Done
'----------------------------End of WrtCmdString--------------------------


DAT 'WrtRegs
'-------------------------------------------------------------------------
'---------------------------------┌─────────┐-----------------------------
'---------------------------------│ WrtRegs │-----------------------------
'---------------------------------└─────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Writes a 32-bit data array to FPU
' Parameters: -Pointer to 32-bit data array in HUB/par1
'             -Counter byte                 in HUB/par2
'             -Register number              in HUB/par3
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: r1, r4, r5, r6          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
WrtRegs

'Fetch parameters
RDLONG   r6,             par1_Addr_     'Load HUB address of data array
RDLONG   r5,             par2_Addr_     'Load Counter from par2
RDLONG   r4,             par3_Addr_     'Load start Reg # from par3

'Load indirect  Reg(127) with the start Reg(#)
'SELECTA 127
MOV      r1,             #_SELECTA
CALL     #Write_Byte
MOV      r1,             #127
CALL     #Write_Byte
'Write Start Reg(#) into Reg(127)
MOV      r1,             #_LSETI
CALL     #Write_Byte
MOV      r1,             r4
CALL     #Write_Byte

'WRIND _LONG32, 127, Counter
MOV      r1,             #_WRIND
CALL     #Write_Byte
MOV      r1,             #_LONG32      'Data type
CALL     #Write_Byte
MOV      r1,             #127          'Indirect Reg(#)
CALL     #Write_Byte
MOV      r1,             r5            'Data counter
CALL     #Write_Byte

:Loop
RDLONG   r4,             r6            'Load next 32-bit value from HUB
CALL     #Write_Register               'and write it to FPU 
ADD      r6,             #4            'Increment pointer to HUB memory
DJNZ     r5,             #:Loop        'Decrement r5; jump if not zero 
  
JMP      #Done
'------------------------------End of WrtRegs-----------------------------


DAT 'RByte
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ RByte │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from FPU 
' Parameters: None
'     Result: byte entry in HUB/par1 (LSB of) 
'+Reads/Uses: COG/par1_Addr_
'    +Writes: COG/r1
'      Calls: #Read_Setup_Delay , #Read_Byte
'-------------------------------------------------------------------------
RByte

CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Byte
WRLONG   r1,             par1_Addr_    'Write r1 into HUB/par1
   
JMP      #Done          
'--------------------------------End of RByte-----------------------------


DAT 'RdReg
'-------------------------------------------------------------------------
'----------------------------------┌───────┐------------------------------
'----------------------------------│ RdReg │------------------------------
'----------------------------------└───────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 32-bit register from FPU 
' Parameters: None
'     Result: Register Entry in HUB/par1 
'+Reads/Uses: COG/par1_Addr_
'    +Writes: COG/r1                       
'      Calls: #Read_Setup_Delay, #Read_Register
'-------------------------------------------------------------------------
RdReg

CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Register
WRLONG   r1,             par1_Addr_    'Write r1 into HUB/par1
   
JMP      #Done         
'--------------------------------End of RdReg-----------------------------


DAT 'RdDReg
'-------------------------------------------------------------------------
'---------------------------------┌────────┐------------------------------
'---------------------------------│ RdDReg │------------------------------
'---------------------------------└────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 64-bit register from FPU 
' Parameters: None
'     Result: -32-bit Register Entry in HUB/par1
'             -32-bit Register Entry in HUB/par2
'+Reads/Uses: COG/par1_Addr_, par2_Addr_
'    +Writes: COG/r1                       
'      Calls: #Read_Setup_Delay, #Read_Register
'-------------------------------------------------------------------------
RdDReg

CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Register
WRLONG   r1,             par1_Addr_    'Write r1 into HUB/par1
CALL     #Read_Register
WRLONG   r1,             par2_Addr_    'Write r1 into HUB/par2

JMP      #Done         
'------------------------------End of RdDReg------------------------------

DAT 'RdString
'-------------------------------------------------------------------------
'-------------------------------┌──────────┐------------------------------
'-------------------------------│ RdString │------------------------------
'-------------------------------└──────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Reads String from the String Buffer of FPU 
' Parameters: None
'     Result: String in HUB/str 
'+Reads/Uses: HUB/CON/_READSTR
'    +Writes: COG/r1
'      Calls: #Wait_4_Ready, #Write_Byte, #Read_Setup_Delay, #Read_String  
'-------------------------------------------------------------------------
RdString

'Send a _READSTR command to read the String Buffer from FPU
CALL     #Wait_4_Ready 
MOV      r1,             #_READSTR     'Send _READSTR          
CALL     #Write_Byte
CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_String                  'Now read String Buffer of FPU
                                       'into HUB RAM   
JMP      #Done       
'------------------------------End of RdString----------------------------


DAT 'RdRegs
'-------------------------------------------------------------------------
'---------------------------------┌────────┐------------------------------
'---------------------------------│ RdRegs │------------------------------
'---------------------------------└────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Writes a 32-bit data from the FPU to HUB
' Parameters: -FPU Reg #                    in HUB/par1
'             -Counter byte                 in HUB/par2
'             -Pointer to 32-bit data array in HUB/par3
'     Result: None                                                                                             
'+Reads/Uses: COG/par1_Addr_, par2_Addr_, par3_Addr_
'    +Writes: r1, r4, r5, r6          
'      Calls: #Write_Byte, #Write_Reg
'-------------------------------------------------------------------------
RdRegs

'Fetch parameters
RDLONG   r4,             par1_Addr_     'Load start Reg # from par1
RDLONG   r5,             par2_Addr_     'Load Counter from par2
RDLONG   r6,             par3_Addr_     'LOAD HUB address from par3

'Load indirect  Reg(127) with the start Reg(#)
'SELECTA 127
MOV      r1,             #_SELECTA
CALL     #Write_Byte
MOV      r1,             #127
CALL     #Write_Byte
'Write Start Reg(#) into Reg(127)
MOV      r1,             #_LSETI
CALL     #Write_Byte
MOV      r1,             r4
CALL     #Write_Byte

CALL     #Wait_4_Ready                 'Before a read operation

'WRIND _LONG32, 127, Counter
MOV      r1,             #_RDIND
CALL     #Write_Byte
MOV      r1,             #_LONG32      'Data type
CALL     #Write_Byte
MOV      r1,             #127          'Indirect Reg(#)
CALL     #Write_Byte
MOV      r1,             r5            'Data counter
CALL     #Write_Byte

:Loop
CALL     #Read_Setup_Delay             'Insert Read Setup Delay
CALL     #Read_Register                'Read register from FPU
WRLONG   r1,             r6            'Write 32-bit reg data into HUB
ADD      r6,             #4  
DJNZ     r5,             #:Loop        'Get next register 
  
JMP      #Done
'------------------------------End of RdRegs------------------------------


DAT '---------------------------PRI PASM code-----------------------------
'Now come the "PRIVATE" PASM routines of this Driver. They are "PRI" in
'the sense that they do not have "command No." and they do not use par1,
'par2, etc.... They are service routines for the user accesable tasks.


DAT 'Wait_4_Ready
'-------------------------------------------------------------------------
'---------------------------┌──────────────┐------------------------------
'---------------------------│ Wait_4_Ready │------------------------------
'---------------------------└──────────────┘------------------------------
'-------------------------------------------------------------------------
'     Action: Waits for a LOW DIO, i.e for a ready FPU with empty
'             instruction buffer
' Parameters: None
'     Result: None 
'+Reads/Uses: COG/dio_Mask, time, _Data_Period
'    +Writes: -COG/time,
'             -CARRY flag
'      Calls: None
'       Note: Prop is fast enough at 80 MHz to check DIO line before FPU
'             is able to rise it in response to a received command. That's
'             why a Data Period Delay is inserted before the check.
'-------------------------------------------------------------------------
Wait_4_Ready
                                     
ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT

'Insert Data Period Delay 
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us Data Period Delay
WAITCNT  time,           #0            'Wait for 1.6 usec  

:Loop
TEST     dio_Mask,       INA WC        'Read SOUT state into 'C' flag
IF_C{
}JMP     #:Loop                        'Wait until DIO LOW

Wait_4_Ready_Ret
RET          
'----------------------------End of Wait_4_Ready--------------------------


DAT 'Write_Byte
'-------------------------------------------------------------------------
'-------------------------------┌────────────┐----------------------------
'-------------------------------│ Write_Byte │----------------------------
'-------------------------------└────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a byte to FPU 
' Parameters: Byte to send in Least Significant Byte of r1 32-bit register
'     Result: None 
'+Reads/Uses: COG/_Data_Period, dio_Mask
'    +Writes: COG/time
'      Calls: #Shift_Out_Byte
'-------------------------------------------------------------------------
Write_Byte

'Wait for the Minimum Data Period
MOV      time,           CNT           'Find the current time
ADD      time,           _Data_Period  '1.6 us minimum data period
WAITCNT  time,           #0            'Wait for  1.6 us

CALL     #Shift_Out_Byte               'Write byte to FPU via 2-wire SPI
   
Write_Byte_Ret
RET              
'-----------------------------End of Write_Byte---------------------------


DAT 'Write_Register
'-------------------------------------------------------------------------
'----------------------------┌────────────────┐---------------------------
'----------------------------│ Write_Register │---------------------------
'----------------------------└────────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Writes a 32-bit value to FPU
' Parameters: 32-bit value in r4 to send (MSB first)
'     Result: None 
'+Reads/Uses: COG/_Byte_Mask
'    +Writes: COG/r1
'      Calls: #Write_Byte
'-------------------------------------------------------------------------
Write_Register

'Send MS byte of r4
MOV      r1,             r4
ROR      r1,             #24
CALL     #Write_Byte

'Send 2nd byte of r4
MOV      r1,             r4
ROR      r1,             #16
CALL     #Write_Byte

'Send 3rd byte of r4
MOV      r1,             r4
ROR      r1,             #8
CALL     #Write_Byte

'Send LS byte of r4
MOV      r1,             r4
CALL     #Write_Byte
  
Write_Register_Ret
RET              
'--------------------------End of Write_Register--------------------------


DAT 'Read_Setup_Delay
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Read_Setup_Delay │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Inserts 15 usec Read Setup Delay
' Parameters: None
'     Result: None
'+Reads/Uses: COG/_Read_Setup_Delay 
'    +Writes: COG/time
'      Calls: None
'-------------------------------------------------------------------------
Read_Setup_Delay

MOV      time,           CNT                 'Find the current time
ADD      time,           _Read_Setup_Delay   '15 usec Read Setup Delay
WAITCNT  time,           #0                  'Wait for 15 usec
  
Read_Setup_Delay_Ret
RET              
'---------------------------End of Read_Setup_Delay-----------------------


DAT 'Read_Byte
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ Read_Byte │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
'     Action: Reads a byte from FPU
' Parameters: None
'     Result: Entry in r1
'+Reads/Uses: COG/_Read_Byte_Delay
'    +Writes: COG/time
'      Calls: #Shift_In_Byte
'-------------------------------------------------------------------------
Read_Byte

'Insert a 1 us Read byte Delay
MOV      time,           CNT               'Find the current time
ADD      time,           _Read_Byte_Delay  '1 us Read byte Delay
WAITCNT  time,           #0                'Wait for 1 usec       
  
CALL     #Shift_In_Byte                    'Read a byte from FPU
  
Read_Byte_Ret
RET              
'-----------------------------End of Read_Byte----------------------------


DAT 'Read_Register
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Read_Register │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Reads a 32-bit register form FPU
' Parameters: None
'     Result: Entry in r1
'+Reads/Uses: None
'    +Writes: COG/r3
'      Calls: #Read_Byte
'       note: #Read_Byte's descendant uses r2
'-------------------------------------------------------------------------
Read_Register

'Collect FPU register in r3 
CALL     #Read_Byte
MOV      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1
CALL     #Read_Byte
SHL      r3,             #8
ADD      r3,             r1

MOV      r1,             r3            'Done. Copy sum from r3 into r1
  
Read_Register_Ret
RET              
'-----------------------------End of Read_Register------------------------


DAT 'Read_String
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Read_String │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Reads a zero terminated string from FPU into HUB memory
' Parameters: None
'     Result: Sring in HUB/BYTE[_MAXSTRL] str
'+Reads/Uses: COG/str_Addr_
'    +Writes: COG/r1, r3
'      Calls: #Read_Byte
'       Note: Writes to HUB the terminating zero, as well
'-------------------------------------------------------------------------
Read_String

'Prepare loop to read string from FPU to HUB
MOV      r3,             str_Addr_
 
:Loop
CALL     #Read_Byte                    'Read a character from FPU
WRBYTE   r1,             r3            'Write character to HUB memory
CMP      r1,             #0 WZ         'String terminated if char is 0
                                       'If char not zero    
IF_NZ{
}ADD     r3,             #1            'Increment pointer to HUB memory 
IF_NZ{
}JMP     #:Loop                        'Jump to fetch next character 
  
Read_String_Ret
RET              
'-----------------------------End of Read_String--------------------------


DAT '--------------------------------SPI----------------------------------

DAT 'Shift_Out_Byte
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Shift_Out_Byte │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
'     Action: Shifts out a byte to FPU  (MSBFIRST) via 2-wire SPI
' Parameters: Byte to send in r1
'     Result: None
'+Reads/Uses: COG/dio_Mask         
'    +Writes: COG/r2, r3
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Shift_Out_Byte                               

OR       DIRA,           dio_Mask      'Set DIO pin as an OUTPUT 
MOV      r2,             #8            'Set length of byte         
MOV      r3,             #%1000_0000   'Set bit mask (MSBFIRST)
                                                               
:Loop
TEST     r1,             r3 WC         'Test a bit of data byte
MUXC     OUTA,           dio_Mask      'Set DIO HIGH or LOW
SHR      r3,             #1            'Prepare for next data bit  
CALL     #Clock_Pulse                  'Send a clock pulse
DJNZ     r2,             #:Loop        'Decrement r2; jump if not zero
         
Shift_Out_Byte_Ret
RET
'---------------------------End of Shift_Out_Byte-------------------------


DAT 'Shift_In_Byte
'-------------------------------------------------------------------------
'-----------------------------┌───────────────┐---------------------------
'-----------------------------│ Shift_In_Byte │---------------------------
'-----------------------------└───────────────┘---------------------------
'-------------------------------------------------------------------------
'     Action: Shifts in a byte from FPU (MSBPRE) via 2-wire SPI
' Parameters: None
'     Result: Entry byte in COG/r1
'+Reads/Uses: COG/dio_Mask 
'    +Writes: COG/r2
'      Calls: #Clock_Pulse
'-------------------------------------------------------------------------
Shift_In_Byte
ANDN     DIRA,           dio_Mask      'Set DIO pin as an INPUT
MOV      r2,             #8            'Set length of byte
MOV      r1,             #0            'Clear r1   
          
:Loop
TEST     dio_Mask,       INA WC        'Read Data Bit into 'C' flag
RCL      r1,             #1            'Left rotate 'C' flag into r1  
CALL     #Clock_Pulse                  'Send a clock pulse   
DJNZ     r2,             #:Loop        'Decrement r2; jump if not zero

Shift_In_Byte_Ret        
RET              
'---------------------------End of Shift_In_Byte--------------------------


DAT 'Clock_Pulse
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Clock_Pulse │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Sends a 50 ns LONG HIGH pulse to CLK pin of FPU
' Parameters: None
'     Result: None 
'+Reads/Uses: COG/clk_Mask 
'    +Writes: None
'      Calls: None
'       Note: At 80_000_000 Hz the CLK pulse width is about 50 ns(4 ticks)
'             and the CLK pin is pulsed at the rate about 2.5 MHz. This
'             rate is determined by the cycle time of the loop containing
'             the "CALL #Clock_Pulse" instruction. You can make the rate a
'             bit faster using inline code instead of DJNZ in the shift
'             in/out routines. However, the overal data burst speed will
'             not increase that much since the necessary delays affect it,
'             as well. They should remain in the time sequence, of course.
'-------------------------------------------------------------------------
Clock_Pulse

OR       OUTA,           clk_Mask      'Set CLK Pin HIGH
ANDN     OUTA,           clk_Mask      'Set CLK Pin LOW

Clock_Pulse_Ret         
RET
'---------------------------End of Clock_Pulse---------------------------- 


DAT '-----------COG memory allocation defined by PASM symbols-------------
  
'-------------------------------------------------------------------------
'----------------------Initialized data for constants---------------------
'-------------------------------------------------------------------------
_Zero                LONG    0

'-------------------------Delays at 80_000_000 MHz------------------------
_Data_Period         LONG    128       '1.6 us Minimum Data Period  
_Reset_Delay         LONG    800_000   '10 ms Reset Delay
_Read_Setup_Delay    LONG    1_200     '15 us Read Setup Delay
_Read_Byte_Delay     LONG    80        '1 us Read byte Delay

'-------------------------------------------------------------------------
'---------------------Uninitialized data for variables--------------------
'-------------------------------------------------------------------------

'----------------------------------Pin Masks------------------------------
dio_Mask             RES     1         'Pin mask in Propeller for DIO
clk_Mask             RES     1         'Pin mask in Propeller for CLK

'----------------------------HUB memory addresses-------------------------
par1_Addr_           RES     1
par2_Addr_           RES     1
par3_Addr_           RES     1
par4_Addr_           RES     1
par5_Addr_           RES     1
str_Addr_            RES     1

'--------------------Time register for delay processes--------------------
time                 RES     1

'------------------------Recycled Temporary Registers---------------------
r1                   RES     1         
r2                   RES     1         
r3                   RES     1
r4                   RES     1
r5                   RES     1
r6                   RES     1          

FIT                  496               'For sure


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