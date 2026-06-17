#!/usr/bin/env python3
"""
BypassNetwork(旁路网络)生成器。

BypassNetwork 位于香山 V2R2 后端「读寄存器(DataPath)」与「执行单元(ExuBlock)」之间,
把各旁路源 EXU 的在飞结果路由给正在准备发射的 uop 源操作数(forward/bypass),省掉
「写回再读回」的往返。旁路匹配早已由 IssueQueue 在唤醒阶段完成,并编码进 DataPath
透传的 dataSources.value(来源种类)与 exuSources.value(旁路源在组内序号)。

可读核 xs_BypassNetwork_core(手写,见 rtl/backend/BypassNetwork.sv)用 enum/struct/
function/genvar 表达旁路数据向量、bypass 寄存、RegCache 回写与来源选择函数 sel_*。

本脚本生成「端口级互联 glue」(可读核通过 `include 引入),以及 wrapper / tb:
  1. bypassnetwork_ports.svh —— 可读核端口表(golden 同名扁平端口,去掉 clock/reset)。
  2. bypassnetwork_body.svh  —— 643 个输出的连接:
       * 71 个源操作数 → 调用 sel_int_src / sel_fp_src / sel_vec_src;
       * valid 前向 / 其余 bits 直通 / ready 反向;
       * toDataPath 7 路接 rc_wen/rc_data;
       * ImmExtractor 黑盒实例(立即数扩展,两侧共享 golden 定义)。
  3. BypassNetwork_wrapper.sv / variants_xs.sv(BypassNetwork_xs)—— golden 同名/镜像
     扁平 wrapper(例化可读核),供 FM 与 UT 双例化。
  4. tb.sv —— 随机激励 + 逐拍比对全部输出。

设计意图来源:src/main/scala/xiangshan/backend/datapath/BypassNetwork.scala。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
GSV = (GOLDEN / "BypassNetwork.sv").read_text()
BK = XSSV / "rtl/backend"
GEN_HDR = "// 自动生成:scripts/gen_bypassnetwork.py —— 勿手改\n"

# DataSource 编码 → 可读 enum 名
DS_NAME = {1: "DS_FORWARD", 2: "DS_BYPASS", 4: "DS_IMM",
           5: "DS_V0", 6: "DS_REGCACHE", 8: "DS_REG", 0: "DS_ZERO"}


# ----------------------------------------------------------------------------
# 顶层端口解析
# ----------------------------------------------------------------------------
def top_ports():
    m = re.search(r"^module BypassNetwork\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def to_dp(name):
    """对应的 fromDataPath 端口名(toExus 直通取这个)。"""
    return name.replace("io_toExus_", "io_fromDataPath_")


# ----------------------------------------------------------------------------
# 解析每个 src 输出的来源元信息(从 golden 体里提取,避免硬编码 27 个 EXU)
# ----------------------------------------------------------------------------
def parse_src_bodies():
    """返回 dict: 输出端口名 -> meta。meta 含:
        group  : 'int' / 'fp' / 'vec'
        exu    : exuSources 序号信号名 (io_fromDataPath_<g>_<i>_<j>_bits_exuSources_<s>_value) 或 None
        ds     : dataSources 信号名
        reg    : 物理寄存器堆读出信号 (即 fromDataPath ..._src_<n>)
        rc     : RegCache 读出信号 或 None
        imm    : ImmExtractor 输出信号 (_imm_mod_*_io_out_imm) 或 None
        v0     : v0 载体表达式(vec 组) 或 None
        width  : 位宽
    """
    metas = {}
    for m in re.finditer(r"assign (io_toExus_\w+_bits_src_(\d)) =\s*(.*?);\n", GSV, re.S):
        name, srcidx, body = m.group(1), int(m.group(2)), m.group(3)
        cases = set(int(c, 16) for c in re.findall(r"dataSources_\d+_value == 4'h(\w)", body))
        ds = None
        dm = re.search(r"(io_fromDataPath_\w+_bits_dataSources_\d+_value)", body)
        if dm:
            ds = dm.group(1)
        # 组别:vf 与 load-vec(mem5/6)是向量域(128bit);fp 看 ext[8];其余 int。
        gm = re.match(r"io_toExus_(\w+?)_(\d+)_(\d+)_bits_src_", name)
        gkind = gm.group(1)
        if gkind == "vf" or (gkind == "mem" and re.search(r"_ext_io_out\[8\]|128'h", body)) or "128'h" in body:
            group = "vec"
        elif re.search(r"_ext(?:_\d+)?_io_out\[8\]", body):
            group = "fp"
        else:
            group = "int"
        # exuSources 序号信号
        exu = None
        if group in ("int", "fp"):
            base = name.replace("io_toExus_", "io_fromDataPath_").split("_bits_")[0]
            exu = f"{base}_bits_exuSources_{srcidx}_value"
        reg = name.replace("io_toExus_", "io_fromDataPath_")  # ..._bits_src_<n>
        rc = None
        rcm = re.search(r"(io_fromDataPath_rcData_\d+_\d+_\d+)", body)
        if rcm:
            rc = rcm.group(1)
        imm = None
        imm_m = re.search(r"(_imm_mod(?:_\d+)?_io_out_imm)", body)
        if imm_m:
            imm = imm_m.group(1)
        width = 128 if group == "vec" else 64
        metas[name] = dict(group=group, exu=exu, ds=ds, reg=reg, rc=rc,
                           imm=imm, body=body, width=width, srcidx=srcidx)
    return metas


# vec 组 v0 载体:就是该 EXU 自己的 src_3 输出(已解析好的 v0 操作数,可能含 reg/imm)。
# src_3 本身由其 dataSources_3 选择(reg / imm),在 body 里单独生成。
def vec_src3_expr(exu_prefix):
    """返回该 EXU 的 src_3 readable 右值:sel_vec_src(ds3, 0, reg_src3, imm_src3)。
    v0 载体即此值。reg 来自 fromDataPath ..._src_3;imm(若该 src_3 支持)从 golden 取。"""
    fp = exu_prefix.replace("io_toExus_", "io_fromDataPath_")
    ds3 = f"{fp}_bits_dataSources_3_value"
    reg3 = f"{fp}_bits_src_3"
    # 该 EXU 的 src_3 输出里是否含 imm(仅 vf_0_1 类)。src_3 可能等于一个中间 wire
    # (如 _..._T_120),需顺着其定义找 imm 模块输出。
    m = re.search(re.escape(exu_prefix) + r"_bits_src_3 =\s*(.*?);\n", GSV, re.S)
    imm3 = "'0"
    if m:
        rhs = m.group(1)
        wm = re.fullmatch(r"\s*(_\w+)\s*", rhs)
        if wm:  # src_3 = 某中间 wire,展开其定义
            dm = re.search(r"assign " + re.escape(wm.group(1)) + r" =\s*(.*?);\n", GSV, re.S)
            if dm:
                rhs = dm.group(1)
        immm = re.search(r"(_imm_mod(?:_\d+)?_io_out_imm)", rhs)
        if immm:
            imm3 = immm.group(1)
    return f"sel_vec_src(data_source_e'({ds3}), '0, {reg3}, {imm3})"


# ----------------------------------------------------------------------------
# 生成 body.svh
# ----------------------------------------------------------------------------
def gen_body(ps):
    metas = parse_src_bodies()
    out_names = [n for d, _, n in ps if d == "output"]
    L = [GEN_HDR,
         "// 由 xs_BypassNetwork_core 通过 `include 引入:643 个输出的端口级互联。",
         "// 源操作数调用核内 sel_* 函数;其余 bits 直通、valid 前向、ready 反向;",
         "// toDataPath 接 RegCache 回写;ImmExtractor(立即数扩展)作黑盒实例化。",
         ""]

    # --- 1) ImmExtractor 黑盒实例(原样保留 golden 连接;立即数扩展为黑盒)---
    # 先声明各 imm 输出中间网(宽度从 golden wire 声明取:_2/57=64bit,_12/37=128bit)。
    L.append("  // ---- 立即数扩展输出网(ImmExtractor 黑盒输出)----")
    imm_wire_w = {}
    for wm in re.finditer(r"wire \[(\d+):0\]\s+(_imm_mod(?:_\d+)?_io_out_imm);", GSV):
        imm_wire_w[wm.group(2)] = int(wm.group(1)) + 1
    for inst_m in re.finditer(r"\.io_out_imm\s*\((_imm_mod(?:_\d+)?_io_out_imm)\)", GSV):
        nm = inst_m.group(1)
        if nm in imm_wire_w:
            w = imm_wire_w[nm]
            L.append(f"  logic [{w-1}:0] {nm};")
    L.append("")
    L.append("  // ---- 立即数扩展(ImmExtractor 黑盒;按 immType 把 imm 扩展到目标位宽)----")
    for m in re.finditer(r"  (ImmExtractor(?:_\d+)?) (imm_mod(?:_\d+)?) \((.*?)\n  \);", GSV, re.S):
        typ, inst, conns = m.group(1), m.group(2), m.group(3)
        conns = re.sub(r"\s+", " ", conns).strip()
        L.append(f"  {typ} {inst} ({conns});")
    L.append("")

    # --- 2) 71 个源操作数 ---
    L.append("  // ---- 源操作数旁路选择(调用核内 sel_*)----")
    for name in out_names:
        if name not in metas:
            continue
        mt = metas[name]
        ds_e = f"data_source_e'({mt['ds']})"
        # 用 always_comb 调用 sel_*(函数内部读模块级 forward/bypass 数组),否则连续
        # 赋值的隐式敏感列表不含函数内非实参读到的信号,数组变化时不重算(见 Alu.sv)。
        if mt["group"] == "int":
            rc = mt["rc"] if mt["rc"] else "'0"
            imm = mt["imm"] if mt["imm"] else "'0"
            # Load EXU 的 src0:无 ImmExtractor,立即数为内联 U 型展开(load_imm_u)。
            if imm == "'0":
                lim = re.search(r"\{\{32\{(io_fromDataPath_immInfo_\d+_imm)\[31\]\}\}", mt["body"])
                if lim:
                    imm = f"load_imm_u({lim.group(1)}[31:0])"
            exu = mt["exu"]
            L.append(f"  always_comb {name} = sel_int_src({ds_e},")
            L.append(f"    pick_int({exu}, int_fwd_bus), pick_int({exu}, int_byp_bus),")
            L.append(f"    {mt['reg']}, {rc}, {imm});")
        elif mt["group"] == "fp":
            exu = mt["exu"]
            L.append(f"  always_comb {name} = sel_fp_src({ds_e},")
            L.append(f"    pick_fp({exu}, fp_fwd_bus), pick_fp({exu}, fp_byp_bus),")
            L.append(f"    {mt['reg']});")
        else:  # vec
            exu_prefix = "io_toExus_" + name.split("io_toExus_")[1].split("_bits_")[0]
            imm = mt["imm"] if mt["imm"] else "'0"
            if name.endswith("_bits_src_3"):
                # src_3 即 v0 载体:由其 dataSources_3 选择 reg/imm。
                L.append(f"  always_comb {name} = {vec_src3_expr(exu_prefix)};")
            else:
                # 仅当该 src 支持 v0(golden 含 4'h5 分支)时,v0 来源 = 本 EXU 已解析的
                # src_3 载体;否则(如 src_4)无 v0 源,传 0。
                has_v0 = "4'h5" in mt["body"]
                v0 = f"{exu_prefix}_bits_src_3" if has_v0 else "'0"
                L.append(f"  always_comb {name} =")
                L.append(f"    sel_vec_src({ds_e}, {v0}, {mt['reg']}, {imm});")
    L.append("")

    # --- 3) toDataPath(RegCache 回写)---
    L.append("  // ---- RegCache 回写(7 路 wen/data,各打一拍)----")
    for i in range(7):
        L.append(f"  assign io_toDataPath_{i}_wen  = rc_wen[{i}];")
        L.append(f"  assign io_toDataPath_{i}_data = rc_data[{i}];")
    L.append("")

    # 输入端口集合(用于判断某 toExus 字段是否真有 fromDataPath 直通源)
    in_names = set(n for d, _, n in ps if d == "input")

    # --- 4a) 分支单元(Brh)专用 imm / nextPcOffset(非直通,需计算)---
    L.append("")
    L.append("  // ---- 分支单元立即数 / nextPcOffset(int_0_1 / 1_1 / 2_1)----")
    brh_done = set()
    for d, w, n in ps:
        if d != "output":
            continue
        m = re.match(r"(io_toExus_int_\d_1)_bits_(imm|nextPcOffset)$", n)
        if not m:
            continue
        base = m.group(1)
        fp = base.replace("io_toExus_", "io_fromDataPath_")
        # 该 imm 直通(int_3_1)还是分支计算?看 golden 右值是否含 ftqOffset。
        gm = re.search(re.escape(n) + r" =\s*(.*?);\n", GSV, re.S)
        if gm and "ftqOffset" not in gm.group(1):
            continue  # 直通,留给 4b 处理
        if m.group(2) == "imm":
            immm = re.search(r"(_imm_mod(?:_\d+)?_io_out_imm)", gm.group(1))
            imm_src = immm.group(1) + "[63:0]" if immm else "'0"
            is_jalr = f"({fp}_bits_fuType[0] & {fp}_bits_fuOpType[0])"
            L.append(f"  assign {n} = brh_imm({imm_src}, {is_jalr}, {fp}_bits_ftqOffset);")
        else:
            L.append(f"  assign {n} = brh_next_pc_off({fp}_bits_ftqOffset, {fp}_bits_preDecode_isRVC);")
        brh_done.add(n)

    # --- 4b) ready 反向 + valid 前向 + 其余 bits 直通 ---
    L.append("")
    L.append("  // ---- ready 反向 / valid 前向 / 其余 bits 直通 ----")
    for d, w, n in ps:
        if d == "output":
            if n.endswith("_ready"):
                # io_fromDataPath_X_ready = io_toExus_X_ready
                src = n.replace("io_fromDataPath_", "io_toExus_")
                L.append(f"  assign {n} = {src};")
            elif n in metas or n.startswith("io_toDataPath") or n in brh_done:
                continue  # 已处理
            else:
                # valid / 其余 bits 直通自 fromDataPath(确认源端口存在)
                src = to_dp(n)
                assert src in in_names, f"no passthrough source for {n} -> {src}"
                L.append(f"  assign {n} = {src};")
    return "\n".join(L) + "\n"


# ----------------------------------------------------------------------------
# ports.svh
# ----------------------------------------------------------------------------
def gen_ports(ps):
    decls = []
    inner = [(d, w, n) for d, w, n in ps if n not in ("clock", "reset")]
    for d, w, n in inner:
        ws = f"[{w-1}:0] " if w > 1 else ""
        # 输出声明为 logic(var),才能在 always_comb 里给源操作数赋值(旁路 mux)。
        ty = "output logic" if d == "output" else "input "
        decls.append(f"  {ty:13s} {ws}{n}")
    (BK / "bypassnetwork_ports.svh").write_text(
        GEN_HDR + "// 可读核 xs_BypassNetwork_core 端口表(golden 同名扁平端口,无 clock/reset)。\n"
        + ",\n".join(decls) + "\n")


# ----------------------------------------------------------------------------
# wrapper / variants / tb
# ----------------------------------------------------------------------------
def emit_wrapper(modname, ps):
    decls = []
    for d, w, n in ps:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    L = [f"module {modname}(", ",\n".join(decls) + "\n);"]
    conns = [f"    .{n}({n})" for _, _, n in ps]
    L.append("  xs_BypassNetwork_core u_core (")
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("endmodule\n")
    return "\n".join(L)


def gen_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["""// 自动生成:scripts/gen_bypassnetwork.py —— 勿手改
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
    T.append(f"  BypassNetwork    u_g ({', '.join(gg)});")
    T.append(f"  BypassNetwork_xs u_i ({', '.join(ig)});")

    def rnd(w, n):
        if n.endswith("_valid") or n.endswith("_ready"):
            return "$urandom_range(0,1)"
        # dataSources.value:多给 forward/bypass/reg 等合法编码,提升旁路覆盖
        if "_dataSources_" in n:
            return "ds_rand()"
        if "_exuSources_" in n:
            return f"{w}'($urandom)"  # 序号全随机(含越界,验证防 X)
        if w == 1:
            return "$urandom_range(0,1)"
        if w <= 32:
            return f"{w}'($urandom)"
        rep = (w + 31) // 32
        return f"{w}'({{{', '.join(['$urandom()'] * rep)}}})"

    reset_valids = [n for _, n in ins if n.endswith("_valid")]
    # dataSources 随机:在 8 种合法来源里挑,覆盖各分支
    T.append("""  function automatic logic [3:0] ds_rand();
    case ($urandom_range(0,6))
      0: ds_rand = 4'h1; 1: ds_rand = 4'h2; 2: ds_rand = 4'h4;
      3: ds_rand = 4'h5; 4: ds_rand = 4'h6; 5: ds_rand = 4'h8;
      default: ds_rand = 4'h0;
    endcase
  endfunction""")
    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    for n in reset_valids:
        T.append(f"      {n} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        T.append(f"      {n} <= {rnd(w, n)};")
    T.append("    end")
    T.append("  end")
    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    ps = top_ports()
    gen_ports(ps)
    (BK / "bypassnetwork_body.svh").write_text(gen_body(ps))
    (BK / "BypassNetwork_wrapper.sv").write_text(GEN_HDR + emit_wrapper("BypassNetwork", ps))
    ut = XSSV / "verif/ut/BypassNetwork"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(GEN_HDR + emit_wrapper("BypassNetwork_xs", ps))
    (ut / "tb.sv").write_text(gen_tb(ps))
    ni = sum(1 for d, _, _ in ps if d == "input")
    no = sum(1 for d, _, _ in ps if d == "output")
    print(f"BypassNetwork: {len(ps)} ports ({ni} in / {no} out)")


if __name__ == "__main__":
    main()
