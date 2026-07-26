// =============================================================================
//  LqPAddrModule_1 —— LoadQueueRAW 部分物理地址 CAM（可读重写，镜像 golden 层次）
// -----------------------------------------------------------------------------
//  设计意图来源: src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala
//    (LqPAddrModule: numEntries=32, numRead=2(violation), numWrite=3, gen=UInt(24.W))
//
//  与 golden LoadQueueRAW.sv 内例化的 `LqPAddrModule_1 paddrModule` 端口/内部寄存器
//  逐一对应，供 FM 层次化配对。
//
//  ── 写路径（banked，1 拍延迟写）──
//    golden 的 DataModule 把 32 条目分成 8 bank×4 entry，写口经一级流水（DelayN /
//    DelayNWithValid）后才落到 data 阵列。即 io_wen 当拍锁存 {addrDec, wen&bankHit,
//    wdata}，下一拍才真正写 data_N。本模块用 [bank][port] 数组镜像这 24 组延迟寄存器
//    (bankWriteEn_delay / bankWriteAddrDec_resp_pipMod / writeData_resp_pipMod)。
//
//  ── 读路径（组合，2 个 violation 读口）──
//    io_violationMmask_p_N =
//        (violationMdata_p[23:2] == data_N[23:2])                    // cache-line 命中
//      & (violationCheckLine_p | violationMdata_p[1:0] == data_N[1:0]) // 非 wline 再比字节偏移
//    （data 为 paddr[27:4]，[23:2]=paddr[27:6] cache-line，[1:0]=paddr[5:4]）
// =============================================================================
module LqPAddrModule_1(
  input         clock,
  input         reset,
  input         io_wen_0,
  input         io_wen_1,
  input         io_wen_2,
  input  [4:0]  io_waddr_0,
  input  [4:0]  io_waddr_1,
  input  [4:0]  io_waddr_2,
  input  [23:0] io_wdata_0,
  input  [23:0] io_wdata_1,
  input  [23:0] io_wdata_2,
  input  [23:0] io_violationMdata_0,
  input  [23:0] io_violationMdata_1,
  input         io_violationCheckLine_0,
  input         io_violationCheckLine_1,
  output        io_violationMmask_0_0,  output io_violationMmask_0_1,
  output        io_violationMmask_0_2,  output io_violationMmask_0_3,
  output        io_violationMmask_0_4,  output io_violationMmask_0_5,
  output        io_violationMmask_0_6,  output io_violationMmask_0_7,
  output        io_violationMmask_0_8,  output io_violationMmask_0_9,
  output        io_violationMmask_0_10, output io_violationMmask_0_11,
  output        io_violationMmask_0_12, output io_violationMmask_0_13,
  output        io_violationMmask_0_14, output io_violationMmask_0_15,
  output        io_violationMmask_0_16, output io_violationMmask_0_17,
  output        io_violationMmask_0_18, output io_violationMmask_0_19,
  output        io_violationMmask_0_20, output io_violationMmask_0_21,
  output        io_violationMmask_0_22, output io_violationMmask_0_23,
  output        io_violationMmask_0_24, output io_violationMmask_0_25,
  output        io_violationMmask_0_26, output io_violationMmask_0_27,
  output        io_violationMmask_0_28, output io_violationMmask_0_29,
  output        io_violationMmask_0_30, output io_violationMmask_0_31,
  output        io_violationMmask_1_0,  output io_violationMmask_1_1,
  output        io_violationMmask_1_2,  output io_violationMmask_1_3,
  output        io_violationMmask_1_4,  output io_violationMmask_1_5,
  output        io_violationMmask_1_6,  output io_violationMmask_1_7,
  output        io_violationMmask_1_8,  output io_violationMmask_1_9,
  output        io_violationMmask_1_10, output io_violationMmask_1_11,
  output        io_violationMmask_1_12, output io_violationMmask_1_13,
  output        io_violationMmask_1_14, output io_violationMmask_1_15,
  output        io_violationMmask_1_16, output io_violationMmask_1_17,
  output        io_violationMmask_1_18, output io_violationMmask_1_19,
  output        io_violationMmask_1_20, output io_violationMmask_1_21,
  output        io_violationMmask_1_22, output io_violationMmask_1_23,
  output        io_violationMmask_1_24, output io_violationMmask_1_25,
  output        io_violationMmask_1_26, output io_violationMmask_1_27,
  output        io_violationMmask_1_28, output io_violationMmask_1_29,
  output        io_violationMmask_1_30, output io_violationMmask_1_31
);

  localparam int SIZE  = 32;
  localparam int NBANK = 8;   // 8 bank × 4 entry
  localparam int NPORT = 3;

  // ---- 数据阵列 ----
  logic [23:0] data [SIZE];

  // ---- 写口聚合 ----
  logic        wen   [NPORT];
  logic [4:0]  waddr [NPORT];
  logic [23:0] wdata [NPORT];
  always_comb begin
    wen[0]=io_wen_0; wen[1]=io_wen_1; wen[2]=io_wen_2;
    waddr[0]=io_waddr_0; waddr[1]=io_waddr_1; waddr[2]=io_waddr_2;
    wdata[0]=io_wdata_0; wdata[1]=io_wdata_1; wdata[2]=io_wdata_2;
  end

  // writeAddrDec_p = 1 << waddr_p（32 位 one-hot）
  logic [31:0] writeAddrDec [NPORT];
  always_comb for (int p = 0; p < NPORT; p++) writeAddrDec[p] = 32'h1 << waddr[p];

  // ---- 1 拍延迟写流水（[bank][port]，镜像 golden DelayN 组）----
  //   bankWriteEn_delay      : DelayN(wen_p & |addrDec_p[bank])
  //   bankWriteAddrDec_pipMod : DelayNWithValid(addrDec_p[bank*4 +: 4], wen_p)
  //   writeData_pipMod        : DelayNWithValid(wdata_p, wen_p)
  logic        bankWriteEn_delay      [NBANK][NPORT];
  logic [3:0]  bankWriteAddrDec_pipMod[NBANK][NPORT];
  logic [23:0] writeData_pipMod       [NBANK][NPORT];

  always_ff @(posedge clock) begin
    for (int b = 0; b < NBANK; b++)
      for (int p = 0; p < NPORT; p++) begin
        bankWriteEn_delay[b][p] <= wen[p] & (|writeAddrDec[p][4*b +: 4]);
        if (wen[p]) begin
          bankWriteAddrDec_pipMod[b][p] <= writeAddrDec[p][4*b +: 4];
          writeData_pipMod[b][p]        <= wdata[p];
        end
      end
  end

  // 每条目的写使能 / 写数据：**组合信号**（不放 always_ff 内的 blocking 临时量,
  //   否则 FM 前端把 anyWr/wval/hit 各迭代推成死寄存器 anyWr_reg/wval_reg32/hit_reg
  //   → impl-only unread。移入 always_comb 后 always_ff 只留真状态 data[]）。
  logic            entryWrEn  [SIZE];
  logic [23:0]     entryWrVal [SIZE];
  always_comb
    for (int b = 0; b < NBANK; b++)
      for (int e = 0; e < 4; e++) begin
        logic        anyWr;
        logic [23:0] wval;
        anyWr = 1'b0;
        wval  = 24'h0;
        for (int p = 0; p < NPORT; p++) begin
          logic hit;
          hit = bankWriteEn_delay[b][p] & bankWriteAddrDec_pipMod[b][p][e];
          anyWr |= hit;
          if (hit) wval |= writeData_pipMod[b][p];
        end
        entryWrEn[4*b + e]  = anyWr;
        entryWrVal[4*b + e] = wval;
      end

  // data 写：条目命中则更新（clean always_ff，只留真寄存器 data[]）
  always_ff @(posedge clock)
    for (int i = 0; i < SIZE; i++)
      if (entryWrEn[i]) data[i] <= entryWrVal[i];

  // ---- 读口（组合 CAM 匹配）----
  logic [SIZE-1:0] mmask0, mmask1;
  always_comb
    for (int i = 0; i < SIZE; i++) begin
      mmask0[i] = (io_violationMdata_0[23:2] == data[i][23:2]) &
                  (io_violationCheckLine_0 | (io_violationMdata_0[1:0] == data[i][1:0]));
      mmask1[i] = (io_violationMdata_1[23:2] == data[i][23:2]) &
                  (io_violationCheckLine_1 | (io_violationMdata_1[1:0] == data[i][1:0]));
    end

  assign {io_violationMmask_0_31, io_violationMmask_0_30, io_violationMmask_0_29, io_violationMmask_0_28,
          io_violationMmask_0_27, io_violationMmask_0_26, io_violationMmask_0_25, io_violationMmask_0_24,
          io_violationMmask_0_23, io_violationMmask_0_22, io_violationMmask_0_21, io_violationMmask_0_20,
          io_violationMmask_0_19, io_violationMmask_0_18, io_violationMmask_0_17, io_violationMmask_0_16,
          io_violationMmask_0_15, io_violationMmask_0_14, io_violationMmask_0_13, io_violationMmask_0_12,
          io_violationMmask_0_11, io_violationMmask_0_10, io_violationMmask_0_9,  io_violationMmask_0_8,
          io_violationMmask_0_7,  io_violationMmask_0_6,  io_violationMmask_0_5,  io_violationMmask_0_4,
          io_violationMmask_0_3,  io_violationMmask_0_2,  io_violationMmask_0_1,  io_violationMmask_0_0} = mmask0;
  assign {io_violationMmask_1_31, io_violationMmask_1_30, io_violationMmask_1_29, io_violationMmask_1_28,
          io_violationMmask_1_27, io_violationMmask_1_26, io_violationMmask_1_25, io_violationMmask_1_24,
          io_violationMmask_1_23, io_violationMmask_1_22, io_violationMmask_1_21, io_violationMmask_1_20,
          io_violationMmask_1_19, io_violationMmask_1_18, io_violationMmask_1_17, io_violationMmask_1_16,
          io_violationMmask_1_15, io_violationMmask_1_14, io_violationMmask_1_13, io_violationMmask_1_12,
          io_violationMmask_1_11, io_violationMmask_1_10, io_violationMmask_1_9,  io_violationMmask_1_8,
          io_violationMmask_1_7,  io_violationMmask_1_6,  io_violationMmask_1_5,  io_violationMmask_1_4,
          io_violationMmask_1_3,  io_violationMmask_1_2,  io_violationMmask_1_1,  io_violationMmask_1_0} = mmask1;

endmodule
