#!/usr/bin/env python3
# 生成 RenameTableWrapper 的可读装配核 + 包装层 + UT 变体。
# RenameTableWrapper 是纯 wiring 壳(0 寄存器): 计算 6 端口共享的 arch/spec 写使能/地址/数据
# 派生信号, 分发给 5 个 RenameTable 实例(intRat/fpRat/vecRat/v0Rat/vlRat)。逻辑全在
# 这些 RenameTable 子里。故本层证明 = assembly: 5 实例对称黑盒, 只证 wrapper 派生 wire 与
# 实例端口连线 == golden。
#
# 生成法(机械): 取 golden RenameTableWrapper.sv 的 body, 去掉 `ifndef SYNTHESIS 断言块
# (只读死 wire _GEN_17.._GEN_28)+去掉这些死 wire 声明, 其余(派生 wire + 5 实例连线)原样
# 保留=忠实 wiring。核模块名 xs_RenameTableWrapper, 端口同 golden。
import re, sys

GOLD = "/home/eda/xs-env/G0-canonical/golden-rtl/RenameTableWrapper.sv"
OUT_CORE = "/tmp/xs-signoff-cb-children2/rtl/backend/RenameTableWrapper_core.sv"
OUT_WRAP = "/tmp/xs-signoff-cb-children2/rtl/backend/RenameTableWrapper_wrapper.sv"
OUT_XS   = "/tmp/xs-signoff-cb-children2/verif/ut/RenameTableWrapper/variants_xs.sv"

src = open(GOLD).read()
lines = src.split("\n")

# 定位 module 头与 body
mod_start = next(i for i,l in enumerate(lines) if l.startswith("module RenameTableWrapper("))
port_end  = next(i for i in range(mod_start, len(lines)) if lines[i].startswith(");"))
endmod    = next(i for i in range(len(lines)-1, 0, -1) if lines[i].strip()=="endmodule")

header = lines[mod_start:port_end+1]          # module ... );  (含端口)
body   = lines[port_end+1:endmod]             # body 到 endmodule 之前

# 提取端口名(用于 wrapper/xs 例化连线)
ports = []
for l in header[1:-1]:
    m = re.match(r"\s*(input|output)\s+(?:\[[^\]]+\]\s+)?(\w+)", l)
    if m: ports.append(m.group(2))

# 去掉 `ifndef SYNTHESIS ... `endif 断言块
out_body = []
skip = False
for l in body:
    if re.match(r"\s*`ifndef SYNTHESIS", l):
        skip = True; continue
    if skip and re.match(r"\s*`endif", l):
        skip = False; continue
    if skip:
        continue
    out_body.append(l)

# 去掉只被断言读的死 wire 声明 _GEN_17.._GEN_28 (整条 `wire ... _GEN_NN = ...;` 可能跨行)
# 先把 body 合成文本, 用正则删这些赋值(它们各是单条 assign-in-decl)。
btext = "\n".join(out_body)
for n in range(17, 29):
    # wire  _GEN_NN = ...;  (可能多行, 直到分号)
    btext = re.sub(r"\n\s*wire\s+_GEN_%d\s*=.*?;" % n, "", btext, flags=re.S)

core_name = "xs_RenameTableWrapper"
core = ["// 生成: scripts/gen_renametablewrapper.py —— 勿手改",
        "// RenameTableWrapper 可读装配核: 纯 wiring(0 寄存器), 派生 6 端口写控制分发给",
        "// 5 个 RenameTable 实例(assembly 黑盒)。忠实复刻 golden 连线, 去 SYNTHESIS 断言。",
        "module %s(" % core_name]
core += header[1:]          # 端口(去掉原 module 行)
core.append(btext)
core.append("endmodule")
open(OUT_CORE, "w").write("\n".join(core) + "\n")

# 包装层: golden 同名, 例化 u_core, 全端口直连
def gen_shell(modname, corename):
    o = ["module %s(" % modname]
    o += header[1:]
    o.append("")
    o.append("  %s u_core (" % corename)
    conns = []
    for p in ports:
        conns.append("    .%s (%s)" % (p, p))
    o.append(",\n".join(conns))
    o.append("  );")
    o.append("endmodule")
    return "\n".join(o) + "\n"

open(OUT_WRAP, "w").write(
    "// 生成: scripts/gen_renametablewrapper.py —— 勿手改\n"
    "// RenameTableWrapper 包装层(golden 同名) → xs_RenameTableWrapper 核。\n"
    + gen_shell("RenameTableWrapper", core_name))

import os
os.makedirs(os.path.dirname(OUT_XS), exist_ok=True)
open(OUT_XS, "w").write(
    "// 生成: scripts/gen_renametablewrapper.py —— 勿手改 (UT 变体, 名 _xs)\n"
    + gen_shell("RenameTableWrapper_xs", core_name))

print("ports:", len(ports))
print("wrote", OUT_CORE, OUT_WRAP, OUT_XS)
