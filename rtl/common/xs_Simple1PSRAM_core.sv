// xs_Simple1PSRAM_core —— 可读的单端口(1RW)写优先 SRAM 核。
//
// 独立实现, 不扩改带 MBIST 的 xs_SRAMTemplate_core, 也不复制 golden 网表。用于 L2
// SubDirectory 的 meta/tag SRAM 叶(SRAMTemplate_197..201)的可读重写。
//
// 语义(对齐 golden 单 RW 口行为):
//   * 单物理读写口, 写优先: 同拍 r/w 都请求时只写(读让路)。
//   * 读延迟 1: 读命中拍锁存 setIdx, 下一拍输出 mem[锁存地址](地址寄存, 数据组合读出)。
//   * 写: 逐 lane(way)mask, 只更新 waymask 置位的 30bit 段。
//   * 无上电初始化(197..200 配置)。
//   * io_r_req_ready = ~写请求(写占口时读不就绪); io_w_req_ready 恒 1。
//
// 数据按 lane 打包: io_*_data[w*WIDTH +: WIDTH] 是第 w 路。wrapper 负责逐路拆/并。
module xs_Simple1PSRAM_core #(
  parameter int SETS  = 1024,   // 存储深度(行数)
  parameter int WAYS  = 10,     // 每行路数(lane)
  parameter int WIDTH = 30      // 每路数据位宽
) (
  input                         clock,
  // 读口
  output                        io_r_req_ready,
  input                         io_r_req_valid,
  input  [$clog2(SETS)-1:0]     io_r_req_bits_setIdx,
  output [WAYS*WIDTH-1:0]       io_r_resp_data,       // 打包读数据(wrapper 拆成逐路)
  // 写口
  output                        io_w_req_ready,
  input                         io_w_req_valid,
  input  [$clog2(SETS)-1:0]     io_w_req_bits_setIdx,
  input  [WAYS*WIDTH-1:0]       io_w_req_bits_data,   // 打包写数据
  input  [WAYS-1:0]             io_w_req_bits_waymask
);
  localparam int AW = $clog2(SETS);

  // 推断存储阵列: SETS 行 × (WAYS*WIDTH) 位。综合成物理 SRAM。
  logic [WAYS*WIDTH-1:0] mem [SETS-1:0];

  // 单口写优先仲裁: 写请求占用物理口, 读仅在无写时进行。
  wire wen = io_w_req_valid;
  wire ren = io_r_req_valid & ~io_w_req_valid;
  assign io_r_req_ready = ~io_w_req_valid;
  assign io_w_req_ready = 1'b1;

  // 同步读: 读拍锁存地址, 组合读出 mem[锁存地址](读延迟 1 拍)。
  logic [AW-1:0] raddr_q;
  always_ff @(posedge clock)
    if (ren) raddr_q <= io_r_req_bits_setIdx;
  assign io_r_resp_data = mem[raddr_q];

  // 同步写: 逐路 mask 更新。
  always_ff @(posedge clock)
    if (wen)
      for (int w = 0; w < WAYS; w++)
        if (io_w_req_bits_waymask[w])
          mem[io_w_req_bits_setIdx][w*WIDTH +: WIDTH] <= io_w_req_bits_data[w*WIDTH +: WIDTH];

endmodule
