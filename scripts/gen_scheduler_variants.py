#!/usr/bin/env python3
"""
Scheduler 三个变体(Fp / Vf / Mem)可读重写生成器。

设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
        (class Scheduler / SchedulerImpBase / SchedulerArithImp / SchedulerMemImp)
golden:Scheduler_1.sv(Fp)、Scheduler_2.sv(Vf)、Scheduler_3.sv(Mem)

================================ 设计意图 ================================
与 Int 变体(scripts/gen_scheduler_int.py)完全同源:Scheduler 是「发射调度
顶层」,本身几乎不含算法逻辑——真正的乱序调度(条目阵列 / 年龄仲裁 / 唤醒队列
/ FU busy 表)全部封装在 IssueQueue 子模块里。Scheduler 的职责是把若干
IssueQueue 例化在一起并做「互联(glue)」:

  1) 唤醒网络路由:收 dispatch uop / 跨 IQ 唤醒 / 各类写回唤醒,广播给每个 IQ,
     再把每个 IQ 产生的唤醒汇出到 toSchedulers。
  2) 响应路由:把 DataPath 回来的 og0/og1 resp、cancel 等按 IQ 分发回去。
  3) dispatch 派发:fromDispatch 的 uop 直连各 IQ 的 enq;IQ 的 enq.ready 回送。
  4) 发射 perf 统计:enq_fire 个数(popcount)+ 各 IQ full 位,经两级 RegNext 输出。

三变体相对 Int 的差异(本脚本据 golden 实测):
  Fp(Scheduler_1):3 个 FP IssueQueue;结构与 Int 几乎一致;多一条
      io_toDataPathAfterDelay_2_0_valid 的输出扇出(来自第 3 个 IQ 的 deqDelay)。
  Vf(Scheduler_2):3 个 VF IssueQueue;额外有 32 条向量写回唤醒的「pdest 零扩展」
      组合线(wakeupFrom{Vf,V0,Vl}WB[Delayed]_*_bits_pdest = {高位0, 写回addr}),
      把写回寄存器号补齐成 8bit pdest 后喂给 IQ。
  Mem(Scheduler_3):9 个访存 IssueQueue(StaMou×2 / Ldu×3 / VlduVstu* / VlduVstu /
      StdMoud×2)。Mem 专属 glue:
        * Sta 与 Std 共享 dispatch 端口 0..3:Sta 取 valid&~isDropAmocasSta
          (AMO-CAS 丢弃存地址),Std 取原始 valid;故有 4 条 Sta enq.valid 派生线,
          且 io_fromDispatch_uops_{0,2}_ready = Sta.enq0.ready & Std.enq0.ready。
        * 9 条 io_toDataPathAfterDelay_*_0_valid 输出扇出(各 IQ 的 deqDelay)。
        * 同 Vf 的 32 条向量写回 pdest 零扩展线。
      staFeedback / vstuFeedback / fromMem.wakeup 等访存反馈端口本身无顶层逻辑,
      直接连进各 IQ 黑盒(在实例连线表里透传)。

================================ 重写方式 ================================
与 Int 同:可读核(golden 同名顶层 wrapper)+ 机械互联 svh(纯例化+连线)+ 类型包。
  - 可读核:用 genvar/for + function 重写 perf 计数树;dispatch-ready / deqDelay
    扇出 / Sta 派生 valid 等 glue 以可读形式写出;`include 互联 svh 例化各 IQ。
  - 互联 svh:各 IQ 例化 + 端口直连,enq.ready 输出引到内部线供 perf/ready 使用;
    向量写回 pdest 零扩展线、Sta 派生 valid 线在此声明(就近于例化)。无 _GEN_/_T_。
  - 类型包:维度参数 + iq_id_e 枚举 + popcount 函数 + perf 两级流水 struct。

UT/FM:IQ 子模块两侧共享 golden 黑盒闭包(自动按实例递归求出),逐拍比对全部输出。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
GEN = "// 自动生成:scripts/gen_scheduler_variants.py —— 勿手改\n"


# ============================ 变体配置 ============================
# 每个变体:golden 文件名、模块名、pkg/svh 前缀、IQ 列表(模块名,实例名,中文注释)、
# iq 枚举名。其余(perf 结构 / 派生线 / 扇出 / 派发ready)全部从 golden 文本自动提取。
VARIANTS = {
    "fp": {
        "golden": "Scheduler_1.sv", "module": "Scheduler_1",
        "pkg": "scheduler_fp_pkg", "svh": "scheduler_fp_iq_connect.svh",
        "core": "Scheduler_1.sv", "ut": "Scheduler_1",
        "iqs": [
            ("IssueQueueFaluFcvtF2vFmacFdiv", "IssueQueueFaluFcvtF2vFmacFdiv", "FALU/FCVT/F2V/FMAC/FDIV 综合 FP 发射队列"),
            ("IssueQueueFaluFmacFdiv",        "IssueQueueFaluFmacFdiv",        "FALU/FMAC/FDIV 发射队列"),
            ("IssueQueueFaluFmac",            "IssueQueueFaluFmac",            "FALU/FMAC 发射队列"),
        ],
        "enum": [
            ("IQ_FALU_FCVT_F2V_FMAC_FDIV", "综合 FP IQ (enq 0/1, perf full bit0)"),
            ("IQ_FALU_FMAC_FDIV",          "FALU/FMAC/FDIV IQ (enq 2/3, perf full bit1)"),
            ("IQ_FALU_FMAC",               "FALU/FMAC IQ (enq 4/5, perf full bit2)"),
        ],
        "title": "Fp",
    },
    "vf": {
        "golden": "Scheduler_2.sv", "module": "Scheduler_2",
        "pkg": "scheduler_vf_pkg", "svh": "scheduler_vf_iq_connect.svh",
        "core": "Scheduler_2.sv", "ut": "Scheduler_2",
        "iqs": [
            ("IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf",
             "IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf", "综合向量浮点/定点发射队列"),
            ("IssueQueueVfmaVialuFixVfalu", "IssueQueueVfmaVialuFixVfalu", "VFMA/VIALU/VFALU 发射队列"),
            ("IssueQueueVfdivVidiv",        "IssueQueueVfdivVidiv",        "向量除法发射队列"),
        ],
        "enum": [
            ("IQ_VF_COMBO",  "综合 VF IQ (enq 0/1, perf full bit0)"),
            ("IQ_VFMA_VFALU","VFMA/VIALU/VFALU IQ (enq 2/3, perf full bit1)"),
            ("IQ_VF_DIV",    "向量除法 IQ (enq 4/5, perf full bit2)"),
        ],
        "title": "Vf",
    },
    "mem": {
        "golden": "Scheduler_3.sv", "module": "Scheduler_3",
        "pkg": "scheduler_mem_pkg", "svh": "scheduler_mem_iq_connect.svh",
        "core": "Scheduler_3.sv", "ut": "Scheduler_3",
        "iqs": [
            ("IssueQueueStaMou", "IssueQueueStaMou",   "存地址/AMO 发射队列 #0"),
            ("IssueQueueStaMou", "IssueQueueStaMou_1", "存地址/AMO 发射队列 #1"),
            ("IssueQueueLdu",    "IssueQueueLdu",      "Load 发射队列 #0"),
            ("IssueQueueLdu",    "IssueQueueLdu_1",    "Load 发射队列 #1"),
            ("IssueQueueLdu",    "IssueQueueLdu_2",    "Load 发射队列 #2"),
            ("IssueQueueVlduVstuVseglduVsegstu", "IssueQueueVlduVstuVseglduVsegstu", "向量访存(含段)发射队列"),
            ("IssueQueueVlduVstu", "IssueQueueVlduVstu", "向量 Load/Store 发射队列"),
            ("IssueQueueStdMoud", "IssueQueueStdMoud",   "存数据/AMO 发射队列 #0"),
            ("IssueQueueStdMoud", "IssueQueueStdMoud_1", "存数据/AMO 发射队列 #1"),
        ],
        "enum": [
            ("IQ_STA_MOU_0",  "存地址 IQ #0 (perf full bit0)"),
            ("IQ_STA_MOU_1",  "存地址 IQ #1 (perf full bit1)"),
            ("IQ_LDU_0",      "Load IQ #0 (perf full bit2)"),
            ("IQ_LDU_1",      "Load IQ #1 (perf full bit3)"),
            ("IQ_LDU_2",      "Load IQ #2 (perf full bit4)"),
            ("IQ_VLDU_VSTU_SEG", "向量访存(段)IQ (perf full bit5)"),
            ("IQ_VLDU_VSTU",  "向量 Load/Store IQ (perf full bit6)"),
            ("IQ_STD_MOU_0",  "存数据 IQ #0 (perf full bit7)"),
            ("IQ_STD_MOU_1",  "存数据 IQ #1 (perf full bit8)"),
        ],
        "title": "Mem",
        # Ldu 的 load-dependency 寄存器(loadWaitStrict/storeSetHit/waitForRobIdx)在
        # 黑盒 IQ 内部;开 merge-dup 时 FM 在「顶层标量(ref) vs u_core 内(impl)」两侧
        # 做不对称常量传播,把同值寄存器误判 Constant0 vs Constrained0X 而 fail。关掉合并
        # 即干净比对(同 fm_eq.tcl 注释里的 LoadUnit 场景)。Fp/Vf 无此类寄存器,无需关。
        "fm_merge_dup_false": True,
    },
}


# ============================ golden 解析工具 ============================
def gtext(cfg):
    return (GOLDEN / cfg["golden"]).read_text()


def parse_ports(cfg):
    text = gtext(cfg)
    m = re.search(r"^module %s\(\n(.*?)\n\);" % re.escape(cfg["module"]), text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            w = int(pm.group(2)) + 1 if pm.group(2) else 1
            n = pm.group(3)
            if n in ("clock", "reset"):
                continue
            res.append((pm.group(1), w, n))
    return res


def parse_inst_conns(cfg, inst):
    """返回 golden 中某 IQ 实例的 [(iqport, rhs)],含 clock/reset。"""
    txt = gtext(cfg)
    m = re.search(r'^  \w+ %s \(\n(.*?)\n  \);' % re.escape(inst), txt, re.S | re.M)
    body = m.group(1)
    logical = []
    cur = ""
    for ln in body.split('\n'):
        if re.match(r'\s*\.\w', ln):
            if cur:
                logical.append(cur)
            cur = ln.strip()
        else:
            cur += " " + ln.strip()
    if cur:
        logical.append(cur)
    out = []
    for lg in logical:
        cm = re.match(r'\.(\S+)\s*\((.*)\)\s*,?$', lg)
        if cm:
            out.append((cm.group(1), cm.group(2).strip()))
    return out


# golden 把 Sta 的 enq.valid 派生线命名成 _IssueQueueStaMou_io_enq_<p>_valid_T_<n>
# (含 firtool 临时名 _T_),为满足可读闸门改名成语义名 sta_enq_valid_uop<idx>。
# _T_1 → dispatch uop 0/1(StaMou),_T_3 → dispatch uop 2/3(StaMou_1)。
_STA_VALID_RENAME = {
    "_IssueQueueStaMou_io_enq_0_valid_T_1": "sta_enq_valid_uop0",
    "_IssueQueueStaMou_io_enq_1_valid_T_1": "sta_enq_valid_uop1",
    "_IssueQueueStaMou_io_enq_0_valid_T_3": "sta_enq_valid_uop2",
    "_IssueQueueStaMou_io_enq_1_valid_T_3": "sta_enq_valid_uop3",
}


def rename_derived(s):
    for old, new in _STA_VALID_RENAME.items():
        s = s.replace(old, new)
    return s


def parse_derived_wires(cfg):
    """提取顶层「派生组合线」声明(向量写回 pdest 零扩展 + Sta enq.valid 派生),
    返回 [(decl_lhs, rhs_str, range)],纯组合({0,addr} 或 valid&~drop,可读);
    Sta enq.valid 线改成语义名(去掉 firtool 临时 _T_)。"""
    txt = gtext(cfg)
    wires = []
    # wire [7:0] wakeupFrom..._bits_pdest = {N'h0, io_..._addr};
    for m in re.finditer(
        r'^  wire (\[\d+:0\] )?(\w*(?:WB|WBVec)\w*_bits_pdest)\s*=\s*(.*?);\s*$',
        txt, re.M):
        wires.append((m.group(2), m.group(3).strip(), m.group(1) or ""))
    # wire _IssueQueueStaMou_io_enq_X_valid_T_Y = io_..._valid & ~io_..._isDropAmocasSta;
    for m in re.finditer(
        r'^  wire\s+(_IssueQueue\w*_io_enq_\d+_valid_T_\d+)\s*=\s*(.*?);\s*$',
        txt, re.M | re.S):
        rhs = re.sub(r'\s+', ' ', m.group(2).strip())
        wires.append((rename_derived(m.group(1)), rhs, ""))
    return wires


def parse_perf(cfg):
    """从 golden always 块解析 perf 流水的语义,返回:
       enq_fire = [(iq_ready_signal, valid_signal)], 顺序与 lastCycleIqEnqFireVec_* 一致
       iq_full  = [ready_signal,...]  顺序与 lastCycleIqFullVec_* 一致
       cnt_w    = io_perf_0_value_REG 的位宽(popcount 结果宽度)
       full_n   = full 位个数(= IQ 个数)"""
    txt = gtext(cfg)
    fire = []
    i = 0
    while True:
        m = re.search(
            r'lastCycleIqEnqFireVec_%d <=\s*(.*?)\s*;' % i, txt, re.S)
        if not m:
            break
        expr = re.sub(r'\s+', ' ', m.group(1).strip())
        rd, vl = [x.strip() for x in expr.split('&', 1)]
        fire.append((rd, vl))
        i += 1
    full = []
    i = 0
    while True:
        m = re.search(r'lastCycleIqFullVec_%d <=\s*(.*?)\s*;' % i, txt, re.S)
        if not m:
            break
        full.append(re.sub(r'\s+', ' ', m.group(1).strip()))
        i += 1
    cm = re.search(r'reg\s+\[(\d+):0\]\s+io_perf_0_value_REG;', txt)
    cnt_w = int(cm.group(1)) + 1
    pm = re.search(r'io_perf_0_value\s*=\s*\{(\d+)\'h0,', txt)
    pad0 = int(pm.group(1))  # perf_0 高位补 0 位数
    return fire, full, cnt_w, pad0


def parse_dispatch_ready(cfg):
    """返回 [(port_idx, rhs)],rhs 已规整空白。"""
    txt = gtext(cfg)
    out = []
    for m in re.finditer(
        r'assign io_fromDispatch_uops_(\d+)_ready =\s*(.*?);', txt, re.S):
        out.append((int(m.group(1)), re.sub(r'\s+', ' ', m.group(2).strip())))
    return sorted(out)


def parse_todatapath_fanout(cfg):
    """返回 [(port_idx, rhs)] for io_toDataPathAfterDelay_<idx>_0_valid = <wire>;"""
    txt = gtext(cfg)
    out = []
    for m in re.finditer(
        r'assign io_toDataPathAfterDelay_(\d+)_0_valid =\s*(.*?);', txt, re.S):
        out.append((int(m.group(1)), re.sub(r'\s+', ' ', m.group(2).strip())))
    return sorted(out)


def fanout_wire_name(rhs):
    """_IssueQueue<inst>_io_deqDelay_0_valid → <inst>_deqDelay_0_valid(内部线名)。"""
    return re.sub(r'_IssueQueue(\w+)_io_(deqDelay_\d+_valid)', r'IssueQueue\1_\2', rhs.strip())


def deqdelay_fanout_insts(cfg):
    """顶层 deqDelay 扇出涉及的 IQ 实例名集合(去 _io_ 后即内部线前缀=实例名)。"""
    insts = []
    for _, rhs in parse_todatapath_fanout(cfg):
        m = re.match(r'_IssueQueue(\w+)_io_deqDelay_\d+_valid', rhs.strip())
        if m:
            inst = "IssueQueue" + m.group(1)
            if inst not in insts:
                insts.append(inst)
    return insts


def decl(d, w, n, suffix=","):
    rng = f"[{w-1}:0] " if w > 1 else ""
    return f"  {d:<7}{rng}{n}{suffix}\n"


# ============================ 1) 类型包 ============================
def emit_pkg(cfg):
    n_iq = len(cfg["iqs"])
    fire, full, cnt_w, pad0 = parse_perf(cfg)
    n_fire = len(fire)
    enum_w = max(1, (n_iq - 1).bit_length())
    s = [GEN]
    s.append(f"""\
// =============================================================================
// {cfg['pkg']} —— 香山 V2R2 {cfg['title']} Scheduler 可读重写 类型/参数包
// 设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
//        golden:{cfg['golden']}
// =============================================================================
package {cfg['pkg']};

  // ---- 维度参数(本 {cfg['title']} SchdBlock 的实例化结果)----
  localparam int NUM_IQ        = {n_iq};   // 本调度块内发射队列个数
  localparam int NUM_ENQ_FIRE  = {n_fire};   // 参与 perf 统计的 enq 端口数(各 IQ 2 路)
  localparam int PERF_CNT_W    = {cnt_w};   // enq_fire popcount 结果位宽
  localparam int PERF_PORT_W   = 6;   // io_perf_*_value 端口位宽(高位补 0)

  // {n_iq} 个发射队列的身份标识(与 golden 例化顺序一致)。
  typedef enum logic [{enum_w-1}:0] {{
""")
    for k, (name, cmt) in enumerate(cfg["enum"]):
        comma = "," if k < n_iq - 1 else ""
        s.append(f"    {name:<20} = {enum_w}'d{k}{comma}  // {cmt}\n")
    s.append(f"""\
  }} iq_id_e;

  // perf 计数两级流水:firtool 把每个 perf 事件用 RegNext 打两拍再输出。
  // s1 = 对采样值打一拍并求和;s2 = 再打一拍,即对外输出值。
  typedef struct packed {{
    logic [PERF_CNT_W-1:0] enq_fire_cnt;   // 上拍各 enq 端口 fire 个数之和
    logic [NUM_IQ-1:0]     iq_full;        // 各 IQ 上拍 enq0.ready(可收/满)位向量
  }} perf_sample_t;

  // enq_fire 个数的 popcount({n_fire} 位 → {cnt_w} 位结果)。用函数表达计数树,
  // 替代 firtool 展平的 {{1'h0,..}}+{{1'h0,..}} 嵌套加法。
  function automatic logic [PERF_CNT_W-1:0] popcount(input logic [NUM_ENQ_FIRE-1:0] v);
    popcount = '0;
    for (int i = 0; i < NUM_ENQ_FIRE; i++) popcount += PERF_CNT_W'(v[i]);
  endfunction

endpackage
""")
    (BK / f"{cfg['pkg']}.sv").write_text("".join(s))
    print(f"wrote {cfg['pkg']}.sv (NUM_IQ={n_iq} fire={n_fire} cnt_w={cnt_w})")


# ============================ 2) IQ 互联 svh ============================
def emit_iq_connect(cfg):
    s = [GEN]
    s.append(f"""\
// =============================================================================
// {cfg['svh']} —— {cfg['title']} Scheduler 的 {len(cfg['iqs'])} 个 IssueQueue 例化与互联
// (机械连线表:IQ 端口 ↔ 顶层端口 直连;IQ 的 enq.ready 引到内部线供 dispatch-ready
//  与 perf 统计使用。本文件仅含「就近声明的纯组合派生线」(向量写回 pdest 零扩展、
//  Sta enq.valid 的 isDropAmocasSta 门控),其余无任何组合/时序逻辑,无 firtool 临时网名。)
// =============================================================================

""")
    # 派生组合线(向量写回 pdest 零扩展 / Sta enq.valid 门控)
    derived = parse_derived_wires(cfg)
    if derived:
        s.append("  // ---- 派生组合线(纯连线扩展/门控,喂给下方 IQ 例化)----\n")
        for lhs, rhs, rng in derived:
            s.append(f"  wire {rng}{lhs} = {rhs};\n")
        s.append("\n")
    # 内部 enq.ready 线
    s.append("  // ---- 各 IQ 的 enq.ready(回送 dispatch-ready / perf)----\n")
    for _, inst, _ in cfg["iqs"]:
        s.append(f"  logic {inst}_enq_0_ready;\n")
        s.append(f"  logic {inst}_enq_1_ready;\n")
    s.append("\n")
    # 哪些 IQ 的 deqDelay_0_valid 经顶层扇出(golden 把它们引到内部线再扇出到输出端口)。
    fanout_insts = deqdelay_fanout_insts(cfg)
    if fanout_insts:
        s.append("  // ---- 经顶层扇出的 IQ deqDelay_0_valid(核里再扇出到 toDataPathAfterDelay)----\n")
        for inst in fanout_insts:
            s.append(f"  logic {inst}_deqDelay_0_valid;\n")
        s.append("\n")
    for mod, inst, cmt in cfg["iqs"]:
        conns = parse_inst_conns(cfg, inst)
        s.append(f"  // ---- {inst}:{cmt} ----\n")
        s.append(f"  {mod} {inst} (\n")
        lines = []
        for p, r in conns:
            if p == "io_enq_0_ready":
                lines.append(f"    .{p}({inst}_enq_0_ready)")
            elif p == "io_enq_1_ready":
                lines.append(f"    .{p}({inst}_enq_1_ready)")
            elif p == "io_deqDelay_0_valid" and inst in fanout_insts:
                lines.append(f"    .{p}({inst}_deqDelay_0_valid)")
            else:
                lines.append(f"    .{p}({rename_derived(r)})")
        s.append(",\n".join(lines))
        s.append("\n  );\n\n")
    (BK / cfg["svh"]).write_text("".join(s))
    print(f"wrote {cfg['svh']}")


# ============================ 3) 可读核 ============================
def ready_sig(rhs):
    """把 golden 的 _IssueQueue<inst>_io_enq_0_ready 改写成 <inst>_enq_0_ready 内部线名;
    并把 Sta enq.valid 派生线改成语义名(去 firtool 临时名)。"""
    rhs = re.sub(r'_IssueQueue(\w+)_io_(enq_\d+_ready)', r'IssueQueue\1_\2', rhs)
    return rename_derived(rhs)


def emit_core(cfg):
    ports = parse_ports(cfg)
    fire, full, cnt_w, pad0 = parse_perf(cfg)
    n_iq = len(cfg["iqs"])
    dr = parse_dispatch_ready(cfg)
    fanout = parse_todatapath_fanout(cfg)
    s = [GEN]
    s.append(f"""\
// =============================================================================
// {cfg['module']} —— 香山 V2R2 {cfg['title']} Scheduler 可读核(golden 同名顶层)
// 设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
//        golden:{cfg['golden']}
//
// 见 scripts/gen_scheduler_variants.py 头部「设计意图 / 重写方式」。
// 本核做四件可读的事:
//   A) 例化 {n_iq} 个 IssueQueue 并互联(唤醒网络/响应/cancel,机械连线在 .svh);
//   B) dispatch-ready 透传:把各 IQ 的 enq0.ready 回送给 fromDispatch.uops.ready;
//   C) deqDelay 输出扇出:各 IQ 的 deqDelay_0_valid 引到对应 toDataPathAfterDelay;
//   D) 发射 perf 统计:enq_fire popcount + 各 IQ full 位,两级 RegNext 后输出。
// =============================================================================
module {cfg['module']} import {cfg['pkg']}::*; (
  input         clock,
  input         reset,
""")
    for d, w, n in ports:
        s.append(decl(d, w, n))
    s[-1] = s[-1].rstrip(",\n") + "\n"
    s.append(");\n\n")

    # A) IQ 例化
    s.append(f'  // ===== A) 例化 {n_iq} 个 IssueQueue 并互联(唤醒网络/响应/cancel) =====\n')
    s.append(f'  `include "{cfg["svh"]}"\n\n')

    # B) dispatch-ready
    s.append("  // ===== B) dispatch-ready 透传 =====\n")
    s.append("  // 每个 dispatch 入端口的 ready 来自承接它的 IQ 的 enq0.ready。\n")
    if cfg["title"] == "Mem":
        s.append("  // 注:端口 0/2 由 Sta 与 Std 共享(存地址+存数据),须两个 IQ 都能收才 ready。\n")
    for idx, rhs in dr:
        s.append(f"  assign io_fromDispatch_uops_{idx}_ready = {ready_sig(rhs)};\n")
    s.append("\n")

    # C) deqDelay 扇出
    if fanout:
        s.append("  // ===== C) deqDelay 发射有效 输出扇出 =====\n")
        s.append("  // 各 IQ 的 deqDelay_0_valid 在 .svh 里引到内部线,这里扇出到对应输出端口。\n")
        for idx, rhs in fanout:
            wire = re.sub(r'_IssueQueue(\w+)_io_(deqDelay_\d+_valid)', r'IssueQueue\1_\2', rhs)
            s.append(f"  assign io_toDataPathAfterDelay_{idx}_0_valid = {wire};\n")
        s.append("\n")

    # D) perf
    s.append(f"""\
  // ===== D) 发射 perf 统计 =====
  // enq_fire[i] = 第 i 个统计端口本拍 fire(IQ enq.ready & 对应 valid);
  // iq_full[k]  = 第 k 个 IQ 的 enq0.ready(队列是否还能收)。
  logic [NUM_ENQ_FIRE-1:0] enq_fire;
  logic [NUM_IQ-1:0]       iq_full;
""")
    enum_names = [name for name, _ in cfg["enum"]]
    for k, (rd, vl) in enumerate(fire):
        s.append(f"  assign enq_fire[{k}] = {ready_sig(rd)} & {ready_sig(vl)};\n")
    s.append("\n")
    # iq_full 用 iq_id_e 枚举名索引(每个 IQ 对应一位),让枚举成为可读的位定位。
    for k, rd in enumerate(full):
        s.append(f"  assign iq_full[{enum_names[k]}] = {ready_sig(rd)};\n")
    s.append(f"""
  // perf 三级流水(与 firtool 一致):
  //   stage0(last_cycle):先把本拍 enq_fire / iq_full 各打一拍;
  //   stage1(perf_s1)   :对 stage0 的 enq_fire 求 popcount;full 位直接打拍;
  //   stage2(perf_s2)   :再打一拍,作为对外 io_perf 输出。
  // popcount 作用在「已寄存」的 enq_fire 上(故计数比 fire 晚一拍),保留以逐拍等价。
  logic [NUM_ENQ_FIRE-1:0] last_cycle_enq_fire;
  logic [NUM_IQ-1:0]       last_cycle_iq_full;
  perf_sample_t perf_s1, perf_s2;
  always_ff @(posedge clock) begin
    last_cycle_enq_fire  <= enq_fire;
    last_cycle_iq_full   <= iq_full;
    perf_s1.enq_fire_cnt <= popcount(last_cycle_enq_fire);
    perf_s1.iq_full      <= last_cycle_iq_full;
    perf_s2              <= perf_s1;
  end

  // perf 输出:enq_fire_cnt 端口 {6}bit(高位补 {pad0}'h0);各 full 端口 6bit(高位补 5'h0)。
  assign io_perf_0_value = {{{pad0}'h0, perf_s2.enq_fire_cnt}};
""")
    for k in range(n_iq):
        s.append(f"  assign io_perf_{k+1}_value = {{5'h0, perf_s2.iq_full[{enum_names[k]}]}};\n")
    s.append("\nendmodule\n")
    (BK / cfg["core"]).write_text("".join(s))
    print(f"wrote {cfg['core']} (ports={len(ports)} fire={len(fire)} full={len(full)})")


# ============================ 4) UT/FM 配套 ============================
def iq_dep_closure(cfg):
    """递归求 golden 顶层例化的全部子模块文件(IQ 黑盒闭包),作为两侧共享黑盒。"""
    seen = set()
    stack = [cfg["module"]]
    inst_re = re.compile(r'^  ([A-Z][A-Za-z0-9_]+) [A-Za-z0-9_]+ \($', re.M)
    while stack:
        m = stack.pop()
        if m in seen:
            continue
        seen.add(m)
        f = GOLDEN / (m + ".sv")
        if not f.exists():
            continue
        for c in inst_re.findall(f.read_text()):
            if c not in seen:
                stack.append(c)
    seen.discard(cfg["module"])
    return sorted(s + ".sv" for s in seen)


def emit_ut(cfg):
    UT = XSSV / "verif/ut" / cfg["ut"]
    UT.mkdir(parents=True, exist_ok=True)
    # _xs 变体(改名供 tb 与 golden 共存)
    core_txt = (BK / cfg["core"]).read_text()
    xs_txt = core_txt.replace(f"module {cfg['module']} import",
                              f"module {cfg['module']}_xs import")
    (UT / "scheduler_variant_xs.sv").write_text(xs_txt)

    ports = parse_ports(cfg)
    ins = [(w, n) for d, w, n in ports if d == "input"]
    outs = [(w, n) for d, w, n in ports if d == "output"]
    L = ["// 自动生成:scripts/gen_scheduler_variants.py(tb)—— 勿手改\n"]
    L.append("`timescale 1ns/1ps\nmodule tb;\n")
    L.append("  int unsigned NCYCLES = 200000;\n")
    L.append("  bit clk=0, rst; int errors=0, checks=0; bit no_flush;\n")
    L.append("  always #5 clk = ~clk;\n")
    for w, n in ins:
        rng = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  logic {rng}{n};\n")
    for w, n in outs:
        rng = f"[{w-1}:0] " if w > 1 else ""
        L.append(f"  wire {rng}g_{n};\n  wire {rng}i_{n};\n")

    def inst(mod, pfx):
        ss = [f"  {mod} u_{pfx} (\n    .clock(clk), .reset(rst),\n"]
        conn = [f"    .{n}({n})" for w, n in ins]
        conn += [f"    .{n}({pfx}_{n})" for w, n in outs]
        ss.append(",\n".join(conn))
        ss.append("\n  );\n")
        return "".join(ss)
    L.append(inst(cfg["module"], "g"))
    L.append(inst(cfg["module"] + "_xs", "i"))

    L.append("  task drive_rand();\n")
    for w, n in ins:
        L.append(f"    {n} = $urandom;\n")
    L.append("    // 降低各 valid/handshake 密度,覆盖 enq/唤醒/发射/响应/重定向\n")
    for w, n in ins:
        if n.endswith("_valid") and ("Resp" not in n):
            L.append(f"    {n} = ($urandom % 4 == 0);\n")
    for w, n in ins:
        if re.search(r"toDataPathAfterDelay_\d+_\d+_ready$", n):
            L.append(f"    {n} = ($urandom % 8 != 0);\n")
    L.append("    if (no_flush) io_fromCtrlBlock_flush_valid = 1'b0;\n")
    L.append("    else io_fromCtrlBlock_flush_valid = ($urandom % 16 == 0);\n")
    L.append("  endtask\n")

    L.append("  task check();\n")
    for w, n in outs:
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;\n")
        L.append(f"      if(errors<=120) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end\n")
    L.append("    checks++;\n  endtask\n")
    L.append("""  initial begin
    no_flush = $test$plusargs("NO_FLUSH");
    rst = 1; drive_rand();
    repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) begin
      @(negedge clk); drive_rand();
      @(posedge clk); #1 check();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    (UT / "sched_tb.sv").write_text("".join(L))

    deps = iq_dep_closure(cfg)
    bb = " ".join(deps)
    fm_merge_line = "FM_MERGE_DUP = false\n" if cfg.get("fm_merge_dup_false") else ""
    mk = f"""\
MODULE = {cfg['module']}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核(golden 同名顶层 wrapper)+ 类型包。svh 由核 include。
RTL_SRCS = $(RTL_DIR)/backend/{cfg['pkg']}.sv \\
           $(RTL_DIR)/backend/{cfg['core']}

# golden 黑盒:IQ 例化所需的全部子模块(两侧 u_g/u_i 共享)。
BB_DEPS = {bb}

# UT: u_g=golden 顶层, u_i=可读核顶层(重命名 _xs)。
TB_SRCS = scheduler_variant_xs.sv sched_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/{cfg['module']}.sv \\
              $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))

# FM: ref=golden 顶层+依赖; impl=可读核+同一批 golden 黑盒。
WRAPPER_SRCS = $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = {cfg['module']}
FM_REF_DEPS_{cfg['module']} = $(BB_DEPS)

{fm_merge_line}include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden 无 reset 的状态寄存器上电为 X,flush 把 X 派生值灌进 don't-care 输出造假阳性。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
"""
    (UT / "Makefile").write_text(mk)
    print(f"wrote verif/ut/{cfg['ut']}/ (ins={len(ins)} outs={len(outs)} bb_deps={len(deps)})")


if __name__ == "__main__":
    import sys
    which = sys.argv[1:] or list(VARIANTS)
    for key in which:
        cfg = VARIANTS[key]
        print(f"==== {cfg['title']} ({cfg['module']}) ====")
        emit_pkg(cfg)
        emit_iq_connect(cfg)
        emit_core(cfg)
        emit_ut(cfg)
