// ============================================================================
// DecodeStage.sv —— 香山 V2R2（昆明湖）后端译码级（可读重写，可读核）
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/backend/decode/DecodeStage.scala
//
// 在后端的位置：前端 IBuffer 每拍送来 DecodeWidth(=6) 条已展开的 32 位指令
// （StaticInst，含 instr/foldpc/前端异常/ftq 指针/预译码信息）。本级把它们：
//   1) 并行送 6 个简单译码器 DecodeUnit，各产出一条 uop 的控制信息 DecodedInst，
//      并给出该指令是否「复杂」(isComplex，需要拆成多条 uop，如向量指令)。
//   2) 复杂指令按表序择「第一条」送复杂译码器 DecodeUnitComp，拆成最多 6 条 uop。
//   3) VTypeGen 维护体系结构 / 投机 vtype，旁路给各译码器（向量译码依赖 vtype）。
// 然后把「复杂译码结果排在前、简单译码结果填后」拼成本级输出，交给重命名 Rename。
//
// 本级真正手写的 glue（子模块 DecodeUnit/DecodeUnitComp/VTypeGen 全部 golden 黑盒）：
//   * 流水握手 / 反压：每路 io_in[i].ready 取决于「前 i 条都是简单且能与复杂结果一
//     起塞进 RenameWidth」或「第 i 条是首个复杂指令且复杂译码器 ready」。
//   * 复杂指令路由：isComplexVec / firstComplexOH / complexNum（复杂译码器一拍产
//     出的 uop 数）决定简单结果在输出里的偏移 (i - complexNum)。
//   * 结果汇聚：finalDecodedInst[i] = complexNum>i ? 复杂[i] : 简单[i-complexNum]。
//   * 输出修正：向量反序指令交换 lsrc0/1、srcType0/1；srcType3 读 V0 修正；
//     v0Wen/vecWen 依 ldest 拆分；简单指令补 uopIdx=0/firstUop=lastUop=1/numWB=1。
//   * 重定向 / vtype 恢复 (isResumeVType) 时全局禁止接收与输出。
//   * 非法指令 (EX_II/EX_VI) 上报 CSR (trapInstInfo)。
//   * 6 路性能事件（融合数 / 等待 / 利用率 / INST_SPEC / recovery 气泡），各打两拍。
//
// 验证：UT 与 golden DecodeStage 双例化逐拍比对全部输出；FM 以三类子模块为两侧共享
//       golden 黑盒、对本层 glue 做签名等价。
// ============================================================================
`include "decodestage_pkg.sv"

module DecodeStage_it
  import decodestage_pkg::*;
(
  `include "decodestage_core_ports.svh"
);

  // ==========================================================================
  // 0. VTypeGen 输出 vtype（旁路给各译码器 / 复杂译码器）
  // ==========================================================================
  vtype_t vt;

  // ==========================================================================
  // 1. 6 个简单译码器的产出（struct 数组 + isComplex/uopInfo）
  // --------------------------------------------------------------------------
  // simple[i]            ：第 i 路简单译码结果（DecodedInst）。注意简单译码器不产出
  //                        uopIdx/firstUop/lastUop/numWB/v0Wen/vlWen/vpu_fpu_isFoldTo1
  //                        这 9 个字段（这些字段在 simple[i] 中保持悬空，glue 在简单
  //                        路径用常量覆盖，从不读取它们）。
  // simple_isComplex[i]  ：该指令是否需要复杂译码。
  // simple_uop[i]        ：复杂拆分信息（numOfUop/numOfWB/lmul）。
  // ==========================================================================
  decoded_inst_t simple [DECODE_WIDTH];
  logic          simple_isComplex [DECODE_WIDTH];
  uop_info_t     simple_uop       [DECODE_WIDTH];

  // ==========================================================================
  // 2. 复杂译码器的产出
  // --------------------------------------------------------------------------
  // complex[j]        ：复杂译码器拆出的第 j 条 uop（DecodedInst，字段齐全）。
  // complex_valid_o[j]：第 j 条 uop 有效。
  // complex_num       ：本拍复杂译码器产出的 uop 数（0..6）。
  // comp_in_ready     ：复杂译码器能接收新输入。
  // ==========================================================================
  decoded_inst_t complex        [DECODE_WIDTH];
  logic          complex_valid_o[DECODE_WIDTH];
  logic [2:0]    complex_num;
  logic          comp_in_ready;

  // 复杂译码器输入：择一选出的复杂指令及其 uop 信息、输入有效
  decoded_inst_t comp_in_inst;
  uop_info_t     comp_in_uop;
  logic          comp_in_valid;

  // VTypeGen 是否可更新 vtype（复杂译码器接收到一条 vset 且非重定向时）
  logic can_update_vtype;

  // ==========================================================================
  // 3. io 别名 / 向量化
  // ==========================================================================
  logic [DECODE_WIDTH-1:0] in_valid;
  logic [DECODE_WIDTH-1:0] out_ready;
  assign in_valid  = {io_in_5_valid, io_in_4_valid, io_in_3_valid,
                      io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign out_ready = {io_out_5_ready, io_out_4_ready, io_out_3_ready,
                      io_out_2_ready, io_out_1_ready, io_out_0_ready};

  // readyCounter：若第 0 路输出 ready，假设下游 Rename 整宽(RenameWidth)可收，否则 0。
  // 这是对 Rename 反压的简化假设（见 Scala 注释），用于约束本拍最多接收多少条。
  logic [2:0] readyCounter;
  assign readyCounter = io_out_0_ready ? RENAME_WIDTH[2:0] : 3'd0;

  // 每路是否「有效且复杂 / 有效且简单」
  logic [DECODE_WIDTH-1:0] isComplexVec;
  logic [DECODE_WIDTH-1:0] isSimpleVec;
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_cls
    assign isComplexVec[i] = in_valid[i] &  simple_isComplex[i];
    assign isSimpleVec [i] = in_valid[i] & ~simple_isComplex[i];
  end

  // ==========================================================================
  // 4. 复杂指令选择（按表序 PriorityMux 第一条复杂指令）
  // --------------------------------------------------------------------------
  // 一拍只送一条复杂指令进复杂译码器；选最靠前的那条（firstComplexOH）。
  // ==========================================================================
  // complexNumAddLocation[i] = i + complexNum：第 i 路简单结果在最终输出里的位置。
  logic [3:0] complexAddLoc [DECODE_WIDTH];
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_addloc
    assign complexAddLoc[i] = {1'b0, complex_num} + i[3:0];
  end

  // complexValid：存在「位置不超过 readyCounter」的复杂指令（可被本拍接收）。
  logic complex_valid_any;
  always_comb begin
    complex_valid_any = 1'b0;
    for (int i = 0; i < DECODE_WIDTH; i++)
      if (isComplexVec[i] && (complexAddLoc[i] <= {1'b0, readyCounter}))
        complex_valid_any = 1'b1;
  end

  // 复杂译码器输入有效：有可接收的复杂指令，且非 vtype 恢复期。
  assign comp_in_valid = complex_valid_any & ~io_fromRob_isResumeVType;

  // PriorityMux：选第一条复杂指令的 DecodedInst / uopInfo 送复杂译码器。
  always_comb begin
    comp_in_inst = simple[0];
    comp_in_uop  = simple_uop[0];
    for (int i = DECODE_WIDTH - 1; i >= 0; i--)
      if (isComplexVec[i]) begin
        comp_in_inst = simple[i];
        comp_in_uop  = simple_uop[i];
      end
  end

  // firstComplexOH：首个复杂指令的 one-hot（供握手判断「第 i 路是否首个复杂」）。
  logic [DECODE_WIDTH-1:0] firstComplexOH;
  always_comb begin
    firstComplexOH = '0;
    for (int i = DECODE_WIDTH - 1; i >= 0; i--)
      if (isComplexVec[i]) firstComplexOH = ('0 | (1 << i));
  end

  // simplePrefixVec[i]：前 i+1 路是否「全为有效简单指令」（用于判断能否整段直通）。
  logic [DECODE_WIDTH-1:0] simplePrefix;
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_prefix
    assign simplePrefix[i] = &isSimpleVec[i:0];
  end

  // ==========================================================================
  // 5. VTypeGen 更新条件
  // --------------------------------------------------------------------------
  // 复杂译码器接收 (in.fire) 到一条 vset、且非重定向，才允许更新 vtype。
  // in.fire = comp_in_valid & comp_in_ready；vset 标志取自被选中的复杂指令。
  // ==========================================================================
  assign can_update_vtype = comp_in_valid & comp_in_ready & comp_in_inst.isVset & ~io_redirect;

  // ==========================================================================
  // 6. 输入握手 io_in[i].ready
  // --------------------------------------------------------------------------
  // 两种放行情形（且均要求无重定向、无 vtype 恢复）：
  //   a) 前 i 条全简单，且第 i 条（含复杂偏移）位置 < readyCounter → 可整段直通；
  //   b) 第 i 条是首个复杂指令，且其位置 <= readyCounter，且复杂译码器 ready。
  // ==========================================================================
  logic [DECODE_WIDTH-1:0] in_ready;
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_ready
    assign in_ready[i] = ~io_redirect & ~io_fromRob_isResumeVType & (
        (simplePrefix[i]   &  (complexAddLoc[i] <  {1'b0, readyCounter})) |
        (firstComplexOH[i] & ((complexAddLoc[i] <= {1'b0, readyCounter}) & comp_in_ready))
      );
  end
  assign io_in_0_ready = in_ready[0];
  assign io_in_1_ready = in_ready[1];
  assign io_in_2_ready = in_ready[2];
  assign io_in_3_ready = in_ready[3];
  assign io_in_4_ready = in_ready[4];
  assign io_in_5_ready = in_ready[5];

  // ==========================================================================
  // 7. 结果汇聚：finalDecodedInst[i] + 有效位
  // --------------------------------------------------------------------------
  // 复杂结果排在最终输出最前面（共 complexNum 条），简单结果填其后：
  //   finalDecodedInst[i] = (complexNum > i) ? complex[i] : simple[i - complexNum]
  // 其中 (i - complexNum) 为 3 位模运算下标（与 Scala 的 UInt 减法一致；越界项不会
  // 被选中，因为越界时 complexNum > i 必然成立走复杂分支）。
  // 简单译码器缺失的 9 个字段在简单路径用常量覆盖（见 fill_simple_fields）。
  // ==========================================================================
  logic [DECODE_WIDTH-1:0] gt_complex;   // complexNum > i
  logic [2:0]              simpleIdx [DECODE_WIDTH]; // (i - complexNum)[2:0]
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_sel
    assign gt_complex[i] = complex_num > i[2:0];
    assign simpleIdx[i]  = i[2:0] - complex_num;
  end

  // 简单结果 / 有效位按 (i - complexNum) 重排查找（与 golden 的 _GEN_* 8 项数组一致，
  // 下标 6/7 回绕到 0，永不被有效选中）。这里用组合逻辑直接重排成 simple_sel[i] /
  // simple_prefix_sel[i]，不写「读模块级信号的 function」（Formality 不喜欢，会报
  // FMR_VLOG-091 并阻断 impl 读入）。
  decoded_inst_t simple_sel        [DECODE_WIDTH];
  logic [DECODE_WIDTH-1:0] simple_prefix_sel;
  always_comb begin
    for (int i = 0; i < DECODE_WIDTH; i++) begin
      simple_sel[i]        = simple[0];
      simple_prefix_sel[i] = simplePrefix[0];
      case (simpleIdx[i])
        3'd0: begin simple_sel[i] = simple[0]; simple_prefix_sel[i] = simplePrefix[0]; end
        3'd1: begin simple_sel[i] = simple[1]; simple_prefix_sel[i] = simplePrefix[1]; end
        3'd2: begin simple_sel[i] = simple[2]; simple_prefix_sel[i] = simplePrefix[2]; end
        3'd3: begin simple_sel[i] = simple[3]; simple_prefix_sel[i] = simplePrefix[3]; end
        3'd4: begin simple_sel[i] = simple[4]; simple_prefix_sel[i] = simplePrefix[4]; end
        3'd5: begin simple_sel[i] = simple[5]; simple_prefix_sel[i] = simplePrefix[5]; end
        default: begin simple_sel[i] = simple[0]; simple_prefix_sel[i] = simplePrefix[0]; end
      endcase
    end
  end

  decoded_inst_t final_inst [DECODE_WIDTH];
  logic [DECODE_WIDTH-1:0] final_valid;

  always_comb begin
    for (int i = 0; i < DECODE_WIDTH; i++) begin
      decoded_inst_t s, c;
      s = simple_sel[i];
      c = complex[i];
      if (gt_complex[i]) begin
        // 复杂路径：整条复杂 uop（字段齐全）。
        final_inst[i]  = c;
        // firstUop 例外：复杂译码器只在第 0 路输出 firstUop（一次复杂展开只有第一条
        // uop 是 firstUop）；其余路 complex[i].firstUop 端口在 golden 不存在，故复杂
        // 路径上 i>0 恒为 0（与 golden io_out_i_bits_firstUop = ~(complexNum>i) 一致）。
        final_inst[i].firstUop = (i == 0) ? complex[0].firstUop : 1'b0;
        final_valid[i] = complex_valid_o[i];
      end else begin
        // 简单路径：以简单结果为基底，覆盖简单译码器未产出的 9 个字段（常量）。
        final_inst[i]  = s;
        final_inst[i].uopIdx              = 7'd0;
        final_inst[i].firstUop            = 1'b1;
        final_inst[i].lastUop             = 1'b1;
        final_inst[i].numWB               = 7'd1;
        final_inst[i].vlWen               = 1'b0;
        final_inst[i].vpu_fpu_isFoldTo1_2 = 1'b0;
        final_inst[i].vpu_fpu_isFoldTo1_4 = 1'b0;
        final_inst[i].vpu_fpu_isFoldTo1_8 = 1'b0;
        // v0Wen/vecWen 两路都由 ldest 重算（见第 8 节），此处不依赖 simple 原值。
        final_valid[i] = simple_prefix_sel[i];
      end
    end
  end

  // ==========================================================================
  // 8. 输出修正（向量反序交换 / V0 源修正 / v0Wen-vecWen 拆分）+ 输出 struct
  // --------------------------------------------------------------------------
  // out_inst[i] 是直接送下游的 DecodedInst；大部分字段直接取 final_inst[i]，少数需
  // glue 修正：
  //   * 向量反序 (vpu_isReverse)：交换 lsrc0<->lsrc1、srcType0<->srcType1。
  //   * srcType3 修正：若 src0/1/2/3 任一以向量形式读 v0(lsrc==0)，则 src3 强制为 V0。
  //   * v0Wen = vecWen & (ldest==0)；vecWen' = vecWen & (ldest!=0)（写 v0 与写普通向
  //     量寄存器分流）。
  //   * 输出有效：final_valid[i] & ~isResumeVType。
  // ==========================================================================
  decoded_inst_t           out_inst   [DECODE_WIDTH];
  logic [DECODE_WIDTH-1:0] out_valid;
  logic [5:0]              out_lsrc0    [DECODE_WIDTH];
  logic [5:0]              out_lsrc1    [DECODE_WIDTH];
  logic [3:0]              out_srcType0 [DECODE_WIDTH];
  logic [3:0]              out_srcType1 [DECODE_WIDTH];
  logic [3:0]              out_srcType3 [DECODE_WIDTH];
  logic [DECODE_WIDTH-1:0] out_v0Wen;
  logic [DECODE_WIDTH-1:0] out_vecWen;

  // SrcType.isVp(s)：源类型是否为向量（编码 bit2=1），与 golden srcType[2] 判定一致。
  function automatic logic src_is_vp(input logic [3:0] st);
    return st[2];
  endfunction

  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_out
    // 反序交换
    assign out_lsrc0[i]    = final_inst[i].vpu_isReverse ? final_inst[i].lsrc[1]    : final_inst[i].lsrc[0];
    assign out_lsrc1[i]    = final_inst[i].vpu_isReverse ? final_inst[i].lsrc[0]    : final_inst[i].lsrc[1];
    assign out_srcType0[i] = final_inst[i].vpu_isReverse ? final_inst[i].srcType[1] : final_inst[i].srcType[0];
    assign out_srcType1[i] = final_inst[i].vpu_isReverse ? final_inst[i].srcType[0] : final_inst[i].srcType[1];
    // srcType3：src0/1/2/3 任一以向量形式读 v0(lsrc==0) → src3 = V0(4'h8)
    assign out_srcType3[i] =
        ( (src_is_vp(final_inst[i].srcType[0]) & (final_inst[i].lsrc[0] == 6'h0))
        | (src_is_vp(final_inst[i].srcType[1]) & (final_inst[i].lsrc[1] == 6'h0))
        | (src_is_vp(final_inst[i].srcType[2]) & (final_inst[i].lsrc[2] == 6'h0))
        | (src_is_vp(final_inst[i].srcType[3])) )
        ? 4'h8 : final_inst[i].srcType[3];
    // v0Wen / vecWen 分流
    assign out_v0Wen[i]  = final_inst[i].vecWen & (final_inst[i].ldest == 6'h0);
    assign out_vecWen[i] = final_inst[i].vecWen & (final_inst[i].ldest != 6'h0);
    // 输出有效
    assign out_valid[i]  = final_valid[i] & ~io_fromRob_isResumeVType;
    // 其余字段整体取 final_inst（unpack svh 逐字段拆到端口；glue 字段已单独接出）
    assign out_inst[i]   = final_inst[i];
  end

  // ==========================================================================
  // 9. RAT（重命名别名表）读口地址 / hold
  // --------------------------------------------------------------------------
  // 用「融合前」的 lsrc 读 RAT 以改善时序（Scala 注释）。golden 这里直接用
  // io_out_i_bits_lsrc_*_0（= out_lsrc0/1，已含反序交换）。addr 端口按各自逻辑寄存
  // 器编号空间定宽，实际只用低 6 位，高位补 0。hold = !out_ready（下游未就绪时保持）。
  // ==========================================================================
  // RAT 接出（逐通道/逐读口展开，地址零扩展，hold = ~ready）见生成的 svh。
  `include "decodestage_rat.svh"

  // ==========================================================================
  // 10. 非法指令上报 CSR (trapInstInfo)
  // --------------------------------------------------------------------------
  // 某路输出 fire 且其异常向量含 EX_II(2)/EX_VI(22) → 该路为非法指令。任一非法且非
  // 重定向 → trapInstInfo.valid。bits 取首个非法指令的 instr/ftq 信息（PriorityMux）。
  // ==========================================================================
  logic [DECODE_WIDTH-1:0] illegal_vec;
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_ill
    assign illegal_vec[i] = out_valid[i] & out_ready[i]
                          & (final_inst[i].exceptionVec[2] | final_inst[i].exceptionVec[22]);
  end
  assign io_toCSR_trapInstInfo_valid = (|illegal_vec) & ~io_redirect;

  logic [31:0] trap_instr;
  logic        trap_ftq_flag;
  logic [5:0]  trap_ftq_value;
  logic [3:0]  trap_ftq_offset;
  always_comb begin
    trap_instr      = 32'h0;
    trap_ftq_flag   = 1'b0;
    trap_ftq_value  = 6'h0;
    trap_ftq_offset = 4'h0;
    for (int i = DECODE_WIDTH - 1; i >= 0; i--)
      if (illegal_vec[i]) begin
        trap_instr      = final_inst[i].instr;
        trap_ftq_flag   = final_inst[i].ftqPtr_flag;
        trap_ftq_value  = final_inst[i].ftqPtr_value;
        trap_ftq_offset = final_inst[i].ftqOffset;
      end
  end
  assign io_toCSR_trapInstInfo_bits_instr        = trap_instr;
  assign io_toCSR_trapInstInfo_bits_ftqPtr_flag  = trap_ftq_flag;
  assign io_toCSR_trapInstInfo_bits_ftqPtr_value = trap_ftq_value;
  assign io_toCSR_trapInstInfo_bits_ftqOffset    = trap_ftq_offset;

  // ==========================================================================
  // 11. stallReason 透传（背压原因链：本级 out 透传给上游 in）
  // --------------------------------------------------------------------------
  // out.backReason 由下游给入；in.backReason = out.backReason（直接回灌上游）。
  // out.reason[i] = backReason.valid ? backReason.bits : in.reason[i]。
  // ==========================================================================
  assign io_stallReason_in_backReason_valid = io_stallReason_out_backReason_valid;
  assign io_stallReason_in_backReason_bits  = io_stallReason_out_backReason_bits;
  `include "decodestage_stall.svh"

  // ==========================================================================
  // 12. 性能事件（6 路，各打两拍输出）
  // --------------------------------------------------------------------------
  // perf0 = PopCount(fusion)（融合指令数）           perf1 = PopCount(in valid&~ready)
  // perf2 = (有任一 in valid) & ~out0.ready          perf3 = PopCount(in.valid)（利用率）
  // perf4 = PopCount(in.fire)（INST_SPEC）            perf5 = recoveryFlag（恢复气泡）
  // recoveryFlag：重定向后置位，直到有 in.fire 才清除（衡量重定向造成的译码气泡）。
  // 各事件经两级寄存器对齐后接出，降低长扇出对时序影响（与 Scala 一致）。
  // ==========================================================================
  logic [DECODE_WIDTH-1:0] in_fire;
  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_fire
    assign in_fire[i] = in_valid[i] & in_ready[i];
  end

  // recoveryFlag + 第一级 fusion / inValidNotReady 寄存。
  // 注意：这三组寄存器在 golden 里位于「异步复位」always 块（posedge clock or posedge
  // reset），故这里也用异步复位，使 FM 把复位语义视为等价（同步 vs 异步复位的次态
  // 函数不同，会被 FM 判为 not-equivalent）。而 perf 输出级寄存器在 golden 无复位，
  // 故下面保持无复位。
  logic recovery_flag;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)               recovery_flag <= 1'b0;
    else if (io_redirect)    recovery_flag <= 1'b1;
    else if (|in_fire)       recovery_flag <= 1'b0;
  end

  // 第一级寄存：fusion / inValidNotReady 各打一拍（异步复位，对齐 golden）
  logic [DECODE_WIDTH-2:0] fusion_in;
  assign fusion_in = {io_fusion_4, io_fusion_3, io_fusion_2, io_fusion_1, io_fusion_0};
  logic [DECODE_WIDTH-2:0] fusion_r;       // 5 路
  logic [DECODE_WIDTH-1:0] invnr_r;        // 6 路 in valid & ~ready
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fusion_r <= '0;
      invnr_r  <= '0;
    end else begin
      fusion_r <= fusion_in;
      for (int i = 0; i < DECODE_WIDTH; i++)
        invnr_r[i] <= in_valid[i] & ~in_ready[i];
    end
  end

  // 6 路事件源（第一级计数）
  function automatic logic [2:0] popcnt6(input logic [DECODE_WIDTH-1:0] v);
    logic [2:0] s; s = '0;
    for (int i = 0; i < DECODE_WIDTH; i++) s += {2'b0, v[i]};
    return s;
  endfunction
  function automatic logic [2:0] popcnt5(input logic [DECODE_WIDTH-2:0] v);
    logic [2:0] s; s = '0;
    for (int i = 0; i < DECODE_WIDTH-1; i++) s += {2'b0, v[i]};
    return s;
  endfunction

  // 两级打拍（与 golden 完全一致的寄存器结构，逐事件独立命名以避免 comb-array 喂
  // always_ff 的调度歧义）：
  //   perf0/perf1：先经 fusion_r/invnr_r 第一级，再 popcount → reg → reg1（共 3 拍）
  //   perf2/perf3/perf4：组合事件 → reg → reg1（共 2 拍）
  //   perf5：recovery_flag(本身为 reg) → reg → reg1（共 3 拍）
  logic [2:0] perf0_reg, perf0_reg1;
  logic [2:0] perf1_reg, perf1_reg1;
  logic       perf2_reg, perf2_reg1;
  logic [2:0] perf3_reg, perf3_reg1;
  logic [2:0] perf4_reg, perf4_reg1;
  logic       perf5_reg, perf5_reg1;
  always_ff @(posedge clock) begin
    perf0_reg  <= popcnt5(fusion_r);                       perf0_reg1 <= perf0_reg;
    perf1_reg  <= popcnt6(invnr_r);                        perf1_reg1 <= perf1_reg;
    perf2_reg  <= (|in_valid) & ~io_out_0_ready;           perf2_reg1 <= perf2_reg;
    perf3_reg  <= popcnt6(in_valid);                       perf3_reg1 <= perf3_reg;
    perf4_reg  <= popcnt6(in_fire);                        perf4_reg1 <= perf4_reg;
    perf5_reg  <= recovery_flag;                           perf5_reg1 <= perf5_reg;
  end
  assign io_perf_0_value = {3'h0, perf0_reg1};
  assign io_perf_1_value = {3'h0, perf1_reg1};
  assign io_perf_2_value = {5'h0, perf2_reg1};
  assign io_perf_3_value = {3'h0, perf3_reg1};
  assign io_perf_4_value = {3'h0, perf4_reg1};
  assign io_perf_5_value = {5'h0, perf5_reg1};

  // ==========================================================================
  // 13. 扁平输入/输出拆装 + 三类子模块实例（生成的 svh）
  // ==========================================================================
  `include "decodestage_unpack.svh"     // out_inst -> 扁平输出端口
  `include "decodestage_decoders_it.svh"   // 6 个 DecodeUnit
  `include "decodestage_comp.svh"       // DecodeUnitComp
  `include "decodestage_vtypegen.svh"   // VTypeGen

endmodule
