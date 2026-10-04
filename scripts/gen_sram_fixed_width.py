#!/usr/bin/env python3
"""gen_sram_fixed_width.py —— SRAMTemplateWithFixedWidth 家族（4 个变体）薄文件生成器。

家族：ICache 数据阵列（ICacheDataArray）里每个 (way, bank) 一块 SRAMTemplateWithFixedWidth，
Chisel 定义在 frontend/icache/ICache.scala:835。它把一条 dataBits 位的数据按固定宽度 width
切成 bankNum = ceil(dataBits / width) 块，每块一个 SRAMTemplate。本配置 dataBits = 65
（ICacheDataEntryBits：64 位数据 + 1 位校验）、width = 66（ICacheDataSRAMWidth），所以
bankNum = 1：只有一块 66 位宽的 SRAM，写入时高位补 1 个 0，读出时截掉最高位。

4 个 golden 变体逻辑完全相同，唯一差别是内层 SRAMTemplate 的单态化（SRAMTemplate_4/_8/_16/_32），
而它们之间又只差 MBIST bore_array 的位宽（3/4/5/6 位：ICache 数据阵列 32 块 SRAM 在 MBIST
分发树里的 array 编号越往后越大，firtool 按最小位宽生成）。

本脚本**每次运行都重新核对 golden**（fail-closed，任何一条不符即拒绝生成）：
  1. 端口表逐项解析，只允许出现模板里的端口名，位宽与 SRAM 宽度自洽；
  2. golden 体内恰好一个例化 `SRAMTemplate_<n> srams_0`，逐端口连接与模板逐字相同
     （写数据 = {1'h0, io_w_req_bits_data_0}、ram_ctl = 64'h0、其余同名直连）；
  3. 唯一一条 assign 是 `io_r_resp_data_0 = _srams_0_io_r_resp_data_0[64:0]`。

用法：python3 scripts/gen_sram_fixed_width.py [--check]
"""
import argparse
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = os.path.join(REPO, 'rtl', 'frontend')
VARIANTS = ['SRAMTemplateWithFixedWidth', 'SRAMTemplateWithFixedWidth_4',
            'SRAMTemplateWithFixedWidth_12', 'SRAMTemplateWithFixedWidth_28']
PORT_RE = re.compile(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$')
DATA_W, SRAM_W = 65, 66


def fail(m, msg):
    raise SystemExit('gen_sram_fixed_width: %s: %s' % (m, msg))


def parse(m):
    txt = open(os.path.join(G, m + '.sv')).read()
    i = txt.index('\nmodule %s(' % m) + 1
    j = txt.index('\n);', i)
    P = []
    for ln in txt[i:j].splitlines()[1:]:
        r = PORT_RE.match(ln)
        if not r:
            fail(m, '端口行解析失败: %r' % ln)
        P.append((r.group(1), int(r.group(2)) + 1 if r.group(2) else 1, r.group(3)))
    W = {n: w for _, w, n in P}
    if W.get('io_w_req_bits_data_0') != DATA_W or W.get('io_r_resp_data_0') != DATA_W:
        fail(m, '数据端口宽度不是 %d' % DATA_W)
    if W.get('boreChildrenBd_bore_wdata') != SRAM_W:
        fail(m, 'bore_wdata 宽度不是 SRAM 宽 %d' % SRAM_W)
    body = txt[j:txt.index('\nendmodule', j)]
    insts = re.findall(r'\n  (\w+) (\w+) \(', body)
    if len(insts) != 1 or insts[0][1] != 'srams_0' or not re.match(r'SRAMTemplate_\d+$', insts[0][0]):
        fail(m, '体内例化不是唯一一个 SRAMTemplate_<n> srams_0: %s' % insts)
    child = insts[0][0]
    conns = dict(re.findall(r'\.(\w+)\s*\(([^()]*(?:\([^()]*\))?[^()]*)\)', body))
    expect = {}
    for d, w, n in P:
        if n in ('clock', 'reset'):
            expect[n] = n
        elif n.startswith('boreChildrenBd_'):
            expect[n] = n
        elif n.startswith('sigFromSrams_bore_'):
            k = n[len('sigFromSrams_bore_'):]
            expect['io_broadcast_' + k] = n
        elif n in ('io_r_req_valid', 'io_r_req_bits_setIdx', 'io_w_req_valid', 'io_w_req_bits_setIdx'):
            expect[n] = n
    expect['io_r_resp_data_0'] = '_srams_0_io_r_resp_data_0'
    expect['io_w_req_bits_data_0'] = '{1\'h0, io_w_req_bits_data_0}'
    expect['io_broadcast_ram_ctl'] = '64\'h0'
    got = {k: re.sub(r'\s+', ' ', v).strip() for k, v in conns.items()}
    if got != expect:
        fail(m, '例化连接与模板不符: 多 %s / 少或不同 %s'
             % (sorted(set(got.items()) - set(expect.items())),
                sorted(set(expect.items()) - set(got.items()))))
    assigns = re.findall(r'assign\s+(\w+)\s*=\s*(.*?);', body, re.S)
    if assigns != [('io_r_resp_data_0', '_srams_0_io_r_resp_data_0[64:0]')]:
        fail(m, 'assign 集合与模板不符: %s' % assigns)
    return dict(m=m, P=P, child=child, aw=W['boreChildrenBd_bore_array'],
                glines=len(txt.splitlines()))


def emit(R):
    m, child = R['m'], R['child']
    L = []
    A = L.append
    if m == 'SRAMTemplateWithFixedWidth':
        A('// SRAMTemplateWithFixedWidth.sv —— ICache 数据阵列的一块"定宽切分"SRAM（家族基础变体）')
        A('//')
        A('// 位置：ICacheDataArray 里每个 (way, bank) 一块（frontend/icache/ICache.scala:437 例化，')
        A('//   类定义在同文件 :835）。它的本职是把一条 dataBits 位的数据按固定宽度 width 切成')
        A('//   bankNum = ceil(dataBits/width) 块、每块一个 SRAMTemplate，读回再拼起来，让所有 ICache')
        A('//   数据 SRAM 宏都是同一个尺寸。')
        A('// 本配置：dataBits = 65（ICacheDataEntryBits：64 位数据 + 1 位校验），width = 66，')
        A('//   所以 bankNum = 1 —— 只有一块 66 位宽的 SRAM：写入时高位补 1 个 0，读出时截掉最高位。')
        A('//   本层没有寄存器、没有运算，读写握手（ready）因父级不用被 firtool 删掉了。')
        A('// 家族：本文件与 _4 / _12 / _28 四个变体逻辑完全相同，唯一差别是内层 SRAMTemplate 的单态化')
        A('//   （SRAMTemplate_4 / _8 / _16 / _32），它们之间只差 MBIST bore_array 位宽（3/4/5/6 位，')
        A('//   ICache 数据阵列 32 块 SRAM 的 MBIST array 编号越往后越大，firtool 按最小位宽生成）。')
        A('//   子模块的模块名不能参数化，所以每个变体自带这一处例化（由生成器从 golden 核对后产出）。')
    else:
        A('// %s.sv —— ICache 数据阵列的一块"定宽切分"SRAM（SRAMTemplateWithFixedWidth 家族变体）' % m)
        A('//')
        A('// 本变体参数：内层 SRAM = %s，MBIST bore_array %d 位；其余（65 位数据 → 66 位宽单块 SRAM，' % (child, R['aw']))
        A('//   写入高位补 0、读出截掉最高位）与家族基础变体完全相同，')
        A('//   机制讲在 rtl/frontend/SRAMTemplateWithFixedWidth.sv 的文件头。')
    A('// golden %d 行 / %d 端口；唯一子模块 %s（已独立签核）。' % (R['glines'], len(R['P']), child))
    A('// 本文件由 scripts/gen_sram_fixed_width.py 从 golden 机械生成并逐端口核对（勿手改）。')
    A('')
    A('// BEGIN GENERATED(%s) —— scripts/gen_sram_fixed_width.py' % m)
    A('module %s (' % m)
    A(',\n'.join('  %-6s logic %s%s' % (d, ('[%d:0]' % (w - 1)).ljust(7) if w > 1 else ' ' * 7, n)
                 for d, w, n in R['P']))
    A(');')
    A('')
    A('  localparam int unsigned DATA_W = %d;   // ICacheDataEntryBits' % DATA_W)
    A('  localparam int unsigned SRAM_W = %d;   // ICacheDataSRAMWidth（bankNum = 1）' % SRAM_W)
    A('')
    A('  logic [SRAM_W-1:0] sram_rdata;')
    A('')
    A('  // 唯一一块 SRAM：写数据零扩展到 SRAM 宽，DFT 广播/bore 口原样透传')
    A('  %s srams_0 (' % child)
    conns = []
    for d, w, n in R['P']:
        if n in ('clock', 'reset', 'io_r_req_valid', 'io_r_req_bits_setIdx',
                 'io_w_req_valid', 'io_w_req_bits_setIdx') or n.startswith('boreChildrenBd_'):
            conns.append((n, n))
        elif n == 'io_r_resp_data_0':
            conns.append((n, 'sram_rdata'))
        elif n == 'io_w_req_bits_data_0':
            conns.append((n, 'SRAM_W\'(io_w_req_bits_data_0)'))
        elif n.startswith('sigFromSrams_bore_'):
            k = n[len('sigFromSrams_bore_'):]
            conns.append(('io_broadcast_' + k, n))
            if k == 'ram_mcp_hold':
                conns.append(('io_broadcast_ram_ctl', '64\'h0'))
    A(',\n'.join('    .%-30s (%s)' % c for c in conns))
    A('  );')
    A('')
    A('  // 读回截掉补的最高位')
    A('  assign io_r_resp_data_0 = sram_rdata[DATA_W-1:0];')
    A('')
    A('endmodule')
    A('// END GENERATED(%s)' % m)
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    bad = 0
    for m in VARIANTS:
        R = parse(m)
        txt = emit(R)
        p = os.path.join(OUT, m + '.sv')
        cur = open(p).read() if os.path.exists(p) else None
        if a.check:
            if cur != txt:
                print('DRIFT: %s' % p)
                bad += 1
        elif cur != txt:
            open(p, 'w').write(txt)
        print('%-32s child=%-16s bore_array=%d' % (m, R['child'], R['aw']))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
