#!/usr/bin/env python3
# 由 golden Backend.sv 生成 Backend_bt.sv:
#   - module Backend( -> module Backend_bt(
#   - 把选定子模块实例的「模块名」换成 _bt 包装(端口逐字 = golden, 直接按名替换实例化首token)
#   - 其余 golden 互联 body / 子模块全部保留 golden(本 BT 只换这些重写核)
import re, sys
# golden module name -> _bt wrapper  (instance line: '  <Mod> inner_xxx (')
# 全部候选(gen_bt.py 都已生成 _bt 包装):
ALL = {
  'WbFuBusyTable': 'WbFuBusyTable_bt',   # 已纳入(active)
  'BypassNetwork': 'BypassNetwork_bt',   # 已纳入(active)
  'WbDataPath':    'WbDataPath_bt',       # 已纳入(active)
  'Scheduler':     'Scheduler_bt',        # 已纳入(active, Int Scheduler 子树)
  'DataPath':      'DataPath_bt',         # 纳入不了: DPIC 撞名 + 210 instance-port output tie0
  'ExuBlock':      'ExuBlock_bt',         # 纳入不了: 重写核省略 FU ready/data/redirect/debug
  'ExuBlock_1':    'ExuBlock_1_bt',       # 纳入不了: 同上(ExeUnit_9 含 FDivSqrt 动态 ready)
}
# 默认只换 **已验证可纳入** 的 4 个(避免无参误换入未建/受阻包装);argv 可显式覆盖。
DEFAULT_ACTIVE = ['WbFuBusyTable','BypassNetwork','WbDataPath','Scheduler']
keep = set(sys.argv[1:]) if len(sys.argv)>1 else set(DEFAULT_ACTIVE)
SWAP = {k:v for k,v in ALL.items() if k in keep}

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
