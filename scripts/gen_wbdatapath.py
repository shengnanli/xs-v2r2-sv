#!/usr/bin/env python3
"""
WbDataPath 生成器(写回数据通路)。

WbDataPath 顶层是一张巨大的"执行结果 → 物理寄存器写回端口"互联网(1110 端口), 内部例化:
  · VldMergeUnit ×2          向量 load 结果按 vl 合并(黑盒)
  · RealWBCollideChecker ×5  五个写回域(int/fp/vec/v0/vl)各一写回仲裁器(黑盒)
  · DummyDPICWrapper ×26      difftest 探针(纯 sink, 不驱动任何输出端口, 黑盒)

真正的微架构逻辑(accept-cond 写使能分流、VfExe→Int 打拍、fire/ready、写口/ROB 输出格式化)
抽到可读核 xs_WbDataPath_core(rtl/backend/WbDataPath.sv, 手写)。黑盒的例化与机械接线、
accept-cond 喂仲裁器输入引脚、toCtrlBlock 透传、difftest 接线, 保持与 golden 一致, 由本
脚本从 golden 变换生成到 wrapper(WbDataPath_wrapper.sv)。

变换策略(从 golden 文本生成 wrapper, 保证 FM 黑盒引脚对齐 + 可读核承载真逻辑):
  1) 去掉 firtool 随机化/SYNTHESIS 宏样板与 assert always 块(仅调试, 不影响输出);
  2) 把 intWrite_REG + intArbiterInputsWire_14 的 RegEnable always 块及其 reg 声明
     替换为可读核的 vfe2int_reg_* 输出(核里用 always_ff 实现同一打拍);
  3) 把 toPreg 输出格式化 assign 块替换为"核 preg_* 输出 → 顶层 toPreg 端口"接线
     (格式化逻辑 wen=valid&wen 等在核里 genvar 展开);
  4) 例化可读核, 把五个仲裁器的 io_out_* 网接到核输入;
  5) 其余(黑盒例化、accept-cond wire、fromExu_ready、toCtrlBlock、difftest)逐字保留。

_xs 镜像(verif/ut/WbDataPath/variants_xs.sv)= wrapper 改名 WbDataPath_xs; tb 双例化逐拍比对。
"""
import re
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
    """删 `ifndef SYNTHESIS ... always(assert) ... `endif"""
    return re.sub(r"  `ifndef SYNTHESIS\n    always @\(posedge clock\) begin.*?  `endif // not def SYNTHESIS\n",
                  "", body, flags=re.S)


def remove_randomize_block(body):
    return re.sub(r"  `ifdef ENABLE_INITIAL_REG_\n.*?  `endif // ENABLE_INITIAL_REG_\n",
                  "", body, flags=re.S)


def remove_regenable_block(body):
    """删 intWrite_REG 的 RegEnable always 块 + 三个 reg 声明 + intWrite_REG reg 声明。
       (这部分逻辑改由可读核 vfe2int_reg_* 承载。)"""
    body = re.sub(r"  always @\(posedge clock\) begin\n    intWrite_REG <=.*?  end // always @\(posedge\)\n",
                  "", body, flags=re.S)
    for d in (r"  reg          intWrite_REG;\n",
              r"  reg  \[127:0\] intArbiterInputsWire_14_bits_r_data_1;\n",
              r"  reg  \[7:0\]   intArbiterInputsWire_14_bits_r_pdest;\n",
              r"  reg          intArbiterInputsWire_14_bits_r_intWen;\n"):
        body = re.sub(d, "", body)
    return body


def remove_topreg_assigns(body):
    """删 toPreg 输出格式化 assign(改由核 preg_* 输出接线)。"""
    return re.sub(r"  assign io_to(Int|Fp|Vf|V0|Vl)Preg_[0-9]+_\w+ =[^;]*;\n",
                  "", body)


# 各域物理寄存器号位宽(int/fp 8b, vec 7b, v0 5b); vl 无 pdest/data。
PD_W = {"int": 8, "fp": 8, "vf": 7, "v0": 5}
DAT_W = {"int": 64, "fp": 64, "vf": 128, "v0": 128}


def core_decls():
    """可读核所需的内部网声明(必须在 body 之前, 否则被推断为隐式 1-bit 网)。"""
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
    # 核例化
    L.append(f"  {CORE} u_core (")
    conns = ["    .clock(clock)"]
    # vfe2int 输入(VfExu_0_1, data_1[63:0])
    conns += [
        "    .vfe2int_in_valid (io_fromVfExu_0_1_valid)",
        "    .vfe2int_in_intWen(io_fromVfExu_0_1_bits_intWen)",
        "    .vfe2int_in_pdest (io_fromVfExu_0_1_bits_pdest)",
        "    .vfe2int_in_data  (io_fromVfExu_0_1_bits_data_1[63:0])",
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
        # 核 preg 输出
        conns.append(f"    .{dom}_preg_wen({dom}_preg_wen)")
        conns.append(f"    .{dom}_preg_{cwen}({dom}_preg_xwen)")
        if dom != "vl":
            conns.append(f"    .{dom}_preg_addr({dom}_preg_addr)")
            conns.append(f"    .{dom}_preg_data({dom}_preg_data)")
    L.append(",\n".join(conns))
    L.append("  );")

    # 核 preg 输出 → 顶层 toPreg 端口
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
            # vl 的 addr/data 在 golden 中悬空, 此处同样不接(保持高阻/X, UT 跳过)
    return "\n".join(L)


def make_wrapper(modname):
    text = strip_firtool_macros(load_golden())
    hdr_full, _ = parse_header(text)
    body = body_after_ports(text)
    body = remove_assert_block(body)
    body = remove_randomize_block(body)
    body = remove_regenable_block(body)
    body = remove_topreg_assigns(body)
    # intWbArbiter io_in_11 用到 intArbiterInputsWire_14_bits_r_* / intWrite_REG —— 改名到核输出
    body = body.replace("intWrite_REG", "vfe2int_reg_write")
    body = body.replace("intArbiterInputsWire_14_bits_r_intWen", "vfe2int_reg_intWen")
    body = body.replace("intArbiterInputsWire_14_bits_r_pdest", "vfe2int_reg_pdest")
    body = body.replace("intArbiterInputsWire_14_bits_r_data_1[63:0]", "vfe2int_reg_data")

    hdr = hdr_full.replace(f"module {MODULE}(", f"module {modname}(", 1)
    return hdr + "\n\n" + core_decls() + "\n\n" + body + "\n" + core_inst() + "\nendmodule\n"


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
            return "8'($urandom_range(0,15))"
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
    ut = XSSV / f"verif/ut/{MODULE}"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(note + make_wrapper(f"{MODULE}_xs"))
    (ut / "tb.sv").write_text(emit_tb())
    print(f"{MODULE}: wrapper + variants + tb generated")


if __name__ == "__main__":
    main()
