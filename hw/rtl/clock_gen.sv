//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none

module clock_gen (
    input var logic clk_i,
    output logic clk_o,
    output logic rst_no,    
    output logic clk_mcu_o,
    output logic rst_mcu_no
);
  rPLL #(
      .FCLKIN("27"),
      .DYN_IDIV_SEL("false"),
      .IDIV_SEL(8),
      .DYN_FBDIV_SEL("false"),
      .FBDIV_SEL(15),
      .DYN_ODIV_SEL("false"),
      .ODIV_SEL(16),
      .PSDA_SEL("0000"),
      .DYN_DA_EN("true"),
      .DUTYDA_SEL("1000"),
      .CLKOUT_FT_DIR(1),
      .CLKOUTP_FT_DIR(1),
      .CLKOUT_DLY_STEP(0),
      .CLKOUTP_DLY_STEP(0),
      .CLKFB_SEL("internal"),
      .CLKOUT_BYPASS("false"),
      .CLKOUTP_BYPASS("false"),
      .CLKOUTD_BYPASS("false"),
      .DYN_SDIV_SEL(32),
      .CLKOUTD_SRC("CLKOUT"),
      .CLKOUTD3_SRC("CLKOUT"),
      .DEVICE("GW1NR-9C")
  ) u_pll (
      .CLKIN(clk_i),
      .CLKOUT(clk),      
      .CLKOUTD3(clk_mcu),
      .LOCK(pll_locked),

      // Unused
      .CLKOUTP(),      
      .RESET(1'b0),
      .RESET_P(1'b0),
      .CLKFB(1'b0),
      .FBDSEL({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}),
      .IDSEL({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}),
      .ODSEL({1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}),
      .PSDA({1'b0, 1'b0, 1'b0, 1'b0}),
      .DUTYDA({1'b0, 1'b0, 1'b0, 1'b0}),
      .FDLY({1'b0, 1'b0, 1'b0, 1'b0})
  );

  logic clk, clk_mcu, pll_locked;


  // State registers
  logic [3:0] rst, rst_next,rst_mcu,rst_mcu_next;

  always_ff @(posedge clk) rst <= rst_next;  
  always_ff @(posedge clk_mcu) rst_mcu <= rst_mcu_next;

  // Next state logic
  always_comb begin
    rst_next = 4'b0;    
    rst_mcu_next = 4'b0;

    if (pll_locked) begin
      rst_next = {rst[2:0], 1'b1};      
      rst_mcu_next = {rst_mcu[2:0], 1'b1};
    end
  end

  // Output logic
  assign clk_o = clk;
  assign rst_no = rst[3];  
  assign clk_mcu_o = clk_mcu;
  assign rst_mcu_no = rst_mcu[3];

endmodule

`default_nettype wire

