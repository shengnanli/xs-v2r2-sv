// =============================================================================
//  RXDAT —— coupledL2 (tl2chi) CHI DAT 接收通道 可读重写核 (xs_RXDAT_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/tl2chi/RXDAT.scala
//  把 CHI 互联回来的 DAT flit(CompData) 一拍数据写入 refillBuffer, 并向 MSHRCtl 投递
//  RespBundle。单态化 (firtool RXDAT.sv): 纯组合(clock/reset 仅供 SYNTHESIS 下裁掉的断言);
//  enableDataCheck=true, dataCheckMethod=1 (逐字节奇偶校验)。
//
//  ===== 节拍 (256-bit 总线, 一个 cacheline 两拍) =====
//    dataID==2'b00 => first(第一拍)   dataID==2'b10 => last(第二拍)
//
//  ===== DataCheck (method 1, 逐字节奇偶) =====
//    每字节: 期望 dataCheck[i] == 该字节奇偶(xorR)取反; 不符即出错。
//    term_i = dataCheck[i] ^ ~(^data[8i+7:8i]) ; dataCheck = OR_i term_i
//    (Scala: dataCheck.get(i) ^ data(..).xorR ^ true.B, 即 a^b^1 = a^~b)
//
//  ===== 输出 =====
//    refillBufWrite: 把这一拍 256b 数据复制两份铺满 512b 行槽(beatMask 选写哪拍)
//    in(RespBundle): first|last 时有效; corrupt = NDERR|DERR|dataCheck|poison
//    ★注意 dataCheck 只经 corrupt 外露，本模块**不**单独输出 dataCheckErr★：
//    G0 曾有 io_in_respInfo_dataCheckErr 端口，G1 已删（校验值本身仍是输入，
//    wire dataCheck 仍算并喂给 corrupt）。上轮迁移时误把 G0 的这个端口带了过来，
//    导致 tb 在 golden 侧连了 G1 不存在的端口、UT 根本编不过。
// =============================================================================

module xs_RXDAT_core (
  input          clock,   // 仅供 SYNTHESIS 下被裁掉的 dataCheck 断言, 组合逻辑不用
  input          reset,
  // ---- io.out (Flipped DecoupledIO CHIDAT, 来自 CHI 互联) ----
  input          io_out_valid,
  input  [11:0]  io_out_bits_txnID,
  input  [10:0]  io_out_bits_homeNID,
  input  [3:0]   io_out_bits_opcode,
  input  [1:0]   io_out_bits_respErr,
  input  [2:0]   io_out_bits_resp,
  input  [11:0]  io_out_bits_dbID,
  input  [1:0]   io_out_bits_dataID,
  input          io_out_bits_traceTag,
  input  [255:0] io_out_bits_data,
  input  [31:0]  io_out_bits_dataCheck,
  input  [3:0]   io_out_bits_poison,
  // ---- io.in (Output RespBundle, 投向 MSHRCtl) ----
  output         io_in_valid,
  output [7:0]   io_in_mshrId,
  output         io_in_respInfo_last,
  output         io_in_respInfo_corrupt,
  output [6:0]   io_in_respInfo_chiOpcode,
  output [10:0]  io_in_respInfo_homeNID,
  output [11:0]  io_in_respInfo_dbID,
  output [2:0]   io_in_respInfo_resp,
  output [1:0]   io_in_respInfo_respErr,
  output         io_in_respInfo_traceTag,
  // ---- io.refillBufWrite (ValidIO MSHRBufWrite) ----
  output         io_refillBufWrite_valid,
  output [7:0]   io_refillBufWrite_bits_id,
  output [511:0] io_refillBufWrite_bits_data_data,
  output [1:0]   io_refillBufWrite_bits_beatMask
);

  // 节拍判定
  wire first = io_out_bits_dataID == 2'h0;
  wire last  = io_out_bits_dataID == 2'h2;

  // 逐字节奇偶校验: byte_check[i]=1 表示第 i 字节校验失败
  wire [31:0] byte_check;
  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : g_datacheck
      assign byte_check[i] = io_out_bits_dataCheck[i] ^ ~(^io_out_bits_data[8*i +: 8]);
    end
  endgenerate
  wire dataCheck = |byte_check;
  wire poison    = |io_out_bits_poison;

  // RespErrEncodings: NDERR=2'h2, DERR=2'h3(两位全 1)
  wire denied  = io_out_bits_respErr == 2'h2;
  wire derr    = &io_out_bits_respErr;

  // 写 refillBuffer: 256b 一拍数据复制两份铺满 512b 行槽
  assign io_refillBufWrite_valid        = io_out_valid;
  assign io_refillBufWrite_bits_id      = io_out_bits_txnID[7:0];
  assign io_refillBufWrite_bits_data_data = {2{io_out_bits_data}};
  assign io_refillBufWrite_bits_beatMask  = {last, first};

  // 投向 MSHR 的 RespBundle
  assign io_in_valid                 = (first | last) & io_out_valid;
  assign io_in_mshrId                = io_out_bits_txnID[7:0];
  assign io_in_respInfo_last         = last;
  assign io_in_respInfo_corrupt      = denied | derr | dataCheck | poison;
  assign io_in_respInfo_chiOpcode    = {3'h0, io_out_bits_opcode};
  assign io_in_respInfo_homeNID      = io_out_bits_homeNID;
  assign io_in_respInfo_dbID         = io_out_bits_dbID;
  assign io_in_respInfo_resp         = io_out_bits_resp;
  assign io_in_respInfo_respErr      = io_out_bits_respErr;
  assign io_in_respInfo_traceTag     = io_out_bits_traceTag;

endmodule

// 自动生成 xs-v2r2-sv/scripts/gen_chi_channel.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module RXDAT(
  input clock,
  input reset,
  input io_out_valid,
  input [11:0] io_out_bits_txnID,
  input [10:0] io_out_bits_homeNID,
  input [3:0] io_out_bits_opcode,
  input [1:0] io_out_bits_respErr,
  input [2:0] io_out_bits_resp,
  input [11:0] io_out_bits_dbID,
  input [1:0] io_out_bits_dataID,
  input io_out_bits_traceTag,
  input [255:0] io_out_bits_data,
  input [31:0] io_out_bits_dataCheck,
  input [3:0] io_out_bits_poison,
  output io_in_valid,
  output [7:0] io_in_mshrId,
  output io_in_respInfo_last,
  output io_in_respInfo_corrupt,
  output [6:0] io_in_respInfo_chiOpcode,
  output [10:0] io_in_respInfo_homeNID,
  output [11:0] io_in_respInfo_dbID,
  output [2:0] io_in_respInfo_resp,
  output [1:0] io_in_respInfo_respErr,
  output io_in_respInfo_traceTag,
  output io_refillBufWrite_valid,
  output [7:0] io_refillBufWrite_bits_id,
  output [511:0] io_refillBufWrite_bits_data_data,
  output [1:0] io_refillBufWrite_bits_beatMask
);
  xs_RXDAT_core u_core (
    .clock(clock),
    .reset(reset),
    .io_out_valid(io_out_valid),
    .io_out_bits_txnID(io_out_bits_txnID),
    .io_out_bits_homeNID(io_out_bits_homeNID),
    .io_out_bits_opcode(io_out_bits_opcode),
    .io_out_bits_respErr(io_out_bits_respErr),
    .io_out_bits_resp(io_out_bits_resp),
    .io_out_bits_dbID(io_out_bits_dbID),
    .io_out_bits_dataID(io_out_bits_dataID),
    .io_out_bits_traceTag(io_out_bits_traceTag),
    .io_out_bits_data(io_out_bits_data),
    .io_out_bits_dataCheck(io_out_bits_dataCheck),
    .io_out_bits_poison(io_out_bits_poison),
    .io_in_valid(io_in_valid),
    .io_in_mshrId(io_in_mshrId),
    .io_in_respInfo_last(io_in_respInfo_last),
    .io_in_respInfo_corrupt(io_in_respInfo_corrupt),
    .io_in_respInfo_chiOpcode(io_in_respInfo_chiOpcode),
    .io_in_respInfo_homeNID(io_in_respInfo_homeNID),
    .io_in_respInfo_dbID(io_in_respInfo_dbID),
    .io_in_respInfo_resp(io_in_respInfo_resp),
    .io_in_respInfo_respErr(io_in_respInfo_respErr),
    .io_in_respInfo_traceTag(io_in_respInfo_traceTag),
    .io_refillBufWrite_valid(io_refillBufWrite_valid),
    .io_refillBufWrite_bits_id(io_refillBufWrite_bits_id),
    .io_refillBufWrite_bits_data_data(io_refillBufWrite_bits_data_data),
    .io_refillBufWrite_bits_beatMask(io_refillBufWrite_bits_beatMask)
  );
endmodule
