#!/usr/bin/env python3
"""
Predictor 顶层（BPU：分支预测单元顶层流水）生成器。

解析 golden `Predictor.sv`，生成：
  - rtl/frontend/Predictor_wrapper.sv : golden 同名 wrapper `Predictor`
  - verif/ut/Predictor/variants_xs.sv : 镜像 `Predictor_xs`
  - verif/ut/Predictor/tb.sv          : golden vs _xs 双例化，随机激励逐拍比对全部输出

设计观察（详见 docs/frontend/Predictor.md）：
  * Predictor 是 BPU 顶层：例化 1 个 Composer（5 预测器菊花链，已单独可读重写+验证）+
    1 个 DelayN（ctrl 使能延迟 1 拍）+ 262 个 PriorityMuxModule（s0 PC / 折叠历史 /
    ghist 指针 / lastBrNumOH / 256 位 ghv 每比特的“多源覆盖写”优先级选择器）。
  * golden 44818 行里，**真正的控制逻辑只有两小块、其余全是历史扇出/接线**：
      ① BPU 流水 FSM：s1/s2/s3 valid 寄存器 + s0/s1 fire + s1/s2 flush + 覆盖式 redirect
         合成 + 对 FTQ 的 resp.valid 握手；
      ② topdown 气泡原因 3 级流水（reason 位 shift-and-OR）。
    这两块被**手写为可读核 xs_Predictor_core**（rtl/frontend/Predictor.sv），是学习载体。
  * 其余（256 位 ghv 移位向量、4×17 折叠历史、ahead-fh-oldest-bits、ghist 指针、
    s2/s3 redirect 判定的庞大组合表达式、Composer/DelayN/PriorityMuxModule 黑盒例化、
    给 Composer 的 io_in_bits_ghist 巨型重建 mux）是 firtool 展平的机械扇出，
    名字/连接必须与 golden 逐字一致，FM 才能把两侧黑盒引脚对齐——故 wrapper **逐字照搬
    golden 整个 body**（仅去掉 firtool 随机化宏样板、改模块名）。这与 Composer 的
    “wrapper 照搬黑盒例化 + 内部 net 原名”策略一致。

wrapper 与可读核的关系：
  - wrapper 即 golden body 的忠实复制（保证 FM 签名分析/UT 逐字等价的基线）。
  - xs_Predictor_core 是 FSM+topdown 的独立可读再实现，由 wrapper 例化为**校验伴随**：
    吃 wrapper 内同名控制源 net，吐出一份 FSM/topdown 影子输出，经 wrapper 的
    `xs_*` 调试端口引出，tb 里与 golden 对应寄存器逐拍比对（证明可读核功能等价）。
    可读核不改变 wrapper 对外功能，纯增量；学习者读 core + 文档即可掌握 BPU 流水控制。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
SRC = (GOLDEN / "Predictor.sv").read_text()

# ----------------------------------------------------------------------------
# 1. 解析顶层端口（module Predictor( ... );）
# ----------------------------------------------------------------------------
def parse_ports(text, modname):
    hdr = re.search(rf"^module {re.escape(modname)}\((.*?)\n\);", text, re.S | re.M).group(1)
    res = []
    for line in hdr.splitlines():
        m = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if m:
            res.append((m.group(1), int(m.group(2)) + 1 if m.group(2) else 1, m.group(3)))
    return res

PORTS = parse_ports(SRC, "Predictor")

def width_str(w):
    return f"[{w-1}:0] " if w > 1 else ""

# ----------------------------------------------------------------------------
# 2. 提取 golden body：从 ");" 之后（端口表结束）到 "endmodule" 之前。
#    这是 wrapper 要逐字照搬的部分（声明 + 实例 + assign + always）。
# ----------------------------------------------------------------------------
mod_start = re.search(r"^module Predictor\(", SRC, re.M).start()
hdr_end = SRC.index("\n);", mod_start) + len("\n);")
endmod = SRC.rindex("\nendmodule")
BODY = SRC[hdr_end:endmod]   # 以 "\n" 开头

# ----------------------------------------------------------------------------
# 3. 可读核 xs_Predictor_core 的接口。
#    核内部重算 FSM(s1/s2/s3_valid, fire, flush, resp.valid) 与 topdown reasons。
#    它消费的“控制源” net（均为 golden 内部已存在的同名 net）：
# ----------------------------------------------------------------------------
CORE_IN = [
    # 流水握手 / 覆盖 redirect（组合，来自 Composer 输出 + redirect 判定）
    ("s1_ready",          "_predictors_io_s1_ready"),
    ("resp_ready",        "io_bpu_to_ftq_resp_ready"),
    ("redirect_valid",    "io_ftq_to_bpu_redirect_valid"),
    ("s2_redirect_0",     "s2_redirect_dup_0_probe"),
    ("s2_redirect_1",     "s2_redirect_dup_1"),
    ("s2_redirect_2",     "s2_redirect_dup_2"),
    ("s2_redirect_3",     "s2_redirect_dup_3"),
    ("s3_redirect_0",     "s3_redirect_dup_0_probe"),
    ("s3_redirect_1",     "s3_redirect_dup_1"),
    ("s3_redirect_2",     "s3_redirect_dup_2"),
    ("s3_redirect_3",     "s3_redirect_dup_3"),
    # topdown 气泡原因解码（组合，来自 redirect payload 寄存器）
    ("control_btb_miss",  "ControlBTBMissBubble"),
    ("control_redirect",  "controlRedirectBubble"),
    ("tage_miss",         "TAGEMissBubble"),
    ("sc_miss",           "SCMissBubble"),
    ("ittage_miss",       "ITTAGEMissBubble"),
    ("ras_miss_pre",      "_RASMissBubble_T"),   # =isJalr&jr_hit；与 isRet 相与得 RASMiss
    ("redirect_is_ret",   "do_redirect_dup_next_bits_r_cfiUpdate_pd_isRet"),
    ("mem_vio_bubble",    "memVioRedirectBubble"),
    ("other_bubble",      "otherRedirectBubble"),
    ("btb_miss_bubble",   "btbMissBubble"),
]
# 核输出（影子；tb 与 golden 同名寄存器逐拍比对）
CORE_OUT = [
    ("s1_valid",  1), ("s2_valid", 1), ("s3_valid", 1),
    ("resp_valid", 1),
    ("s0_fire_0", 1), ("s0_fire_1", 1), ("s0_fire_2", 1), ("s0_fire_3", 1),
    ("s1_fire_0", 1), ("s1_fire_1", 1), ("s1_fire_2", 1), ("s1_fire_3", 1),
] + [(f"topdown2_reason_{i}", 1) for i in (1,2,3,4,5,6,7,8,9,12)]

# 影子输出引到 wrapper 的调试端口（仅 _xs / tb 用；golden 无这些口，tb 用层次探针对golden）
CORE_DBG_PORTS = [(f"xs_dbg_{n}", w) for n, w in CORE_OUT]


def strip_firtool_macros(body):
    """body 本身不含宏定义（宏在 module 之前），无需处理；保留以备扩展。"""
    return body


# 状态元素：由可读核 u_core 驱动（不再由 golden-copied body 驱动）。
# s{1,2,3}_valid_dup_3 = FSM valid（547 扇出，喂 resp.valid/s2_valid/s3_valid 输出+全部
# 预测门控）；topdown_stages_2_reasons_* = 3 级气泡原因流水的末级寄存器。
SPLICE_VALID_REGS = ["s1_valid_dup_3", "s2_valid_dup_3", "s3_valid_dup_3"]
SPLICE_TD2_REGS = [f"topdown_stages_2_reasons_{i}" for i in (1,2,3,4,5,6,7,8,9,12)]
# 整个 topdown reasons 3 级流水都搬进 u_core：stage_0/stage_1 若只喂 stage_2 会在 splice 后
# 变 impl-only 死寄存器，故 stage_0/stage_1 也一并删除（输出级仍保留 golden 同拍 _GEN_10x
# 注入，见 io_bpu_to_ftq_resp_bits_topdown_info_reasons_* 保持不动）。
SPLICE_TD01_REGS = [f"topdown_stages_{s}_reasons_{i}"
                    for s in (0, 1) for i in (1,2,3,4,5,6,7,8,9,12)]
SPLICE_ALL_STATE = SPLICE_VALID_REGS + SPLICE_TD2_REGS + SPLICE_TD01_REGS


def splice_body(body):
    """把 golden-copied body 中被可读核接管的 13 个状态元素（3 valid + 10 topdown_stages_2）
    的 golden 驱动（reg 声明→wire、reset、next-state、_RANDOM/reset-init）删除，
    并额外删除仅喂 stage_2 的 topdown stage_0/stage_1 整条流水（避免变 impl-only 死位）。
    reg 声明改为 wire（由 u_core 连接驱动，见 emit_wrapper 的 core 连接）。
    结果与手写 splice 逐字一致（reproducible: 重生成后 git diff 须空）。"""
    lines = body.split("\n")
    out = []
    # 需删除的名字集合（stage_0/1 全删；stage_2/valid: reg->wire + 删 next/reset/init）
    dead = set(SPLICE_ALL_STATE)
    wire_conv = set(SPLICE_VALID_REGS + SPLICE_TD2_REGS)  # reg->wire, 由 u_core 驱动
    del_names = set(SPLICE_TD01_REGS)                     # 整体删除

    # 逐行处理：多行 next-state（以 "<name> <=" 起、可能续行到 ";")需跨行删除。
    i = 0
    def is_decl(line, name):
        return re.match(rf"^\s*reg\s+{re.escape(name)};\s*$", line) is not None
    while i < len(lines):
        ln = lines[i]
        stripped = ln.strip()
        # 1) reg 声明
        m = re.match(r"^\s*reg\s+(\w+);\s*$", ln)
        if m and m.group(1) in dead:
            nm = m.group(1)
            if nm in wire_conv:
                out.append(re.sub(r"^(\s*)reg(\s+)", r"\1wire\2", ln))
            # del_names: 跳过（删声明）
            i += 1
            continue
        # 2) reset ( <name> <= 1'h0; ) 单行
        m = re.match(r"^\s*(\w+)\s*<=\s*1'h0;\s*$", ln)
        if m and m.group(1) in dead:
            i += 1
            continue
        # 3) reset-init / _RANDOM ( <name> = ...; ) 单行(blocking, 在 ifndef SYNTHESIS)
        m = re.match(r"^\s*(\w+)\s*=\s*.*;\s*$", ln)
        if m and m.group(1) in dead:
            i += 1
            continue
        # 4) next-state ( <name> <= ... ) 可能跨多行到 ';'
        m = re.match(r"^\s*(\w+)\s*<=", ln)
        if m and m.group(1) in dead:
            # 吞掉直到本语句以 ';' 结束
            while i < len(lines) and not lines[i].rstrip().endswith(";"):
                i += 1
            i += 1  # 吞掉带 ';' 的末行
            continue
        out.append(ln)
        i += 1
    spliced = "\n".join(out)
    # 5) _GEN_112 = s3_valid_dup_3 | ... 仅被已删的 s3 next-state 使用 → 删该 wire 定义
    spliced = re.sub(r"^\s*wire\s+_GEN_112\s*=[^;]*;\s*\n", "", spliced, flags=re.M)
    return spliced


# 可读核输出 → wrapper 内被驱动的 net 映射（REAL splice：核真驱动 FSM+topdown 输出）。
# 未列出的核输出（resp_valid/s0_fire/s1_fire）由 body 组合式从 core-driven valid wire 再
# 生成（与核内部推导恒等），故悬空不双驱。
CORE_DRIVE = {
    "s1_valid": "s1_valid_dup_3",
    "s2_valid": "s2_valid_dup_3",
    "s3_valid": "s3_valid_dup_3",
    **{f"topdown2_reason_{i}": f"topdown_stages_2_reasons_{i}" for i in (1,2,3,4,5,6,7,8,9,12)},
}


def emit_wrapper(modname, with_dbg_ports):
    L = []
    L.append("// 自动生成：scripts/gen_predictor.py —— 勿手改")
    L.append("// BPU 顶层 wrapper：照搬 golden body 的历史扇出/接线（Composer 黑盒 + 256 位 ghv /")
    L.append("// 折叠历史扇出 + s2/s3 redirect 判定），但 FSM valid + topdown reasons 流水的 golden")
    L.append("// 驱动被删除，改由例化的可读核 xs_Predictor_core **真驱动**（REAL，非影子）：")
    L.append("//   s{1,2,3}_valid_dup_3 + topdown_stages_2_reasons_* ← u_core（reg 转 wire）。")
    L.append("// resp.valid / s0_fire / s1_fire 由 body 组合式从 core-driven valid 再生成；")
    L.append("// topdown 输出级保留 golden 同拍 _GEN_10x 注入。UT 影子探针经 xs_dbg_* 引出。")
    L.append(f"module {modname}(")
    decls = [f"  {d:6s} {width_str(w)}{n}" for d, w, n in PORTS]
    if with_dbg_ports:
        decls += [f"  output {width_str(w)}{n}" for n, w in CORE_DBG_PORTS]
    L.append(",\n".join(decls))
    L.append(");")
    L.append(splice_body(strip_firtool_macros(BODY)).rstrip())
    L.append("")
    L.append("  // ===== 可读核 xs_Predictor_core：真驱动 FSM valid + topdown reasons（REAL）=====")
    conn = [".clock(clock)", ".reset(reset)"]
    for cn, src in CORE_IN:
        conn.append(f".{cn}({src})")
    for n, w in CORE_OUT:
        if n in CORE_DRIVE:
            # 核真驱动的功能 net（同时引到 dbg 口时用中间 net? 直接驱动 body net）
            tgt = CORE_DRIVE[n]
            if with_dbg_ports:
                conn.append(f".{n}(xs_dbg_{n})")   # _xs: 引 dbg 口, 且下面另 assign 驱动 body net
            else:
                conn.append(f".{n}({tgt})")
        else:
            # 组合再生成的核输出（resp_valid/s0_fire/s1_fire）：body 自算, 核输出悬空/仅 dbg
            conn.append(f".{n}(xs_dbg_{n})" if with_dbg_ports else f".{n}(/* body re-derives */)")
    L.append("  xs_Predictor_core u_core (")
    L.append("    " + ",\n    ".join(conn))
    L.append("  );")
    if with_dbg_ports:
        # _xs 变体：核输出既引 dbg 口(供 tb 探针)又驱动 body net(真驱动) → 用 xs_dbg_* 连回
        L.append("  // _xs：核驱动的功能 net 由 dbg 输出回连（tb 探针 + 真驱动同一份值）")
        for n in CORE_DRIVE:
            L.append(f"  assign {CORE_DRIVE[n]} = xs_dbg_{n};")
    L.append("endmodule")
    return "\n".join(L) + "\n"


def emit_tb():
    ins = [(w, n) for d, w, n in PORTS if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in PORTS if d == "output"]
    T = []
    T.append("// 自动生成：scripts/gen_predictor.py —— 勿手改")
    T.append("// Predictor UT：golden Predictor vs 手写 Predictor_xs 双例化（共用同名 golden 子模块），")
    T.append("// 随机 s0 起步 / redirect / update / FTQ resp 握手，逐拍比对全部输出。")
    T.append("// 另：探针比对可读核 xs_Predictor_core 的 FSM/topdown 影子 vs golden 内部寄存器。")
    T.append("`timescale 1ns/1ps")
    T.append("module tb;")
    T.append("  int unsigned NCYCLES = 40000;")
    T.append("  int unsigned WARMUP  = 64;")
    T.append("  bit clk = 0, rst;")
    T.append("  int errors = 0, checks = 0, core_checks = 0, core_errors = 0;")
    T.append("  int cyc = 0;")
    T.append("  always #5 clk = ~clk;")
    for w, n in ins:
        T.append(f"  logic {width_str(w)}{n};")
    for w, n in outs:
        T.append(f"  wire {width_str(w)}g_{n};")
        T.append(f"  wire {width_str(w)}i_{n};")
    for n, w in CORE_DBG_PORTS:
        T.append(f"  wire {width_str(w)}{n};")
    common = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = common + [f".{n}(g_{n})" for _, n in outs]
    ig = common + [f".{n}(i_{n})" for _, n in outs] + [f".{n}({n})" for n, _ in CORE_DBG_PORTS]
    T.append(f"  Predictor    u_g ({', '.join(gg)});")
    T.append(f"  Predictor_xs u_i ({', '.join(ig)});")
    T.append("")

    # 激励：低位压缩 PC 提高命中率；redirect/update 偶发；FTQ resp_ready 随机
    pc_sigs = [n for _, n in ins if re.search(r"(cfiUpdate_pc|update_bits_pc|cfiUpdate_target|full_target)$", n)]
    pulse1of = {  # 信号 -> 1/N 概率为 1
        "io_ftq_to_bpu_redirect_valid": 8,
        "io_ftq_to_bpu_update_valid": 3,
        "io_ftq_to_bpu_redirctFromIFU": 16,
        "io_bpu_to_ftq_resp_ready": 1,   # 多数时间 ready（1/1 即恒为随机，下面特判）
    }
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_ftq_to_bpu_redirect_valid <= 1'b0;")
    T.append("      io_ftq_to_bpu_update_valid   <= 1'b0;")
    T.append("      io_ftq_to_bpu_redirctFromIFU <= 1'b0;")
    T.append("      io_bpu_to_ftq_resp_ready     <= 1'b1;")
    T.append("    end else begin")
    for w, n in ins:
        if n == "io_bpu_to_ftq_resp_ready":
            T.append(f"      {n} <= ($urandom_range(0,3)!=0);")  # ~75% ready
        elif n in pulse1of:
            T.append(f"      {n} <= ($urandom_range(0,{pulse1of[n]-1})==0);")
        elif n == "io_reset_vector":
            T.append(f"      {n} <= {w}'h80000000;")
        elif n in pc_sigs:
            T.append(f"      {n} <= {{{w-13}'($urandom), 12'($urandom_range(0,1023)), 1'b0}};")
        elif n.startswith(("boreChildrenBd", "sigFromSrams")):
            # DFT/SRAM 旁路口：维持 0（黑盒内部不消费其语义；保持两侧一致即可）
            T.append(f"      {n} <= {w}'h0;")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()'] * rep)}}});")
    T.append("    end")
    T.append("  end")
    T.append("")
    T.append("  // ---- 主比对：跳过 golden 为 X 的位（黑盒内层 SRAM 在 +SYNTHESIS 下初值 X）----")
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    cyc++; #4;")
    T.append("    if (cyc > WARMUP) begin")
    T.append("      checks++;")
    for w, n in outs:
        T.append(f"      if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"        if (errors<=40) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("    end")
    T.append("  end")
    T.append("")
    T.append("  // ---- 可读核探针比对：golden 内部寄存器 vs 可读核影子输出 ----")
    probe = [  # (golden 层次信号, 核影子端口)
        ("u_g.s1_valid_dup_3", "s1_valid"),
        ("u_g.s2_valid_dup_3", "s2_valid"),
        ("u_g.s3_valid_dup_3", "s3_valid"),
        ("u_g.io_bpu_to_ftq_resp_valid_0", "resp_valid"),
        ("u_g.s0_fire_dup_0", "s0_fire_0"),
        ("u_g.s0_fire_dup_3", "s0_fire_3"),
        ("u_g.s1_fire_dup_0", "s1_fire_0"),
    ] + [(f"u_g.topdown_stages_2_reasons_{i}", f"topdown2_reason_{i}") for i in (1,2,3,4,5,6,7,8,9,12)]
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4;")
    T.append("    if (cyc > WARMUP) begin")
    for g, x in probe:
        T.append(f"      core_checks++;")
        T.append(f"      if (!$isunknown({g}) && {g} !== xs_dbg_{x}) begin core_errors++;")
        T.append(f"        if (core_errors<=40) $display(\"[%0t] CORE {x} g=%b core=%b\", $time, {g}, xs_dbg_{x}); end")
    T.append("    end")
    T.append("  end")
    T.append("")
    T.append("  initial begin")
    T.append("    rst = 1; repeat (16) @(posedge clk); rst = 0;")
    T.append("    repeat (NCYCLES) @(posedge clk);")
    T.append('    $display("checks=%0d errors=%0d core_checks=%0d core_errors=%0d", checks, errors, core_checks, core_errors);')
    T.append('    if (errors == 0 && core_errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
    T.append("    $finish;")
    T.append("  end")
    T.append("endmodule")
    return "\n".join(T) + "\n"


def main():
    (XSSV / "rtl/frontend/Predictor_wrapper.sv").write_text(emit_wrapper("Predictor", with_dbg_ports=False))
    ut = XSSV / "verif/ut/Predictor"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(emit_wrapper("Predictor_xs", with_dbg_ports=True))
    (ut / "tb.sv").write_text(emit_tb())
    ni = sum(1 for d, _, _ in PORTS if d == "input")
    no = sum(1 for d, _, _ in PORTS if d == "output")
    print(f"Predictor: {ni} inputs, {no} outputs; body {BODY.count(chr(10))} lines; core ins {len(CORE_IN)}, outs {len(CORE_OUT)}")


if __name__ == "__main__":
    main()
