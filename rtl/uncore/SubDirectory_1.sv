// =============================================================================
//  subdirectory1_pkg —— openLLC 目录子块 SubDirectory_1(selfDir 实例)参数/类型
// -----------------------------------------------------------------------------
//  对照 Scala openLLC/src/main/scala/openLLC/Directory.scala 的 selfDir:
//    SubDirectory[SelfMetaEntry], replacement = cacheParams.replacement = "plru"
//  firtool 单态化 golden/chisel-rtl/SubDirectory_1.sv:
//    sets=4096(setBits=12), ways=16(wayBits=4), tagBits=28,
//    meta = SelfMetaEntry{valid, dirty}  →  每路 2 位
//    replacement = "plru"  →  15 位二叉树状态(replacer_sram), 含命中/refill 时更新
//
//  三级流水(同 SubDirectory):
//    stage1: io.read.fire, 发起 Tag/Meta/Replacer SRAM 读
//    stage2: SRAM 数据回来, 锁存 tagAll_s3/metaAll_s3/repl_state_s3 (reqValid_s2 门控)
//    stage3: 算 hit/way, PLRU 选替换路, 命中/refill 时回写 replacer_sram
//
//  3 个黑盒子模块(在 wrapper 内例化):
//    SRAMTemplate_194  tagArray            (16 路 × 28bit × 4096 set, 单口)
//    SRAMTemplate_195  metaArray           (16 路 × {valid,dirty} × 4096 set, 单口)
//    SRAMTemplate_196  replacer_sram_opt   (1 × 15bit × 4096 set, 单口, shouldReset)
// =============================================================================
package subdirectory1_pkg;

  localparam int WAYS     = 16;
  localparam int WAY_BITS = 4;
  localparam int SETS     = 4096;
  localparam int SET_BITS = 12;
  localparam int TAG_BITS = 28;
  localparam int PLRU_BITS = 15;   // 16 路二叉 PLRU = 15 个节点

  // SelfMetaEntry: valid + dirty。字段顺序与下游 io_resp_bits_meta_* 一致。
  typedef struct packed {
    logic valid;
    logic dirty;
  } self_meta_entry_t;

  // CHI 命中时更新 PLRU 的 opcode(只读独占/读非脏共享)
  localparam logic [6:0] OPC_READ_UNIQUE          = 7'h07;
  localparam logic [6:0] OPC_READ_NOT_SHARED_DIRTY = 7'h26;

endpackage

// =============================================================================
//  xs_SubDirectory_1_core —— openLLC SubDirectory_1(selfDir 实例)可读重写核
// -----------------------------------------------------------------------------
//  对照 Scala openLLC/.../Directory.scala 的 class SubDirectory(plru 实例化),
//  以及 firtool 产物 golden/chisel-rtl/SubDirectory_1.sv。
//
//  本核做三级流水的控制/选路 + PLRU 替换逻辑; tagArray/metaArray/replacer_sram
//  三块 SRAM 作为黑盒由外层 SubDirectory_1(wrapper) 例化, 经 i_*/o_* 与本核对接:
//    i_tagRead_*  : tagArray  读出 16 路 tag
//    i_metaValid_*/i_metaDirty_* : metaArray 读出 16 路 {valid,dirty}
//    i_replState  : replacer_sram 读出 15 位 PLRU 树状态
//    o_ren        : 三块 SRAM 共用读使能 (= io.read.fire)
//    o_metaW*     : metaArray 写控制 (复位写 init=0 全路; 复位后写 io_metaWReq)
//    o_replW*     : replacer_sram 写控制 (复位写 0; 命中/refill 时回写 PLRU 新状态)
//  (tagArray 写 waymask 仅依赖外部端口 io_tagWReq_bits_way, 留在 wrapper 内联)
//
//  寄存器命名与 golden 一致(resetFinish/resetIdx/reqValid_s2/req_s2_*/reqValid_s3/
//  req_s3_*/metaAll_s3_*/tagAll_s3_*/repl_state_s3) 以利 Formality 配对。
// =============================================================================
`timescale 1ns/1ps


module xs_SubDirectory_1_core
  import subdirectory1_pkg::*;
(
  input               clock,
  input               reset,

  // ---- io.read ----
  output              io_read_ready,
  input               io_read_valid,
  input  [27:0]       io_read_bits_tag,
  input  [11:0]       io_read_bits_set,
  input  [6:0]        io_read_bits_replacerInfo_opcode,
  input               io_read_bits_replacerInfo_refill,

  // ---- io.resp (stage3) ----
  output              io_resp_valid,
  output              io_resp_bits_hit,
  output [27:0]       io_resp_bits_tag,
  output [11:0]       io_resp_bits_set,
  output [3:0]        io_resp_bits_way,
  output              io_resp_bits_meta_valid,
  output              io_resp_bits_meta_dirty,
  output              io_resp_bits_error,

  // ---- io.tagWReq ----
  input               io_tagWReq_valid,
  input  [11:0]       io_tagWReq_bits_set,
  input  [3:0]        io_tagWReq_bits_way,
  input  [27:0]       io_tagWReq_bits_wtag,

  // ---- io.metaWReq ----
  input               io_metaWReq_valid,
  input  [11:0]       io_metaWReq_bits_set,
  input  [15:0]       io_metaWReq_bits_wayOH,
  input               io_metaWReq_bits_wmeta_valid,
  input               io_metaWReq_bits_wmeta_dirty,

  // ---- SRAM 读数据 (16 路) ----
  input  [27:0] i_tagRead_0,  input [27:0] i_tagRead_1,  input [27:0] i_tagRead_2,
  input  [27:0] i_tagRead_3,  input [27:0] i_tagRead_4,  input [27:0] i_tagRead_5,
  input  [27:0] i_tagRead_6,  input [27:0] i_tagRead_7,  input [27:0] i_tagRead_8,
  input  [27:0] i_tagRead_9,  input [27:0] i_tagRead_10, input [27:0] i_tagRead_11,
  input  [27:0] i_tagRead_12, input [27:0] i_tagRead_13, input [27:0] i_tagRead_14,
  input  [27:0] i_tagRead_15,
  input  i_metaValid_0,  input i_metaValid_1,  input i_metaValid_2,  input i_metaValid_3,
  input  i_metaValid_4,  input i_metaValid_5,  input i_metaValid_6,  input i_metaValid_7,
  input  i_metaValid_8,  input i_metaValid_9,  input i_metaValid_10, input i_metaValid_11,
  input  i_metaValid_12, input i_metaValid_13, input i_metaValid_14, input i_metaValid_15,
  input  i_metaDirty_0,  input i_metaDirty_1,  input i_metaDirty_2,  input i_metaDirty_3,
  input  i_metaDirty_4,  input i_metaDirty_5,  input i_metaDirty_6,  input i_metaDirty_7,
  input  i_metaDirty_8,  input i_metaDirty_9,  input i_metaDirty_10, input i_metaDirty_11,
  input  i_metaDirty_12, input i_metaDirty_13, input i_metaDirty_14, input i_metaDirty_15,
  input  [14:0] i_replState,

  // ---- 控制 SRAM 黑盒 ----
  output              o_ren,
  output              o_metaWen,
  output [11:0]       o_metaWset,
  output              o_metaWvalid,
  output              o_metaWdirty,
  output [15:0]       o_metaWaymask,
  output              o_replWen,
  output [11:0]       o_replWset,
  output [14:0]       o_replWdata
);

  // ---------------------------------------------------------------------------
  // 复位扫写
  // ---------------------------------------------------------------------------
  reg               resetFinish;
  reg  [11:0]       resetIdx;

  // 流水寄存器 (命名同 golden)
  reg               reqValid_s2;
  reg  [27:0]       req_s2_tag;
  reg  [11:0]       req_s2_set;
  reg  [6:0]        req_s2_replacerInfo_opcode;
  reg               req_s2_replacerInfo_refill;

  reg               reqValid_s3;
  reg  [27:0]       req_s3_tag;
  reg  [11:0]       req_s3_set;
  reg  [6:0]        req_s3_replacerInfo_opcode;
  reg               req_s3_replacerInfo_refill;

  self_meta_entry_t metaAll_s3 [WAYS];   // 16 路 {valid,dirty}
  reg  [27:0]       tagAll_s3  [WAYS];   // 16 路 tag
  reg  [14:0]       repl_state_s3;       // PLRU 树状态

  // 把扁平 SRAM 读口聚成数组
  wire        metaRdValid [WAYS];
  wire        metaRdDirty [WAYS];
  wire [27:0] tagRd       [WAYS];
  assign metaRdValid[0]=i_metaValid_0;  assign metaRdValid[1]=i_metaValid_1;
  assign metaRdValid[2]=i_metaValid_2;  assign metaRdValid[3]=i_metaValid_3;
  assign metaRdValid[4]=i_metaValid_4;  assign metaRdValid[5]=i_metaValid_5;
  assign metaRdValid[6]=i_metaValid_6;  assign metaRdValid[7]=i_metaValid_7;
  assign metaRdValid[8]=i_metaValid_8;  assign metaRdValid[9]=i_metaValid_9;
  assign metaRdValid[10]=i_metaValid_10; assign metaRdValid[11]=i_metaValid_11;
  assign metaRdValid[12]=i_metaValid_12; assign metaRdValid[13]=i_metaValid_13;
  assign metaRdValid[14]=i_metaValid_14; assign metaRdValid[15]=i_metaValid_15;
  assign metaRdDirty[0]=i_metaDirty_0;  assign metaRdDirty[1]=i_metaDirty_1;
  assign metaRdDirty[2]=i_metaDirty_2;  assign metaRdDirty[3]=i_metaDirty_3;
  assign metaRdDirty[4]=i_metaDirty_4;  assign metaRdDirty[5]=i_metaDirty_5;
  assign metaRdDirty[6]=i_metaDirty_6;  assign metaRdDirty[7]=i_metaDirty_7;
  assign metaRdDirty[8]=i_metaDirty_8;  assign metaRdDirty[9]=i_metaDirty_9;
  assign metaRdDirty[10]=i_metaDirty_10; assign metaRdDirty[11]=i_metaDirty_11;
  assign metaRdDirty[12]=i_metaDirty_12; assign metaRdDirty[13]=i_metaDirty_13;
  assign metaRdDirty[14]=i_metaDirty_14; assign metaRdDirty[15]=i_metaDirty_15;
  assign tagRd[0]=i_tagRead_0;  assign tagRd[1]=i_tagRead_1;  assign tagRd[2]=i_tagRead_2;
  assign tagRd[3]=i_tagRead_3;  assign tagRd[4]=i_tagRead_4;  assign tagRd[5]=i_tagRead_5;
  assign tagRd[6]=i_tagRead_6;  assign tagRd[7]=i_tagRead_7;  assign tagRd[8]=i_tagRead_8;
  assign tagRd[9]=i_tagRead_9;  assign tagRd[10]=i_tagRead_10; assign tagRd[11]=i_tagRead_11;
  assign tagRd[12]=i_tagRead_12; assign tagRd[13]=i_tagRead_13; assign tagRd[14]=i_tagRead_14;
  assign tagRd[15]=i_tagRead_15;

  // ---------------------------------------------------------------------------
  // io.read.ready / read.fire —— 含 replacerWen 反压(plru 写 replacer 时不接读)
  // ---------------------------------------------------------------------------
  wire replacerWen;
  wire io_read_ready_int =
       ~io_metaWReq_valid & ~io_tagWReq_valid & ~replacerWen & resetFinish;
  wire read_fire = io_read_ready_int & io_read_valid;

  integer rstk;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      resetFinish <= 1'b0;
      resetIdx    <= 12'hFFF;          // SETS-1
      reqValid_s2 <= 1'b0;
      req_s2_tag  <= 28'h0;
      req_s2_set  <= 12'h0;
      req_s2_replacerInfo_opcode <= 7'h0;
      req_s2_replacerInfo_refill <= 1'b0;
      reqValid_s3 <= 1'b0;
      req_s3_tag  <= 28'h0;
      req_s3_set  <= 12'h0;
      req_s3_replacerInfo_opcode <= 7'h0;
      req_s3_replacerInfo_refill <= 1'b0;
      for (rstk = 0; rstk < WAYS; rstk = rstk + 1) begin
        metaAll_s3[rstk] <= '0;
        tagAll_s3[rstk]  <= 28'h0;
      end
      repl_state_s3 <= 15'h0;
    end
    else begin
      resetFinish <= (resetIdx == 12'h0) | resetFinish;
      if (!resetFinish)
        resetIdx <= resetIdx - 12'h1;

      // s2: 锁存读请求(含 replacerInfo)
      reqValid_s2 <= read_fire;
      if (read_fire) begin
        req_s2_tag <= io_read_bits_tag;
        req_s2_set <= io_read_bits_set;
        req_s2_replacerInfo_opcode <= io_read_bits_replacerInfo_opcode;
        req_s2_replacerInfo_refill <= io_read_bits_replacerInfo_refill;
      end

      // s3: 锁存 SRAM 读出 + 透传 s2 请求 + 锁存 PLRU 状态
      reqValid_s3 <= reqValid_s2;
      if (reqValid_s2) begin
        req_s3_tag <= req_s2_tag;
        req_s3_set <= req_s2_set;
        req_s3_replacerInfo_opcode <= req_s2_replacerInfo_opcode;
        req_s3_replacerInfo_refill <= req_s2_replacerInfo_refill;
        for (rstk = 0; rstk < WAYS; rstk = rstk + 1) begin
          metaAll_s3[rstk].valid <= metaRdValid[rstk];
          metaAll_s3[rstk].dirty <= metaRdDirty[rstk];
          tagAll_s3[rstk]        <= tagRd[rstk];
        end
        repl_state_s3 <= i_replState;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 选路逻辑 (stage3)
  // ---------------------------------------------------------------------------
  wire [WAYS-1:0] hitVec;
  wire [WAYS-1:0] invalidVec;
  genvar w;
  generate
    for (w = 0; w < WAYS; w = w + 1) begin : g_hit
      assign hitVec[w]     = (tagAll_s3[w] == req_s3_tag) & metaAll_s3[w].valid;
      assign invalidVec[w] = ~metaAll_s3[w].valid;
    end
  endgenerate

  wire hit_s3 = |hitVec;

  // hitWay = OHToUInt(hitVec): one-hot → 二进制下标
  wire [3:0] hitWay;
  assign hitWay[0] = hitVec[1]|hitVec[3]|hitVec[5]|hitVec[7]
                   | hitVec[9]|hitVec[11]|hitVec[13]|hitVec[15];
  assign hitWay[1] = hitVec[2]|hitVec[3]|hitVec[6]|hitVec[7]
                   | hitVec[10]|hitVec[11]|hitVec[14]|hitVec[15];
  assign hitWay[2] = hitVec[4]|hitVec[5]|hitVec[6]|hitVec[7]
                   | hitVec[12]|hitVec[13]|hitVec[14]|hitVec[15];
  assign hitWay[3] = hitVec[8]|hitVec[9]|hitVec[10]|hitVec[11]
                   | hitVec[12]|hitVec[13]|hitVec[14]|hitVec[15];

  // invalid_way_sel: 取下标最小的空路
  wire hasInvalid = |invalidVec;
  reg  [3:0] invalidWay;
  integer ik;
  always @* begin
    invalidWay = 4'd0;
    for (ik = WAYS-1; ik >= 0; ik = ik - 1)
      if (invalidVec[ik]) invalidWay = ik[3:0];
  end

  // PLRU 替换路: 从根节点(repl_state_s3[14])按各节点位逐级下降到 LRU 叶子
  wire [3:0] replaceWay;
  assign replaceWay =
    {repl_state_s3[14],
     repl_state_s3[14]
       ? {repl_state_s3[13],
          repl_state_s3[13]
            ? {repl_state_s3[12],
               repl_state_s3[12] ? repl_state_s3[11] : repl_state_s3[10]}
            : {repl_state_s3[9],  repl_state_s3[9]  ? repl_state_s3[8]  : repl_state_s3[7]}}
       : {repl_state_s3[6],
          repl_state_s3[6]
            ? {repl_state_s3[5], repl_state_s3[5] ? repl_state_s3[4] : repl_state_s3[3]}
            : {repl_state_s3[2], repl_state_s3[2] ? repl_state_s3[1] : repl_state_s3[0]}}};

  wire [3:0] chosenWay = hasInvalid ? invalidWay : replaceWay;
  wire [3:0] way_s3    = hit_s3 ? hitWay : chosenWay;

  // 按 way_s3 选出 tag / meta (16 路, way_s3 ∈ [0,15])
  reg  [27:0] sel_tag;
  reg         sel_meta_valid;
  reg         sel_meta_dirty;
  always @* begin
    sel_tag        = tagAll_s3[way_s3];
    sel_meta_valid = metaAll_s3[way_s3].valid;
    sel_meta_dirty = metaAll_s3[way_s3].dirty;
  end

  // ---------------------------------------------------------------------------
  // PLRU 更新触发: stage3 命中且为 ReadUnique/ReadNotSharedDirty, 或 refill
  // ---------------------------------------------------------------------------
  assign replacerWen =
       reqValid_s3 & hit_s3
       & (req_s3_replacerInfo_opcode == OPC_READ_UNIQUE
          | req_s3_replacerInfo_opcode == OPC_READ_NOT_SHARED_DIRTY)
     | reqValid_s3 & req_s3_replacerInfo_refill;

  // PLRU get_next_state(repl_state_s3, way_s3): 把 way_s3 路径上各节点翻向"非该路",
  // 使其成为 MRU; 复位期写 0。结构与 golden 逐位一致。
  wire [14:0] replNext =
    {~(way_s3[3]),
     way_s3[3]
       ? {~(way_s3[2]),
          way_s3[2]
            ? {~(way_s3[1]),
               way_s3[1] ? ~(way_s3[0]) : repl_state_s3[11],
               way_s3[1] ? repl_state_s3[10] : ~(way_s3[0])}
            : repl_state_s3[12:10],
          way_s3[2]
            ? repl_state_s3[9:7]
            : {~(way_s3[1]),
               way_s3[1] ? ~(way_s3[0]) : repl_state_s3[8],
               way_s3[1] ? repl_state_s3[7] : ~(way_s3[0])}}
       : repl_state_s3[13:7],
     way_s3[3]
       ? repl_state_s3[6:0]
       : {~(way_s3[2]),
          way_s3[2]
            ? {~(way_s3[1]),
               way_s3[1] ? ~(way_s3[0]) : repl_state_s3[4],
               way_s3[1] ? repl_state_s3[3] : ~(way_s3[0])}
            : repl_state_s3[5:3],
          way_s3[2]
            ? repl_state_s3[2:0]
            : {~(way_s3[1]),
               way_s3[1] ? ~(way_s3[0]) : repl_state_s3[1],
               way_s3[1] ? repl_state_s3[0] : ~(way_s3[0])}}};

  // ---------------------------------------------------------------------------
  // 输出
  // ---------------------------------------------------------------------------
  assign io_read_ready           = io_read_ready_int;
  assign io_resp_valid           = reqValid_s3;
  assign io_resp_bits_hit        = hit_s3;
  assign io_resp_bits_tag        = sel_tag;
  assign io_resp_bits_set        = req_s3_set;
  assign io_resp_bits_way        = way_s3;
  assign io_resp_bits_meta_valid = sel_meta_valid;
  assign io_resp_bits_meta_dirty = sel_meta_dirty;
  assign io_resp_bits_error      = 1'b0;

  // ---- metaArray 写控制 ----
  assign o_ren         = read_fire;
  assign o_metaWen     = io_metaWReq_valid | ~resetFinish;
  assign o_metaWset    = resetFinish ? io_metaWReq_bits_set : resetIdx;
  assign o_metaWvalid  = resetFinish & io_metaWReq_bits_wmeta_valid;
  assign o_metaWdirty  = resetFinish & io_metaWReq_bits_wmeta_dirty;
  assign o_metaWaymask = resetFinish ? io_metaWReq_bits_wayOH : 16'hFFFF;

  // ---- replacer_sram 写控制 ----
  assign o_replWen     = ~resetFinish | replacerWen;
  assign o_replWset    = resetFinish ? req_s3_set : resetIdx;
  assign o_replWdata   = resetFinish ? replNext : 15'h0;

endmodule

// 自动生成 scripts/gen_subdirectory1.py —— 勿手改

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module SubDirectory_1(
  input clock,
  input reset,
  output io_read_ready,
  input io_read_valid,
  input [27:0] io_read_bits_tag,
  input [11:0] io_read_bits_set,
  input [6:0] io_read_bits_replacerInfo_opcode,
  input io_read_bits_replacerInfo_refill,
  output io_resp_valid,
  output io_resp_bits_hit,
  output [27:0] io_resp_bits_tag,
  output [11:0] io_resp_bits_set,
  output [3:0] io_resp_bits_way,
  output io_resp_bits_meta_valid,
  output io_resp_bits_meta_dirty,
  output io_resp_bits_error,
  input io_tagWReq_valid,
  input [11:0] io_tagWReq_bits_set,
  input [3:0] io_tagWReq_bits_way,
  input [27:0] io_tagWReq_bits_wtag,
  input io_metaWReq_valid,
  input [11:0] io_metaWReq_bits_set,
  input [15:0] io_metaWReq_bits_wayOH,
  input io_metaWReq_bits_wmeta_valid,
  input io_metaWReq_bits_wmeta_dirty
);

  wire [14:0]       _replacer_sram_opt_io_r_resp_data_0;
  wire              _metaArray_io_r_resp_data_0_valid;
  wire              _metaArray_io_r_resp_data_0_dirty;
  wire              _metaArray_io_r_resp_data_1_valid;
  wire              _metaArray_io_r_resp_data_1_dirty;
  wire              _metaArray_io_r_resp_data_2_valid;
  wire              _metaArray_io_r_resp_data_2_dirty;
  wire              _metaArray_io_r_resp_data_3_valid;
  wire              _metaArray_io_r_resp_data_3_dirty;
  wire              _metaArray_io_r_resp_data_4_valid;
  wire              _metaArray_io_r_resp_data_4_dirty;
  wire              _metaArray_io_r_resp_data_5_valid;
  wire              _metaArray_io_r_resp_data_5_dirty;
  wire              _metaArray_io_r_resp_data_6_valid;
  wire              _metaArray_io_r_resp_data_6_dirty;
  wire              _metaArray_io_r_resp_data_7_valid;
  wire              _metaArray_io_r_resp_data_7_dirty;
  wire              _metaArray_io_r_resp_data_8_valid;
  wire              _metaArray_io_r_resp_data_8_dirty;
  wire              _metaArray_io_r_resp_data_9_valid;
  wire              _metaArray_io_r_resp_data_9_dirty;
  wire              _metaArray_io_r_resp_data_10_valid;
  wire              _metaArray_io_r_resp_data_10_dirty;
  wire              _metaArray_io_r_resp_data_11_valid;
  wire              _metaArray_io_r_resp_data_11_dirty;
  wire              _metaArray_io_r_resp_data_12_valid;
  wire              _metaArray_io_r_resp_data_12_dirty;
  wire              _metaArray_io_r_resp_data_13_valid;
  wire              _metaArray_io_r_resp_data_13_dirty;
  wire              _metaArray_io_r_resp_data_14_valid;
  wire              _metaArray_io_r_resp_data_14_dirty;
  wire              _metaArray_io_r_resp_data_15_valid;
  wire              _metaArray_io_r_resp_data_15_dirty;
  wire [27:0]       _tagArray_io_r_resp_data_0;
  wire [27:0]       _tagArray_io_r_resp_data_1;
  wire [27:0]       _tagArray_io_r_resp_data_2;
  wire [27:0]       _tagArray_io_r_resp_data_3;
  wire [27:0]       _tagArray_io_r_resp_data_4;
  wire [27:0]       _tagArray_io_r_resp_data_5;
  wire [27:0]       _tagArray_io_r_resp_data_6;
  wire [27:0]       _tagArray_io_r_resp_data_7;
  wire [27:0]       _tagArray_io_r_resp_data_8;
  wire [27:0]       _tagArray_io_r_resp_data_9;
  wire [27:0]       _tagArray_io_r_resp_data_10;
  wire [27:0]       _tagArray_io_r_resp_data_11;
  wire [27:0]       _tagArray_io_r_resp_data_12;
  wire [27:0]       _tagArray_io_r_resp_data_13;
  wire [27:0]       _tagArray_io_r_resp_data_14;
  wire [27:0]       _tagArray_io_r_resp_data_15;

  // ---- 核与 SRAM 黑盒的边界 wire (核的 o_* 输出) ----
  wire        o_ren;
  wire        o_metaWen;
  wire [11:0] o_metaWset;
  wire        o_metaWvalid;
  wire        o_metaWdirty;
  wire [15:0] o_metaWaymask;
  wire        o_replWen;
  wire [11:0] o_replWset;
  wire [14:0] o_replWdata;

  xs_SubDirectory_1_core u_core (
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
    .io_resp_bits_meta_valid(io_resp_bits_meta_valid),
    .io_resp_bits_meta_dirty(io_resp_bits_meta_dirty),
    .io_resp_bits_error(io_resp_bits_error),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_valid(io_metaWReq_bits_wmeta_valid),
    .io_metaWReq_bits_wmeta_dirty(io_metaWReq_bits_wmeta_dirty),
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
    .i_tagRead_10(_tagArray_io_r_resp_data_10),
    .i_tagRead_11(_tagArray_io_r_resp_data_11),
    .i_tagRead_12(_tagArray_io_r_resp_data_12),
    .i_tagRead_13(_tagArray_io_r_resp_data_13),
    .i_tagRead_14(_tagArray_io_r_resp_data_14),
    .i_tagRead_15(_tagArray_io_r_resp_data_15),
    .i_metaValid_0(_metaArray_io_r_resp_data_0_valid),
    .i_metaValid_1(_metaArray_io_r_resp_data_1_valid),
    .i_metaValid_2(_metaArray_io_r_resp_data_2_valid),
    .i_metaValid_3(_metaArray_io_r_resp_data_3_valid),
    .i_metaValid_4(_metaArray_io_r_resp_data_4_valid),
    .i_metaValid_5(_metaArray_io_r_resp_data_5_valid),
    .i_metaValid_6(_metaArray_io_r_resp_data_6_valid),
    .i_metaValid_7(_metaArray_io_r_resp_data_7_valid),
    .i_metaValid_8(_metaArray_io_r_resp_data_8_valid),
    .i_metaValid_9(_metaArray_io_r_resp_data_9_valid),
    .i_metaValid_10(_metaArray_io_r_resp_data_10_valid),
    .i_metaValid_11(_metaArray_io_r_resp_data_11_valid),
    .i_metaValid_12(_metaArray_io_r_resp_data_12_valid),
    .i_metaValid_13(_metaArray_io_r_resp_data_13_valid),
    .i_metaValid_14(_metaArray_io_r_resp_data_14_valid),
    .i_metaValid_15(_metaArray_io_r_resp_data_15_valid),
    .i_metaDirty_0(_metaArray_io_r_resp_data_0_dirty),
    .i_metaDirty_1(_metaArray_io_r_resp_data_1_dirty),
    .i_metaDirty_2(_metaArray_io_r_resp_data_2_dirty),
    .i_metaDirty_3(_metaArray_io_r_resp_data_3_dirty),
    .i_metaDirty_4(_metaArray_io_r_resp_data_4_dirty),
    .i_metaDirty_5(_metaArray_io_r_resp_data_5_dirty),
    .i_metaDirty_6(_metaArray_io_r_resp_data_6_dirty),
    .i_metaDirty_7(_metaArray_io_r_resp_data_7_dirty),
    .i_metaDirty_8(_metaArray_io_r_resp_data_8_dirty),
    .i_metaDirty_9(_metaArray_io_r_resp_data_9_dirty),
    .i_metaDirty_10(_metaArray_io_r_resp_data_10_dirty),
    .i_metaDirty_11(_metaArray_io_r_resp_data_11_dirty),
    .i_metaDirty_12(_metaArray_io_r_resp_data_12_dirty),
    .i_metaDirty_13(_metaArray_io_r_resp_data_13_dirty),
    .i_metaDirty_14(_metaArray_io_r_resp_data_14_dirty),
    .i_metaDirty_15(_metaArray_io_r_resp_data_15_dirty),
    .i_replState(_replacer_sram_opt_io_r_resp_data_0),
    .o_ren(o_ren),
    .o_metaWen(o_metaWen),
    .o_metaWset(o_metaWset),
    .o_metaWvalid(o_metaWvalid),
    .o_metaWdirty(o_metaWdirty),
    .o_metaWaymask(o_metaWaymask),
    .o_replWen(o_replWen),
    .o_replWset(o_replWset),
    .o_replWdata(o_replWdata)
  );

  SRAMTemplate_194 tagArray (
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
    .io_r_resp_data_10     (_tagArray_io_r_resp_data_10),
    .io_r_resp_data_11     (_tagArray_io_r_resp_data_11),
    .io_r_resp_data_12     (_tagArray_io_r_resp_data_12),
    .io_r_resp_data_13     (_tagArray_io_r_resp_data_13),
    .io_r_resp_data_14     (_tagArray_io_r_resp_data_14),
    .io_r_resp_data_15     (_tagArray_io_r_resp_data_15),
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
    .io_w_req_bits_data_10 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_11 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_12 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_13 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_14 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_15 (io_tagWReq_bits_wtag),
    .io_w_req_bits_waymask (16'h1 << io_tagWReq_bits_way)
  );
  SRAMTemplate_195 metaArray (
    .clock                       (clock),
    .io_r_req_ready              (/* unused */),
    .io_r_req_valid              (o_ren),
    .io_r_req_bits_setIdx        (io_read_bits_set),
    .io_r_resp_data_0_valid      (_metaArray_io_r_resp_data_0_valid),
    .io_r_resp_data_0_dirty      (_metaArray_io_r_resp_data_0_dirty),
    .io_r_resp_data_1_valid      (_metaArray_io_r_resp_data_1_valid),
    .io_r_resp_data_1_dirty      (_metaArray_io_r_resp_data_1_dirty),
    .io_r_resp_data_2_valid      (_metaArray_io_r_resp_data_2_valid),
    .io_r_resp_data_2_dirty      (_metaArray_io_r_resp_data_2_dirty),
    .io_r_resp_data_3_valid      (_metaArray_io_r_resp_data_3_valid),
    .io_r_resp_data_3_dirty      (_metaArray_io_r_resp_data_3_dirty),
    .io_r_resp_data_4_valid      (_metaArray_io_r_resp_data_4_valid),
    .io_r_resp_data_4_dirty      (_metaArray_io_r_resp_data_4_dirty),
    .io_r_resp_data_5_valid      (_metaArray_io_r_resp_data_5_valid),
    .io_r_resp_data_5_dirty      (_metaArray_io_r_resp_data_5_dirty),
    .io_r_resp_data_6_valid      (_metaArray_io_r_resp_data_6_valid),
    .io_r_resp_data_6_dirty      (_metaArray_io_r_resp_data_6_dirty),
    .io_r_resp_data_7_valid      (_metaArray_io_r_resp_data_7_valid),
    .io_r_resp_data_7_dirty      (_metaArray_io_r_resp_data_7_dirty),
    .io_r_resp_data_8_valid      (_metaArray_io_r_resp_data_8_valid),
    .io_r_resp_data_8_dirty      (_metaArray_io_r_resp_data_8_dirty),
    .io_r_resp_data_9_valid      (_metaArray_io_r_resp_data_9_valid),
    .io_r_resp_data_9_dirty      (_metaArray_io_r_resp_data_9_dirty),
    .io_r_resp_data_10_valid     (_metaArray_io_r_resp_data_10_valid),
    .io_r_resp_data_10_dirty     (_metaArray_io_r_resp_data_10_dirty),
    .io_r_resp_data_11_valid     (_metaArray_io_r_resp_data_11_valid),
    .io_r_resp_data_11_dirty     (_metaArray_io_r_resp_data_11_dirty),
    .io_r_resp_data_12_valid     (_metaArray_io_r_resp_data_12_valid),
    .io_r_resp_data_12_dirty     (_metaArray_io_r_resp_data_12_dirty),
    .io_r_resp_data_13_valid     (_metaArray_io_r_resp_data_13_valid),
    .io_r_resp_data_13_dirty     (_metaArray_io_r_resp_data_13_dirty),
    .io_r_resp_data_14_valid     (_metaArray_io_r_resp_data_14_valid),
    .io_r_resp_data_14_dirty     (_metaArray_io_r_resp_data_14_dirty),
    .io_r_resp_data_15_valid     (_metaArray_io_r_resp_data_15_valid),
    .io_r_resp_data_15_dirty     (_metaArray_io_r_resp_data_15_dirty),
    .io_w_req_ready              (/* unused */),
    .io_w_req_valid              (o_metaWen),
    .io_w_req_bits_setIdx        (o_metaWset),
    .io_w_req_bits_data_0_valid  (o_metaWvalid),
    .io_w_req_bits_data_0_dirty  (o_metaWdirty),
    .io_w_req_bits_data_1_valid  (o_metaWvalid),
    .io_w_req_bits_data_1_dirty  (o_metaWdirty),
    .io_w_req_bits_data_2_valid  (o_metaWvalid),
    .io_w_req_bits_data_2_dirty  (o_metaWdirty),
    .io_w_req_bits_data_3_valid  (o_metaWvalid),
    .io_w_req_bits_data_3_dirty  (o_metaWdirty),
    .io_w_req_bits_data_4_valid  (o_metaWvalid),
    .io_w_req_bits_data_4_dirty  (o_metaWdirty),
    .io_w_req_bits_data_5_valid  (o_metaWvalid),
    .io_w_req_bits_data_5_dirty  (o_metaWdirty),
    .io_w_req_bits_data_6_valid  (o_metaWvalid),
    .io_w_req_bits_data_6_dirty  (o_metaWdirty),
    .io_w_req_bits_data_7_valid  (o_metaWvalid),
    .io_w_req_bits_data_7_dirty  (o_metaWdirty),
    .io_w_req_bits_data_8_valid  (o_metaWvalid),
    .io_w_req_bits_data_8_dirty  (o_metaWdirty),
    .io_w_req_bits_data_9_valid  (o_metaWvalid),
    .io_w_req_bits_data_9_dirty  (o_metaWdirty),
    .io_w_req_bits_data_10_valid (o_metaWvalid),
    .io_w_req_bits_data_10_dirty (o_metaWdirty),
    .io_w_req_bits_data_11_valid (o_metaWvalid),
    .io_w_req_bits_data_11_dirty (o_metaWdirty),
    .io_w_req_bits_data_12_valid (o_metaWvalid),
    .io_w_req_bits_data_12_dirty (o_metaWdirty),
    .io_w_req_bits_data_13_valid (o_metaWvalid),
    .io_w_req_bits_data_13_dirty (o_metaWdirty),
    .io_w_req_bits_data_14_valid (o_metaWvalid),
    .io_w_req_bits_data_14_dirty (o_metaWdirty),
    .io_w_req_bits_data_15_valid (o_metaWvalid),
    .io_w_req_bits_data_15_dirty (o_metaWdirty),
    .io_w_req_bits_waymask       (o_metaWaymask)
  );
  SRAMTemplate_196 replacer_sram_opt (
    .clock                (clock),
    .reset                (reset),
    .io_r_req_valid       (o_ren),
    .io_r_req_bits_setIdx (io_read_bits_set),
    .io_r_resp_data_0     (_replacer_sram_opt_io_r_resp_data_0),
    .io_w_req_valid       (o_replWen),
    .io_w_req_bits_setIdx (o_replWset),
    .io_w_req_bits_data_0 (o_replWdata)
  );
endmodule
