#!/usr/bin/env python3
"""gen_datasrambank.py —— 生成 DataSRAMBank 家族的 wrapper（DataSRAMBank / _1 / _2 / _4）。

家族结构（G1 golden 现读）：一个 DCache 数据 bank = 4 路 × 1 个单口 SRAMTemplate（256 组 × 72 位
{ecc[7:0], data[63:0]}）。4 个变体的逻辑完全相同，差别只有两处机械事实：
  · 每一路例化哪一个 SRAMTemplate_N（MBIST array id 位宽不同 → 宏包装的 bore_array 端口宽不同）；
  · 端口表里 4 组 boreChildrenBd_bore*_array 的位宽。
Verilog 不能把"例化哪个模块"做成参数，所以：
  · 可读核 xs_DataSRAMBank_core（写使能按路译码 + "写最多一路"检查）手写在 rtl/memblock/DataSRAMBank.sv，
    本脚本不碰；
  · 4 个 wrapper（端口表 + 例化核 + 例化 4 路 SRAMTemplate_N + 断言寄存器 REG）由本脚本从 golden
    端口表与 golden 的 SRAMTemplate 例化生成：DataSRAMBank.sv 里是 BEGIN/END GENERATED 区，
    _1/_2/_4 是整文件。
fail-closed：golden 里每个变体必须恰好 4 个 SRAMTemplate 例化、实例名 data_bank_0..3，否则失败。

用法：python3 scripts/gen_datasrambank.py [--check]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
VARIANTS = ["DataSRAMBank", "DataSRAMBank_1", "DataSRAMBank_2", "DataSRAMBank_4"]
N_WAYS = 4
BD = ["addr", "addr_rd", "wdata", "wmask", "re", "we", "rdata", "ack", "selectedOH", "array"]
SIG = ["ram_hold", "ram_bypass", "ram_bp_clken", "ram_aux_clk", "ram_aux_ckbp", "ram_mcp_hold", "cgen"]
BEGIN = "// BEGIN GENERATED(datasrambank_wrapper)"
END = "// END GENERATED"


def golden(v):
    txt = open(os.path.join(G, v + ".sv")).read()
    i = txt.index(f"\nmodule {v}(") + 1
    head = txt[i:txt.index("\n);", i) + 3]
    body = txt[i:]
    insts = re.findall(r"^  (SRAMTemplate_\d+) (data_bank_\d+) \(", body, re.M)
    if [n for _, n in insts] != [f"data_bank_{w}" for w in range(N_WAYS)]:
        raise SystemExit(f"{v}: SRAMTemplate 例化不是 data_bank_0..3: {insts}")
    return head, [t for t, _ in insts]


def wrapper(v):
    head, types = golden(v)
    L = [BEGIN, f"// 由 scripts/gen_datasrambank.py 从 golden {v}.sv 的端口表与 SRAMTemplate 例化生成 —— 勿手改。",
         f"// 每路 SRAMTemplate：{', '.join(f'路{w}={t}' for w, t in enumerate(types))}", head, "",
         "  logic [3:0] way_wen;           // 每路写使能 = w_en & way_en[w]",
         "  logic       write_one_hot_ok;  // 本拍写最多一路（仿真检查用）",
         "  xs_DataSRAMBank_core u_core (",
         "    .io_w_en          (io_w_en),",
         "    .io_w_way_en      (io_w_way_en),",
         "    .way_wen          (way_wen),",
         "    .write_one_hot_ok (write_one_hot_ok)",
         "  );", "",
         "  // assert(RegNext(!io.w.en || PopCount(io.w.way_en) <= 1.U)) 在 golden 里留下的寄存器（名同 golden）",
         "  logic REG;",
         "  always_ff @(posedge clock) REG <= write_one_hot_ok;",
         "`ifndef SYNTHESIS",
         "  always @(posedge clock)",
         "    if (!reset && !REG) $error(\"DataSRAMBank: write enables more than one way\");",
         "`endif", ""]
    for w, t in enumerate(types):
        sfx = "" if w == 0 else f"_{w}"
        c = [("clock", "clock"), ("reset", "reset"),
             ("io_r_req_valid", "io_r_en"), ("io_r_req_bits_setIdx", "io_r_addr"),
             ("io_r_resp_data_0", f"io_r_data_{w}"),
             ("io_w_req_valid", f"way_wen[{w}]"), ("io_w_req_bits_setIdx", "io_w_addr"),
             ("io_w_req_bits_data_0", "io_w_data")]
        c += [(f"io_broadcast_{s}", f"sigFromSrams_bore{sfx}_{s}") for s in SIG[:6]]
        c += [("io_broadcast_ram_ctl", "64'h0"), ("io_broadcast_cgen", f"sigFromSrams_bore{sfx}_cgen")]
        c += [(f"boreChildrenBd_bore_{b}", f"boreChildrenBd_bore{sfx}_{b}") for b in BD]
        wid = max(len(a) for a, _ in c)
        L.append(f"  // 第 {w} 路")
        L.append(f"  {t} data_bank_{w} (")
        L.append(",\n".join(f"    .{a.ljust(wid)} ({b})" for a, b in c))
        L.append("  );")
    L += ["", "endmodule", END]
    return "\n".join(L) + "\n"


THIN_HEAD = """// {v} —— DCache 数据阵列的一个 bank（DataSRAMBank 家族的变体）
//
// 与 DataSRAMBank 逻辑完全相同（见 rtl/memblock/DataSRAMBank.sv 文件头与可读核 xs_DataSRAMBank_core），
// 只有每一路例化的 SRAMTemplate 变体（MBIST array id 位宽不同）与 bore*_array 端口位宽不同。
// 本文件整体由 scripts/gen_datasrambank.py 生成。

"""


def outputs():
    out = {}
    base = os.path.join(REPO, "rtl", "memblock", "DataSRAMBank.sv")
    txt = open(base).read()
    if txt.count(BEGIN) != 1 or txt.count(END) != 1:
        raise SystemExit("DataSRAMBank.sv 里 GENERATED 标记不是恰好一对")
    pre = txt[:txt.index(BEGIN)]
    out[base] = pre + wrapper("DataSRAMBank")
    for v in VARIANTS[1:]:
        out[os.path.join(REPO, "rtl", "memblock", v + ".sv")] = THIN_HEAD.format(v=v) + wrapper(v)
    return out


def main():
    check = "--check" in sys.argv
    rc = 0
    for p, txt in outputs().items():
        old = open(p).read() if os.path.exists(p) else None
        if check:
            if old != txt:
                print(f"[gencheck] {p} 与生成结果不一致"); rc = 1
            else:
                print(f"[gencheck] {p} OK")
        elif old != txt:
            open(p, "w").write(txt); print(f"wrote {p}")
        else:
            print(f"unchanged {p}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
