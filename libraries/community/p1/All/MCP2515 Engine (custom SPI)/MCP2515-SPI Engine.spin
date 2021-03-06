{{File: MCP2515-SPI Engine.spin}}
{{

┌───────────────────────────────────┬─────────────────────────────────────────┬───────────────┐
│ MCP2515 SPI Engine - v0.5         │ (C)2007 Stephen Moraco, KZ0Q            │ 08 Dec 2007   │
├───────────────────────────────────┴─────────────────────────────────────────┴───────────────┤
│  This program is free software; you can redistribute it and/or                              │
│  modify it under the terms of the GNU General Public License as published                   │
│  by the Free Software Foundation; either version 2 of the License, or                       │
│  (at your option) any later version.                                                        │
│                                                                                             │
│  This program is distributed in the hope that it will be useful,                            │
│  but WITHOUT ANY WARRANTY; without even the implied warranty of                             │
│  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                              │
│  GNU General Public License for more details.                                               │
│                                                                                             │
│  You should have received a copy of the GNU General Public License                          │
│  along with this program; if not, write to the Free Software                                │
│  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                  │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│ This object runs in a single Cog and manages all direct interaction with the SPI            │
│ interface to the attached MCP 2515 CAN Controller from Microchip.                           │
│                                                                                             │
│ For this purpose, we look like:                                                             │
│    ┌──────────────────┐       ┌────────────┐                                                │
│    │            /Reset├──────→│ /Reset     │                                                │
│    │ Propeller     /CS├──────→│ /CS        │                                                │
│    │                  │       │       MCP  │                                                │
│    │          SPI CLK ├──────→│ SCK   2515 │                                                │
│    │     SPI DATA OUT ├──────→│ SI         │                                                │
│    │      SPI DATA IN │←──────┤ SO         │                                                │
│    └──────────────────┘       └────────────┘                                                │
│                                                                                             │
│ Architectural differences from the original SPI Engine v1.1:                                │
│                                                                                             │
│   The major design goal of this implementation is to increase performance of                │
│   SPI communication with the specific MCP 2515 CAN Controller chip. In order to             │
│   accomplish this goal we did some things differently.                                      │
│                                                                                             │
│   The following are differences from the excellent SPI Engine v1.1 implementation:          │
│                                                                                             │
│       This SPI assembly is no longer configurable to different bit ordering over            │
│       the SPI bus. The MCP2515 can only talk one order so this was removed.                 │
│                                                                                             │
│       Pin bit-masks which are used in this and the SPI Engine in this case are              │
│       calculated at engine startup, not as each command is processed.                       │
│                                                                                             │
│       The major architectural change from the SPI Engine is this engine is invoked once     │
│       foreach MCP2515 transaction. These are mostly writes-followed by reads but some       │
│       are reads or writes only.  One can accomplish the same interaction with the           │
│       SPI Engine but it switches between spin and assembly multiple times within            │
│       a single transaction where this does not. This engine activates as each transaction   │
│       request arrives and finshes the entire transaction with no switching out of           │
│       assembly.                                                                             │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│ To Do:                                                                                      │
│   - need to add "arbitrary length" register read and register write commands                │
│     this would allow things like zero'ing the receive registers, etc.                       │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│ Revision History                                                                            │
│                                                                                             │
│ v0.5  created by Stephen Moraco from original "SPI Engine" code v1.1 by                     │
│        Beau Schwabe (Parallax)  Started  with bursting at ~9.9 KBps, need much higher       │
└─────────────────────────────────────────────────────────────────────────────────────────────┘


The MicroChip page for the MCP 2515 Stand-alone CAN Controller
 http://www.microchip.com/stellent/idcplg?IdcService=SS_GET_PAGE&nodeId=1335&dDocName=en010406

The MCP 2551 CAN Transceiver page:
 http://www.microchip.com/stellent/idcplg?IdcService=SS_GET_PAGE&nodeId=1335&dDocName=en010405


}}

CON                                                     ' MCP2515 SPI Engine Constants
  #1,_OUT1IN0, _OUT1IN1, _OUT2IN1, _OUT3IN0, _OUT4IN0, _OUT1OUT13, _OUT1IN13    ' (internal use)


  MODE_NORMAL =   $00 '/* Normal (send and receive messages)               */
  MODE_SLEEP =    $20 '/* Wait for interrupt                               */
  MODE_LOOPBACK = $40 '/* Testing - messages stay internal                 */
  MODE_LISTEN =   $60 '/* Listen only -- don't send                        */
  MODE_CONFIG =   $80 '/* Configuration (1XX0 0000 is Config)              */

  ' Start Parameter: is /RESET line avail in hardware?
  NO_RESET_LINE = FALSE
  USE_RESET_LINE = TRUE

  ' -----------------
  ' General I/O pins
  '  (Debug port
  '      3-pin hdr)
  ' -----------------
' DBG_b1 = 15                   ' U2 Pin16
' DBG_b2 = 16                   ' U2 Pin19    (echo /Reset line)
' DBG_b3 = 18                   ' U2 Pin21    (echo /CS line)

   ' SPI Instruction Set:
  ' MCP 2515 commands sent via SPI
  '   immediately after asserting /CS
  CMD_RESET          = %1100_0000
  CMD_READ           = %0000_0011
  CMD_WRITE          = %0000_0010
  CMD_READ_STATUS    = %1010_0000
  CMD_RX_STATUS      = %1011_0000
  CMD_BIT_MODIFY     = %0000_0101
  ' For single buffer reads
  CMD_RTS_TxBFR0  = %1000_0001
  CMD_RTS_TxBFR1  = %1000_0010
  CMD_RTS_TxBFR2  = %1000_0100


  CMD_RD_RXBFR_BASE  = %1001_0000                       ' CMD_RD_RXBFR_BASE = %1001_0nm0
  '-------------------------------
  ' specify one of the following
  PARM_RD_RX0BF_SIDH = %0000_0000
  PARM_RD_RX0BF_D0   = %0000_0010
  PARM_RD_RX1BF_SIDH = %0000_0100
  PARM_RD_RX1BF_D0   = %0000_0110


  CMD_LD_TXBFR_BASE   = %0100_0000                      ' CMD_LD_TX_BFR_BASE = %0100_0abc
  '-------------------------------
  ' specify one of the following
  PARM_LD_TXBFR0_SIDH = %0100_0000
  PARM_LD_TXBFR0_D0   = %0100_0001
  PARM_LD_TXBFR1_SIDH = %0100_0010
  PARM_LD_TXBFR1_D0   = %0100_0011
  PARM_LD_TXBFR2_SIDH = %0100_0100
  PARM_LD_TXBFR2_D0   = %0100_0101
  '-------------------------------
  ' or-together one of the following...
  OR_PARM_LD_TXBFR0  = %0000_0000
  OR_PARM_LD_TXBFR1  = %0000_0010
  OR_PARM_LD_TXBFR2  = %0000_0100
  ' with one of the following...
  OR_PARM_LD_TXBFR_SIDH = %0000_0000
  OR_PARM_LD_TXBFR_D0   = %0000_0001


  ' For multi-buffer reads
  CMD_RTS_TxBFR_BASE = %1000_0000                      ' CMD_RTS_TxBFR_BASE = %1000_0abc
  '-------------------------------
  ' or-together one or more of the following
  OR_PARM_RTS_TXBFR1  = %0000_0001
  OR_PARM_RTS_TXBFR2  = %0000_0010
  OR_PARM_RTS_TXBFR3  = %0000_0100


  ' MCP2515 Register Names

  REG_BFPCTRL   = %0000_1100
  REG_TXRTSCTRL = %0000_1101
  REG_CANSTAT   = %0000_1110
  REG_CANCTRL   = %0000_1111

  REG_TEC       = %0001_1100
  REG_REC       = %0001_1101

  REG_CNF3      = %0010_1000
  REG_CNF2      = %0010_1001
  REG_CNF1      = %0010_1010
  REG_CANINTE   = %0010_1011
  REG_CANINTF   = %0010_1100
  REG_EFLG      = %0010_1101

  REG_TXB0CTRL  = %0011_0000
  REG_TXB1CTRL  = %0100_0000
  REG_TXB2CTRL  = %0101_0000
  REG_RXB0CTRL  = %0110_0000
  REG_RXB1CTRL  = %0111_0000


  ' MCP2515 Bit Names for fields/bits within
  '  bit-addressable registers

  BIT_RDSTATUS_RX0IF   = %0000_0001
  BIT_RDSTATUS_RX1IF   = %0000_0010
  BIT_RDSTATUS_TX0REQ  = %0000_0100
  BIT_RDSTATUS_TX0IF   = %0000_1000
  BIT_RDSTATUS_TX1REQ  = %0001_0000
  BIT_RDSTATUS_TX1IF   = %0010_0000
  BIT_RDSTATUS_TX2REQ  = %0100_0000
  BIT_RDSTATUS_TX2IF   = %1000_0000

  ' NOTE these BIT_INTF_ def's apply to INTE bits too
  '  although the name would reflect E vs. F but who cares here?
  BIT_INTF_RX0IF   = %0000_0001 ' Rx buffer 0 full
  BIT_INTF_RX1IF   = %0000_0010 ' Rx buffer 1 full
  BIT_INTF_TX0IF   = %0000_0100 ' Tx buffer 0 empty
  BIT_INTF_TX1IF   = %0000_1000 ' Tx buffer 1 empty
  BIT_INTF_TX2IF   = %0001_0000 ' Tx buffer 2 empty
  BIT_INTF_ERRIF   = $0010_0000 ' multiple sources: see EFLG register
  BIT_INTF_WAKIF   = %0100_0000 ' Wakeup interrupt
  BIT_INTF_MERIF   = %1000_0000 ' Message Error

  BIT_EFLG_EWARN  = %0000_0001   ' TEC or REC = or > 96! (in Warning state), auto resets
  BIT_EFLG_RXWAR  = %0000_0010   ' REC = or > 96! (in WARNING state), auto resets
  BIT_EFLG_TXWAR  = %0000_0100   ' TEC = or > 96! (in WARNING state), auto resets
  BIT_EFLG_RXEP   = %0000_1000   ' REC = or > 128! (in ERROR-PASSIVE state), auto resets
  BIT_EFLG_TXEP   = %0001_0000   ' TEC = or > 128! (in ERROR-PASSIVE state), auto resets
  BIT_EFLG_TXBO   = %0010_0000   ' TEC at 255! (in BUS-OFF ERROR state), auto resets
  BIT_EFLG_RX0OVR = %0100_0000   ' Valid message rcvd but Rx0B is full! (so is Rx1B if rollover mode enabled)
  BIT_EFLG_RX1OVR = %1000_0000   ' Valid message rcvd but Rx1B is full!

{
    There are eight MCP2515 SPI bus sequences:
   ┌──────────────────────────────────────────────┐
   │  (1) Request-to-send (RTS) Instruction|Reset │
   │ Write(cmdByte)                               │
   │                                              │
   │  (2) Load Tx Buffer Instruction              │
   │ Write(cmdByte,Len,@data)                     │
   │  (3) Write Instruction                       │
   │ WriteReg(cmdByte,regId,Len,@data)            │
   │  (4) Bit-modify Instruction                  │
   │ WriteRegBitModify(cmdByte,regId,mask,value)  │
   │                                              │
   │  (5) Read Rx Buffer Instruction              │
   │  (6) Read Status Instruction                 │
   │ ReadStatus(cmdByte) : Value                  │
   │    becomes --> Read(cmdByte,2,@value)        │
   │  (7) RX Status Instruction                   │
   │ Read(cmdByte,Len,@data)                      │
   │                                              │
   │  (8) Read Instruction                        │
   │ ReadReg(cmdByte,regId,Len,@data)             │
   │   - where Len [1-n]                          │
   └──────────────────────────────────────────────┘
   ┌─────┬──────────────────────────────────────────────────────────┬─────────────────────────┐
   │ (1) │ ▶CmdByte                                                 │ w          w[1]         │
   │     │                                                          │                         │
   │     │                                                          │                         │
   │ (2) │ ▶CmdByte, [ ▶{dataOutByte} ... ]                         │ ww[,w]     w[2-n]       │
   │     │                                                          │                         │
   │ (3) │ ▶CmdByte,    ▶{addrByte} [ ▶{dataOutByte} ... ]          │ www[,w]    w[3-n]       │
   │     │                                                          │                         │
   │ (4) │ ▶CmdByte,    ▶{addrByte}   ▶{maskByte}   ▶{dataOutByte}  │ wwww       w[4]         │
   │     │                                                          │                         │
   │     │                                                          │                         │
   │ (5) │ ▶CmdByte, [ ◀{dataInByte} ... ]                          │ wr[,r]     w[1],r[1-n]  │
   │ (6) │ ▶CmdByte,    ◀{dataInByte} ◀{dataInByteCopy}             │ wrr        w[1],r[2]    │
   │     │                                                          │                         │
   │     │                                                          │                         │
   │ (7) │ ▶CmdByte,    ◀{dataInByte} ◀{dataInByteCopy}             │ wrr        w[1],r[2]    │
   │     │                                                          │                         │
   │     │                                                          │                         │
   │ (8) │ ▶CmdByte,    ▶{addrByte} [ ◀{dataInByte} ... ]           │ wwr[,r]    w[2],r[1-n]  │
   │     │                                                          │                         │
   └─────┴──────────────────────────────────────────────────────────┴─────────────────────────┘
}

DAT                                                     ' MCP2515 SPI Engine Variables for interface Cog

m_nCogId                        long            0       ' COG ID for the SPI I/F
m_nLockID                       long            0       ' semaphore ID for the SPI I/F

m_nMcp2515clkFreq               long            0
m_bUseResetLine                 long            0

m_nCommand                      long            0       ' semaphore ID for the SPI I/F
m_nMcpInstructionWithBuffer     long            0,0     ' our cmd w/dataPointer form


PUB Start(bResetPin_p, bCsPin_p, SPIRxPin_p, SPITxPin_p, SPIClkPin_p, nMCPFreq_p, bUseResetLine_p) : okay

'' Start the MCP2515 SPI module and allocate our lock

  ' inform the Cog of pins assigned to SPI and selects for the MCP2515
  ' place them into the region that will be loaded into the Cog at start

  pinRxD := SPIRxPin_p
  pinTxD := SPITxPin_p
  pinCLK := SPIClkPin_p

  pinCSb := bCsPin_p
  pinRESETb := bResetPin_p

'  pinDbgB1 :=  DBG_b1
'  pinDbgB2 :=  DBG_b2
'  pinDbgB3 :=  DBG_b3

  m_nMcp2515clkFreq := nMCPFreq_p
  m_bUseResetLine := bUseResetLine_p

' dira[pinDbgB1]~~                                      ' Set pin to output
' dira[pinDbgB2]~~                                      ' Set pin to output
' dira[pinDbgB3]~~                                      ' Set pin to output
  'outa[pinDbgB1]~                                      ' write initial value of "0" (1 coming up says Cog Started)
' outa[pinDbgB2]~~                                      ' write initial value of "1"
  'outa[pinDbgB3]~                                      ' write initial value of "0" (1 coming up says Cog Started)

'' setup the semaphore protecting SPI use
  m_nLockID := locknew

'' Reset outboard MCP2515, via pin (or command, as selected) and wait for reset to complete
  Reset2515

'' start the backend SPI Cog...
  okay := backendStart


PUB Stop

'' Stop SPI Engine - frees a cog and a lock

  ' if the Cog has been started, stop it
  if m_nCogId
    cogstop(m_nCogId~ - 1)

  ' mark the id field as never been started
  m_nCogId~

  ' clear our command/address value
  m_nCommand~

  ' return our lock (if we have one)
  '  so it can be used by others
  if m_nLockID <> -1
    lockret(m_nLockID)


PUB Reset2515 | nDelayINuSec

'' 12.0 SPI Interface

'' 12.2 Reset instruction

'' Strobe the /Reset line to reset the MCP2515 chip
'' then pause for 128 2515 clock cycles for it to come
'' ready again.

  ' prevent others from using this SPI interface during this request
  LockSPI

  ' stobe the reset line to reset MCP2515
  if m_bUseResetLine
    reset2515ViaResetLine
  else
    reset2515ViaCmd

  ' wait for chip to be ready to talk to us after reset
  nDelayINuSec := clkfreq / (m_nMcp2515clkFreq/128)
  Pause(nDelayINuSec)

  ' now let others use this SPI interface, we're done
  UnlockSPI

PRI reset2515ViaResetLine                               ' reset vi /RESET hardware line

' The /RESET line is available, let's use it to reset the MCP2515 chip
' NOTE: there is no locking here since our caller has handled the locking and unlocking!

  ' first make sure the line is not set so the MCP will see the reset!
  UnResetCAN2515chip

  ' now stobe the reset line to reset MCP2515
  ResetCAN2515chip
  UnResetCAN2515chip


PRI reset2515ViaCmd | nMcpInstruction                   ' reset by sending RESET command byte (hardware line not present)

' The /RESET line is NOT available, let's send a command to reset the MCP2515 chip
' NOTE: there is no locking here since our caller has handled the locking and unlocking!

  ' get our reset command
  nMcpInstruction := CMD_RESET

  ' now hand our command to the engine to be acted upon
  setcommand(_OUT1IN0, @nMcpInstruction)


PUB ReadRegister(nRegAddr_p) : nRegValue | nMcpInstruction

'' 12.3 Read Instruction

'' Read and return the value of one of the MCP 2515 Registers [$00-$7F]

  ' prevent others from using this SPI interface during this request
  LockSPI

  nMcpInstruction := (CMD_READ << 8) | (nRegAddr_p & $7F)

  nRegValue := OUTANDIN(_OUT2IN1, nMcpInstruction)

  ' now let others use this SPI interface, we're done
  UnlockSPI


PUB UnloadRxBuffer(nRxBffr_p, pDataBffr_p)

'' 12.4 Read RX Buffer Instruction

'' Read a receive buffer {nRxBffr_p} into the caller memory at location at {pDataBffr}
''
'' Ex: CAN.ReadRxBuffer(CAN#RX0BF, @MyBffr)

  ' prevent others from using this SPI interface during this request
  LockSPI

  m_nMcpInstructionWithBuffer[0] := CMD_RD_RXBFR_BASE | (nRxBffr_p & $06)
  m_nMcpInstructionWithBuffer[1] := pDataBffr_p

  ' now hand our command to the engine to be acted upon
  setcommand(_OUT1IN13, @m_nMcpInstructionWithBuffer)

  ' now let others use this SPI interface, we're done
  UnlockSPI


PUB WriteRegister(nRegAddr_p, nRegValue_p) | nMcpInstruction

'' 12.5 Write Instruction

'' Write {nRegValue_p} [$00-$ff] to one of the MCP 2515 Registers {nRegAddr_p} [$00-$7F]

  ' prevent others from using this SPI interface during this request
  LockSPI

  nMcpInstruction := (CMD_WRITE << 16) | ((nRegAddr_p & $7F) << 8) | (nRegValue_p & $FF)

  ' now hand our command to the engine to be acted upon
  setcommand(_OUT3IN0, @nMcpInstruction)

  ' now let others use this SPI interface, we're done
  UnlockSPI


PUB LoadTxBuffer(nTxBffr_p, pDataBffr_p)

'' 12.6 Load TX Buffer Instruction

  ' prevent others from using this SPI interface during this request
  LockSPI

  m_nMcpInstructionWithBuffer[0] := CMD_LD_TXBFR_BASE | (nTxBffr_p & $03)
  m_nMcpInstructionWithBuffer[1] := pDataBffr_p

  ' now hand our command to the engine to be acted upon
  setcommand(_OUT1OUT13, @m_nMcpInstructionWithBuffer)

  ' now let others use this SPI interface, we're done
  UnlockSPI


PUB SendTxBuffer(nTxBffrSet_p) | nMcpInstruction

'' 12.7 Request-to-send (RTS) Instruction

  ' prevent others from using this SPI interface during this request
  LockSPI

  nMcpInstruction := CMD_RTS_TxBFR_BASE | (nTxBffrSet_p & $07)

  ' now hand our command to the engine to be acted upon
  setcommand(_OUT1IN0, @nMcpInstruction)

  ' now let others use this SPI interface, we're done
  UnlockSPI


PUB GetReadStatus : nStatusValue | nMcpInstruction

'' 12.8 Read Status Instruction

'' Return the MCP2515 Read Status

  ' prevent others from using this SPI interface during this request
  LockSPI

  nMcpInstruction := CMD_READ_STATUS

  nStatusValue := OUTANDIN(_OUT1IN1, nMcpInstruction)

  ' now let others use this SPI interface, we're done
  UnlockSPI


PUB GetReceiveStatus : nStatusValue | nMcpInstruction

'' 12.9 RX Status Instruction

'' Return the MCP2515 Receive Status

  ' prevent others from using this SPI interface during this request
  LockSPI

  nMcpInstruction := CMD_RX_STATUS

  nStatusValue := OUTANDIN(_OUT1IN1, nMcpInstruction)

  ' now let others use this SPI interface, we're done
  UnlockSPI


PUB BitModifyRegister(nRegAddr_p, nRegMask_p, nRegValue_p) | nMcpInstruction

'' 12.10 Bit Modify Instruction

  ' prevent others from using this SPI interface during this request
  LockSPI

  nMcpInstruction := (CMD_BIT_MODIFY << 24) | ((nRegAddr_p & $7F) << 16) | ((nRegMask_p & $FF) << 8) | (nRegValue_p & $FF)

  ' now hand our command to the engine to be acted upon
  setcommand(_OUT4IN0, @nMcpInstruction)

  ' now let others use this SPI interface, we're done
  UnlockSPI


'----------------------------------------------------------------------------------------------
PRI LockSPI                                             ' lock the MCP2515 SPI Engine Semaphore for exclusive use

  ' if we have a semaphore, lock it now
  if m_nLockID <> -1
    repeat until not lockset(m_nLockID)
    'outa[pinDbgB1]~                                    ' write "0" : we are locked


PRI UnlockSPI                                           ' unlock the MCP2515 SPI Engine Semaphore (we're done with it)

  ' if we have a semaphore, unlock it now
  if m_nLockID <> -1
    lockclr(m_nLockID)
    'outa[pinDbgB1]~~                                   ' write "1" : we are unlocked


PRI Pause(nPeriod_p)                                    ' Pause for {nPeriod_p} in uS

    waitcnt(clkfreq/1_000_000 * nPeriod_p + cnt)


PRI ResetCAN2515chip                                    ' assert the /RESET signal

  dira[pinRESETb]~~             ' set direction to output
  outa[pinRESETb]~              ' write "0" to pin (reset the MCP chip)
' dira[pinDbgB2]~~              ' set direction to output
' outa[pinDbgB2]~               ' write "0" to pin (reset the MCP chip)


PRI UnResetCAN2515chip                                  ' de-assert the /RESET signal

  outa[pinRESETb]~~             ' write "1" to pin (take the MCP chip out of reset)
' outa[pinDbgB2]~~              ' write "1" to pin (take the MCP chip out of reset)


'----------------------------------------------------------------------------------------------
PRI BackendStart : okay                                 ' start the MCP2515 SPI Engine Cog

'' Start Backend SPI Engine - starts a cog
'' returns false if no cog available

    stop
    okay := m_nCogId := cognew(@SPICogStart, @m_nCommand) + 1


PRI OUTANDIN(nCmdValue_p, nMcpInstru_p) | nRegValue     ' perform the form of command which returns a byte value

    'outa[pinDbgB1]~                                    ' write "0" : requesting value
    'nRegValue := -1
    setcommand(nCmdValue_p, @nMcpInstru_p)
    'outa[pinDbgB1]~~                                   ' write "1" : grabbing result!!!
    'repeat until nRegValue <> -1
    result := nRegValue


PRI setcommand(nCmdValue_p, pArguments_p)               ' pass command to MCP2515 SPI Engine Cog and wait for acknowledgement that it has it

    'outa[pinDbgB1]~                                    ' write "0" : sending value to Cog
  ' if the MCP2515 SPI Engine Cog has not been started...
    if m_nCogId == 0
    ' start it
       m_nCommand := 0
       backendStart

    m_nCommand := nCmdValue_p << 16 | (pArguments_p & $7fff) ' write command and MAIN RAM address
    repeat while m_nCommand                             ' wait for command to be cleared, signifying receipt
    'outa[pinDbgB1]~~                                   ' write "1" : Cog says move-on!!!

    ' NOTE: lost this outa debug in later transactions... problem with code here? moving this to mods of par reg!! in Cog


'##############################################################################################
DAT                                                     ' our MCP2515 SPI Engine assembly code and data
              org       0
'
' SPI Engine - main loop
'
SPICogStart
' prepare masks and set direction of pins
              mov     mskRxD,         #1        wz      '     Configure SPI Rx Data PIN
              shl     mskRxD,         pinRxD
              muxz    dira,           mskRxD            '       Set Rx Data to an INPUT
              ' -------------
              mov     mskTxD,         #1        wz      '     Configure SPI Tx Data PIN
              shl     mskTxD,         pinTxD
              muxnz   dira,           mskTxD            '       Set Tx Data to an OUTPUT
              muxz    outa,           mskTxD            '         PreSet DataPin LOW
              ' -------------
              mov     mskCLK,         #1        wz      '     Configure SPI CLOCK PIN
              shl     mskCLK,         pinCLK
              muxnz   dira,           mskCLK            '       Set CLOCK to an OUTPUT
              muxz    outa,           mskCLK            '         PreSet CLOCK LOW
              ' -------------
              mov     mskCSb,         #1        wz      '     Configure /CS PIN
              shl     mskCSb,         pinCSb
              muxnz   dira,           mskCSb            '       Set /CS to an OUTPUT
              muxnz   outa,           mskCSb            '         PreSet /CS HIGH
              ' -------------
'              mov     mskDbgB3,       #1        wz      '     Configure /CS(DBG) PIN
'              shl     mskDbgB3,       pinDbgB3
'              muxnz   dira,           mskDbgB3          '       Set /CS(DBG) to an OUTPUT
'              muxnz   outa,           mskDbgB3          '         PreSet /CS(DBG) HIGH
              ' -------------
'              mov     mskDbgB1,       #1        wz      '     Configure /CS(DBG) PIN
'              shl     mskDbgB1,       pinDbgB1
'              muxnz   dira,           mskDbgB1          '       Set par(DBG) to an OUTPUT
'              muxnz   outa,           mskDbgB1          '         PreSet par(DBG) HIGH
              ' -------------

loop          rdlong  t1,par          wz                ' WAIT FOR COMMAND... forever...
        if_z  jmp     #loop
'              muxz    dira,           mskDbgB1          ' (DBG) set pin to output, again...       WARNING WARNING
'              muxnz   outa,           mskDbgB1          ' (DBG) show acting on command: pin=LOW
              movd    :argP,#arg0                       ' get 2 arguments ; arg0 to arg1
              mov     t2,t1                             '     │
              mov     t3,#2                             ' ───┘
:argP         rdlong  arg0,t2
              add     :argP,d0                          ' point to next long in COG (incr COG ptr)
              add     t2,#4                             ' point to next addr in MAIN (incr MAIN ptr)
              djnz    t3,#:argP

              add     t1,#8                             '  calculate address of the ") | nRegValue" variable
              mov     pNRegValue,t1                     '  preserve address so we can write the result
                                                        '   variable back to Spin language.

              ror     t1,#16+2                          ' lookup command address
              add     t1,#jumps
              movs    :table,t1
              rol     t1,#2
              shl     t1,#3
:table        mov     t2,0
              shr     t2,t1
              and     t2,#$FF
              jmp     t2                                ' jump to command

jumps         byte    0                                 '0
              byte    OUT1IN0_                          '1
              byte    OUT1IN1_                          '2
              byte    OUT2IN1_                          '3
              byte    OUT3IN0_                          '4
              byte    OUT4IN0_                          '5
              byte    OUT1OUT13_                        '6
              byte    OUT1IN13_                         '7
              byte    NotUsed_                          '8
NotUsed_      jmp     #loop
'##############################################################################################
OUT1IN0_      ' write one byte, receive nothing
              wrlong  zero,par                          ' zero command to signify command received
              mov     nbrBits,        #8        wz      '     Load number of data bits, Z = NZ(0)
'              muxnz   outa,           mskDbgB1          ' (DBG) show telling Cog we're done: pin=HIGH
              muxz    outa,           mskCSb            '          Set /CS LOW (assert CS)
'              muxz    outa,           mskDbgB3          '          Set /CS(DBG) LOW
              mov     msBitMask,      #%1000_0000       '          Create MSB mask
              call    #WRnBITS
              mov     nbrBits,        #8        wz,nr   '     Set Z to NZ state
              muxnz   outa,           mskCSb            '          Set /CS HIGH (deassert CS)
'              muxnz   outa,           mskDbgB3          '          Set /CS(DBG) HIGH
              jmp     #loop                             '     Go wait for next command

'----------------------------------------------------------------------------------------------
OUT1IN1_      ' write one byte, receive one byte returning it to caller
              wrlong  zero,par                          ' zero command to signify command received
              mov     nbrBits,        #8        wz      '     Load number of data bits, Z = NZ
'              muxnz   outa,           mskDbgB1          ' (DBG) show telling Cog we're done: pin=HIGH
              muxz    outa,           mskCSb            '          Set /CS LOW (assert CS)
'              muxz    outa,           mskDbgB3          '          Set /CS(DBG) LOW
              mov     msBitMask,      #%1000_0000       '          Create MSB mask
              call    #WRnBITS
              call    #RD1BYTE                          '     read byte returning it to caller result variable
              mov     nbrBits,        #8        wz,nr   '     Set Z to NZ state
              muxnz   outa,           mskCSb            '          Set /CS HIGH (deassert CS)
'              muxnz   outa,           mskDbgB3          '          Set /CS(DBG) HIGH
              jmp     #loop                             '     Go wait for next command

'----------------------------------------------------------------------------------------------
OUT2IN1_      ' write two bytes, receive one byte returning it to caller
              wrlong  zero,par                          ' zero command to signify command received
              mov     nbrBits,        #16       wz      '     Load number of data bits, Z = NZ
'              muxnz   outa,           mskDbgB1          ' (DBG) show telling Cog we're done: pin=HIGH
              muxz    outa,           mskCSb            '          Set /CS LOW (assert CS)
'              muxz    outa,           mskDbgB3          '          Set /CS(DBG) LOW
              mov     msBitMask,      #%1               '          Create MSB mask     ;     load with "1"
              rol     msBitMask,      nbrBits           '          Shift "1" N number of bits to the left.
              ror     msBitMask,      #1                '          Shifting the number of bits left actually puts
                                                        '          us one more place to the left than we want. To
                                                        '          compensate we'll shift one position right.
              call    #WRnBITS
              call    #RD1BYTE                          '     read byte returning it to caller result variable
              mov     nbrBits,        #8        wz,nr   '     Set Z to NZ state
              muxnz   outa,           mskCSb            '          Set /CS HIGH (deassert CS)
'              muxnz   outa,           mskDbgB3          '          Set /CS(DBG) HIGH
              jmp     #loop                             '     Go wait for next command

'----------------------------------------------------------------------------------------------
OUT3IN0_      ' write three bytes, receive nothing
              wrlong  zero,par                          ' zero command to signify command received
              mov     nbrBits,        #24       wz      '     Load number of data bits, Z = NZ
'              muxnz   outa,           mskDbgB1          ' (DBG) show telling Cog we're done: pin=HIGH
              muxz    outa,           mskCSb            '          Set /CS LOW (assert CS)
'              muxz    outa,           mskDbgB3          '          Set /CS(DBG) LOW
              mov     msBitMask,      #%1               '          Create MSB mask     ;     load with "1"
              rol     msBitMask,      nbrBits           '          Shift "1" N number of bits to the left.
              ror     msBitMask,      #1                '          Shifting the number of bits left actually puts
                                                        '          us one more place to the left than we want. To
                                                        '          compensate we'll shift one position right.
              call    #WRnBITS
              mov     nbrBits,        #8        wz,nr   '     Set Z to NZ state
              muxnz   outa,           mskCSb            '          Set /CS HIGH (deassert CS)
'              muxnz   outa,           mskDbgB3          '          Set /CS(DBG) HIGH
              jmp     #loop                             '     Go wait for next command

'----------------------------------------------------------------------------------------------
OUT4IN0_      ' write four bytes, receive nothing
              wrlong  zero,par                          ' zero command to signify command received
              mov     nbrBits,        #32       wz      '     Load number of data bits, Z = NZ
'              muxnz   outa,           mskDbgB1          ' (DBG) show telling Cog we're done: pin=HIGH
              muxz    outa,           mskCSb            '          Set /CS LOW (assert CS)
'              muxz    outa,           mskDbgB3          '          Set /CS(DBG) LOW
              mov     msBitMask,      #%1               '          Create MSB mask     ;     load with "1"
              rol     msBitMask,      nbrBits           '          Shift "1" N number of bits to the left.
              ror     msBitMask,      #1                '          Shifting the number of bits left actually puts
                                                        '          us one more place to the left than we want. To
                                                        '          compensate we'll shift one position right.
              call    #WRnBITS
              mov     nbrBits,        #8        wz,nr   '     Set Z to NZ state
              muxnz   outa,           mskCSb            '          Set /CS HIGH (deassert CS)
'              muxnz   outa,           mskDbgB3          '          Set /CS(DBG) HIGH
              jmp     #loop                             '     Go wait for next command

'----------------------------------------------------------------------------------------------
OUT1OUT13_    ' write one byte, then write 8/13 bytes from callers buffer
              mov     nbrBits,        #8        wz      '     Load number of data bits, Z = NZ
              muxz    outa,           mskCSb            '          Set /CS LOW (assert CS)
'              muxz    outa,           mskDbgB3          '          Set /CS(DBG) LOW
              mov     msBitMask,      #%1000_0000       '          Create MSB mask
              call    #WRnBITS
              ' calculate our copy and receive counts
              and     arg0,           #1        wz,nr   ' LS-bit of command indicates what we are sending
        if_nz mov     bytXferCt,      #2                '       1 =  8 byte transfer (2 longs read from MAIN)
        if_nz mov     cpyLongCt,      #2
        if_z  mov     bytXferCt,      #3                '       0 = 13 byte transfer (3 longs + byte read from MAIN)
        if_z  mov     cpyLongCt,      #4
              ' go copy users' data to our buffer (for "len" bytes)
              movd    :argR,#nIntrnlBffr0               ' place address of COG RAM into read instruction
              mov     t2,arg1                           ' load callers pointer (to MAIN RAM) into t2
:argR         rdlong  nIntrnlBffr0,t2                   ' read a LONG from callers buffer into COG RAM
              add     :argR,d0                          ' point to next long in COG (incr COG ptr)
              add     t2,#4                             ' point to next long in MAIN (incr MAIN ptr)
              djnz    cpyLongCt,#:argR                  ' if we're not done, do another
              ' post command complete (after we've copied data from callers buffer)
              wrlong  zero,par                          ' zero command to signify command received
              and     arg0,           #1        wz,nr   ' set Z = NZ(0)
'              muxnz   outa,           mskDbgB1          ' (DBG) show telling Cog we're done: pin=HIGH
              ' send 2 or 3 words followed by 13th byte if longer send
:SNxtLongI    mov     arg0,            nIntrnlBffr0     ' copy 1st word into location being sent
              mov     nbrBits,        #32               ' Load/reload number of data bits
              call    #SendLong                          ' go send 32 bits
              add     :SNxtLongI,#1                     ' point to next COG long to be sent
              djnz    bytXferCt,#:SNxtLongI             ' if more longs to be sent, go do next
              and     arg0,           #1        wz,nr   ' LS-bit of command indicates what we are sending
        if_nz jmp     #:SendExit                        ' if short form (8vs13) then skip 13th byte
              mov     arg0,            nIntrnlBffr3     ' MS-8bits is 13th byte to be sent
              mov     nbrBits,        #8                '     Load number of data bits (send MS-8bits)
              mov     msBitMask,      #$08              '          Create MSB mask     ;     load with "1"
              rol     msBitMask,      #24               '          Shift "1" N number of bits to the left.
              call    #WRnBITS
:SendExit
              ' now close out this effort
              mov     nbrBits,        #8        wz,nr   '     Set Z to NZ state
              muxnz   outa,           mskCSb            '          Set /CS HIGH (deassert CS)
'              muxnz   outa,           mskDbgB3          '          Set /CS(DBG) HIGH
              jmp     #loop                             '     Go wait for next command

SendLong
'  The bytes as setup in memory are not the order they need to be sent over SPI...
'  So, let's send long.byte[0], then .byte[1], then .byte[2] and finally .byte[3] <SIGH>
              mov     t4,             arg0
              mov     nbrBits,        #8                '     Load number of data bits
              mov     msBitMask,      #%1000_0000       '          Create MSB mask     ;     load with "1"
              call    #WRnBITS
              mov     arg0,            t4
              shl     msBitMask,      #8                '          Adjust MSB mask
              mov     nbrBits,        #8                '     Load number of data bits
              call    #WRnBITS
              mov     arg0,            t4
              shl     msBitMask,      #8                '          Adjust MSB mask
              mov     nbrBits,        #8                '     Load number of data bits
              call    #WRnBITS
              mov     arg0,            t4
              shl     msBitMask,      #8                '          Adjust MSB mask
              mov     nbrBits,        #8                '     Load number of data bits
              call    #WRnBITS
SendLong_ret ret

'----------------------------------------------------------------------------------------------
OUT1IN13_     ' write one byte, then read 8/13 bytes into callers buffer
              mov     nbrBits,        #8        wz      '     Load number of data bits, Z = NZ
              muxz    outa,           mskCSb            '          Set /CS LOW (assert CS)
'              muxz    outa,           mskDbgB3          '          Set /CS(DBG) LOW
              mov     msBitMask,      #%1000_0000       '          Create MSB mask
              call    #WRnBITS
              ' calculate our copy and receive counts
              and     arg0,           #1        wz,nr   ' LS-bit of command indicates what we are receiving
        if_nz mov     bytXferCt,      #2                '       1 =  8 byte transfer (2 longs written to MAIN)
        if_nz mov     cpyLongCt,      #2
        if_z  mov     bytXferCt,      #3                '       0 = 13 byte transfer (3 longs+1 byte written to MAIN)
        if_z  mov     cpyLongCt,      #4
              ' read "len" bytes and store into our buffer
:RNxtLong     mov     nbrBits,        #32               ' Load number of data bits
              call    #RDnBITS                          ' Receive N bits
              call    #ReorderBytes                     ' Reorder the bits
:RNxtMovI     mov     nIntrnlBffr0,   rcvLong           ' save them to Cog RAM
              add     :RNxtMovI,D0                      ' point to next Cog RAM long to contain a read value
              djnz    bytXferCt,#:RNxtLong              ' if we're not done, do another
              and     arg0,           #1        wz,nr   ' LS-bit of command indicates what we are receiving
       if_nz  jmp     #:XferToCaller                    ' if short form (8vs13) then skip 13th byte
              mov     nbrBits,        #8                ' Load number of data bits in last byte
              call    #RDnBITS                          ' Receive N bits
              rol     rcvLong,        #24               ' Move data byte into MS-Byte location within long
              call    #ReorderBytes                     ' Reorder the bits
              mov     nIntrnlBffr3,   rcvLong           ' and stuff this long into our Cog RAM buffer
:XferToCaller
             ' copy our buffer bytes to callers buffer
              movd    :argW,#nIntrnlBffr0               ' place address of COG RAM into write instruction
              mov     t2,arg1                           ' load callers pointer into MAIN RAM into t2
:argW         wrlong  nIntrnlBffr0,t2                   ' write the LONG to callers buffer
              add     :argW,d0                          ' point to next long in COG (incr COG ptr)
              add     t2,#4                             ' point to next addr in MAIN (incr MAIN ptr)
              djnz    cpyLongCt,#:argW                  ' if we're not done, do another

              ' post command complete (after we've returned data to callers buffer)
              wrlong  zero,par                          ' zero command to signify command received
              mov     nbrBits,        #8        wz,nr   '     Set Z to NZ state
'              muxnz   outa,           mskDbgB1          ' (DBG) show telling Cog we're done: pin=HIGH
              muxnz   outa,           mskCSb            '          Set /CS HIGH (deassert CS)
'              muxnz   outa,           mskDbgB3          '          Set /CS(DBG) HIGH
              jmp     #loop                             '     Go wait for next command

ReorderBytes
' have bytes in SPI order in 'rcvLong' Cell
'  let's flip them into in-memory order before handing them back to caller
'  we need to:   [3] -> [0]
'                [2] -> [1]
'                [1] -> [2]
'                [0] -> [3]
              mov       t4,rcvLong                      ' save starting value so we can over-write
              ' build [0]
              mov       t3,t4                   ' get orig value
              shr       t3,#24                  ' shift [3] into [0]
              and       t3,#$ff                 ' isolate just [0]
              mov       rcvLong,t3              ' move to result
              ' build [1]
              mov       t3,t4                   ' get orig value
              shr       t3,#8                   ' shift [2] into [1]
              and       t3,byt1mask             ' isolate to just [1]
              or        rcvLong,t3              ' or into result
              ' build [2]
              mov       t3,t4                   ' get orig value
              shl       t3,#8                   ' shift [1] into [2]
              and       t3,byt2mask             ' isolate to just [2]
              or        rcvLong,t3              ' or into result
              ' build [2]
              mov       t3,t4                   ' get orig value
              shl       t3,#24                  ' shift [0] into [3]
              and       t3,byt3mask             ' isolate to just [3]
              or        rcvLong,t3              ' or into result
ReorderBytes_ret ret
'
'==============================================================================================
WRnBITS                                                 'WRnBITS Entry
              mov     nbrBits,        #42       wz,nr   '     Load number of data bits
'              muxz    outa,           mskTxD            '          PreSet DataPin LOW
'              muxz    outa,           mskCLK            '          PreSet ClockPin LOW
MSBFIRST_                                               '     Send Data MSBFIRST
              mov     t3,             arg0              '          Load t3 with DataValue
:MSB_Sout     test    t3,             msBitMask wc      '          Test MSB of DataValue
              muxc    outa,           mskTxD            '          Set DataBit HIGH or LOW
              shl     t3,             #1                '          Prepare for next DataBit
              mov     mskCLK,         #0        wz,nr   '     Clock Pin
              muxz    outa,           mskCLK            '          Set ClockPin HIGH
              muxnz   outa,           mskCLK            '          Set ClockPin LOW
              djnz    nbrBits,        #:MSB_Sout        '          Decrement nbrBits ; jump if not Zero
              mov     t3,             #0        wz      '          Force DataBit LOW
              muxnz   outa,           mskTxD

WRnBITS_ret ret                                         ' return to caller
'
'==============================================================================================
RD1BYTE                                                 ' RD1BYTE Entry
              mov     rcvByte,        #0                ' zero our receive long
              mov     nbrBits,        #8        wz      '     Load number of data bits
'              muxz    outa,           mskCLK            '          PreSet ClockPin LOW
MSBPRE_1                                                '     Receive Data MSBPRE
:MSBPRE1_Sin  test    mskRxD,         ina       wc      '          Read Data Bit into 'C' flag
              rcl     rcvByte,        #1                '          rotate "C" flag into return value
              mov     mskCLK,         #0        wz,nr   '     Clock Pin
              muxz    outa,           mskCLK            '          Set ClockPin HIGH
              muxnz   outa,           mskCLK            '          Set ClockPin LOW
              djnz    nbrBits,        #:MSBPRE1_Sin     '          Decrement nbrBits ; jump if not Zero
Update_RD1BYTE                                          '     Pass received data to OUTANDIN receive variable
              wrlong  rcvByte,        pNRegValue        ' write received byte to | nResult variable in MAIN RAM

RD1BYTE_ret ret                                         ' return to caller
''
'
'==============================================================================================
RDnBITS                                                 ' RDnBITS Entry
              mov     nbrBits,        #0        wz,nr   '     Load number of data bits
'              muxz    outa,           mskCLK            '          PreSet ClockPin LOW
MSBPRE_2                                                '     Receive Data MSBPRE
:MSBPRE2_Sin  test    mskRxD,         ina       wc      '          Read Data Bit into 'C' flag
              rcl     rcvLong,        #1                '          rotate "C" flag into return value
              mov     mskCLK,         #0        wz,nr   '     Clock Pin
              muxz    outa,           mskCLK            '          Set ClockPin HIGH
              muxnz   outa,           mskCLK            '          Set ClockPin LOW
              djnz    nbrBits,        #:MSBPRE2_Sin     '          Decrement nbrBits ; jump if not Zero

RDnBITS_ret ret                                         ' return to caller
''
'==============================================================================================

'
' ########################### Passed data from starting Cog ##################################
'
pinRESETb               long    0                       ' The pins connected to the MCP2515 lines
pinCSb                  long    0
pinRxD                  long    0
pinTxD                  long    0
pinCLK                  long    0

'pinDbgB1                long    0                       ' General DEBUG pins (Logic Analyzer hooked to these
'pinDbgB2                long    0                       '   on development board)
'pinDbgB3                long    0

'
' ########################### Initialized data ###############################################
'
zero                    long    0                       ' Used to pass a zero'd long to MAIN RAM
d0                      long    $200                    ' Used to increment d-field of rdlong/wrlong
byt1mask                long    $0000ff00
byt2mask                long    $00ff0000
byt3mask                long    $ff000000

'
' ########################### Uninitialized data #############################################
'
nbrBits                 res     1                       ' Holds # of Bits as each byte is sent/received
msBitMask               res     1                       ' Holds the single bit mask, indicating where are MS-Bit is
mskRxD                  res     1                       ' Holds RxData Pin mask
mskTxD                  res     1                       ' Holds TxData Pin mask
mskCLK                  res     1                       ' Holds CLK Pin mask
mskCSb                  res     1                       ' Holds CSb Pin mask

'mskDbgB1                res     1
'mskDbgB2                res     1
'mskDbgB3                res     1


cpyLongCt               res     1                       ' Holds the number of LONGs to read/write from/to MAIN RAM (in case of 8/13-byte I/O)
bytXferCt               res     1

rcvByte                 res     1                       ' Holds the byte while we are receiving it
rcvLong                 res     1                       ' Holds n-bytes (1-4) while we are receiving them


t1                      res     1                       '     Used for DataPin mask     and     COG shutdown
t2                      res     1                       '     Used for CLockPin mask    and     COG shutdown
t3                      res     1                       '     Used to hold DataValue SHIFTIN/SHIFTOUT
t4                      res     1

pNRegValue              res     1                       ' Holds pointer to MAIN RAM of the nRegValue variable on call stack

arg0                    res     1                       ' 1-4 data bytes to be written
arg1                    res     1                       ' ignored - or pointer to users MAIN RAM buffer (long-aligned)

nIntrnlBffr0            res     1                       ' four of these make our 16-byte buffer
nIntrnlBffr1            res     1                       ' four of these make our 16-byte buffer
nIntrnlBffr2            res     1                       ' four of these make our 16-byte buffer
nIntrnlBffr3            res     1                       ' four of these make our 16-byte buffer



                        FIT     496