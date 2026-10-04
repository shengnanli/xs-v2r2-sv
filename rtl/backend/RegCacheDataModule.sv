// =============================================================================
// RegCacheDataModule —— 寄存器缓存（RegCache）的数据存储体（RegCache 的子模块；
//                       家族核 xs_RegCacheDataModule_core 也服务 RegCacheDataModule_1）
//
// 设计源：src/main/scala/xiangshan/backend/regcache/RegCacheDataModule.scala。
//
// 背景：RegCache 是整数物理寄存器堆前面的一个小全相联缓存，最近写回的结果按
//   "槽号"存在这里，发射时命中就不必读大寄存器堆。RegCache 分两半：
//     IntRegCache（RegCacheDataModule  ：16 项、23 读口、4 写口——整数 FU 写回）
//     MemRegCache（RegCacheDataModule_1：12 项、23 读口、3 写口——访存 load 写回）
//   槽号由上层 RegCacheAgeDetector 选出的"最老项"分配，本模块只是一块多口寄存器阵列。
//
// 机制：
//   * 写：每项看所有写口里 wen && addr==该项 的那些（Mux1H，按位或；同项多写口是上层
//     保证不会出现的情形，golden 只有断言），命中则写入数据并置 valid（v 一旦置位不清，
//     只有复位清零）。
//   * 读：组合读 mem[addr]；地址超出项数（只有 12 项的 _1 变体可能）时读第 0 项
//     （Chisel Vec 动态下标越界，firtool 取第 0 项）。ren 只用于"读到无效项"的断言，
//     不影响数据。
//   * validInfo 直接输出 v，供 RegCacheAgeTimer 做替换年龄比较。
// 复位：v 异步复位为 0；mem 不复位（Reg）。调试用的 tag 阵列在 G1 配置（debugEn=false）下不存在。
// =============================================================================
module xs_RegCacheDataModule_core #(
  parameter int N_ENTRY = 16,
  parameter int N_READ  = 23,
  parameter int N_WRITE = 4,
  parameter int DATA_W  = 64,
  parameter int ADDR_W  = 4
) (
  input  logic                clock,
  input  logic                reset,
  input  logic [N_READ-1:0]   ren,          // 只用于断言（见文件头），数据通路不看
  input  logic [ADDR_W-1:0]   raddr [N_READ],
  output logic [DATA_W-1:0]   rdata [N_READ],
  input  logic [N_WRITE-1:0]  wen,
  input  logic [ADDR_W-1:0]   waddr [N_WRITE],
  input  logic [DATA_W-1:0]   wdata [N_WRITE],
  output logic [N_ENTRY-1:0]  valid_info
);

  logic [N_ENTRY-1:0] v;
  logic [DATA_W-1:0]  mem [N_ENTRY];

  // ---------------------------------------------------------------------------
  // §1 写：逐项收集命中的写口（独热），Mux1H 选数据
  // ---------------------------------------------------------------------------
  logic [N_WRITE-1:0] wen_oh   [N_ENTRY];
  logic [DATA_W-1:0]  wen_data [N_ENTRY];
  always_comb begin
    for (int k = 0; k < N_ENTRY; k++) begin
      wen_data[k] = '0;
      for (int w = 0; w < N_WRITE; w++) begin
        wen_oh[k][w] = wen[w] & (waddr[w] == ADDR_W'(k));
        if (wen_oh[k][w]) wen_data[k] |= wdata[w];
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      v <= '0;
    else
      for (int k = 0; k < N_ENTRY; k++)
        if (|wen_oh[k]) v[k] <= 1'b1;
  end

  always_ff @(posedge clock) begin
    for (int k = 0; k < N_ENTRY; k++)
      if (|wen_oh[k]) mem[k] <= wen_data[k];
  end

  // ---------------------------------------------------------------------------
  // §2 读：组合读，越界读第 0 项
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int r = 0; r < N_READ; r++) begin
      rdata[r] = mem[0];                                   // 越界（及地址 0）读第 0 项
      for (int k = 1; k < N_ENTRY; k++)
        if (raddr[r] == ADDR_W'(k)) rdata[r] = mem[k];
    end
  end

  assign valid_info = v;

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden RegCacheDataModule.sv 逐位一致（16 项 / 23 读口 / 4 写口）
// ---------------------------------------------------------------------------
module RegCacheDataModule (
  input         clock,
  input         reset,
  input         io_readPorts_0_ren,
  input  [3:0]  io_readPorts_0_addr,
  output [63:0] io_readPorts_0_data,
  input         io_readPorts_1_ren,
  input  [3:0]  io_readPorts_1_addr,
  output [63:0] io_readPorts_1_data,
  input         io_readPorts_2_ren,
  input  [3:0]  io_readPorts_2_addr,
  output [63:0] io_readPorts_2_data,
  input         io_readPorts_3_ren,
  input  [3:0]  io_readPorts_3_addr,
  output [63:0] io_readPorts_3_data,
  input         io_readPorts_4_ren,
  input  [3:0]  io_readPorts_4_addr,
  output [63:0] io_readPorts_4_data,
  input         io_readPorts_5_ren,
  input  [3:0]  io_readPorts_5_addr,
  output [63:0] io_readPorts_5_data,
  input         io_readPorts_6_ren,
  input  [3:0]  io_readPorts_6_addr,
  output [63:0] io_readPorts_6_data,
  input         io_readPorts_7_ren,
  input  [3:0]  io_readPorts_7_addr,
  output [63:0] io_readPorts_7_data,
  input         io_readPorts_8_ren,
  input  [3:0]  io_readPorts_8_addr,
  output [63:0] io_readPorts_8_data,
  input         io_readPorts_9_ren,
  input  [3:0]  io_readPorts_9_addr,
  output [63:0] io_readPorts_9_data,
  input         io_readPorts_10_ren,
  input  [3:0]  io_readPorts_10_addr,
  output [63:0] io_readPorts_10_data,
  input         io_readPorts_11_ren,
  input  [3:0]  io_readPorts_11_addr,
  output [63:0] io_readPorts_11_data,
  input         io_readPorts_12_ren,
  input  [3:0]  io_readPorts_12_addr,
  output [63:0] io_readPorts_12_data,
  input         io_readPorts_13_ren,
  input  [3:0]  io_readPorts_13_addr,
  output [63:0] io_readPorts_13_data,
  input         io_readPorts_14_ren,
  input  [3:0]  io_readPorts_14_addr,
  output [63:0] io_readPorts_14_data,
  input         io_readPorts_15_ren,
  input  [3:0]  io_readPorts_15_addr,
  output [63:0] io_readPorts_15_data,
  input         io_readPorts_16_ren,
  input  [3:0]  io_readPorts_16_addr,
  output [63:0] io_readPorts_16_data,
  input         io_readPorts_17_ren,
  input  [3:0]  io_readPorts_17_addr,
  output [63:0] io_readPorts_17_data,
  input         io_readPorts_18_ren,
  input  [3:0]  io_readPorts_18_addr,
  output [63:0] io_readPorts_18_data,
  input         io_readPorts_19_ren,
  input  [3:0]  io_readPorts_19_addr,
  output [63:0] io_readPorts_19_data,
  input         io_readPorts_20_ren,
  input  [3:0]  io_readPorts_20_addr,
  output [63:0] io_readPorts_20_data,
  input         io_readPorts_21_ren,
  input  [3:0]  io_readPorts_21_addr,
  output [63:0] io_readPorts_21_data,
  input         io_readPorts_22_ren,
  input  [3:0]  io_readPorts_22_addr,
  output [63:0] io_readPorts_22_data,
  input         io_writePorts_0_wen,
  input  [3:0]  io_writePorts_0_addr,
  input  [63:0] io_writePorts_0_data,
  input         io_writePorts_1_wen,
  input  [3:0]  io_writePorts_1_addr,
  input  [63:0] io_writePorts_1_data,
  input         io_writePorts_2_wen,
  input  [3:0]  io_writePorts_2_addr,
  input  [63:0] io_writePorts_2_data,
  input         io_writePorts_3_wen,
  input  [3:0]  io_writePorts_3_addr,
  input  [63:0] io_writePorts_3_data,
  output        io_validInfo_0,
  output        io_validInfo_1,
  output        io_validInfo_2,
  output        io_validInfo_3,
  output        io_validInfo_4,
  output        io_validInfo_5,
  output        io_validInfo_6,
  output        io_validInfo_7,
  output        io_validInfo_8,
  output        io_validInfo_9,
  output        io_validInfo_10,
  output        io_validInfo_11,
  output        io_validInfo_12,
  output        io_validInfo_13,
  output        io_validInfo_14,
  output        io_validInfo_15
);

  logic [22:0] ren;
  logic [3:0]  raddr [23];
  logic [63:0] rdata [23];
  logic [3:0]  wen;
  logic [3:0]  waddr [4];
  logic [63:0] wdata [4];
  logic [15:0] valid_info;

  assign ren[0]   = io_readPorts_0_ren;
  assign raddr[0] = io_readPorts_0_addr;
  assign ren[1]   = io_readPorts_1_ren;
  assign raddr[1] = io_readPorts_1_addr;
  assign ren[2]   = io_readPorts_2_ren;
  assign raddr[2] = io_readPorts_2_addr;
  assign ren[3]   = io_readPorts_3_ren;
  assign raddr[3] = io_readPorts_3_addr;
  assign ren[4]   = io_readPorts_4_ren;
  assign raddr[4] = io_readPorts_4_addr;
  assign ren[5]   = io_readPorts_5_ren;
  assign raddr[5] = io_readPorts_5_addr;
  assign ren[6]   = io_readPorts_6_ren;
  assign raddr[6] = io_readPorts_6_addr;
  assign ren[7]   = io_readPorts_7_ren;
  assign raddr[7] = io_readPorts_7_addr;
  assign ren[8]   = io_readPorts_8_ren;
  assign raddr[8] = io_readPorts_8_addr;
  assign ren[9]   = io_readPorts_9_ren;
  assign raddr[9] = io_readPorts_9_addr;
  assign ren[10]   = io_readPorts_10_ren;
  assign raddr[10] = io_readPorts_10_addr;
  assign ren[11]   = io_readPorts_11_ren;
  assign raddr[11] = io_readPorts_11_addr;
  assign ren[12]   = io_readPorts_12_ren;
  assign raddr[12] = io_readPorts_12_addr;
  assign ren[13]   = io_readPorts_13_ren;
  assign raddr[13] = io_readPorts_13_addr;
  assign ren[14]   = io_readPorts_14_ren;
  assign raddr[14] = io_readPorts_14_addr;
  assign ren[15]   = io_readPorts_15_ren;
  assign raddr[15] = io_readPorts_15_addr;
  assign ren[16]   = io_readPorts_16_ren;
  assign raddr[16] = io_readPorts_16_addr;
  assign ren[17]   = io_readPorts_17_ren;
  assign raddr[17] = io_readPorts_17_addr;
  assign ren[18]   = io_readPorts_18_ren;
  assign raddr[18] = io_readPorts_18_addr;
  assign ren[19]   = io_readPorts_19_ren;
  assign raddr[19] = io_readPorts_19_addr;
  assign ren[20]   = io_readPorts_20_ren;
  assign raddr[20] = io_readPorts_20_addr;
  assign ren[21]   = io_readPorts_21_ren;
  assign raddr[21] = io_readPorts_21_addr;
  assign ren[22]   = io_readPorts_22_ren;
  assign raddr[22] = io_readPorts_22_addr;
  assign wen[0]   = io_writePorts_0_wen;
  assign waddr[0] = io_writePorts_0_addr;
  assign wdata[0] = io_writePorts_0_data;
  assign wen[1]   = io_writePorts_1_wen;
  assign waddr[1] = io_writePorts_1_addr;
  assign wdata[1] = io_writePorts_1_data;
  assign wen[2]   = io_writePorts_2_wen;
  assign waddr[2] = io_writePorts_2_addr;
  assign wdata[2] = io_writePorts_2_data;
  assign wen[3]   = io_writePorts_3_wen;
  assign waddr[3] = io_writePorts_3_addr;
  assign wdata[3] = io_writePorts_3_data;

  xs_RegCacheDataModule_core #(
    .N_ENTRY (16),
    .N_READ  (23),
    .N_WRITE (4)
  ) u_core (
    .clock      (clock),
    .reset      (reset),
    .ren        (ren),
    .raddr      (raddr),
    .rdata      (rdata),
    .wen        (wen),
    .waddr      (waddr),
    .wdata      (wdata),
    .valid_info (valid_info)
  );

  assign io_readPorts_0_data = rdata[0];
  assign io_readPorts_1_data = rdata[1];
  assign io_readPorts_2_data = rdata[2];
  assign io_readPorts_3_data = rdata[3];
  assign io_readPorts_4_data = rdata[4];
  assign io_readPorts_5_data = rdata[5];
  assign io_readPorts_6_data = rdata[6];
  assign io_readPorts_7_data = rdata[7];
  assign io_readPorts_8_data = rdata[8];
  assign io_readPorts_9_data = rdata[9];
  assign io_readPorts_10_data = rdata[10];
  assign io_readPorts_11_data = rdata[11];
  assign io_readPorts_12_data = rdata[12];
  assign io_readPorts_13_data = rdata[13];
  assign io_readPorts_14_data = rdata[14];
  assign io_readPorts_15_data = rdata[15];
  assign io_readPorts_16_data = rdata[16];
  assign io_readPorts_17_data = rdata[17];
  assign io_readPorts_18_data = rdata[18];
  assign io_readPorts_19_data = rdata[19];
  assign io_readPorts_20_data = rdata[20];
  assign io_readPorts_21_data = rdata[21];
  assign io_readPorts_22_data = rdata[22];
  assign io_validInfo_0 = valid_info[0];
  assign io_validInfo_1 = valid_info[1];
  assign io_validInfo_2 = valid_info[2];
  assign io_validInfo_3 = valid_info[3];
  assign io_validInfo_4 = valid_info[4];
  assign io_validInfo_5 = valid_info[5];
  assign io_validInfo_6 = valid_info[6];
  assign io_validInfo_7 = valid_info[7];
  assign io_validInfo_8 = valid_info[8];
  assign io_validInfo_9 = valid_info[9];
  assign io_validInfo_10 = valid_info[10];
  assign io_validInfo_11 = valid_info[11];
  assign io_validInfo_12 = valid_info[12];
  assign io_validInfo_13 = valid_info[13];
  assign io_validInfo_14 = valid_info[14];
  assign io_validInfo_15 = valid_info[15];

endmodule
