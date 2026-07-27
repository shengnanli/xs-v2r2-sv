// MbistPipeL2Prefetcher —— 手写可读实现(TL2 shard D, AUX signoff)。
//
// L2 预取器内 MBIST(内建自测)分发流水级: 把上游 mbist 控制器的一拍请求
// 锁存, 再"扩散"(spread)到下游两个 SRAM bank(toSRAM_0 / toSRAM_1)。
//
// 请求锁存(activated = mbist_all | mbist_req 时更新控制寄存器):
//   - array/all/wen/ren 在 activated 时锁存;
//   - be/addr/dataIn/addrRd 仅在 activated 且(读或写)时锁存(节省翻转);
//   - reqReg 每拍跟随 mbist_req(用作 ack)。
//
// bank 选择(doSpread / doSpread_1):
//   arrayReg 选择目标 bank(0->bank0, 1->bank1); allReg=1 时两 bank 同时选中。
//   doSpread   = ~arrayReg | allReg  (bank0 使能)
//   doSpread_1 =  arrayReg | allReg  (bank1 使能)
// 未被选中的 bank addr 强制 0, re/we 门控清零。
//
// 读回合并: 只有被 array 选中的那个 bank 数据有效, 另一个读 0, 二者相或。
//
// 本文件定义可读核 xs_MbistPipeL2Prefetcher_core。golden 同名扁平端口包装
// 在 rtl/l2/MbistPipeL2Prefetcher_wrapper.sv(仅 FM impl 侧例化本核), UT 变体
// MbistPipeL2Prefetcher_xs 在 verif/ut 下。
module xs_MbistPipeL2Prefetcher_core(
  input         clock,
  input         reset,
  input         mbist_array,
  input         mbist_all,
  input         mbist_req,
  output        mbist_ack,
  input         mbist_writeen,
  input         mbist_be,
  input  [8:0]  mbist_addr,
  input  [12:0] mbist_indata,
  input         mbist_readen,
  input  [8:0]  mbist_addr_rd,
  output [12:0] mbist_outdata,
  output [8:0]  toSRAM_0_addr,
  output [8:0]  toSRAM_0_addr_rd,
  output [12:0] toSRAM_0_wdata,
  output        toSRAM_0_wmask,
  output        toSRAM_0_re,
  output        toSRAM_0_we,
  input  [12:0] toSRAM_0_rdata,
  output        toSRAM_0_ack,
  output        toSRAM_0_selectedOH,
  output        toSRAM_0_array,
  output [8:0]  toSRAM_1_addr,
  output [8:0]  toSRAM_1_addr_rd,
  output [12:0] toSRAM_1_wdata,
  output        toSRAM_1_wmask,
  output        toSRAM_1_re,
  output        toSRAM_1_we,
  input  [12:0] toSRAM_1_rdata,
  output        toSRAM_1_ack,
  output        toSRAM_1_selectedOH,
  output        toSRAM_1_array
);

  // ---- 锁存的 MBIST 控制/数据寄存器 ----
  reg        arrayReg;   // 目标 bank 选择(0=bank0, 1=bank1)
  reg        reqReg;     // 请求脉冲跟随(用作 ack)
  reg        allReg;     // 全阵列(两 bank 同时)标志
  reg        wenReg;     // 写使能
  reg        beReg;      // 字节使能(写 mask)
  reg  [8:0] addrReg;    // 写地址
  reg  [12:0] dataInReg; // 写数据
  reg        renReg;     // 读使能
  reg  [8:0] addrRdReg;  // 读地址

  wire activated = mbist_all | mbist_req;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      arrayReg  <= 1'h0;
      reqReg    <= 1'h0;
      allReg    <= 1'h0;
      wenReg    <= 1'h0;
      beReg     <= 1'h0;
      addrReg   <= 9'h0;
      dataInReg <= 13'h0;
      renReg    <= 1'h0;
      addrRdReg <= 9'h0;
    end
    else begin
      if (activated) begin
        arrayReg <= mbist_array;
        allReg   <= mbist_all;
        wenReg   <= mbist_writeen;
        renReg   <= mbist_readen;
      end
      reqReg <= mbist_req;
      if (activated & (mbist_readen | mbist_writeen)) begin
        beReg     <= mbist_be;
        addrReg   <= mbist_addr;
        dataInReg <= mbist_indata;
        addrRdReg <= mbist_addr_rd;
      end
    end
  end

  // ---- bank 选择(spread) ----
  wire doSpread   = ~arrayReg | allReg;   // bank0 使能
  wire doSpread_1 =  arrayReg | allReg;   // bank1 使能

  // ---- 读回合并(仅被 array 选中的 bank 有效) ----
  wire [12:0] sramDataOut_0 = arrayReg ? 13'h0 : toSRAM_0_rdata;
  wire [12:0] sramDataOut_1 = arrayReg ? toSRAM_1_rdata : 13'h0;

  // ---- 输出 ----
  assign mbist_ack     = reqReg;
  assign mbist_outdata = sramDataOut_0 | sramDataOut_1;

  assign toSRAM_0_addr       = doSpread ? addrReg : 9'h0;
  assign toSRAM_0_addr_rd    = doSpread ? addrRdReg : 9'h0;
  assign toSRAM_0_wdata      = dataInReg;
  assign toSRAM_0_wmask      = beReg;
  assign toSRAM_0_re         = doSpread & renReg;
  assign toSRAM_0_we         = doSpread & wenReg;
  assign toSRAM_0_ack        = reqReg;
  assign toSRAM_0_selectedOH = allReg | ~reqReg | ~arrayReg;
  assign toSRAM_0_array      = arrayReg;

  assign toSRAM_1_addr       = doSpread_1 ? addrReg : 9'h0;
  assign toSRAM_1_addr_rd    = doSpread_1 ? addrRdReg : 9'h0;
  assign toSRAM_1_wdata      = dataInReg;
  assign toSRAM_1_wmask      = beReg;
  assign toSRAM_1_re         = doSpread_1 & renReg;
  assign toSRAM_1_we         = doSpread_1 & wenReg;
  assign toSRAM_1_ack        = reqReg;
  assign toSRAM_1_selectedOH = allReg | ~reqReg | arrayReg;
  assign toSRAM_1_array      = arrayReg;

endmodule
