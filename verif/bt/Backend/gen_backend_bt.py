#!/usr/bin/env python3
# 由 golden Backend.sv 生成 Backend_bt.sv:
#   - module Backend( -> module Backend_bt(
#   - 把选定子模块实例的「模块名」换成 _bt 包装(端口逐字 = golden, 直接按名替换实例化首token)
#   - 其余 golden 互联 body / 子模块全部保留 golden(本 BT 只换这些重写核)
import re, sys
SWAP = {
  # golden module name -> _bt wrapper  (instance line: '  <Mod> inner_xxx (')
  'WbFuBusyTable': 'WbFuBusyTable_bt',
  'DataPath':      'DataPath_bt',
  'BypassNetwork': 'BypassNetwork_bt',
}
# allow choosing subset via argv (default all)
if len(sys.argv)>1:
    keep=set(sys.argv[1:])
    SWAP={k:v for k,v in SWAP.items() if k in keep}

src=open('../../../golden/chisel-rtl/Backend.sv').read()
out=[]
swapped={k:0 for k in SWAP}
for line in src.split('\n'):
    m=re.match(r'^(\s*)([A-Za-z_][A-Za-z0-9_]*)(\s+inner_[A-Za-z0-9_]*\s*\()\s*$', line)
    if m and m.group(2) in SWAP:
        line=f"{m.group(1)}{SWAP[m.group(2)]}{m.group(3)}"
        swapped[m.group(2)]+=1
    elif line.startswith('module Backend('):
        line=line.replace('module Backend(','module Backend_bt(')
    out.append(line)
open('Backend_bt.sv','w').write('\n'.join(out))
print("Backend_bt.sv written. swaps:",swapped, " (active:",list(SWAP.keys()),")")
