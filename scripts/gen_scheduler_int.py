#!/usr/bin/env python3
"""
Scheduler(Int 变体)可读重写生成器。

设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
        (class Scheduler / SchedulerImpBase / SchedulerArithImp)

================================ 设计意图 ================================
Scheduler 是「发射调度顶层」,本身几乎不含算法逻辑 —— 真正的乱序调度
(条目阵列 / 年龄仲裁 / 唤醒队列 / FU busy 表)全部封装在 IssueQueue 子模块里。
Scheduler 的职责是把若干 IssueQueue 例化在一起并做「互联(glue)」:

  1) 唤醒网络路由(wakeup network):
     - 收 fromDispatch 的 uop、fromSchedulers 的跨 IQ 唤醒、各类写回唤醒;
     - 把这些唤醒**广播**给每个 IQ 的 wakeupFromIQ 端口;
     - 把每个 IQ 自己产生的 wakeupToIQ 汇出到 toSchedulers,供别的 Scheduler 消费。
     关键点:同一个唤醒源(exuIdx)对不同 IQ 提供「不同的 pdest 拷贝」
     (pdestCopy/rfWenCopy/loadDependencyCopy)—— 这是物理上为缩短唤醒扇出
     时序而做的「目的寄存器号多拷贝」。拷贝下标由「IQ 在本 SchdBlock 内的位置」
     决定(本 Int 变体:IQ0/IQ1 取 copy0,IQ2/IQ3 取 copy1)。

  2) 响应路由:把 DataPath 回来的 og0/og1 resp、cancel 等按 IQ 分发回去。

  3) dispatch 派发:fromDispatch 的 uop 直连各 IQ 的 enq;IQ 的 enq.ready
     再回送成 fromDispatch.uops.ready。

  4) 发射 perf 统计(SchedulerImpBase 里的 basePerfEvents):
     - issueQueue_enq_fire_cnt:上一拍 8 个 enq 端口「ready & valid」的个数;
     - <IQ>_full:上一拍每个 IQ 的 enq0.ready(队列是否还能收)。
     这些事件计数都经过 RegNext 打两拍再输出(firtool 的 _REG/_REG_1)。

================================ 重写方式 ================================
firtool golden Scheduler.sv 把上述意图展平成:4 个 IssueQueue 例化 + 几百条
「IQ 端口 ↔ 顶层端口」直连 + 5 个 perf 计数寄存器。经分析(见脚本注释):
  - 355 个输出里 346 个由 IQ 例化内部直接驱动(纯连线,无逻辑);
  - 仅 9 个 assign:4 条 dispatch-ready 透传 + 5 条 perf 输出;
  - 唯一的时序/组合逻辑就是 perf 计数树 + 两级 RegNext。
也就是说 Scheduler 是「真正的互联模块」:逻辑都在被例化的 IQ 黑盒里。
因此本重写遵循「可读核 + 机械互联 svh」分层(.svh 套壳闸门合法场景):

  rtl/backend/scheduler_int_pkg.sv
      参数(IQ 个数 / enq 端口数 / 唤醒源数)、iq_id_e 枚举、perf 流水 struct、
      唤醒拷贝下标选择函数 copy_idx_of_iq()。
  rtl/backend/Scheduler.sv  —— 可读核 xs_Scheduler_int_core(golden 同名顶层 wrapper)
      * 用 enum 标识 4 个 IQ,用 struct 表达 perf 两级流水;
      * 用 genvar/for + function 重写 perf 计数(enq_fire popcount 树 / full 向量);
      * dispatch-ready 透传;
      * `include scheduler_int_iq_connect.svh 例化 4 个 IQ 并连线。
  rtl/backend/scheduler_int_iq_connect.svh —— 机械互联表(例化 4 个 IQ + 端口直连)
      纯连线,无 _GEN_/_T_,满足 .svh 套壳闸门。

UT/FM:IQ 子模块两侧共享 golden 黑盒(IssueQueue* 及其全部依赖),
       u_g=golden Scheduler,u_i=可读核 Scheduler_xs,逐拍比对全部输出。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/Scheduler"
GEN = "// 自动生成:scripts/gen_scheduler_int.py —— 勿手改\n"

# Int Scheduler 的 4 个 IssueQueue 实例(模块名, 实例名), 与 golden 顺序一致。
IQS = [
    ("IssueQueueAluMulBkuBrhJmp",                  "IssueQueueAluMulBkuBrhJmp"),
    ("IssueQueueAluMulBkuBrhJmp",                  "IssueQueueAluMulBkuBrhJmp_1"),
    ("IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v", "IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v"),
    ("IssueQueueAluCsrFenceDiv",                   "IssueQueueAluCsrFenceDiv"),
]


def parse_ports(modname, fname):
    text = (GOLDEN / fname).read_text()
    m = re.search(r"^module %s\(\n(.*?)\n\);" % re.escape(modname), text, re.S | re.M)
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


def parse_inst_conns(inst):
    """返回 golden Scheduler 中某 IQ 实例的 [(iqport, rhs)],含 clock/reset。"""
    txt = (GOLDEN / "Scheduler.sv").read_text()
    m = re.search(r'^  \w+ %s \(\n(.*?)\n  \);' % re.escape(inst), txt, re.S | re.M)
    body = m.group(1)
    lines = body.split('\n'); logical = []; cur = ""
    for ln in lines:
        if re.match(r'\s*\.\w', ln):
            if cur: logical.append(cur)
            cur = ln.strip()
        else:
            cur += " " + ln.strip()
    if cur: logical.append(cur)
    out = []
    for lg in logical:
        cm = re.match(r'\.(\S+)\s*\((.*)\)\s*,?$', lg)
        if cm:
            out.append((cm.group(1), cm.group(2).strip()))
    return out


def decl(d, w, n, suffix=","):
    rng = f"[{w-1}:0] " if w > 1 else ""
    return f"  {d:<7}{rng}{n}{suffix}\n"


# ---------------------------------------------------------------------------
# 1) 类型包
# ---------------------------------------------------------------------------
def emit_pkg():
    s = [GEN]
    s.append("""\
// =============================================================================
// scheduler_int_pkg —— 香山 V2R2 Int Scheduler 可读重写 类型/参数包
// 设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
// =============================================================================
package scheduler_int_pkg;

  // ---- 维度参数(本 Int SchdBlock 的实例化结果)----
  localparam int NUM_IQ      = 4;  // 本调度块内的发射队列个数
  localparam int NUM_ENQ     = 8;  // dispatch 派发入端口数(每 IQ 2 路 * 4 IQ)
  localparam int NUM_WK_SRC  = 7;  // fromSchedulers 跨 IQ 唤醒源个数(exuIdx 0..6)
  localparam int NUM_PDEST_COPY = 2;  // 每个唤醒源的 pdest 拷贝份数

  // 4 个发射队列的身份标识(与 golden 例化顺序一致)。
  // 唤醒网络要按 IQ 的物理位置选择 pdest 拷贝下标,故给每个 IQ 命名。
  typedef enum logic [1:0] {
    IQ_ALU_MUL_BKU_BRH_JMP_0 = 2'd0,  // AluMulBkuBrhJmp     (enq 0/1, perf full bit0)
    IQ_ALU_MUL_BKU_BRH_JMP_1 = 2'd1,  // AluMulBkuBrhJmp #2  (enq 2/3, perf full bit1)
    IQ_ALU_BRH_JMP_I2F_VSET  = 2'd2,  // AluBrhJmpI2f...     (enq 4/5, perf full bit2)
    IQ_ALU_CSR_FENCE_DIV     = 2'd3   // AluCsrFenceDiv      (enq 6/7, perf full bit3)
  } iq_id_e;

  // 唤醒拷贝下标选择:为缩短唤醒目的寄存器号(pdest)的扇出时序,每个唤醒源
  // 给出多份 pdest 拷贝;每个 IQ 取属于自己那一份。本 Int 变体的物理映射为
  // 前两个 IQ 用 copy0,后两个 IQ 用 copy1(由 backend 的 isCopyPdest 决定)。
  function automatic int copy_idx_of_iq(input iq_id_e iq);
    case (iq)
      IQ_ALU_MUL_BKU_BRH_JMP_0, IQ_ALU_MUL_BKU_BRH_JMP_1: copy_idx_of_iq = 0;
      default:                                            copy_idx_of_iq = 1;
    endcase
  endfunction

  // perf 计数两级流水:firtool 把每个 perf 事件用 RegNext 打两拍再输出。
  // s1 = 本拍采样值;s2 = 上一拍的 s1(即对外输出值)。
  typedef struct packed {
    logic [3:0] enq_fire_cnt;   // 8 个 enq 端口上拍 fire 个数(0..8 → 4bit)
    logic [3:0] iq_full;        // 4 个 IQ 上拍 enq0.ready(可收/满)位向量
  } perf_sample_t;

  // enq_fire 个数的 popcount(8 位 → 4 位结果)。用函数表达计数树,
  // 替代 firtool 展平的 {1'h0,..}+{1'h0,..} 嵌套加法。
  function automatic logic [3:0] popcount8(input logic [7:0] v);
    popcount8 = 4'(v[0]) + 4'(v[1]) + 4'(v[2]) + 4'(v[3])
              + 4'(v[4]) + 4'(v[5]) + 4'(v[6]) + 4'(v[7]);
  endfunction

endpackage
""")
    (BK / "scheduler_int_pkg.sv").write_text("".join(s))
    print("wrote scheduler_int_pkg.sv")


# ---------------------------------------------------------------------------
# 2) IQ 互联 svh —— 机械连线表(.svh 套壳闸门合法:逻辑都在 IQ 黑盒里)
# ---------------------------------------------------------------------------
def emit_iq_connect():
    s = [GEN]
    s.append("""\
// =============================================================================
// scheduler_int_iq_connect.svh —— Int Scheduler 的 4 个 IssueQueue 例化与互联
// (机械连线表:IQ 端口 ↔ 顶层端口 直连;唯一的内部信号是各 IQ 的 enq.ready,
//  它回送给 dispatch-ready 与 perf 统计。本文件无任何组合/时序逻辑,无 _GEN_/_T_。)
//
// 注:唤醒拷贝下标的物理选择(copy0 / copy1)体现在「连到哪个 pdestCopy 端口」上,
//     这正是 scheduler_int_pkg::copy_idx_of_iq 表达的意图;此处按 golden 的拷贝
//     选择结果做端口直连。
// =============================================================================

""")
    # 内部 enq.ready 线
    for _, inst in IQS:
        s.append(f"  logic {inst}_enq_0_ready;\n")
        s.append(f"  logic {inst}_enq_1_ready;\n")
    s.append("\n")
    for mod, inst in IQS:
        conns = parse_inst_conns(inst)
        s.append(f"  // ---- {inst} ----\n")
        s.append(f"  {mod} {inst} (\n")
        lines = []
        for p, r in conns:
            # enq ready 输出连到内部线
            if p == "io_enq_0_ready":
                lines.append(f"    .{p}({inst}_enq_0_ready)")
            elif p == "io_enq_1_ready":
                lines.append(f"    .{p}({inst}_enq_1_ready)")
            else:
                lines.append(f"    .{p}({r})")
        s.append(",\n".join(lines))
        s.append("\n  );\n\n")
    (BK / "scheduler_int_iq_connect.svh").write_text("".join(s))
    print("wrote scheduler_int_iq_connect.svh")


# ---------------------------------------------------------------------------
# 3) 可读核 = golden 同名顶层 wrapper(Scheduler.sv)
# ---------------------------------------------------------------------------
def emit_core():
    ports = parse_ports("Scheduler", "Scheduler.sv")
    s = [GEN]
    s.append("""\
// =============================================================================
// xs_Scheduler_int_core —— 香山 V2R2 Int Scheduler 可读核(golden 同名顶层)
// 设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
//
// 见 scripts/gen_scheduler_int.py 头部「设计意图 / 重写方式」。
// 本核做三件可读的事:
//   A) 例化 4 个 IssueQueue 并互联唤醒网络/响应(机械连线在 .svh,见套壳闸门);
//   B) dispatch-ready 透传:把各 IQ 的 enq0.ready 回送给 fromDispatch.uops.ready;
//   C) 发射 perf 统计:enq_fire 计数树 + 各 IQ full 位,两级 RegNext 后输出。
// =============================================================================
module Scheduler import scheduler_int_pkg::*; (
  input         clock,
  input         reset,
""")
    for d, w, n in ports:
        s.append(decl(d, w, n))
    s[-1] = s[-1].rstrip(",\n") + "\n"
    s.append(");\n\n")

    # A) IQ 例化 + 互联
    s.append('  // ===== A) 例化 4 个 IssueQueue 并互联(唤醒网络/响应/cancel) =====\n')
    s.append('  `include "scheduler_int_iq_connect.svh"\n\n')

    # B) dispatch-ready 透传
    s.append("""\
  // ===== B) dispatch-ready 透传 =====
  // 每个 IQ 的 enq0.ready 直接回送给对应的 dispatch uop ready。
  // (uops 6/7 等奇数端口的 ready 不外引 —— golden 仅引出每 IQ 第 0 个 enq 的 ready。)
  assign io_fromDispatch_uops_0_ready = IssueQueueAluMulBkuBrhJmp_enq_0_ready;
  assign io_fromDispatch_uops_2_ready = IssueQueueAluMulBkuBrhJmp_1_enq_0_ready;
  assign io_fromDispatch_uops_4_ready = IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v_enq_0_ready;
  assign io_fromDispatch_uops_6_ready = IssueQueueAluCsrFenceDiv_enq_0_ready;

""")

    # C) perf
    s.append("""\
  // ===== C) 发射 perf 统计 =====
  // 先把 4 个 IQ 的 2 路 enq 的 ready/valid 收成规整二维数组,便于用循环统计。
  //   enq_ready[iq][k] = 第 iq 个 IQ 第 k 路 enq 是否可收
  //   enq_valid[iq][k] = 对应 dispatch uop 是否有效
  logic [NUM_IQ-1:0][1:0] enq_ready;
  logic [NUM_IQ-1:0][1:0] enq_valid;
  always_comb begin
    enq_ready[IQ_ALU_MUL_BKU_BRH_JMP_0] = {IssueQueueAluMulBkuBrhJmp_enq_1_ready,
                                           IssueQueueAluMulBkuBrhJmp_enq_0_ready};
    enq_ready[IQ_ALU_MUL_BKU_BRH_JMP_1] = {IssueQueueAluMulBkuBrhJmp_1_enq_1_ready,
                                           IssueQueueAluMulBkuBrhJmp_1_enq_0_ready};
    enq_ready[IQ_ALU_BRH_JMP_I2F_VSET]  = {IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v_enq_1_ready,
                                           IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v_enq_0_ready};
    enq_ready[IQ_ALU_CSR_FENCE_DIV]     = {IssueQueueAluCsrFenceDiv_enq_1_ready,
                                           IssueQueueAluCsrFenceDiv_enq_0_ready};
    enq_valid[IQ_ALU_MUL_BKU_BRH_JMP_0] = {io_fromDispatch_uops_1_valid, io_fromDispatch_uops_0_valid};
    enq_valid[IQ_ALU_MUL_BKU_BRH_JMP_1] = {io_fromDispatch_uops_3_valid, io_fromDispatch_uops_2_valid};
    enq_valid[IQ_ALU_BRH_JMP_I2F_VSET]  = {io_fromDispatch_uops_5_valid, io_fromDispatch_uops_4_valid};
    enq_valid[IQ_ALU_CSR_FENCE_DIV]     = {io_fromDispatch_uops_7_valid, io_fromDispatch_uops_6_valid};
  end

  // 每 IQ 每路本拍是否 fire(ready & valid),拼成 8 位向量;各 IQ 的 full = enq0.ready。
  logic [NUM_ENQ-1:0] enq_fire;
  logic [NUM_IQ-1:0]  iq_full;
  genvar gi;
  generate
    for (gi = 0; gi < NUM_IQ; gi++) begin : g_perf_src
      assign enq_fire[gi*2 +: 2] = enq_ready[gi] & enq_valid[gi];
      assign iq_full[gi]         = enq_ready[gi][0];  // enq0 ready = 队列是否还能收
    end
  endgenerate

  // perf 三级流水(与 firtool 一致):
  //   stage0(last_cycle):先把本拍 enq_fire / iq_full 各打一拍(lastCycle*Vec);
  //   stage1(perf_s1)   :对 stage0 的 enq_fire 求 popcount;full 位直接打拍;
  //   stage2(perf_s2)   :再打一拍,作为对外 io_perf 输出。
  // 注意 popcount 作用在「已寄存」的 enq_fire 上(故计数比 fire 晚一拍),
  // 这一拍延迟是 golden 的真实时序,必须保留以逐拍等价。
  logic [NUM_ENQ-1:0] last_cycle_enq_fire;
  logic [NUM_IQ-1:0]  last_cycle_iq_full;
  perf_sample_t perf_s1, perf_s2;
  always_ff @(posedge clock) begin
    last_cycle_enq_fire  <= enq_fire;
    last_cycle_iq_full   <= iq_full;
    perf_s1.enq_fire_cnt <= popcount8(last_cycle_enq_fire);
    perf_s1.iq_full      <= last_cycle_iq_full;
    perf_s2              <= perf_s1;
  end

  // perf 输出:enq_fire_cnt 端口 6bit(高位补 0);各 full 端口 6bit(高位补 0)。
  assign io_perf_0_value = {2'h0, perf_s2.enq_fire_cnt};
  assign io_perf_1_value = {5'h0, perf_s2.iq_full[IQ_ALU_MUL_BKU_BRH_JMP_0]};
  assign io_perf_2_value = {5'h0, perf_s2.iq_full[IQ_ALU_MUL_BKU_BRH_JMP_1]};
  assign io_perf_3_value = {5'h0, perf_s2.iq_full[IQ_ALU_BRH_JMP_I2F_VSET]};
  assign io_perf_4_value = {5'h0, perf_s2.iq_full[IQ_ALU_CSR_FENCE_DIV]};

endmodule
""")
    (BK / "Scheduler.sv").write_text("".join(s))
    print("wrote Scheduler.sv (core+wrapper, ports=%d)" % len(ports))


# ---------------------------------------------------------------------------
# 4) _xs 变体(改名供 tb 与 golden 共存)+ tb + Makefile
# ---------------------------------------------------------------------------
def emit_xs_variant():
    txt = (BK / "Scheduler.sv").read_text()
    txt = txt.replace("module Scheduler import", "module Scheduler_xs import")
    (UT / "scheduler_variant_xs.sv").write_text(txt)
    print("wrote scheduler_variant_xs.sv")


def emit_tb():
    ports = parse_ports("Scheduler", "Scheduler.sv")
    ins  = [(w, n) for d, w, n in ports if d == "input"]
    outs = [(w, n) for d, w, n in ports if d == "output"]
    L = ["// 自动生成:scripts/gen_scheduler_int.py(tb)—— 勿手改\n"]
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
        s = [f"  {mod} u_{pfx} (\n    .clock(clk), .reset(rst),\n"]
        conn = [f"    .{n}({n})" for w, n in ins]
        conn += [f"    .{n}({pfx}_{n})" for w, n in outs]
        s.append(",\n".join(conn)); s.append("\n  );\n")
        return "".join(s)
    L.append(inst("Scheduler", "g"))
    L.append(inst("Scheduler_xs", "i"))

    L.append("  task drive_rand();\n")
    for w, n in ins:
        L.append(f"    {n} = $urandom;\n")
    L.append("    // 降低各 valid/handshake 密度,覆盖 enq/唤醒/发射/响应/重定向\n")
    for w, n in ins:
        if n.endswith("_valid") and ("Resp" not in n):
            L.append(f"    {n} = ($urandom % 4 == 0);\n")
    # deqDelay ready 偏高(让发射常被接受)
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
    UT.mkdir(parents=True, exist_ok=True)
    (UT / "sched_tb.sv").write_text("".join(L))
    print("wrote sched_tb.sv (ins=%d outs=%d)" % (len(ins), len(outs)))


# 4 个 IQ 的 golden 依赖闭包(由脚本计算,见头注),两侧 u_g/u_i 共享黑盒。
BB_DEPS = ("IssueQueueAluMulBkuBrhJmp.sv IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv "
           "IssueQueueAluCsrFenceDiv.sv "
           "AgeDetector.sv AgeDetector_1.sv EnqEntry.sv EnqEntry_4.sv EnqEntry_6.sv "
           "EnqPolicy.sv EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv EntriesAluCsrFenceDiv.sv "
           "EntriesAluMulBkuBrhJmp.sv FuBusyTableRead.sv FuBusyTableRead_2.sv "
           "FuBusyTableRead_22.sv FuBusyTableRead_23.sv FuBusyTableRead_26.sv "
           "FuBusyTableRead_28.sv FuBusyTableWrite.sv FuBusyTableWrite_22.sv "
           "FuBusyTableWrite_26.sv MultiWakeupQueue.sv MultiWakeupQueue_2.sv "
           "NewAgeDetector.sv OthersEntry.sv OthersEntry_44.sv OthersEntry_50.sv "
           "OthersEntry_6.sv OthersEntry_66.sv OthersEntry_72.sv PipeWithFlush.sv "
           "PipeWithFlush_1.sv UIntCompressor_27_000011100000000000001010101.sv")


def emit_makefile():
    mk = """\
MODULE = Scheduler

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核(golden 同名顶层 wrapper)+ 类型包。svh 由核 include。
RTL_SRCS = $(RTL_DIR)/backend/scheduler_int_pkg.sv \\
           $(RTL_DIR)/backend/Scheduler.sv

# golden 黑盒:4 个 IQ 例化所需的全部子模块(两侧 u_g/u_i 共享)。
BB_DEPS = %s

# UT: u_g=golden Scheduler 顶层, u_i=可读核顶层(重命名 _xs)。
TB_SRCS = scheduler_variant_xs.sv sched_tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Scheduler.sv \\
              $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))

# FM: ref=golden Scheduler+依赖; impl=可读核+同一批 golden 黑盒。
WRAPPER_SRCS = $(addprefix $(GOLDEN_RTL)/,$(BB_DEPS))
FM_VARIANTS = Scheduler
FM_REF_DEPS_Scheduler = $(BB_DEPS)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# golden 无 reset 的状态寄存器上电为 X,flush 把 X 派生值灌进 don't-care 输出造假阳性。
# initreg 让两侧寄存器都从 0 上电,消除 golden 上电 X 假象。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
""" % BB_DEPS
    UT.mkdir(parents=True, exist_ok=True)
    (UT / "Makefile.sched").write_text(mk)
    print("wrote Makefile.sched")


if __name__ == "__main__":
    emit_pkg()
    emit_iq_connect()
    emit_core()
    UT.mkdir(parents=True, exist_ok=True)
    emit_xs_variant()
    emit_tb()
    emit_makefile()
