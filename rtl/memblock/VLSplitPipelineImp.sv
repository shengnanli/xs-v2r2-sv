// =====================================================================
// VLSplitPipelineImp.sv —— 向量访存"拆分流水"（VSplitPipeline 家族的参数化核 + VLoad 变体 wrapper）
// ---------------------------------------------------------------------
// 位置（Chisel: xiangshan/mem/vector/VSplit.scala 的 VSplitPipeline）：
//   发射队列 ──in──> 【拆分流水 s0/s1】 ──out──> skid 缓冲 ──> 拆分缓冲(VSplitBuffer) ──> 标量访存流水
//                        │  ^
//          toMergeBuffer.req  resp(mBIndex)        合并缓冲(VMergeBuffer)：给这条 uop 分一个条目
// 一条向量访存 uop 在这里被"读懂"：它是哪一类指令、要访问几个元素（flow）、哪些元素被 mask /
//   vstart / vl 关掉、这条 uop 的起始地址相对指令基址偏多少。真正逐元素发访问的是后面的拆分缓冲。
// 两级：
//   s0（组合）：从 fuOpType / vtype / nf / eew 译出指令类型（unit-stride / strided / indexed，是否 segment、
//      whole-register、mask 型），算 emul、这条 uop 在一个 field 里是第几个（uopIdxInField）、
//      对应第几个目的寄存器（vdIdxInField）、有效长度 evl、本 uop 的元素掩码 flowMask 与字节掩码 byteMask。
//   s1（一拍后）：算本 uop 的地址偏移 uopOffset；unit-stride 把整条 uop 当成最多两次 128 位访问，
//      算出 32 位的 usMask（低 16 位 = 第一次访问，高 16 位 = 跨到下一个 16B 的第二次访问）；
//      向合并缓冲申请条目，申请到了（或这是部分重放、沿用旧条目）才把 uop 交给拆分缓冲。
// 两个变体只差在（参数 IS_VSTORE）：
//   · 三个特殊 unit-stride 操作码：whole-register（vl<nf>r / vs<nf>r）、mask 型（vlm / vsm）、
//     fault-only-first（只有 load 有 vleff）；
//   · load 的有序 indexed（mop=11）必须按序做：它只在合并缓冲点名轮到它时才被接收；
//   · 交给合并缓冲的字段集合不同（load 多 data / vdIdx / fof，store 多 uop.vpu.vmask）。
// 寄存器的位置：s1_valid 在核里；s1 入口的整包打拍寄存器（s1_in_r_*）放在各变体 wrapper 的生成段里——
//   golden 两个变体留下的字段集合不同（load 多 fof / vdIdxInField），字段集合照 golden 现数；
//   核输出"下一拍要装的包" s0_out 与装载使能 s0_fire，读回 s1_in。
// 文件结构：xs_VSplitPipeline_core（手写）→ VLSplitPipelineImp wrapper（生成）；类型与小函数在 vlsu_pkg.sv。
//   store 变体的 wrapper 在 VSSplitPipelineImp.sv。GENERATED 段由 scripts/gen_vsplit.py 生成。
// =====================================================================


// =====================================================================
// xs_VSplitPipeline_core —— 拆分流水的可读核（load / store 共用）
// =====================================================================
module xs_VSplitPipeline_core
  import vlsu_pkg::*;
#(
  parameter bit IS_VSTORE = 1'b0
) (
  // BEGIN GENERATED(core_ports) —— scripts/gen_vsplit.py 生成，勿手改
  input  logic          clock,
  input  logic          reset,
  input  logic          redirect_valid,
  input  logic          redirect_bits_robIdx_flag,
  input  logic [7:0]    redirect_bits_robIdx_value,
  input  logic          redirect_bits_level,
  output logic          in_ready,
  input  logic          in_valid,
  input  split_in_t     in,
  input  logic          toMergeBuffer_req_ready,
  output logic          toMergeBuffer_req_valid,
  output merge_req_t    toMergeBuffer_req,
  input  logic          toMergeBuffer_resp_valid,
  input  logic [3:0]    toMergeBuffer_resp_bits_mBIndex,
  input  logic          out_ready,
  output logic          out_valid,
  output vls_t          out,
  input  logic          threshold_valid,
  input  logic          threshold_bits_robIdx_flag,
  input  logic [7:0]    threshold_bits_robIdx_value,
  input  logic [6:0]    threshold_bits_uopIdx,
  output vls_t          s0_out,
  output logic          s0_fire,
  input  vls_t          s1_in
  // END GENERATED(core_ports)
);

  logic s1_ready;

  // ===================================================================
  // s0：译码，算 emul / 各种下标 / 有效长度 / 元素掩码
  // -------------------------------------------------------------------
  // 输入：in（发射队列来的 uop + 5 个源操作数：src_0=基址 rs1，src_1=stride 或 index 向量，
  //       src_2=store 数据 vs3，src_3=v0 mask，src_4=vl）、threshold（合并缓冲点名）、redirect。
  // 关键量（倍数 emul/lmul 都是 3 位有符号的 log2）：
  //   · emul：访存元素的寄存器组倍数 = eew - sew + lmul；whole-register 由 nf 决定；mask 型恒 1 倍。
  //   · 一条指令被后端拆成多条 uop，每条 uop 对应"一个 field 里的一个寄存器"。indexed 指令里
  //     index 寄存器组（emul）和数据寄存器组（lmul）大小可以不同，uop 数取大的那个：
  //       uopIdxInField = 本 uop 是 field 里第几条；vdIdxInField = 它写的是第几个目的寄存器。
  //   · flowsLog2 = 一条 uop 里的元素数（log2）；numFlowsSameVdLog2 = 一个目的寄存器里的元素数。
  //   · flowMask = (v0 mask 或全 1) ∩ [vstart, evl) ∩ 本 uop 负责的元素区间，再右移到从 bit0 起。
  //     "特殊 indexed"（emul > lmul：多条 uop 写同一个目的寄存器）时两种右移量不同，见下。
  // ===================================================================
  logic [8:0] s0_fuOpType;
  logic [1:0] s0_mop, s0_sew, s0_eew;
  logic [2:0] s0_lmul;
  logic       s0_us_whole_reg, s0_us_mask, s0_us_fof;

  assign s0_fuOpType     = in.uop.fuOpType;
  assign s0_mop          = s0_fuOpType[6:5];
  assign s0_sew          = in.uop.vpu_vsew;
  assign s0_eew          = in.uop.vpu_veew;
  assign s0_lmul         = in.uop.vpu_vlmul;
  assign s0_us_whole_reg = s0_fuOpType == (IS_VSTORE ? VSTU_VSR : VLDU_VLR);
  assign s0_us_mask      = s0_fuOpType == (IS_VSTORE ? VSTU_VSM : VLDU_VLM);
  assign s0_us_fof       = IS_VSTORE ? 1'b0 : (s0_fuOpType == VLDU_VLEFF);

  logic [2:0] s0_nf;             // field 数 - 1（whole-register 的 nf 另有含义，当 0）
  logic [3:0] s0_nfield;
  logic [2:0] s0_emul;
  logic       s0_preIsSplit;     // 非 unit-stride：逐元素拆；unit-stride 则整条 uop 当 128 位访问
  logic       s0_isUsWholeReg, s0_isMaskReg, s0_isSegment;
  logic [2:0] s0_instType;       // {segment, mop}
  logic       s0_isIndexed;

  always_comb begin
    s0_nf = s0_us_whole_reg ? 3'b0 : in.uop.vpu_nf;
    // whole-register：nf+1 = 1/2/4/8 个寄存器 → emul = 0/1/2/3
    if (s0_us_whole_reg) begin
      case (in.uop.vpu_nf)
        3'b001:  s0_emul = 3'b001;
        3'b011:  s0_emul = 3'b010;
        3'b111:  s0_emul = 3'b011;
        default: s0_emul = 3'b000;
      endcase
    end else if (s0_us_mask) begin
      s0_emul = 3'b000;
    end else begin
      s0_emul = 3'(s0_eew) - 3'(s0_sew) + s0_lmul;
    end
  end
  assign s0_nfield       = 4'(s0_nf) + 4'd1;
  assign s0_preIsSplit   = (s0_mop != MOP_UNIT_STRIDE);
  assign s0_isUsWholeReg = (s0_mop == MOP_UNIT_STRIDE) & s0_us_whole_reg;
  assign s0_isMaskReg    = (s0_mop == MOP_UNIT_STRIDE) & s0_us_mask;
  assign s0_isSegment    = (s0_nf != 3'b0) & ~s0_us_whole_reg;
  assign s0_instType     = {s0_isSegment, s0_mop};
  assign s0_isIndexed    = s0_instType[0];

  // ---- uop / 目的寄存器在 field 里的下标 ----
  logic [6:0] s0_uopIdx;
  logic [2:0] s0_uopIdxInField, s0_vdIdxInField;
  logic       s0_lmulGtEmul, s0_emulGtLmul;
  assign s0_uopIdx     = in.uop.vpu_vuopIdx;
  assign s0_lmulGtEmul = $signed(s0_lmul) > $signed(s0_emul);
  assign s0_emulGtLmul = $signed(s0_emul) > $signed(s0_lmul);
  assign s0_uopIdxInField = uop_idx_in_field((s0_isIndexed & s0_lmulGtEmul) ? s0_lmul : s0_emul, s0_uopIdx);
  always_comb begin
    logic [2:0] multiple;        // index 寄存器组比数据寄存器组大多少倍（log2）
    multiple = s0_emul - s0_lmul;
    if (s0_mop == MOP_UNIT_STRIDE || s0_mop == MOP_STRIDED || s0_lmulGtEmul) begin
      s0_vdIdxInField = s0_uopIdxInField;
    end else begin
      case (multiple)
        3'd0:    s0_vdIdxInField = s0_uopIdxInField;
        3'd1:    s0_vdIdxInField = s0_uopIdxInField >> 1;
        3'd2:    s0_vdIdxInField = s0_uopIdxInField >> 2;
        default: s0_vdIdxInField = 3'b0;
      endcase
    end
  end

  // ---- 本指令一共几条 uop：NFIELDS * max(lmul, emul)（倍数小于 1 时按 1）----
  logic [10:0] s0_numUops;
  always_comb begin
    logic [2:0] lmulPos, emulPos;
    lmulPos = ($signed(s0_lmul) < 0) ? 3'b0 : s0_lmul;
    emulPos = ($signed(s0_emul) < 0) ? 3'b0 : s0_emul;
    s0_numUops = (s0_fuOpType[5] & s0_lmulGtEmul) ? 11'(s0_nfield) << lmulPos
                                                  : 11'(s0_nfield) << emulPos;
  end

  // ---- 有效长度 evl ----
  logic [7:0] s0_vl, s0_evl, s0_usWholeRegVl;
  assign s0_vl = in.src_4[7:0];
  always_comb begin
    logic [3:0] nfieldsRaw;
    nfieldsRaw = 4'(in.uop.vpu_nf) + 4'd1;
    // whole-register：元素数 = 寄存器数 * (VLENB / 元素字节数)
    case (s0_eew)
      2'b00:   s0_usWholeRegVl = {nfieldsRaw, 4'b0};
      2'b01:   s0_usWholeRegVl = 8'({nfieldsRaw, 3'b0});
      2'b10:   s0_usWholeRegVl = 8'({nfieldsRaw, 2'b0});
      default: s0_usWholeRegVl = 8'({nfieldsRaw, 1'b0});
    endcase
    if (s0_isUsWholeReg)
      s0_evl = s0_usWholeRegVl;
    else if (s0_isMaskReg)       // mask 型按字节访问：ceil(vl / 8)
      s0_evl = (s0_vl[2:0] == 3'b0) ? 8'(s0_vl[7:3]) : 8'(6'(s0_vl[7:3]) + 6'd1);
    else
      s0_evl = s0_vl;
  end

  // ---- 元素宽度、每 uop / 每目的寄存器的元素数 ----
  logic [1:0] s0_alignedType;          // 访存元素宽度（log2 字节）：indexed 是数据宽 sew，否则 eew
  logic [2:0] s0_flowsLog2;            // 一条 uop 的元素数（log2）
  logic [2:0] s0_numFlowsSameVdLog2;   // 一个目的寄存器的元素数（log2）
  logic [2:0] s0_eewFlowLog2, s0_sewFlowLog2;
  assign s0_alignedType        = s0_isIndexed ? s0_sew : s0_eew;
  assign s0_eewFlowLog2        = mul_frac_only(s0_emul) + 3'd4 - 3'(s0_eew);
  assign s0_sewFlowLog2        = mul_frac_only(s0_lmul) + 3'd4 - 3'(s0_sew);
  assign s0_flowsLog2          = s0_isIndexed ? (s0_emulGtLmul ? s0_eewFlowLog2 : s0_sewFlowLog2)
                                              : s0_eewFlowLog2;
  assign s0_numFlowsSameVdLog2 = s0_isIndexed ? 3'd4 - 3'(s0_sew) : 3'd4 - 3'(s0_eew);

  logic [9:0]  s0_flowsPrevThisUop;       // 本 uop 之前、同一 field 里已有多少元素
  logic [9:0]  s0_flowsPrevThisVd;        // 本目的寄存器之前已有多少元素
  logic [10:0] s0_flowsIncludeThisUop;    // 算上本 uop
  assign s0_flowsPrevThisUop    = 10'(s0_uopIdxInField) << s0_flowsLog2;
  assign s0_flowsPrevThisVd     = 10'(s0_vdIdxInField)  << s0_numFlowsSameVdLog2;
  assign s0_flowsIncludeThisUop = 11'(4'(s0_uopIdxInField) + 4'd1) << s0_flowsLog2;

  // ---- 掩码 ----
  // "特殊 indexed"：emul > lmul，多条 uop 对应同一个目的寄存器。发元素访问要按"本 uop 之前的元素数"
  // 右移（flowMask），而交给合并缓冲的 mask 要按"本目的寄存器之前的元素数"右移（indexedSrcMask），
  // 两者之差 indexedSplitOffset 给拆分缓冲算元素在目的寄存器里的位置。
  logic               s0_isSpecialIndexed;
  logic [VLEN-1:0]    s0_srcMask;           // mask ∩ [vstart, evl)
  logic [VLENB-1:0]   s0_flowMask;
  logic [VLEN-1:0]    s0_indexedSrcMask;
  assign s0_isSpecialIndexed = s0_isIndexed & s0_emulGtLmul;
  assign s0_srcMask = (in.uop.vpu_vm ? '1 : in.src_3)
                    & low_ones(11'(s0_evl)) & ~low_ones(11'(in.uop.vpu_vstart));
  always_comb begin
    logic [VLEN:0] thisUop;
    thisUop = {1'b0, low_ones(s0_flowsIncludeThisUop) & s0_srcMask & ~low_ones(11'(s0_flowsPrevThisUop))};
    s0_flowMask = VLENB'(thisUop >> (s0_isSpecialIndexed ? s0_flowsPrevThisUop : s0_flowsPrevThisVd));
  end
  assign s0_indexedSrcMask = s0_srcMask >> s0_flowsPrevThisVd;

  // ---- 握手 ----
  // 合并缓冲快满时（threshold.valid）只放行它点名的那条 uop；load 的有序 indexed 永远只在被点名时放行
  logic s0_mergeBufferNack, s0_kill, s0_valid;
  assign s0_mergeBufferNack = (threshold_valid | (s0_mop == MOP_ORDER_INDEX) & ~IS_VSTORE)
                            & ~({threshold_bits_robIdx_flag, threshold_bits_robIdx_value}
                                  == {in.uop.robIdx_flag, in.uop.robIdx_value}
                                & threshold_bits_uopIdx == in.uop.vpu_vuopIdx);
  assign s0_kill  = rob_need_flush(in.uop.robIdx_flag, in.uop.robIdx_value, redirect_valid,
                                   redirect_bits_level, redirect_bits_robIdx_flag, redirect_bits_robIdx_value);
  assign s0_valid = in_valid & ~s0_kill;
  assign s0_fire  = s0_valid & s1_ready;
  assign in_ready = s1_ready & ~s0_mergeBufferNack;

  // ---- 交给 s1 的包 ----
  always_comb begin
    s0_out                    = '0;
    s0_out.uop                = in.uop;
    s0_out.uop.vpu_vl         = s0_evl;
    s0_out.uop.uopIdx         = s0_uopIdx;
    s0_out.uop.numUops        = s0_numUops[6:0];
    s0_out.uop.lastUop        = (11'(8'(s0_uopIdx) + 8'd1) == s0_numUops);
    s0_out.uop.vpu_nf         = s0_nf;
    s0_out.rawNf              = in.uop.vpu_nf;
    s0_out.flowMask           = s0_flowMask;
    s0_out.indexedSrcMask     = s0_indexedSrcMask[VLENB-1:0];
    s0_out.indexedSplitOffset = s0_isSpecialIndexed ? s0_flowsPrevThisUop[4:0] - s0_flowsPrevThisVd[4:0] : 5'b0;
    s0_out.byteMask           = flow_to_byte_mask(s0_flowMask, s0_alignedType);
    s0_out.fof                = (s0_mop == MOP_UNIT_STRIDE) & s0_us_fof;
    s0_out.baseAddr           = in.src_0[XLEN-1:0];
    s0_out.stride             = in.src_1;
    s0_out.flowNum            = in.flowNum;
    s0_out.nfields            = s0_nfield;
    s0_out.eew                = s0_eew;
    s0_out.sew                = 3'(s0_sew);
    s0_out.emul               = s0_emul;
    s0_out.lmul               = s0_lmul;
    // VLMAX = LMUL * VLEN / SEW；whole-register 用它自己的 evl
    s0_out.vlmax              = s0_isUsWholeReg ? s0_evl : 8'h1 << (s0_lmul + 3'd4 - 3'(s0_sew));
    s0_out.instType           = s0_instType;
    s0_out.data               = in.src_2;
    s0_out.vdIdxInField       = s0_vdIdxInField;
    s0_out.preIsSplit         = s0_preIsSplit;
    s0_out.alignedType        = s0_preIsSplit ? {1'b0, s0_alignedType} : 3'b100;   // unit-stride：128 位访问
    // 一个 index 寄存器里的元素数 - 1（当下标掩码用）
    s0_out.indexVlMaxInVd     = (8'h1 << ((($signed(s0_emul) > 0) ? 3'b0 : s0_emul) + 3'd4 - 3'(s0_eew))) - 8'h1;
    s0_out.isVecPartReplay    = in.isVecPartReplay;
    s0_out.vecReplayMbIdx     = in.vecReplayMbIdx;
    s0_out.vecReplayFlowMask  = in.vecReplayMask;
  end

  // ===================================================================
  // s1：算 uop 地址偏移与 unit-stride 的 32 位字节掩码；向合并缓冲要条目；交给拆分缓冲
  // -------------------------------------------------------------------
  // 输入：s1_in（s0 的包打一拍）、toMergeBuffer 的 ready / resp、out_ready、redirect。
  // 地址偏移 uopOffset（本 uop 相对指令基址）：
  //   unit-stride：uop 在 field 里的序号 << alignedType（alignedType=4，即每条 uop 16 字节）；
  //   strided    ：(序号 * stride) << (4 - eew)，即 序号 * 每 uop 元素数 * stride；
  //   indexed    ：0（每个元素的偏移由拆分缓冲从 index 向量里取）。
  // unit-stride 的起始地址若不是 16B 对齐，16 个字节会跨两个 16B 窗口：usMask 把 byteMask 左移
  //   起始地址低 4 位，低 16 位 / 高 16 位分别是两次访问的字节掩码；哪一半有字节就要发哪一次。
  // 握手：能往下走 = 拆分缓冲收 且（合并缓冲给了条目，或这是部分重放——沿用上次的条目号）。
  // ===================================================================
  logic s1_valid;
  logic s1_kill, s1_can_go, s1_fire;

  assign s1_kill   = rob_need_flush(s1_in.uop.robIdx_flag, s1_in.uop.robIdx_value, redirect_valid,
                                    redirect_bits_level, redirect_bits_robIdx_flag, redirect_bits_robIdx_value);
  assign s1_can_go = out_ready & (toMergeBuffer_req_ready | s1_in.isVecPartReplay & s1_valid);
  assign s1_fire   = s1_valid & ~s1_kill & s1_can_go;
  assign s1_ready  = s1_kill | ~s1_valid | s1_can_go;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid <= 1'b0;
    end else begin
      if      (s0_fire) s1_valid <= 1'b1;
      else if (s1_fire) s1_valid <= 1'b0;
      else if (s1_kill) s1_valid <= 1'b0;
    end
  end

  // ---- stride 与 uop 地址偏移 ----
  logic              s1_isIndexed, s1_isStrided, s1_isSpecialIndexed;
  logic [VLEN-1:0]   s1_stride;         // indexed：整个 index 向量（拆分缓冲再取元素）；否则 64 位步长
  logic [6:0]        s1_uopInsideField; // 本 uop 在 field 里的序号
  logic [XLEN-1:0]   s1_uopOffset;
  assign s1_isIndexed        = s1_in.instType[0];
  assign s1_isStrided        = (s1_in.instType[1:0] == MOP_STRIDED);
  assign s1_isSpecialIndexed = s1_isIndexed & ($signed(s1_in.emul) > $signed(s1_in.lmul));
  // unit-stride 的"步长" = 元素字节数 * NFIELDS（只在 segment 时有意义，这里照 Chisel 算出）
  assign s1_stride = s1_isIndexed ? s1_in.stride
                   : s1_isStrided ? VLEN'(s1_in.stride[XLEN-1:0])
                   :                VLEN'(7'(s1_in.nfields) << s1_in.eew);
  assign s1_uopInsideField = s1_in.uop.vpu_vuopIdx >> s1_in.uop.vpu_nf;
  always_comb begin
    case (s1_in.instType[1:0])
      MOP_UNIT_STRIDE: s1_uopOffset = XLEN'(14'(s1_uopInsideField) << s1_in.alignedType);
      MOP_STRIDED:     s1_uopOffset = stride_times(s1_uopInsideField, s1_stride[XLEN-1:0]) << (3'd4 - 3'(s1_in.eew));
      default:         s1_uopOffset = '0;
    endcase
  end

  // ---- unit-stride 的两次 128 位访问 ----
  logic [3:0]  s1_usLowBitsAddr;        // uop 起始地址的低 4 位
  logic [31:0] s1_usMask;
  logic        s1_usMaskLowActive, s1_usMaskHighActive;
  logic [4:0]  s1_usActiveNum, s1_activeNum;
  assign s1_usLowBitsAddr    = s1_in.baseAddr[3:0] + s1_uopOffset[3:0];
  assign s1_usMask           = 32'(s1_in.byteMask) << s1_usLowBitsAddr;
  assign s1_usMaskLowActive  = |s1_usMask[31:16];     // 命名照 Chisel（"Low" 取的是高半）
  assign s1_usMaskHighActive = |s1_usMask[15:0];
  assign s1_usActiveNum = (s1_usMaskLowActive & s1_usMaskHighActive) ? 5'd2
                        : (s1_usMaskLowActive | s1_usMaskHighActive) ? 5'd1 : 5'd0;
  // 本 uop 真正要发的访问数：逐元素拆的数 flowMask 里的 1，unit-stride 数 0/1/2
  always_comb begin
    logic [4:0] popcount;
    popcount = 5'd0;
    for (int i = 0; i < VLENB; i++) popcount = popcount + 5'(s1_in.flowMask[i]);
    s1_activeNum = s1_in.preIsSplit ? popcount : s1_usActiveNum;
  end

  // ---- 向合并缓冲申请条目（只有下游能收时才申请，免得白占条目）----
  assign toMergeBuffer_req_valid = out_ready & s1_valid & ~s1_in.isVecPartReplay;
  always_comb begin
    toMergeBuffer_req            = '0;
    toMergeBuffer_req.uop        = s1_in.uop;
    toMergeBuffer_req.uop.vpu_nf = s1_in.rawNf;
    toMergeBuffer_req.flowNum    = s1_activeNum;
    toMergeBuffer_req.data       = s1_in.data;
    toMergeBuffer_req.mask       = s1_isSpecialIndexed ? s1_in.indexedSrcMask : s1_in.flowMask;
    toMergeBuffer_req.vaddr      = s1_in.baseAddr[49:0];
    toMergeBuffer_req.vdIdx      = s1_in.vdIdxInField;
    toMergeBuffer_req.fof        = s1_in.fof;
    toMergeBuffer_req.vlmax      = s1_in.vlmax;
  end

  // ---- 交给拆分缓冲 ----
  assign out_valid = s1_valid & (toMergeBuffer_resp_valid | s1_in.isVecPartReplay);
  always_comb begin
    out               = s1_in;
    out.uopAddr       = s1_in.baseAddr + s1_uopOffset;
    out.stride        = s1_stride;
    out.mBIndex       = s1_in.isVecPartReplay ? s1_in.vecReplayMbIdx : toMergeBuffer_resp_bits_mBIndex;
    out.usLowBitsAddr = s1_usLowBitsAddr;
    out.usAligned128  = (s1_usLowBitsAddr == 4'b0);
    out.usMask        = s1_usMask;
    out.uop.vpu_nf    = s1_in.rawNf;
  end

endmodule

// =====================================================================
// VLSplitPipelineImp —— golden 同名 wrapper（load 变体，生成）：
//   扁平端口 ↔ struct 拆装 + s1 入口整包寄存器（字段集合照 golden）
// =====================================================================
// BEGIN GENERATED(wrapper_VLSplitPipelineImp) —— scripts/gen_vsplit.py 生成，勿手改
module VLSplitPipelineImp
  import vlsu_pkg::*;
(
  input          clock,
  input          reset,
  input          io_redirect_valid,
  input          io_redirect_bits_robIdx_flag,
  input  [7:0]   io_redirect_bits_robIdx_value,
  input          io_redirect_bits_level,
  output         io_in_ready,
  input          io_in_valid,
  input  [49:0]  io_in_bits_uop_pc,
  input          io_in_bits_uop_ftqPtr_flag,
  input  [5:0]   io_in_bits_uop_ftqPtr_value,
  input  [3:0]   io_in_bits_uop_ftqOffset,
  input  [34:0]  io_in_bits_uop_fuType,
  input  [8:0]   io_in_bits_uop_fuOpType,
  input          io_in_bits_uop_vecWen,
  input          io_in_bits_uop_v0Wen,
  input          io_in_bits_uop_vlWen,
  input          io_in_bits_uop_vpu_vill,
  input          io_in_bits_uop_vpu_vma,
  input          io_in_bits_uop_vpu_vta,
  input  [1:0]   io_in_bits_uop_vpu_vsew,
  input  [2:0]   io_in_bits_uop_vpu_vlmul,
  input          io_in_bits_uop_vpu_specVill,
  input          io_in_bits_uop_vpu_specVma,
  input          io_in_bits_uop_vpu_specVta,
  input  [1:0]   io_in_bits_uop_vpu_specVsew,
  input  [2:0]   io_in_bits_uop_vpu_specVlmul,
  input          io_in_bits_uop_vpu_vm,
  input  [7:0]   io_in_bits_uop_vpu_vstart,
  input  [2:0]   io_in_bits_uop_vpu_frm,
  input          io_in_bits_uop_vpu_fpu_isFpToVecInst,
  input          io_in_bits_uop_vpu_fpu_isFP32Instr,
  input          io_in_bits_uop_vpu_fpu_isFP64Instr,
  input          io_in_bits_uop_vpu_fpu_isReduction,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_2,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_4,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_in_bits_uop_vpu_vxrm,
  input  [6:0]   io_in_bits_uop_vpu_vuopIdx,
  input          io_in_bits_uop_vpu_lastUop,
  input  [127:0] io_in_bits_uop_vpu_vmask,
  input  [2:0]   io_in_bits_uop_vpu_nf,
  input  [1:0]   io_in_bits_uop_vpu_veew,
  input          io_in_bits_uop_vpu_isReverse,
  input          io_in_bits_uop_vpu_isExt,
  input          io_in_bits_uop_vpu_isNarrow,
  input          io_in_bits_uop_vpu_isDstMask,
  input          io_in_bits_uop_vpu_isOpMask,
  input          io_in_bits_uop_vpu_isMove,
  input          io_in_bits_uop_vpu_isDependOldVd,
  input          io_in_bits_uop_vpu_isWritePartVd,
  input          io_in_bits_uop_vpu_isVleff,
  input  [7:0]   io_in_bits_uop_pdest,
  input          io_in_bits_uop_robIdx_flag,
  input  [7:0]   io_in_bits_uop_robIdx_value,
  input          io_in_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_uop_debugInfo_renameTime,
  input  [63:0]  io_in_bits_uop_debugInfo_dispatchTime,
  input  [63:0]  io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_bits_uop_debugInfo_issueTime,
  input  [63:0]  io_in_bits_uop_debugInfo_writebackTime,
  input  [63:0]  io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_uop_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_uop_debug_seqNum_uopIdx,
  input          io_in_bits_uop_lqIdx_flag,
  input  [6:0]   io_in_bits_uop_lqIdx_value,
  input          io_in_bits_uop_sqIdx_flag,
  input  [5:0]   io_in_bits_uop_sqIdx_value,
  input  [4:0]   io_in_bits_uop_numLsElem,
  input  [127:0] io_in_bits_src_0,
  input  [127:0] io_in_bits_src_1,
  input  [127:0] io_in_bits_src_2,
  input  [127:0] io_in_bits_src_3,
  input  [127:0] io_in_bits_src_4,
  input  [4:0]   io_in_bits_flowNum,
  input          io_in_bits_isVecPartReplay,
  input  [15:0]  io_in_bits_vecReplayMask,
  input  [3:0]   io_in_bits_vecReplayMbIdx,
  input          io_toMergeBuffer_req_ready,
  output         io_toMergeBuffer_req_valid,
  output [15:0]  io_toMergeBuffer_req_bits_mask,
  output [49:0]  io_toMergeBuffer_req_bits_vaddr,
  output [4:0]   io_toMergeBuffer_req_bits_flowNum,
  output [8:0]   io_toMergeBuffer_req_bits_uop_fuOpType,
  output         io_toMergeBuffer_req_bits_uop_vecWen,
  output         io_toMergeBuffer_req_bits_uop_v0Wen,
  output         io_toMergeBuffer_req_bits_uop_vlWen,
  output         io_toMergeBuffer_req_bits_uop_vpu_vill,
  output         io_toMergeBuffer_req_bits_uop_vpu_vma,
  output         io_toMergeBuffer_req_bits_uop_vpu_vta,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_vsew,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_vlmul,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVill,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVma,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVta,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_specVsew,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_specVlmul,
  output         io_toMergeBuffer_req_bits_uop_vpu_vm,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_frm,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_vxrm,
  output [6:0]   io_toMergeBuffer_req_bits_uop_vpu_vuopIdx,
  output         io_toMergeBuffer_req_bits_uop_vpu_lastUop,
  output [7:0]   io_toMergeBuffer_req_bits_uop_vpu_vl,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_nf,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_veew,
  output         io_toMergeBuffer_req_bits_uop_vpu_isReverse,
  output         io_toMergeBuffer_req_bits_uop_vpu_isExt,
  output         io_toMergeBuffer_req_bits_uop_vpu_isNarrow,
  output         io_toMergeBuffer_req_bits_uop_vpu_isDstMask,
  output         io_toMergeBuffer_req_bits_uop_vpu_isOpMask,
  output         io_toMergeBuffer_req_bits_uop_vpu_isMove,
  output         io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd,
  output         io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd,
  output         io_toMergeBuffer_req_bits_uop_vpu_isVleff,
  output [6:0]   io_toMergeBuffer_req_bits_uop_uopIdx,
  output [7:0]   io_toMergeBuffer_req_bits_uop_pdest,
  output         io_toMergeBuffer_req_bits_uop_robIdx_flag,
  output [7:0]   io_toMergeBuffer_req_bits_uop_robIdx_value,
  output         io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_renameTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_selectTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_issueTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime,
  output [55:0]  io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum,
  output [7:0]   io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx,
  output         io_toMergeBuffer_req_bits_uop_lqIdx_flag,
  output [6:0]   io_toMergeBuffer_req_bits_uop_lqIdx_value,
  output         io_toMergeBuffer_req_bits_uop_sqIdx_flag,
  output [5:0]   io_toMergeBuffer_req_bits_uop_sqIdx_value,
  output [127:0] io_toMergeBuffer_req_bits_data,
  output [2:0]   io_toMergeBuffer_req_bits_vdIdx,
  output         io_toMergeBuffer_req_bits_fof,
  output [7:0]   io_toMergeBuffer_req_bits_vlmax,
  input          io_toMergeBuffer_resp_valid,
  input  [3:0]   io_toMergeBuffer_resp_bits_mBIndex,
  input          io_out_ready,
  output         io_out_valid,
  output [15:0]  io_out_bits_flowMask,
  output [127:0] io_out_bits_data,
  output [63:0]  io_out_bits_baseAddr,
  output [63:0]  io_out_bits_uopAddr,
  output [127:0] io_out_bits_stride,
  output [4:0]   io_out_bits_flowNum,
  output [1:0]   io_out_bits_eew,
  output [2:0]   io_out_bits_sew,
  output [2:0]   io_out_bits_emul,
  output [2:0]   io_out_bits_lmul,
  output [2:0]   io_out_bits_instType,
  output [4:0]   io_out_bits_indexedSplitOffset,
  output [49:0]  io_out_bits_uop_pc,
  output         io_out_bits_uop_ftqPtr_flag,
  output [5:0]   io_out_bits_uop_ftqPtr_value,
  output [3:0]   io_out_bits_uop_ftqOffset,
  output [34:0]  io_out_bits_uop_fuType,
  output [8:0]   io_out_bits_uop_fuOpType,
  output         io_out_bits_uop_vecWen,
  output         io_out_bits_uop_v0Wen,
  output         io_out_bits_uop_vlWen,
  output         io_out_bits_uop_vpu_vill,
  output         io_out_bits_uop_vpu_vma,
  output         io_out_bits_uop_vpu_vta,
  output [1:0]   io_out_bits_uop_vpu_vsew,
  output [2:0]   io_out_bits_uop_vpu_vlmul,
  output         io_out_bits_uop_vpu_specVill,
  output         io_out_bits_uop_vpu_specVma,
  output         io_out_bits_uop_vpu_specVta,
  output [1:0]   io_out_bits_uop_vpu_specVsew,
  output [2:0]   io_out_bits_uop_vpu_specVlmul,
  output         io_out_bits_uop_vpu_vm,
  output [7:0]   io_out_bits_uop_vpu_vstart,
  output [2:0]   io_out_bits_uop_vpu_frm,
  output         io_out_bits_uop_vpu_fpu_isFpToVecInst,
  output         io_out_bits_uop_vpu_fpu_isFP32Instr,
  output         io_out_bits_uop_vpu_fpu_isFP64Instr,
  output         io_out_bits_uop_vpu_fpu_isReduction,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_2,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_4,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_out_bits_uop_vpu_vxrm,
  output [6:0]   io_out_bits_uop_vpu_vuopIdx,
  output         io_out_bits_uop_vpu_lastUop,
  output [127:0] io_out_bits_uop_vpu_vmask,
  output [7:0]   io_out_bits_uop_vpu_vl,
  output [2:0]   io_out_bits_uop_vpu_nf,
  output [1:0]   io_out_bits_uop_vpu_veew,
  output         io_out_bits_uop_vpu_isReverse,
  output         io_out_bits_uop_vpu_isExt,
  output         io_out_bits_uop_vpu_isNarrow,
  output         io_out_bits_uop_vpu_isDstMask,
  output         io_out_bits_uop_vpu_isOpMask,
  output         io_out_bits_uop_vpu_isMove,
  output         io_out_bits_uop_vpu_isDependOldVd,
  output         io_out_bits_uop_vpu_isWritePartVd,
  output         io_out_bits_uop_vpu_isVleff,
  output [6:0]   io_out_bits_uop_uopIdx,
  output         io_out_bits_uop_lastUop,
  output [6:0]   io_out_bits_uop_numUops,
  output [7:0]   io_out_bits_uop_pdest,
  output         io_out_bits_uop_robIdx_flag,
  output [7:0]   io_out_bits_uop_robIdx_value,
  output         io_out_bits_uop_debugInfo_eliminatedMove,
  output [63:0]  io_out_bits_uop_debugInfo_renameTime,
  output [63:0]  io_out_bits_uop_debugInfo_dispatchTime,
  output [63:0]  io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_out_bits_uop_debugInfo_selectTime,
  output [63:0]  io_out_bits_uop_debugInfo_issueTime,
  output [63:0]  io_out_bits_uop_debugInfo_writebackTime,
  output [63:0]  io_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_uop_debugInfo_tlbRespTime,
  output [55:0]  io_out_bits_uop_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_uop_debug_seqNum_uopIdx,
  output         io_out_bits_uop_lqIdx_flag,
  output [6:0]   io_out_bits_uop_lqIdx_value,
  output         io_out_bits_uop_sqIdx_flag,
  output [5:0]   io_out_bits_uop_sqIdx_value,
  output [4:0]   io_out_bits_uop_numLsElem,
  output         io_out_bits_preIsSplit,
  output [3:0]   io_out_bits_mBIndex,
  output [2:0]   io_out_bits_alignedType,
  output [7:0]   io_out_bits_indexVlMaxInVd,
  output [3:0]   io_out_bits_usLowBitsAddr,
  output         io_out_bits_usAligned128,
  output [31:0]  io_out_bits_usMask,
  output         io_out_bits_isVecPartReplay,
  output [15:0]  io_out_bits_vecReplayFlowMask,
  input          io_threshold_valid,
  input          io_threshold_bits_robIdx_flag,
  input  [7:0]   io_threshold_bits_robIdx_value,
  input  [6:0]   io_threshold_bits_uopIdx
);

  split_in_t     in;
  always_comb begin
    in = '0;
    in.uop.pc = io_in_bits_uop_pc;
    in.uop.ftqPtr_flag = io_in_bits_uop_ftqPtr_flag;
    in.uop.ftqPtr_value = io_in_bits_uop_ftqPtr_value;
    in.uop.ftqOffset = io_in_bits_uop_ftqOffset;
    in.uop.fuType = io_in_bits_uop_fuType;
    in.uop.fuOpType = io_in_bits_uop_fuOpType;
    in.uop.vecWen = io_in_bits_uop_vecWen;
    in.uop.v0Wen = io_in_bits_uop_v0Wen;
    in.uop.vlWen = io_in_bits_uop_vlWen;
    in.uop.vpu_vill = io_in_bits_uop_vpu_vill;
    in.uop.vpu_vma = io_in_bits_uop_vpu_vma;
    in.uop.vpu_vta = io_in_bits_uop_vpu_vta;
    in.uop.vpu_vsew = io_in_bits_uop_vpu_vsew;
    in.uop.vpu_vlmul = io_in_bits_uop_vpu_vlmul;
    in.uop.vpu_specVill = io_in_bits_uop_vpu_specVill;
    in.uop.vpu_specVma = io_in_bits_uop_vpu_specVma;
    in.uop.vpu_specVta = io_in_bits_uop_vpu_specVta;
    in.uop.vpu_specVsew = io_in_bits_uop_vpu_specVsew;
    in.uop.vpu_specVlmul = io_in_bits_uop_vpu_specVlmul;
    in.uop.vpu_vm = io_in_bits_uop_vpu_vm;
    in.uop.vpu_vstart = io_in_bits_uop_vpu_vstart;
    in.uop.vpu_frm = io_in_bits_uop_vpu_frm;
    in.uop.vpu_fpu_isFpToVecInst = io_in_bits_uop_vpu_fpu_isFpToVecInst;
    in.uop.vpu_fpu_isFP32Instr = io_in_bits_uop_vpu_fpu_isFP32Instr;
    in.uop.vpu_fpu_isFP64Instr = io_in_bits_uop_vpu_fpu_isFP64Instr;
    in.uop.vpu_fpu_isReduction = io_in_bits_uop_vpu_fpu_isReduction;
    in.uop.vpu_fpu_isFoldTo1_2 = io_in_bits_uop_vpu_fpu_isFoldTo1_2;
    in.uop.vpu_fpu_isFoldTo1_4 = io_in_bits_uop_vpu_fpu_isFoldTo1_4;
    in.uop.vpu_fpu_isFoldTo1_8 = io_in_bits_uop_vpu_fpu_isFoldTo1_8;
    in.uop.vpu_vxrm = io_in_bits_uop_vpu_vxrm;
    in.uop.vpu_vuopIdx = io_in_bits_uop_vpu_vuopIdx;
    in.uop.vpu_lastUop = io_in_bits_uop_vpu_lastUop;
    in.uop.vpu_vmask = io_in_bits_uop_vpu_vmask;
    in.uop.vpu_nf = io_in_bits_uop_vpu_nf;
    in.uop.vpu_veew = io_in_bits_uop_vpu_veew;
    in.uop.vpu_isReverse = io_in_bits_uop_vpu_isReverse;
    in.uop.vpu_isExt = io_in_bits_uop_vpu_isExt;
    in.uop.vpu_isNarrow = io_in_bits_uop_vpu_isNarrow;
    in.uop.vpu_isDstMask = io_in_bits_uop_vpu_isDstMask;
    in.uop.vpu_isOpMask = io_in_bits_uop_vpu_isOpMask;
    in.uop.vpu_isMove = io_in_bits_uop_vpu_isMove;
    in.uop.vpu_isDependOldVd = io_in_bits_uop_vpu_isDependOldVd;
    in.uop.vpu_isWritePartVd = io_in_bits_uop_vpu_isWritePartVd;
    in.uop.vpu_isVleff = io_in_bits_uop_vpu_isVleff;
    in.uop.pdest = io_in_bits_uop_pdest;
    in.uop.robIdx_flag = io_in_bits_uop_robIdx_flag;
    in.uop.robIdx_value = io_in_bits_uop_robIdx_value;
    in.uop.debugInfo_eliminatedMove = io_in_bits_uop_debugInfo_eliminatedMove;
    in.uop.debugInfo_renameTime = io_in_bits_uop_debugInfo_renameTime;
    in.uop.debugInfo_dispatchTime = io_in_bits_uop_debugInfo_dispatchTime;
    in.uop.debugInfo_enqRsTime = io_in_bits_uop_debugInfo_enqRsTime;
    in.uop.debugInfo_selectTime = io_in_bits_uop_debugInfo_selectTime;
    in.uop.debugInfo_issueTime = io_in_bits_uop_debugInfo_issueTime;
    in.uop.debugInfo_writebackTime = io_in_bits_uop_debugInfo_writebackTime;
    in.uop.debugInfo_runahead_checkpoint_id = io_in_bits_uop_debugInfo_runahead_checkpoint_id;
    in.uop.debugInfo_tlbFirstReqTime = io_in_bits_uop_debugInfo_tlbFirstReqTime;
    in.uop.debugInfo_tlbRespTime = io_in_bits_uop_debugInfo_tlbRespTime;
    in.uop.debug_seqNum_seqNum = io_in_bits_uop_debug_seqNum_seqNum;
    in.uop.debug_seqNum_uopIdx = io_in_bits_uop_debug_seqNum_uopIdx;
    in.uop.lqIdx_flag = io_in_bits_uop_lqIdx_flag;
    in.uop.lqIdx_value = io_in_bits_uop_lqIdx_value;
    in.uop.sqIdx_flag = io_in_bits_uop_sqIdx_flag;
    in.uop.sqIdx_value = io_in_bits_uop_sqIdx_value;
    in.uop.numLsElem = io_in_bits_uop_numLsElem;
    in.src_0 = io_in_bits_src_0;
    in.src_1 = io_in_bits_src_1;
    in.src_2 = io_in_bits_src_2;
    in.src_3 = io_in_bits_src_3;
    in.src_4 = io_in_bits_src_4;
    in.flowNum = io_in_bits_flowNum;
    in.isVecPartReplay = io_in_bits_isVecPartReplay;
    in.vecReplayMask = io_in_bits_vecReplayMask;
    in.vecReplayMbIdx = io_in_bits_vecReplayMbIdx;
  end

  merge_req_t    toMergeBuffer_req;
  assign io_toMergeBuffer_req_bits_mask = toMergeBuffer_req.mask;
  assign io_toMergeBuffer_req_bits_vaddr = toMergeBuffer_req.vaddr;
  assign io_toMergeBuffer_req_bits_flowNum = toMergeBuffer_req.flowNum;
  assign io_toMergeBuffer_req_bits_uop_fuOpType = toMergeBuffer_req.uop.fuOpType;
  assign io_toMergeBuffer_req_bits_uop_vecWen = toMergeBuffer_req.uop.vecWen;
  assign io_toMergeBuffer_req_bits_uop_v0Wen = toMergeBuffer_req.uop.v0Wen;
  assign io_toMergeBuffer_req_bits_uop_vlWen = toMergeBuffer_req.uop.vlWen;
  assign io_toMergeBuffer_req_bits_uop_vpu_vill = toMergeBuffer_req.uop.vpu_vill;
  assign io_toMergeBuffer_req_bits_uop_vpu_vma = toMergeBuffer_req.uop.vpu_vma;
  assign io_toMergeBuffer_req_bits_uop_vpu_vta = toMergeBuffer_req.uop.vpu_vta;
  assign io_toMergeBuffer_req_bits_uop_vpu_vsew = toMergeBuffer_req.uop.vpu_vsew;
  assign io_toMergeBuffer_req_bits_uop_vpu_vlmul = toMergeBuffer_req.uop.vpu_vlmul;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVill = toMergeBuffer_req.uop.vpu_specVill;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVma = toMergeBuffer_req.uop.vpu_specVma;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVta = toMergeBuffer_req.uop.vpu_specVta;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVsew = toMergeBuffer_req.uop.vpu_specVsew;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVlmul = toMergeBuffer_req.uop.vpu_specVlmul;
  assign io_toMergeBuffer_req_bits_uop_vpu_vm = toMergeBuffer_req.uop.vpu_vm;
  assign io_toMergeBuffer_req_bits_uop_vpu_frm = toMergeBuffer_req.uop.vpu_frm;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst = toMergeBuffer_req.uop.vpu_fpu_isFpToVecInst;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr = toMergeBuffer_req.uop.vpu_fpu_isFP32Instr;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr = toMergeBuffer_req.uop.vpu_fpu_isFP64Instr;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction = toMergeBuffer_req.uop.vpu_fpu_isReduction;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2 = toMergeBuffer_req.uop.vpu_fpu_isFoldTo1_2;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4 = toMergeBuffer_req.uop.vpu_fpu_isFoldTo1_4;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8 = toMergeBuffer_req.uop.vpu_fpu_isFoldTo1_8;
  assign io_toMergeBuffer_req_bits_uop_vpu_vxrm = toMergeBuffer_req.uop.vpu_vxrm;
  assign io_toMergeBuffer_req_bits_uop_vpu_vuopIdx = toMergeBuffer_req.uop.vpu_vuopIdx;
  assign io_toMergeBuffer_req_bits_uop_vpu_lastUop = toMergeBuffer_req.uop.vpu_lastUop;
  assign io_toMergeBuffer_req_bits_uop_vpu_vl = toMergeBuffer_req.uop.vpu_vl;
  assign io_toMergeBuffer_req_bits_uop_vpu_nf = toMergeBuffer_req.uop.vpu_nf;
  assign io_toMergeBuffer_req_bits_uop_vpu_veew = toMergeBuffer_req.uop.vpu_veew;
  assign io_toMergeBuffer_req_bits_uop_vpu_isReverse = toMergeBuffer_req.uop.vpu_isReverse;
  assign io_toMergeBuffer_req_bits_uop_vpu_isExt = toMergeBuffer_req.uop.vpu_isExt;
  assign io_toMergeBuffer_req_bits_uop_vpu_isNarrow = toMergeBuffer_req.uop.vpu_isNarrow;
  assign io_toMergeBuffer_req_bits_uop_vpu_isDstMask = toMergeBuffer_req.uop.vpu_isDstMask;
  assign io_toMergeBuffer_req_bits_uop_vpu_isOpMask = toMergeBuffer_req.uop.vpu_isOpMask;
  assign io_toMergeBuffer_req_bits_uop_vpu_isMove = toMergeBuffer_req.uop.vpu_isMove;
  assign io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd = toMergeBuffer_req.uop.vpu_isDependOldVd;
  assign io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd = toMergeBuffer_req.uop.vpu_isWritePartVd;
  assign io_toMergeBuffer_req_bits_uop_vpu_isVleff = toMergeBuffer_req.uop.vpu_isVleff;
  assign io_toMergeBuffer_req_bits_uop_uopIdx = toMergeBuffer_req.uop.uopIdx;
  assign io_toMergeBuffer_req_bits_uop_pdest = toMergeBuffer_req.uop.pdest;
  assign io_toMergeBuffer_req_bits_uop_robIdx_flag = toMergeBuffer_req.uop.robIdx_flag;
  assign io_toMergeBuffer_req_bits_uop_robIdx_value = toMergeBuffer_req.uop.robIdx_value;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove = toMergeBuffer_req.uop.debugInfo_eliminatedMove;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_renameTime = toMergeBuffer_req.uop.debugInfo_renameTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime = toMergeBuffer_req.uop.debugInfo_dispatchTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime = toMergeBuffer_req.uop.debugInfo_enqRsTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_selectTime = toMergeBuffer_req.uop.debugInfo_selectTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_issueTime = toMergeBuffer_req.uop.debugInfo_issueTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime = toMergeBuffer_req.uop.debugInfo_writebackTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id = toMergeBuffer_req.uop.debugInfo_runahead_checkpoint_id;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime = toMergeBuffer_req.uop.debugInfo_tlbFirstReqTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime = toMergeBuffer_req.uop.debugInfo_tlbRespTime;
  assign io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum = toMergeBuffer_req.uop.debug_seqNum_seqNum;
  assign io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx = toMergeBuffer_req.uop.debug_seqNum_uopIdx;
  assign io_toMergeBuffer_req_bits_uop_lqIdx_flag = toMergeBuffer_req.uop.lqIdx_flag;
  assign io_toMergeBuffer_req_bits_uop_lqIdx_value = toMergeBuffer_req.uop.lqIdx_value;
  assign io_toMergeBuffer_req_bits_uop_sqIdx_flag = toMergeBuffer_req.uop.sqIdx_flag;
  assign io_toMergeBuffer_req_bits_uop_sqIdx_value = toMergeBuffer_req.uop.sqIdx_value;
  assign io_toMergeBuffer_req_bits_data = toMergeBuffer_req.data;
  assign io_toMergeBuffer_req_bits_vdIdx = toMergeBuffer_req.vdIdx;
  assign io_toMergeBuffer_req_bits_fof = toMergeBuffer_req.fof;
  assign io_toMergeBuffer_req_bits_vlmax = toMergeBuffer_req.vlmax;

  vls_t          out;
  assign io_out_bits_flowMask = out.flowMask;
  assign io_out_bits_data = out.data;
  assign io_out_bits_baseAddr = out.baseAddr;
  assign io_out_bits_uopAddr = out.uopAddr;
  assign io_out_bits_stride = out.stride;
  assign io_out_bits_flowNum = out.flowNum;
  assign io_out_bits_eew = out.eew;
  assign io_out_bits_sew = out.sew;
  assign io_out_bits_emul = out.emul;
  assign io_out_bits_lmul = out.lmul;
  assign io_out_bits_instType = out.instType;
  assign io_out_bits_indexedSplitOffset = out.indexedSplitOffset;
  assign io_out_bits_uop_pc = out.uop.pc;
  assign io_out_bits_uop_ftqPtr_flag = out.uop.ftqPtr_flag;
  assign io_out_bits_uop_ftqPtr_value = out.uop.ftqPtr_value;
  assign io_out_bits_uop_ftqOffset = out.uop.ftqOffset;
  assign io_out_bits_uop_fuType = out.uop.fuType;
  assign io_out_bits_uop_fuOpType = out.uop.fuOpType;
  assign io_out_bits_uop_vecWen = out.uop.vecWen;
  assign io_out_bits_uop_v0Wen = out.uop.v0Wen;
  assign io_out_bits_uop_vlWen = out.uop.vlWen;
  assign io_out_bits_uop_vpu_vill = out.uop.vpu_vill;
  assign io_out_bits_uop_vpu_vma = out.uop.vpu_vma;
  assign io_out_bits_uop_vpu_vta = out.uop.vpu_vta;
  assign io_out_bits_uop_vpu_vsew = out.uop.vpu_vsew;
  assign io_out_bits_uop_vpu_vlmul = out.uop.vpu_vlmul;
  assign io_out_bits_uop_vpu_specVill = out.uop.vpu_specVill;
  assign io_out_bits_uop_vpu_specVma = out.uop.vpu_specVma;
  assign io_out_bits_uop_vpu_specVta = out.uop.vpu_specVta;
  assign io_out_bits_uop_vpu_specVsew = out.uop.vpu_specVsew;
  assign io_out_bits_uop_vpu_specVlmul = out.uop.vpu_specVlmul;
  assign io_out_bits_uop_vpu_vm = out.uop.vpu_vm;
  assign io_out_bits_uop_vpu_vstart = out.uop.vpu_vstart;
  assign io_out_bits_uop_vpu_frm = out.uop.vpu_frm;
  assign io_out_bits_uop_vpu_fpu_isFpToVecInst = out.uop.vpu_fpu_isFpToVecInst;
  assign io_out_bits_uop_vpu_fpu_isFP32Instr = out.uop.vpu_fpu_isFP32Instr;
  assign io_out_bits_uop_vpu_fpu_isFP64Instr = out.uop.vpu_fpu_isFP64Instr;
  assign io_out_bits_uop_vpu_fpu_isReduction = out.uop.vpu_fpu_isReduction;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_2 = out.uop.vpu_fpu_isFoldTo1_2;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_4 = out.uop.vpu_fpu_isFoldTo1_4;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_8 = out.uop.vpu_fpu_isFoldTo1_8;
  assign io_out_bits_uop_vpu_vxrm = out.uop.vpu_vxrm;
  assign io_out_bits_uop_vpu_vuopIdx = out.uop.vpu_vuopIdx;
  assign io_out_bits_uop_vpu_lastUop = out.uop.vpu_lastUop;
  assign io_out_bits_uop_vpu_vmask = out.uop.vpu_vmask;
  assign io_out_bits_uop_vpu_vl = out.uop.vpu_vl;
  assign io_out_bits_uop_vpu_nf = out.uop.vpu_nf;
  assign io_out_bits_uop_vpu_veew = out.uop.vpu_veew;
  assign io_out_bits_uop_vpu_isReverse = out.uop.vpu_isReverse;
  assign io_out_bits_uop_vpu_isExt = out.uop.vpu_isExt;
  assign io_out_bits_uop_vpu_isNarrow = out.uop.vpu_isNarrow;
  assign io_out_bits_uop_vpu_isDstMask = out.uop.vpu_isDstMask;
  assign io_out_bits_uop_vpu_isOpMask = out.uop.vpu_isOpMask;
  assign io_out_bits_uop_vpu_isMove = out.uop.vpu_isMove;
  assign io_out_bits_uop_vpu_isDependOldVd = out.uop.vpu_isDependOldVd;
  assign io_out_bits_uop_vpu_isWritePartVd = out.uop.vpu_isWritePartVd;
  assign io_out_bits_uop_vpu_isVleff = out.uop.vpu_isVleff;
  assign io_out_bits_uop_uopIdx = out.uop.uopIdx;
  assign io_out_bits_uop_lastUop = out.uop.lastUop;
  assign io_out_bits_uop_numUops = out.uop.numUops;
  assign io_out_bits_uop_pdest = out.uop.pdest;
  assign io_out_bits_uop_robIdx_flag = out.uop.robIdx_flag;
  assign io_out_bits_uop_robIdx_value = out.uop.robIdx_value;
  assign io_out_bits_uop_debugInfo_eliminatedMove = out.uop.debugInfo_eliminatedMove;
  assign io_out_bits_uop_debugInfo_renameTime = out.uop.debugInfo_renameTime;
  assign io_out_bits_uop_debugInfo_dispatchTime = out.uop.debugInfo_dispatchTime;
  assign io_out_bits_uop_debugInfo_enqRsTime = out.uop.debugInfo_enqRsTime;
  assign io_out_bits_uop_debugInfo_selectTime = out.uop.debugInfo_selectTime;
  assign io_out_bits_uop_debugInfo_issueTime = out.uop.debugInfo_issueTime;
  assign io_out_bits_uop_debugInfo_writebackTime = out.uop.debugInfo_writebackTime;
  assign io_out_bits_uop_debugInfo_runahead_checkpoint_id = out.uop.debugInfo_runahead_checkpoint_id;
  assign io_out_bits_uop_debugInfo_tlbFirstReqTime = out.uop.debugInfo_tlbFirstReqTime;
  assign io_out_bits_uop_debugInfo_tlbRespTime = out.uop.debugInfo_tlbRespTime;
  assign io_out_bits_uop_debug_seqNum_seqNum = out.uop.debug_seqNum_seqNum;
  assign io_out_bits_uop_debug_seqNum_uopIdx = out.uop.debug_seqNum_uopIdx;
  assign io_out_bits_uop_lqIdx_flag = out.uop.lqIdx_flag;
  assign io_out_bits_uop_lqIdx_value = out.uop.lqIdx_value;
  assign io_out_bits_uop_sqIdx_flag = out.uop.sqIdx_flag;
  assign io_out_bits_uop_sqIdx_value = out.uop.sqIdx_value;
  assign io_out_bits_uop_numLsElem = out.uop.numLsElem;
  assign io_out_bits_preIsSplit = out.preIsSplit;
  assign io_out_bits_mBIndex = out.mBIndex;
  assign io_out_bits_alignedType = out.alignedType;
  assign io_out_bits_indexVlMaxInVd = out.indexVlMaxInVd;
  assign io_out_bits_usLowBitsAddr = out.usLowBitsAddr;
  assign io_out_bits_usAligned128 = out.usAligned128;
  assign io_out_bits_usMask = out.usMask;
  assign io_out_bits_isVecPartReplay = out.isVecPartReplay;
  assign io_out_bits_vecReplayFlowMask = out.vecReplayFlowMask;

  // ---- 核与寄存器之间的桥 ----
  vls_t          s0_out, s1_in;
  logic          s0_fire;

  // ---- s1_in <= s0_out（s0_fire 时整包打拍，无复位）：golden 留下的 92 个字段 ----
  logic          s1_in_r_isVecPartReplay;
  logic [15:0]   s1_in_r_flowMask;
  logic [15:0]   s1_in_r_byteMask;
  logic [127:0]  s1_in_r_data;
  logic [63:0]   s1_in_r_baseAddr;
  logic [127:0]  s1_in_r_stride;
  logic [4:0]    s1_in_r_flowNum;
  logic [3:0]    s1_in_r_nfields;
  logic [1:0]    s1_in_r_eew;
  logic [2:0]    s1_in_r_sew;
  logic [2:0]    s1_in_r_emul;
  logic [2:0]    s1_in_r_lmul;
  logic [7:0]    s1_in_r_vlmax;
  logic [2:0]    s1_in_r_instType;
  logic [2:0]    s1_in_r_rawNf;
  logic [15:0]   s1_in_r_indexedSrcMask;
  logic [4:0]    s1_in_r_indexedSplitOffset;
  logic [49:0]   s1_in_r_uop_pc;
  logic          s1_in_r_uop_ftqPtr_flag;
  logic [5:0]    s1_in_r_uop_ftqPtr_value;
  logic [3:0]    s1_in_r_uop_ftqOffset;
  logic [34:0]   s1_in_r_uop_fuType;
  logic [8:0]    s1_in_r_uop_fuOpType;
  logic          s1_in_r_uop_vecWen;
  logic          s1_in_r_uop_v0Wen;
  logic          s1_in_r_uop_vlWen;
  logic          s1_in_r_uop_vpu_vill;
  logic          s1_in_r_uop_vpu_vma;
  logic          s1_in_r_uop_vpu_vta;
  logic [1:0]    s1_in_r_uop_vpu_vsew;
  logic [2:0]    s1_in_r_uop_vpu_vlmul;
  logic          s1_in_r_uop_vpu_specVill;
  logic          s1_in_r_uop_vpu_specVma;
  logic          s1_in_r_uop_vpu_specVta;
  logic [1:0]    s1_in_r_uop_vpu_specVsew;
  logic [2:0]    s1_in_r_uop_vpu_specVlmul;
  logic          s1_in_r_uop_vpu_vm;
  logic [7:0]    s1_in_r_uop_vpu_vstart;
  logic [2:0]    s1_in_r_uop_vpu_frm;
  logic          s1_in_r_uop_vpu_fpu_isFpToVecInst;
  logic          s1_in_r_uop_vpu_fpu_isFP32Instr;
  logic          s1_in_r_uop_vpu_fpu_isFP64Instr;
  logic          s1_in_r_uop_vpu_fpu_isReduction;
  logic          s1_in_r_uop_vpu_fpu_isFoldTo1_2;
  logic          s1_in_r_uop_vpu_fpu_isFoldTo1_4;
  logic          s1_in_r_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    s1_in_r_uop_vpu_vxrm;
  logic [6:0]    s1_in_r_uop_vpu_vuopIdx;
  logic          s1_in_r_uop_vpu_lastUop;
  logic [127:0]  s1_in_r_uop_vpu_vmask;
  logic [7:0]    s1_in_r_uop_vpu_vl;
  logic [2:0]    s1_in_r_uop_vpu_nf;
  logic [1:0]    s1_in_r_uop_vpu_veew;
  logic          s1_in_r_uop_vpu_isReverse;
  logic          s1_in_r_uop_vpu_isExt;
  logic          s1_in_r_uop_vpu_isNarrow;
  logic          s1_in_r_uop_vpu_isDstMask;
  logic          s1_in_r_uop_vpu_isOpMask;
  logic          s1_in_r_uop_vpu_isMove;
  logic          s1_in_r_uop_vpu_isDependOldVd;
  logic          s1_in_r_uop_vpu_isWritePartVd;
  logic          s1_in_r_uop_vpu_isVleff;
  logic [6:0]    s1_in_r_uop_uopIdx;
  logic          s1_in_r_uop_lastUop;
  logic [6:0]    s1_in_r_uop_numUops;
  logic [7:0]    s1_in_r_uop_pdest;
  logic          s1_in_r_uop_robIdx_flag;
  logic [7:0]    s1_in_r_uop_robIdx_value;
  logic          s1_in_r_uop_debugInfo_eliminatedMove;
  logic [63:0]   s1_in_r_uop_debugInfo_renameTime;
  logic [63:0]   s1_in_r_uop_debugInfo_dispatchTime;
  logic [63:0]   s1_in_r_uop_debugInfo_enqRsTime;
  logic [63:0]   s1_in_r_uop_debugInfo_selectTime;
  logic [63:0]   s1_in_r_uop_debugInfo_issueTime;
  logic [63:0]   s1_in_r_uop_debugInfo_writebackTime;
  logic [63:0]   s1_in_r_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   s1_in_r_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   s1_in_r_uop_debugInfo_tlbRespTime;
  logic [55:0]   s1_in_r_uop_debug_seqNum_seqNum;
  logic [7:0]    s1_in_r_uop_debug_seqNum_uopIdx;
  logic          s1_in_r_uop_lqIdx_flag;
  logic [6:0]    s1_in_r_uop_lqIdx_value;
  logic          s1_in_r_uop_sqIdx_flag;
  logic [5:0]    s1_in_r_uop_sqIdx_value;
  logic [4:0]    s1_in_r_uop_numLsElem;
  logic          s1_in_r_fof;
  logic [2:0]    s1_in_r_vdIdxInField;
  logic          s1_in_r_preIsSplit;
  logic [2:0]    s1_in_r_alignedType;
  logic [7:0]    s1_in_r_indexVlMaxInVd;
  logic [3:0]    s1_in_r_vecReplayMbIdx;
  logic [15:0]   s1_in_r_vecReplayFlowMask;
  always_ff @(posedge clock) begin
    if (s0_fire) begin
      s1_in_r_isVecPartReplay <= s0_out.isVecPartReplay;
      s1_in_r_flowMask <= s0_out.flowMask;
      s1_in_r_byteMask <= s0_out.byteMask;
      s1_in_r_data <= s0_out.data;
      s1_in_r_baseAddr <= s0_out.baseAddr;
      s1_in_r_stride <= s0_out.stride;
      s1_in_r_flowNum <= s0_out.flowNum;
      s1_in_r_nfields <= s0_out.nfields;
      s1_in_r_eew <= s0_out.eew;
      s1_in_r_sew <= s0_out.sew;
      s1_in_r_emul <= s0_out.emul;
      s1_in_r_lmul <= s0_out.lmul;
      s1_in_r_vlmax <= s0_out.vlmax;
      s1_in_r_instType <= s0_out.instType;
      s1_in_r_rawNf <= s0_out.rawNf;
      s1_in_r_indexedSrcMask <= s0_out.indexedSrcMask;
      s1_in_r_indexedSplitOffset <= s0_out.indexedSplitOffset;
      s1_in_r_uop_pc <= s0_out.uop.pc;
      s1_in_r_uop_ftqPtr_flag <= s0_out.uop.ftqPtr_flag;
      s1_in_r_uop_ftqPtr_value <= s0_out.uop.ftqPtr_value;
      s1_in_r_uop_ftqOffset <= s0_out.uop.ftqOffset;
      s1_in_r_uop_fuType <= s0_out.uop.fuType;
      s1_in_r_uop_fuOpType <= s0_out.uop.fuOpType;
      s1_in_r_uop_vecWen <= s0_out.uop.vecWen;
      s1_in_r_uop_v0Wen <= s0_out.uop.v0Wen;
      s1_in_r_uop_vlWen <= s0_out.uop.vlWen;
      s1_in_r_uop_vpu_vill <= s0_out.uop.vpu_vill;
      s1_in_r_uop_vpu_vma <= s0_out.uop.vpu_vma;
      s1_in_r_uop_vpu_vta <= s0_out.uop.vpu_vta;
      s1_in_r_uop_vpu_vsew <= s0_out.uop.vpu_vsew;
      s1_in_r_uop_vpu_vlmul <= s0_out.uop.vpu_vlmul;
      s1_in_r_uop_vpu_specVill <= s0_out.uop.vpu_specVill;
      s1_in_r_uop_vpu_specVma <= s0_out.uop.vpu_specVma;
      s1_in_r_uop_vpu_specVta <= s0_out.uop.vpu_specVta;
      s1_in_r_uop_vpu_specVsew <= s0_out.uop.vpu_specVsew;
      s1_in_r_uop_vpu_specVlmul <= s0_out.uop.vpu_specVlmul;
      s1_in_r_uop_vpu_vm <= s0_out.uop.vpu_vm;
      s1_in_r_uop_vpu_vstart <= s0_out.uop.vpu_vstart;
      s1_in_r_uop_vpu_frm <= s0_out.uop.vpu_frm;
      s1_in_r_uop_vpu_fpu_isFpToVecInst <= s0_out.uop.vpu_fpu_isFpToVecInst;
      s1_in_r_uop_vpu_fpu_isFP32Instr <= s0_out.uop.vpu_fpu_isFP32Instr;
      s1_in_r_uop_vpu_fpu_isFP64Instr <= s0_out.uop.vpu_fpu_isFP64Instr;
      s1_in_r_uop_vpu_fpu_isReduction <= s0_out.uop.vpu_fpu_isReduction;
      s1_in_r_uop_vpu_fpu_isFoldTo1_2 <= s0_out.uop.vpu_fpu_isFoldTo1_2;
      s1_in_r_uop_vpu_fpu_isFoldTo1_4 <= s0_out.uop.vpu_fpu_isFoldTo1_4;
      s1_in_r_uop_vpu_fpu_isFoldTo1_8 <= s0_out.uop.vpu_fpu_isFoldTo1_8;
      s1_in_r_uop_vpu_vxrm <= s0_out.uop.vpu_vxrm;
      s1_in_r_uop_vpu_vuopIdx <= s0_out.uop.vpu_vuopIdx;
      s1_in_r_uop_vpu_lastUop <= s0_out.uop.vpu_lastUop;
      s1_in_r_uop_vpu_vmask <= s0_out.uop.vpu_vmask;
      s1_in_r_uop_vpu_vl <= s0_out.uop.vpu_vl;
      s1_in_r_uop_vpu_nf <= s0_out.uop.vpu_nf;
      s1_in_r_uop_vpu_veew <= s0_out.uop.vpu_veew;
      s1_in_r_uop_vpu_isReverse <= s0_out.uop.vpu_isReverse;
      s1_in_r_uop_vpu_isExt <= s0_out.uop.vpu_isExt;
      s1_in_r_uop_vpu_isNarrow <= s0_out.uop.vpu_isNarrow;
      s1_in_r_uop_vpu_isDstMask <= s0_out.uop.vpu_isDstMask;
      s1_in_r_uop_vpu_isOpMask <= s0_out.uop.vpu_isOpMask;
      s1_in_r_uop_vpu_isMove <= s0_out.uop.vpu_isMove;
      s1_in_r_uop_vpu_isDependOldVd <= s0_out.uop.vpu_isDependOldVd;
      s1_in_r_uop_vpu_isWritePartVd <= s0_out.uop.vpu_isWritePartVd;
      s1_in_r_uop_vpu_isVleff <= s0_out.uop.vpu_isVleff;
      s1_in_r_uop_uopIdx <= s0_out.uop.uopIdx;
      s1_in_r_uop_lastUop <= s0_out.uop.lastUop;
      s1_in_r_uop_numUops <= s0_out.uop.numUops;
      s1_in_r_uop_pdest <= s0_out.uop.pdest;
      s1_in_r_uop_robIdx_flag <= s0_out.uop.robIdx_flag;
      s1_in_r_uop_robIdx_value <= s0_out.uop.robIdx_value;
      s1_in_r_uop_debugInfo_eliminatedMove <= s0_out.uop.debugInfo_eliminatedMove;
      s1_in_r_uop_debugInfo_renameTime <= s0_out.uop.debugInfo_renameTime;
      s1_in_r_uop_debugInfo_dispatchTime <= s0_out.uop.debugInfo_dispatchTime;
      s1_in_r_uop_debugInfo_enqRsTime <= s0_out.uop.debugInfo_enqRsTime;
      s1_in_r_uop_debugInfo_selectTime <= s0_out.uop.debugInfo_selectTime;
      s1_in_r_uop_debugInfo_issueTime <= s0_out.uop.debugInfo_issueTime;
      s1_in_r_uop_debugInfo_writebackTime <= s0_out.uop.debugInfo_writebackTime;
      s1_in_r_uop_debugInfo_runahead_checkpoint_id <= s0_out.uop.debugInfo_runahead_checkpoint_id;
      s1_in_r_uop_debugInfo_tlbFirstReqTime <= s0_out.uop.debugInfo_tlbFirstReqTime;
      s1_in_r_uop_debugInfo_tlbRespTime <= s0_out.uop.debugInfo_tlbRespTime;
      s1_in_r_uop_debug_seqNum_seqNum <= s0_out.uop.debug_seqNum_seqNum;
      s1_in_r_uop_debug_seqNum_uopIdx <= s0_out.uop.debug_seqNum_uopIdx;
      s1_in_r_uop_lqIdx_flag <= s0_out.uop.lqIdx_flag;
      s1_in_r_uop_lqIdx_value <= s0_out.uop.lqIdx_value;
      s1_in_r_uop_sqIdx_flag <= s0_out.uop.sqIdx_flag;
      s1_in_r_uop_sqIdx_value <= s0_out.uop.sqIdx_value;
      s1_in_r_uop_numLsElem <= s0_out.uop.numLsElem;
      s1_in_r_fof <= s0_out.fof;
      s1_in_r_vdIdxInField <= s0_out.vdIdxInField;
      s1_in_r_preIsSplit <= s0_out.preIsSplit;
      s1_in_r_alignedType <= s0_out.alignedType;
      s1_in_r_indexVlMaxInVd <= s0_out.indexVlMaxInVd;
      s1_in_r_vecReplayMbIdx <= s0_out.vecReplayMbIdx;
      s1_in_r_vecReplayFlowMask <= s0_out.vecReplayFlowMask;
    end
  end
  always_comb begin
    s1_in = '0;
    s1_in.isVecPartReplay = s1_in_r_isVecPartReplay;
    s1_in.flowMask = s1_in_r_flowMask;
    s1_in.byteMask = s1_in_r_byteMask;
    s1_in.data = s1_in_r_data;
    s1_in.baseAddr = s1_in_r_baseAddr;
    s1_in.stride = s1_in_r_stride;
    s1_in.flowNum = s1_in_r_flowNum;
    s1_in.nfields = s1_in_r_nfields;
    s1_in.eew = s1_in_r_eew;
    s1_in.sew = s1_in_r_sew;
    s1_in.emul = s1_in_r_emul;
    s1_in.lmul = s1_in_r_lmul;
    s1_in.vlmax = s1_in_r_vlmax;
    s1_in.instType = s1_in_r_instType;
    s1_in.rawNf = s1_in_r_rawNf;
    s1_in.indexedSrcMask = s1_in_r_indexedSrcMask;
    s1_in.indexedSplitOffset = s1_in_r_indexedSplitOffset;
    s1_in.uop.pc = s1_in_r_uop_pc;
    s1_in.uop.ftqPtr_flag = s1_in_r_uop_ftqPtr_flag;
    s1_in.uop.ftqPtr_value = s1_in_r_uop_ftqPtr_value;
    s1_in.uop.ftqOffset = s1_in_r_uop_ftqOffset;
    s1_in.uop.fuType = s1_in_r_uop_fuType;
    s1_in.uop.fuOpType = s1_in_r_uop_fuOpType;
    s1_in.uop.vecWen = s1_in_r_uop_vecWen;
    s1_in.uop.v0Wen = s1_in_r_uop_v0Wen;
    s1_in.uop.vlWen = s1_in_r_uop_vlWen;
    s1_in.uop.vpu_vill = s1_in_r_uop_vpu_vill;
    s1_in.uop.vpu_vma = s1_in_r_uop_vpu_vma;
    s1_in.uop.vpu_vta = s1_in_r_uop_vpu_vta;
    s1_in.uop.vpu_vsew = s1_in_r_uop_vpu_vsew;
    s1_in.uop.vpu_vlmul = s1_in_r_uop_vpu_vlmul;
    s1_in.uop.vpu_specVill = s1_in_r_uop_vpu_specVill;
    s1_in.uop.vpu_specVma = s1_in_r_uop_vpu_specVma;
    s1_in.uop.vpu_specVta = s1_in_r_uop_vpu_specVta;
    s1_in.uop.vpu_specVsew = s1_in_r_uop_vpu_specVsew;
    s1_in.uop.vpu_specVlmul = s1_in_r_uop_vpu_specVlmul;
    s1_in.uop.vpu_vm = s1_in_r_uop_vpu_vm;
    s1_in.uop.vpu_vstart = s1_in_r_uop_vpu_vstart;
    s1_in.uop.vpu_frm = s1_in_r_uop_vpu_frm;
    s1_in.uop.vpu_fpu_isFpToVecInst = s1_in_r_uop_vpu_fpu_isFpToVecInst;
    s1_in.uop.vpu_fpu_isFP32Instr = s1_in_r_uop_vpu_fpu_isFP32Instr;
    s1_in.uop.vpu_fpu_isFP64Instr = s1_in_r_uop_vpu_fpu_isFP64Instr;
    s1_in.uop.vpu_fpu_isReduction = s1_in_r_uop_vpu_fpu_isReduction;
    s1_in.uop.vpu_fpu_isFoldTo1_2 = s1_in_r_uop_vpu_fpu_isFoldTo1_2;
    s1_in.uop.vpu_fpu_isFoldTo1_4 = s1_in_r_uop_vpu_fpu_isFoldTo1_4;
    s1_in.uop.vpu_fpu_isFoldTo1_8 = s1_in_r_uop_vpu_fpu_isFoldTo1_8;
    s1_in.uop.vpu_vxrm = s1_in_r_uop_vpu_vxrm;
    s1_in.uop.vpu_vuopIdx = s1_in_r_uop_vpu_vuopIdx;
    s1_in.uop.vpu_lastUop = s1_in_r_uop_vpu_lastUop;
    s1_in.uop.vpu_vmask = s1_in_r_uop_vpu_vmask;
    s1_in.uop.vpu_vl = s1_in_r_uop_vpu_vl;
    s1_in.uop.vpu_nf = s1_in_r_uop_vpu_nf;
    s1_in.uop.vpu_veew = s1_in_r_uop_vpu_veew;
    s1_in.uop.vpu_isReverse = s1_in_r_uop_vpu_isReverse;
    s1_in.uop.vpu_isExt = s1_in_r_uop_vpu_isExt;
    s1_in.uop.vpu_isNarrow = s1_in_r_uop_vpu_isNarrow;
    s1_in.uop.vpu_isDstMask = s1_in_r_uop_vpu_isDstMask;
    s1_in.uop.vpu_isOpMask = s1_in_r_uop_vpu_isOpMask;
    s1_in.uop.vpu_isMove = s1_in_r_uop_vpu_isMove;
    s1_in.uop.vpu_isDependOldVd = s1_in_r_uop_vpu_isDependOldVd;
    s1_in.uop.vpu_isWritePartVd = s1_in_r_uop_vpu_isWritePartVd;
    s1_in.uop.vpu_isVleff = s1_in_r_uop_vpu_isVleff;
    s1_in.uop.uopIdx = s1_in_r_uop_uopIdx;
    s1_in.uop.lastUop = s1_in_r_uop_lastUop;
    s1_in.uop.numUops = s1_in_r_uop_numUops;
    s1_in.uop.pdest = s1_in_r_uop_pdest;
    s1_in.uop.robIdx_flag = s1_in_r_uop_robIdx_flag;
    s1_in.uop.robIdx_value = s1_in_r_uop_robIdx_value;
    s1_in.uop.debugInfo_eliminatedMove = s1_in_r_uop_debugInfo_eliminatedMove;
    s1_in.uop.debugInfo_renameTime = s1_in_r_uop_debugInfo_renameTime;
    s1_in.uop.debugInfo_dispatchTime = s1_in_r_uop_debugInfo_dispatchTime;
    s1_in.uop.debugInfo_enqRsTime = s1_in_r_uop_debugInfo_enqRsTime;
    s1_in.uop.debugInfo_selectTime = s1_in_r_uop_debugInfo_selectTime;
    s1_in.uop.debugInfo_issueTime = s1_in_r_uop_debugInfo_issueTime;
    s1_in.uop.debugInfo_writebackTime = s1_in_r_uop_debugInfo_writebackTime;
    s1_in.uop.debugInfo_runahead_checkpoint_id = s1_in_r_uop_debugInfo_runahead_checkpoint_id;
    s1_in.uop.debugInfo_tlbFirstReqTime = s1_in_r_uop_debugInfo_tlbFirstReqTime;
    s1_in.uop.debugInfo_tlbRespTime = s1_in_r_uop_debugInfo_tlbRespTime;
    s1_in.uop.debug_seqNum_seqNum = s1_in_r_uop_debug_seqNum_seqNum;
    s1_in.uop.debug_seqNum_uopIdx = s1_in_r_uop_debug_seqNum_uopIdx;
    s1_in.uop.lqIdx_flag = s1_in_r_uop_lqIdx_flag;
    s1_in.uop.lqIdx_value = s1_in_r_uop_lqIdx_value;
    s1_in.uop.sqIdx_flag = s1_in_r_uop_sqIdx_flag;
    s1_in.uop.sqIdx_value = s1_in_r_uop_sqIdx_value;
    s1_in.uop.numLsElem = s1_in_r_uop_numLsElem;
    s1_in.fof = s1_in_r_fof;
    s1_in.vdIdxInField = s1_in_r_vdIdxInField;
    s1_in.preIsSplit = s1_in_r_preIsSplit;
    s1_in.alignedType = s1_in_r_alignedType;
    s1_in.indexVlMaxInVd = s1_in_r_indexVlMaxInVd;
    s1_in.vecReplayMbIdx = s1_in_r_vecReplayMbIdx;
    s1_in.vecReplayFlowMask = s1_in_r_vecReplayFlowMask;
  end

  xs_VSplitPipeline_core #(.IS_VSTORE(1'b0)) u_core (
    .clock                                        (clock),
    .reset                                        (reset),
    .redirect_valid                               (io_redirect_valid),
    .redirect_bits_robIdx_flag                    (io_redirect_bits_robIdx_flag),
    .redirect_bits_robIdx_value                   (io_redirect_bits_robIdx_value),
    .redirect_bits_level                          (io_redirect_bits_level),
    .in_ready                                     (io_in_ready),
    .in_valid                                     (io_in_valid),
    .in                                           (in),
    .toMergeBuffer_req_ready                      (io_toMergeBuffer_req_ready),
    .toMergeBuffer_req_valid                      (io_toMergeBuffer_req_valid),
    .toMergeBuffer_req                            (toMergeBuffer_req),
    .toMergeBuffer_resp_valid                     (io_toMergeBuffer_resp_valid),
    .toMergeBuffer_resp_bits_mBIndex              (io_toMergeBuffer_resp_bits_mBIndex),
    .out_ready                                    (io_out_ready),
    .out_valid                                    (io_out_valid),
    .out                                          (out),
    .threshold_valid                              (io_threshold_valid),
    .threshold_bits_robIdx_flag                   (io_threshold_bits_robIdx_flag),
    .threshold_bits_robIdx_value                  (io_threshold_bits_robIdx_value),
    .threshold_bits_uopIdx                        (io_threshold_bits_uopIdx),
    .s0_out                                       (s0_out),
    .s0_fire                                      (s0_fire),
    .s1_in                                        (s1_in)
  );

endmodule
// END GENERATED(wrapper_VLSplitPipelineImp)
