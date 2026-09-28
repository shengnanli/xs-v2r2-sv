// VlRegFile.sv —— VlRegFile 物理寄存器堆的一片：xs_Regfile_core 的薄 wrapper（参数 + 端口展平）
// =============================================================================
// 参数（golden 实测，由 scripts/gen_datapath_rf.py 解析并断言）：32 项 × 8 位，
//   4 个同步读口、4 个写口、地址 5 位（读视图 32 行，越界读 0 号项）；
//   debug 组合读口 1 个；debug 全量读出 无；0 号项异步复位为 0。
// 机制（Mux1H 按位或写、地址打一拍的同步读、越界填 0 号项）见核体 rtl/backend/xs_Regfile_core.sv。
// golden 对照：G1-canonical/golden-rtl/VlRegFile.sv。本文件由 scripts/gen_datapath_rf.py 生成，勿手改。
// =============================================================================
module VlRegFile(
  input          clock,
  input          reset,
  input  [4:0]   io_readPorts_0_addr,
  output [7:0]   io_readPorts_0_data,
  input  [4:0]   io_readPorts_1_addr,
  output [7:0]   io_readPorts_1_data,
  input  [4:0]   io_readPorts_2_addr,
  output [7:0]   io_readPorts_2_data,
  input  [4:0]   io_readPorts_3_addr,
  output [7:0]   io_readPorts_3_data,
  input          io_writePorts_0_wen,
  input  [4:0]   io_writePorts_0_addr,
  input  [7:0]   io_writePorts_0_data,
  input          io_writePorts_1_wen,
  input  [4:0]   io_writePorts_1_addr,
  input  [7:0]   io_writePorts_1_data,
  input          io_writePorts_2_wen,
  input  [4:0]   io_writePorts_2_addr,
  input  [7:0]   io_writePorts_2_data,
  input          io_writePorts_3_wen,
  input  [4:0]   io_writePorts_3_addr,
  input  [7:0]   io_writePorts_3_data,
  input  [4:0]   io_debug_rports_0_addr,
  output [7:0]   io_debug_rports_0_data
);
  localparam int unsigned NUM_PREGS = 32;
  localparam int unsigned NUM_READ  = 4;
  localparam int unsigned NUM_WRITE = 4;
  localparam int unsigned DATA_W    = 8;
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
    .NUM_DEBUG_READ (1),
    .MEM0_RESET     (1'b1)
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
  // debug
  assign debug_read_addr[0] = io_debug_rports_0_addr;
  assign io_debug_rports_0_data = debug_read_data[0];
  // 本变体没有 debug_all_rdata 端口（debug_all_rdata 悬空）
endmodule
