// =============================================================================
// compressunit_pkg —— 香山 V2R2(昆明湖) ROB 压缩单元 CompressUnit 的类型/常量
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.rename.CompressUnit。
//
// 【背景:为什么要"ROB 压缩"】
//   重命名阶段每拍最多吞 RenameWidth(=6) 条指令。某些**连续**且"可压缩"
//   (canRobCompress)的指令(典型是被 fusion 融合后的同类指令、或同一宏指令
//   拆出的微操作),可以共享**一个 ROB 表项**提交,从而扩大有效指令窗口
//   (思路见模块头引用的 CROB 论文)。本单元在重命名前算出"这 6 条里哪些能
//   压成一组、每组多大、组的最后一条是谁(谁占 ROB 表项)"。
//
// 【它输出什么(对每条 lane i ∈ 0..5)】
//   canCompressVec[i] : 该 lane 本身是否"可参与压缩"(有效、非 fusion、是末 uop、
//                       无异常/非调试触发、且 canRobCompress)。
//   needRobFlags[i]   : 该 lane 是否需要**独占一个 ROB 表项**。一个压缩组里只有
//                       "最后一条可压缩指令"置 1;组内其余置 0(并入末条的表项)。
//                       不可压缩指令各自置 1。
//   instrSizes[i]     : 包含该 lane 的压缩组大小(可压缩则=连续 1 的游程长度;
//                       不可压缩则=1)。
//   masks[i]          : 6 位 one-hot/多热,标出"和该 lane 同组"的所有 lane。
//                       不可压缩 lane:仅自身位为 1;可压缩 lane:整段游程为 1。
//
// 【数据流】canCompress(6bit) --查表/逐lane计算--> 上述四组输出。
//   Scala 用 DecodeLogic 把 2^6=64 种 key 预先算成真值表;这里直接用纯组合的
//   **逐 lane 游程统计**重建同一函数(更可读,且与查表等价)。
// =============================================================================
package compressunit_pkg;

  // 重命名宽度(每拍最多处理的指令数)。
  localparam int unsigned RENAME_WIDTH = 6;

  // 输出位宽。
  localparam int unsigned SIZE_W = $clog2(RENAME_WIDTH + 1); // 3:可表示 0..6
  localparam int unsigned MASK_W = RENAME_WIDTH;             // 6

  // 异常向量位数(ExceptionVec)。CompressUnit 只用其 "是否有任一异常"。
  localparam int unsigned EXC_W = 24;

  // TriggerAction.DebugMode 编码(4 位):进入调试模式的触发动作。
  localparam logic [3:0] TRIGGER_DEBUG_MODE = 4'd1;

  // CommitType.isFused(c) = c(2) —— 即 commitType 的 bit2 表示"该指令是 fusion
  // 融合产物"。被融合的指令不参与 ROB 压缩(它已经是合并结果)。

  // 单条 lane 的输入(聚合 golden 扁平端口为 struct)。
  typedef struct packed {
    logic                  valid;
    logic [EXC_W-1:0]      exceptionVec;
    logic [3:0]            trigger;
    logic                  canRobCompress;
    logic                  lastUop;
    logic [2:0]            commitType;
  } compress_in_t;

endpackage

// =============================================================================
// xs_CompressUnit_core —— 香山 V2R2(昆明湖) ROB 压缩单元核(可读重写)
// -----------------------------------------------------------------------------
// 对应 Scala 源:xiangshan.backend.rename.CompressUnit。纯组合叶子。
//
// 输入:每拍 RENAME_WIDTH(=6) 条候选指令的若干属性(见 compress_in_t)。
// 输出:canCompressVec / needRobFlags / instrSizes / masks(语义见 pkg 头注)。
//
// 【算法(直接来自 Scala 设计意图)】
//   1) 先算每条 lane 的"可压缩"位 canCompress[i]:
//        valid 且 非 fusion 且 是末 uop(lastUop) 且 无异常/非调试触发 且 canRobCompress。
//   2) 把 canCompress 当作 6 位 key,**两端各补一个 0** 成 8 位 padded key(下标 1..6
//      对应 lane 0..5,下标 0 与 7 是哨兵 0)。这样"游程"统计无需特判边界。
//   3) 对每条 lane i(padded 下标 1..6):
//        - cntL(i): 从 i 向左数连续 1 的个数(含自身),遇 0 停。
//        - cntR(i): 从 i 向右数连续 1 的个数(含自身),遇 0 停。
//        - needRob[i] = ~(key[i] & key[i+1]):若右邻也是 1 则本条并入右边(不需 ROB);
//                       否则本条是"组末"或"不可压缩",需独占 ROB 表项。
//        - size[i]   = key[i] ? cntL(i)+cntR(i)-1 : 1  (所在游程长度;不可压则 1)。
//        - mask[i]   = key[i] ? 游程区间[i-cntL+1 .. i+cntR-1] 全 1 : 仅自身位。
//   Scala 把这一函数对 2^6=64 种 key 预计算成 DecodeLogic 真值表;此处用逐 lane
//   的组合游程统计**等价重建**,可读且无需查找表。
// =============================================================================
import compressunit_pkg::*;


module xs_CompressUnit_core (
  input  compress_in_t [RENAME_WIDTH-1:0] in,
  output logic         [RENAME_WIDTH-1:0]              can_compress_vec,
  output logic         [RENAME_WIDTH-1:0]              need_rob_flags,
  output logic         [RENAME_WIDTH-1:0][SIZE_W-1:0]  instr_sizes,
  output logic         [RENAME_WIDTH-1:0][MASK_W-1:0]  masks
);

  // ---------------------------------------------------------------------------
  // 1. 逐 lane 的"可压缩"判定。
  //    noExc:无任何异常 且 触发动作不是 DebugMode(进调试不能压)。
  // ---------------------------------------------------------------------------
  logic [RENAME_WIDTH-1:0] can_compress;

  always_comb begin
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      automatic logic no_exc = (in[i].exceptionVec == '0)
                             && (in[i].trigger != TRIGGER_DEBUG_MODE);
      automatic logic not_fused = ~in[i].commitType[2]; // CommitType.isFused = bit2
      can_compress[i] = in[i].valid
                      & not_fused
                      & in[i].lastUop
                      & no_exc
                      & in[i].canRobCompress;
    end
  end

  // ---------------------------------------------------------------------------
  // 2. 两端补 0 的 padded key(8 位):key[0]=key[7]=0 哨兵,key[1..6]=can_compress[0..5]。
  //    用 padded 下标 (lane+1) 访问。
  // ---------------------------------------------------------------------------
  logic [RENAME_WIDTH+1:0] key; // [7:0]
  always_comb begin
    key            = '0;
    key[RENAME_WIDTH:1] = can_compress; // 下标 1..6
  end

  // ---------------------------------------------------------------------------
  // 3. 游程统计函数(在 padded key 上,含自身):
  //    cnt_left(p)  : 从 p 向左(下标递减)数连续 1 的个数,遇 0 即停。
  //    cnt_right(p) : 从 p 向右(下标递增)数连续 1 的个数,遇 0 即停。
  //    若 key[p]==0 则两者均为 0。
  // ---------------------------------------------------------------------------
  function automatic int cnt_left(input logic [RENAME_WIDTH+1:0] k, input int p);
    int n;
    n = 0;
    for (int j = p; j >= 0; j--) begin
      if (k[j]) n++;
      else      break;
    end
    return n;
  endfunction

  function automatic int cnt_right(input logic [RENAME_WIDTH+1:0] k, input int p);
    int n;
    n = 0;
    for (int j = p; j <= RENAME_WIDTH+1; j++) begin
      if (k[j]) n++;
      else      break;
    end
    return n;
  endfunction

  // 单条 lane 的组大小:可压缩则=游程长度(cntL+cntR-1),不可压缩则=1。
  // (对 lane i,padded 下标 p=i+1;key[p]==0 即不可压缩。)
  function automatic logic [SIZE_W-1:0] lane_size(input logic [RENAME_WIDTH+1:0] k,
                                                  input int i);
    int p, cl, cr;
    p  = i + 1;
    if (!k[p]) return SIZE_W'(1);
    cl = cnt_left (k, p);
    cr = cnt_right(k, p);
    return SIZE_W'(cl + cr - 1);
  endfunction

  // 单条 lane 的 mask:不可压缩则仅自身位;可压缩则游程区间 [i-cl+1 .. i+cr-1] 全 1。
  // 固定上界遍历所有 lane,落在区间内置 1(便于 Formality 静态展开)。
  function automatic logic [MASK_W-1:0] lane_mask(input logic [RENAME_WIDTH+1:0] k,
                                                  input int i);
    int p, cl, cr, lo, hi;
    logic [MASK_W-1:0] m;
    p = i + 1;
    m = '0;
    if (!k[p]) begin
      m[i] = 1'b1;                 // 不可压缩:仅自身。
    end else begin
      cl = cnt_left (k, p);
      cr = cnt_right(k, p);
      lo = i - (cl - 1);           // 游程最左 lane(0-based)
      hi = i + (cr - 1);           // 游程最右 lane(0-based)
      for (int b = 0; b < RENAME_WIDTH; b++)
        if (b >= lo && b <= hi) m[b] = 1'b1;
    end
    return m;
  endfunction

  // ---------------------------------------------------------------------------
  // 4. 逐 lane 产出 needRob / size / mask。
  //    所有中间量都在纯函数里(automatic 局部,不被综合成状态),always_comb 只做
  //    无条件赋值,避免 Formality 对条件分支临时量推断死寄存器。
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < RENAME_WIDTH; i++) begin
      automatic int p = i + 1;             // padded 下标

      // needRob:右邻也是 1 → 并入右边(0);否则本条需独占 ROB(1)。
      need_rob_flags[i] = ~(key[p] & key[p+1]);
      instr_sizes[i]    = lane_size(key, i);
      masks[i]          = lane_mask(key, i);
    end
  end

  assign can_compress_vec = can_compress;

endmodule

// =============================================================================
// CompressUnit (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/CompressUnit.sv
// 完全一致。机械生成的端口适配层:扁平端口 <-> 可读核 xs_CompressUnit_core 的
// struct/数组端口。算法逻辑在 rtl/backend/CompressUnit.sv。
// 由 scripts/gen_compressunit.py 生成。
// =============================================================================
import compressunit_pkg::*;

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module CompressUnit (
  input         io_in_0_valid,
  input         io_in_0_bits_exceptionVec_0,
  input         io_in_0_bits_exceptionVec_1,
  input         io_in_0_bits_exceptionVec_2,
  input         io_in_0_bits_exceptionVec_3,
  input         io_in_0_bits_exceptionVec_4,
  input         io_in_0_bits_exceptionVec_5,
  input         io_in_0_bits_exceptionVec_6,
  input         io_in_0_bits_exceptionVec_7,
  input         io_in_0_bits_exceptionVec_8,
  input         io_in_0_bits_exceptionVec_9,
  input         io_in_0_bits_exceptionVec_10,
  input         io_in_0_bits_exceptionVec_11,
  input         io_in_0_bits_exceptionVec_12,
  input         io_in_0_bits_exceptionVec_13,
  input         io_in_0_bits_exceptionVec_14,
  input         io_in_0_bits_exceptionVec_15,
  input         io_in_0_bits_exceptionVec_16,
  input         io_in_0_bits_exceptionVec_17,
  input         io_in_0_bits_exceptionVec_18,
  input         io_in_0_bits_exceptionVec_19,
  input         io_in_0_bits_exceptionVec_20,
  input         io_in_0_bits_exceptionVec_21,
  input         io_in_0_bits_exceptionVec_22,
  input         io_in_0_bits_exceptionVec_23,
  input  [3:0]  io_in_0_bits_trigger,
  input         io_in_0_bits_canRobCompress,
  input         io_in_0_bits_lastUop,
  input  [2:0]  io_in_0_bits_commitType,
  input         io_in_1_valid,
  input         io_in_1_bits_exceptionVec_0,
  input         io_in_1_bits_exceptionVec_1,
  input         io_in_1_bits_exceptionVec_2,
  input         io_in_1_bits_exceptionVec_3,
  input         io_in_1_bits_exceptionVec_4,
  input         io_in_1_bits_exceptionVec_5,
  input         io_in_1_bits_exceptionVec_6,
  input         io_in_1_bits_exceptionVec_7,
  input         io_in_1_bits_exceptionVec_8,
  input         io_in_1_bits_exceptionVec_9,
  input         io_in_1_bits_exceptionVec_10,
  input         io_in_1_bits_exceptionVec_11,
  input         io_in_1_bits_exceptionVec_12,
  input         io_in_1_bits_exceptionVec_13,
  input         io_in_1_bits_exceptionVec_14,
  input         io_in_1_bits_exceptionVec_15,
  input         io_in_1_bits_exceptionVec_16,
  input         io_in_1_bits_exceptionVec_17,
  input         io_in_1_bits_exceptionVec_18,
  input         io_in_1_bits_exceptionVec_19,
  input         io_in_1_bits_exceptionVec_20,
  input         io_in_1_bits_exceptionVec_21,
  input         io_in_1_bits_exceptionVec_22,
  input         io_in_1_bits_exceptionVec_23,
  input  [3:0]  io_in_1_bits_trigger,
  input         io_in_1_bits_canRobCompress,
  input         io_in_1_bits_lastUop,
  input  [2:0]  io_in_1_bits_commitType,
  input         io_in_2_valid,
  input         io_in_2_bits_exceptionVec_0,
  input         io_in_2_bits_exceptionVec_1,
  input         io_in_2_bits_exceptionVec_2,
  input         io_in_2_bits_exceptionVec_3,
  input         io_in_2_bits_exceptionVec_4,
  input         io_in_2_bits_exceptionVec_5,
  input         io_in_2_bits_exceptionVec_6,
  input         io_in_2_bits_exceptionVec_7,
  input         io_in_2_bits_exceptionVec_8,
  input         io_in_2_bits_exceptionVec_9,
  input         io_in_2_bits_exceptionVec_10,
  input         io_in_2_bits_exceptionVec_11,
  input         io_in_2_bits_exceptionVec_12,
  input         io_in_2_bits_exceptionVec_13,
  input         io_in_2_bits_exceptionVec_14,
  input         io_in_2_bits_exceptionVec_15,
  input         io_in_2_bits_exceptionVec_16,
  input         io_in_2_bits_exceptionVec_17,
  input         io_in_2_bits_exceptionVec_18,
  input         io_in_2_bits_exceptionVec_19,
  input         io_in_2_bits_exceptionVec_20,
  input         io_in_2_bits_exceptionVec_21,
  input         io_in_2_bits_exceptionVec_22,
  input         io_in_2_bits_exceptionVec_23,
  input  [3:0]  io_in_2_bits_trigger,
  input         io_in_2_bits_canRobCompress,
  input         io_in_2_bits_lastUop,
  input  [2:0]  io_in_2_bits_commitType,
  input         io_in_3_valid,
  input         io_in_3_bits_exceptionVec_0,
  input         io_in_3_bits_exceptionVec_1,
  input         io_in_3_bits_exceptionVec_2,
  input         io_in_3_bits_exceptionVec_3,
  input         io_in_3_bits_exceptionVec_4,
  input         io_in_3_bits_exceptionVec_5,
  input         io_in_3_bits_exceptionVec_6,
  input         io_in_3_bits_exceptionVec_7,
  input         io_in_3_bits_exceptionVec_8,
  input         io_in_3_bits_exceptionVec_9,
  input         io_in_3_bits_exceptionVec_10,
  input         io_in_3_bits_exceptionVec_11,
  input         io_in_3_bits_exceptionVec_12,
  input         io_in_3_bits_exceptionVec_13,
  input         io_in_3_bits_exceptionVec_14,
  input         io_in_3_bits_exceptionVec_15,
  input         io_in_3_bits_exceptionVec_16,
  input         io_in_3_bits_exceptionVec_17,
  input         io_in_3_bits_exceptionVec_18,
  input         io_in_3_bits_exceptionVec_19,
  input         io_in_3_bits_exceptionVec_20,
  input         io_in_3_bits_exceptionVec_21,
  input         io_in_3_bits_exceptionVec_22,
  input         io_in_3_bits_exceptionVec_23,
  input  [3:0]  io_in_3_bits_trigger,
  input         io_in_3_bits_canRobCompress,
  input         io_in_3_bits_lastUop,
  input  [2:0]  io_in_3_bits_commitType,
  input         io_in_4_valid,
  input         io_in_4_bits_exceptionVec_0,
  input         io_in_4_bits_exceptionVec_1,
  input         io_in_4_bits_exceptionVec_2,
  input         io_in_4_bits_exceptionVec_3,
  input         io_in_4_bits_exceptionVec_4,
  input         io_in_4_bits_exceptionVec_5,
  input         io_in_4_bits_exceptionVec_6,
  input         io_in_4_bits_exceptionVec_7,
  input         io_in_4_bits_exceptionVec_8,
  input         io_in_4_bits_exceptionVec_9,
  input         io_in_4_bits_exceptionVec_10,
  input         io_in_4_bits_exceptionVec_11,
  input         io_in_4_bits_exceptionVec_12,
  input         io_in_4_bits_exceptionVec_13,
  input         io_in_4_bits_exceptionVec_14,
  input         io_in_4_bits_exceptionVec_15,
  input         io_in_4_bits_exceptionVec_16,
  input         io_in_4_bits_exceptionVec_17,
  input         io_in_4_bits_exceptionVec_18,
  input         io_in_4_bits_exceptionVec_19,
  input         io_in_4_bits_exceptionVec_20,
  input         io_in_4_bits_exceptionVec_21,
  input         io_in_4_bits_exceptionVec_22,
  input         io_in_4_bits_exceptionVec_23,
  input  [3:0]  io_in_4_bits_trigger,
  input         io_in_4_bits_canRobCompress,
  input         io_in_4_bits_lastUop,
  input  [2:0]  io_in_4_bits_commitType,
  input         io_in_5_valid,
  input         io_in_5_bits_exceptionVec_0,
  input         io_in_5_bits_exceptionVec_1,
  input         io_in_5_bits_exceptionVec_2,
  input         io_in_5_bits_exceptionVec_3,
  input         io_in_5_bits_exceptionVec_4,
  input         io_in_5_bits_exceptionVec_5,
  input         io_in_5_bits_exceptionVec_6,
  input         io_in_5_bits_exceptionVec_7,
  input         io_in_5_bits_exceptionVec_8,
  input         io_in_5_bits_exceptionVec_9,
  input         io_in_5_bits_exceptionVec_10,
  input         io_in_5_bits_exceptionVec_11,
  input         io_in_5_bits_exceptionVec_12,
  input         io_in_5_bits_exceptionVec_13,
  input         io_in_5_bits_exceptionVec_14,
  input         io_in_5_bits_exceptionVec_15,
  input         io_in_5_bits_exceptionVec_16,
  input         io_in_5_bits_exceptionVec_17,
  input         io_in_5_bits_exceptionVec_18,
  input         io_in_5_bits_exceptionVec_19,
  input         io_in_5_bits_exceptionVec_20,
  input         io_in_5_bits_exceptionVec_21,
  input         io_in_5_bits_exceptionVec_22,
  input         io_in_5_bits_exceptionVec_23,
  input  [3:0]  io_in_5_bits_trigger,
  input         io_in_5_bits_canRobCompress,
  input         io_in_5_bits_lastUop,
  input  [2:0]  io_in_5_bits_commitType,
  output        io_out_needRobFlags_0,
  output        io_out_needRobFlags_1,
  output        io_out_needRobFlags_2,
  output        io_out_needRobFlags_3,
  output        io_out_needRobFlags_4,
  output        io_out_needRobFlags_5,
  output [2:0]  io_out_instrSizes_0,
  output [2:0]  io_out_instrSizes_1,
  output [2:0]  io_out_instrSizes_2,
  output [2:0]  io_out_instrSizes_3,
  output [2:0]  io_out_instrSizes_4,
  output [2:0]  io_out_instrSizes_5,
  output [5:0]  io_out_masks_0,
  output [5:0]  io_out_masks_1,
  output [5:0]  io_out_masks_2,
  output [5:0]  io_out_masks_3,
  output [5:0]  io_out_masks_4,
  output [5:0]  io_out_masks_5,
  output        io_out_canCompressVec_0,
  output        io_out_canCompressVec_1,
  output        io_out_canCompressVec_2,
  output        io_out_canCompressVec_3,
  output        io_out_canCompressVec_4,
  output        io_out_canCompressVec_5
);

  compress_in_t [RENAME_WIDTH-1:0] in_w;
  logic [RENAME_WIDTH-1:0]             ccv, nrf;
  logic [RENAME_WIDTH-1:0][SIZE_W-1:0] sizes;
  logic [RENAME_WIDTH-1:0][MASK_W-1:0] masks_w;

  assign in_w[0] = '{
    valid:          io_in_0_valid,
    exceptionVec:   {io_in_0_bits_exceptionVec_23, io_in_0_bits_exceptionVec_22, io_in_0_bits_exceptionVec_21, io_in_0_bits_exceptionVec_20, io_in_0_bits_exceptionVec_19, io_in_0_bits_exceptionVec_18, io_in_0_bits_exceptionVec_17, io_in_0_bits_exceptionVec_16, io_in_0_bits_exceptionVec_15, io_in_0_bits_exceptionVec_14, io_in_0_bits_exceptionVec_13, io_in_0_bits_exceptionVec_12, io_in_0_bits_exceptionVec_11, io_in_0_bits_exceptionVec_10, io_in_0_bits_exceptionVec_9, io_in_0_bits_exceptionVec_8, io_in_0_bits_exceptionVec_7, io_in_0_bits_exceptionVec_6, io_in_0_bits_exceptionVec_5, io_in_0_bits_exceptionVec_4, io_in_0_bits_exceptionVec_3, io_in_0_bits_exceptionVec_2, io_in_0_bits_exceptionVec_1, io_in_0_bits_exceptionVec_0},
    trigger:        io_in_0_bits_trigger,
    canRobCompress: io_in_0_bits_canRobCompress,
    lastUop:        io_in_0_bits_lastUop,
    commitType:     io_in_0_bits_commitType
  };
  assign in_w[1] = '{
    valid:          io_in_1_valid,
    exceptionVec:   {io_in_1_bits_exceptionVec_23, io_in_1_bits_exceptionVec_22, io_in_1_bits_exceptionVec_21, io_in_1_bits_exceptionVec_20, io_in_1_bits_exceptionVec_19, io_in_1_bits_exceptionVec_18, io_in_1_bits_exceptionVec_17, io_in_1_bits_exceptionVec_16, io_in_1_bits_exceptionVec_15, io_in_1_bits_exceptionVec_14, io_in_1_bits_exceptionVec_13, io_in_1_bits_exceptionVec_12, io_in_1_bits_exceptionVec_11, io_in_1_bits_exceptionVec_10, io_in_1_bits_exceptionVec_9, io_in_1_bits_exceptionVec_8, io_in_1_bits_exceptionVec_7, io_in_1_bits_exceptionVec_6, io_in_1_bits_exceptionVec_5, io_in_1_bits_exceptionVec_4, io_in_1_bits_exceptionVec_3, io_in_1_bits_exceptionVec_2, io_in_1_bits_exceptionVec_1, io_in_1_bits_exceptionVec_0},
    trigger:        io_in_1_bits_trigger,
    canRobCompress: io_in_1_bits_canRobCompress,
    lastUop:        io_in_1_bits_lastUop,
    commitType:     io_in_1_bits_commitType
  };
  assign in_w[2] = '{
    valid:          io_in_2_valid,
    exceptionVec:   {io_in_2_bits_exceptionVec_23, io_in_2_bits_exceptionVec_22, io_in_2_bits_exceptionVec_21, io_in_2_bits_exceptionVec_20, io_in_2_bits_exceptionVec_19, io_in_2_bits_exceptionVec_18, io_in_2_bits_exceptionVec_17, io_in_2_bits_exceptionVec_16, io_in_2_bits_exceptionVec_15, io_in_2_bits_exceptionVec_14, io_in_2_bits_exceptionVec_13, io_in_2_bits_exceptionVec_12, io_in_2_bits_exceptionVec_11, io_in_2_bits_exceptionVec_10, io_in_2_bits_exceptionVec_9, io_in_2_bits_exceptionVec_8, io_in_2_bits_exceptionVec_7, io_in_2_bits_exceptionVec_6, io_in_2_bits_exceptionVec_5, io_in_2_bits_exceptionVec_4, io_in_2_bits_exceptionVec_3, io_in_2_bits_exceptionVec_2, io_in_2_bits_exceptionVec_1, io_in_2_bits_exceptionVec_0},
    trigger:        io_in_2_bits_trigger,
    canRobCompress: io_in_2_bits_canRobCompress,
    lastUop:        io_in_2_bits_lastUop,
    commitType:     io_in_2_bits_commitType
  };
  assign in_w[3] = '{
    valid:          io_in_3_valid,
    exceptionVec:   {io_in_3_bits_exceptionVec_23, io_in_3_bits_exceptionVec_22, io_in_3_bits_exceptionVec_21, io_in_3_bits_exceptionVec_20, io_in_3_bits_exceptionVec_19, io_in_3_bits_exceptionVec_18, io_in_3_bits_exceptionVec_17, io_in_3_bits_exceptionVec_16, io_in_3_bits_exceptionVec_15, io_in_3_bits_exceptionVec_14, io_in_3_bits_exceptionVec_13, io_in_3_bits_exceptionVec_12, io_in_3_bits_exceptionVec_11, io_in_3_bits_exceptionVec_10, io_in_3_bits_exceptionVec_9, io_in_3_bits_exceptionVec_8, io_in_3_bits_exceptionVec_7, io_in_3_bits_exceptionVec_6, io_in_3_bits_exceptionVec_5, io_in_3_bits_exceptionVec_4, io_in_3_bits_exceptionVec_3, io_in_3_bits_exceptionVec_2, io_in_3_bits_exceptionVec_1, io_in_3_bits_exceptionVec_0},
    trigger:        io_in_3_bits_trigger,
    canRobCompress: io_in_3_bits_canRobCompress,
    lastUop:        io_in_3_bits_lastUop,
    commitType:     io_in_3_bits_commitType
  };
  assign in_w[4] = '{
    valid:          io_in_4_valid,
    exceptionVec:   {io_in_4_bits_exceptionVec_23, io_in_4_bits_exceptionVec_22, io_in_4_bits_exceptionVec_21, io_in_4_bits_exceptionVec_20, io_in_4_bits_exceptionVec_19, io_in_4_bits_exceptionVec_18, io_in_4_bits_exceptionVec_17, io_in_4_bits_exceptionVec_16, io_in_4_bits_exceptionVec_15, io_in_4_bits_exceptionVec_14, io_in_4_bits_exceptionVec_13, io_in_4_bits_exceptionVec_12, io_in_4_bits_exceptionVec_11, io_in_4_bits_exceptionVec_10, io_in_4_bits_exceptionVec_9, io_in_4_bits_exceptionVec_8, io_in_4_bits_exceptionVec_7, io_in_4_bits_exceptionVec_6, io_in_4_bits_exceptionVec_5, io_in_4_bits_exceptionVec_4, io_in_4_bits_exceptionVec_3, io_in_4_bits_exceptionVec_2, io_in_4_bits_exceptionVec_1, io_in_4_bits_exceptionVec_0},
    trigger:        io_in_4_bits_trigger,
    canRobCompress: io_in_4_bits_canRobCompress,
    lastUop:        io_in_4_bits_lastUop,
    commitType:     io_in_4_bits_commitType
  };
  assign in_w[5] = '{
    valid:          io_in_5_valid,
    exceptionVec:   {io_in_5_bits_exceptionVec_23, io_in_5_bits_exceptionVec_22, io_in_5_bits_exceptionVec_21, io_in_5_bits_exceptionVec_20, io_in_5_bits_exceptionVec_19, io_in_5_bits_exceptionVec_18, io_in_5_bits_exceptionVec_17, io_in_5_bits_exceptionVec_16, io_in_5_bits_exceptionVec_15, io_in_5_bits_exceptionVec_14, io_in_5_bits_exceptionVec_13, io_in_5_bits_exceptionVec_12, io_in_5_bits_exceptionVec_11, io_in_5_bits_exceptionVec_10, io_in_5_bits_exceptionVec_9, io_in_5_bits_exceptionVec_8, io_in_5_bits_exceptionVec_7, io_in_5_bits_exceptionVec_6, io_in_5_bits_exceptionVec_5, io_in_5_bits_exceptionVec_4, io_in_5_bits_exceptionVec_3, io_in_5_bits_exceptionVec_2, io_in_5_bits_exceptionVec_1, io_in_5_bits_exceptionVec_0},
    trigger:        io_in_5_bits_trigger,
    canRobCompress: io_in_5_bits_canRobCompress,
    lastUop:        io_in_5_bits_lastUop,
    commitType:     io_in_5_bits_commitType
  };

  xs_CompressUnit_core u_core (
    .in               (in_w),
    .can_compress_vec (ccv),
    .need_rob_flags   (nrf),
    .instr_sizes      (sizes),
    .masks            (masks_w)
  );

  assign io_out_needRobFlags_0    = nrf[0];
  assign io_out_needRobFlags_1    = nrf[1];
  assign io_out_needRobFlags_2    = nrf[2];
  assign io_out_needRobFlags_3    = nrf[3];
  assign io_out_needRobFlags_4    = nrf[4];
  assign io_out_needRobFlags_5    = nrf[5];
  assign io_out_instrSizes_0      = sizes[0];
  assign io_out_instrSizes_1      = sizes[1];
  assign io_out_instrSizes_2      = sizes[2];
  assign io_out_instrSizes_3      = sizes[3];
  assign io_out_instrSizes_4      = sizes[4];
  assign io_out_instrSizes_5      = sizes[5];
  assign io_out_masks_0           = masks_w[0];
  assign io_out_masks_1           = masks_w[1];
  assign io_out_masks_2           = masks_w[2];
  assign io_out_masks_3           = masks_w[3];
  assign io_out_masks_4           = masks_w[4];
  assign io_out_masks_5           = masks_w[5];
  assign io_out_canCompressVec_0  = ccv[0];
  assign io_out_canCompressVec_1  = ccv[1];
  assign io_out_canCompressVec_2  = ccv[2];
  assign io_out_canCompressVec_3  = ccv[3];
  assign io_out_canCompressVec_4  = ccv[4];
  assign io_out_canCompressVec_5  = ccv[5];

endmodule
