//-----------------------------------------------------------------------------
// Jason Wilden 2025
//-----------------------------------------------------------------------------
`default_nettype none
`include "../common_defs.svh"


module midi_parser (
    input `VAR logic       clk_i,
    input `VAR logic       rst_ni,

    // MIDI RX data in
    input `VAR logic       byte_valid_i,
    input `VAR midi_byte_t midi_byte_i,

    // Channel (0x17 = OMNI)
    input `VAR logic[4:0]  channel_i,

    // Message output (1,2 or 3 bytes)
    output logic          msg_valid_o,
    output logic[1:0]     msg_len_o,
    output midi_byte_t    msg_status_o,
    output midi_byte_t    msg_data1_o,
    output midi_byte_t    msg_data2_o,

    // Realtime message output (1 byte)
    output logic          rt_msg_valid_o,
    output midi_byte_t    rt_msg_o
);

  //-----------------------------------------------------------------------------
  // Byte classification
  //-----------------------------------------------------------------------------
  wire is_status_byte = midi_byte_i[7];
  wire is_real_time = midi_byte_i[7] && (midi_byte_i[7:3] == 5'b11111);
  wire is_single_byte_msg = (midi_byte_i[7:2] == 6'b111101);
  wire is_channel_voice = (run_stat & 8'hF0) < 8'hF0;
  wire is_our_channel = (channel_i == MidiOmni) || ((run_stat & 4'hF) == (channel_i[3:0] - 4'd1));

  //-----------------------------------------------------------------------------
  // State Registers
  //-----------------------------------------------------------------------------
  midi_byte_t run_stat, run_stat_next;
  logic third_byte_expected, third_byte_expected_next;
  logic sysex, sysex_next;
  
  midi_byte_t msg_status, msg_status_next;
  midi_byte_t msg_data1, msg_data1_next;
  midi_byte_t msg_data2, msg_data2_next;
  logic [1:0] msg_len, msg_len_next;
  logic msg_valid, msg_valid_next;
  
  logic rt_valid, rt_valid_next;
  midi_byte_t rt_msg, rt_msg_next;

  //-----------------------------------------------------------------------------
  // Sequential Logic
  //-----------------------------------------------------------------------------
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      run_stat <= MidiStatusInvalid;
      third_byte_expected <= 1'b0;
      sysex <= 1'b0;
      msg_status <= 8'h00;
      msg_data1 <= 8'h00;
      msg_data2 <= 8'h00;
      msg_len <= 2'b00;
      msg_valid <= 1'b0;
      rt_valid <= 1'b0;
      rt_msg <= 8'h00;
    end else begin
      run_stat <= run_stat_next;
      third_byte_expected <= third_byte_expected_next;
      sysex <= sysex_next;
      msg_status <= msg_status_next;
      msg_data1 <= msg_data1_next;
      msg_data2 <= msg_data2_next;
      msg_len <= msg_len_next;
      msg_valid <= msg_valid_next;
      rt_valid <= rt_valid_next;
      rt_msg <= rt_msg_next;
    end
  end

  //-----------------------------------------------------------------------------
  // Combinational Logic
  //-----------------------------------------------------------------------------
  always_comb begin
    // Default: hold state
    run_stat_next = run_stat;
    third_byte_expected_next = third_byte_expected;
    sysex_next = sysex;
    msg_status_next = msg_status;
    msg_data1_next = msg_data1;
    msg_data2_next = msg_data2;
    msg_len_next = msg_len;
    msg_valid_next = 1'b0;
    rt_valid_next = 1'b0;
    rt_msg_next = rt_msg;

    if (byte_valid_i) begin
      // Real-time messages - out of band, don't affect state
      if (midi_byte_i[7] && (midi_byte_i[7:3] == 5'b11111)) begin
        rt_valid_next = 1'b1;
        rt_msg_next = midi_byte_i;
      end 
      // SysEx draining
      else if (sysex) begin
        if (midi_byte_i == MidiStatusSysExEnd) begin
          sysex_next = 1'b0;
        end
      end
      // Status byte
      else if (midi_byte_i[7]) begin
        run_stat_next = midi_byte_i;
        third_byte_expected_next = 1'b0;

        if (midi_byte_i == MidiStatusSysExStart) begin
          sysex_next = 1'b1;
        end 
        // Single byte system messages (tune request, etc)
        else if (midi_byte_i[7:2] == 6'b111101) begin
          msg_status_next = midi_byte_i;
          msg_len_next = 2'd1;
          msg_valid_next = 1'b1;
        end
      end
      // Data byte
      else begin
        // Channel filtering (only for channel voice messages)
        if ((run_stat & 8'hF0) < 8'hF0) begin
          if (channel_i != MidiOmni && (run_stat & 4'hF) != (channel_i[3:0] - 4'd1)) begin
            // Wrong channel - ignore
          end else if (third_byte_expected) begin
            // Third byte of 3-byte message
            msg_data2_next = midi_byte_i;
            msg_len_next = 2'd3;
            msg_valid_next = 1'b1;
            third_byte_expected_next = 1'b0;
          end else begin
            // First data byte - determine message length
            case (run_stat & 8'hF0)
              MidiStatusNoteOn,
              MidiStatusNoteOff,
              MidiStatusControlChange,
              MidiStatusPitchBend,
              MidiStatusPolyPressure: begin
                // 3-byte messages
                msg_status_next = run_stat;
                msg_data1_next = midi_byte_i;
                msg_len_next = 2'd2;
                third_byte_expected_next = 1'b1;
              end

              MidiStatusProgramChange,
              MidiStatusChannelPressure: begin
                // 2-byte messages - complete
                msg_status_next = run_stat;
                msg_data1_next = midi_byte_i;
                msg_len_next = 2'd2;
                msg_valid_next = 1'b1;
              end

              default: begin
                // Invalid - ignore
              end
            endcase
          end
        end 
        // System messages (no channel filtering)
        else if (run_stat != MidiStatusInvalid) begin
          if (third_byte_expected) begin
            // Third byte of system message
            msg_data2_next = midi_byte_i;
            msg_len_next = 2'd3;
            msg_valid_next = 1'b1;
            third_byte_expected_next = 1'b0;
            run_stat_next = MidiStatusInvalid;
          end else begin
            case (run_stat)
              MidiStatusSongPos: begin
                // 3-byte system message
                msg_status_next = run_stat;
                msg_data1_next = midi_byte_i;
                msg_len_next = 2'd2;
                third_byte_expected_next = 1'b1;
              end

              MidiStatusSongSelect,
              MidiStatusTimingClock: begin
                // 2-byte system messages - complete
                msg_status_next = run_stat;
                msg_data1_next = midi_byte_i;
                msg_len_next = 2'd2;
                msg_valid_next = 1'b1;
                run_stat_next = MidiStatusInvalid;
              end

              default: begin
                // Unknown system message
                run_stat_next = MidiStatusInvalid;
              end
            endcase
          end
        end
      end
    end
  end

  //-----------------------------------------------------------------------------
  // Output assignments
  //-----------------------------------------------------------------------------
  assign msg_valid_o = msg_valid;
  assign msg_len_o = msg_len;
  assign msg_status_o = msg_status;
  assign msg_data1_o = msg_data1;
  assign msg_data2_o = msg_data2;
  assign rt_msg_valid_o = rt_valid;
  assign rt_msg_o = rt_msg;

endmodule

`default_nettype wire