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
wire bus_out; // SB_IO outputs 
SB_IO #(.PIN_TYPE(6'b1010_01), .PULLUP(1'b0))
io_Dn [15:0] (.PACKAGE_PIN(mem_d),
  .OUTPUT_ENABLE(bus_out),
  .D_OUT_0(mem_do),
  .D_IN_0(mem_di)
);

assign mem_cs2 = 1;

wire ctrl_busy, ctrl_init_done, ctrl_ack, cpu_rwn, cpu_adv, ctrl_rst;
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
  .o_sdram_busdir(bus_out),

  // cpu (control) signals 
  .i_rst(ctrl_rst),
  .o_busy(ctrl_busy),
  .o_ack(ctrl_ack),
  .i_data(cpu_data_o),
  .o_data(cpu_data_i),
  .i_addr(cpu_addr),
  .i_rwn(cpu_rwn),
  .i_adv(cpu_adv),
  .i_clk(clk),
  .o_init_done(ctrl_init_done),

  //others
  .i_selfrefresh_req('b0),
  .i_loadmod_req('b0),
  .i_precharge_req('b0),
  .i_disable_active('b0),
  .i_disable_precharge('b0),
  .i_burststop_req(0),
  .i_disable_autorefresh(0),
  .i_power_down('b0) 
);

reg [16:0] clk_count = 0;

reg [31:0] pat1 = 32'b01010101;
reg [31:0] pat2 = 32'b10101010;
reg sel;
//assign cpu_data_o = pat1;
//assign cpu_addr = 27'b0101010101;

//assign gpio[2] = ctrl_init_done;
assign gpio[1] = bus_out;
assign gpio[0] = cpu_adv;
//assign gpio[5] = clk;

always @(posedge clk) begin
  clk_count <= (clk_count == 'd41060) ? 'd40900 : clk_count + 1; 
  case(clk_count)
    'd0: begin
      ctrl_rst = 1; 
      cpu_adv = 0;
      cpu_rwn = 0;
      cpu_addr <= 27'b0101010101;
    end
    'd1: begin
      cpu_adv = 0;
      cpu_rwn = 0;
    end
    'd40997, 'd40998, 'd40999: begin
      cpu_data_o = pat1;
      cpu_rwn = 0;
    end
    'd41000: begin
      cpu_data_o = pat1;
      cpu_addr <= 27'b0000100000;
      cpu_rwn = 0;
      cpu_adv = 1;
    end
    'd41001, 'd41002, 'd41003, 'd41004, 'd41005, 'd41006: begin
      cpu_data_o = pat1;
      cpu_rwn = 0;
      cpu_adv = 0;
    end
    'd41015: begin
      cpu_data_o = pat2;
      cpu_addr <= 27'b0000111000;
      cpu_rwn = 0;
      cpu_adv = 1;
    end
    'd41016, 'd41017, 'd41018, 'd41019, 'd41020, 'd41021: begin
      cpu_data_o = pat2;
      cpu_rwn = 0;
      cpu_adv = 0;
    end
    'd41030: begin
      cpu_addr <= 27'b0000100000;
      cpu_rwn = 1;
      cpu_adv = 1;
    end
    'd41031, 'd41032, 'd41033, 'd41034, 'd41035, 'd41036: begin
      cpu_rwn = 1;
      cpu_adv = 0;
    end
    'd41045: begin
      cpu_addr <= 27'b0000111000;
      cpu_rwn = 1;
      cpu_adv = 1;
    end
    'd41046, 'd41047, 'd41048, 'd41049, 'd41050, 'd41051: begin
      cpu_rwn = 1;
      cpu_adv = 0;
    end

    default: begin
      cpu_data_o = 0;
      ctrl_rst = 0;
      cpu_adv = 0;
      cpu_rwn = 1;
    end
  endcase
end

endmodule
