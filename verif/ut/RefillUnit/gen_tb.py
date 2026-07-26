#!/usr/bin/env python3
# 生成 RefillUnit 的 UT testbench: golden RefillUnit vs 手写 RefillUnit_xs 双例化,
# 随机激励逐拍比对所有输出。两侧共用 golden FastArbiter_50 定义(单定义两实例, 无撞名)。
# 复位后跳过若干 warmup 拍(SYNTHESIS 下寄存器复位到 0, 两侧同构)。
import sys

# (name, width)  width=1 表示标量
INPUTS = [
    ("io_alloc_valid", 1),
    ("io_alloc_bits_state_w_snpRsp", 1),
    ("io_alloc_bits_task_set", 12),
    ("io_alloc_bits_task_bank", 2),
    ("io_alloc_bits_task_tag", 28),
    ("io_alloc_bits_task_off", 6),
    ("io_alloc_bits_task_size", 3),
    ("io_alloc_bits_task_bufID", 4),
    ("io_alloc_bits_task_reqID", 12),
    ("io_alloc_bits_task_replSnp", 1),
    ("io_alloc_bits_task_snpVec_0", 1),
    ("io_alloc_bits_task_tgtID", 11),
    ("io_alloc_bits_task_srcID", 11),
    ("io_alloc_bits_task_txnID", 12),
    ("io_alloc_bits_task_dbID", 12),
    ("io_alloc_bits_task_fwdNID", 11),
    ("io_alloc_bits_task_fwdTxnID", 12),
    ("io_alloc_bits_task_chiOpcode", 7),
    ("io_alloc_bits_task_resp", 3),
    ("io_alloc_bits_task_fwdState", 3),
    ("io_alloc_bits_task_pCrdType", 4),
    ("io_alloc_bits_task_retToSrc", 1),
    ("io_alloc_bits_task_doNotGoToSD", 1),
    ("io_alloc_bits_task_expCompAck", 1),
    ("io_alloc_bits_task_allowRetry", 1),
    ("io_alloc_bits_task_order", 2),
    ("io_alloc_bits_task_memAttr_allocate", 1),
    ("io_alloc_bits_task_memAttr_cacheable", 1),
    ("io_alloc_bits_task_memAttr_device", 1),
    ("io_alloc_bits_task_memAttr_ewa", 1),
    ("io_alloc_bits_task_snpAttr", 1),
    ("io_alloc_bits_dirResult_clients_hit", 1),
    ("io_alloc_bits_dirResult_clients_meta_0_valid", 1),
    ("io_alloc_bits_isWrite", 1),
    ("io_task_ready", 1),
    ("io_respData_valid", 1),
    ("io_respData_bits_txnID", 12),
    ("io_respData_bits_opcode", 7),
    ("io_respData_bits_resp", 3),
    ("io_respData_bits_srcID", 11),
    ("io_respData_bits_dataID", 2),
    ("io_respData_bits_data_data", 256),
    ("io_resp_valid", 1),
    ("io_resp_bits_txnID", 12),
    ("io_resp_bits_opcode", 7),
    ("io_resp_bits_srcID", 11),
    ("io_read_valid", 1),
    ("io_read_bits_id", 4),
]

OUTPUTS = [
    ("io_task_valid", 1),
    ("io_task_bits_set", 12),
    ("io_task_bits_bank", 2),
    ("io_task_bits_tag", 28),
    ("io_task_bits_off", 6),
    ("io_task_bits_size", 3),
    ("io_task_bits_refillTask", 1),
    ("io_task_bits_bufID", 4),
    ("io_task_bits_reqID", 12),
    ("io_task_bits_replSnp", 1),
    ("io_task_bits_snpVec_0", 1),
    ("io_task_bits_tgtID", 11),
    ("io_task_bits_srcID", 11),
    ("io_task_bits_txnID", 12),
    ("io_task_bits_dbID", 12),
    ("io_task_bits_fwdNID", 11),
    ("io_task_bits_fwdTxnID", 12),
    ("io_task_bits_chiOpcode", 7),
    ("io_task_bits_resp", 3),
    ("io_task_bits_fwdState", 3),
    ("io_task_bits_pCrdType", 4),
    ("io_task_bits_retToSrc", 1),
    ("io_task_bits_doNotGoToSD", 1),
    ("io_task_bits_expCompAck", 1),
    ("io_task_bits_allowRetry", 1),
    ("io_task_bits_order", 2),
    ("io_task_bits_memAttr_allocate", 1),
    ("io_task_bits_memAttr_cacheable", 1),
    ("io_task_bits_memAttr_device", 1),
    ("io_task_bits_memAttr_ewa", 1),
    ("io_task_bits_snpAttr", 1),
    ("io_data_data_0_data", 256),
    ("io_data_data_1_data", 256),
]
for i in range(16):
    OUTPUTS += [
        (f"io_refillInfo_{i}_valid", 1),
        (f"io_refillInfo_{i}_bits_set", 12),
        (f"io_refillInfo_{i}_bits_tag", 28),
        (f"io_refillInfo_{i}_bits_reqID", 12),
    ]


def decl(name, w):
    return f"logic [{w-1}:0] {name};" if w > 1 else f"logic {name};"


def wdecl(name, w):
    return f"wire [{w-1}:0] {name};" if w > 1 else f"wire {name};"


def port_map(names, prefix=""):
    return ",\n".join(f"    .{n}({prefix}{n})" for n in names)


def main():
    lines = []
    lines.append("// 自动生成: gen_tb.py —— 勿手改")
    lines.append("`timescale 1ns/1ps")
    lines.append("module tb;")
    lines.append("  int unsigned NCYCLES = 200000;")
    lines.append("  int unsigned WARMUP  = 8;")
    lines.append("  bit clk = 0, rst;")
    lines.append("  int errors = 0, checks = 0, cyc = 0;")
    lines.append("  always #5 clk = ~clk;")
    lines.append("")
    for n, w in INPUTS:
        lines.append("  " + decl(n, w))
    for n, w in OUTPUTS:
        lines.append("  " + wdecl("g_" + n, w))
        lines.append("  " + wdecl("i_" + n, w))
    lines.append("")

    # golden instance
    lines.append("  RefillUnit dut_g (")
    lines.append("    .clock(clk), .reset(rst),")
    lines.append(port_map([n for n, _ in INPUTS]) + ",")
    lines.append(port_map([n for n, _ in OUTPUTS], prefix="g_"))
    lines.append("  );")
    lines.append("")
    # impl instance
    lines.append("  RefillUnit_xs dut_i (")
    lines.append("    .clock(clk), .reset(rst),")
    lines.append(port_map([n for n, _ in INPUTS]) + ",")
    lines.append(port_map([n for n, _ in OUTPUTS], prefix="i_"))
    lines.append("  );")
    lines.append("")

    # stimulus
    lines.append("  // 随机激励: 对每个输入独立取随机值; 部分字段偏置以覆盖控制路径")
    lines.append("  task automatic drive_random();")
    for n, w in INPUTS:
        if w <= 32:
            lines.append(f"    {n} = $random;")
        else:
            chunks = (w + 31) // 32
            parts = ",".join("$random" for _ in range(chunks))
            lines.append(f"    {n} = {{{parts}}};")
    lines.append("    // 偏置: 使控制路径更常被触发")
    # alloc 常置以填满 buffer; txnID/reqID 收窄到小范围让 respData/resp 命中 buffer 里的条目
    lines.append("    if (($random & 1) == 0) io_alloc_valid = 1'b1;")
    lines.append("    io_alloc_bits_task_reqID = {8'h0, $random} & 12'hF;  // 收窄 reqID 到 0..15")
    lines.append("    io_respData_bits_txnID   = {8'h0, $random} & 12'hF;  // 命中 buffer reqID")
    lines.append("    io_resp_bits_txnID       = {8'h0, $random} & 12'hF;")
    lines.append("    // opcode 偏置到 SnpRespData/SnpResp(=0x1)")
    lines.append("    if (($random & 1) == 0) io_respData_bits_opcode = 7'h1;")
    lines.append("    if (($random & 1) == 0) io_resp_bits_opcode = 7'h1;")
    lines.append("    // resp 偏置到 I(=0)以触发 cancel; srcID 偏置到 0 以触发 snpVec 清位")
    lines.append("    if (($random & 3) == 0) io_respData_bits_resp = 3'h0;")
    lines.append("    if (($random & 1) == 0) io_respData_bits_srcID = 11'h0;")
    lines.append("    if (($random & 1) == 0) io_resp_bits_srcID = 11'h0;")
    lines.append("    // task_ready 多数为高以触发 issue fire; read 偶发触发 dealloc")
    lines.append("    if (($random & 3) != 0) io_task_ready = 1'b1;")
    lines.append("    if (($random & 7) != 0) io_read_valid = 1'b0;")
    lines.append("  endtask")
    lines.append("")

    # compare
    lines.append("  task automatic check_outputs();")
    lines.append("    checks++;")
    for n, _ in OUTPUTS:
        lines.append(f"    if (g_{n} !== i_{n}) begin errors++; if (errors<=20) $display(\"[%0d] MISMATCH {n}: g=%h i=%h\", cyc, g_{n}, i_{n}); end")
    lines.append("  endtask")
    lines.append("")

    lines.append("  initial begin")
    lines.append("    rst = 1'b1;")
    for n, _ in INPUTS:
        lines.append(f"    {n} = '0;")
    lines.append("    repeat (6) @(posedge clk);")
    lines.append("    @(negedge clk); rst = 1'b0;")
    lines.append("    for (cyc = 0; cyc < NCYCLES; cyc++) begin")
    lines.append("      @(negedge clk);")
    lines.append("      drive_random();")
    lines.append("      @(posedge clk);")
    lines.append("      #1;")
    lines.append("      if (cyc >= WARMUP) check_outputs();")
    lines.append("    end")
    lines.append("    if (errors == 0)")
    lines.append("      $display(\"TEST PASSED: checks=%0d errors=0\", checks);")
    lines.append("    else")
    lines.append("      $display(\"TEST FAILED: checks=%0d errors=%0d\", checks, errors);")
    lines.append("    $finish;")
    lines.append("  end")
    lines.append("endmodule")

    with open("tb.sv", "w") as f:
        f.write("\n".join(lines) + "\n")
    print("wrote tb.sv")


if __name__ == "__main__":
    main()
