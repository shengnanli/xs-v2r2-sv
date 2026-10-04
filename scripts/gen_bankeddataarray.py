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

另生成 verif/ut/BankedDataArray/fm_pins_pre.tcl（FM「匹配前」钉点，fail-closed、一一对应、字面计数）：
  · ecc_data_delayed：golden 平铺 ecc_data_delayed{_k}_reg[bit]（k = 4b+w，k=0 无后缀）
    <-> 重写 ecc_data_delayed_reg[b][w][bit]，32 × 72 = 2304 对；
  · ecc_data_delayed_REG：golden ecc_data_delayed_REG{_k}_reg <-> 重写 ecc_data_delayed_REG_reg[b][w]，32 对。
  实测（2026-09-28 非正式试跑）：不钉时 FM 按"末段名"把前者 1792 位留成两侧 unmatched、
  把后者按 Name(Last) 配成错位的对子，native FAILED。
  · 两侧对称的无读者寄存器（FM 不给无扇出的点做签名配对，钉上才能进 vmucp 真比较）：
      每个 SRAMTemplate 的 MBIST 回读寄存器 rdataReg[71:0]：golden data_banks_0_b/data_bank_w/rdataReg_reg[bit]
        <-> 重写 data_banks_0_b/data_bank_w/u_core/rdataReg_reg[bit]（32 × 72 = 2304 对；BankedDataArray 的
        MBIST 回读借用整行读寄存器，这条 bore_rdata 在两侧都悬空）；
      它的采样使能 golden respReg <-> 重写 u_core/g_nomcp.respReg（32 对；codex 0206 D1 起共享核在
        holdRead 关时不再生成与它同方程的 rdata_last_REG，不再有 merge 幸存名的问题）；
      MbistPipeDCacheData 的 addrReg[8:0] / addrRdReg[8] / beReg（11 对，同 DuplicatedTagArray 的那批死位）。
  只消命名鸿沟，不约束 ref。

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


PINS = os.path.join(REPO, "verif", "ut", "BankedDataArray", "fm_pins_pre.tcl")


def pins():
    top = "BankedDataArray"
    L = ["# BankedDataArray FM「匹配前」钉点 —— 由 scripts/gen_bankeddataarray.py 生成，勿手改。",
         "# 只消命名鸿沟（golden 平铺 _k 后缀 vs 重写 [b][w] 二维数组）：不约束 ref、不放宽 appvar、",
         "# 不扩黑盒、不 dont_verify。依据见生成器文件头。",
         f'if {{$top ne "{top}"}} {{ error "BDA_PREPIN_WRONG_TOP=$top" }}',
         "set _bda_n 0",
         "for {set _b 0} {$_b < 8} {incr _b} {",
         "    for {set _w 0} {$_w < 4} {incr _w} {",
         "        set _k [expr {$_b * 4 + $_w}]",
         '        if {$_k == 0} { set _sfx "" } else { set _sfx "_$_k" }',
         '        set _r "r:/WORK/' + top + '/ecc_data_delayed_REG${_sfx}_reg"',
         '        set _i "i:/WORK/' + top + '/ecc_data_delayed_REG_reg\\[$_b\\]\\[$_w\\]"',
         '        if {![set_user_match $_r $_i]} { puts "BDA_PREPIN_FAIL: $_r <-> $_i"; error "BDA_PREPIN_MISS=$_r" }',
         "        incr _bda_n",
         "        for {set _bit 0} {$_bit < 72} {incr _bit} {",
         '            set _r "r:/WORK/' + top + '/ecc_data_delayed${_sfx}_reg\\[$_bit\\]"',
         '            set _i "i:/WORK/' + top + '/ecc_data_delayed_reg\\[$_b\\]\\[$_w\\]\\[$_bit\\]"',
         '            if {![set_user_match $_r $_i]} { puts "BDA_PREPIN_FAIL: $_r <-> $_i"; error "BDA_PREPIN_MISS=$_r" }',
         "            incr _bda_n",
         "        }",
         "    }",
         "}",
         "for {set _b 0} {$_b < 8} {incr _b} {",
         "    for {set _w 0} {$_w < 4} {incr _w} {",
         '        set _p "data_banks_0_$_b/data_bank_$_w"',
         '        set _r "r:/WORK/' + top + '/$_p/respReg_reg"',
         '        set _i "i:/WORK/' + top + '/$_p/u_core/g_nomcp.respReg_reg"',
         '        if {![set_user_match $_r $_i]} { puts "BDA_PREPIN_FAIL: $_r <-> $_i"; error "BDA_PREPIN_MISS=$_r" }',
         "        incr _bda_n",
         "        for {set _bit 0} {$_bit < 72} {incr _bit} {",
         '            set _r "r:/WORK/' + top + '/$_p/rdataReg_reg\\[$_bit\\]"',
         '            set _i "i:/WORK/' + top + '/$_p/u_core/rdataReg_reg\\[$_bit\\]"',
         '            if {![set_user_match $_r $_i]} { puts "BDA_PREPIN_FAIL: $_r <-> $_i"; error "BDA_PREPIN_MISS=$_r" }',
         "            incr _bda_n",
         "        }",
         "    }",
         "}",
    ] + [
        f'if {{![set_user_match "r:/WORK/{top}/mbistPl/{rn}" "i:/WORK/{top}/mbistPl/u_core/{im}"]}} '
        f'{{ error "BDA_PREPIN_MISS=mbistPl/{rn}" }} ; incr _bda_n'
        for rn, im in ([(f"addrReg_reg\\[{k}\\]", f"addrReg_reg\\[{k}\\]") for k in range(9)] +
                       [("addrRdReg_reg\\[8\\]", "addrRdReg_reg\\[8\\]"), ("beReg_reg", "beReg_reg\\[0\\]")])
    ] + [
         'puts "BDA_PREPIN_END n=$_bda_n expect=4683"',
         'if {$_bda_n != 4683} { error "BDA_PREPIN_COUNT=$_bda_n" }']
    return "\n".join(L) + "\n"


def main():
    ports, insts = gen()
    old = open(OUT).read()
    for tag in ("bda_ports", "bda_insts"):
        if old.count(f"// BEGIN GENERATED({tag})") != 1:
            raise SystemExit(f"GENERATED({tag}) 标记不是恰好一个")
    new = splice(splice(old, "bda_ports", ports), "bda_insts", insts)
    rc = 0
    for path, txt in ((OUT, new), (PINS, pins())):
        cur = open(path).read() if os.path.exists(path) else None
        if "--check" in sys.argv:
            if cur != txt:
                print(f"[gencheck] {path} 与生成结果不一致"); rc = 1
            else:
                print(f"[gencheck] {path} OK")
        elif cur != txt:
            open(path, "w").write(txt); print(f"wrote {path}")
        else:
            print(f"unchanged {path}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
