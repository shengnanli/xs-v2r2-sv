#!/usr/bin/env python3
"""生成 verif/ut/IndexableCAMTemplate/tb.sv —— 家族 5 变体共用一个双例化对照台。

家族参数表直接来自 G1 golden 的端口宽度（键宽 = io_r_req_0_idx 宽度，
条目数 = io_r_resp_0_* 个数），改动后重跑本脚本即可刷新 tb。
"""
import os

VARIANTS = [
    ("IndexableCAMTemplate",     9,  8),
    ("IndexableCAMTemplate_32", 11,  8),
    ("IndexableCAMTemplate_33",  8, 16),
    ("IndexableCAMTemplate_41",  8,  4),
    ("IndexableCAMTemplate_43",  9,  4),
]
HERE = os.path.dirname(os.path.abspath(__file__))


def idxw(ne):
    return max(1, (ne - 1).bit_length())


def sig(name):
    return name.replace("IndexableCAMTemplate", "cam")


def inst(name, ne, suffix, mod):
    s = sig(name)
    lines = [f"  {mod} u_{suffix}_{s} ("]
    lines.append(f"    .clock             ({s}_clock),")
    lines.append(f"    .io_r_req_0_idx    ({s}_rkey),")
    for i in range(ne):
        lines.append(f"    .io_r_resp_0_{i}{' ' * (5 - len(str(i)))}({suffix}_{s}_match[{i}]),")
    lines.append(f"    .io_w_valid        ({s}_wvalid),")
    lines.append(f"    .io_w_bits_data_idx({s}_wkey),")
    lines.append(f"    .io_w_bits_index   ({s}_widx)")
    lines.append("  );")
    return "\n".join(lines)


out = []
out.append("""// 自动生成：verif/ut/IndexableCAMTemplate/gen.py —— 勿手改
// IndexableCAMTemplate 家族 5 变体双例化逐拍比对：
//   golden <V> vs 可读重写 <V>_xs（同一个 xs_IndexableCAMTemplate_core 设不同参）。
// 被测语义：写口按索引写入条目（同步），读口把查询键与全部条目并行比较（组合），
//   输出逐条目命中位图。条目寄存器无复位，上电为 X —— 故先做一轮 warmup 把每个
//   变体的每个条目都写一遍，之后两侧才有可比的定值。
// 覆盖闸（小模块最容易假绿）：每个变体都必须
//   (1) 每个条目索引至少被写过一次；
//   (2) 命中（match != 0）与未命中（match == 0）各至少 COV_MIN 次；
//   (3) 有效比对次数 checks 至少 COV_MIN 次。
//   任何一项为 0 / 不足即判 FAIL，不看 errors。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 500;
  bit clock = 0;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;
""")

for name, ew, ne in VARIANTS:
    s = sig(name)
    iw = idxw(ne)
    out.append(f"""  // ---- {name}: 键 {ew} 位 / 条目 {ne} 项 / 索引 {iw} 位 ----
  logic            {s}_clock;
  logic [{ew - 1}:0] {s}_rkey;
  logic            {s}_wvalid;
  logic [{ew - 1}:0] {s}_wkey;
  logic [{iw - 1}:0] {s}_widx;
  wire  [{ne - 1}:0] g_{s}_match;
  wire  [{ne - 1}:0] i_{s}_match;
  int   {s}_checks, {s}_hit, {s}_miss;
  logic [{ne - 1}:0] {s}_written;

{inst(name, ne, 'g', name)}

{inst(name, ne, 'i', name + '_xs')}
""")

out.append("""  // 所有变体共用同一个时钟沿（同一个 clock 网）
""")
for name, ew, ne in VARIANTS:
    out.append(f"  assign {sig(name)}_clock = clock;")
out.append("")

# drive / check tasks
drive = []
check = []
init = []
for name, ew, ne in VARIANTS:
    s = sig(name)
    iw = idxw(ne)
    # 键池：宽度取 min(ew, 4) 位，保证随机键经常撞上已写条目
    drive.append(f"""    // {name}
    {s}_wvalid = ($urandom_range(0, 3) != 0);
    {s}_widx   = {iw}'($urandom);
    {s}_wkey   = {ew}'($urandom_range(0, KEY_POOL - 1));
    {s}_rkey   = {ew}'($urandom_range(0, KEY_POOL - 1));
    if ({s}_wvalid) {s}_written[{s}_widx] = 1'b1;""")
    check.append(f"""    if (!$isunknown(g_{s}_match)) begin
      checks++; {s}_checks++;
      if (|g_{s}_match) {s}_hit++; else {s}_miss++;
      if (g_{s}_match !== i_{s}_match) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH {name} rkey=%0h g=%0h i=%0h",
                   $time, {s}_rkey, g_{s}_match, i_{s}_match);
      end
    end""")
    init.append(f"""    {s}_wvalid = 1'b0; {s}_widx = '0; {s}_wkey = '0; {s}_rkey = '0;
    {s}_checks = 0; {s}_hit = 0; {s}_miss = 0; {s}_written = '0;""")

warm = []
for name, ew, ne in VARIANTS:
    s = sig(name)
    iw = idxw(ne)
    warm.append(f"""      if (k < {ne}) begin
        {s}_wvalid = 1'b1;
        {s}_widx   = {iw}'(k);
        {s}_wkey   = {ew}'($urandom);
        {s}_written[{s}_widx] = 1'b1;
      end else {s}_wvalid = 1'b0;""")

cov = []
for name, ew, ne in VARIANTS:
    s = sig(name)
    cov.append(f"""    $display("  {name}: checks=%0d hit=%0d miss=%0d written=%0h/%0h",
             {s}_checks, {s}_hit, {s}_miss, {s}_written, {{{ne}{{1'b1}}}});
    if ({s}_written !== {{{ne}{{1'b1}}}}) begin
      $display("COVERAGE FAIL: {name} 有条目从未被写过"); cov_fail++;
    end
    if ({s}_checks < COV_MIN || {s}_hit < COV_MIN || {s}_miss < COV_MIN) begin
      $display("COVERAGE FAIL: {name} 事件数不足 (checks/hit/miss 各需 >= %0d)", COV_MIN);
      cov_fail++;
    end""")

nl = "\n"
out.append(f"""
  localparam int KEY_POOL = 24;   // 键池比最大条目数略大：随机键既常命中也常落空
  int cov_fail = 0;

  task automatic drive_random_inputs();
{nl.join(drive)}
  endtask

  task automatic check_outputs();
{nl.join(check)}
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
{nl.join(init)}
    // warmup：逐条目写满，让两侧条目寄存器脱离 X
    for (int k = 0; k < 16; k++) begin
      @(negedge clock);
{nl.join(warm)}
      @(posedge clock);
    end
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("IndexableCAMTemplate family checks=%0d errors=%0d", checks, errors);
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

open(os.path.join(HERE, "tb.sv"), "w").write("\n".join(out))
print("wrote tb.sv")
