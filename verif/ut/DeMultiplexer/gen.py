#!/usr/bin/env python3
"""生成 DeMultiplexer 家族的薄文件（rtl/frontend/）。

家族成员（G1 Frontend 闭包内，机械比对确认同形）：
  DeMultiplexer    4 出口，载荷 {blkPaddr 42b, vSetIdx 8b}，无 chosen 端口
  DeMultiplexer_1 10 出口，同样的载荷，多一个 io_chosen[3:0]
两者都是 ICacheMissUnit 的分发点：把一路 miss 请求投给第一个空闲的 MSHR。
形状完全一样（载荷广播 + 按 ready 的 lowest-index-wins 优先级链），
差别只有出口数和有没有 chosen 端口。
"""
import os, re

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/frontend"))
PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')

VARIANTS = {
    "DeMultiplexer":   "ICacheMissUnit：把取指 miss 投给 4 个取指 MSHR 中第一个空闲的",
    "DeMultiplexer_1": "ICacheMissUnit：把预取 miss 投给 10 个预取 MSHR 中第一个空闲的",
}


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
    return dict(ports=ports, head_text=head + "\n);",
                pw={p["name"]: p["w"] for p in ports})


def gen_variant(name):
    f = facts(name)
    ins = [p for p in f["ports"] if p["name"].startswith("io_in_bits_")]
    fields = [p["name"][len("io_in_bits_"):] for p in ins]
    width = sum(p["w"] for p in ins)
    n_out = sum(1 for p in f["ports"] if re.fullmatch(r'io_out_\d+_valid', p["name"]))
    has_chosen = "io_chosen" in f["pw"]
    chosen_w = f["pw"].get("io_chosen", 1)
    nports = len(f["ports"])
    assert nports == 2 + len(fields) + n_out * (2 + len(fields)) + int(has_chosen), name
    outs_of = lambda k: [f"io_out_{k}_bits_{fl}" for fl in fields]
    unpack = "\n".join(
        f"  assign {{{', '.join(outs_of(k))}}} = out_bits_flat[{n_out - 1 - k}*WIDTH +: WIDTH];"
        f"   // 第 {k} 个出口"
        for k in range(n_out))
    fld_desc = ", ".join(f"{fl}={p['w']}b" for fl, p in zip(fields, ins))
    chosen_line = ("    .chosen   (io_chosen)" if has_chosen else
                   "    .chosen   ()          // 本变体 golden 没有 chosen 端口")
    return f"""// =============================================================================
// {name} —— 一入多出解复用器（xs_DeMultiplexer_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   出口数 NUM_OUT = {n_out}；广播载荷 WIDTH = {width} 位，{len(fields)} 个字段：{fld_desc}；
//   chosen 端口：{'有，' + str(chosen_w) + ' 位 = clog2(' + str(n_out) + ')' if has_chosen else '无'}；
//   端口 {nports} 个 = in 的 ready/valid 2 根 + in 载荷 {len(fields)} 根
//                + {n_out} 个出口 ×(ready/valid + 载荷 {len(fields)} 根){' + chosen 1 根' if has_chosen else ''}；
//   golden 模块体 = 纯组合 assign，无寄存器 / 无时钟 / 无子模块。
//   使用者：{VARIANTS[name]}。
//
// 结构：golden 同名端口表 -> 载荷拼成 {width} 位、out_ready 按"出口 0 在最高位"拼成
//   位图 -> 设参例化 xs_DeMultiplexer_core（分发语义与不变式都在
//   xs_DeMultiplexer_core.sv 里讲）-> 把广播出来的载荷与 valid 拆回各出口端口。
// 自动生成：verif/ut/DeMultiplexer/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module {name}(
{f["head_text"].split(chr(10), 1)[1]}

  localparam int unsigned NUM_OUT = {n_out};
  localparam int unsigned WIDTH   = {width};

  logic [NUM_OUT-1:0]       out_ready_vec;
  logic [NUM_OUT-1:0]       out_valid_vec;
  logic [NUM_OUT*WIDTH-1:0] out_bits_flat;

  // 位序：出口 0 在最高位（与核里的优先级约定一致）
  assign out_ready_vec = {{{", ".join(f"io_out_{k}_ready" for k in range(n_out))}}};
  assign {{{", ".join(f"io_out_{k}_valid" for k in range(n_out))}}} = out_valid_vec;

  xs_DeMultiplexer_core #(
    .WIDTH         (WIDTH),
    .NUM_OUT       (NUM_OUT),
    .CHOSEN_W      ({chosen_w}),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_BITS_IN  ($bits({{{", ".join(p["name"] for p in ins)}}})),
    .PORT_BITS_OUT0($bits({{{", ".join(outs_of(0))}}})),
    .HAS_CHOSEN    (1'b{int(has_chosen)}),
    .GOLDEN_PORTS  ({nports}),
    .GOLDEN_FIELDS ({len(fields)})
  ) u_core (
    .in_valid (io_in_valid),
    .in_ready (io_in_ready),
    .in_bits  ({{{", ".join(p["name"] for p in ins)}}}),
    .out_ready(out_ready_vec),
    .out_valid(out_valid_vec),
    .out_bits (out_bits_flat),
{chosen_line}
  );

{unpack}

endmodule
"""




# ---------------------------------------------------------------------------
# 家族 tb：2 变体一个对照台
# ---------------------------------------------------------------------------
def analyse(name):
    f = facts(name)
    ins = [p for p in f["ports"] if p["name"].startswith("io_in_bits_")]
    fields = [p["name"][len("io_in_bits_"):] for p in ins]
    width = sum(p["w"] for p in ins)
    n_out = sum(1 for p in f["ports"] if re.fullmatch(r'io_out_\d+_valid', p["name"]))
    has_chosen = "io_chosen" in f["pw"]
    chosen_w = f["pw"].get("io_chosen", 0)
    return f, ins, fields, width, n_out, has_chosen, chosen_w


TB_HEAD = """// 自动生成：verif/ut/DeMultiplexer/gen.py（读 G1 golden）—— 勿手改
// DeMultiplexer 家族双例化逐拍比对：golden DeMultiplexer / DeMultiplexer_1 vs 各自的 _xs
//   （同一个 xs_DeMultiplexer_core 设不同 NUM_OUT / 有无 chosen）。
// 被测语义：纯组合；载荷广播给所有出口，valid 按 ready 的 lowest-index-wins 优先级
//   链逐级屏蔽；chosen（只有 _1 有）= 第一个 ready 的出口下标，全不 ready 给末位。
// 激励：out_ready 位图按"全 0 / 单热 / 稀疏 / 全随机"混合，载荷逐位随机，
//   in_valid 一半概率为 0。
// 覆盖闸：每个变体都要 (1) 有效比对 >= COV_MIN；(2) **每个出口**被选中（= 它是第一个
//   ready 的）>= COV_MIN；(3) 一个出口都不 ready >= COV_MIN；(4) in_valid=0 >= COV_MIN；
//   (5) 每个广播载荷位都被观察到过 1 和 0。任何一项不足即 TEST FAILED。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;
"""


def tbsig(name):
    return "dm0" if name == "DeMultiplexer" else "dm1"


def gen_tb():
    L, infos = [TB_HEAD], []
    for name in VARIANTS:
        f, ins, fields, width, n_out, has_chosen, chosen_w = analyse(name)
        s = tbsig(name)
        infos.append((name, s, f, ins, fields, width, n_out, has_chosen, chosen_w))
        cw = chosen_w if has_chosen else 1
        L.append(f"  // ---- {name}: {n_out} 出口 / 载荷 {width} 位 / chosen={'有' if has_chosen else '无'} ----")
        L.append(f"  logic {s}_in_valid;")
        L.append(f"  logic [{width-1}:0] {s}_in_bits;")
        L.append(f"  logic [{n_out-1}:0] {s}_ready;   // 位 {n_out-1} = 出口 0")
        L.append(f"  wire  g_{s}_in_ready, i_{s}_in_ready;")
        L.append(f"  wire  [{n_out-1}:0] g_{s}_valid, i_{s}_valid;")
        L.append(f"  wire  [{n_out*width-1}:0] g_{s}_bits, i_{s}_bits;")
        if has_chosen:
            L.append(f"  wire  [{cw-1}:0] g_{s}_chosen, i_{s}_chosen;")
        L.append(f"  logic [{n_out*width-1}:0] {s}_ones, {s}_zeros;")
        L.append(f"  int   {s}_checks, {s}_noready, {s}_idle;")
        L.append(f"  int   {s}_pick [{n_out}];")
        for tag, mod in (("g", name), ("i", name + "_xs")):
            conn = [f"    .io_in_valid({s}_in_valid)", f"    .io_in_ready({tag}_{s}_in_ready)"]
            hi = width - 1
            for pp in ins:
                lo = hi - pp["w"] + 1
                conn.append(f"    .{pp['name']}({s}_in_bits[{hi}:{lo}])" if pp["w"] > 1
                            else f"    .{pp['name']}({s}_in_bits[{hi}])")
                hi = lo - 1
            for k in range(n_out):
                conn.append(f"    .io_out_{k}_ready({s}_ready[{n_out-1-k}])")
                conn.append(f"    .io_out_{k}_valid({tag}_{s}_valid[{n_out-1-k}])")
                hi = (n_out - k) * width - 1
                for fl, pp in zip(fields, ins):
                    lo = hi - pp["w"] + 1
                    pn = f"io_out_{k}_bits_{fl}"
                    conn.append(f"    .{pn}({tag}_{s}_bits[{hi}:{lo}])" if pp["w"] > 1
                                else f"    .{pn}({tag}_{s}_bits[{hi}])")
                    hi = lo - 1
            if has_chosen:
                conn.append(f"    .io_chosen({tag}_{s}_chosen)")
            L.append(f"  {mod} u_{tag}_{s} (")
            L.append(",\n".join(conn))
            L.append("  );")
        L.append("")

    drive, check, init, cov = [], [], [], []
    for name, s, f, ins, fields, width, n_out, has_chosen, chosen_w in infos:
        cmp_g = f"{{g_{s}_in_ready, g_{s}_valid, g_{s}_bits" + (f", g_{s}_chosen}}" if has_chosen else "}")
        cmp_i = f"{{i_{s}_in_ready, i_{s}_valid, i_{s}_bits" + (f", i_{s}_chosen}}" if has_chosen else "}")
        drive.append(f"""    {s}_in_valid = ($urandom_range(0, 1) == 1);
    {s}_ready = {n_out}'(pick_bits({n_out}));
    for (int b = 0; b < {width}; b++) {s}_in_bits[b] = 1'($urandom);""")
        check.append(f"""    if (!$isunknown({cmp_g})) begin
      checks++; {s}_checks++;
      {s}_ones  |= g_{s}_bits;
      {s}_zeros |= ~g_{s}_bits;
      if (!{s}_in_valid) {s}_idle++;
      if ({s}_ready == '0) {s}_noready++;
      else for (int k = {n_out} - 1; k >= 0; k--)
        if ({s}_ready[k]) begin {s}_pick[k]++; break; end
      if ({cmp_g} !== {cmp_i}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH {name} rdy=%0b g=%0h i=%0h", $time,
                   {s}_ready, g_{s}_valid, i_{s}_valid);
      end
    end""")
        init.append(f"    {s}_in_valid = 0; {s}_in_bits = '0; {s}_ready = '0;"
                    f" {s}_ones = '0; {s}_zeros = '0;\n"
                    f"    {s}_checks = 0; {s}_noready = 0; {s}_idle = 0;\n"
                    f"    for (int k = 0; k < {n_out}; k++) {s}_pick[k] = 0;")
        cov.append(f"""    $write("  {name}: checks=%0d noready=%0d idle=%0d pick=",
           {s}_checks, {s}_noready, {s}_idle);
    for (int k = {n_out} - 1; k >= 0; k--) $write("%0d ", {s}_pick[k]);
    $display("ones=%0d/{n_out*width} zeros=%0d/{n_out*width}",
             $countones({s}_ones), $countones({s}_zeros));
    cov_fail += cov_short("{name} checks",  {s}_checks)
              + cov_short("{name} noready", {s}_noready)
              + cov_short("{name} idle",    {s}_idle);
    for (int k = 0; k < {n_out}; k++)
      cov_fail += cov_short($sformatf("{name} 出口 %0d 被选中", {n_out}-1-k), {s}_pick[k]);
    if (!(&{s}_ones) || !(&{s}_zeros)) begin
      $display("COVERAGE FAIL: {name} 有广播载荷位从未观察到 1 或 0"); cov_fail++;
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

  // ready 位图：全 0 / 单热 / 稀疏 / 全随机 四种混合
  function automatic int unsigned pick_bits(int unsigned n);
    int unsigned v;
    case ($urandom_range(0, 3))
      0: v = 0;
      1: v = 1 << $urandom_range(0, n - 1);
      2: v = $urandom & $urandom;
      default: v = $urandom;
    endcase
    return v & ((1 << n) - 1);
  endfunction

  task automatic drive_random_inputs();
{nl.join(drive)}
  endtask

  task automatic check_outputs();
{nl.join(check)}
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
{nl.join(init)}
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("DeMultiplexer family checks=%0d errors=%0d", checks, errors);
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
