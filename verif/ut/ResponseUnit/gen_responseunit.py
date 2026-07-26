#!/usr/bin/env python3
# ============================================================================
# gen_responseunit.py —— 生成 OpenLLC ResponseUnit 的可读手写核 + 包装/变体/UT。
# ----------------------------------------------------------------------------
# 忠实重写 golden ResponseUnit.sv(firtool 展开的 16 条目 response buffer + 2 仲裁器)。
# 逻辑等价 bug-for-bug:
#   * 16 条目 buffer, 每条目保存 task(CHI TaskBundle)+ state(s_comp/s_urgentRead/
#     w_datRsp/w_snpRsp/w_compack/w_comp)+ 256b×2 data beat + beatValids×2 + is_miss;
#   * 分配: s4(freeVec 首个空槽 insertIdx_s4)与 s6(idOH_s6_enc 独立编码 insertIdx_s6);
#     s6 优先占位, s4 在 s6 占位之外分配。
#   * 8 个响应更新通道(各 16 条目 match by reqID==txnID & valid & 通道 opcode 条件):
#       ch0 snRxdat(opcode 0x4, 按 dataID[1] 选 beat)
#       ch1 snRxrsp(opcode 0x5/0x4)     ch2 rnRxdat(opcode 0x1,非 replSnp)
#       ch3 rnRxrsp(opcode 0x1)         ch4 rnRxrsp(无 opcode 限, 与 rnRxdat 合并 snpRsp)
#       ch5 rnRxrsp(opcode 0x2, compack) ch6 bypassData_0(0x4) ch7 bypassData_1(0x4)
#   * 出队: txrspArb(FastArbiter_50)选 non-read 完成条目发 txrsp; txdatArb(FastArbiter_52)
#     选 read 完成条目发 txdat。io_txrsp_ready&valid / io_txdat_ready&valid → 置 s_comp。
#   * respInfo[16]: 逐条目透传(valid&~will_free, set/tag/opcode/reqID/w_snpRsp/w_compdata/
#     w_compack(含 rnRxrsp 旁路)/is_miss)。
#   * urgentRead: 首个 valid&~s_urgentRead 条目, io_urgentRead_ready 时置 s_urgentRead。
#   * bufferTimer_N(16b)/REG_N(1b): 泄漏检测计时器, 仅 `ifndef SYNTHESIS 断言读 →
#     两侧对称 cone-dead(class-4 matched-unread 双射加强, 见 fm_pins.tcl)。
# FastArbiter_50/52 在两侧 elaborate(确定性仲裁逻辑, 非厂商宏, 0 黑盒)。
# ============================================================================
import sys

N = 16
IDX = 4  # $clog2(16)

# --- buffer 条目 task 字段(名, 宽度)——顺序与 golden buffer_N_task_* 一致 ---
TASK_FIELDS = [
    ("set", 12), ("bank", 2), ("tag", 28), ("off", 6), ("size", 3),
    ("refillTask", 1), ("bufID", 4), ("reqID", 12), ("replSnp", 1),
    ("snpVec_0", 1), ("tgtID", 11), ("srcID", 11), ("txnID", 12),
    ("homeNID", 11), ("dbID", 12), ("fwdNID", 11), ("fwdTxnID", 12),
    ("chiOpcode", 7), ("resp", 3), ("fwdState", 3), ("pCrdType", 4),
    ("retToSrc", 1), ("doNotGoToSD", 1), ("expCompAck", 1), ("allowRetry", 1),
    ("order", 2), ("memAttr_allocate", 1), ("memAttr_cacheable", 1),
    ("memAttr_device", 1), ("memAttr_ewa", 1), ("snpAttr", 1),
]
STATE_FIELDS = ["s_comp", "s_urgentRead", "w_datRsp", "w_snpRsp", "w_compack", "w_comp"]

# s4 alloc 写入的 task 字段(golden _GEN_50 分支;不含 snpVec_0/resp——它们单独多路选择)
ALLOC_TASK_FIELDS = [f for f, _ in TASK_FIELDS if f not in ("snpVec_0", "resp")]


def wdecl(name, w):
    return f"  logic [{w-1}:0] {name};" if w > 1 else f"  logic {name};"


# ---------------------------------------------------------------------------
# 生成可读核 xs_ResponseUnit_core + 包装(module_name)。
# emit_wrapper_name: 若非 None, 追加同逻辑的扁平端口包装模块。
# ---------------------------------------------------------------------------
def gen_core():
    L = []
    ap = L.append

    # ---------------- package ----------------
    ap("package xs_responseunit_pkg;")
    ap(f"  localparam int unsigned N   = {N};")
    ap(f"  localparam int unsigned IDX = {IDX};")
    ap("  // buffer 条目 task 结构(与 golden buffer_N_task_* 字段/位宽逐位一致)")
    ap("  typedef struct packed {")
    for f, w in reversed(TASK_FIELDS):  # packed struct: 先声明高位, 保持可读顺序即可
        ap(f"    logic [{w-1}:0] {f};" if w > 1 else f"    logic {f};")
    ap("  } ru_task_t;")
    ap("endpackage")
    ap("")

    # ---------------- core module header ----------------
    ap("module xs_ResponseUnit_core")
    ap("  import xs_responseunit_pkg::*;")
    ap("(")
    ap("  input  logic clock,")
    ap("  input  logic reset,")
    # -- fromMainPipe alloc s4 --
    ap("  // fromMainPipe.alloc.s4")
    ap("  input  logic        io_fromMainPipe_alloc_s4_valid,")
    ap("  input  logic        io_fromMainPipe_alloc_s4_bits_state_w_datRsp,")
    ap("  input  logic        io_fromMainPipe_alloc_s4_bits_state_w_snpRsp,")
    ap("  input  logic        io_fromMainPipe_alloc_s4_bits_state_w_compack,")
    ap("  input  logic        io_fromMainPipe_alloc_s4_bits_state_w_comp,")
    ap("  input  ru_task_t     io_fromMainPipe_alloc_s4_bits_task,")
    ap("  input  logic        io_fromMainPipe_alloc_s4_bits_is_miss,")
    # -- fromMainPipe alloc s6 --
    ap("  // fromMainPipe.alloc.s6")
    ap("  input  logic        io_fromMainPipe_alloc_s6_valid,")
    ap("  input  logic        io_fromMainPipe_alloc_s6_bits_state_w_snpRsp,")
    ap("  input  ru_task_t     io_fromMainPipe_alloc_s6_bits_task,")
    ap("  input  logic [255:0] io_fromMainPipe_alloc_s6_bits_data_data_0_data,")
    ap("  input  logic [255:0] io_fromMainPipe_alloc_s6_bits_data_data_1_data,")
    # -- response channels --
    ap("  // snRxdat / snRxrsp")
    ap("  input  logic        io_snRxdat_valid,")
    ap("  input  logic [11:0] io_snRxdat_bits_txnID,")
    ap("  input  logic [6:0]  io_snRxdat_bits_opcode,")
    ap("  input  logic [1:0]  io_snRxdat_bits_dataID,")
    ap("  input  logic [255:0] io_snRxdat_bits_data_data,")
    ap("  input  logic        io_snRxrsp_valid,")
    ap("  input  logic [11:0] io_snRxrsp_bits_txnID,")
    ap("  input  logic [6:0]  io_snRxrsp_bits_opcode,")
    ap("  // bypassData_0 / bypassData_1")
    ap("  input  logic        io_bypassData_0_valid,")
    ap("  input  logic [11:0] io_bypassData_0_bits_txnID,")
    ap("  input  logic [6:0]  io_bypassData_0_bits_opcode,")
    ap("  input  logic [255:0] io_bypassData_0_bits_data_data,")
    ap("  input  logic        io_bypassData_1_valid,")
    ap("  input  logic [11:0] io_bypassData_1_bits_txnID,")
    ap("  input  logic [6:0]  io_bypassData_1_bits_opcode,")
    ap("  input  logic [1:0]  io_bypassData_1_bits_dataID,")
    ap("  input  logic [255:0] io_bypassData_1_bits_data_data,")
    ap("  // rnRxdat / rnRxrsp")
    ap("  input  logic        io_rnRxdat_valid,")
    ap("  input  logic [11:0] io_rnRxdat_bits_txnID,")
    ap("  input  logic [6:0]  io_rnRxdat_bits_opcode,")
    ap("  input  logic [2:0]  io_rnRxdat_bits_resp,")
    ap("  input  logic [10:0] io_rnRxdat_bits_srcID,")
    ap("  input  logic [1:0]  io_rnRxdat_bits_dataID,")
    ap("  input  logic [255:0] io_rnRxdat_bits_data_data,")
    ap("  input  logic        io_rnRxrsp_valid,")
    ap("  input  logic [11:0] io_rnRxrsp_bits_txnID,")
    ap("  input  logic [6:0]  io_rnRxrsp_bits_opcode,")
    ap("  input  logic [10:0] io_rnRxrsp_bits_srcID,")
    ap("  // out ready")
    ap("  input  logic        io_txrsp_ready,")
    ap("  input  logic        io_txdat_ready,")
    ap("  input  logic        io_urgentRead_ready,")
    # -- outputs: txrsp --
    ap("  // txrsp")
    ap("  output logic        io_txrsp_valid,")
    ap("  output logic [10:0] io_txrsp_bits_tgtID,")
    ap("  output logic [10:0] io_txrsp_bits_srcID,")
    ap("  output logic [11:0] io_txrsp_bits_txnID,")
    ap("  output logic [11:0] io_txrsp_bits_dbID,")
    ap("  output logic [6:0]  io_txrsp_bits_chiOpcode,")
    ap("  output logic [2:0]  io_txrsp_bits_resp,")
    ap("  output logic [2:0]  io_txrsp_bits_fwdState,")
    ap("  output logic [3:0]  io_txrsp_bits_pCrdType,")
    # -- outputs: txdat --
    ap("  // txdat")
    ap("  output logic        io_txdat_valid,")
    ap("  output logic [10:0] io_txdat_bits_task_tgtID,")
    ap("  output logic [10:0] io_txdat_bits_task_srcID,")
    ap("  output logic [11:0] io_txdat_bits_task_txnID,")
    ap("  output logic [10:0] io_txdat_bits_task_homeNID,")
    ap("  output logic [11:0] io_txdat_bits_task_dbID,")
    ap("  output logic [2:0]  io_txdat_bits_task_resp,")
    ap("  output logic [2:0]  io_txdat_bits_task_fwdState,")
    ap("  output logic [255:0] io_txdat_bits_data_data_0_data,")
    ap("  output logic [255:0] io_txdat_bits_data_data_1_data,")
    # -- outputs: respInfo[16] (packed arrays) --
    ap("  // respInfo[16]")
    ap("  output logic [N-1:0]        io_respInfo_valid,")
    ap("  output logic [N-1:0][11:0]  io_respInfo_set,")
    ap("  output logic [N-1:0][27:0]  io_respInfo_tag,")
    ap("  output logic [N-1:0][6:0]   io_respInfo_opcode,")
    ap("  output logic [N-1:0][11:0]  io_respInfo_reqID,")
    ap("  output logic [N-1:0]        io_respInfo_w_snpRsp,")
    ap("  output logic [N-1:0]        io_respInfo_w_compdata,")
    ap("  output logic [N-1:0]        io_respInfo_w_compack,")
    ap("  output logic [N-1:0]        io_respInfo_is_miss,")
    # -- outputs: urgentRead --
    ap("  // urgentRead")
    ap("  output logic        io_urgentRead_valid,")
    ap("  output logic [11:0] io_urgentRead_bits_set,")
    ap("  output logic [1:0]  io_urgentRead_bits_bank,")
    ap("  output logic [27:0] io_urgentRead_bits_tag,")
    ap("  output logic [10:0] io_urgentRead_bits_tgtID,")
    ap("  output logic [10:0] io_urgentRead_bits_srcID,")
    ap("  output logic [11:0] io_urgentRead_bits_txnID,")
    ap("  output logic [3:0]  io_urgentRead_bits_pCrdType")
    ap(");")
    ap("")

    # ---------------- state registers (16-entry arrays) ----------------
    ap("  // ============ buffer 状态寄存器(16 条目数组) ============")
    ap("  ru_task_t             buffer_task   [N-1:0];")
    ap("  logic                 buffer_valid  [N-1:0];")
    for s in STATE_FIELDS:
        ap(f"  logic                 buffer_{s}[N-1:0];")
    ap("  logic [255:0]         buffer_data0  [N-1:0];")
    ap("  logic [255:0]         buffer_data1  [N-1:0];")
    ap("  logic                 buffer_beat0  [N-1:0];")
    ap("  logic                 buffer_beat1  [N-1:0];")
    ap("  logic                 buffer_is_miss[N-1:0];")
    ap("  logic [15:0]          bufferTimer   [N-1:0]; // 泄漏计时器(死寄存器, 对称)")
    ap("  logic                 REG_valid_d   [N-1:0]; // 上一拍 valid 快照(golden REG_N)")
    ap("")
    # convenience packed vectors from arrays
    ap("  // ---- 从数组打平的位向量(便于优先编码/或归约) ----")
    for name, expr in [
        ("validVec", "buffer_valid[i]"),
        ("beat0Vec", "buffer_beat0[i]"),
        ("beat1Vec", "buffer_beat1[i]"),
        ("isMissVec", "buffer_is_miss[i]"),
        ("wDatRspVec", "buffer_w_datRsp[i]"),
        ("wSnpRspVec", "buffer_w_snpRsp[i]"),
        ("snpVec0Vec", "buffer_task[i].snpVec_0"),
    ]:
        ap(f"  logic [N-1:0] {name};")
    ap("  logic [N-1:0][6:0]  chiOpcodeVec;")
    ap("  logic [N-1:0][2:0]  respVec;")
    ap("  for (genvar i = 0; i < N; i++) begin : g_vecs")
    ap("    assign validVec[i]     = buffer_valid[i];")
    ap("    assign beat0Vec[i]     = buffer_beat0[i];")
    ap("    assign beat1Vec[i]     = buffer_beat1[i];")
    ap("    assign isMissVec[i]    = buffer_is_miss[i];")
    ap("    assign wDatRspVec[i]   = buffer_w_datRsp[i];")
    ap("    assign wSnpRspVec[i]   = buffer_w_snpRsp[i];")
    ap("    assign snpVec0Vec[i]   = buffer_task[i].snpVec_0;")
    ap("    assign chiOpcodeVec[i] = buffer_task[i].chiOpcode;")
    ap("    assign respVec[i]      = buffer_task[i].resp;")
    ap("  end")
    ap("")

    # ---------------- allocation (s4 / s6) ----------------
    ap("  // ============ 分配: s6 独立占位编码 + s4 空槽 ============")
    ap("  // idOH_s6_enc: golden 的 s6 占位 one-hot(优先取首个空槽; 全满时占 [15] 的 ~valid)")
    ap("  logic [N-1:0] idOH_s6_enc;")
    ap("  always_comb begin")
    ap("    idOH_s6_enc = 16'h1;")
    ap("    for (int k = 0; k < N-1; k++) begin")
    ap("      if (!buffer_valid[k]) begin idOH_s6_enc = (16'h1 << k); break; end")
    ap("      if (k == N-2) idOH_s6_enc = {~buffer_valid[N-1], 15'h0};")
    ap("    end")
    ap("  end")
    ap("  // freeVec_s4: s6 有效时排除 s6 占位槽, 否则全 ~valid")
    ap("  logic [N-1:0] freeVec_s4;")
    ap("  for (genvar i = 0; i < N; i++) begin : g_freevec")
    ap("    assign freeVec_s4[i] = io_fromMainPipe_alloc_s6_valid")
    ap("      ? (~buffer_valid[i] & ~idOH_s6_enc[i]) : ~buffer_valid[i];")
    ap("  end")
    ap("  logic [N-1:0] fullS6Vec; // golden _full_s6_T = ~valid(位序反转仅影响 |, 语义同)")
    ap("  for (genvar i = 0; i < N; i++) begin : g_fulls6")
    ap("    assign fullS6Vec[i] = ~buffer_valid[i];")
    ap("  end")
    ap("")
    # priority encoders
    ap("  // insertIdx_s4 = freeVec_s4 首个置位下标; insertIdx_s6 = idOH_s6_enc 首个置位下标")
    ap("  logic [IDX-1:0] insertIdx_s4, insertIdx_s6;")
    ap("  always_comb begin")
    ap("    insertIdx_s4 = {IDX{1'b1}};")
    ap("    for (int k = N-1; k >= 0; k--) if (freeVec_s4[k]) insertIdx_s4 = IDX'(k);")
    ap("  end")
    ap("  always_comb begin")
    ap("    insertIdx_s6 = {IDX{1'b1}};")
    ap("    for (int k = N-1; k >= 0; k--) if (idOH_s6_enc[k]) insertIdx_s6 = IDX'(k);")
    ap("  end")
    ap("  logic canAlloc_s6, canAlloc_s4;")
    ap("  assign canAlloc_s6 = io_fromMainPipe_alloc_s6_valid & (|fullS6Vec);")
    ap("  assign canAlloc_s4 = io_fromMainPipe_alloc_s4_valid & (|freeVec_s4);")
    ap("  logic [N-1:0] allocS4OH, allocS6OH; // 每条目分配 one-hot")
    ap("  for (genvar i = 0; i < N; i++) begin : g_allocoh")
    ap("    assign allocS6OH[i] = canAlloc_s6 & (insertIdx_s6 == IDX'(i));")
    ap("    assign allocS4OH[i] = canAlloc_s4 & (insertIdx_s4 == IDX'(i));")
    ap("  end")
    ap("")

    # ---------------- update channels ----------------
    ap("  // ============ 8 个响应更新通道的 match 向量 + 优先命中下标 ============")
    ap("  logic snRxdatOp, snRxrspOp5, snRxrspOp4, rnRxdatOp, rnRxrspOp, rnRxrspOp2;")
    ap("  logic byp0Op, byp1Op;")
    ap("  assign snRxdatOp  = io_snRxdat_bits_opcode == 7'h4;")
    ap("  assign snRxrspOp5 = io_snRxrsp_bits_opcode == 7'h5;")
    ap("  assign snRxrspOp4 = io_snRxrsp_bits_opcode == 7'h4;")
    ap("  assign rnRxdatOp  = io_rnRxdat_bits_opcode == 7'h1;")
    ap("  assign rnRxrspOp  = io_rnRxrsp_bits_opcode == 7'h1;")
    ap("  assign rnRxrspOp2 = io_rnRxrsp_bits_opcode == 7'h2;")
    ap("  assign byp0Op     = io_bypassData_0_bits_opcode == 7'h4;")
    ap("  assign byp1Op     = io_bypassData_1_bits_opcode == 7'h4;")
    ap("")
    # channel match vectors: uv0..uv7  (uv4 has no opcode gate)
    ap("  logic [N-1:0] uv0, uv1, uv2, uv3, uv4, uv5, uv6, uv7;")
    ap("  for (genvar i = 0; i < N; i++) begin : g_uv")
    ap("    assign uv0[i] = (buffer_task[i].reqID == io_snRxdat_bits_txnID) & buffer_valid[i] & snRxdatOp;")
    ap("    assign uv1[i] = (buffer_task[i].reqID == io_snRxrsp_bits_txnID) & buffer_valid[i] & (snRxrspOp5 | snRxrspOp4);")
    ap("    assign uv2[i] = (buffer_task[i].reqID == io_rnRxdat_bits_txnID) & buffer_valid[i] & ~buffer_task[i].replSnp & rnRxdatOp;")
    ap("    assign uv3[i] = (buffer_task[i].reqID == io_rnRxrsp_bits_txnID) & buffer_valid[i] & ~buffer_w_snpRsp[i] & rnRxrspOp;")
    ap("    assign uv4[i] = (buffer_task[i].reqID == io_rnRxrsp_bits_txnID) & buffer_valid[i] & ~buffer_w_snpRsp[i];")
    ap("    assign uv5[i] = (buffer_task[i].reqID == io_rnRxrsp_bits_txnID) & buffer_valid[i]")
    ap("                  & buffer_w_datRsp[i] & buffer_s_comp[i] & ~buffer_w_compack[i] & rnRxrspOp2;")
    ap("    assign uv6[i] = (buffer_task[i].reqID == io_bypassData_0_bits_txnID) & buffer_valid[i] & byp0Op;")
    ap("    assign uv7[i] = (buffer_task[i].reqID == io_bypassData_1_bits_txnID) & buffer_valid[i] & byp1Op;")
    ap("  end")
    ap("")
    # priority-encoded update ids
    ap("  // update_id_k = uvk 首个命中下标(优先, 缺省末项 15 —— 与 golden 同)")
    ap("  logic [IDX-1:0] uid0, uid1, uid2, uid3, uid4, uid5, uid6, uid7;")
    for k in range(8):
        ap(f"  always_comb begin uid{k} = {{IDX{{1'b1}}}};")
        ap(f"    for (int p = N-1; p >= 0; p--) if (uv{k}[p]) uid{k} = IDX'(p); end")
    ap("")

    # ---------------- data-select helpers (rnRxdat beat / newBeatValids etc.) ----------------
    ap("  // ---- rnRxdat 更新(ch2): 新 beatValids/snpVec/resp ----")
    ap("  logic [1:0] newBeatValids;")
    ap("  logic       newSnpVec_0, isReadUnique;")
    ap("  assign newBeatValids = {beat1Vec[uid2], beat0Vec[uid2]} | (2'h1 << io_rnRxdat_bits_dataID[1]);")
    ap("  assign newSnpVec_0   = snpVec0Vec[uid2] & (|io_rnRxdat_bits_srcID);")
    ap("  assign isReadUnique  = chiOpcodeVec[uid2] == 7'h7;")
    ap("  logic [2:0] newResp; // _buffer_task_resp_T_1 = resp | 4")
    ap("  assign newResp = respVec[uid2] | 3'h4;")
    ap("  logic isReadOnce; // _GEN_213 = chiOpcode==9 | chiOpcode==8")
    ap("  assign isReadOnce = (chiOpcodeVec[uid2] == 7'h9) | (chiOpcodeVec[uid2] == 7'h8);")
    ap("  logic rnRxdatRespHi; // _GEN_214")
    ap("  assign rnRxdatRespHi = io_rnRxdat_valid & (|uv2) & io_rnRxdat_bits_resp[2];")
    ap("  // ch0 snRxdat: 双 beat 到齐则 w_datRsp(_buffer_state_w_datRsp_T_2)")
    ap("  logic snRxdatBothBeats;")
    ap("  assign snRxdatBothBeats = (2'({1'h0, beat0Vec[uid0]} + {1'h0, beat1Vec[uid0]}) == 2'h1);")
    ap("  // ch3/ch4 rnRxrsp snpRsp 合并(newSnpVec_1_0 / newSnpVec_2_0)")
    ap("  logic newSnpVec_1_0, newSnpVec_2_0;")
    ap("  assign newSnpVec_1_0 = snpVec0Vec[uid3] & (|io_rnRxrsp_bits_srcID);")
    ap("  assign newSnpVec_2_0 = snpVec0Vec[uid4] & (|io_rnRxdat_bits_srcID) & (|io_rnRxrsp_bits_srcID);")
    ap("  logic sUrgSetByRnRxrsp; // _buffer_state_s_urgentRead_T_4")
    ap("  assign sUrgSetByRnRxrsp = newSnpVec_1_0 | (|{beat1Vec[uid3], beat0Vec[uid3]}) | wDatRspVec[uid3];")
    ap("  // ch3/ch4 同拍 rnRxdat&rnRxrsp 同 txnID 且都 opcode==1 的合并条件")
    ap("  logic bothRxValid, bothRxOp1, bothRxSameTxn;")
    ap("  assign bothRxValid    = io_rnRxdat_valid & io_rnRxrsp_valid;")
    ap("  assign bothRxOp1      = (io_rnRxdat_bits_opcode == 7'h1) & (io_rnRxrsp_bits_opcode == 7'h1);")
    ap("  assign bothRxSameTxn  = io_rnRxdat_bits_txnID == io_rnRxrsp_bits_txnID;")
    ap("  logic mergeSnp; // 触发 ch4(newSnpVec_2_0)分支")
    ap("  assign mergeSnp = bothRxValid & bothRxOp1 & bothRxSameTxn & (|uv4);")
    ap("")

    # ---------------- dequeue (arbiter) ----------------
    ap("  // ============ 出队仲裁(txrsp: 非读完成; txdat: 读完成) ============")
    ap("  logic        txrspArb_out_valid;")
    ap("  logic [6:0]  txrspArb_out_chiOpcode;")
    ap("  logic [IDX-1:0] txrspArb_chosen;")
    ap("  logic        txdatArb_out_valid;")
    ap("  logic [IDX-1:0] txdatArb_chosen;")
    ap("  logic [N-1:0] isRead;")
    ap("  for (genvar i = 0; i < N; i++) begin : g_isread")
    ap("    assign isRead[i] = (buffer_task[i].chiOpcode == 7'h7) | (buffer_task[i].chiOpcode == 7'h26);")
    ap("  end")
    ap("  logic txrspFire, txdatFire; // io_*_ready & arb_out_valid")
    ap("  assign txrspFire = io_txrsp_ready & txrspArb_out_valid;")
    ap("  assign txdatFire = io_txdat_ready & txdatArb_out_valid;")
    ap("  logic [N-1:0] txrspDeqOH, txdatDeqOH;")
    ap("  for (genvar i = 0; i < N; i++) begin : g_deqoh")
    ap("    assign txrspDeqOH[i] = txrspFire & (txrspArb_chosen == IDX'(i));")
    ap("    assign txdatDeqOH[i] = txdatFire & (txdatArb_chosen == IDX'(i));")
    ap("  end")
    ap("")

    # ---------------- will_free / urgent ----------------
    ap("  // ============ will_free(条目全部完成可释放) + urgent(待发 urgentRead) ============")
    ap("  logic [N-1:0] will_free;")
    ap("  for (genvar i = 0; i < N; i++) begin : g_willfree")
    ap("    assign will_free[i] = buffer_valid[i] & buffer_w_datRsp[i] & buffer_s_comp[i]")
    ap("      & buffer_w_compack[i] & buffer_w_snpRsp[i] & buffer_w_comp[i] & buffer_s_urgentRead[i];")
    ap("  end")
    ap("  logic [N-1:0] urgent_vec;")
    ap("  for (genvar i = 0; i < N; i++) begin : g_urgentvec")
    ap("    assign urgent_vec[i] = buffer_valid[i] & ~buffer_s_urgentRead[i];")
    ap("  end")
    ap("  logic [IDX-1:0] urgentIdx;")
    ap("  always_comb begin urgentIdx = {IDX{1'b1}};")
    ap("    for (int p = N-1; p >= 0; p--) if (urgent_vec[p]) urgentIdx = IDX'(p); end")
    ap("  logic urgentFire; // _GEN_297")
    ap("  assign urgentFire = io_urgentRead_ready & (|urgent_vec);")
    ap("")

    # ---------------- per-entry next-state (generate loop) ----------------
    ap("  // ============ 每条目状态更新(generate-for + 同步 reset) ============")
    ap("  for (genvar i = 0; i < N; i++) begin : g_entry")
    ap("    // 该条目参与各更新通道的命中(优先命中 & 是本条目)")
    ap("    logic hitS4, hitS6;        // 本拍是否分配到本条目")
    ap("    logic snRxdatHit0, snRxdatHit1; // ch0(按 dataID[1])")
    ap("    logic rnRxdatHit;          // ch2")
    ap("    logic byp0Hit;             // ch6")
    ap("    logic byp1Hit;             // ch7")
    ap("    assign hitS4       = allocS4OH[i];")
    ap("    assign hitS6       = allocS6OH[i];")
    ap("    assign snRxdatHit0 = io_snRxdat_valid & (|uv0) & (uid0 == IDX'(i)) & ~io_snRxdat_bits_dataID[1];")
    ap("    assign snRxdatHit1 = io_snRxdat_valid & (|uv0) & (uid0 == IDX'(i)) &  io_snRxdat_bits_dataID[1];")
    ap("    assign rnRxdatHit  = io_rnRxdat_valid & (|uv2) & (uid2 == IDX'(i));")
    ap("    assign byp0Hit     = io_bypassData_0_valid & (|uv6) & (uid6 == IDX'(i));")
    ap("    assign byp1Hit     = io_bypassData_1_valid & (|uv7) & (uid7 == IDX'(i));")
    ap("    // s_comp: 出队(txrsp/txdat 命中本条目)置位, 否则保持(除本拍分配清 0)")
    ap("    logic sCompHold;")
    ap("    assign sCompHold = ~(hitS4 | hitS6) & buffer_s_comp[i];")
    ap("    // beatValids0 下一态(_GEN_151 家族)")
    ap("    logic nextBeat0;")
    ap("    assign nextBeat0 = rnRxdatHit ? newBeatValids[0]")
    ap("      : (snRxdatHit0 | (~hitS4 & (hitS6 | buffer_beat0[i])));")
    ap("    // w_datRsp 下一态(_GEN_196 家族)")
    ap("    logic nextWDatRsp;")
    ap("    assign nextWDatRsp = rnRxdatHit ? (&newBeatValids)")
    ap("      : ((io_snRxdat_valid & (|uv0) & (uid0 == IDX'(i))) ? snRxdatBothBeats")
    ap("        : (hitS4 ? io_fromMainPipe_alloc_s4_bits_state_w_datRsp : (hitS6 | buffer_w_datRsp[i])));")
    ap("")
    ap("    always_ff @(posedge clock or posedge reset) begin")
    ap("      if (reset) begin")
    ap("        buffer_valid[i]   <= 1'b0;")
    ap("        buffer_task[i]    <= '0;")
    for s in STATE_FIELDS:
        ap(f"        buffer_{s}[i]{' '*(12-len(s))}<= 1'b0;")
    ap("        buffer_data0[i]   <= 256'h0;")
    ap("        buffer_data1[i]   <= 256'h0;")
    ap("        buffer_beat0[i]   <= 1'b0;")
    ap("        buffer_beat1[i]   <= 1'b0;")
    ap("        buffer_is_miss[i] <= 1'b0;")
    ap("        bufferTimer[i]    <= 16'h0;")
    ap("        REG_valid_d[i]    <= 1'b0;")
    ap("      end else begin")
    ap("        // ---- valid: will_free 清 0; 否则分配置位或保持 ----")
    ap("        buffer_valid[i] <= ~will_free[i]")
    ap("          & (canAlloc_s4 ? (hitS4 | hitS6 | buffer_valid[i]) : (hitS6 | buffer_valid[i]));")
    ap("        // ---- task payload: s4 优先, 否则 s6(除 snpVec_0/resp 单独选择) ----")
    ap("        if (hitS4) begin")
    for f in ALLOC_TASK_FIELDS:
        ap(f"          buffer_task[i].{f}{' '*(18-len(f))}<= io_fromMainPipe_alloc_s4_bits_task.{f};")
    ap("          buffer_is_miss[i] <= io_fromMainPipe_alloc_s4_bits_is_miss;")
    ap("        end else begin")
    ap("          if (hitS6) begin")
    for f in ALLOC_TASK_FIELDS:
        ap(f"            buffer_task[i].{f}{' '*(18-len(f))}<= io_fromMainPipe_alloc_s6_bits_task.{f};")
    ap("          end")
    ap("          buffer_is_miss[i] <= ~hitS6 & buffer_is_miss[i];")
    ap("        end")
    ap("        // ---- snpVec_0 & w_snpRsp: 合并 snoop 响应优先级链 ----")
    ap("        if (mergeSnp & (uid4 == IDX'(i))) begin")
    ap("          buffer_task[i].snpVec_0 <= newSnpVec_2_0;")
    ap("          buffer_w_snpRsp[i]      <= ~newSnpVec_2_0;")
    ap("        end else if (io_rnRxrsp_valid & (|uv3) & (uid3 == IDX'(i))) begin")
    ap("          buffer_task[i].snpVec_0 <= newSnpVec_1_0;")
    ap("          buffer_w_snpRsp[i]      <= ~newSnpVec_1_0;")
    ap("        end else if (rnRxdatHit) begin")
    ap("          buffer_task[i].snpVec_0 <= newSnpVec_0;")
    ap("          buffer_w_snpRsp[i]      <= ~newSnpVec_0;")
    ap("        end else if (hitS4) begin")
    ap("          buffer_task[i].snpVec_0 <= io_fromMainPipe_alloc_s4_bits_task.snpVec_0;")
    ap("          buffer_w_snpRsp[i]      <= io_fromMainPipe_alloc_s4_bits_state_w_snpRsp;")
    ap("        end else if (hitS6) begin")
    ap("          buffer_task[i].snpVec_0 <= io_fromMainPipe_alloc_s6_bits_task.snpVec_0;")
    ap("          buffer_w_snpRsp[i]      <= io_fromMainPipe_alloc_s6_bits_state_w_snpRsp;")
    ap("        end")
    ap("        // ---- task.resp: rnRxdat readUnique 升级 | s4 | s6 ----")
    ap("        if (rnRxdatRespHi & isReadUnique & (uid2 == IDX'(i)))")
    ap("          buffer_task[i].resp <= newResp;")
    ap("        else if (hitS4) buffer_task[i].resp <= io_fromMainPipe_alloc_s4_bits_task.resp;")
    ap("        else if (hitS6) buffer_task[i].resp <= io_fromMainPipe_alloc_s6_bits_task.resp;")
    ap("        // ---- s_comp: 出队(txrsp/txdat 命中)置位, 否则保持 ----")
    ap("        buffer_s_comp[i] <= txrspFire ? (txrspDeqOH[i] | txdatDeqOH[i] | sCompHold)")
    ap("                                      : (txdatDeqOH[i] | sCompHold);")
    ap("        // ---- s_urgentRead: urgentRead 发出置位 | ch3 合并 | 分配/保持 ----")
    ap("        buffer_s_urgentRead[i] <= (urgentFire & (urgentIdx == IDX'(i)))")
    ap("          | ((io_rnRxrsp_valid & (|uv3) & (uid3 == IDX'(i))) ? sUrgSetByRnRxrsp")
    ap("             : ((hitS4 | hitS6) | buffer_s_urgentRead[i]));")
    ap("        // ---- w_datRsp: will_free 清 0; 否则 bypass1/bypass0/其它通道 ----")
    ap("        buffer_w_datRsp[i] <= ~will_free[i]")
    ap("          & ((io_bypassData_1_valid & (|uv7)) ? ((uid7 == IDX'(i)) | byp0Hit | nextWDatRsp)")
    ap("             : (byp0Hit | nextWDatRsp));")
    ap("        // ---- w_compack: ch5(rnRxrsp op2) 置位 | s4 | 保持 ----")
    ap("        buffer_w_compack[i] <= (io_rnRxrsp_valid & (|uv5) & (uid5 == IDX'(i)))")
    ap("          | (hitS4 ? io_fromMainPipe_alloc_s4_bits_state_w_compack")
    ap("                   : (~hitS6 & buffer_w_compack[i]));")
    ap("        // ---- w_comp: ch1(snRxrsp) 置位 & readUnique/非readOnce 门控 | s4 | s6/保持 ----")
    ap("        buffer_w_comp[i] <= (~rnRxdatRespHi | isReadUnique | ~(isReadOnce & (uid2 == IDX'(i))))")
    ap("          & ((io_snRxrsp_valid & (|uv1) & (uid1 == IDX'(i)))")
    ap("             | (hitS4 ? io_fromMainPipe_alloc_s4_bits_state_w_comp")
    ap("                      : (hitS6 | buffer_w_comp[i])));")
    ap("        // ---- data beat0: bypass1/bypass0/rnRxdat/snRxdat/s6 优先链 ----")
    ap("        if (byp1Hit & ~io_bypassData_1_bits_dataID[1])")
    ap("          buffer_data0[i] <= io_bypassData_1_bits_data_data;")
    ap("        else if (byp0Hit) buffer_data0[i] <= io_bypassData_0_bits_data_data;")
    ap("        else if (rnRxdatHit & ~io_rnRxdat_bits_dataID[1]) buffer_data0[i] <= io_rnRxdat_bits_data_data;")
    ap("        else if (snRxdatHit0) buffer_data0[i] <= io_snRxdat_bits_data_data;")
    ap("        else if (hitS6) buffer_data0[i] <= io_fromMainPipe_alloc_s6_bits_data_data_0_data;")
    ap("        // ---- data beat1 ----")
    ap("        if (byp1Hit & io_bypassData_1_bits_dataID[1])")
    ap("          buffer_data1[i] <= io_bypassData_1_bits_data_data;")
    ap("        else if (rnRxdatHit & io_rnRxdat_bits_dataID[1]) buffer_data1[i] <= io_rnRxdat_bits_data_data;")
    ap("        else if (snRxdatHit1) buffer_data1[i] <= io_snRxdat_bits_data_data;")
    ap("        else if (hitS6) buffer_data1[i] <= io_fromMainPipe_alloc_s6_bits_data_data_1_data;")
    ap("        // ---- beatValids ----")
    ap("        if (byp1Hit) buffer_beat0[i] <= ~io_bypassData_1_bits_dataID[1] | byp0Hit | nextBeat0;")
    ap("        else buffer_beat0[i] <= byp0Hit | nextBeat0;")
    ap("        buffer_beat1[i] <= (byp1Hit & io_bypassData_1_bits_dataID[1])")
    ap("          | (rnRxdatHit ? newBeatValids[1]")
    ap("             : (snRxdatHit1 | (~hitS4 & (hitS6 | buffer_beat1[i]))));")
    ap("        // ---- bufferTimer(死): valid→invalid 清 0, 否则 valid 自增 ----")
    ap("        if (REG_valid_d[i] & ~buffer_valid[i]) bufferTimer[i] <= 16'h0;")
    ap("        else if (buffer_valid[i]) bufferTimer[i] <= 16'(bufferTimer[i] + 16'h1);")
    ap("        REG_valid_d[i] <= buffer_valid[i];")
    ap("      end")
    ap("    end")
    ap("  end")
    ap("")

    # ---------------- arbiter instances ----------------
    ap("  // ============ FastArbiter_50 (txrsp) / FastArbiter_52 (txdat) 两侧 elaborate ============")
    gen_arb_inst(ap, "FastArbiter_50", "txrspArb", "txrsp")
    gen_arb_inst(ap, "FastArbiter_52", "txdatArb", "txdat")
    ap("")

    # ---------------- outputs ----------------
    ap("  // ============ 输出装配 ============")
    ap("  assign io_txrsp_valid = txrspArb_out_valid;")
    ap("  // txrsp.chiOpcode: 高 6 位 2, 低位由仲裁出的 opcode 判定(golden 编码)")
    ap("  assign io_txrsp_bits_chiOpcode =")
    ap("    {6'h2, (txrspArb_out_chiOpcode == 7'h1B) | (txrspArb_out_chiOpcode == 7'h17)")
    ap("         | ((txrspArb_out_chiOpcode == 7'h42) & isMissVec[txrspArb_chosen])};")
    ap("  assign io_txdat_valid = txdatArb_out_valid;")
    ap("  // respInfo[16]")
    ap("  for (genvar i = 0; i < N; i++) begin : g_respinfo")
    ap("    assign io_respInfo_valid[i]     = buffer_valid[i] & ~will_free[i];")
    ap("    assign io_respInfo_set[i]       = buffer_task[i].set;")
    ap("    assign io_respInfo_tag[i]       = buffer_task[i].tag;")
    ap("    assign io_respInfo_opcode[i]    = buffer_task[i].chiOpcode;")
    ap("    assign io_respInfo_reqID[i]     = buffer_task[i].reqID;")
    ap("    assign io_respInfo_w_snpRsp[i]  = buffer_w_snpRsp[i];")
    ap("    assign io_respInfo_w_compdata[i]= buffer_w_datRsp[i];")
    ap("    assign io_respInfo_w_compack[i] = buffer_w_compack[i]")
    ap("      | (io_rnRxrsp_valid & rnRxrspOp2 & (io_rnRxrsp_bits_txnID == buffer_task[i].reqID));")
    ap("    assign io_respInfo_is_miss[i]   = buffer_is_miss[i];")
    ap("  end")
    ap("  // urgentRead")
    ap("  assign io_urgentRead_valid       = |urgent_vec;")
    ap("  assign io_urgentRead_bits_set    = buffer_task[urgentIdx].set;")
    ap("  assign io_urgentRead_bits_bank   = buffer_task[urgentIdx].bank;")
    ap("  assign io_urgentRead_bits_tag    = buffer_task[urgentIdx].tag;")
    ap("  assign io_urgentRead_bits_tgtID  = buffer_task[urgentIdx].tgtID;")
    ap("  assign io_urgentRead_bits_srcID  = buffer_task[urgentIdx].srcID;")
    ap("  assign io_urgentRead_bits_txnID  = buffer_task[urgentIdx].reqID;")
    ap("  assign io_urgentRead_bits_pCrdType = buffer_task[urgentIdx].pCrdType;")
    ap("")
    ap("endmodule")
    return "\n".join(L) + "\n"


# ---------------------------------------------------------------------------
# 生成一个 FastArbiter 实例(txrspArb=FastArbiter_50 全 task 端口;
# txdatArb=FastArbiter_52 仅 txdat 子集端口)。valid 表达式按 golden。
# ---------------------------------------------------------------------------
def gen_arb_inst(ap, arb_type, inst, kind):
    ap(f"  {arb_type} {inst} (")
    ap("    .clock (clock), .reset (reset),")
    for i in range(N):
        if kind == "txrsp":
            # valid = will_free_T & w_snpRsp & w_comp & s_urgentRead & ~s_comp & ~isRead
            v = (f"buffer_valid[{i}] & buffer_w_datRsp[{i}] & buffer_w_snpRsp[{i}] "
                 f"& buffer_w_comp[{i}] & buffer_s_urgentRead[{i}] & ~buffer_s_comp[{i}] & ~isRead[{i}]")
            ap(f"    .io_in_{i}_valid ({v}),")
            # FastArbiter_50 io_in 不含 homeNID(golden 未连该字段)
            for f, _ in TASK_FIELDS:
                if f == "homeNID":
                    continue
                ap(f"    .io_in_{i}_bits_{f} (buffer_task[{i}].{f}),")
        else:
            # txdat valid = will_free_T & w_snpRsp & s_urgentRead & ~s_comp & isRead
            v = (f"buffer_valid[{i}] & buffer_w_datRsp[{i}] & buffer_w_snpRsp[{i}] "
                 f"& buffer_s_urgentRead[{i}] & ~buffer_s_comp[{i}] & isRead[{i}]")
            ap(f"    .io_in_{i}_valid ({v}),")
            for f in ["tgtID", "srcID", "txnID", "homeNID", "dbID", "resp", "fwdState"]:
                ap(f"    .io_in_{i}_bits_task_{f} (buffer_task[{i}].{f}),")
            ap(f"    .io_in_{i}_bits_data_data_0_data (buffer_data0[{i}]),")
            ap(f"    .io_in_{i}_bits_data_data_1_data (buffer_data1[{i}]),")
    # io_out mapping
    if kind == "txrsp":
        ap("    .io_out_ready (io_txrsp_ready),")
        ap("    .io_out_valid (txrspArb_out_valid),")
        ap("    .io_out_bits_set (), .io_out_bits_bank (), .io_out_bits_tag (),")
        ap("    .io_out_bits_off (), .io_out_bits_size (), .io_out_bits_refillTask (),")
        ap("    .io_out_bits_bufID (), .io_out_bits_reqID (), .io_out_bits_replSnp (),")
        ap("    .io_out_bits_snpVec_0 (),")
        ap("    .io_out_bits_tgtID (io_txrsp_bits_tgtID),")
        ap("    .io_out_bits_srcID (io_txrsp_bits_srcID),")
        ap("    .io_out_bits_txnID (io_txrsp_bits_txnID),")
        ap("    .io_out_bits_dbID (io_txrsp_bits_dbID),")
        ap("    .io_out_bits_fwdNID (), .io_out_bits_fwdTxnID (),")
        ap("    .io_out_bits_chiOpcode (txrspArb_out_chiOpcode),")
        ap("    .io_out_bits_resp (io_txrsp_bits_resp),")
        ap("    .io_out_bits_fwdState (io_txrsp_bits_fwdState),")
        ap("    .io_out_bits_pCrdType (io_txrsp_bits_pCrdType),")
        ap("    .io_out_bits_retToSrc (), .io_out_bits_doNotGoToSD (),")
        ap("    .io_out_bits_expCompAck (), .io_out_bits_allowRetry (), .io_out_bits_order (),")
        ap("    .io_out_bits_memAttr_allocate (), .io_out_bits_memAttr_cacheable (),")
        ap("    .io_out_bits_memAttr_device (), .io_out_bits_memAttr_ewa (), .io_out_bits_snpAttr (),")
        ap("    .io_chosen (txrspArb_chosen)")
    else:
        ap("    .io_out_ready (io_txdat_ready),")
        ap("    .io_out_valid (txdatArb_out_valid),")
        ap("    .io_out_bits_task_tgtID (io_txdat_bits_task_tgtID),")
        ap("    .io_out_bits_task_srcID (io_txdat_bits_task_srcID),")
        ap("    .io_out_bits_task_txnID (io_txdat_bits_task_txnID),")
        ap("    .io_out_bits_task_homeNID (io_txdat_bits_task_homeNID),")
        ap("    .io_out_bits_task_dbID (io_txdat_bits_task_dbID),")
        ap("    .io_out_bits_task_resp (io_txdat_bits_task_resp),")
        ap("    .io_out_bits_task_fwdState (io_txdat_bits_task_fwdState),")
        ap("    .io_out_bits_data_data_0_data (io_txdat_bits_data_data_0_data),")
        ap("    .io_out_bits_data_data_1_data (io_txdat_bits_data_data_1_data),")
        ap("    .io_chosen (txdatArb_chosen)")
    ap("  );")


# ---------------------------------------------------------------------------
# 解析 golden ResponseUnit.sv 的扁平端口列表 → [(dir, width, name), ...]
# ---------------------------------------------------------------------------
import re

GOLDEN = "/home/eda/xs-env/G0-canonical/golden-rtl/ResponseUnit.sv"


def parse_golden_ports():
    ports = []
    inmod = False
    with open(GOLDEN) as f:
        for line in f:
            if line.startswith("module ResponseUnit("):
                inmod = True
                continue
            if inmod:
                if line.startswith(");"):
                    break
                m = re.match(r"\s+(input|output)\s+(\[\d+:\d+\])?\s*([A-Za-z0-9_]+)", line)
                if m:
                    d, w, n = m.group(1), m.group(2) or "", m.group(3)
                    ports.append((d, w, n))
    return ports


# ru_task_t 字段打包(struct 字面量, 供 wrapper 把扁平 task_* 端口打包)
def task_pack(prefix):
    parts = [f"{f}: {prefix}_{f}" for f, _ in TASK_FIELDS]
    return "'{" + ", ".join(parts) + "}"


# ---------------------------------------------------------------------------
# 生成扁平端口包装模块(module_name)。golden 同名扁平端口 ↔ 核 struct/数组端口。
# ---------------------------------------------------------------------------
def gen_wrapper(module_name):
    ports = parse_golden_ports()
    L = []
    ap = L.append
    ap(f"// {module_name} 包装层: golden 同名扁平端口 ↔ xs_ResponseUnit_core struct/数组端口。")
    ap("// 仅机械打包/拆包, 供 FM 对比与 ST 替换。")
    ap(f"module {module_name}")
    ap("  import xs_responseunit_pkg::*;")
    ap("(")
    decls = []
    for d, w, n in ports:
        ww = f"{w:8}" if w else "        "
        decls.append(f"  {d:6} {ww} {n}")
    ap(",\n".join(decls))
    ap(");")
    ap("")
    # pack s4/s6 task structs
    ap("  ru_task_t s4_task, s6_task;")
    ap("  assign s4_task = " + task_pack("io_fromMainPipe_alloc_s4_bits_task") + ";")
    ap("  assign s6_task = " + task_pack("io_fromMainPipe_alloc_s6_bits_task") + ";")
    ap("")
    ap("  // respInfo[16] 输出数组 → 扁平端口拆包")
    for fld in ["valid"]:
        ap(f"  logic [N-1:0]       ri_{fld};")
    ap("  logic [N-1:0][11:0] ri_set;")
    ap("  logic [N-1:0][27:0] ri_tag;")
    ap("  logic [N-1:0][6:0]  ri_opcode;")
    ap("  logic [N-1:0][11:0] ri_reqID;")
    ap("  logic [N-1:0]       ri_w_snpRsp, ri_w_compdata, ri_w_compack, ri_is_miss;")
    ap("")
    ap("  xs_ResponseUnit_core u_core (")
    ap("    .clock (clock), .reset (reset),")
    # scalar/struct connections for alloc + channels + ready
    core_scalar = [
        "io_fromMainPipe_alloc_s4_valid",
        "io_fromMainPipe_alloc_s4_bits_state_w_datRsp",
        "io_fromMainPipe_alloc_s4_bits_state_w_snpRsp",
        "io_fromMainPipe_alloc_s4_bits_state_w_compack",
        "io_fromMainPipe_alloc_s4_bits_state_w_comp",
        "io_fromMainPipe_alloc_s4_bits_is_miss",
        "io_fromMainPipe_alloc_s6_valid",
        "io_fromMainPipe_alloc_s6_bits_state_w_snpRsp",
        "io_fromMainPipe_alloc_s6_bits_data_data_0_data",
        "io_fromMainPipe_alloc_s6_bits_data_data_1_data",
        "io_snRxdat_valid", "io_snRxdat_bits_txnID", "io_snRxdat_bits_opcode",
        "io_snRxdat_bits_dataID", "io_snRxdat_bits_data_data",
        "io_snRxrsp_valid", "io_snRxrsp_bits_txnID", "io_snRxrsp_bits_opcode",
        "io_bypassData_0_valid", "io_bypassData_0_bits_txnID", "io_bypassData_0_bits_opcode",
        "io_bypassData_0_bits_data_data",
        "io_bypassData_1_valid", "io_bypassData_1_bits_txnID", "io_bypassData_1_bits_opcode",
        "io_bypassData_1_bits_dataID", "io_bypassData_1_bits_data_data",
        "io_rnRxdat_valid", "io_rnRxdat_bits_txnID", "io_rnRxdat_bits_opcode",
        "io_rnRxdat_bits_resp", "io_rnRxdat_bits_srcID", "io_rnRxdat_bits_dataID",
        "io_rnRxdat_bits_data_data",
        "io_rnRxrsp_valid", "io_rnRxrsp_bits_txnID", "io_rnRxrsp_bits_opcode",
        "io_rnRxrsp_bits_srcID",
        "io_txrsp_ready", "io_txdat_ready", "io_urgentRead_ready",
        # txrsp outputs
        "io_txrsp_valid", "io_txrsp_bits_tgtID", "io_txrsp_bits_srcID",
        "io_txrsp_bits_txnID", "io_txrsp_bits_dbID", "io_txrsp_bits_chiOpcode",
        "io_txrsp_bits_resp", "io_txrsp_bits_fwdState", "io_txrsp_bits_pCrdType",
        # txdat outputs
        "io_txdat_valid", "io_txdat_bits_task_tgtID", "io_txdat_bits_task_srcID",
        "io_txdat_bits_task_txnID", "io_txdat_bits_task_homeNID", "io_txdat_bits_task_dbID",
        "io_txdat_bits_task_resp", "io_txdat_bits_task_fwdState",
        "io_txdat_bits_data_data_0_data", "io_txdat_bits_data_data_1_data",
        # urgentRead outputs
        "io_urgentRead_valid", "io_urgentRead_bits_set", "io_urgentRead_bits_bank",
        "io_urgentRead_bits_tag", "io_urgentRead_bits_tgtID", "io_urgentRead_bits_srcID",
        "io_urgentRead_bits_txnID", "io_urgentRead_bits_pCrdType",
    ]
    ap("    .io_fromMainPipe_alloc_s4_bits_task (s4_task),")
    ap("    .io_fromMainPipe_alloc_s6_bits_task (s6_task),")
    for s in core_scalar:
        ap(f"    .{s} ({s}),")
    # respInfo array ports → local arrays
    ap("    .io_respInfo_valid (ri_valid),")
    ap("    .io_respInfo_set (ri_set),")
    ap("    .io_respInfo_tag (ri_tag),")
    ap("    .io_respInfo_opcode (ri_opcode),")
    ap("    .io_respInfo_reqID (ri_reqID),")
    ap("    .io_respInfo_w_snpRsp (ri_w_snpRsp),")
    ap("    .io_respInfo_w_compdata (ri_w_compdata),")
    ap("    .io_respInfo_w_compack (ri_w_compack),")
    ap("    .io_respInfo_is_miss (ri_is_miss)")
    ap("  );")
    ap("")
    # fan out respInfo arrays to flat ports
    for i in range(N):
        ap(f"  assign io_respInfo_{i}_valid       = ri_valid[{i}];")
        ap(f"  assign io_respInfo_{i}_bits_set    = ri_set[{i}];")
        ap(f"  assign io_respInfo_{i}_bits_tag    = ri_tag[{i}];")
        ap(f"  assign io_respInfo_{i}_bits_opcode = ri_opcode[{i}];")
        ap(f"  assign io_respInfo_{i}_bits_reqID  = ri_reqID[{i}];")
        ap(f"  assign io_respInfo_{i}_bits_w_snpRsp  = ri_w_snpRsp[{i}];")
        ap(f"  assign io_respInfo_{i}_bits_w_compdata= ri_w_compdata[{i}];")
        ap(f"  assign io_respInfo_{i}_bits_w_compack = ri_w_compack[{i}];")
        ap(f"  assign io_respInfo_{i}_bits_is_miss   = ri_is_miss[{i}];")
    ap("")
    ap("endmodule")
    return "\n".join(L) + "\n"


# ---------------------------------------------------------------------------
# 生成 UT testbench: golden ResponseUnit vs ResponseUnit_xs 双例化, 随机激励逐拍比对。
# ---------------------------------------------------------------------------
def gen_tb():
    ports = parse_golden_ports()
    inputs = [(w, n) for d, w, n in ports if d == "input" and n not in ("clock", "reset")]
    outputs = [(w, n) for d, w, n in ports if d == "output"]

    def wof(w):
        if not w:
            return 1
        m = re.match(r"\[(\d+):(\d+)\]", w)
        return int(m.group(1)) - int(m.group(2)) + 1

    L = []
    ap = L.append
    ap("// 自动生成: gen_responseunit.py gen_tb() —— 勿手改")
    ap("`timescale 1ns/1ps")
    ap("module tb;")
    ap("  int unsigned NCYCLES = 200000;")
    ap("  int unsigned WARMUP  = 8;")
    ap("  bit clk = 0, rst;")
    ap("  int errors = 0, checks = 0, cyc = 0;")
    ap("  always #5 clk = ~clk;")
    ap("")
    for w, n in inputs:
        ap(f"  logic {w+' ' if w else ''}{n};")
    for w, n in outputs:
        ap(f"  wire {w+' ' if w else ''}g_{n};")
        ap(f"  wire {w+' ' if w else ''}i_{n};")
    ap("")
    for inst, pref in [("ResponseUnit", "g_"), ("ResponseUnit_xs", "i_")]:
        ap(f"  {inst} dut_{pref[0]} (")
        ap("    .clock(clk), .reset(rst),")
        ap(",\n".join(f"    .{n}({n})" for _, n in inputs) + ",")
        ap(",\n".join(f"    .{n}({pref}{n})" for _, n in outputs))
        ap("  );")
        ap("")
    # stimulus
    ap("  task automatic drive_random();")
    for w, n in inputs:
        wd = wof(w)
        if wd <= 32:
            ap(f"    {n} = $random;")
        else:
            chunks = (wd + 31) // 32
            ap(f"    {n} = {{{','.join('$random' for _ in range(chunks))}}};")
    ap("    // 偏置: 使控制路径更常被触发")
    ap("    if (($random & 1) == 0) io_snRxdat_bits_opcode = 7'h4;")
    ap("    if (($random & 1) == 0) io_rnRxdat_bits_opcode = 7'h1;")
    ap("    if (($random & 1) == 0) io_rnRxrsp_bits_opcode = 7'h1;")
    ap("    if (($random & 3) == 0) io_rnRxrsp_bits_opcode = 7'h2;")
    ap("    if (($random & 3) == 0) io_snRxrsp_bits_opcode = 7'h5;")
    ap("    if (($random & 1) == 0) io_bypassData_0_bits_opcode = 7'h4;")
    ap("    if (($random & 1) == 0) io_bypassData_1_bits_opcode = 7'h4;")
    ap("    if (($random & 3) != 0) io_txrsp_ready = 1'b1;")
    ap("    if (($random & 3) != 0) io_txdat_ready = 1'b1;")
    ap("    if (($random & 3) != 0) io_urgentRead_ready = 1'b1;")
    ap("    // 让响应通道的 txnID 常命中已分配条目的 reqID(偏置到小范围)")
    ap("    io_snRxdat_bits_txnID = $random & 12'h1F;")
    ap("    io_snRxrsp_bits_txnID = $random & 12'h1F;")
    ap("    io_rnRxdat_bits_txnID = $random & 12'h1F;")
    ap("    io_rnRxrsp_bits_txnID = $random & 12'h1F;")
    ap("    io_bypassData_0_bits_txnID = $random & 12'h1F;")
    ap("    io_bypassData_1_bits_txnID = $random & 12'h1F;")
    ap("    io_fromMainPipe_alloc_s4_bits_task_reqID = $random & 12'h1F;")
    ap("    io_fromMainPipe_alloc_s6_bits_task_reqID = $random & 12'h1F;")
    ap("  endtask")
    ap("")
    ap("  task automatic check_outputs();")
    ap("    checks++;")
    for w, n in outputs:
        ap(f"    if (g_{n} !== i_{n}) begin errors++; if (errors<=20) $display(\"[%0d] MISMATCH {n}: g=%h i=%h\", cyc, g_{n}, i_{n}); end")
    ap("  endtask")
    ap("")
    ap("  initial begin")
    ap("    rst = 1'b1;")
    for w, n in inputs:
        ap(f"    {n} = '0;")
    ap("    repeat (6) @(posedge clk);")
    ap("    @(negedge clk); rst = 1'b0;")
    ap("    for (cyc = 0; cyc < NCYCLES; cyc++) begin")
    ap("      @(negedge clk);")
    ap("      drive_random();")
    ap("      @(posedge clk);")
    ap("      #1;")
    ap("      if (cyc >= WARMUP) check_outputs();")
    ap("    end")
    ap("    if (errors == 0)")
    ap("      $display(\"TEST PASSED: checks=%0d errors=0\", checks);")
    ap("    else")
    ap("      $display(\"TEST FAILED: checks=%0d errors=%0d\", checks, errors);")
    ap("    $finish;")
    ap("  end")
    ap("endmodule")
    return "\n".join(L) + "\n"


# ---------------------------------------------------------------------------
# 生成 fm_pins.tcl: bufferTimer_N[b] / REG_N 对称死寄存器双射(class-4 加强)。
# ---------------------------------------------------------------------------
def gen_fm_pins():
    L = []
    ap = L.append
    ap("# ResponseUnit matched-unread 双射钉点: golden 展平名 ↔ impl 2D 数组名。")
    ap("# bufferTimer/REG 为泄漏检测计时器, 仅被 `ifndef SYNTHESIS 断言读取 → 两侧对称 cone-dead。")
    ap("# 显式 set_user_match 建立 1:1 双射, 配合 verify_matched_unread_compare_points=true")
    ap("# 让 FM 实际比较证明等价(class-4 加强证明, 非 waiver)。")
    for i in range(N):
        for b in range(16):
            ap(f"set_user_match r:/WORK/ResponseUnit/bufferTimer_{i}_reg\\[{b}\\] "
               f"i:/WORK/ResponseUnit/u_core/bufferTimer_reg\\[{i}\\]\\[{b}\\]")
    ap("set_user_match r:/WORK/ResponseUnit/REG_reg i:/WORK/ResponseUnit/u_core/REG_valid_d_reg\\[0\\]")
    for i in range(1, N):
        ap(f"set_user_match r:/WORK/ResponseUnit/REG_{i}_reg "
           f"i:/WORK/ResponseUnit/u_core/REG_valid_d_reg\\[{i}\\]")
    return "\n".join(L) + "\n"


MAKEFILE = """MODULE = ResponseUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_ResponseUnit_core(含 xs_responseunit_pkg)+ 扁平端口包装 ResponseUnit
RTL_SRCS = $(RTL_DIR)/l2/ResponseUnit.sv
# WRAPPER_SRCS 仅用于 FM impl 侧(不进 UT 编译): 扁平端口包装 + golden 两仲裁器
# (两侧 elaborate 确定性仲裁逻辑, 非厂商宏, 消除黑盒——impl 与 ref 同读同一子模块)。
WRAPPER_SRCS = $(RTL_DIR)/l2/ResponseUnit_wrapper.sv \\
               $(GOLDEN_RTL)/FastArbiter_50.sv $(GOLDEN_RTL)/FastArbiter_52.sv
# golden 顶层 + 其两个子模块(UT 双例化两侧共用同一定义)
GOLDEN_SRCS = $(GOLDEN_RTL)/ResponseUnit.sv \\
              $(GOLDEN_RTL)/FastArbiter_50.sv $(GOLDEN_RTL)/FastArbiter_52.sv
# UT 变体(impl 顶层改名 ResponseUnit_xs 以与 golden ResponseUnit 双例化)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 ResponseUnit 顶层；FastArbiter_50/52 两侧 elaborate 作为共同子模块
FM_VARIANTS = ResponseUnit
FM_REF_DEPS_ResponseUnit = FastArbiter_50.sv FastArbiter_52.sv

# bufferTimer(256)/REG(16) 为泄漏检测计时器, 仅被 `ifndef SYNTHESIS 断言读取 →
# 两侧对称 cone-dead。fm_pins.tcl 建立 golden 展平名 ↔ impl 2D 数组名的 1:1 双射,
# 配合 verify_matched_unread_compare_points=true 让 FM 实际比较证明等价(class-4 加强证明,
# 非 waiver)。ResponseUnit 须由 main 加入 fm_eq.tcl/run_signoff_target.sh 的
# matched-unread 白名单方可运行本加强(standing rule)。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden ResponseUnit 含 `ifndef SYNTHESIS 的随机初值与断言(ResponseBuf overflow /
# Response task repeated / ResponseBuf Leak);UT 随机激励会触发, 故定义 SYNTHESIS 关掉
# (同时关随机初值注入, 使两侧寄存器复位到 0 后同构可比)。
VCS += +define+SYNTHESIS
"""


if __name__ == "__main__":
    with open("../../../rtl/l2/ResponseUnit.sv", "w") as f:
        f.write(gen_core())
    print("wrote rtl/l2/ResponseUnit.sv")
    with open("../../../rtl/l2/ResponseUnit_wrapper.sv", "w") as f:
        f.write(gen_wrapper("ResponseUnit"))
    print("wrote rtl/l2/ResponseUnit_wrapper.sv")
    with open("variants_xs.sv", "w") as f:
        f.write(gen_wrapper("ResponseUnit_xs"))
    print("wrote variants_xs.sv")
    with open("tb.sv", "w") as f:
        f.write(gen_tb())
    print("wrote tb.sv")
    with open("fm_pins.tcl", "w") as f:
        f.write(gen_fm_pins())
    print("wrote fm_pins.tcl")
    with open("Makefile", "w") as f:
        f.write(MAKEFILE)
    print("wrote Makefile")
