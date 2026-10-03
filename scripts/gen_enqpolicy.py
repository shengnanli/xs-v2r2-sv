#!/usr/bin/env python3
"""gen_enqpolicy.py —— 发射队列入队策略 EnqPolicy 家族（4 个位宽变体）的薄 wrapper + UT tb 生成器。

生成对象（全是机械部分；逻辑只在手写核 rtl/backend/xs_EnqPolicy_core.sv 里）：
  rtl/backend/EnqPolicy.sv / EnqPolicy_8.sv / EnqPolicy_14.sv / EnqPolicy_18.sv
      golden 同名薄 wrapper：端口表逐字取 golden，例化 xs_EnqPolicy_core #(.W(<位宽>))
  verif/ut/EnqPolicy/tb.sv
      四对双例化（golden vs 重写），逐拍比全部输出

家族成员不是手抄的名单，而是从 G1 golden 里**机械找出来**：凡是 `module EnqPolicy[_N](`
的都算，然后对每个做三项核对 —— 有一项不符就当场失败，不生成：
  (1) 端口表恰好 5 个、名字与方向固定（io_canEnq / io_enqSelOHVec_{0,1}_{valid,bits}）；
  (2) 三个向量端口同宽（= W），两个 valid 是 1 位；
  (3) 模块体里没有 reg / 子模块例化（纯组合、0 child）。

用法:
  scripts/gen_enqpolicy.py            # 写文件
  scripts/gen_enqpolicy.py --check    # 只比对，不写；有漂移 rc=1（gate 用）
"""
import argparse
import pathlib
import re
import sys

GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = pathlib.Path(__file__).resolve().parents[1]
RTL = REPO / 'rtl' / 'backend'
UT = REPO / 'verif' / 'ut' / 'EnqPolicy'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')
SHAPE = [('input', 'io_canEnq'),
         ('output', 'io_enqSelOHVec_0_valid'),
         ('output', 'io_enqSelOHVec_0_bits'),
         ('output', 'io_enqSelOHVec_1_valid'),
         ('output', 'io_enqSelOHVec_1_bits')]


def family():
    """G1 golden 里所有 EnqPolicy 变体 -> 位宽 W（按名字排序）。"""
    out = {}
    for f in sorted(GOLDEN.glob('EnqPolicy*.sv')):
        mod = f.stem
        if not re.fullmatch(r'EnqPolicy(_\d+)?', mod):
            continue
        txt = f.read_text()
        m = re.search(r'^module %s\((.*?)\);' % mod, txt, re.M | re.S)
        assert m, f'{mod}: 找不到模块头'
        ports = []
        for line in m.group(1).strip().split('\n'):
            pm = PORT_RE.match(line)
            assert pm, f'{mod}: 端口行解析不了: {line!r}'
            ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
        assert [(d, n) for d, _, n in ports] == SHAPE, f'{mod}: 端口表形状不符 {ports}'
        w = ports[0][1]
        assert [p[1] for p in ports] == [w, 1, w, 1, w], f'{mod}: 位宽不符 {ports}'
        body = txt[m.end():txt.index('endmodule', m.end())]
        assert not re.search(r'^\s*reg\b', body, re.M), f'{mod}: 有寄存器，不是纯组合'
        assert not re.search(r'^\s*[A-Za-z_]\w*\s+[A-Za-z_]\w*\s*\(', body, re.M), \
            f'{mod}: 有子模块例化'
        out[mod] = w
    assert out, 'golden 里没找到 EnqPolicy 家族'
    return out


def gen_wrapper(mod, w):
    return f"""// {mod}.sv —— 发射队列入队策略（W={w}）薄包装层
// -----------------------------------------------------------------------------
// 逻辑全在 xs_EnqPolicy_core.sv（家族共享核，按位宽参数化）；本文件只给 W 并改名接线。
//   口 0 = 最低位的空槽，valid = 至少 1 个空槽；
//   口 1 = 最高位的空槽，valid = 至少 2 个空槽。
// 端口表逐字取自 G1 golden {mod}.sv。
//
// 自动生成：scripts/gen_enqpolicy.py —— 勿手改
// =============================================================================
module {mod}(
  input  [{w - 1}:0] io_canEnq,
  output        io_enqSelOHVec_0_valid,
  output [{w - 1}:0] io_enqSelOHVec_0_bits,
  output        io_enqSelOHVec_1_valid,
  output [{w - 1}:0] io_enqSelOHVec_1_bits
);

  xs_EnqPolicy_core #(
    .W({w})
  ) u_core (
    .can_enq    (io_canEnq),
    .sel0_valid (io_enqSelOHVec_0_valid),
    .sel0_oh    (io_enqSelOHVec_0_bits),
    .sel1_valid (io_enqSelOHVec_1_valid),
    .sel1_oh    (io_enqSelOHVec_1_bits)
  );

endmodule
"""


def gen_tb(fam):
    L = []
    A = L.append
    A('// EnqPolicy 家族 UT —— golden 与重写件双例化（每个位宽变体一对），逐拍比全部输出。')
    A('//')
    A('// 激励：纯组合块，输入只有 canEnq 一根。')
    A('//   * W <= 16 的变体：前 2^W 拍把 canEnq 从 0 数到 2^W-1，**穷举**全部输入；')
    A('//   * 之后（以及 W > 16 的变体全程）按五种形态随机：全随机 / 全 0 / 只 1 位 /')
    A('//     只 2 位 / 全 1 去掉几位 —— 后四种专门打「0 个、1 个、2 个空槽」这几个')
    A('//     边界（全随机下 W=22 时 popcount<2 几乎不出现）。')
    A('// 覆盖闸：每个变体 popcount==0 / ==1 / >=2 三个桶都必须非零，否则判 FAIL。')
    A('//')
    A('// 自动生成：scripts/gen_enqpolicy.py —— 勿手改')
    A('`timescale 1ns/1ps')
    A('')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  int errors = 0;')
    A('  longint checks = 0;')
    A('  int cov_fail = 0;')
    A('')
    A('  function automatic int popc(input logic [63:0] x);')
    A('    popc = 0;')
    A('    for (int k = 0; k < 64; k++) popc += x[k];')
    A('  endfunction')
    A('')
    for mod, w in fam.items():
        A(f'  // ---- {mod}（W={w}）----')
        A(f'  logic [{w - 1}:0] in_{mod};')
        for pfx in ('g', 'i'):
            A(f'  wire        {pfx}_{mod}_v0, {pfx}_{mod}_v1;')
            A(f'  wire [{w - 1}:0] {pfx}_{mod}_b0, {pfx}_{mod}_b1;')
        for pfx, name in (('g', mod), ('i', mod + '_xs')):
            A(f'  {name} u_{pfx}_{mod} (')
            A(f'    .io_canEnq(in_{mod}),')
            A(f'    .io_enqSelOHVec_0_valid({pfx}_{mod}_v0),')
            A(f'    .io_enqSelOHVec_0_bits({pfx}_{mod}_b0),')
            A(f'    .io_enqSelOHVec_1_valid({pfx}_{mod}_v1),')
            A(f'    .io_enqSelOHVec_1_bits({pfx}_{mod}_b1)')
            A('  );')
        A(f'  int cov_{mod}_pc0 = 0, cov_{mod}_pc1 = 0, cov_{mod}_pc2 = 0;')
        A('')
    A('  `define CHK(G, I, NM) begin \\')
    A('    checks++; \\')
    A('    if ((G) !== (I)) begin \\')
    A('      errors++; \\')
    A('      if (errors <= 40) $display("[ERR] cyc=%0d %s golden=%h impl=%h", cyc, NM, G, I); \\')
    A('    end \\')
    A('  end')
    A('')
    A('  // W 位的随机激励：五种形态（见文件头）')
    A('  function automatic logic [63:0] stim(input int w);')
    A('    logic [63:0] x;')
    A('    case ($urandom_range(0, 4))')
    A('      0: x = {$urandom(), $urandom()};')
    A("      1: x = '0;")
    A("      2: x = 64'(1) << $urandom_range(0, w - 1);")
    A("      3: x = (64'(1) << $urandom_range(0, w - 1)) | (64'(1) << $urandom_range(0, w - 1));")
    A("      default: x = ~((64'(1) << $urandom_range(0, w - 1)) | (64'(1) << $urandom_range(0, w - 1)));")
    A('    endcase')
    A('    return x;')
    A('  endfunction')
    A('')
    A('  longint cyc = 0;')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    for (cyc = 0; cyc < NCYCLES; cyc++) begin')
    for mod, w in fam.items():
        if w <= 16:
            A(f'      in_{mod} = (cyc < (64\'(1) << {w})) ? {w}\'(cyc) : {w}\'(stim({w}));')
        else:
            A(f"      in_{mod} = {w}'(stim({w}));")
    A('      #1;')
    for mod, w in fam.items():
        A(f'      `CHK(g_{mod}_v0, i_{mod}_v0, "{mod}.io_enqSelOHVec_0_valid")')
        A(f'      `CHK(g_{mod}_b0, i_{mod}_b0, "{mod}.io_enqSelOHVec_0_bits")')
        A(f'      `CHK(g_{mod}_v1, i_{mod}_v1, "{mod}.io_enqSelOHVec_1_valid")')
        A(f'      `CHK(g_{mod}_b1, i_{mod}_b1, "{mod}.io_enqSelOHVec_1_bits")')
        A(f'      case (popc(64\'(in_{mod})))')
        A(f'        0: cov_{mod}_pc0++;')
        A(f'        1: cov_{mod}_pc1++;')
        A(f'        default: cov_{mod}_pc2++;')
        A('      endcase')
    A('      #1;')
    A('    end')
    A('    $display("=== %0d cycles, checks=%0d, errors=%0d ===", cyc, checks, errors);')
    for mod in fam:
        for b in ('pc0', 'pc1', 'pc2'):
            A(f'    $display("  cov %-22s = %0d", "{mod}_{b}", cov_{mod}_{b});')
            A(f'    if (cov_{mod}_{b} == 0) begin cov_fail++; '
              f'$display("  *** COVERAGE HOLE: {mod}_{b}"); end')
    A('    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");')
    A('    else $display("TEST FAILED (errors=%0d cov_fail=%0d checks=%0d)", errors, cov_fail, checks);')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    args = ap.parse_args()
    fam = family()
    files = {RTL / f'{m}.sv': gen_wrapper(m, w) for m, w in fam.items()}
    files[UT / 'tb.sv'] = gen_tb(fam)
    bad = 0
    for p, txt in files.items():
        if args.check:
            if not p.exists() or p.read_text() != txt:
                print(f'DRIFT: {p}')
                bad = 1
        else:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(txt)
            print(f'wrote {p}')
    if args.check and not bad:
        print(f'gen_enqpolicy: {len(files)} 个产物无漂移（{", ".join(f"{m}=W{w}" for m, w in fam.items())}）')
    return bad


if __name__ == '__main__':
    sys.exit(main())
