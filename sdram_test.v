module top(input clk, 
  output [7:0] gpio,
  inout [15:0] mem_d,
  output [12:0] mem_a,
  output mem_ras, mem_cas,
  output [1:0] mem_dqm,
  output [1:0] mem_ba,
  output mem_clk, mem_cke, mem_we,
  output mem_cs1, mem_cs2
);

wire clk;

wire [15:0] mem_do;
wire [15:0] mem_di;
wire bus_out = ~mem_we; // SB_IO outputs 
SB_IO #(.PIN_TYPE(6'b1010_01), .PULLUP(1'b0))
io_Dn [15:0] (.PACKAGE_PIN(mem_d),
  .OUTPUT_ENABLE(bus_out),
  .D_OUT_0(mem_do),
  .D_IN_0(mem_di)
);

assign mem_cs2 = 1;

wire ctrl_busyn, ctrl_init_done, ctrl_ack, cpu_rwn, cpu_advn, ctrl_rst;
wire [31:0] cpu_data_i;
reg [31:0] cpu_data_o;
reg [26:0] cpu_addr;
sdram_controller sdr(
  // ext. (physical) signals
  .o_sdram_dq(mem_do),
  .i_sdram_dq(mem_di),
  .o_sdram_addr(mem_a),
  .o_sdram_blkaddr(mem_ba), 
  .o_sdram_casn(mem_cas), 
  .o_sdram_cke(mem_cke), 
  .o_sdram_csn(mem_cs1), 
  .o_sdram_dqm(mem_dqm), 
  .o_sdram_rasn(mem_ras), 
  .o_sdram_wen(mem_we), 
  .o_sdram_clk(mem_clk), 

  // cpu (control) signals 
  .i_rst(ctrl_rst),
  .o_busy(ctrl_busyn),
  .o_ack(ctrl_ack),
  .i_data(cpu_data_o),
  .o_data(cpu_data_i),
  .i_addr(cpu_addr),
  .i_rwn(cpu_rwn),
  .i_adv(cpu_advn),
  .i_clk(clk),
  .o_init_done(ctrl_init_done),

  //others
  .i_selfrefresh_req('b0),
  .i_loadmod_req('b0),
  .i_precharge_req('b0),
  .i_disable_active('b0)
);

reg [16:0] clk_count = 0;
always @(posedge clk) begin
  clk_count <= clk_count + 1; 
end

assign cpu_data_o = 32'b01010101;
assign cpu_addr = 0;

assign gpio[0] = ctrl_init_done;
assign gpio[1] = ctrl_busyn;
assign gpio[2] = cpu_advn;
assign gpio[5] = clk;

always @(*) begin
  case(clk_count)
    'd0: begin
      ctrl_rst = 1; 
      cpu_advn = 1;
      cpu_rwn = 0;
    end
    'd1: begin
      cpu_advn = 1;
      cpu_rwn = 0;
    end
    'd30000: begin
      cpu_advn = 0;
      cpu_rwn = 0;
    end
    'd41000: begin
      ctrl_rwn = 0;
      cpu_adv = 0;
    end
    'd41001, 'd41002, 'd41003, 'd41004, 'd41005, 'd41006: begin
      ctrl_rwn = 0;
      cpu_adv = 1;
    end
    default: begin
      ctrl_rst = 0;
      cpu_advn = 1;
      cpu_rwn = 0;
    end
  endcase
end

endmodule
