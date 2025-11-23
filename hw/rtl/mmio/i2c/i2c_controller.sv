//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none
`include "../../common_defs.svh"

module i2c_controller #(
  parameter integer SYS_CLK_HZ,
  parameter integer I2C_CLK_HZ
)(
  input `VAR logic       clk_i,
  input `VAR logic       rst_ni,

  // Transaction
  input `VAR logic       start_i,
  input `VAR logic       restart_i,
  input `VAR logic       read_enable_i,
  input `VAR logic [6:0] dev_addr_i,
  input `VAR logic [7:0] data_i,

  // Outputs
  output     logic       done_o,
  output     logic       busy_o,
  output     logic       ack_error_o,
  output     logic [7:0] data_o,

  // I2C pins
  inout      tri         sda_io,
  inout      tri         scl_io
);

// ---------------------------------------------------------
// Clock Divider
// ---------------------------------------------------------
localparam int DIVISOR = SYS_CLK_HZ / (I2C_CLK_HZ * 2);

logic [$clog2(DIVISOR)-1:0] clk_cnt, clk_cnt_d;
logic scl_phase, scl_phase_d;

// ---------------------------------------------------------
// Tri-state lines 
// ---------------------------------------------------------
logic sda_drive, sda_drive_d;   // 1 = drive low, 0 = release
logic scl_drive, scl_drive_d;

// ---------------------------------------------------------
// State encoding
// ---------------------------------------------------------
typedef enum logic [4:0] {
    Idle,                   // Waiting for start
    Start,                  // Pull SDA low while SCL high
    Restart,                // Generate a repeated Start
    SendAddr,               // Address + RW bit 
    AddrAck,                // Sample ack from worker on Addr send
    SendData,               // Write a data byte
    DataAck,                // Sample ack from worker on Data Data
    ReadData,               // Read a data byte
    ControllerAck,          // Send Ack/Nack after read to worker
    Stop,                   // Generate stop condition
    Done                    // Transaction complete
} state_t;

state_t state, state_d;

// ---------------------------------------------------------
// Registers
// ---------------------------------------------------------
logic [3:0] bit_cnt, bit_cnt_d;   // Count down from 7 when shifting bits
logic [7:0] read_sr, read_sr_d;   // Shift register for incoming data

logic busy, busy_d;               // Status signals
logic done, done_d;
logic ack_error, ack_error_d;

always_ff @(posedge clk_i) begin
  if (!rst_ni) begin
    clk_cnt <= 0;
    scl_phase <= 1'b1;
    state <= Idle;
    bit_cnt <= 4'd0;
    
    sda_drive <= 1'b0;
    scl_drive <= 1'b0;

    read_sr <= 8'd0;

    busy <= 1'b0;
    done <= 1'b0;
    ack_error <= 1'b0;

  end else begin
    clk_cnt <= clk_cnt_d;
    scl_phase <= scl_phase_d;
    state <= state_d;
    bit_cnt <= bit_cnt_d;

    sda_drive <= sda_drive_d;
    scl_drive <= scl_drive_d;

    read_sr <= read_sr_d;

    busy <= busy_d;
    done <= done_d;
    ack_error <= ack_error_d;
  end
end

// ---------------------------------------------------------
// Next state logic
// ---------------------------------------------------------
logic send_bit;

always_comb begin
  // Default hold
  clk_cnt_d = clk_cnt;
  scl_phase_d = scl_phase;
  state_d = state;
  bit_cnt_d = bit_cnt;

  sda_drive_d = sda_drive;
  scl_drive_d = scl_drive;

  read_sr_d = read_sr;

  busy_d = busy;
  done_d = done;
  ack_error_d = ack_error;

  send_bit = 0;

  // Clock divider
  if(clk_cnt == DIVISOR-1) begin
    clk_cnt_d = 0;
    scl_phase_d = ~scl_phase;       // Toggle SCL phase
  end else begin
    clk_cnt_d = clk_cnt + 1'd1;
  end

  // Drive SCL low during low phase, release during high phase.
  scl_drive_d = (scl_phase == 0);

  unique case(state)
    // Wait for start request
    Idle:begin
      done_d = 0;
      busy_d = 0;
      sda_drive_d = 0;      // Release SDA line
      if(start_i) begin
        busy_d = 1;
        state_d = Start;
      end
    end
    // Start/Restart condition: SDA low while SCL high
    Start, Restart:begin
      sda_drive_d = 1;
      bit_cnt_d = 'd7;
      state_d = SendAddr;
    end
    // 7-bit address + rw bit. SDA only changes during SCL low
    // as I2C requires SDA stable during SCL high.
    SendAddr:begin
      if(!scl_phase) begin        
        // For bit 0 we send R/W instead of an address bit.
        send_bit = (bit_cnt == 0) ? read_enable_i : dev_addr_i[bit_cnt];        
        sda_drive_d = (send_bit == 0) ? 1:0;

        // If that was the last bit, then we want an ack.
        if(bit_cnt == 0) state_d = AddrAck;
        else bit_cnt_d = bit_cnt - 1'd1;
      end
    end
    // Sample ack from worker, the worker pulls SDA low to
    // indicate an ack. The controller releases the SDA and
    // samples while SCL is high.
    AddrAck:begin
      sda_drive_d = 0;      // Release for worker ack.
      if(scl_phase) begin
        // We got a NACK!
        if(sda_io) ack_error_d = 1;

        // Reset for next byte
        bit_cnt_d = 'd7;

        if(read_enable_i) state_d = ReadData;
        else state_d = SendData;        
      end
    end
    // Shift out data bits, MSB first.
    SendData:begin
      if(!scl_phase) begin
        sda_drive_d = (data_i[bit_cnt] == 0) ? 'b1:'b0;
        if(bit_cnt==0) state_d = DataAck;
        else bit_cnt_d = bit_cnt - 1'd1;
      end
    end
    // Sample Ack from worker after byte has been sent
    DataAck:begin
      sda_drive_d = 0;    // Release for worker ack.
      if(scl_phase) begin
        // That was a NACK!
        if(sda_io) ack_error_d = 1'd1;

        // After write we do a stop or restart.
        if(restart_i) state_d = Restart;
        else state_d = Stop;        
      end
    end
    // Sample 8 bits from worker. Controller releases the SDA
    // and the worker drives the bits.  Controller samples on
    // SCL high.
    ReadData:begin
       sda_drive_d = 0; // release SDA for input

        if(scl_phase) begin
          // Sample and shift in bit
          read_sr_d = {read_sr[6:0], sda_io};
          if (bit_cnt == 0) state_d = ControllerAck;          
        end

        if (!scl_phase) begin
          if (bit_cnt != 0) bit_cnt_d = bit_cnt - 1'd1;
        end
    end
    // For single byte reads we just send a NACK (release SDA).
    // ACK (SDA low) would request another byte.
    ControllerAck:begin
      sda_drive_d = 0;    // NACK

      if(scl_phase) begin
        if(restart_i) state_d = Restart;
        else state_d = Stop;
      end
    end
    // Stop condition.  SDA goes high while SCL high.
    Stop:begin
      if(!scl_phase) begin
        sda_drive_d = 1'd1;
      end else begin
        sda_drive_d = 0;
        state_d = Done;  
      end
    end
    // Pulse the done signal and return to Idle
    Done:begin
      busy_d = 0;
      done_d = 1'b1;
      state_d = Idle;
    end

    default: begin
    end
  endcase
end

// ---------------------------------------------------------
// Outputs
// ---------------------------------------------------------
assign busy_o = busy;
assign done_o = done;
assign ack_error_o = ack_error;
assign data_o = read_sr;
// Open drain buffers.
assign sda_io = sda_drive ? 1'b0 : 1'bz;
assign scl_io = scl_drive ? 1'b0 : 1'bz;


endmodule

`default_nettype wire