// =============================================================================
//  subdirectory_pkg —— openLLC 目录子块 SubDirectory 的参数与类型
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/Directory.scala
//    class SubDirectory[T <: Data](sets, ways, tagBits, meta_init_fn,
//                                  meta_valid_fn, invalid_way_sel, replacement)
//  顶层 Directory 例化两个 SubDirectory:
//    - clientDir = SubDirectory[Vec[ClientMetaEntry]] (snoop filter)
//    - selfDir   = SubDirectory[SelfMetaEntry]
//  本文件对应的 golden `SubDirectory`(516 行) 是 clientDir 实例的单态化:
//    sets=1024(setBits=10), ways=10(wayBits=4), tagBits=30,
//    meta = Vec(numRNs=1) of ClientMetaEntry{valid:Bool}  →  仅一个 valid 位/路
//    replacement = "random"  →  用 MaxPeriodFibonacciLFSR 产生替换路, 无 replacer SRAM
//
//  三级流水(见 Scala 注释):
//    stage1: io.read.fire, 发起 Tag/Meta SRAM 读
//    stage2: SRAM 数据回来, 锁存 tagAll_s3 / metaValidVec (用 reqValid_s2 门控)
//    stage3: 算 hit/way, 选出 meta/tag, io.resp.valid=reqValid_s3
//
//  3 个黑盒子模块(在 wrapper 内例化, 核只接其读口/控制口):
//    SRAMTemplate_197  tagArray  (10 路 × 30bit × 1024 set, 单口)
//    SRAMTemplate_193  metaArray (10 路 × 1bit(valid) × 1024 set, 单口)
//    MaxPeriodFibonacciLFSR_3    随机替换的 16 位 Fibonacci LFSR(自由运行, 取低 7 位)
// =============================================================================
package subdirectory_pkg;

  localparam int WAYS     = 10;  // 路数
  localparam int WAY_BITS = 4;   // log2Ceil(10) = 4
  localparam int SETS     = 1024;
  localparam int SET_BITS = 10;
  localparam int TAG_BITS = 30;

  // ClientMetaEntry: 仅含一个 valid 位 (numRNs=1, 故 meta 是 Vec(1))。
  // meta_valid_fn(clients) = Cat(metas.map(_.valid)).orR, 单元素即该 valid。
  typedef struct packed {
    logic valid;
  } client_meta_entry_t;

endpackage

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

// 自动生成 scripts/gen_subdirectory.py —— 勿手改

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module SubDirectory(
  input clock,
  input reset,
  output io_read_ready,
  input io_read_valid,
  input [29:0] io_read_bits_tag,
  input [9:0] io_read_bits_set,
  input [6:0] io_read_bits_replacerInfo_opcode,
  input io_read_bits_replacerInfo_refill,
  output io_resp_valid,
  output io_resp_bits_hit,
  output [29:0] io_resp_bits_tag,
  output [9:0] io_resp_bits_set,
  output [3:0] io_resp_bits_way,
  output io_resp_bits_meta_0_valid,
  output io_resp_bits_error,
  input io_tagWReq_valid,
  input [9:0] io_tagWReq_bits_set,
  input [3:0] io_tagWReq_bits_way,
  input [29:0] io_tagWReq_bits_wtag,
  input io_metaWReq_valid,
  input [9:0] io_metaWReq_bits_set,
  input [9:0] io_metaWReq_bits_wayOH,
  input io_metaWReq_bits_wmeta_0_valid
);

  wire              _lfsr_prng_io_out_0;
  wire              _lfsr_prng_io_out_1;
  wire              _lfsr_prng_io_out_2;
  wire              _lfsr_prng_io_out_3;
  wire              _lfsr_prng_io_out_4;
  wire              _lfsr_prng_io_out_5;
  wire              _lfsr_prng_io_out_6;
  wire              _metaArray_io_r_resp_data_0_0_valid;
  wire              _metaArray_io_r_resp_data_1_0_valid;
  wire              _metaArray_io_r_resp_data_2_0_valid;
  wire              _metaArray_io_r_resp_data_3_0_valid;
  wire              _metaArray_io_r_resp_data_4_0_valid;
  wire              _metaArray_io_r_resp_data_5_0_valid;
  wire              _metaArray_io_r_resp_data_6_0_valid;
  wire              _metaArray_io_r_resp_data_7_0_valid;
  wire              _metaArray_io_r_resp_data_8_0_valid;
  wire              _metaArray_io_r_resp_data_9_0_valid;
  wire [29:0]       _tagArray_io_r_resp_data_0;
  wire [29:0]       _tagArray_io_r_resp_data_1;
  wire [29:0]       _tagArray_io_r_resp_data_2;
  wire [29:0]       _tagArray_io_r_resp_data_3;
  wire [29:0]       _tagArray_io_r_resp_data_4;
  wire [29:0]       _tagArray_io_r_resp_data_5;
  wire [29:0]       _tagArray_io_r_resp_data_6;
  wire [29:0]       _tagArray_io_r_resp_data_7;
  wire [29:0]       _tagArray_io_r_resp_data_8;
  wire [29:0]       _tagArray_io_r_resp_data_9;

  // ---- 核与 SRAM/LFSR 黑盒的边界 wire (核的 o_* 输出) ----
  wire        o_ren;
  wire [9:0]  o_tagWaymask;
  wire        o_metaWen;
  wire [9:0]  o_metaWset;
  wire        o_metaWdata;
  wire [9:0]  o_metaWaymask;

  xs_SubDirectory_core u_core (
    .clock(clock),
    .reset(reset),
    .io_read_ready(io_read_ready),
    .io_read_valid(io_read_valid),
    .io_read_bits_tag(io_read_bits_tag),
    .io_read_bits_set(io_read_bits_set),
    .io_read_bits_replacerInfo_opcode(io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_refill(io_read_bits_replacerInfo_refill),
    .io_resp_valid(io_resp_valid),
    .io_resp_bits_hit(io_resp_bits_hit),
    .io_resp_bits_tag(io_resp_bits_tag),
    .io_resp_bits_set(io_resp_bits_set),
    .io_resp_bits_way(io_resp_bits_way),
    .io_resp_bits_meta_0_valid(io_resp_bits_meta_0_valid),
    .io_resp_bits_error(io_resp_bits_error),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_0_valid(io_metaWReq_bits_wmeta_0_valid),
    .i_tagRead_0(_tagArray_io_r_resp_data_0),
    .i_tagRead_1(_tagArray_io_r_resp_data_1),
    .i_tagRead_2(_tagArray_io_r_resp_data_2),
    .i_tagRead_3(_tagArray_io_r_resp_data_3),
    .i_tagRead_4(_tagArray_io_r_resp_data_4),
    .i_tagRead_5(_tagArray_io_r_resp_data_5),
    .i_tagRead_6(_tagArray_io_r_resp_data_6),
    .i_tagRead_7(_tagArray_io_r_resp_data_7),
    .i_tagRead_8(_tagArray_io_r_resp_data_8),
    .i_tagRead_9(_tagArray_io_r_resp_data_9),
    .i_metaValid_0(_metaArray_io_r_resp_data_0_0_valid),
    .i_metaValid_1(_metaArray_io_r_resp_data_1_0_valid),
    .i_metaValid_2(_metaArray_io_r_resp_data_2_0_valid),
    .i_metaValid_3(_metaArray_io_r_resp_data_3_0_valid),
    .i_metaValid_4(_metaArray_io_r_resp_data_4_0_valid),
    .i_metaValid_5(_metaArray_io_r_resp_data_5_0_valid),
    .i_metaValid_6(_metaArray_io_r_resp_data_6_0_valid),
    .i_metaValid_7(_metaArray_io_r_resp_data_7_0_valid),
    .i_metaValid_8(_metaArray_io_r_resp_data_8_0_valid),
    .i_metaValid_9(_metaArray_io_r_resp_data_9_0_valid),
    .i_lfsr_0(_lfsr_prng_io_out_0),
    .i_lfsr_1(_lfsr_prng_io_out_1),
    .i_lfsr_2(_lfsr_prng_io_out_2),
    .i_lfsr_3(_lfsr_prng_io_out_3),
    .i_lfsr_4(_lfsr_prng_io_out_4),
    .i_lfsr_5(_lfsr_prng_io_out_5),
    .i_lfsr_6(_lfsr_prng_io_out_6),
    .o_ren(o_ren),
    .o_tagWaymask(o_tagWaymask),
    .o_metaWen(o_metaWen),
    .o_metaWset(o_metaWset),
    .o_metaWdata(o_metaWdata),
    .o_metaWaymask(o_metaWaymask)
  );

  SRAMTemplate_197 tagArray (
    .clock                 (clock),
    .io_r_req_ready        (/* unused */),
    .io_r_req_valid        (o_ren),
    .io_r_req_bits_setIdx  (io_read_bits_set),
    .io_r_resp_data_0      (_tagArray_io_r_resp_data_0),
    .io_r_resp_data_1      (_tagArray_io_r_resp_data_1),
    .io_r_resp_data_2      (_tagArray_io_r_resp_data_2),
    .io_r_resp_data_3      (_tagArray_io_r_resp_data_3),
    .io_r_resp_data_4      (_tagArray_io_r_resp_data_4),
    .io_r_resp_data_5      (_tagArray_io_r_resp_data_5),
    .io_r_resp_data_6      (_tagArray_io_r_resp_data_6),
    .io_r_resp_data_7      (_tagArray_io_r_resp_data_7),
    .io_r_resp_data_8      (_tagArray_io_r_resp_data_8),
    .io_r_resp_data_9      (_tagArray_io_r_resp_data_9),
    .io_w_req_ready        (/* unused */),
    .io_w_req_valid        (io_tagWReq_valid),
    .io_w_req_bits_setIdx  (io_tagWReq_bits_set),
    .io_w_req_bits_data_0  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_1  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_2  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_3  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_4  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_5  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_6  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_7  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_8  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_9  (io_tagWReq_bits_wtag),
    .io_w_req_bits_waymask (o_tagWaymask)
  );
  SRAMTemplate_193 metaArray (
    .clock                        (clock),
    .io_r_req_ready               (/* unused */),
    .io_r_req_valid               (o_ren),
    .io_r_req_bits_setIdx         (io_read_bits_set),
    .io_r_resp_data_0_0_valid     (_metaArray_io_r_resp_data_0_0_valid),
    .io_r_resp_data_1_0_valid     (_metaArray_io_r_resp_data_1_0_valid),
    .io_r_resp_data_2_0_valid     (_metaArray_io_r_resp_data_2_0_valid),
    .io_r_resp_data_3_0_valid     (_metaArray_io_r_resp_data_3_0_valid),
    .io_r_resp_data_4_0_valid     (_metaArray_io_r_resp_data_4_0_valid),
    .io_r_resp_data_5_0_valid     (_metaArray_io_r_resp_data_5_0_valid),
    .io_r_resp_data_6_0_valid     (_metaArray_io_r_resp_data_6_0_valid),
    .io_r_resp_data_7_0_valid     (_metaArray_io_r_resp_data_7_0_valid),
    .io_r_resp_data_8_0_valid     (_metaArray_io_r_resp_data_8_0_valid),
    .io_r_resp_data_9_0_valid     (_metaArray_io_r_resp_data_9_0_valid),
    .io_w_req_ready               (/* unused */),
    .io_w_req_valid               (o_metaWen),
    .io_w_req_bits_setIdx         (o_metaWset),
    .io_w_req_bits_data_0_0_valid (o_metaWdata),
    .io_w_req_bits_data_1_0_valid (o_metaWdata),
    .io_w_req_bits_data_2_0_valid (o_metaWdata),
    .io_w_req_bits_data_3_0_valid (o_metaWdata),
    .io_w_req_bits_data_4_0_valid (o_metaWdata),
    .io_w_req_bits_data_5_0_valid (o_metaWdata),
    .io_w_req_bits_data_6_0_valid (o_metaWdata),
    .io_w_req_bits_data_7_0_valid (o_metaWdata),
    .io_w_req_bits_data_8_0_valid (o_metaWdata),
    .io_w_req_bits_data_9_0_valid (o_metaWdata),
    .io_w_req_bits_waymask        (o_metaWaymask)
  );
  MaxPeriodFibonacciLFSR_3 lfsr_prng (
    .clock     (clock),
    .reset     (reset),
    .io_out_0  (_lfsr_prng_io_out_0),
    .io_out_1  (_lfsr_prng_io_out_1),
    .io_out_2  (_lfsr_prng_io_out_2),
    .io_out_3  (_lfsr_prng_io_out_3),
    .io_out_4  (_lfsr_prng_io_out_4),
    .io_out_5  (_lfsr_prng_io_out_5),
    .io_out_6  (_lfsr_prng_io_out_6),
    .io_out_7  (/* unused */),
    .io_out_8  (/* unused */),
    .io_out_9  (/* unused */),
    .io_out_10 (/* unused */),
    .io_out_11 (/* unused */),
    .io_out_12 (/* unused */),
    .io_out_13 (/* unused */),
    .io_out_14 (/* unused */),
    .io_out_15 (/* unused */)
  );
endmodule
