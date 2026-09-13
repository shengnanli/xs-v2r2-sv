#!/usr/bin/env python3
"""生成 ICache 侧固定优先级仲裁器家族的薄文件（rtl/frontend/）与家族 tb。

家族成员（G1 Frontend 闭包内，机械比对确认同形）：
  Arbiter2_ICacheMissReq  2 入口，载荷 {blkPaddr 42b, vSetIdx 8b} = 50b
                          用在 ICacheMainPipe / IPrefetchPipe（各一处）
  Arbiter5_MSHRAcquire    5 入口，载荷 {acquire_source 4b, acquire_address 48b,
                          vSetIdx 8b} = 60b，用在 ICacheMissUnit
两者形状完全一样（lowest-index-wins、无锁定、纯组合），差别只有入口数与载荷字段；
Arbiter5 额外有一处**常量替换**：golden 里前 4 路没有 acquire_source 端口，仲裁器
直接替它们填 4'h0..4'h3，只有第 5 路用自己的端口值 —— 这个常量由薄文件在拼载荷
时填入，核看到的仍然是"每路一根等宽载荷"。
"""
import os, re, sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/frontend"))
PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')

# name -> (入口数, 使用者说明)
VARIANTS = {
    "Arbiter2_ICacheMissReq": (2, "ICacheMainPipe 与 IPrefetchPipe 各一处：把两路 miss 请求并成一路"),
    "Arbiter5_MSHRAcquire":   (5, "ICacheMissUnit：把 4 个取指 MSHR + 1 路预取的 Acquire 并成一路"),
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
    return dict(name=name, ports=ports, head_text=head + "\n);",
                pw={p["name"]: p["w"] for p in ports})


def analyse(name):
    f = facts(name)
    n_in = VARIANTS[name][0]
    outs = [p for p in f["ports"] if p["name"].startswith("io_out_bits_")]
    fields = [p["name"][len("io_out_bits_"):] for p in outs]
    width = sum(p["w"] for p in outs)
    n_bits_ports = sum(1 for p in f["ports"] if "_bits_" in p["name"])
    assert len(f["ports"]) == 2 * n_in + 2 + n_bits_ports, name
    # 每一路的载荷来源：有同名端口就用端口，没有就填常量（= 该路的下标）
    ways = []
    for k in range(n_in):
        terms = []
        for fld, p in zip(fields, outs):
            pn = f"io_in_{k}_bits_{fld}"
            terms.append(pn if pn in f["pw"] else f"{p['w']}'d{k}")
        ways.append(terms)
    return f, n_in, fields, outs, width, n_bits_ports, ways


def gen_variant(name):
    f, n_in, fields, outs, width, n_bits_ports, ways = analyse(name)
    ports = f["head_text"].split("\n", 1)[1]
    const_note = ""
    if any(t[0].endswith(f"'d{k}") for k, t in enumerate(ways)):
        const_note = ("\n//   常量替换：前 %d 路 golden 没有 %s 端口，仲裁器替它们填该路下标常量，"
                      "\n//   只有最后一路用自己的端口值 —— 薄文件在拼载荷时填入。"
                      % (sum(1 for t in ways if "'d" in t[0]), fields[0]))
    way_lines = "\n".join(
        f"  assign way_bits[{n_in - 1 - k}] = {{" + ", ".join(ways[k]) + "};"
        f"   // 第 {k} 路（优先级第 {k + 1} 高）"
        for k in range(n_in))
    fld_desc = ", ".join(f"{fl}={p['w']}b" for fl, p in zip(fields, outs))
    return f"""// =============================================================================
// {name} —— 固定优先级仲裁器（xs_FixedPriorityArbiter_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   入口数 NUM_IN = {n_in}；载荷 WIDTH = {width} 位，{len(fields)} 个字段：{fld_desc}；
//   端口 {len(f["ports"])} 个 = 每路 ready/valid 共 {2 * n_in} 根 + out_ready/out_valid 2 根
//                + {n_bits_ports} 根 *_bits_* 载荷端口；
//   golden 模块体 = 纯组合 assign，无寄存器 / 无时钟 / 无子模块。
//   使用者：{VARIANTS[name][1]}。{const_note}
//
// 结构：golden 同名端口表 -> 每路载荷按输出字段顺序 MSB 优先拼成 {width} 位 ->
//   按"优先级从高到低"MSB 优先拼成 in_bits -> 设参例化 xs_FixedPriorityArbiter_core
//   （仲裁语义与不变式都在 xs_FixedPriorityArbiter_core.sv 里讲）-> 拆包回输出端口。
// 自动生成：verif/ut/Arbiter2_ICacheMissReq/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module {name}(
{ports}

  localparam int unsigned NUM_IN  = {n_in};
  localparam int unsigned WIDTH   = {width};

  // 每一路的载荷（下标 {n_in - 1} = 第 0 路 = 优先级最高，与 in_valid 位序一致）
  logic [WIDTH-1:0] way_bits [NUM_IN];
{way_lines}

  logic [NUM_IN*WIDTH-1:0] in_bits_flat;
  for (genvar k = 0; k < NUM_IN; k++) begin : g_pack
    assign in_bits_flat[k*WIDTH +: WIDTH] = way_bits[k];
  end

  logic [NUM_IN-1:0] in_valid_vec;
  logic [NUM_IN-1:0] in_ready_vec;
  assign in_valid_vec = {{{", ".join(f"io_in_{k}_valid" for k in range(n_in))}}};
  assign {{{", ".join(f"io_in_{k}_ready" for k in range(n_in))}}} = in_ready_vec;

  logic [WIDTH-1:0] out_bits_flat;

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_BITS_OUT    ($bits({{{", ".join(p["name"] for p in outs)}}})),
    .PORT_BITS_LAST_IN($bits({{{", ".join(ways[n_in - 1])}}})),
    .GOLDEN_PORTS     ({len(f["ports"])}),
    .GOLDEN_BITS_PORTS({n_bits_ports})
  ) u_core (
    .in_valid (in_valid_vec),
    .in_ready (in_ready_vec),
    .in_bits  (in_bits_flat),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_bits_flat)
  );

  assign {{{", ".join(p["name"] for p in outs)}}} = out_bits_flat;

endmodule
"""




# ---------------------------------------------------------------------------
# 家族 tb：2 变体一个对照台
# ---------------------------------------------------------------------------
TB_HEAD = """// 自动生成：verif/ut/Arbiter2_ICacheMissReq/gen.py（读 G1 golden）—— 勿手改
// ICache 固定优先级仲裁器家族双例化逐拍比对：
//   golden Arbiter2_ICacheMissReq / Arbiter5_MSHRAcquire vs 各自的 _xs
//   （同一个 xs_FixedPriorityArbiter_core 设不同 WIDTH/NUM_IN）。
// 被测语义：纯组合、lowest-index-wins、无锁定；一路都没请求时 out_bits 取最后一路
//   （golden 三元链的兜底分支，输出无意义但必须逐位一致，所以照样比）。
// 激励：valid 位图按"全 0 / 单热 / 稀疏 / 全随机"混合，各路载荷逐位随机，
//   out_ready 一半概率为 0（覆盖 in_ready 全 0 的情形）。
// 覆盖闸：每个变体都要 (1) 有效比对 >= COV_MIN；(2) **每一路**单独胜出 >= COV_MIN；
//   (3) 无人请求（out_valid=0）>= COV_MIN；(4) out_ready=0 >= COV_MIN；
//   (5) 每个输出位都被观察到过 1 和 0。任何一项不足即 TEST FAILED。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;
"""


def tbsig(name):
    return "a2" if name.startswith("Arbiter2") else "a5"


def gen_tb():
    L, infos = [TB_HEAD], []
    for name in VARIANTS:
        f, n_in, fields, outs, width, n_bits_ports, ways = analyse(name)
        s = tbsig(name)
        infos.append((name, s, n_in, width, f, fields, outs))
        L.append(f"  // ---- {name}: {n_in} 入口 / 载荷 {width} 位 ----")
        L.append(f"  logic [{n_in-1}:0] {s}_valid;")
        L.append(f"  logic {s}_out_ready;")
        L.append(f"  logic [{n_in*width-1}:0] {s}_bits;   // 高位段 = 第 0 路")
        L.append(f"  wire  [{n_in-1}:0] g_{s}_ready, i_{s}_ready;")
        L.append(f"  wire  g_{s}_out_valid, i_{s}_out_valid;")
        L.append(f"  wire  [{width-1}:0] g_{s}_out_bits, i_{s}_out_bits;")
        L.append(f"  logic [{width-1}:0] {s}_ones, {s}_zeros;")
        L.append(f"  int   {s}_checks, {s}_none, {s}_stall;")
        L.append(f"  int   {s}_win [{n_in}];")
        for tag, mod in (("g", name), ("i", name + "_xs")):
            conn = []
            for k in range(n_in):
                conn.append(f"    .io_in_{k}_ready({tag}_{s}_ready[{n_in-1-k}])")
                conn.append(f"    .io_in_{k}_valid({s}_valid[{n_in-1-k}])")
                hi = (n_in - k) * width - 1
                for fl, pp in zip(fields, outs):
                    lo = hi - pp["w"] + 1
                    pn = f"io_in_{k}_bits_{fl}"
                    if pn in f["pw"]:
                        conn.append(f"    .{pn}({s}_bits[{hi}:{lo}])" if pp["w"] > 1
                                    else f"    .{pn}({s}_bits[{hi}])")
                    hi = lo - 1
            conn.append(f"    .io_out_ready({s}_out_ready)")
            conn.append(f"    .io_out_valid({tag}_{s}_out_valid)")
            hi = width - 1
            for pp in outs:
                lo = hi - pp["w"] + 1
                conn.append(f"    .{pp['name']}({tag}_{s}_out_bits[{hi}:{lo}])" if pp["w"] > 1
                            else f"    .{pp['name']}({tag}_{s}_out_bits[{hi}])")
                hi = lo - 1
            L.append(f"  {mod} u_{tag}_{s} (")
            L.append(",\n".join(conn))
            L.append("  );")
        L.append("")

    drive, check, init, cov = [], [], [], []
    for name, s, n_in, width, f, fields, outs in infos:
        drive.append(f"""    {s}_valid = {n_in}'(pick_bits({n_in}));
    {s}_out_ready = ($urandom_range(0, 1) == 1);
    for (int b = 0; b < {n_in*width}; b++) {s}_bits[b] = 1'($urandom);""")
        check.append(f"""    if (!$isunknown({{g_{s}_ready, g_{s}_out_valid, g_{s}_out_bits}})) begin
      checks++; {s}_checks++;
      {s}_ones  |= g_{s}_out_bits;
      {s}_zeros |= ~g_{s}_out_bits;
      if (!{s}_out_ready) {s}_stall++;
      if ({s}_valid == '0) {s}_none++;
      else for (int k = {n_in} - 1; k >= 0; k--)
        if ({s}_valid[k]) begin {s}_win[k]++; break; end
      if ({{g_{s}_ready, g_{s}_out_valid, g_{s}_out_bits}} !==
          {{i_{s}_ready, i_{s}_out_valid, i_{s}_out_bits}}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH {name} valid=%0b rdy=%0b/%0b bits=%0h/%0h", $time,
                   {s}_valid, g_{s}_ready, i_{s}_ready, g_{s}_out_bits, i_{s}_out_bits);
      end
    end""")
        init.append(f"    {s}_valid = '0; {s}_bits = '0; {s}_out_ready = 0;"
                    f" {s}_ones = '0; {s}_zeros = '0;\n"
                    f"    {s}_checks = 0; {s}_none = 0; {s}_stall = 0;\n"
                    f"    for (int k = 0; k < {n_in}; k++) {s}_win[k] = 0;")
        cov.append(f"""    $write("  {name}: checks=%0d none=%0d stall=%0d win=",
           {s}_checks, {s}_none, {s}_stall);
    for (int k = {n_in} - 1; k >= 0; k--) $write("%0d ", {s}_win[k]);
    $display("ones=%0d/{width} zeros=%0d/{width}", $countones({s}_ones), $countones({s}_zeros));
    cov_fail += cov_short("{name} checks", {s}_checks)
              + cov_short("{name} none",   {s}_none)
              + cov_short("{name} stall",  {s}_stall);
    for (int k = 0; k < {n_in}; k++)
      cov_fail += cov_short($sformatf("{name} 第 %0d 路胜出", {n_in}-1-k), {s}_win[k]);
    if (!(&{s}_ones) || !(&{s}_zeros)) begin
      $display("COVERAGE FAIL: {name} 有输出位从未观察到 1 或 0"); cov_fail++;
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

  // valid 位图：全 0 / 单热 / 稀疏 / 全随机 四种混合
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
    $display("Arbiter family checks=%0d errors=%0d", checks, errors);
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
