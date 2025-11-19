//------------------------------------------------------------------------------
// Jason Wilden 2025
//------------------------------------------------------------------------------
`default_nettype none
`include "../../common_defs.svh"

module timer#(parameter MCU_FREQ)
(
    input `VAR  logic       clk_i,
    input `VAR  logic       rst_ni,
    input `VAR logic        clk_mcu_i,
    input `VAR logic        rst_mcu_ni,
    input `VAR logic        select_i,       

    output     logic        mem_ready_o,    
    input `VAR logic [3:0]  mem_wstrb_i,    
    input `VAR logic [31:0] mem_addr_i,     
    input `VAR logic [31:0] mem_wdata_i,    
    output     logic [31:0] mem_rdata_o     
);

localparam CYCLES_PER_US = MCU_FREQ/1_000_000;
localparam integer CYCLEW = $clog2(CYCLES_PER_US);

//------------------------------------------------------------------------------
// Registers
//------------------------------------------------------------------------------
localparam CR = 4'h00;                    // Control register
localparam LO = 4'h01;                    // Counter low word 
localparam HI = 4'h02;                    // Counter high word

//------------------------------------------------------------------------------
// Determine operation
//------------------------------------------------------------------------------
logic wr_cr, rd_lo, rd_hi;

assign wr_cr = (|mem_wstrb_i && select_i && (mem_addr_i[5:2] == CR));
assign rd_lo = (select_i && (mem_addr_i[5:2] == LO));
assign rd_hi = (select_i && (mem_addr_i[5:2] == HI));


//------------------------------------------------------------------------------
// State registers
//------------------------------------------------------------------------------
logic[CYCLEW-1:0] cycle_cnt, cycle_cnt_next;
logic[63:0] us_cnt, us_cnt_next, us_cnt_latch;

logic run, run_next;
logic clear, clear_next;

always @(posedge clk_mcu_i) begin
    if(!rst_mcu_ni) begin
        cycle_cnt <= 0;
        us_cnt <= 0;        
        run <= 0;
        clear <= 0;
    end else begin
        cycle_cnt <= cycle_cnt_next;
        us_cnt <= us_cnt_next;
        run  <= run_next;
        clear <= clear_next;

        // Latch counter on LO read for 64-bit access (convention)
        if(rd_lo) us_cnt_latch <= us_cnt;
    end
end

//------------------------------------------------------------------------------
// Next state logic
//------------------------------------------------------------------------------
always_comb begin    
    cycle_cnt_next = cycle_cnt;
    us_cnt_next = us_cnt;

    run_next = wr_cr ? mem_wdata_i[0] : run;
    clear_next = wr_cr ? mem_wdata_i[1] : 1'b0; // Auto clear

    if(clear) begin
        us_cnt_next = 0;
        cycle_cnt_next = 0;
    end else begin 
        if(run) begin
            if(cycle_cnt == CYCLES_PER_US -1) begin
                cycle_cnt_next = 0;
                us_cnt_next = us_cnt + 1'b1;
            end else begin
                cycle_cnt_next = cycle_cnt+1'b1;
            end
        end else begin
            cycle_cnt_next = 0;     
        end
    end
end

//------------------------------------------------------------------------------
// Output logic
//------------------------------------------------------------------------------
assign mem_rdata_o = rd_hi ? us_cnt_latch[63:32] : 
                     rd_lo ? us_cnt_latch[31:0] : 
                     0;
assign mem_ready_o = select_i;   // Single cycle response

endmodule