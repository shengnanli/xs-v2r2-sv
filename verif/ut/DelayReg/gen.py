#!/usr/bin/env python3
"""生成 DelayReg 家族的变体薄文件（rtl/common/DelayReg*.sv）与家族 tb。

事实全部从 G1 golden 现读（gen_facts.py）：端口表逐字照抄 golden，级数与寄存器
总位数从 golden 的 reg 声明数出来。**生成前先跑一遍完全重建核对**（见
gen_facts.verify_reconstruct）：只用 (端口表, 级数) 重建 golden 模块体，
11/11 必须逐行一致，否则说明某个变体里有本核覆盖不到的东西，当场拒绝生成
而不是照生成再指望 FM 兜底。

改 golden 基线后重跑本脚本即可刷新。
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_facts import facts, verify_reconstruct, VARIANTS, USERS

HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/common"))


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
    ins = [p["name"] for p in f["ins"]]
    outs = [p["name"] for p in f["outs"]]
    sample = ", ".join(f'{p["name"][2:]}={p["w"]}b' for p in f["ins"][:5])
    more = "" if len(ins) <= 5 else f" …共 {len(ins)} 个字段，明细见端口表"
    who, where = USERS[name]
    ports = f["head_text"].split("\n", 1)[1]
    return f"""// =============================================================================
// {name} —— 带使能与同步复位的载荷打拍链（xs_DelayReg_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   延迟级数 STAGES = {stages}；载荷宽度 = {payload} 位，分 {len(ins)} 个字段；
//   golden 模块体 = {regbits} 个 reg 位（{stages} 级 × {payload} 位），同步复位 / 带使能 / 无子模块；
//   端口 {len(f["ports"])} 个 = clock + reset + {len(ins)} 个 i_* + {len(outs)} 个 o_* + enable。
//   （enable 排在**最后**，不是跟 clock/reset 一起——Chisel 里它是 Delayer 基类
//     在主 Bundle 之后单独 IO 出来的一根，端口序照抄 golden。）
//   载荷字段：{sample}{more}。
//   使用者：{who}。
//   级数的出处：{where}
//   —— 全族级数从 1 到 4 不等，那是**每个 DifftestBundle 在调用点各自选的
//      delay= 参数**，不是某个变体漏做了什么，不要去"补齐"。
//
// 结构：golden 同名端口表 -> 打包成一根 {payload} 位扁平载荷 -> 设参例化
//   xs_DelayReg_core（核体见 xs_DelayReg_core.sv，打拍/复位/使能语义与不变式
//   都在那里讲）-> 拆包回 golden 的 o_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：任何一个端口的位宽
//   抄错，拼接总位数就变，time 0 直接 $fatal（见 verif/ut/DelayReg 的 negtest）。
// 自动生成：verif/ut/DelayReg/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module {name}(
{ports}

  localparam int unsigned STAGES          = {stages};
  localparam int unsigned GOLDEN_REG_BITS = {regbits};   // golden 里 reg 位数总和
  localparam int unsigned PAYLOAD_W       = GOLDEN_REG_BITS / STAGES;

  // 端口表事实：golden 全部 i_* / o_* 端口拼起来各有多少位（$bits 只认端口声明）
  localparam int unsigned PORT_BITS_IN = $bits(
{wrap_concat(ins, "    ")});
  localparam int unsigned PORT_BITS_OUT = $bits(
{wrap_concat(outs, "    ")});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  // 打包次序 = golden 端口声明顺序，先声明的在高位。
  assign payload_in =
{wrap_concat(ins, "    ", ";")}

  xs_DelayReg_core #(
    .WIDTH          (PAYLOAD_W),
    .STAGES         (STAGES),
    .GOLDEN_REG_BITS(GOLDEN_REG_BITS),
    .PORT_BITS_IN   (PORT_BITS_IN),
    .PORT_BITS_OUT  (PORT_BITS_OUT)
  ) u_core (
    .clock (clock),
    .reset (reset),
    .enable(enable),
    .d_in  (payload_in),
    .d_out (payload_out)
  );

  // 拆包：与上面的打包次序互逆。
  assign
{wrap_concat(outs, "    ", " = payload_out;")}

endmodule
"""


# ---------------------------------------------------------------------------
# 家族 tb：11 变体一个对照台。
# tb 侧**独立重算**一次载荷的位切片（按 golden 端口顺序 MSB 优先），因此它同时
# 是薄文件打包顺序的第二道证明——薄文件与 tb 若对不上，逐拍比对立刻失配。
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
    return "d0" if name == "DelayReg" else "d" + name[len("DelayReg_"):]


TB_HEAD = """// 自动生成：verif/ut/DelayReg/gen.py（读 G1 golden）—— 勿手改
// DelayReg 家族 11 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
// （同一个 xs_DelayReg_core 设不同 WIDTH/STAGES）。
//
// tb 把每个变体的载荷当成一根扁平向量驱动，再按 **golden 端口顺序 MSB 优先**
// 切片接到各个 i_*/o_* 上——这份切片是 tb 独立重算的，与薄文件里的拼接互为对照：
// 只要两边的打包顺序对不上，逐拍比对立刻失配。
//
// ★激励为什么不是"每位一次 $urandom"★ 本族载荷合计 48320 位（最宽的 DelayReg_21
// 一个就 19208 位）。逐位 $urandom 在 20 万拍下是 96 亿次调用，跑不完。
// 改成：开跑前按 32 位字灌满一次随机，之后每拍从低位**移入 32 位新随机**。
// 这样每拍的载荷值都与上一拍不同（能抓"取错级"），每一位也都会被刷新
// （最宽的一路 19208 位，20 万拍里轮过 10 遍），而每拍只要 11 次 $urandom。
// 另外每拍以一定概率直接给全 0 / 全 1，把位图覆盖一次性打满。
//
// ★这一族与 DelayN 的差别：reset 与 enable★ 所以激励必须覆盖
//   enable=0 连续保持（整条链冻结）、reset 与 enable 同拍（复位优先）、
//   reset 在 enable=0 时单独到来（同步复位照样生效）——三者都有覆盖闸。
//
// 复位后输出确定为 0，所以不需要像 DelayN 那样跳过 X；但开跑前仍先拉几拍 reset，
// 让两侧从同一个确定状态出发（+vcs+initreg+random 那轮尤其要）。
//
// 覆盖闸（小模块最容易假绿）：每个变体都必须
//   (1) 有效比对次数 checks >= COV_MIN；
//   (2) 输出发生变化的次数 >= COV_MIN —— 证明数据真的在流动；
//   (3) **每一个载荷位**都在输出上既被观察到 1 也被观察到 0；
// 外加全局三项控制覆盖（见 §CTRLCOV）。任何一项不满足即 TEST FAILED，不看 errors。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  // ★覆盖门限按拍数等比缩放★（基准 = 20 万拍时的那组值）。
  // 固定门限会让"跑短拍数"这件事本身变成 FAIL —— mutants.py 为了快是按 2 万拍跑的，
  // 门限不缩放就会有几项天然达不到，负测的输出里混进一堆与变异无关的红字，
  // 真正该看的 errors 反而被淹掉。缩放之后短跑与长跑的判据是同一条。
  int unsigned COV_MIN, COV_RUNS, COV_RST, COV_RST_EN1, COV_RST_EN0;
  function automatic int unsigned scaled(int unsigned per200k);
    return (NCYCLES * per200k) / 200000 > 0 ? (NCYCLES * per200k) / 200000 : 1;
  endfunction
  bit clock = 0;
  logic reset = 1'b1;
  logic enable = 1'b1;
  int errors = 0;
  int checks = 0;
  int cov_fail = 0;
  int mode;
  always #5 clock = ~clock;

  // §CTRLCOV 控制面覆盖计数
  int cov_en0 = 0;        // enable=0（冻结）拍数
  int cov_en0_run = 0;    // enable 连续拉低 >= 4 拍的次数
  int cov_rst = 0;        // reset=1 拍数（暖机之后）
  int cov_rst_en1 = 0;    // reset=1 且 enable=1（复位优先于使能）
  int cov_rst_en0 = 0;    // reset=1 且 enable=0（同步复位不受使能门控）
  int en0_len = 0;
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
            conn = ["    .clock(clock)", "    .reset(reset)", "    .enable(enable)"]
            for nm, hi, lo, w in ins:
                conn.append(f"    .{nm}({s}_in[{hi}:{lo}])" if w > 1 else f"    .{nm}({s}_in[{hi}])")
            for nm, hi, lo, w in outs:
                conn.append(f"    .{nm}({tag}_{s}_out[{hi}:{lo}])" if w > 1
                            else f"    .{nm}({tag}_{s}_out[{hi}])")
            L.append(f"  {mod} u_{tag}_{s} (")
            L.append(",\n".join(conn))
            L.append("  );")
        L.append("")

    drive, check, init, seed, cov = [], [], [], [], []
    for name, s, pw, stg, ins, outs in infos:
        # 移入 32 位新随机；窄载荷（<=32 位）直接整根重取
        if pw <= 32:
            shift = f"{s}_in = {pw}'($urandom());"
        else:
            shift = f"{s}_in = {{{s}_in[{pw-33}:0], 32'($urandom())}};"
        drive.append(f"""    case (mode)
      0:       {s}_in = '0;
      1:       {s}_in = '1;
      default: {shift}
    endcase""")
        check.append(f"""    begin
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
        init.append(f"    {s}_ones = '0; {s}_zeros = '0; {s}_prev = 'x;"
                    f" {s}_checks = 0; {s}_moves = 0;")
        nw = (pw + 31) // 32
        seed.append(f"    for (int w = 0; w < {nw}; w++) "
                    f"{s}_in[32*w +: 32] = 32'($urandom());" if pw > 32
                    else f"    {s}_in = {pw}'($urandom());")
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
      $display("COVERAGE FAIL: {name} 有载荷位从未在输出上观察到 1 或 0");
      cov_fail++;
    end""")

    nl = "\n"
    L.append(f"""
  // 每拍选一种载荷模式：全 0 / 全 1 / 移入新随机
  task automatic drive_random_inputs();
    mode = $urandom_range(0, 7);
{nl.join(drive)}
  endtask

  task automatic seed_inputs();
{nl.join(seed)}
  endtask

  task automatic check_outputs();
{nl.join(check)}
  endtask

  // 控制面激励：enable 以游程方式拉低（要连续冻结，不能只单拍抖动），
  // reset 周期性脉冲，且**故意安排**与 enable 的 4 种组合都出现。
  task automatic drive_ctrl(int unsigned c);
    if (en0_len > 0) begin
      en0_len--;
      enable = 1'b0;
    end
    else if ($urandom_range(0, 99) < 12) begin
      en0_len = $urandom_range(3, 9);   // 连续冻结 4..10 拍
      enable  = 1'b0;
    end
    else begin
      enable = 1'b1;
    end
    // reset：每 337 拍打 2 拍；另每 1013 拍打 1 拍并**强制 enable=0**，
    // 保证"同步复位在 enable=0 时照样生效"这一条被观测到。
    reset = ((c % 337) < 2) || ((c % 1013) == 0);
    if ((c % 1013) == 0) enable = 1'b0;
    if ((c % 337) < 2)   enable = 1'b1;   // 这一组是"复位与使能同拍"
  endtask

  task automatic sample_ctrl_cov(int unsigned c);
    if (!enable) cov_en0++;
    if (en0_len == 0 && !enable) cov_en0_run++;
    if (reset) begin
      cov_rst++;
      if (enable) cov_rst_en1++; else cov_rst_en0++;
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    COV_MIN     = scaled(1000);
    COV_RUNS    = scaled(100);
    COV_RST     = scaled(100);
    COV_RST_EN1 = scaled(50);
    COV_RST_EN0 = scaled(20);
{nl.join(init)}
    seed_inputs();
    reset = 1'b1; enable = 1'b1;
    repeat (5) @(negedge clock);
    reset = 1'b0;

    for (int unsigned c = 0; c < NCYCLES; c++) begin
      @(negedge clock);   // 输出在 posedge 变，negedge 稳定：先比对上一拍结果，再换激励
      check_outputs();
      sample_ctrl_cov(c);
      drive_random_inputs();
      drive_ctrl(c);
    end
    $display("DelayReg family checks=%0d errors=%0d", checks, errors);
{nl.join(cov)}
    $display("  CTRL: en0=%0d runs=%0d rst=%0d rst&en1=%0d rst&en0=%0d",
             cov_en0, cov_en0_run, cov_rst, cov_rst_en1, cov_rst_en0);
    if (cov_en0     < COV_MIN)     begin $display("COVERAGE FAIL: enable=0 拍数不足"); cov_fail++; end
    if (cov_en0_run < COV_RUNS)    begin $display("COVERAGE FAIL: enable 连续冻结段数不足"); cov_fail++; end
    if (cov_rst     < COV_RST)     begin $display("COVERAGE FAIL: reset 拍数不足"); cov_fail++; end
    if (cov_rst_en1 < COV_RST_EN1) begin $display("COVERAGE FAIL: 未观测到 reset 与 enable 同拍（复位优先没被验到）"); cov_fail++; end
    if (cov_rst_en0 < COV_RST_EN0) begin $display("COVERAGE FAIL: 未观测到 reset 在 enable=0 时到来（同步复位不受使能门控没被验到）"); cov_fail++; end
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
    bad = [n for n in VARIANTS if not verify_reconstruct(n)[0]]
    if bad:
        raise SystemExit("完全重建核对未通过，拒绝生成: %s" % bad)
    print("完全重建核对: %d/%d 逐行一致" % (len(VARIANTS), len(VARIANTS)))
    for n in VARIANTS:
        open(os.path.join(RTL, n + ".sv"), "w").write(gen_variant(n))
        print("wrote", os.path.join(RTL, n + ".sv"))
    gen_tb()
