// tb.sv —— VMergeBuffer 家族双例化 UT（由 scripts/gen_vmergebuf.py 生成，勿手改）
//
// 两个变体各一对：golden VLMergeBufferImp / VSMergeBufferImp 与重写件 *_xs（rtl/memblock，
// derive_ut_impl.py 改名）。同激励并跑，每拍（下降沿）逐位比较全部输出端口；
// uopWriteback / toLsq / feedback 的 bits 只在对应 valid（取 golden 侧）为 1 时比较
// —— 它们在 valid=0 时取自没写过的条目/不复位的寄存器，内容没有定义。
//
// 时间线：复位 5 拍 -> 暖机（入队占满 16 条目 / 逐条目带异常写回 / redirect 全冲）-> 随机。
// 暖机的目的：条目里 gpaddr / vaNeedExt / isForVSnonLeafPTE 只在异常写回时才写，
// +vcs+initreg+random 下两侧初值不同，先全部写一遍才能在出队时逐位比较。
// 随机阶段的激励偏置：写回口的 mBIndex 多数取 golden 当前已分配的条目，多口常撞同一条目；
// flowNum 多为 1..4（条目能在几拍内完成出队）；redirect 的 robIdx 与请求落在同一小窗口
// （约一半请求/条目会被冲）；fuOpType 约四成是 unit-stride（走字节合并路径）。
`timescale 1ns/1ps
module tb;
  logic clock = 1'b0;
  logic reset = 1'b1;
  always #5 clock = ~clock;

  int ncycles = 200000;
  int cycle   = 0;
  longint checks = 0;
  int errors = 0;

  function automatic void chk(input string name, input logic bad);
    checks++;
    if (bad) begin
      errors++;
      if (errors <= 20) $display("[%0d] MISMATCH %s", cycle, name);
    end
  endfunction

  function automatic logic [3:0] pick_idx(input logic [15:0] alloc);
    logic [3:0] c;
    if (($urandom % 100) < 80 && alloc != 16'h0) begin
      do c = 4'($urandom); while (!alloc[c]);
      return c;
    end
    return 4'($urandom);
  endfunction

  function automatic logic [3:0] pick_trigger();
    int r;
    r = $urandom % 100;
    if (r < 70) return 4'd15;
    if (r < 80) return 4'd0;
    if (r < 90) return 4'd1;
    return 4'($urandom);
  endfunction

  // ---------------- VLMergeBufferImp ----------------
  logic            vl_io_redirect_valid;
  logic            vl_io_redirect_bits_robIdx_flag;
  logic [7:0]      vl_io_redirect_bits_robIdx_value;
  logic            vl_io_redirect_bits_level;
  logic            vl_io_fromPipeline_0_valid;
  logic [3:0]      vl_io_fromPipeline_0_bits_mBIndex;
  logic [3:0]      vl_io_fromPipeline_0_bits_trigger;
  logic            vl_io_fromPipeline_0_bits_exceptionVec_3;
  logic            vl_io_fromPipeline_0_bits_exceptionVec_4;
  logic            vl_io_fromPipeline_0_bits_exceptionVec_5;
  logic            vl_io_fromPipeline_0_bits_exceptionVec_13;
  logic            vl_io_fromPipeline_0_bits_exceptionVec_19;
  logic            vl_io_fromPipeline_0_bits_exceptionVec_21;
  logic            vl_io_fromPipeline_0_bits_hasException;
  logic [63:0]     vl_io_fromPipeline_0_bits_vaddr;
  logic            vl_io_fromPipeline_0_bits_vaNeedExt;
  logic [63:0]     vl_io_fromPipeline_0_bits_gpaddr;
  logic            vl_io_fromPipeline_0_bits_isForVSnonLeafPTE;
  logic [7:0]      vl_io_fromPipeline_0_bits_vstart;
  logic [15:0]     vl_io_fromPipeline_0_bits_vecTriggerMask;
  logic [7:0]      vl_io_fromPipeline_0_bits_elemIdx;
  logic [15:0]     vl_io_fromPipeline_0_bits_mask;
  logic [2:0]      vl_io_fromPipeline_0_bits_alignedType;
  logic [3:0]      vl_io_fromPipeline_0_bits_reg_offset;
  logic [7:0]      vl_io_fromPipeline_0_bits_elemIdxInsideVd;
  logic [127:0]    vl_io_fromPipeline_0_bits_vecdata;
  logic            vl_io_fromPipeline_1_valid;
  logic [3:0]      vl_io_fromPipeline_1_bits_mBIndex;
  logic [3:0]      vl_io_fromPipeline_1_bits_trigger;
  logic            vl_io_fromPipeline_1_bits_exceptionVec_3;
  logic            vl_io_fromPipeline_1_bits_exceptionVec_4;
  logic            vl_io_fromPipeline_1_bits_exceptionVec_5;
  logic            vl_io_fromPipeline_1_bits_exceptionVec_13;
  logic            vl_io_fromPipeline_1_bits_exceptionVec_19;
  logic            vl_io_fromPipeline_1_bits_exceptionVec_21;
  logic            vl_io_fromPipeline_1_bits_hasException;
  logic [63:0]     vl_io_fromPipeline_1_bits_vaddr;
  logic            vl_io_fromPipeline_1_bits_vaNeedExt;
  logic [63:0]     vl_io_fromPipeline_1_bits_gpaddr;
  logic            vl_io_fromPipeline_1_bits_isForVSnonLeafPTE;
  logic [7:0]      vl_io_fromPipeline_1_bits_vstart;
  logic [15:0]     vl_io_fromPipeline_1_bits_vecTriggerMask;
  logic [7:0]      vl_io_fromPipeline_1_bits_elemIdx;
  logic [15:0]     vl_io_fromPipeline_1_bits_mask;
  logic [2:0]      vl_io_fromPipeline_1_bits_alignedType;
  logic [3:0]      vl_io_fromPipeline_1_bits_reg_offset;
  logic [7:0]      vl_io_fromPipeline_1_bits_elemIdxInsideVd;
  logic [127:0]    vl_io_fromPipeline_1_bits_vecdata;
  logic            vl_io_fromPipeline_2_valid;
  logic [3:0]      vl_io_fromPipeline_2_bits_mBIndex;
  logic [3:0]      vl_io_fromPipeline_2_bits_trigger;
  logic            vl_io_fromPipeline_2_bits_exceptionVec_3;
  logic            vl_io_fromPipeline_2_bits_exceptionVec_4;
  logic            vl_io_fromPipeline_2_bits_exceptionVec_5;
  logic            vl_io_fromPipeline_2_bits_exceptionVec_13;
  logic            vl_io_fromPipeline_2_bits_exceptionVec_19;
  logic            vl_io_fromPipeline_2_bits_exceptionVec_21;
  logic            vl_io_fromPipeline_2_bits_hasException;
  logic [63:0]     vl_io_fromPipeline_2_bits_vaddr;
  logic            vl_io_fromPipeline_2_bits_vaNeedExt;
  logic [63:0]     vl_io_fromPipeline_2_bits_gpaddr;
  logic            vl_io_fromPipeline_2_bits_isForVSnonLeafPTE;
  logic [7:0]      vl_io_fromPipeline_2_bits_vstart;
  logic [15:0]     vl_io_fromPipeline_2_bits_vecTriggerMask;
  logic [7:0]      vl_io_fromPipeline_2_bits_elemIdx;
  logic [15:0]     vl_io_fromPipeline_2_bits_mask;
  logic [2:0]      vl_io_fromPipeline_2_bits_alignedType;
  logic [3:0]      vl_io_fromPipeline_2_bits_reg_offset;
  logic [7:0]      vl_io_fromPipeline_2_bits_elemIdxInsideVd;
  logic [127:0]    vl_io_fromPipeline_2_bits_vecdata;
  logic            vl_g_io_fromSplit_0_req_ready;
  logic            vl_i_io_fromSplit_0_req_ready;
  logic            vl_io_fromSplit_0_req_valid;
  logic [15:0]     vl_io_fromSplit_0_req_bits_mask;
  logic [49:0]     vl_io_fromSplit_0_req_bits_vaddr;
  logic [4:0]      vl_io_fromSplit_0_req_bits_flowNum;
  logic [8:0]      vl_io_fromSplit_0_req_bits_uop_fuOpType;
  logic            vl_io_fromSplit_0_req_bits_uop_vecWen;
  logic            vl_io_fromSplit_0_req_bits_uop_v0Wen;
  logic            vl_io_fromSplit_0_req_bits_uop_vlWen;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_vill;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_vma;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_vta;
  logic [1:0]      vl_io_fromSplit_0_req_bits_uop_vpu_vsew;
  logic [2:0]      vl_io_fromSplit_0_req_bits_uop_vpu_vlmul;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_specVill;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_specVma;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_specVta;
  logic [1:0]      vl_io_fromSplit_0_req_bits_uop_vpu_specVsew;
  logic [2:0]      vl_io_fromSplit_0_req_bits_uop_vpu_specVlmul;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_vm;
  logic [2:0]      vl_io_fromSplit_0_req_bits_uop_vpu_frm;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      vl_io_fromSplit_0_req_bits_uop_vpu_vxrm;
  logic [6:0]      vl_io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_lastUop;
  logic [7:0]      vl_io_fromSplit_0_req_bits_uop_vpu_vl;
  logic [2:0]      vl_io_fromSplit_0_req_bits_uop_vpu_nf;
  logic [1:0]      vl_io_fromSplit_0_req_bits_uop_vpu_veew;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isReverse;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isExt;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isNarrow;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isDstMask;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isOpMask;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isMove;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd;
  logic            vl_io_fromSplit_0_req_bits_uop_vpu_isVleff;
  logic [6:0]      vl_io_fromSplit_0_req_bits_uop_uopIdx;
  logic [7:0]      vl_io_fromSplit_0_req_bits_uop_pdest;
  logic            vl_io_fromSplit_0_req_bits_uop_robIdx_flag;
  logic [7:0]      vl_io_fromSplit_0_req_bits_uop_robIdx_value;
  logic            vl_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_renameTime;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     vl_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx;
  logic            vl_io_fromSplit_0_req_bits_uop_lqIdx_flag;
  logic [6:0]      vl_io_fromSplit_0_req_bits_uop_lqIdx_value;
  logic            vl_io_fromSplit_0_req_bits_uop_sqIdx_flag;
  logic [5:0]      vl_io_fromSplit_0_req_bits_uop_sqIdx_value;
  logic [127:0]    vl_io_fromSplit_0_req_bits_data;
  logic [2:0]      vl_io_fromSplit_0_req_bits_vdIdx;
  logic            vl_io_fromSplit_0_req_bits_fof;
  logic [7:0]      vl_io_fromSplit_0_req_bits_vlmax;
  logic            vl_g_io_fromSplit_0_resp_valid;
  logic            vl_i_io_fromSplit_0_resp_valid;
  logic [3:0]      vl_g_io_fromSplit_0_resp_bits_mBIndex;
  logic [3:0]      vl_i_io_fromSplit_0_resp_bits_mBIndex;
  logic            vl_g_io_fromSplit_1_req_ready;
  logic            vl_i_io_fromSplit_1_req_ready;
  logic            vl_io_fromSplit_1_req_valid;
  logic [15:0]     vl_io_fromSplit_1_req_bits_mask;
  logic [49:0]     vl_io_fromSplit_1_req_bits_vaddr;
  logic [4:0]      vl_io_fromSplit_1_req_bits_flowNum;
  logic [8:0]      vl_io_fromSplit_1_req_bits_uop_fuOpType;
  logic            vl_io_fromSplit_1_req_bits_uop_vecWen;
  logic            vl_io_fromSplit_1_req_bits_uop_v0Wen;
  logic            vl_io_fromSplit_1_req_bits_uop_vlWen;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_vill;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_vma;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_vta;
  logic [1:0]      vl_io_fromSplit_1_req_bits_uop_vpu_vsew;
  logic [2:0]      vl_io_fromSplit_1_req_bits_uop_vpu_vlmul;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_specVill;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_specVma;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_specVta;
  logic [1:0]      vl_io_fromSplit_1_req_bits_uop_vpu_specVsew;
  logic [2:0]      vl_io_fromSplit_1_req_bits_uop_vpu_specVlmul;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_vm;
  logic [2:0]      vl_io_fromSplit_1_req_bits_uop_vpu_frm;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      vl_io_fromSplit_1_req_bits_uop_vpu_vxrm;
  logic [6:0]      vl_io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_lastUop;
  logic [7:0]      vl_io_fromSplit_1_req_bits_uop_vpu_vl;
  logic [2:0]      vl_io_fromSplit_1_req_bits_uop_vpu_nf;
  logic [1:0]      vl_io_fromSplit_1_req_bits_uop_vpu_veew;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isReverse;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isExt;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isNarrow;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isDstMask;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isOpMask;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isMove;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isDependOldVd;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isWritePartVd;
  logic            vl_io_fromSplit_1_req_bits_uop_vpu_isVleff;
  logic [6:0]      vl_io_fromSplit_1_req_bits_uop_uopIdx;
  logic [7:0]      vl_io_fromSplit_1_req_bits_uop_pdest;
  logic            vl_io_fromSplit_1_req_bits_uop_robIdx_flag;
  logic [7:0]      vl_io_fromSplit_1_req_bits_uop_robIdx_value;
  logic            vl_io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_renameTime;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     vl_io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx;
  logic            vl_io_fromSplit_1_req_bits_uop_lqIdx_flag;
  logic [6:0]      vl_io_fromSplit_1_req_bits_uop_lqIdx_value;
  logic            vl_io_fromSplit_1_req_bits_uop_sqIdx_flag;
  logic [5:0]      vl_io_fromSplit_1_req_bits_uop_sqIdx_value;
  logic [127:0]    vl_io_fromSplit_1_req_bits_data;
  logic [2:0]      vl_io_fromSplit_1_req_bits_vdIdx;
  logic            vl_io_fromSplit_1_req_bits_fof;
  logic [7:0]      vl_io_fromSplit_1_req_bits_vlmax;
  logic            vl_g_io_fromSplit_1_resp_valid;
  logic            vl_i_io_fromSplit_1_resp_valid;
  logic [3:0]      vl_g_io_fromSplit_1_resp_bits_mBIndex;
  logic [3:0]      vl_i_io_fromSplit_1_resp_bits_mBIndex;
  logic            vl_io_uopWriteback_0_ready;
  logic            vl_g_io_uopWriteback_0_valid;
  logic            vl_i_io_uopWriteback_0_valid;
  logic            vl_g_io_uopWriteback_0_bits_uop_exceptionVec_3;
  logic            vl_i_io_uopWriteback_0_bits_uop_exceptionVec_3;
  logic            vl_g_io_uopWriteback_0_bits_uop_exceptionVec_4;
  logic            vl_i_io_uopWriteback_0_bits_uop_exceptionVec_4;
  logic            vl_g_io_uopWriteback_0_bits_uop_exceptionVec_5;
  logic            vl_i_io_uopWriteback_0_bits_uop_exceptionVec_5;
  logic            vl_g_io_uopWriteback_0_bits_uop_exceptionVec_13;
  logic            vl_i_io_uopWriteback_0_bits_uop_exceptionVec_13;
  logic            vl_g_io_uopWriteback_0_bits_uop_exceptionVec_19;
  logic            vl_i_io_uopWriteback_0_bits_uop_exceptionVec_19;
  logic            vl_g_io_uopWriteback_0_bits_uop_exceptionVec_21;
  logic            vl_i_io_uopWriteback_0_bits_uop_exceptionVec_21;
  logic [3:0]      vl_g_io_uopWriteback_0_bits_uop_trigger;
  logic [3:0]      vl_i_io_uopWriteback_0_bits_uop_trigger;
  logic [8:0]      vl_g_io_uopWriteback_0_bits_uop_fuOpType;
  logic [8:0]      vl_i_io_uopWriteback_0_bits_uop_fuOpType;
  logic            vl_g_io_uopWriteback_0_bits_uop_vecWen;
  logic            vl_i_io_uopWriteback_0_bits_uop_vecWen;
  logic            vl_g_io_uopWriteback_0_bits_uop_v0Wen;
  logic            vl_i_io_uopWriteback_0_bits_uop_v0Wen;
  logic            vl_g_io_uopWriteback_0_bits_uop_vlWen;
  logic            vl_i_io_uopWriteback_0_bits_uop_vlWen;
  logic            vl_g_io_uopWriteback_0_bits_uop_flushPipe;
  logic            vl_i_io_uopWriteback_0_bits_uop_flushPipe;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_vill;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_vill;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_vma;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_vma;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_vta;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_vta;
  logic [1:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_vsew;
  logic [1:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_vsew;
  logic [2:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_vlmul;
  logic [2:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_vlmul;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_specVill;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_specVill;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_specVma;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_specVma;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_specVta;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_specVta;
  logic [1:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_specVsew;
  logic [1:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_specVsew;
  logic [2:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_specVlmul;
  logic [2:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_specVlmul;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_vm;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_vm;
  logic [7:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_vstart;
  logic [7:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_vstart;
  logic [2:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_frm;
  logic [2:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_frm;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_vxrm;
  logic [1:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_vxrm;
  logic [6:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_vuopIdx;
  logic [6:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_vuopIdx;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_lastUop;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_lastUop;
  logic [127:0]    vl_g_io_uopWriteback_0_bits_uop_vpu_vmask;
  logic [127:0]    vl_i_io_uopWriteback_0_bits_uop_vpu_vmask;
  logic [7:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_vl;
  logic [7:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_vl;
  logic [2:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_nf;
  logic [2:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_nf;
  logic [1:0]      vl_g_io_uopWriteback_0_bits_uop_vpu_veew;
  logic [1:0]      vl_i_io_uopWriteback_0_bits_uop_vpu_veew;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isReverse;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isReverse;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isExt;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isExt;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isNarrow;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isNarrow;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isDstMask;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isDstMask;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isOpMask;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isOpMask;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isMove;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isMove;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isDependOldVd;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isDependOldVd;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isWritePartVd;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isWritePartVd;
  logic            vl_g_io_uopWriteback_0_bits_uop_vpu_isVleff;
  logic            vl_i_io_uopWriteback_0_bits_uop_vpu_isVleff;
  logic [7:0]      vl_g_io_uopWriteback_0_bits_uop_psrc_2;
  logic [7:0]      vl_i_io_uopWriteback_0_bits_uop_psrc_2;
  logic [7:0]      vl_g_io_uopWriteback_0_bits_uop_pdest;
  logic [7:0]      vl_i_io_uopWriteback_0_bits_uop_pdest;
  logic            vl_g_io_uopWriteback_0_bits_uop_robIdx_flag;
  logic            vl_i_io_uopWriteback_0_bits_uop_robIdx_flag;
  logic [7:0]      vl_g_io_uopWriteback_0_bits_uop_robIdx_value;
  logic [7:0]      vl_i_io_uopWriteback_0_bits_uop_robIdx_value;
  logic            vl_g_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove;
  logic            vl_i_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_renameTime;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_renameTime;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_selectTime;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_selectTime;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_issueTime;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_issueTime;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vl_g_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime;
  logic [63:0]     vl_i_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     vl_g_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum;
  logic [55:0]     vl_i_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      vl_g_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx;
  logic [7:0]      vl_i_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx;
  logic            vl_g_io_uopWriteback_0_bits_uop_replayInst;
  logic            vl_i_io_uopWriteback_0_bits_uop_replayInst;
  logic [127:0]    vl_g_io_uopWriteback_0_bits_data;
  logic [127:0]    vl_i_io_uopWriteback_0_bits_data;
  logic [2:0]      vl_g_io_uopWriteback_0_bits_vdIdx;
  logic [2:0]      vl_i_io_uopWriteback_0_bits_vdIdx;
  logic [2:0]      vl_g_io_uopWriteback_0_bits_vdIdxInField;
  logic [2:0]      vl_i_io_uopWriteback_0_bits_vdIdxInField;
  logic            vl_io_uopWriteback_1_ready;
  logic            vl_g_io_uopWriteback_1_valid;
  logic            vl_i_io_uopWriteback_1_valid;
  logic            vl_g_io_uopWriteback_1_bits_uop_exceptionVec_3;
  logic            vl_i_io_uopWriteback_1_bits_uop_exceptionVec_3;
  logic            vl_g_io_uopWriteback_1_bits_uop_exceptionVec_4;
  logic            vl_i_io_uopWriteback_1_bits_uop_exceptionVec_4;
  logic            vl_g_io_uopWriteback_1_bits_uop_exceptionVec_5;
  logic            vl_i_io_uopWriteback_1_bits_uop_exceptionVec_5;
  logic            vl_g_io_uopWriteback_1_bits_uop_exceptionVec_13;
  logic            vl_i_io_uopWriteback_1_bits_uop_exceptionVec_13;
  logic            vl_g_io_uopWriteback_1_bits_uop_exceptionVec_19;
  logic            vl_i_io_uopWriteback_1_bits_uop_exceptionVec_19;
  logic            vl_g_io_uopWriteback_1_bits_uop_exceptionVec_21;
  logic            vl_i_io_uopWriteback_1_bits_uop_exceptionVec_21;
  logic [3:0]      vl_g_io_uopWriteback_1_bits_uop_trigger;
  logic [3:0]      vl_i_io_uopWriteback_1_bits_uop_trigger;
  logic [8:0]      vl_g_io_uopWriteback_1_bits_uop_fuOpType;
  logic [8:0]      vl_i_io_uopWriteback_1_bits_uop_fuOpType;
  logic            vl_g_io_uopWriteback_1_bits_uop_vecWen;
  logic            vl_i_io_uopWriteback_1_bits_uop_vecWen;
  logic            vl_g_io_uopWriteback_1_bits_uop_v0Wen;
  logic            vl_i_io_uopWriteback_1_bits_uop_v0Wen;
  logic            vl_g_io_uopWriteback_1_bits_uop_vlWen;
  logic            vl_i_io_uopWriteback_1_bits_uop_vlWen;
  logic            vl_g_io_uopWriteback_1_bits_uop_flushPipe;
  logic            vl_i_io_uopWriteback_1_bits_uop_flushPipe;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_vill;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_vill;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_vma;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_vma;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_vta;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_vta;
  logic [1:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_vsew;
  logic [1:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_vsew;
  logic [2:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_vlmul;
  logic [2:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_vlmul;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_specVill;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_specVill;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_specVma;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_specVma;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_specVta;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_specVta;
  logic [1:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_specVsew;
  logic [1:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_specVsew;
  logic [2:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_specVlmul;
  logic [2:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_specVlmul;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_vm;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_vm;
  logic [7:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_vstart;
  logic [7:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_vstart;
  logic [2:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_frm;
  logic [2:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_frm;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isReduction;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isReduction;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_vxrm;
  logic [1:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_vxrm;
  logic [6:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_vuopIdx;
  logic [6:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_vuopIdx;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_lastUop;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_lastUop;
  logic [127:0]    vl_g_io_uopWriteback_1_bits_uop_vpu_vmask;
  logic [127:0]    vl_i_io_uopWriteback_1_bits_uop_vpu_vmask;
  logic [7:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_vl;
  logic [7:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_vl;
  logic [2:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_nf;
  logic [2:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_nf;
  logic [1:0]      vl_g_io_uopWriteback_1_bits_uop_vpu_veew;
  logic [1:0]      vl_i_io_uopWriteback_1_bits_uop_vpu_veew;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isReverse;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isReverse;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isExt;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isExt;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isNarrow;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isNarrow;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isDstMask;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isDstMask;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isOpMask;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isOpMask;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isMove;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isMove;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isDependOldVd;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isDependOldVd;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isWritePartVd;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isWritePartVd;
  logic            vl_g_io_uopWriteback_1_bits_uop_vpu_isVleff;
  logic            vl_i_io_uopWriteback_1_bits_uop_vpu_isVleff;
  logic [7:0]      vl_g_io_uopWriteback_1_bits_uop_psrc_2;
  logic [7:0]      vl_i_io_uopWriteback_1_bits_uop_psrc_2;
  logic [7:0]      vl_g_io_uopWriteback_1_bits_uop_pdest;
  logic [7:0]      vl_i_io_uopWriteback_1_bits_uop_pdest;
  logic            vl_g_io_uopWriteback_1_bits_uop_robIdx_flag;
  logic            vl_i_io_uopWriteback_1_bits_uop_robIdx_flag;
  logic [7:0]      vl_g_io_uopWriteback_1_bits_uop_robIdx_value;
  logic [7:0]      vl_i_io_uopWriteback_1_bits_uop_robIdx_value;
  logic            vl_g_io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove;
  logic            vl_i_io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_renameTime;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_renameTime;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_selectTime;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_selectTime;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_issueTime;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_issueTime;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vl_g_io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime;
  logic [63:0]     vl_i_io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     vl_g_io_uopWriteback_1_bits_uop_debug_seqNum_seqNum;
  logic [55:0]     vl_i_io_uopWriteback_1_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      vl_g_io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx;
  logic [7:0]      vl_i_io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx;
  logic            vl_g_io_uopWriteback_1_bits_uop_replayInst;
  logic            vl_i_io_uopWriteback_1_bits_uop_replayInst;
  logic [127:0]    vl_g_io_uopWriteback_1_bits_data;
  logic [127:0]    vl_i_io_uopWriteback_1_bits_data;
  logic [2:0]      vl_g_io_uopWriteback_1_bits_vdIdx;
  logic [2:0]      vl_i_io_uopWriteback_1_bits_vdIdx;
  logic [2:0]      vl_g_io_uopWriteback_1_bits_vdIdxInField;
  logic [2:0]      vl_i_io_uopWriteback_1_bits_vdIdxInField;
  logic            vl_g_io_toSplit_threshold;
  logic            vl_i_io_toSplit_threshold;
  logic            vl_g_io_toLsq_0_valid;
  logic            vl_i_io_toLsq_0_valid;
  logic            vl_g_io_toLsq_0_bits_robidx_flag;
  logic            vl_i_io_toLsq_0_bits_robidx_flag;
  logic [7:0]      vl_g_io_toLsq_0_bits_robidx_value;
  logic [7:0]      vl_i_io_toLsq_0_bits_robidx_value;
  logic [6:0]      vl_g_io_toLsq_0_bits_uopidx;
  logic [6:0]      vl_i_io_toLsq_0_bits_uopidx;
  logic [63:0]     vl_g_io_toLsq_0_bits_vaddr;
  logic [63:0]     vl_i_io_toLsq_0_bits_vaddr;
  logic            vl_g_io_toLsq_0_bits_vaNeedExt;
  logic            vl_i_io_toLsq_0_bits_vaNeedExt;
  logic [63:0]     vl_g_io_toLsq_0_bits_gpaddr;
  logic [63:0]     vl_i_io_toLsq_0_bits_gpaddr;
  logic            vl_g_io_toLsq_0_bits_isForVSnonLeafPTE;
  logic            vl_i_io_toLsq_0_bits_isForVSnonLeafPTE;
  logic            vl_g_io_toLsq_0_bits_feedback_0;
  logic            vl_i_io_toLsq_0_bits_feedback_0;
  logic            vl_g_io_toLsq_0_bits_feedback_1;
  logic            vl_i_io_toLsq_0_bits_feedback_1;
  logic [7:0]      vl_g_io_toLsq_0_bits_vl;
  logic [7:0]      vl_i_io_toLsq_0_bits_vl;
  logic            vl_g_io_toLsq_0_bits_exceptionVec_3;
  logic            vl_i_io_toLsq_0_bits_exceptionVec_3;
  logic            vl_g_io_toLsq_0_bits_exceptionVec_4;
  logic            vl_i_io_toLsq_0_bits_exceptionVec_4;
  logic            vl_g_io_toLsq_0_bits_exceptionVec_5;
  logic            vl_i_io_toLsq_0_bits_exceptionVec_5;
  logic            vl_g_io_toLsq_0_bits_exceptionVec_13;
  logic            vl_i_io_toLsq_0_bits_exceptionVec_13;
  logic            vl_g_io_toLsq_0_bits_exceptionVec_19;
  logic            vl_i_io_toLsq_0_bits_exceptionVec_19;
  logic            vl_g_io_toLsq_0_bits_exceptionVec_21;
  logic            vl_i_io_toLsq_0_bits_exceptionVec_21;
  logic            vl_g_io_toLsq_1_valid;
  logic            vl_i_io_toLsq_1_valid;
  logic            vl_g_io_toLsq_1_bits_robidx_flag;
  logic            vl_i_io_toLsq_1_bits_robidx_flag;
  logic [7:0]      vl_g_io_toLsq_1_bits_robidx_value;
  logic [7:0]      vl_i_io_toLsq_1_bits_robidx_value;
  logic [6:0]      vl_g_io_toLsq_1_bits_uopidx;
  logic [6:0]      vl_i_io_toLsq_1_bits_uopidx;
  logic [63:0]     vl_g_io_toLsq_1_bits_vaddr;
  logic [63:0]     vl_i_io_toLsq_1_bits_vaddr;
  logic            vl_g_io_toLsq_1_bits_vaNeedExt;
  logic            vl_i_io_toLsq_1_bits_vaNeedExt;
  logic [63:0]     vl_g_io_toLsq_1_bits_gpaddr;
  logic [63:0]     vl_i_io_toLsq_1_bits_gpaddr;
  logic            vl_g_io_toLsq_1_bits_isForVSnonLeafPTE;
  logic            vl_i_io_toLsq_1_bits_isForVSnonLeafPTE;
  logic            vl_g_io_toLsq_1_bits_feedback_0;
  logic            vl_i_io_toLsq_1_bits_feedback_0;
  logic            vl_g_io_toLsq_1_bits_feedback_1;
  logic            vl_i_io_toLsq_1_bits_feedback_1;
  logic [7:0]      vl_g_io_toLsq_1_bits_vl;
  logic [7:0]      vl_i_io_toLsq_1_bits_vl;
  logic            vl_g_io_toLsq_1_bits_exceptionVec_3;
  logic            vl_i_io_toLsq_1_bits_exceptionVec_3;
  logic            vl_g_io_toLsq_1_bits_exceptionVec_4;
  logic            vl_i_io_toLsq_1_bits_exceptionVec_4;
  logic            vl_g_io_toLsq_1_bits_exceptionVec_5;
  logic            vl_i_io_toLsq_1_bits_exceptionVec_5;
  logic            vl_g_io_toLsq_1_bits_exceptionVec_13;
  logic            vl_i_io_toLsq_1_bits_exceptionVec_13;
  logic            vl_g_io_toLsq_1_bits_exceptionVec_19;
  logic            vl_i_io_toLsq_1_bits_exceptionVec_19;
  logic            vl_g_io_toLsq_1_bits_exceptionVec_21;
  logic            vl_i_io_toLsq_1_bits_exceptionVec_21;
  logic            vl_g_io_feedback_0_valid;
  logic            vl_i_io_feedback_0_valid;
  logic            vl_g_io_feedback_0_bits_robIdx_flag;
  logic            vl_i_io_feedback_0_bits_robIdx_flag;
  logic [7:0]      vl_g_io_feedback_0_bits_robIdx_value;
  logic [7:0]      vl_i_io_feedback_0_bits_robIdx_value;
  logic            vl_g_io_feedback_0_bits_hit;
  logic            vl_i_io_feedback_0_bits_hit;
  logic            vl_g_io_feedback_0_bits_flushState;
  logic            vl_i_io_feedback_0_bits_flushState;
  logic [3:0]      vl_g_io_feedback_0_bits_sourceType;
  logic [3:0]      vl_i_io_feedback_0_bits_sourceType;
  logic            vl_g_io_feedback_0_bits_sqIdx_flag;
  logic            vl_i_io_feedback_0_bits_sqIdx_flag;
  logic [5:0]      vl_g_io_feedback_0_bits_sqIdx_value;
  logic [5:0]      vl_i_io_feedback_0_bits_sqIdx_value;
  logic            vl_g_io_feedback_0_bits_lqIdx_flag;
  logic            vl_i_io_feedback_0_bits_lqIdx_flag;
  logic [6:0]      vl_g_io_feedback_0_bits_lqIdx_value;
  logic [6:0]      vl_i_io_feedback_0_bits_lqIdx_value;
  logic            vl_g_io_feedback_0_bits_isVecPartReplay;
  logic            vl_i_io_feedback_0_bits_isVecPartReplay;
  logic [15:0]     vl_g_io_feedback_0_bits_vecReplayMask;
  logic [15:0]     vl_i_io_feedback_0_bits_vecReplayMask;
  logic [3:0]      vl_g_io_feedback_0_bits_vecReplayMbIdx;
  logic [3:0]      vl_i_io_feedback_0_bits_vecReplayMbIdx;
  logic            vl_g_io_feedback_1_valid;
  logic            vl_i_io_feedback_1_valid;
  logic            vl_g_io_feedback_1_bits_robIdx_flag;
  logic            vl_i_io_feedback_1_bits_robIdx_flag;
  logic [7:0]      vl_g_io_feedback_1_bits_robIdx_value;
  logic [7:0]      vl_i_io_feedback_1_bits_robIdx_value;
  logic            vl_g_io_feedback_1_bits_hit;
  logic            vl_i_io_feedback_1_bits_hit;
  logic            vl_g_io_feedback_1_bits_flushState;
  logic            vl_i_io_feedback_1_bits_flushState;
  logic [3:0]      vl_g_io_feedback_1_bits_sourceType;
  logic [3:0]      vl_i_io_feedback_1_bits_sourceType;
  logic            vl_g_io_feedback_1_bits_sqIdx_flag;
  logic            vl_i_io_feedback_1_bits_sqIdx_flag;
  logic [5:0]      vl_g_io_feedback_1_bits_sqIdx_value;
  logic [5:0]      vl_i_io_feedback_1_bits_sqIdx_value;
  logic            vl_g_io_feedback_1_bits_lqIdx_flag;
  logic            vl_i_io_feedback_1_bits_lqIdx_flag;
  logic [6:0]      vl_g_io_feedback_1_bits_lqIdx_value;
  logic [6:0]      vl_i_io_feedback_1_bits_lqIdx_value;
  logic            vl_g_io_feedback_1_bits_isVecPartReplay;
  logic            vl_i_io_feedback_1_bits_isVecPartReplay;
  logic [15:0]     vl_g_io_feedback_1_bits_vecReplayMask;
  logic [15:0]     vl_i_io_feedback_1_bits_vecReplayMask;
  logic [3:0]      vl_g_io_feedback_1_bits_vecReplayMbIdx;
  logic [3:0]      vl_i_io_feedback_1_bits_vecReplayMbIdx;
  longint          cov_vl [5];  // 写回 / toLsq / 反馈 / 部分重放 / 带异常出队
  logic [15:0]     vl_alloc;
  assign vl_alloc = {u_vl_g.allocated_15, u_vl_g.allocated_14, u_vl_g.allocated_13, u_vl_g.allocated_12, u_vl_g.allocated_11, u_vl_g.allocated_10, u_vl_g.allocated_9, u_vl_g.allocated_8, u_vl_g.allocated_7, u_vl_g.allocated_6, u_vl_g.allocated_5, u_vl_g.allocated_4, u_vl_g.allocated_3, u_vl_g.allocated_2, u_vl_g.allocated_1, u_vl_g.allocated_0};
  VLMergeBufferImp u_vl_g (
    .clock                                                        (clock),
    .reset                                                        (reset),
    .io_redirect_valid                                            (vl_io_redirect_valid),
    .io_redirect_bits_robIdx_flag                                 (vl_io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value                                (vl_io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                                       (vl_io_redirect_bits_level),
    .io_fromPipeline_0_valid                                      (vl_io_fromPipeline_0_valid),
    .io_fromPipeline_0_bits_mBIndex                               (vl_io_fromPipeline_0_bits_mBIndex),
    .io_fromPipeline_0_bits_trigger                               (vl_io_fromPipeline_0_bits_trigger),
    .io_fromPipeline_0_bits_exceptionVec_3                        (vl_io_fromPipeline_0_bits_exceptionVec_3),
    .io_fromPipeline_0_bits_exceptionVec_4                        (vl_io_fromPipeline_0_bits_exceptionVec_4),
    .io_fromPipeline_0_bits_exceptionVec_5                        (vl_io_fromPipeline_0_bits_exceptionVec_5),
    .io_fromPipeline_0_bits_exceptionVec_13                       (vl_io_fromPipeline_0_bits_exceptionVec_13),
    .io_fromPipeline_0_bits_exceptionVec_19                       (vl_io_fromPipeline_0_bits_exceptionVec_19),
    .io_fromPipeline_0_bits_exceptionVec_21                       (vl_io_fromPipeline_0_bits_exceptionVec_21),
    .io_fromPipeline_0_bits_hasException                          (vl_io_fromPipeline_0_bits_hasException),
    .io_fromPipeline_0_bits_vaddr                                 (vl_io_fromPipeline_0_bits_vaddr),
    .io_fromPipeline_0_bits_vaNeedExt                             (vl_io_fromPipeline_0_bits_vaNeedExt),
    .io_fromPipeline_0_bits_gpaddr                                (vl_io_fromPipeline_0_bits_gpaddr),
    .io_fromPipeline_0_bits_isForVSnonLeafPTE                     (vl_io_fromPipeline_0_bits_isForVSnonLeafPTE),
    .io_fromPipeline_0_bits_vstart                                (vl_io_fromPipeline_0_bits_vstart),
    .io_fromPipeline_0_bits_vecTriggerMask                        (vl_io_fromPipeline_0_bits_vecTriggerMask),
    .io_fromPipeline_0_bits_elemIdx                               (vl_io_fromPipeline_0_bits_elemIdx),
    .io_fromPipeline_0_bits_mask                                  (vl_io_fromPipeline_0_bits_mask),
    .io_fromPipeline_0_bits_alignedType                           (vl_io_fromPipeline_0_bits_alignedType),
    .io_fromPipeline_0_bits_reg_offset                            (vl_io_fromPipeline_0_bits_reg_offset),
    .io_fromPipeline_0_bits_elemIdxInsideVd                       (vl_io_fromPipeline_0_bits_elemIdxInsideVd),
    .io_fromPipeline_0_bits_vecdata                               (vl_io_fromPipeline_0_bits_vecdata),
    .io_fromPipeline_1_valid                                      (vl_io_fromPipeline_1_valid),
    .io_fromPipeline_1_bits_mBIndex                               (vl_io_fromPipeline_1_bits_mBIndex),
    .io_fromPipeline_1_bits_trigger                               (vl_io_fromPipeline_1_bits_trigger),
    .io_fromPipeline_1_bits_exceptionVec_3                        (vl_io_fromPipeline_1_bits_exceptionVec_3),
    .io_fromPipeline_1_bits_exceptionVec_4                        (vl_io_fromPipeline_1_bits_exceptionVec_4),
    .io_fromPipeline_1_bits_exceptionVec_5                        (vl_io_fromPipeline_1_bits_exceptionVec_5),
    .io_fromPipeline_1_bits_exceptionVec_13                       (vl_io_fromPipeline_1_bits_exceptionVec_13),
    .io_fromPipeline_1_bits_exceptionVec_19                       (vl_io_fromPipeline_1_bits_exceptionVec_19),
    .io_fromPipeline_1_bits_exceptionVec_21                       (vl_io_fromPipeline_1_bits_exceptionVec_21),
    .io_fromPipeline_1_bits_hasException                          (vl_io_fromPipeline_1_bits_hasException),
    .io_fromPipeline_1_bits_vaddr                                 (vl_io_fromPipeline_1_bits_vaddr),
    .io_fromPipeline_1_bits_vaNeedExt                             (vl_io_fromPipeline_1_bits_vaNeedExt),
    .io_fromPipeline_1_bits_gpaddr                                (vl_io_fromPipeline_1_bits_gpaddr),
    .io_fromPipeline_1_bits_isForVSnonLeafPTE                     (vl_io_fromPipeline_1_bits_isForVSnonLeafPTE),
    .io_fromPipeline_1_bits_vstart                                (vl_io_fromPipeline_1_bits_vstart),
    .io_fromPipeline_1_bits_vecTriggerMask                        (vl_io_fromPipeline_1_bits_vecTriggerMask),
    .io_fromPipeline_1_bits_elemIdx                               (vl_io_fromPipeline_1_bits_elemIdx),
    .io_fromPipeline_1_bits_mask                                  (vl_io_fromPipeline_1_bits_mask),
    .io_fromPipeline_1_bits_alignedType                           (vl_io_fromPipeline_1_bits_alignedType),
    .io_fromPipeline_1_bits_reg_offset                            (vl_io_fromPipeline_1_bits_reg_offset),
    .io_fromPipeline_1_bits_elemIdxInsideVd                       (vl_io_fromPipeline_1_bits_elemIdxInsideVd),
    .io_fromPipeline_1_bits_vecdata                               (vl_io_fromPipeline_1_bits_vecdata),
    .io_fromPipeline_2_valid                                      (vl_io_fromPipeline_2_valid),
    .io_fromPipeline_2_bits_mBIndex                               (vl_io_fromPipeline_2_bits_mBIndex),
    .io_fromPipeline_2_bits_trigger                               (vl_io_fromPipeline_2_bits_trigger),
    .io_fromPipeline_2_bits_exceptionVec_3                        (vl_io_fromPipeline_2_bits_exceptionVec_3),
    .io_fromPipeline_2_bits_exceptionVec_4                        (vl_io_fromPipeline_2_bits_exceptionVec_4),
    .io_fromPipeline_2_bits_exceptionVec_5                        (vl_io_fromPipeline_2_bits_exceptionVec_5),
    .io_fromPipeline_2_bits_exceptionVec_13                       (vl_io_fromPipeline_2_bits_exceptionVec_13),
    .io_fromPipeline_2_bits_exceptionVec_19                       (vl_io_fromPipeline_2_bits_exceptionVec_19),
    .io_fromPipeline_2_bits_exceptionVec_21                       (vl_io_fromPipeline_2_bits_exceptionVec_21),
    .io_fromPipeline_2_bits_hasException                          (vl_io_fromPipeline_2_bits_hasException),
    .io_fromPipeline_2_bits_vaddr                                 (vl_io_fromPipeline_2_bits_vaddr),
    .io_fromPipeline_2_bits_vaNeedExt                             (vl_io_fromPipeline_2_bits_vaNeedExt),
    .io_fromPipeline_2_bits_gpaddr                                (vl_io_fromPipeline_2_bits_gpaddr),
    .io_fromPipeline_2_bits_isForVSnonLeafPTE                     (vl_io_fromPipeline_2_bits_isForVSnonLeafPTE),
    .io_fromPipeline_2_bits_vstart                                (vl_io_fromPipeline_2_bits_vstart),
    .io_fromPipeline_2_bits_vecTriggerMask                        (vl_io_fromPipeline_2_bits_vecTriggerMask),
    .io_fromPipeline_2_bits_elemIdx                               (vl_io_fromPipeline_2_bits_elemIdx),
    .io_fromPipeline_2_bits_mask                                  (vl_io_fromPipeline_2_bits_mask),
    .io_fromPipeline_2_bits_alignedType                           (vl_io_fromPipeline_2_bits_alignedType),
    .io_fromPipeline_2_bits_reg_offset                            (vl_io_fromPipeline_2_bits_reg_offset),
    .io_fromPipeline_2_bits_elemIdxInsideVd                       (vl_io_fromPipeline_2_bits_elemIdxInsideVd),
    .io_fromPipeline_2_bits_vecdata                               (vl_io_fromPipeline_2_bits_vecdata),
    .io_fromSplit_0_req_ready                                     (vl_g_io_fromSplit_0_req_ready),
    .io_fromSplit_0_req_valid                                     (vl_io_fromSplit_0_req_valid),
    .io_fromSplit_0_req_bits_mask                                 (vl_io_fromSplit_0_req_bits_mask),
    .io_fromSplit_0_req_bits_vaddr                                (vl_io_fromSplit_0_req_bits_vaddr),
    .io_fromSplit_0_req_bits_flowNum                              (vl_io_fromSplit_0_req_bits_flowNum),
    .io_fromSplit_0_req_bits_uop_fuOpType                         (vl_io_fromSplit_0_req_bits_uop_fuOpType),
    .io_fromSplit_0_req_bits_uop_vecWen                           (vl_io_fromSplit_0_req_bits_uop_vecWen),
    .io_fromSplit_0_req_bits_uop_v0Wen                            (vl_io_fromSplit_0_req_bits_uop_v0Wen),
    .io_fromSplit_0_req_bits_uop_vlWen                            (vl_io_fromSplit_0_req_bits_uop_vlWen),
    .io_fromSplit_0_req_bits_uop_vpu_vill                         (vl_io_fromSplit_0_req_bits_uop_vpu_vill),
    .io_fromSplit_0_req_bits_uop_vpu_vma                          (vl_io_fromSplit_0_req_bits_uop_vpu_vma),
    .io_fromSplit_0_req_bits_uop_vpu_vta                          (vl_io_fromSplit_0_req_bits_uop_vpu_vta),
    .io_fromSplit_0_req_bits_uop_vpu_vsew                         (vl_io_fromSplit_0_req_bits_uop_vpu_vsew),
    .io_fromSplit_0_req_bits_uop_vpu_vlmul                        (vl_io_fromSplit_0_req_bits_uop_vpu_vlmul),
    .io_fromSplit_0_req_bits_uop_vpu_specVill                     (vl_io_fromSplit_0_req_bits_uop_vpu_specVill),
    .io_fromSplit_0_req_bits_uop_vpu_specVma                      (vl_io_fromSplit_0_req_bits_uop_vpu_specVma),
    .io_fromSplit_0_req_bits_uop_vpu_specVta                      (vl_io_fromSplit_0_req_bits_uop_vpu_specVta),
    .io_fromSplit_0_req_bits_uop_vpu_specVsew                     (vl_io_fromSplit_0_req_bits_uop_vpu_specVsew),
    .io_fromSplit_0_req_bits_uop_vpu_specVlmul                    (vl_io_fromSplit_0_req_bits_uop_vpu_specVlmul),
    .io_fromSplit_0_req_bits_uop_vpu_vm                           (vl_io_fromSplit_0_req_bits_uop_vpu_vm),
    .io_fromSplit_0_req_bits_uop_vpu_frm                          (vl_io_fromSplit_0_req_bits_uop_vpu_frm),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst            (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_fromSplit_0_req_bits_uop_vpu_vxrm                         (vl_io_fromSplit_0_req_bits_uop_vpu_vxrm),
    .io_fromSplit_0_req_bits_uop_vpu_vuopIdx                      (vl_io_fromSplit_0_req_bits_uop_vpu_vuopIdx),
    .io_fromSplit_0_req_bits_uop_vpu_lastUop                      (vl_io_fromSplit_0_req_bits_uop_vpu_lastUop),
    .io_fromSplit_0_req_bits_uop_vpu_vl                           (vl_io_fromSplit_0_req_bits_uop_vpu_vl),
    .io_fromSplit_0_req_bits_uop_vpu_nf                           (vl_io_fromSplit_0_req_bits_uop_vpu_nf),
    .io_fromSplit_0_req_bits_uop_vpu_veew                         (vl_io_fromSplit_0_req_bits_uop_vpu_veew),
    .io_fromSplit_0_req_bits_uop_vpu_isReverse                    (vl_io_fromSplit_0_req_bits_uop_vpu_isReverse),
    .io_fromSplit_0_req_bits_uop_vpu_isExt                        (vl_io_fromSplit_0_req_bits_uop_vpu_isExt),
    .io_fromSplit_0_req_bits_uop_vpu_isNarrow                     (vl_io_fromSplit_0_req_bits_uop_vpu_isNarrow),
    .io_fromSplit_0_req_bits_uop_vpu_isDstMask                    (vl_io_fromSplit_0_req_bits_uop_vpu_isDstMask),
    .io_fromSplit_0_req_bits_uop_vpu_isOpMask                     (vl_io_fromSplit_0_req_bits_uop_vpu_isOpMask),
    .io_fromSplit_0_req_bits_uop_vpu_isMove                       (vl_io_fromSplit_0_req_bits_uop_vpu_isMove),
    .io_fromSplit_0_req_bits_uop_vpu_isDependOldVd                (vl_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd),
    .io_fromSplit_0_req_bits_uop_vpu_isWritePartVd                (vl_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd),
    .io_fromSplit_0_req_bits_uop_vpu_isVleff                      (vl_io_fromSplit_0_req_bits_uop_vpu_isVleff),
    .io_fromSplit_0_req_bits_uop_uopIdx                           (vl_io_fromSplit_0_req_bits_uop_uopIdx),
    .io_fromSplit_0_req_bits_uop_pdest                            (vl_io_fromSplit_0_req_bits_uop_pdest),
    .io_fromSplit_0_req_bits_uop_robIdx_flag                      (vl_io_fromSplit_0_req_bits_uop_robIdx_flag),
    .io_fromSplit_0_req_bits_uop_robIdx_value                     (vl_io_fromSplit_0_req_bits_uop_robIdx_value),
    .io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove         (vl_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove),
    .io_fromSplit_0_req_bits_uop_debugInfo_renameTime             (vl_io_fromSplit_0_req_bits_uop_debugInfo_renameTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime           (vl_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime              (vl_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_selectTime             (vl_io_fromSplit_0_req_bits_uop_debugInfo_selectTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_issueTime              (vl_io_fromSplit_0_req_bits_uop_debugInfo_issueTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_writebackTime          (vl_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id (vl_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime        (vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime            (vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime),
    .io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum              (vl_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum),
    .io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx              (vl_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx),
    .io_fromSplit_0_req_bits_uop_lqIdx_flag                       (vl_io_fromSplit_0_req_bits_uop_lqIdx_flag),
    .io_fromSplit_0_req_bits_uop_lqIdx_value                      (vl_io_fromSplit_0_req_bits_uop_lqIdx_value),
    .io_fromSplit_0_req_bits_uop_sqIdx_flag                       (vl_io_fromSplit_0_req_bits_uop_sqIdx_flag),
    .io_fromSplit_0_req_bits_uop_sqIdx_value                      (vl_io_fromSplit_0_req_bits_uop_sqIdx_value),
    .io_fromSplit_0_req_bits_data                                 (vl_io_fromSplit_0_req_bits_data),
    .io_fromSplit_0_req_bits_vdIdx                                (vl_io_fromSplit_0_req_bits_vdIdx),
    .io_fromSplit_0_req_bits_fof                                  (vl_io_fromSplit_0_req_bits_fof),
    .io_fromSplit_0_req_bits_vlmax                                (vl_io_fromSplit_0_req_bits_vlmax),
    .io_fromSplit_0_resp_valid                                    (vl_g_io_fromSplit_0_resp_valid),
    .io_fromSplit_0_resp_bits_mBIndex                             (vl_g_io_fromSplit_0_resp_bits_mBIndex),
    .io_fromSplit_1_req_ready                                     (vl_g_io_fromSplit_1_req_ready),
    .io_fromSplit_1_req_valid                                     (vl_io_fromSplit_1_req_valid),
    .io_fromSplit_1_req_bits_mask                                 (vl_io_fromSplit_1_req_bits_mask),
    .io_fromSplit_1_req_bits_vaddr                                (vl_io_fromSplit_1_req_bits_vaddr),
    .io_fromSplit_1_req_bits_flowNum                              (vl_io_fromSplit_1_req_bits_flowNum),
    .io_fromSplit_1_req_bits_uop_fuOpType                         (vl_io_fromSplit_1_req_bits_uop_fuOpType),
    .io_fromSplit_1_req_bits_uop_vecWen                           (vl_io_fromSplit_1_req_bits_uop_vecWen),
    .io_fromSplit_1_req_bits_uop_v0Wen                            (vl_io_fromSplit_1_req_bits_uop_v0Wen),
    .io_fromSplit_1_req_bits_uop_vlWen                            (vl_io_fromSplit_1_req_bits_uop_vlWen),
    .io_fromSplit_1_req_bits_uop_vpu_vill                         (vl_io_fromSplit_1_req_bits_uop_vpu_vill),
    .io_fromSplit_1_req_bits_uop_vpu_vma                          (vl_io_fromSplit_1_req_bits_uop_vpu_vma),
    .io_fromSplit_1_req_bits_uop_vpu_vta                          (vl_io_fromSplit_1_req_bits_uop_vpu_vta),
    .io_fromSplit_1_req_bits_uop_vpu_vsew                         (vl_io_fromSplit_1_req_bits_uop_vpu_vsew),
    .io_fromSplit_1_req_bits_uop_vpu_vlmul                        (vl_io_fromSplit_1_req_bits_uop_vpu_vlmul),
    .io_fromSplit_1_req_bits_uop_vpu_specVill                     (vl_io_fromSplit_1_req_bits_uop_vpu_specVill),
    .io_fromSplit_1_req_bits_uop_vpu_specVma                      (vl_io_fromSplit_1_req_bits_uop_vpu_specVma),
    .io_fromSplit_1_req_bits_uop_vpu_specVta                      (vl_io_fromSplit_1_req_bits_uop_vpu_specVta),
    .io_fromSplit_1_req_bits_uop_vpu_specVsew                     (vl_io_fromSplit_1_req_bits_uop_vpu_specVsew),
    .io_fromSplit_1_req_bits_uop_vpu_specVlmul                    (vl_io_fromSplit_1_req_bits_uop_vpu_specVlmul),
    .io_fromSplit_1_req_bits_uop_vpu_vm                           (vl_io_fromSplit_1_req_bits_uop_vpu_vm),
    .io_fromSplit_1_req_bits_uop_vpu_frm                          (vl_io_fromSplit_1_req_bits_uop_vpu_frm),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst            (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_fromSplit_1_req_bits_uop_vpu_vxrm                         (vl_io_fromSplit_1_req_bits_uop_vpu_vxrm),
    .io_fromSplit_1_req_bits_uop_vpu_vuopIdx                      (vl_io_fromSplit_1_req_bits_uop_vpu_vuopIdx),
    .io_fromSplit_1_req_bits_uop_vpu_lastUop                      (vl_io_fromSplit_1_req_bits_uop_vpu_lastUop),
    .io_fromSplit_1_req_bits_uop_vpu_vl                           (vl_io_fromSplit_1_req_bits_uop_vpu_vl),
    .io_fromSplit_1_req_bits_uop_vpu_nf                           (vl_io_fromSplit_1_req_bits_uop_vpu_nf),
    .io_fromSplit_1_req_bits_uop_vpu_veew                         (vl_io_fromSplit_1_req_bits_uop_vpu_veew),
    .io_fromSplit_1_req_bits_uop_vpu_isReverse                    (vl_io_fromSplit_1_req_bits_uop_vpu_isReverse),
    .io_fromSplit_1_req_bits_uop_vpu_isExt                        (vl_io_fromSplit_1_req_bits_uop_vpu_isExt),
    .io_fromSplit_1_req_bits_uop_vpu_isNarrow                     (vl_io_fromSplit_1_req_bits_uop_vpu_isNarrow),
    .io_fromSplit_1_req_bits_uop_vpu_isDstMask                    (vl_io_fromSplit_1_req_bits_uop_vpu_isDstMask),
    .io_fromSplit_1_req_bits_uop_vpu_isOpMask                     (vl_io_fromSplit_1_req_bits_uop_vpu_isOpMask),
    .io_fromSplit_1_req_bits_uop_vpu_isMove                       (vl_io_fromSplit_1_req_bits_uop_vpu_isMove),
    .io_fromSplit_1_req_bits_uop_vpu_isDependOldVd                (vl_io_fromSplit_1_req_bits_uop_vpu_isDependOldVd),
    .io_fromSplit_1_req_bits_uop_vpu_isWritePartVd                (vl_io_fromSplit_1_req_bits_uop_vpu_isWritePartVd),
    .io_fromSplit_1_req_bits_uop_vpu_isVleff                      (vl_io_fromSplit_1_req_bits_uop_vpu_isVleff),
    .io_fromSplit_1_req_bits_uop_uopIdx                           (vl_io_fromSplit_1_req_bits_uop_uopIdx),
    .io_fromSplit_1_req_bits_uop_pdest                            (vl_io_fromSplit_1_req_bits_uop_pdest),
    .io_fromSplit_1_req_bits_uop_robIdx_flag                      (vl_io_fromSplit_1_req_bits_uop_robIdx_flag),
    .io_fromSplit_1_req_bits_uop_robIdx_value                     (vl_io_fromSplit_1_req_bits_uop_robIdx_value),
    .io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove         (vl_io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove),
    .io_fromSplit_1_req_bits_uop_debugInfo_renameTime             (vl_io_fromSplit_1_req_bits_uop_debugInfo_renameTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime           (vl_io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime              (vl_io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_selectTime             (vl_io_fromSplit_1_req_bits_uop_debugInfo_selectTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_issueTime              (vl_io_fromSplit_1_req_bits_uop_debugInfo_issueTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_writebackTime          (vl_io_fromSplit_1_req_bits_uop_debugInfo_writebackTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id (vl_io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime        (vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime            (vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime),
    .io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum              (vl_io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum),
    .io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx              (vl_io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx),
    .io_fromSplit_1_req_bits_uop_lqIdx_flag                       (vl_io_fromSplit_1_req_bits_uop_lqIdx_flag),
    .io_fromSplit_1_req_bits_uop_lqIdx_value                      (vl_io_fromSplit_1_req_bits_uop_lqIdx_value),
    .io_fromSplit_1_req_bits_uop_sqIdx_flag                       (vl_io_fromSplit_1_req_bits_uop_sqIdx_flag),
    .io_fromSplit_1_req_bits_uop_sqIdx_value                      (vl_io_fromSplit_1_req_bits_uop_sqIdx_value),
    .io_fromSplit_1_req_bits_data                                 (vl_io_fromSplit_1_req_bits_data),
    .io_fromSplit_1_req_bits_vdIdx                                (vl_io_fromSplit_1_req_bits_vdIdx),
    .io_fromSplit_1_req_bits_fof                                  (vl_io_fromSplit_1_req_bits_fof),
    .io_fromSplit_1_req_bits_vlmax                                (vl_io_fromSplit_1_req_bits_vlmax),
    .io_fromSplit_1_resp_valid                                    (vl_g_io_fromSplit_1_resp_valid),
    .io_fromSplit_1_resp_bits_mBIndex                             (vl_g_io_fromSplit_1_resp_bits_mBIndex),
    .io_uopWriteback_0_ready                                      (vl_io_uopWriteback_0_ready),
    .io_uopWriteback_0_valid                                      (vl_g_io_uopWriteback_0_valid),
    .io_uopWriteback_0_bits_uop_exceptionVec_3                    (vl_g_io_uopWriteback_0_bits_uop_exceptionVec_3),
    .io_uopWriteback_0_bits_uop_exceptionVec_4                    (vl_g_io_uopWriteback_0_bits_uop_exceptionVec_4),
    .io_uopWriteback_0_bits_uop_exceptionVec_5                    (vl_g_io_uopWriteback_0_bits_uop_exceptionVec_5),
    .io_uopWriteback_0_bits_uop_exceptionVec_13                   (vl_g_io_uopWriteback_0_bits_uop_exceptionVec_13),
    .io_uopWriteback_0_bits_uop_exceptionVec_19                   (vl_g_io_uopWriteback_0_bits_uop_exceptionVec_19),
    .io_uopWriteback_0_bits_uop_exceptionVec_21                   (vl_g_io_uopWriteback_0_bits_uop_exceptionVec_21),
    .io_uopWriteback_0_bits_uop_trigger                           (vl_g_io_uopWriteback_0_bits_uop_trigger),
    .io_uopWriteback_0_bits_uop_fuOpType                          (vl_g_io_uopWriteback_0_bits_uop_fuOpType),
    .io_uopWriteback_0_bits_uop_vecWen                            (vl_g_io_uopWriteback_0_bits_uop_vecWen),
    .io_uopWriteback_0_bits_uop_v0Wen                             (vl_g_io_uopWriteback_0_bits_uop_v0Wen),
    .io_uopWriteback_0_bits_uop_vlWen                             (vl_g_io_uopWriteback_0_bits_uop_vlWen),
    .io_uopWriteback_0_bits_uop_flushPipe                         (vl_g_io_uopWriteback_0_bits_uop_flushPipe),
    .io_uopWriteback_0_bits_uop_vpu_vill                          (vl_g_io_uopWriteback_0_bits_uop_vpu_vill),
    .io_uopWriteback_0_bits_uop_vpu_vma                           (vl_g_io_uopWriteback_0_bits_uop_vpu_vma),
    .io_uopWriteback_0_bits_uop_vpu_vta                           (vl_g_io_uopWriteback_0_bits_uop_vpu_vta),
    .io_uopWriteback_0_bits_uop_vpu_vsew                          (vl_g_io_uopWriteback_0_bits_uop_vpu_vsew),
    .io_uopWriteback_0_bits_uop_vpu_vlmul                         (vl_g_io_uopWriteback_0_bits_uop_vpu_vlmul),
    .io_uopWriteback_0_bits_uop_vpu_specVill                      (vl_g_io_uopWriteback_0_bits_uop_vpu_specVill),
    .io_uopWriteback_0_bits_uop_vpu_specVma                       (vl_g_io_uopWriteback_0_bits_uop_vpu_specVma),
    .io_uopWriteback_0_bits_uop_vpu_specVta                       (vl_g_io_uopWriteback_0_bits_uop_vpu_specVta),
    .io_uopWriteback_0_bits_uop_vpu_specVsew                      (vl_g_io_uopWriteback_0_bits_uop_vpu_specVsew),
    .io_uopWriteback_0_bits_uop_vpu_specVlmul                     (vl_g_io_uopWriteback_0_bits_uop_vpu_specVlmul),
    .io_uopWriteback_0_bits_uop_vpu_vm                            (vl_g_io_uopWriteback_0_bits_uop_vpu_vm),
    .io_uopWriteback_0_bits_uop_vpu_vstart                        (vl_g_io_uopWriteback_0_bits_uop_vpu_vstart),
    .io_uopWriteback_0_bits_uop_vpu_frm                           (vl_g_io_uopWriteback_0_bits_uop_vpu_frm),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst             (vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr               (vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr               (vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isReduction               (vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2               (vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4               (vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8               (vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopWriteback_0_bits_uop_vpu_vxrm                          (vl_g_io_uopWriteback_0_bits_uop_vpu_vxrm),
    .io_uopWriteback_0_bits_uop_vpu_vuopIdx                       (vl_g_io_uopWriteback_0_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_0_bits_uop_vpu_lastUop                       (vl_g_io_uopWriteback_0_bits_uop_vpu_lastUop),
    .io_uopWriteback_0_bits_uop_vpu_vmask                         (vl_g_io_uopWriteback_0_bits_uop_vpu_vmask),
    .io_uopWriteback_0_bits_uop_vpu_vl                            (vl_g_io_uopWriteback_0_bits_uop_vpu_vl),
    .io_uopWriteback_0_bits_uop_vpu_nf                            (vl_g_io_uopWriteback_0_bits_uop_vpu_nf),
    .io_uopWriteback_0_bits_uop_vpu_veew                          (vl_g_io_uopWriteback_0_bits_uop_vpu_veew),
    .io_uopWriteback_0_bits_uop_vpu_isReverse                     (vl_g_io_uopWriteback_0_bits_uop_vpu_isReverse),
    .io_uopWriteback_0_bits_uop_vpu_isExt                         (vl_g_io_uopWriteback_0_bits_uop_vpu_isExt),
    .io_uopWriteback_0_bits_uop_vpu_isNarrow                      (vl_g_io_uopWriteback_0_bits_uop_vpu_isNarrow),
    .io_uopWriteback_0_bits_uop_vpu_isDstMask                     (vl_g_io_uopWriteback_0_bits_uop_vpu_isDstMask),
    .io_uopWriteback_0_bits_uop_vpu_isOpMask                      (vl_g_io_uopWriteback_0_bits_uop_vpu_isOpMask),
    .io_uopWriteback_0_bits_uop_vpu_isMove                        (vl_g_io_uopWriteback_0_bits_uop_vpu_isMove),
    .io_uopWriteback_0_bits_uop_vpu_isDependOldVd                 (vl_g_io_uopWriteback_0_bits_uop_vpu_isDependOldVd),
    .io_uopWriteback_0_bits_uop_vpu_isWritePartVd                 (vl_g_io_uopWriteback_0_bits_uop_vpu_isWritePartVd),
    .io_uopWriteback_0_bits_uop_vpu_isVleff                       (vl_g_io_uopWriteback_0_bits_uop_vpu_isVleff),
    .io_uopWriteback_0_bits_uop_psrc_2                            (vl_g_io_uopWriteback_0_bits_uop_psrc_2),
    .io_uopWriteback_0_bits_uop_pdest                             (vl_g_io_uopWriteback_0_bits_uop_pdest),
    .io_uopWriteback_0_bits_uop_robIdx_flag                       (vl_g_io_uopWriteback_0_bits_uop_robIdx_flag),
    .io_uopWriteback_0_bits_uop_robIdx_value                      (vl_g_io_uopWriteback_0_bits_uop_robIdx_value),
    .io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove          (vl_g_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove),
    .io_uopWriteback_0_bits_uop_debugInfo_renameTime              (vl_g_io_uopWriteback_0_bits_uop_debugInfo_renameTime),
    .io_uopWriteback_0_bits_uop_debugInfo_dispatchTime            (vl_g_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime),
    .io_uopWriteback_0_bits_uop_debugInfo_enqRsTime               (vl_g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_0_bits_uop_debugInfo_selectTime              (vl_g_io_uopWriteback_0_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_0_bits_uop_debugInfo_issueTime               (vl_g_io_uopWriteback_0_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_0_bits_uop_debugInfo_writebackTime           (vl_g_io_uopWriteback_0_bits_uop_debugInfo_writebackTime),
    .io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id  (vl_g_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime         (vl_g_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime             (vl_g_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime),
    .io_uopWriteback_0_bits_uop_debug_seqNum_seqNum               (vl_g_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum),
    .io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx               (vl_g_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx),
    .io_uopWriteback_0_bits_uop_replayInst                        (vl_g_io_uopWriteback_0_bits_uop_replayInst),
    .io_uopWriteback_0_bits_data                                  (vl_g_io_uopWriteback_0_bits_data),
    .io_uopWriteback_0_bits_vdIdx                                 (vl_g_io_uopWriteback_0_bits_vdIdx),
    .io_uopWriteback_0_bits_vdIdxInField                          (vl_g_io_uopWriteback_0_bits_vdIdxInField),
    .io_uopWriteback_1_ready                                      (vl_io_uopWriteback_1_ready),
    .io_uopWriteback_1_valid                                      (vl_g_io_uopWriteback_1_valid),
    .io_uopWriteback_1_bits_uop_exceptionVec_3                    (vl_g_io_uopWriteback_1_bits_uop_exceptionVec_3),
    .io_uopWriteback_1_bits_uop_exceptionVec_4                    (vl_g_io_uopWriteback_1_bits_uop_exceptionVec_4),
    .io_uopWriteback_1_bits_uop_exceptionVec_5                    (vl_g_io_uopWriteback_1_bits_uop_exceptionVec_5),
    .io_uopWriteback_1_bits_uop_exceptionVec_13                   (vl_g_io_uopWriteback_1_bits_uop_exceptionVec_13),
    .io_uopWriteback_1_bits_uop_exceptionVec_19                   (vl_g_io_uopWriteback_1_bits_uop_exceptionVec_19),
    .io_uopWriteback_1_bits_uop_exceptionVec_21                   (vl_g_io_uopWriteback_1_bits_uop_exceptionVec_21),
    .io_uopWriteback_1_bits_uop_trigger                           (vl_g_io_uopWriteback_1_bits_uop_trigger),
    .io_uopWriteback_1_bits_uop_fuOpType                          (vl_g_io_uopWriteback_1_bits_uop_fuOpType),
    .io_uopWriteback_1_bits_uop_vecWen                            (vl_g_io_uopWriteback_1_bits_uop_vecWen),
    .io_uopWriteback_1_bits_uop_v0Wen                             (vl_g_io_uopWriteback_1_bits_uop_v0Wen),
    .io_uopWriteback_1_bits_uop_vlWen                             (vl_g_io_uopWriteback_1_bits_uop_vlWen),
    .io_uopWriteback_1_bits_uop_flushPipe                         (vl_g_io_uopWriteback_1_bits_uop_flushPipe),
    .io_uopWriteback_1_bits_uop_vpu_vill                          (vl_g_io_uopWriteback_1_bits_uop_vpu_vill),
    .io_uopWriteback_1_bits_uop_vpu_vma                           (vl_g_io_uopWriteback_1_bits_uop_vpu_vma),
    .io_uopWriteback_1_bits_uop_vpu_vta                           (vl_g_io_uopWriteback_1_bits_uop_vpu_vta),
    .io_uopWriteback_1_bits_uop_vpu_vsew                          (vl_g_io_uopWriteback_1_bits_uop_vpu_vsew),
    .io_uopWriteback_1_bits_uop_vpu_vlmul                         (vl_g_io_uopWriteback_1_bits_uop_vpu_vlmul),
    .io_uopWriteback_1_bits_uop_vpu_specVill                      (vl_g_io_uopWriteback_1_bits_uop_vpu_specVill),
    .io_uopWriteback_1_bits_uop_vpu_specVma                       (vl_g_io_uopWriteback_1_bits_uop_vpu_specVma),
    .io_uopWriteback_1_bits_uop_vpu_specVta                       (vl_g_io_uopWriteback_1_bits_uop_vpu_specVta),
    .io_uopWriteback_1_bits_uop_vpu_specVsew                      (vl_g_io_uopWriteback_1_bits_uop_vpu_specVsew),
    .io_uopWriteback_1_bits_uop_vpu_specVlmul                     (vl_g_io_uopWriteback_1_bits_uop_vpu_specVlmul),
    .io_uopWriteback_1_bits_uop_vpu_vm                            (vl_g_io_uopWriteback_1_bits_uop_vpu_vm),
    .io_uopWriteback_1_bits_uop_vpu_vstart                        (vl_g_io_uopWriteback_1_bits_uop_vpu_vstart),
    .io_uopWriteback_1_bits_uop_vpu_frm                           (vl_g_io_uopWriteback_1_bits_uop_vpu_frm),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst             (vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr               (vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr               (vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isReduction               (vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isReduction),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2               (vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4               (vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8               (vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopWriteback_1_bits_uop_vpu_vxrm                          (vl_g_io_uopWriteback_1_bits_uop_vpu_vxrm),
    .io_uopWriteback_1_bits_uop_vpu_vuopIdx                       (vl_g_io_uopWriteback_1_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_1_bits_uop_vpu_lastUop                       (vl_g_io_uopWriteback_1_bits_uop_vpu_lastUop),
    .io_uopWriteback_1_bits_uop_vpu_vmask                         (vl_g_io_uopWriteback_1_bits_uop_vpu_vmask),
    .io_uopWriteback_1_bits_uop_vpu_vl                            (vl_g_io_uopWriteback_1_bits_uop_vpu_vl),
    .io_uopWriteback_1_bits_uop_vpu_nf                            (vl_g_io_uopWriteback_1_bits_uop_vpu_nf),
    .io_uopWriteback_1_bits_uop_vpu_veew                          (vl_g_io_uopWriteback_1_bits_uop_vpu_veew),
    .io_uopWriteback_1_bits_uop_vpu_isReverse                     (vl_g_io_uopWriteback_1_bits_uop_vpu_isReverse),
    .io_uopWriteback_1_bits_uop_vpu_isExt                         (vl_g_io_uopWriteback_1_bits_uop_vpu_isExt),
    .io_uopWriteback_1_bits_uop_vpu_isNarrow                      (vl_g_io_uopWriteback_1_bits_uop_vpu_isNarrow),
    .io_uopWriteback_1_bits_uop_vpu_isDstMask                     (vl_g_io_uopWriteback_1_bits_uop_vpu_isDstMask),
    .io_uopWriteback_1_bits_uop_vpu_isOpMask                      (vl_g_io_uopWriteback_1_bits_uop_vpu_isOpMask),
    .io_uopWriteback_1_bits_uop_vpu_isMove                        (vl_g_io_uopWriteback_1_bits_uop_vpu_isMove),
    .io_uopWriteback_1_bits_uop_vpu_isDependOldVd                 (vl_g_io_uopWriteback_1_bits_uop_vpu_isDependOldVd),
    .io_uopWriteback_1_bits_uop_vpu_isWritePartVd                 (vl_g_io_uopWriteback_1_bits_uop_vpu_isWritePartVd),
    .io_uopWriteback_1_bits_uop_vpu_isVleff                       (vl_g_io_uopWriteback_1_bits_uop_vpu_isVleff),
    .io_uopWriteback_1_bits_uop_psrc_2                            (vl_g_io_uopWriteback_1_bits_uop_psrc_2),
    .io_uopWriteback_1_bits_uop_pdest                             (vl_g_io_uopWriteback_1_bits_uop_pdest),
    .io_uopWriteback_1_bits_uop_robIdx_flag                       (vl_g_io_uopWriteback_1_bits_uop_robIdx_flag),
    .io_uopWriteback_1_bits_uop_robIdx_value                      (vl_g_io_uopWriteback_1_bits_uop_robIdx_value),
    .io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove          (vl_g_io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove),
    .io_uopWriteback_1_bits_uop_debugInfo_renameTime              (vl_g_io_uopWriteback_1_bits_uop_debugInfo_renameTime),
    .io_uopWriteback_1_bits_uop_debugInfo_dispatchTime            (vl_g_io_uopWriteback_1_bits_uop_debugInfo_dispatchTime),
    .io_uopWriteback_1_bits_uop_debugInfo_enqRsTime               (vl_g_io_uopWriteback_1_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_1_bits_uop_debugInfo_selectTime              (vl_g_io_uopWriteback_1_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_1_bits_uop_debugInfo_issueTime               (vl_g_io_uopWriteback_1_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_1_bits_uop_debugInfo_writebackTime           (vl_g_io_uopWriteback_1_bits_uop_debugInfo_writebackTime),
    .io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id  (vl_g_io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime         (vl_g_io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime             (vl_g_io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime),
    .io_uopWriteback_1_bits_uop_debug_seqNum_seqNum               (vl_g_io_uopWriteback_1_bits_uop_debug_seqNum_seqNum),
    .io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx               (vl_g_io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx),
    .io_uopWriteback_1_bits_uop_replayInst                        (vl_g_io_uopWriteback_1_bits_uop_replayInst),
    .io_uopWriteback_1_bits_data                                  (vl_g_io_uopWriteback_1_bits_data),
    .io_uopWriteback_1_bits_vdIdx                                 (vl_g_io_uopWriteback_1_bits_vdIdx),
    .io_uopWriteback_1_bits_vdIdxInField                          (vl_g_io_uopWriteback_1_bits_vdIdxInField),
    .io_toSplit_threshold                                         (vl_g_io_toSplit_threshold),
    .io_toLsq_0_valid                                             (vl_g_io_toLsq_0_valid),
    .io_toLsq_0_bits_robidx_flag                                  (vl_g_io_toLsq_0_bits_robidx_flag),
    .io_toLsq_0_bits_robidx_value                                 (vl_g_io_toLsq_0_bits_robidx_value),
    .io_toLsq_0_bits_uopidx                                       (vl_g_io_toLsq_0_bits_uopidx),
    .io_toLsq_0_bits_vaddr                                        (vl_g_io_toLsq_0_bits_vaddr),
    .io_toLsq_0_bits_vaNeedExt                                    (vl_g_io_toLsq_0_bits_vaNeedExt),
    .io_toLsq_0_bits_gpaddr                                       (vl_g_io_toLsq_0_bits_gpaddr),
    .io_toLsq_0_bits_isForVSnonLeafPTE                            (vl_g_io_toLsq_0_bits_isForVSnonLeafPTE),
    .io_toLsq_0_bits_feedback_0                                   (vl_g_io_toLsq_0_bits_feedback_0),
    .io_toLsq_0_bits_feedback_1                                   (vl_g_io_toLsq_0_bits_feedback_1),
    .io_toLsq_0_bits_vl                                           (vl_g_io_toLsq_0_bits_vl),
    .io_toLsq_0_bits_exceptionVec_3                               (vl_g_io_toLsq_0_bits_exceptionVec_3),
    .io_toLsq_0_bits_exceptionVec_4                               (vl_g_io_toLsq_0_bits_exceptionVec_4),
    .io_toLsq_0_bits_exceptionVec_5                               (vl_g_io_toLsq_0_bits_exceptionVec_5),
    .io_toLsq_0_bits_exceptionVec_13                              (vl_g_io_toLsq_0_bits_exceptionVec_13),
    .io_toLsq_0_bits_exceptionVec_19                              (vl_g_io_toLsq_0_bits_exceptionVec_19),
    .io_toLsq_0_bits_exceptionVec_21                              (vl_g_io_toLsq_0_bits_exceptionVec_21),
    .io_toLsq_1_valid                                             (vl_g_io_toLsq_1_valid),
    .io_toLsq_1_bits_robidx_flag                                  (vl_g_io_toLsq_1_bits_robidx_flag),
    .io_toLsq_1_bits_robidx_value                                 (vl_g_io_toLsq_1_bits_robidx_value),
    .io_toLsq_1_bits_uopidx                                       (vl_g_io_toLsq_1_bits_uopidx),
    .io_toLsq_1_bits_vaddr                                        (vl_g_io_toLsq_1_bits_vaddr),
    .io_toLsq_1_bits_vaNeedExt                                    (vl_g_io_toLsq_1_bits_vaNeedExt),
    .io_toLsq_1_bits_gpaddr                                       (vl_g_io_toLsq_1_bits_gpaddr),
    .io_toLsq_1_bits_isForVSnonLeafPTE                            (vl_g_io_toLsq_1_bits_isForVSnonLeafPTE),
    .io_toLsq_1_bits_feedback_0                                   (vl_g_io_toLsq_1_bits_feedback_0),
    .io_toLsq_1_bits_feedback_1                                   (vl_g_io_toLsq_1_bits_feedback_1),
    .io_toLsq_1_bits_vl                                           (vl_g_io_toLsq_1_bits_vl),
    .io_toLsq_1_bits_exceptionVec_3                               (vl_g_io_toLsq_1_bits_exceptionVec_3),
    .io_toLsq_1_bits_exceptionVec_4                               (vl_g_io_toLsq_1_bits_exceptionVec_4),
    .io_toLsq_1_bits_exceptionVec_5                               (vl_g_io_toLsq_1_bits_exceptionVec_5),
    .io_toLsq_1_bits_exceptionVec_13                              (vl_g_io_toLsq_1_bits_exceptionVec_13),
    .io_toLsq_1_bits_exceptionVec_19                              (vl_g_io_toLsq_1_bits_exceptionVec_19),
    .io_toLsq_1_bits_exceptionVec_21                              (vl_g_io_toLsq_1_bits_exceptionVec_21),
    .io_feedback_0_valid                                          (vl_g_io_feedback_0_valid),
    .io_feedback_0_bits_robIdx_flag                               (vl_g_io_feedback_0_bits_robIdx_flag),
    .io_feedback_0_bits_robIdx_value                              (vl_g_io_feedback_0_bits_robIdx_value),
    .io_feedback_0_bits_hit                                       (vl_g_io_feedback_0_bits_hit),
    .io_feedback_0_bits_flushState                                (vl_g_io_feedback_0_bits_flushState),
    .io_feedback_0_bits_sourceType                                (vl_g_io_feedback_0_bits_sourceType),
    .io_feedback_0_bits_sqIdx_flag                                (vl_g_io_feedback_0_bits_sqIdx_flag),
    .io_feedback_0_bits_sqIdx_value                               (vl_g_io_feedback_0_bits_sqIdx_value),
    .io_feedback_0_bits_lqIdx_flag                                (vl_g_io_feedback_0_bits_lqIdx_flag),
    .io_feedback_0_bits_lqIdx_value                               (vl_g_io_feedback_0_bits_lqIdx_value),
    .io_feedback_0_bits_isVecPartReplay                           (vl_g_io_feedback_0_bits_isVecPartReplay),
    .io_feedback_0_bits_vecReplayMask                             (vl_g_io_feedback_0_bits_vecReplayMask),
    .io_feedback_0_bits_vecReplayMbIdx                            (vl_g_io_feedback_0_bits_vecReplayMbIdx),
    .io_feedback_1_valid                                          (vl_g_io_feedback_1_valid),
    .io_feedback_1_bits_robIdx_flag                               (vl_g_io_feedback_1_bits_robIdx_flag),
    .io_feedback_1_bits_robIdx_value                              (vl_g_io_feedback_1_bits_robIdx_value),
    .io_feedback_1_bits_hit                                       (vl_g_io_feedback_1_bits_hit),
    .io_feedback_1_bits_flushState                                (vl_g_io_feedback_1_bits_flushState),
    .io_feedback_1_bits_sourceType                                (vl_g_io_feedback_1_bits_sourceType),
    .io_feedback_1_bits_sqIdx_flag                                (vl_g_io_feedback_1_bits_sqIdx_flag),
    .io_feedback_1_bits_sqIdx_value                               (vl_g_io_feedback_1_bits_sqIdx_value),
    .io_feedback_1_bits_lqIdx_flag                                (vl_g_io_feedback_1_bits_lqIdx_flag),
    .io_feedback_1_bits_lqIdx_value                               (vl_g_io_feedback_1_bits_lqIdx_value),
    .io_feedback_1_bits_isVecPartReplay                           (vl_g_io_feedback_1_bits_isVecPartReplay),
    .io_feedback_1_bits_vecReplayMask                             (vl_g_io_feedback_1_bits_vecReplayMask),
    .io_feedback_1_bits_vecReplayMbIdx                            (vl_g_io_feedback_1_bits_vecReplayMbIdx)
  );
  VLMergeBufferImp_xs u_vl_i (
    .clock                                                        (clock),
    .reset                                                        (reset),
    .io_redirect_valid                                            (vl_io_redirect_valid),
    .io_redirect_bits_robIdx_flag                                 (vl_io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value                                (vl_io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                                       (vl_io_redirect_bits_level),
    .io_fromPipeline_0_valid                                      (vl_io_fromPipeline_0_valid),
    .io_fromPipeline_0_bits_mBIndex                               (vl_io_fromPipeline_0_bits_mBIndex),
    .io_fromPipeline_0_bits_trigger                               (vl_io_fromPipeline_0_bits_trigger),
    .io_fromPipeline_0_bits_exceptionVec_3                        (vl_io_fromPipeline_0_bits_exceptionVec_3),
    .io_fromPipeline_0_bits_exceptionVec_4                        (vl_io_fromPipeline_0_bits_exceptionVec_4),
    .io_fromPipeline_0_bits_exceptionVec_5                        (vl_io_fromPipeline_0_bits_exceptionVec_5),
    .io_fromPipeline_0_bits_exceptionVec_13                       (vl_io_fromPipeline_0_bits_exceptionVec_13),
    .io_fromPipeline_0_bits_exceptionVec_19                       (vl_io_fromPipeline_0_bits_exceptionVec_19),
    .io_fromPipeline_0_bits_exceptionVec_21                       (vl_io_fromPipeline_0_bits_exceptionVec_21),
    .io_fromPipeline_0_bits_hasException                          (vl_io_fromPipeline_0_bits_hasException),
    .io_fromPipeline_0_bits_vaddr                                 (vl_io_fromPipeline_0_bits_vaddr),
    .io_fromPipeline_0_bits_vaNeedExt                             (vl_io_fromPipeline_0_bits_vaNeedExt),
    .io_fromPipeline_0_bits_gpaddr                                (vl_io_fromPipeline_0_bits_gpaddr),
    .io_fromPipeline_0_bits_isForVSnonLeafPTE                     (vl_io_fromPipeline_0_bits_isForVSnonLeafPTE),
    .io_fromPipeline_0_bits_vstart                                (vl_io_fromPipeline_0_bits_vstart),
    .io_fromPipeline_0_bits_vecTriggerMask                        (vl_io_fromPipeline_0_bits_vecTriggerMask),
    .io_fromPipeline_0_bits_elemIdx                               (vl_io_fromPipeline_0_bits_elemIdx),
    .io_fromPipeline_0_bits_mask                                  (vl_io_fromPipeline_0_bits_mask),
    .io_fromPipeline_0_bits_alignedType                           (vl_io_fromPipeline_0_bits_alignedType),
    .io_fromPipeline_0_bits_reg_offset                            (vl_io_fromPipeline_0_bits_reg_offset),
    .io_fromPipeline_0_bits_elemIdxInsideVd                       (vl_io_fromPipeline_0_bits_elemIdxInsideVd),
    .io_fromPipeline_0_bits_vecdata                               (vl_io_fromPipeline_0_bits_vecdata),
    .io_fromPipeline_1_valid                                      (vl_io_fromPipeline_1_valid),
    .io_fromPipeline_1_bits_mBIndex                               (vl_io_fromPipeline_1_bits_mBIndex),
    .io_fromPipeline_1_bits_trigger                               (vl_io_fromPipeline_1_bits_trigger),
    .io_fromPipeline_1_bits_exceptionVec_3                        (vl_io_fromPipeline_1_bits_exceptionVec_3),
    .io_fromPipeline_1_bits_exceptionVec_4                        (vl_io_fromPipeline_1_bits_exceptionVec_4),
    .io_fromPipeline_1_bits_exceptionVec_5                        (vl_io_fromPipeline_1_bits_exceptionVec_5),
    .io_fromPipeline_1_bits_exceptionVec_13                       (vl_io_fromPipeline_1_bits_exceptionVec_13),
    .io_fromPipeline_1_bits_exceptionVec_19                       (vl_io_fromPipeline_1_bits_exceptionVec_19),
    .io_fromPipeline_1_bits_exceptionVec_21                       (vl_io_fromPipeline_1_bits_exceptionVec_21),
    .io_fromPipeline_1_bits_hasException                          (vl_io_fromPipeline_1_bits_hasException),
    .io_fromPipeline_1_bits_vaddr                                 (vl_io_fromPipeline_1_bits_vaddr),
    .io_fromPipeline_1_bits_vaNeedExt                             (vl_io_fromPipeline_1_bits_vaNeedExt),
    .io_fromPipeline_1_bits_gpaddr                                (vl_io_fromPipeline_1_bits_gpaddr),
    .io_fromPipeline_1_bits_isForVSnonLeafPTE                     (vl_io_fromPipeline_1_bits_isForVSnonLeafPTE),
    .io_fromPipeline_1_bits_vstart                                (vl_io_fromPipeline_1_bits_vstart),
    .io_fromPipeline_1_bits_vecTriggerMask                        (vl_io_fromPipeline_1_bits_vecTriggerMask),
    .io_fromPipeline_1_bits_elemIdx                               (vl_io_fromPipeline_1_bits_elemIdx),
    .io_fromPipeline_1_bits_mask                                  (vl_io_fromPipeline_1_bits_mask),
    .io_fromPipeline_1_bits_alignedType                           (vl_io_fromPipeline_1_bits_alignedType),
    .io_fromPipeline_1_bits_reg_offset                            (vl_io_fromPipeline_1_bits_reg_offset),
    .io_fromPipeline_1_bits_elemIdxInsideVd                       (vl_io_fromPipeline_1_bits_elemIdxInsideVd),
    .io_fromPipeline_1_bits_vecdata                               (vl_io_fromPipeline_1_bits_vecdata),
    .io_fromPipeline_2_valid                                      (vl_io_fromPipeline_2_valid),
    .io_fromPipeline_2_bits_mBIndex                               (vl_io_fromPipeline_2_bits_mBIndex),
    .io_fromPipeline_2_bits_trigger                               (vl_io_fromPipeline_2_bits_trigger),
    .io_fromPipeline_2_bits_exceptionVec_3                        (vl_io_fromPipeline_2_bits_exceptionVec_3),
    .io_fromPipeline_2_bits_exceptionVec_4                        (vl_io_fromPipeline_2_bits_exceptionVec_4),
    .io_fromPipeline_2_bits_exceptionVec_5                        (vl_io_fromPipeline_2_bits_exceptionVec_5),
    .io_fromPipeline_2_bits_exceptionVec_13                       (vl_io_fromPipeline_2_bits_exceptionVec_13),
    .io_fromPipeline_2_bits_exceptionVec_19                       (vl_io_fromPipeline_2_bits_exceptionVec_19),
    .io_fromPipeline_2_bits_exceptionVec_21                       (vl_io_fromPipeline_2_bits_exceptionVec_21),
    .io_fromPipeline_2_bits_hasException                          (vl_io_fromPipeline_2_bits_hasException),
    .io_fromPipeline_2_bits_vaddr                                 (vl_io_fromPipeline_2_bits_vaddr),
    .io_fromPipeline_2_bits_vaNeedExt                             (vl_io_fromPipeline_2_bits_vaNeedExt),
    .io_fromPipeline_2_bits_gpaddr                                (vl_io_fromPipeline_2_bits_gpaddr),
    .io_fromPipeline_2_bits_isForVSnonLeafPTE                     (vl_io_fromPipeline_2_bits_isForVSnonLeafPTE),
    .io_fromPipeline_2_bits_vstart                                (vl_io_fromPipeline_2_bits_vstart),
    .io_fromPipeline_2_bits_vecTriggerMask                        (vl_io_fromPipeline_2_bits_vecTriggerMask),
    .io_fromPipeline_2_bits_elemIdx                               (vl_io_fromPipeline_2_bits_elemIdx),
    .io_fromPipeline_2_bits_mask                                  (vl_io_fromPipeline_2_bits_mask),
    .io_fromPipeline_2_bits_alignedType                           (vl_io_fromPipeline_2_bits_alignedType),
    .io_fromPipeline_2_bits_reg_offset                            (vl_io_fromPipeline_2_bits_reg_offset),
    .io_fromPipeline_2_bits_elemIdxInsideVd                       (vl_io_fromPipeline_2_bits_elemIdxInsideVd),
    .io_fromPipeline_2_bits_vecdata                               (vl_io_fromPipeline_2_bits_vecdata),
    .io_fromSplit_0_req_ready                                     (vl_i_io_fromSplit_0_req_ready),
    .io_fromSplit_0_req_valid                                     (vl_io_fromSplit_0_req_valid),
    .io_fromSplit_0_req_bits_mask                                 (vl_io_fromSplit_0_req_bits_mask),
    .io_fromSplit_0_req_bits_vaddr                                (vl_io_fromSplit_0_req_bits_vaddr),
    .io_fromSplit_0_req_bits_flowNum                              (vl_io_fromSplit_0_req_bits_flowNum),
    .io_fromSplit_0_req_bits_uop_fuOpType                         (vl_io_fromSplit_0_req_bits_uop_fuOpType),
    .io_fromSplit_0_req_bits_uop_vecWen                           (vl_io_fromSplit_0_req_bits_uop_vecWen),
    .io_fromSplit_0_req_bits_uop_v0Wen                            (vl_io_fromSplit_0_req_bits_uop_v0Wen),
    .io_fromSplit_0_req_bits_uop_vlWen                            (vl_io_fromSplit_0_req_bits_uop_vlWen),
    .io_fromSplit_0_req_bits_uop_vpu_vill                         (vl_io_fromSplit_0_req_bits_uop_vpu_vill),
    .io_fromSplit_0_req_bits_uop_vpu_vma                          (vl_io_fromSplit_0_req_bits_uop_vpu_vma),
    .io_fromSplit_0_req_bits_uop_vpu_vta                          (vl_io_fromSplit_0_req_bits_uop_vpu_vta),
    .io_fromSplit_0_req_bits_uop_vpu_vsew                         (vl_io_fromSplit_0_req_bits_uop_vpu_vsew),
    .io_fromSplit_0_req_bits_uop_vpu_vlmul                        (vl_io_fromSplit_0_req_bits_uop_vpu_vlmul),
    .io_fromSplit_0_req_bits_uop_vpu_specVill                     (vl_io_fromSplit_0_req_bits_uop_vpu_specVill),
    .io_fromSplit_0_req_bits_uop_vpu_specVma                      (vl_io_fromSplit_0_req_bits_uop_vpu_specVma),
    .io_fromSplit_0_req_bits_uop_vpu_specVta                      (vl_io_fromSplit_0_req_bits_uop_vpu_specVta),
    .io_fromSplit_0_req_bits_uop_vpu_specVsew                     (vl_io_fromSplit_0_req_bits_uop_vpu_specVsew),
    .io_fromSplit_0_req_bits_uop_vpu_specVlmul                    (vl_io_fromSplit_0_req_bits_uop_vpu_specVlmul),
    .io_fromSplit_0_req_bits_uop_vpu_vm                           (vl_io_fromSplit_0_req_bits_uop_vpu_vm),
    .io_fromSplit_0_req_bits_uop_vpu_frm                          (vl_io_fromSplit_0_req_bits_uop_vpu_frm),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst            (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8              (vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_fromSplit_0_req_bits_uop_vpu_vxrm                         (vl_io_fromSplit_0_req_bits_uop_vpu_vxrm),
    .io_fromSplit_0_req_bits_uop_vpu_vuopIdx                      (vl_io_fromSplit_0_req_bits_uop_vpu_vuopIdx),
    .io_fromSplit_0_req_bits_uop_vpu_lastUop                      (vl_io_fromSplit_0_req_bits_uop_vpu_lastUop),
    .io_fromSplit_0_req_bits_uop_vpu_vl                           (vl_io_fromSplit_0_req_bits_uop_vpu_vl),
    .io_fromSplit_0_req_bits_uop_vpu_nf                           (vl_io_fromSplit_0_req_bits_uop_vpu_nf),
    .io_fromSplit_0_req_bits_uop_vpu_veew                         (vl_io_fromSplit_0_req_bits_uop_vpu_veew),
    .io_fromSplit_0_req_bits_uop_vpu_isReverse                    (vl_io_fromSplit_0_req_bits_uop_vpu_isReverse),
    .io_fromSplit_0_req_bits_uop_vpu_isExt                        (vl_io_fromSplit_0_req_bits_uop_vpu_isExt),
    .io_fromSplit_0_req_bits_uop_vpu_isNarrow                     (vl_io_fromSplit_0_req_bits_uop_vpu_isNarrow),
    .io_fromSplit_0_req_bits_uop_vpu_isDstMask                    (vl_io_fromSplit_0_req_bits_uop_vpu_isDstMask),
    .io_fromSplit_0_req_bits_uop_vpu_isOpMask                     (vl_io_fromSplit_0_req_bits_uop_vpu_isOpMask),
    .io_fromSplit_0_req_bits_uop_vpu_isMove                       (vl_io_fromSplit_0_req_bits_uop_vpu_isMove),
    .io_fromSplit_0_req_bits_uop_vpu_isDependOldVd                (vl_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd),
    .io_fromSplit_0_req_bits_uop_vpu_isWritePartVd                (vl_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd),
    .io_fromSplit_0_req_bits_uop_vpu_isVleff                      (vl_io_fromSplit_0_req_bits_uop_vpu_isVleff),
    .io_fromSplit_0_req_bits_uop_uopIdx                           (vl_io_fromSplit_0_req_bits_uop_uopIdx),
    .io_fromSplit_0_req_bits_uop_pdest                            (vl_io_fromSplit_0_req_bits_uop_pdest),
    .io_fromSplit_0_req_bits_uop_robIdx_flag                      (vl_io_fromSplit_0_req_bits_uop_robIdx_flag),
    .io_fromSplit_0_req_bits_uop_robIdx_value                     (vl_io_fromSplit_0_req_bits_uop_robIdx_value),
    .io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove         (vl_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove),
    .io_fromSplit_0_req_bits_uop_debugInfo_renameTime             (vl_io_fromSplit_0_req_bits_uop_debugInfo_renameTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime           (vl_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime              (vl_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_selectTime             (vl_io_fromSplit_0_req_bits_uop_debugInfo_selectTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_issueTime              (vl_io_fromSplit_0_req_bits_uop_debugInfo_issueTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_writebackTime          (vl_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id (vl_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime        (vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime            (vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime),
    .io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum              (vl_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum),
    .io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx              (vl_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx),
    .io_fromSplit_0_req_bits_uop_lqIdx_flag                       (vl_io_fromSplit_0_req_bits_uop_lqIdx_flag),
    .io_fromSplit_0_req_bits_uop_lqIdx_value                      (vl_io_fromSplit_0_req_bits_uop_lqIdx_value),
    .io_fromSplit_0_req_bits_uop_sqIdx_flag                       (vl_io_fromSplit_0_req_bits_uop_sqIdx_flag),
    .io_fromSplit_0_req_bits_uop_sqIdx_value                      (vl_io_fromSplit_0_req_bits_uop_sqIdx_value),
    .io_fromSplit_0_req_bits_data                                 (vl_io_fromSplit_0_req_bits_data),
    .io_fromSplit_0_req_bits_vdIdx                                (vl_io_fromSplit_0_req_bits_vdIdx),
    .io_fromSplit_0_req_bits_fof                                  (vl_io_fromSplit_0_req_bits_fof),
    .io_fromSplit_0_req_bits_vlmax                                (vl_io_fromSplit_0_req_bits_vlmax),
    .io_fromSplit_0_resp_valid                                    (vl_i_io_fromSplit_0_resp_valid),
    .io_fromSplit_0_resp_bits_mBIndex                             (vl_i_io_fromSplit_0_resp_bits_mBIndex),
    .io_fromSplit_1_req_ready                                     (vl_i_io_fromSplit_1_req_ready),
    .io_fromSplit_1_req_valid                                     (vl_io_fromSplit_1_req_valid),
    .io_fromSplit_1_req_bits_mask                                 (vl_io_fromSplit_1_req_bits_mask),
    .io_fromSplit_1_req_bits_vaddr                                (vl_io_fromSplit_1_req_bits_vaddr),
    .io_fromSplit_1_req_bits_flowNum                              (vl_io_fromSplit_1_req_bits_flowNum),
    .io_fromSplit_1_req_bits_uop_fuOpType                         (vl_io_fromSplit_1_req_bits_uop_fuOpType),
    .io_fromSplit_1_req_bits_uop_vecWen                           (vl_io_fromSplit_1_req_bits_uop_vecWen),
    .io_fromSplit_1_req_bits_uop_v0Wen                            (vl_io_fromSplit_1_req_bits_uop_v0Wen),
    .io_fromSplit_1_req_bits_uop_vlWen                            (vl_io_fromSplit_1_req_bits_uop_vlWen),
    .io_fromSplit_1_req_bits_uop_vpu_vill                         (vl_io_fromSplit_1_req_bits_uop_vpu_vill),
    .io_fromSplit_1_req_bits_uop_vpu_vma                          (vl_io_fromSplit_1_req_bits_uop_vpu_vma),
    .io_fromSplit_1_req_bits_uop_vpu_vta                          (vl_io_fromSplit_1_req_bits_uop_vpu_vta),
    .io_fromSplit_1_req_bits_uop_vpu_vsew                         (vl_io_fromSplit_1_req_bits_uop_vpu_vsew),
    .io_fromSplit_1_req_bits_uop_vpu_vlmul                        (vl_io_fromSplit_1_req_bits_uop_vpu_vlmul),
    .io_fromSplit_1_req_bits_uop_vpu_specVill                     (vl_io_fromSplit_1_req_bits_uop_vpu_specVill),
    .io_fromSplit_1_req_bits_uop_vpu_specVma                      (vl_io_fromSplit_1_req_bits_uop_vpu_specVma),
    .io_fromSplit_1_req_bits_uop_vpu_specVta                      (vl_io_fromSplit_1_req_bits_uop_vpu_specVta),
    .io_fromSplit_1_req_bits_uop_vpu_specVsew                     (vl_io_fromSplit_1_req_bits_uop_vpu_specVsew),
    .io_fromSplit_1_req_bits_uop_vpu_specVlmul                    (vl_io_fromSplit_1_req_bits_uop_vpu_specVlmul),
    .io_fromSplit_1_req_bits_uop_vpu_vm                           (vl_io_fromSplit_1_req_bits_uop_vpu_vm),
    .io_fromSplit_1_req_bits_uop_vpu_frm                          (vl_io_fromSplit_1_req_bits_uop_vpu_frm),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst            (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8              (vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_fromSplit_1_req_bits_uop_vpu_vxrm                         (vl_io_fromSplit_1_req_bits_uop_vpu_vxrm),
    .io_fromSplit_1_req_bits_uop_vpu_vuopIdx                      (vl_io_fromSplit_1_req_bits_uop_vpu_vuopIdx),
    .io_fromSplit_1_req_bits_uop_vpu_lastUop                      (vl_io_fromSplit_1_req_bits_uop_vpu_lastUop),
    .io_fromSplit_1_req_bits_uop_vpu_vl                           (vl_io_fromSplit_1_req_bits_uop_vpu_vl),
    .io_fromSplit_1_req_bits_uop_vpu_nf                           (vl_io_fromSplit_1_req_bits_uop_vpu_nf),
    .io_fromSplit_1_req_bits_uop_vpu_veew                         (vl_io_fromSplit_1_req_bits_uop_vpu_veew),
    .io_fromSplit_1_req_bits_uop_vpu_isReverse                    (vl_io_fromSplit_1_req_bits_uop_vpu_isReverse),
    .io_fromSplit_1_req_bits_uop_vpu_isExt                        (vl_io_fromSplit_1_req_bits_uop_vpu_isExt),
    .io_fromSplit_1_req_bits_uop_vpu_isNarrow                     (vl_io_fromSplit_1_req_bits_uop_vpu_isNarrow),
    .io_fromSplit_1_req_bits_uop_vpu_isDstMask                    (vl_io_fromSplit_1_req_bits_uop_vpu_isDstMask),
    .io_fromSplit_1_req_bits_uop_vpu_isOpMask                     (vl_io_fromSplit_1_req_bits_uop_vpu_isOpMask),
    .io_fromSplit_1_req_bits_uop_vpu_isMove                       (vl_io_fromSplit_1_req_bits_uop_vpu_isMove),
    .io_fromSplit_1_req_bits_uop_vpu_isDependOldVd                (vl_io_fromSplit_1_req_bits_uop_vpu_isDependOldVd),
    .io_fromSplit_1_req_bits_uop_vpu_isWritePartVd                (vl_io_fromSplit_1_req_bits_uop_vpu_isWritePartVd),
    .io_fromSplit_1_req_bits_uop_vpu_isVleff                      (vl_io_fromSplit_1_req_bits_uop_vpu_isVleff),
    .io_fromSplit_1_req_bits_uop_uopIdx                           (vl_io_fromSplit_1_req_bits_uop_uopIdx),
    .io_fromSplit_1_req_bits_uop_pdest                            (vl_io_fromSplit_1_req_bits_uop_pdest),
    .io_fromSplit_1_req_bits_uop_robIdx_flag                      (vl_io_fromSplit_1_req_bits_uop_robIdx_flag),
    .io_fromSplit_1_req_bits_uop_robIdx_value                     (vl_io_fromSplit_1_req_bits_uop_robIdx_value),
    .io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove         (vl_io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove),
    .io_fromSplit_1_req_bits_uop_debugInfo_renameTime             (vl_io_fromSplit_1_req_bits_uop_debugInfo_renameTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime           (vl_io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime              (vl_io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_selectTime             (vl_io_fromSplit_1_req_bits_uop_debugInfo_selectTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_issueTime              (vl_io_fromSplit_1_req_bits_uop_debugInfo_issueTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_writebackTime          (vl_io_fromSplit_1_req_bits_uop_debugInfo_writebackTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id (vl_io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime        (vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime            (vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime),
    .io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum              (vl_io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum),
    .io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx              (vl_io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx),
    .io_fromSplit_1_req_bits_uop_lqIdx_flag                       (vl_io_fromSplit_1_req_bits_uop_lqIdx_flag),
    .io_fromSplit_1_req_bits_uop_lqIdx_value                      (vl_io_fromSplit_1_req_bits_uop_lqIdx_value),
    .io_fromSplit_1_req_bits_uop_sqIdx_flag                       (vl_io_fromSplit_1_req_bits_uop_sqIdx_flag),
    .io_fromSplit_1_req_bits_uop_sqIdx_value                      (vl_io_fromSplit_1_req_bits_uop_sqIdx_value),
    .io_fromSplit_1_req_bits_data                                 (vl_io_fromSplit_1_req_bits_data),
    .io_fromSplit_1_req_bits_vdIdx                                (vl_io_fromSplit_1_req_bits_vdIdx),
    .io_fromSplit_1_req_bits_fof                                  (vl_io_fromSplit_1_req_bits_fof),
    .io_fromSplit_1_req_bits_vlmax                                (vl_io_fromSplit_1_req_bits_vlmax),
    .io_fromSplit_1_resp_valid                                    (vl_i_io_fromSplit_1_resp_valid),
    .io_fromSplit_1_resp_bits_mBIndex                             (vl_i_io_fromSplit_1_resp_bits_mBIndex),
    .io_uopWriteback_0_ready                                      (vl_io_uopWriteback_0_ready),
    .io_uopWriteback_0_valid                                      (vl_i_io_uopWriteback_0_valid),
    .io_uopWriteback_0_bits_uop_exceptionVec_3                    (vl_i_io_uopWriteback_0_bits_uop_exceptionVec_3),
    .io_uopWriteback_0_bits_uop_exceptionVec_4                    (vl_i_io_uopWriteback_0_bits_uop_exceptionVec_4),
    .io_uopWriteback_0_bits_uop_exceptionVec_5                    (vl_i_io_uopWriteback_0_bits_uop_exceptionVec_5),
    .io_uopWriteback_0_bits_uop_exceptionVec_13                   (vl_i_io_uopWriteback_0_bits_uop_exceptionVec_13),
    .io_uopWriteback_0_bits_uop_exceptionVec_19                   (vl_i_io_uopWriteback_0_bits_uop_exceptionVec_19),
    .io_uopWriteback_0_bits_uop_exceptionVec_21                   (vl_i_io_uopWriteback_0_bits_uop_exceptionVec_21),
    .io_uopWriteback_0_bits_uop_trigger                           (vl_i_io_uopWriteback_0_bits_uop_trigger),
    .io_uopWriteback_0_bits_uop_fuOpType                          (vl_i_io_uopWriteback_0_bits_uop_fuOpType),
    .io_uopWriteback_0_bits_uop_vecWen                            (vl_i_io_uopWriteback_0_bits_uop_vecWen),
    .io_uopWriteback_0_bits_uop_v0Wen                             (vl_i_io_uopWriteback_0_bits_uop_v0Wen),
    .io_uopWriteback_0_bits_uop_vlWen                             (vl_i_io_uopWriteback_0_bits_uop_vlWen),
    .io_uopWriteback_0_bits_uop_flushPipe                         (vl_i_io_uopWriteback_0_bits_uop_flushPipe),
    .io_uopWriteback_0_bits_uop_vpu_vill                          (vl_i_io_uopWriteback_0_bits_uop_vpu_vill),
    .io_uopWriteback_0_bits_uop_vpu_vma                           (vl_i_io_uopWriteback_0_bits_uop_vpu_vma),
    .io_uopWriteback_0_bits_uop_vpu_vta                           (vl_i_io_uopWriteback_0_bits_uop_vpu_vta),
    .io_uopWriteback_0_bits_uop_vpu_vsew                          (vl_i_io_uopWriteback_0_bits_uop_vpu_vsew),
    .io_uopWriteback_0_bits_uop_vpu_vlmul                         (vl_i_io_uopWriteback_0_bits_uop_vpu_vlmul),
    .io_uopWriteback_0_bits_uop_vpu_specVill                      (vl_i_io_uopWriteback_0_bits_uop_vpu_specVill),
    .io_uopWriteback_0_bits_uop_vpu_specVma                       (vl_i_io_uopWriteback_0_bits_uop_vpu_specVma),
    .io_uopWriteback_0_bits_uop_vpu_specVta                       (vl_i_io_uopWriteback_0_bits_uop_vpu_specVta),
    .io_uopWriteback_0_bits_uop_vpu_specVsew                      (vl_i_io_uopWriteback_0_bits_uop_vpu_specVsew),
    .io_uopWriteback_0_bits_uop_vpu_specVlmul                     (vl_i_io_uopWriteback_0_bits_uop_vpu_specVlmul),
    .io_uopWriteback_0_bits_uop_vpu_vm                            (vl_i_io_uopWriteback_0_bits_uop_vpu_vm),
    .io_uopWriteback_0_bits_uop_vpu_vstart                        (vl_i_io_uopWriteback_0_bits_uop_vpu_vstart),
    .io_uopWriteback_0_bits_uop_vpu_frm                           (vl_i_io_uopWriteback_0_bits_uop_vpu_frm),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst             (vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr               (vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr               (vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isReduction               (vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2               (vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4               (vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8               (vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopWriteback_0_bits_uop_vpu_vxrm                          (vl_i_io_uopWriteback_0_bits_uop_vpu_vxrm),
    .io_uopWriteback_0_bits_uop_vpu_vuopIdx                       (vl_i_io_uopWriteback_0_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_0_bits_uop_vpu_lastUop                       (vl_i_io_uopWriteback_0_bits_uop_vpu_lastUop),
    .io_uopWriteback_0_bits_uop_vpu_vmask                         (vl_i_io_uopWriteback_0_bits_uop_vpu_vmask),
    .io_uopWriteback_0_bits_uop_vpu_vl                            (vl_i_io_uopWriteback_0_bits_uop_vpu_vl),
    .io_uopWriteback_0_bits_uop_vpu_nf                            (vl_i_io_uopWriteback_0_bits_uop_vpu_nf),
    .io_uopWriteback_0_bits_uop_vpu_veew                          (vl_i_io_uopWriteback_0_bits_uop_vpu_veew),
    .io_uopWriteback_0_bits_uop_vpu_isReverse                     (vl_i_io_uopWriteback_0_bits_uop_vpu_isReverse),
    .io_uopWriteback_0_bits_uop_vpu_isExt                         (vl_i_io_uopWriteback_0_bits_uop_vpu_isExt),
    .io_uopWriteback_0_bits_uop_vpu_isNarrow                      (vl_i_io_uopWriteback_0_bits_uop_vpu_isNarrow),
    .io_uopWriteback_0_bits_uop_vpu_isDstMask                     (vl_i_io_uopWriteback_0_bits_uop_vpu_isDstMask),
    .io_uopWriteback_0_bits_uop_vpu_isOpMask                      (vl_i_io_uopWriteback_0_bits_uop_vpu_isOpMask),
    .io_uopWriteback_0_bits_uop_vpu_isMove                        (vl_i_io_uopWriteback_0_bits_uop_vpu_isMove),
    .io_uopWriteback_0_bits_uop_vpu_isDependOldVd                 (vl_i_io_uopWriteback_0_bits_uop_vpu_isDependOldVd),
    .io_uopWriteback_0_bits_uop_vpu_isWritePartVd                 (vl_i_io_uopWriteback_0_bits_uop_vpu_isWritePartVd),
    .io_uopWriteback_0_bits_uop_vpu_isVleff                       (vl_i_io_uopWriteback_0_bits_uop_vpu_isVleff),
    .io_uopWriteback_0_bits_uop_psrc_2                            (vl_i_io_uopWriteback_0_bits_uop_psrc_2),
    .io_uopWriteback_0_bits_uop_pdest                             (vl_i_io_uopWriteback_0_bits_uop_pdest),
    .io_uopWriteback_0_bits_uop_robIdx_flag                       (vl_i_io_uopWriteback_0_bits_uop_robIdx_flag),
    .io_uopWriteback_0_bits_uop_robIdx_value                      (vl_i_io_uopWriteback_0_bits_uop_robIdx_value),
    .io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove          (vl_i_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove),
    .io_uopWriteback_0_bits_uop_debugInfo_renameTime              (vl_i_io_uopWriteback_0_bits_uop_debugInfo_renameTime),
    .io_uopWriteback_0_bits_uop_debugInfo_dispatchTime            (vl_i_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime),
    .io_uopWriteback_0_bits_uop_debugInfo_enqRsTime               (vl_i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_0_bits_uop_debugInfo_selectTime              (vl_i_io_uopWriteback_0_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_0_bits_uop_debugInfo_issueTime               (vl_i_io_uopWriteback_0_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_0_bits_uop_debugInfo_writebackTime           (vl_i_io_uopWriteback_0_bits_uop_debugInfo_writebackTime),
    .io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id  (vl_i_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime         (vl_i_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime             (vl_i_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime),
    .io_uopWriteback_0_bits_uop_debug_seqNum_seqNum               (vl_i_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum),
    .io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx               (vl_i_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx),
    .io_uopWriteback_0_bits_uop_replayInst                        (vl_i_io_uopWriteback_0_bits_uop_replayInst),
    .io_uopWriteback_0_bits_data                                  (vl_i_io_uopWriteback_0_bits_data),
    .io_uopWriteback_0_bits_vdIdx                                 (vl_i_io_uopWriteback_0_bits_vdIdx),
    .io_uopWriteback_0_bits_vdIdxInField                          (vl_i_io_uopWriteback_0_bits_vdIdxInField),
    .io_uopWriteback_1_ready                                      (vl_io_uopWriteback_1_ready),
    .io_uopWriteback_1_valid                                      (vl_i_io_uopWriteback_1_valid),
    .io_uopWriteback_1_bits_uop_exceptionVec_3                    (vl_i_io_uopWriteback_1_bits_uop_exceptionVec_3),
    .io_uopWriteback_1_bits_uop_exceptionVec_4                    (vl_i_io_uopWriteback_1_bits_uop_exceptionVec_4),
    .io_uopWriteback_1_bits_uop_exceptionVec_5                    (vl_i_io_uopWriteback_1_bits_uop_exceptionVec_5),
    .io_uopWriteback_1_bits_uop_exceptionVec_13                   (vl_i_io_uopWriteback_1_bits_uop_exceptionVec_13),
    .io_uopWriteback_1_bits_uop_exceptionVec_19                   (vl_i_io_uopWriteback_1_bits_uop_exceptionVec_19),
    .io_uopWriteback_1_bits_uop_exceptionVec_21                   (vl_i_io_uopWriteback_1_bits_uop_exceptionVec_21),
    .io_uopWriteback_1_bits_uop_trigger                           (vl_i_io_uopWriteback_1_bits_uop_trigger),
    .io_uopWriteback_1_bits_uop_fuOpType                          (vl_i_io_uopWriteback_1_bits_uop_fuOpType),
    .io_uopWriteback_1_bits_uop_vecWen                            (vl_i_io_uopWriteback_1_bits_uop_vecWen),
    .io_uopWriteback_1_bits_uop_v0Wen                             (vl_i_io_uopWriteback_1_bits_uop_v0Wen),
    .io_uopWriteback_1_bits_uop_vlWen                             (vl_i_io_uopWriteback_1_bits_uop_vlWen),
    .io_uopWriteback_1_bits_uop_flushPipe                         (vl_i_io_uopWriteback_1_bits_uop_flushPipe),
    .io_uopWriteback_1_bits_uop_vpu_vill                          (vl_i_io_uopWriteback_1_bits_uop_vpu_vill),
    .io_uopWriteback_1_bits_uop_vpu_vma                           (vl_i_io_uopWriteback_1_bits_uop_vpu_vma),
    .io_uopWriteback_1_bits_uop_vpu_vta                           (vl_i_io_uopWriteback_1_bits_uop_vpu_vta),
    .io_uopWriteback_1_bits_uop_vpu_vsew                          (vl_i_io_uopWriteback_1_bits_uop_vpu_vsew),
    .io_uopWriteback_1_bits_uop_vpu_vlmul                         (vl_i_io_uopWriteback_1_bits_uop_vpu_vlmul),
    .io_uopWriteback_1_bits_uop_vpu_specVill                      (vl_i_io_uopWriteback_1_bits_uop_vpu_specVill),
    .io_uopWriteback_1_bits_uop_vpu_specVma                       (vl_i_io_uopWriteback_1_bits_uop_vpu_specVma),
    .io_uopWriteback_1_bits_uop_vpu_specVta                       (vl_i_io_uopWriteback_1_bits_uop_vpu_specVta),
    .io_uopWriteback_1_bits_uop_vpu_specVsew                      (vl_i_io_uopWriteback_1_bits_uop_vpu_specVsew),
    .io_uopWriteback_1_bits_uop_vpu_specVlmul                     (vl_i_io_uopWriteback_1_bits_uop_vpu_specVlmul),
    .io_uopWriteback_1_bits_uop_vpu_vm                            (vl_i_io_uopWriteback_1_bits_uop_vpu_vm),
    .io_uopWriteback_1_bits_uop_vpu_vstart                        (vl_i_io_uopWriteback_1_bits_uop_vpu_vstart),
    .io_uopWriteback_1_bits_uop_vpu_frm                           (vl_i_io_uopWriteback_1_bits_uop_vpu_frm),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst             (vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr               (vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr               (vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isReduction               (vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isReduction),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2               (vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4               (vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8               (vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopWriteback_1_bits_uop_vpu_vxrm                          (vl_i_io_uopWriteback_1_bits_uop_vpu_vxrm),
    .io_uopWriteback_1_bits_uop_vpu_vuopIdx                       (vl_i_io_uopWriteback_1_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_1_bits_uop_vpu_lastUop                       (vl_i_io_uopWriteback_1_bits_uop_vpu_lastUop),
    .io_uopWriteback_1_bits_uop_vpu_vmask                         (vl_i_io_uopWriteback_1_bits_uop_vpu_vmask),
    .io_uopWriteback_1_bits_uop_vpu_vl                            (vl_i_io_uopWriteback_1_bits_uop_vpu_vl),
    .io_uopWriteback_1_bits_uop_vpu_nf                            (vl_i_io_uopWriteback_1_bits_uop_vpu_nf),
    .io_uopWriteback_1_bits_uop_vpu_veew                          (vl_i_io_uopWriteback_1_bits_uop_vpu_veew),
    .io_uopWriteback_1_bits_uop_vpu_isReverse                     (vl_i_io_uopWriteback_1_bits_uop_vpu_isReverse),
    .io_uopWriteback_1_bits_uop_vpu_isExt                         (vl_i_io_uopWriteback_1_bits_uop_vpu_isExt),
    .io_uopWriteback_1_bits_uop_vpu_isNarrow                      (vl_i_io_uopWriteback_1_bits_uop_vpu_isNarrow),
    .io_uopWriteback_1_bits_uop_vpu_isDstMask                     (vl_i_io_uopWriteback_1_bits_uop_vpu_isDstMask),
    .io_uopWriteback_1_bits_uop_vpu_isOpMask                      (vl_i_io_uopWriteback_1_bits_uop_vpu_isOpMask),
    .io_uopWriteback_1_bits_uop_vpu_isMove                        (vl_i_io_uopWriteback_1_bits_uop_vpu_isMove),
    .io_uopWriteback_1_bits_uop_vpu_isDependOldVd                 (vl_i_io_uopWriteback_1_bits_uop_vpu_isDependOldVd),
    .io_uopWriteback_1_bits_uop_vpu_isWritePartVd                 (vl_i_io_uopWriteback_1_bits_uop_vpu_isWritePartVd),
    .io_uopWriteback_1_bits_uop_vpu_isVleff                       (vl_i_io_uopWriteback_1_bits_uop_vpu_isVleff),
    .io_uopWriteback_1_bits_uop_psrc_2                            (vl_i_io_uopWriteback_1_bits_uop_psrc_2),
    .io_uopWriteback_1_bits_uop_pdest                             (vl_i_io_uopWriteback_1_bits_uop_pdest),
    .io_uopWriteback_1_bits_uop_robIdx_flag                       (vl_i_io_uopWriteback_1_bits_uop_robIdx_flag),
    .io_uopWriteback_1_bits_uop_robIdx_value                      (vl_i_io_uopWriteback_1_bits_uop_robIdx_value),
    .io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove          (vl_i_io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove),
    .io_uopWriteback_1_bits_uop_debugInfo_renameTime              (vl_i_io_uopWriteback_1_bits_uop_debugInfo_renameTime),
    .io_uopWriteback_1_bits_uop_debugInfo_dispatchTime            (vl_i_io_uopWriteback_1_bits_uop_debugInfo_dispatchTime),
    .io_uopWriteback_1_bits_uop_debugInfo_enqRsTime               (vl_i_io_uopWriteback_1_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_1_bits_uop_debugInfo_selectTime              (vl_i_io_uopWriteback_1_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_1_bits_uop_debugInfo_issueTime               (vl_i_io_uopWriteback_1_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_1_bits_uop_debugInfo_writebackTime           (vl_i_io_uopWriteback_1_bits_uop_debugInfo_writebackTime),
    .io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id  (vl_i_io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime         (vl_i_io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime             (vl_i_io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime),
    .io_uopWriteback_1_bits_uop_debug_seqNum_seqNum               (vl_i_io_uopWriteback_1_bits_uop_debug_seqNum_seqNum),
    .io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx               (vl_i_io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx),
    .io_uopWriteback_1_bits_uop_replayInst                        (vl_i_io_uopWriteback_1_bits_uop_replayInst),
    .io_uopWriteback_1_bits_data                                  (vl_i_io_uopWriteback_1_bits_data),
    .io_uopWriteback_1_bits_vdIdx                                 (vl_i_io_uopWriteback_1_bits_vdIdx),
    .io_uopWriteback_1_bits_vdIdxInField                          (vl_i_io_uopWriteback_1_bits_vdIdxInField),
    .io_toSplit_threshold                                         (vl_i_io_toSplit_threshold),
    .io_toLsq_0_valid                                             (vl_i_io_toLsq_0_valid),
    .io_toLsq_0_bits_robidx_flag                                  (vl_i_io_toLsq_0_bits_robidx_flag),
    .io_toLsq_0_bits_robidx_value                                 (vl_i_io_toLsq_0_bits_robidx_value),
    .io_toLsq_0_bits_uopidx                                       (vl_i_io_toLsq_0_bits_uopidx),
    .io_toLsq_0_bits_vaddr                                        (vl_i_io_toLsq_0_bits_vaddr),
    .io_toLsq_0_bits_vaNeedExt                                    (vl_i_io_toLsq_0_bits_vaNeedExt),
    .io_toLsq_0_bits_gpaddr                                       (vl_i_io_toLsq_0_bits_gpaddr),
    .io_toLsq_0_bits_isForVSnonLeafPTE                            (vl_i_io_toLsq_0_bits_isForVSnonLeafPTE),
    .io_toLsq_0_bits_feedback_0                                   (vl_i_io_toLsq_0_bits_feedback_0),
    .io_toLsq_0_bits_feedback_1                                   (vl_i_io_toLsq_0_bits_feedback_1),
    .io_toLsq_0_bits_vl                                           (vl_i_io_toLsq_0_bits_vl),
    .io_toLsq_0_bits_exceptionVec_3                               (vl_i_io_toLsq_0_bits_exceptionVec_3),
    .io_toLsq_0_bits_exceptionVec_4                               (vl_i_io_toLsq_0_bits_exceptionVec_4),
    .io_toLsq_0_bits_exceptionVec_5                               (vl_i_io_toLsq_0_bits_exceptionVec_5),
    .io_toLsq_0_bits_exceptionVec_13                              (vl_i_io_toLsq_0_bits_exceptionVec_13),
    .io_toLsq_0_bits_exceptionVec_19                              (vl_i_io_toLsq_0_bits_exceptionVec_19),
    .io_toLsq_0_bits_exceptionVec_21                              (vl_i_io_toLsq_0_bits_exceptionVec_21),
    .io_toLsq_1_valid                                             (vl_i_io_toLsq_1_valid),
    .io_toLsq_1_bits_robidx_flag                                  (vl_i_io_toLsq_1_bits_robidx_flag),
    .io_toLsq_1_bits_robidx_value                                 (vl_i_io_toLsq_1_bits_robidx_value),
    .io_toLsq_1_bits_uopidx                                       (vl_i_io_toLsq_1_bits_uopidx),
    .io_toLsq_1_bits_vaddr                                        (vl_i_io_toLsq_1_bits_vaddr),
    .io_toLsq_1_bits_vaNeedExt                                    (vl_i_io_toLsq_1_bits_vaNeedExt),
    .io_toLsq_1_bits_gpaddr                                       (vl_i_io_toLsq_1_bits_gpaddr),
    .io_toLsq_1_bits_isForVSnonLeafPTE                            (vl_i_io_toLsq_1_bits_isForVSnonLeafPTE),
    .io_toLsq_1_bits_feedback_0                                   (vl_i_io_toLsq_1_bits_feedback_0),
    .io_toLsq_1_bits_feedback_1                                   (vl_i_io_toLsq_1_bits_feedback_1),
    .io_toLsq_1_bits_vl                                           (vl_i_io_toLsq_1_bits_vl),
    .io_toLsq_1_bits_exceptionVec_3                               (vl_i_io_toLsq_1_bits_exceptionVec_3),
    .io_toLsq_1_bits_exceptionVec_4                               (vl_i_io_toLsq_1_bits_exceptionVec_4),
    .io_toLsq_1_bits_exceptionVec_5                               (vl_i_io_toLsq_1_bits_exceptionVec_5),
    .io_toLsq_1_bits_exceptionVec_13                              (vl_i_io_toLsq_1_bits_exceptionVec_13),
    .io_toLsq_1_bits_exceptionVec_19                              (vl_i_io_toLsq_1_bits_exceptionVec_19),
    .io_toLsq_1_bits_exceptionVec_21                              (vl_i_io_toLsq_1_bits_exceptionVec_21),
    .io_feedback_0_valid                                          (vl_i_io_feedback_0_valid),
    .io_feedback_0_bits_robIdx_flag                               (vl_i_io_feedback_0_bits_robIdx_flag),
    .io_feedback_0_bits_robIdx_value                              (vl_i_io_feedback_0_bits_robIdx_value),
    .io_feedback_0_bits_hit                                       (vl_i_io_feedback_0_bits_hit),
    .io_feedback_0_bits_flushState                                (vl_i_io_feedback_0_bits_flushState),
    .io_feedback_0_bits_sourceType                                (vl_i_io_feedback_0_bits_sourceType),
    .io_feedback_0_bits_sqIdx_flag                                (vl_i_io_feedback_0_bits_sqIdx_flag),
    .io_feedback_0_bits_sqIdx_value                               (vl_i_io_feedback_0_bits_sqIdx_value),
    .io_feedback_0_bits_lqIdx_flag                                (vl_i_io_feedback_0_bits_lqIdx_flag),
    .io_feedback_0_bits_lqIdx_value                               (vl_i_io_feedback_0_bits_lqIdx_value),
    .io_feedback_0_bits_isVecPartReplay                           (vl_i_io_feedback_0_bits_isVecPartReplay),
    .io_feedback_0_bits_vecReplayMask                             (vl_i_io_feedback_0_bits_vecReplayMask),
    .io_feedback_0_bits_vecReplayMbIdx                            (vl_i_io_feedback_0_bits_vecReplayMbIdx),
    .io_feedback_1_valid                                          (vl_i_io_feedback_1_valid),
    .io_feedback_1_bits_robIdx_flag                               (vl_i_io_feedback_1_bits_robIdx_flag),
    .io_feedback_1_bits_robIdx_value                              (vl_i_io_feedback_1_bits_robIdx_value),
    .io_feedback_1_bits_hit                                       (vl_i_io_feedback_1_bits_hit),
    .io_feedback_1_bits_flushState                                (vl_i_io_feedback_1_bits_flushState),
    .io_feedback_1_bits_sourceType                                (vl_i_io_feedback_1_bits_sourceType),
    .io_feedback_1_bits_sqIdx_flag                                (vl_i_io_feedback_1_bits_sqIdx_flag),
    .io_feedback_1_bits_sqIdx_value                               (vl_i_io_feedback_1_bits_sqIdx_value),
    .io_feedback_1_bits_lqIdx_flag                                (vl_i_io_feedback_1_bits_lqIdx_flag),
    .io_feedback_1_bits_lqIdx_value                               (vl_i_io_feedback_1_bits_lqIdx_value),
    .io_feedback_1_bits_isVecPartReplay                           (vl_i_io_feedback_1_bits_isVecPartReplay),
    .io_feedback_1_bits_vecReplayMask                             (vl_i_io_feedback_1_bits_vecReplayMask),
    .io_feedback_1_bits_vecReplayMbIdx                            (vl_i_io_feedback_1_bits_vecReplayMbIdx)
  );

  task automatic drive_vl(input int phase);
    if (phase == 3) begin
      vl_io_redirect_valid = ($urandom % 100) < 4;
      vl_io_redirect_bits_robIdx_flag = 1'b0;
      vl_io_redirect_bits_robIdx_value = 8'(96 + $urandom % 16);
      vl_io_redirect_bits_level = 1'($urandom);
      vl_io_fromPipeline_0_valid = ($urandom % 100) < 60;
      vl_io_fromPipeline_0_bits_mBIndex = pick_idx(vl_alloc);
      vl_io_fromPipeline_0_bits_trigger = pick_trigger();
      vl_io_fromPipeline_0_bits_exceptionVec_3 = ($urandom % 100) < 8;
      vl_io_fromPipeline_0_bits_exceptionVec_4 = ($urandom % 100) < 8;
      vl_io_fromPipeline_0_bits_exceptionVec_5 = ($urandom % 100) < 8;
      vl_io_fromPipeline_0_bits_exceptionVec_13 = ($urandom % 100) < 8;
      vl_io_fromPipeline_0_bits_exceptionVec_19 = ($urandom % 100) < 8;
      vl_io_fromPipeline_0_bits_exceptionVec_21 = ($urandom % 100) < 8;
      vl_io_fromPipeline_0_bits_hasException = ($urandom % 100) < 15;
      vl_io_fromPipeline_0_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_0_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_0_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_0_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_0_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_0_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_0_bits_elemIdx = (($urandom % 100) < 80) ? 8'($urandom % 32) : 8'($urandom);
      vl_io_fromPipeline_0_bits_mask = (($urandom % 100) < 20) ? 16'hFFFF : 16'($urandom) & 16'($urandom);
      vl_io_fromPipeline_0_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_0_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_0_bits_elemIdxInsideVd = (($urandom % 100) < 30) ? 8'd0 : 8'($urandom % 16);
      vl_io_fromPipeline_0_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromPipeline_1_valid = ($urandom % 100) < 60;
      vl_io_fromPipeline_1_bits_mBIndex = (($urandom % 100) < 35) ? vl_io_fromPipeline_0_bits_mBIndex : pick_idx(vl_alloc);
      vl_io_fromPipeline_1_bits_trigger = pick_trigger();
      vl_io_fromPipeline_1_bits_exceptionVec_3 = ($urandom % 100) < 8;
      vl_io_fromPipeline_1_bits_exceptionVec_4 = ($urandom % 100) < 8;
      vl_io_fromPipeline_1_bits_exceptionVec_5 = ($urandom % 100) < 8;
      vl_io_fromPipeline_1_bits_exceptionVec_13 = ($urandom % 100) < 8;
      vl_io_fromPipeline_1_bits_exceptionVec_19 = ($urandom % 100) < 8;
      vl_io_fromPipeline_1_bits_exceptionVec_21 = ($urandom % 100) < 8;
      vl_io_fromPipeline_1_bits_hasException = ($urandom % 100) < 15;
      vl_io_fromPipeline_1_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_1_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_1_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_1_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_1_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_1_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_1_bits_elemIdx = (($urandom % 100) < 80) ? 8'($urandom % 32) : 8'($urandom);
      vl_io_fromPipeline_1_bits_mask = (($urandom % 100) < 20) ? 16'hFFFF : 16'($urandom) & 16'($urandom);
      vl_io_fromPipeline_1_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_1_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_1_bits_elemIdxInsideVd = (($urandom % 100) < 30) ? 8'd0 : 8'($urandom % 16);
      vl_io_fromPipeline_1_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromPipeline_2_valid = ($urandom % 100) < 60;
      vl_io_fromPipeline_2_bits_mBIndex = (($urandom % 100) < 35) ? vl_io_fromPipeline_0_bits_mBIndex : pick_idx(vl_alloc);
      vl_io_fromPipeline_2_bits_trigger = pick_trigger();
      vl_io_fromPipeline_2_bits_exceptionVec_3 = ($urandom % 100) < 8;
      vl_io_fromPipeline_2_bits_exceptionVec_4 = ($urandom % 100) < 8;
      vl_io_fromPipeline_2_bits_exceptionVec_5 = ($urandom % 100) < 8;
      vl_io_fromPipeline_2_bits_exceptionVec_13 = ($urandom % 100) < 8;
      vl_io_fromPipeline_2_bits_exceptionVec_19 = ($urandom % 100) < 8;
      vl_io_fromPipeline_2_bits_exceptionVec_21 = ($urandom % 100) < 8;
      vl_io_fromPipeline_2_bits_hasException = ($urandom % 100) < 15;
      vl_io_fromPipeline_2_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_2_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_2_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_2_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_2_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_2_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_2_bits_elemIdx = (($urandom % 100) < 80) ? 8'($urandom % 32) : 8'($urandom);
      vl_io_fromPipeline_2_bits_mask = (($urandom % 100) < 20) ? 16'hFFFF : 16'($urandom) & 16'($urandom);
      vl_io_fromPipeline_2_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_2_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_2_bits_elemIdxInsideVd = (($urandom % 100) < 30) ? 8'd0 : 8'($urandom % 16);
      vl_io_fromPipeline_2_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_0_req_valid = ($urandom % 100) < 50;
      vl_io_fromSplit_0_req_bits_mask = 16'($urandom);
      vl_io_fromSplit_0_req_bits_vaddr = 50'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_flowNum = (($urandom % 100) < 10) ? 5'($urandom) : 5'(1 + $urandom % 4);
      vl_io_fromSplit_0_req_bits_uop_fuOpType = (($urandom % 100) < 40) ? {2'b01, 2'b00, 5'($urandom)} : 9'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vecWen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_v0Wen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vlWen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vill = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vma = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vta = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vsew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vlmul = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVill = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVma = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVta = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVsew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vm = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_frm = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vxrm = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_lastUop = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vl = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_nf = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_veew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isReverse = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isExt = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isMove = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isVleff = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_uopIdx = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_pdest = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_robIdx_flag = ($urandom % 100) < 5;
      vl_io_fromSplit_0_req_bits_uop_robIdx_value = 8'(96 + $urandom % 16);
      vl_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_lqIdx_flag = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_lqIdx_value = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_sqIdx_flag = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_sqIdx_value = 6'($urandom);
      vl_io_fromSplit_0_req_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_0_req_bits_vdIdx = 3'($urandom);
      vl_io_fromSplit_0_req_bits_fof = ($urandom % 100) < 25;
      vl_io_fromSplit_0_req_bits_vlmax = 8'(1 << ($urandom % 8));
      vl_io_fromSplit_1_req_valid = ($urandom % 100) < 50;
      vl_io_fromSplit_1_req_bits_mask = 16'($urandom);
      vl_io_fromSplit_1_req_bits_vaddr = 50'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_flowNum = (($urandom % 100) < 10) ? 5'($urandom) : 5'(1 + $urandom % 4);
      vl_io_fromSplit_1_req_bits_uop_fuOpType = (($urandom % 100) < 40) ? {2'b01, 2'b00, 5'($urandom)} : 9'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vecWen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_v0Wen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vlWen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vill = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vma = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vta = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vsew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vlmul = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVill = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVma = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVta = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVsew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vm = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_frm = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vxrm = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_lastUop = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vl = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_nf = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_veew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isReverse = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isExt = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isMove = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isVleff = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_uopIdx = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_pdest = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_robIdx_flag = ($urandom % 100) < 5;
      vl_io_fromSplit_1_req_bits_uop_robIdx_value = 8'(96 + $urandom % 16);
      vl_io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_lqIdx_flag = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_lqIdx_value = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_sqIdx_flag = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_sqIdx_value = 6'($urandom);
      vl_io_fromSplit_1_req_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_1_req_bits_vdIdx = 3'($urandom);
      vl_io_fromSplit_1_req_bits_fof = ($urandom % 100) < 25;
      vl_io_fromSplit_1_req_bits_vlmax = 8'(1 << ($urandom % 8));
      vl_io_uopWriteback_0_ready = ($urandom % 100) < 70;
      vl_io_uopWriteback_1_ready = ($urandom % 100) < 70;
    end else if (phase == 0) begin
      vl_io_redirect_valid = 1'b0;
      vl_io_redirect_bits_robIdx_flag = 1'b0;
      vl_io_redirect_bits_robIdx_value = 8'd50;
      vl_io_redirect_bits_level = 1'b0;
      vl_io_fromPipeline_0_valid = 1'b0;
      vl_io_fromPipeline_0_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_0_bits_trigger = 4'd15;
      vl_io_fromPipeline_0_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_0_bits_hasException = 1'b1;
      vl_io_fromPipeline_0_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_0_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_0_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_0_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_0_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_0_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_0_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_0_bits_mask = 16'($urandom);
      vl_io_fromPipeline_0_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_0_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_0_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_0_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromPipeline_1_valid = 1'b0;
      vl_io_fromPipeline_1_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_1_bits_trigger = 4'd15;
      vl_io_fromPipeline_1_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_1_bits_hasException = 1'b1;
      vl_io_fromPipeline_1_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_1_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_1_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_1_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_1_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_1_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_1_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_1_bits_mask = 16'($urandom);
      vl_io_fromPipeline_1_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_1_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_1_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_1_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromPipeline_2_valid = 1'b0;
      vl_io_fromPipeline_2_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_2_bits_trigger = 4'd15;
      vl_io_fromPipeline_2_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_2_bits_hasException = 1'b1;
      vl_io_fromPipeline_2_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_2_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_2_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_2_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_2_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_2_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_2_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_2_bits_mask = 16'($urandom);
      vl_io_fromPipeline_2_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_2_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_2_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_2_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_0_req_valid = 1'b1;
      vl_io_fromSplit_0_req_bits_mask = 16'($urandom);
      vl_io_fromSplit_0_req_bits_vaddr = 50'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_flowNum = 5'd31;
      vl_io_fromSplit_0_req_bits_uop_fuOpType = 9'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vecWen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_v0Wen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vlWen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vill = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vma = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vta = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vsew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vlmul = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVill = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVma = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVta = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVsew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vm = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_frm = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vxrm = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_lastUop = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vl = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_nf = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_veew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isReverse = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isExt = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isMove = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isVleff = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_uopIdx = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_pdest = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_robIdx_flag = 1'b0;
      vl_io_fromSplit_0_req_bits_uop_robIdx_value = 8'd100;
      vl_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_lqIdx_flag = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_lqIdx_value = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_sqIdx_flag = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_sqIdx_value = 6'($urandom);
      vl_io_fromSplit_0_req_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_0_req_bits_vdIdx = 3'($urandom);
      vl_io_fromSplit_0_req_bits_fof = 1'b0;
      vl_io_fromSplit_0_req_bits_vlmax = 8'($urandom);
      vl_io_fromSplit_1_req_valid = 1'b1;
      vl_io_fromSplit_1_req_bits_mask = 16'($urandom);
      vl_io_fromSplit_1_req_bits_vaddr = 50'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_flowNum = 5'd31;
      vl_io_fromSplit_1_req_bits_uop_fuOpType = 9'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vecWen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_v0Wen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vlWen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vill = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vma = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vta = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vsew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vlmul = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVill = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVma = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVta = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVsew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vm = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_frm = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vxrm = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_lastUop = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vl = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_nf = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_veew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isReverse = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isExt = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isMove = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isVleff = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_uopIdx = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_pdest = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_robIdx_flag = 1'b0;
      vl_io_fromSplit_1_req_bits_uop_robIdx_value = 8'd100;
      vl_io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_lqIdx_flag = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_lqIdx_value = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_sqIdx_flag = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_sqIdx_value = 6'($urandom);
      vl_io_fromSplit_1_req_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_1_req_bits_vdIdx = 3'($urandom);
      vl_io_fromSplit_1_req_bits_fof = 1'b0;
      vl_io_fromSplit_1_req_bits_vlmax = 8'($urandom);
      vl_io_uopWriteback_0_ready = 1'b1;
      vl_io_uopWriteback_1_ready = 1'b1;
    end else if (phase == 1) begin
      vl_io_redirect_valid = 1'b0;
      vl_io_redirect_bits_robIdx_flag = 1'b0;
      vl_io_redirect_bits_robIdx_value = 8'd50;
      vl_io_redirect_bits_level = 1'b0;
      vl_io_fromPipeline_0_valid = 1'b1;
      vl_io_fromPipeline_0_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_0_bits_trigger = 4'd15;
      vl_io_fromPipeline_0_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_0_bits_hasException = 1'b1;
      vl_io_fromPipeline_0_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_0_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_0_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_0_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_0_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_0_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_0_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_0_bits_mask = 16'($urandom);
      vl_io_fromPipeline_0_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_0_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_0_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_0_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromPipeline_1_valid = 1'b0;
      vl_io_fromPipeline_1_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_1_bits_trigger = 4'd15;
      vl_io_fromPipeline_1_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_1_bits_hasException = 1'b1;
      vl_io_fromPipeline_1_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_1_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_1_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_1_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_1_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_1_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_1_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_1_bits_mask = 16'($urandom);
      vl_io_fromPipeline_1_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_1_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_1_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_1_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromPipeline_2_valid = 1'b0;
      vl_io_fromPipeline_2_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_2_bits_trigger = 4'd15;
      vl_io_fromPipeline_2_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_2_bits_hasException = 1'b1;
      vl_io_fromPipeline_2_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_2_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_2_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_2_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_2_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_2_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_2_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_2_bits_mask = 16'($urandom);
      vl_io_fromPipeline_2_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_2_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_2_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_2_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_0_req_valid = 1'b0;
      vl_io_fromSplit_0_req_bits_mask = 16'($urandom);
      vl_io_fromSplit_0_req_bits_vaddr = 50'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_flowNum = 5'd31;
      vl_io_fromSplit_0_req_bits_uop_fuOpType = 9'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vecWen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_v0Wen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vlWen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vill = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vma = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vta = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vsew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vlmul = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVill = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVma = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVta = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVsew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vm = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_frm = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vxrm = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_lastUop = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vl = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_nf = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_veew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isReverse = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isExt = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isMove = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isVleff = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_uopIdx = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_pdest = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_robIdx_flag = 1'b0;
      vl_io_fromSplit_0_req_bits_uop_robIdx_value = 8'd100;
      vl_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_lqIdx_flag = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_lqIdx_value = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_sqIdx_flag = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_sqIdx_value = 6'($urandom);
      vl_io_fromSplit_0_req_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_0_req_bits_vdIdx = 3'($urandom);
      vl_io_fromSplit_0_req_bits_fof = 1'b0;
      vl_io_fromSplit_0_req_bits_vlmax = 8'($urandom);
      vl_io_fromSplit_1_req_valid = 1'b0;
      vl_io_fromSplit_1_req_bits_mask = 16'($urandom);
      vl_io_fromSplit_1_req_bits_vaddr = 50'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_flowNum = 5'd31;
      vl_io_fromSplit_1_req_bits_uop_fuOpType = 9'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vecWen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_v0Wen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vlWen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vill = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vma = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vta = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vsew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vlmul = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVill = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVma = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVta = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVsew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vm = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_frm = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vxrm = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_lastUop = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vl = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_nf = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_veew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isReverse = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isExt = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isMove = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isVleff = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_uopIdx = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_pdest = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_robIdx_flag = 1'b0;
      vl_io_fromSplit_1_req_bits_uop_robIdx_value = 8'd100;
      vl_io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_lqIdx_flag = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_lqIdx_value = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_sqIdx_flag = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_sqIdx_value = 6'($urandom);
      vl_io_fromSplit_1_req_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_1_req_bits_vdIdx = 3'($urandom);
      vl_io_fromSplit_1_req_bits_fof = 1'b0;
      vl_io_fromSplit_1_req_bits_vlmax = 8'($urandom);
      vl_io_uopWriteback_0_ready = 1'b1;
      vl_io_uopWriteback_1_ready = 1'b1;
    end else if (phase == 2) begin
      vl_io_redirect_valid = 1'b1;
      vl_io_redirect_bits_robIdx_flag = 1'b0;
      vl_io_redirect_bits_robIdx_value = 8'd50;
      vl_io_redirect_bits_level = 1'b0;
      vl_io_fromPipeline_0_valid = 1'b0;
      vl_io_fromPipeline_0_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_0_bits_trigger = 4'd15;
      vl_io_fromPipeline_0_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_0_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_0_bits_hasException = 1'b1;
      vl_io_fromPipeline_0_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_0_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_0_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_0_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_0_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_0_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_0_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_0_bits_mask = 16'($urandom);
      vl_io_fromPipeline_0_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_0_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_0_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_0_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromPipeline_1_valid = 1'b0;
      vl_io_fromPipeline_1_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_1_bits_trigger = 4'd15;
      vl_io_fromPipeline_1_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_1_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_1_bits_hasException = 1'b1;
      vl_io_fromPipeline_1_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_1_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_1_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_1_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_1_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_1_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_1_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_1_bits_mask = 16'($urandom);
      vl_io_fromPipeline_1_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_1_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_1_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_1_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromPipeline_2_valid = 1'b0;
      vl_io_fromPipeline_2_bits_mBIndex = 4'(cycle);
      vl_io_fromPipeline_2_bits_trigger = 4'd15;
      vl_io_fromPipeline_2_bits_exceptionVec_3 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_4 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_5 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_13 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_19 = 1'($urandom);
      vl_io_fromPipeline_2_bits_exceptionVec_21 = 1'($urandom);
      vl_io_fromPipeline_2_bits_hasException = 1'b1;
      vl_io_fromPipeline_2_bits_vaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_2_bits_vaNeedExt = 1'($urandom);
      vl_io_fromPipeline_2_bits_gpaddr = 64'({$urandom, $urandom});
      vl_io_fromPipeline_2_bits_isForVSnonLeafPTE = 1'($urandom);
      vl_io_fromPipeline_2_bits_vstart = 8'($urandom);
      vl_io_fromPipeline_2_bits_vecTriggerMask = 16'($urandom);
      vl_io_fromPipeline_2_bits_elemIdx = 8'd0;
      vl_io_fromPipeline_2_bits_mask = 16'($urandom);
      vl_io_fromPipeline_2_bits_alignedType = 3'($urandom);
      vl_io_fromPipeline_2_bits_reg_offset = 4'($urandom);
      vl_io_fromPipeline_2_bits_elemIdxInsideVd = 8'($urandom);
      vl_io_fromPipeline_2_bits_vecdata = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_0_req_valid = 1'b0;
      vl_io_fromSplit_0_req_bits_mask = 16'($urandom);
      vl_io_fromSplit_0_req_bits_vaddr = 50'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_flowNum = 5'd31;
      vl_io_fromSplit_0_req_bits_uop_fuOpType = 9'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vecWen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_v0Wen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vlWen = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vill = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vma = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vta = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vsew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vlmul = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVill = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVma = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVta = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVsew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vm = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_frm = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vxrm = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_lastUop = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_vl = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_nf = 3'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_veew = 2'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isReverse = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isExt = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isMove = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_vpu_isVleff = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_uopIdx = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_pdest = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_robIdx_flag = 1'b0;
      vl_io_fromSplit_0_req_bits_uop_robIdx_value = 8'd100;
      vl_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vl_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vl_io_fromSplit_0_req_bits_uop_lqIdx_flag = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_lqIdx_value = 7'($urandom);
      vl_io_fromSplit_0_req_bits_uop_sqIdx_flag = 1'($urandom);
      vl_io_fromSplit_0_req_bits_uop_sqIdx_value = 6'($urandom);
      vl_io_fromSplit_0_req_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_0_req_bits_vdIdx = 3'($urandom);
      vl_io_fromSplit_0_req_bits_fof = 1'b0;
      vl_io_fromSplit_0_req_bits_vlmax = 8'($urandom);
      vl_io_fromSplit_1_req_valid = 1'b0;
      vl_io_fromSplit_1_req_bits_mask = 16'($urandom);
      vl_io_fromSplit_1_req_bits_vaddr = 50'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_flowNum = 5'd31;
      vl_io_fromSplit_1_req_bits_uop_fuOpType = 9'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vecWen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_v0Wen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vlWen = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vill = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vma = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vta = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vsew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vlmul = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVill = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVma = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVta = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVsew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vm = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_frm = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vxrm = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_lastUop = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_vl = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_nf = 3'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_veew = 2'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isReverse = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isExt = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isMove = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_vpu_isVleff = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_uopIdx = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_pdest = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_robIdx_flag = 1'b0;
      vl_io_fromSplit_1_req_bits_uop_robIdx_value = 8'd100;
      vl_io_fromSplit_1_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vl_io_fromSplit_1_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vl_io_fromSplit_1_req_bits_uop_lqIdx_flag = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_lqIdx_value = 7'($urandom);
      vl_io_fromSplit_1_req_bits_uop_sqIdx_flag = 1'($urandom);
      vl_io_fromSplit_1_req_bits_uop_sqIdx_value = 6'($urandom);
      vl_io_fromSplit_1_req_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      vl_io_fromSplit_1_req_bits_vdIdx = 3'($urandom);
      vl_io_fromSplit_1_req_bits_fof = 1'b0;
      vl_io_fromSplit_1_req_bits_vlmax = 8'($urandom);
      vl_io_uopWriteback_0_ready = 1'b1;
      vl_io_uopWriteback_1_ready = 1'b1;
    end
  endtask

  task automatic compare_vl();
    if (1'b1) chk("VLMergeBufferImp.io_fromSplit_0_req_ready", vl_g_io_fromSplit_0_req_ready !== vl_i_io_fromSplit_0_req_ready);
    if (1'b1) chk("VLMergeBufferImp.io_fromSplit_0_resp_valid", vl_g_io_fromSplit_0_resp_valid !== vl_i_io_fromSplit_0_resp_valid);
    if (1'b1) chk("VLMergeBufferImp.io_fromSplit_0_resp_bits_mBIndex", vl_g_io_fromSplit_0_resp_bits_mBIndex !== vl_i_io_fromSplit_0_resp_bits_mBIndex);
    if (1'b1) chk("VLMergeBufferImp.io_fromSplit_1_req_ready", vl_g_io_fromSplit_1_req_ready !== vl_i_io_fromSplit_1_req_ready);
    if (1'b1) chk("VLMergeBufferImp.io_fromSplit_1_resp_valid", vl_g_io_fromSplit_1_resp_valid !== vl_i_io_fromSplit_1_resp_valid);
    if (1'b1) chk("VLMergeBufferImp.io_fromSplit_1_resp_bits_mBIndex", vl_g_io_fromSplit_1_resp_bits_mBIndex !== vl_i_io_fromSplit_1_resp_bits_mBIndex);
    if (1'b1) chk("VLMergeBufferImp.io_uopWriteback_0_valid", vl_g_io_uopWriteback_0_valid !== vl_i_io_uopWriteback_0_valid);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_3", vl_g_io_uopWriteback_0_bits_uop_exceptionVec_3 !== vl_i_io_uopWriteback_0_bits_uop_exceptionVec_3);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_4", vl_g_io_uopWriteback_0_bits_uop_exceptionVec_4 !== vl_i_io_uopWriteback_0_bits_uop_exceptionVec_4);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_5", vl_g_io_uopWriteback_0_bits_uop_exceptionVec_5 !== vl_i_io_uopWriteback_0_bits_uop_exceptionVec_5);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_13", vl_g_io_uopWriteback_0_bits_uop_exceptionVec_13 !== vl_i_io_uopWriteback_0_bits_uop_exceptionVec_13);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_19", vl_g_io_uopWriteback_0_bits_uop_exceptionVec_19 !== vl_i_io_uopWriteback_0_bits_uop_exceptionVec_19);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_21", vl_g_io_uopWriteback_0_bits_uop_exceptionVec_21 !== vl_i_io_uopWriteback_0_bits_uop_exceptionVec_21);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_trigger", vl_g_io_uopWriteback_0_bits_uop_trigger !== vl_i_io_uopWriteback_0_bits_uop_trigger);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_fuOpType", vl_g_io_uopWriteback_0_bits_uop_fuOpType !== vl_i_io_uopWriteback_0_bits_uop_fuOpType);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vecWen", vl_g_io_uopWriteback_0_bits_uop_vecWen !== vl_i_io_uopWriteback_0_bits_uop_vecWen);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_v0Wen", vl_g_io_uopWriteback_0_bits_uop_v0Wen !== vl_i_io_uopWriteback_0_bits_uop_v0Wen);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vlWen", vl_g_io_uopWriteback_0_bits_uop_vlWen !== vl_i_io_uopWriteback_0_bits_uop_vlWen);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_flushPipe", vl_g_io_uopWriteback_0_bits_uop_flushPipe !== vl_i_io_uopWriteback_0_bits_uop_flushPipe);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vill", vl_g_io_uopWriteback_0_bits_uop_vpu_vill !== vl_i_io_uopWriteback_0_bits_uop_vpu_vill);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vma", vl_g_io_uopWriteback_0_bits_uop_vpu_vma !== vl_i_io_uopWriteback_0_bits_uop_vpu_vma);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vta", vl_g_io_uopWriteback_0_bits_uop_vpu_vta !== vl_i_io_uopWriteback_0_bits_uop_vpu_vta);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vsew", vl_g_io_uopWriteback_0_bits_uop_vpu_vsew !== vl_i_io_uopWriteback_0_bits_uop_vpu_vsew);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vlmul", vl_g_io_uopWriteback_0_bits_uop_vpu_vlmul !== vl_i_io_uopWriteback_0_bits_uop_vpu_vlmul);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVill", vl_g_io_uopWriteback_0_bits_uop_vpu_specVill !== vl_i_io_uopWriteback_0_bits_uop_vpu_specVill);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVma", vl_g_io_uopWriteback_0_bits_uop_vpu_specVma !== vl_i_io_uopWriteback_0_bits_uop_vpu_specVma);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVta", vl_g_io_uopWriteback_0_bits_uop_vpu_specVta !== vl_i_io_uopWriteback_0_bits_uop_vpu_specVta);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVsew", vl_g_io_uopWriteback_0_bits_uop_vpu_specVsew !== vl_i_io_uopWriteback_0_bits_uop_vpu_specVsew);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVlmul", vl_g_io_uopWriteback_0_bits_uop_vpu_specVlmul !== vl_i_io_uopWriteback_0_bits_uop_vpu_specVlmul);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vm", vl_g_io_uopWriteback_0_bits_uop_vpu_vm !== vl_i_io_uopWriteback_0_bits_uop_vpu_vm);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vstart", vl_g_io_uopWriteback_0_bits_uop_vpu_vstart !== vl_i_io_uopWriteback_0_bits_uop_vpu_vstart);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_frm", vl_g_io_uopWriteback_0_bits_uop_vpu_frm !== vl_i_io_uopWriteback_0_bits_uop_vpu_frm);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst", vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst !== vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr", vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr !== vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr", vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr !== vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isReduction", vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction !== vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2", vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2 !== vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4", vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4 !== vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8", vl_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8 !== vl_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vxrm", vl_g_io_uopWriteback_0_bits_uop_vpu_vxrm !== vl_i_io_uopWriteback_0_bits_uop_vpu_vxrm);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vuopIdx", vl_g_io_uopWriteback_0_bits_uop_vpu_vuopIdx !== vl_i_io_uopWriteback_0_bits_uop_vpu_vuopIdx);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_lastUop", vl_g_io_uopWriteback_0_bits_uop_vpu_lastUop !== vl_i_io_uopWriteback_0_bits_uop_vpu_lastUop);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vmask", vl_g_io_uopWriteback_0_bits_uop_vpu_vmask !== vl_i_io_uopWriteback_0_bits_uop_vpu_vmask);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vl", vl_g_io_uopWriteback_0_bits_uop_vpu_vl !== vl_i_io_uopWriteback_0_bits_uop_vpu_vl);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_nf", vl_g_io_uopWriteback_0_bits_uop_vpu_nf !== vl_i_io_uopWriteback_0_bits_uop_vpu_nf);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_veew", vl_g_io_uopWriteback_0_bits_uop_vpu_veew !== vl_i_io_uopWriteback_0_bits_uop_vpu_veew);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isReverse", vl_g_io_uopWriteback_0_bits_uop_vpu_isReverse !== vl_i_io_uopWriteback_0_bits_uop_vpu_isReverse);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isExt", vl_g_io_uopWriteback_0_bits_uop_vpu_isExt !== vl_i_io_uopWriteback_0_bits_uop_vpu_isExt);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isNarrow", vl_g_io_uopWriteback_0_bits_uop_vpu_isNarrow !== vl_i_io_uopWriteback_0_bits_uop_vpu_isNarrow);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isDstMask", vl_g_io_uopWriteback_0_bits_uop_vpu_isDstMask !== vl_i_io_uopWriteback_0_bits_uop_vpu_isDstMask);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isOpMask", vl_g_io_uopWriteback_0_bits_uop_vpu_isOpMask !== vl_i_io_uopWriteback_0_bits_uop_vpu_isOpMask);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isMove", vl_g_io_uopWriteback_0_bits_uop_vpu_isMove !== vl_i_io_uopWriteback_0_bits_uop_vpu_isMove);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isDependOldVd", vl_g_io_uopWriteback_0_bits_uop_vpu_isDependOldVd !== vl_i_io_uopWriteback_0_bits_uop_vpu_isDependOldVd);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isWritePartVd", vl_g_io_uopWriteback_0_bits_uop_vpu_isWritePartVd !== vl_i_io_uopWriteback_0_bits_uop_vpu_isWritePartVd);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isVleff", vl_g_io_uopWriteback_0_bits_uop_vpu_isVleff !== vl_i_io_uopWriteback_0_bits_uop_vpu_isVleff);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_psrc_2", vl_g_io_uopWriteback_0_bits_uop_psrc_2 !== vl_i_io_uopWriteback_0_bits_uop_psrc_2);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_pdest", vl_g_io_uopWriteback_0_bits_uop_pdest !== vl_i_io_uopWriteback_0_bits_uop_pdest);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_robIdx_flag", vl_g_io_uopWriteback_0_bits_uop_robIdx_flag !== vl_i_io_uopWriteback_0_bits_uop_robIdx_flag);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_robIdx_value", vl_g_io_uopWriteback_0_bits_uop_robIdx_value !== vl_i_io_uopWriteback_0_bits_uop_robIdx_value);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove", vl_g_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_renameTime", vl_g_io_uopWriteback_0_bits_uop_debugInfo_renameTime !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_renameTime);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_dispatchTime", vl_g_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_enqRsTime", vl_g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_selectTime", vl_g_io_uopWriteback_0_bits_uop_debugInfo_selectTime !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_selectTime);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_issueTime", vl_g_io_uopWriteback_0_bits_uop_debugInfo_issueTime !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_issueTime);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_writebackTime", vl_g_io_uopWriteback_0_bits_uop_debugInfo_writebackTime !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_writebackTime);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id", vl_g_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime", vl_g_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime", vl_g_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime !== vl_i_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debug_seqNum_seqNum", vl_g_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum !== vl_i_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx", vl_g_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx !== vl_i_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_uop_replayInst", vl_g_io_uopWriteback_0_bits_uop_replayInst !== vl_i_io_uopWriteback_0_bits_uop_replayInst);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_data", vl_g_io_uopWriteback_0_bits_data !== vl_i_io_uopWriteback_0_bits_data);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_vdIdx", vl_g_io_uopWriteback_0_bits_vdIdx !== vl_i_io_uopWriteback_0_bits_vdIdx);
    if (vl_g_io_uopWriteback_0_valid) chk("VLMergeBufferImp.io_uopWriteback_0_bits_vdIdxInField", vl_g_io_uopWriteback_0_bits_vdIdxInField !== vl_i_io_uopWriteback_0_bits_vdIdxInField);
    if (1'b1) chk("VLMergeBufferImp.io_uopWriteback_1_valid", vl_g_io_uopWriteback_1_valid !== vl_i_io_uopWriteback_1_valid);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_exceptionVec_3", vl_g_io_uopWriteback_1_bits_uop_exceptionVec_3 !== vl_i_io_uopWriteback_1_bits_uop_exceptionVec_3);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_exceptionVec_4", vl_g_io_uopWriteback_1_bits_uop_exceptionVec_4 !== vl_i_io_uopWriteback_1_bits_uop_exceptionVec_4);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_exceptionVec_5", vl_g_io_uopWriteback_1_bits_uop_exceptionVec_5 !== vl_i_io_uopWriteback_1_bits_uop_exceptionVec_5);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_exceptionVec_13", vl_g_io_uopWriteback_1_bits_uop_exceptionVec_13 !== vl_i_io_uopWriteback_1_bits_uop_exceptionVec_13);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_exceptionVec_19", vl_g_io_uopWriteback_1_bits_uop_exceptionVec_19 !== vl_i_io_uopWriteback_1_bits_uop_exceptionVec_19);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_exceptionVec_21", vl_g_io_uopWriteback_1_bits_uop_exceptionVec_21 !== vl_i_io_uopWriteback_1_bits_uop_exceptionVec_21);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_trigger", vl_g_io_uopWriteback_1_bits_uop_trigger !== vl_i_io_uopWriteback_1_bits_uop_trigger);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_fuOpType", vl_g_io_uopWriteback_1_bits_uop_fuOpType !== vl_i_io_uopWriteback_1_bits_uop_fuOpType);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vecWen", vl_g_io_uopWriteback_1_bits_uop_vecWen !== vl_i_io_uopWriteback_1_bits_uop_vecWen);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_v0Wen", vl_g_io_uopWriteback_1_bits_uop_v0Wen !== vl_i_io_uopWriteback_1_bits_uop_v0Wen);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vlWen", vl_g_io_uopWriteback_1_bits_uop_vlWen !== vl_i_io_uopWriteback_1_bits_uop_vlWen);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_flushPipe", vl_g_io_uopWriteback_1_bits_uop_flushPipe !== vl_i_io_uopWriteback_1_bits_uop_flushPipe);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vill", vl_g_io_uopWriteback_1_bits_uop_vpu_vill !== vl_i_io_uopWriteback_1_bits_uop_vpu_vill);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vma", vl_g_io_uopWriteback_1_bits_uop_vpu_vma !== vl_i_io_uopWriteback_1_bits_uop_vpu_vma);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vta", vl_g_io_uopWriteback_1_bits_uop_vpu_vta !== vl_i_io_uopWriteback_1_bits_uop_vpu_vta);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vsew", vl_g_io_uopWriteback_1_bits_uop_vpu_vsew !== vl_i_io_uopWriteback_1_bits_uop_vpu_vsew);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vlmul", vl_g_io_uopWriteback_1_bits_uop_vpu_vlmul !== vl_i_io_uopWriteback_1_bits_uop_vpu_vlmul);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_specVill", vl_g_io_uopWriteback_1_bits_uop_vpu_specVill !== vl_i_io_uopWriteback_1_bits_uop_vpu_specVill);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_specVma", vl_g_io_uopWriteback_1_bits_uop_vpu_specVma !== vl_i_io_uopWriteback_1_bits_uop_vpu_specVma);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_specVta", vl_g_io_uopWriteback_1_bits_uop_vpu_specVta !== vl_i_io_uopWriteback_1_bits_uop_vpu_specVta);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_specVsew", vl_g_io_uopWriteback_1_bits_uop_vpu_specVsew !== vl_i_io_uopWriteback_1_bits_uop_vpu_specVsew);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_specVlmul", vl_g_io_uopWriteback_1_bits_uop_vpu_specVlmul !== vl_i_io_uopWriteback_1_bits_uop_vpu_specVlmul);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vm", vl_g_io_uopWriteback_1_bits_uop_vpu_vm !== vl_i_io_uopWriteback_1_bits_uop_vpu_vm);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vstart", vl_g_io_uopWriteback_1_bits_uop_vpu_vstart !== vl_i_io_uopWriteback_1_bits_uop_vpu_vstart);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_frm", vl_g_io_uopWriteback_1_bits_uop_vpu_frm !== vl_i_io_uopWriteback_1_bits_uop_vpu_frm);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst", vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst !== vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFpToVecInst);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr", vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr !== vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFP32Instr);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr", vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr !== vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFP64Instr);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_fpu_isReduction", vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isReduction !== vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isReduction);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2", vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2 !== vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_2);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4", vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4 !== vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_4);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8", vl_g_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8 !== vl_i_io_uopWriteback_1_bits_uop_vpu_fpu_isFoldTo1_8);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vxrm", vl_g_io_uopWriteback_1_bits_uop_vpu_vxrm !== vl_i_io_uopWriteback_1_bits_uop_vpu_vxrm);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vuopIdx", vl_g_io_uopWriteback_1_bits_uop_vpu_vuopIdx !== vl_i_io_uopWriteback_1_bits_uop_vpu_vuopIdx);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_lastUop", vl_g_io_uopWriteback_1_bits_uop_vpu_lastUop !== vl_i_io_uopWriteback_1_bits_uop_vpu_lastUop);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vmask", vl_g_io_uopWriteback_1_bits_uop_vpu_vmask !== vl_i_io_uopWriteback_1_bits_uop_vpu_vmask);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_vl", vl_g_io_uopWriteback_1_bits_uop_vpu_vl !== vl_i_io_uopWriteback_1_bits_uop_vpu_vl);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_nf", vl_g_io_uopWriteback_1_bits_uop_vpu_nf !== vl_i_io_uopWriteback_1_bits_uop_vpu_nf);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_veew", vl_g_io_uopWriteback_1_bits_uop_vpu_veew !== vl_i_io_uopWriteback_1_bits_uop_vpu_veew);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isReverse", vl_g_io_uopWriteback_1_bits_uop_vpu_isReverse !== vl_i_io_uopWriteback_1_bits_uop_vpu_isReverse);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isExt", vl_g_io_uopWriteback_1_bits_uop_vpu_isExt !== vl_i_io_uopWriteback_1_bits_uop_vpu_isExt);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isNarrow", vl_g_io_uopWriteback_1_bits_uop_vpu_isNarrow !== vl_i_io_uopWriteback_1_bits_uop_vpu_isNarrow);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isDstMask", vl_g_io_uopWriteback_1_bits_uop_vpu_isDstMask !== vl_i_io_uopWriteback_1_bits_uop_vpu_isDstMask);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isOpMask", vl_g_io_uopWriteback_1_bits_uop_vpu_isOpMask !== vl_i_io_uopWriteback_1_bits_uop_vpu_isOpMask);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isMove", vl_g_io_uopWriteback_1_bits_uop_vpu_isMove !== vl_i_io_uopWriteback_1_bits_uop_vpu_isMove);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isDependOldVd", vl_g_io_uopWriteback_1_bits_uop_vpu_isDependOldVd !== vl_i_io_uopWriteback_1_bits_uop_vpu_isDependOldVd);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isWritePartVd", vl_g_io_uopWriteback_1_bits_uop_vpu_isWritePartVd !== vl_i_io_uopWriteback_1_bits_uop_vpu_isWritePartVd);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_vpu_isVleff", vl_g_io_uopWriteback_1_bits_uop_vpu_isVleff !== vl_i_io_uopWriteback_1_bits_uop_vpu_isVleff);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_psrc_2", vl_g_io_uopWriteback_1_bits_uop_psrc_2 !== vl_i_io_uopWriteback_1_bits_uop_psrc_2);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_pdest", vl_g_io_uopWriteback_1_bits_uop_pdest !== vl_i_io_uopWriteback_1_bits_uop_pdest);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_robIdx_flag", vl_g_io_uopWriteback_1_bits_uop_robIdx_flag !== vl_i_io_uopWriteback_1_bits_uop_robIdx_flag);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_robIdx_value", vl_g_io_uopWriteback_1_bits_uop_robIdx_value !== vl_i_io_uopWriteback_1_bits_uop_robIdx_value);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove", vl_g_io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_eliminatedMove);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_renameTime", vl_g_io_uopWriteback_1_bits_uop_debugInfo_renameTime !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_renameTime);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_dispatchTime", vl_g_io_uopWriteback_1_bits_uop_debugInfo_dispatchTime !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_dispatchTime);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_enqRsTime", vl_g_io_uopWriteback_1_bits_uop_debugInfo_enqRsTime !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_enqRsTime);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_selectTime", vl_g_io_uopWriteback_1_bits_uop_debugInfo_selectTime !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_selectTime);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_issueTime", vl_g_io_uopWriteback_1_bits_uop_debugInfo_issueTime !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_issueTime);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_writebackTime", vl_g_io_uopWriteback_1_bits_uop_debugInfo_writebackTime !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_writebackTime);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id", vl_g_io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_runahead_checkpoint_id);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime", vl_g_io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_tlbFirstReqTime);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime", vl_g_io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime !== vl_i_io_uopWriteback_1_bits_uop_debugInfo_tlbRespTime);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debug_seqNum_seqNum", vl_g_io_uopWriteback_1_bits_uop_debug_seqNum_seqNum !== vl_i_io_uopWriteback_1_bits_uop_debug_seqNum_seqNum);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx", vl_g_io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx !== vl_i_io_uopWriteback_1_bits_uop_debug_seqNum_uopIdx);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_uop_replayInst", vl_g_io_uopWriteback_1_bits_uop_replayInst !== vl_i_io_uopWriteback_1_bits_uop_replayInst);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_data", vl_g_io_uopWriteback_1_bits_data !== vl_i_io_uopWriteback_1_bits_data);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_vdIdx", vl_g_io_uopWriteback_1_bits_vdIdx !== vl_i_io_uopWriteback_1_bits_vdIdx);
    if (vl_g_io_uopWriteback_1_valid) chk("VLMergeBufferImp.io_uopWriteback_1_bits_vdIdxInField", vl_g_io_uopWriteback_1_bits_vdIdxInField !== vl_i_io_uopWriteback_1_bits_vdIdxInField);
    if (1'b1) chk("VLMergeBufferImp.io_toSplit_threshold", vl_g_io_toSplit_threshold !== vl_i_io_toSplit_threshold);
    if (1'b1) chk("VLMergeBufferImp.io_toLsq_0_valid", vl_g_io_toLsq_0_valid !== vl_i_io_toLsq_0_valid);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_robidx_flag", vl_g_io_toLsq_0_bits_robidx_flag !== vl_i_io_toLsq_0_bits_robidx_flag);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_robidx_value", vl_g_io_toLsq_0_bits_robidx_value !== vl_i_io_toLsq_0_bits_robidx_value);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_uopidx", vl_g_io_toLsq_0_bits_uopidx !== vl_i_io_toLsq_0_bits_uopidx);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_vaddr", vl_g_io_toLsq_0_bits_vaddr !== vl_i_io_toLsq_0_bits_vaddr);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_vaNeedExt", vl_g_io_toLsq_0_bits_vaNeedExt !== vl_i_io_toLsq_0_bits_vaNeedExt);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_gpaddr", vl_g_io_toLsq_0_bits_gpaddr !== vl_i_io_toLsq_0_bits_gpaddr);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_isForVSnonLeafPTE", vl_g_io_toLsq_0_bits_isForVSnonLeafPTE !== vl_i_io_toLsq_0_bits_isForVSnonLeafPTE);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_feedback_0", vl_g_io_toLsq_0_bits_feedback_0 !== vl_i_io_toLsq_0_bits_feedback_0);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_feedback_1", vl_g_io_toLsq_0_bits_feedback_1 !== vl_i_io_toLsq_0_bits_feedback_1);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_vl", vl_g_io_toLsq_0_bits_vl !== vl_i_io_toLsq_0_bits_vl);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_exceptionVec_3", vl_g_io_toLsq_0_bits_exceptionVec_3 !== vl_i_io_toLsq_0_bits_exceptionVec_3);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_exceptionVec_4", vl_g_io_toLsq_0_bits_exceptionVec_4 !== vl_i_io_toLsq_0_bits_exceptionVec_4);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_exceptionVec_5", vl_g_io_toLsq_0_bits_exceptionVec_5 !== vl_i_io_toLsq_0_bits_exceptionVec_5);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_exceptionVec_13", vl_g_io_toLsq_0_bits_exceptionVec_13 !== vl_i_io_toLsq_0_bits_exceptionVec_13);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_exceptionVec_19", vl_g_io_toLsq_0_bits_exceptionVec_19 !== vl_i_io_toLsq_0_bits_exceptionVec_19);
    if (vl_g_io_toLsq_0_valid) chk("VLMergeBufferImp.io_toLsq_0_bits_exceptionVec_21", vl_g_io_toLsq_0_bits_exceptionVec_21 !== vl_i_io_toLsq_0_bits_exceptionVec_21);
    if (1'b1) chk("VLMergeBufferImp.io_toLsq_1_valid", vl_g_io_toLsq_1_valid !== vl_i_io_toLsq_1_valid);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_robidx_flag", vl_g_io_toLsq_1_bits_robidx_flag !== vl_i_io_toLsq_1_bits_robidx_flag);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_robidx_value", vl_g_io_toLsq_1_bits_robidx_value !== vl_i_io_toLsq_1_bits_robidx_value);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_uopidx", vl_g_io_toLsq_1_bits_uopidx !== vl_i_io_toLsq_1_bits_uopidx);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_vaddr", vl_g_io_toLsq_1_bits_vaddr !== vl_i_io_toLsq_1_bits_vaddr);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_vaNeedExt", vl_g_io_toLsq_1_bits_vaNeedExt !== vl_i_io_toLsq_1_bits_vaNeedExt);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_gpaddr", vl_g_io_toLsq_1_bits_gpaddr !== vl_i_io_toLsq_1_bits_gpaddr);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_isForVSnonLeafPTE", vl_g_io_toLsq_1_bits_isForVSnonLeafPTE !== vl_i_io_toLsq_1_bits_isForVSnonLeafPTE);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_feedback_0", vl_g_io_toLsq_1_bits_feedback_0 !== vl_i_io_toLsq_1_bits_feedback_0);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_feedback_1", vl_g_io_toLsq_1_bits_feedback_1 !== vl_i_io_toLsq_1_bits_feedback_1);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_vl", vl_g_io_toLsq_1_bits_vl !== vl_i_io_toLsq_1_bits_vl);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_exceptionVec_3", vl_g_io_toLsq_1_bits_exceptionVec_3 !== vl_i_io_toLsq_1_bits_exceptionVec_3);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_exceptionVec_4", vl_g_io_toLsq_1_bits_exceptionVec_4 !== vl_i_io_toLsq_1_bits_exceptionVec_4);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_exceptionVec_5", vl_g_io_toLsq_1_bits_exceptionVec_5 !== vl_i_io_toLsq_1_bits_exceptionVec_5);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_exceptionVec_13", vl_g_io_toLsq_1_bits_exceptionVec_13 !== vl_i_io_toLsq_1_bits_exceptionVec_13);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_exceptionVec_19", vl_g_io_toLsq_1_bits_exceptionVec_19 !== vl_i_io_toLsq_1_bits_exceptionVec_19);
    if (vl_g_io_toLsq_1_valid) chk("VLMergeBufferImp.io_toLsq_1_bits_exceptionVec_21", vl_g_io_toLsq_1_bits_exceptionVec_21 !== vl_i_io_toLsq_1_bits_exceptionVec_21);
    if (1'b1) chk("VLMergeBufferImp.io_feedback_0_valid", vl_g_io_feedback_0_valid !== vl_i_io_feedback_0_valid);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_robIdx_flag", vl_g_io_feedback_0_bits_robIdx_flag !== vl_i_io_feedback_0_bits_robIdx_flag);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_robIdx_value", vl_g_io_feedback_0_bits_robIdx_value !== vl_i_io_feedback_0_bits_robIdx_value);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_hit", vl_g_io_feedback_0_bits_hit !== vl_i_io_feedback_0_bits_hit);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_flushState", vl_g_io_feedback_0_bits_flushState !== vl_i_io_feedback_0_bits_flushState);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_sourceType", vl_g_io_feedback_0_bits_sourceType !== vl_i_io_feedback_0_bits_sourceType);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_sqIdx_flag", vl_g_io_feedback_0_bits_sqIdx_flag !== vl_i_io_feedback_0_bits_sqIdx_flag);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_sqIdx_value", vl_g_io_feedback_0_bits_sqIdx_value !== vl_i_io_feedback_0_bits_sqIdx_value);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_lqIdx_flag", vl_g_io_feedback_0_bits_lqIdx_flag !== vl_i_io_feedback_0_bits_lqIdx_flag);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_lqIdx_value", vl_g_io_feedback_0_bits_lqIdx_value !== vl_i_io_feedback_0_bits_lqIdx_value);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_isVecPartReplay", vl_g_io_feedback_0_bits_isVecPartReplay !== vl_i_io_feedback_0_bits_isVecPartReplay);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_vecReplayMask", vl_g_io_feedback_0_bits_vecReplayMask !== vl_i_io_feedback_0_bits_vecReplayMask);
    if (vl_g_io_feedback_0_valid) chk("VLMergeBufferImp.io_feedback_0_bits_vecReplayMbIdx", vl_g_io_feedback_0_bits_vecReplayMbIdx !== vl_i_io_feedback_0_bits_vecReplayMbIdx);
    if (1'b1) chk("VLMergeBufferImp.io_feedback_1_valid", vl_g_io_feedback_1_valid !== vl_i_io_feedback_1_valid);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_robIdx_flag", vl_g_io_feedback_1_bits_robIdx_flag !== vl_i_io_feedback_1_bits_robIdx_flag);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_robIdx_value", vl_g_io_feedback_1_bits_robIdx_value !== vl_i_io_feedback_1_bits_robIdx_value);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_hit", vl_g_io_feedback_1_bits_hit !== vl_i_io_feedback_1_bits_hit);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_flushState", vl_g_io_feedback_1_bits_flushState !== vl_i_io_feedback_1_bits_flushState);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_sourceType", vl_g_io_feedback_1_bits_sourceType !== vl_i_io_feedback_1_bits_sourceType);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_sqIdx_flag", vl_g_io_feedback_1_bits_sqIdx_flag !== vl_i_io_feedback_1_bits_sqIdx_flag);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_sqIdx_value", vl_g_io_feedback_1_bits_sqIdx_value !== vl_i_io_feedback_1_bits_sqIdx_value);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_lqIdx_flag", vl_g_io_feedback_1_bits_lqIdx_flag !== vl_i_io_feedback_1_bits_lqIdx_flag);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_lqIdx_value", vl_g_io_feedback_1_bits_lqIdx_value !== vl_i_io_feedback_1_bits_lqIdx_value);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_isVecPartReplay", vl_g_io_feedback_1_bits_isVecPartReplay !== vl_i_io_feedback_1_bits_isVecPartReplay);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_vecReplayMask", vl_g_io_feedback_1_bits_vecReplayMask !== vl_i_io_feedback_1_bits_vecReplayMask);
    if (vl_g_io_feedback_1_valid) chk("VLMergeBufferImp.io_feedback_1_bits_vecReplayMbIdx", vl_g_io_feedback_1_bits_vecReplayMbIdx !== vl_i_io_feedback_1_bits_vecReplayMbIdx);
    cov_vl[0] += vl_g_io_uopWriteback_0_valid;
    cov_vl[1] += vl_g_io_toLsq_0_valid;
    cov_vl[2] += vl_g_io_feedback_0_valid;
    cov_vl[3] += vl_g_io_feedback_0_valid & vl_g_io_feedback_0_bits_isVecPartReplay;
    cov_vl[4] += vl_g_io_toLsq_0_valid & vl_g_io_toLsq_0_bits_feedback_0;
    cov_vl[0] += vl_g_io_uopWriteback_1_valid;
    cov_vl[1] += vl_g_io_toLsq_1_valid;
    cov_vl[2] += vl_g_io_feedback_1_valid;
    cov_vl[3] += vl_g_io_feedback_1_valid & vl_g_io_feedback_1_bits_isVecPartReplay;
    cov_vl[4] += vl_g_io_toLsq_1_valid & vl_g_io_toLsq_1_bits_feedback_0;
  endtask

  // ---------------- VSMergeBufferImp ----------------
  logic            vs_io_redirect_valid;
  logic            vs_io_redirect_bits_robIdx_flag;
  logic [7:0]      vs_io_redirect_bits_robIdx_value;
  logic            vs_io_redirect_bits_level;
  logic            vs_io_fromPipeline_0_valid;
  logic [3:0]      vs_io_fromPipeline_0_bits_mBIndex;
  logic            vs_io_fromPipeline_0_bits_hit;
  logic [3:0]      vs_io_fromPipeline_0_bits_trigger;
  logic            vs_io_fromPipeline_0_bits_exceptionVec_3;
  logic            vs_io_fromPipeline_0_bits_exceptionVec_6;
  logic            vs_io_fromPipeline_0_bits_exceptionVec_7;
  logic            vs_io_fromPipeline_0_bits_exceptionVec_15;
  logic            vs_io_fromPipeline_0_bits_exceptionVec_19;
  logic            vs_io_fromPipeline_0_bits_exceptionVec_23;
  logic            vs_io_fromPipeline_0_bits_hasException;
  logic [63:0]     vs_io_fromPipeline_0_bits_vaddr;
  logic            vs_io_fromPipeline_0_bits_vaNeedExt;
  logic [63:0]     vs_io_fromPipeline_0_bits_gpaddr;
  logic            vs_io_fromPipeline_0_bits_isForVSnonLeafPTE;
  logic [7:0]      vs_io_fromPipeline_0_bits_vstart;
  logic [7:0]      vs_io_fromPipeline_0_bits_elemIdx;
  logic [15:0]     vs_io_fromPipeline_0_bits_mask;
  logic [4:0]      vs_io_fromPipeline_0_bits_splitIndex;
  logic            vs_g_io_fromSplit_0_req_ready;
  logic            vs_i_io_fromSplit_0_req_ready;
  logic            vs_io_fromSplit_0_req_valid;
  logic [15:0]     vs_io_fromSplit_0_req_bits_mask;
  logic [49:0]     vs_io_fromSplit_0_req_bits_vaddr;
  logic [4:0]      vs_io_fromSplit_0_req_bits_flowNum;
  logic [8:0]      vs_io_fromSplit_0_req_bits_uop_fuOpType;
  logic            vs_io_fromSplit_0_req_bits_uop_vecWen;
  logic            vs_io_fromSplit_0_req_bits_uop_v0Wen;
  logic            vs_io_fromSplit_0_req_bits_uop_vlWen;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_vill;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_vma;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_vta;
  logic [1:0]      vs_io_fromSplit_0_req_bits_uop_vpu_vsew;
  logic [2:0]      vs_io_fromSplit_0_req_bits_uop_vpu_vlmul;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_specVill;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_specVma;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_specVta;
  logic [1:0]      vs_io_fromSplit_0_req_bits_uop_vpu_specVsew;
  logic [2:0]      vs_io_fromSplit_0_req_bits_uop_vpu_specVlmul;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_vm;
  logic [2:0]      vs_io_fromSplit_0_req_bits_uop_vpu_frm;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      vs_io_fromSplit_0_req_bits_uop_vpu_vxrm;
  logic [6:0]      vs_io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_lastUop;
  logic [127:0]    vs_io_fromSplit_0_req_bits_uop_vpu_vmask;
  logic [7:0]      vs_io_fromSplit_0_req_bits_uop_vpu_vl;
  logic [2:0]      vs_io_fromSplit_0_req_bits_uop_vpu_nf;
  logic [1:0]      vs_io_fromSplit_0_req_bits_uop_vpu_veew;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isReverse;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isExt;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isNarrow;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isDstMask;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isOpMask;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isMove;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd;
  logic            vs_io_fromSplit_0_req_bits_uop_vpu_isVleff;
  logic [6:0]      vs_io_fromSplit_0_req_bits_uop_uopIdx;
  logic [7:0]      vs_io_fromSplit_0_req_bits_uop_pdest;
  logic            vs_io_fromSplit_0_req_bits_uop_robIdx_flag;
  logic [7:0]      vs_io_fromSplit_0_req_bits_uop_robIdx_value;
  logic            vs_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_renameTime;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     vs_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx;
  logic            vs_io_fromSplit_0_req_bits_uop_lqIdx_flag;
  logic [6:0]      vs_io_fromSplit_0_req_bits_uop_lqIdx_value;
  logic            vs_io_fromSplit_0_req_bits_uop_sqIdx_flag;
  logic [5:0]      vs_io_fromSplit_0_req_bits_uop_sqIdx_value;
  logic [7:0]      vs_io_fromSplit_0_req_bits_vlmax;
  logic            vs_g_io_fromSplit_0_resp_valid;
  logic            vs_i_io_fromSplit_0_resp_valid;
  logic [3:0]      vs_g_io_fromSplit_0_resp_bits_mBIndex;
  logic [3:0]      vs_i_io_fromSplit_0_resp_bits_mBIndex;
  logic            vs_io_uopWriteback_0_ready;
  logic            vs_g_io_uopWriteback_0_valid;
  logic            vs_i_io_uopWriteback_0_valid;
  logic            vs_g_io_uopWriteback_0_bits_uop_exceptionVec_3;
  logic            vs_i_io_uopWriteback_0_bits_uop_exceptionVec_3;
  logic            vs_g_io_uopWriteback_0_bits_uop_exceptionVec_6;
  logic            vs_i_io_uopWriteback_0_bits_uop_exceptionVec_6;
  logic            vs_g_io_uopWriteback_0_bits_uop_exceptionVec_7;
  logic            vs_i_io_uopWriteback_0_bits_uop_exceptionVec_7;
  logic            vs_g_io_uopWriteback_0_bits_uop_exceptionVec_15;
  logic            vs_i_io_uopWriteback_0_bits_uop_exceptionVec_15;
  logic            vs_g_io_uopWriteback_0_bits_uop_exceptionVec_19;
  logic            vs_i_io_uopWriteback_0_bits_uop_exceptionVec_19;
  logic            vs_g_io_uopWriteback_0_bits_uop_exceptionVec_23;
  logic            vs_i_io_uopWriteback_0_bits_uop_exceptionVec_23;
  logic [3:0]      vs_g_io_uopWriteback_0_bits_uop_trigger;
  logic [3:0]      vs_i_io_uopWriteback_0_bits_uop_trigger;
  logic [8:0]      vs_g_io_uopWriteback_0_bits_uop_fuOpType;
  logic [8:0]      vs_i_io_uopWriteback_0_bits_uop_fuOpType;
  logic            vs_g_io_uopWriteback_0_bits_uop_vecWen;
  logic            vs_i_io_uopWriteback_0_bits_uop_vecWen;
  logic            vs_g_io_uopWriteback_0_bits_uop_v0Wen;
  logic            vs_i_io_uopWriteback_0_bits_uop_v0Wen;
  logic            vs_g_io_uopWriteback_0_bits_uop_vlWen;
  logic            vs_i_io_uopWriteback_0_bits_uop_vlWen;
  logic            vs_g_io_uopWriteback_0_bits_uop_flushPipe;
  logic            vs_i_io_uopWriteback_0_bits_uop_flushPipe;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_vill;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_vill;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_vma;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_vma;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_vta;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_vta;
  logic [1:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_vsew;
  logic [1:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_vsew;
  logic [2:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_vlmul;
  logic [2:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_vlmul;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_specVill;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_specVill;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_specVma;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_specVma;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_specVta;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_specVta;
  logic [1:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_specVsew;
  logic [1:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_specVsew;
  logic [2:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_specVlmul;
  logic [2:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_specVlmul;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_vm;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_vm;
  logic [7:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_vstart;
  logic [7:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_vstart;
  logic [2:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_frm;
  logic [2:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_frm;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_vxrm;
  logic [1:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_vxrm;
  logic [6:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_vuopIdx;
  logic [6:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_vuopIdx;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_lastUop;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_lastUop;
  logic [127:0]    vs_g_io_uopWriteback_0_bits_uop_vpu_vmask;
  logic [127:0]    vs_i_io_uopWriteback_0_bits_uop_vpu_vmask;
  logic [7:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_vl;
  logic [7:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_vl;
  logic [2:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_nf;
  logic [2:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_nf;
  logic [1:0]      vs_g_io_uopWriteback_0_bits_uop_vpu_veew;
  logic [1:0]      vs_i_io_uopWriteback_0_bits_uop_vpu_veew;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isReverse;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isReverse;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isExt;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isExt;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isNarrow;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isNarrow;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isDstMask;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isDstMask;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isOpMask;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isOpMask;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isMove;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isMove;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isDependOldVd;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isDependOldVd;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isWritePartVd;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isWritePartVd;
  logic            vs_g_io_uopWriteback_0_bits_uop_vpu_isVleff;
  logic            vs_i_io_uopWriteback_0_bits_uop_vpu_isVleff;
  logic [7:0]      vs_g_io_uopWriteback_0_bits_uop_psrc_2;
  logic [7:0]      vs_i_io_uopWriteback_0_bits_uop_psrc_2;
  logic [7:0]      vs_g_io_uopWriteback_0_bits_uop_pdest;
  logic [7:0]      vs_i_io_uopWriteback_0_bits_uop_pdest;
  logic            vs_g_io_uopWriteback_0_bits_uop_robIdx_flag;
  logic            vs_i_io_uopWriteback_0_bits_uop_robIdx_flag;
  logic [7:0]      vs_g_io_uopWriteback_0_bits_uop_robIdx_value;
  logic [7:0]      vs_i_io_uopWriteback_0_bits_uop_robIdx_value;
  logic            vs_g_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove;
  logic            vs_i_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_renameTime;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_renameTime;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_selectTime;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_selectTime;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_issueTime;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_issueTime;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_writebackTime;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     vs_g_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime;
  logic [63:0]     vs_i_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     vs_g_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum;
  logic [55:0]     vs_i_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      vs_g_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx;
  logic [7:0]      vs_i_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx;
  logic            vs_g_io_uopWriteback_0_bits_uop_replayInst;
  logic            vs_i_io_uopWriteback_0_bits_uop_replayInst;
  logic [127:0]    vs_g_io_uopWriteback_0_bits_data;
  logic [127:0]    vs_i_io_uopWriteback_0_bits_data;
  logic [2:0]      vs_g_io_uopWriteback_0_bits_vdIdx;
  logic [2:0]      vs_i_io_uopWriteback_0_bits_vdIdx;
  logic [2:0]      vs_g_io_uopWriteback_0_bits_vdIdxInField;
  logic [2:0]      vs_i_io_uopWriteback_0_bits_vdIdxInField;
  logic            vs_g_io_toSplit_threshold;
  logic            vs_i_io_toSplit_threshold;
  logic            vs_g_io_toLsq_0_valid;
  logic            vs_i_io_toLsq_0_valid;
  logic            vs_g_io_toLsq_0_bits_robidx_flag;
  logic            vs_i_io_toLsq_0_bits_robidx_flag;
  logic [7:0]      vs_g_io_toLsq_0_bits_robidx_value;
  logic [7:0]      vs_i_io_toLsq_0_bits_robidx_value;
  logic [6:0]      vs_g_io_toLsq_0_bits_uopidx;
  logic [6:0]      vs_i_io_toLsq_0_bits_uopidx;
  logic [63:0]     vs_g_io_toLsq_0_bits_vaddr;
  logic [63:0]     vs_i_io_toLsq_0_bits_vaddr;
  logic            vs_g_io_toLsq_0_bits_vaNeedExt;
  logic            vs_i_io_toLsq_0_bits_vaNeedExt;
  logic [63:0]     vs_g_io_toLsq_0_bits_gpaddr;
  logic [63:0]     vs_i_io_toLsq_0_bits_gpaddr;
  logic            vs_g_io_toLsq_0_bits_isForVSnonLeafPTE;
  logic            vs_i_io_toLsq_0_bits_isForVSnonLeafPTE;
  logic            vs_g_io_toLsq_0_bits_feedback_0;
  logic            vs_i_io_toLsq_0_bits_feedback_0;
  logic            vs_g_io_toLsq_0_bits_feedback_1;
  logic            vs_i_io_toLsq_0_bits_feedback_1;
  logic            vs_g_io_toLsq_0_bits_exceptionVec_3;
  logic            vs_i_io_toLsq_0_bits_exceptionVec_3;
  logic            vs_g_io_toLsq_0_bits_exceptionVec_6;
  logic            vs_i_io_toLsq_0_bits_exceptionVec_6;
  logic            vs_g_io_toLsq_0_bits_exceptionVec_7;
  logic            vs_i_io_toLsq_0_bits_exceptionVec_7;
  logic            vs_g_io_toLsq_0_bits_exceptionVec_15;
  logic            vs_i_io_toLsq_0_bits_exceptionVec_15;
  logic            vs_g_io_toLsq_0_bits_exceptionVec_19;
  logic            vs_i_io_toLsq_0_bits_exceptionVec_19;
  logic            vs_g_io_toLsq_0_bits_exceptionVec_23;
  logic            vs_i_io_toLsq_0_bits_exceptionVec_23;
  logic            vs_g_io_feedback_0_valid;
  logic            vs_i_io_feedback_0_valid;
  logic            vs_g_io_feedback_0_bits_robIdx_flag;
  logic            vs_i_io_feedback_0_bits_robIdx_flag;
  logic [7:0]      vs_g_io_feedback_0_bits_robIdx_value;
  logic [7:0]      vs_i_io_feedback_0_bits_robIdx_value;
  logic            vs_g_io_feedback_0_bits_hit;
  logic            vs_i_io_feedback_0_bits_hit;
  logic [3:0]      vs_g_io_feedback_0_bits_sourceType;
  logic [3:0]      vs_i_io_feedback_0_bits_sourceType;
  logic            vs_g_io_feedback_0_bits_sqIdx_flag;
  logic            vs_i_io_feedback_0_bits_sqIdx_flag;
  logic [5:0]      vs_g_io_feedback_0_bits_sqIdx_value;
  logic [5:0]      vs_i_io_feedback_0_bits_sqIdx_value;
  logic            vs_g_io_feedback_0_bits_lqIdx_flag;
  logic            vs_i_io_feedback_0_bits_lqIdx_flag;
  logic [6:0]      vs_g_io_feedback_0_bits_lqIdx_value;
  logic [6:0]      vs_i_io_feedback_0_bits_lqIdx_value;
  logic            vs_g_io_feedback_0_bits_isVecPartReplay;
  logic            vs_i_io_feedback_0_bits_isVecPartReplay;
  logic [15:0]     vs_g_io_feedback_0_bits_vecReplayMask;
  logic [15:0]     vs_i_io_feedback_0_bits_vecReplayMask;
  logic [3:0]      vs_g_io_feedback_0_bits_vecReplayMbIdx;
  logic [3:0]      vs_i_io_feedback_0_bits_vecReplayMbIdx;
  longint          cov_vs [5];  // 写回 / toLsq / 反馈 / 部分重放 / 带异常出队
  logic [15:0]     vs_alloc;
  assign vs_alloc = {u_vs_g.allocated_15, u_vs_g.allocated_14, u_vs_g.allocated_13, u_vs_g.allocated_12, u_vs_g.allocated_11, u_vs_g.allocated_10, u_vs_g.allocated_9, u_vs_g.allocated_8, u_vs_g.allocated_7, u_vs_g.allocated_6, u_vs_g.allocated_5, u_vs_g.allocated_4, u_vs_g.allocated_3, u_vs_g.allocated_2, u_vs_g.allocated_1, u_vs_g.allocated_0};
  VSMergeBufferImp u_vs_g (
    .clock                                                        (clock),
    .reset                                                        (reset),
    .io_redirect_valid                                            (vs_io_redirect_valid),
    .io_redirect_bits_robIdx_flag                                 (vs_io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value                                (vs_io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                                       (vs_io_redirect_bits_level),
    .io_fromPipeline_0_valid                                      (vs_io_fromPipeline_0_valid),
    .io_fromPipeline_0_bits_mBIndex                               (vs_io_fromPipeline_0_bits_mBIndex),
    .io_fromPipeline_0_bits_hit                                   (vs_io_fromPipeline_0_bits_hit),
    .io_fromPipeline_0_bits_trigger                               (vs_io_fromPipeline_0_bits_trigger),
    .io_fromPipeline_0_bits_exceptionVec_3                        (vs_io_fromPipeline_0_bits_exceptionVec_3),
    .io_fromPipeline_0_bits_exceptionVec_6                        (vs_io_fromPipeline_0_bits_exceptionVec_6),
    .io_fromPipeline_0_bits_exceptionVec_7                        (vs_io_fromPipeline_0_bits_exceptionVec_7),
    .io_fromPipeline_0_bits_exceptionVec_15                       (vs_io_fromPipeline_0_bits_exceptionVec_15),
    .io_fromPipeline_0_bits_exceptionVec_19                       (vs_io_fromPipeline_0_bits_exceptionVec_19),
    .io_fromPipeline_0_bits_exceptionVec_23                       (vs_io_fromPipeline_0_bits_exceptionVec_23),
    .io_fromPipeline_0_bits_hasException                          (vs_io_fromPipeline_0_bits_hasException),
    .io_fromPipeline_0_bits_vaddr                                 (vs_io_fromPipeline_0_bits_vaddr),
    .io_fromPipeline_0_bits_vaNeedExt                             (vs_io_fromPipeline_0_bits_vaNeedExt),
    .io_fromPipeline_0_bits_gpaddr                                (vs_io_fromPipeline_0_bits_gpaddr),
    .io_fromPipeline_0_bits_isForVSnonLeafPTE                     (vs_io_fromPipeline_0_bits_isForVSnonLeafPTE),
    .io_fromPipeline_0_bits_vstart                                (vs_io_fromPipeline_0_bits_vstart),
    .io_fromPipeline_0_bits_elemIdx                               (vs_io_fromPipeline_0_bits_elemIdx),
    .io_fromPipeline_0_bits_mask                                  (vs_io_fromPipeline_0_bits_mask),
    .io_fromPipeline_0_bits_splitIndex                            (vs_io_fromPipeline_0_bits_splitIndex),
    .io_fromSplit_0_req_ready                                     (vs_g_io_fromSplit_0_req_ready),
    .io_fromSplit_0_req_valid                                     (vs_io_fromSplit_0_req_valid),
    .io_fromSplit_0_req_bits_mask                                 (vs_io_fromSplit_0_req_bits_mask),
    .io_fromSplit_0_req_bits_vaddr                                (vs_io_fromSplit_0_req_bits_vaddr),
    .io_fromSplit_0_req_bits_flowNum                              (vs_io_fromSplit_0_req_bits_flowNum),
    .io_fromSplit_0_req_bits_uop_fuOpType                         (vs_io_fromSplit_0_req_bits_uop_fuOpType),
    .io_fromSplit_0_req_bits_uop_vecWen                           (vs_io_fromSplit_0_req_bits_uop_vecWen),
    .io_fromSplit_0_req_bits_uop_v0Wen                            (vs_io_fromSplit_0_req_bits_uop_v0Wen),
    .io_fromSplit_0_req_bits_uop_vlWen                            (vs_io_fromSplit_0_req_bits_uop_vlWen),
    .io_fromSplit_0_req_bits_uop_vpu_vill                         (vs_io_fromSplit_0_req_bits_uop_vpu_vill),
    .io_fromSplit_0_req_bits_uop_vpu_vma                          (vs_io_fromSplit_0_req_bits_uop_vpu_vma),
    .io_fromSplit_0_req_bits_uop_vpu_vta                          (vs_io_fromSplit_0_req_bits_uop_vpu_vta),
    .io_fromSplit_0_req_bits_uop_vpu_vsew                         (vs_io_fromSplit_0_req_bits_uop_vpu_vsew),
    .io_fromSplit_0_req_bits_uop_vpu_vlmul                        (vs_io_fromSplit_0_req_bits_uop_vpu_vlmul),
    .io_fromSplit_0_req_bits_uop_vpu_specVill                     (vs_io_fromSplit_0_req_bits_uop_vpu_specVill),
    .io_fromSplit_0_req_bits_uop_vpu_specVma                      (vs_io_fromSplit_0_req_bits_uop_vpu_specVma),
    .io_fromSplit_0_req_bits_uop_vpu_specVta                      (vs_io_fromSplit_0_req_bits_uop_vpu_specVta),
    .io_fromSplit_0_req_bits_uop_vpu_specVsew                     (vs_io_fromSplit_0_req_bits_uop_vpu_specVsew),
    .io_fromSplit_0_req_bits_uop_vpu_specVlmul                    (vs_io_fromSplit_0_req_bits_uop_vpu_specVlmul),
    .io_fromSplit_0_req_bits_uop_vpu_vm                           (vs_io_fromSplit_0_req_bits_uop_vpu_vm),
    .io_fromSplit_0_req_bits_uop_vpu_frm                          (vs_io_fromSplit_0_req_bits_uop_vpu_frm),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst            (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_fromSplit_0_req_bits_uop_vpu_vxrm                         (vs_io_fromSplit_0_req_bits_uop_vpu_vxrm),
    .io_fromSplit_0_req_bits_uop_vpu_vuopIdx                      (vs_io_fromSplit_0_req_bits_uop_vpu_vuopIdx),
    .io_fromSplit_0_req_bits_uop_vpu_lastUop                      (vs_io_fromSplit_0_req_bits_uop_vpu_lastUop),
    .io_fromSplit_0_req_bits_uop_vpu_vmask                        (vs_io_fromSplit_0_req_bits_uop_vpu_vmask),
    .io_fromSplit_0_req_bits_uop_vpu_vl                           (vs_io_fromSplit_0_req_bits_uop_vpu_vl),
    .io_fromSplit_0_req_bits_uop_vpu_nf                           (vs_io_fromSplit_0_req_bits_uop_vpu_nf),
    .io_fromSplit_0_req_bits_uop_vpu_veew                         (vs_io_fromSplit_0_req_bits_uop_vpu_veew),
    .io_fromSplit_0_req_bits_uop_vpu_isReverse                    (vs_io_fromSplit_0_req_bits_uop_vpu_isReverse),
    .io_fromSplit_0_req_bits_uop_vpu_isExt                        (vs_io_fromSplit_0_req_bits_uop_vpu_isExt),
    .io_fromSplit_0_req_bits_uop_vpu_isNarrow                     (vs_io_fromSplit_0_req_bits_uop_vpu_isNarrow),
    .io_fromSplit_0_req_bits_uop_vpu_isDstMask                    (vs_io_fromSplit_0_req_bits_uop_vpu_isDstMask),
    .io_fromSplit_0_req_bits_uop_vpu_isOpMask                     (vs_io_fromSplit_0_req_bits_uop_vpu_isOpMask),
    .io_fromSplit_0_req_bits_uop_vpu_isMove                       (vs_io_fromSplit_0_req_bits_uop_vpu_isMove),
    .io_fromSplit_0_req_bits_uop_vpu_isDependOldVd                (vs_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd),
    .io_fromSplit_0_req_bits_uop_vpu_isWritePartVd                (vs_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd),
    .io_fromSplit_0_req_bits_uop_vpu_isVleff                      (vs_io_fromSplit_0_req_bits_uop_vpu_isVleff),
    .io_fromSplit_0_req_bits_uop_uopIdx                           (vs_io_fromSplit_0_req_bits_uop_uopIdx),
    .io_fromSplit_0_req_bits_uop_pdest                            (vs_io_fromSplit_0_req_bits_uop_pdest),
    .io_fromSplit_0_req_bits_uop_robIdx_flag                      (vs_io_fromSplit_0_req_bits_uop_robIdx_flag),
    .io_fromSplit_0_req_bits_uop_robIdx_value                     (vs_io_fromSplit_0_req_bits_uop_robIdx_value),
    .io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove         (vs_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove),
    .io_fromSplit_0_req_bits_uop_debugInfo_renameTime             (vs_io_fromSplit_0_req_bits_uop_debugInfo_renameTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime           (vs_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime              (vs_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_selectTime             (vs_io_fromSplit_0_req_bits_uop_debugInfo_selectTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_issueTime              (vs_io_fromSplit_0_req_bits_uop_debugInfo_issueTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_writebackTime          (vs_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id (vs_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime        (vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime            (vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime),
    .io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum              (vs_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum),
    .io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx              (vs_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx),
    .io_fromSplit_0_req_bits_uop_lqIdx_flag                       (vs_io_fromSplit_0_req_bits_uop_lqIdx_flag),
    .io_fromSplit_0_req_bits_uop_lqIdx_value                      (vs_io_fromSplit_0_req_bits_uop_lqIdx_value),
    .io_fromSplit_0_req_bits_uop_sqIdx_flag                       (vs_io_fromSplit_0_req_bits_uop_sqIdx_flag),
    .io_fromSplit_0_req_bits_uop_sqIdx_value                      (vs_io_fromSplit_0_req_bits_uop_sqIdx_value),
    .io_fromSplit_0_req_bits_vlmax                                (vs_io_fromSplit_0_req_bits_vlmax),
    .io_fromSplit_0_resp_valid                                    (vs_g_io_fromSplit_0_resp_valid),
    .io_fromSplit_0_resp_bits_mBIndex                             (vs_g_io_fromSplit_0_resp_bits_mBIndex),
    .io_uopWriteback_0_ready                                      (vs_io_uopWriteback_0_ready),
    .io_uopWriteback_0_valid                                      (vs_g_io_uopWriteback_0_valid),
    .io_uopWriteback_0_bits_uop_exceptionVec_3                    (vs_g_io_uopWriteback_0_bits_uop_exceptionVec_3),
    .io_uopWriteback_0_bits_uop_exceptionVec_6                    (vs_g_io_uopWriteback_0_bits_uop_exceptionVec_6),
    .io_uopWriteback_0_bits_uop_exceptionVec_7                    (vs_g_io_uopWriteback_0_bits_uop_exceptionVec_7),
    .io_uopWriteback_0_bits_uop_exceptionVec_15                   (vs_g_io_uopWriteback_0_bits_uop_exceptionVec_15),
    .io_uopWriteback_0_bits_uop_exceptionVec_19                   (vs_g_io_uopWriteback_0_bits_uop_exceptionVec_19),
    .io_uopWriteback_0_bits_uop_exceptionVec_23                   (vs_g_io_uopWriteback_0_bits_uop_exceptionVec_23),
    .io_uopWriteback_0_bits_uop_trigger                           (vs_g_io_uopWriteback_0_bits_uop_trigger),
    .io_uopWriteback_0_bits_uop_fuOpType                          (vs_g_io_uopWriteback_0_bits_uop_fuOpType),
    .io_uopWriteback_0_bits_uop_vecWen                            (vs_g_io_uopWriteback_0_bits_uop_vecWen),
    .io_uopWriteback_0_bits_uop_v0Wen                             (vs_g_io_uopWriteback_0_bits_uop_v0Wen),
    .io_uopWriteback_0_bits_uop_vlWen                             (vs_g_io_uopWriteback_0_bits_uop_vlWen),
    .io_uopWriteback_0_bits_uop_flushPipe                         (vs_g_io_uopWriteback_0_bits_uop_flushPipe),
    .io_uopWriteback_0_bits_uop_vpu_vill                          (vs_g_io_uopWriteback_0_bits_uop_vpu_vill),
    .io_uopWriteback_0_bits_uop_vpu_vma                           (vs_g_io_uopWriteback_0_bits_uop_vpu_vma),
    .io_uopWriteback_0_bits_uop_vpu_vta                           (vs_g_io_uopWriteback_0_bits_uop_vpu_vta),
    .io_uopWriteback_0_bits_uop_vpu_vsew                          (vs_g_io_uopWriteback_0_bits_uop_vpu_vsew),
    .io_uopWriteback_0_bits_uop_vpu_vlmul                         (vs_g_io_uopWriteback_0_bits_uop_vpu_vlmul),
    .io_uopWriteback_0_bits_uop_vpu_specVill                      (vs_g_io_uopWriteback_0_bits_uop_vpu_specVill),
    .io_uopWriteback_0_bits_uop_vpu_specVma                       (vs_g_io_uopWriteback_0_bits_uop_vpu_specVma),
    .io_uopWriteback_0_bits_uop_vpu_specVta                       (vs_g_io_uopWriteback_0_bits_uop_vpu_specVta),
    .io_uopWriteback_0_bits_uop_vpu_specVsew                      (vs_g_io_uopWriteback_0_bits_uop_vpu_specVsew),
    .io_uopWriteback_0_bits_uop_vpu_specVlmul                     (vs_g_io_uopWriteback_0_bits_uop_vpu_specVlmul),
    .io_uopWriteback_0_bits_uop_vpu_vm                            (vs_g_io_uopWriteback_0_bits_uop_vpu_vm),
    .io_uopWriteback_0_bits_uop_vpu_vstart                        (vs_g_io_uopWriteback_0_bits_uop_vpu_vstart),
    .io_uopWriteback_0_bits_uop_vpu_frm                           (vs_g_io_uopWriteback_0_bits_uop_vpu_frm),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst             (vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr               (vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr               (vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isReduction               (vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2               (vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4               (vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8               (vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopWriteback_0_bits_uop_vpu_vxrm                          (vs_g_io_uopWriteback_0_bits_uop_vpu_vxrm),
    .io_uopWriteback_0_bits_uop_vpu_vuopIdx                       (vs_g_io_uopWriteback_0_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_0_bits_uop_vpu_lastUop                       (vs_g_io_uopWriteback_0_bits_uop_vpu_lastUop),
    .io_uopWriteback_0_bits_uop_vpu_vmask                         (vs_g_io_uopWriteback_0_bits_uop_vpu_vmask),
    .io_uopWriteback_0_bits_uop_vpu_vl                            (vs_g_io_uopWriteback_0_bits_uop_vpu_vl),
    .io_uopWriteback_0_bits_uop_vpu_nf                            (vs_g_io_uopWriteback_0_bits_uop_vpu_nf),
    .io_uopWriteback_0_bits_uop_vpu_veew                          (vs_g_io_uopWriteback_0_bits_uop_vpu_veew),
    .io_uopWriteback_0_bits_uop_vpu_isReverse                     (vs_g_io_uopWriteback_0_bits_uop_vpu_isReverse),
    .io_uopWriteback_0_bits_uop_vpu_isExt                         (vs_g_io_uopWriteback_0_bits_uop_vpu_isExt),
    .io_uopWriteback_0_bits_uop_vpu_isNarrow                      (vs_g_io_uopWriteback_0_bits_uop_vpu_isNarrow),
    .io_uopWriteback_0_bits_uop_vpu_isDstMask                     (vs_g_io_uopWriteback_0_bits_uop_vpu_isDstMask),
    .io_uopWriteback_0_bits_uop_vpu_isOpMask                      (vs_g_io_uopWriteback_0_bits_uop_vpu_isOpMask),
    .io_uopWriteback_0_bits_uop_vpu_isMove                        (vs_g_io_uopWriteback_0_bits_uop_vpu_isMove),
    .io_uopWriteback_0_bits_uop_vpu_isDependOldVd                 (vs_g_io_uopWriteback_0_bits_uop_vpu_isDependOldVd),
    .io_uopWriteback_0_bits_uop_vpu_isWritePartVd                 (vs_g_io_uopWriteback_0_bits_uop_vpu_isWritePartVd),
    .io_uopWriteback_0_bits_uop_vpu_isVleff                       (vs_g_io_uopWriteback_0_bits_uop_vpu_isVleff),
    .io_uopWriteback_0_bits_uop_psrc_2                            (vs_g_io_uopWriteback_0_bits_uop_psrc_2),
    .io_uopWriteback_0_bits_uop_pdest                             (vs_g_io_uopWriteback_0_bits_uop_pdest),
    .io_uopWriteback_0_bits_uop_robIdx_flag                       (vs_g_io_uopWriteback_0_bits_uop_robIdx_flag),
    .io_uopWriteback_0_bits_uop_robIdx_value                      (vs_g_io_uopWriteback_0_bits_uop_robIdx_value),
    .io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove          (vs_g_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove),
    .io_uopWriteback_0_bits_uop_debugInfo_renameTime              (vs_g_io_uopWriteback_0_bits_uop_debugInfo_renameTime),
    .io_uopWriteback_0_bits_uop_debugInfo_dispatchTime            (vs_g_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime),
    .io_uopWriteback_0_bits_uop_debugInfo_enqRsTime               (vs_g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_0_bits_uop_debugInfo_selectTime              (vs_g_io_uopWriteback_0_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_0_bits_uop_debugInfo_issueTime               (vs_g_io_uopWriteback_0_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_0_bits_uop_debugInfo_writebackTime           (vs_g_io_uopWriteback_0_bits_uop_debugInfo_writebackTime),
    .io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id  (vs_g_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime         (vs_g_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime             (vs_g_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime),
    .io_uopWriteback_0_bits_uop_debug_seqNum_seqNum               (vs_g_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum),
    .io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx               (vs_g_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx),
    .io_uopWriteback_0_bits_uop_replayInst                        (vs_g_io_uopWriteback_0_bits_uop_replayInst),
    .io_uopWriteback_0_bits_data                                  (vs_g_io_uopWriteback_0_bits_data),
    .io_uopWriteback_0_bits_vdIdx                                 (vs_g_io_uopWriteback_0_bits_vdIdx),
    .io_uopWriteback_0_bits_vdIdxInField                          (vs_g_io_uopWriteback_0_bits_vdIdxInField),
    .io_toSplit_threshold                                         (vs_g_io_toSplit_threshold),
    .io_toLsq_0_valid                                             (vs_g_io_toLsq_0_valid),
    .io_toLsq_0_bits_robidx_flag                                  (vs_g_io_toLsq_0_bits_robidx_flag),
    .io_toLsq_0_bits_robidx_value                                 (vs_g_io_toLsq_0_bits_robidx_value),
    .io_toLsq_0_bits_uopidx                                       (vs_g_io_toLsq_0_bits_uopidx),
    .io_toLsq_0_bits_vaddr                                        (vs_g_io_toLsq_0_bits_vaddr),
    .io_toLsq_0_bits_vaNeedExt                                    (vs_g_io_toLsq_0_bits_vaNeedExt),
    .io_toLsq_0_bits_gpaddr                                       (vs_g_io_toLsq_0_bits_gpaddr),
    .io_toLsq_0_bits_isForVSnonLeafPTE                            (vs_g_io_toLsq_0_bits_isForVSnonLeafPTE),
    .io_toLsq_0_bits_feedback_0                                   (vs_g_io_toLsq_0_bits_feedback_0),
    .io_toLsq_0_bits_feedback_1                                   (vs_g_io_toLsq_0_bits_feedback_1),
    .io_toLsq_0_bits_exceptionVec_3                               (vs_g_io_toLsq_0_bits_exceptionVec_3),
    .io_toLsq_0_bits_exceptionVec_6                               (vs_g_io_toLsq_0_bits_exceptionVec_6),
    .io_toLsq_0_bits_exceptionVec_7                               (vs_g_io_toLsq_0_bits_exceptionVec_7),
    .io_toLsq_0_bits_exceptionVec_15                              (vs_g_io_toLsq_0_bits_exceptionVec_15),
    .io_toLsq_0_bits_exceptionVec_19                              (vs_g_io_toLsq_0_bits_exceptionVec_19),
    .io_toLsq_0_bits_exceptionVec_23                              (vs_g_io_toLsq_0_bits_exceptionVec_23),
    .io_feedback_0_valid                                          (vs_g_io_feedback_0_valid),
    .io_feedback_0_bits_robIdx_flag                               (vs_g_io_feedback_0_bits_robIdx_flag),
    .io_feedback_0_bits_robIdx_value                              (vs_g_io_feedback_0_bits_robIdx_value),
    .io_feedback_0_bits_hit                                       (vs_g_io_feedback_0_bits_hit),
    .io_feedback_0_bits_sourceType                                (vs_g_io_feedback_0_bits_sourceType),
    .io_feedback_0_bits_sqIdx_flag                                (vs_g_io_feedback_0_bits_sqIdx_flag),
    .io_feedback_0_bits_sqIdx_value                               (vs_g_io_feedback_0_bits_sqIdx_value),
    .io_feedback_0_bits_lqIdx_flag                                (vs_g_io_feedback_0_bits_lqIdx_flag),
    .io_feedback_0_bits_lqIdx_value                               (vs_g_io_feedback_0_bits_lqIdx_value),
    .io_feedback_0_bits_isVecPartReplay                           (vs_g_io_feedback_0_bits_isVecPartReplay),
    .io_feedback_0_bits_vecReplayMask                             (vs_g_io_feedback_0_bits_vecReplayMask),
    .io_feedback_0_bits_vecReplayMbIdx                            (vs_g_io_feedback_0_bits_vecReplayMbIdx)
  );
  VSMergeBufferImp_xs u_vs_i (
    .clock                                                        (clock),
    .reset                                                        (reset),
    .io_redirect_valid                                            (vs_io_redirect_valid),
    .io_redirect_bits_robIdx_flag                                 (vs_io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value                                (vs_io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                                       (vs_io_redirect_bits_level),
    .io_fromPipeline_0_valid                                      (vs_io_fromPipeline_0_valid),
    .io_fromPipeline_0_bits_mBIndex                               (vs_io_fromPipeline_0_bits_mBIndex),
    .io_fromPipeline_0_bits_hit                                   (vs_io_fromPipeline_0_bits_hit),
    .io_fromPipeline_0_bits_trigger                               (vs_io_fromPipeline_0_bits_trigger),
    .io_fromPipeline_0_bits_exceptionVec_3                        (vs_io_fromPipeline_0_bits_exceptionVec_3),
    .io_fromPipeline_0_bits_exceptionVec_6                        (vs_io_fromPipeline_0_bits_exceptionVec_6),
    .io_fromPipeline_0_bits_exceptionVec_7                        (vs_io_fromPipeline_0_bits_exceptionVec_7),
    .io_fromPipeline_0_bits_exceptionVec_15                       (vs_io_fromPipeline_0_bits_exceptionVec_15),
    .io_fromPipeline_0_bits_exceptionVec_19                       (vs_io_fromPipeline_0_bits_exceptionVec_19),
    .io_fromPipeline_0_bits_exceptionVec_23                       (vs_io_fromPipeline_0_bits_exceptionVec_23),
    .io_fromPipeline_0_bits_hasException                          (vs_io_fromPipeline_0_bits_hasException),
    .io_fromPipeline_0_bits_vaddr                                 (vs_io_fromPipeline_0_bits_vaddr),
    .io_fromPipeline_0_bits_vaNeedExt                             (vs_io_fromPipeline_0_bits_vaNeedExt),
    .io_fromPipeline_0_bits_gpaddr                                (vs_io_fromPipeline_0_bits_gpaddr),
    .io_fromPipeline_0_bits_isForVSnonLeafPTE                     (vs_io_fromPipeline_0_bits_isForVSnonLeafPTE),
    .io_fromPipeline_0_bits_vstart                                (vs_io_fromPipeline_0_bits_vstart),
    .io_fromPipeline_0_bits_elemIdx                               (vs_io_fromPipeline_0_bits_elemIdx),
    .io_fromPipeline_0_bits_mask                                  (vs_io_fromPipeline_0_bits_mask),
    .io_fromPipeline_0_bits_splitIndex                            (vs_io_fromPipeline_0_bits_splitIndex),
    .io_fromSplit_0_req_ready                                     (vs_i_io_fromSplit_0_req_ready),
    .io_fromSplit_0_req_valid                                     (vs_io_fromSplit_0_req_valid),
    .io_fromSplit_0_req_bits_mask                                 (vs_io_fromSplit_0_req_bits_mask),
    .io_fromSplit_0_req_bits_vaddr                                (vs_io_fromSplit_0_req_bits_vaddr),
    .io_fromSplit_0_req_bits_flowNum                              (vs_io_fromSplit_0_req_bits_flowNum),
    .io_fromSplit_0_req_bits_uop_fuOpType                         (vs_io_fromSplit_0_req_bits_uop_fuOpType),
    .io_fromSplit_0_req_bits_uop_vecWen                           (vs_io_fromSplit_0_req_bits_uop_vecWen),
    .io_fromSplit_0_req_bits_uop_v0Wen                            (vs_io_fromSplit_0_req_bits_uop_v0Wen),
    .io_fromSplit_0_req_bits_uop_vlWen                            (vs_io_fromSplit_0_req_bits_uop_vlWen),
    .io_fromSplit_0_req_bits_uop_vpu_vill                         (vs_io_fromSplit_0_req_bits_uop_vpu_vill),
    .io_fromSplit_0_req_bits_uop_vpu_vma                          (vs_io_fromSplit_0_req_bits_uop_vpu_vma),
    .io_fromSplit_0_req_bits_uop_vpu_vta                          (vs_io_fromSplit_0_req_bits_uop_vpu_vta),
    .io_fromSplit_0_req_bits_uop_vpu_vsew                         (vs_io_fromSplit_0_req_bits_uop_vpu_vsew),
    .io_fromSplit_0_req_bits_uop_vpu_vlmul                        (vs_io_fromSplit_0_req_bits_uop_vpu_vlmul),
    .io_fromSplit_0_req_bits_uop_vpu_specVill                     (vs_io_fromSplit_0_req_bits_uop_vpu_specVill),
    .io_fromSplit_0_req_bits_uop_vpu_specVma                      (vs_io_fromSplit_0_req_bits_uop_vpu_specVma),
    .io_fromSplit_0_req_bits_uop_vpu_specVta                      (vs_io_fromSplit_0_req_bits_uop_vpu_specVta),
    .io_fromSplit_0_req_bits_uop_vpu_specVsew                     (vs_io_fromSplit_0_req_bits_uop_vpu_specVsew),
    .io_fromSplit_0_req_bits_uop_vpu_specVlmul                    (vs_io_fromSplit_0_req_bits_uop_vpu_specVlmul),
    .io_fromSplit_0_req_bits_uop_vpu_vm                           (vs_io_fromSplit_0_req_bits_uop_vpu_vm),
    .io_fromSplit_0_req_bits_uop_vpu_frm                          (vs_io_fromSplit_0_req_bits_uop_vpu_frm),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst            (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8              (vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_fromSplit_0_req_bits_uop_vpu_vxrm                         (vs_io_fromSplit_0_req_bits_uop_vpu_vxrm),
    .io_fromSplit_0_req_bits_uop_vpu_vuopIdx                      (vs_io_fromSplit_0_req_bits_uop_vpu_vuopIdx),
    .io_fromSplit_0_req_bits_uop_vpu_lastUop                      (vs_io_fromSplit_0_req_bits_uop_vpu_lastUop),
    .io_fromSplit_0_req_bits_uop_vpu_vmask                        (vs_io_fromSplit_0_req_bits_uop_vpu_vmask),
    .io_fromSplit_0_req_bits_uop_vpu_vl                           (vs_io_fromSplit_0_req_bits_uop_vpu_vl),
    .io_fromSplit_0_req_bits_uop_vpu_nf                           (vs_io_fromSplit_0_req_bits_uop_vpu_nf),
    .io_fromSplit_0_req_bits_uop_vpu_veew                         (vs_io_fromSplit_0_req_bits_uop_vpu_veew),
    .io_fromSplit_0_req_bits_uop_vpu_isReverse                    (vs_io_fromSplit_0_req_bits_uop_vpu_isReverse),
    .io_fromSplit_0_req_bits_uop_vpu_isExt                        (vs_io_fromSplit_0_req_bits_uop_vpu_isExt),
    .io_fromSplit_0_req_bits_uop_vpu_isNarrow                     (vs_io_fromSplit_0_req_bits_uop_vpu_isNarrow),
    .io_fromSplit_0_req_bits_uop_vpu_isDstMask                    (vs_io_fromSplit_0_req_bits_uop_vpu_isDstMask),
    .io_fromSplit_0_req_bits_uop_vpu_isOpMask                     (vs_io_fromSplit_0_req_bits_uop_vpu_isOpMask),
    .io_fromSplit_0_req_bits_uop_vpu_isMove                       (vs_io_fromSplit_0_req_bits_uop_vpu_isMove),
    .io_fromSplit_0_req_bits_uop_vpu_isDependOldVd                (vs_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd),
    .io_fromSplit_0_req_bits_uop_vpu_isWritePartVd                (vs_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd),
    .io_fromSplit_0_req_bits_uop_vpu_isVleff                      (vs_io_fromSplit_0_req_bits_uop_vpu_isVleff),
    .io_fromSplit_0_req_bits_uop_uopIdx                           (vs_io_fromSplit_0_req_bits_uop_uopIdx),
    .io_fromSplit_0_req_bits_uop_pdest                            (vs_io_fromSplit_0_req_bits_uop_pdest),
    .io_fromSplit_0_req_bits_uop_robIdx_flag                      (vs_io_fromSplit_0_req_bits_uop_robIdx_flag),
    .io_fromSplit_0_req_bits_uop_robIdx_value                     (vs_io_fromSplit_0_req_bits_uop_robIdx_value),
    .io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove         (vs_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove),
    .io_fromSplit_0_req_bits_uop_debugInfo_renameTime             (vs_io_fromSplit_0_req_bits_uop_debugInfo_renameTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime           (vs_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime              (vs_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_selectTime             (vs_io_fromSplit_0_req_bits_uop_debugInfo_selectTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_issueTime              (vs_io_fromSplit_0_req_bits_uop_debugInfo_issueTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_writebackTime          (vs_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id (vs_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime        (vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime            (vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime),
    .io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum              (vs_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum),
    .io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx              (vs_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx),
    .io_fromSplit_0_req_bits_uop_lqIdx_flag                       (vs_io_fromSplit_0_req_bits_uop_lqIdx_flag),
    .io_fromSplit_0_req_bits_uop_lqIdx_value                      (vs_io_fromSplit_0_req_bits_uop_lqIdx_value),
    .io_fromSplit_0_req_bits_uop_sqIdx_flag                       (vs_io_fromSplit_0_req_bits_uop_sqIdx_flag),
    .io_fromSplit_0_req_bits_uop_sqIdx_value                      (vs_io_fromSplit_0_req_bits_uop_sqIdx_value),
    .io_fromSplit_0_req_bits_vlmax                                (vs_io_fromSplit_0_req_bits_vlmax),
    .io_fromSplit_0_resp_valid                                    (vs_i_io_fromSplit_0_resp_valid),
    .io_fromSplit_0_resp_bits_mBIndex                             (vs_i_io_fromSplit_0_resp_bits_mBIndex),
    .io_uopWriteback_0_ready                                      (vs_io_uopWriteback_0_ready),
    .io_uopWriteback_0_valid                                      (vs_i_io_uopWriteback_0_valid),
    .io_uopWriteback_0_bits_uop_exceptionVec_3                    (vs_i_io_uopWriteback_0_bits_uop_exceptionVec_3),
    .io_uopWriteback_0_bits_uop_exceptionVec_6                    (vs_i_io_uopWriteback_0_bits_uop_exceptionVec_6),
    .io_uopWriteback_0_bits_uop_exceptionVec_7                    (vs_i_io_uopWriteback_0_bits_uop_exceptionVec_7),
    .io_uopWriteback_0_bits_uop_exceptionVec_15                   (vs_i_io_uopWriteback_0_bits_uop_exceptionVec_15),
    .io_uopWriteback_0_bits_uop_exceptionVec_19                   (vs_i_io_uopWriteback_0_bits_uop_exceptionVec_19),
    .io_uopWriteback_0_bits_uop_exceptionVec_23                   (vs_i_io_uopWriteback_0_bits_uop_exceptionVec_23),
    .io_uopWriteback_0_bits_uop_trigger                           (vs_i_io_uopWriteback_0_bits_uop_trigger),
    .io_uopWriteback_0_bits_uop_fuOpType                          (vs_i_io_uopWriteback_0_bits_uop_fuOpType),
    .io_uopWriteback_0_bits_uop_vecWen                            (vs_i_io_uopWriteback_0_bits_uop_vecWen),
    .io_uopWriteback_0_bits_uop_v0Wen                             (vs_i_io_uopWriteback_0_bits_uop_v0Wen),
    .io_uopWriteback_0_bits_uop_vlWen                             (vs_i_io_uopWriteback_0_bits_uop_vlWen),
    .io_uopWriteback_0_bits_uop_flushPipe                         (vs_i_io_uopWriteback_0_bits_uop_flushPipe),
    .io_uopWriteback_0_bits_uop_vpu_vill                          (vs_i_io_uopWriteback_0_bits_uop_vpu_vill),
    .io_uopWriteback_0_bits_uop_vpu_vma                           (vs_i_io_uopWriteback_0_bits_uop_vpu_vma),
    .io_uopWriteback_0_bits_uop_vpu_vta                           (vs_i_io_uopWriteback_0_bits_uop_vpu_vta),
    .io_uopWriteback_0_bits_uop_vpu_vsew                          (vs_i_io_uopWriteback_0_bits_uop_vpu_vsew),
    .io_uopWriteback_0_bits_uop_vpu_vlmul                         (vs_i_io_uopWriteback_0_bits_uop_vpu_vlmul),
    .io_uopWriteback_0_bits_uop_vpu_specVill                      (vs_i_io_uopWriteback_0_bits_uop_vpu_specVill),
    .io_uopWriteback_0_bits_uop_vpu_specVma                       (vs_i_io_uopWriteback_0_bits_uop_vpu_specVma),
    .io_uopWriteback_0_bits_uop_vpu_specVta                       (vs_i_io_uopWriteback_0_bits_uop_vpu_specVta),
    .io_uopWriteback_0_bits_uop_vpu_specVsew                      (vs_i_io_uopWriteback_0_bits_uop_vpu_specVsew),
    .io_uopWriteback_0_bits_uop_vpu_specVlmul                     (vs_i_io_uopWriteback_0_bits_uop_vpu_specVlmul),
    .io_uopWriteback_0_bits_uop_vpu_vm                            (vs_i_io_uopWriteback_0_bits_uop_vpu_vm),
    .io_uopWriteback_0_bits_uop_vpu_vstart                        (vs_i_io_uopWriteback_0_bits_uop_vpu_vstart),
    .io_uopWriteback_0_bits_uop_vpu_frm                           (vs_i_io_uopWriteback_0_bits_uop_vpu_frm),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst             (vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr               (vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr               (vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isReduction               (vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2               (vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4               (vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8               (vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_uopWriteback_0_bits_uop_vpu_vxrm                          (vs_i_io_uopWriteback_0_bits_uop_vpu_vxrm),
    .io_uopWriteback_0_bits_uop_vpu_vuopIdx                       (vs_i_io_uopWriteback_0_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_0_bits_uop_vpu_lastUop                       (vs_i_io_uopWriteback_0_bits_uop_vpu_lastUop),
    .io_uopWriteback_0_bits_uop_vpu_vmask                         (vs_i_io_uopWriteback_0_bits_uop_vpu_vmask),
    .io_uopWriteback_0_bits_uop_vpu_vl                            (vs_i_io_uopWriteback_0_bits_uop_vpu_vl),
    .io_uopWriteback_0_bits_uop_vpu_nf                            (vs_i_io_uopWriteback_0_bits_uop_vpu_nf),
    .io_uopWriteback_0_bits_uop_vpu_veew                          (vs_i_io_uopWriteback_0_bits_uop_vpu_veew),
    .io_uopWriteback_0_bits_uop_vpu_isReverse                     (vs_i_io_uopWriteback_0_bits_uop_vpu_isReverse),
    .io_uopWriteback_0_bits_uop_vpu_isExt                         (vs_i_io_uopWriteback_0_bits_uop_vpu_isExt),
    .io_uopWriteback_0_bits_uop_vpu_isNarrow                      (vs_i_io_uopWriteback_0_bits_uop_vpu_isNarrow),
    .io_uopWriteback_0_bits_uop_vpu_isDstMask                     (vs_i_io_uopWriteback_0_bits_uop_vpu_isDstMask),
    .io_uopWriteback_0_bits_uop_vpu_isOpMask                      (vs_i_io_uopWriteback_0_bits_uop_vpu_isOpMask),
    .io_uopWriteback_0_bits_uop_vpu_isMove                        (vs_i_io_uopWriteback_0_bits_uop_vpu_isMove),
    .io_uopWriteback_0_bits_uop_vpu_isDependOldVd                 (vs_i_io_uopWriteback_0_bits_uop_vpu_isDependOldVd),
    .io_uopWriteback_0_bits_uop_vpu_isWritePartVd                 (vs_i_io_uopWriteback_0_bits_uop_vpu_isWritePartVd),
    .io_uopWriteback_0_bits_uop_vpu_isVleff                       (vs_i_io_uopWriteback_0_bits_uop_vpu_isVleff),
    .io_uopWriteback_0_bits_uop_psrc_2                            (vs_i_io_uopWriteback_0_bits_uop_psrc_2),
    .io_uopWriteback_0_bits_uop_pdest                             (vs_i_io_uopWriteback_0_bits_uop_pdest),
    .io_uopWriteback_0_bits_uop_robIdx_flag                       (vs_i_io_uopWriteback_0_bits_uop_robIdx_flag),
    .io_uopWriteback_0_bits_uop_robIdx_value                      (vs_i_io_uopWriteback_0_bits_uop_robIdx_value),
    .io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove          (vs_i_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove),
    .io_uopWriteback_0_bits_uop_debugInfo_renameTime              (vs_i_io_uopWriteback_0_bits_uop_debugInfo_renameTime),
    .io_uopWriteback_0_bits_uop_debugInfo_dispatchTime            (vs_i_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime),
    .io_uopWriteback_0_bits_uop_debugInfo_enqRsTime               (vs_i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_0_bits_uop_debugInfo_selectTime              (vs_i_io_uopWriteback_0_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_0_bits_uop_debugInfo_issueTime               (vs_i_io_uopWriteback_0_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_0_bits_uop_debugInfo_writebackTime           (vs_i_io_uopWriteback_0_bits_uop_debugInfo_writebackTime),
    .io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id  (vs_i_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime         (vs_i_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime             (vs_i_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime),
    .io_uopWriteback_0_bits_uop_debug_seqNum_seqNum               (vs_i_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum),
    .io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx               (vs_i_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx),
    .io_uopWriteback_0_bits_uop_replayInst                        (vs_i_io_uopWriteback_0_bits_uop_replayInst),
    .io_uopWriteback_0_bits_data                                  (vs_i_io_uopWriteback_0_bits_data),
    .io_uopWriteback_0_bits_vdIdx                                 (vs_i_io_uopWriteback_0_bits_vdIdx),
    .io_uopWriteback_0_bits_vdIdxInField                          (vs_i_io_uopWriteback_0_bits_vdIdxInField),
    .io_toSplit_threshold                                         (vs_i_io_toSplit_threshold),
    .io_toLsq_0_valid                                             (vs_i_io_toLsq_0_valid),
    .io_toLsq_0_bits_robidx_flag                                  (vs_i_io_toLsq_0_bits_robidx_flag),
    .io_toLsq_0_bits_robidx_value                                 (vs_i_io_toLsq_0_bits_robidx_value),
    .io_toLsq_0_bits_uopidx                                       (vs_i_io_toLsq_0_bits_uopidx),
    .io_toLsq_0_bits_vaddr                                        (vs_i_io_toLsq_0_bits_vaddr),
    .io_toLsq_0_bits_vaNeedExt                                    (vs_i_io_toLsq_0_bits_vaNeedExt),
    .io_toLsq_0_bits_gpaddr                                       (vs_i_io_toLsq_0_bits_gpaddr),
    .io_toLsq_0_bits_isForVSnonLeafPTE                            (vs_i_io_toLsq_0_bits_isForVSnonLeafPTE),
    .io_toLsq_0_bits_feedback_0                                   (vs_i_io_toLsq_0_bits_feedback_0),
    .io_toLsq_0_bits_feedback_1                                   (vs_i_io_toLsq_0_bits_feedback_1),
    .io_toLsq_0_bits_exceptionVec_3                               (vs_i_io_toLsq_0_bits_exceptionVec_3),
    .io_toLsq_0_bits_exceptionVec_6                               (vs_i_io_toLsq_0_bits_exceptionVec_6),
    .io_toLsq_0_bits_exceptionVec_7                               (vs_i_io_toLsq_0_bits_exceptionVec_7),
    .io_toLsq_0_bits_exceptionVec_15                              (vs_i_io_toLsq_0_bits_exceptionVec_15),
    .io_toLsq_0_bits_exceptionVec_19                              (vs_i_io_toLsq_0_bits_exceptionVec_19),
    .io_toLsq_0_bits_exceptionVec_23                              (vs_i_io_toLsq_0_bits_exceptionVec_23),
    .io_feedback_0_valid                                          (vs_i_io_feedback_0_valid),
    .io_feedback_0_bits_robIdx_flag                               (vs_i_io_feedback_0_bits_robIdx_flag),
    .io_feedback_0_bits_robIdx_value                              (vs_i_io_feedback_0_bits_robIdx_value),
    .io_feedback_0_bits_hit                                       (vs_i_io_feedback_0_bits_hit),
    .io_feedback_0_bits_sourceType                                (vs_i_io_feedback_0_bits_sourceType),
    .io_feedback_0_bits_sqIdx_flag                                (vs_i_io_feedback_0_bits_sqIdx_flag),
    .io_feedback_0_bits_sqIdx_value                               (vs_i_io_feedback_0_bits_sqIdx_value),
    .io_feedback_0_bits_lqIdx_flag                                (vs_i_io_feedback_0_bits_lqIdx_flag),
    .io_feedback_0_bits_lqIdx_value                               (vs_i_io_feedback_0_bits_lqIdx_value),
    .io_feedback_0_bits_isVecPartReplay                           (vs_i_io_feedback_0_bits_isVecPartReplay),
    .io_feedback_0_bits_vecReplayMask                             (vs_i_io_feedback_0_bits_vecReplayMask),
    .io_feedback_0_bits_vecReplayMbIdx                            (vs_i_io_feedback_0_bits_vecReplayMbIdx)
  );

  task automatic drive_vs(input int phase);
    if (phase == 3) begin
      vs_io_redirect_valid = ($urandom % 100) < 4;
      vs_io_redirect_bits_robIdx_flag = 1'b0;
      vs_io_redirect_bits_robIdx_value = 8'(96 + $urandom % 16);
      vs_io_redirect_bits_level = 1'($urandom);
      vs_io_fromPipeline_0_valid = ($urandom % 100) < 60;
      vs_io_fromPipeline_0_bits_mBIndex = pick_idx(vs_alloc);
      vs_io_fromPipeline_0_bits_hit = ($urandom % 100) < 80;
      vs_io_fromPipeline_0_bits_trigger = pick_trigger();
      vs_io_fromPipeline_0_bits_exceptionVec_3 = ($urandom % 100) < 8;
      vs_io_fromPipeline_0_bits_exceptionVec_6 = ($urandom % 100) < 8;
      vs_io_fromPipeline_0_bits_exceptionVec_7 = ($urandom % 100) < 8;
      vs_io_fromPipeline_0_bits_exceptionVec_15 = ($urandom % 100) < 8;
      vs_io_fromPipeline_0_bits_exceptionVec_19 = ($urandom % 100) < 8;
      vs_io_fromPipeline_0_bits_exceptionVec_23 = ($urandom % 100) < 8;
      vs_io_fromPipeline_0_bits_hasException = ($urandom % 100) < 15;
      vs_io_fromPipeline_0_bits_vaddr = 64'({$urandom, $urandom});
      vs_io_fromPipeline_0_bits_vaNeedExt = 1'($urandom);
      vs_io_fromPipeline_0_bits_gpaddr = 64'({$urandom, $urandom});
      vs_io_fromPipeline_0_bits_isForVSnonLeafPTE = 1'($urandom);
      vs_io_fromPipeline_0_bits_vstart = 8'($urandom);
      vs_io_fromPipeline_0_bits_elemIdx = (($urandom % 100) < 80) ? 8'($urandom % 32) : 8'($urandom);
      vs_io_fromPipeline_0_bits_mask = (($urandom % 100) < 20) ? 16'hFFFF : 16'($urandom) & 16'($urandom);
      vs_io_fromPipeline_0_bits_splitIndex = 5'($urandom);
      vs_io_fromSplit_0_req_valid = ($urandom % 100) < 50;
      vs_io_fromSplit_0_req_bits_mask = 16'($urandom);
      vs_io_fromSplit_0_req_bits_vaddr = 50'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_flowNum = (($urandom % 100) < 10) ? 5'($urandom) : 5'(1 + $urandom % 4);
      vs_io_fromSplit_0_req_bits_uop_fuOpType = (($urandom % 100) < 40) ? {2'b01, 2'b00, 5'($urandom)} : 9'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vecWen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_v0Wen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vlWen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vill = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vma = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vta = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vsew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vlmul = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVill = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVma = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVta = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVsew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vm = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_frm = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vxrm = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_lastUop = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_vpu_vl = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_nf = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_veew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isReverse = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isExt = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isMove = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isVleff = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_uopIdx = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_pdest = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_robIdx_flag = ($urandom % 100) < 5;
      vs_io_fromSplit_0_req_bits_uop_robIdx_value = 8'(96 + $urandom % 16);
      vs_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_lqIdx_flag = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_lqIdx_value = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_sqIdx_flag = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_sqIdx_value = 6'($urandom);
      vs_io_fromSplit_0_req_bits_vlmax = 8'(1 << ($urandom % 8));
      vs_io_uopWriteback_0_ready = ($urandom % 100) < 70;
    end else if (phase == 0) begin
      vs_io_redirect_valid = 1'b0;
      vs_io_redirect_bits_robIdx_flag = 1'b0;
      vs_io_redirect_bits_robIdx_value = 8'd50;
      vs_io_redirect_bits_level = 1'b0;
      vs_io_fromPipeline_0_valid = 1'b0;
      vs_io_fromPipeline_0_bits_mBIndex = 4'(cycle);
      vs_io_fromPipeline_0_bits_hit = 1'($urandom);
      vs_io_fromPipeline_0_bits_trigger = 4'd15;
      vs_io_fromPipeline_0_bits_exceptionVec_3 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_6 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_7 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_15 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_19 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_23 = 1'($urandom);
      vs_io_fromPipeline_0_bits_hasException = 1'b1;
      vs_io_fromPipeline_0_bits_vaddr = 64'({$urandom, $urandom});
      vs_io_fromPipeline_0_bits_vaNeedExt = 1'($urandom);
      vs_io_fromPipeline_0_bits_gpaddr = 64'({$urandom, $urandom});
      vs_io_fromPipeline_0_bits_isForVSnonLeafPTE = 1'($urandom);
      vs_io_fromPipeline_0_bits_vstart = 8'($urandom);
      vs_io_fromPipeline_0_bits_elemIdx = 8'd0;
      vs_io_fromPipeline_0_bits_mask = 16'($urandom);
      vs_io_fromPipeline_0_bits_splitIndex = 5'($urandom);
      vs_io_fromSplit_0_req_valid = 1'b1;
      vs_io_fromSplit_0_req_bits_mask = 16'($urandom);
      vs_io_fromSplit_0_req_bits_vaddr = 50'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_flowNum = 5'd31;
      vs_io_fromSplit_0_req_bits_uop_fuOpType = 9'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vecWen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_v0Wen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vlWen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vill = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vma = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vta = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vsew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vlmul = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVill = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVma = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVta = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVsew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vm = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_frm = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vxrm = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_lastUop = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_vpu_vl = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_nf = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_veew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isReverse = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isExt = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isMove = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isVleff = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_uopIdx = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_pdest = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_robIdx_flag = 1'b0;
      vs_io_fromSplit_0_req_bits_uop_robIdx_value = 8'd100;
      vs_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_lqIdx_flag = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_lqIdx_value = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_sqIdx_flag = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_sqIdx_value = 6'($urandom);
      vs_io_fromSplit_0_req_bits_vlmax = 8'($urandom);
      vs_io_uopWriteback_0_ready = 1'b1;
    end else if (phase == 1) begin
      vs_io_redirect_valid = 1'b0;
      vs_io_redirect_bits_robIdx_flag = 1'b0;
      vs_io_redirect_bits_robIdx_value = 8'd50;
      vs_io_redirect_bits_level = 1'b0;
      vs_io_fromPipeline_0_valid = 1'b1;
      vs_io_fromPipeline_0_bits_mBIndex = 4'(cycle);
      vs_io_fromPipeline_0_bits_hit = 1'($urandom);
      vs_io_fromPipeline_0_bits_trigger = 4'd15;
      vs_io_fromPipeline_0_bits_exceptionVec_3 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_6 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_7 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_15 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_19 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_23 = 1'($urandom);
      vs_io_fromPipeline_0_bits_hasException = 1'b1;
      vs_io_fromPipeline_0_bits_vaddr = 64'({$urandom, $urandom});
      vs_io_fromPipeline_0_bits_vaNeedExt = 1'($urandom);
      vs_io_fromPipeline_0_bits_gpaddr = 64'({$urandom, $urandom});
      vs_io_fromPipeline_0_bits_isForVSnonLeafPTE = 1'($urandom);
      vs_io_fromPipeline_0_bits_vstart = 8'($urandom);
      vs_io_fromPipeline_0_bits_elemIdx = 8'd0;
      vs_io_fromPipeline_0_bits_mask = 16'($urandom);
      vs_io_fromPipeline_0_bits_splitIndex = 5'($urandom);
      vs_io_fromSplit_0_req_valid = 1'b0;
      vs_io_fromSplit_0_req_bits_mask = 16'($urandom);
      vs_io_fromSplit_0_req_bits_vaddr = 50'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_flowNum = 5'd31;
      vs_io_fromSplit_0_req_bits_uop_fuOpType = 9'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vecWen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_v0Wen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vlWen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vill = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vma = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vta = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vsew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vlmul = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVill = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVma = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVta = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVsew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vm = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_frm = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vxrm = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_lastUop = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_vpu_vl = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_nf = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_veew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isReverse = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isExt = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isMove = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isVleff = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_uopIdx = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_pdest = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_robIdx_flag = 1'b0;
      vs_io_fromSplit_0_req_bits_uop_robIdx_value = 8'd100;
      vs_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_lqIdx_flag = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_lqIdx_value = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_sqIdx_flag = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_sqIdx_value = 6'($urandom);
      vs_io_fromSplit_0_req_bits_vlmax = 8'($urandom);
      vs_io_uopWriteback_0_ready = 1'b1;
    end else if (phase == 2) begin
      vs_io_redirect_valid = 1'b1;
      vs_io_redirect_bits_robIdx_flag = 1'b0;
      vs_io_redirect_bits_robIdx_value = 8'd50;
      vs_io_redirect_bits_level = 1'b0;
      vs_io_fromPipeline_0_valid = 1'b0;
      vs_io_fromPipeline_0_bits_mBIndex = 4'(cycle);
      vs_io_fromPipeline_0_bits_hit = 1'($urandom);
      vs_io_fromPipeline_0_bits_trigger = 4'd15;
      vs_io_fromPipeline_0_bits_exceptionVec_3 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_6 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_7 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_15 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_19 = 1'($urandom);
      vs_io_fromPipeline_0_bits_exceptionVec_23 = 1'($urandom);
      vs_io_fromPipeline_0_bits_hasException = 1'b1;
      vs_io_fromPipeline_0_bits_vaddr = 64'({$urandom, $urandom});
      vs_io_fromPipeline_0_bits_vaNeedExt = 1'($urandom);
      vs_io_fromPipeline_0_bits_gpaddr = 64'({$urandom, $urandom});
      vs_io_fromPipeline_0_bits_isForVSnonLeafPTE = 1'($urandom);
      vs_io_fromPipeline_0_bits_vstart = 8'($urandom);
      vs_io_fromPipeline_0_bits_elemIdx = 8'd0;
      vs_io_fromPipeline_0_bits_mask = 16'($urandom);
      vs_io_fromPipeline_0_bits_splitIndex = 5'($urandom);
      vs_io_fromSplit_0_req_valid = 1'b0;
      vs_io_fromSplit_0_req_bits_mask = 16'($urandom);
      vs_io_fromSplit_0_req_bits_vaddr = 50'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_flowNum = 5'd31;
      vs_io_fromSplit_0_req_bits_uop_fuOpType = 9'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vecWen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_v0Wen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vlWen = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vill = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vma = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vta = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vsew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vlmul = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVill = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVma = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVta = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVsew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_specVlmul = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vm = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_frm = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vxrm = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_lastUop = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_vpu_vl = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_nf = 3'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_veew = 2'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isReverse = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isExt = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isNarrow = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isDstMask = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isOpMask = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isMove = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isDependOldVd = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isWritePartVd = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_vpu_isVleff = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_uopIdx = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_pdest = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_robIdx_flag = 1'b0;
      vs_io_fromSplit_0_req_bits_uop_robIdx_value = 8'd100;
      vs_io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      vs_io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      vs_io_fromSplit_0_req_bits_uop_lqIdx_flag = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_lqIdx_value = 7'($urandom);
      vs_io_fromSplit_0_req_bits_uop_sqIdx_flag = 1'($urandom);
      vs_io_fromSplit_0_req_bits_uop_sqIdx_value = 6'($urandom);
      vs_io_fromSplit_0_req_bits_vlmax = 8'($urandom);
      vs_io_uopWriteback_0_ready = 1'b1;
    end
  endtask

  task automatic compare_vs();
    if (1'b1) chk("VSMergeBufferImp.io_fromSplit_0_req_ready", vs_g_io_fromSplit_0_req_ready !== vs_i_io_fromSplit_0_req_ready);
    if (1'b1) chk("VSMergeBufferImp.io_fromSplit_0_resp_valid", vs_g_io_fromSplit_0_resp_valid !== vs_i_io_fromSplit_0_resp_valid);
    if (1'b1) chk("VSMergeBufferImp.io_fromSplit_0_resp_bits_mBIndex", vs_g_io_fromSplit_0_resp_bits_mBIndex !== vs_i_io_fromSplit_0_resp_bits_mBIndex);
    if (1'b1) chk("VSMergeBufferImp.io_uopWriteback_0_valid", vs_g_io_uopWriteback_0_valid !== vs_i_io_uopWriteback_0_valid);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_3", vs_g_io_uopWriteback_0_bits_uop_exceptionVec_3 !== vs_i_io_uopWriteback_0_bits_uop_exceptionVec_3);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_6", vs_g_io_uopWriteback_0_bits_uop_exceptionVec_6 !== vs_i_io_uopWriteback_0_bits_uop_exceptionVec_6);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_7", vs_g_io_uopWriteback_0_bits_uop_exceptionVec_7 !== vs_i_io_uopWriteback_0_bits_uop_exceptionVec_7);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_15", vs_g_io_uopWriteback_0_bits_uop_exceptionVec_15 !== vs_i_io_uopWriteback_0_bits_uop_exceptionVec_15);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_19", vs_g_io_uopWriteback_0_bits_uop_exceptionVec_19 !== vs_i_io_uopWriteback_0_bits_uop_exceptionVec_19);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_exceptionVec_23", vs_g_io_uopWriteback_0_bits_uop_exceptionVec_23 !== vs_i_io_uopWriteback_0_bits_uop_exceptionVec_23);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_trigger", vs_g_io_uopWriteback_0_bits_uop_trigger !== vs_i_io_uopWriteback_0_bits_uop_trigger);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_fuOpType", vs_g_io_uopWriteback_0_bits_uop_fuOpType !== vs_i_io_uopWriteback_0_bits_uop_fuOpType);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vecWen", vs_g_io_uopWriteback_0_bits_uop_vecWen !== vs_i_io_uopWriteback_0_bits_uop_vecWen);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_v0Wen", vs_g_io_uopWriteback_0_bits_uop_v0Wen !== vs_i_io_uopWriteback_0_bits_uop_v0Wen);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vlWen", vs_g_io_uopWriteback_0_bits_uop_vlWen !== vs_i_io_uopWriteback_0_bits_uop_vlWen);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_flushPipe", vs_g_io_uopWriteback_0_bits_uop_flushPipe !== vs_i_io_uopWriteback_0_bits_uop_flushPipe);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vill", vs_g_io_uopWriteback_0_bits_uop_vpu_vill !== vs_i_io_uopWriteback_0_bits_uop_vpu_vill);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vma", vs_g_io_uopWriteback_0_bits_uop_vpu_vma !== vs_i_io_uopWriteback_0_bits_uop_vpu_vma);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vta", vs_g_io_uopWriteback_0_bits_uop_vpu_vta !== vs_i_io_uopWriteback_0_bits_uop_vpu_vta);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vsew", vs_g_io_uopWriteback_0_bits_uop_vpu_vsew !== vs_i_io_uopWriteback_0_bits_uop_vpu_vsew);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vlmul", vs_g_io_uopWriteback_0_bits_uop_vpu_vlmul !== vs_i_io_uopWriteback_0_bits_uop_vpu_vlmul);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVill", vs_g_io_uopWriteback_0_bits_uop_vpu_specVill !== vs_i_io_uopWriteback_0_bits_uop_vpu_specVill);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVma", vs_g_io_uopWriteback_0_bits_uop_vpu_specVma !== vs_i_io_uopWriteback_0_bits_uop_vpu_specVma);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVta", vs_g_io_uopWriteback_0_bits_uop_vpu_specVta !== vs_i_io_uopWriteback_0_bits_uop_vpu_specVta);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVsew", vs_g_io_uopWriteback_0_bits_uop_vpu_specVsew !== vs_i_io_uopWriteback_0_bits_uop_vpu_specVsew);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_specVlmul", vs_g_io_uopWriteback_0_bits_uop_vpu_specVlmul !== vs_i_io_uopWriteback_0_bits_uop_vpu_specVlmul);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vm", vs_g_io_uopWriteback_0_bits_uop_vpu_vm !== vs_i_io_uopWriteback_0_bits_uop_vpu_vm);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vstart", vs_g_io_uopWriteback_0_bits_uop_vpu_vstart !== vs_i_io_uopWriteback_0_bits_uop_vpu_vstart);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_frm", vs_g_io_uopWriteback_0_bits_uop_vpu_frm !== vs_i_io_uopWriteback_0_bits_uop_vpu_frm);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst", vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst !== vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr", vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr !== vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr", vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr !== vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isReduction", vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction !== vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isReduction);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2", vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2 !== vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4", vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4 !== vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8", vs_g_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8 !== vs_i_io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vxrm", vs_g_io_uopWriteback_0_bits_uop_vpu_vxrm !== vs_i_io_uopWriteback_0_bits_uop_vpu_vxrm);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vuopIdx", vs_g_io_uopWriteback_0_bits_uop_vpu_vuopIdx !== vs_i_io_uopWriteback_0_bits_uop_vpu_vuopIdx);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_lastUop", vs_g_io_uopWriteback_0_bits_uop_vpu_lastUop !== vs_i_io_uopWriteback_0_bits_uop_vpu_lastUop);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vmask", vs_g_io_uopWriteback_0_bits_uop_vpu_vmask !== vs_i_io_uopWriteback_0_bits_uop_vpu_vmask);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_vl", vs_g_io_uopWriteback_0_bits_uop_vpu_vl !== vs_i_io_uopWriteback_0_bits_uop_vpu_vl);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_nf", vs_g_io_uopWriteback_0_bits_uop_vpu_nf !== vs_i_io_uopWriteback_0_bits_uop_vpu_nf);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_veew", vs_g_io_uopWriteback_0_bits_uop_vpu_veew !== vs_i_io_uopWriteback_0_bits_uop_vpu_veew);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isReverse", vs_g_io_uopWriteback_0_bits_uop_vpu_isReverse !== vs_i_io_uopWriteback_0_bits_uop_vpu_isReverse);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isExt", vs_g_io_uopWriteback_0_bits_uop_vpu_isExt !== vs_i_io_uopWriteback_0_bits_uop_vpu_isExt);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isNarrow", vs_g_io_uopWriteback_0_bits_uop_vpu_isNarrow !== vs_i_io_uopWriteback_0_bits_uop_vpu_isNarrow);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isDstMask", vs_g_io_uopWriteback_0_bits_uop_vpu_isDstMask !== vs_i_io_uopWriteback_0_bits_uop_vpu_isDstMask);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isOpMask", vs_g_io_uopWriteback_0_bits_uop_vpu_isOpMask !== vs_i_io_uopWriteback_0_bits_uop_vpu_isOpMask);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isMove", vs_g_io_uopWriteback_0_bits_uop_vpu_isMove !== vs_i_io_uopWriteback_0_bits_uop_vpu_isMove);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isDependOldVd", vs_g_io_uopWriteback_0_bits_uop_vpu_isDependOldVd !== vs_i_io_uopWriteback_0_bits_uop_vpu_isDependOldVd);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isWritePartVd", vs_g_io_uopWriteback_0_bits_uop_vpu_isWritePartVd !== vs_i_io_uopWriteback_0_bits_uop_vpu_isWritePartVd);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_vpu_isVleff", vs_g_io_uopWriteback_0_bits_uop_vpu_isVleff !== vs_i_io_uopWriteback_0_bits_uop_vpu_isVleff);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_psrc_2", vs_g_io_uopWriteback_0_bits_uop_psrc_2 !== vs_i_io_uopWriteback_0_bits_uop_psrc_2);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_pdest", vs_g_io_uopWriteback_0_bits_uop_pdest !== vs_i_io_uopWriteback_0_bits_uop_pdest);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_robIdx_flag", vs_g_io_uopWriteback_0_bits_uop_robIdx_flag !== vs_i_io_uopWriteback_0_bits_uop_robIdx_flag);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_robIdx_value", vs_g_io_uopWriteback_0_bits_uop_robIdx_value !== vs_i_io_uopWriteback_0_bits_uop_robIdx_value);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove", vs_g_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_renameTime", vs_g_io_uopWriteback_0_bits_uop_debugInfo_renameTime !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_renameTime);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_dispatchTime", vs_g_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_dispatchTime);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_enqRsTime", vs_g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_selectTime", vs_g_io_uopWriteback_0_bits_uop_debugInfo_selectTime !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_selectTime);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_issueTime", vs_g_io_uopWriteback_0_bits_uop_debugInfo_issueTime !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_issueTime);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_writebackTime", vs_g_io_uopWriteback_0_bits_uop_debugInfo_writebackTime !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_writebackTime);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id", vs_g_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime", vs_g_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime", vs_g_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime !== vs_i_io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debug_seqNum_seqNum", vs_g_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum !== vs_i_io_uopWriteback_0_bits_uop_debug_seqNum_seqNum);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx", vs_g_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx !== vs_i_io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_uop_replayInst", vs_g_io_uopWriteback_0_bits_uop_replayInst !== vs_i_io_uopWriteback_0_bits_uop_replayInst);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_data", vs_g_io_uopWriteback_0_bits_data !== vs_i_io_uopWriteback_0_bits_data);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_vdIdx", vs_g_io_uopWriteback_0_bits_vdIdx !== vs_i_io_uopWriteback_0_bits_vdIdx);
    if (vs_g_io_uopWriteback_0_valid) chk("VSMergeBufferImp.io_uopWriteback_0_bits_vdIdxInField", vs_g_io_uopWriteback_0_bits_vdIdxInField !== vs_i_io_uopWriteback_0_bits_vdIdxInField);
    if (1'b1) chk("VSMergeBufferImp.io_toSplit_threshold", vs_g_io_toSplit_threshold !== vs_i_io_toSplit_threshold);
    if (1'b1) chk("VSMergeBufferImp.io_toLsq_0_valid", vs_g_io_toLsq_0_valid !== vs_i_io_toLsq_0_valid);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_robidx_flag", vs_g_io_toLsq_0_bits_robidx_flag !== vs_i_io_toLsq_0_bits_robidx_flag);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_robidx_value", vs_g_io_toLsq_0_bits_robidx_value !== vs_i_io_toLsq_0_bits_robidx_value);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_uopidx", vs_g_io_toLsq_0_bits_uopidx !== vs_i_io_toLsq_0_bits_uopidx);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_vaddr", vs_g_io_toLsq_0_bits_vaddr !== vs_i_io_toLsq_0_bits_vaddr);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_vaNeedExt", vs_g_io_toLsq_0_bits_vaNeedExt !== vs_i_io_toLsq_0_bits_vaNeedExt);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_gpaddr", vs_g_io_toLsq_0_bits_gpaddr !== vs_i_io_toLsq_0_bits_gpaddr);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_isForVSnonLeafPTE", vs_g_io_toLsq_0_bits_isForVSnonLeafPTE !== vs_i_io_toLsq_0_bits_isForVSnonLeafPTE);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_feedback_0", vs_g_io_toLsq_0_bits_feedback_0 !== vs_i_io_toLsq_0_bits_feedback_0);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_feedback_1", vs_g_io_toLsq_0_bits_feedback_1 !== vs_i_io_toLsq_0_bits_feedback_1);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_exceptionVec_3", vs_g_io_toLsq_0_bits_exceptionVec_3 !== vs_i_io_toLsq_0_bits_exceptionVec_3);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_exceptionVec_6", vs_g_io_toLsq_0_bits_exceptionVec_6 !== vs_i_io_toLsq_0_bits_exceptionVec_6);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_exceptionVec_7", vs_g_io_toLsq_0_bits_exceptionVec_7 !== vs_i_io_toLsq_0_bits_exceptionVec_7);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_exceptionVec_15", vs_g_io_toLsq_0_bits_exceptionVec_15 !== vs_i_io_toLsq_0_bits_exceptionVec_15);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_exceptionVec_19", vs_g_io_toLsq_0_bits_exceptionVec_19 !== vs_i_io_toLsq_0_bits_exceptionVec_19);
    if (vs_g_io_toLsq_0_valid) chk("VSMergeBufferImp.io_toLsq_0_bits_exceptionVec_23", vs_g_io_toLsq_0_bits_exceptionVec_23 !== vs_i_io_toLsq_0_bits_exceptionVec_23);
    if (1'b1) chk("VSMergeBufferImp.io_feedback_0_valid", vs_g_io_feedback_0_valid !== vs_i_io_feedback_0_valid);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_robIdx_flag", vs_g_io_feedback_0_bits_robIdx_flag !== vs_i_io_feedback_0_bits_robIdx_flag);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_robIdx_value", vs_g_io_feedback_0_bits_robIdx_value !== vs_i_io_feedback_0_bits_robIdx_value);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_hit", vs_g_io_feedback_0_bits_hit !== vs_i_io_feedback_0_bits_hit);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_sourceType", vs_g_io_feedback_0_bits_sourceType !== vs_i_io_feedback_0_bits_sourceType);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_sqIdx_flag", vs_g_io_feedback_0_bits_sqIdx_flag !== vs_i_io_feedback_0_bits_sqIdx_flag);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_sqIdx_value", vs_g_io_feedback_0_bits_sqIdx_value !== vs_i_io_feedback_0_bits_sqIdx_value);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_lqIdx_flag", vs_g_io_feedback_0_bits_lqIdx_flag !== vs_i_io_feedback_0_bits_lqIdx_flag);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_lqIdx_value", vs_g_io_feedback_0_bits_lqIdx_value !== vs_i_io_feedback_0_bits_lqIdx_value);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_isVecPartReplay", vs_g_io_feedback_0_bits_isVecPartReplay !== vs_i_io_feedback_0_bits_isVecPartReplay);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_vecReplayMask", vs_g_io_feedback_0_bits_vecReplayMask !== vs_i_io_feedback_0_bits_vecReplayMask);
    if (vs_g_io_feedback_0_valid) chk("VSMergeBufferImp.io_feedback_0_bits_vecReplayMbIdx", vs_g_io_feedback_0_bits_vecReplayMbIdx !== vs_i_io_feedback_0_bits_vecReplayMbIdx);
    cov_vs[0] += vs_g_io_uopWriteback_0_valid;
    cov_vs[1] += vs_g_io_toLsq_0_valid;
    cov_vs[2] += vs_g_io_feedback_0_valid;
    cov_vs[3] += vs_g_io_feedback_0_valid & vs_g_io_feedback_0_bits_isVecPartReplay;
    cov_vs[4] += vs_g_io_toLsq_0_valid & vs_g_io_toLsq_0_bits_feedback_0;
  endtask

  initial begin
    int phase;
    if ($value$plusargs("ncycles=%d", ncycles)) ;
    phase = 0;
    drive_vl(0);
    drive_vs(0);
    repeat (5) @(posedge clock);
    #1 reset = 1'b0;
    for (cycle = 0; cycle < ncycles; cycle++) begin
      phase = (cycle < 40) ? 0 : (cycle < 80) ? 1 : (cycle < 82) ? 2 : 3;
      drive_vl(phase);
      drive_vs(phase);
      @(negedge clock);
      if (cycle >= 2) begin
        compare_vl();
        compare_vs();
      end
      @(posedge clock);
      #1;
    end
    $display("coverage vl: wb=%0d toLsq=%0d feedback=%0d partReplay=%0d excFlush=%0d",
             cov_vl[0], cov_vl[1], cov_vl[2], cov_vl[3], cov_vl[4]);
    $display("coverage vs: wb=%0d toLsq=%0d feedback=%0d partReplay=%0d excFlush=%0d",
             cov_vs[0], cov_vs[1], cov_vs[2], cov_vs[3], cov_vs[4]);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
