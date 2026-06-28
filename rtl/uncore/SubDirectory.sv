// =============================================================================
//  xs_SubDirectory_core —— openLLC SubDirectory(clientDir 实例)可读重写核
// -----------------------------------------------------------------------------
//  对照 Scala openLLC/src/main/scala/openLLC/Directory.scala 的 class SubDirectory,
//  以及 firtool 单态化产物 golden/chisel-rtl/SubDirectory.sv。
//
//  本核只做三级流水的控制/选路逻辑; tagArray/metaArray 两块 SRAM 与随机替换 LFSR
//  作为黑盒由外层 SubDirectory(wrapper) 例化, 通过下面 i_*/o_* 接口与本核对接:
//    i_tagRead_*   : tagArray  读出的 10 路 tag (组合, fire 后下一拍有效)
//    i_metaValid_* : metaArray 读出的 10 路 meta.valid
//    i_lfsr_*      : LFSR 低 7 位(自由运行), 供随机替换路计算
//    o_ren         : SRAM 读使能 (= io.read.fire)
//    o_tagWaymask  : tagArray  写 waymask (one-hot of io_tagWReq_bits_way)
//    o_metaWen / o_metaWset / o_metaWdata / o_metaWaymask : metaArray 写控制
//                    (复位期写 init=0 全路, 复位后写 io_metaWReq)
//
//  寄存器命名与 golden 保持一致(resetFinish/resetIdx/reqValid_s2/req_s2_*/
//  reqValid_s3/req_s3_*/metaValidVec_*/tagAll_s3_*) 以利 Formality 配对。
// =============================================================================
`timescale 1ns/1ps

module xs_SubDirectory_core
  import subdirectory_pkg::*;
(
  input               clock,
  input               reset,

  // ---- io.read (请求入口) ----
  output              io_read_ready,
  input               io_read_valid,
  input  [29:0]       io_read_bits_tag,
  input  [9:0]        io_read_bits_set,
  input  [6:0]        io_read_bits_replacerInfo_opcode,  // random 替换未用
  input               io_read_bits_replacerInfo_refill,  // random 替换未用

  // ---- io.resp (响应出口, stage3) ----
  output              io_resp_valid,
  output              io_resp_bits_hit,
  output [29:0]       io_resp_bits_tag,
  output [9:0]        io_resp_bits_set,
  output [3:0]        io_resp_bits_way,
  output              io_resp_bits_meta_0_valid,
  output              io_resp_bits_error,

  // ---- io.tagWReq (tag 写) ----
  input               io_tagWReq_valid,
  input  [9:0]        io_tagWReq_bits_set,
  input  [3:0]        io_tagWReq_bits_way,
  input  [29:0]       io_tagWReq_bits_wtag,

  // ---- io.metaWReq (meta 写) ----
  input               io_metaWReq_valid,
  input  [9:0]        io_metaWReq_bits_set,
  input  [9:0]        io_metaWReq_bits_wayOH,
  input               io_metaWReq_bits_wmeta_0_valid,

  // ---- 与 SRAM 黑盒的读数据接口 (10 路) ----
  input  [29:0]       i_tagRead_0,  input  [29:0] i_tagRead_1,
  input  [29:0]       i_tagRead_2,  input  [29:0] i_tagRead_3,
  input  [29:0]       i_tagRead_4,  input  [29:0] i_tagRead_5,
  input  [29:0]       i_tagRead_6,  input  [29:0] i_tagRead_7,
  input  [29:0]       i_tagRead_8,  input  [29:0] i_tagRead_9,
  input               i_metaValid_0, input        i_metaValid_1,
  input               i_metaValid_2, input        i_metaValid_3,
  input               i_metaValid_4, input        i_metaValid_5,
  input               i_metaValid_6, input        i_metaValid_7,
  input               i_metaValid_8, input        i_metaValid_9,

  // ---- LFSR 低 7 位 (随机替换) ----
  input               i_lfsr_0, input i_lfsr_1, input i_lfsr_2, input i_lfsr_3,
  input               i_lfsr_4, input i_lfsr_5, input i_lfsr_6,

  // ---- 控制 SRAM 黑盒 ----
  output              o_ren,
  output [9:0]        o_tagWaymask,
  output              o_metaWen,
  output [9:0]        o_metaWset,
  output              o_metaWdata,
  output [9:0]        o_metaWaymask
);

  // ---------------------------------------------------------------------------
  // 复位扫写: resetIdx 从 SETS-1 递减到 0, 期间向 metaArray 全路写 init(valid=0),
  // 到 0 后 resetFinish 拉高, 之后才接受读/写请求。
  // ---------------------------------------------------------------------------
  reg               resetFinish;
  reg  [9:0]        resetIdx;

  // io.read.ready: 无 meta/tag 写 且 复位完成 (random 替换无 replacerWen)
  wire io_read_ready_int = ~io_metaWReq_valid & ~io_tagWReq_valid & resetFinish;
  wire read_fire = io_read_ready_int & io_read_valid;  // golden: _req_s2_T

  // ---------------------------------------------------------------------------
  // 流水寄存器
  //   s2: 锁存读请求 (fire 后 1 拍)
  //   s3: 锁存 SRAM 读出的 tag/metaValid + 透传 s2 请求 (fire 后 2 拍)
  // ---------------------------------------------------------------------------
  reg               reqValid_s2;
  reg  [29:0]       req_s2_tag;
  reg  [9:0]        req_s2_set;

  reg               reqValid_s3;
  reg  [29:0]       req_s3_tag;
  reg  [9:0]        req_s3_set;

  reg               metaValidVec [WAYS];   // 10 路 meta.valid
  reg  [29:0]       tagAll_s3    [WAYS];   // 10 路 tag

  // 把扁平 SRAM 读口聚成数组, 便于本拍锁存。
  wire        metaRead [WAYS];
  wire [29:0] tagRead  [WAYS];
  assign metaRead[0]=i_metaValid_0; assign metaRead[1]=i_metaValid_1;
  assign metaRead[2]=i_metaValid_2; assign metaRead[3]=i_metaValid_3;
  assign metaRead[4]=i_metaValid_4; assign metaRead[5]=i_metaValid_5;
  assign metaRead[6]=i_metaValid_6; assign metaRead[7]=i_metaValid_7;
  assign metaRead[8]=i_metaValid_8; assign metaRead[9]=i_metaValid_9;
  assign tagRead[0]=i_tagRead_0; assign tagRead[1]=i_tagRead_1;
  assign tagRead[2]=i_tagRead_2; assign tagRead[3]=i_tagRead_3;
  assign tagRead[4]=i_tagRead_4; assign tagRead[5]=i_tagRead_5;
  assign tagRead[6]=i_tagRead_6; assign tagRead[7]=i_tagRead_7;
  assign tagRead[8]=i_tagRead_8; assign tagRead[9]=i_tagRead_9;

  integer rstk;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      resetFinish <= 1'b0;
      resetIdx    <= 10'h3FF;       // SETS-1
      reqValid_s2 <= 1'b0;
      req_s2_tag  <= 30'h0;
      req_s2_set  <= 10'h0;
      reqValid_s3 <= 1'b0;
      req_s3_tag  <= 30'h0;
      req_s3_set  <= 10'h0;
      for (rstk = 0; rstk < WAYS; rstk = rstk + 1) begin
        metaValidVec[rstk] <= 1'b0;
        tagAll_s3[rstk]    <= 30'h0;
      end
    end
    else begin
      // 复位扫写计数
      resetFinish <= (resetIdx == 10'h0) | resetFinish;
      if (!resetFinish)
        resetIdx <= resetIdx - 10'h1;

      // s2: 锁存读请求
      reqValid_s2 <= read_fire;
      if (read_fire) begin
        req_s2_tag <= io_read_bits_tag;
        req_s2_set <= io_read_bits_set;
      end

      // s3: 锁存 SRAM 读出 + 透传 s2 请求
      reqValid_s3 <= reqValid_s2;
      if (reqValid_s2) begin
        req_s3_tag <= req_s2_tag;
        req_s3_set <= req_s2_set;
        for (rstk = 0; rstk < WAYS; rstk = rstk + 1) begin
          metaValidVec[rstk] <= metaRead[rstk];
          tagAll_s3[rstk]    <= tagRead[rstk];
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 选路逻辑 (stage3, 全组合)
  //   tagMatch[w] = (tagAll_s3[w] == req_s3_tag)
  //   hitVec[w]   = tagMatch[w] & metaValidVec[w]
  // ---------------------------------------------------------------------------
  wire [WAYS-1:0] tagMatch;
  wire [WAYS-1:0] hitVec;
  genvar w;
  generate
    for (w = 0; w < WAYS; w = w + 1) begin : g_hit
      assign tagMatch[w] = (tagAll_s3[w] == req_s3_tag);
      assign hitVec[w]   = tagMatch[w] & metaValidVec[w];
    end
  endgenerate

  wire hit_s3 = |hitVec;

  // hitWay = OHToUInt(hitVec): one-hot → 二进制下标 (按下标各 bit 的 OR)
  wire [3:0] hitWay;
  assign hitWay[0] = hitVec[1] | hitVec[3] | hitVec[5] | hitVec[7] | hitVec[9];
  assign hitWay[1] = hitVec[2] | hitVec[3] | hitVec[6] | hitVec[7];
  assign hitWay[2] = hitVec[4] | hitVec[5] | hitVec[6] | hitVec[7];
  assign hitWay[3] = hitVec[8] | hitVec[9];

  // invalid_way_sel: 有空路则取下标最小的空路 (ParallelPriorityMux over ~valid)
  wire [WAYS-1:0] invalidVec;
  generate
    for (w = 0; w < WAYS; w = w + 1) begin : g_inv
      assign invalidVec[w] = ~metaValidVec[w];
    end
  endgenerate
  wire hasInvalid = |invalidVec;

  reg  [3:0] invalidWay;
  integer ik;
  always @* begin
    invalidWay = 4'd0;
    for (ik = WAYS-1; ik >= 0; ik = ik - 1)
      if (invalidVec[ik]) invalidWay = ik[3:0];   // 倒序遍历, 最小下标最后写入→优先
  end

  // 随机替换路: 把 LFSR 低 7 位映射到 [0,9] (repl.get_replace_way, 非均匀阈值梯)
  wire [6:0] replRand = {i_lfsr_6, i_lfsr_5, i_lfsr_4, i_lfsr_3,
                         i_lfsr_2, i_lfsr_1, i_lfsr_0};
  wire [3:0] replaceWay =
      (replRand < 7'h0C) ? 4'h0 :
      (replRand < 7'h19) ? 4'h1 :
      (replRand < 7'h26) ? 4'h2 :
      (replRand < 7'h33) ? 4'h3 :
      i_lfsr_6                                   // replRand[6] (即 >=64)
        ? ((replRand < 7'h4C) ? 4'h5 :
           (replRand < 7'h59) ? 4'h6 :
           (replRand < 7'h66) ? 4'h7 :
                                {3'h4, (replRand > 7'h72)})  // >114→9, 否则 8
        : 4'h4;

  // chosenWay = 有空路则填空路, 否则随机替换路; 命中则用命中路
  wire [3:0] chosenWay = hasInvalid ? invalidWay : replaceWay;
  wire [3:0] way_s3    = hit_s3 ? hitWay : chosenWay;

  // 按 way_s3 选出 tag / meta.valid (way_s3 ∈ [0,9]; 默认走 0 与 golden 一致)
  reg  [29:0] sel_tag;
  reg         sel_meta_valid;
  always @* begin
    case (way_s3)
      4'd0: begin sel_tag = tagAll_s3[0]; sel_meta_valid = metaValidVec[0]; end
      4'd1: begin sel_tag = tagAll_s3[1]; sel_meta_valid = metaValidVec[1]; end
      4'd2: begin sel_tag = tagAll_s3[2]; sel_meta_valid = metaValidVec[2]; end
      4'd3: begin sel_tag = tagAll_s3[3]; sel_meta_valid = metaValidVec[3]; end
      4'd4: begin sel_tag = tagAll_s3[4]; sel_meta_valid = metaValidVec[4]; end
      4'd5: begin sel_tag = tagAll_s3[5]; sel_meta_valid = metaValidVec[5]; end
      4'd6: begin sel_tag = tagAll_s3[6]; sel_meta_valid = metaValidVec[6]; end
      4'd7: begin sel_tag = tagAll_s3[7]; sel_meta_valid = metaValidVec[7]; end
      4'd8: begin sel_tag = tagAll_s3[8]; sel_meta_valid = metaValidVec[8]; end
      4'd9: begin sel_tag = tagAll_s3[9]; sel_meta_valid = metaValidVec[9]; end
      default: begin sel_tag = tagAll_s3[0]; sel_meta_valid = metaValidVec[0]; end
    endcase
  end

  // ---------------------------------------------------------------------------
  // 输出
  // ---------------------------------------------------------------------------
  assign io_read_ready             = io_read_ready_int;
  assign io_resp_valid             = reqValid_s3;
  assign io_resp_bits_hit          = hit_s3;
  assign io_resp_bits_tag          = sel_tag;
  assign io_resp_bits_set          = req_s3_set;
  assign io_resp_bits_way          = way_s3;
  assign io_resp_bits_meta_0_valid = sel_meta_valid;
  assign io_resp_bits_error        = 1'b0;

  // ---- SRAM 黑盒控制输出 ----
  wire [15:0] tagWayOH16 = 16'h0001 << io_tagWReq_bits_way;
  assign o_ren          = read_fire;
  assign o_tagWaymask   = tagWayOH16[9:0];
  assign o_metaWen      = io_metaWReq_valid | ~resetFinish;
  assign o_metaWset     = resetFinish ? io_metaWReq_bits_set : resetIdx;
  assign o_metaWdata    = resetFinish & io_metaWReq_bits_wmeta_0_valid;
  assign o_metaWaymask  = resetFinish ? io_metaWReq_bits_wayOH : 10'h3FF;

endmodule
