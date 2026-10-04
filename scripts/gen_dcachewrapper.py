#!/usr/bin/env python3
"""gen_dcachewrapper.py —— DCacheWrapper（L1 数据缓存 DCache 的 LazyModule 外壳）的全部机械产物。

src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala，class DCacheWrapper / DCacheWrapperImp：
  * `io <> dcache.module.io`：除 perf 外的端口原样接到 DCache 实例 dcache；
  * diplomacy 的 uncacheNode 接到 dcache.cacheCtrlOpt.node：外壳端口叫 auto_uncache_in_*，
    DCache 端口叫 auto_cacheCtrlOpt_in_*，逐个对应（CtrlUnit 的 TL-UL 寄存器口，注入伪 ECC 错误用）；
  * HasPerfEvents.generatePerfEvent()：DCache 报上来的 40 个 perf 事件计数（各 6 位）再各打两拍送出（不复位）。
golden 除这 480 位寄存器外全是 dcache 实例的逐端口连线。

本脚本生成 4 份文件（--check 时逐字比较、不写）：
  1. rtl/memblock/DCacheWrapper.sv：整份 wrapper（端口表从 golden 现读；DCache 端口表必须与 wrapper 端口表
     在 uncache<->cacheCtrlOpt 换名后逐名逐宽相同；perf 口只能是 io_perf_<n>_value、6 位、40 个；
     golden 的 dcache 实例连线逐项与生成的连线比对）。
  2. verif/ut/DCacheWrapper/fm_pins_pre.tcl：FM「匹配前」钉点 =
     (a) 本层 480 位 perf 寄存器：golden io_perf_<n>_value_REG / _REG_1 <-> 数组 perf_stage1[n] / perf_stage2[n]；
     (b) DCache 子树：**原样收割** verif/ut/DCache/fm_pins_pre.tcl（DCache 单独签核时那份）的全部点对，
         只把根从 /WORK/DCache 换成 /WORK/DCacheWrapper/dcache —— 与 DCache 单独签核是同一批点对。
     收割读不到、格式不认识、条数与该文件字面期望不符，都直接失败。
  3. verif/allow/DCacheWrapper.json：黑盒声明 = verif/allow/DCache.json 逐项把路径根换成 .../DCacheWrapper/dcache/
     （厂商 SRAM 叶子 array_7_ext ×32 / array_8_ext ×8 与 golden 侧被 firtool 消空的 StorePipe 两侧各一份），不增不减。

用法：python3 scripts/gen_dcachewrapper.py [--check]
"""
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
MOD, CHILD, INST = 'DCacheWrapper', 'DCache', 'dcache'
OUT_RTL = os.path.join(REPO, 'rtl', 'memblock', MOD + '.sv')
OUT_PINS = os.path.join(REPO, 'verif', 'ut', MOD, 'fm_pins_pre.tcl')
OUT_ALLOW = os.path.join(REPO, 'verif', 'allow', MOD + '.json')
SRC_PINS = os.path.join(REPO, 'verif', 'ut', CHILD, 'fm_pins_pre.tcl')
SRC_ALLOW = os.path.join(REPO, 'verif', 'allow', CHILD + '.json')
NUM_PERF, PERF_W = 40, 6
PERF_RE = re.compile(r'io_perf_(\d+)_value$')


def die(msg):
    raise SystemExit('gen_dcachewrapper: ' + msg)


def ports(mod):
    t = open(os.path.join(G, mod + '.sv')).read()
    i = t.index('\nmodule %s(' % mod) + 1
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if not m:
            die('%s: 端口行解析失败: %r' % (mod, line))
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out, t.count('\n') + 1


def child_port(n):
    return n.replace('auto_uncache_in_', 'auto_cacheCtrlOpt_in_')


def golden_conn():
    t = open(os.path.join(G, MOD + '.sv')).read()
    m = re.search(r'^  %s %s \((.*?)^  \);' % (CHILD, INST), t, re.S | re.M)
    if not m:
        die('golden 里找不到 %s %s 实例' % (CHILD, INST))
    return {c.group(1): ' '.join(c.group(2).split())
            for c in re.finditer(r'\.(\w+)\s*\((.*?)\)(?:,|\s*$)', m.group(1), re.S)}


def emit_rtl():
    P, glines = ports(MOD)
    C, _ = ports(CHILD)
    if [(d, w, child_port(n)) for d, w, n in P] != C:
        die('wrapper 端口表（uncache->cacheCtrlOpt 换名后）与 DCache 端口表不同')
    perf = [(int(PERF_RE.match(n).group(1)), d, w) for d, w, n in P if PERF_RE.match(n)]
    if sorted(k for k, _, _ in perf) != list(range(NUM_PERF)) or any(d != 'output' or w != PERF_W for _, d, w in perf):
        die('perf 口不是 40 个 6 位输出')
    gc = golden_conn()
    L = []
    A = L.append
    A('// %s.sv —— L1 数据缓存 DCache 的外壳：端口直通 + perf 计数打两拍' % MOD)
    A('//')
    A('// 位置：MemBlock 里的 dcache（src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala，class DCacheWrapper）。')
    A('//   它只做三件事：')
    A('//   1. `io <> dcache.module.io`：LSU / 预取 / 错误上报 / MBIST 等端口原样接到 DCache 实例 dcache；')
    A('//   2. diplomacy 的 uncacheNode 接到 DCache 的 cacheCtrlOpt 节点（CtrlUnit 的 TL-UL 寄存器口，软件经它')
    A('//      注入伪 ECC 错误）：外壳端口 auto_uncache_in_* <-> DCache 端口 auto_cacheCtrlOpt_in_*，逐个直连；')
    A('//   3. HasPerfEvents.generatePerfEvent()：DCache 报上来的 %d 个 perf 事件计数（各 %d 位）各打两拍再送出' % (NUM_PERF, PERF_W))
    A('//      （两级寄存器都不复位；DCache 内部已经各打过两拍，所以端口上一共晚 4 拍）。')
    A('// 子模块 DCache 是本仓的独立签核目标（rtl/memblock/DCache.sv，xs_DCache_core），本层证明时两侧白盒。')
    A('// golden %d 行 / %d 端口；本文件由 scripts/gen_dcachewrapper.py 从 golden 端口表生成（勿手改）。' % (glines, len(P)))
    A('')
    A('module %s (' % MOD)
    A(',\n'.join('  %-6s %-9s%s' % (d, '' if w == 1 else '[%d:0]' % (w - 1), n) for d, w, n in P))
    A(');')
    A('')
    A('  // ---- perf 计数打两拍（不复位）----')
    A('  localparam int unsigned NUM_PERF = %d;' % NUM_PERF)
    A('  logic [%d:0] dcache_perf [NUM_PERF];   // DCache 实例报上来的计数' % (PERF_W - 1))
    A('  logic [%d:0] perf_stage1 [NUM_PERF];' % (PERF_W - 1))
    A('  logic [%d:0] perf_stage2 [NUM_PERF];' % (PERF_W - 1))
    A('')
    A('  always_ff @(posedge clock) begin')
    A('    for (int n = 0; n < NUM_PERF; n++) begin')
    A('      perf_stage1[n] <= dcache_perf[n];')
    A('      perf_stage2[n] <= perf_stage1[n];')
    A('    end')
    A('  end')
    A('')
    for k in range(NUM_PERF):
        A('  assign io_perf_%d_value = perf_stage2[%d];' % (k, k))
    A('')
    A('  // ---- DCache 实例（实例名同 golden）----')
    A('  %s %s (' % (CHILD, INST))
    cl = []
    for d, w, n in P:
        cp = child_port(n)
        m = PERF_RE.match(n)
        tgt = 'dcache_perf[%s]' % m.group(1) if m else n
        g = gc.get(cp)
        gexp = ('_dcache_io_perf_%s_value' % m.group(1)) if m else n
        if g != gexp:
            die('dcache.%s golden 接 %s，期望 %s' % (cp, g, gexp))
        cl.append('    .%-51s (%s)' % (cp, tgt))
    if set(gc) != {child_port(n) for _, _, n in P}:
        die('golden dcache 实例连线端口集合与端口表不符')
    A(',\n'.join(cl))
    A('  );')
    A('')
    A('endmodule')
    return '\n'.join(L) + '\n'


def harvest_dcache_pins():
    t = open(SRC_PINS).read()
    m_exp = re.search(r'^\s*set _expect (\d+)$', t, re.M)
    m_r = re.search(r'^\s*set r "r:/WORK/DCache"$', t, re.M)
    m_i = re.search(r'^\s*set i "i:/WORK/DCache"$', t, re.M)
    m_p = re.search(r'^\s*set pairs \{\n(.*?)^\s*\}\n', t, re.S | re.M)
    if not (m_exp and m_r and m_i and m_p):
        die('认不出 %s 的格式（set _expect / set r / set i / set pairs）' % SRC_PINS)
    pairs = []
    for line in m_p.group(1).splitlines():
        if not line.strip():
            continue
        m = re.fullmatch(r'\s*\{([^{}]+)\} \{([^{}]+)\}', line)
        if not m:
            die('%s 里认不出的点对行：%r' % (SRC_PINS, line))
        pairs.append((m.group(1), m.group(2)))
    if len(pairs) != int(m_exp.group(1)):
        die('收割 %d 对，DCache 钉点文件字面期望 %s' % (len(pairs), m_exp.group(1)))
    return pairs


def emit_pins():
    own = []
    for k in range(NUM_PERF):
        for b in range(PERF_W):
            own.append(('io_perf_%d_value_REG_reg[%d]' % (k, b), 'perf_stage1_reg[%d][%d]' % (k, b)))
            own.append(('io_perf_%d_value_REG_1_reg[%d]' % (k, b), 'perf_stage2_reg[%d][%d]' % (k, b)))
    sub = harvest_dcache_pins()
    allp = own + [('%s/%s' % (INST, r), '%s/%s' % (INST, i)) for r, i in sub]
    if len({r for r, _ in allp}) != len(allp) or len({i for _, i in allp}) != len(allp):
        die('钉点不单射')
    n = len(allp)
    o = []
    o.append('# DCacheWrapper FM「匹配前」钉点 —— 自动生成：scripts/gen_dcachewrapper.py（勿手改）')
    o.append('#')
    o.append('# 组成：本层 perf 两级寄存器 %d 位（golden io_perf_<n>_value_REG / _REG_1 <-> perf_stage1/2[n]），' % len(own))
    o.append('#       + DCache 子树 %d 对：原样收割 verif/ut/DCache/fm_pins_pre.tcl，根换成 /WORK/DCacheWrapper/dcache。' % len(sub))
    o.append('# set_user_match 只声明两点对应，比较照比。fail-closed：拒一条或总数 != %d 即 error。输出一律 ASCII。' % n)
    o.append('proc _dcw_pre_pin { } {')
    o.append('    set _expect %d' % n)
    o.append('    set r "r:/WORK/%s"' % MOD)
    o.append('    set i "i:/WORK/%s"' % MOD)
    o.append('    puts "DCW_PREPIN_BEGIN %s expect=$_expect"' % MOD)
    o.append('    set pairs {')
    for r, i in allp:
        o.append('        {%s} {%s}' % (r, i))
    o.append('    }')
    o.append('    set n 0')
    o.append('    foreach {rp ip} $pairs {')
    o.append('        if {![set_user_match "$r/$rp" "$i/$ip"]} {')
    o.append('            puts "DCW_PREPIN_FAIL: set_user_match returned 0 for $r/$rp <-> $i/$ip"')
    o.append('            error "DCW_PREPIN_MISS=$rp"')
    o.append('        }')
    o.append('        incr n')
    o.append('    }')
    o.append('    puts "DCW_PREPIN_END %s n=$n expect=$_expect"' % MOD)
    o.append('    if {$n != $_expect} {')
    o.append('        puts "DCW_PREPIN_ERROR: pinned $n but expected $_expect"')
    o.append('        error "DCW_PREPIN_COUNT=$n"')
    o.append('    }')
    o.append('}')
    o.append('_dcw_pre_pin')
    return '\n'.join(o) + '\n'


def emit_allow():
    src = json.load(open(SRC_ALLOW))
    if src.get('target') != CHILD:
        die('%s 的 target 不是 DCache' % SRC_ALLOW)
    objs = []
    for o in src['objects']:
        pre = '%s:/WORK/%s/' % (o['side'], CHILD)
        if not o['path'].startswith(pre):
            die('allow 路径 %s 不以 %s 开头' % (o['path'], pre))
        n = dict(o)
        n['path'] = '%s:/WORK/%s/%s/%s' % (o['side'], MOD, INST, o['path'][len(pre):])
        objs.append(n)
    out = {'schema': src['schema'], 'target': MOD, 'baseline': src['baseline'], 'objects': objs}
    return json.dumps(out, indent=1, ensure_ascii=False) + '\n'


def main():
    check = '--check' in sys.argv[1:]
    rc = 0
    for path, txt in ((OUT_RTL, emit_rtl()), (OUT_PINS, emit_pins()), (OUT_ALLOW, emit_allow())):
        cur = open(path).read() if os.path.exists(path) else None
        if check:
            ok = cur == txt
            print(('OK: ' if ok else 'DRIFT: ') + path)
            rc |= 0 if ok else 1
        elif cur != txt:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, 'w').write(txt)
            print('wrote ' + path)
        else:
            print('unchanged ' + path)
    return rc


if __name__ == '__main__':
    sys.exit(main())
