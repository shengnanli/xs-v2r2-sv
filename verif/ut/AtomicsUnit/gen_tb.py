#!/usr/bin/env python3
# 生成 AtomicsUnit 的 UT testbench: golden AtomicsUnit vs 手写 AtomicsUnit_xs 双例化,
# 随机激励逐拍比对所有输出。两侧共用 golden DummyDPICWrapper_50 + DiffExtLrScEvent 定义
# (SYNTHESIS 下 DPI 块被裁, 空模块)。复位后跳过 warmup, 两侧寄存器同构可比。
# 端口表内联(从 golden/chisel-rtl/AtomicsUnit.sv 机械提取, clock/reset 特殊驱动)。
INPUTS = [('io_hartId', 6), ('io_in_valid', 1), ('io_in_bits_uop_fuOpType', 9), ('io_in_bits_uop_rfWen', 1), ('io_in_bits_uop_pdest', 8), ('io_in_bits_uop_robIdx_flag', 1), ('io_in_bits_uop_robIdx_value', 8), ('io_in_bits_uop_debugInfo_enqRsTime', 64), ('io_in_bits_uop_debugInfo_selectTime', 64), ('io_in_bits_uop_debugInfo_issueTime', 64), ('io_in_bits_uop_sqIdx_flag', 1), ('io_in_bits_uop_sqIdx_value', 6), ('io_in_bits_src_0', 64), ('io_storeDataIn_0_valid', 1), ('io_storeDataIn_0_bits_uop_fuOpType', 9), ('io_storeDataIn_0_bits_data', 64), ('io_storeDataIn_1_valid', 1), ('io_storeDataIn_1_bits_uop_fuOpType', 9), ('io_storeDataIn_1_bits_data', 64), ('io_dcache_req_ready', 1), ('io_dcache_resp_valid', 1), ('io_dcache_resp_bits_data', 128), ('io_dcache_resp_bits_miss', 1), ('io_dcache_resp_bits_replay', 1), ('io_dcache_resp_bits_error', 1), ('io_dcache_resp_bits_id', 6), ('io_dcache_block_lr', 1), ('io_dtlb_resp_valid', 1), ('io_dtlb_resp_bits_paddr_0', 48), ('io_dtlb_resp_bits_gpaddr_0', 64), ('io_dtlb_resp_bits_fullva', 64), ('io_dtlb_resp_bits_pbmt_0', 2), ('io_dtlb_resp_bits_miss', 1), ('io_dtlb_resp_bits_isForVSnonLeafPTE', 1), ('io_dtlb_resp_bits_excp_0_gpf_ld', 1), ('io_dtlb_resp_bits_excp_0_gpf_st', 1), ('io_dtlb_resp_bits_excp_0_pf_ld', 1), ('io_dtlb_resp_bits_excp_0_pf_st', 1), ('io_dtlb_resp_bits_excp_0_af_ld', 1), ('io_dtlb_resp_bits_excp_0_af_st', 1), ('io_pmpResp_ld', 1), ('io_pmpResp_st', 1), ('io_pmpResp_mmio', 1), ('io_flush_sbuffer_empty', 1), ('io_redirect_valid', 1), ('io_csrCtrl_cache_error_enable', 1), ('io_csrCtrl_mem_trigger_tUpdate_valid', 1), ('io_csrCtrl_mem_trigger_tUpdate_bits_addr', 2), ('io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType', 2), ('io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select', 1), ('io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action', 4), ('io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain', 1), ('io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store', 1), ('io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load', 1), ('io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2', 64), ('io_csrCtrl_mem_trigger_tEnableVec_0', 1), ('io_csrCtrl_mem_trigger_tEnableVec_1', 1), ('io_csrCtrl_mem_trigger_tEnableVec_2', 1), ('io_csrCtrl_mem_trigger_tEnableVec_3', 1), ('io_csrCtrl_mem_trigger_debugMode', 1), ('io_csrCtrl_mem_trigger_triggerCanRaiseBpExp', 1)]

OUTPUTS = [('io_in_ready', 1), ('io_out_valid', 1), ('io_out_bits_uop_exceptionVec_3', 1), ('io_out_bits_uop_exceptionVec_4', 1), ('io_out_bits_uop_exceptionVec_5', 1), ('io_out_bits_uop_exceptionVec_6', 1), ('io_out_bits_uop_exceptionVec_7', 1), ('io_out_bits_uop_exceptionVec_13', 1), ('io_out_bits_uop_exceptionVec_15', 1), ('io_out_bits_uop_exceptionVec_21', 1), ('io_out_bits_uop_exceptionVec_23', 1), ('io_out_bits_uop_trigger', 4), ('io_out_bits_uop_rfWen', 1), ('io_out_bits_uop_pdest', 8), ('io_out_bits_uop_robIdx_flag', 1), ('io_out_bits_uop_robIdx_value', 8), ('io_out_bits_uop_debugInfo_enqRsTime', 64), ('io_out_bits_uop_debugInfo_selectTime', 64), ('io_out_bits_uop_debugInfo_issueTime', 64), ('io_out_bits_data', 64), ('io_out_bits_debug_isMMIO', 1), ('io_dcache_req_valid', 1), ('io_dcache_req_bits_cmd', 5), ('io_dcache_req_bits_vaddr', 50), ('io_dcache_req_bits_addr', 48), ('io_dcache_req_bits_word_idx', 3), ('io_dcache_req_bits_amo_data', 128), ('io_dcache_req_bits_amo_mask', 16), ('io_dcache_req_bits_amo_cmp', 128), ('io_dtlb_req_valid', 1), ('io_dtlb_req_bits_vaddr', 50), ('io_dtlb_req_bits_fullva', 64), ('io_dtlb_req_bits_cmd', 3), ('io_dtlb_req_bits_debug_robIdx_flag', 1), ('io_dtlb_req_bits_debug_robIdx_value', 8), ('io_flush_sbuffer_valid', 1), ('io_feedbackSlow_valid', 1), ('io_feedbackSlow_bits_sqIdx_flag', 1), ('io_feedbackSlow_bits_sqIdx_value', 6), ('io_exceptionInfo_valid', 1), ('io_exceptionInfo_bits_vaddr', 64), ('io_exceptionInfo_bits_gpaddr', 64), ('io_exceptionInfo_bits_isForVSnonLeafPTE', 1)]


def decl(name, w):
    return f"logic [{w-1}:0] {name};" if w > 1 else f"logic {name};"


def wdecl(name, w):
    return f"wire [{w-1}:0] {name};" if w > 1 else f"wire {name};"


def port_map(names, prefix=""):
    return ",\n".join(f"    .{n}({prefix}{n})" for n in names)


def main():
    L = []
    L.append("// 自动生成: gen_tb.py —— 勿手改")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 200000;")
    L.append("  int unsigned WARMUP  = 8;")
    L.append("  bit clk = 0, rst;")
    L.append("  int errors = 0, checks = 0, cyc = 0;")
    L.append("  always #5 clk = ~clk;")
    L.append("")
    for n, w in INPUTS:
        L.append("  " + decl(n, w))
    for n, w in OUTPUTS:
        L.append("  " + wdecl("g_" + n, w))
        L.append("  " + wdecl("i_" + n, w))
    L.append("")

    L.append("  AtomicsUnit dut_g (")
    L.append("    .clock(clk), .reset(rst),")
    L.append(port_map([n for n, _ in INPUTS]) + ",")
    L.append(port_map([n for n, _ in OUTPUTS], prefix="g_"))
    L.append("  );")
    L.append("")
    L.append("  AtomicsUnit_xs dut_i (")
    L.append("    .clock(clk), .reset(rst),")
    L.append(port_map([n for n, _ in INPUTS]) + ",")
    L.append(port_map([n for n, _ in OUTPUTS], prefix="i_"))
    L.append("  );")
    L.append("")

    # 随机激励。fuOpType 偏置到合法原子编码集(LR/SC/AMO/AMOCAS), 让状态机深入推进;
    # storeDataIn 的 uopIdx(fuOpType[8:6])随机以覆盖 sels_* 分拣; 响应握手多数拉高。
    L.append("  // 合法原子 fuOpType 池(与 golden cmd 表覆盖一致): LR/SC W&D, AMO*, AMOCAS")
    L.append("  logic [8:0] fuop_pool [];")
    L.append("  task automatic drive_random();")
    for n, w in INPUTS:
        if w <= 32:
            L.append(f"    {n} = $random;")
        else:
            chunks = (w + 31) // 32
            parts = ",".join("$random" for _ in range(chunks))
            L.append(f"    {n} = {{{parts}}};")
    L.append("    // 偏置: 输入 fuOpType 取自合法池, 使 dcache cmd/AMO 路径被激活")
    L.append("    io_in_bits_uop_fuOpType = fuop_pool[$urandom_range(0, fuop_pool.size()-1)];")
    L.append("    // storeDataIn uopIdx 取 0..3 覆盖 rd_l/rs2_l/rd_h/rs2_h 分拣")
    L.append("    io_storeDataIn_0_bits_uop_fuOpType = {$random} & 9'h1C0 | ({$random} & 9'h3F);")
    L.append("    io_storeDataIn_1_bits_uop_fuOpType = {$random} & 9'h1C0 | ({$random} & 9'h3F);")
    L.append("    // 响应握手大多拉高以推进状态机")
    L.append("    if (($random & 3) != 0) io_dcache_req_ready   = 1'b1;")
    L.append("    if (($random & 3) != 0) io_dcache_resp_valid  = 1'b1;")
    L.append("    if (($random & 3) != 0) io_dtlb_resp_valid    = 1'b1;")
    L.append("    if (($random & 3) != 0) io_flush_sbuffer_empty= 1'b1;")
    L.append("    if (($random & 7) == 0) io_dcache_resp_bits_miss = 1'b1;")
    L.append("  endtask")
    L.append("")

    L.append("  task automatic check_outputs();")
    L.append("    checks++;")
    for n, _ in OUTPUTS:
        L.append(f"    if (g_{n} !== i_{n}) begin errors++; if (errors<=20) $display(\"[%0d] MISMATCH {n}: g=%h i=%h\", cyc, g_{n}, i_{n}); end")
    L.append("  endtask")
    L.append("")

    L.append("  initial begin")
    # build fuOpType pool: LR.W=2 LR.D=3 SC.W=6 SC.D=7; AMO* (E/F,12/13,16/17,1A/1B,1E/1F,22/23,26/27,2A/2B,2E/2F,A/B); AMOCAS 2C
    pool = [0x2,0x3,0x6,0x7,0xA,0xB,0xE,0xF,0x12,0x13,0x16,0x17,0x1A,0x1B,
            0x1E,0x1F,0x22,0x23,0x26,0x27,0x2A,0x2B,0x2C,0x2E,0x2F]
    L.append(f"    fuop_pool = new[{len(pool)}];")
    for i, v in enumerate(pool):
        L.append(f"    fuop_pool[{i}] = 9'h{v:X};")
    L.append("    rst = 1'b1;")
    for n, _ in INPUTS:
        L.append(f"    {n} = '0;")
    L.append("    repeat (6) @(posedge clk);")
    L.append("    @(negedge clk); rst = 1'b0;")
    L.append("    for (cyc = 0; cyc < NCYCLES; cyc++) begin")
    L.append("      @(negedge clk);")
    L.append("      drive_random();")
    L.append("      @(posedge clk);")
    L.append("      #1;")
    L.append("      if (cyc >= WARMUP) check_outputs();")
    L.append("    end")
    L.append("    if (errors == 0)")
    L.append("      $display(\"TEST PASSED: checks=%0d errors=0\", checks);")
    L.append("    else")
    L.append("      $display(\"TEST FAILED: checks=%0d errors=%0d\", checks, errors);")
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")

    with open("tb.sv", "w") as f:
        f.write("\n".join(L) + "\n")
    print("wrote tb.sv")


if __name__ == "__main__":
    main()
