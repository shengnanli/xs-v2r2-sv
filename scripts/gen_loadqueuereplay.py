#!/usr/bin/env python3
# =============================================================================
#  gen_loadqueuereplay.py —— 由 golden LoadQueueReplay.sv 的端口表生成：
#    1) rtl/memblock/LoadQueueReplay_wrapper.sv —— golden 同名扁平端口 → 例化可读核
#       + 黑盒子模块（FM/ST 用）
#    2) verif/ut/LoadQueueReplay/variants_xs.sv —— _xs 镜像（UT 用，模块名 LoadQueueReplay_xs）
#    3) verif/ut/LoadQueueReplay/tb.sv          —— golden u_g vs _xs u_i 双例化逐拍比对
#
#  端口与 golden 完全一致；wrapper/_xs 内部把扁平 io_* 机械打包成核的 struct/数组端口。
#  核（xs_LoadQueueReplay_core）实现全部调度逻辑；3 个黑盒子模块 AgeDetector_38 /
#  FreeList_5 / LqVAddrModule 由核内 subinst.svh 例化（UT/FM 两侧共用 golden 定义）。
# =============================================================================
import re, os

ROOT   = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
GOLDEN = os.path.join(ROOT, "golden", "chisel-rtl", "LoadQueueReplay.sv")
LDW    = 3   # LoadPipelineWidth
VECW   = 2   # VecLoadPipelineWidth
STW    = 2   # StorePipelineWidth
SQSZ   = 56  # StoreQueueSize

def parse_ports(path):
    txt = open(path).read()
    m = re.search(r"module LoadQueueReplay\((.*?)\n\);", txt, re.S)
    body = m.group(1)
    ports = []  # (dir, width, name)
    for ln in body.splitlines():
        ln = ln.strip().rstrip(",")
        mm = re.match(r"(input|output)\s+(\[[0-9]+:[0-9]+\]\s+)?(\w+)", ln)
        if not mm: continue
        ports.append((mm.group(1), (mm.group(2) or "").strip(), mm.group(3)))
    return ports

PORTS = parse_ports(GOLDEN)

def decl(d, w, n):
    return f"  {d} {w+' ' if w else ''}{n}"

# ---- helpers to build packed concat (port w high .. 0 low) ----
def cat(fn, n):
    # {fn(n-1), ..., fn(0)}  (MSB = highest index)
    return "{" + ", ".join(fn(i) for i in range(n-1, -1, -1)) + "}"

# ---- 核端口连接（把扁平 io_* 打包成核的 struct/数组端口）---------------------
def core_inst():
    L = []
    L.append("  xs_LoadQueueReplay_core u_core (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .redirect_valid(io_redirect_valid),")
    L.append("    .redirect_robIdx('{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value}),")
    L.append("    .redirect_level(io_redirect_bits_level),")
    # vecFeedback
    L.append(f"    .vecFb_valid({cat(lambda j:f'io_vecFeedback_{j}_valid', VECW)}),")
    L.append(f"    .vecFb_robIdx({cat(lambda j:f'vfb{j}_rob', VECW)}),")
    L.append(f"    .vecFb_uopIdx({cat(lambda j:f'io_vecFeedback_{j}_bits_uopidx', VECW)}),")
    L.append(f"    .vecFb_isCommit({cat(lambda j:f'io_vecFeedback_{j}_bits_feedback_0', VECW)}),")
    L.append(f"    .vecFb_isFlush({cat(lambda j:f'io_vecFeedback_{j}_bits_feedback_1', VECW)}),")
    # enq buses
    L.append(f"    .enq_valid({cat(lambda w:f'io_enq_{w}_valid', LDW)}),")
    L.append(f"    .enq_uop({cat(lambda w:f'enq{w}_uop', LDW)}),")
    L.append(f"    .enq_vec({cat(lambda w:f'enq{w}_vec', LDW)}),")
    L.append(f"    .enq_vaddr({cat(lambda w:f'io_enq_{w}_bits_vaddr', LDW)}),")
    L.append(f"    .enq_tlbMiss({cat(lambda w:f'io_enq_{w}_bits_tlbMiss', LDW)}),")
    L.append(f"    .enq_isLoadReplay({cat(lambda w:f'io_enq_{w}_bits_isLoadReplay', LDW)}),")
    L.append(f"    .enq_handledByMSHR({cat(lambda w:f'io_enq_{w}_bits_handledByMSHR', LDW)}),")
    L.append(f"    .enq_schedIndex({cat(lambda w:f'io_enq_{w}_bits_schedIndex', LDW)}),")
    L.append(f"    .enq_cause({cat(lambda w:f'enq{w}_cause', LDW)}),")
    L.append(f"    .enq_mshr_id({cat(lambda w:f'io_enq_{w}_bits_rep_info_mshr_id', LDW)}),")
    L.append(f"    .enq_full_fwd({cat(lambda w:f'io_enq_{w}_bits_rep_info_full_fwd', LDW)}),")
    L.append(f"    .enq_data_inv_sq_idx({cat(lambda w:f'enq{w}_data_inv', LDW)}),")
    L.append(f"    .enq_addr_inv_sq_idx({cat(lambda w:f'enq{w}_addr_inv', LDW)}),")
    L.append(f"    .enq_last_beat({cat(lambda w:f'io_enq_{w}_bits_rep_info_last_beat', LDW)}),")
    L.append(f"    .enq_tlb_id({cat(lambda w:f'io_enq_{w}_bits_rep_info_tlb_id', LDW)}),")
    L.append(f"    .enq_tlb_full({cat(lambda w:f'io_enq_{w}_bits_rep_info_tlb_full', LDW)}),")
    # store addr/data in
    L.append(f"    .staIn_valid({cat(lambda w:f'io_storeAddrIn_{w}_valid', STW)}),")
    L.append(f"    .staIn_sqIdx({cat(lambda w:f'sta{w}_sq', STW)}),")
    L.append(f"    .staIn_miss({cat(lambda w:f'io_storeAddrIn_{w}_bits_miss', STW)}),")
    L.append(f"    .stdIn_valid({cat(lambda w:f'io_storeDataIn_{w}_valid', STW)}),")
    L.append(f"    .stdIn_sqIdx({cat(lambda w:f'std{w}_sq', STW)}),")
    # store ready vec/ptr
    L.append("    .stAddrReadySqPtr('{flag:io_stAddrReadySqPtr_flag, value:io_stAddrReadySqPtr_value}),")
    L.append(f"    .stAddrReadyVec({cat(lambda i:f'io_stAddrReadyVec_{i}', SQSZ)}),")
    L.append("    .stDataReadySqPtr('{flag:io_stDataReadySqPtr_flag, value:io_stDataReadySqPtr_value}),")
    L.append(f"    .stDataReadyVec({cat(lambda i:f'io_stDataReadyVec_{i}', SQSZ)}),")
    # misc
    L.append("    .tl_d_valid(io_tl_d_channel_valid), .tl_d_mshrid(io_tl_d_channel_mshrid),")
    L.append("    .sqEmpty(io_sqEmpty),")
    L.append("    .ldWbPtr('{flag:io_ldWbPtr_flag, value:io_ldWbPtr_value}),")
    L.append("    .rarFull(io_rarFull), .rawFull(io_rawFull),")
    L.append("    .loadMisalignFull(io_loadMisalignFull), .misalignAllowSpec(io_misalignAllowSpec),")
    L.append("    .l2_hint_valid(io_l2_hint_valid), .l2_hint_sourceId(io_l2_hint_bits_sourceId),")
    L.append("    .l2_hint_isKeyword(io_l2_hint_bits_isKeyword),")
    L.append("    .tlb_hint_valid(io_tlb_hint_resp_valid), .tlb_hint_id(io_tlb_hint_resp_bits_id),")
    L.append("    .tlb_hint_replay_all(io_tlb_hint_resp_bits_replay_all),")
    # debug topdown
    L.append("    .dtd_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),")
    L.append("    .dtd_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),")
    L.append("    .dtd_robHeadMissInDTlb(io_debugTopDown_robHeadMissInDTlb),")
    L.append("    .dtd_robHeadTlbReplay(io_debugTopDown_robHeadTlbReplay),")
    L.append("    .dtd_robHeadTlbMiss(io_debugTopDown_robHeadTlbMiss),")
    L.append("    .dtd_robHeadLoadVio(io_debugTopDown_robHeadLoadVio),")
    L.append("    .dtd_robHeadLoadMSHR(io_debugTopDown_robHeadLoadMSHR),")
    # replay out buses
    L.append(f"    .replay_valid({cat(lambda w:f'rep_valid[{w}]', LDW)}),")
    L.append(f"    .replay_ready({cat(lambda w:f'io_replay_{w}_ready', LDW)}),")
    L.append(f"    .replay_uop({cat(lambda w:f'rep_uop[{w}]', LDW)}),")
    L.append(f"    .replay_vaddr({cat(lambda w:f'io_replay_{w}_bits_vaddr', LDW)}),")
    L.append(f"    .replay_vec({cat(lambda w:f'rep_vec[{w}]', LDW)}),")
    L.append(f"    .replay_mshrid({cat(lambda w:f'io_replay_{w}_bits_mshrid', LDW)}),")
    L.append(f"    .replay_forward_tlDchannel({cat(lambda w:f'io_replay_{w}_bits_forward_tlDchannel', LDW)}),")
    L.append(f"    .replay_schedIndex({cat(lambda w:f'io_replay_{w}_bits_schedIndex', LDW)}),")
    L.append("    .lqFull(io_lqFull),")
    L.append("    .perf_value(perf_value)")
    L.append("  );")
    return "\n".join(L)

# ---- wrapper 适配层（局部 struct 打包 + replay 输出解包）---------------------
def adapt():
    L = []
    L.append("  import loadqueuereplay_pkg::*;")
    L.append("  // ---- 输入侧打包 ----")
    # vecFeedback robIdx
    for j in range(VECW):
        L.append(f"  rob_ptr_t vfb{j}_rob; assign vfb{j}_rob = '{{flag:io_vecFeedback_{j}_bits_robidx_flag, value:io_vecFeedback_{j}_bits_robidx_value}};")
    # enq uop / vec / cause / sq idx
    for w in range(LDW):
        L.append(f"  lqr_uop_t enq{w}_uop;")
        L.append(f"  lqr_vec_t enq{w}_vec;")
        L.append(f"  logic [10:0] enq{w}_cause;")
        L.append(f"  sq_ptr_t enq{w}_data_inv, enq{w}_addr_inv;")
    L.append("")
    for w in range(LDW):
        # exceptionVec: 24 bits, golden has all 24 input bits io_enq_w_bits_uop_exceptionVec_0..23
        ev = "{" + ", ".join(f"io_enq_{w}_bits_uop_exceptionVec_{b}" for b in range(23,-1,-1)) + "}"
        L.append(f"  assign enq{w}_uop = '{{")
        L.append(f"    exceptionVec:{ev},")
        L.append(f"    preDecodeInfo_isRVC:io_enq_{w}_bits_uop_preDecodeInfo_isRVC,")
        L.append(f"    ftqPtr_flag:io_enq_{w}_bits_uop_ftqPtr_flag, ftqPtr_value:io_enq_{w}_bits_uop_ftqPtr_value,")
        L.append(f"    ftqOffset:io_enq_{w}_bits_uop_ftqOffset, fuOpType:io_enq_{w}_bits_uop_fuOpType,")
        L.append(f"    rfWen:io_enq_{w}_bits_uop_rfWen, fpWen:io_enq_{w}_bits_uop_fpWen,")
        L.append(f"    vpu_vstart:io_enq_{w}_bits_uop_vpu_vstart, vpu_veew:io_enq_{w}_bits_uop_vpu_veew,")
        L.append(f"    uopIdx:io_enq_{w}_bits_uop_uopIdx, pdest:io_enq_{w}_bits_uop_pdest,")
        L.append(f"    robIdx:'{{flag:io_enq_{w}_bits_uop_robIdx_flag, value:io_enq_{w}_bits_uop_robIdx_value}},")
        L.append(f"    dbg_enqRsTime:io_enq_{w}_bits_uop_debugInfo_enqRsTime,")
        L.append(f"    dbg_selectTime:io_enq_{w}_bits_uop_debugInfo_selectTime,")
        L.append(f"    dbg_issueTime:io_enq_{w}_bits_uop_debugInfo_issueTime,")
        L.append(f"    storeSetHit:io_enq_{w}_bits_uop_storeSetHit,")
        L.append(f"    waitForRobIdx_flag:io_enq_{w}_bits_uop_waitForRobIdx_flag, waitForRobIdx_value:io_enq_{w}_bits_uop_waitForRobIdx_value,")
        L.append(f"    loadWaitBit:io_enq_{w}_bits_uop_loadWaitBit, loadWaitStrict:io_enq_{w}_bits_uop_loadWaitStrict,")
        L.append(f"    lqIdx:'{{flag:io_enq_{w}_bits_uop_lqIdx_flag, value:io_enq_{w}_bits_uop_lqIdx_value}},")
        L.append(f"    sqIdx:'{{flag:io_enq_{w}_bits_uop_sqIdx_flag, value:io_enq_{w}_bits_uop_sqIdx_value}}}};")
        L.append(f"  assign enq{w}_vec = '{{")
        L.append(f"    isvec:io_enq_{w}_bits_isvec, isLastElem:1'b0, is128bit:io_enq_{w}_bits_is128bit,")
        L.append(f"    uop_unit_stride_fof:1'b0, usSecondInv:1'b0,")
        L.append(f"    elemIdx:io_enq_{w}_bits_elemIdx, alignedType:io_enq_{w}_bits_alignedType,")
        L.append(f"    mbIndex:io_enq_{w}_bits_mbIndex, elemIdxInsideVd:io_enq_{w}_bits_elemIdxInsideVd,")
        L.append(f"    reg_offset:io_enq_{w}_bits_reg_offset, vecActive:io_enq_{w}_bits_vecActive,")
        L.append(f"    is_first_ele:1'b0, mask:io_enq_{w}_bits_mask}};")
        cz = "{" + ", ".join(f"io_enq_{w}_bits_rep_info_cause_{b}" for b in range(10,-1,-1)) + "}"
        L.append(f"  assign enq{w}_cause = {cz};")
        L.append(f"  assign enq{w}_data_inv = '{{flag:io_enq_{w}_bits_rep_info_data_inv_sq_idx_flag, value:io_enq_{w}_bits_rep_info_data_inv_sq_idx_value}};")
        L.append(f"  assign enq{w}_addr_inv = '{{flag:io_enq_{w}_bits_rep_info_addr_inv_sq_idx_flag, value:io_enq_{w}_bits_rep_info_addr_inv_sq_idx_value}};")
    for w in range(STW):
        L.append(f"  sq_ptr_t sta{w}_sq; assign sta{w}_sq = '{{flag:io_storeAddrIn_{w}_bits_uop_sqIdx_flag, value:io_storeAddrIn_{w}_bits_uop_sqIdx_value}};")
        L.append(f"  sq_ptr_t std{w}_sq; assign std{w}_sq = '{{flag:io_storeDataIn_{w}_bits_uop_sqIdx_flag, value:io_storeDataIn_{w}_bits_uop_sqIdx_value}};")
    L.append("")
    L.append("  // ---- 输出侧解包 ----")
    L.append("  logic [2:0] rep_valid;")
    L.append("  lqr_uop_t   rep_uop [3];")
    L.append("  lqr_vec_t   rep_vec [3];")
    L.append("  logic [5:0] perf_value [13];")
    # replay uop exceptionVec output bits present in golden (skip 3,4,5,13,21)
    EV_OUT = [0,1,2,6,7,8,9,10,11,12,14,15,16,17,18,19,20,22,23]
    for w in range(LDW):
        L.append(f"  assign io_replay_{w}_valid = rep_valid[{w}];")
        for b in EV_OUT:
            L.append(f"  assign io_replay_{w}_bits_uop_exceptionVec_{b} = rep_uop[{w}].exceptionVec[{b}];")
        L.append(f"  assign io_replay_{w}_bits_uop_preDecodeInfo_isRVC = rep_uop[{w}].preDecodeInfo_isRVC;")
        L.append(f"  assign io_replay_{w}_bits_uop_ftqPtr_flag = rep_uop[{w}].ftqPtr_flag;")
        L.append(f"  assign io_replay_{w}_bits_uop_ftqPtr_value = rep_uop[{w}].ftqPtr_value;")
        L.append(f"  assign io_replay_{w}_bits_uop_ftqOffset = rep_uop[{w}].ftqOffset;")
        L.append(f"  assign io_replay_{w}_bits_uop_fuOpType = rep_uop[{w}].fuOpType;")
        L.append(f"  assign io_replay_{w}_bits_uop_rfWen = rep_uop[{w}].rfWen;")
        L.append(f"  assign io_replay_{w}_bits_uop_fpWen = rep_uop[{w}].fpWen;")
        L.append(f"  assign io_replay_{w}_bits_uop_vpu_vstart = rep_uop[{w}].vpu_vstart;")
        L.append(f"  assign io_replay_{w}_bits_uop_vpu_veew = rep_uop[{w}].vpu_veew;")
        L.append(f"  assign io_replay_{w}_bits_uop_uopIdx = rep_uop[{w}].uopIdx;")
        L.append(f"  assign io_replay_{w}_bits_uop_pdest = rep_uop[{w}].pdest;")
        L.append(f"  assign io_replay_{w}_bits_uop_robIdx_flag = rep_uop[{w}].robIdx.flag;")
        L.append(f"  assign io_replay_{w}_bits_uop_robIdx_value = rep_uop[{w}].robIdx.value;")
        L.append(f"  assign io_replay_{w}_bits_uop_debugInfo_enqRsTime = rep_uop[{w}].dbg_enqRsTime;")
        L.append(f"  assign io_replay_{w}_bits_uop_debugInfo_selectTime = rep_uop[{w}].dbg_selectTime;")
        L.append(f"  assign io_replay_{w}_bits_uop_debugInfo_issueTime = rep_uop[{w}].dbg_issueTime;")
        L.append(f"  assign io_replay_{w}_bits_uop_storeSetHit = rep_uop[{w}].storeSetHit;")
        L.append(f"  assign io_replay_{w}_bits_uop_waitForRobIdx_flag = rep_uop[{w}].waitForRobIdx_flag;")
        L.append(f"  assign io_replay_{w}_bits_uop_waitForRobIdx_value = rep_uop[{w}].waitForRobIdx_value;")
        L.append(f"  assign io_replay_{w}_bits_uop_loadWaitBit = rep_uop[{w}].loadWaitBit;")
        L.append(f"  assign io_replay_{w}_bits_uop_lqIdx_flag = rep_uop[{w}].lqIdx.flag;")
        L.append(f"  assign io_replay_{w}_bits_uop_lqIdx_value = rep_uop[{w}].lqIdx.value;")
        L.append(f"  assign io_replay_{w}_bits_uop_sqIdx_flag = rep_uop[{w}].sqIdx.flag;")
        L.append(f"  assign io_replay_{w}_bits_uop_sqIdx_value = rep_uop[{w}].sqIdx.value;")
        L.append(f"  assign io_replay_{w}_bits_mask = rep_vec[{w}].mask;")
        L.append(f"  assign io_replay_{w}_bits_isvec = rep_vec[{w}].isvec;")
        L.append(f"  assign io_replay_{w}_bits_is128bit = rep_vec[{w}].is128bit;")
        L.append(f"  assign io_replay_{w}_bits_elemIdx = rep_vec[{w}].elemIdx;")
        L.append(f"  assign io_replay_{w}_bits_alignedType = rep_vec[{w}].alignedType;")
        L.append(f"  assign io_replay_{w}_bits_mbIndex = rep_vec[{w}].mbIndex;")
        L.append(f"  assign io_replay_{w}_bits_reg_offset = rep_vec[{w}].reg_offset;")
        L.append(f"  assign io_replay_{w}_bits_elemIdxInsideVd = rep_vec[{w}].elemIdxInsideVd;")
        L.append(f"  assign io_replay_{w}_bits_vecActive = rep_vec[{w}].vecActive;")
    for k in range(13):
        L.append(f"  assign io_perf_{k}_value = perf_value[{k}];")
    return "\n".join(L)

def gen_module(modname):
    out = []
    out.append("// 自动生成：scripts/gen_loadqueuereplay.py —— 勿手改")
    out.append(f"module {modname}(")
    out.append(",\n".join(decl(d,w,n) for d,w,n in PORTS))
    out.append(");")
    out.append(adapt())
    out.append(core_inst())
    out.append("endmodule")
    return "\n".join(out)

# ---------------- tb ----------------
def gen_tb():
    inputs  = [(w,n) for d,w,n in PORTS if d=="input"  and n not in ("clock","reset")]
    outputs = [(w,n) for d,w,n in PORTS if d=="output"]
    L = []
    L.append("// 自动生成：scripts/gen_loadqueuereplay.py —— 勿手改")
    L.append("`timescale 1ns/1ps")
    L.append("module tb;")
    L.append("  int unsigned NCYCLES = 250000;")
    L.append("  bit clk = 0, rst;")
    L.append("  int errors = 0, checks = 0;")
    L.append("  always #5 clk = ~clk;")
    L.append("")
    for w,n in inputs:
        L.append(f"  logic {w+' ' if w else ''}{n};")
    for w,n in outputs:
        L.append(f"  wire {w+' ' if w else ''}g_{n};")
        L.append(f"  wire {w+' ' if w else ''}i_{n};")
    L.append("")
    def inst(name, pfx):
        s = [f"  LoadQueueReplay{'' if name=='g' else '_xs'} u_{name} ("]
        s.append("    .clock(clk), .reset(rst),")
        conns = []
        for d,w,n in PORTS:
            if n in ("clock","reset"): continue
            if d=="input":  conns.append(f"    .{n}({n})")
            else:           conns.append(f"    .{n}({pfx}{n})")
        s.append(",\n".join(conns))
        s.append("  );")
        return "\n".join(s)
    L.append(inst("g","g_"))
    L.append(inst("i","i_"))
    L.append("")
    # ---- random drive ----
    L.append(r"""  // 随机激励：受限随机以提升各 replay cause / 年龄选择 / 流水路径覆盖。
  //  - enq：3 路随机有效，cause 用随机 11 位（保证常有非零），sqIdx/lqIdx/robIdx 小范围。
  //  - isLoadReplay 较低概率（让首次入队为主，但也覆盖回流释放/重置路径）。
  //  - store addr/data in、stReadyVec/Ptr、tlb/l2 hint、redirect 随机。
  //  - replay.ready 随机（覆盖背压/冷却）。
  task automatic drive();
    int c;
    io_redirect_valid = ($urandom_range(0,19)==0);
    io_redirect_bits_robIdx_flag = $urandom;
    io_redirect_bits_robIdx_value = $urandom_range(0,60);
    io_redirect_bits_level = $urandom;
    for (int j=0;j<2;j++) begin end
    io_vecFeedback_0_valid = ($urandom_range(0,15)==0);
    io_vecFeedback_1_valid = ($urandom_range(0,15)==0);
    io_vecFeedback_0_bits_robidx_flag = $urandom; io_vecFeedback_1_bits_robidx_flag = $urandom;
    io_vecFeedback_0_bits_robidx_value = $urandom_range(0,60); io_vecFeedback_1_bits_robidx_value = $urandom_range(0,60);
    io_vecFeedback_0_bits_uopidx = $urandom_range(0,7); io_vecFeedback_1_bits_uopidx = $urandom_range(0,7);
    io_vecFeedback_0_bits_feedback_0 = $urandom; io_vecFeedback_0_bits_feedback_1 = $urandom;
    io_vecFeedback_1_bits_feedback_0 = $urandom; io_vecFeedback_1_bits_feedback_1 = $urandom;
  endtask""")
    # per-enq driver + remaining inputs (generated programmatically)
    L.append("  task automatic drive_enq();")
    L.append("    int rr;")
    for w in range(LDW):
        L.append(f"    io_enq_{w}_valid = $urandom_range(0,1);")
        L.append(f"    io_enq_{w}_bits_isLoadReplay = ($urandom_range(0,3)==0);")
        L.append(f"    io_enq_{w}_bits_handledByMSHR = $urandom;")
        L.append(f"    io_enq_{w}_bits_schedIndex = $urandom_range(0,71);")
        L.append(f"    io_enq_{w}_bits_tlbMiss = $urandom;")
        # exceptionVec: mostly 0 (so loads can enqueue)
        for b in range(24):
            L.append(f"    io_enq_{w}_bits_uop_exceptionVec_{b} = ($urandom_range(0,63)==0);")
        # cause: random 11 bits but bias to having some set
        for b in range(11):
            L.append(f"    io_enq_{w}_bits_rep_info_cause_{b} = ($urandom_range(0,2)==0);")
        L.append(f"    io_enq_{w}_bits_rep_info_mshr_id = $urandom_range(0,7);")
        L.append(f"    io_enq_{w}_bits_rep_info_full_fwd = $urandom;")
        L.append(f"    io_enq_{w}_bits_rep_info_data_inv_sq_idx_flag = $urandom;")
        L.append(f"    io_enq_{w}_bits_rep_info_data_inv_sq_idx_value = $urandom_range(0,55);")
        L.append(f"    io_enq_{w}_bits_rep_info_addr_inv_sq_idx_flag = $urandom;")
        L.append(f"    io_enq_{w}_bits_rep_info_addr_inv_sq_idx_value = $urandom_range(0,55);")
        L.append(f"    io_enq_{w}_bits_rep_info_last_beat = $urandom;")
        L.append(f"    io_enq_{w}_bits_rep_info_tlb_id = $urandom_range(0,7);")
        L.append(f"    io_enq_{w}_bits_rep_info_tlb_full = $urandom;")
        L.append(f"    io_enq_{w}_bits_vaddr = {{$urandom, $urandom}};")
        L.append(f"    io_enq_{w}_bits_mask = $urandom;")
        L.append(f"    io_enq_{w}_bits_isvec = ($urandom_range(0,7)==0);")
        L.append(f"    io_enq_{w}_bits_is128bit = $urandom;")
        L.append(f"    io_enq_{w}_bits_elemIdx = $urandom;")
        L.append(f"    io_enq_{w}_bits_alignedType = $urandom;")
        L.append(f"    io_enq_{w}_bits_mbIndex = $urandom;")
        L.append(f"    io_enq_{w}_bits_reg_offset = $urandom;")
        L.append(f"    io_enq_{w}_bits_elemIdxInsideVd = $urandom;")
        L.append(f"    io_enq_{w}_bits_vecActive = $urandom;")
        L.append(f"    io_enq_{w}_bits_uop_robIdx_flag = $urandom;")
        L.append(f"    io_enq_{w}_bits_uop_robIdx_value = $urandom_range(0,60);")
        L.append(f"    io_enq_{w}_bits_uop_lqIdx_flag = $urandom;")
        L.append(f"    io_enq_{w}_bits_uop_lqIdx_value = $urandom_range(0,71);")
        L.append(f"    io_enq_{w}_bits_uop_sqIdx_flag = $urandom;")
        L.append(f"    io_enq_{w}_bits_uop_sqIdx_value = $urandom_range(0,55);")
        L.append(f"    io_enq_{w}_bits_uop_loadWaitStrict = $urandom;")
        # remaining uop passthrough fields randomized
        for fld,rng in [("preDecodeInfo_isRVC",None),("ftqPtr_flag",None),("ftqPtr_value",None),
                        ("ftqOffset",None),("fuOpType",None),("rfWen",None),("fpWen",None),
                        ("vpu_vstart",None),("vpu_veew",None),("uopIdx",None),("pdest",None),
                        ("storeSetHit",None),("waitForRobIdx_flag",None),("waitForRobIdx_value",None),
                        ("loadWaitBit",None),("debugInfo_enqRsTime",None),("debugInfo_selectTime",None),
                        ("debugInfo_issueTime",None)]:
            if "debugInfo" in fld:
                L.append(f"    io_enq_{w}_bits_uop_{fld} = {{$urandom,$urandom}};")
            else:
                L.append(f"    io_enq_{w}_bits_uop_{fld} = $urandom;")
    L.append("  endtask")
    # rest
    L.append("  task automatic drive_rest();")
    for w in range(STW):
        L.append(f"    io_storeAddrIn_{w}_valid = $urandom_range(0,1);")
        L.append(f"    io_storeAddrIn_{w}_bits_uop_sqIdx_flag = $urandom;")
        L.append(f"    io_storeAddrIn_{w}_bits_uop_sqIdx_value = $urandom_range(0,55);")
        L.append(f"    io_storeAddrIn_{w}_bits_miss = $urandom;")
        L.append(f"    io_storeDataIn_{w}_valid = $urandom_range(0,1);")
        L.append(f"    io_storeDataIn_{w}_bits_uop_sqIdx_flag = $urandom;")
        L.append(f"    io_storeDataIn_{w}_bits_uop_sqIdx_value = $urandom_range(0,55);")
    L.append("    io_stAddrReadySqPtr_flag = $urandom; io_stAddrReadySqPtr_value = $urandom_range(0,55);")
    L.append("    io_stDataReadySqPtr_flag = $urandom; io_stDataReadySqPtr_value = $urandom_range(0,55);")
    for i in range(SQSZ):
        L.append(f"    io_stAddrReadyVec_{i} = $urandom; io_stDataReadyVec_{i} = $urandom;")
    L.append("    io_sqEmpty = ($urandom_range(0,7)==0);")
    L.append("    io_ldWbPtr_flag = $urandom; io_ldWbPtr_value = $urandom_range(0,71);")
    L.append("    io_rarFull = $urandom; io_rawFull = $urandom;")
    L.append("    io_loadMisalignFull = $urandom; io_misalignAllowSpec = $urandom;")
    L.append("    io_tl_d_channel_valid = $urandom_range(0,1); io_tl_d_channel_mshrid = $urandom_range(0,7);")
    L.append("    io_l2_hint_valid = ($urandom_range(0,7)==0); io_l2_hint_bits_sourceId = $urandom_range(0,7);")
    L.append("    io_l2_hint_bits_isKeyword = $urandom;")
    L.append("    io_tlb_hint_resp_valid = ($urandom_range(0,3)==0); io_tlb_hint_resp_bits_id = $urandom_range(0,7);")
    L.append("    io_tlb_hint_resp_bits_replay_all = ($urandom_range(0,7)==0);")
    L.append("    io_debugTopDown_robHeadVaddr_valid = $urandom; io_debugTopDown_robHeadVaddr_bits = {$urandom,$urandom};")
    L.append("    io_debugTopDown_robHeadMissInDTlb = $urandom;")
    L.append("    io_replay_0_ready = $urandom; io_replay_1_ready = $urandom; io_replay_2_ready = $urandom;")
    L.append("  endtask")
    L.append("")
    # checker
    #  io_replay_N_bits_* 是 Decoupled 的 bits：仅在 io_replay_N_valid 为 1 时有意义
    #  （!valid 时 golden/impl 各自驱动「上次选中项的陈旧值」，是 don't-care；golden 的
    #  vaddr 读使能 io_ren 本身就被 X 驱动，印证 bits 不参与等价）。故 bits 比对按 valid 选通。
    import re as _re
    def gate(n):
        m = _re.match(r"io_replay_([0-9]+)_bits_", n)
        return f"g_io_replay_{m.group(1)}_valid && " if m else ""
    L.append("  int warmup = 6;")
    L.append("  always @(posedge clk) if (!rst) begin")
    L.append("    if (warmup > 0) warmup--; else begin")
    L.append("    checks++;")
    for w,n in outputs:
        L.append(f"    if ({gate(n)}!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f"      if(errors<=80) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    L.append("    end")
    L.append("  end")
    L.append("")
    L.append("""  initial begin
    rst = 1; drive(); drive_enq(); drive_rest();
    repeat (10) @(posedge clk);
    rst = 0;
    repeat (NCYCLES) begin @(negedge clk); drive(); drive_enq(); drive_rest(); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule""")
    return "\n".join(L)

if __name__ == "__main__":
    open(os.path.join(ROOT,"rtl","memblock","LoadQueueReplay_wrapper.sv"),"w").write(gen_module("LoadQueueReplay")+"\n")
    vdir = os.path.join(ROOT,"verif","ut","LoadQueueReplay")
    os.makedirs(vdir, exist_ok=True)
    open(os.path.join(vdir,"variants_xs.sv"),"w").write(gen_module("LoadQueueReplay_xs")+"\n")
    open(os.path.join(vdir,"tb.sv"),"w").write(gen_tb()+"\n")
    print("generated wrapper, variants_xs.sv, tb.sv")
