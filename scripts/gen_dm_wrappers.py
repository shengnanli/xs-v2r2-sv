#!/usr/bin/env python3
"""
为 (Sync)DataModuleTemplate 系列生成：
  1) rtl/common/DataModule_variants.sv      内层变体包装（golden 同名，FM/ST 用）
  2) rtl/common/SyncDataModule_variants.sv  外层变体包装（golden 同名，FM/ST 用）
  3) verif/ut/SyncDataModule/variants_xs.sv 同内容但模块名加 _xs 后缀（UT 双例化用，
     避免与 golden 模块名冲突）
  4) verif/ut/SyncDataModule/tb.sv          全变体 golden vs _xs 随机比对 testbench

包装层把 golden 的展平端口（io_rdata_3_startAddr 等）按声明序拼接成参数化核心的
packed 数组端口；字段拼接顺序只需 wrapper 内部自洽（写入与读出同序），无需与
Chisel 内部打包一致。
"""
import re
import sys
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"

# 变体配置：BYPASS 全 1 除非列在 no_bypass
OUTER = ["SyncDataModuleTemplate_BackendPC_64entry", "SyncDataModuleTemplate_FtqPC_64entry",
         "SyncDataModuleTemplate__1024entry", "SyncDataModuleTemplate__1024entry_1",
         "SyncDataModuleTemplate__64entry", "SyncDataModuleTemplate__64entry_1",
         "SyncDataModuleTemplate__64entry_2", "SyncDataModuleTemplate__64entry_3",
         "SyncDataModuleTemplate__64entry_4"]
INNER = ["DataModule_BackendPC_16entry", "DataModule_FtqPC_16entry",
         "DataModule__64entry", "DataModule__64entry_16",
         "DataModule__16entry", "DataModule__16entry_4",
         "DataModule__16entry_8", "DataModule__16entry_12",
         "DataModule__16entry_16"]

def detect_bypass(inner_file, nr):
    """从内层 golden 代码探测每个读口是否有写旁路：
    存在 `io_wen_<w> & io_waddr_<w> == io_raddr_<r>` 比较器即该读口有旁路。"""
    text = inner_file.read_text()
    pairs = re.findall(r"io_wen_(\d+) & io_waddr_\1 == io_raddr_(\d+)", text)
    has = {int(r) for _, r in pairs}
    return [r in has for r in range(nr)]


def inner_of(outer_file):
    m = re.search(r"\b(DataModule_\w*?\d+entry(?:_\d+)?)\s+dataBanks_0", outer_file.read_text())
    assert m, f"no dataBanks_0 in {outer_file}"
    return m.group(1)


def parse_ports(svfile, modname):
    """返回 [(dir, width, name)]，width 为整数位宽。"""
    text = svfile.read_text()
    m = re.search(rf"^module {re.escape(modname)}\((.*?)\n\);", text, re.S | re.M)
    assert m, f"module {modname} not found in {svfile}"
    ports = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            d, w, n = pm.group(1), pm.group(2), pm.group(3)
            ports.append((d, int(w) + 1 if w else 1, n))
    return ports


def group(ports, prefix):
    """收集 io_<prefix>_<n>[_field...] 端口 -> {n: [(width,name,suffix)...]}（按声明序）
    suffix 为字段名（无字段后缀时为空串）。"""
    res = {}
    for d, w, n in ports:
        pm = re.match(rf"io_{prefix}_(\d+)(?:_(\w+))?$", n)
        if pm:
            res.setdefault(int(pm.group(1)), []).append((w, n, pm.group(2) or ""))
    return res


def canonical_fields(grp):
    """各口字段并集（按首次出现序）：[(suffix, width)]。firtool 会裁剪被上游
    绑常量/下游未用的字段端口，缺失字段写口补 0、读口跳过。"""
    fields = []
    for p in sorted(grp):
        for w, n, suf in grp[p]:
            if suf not in [f[0] for f in fields]:
                fields.append((suf, w))
    return fields


def concat_w(port_fields, canon):
    """写口拼接：规范布局首字段在 LSB（与 golden 按字段拆寄存器的位号对齐，
    利于 FM 名字/位置匹配），故 SV 拼接列表要反序（左侧为 MSB）。缺失字段补 0。"""
    have = {suf: n for _, n, suf in port_fields}
    parts = [have.get(suf, f"{w}'h0") for suf, w in reversed(canon)]
    return parts[0] if len(parts) == 1 else "{" + ", ".join(parts) + "}"


def gen_wrapper(name, ports, inner, suffix=""):
    entries = int(re.search(r"_(\d+)entry", name).group(1))
    rd, wr = group(ports, "raddr"), group(ports, "waddr")
    rdat, wdat = group(ports, "rdata"), group(ports, "wdata")
    wen, ren = group(ports, "wen"), group(ports, "ren")
    nr, nw = len(rd), len(wr)
    canon = canonical_fields(wdat)
    # 读口字段须是写口字段子集（裁剪只会减少）
    for p in rdat:
        for w, n, suf in rdat[p]:
            assert suf in [f[0] for f in canon], f"{name}: rdata field {suf} not in wdata"
    width = sum(w for _, w in canon)
    has_ren = len(ren) > 0
    byp_file = GOLDEN / f"{name}.sv" if inner else GOLDEN / f"{inner_of(GOLDEN / (name + '.sv'))}.sv"
    byp = detect_bypass(byp_file, nr)
    bypass = f"{nr}'b" + "".join("1" if b else "0" for b in reversed(byp))
    core = "xs_DataModule" if inner else "xs_SyncDataModule"

    decls = []
    for d, w, n in ports:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{n}")
    body = [f"module {name}{suffix}(", ",\n".join(decls) + "\n);"]

    # 规范布局中各字段的位区间（首字段 LSB）
    pos, lo = {}, 0
    for suf, w in canon:
        pos[suf] = (lo + w - 1, lo)
        lo += w
    body.append(f"  wire [{nr}-1:0][{width}-1:0] rdata_bus;")
    for p in range(nr):
        for w, n, suf in rdat[p]:
            h, l = pos[suf]
            sl = f"[{h}:{l}]" if (h, l) != (width - 1, 0) else ""
            body.append(f"  assign {n} = rdata_bus[{p}]{sl};")

    raddr_c = "{" + ", ".join(rd[p][0][1] for p in reversed(range(nr))) + "}"
    waddr_c = "{" + ", ".join(wr[p][0][1] for p in reversed(range(nw))) + "}"
    wen_c   = "{" + ", ".join(wen[p][0][1] for p in reversed(range(nw))) + "}"
    wdata_c = "{" + ", ".join(concat_w(wdat[p], canon) for p in reversed(range(nw))) + "}"

    params = [f".NUM_ENTRIES({entries})", f".NUM_READ({nr})", f".NUM_WRITE({nw})",
              f".DATA_WIDTH({width})", f".BYPASS_EN({bypass})"]
    conns = [".clock(clock)",
             f".io_raddr({raddr_c})", ".io_rdata(rdata_bus)",
             f".io_wen({wen_c})", f".io_waddr({waddr_c})", f".io_wdata({wdata_c})"]
    if not inner:
        has_reset = any(n == "reset" for _, _, n in ports)
        assert has_reset, f"{name}: outer variant without reset?"
        params.insert(4, f".HAS_REN({1 if has_ren else 0})")
        ren_c = ("{" + ", ".join(ren[p][0][1] for p in reversed(range(nr))) + "}"
                 if has_ren else f"{{{nr}{{1'b1}}}}")
        conns.insert(1, ".reset(reset)")
        conns.insert(2, f".io_ren({ren_c})")

    body.append(f"  {core} #(")
    body.append("    " + ",\n    ".join(params))
    body.append("  ) u_core (")
    body.append("    " + ",\n    ".join(conns))
    body.append("  );")
    body.append("endmodule\n")
    return "\n".join(body)


def gen_tb(variants):
    """variants: [(name, ports)]；golden 名 vs 名_xs 双例化随机比对"""
    L = []
    L.append("""// 自动生成：scripts/gen_dm_wrappers.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 50000;
  int unsigned WARMUP  = 3000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;
""")
    for name, ports in variants:
        pre = f"v{name}"
        ins = [(w, n) for d, w, n in ports if d == "input" and n not in ("clock", "reset")]
        outs = [(w, n) for d, w, n in ports if d == "output"]
        for w, n in ins:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  logic {ws}{pre}_{n};")
        for w, n in outs:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  wire {ws}{pre}_g_{n};")
            L.append(f"  wire {ws}{pre}_i_{n};")
        gconn = [".clock(clk)"] + ([".reset(rst)"] if any(n == "reset" for _, _, n in ports) else [])
        gconn += [f".{n}({pre}_{n})" for _, n in ins]
        iconn = list(gconn)
        gconn += [f".{n}({pre}_g_{n})" for _, n in outs]
        iconn += [f".{n}({pre}_i_{n})" for _, n in outs]
        L.append(f"  {name} u_g_{name} ({', '.join(gconn)});")
        L.append(f"  {name}_xs u_i_{name} ({', '.join(iconn)});")
        # 激励：en 类 75%，其余全随机
        L.append("  always @(negedge clk) begin")
        L.append("    if (rst) begin")
        for w, n in ins:
            if re.match(r"io_(wen|ren)_\d+$", n):
                L.append(f"      {pre}_{n} <= 1'b0;")
        L.append("    end else begin")
        for w, n in ins:
            if re.match(r"io_(wen|ren)_\d+$", n):
                L.append(f"      {pre}_{n} <= ($urandom_range(0, 3) != 0);")
            elif w <= 32:
                L.append(f"      {pre}_{n} <= {w}'($urandom);")
            else:
                rep = (w + 31) // 32
                rnd = "{" + ", ".join(["$urandom()"] * rep) + "}"
                L.append(f"      {pre}_{n} <= {w}'({rnd});")
        L.append("    end")
        L.append("  end")
        L.append("  always @(negedge clk) if (!rst && cycle > WARMUP) begin")
        L.append("    #4;")
        L.append("    checks++;")
        for w, n in outs:
            L.append(f"    if ({pre}_g_{n} !== {pre}_i_{n}) begin")
            L.append(f"      errors++; $display(\"[%0t] {name}.{n} mismatch: g=%h i=%h\", $time, {pre}_g_{n}, {pre}_i_{n});")
            L.append("    end")
        L.append("  end")
        L.append("")
    L.append("""  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 50000;
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb);
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(L)


def main():
    all_variants = []
    inner_txt, outer_txt, xs_txt = [], [], []
    hdr = "// 自动生成：scripts/gen_dm_wrappers.py —— 勿手改\n"
    for name in INNER:
        ports = parse_ports(GOLDEN / f"{name}.sv", name)
        inner_txt.append(gen_wrapper(name, ports, inner=True))
        xs_txt.append(gen_wrapper(name, ports, inner=True, suffix="_xs"))
        all_variants.append((name, ports))
    for name in OUTER:
        ports = parse_ports(GOLDEN / f"{name}.sv", name)
        outer_txt.append(gen_wrapper(name, ports, inner=False))
        xs_txt.append(gen_wrapper(name, ports, inner=False, suffix="_xs"))
        all_variants.append((name, ports))

    (XSSV / "rtl/common/DataModule_variants.sv").write_text(hdr + "\n".join(inner_txt))
    (XSSV / "rtl/common/SyncDataModule_variants.sv").write_text(hdr + "\n".join(outer_txt))
    ut = XSSV / "verif/ut/SyncDataModule"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + "\n".join(xs_txt))
    (ut / "tb.sv").write_text(gen_tb(all_variants))
    print(f"generated {len(INNER)} inner + {len(OUTER)} outer wrappers, tb with {len(all_variants)} pairs")


if __name__ == "__main__":
    main()
