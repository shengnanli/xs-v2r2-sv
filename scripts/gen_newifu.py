#!/usr/bin/env python3
"""
为 NewIFU 生成：
  · rtl/frontend/NewIFU_subs.sv —— 5 个子模块黑盒适配器(把 golden 扁平端口包装成
    可读核 xs_NewIFU_core 用的 array/struct 干净接口)：
      xs_newifu_rvcexpander / xs_newifu_predecode / xs_newifu_f3predecoder /
      xs_newifu_predchecker / xs_newifu_frontendtrigger
  · rtl/frontend/NewIFU_wrapper.sv —— golden 同名 NewIFU(扁平端口 ↔ 可读核 struct/数组)
  · verif/ut/NewIFU/variants_xs.sv —— 与 wrapper 同，模块名 NewIFU_xs
  · verif/ut/NewIFU/tb.sv —— golden NewIFU vs NewIFU_xs 双例化随机比对

设计：可读核 xs_NewIFU_core 内部已例化上述 5 个适配器(golden 同名子模块当黑盒)。
wrapper 只做 NewIFU 顶层扁平端口 ↔ 核 struct/数组端口的机械映射。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
PW = 16


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def haswidth(w):
    return f"[{w-1}:0] " if w > 1 else ""


# ---------------------------------------------------------------------------
# 子模块适配器
# ---------------------------------------------------------------------------
def adapter_rvcexpander():
    # golden RVCExpander 端口已是干净接口，直接同名直通
    return """// ---- xs_newifu_rvcexpander：golden RVCExpander 直通适配 ----
module xs_newifu_rvcexpander(
  input  wire [31:0] io_in,
  input  wire        io_fsIsOff,
  output wire [31:0] io_out_bits,
  output wire        io_ill
);
  RVCExpander u(.io_in(io_in), .io_fsIsOff(io_fsIsOff),
                .io_out_bits(io_out_bits), .io_ill(io_ill));
endmodule
"""


def adapter_predecode():
    ps = ports("PreDecode")
    conns = []
    conns.append(".clock(clock)")
    conns.append(".reset(reset)")
    conns.append(".io_in_valid(in_valid)")
    for d, w, n in ps:
        m = re.match(r"io_in_bits_data_(\d+)$", n)
        if m:
            conns.append(f".io_in_bits_data_{m.group(1)}(in_data[{m.group(1)}])")
    pat = [
        (r"io_out_pd_(\d+)_valid$",  "out_pd[{i}].valid"),
        (r"io_out_pd_(\d+)_isRVC$",  "out_pd[{i}].isRVC"),
        (r"io_out_pd_(\d+)_brType$", "out_pd[{i}].brType"),
        (r"io_out_pd_(\d+)_isCall$", "out_pd[{i}].isCall"),
        (r"io_out_pd_(\d+)_isRet$",  "out_pd[{i}].isRet"),
        (r"io_out_hasHalfValid_(\d+)$", "out_hasHalfValid[{i}]"),
        (r"io_out_instr_(\d+)$",     "out_instr[{i}]"),
        (r"io_out_jumpOffset_(\d+)$","out_jumpOffset[{i}]"),
    ]
    for d, w, n in ps:
        if d != "output":
            continue
        for rgx, tmpl in pat:
            mm = re.match(rgx, n)
            if mm:
                conns.append(f".{n}({tmpl.format(i=mm.group(1))})")
                break
    body = ",\n    ".join(conns)
    return f"""// ---- xs_newifu_predecode：golden PreDecode 黑盒适配(扁平→数组/struct) ----
module xs_newifu_predecode
  import xs_newifu_pkg::*;
(
  input  wire        clock,
  input  wire        reset,
  input  wire        in_valid,
  input  wire [PredictWidth:0][15:0] in_data,
  input  wire [PredictWidth-1:0][VAddrBits-1:0] pc, // golden 已裁剪，仅占位
  output pd_info_t [PredictWidth-1:0]    out_pd,
  output wire [PredictWidth-1:0][31:0]   out_instr,
  output wire [PredictWidth-1:0][63:0]   out_jumpOffset,
  output wire [PredictWidth-1:0]         out_hasHalfValid
);
  // golden 裁掉了 pd_0_valid(恒1)、hasHalfValid_0/1(恒0)：在此补默认值
  assign out_pd[0].valid = 1'b1;
  assign out_hasHalfValid[0] = 1'b0;
  assign out_hasHalfValid[1] = 1'b0;
  PreDecode u (
    {body}
  );
endmodule
"""


def adapter_f3predecoder():
    ps = ports("F3Predecoder")
    conns = []
    for d, w, n in ps:
        m = re.match(r"io_in_instr_(\d+)$", n)
        if m:
            conns.append(f".io_in_instr_{m.group(1)}(instr[{m.group(1)}])")
    pat = [
        (r"io_out_pd_(\d+)_brType$", "brType[{i}]"),
        (r"io_out_pd_(\d+)_isCall$", "isCall[{i}]"),
        (r"io_out_pd_(\d+)_isRet$",  "isRet[{i}]"),
    ]
    for d, w, n in ps:
        if d != "output":
            continue
        for rgx, tmpl in pat:
            mm = re.match(rgx, n)
            if mm:
                conns.append(f".{n}({tmpl.format(i=mm.group(1))})")
                break
    body = ",\n    ".join(conns)
    return f"""// ---- xs_newifu_f3predecoder：golden F3Predecoder 黑盒适配 ----
module xs_newifu_f3predecoder
  import xs_newifu_pkg::*;
(
  input  wire [PredictWidth-1:0][31:0] instr,
  output wire [PredictWidth-1:0][1:0]  brType,
  output wire [PredictWidth-1:0]       isCall,
  output wire [PredictWidth-1:0]       isRet
);
  F3Predecoder u (
    {body}
  );
endmodule
"""


def adapter_predchecker():
    ps = ports("PredChecker")
    conns = ['.clock(clock)']
    smap = [
        (r"io_in_ftqOffset_valid$", "ftqOffset_valid"),
        (r"io_in_ftqOffset_bits$",  "ftqOffset_bits"),
        (r"io_in_target$",          "target"),
        (r"io_in_fire_in$",         "fire_in"),
    ]
    arrmap = [
        (r"io_in_jumpOffset_(\d+)$",  "jumpOffset[{i}]"),
        (r"io_in_instrRange_(\d+)$",  "instrRange[{i}]"),
        (r"io_in_instrValid_(\d+)$",  "instrValid[{i}]"),
        (r"io_in_pc_(\d+)$",          "pc[{i}]"),
        (r"io_in_pds_(\d+)_isRVC$",   "pds[{i}].isRVC"),
        (r"io_in_pds_(\d+)_brType$",  "pds[{i}].brType"),
        (r"io_in_pds_(\d+)_isRet$",   "pds[{i}].isRet"),
        (r"io_out_stage1Out_fixedRange_(\d+)$",     "fixedRange[{i}]"),
        (r"io_out_stage1Out_fixedTaken_(\d+)$",     "fixedTaken[{i}]"),
        (r"io_out_stage2Out_fixedTarget_(\d+)$",    "fixedTarget[{i}]"),
        (r"io_out_stage2Out_jalTarget_(\d+)$",      "jalTarget[{i}]"),
        (r"io_out_stage2Out_fixedMissPred_(\d+)$",  "fixedMissPred[{i}]"),
        (r"io_out_stage2Out_faultType_(\d+)_value$","faultType[{i}]"),
    ]
    for d, w, n in ps:
        if n in ("clock", "reset"):
            continue
        done = False
        for rgx, tmpl in smap:
            if re.match(rgx, n):
                conns.append(f".{n}({tmpl})")
                done = True
                break
        if done:
            continue
        for rgx, tmpl in arrmap:
            mm = re.match(rgx, n)
            if mm:
                conns.append(f".{n}({tmpl.format(i=mm.group(1))})")
                done = True
                break
        assert done, f"unmapped PredChecker port {n}"
    body = ",\n    ".join(conns)
    return f"""// ---- xs_newifu_predchecker：golden PredChecker 黑盒适配 ----
module xs_newifu_predchecker
  import xs_newifu_pkg::*;
(
  input  wire        clock,
  input  wire        ftqOffset_valid,
  input  wire [3:0]  ftqOffset_bits,
  input  wire [PredictWidth-1:0][63:0] jumpOffset,
  input  wire [VAddrBits-1:0]          target,
  input  wire [PredictWidth-1:0]       instrRange,
  input  wire [PredictWidth-1:0]       instrValid,
  input  pd_info_t [PredictWidth-1:0]  pds,
  input  wire [PredictWidth-1:0][VAddrBits-1:0] pc,
  input  wire        fire_in,
  output wire [PredictWidth-1:0]       fixedRange,
  output wire [PredictWidth-1:0]       fixedTaken,
  output wire [PredictWidth-1:0][VAddrBits-1:0] fixedTarget,
  output wire [PredictWidth-1:0][VAddrBits-1:0] jalTarget,
  output wire [PredictWidth-1:0]       fixedMissPred,
  output wire [PredictWidth-1:0][2:0]  faultType
);
  PredChecker u (
    {body}
  );
endmodule
"""


def adapter_frontendtrigger():
    ps = ports("FrontendTrigger")
    conns = ['.clock(clock)', '.reset(reset)']
    smap = {
        "io_frontendTrigger_tUpdate_valid": "tUpdate_valid",
        "io_frontendTrigger_tUpdate_bits_addr": "tUpdate_addr",
        "io_frontendTrigger_tUpdate_bits_tdata_matchType": "tUpdate_matchType",
        "io_frontendTrigger_tUpdate_bits_tdata_select": "tUpdate_select",
        "io_frontendTrigger_tUpdate_bits_tdata_action": "tUpdate_action",
        "io_frontendTrigger_tUpdate_bits_tdata_chain": "tUpdate_chain",
        "io_frontendTrigger_tUpdate_bits_tdata_tdata2": "tUpdate_tdata2",
        "io_frontendTrigger_debugMode": "debugMode",
        "io_frontendTrigger_triggerCanRaiseBpExp": "triggerCanRaiseBpExp",
    }
    for d, w, n in ps:
        if n in ("clock", "reset"):
            continue
        if n in smap:
            conns.append(f".{n}({smap[n]})")
            continue
        m = re.match(r"io_frontendTrigger_tEnableVec_(\d+)$", n)
        if m:
            conns.append(f".{n}(tEnableVec[{m.group(1)}])")
            continue
        m = re.match(r"io_pc_(\d+)$", n)
        if m:
            conns.append(f".{n}(pc[{m.group(1)}])")
            continue
        m = re.match(r"io_triggered_(\d+)$", n)
        if m:
            conns.append(f".{n}(triggered[{m.group(1)}])")
            continue
        assert False, f"unmapped FrontendTrigger port {n}"
    body = ",\n    ".join(conns)
    return f"""// ---- xs_newifu_frontendtrigger：golden FrontendTrigger 黑盒适配 ----
module xs_newifu_frontendtrigger
  import xs_newifu_pkg::*;
(
  input  wire        clock,
  input  wire        reset,
  input  wire        tUpdate_valid,
  input  wire [1:0]  tUpdate_addr,
  input  wire [1:0]  tUpdate_matchType,
  input  wire        tUpdate_select,
  input  wire [3:0]  tUpdate_action,
  input  wire        tUpdate_chain,
  input  wire [63:0] tUpdate_tdata2,
  input  wire [3:0]  tEnableVec,
  input  wire        debugMode,
  input  wire        triggerCanRaiseBpExp,
  input  wire [PredictWidth-1:0][VAddrBits-1:0] pc,
  output wire [PredictWidth-1:0][3:0] triggered
);
  FrontendTrigger u (
    {body}
  );
endmodule
"""


def emit_subs():
    return ("// 自动生成：scripts/gen_newifu.py —— 勿手改\n"
            "// NewIFU 可读核所用的 5 个子模块黑盒适配器。\n"
            + adapter_rvcexpander() + "\n"
            + adapter_predecode() + "\n"
            + adapter_f3predecoder() + "\n"
            + adapter_predchecker() + "\n"
            + adapter_frontendtrigger())


# ---------------------------------------------------------------------------
# 顶层 wrapper（NewIFU 扁平端口 ↔ xs_NewIFU_core struct/数组）
# ---------------------------------------------------------------------------
def emit_wrapper(modname):
    ps = ports("NewIFU")
    # 端口声明（与 golden 完全一致）
    decls = []
    for d, w, n in ps:
        decls.append(f"  {d:6s} {haswidth(w)}{n}")
    L = []
    L.append(f"module {modname}(")
    L.append(",\n".join(decls))
    L.append(");")
    L.append("  import xs_newifu_pkg::*;")

    # ---- 打包输入数组/struct ----
    pk = []
    # ftq_req struct
    pk.append("  ftq_req_t ftq_req;")
    pk.append("  assign ftq_req.startAddr     = io_ftqInter_fromFtq_req_bits_startAddr;")
    pk.append("  assign ftq_req.nextlineStart = io_ftqInter_fromFtq_req_bits_nextlineStart;")
    pk.append("  assign ftq_req.nextStartAddr = io_ftqInter_fromFtq_req_bits_nextStartAddr;")
    pk.append("  assign ftq_req.ftqIdx_flag   = io_ftqInter_fromFtq_req_bits_ftqIdx_flag;")
    pk.append("  assign ftq_req.ftqIdx_value  = io_ftqInter_fromFtq_req_bits_ftqIdx_value;")
    pk.append("  assign ftq_req.ftqOffset_valid = io_ftqInter_fromFtq_req_bits_ftqOffset_valid;")
    pk.append("  assign ftq_req.ftqOffset_bits  = io_ftqInter_fromFtq_req_bits_ftqOffset_bits;")
    # topdown reasons in
    pk.append("  wire [37:0] ftq_req_topdown_reasons = {")
    pk.append("    " + ", ".join(f"io_ftqInter_fromFtq_req_bits_topdown_info_reasons_{i}" for i in range(37, -1, -1)) + "};")

    # struct/array output nets from core
    nets = []
    nets.append("  pd_info_t [15:0] c_pdWb_pd, c_ibuffer_pd;")
    nets.append("  wire [15:0][49:0] c_pdWb_pc, c_ibuffer_pc;")
    nets.append("  wire [15:0][31:0] c_ibuffer_instrs;")
    nets.append("  wire [15:0][9:0]  c_ibuffer_foldpc;")
    nets.append("  wire [15:0][1:0]  c_ibuffer_exceptionType;")
    nets.append("  wire [15:0][3:0]  c_ibuffer_triggered;")
    nets.append("  wire [15:0]       c_pdWb_instrRange, c_ibuffer_valid_vec, c_ibuffer_enqEnable;")
    nets.append("  wire [15:0]       c_ibuffer_ftqOffset_valid, c_ibuffer_backendException;")
    nets.append("  wire [15:0]       c_ibuffer_crossPageIPFFix, c_ibuffer_illegalInstr, c_ibuffer_isLastInFtqEntry;")
    nets.append("  wire [37:0]       c_ibuffer_topdown_reasons;")
    nets.append("  wire [12:0][5:0]  c_perf_value;")

    # rob commit valid vector
    pk.append("  wire [7:0] rob_commit_valid = {io_rob_commits_7_valid, io_rob_commits_6_valid,")
    pk.append("    io_rob_commits_5_valid, io_rob_commits_4_valid, io_rob_commits_3_valid,")
    pk.append("    io_rob_commits_2_valid, io_rob_commits_1_valid, io_rob_commits_0_valid};")

    # ---- core instantiation ----
    inst = []
    inst.append("  xs_NewIFU_core u_core (")
    inst.append("    .clock(clock), .reset(reset),")
    inst.append("    .ftq_req_ready(io_ftqInter_fromFtq_req_ready), .ftq_req_valid(io_ftqInter_fromFtq_req_valid),")
    inst.append("    .ftq_req(ftq_req), .ftq_req_topdown_reasons(ftq_req_topdown_reasons),")
    inst.append("    .ftq_redirect_valid(io_ftqInter_fromFtq_redirect_valid),")
    inst.append("    .ftq_redirect_ftqIdx_flag(io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag),")
    inst.append("    .ftq_redirect_ftqIdx_value(io_ftqInter_fromFtq_redirect_bits_ftqIdx_value),")
    inst.append("    .ftq_redirect_ftqOffset(io_ftqInter_fromFtq_redirect_bits_ftqOffset),")
    inst.append("    .ftq_redirect_level(io_ftqInter_fromFtq_redirect_bits_level),")
    inst.append("    .ftq_topdown_redirect_valid(io_ftqInter_fromFtq_topdown_redirect_valid),")
    inst.append("    .ftq_topdown_redirect_debugIsCtrl(io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl),")
    inst.append("    .ftq_topdown_redirect_debugIsMemVio(io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio),")
    inst.append("    .ftq_topdown_redirect_cfi_pd_isRet(io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet),")
    inst.append("    .ftq_topdown_redirect_cfi_br_hit(io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit),")
    inst.append("    .ftq_topdown_redirect_cfi_jr_hit(io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit),")
    inst.append("    .ftq_topdown_redirect_cfi_sc_hit(io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit),")
    inst.append("    .bpu_flush_s2_valid(io_ftqInter_fromFtq_flushFromBpu_s2_valid),")
    inst.append("    .bpu_flush_s2_flag(io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag),")
    inst.append("    .bpu_flush_s2_value(io_ftqInter_fromFtq_flushFromBpu_s2_bits_value),")
    inst.append("    .bpu_flush_s3_valid(io_ftqInter_fromFtq_flushFromBpu_s3_valid),")
    inst.append("    .bpu_flush_s3_flag(io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag),")
    inst.append("    .bpu_flush_s3_value(io_ftqInter_fromFtq_flushFromBpu_s3_bits_value),")
    inst.append("    .pdWb_valid(io_ftqInter_toFtq_pdWb_valid),")
    inst.append("    .pdWb_pc(c_pdWb_pc), .pdWb_pd(c_pdWb_pd),")
    inst.append("    .pdWb_ftqIdx_flag(io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag),")
    inst.append("    .pdWb_ftqIdx_value(io_ftqInter_toFtq_pdWb_bits_ftqIdx_value),")
    inst.append("    .pdWb_misOffset_valid(io_ftqInter_toFtq_pdWb_bits_misOffset_valid),")
    inst.append("    .pdWb_misOffset_bits(io_ftqInter_toFtq_pdWb_bits_misOffset_bits),")
    inst.append("    .pdWb_cfiOffset_valid(io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid),")
    inst.append("    .pdWb_target(io_ftqInter_toFtq_pdWb_bits_target),")
    inst.append("    .pdWb_jalTarget(io_ftqInter_toFtq_pdWb_bits_jalTarget),")
    inst.append("    .pdWb_instrRange(c_pdWb_instrRange),")
    inst.append("    .icache_ready(io_icacheInter_icacheReady), .icache_resp_valid(io_icacheInter_resp_valid),")
    inst.append("    .icache_resp_doubleline(io_icacheInter_resp_bits_doubleline),")
    inst.append("    .icache_resp_vaddr_0(io_icacheInter_resp_bits_vaddr_0),")
    inst.append("    .icache_resp_vaddr_1(io_icacheInter_resp_bits_vaddr_1),")
    inst.append("    .icache_resp_data(io_icacheInter_resp_bits_data),")
    inst.append("    .icache_resp_paddr_0(io_icacheInter_resp_bits_paddr_0),")
    inst.append("    .icache_resp_exception_0(io_icacheInter_resp_bits_exception_0),")
    inst.append("    .icache_resp_exception_1(io_icacheInter_resp_bits_exception_1),")
    inst.append("    .icache_resp_pmp_mmio_0(io_icacheInter_resp_bits_pmp_mmio_0),")
    inst.append("    .icache_resp_pmp_mmio_1(io_icacheInter_resp_bits_pmp_mmio_1),")
    inst.append("    .icache_resp_itlb_pbmt_0(io_icacheInter_resp_bits_itlb_pbmt_0),")
    inst.append("    .icache_resp_itlb_pbmt_1(io_icacheInter_resp_bits_itlb_pbmt_1),")
    inst.append("    .icache_resp_backendException(io_icacheInter_resp_bits_backendException),")
    inst.append("    .icache_resp_gpaddr(io_icacheInter_resp_bits_gpaddr),")
    inst.append("    .icache_resp_isForVSnonLeafPTE(io_icacheInter_resp_bits_isForVSnonLeafPTE),")
    inst.append("    .icache_topdownIcacheMiss(io_icacheInter_topdownIcacheMiss),")
    inst.append("    .icache_topdownItlbMiss(io_icacheInter_topdownItlbMiss),")
    inst.append("    .icacheStop(io_icacheStop),")
    inst.append("    .perf_only_0_hit(io_icachePerfInfo_only_0_hit), .perf_only_0_miss(io_icachePerfInfo_only_0_miss),")
    inst.append("    .perf_hit_0_hit_1(io_icachePerfInfo_hit_0_hit_1), .perf_hit_0_miss_1(io_icachePerfInfo_hit_0_miss_1),")
    inst.append("    .perf_miss_0_hit_1(io_icachePerfInfo_miss_0_hit_1), .perf_miss_0_miss_1(io_icachePerfInfo_miss_0_miss_1),")
    inst.append("    .perf_hit_0_except_1(io_icachePerfInfo_hit_0_except_1), .perf_miss_0_except_1(io_icachePerfInfo_miss_0_except_1),")
    inst.append("    .perf_except_0(io_icachePerfInfo_except_0),")
    inst.append("    .perf_bank_hit_0(io_icachePerfInfo_bank_hit_0), .perf_bank_hit_1(io_icachePerfInfo_bank_hit_1),")
    inst.append("    .perf_hit(io_icachePerfInfo_hit),")
    inst.append("    .ibuffer_ready(io_toIbuffer_ready), .ibuffer_valid(io_toIbuffer_valid),")
    inst.append("    .ibuffer_instrs(c_ibuffer_instrs), .ibuffer_valid_vec(io_toIbuffer_bits_valid),")
    inst.append("    .ibuffer_enqEnable(c_ibuffer_enqEnable), .ibuffer_pd(c_ibuffer_pd),")
    inst.append("    .ibuffer_foldpc(c_ibuffer_foldpc), .ibuffer_ftqOffset_valid(c_ibuffer_ftqOffset_valid),")
    inst.append("    .ibuffer_backendException(c_ibuffer_backendException),")
    inst.append("    .ibuffer_exceptionType(c_ibuffer_exceptionType),")
    inst.append("    .ibuffer_crossPageIPFFix(c_ibuffer_crossPageIPFFix),")
    inst.append("    .ibuffer_illegalInstr(c_ibuffer_illegalInstr),")
    inst.append("    .ibuffer_triggered(c_ibuffer_triggered),")
    inst.append("    .ibuffer_isLastInFtqEntry(c_ibuffer_isLastInFtqEntry),")
    inst.append("    .ibuffer_pc(c_ibuffer_pc),")
    inst.append("    .ibuffer_ftqPtr_flag(io_toIbuffer_bits_ftqPtr_flag),")
    inst.append("    .ibuffer_ftqPtr_value(io_toIbuffer_bits_ftqPtr_value),")
    inst.append("    .ibuffer_topdown_reasons(c_ibuffer_topdown_reasons),")
    inst.append("    .toBackend_gpaddrMem_wen(io_toBackend_gpaddrMem_wen),")
    inst.append("    .toBackend_gpaddrMem_waddr(io_toBackend_gpaddrMem_waddr),")
    inst.append("    .toBackend_gpaddrMem_wdata_gpaddr(io_toBackend_gpaddrMem_wdata_gpaddr),")
    inst.append("    .toBackend_gpaddrMem_wdata_isForVSnonLeafPTE(io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE),")
    inst.append("    .uncache_resp_valid(io_uncacheInter_fromUncache_valid),")
    inst.append("    .uncache_resp_data(io_uncacheInter_fromUncache_bits_data),")
    inst.append("    .uncache_resp_corrupt(io_uncacheInter_fromUncache_bits_corrupt),")
    inst.append("    .uncache_req_ready(io_uncacheInter_toUncache_ready),")
    inst.append("    .uncache_req_valid(io_uncacheInter_toUncache_valid),")
    inst.append("    .uncache_req_addr(io_uncacheInter_toUncache_bits_addr),")
    inst.append("    .itlb_req_ready(io_iTLBInter_req_ready), .itlb_req_valid(io_iTLBInter_req_valid),")
    inst.append("    .itlb_req_vaddr(io_iTLBInter_req_bits_vaddr), .itlb_resp_ready(io_iTLBInter_resp_ready),")
    inst.append("    .itlb_resp_valid(io_iTLBInter_resp_valid), .itlb_resp_paddr_0(io_iTLBInter_resp_bits_paddr_0),")
    inst.append("    .itlb_resp_gpaddr_0(io_iTLBInter_resp_bits_gpaddr_0), .itlb_resp_pbmt_0(io_iTLBInter_resp_bits_pbmt_0),")
    inst.append("    .itlb_resp_miss(io_iTLBInter_resp_bits_miss),")
    inst.append("    .itlb_resp_isForVSnonLeafPTE(io_iTLBInter_resp_bits_isForVSnonLeafPTE),")
    inst.append("    .itlb_resp_gpf_instr(io_iTLBInter_resp_bits_excp_0_gpf_instr),")
    inst.append("    .itlb_resp_pf_instr(io_iTLBInter_resp_bits_excp_0_pf_instr),")
    inst.append("    .itlb_resp_af_instr(io_iTLBInter_resp_bits_excp_0_af_instr),")
    inst.append("    .pmp_req_addr(io_pmp_req_bits_addr), .pmp_resp_instr(io_pmp_resp_instr), .pmp_resp_mmio(io_pmp_resp_mmio),")
    inst.append("    .mmioCommitRead_mmioFtqPtr_flag(io_mmioCommitRead_mmioFtqPtr_flag),")
    inst.append("    .mmioCommitRead_mmioFtqPtr_value(io_mmioCommitRead_mmioFtqPtr_value),")
    inst.append("    .mmioCommitRead_mmioLastCommit(io_mmioCommitRead_mmioLastCommit),")
    inst.append("    .ft_tUpdate_valid(io_frontendTrigger_tUpdate_valid),")
    inst.append("    .ft_tUpdate_addr(io_frontendTrigger_tUpdate_bits_addr),")
    inst.append("    .ft_tUpdate_matchType(io_frontendTrigger_tUpdate_bits_tdata_matchType),")
    inst.append("    .ft_tUpdate_select(io_frontendTrigger_tUpdate_bits_tdata_select),")
    inst.append("    .ft_tUpdate_action(io_frontendTrigger_tUpdate_bits_tdata_action),")
    inst.append("    .ft_tUpdate_chain(io_frontendTrigger_tUpdate_bits_tdata_chain),")
    inst.append("    .ft_tUpdate_tdata2(io_frontendTrigger_tUpdate_bits_tdata_tdata2),")
    inst.append("    .ft_tEnableVec({io_frontendTrigger_tEnableVec_3, io_frontendTrigger_tEnableVec_2, io_frontendTrigger_tEnableVec_1, io_frontendTrigger_tEnableVec_0}),")
    inst.append("    .ft_debugMode(io_frontendTrigger_debugMode),")
    inst.append("    .ft_triggerCanRaiseBpExp(io_frontendTrigger_triggerCanRaiseBpExp),")
    inst.append("    .rob_commit_valid(rob_commit_valid),")
    for i in range(8):
        inst.append(f"    .rob_commit_{i}_ftqIdx_flag(io_rob_commits_{i}_bits_ftqIdx_flag), .rob_commit_{i}_ftqIdx_value(io_rob_commits_{i}_bits_ftqIdx_value), .rob_commit_{i}_ftqOffset(io_rob_commits_{i}_bits_ftqOffset),")
    inst.append("    .csr_fsIsOff(io_csr_fsIsOff),")
    inst.append("    .perf_value(c_perf_value)")
    inst.append("  );")

    # ---- unpack struct/array outputs to flat golden ports ----
    up = []
    for i in range(PW):
        up.append(f"  assign io_ftqInter_toFtq_pdWb_bits_pc_{i} = c_pdWb_pc[{i}];")
    for i in range(PW):
        up.append(f"  assign io_ftqInter_toFtq_pdWb_bits_pd_{i}_valid  = c_pdWb_pd[{i}].valid;")
        up.append(f"  assign io_ftqInter_toFtq_pdWb_bits_pd_{i}_isRVC  = c_pdWb_pd[{i}].isRVC;")
        up.append(f"  assign io_ftqInter_toFtq_pdWb_bits_pd_{i}_brType = c_pdWb_pd[{i}].brType;")
        up.append(f"  assign io_ftqInter_toFtq_pdWb_bits_pd_{i}_isCall = c_pdWb_pd[{i}].isCall;")
        up.append(f"  assign io_ftqInter_toFtq_pdWb_bits_pd_{i}_isRet  = c_pdWb_pd[{i}].isRet;")
    for i in range(PW):
        up.append(f"  assign io_ftqInter_toFtq_pdWb_bits_instrRange_{i} = c_pdWb_instrRange[{i}];")
    # ibuffer
    for i in range(PW):
        up.append(f"  assign io_toIbuffer_bits_instrs_{i} = c_ibuffer_instrs[{i}];")
    up.append("  assign io_toIbuffer_bits_enqEnable = c_ibuffer_enqEnable;")
    for i in range(PW):
        up.append(f"  assign io_toIbuffer_bits_pd_{i}_isRVC  = c_ibuffer_pd[{i}].isRVC;")
        up.append(f"  assign io_toIbuffer_bits_pd_{i}_brType = c_ibuffer_pd[{i}].brType;")
    for i in range(PW):
        up.append(f"  assign io_toIbuffer_bits_foldpc_{i} = c_ibuffer_foldpc[{i}];")
        up.append(f"  assign io_toIbuffer_bits_ftqOffset_{i}_valid = c_ibuffer_ftqOffset_valid[{i}];")
        up.append(f"  assign io_toIbuffer_bits_exceptionType_{i} = c_ibuffer_exceptionType[{i}];")
        up.append(f"  assign io_toIbuffer_bits_crossPageIPFFix_{i} = c_ibuffer_crossPageIPFFix[{i}];")
        up.append(f"  assign io_toIbuffer_bits_illegalInstr_{i} = c_ibuffer_illegalInstr[{i}];")
        up.append(f"  assign io_toIbuffer_bits_triggered_{i} = c_ibuffer_triggered[{i}];")
        up.append(f"  assign io_toIbuffer_bits_isLastInFtqEntry_{i} = c_ibuffer_isLastInFtqEntry[{i}];")
        up.append(f"  assign io_toIbuffer_bits_pc_{i} = c_ibuffer_pc[{i}];")
    up.append("  assign io_toIbuffer_bits_backendException_0 = c_ibuffer_backendException[0];")
    for i in range(38):
        up.append(f"  assign io_toIbuffer_bits_topdown_info_reasons_{i} = c_ibuffer_topdown_reasons[{i}];")
    for i in range(13):
        up.append(f"  assign io_perf_{i}_value = c_perf_value[{i}];")
    # iTLB req fixed-tie ports the core doesn't drive (golden has them as outputs? check)
    L += pk + nets + inst + up
    L.append("endmodule")
    return "\n".join(L) + "\n"


def emit_tb():
    ps = ports("NewIFU")
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    L = ["// 自动生成：scripts/gen_newifu.py —— 勿手改",
         "// golden NewIFU vs NewIFU_xs 双例化，随机激励逐拍比对全部输出。",
         "`timescale 1ns/1ps",
         "module tb;",
         "  int unsigned NCYCLES = 80000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;",
         ""]
    for w, n in ins:
        L.append(f"  logic {haswidth(w)}{n};")
    for w, n in outs:
        L.append(f"  wire {haswidth(w)}g_{n};")
        L.append(f"  wire {haswidth(w)}i_{n};")
    # instantiations
    gconn = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gconn + [f".{n}(g_{n})" for _, n in outs]
    ig = gconn + [f".{n}(i_{n})" for _, n in outs]
    L.append(f"  NewIFU    u_g ({', '.join(gg)});")
    L.append(f"  NewIFU_xs u_i ({', '.join(ig)});")
    # stimulus
    L.append("""
  // 随机激励：以 negedge 驱动，给取指请求/ICache 响应/flush/redirect/MMIO/commit。
  always @(negedge clk) if (rst) begin
    // 复位时把所有输入清 0
""")
    for w, n in ins:
        L.append(f"    {n} <= '0;")
    L.append("  end else begin")
    # drive with biased randomness; valids low-ish, addrs constrained
    for w, n in ins:
        if n == "io_ftqInter_fromFtq_req_valid":
            L.append(f"    {n} <= ($urandom_range(0,3)!=0);")
        elif n.endswith("_valid") or n.endswith("_ready") or n == "io_icacheInter_icacheReady":
            L.append(f"    {n} <= ($urandom_range(0,3)!=0);")
        elif n in ("io_ftqInter_fromFtq_redirect_valid","io_ftqInter_fromFtq_topdown_redirect_valid",
                   "io_ftqInter_fromFtq_flushFromBpu_s2_valid","io_ftqInter_fromFtq_flushFromBpu_s3_valid"):
            L.append(f"    {n} <= ($urandom_range(0,15)==0);")
        elif "startAddr" in n or "nextlineStart" in n or "nextStartAddr" in n or n=="io_icacheInter_resp_bits_vaddr_0" or n=="io_icacheInter_resp_bits_vaddr_1":
            # constrain addr to a small space to maximize startAddr==vaddr matches
            L.append(f"    {n} <= {{38'h0, $urandom_range(0,3), 6'($urandom)}};")
        elif w <= 32:
            L.append(f"    {n} <= {w}'($urandom);")
        else:
            rep = (w + 31)//32
            L.append(f"    {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    L.append("  end")
    # checker
    L.append("""
  // 比对：golden 在流水未热身/未 fire 时寄存器为 X(SYNTHESIS 下无初值)，
  // 这些位置 golden 输出 X 不具可比性 → 用 !$isunknown(golden) 跳过。
  always @(negedge clk) if (!rst) begin
    #4; checks++;""")
    for w, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && (g_{n} !== i_{n})) begin errors++;")
        L.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    L.append("  end")
    L.append("""
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(L)


def main():
    hdr = "// 自动生成：scripts/gen_newifu.py —— 勿手改\n"
    (XSSV / "rtl/frontend/NewIFU_subs.sv").write_text(emit_subs())
    (XSSV / "rtl/frontend/NewIFU_wrapper.sv").write_text(hdr + emit_wrapper("NewIFU"))
    ut = XSSV / "verif/ut/NewIFU"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_wrapper("NewIFU_xs"))
    (ut / "tb.sv").write_text(emit_tb())
    print("generated NewIFU_subs.sv, NewIFU_wrapper.sv, variants_xs.sv, tb.sv")
    print(f"NewIFU ports: {len(ports('NewIFU'))}")


if __name__ == "__main__":
    main()
