#!/usr/bin/env python3
"""生成 FastArbiter_29 (72 路纯 grant round-robin 仲裁器) 的可读核。

FastArbiter_29 是 TL2CHICoupledL2 直接子: 72 路输入只有 valid/ready 握手, 无 payload
(纯 grant 仲裁, 归约到 io_out_valid = |valids)。golden 是 firtool 把 72 位 round-robin 展平
成 5800 行的 rrSelOH/chosenOH/gt_mask 位表达式; 可读核用 NUM=72 的通用 always_comb 循环
(与 FastArbiter_1/2/28 同一算法, 只是宽度大且无 payload) 忠实复刻, 逐位等价。

只生成可读核 rtl/uncore/FastArbiter_29.sv (module xs_FastArbiter_29_core);
wrapper/变体/tb/Makefile 由 gen_fastarbiter.py 的通用端口解析生成。
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RTL = ROOT / "rtl" / "uncore"
NUM = 72


def gen_core():
    L = []
    L.append("// =============================================================================")
    L.append("//  FastArbiter_29 —— 72 路纯 grant round-robin 仲裁器可读核 (xs_FastArbiter_29_core)")
    L.append("// -----------------------------------------------------------------------------")
    L.append("//  TL2CHICoupledL2 直接子: 72 路输入只有 valid/ready 握手, 无 payload。")
    L.append("//  ★本变体无 io_out_ready 端口 (sink 恒收), 与 4/5 路 FastArbiter 的关键差异★:")
    L.append("//    状态更新条件是 (|valids) 而非 (io_out_ready & |valids);")
    L.append("//    io_in_i_ready = chosenOH[i] (不再 & io_out_ready)。")
    L.append("//  算法 = utility.FastArbiter 带挂起记忆 round-robin (同 FastArbiter_1/2/28, NUM=72):")
    L.append("//    rrSelOH  = lowest_oh(rrGrantMask & pendingMask)")
    L.append("//    chosenOH = (rrSelOH 命中 valid) ? rrSelOH : lowest_oh(valids)")
    L.append("//    pendingMask <= valids & ~chosenOH; rrGrantMask <= gt_mask(chosenOH)  (|valids 时)")
    L.append("//  io_out_valid = |valids。golden 是 firtool 把 72 位 round-robin 展平成 5800 行位表达式,")
    L.append("//  本核用通用循环复刻, 与 golden FastArbiter_29 逐位等价。")
    L.append("// =============================================================================")
    L.append("module xs_FastArbiter_29_core (")
    L.append("  input  clock,")
    L.append("  input  reset,")
    for i in range(NUM):
        L.append(f"  output io_in_{i}_ready,")
        L.append(f"  input  io_in_{i}_valid,")
    L.append("  output io_out_valid")
    L.append(");")
    L.append("")
    L.append(f"  localparam int unsigned NUM = {NUM};")
    L.append("")
    L.append("  logic [NUM-1:0] valids;")
    L.append("  assign valids = {")
    for i in range(NUM - 1, -1, -1):
        comma = "," if i > 0 else ""
        L.append(f"    io_in_{i}_valid{comma}")
    L.append("  };")
    L.append("")
    L.append("  // ---- round-robin 状态 + 组合选胜 ----")
    L.append("  reg   [NUM-1:0] pendingMask;")
    L.append("  reg   [NUM-1:0] rrGrantMask;")
    L.append("  logic [NUM-1:0] chosenOH;")
    L.append("")
    L.append("  logic [NUM-1:0] cand;")
    L.append("  logic [NUM-1:0] rrSelOH;")
    L.append("  assign cand    = rrGrantMask & pendingMask;")
    L.append("  assign rrSelOH = cand & (~cand + {{(NUM-1){1'b0}}, 1'b1});   // x & -x = 隔离最低置位")
    L.append("  logic [NUM-1:0] baseOH;")
    L.append("  assign baseOH   = valids & (~valids + {{(NUM-1){1'b0}}, 1'b1});")
    L.append("  assign chosenOH = (|(rrSelOH & valids)) ? rrSelOH : baseOH;")
    L.append("")
    L.append("  // gt_mask(chosenOH): bit[i] = OR(chosenOH[i-1:0]); bit0 恒 0。")
    L.append("  logic [NUM-1:0] gtMask;")
    L.append("  always_comb begin")
    L.append("    gtMask = '0;")
    L.append("    for (int i = 0; i < NUM; i++)")
    L.append("      gtMask[i] = |(chosenOH & ((NUM'(1) << i) - NUM'(1)));")
    L.append("  end")
    L.append("")
    L.append("  always @(posedge clock or posedge reset) begin")
    L.append("    if (reset) begin")
    L.append("      pendingMask <= '0;")
    L.append("      rrGrantMask <= '0;")
    L.append("    end else if (|valids) begin")
    L.append("      pendingMask <= valids & ~chosenOH;")
    L.append("      rrGrantMask <= gtMask;")
    L.append("    end")
    L.append("  end")
    L.append("")
    L.append("  // ---- 握手: io_in_i_ready = chosenOH[i] (无 io_out_ready 门控) ----")
    for i in range(NUM):
        L.append(f"  assign io_in_{i}_ready = chosenOH[{i}];")
    L.append("")
    L.append("  assign io_out_valid = |valids;")
    L.append("")
    L.append("endmodule")
    L.append("")
    return "\n".join(L)


def main():
    (RTL / "FastArbiter_29.sv").write_text(gen_core())
    print("generated FastArbiter_29 core")


if __name__ == "__main__":
    main()
