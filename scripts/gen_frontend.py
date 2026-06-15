#!/usr/bin/env python3
"""
Frontend 顶层（前端总顶层：BPU/IFU/ICache/FTQ/IBuffer + ITLB/PMP + redirect 路由）生成器。

解析 golden `Frontend.sv`，生成：
  - rtl/frontend/Frontend_wrapper.sv : golden 同名 wrapper `Frontend`
      = 逐字照搬 golden body（25 个子模块黑盒例化 + MBIST/SRAM/PTW 物理 sideband 扇出
        + A/B 两类 glue 逻辑），额外例化可读核 xs_Frontend_core 作"校验伴随"（影子输出
        悬空，不改变对外功能 → FM 与 golden 纯等价）。
  - verif/ut/Frontend/variants_xs.sv : 镜像 `Frontend_xs`
      = 同 wrapper，但把可读核的影子输出经 xs_dbg_* **额外输出端口**引出，供 tb 探针比对。
  - verif/ut/Frontend/tb.sv          : golden(`Frontend`) vs `Frontend_xs` 双例化，
      随机后端 redirect/commit/取指握手/sfence/TLB 响应，逐拍比对：
        (1) 全部对外功能输出 g_* === i_*；
        (2) 影子探针：可读核 xs_dbg_* === golden 内部对应寄存器（u_g.inner_*）。
  - verif/ut/Frontend/Makefile       : 自动算出 golden Frontend 的全部传递依赖（197 文件）。

设计观察（详见 docs/frontend/Frontend.md）：
  * Frontend 是前端总顶层：例化 Predictor/Ftq/NewIFU/ICache/IBuffer 五大子系统 +
    TLB(ITLB)/PMP/PMPChecker×5/PTWFilter/PTWRepeater(取指翻译) + PFEvent/HPerfMonitor(性能)
    + InstrUncache(MMIO 取指) + DelayN×4 + MBIST 接口，全部已各自验证 → 当 golden 黑盒。
  * golden 9749 行里，真正属于 Frontend 自身的"逻辑"只有两类（其余全是接线/sideband）：
      A. 跨级打拍流水寄存：redirect→IBuffer 冲刷、sfence→ITLB(2 拍)、fencei/pf→ICache(1 拍)、
         icache error→io_error(2 拍)、perf→io_perf(2 拍)；
      B. 跨取指块 PC 连续性一致性检查器：checkPcMem(64×50 FTQ startAddr 镜像) +
         prevTaken/prevNotTaken/prevIsRVC 跨块 latch + 6-lane 扫描，验证相邻指令/相邻块
         PC 连续且与预测一致（纯校验，不驱动对外输出，但是前端唯一非平凡逻辑）。
    这两类被手写为可读核 xs_Frontend_core（rtl/frontend/Frontend.sv），是学习载体。

wrapper 与可读核的关系（同 Predictor 的"校验伴随"范式）：
  - wrapper 即 golden body 的忠实复制（去 firtool 随机化样板、保留同名 net）→ FM/UT 基线。
  - xs_Frontend_core 吃 wrapper 内同名源 net，独立可读再实现 A/B 两类逻辑，吐影子输出：
      · A 类影子（flush/sfence_q/error_q/perf_q…）与 golden 对应输出/寄存器逐拍比对；
      · B 类影子（pc_continuity_violation）与 golden 各 inner__probe_N 的或逐拍比对。
"""
import re
import os
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
SRC = (GOLDEN / "Frontend.sv").read_text()

# ---------------------------------------------------------------------------
# 1. 解析顶层端口
# ---------------------------------------------------------------------------
def parse_ports(text, modname):
    hdr = re.search(rf"^module {re.escape(modname)}\((.*?)\n\);", text, re.S | re.M).group(1)
    res = []
    for line in hdr.splitlines():
        m = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if m:
            res.append((m.group(1), int(m.group(2)) + 1 if m.group(2) else 1, m.group(3)))
    return res

PORTS = parse_ports(SRC, "Frontend")

# ---------------------------------------------------------------------------
# 2. 计算 golden Frontend 的全部传递依赖（用于 UT/FM 的 GOLDEN_SRCS）
# ---------------------------------------------------------------------------
def dep_closure():
    files = [f for f in os.listdir(GOLDEN) if f.endswith((".sv", ".v"))]
    mod2file = {}
    for fn in files:
        t = (GOLDEN / fn).read_text(errors="ignore")
        for m in re.findall(r"^\s*module\s+([A-Za-z_][A-Za-z_0-9]*)\b", t, re.M):
            mod2file.setdefault(m, fn)
    kw = {"module", "input", "output", "wire", "reg", "assign", "always", "if",
          "else", "begin", "end", "case", "for", "initial", "localparam",
          "parameter", "logic", "genvar", "generate", "endmodule", "function", "task"}

    def insts(fn):
        t = (GOLDEN / fn).read_text(errors="ignore")
        res = set()
        for m in re.finditer(
                r"^\s{2,}([A-Za-z_][A-Za-z_0-9]*)\s+(?:#\([^)]*\)\s*)?"
                r"[A-Za-z_][A-Za-z_0-9]*\s*\(\s*$", t, re.M):
            res.add(m.group(1))
        return res

    seen, queue, closure = set(), ["Frontend.sv"], set()
    while queue:
        fn = queue.pop()
        if fn in seen:
            continue
        seen.add(fn)
        for mod in insts(fn):
            if mod in kw:
                continue
            f = mod2file.get(mod)
            if f and f != "Frontend.sv":
                closure.add(f)
                if f not in seen:
                    queue.append(f)
    return sorted(closure)

# ---------------------------------------------------------------------------
# 3. golden body 提取（端口列表 ");" 之后 ~ "endmodule" 之前；去随机化样板）
#    保留：声明、assign、always、子模块例化、`ifndef SYNTHESIS 断言块。
#    去除：`ifdef ENABLE_INITIAL_REG_ ... `endif（仅仿真随机初始化）。
# ---------------------------------------------------------------------------
def golden_body():
    lines = SRC.splitlines()
    # 端口结束行 ");"（第一个顶格 ");"）
    pend = next(i for i, l in enumerate(lines) if l.rstrip() == ");")
    eend = next(i for i, l in enumerate(lines) if l.rstrip() == "endmodule")
    body = lines[pend + 1:eend]
    # 删除 `ifdef ENABLE_INITIAL_REG_ ... `endif // ENABLE_INITIAL_REG_ 区段
    out, skip = [], False
    for l in body:
        if "`ifdef ENABLE_INITIAL_REG_" in l:
            skip = True
            continue
        if skip and "ENABLE_INITIAL_REG_" in l and "`endif" in l:
            skip = False
            continue
        if skip:
            continue
        out.append(l)
    return "\n".join(out)

GBODY = golden_body()

# 头部宏（module 之前，行 1..86）—— RANDOM/SYNTHESIS/ASSERT 宏样板，UT 定义 SYNTHESIS 关掉
def golden_header():
    lines = SRC.splitlines()
    mstart = next(i for i, l in enumerate(lines) if l.startswith("module Frontend("))
    return "\n".join(lines[:mstart])

GHEADER = golden_header()

# ---------------------------------------------------------------------------
# 4. 端口声明渲染
# ---------------------------------------------------------------------------
def decl(d, w, n):
    ws = f"[{w-1}:0] " if w > 1 else ""
    return f"  {d:6s} {ws}{n}"

def port_block(ports):
    return ",\n".join(decl(*p) for p in ports)

# ---------------------------------------------------------------------------
# 5. 校验伴随：golden net → 可读核端口 的连接映射
# ---------------------------------------------------------------------------
# IBuffer 6 lane 的 struct 打包（与 ib_lane_t 字段顺序一致：
#   {fire, pc, ftq_flag, ftq_value, br_type, pred_taken, is_rvc}）
def ib_lane_concat():
    rows = []
    for i in range(6):
        b = f"_inner_ibuffer_io_out_{i}"
        fire = f"(io_backend_cfVec_{i}_ready & {b}_valid)"
        rows.append(
            f"    '{{fire:{fire}, pc:{b}_bits_pc, "
            f"ftq_flag:{b}_bits_ftqPtr_flag, ftq_value:{b}_bits_ftqPtr_value, "
            f"br_type:{b}_bits_pd_brType, pred_taken:{b}_bits_pred_taken, "
            f"is_rvc:{b}_bits_pd_isRVC}}")
    return ",\n".join(rows)

def perf_in_concat():
    return ", ".join(f"_inner_perfEvents_hpm_io_perf_{p}_value" for p in range(8))

# 可读核例化（影子输出按 expose 决定连到 net 还是悬空）
def core_inst(expose):
    def o(port):
        # A 类影子输出：expose=True → 连 xs_dbg_<port>；否则悬空
        return f"xs_dbg_{port}" if expose else "/* dbg */"
    # perf_q 是 unpacked 数组输出：expose 时连模块的 xs_dbg_perf_q 数组端口，否则连本地数组
    perf_q_conn = "xs_dbg_perf_q" if expose else "xs_dbg_perf_q_open"
    perf_in = "'{" + perf_in_concat() + "}"
    L = []
    L.append("  // ===== 可读核 xs_Frontend_core（校验伴随；纯增量，不影响对外功能）=====")
    L.append("  ib_lane_t xs_ib_lane [6];")
    L.append("  assign xs_ib_lane = '{")
    L.append(ib_lane_concat())
    L.append("  };")
    if not expose:
        # 非 expose（golden 同名 wrapper）：perf_q 接本地悬空数组，避免无驱动端口
        L.append("  wire [5:0] xs_dbg_perf_q_open [8];")
    L.append("  xs_Frontend_core u_core (")
    conns = [
        ".clock(clock)", ".reset(reset)",
        # A 类输入
        ".redirect_valid(io_backend_toFtq_redirect_valid)",
        ".redirect_is_ctrl(io_backend_toFtq_redirect_bits_debugIsCtrl)",
        ".redirect_is_memvio(io_backend_toFtq_redirect_bits_debugIsMemVio)",
        ".sfence_valid(io_sfence_valid)",
        ".sfence_rs1(io_sfence_bits_rs1)",
        ".sfence_rs2(io_sfence_bits_rs2)",
        ".sfence_addr(io_sfence_bits_addr)",
        ".sfence_id(io_sfence_bits_id)",
        ".sfence_flushPipe(io_sfence_bits_flushPipe)",
        ".sfence_hv(io_sfence_bits_hv)",
        ".sfence_hg(io_sfence_bits_hg)",
        ".fencei(io_fencei)",
        ".csr_pf_enable(_inner_csrCtrl_delay_io_out_pf_ctrl_l1I_pf_enable)",
        ".icache_err_valid(_inner_icache_io_error_valid)",
        ".icache_err_paddr(_inner_icache_io_error_bits_paddr)",
        ".icache_err_to_beu(_inner_icache_io_error_bits_report_to_beu)",
        f".perf_in({perf_in})",
        # A 类输出（影子）
        f".flush({o('flush')})",
        f".flush_ctrl_redirect({o('flush_ctrl')})",
        f".flush_memvio_redirect({o('flush_memvio')})",
        f".sfence_q_valid({o('sfence_q_valid')})",
        f".sfence_q_rs1({o('sfence_q_rs1')})",
        f".sfence_q_rs2({o('sfence_q_rs2')})",
        f".sfence_q_addr({o('sfence_q_addr')})",
        f".sfence_q_id({o('sfence_q_id')})",
        f".sfence_q_flushPipe({o('sfence_q_flushPipe')})",
        f".sfence_q_hv({o('sfence_q_hv')})",
        f".sfence_q_hg({o('sfence_q_hg')})",
        f".icache_fencei_q({o('icache_fencei_q')})",
        f".icache_pf_enable_q({o('icache_pf_enable_q')})",
        f".error_valid_q({o('error_valid_q')})",
        f".error_paddr_q({o('error_paddr_q')})",
        f".error_to_beu_q({o('error_to_beu_q')})",
        f".perf_q({perf_q_conn})",
        # B 类输入
        ".ib_lane(xs_ib_lane)",
        ".ftq_pcmem_wen(_inner_ftq_io_toBackend_pc_mem_wen)",
        ".ftq_pcmem_waddr(_inner_ftq_io_toBackend_pc_mem_waddr)",
        ".ftq_pcmem_wdata(_inner_ftq_io_toBackend_pc_mem_wdata_startAddr)",
        ".ftq_newest_ptr_value(_inner_ftq_io_toBackend_newest_entry_ptr_value)",
        ".ftq_newest_target(_inner_ftq_io_toBackend_newest_entry_target)",
        # B 类输出（影子）
        f".pc_continuity_violation({o('pc_vio')})",
    ]
    L.append(",\n".join("    " + c for c in conns))
    L.append("  );")
    return "\n".join(L)

# 影子调试端口（_xs 变体额外输出）
DBG_PORTS = [
    (1, "xs_dbg_flush"), (1, "xs_dbg_flush_ctrl"), (1, "xs_dbg_flush_memvio"),
    (1, "xs_dbg_sfence_q_valid"), (1, "xs_dbg_sfence_q_rs1"), (1, "xs_dbg_sfence_q_rs2"),
    (50, "xs_dbg_sfence_q_addr"), (16, "xs_dbg_sfence_q_id"),
    (1, "xs_dbg_sfence_q_flushPipe"), (1, "xs_dbg_sfence_q_hv"), (1, "xs_dbg_sfence_q_hg"),
    (1, "xs_dbg_icache_fencei_q"), (1, "xs_dbg_icache_pf_enable_q"),
    (1, "xs_dbg_error_valid_q"), (48, "xs_dbg_error_paddr_q"), (1, "xs_dbg_error_to_beu_q"),
    (1, "xs_dbg_pc_vio"),
]
# perf_q 影子（数组型，端口拆 8 个）
DBG_PERF = [(6, f"xs_dbg_perf_q_{p}") for p in range(8)]

def dbg_port_decls():
    L = []
    # perf_q 用打包数组端口（核口为数组）→ 这里声明 8 个标量输出
    L.append("  output [5:0] xs_dbg_perf_q [8],")  # 数组端口
    for w, n in DBG_PORTS:
        ws = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  output {ws}{n},")
    s = "\n".join(L)
    return s.rstrip(",\n").rstrip(",")

# ---------------------------------------------------------------------------
# 6. 生成 wrapper（golden 同名 Frontend）
# ---------------------------------------------------------------------------
def gen_wrapper():
    L = [GHEADER, "module Frontend\n  import xs_frontend_pkg::*;\n(",
         port_block(PORTS), ");"]
    L.append(GBODY)
    L.append("")
    L.append(core_inst(expose=False))
    L.append("endmodule")
    return "\n".join(L)

# ---------------------------------------------------------------------------
# 7. 生成 _xs 变体（Frontend_xs，额外 xs_dbg_* 输出）
# ---------------------------------------------------------------------------
def gen_xs():
    L = [GHEADER, "module Frontend_xs\n  import xs_frontend_pkg::*;\n(",
         port_block(PORTS) + ",",
         dbg_port_decls(), ");"]
    L.append(GBODY)
    L.append("")
    L.append(core_inst(expose=True))
    L.append("endmodule")
    return "\n".join(L)

# ---------------------------------------------------------------------------
# 8. 生成 tb
# ---------------------------------------------------------------------------
# 随机激励：握手/控制类输入的概率分布；复位区清 0 的 valid 类。
PROB = {
    "io_fencei":                              "($urandom_range(0,63)==0)",
    "io_sfence_valid":                        "($urandom_range(0,31)==0)",
    "io_backend_toFtq_redirect_valid":        "($urandom_range(0,15)==0)",
    "io_ptw_resp_valid":                      "($urandom_range(0,3)!=0)",
    "io_ptw_req_0_ready":                     "($urandom_range(0,1)==0)",
    "io_ptw_resp_ready":                      "1'b1",
    "io_backend_canAccept":                   "($urandom_range(0,3)!=0)",
    "io_backend_wfi_wfiReq":                  "($urandom_range(0,31)==0)",
    "io_softPrefetch_0_valid":                "($urandom_range(0,7)==0)",
    "io_softPrefetch_1_valid":                "($urandom_range(0,7)==0)",
    "io_softPrefetch_2_valid":                "($urandom_range(0,7)==0)",
    "auto_inner_icache_ctrlUnitOpt_in_a_valid":"($urandom_range(0,3)==0)",
    "auto_inner_icache_ctrlUnitOpt_in_d_ready":"($urandom_range(0,1)==0)",
    "auto_inner_icache_client_out_a_ready":   "($urandom_range(0,1)==0)",
    "auto_inner_icache_client_out_d_valid":   "($urandom_range(0,2)==0)",
    "auto_inner_instrUncache_client_out_a_ready":"($urandom_range(0,1)==0)",
    "auto_inner_instrUncache_client_out_d_valid":"($urandom_range(0,3)==0)",
    "io_backend_toFtq_rob_commits_0_valid":   "($urandom_range(0,2)!=0)",
    "io_backend_toFtq_rob_commits_1_valid":   "($urandom_range(0,2)!=0)",
    "io_backend_toFtq_rob_commits_2_valid":   "($urandom_range(0,2)!=0)",
    "io_backend_toFtq_rob_commits_3_valid":   "($urandom_range(0,2)!=0)",
    "io_backend_toFtq_rob_commits_4_valid":   "($urandom_range(0,2)!=0)",
    "io_backend_toFtq_rob_commits_5_valid":   "($urandom_range(0,2)!=0)",
    "io_backend_toFtq_rob_commits_6_valid":   "($urandom_range(0,2)!=0)",
    "io_backend_toFtq_rob_commits_7_valid":   "($urandom_range(0,2)!=0)",
    # backend 取指口 ready 高概率，使 cfVec lane 经常 fire → 多触发检查器
    "io_backend_cfVec_0_ready":               "($urandom_range(0,4)!=0)",
    "io_backend_cfVec_1_ready":               "($urandom_range(0,4)!=0)",
    "io_backend_cfVec_2_ready":               "($urandom_range(0,4)!=0)",
    "io_backend_cfVec_3_ready":               "($urandom_range(0,4)!=0)",
    "io_backend_cfVec_4_ready":               "($urandom_range(0,4)!=0)",
    "io_backend_cfVec_5_ready":               "($urandom_range(0,4)!=0)",
}
# 复位区清 0（valid/flush/req 类）
RST0 = [n for n in PROB if any(k in n for k in
        ("valid", "_req_", "flush", "wfiReq", "canAccept", "ready"))]

# 影子探针：核 xs_dbg_* 对应的 golden 内部寄存器（u_g.<reg>）。
# A 类直接对 golden 对外输出（更稳）；sfence/fencei/error 也对 golden 内部 net。
SHADOW = [
    # (xs_dbg 信号, golden 比对源(u_g.<net>), 名字)
    ("xs_dbg_flush",            "u_g.inner_needFlush",                     "flush"),
    ("xs_dbg_flush_ctrl",       "u_g.inner_FlushControlRedirect",          "flush_ctrl"),
    ("xs_dbg_flush_memvio",     "u_g.inner_FlushMemVioRedirect",           "flush_memvio"),
    ("xs_dbg_sfence_q_valid",   "u_g.inner_sfence_valid",                  "sfence_q_valid"),
    ("xs_dbg_sfence_q_rs1",     "u_g.inner_sfence_bits_rs1",               "sfence_q_rs1"),
    ("xs_dbg_sfence_q_rs2",     "u_g.inner_sfence_bits_rs2",               "sfence_q_rs2"),
    ("xs_dbg_sfence_q_addr",    "u_g.inner_sfence_bits_addr",              "sfence_q_addr"),
    ("xs_dbg_sfence_q_id",      "u_g.inner_sfence_bits_id",                "sfence_q_id"),
    ("xs_dbg_sfence_q_flushPipe","u_g.inner_sfence_bits_flushPipe",        "sfence_q_flushPipe"),
    ("xs_dbg_sfence_q_hv",      "u_g.inner_sfence_bits_hv",                "sfence_q_hv"),
    ("xs_dbg_sfence_q_hg",      "u_g.inner_sfence_bits_hg",                "sfence_q_hg"),
    ("xs_dbg_icache_fencei_q",  "u_g.inner_icache_io_fencei_REG",          "icache_fencei_q"),
    ("xs_dbg_icache_pf_enable_q","u_g.inner_icache_io_csr_pf_enable_REG",  "icache_pf_enable_q"),
    ("xs_dbg_error_valid_q",    "u_g.io_error_valid",                      "error_valid_q"),
    ("xs_dbg_error_paddr_q",    "u_g.io_error_bits_paddr",                 "error_paddr_q"),
    ("xs_dbg_error_to_beu_q",   "u_g.io_error_bits_report_to_beu",         "error_to_beu_q"),
]
SHADOW_PERF = [(f"xs_dbg_perf_q_{p}", f"u_g.io_perf_{p}_value", f"perf_q_{p}")
               for p in range(8)]

def gen_tb():
    ins = [(w, n) for d, w, n in PORTS if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in PORTS if d == "output"]

    T = ["// 自动生成：scripts/gen_frontend.py —— 勿手改",
         "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 120000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0, core_errors = 0;",
         "  always #5 clk = ~clk;", ""]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")
    # 影子 net
    for w, n in DBG_PORTS:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}{n};")
    for w, n in DBG_PERF:
        T.append(f"  wire [5:0] {n};")
    T.append("  wire [5:0] xs_dbg_perf_q [8];")
    for p in range(8):
        T.append(f"  assign xs_dbg_perf_q_{p} = xs_dbg_perf_q[{p}];")

    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    ig += [f".{n}({n})" for _, n in DBG_PORTS]
    ig += [".xs_dbg_perf_q(xs_dbg_perf_q)"]
    T.append("  Frontend    u_g (" + ", ".join(gg) + ");")
    T.append("  Frontend_xs u_i (" + ", ".join(ig) + ");")

    # 随机激励
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in RST0:
        if n in dict((nn, ww) for ww, nn in ins):
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    indict = dict((nn, ww) for ww, nn in ins)
    for w, n in ins:
        if n in PROB:
            T.append(f"      {n} <= {PROB[n]};")
        elif n in ("io_reset_vector",):
            T.append(f"      {n} <= {w}'($urandom);")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    T.append("    end")
    T.append("  end")

    # 比对：对外功能输出
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && (g_{n} !== i_{n})) begin errors++;")
        T.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    # 比对：影子探针（可读核 vs golden 内部寄存器/输出）
    for dbg, gsrc, nm in SHADOW + SHADOW_PERF:
        T.append(f"    if (!$isunknown({gsrc}) && ({gsrc} !== {dbg})) begin core_errors++;")
        T.append(f"      if(core_errors<=60) $display(\"[%0t] CORE {nm} g=%h core=%h\", $time, {gsrc}, {dbg}); end")
    T.append("  end")

    T.append("""  initial begin
    rst = 1; repeat (30) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d core_errors=%0d", checks, errors, core_errors);
    if (errors == 0 && core_errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)

# ---------------------------------------------------------------------------
# 9. 生成 Makefile
# ---------------------------------------------------------------------------
def gen_makefile(deps):
    dep_lines = " \\\n  ".join(f"$(GOLDEN_RTL)/{f}" for f in deps)
    return f"""MODULE = Frontend

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核（含 package xs_frontend_pkg + xs_Frontend_core）
RTL_SRCS     = $(RTL_DIR)/frontend/Frontend.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/Frontend_wrapper.sv
TB_SRCS      = variants_xs.sv tb.sv

# ----------------------------------------------------------------------------
# golden Frontend 例化的 25 个子模块及其全部传递依赖（自动算出，共 {len(deps)} 文件）。
# UT 双例化时 golden Frontend 与 Frontend_xs（同 body + 影子核）共用这一批 golden 实现，
# 故比对仅检验顶层 glue（打拍流水 + PC 连续性检查器）等价；子模块本身已各自验证过。
# ----------------------------------------------------------------------------
SUBMODS = \\
  {dep_lines}

GOLDEN_SRCS = $(GOLDEN_RTL)/Frontend.sv $(SUBMODS)

# FM ref 侧依赖留空：所有子模块两侧均不读源 → hdlin_unresolved_modules=black_box 统一黑盒，
# 顶层 glue + 子模块互联按签名比对等价（wrapper = golden body 忠实复制 + 悬空校验伴随）。
FM_VARIANTS = Frontend
FM_REF_DEPS_Frontend =

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言；UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS
"""

# ---------------------------------------------------------------------------
def main():
    hdr = "// 自动生成：scripts/gen_frontend.py —— 勿手改\n"
    (XSSV / "rtl/frontend/Frontend_wrapper.sv").write_text(hdr + gen_wrapper())
    ut = XSSV / "verif/ut/Frontend"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + gen_xs())
    (ut / "tb.sv").write_text(gen_tb())
    deps = dep_closure()
    (ut / "Makefile").write_text(gen_makefile(deps))

    ins = [p for p in PORTS if p[0] == "input" and p[2] not in ("clock", "reset")]
    outs = [p for p in PORTS if p[0] == "output"]
    print(f"Frontend: {len(PORTS)} ports, {len(ins)} inputs, {len(outs)} outputs, "
          f"{len(deps)} golden deps")


if __name__ == "__main__":
    main()
