#!/usr/bin/env python3
"""生成 PriorityMuxModule 家族的变体薄文件（rtl/frontend/）与家族 tb。

事实全部从 G1 golden 现读（gen_facts.py 解析端口表 + 三元链）。
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_facts import facts

HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/frontend"))

# Predictor 里各自负责哪一类预测状态（名字取自 golden 的端口前缀）
USE = {
    "PriorityMuxModule":    "预测目标 PC（target，50 位虚地址）",
    "PriorityMuxModule_4":  "折叠全局历史 FGH（17 条 folded_hist，共 140 位）",
    "PriorityMuxModule_8":  "全局历史指针 GHPtr（flag + 8 位 value）",
    "PriorityMuxModule_12": "AFHOB 全历史外置缓冲（23 个 1 位 bits 字段）",
    "PriorityMuxModule_16": "分支序号 one-hot BrNumOH（3 位）",
    "PriorityMuxModule_20": "新历史比特 new_bit（1 位；本变体只有 3 路 sel）",
}
VARIANTS = list(USE)


def wrap(names, indent, open_="{", close="}"):
    lines, cur = [], indent + open_
    for i, n in enumerate(names):
        piece = n + (close if i == len(names) - 1 else ",")
        if len(cur) + len(piece) + 1 > 92 and not cur.endswith(open_):
            lines.append(cur)
            cur = indent + " " * len(open_) + piece
        else:
            cur += ("" if cur.endswith(open_) else " ") + piece
    lines.append(cur)
    return "\n".join(lines)


def gen_variant(name):
    f = facts(name)
    nw, nf, pw = f["num_ways"], f["num_fields"], f["payload"]
    outs = [x["out"] for x in f["fields"]]
    ways = [[x["srcs"][w] for x in f["fields"]] for w in range(nw)]
    dflts = [x["dflt"] for x in f["fields"]]
    src_all = [n for way in ways for n in way]
    fld_desc = ", ".join(f'{x["out"][len("out_res"):].lstrip("_") or "out_res"}={x["w"]}b'
                         for x in f["fields"][:4])
    more = "" if nf <= 4 else f" …共 {nf} 个字段，明细见端口表"
    ports = f["head_text"].split("\n", 1)[1]
    sel_desc = " > ".join(f["sels"])
    return f"""// =============================================================================
// {name} —— 带兜底源的优先级选择器（xs_PriorityMuxModule_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   候选路数 NUM_WAYS = {nw}（各带一个 sel）+ 1 路兜底源（无 sel）；
//   载荷字段 NUM_FIELDS = {nf}，打平后 WIDTH = {pw} 位；
//   端口 {len(f["ports"])} 个 = {nw} 个 sel + ({nw} 路 + 兜底 + 输出) × {nf} 个字段；
//   golden 模块体 = {nf} 条纯组合三元链，无寄存器 / 无时钟 / 无子模块。
//   优先级（高 -> 低）：{sel_desc}，全不成立则取 {dflts[0].split("_src")[0]}_src*。
//   载荷字段：{fld_desc}{more}。
//   用途：Predictor 的 {USE[name]}。
//
// 结构：golden 同名端口表 -> 把每一路的全部字段按输出顺序 MSB 优先拼成一根
//   {pw} 位载荷 -> 设参例化 xs_PriorityMuxModule_core（核体见
//   xs_PriorityMuxModule_core.sv，优先级语义与不变式都在那里讲）-> 拆包回输出端口。
//   PORT_BITS_* 与 GOLDEN_PORTS 用 $bits(端口拼接) / 端口数算出来传给核：
//   任何字段位宽、路数、字段数抄错，time 0 直接 $fatal。
// 自动生成：verif/ut/PriorityMuxModule/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module {name}(
{ports}

  localparam int unsigned NUM_WAYS      = {nw};
  localparam int unsigned NUM_FIELDS    = {nf};
  localparam int unsigned GOLDEN_PORTS  = {len(f["ports"])};   // golden 端口总数
  localparam int unsigned PAYLOAD_W     = {pw};

  // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
  localparam int unsigned PORT_BITS_SRC = $bits(
{wrap(src_all, "    ")});
  localparam int unsigned PORT_BITS_DFLT = $bits(
{wrap(dflts, "    ")});
  localparam int unsigned PORT_BITS_OUT = $bits(
{wrap(outs, "    ")});

  logic [PAYLOAD_W-1:0] res;

  xs_PriorityMuxModule_core #(
    .WIDTH         (PAYLOAD_W),
    .NUM_WAYS      (NUM_WAYS),
    .NUM_FIELDS    (NUM_FIELDS),
    .GOLDEN_PORTS  (GOLDEN_PORTS),
    .PORT_BITS_SRC (PORT_BITS_SRC),
    .PORT_BITS_DFLT(PORT_BITS_DFLT),
    .PORT_BITS_OUT (PORT_BITS_OUT)
  ) u_core (
    // sel / src 都按"优先级从高到低"MSB 优先拼接
    .sel(
{wrap(f["sels"], "      ")}),
    .src(
{wrap(src_all, "      ")}),
    .dflt(
{wrap(dflts, "      ")}),
    .res(res)
  );

  assign
{wrap(outs, "    ", close="} = res;")}

endmodule
"""


# ---------------------------------------------------------------------------
# 家族 tb：6 变体一个对照台
# ---------------------------------------------------------------------------
def sig(name):
    return "pm0" if name == "PriorityMuxModule" else "pm" + name[len("PriorityMuxModule_"):]


TB_HEAD = """// 自动生成：verif/ut/PriorityMuxModule/gen.py（读 G1 golden）—— 勿手改
// PriorityMuxModule 家族 6 变体双例化逐拍比对：
//   golden <V> vs 可读重写 <V>_xs（同一个 xs_PriorityMuxModule_core 设不同参）。
// 被测语义：纯组合优先级选择——最高优先级的有效 sel 决定输出，全无效取兜底源。
// 激励：sel 位图按"稀疏 / 单热 / 全 0 / 全随机"混合，保证每一路都真的被选中过，
//   也保证兜底路被走到；各路源数据逐位随机。
// 覆盖闸（纯组合小模块最容易假绿）：每个变体都必须
//   (1) 有效比对次数 >= COV_MIN；
//   (2) **每一路** sel 单独胜出的次数 >= COV_MIN，兜底路命中次数也 >= COV_MIN
//       —— 只跑到一两条分支就报 errors=0 的 tb 在这里会被判 FAIL；
//   (3) 每一个输出位都被观察到过 1 和 0。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0;
  int checks = 0;
  int cov_fail = 0;
  always #5 clock = ~clock;
"""


def gen_tb():
    L, infos = [TB_HEAD], []
    for name in VARIANTS:
        f = facts(name)
        s, nw, pw = sig(name), f["num_ways"], f["payload"]
        infos.append((name, s, f))
        L.append(f"  // ---- {name}: {nw} 路 + 兜底 / 载荷 {pw} 位 / {f['num_fields']} 字段 ----")
        L.append(f"  logic [{nw-1}:0] {s}_sel;")
        L.append(f"  logic [{nw*pw-1}:0] {s}_src;")
        L.append(f"  logic [{pw-1}:0] {s}_dflt;")
        L.append(f"  wire  [{pw-1}:0] g_{s}_res;")
        L.append(f"  wire  [{pw-1}:0] i_{s}_res;")
        L.append(f"  logic [{pw-1}:0] {s}_ones, {s}_zeros;")
        L.append(f"  int   {s}_checks, {s}_dflt_hit;")
        L.append(f"  int   {s}_way_hit [{nw}];")
        # 端口连接：把扁平载荷按字段切片接回 golden 的具名端口
        for tag, mod in (("g", name), ("i", name + "_xs")):
            conn = []
            for w, selname in enumerate(f["sels"]):
                # sel MSB 优先：第 w 路（0=最高优先）对应 sel[nw-1-w]
                conn.append(f"    .{selname}({s}_sel[{nw-1-w}])")
            hi = nw * pw - 1
            for w in range(nw):
                for fld in f["fields"]:
                    lo = hi - fld["w"] + 1
                    nmm = fld["srcs"][w]
                    conn.append(f"    .{nmm}({s}_src[{hi}:{lo}])" if fld["w"] > 1
                                else f"    .{nmm}({s}_src[{hi}])")
                    hi = lo - 1
            assert hi == -1
            hi = pw - 1
            for fld in f["fields"]:
                lo = hi - fld["w"] + 1
                conn.append(f"    .{fld['dflt']}({s}_dflt[{hi}:{lo}])" if fld["w"] > 1
                            else f"    .{fld['dflt']}({s}_dflt[{hi}])")
                hi = lo - 1
            hi = pw - 1
            for fld in f["fields"]:
                lo = hi - fld["w"] + 1
                conn.append(f"    .{fld['out']}({tag}_{s}_res[{hi}:{lo}])" if fld["w"] > 1
                            else f"    .{fld['out']}({tag}_{s}_res[{hi}])")
                hi = lo - 1
            L.append(f"  {mod} u_{tag}_{s} (")
            L.append(",\n".join(conn))
            L.append("  );")
        L.append("")

    drive, check, init, cov = [], [], [], []
    for name, s, f in infos:
        nw, pw = f["num_ways"], f["payload"]
        drive.append(f"""    {s}_sel = {nw}'(pick_sel({nw}));
    for (int b = 0; b < {nw*pw}; b++) {s}_src[b]  = 1'($urandom);
    for (int b = 0; b < {pw}; b++)    {s}_dflt[b] = 1'($urandom);""")
        check.append(f"""    if (!$isunknown(g_{s}_res)) begin
      checks++; {s}_checks++;
      {s}_ones  |= g_{s}_res;
      {s}_zeros |= ~g_{s}_res;
      if ({s}_sel == '0) {s}_dflt_hit++;
      else for (int w = {nw} - 1; w >= 0; w--)
        if ({s}_sel[w]) begin {s}_way_hit[w]++; break; end
      if (g_{s}_res !== i_{s}_res) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH {name} sel=%0b g=%0h i=%0h",
                   $time, {s}_sel, g_{s}_res, i_{s}_res);
      end
    end""")
        init.append(f"    {s}_sel = '0; {s}_src = '0; {s}_dflt = '0; {s}_ones = '0;"
                    f" {s}_zeros = '0; {s}_checks = 0; {s}_dflt_hit = 0;\n"
                    f"    for (int w = 0; w < {nw}; w++) {s}_way_hit[w] = 0;")
        cov.append(f"""    $write("  {name}: checks=%0d dflt_hit=%0d way_hit=",
           {s}_checks, {s}_dflt_hit);
    for (int w = {nw} - 1; w >= 0; w--) $write("%0d ", {s}_way_hit[w]);
    $display("ones=%0d/{pw} zeros=%0d/{pw}", $countones({s}_ones), $countones({s}_zeros));
    if ({s}_checks < COV_MIN) begin
      $display("COVERAGE FAIL: {name} 有效比对只有 %0d 次", {s}_checks); cov_fail++;
    end
    if ({s}_dflt_hit < COV_MIN) begin
      $display("COVERAGE FAIL: {name} 兜底路只命中 %0d 次", {s}_dflt_hit); cov_fail++;
    end
    for (int w = 0; w < {nw}; w++)
      if ({s}_way_hit[w] < COV_MIN) begin
        $display("COVERAGE FAIL: {name} 第 %0d 路只胜出 %0d 次", {nw}-1-w, {s}_way_hit[w]);
        cov_fail++;
      end
    if (!(&{s}_ones) || !(&{s}_zeros)) begin
      $display("COVERAGE FAIL: {name} 有输出位从未观察到 1 或 0"); cov_fail++;
    end""")

    nl = "\n"
    L.append(f"""
  // sel 位图：全 0（走兜底）/ 单热（逐路胜出）/ 稀疏 / 全随机 四种混合
  function automatic int unsigned pick_sel(int unsigned nw);
    int unsigned v;
    case ($urandom_range(0, 3))
      0: v = 0;
      1: v = 1 << $urandom_range(0, nw - 1);
      2: v = $urandom & $urandom;
      default: v = $urandom;
    endcase
    return v & ((1 << nw) - 1);
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
    $display("PriorityMuxModule family checks=%0d errors=%0d", checks, errors);
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
