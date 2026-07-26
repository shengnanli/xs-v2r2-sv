#!/usr/bin/env python3
# =====================================================================
# gen_slice_variants.py —— 从已签核绿基线 Slice(sliceId=0)机械派生
# TL2 direct-child shard 2 变体 Slice_1/Slice_2/Slice_3。
#
# 变体与基线仅差(golden 逐行 diff 实测,name-normalize 后仅 8/14/14 行):
#   · io_sliceId              2'h0 -> 2'hN
#   · 子模块实例类型          Directory/DataStorage/L2Slice -> _N 后缀
#   · MBIST array-id 位宽      childBd[_1]_array / bd_array / boreChildrenBd_bore_array
#                             base:4/5/5/5 位  N=1:5/5/4/5  N=2,3:6/6/6/6
#     (base childBd_array[3:0] childBd_1_array[4:0] bd_array[4:0] port[4:0])
#     (每 Slice_N 精确取自 golden Slice_N.sv 对应 wire/port 声明)
#
# 复用已签核绿核 xs_Slice_core 的全部结构(端口/glue/inst/outassign 布线),
# 仅按 golden 变体 delta 收窄/加宽 array 网 + 换绿子模块名 + 设 sliceId。
# 每 Slice_N 为 assembly 父:黑盒其独立已证绿子(Directory_N/L2Slice_N=green-AUX,
# 13 绿 305 子 + 厂商 array_18_ext)+ 两侧 elaborate 非 305 逻辑子
# (DataStorage_N/RequestBuffer/RXSNP/MSHRBuffer[_1] 同基线 codex_0036 裁定)。
# =====================================================================
import re, json
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
L2 = XSSV / "rtl/l2"
VARDIR = L2 / "slice_variants"
VARDIR.mkdir(exist_ok=True)

# 每变体精确 delta(取自 golden Slice_N.sv 实测)。
# array 网位宽以 [msb:0] 形式;child 实例类型后缀 N。
VARIANTS = {
    1: dict(sid="2'h1",
            port_array="[4:0]",      # input boreChildrenBd_bore_array
            bd_array_w="[4:0]",      # wire bd_array
            childBd_array_w="[4:0]", # Directory 侧 (base [3:0])
            childBd_1_array_w="[4:0]"),  # DataStorage 侧 (base [4:0])
    2: dict(sid="2'h2",
            port_array="[5:0]",
            bd_array_w="[5:0]",
            childBd_array_w="[5:0]",
            childBd_1_array_w="[5:0]"),
    3: dict(sid="2'h3",
            port_array="[5:0]",
            bd_array_w="[5:0]",
            childBd_array_w="[5:0]",
            childBd_1_array_w="[5:0]"),
}

def read(p): return (L2 / p).read_text()

BASE_PORTS   = read("slice_ports.svh")
BASE_DECLS   = read("slice_decls.svh")
BASE_GLUE    = read("slice_glue.svh")
BASE_INST    = read("slice_inst.svh")
BASE_OUTASSN = read("slice_outassign.svh")
BASE_WRAP    = read("Slice_wrapper.sv")
BASE_CORE    = read("Slice.sv")

def gen_ports(v):
    t = BASE_PORTS
    # input [4:0] boreChildrenBd_bore_array,
    t = re.sub(r'input \[4:0\] boreChildrenBd_bore_array,',
               f'input {v["port_array"]} boreChildrenBd_bore_array,', t)
    return t

def gen_decls(v):
    t = BASE_DECLS
    # logic [3:0] childBd_array;  -> variant width
    t = re.sub(r'logic \[3:0\] childBd_array;',
               f'logic {v["childBd_array_w"]} childBd_array;', t)
    # logic [4:0] childBd_1_array;
    t = re.sub(r'logic \[4:0\] childBd_1_array;',
               f'logic {v["childBd_1_array_w"]} childBd_1_array;', t)
    return t

def gen_glue(v):
    t = BASE_GLUE
    # wire [4:0]   bd_array = boreChildrenBd_bore_array;
    t = re.sub(r'wire \[4:0\]   bd_array = boreChildrenBd_bore_array;',
               f'wire {v["bd_array_w"]}   bd_array = boreChildrenBd_bore_array;', t)
    return t

def gen_inst(n):
    t = BASE_INST
    # .io_sliceId (2'h0)  -> 2'hN
    t = t.replace(".io_sliceId (2'h0)", f".io_sliceId (2'h{n})")
    # child instance types (anchor to instance-decl lines, unique)
    t = t.replace("  Directory directory (", f"  Directory_{n} directory (")
    t = t.replace("  DataStorage dataStorage (", f"  DataStorage_{n} dataStorage (")
    t = t.replace("  L2Slice mbistPl (", f"  L2Slice_{n} mbistPl (")
    return t

def gen_core(n):
    t = BASE_CORE
    t = t.replace("module xs_Slice_core (", f"module xs_Slice_{n}_core (")
    # re-point includes to variant svh copies (in this dir)
    t = t.replace('`include "slice_ports.svh"',    f'`include "slice_{n}_ports.svh"')
    t = t.replace('`include "slice_decls.svh"',    f'`include "slice_{n}_decls.svh"')
    t = t.replace('`include "slice_glue.svh"',     f'`include "slice_{n}_glue.svh"')
    t = t.replace('`include "slice_inst.svh"',     f'`include "slice_{n}_inst.svh"')
    t = t.replace('`include "slice_outassign.svh"',f'`include "slice_{n}_outassign.svh"')
    hdr = (f"// 变体核 xs_Slice_{n}_core —— 由 scripts/gen_slice_variants.py 从绿基线\n"
           f"// xs_Slice_core 机械派生(sliceId={n}, 子模块 Directory_{n}/DataStorage_{n}/\n"
           f"// L2Slice_{n}, MBIST array-id 位宽按 golden Slice_{n} 收窄/加宽)。勿手改。\n")
    return hdr + t

def gen_wrapper(n, v):
    t = BASE_WRAP
    # module Slice( -> module Slice_N(
    t = t.replace("module Slice(", f"module Slice_{n}(")
    # port width
    t = re.sub(r'input  \[4:0\] boreChildrenBd_bore_array,',
               f'input  {v["port_array"]} boreChildrenBd_bore_array,', t)
    # core instance
    t = t.replace("xs_Slice_core u_core (", f"xs_Slice_{n}_core u_core (")
    return t

def gen_allow(n):
    """assembly allow.json:8×vendor array_18_ext + 13 green 305 子(directory->Directory_N
    通过实例名, mbistPl->L2Slice_N)。paths 用实例名(不含类型), 故与 base 完全相同,
    仅顶层名 Slice -> Slice_N。"""
    base = json.loads((XSSV / "verif/signoff/allow/Slice.json").read_text())
    def swap(p): return p.replace("/WORK/Slice/", f"/WORK/Slice_{n}/")
    out = {"unresolved_blackbox": [], "interface_only": [], "empty_blackbox": [], "unmatched": []}
    for e in base["unresolved_blackbox"]:
        out["unresolved_blackbox"].append({
            "id": e["id"],
            "ref_path": swap(e["ref_path"]),
            "impl_path": swap(e["impl_path"]),
        })
    return out

for n, v in VARIANTS.items():
    (VARDIR / f"slice_{n}_ports.svh").write_text(gen_ports(v))
    (VARDIR / f"slice_{n}_decls.svh").write_text(gen_decls(v))
    (VARDIR / f"slice_{n}_glue.svh").write_text(gen_glue(v))
    (VARDIR / f"slice_{n}_inst.svh").write_text(gen_inst(n))
    (VARDIR / f"slice_{n}_outassign.svh").write_text(BASE_OUTASSN)  # identical
    (VARDIR / f"Slice_{n}_core.sv").write_text(gen_core(n))
    (VARDIR / f"Slice_{n}_wrapper.sv").write_text(gen_wrapper(n, v))
    (XSSV / f"verif/signoff/allow/Slice_{n}.json").write_text(
        json.dumps(gen_allow(n), indent=4) + "\n")
    print(f"generated Slice_{n}: core+wrapper+5 svh + allow/Slice_{n}.json")

print("done")

# =====================================================================
# UT 双例化派生(golden Slice_N vs impl Slice_N_xs, seed 1/7/42 errors=0)。
# 从基线 verif/ut/Slice/{tb.sv,variants_xs.sv,golden_filelist.f} 机械派生:
#   · tb.sv:      Slice->Slice_N(golden inst)/Slice_xs->Slice_N_xs(impl inst)
#                 + boreChildrenBd_bore_array 位宽按变体加宽
#   · Slice_N_xs: 基线 Slice_xs(=core wrapper)换名 + 换绿子模块名 + sliceId + 位宽
#   · golden_filelist.f: Slice_N 全递归叶子闭包(80 模块)
# =====================================================================
import subprocess, os

GOLDEN_ABS = Path("/home/eda/xs-env/G0-canonical/golden-rtl")
UTBASE = XSSV / "verif/ut/Slice"

def golden_closure(top):
    seen=set(); stack=[top]; out=[]
    while stack:
        m=stack.pop()
        if m in seen: continue
        seen.add(m)
        f=GOLDEN_ABS/f"{m}.sv"
        fv=GOLDEN_ABS/f"{m}.v"
        use=None
        if f.exists(): use=f
        elif fv.exists(): use=fv
        if use is None: continue
        out.append(use.name)
        txt=use.read_text()
        for c in sorted(set(re.findall(r'^  ([A-Za-z]\w+)(?= \w+ \()', txt, re.M))):
            if c not in seen: stack.append(c)
    return sorted(out)

BASE_TB   = (UTBASE/"tb.sv").read_text()
BASE_VXS  = (UTBASE/"variants_xs.sv").read_text()

for n, v in VARIANTS.items():
    UT = XSSV / f"verif/ut/Slice_{n}"
    UT.mkdir(exist_ok=True)
    aw = v["port_array"]  # e.g. [4:0] / [5:0]

    # --- Slice_N_xs (impl-side wrapper, distinct name from golden Slice_N) ---
    vxs = BASE_VXS
    vxs = vxs.replace("module Slice_xs(", f"module Slice_{n}_xs(")
    vxs = re.sub(r'input  \[4:0\] boreChildrenBd_bore_array,',
                 f'input  {aw} boreChildrenBd_bore_array,', vxs)
    vxs = vxs.replace("xs_Slice_core u_core (", f"xs_Slice_{n}_core u_core (")
    (UT/"variants_xs.sv").write_text(vxs)

    # --- tb.sv (golden Slice_N vs impl Slice_N_xs) ---
    tb = BASE_TB
    # impl instance FIRST (order matters: rename Slice_xs before bare Slice):
    #   "Slice_xs <ws> u_<inst> (" -> "Slice_N_xs <ws> u_<inst> ("
    tb = re.sub(r'\bSlice_xs(\s+u_\w+ ?\()', rf'Slice_{n}_xs\1', tb)
    # golden instance: bare "Slice <ws> u_<inst> (" -> "Slice_N <ws> u_<inst> ("
    tb = re.sub(r'\bSlice(\s+u_\w+ ?\()', rf'Slice_{n}\1', tb)
    # bore_array reg width in tb
    tb = re.sub(r'logic \[4:0\] boreChildrenBd_bore_array;',
                f'logic {aw} boreChildrenBd_bore_array;', tb)
    (UT/"tb.sv").write_text(tb)

    # --- golden_filelist.f (variant full closure) ---
    files = golden_closure(f"Slice_{n}")
    fl = "\n".join(f"../../../golden/chisel-rtl/{f}" for f in files) + "\n"
    (UT/"golden_filelist.f").write_text(fl)
    print(f"UT Slice_{n}: variants_xs + tb + golden_filelist({len(files)} files)")

print("UT gen done")
