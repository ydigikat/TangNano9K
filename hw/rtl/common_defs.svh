//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`ifndef __COMMON_DEFS_SVH__
`define __COMMON_DEFS_SVH__

// Iverilog does not support the var keyword however Gowin EDA requires this to
// be specified if the default nettype is none. This is because "input logic"
// could be interpreted as either a wire or variable.  Iverilog does support the
// wire type of course, but "input wire logic" would be nonsensical syntax.
`ifdef __ICARUS__
`define VAR
`else
`define VAR var
`endif

//-----------------------------------------------------------------------------
// Uart states
//-----------------------------------------------------------------------------
typedef enum logic[2:0] 
{  
  Idle,
  Start,
  Data,
  Stop
} uart_state_t;

//-----------------------------------------------------------------------------
// Memory files.  This should contain the firmware as hex values split 
// across the 4 (byte) lanes.  The files should be padded to MEM_SIZE with 0s.
//
// The firmware build generates these and places them in the handover folder.
//
// There seems to be no way to pass a `define on the command line to the 
// Gowin EDA tools so have to hard-code them here (Nov 2025).
//-----------------------------------------------------------------------------
`define B0_MEM_FILE "../handover/firmware_b0.hex"
`define B1_MEM_FILE "../handover/firmware_b1.hex"
`define B2_MEM_FILE "../handover/firmware_b2.hex"
`define B3_MEM_FILE "../handover/firmware_b3.hex"

`endif  // __COMMON_DEFS_SVH__
