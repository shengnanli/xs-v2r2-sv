#!/usr/bin/env python3
"""
gen_ctrlflow_fu.py —— 为后端控制流执行单元 BranchUnit / JumpUnit 生成:
  - rtl/backend/<M>_wrapper.sv   (golden 同名扁平端口 wrapper, 仅 FM/ST 用)
  - verif/ut/<M>/variants_xs.sv  (_xs 镜像, UT 用)
  - verif/ut/<M>/tb.sv           (golden vs 可读核 双例化随机比对)

可读核 xs_<M>_core 端口名与 golden 扁平名(io_*)一一同名(便于 FM 签名比对),
但只声明"本单元真正产生的字段"; 其余 cfiUpdate/折叠历史/afhob 等恒为 golden 常量的
字段, 由 wrapper/_xs 在端口适配层直接置常量(从 golden 的 assign 解析得到)。

设计意图来自 fu/wrapper/{BranchUnit,JumpUnit}.scala; 可读核本体见 rtl/backend/<M>.sv。
本脚本只做机械端口适配 + 随机激励 tb。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"

# 各模块: 可读核名 + "核驱动的输出"集合(其余输出由 wrapper 置 golden 常量)
CONFIG = {
    "BranchUnit": {
        "core": "xs_BranchUnit_core",
        "driven": [
            "io_out_valid",
            "io_out_bits_ctrl_robIdx_flag", "io_out_bits_ctrl_robIdx_value",
            "io_out_bits_ctrl_pdest", "io_out_bits_res_data",
            "io_out_bits_res_redirect_valid",
            "io_out_bits_res_redirect_bits_robIdx_flag",
            "io_out_bits_res_redirect_bits_robIdx_value",
            "io_out_bits_res_redirect_bits_ftqIdx_flag",
            "io_out_bits_res_redirect_bits_ftqIdx_value",
            "io_out_bits_res_redirect_bits_ftqOffset",
            "io_out_bits_res_redirect_bits_cfiUpdate_pc",
            "io_out_bits_res_redirect_bits_cfiUpdate_predTaken",
            "io_out_bits_res_redirect_bits_cfiUpdate_target",
            "io_out_bits_res_redirect_bits_cfiUpdate_taken",
            "io_out_bits_res_redirect_bits_cfiUpdate_isMisPred",
            "io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF",
            "io_out_bits_res_redirect_bits_cfiUpdate_backendIPF",
            "io_out_bits_res_redirect_bits_cfiUpdate_backendIAF",
            "io_out_bits_res_redirect_bits_fullTarget",
            "io_out_bits_perfDebugInfo_enqRsTime",
            "io_out_bits_perfDebugInfo_selectTime",
            "io_out_bits_perfDebugInfo_issueTime",
        ],
    },
    "JumpUnit": {
        "core": "xs_JumpUnit_core",
        "driven": [
            "io_out_valid",
            "io_out_bits_ctrl_robIdx_flag", "io_out_bits_ctrl_robIdx_value",
            "io_out_bits_ctrl_pdest", "io_out_bits_ctrl_rfWen",
            "io_out_bits_res_data",
            "io_out_bits_res_redirect_valid",
            "io_out_bits_res_redirect_bits_robIdx_flag",
            "io_out_bits_res_redirect_bits_robIdx_value",
            "io_out_bits_res_redirect_bits_ftqIdx_flag",
            "io_out_bits_res_redirect_bits_ftqIdx_value",
            "io_out_bits_res_redirect_bits_ftqOffset",
            "io_out_bits_res_redirect_bits_cfiUpdate_pc",
            "io_out_bits_res_redirect_bits_cfiUpdate_predTaken",
            "io_out_bits_res_redirect_bits_cfiUpdate_target",
            "io_out_bits_res_redirect_bits_cfiUpdate_taken",
            "io_out_bits_res_redirect_bits_cfiUpdate_isMisPred",
            "io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF",
            "io_out_bits_res_redirect_bits_cfiUpdate_backendIPF",
            "io_out_bits_res_redirect_bits_cfiUpdate_backendIAF",
            "io_out_bits_res_redirect_bits_fullTarget",
            "io_out_bits_perfDebugInfo_enqRsTime",
            "io_out_bits_perfDebugInfo_selectTime",
            "io_out_bits_perfDebugInfo_issueTime",
        ],
    },
}


def golden_text(name):
    return (GOLDEN / f"{name}.sv").read_text()


def ports(name):
    text = golden_text(name)
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def const_assigns(name):
    """解析 golden 里形如 `assign <port> = N'hX;` 的纯常量输出。"""
    text = golden_text(name)
    out = {}
    for m in re.finditer(r"assign\s+(io_\w+)\s*=\s*(\d+'h[0-9a-fA-F]+);", text):
        out[m.group(1)] = m.group(2)
    return out


def wrapper(modname, core, ps, driven, consts):
    """golden 同名 wrapper: 核驱动信号接核, 常量信号置 golden 常量。"""
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);", ""]

    ins = [n for d, _, n in ps if d == "input"]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    core_outs = [n for _, n in outs if n in driven]

    # 例化可读核: 输入全透传, 输出只接核驱动的那部分
    conns = [f"    .{n}({n})" for n in ins]
    conns += [f"    .{n}({n})" for n in core_outs]
    L.append(f"  {core} u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("")
    L.append("  // —— 本单元不产生的 cfiUpdate/历史/afhob 等字段, 置 golden 常量 ——")
    for w, n in outs:
        if n in driven:
            continue
        if n in consts:
            L.append(f"  assign {n} = {consts[n]};")
        else:
            L.append(f"  assign {n} = '0; // (golden 未显式常量, 默认 0)")
    L.append("endmodule\n")
    return "\n".join(L)


def make_tb(mod, ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]

    T = [f"""// 自动生成：scripts/gen_ctrlflow_fu.py —— 勿手改
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

    gc = [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  {mod}    u_g ({', '.join(gg)});")
    T.append(f"  {mod}_xs u_i ({', '.join(ig)});")

    # ---- 随机激励 ----
    # 控制流 FU 是纯组合逻辑, 无状态; 每拍重新随机所有输入。
    # 关键覆盖: fuOpType 覆盖各分支/跳转编码; src/pc/imm 既给全随机又压窄高位,
    # 提高带符号/无符号比较的边界与目标地址跨 canonical 检查的命中。
    # 地址翻译模式必须 one-hot(满足 CSR 互斥语义), 否则 backendIxF 多模式叠加无意义。
    def rnd(w, n):
        if n.startswith("io_instrAddrTransType_"):
            return None  # one-hot 单独赋值
        if n == "io_in_valid":
            return "$urandom_range(0,1)"
        # fuOpType: 全随机覆盖 9 位编码空间(含非法值, 验证 don't-care 一致性)
        if n == "io_in_bits_ctrl_fuOpType":
            return "9'($urandom)"
        # imm: 64 位全随机(JumpUnit 取低 33 位, BranchUnit 取低 15 位; 高位被核截断)
        if n == "io_in_bits_data_imm":
            return "64'($urandom)"
        # pc: 50 位虚地址, 高位偶尔点亮以测 canonical 边界
        if n == "io_in_bits_data_pc":
            return "{14'($urandom_range(0,3)), 36'($urandom)}"
        # src: 既测全随机, 也测相近值(高位收窄)以触发 eq/lt 边界
        if n in ("io_in_bits_data_src_0", "io_in_bits_data_src_1"):
            return "($urandom_range(0,1) ? 64'({$urandom(),$urandom()}) " \
                   ": {60'h0, 4'($urandom)})"
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()']*rep)}}})"

    in_names = {n for _, n in ins}
    has_trans = any(n.startswith("io_instrAddrTransType_") for _, n in ins)

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    if "io_in_valid" in in_names:
        T.append("      io_in_valid <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        r = rnd(w, n)
        if r is not None:
            T.append(f"      {n} <= {r};")
    if has_trans:
        # one-hot(含全 0=无效): 0..5
        T.append("      begin int tm; tm = $urandom_range(0,5);")
        T.append("        io_instrAddrTransType_bare   <= (tm==1);")
        T.append("        io_instrAddrTransType_sv39   <= (tm==2);")
        T.append("        io_instrAddrTransType_sv39x4 <= (tm==3);")
        T.append("        io_instrAddrTransType_sv48   <= (tm==4);")
        T.append("        io_instrAddrTransType_sv48x4 <= (tm==5); end")
    T.append("    end")
    T.append("  end")

    # 比对: 复位后每拍在时钟稳定区比对所有输出(跳过 golden 为 X 的不可达态)
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", "
                 f"$time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    hdr = "// 自动生成：scripts/gen_ctrlflow_fu.py —— 勿手改\n"
    for mod, cfg in CONFIG.items():
        ps = ports(mod)
        driven = set(cfg["driven"])
        consts = const_assigns(mod)
        core = cfg["core"]

        (XSSV / f"rtl/backend/{mod}_wrapper.sv").write_text(
            hdr + wrapper(mod, core, ps, driven, consts))

        # _xs 镜像与 wrapper 同构, 只是模块名加 _xs
        (XSSV / f"verif/ut/{mod}").mkdir(parents=True, exist_ok=True)
        (XSSV / f"verif/ut/{mod}/variants_xs.sv").write_text(
            hdr + wrapper(f"{mod}_xs", core, ps, driven, consts))

        (XSSV / f"verif/ut/{mod}/tb.sv").write_text(make_tb(mod, ps))

        ins = [n for d, _, n in ps if d == "input"]
        outs = [n for d, _, n in ps if d == "output"]
        print(f"{mod}: {len(ps)} ports, {len(ins)} in, {len(outs)} out, "
              f"{len(driven)} core-driven, {len(outs)-len(driven)} tied-const")


if __name__ == "__main__":
    main()
