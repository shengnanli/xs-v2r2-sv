#!/usr/bin/env python3
"""gen_ndaux.py —— Lane I（NewDispatch 辅助子模块）wrapper 端口表/接线生成器。

只生成三个文件里 `// BEGIN GENERATED(...)` / `// END GENERATED` 之间的机械派生区：
golden 同名 wrapper 的**端口表**（逐字取自 G1 golden，保证逐位对齐）与**核例化的
展平接线**。手写区（可读核、注释）脚本一律不碰。

为什么端口表要生成而不是手抄：RegCacheTagModule 170 口、RegCacheTagTable 120 口、
LsqEnqCtrl 622 口，手抄一定会错，而错法恰好是 portlint 之外最难发现的那种
（名字对、位宽差一位）。这里直接从 golden 文本切片，连空格都不改。

用法: gen_ndaux.py [--check]      （--check 只比对不写，用于确认没有腐烂）
"""
import argparse
import pathlib
import re
import sys

G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = pathlib.Path(__file__).resolve().parent.parent


def golden_port_block(name):
    """返回 golden `module <name>(` 与 `\n);` 之间的端口行（原文，去掉首尾）。"""
    t = (G1 / f'{name}.sv').read_text(errors='replace')
    i = t.index(f'module {name}(\n') + len(f'module {name}(\n')
    j = t.index('\n);', i)
    return t[i:j]


def cat(sigs):
    """SystemVerilog 拼接：高下标在左，对应 packed 数组 [N-1:0]。"""
    return '{' + ', '.join(sigs) + '}'


def down(fmt, n):
    return cat([fmt.format(i) for i in range(n - 1, -1, -1)])


CONN = re.compile(r'^(\s*\.\w+\s*)\((.*)\)(,?)$')


def reflow(text, limit=100):
    """把生成区里超长的端口接线折成多行。

    生成区也是给人读的：一行一千字符的拼接，谁也看不出少连了哪一根。折行只动
    空白，拼接元素的顺序与内容原样保留。
    """
    out = []
    for line in text.split('\n'):
        m = CONN.match(line)
        if len(line) <= limit or not m or not m.group(2).startswith('{'):
            out.append(line)
            continue
        head, body, comma = m.group(1), m.group(2), m.group(3)
        pad = ' ' * (len(head) - len(head.lstrip()) + 2)
        toks = body[1:-1].split(', ')
        out.append(head.rstrip() + ' ({')
        cur = pad
        for k, tok in enumerate(toks):
            piece = tok + (', ' if k < len(toks) - 1 else '')
            if len(cur) + len(piece) > limit - 2 and cur.strip():
                out.append(cur.rstrip())
                cur = pad
            cur += piece
        out.append(cur.rstrip())
        out.append(' ' * (len(head) - len(head.lstrip())) + '})' + comma)
    return '\n'.join(out)


# ---------------------------------------------------------------- RegCacheTagModule
def tagmodule_wrapper(name, n_entry, n_write, n_read=12, n_ldep=3, diag_self=False):
    ports = golden_port_block(name)
    ld = []
    for e in range(n_entry - 1, -1, -1):
        ld.append(cat([f'io_loadDependencyVec_{e}_{d}' for d in range(n_ldep - 1, -1, -1)]))
    wld = []
    for w in range(n_write - 1, -1, -1):
        # ★Mem 变体(_1)的对角线★：写口 w 就是 load unit w 自己，golden 里
        # io_writePorts_w_loadDependency_w 这个输入端口**不存在**（被折成常数）。
        # 常数由核的 SELF_DEP_DIAG 参数供给，wrapper 这里只能给个占位 2'h0。
        wld.append(cat(["2'h0" if (diag_self and d == w)
                        else f'io_writePorts_{w}_loadDependency_{d}'
                        for d in range(n_ldep - 1, -1, -1)]))
    L = []
    L.append(f'module {name}(')
    L.append(ports)
    L.append(');')
    L.append('')
    L.append('  xs_RegCacheTagModule_core #(')
    L.append(f'    .NUM_ENTRIES({n_entry}), .NUM_WRITE({n_write}), .NUM_READ({n_read}),')
    L.append("    .SELF_DEP_DIAG(1'b%d)" % (1 if diag_self else 0))
    L.append('  ) u_core (')
    L.append('    .clock                 (clock),')
    L.append('    .reset                 (reset),')
    L.append(f'    .io_read_ren           ({down("io_readPorts_{}_ren", n_read)}),')
    L.append(f'    .io_read_tag           ({down("io_readPorts_{}_tag", n_read)}),')
    L.append(f'    .io_read_valid         ({down("io_readPorts_{}_valid", n_read)}),')
    L.append(f'    .io_read_addr          ({down("io_readPorts_{}_addr", n_read)}),')
    L.append(f'    .io_write_wen          ({down("io_writePorts_{}_wen", n_write)}),')
    L.append(f'    .io_write_addr         ({down("io_writePorts_{}_addr", n_write)}),')
    L.append(f'    .io_write_tag          ({down("io_writePorts_{}_tag", n_write)}),')
    L.append(f'    .io_write_loadDependency({cat(wld)}),')
    L.append(f'    .io_cancelVec          ({down("io_cancelVec_{}", n_entry)}),')
    L.append(f'    .io_validVec           ({down("io_validVec_{}", n_entry)}),')
    L.append(f'    .io_tagVec             ({down("io_tagVec_{}", n_entry)}),')
    L.append(f'    .io_loadDependencyVec  ({cat(ld)})')
    L.append('  );')
    L.append('')
    L.append('endmodule')
    return '\n'.join(L)


# ---------------------------------------------------------------- RegCacheTagTable
# golden 的 wakeup 端口顺序是 6..0（倒序），且只有 0/1 号带 is0Lat；
# og0Cancel 只有偶数下标 0/2/4/6 存在（Int 侧四个唤醒源各对一个）。
def tagtable_wrapper(n_read=12, n_alloc=6, n_wk=7, n_ldep=3, n_ld=3):
    ports = golden_port_block('RegCacheTagTable')
    wkld = []
    for w in range(n_wk - 1, -1, -1):
        wkld.append(cat([f'io_wakeupFromIQ_{w}_bits_loadDependency_{d}'
                         for d in range(n_ldep - 1, -1, -1)]))
    # is0Lat / og0Cancel —— ★实测 golden 的常量折叠，别按 Chisel 默认推★
    #   wakeup 0/1（Int 口 0/1）：is0Lat 是真端口，og0Cancel_0 / og0Cancel_2 是真端口；
    #   wakeup 2/3（Int 口 2/3）：golden 写成 `& ~io_og0Cancel_4` / `& ~io_og0Cancel_6`，
    #     is0Lat 项整个不见了 —— 说明 is0Lat 被折叠成**常数 1**（不是 0！按 0 写就把
    #     这两个口的 og0 取消整条路噤声了，是真 bug）；
    #   wakeup 4/5/6（Mem 三个口）：连 og0Cancel 项都没有 ⇒ 该乘积恒 0，
    #     is0Lat 取什么都无所谓，这里给 0。
    is0lat = cat([("io_wakeupFromIQ_%d_bits_is0Lat" % w) if w < 2
                  else ("1'b1" if w < 4 else "1'b0")
                  for w in range(n_wk - 1, -1, -1)])
    og0 = cat([f'io_og0Cancel_{2*w}' if w < 4 else "1'b0" for w in range(n_wk - 1, -1, -1)])
    L = []
    L.append('module RegCacheTagTable(')
    L.append(ports)
    L.append(');')
    L.append('')
    L.append('  xs_RegCacheTagTable_core u_core (')
    L.append('    .clock                        (clock),')
    L.append('    .reset                        (reset),')
    L.append(f'    .io_read_ren                  ({down("io_readPorts_{}_ren", n_read)}),')
    L.append(f'    .io_read_tag                  ({down("io_readPorts_{}_tag", n_read)}),')
    L.append(f'    .io_read_valid                ({down("io_readPorts_{}_valid", n_read)}),')
    L.append(f'    .io_read_addr                 ({down("io_readPorts_{}_addr", n_read)}),')
    L.append(f'    .io_wakeup_valid              ({down("io_wakeupFromIQ_{}_valid", n_wk)}),')
    L.append(f'    .io_wakeup_rfWen              ({down("io_wakeupFromIQ_{}_bits_rfWen", n_wk)}),')
    L.append(f'    .io_wakeup_pdest              ({down("io_wakeupFromIQ_{}_bits_pdest", n_wk)}),')
    L.append(f'    .io_wakeup_loadDependency     ({cat(wkld)}),')
    L.append(f'    .io_wakeup_is0Lat             ({is0lat}),')
    L.append(f'    .io_wakeup_rcDest             ({down("io_wakeupFromIQ_{}_bits_rcDest", n_wk)}),')
    L.append(f'    .io_og0Cancel                 ({og0}),')
    L.append(f'    .io_ldCancel                  ({down("io_ldCancel_{}_ld2Cancel", n_ld)}),')
    L.append(f'    .io_allocPregs_valid          ({down("io_allocPregs_{}_valid", n_alloc)}),')
    L.append(f'    .io_allocPregs_bits           ({down("io_allocPregs_{}_bits", n_alloc)})')
    L.append('  );')
    L.append('')
    L.append('endmodule')
    return '\n'.join(L)


# ---------------------------------------------------------------- LsqEnqCtrl
UOP_SCALARS = [  # (enq_req 侧字段名, 位宽字面量) —— 只列两侧同名同宽的直通字段
    ('trigger', 4), ('fuType', 35), ('fuOpType', 9), ('rfWen', 1), ('flushPipe', 1),
    ('vpu_nf', 3), ('vpu_veew', 2), ('uopIdx', 7), ('lastUop', 1), ('pdest', 8),
    ('robIdx_flag', 1), ('robIdx_value', 8), ('debugInfo_renameTime', 64),
    ('debug_seqNum_seqNum', 56), ('debug_seqNum_uopIdx', 8), ('numLsElem', 5),
]
N_EXC = 24
N_ENQ = 6


def lsq_wrapper():
    ports = golden_port_block('LsqEnqCtrl')
    L = []
    L.append('module LsqEnqCtrl(')
    L.append(ports)
    L.append(');')
    L.append('')
    L.append('  xs_LsqEnqCtrl_core u_core (')
    L.append('    .clock                  (clock),')
    L.append('    .reset                  (reset),')
    L.append('    .io_redirect_valid      (io_redirect_valid),')
    L.append('    .io_enq_canAccept       (io_enq_canAccept),')
    L.append(f'    .io_enq_needAlloc       ({down("io_enq_needAlloc_{}", N_ENQ)}),')
    L.append(f'    .io_enq_iqAccept        ({down("io_enq_iqAccept_{}", N_ENQ)}),')
    L.append(f'    .io_enq_req_valid       ({down("io_enq_req_{}_valid", N_ENQ)}),')
    exc = [down('io_enq_req_%d_bits_exceptionVec_{}' % e, N_EXC) for e in range(N_ENQ - 1, -1, -1)]
    L.append(f'    .io_enq_req_exceptionVec({cat(exc)}),')
    for f, _w in UOP_SCALARS:
        L.append('    .io_enq_req_%-14s(%s),' % (f, down('io_enq_req_{}_bits_' + f, N_ENQ)))
    L.append('    .io_lcommit             (io_lcommit),')
    L.append('    .io_scommit             (io_scommit),')
    L.append('    .io_lqCancelCnt         (io_lqCancelCnt),')
    L.append('    .io_sqCancelCnt         (io_sqCancelCnt),')
    L.append('    .io_lqFreeCount         (io_lqFreeCount),')
    L.append('    .io_sqFreeCount         (io_sqFreeCount),')
    for f in ('lqIdx_flag', 'lqIdx_value', 'sqIdx_flag', 'sqIdx_value'):
        L.append('    .io_enq_resp_%-15s(%s),' % (f, down('io_enq_resp_{}_' + f, N_ENQ)))
    L.append(f'    .io_enqLsq_needAlloc    ({down("io_enqLsq_needAlloc_{}", N_ENQ)}),')
    L.append(f'    .io_enqLsq_req_valid    ({down("io_enqLsq_req_{}_valid", N_ENQ)}),')
    oexc = [down('io_enqLsq_req_%d_bits_exceptionVec_{}' % e, N_EXC)
            for e in range(N_ENQ - 1, -1, -1)]
    L.append(f'    .io_enqLsq_req_exceptionVec({cat(oexc)}),')
    out_fields = [f for f, _ in UOP_SCALARS] + [
        'debugInfo_eliminatedMove', 'debugInfo_dispatchTime', 'debugInfo_enqRsTime',
        'debugInfo_selectTime', 'debugInfo_issueTime', 'debugInfo_writebackTime',
        'debugInfo_runahead_checkpoint_id', 'debugInfo_tlbFirstReqTime',
        'debugInfo_tlbRespTime', 'lqIdx_flag', 'lqIdx_value', 'sqIdx_flag', 'sqIdx_value']
    for k, f in enumerate(out_fields):
        tail = '' if k == len(out_fields) - 1 else ','
        L.append('    .io_enqLsq_req_%-25s(%s)%s'
                 % (f, down('io_enqLsq_req_{}_bits_' + f, N_ENQ), tail))
    L.append('  );')
    L.append('')
    L.append('endmodule')
    return '\n'.join(L)


GEN = {
    'rtl/backend/RegCacheTagModule.sv': ('wrapper', lambda: tagmodule_wrapper('RegCacheTagModule', 16, 4)),
    'rtl/backend/RegCacheTagModule_1.sv': ('wrapper', lambda: tagmodule_wrapper('RegCacheTagModule_1', 12, 3, diag_self=True)),
    'rtl/backend/RegCacheTagTable.sv': ('wrapper', tagtable_wrapper),
    'rtl/backend/LsqEnqCtrl.sv': ('wrapper', lsq_wrapper),
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for rel, (tag, fn) in GEN.items():
        p = REPO / rel
        if not p.exists():
            print(f'[skip] {rel} 尚未创建')
            continue
        text = p.read_text()
        body = fn()
        pat = re.compile(r'(// BEGIN GENERATED\(%s\)\n).*?(\n// END GENERATED)' % tag, re.S)
        if not pat.search(text):
            print(f'[ERR ] {rel}: 找不到 GENERATED({tag}) 区')
            bad = 1
            continue
        new = pat.sub(lambda m: m.group(1) + reflow(body) + m.group(2), text)
        if new == text:
            print(f'[ok  ] {rel}')
        elif a.check:
            print(f'[DRIFT] {rel}: 生成区与源码不一致')
            bad = 1
        else:
            p.write_text(new)
            print(f'[gen ] {rel}')
    return bad


if __name__ == '__main__':
    sys.exit(main())
