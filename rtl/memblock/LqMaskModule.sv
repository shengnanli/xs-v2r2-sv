// =============================================================================
//  LqMaskModule —— LoadQueueRAW 字节 mask CAM（可读重写，镜像 golden 层次）
// -----------------------------------------------------------------------------
//  设计意图来源: src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala
//    (LqMaskModule: numEntries=32, numRead=2(violation), numWrite=3, gen=UInt(16.W))
//
//  与 golden LoadQueueRAW.sv 内例化的 `LqMaskModule maskModule` 端口/内部寄存器逐一
//  对应，供 FM 层次化配对。
//
//  写路径与 LqPAddrModule_1 相同（banked，1 拍延迟写；见该文件说明），仅数据宽度 16 位。
//  读路径（组合）: io_violationMmask_p_N = |(io_violationMdata_p & data_N)
//    —— 任一字节 mask 重叠即视为可能违例（store 与 load 访问同一字节）。
// =============================================================================
module LqMaskModule(
  input         clock,
  input         reset,
  input         io_wen_0,
  input         io_wen_1,
  input         io_wen_2,
  input  [4:0]  io_waddr_0,
  input  [4:0]  io_waddr_1,
  input  [4:0]  io_waddr_2,
  input  [15:0] io_wdata_0,
  input  [15:0] io_wdata_1,
  input  [15:0] io_wdata_2,
  input  [15:0] io_violationMdata_0,
  input  [15:0] io_violationMdata_1,
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
  localparam int NBANK = 8;
  localparam int NPORT = 3;

  logic [15:0] data [SIZE];

  logic        wen   [NPORT];
  logic [4:0]  waddr [NPORT];
  logic [15:0] wdata [NPORT];
  always_comb begin
    wen[0]=io_wen_0; wen[1]=io_wen_1; wen[2]=io_wen_2;
    waddr[0]=io_waddr_0; waddr[1]=io_waddr_1; waddr[2]=io_waddr_2;
    wdata[0]=io_wdata_0; wdata[1]=io_wdata_1; wdata[2]=io_wdata_2;
  end

  logic [31:0] writeAddrDec [NPORT];
  always_comb for (int p = 0; p < NPORT; p++) writeAddrDec[p] = 32'h1 << waddr[p];

  logic        bankWriteEn_delay      [NBANK][NPORT];
  logic [3:0]  bankWriteAddrDec_pipMod[NBANK][NPORT];
  logic [15:0] writeData_pipMod       [NBANK][NPORT];

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

  // 每条目写使能/写数据用**组合信号**（不放 always_ff 内 blocking 临时量, 否则 FM 把
  //   anyWr/wval/hit 推成死寄存器 → impl-only unread; 移 always_comb, always_ff 只留 data[]）。
  logic        entryWrEn  [SIZE];
  logic [15:0] entryWrVal [SIZE];
  always_comb
    for (int b = 0; b < NBANK; b++)
      for (int e = 0; e < 4; e++) begin
        logic        anyWr;
        logic [15:0] wval;
        anyWr = 1'b0;
        wval  = 16'h0;
        for (int p = 0; p < NPORT; p++) begin
          logic hit;
          hit = bankWriteEn_delay[b][p] & bankWriteAddrDec_pipMod[b][p][e];
          anyWr |= hit;
          if (hit) wval |= writeData_pipMod[b][p];
        end
        entryWrEn[4*b + e]  = anyWr;
        entryWrVal[4*b + e] = wval;
      end

  always_ff @(posedge clock)
    for (int i = 0; i < SIZE; i++)
      if (entryWrEn[i]) data[i] <= entryWrVal[i];

  logic [SIZE-1:0] mmask0, mmask1;
  always_comb
    for (int i = 0; i < SIZE; i++) begin
      mmask0[i] = |(io_violationMdata_0 & data[i]);
      mmask1[i] = |(io_violationMdata_1 & data[i]);
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
