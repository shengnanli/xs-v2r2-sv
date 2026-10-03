// V0RegFilePart0.sv —— V0RegFile 物理寄存器堆的一片：xs_Regfile_core 的薄 wrapper（参数 + 端口展平）
// =============================================================================
// 参数（golden 实测，由 scripts/gen_datapath_rf.py 解析并断言）：22 项 × 64 位，
//   4 个同步读口、6 个写口、地址 5 位（读视图 32 行，越界读 0 号项）；
//   debug 组合读口 0 个；debug 全量读出 有；0 号项不复位。
//   V0RegFilePart0..N 在 golden 里逐字相同（仅模块名不同），片号只决定上层接哪几位数据。
// 机制（Mux1H 按位或写、地址打一拍的同步读、越界填 0 号项）见核体 rtl/backend/xs_Regfile_core.sv。
// golden 对照：G1-canonical/golden-rtl/V0RegFilePart0.sv。本文件由 scripts/gen_datapath_rf.py 生成，勿手改。
// =============================================================================
module V0RegFilePart0(
  input          clock,
  input          reset,
  input  [4:0]   io_readPorts_0_addr,
  output [63:0]  io_readPorts_0_data,
  input  [4:0]   io_readPorts_1_addr,
  output [63:0]  io_readPorts_1_data,
  input  [4:0]   io_readPorts_2_addr,
  output [63:0]  io_readPorts_2_data,
  input  [4:0]   io_readPorts_3_addr,
  output [63:0]  io_readPorts_3_data,
  input          io_writePorts_0_wen,
  input  [4:0]   io_writePorts_0_addr,
  input  [63:0]  io_writePorts_0_data,
  input          io_writePorts_1_wen,
  input  [4:0]   io_writePorts_1_addr,
  input  [63:0]  io_writePorts_1_data,
  input          io_writePorts_2_wen,
  input  [4:0]   io_writePorts_2_addr,
  input  [63:0]  io_writePorts_2_data,
  input          io_writePorts_3_wen,
  input  [4:0]   io_writePorts_3_addr,
  input  [63:0]  io_writePorts_3_data,
  input          io_writePorts_4_wen,
  input  [4:0]   io_writePorts_4_addr,
  input  [63:0]  io_writePorts_4_data,
  input          io_writePorts_5_wen,
  input  [4:0]   io_writePorts_5_addr,
  input  [63:0]  io_writePorts_5_data,
  output [63:0]  io_debug_all_rdata_0,
  output [63:0]  io_debug_all_rdata_1,
  output [63:0]  io_debug_all_rdata_2,
  output [63:0]  io_debug_all_rdata_3,
  output [63:0]  io_debug_all_rdata_4,
  output [63:0]  io_debug_all_rdata_5,
  output [63:0]  io_debug_all_rdata_6,
  output [63:0]  io_debug_all_rdata_7,
  output [63:0]  io_debug_all_rdata_8,
  output [63:0]  io_debug_all_rdata_9,
  output [63:0]  io_debug_all_rdata_10,
  output [63:0]  io_debug_all_rdata_11,
  output [63:0]  io_debug_all_rdata_12,
  output [63:0]  io_debug_all_rdata_13,
  output [63:0]  io_debug_all_rdata_14,
  output [63:0]  io_debug_all_rdata_15,
  output [63:0]  io_debug_all_rdata_16,
  output [63:0]  io_debug_all_rdata_17,
  output [63:0]  io_debug_all_rdata_18,
  output [63:0]  io_debug_all_rdata_19,
  output [63:0]  io_debug_all_rdata_20,
  output [63:0]  io_debug_all_rdata_21
);
  localparam int unsigned NUM_PREGS = 22;
  localparam int unsigned NUM_READ  = 4;
  localparam int unsigned NUM_WRITE = 6;
  localparam int unsigned DATA_W    = 64;
  localparam int unsigned ADDR_W    = 5;

  logic [NUM_READ-1:0][ADDR_W-1:0]  read_addr;
  logic [NUM_READ-1:0][DATA_W-1:0]  read_data;
  logic [NUM_WRITE-1:0]             write_wen;
  logic [NUM_WRITE-1:0][ADDR_W-1:0] write_addr;
  logic [NUM_WRITE-1:0][DATA_W-1:0] write_data;
  logic [0:0][ADDR_W-1:0]         debug_read_addr;
  logic [0:0][DATA_W-1:0]         debug_read_data;
  logic [NUM_PREGS-1:0][DATA_W-1:0] debug_all_rdata;

  xs_Regfile_core #(
    .NUM_PREGS      (NUM_PREGS),
    .NUM_READ       (NUM_READ),
    .NUM_WRITE      (NUM_WRITE),
    .DATA_W         (DATA_W),
    .ADDR_W         (ADDR_W),
    .NUM_DEBUG_READ (0),
    .MEM0_RESET     (1'b0)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .read_addr       (read_addr),
    .read_data       (read_data),
    .write_wen       (write_wen),
    .write_addr      (write_addr),
    .write_data      (write_data),
    .debug_read_addr (debug_read_addr),
    .debug_read_data (debug_read_data),
    .debug_all_rdata (debug_all_rdata)
  );

  // 读口
  assign read_addr[0] = io_readPorts_0_addr;
  assign io_readPorts_0_data = read_data[0];
  assign read_addr[1] = io_readPorts_1_addr;
  assign io_readPorts_1_data = read_data[1];
  assign read_addr[2] = io_readPorts_2_addr;
  assign io_readPorts_2_data = read_data[2];
  assign read_addr[3] = io_readPorts_3_addr;
  assign io_readPorts_3_data = read_data[3];
  // 写口
  assign write_wen[0]  = io_writePorts_0_wen;
  assign write_addr[0] = io_writePorts_0_addr;
  assign write_data[0] = io_writePorts_0_data;
  assign write_wen[1]  = io_writePorts_1_wen;
  assign write_addr[1] = io_writePorts_1_addr;
  assign write_data[1] = io_writePorts_1_data;
  assign write_wen[2]  = io_writePorts_2_wen;
  assign write_addr[2] = io_writePorts_2_addr;
  assign write_data[2] = io_writePorts_2_data;
  assign write_wen[3]  = io_writePorts_3_wen;
  assign write_addr[3] = io_writePorts_3_addr;
  assign write_data[3] = io_writePorts_3_data;
  assign write_wen[4]  = io_writePorts_4_wen;
  assign write_addr[4] = io_writePorts_4_addr;
  assign write_data[4] = io_writePorts_4_data;
  assign write_wen[5]  = io_writePorts_5_wen;
  assign write_addr[5] = io_writePorts_5_addr;
  assign write_data[5] = io_writePorts_5_data;
  // debug
  assign debug_read_addr = '0;  // 本变体没有 debug 组合读口
  assign io_debug_all_rdata_0 = debug_all_rdata[0];
  assign io_debug_all_rdata_1 = debug_all_rdata[1];
  assign io_debug_all_rdata_2 = debug_all_rdata[2];
  assign io_debug_all_rdata_3 = debug_all_rdata[3];
  assign io_debug_all_rdata_4 = debug_all_rdata[4];
  assign io_debug_all_rdata_5 = debug_all_rdata[5];
  assign io_debug_all_rdata_6 = debug_all_rdata[6];
  assign io_debug_all_rdata_7 = debug_all_rdata[7];
  assign io_debug_all_rdata_8 = debug_all_rdata[8];
  assign io_debug_all_rdata_9 = debug_all_rdata[9];
  assign io_debug_all_rdata_10 = debug_all_rdata[10];
  assign io_debug_all_rdata_11 = debug_all_rdata[11];
  assign io_debug_all_rdata_12 = debug_all_rdata[12];
  assign io_debug_all_rdata_13 = debug_all_rdata[13];
  assign io_debug_all_rdata_14 = debug_all_rdata[14];
  assign io_debug_all_rdata_15 = debug_all_rdata[15];
  assign io_debug_all_rdata_16 = debug_all_rdata[16];
  assign io_debug_all_rdata_17 = debug_all_rdata[17];
  assign io_debug_all_rdata_18 = debug_all_rdata[18];
  assign io_debug_all_rdata_19 = debug_all_rdata[19];
  assign io_debug_all_rdata_20 = debug_all_rdata[20];
  assign io_debug_all_rdata_21 = debug_all_rdata[21];
endmodule
