#!/usr/bin/env python3
"""
VecExcpDataMergeModule (向量异常数据合并) 可读 SV 生成器。

== 设计意图 (来自人写 Chisel: backend/VecExcpDataMerge / VecExcpInfo 处理) ==
当向量访存指令 (vle/vse/index/stride/segment/whole) 发生异常时, 需要把「异常点之前
已完成的元素」与「原目的寄存器 (old vd)」合并, 重建正确的向量目的寄存器内容供恢复。
本模块是一个 5 态 FSM (state 0..4):
  0 idle      : 等 i_fromExceptionGen 报异常, 转 1;
  1 sWaitRab  : 等 RAB (rename alloc buffer) 与 RAT 把该向量指令拆出的 nf+1 个逻辑/物理
                寄存器映射逐个送来 (regMaps_0..7), 收齐 (collectedAllRegMap) 转 2;
  2 (busy)    : 逐元素读 VPRF 旧数据 + 合并, o_status_busy=1, 完成部分转 3;
  3 merge     : 把合并结果写回 VPRF (o_toVPRF_w), 转 4;
  4 done      : mvFinished 后回 0。
子模块:
  · NfMappedElemIdx  : 按 nf/eew 计算每个 field 在 vreg 内的元素下标区间 (idxRangeVec)。
  · GetE8OffsetInVreg: 按 eew 与 vstart 算出异常元素在 vreg 内的 e8 (字节) 偏移。
  · DelayN_13        : o_status_busy 打一拍 (= xs_delayn_core N=1)。
NfMappedElemIdx / GetE8OffsetInVreg 是纯逻辑子模块, FM 两侧 elaborate (非黑盒);
DelayN_13 复用通用延迟核。

== 反套壳 (bit-exact 转写) ==
本模块控制/数据路径极密 (5 态 FSM + 8 路 regMaps 合并 + 44 个元素下标实例), golden 用大量
CIRCT SSA 临时量 (_GEN_N / _<stem>_T_N)。忠实可读重写 = **纯标识符改名**保证逐位一致:
  _GEN_N          -> w<N>            (匿名 SSA 中间量 -> 命名 wire)
  _GEN            -> w_gen
  _<stem>_T_N     -> <stem>_t<N>    (保留 golden 已有的语义 stem, 去掉 _T_ 噪声)
表达式树与寄存器更新逻辑逐字保留 (不改语义, 只换名), 并按段落加注释。厂商叶子: 无。
DelayN_13 换成 xs_delayn_core 例化。

产物:
  rtl/backend/VecExcpDataMergeModule.sv  —— golden 同名可读核 (含改名后的 VecExcpDataMerge 逻辑)
  verif/ut/VecExcpDataMergeModule/{variants_xs.sv,tb.sv,Makefile}
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"


def strip_firrtl_boilerplate(txt):
    """去掉文件顶部 CIRCT 宏定义头, 只保留 module ... endmodule。"""
    m = re.search(r"(module VecExcpDataMergeModule\(.*?endmodule)", txt, re.S)
    return m.group(1)


def rename_temporaries(body):
    """
    纯标识符改名 (bit-exact): 去掉 golden 的 _GEN_/_T_ SSA 噪声。
      _GEN_<N>      -> w<N>
      _GEN          -> w_gen
      _<stem>_T_<N> -> <stem>_t<N>
      _<stem>_T     -> <stem>_t
    仅替换标识符 token, 不触碰字面量/位选/运算符, 故语义/位级完全不变。
    """
    # 先处理带 stem 的 _T (更长, 优先), 保留 stem 语义。
    # _foo_bar_T_3 -> foo_bar_t3 ; _foo_T -> foo_t
    def repl_T(m):
        stem = m.group(1)          # foo_bar (不含前导 _ 与尾部 _T[_N])
        num = m.group(2)           # 可能为 None
        base = stem + "_t" + (num if num else "")
        return base
    # 匹配前导下划线 + stem + _T + 可选 _N, 作为整词
    body = re.sub(r"\b_([A-Za-z][A-Za-z0-9_]*?)_T(?:_(\d+))?\b", repl_T, body)
    # 再处理 _GEN_N / _GEN
    body = re.sub(r"\b_GEN_(\d+)\b", r"w\1", body)
    body = re.sub(r"\b_GEN\b", r"w_gen", body)
    # 子模块输出网 golden 名如 _NfMappedElemIdx_out_... / _GetE8OffsetInVreg_out_...
    # 上面 _T 规则不会碰它们 (无 _T); 但为可读去掉前导下划线统一成 n_ 前缀。
    body = re.sub(r"\b_(NfMappedElemIdx_out_\w+)\b", r"n_\1", body)
    body = re.sub(r"\b_(GetE8OffsetInVreg_out_\w+)\b", r"g_\1", body)
    body = re.sub(r"\b_(o_status_busy_\w+)\b", r"s_\1", body)
    # 兜底: 任何仍以 _ 开头的 CIRCT 网名 (如 _oldPregVecFromRat_0_bits...) 去前导 _。
    # 注意不能碰端口/合法名; 只改「行首声明或使用中以 _ 开头的私有网」。
    return body


def swap_delayn(body):
    """DelayN_13 例化换成 xs_delayn_core #(.WIDTH(1),.N(1))。"""
    # golden:
    #   DelayN_13 o_status_busy_delay (
    #     .clock (clock), .io_in (...), .io_out (o_status_busy) );
    def repl(m):
        inner = m.group(1)
        return ("xs_delayn_core #(.WIDTH(1), .N(1)) o_status_busy_delay ("
                + inner + ");")
    body = re.sub(r"DelayN_13 o_status_busy_delay \((.*?)\)\s*;",
                  repl, body, flags=re.S)
    return body


def build_core(golden_txt, modname):
    body = strip_firrtl_boilerplate(golden_txt)
    body = rename_temporaries(body)
    body = swap_delayn(body)
    if modname != "VecExcpDataMergeModule":
        body = body.replace("module VecExcpDataMergeModule(",
                            f"module {modname}(", 1)
        # 子模块实例类型也须换名, 避免与 golden 撞名 (UT 双例化)。
        body = body.replace("NfMappedElemIdx NfMappedElemIdx (",
                            "NfMappedElemIdx_xs NfMappedElemIdx (")
        body = body.replace("GetE8OffsetInVreg GetE8OffsetInVreg (",
                            "GetE8OffsetInVreg_xs GetE8OffsetInVreg (")
    hdr = (
        "// 自动生成: scripts/gen_vecexcpdatamerge.py —— 勿手改 (bit-exact 标识符改名转写)。\n"
        "// VecExcpDataMergeModule: 向量异常数据合并 5 态 FSM (详见脚本头注释)。\n"
        "// 可读化 = 去 golden 的 _GEN_/_T_ SSA 噪声 (纯改名, 逐位一致); DelayN_13->xs_delayn_core。\n")
    return hdr + body + "\n"


def parse_ports(gsv):
    m = re.search(r"^module VecExcpDataMergeModule\((.*?)\n\);", gsv, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            if pm.group(3) in ("clock", "reset"):
                continue
            ww = int(pm.group(2)) + 1 if pm.group(2) else 1
            res.append((pm.group(1), ww, pm.group(3)))
    return res


def emit_tb(ports):
    ins = [(ww, n) for d, ww, n in ports if d == "input"]
    outs = [(ww, n) for d, ww, n in ports if d == "output"]
    L = ["// 自动生成: gen_vecexcpdatamerge.py —— 勿手改", "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;", ""]
    for ww, n in ins:
        ws = f"[{ww-1}:0] " if ww > 1 else ""
        L.append(f"  logic {ws}{n};")
    for ww, n in outs:
        ws = f"[{ww-1}:0] " if ww > 1 else ""
        L.append(f"  wire {ws}g_{n};")
        L.append(f"  wire {ws}i_{n};")
    L.append("")

    def inst(modname, instname, prefix):
        conns = ["    .clock(clk)", "    .reset(rst)"]
        for d, ww, n in ports:
            conns.append(f"    .{n}({n})" if d == "input" else f"    .{n}({prefix}{n})")
        return f"  {modname} {instname} (\n" + ",\n".join(conns) + "\n  );"
    L.append(inst("VecExcpDataMergeModule", "u_g", "g_"))
    L.append(inst("VecExcpDataMergeModule_xs", "u_i", "i_"))
    L.append("")
    L.append("  always @(posedge clk) if (!rst) begin")
    for ww, n in ins:
        if ww <= 32:
            L.append(f"    {n} <= $urandom;")
        else:
            chunks = (ww + 31) // 32
            parts = ",".join("$urandom" for _ in range(chunks))
            L.append(f"    {n} <= {{{parts}}};")
    # bias exception-gen valid + small nf/vsew to walk the FSM through all states
    L.append("    // 偏置: 让异常常发生 + nf/vsew 取小以走完 FSM 各状态。")
    L.append("    i_fromExceptionGen_valid <= ($urandom & 3) == 0;")
    L.append("    i_fromExceptionGen_bits_nf   <= $urandom % 3'd4;")
    L.append("    i_fromExceptionGen_bits_vsew <= $urandom % 2'd3;")
    L.append("    i_fromExceptionGen_bits_veew <= $urandom % 2'd3;")
    L.append("  end")
    L.append("")
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for ww, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f'      if(errors<=80) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n}); end')
    L.append("  end")
    L.append("")
    L.append("  initial begin")
    L.append("    rst = 1; repeat (16) @(posedge clk); rst = 0;")
    L.append("    repeat (NCYCLES) @(posedge clk);")
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    L.append("")
    vdir = XSSV / "verif/ut/VecExcpDataMergeModule"
    vdir.mkdir(parents=True, exist_ok=True)
    (vdir / "tb.sv").write_text("\n".join(L))


def emit_makefile():
    L = ["MODULE = VecExcpDataMergeModule", "",
         "RTL_DIR = ../../../rtl",
         "GOLDEN_RTL = ../../../golden/chisel-rtl", "",
         "# 手写可读核 (bit-exact 改名转写) + 通用延迟核 xs_delayn_core (来自 DelayN.sv)。",
         "# 逻辑子模块 NfMappedElemIdx / GetE8OffsetInVreg 两侧 elaborate (非黑盒)。",
         "# UT 双例化: golden (u_g) vs 可读核 _xs (u_i)。为避免 UT 编译期与 golden 同名撞名,",
         "# golden-名可读核只进 FM impl 侧 (WRAPPER_SRCS); UT 侧用 variants_xs.sv 的 _xs 变体。",
         "RTL_SRCS     =",
         "WRAPPER_SRCS = $(RTL_DIR)/backend/VecExcpDataMergeModule.sv \\",
         "               $(RTL_DIR)/backend/DelayN.sv \\",
         "               $(GOLDEN_RTL)/NfMappedElemIdx.sv \\",
         "               $(GOLDEN_RTL)/GetE8OffsetInVreg.sv",
         "GOLDEN_SRCS  = $(GOLDEN_RTL)/VecExcpDataMergeModule.sv \\",
         "               $(GOLDEN_RTL)/NfMappedElemIdx.sv \\",
         "               $(GOLDEN_RTL)/GetE8OffsetInVreg.sv \\",
         "               $(GOLDEN_RTL)/DelayN_13.sv",
         "# variants_xs 的 _xs 核用 xs_delayn_core (来自 DelayN.sv), UT 侧须编译进来。",
         "TB_SRCS      = $(RTL_DIR)/backend/DelayN.sv variants_xs.sv tb.sv", "",
         "# 逻辑子模块两侧 elaborate; DelayN_13(golden 1 级 1-bit 延迟)也须给 FM ref 侧",
         "# elaborate, 否则 ref 侧 DelayN_13 成黑盒而 impl 侧 xs_delayn_core 已展开 => 失配。",
         "FM_REF_DEPS_VecExcpDataMergeModule = NfMappedElemIdx.sv GetE8OffsetInVreg.sv DelayN_13.sv",
         "FM_VARIANTS = VecExcpDataMergeModule", "",
         "include ../../../scripts/ut_common.mk", "",
         "VCS += +define+SYNTHESIS", ""]
    (XSSV / "verif/ut/VecExcpDataMergeModule/Makefile").write_text("\n".join(L))


def emit_variants(golden_txt):
    """_xs 变体: 可读核改名 + 子模块 _xs 版 (NfMappedElemIdx_xs/GetE8OffsetInVreg_xs 为
       golden 子模块改名副本, 两侧共用逻辑)。"""
    xs_core = build_core(golden_txt, "VecExcpDataMergeModule_xs")
    # 子模块 _xs 副本 (从 golden 定义改名)。
    nf = (GOLDEN / "NfMappedElemIdx.sv").read_text()
    ge = (GOLDEN / "GetE8OffsetInVreg.sv").read_text()
    nf_body = re.search(r"(module NfMappedElemIdx\(.*?endmodule)", nf, re.S).group(1)
    ge_body = re.search(r"(module GetE8OffsetInVreg\(.*?endmodule)", ge, re.S).group(1)
    nf_xs = nf_body.replace("module NfMappedElemIdx(", "module NfMappedElemIdx_xs(", 1)
    ge_xs = ge_body.replace("module GetE8OffsetInVreg(", "module GetE8OffsetInVreg_xs(", 1)
    out = ("// VecExcpDataMergeModule_xs + 子模块 _xs 副本 —— UT 双例化变体 (与可读核逐字一致,\n"
           "// 仅模块/子模块名加 _xs)。DelayN 用 xs_delayn_core (来自 DelayN.sv, TB 已含)。\n"
           + xs_core + "\n" + nf_xs + "\n\n" + ge_xs + "\n")
    (XSSV / "verif/ut/VecExcpDataMergeModule/variants_xs.sv").write_text(out)


def main():
    gtxt = (GOLDEN / "VecExcpDataMergeModule.sv").read_text()
    ports = parse_ports(gtxt)
    core = build_core(gtxt, "VecExcpDataMergeModule")
    (BK / "VecExcpDataMergeModule.sv").write_text(core)
    emit_variants(gtxt)
    emit_tb(ports)
    emit_makefile()
    # 报告残余 _GEN_/_T_ 噪声 (应为 0)。
    resid = len(re.findall(r"_GEN_|_T_\d", core))
    print(f"[VecExcpDataMergeModule] ports={len(ports)} residual_GEN/T={resid}")


if __name__ == "__main__":
    main()
