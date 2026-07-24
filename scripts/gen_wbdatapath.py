#!/usr/bin/env python3
"""
WbDataPath 生成器(写回数据通路)。

WbDataPath 顶层是一张巨大的"执行结果 → 物理寄存器写回口 + ROB/CtrlBlock 透传"互联网
(golden 2489 端口/21k 行, 其中 toCtrlBlock 的 writeback data/redirect/predecodeInfo/
debugInfo 等 ~1500 端口是纯透传), 内部例化:
  · VldMergeUnit ×2          向量 load 结果按 vl 合并(真逻辑, 两侧共享 golden 文件)
  · RealWBCollideChecker ×5  五个写回域(int/fp/vec/v0/vl)各一写回仲裁器(真逻辑, 共享)
  · DummyDPICWrapper ×26      difftest 探针(纯 sink, 只有输入 0 扇出, FM 两侧对称黑盒)

真正的微架构逻辑(VfExe→Int 打拍活跃锥、写回口格式化)在可读核 xs_WbDataPath_core
(rtl/backend/WbDataPath.sv, 手写; 端口契约被 verif/it/Writeback 与 verif/bt/Backend
复用, 冻结不改)。黑盒例化/accept-cond 喂仲裁器/toCtrlBlock 透传/difftest 接线等机械
互联由本脚本从 golden 变换生成到 wrapper(WbDataPath_wrapper.sv)。

变换策略(从 golden 文本生成 wrapper, 保证接口完整 + 黑盒引脚对齐 + 可读核承载真逻辑):
  1) 去掉 firtool 随机化/SYNTHESIS 宏样板与 assert always 块(仅调试, 不影响输出);
  2) golden 的 VfExe(VfExu_0_1)→Int 打拍是 Scala `RegEnable(整个 writeback bundle)`:
     29 个寄存器(intWrite_REG + intArbiterInputsWire_14_bits_r_*)。本配置只消费其中
     {valid, intWen, pdest, data_1[63:0]} —— 这个**活跃锥**由可读核 vfe2int_* 承载
     (always_ff 同一打拍); 其余字段(data_0/2..5, robIdx, 各域 wen, fflags, debugInfo,
     seqNum 等)在 golden 中 cone-dead 但真实存在于芯片状态, 由本脚本按 golden **同名**
     生成可读镜像打拍块(gen_vfe2int_mirror), 使 FM 按名配对成对称 matched-unread 点
     (vmucp 加强可直接证明恒等)。唯一例外 data_1[127:64]: golden 单个 128b 寄存器的
     高 64 位 dead、低 64 位活(由核 64b vfe2int_reg_data 承载), 镜像会与核寄存器争夺
     配对, 故留作 documented golden-only cone-dead(PASS_DEAD_REF, 64 bit);
  3) toPreg 输出格式化 assign 替换为"核 preg_* 输出 → 顶层 toPreg 端口"接线
     (格式化逻辑 wen=valid&wen 等在核里 genvar 展开);
  4) 例化可读核, 把五个仲裁器的 io_out_* 网接到核输入;
  5) 其余(黑盒例化、accept-cond wire、fromExu_ready、toCtrlBlock 透传、difftest)逐字
     保留 —— golden 接口 2489 端口全部原样出现在 wrapper 头。

DummyDPICWrapper stub(WbDataPath_dpic_stub.sv)由 golden 各变体模块头自动生成(空体),
仅供 UT 双例化链接; FM 两侧都不读 stub → hdlin_unresolved_modules=black_box 对称黑盒。

_xs 镜像(verif/ut/WbDataPath/variants_xs.sv)= wrapper 改名 WbDataPath_xs; tb 双例化逐拍比对。
"""
import re
import sys
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
MODULE = "WbDataPath"
CORE = "xs_WbDataPath_core"

# 各域仲裁器出口数(= 物理寄存器写口数), 与可读核参数一致。
NOUT = {"int": 8, "fp": 6, "vf": 6, "v0": 6, "vl": 4}
ARB = {"int": "intWbArbiter", "fp": "fpWbArbiter", "vf": "vfWbArbiter",
       "v0": "v0WbArbiter", "vl": "vlWbArbiter"}
# 仲裁器出口 bits 里的写使能字段名(int 用 rfWen)
ARB_WEN = {"int": "rfWen", "fp": "fpWen", "vf": "vecWen", "v0": "v0Wen", "vl": "vlWen"}
# 可读核 preg 端口/顶层 toPreg 端口里的写使能字段名(int 用 intWen)
CORE_WEN = {"int": "intWen", "fp": "fpWen", "vf": "vecWen", "v0": "v0Wen", "vl": "vlWen"}

# VfExe→Int 打拍 bundle 的**活跃锥**字段(可读核 vfe2int_* 承载, 镜像块须排除):
#   valid(intWrite_REG) / intWen / pdest / data_1[63:0](核 64b vfe2int_reg_data)。
VFE2INT_LIVE = {"pdest": "vfe2int_reg_pdest", "intWen": "vfe2int_reg_intWen"}
VFE2INT_DATA = "data_1"          # 128b 寄存器, 低 64 活(核), 高 64 documented dead
VFE2INT_SRC = "io_fromVfExu_0_1"  # 打拍源 EXU(本配置唯一 VfExe 写 Int 特例)


def load_golden():
    return (GOLDEN / f"{MODULE}.sv").read_text()


def parse_header(text):
    """提取 module 端口声明块(含括号), 原样保留。"""
    m = re.search(rf"^module {MODULE}\((.*?)\n\);", text, re.S | re.M)
    return m.group(0), m.group(1)


def strip_firtool_macros(text):
    """删掉文件顶端 firtool 宏样板(从开头到 module 之前)。"""
    idx = text.index(f"module {MODULE}(")
    return text[idx:]


def body_after_ports(text):
    m = re.search(rf"^module {MODULE}\(.*?\n\);\n", text, re.S | re.M)
    end = re.search(r"\nendmodule", text)
    return text[m.end():end.start()]


def remove_assert_block(body):
    """删 `ifndef SYNTHESIS ... always(assert) ... `endif(仅调试, 不影响输出)。"""
    return re.sub(r"  `ifndef SYNTHESIS\n    always @\(posedge clock\) begin.*?  `endif // not def SYNTHESIS\n",
                  "", body, flags=re.S)


def remove_randomize_block(body):
    return re.sub(r"  `ifdef ENABLE_INITIAL_REG_\n.*?  `endif // ENABLE_INITIAL_REG_\n",
                  "", body, flags=re.S)


# ---------------------------------------------------------------------------
# VfExe→Int 打拍 bundle: 解析 / 摘除 / 镜像
# ---------------------------------------------------------------------------
_RE_V14_REG = re.compile(
    r"  reg +(?:\[(\d+):0\] *)? *intArbiterInputsWire_14_bits_r_(\w+);\n")
_RE_V14_WIRE = re.compile(
    r"  wire +(?:\[(\d+):0\] *)? *intArbiterInputsWire_14_bits_(\w+) =\s*\n?\s*"
    r"intArbiterInputsWire_14_bits_r_\2;\n")


def parse_vfe2int_fields(body):
    """从 reg 声明解析打拍 bundle 全字段: [(field, width)] 按出现顺序。"""
    return [(m.group(2), int(m.group(1)) + 1 if m.group(1) else 1)
            for m in _RE_V14_REG.finditer(body)]


def remove_regenable_block(body):
    """摘除 golden 的 VfExe→Int RegEnable 打拍(活跃锥移入可读核, 其余字段由镜像块重建):
       1) always 块(以 intWrite_REG <= 开头的唯一功能性 always);
       2) intWrite_REG + 全部 intArbiterInputsWire_14_bits_r_* 寄存器声明;
       3) 中间 wire 定义: 活跃字段改接核输出, dead 字段删除(镜像寄存器无下游读者),
          data_1 删除 wire 定义并把唯一消费点(仲裁器 in_11 data 引脚)改接核输出。"""
    n_always = len(re.findall(r"  always @\(posedge clock\) begin\n    intWrite_REG <=", body))
    assert n_always == 1, f"RegEnable always 块应唯一, 实得 {n_always}"
    body = re.sub(r"  always @\(posedge clock\) begin\n    intWrite_REG <=.*?  end // always @\(posedge\)\n",
                  "", body, flags=re.S)
    body = re.sub(r"  reg +intWrite_REG;\n", "", body)
    body = _RE_V14_REG.sub("", body)

    live_seen = set()

    def wire_sub(m):
        width, field = m.group(1), m.group(2)
        if field in VFE2INT_LIVE:
            live_seen.add(field)
            ws = f"[{width}:0] " if width else ""
            return f"  wire {ws}intArbiterInputsWire_14_bits_{field} = {VFE2INT_LIVE[field]};\n"
        return ""  # dead 字段(含 data_1, 其消费点单独改写): 删 wire 定义

    body = _RE_V14_WIRE.sub(wire_sub, body)
    assert live_seen == set(VFE2INT_LIVE), f"活跃字段 wire 未齐: {live_seen}"

    # data_1 唯一消费点: intWbArbiter .io_in_11_bits_data(...[63:0]) → 核 64b 输出
    tgt = f"intArbiterInputsWire_14_bits_{VFE2INT_DATA}[63:0]"
    assert body.count(tgt) == 1, f"data_1 消费点应唯一, 实得 {body.count(tgt)}"
    body = body.replace(tgt, "vfe2int_reg_data")
    # intWrite_REG 唯一消费点: wire intArbiterInputsWire_14_valid = intWrite_REG;
    assert body.count("intWrite_REG") == 1, "intWrite_REG 消费点应唯一"
    body = body.replace("intWrite_REG", "vfe2int_reg_write")
    return body


def gen_vfe2int_mirror(fields):
    """golden RegEnable 打拍整个 writeback bundle; 活跃锥外的字段本配置 cone-dead 但
       真实存在于芯片状态。按 golden 同名重建打拍寄存器(使 FM 按名配对为对称
       matched-unread 点; 无任何下游读者)。data_1 除外(见文件头注释)。"""
    dead = [(f, w) for f, w in fields if f not in VFE2INT_LIVE and f != VFE2INT_DATA]
    L = ["  // ---- VfExe(VfExu_0_1)→Int 打拍 bundle 的非活跃字段镜像 ----",
         "  // Scala: RegEnable(整个 writeback bundle, fromVfExu(0)(1).valid)。活跃锥",
         "  // {valid,intWen,pdest,data_1[63:0]} 在可读核 vfe2int_*; 其余字段照 golden",
         "  // 同名寄存(本配置无下游读者, FM 对称 matched-unread; data_1[127:64] 为",
         "  // documented golden-only dead, 见 gen_wbdatapath.py 文件头)。"]
    for f, w in dead:
        ws = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  reg  {ws}intArbiterInputsWire_14_bits_r_{f};")
    L.append("  always @(posedge clock) begin")
    L.append(f"    if ({VFE2INT_SRC}_valid) begin")
    for f, _ in dead:
        L.append(f"      intArbiterInputsWire_14_bits_r_{f} <= {VFE2INT_SRC}_bits_{f};")
    L.append("    end")
    L.append("  end")
    return "\n".join(L)


def remove_topreg_assigns(body):
    """删 toPreg 输出格式化 assign(改由核 preg_* 输出接线)。"""
    return re.sub(r"  assign io_to(Int|Fp|Vf|V0|Vl)Preg_[0-9]+_\w+ =[^;]*;\n",
                  "", body)


# 各域物理寄存器号位宽(int/fp 8b, vec 7b, v0 5b); vl 无 pdest/data。
PD_W = {"int": 8, "fp": 8, "vf": 7, "v0": 5}
DAT_W = {"int": 64, "fp": 64, "vf": 128, "v0": 128}


def core_decls():
    """可读核 I/O 网声明(必须在 body 之前, 否则被推断为隐式 1-bit 网)。"""
    L = ["  // ---- 可读核 I/O 网声明(vfe2int 打拍输出 + 各域 preg 格式化输出)----"]
    L.append("  wire vfe2int_reg_write, vfe2int_reg_intWen;")
    L.append("  wire [7:0] vfe2int_reg_pdest;")
    L.append("  wire [63:0] vfe2int_reg_data;")
    for dom in ("int", "fp", "vf", "v0", "vl"):
        n = NOUT[dom]
        L.append(f"  wire [{n-1}:0] {dom}_preg_wen, {dom}_preg_xwen;")
        if dom != "vl":
            L.append(f"  wire [{n-1}:0][{PD_W[dom]-1}:0]  {dom}_preg_addr;")
            L.append(f"  wire [{n-1}:0][{DAT_W[dom]-1}:0] {dom}_preg_data;")
    return "\n".join(L)


def core_inst():
    """生成可读核例化 + 仲裁出口接核入 + 核 preg 出口接顶层 toPreg。"""
    L = []
    L.append(f"  {CORE} u_core (")
    conns = ["    .clock(clock)"]
    # vfe2int 活跃锥输入(VfExu_0_1; data = bits_data_1 低 64 位)
    conns += [
        f"    .vfe2int_in_valid ({VFE2INT_SRC}_valid)",
        f"    .vfe2int_in_intWen({VFE2INT_SRC}_bits_intWen)",
        f"    .vfe2int_in_pdest ({VFE2INT_SRC}_bits_pdest)",
        f"    .vfe2int_in_data  ({VFE2INT_SRC}_bits_{VFE2INT_DATA}[63:0])",
        "    .vfe2int_reg_write (vfe2int_reg_write)",
        "    .vfe2int_reg_intWen(vfe2int_reg_intWen)",
        "    .vfe2int_reg_pdest (vfe2int_reg_pdest)",
        "    .vfe2int_reg_data  (vfe2int_reg_data)",
    ]
    # 仲裁器出口 → 核输入(打包成 packed 数组)
    for dom in ("int", "fp", "vf", "v0", "vl"):
        a = ARB[dom]
        n = NOUT[dom]
        awen = ARB_WEN[dom]
        cwen = CORE_WEN[dom]
        v = "{" + ", ".join(f"_{a}_io_out_{k}_valid" for k in range(n - 1, -1, -1)) + "}"
        w = "{" + ", ".join(f"_{a}_io_out_{k}_bits_{awen}" for k in range(n - 1, -1, -1)) + "}"
        conns.append(f"    .{dom}_arb_valid({v})")
        conns.append(f"    .{dom}_arb_{awen}({w})")
        if dom != "vl":
            p = "{" + ", ".join(f"_{a}_io_out_{k}_bits_pdest" for k in range(n - 1, -1, -1)) + "}"
            d = "{" + ", ".join(f"_{a}_io_out_{k}_bits_data" for k in range(n - 1, -1, -1)) + "}"
            conns.append(f"    .{dom}_arb_pdest({p})")
            conns.append(f"    .{dom}_arb_data({d})")
        conns.append(f"    .{dom}_preg_wen({dom}_preg_wen)")
        conns.append(f"    .{dom}_preg_{cwen}({dom}_preg_xwen)")
        if dom != "vl":
            conns.append(f"    .{dom}_preg_addr({dom}_preg_addr)")
            conns.append(f"    .{dom}_preg_data({dom}_preg_data)")
    L.append(",\n".join(conns))
    L.append("  );")

    L.append("  // ---- 核格式化输出 → 物理寄存器写口 ----")
    tp = {"int": "toIntPreg", "fp": "toFpPreg", "vf": "toVfPreg", "v0": "toV0Preg", "vl": "toVlPreg"}
    for dom in ("int", "fp", "vf", "v0", "vl"):
        wen = CORE_WEN[dom]
        for k in range(NOUT[dom]):
            pre = f"io_{tp[dom]}_{k}"
            L.append(f"  assign {pre}_wen = {dom}_preg_wen[{k}];")
            L.append(f"  assign {pre}_{wen} = {dom}_preg_xwen[{k}];")
            if dom != "vl":
                L.append(f"  assign {pre}_addr = {dom}_preg_addr[{k}];")
                L.append(f"  assign {pre}_data = {dom}_preg_data[{k}];")
            # vl 的 addr/data 在 golden 中悬空(无驱动), 此处同样不接(UT 按 X 跳过)
    return "\n".join(L)


def sanity_check_wrapper(text, fields):
    """生成后自检(fail-closed): 打拍 bundle 变换完备 + 无 golden 侧残留引用。"""
    assert "intWrite_REG" not in text, "intWrite_REG 残留"
    for f, _ in fields:
        n_r = len(re.findall(rf"intArbiterInputsWire_14_bits_r_{f}\b", text))
        n_w = len(re.findall(rf"intArbiterInputsWire_14_bits_{f}\b", text))
        if f in VFE2INT_LIVE:
            # wire 定义 1 处 + 下游消费 ≥1 处(intWen 有 in_11_valid 与 in_11_bits_rfWen 两个)
            assert n_r == 0 and n_w >= 2, f"活跃字段 {f}: r={n_r} w={n_w}(期望 0/≥2)"
        elif f == VFE2INT_DATA:
            assert n_r == 0 and n_w == 0, f"data_1 应全改接核输出: r={n_r} w={n_w}"
        else:
            # 镜像块: reg 声明 + 打拍赋值 = 2 处 _r_; 无 wire/下游读者
            assert n_r == 2 and n_w == 0, f"dead 字段 {f}: r={n_r} w={n_w}(期望 2/0)"
    assert "intArbiterInputsWire_14_valid = vfe2int_reg_write" in text.replace("\n    ", " "), \
        "in_14 valid 未接核 vfe2int_reg_write"


def make_wrapper(modname):
    text = strip_firtool_macros(load_golden())
    hdr_full, _ = parse_header(text)
    body = body_after_ports(text)
    fields = parse_vfe2int_fields(body)
    assert len(fields) == 28, f"打拍 bundle 字段数漂移: {len(fields)}(期望 28), 需复核活跃锥"
    body = remove_assert_block(body)
    body = remove_randomize_block(body)
    body = remove_regenable_block(body)
    body = remove_topreg_assigns(body)

    hdr = hdr_full.replace(f"module {MODULE}(", f"module {modname}(", 1)
    out = (hdr + "\n\n" + core_decls() + "\n\n" + body + "\n"
           + gen_vfe2int_mirror(fields) + "\n" + core_inst() + "\nendmodule\n")
    sanity_check_wrapper(out, fields)
    return out


# ---------------------------------------------------------------------------
# DummyDPICWrapper stub: 从 golden 各变体模块头自动生成空体(仅 UT 链接用)
# ---------------------------------------------------------------------------
def gen_dpic_stub():
    body = body_after_ports(strip_firtool_macros(load_golden()))
    kinds = sorted(set(re.findall(r"^  (DummyDPICWrapper_\d+) ", body, re.M)),
                   key=lambda s: int(s.split("_")[1]))
    assert kinds, "golden 未见 DummyDPICWrapper 例化"
    L = ["""// =============================================================================
// DummyDPICWrapper_* —— difftest 探针空体 stub(由 gen_wbdatapath.py 从 golden 模块头生成)
// -----------------------------------------------------------------------------
// WbDataPath 在 EnableDifftest 时为每个写回出口例化一个 DummyDPICWrapper(内含 DPI-C
// 的 DiffXxxWriteback), 把仲裁器胜出的写回结果送给 difftest 框架做指令级比对。
// 这些实例是**纯 sink**: 只有输入端口, 不驱动 WbDataPath 的任何输出, 对功能行为无影响。
//
// 仅供 UT 双例化链接(golden DUT 与可读 DUT 共用)。FM 两侧都不读本文件 →
// hdlin_unresolved_modules=black_box 使 26 个实例在 ref/impl 对称黑盒、引脚按名配对。
// ============================================================================="""]
    for k in kinds:
        src = (GOLDEN / f"{k}.sv").read_text()
        m = re.search(rf"^module {k}\(.*?\n\);", src, re.S | re.M)
        assert m, f"golden {k}.sv 模块头解析失败"
        L.append("\n" + m.group(0) + "\nendmodule")
    return "\n".join(L) + "\n"


def parse_io():
    """返回 (inputs, outputs): 每项 (width, name); 排除 clock/reset。"""
    _, plist = parse_header(strip_firtool_macros(load_golden()))
    ins, outs = [], []
    for line in plist.splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if not pm:
            continue
        w = int(pm.group(2)) + 1 if pm.group(2) else 1
        n = pm.group(3)
        if n in ("clock", "reset"):
            continue
        (ins if pm.group(1) == "input" else outs).append((w, n))
    return ins, outs


def emit_tb():
    ins, outs = parse_io()
    T = ["""// 自动生成：scripts/gen_wbdatapath.py —— 勿手改
// WbDataPath UT: golden(u_g) vs 可读 wrapper WbDataPath_xs(u_i) 逐拍比对全部输出。
// WbDataPath 含时序(flush + VfExe→Int 打拍)。激励: 每拍随机驱动所有 EXU 的
// valid/wen/pdest/data 及 flush, 复位后在时钟稳定区比对 toPreg/toCtrlBlock/ready
// 全部输出(跳过 golden 为 X 的不可达态, 如悬空的 vlPreg addr/data)。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
"""]
    for w, n in ins:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  logic {ws}{n};")
    for w, n in outs:
        ws = f"[{w-1}:0] " if w > 1 else ""
        T.append(f"  wire {ws}g_{n};")
        T.append(f"  wire {ws}i_{n};")

    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  {MODULE}    u_g ({', '.join(gg)});")
    T.append(f"  {MODULE}_xs u_i ({', '.join(ig)});")

    # 随机激励: valid 常发(覆盖写回), wen 各位独立随机(覆盖多域分流), data/pdest 全随机,
    # robIdx 压小空间提高 flush 命中, flush 偶发(覆盖打拍寄存器在 flush 下行为)。
    def rnd(w, n):
        if n.endswith("_valid"):
            return "($urandom_range(0,3)!=0)"
        if n == "io_flush_valid":
            return "($urandom_range(0,7)==0)"
        if "robIdx_value" in n:
            return f"{w}'($urandom_range(0,15))"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()'] * rep)}}})"

    inames = {n for _, n in ins}
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in ("io_flush_valid",):
        if n in inames:
            T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")

    # 活跃度计数: 统计 golden 端各输出非 0 的拍数, 证明输出被真正激励(非全 0/X 假阳过)。
    T.append(f"  int unsigned act [{len(outs)}];")
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4;")
    for j, (w, n) in enumerate(outs):
        T.append(f"    checks++; if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} != 0) act[{j}]++;")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    begin int unsigned nactive = 0;
      foreach (act[k]) if (act[k] > 0) nactive++;
      $display("checks=%0d errors=%0d active_outputs=%0d/%0d", checks, errors, nactive, $size(act));
    end
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    note = "// 自动生成：scripts/gen_wbdatapath.py —— 勿手改\n"
    (XSSV / f"rtl/backend/{MODULE}_wrapper.sv").write_text(note + make_wrapper(MODULE))
    (XSSV / f"rtl/backend/{MODULE}_dpic_stub.sv").write_text(gen_dpic_stub())
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(note + make_wrapper(f"{MODULE}_xs"))
    (ut / "tb.sv").write_text(emit_tb())
    ins, outs = parse_io()
    print(f"{MODULE}: wrapper + dpic_stub + variants + tb generated "
          f"({len(ins)} in / {len(outs)} out ports)")


if __name__ == "__main__":
    main()
