#!/usr/bin/env python3
"""gen_payload_shells.py —— "打包载荷"核的薄文件 + FM 匹配前钉点（lane mmiobridge-xbar-l2tlbwrap）。

  PTWRepeaterNB      rtl/mmu/       核 xs_PTWRepeaterNB_core：req / resp 两根打包向量

（本 lane 起初还生成 skidBufferConnect；该目标由 storeunit-vsplit lane 签核并先合入 main
 （scripts/gen_vsplit.py），本 lane 版本已撤下，这里不再生成它。）

核手写、载荷不分字段；薄文件从 golden 端口表把字段按 golden 端口顺序 MSB 优先拼成打包向量，再把出口拆回去。


golden 把每个字段存成一个独立寄存器（req_vpn、resp_s1_entry_tag …），核里是一根向量
（u_core/req、u_core/resp）；名字对不上会让 Formality 的配对卡死，所以同时生成
verif/ut/<Module>/fm_pins_pre.tcl：golden 每个寄存器位 set_user_match 到向量的对应位，一一对应、字面计数、
fail-closed（拒一条或总数不对就 error；safe interp 里不用 exit）。只消名差，不约束 ref、不改 appvar、不加黑盒。

用法：python3 scripts/gen_payload_shells.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('\nmodule %s(' % mod) + 1
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if not m:
            raise SystemExit('%s: 端口行解析失败: %r' % (mod, line))
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    golden_regs = re.findall(r'^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', t, re.M)
    golden_regs = [(n, 1 if w == '' else int(w) + 1) for w, n in golden_regs]
    return out, t.count('\n') + 1, golden_regs


def port_decl(P):
    return ',\n'.join('  %-6s logic %s%s' % (d, '' if w == 1 else '[%d:0] ' % (w - 1), n) for d, w, n in P)


def fields(P, prefix):
    """prefix 下的字段表 [(字段名, 位宽)]，按 golden 端口顺序。"""
    return [(n[len(prefix):], w) for _, w, n in P if n.startswith(prefix)]


def cat(prefix, flds, present, ind):
    """MSB 优先拼接；不在 present 里的字段填 0。"""
    items = []
    for f, w in flds:
        if f in present:
            items.append(prefix + f)
        else:
            items.append("%d'h0 /* 本口无 %s */" % (w, f))
    return '{' + (',\n' + ' ' * ind).join(items) + '}'


def offsets(flds):
    """MSB 优先拼接时每个字段的最低位偏移。"""
    off = {}
    pos = sum(w for _, w in flds)
    for f, w in flds:
        pos -= w
        off[f] = pos
    assert pos == 0
    return off


def pins_tcl(mod, tag, expect, lines):
    L = []
    W = L.append
    W('# %s FM「匹配前」钉点 —— 自动生成：scripts/gen_payload_shells.py（勿手改）' % mod)
    W('#')
    W('# 只消 golden 逐字段寄存器名与核里打包向量之间的命名鸿沟。set_user_match 只是声明两点对应，')
    W('# 比较照比：不约束 ref、不改 appvar、不加黑盒。fail-closed：set_user_match 从不抛异常')
    W('# （返回 0 = 没配上），逐条数返回值；拒一条或总数不等于字面整数（= golden 顶层寄存器位数）')
    W('# 就 error（safe interp 里不用 exit）。子模块内部不钉。进 fm.log 的输出一律 ASCII。')
    W('set ::%s_PIN_EXPECT %d' % (tag, expect))
    W('set ::%s_PIN_OK 0' % tag)
    W('set ::%s_PIN_BAD 0' % tag)
    W('proc %s_pin {r m} {' % tag.lower())
    W('  if {[set_user_match $r $m]} { incr ::%s_PIN_OK } else {' % tag)
    W('    incr ::%s_PIN_BAD' % tag)
    W('    if {$::%s_PIN_BAD <= 10} { puts "%s_PIN_FAIL: $r <-> $m" }' % (tag, tag))
    W('  }')
    W('}')
    W('puts "%s_PIN_BEGIN %s expect=$::%s_PIN_EXPECT"' % (tag, mod, tag))
    for r, m in lines:
        W('%s_pin {%s} {%s}' % (tag.lower(), r, m))      # 花括号：路径里的 [N] 不许被 Tcl 当命令替换
    W('puts "%s_PIN_END %s ok=$::%s_PIN_OK bad=$::%s_PIN_BAD"' % (tag, mod, tag, tag))
    W('if {$::%s_PIN_BAD != 0} { error "%s_PIN_MISS=$::%s_PIN_BAD" }' % (tag, tag, tag))
    W('if {$::%s_PIN_OK != %d} { error "%s_PIN_COUNT=$::%s_PIN_OK expect=%d" }' % (tag, expect, tag, tag, expect))
    return '\n'.join(L) + '\n'


def reg_pin_lines(mod, golden_regs, vec_of, off_of):
    """golden 每个寄存器位 -> 核里向量位。vec_of(name) 给 (向量名, 字段名) 或 None（同名标量寄存器）。"""
    lines = []
    total = 0
    for name, w in golden_regs:
        hit = vec_of(name)
        for b in range(w):
            r = 'r:/WORK/%s/%s_reg' % (mod, name) + ('[%d]' % b if w > 1 else '')
            if hit is None:
                m = 'i:/WORK/%s/u_core/%s_reg' % (mod, name) + ('[%d]' % b if w > 1 else '')
            else:
                vec, fld = hit
                m = 'i:/WORK/%s/u_core/%s_reg[%d]' % (mod, vec, off_of[vec][fld] + b)
            lines.append((r, m))
        total += w
    return lines, total


# ---------------------------------------------------------------------------
# PTWRepeaterNB
# ---------------------------------------------------------------------------
def emit_ptwrepeater():
    mod = 'PTWRepeaterNB'
    P, glines, gregs = ports(mod)
    names = [n for _, _, n in P]
    req = fields(P, 'io_tlb_req_0_bits_')
    resp = fields(P, 'io_ptw_resp_bits_')
    assert req == fields(P, 'io_ptw_req_0_bits_'), 'req 两侧字段表不同'
    assert resp == fields(P, 'io_tlb_resp_bits_'), 'resp 两侧字段表不同'
    ctrl = ['clock', 'reset', 'io_sfence_valid', 'io_csr_satp_changed', 'io_csr_vsatp_changed',
            'io_csr_hgatp_changed', 'io_csr_priv_virt_changed',
            'io_tlb_req_0_ready', 'io_tlb_req_0_valid', 'io_tlb_resp_ready', 'io_tlb_resp_valid',
            'io_ptw_req_0_ready', 'io_ptw_req_0_valid', 'io_ptw_resp_ready', 'io_ptw_resp_valid']
    known = set(ctrl) | set('io_tlb_req_0_bits_' + f for f, _ in req) | set('io_ptw_req_0_bits_' + f for f, _ in req) \
        | set('io_tlb_resp_bits_' + f for f, _ in resp) | set('io_ptw_resp_bits_' + f for f, _ in resp)
    assert known == set(names), sorted(set(names) ^ known)[:5]
    req_w = sum(w for _, w in req)
    resp_w = sum(w for _, w in resp)
    off = {'req': offsets(req), 'resp': offsets(resp)}
    # golden 寄存器：sent / recv 同名标量；req_<f> / resp_<f> 进向量
    reqf = {f for f, _ in req}
    respf = {f for f, _ in resp}

    def vec_of(name):
        if name in ('sent', 'recv'):
            return None
        if name.startswith('req_') and name[4:] in reqf:
            return ('req', name[4:])
        if name.startswith('resp_') and name[5:] in respf:
            return ('resp', name[5:])
        raise SystemExit('%s: golden 寄存器 %s 落不进已知形状' % (mod, name))
    pin_lines, total = reg_pin_lines(mod, gregs, vec_of, off)
    assert total == 2 + req_w + resp_w, (total, req_w, resp_w)

    L = []
    W = L.append
    W('// %s.sv —— L1 TLB 与 L2TLB 之间的单项请求/应答中继（薄文件）' % mod)
    W('//')
    W('// 核在 rtl/mmu/xs_PTWRepeaterNB_core.sv（请求 / 应答两条独立的单项通路，各一个"在手"标志；机制与怪癖讲在那里）。')
    W('// 本文件把 golden 端口表里的字段按端口顺序 MSB 优先拼成两根打包向量交给核：')
    W('//   req  = io_*_req_0_bits_*  共 %d 个字段 %d 位（vpn + s2xlate）' % (len(req), req_w))
    W('//   resp = io_*_resp_bits_*   共 %d 个字段 %d 位（PtwRespS2：s1 页表项 + s2 页表项 + 故障位）' % (len(resp), resp_w))
    W('// flush 源 = sfence.valid | satp/vsatp/hgatp.changed | priv.virt_changed，在核里经 DelayN_1 打一拍。')
    W('// golden %d 行 / %d 端口；本文件由 scripts/gen_payload_shells.py 从 golden 端口表生成（勿手改）。' % (glines, len(P)))
    W('')
    W('module %s (' % mod)
    W(port_decl(P))
    W(');')
    W('')
    W('  localparam int unsigned REQ_W  = %d;' % req_w)
    W('  localparam int unsigned RESP_W = %d;' % resp_w)
    W('')
    W('  logic [REQ_W-1:0]  tlb_req_bits, ptw_req_bits;')
    W('  logic [RESP_W-1:0] ptw_resp_bits, tlb_resp_bits;')
    W('')
    W('  assign tlb_req_bits  = %s;' % cat('io_tlb_req_0_bits_', req, reqf, 26))
    W('  assign ptw_resp_bits = %s;' % cat('io_ptw_resp_bits_', resp, respf, 26))
    W('')
    W('  xs_PTWRepeaterNB_core #(')
    W('    .REQ_W (REQ_W),')
    W('    .RESP_W(RESP_W)')
    W('  ) u_core (')
    W('    .clock         (clock),')
    W('    .reset         (reset),')
    W('    .flush_src     (io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed |')
    W('                    io_csr_hgatp_changed | io_csr_priv_virt_changed),')
    W('    .tlb_req_ready (io_tlb_req_0_ready),')
    W('    .tlb_req_valid (io_tlb_req_0_valid),')
    W('    .tlb_req_bits  (tlb_req_bits),')
    W('    .tlb_resp_ready(io_tlb_resp_ready),')
    W('    .tlb_resp_valid(io_tlb_resp_valid),')
    W('    .tlb_resp_bits (tlb_resp_bits),')
    W('    .ptw_req_ready (io_ptw_req_0_ready),')
    W('    .ptw_req_valid (io_ptw_req_0_valid),')
    W('    .ptw_req_bits  (ptw_req_bits),')
    W('    .ptw_resp_ready(io_ptw_resp_ready),')
    W('    .ptw_resp_valid(io_ptw_resp_valid),')
    W('    .ptw_resp_bits (ptw_resp_bits)')
    W('  );')
    W('')
    W('  assign %s = ptw_req_bits;' % cat('io_ptw_req_0_bits_', req, reqf, 10))
    W('  assign %s = tlb_resp_bits;' % cat('io_tlb_resp_bits_', resp, respf, 10))
    W('')
    W('endmodule')
    return {os.path.join(REPO, 'rtl', 'mmu', mod + '.sv'): '\n'.join(L) + '\n',
            os.path.join(REPO, 'verif', 'ut', mod, 'fm_pins_pre.tcl'): pins_tcl(mod, 'PTWRNB', total, pin_lines)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    outs = {}
    outs.update(emit_ptwrepeater())
    bad = 0
    for p, txt in outs.items():
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad = 1
        elif cur != txt:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            open(p, 'w').write(txt)
            print('wrote %s' % p)
    if a.check and not bad:
        print('OK: gen_payload_shells.py（%d 个文件与生成结果一致）' % len(outs))
    return bad


if __name__ == '__main__':
    sys.exit(main())
