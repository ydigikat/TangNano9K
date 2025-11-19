//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none 
`timescale 1ns / 10ps

module midi_parser_tb ();

  //------------------------------------------------------------------------------
  // Test control
  //------------------------------------------------------------------------------
  integer test_failures = 0;
  integer test_count = 0;

  //------------------------------------------------------------------------------
  // DUT parameters and signals
  //------------------------------------------------------------------------------
  logic byte_valid, msg_valid, rt_msg_valid;
  logic [7:0] midi_byte, msg_status, msg_data1, msg_data2, rt_msg;
  logic [4:0] channel;
  logic [1:0] len;


  //------------------------------------------------------------------------------
  // Clocks and resets
  //------------------------------------------------------------------------------
  logic clk=0, rst_n;

  always #5 clk = ~clk;

  initial begin
    rst_n = 0;              
    byte_valid = 0;       
    midi_byte = 0;
    channel = 5'h17;    // OMNI mode for most tests
    #50;
    rst_n = 1;
  end

  //------------------------------------------------------------------------------
  // Unit under test
  //------------------------------------------------------------------------------
  midi_parser uut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .byte_valid_i(byte_valid),
    .midi_byte_i(midi_byte),
    .channel_i(channel),
    .msg_valid_o(msg_valid),
    .msg_len_o(len),
    .msg_status_o(msg_status),
    .msg_data1_o(msg_data1),
    .msg_data2_o(msg_data2),
    .rt_msg_valid_o(rt_msg_valid),
    .rt_msg_o(rt_msg)
  );

  //------------------------------------------------------------------------------
  // Helper task to send a single MIDI byte
  //------------------------------------------------------------------------------
  task automatic send_byte(input logic [7:0] byte_in);
    @(posedge clk);
    byte_valid = 1;
    midi_byte = byte_in;
    @(posedge clk);
    #1;
    byte_valid = 0;
    midi_byte = 0;
  endtask

  //------------------------------------------------------------------------------
  // Tests
  //------------------------------------------------------------------------------
  task automatic verify_reset_state; 
    @(posedge clk);
    #1;

    // Check all values are zeroed as expected at start of test run.
    if(byte_valid || msg_valid || rt_msg_valid || len || midi_byte) begin
      $display("FAIL: verify_reset_state. Invalid starting state");
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_realtime_message;
    @(posedge clk);
    byte_valid = 1;
    midi_byte = 8'hF8;  // Timing Clock
    
    @(posedge clk);
    #1;
    byte_valid = 0;
    
    if (rt_msg_valid !== 1'b1) begin
      $display("FAIL: verify_realtime_message. Real-time message not detected");
      test_failures++;
    end
    
    if (rt_msg !== 8'hF8) begin
      $display("FAIL: verify_realtime_message. Real-time message data mismatch. Expected: F8, Got: %h", rt_msg);
      test_failures++;
    end
    
    @(posedge clk);
    #1;
    
    if (rt_msg_valid !== 1'b0) begin
      $display("FAIL: verify_realtime_message. Real-time valid stuck high");
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_note_on_3bytes;
    send_byte(8'h90);  // Note On, channel 1
    send_byte(8'h3C);  // Note 60 (middle C)
    
    @(posedge clk);
    #1;
    
    // Should not be valid yet (need 3 bytes)
    if (msg_valid !== 1'b0) begin
      $display("FAIL: verify_note_on_3bytes. Note On valid too early");
      test_failures++;
    end
    
    send_byte(8'h64);  // Velocity 10
    
    if (msg_valid !== 1'b1) begin
      $display("FAIL:verify_note_on_3bytes. Note On not valid after 3 bytes");
      test_failures++;
    end
    
    if (len !== 2'd3) begin
      $display("FAIL: verify_note_on_3bytes. Note On length incorrect. Expected: 3, Got: %d", len);
      test_failures++;
    end
    
    if (msg_status !== 8'h90 || msg_data1 !== 8'h3C || msg_data2 !== 8'h64) begin
      $display("FAIL: verify_note_on_3bytes. Note On data mismatch. Got: %h %h %h", msg_status, msg_data1, msg_data2);
      test_failures++;
    end
    
    @(posedge clk);
    #1;
    
    if (msg_valid !== 1'b0) begin
      $display("FAIL: verify_note_on_3bytes. Note On valid stuck high");
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_program_change_2bytes;
    send_byte(8'hC0);  // Program Change, channel 1
    send_byte(8'h05);  // Program 5

    
    if (msg_valid !== 1'b1) begin
      $display("FAIL: verify_program_change_2bytes. Program Change not valid after 2 bytes");
      test_failures++;
    end
    
    if (len !== 2'd2) begin
      $display("FAIL: verify_program_change_2bytes. Program Change length incorrect. Expected: 2, Got: %d", len);
      test_failures++;
    end
    
    if (msg_status !== 8'hC0 || msg_data1 !== 8'h05) begin
      $display("FAIL:verify_program_change_2bytes. Program Change data mismatch. Got: %h %h", msg_status, msg_data1);
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_control_change;
    send_byte(8'hB0);  // Control Change, channel 1
    send_byte(8'h07);  // Controller 7 (volume)
    send_byte(8'h7F);  // Value 127
    

    if (msg_valid !== 1'b1) begin
      $display("FAIL: verify_control_change. Control Change not valid");
      test_failures++;
    end
    
    if (len !== 2'd3) begin
      $display("FAIL: verify_control_change. Control Change length incorrect. Expected: 3, Got: %d", len);
      test_failures++;
    end
    
    if (msg_status !== 8'hB0 || msg_data1 !== 8'h07 || msg_data2 !== 8'h7F) begin
      $display("FAIL: verify_control_change. Control Change data mismatch. Got: %h %h %h", msg_status, msg_data1, msg_data2);
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_running_status;
    // Send first complete Note On
    send_byte(8'h90);  // Note On status
    send_byte(8'h3C);  // Note 60
    send_byte(8'h64);  // Velocity 100
    
  
    if (msg_valid !== 1'b1) begin
      $display("FAIL: verify_running_status. Running status - first message not valid");
      test_failures++;
    end
    
    @(posedge clk);
    #1;
    
    // Send second note using running status (no status byte)
    send_byte(8'h40);  // Note 64 (no status byte)
    send_byte(8'h50);  // Velocity 80
    
    
    if (msg_valid !== 1'b1) begin
      $display("FAIL: verify_running_status. Running status - second message not valid");
      test_failures++;
    end
    
    if (msg_status !== 8'h90 || msg_data1 !== 8'h40 || msg_data2 !== 8'h50) begin
      $display("FAIL: verify_running_status. Running status data mismatch. Got: %h %h %h", msg_status, msg_data1, msg_data2);
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_sysex_drain;
    // Start SysEx
    send_byte(8'hF0);  // SysEx Start
    
    // Send some SysEx data (should be ignored)
    send_byte(8'h7E);
    send_byte(8'h00);
    send_byte(8'h06);
  
    // No messages should be generated during SysEx
    if (msg_valid !== 1'b0) begin
      $display("FAIL: verify_sysex_drain. Message generated during SysEx");
      test_failures++;
    end
    
    // End SysEx
    send_byte(8'hF7);  // SysEx End
    
 
    // Now send a normal message to verify parser recovered
    send_byte(8'hC0);  // Program Change
    send_byte(8'h10);  // Program 16
    

    
    if (msg_valid !== 1'b1) begin
      $display("FAIL: verify_sysex_drain. Parser did not recover after SysEx");
      test_failures++;
    end
    test_count++;
  endtask

  task automatic verify_realtime_during_message;
    // Start a Note On message
    send_byte(8'h90);  // Note On status
    send_byte(8'h3C);  // Note 60
    
    // Inject real-time message mid-sequence
    @(posedge clk);
    byte_valid = 1;
    midi_byte = 8'hF8;  // Timing Clock
    
    @(posedge clk);
    #1;
    byte_valid = 0;
    
    if (rt_msg_valid !== 1'b1) begin
      $display("FAIL: verify_realtime_during_message. Real-time not detected during message");
      test_failures++;
    end
    
    @(posedge clk);
    #1;
    
    // Complete the Note On
    send_byte(8'h64);  // Velocity 100
  
    
    if (msg_valid !== 1'b1) begin
      $display("FAIL: verify_realtime_during_message. Note On not valid after real-time interruption");
      test_failures++;
    end
    
    if (msg_status !== 8'h90 || msg_data1 !== 8'h3C || msg_data2 !== 8'h64) begin
      $display("FAIL: verify_realtime_during_message. Message corrupted by real-time. Got: %h %h %h", msg_status, msg_data1, msg_data2);
      test_failures++;
    end
    test_count++;
  endtask

  //------------------------------------------------------------------------------
  // Test executor
  //------------------------------------------------------------------------------
  initial begin
    $dumpfile("midi_parser.fst");
    $dumpvars(0,midi_parser_tb);
    $display("TESTBENCH: midi_parser_tb");

    // Wait for a stable uut
    wait (rst_n);
    repeat (2) @(posedge clk);

    verify_reset_state();    
    verify_realtime_message();
    verify_note_on_3bytes();
    verify_program_change_2bytes();
    verify_control_change();
    verify_running_status();
    verify_sysex_drain();
    verify_realtime_during_message();

    repeat (5) @(posedge clk);

    if (test_failures == 0) $display("PASS: All %0d tests passed.",test_count);
    else $fatal(1, "FAIL: midi_parser_tb. %0d test(s) failed.", test_failures);

    $finish;
  end

endmodule