#!/usr/bin/env python3
"""coupledL2 (tl2chi) MainPipe 可读核 xs_MainPipe_core 生成器 (被 gen_l2mainpipe.py 调用)。

从 Scala coupledL2/.../tl2chi/MainPipe.scala 逐级 when 重写, golden=MainPipe_1 单态化交叉核对。
s2(组合输入)→ s3(主计算: 命中/一致性/派发)→ s4(锁存 B 响应)→ s5(DS 读数据/收尾)。
内联 4 个优先 Arbiter(in0=s5>s4>s3); CustomL1Hint 黑盒(核出 7 个 hint 喂线)。
"""

from gen_grantbuffer import FIELDS, sv, decl
import re
from pathlib import Path

GOLDEN = Path(__file__).resolve().parents[1] / "golden" / "chisel-rtl"
GOLD = "MainPipe_1"

META = ["dirty", "state", "clients", "alias", "prefetch", "prefetchSrc",
        "accessed", "tagErr", "dataErr"]
FSM = ["s_acquire", "s_rprobe", "s_pprobe", "s_release", "s_probeack", "s_refill",
       "s_cmoresp", "w_rprobeackfirst", "w_rprobeacklast", "w_pprobeackfirst",
       "w_pprobeacklast", "w_grantfirst", "w_grantlast", "w_grant", "w_releaseack",
       "w_replResp", "s_rcompack", "s_dct"]
DIR = ["hit", "tag", "set", "way"] + ["meta_" + m for m in META] + ["error"]
MSHR_TASK = ["channel", "set", "tag", "off", "alias", "isKeyword", "opcode", "param",
             "sourceId", "aliasTask", "fromL2pft", "reqSource", "snpHitRelease",
             "snpHitReleaseToInval", "snpHitReleaseToClean", "snpHitReleaseWithData",
             "snpHitReleaseIdx", "snpHitReleaseMeta_dirty", "snpHitReleaseMeta_state",
             "snpHitReleaseMeta_clients", "snpHitReleaseMeta_alias",
             "snpHitReleaseMeta_prefetch", "snpHitReleaseMeta_prefetchSrc",
             "snpHitReleaseMeta_accessed", "snpHitReleaseMeta_tagErr",
             "snpHitReleaseMeta_dataErr", "srcID", "txnID", "fwdNID", "fwdTxnID",
             "chiOpcode", "retToSrc", "traceTag"]
HINT_S1 = ["channel", "isKeyword", "opcode", "sourceId", "mshrTask", "mergeA",
           "aMergeTask_isKeyword", "aMergeTask_opcode", "aMergeTask_sourceId"]

# TXREQ (CHIREQ) 暴露字段
TXREQ_F = [("tgtID", 11), ("srcID", 11), ("txnID", 12), ("opcode", 7), ("addr", 48),
           ("likelyshared", 1), ("allowRetry", 1), ("pCrdType", 4),
           ("memAttr_allocate", 1), ("memAttr_cacheable", 1), ("memAttr_device", 1),
           ("memAttr_ewa", 1), ("expCompAck", 1)]
# TXRSP 暴露字段
TXRSP_F = [("txChannel", 3), ("denied", 1), ("tgtID", 11), ("srcID", 11), ("txnID", 12),
           ("dbID", 12), ("chiOpcode", 7), ("resp", 3), ("fwdState", 3), ("pCrdType", 4),
           ("traceTag", 1)]

# source_req_s3 相对 req_s3(=task_s3 view) 覆盖的字段 → 各自的 SV 表达式
# (b_resp_ovr = sink_resp 有效 & fromB 时走 snoop 响应路径; 详见 golden _GEN_3)
SRC_OVR = {
    "opcode":    "sink_resp_s3_valid ? sink_resp_s3_bits_opcode : task_s3_bits_opcode",
    "param":     "sink_resp_s3_valid ? sink_resp_s3_bits_param : task_s3_bits_param",
    "mshrId":    "sink_resp_s3_valid ? (task_s3_bits_sourceId + 8'h80) : task_s3_bits_mshrId",
    "txChannel": "b_resp_ovr ? {doRespData, ~doRespData, 1'b0} : task_s3_bits_txChannel",
    "size":      "b_resp_ovr ? 3'h6 : task_s3_bits_size",
    "meta_dirty":      "b_resp_ovr ? 1'b0 : task_s3_bits_meta_dirty",
    "meta_state":      "b_resp_ovr ? metaW_s3_b_state : task_s3_bits_meta_state",
    "meta_clients":    "b_resp_ovr ? metaW_s3_b_clients : task_s3_bits_meta_clients",
    "meta_alias":      "b_resp_ovr ? metaW_s3_b_alias : task_s3_bits_meta_alias",
    "meta_prefetch":   "b_resp_ovr ? 1'b0 : task_s3_bits_meta_prefetch",
    "meta_prefetchSrc":"b_resp_ovr ? 3'h0 : task_s3_bits_meta_prefetchSrc",
    "meta_accessed":   "b_resp_ovr ? metaW_s3_b_accessed : task_s3_bits_meta_accessed",
    "meta_tagErr":     "b_resp_ovr ? metaW_s3_b_tagErr : task_s3_bits_meta_tagErr",
    "meta_dataErr":    "b_resp_ovr ? metaW_s3_b_dataErr : task_s3_bits_meta_dataErr",
    "metaWen":   "b_resp_ovr ? metaW_valid_s3_b : task_s3_bits_metaWen",
    "tgtID":     "b_resp_ovr ? task_s3_bits_srcID : task_s3_bits_tgtID",
    "srcID":     "b_resp_ovr ? task_s3_bits_tgtID : task_s3_bits_srcID",
    "dbID":      "b_resp_ovr ? 12'h0 : task_s3_bits_dbID",
    "chiOpcode": "b_resp_ovr ? snpResp_chiOpcode : task_s3_bits_chiOpcode",
    "resp":      "b_resp_ovr ? snpResp_resp : task_s3_bits_resp",
    "fwdState":  "b_resp_ovr ? snpResp_fwdState : task_s3_bits_fwdState",
    "pCrdType":  "b_resp_ovr ? 4'h0 : task_s3_bits_pCrdType",
}


def fld_decl(w, pad=8):
    return (decl(w)).ljust(pad)


def reg_block(prefix):
    """task_<prefix>_bits_<f> 寄存器声明 (95 字段, golden 扁平命名)。"""
    out = []
    for n, w in FIELDS:
        out.append(f"  logic {fld_decl(w)}task_{prefix}_bits_{n};")
    return out


def view_block(prefix, struct):
    """always_comb: 扁平 task_<prefix>_bits_* → 结构体 struct 视图。"""
    L = [f"  task_bundle_t {struct};", "  always_comb begin"]
    for n, _ in FIELDS:
        L.append(f"    {struct}.{sv(n):<22} = task_{prefix}_bits_{n};")
    L.append("  end")
    return L


def gen_core():
    L = []
    A = L.append
    A("// 自动生成 scripts/gen_l2mainpipe.py / gen_l2mainpipe_core.py —— 勿手改")
    A("// =============================================================================")
    A("//  MainPipe —— coupledL2 (tl2chi) L2 slice s2/s3/s4/s5 主流水 可读重写核")
    A("//          (xs_MainPipe_core, golden=MainPipe_1)")
    A("// -----------------------------------------------------------------------------")
    A("//  对照 Scala coupledL2/src/main/scala/coupledL2/tl2chi/MainPipe.scala。")
    A("//  s2: 组合收 RequestArb 的 task; s3: 主计算(读 Directory→判命中/一致性→派发);")
    A("//  s4: 锁存 sinkB 响应; s5: 收 DS 数据/发 releaseBuf/出 error。")
    A("//  4 个优先 Arbiter(in0=s5>s4>s3) 内联; CustomL1Hint 黑盒(核出 hint_s3_*)。")
    A("//  ===== X 铁律 =====")
    A("//    主流水寄存器异步复位置 0(resetIdx 起 511); data_s4/data_s5/io_perf_*_REG")
    A("//    为无复位 RegNext(+vcs+initreg+0 起 0)。寄存器全用 golden 扁平命名(FM/探针配对)。")
    A("// =============================================================================")
    A("module xs_MainPipe_core")
    A("  import l2_task_pkg::*;")
    A("(")
    A(core_ports())
    A(");")
    A("")
    # ---- 一致性/opcode 常量 ----
    A("  // ===== 一致性状态/opcode 常量(单态化) =====")
    A("  localparam logic [1:0] INVALID = 2'd0, BRANCH = 2'd1, TRUNK = 2'd2, TIP = 2'd3;")
    A("  // CHI Resp 编码: I=0 SC=1 UC=UD=2 SD=3; PassDirty=4")
    A("  localparam logic [2:0] CHI_I = 3'd0, CHI_SC = 3'd1, CHI_UC = 3'd2, CHI_SD = 3'd3;")
    A("  localparam logic [2:0] CHI_PD = 3'd4;")
    A("")
    A(funcs())
    A("")
    # ---- 复位计数 ----
    A("  // ===== 复位: resetIdx 倒数 512 拍, 期间逐 set 清 Directory =====")
    A("  logic        resetFinish;")
    A("  logic [8:0]  resetIdx;")
    A("")
    # ---- 流水寄存器声明 ----
    A("  // ===== 流水寄存器(扁平 golden 命名, 异步复位置 0 除 data_s4/s5) =====")
    A("  logic        task_s3_valid;")
    L += reg_block("s3")
    A("  logic        task_s4_valid;")
    L += reg_block("s4")
    A("  logic        task_s5_valid;")
    L += reg_block("s5")
    A("  logic        replResp_valid_s4;")
    A("  logic [1:0]  task_s3_valid_hold2;")
    A("  logic [511:0] data_s4;          // 无复位 RegNext")
    A("  logic        need_write_releaseBuf_s4, isD_s4, isTXREQ_s4, isTXRSP_s4, isTXDAT_s4;")
    A("  logic        tagError_s4, dataError_s4, l2Error_s4;")
    A("  logic        chnl_valid_s4_REG;")
    A("  logic [511:0] data_s5;          // 无复位 RegNext")
    A("  logic        need_write_releaseBuf_s5, isD_s5, isTXREQ_s5, isTXRSP_s5, isTXDAT_s5;")
    A("  logic        tagError_s5, dataMetaError_s5, l2TagError_s5;")
    A("  logic        chnl_valid_s5_REG, chnl_fire_s3_d1, chnl_fire_s3_d2;")
    A("  logic        io_perf_0_value_REG, io_perf_0_value_dly2;")
    A("  logic        io_perf_1_value_REG, io_perf_1_value_dly2;")
    A("  logic        io_perf_2_value_REG, io_perf_2_value_dly2;")
    A("  logic        io_perf_3_value_REG, io_perf_3_value_dly2;")
    A("  logic        io_perf_4_value_REG, io_perf_4_value_dly2;")
    A("  logic        io_perf_5_value_REG, io_perf_5_value_dly2;")
    A("  logic        io_perf_6_value_REG, io_perf_6_value_dly2;")
    A("  logic        io_perf_7_value_REG, io_perf_7_value_dly2;")
    A("")
    # ---- 结构体视图 ----
    A("  // ===== 结构体视图(便于逐字段派生) =====")
    L += view_block("s3", "req_s3")
    L += view_block("s4", "task_s4_v")
    L += view_block("s5", "task_s5_v")
    A("")
    L += s3_decode()
    A("")
    L += s3_snoop_resp()
    A("")
    L += s3_sink_source()
    A("")
    L += s3_ds_dir_nested()
    A("")
    L += s3_mshr_alloc()
    A("")
    L += s3_prefetch()
    A("")
    L += stage5()
    A("")
    L += channels()
    A("")
    L += stage4()
    A("")
    L += block_status_err_perf()
    A("")
    L += seq_blocks()
    A("")
    A("endmodule")
    A("")
    return "\n".join(L)


def core_ports():
    """核端口 = golden MainPipe_1 端口 - (taskInfo_s1/l1Hint) + 7 个 hint 输出。"""
    text = (GOLDEN / f"{GOLD}.sv").read_text()
    m = re.search(r"module\s+%s\s*\((.*?)\n\);" % GOLD, text, re.S)
    P = []
    for raw in m.group(1).splitlines():
        line = raw.split("//", 1)[0].strip().rstrip(",")
        if not line:
            continue
        mm = re.match(r"(input|output)\s+(?:(?:wire|logic|reg)\s+)?(\[[^\]]+\])?\s*([A-Za-z_]\w*)$", line)
        d, w, n = mm.groups()
        if n in ("clock", "reset"):
            continue
        if n.startswith("io_taskInfo_s1") or n.startswith("io_l1Hint"):
            continue
        P.append((d, w or "", n))
    out = ["  input  logic        clock,", "  input  logic        reset,"]
    for d, w, n in P:
        kw = "input " if d == "input" else "output"
        out.append(f"  {kw} logic {(w + ' ') if w else '':<8}{n},")
    # hint 喂线 (核 → CustomL1Hint)
    out.append("  // ---- 喂 CustomL1Hint 的 s3 信号 ----")
    out.append("  output logic        hint_s3_task_valid,")
    out.append("  output logic [2:0]  hint_s3_task_bits_channel,")
    out.append("  output logic        hint_s3_task_bits_isKeyword,")
    out.append("  output logic [3:0]  hint_s3_task_bits_opcode,")
    out.append("  output logic [6:0]  hint_s3_task_bits_sourceId,")
    out.append("  output logic        hint_s3_task_bits_mshrTask,")
    out.append("  output logic        hint_s3_need_mshr")
    return "\n".join(out)


def funcs():
    """权限/snoop 判定函数(仅读入参, 不捕获模块信号 → 安全)。"""
    L = []
    A = L.append
    A("  // ===== 权限/snoop 判定函数(只读入参) =====")
    A("  function automatic logic f_needT(input logic [3:0] op, input logic [2:0] pm);")
    A("    f_needT = (~op[2]) | (op == 4'd5 & pm == 3'd1) | ((op == 4'd6 | op == 4'd7) & pm != 3'd0);")
    A("  endfunction")
    A("  function automatic logic f_isToN(input logic [2:0] pm);   f_isToN = (pm==3'd1)|(pm==3'd2)|(pm==3'd5); endfunction")
    A("  function automatic logic f_isParamFromT(input logic [2:0] pm); f_isParamFromT = (pm==3'd0)|(pm==3'd1)|(pm==3'd3); endfunction")
    A("  function automatic logic f_isT(input logic [1:0] st); f_isT = st[1]; endfunction")
    A("  // CHI snoop opcode (7-bit) 判定")
    A("  function automatic logic f_isSnpXFwd(input logic [6:0] o);")
    A("    f_isSnpXFwd = (o==7'h11)|(o==7'h12)|(o==7'h13)|(o==7'h14)|(o==7'h17); endfunction")
    A("  function automatic logic f_isSnpStashX(input logic [6:0] o); f_isSnpStashX = (o==7'h0B)|(o==7'h0C); endfunction")
    A("  function automatic logic f_isSnpQuery(input logic [6:0] o);  f_isSnpQuery = (o==7'h10); endfunction")
    A("  function automatic logic f_isSnpOnceX(input logic [6:0] o);  f_isSnpOnceX = (o==7'h03)|(o==7'h13); endfunction")
    A("  function automatic logic f_isSnpUniqueX(input logic [6:0] o);")
    A("    f_isSnpUniqueX = (o==7'h07)|(o==7'h17)|(o==7'h05); endfunction")
    A("  function automatic logic f_isSnpMakeInvalidX(input logic [6:0] o); f_isSnpMakeInvalidX = (o==7'h0A)|(o==7'h06); endfunction")
    A("  function automatic logic f_isSnpToB(input logic [6:0] o);")
    A("    f_isSnpToB = (o==7'h01)|(o==7'h02)|(o==7'h04)|(o==7'h11)|(o==7'h12)|(o==7'h14); endfunction")
    A("  function automatic logic f_isSnpToBFwd(input logic [6:0] o); f_isSnpToBFwd = (o==7'h11)|(o==7'h12)|(o==7'h14); endfunction")
    A("  function automatic logic f_isSnpToBNonFwd(input logic [6:0] o); f_isSnpToBNonFwd = (o==7'h01)|(o==7'h02)|(o==7'h04); endfunction")
    A("  function automatic logic f_isSnpToN(input logic [6:0] o);")
    A("    f_isSnpToN = f_isSnpUniqueX(o) | (o==7'h09) | f_isSnpMakeInvalidX(o); endfunction")
    return "\n".join(L)


def s3_decode():
    """s3 通道/opcode 译码 + need_mshr 判定。"""
    L = []
    A = L.append
    A("  // ===== s3: 通道 one-hot / mshr / TL-opcode 译码 =====")
    A("  wire mshr_req_s3  = task_s3_bits_mshrTask;")
    A("  wire fromA_s3 = task_s3_bits_channel[0];")
    A("  wire fromB_s3 = task_s3_bits_channel[1];")
    A("  wire fromC_s3 = task_s3_bits_channel[2];")
    A("  wire toTXREQ_s3 = task_s3_bits_txChannel[0];")
    A("  wire toTXRSP_s3 = task_s3_bits_txChannel[1];")
    A("  wire toTXDAT_s3 = task_s3_bits_txChannel[2];")
    A("  wire sinkA_req_s3 = ~mshr_req_s3 & fromA_s3;")
    A("  wire sinkB_req_s3 = ~mshr_req_s3 & fromB_s3;")
    A("  wire sinkC_req_s3 = ~mshr_req_s3 & fromC_s3;")
    A("  // sinkA TL opcode: Get=4 Hint=5 AcquireBlock=6 AcquirePerm=7 CBOClean=12 CBOFlush=13 CBOInval=14")
    A("  wire req_acquire_s3      = sinkA_req_s3 & (task_s3_bits_opcode==4'd6 | task_s3_bits_opcode==4'd7);")
    A("  wire req_acquireBlock_s3 = sinkA_req_s3 & task_s3_bits_opcode==4'd6;")
    A("  wire req_prefetch_s3     = sinkA_req_s3 & task_s3_bits_opcode==4'd5;")
    A("  wire req_get_s3          = sinkA_req_s3 & task_s3_bits_opcode==4'd4;")
    A("  wire req_cbo_clean_s3    = sinkA_req_s3 & task_s3_bits_opcode==4'd12;")
    A("  wire req_cbo_flush_s3    = sinkA_req_s3 & task_s3_bits_opcode==4'd13;   // enableL2Flush=false → cmoHitInvalid=0")
    A("  wire req_cbo_inval_s3    = sinkA_req_s3 & task_s3_bits_opcode==4'd14;")
    A("  wire cmo_cbo_s3          = req_cbo_clean_s3 | req_cbo_flush_s3 | req_cbo_inval_s3;")
    A("  // mshr 任务 TL-D 类: Grant=4 GrantData=5 AccessAckData=1 HintAck=2 CBOAck=8")
    A("  wire mshr_grant_s3        = mshr_req_s3 & fromA_s3 & (task_s3_bits_opcode==4'd4 | task_s3_bits_opcode==4'd5);")
    A("  wire mshr_grantdata_s3    = mshr_req_s3 & fromA_s3 & task_s3_bits_opcode==4'd5;")
    A("  wire mshr_accessackdata_s3= mshr_req_s3 & fromA_s3 & task_s3_bits_opcode==4'd1;")
    A("  wire mshr_hintack_s3      = mshr_req_s3 & fromA_s3 & task_s3_bits_opcode==4'd2;")
    A("  wire mshr_cmoresp_s3      = mshr_req_s3 & fromA_s3 & task_s3_bits_opcode==4'd8;")
    A("  wire mshr_refill_s3       = mshr_accessackdata_s3 | mshr_hintack_s3 | mshr_grant_s3;")
    A("  // mshr 任务 CHI 类(按 txChannel + chiOpcode)")
    A("  wire mshr_snpResp_s3        = mshr_req_s3 & toTXRSP_s3 & task_s3_bits_chiOpcode==7'h01;")
    A("  wire mshr_snpRespFwded_s3   = mshr_req_s3 & toTXRSP_s3 & task_s3_bits_chiOpcode==7'h09;")
    A("  wire mshr_snpRespData_s3    = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h01;")
    A("  wire mshr_snpRespDataPtl_s3 = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h05;")
    A("  wire mshr_snpRespDataFwded_s3 = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h06;")
    A("  wire mshr_snpRespX_s3     = mshr_snpResp_s3 | mshr_snpRespFwded_s3;")
    A("  wire mshr_snpRespDataX_s3 = mshr_snpRespData_s3 | mshr_snpRespDataPtl_s3 | mshr_snpRespDataFwded_s3;")
    A("  wire mshr_dct_s3          = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h04;  // CompData")
    A("  wire mshr_writeCleanFull_s3 = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h17;")
    A("  wire mshr_writeBackFull_s3  = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h1B;")
    A("  wire mshr_writeEvictFull_s3 = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h15;")
    A("  wire mshr_writeEvictOrEvict_s3 = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h42;  // Issue>=Eb")
    A("  wire mshr_evict_s3          = mshr_req_s3 & toTXREQ_s3 & task_s3_bits_chiOpcode==7'h0D;")
    A("  wire mshr_cbWrData_s3       = mshr_req_s3 & toTXDAT_s3 & task_s3_bits_chiOpcode==7'h02;  // CopyBackWrData")
    A("")
    A("  // ===== Directory 结果 + nestable(snoop 嵌套 Release 时以 MSHR meta 替代目录) =====")
    A("  wire        dh = io_dirResp_s3_hit;")
    A("  wire [1:0]  meta_state = io_dirResp_s3_meta_state;")
    A("  wire        meta_has_clients_s3 = io_dirResp_s3_meta_clients;")
    A("  wire        req_needT_s3 = f_needT(task_s3_bits_opcode, task_s3_bits_param);")
    A("  wire        cache_alias = req_acquire_s3 & dh & io_dirResp_s3_meta_clients &")
    A("                            (io_dirResp_s3_meta_alias != task_s3_bits_alias);")
    A("  wire        snpHitRel = task_s3_bits_snpHitRelease;")
    A("  wire        nest_hit       = snpHitRel ? (task_s3_bits_snpHitReleaseMeta_state != INVALID) : dh;")
    A("  wire [1:0]  nest_state     = snpHitRel ? task_s3_bits_snpHitReleaseMeta_state    : meta_state;")
    A("  wire        nest_dirty     = snpHitRel ? task_s3_bits_snpHitReleaseMeta_dirty    : io_dirResp_s3_meta_dirty;")
    A("  wire        nest_clients   = snpHitRel ? task_s3_bits_snpHitReleaseMeta_clients  : io_dirResp_s3_meta_clients;")
    A("  wire        nest_tagErr    = snpHitRel ? task_s3_bits_snpHitReleaseMeta_tagErr   : io_dirResp_s3_meta_tagErr;")
    A("  wire        nest_error     = io_dirResp_s3_error;")
    A("  // 错误标志")
    A("  wire        tagError_s3  = io_dirResp_s3_error | io_dirResp_s3_meta_tagErr;")
    A("  wire        dataError_s3 = io_dirResp_s3_meta_dataErr;")
    A("  wire        l2TagError_s3 = io_dirResp_s3_error;")
    A("  wire        l2Error_s3   = io_dirResp_s3_error | (mshr_req_s3 & task_s3_bits_dataCheckErr);")
    A("")
    A("  // ===== replacer 响应(替换路是否需先回写) =====")
    A("  wire replResp_valid_s3   = io_replResp_valid;")
    A("  wire replResp_valid_hold = replResp_valid_s3 | replResp_valid_s4;")
    A("  wire retry     = replResp_valid_hold & io_replResp_bits_retry;")
    A("  wire need_repl = replResp_valid_hold & (io_replResp_bits_meta_state != INVALID) & task_s3_bits_replTask;")
    A("")
    A("  // ===== A 通道是否需 Acquire/Probe/Release(向下获权/探测/回写) =====")
    A("  wire acquire_on_miss_s3 = req_acquire_s3 | req_prefetch_s3 | req_get_s3;")
    A("  wire acquire_on_hit_s3  = (meta_state==BRANCH) & req_needT_s3 & ~req_prefetch_s3;")
    A("  wire need_acquire_s3_a  = fromA_s3 & ((dh ? acquire_on_hit_s3 : acquire_on_miss_s3) | cmo_cbo_s3);")
    A("  wire need_probe_s3_a    = dh & meta_has_clients_s3 & (")
    A("       (req_get_s3 & meta_state==TRUNK) | (req_cbo_clean_s3 & meta_state==TRUNK) |")
    A("       req_cbo_flush_s3 | req_cbo_inval_s3);")
    A("  wire need_release_s3_a  = dh & (")
    A("       (req_cbo_clean_s3 & ~need_probe_s3_a & io_dirResp_s3_meta_dirty) |")
    A("       (req_cbo_flush_s3 & (|meta_state)) | (req_cbo_inval_s3 & (|meta_state)));")
    A("  wire need_cmoresp_s3_a  = cmo_cbo_s3;")
    A("  wire need_compack_s3_a  = ~cmo_cbo_s3;")
    A("  wire need_mshr_s3_a     = need_acquire_s3_a | need_probe_s3_a | cache_alias;")
    A("")
    A("  // ===== B 通道(RXSNP snoop): 是否需 pProbe / DCT 前递 =====")
    A("  wire [6:0] chi = task_s3_bits_chiOpcode;")
    A("  wire expectFwd = f_isSnpXFwd(chi);")
    A("  wire canFwd    = nest_hit & ~(nest_tagErr | nest_error);")
    A("  wire doFwd     = expectFwd & canFwd;")
    A("  wire need_pprobe_s3_b_snpStable = fromB_s3 & (f_isSnpOnceX(chi) | f_isSnpQuery(chi) | f_isSnpStashX(chi))")
    A("                                    & dh & meta_state==TRUNK & meta_has_clients_s3;")
    A("  wire need_pprobe_s3_b_snpToB    = fromB_s3 & (f_isSnpToB(chi) | chi==7'h08)")
    A("                                    & dh & meta_state==TRUNK & meta_has_clients_s3;")
    A("  wire need_pprobe_s3_b_snpToN    = fromB_s3 & (f_isSnpUniqueX(chi) | chi==7'h09 | f_isSnpMakeInvalidX(chi))")
    A("                                    & dh & meta_has_clients_s3;")
    A("  wire need_pprobe_s3_b_snpNDERR  = fromB_s3 & tagError_s3 & dh;")
    A("  wire need_pprobe_s3_b = need_pprobe_s3_b_snpStable | need_pprobe_s3_b_snpToB |")
    A("                         need_pprobe_s3_b_snpToN | need_pprobe_s3_b_snpNDERR;")
    A("  wire need_dct_s3_b    = doFwd;")
    A("  wire need_mshr_s3_b   = need_pprobe_s3_b | need_dct_s3_b;")
    A("  wire need_mshr_s3     = need_mshr_s3_a | need_mshr_s3_b;")
    return L


def s3_snoop_resp():
    """s3: snoop 响应一致性态 (respCacheState/fwdState) + metaW_s3_b。"""
    L = []
    A = L.append
    A("  // ===== snoop 响应: 是否回数据 / PassDirty / 响应后一致性态 =====")
    A("  wire retToSrc = task_s3_bits_retToSrc;")
    A("  wire neverRespData = f_isSnpMakeInvalidX(chi) | f_isSnpStashX(chi) | f_isSnpQuery(chi) |")
    A("                       chi==7'h13 | chi==7'h17;  // SnpOnceFwd / SnpUniqueFwd")
    A("  wire shouldRespData_dirty = nest_hit & (nest_state==TIP | nest_state==TRUNK) & nest_dirty;")
    A("  wire shouldRespData_once  = nest_hit & nest_state==TIP & ~nest_dirty & chi==7'h03;  // SnpOnce")
    A("  wire shouldRespData_retToSrc_fwd    = nest_hit & retToSrc & f_isSnpXFwd(chi);")
    A("  wire shouldRespData_retToSrc_nonFwd = nest_hit & retToSrc & nest_state==BRANCH &")
    A("       (chi==7'h03 | chi==7'h07 | f_isSnpToBNonFwd(chi));  // SnpOnce / SnpUnique / SnpToB-nonFwd")
    A("  wire shouldRespData = shouldRespData_dirty | shouldRespData_once |")
    A("                        shouldRespData_retToSrc_fwd | shouldRespData_retToSrc_nonFwd;")
    A("  wire doRespData = shouldRespData & ~neverRespData;")
    A("  wire respPassDirty = doRespData & nest_hit & f_isT(nest_state) & nest_dirty &")
    A("       (chi != 7'h03 | snpHitRel) & ~(f_isSnpStashX(chi) | f_isSnpQuery(chi));")
    A("")
    A("  // respCacheState: snoop 命中且无 tagErr 时, 按 snoop 类型降级(顺序 when, 后者覆盖前者)")
    A("  logic [2:0] respCacheState;")
    A("  always_comb begin")
    A("    respCacheState = CHI_I;")
    A("    if (nest_hit & ~tagError_s3) begin")
    A("      if (f_isSnpToB(chi))")
    A("        respCacheState = task_s3_bits_snpHitReleaseToInval ? CHI_I : CHI_SC;")
    A("      if (f_isSnpOnceX(chi) | f_isSnpStashX(chi) | f_isSnpQuery(chi))")
    A("        respCacheState = (nest_state==BRANCH) ? CHI_SC : (nest_dirty ? CHI_UC : CHI_UC); // UD==UC==2")
    A("      if (f_isSnpOnceX(chi)) begin")
    A("        if (task_s3_bits_snpHitReleaseToClean & nest_dirty) respCacheState = CHI_SC;")
    A("        if (task_s3_bits_snpHitReleaseToInval)              respCacheState = CHI_I;")
    A("      end")
    A("      if (chi==7'h08)  // SnpCleanShared")
    A("        respCacheState = f_isT(nest_state) ? CHI_UC : CHI_SC;")
    A("    end")
    A("  end")
    A("  wire [2:0] snpResp_resp = respCacheState | ((respPassDirty & doRespData) ? CHI_PD : 3'h0);")
    A("")
    A("  // fwdState: DCT 前递时给请求方的一致性态")
    A("  logic [2:0] fwdCacheState; logic fwdPassDirty;")
    A("  always_comb begin")
    A("    fwdCacheState = CHI_I; fwdPassDirty = 1'b0;")
    A("    if (nest_hit) begin")
    A("      if (f_isSnpToBFwd(chi))")
    A("        fwdCacheState = task_s3_bits_snpHitReleaseToInval ? CHI_I : CHI_SC;")
    A("      if (chi==7'h17) begin  // SnpUniqueFwd")
    A("        if (nest_state==TIP & nest_dirty) begin fwdCacheState = CHI_UC; fwdPassDirty = 1'b1; end // UD==UC==2")
    A("        else                                    fwdCacheState = CHI_UC;")
    A("      end")
    A("    end")
    A("  end")
    A("  wire [2:0] snpResp_fwdState = fwdCacheState | (fwdPassDirty ? CHI_PD : 3'h0);")
    A("")
    A("  // snoop 响应 CHI opcode: {doFwd,doRespData} → SnpResp/SnpRespFwded/SnpRespData/SnpRespDataFwded")
    A("  logic [6:0] snpResp_chiOpcode;")
    A("  always_comb begin")
    A("    case ({doFwd, doRespData})")
    A("      2'b00: snpResp_chiOpcode = 7'h01;  // SnpResp")
    A("      2'b10: snpResp_chiOpcode = 7'h09;  // SnpRespFwded")
    A("      2'b01: snpResp_chiOpcode = 7'h01;  // SnpRespData (DAT 通道, 同值 1)")
    A("      2'b11: snpResp_chiOpcode = 7'h06;  // SnpRespDataFwded")
    A("    endcase")
    A("  end")
    A("")
    A("  // metaW_s3_b: B-snoop 命中写回的目录 meta(isSnpToN 全清, 否则降 BRANCH/保持)")
    A("  wire isSnpToN_b = f_isSnpToN(chi);")
    A("  wire [1:0] metaW_s3_b_state   = isSnpToN_b ? INVALID : (chi==7'h08 ? meta_state : BRANCH);")
    A("  wire       metaW_s3_b_clients = ~isSnpToN_b & io_dirResp_s3_meta_clients;")
    A("  wire [1:0] metaW_s3_b_alias   = isSnpToN_b ? 2'h0 : io_dirResp_s3_meta_alias;")
    A("  wire       metaW_s3_b_accessed= ~isSnpToN_b & io_dirResp_s3_meta_accessed;")
    A("  wire       metaW_s3_b_tagErr  = ~isSnpToN_b & io_dirResp_s3_meta_tagErr;")
    A("  wire       metaW_s3_b_dataErr = ~isSnpToN_b & io_dirResp_s3_meta_dataErr;")
    A("")
    A("  // ===== 写 Directory 的各路有效(a>b>c>mshr>cmo 优先, 提前定义供 source_req 使用) =====")
    A("  wire metaW_valid_s3_a = sinkA_req_s3 & ~need_mshr_s3_a & ~req_get_s3 & ~req_prefetch_s3 & ~cmo_cbo_s3;")
    A("  wire metaW_valid_s3_b = sinkB_req_s3 & ~need_mshr_s3_b & dh &")
    A("       (chi != 7'h03 | (task_s3_bits_snpHitReleaseToClean & task_s3_bits_snpHitReleaseMeta_dirty)) &")
    A("       ~f_isSnpStashX(chi) & ~f_isSnpQuery(chi) &")
    A("       (meta_state==TIP | (meta_state==BRANCH & f_isSnpToN(chi)));")
    A("  wire metaW_valid_s3_c    = sinkC_req_s3 & dh;")
    A("  wire metaW_valid_s3_mshr = mshr_req_s3 & task_s3_bits_metaWen & ~(mshr_refill_s3 & retry);")
    A("  wire metaW_valid_s3_cmo  = req_cbo_inval_s3 & dh;")
    A("  wire mw_ab  = metaW_valid_s3_a | metaW_valid_s3_b;")
    A("  wire mw_abc = mw_ab | metaW_valid_s3_c;")
    return L


def s3_sink_source():
    """s3: sink_resp(A/B/C 直接响应) + source_req_s3。"""
    L = []
    A = L.append
    A("  // ===== sink 直接响应(无需 MSHR 的 A/B/C 请求) =====")
    A("  wire sink_resp_s3_valid = task_s3_valid & ~mshr_req_s3 & ~need_mshr_s3;")
    A("  wire sink_resp_s3_a_promoteT = dh & f_isT(meta_state);")
    A("  // odOpGen: A 请求 → TL-D opcode 查表(Get→AccessAckData, AcqBlock→GrantData, AcqPerm→Grant, Hint→HintAck, CBO→CBOAck)")
    A("  wire [15:0][3:0] odOp_lut = '{4'h0,4'h8,4'h8,4'h8,4'h0,4'h0,4'h0,4'h0,")
    A("                                4'h4,4'h5,4'h2,4'h1,4'h1,4'h1,4'h0,4'h0};")
    A("  wire [3:0] sink_resp_s3_bits_opcode =")
    A("       fromA_s3 ? odOp_lut[task_s3_bits_opcode] : (fromB_s3 ? 4'h0 : 4'h6);  // C→ReleaseAck=6")
    A("  wire [2:0] sink_resp_s3_bits_param =")
    A("       fromA_s3 ? {2'h0, req_acquire_s3 & ~(|task_s3_bits_param) & ~sink_resp_s3_a_promoteT} : 3'h0;")
    A("")
    A("  // ===== source_req_s3 = req_s3 + (sink_resp 时覆盖 opcode/param/mshrId; B-snoop 时覆盖响应字段) =====")
    A("  wire b_resp_ovr = sink_resp_s3_valid & ~fromA_s3 & fromB_s3;  // golden _GEN_3 取反")
    A("  task_bundle_t source_req_s3;")
    A("  always_comb begin")
    A("    source_req_s3 = req_s3;")
    for n, _ in FIELDS:
        if n in SRC_OVR:
            A(f"    source_req_s3.{sv(n):<12} = {SRC_OVR[n]};")
    A("  end")
    return L


def s3_ds_dir_nested():
    """s3: DataStorage 读写 + Directory 写 + nestedwb。"""
    L = []
    A = L.append
    A("  // ===== DataStorage 读/写决策 =====")
    A("  wire [511:0] data_s3 = io_releaseBufResp_s3_valid ? io_releaseBufResp_s3_bits_data")
    A("                                                    : io_refillBufResp_s3_bits_data;")
    A("  wire [511:0] c_releaseData_s3 = {io_bufResp_data_1, io_bufResp_data_0};")
    A("  wire hasData_s3_tl  = source_req_s3.opcode[0];")
    A("  wire hasData_s3_chi = source_req_s3.txChannel[2];")
    A("  wire hasData_s3     = hasData_s3_tl | hasData_s3_chi;")
    A("  wire data_unready_s3    = hasData_s3   & ~mshr_req_s3;")
    A("  wire data_unready_s3_tl = hasData_s3_tl & ~mshr_req_s3;")
    A("  wire need_data_a = dh & (req_get_s3 | req_acquireBlock_s3);")
    A("  wire need_data_b = sinkB_req_s3 & (doRespData | doFwd | (nest_hit & nest_state==TRUNK));")
    A("  wire need_data_mshr_repl = mshr_refill_s3 & need_repl & ~retry;")
    A("  wire need_data_cmo = cmo_cbo_s3 & nest_hit & nest_dirty;")
    A("  wire ren = need_data_a | need_data_b | need_data_mshr_repl | need_data_cmo;")
    A("  // 写 DS: C 释放带数据 / mshr 各类回写填充")
    A("  wire wen_c = sinkC_req_s3 & f_isParamFromT(task_s3_bits_param) & task_s3_bits_opcode[0] & dh;")
    A("  wire wen_mshr = task_s3_bits_dsWen & (mshr_snpRespX_s3 | mshr_snpRespDataX_s3 |")
    A("       mshr_writeCleanFull_s3 | mshr_writeBackFull_s3 | mshr_writeEvictFull_s3 |")
    A("       mshr_writeEvictOrEvict_s3 | mshr_evict_s3 | (mshr_refill_s3 & ~need_repl & ~retry));")
    A("  wire wen = wen_c | wen_mshr;")
    A("  wire need_write_releaseBuf = need_probe_s3_a | cache_alias | (need_data_b & need_mshr_s3_b) |")
    A("                               need_data_mshr_repl | need_data_cmo;")
    A("")
    A("  wire [2:0] metaW_way = (mshr_refill_s3 & task_s3_bits_replTask) ? io_replResp_bits_way :")
    A("                         (mshr_req_s3 ? task_s3_bits_way : io_dirResp_s3_way);")
    A("  assign io_toDS_en_s3 = task_s3_valid & (ren | wen);")
    A("  assign io_toDS_req_s3_valid = task_s3_valid_hold2[0] & (ren | wen);")
    A("  assign io_toDS_req_s3_bits_way = metaW_way;")
    A("  assign io_toDS_req_s3_bits_set = mshr_req_s3 ? task_s3_bits_set : io_dirResp_s3_set;")
    A("  assign io_toDS_req_s3_bits_wen = wen;")
    A("  assign io_toDS_wdata_s3_data = ~mshr_req_s3 ? c_releaseData_s3 :")
    A("       (task_s3_bits_useProbeData ? io_releaseBufResp_s3_bits_data : io_refillBufResp_s3_bits_data);")
    A("")
    A("  // ===== 写 Directory: metaWReq(含复位逐 set 清零) + tagWReq =====")
    A("  // mshr 写 meta 取 mergeA 的 aMergeTask.meta 或 req.meta")
    A("  wire       mshrMeta_dirty   = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_dirty    : task_s3_bits_meta_dirty;")
    A("  wire [1:0] mshrMeta_state   = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_state    : task_s3_bits_meta_state;")
    A("  wire       mshrMeta_clients = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_clients  : task_s3_bits_meta_clients;")
    A("  wire [1:0] mshrMeta_alias   = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_alias    : task_s3_bits_meta_alias;")
    A("  wire       mshrMeta_prefetch= task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_prefetch : task_s3_bits_meta_prefetch;")
    A("  wire [2:0] mshrMeta_prefetchSrc = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_prefetchSrc : task_s3_bits_meta_prefetchSrc;")
    A("  wire       mshrMeta_accessed= task_s3_bits_mergeA ? task_s3_bits_aMergeTask_meta_accessed : task_s3_bits_meta_accessed;")
    A("  // wmeta 优先级 a>b>c>mshr>(cmo=全0)")
    A("  assign io_metaWReq_valid = ~resetFinish | (task_s3_valid &")
    A("       (metaW_valid_s3_a | metaW_valid_s3_b | metaW_valid_s3_c | metaW_valid_s3_mshr | metaW_valid_s3_cmo));")
    A("  assign io_metaWReq_bits_set   = resetFinish ? task_s3_bits_set : resetIdx;")
    A("  assign io_metaWReq_bits_wayOH = resetFinish ? (8'h1 << metaW_way) : 8'hFF;")
    A("  assign io_metaWReq_bits_wmeta_dirty = resetFinish & (")
    A("       metaW_valid_s3_a ? io_dirResp_s3_meta_dirty :")
    A("       metaW_valid_s3_b ? 1'b0 :")
    A("       metaW_valid_s3_c ? (io_dirResp_s3_meta_dirty | wen_c) :")
    A("       metaW_valid_s3_mshr ? mshrMeta_dirty : 1'b0);")
    A("  assign io_metaWReq_bits_wmeta_state = ~resetFinish ? 2'h0 : (")
    A("       metaW_valid_s3_a ? ((req_needT_s3 | sink_resp_s3_a_promoteT) ? TRUNK : meta_state) :")
    A("       metaW_valid_s3_b ? metaW_s3_b_state :")
    A("       metaW_valid_s3_c ? (f_isParamFromT(task_s3_bits_param) ? TIP : meta_state) :")
    A("       metaW_valid_s3_mshr ? mshrMeta_state : 2'h0);")
    A("  assign io_metaWReq_bits_wmeta_clients = resetFinish & (")
    A("       metaW_valid_s3_a ? ~io_dirResp_s3_error :")
    A("       metaW_valid_s3_b ? metaW_s3_b_clients :")
    A("       metaW_valid_s3_c ? ~f_isToN(task_s3_bits_param) :")
    A("       metaW_valid_s3_mshr ? mshrMeta_clients : 1'b0);")
    A("  assign io_metaWReq_bits_wmeta_alias = ~resetFinish ? 2'h0 : (")
    A("       metaW_valid_s3_a ? ((req_get_s3 | req_prefetch_s3) ? io_dirResp_s3_meta_alias : task_s3_bits_alias) :")
    A("       metaW_valid_s3_b ? metaW_s3_b_alias :")
    A("       metaW_valid_s3_c ? io_dirResp_s3_meta_alias :")
    A("       metaW_valid_s3_mshr ? mshrMeta_alias : 2'h0);")
    A("  assign io_metaWReq_bits_wmeta_prefetch    = resetFinish & ~mw_abc & metaW_valid_s3_mshr & mshrMeta_prefetch;")
    A("  assign io_metaWReq_bits_wmeta_prefetchSrc = (~resetFinish | mw_abc | ~metaW_valid_s3_mshr) ? 3'h0 : mshrMeta_prefetchSrc;")
    A("  assign io_metaWReq_bits_wmeta_accessed = resetFinish & (")
    A("       metaW_valid_s3_a ? 1'b1 :")
    A("       metaW_valid_s3_b ? metaW_s3_b_accessed :")
    A("       metaW_valid_s3_c ? io_dirResp_s3_meta_accessed :")
    A("       metaW_valid_s3_mshr ? mshrMeta_accessed : 1'b0);")
    A("  assign io_metaWReq_bits_wmeta_tagErr = resetFinish & (")
    A("       metaW_valid_s3_a ? io_dirResp_s3_meta_tagErr :")
    A("       metaW_valid_s3_b ? metaW_s3_b_tagErr :")
    A("       metaW_valid_s3_c ? (wen_c ? task_s3_bits_denied : io_dirResp_s3_meta_tagErr) :")
    A("       metaW_valid_s3_mshr ? task_s3_bits_denied : 1'b0);")
    A("  assign io_metaWReq_bits_wmeta_dataErr = resetFinish & (")
    A("       metaW_valid_s3_a ? io_dirResp_s3_meta_dataErr :")
    A("       metaW_valid_s3_b ? metaW_s3_b_dataErr :")
    A("       metaW_valid_s3_c ? (wen_c ? task_s3_bits_corrupt : io_dirResp_s3_meta_dataErr) :")
    A("       metaW_valid_s3_mshr ? task_s3_bits_corrupt : 1'b0);")
    A("  assign io_tagWReq_valid = task_s3_valid & task_s3_bits_tagWen & mshr_refill_s3 & ~retry;")
    A("  assign io_tagWReq_bits_set = task_s3_bits_set;")
    A("  assign io_tagWReq_bits_way = (mshr_refill_s3 & task_s3_bits_replTask) ? io_replResp_bits_way : task_s3_bits_way;")
    A("  assign io_tagWReq_bits_wtag = task_s3_bits_tag;")
    A("")
    A("  // ===== 嵌套写回 nestedwb(C 释放置脏/置 tip; B snoop 失效/降级) =====")
    A("  assign io_nestedwb_set = task_s3_bits_set;")
    A("  assign io_nestedwb_tag = task_s3_bits_tag;")
    A("  assign io_nestedwb_c_set_dirty = task_s3_valid & fromC_s3 & task_s3_bits_opcode==4'd7 & task_s3_bits_param==3'd1;  // ReleaseData & TtoN")
    A("  assign io_nestedwb_c_set_tip   = task_s3_valid & fromC_s3 & task_s3_bits_opcode==4'd6 & task_s3_bits_param==3'd1;  // Release & TtoN")
    A("  assign io_nestedwb_b_inv_dirty = task_s3_valid & fromB_s3 & task_s3_bits_snpHitReleaseToInval &")
    A("                                   ~(f_isSnpStashX(chi) | f_isSnpQuery(chi));")
    A("  assign io_nestedwb_b_toB     = task_s3_valid & fromB_s3 & source_req_s3.metaWen & source_req_s3.meta_state==BRANCH;")
    A("  assign io_nestedwb_b_toN     = task_s3_valid & fromB_s3 & source_req_s3.metaWen & source_req_s3.meta_state==INVALID;")
    A("  assign io_nestedwb_b_toClean = task_s3_valid & fromB_s3 & source_req_s3.metaWen & ~source_req_s3.meta_dirty;")
    A("  assign io_nestedwbData_data  = c_releaseData_s3;")
    return L


def s3_mshr_alloc():
    """s3: MSHR 分配请求(dirResult/FSMState/task)。"""
    L = []
    A = L.append
    A("  // ===== MSHR 分配(s3 判定需 MSHR 时, 把 dirResult/初态/任务 发往 MSHRCtl) =====")
    A("  assign io_toMSHRCtl_mshr_alloc_s3_valid = task_s3_valid & ~mshr_req_s3 & need_mshr_s3;")
    # dirResult = nestable
    nest = {"hit": "nest_hit", "tag": "(snpHitRel ? task_s3_bits_tag : io_dirResp_s3_tag)",
            "set": "(snpHitRel ? task_s3_bits_set : io_dirResp_s3_set)", "way": "io_dirResp_s3_way",
            "meta_dirty": "nest_dirty", "meta_state": "nest_state", "meta_clients": "nest_clients",
            "meta_alias": "(snpHitRel ? task_s3_bits_snpHitReleaseMeta_alias : io_dirResp_s3_meta_alias)",
            "meta_prefetch": "(snpHitRel ? task_s3_bits_snpHitReleaseMeta_prefetch : io_dirResp_s3_meta_prefetch)",
            "meta_prefetchSrc": "(snpHitRel ? task_s3_bits_snpHitReleaseMeta_prefetchSrc : io_dirResp_s3_meta_prefetchSrc)",
            "meta_accessed": "(snpHitRel ? task_s3_bits_snpHitReleaseMeta_accessed : io_dirResp_s3_meta_accessed)",
            "meta_tagErr": "nest_tagErr", "meta_dataErr": "(snpHitRel ? task_s3_bits_snpHitReleaseMeta_dataErr : io_dirResp_s3_meta_dataErr)",
            "error": "nest_error"}
    for f in DIR:
        A(f"  assign io_toMSHRCtl_mshr_alloc_s3_bits_dirResult_{f} = {nest[f]};")
    A("  // FSMState 初态: 全 1(s_/w_ 取假为有效), 按通道与需求清相应位")
    A("  logic [17:0] alloc_state;  // 顺序见 FSM 端口")
    # build always_comb for alloc_state
    A("  always_comb begin")
    A("    alloc_state = '1;")
    A("    if (fromA_s3) begin")
    A("      alloc_state[5]  = cmo_cbo_s3;            // s_refill")
    A("      alloc_state[15] = cmo_cbo_s3 | dh;       // w_replResp")
    A("      if (need_acquire_s3_a) begin")
    A("        alloc_state[0]  = 1'b0;                // s_acquire")
    A("        alloc_state[16] = ~need_compack_s3_a;  // s_rcompack")
    A("        alloc_state[11] = 1'b0;                // w_grantfirst")
    A("        alloc_state[12] = 1'b0;                // w_grantlast")
    A("        alloc_state[13] = 1'b0;                // w_grant")
    A("      end")
    A("      if (cache_alias | need_probe_s3_a) begin")
    A("        alloc_state[1] = 1'b0;                 // s_rprobe")
    A("        alloc_state[7] = 1'b0;                 // w_rprobeackfirst")
    A("        alloc_state[8] = 1'b0;                 // w_rprobeacklast")
    A("      end")
    A("      if (need_release_s3_a) begin")
    A("        alloc_state[3]  = 1'b0;                // s_release")
    A("        alloc_state[14] = 1'b0;                // w_releaseack")
    A("      end")
    A("      if (need_cmoresp_s3_a) alloc_state[6] = 1'b0;  // s_cmoresp")
    A("    end")
    A("    if (fromB_s3) begin")
    A("      alloc_state[4] = 1'b0;                   // s_probeack")
    A("      if (need_pprobe_s3_b) begin")
    A("        alloc_state[2] = 1'b0;                 // s_pprobe")
    A("        alloc_state[9]  = 1'b0;                // w_pprobeackfirst")
    A("        alloc_state[10] = 1'b0;                // w_pprobeacklast")
    A("      end")
    A("      if (need_dct_s3_b) alloc_state[17] = 1'b0;  // s_dct")
    A("    end")
    A("  end")
    for i, f in enumerate(FSM):
        A(f"  assign io_toMSHRCtl_mshr_alloc_s3_bits_state_{f} = alloc_state[{i}];")
    A("  // task = req_s3, 仅 aliasTask 取 cache_alias")
    for f in MSHR_TASK:
        rhs = "cache_alias" if f == "aliasTask" else f"task_s3_bits_{f}"
        A(f"  assign io_toMSHRCtl_mshr_alloc_s3_bits_task_{f} = {rhs};")
    return L


def s3_prefetch():
    L = []
    A = L.append
    A("  // ===== 预取训练(命中预取块/带 needHint 的缺失/aMerge 触发) =====")
    A("  assign io_prefetchTrain_valid = task_s3_valid & (")
    A("       ((req_acquire_s3 | req_get_s3) & task_s3_bits_needHint & (~dh | io_dirResp_s3_meta_prefetch)) |")
    A("       task_s3_bits_mergeA);")
    A("  assign io_prefetchTrain_bits_tag = {2'h0, task_s3_bits_tag};")
    A("  assign io_prefetchTrain_bits_set = task_s3_bits_set;")
    A("  assign io_prefetchTrain_bits_needT = task_s3_bits_mergeA ?")
    A("       f_needT({1'b0, task_s3_bits_aMergeTask_opcode}, task_s3_bits_aMergeTask_param) : req_needT_s3;")
    A("  assign io_prefetchTrain_bits_source = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_sourceId : task_s3_bits_sourceId;")
    A("  assign io_prefetchTrain_bits_vaddr  = task_s3_bits_mergeA ? task_s3_bits_aMergeTask_vaddr : task_s3_bits_vaddr;")
    A("  assign io_prefetchTrain_bits_hit        = task_s3_bits_mergeA ? 1'b1 : dh;")
    A("  assign io_prefetchTrain_bits_prefetched = task_s3_bits_mergeA ? 1'b1 : io_dirResp_s3_meta_prefetch;")
    A("  assign io_prefetchTrain_bits_pfsource   = io_dirResp_s3_meta_prefetchSrc;")
    A("  assign io_prefetchTrain_bits_reqsource  = task_s3_bits_reqSource;")
    A("")
    A("  // ===== 喂 CustomL1Hint 的 s3 信号 =====")
    A("  assign hint_s3_task_valid        = task_s3_valid;")
    A("  assign hint_s3_task_bits_channel = task_s3_bits_channel;")
    A("  assign hint_s3_task_bits_isKeyword = task_s3_bits_isKeyword;")
    A("  assign hint_s3_task_bits_opcode  = sink_resp_s3_valid ? sink_resp_s3_bits_opcode : task_s3_bits_opcode;")
    A("  assign hint_s3_task_bits_sourceId = task_s3_bits_sourceId;")
    A("  assign hint_s3_task_bits_mshrTask = task_s3_bits_mshrTask;")
    A("  assign hint_s3_need_mshr         = need_mshr_s3;")
    return L


def stage4():
    L = []
    A = L.append
    A("  // ===== Stage 4: 锁存 sinkB 响应/数据(时序), 处理 drop =====")
    A("  wire pendingTXDAT_s4 = task_s4_bits_channel[1] & ~task_s4_bits_mshrTask & task_s4_bits_txChannel[2];")
    A("  wire pendingD_s4 = task_s4_bits_channel[0] & ~task_s4_bits_mshrTask &")
    A("                     (task_s4_bits_opcode==4'd5 | task_s4_bits_opcode==4'd1);  // GrantData / AccessAckData")
    A("  wire req_drop_s3 = (~need_write_releaseBuf & ((~mshr_req_s3 & need_mshr_s3) | chnl_fire_s3)) |")
    A("                     (mshr_refill_s3 & retry);")
    A("  wire req_drop_s4 = ~need_write_releaseBuf_s4 & chnl_fire_s4;")
    return L


def stage5():
    L = []
    A = L.append
    A("  // ===== Stage 5: 收 DS 读数据, 发 releaseBufWrite, 出 error =====")
    A("  wire [511:0] rdata_s5 = io_toDS_rdata_s5_data;")
    A("  wire dataError_s5 = io_toDS_error_s5 | dataMetaError_s5;")
    A("  wire l2Error_s5   = l2TagError_s5 | io_toDS_error_s5;")
    A("  wire [511:0] out_data_s5 = (task_s5_bits_mshrTask | task_s5_bits_snpHitReleaseWithData) ? data_s5 : rdata_s5;")
    A("  wire chnl_valid_s5 = task_s5_valid & ~chnl_valid_s5_REG & ~chnl_fire_s3_d2;")
    A("  assign io_releaseBufWrite_valid = task_s5_valid & need_write_releaseBuf_s5;")
    A("  assign io_releaseBufWrite_bits_id = task_s5_bits_mshrId;")
    A("  assign io_releaseBufWrite_bits_data_data = rdata_s5;")
    return L


def channels():
    """各通道 s3/s4/s5 valid + 内联优先 Arbiter(in0=s5>s4>s3) + fire。"""
    L = []
    A = L.append
    A("  // s4/s5 通道有效门控(RegNext(chnl_fire) 防同任务多次发)")
    A("  wire chnl_valid_s4 = task_s4_valid & ~chnl_valid_s4_REG;")
    A("  // ===== 各通道 s3 派发判定(D=SourceD, TXREQ/RSP/DAT=CHI) =====")
    A("  // d_s3_latch/txdat_s3_latch=true: 非 mshr 的 A-D / B-DAT 响应推后一拍到 s4")
    A("  wire isD_s3 = mshr_req_s3 ? (mshr_cmoresp_s3 | (mshr_refill_s3 & ~retry)) :")
    A("       (fromC_s3 | (fromA_s3 & ~need_mshr_s3_a & ~data_unready_s3_tl & task_s3_bits_opcode!=4'd5));")
    A("  wire isD_s3_ready = mshr_req_s3 ? (mshr_cmoresp_s3 | (mshr_refill_s3 & ~retry)) : fromC_s3;")
    A("  wire isTXREQ_s3 = mshr_req_s3 & (mshr_writeBackFull_s3 | mshr_writeCleanFull_s3 |")
    A("                    mshr_writeEvictFull_s3 | mshr_writeEvictOrEvict_s3 | mshr_evict_s3);")
    A("  wire isTXRSP_s3 = mshr_req_s3 ? mshr_snpRespX_s3 : (fromB_s3 & ~need_mshr_s3 & ~hasData_s3);")
    A("  wire isTXDAT_s3 = mshr_req_s3 ? (mshr_snpRespDataX_s3 | mshr_cbWrData_s3 | mshr_dct_s3) :")
    A("       (fromB_s3 & ~need_mshr_s3 & doRespData &")
    A("        (~data_unready_s3 | (snpHitRel & task_s3_bits_snpHitReleaseWithData)));")
    A("  wire isTXDAT_s3_ready = mshr_req_s3 ? (mshr_snpRespDataX_s3 | mshr_cbWrData_s3 | mshr_dct_s3) : 1'b0;")
    A("")
    A("  // 各级各通道 valid")
    A("  wire d_s3_valid     = task_s3_valid & isD_s3_ready;")
    A("  wire txreq_s3_valid = task_s3_valid & isTXREQ_s3;")
    A("  wire txrsp_s3_valid = task_s3_valid & isTXRSP_s3;")
    A("  wire txdat_s3_valid = task_s3_valid & isTXDAT_s3_ready;")
    A("  wire d_s4_valid     = chnl_valid_s4 & isD_s4;")
    A("  wire txreq_s4_valid = chnl_valid_s4 & isTXREQ_s4;")
    A("  wire txrsp_s4_valid = chnl_valid_s4 & isTXRSP_s4;")
    A("  wire txdat_s4_valid = chnl_valid_s4 & isTXDAT_s4;")
    A("  wire d_s5_valid     = chnl_valid_s5 & isD_s5;")
    A("  wire txreq_s5_valid = chnl_valid_s5 & isTXREQ_s5;")
    A("  wire txrsp_s5_valid = chnl_valid_s5 & isTXRSP_s5;")
    A("  wire txdat_s5_valid = chnl_valid_s5 & isTXDAT_s5;")
    A("")
    A("  // 优先 Arbiter: in0=s5 最高 > s4 > s3。D/REQ/RSP 下游恒 ready=1; DAT=io_toTXDAT_ready")
    A("  wire d_s5_fire = d_s5_valid;")
    A("  wire d_s4_fire = d_s4_valid & ~d_s5_valid;")
    A("  wire d_s3_fire = d_s3_valid & ~d_s5_valid & ~d_s4_valid;")
    A("  wire txreq_s5_fire = txreq_s5_valid;")
    A("  wire txreq_s4_fire = txreq_s4_valid & ~txreq_s5_valid;")
    A("  wire txreq_s3_fire = txreq_s3_valid & ~txreq_s5_valid & ~txreq_s4_valid;")
    A("  wire txrsp_s5_fire = txrsp_s5_valid;")
    A("  wire txrsp_s4_fire = txrsp_s4_valid & ~txrsp_s5_valid;")
    A("  wire txrsp_s3_fire = txrsp_s3_valid & ~txrsp_s5_valid & ~txrsp_s4_valid;")
    A("  wire txdat_s5_fire = txdat_s5_valid & io_toTXDAT_ready;")
    A("  wire txdat_s4_fire = txdat_s4_valid & io_toTXDAT_ready & ~txdat_s5_valid;")
    A("  wire txdat_s3_fire = txdat_s3_valid & io_toTXDAT_ready & ~txdat_s5_valid & ~txdat_s4_valid;")
    A("  wire chnl_fire_s3 = d_s3_fire | txreq_s3_fire | txrsp_s3_fire | txdat_s3_fire;")
    A("  wire chnl_fire_s4 = d_s4_fire | txreq_s4_fire | txrsp_s4_fire | txdat_s4_fire;")
    A("")
    A("  // Arbiter 输出 valid")
    A("  assign io_toSourceD_valid = d_s5_valid | d_s4_valid | d_s3_valid;")
    A("  assign io_toTXREQ_valid   = txreq_s5_valid | txreq_s4_valid | txreq_s3_valid;")
    A("  assign io_toTXRSP_valid   = txrsp_s5_valid | txrsp_s4_valid | txrsp_s3_valid;")
    A("  assign io_toTXDAT_valid   = txdat_s5_valid | txdat_s4_valid | txdat_s3_valid;")
    A("")
    A("  // s5 task 视图的 denied/corrupt 覆盖(SourceD 与 TXDAT 略不同)")
    A("  task_bundle_t s5_sd, s5_txdat;")
    A("  always_comb begin")
    A("    s5_sd = task_s5_v;")
    A("    s5_sd.denied  = (task_s5_bits_mshrTask | task_s5_bits_snpHitReleaseWithData) ? task_s5_bits_denied  : tagError_s5;")
    A("    s5_sd.corrupt = (task_s5_bits_mshrTask | task_s5_bits_snpHitReleaseWithData) ? task_s5_bits_corrupt : dataError_s5;")
    A("    s5_txdat = task_s5_v;")
    A("    s5_txdat.denied  = tagError_s5;")
    A("    s5_txdat.corrupt = task_s5_bits_corrupt | dataError_s5;")
    A("  end")
    A("")
    A("  // ----- SourceD (TaskWithData): 优先选 s5>s4>s3, 全字段 -----")
    for n, _ in FIELDS:
        s = sv(n)
        A(f"  assign io_toSourceD_bits_task_{n} = d_s5_valid ? s5_sd.{s} : d_s4_valid ? task_s4_v.{s} : source_req_s3.{s};")
    A("  assign io_toSourceD_bits_data_data = d_s5_valid ? out_data_s5 : d_s4_valid ? data_s4 : data_s3;")
    A("")
    A("  // ----- TXDAT (TaskWithData) -----")
    for n, _ in FIELDS:
        s = sv(n)
        A(f"  assign io_toTXDAT_bits_task_{n} = txdat_s5_valid ? s5_txdat.{s} : txdat_s4_valid ? task_s4_v.{s} : source_req_s3.{s};")
    A("  assign io_toTXDAT_bits_data_data = txdat_s5_valid ? out_data_s5 : txdat_s4_valid ? data_s4 : data_s3;")
    A("")
    A("  // ----- TXREQ (CHIREQ via toCHIREQBundle): addr={2'h0,tag,set,6'h0} -----")
    def chireq(stage, src):  # src.<field>
        return src
    for f, w in TXREQ_F:
        if f == "opcode":
            s5, s4, s3 = "task_s5_bits_chiOpcode", "task_s4_bits_chiOpcode", "source_req_s3.chiOpcode"
        elif f == "addr":
            s5 = "{2'h0, task_s5_bits_tag, task_s5_bits_set, 6'h0}"
            s4 = "{2'h0, task_s4_bits_tag, task_s4_bits_set, 6'h0}"
            s3 = "{2'h0, source_req_s3.tag, source_req_s3.set, 6'h0}"
        else:
            s5, s4, s3 = f"task_s5_bits_{f}", f"task_s4_bits_{f}", f"source_req_s3.{f}"
        A(f"  assign io_toTXREQ_bits_{f} = txreq_s5_valid ? {s5} : txreq_s4_valid ? {s4} : {s3};")
    A("")
    A("  // ----- TXRSP (TaskBundle subset): s5 denied=tagError_s5 -----")
    for f, w in TXRSP_F:
        if f == "denied":
            s5 = "tagError_s5"
            s4 = "task_s4_bits_denied"
            s3 = "source_req_s3.denied"
        else:
            s5, s4, s3 = f"task_s5_bits_{f}", f"task_s4_bits_{f}", f"source_req_s3.{f}"
        A(f"  assign io_toTXRSP_bits_{f} = txrsp_s5_valid ? {s5} : txrsp_s4_valid ? {s4} : {s3};")
    return L


def block_status_err_perf():
    L = []
    A = L.append
    A("  // ===== BlockInfo: 若 s2/s3 可能写 Dir 则反压 s1 同 set 入口 =====")
    A("  wire [8:0] s1_c_set = io_fromReqArb_status_s1_sets_0;")
    A("  wire [8:0] s1_b_set = io_fromReqArb_status_s1_sets_1;")
    A("  wire [8:0] s1_a_set = io_fromReqArb_status_s1_sets_2;")
    A("  wire [8:0] s1_g_set = io_fromReqArb_status_s1_sets_3;")
    A("  wire [30:0] s1_b_tag = io_fromReqArb_status_s1_tags_1;")
    A("  wire s2_valid = io_taskFromArb_s2_valid;")
    A("  // s23Block: set 相等 且 非(保证不写 meta 的 mshrTask)")
    A("  wire s2_writesMeta = ~(io_taskFromArb_s2_bits_mshrTask & ~io_taskFromArb_s2_bits_metaWen);")
    A("  wire s3_writesMeta = ~(task_s3_bits_mshrTask & ~task_s3_bits_metaWen);")
    A("  assign io_toReqBuf_0 = s2_valid & (io_taskFromArb_s2_bits_set==s1_a_set) & s2_writesMeta;")
    A("  assign io_toReqBuf_1 = task_s3_valid & (task_s3_bits_set==s1_a_set) & s3_writesMeta;")
    A("  assign io_toReqArb_blockC_s1 = s2_valid & (io_taskFromArb_s2_bits_set==s1_c_set) & s2_writesMeta;")
    A("  assign io_toReqArb_blockG_s1 = s2_valid & (io_taskFromArb_s2_bits_set==s1_g_set) & s2_writesMeta;")
    A("  assign io_toReqArb_blockB_s1 =")
    A("       (s2_valid & (io_taskFromArb_s2_bits_set==s1_b_set)) |")
    A("       (task_s3_valid & (task_s3_bits_set==s1_b_set)) |")
    A("       (task_s4_valid & (task_s4_bits_set==s1_b_set) & (task_s4_bits_tag==s1_b_tag)) |")
    A("       (task_s5_valid & (task_s5_bits_set==s1_b_set) & (task_s5_bits_tag==s1_b_tag));")
    A("")
    A("  // ===== Pipeline Status(给 GrantBuffer/TX 容量冲突判定) =====")
    A("  assign io_status_vec_toD_0_valid = task_s3_valid & (mshr_req_s3 ? (mshr_refill_s3 & ~retry) : 1'b1);")
    A("  assign io_status_vec_toD_0_bits_channel = task_s3_bits_channel;")
    A("  assign io_status_vec_toD_1_valid = task_s4_valid & (isD_s4 | pendingD_s4);")
    A("  assign io_status_vec_toD_1_bits_channel = task_s4_bits_channel;")
    A("  assign io_status_vec_toD_2_valid = d_s5_valid;")
    A("  assign io_status_vec_toD_2_bits_channel = task_s5_bits_channel;")
    A("  assign io_status_vec_toTX_0_valid = task_s3_valid;")
    A("  assign io_status_vec_toTX_0_bits_channel   = task_s3_bits_channel;")
    A("  assign io_status_vec_toTX_0_bits_txChannel = source_req_s3.txChannel;")
    A("  assign io_status_vec_toTX_0_bits_mshrTask  = task_s3_bits_mshrTask;")
    A("  assign io_status_vec_toTX_1_valid = task_s4_valid;")
    A("  assign io_status_vec_toTX_1_bits_channel   = task_s4_bits_channel;")
    A("  assign io_status_vec_toTX_1_bits_txChannel = task_s4_bits_txChannel;")
    A("  assign io_status_vec_toTX_1_bits_mshrTask  = task_s4_bits_mshrTask;")
    A("  assign io_status_vec_toTX_2_valid = task_s5_valid;")
    A("  assign io_status_vec_toTX_2_bits_channel   = task_s5_bits_channel;")
    A("  assign io_status_vec_toTX_2_bits_txChannel = task_s5_bits_txChannel;")
    A("  assign io_status_vec_toTX_2_bits_mshrTask  = task_s5_bits_mshrTask;")
    A("")
    A("  // ===== ECC error =====")
    A("  assign io_error_valid = task_s5_valid;")
    A("  assign io_error_bits_valid = l2Error_s5;")
    A("  assign io_error_bits_address = {task_s5_bits_tag, task_s5_bits_set, task_s5_bits_off};")
    A("")
    A("  // ===== 性能事件(8 个, 2 级 RegNext 延迟后零扩展成 6-bit) =====")
    A("  wire perf0 = task_s3_valid & ((sinkA_req_s3 & ~req_prefetch_s3) | sinkC_req_s3);")
    A("  wire perf1 = task_s3_valid & (mshr_cbWrData_s3 | mshr_snpRespDataX_s3);")
    A("  wire perf2 = task_s3_valid & sinkC_req_s3 & task_s3_bits_opcode==4'd7;  // ReleaseData")
    A("  wire perf3 = task_s3_valid & mshr_cbWrData_s3;")
    A("  wire perf4 = task_s3_valid & mshr_snpRespDataX_s3;")
    A("  wire perf5 = task_s3_valid & sinkA_req_s3 & ~req_prefetch_s3;")
    A("  wire perf6 = task_s3_valid & sinkC_req_s3;")
    A("  wire perf7 = task_s3_valid & sinkB_req_s3 & task_s3_bits_param==3'd2;  // toN")
    for i in range(8):
        A(f"  assign io_perf_{i}_value = {{5'h0, io_perf_{i}_value_dly2}};")
    return L


def seq_blocks():
    """时序: 异步复位主流水寄存器 + 无复位 data_s4/s5/perf RegNext。"""
    L = []
    A = L.append
    A("  // ===== 时序 1: 异步复位主流水寄存器 =====")
    A("  always_ff @(posedge clock or posedge reset) begin")
    A("    if (reset) begin")
    A("      resetFinish <= 1'b0;")
    A("      resetIdx    <= 9'd511;")
    A("      task_s3_valid <= 1'b0; task_s4_valid <= 1'b0; task_s5_valid <= 1'b0;")
    A("      replResp_valid_s4 <= 1'b0; task_s3_valid_hold2 <= 2'b0;")
    A("      need_write_releaseBuf_s4 <= 1'b0; isD_s4 <= 1'b0; isTXREQ_s4 <= 1'b0;")
    A("      isTXRSP_s4 <= 1'b0; isTXDAT_s4 <= 1'b0; tagError_s4 <= 1'b0;")
    A("      dataError_s4 <= 1'b0; l2Error_s4 <= 1'b0; chnl_valid_s4_REG <= 1'b0;")
    A("      need_write_releaseBuf_s5 <= 1'b0; isD_s5 <= 1'b0; isTXREQ_s5 <= 1'b0;")
    A("      isTXRSP_s5 <= 1'b0; isTXDAT_s5 <= 1'b0; tagError_s5 <= 1'b0;")
    A("      dataMetaError_s5 <= 1'b0; l2TagError_s5 <= 1'b0;")
    A("      chnl_valid_s5_REG <= 1'b0; chnl_fire_s3_d1 <= 1'b0; chnl_fire_s3_d2 <= 1'b0;")
    for n, _ in FIELDS:
        A(f"      task_s3_bits_{n} <= '0; task_s4_bits_{n} <= '0; task_s5_bits_{n} <= '0;")
    A("    end else begin")
    A("      resetFinish <= (resetIdx == 9'd0) | resetFinish;")
    A("      if (~resetFinish) resetIdx <= resetIdx - 9'd1;")
    A("      replResp_valid_s4 <= io_replResp_valid;")
    A("      // task_s3_valid_hold2: s2 有效起 2 拍 (给 DS req valid 拉宽)")
    A("      task_s3_valid_hold2 <= io_taskFromArb_s2_valid ? 2'b11 : (task_s3_valid_hold2 >> 1);")
    A("      // s2 → s3")
    A("      task_s3_valid <= io_taskFromArb_s2_valid;")
    A("      if (io_taskFromArb_s2_valid) begin")
    for n, _ in FIELDS:
        A(f"        task_s3_bits_{n} <= io_taskFromArb_s2_bits_{n};")
    A("      end")
    A("      // s3 → s4 (锁存 source_req_s3; need_mshr 时 mshrId 取 alloc_ptr)")
    A("      task_s4_valid <= task_s3_valid & ~req_drop_s3;")
    A("      if (task_s3_valid & ~req_drop_s3) begin")
    for n, _ in FIELDS:
        if n == "mshrId":
            A("        task_s4_bits_mshrId <= (~mshr_req_s3 & need_mshr_s3) ? io_fromMSHRCtl_mshr_alloc_ptr : source_req_s3.mshrId;")
        else:
            A(f"        task_s4_bits_{n} <= source_req_s3.{sv(n)};")
    A("        need_write_releaseBuf_s4 <= need_write_releaseBuf;")
    A("        isD_s4 <= isD_s3; isTXREQ_s4 <= isTXREQ_s3; isTXRSP_s4 <= isTXRSP_s3; isTXDAT_s4 <= isTXDAT_s3;")
    A("        tagError_s4 <= tagError_s3; dataError_s4 <= dataError_s3; l2Error_s4 <= l2Error_s3;")
    A("      end")
    A("      chnl_valid_s4_REG <= chnl_fire_s3;")
    A("      // s4 → s5")
    A("      task_s5_valid <= task_s4_valid & ~req_drop_s4;")
    A("      if (task_s4_valid & ~req_drop_s4) begin")
    for n, _ in FIELDS:
        A(f"        task_s5_bits_{n} <= task_s4_bits_{n};")
    A("        need_write_releaseBuf_s5 <= need_write_releaseBuf_s4;")
    A("        isD_s5 <= isD_s4 | pendingD_s4; isTXREQ_s5 <= isTXREQ_s4; isTXRSP_s5 <= isTXRSP_s4;")
    A("        isTXDAT_s5 <= isTXDAT_s4 | pendingTXDAT_s4;")
    A("        tagError_s5 <= tagError_s4; dataMetaError_s5 <= dataError_s4; l2TagError_s5 <= l2Error_s4;")
    A("      end")
    A("      chnl_valid_s5_REG   <= chnl_fire_s4;")
    A("      chnl_fire_s3_d1 <= chnl_fire_s3;")
    A("      chnl_fire_s3_d2 <= chnl_fire_s3_d1;")
    A("    end")
    A("  end")
    A("")
    A("  // ===== 时序 2: 无复位 RegNext (data_s4/s5 数据通路 + perf 计数, initreg+0 起 0) =====")
    A("  always_ff @(posedge clock) begin")
    A("    if (task_s3_valid & ~req_drop_s3) data_s4 <= data_s3;")
    A("    if (task_s4_valid & ~req_drop_s4) data_s5 <= data_s4;")
    for i in range(8):
        A(f"    io_perf_{i}_value_REG <= perf{i};")
        A(f"    io_perf_{i}_value_dly2 <= io_perf_{i}_value_REG;")
    A("  end")
    return L
