#!/usr/bin/env python3
"""gen.py —— 生成 AgeDetector 家族（发射队列版，9 个变体）的薄包装层文件。

为什么用生成器：9 个 wrapper 除了「条目位宽 / 发射口数」之外逐字同形，端口表必须与
G1 golden 逐位同名同宽（portlint 判据）。手抄 9 份端口表是纯机械劳动，且抄错一位
要到 portlint 才发现。这里直接从 golden 的模块头**机械提取**端口表，参数（条目数 /
入队口数 / 发射口数 / age 寄存器数）也全部从 golden 量出来，不从 Chisel 默认值推。

核体不由本脚本生成：rtl/backend/xs_AgeDetector_core.sv 是手写的可读核，家族共享一份。

用法: python3 gen.py [--check]
  --check 只比对不写盘（退出码非零 = 磁盘上的文件与 golden 量出来的不一致）
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT_DIR = REPO / 'rtl' / 'backend'

VARIANTS = ['AgeDetector', 'AgeDetector_1', 'AgeDetector_8', 'AgeDetector_9',
            'AgeDetector_12', 'AgeDetector_13', 'AgeDetector_15',
            'AgeDetector_19', 'AgeDetector_21']

# 每个变体被哪些发射队列例化（`grep -l "^\s*<变体>\s" golden-rtl/*.sv` 机械得到）
PARENTS = {}


def golden_facts(name):
    """从 golden 文件量出这个变体的一切：端口表原文、条目数、入队口数、发射口数、age 寄存器数。"""
    text = (GOLDEN / f'{name}.sv').read_text()
    m = re.search(r'^module %s\(\n(.*?)^\);$' % re.escape(name), text, re.M | re.S)
    if not m:
        raise SystemExit(f'{name}: 找不到模块头')
    ports = m.group(1).rstrip('\n')
    width = int(re.search(r'\[(\d+):0\]\s*io_enq_0', ports).group(1)) + 1
    n_enq = len(re.findall(r'\bio_enq_(\d+)\b', ports))
    n_deq = len(re.findall(r'output\s+\[?[\d:]*\]?\s*io_out_\d+', ports))
    n_ci = len(re.findall(r'input\s+\[?[\d:]*\]?\s*io_canIssue_\d+', ports))
    if n_ci != n_deq:
        raise SystemExit(f'{name}: canIssue 口数 {n_ci} != out 口数 {n_deq}')
    regs = len(re.findall(r'^\s*reg\s+age_\d+_\d+;', text, re.M))
    reset_arms = len(re.findall(r'^\s*age_\d+_\d+ <= 1\'h0;', text, re.M))
    subs = sorted({g for g in re.findall(r'^\s{2}([A-Z]\w+)\s+\w+\s*\(', text, re.M)})
    parents = sorted(p.stem for p in GOLDEN.glob('*.sv')
                     if re.search(r'^\s*%s\s+\w+\s*\(' % re.escape(name),
                                  p.read_text(errors='replace'), re.M))
    PARENTS[name] = parents
    return dict(ports=ports, width=width, n_enq=n_enq, n_deq=n_deq,
                regs=regs, reset_arms=reset_arms, subs=subs, parents=parents)



TB_HEAD = r"""// =============================================================================
// AgeDetector 家族 UT（发射队列版，9 个变体）：每个变体一对 DUT —— golden <M> 对
// 重写 <M>_xs，共享时钟/复位，各自独立随机激励，逐拍比对**全部** io_out 端口。
//
// ★ 激励为什么不能是「每个输入位独立均匀随机」★
// 本模块的判别力集中在三处，均匀随机都碰不到：
//   1. **两个入队口同拍进队**（矩阵次态的第 (1) 条规则）—— 决定"口号小的算更老"。
//      两口各自 one-hot、位宽最大 16，独立均匀随机时两口同拍都非零的概率极低。
//      这里直接按事件造：45% 的拍两口都进队。
//   2. **两口撞同一条目**（i0 == i1）—— isEnq(i) 为真但 beatenByEarlierPort 也为真。
//   3. **canIssue 只点亮两位**（成对探测）—— 这时 io_out 直接把 get_age(i,j) 这一位
//      读出来，N*(N-1)/2 个上三角元素因此能被逐个观测，而不是淹没在 N 选 1 的结果里。
//      游标 pairI/pairJ 逐拍推进，保证扫遍所有对（tb 尾部核对 pairs = N*(N-1)/2）。
// 另有 4% 的拍喂**非 one-hot** 的 enq：golden 的 PopCount 断言在 `ifndef SYNTHESIS
// 里，两侧都带 +define+SYNTHESIS 编译 ⇒ 断言不在场，非法编码上两边也必须逐位一致
// （CONVENTIONS：输入端口在 FM 里是自由变量，UT 这边也别把它当约束）。
//
// ★ 覆盖证据 ★
// 每个变体各自统计若干「没有它这一轮就等于没验」的事件，任何一项为 0、或成对探测
// 没扫满，tb 判 TEST FAILED —— 不让 errors=0 在空激励上成立。
//
// 自动生成：verif/ut/AgeDetector/gen.py —— 勿手改
// =============================================================================
`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// agedet_env —— 一个变体的激励 + 比对 + 覆盖统计（按条目数/发射口数参数化）
// -----------------------------------------------------------------------------
module agedet_env #(
  parameter string NAME = "?",
  parameter int    N    = 2,   // 条目数
  parameter int    NDEQ = 1    // 发射口数
) (
  input  logic         clk,
  input  logic         rst,
  output logic [N-1:0] enq0,
  output logic [N-1:0] enq1,
  output logic [N-1:0] canIssue [NDEQ],
  input  logic [N-1:0] g_out    [NDEQ],
  input  logic [N-1:0] i_out    [NDEQ]
);

  int     errors = 0;
  longint checks = 0;

  // 覆盖计数（每个都是"没有它这一轮就等于没验"的事件）
  longint cov_enq_both  = 0;   // 两口同拍进不同条目（端口优先级判别点）
  longint cov_enq_same  = 0;   // 两口同拍撞同一条目
  longint cov_enq_nonoh = 0;   // 某口喂了非 one-hot（非法编码）
  longint cov_enq_none  = 0;   // 本拍无人进队（矩阵保持，时钟使能关着）
  longint cov_out_hit   = 0;   // io_out 非 0（真的选出了一个）
  longint cov_ci_full   = 0;   // canIssue 全 1
  longint cov_ci_zero   = 0;   // canIssue 全 0（out 必须全 0）
  longint cov_multi_ci  = 0;   // canIssue 至少两个候选（选择逻辑真的在挑）
  bit     pair_seen [N][N];    // 成对探测覆盖到的 (i,j)

  int pairI = 0, pairJ = 1;    // 成对探测游标

  function automatic logic [N-1:0] one_hot(input int idx);
    logic [N-1:0] v;
    v = '0;
    v[idx] = 1'b1;
    return v;
  endfunction

  task automatic gen_stim();
    int r, i0, i1;
    enq0 = '0;
    enq1 = '0;
    r = $urandom_range(0, 99);
    if (r < 45) begin              // 两口同拍都进队（i0==i1 时即"撞同一条目"）
      i0 = $urandom_range(0, N-1);
      i1 = $urandom_range(0, N-1);
      enq0 = one_hot(i0);
      enq1 = one_hot(i1);
    end
    else if (r < 70) enq0 = one_hot($urandom_range(0, N-1));   // 只有 0 口
    else if (r < 90) enq1 = one_hot($urandom_range(0, N-1));   // 只有 1 口
    else if (r < 94) begin                                     // 非 one-hot
      enq0 = N'($urandom);
      enq1 = N'($urandom);
    end
    // 其余 6%: 本拍无人进队 —— 时钟使能全关，矩阵必须原样不动

    for (int d = 0; d < NDEQ; d++) begin
      r = $urandom_range(0, 99);
      if (r < 40) begin            // 成对探测：out 直接暴露 get_age(pairI,pairJ)
        canIssue[d] = '0;
        canIssue[d][pairI] = 1'b1;
        canIssue[d][pairJ] = 1'b1;
      end
      else if (r < 60) canIssue[d] = '1;
      else if (r < 90) canIssue[d] = N'($urandom);
      else             canIssue[d] = one_hot($urandom_range(0, N-1));
    end

    // 游标每拍推进一格，逐对扫过整个上三角
    pairJ = pairJ + 1;
    if (pairJ >= N) begin
      pairI = pairI + 1;
      pairJ = pairI + 1;
      if (pairJ >= N) begin
        pairI = 0;
        pairJ = 1;
      end
    end
  endtask

  always @(negedge clk) begin
    if (rst) begin
      enq0 = '0;
      enq1 = '0;
      for (int d = 0; d < NDEQ; d++) canIssue[d] = '0;
      pairI = 0;
      pairJ = 1;
    end
    else gen_stim();
  end

  // 覆盖采样（用本拍已生效的激励）
  always @(posedge clk) if (!rst) begin
    int a, b;
    if ((|enq0) && (|enq1)) begin
      if (enq0 == enq1) cov_enq_same++;
      else              cov_enq_both++;
    end
    if (!(|enq0) && !(|enq1)) cov_enq_none++;
    if ($countones(enq0) > 1 || $countones(enq1) > 1) cov_enq_nonoh++;
    for (int d = 0; d < NDEQ; d++) begin
      if (|g_out[d])                    cov_out_hit++;
      if (&canIssue[d])                 cov_ci_full++;
      if (!(|canIssue[d]))              cov_ci_zero++;
      if ($countones(canIssue[d]) >= 2) cov_multi_ci++;
    end
    if ($countones(canIssue[0]) == 2) begin
      a = -1;
      b = -1;
      for (int k = 0; k < N; k++) if (canIssue[0][k]) begin
        if (a < 0) a = k;
        else       b = k;
      end
      if (b >= 0) pair_seen[a][b] = 1'b1;
    end
  end

  // 比对：负沿施加激励后 4ns（下一个正沿之前）比全部 io_out
  always @(negedge clk) if (!rst) begin
    #4;
    for (int d = 0; d < NDEQ; d++) begin
      checks++;
      if (!$isunknown(g_out[d]) && g_out[d] !== i_out[d]) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] %s io_out_%0d g=%h i=%h (enq=%h/%h canIssue=%h)",
                   $time, NAME, d, g_out[d], i_out[d], enq0, enq1, canIssue[d]);
      end
    end
  end

  function automatic int pairs_seen();
    int n;
    n = 0;
    for (int a = 0; a < N; a++)
      for (int b = a + 1; b < N; b++) if (pair_seen[a][b]) n++;
    return n;
  endfunction

  // 返回 0 = 本变体合格；非 0 = 有错或覆盖不足（覆盖不足时 errors=0 不作数）
  function automatic int report();
    int want, got, bad;
    want = N * (N - 1) / 2;
    got  = pairs_seen();
    bad  = 0;
    if (errors != 0) bad = 1;
    if (checks < 100000) bad = 1;
    if (cov_enq_both == 0 || cov_enq_same == 0 || cov_enq_nonoh == 0 ||
        cov_enq_none == 0 || cov_out_hit == 0 || cov_ci_full == 0 ||
        cov_ci_zero == 0 || cov_multi_ci == 0) bad = 1;
    if (got != want) bad = 1;
    $display("COV %-16s checks=%0d errors=%0d enq_both=%0d enq_same=%0d enq_nonoh=%0d enq_none=%0d out_hit=%0d ci_full=%0d ci_zero=%0d multi_ci=%0d pairs=%0d/%0d %s",
             NAME, checks, errors, cov_enq_both, cov_enq_same, cov_enq_nonoh,
             cov_enq_none, cov_out_hit, cov_ci_full, cov_ci_zero, cov_multi_ci,
             got, want, (bad ? "BAD" : "ok"));
    return bad;
  endfunction

endmodule

// -----------------------------------------------------------------------------
// tb —— 9 个变体各一对 DUT + 一个 env
// -----------------------------------------------------------------------------
module tb;
  int unsigned NCYCLES = 200000;
  bit   clk = 0;
  logic rst;

  always #5 clk = ~clk;
"""


def render_tb(facts):
    L = [TB_HEAD]
    for name, f in facts:
        n, ne, nd = f['width'], f['n_enq'], f['n_deq']
        w = f'[{n-1}:0]'
        L.append(f'  // --- {name}: {n} 条目 / {ne} 入队口 / {nd} 发射口 ---')
        L.append(f'  logic {w} {name}_enq0, {name}_enq1;')
        L.append(f'  logic {w} {name}_ci [{nd}];')
        L.append(f'  logic {w} {name}_g_out [{nd}];')
        L.append(f'  logic {w} {name}_i_out [{nd}];')
        for pfx, mod in (('g', name), ('i', f'{name}_xs')):
            conn = ['.clock(clk)', '.reset(rst)']
            conn += [f'.io_enq_{k}({name}_enq{k})' for k in range(ne)]
            conn += [f'.io_canIssue_{k}({name}_ci[{k}])' for k in range(nd)]
            conn += [f'.io_out_{k}({name}_{pfx}_out[{k}])' for k in range(nd)]
            L.append(f'  {mod} {pfx}_{name} (')
            L.append('    ' + ', '.join(conn) + ');')
        L.append(f'  agedet_env #(.NAME("{name}"), .N({n}), .NDEQ({nd})) e_{name} (')
        L.append(f'    .clk(clk), .rst(rst), .enq0({name}_enq0), .enq1({name}_enq1),')
        L.append(f'    .canIssue({name}_ci), .g_out({name}_g_out), .i_out({name}_i_out));')
        L.append('')
    L.append('  initial begin')
    L.append('    int bad;')
    L.append('    longint tot_checks;')
    L.append('    int tot_errors;')
    L.append('    if ($value$plusargs("ncycles=%d", NCYCLES)) ;')
    L.append('    rst = 1; repeat (8) @(posedge clk); rst = 0;')
    L.append('    repeat (NCYCLES) @(posedge clk);')
    L.append('    bad = 0;')
    L.append('    tot_checks = 0;')
    L.append('    tot_errors = 0;')
    for name, _ in facts:
        L.append(f'    bad += e_{name}.report();')
        L.append(f'    tot_checks += e_{name}.checks;')
        L.append(f'    tot_errors += e_{name}.errors;')
    L.append('    $display("VARIANTS=' + str(len(facts)) + ' bad=%0d", bad);')
    # 全家族合计的一行：mutants.py 只读这一行（家族里任一变体报错都必须在这里出现）
    L.append('    $display("checks=%0d errors=%0d", tot_checks, tot_errors);')
    L.append('    if (bad == 0) $display("TEST PASSED"); else $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def render(name, f):
    n, ne, nd = f['width'], f['n_enq'], f['n_deq']
    w = f'[{n-1}:0] ' if n > 1 else ''
    parents = f['parents']
    ph = '\n'.join(f'//     {p}' for p in parents)
    L = []
    L.append(f'// {name}.sv —— 发射队列「最老可发射条目」选择器：{n} 条目 / {ne} 入队口 / {nd} 发射口')
    L.append('// -----------------------------------------------------------------------------')
    L.append('// 核体见 xs_AgeDetector_core.sv（家族共享参数化核，年龄矩阵的全部逻辑都在那里）。')
    L.append('// 本文件只做端口打包：把 golden 的扁平端口拢成核的数组接口，并设本变体的参数。')
    L.append('//')
    L.append('// 本变体规模（全部从 G1 golden %s.sv 机械量得，见 verif/ut/AgeDetector/gen.py）：' % name)
    L.append(f'//   条目数 {n}（io_enq_0 的位宽）；入队口 {ne}；发射口 {nd}（canIssue/out 各 {nd} 份）')
    L.append(f'//   age 寄存器 {f["regs"]} 个 = {n}*{n}-1)/2 的严格上三角，复位臂 {f["reset_arms"]} 条'.replace(f'{n}*{n}-1)/2', f'{n}*({n}-1)/2'))
    L.append('//     —— 寄存器数与复位臂数相等 ⇒ 本变体没有不复位寄存器。')
    L.append(f'//   golden 里例化的子模块：{"、".join(f["subs"]) if f["subs"] else "无（自包含叶子）"}')
    L.append('//')
    L.append('// 被这些发射队列例化：')
    L.append(ph if parents else '//     （无）')
    L.append('//')
    L.append('// 自动生成：verif/ut/AgeDetector/gen.py —— 勿手改')
    L.append('// =============================================================================')
    L.append(f'module {name}(')
    L.append(f['ports'])
    L.append(');')
    L.append(f'  logic {w}enq      [{ne}];')
    L.append(f'  logic {w}canIssue [{nd}];')
    L.append(f'  logic {w}out      [{nd}];')
    L.append('')
    for k in range(ne):
        L.append(f'  assign enq[{k}] = io_enq_{k};')
    for k in range(nd):
        L.append(f'  assign canIssue[{k}] = io_canIssue_{k};')
    L.append('')
    for k in range(nd):
        L.append(f'  assign io_out_{k} = out[{k}];')
    L.append('')
    L.append('  xs_AgeDetector_core #(')
    L.append(f'    .NUM_ENTRIES({n}),')
    L.append(f'    .NUM_ENQ    ({ne}),')
    L.append(f'    .NUM_DEQ    ({nd})')
    L.append('  ) u_core (')
    L.append('    .clock       (clock),')
    L.append('    .reset       (reset),')
    L.append('    .io_enq      (enq),')
    L.append('    .io_canIssue (canIssue),')
    L.append('    .io_out      (out)')
    L.append('  );')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    facts = [(v, golden_facts(v)) for v in VARIANTS]
    outputs = [(OUT_DIR / f'{v}.sv', render(v, f)) for v, f in facts]
    outputs.append((HERE / 'tb.sv', render_tb(facts)))
    for dst, txt in outputs:
        if a.check:
            cur = dst.read_text() if dst.exists() else ''
            if cur != txt:
                print(f'DIFF: {dst}')
                bad += 1
        else:
            dst.write_text(txt)
            print(f'wrote {dst}')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
