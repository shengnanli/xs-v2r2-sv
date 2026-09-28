#!/usr/bin/env python3
"""gen_bankeddataarray.py —— 生成 rtl/memblock/BankedDataArray.sv 的两个 GENERATED 区。

  bda_ports：golden BankedDataArray 的端口表原样（模块头加 import bankeddataarray_pkg::*）；
  bda_insts：8 个 DataSRAMBank_* 与 MbistPipeDCacheData 的例化、MBIST 穿线（32 条 childBd）。
手写区（功能逻辑）不碰。

机械事实全部从 golden 现读并 fail-closed 核对：
  · 8 个 bank 的例化类型（data_banks_0_0..0_7 各是哪个 DataSRAMBank 变体）；
  · bank b 的第 j 组 bore / sigFromSrams 端口接的是第 4b+j 条 childBd / 顶层第 4b+j 组 sigFromSrams
    （逐条对 golden 的连接文本，不符即失败）；
  · MbistPipeDCacheData 的 toSRAM_n_rdata 接的是 bank n/4 的整行读输出（golden 里的 ecc_data_delayed_{32+n/4}）；
  · childBd_n_* 的位宽取 golden MbistPipeDCacheData 的 toSRAM_n_* 端口位宽。

用法：python3 scripts/gen_bankeddataarray.py [--check]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
OUT = os.path.join(REPO, "rtl", "memblock", "BankedDataArray.sv")
N_BANKS, N_WAYS = 8, 4
BD = ["addr", "addr_rd", "wdata", "wmask", "re", "we", "rdata", "ack", "selectedOH", "array"]
SIG = ["ram_hold", "ram_bypass", "ram_bp_clken", "ram_aux_clk", "ram_aux_ckbp", "ram_mcp_hold", "cgen"]
PORT = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')


def module_text(fname, mod):
    txt = open(os.path.join(G, fname)).read()
    i = txt.index(f"\nmodule {mod}(") + 1
    return txt[i:txt.index("\nendmodule", i)]


def port_widths(body):
    head = body[:body.index("\n);")]
    w = {}
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit(f"端口行解析失败: {ln!r}")
        w[m.group(4)] = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
    return w


def sfx(n):
    return "" if n == 0 else f"_{n}"


def gen():
    bda = module_text("BankedDataArray.sv", "BankedDataArray")
    ports = bda[:bda.index("\n);") + 3]
    ports = ports.replace("module BankedDataArray(", "module BankedDataArray\n  import bankeddataarray_pkg::*;\n(", 1)

    # ---- 核对 golden 的 bank 例化 ----
    insts = re.findall(r"^  (DataSRAMBank\w*) data_banks_0_(\d) \((.*?)\n  \);", bda, re.M | re.S)
    if [int(b) for _, b, _ in insts] != list(range(N_BANKS)):
        raise SystemExit(f"golden data_banks 例化不是 0_0..0_7: {[b for _, b, _ in insts]}")
    types = []
    for t, b, body in insts:
        b = int(b)
        types.append(t)
        conn = dict(re.findall(r"\.(\w+)\s*\(([^()]*)\)", body))
        for j in range(N_WAYS):
            n = b * N_WAYS + j
            if conn.get(f"boreChildrenBd_bore{sfx(j)}_addr") != f"childBd{sfx(n)}_addr":
                raise SystemExit(f"bank {b} bore {j} 不接 childBd_{n}: {conn.get(f'boreChildrenBd_bore{sfx(j)}_addr')}")
            if conn.get(f"sigFromSrams_bore{sfx(j)}_ram_hold") != f"sigFromSrams_bore{sfx(n)}_ram_hold":
                raise SystemExit(f"bank {b} sig {j} 不接顶层第 {n} 组")
    mb = module_text("BankedDataArray.sv", "BankedDataArray")
    mconn = dict(re.findall(r"\.(toSRAM_\d+_rdata)\s*\(([^()]*)\)", mb))
    for n in range(N_BANKS * N_WAYS):
        want = f"ecc_data_delayed_{32 + n // N_WAYS}"
        if mconn.get(f"toSRAM_{n}_rdata") != want:
            raise SystemExit(f"toSRAM_{n}_rdata 接的不是 {want}: {mconn.get(f'toSRAM_{n}_rdata')}")
    mw = port_widths(module_text("MbistPipeDCacheData.sv", "MbistPipeDCacheData"))

    L = ["  // ---- MBIST 穿线：MbistPipeDCacheData 的 32 个 toSRAM 口 ↔ 8 bank × 4 路 SRAM 的 bore 口 ----"]
    for n in range(N_BANKS * N_WAYS):
        for f in BD:
            w = mw[f"toSRAM_{n}_{f}"]
            rng = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  wire {rng}childBd_{n}_{f};")
    L.append("")
    L.append("  // MBIST 回读：toSRAM_n_rdata 借用 bank n/4 的整行读输出寄存器（§6）；ack / re 回到手写区")
    for n in range(N_BANKS * N_WAYS):
        L.append(f"  assign mbist_sram_ack[{n}] = childBd_{n}_ack;")
        L.append(f"  assign mbist_sram_re[{n}]  = childBd_{n}_re;")
    L.append("")
    c = [("clock", "clock"), ("reset", "reset"),
         ("mbist_array", "boreChildrenBd_bore_array"), ("mbist_all", "boreChildrenBd_bore_all"),
         ("mbist_req", "boreChildrenBd_bore_req"), ("mbist_ack", "mbist_ack"),
         ("mbist_writeen", "boreChildrenBd_bore_writeen"), ("mbist_be", "boreChildrenBd_bore_be"),
         ("mbist_addr", "boreChildrenBd_bore_addr"), ("mbist_indata", "boreChildrenBd_bore_indata"),
         ("mbist_readen", "boreChildrenBd_bore_readen"), ("mbist_addr_rd", "boreChildrenBd_bore_addr_rd"),
         ("mbist_outdata", "boreChildrenBd_bore_outdata")]
    for n in range(N_BANKS * N_WAYS):
        for f in BD:
            c.append((f"toSRAM_{n}_{f}", f"mbist_rdata[{n // N_WAYS}]" if f == "rdata" else f"childBd_{n}_{f}"))
    wid = max(len(a) for a, _ in c)
    L.append("  MbistPipeDCacheData mbistPl (")
    L.append(",\n".join(f"    .{a.ljust(wid)} ({b})" for a, b in c))
    L.append("  );")
    L.append("  assign boreChildrenBd_bore_ack = mbist_ack;")
    L.append("")
    for b, t in enumerate(types):
        c = [("clock", "clock"), ("reset", "reset"),
             ("io_w_en", f"bank_w_en[{b}]"), ("io_w_addr", f"bank_w_addr[{b}]"),
             ("io_w_way_en", f"bank_w_way_en[{b}]"), ("io_w_data", f"bank_w_data[{b}]"),
             ("io_r_en", f"bank_r_en[{b}]"), ("io_r_addr", f"bank_r_addr[{b}]")]
        c += [(f"io_r_data_{w}", f"bank_r_data[{b}][{w}]") for w in range(N_WAYS)]
        for j in range(N_WAYS):
            n = b * N_WAYS + j
            c += [(f"boreChildrenBd_bore{sfx(j)}_{f}", f"childBd_{n}_{f}") for f in BD]
        for j in range(N_WAYS):
            n = b * N_WAYS + j
            c += [(f"sigFromSrams_bore{sfx(j)}_{f}", f"sigFromSrams_bore{sfx(n)}_{f}") for f in SIG]
        wid = max(len(a) for a, _ in c)
        L.append(f"  // bank {b}")
        L.append(f"  {t} data_banks_0_{b} (")
        L.append(",\n".join(f"    .{a.ljust(wid)} ({x})" for a, x in c))
        L.append("  );")
    L.append("")
    L.append("endmodule")
    return ports, "\n".join(L)


def splice(txt, tag, body):
    b, e = f"// BEGIN GENERATED({tag})", "// END GENERATED"
    i = txt.index(b)
    j = txt.index(e, i)
    return txt[:i] + b + "\n// 由 scripts/gen_bankeddataarray.py 从 golden 生成 —— 勿手改\n" + body + "\n" + txt[j:]


def main():
    ports, insts = gen()
    old = open(OUT).read()
    for tag in ("bda_ports", "bda_insts"):
        if old.count(f"// BEGIN GENERATED({tag})") != 1:
            raise SystemExit(f"GENERATED({tag}) 标记不是恰好一个")
    new = splice(splice(old, "bda_ports", ports), "bda_insts", insts)
    if "--check" in sys.argv:
        if new != old:
            print(f"[gencheck] {OUT} 与生成结果不一致"); return 1
        print(f"[gencheck] {OUT} OK"); return 0
    if new != old:
        open(OUT, "w").write(new); print(f"wrote {OUT}")
    else:
        print(f"unchanged {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
