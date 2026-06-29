#!/usr/bin/env python3
# 由 rtl/memblock/{MemBlock.sv, memblock_inst.svh} 生成 MemBlock BT 装配:
#   1) memblock_inst_bt.svh = golden 互联实例表(逐字 = rewrite 核的 memblock_inst.svh),
#      只把 clean-swap-set 子模块实例的「模块名」换成重写件:
#        - 需补 golden-only 端口的: 换成 <M>_bt 全端口包装(内含 <M>_xs → xs_<M>_core)
#        - 端口逐字等于 golden 的:   直接换成 <M>_xs 适配器(PMP/PMPChecker_10)
#      其余 ~60 子模块实例保留 golden(本 BT 不换这些——无重写核或非干净双例化)。
#   2) MemBlock_bt.sv = rewrite 核 rtl/memblock/MemBlock.sv 逐字, 但
#        module xs_MemBlock_core -> module xs_MemBlock_core_bt
#        `include "memblock_inst.svh" -> `include "memblock_inst_bt.svh"
#      并追加 module MemBlock_bt(全 golden 端口) 包装, 例化 xs_MemBlock_core_bt u_core。
# 重写核的端口表/内部网/顶层逻辑/perf 全部复用(rtl/memblock 经 +incdir 提供)。
import re, os
HERE=os.path.dirname(os.path.abspath(__file__)); os.chdir(HERE)
RTL='../../../rtl/memblock'

# clean swap set: golden module instance -> rewrite module to use
#   值带 '_bt' 的需要全端口包装(已由 gen_bt.py 生成); 其余直接用 _xs 适配器。
SWAP_BT  = {  # need full-port _bt wrapper
  'DCacheWrapper': 'DCacheWrapper_bt',
  'Uncache':       'Uncache_bt',
  'L2TLBWrapper':  'L2TLBWrapper_bt',
  'Sbuffer':       'Sbuffer_bt',
  'TLBNonBlock':   'TLBNonBlock_bt',   # ld DTLB only (TLBNonBlock_1/_2 不同参数, 保留 golden)
}
SWAP_XS  = {  # adapter ports == golden ports exactly, swap module name directly
  'PMP':           'PMP_xs',
  'PMPChecker_10': 'PMPChecker_10_xs',
}
SWAP={**SWAP_BT, **SWAP_XS}

# 可选: 命令行限定只换哪些 golden 模块(用于二分定位发散核)。默认全换。
import sys
if len(sys.argv)>1:
    keep=set(sys.argv[1:])
    SWAP={k:v for k,v in SWAP.items() if k in keep}

# ---- 1) build memblock_inst_bt.svh -----------------------------------------
src=open(f'{RTL}/memblock_inst.svh').read().split('\n')
out=[]; swapped={k:0 for k in SWAP}
inst_re=re.compile(r'^(\s*)([A-Za-z_][A-Za-z0-9_]*)(\s+inner_[A-Za-z0-9_]*\s*\(\s*)$')
for line in src:
    m=inst_re.match(line)
    if m and m.group(2) in SWAP:
        line=f"{m.group(1)}{SWAP[m.group(2)]}{m.group(3)}"
        swapped[m.group(2)]+=1
    out.append(line)
open('memblock_inst_bt.svh','w').write('\n'.join(out))
print("memblock_inst_bt.svh swaps:", swapped)

# ---- 2) build MemBlock_bt.sv (rewrite core renamed + golden-port wrapper) ----
core=open(f'{RTL}/MemBlock.sv').read()
core=core.replace('module xs_MemBlock_core', 'module xs_MemBlock_core_bt')
core=core.replace('`include "memblock_inst.svh"', '`include "memblock_inst_bt.svh"')

# wrapper: full golden MemBlock ports, instantiate xs_MemBlock_core_bt by name.
def mod_ports(path,mod):
    t=open(path).read()
    m=re.search(r'(?m)^module\s+'+re.escape(mod)+r'\b',t)
    p=t.index('(',m.start()); r=t[p+1:]; e=re.search(r'\n\);',r); body=r[:e.start()]
    PORT=re.compile(r'(input|output|inout)\s+(?:wire\s+|reg\s+|logic\s+)*(\[[^\]]+\]\s*)?([A-Za-z_][A-Za-z0-9_]*)$')
    o=[]
    for line in body.split('\n'):
        line=line.split('//')[0].strip().rstrip(',')
        mm=PORT.match(line)
        if mm:o.append((mm.group(1),(mm.group(2)or'').strip(),mm.group(3)))
    return o

# 用 MemBlock_wrapper.sv 的 module MemBlock( 端口 = golden 顶层端口(已核对)。
wp=mod_ports(f'{RTL}/MemBlock_wrapper.sv','MemBlock')
w=[]
w.append("// 自动生成: verif/bt/MemBlock/gen_memblock_bt.py —— 勿手改")
w.append("// MemBlock_bt: 全 golden 端口顶层, 例化重写互联核 xs_MemBlock_core_bt")
w.append("//   (核里 clean-swap-set 子模块实例已换成重写件 _bt/_xs, 其余子模块保留 golden)。")
w.append("module MemBlock_bt(")
w.append(",\n".join(f"  {d} {wd+' ' if wd else ''}{n}" for d,wd,n in wp))
w.append(");")
w.append("  xs_MemBlock_core_bt u_core (")
w.append(",\n".join(f"    .{n}({n})" for d,wd,n in wp))
w.append("  );")
w.append("endmodule")

open('MemBlock_bt.sv','w').write(core+"\n\n"+"\n".join(w)+"\n")
print(f"MemBlock_bt.sv written ({len(wp)} top ports)")
