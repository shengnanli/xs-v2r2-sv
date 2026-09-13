#!/usr/bin/env python3
"""生成 DelayNWithValid 家族的变体薄文件（rtl/common/）与家族 tb。

家族成员（G1 Frontend 闭包内，都由 FTB 例化）：
  DelayNWithValid    载荷 50 位（预测目标地址）
  DelayNWithValid_1  载荷 60 位（FTBEntry：brSlots/tailSlot/pftAddr/…）
两者时序结构逐字相同（valid 打一拍 + 两级带使能的数据寄存器），只差载荷位宽。
事实全部从 G1 golden 现读。
"""
import os, re, sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/common"))
PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')

USE = {
    "DelayNWithValid":   "FTB —— 预测目标地址沿预测流水打两拍",
    "DelayNWithValid_1": "FTB —— FTBEntry（分支槽 / 尾槽 / 预取地址 / strong_bias）打两拍",
}
VARIANTS = list(USE)


def facts(name):
    txt = open(f"{G}/{name}.sv").read()
    body = txt[txt.index(f"\nmodule {name}(") + 1:]
    head = body[:body.index("\n);")]
    ports = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit(f"{name}: 端口行解析失败: {ln!r}")
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        ports.append(dict(dir=m.group(1), w=w, name=m.group(4)))
    ins = [p for p in ports if p["name"].startswith("io_in_bits")]
    outs = [p for p in ports if p["name"].startswith("io_out_bits")]
    tot = 0
    for hi, lo, rn in re.findall(r'^  reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);', body, re.M):
        if rn == "valid_REG":
            continue
        tot += (int(hi) - int(lo) + 1) if hi else 1
    payload = sum(p["w"] for p in ins)
    assert [p["name"][len("io_in_bits"):] for p in ins] == \
           [p["name"][len("io_out_bits"):] for p in outs], name
    assert [p["w"] for p in ins] == [p["w"] for p in outs], name
    assert payload * 2 == tot, (name, payload, tot)
    return dict(name=name, ports=ports, head_text=head + "\n);", ins=ins, outs=outs,
                payload=payload, data_reg_bits=tot)


def wrap(names, indent, tail=""):
    lines, cur = [], indent + "{"
    for i, n in enumerate(names):
        piece = n + ("}" + tail if i == len(names) - 1 else ",")
        if len(cur) + len(piece) + 1 > 90 and not cur.endswith("{"):
            lines.append(cur)
            cur = indent + " " + piece
        else:
            cur += ("" if cur.endswith("{") else " ") + piece
    lines.append(cur)
    return "\n".join(lines)


def gen_variant(name):
    f = facts(name)
    ins = [p["name"] for p in f["ins"]]
    outs = [p["name"] for p in f["outs"]]
    fld = ", ".join(f'{p["name"][len("io_in_bits_"):] or "io_in_bits"}={p["w"]}b'
                    for p in f["ins"][:5])
    more = "" if len(ins) <= 5 else f" …共 {len(ins)} 个字段，明细见端口表"
    return f"""// =============================================================================
// {name} —— 带 valid 使能的两级打拍链（xs_DelayNWithValid_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   载荷 WIDTH = {f["payload"]} 位，分 {len(ins)} 个字段；级数固定 2 级；
//   golden 模块体 = 1 个异步复位的 valid 寄存器 + {f["data_reg_bits"]} 个无复位数据 reg 位
//     （2 级 × {f["payload"]} 位），无子模块；
//   端口 {len(f["ports"])} 个 = clock + reset + io_in_valid + {len(ins)} 入 + {len(outs)} 出。
//   载荷字段：{fld}{more}。
//   使用者：{USE[name]}。
//
// 结构：golden 同名端口表 -> 打包成一根 {f["payload"]} 位扁平载荷 -> 设参例化
//   xs_DelayNWithValid_core（使能与复位语义、不变式都在 xs_DelayNWithValid_core.sv
//   里讲）-> 拆包回 golden 的 io_out_bits_* 端口。本层只做拼包/拆包。
//   PORT_BITS_IN/OUT 用 $bits(golden 端口拼接) 算出来传给核：端口位宽抄错 time 0 $fatal。
// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module {name}(
{f["head_text"].split(chr(10), 1)[1]}

  localparam int unsigned GOLDEN_DATA_REG_BITS = {f["data_reg_bits"]};  // golden 两级数据 reg 位数
  localparam int unsigned PAYLOAD_W            = GOLDEN_DATA_REG_BITS / 2;

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_IN = $bits(
{wrap(ins, "    ")});
  localparam int unsigned PORT_BITS_OUT = $bits(
{wrap(outs, "    ")});

  logic [PAYLOAD_W-1:0] payload_in;
  logic [PAYLOAD_W-1:0] payload_out;

  assign payload_in =
{wrap(ins, "    ", ";")}

  xs_DelayNWithValid_core #(
    .WIDTH               (PAYLOAD_W),
    .GOLDEN_DATA_REG_BITS(GOLDEN_DATA_REG_BITS),
    .PORT_BITS_IN        (PORT_BITS_IN),
    .PORT_BITS_OUT       (PORT_BITS_OUT)
  ) u_core (
    .clock   (clock),
    .reset   (reset),
    .in_valid(io_in_valid),
    .d_in    (payload_in),
    .d_out   (payload_out)
  );

  assign
{wrap(outs, "    ", " = payload_out;")}

endmodule
"""


def slices(ports):
    tot = sum(p["w"] for p in ports)
    out, hi = [], tot - 1
    for p in ports:
        lo = hi - p["w"] + 1
        out.append((p["name"], hi, lo, p["w"]))
        hi = lo - 1
    assert hi == -1
    return out


def tbsig(name):
    return "dv0" if name == "DelayNWithValid" else "dv1"


TB_HEAD = """// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// DelayNWithValid 家族 2 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
//   （同一个 xs_DelayNWithValid_core 设不同 WIDTH）。
// 被测语义：valid 打一拍 + 两级"只在使能时更新"的数据寄存器；输入无效时输出保持。
//   只有 valid 寄存器带异步复位，两级数据寄存器无复位（上电 X），故用
//   $isunknown(golden 输出) 跳过尚未灌满的拍。
// 激励：io_in_valid 按 50% 随机（既有连续有效也有长时间无效，才测得到"保持"），
//   载荷逐位随机并混入全 0 / 全 1；reset 偶尔异步脉冲一拍。
// 覆盖闸：每个变体都要 (1) 有效比对 >= COV_MIN；(2) in_valid=1 与 in_valid=0
//   各 >= COV_MIN；(3) 输出**保持不变**（相邻拍相等）与**发生变化**各 >= COV_MIN
//   —— 只测流动不测保持的 tb 会在这里被判 FAIL；(4) 每个载荷位都见过 1 和 0。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  logic reset;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;
"""


def gen_tb():
    L, infos = [TB_HEAD], []
    for name in VARIANTS:
        f = facts(name)
        s, pw = tbsig(name), f["payload"]
        infos.append((name, s, f))
        L.append(f"  // ---- {name}: 载荷 {pw} 位 / {len(f['ins'])} 字段 ----")
        L.append(f"  logic {s}_in_valid;")
        L.append(f"  logic [{pw-1}:0] {s}_in;")
        L.append(f"  wire  [{pw-1}:0] g_{s}_out, i_{s}_out;")
        L.append(f"  logic [{pw-1}:0] {s}_ones, {s}_zeros, {s}_prev;")
        L.append(f"  int   {s}_checks, {s}_vld, {s}_idle, {s}_hold, {s}_move;")
        for tag, mod in (("g", name), ("i", name + "_xs")):
            conn = ["    .clock(clock)", "    .reset(reset)",
                    f"    .io_in_valid({s}_in_valid)"]
            for nm, hi, lo, w in slices(f["ins"]):
                conn.append(f"    .{nm}({s}_in[{hi}:{lo}])" if w > 1 else f"    .{nm}({s}_in[{hi}])")
            for nm, hi, lo, w in slices(f["outs"]):
                conn.append(f"    .{nm}({tag}_{s}_out[{hi}:{lo}])" if w > 1
                            else f"    .{nm}({tag}_{s}_out[{hi}])")
            L.append(f"  {mod} u_{tag}_{s} (")
            L.append(",\n".join(conn))
            L.append("  );")
        L.append("")

    drive, check, init, cov = [], [], [], []
    for name, s, f in infos:
        pw = f["payload"]
        drive.append(f"""    {s}_in_valid = ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       {s}_in = '0;
      1:       {s}_in = '1;
      default: for (int b = 0; b < {pw}; b++) {s}_in[b] = 1'($urandom);
    endcase""")
        check.append(f"""    if (!$isunknown(g_{s}_out)) begin
      checks++; {s}_checks++;
      {s}_ones  |= g_{s}_out;
      {s}_zeros |= ~g_{s}_out;
      if ({s}_in_valid) {s}_vld++; else {s}_idle++;
      if (!$isunknown({s}_prev)) begin
        if ({s}_prev === g_{s}_out) {s}_hold++; else {s}_move++;
      end
      {s}_prev = g_{s}_out;
      if (g_{s}_out !== i_{s}_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH {name} g=%0h i=%0h", $time, g_{s}_out, i_{s}_out);
      end
    end""")
        init.append(f"    {s}_in_valid = 0; {s}_in = '0; {s}_ones = '0; {s}_zeros = '0;"
                    f" {s}_prev = 'x;\n"
                    f"    {s}_checks = 0; {s}_vld = 0; {s}_idle = 0; {s}_hold = 0; {s}_move = 0;")
        cov.append(f"""    $display("  {name}: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/{pw} zeros=%0d/{pw}",
             {s}_checks, {s}_vld, {s}_idle, {s}_hold, {s}_move,
             $countones({s}_ones), $countones({s}_zeros));
    cov_fail += cov_short("{name} checks", {s}_checks)
              + cov_short("{name} valid",  {s}_vld)
              + cov_short("{name} idle",   {s}_idle)
              + cov_short("{name} hold",   {s}_hold)
              + cov_short("{name} move",   {s}_move);
    if (!(&{s}_ones) || !(&{s}_zeros)) begin
      $display("COVERAGE FAIL: {name} 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end""")

    nl = "\n"
    L.append(f"""
  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
{nl.join(drive)}
  endtask

  task automatic check_outputs();
{nl.join(check)}
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
{nl.join(init)}
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      check_outputs();        // 输出在 posedge 变，negedge 稳定
      drive_random_inputs();
      @(posedge clock);
      if ($urandom_range(0, 4999) == 0) begin   // 异步复位脉冲
        reset = 1'b1;
        #1 reset = 1'b0;
      end
    end
    $display("DelayNWithValid family checks=%0d errors=%0d", checks, errors);
{nl.join(cov)}
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
