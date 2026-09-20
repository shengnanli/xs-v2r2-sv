#!/usr/bin/env python3
"""生成 DelayN 家族的变体薄文件（rtl/common/DelayN*.sv）。

事实全部从 G1 golden 现读（gen_facts.py）：端口表逐字照抄 golden，级数与
寄存器总位数从 golden 的 reg 声明数出来。改 golden 基线后重跑本脚本即可刷新。
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_facts import facts

HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/common"))

# Frontend 例化闭包里的 6 个 DelayN 变体 + 各自的使用者（golden 里 grep 出来的父模块）
VARIANTS = {
    "DelayN":     "Predictor / Composer —— 分支预测各子预测器的使能位打一拍",
    "DelayN_1":   "FTB / Backend / PTW 系列 —— 单比特控制位打两拍",
    "DelayN_7":   "Frontend / TLB 系列 —— satp/vsatp/hgatp/mbmc/priv/pmm 快照打两拍",
    "DelayN_8":   "Frontend / MemBlock —— 自定义 CSR 分发包（含 trigger）打两拍",
    "DelayN_9":   "TLB 系列 —— TLB 请求（valid + rs1/rs2/addr/id/flushPipe/hv/hg）打两拍",
    "DelayN_13":  "Frontend / L2TLB / LSQ 系列 —— 单比特控制位打一拍",
    "DelayN_15":  "CtrlBlock —— 单比特控制位打四拍",
    "DelayN_17":  "InterruptFilter / CtrlBlock —— 单比特控制位打五拍",
    "DelayN_208": "InterruptFilter —— 8 位中断向量打五拍",
    "DelayN_214": "ExeUnit_7（向量执行单元）—— 183 位微操作包打两拍",
    "DelayN_215": "ExeUnit_7 —— robIdx(flag+value) 打两拍",
    "DelayN_220": "L2TLB —— PTW 请求（valid + rs1/rs2/addr/id/hv/hg）打一拍",
    "DelayN_221": "L2TLB —— 261 位 PTW 响应包打一拍",
    "DelayN_225": "LqPAddrModule —— ★0 级退化变体★：DelayN(x, 0) 就是一根直连线，"
                  "golden 里连 clock 端口都没有",
    "DelayN_297": "LoadQueueRAW —— 单比特控制位打三拍",
    "DelayN_331": "MemBlock —— 单比特控制位打十拍（本族最深）",
    "DelayN_333": "MemBlock —— 14 位控制包打两拍",
    "DelayN_334": "L2Top —— 48 位包打五拍",
}


def wrap_concat(names, indent, tail=""):
    """把一串端口名折成多行拼接：{a, b, c} —— 每行不超过 ~90 列。"""
    lines, cur = [], indent + "{"
    for i, n in enumerate(names):
        last = (i == len(names) - 1)
        piece = n + ("}" + tail if last else ",")
        if len(cur) + len(piece) + 1 > 90 and not cur.endswith("{"):
            lines.append(cur)
            cur = indent + " " + piece
        else:
            cur += ("" if cur.endswith("{") else " ") + piece
    lines.append(cur)
    return "\n".join(lines)


def gen_variant(name):
    f = facts(name)
    stages, regbits, payload = f["stages"], f["reg_bits"], f["payload"]
    assert payload * stages == regbits, name
    has_clk = "clock" in f["other"]
    assert has_clk == (stages > 0), name
    ins = [p["name"] for p in f["ins"]]
    outs = [p["name"] for p in f["outs"]]
    fields = ", ".join(f'{p["name"][len("io_in_"):] or "io_in"}={p["w"]}b'
                       for p in f["ins"][:5])
    more = "" if len(ins) <= 5 else f" …共 {len(ins)} 个字段，明细见端口表"
    ports = f["head_text"].split("\n", 1)[1]
    # 0 级变体的 golden 没有 clock 端口，核里那条时钟分支也不存在；给核喂常 0，
    # 并用 GOLDEN_HAS_CLOCK 把「端口表有没有时钟」与「级数是不是 0」绑死。
    clk_arg = "clock" if has_clk else "1'b0"     # 0 级变体：golden 端口表无 clock
    # PAYLOAD_W 平时从 golden 的 reg 位数除级数得出（抄错级数或位宽立刻不守恒）；
    # 0 级变体没有 reg，只能直接写载荷位宽，由下面 PORT_BITS_IN/OUT 的 $bits 核对。
    payload_expr = ("GOLDEN_REG_BITS / STAGES" if has_clk
                    else "%d;   // 0 级：无 reg 可除，载荷位宽直接写，由下面 $bits 核对"
                         % payload)
    stage_desc = ("%d 级 × %d 位" % (stages, payload) if has_clk
                  else "0 级 —— golden 模块体里一个 reg 也没有，输出直连输入")
    return f"""// =============================================================================
// {name} —— 固定级数的载荷打拍链（xs_DelayN_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = {stages}；载荷宽度 = {payload} 位，分 {len(ins)} 个字段；
//   golden 模块体 = {regbits} 个 reg 位（{stage_desc}），无复位 / 无使能 / 无子模块；
//   端口 {len(f["ports"])} 个 = {"clock + " if has_clk else ""}{len(ins)} 个 io_in_* + {len(outs)} 个 io_out_*。
//   载荷字段：{fields}{more}。
//   使用者：{VARIANTS[name]}。
//
// 结构：golden 同名端口表 -> 打包成一根 {payload} 位扁平载荷 -> 设参例化
//   xs_DelayN_core（核体见 xs_DelayN_core.sv，打拍语义与不变式都在那里讲）
//   -> 拆包回 golden 的 io_out_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（本轮已发生 3 次位宽静默错事故）。
// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module {name}(
{ports}

  localparam int unsigned STAGES          = {stages};
  localparam int unsigned GOLDEN_REG_BITS = {regbits};   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = {payload_expr}{";" if has_clk else ""}

  // 端口表事实：golden 全部输入 / 输出端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
{wrap_concat(ins, "    ")});
  localparam int unsigned PORT_BITS_OUT = $bits(
{wrap_concat(outs, "    ")});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
{wrap_concat(ins, "    ", ";")}

  xs_DelayN_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT),
    .GOLDEN_HAS_CLOCK({int(has_clk)})
  ) u_core (
    .clock({clk_arg}),
    .d_in (payload_in),
    .d_out(payload_out)
  );

  assign
{wrap_concat(outs, "    ", " = payload_out;")}

endmodule
"""




# ---------------------------------------------------------------------------
# 家族 tb：6 变体一个对照台。
# tb 侧**独立重算**一次载荷的位切片（按 golden 端口顺序 MSB 优先），因此它同时
# 是薄文件打包顺序的第二道证明——薄文件与 tb 若对不上，逐拍比对立刻炸。
# ---------------------------------------------------------------------------
def slices(ports):
    tot = sum(p["w"] for p in ports)
    out, hi = [], tot - 1
    for p in ports:
        lo = hi - p["w"] + 1
        out.append((p["name"], hi, lo, p["w"]))
        hi = lo - 1
    assert hi == -1
    return out


def sig(name):
    return "d0" if name == "DelayN" else "d" + name[len("DelayN_"):]


TB_HEAD = """// 自动生成：verif/ut/DelayN/gen.py（读 G1 golden）—— 勿手改
// DelayN 家族 6 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
// （同一个 xs_DelayN_core 设不同 WIDTH/STAGES）。
//
// tb 把每个变体的载荷当成一根扁平向量随机驱动，再按 **golden 端口顺序 MSB 优先**
// 切片接到各个 io_in_*/io_out_* 上——这份切片是 tb 独立重算的，与薄文件里的拼接
// 互为对照：只要两边的打包顺序对不上，逐拍比对立刻失配。
//
// 打拍链无复位：上电输出为 X，故 $isunknown(golden 输出) 时跳过比对（不计 checks）。
//
// 覆盖闸（小模块最容易假绿：本轮有 tb 在 20 万拍里只 fire 1 次却报 errors=0）：
//   每个变体都必须
//     (1) 有效比对次数 checks >= COV_MIN；
//     (2) 输出发生变化（相邻拍不等）的次数 >= COV_MIN —— 证明数据真的在流动；
//     (3) **每一个载荷位**都在输出上既被观察到 1 也被观察到 0 —— 任何一位常 X /
//         常 0 / 接错都会让 ones/zeros 位图缺位，直接判 FAIL。
//   任何一项不满足即 TEST FAILED，不看 errors。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0;
  int checks = 0;
  int cov_fail = 0;
  int mode;
  always #5 clock = ~clock;
"""


def gen_tb():
    L = [TB_HEAD]
    infos = []
    for name in VARIANTS:
        f = facts(name)
        s, pw = sig(name), f["payload"]
        ins, outs = slices(f["ins"]), slices(f["outs"])
        infos.append((name, s, pw, f["stages"], ins, outs))
        L.append(f"  // ---- {name}: 载荷 {pw} 位 / {f['stages']} 级 / {len(f['ins'])} 字段 ----")
        L.append(f"  logic [{pw-1}:0] {s}_in;")
        L.append(f"  wire  [{pw-1}:0] g_{s}_out;")
        L.append(f"  wire  [{pw-1}:0] i_{s}_out;")
        L.append(f"  logic [{pw-1}:0] {s}_ones, {s}_zeros, {s}_prev;")
        L.append(f"  int   {s}_checks, {s}_moves;")
        for tag, mod in (("g", name), ("i", name + "_xs")):
            # 0 级变体（DelayN_225）没有 clock 端口，连都不能连。
            conn = ["    .clock(clock)"] if "clock" in f["other"] else []
            for nm, hi, lo, w in ins:
                conn.append(f"    .{nm}({s}_in[{hi}:{lo}])" if w > 1 else f"    .{nm}({s}_in[{hi}])")
            for nm, hi, lo, w in outs:
                conn.append(f"    .{nm}({tag}_{s}_out[{hi}:{lo}])" if w > 1
                            else f"    .{nm}({tag}_{s}_out[{hi}])")
            L.append(f"  {mod} u_{tag}_{s} (")
            L.append(",\n".join(conn))
            L.append("  );")
        L.append("")

    drive, check, init, cov = [], [], [], []
    for name, s, pw, stg, ins, outs in infos:
        drive.append(f"""    case (mode)
      0:       {s}_in = '0;
      1:       {s}_in = '1;
      default: for (int b = 0; b < {pw}; b++) {s}_in[b] = 1'($urandom);
    endcase""")
        check.append(f"""    if (!$isunknown(g_{s}_out)) begin
      checks++; {s}_checks++;
      {s}_ones  |= g_{s}_out;
      {s}_zeros |= ~g_{s}_out;
      if ({s}_prev !== g_{s}_out) {s}_moves++;
      {s}_prev = g_{s}_out;
      if (g_{s}_out !== i_{s}_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH {name} g=%0h i=%0h", $time, g_{s}_out, i_{s}_out);
      end
    end""")
        init.append(f"    {s}_in = '0; {s}_ones = '0; {s}_zeros = '0; {s}_prev = 'x;"
                    f" {s}_checks = 0; {s}_moves = 0;")
        cov.append(f"""    $display("  {name}: checks=%0d moves=%0d ones=%0d/{pw} zeros=%0d/{pw}",
             {s}_checks, {s}_moves, $countones({s}_ones), $countones({s}_zeros));
    if ({s}_checks < COV_MIN) begin
      $display("COVERAGE FAIL: {name} 有效比对只有 %0d 次 (需 >= %0d)", {s}_checks, COV_MIN);
      cov_fail++;
    end
    if ({s}_moves < COV_MIN) begin
      $display("COVERAGE FAIL: {name} 输出只变化 %0d 次 (需 >= %0d)，数据没在流动",
               {s}_moves, COV_MIN);
      cov_fail++;
    end
    if (!(&{s}_ones) || !(&{s}_zeros)) begin
      $display("COVERAGE FAIL: {name} 有载荷位从未在输出上观察到 1 或 0 (ones=%0h zeros=%0h)",
               {s}_ones, {s}_zeros);
      cov_fail++;
    end""")

    nl = "\n"
    L.append(f"""
  // 每拍随机选一种模式：全 0 / 全 1 / 逐位随机 —— 保证每一位都能被观察到 1 和 0
  task automatic drive_random_inputs();
    mode = $urandom_range(0, 7);
{nl.join(drive)}
  endtask

  task automatic check_outputs();
{nl.join(check)}
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
{nl.join(init)}
    repeat (NCYCLES) begin
      @(negedge clock);   // 输出在 posedge 变，negedge 稳定：先比对上一拍结果，再换激励
      check_outputs();
      drive_random_inputs();
    end
{nl.join(cov)}
    // ★这一行是判据的唯一出口★：checks / errors / bad_cov 一起打，
    // scripts/mutant_harness.py 按 `checks=N errors=N bad_cov=N` 整条匹配。
    // 只打 errors 的话，"一次都没比对"和"比对全过"在日志里长得一模一样。
    $display("DelayN family checks=%0d errors=%0d bad_cov=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
""")
    open(os.path.join(HERE, "tb.sv"), "w").write("\n".join(L))
    print("wrote tb.sv")


if __name__ == "__main__":
    for n in VARIANTS:
        open(os.path.join(RTL, n + ".sv"), "w").write(gen_variant(n))
        print("wrote", os.path.join(RTL, n + ".sv"))
    gen_tb()
