#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_rewrite_coverage_memory.py —— 覆盖率台账的「存储模型」排除类的正反测。

起因（2026-10-17，floor-classifier lane）：rewrite_coverage.EXCLUSIONS 的存储名字表是
`array_|ram_|sram_|*_ext`，比 universe 的 behavioral_ram 家族（g1_configured_universe
.EXCL_PATTERNS 里有 `^data_mem_`、`^array(_\\d+)?$`）窄，于是 data_mem_8x4 /
data_mem_16x12 / data_mem_0_8x3 / data_mem_0_4x2 / array 一直挂在「剩余待重写」里，
其中后三个还是 verif/mc_memory_registry.tsv 的登记行 —— 台账和存储契约表互相矛盾。

修法是 is_behavioral_memory：登记表里有 → 存储；`data_mem_*` 家族 **且** golden 正文逐字
等于 firtool 存储模板 → 存储。本文件验：
  正例  两个未登记的 data_mem 走结构模板认出来；登记表每一行都归存储；
        全部 golden ram_* 都过模板，且深度/宽度与登记表逐行一致（模板与 MC 推导同口径）
  反例  名字是 data_mem_、正文多一条逻辑 → 不认；名字是 data_mem_、正文是个队列 → 不认；
        正文是纯存储、名字不在家族里 → 本规则不收（口径决定不顺手做）；
        golden 里名字带 Mem 的真逻辑模块 → 不进任何排除类
"""
import pathlib
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'scripts'))

import mc_memory_registry as MC          # noqa: E402
import rewrite_coverage as RC            # noqa: E402

FAILS = []
N = [0]


def ck(name, ok, detail=''):
    N[0] += 1
    print('  [%s] %s%s' % ('OK' if ok else 'FAIL', name, ('  ' + detail) if detail else ''))
    if not ok:
        FAILS.append(name)


def golden_text(name):
    return (RC.GOLDEN / (name + '.sv')).read_text(errors='replace')


def main():
    reg = MC.load_registry()

    # ---- 正例 1：两个未登记的 data_mem 靠结构模板认出来 -------------------------
    for n, shape in (('data_mem_8x4', (8, 4, 2, 1)), ('data_mem_16x12', (16, 12, 2, 1))):
        ck('%s 不在 MC 登记表（证明走的是结构路径）' % n, n not in reg)
        got = RC.firtool_memory_shape(golden_text(n))
        ck('%s 过 firtool 存储模板 (depth,width,nR,nW)=%s' % (n, shape), got == shape, 'got=%s' % (got,))
        ck('%s 归存储排除类' % n, RC.classify(n) == 'mc_memory_model', 'classify=%s' % RC.classify(n))

    # ---- 正例 2：登记表每一行都必须归存储（与契约表一致） --------------------------
    gold = RC.golden_modules()
    miss = sorted(d for d in reg if d in gold and not RC.classify(d))
    ck('MC 登记表的 %d 行（golden 里有定义的）全部落进排除类' % sum(d in gold for d in reg),
       not miss, 'miss=%s' % miss[:5])

    # ---- 正例 3：模板与 MC 推导同口径 ---------------------------------------------
    bad = []
    nram = 0
    for n in sorted(gold):
        if not n.startswith('ram_'):
            continue
        nram += 1
        shape = RC.firtool_memory_shape(golden_text(n))
        if shape is None:
            bad.append(n)
            continue
        r = reg.get(n)
        if r and (str(shape[0]), str(shape[1])) != (r['depth'], r['width']):
            bad.append(n + '(depth/width!=registry)')
    ck('golden 全部 %d 个 ram_* 都过模板，登记了的深度/宽度与登记表一致' % nram, not bad,
       'bad=%s' % bad[:5])

    # ---- 反例：名字像 data_mem、正文不是纯存储 -----------------------------------
    good = golden_text('data_mem_8x4')
    with tempfile.TemporaryDirectory() as td:
        tdp = pathlib.Path(td)
        # (a) 纯存储正文上多一条逻辑
        extra = good.replace('endmodule', '  wire _unused = R0_en & R1_en;\nendmodule')
        (tdp / 'data_mem_fake_8x4.sv').write_text(extra.replace('data_mem_8x4', 'data_mem_fake_8x4'))
        ck('反例 data_mem_ 名字 + 多一条 wire 的正文 → 不归存储',
           RC.firtool_memory_shape(extra) is None
           and not RC.is_behavioral_memory('data_mem_fake_8x4', golden_dir=td))
        # (b) 读口不再是组合读（多一级寄存器）
        regd = good.replace('assign R0_data = R0_en ? Memory[R0_addr] : 4\'bx;',
                            'reg [3:0] q; always @(posedge R0_clk) q <= Memory[R0_addr];\n'
                            '  assign R0_data = q;')
        ck('反例 data_mem_ 名字 + 读口被改成寄存器读 → 不归存储',
           regd != good and RC.firtool_memory_shape(regd) is None)
        # (c) 名字是 data_mem_、正文其实是个队列（真逻辑）
        import re
        qf = sorted(RC.GOLDEN.glob('Queue2_*.sv'))[0]
        q = qf.read_text(errors='replace')
        src = re.search(r'^module\s+(\w+)', q, re.M).group(1)
        (tdp / 'data_mem_queue_2x8.sv').write_text(q.replace(src, 'data_mem_queue_2x8'))
        ck('反例 data_mem_ 名字 + 队列正文（%s）→ 不归存储' % src,
           not RC.is_behavioral_memory('data_mem_queue_2x8', golden_dir=td))
        # (d) 名字是 data_mem_、golden 里根本没有这个文件
        ck('反例 data_mem_ 名字但 golden 无此文件 → 不归存储',
           not RC.is_behavioral_memory('data_mem_nosuch_1x1', golden_dir=td))

    # ---- 反例：正文纯存储、名字不在家族里 → 本规则不收 -------------------------------
    for n in ('stateBankTags_320x3', 'dt_pcTransType_160x2', 'diff_rat_state_bank_320x776'):
        if n in gold:
            ck('%s 正文过模板但不在 data_mem_ 家族、也未登记 → 不进排除类' % n,
               RC.firtool_memory_shape(golden_text(n)) is not None and RC.classify(n) is None,
               'classify=%s' % RC.classify(n))

    # ---- 反例：名字里带 Mem 的真逻辑模块 ------------------------------------------
    for n in ('GPAMem', 'FtqPcMemWrapper', 'MemBlock'):
        if n in gold:
            ck('%s（真逻辑）不进任何排除类' % n, RC.classify(n) is None, 'classify=%s' % RC.classify(n))

    print('test_rewrite_coverage_memory: %d 项，%s' %
          (N[0], '全过' if not FAILS else '★%d 项不过★' % len(FAILS)))
    return 1 if FAILS else 0


if __name__ == '__main__':
    sys.exit(main())
