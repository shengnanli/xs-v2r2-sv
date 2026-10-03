#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_sctable.py —— SCTable 家族（SCTable / _1 / _2 / _3）的 wrapper 机械派生区。

生成内容（全部从 G1 golden 端口表机械推出）：
  · rtl/frontend/SCTable.sv 里 `BEGIN GENERATED(sctable_wrapper)` 区：历史长度 0 那一档的 wrapper；
  · rtl/frontend/SCTable_1.sv / _2.sv / _3.sv：整份薄文件（只有 wrapper）。
wrapper 做三件事：golden 同名端口表 -> 打包/展平给 xs_SCTable_core（核在 SCTable.sv）；
例化本档的 MBIST 流水 MbistPipeSc_N（各档只差 MBIST 阵列编号，模块名不同所以放 wrapper）。

fail-closed：每个 golden 端口必须恰好被一条规则认领（未认领 / 重复认领即拒绝生成）；
折叠历史端口位宽必须等于 min(8, HIST_LEN)；golden 里例化的 MBIST 流水名必须与表里一致。

用法：
    python3 scripts/gen_sctable.py            # 生成（幂等：内容不变不写文件）
    python3 scripts/gen_sctable.py --check    # 产物与生成器不一致则 rc=1
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, ".."))
GOLDEN_DIR = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
PORT_RE = re.compile(r"^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$")

# (golden 模块名, HIST_LEN, MBIST 流水模块名)；HIST_LEN 对应 Parameters.scala SCHistLens = 0,4,10,16
VARIANTS = [
    ("SCTable",   0,  "MbistPipeSc"),
    ("SCTable_1", 4,  "MbistPipeSc_1"),
    ("SCTable_2", 10, "MbistPipeSc_2"),
    ("SCTable_3", 16, "MbistPipeSc_3"),
]

BCAST = ["ram_hold", "ram_bypass", "ram_bp_clken", "ram_aux_clk", "ram_aux_ckbp", "ram_mcp_hold", "cgen"]
MBIST_TO = [("addr", 8), ("addr_rd", 8), ("wdata", 24), ("wmask", 4), ("re", 1), ("we", 1),
            ("ack", 1), ("selectedOH", 1), ("array", 7)]


def die(msg):
    raise SystemExit("gen_sctable: " + msg)


def golden_text(mod):
    return open(os.path.join(GOLDEN_DIR, mod + ".sv")).read()


def golden_ports(mod):
    m = re.search(r"^module\s+%s\s*\((.*?)^\);" % re.escape(mod), golden_text(mod), re.S | re.M)
    if not m:
        die("golden 里找不到 module %s" % mod)
    out = []
    for ln in m.group(1).splitlines():
        if not ln.strip():
            continue
        pm = PORT_RE.match(ln)
        if not pm:
            die("%s 端口行解析不了：%r" % (mod, ln))
        out.append((pm.group(1), pm.group(3), int(pm.group(2)) + 1 if pm.group(2) else 1))
    return out


def claim_ports(mod, hist_len):
    """每个 golden 端口恰好被一条规则认领；返回 (端口表, 折叠历史端口名或 None, 有无 ghist)。"""
    ports = golden_ports(mod)
    rules = [
        ("clk", r"clock|reset"),
        ("req", r"io_req_valid|io_req_bits_pc"),
        ("fh", r"io_req_bits_folded_hist_hist_\d+_folded_hist"),
        ("resp", r"io_resp_ctrs_[01]_[01]"),
        ("upd", r"io_update_(pc|ghist|mask_[01]|oldCtrs_[01]|tagePreds_[01]|takens_[01])"),
        ("bd", r"boreChildrenBd_bore_(array|all|req|ack|writeen|be|addr|indata|readen|addr_rd|outdata)"),
        ("bcast", r"sigFromSrams_bore_(1_)?(%s)" % "|".join(BCAST)),
    ]
    fh = None
    ghist = False
    for d, n, w in ports:
        hits = [k for k, rx in rules if re.fullmatch(rx, n)]
        if len(hits) != 1:
            die("%s 端口 %s 被 %d 条规则认领" % (mod, n, len(hits)))
        if hits[0] == "fh":
            if fh:
                die("%s 有两个折叠历史端口" % mod)
            fh = (n, w)
        if n == "io_update_ghist":
            ghist = True
    want_fh = min(8, hist_len)
    if hist_len == 0:
        if fh or ghist:
            die("%s HIST_LEN=0 却有历史端口" % mod)
    else:
        if not fh or fh[1] != want_fh:
            die("%s 折叠历史端口 %r 位宽 != min(8,%d)" % (mod, fh, hist_len))
        if not ghist:
            die("%s HIST_LEN>0 却无 io_update_ghist" % mod)
    return ports, fh, ghist


def check_mbist_name(mod, pipe):
    insts = re.findall(r"^\s+(MbistPipeSc\w*)\s+mbistPl\s*\(", golden_text(mod), re.M)
    if insts != [pipe]:
        die("%s golden 例化的 MBIST 流水 %r != 表里 %s" % (mod, insts, pipe))


def rng(w):
    return "[%d:0] " % (w - 1) if w > 1 else ""


def wrapper(mod, hist_len, pipe):
    ports, fh, ghist = claim_ports(mod, hist_len)
    check_mbist_name(mod, pipe)
    L = []
    L.append("module %s" % mod)
    L.append("  import sctable_pkg::*;")
    L.append("(")
    pl = ["  %-6s %s%s" % (d, rng(w), n) for d, n, w in ports]
    L.append(",\n".join(pl))
    L.append(");")
    L.append("")
    L.append("  logic [CTR_W-1:0] resp_ctrs [NUM_BR][2];")
    L.append("  logic [CTR_W-1:0] update_old_ctrs [NUM_BR];")
    L.append("  sc_mbist_req_t    mbist_req   [NUM_BANK];")
    L.append("  logic [23:0]      mbist_rdata [NUM_BANK];")
    L.append("  sc_sram_bcast_t   sram_bcast  [NUM_BANK];")
    L.append("")
    L.append("  // SRAM 宏广播控制位：bank 0 = sigFromSrams_bore_*，bank 1 = sigFromSrams_bore_1_*")
    for b in range(2):
        pfx = "sigFromSrams_bore_" + ("1_" if b else "")
        L.append("  assign sram_bcast[%d] = '{" % b)
        L.append(",\n".join("    %s: %s%s" % (f, pfx, f) for f in BCAST))
        L.append("  };")
    L.append("  assign update_old_ctrs[0] = io_update_oldCtrs_0;")
    L.append("  assign update_old_ctrs[1] = io_update_oldCtrs_1;")
    L.append("")
    L.append("  xs_SCTable_core #(")
    L.append("    .HIST_LEN (%d)" % hist_len)
    L.append("  ) u_core (")
    conns = [
        ("clock", "clock"), ("reset", "reset"),
        ("req_valid", "io_req_valid"), ("req_pc", "io_req_bits_pc"),
        ("req_folded_hist", fh[0] if fh else "1'b0"),
        ("resp_ctrs", "resp_ctrs"),
        ("update_pc", "io_update_pc"),
        ("update_ghist", "io_update_ghist" if ghist else "256'h0"),
        ("update_mask", "{io_update_mask_1, io_update_mask_0}"),
        ("update_old_ctrs", "update_old_ctrs"),
        ("update_tage_preds", "{io_update_tagePreds_1, io_update_tagePreds_0}"),
        ("update_takens", "{io_update_takens_1, io_update_takens_0}"),
        ("mbist_req", "mbist_req"), ("mbist_rdata", "mbist_rdata"), ("sram_bcast", "sram_bcast"),
    ]
    L.append(",\n".join("    .%-17s (%s)" % c for c in conns))
    L.append("  );")
    L.append("")
    for i in range(2):
        for j in range(2):
            L.append("  assign io_resp_ctrs_%d_%d = resp_ctrs[%d][%d];" % (i, j, i, j))
    L.append("")
    L.append("  // MBIST 流水：把顶层 boreChildrenBd 测试口分发到两个 SRAM bank")
    L.append("  %s mbistPl (" % pipe)
    pc = [("clock", "clock"), ("reset", "reset"),
          ("mbist_array", "boreChildrenBd_bore_array"), ("mbist_all", "boreChildrenBd_bore_all"),
          ("mbist_req", "boreChildrenBd_bore_req"), ("mbist_ack", "boreChildrenBd_bore_ack"),
          ("mbist_writeen", "boreChildrenBd_bore_writeen"), ("mbist_be", "boreChildrenBd_bore_be"),
          ("mbist_addr", "boreChildrenBd_bore_addr"), ("mbist_indata", "boreChildrenBd_bore_indata"),
          ("mbist_readen", "boreChildrenBd_bore_readen"), ("mbist_addr_rd", "boreChildrenBd_bore_addr_rd"),
          ("mbist_outdata", "boreChildrenBd_bore_outdata")]
    for b in range(2):
        for f, _ in MBIST_TO:
            pc.append(("toSRAM_%d_%s" % (b, f), "mbist_req[%d].%s" % (b, f)))
        pc.append(("toSRAM_%d_rdata" % b, "mbist_rdata[%d]" % b))
    L.append(",\n".join("    .%-19s (%s)" % c for c in pc))
    L.append("  );")
    L.append("")
    L.append("endmodule")
    return "\n".join(L) + "\n"


BEGIN = "// BEGIN GENERATED(sctable_wrapper) —— scripts/gen_sctable.py 生成，勿手改\n"
END = "// END GENERATED(sctable_wrapper)\n"


def thin_file(mod, hist_len, pipe):
    fh_note = "折叠历史 min(8,%d)=%d 位" % (hist_len, min(8, hist_len))
    head = ("// =============================================================================\n"
            "// %s —— SC 计数器表，历史长度 %d 那一档（%s）\n"
            "//\n"
            "// 核体与机制说明见 SCTable.sv（package sctable_pkg + xs_SCTable_core）。\n"
            "// 本文件只有 golden 同名 wrapper：端口展平 + 本档 MBIST 流水 %s。\n"
            "// =============================================================================\n"
            % (mod, hist_len, fh_note, pipe))
    return head + BEGIN + wrapper(mod, hist_len, pipe) + END


def splice(text, body):
    if text.count(BEGIN) != 1 or text.count(END) != 1:
        die("SCTable.sv 里 GENERATED 标记不是恰好一对")
    a = text.index(BEGIN) + len(BEGIN)
    b = text.index(END)
    return text[:a] + body + text[b:]


def main():
    check = "--check" in sys.argv[1:]
    outs = {}
    base = os.path.join(REPO, "rtl/frontend/SCTable.sv")
    outs[base] = splice(open(base).read(), wrapper(*VARIANTS[0]))
    for v in VARIANTS[1:]:
        outs[os.path.join(REPO, "rtl/frontend/%s.sv" % v[0])] = thin_file(*v)
    rc = 0
    for p, txt in outs.items():
        old = open(p).read() if os.path.exists(p) else None
        if check:
            if old != txt:
                print("[gencheck] %s 与生成结果不一致" % os.path.relpath(p, REPO))
                rc = 1
            else:
                print("[gencheck] %s OK" % os.path.relpath(p, REPO))
        elif old != txt:
            open(p, "w").write(txt)
            print("wrote", os.path.relpath(p, REPO))
        else:
            print("unchanged", os.path.relpath(p, REPO))
    return rc


if __name__ == "__main__":
    sys.exit(main())
