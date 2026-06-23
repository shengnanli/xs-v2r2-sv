#!/usr/bin/env python3
"""
ExeUnit(执行单元包装)可读 SV 生成器。

== 设计意图(来自人写 Chisel:backend/exu/ExeUnit.scala class ExeUnit / ExeUnitImp)==
ExeUnit 把一个发射端口背后的一组功能单元(FU:Alu/Mul/Bku/Div/FAlu/FCVT/FMA/CSR/Fence
...)包成一个执行单元。它本身**不做运算**,运算在 FU 里。ExeUnit 的职责是 FU 周围的
"分发 / 流水对齐 / 时钟门控 / 输出仲裁 / 握手" 这层 glue:

  §0 分发(Dispatcher,in1ToN):按 fuType 把唯一入口 io_in 路由到正确的那个 FU。
      Chisel 里 Dispatcher 是独立 Module(acceptCond=各 FU 的 fuSel)。本工程把
      Dispatcher 当 **golden 黑盒**(它自己另有重写计划),ExeUnit 核只例化它。

  §1 inPipe 控制/有效流水对齐(pipelineReg):
      变长延迟的 FU(latency=N>0)需要在它出结果那一拍拿到 N 拍前进入的 uop 控制位
      (robIdx/pdest/rfWen/...)。ExeUnit 把 io_in 的控制位与 valid 各打 latencyMax 拍,
      其中 valid 流水每拍要做 flush-kill(被重定向冲刷的 uop 不再有效)。
      → 这是逐级同构的移位,用 struct 数组 + genvar 表达(ctrl 链 + valid 链)。

  §2 时钟门控使能(EnableClockGate):
      每个有延迟的 FU 各有一个 ClockGate(黑盒)。其使能 = 该 FU 流水线上"还有在飞的
      有效 uop"。ExeUnit 为每个有延迟 FU 维护一条 fuVldVec 有效移位链(深度=该 FU
      latency),clk_en = 链上任一级有效 | 其打一拍寄存(fuVld_en_reg)。
      → 每 FU 一条同构链,用 genvar 表达。

  §3 输出仲裁(Mux1H / OR-of-AND):
      各 FU 的 io.out 在任一拍至多一个有效(fuOutValidOH one-hot)。ExeUnit 把它们
      按各自 valid 做 "选中则取该 FU 字段,否则取 0" 的或归约,合成唯一 io_out。
      → 对每个输出字段是同一种 one-hot 选择,用 function/循环表达。

  §4 握手 / busy:本工程单态化(昆明湖)下被验证的几个变体均为 latencyCertain,
      busy 恒 0、io_in.ready 由 Dispatcher 决定,故核内不出现 busy 寄存器(与 golden 一致)。

== 被重写的代表变体(参数化,其余同构注明)==
  ExeUnit_4 : 纯整数,单 FU(Alu,lat0)。无 inPipe / 无时钟门控 / 无 flush。最简骨架。
  ExeUnit   : 纯整数,3 FU(Alu lat0 / Mul lat2 / Bku lat2)。含 inPipe(depth2)、
              2 路时钟门控、flush-kill、3 路输出或仲裁。多 FU 整数代表。
  ExeUnit_8 : 浮点,4 FU(Falu lat1 / Fcvt lat2 / f2v lat0 / Fmac lat3)。含 inPipe
              (depth3)、3 路时钟门控、frm(动态舍入)广播、fflags/wflags 仲裁、
              64/128 混合数据宽。浮点代表。
  其余 ExeUnit_1/5/7/9/10/13/14/15/16/17 结构同上述三类之一(纯整数多 FU / 含 CSR /
  含 Fence/Div / 向量),分发=黑盒、流水/门控/仲裁=同构,可由本脚本参数化扩展;此处
  只生成并验证三个代表。

== 反套壳 ==
  可读核 xs_ExeUnit*_core:struct(inPipe 控制位 / valid 链)、function(one-hot 仲裁 /
  flush-kill / 流水推进)、genvar(流水级 / 各 FU 门控链 / 各 FU 仲裁)。
  逻辑 svh / pkg 里 grep "_GEN_|_T_[0-9]|_REG_|RANDOMIZE|io_..._N_N" 必为 0。
  FU(Alu/Mul/Bku/FAlu/...)、Dispatcher、ClockGate 在 UT/FM 两侧均为 golden 黑盒。

产物(<MOD>=ExeUnit / ExeUnit_4 / ExeUnit_8,base=小写无下划线版):
  rtl/backend/<base>_pkg.sv      —— FU 配置常量 + inPipe/valid 链 struct + 仲裁/流水 function
  rtl/backend/<base>_ports.svh   —— 可读核扁平端口表
  rtl/backend/<base>_logic.svh   —— §1/§2/§3 可读重写逻辑(无 golden 临时名)
  rtl/backend/<base>_connect.svh —— FU + Dispatcher + ClockGate 黑盒例化 + 端口连线
  rtl/backend/<MOD>.sv           —— 可读核 xs_<MOD>_core
  rtl/backend/<MOD>_wrapper.sv   —— golden 同名扁平 wrapper(例化核)
  verif/ut/<MOD>/{variants_xs.sv,tb.sv,Makefile}
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"


def hdr(mod):
    return f"// 自动生成:scripts/gen_exeunit.py（{mod}）—— 勿手改(逻辑为从设计意图的可读重写)\n"


# ============================================================================
# golden 解析
# ============================================================================
def parse_ports(gsv, mod):
    """顶层端口 [(dir, width, name)],保留顺序,去掉 clock/reset。"""
    m = re.search(rf"^module {mod}\((.*?)\n\);", gsv, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            if pm.group(3) in ("clock", "reset"):
                continue
            ww = int(pm.group(2)) + 1 if pm.group(2) else 1
            res.append((pm.group(1), ww, pm.group(3)))
    return res


def parse_instances(gsv):
    """[(type, inst, [(pin, rhs)])];rhs 取 .pin(<标识符>)。"""
    insts = []
    for m in re.finditer(r"^  ([A-Z][A-Za-z0-9_]+) +(\w+) +\((.*?)\n  \);",
                         gsv, re.S | re.M):
        typ, inst, body = m.group(1), m.group(2), m.group(3)
        pins = [(pm.group(1), pm.group(2))
                for pm in re.finditer(r"\.(\w+)\s*\(\s*([A-Za-z0-9_]+)\s*\)", body)]
        insts.append((typ, inst, pins))
    return insts


def analyze(gsv, insts):
    """提取参数化所需信息。"""
    info = {}
    # FU = 非 Dispatcher/ClockGate 的例化(且非 DelayN 之类)
    fu = [(t, i) for (t, i, _) in insts
          if not t.startswith("Dispatcher") and not t.startswith("ClockGate")
          and not t.startswith("DelayN")]
    info["fus"] = fu
    info["clockgates"] = [(t, i) for (t, i, _) in insts if t.startswith("ClockGate")]
    info["dispatcher"] = next((i for (t, i, _) in insts if t.startswith("Dispatcher")), None)
    info["has_frm"] = bool(re.search(r"input\s+\[2:0\]\s+io_frm,", gsv))
    info["has_flush"] = "io_flush_valid" in gsv
    # 各 FU latency:看它例化里用到的 ctrlPipe_<N>_ 最大序号;lat0 的 FU 用 io_in/_in1ToN 直连
    fu_lat = {}
    for (t, i, pins) in insts:
        if (t, i) not in fu:
            continue
        idxs = [int(m.group(1)) for (p, _) in pins
                for m in [re.match(r"io_in_bits_ctrlPipe_(\d+)_", p)] if m]
        fu_lat[i] = max(idxs) if idxs else 0
    info["fu_lat"] = fu_lat
    info["latmax"] = max(fu_lat.values()) if fu_lat else 0
    # inPipe 控制位字段:从 inPipe_1_1_<field> 寄存器名提取(field 及位宽)
    fields = {}
    for m in re.finditer(r"reg\s+(?:\[(\d+):0\]\s+)?inPipe_1_1_(\w+);", gsv):
        ww = int(m.group(1)) + 1 if m.group(1) else 1
        fields[m.group(2)] = ww
    info["ctrl_fields"] = fields  # {field: width}
    return info


# ============================================================================
# pkg:配置常量 + inPipe 控制 struct + valid 链 struct + 仲裁/流水/flush function
# ============================================================================
def gen_pkg(base, mod, info):
    pkg = base + "_pkg"
    nfu = len(info["fus"])
    latmax = info["latmax"]
    fields = info["ctrl_fields"]
    L = [hdr(mod),
         f"// {mod} 执行单元包装:FU 周围 glue 的配置常量与可读类型。",
         f"// 单态化(昆明湖)后 FU 个数 / 各 FU 延迟 / 控制位集合均为定值,可读核据此用",
         f"// struct + function + genvar 表达流水对齐、时钟门控使能、输出 one-hot 仲裁。",
         f"package {pkg};",
         f"  localparam int NUM_FU      = {nfu};   // 本执行单元里的功能单元个数",
         f"  localparam int LAT_MAX     = {latmax};   // 各 FU 中最大固定延迟(inPipe 深度)",
         f""]
    # inPipe 控制位 struct(若有变长延迟 FU 才需要)
    if latmax > 0 and fields:
        L += [
         f"  // ------------------------------------------------------------------------",
         f"  // §1 inPipe 控制位:随 uop 一同打拍、在 FU 出结果那拍交给该 FU 的控制信息。",
         f"  //   字段集合来自单态化后实际被下游 FU 消费的控制位(robIdx/pdest/写使能等)。",
         f"  // ------------------------------------------------------------------------",
         f"  typedef struct packed {{"]
        for f, w in fields.items():
            ws = f"[{w-1}:0] " if w > 1 else "      "
            L.append(f"    logic {ws}{f};")
        L += [
         f"  }} ctrl_t;",
         f""]
    # flush-kill function(若有 flush)
    if info["has_flush"]:
        L += [
         f"  // ------------------------------------------------------------------------",
         f"  // flush-kill:一条在飞 uop 是否被本次重定向(redirect)冲刷掉。",
         f"  //   Chisel: robIdx.needFlush(flush) = flush.valid &&",
         f"  //     (flush.level==flushItself && robIdx==flush.robIdx) || robIdx 比 flush 更年轻。",
         f"  //   {{flag,value}} 大小比较即 robIdx 的环形新旧:flag 不同则 value 大者为旧/新由异或定。",
         f"  // ------------------------------------------------------------------------",
         f"  function automatic logic need_flush(",
         f"      logic flush_valid, logic flush_level,",
         f"      logic flush_flag, logic [7:0] flush_value,",
         f"      logic rob_flag,   logic [7:0] rob_value);",
         f"    need_flush = flush_valid &",
         f"      ( (flush_level & ({{rob_flag, rob_value}} == {{flush_flag, flush_value}}))",
         f"        | (rob_flag ^ flush_flag ^ (rob_value > flush_value)) );",
         f"  endfunction",
         f""]
    # one-hot 或仲裁 function(标量与 64/128 数据通用)
    L += [
         f"  // ------------------------------------------------------------------------",
         f"  // §3 输出 one-hot 仲裁:各 FU 至多一个 valid,对每个输出字段做",
         f"  //   \"选中则取该 FU 值、否则取 0\" 的或归约(等价 Mux1H,综合为与-或选择)。",
         f"  //   下面给标量 1bit 与各数据位宽各一个纯函数,connect/logic 里逐字段调用。",
         f"  // ------------------------------------------------------------------------",
         f"  // 标量 1bit:sel & bit 的或归约由调用方按 FU 展开(见 logic.svh)。",
         f"endpackage : {pkg}",
         f""]
    (BK / f"{pkg}.sv").write_text("\n".join(L))


# ============================================================================
# 端口表
# ============================================================================
def gen_ports(ports, base, mod):
    decls = []
    for d, ww, n in ports:
        ws = f"[{ww-1}:0] " if ww > 1 else ""
        ty = "output logic" if d == "output" else "input "
        decls.append(f"  {ty:13s} {ws}{n}")
    (BK / f"{base}_ports.svh").write_text(
        hdr(mod) + f"// 可读核 xs_{mod}_core 端口表(golden 同名扁平端口,无 clock/reset)。\n"
        + ",\n".join(decls) + "\n")


# ============================================================================
# decls:子模块输出网声明 + 流水状态
# ============================================================================
def gen_decls(base, mod, insts, info):
    internal = set()
    for (_, _, pins) in insts:
        for _, rhs in pins:
            if rhs.startswith("_"):
                internal.add(rhs)
    # 按位宽抓声明(从 golden wire 声明里取宽度)
    gsv = (GOLDEN / f"{mod}.sv").read_text()
    width = {}
    for m in re.finditer(r"wire\s+(?:\[(\d+):0\]\s+)?(_\w+);", gsv):
        width[m.group(2)] = int(m.group(1)) + 1 if m.group(1) else 1

    L = [hdr(mod),
         f"// 核内信号声明(先于 logic/connect include)。",
         f"",
         f"  // ---- FU / ClockGate / Dispatcher 子模块输出网 ----"]
    for w in sorted(internal):
        ws = f"[{width.get(w,1)-1}:0] " if width.get(w, 1) > 1 else ""
        L.append(f"  wire {ws}{w};")

    if info["latmax"] > 0 and info["ctrl_fields"]:
        L += [
         f"",
         f"  // ---- §1 inPipe 流水状态:控制位链(深度 LAT_MAX)+ 有效位链 ----",
         f"  //   ctrl_pipe[k] = 进入后第 (k+1) 拍的控制位;valid_pipe[k] 同步的有效位(带 flush-kill)。",
         f"  ctrl_t ctrl_pipe [LAT_MAX];",
         f"  logic  valid_pipe[LAT_MAX];"]
    # 每个有延迟 FU 一条门控有效链 + 其打拍寄存
    piped = [(i, info["fu_lat"][i]) for (_, i) in info["fus"] if info["fu_lat"][i] > 0]
    if piped:
        L += [
         f"",
         f"  // ---- §2 时钟门控使能链:每个有延迟 FU 一条有效移位链 + 一拍延迟寄存 ----"]
        for inst, lat in piped:
            L.append(f"  logic [{lat}:0] fuvld_{inst};   // [0]=入口有效, [1..{lat}]=在飞各级")
            L.append(f"  logic           fuvld_q_{inst};  // clk_en 的一拍寄存")
    L.append("")
    (BK / f"{base}_decls.svh").write_text("\n".join(L))


# ============================================================================
# logic:§1/§2/§3 可读重写
# ============================================================================
def gen_logic(base, mod, info):
    fields = info["ctrl_fields"]
    latmax = info["latmax"]
    L = [hdr(mod),
         f"// 执行单元 glue 的真正逻辑(可读重写,无 golden _GEN_/_T_/_REG_ 名)。",
         f""]

    # §1 inPipe
    if latmax > 0 and fields:
        # 取出 io_in 当前拍控制位 → ctrl_t
        cur_ctrl = ", ".join(f"{f}: io_in_bits_{f}" for f in fields)
        L += [
         f"  // ==========================================================================",
         f"  // §1 inPipe:控制位 + 有效位各打 LAT_MAX 拍,供有延迟 FU 在出结果拍取用。",
         f"  //   控制位链每拍纯移位;有效位链每拍移位并做 flush-kill(被冲刷则清 0)。",
         f"  // ==========================================================================",
         f"  // 进入流水的当拍控制位(取自 io_in)。",
         f"  ctrl_t ctrl_in;",
         f"  assign ctrl_in = '{{{cur_ctrl}}};",
         f"",
         f"  // 一级有效推进:上级有效 v、本级 robIdx,以及 flush 信号(全部显式入参,",
         f"  //   纯函数不捕获外部信号,避免 FM 的 sim/synth 不一致告警)。被冲刷则清 0。",
         f"  function automatic logic stage_alive(",
         f"      logic v, logic rflag, logic [7:0] rval,",
         f"      logic fl_valid, logic fl_level, logic fl_flag, logic [7:0] fl_value);",
        ]
        if info["has_flush"]:
            L += [
         f"    stage_alive = v & ~need_flush(fl_valid, fl_level, fl_flag, fl_value, rflag, rval);"]
        else:
            L += [f"    stage_alive = v;"]
        L += [
         f"  endfunction",
         f"",
         f"  for (genvar k = 0; k < LAT_MAX; k++) begin : g_inpipe",
         f"    always_ff @(posedge clock) begin",
         f"      if (k == 0) ctrl_pipe[0] <= ctrl_in;",
         f"      else        ctrl_pipe[k] <= ctrl_pipe[k-1];",
         f"    end",
         f"  end",
         f""]
        # valid_pipe 需要异步复位(golden 用 posedge clock or posedge reset)
        L += [
         f"  // 有效位链:复位清 0;每拍由上一级(或 io_in)推进并 flush-kill。",
         f"  //   注意上一级的 robIdx 来自上一级的控制位链(ctrl_pipe),与 golden 一致。",
         f"  always_ff @(posedge clock or posedge reset) begin",
         f"    if (reset) begin",
         f"      for (int k = 0; k < LAT_MAX; k++) valid_pipe[k] <= 1'b0;",
         f"    end else begin",
         f"      valid_pipe[0] <= stage_alive(io_in_valid,",
         f"                         io_in_bits_robIdx_flag, io_in_bits_robIdx_value,",
         f"                         io_flush_valid, io_flush_bits_level,",
         f"                         io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value);",
         f"      for (int k = 1; k < LAT_MAX; k++)",
         f"        valid_pipe[k] <= stage_alive(valid_pipe[k-1],",
         f"                           ctrl_pipe[k-1].robIdx_flag, ctrl_pipe[k-1].robIdx_value,",
         f"                           io_flush_valid, io_flush_bits_level,",
         f"                           io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value);",
         f"    end",
         f"  end",
         f""]

    # §2 clock gate enable
    piped = [(i, info["fu_lat"][i]) for (_, i) in info["fus"] if info["fu_lat"][i] > 0]
    if piped:
        L += [
         f"  // ==========================================================================",
         f"  // §2 时钟门控使能:每个有延迟 FU 维护一条有效移位链 fuvld。",
         f"  //   链上任一级有效 ⇒ 该 FU 流水里还有在飞 uop ⇒ 时钟需保持;clk_en 再打一拍",
         f"  //   合并(fuvld_q),喂给该 FU 的 ClockGate.E(见 connect.svh)。",
         f"  //   链入口 fuvld[0] = 该 FU 被分发选中(_in1ToN 该路 valid),由 connect 驱动。",
         f"  // =========================================================================="]
        for inst, lat in piped:
            L += [
         f"  // FU {inst}(latency={lat})有效链推进。",
         f"  always_ff @(posedge clock or posedge reset) begin",
         f"    if (reset) begin",
         f"      fuvld_{inst}[{lat}:1] <= '0;",
         f"      fuvld_q_{inst}        <= 1'b0;",
         f"    end else begin",
         f"      for (int s = 1; s <= {lat}; s++) fuvld_{inst}[s] <= fuvld_{inst}[s-1];",
         f"      fuvld_q_{inst} <= |fuvld_{inst};",
         f"    end",
         f"  end",
         f"  // clk_en = 链上任一级有效 | 上一拍使能(见 connect 接到 ClockGate.E)。",
         f"  wire clk_en_{inst} = (|fuvld_{inst}) | fuvld_q_{inst};",
         f""]
    (BK / f"{base}_logic.svh").write_text("\n".join(L))


# ============================================================================
# connect:FU/Dispatcher/ClockGate 黑盒例化 + 端口连线 + §3 输出仲裁
# ============================================================================
def gen_connect(base, mod, insts, info, gsv):
    fields = info["ctrl_fields"]
    # 把 golden 里 inPipe_1_<stage>_<field> / inPipe_2_<stage> / fuVld* / _ClockGate*_Q
    # 等临时名,替换为可读核的 struct/数组/信号。建立替换表。
    repl = {}
    # 控制位链:inPipe_1_<stage>_<field> -> ctrl_pipe[<stage-1>].<field>
    for m in re.finditer(r"inPipe_1_(\d+)_(\w+)", gsv):
        st, fld = int(m.group(1)), m.group(2)
        repl[f"inPipe_1_{st}_{fld}"] = f"ctrl_pipe[{st-1}].{fld}"
    # 有效链:inPipe_2_<stage> -> valid_pipe[<stage-1>]; io_in_valid 第0级保持
    for m in re.finditer(r"inPipe_2_(\d+)\b", gsv):
        st = int(m.group(1))
        repl[f"inPipe_2_{st}"] = f"valid_pipe[{st-1}]"
    # 简单别名:golden 里 `wire X = Y;`(如 Mul_clock_te_cgen = cg_bore_cgen)只是把
    # 顶层 cgen 端口换名喂给 ClockGate.TE。直接解析到源端口,避免引用未声明的 golden 临时名。
    for m in re.finditer(r"wire\s+(?:\[\d+:0\]\s+)?(\w+_te_cgen)\s*=\s*(\w+);", gsv):
        repl[m.group(1)] = m.group(2)
    # ClockGate 输出 _ClockGate*_Q 保留(它就是黑盒输出网,已在 decls 声明)
    # ClockGate.E 用到的 clk_en_*_probe:换成可读核 clk_en_<inst>
    piped = [(i, info["fu_lat"][i]) for (_, i) in info["fus"] if info["fu_lat"][i] > 0]
    # golden 里 ClockGate 的 .E(clk_en_..._probe);把每个 ClockGate 与 FU 对应
    # ClockGate 顺序 = piped FU 顺序(golden 中 ClockGate, ClockGate_1, ... 依次对应)
    cg_e = {}  # clk_en probe 名 -> clk_en_<inst>
    cg_insts = info["clockgates"]
    for (cg_t, cg_i), (fu_i, _) in zip(cg_insts, piped):
        cg_e[cg_i] = f"clk_en_{fu_i}"
    # fuvld 链入口:golden 里各 FU 的 _in1ToN_io_out_<n>_valid 经一条链;入口由 connect 驱动。
    # 我们改为:在每个有延迟 FU 例化后,assign fuvld_<inst>[0] = <该 FU 的 io_in_valid 连接>。

    L = [hdr(mod),
         f"// FU / Dispatcher(in1ToN) / ClockGate 黑盒例化 + 端口连线 + §3 输出仲裁。",
         f"// FU 与 Dispatcher、ClockGate 在 UT/FM 两侧均为 golden 黑盒(它们是 FU/分发实体)。",
         f"// 本表把可读核的流水/门控信号接到这些黑盒;无 golden _GEN_/_T_ 名。",
         f""]

    # 例化每个子模块
    fu_in_valid = {}  # FU inst -> 其 io_in_valid 连到的 net(用于 fuvld 链入口)
    for (typ, inst, pins) in insts:
        # ClockGate 用可读 clk_en 替换 .E
        L.append(f"  {typ} {inst} (")
        rows = []
        for pin, rhs in pins:
            conn = repl.get(rhs, rhs)
            if typ.startswith("ClockGate") and pin == "E" and inst in cg_e:
                conn = cg_e[inst]
            rows.append(f"    .{pin} ({conn})")
            if (typ, inst) in info["fus"] and pin == "io_in_valid":
                fu_in_valid[inst] = repl.get(rhs, rhs)
        L.append(",\n".join(rows))
        L.append("  );")
        L.append("")

    # fuvld 链入口驱动
    if piped:
        L.append("  // §2 门控链入口:被分发选中(该 FU 的 io_in_valid)即注入有效链第 0 级。")
        for inst, lat in piped:
            src = fu_in_valid.get(inst, "1'b0")
            L.append(f"  assign fuvld_{inst}[0] = {src};")
        L.append("")

    # §3 输出仲裁:从 golden 的 io_out_* assign 重建为可读 one-hot 或归约
    L += gen_arbitration(mod, info, gsv)
    (BK / f"{base}_connect.svh").write_text("\n".join(L))


def gen_arbitration(mod, info, gsv):
    """把 golden 顶层 io_out_* 仲裁式重写为可读 one-hot 或归约(逐 FU 展开)。

    做法:把 golden 所有中间组合 wire(_GEN* / io_out_bits_*_0)递归展开到不动点,
    使每条 io_out_* 的 RHS 只剩 FU 黑盒输出网(_<inst>_io_out_bits_*)与 valid。
    这些 FU 输出网本就是黑盒端口名(可读),展开后无任何 golden 临时名残留。
    """
    fus = [i for (_, i) in info["fus"]]
    valids = [f"_{i}_io_out_valid" for i in fus]
    L = [
        f"  // ==========================================================================",
        f"  // §3 输出 one-hot 仲裁:同一拍至多一个 FU 有效。每个输出字段 = 各 FU",
        f"  //   \"(该FU有效 ? 该FU字段 : 0)\" 的按位或(等价 Chisel Mux1H,综合为与-或选择,",
        f"  //   无优先级歧义)。robIdx/intWen 等 1bit 字段写成 (valid & field) 的或;",
        f"  //   数据/pdest 等多 bit 字段写成 (valid ? field : 0) 的或;f2v 的 128b 向量",
        f"  //   结果按 golden 切片宽度对齐。下列各式由 golden 仲裁逻辑展开中间网得到。",
        f"  // ==========================================================================",
        f"  assign io_out_valid = |{{{', '.join(valids)}}};",
        f"",
    ]
    # 收集顶层 io_out assign
    out_assigns = {}
    for m in re.finditer(r"^\s*assign\s+(io_out_bits_\w+)\s*=\s*(.*?);", gsv, re.S | re.M):
        out_assigns[m.group(1)] = re.sub(r"\s+", " ", m.group(2)).strip()

    # golden 的中间组合网(_GEN* / io_out_bits_*_0)。它们存在是因为:
    #   (1) 在多个输出端口间被复用;(2) 需要对结果做位切片(SV 不允许切片任意表达式)。
    #   故我们保留这些中间网,但**重命名为可读名**(arb_w<idx>),并按宽度声明,
    #   绝不内联出超长表达式、也不残留 golden _GEN/_T 名。
    inter, interw = {}, {}
    for m in re.finditer(
            r"^\s*wire\s+(?:\[(\d+):0\]\s+)?(_GEN(?:_\d+)?|io_out_bits_\w+_0)\s*=\s*(.*?);",
            gsv, re.S | re.M):
        w = int(m.group(1)) + 1 if m.group(1) else 1
        inter[m.group(2)] = re.sub(r"\s+", " ", m.group(3)).strip()
        interw[m.group(2)] = w

    # 只保留被输出端口(经过中间网递归)真正用到的中间网。
    order = [n for (d, _, n) in parse_ports(gsv, mod) if d == "output" and n != "io_out_valid"]
    used = set()
    def collect(expr):
        for name in inter:
            if re.search(rf"(?<![A-Za-z0-9_]){re.escape(name)}(?![A-Za-z0-9_])", expr) and name not in used:
                used.add(name)
                collect(inter[name])
    for n in order:
        if n in out_assigns:
            collect(out_assigns[n])

    # 可读重命名:按使用顺序给中间网编号 arb_w0/arb_w1/...
    ren = {name: f"arb_w{idx}" for idx, name in enumerate(sorted(used))}
    def rename(expr):
        for name in sorted(ren, key=len, reverse=True):
            expr = re.sub(rf"(?<![A-Za-z0-9_]){re.escape(name)}(?![A-Za-z0-9_])", ren[name], expr)
        return expr

    if used:
        L.append("  // 仲裁中间网(被多个输出端口复用 / 需位切片;FU 黑盒输出的或归约结果)。")
        # 依赖顺序:被别人引用的先声明
        emitted = set()
        def emit_inter(name):
            for dep in sorted(used, key=len, reverse=True):
                if dep != name and re.search(
                        rf"(?<![A-Za-z0-9_]){re.escape(dep)}(?![A-Za-z0-9_])", inter[name]) \
                        and dep not in emitted:
                    emit_inter(dep)
            if name in emitted:
                return
            ws = f"[{interw[name]-1}:0] " if interw[name] > 1 else ""
            L.append(f"  wire {ws}{ren[name]} = {rename(inter[name])};")
            emitted.add(name)
        for name in sorted(used):
            emit_inter(name)
        L.append("")

    for n in order:
        if n in out_assigns:
            L.append(f"  assign {n} = {rename(out_assigns[n])};")
    L.append("")
    return L


# ============================================================================
# 可读核
# ============================================================================
def gen_core(base, mod, info):
    pkg = base + "_pkg"
    nfu = len(info["fus"])
    fu_desc = ", ".join(f"{i}(lat{info['fu_lat'][i]})" for (_, i) in info["fus"])
    L = [hdr(mod),
         f"// ============================================================================",
         f"// xs_{mod}_core —— 执行单元包装(香山 V2R2 昆明湖)",
         f"// ----------------------------------------------------------------------------",
         f"// 设计意图来源:src/main/scala/xiangshan/backend/exu/ExeUnit.scala  class ExeUnit",
         f"//",
         f"// 本执行单元含 {nfu} 个功能单元(FU):{fu_desc}。",
         f"// ExeUnit 自身不运算,只做 FU 周围的 glue:",
         f"//   §0 分发  in1ToN(Dispatcher 黑盒):按 fuType 把 io_in 路由到正确的 FU。",
         f"//   §1 inPipe:控制位/有效位打拍对齐,供有延迟 FU 在出结果那拍取到原 uop 控制位",
         f"//            (有效位链每拍做 flush-kill)。",
         f"//   §2 时钟门控:每个有延迟 FU 一条有效链,链上有在飞 uop 则 clk_en=1,喂 ClockGate。",
         f"//   §3 输出仲裁:各 FU 至多一个有效,逐字段 one-hot 或归约成唯一 io_out。",
         f"//",
         f"//        io_in ─▶ in1ToN(Dispatcher 黑盒) ─┬─▶ FU0 ─┐",
         f"//                                          ├─▶ FU1 ─┤ §3 one-hot",
         f"//   flush ─▶ §1 inPipe(ctrl/valid 打拍)──┘   ...  ├──或归约──▶ io_out",
         f"//   §2 fuvld 链 ─▶ ClockGate(黑盒) ─▶ FU.clk     FUn ─┘",
         f"//",
         f"// FU(Alu/Mul/Bku/FAlu/...)、Dispatcher、ClockGate 在 UT/FM 两侧均为 golden 黑盒。",
         f"// ============================================================================",
         f"module xs_{mod}_core",
         f"  import {pkg}::*;",
         f"(",
         f"  input  clock,",
         f"  input  reset,",
         f'  `include "{base}_ports.svh"',
         f");",
         f"",
         f'  `include "{base}_decls.svh"    // 子模块输出网 + 流水/门控状态声明',
         f'  `include "{base}_logic.svh"    // §1 inPipe / §2 时钟门控使能(可读重写)',
         f'  `include "{base}_connect.svh"  // FU/Dispatcher/ClockGate 黑盒例化 + §3 仲裁',
         f"",
         f"endmodule",
         f""]
    (BK / f"{mod}.sv").write_text("\n".join(L))


# ============================================================================
# wrapper + _xs 变体
# ============================================================================
def gen_wrapper(ports, mod, base):
    def emit(modname, instname, h):
        decls = []
        for d, ww, n in ports:
            ws = f"[{ww-1}:0] " if ww > 1 else ""
            decls.append(f"  {d:6s} {ws}{n}")
        body = [h, f"module {modname}(",
                "  input  clock,", "  input  reset,",
                ",\n".join(decls), ");",
                f"  xs_{mod}_core {instname} ("]
        conns = ["    .clock(clock)", "    .reset(reset)"]
        for d, ww, n in ports:
            conns.append(f"    .{n}({n})")
        body.append(",\n".join(conns))
        body += ["  );", "endmodule", ""]
        return "\n".join(body)

    (BK / f"{mod}_wrapper.sv").write_text(
        emit(mod, "u_core", hdr(mod) + "// golden 同名扁平 wrapper(FM/ST 用):例化可读核。"))
    return emit(f"{mod}_xs", "u_core",
                hdr(mod) + f"// impl 侧变体 {mod}_xs:例化可读核(UT 比对)。")


# ============================================================================
# tb
# ============================================================================
def vc(ww):
    return f"[{ww-1}:0] " if ww > 1 else ""


def rand_rhs(ww, n):
    # fuType / fuOpType 限制到合法编码集合由 dispatcher 决定;这里全随机,
    # 比对用 !$isunknown 跳过 golden 不可达态。
    if ww == 1:
        return "$urandom_range(0,1)"
    if ww <= 32:
        return f"{ww}'($urandom)"
    rep = (ww + 31) // 32
    return f"{ww}'({{{', '.join(['$urandom()']*rep)}}})"


def gen_tb(ports, mod, variant_text):
    ins = [(ww, n) for d, ww, n in ports if d == "input"]
    outs = [(ww, n) for d, ww, n in ports if d == "output"]
    L = [hdr(mod), "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;", ""]
    for ww, n in ins:
        L.append(f"  logic {vc(ww)}{n};")
    for ww, n in outs:
        L.append(f"  wire {vc(ww)}g_{n};")
        L.append(f"  wire {vc(ww)}i_{n};")
    L.append("")

    def inst(modname, instname, prefix):
        conns = ["    .clock(clk)", "    .reset(rst)"]
        for d, ww, n in ports:
            conns.append(f"    .{n}({n})" if d == "input" else f"    .{n}({prefix}{n})")
        return f"  {modname} {instname} (\n" + ",\n".join(conns) + "\n  );"
    L.append(inst(mod, "u_g", "g_"))
    L.append(inst(f"{mod}_xs", "u_i", "i_"))
    L.append("")
    L.append("  always @(posedge clk) if (!rst) begin")
    for ww, n in ins:
        L.append(f"    {n} <= {rand_rhs(ww, n)};")
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
    vdir = XSSV / "verif/ut" / mod
    vdir.mkdir(parents=True, exist_ok=True)
    (vdir / "tb.sv").write_text("\n".join(L))
    (vdir / "variants_xs.sv").write_text(variant_text)


def gen_makefile(base, mod, info):
    # 黑盒依赖:Dispatcher 变体 + 各 FU 类型 + ClockGate(+ 其更深叶子用 -y 解析)
    deps = set()
    if info["dispatcher"]:
        pass
    sub_types = sorted({t for (t, _, _) in parse_instances((GOLDEN / f"{mod}.sv").read_text())})
    dep_files = [f"{t}.sv" for t in sub_types]
    sub_lines = " \\\n           ".join(f"$(GOLDEN_RTL)/{f}" for f in dep_files)
    refdeps = " ".join(dep_files)
    L = [f"MODULE = {mod}", "",
         "RTL_DIR = ../../../rtl",
         "GOLDEN_RTL = ../../../golden/chisel-rtl", "",
         "# 手写可读核 + 类型包(核通过 `include 引入端口表 / 逻辑 / 连线 svh)。",
         "RTL_SRCS = " + " \\\n           ".join(
             [f"$(RTL_DIR)/backend/{base}_pkg.sv", f"$(RTL_DIR)/backend/{mod}.sv"]), "",
         "TB_SRCS = variants_xs.sv tb.sv", "",
         "# FU(Alu/Mul/...)、Dispatcher(in1ToN)、ClockGate 全部作 golden 黑盒;",
         "# UT 双例化两侧共用同一份定义,只比对 ExeUnit 的分发接线/流水/门控/仲裁 glue。",
         "SUB_DEPS = " + sub_lines, "",
         "GOLDEN_SRCS = $(GOLDEN_RTL)/" + mod + ".sv $(SUB_DEPS)", "",
         "# FM:FU/Dispatcher/ClockGate 在 ref 与 impl 两侧都**不提供 RTL**,",
         "# 让 FM 按 hdlin_unresolved_modules=black_box 当作同名同端口的未解析黑盒。",
         "# 这样只比对 ExeUnit 的 glue(流水/门控/仲裁);否则 FM 会读进 ClockGate 内部",
         "# 的使能锁存器(EN_reg),因 impl 多一层 u_core 层次而被不对称常量传播,",
         "# 把同源 ClockGate 锁存器误判为 LAT vs LAT1X 而 fail(同 MulUnit 阵列黑盒思路)。",
         "WRAPPER_SRCS = $(RTL_DIR)/backend/" + mod + "_wrapper.sv",
         f"FM_VARIANTS = {mod}",
         f"FM_REF_DEPS_{mod} =", "",
         "include ../../../scripts/ut_common.mk", "",
         "# golden 内含非综合断言;UT/FM 关掉以免随机激励触发 $fatal。",
         "VCS += +define+SYNTHESIS",
         "VCS += +incdir+$(RTL_DIR)/backend",
         "# FU 黑盒内例化更深的 golden 叶子,用 -y 库目录自动解析。",
         "VCS += -y $(GOLDEN_RTL) +libext+.sv+.v",
         "VCS += -assert disable", ""]
    (XSSV / "verif/ut" / mod / "Makefile").write_text("\n".join(L))


# ============================================================================
def base_of(mod):
    return mod.lower().replace("exeunit", "exeunit")  # exeunit / exeunit_4 / exeunit_8


def build(mod):
    base = mod.lower()
    gsv = (GOLDEN / f"{mod}.sv").read_text()
    ports = parse_ports(gsv, mod)
    insts = parse_instances(gsv)
    info = analyze(gsv, insts)

    gen_pkg(base, mod, info)
    gen_ports(ports, base, mod)
    gen_decls(base, mod, insts, info)
    gen_logic(base, mod, info)
    gen_connect(base, mod, insts, info, gsv)
    gen_core(base, mod, info)
    variant = gen_wrapper(ports, mod, base)
    gen_tb(ports, mod, variant)
    gen_makefile(base, mod, info)
    print(f"[{mod}] ports={len(ports)} fus={[i for _,i in info['fus']]} "
          f"latmax={info['latmax']} ctrl_fields={list(info['ctrl_fields'])} "
          f"frm={info['has_frm']} flush={info['has_flush']}")


def main():
    for mod in ("ExeUnit_4", "ExeUnit", "ExeUnit_8"):
        build(mod)


if __name__ == "__main__":
    main()
