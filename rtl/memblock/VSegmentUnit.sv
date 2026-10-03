// =====================================================================
// VSegmentUnit.sv —— 向量 segment 访存单元（vlseg / vsseg：一条指令把若干个"段"顺序搬进 / 搬出寄存器）
// ---------------------------------------------------------------------
// 位置（Chisel: xiangshan/mem/vector/VSegmentUnit.scala）：MemBlock 里独立的一个状态机，不走标量
//   访存流水。segment 指令（nf>0）一次访问 (segmentIdx, fieldIdx) 这一个元素：地址 = 基址 +
//   fieldIdx*元素字节数 + 段偏移（unit-stride：段号*(nf+1)*元素字节数；strided：累加 stride；
//   indexed：index 向量里取第 segmentIdx 个），按 "同一段的各 field → 下一段" 的顺序逐个做完。
//   load 的数据按元素拼进对应目的寄存器的槽（data[splitPtr]），store 的数据从 data[splitPtr] 里取出
//   经一级流水缓冲（NewPipelineConnectPipe_33）写进 sbuffer。
// 接口：in（后端发来的 uop：一条指令拆成 nf*max(lmul,emul) 条 uop，依次进 8 项队列 uopq/data/stride，
//   第一条 uop 到达时锁存整条指令的信息 instMicroOp）；dtlb / pmpResp（地址翻译与权限）；rdcache
//   （load 读 DCache，一次 64/128 位）；sbuffer（store 写）；flush_sbuffer（开始前把 sbuffer 排空）；
//   uopwriteback / feedback / exceptionInfo（逐条 uop 写回 / 反馈 / 异常上报）；fromCsrTrigger（调试触发器）。
// 状态机（14 态，见 §2）：idle → 排空 sbuffer → [每个元素：tlb 请求 → 等 tlb → PMP/对齐检查 →
//   (load) 读 cache → 等 cache → 拼数据 / (store) 送 sbuffer] 循环 → finish（逐条写回） → (fof) 修 vl。
// 非对齐元素（地址不按元素宽度对齐）的处理：没跨 16B 边界的当成一次 128 位访问（notCross16Byte）；
//   跨了的拆成两次 8 字节访问（curPtr=0/1 两半），load 把两半在 combinedData 里拼起来，store 分两次
//   写 sbuffer（两半各有自己的物理地址：低半 lowPagePaddr、高半 instMicroOp.paddr）。
// fault-only-first（vleff）：只有第 0 个元素允许报异常；后面元素出异常时记下 exceptionVl，等指令的
//   最后一条 uop（isEnqFixVlUop，先存在 fofBuffer）在 s_fof_fix_vl 态写回时把 vl 改小。
// 寄存器的位置：控制寄存器与 instMicroOp 的非 uop 字段在核里；大块 payload（uopq×8 / data×8 /
//   stride×8 / instMicroOp.uop / fofBuffer / 写回与反馈的打拍寄存器）放在 wrapper 的生成段里，
//   字段集合照 golden 现数；核给出使能与装载值，读回成 struct / 数组。
// 本配置下 golden 消掉的东西（核里不写）：instMicroOp.vstart 恒 0、exceptionVl.valid、exception_va/gpa/pa
//   寄存器、highPagePaddr / lowPageGPaddr / highPageGPaddr、stridePtrReg.flag、uopwriteback.debug.*（恒 0）、
//   dtlb/rdcache 的若干常量端口、vecDifftestInfo.valid/start/offset。
// 子模块（两侧白盒）：VSegmentTrigger（本 lane）、NewPipelineConnectPipe_33（已签核）。
// 文件结构：xs_VSegmentUnit_core（手写）→ VSegmentUnit wrapper（生成）；接口 struct 在 vsegment_pkg.sv、小函数在 vlsu_pkg.sv；
//   GENERATED 段由 scripts/gen_vsegmentunit.py 生成。
// =====================================================================
// 本文件导航（按"一个 golden 模块一个文件"的规范不拆分；行号由 scripts/gen_vsegmentunit.py 维护）：
// BEGIN GENERATED(nav) —— scripts/gen_vsegmentunit.py 生成，勿手改
//   L48    xs_VSegmentUnit_core —— 可读核
//   L168   §1 指令级状态（instMicroOp）与队列指针
//   L291   §2 状态机
//   L366   §3 地址：虚地址、非对齐拆分、TLB 请求
//   L441   §4 异常与对齐检查（s_pm 态）
//   L564   §5 load：读 DCache，拼进目的寄存器
//   L630   §6 store：取出元素数据，经流水缓冲写 sbuffer
//   L698   §7 指针与计数的推进
//   L836   §8 fof 的最后一条 uop（fofBuffer）
//   L844   §9 写回 / 反馈 / 异常上报
//   L970   VSegmentUnit wrapper（生成）：端口拆装 + payload 寄存器
// END GENERATED(nav)
// =====================================================================

// =====================================================================
// xs_VSegmentUnit_core —— segment 访存状态机的可读核
// =====================================================================
module xs_VSegmentUnit_core
  import vlsu_pkg::*;
  import vsegment_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— scripts/gen_vsegmentunit.py 生成，勿手改
  input  logic          clock,
  input  logic          reset,
  input  logic          in_valid,
  input  seg_in_t       in,
  output logic          uopwriteback_valid,
  output seg_wb_t       uopwriteback,
  input  logic          csrCtrl_cache_error_enable,
  input  logic          rdcache_req_ready,
  output logic          rdcache_req_valid,
  output seg_dcache_req_t rdcache_req,
  input  logic          rdcache_resp_valid,
  input  seg_dcache_resp_t rdcache_resp,
  output logic          rdcache_is128Req,
  output logic [47:0]   rdcache_s1_paddr_dup_lsu,
  output logic [47:0]   rdcache_s1_paddr_dup_dcache,
  input  logic          rdcache_s2_bank_conflict,
  input  logic          sbuffer_ready,
  output logic          sbuffer_valid,
  output seg_sbuf_t     sbuffer,
  output seg_difftest_t vecDifftestInfo,
  output logic          dtlb_req_valid,
  output seg_tlb_req_t  dtlb_req,
  input  logic          dtlb_resp_valid,
  input  seg_tlb_resp_t dtlb_resp,
  input  logic          pmpResp_ld,
  input  logic          pmpResp_st,
  input  logic          pmpResp_instr,
  input  logic          pmpResp_mmio,
  input  logic          pmpResp_atomic,
  output logic          flush_sbuffer_valid,
  input  logic          flush_sbuffer_empty,
  output logic          feedback_valid,
  output seg_feedback_t feedback,
  output logic          exceptionInfo_valid,
  output seg_excinfo_t  exceptionInfo,
  input  logic [1:0]    fromCsrTrigger_tdataVec_0_matchType,
  input  logic          fromCsrTrigger_tdataVec_0_select,
  input  logic          fromCsrTrigger_tdataVec_0_timing,
  input  logic [3:0]    fromCsrTrigger_tdataVec_0_action,
  input  logic          fromCsrTrigger_tdataVec_0_chain,
  input  logic          fromCsrTrigger_tdataVec_0_store,
  input  logic          fromCsrTrigger_tdataVec_0_load,
  input  logic [63:0]   fromCsrTrigger_tdataVec_0_tdata2,
  input  logic [1:0]    fromCsrTrigger_tdataVec_1_matchType,
  input  logic          fromCsrTrigger_tdataVec_1_select,
  input  logic          fromCsrTrigger_tdataVec_1_timing,
  input  logic [3:0]    fromCsrTrigger_tdataVec_1_action,
  input  logic          fromCsrTrigger_tdataVec_1_chain,
  input  logic          fromCsrTrigger_tdataVec_1_store,
  input  logic          fromCsrTrigger_tdataVec_1_load,
  input  logic [63:0]   fromCsrTrigger_tdataVec_1_tdata2,
  input  logic [1:0]    fromCsrTrigger_tdataVec_2_matchType,
  input  logic          fromCsrTrigger_tdataVec_2_select,
  input  logic          fromCsrTrigger_tdataVec_2_timing,
  input  logic [3:0]    fromCsrTrigger_tdataVec_2_action,
  input  logic          fromCsrTrigger_tdataVec_2_chain,
  input  logic          fromCsrTrigger_tdataVec_2_store,
  input  logic          fromCsrTrigger_tdataVec_2_load,
  input  logic [63:0]   fromCsrTrigger_tdataVec_2_tdata2,
  input  logic [1:0]    fromCsrTrigger_tdataVec_3_matchType,
  input  logic          fromCsrTrigger_tdataVec_3_select,
  input  logic          fromCsrTrigger_tdataVec_3_timing,
  input  logic [3:0]    fromCsrTrigger_tdataVec_3_action,
  input  logic          fromCsrTrigger_tdataVec_3_chain,
  input  logic          fromCsrTrigger_tdataVec_3_store,
  input  logic          fromCsrTrigger_tdataVec_3_load,
  input  logic [63:0]   fromCsrTrigger_tdataVec_3_tdata2,
  input  logic          fromCsrTrigger_tEnableVec_0,
  input  logic          fromCsrTrigger_tEnableVec_1,
  input  logic          fromCsrTrigger_tEnableVec_2,
  input  logic          fromCsrTrigger_tEnableVec_3,
  input  logic          fromCsrTrigger_debugMode,
  input  logic          fromCsrTrigger_triggerCanRaiseBpExp,
  output logic [7:0]    uopq_we,
  input  seg_uop_t [7:0] uopq_uop,
  output logic [7:0]    data_we,
  output logic [7:0][127:0] data_wdata,
  input  logic [7:0][127:0] data,
  input  logic [7:0][127:0] stride,
  output logic          instMicroOp_load,
  input  seg_uop_t      instMicroOp_uop_q,
  output logic          fofBuffer_we,
  output seg_uop_t      fofBuffer_wdata,
  input  seg_uop_t      fofBuffer,
  output logic          writebackValid,
  output seg_wb_t       writebackOut,
  input  seg_wb_t       uopwriteback_r,
  output logic          feedbackValid,
  output seg_feedback_t feedbackOut,
  input  seg_feedback_t feedback_r
  // END GENERATED(core_ports)
);

  localparam int Q = 8;            // VSegmentBufferSize：uop 队列深度
  localparam int PADDR_W = 48;

  // ---- 状态编码 ----
  localparam logic [3:0] S_IDLE = 4'd0;   // 等指令
  localparam logic [3:0] S_FLUSH_SBUFFER_REQ = 4'd1;   // 让 sbuffer 排空
  localparam logic [3:0] S_WAIT_FLUSH_SBUFFER_RESP = 4'd2;
  localparam logic [3:0] S_TLB_REQ = 4'd3;             // 发本元素的 TLB 请求
  localparam logic [3:0] S_WAIT_TLB_RESP = 4'd4;
  localparam logic [3:0] S_PM = 4'd5;                  // PMP / 对齐 / 触发器检查
  localparam logic [3:0] S_CACHE_REQ = 4'd6;           // load：读 DCache
  localparam logic [3:0] S_CACHE_RESP = 4'd7;
  localparam logic [3:0] S_MISALIGN_MERGE_DATA = 4'd8; // load 跨 16B：先存低半
  localparam logic [3:0] S_LATCH_AND_MERGE_DATA = 4'd9;// load：把元素拼进目的寄存器
  localparam logic [3:0] S_SEND_DATA = 4'd10;          // store：元素数据送 sbuffer
  localparam logic [3:0] S_WAIT_TO_SBUFFER = 4'd11;    // store：等最后一笔真正进 sbuffer
  localparam logic [3:0] S_FINISH = 4'd12;             // 逐条 uop 写回
  localparam logic [3:0] S_FOF_FIX_VL = 4'd13;         // fof：写回最后一条 uop 以修改 vl

  // ===================================================================
  // §1 指令级状态（instMicroOp）与队列指针
  // ===================================================================
  logic              instMicroOpValid;
  logic [XLEN-1:0]   instMicroOp_baseVaddr;
  logic [VLEN-1:0]   instMicroOp_mask;            // 元素活跃掩码 = (v0 或全 1) ∩ [vstart, vl)
  logic [2:0]        instMicroOp_alignedType;     // 元素字节数 log2（indexed 用 sew，否则 eew）
  logic [7:0]        instMicroOp_vl;
  logic [7:0]        instMicroOp_uopFlowNumMask;  // 一个目的寄存器里的元素数 - 1
  logic              instMicroOp_isVSegLoad, instMicroOp_isVSegStore, instMicroOp_isFof;
  logic [PADDR_W-1:0] instMicroOp_paddr;
  logic [XLEN-1:0]   instMicroOp_exceptionVaddr, instMicroOp_exceptionGpaddr;
  logic              instMicroOp_exceptionIsForVSnonLeafPTE;
  logic [7:0]        instMicroOp_exceptionVstart; // 出异常的元素号
  logic [7:0]        instMicroOp_exceptionVl_bits;// fof：非首元素出异常时要把 vl 改成的值
  // uop 里由本单元改写的字段（其余字段在 wrapper 的生成段里，读回为 instMicroOp_uop_q）
  logic              instMicroOp_uop_exceptionVec_3, instMicroOp_uop_exceptionVec_5, instMicroOp_uop_exceptionVec_7,
                     instMicroOp_uop_exceptionVec_13, instMicroOp_uop_exceptionVec_15, instMicroOp_uop_exceptionVec_19,
                     instMicroOp_uop_exceptionVec_21, instMicroOp_uop_exceptionVec_23;
  logic [3:0]        instMicroOp_uop_trigger;
  seg_uop_t              instMicroOp_uop;             // 合成后的完整 uop
  logic [23:0]       instExcVec;                  // instMicroOp_uop.exceptionVec（8 位有效）

  always_comb begin
    instExcVec     = '0;
    instExcVec[3]  = instMicroOp_uop_exceptionVec_3;
    instExcVec[5]  = instMicroOp_uop_exceptionVec_5;
    instExcVec[7]  = instMicroOp_uop_exceptionVec_7;
    instExcVec[13] = instMicroOp_uop_exceptionVec_13;
    instExcVec[15] = instMicroOp_uop_exceptionVec_15;
    instExcVec[19] = instMicroOp_uop_exceptionVec_19;
    instExcVec[21] = instMicroOp_uop_exceptionVec_21;
    instExcVec[23] = instMicroOp_uop_exceptionVec_23;
    instMicroOp_uop              = instMicroOp_uop_q;
    instMicroOp_uop.exceptionVec = instExcVec;
    instMicroOp_uop.trigger      = instMicroOp_uop_trigger;
  end

  logic       enqPtr_flag, deqPtr_flag, splitPtr_flag;
  logic [2:0] enqPtr_value, deqPtr_value, splitPtr_value, stridePtrReg_value;
  logic [7:0] segmentIdx;          // 当前段号
  logic [3:0] fieldIdx;            // 当前 field 号
  logic [XLEN-1:0] segmentOffset;  // 当前段相对基址的偏移（unit-stride / strided 累加）
  logic [3:0] state;
  logic       fofBufferValid;
  logic       curPtr;              // 跨 16B 非对齐：0 = 低半，1 = 高半
  logic       isMisalignReg, notCross16ByteReg;
  logic [XLEN-1:0] latchVaddr, latchVaddrDup;    // 本元素的虚地址（Dup 是给 DCache 的复制）
  logic [XLEN-1:0] combinedData;   // 跨 16B 的 load 拼接两半数据
  logic [PADDR_W-1:0] lowPagePaddr;// 跨 16B 的低半物理地址
  logic       triggerDebugMode, triggerBreakpoint;
  logic       last_REG;            // csrCtrl.cache_error_enable 打一拍
  logic [XLEN-1:0] nextBaseVaddr_r;// 基址 + fieldIdx*元素字节数（进 s_tlb_req 时算好）
  logic [2:0] issueMaxIdxInIndexLog2;  // 一个 index 寄存器里的元素数 log2（打一拍）
  logic       io_uopwriteback_valid_REG, io_feedback_valid_REG;
  logic [2:0] io_uopwriteback_bits_r_vdIdx, io_uopwriteback_bits_r_vdIdxInField;

  // ---- 由 instMicroOp 导出的量 ----
  logic [7:0] maxSegIdx;
  logic [3:0] maxNfields;
  logic [1:0] issueEew, issueSew;
  logic [2:0] issueLmul, issueEmul;
  logic       issueIsIndexed;
  logic [2:0] issueUopFlowNumLog2;     // 一个目的寄存器里的元素数 log2
  logic [7:0] issueIndexIdx;           // 元素在 index 寄存器里的序号
  logic [7:0] elemIdxInVd;             // 元素在目的寄存器里的序号
  logic       segmentActive;           // 本段是否活跃（没被 mask 掉）

  assign maxSegIdx      = instMicroOp_vl - 8'd1;
  assign maxNfields     = 4'(instMicroOp_uop_q.vpu_nf);
  assign issueEew       = instMicroOp_uop_q.vpu_veew;
  assign issueSew       = instMicroOp_uop_q.vpu_vsew;
  assign issueLmul      = instMicroOp_uop_q.vpu_vlmul;
  assign issueEmul      = 3'(issueEew) - 3'(issueSew) + issueLmul;
  assign issueIsIndexed = instMicroOp_uop_q.fuOpType[5];
  always_comb begin
    logic [2:0] eewFlowLog2, sewFlowLog2;
    eewFlowLog2 = mul_frac_only(issueEmul) + 3'd4 - 3'(issueEew);
    sewFlowLog2 = mul_frac_only(issueLmul) + 3'd4 - 3'(issueSew);
    issueUopFlowNumLog2 = issueIsIndexed ? sewFlowLog2 : eewFlowLog2;    // segment 口径：indexed 一律按 sew
  end
  assign issueIndexIdx = segmentIdx & ((8'h1 << ((($signed(issueEmul) > 0) ? 3'b0 : issueEmul) + 3'd4 - 3'(issueEew))) - 8'h1);
  assign elemIdxInVd   = segmentIdx & instMicroOp_uopFlowNumMask;
  always_comb begin
    logic [255:0] segOH;
    segOH = 256'h1 << segmentIdx;
    segmentActive = |(segOH[VLEN-1:0] & instMicroOp_mask);
  end

  // ---- 入队侧的译码（第一条 uop 到达时锁存指令信息；每条 uop 进队列）----
  logic       isFofOp, isEnqFixVlUop, firstUopFire, uopEnqueue;
  logic [1:0] inMop, inEew, inSew;
  logic [2:0] inLmul, inEmul;
  assign isFofOp       = (in.uop.fuOpType == VLDU_VLEFF);
  assign isEnqFixVlUop = isFofOp & in_valid & in.uop.vpu_lastUop;      // fof 的最后一条 uop：只用来修 vl
  assign firstUopFire  = in_valid & ~instMicroOpValid;
  assign uopEnqueue    = in_valid & ~isEnqFixVlUop;
  assign instMicroOp_load = firstUopFire & ~isEnqFixVlUop;
  assign inMop  = in.uop.fuOpType[6:5];
  assign inEew  = in.uop.vpu_veew;
  assign inSew  = in.uop.vpu_vsew;
  assign inLmul = in.uop.vpu_vlmul;
  assign inEmul = 3'(inEew) - 3'(inSew) + inLmul;

  for (genvar i = 0; i < Q; i++) begin : g_enq
    assign uopq_we[i] = uopEnqueue & (enqPtr_value == 3'(i));
  end

  // 一个目的寄存器里的元素数（GenRealFlowNum，segment 口径）：
  //   unit-stride / strided：MulDataSize(emul) >> eew；indexed：MulDataSize(lmul) >> sew
  //   MulDataSize：倍数 >= 1 → 16 字节，1/2 → 8，1/4 → 4，1/8 → 2
  function automatic logic [4:0] mul_data_size(input logic [2:0] mul);
    case (mul)
      3'b101:  return 5'd2;
      3'b110:  return 5'd4;
      3'b111:  return 5'd8;
      3'b100:  return 5'd0;
      default: return 5'd16;
    endcase
  endfunction
  logic [4:0] inUopFlowNum;
  assign inUopFlowNum = inMop[0] ? (mul_data_size(inLmul) >> inSew) : (mul_data_size(inEmul) >> inEew);

  // ===================================================================
  // §2 状态机
  // ===================================================================
  logic [3:0] stateNext;
  logic       exception_va, exception_gpa, exception_pa, anyException;
  logic       isMisalignWire, notCross16ByteWire, canHandleMisalign;
  logic       cacheRespError;              // DCache 回了硬件错误
  logic       sbufferOut_valid, sbufferOut_fire;   // 送往 sbuffer 流水缓冲的握手
  logic       sbufferFire;                 // 流水缓冲 → sbuffer 的握手
  logic       queueNonEmpty;               // enqPtr != deqPtr
  logic [3:0] queueDistance;
  logic       finishLastSplit;             // 跨 16B 的 store 还差高半没发
  logic       pipe_in_ready, pipe_out_valid;   // 送 sbuffer 的流水缓冲（§6 例化）的握手
  logic       fofFixVlValid, fofBuffer_load;   // §8

  assign queueNonEmpty = ({enqPtr_flag, enqPtr_value} != {deqPtr_flag, deqPtr_value});
  assign queueDistance = (enqPtr_flag == deqPtr_flag) ? 4'(enqPtr_value - deqPtr_value)
                                                      : 4'(4'(4'(enqPtr_value) - 4'd8) - 4'(deqPtr_value));
  assign sbufferOut_fire = pipe_in_ready & sbufferOut_valid;
  assign sbufferFire     = sbuffer_ready & pipe_out_valid;
  assign finishLastSplit = isMisalignReg & ~notCross16ByteReg & ~curPtr;

  always_comb begin
    case (state)
      S_IDLE:                   stateNext = (enqPtr_flag ^ deqPtr_flag ^ (enqPtr_value > deqPtr_value)) ? S_FLUSH_SBUFFER_REQ : S_IDLE;
      S_FLUSH_SBUFFER_REQ,
      S_WAIT_FLUSH_SBUFFER_RESP: stateNext = flush_sbuffer_empty ? S_TLB_REQ : S_WAIT_FLUSH_SBUFFER_RESP;
      S_TLB_REQ:                stateNext = segmentActive ? S_WAIT_TLB_RESP
                                          : (instMicroOp_isVSegLoad ? S_LATCH_AND_MERGE_DATA : S_SEND_DATA);
      S_WAIT_TLB_RESP:          stateNext = dtlb_resp_valid ? (dtlb_resp.miss ? S_TLB_REQ : S_PM) : S_WAIT_TLB_RESP;
      S_PM: begin
        if (anyException)
          stateNext = S_FINISH;
        else if (canHandleMisalign & isMisalignWire & ~notCross16ByteWire | finishLastSplit & instMicroOp_isVSegStore)
          stateNext = S_TLB_REQ;          // 跨 16B：再去翻译另一半
        else
          stateNext = instMicroOp_isVSegLoad ? S_CACHE_REQ : S_SEND_DATA;
      end
      S_CACHE_REQ:              stateNext = (rdcache_req_ready & rdcache_req_valid) ? S_CACHE_RESP : S_CACHE_REQ;
      S_CACHE_RESP: begin
        if (rdcache_resp_valid) begin
          if (rdcache_resp.miss | rdcache_s2_bank_conflict)
            stateNext = S_CACHE_REQ;
          else
            stateNext = instMicroOp_isVSegLoad ? ((isMisalignReg & ~notCross16ByteReg) ? S_MISALIGN_MERGE_DATA
                                                                                       : S_LATCH_AND_MERGE_DATA)
                                               : S_SEND_DATA;
        end else
          stateNext = S_CACHE_RESP;
      end
      S_MISALIGN_MERGE_DATA:    stateNext = exception_pa ? S_FINISH : (~curPtr ? S_TLB_REQ : S_LATCH_AND_MERGE_DATA);
      S_LATCH_AND_MERGE_DATA: begin
        if (exception_pa | (segmentIdx == maxSegIdx) & (fieldIdx == maxNfields) | (segmentIdx == maxSegIdx) & ~segmentActive)
          stateNext = S_FINISH;
        else
          stateNext = S_TLB_REQ;
      end
      S_SEND_DATA: begin
        if (~sbufferOut_fire & segmentActive | finishLastSplit)
          stateNext = S_SEND_DATA;
        else if ((segmentIdx == maxSegIdx) & ((fieldIdx == maxNfields) & sbufferOut_fire
                                             | ~segmentActive & pipe_out_valid & ~sbuffer_ready))
          stateNext = S_WAIT_TO_SBUFFER;
        else if ((segmentIdx == maxSegIdx) & ~segmentActive)
          stateNext = S_FINISH;
        else
          stateNext = S_TLB_REQ;
      end
      S_WAIT_TO_SBUFFER:        stateNext = sbufferFire ? S_FINISH : S_WAIT_TO_SBUFFER;
      S_FINISH:                 stateNext = (queueDistance == 4'd0) ? (fofBufferValid ? S_FOF_FIX_VL : S_IDLE) : S_FINISH;
      S_FOF_FIX_VL:             stateNext = fofBufferValid ? S_FOF_FIX_VL : S_IDLE;
      default:                  stateNext = S_IDLE;
    endcase
  end

  // ===================================================================
  // §3 地址：本元素的虚地址、非对齐拆分、TLB 请求
  // ===================================================================
  logic [XLEN-1:0]  realSegmentOffset, vaddr;
  logic [60:0]      misalignHalfHi;         // 跨 16B 拆分时当前半的地址高位（8 字节对齐）
  logic [XLEN-1:0]  misalignVaddr, tlbReqVaddr;
  logic [49:0]      dcacheReqVaddr;

  assign realSegmentOffset = issueIsIndexed ? index_elem(stride[stridePtrReg_value], issueIndexIdx, issueEew) : segmentOffset;
  assign vaddr             = nextBaseVaddr_r + realSegmentOffset;
  assign misalignHalfHi    = curPtr ? latchVaddr[XLEN-1:3] + 61'd1 : latchVaddr[XLEN-1:3];
  assign misalignVaddr     = {misalignHalfHi, 3'b0};
  assign tlbReqVaddr       = isMisalignReg ? misalignVaddr : vaddr;
  assign dcacheReqVaddr    = isMisalignReg ? {misalignHalfHi[46:0], 3'b0} : latchVaddr[49:0];

  assign dtlb_req_valid = (state == S_TLB_REQ) & segmentActive;
  always_comb begin
    dtlb_req                    = '0;
    dtlb_req.vaddr              = tlbReqVaddr[49:0];
    dtlb_req.fullva             = tlbReqVaddr;
    dtlb_req.cmd                = instMicroOp_isVSegLoad ? 3'd0 : 3'd1;    // TlbCmd.read / write
    dtlb_req.debug_robIdx_flag  = instMicroOp_uop_q.robIdx_flag;
    dtlb_req.debug_robIdx_value = instMicroOp_uop_q.robIdx_value;
  end

  // ---- 调试触发器（纯组合，按本元素的虚地址匹配）----
  logic [3:0] triggerAction;
  // BEGIN GENERATED(trigger) —— scripts/gen_vsegmentunit.py 生成，勿手改
  VSegmentTrigger segmentTrigger (
    .tdataVec_io_fromCsrTrigger_tdataVec_0_matchType  (fromCsrTrigger_tdataVec_0_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_select     (fromCsrTrigger_tdataVec_0_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_timing     (fromCsrTrigger_tdataVec_0_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_action     (fromCsrTrigger_tdataVec_0_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_chain      (fromCsrTrigger_tdataVec_0_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_store      (fromCsrTrigger_tdataVec_0_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_load       (fromCsrTrigger_tdataVec_0_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2     (fromCsrTrigger_tdataVec_0_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_matchType  (fromCsrTrigger_tdataVec_1_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_select     (fromCsrTrigger_tdataVec_1_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_timing     (fromCsrTrigger_tdataVec_1_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_action     (fromCsrTrigger_tdataVec_1_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_chain      (fromCsrTrigger_tdataVec_1_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_store      (fromCsrTrigger_tdataVec_1_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_load       (fromCsrTrigger_tdataVec_1_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2     (fromCsrTrigger_tdataVec_1_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_matchType  (fromCsrTrigger_tdataVec_2_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_select     (fromCsrTrigger_tdataVec_2_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_timing     (fromCsrTrigger_tdataVec_2_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_action     (fromCsrTrigger_tdataVec_2_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_chain      (fromCsrTrigger_tdataVec_2_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_store      (fromCsrTrigger_tdataVec_2_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_load       (fromCsrTrigger_tdataVec_2_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2     (fromCsrTrigger_tdataVec_2_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_matchType  (fromCsrTrigger_tdataVec_3_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_select     (fromCsrTrigger_tdataVec_3_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_timing     (fromCsrTrigger_tdataVec_3_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_action     (fromCsrTrigger_tdataVec_3_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_chain      (fromCsrTrigger_tdataVec_3_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_store      (fromCsrTrigger_tdataVec_3_store),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_load       (fromCsrTrigger_tdataVec_3_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2     (fromCsrTrigger_tdataVec_3_tdata2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_0          (fromCsrTrigger_tEnableVec_0),
    .tdataVec_io_fromCsrTrigger_tEnableVec_1          (fromCsrTrigger_tEnableVec_1),
    .tdataVec_io_fromCsrTrigger_tEnableVec_2          (fromCsrTrigger_tEnableVec_2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_3          (fromCsrTrigger_tEnableVec_3),
    .tdataVec_io_fromCsrTrigger_debugMode             (fromCsrTrigger_debugMode),
    .tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp  (fromCsrTrigger_triggerCanRaiseBpExp),
    .tdataVec_io_fromLoadStore_vaddr                  (dcacheReqVaddr),
    .tdataVec_io_toLoadStore_triggerAction            (triggerAction),
    .tdataVec_io_memType                              (instMicroOp_isVSegLoad)
  );
  // END GENERATED(trigger)
  logic canTriggerException;      // fof 指令只有第 0 个元素能报异常
  assign canTriggerException = (segmentIdx == 8'h0) | ~instMicroOp_isFof;

  // ===================================================================
  // §4 异常与对齐检查（s_pm 态）
  // ===================================================================
  logic       exceptionWithPf;
  logic       pmp_ld, pmp_st, pmp_mmio;    // 翻译出了页异常时 PMP 结果不可信，整体清 0
  logic [1:0] checkEw;
  logic       addrAligned;
  logic [4:0] highAddress;

  assign exceptionWithPf = instMicroOp_uop_exceptionVec_15 | instMicroOp_uop_exceptionVec_13
                         | instMicroOp_uop_exceptionVec_23 | instMicroOp_uop_exceptionVec_21;
  assign pmp_ld   = pmpResp_ld   & ~exceptionWithPf;
  assign pmp_st   = pmpResp_st   & ~exceptionWithPf;
  assign pmp_mmio = pmpResp_mmio & ~exceptionWithPf;
  assign checkEw  = issueIsIndexed ? issueSew : issueEew;
  always_comb begin
    case (checkEw)
      2'd0:    addrAligned = 1'b1;
      2'd1:    addrAligned = (vaddr[0] == 1'b0);
      2'd2:    addrAligned = (vaddr[1:0] == 2'b0);
      default: addrAligned = (vaddr[2:0] == 3'b0);
    endcase
    case (checkEw)
      2'd0:    highAddress = 5'd0;
      2'd1:    highAddress = 5'd1;
      2'd2:    highAddress = 5'd3;
      default: highAddress = 5'd7;
    endcase
    highAddress = highAddress + vaddr[4:0];      // 元素最后一个字节的地址低 5 位
  end
  // 这三个只在 s_pm 态有意义（Chisel 里写在 when(state === s_pm) 内）
  assign notCross16ByteWire = (state == S_PM) & (highAddress[4] == vaddr[4]);
  assign isMisalignWire     = (state == S_PM) & ~addrAligned & ~isMisalignReg;
  assign canHandleMisalign  = ~pmp_mmio & ~triggerBreakpoint & ~triggerDebugMode;

  assign cacheRespError = ((state == S_LATCH_AND_MERGE_DATA) | (state == S_MISALIGN_MERGE_DATA))
                        & (rdcache_resp.tl_error_delayed_tl_denied | rdcache_resp.tl_error_delayed_tl_corrupt)
                        & last_REG & segmentActive;
  assign exception_va  = (state == S_PM) & (instMicroOp_uop_exceptionVec_15 | instMicroOp_uop_exceptionVec_13
                                            | instMicroOp_uop_exceptionVec_7 | instMicroOp_uop_exceptionVec_5
                                            | triggerBreakpoint | triggerDebugMode | pmp_mmio);
  assign exception_gpa = (state == S_PM) & (instMicroOp_uop_exceptionVec_23 | instMicroOp_uop_exceptionVec_21);
  assign exception_pa  = cacheRespError | (state == S_PM) & (pmp_st | pmp_ld | pmp_mmio);
  assign anyException  = exception_va | exception_gpa | exception_pa;

  // ---- 异常位 / 触发器 / 地址信息的寄存器更新 ----
  logic tlbRespFire, tlbRespHit, pbmtUncache;
  assign tlbRespFire = dtlb_resp_valid & (state == S_WAIT_TLB_RESP);
  assign tlbRespHit  = tlbRespFire & ~dtlb_resp.miss;
  assign pbmtUncache = (dtlb_resp.pbmt_0 == 2'd1) | (dtlb_resp.pbmt_0 == 2'd2);   // Pbmt.isUncache：NC 或 IO

  always_ff @(posedge clock) begin
    // 页异常 / 访问异常：TLB 应答时记下；s_pm 态按 load/store 类别与 fof 规则过滤，并并入 PMP 结果
    if (state == S_PM) begin
      instMicroOp_uop_exceptionVec_3  <= triggerBreakpoint & canTriggerException;
      instMicroOp_uop_exceptionVec_7  <= (instMicroOp_uop_exceptionVec_7 | pmp_st | pmp_mmio) & instMicroOp_isVSegStore & canTriggerException;
      instMicroOp_uop_exceptionVec_13 <= instMicroOp_uop_exceptionVec_13 & instMicroOp_isVSegLoad  & canTriggerException;
      instMicroOp_uop_exceptionVec_15 <= instMicroOp_uop_exceptionVec_15 & instMicroOp_isVSegStore & canTriggerException;
      instMicroOp_uop_exceptionVec_21 <= instMicroOp_uop_exceptionVec_21 & instMicroOp_isVSegLoad  & canTriggerException;
      instMicroOp_uop_exceptionVec_23 <= instMicroOp_uop_exceptionVec_23 & instMicroOp_isVSegStore & canTriggerException;
    end else begin
      instMicroOp_uop_exceptionVec_3 <= ~instMicroOp_load & instMicroOp_uop_exceptionVec_3;
      if (tlbRespFire) begin
        instMicroOp_uop_exceptionVec_7  <= dtlb_resp.excp_0_af_st | pbmtUncache;   // 不支持向量 MMIO：uncache 页报访问异常
        instMicroOp_uop_exceptionVec_13 <= dtlb_resp.excp_0_pf_ld;
        instMicroOp_uop_exceptionVec_15 <= dtlb_resp.excp_0_pf_st;
        instMicroOp_uop_exceptionVec_21 <= dtlb_resp.excp_0_gpf_ld;
        instMicroOp_uop_exceptionVec_23 <= dtlb_resp.excp_0_gpf_st;
      end else begin
        instMicroOp_uop_exceptionVec_7  <= ~instMicroOp_load & instMicroOp_uop_exceptionVec_7;
        instMicroOp_uop_exceptionVec_13 <= ~instMicroOp_load & instMicroOp_uop_exceptionVec_13;
        instMicroOp_uop_exceptionVec_15 <= ~instMicroOp_load & instMicroOp_uop_exceptionVec_15;
        instMicroOp_uop_exceptionVec_21 <= ~instMicroOp_load & instMicroOp_uop_exceptionVec_21;
        instMicroOp_uop_exceptionVec_23 <= ~instMicroOp_load & instMicroOp_uop_exceptionVec_23;
      end
    end
    // DCache 硬件错误：denied → load 访问异常，corrupt → hardwareError（优先级最高）
    if (cacheRespError & canTriggerException) begin
      instMicroOp_uop_exceptionVec_5  <= rdcache_resp.tl_error_delayed_tl_denied & instMicroOp_isVSegLoad;
      instMicroOp_uop_exceptionVec_19 <= rdcache_resp.tl_error_delayed_tl_corrupt & ~rdcache_resp.tl_error_delayed_tl_denied;
    end else begin
      if (state == S_PM)
        instMicroOp_uop_exceptionVec_5 <= (instMicroOp_uop_exceptionVec_5 | pmp_ld | pmp_mmio) & instMicroOp_isVSegLoad & canTriggerException;
      else if (tlbRespFire)
        instMicroOp_uop_exceptionVec_5 <= dtlb_resp.excp_0_af_ld | pbmtUncache;
      else
        instMicroOp_uop_exceptionVec_5 <= ~instMicroOp_load & instMicroOp_uop_exceptionVec_5;
      instMicroOp_uop_exceptionVec_19 <= ~instMicroOp_load & instMicroOp_uop_exceptionVec_19;
    end
    // 触发器动作（断点位读的是寄存器里的旧值：Chisel 读 Reg 得到的是当前值）
    if ((state == S_PM) & (instMicroOp_uop_exceptionVec_3 | triggerDebugMode))
      instMicroOp_uop_trigger <= triggerAction;
    else if (instMicroOp_load)
      instMicroOp_uop_trigger <= 4'h0;
    if (tlbRespHit) begin
      instMicroOp_paddr                      <= dtlb_resp.paddr_0;
      instMicroOp_exceptionVaddr             <= dtlb_resp.fullva;
      instMicroOp_exceptionGpaddr            <= dtlb_resp.gpaddr_0;
      instMicroOp_exceptionIsForVSnonLeafPTE <= dtlb_resp.isForVSnonLeafPTE;
    end
    // 出异常的元素号：能报异常的记 vstart；fof 不能报的记 exceptionVl（之后把 vl 改小）
    if (cacheRespError & canTriggerException | (state == S_PM) & anyException & canTriggerException)
      instMicroOp_exceptionVstart <= segmentIdx;
    if (~cacheRespError & ~((state == S_PM) & anyException) | canTriggerException) begin
      if (instMicroOp_load) instMicroOp_exceptionVl_bits <= in.src_4[7:0];
    end else
      instMicroOp_exceptionVl_bits <= segmentIdx;
    // 指令信息锁存（第一条 uop 到达）。★掩码用的是 instMicroOp 里上一条指令留下的 vm / vl / vstart★
    // （Chisel 里 srcMask 读的是寄存器 instMicroOp.*，照抄）
    if (instMicroOp_load) begin
      instMicroOp_baseVaddr      <= in.src_0[XLEN-1:0];
      instMicroOp_mask           <= (instMicroOp_uop_q.vpu_vm ? '1 : in.src_3)
                                  & low_ones(11'(instMicroOp_vl)) & ~low_ones(11'(instMicroOp_uop_q.vpu_vstart));
      instMicroOp_alignedType    <= {1'b0, in.uop.fuOpType[5] ? inSew : inEew};
      instMicroOp_vl             <= in.src_4[7:0];
      instMicroOp_uopFlowNumMask <= 8'(inUopFlowNum) - 8'd1;
      instMicroOp_isVSegLoad     <= in.uop.fuType[33];     // FuType.vsegldu
      instMicroOp_isVSegStore    <= in.uop.fuType[34];     // FuType.vsegstu
      instMicroOp_isFof          <= isFofOp & in.uop.fuType[33];
    end
    issueMaxIdxInIndexLog2 <= (($signed(issueEmul) > 0) ? 3'b0 : issueEmul) + 3'd4 - 3'(issueEew);
  end

  // ===================================================================
  // §5 load：读 DCache，把元素拼进目的寄存器
  // ===================================================================
  logic [PADDR_W-1:0] dcacheReqPaddr;
  logic [3:0]         addrLow4;
  logic [XLEN-1:0]    cacheData;           // 对齐访问：从 128 位应答里按地址低 4 位取出的 8 字节
  logic [XLEN-1:0]    misalignLowData;     // 跨 16B 低半：第一个 16B 窗口里的尾巴
  logic [XLEN-1:0]    misalignCombinedData;// 跨 16B 高半：拼上第二个窗口的头
  logic [XLEN-1:0]    shiftData, rawElem, pickData;
  logic [VLEN-1:0]    mergedData;

  assign dcacheReqPaddr = isMisalignReg ? {instMicroOp_paddr[PADDR_W-1:12], misalignHalfHi[8:0], 3'b0} : instMicroOp_paddr;
  assign rdcache_req_valid = (state == S_CACHE_REQ) & instMicroOp_isVSegLoad;
  always_comb begin
    rdcache_req           = '0;
    rdcache_req.vaddr     = dcacheReqVaddr;
    rdcache_req.vaddr_dup = isMisalignReg ? {curPtr ? latchVaddrDup[49:3] + 47'd1 : latchVaddrDup[49:3], 3'b0} : latchVaddrDup[49:0];
  end
  assign rdcache_is128Req          = notCross16ByteReg;
  assign rdcache_s1_paddr_dup_lsu   = dcacheReqPaddr;
  assign rdcache_s1_paddr_dup_dcache = dcacheReqPaddr;

  assign addrLow4 = latchVaddr[3:0];
  always_comb begin
    // 对齐访问：低 8 字节窗口（地址低 4 位 < 8）或高 8 字节窗口里从偏移处取到窗口末尾，零扩展
    cacheData       = addrLow4[3] ? XLEN'(rdcache_resp.data_delayed[127:64] >> {addrLow4[2:0], 3'b0})
                                  : XLEN'(rdcache_resp.data_delayed[63:0]   >> {addrLow4[2:0], 3'b0});
    // 跨 16B 的低半只可能起于偏移 9..15：取高 8 字节窗口的尾巴
    misalignLowData = (addrLow4 > 4'd8) ? XLEN'(rdcache_resp.data_delayed[127:64] >> {addrLow4[2:0], 3'b0}) : '0;
    // 跨 16B 的高半：低半已存在 combinedData 低 (16-偏移) 字节里，再拼上第二个窗口开头的 (偏移-8) 字节
    case (addrLow4)
      4'd9:    misalignCombinedData = {rdcache_resp.data_delayed[7:0],  combinedData[55:0]};
      4'd10:   misalignCombinedData = {rdcache_resp.data_delayed[15:0], combinedData[47:0]};
      4'd11:   misalignCombinedData = {rdcache_resp.data_delayed[23:0], combinedData[39:0]};
      4'd12:   misalignCombinedData = {rdcache_resp.data_delayed[31:0], combinedData[31:0]};
      4'd13:   misalignCombinedData = {rdcache_resp.data_delayed[39:0], combinedData[23:0]};
      4'd14:   misalignCombinedData = {rdcache_resp.data_delayed[47:0], combinedData[15:0]};
      4'd15:   misalignCombinedData = {rdcache_resp.data_delayed[55:0], combinedData[7:0]};
      default: misalignCombinedData = '0;
    endcase
    shiftData = XLEN'(rdcache_resp.data_delayed >> {addrLow4, 3'b0});     // 128 位访问：直接移到元素处
    rawElem   = isMisalignReg ? (notCross16ByteReg ? shiftData : combinedData) : cacheData;
    case (instMicroOp_alignedType[1:0])                                    // 按元素宽度截断（rdataVecHelper）
      2'd0:    pickData = XLEN'(rawElem[7:0]);
      2'd1:    pickData = XLEN'(rawElem[15:0]);
      2'd2:    pickData = XLEN'(rawElem[31:0]);
      default: pickData = rawElem;
    endcase
    // 把元素写进目的寄存器 data[splitPtr] 的第 elemIdxInVd 个槽（mergeDataWithElemIdx）
    mergedData = data[splitPtr_value];
    case (instMicroOp_alignedType[1:0])
      2'd0:    for (int b = 0; b < 16; b++) if (elemIdxInVd[3:0] == 4'(b)) mergedData[b*8  +: 8]  = pickData[7:0];
      2'd1:    for (int b = 0; b < 8;  b++) if (elemIdxInVd[2:0] == 3'(b)) mergedData[b*16 +: 16] = pickData[15:0];
      2'd2:    for (int b = 0; b < 4;  b++) if (elemIdxInVd[1:0] == 2'(b)) mergedData[b*32 +: 32] = pickData[31:0];
      default: for (int b = 0; b < 2;  b++) if (elemIdxInVd[0]   == 1'(b)) mergedData[b*64 +: 64] = pickData;
    endcase
  end

  // 目的寄存器 data[i]：s_latch_and_merge_data 时写拼好的数据，否则入队时写 vs3（store 数据）
  logic mergeNow;
  assign mergeNow = (state == S_LATCH_AND_MERGE_DATA) & segmentActive;
  for (genvar i = 0; i < Q; i++) begin : g_data
    assign data_we[i]    = mergeNow & (splitPtr_value == 3'(i)) | uopq_we[i];
    assign data_wdata[i] = (mergeNow & (splitPtr_value == 3'(i))) ? mergedData : in.src_2;
  end

  // ===================================================================
  // §6 store：取出元素数据，经流水缓冲写 sbuffer
  // ===================================================================
  logic [VLEN-1:0]   flowData;            // 元素数据铺满 128 位
  logic [15:0]       wmask, bmask;        // 元素的字节掩码（已移位 / 未移位）
  logic [31:0]       cross16Mask;         // 跨 16B：两个窗口的字节掩码
  logic [254:0]      shiftedData;         // flowData 左移到地址低 4 位处（跨 16B 时高半在 [254:128]）
  logic [49:0]       vaddrLow, vaddrHigh; // 跨 16B 两半的虚地址（8 字节对齐）
  logic [PADDR_W-1:0] paddrLow, paddrHigh;
  seg_sbuf_t          sbufferOut;

  assign flowData    = store_elem_data(data[splitPtr_value], elemIdxInVd[4:0], instMicroOp_alignedType);
  assign bmask       = access_mask128(4'b0, 3'(instMicroOp_alignedType[1:0])) & {16{segmentActive}};
  assign wmask       = access_mask128(addrLow4, 3'(instMicroOp_alignedType[1:0])) & {16{segmentActive}};
  assign cross16Mask = 32'(bmask) << addrLow4;
  assign shiftedData = 255'(flowData) << {addrLow4, 3'b0};
  assign vaddrLow    = {latchVaddr[49:3], 3'b0};
  assign vaddrHigh   = vaddrLow + 50'd8;
  assign paddrLow    = {lowPagePaddr[PADDR_W-1:3], 3'b0};
  assign paddrHigh   = {instMicroOp_paddr[PADDR_W-1:3], 3'b0};

  assign sbufferOut_valid = (state == S_SEND_DATA) & segmentActive;
  always_comb begin
    sbufferOut          = '0;
    sbufferOut.vecValid = sbufferOut_valid;
    if (isMisalignReg) begin
      if (notCross16ByteReg) begin          // 没跨 16B：一次 128 位访问，地址对齐到 16B
        sbufferOut.vaddr = {latchVaddr[49:4], 4'b0};
        sbufferOut.data  = shiftedData[VLEN-1:0];
        sbufferOut.mask  = wmask;
        sbufferOut.addr  = {instMicroOp_paddr[PADDR_W-1:4], 4'b0};
      end else begin                        // 跨 16B：按 curPtr 发低半 / 高半
        sbufferOut.vaddr = curPtr ? vaddrHigh : vaddrLow;
        sbufferOut.data  = curPtr ? VLEN'(shiftedData[254:128]) : shiftedData[VLEN-1:0];
        sbufferOut.mask  = curPtr ? cross16Mask[31:16] : cross16Mask[15:0];
        sbufferOut.addr  = curPtr ? paddrHigh : paddrLow;
      end
    end else begin
      sbufferOut.vaddr = latchVaddr[49:0];
      sbufferOut.data  = flowData;
      sbufferOut.mask  = wmask;
      sbufferOut.addr  = instMicroOp_paddr;
    end
  end
  // 送 sbuffer 的一级流水缓冲（已签核的 NewPipelineConnectPipe_33）
  // BEGIN GENERATED(pipe) —— scripts/gen_vsegmentunit.py 生成，勿手改
  NewPipelineConnectPipe_33 VSegmentUnitPipelineConnect (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_ready            (pipe_in_ready),
    .io_in_valid            (sbufferOut_valid),
    .io_in_bits_vaddr       (sbufferOut.vaddr),
    .io_in_bits_data        (sbufferOut.data),
    .io_in_bits_mask        (sbufferOut.mask),
    .io_in_bits_addr        (sbufferOut.addr),
    .io_in_bits_vecValid    (sbufferOut.vecValid),
    .io_out_ready           (sbuffer_ready),
    .io_out_valid           (pipe_out_valid),
    .io_out_bits_vaddr      (sbuffer.vaddr),
    .io_out_bits_data       (sbuffer.data),
    .io_out_bits_mask       (sbuffer.mask),
    .io_out_bits_addr       (sbuffer.addr),
    .io_out_bits_vecValid   (sbuffer.vecValid),
    .io_rightOutFire        (sbufferFire)
  );
  // END GENERATED(pipe)
  assign sbuffer_valid = pipe_out_valid;

  // ===================================================================
  // §7 指针与计数的推进
  // ===================================================================
  logic       fieldActiveWriteFinish;   // 本 field 的 store 数据已被流水缓冲收下
  logic       sendDataLeaving;          // s_send_data 这一拍要离开
  logic       segmentInactiveFinish;    // 本段不活跃，直接跳到下一段
  logic       fieldDone;                // fieldIdx == nf
  logic       segmentDone;              // segmentIdx == vl-1
  logic       stepField;                // 本拍推进一个 field
  logic       stepSegment;              // 本拍推进一个段（所有 field 做完）
  logic [3:0] splitPtrOffset;           // 同一段的下一个 field 对应的目的寄存器相距几个（★取自入口 uop 的 lmul/emul★）
  logic [3:0] splitPtrNext;
  logic [8:0] segmentIdxPlus1;
  logic [3:0] fieldIdxWire;
  logic [7:0] segmentIdxWire;
  logic [2:0] stridePtr_value;
  logic       mergeOrWrite;             // state==9 或 s_send_data 写完一个活跃 field

  assign fieldActiveWriteFinish = sbufferOut_fire & segmentActive;
  assign sendDataLeaving        = (state == S_SEND_DATA) & (stateNext != S_SEND_DATA);
  assign segmentInactiveFinish  = ((state == S_LATCH_AND_MERGE_DATA) | sendDataLeaving) & ~segmentActive;
  assign fieldDone              = (fieldIdx == maxNfields);
  assign segmentDone            = (segmentIdx == maxSegIdx);
  assign stepField              = (state == S_LATCH_AND_MERGE_DATA) & segmentActive | sendDataLeaving & fieldActiveWriteFinish;
  assign mergeOrWrite           = (state == S_LATCH_AND_MERGE_DATA) | sendDataLeaving & fieldActiveWriteFinish;
  assign stepSegment            = fieldDone & mergeOrWrite;
  assign segmentIdxPlus1        = 9'(segmentIdx) + 9'd1;
  always_comb begin
    logic [7:0] lmulRegs, emulRegs;
    lmulRegs = 8'h1 << inLmul;
    emulRegs = 8'h1 << inEmul;
    splitPtrOffset = in.uop.fuOpType[5] ? (($signed(inLmul) < 0) ? 4'd1 : lmulRegs[3:0])
                                        : (($signed(inEmul) < 0) ? 4'd1 : emulRegs[3:0]);
    // 本段做完（或本段不活跃）→ 下一段的第 0 个 field：deqPtr + 段号 / 每寄存器元素数；否则下一个 field
    if (fieldDone | ~segmentActive)
      splitPtrNext = {deqPtr_flag, deqPtr_value} + 4'(segmentIdxPlus1 >> issueUopFlowNumLog2);
    else
      splitPtrNext = {splitPtr_flag, splitPtr_value} + splitPtrOffset;
    // 下一拍的 fieldIdx / segmentIdx（给 nextBaseVaddr / stridePtrReg 提前算）
    if (firstUopFire)                 fieldIdxWire = 4'd0;
    else if (stepField)               fieldIdxWire = fieldDone ? 4'd0 : fieldIdx + 4'd1;
    else if (segmentInactiveFinish)   fieldIdxWire = 4'd0;
    else                              fieldIdxWire = fieldIdx;
    if (firstUopFire)                                   segmentIdxWire = 8'd0;
    else if (stepSegment & ~segmentDone)                segmentIdxWire = segmentIdxPlus1[7:0];
    else if (segmentInactiveFinish & ~segmentDone)      segmentIdxWire = segmentIdxPlus1[7:0];
    else                                                segmentIdxWire = segmentIdx;
  end
  // indexed：第 segmentIdx 个下标在第 segmentIdx / (每 index 寄存器的元素数) 个 index 寄存器里
  assign stridePtr_value = 3'({deqPtr_flag, deqPtr_value} + (issueIsIndexed ? 4'((8'(segmentIdx) >> issueMaxIdxInIndexLog2)) : 4'd0));

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      instMicroOpValid <= 1'b0;
      enqPtr_flag <= 1'b0; enqPtr_value <= 3'd0;
      deqPtr_flag <= 1'b0; deqPtr_value <= 3'd0;
      stridePtrReg_value <= 3'd0;
      segmentIdx <= 8'd0;
      fieldIdx <= 4'd0;
      segmentOffset <= '0;
      splitPtr_flag <= 1'b0; splitPtr_value <= 3'd0;
      latchVaddr <= '0; latchVaddrDup <= '0;
      fofBufferValid <= 1'b0;
      state <= S_IDLE;
      curPtr <= 1'b0;
      isMisalignReg <= 1'b0;
      notCross16ByteReg <= 1'b0;
      combinedData <= '0;
      lowPagePaddr <= '0;
      triggerDebugMode <= 1'b0;
      triggerBreakpoint <= 1'b0;
      last_REG <= 1'b0;
      nextBaseVaddr_r <= '0;
    end else begin
      instMicroOpValid <= (stateNext != S_IDLE) & (instMicroOp_load | instMicroOpValid);
      if (uopEnqueue) {enqPtr_flag, enqPtr_value} <= {enqPtr_flag, enqPtr_value} + 4'd1;
      if ((state == S_FINISH) & queueNonEmpty) {deqPtr_flag, deqPtr_value} <= {deqPtr_flag, deqPtr_value} + 4'd1;
      stridePtrReg_value <= deqPtr_value + (issueIsIndexed ? 3'(segmentIdxWire >> issueMaxIdxInIndexLog2) : 3'd0);
      if (firstUopFire)                                segmentIdx <= 8'd0;
      else if (stepSegment & ~segmentDone)             segmentIdx <= segmentIdxPlus1[7:0];
      else if (segmentInactiveFinish & ~segmentDone)   segmentIdx <= segmentIdxPlus1[7:0];
      if (firstUopFire)                 fieldIdx <= 4'd0;
      else if (stepField)               fieldIdx <= fieldDone ? 4'd0 : fieldIdx + 4'd1;
      else if (segmentInactiveFinish)   fieldIdx <= 4'd0;
      // 段偏移：unit-stride 每段加 (nf+1)*元素字节数；strided 加 stride；indexed 不用（从 index 向量取）
      if (stepSegment | segmentInactiveFinish)
        segmentOffset <= segmentOffset + ((instMicroOp_uop_q.fuOpType[6:5] == 2'b00)
                                          ? XLEN'(7'(maxNfields + 4'd1) << issueEew)
                                          : stride[stridePtr_value][XLEN-1:0]);
      else if (instMicroOp_load)
        segmentOffset <= '0;
      if ((state == S_LATCH_AND_MERGE_DATA) | sendDataLeaving & (fieldActiveWriteFinish | ~segmentActive))
        {splitPtr_flag, splitPtr_value} <= splitPtrNext;
      else if (firstUopFire)
        {splitPtr_flag, splitPtr_value} <= {deqPtr_flag, deqPtr_value};
      if ((state == S_TLB_REQ) & ~isMisalignReg) begin
        latchVaddr    <= vaddr;
        latchVaddrDup <= vaddr;
      end
      fofBufferValid <= ~fofFixVlValid & (fofBuffer_load | fofBufferValid);
      state <= stateNext;
      // 跨 16B 非对齐的两半切换：load 在存完低半时翻到高半；store 在 s_pm 判出非对齐时翻、发完一半时翻
      if ((state == S_FINISH) | (state == S_LATCH_AND_MERGE_DATA) | sendDataLeaving) begin
        isMisalignReg     <= 1'b0;
        notCross16ByteReg <= 1'b0;
        curPtr            <= 1'b0;
      end else begin
        if (instMicroOp_isVSegLoad) begin
          if (isMisalignReg & ~notCross16ByteReg & (state == S_MISALIGN_MERGE_DATA)) curPtr <= 1'b1;
        end else begin
          if (isMisalignWire & ~notCross16ByteReg & (state == S_PM))
            curPtr <= ~curPtr;
          else if (isMisalignReg & ~notCross16ByteReg & (state == S_PM) & (stateNext == S_SEND_DATA))
            curPtr <= 1'b0;
          else if (isMisalignReg & ~notCross16ByteReg & (state == S_SEND_DATA) & (stateNext == S_SEND_DATA) & sbufferOut_fire)
            curPtr <= ~curPtr;
        end
        if ((state == S_PM) & isMisalignWire & ~anyException) begin
          notCross16ByteReg <= notCross16ByteWire;
          isMisalignReg     <= 1'b1;
        end else if (instMicroOp_load) begin
          notCross16ByteReg <= 1'b0;
          isMisalignReg     <= 1'b0;
        end
      end
      if ((state == S_MISALIGN_MERGE_DATA) & segmentActive)
        combinedData <= curPtr ? misalignCombinedData : misalignLowData;
      if (tlbRespHit & ~curPtr) lowPagePaddr <= dtlb_resp.paddr_0;
      if (state == S_TLB_REQ) begin
        triggerDebugMode  <= (triggerAction == 4'h1);
        triggerBreakpoint <= (triggerAction == 4'h0);
      end
      last_REG <= csrCtrl_cache_error_enable;
      if (stateNext == S_TLB_REQ)
        nextBaseVaddr_r <= instMicroOp_baseVaddr + XLEN'(11'(fieldIdxWire) << instMicroOp_alignedType);
    end
  end

  // ===================================================================
  // §8 fof 的最后一条 uop 单独存着（fofBuffer），等前面都写回了再用它修 vl
  // ===================================================================
  assign fofFixVlValid  = (state == S_FOF_FIX_VL) & fofBufferValid;
  assign fofBuffer_load = isEnqFixVlUop & ~fofBufferValid;
  assign fofBuffer_we   = fofFixVlValid | fofBuffer_load;
  assign fofBuffer_wdata = fofFixVlValid ? '0 : in.uop;        // 用完清零（RegInit 的复位值也是 0）

  // ===================================================================
  // §9 写回 / 反馈 / 异常上报（s_finish 态逐条 uop 出队）
  // ===================================================================
  logic [2:0] vdIdxInField;
  logic [1:0] realEw;
  logic [15:0] maskUsed;              // 本 uop 对应目的寄存器的那一段 mask（按元素宽度切 8 份）
  seg_uop_t   deqUop;

  assign deqUop        = uopq_uop[deqPtr_value];
  assign writebackValid = (state == S_FINISH) & queueNonEmpty | fofFixVlValid;
  assign feedbackValid  = (state == S_FINISH) & queueNonEmpty;
  // ★instType 取的是入口 uop 的 fuOpType（Chisel 里 instType 是入队侧的 val）★
  assign vdIdxInField = uop_idx_in_field(in.uop.fuOpType[5] ? issueLmul : issueEmul, deqUop.vpu_vuopIdx);
  assign realEw       = issueIsIndexed ? issueSew : issueEew;
  always_comb begin
    maskUsed = '0;
    for (int i = 0; i < 8; i++) begin
      if (vdIdxInField == 3'(i)) begin
        case (realEw)
          2'd0:    maskUsed = instMicroOp_mask[i*16 +: 16];
          2'd1:    maskUsed = 16'(instMicroOp_mask[i*8 +: 8]);
          2'd2:    maskUsed = 16'(instMicroOp_mask[i*4 +: 4]);
          default: maskUsed = 16'(instMicroOp_mask[i*2 +: 2]);
        endcase
      end
    end
  end

  always_comb begin
    writebackOut = '0;
    if (fofFixVlValid) begin
      writebackOut.uop           = fofBuffer;
      writebackOut.uop.vpu_vl    = instMicroOp_exceptionVl_bits;
      writebackOut.uop.vpu_vmask = '1;
      writebackOut.data          = VLEN'(instMicroOp_exceptionVl_bits);
    end else begin
      // 出队 uop 的 vecWen / pdest / debugInfo 等取队列里这条 uop 自己的；vpu / 异常 / 触发器取指令级的
      writebackOut.uop             = deqUop;
      writebackOut.uop.vpu_vill          = instMicroOp_uop_q.vpu_vill;
      writebackOut.uop.vpu_vma           = instMicroOp_uop_q.vpu_vma;
      writebackOut.uop.vpu_vta           = instMicroOp_uop_q.vpu_vta;
      writebackOut.uop.vpu_vsew          = instMicroOp_uop_q.vpu_vsew;
      writebackOut.uop.vpu_vlmul         = instMicroOp_uop_q.vpu_vlmul;
      writebackOut.uop.vpu_specVill      = instMicroOp_uop_q.vpu_specVill;
      writebackOut.uop.vpu_specVma       = instMicroOp_uop_q.vpu_specVma;
      writebackOut.uop.vpu_specVta       = instMicroOp_uop_q.vpu_specVta;
      writebackOut.uop.vpu_specVsew      = instMicroOp_uop_q.vpu_specVsew;
      writebackOut.uop.vpu_specVlmul     = instMicroOp_uop_q.vpu_specVlmul;
      writebackOut.uop.vpu_vm            = instMicroOp_uop_q.vpu_vm;
      writebackOut.uop.vpu_frm           = instMicroOp_uop_q.vpu_frm;
      writebackOut.uop.vpu_fpu_isFpToVecInst = instMicroOp_uop_q.vpu_fpu_isFpToVecInst;
      writebackOut.uop.vpu_fpu_isFP32Instr   = instMicroOp_uop_q.vpu_fpu_isFP32Instr;
      writebackOut.uop.vpu_fpu_isFP64Instr   = instMicroOp_uop_q.vpu_fpu_isFP64Instr;
      writebackOut.uop.vpu_fpu_isReduction   = instMicroOp_uop_q.vpu_fpu_isReduction;
      writebackOut.uop.vpu_fpu_isFoldTo1_2   = instMicroOp_uop_q.vpu_fpu_isFoldTo1_2;
      writebackOut.uop.vpu_fpu_isFoldTo1_4   = instMicroOp_uop_q.vpu_fpu_isFoldTo1_4;
      writebackOut.uop.vpu_fpu_isFoldTo1_8   = instMicroOp_uop_q.vpu_fpu_isFoldTo1_8;
      writebackOut.uop.vpu_vxrm          = instMicroOp_uop_q.vpu_vxrm;
      writebackOut.uop.vpu_lastUop       = instMicroOp_uop_q.vpu_lastUop;
      writebackOut.uop.vpu_nf            = instMicroOp_uop_q.vpu_nf;
      writebackOut.uop.vpu_veew          = instMicroOp_uop_q.vpu_veew;
      writebackOut.uop.vpu_isReverse     = instMicroOp_uop_q.vpu_isReverse;
      writebackOut.uop.vpu_isExt         = instMicroOp_uop_q.vpu_isExt;
      writebackOut.uop.vpu_isNarrow      = instMicroOp_uop_q.vpu_isNarrow;
      writebackOut.uop.vpu_isDstMask     = instMicroOp_uop_q.vpu_isDstMask;
      writebackOut.uop.vpu_isOpMask      = instMicroOp_uop_q.vpu_isOpMask;
      writebackOut.uop.vpu_isMove        = instMicroOp_uop_q.vpu_isMove;
      writebackOut.uop.vpu_isDependOldVd = instMicroOp_uop_q.vpu_isDependOldVd;
      writebackOut.uop.vpu_isWritePartVd = instMicroOp_uop_q.vpu_isWritePartVd;
      writebackOut.uop.vpu_isVleff       = instMicroOp_uop_q.vpu_isVleff;
      writebackOut.uop.trigger       = instMicroOp_uop_trigger;
      writebackOut.uop.exceptionVec  = instExcVec;
      writebackOut.uop.vpu_vl        = instMicroOp_vl;
      writebackOut.uop.vpu_vstart    = ((|instExcVec) | (instMicroOp_uop_trigger == 4'h1)) ? instMicroOp_exceptionVstart : 8'h0;
      writebackOut.uop.vpu_vmask     = VLEN'(maskUsed);
      writebackOut.uop.vpu_vuopIdx   = deqUop.vpu_vuopIdx;
      writebackOut.uop.robIdx_flag   = instMicroOp_uop_q.robIdx_flag;
      writebackOut.uop.robIdx_value  = instMicroOp_uop_q.robIdx_value;
      writebackOut.uop.fuOpType      = instMicroOp_uop_q.fuOpType;
      writebackOut.data              = data[deqPtr_value];
    end
  end
  always_ff @(posedge clock) begin
    io_uopwriteback_valid_REG <= writebackValid;
    if (writebackValid & ~fofFixVlValid) begin        // fof 修 vl 的那条不改 vdIdx（保持上一次的）
      io_uopwriteback_bits_r_vdIdx        <= vdIdxInField;
      io_uopwriteback_bits_r_vdIdxInField <= vdIdxInField;
    end
    io_feedback_valid_REG <= feedbackValid;
  end
  assign uopwriteback_valid = io_uopwriteback_valid_REG;
  always_comb begin
    uopwriteback              = uopwriteback_r;
    uopwriteback.vdIdx        = io_uopwriteback_bits_r_vdIdx;
    uopwriteback.vdIdxInField = io_uopwriteback_bits_r_vdIdxInField;
  end

  always_comb begin
    feedbackOut              = '0;
    feedbackOut.robIdx_flag  = instMicroOp_uop_q.robIdx_flag;
    feedbackOut.robIdx_value = instMicroOp_uop_q.robIdx_value;
    feedbackOut.sqIdx_flag   = deqUop.sqIdx_flag;
    feedbackOut.sqIdx_value  = deqUop.sqIdx_value;
    feedbackOut.lqIdx_flag   = deqUop.lqIdx_flag;
    feedbackOut.lqIdx_value  = deqUop.lqIdx_value;
  end
  assign feedback_valid = io_feedback_valid_REG;
  assign feedback       = feedback_r;

  assign exceptionInfo_valid = (state == S_FINISH) & (|instExcVec) & queueNonEmpty;
  always_comb begin
    exceptionInfo                   = '0;
    exceptionInfo.vaddr             = instMicroOp_exceptionVaddr;
    exceptionInfo.gpaddr            = instMicroOp_exceptionGpaddr;
    exceptionInfo.isForVSnonLeafPTE = instMicroOp_exceptionIsForVSnonLeafPTE;
  end

  // ---- 其余输出 ----
  assign flush_sbuffer_valid = ~flush_sbuffer_empty & ((state == S_FLUSH_SBUFFER_REQ) | (state == S_WAIT_FLUSH_SBUFFER_RESP));
  always_comb begin
    vecDifftestInfo              = '0;
    vecDifftestInfo.uop          = deqUop;
  end

endmodule

// =====================================================================
// VSegmentUnit —— golden 同名 wrapper（生成）：扁平端口 ↔ struct 拆装 + 大块 payload 寄存器
// =====================================================================
// BEGIN GENERATED(wrapper) —— scripts/gen_vsegmentunit.py 生成，勿手改
module VSegmentUnit
  import vlsu_pkg::*;
  import vsegment_pkg::*;
(
  input          clock,
  input          reset,
  input          io_in_valid,
  input  [34:0]  io_in_bits_uop_fuType,
  input  [8:0]   io_in_bits_uop_fuOpType,
  input          io_in_bits_uop_vecWen,
  input          io_in_bits_uop_v0Wen,
  input          io_in_bits_uop_vlWen,
  input          io_in_bits_uop_vpu_vill,
  input          io_in_bits_uop_vpu_vma,
  input          io_in_bits_uop_vpu_vta,
  input  [1:0]   io_in_bits_uop_vpu_vsew,
  input  [2:0]   io_in_bits_uop_vpu_vlmul,
  input          io_in_bits_uop_vpu_specVill,
  input          io_in_bits_uop_vpu_specVma,
  input          io_in_bits_uop_vpu_specVta,
  input  [1:0]   io_in_bits_uop_vpu_specVsew,
  input  [2:0]   io_in_bits_uop_vpu_specVlmul,
  input          io_in_bits_uop_vpu_vm,
  input  [7:0]   io_in_bits_uop_vpu_vstart,
  input  [2:0]   io_in_bits_uop_vpu_frm,
  input          io_in_bits_uop_vpu_fpu_isFpToVecInst,
  input          io_in_bits_uop_vpu_fpu_isFP32Instr,
  input          io_in_bits_uop_vpu_fpu_isFP64Instr,
  input          io_in_bits_uop_vpu_fpu_isReduction,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_2,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_4,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_in_bits_uop_vpu_vxrm,
  input  [6:0]   io_in_bits_uop_vpu_vuopIdx,
  input          io_in_bits_uop_vpu_lastUop,
  input  [2:0]   io_in_bits_uop_vpu_nf,
  input  [1:0]   io_in_bits_uop_vpu_veew,
  input          io_in_bits_uop_vpu_isReverse,
  input          io_in_bits_uop_vpu_isExt,
  input          io_in_bits_uop_vpu_isNarrow,
  input          io_in_bits_uop_vpu_isDstMask,
  input          io_in_bits_uop_vpu_isOpMask,
  input          io_in_bits_uop_vpu_isMove,
  input          io_in_bits_uop_vpu_isDependOldVd,
  input          io_in_bits_uop_vpu_isWritePartVd,
  input          io_in_bits_uop_vpu_isVleff,
  input  [7:0]   io_in_bits_uop_pdest,
  input          io_in_bits_uop_robIdx_flag,
  input  [7:0]   io_in_bits_uop_robIdx_value,
  input          io_in_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_uop_debugInfo_renameTime,
  input  [63:0]  io_in_bits_uop_debugInfo_dispatchTime,
  input  [63:0]  io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_bits_uop_debugInfo_issueTime,
  input  [63:0]  io_in_bits_uop_debugInfo_writebackTime,
  input  [63:0]  io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_uop_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_uop_debug_seqNum_uopIdx,
  input          io_in_bits_uop_lqIdx_flag,
  input  [6:0]   io_in_bits_uop_lqIdx_value,
  input          io_in_bits_uop_sqIdx_flag,
  input  [5:0]   io_in_bits_uop_sqIdx_value,
  input  [127:0] io_in_bits_src_0,
  input  [127:0] io_in_bits_src_1,
  input  [127:0] io_in_bits_src_2,
  input  [127:0] io_in_bits_src_3,
  input  [127:0] io_in_bits_src_4,
  output         io_uopwriteback_valid,
  output         io_uopwriteback_bits_uop_exceptionVec_3,
  output         io_uopwriteback_bits_uop_exceptionVec_5,
  output         io_uopwriteback_bits_uop_exceptionVec_7,
  output         io_uopwriteback_bits_uop_exceptionVec_13,
  output         io_uopwriteback_bits_uop_exceptionVec_15,
  output         io_uopwriteback_bits_uop_exceptionVec_19,
  output         io_uopwriteback_bits_uop_exceptionVec_21,
  output         io_uopwriteback_bits_uop_exceptionVec_23,
  output [3:0]   io_uopwriteback_bits_uop_trigger,
  output [8:0]   io_uopwriteback_bits_uop_fuOpType,
  output         io_uopwriteback_bits_uop_vecWen,
  output         io_uopwriteback_bits_uop_v0Wen,
  output         io_uopwriteback_bits_uop_vlWen,
  output         io_uopwriteback_bits_uop_vpu_vill,
  output         io_uopwriteback_bits_uop_vpu_vma,
  output         io_uopwriteback_bits_uop_vpu_vta,
  output [1:0]   io_uopwriteback_bits_uop_vpu_vsew,
  output [2:0]   io_uopwriteback_bits_uop_vpu_vlmul,
  output         io_uopwriteback_bits_uop_vpu_specVill,
  output         io_uopwriteback_bits_uop_vpu_specVma,
  output         io_uopwriteback_bits_uop_vpu_specVta,
  output [1:0]   io_uopwriteback_bits_uop_vpu_specVsew,
  output [2:0]   io_uopwriteback_bits_uop_vpu_specVlmul,
  output         io_uopwriteback_bits_uop_vpu_vm,
  output [7:0]   io_uopwriteback_bits_uop_vpu_vstart,
  output [2:0]   io_uopwriteback_bits_uop_vpu_frm,
  output         io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst,
  output         io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr,
  output         io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr,
  output         io_uopwriteback_bits_uop_vpu_fpu_isReduction,
  output         io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2,
  output         io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4,
  output         io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_uopwriteback_bits_uop_vpu_vxrm,
  output [6:0]   io_uopwriteback_bits_uop_vpu_vuopIdx,
  output         io_uopwriteback_bits_uop_vpu_lastUop,
  output [127:0] io_uopwriteback_bits_uop_vpu_vmask,
  output [7:0]   io_uopwriteback_bits_uop_vpu_vl,
  output [2:0]   io_uopwriteback_bits_uop_vpu_nf,
  output [1:0]   io_uopwriteback_bits_uop_vpu_veew,
  output         io_uopwriteback_bits_uop_vpu_isReverse,
  output         io_uopwriteback_bits_uop_vpu_isExt,
  output         io_uopwriteback_bits_uop_vpu_isNarrow,
  output         io_uopwriteback_bits_uop_vpu_isDstMask,
  output         io_uopwriteback_bits_uop_vpu_isOpMask,
  output         io_uopwriteback_bits_uop_vpu_isMove,
  output         io_uopwriteback_bits_uop_vpu_isDependOldVd,
  output         io_uopwriteback_bits_uop_vpu_isWritePartVd,
  output         io_uopwriteback_bits_uop_vpu_isVleff,
  output [7:0]   io_uopwriteback_bits_uop_pdest,
  output         io_uopwriteback_bits_uop_robIdx_flag,
  output [7:0]   io_uopwriteback_bits_uop_robIdx_value,
  output         io_uopwriteback_bits_uop_debugInfo_eliminatedMove,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_renameTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_dispatchTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_selectTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_issueTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_writebackTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]  io_uopwriteback_bits_uop_debugInfo_tlbRespTime,
  output [55:0]  io_uopwriteback_bits_uop_debug_seqNum_seqNum,
  output [7:0]   io_uopwriteback_bits_uop_debug_seqNum_uopIdx,
  output [127:0] io_uopwriteback_bits_data,
  output [2:0]   io_uopwriteback_bits_vdIdx,
  output [2:0]   io_uopwriteback_bits_vdIdxInField,
  output         io_uopwriteback_bits_debug_isMMIO,
  output         io_uopwriteback_bits_debug_isNCIO,
  output         io_uopwriteback_bits_debug_isPerfCnt,
  output [47:0]  io_uopwriteback_bits_debug_paddr,
  output [49:0]  io_uopwriteback_bits_debug_vaddr,
  input          io_csrCtrl_cache_error_enable,
  input          io_rdcache_req_ready,
  output         io_rdcache_req_valid,
  output [49:0]  io_rdcache_req_bits_vaddr,
  output [49:0]  io_rdcache_req_bits_vaddr_dup,
  input          io_rdcache_resp_valid,
  input  [127:0] io_rdcache_resp_bits_data_delayed,
  input          io_rdcache_resp_bits_miss,
  input          io_rdcache_resp_bits_tl_error_delayed_tl_denied,
  input          io_rdcache_resp_bits_tl_error_delayed_tl_corrupt,
  output         io_rdcache_is128Req,
  output [47:0]  io_rdcache_s1_paddr_dup_lsu,
  output [47:0]  io_rdcache_s1_paddr_dup_dcache,
  input          io_rdcache_s2_bank_conflict,
  input          io_sbuffer_ready,
  output         io_sbuffer_valid,
  output [49:0]  io_sbuffer_bits_vaddr,
  output [127:0] io_sbuffer_bits_data,
  output [15:0]  io_sbuffer_bits_mask,
  output [47:0]  io_sbuffer_bits_addr,
  output         io_sbuffer_bits_vecValid,
  output [34:0]  io_vecDifftestInfo_bits_uop_fuType,
  output [8:0]   io_vecDifftestInfo_bits_uop_fuOpType,
  output [2:0]   io_vecDifftestInfo_bits_uop_vpu_nf,
  output [1:0]   io_vecDifftestInfo_bits_uop_vpu_veew,
  output [7:0]   io_vecDifftestInfo_bits_uop_robIdx_value,
  output         io_dtlb_req_valid,
  output [49:0]  io_dtlb_req_bits_vaddr,
  output [63:0]  io_dtlb_req_bits_fullva,
  output [2:0]   io_dtlb_req_bits_cmd,
  output         io_dtlb_req_bits_debug_robIdx_flag,
  output [7:0]   io_dtlb_req_bits_debug_robIdx_value,
  input          io_dtlb_resp_valid,
  input  [47:0]  io_dtlb_resp_bits_paddr_0,
  input  [63:0]  io_dtlb_resp_bits_gpaddr_0,
  input  [63:0]  io_dtlb_resp_bits_fullva,
  input  [1:0]   io_dtlb_resp_bits_pbmt_0,
  input          io_dtlb_resp_bits_miss,
  input          io_dtlb_resp_bits_isForVSnonLeafPTE,
  input          io_dtlb_resp_bits_excp_0_gpf_ld,
  input          io_dtlb_resp_bits_excp_0_gpf_st,
  input          io_dtlb_resp_bits_excp_0_pf_ld,
  input          io_dtlb_resp_bits_excp_0_pf_st,
  input          io_dtlb_resp_bits_excp_0_af_ld,
  input          io_dtlb_resp_bits_excp_0_af_st,
  input          io_pmpResp_ld,
  input          io_pmpResp_st,
  input          io_pmpResp_instr,
  input          io_pmpResp_mmio,
  input          io_pmpResp_atomic,
  output         io_flush_sbuffer_valid,
  input          io_flush_sbuffer_empty,
  output         io_feedback_valid,
  output         io_feedback_bits_robIdx_flag,
  output [7:0]   io_feedback_bits_robIdx_value,
  output         io_feedback_bits_sqIdx_flag,
  output [5:0]   io_feedback_bits_sqIdx_value,
  output         io_feedback_bits_lqIdx_flag,
  output [6:0]   io_feedback_bits_lqIdx_value,
  output         io_exceptionInfo_valid,
  output [63:0]  io_exceptionInfo_bits_vaddr,
  output [63:0]  io_exceptionInfo_bits_gpaddr,
  output         io_exceptionInfo_bits_isForVSnonLeafPTE,
  input  [1:0]   io_fromCsrTrigger_tdataVec_0_matchType,
  input          io_fromCsrTrigger_tdataVec_0_select,
  input          io_fromCsrTrigger_tdataVec_0_timing,
  input  [3:0]   io_fromCsrTrigger_tdataVec_0_action,
  input          io_fromCsrTrigger_tdataVec_0_chain,
  input          io_fromCsrTrigger_tdataVec_0_store,
  input          io_fromCsrTrigger_tdataVec_0_load,
  input  [63:0]  io_fromCsrTrigger_tdataVec_0_tdata2,
  input  [1:0]   io_fromCsrTrigger_tdataVec_1_matchType,
  input          io_fromCsrTrigger_tdataVec_1_select,
  input          io_fromCsrTrigger_tdataVec_1_timing,
  input  [3:0]   io_fromCsrTrigger_tdataVec_1_action,
  input          io_fromCsrTrigger_tdataVec_1_chain,
  input          io_fromCsrTrigger_tdataVec_1_store,
  input          io_fromCsrTrigger_tdataVec_1_load,
  input  [63:0]  io_fromCsrTrigger_tdataVec_1_tdata2,
  input  [1:0]   io_fromCsrTrigger_tdataVec_2_matchType,
  input          io_fromCsrTrigger_tdataVec_2_select,
  input          io_fromCsrTrigger_tdataVec_2_timing,
  input  [3:0]   io_fromCsrTrigger_tdataVec_2_action,
  input          io_fromCsrTrigger_tdataVec_2_chain,
  input          io_fromCsrTrigger_tdataVec_2_store,
  input          io_fromCsrTrigger_tdataVec_2_load,
  input  [63:0]  io_fromCsrTrigger_tdataVec_2_tdata2,
  input  [1:0]   io_fromCsrTrigger_tdataVec_3_matchType,
  input          io_fromCsrTrigger_tdataVec_3_select,
  input          io_fromCsrTrigger_tdataVec_3_timing,
  input  [3:0]   io_fromCsrTrigger_tdataVec_3_action,
  input          io_fromCsrTrigger_tdataVec_3_chain,
  input          io_fromCsrTrigger_tdataVec_3_store,
  input          io_fromCsrTrigger_tdataVec_3_load,
  input  [63:0]  io_fromCsrTrigger_tdataVec_3_tdata2,
  input          io_fromCsrTrigger_tEnableVec_0,
  input          io_fromCsrTrigger_tEnableVec_1,
  input          io_fromCsrTrigger_tEnableVec_2,
  input          io_fromCsrTrigger_tEnableVec_3,
  input          io_fromCsrTrigger_debugMode,
  input          io_fromCsrTrigger_triggerCanRaiseBpExp
);

  seg_in_t       in;
  always_comb begin
    in = '0;
    in.uop.fuType = io_in_bits_uop_fuType;
    in.uop.fuOpType = io_in_bits_uop_fuOpType;
    in.uop.vecWen = io_in_bits_uop_vecWen;
    in.uop.v0Wen = io_in_bits_uop_v0Wen;
    in.uop.vlWen = io_in_bits_uop_vlWen;
    in.uop.vpu_vill = io_in_bits_uop_vpu_vill;
    in.uop.vpu_vma = io_in_bits_uop_vpu_vma;
    in.uop.vpu_vta = io_in_bits_uop_vpu_vta;
    in.uop.vpu_vsew = io_in_bits_uop_vpu_vsew;
    in.uop.vpu_vlmul = io_in_bits_uop_vpu_vlmul;
    in.uop.vpu_specVill = io_in_bits_uop_vpu_specVill;
    in.uop.vpu_specVma = io_in_bits_uop_vpu_specVma;
    in.uop.vpu_specVta = io_in_bits_uop_vpu_specVta;
    in.uop.vpu_specVsew = io_in_bits_uop_vpu_specVsew;
    in.uop.vpu_specVlmul = io_in_bits_uop_vpu_specVlmul;
    in.uop.vpu_vm = io_in_bits_uop_vpu_vm;
    in.uop.vpu_vstart = io_in_bits_uop_vpu_vstart;
    in.uop.vpu_frm = io_in_bits_uop_vpu_frm;
    in.uop.vpu_fpu_isFpToVecInst = io_in_bits_uop_vpu_fpu_isFpToVecInst;
    in.uop.vpu_fpu_isFP32Instr = io_in_bits_uop_vpu_fpu_isFP32Instr;
    in.uop.vpu_fpu_isFP64Instr = io_in_bits_uop_vpu_fpu_isFP64Instr;
    in.uop.vpu_fpu_isReduction = io_in_bits_uop_vpu_fpu_isReduction;
    in.uop.vpu_fpu_isFoldTo1_2 = io_in_bits_uop_vpu_fpu_isFoldTo1_2;
    in.uop.vpu_fpu_isFoldTo1_4 = io_in_bits_uop_vpu_fpu_isFoldTo1_4;
    in.uop.vpu_fpu_isFoldTo1_8 = io_in_bits_uop_vpu_fpu_isFoldTo1_8;
    in.uop.vpu_vxrm = io_in_bits_uop_vpu_vxrm;
    in.uop.vpu_vuopIdx = io_in_bits_uop_vpu_vuopIdx;
    in.uop.vpu_lastUop = io_in_bits_uop_vpu_lastUop;
    in.uop.vpu_nf = io_in_bits_uop_vpu_nf;
    in.uop.vpu_veew = io_in_bits_uop_vpu_veew;
    in.uop.vpu_isReverse = io_in_bits_uop_vpu_isReverse;
    in.uop.vpu_isExt = io_in_bits_uop_vpu_isExt;
    in.uop.vpu_isNarrow = io_in_bits_uop_vpu_isNarrow;
    in.uop.vpu_isDstMask = io_in_bits_uop_vpu_isDstMask;
    in.uop.vpu_isOpMask = io_in_bits_uop_vpu_isOpMask;
    in.uop.vpu_isMove = io_in_bits_uop_vpu_isMove;
    in.uop.vpu_isDependOldVd = io_in_bits_uop_vpu_isDependOldVd;
    in.uop.vpu_isWritePartVd = io_in_bits_uop_vpu_isWritePartVd;
    in.uop.vpu_isVleff = io_in_bits_uop_vpu_isVleff;
    in.uop.pdest = io_in_bits_uop_pdest;
    in.uop.robIdx_flag = io_in_bits_uop_robIdx_flag;
    in.uop.robIdx_value = io_in_bits_uop_robIdx_value;
    in.uop.debugInfo_eliminatedMove = io_in_bits_uop_debugInfo_eliminatedMove;
    in.uop.debugInfo_renameTime = io_in_bits_uop_debugInfo_renameTime;
    in.uop.debugInfo_dispatchTime = io_in_bits_uop_debugInfo_dispatchTime;
    in.uop.debugInfo_enqRsTime = io_in_bits_uop_debugInfo_enqRsTime;
    in.uop.debugInfo_selectTime = io_in_bits_uop_debugInfo_selectTime;
    in.uop.debugInfo_issueTime = io_in_bits_uop_debugInfo_issueTime;
    in.uop.debugInfo_writebackTime = io_in_bits_uop_debugInfo_writebackTime;
    in.uop.debugInfo_runahead_checkpoint_id = io_in_bits_uop_debugInfo_runahead_checkpoint_id;
    in.uop.debugInfo_tlbFirstReqTime = io_in_bits_uop_debugInfo_tlbFirstReqTime;
    in.uop.debugInfo_tlbRespTime = io_in_bits_uop_debugInfo_tlbRespTime;
    in.uop.debug_seqNum_seqNum = io_in_bits_uop_debug_seqNum_seqNum;
    in.uop.debug_seqNum_uopIdx = io_in_bits_uop_debug_seqNum_uopIdx;
    in.uop.lqIdx_flag = io_in_bits_uop_lqIdx_flag;
    in.uop.lqIdx_value = io_in_bits_uop_lqIdx_value;
    in.uop.sqIdx_flag = io_in_bits_uop_sqIdx_flag;
    in.uop.sqIdx_value = io_in_bits_uop_sqIdx_value;
    in.src_0 = io_in_bits_src_0;
    in.src_1 = io_in_bits_src_1;
    in.src_2 = io_in_bits_src_2;
    in.src_3 = io_in_bits_src_3;
    in.src_4 = io_in_bits_src_4;
  end

  seg_wb_t       uopwriteback;
  assign io_uopwriteback_bits_uop_exceptionVec_3 = uopwriteback.uop.exceptionVec[3];
  assign io_uopwriteback_bits_uop_exceptionVec_5 = uopwriteback.uop.exceptionVec[5];
  assign io_uopwriteback_bits_uop_exceptionVec_7 = uopwriteback.uop.exceptionVec[7];
  assign io_uopwriteback_bits_uop_exceptionVec_13 = uopwriteback.uop.exceptionVec[13];
  assign io_uopwriteback_bits_uop_exceptionVec_15 = uopwriteback.uop.exceptionVec[15];
  assign io_uopwriteback_bits_uop_exceptionVec_19 = uopwriteback.uop.exceptionVec[19];
  assign io_uopwriteback_bits_uop_exceptionVec_21 = uopwriteback.uop.exceptionVec[21];
  assign io_uopwriteback_bits_uop_exceptionVec_23 = uopwriteback.uop.exceptionVec[23];
  assign io_uopwriteback_bits_uop_trigger = uopwriteback.uop.trigger;
  assign io_uopwriteback_bits_uop_fuOpType = uopwriteback.uop.fuOpType;
  assign io_uopwriteback_bits_uop_vecWen = uopwriteback.uop.vecWen;
  assign io_uopwriteback_bits_uop_v0Wen = uopwriteback.uop.v0Wen;
  assign io_uopwriteback_bits_uop_vlWen = uopwriteback.uop.vlWen;
  assign io_uopwriteback_bits_uop_vpu_vill = uopwriteback.uop.vpu_vill;
  assign io_uopwriteback_bits_uop_vpu_vma = uopwriteback.uop.vpu_vma;
  assign io_uopwriteback_bits_uop_vpu_vta = uopwriteback.uop.vpu_vta;
  assign io_uopwriteback_bits_uop_vpu_vsew = uopwriteback.uop.vpu_vsew;
  assign io_uopwriteback_bits_uop_vpu_vlmul = uopwriteback.uop.vpu_vlmul;
  assign io_uopwriteback_bits_uop_vpu_specVill = uopwriteback.uop.vpu_specVill;
  assign io_uopwriteback_bits_uop_vpu_specVma = uopwriteback.uop.vpu_specVma;
  assign io_uopwriteback_bits_uop_vpu_specVta = uopwriteback.uop.vpu_specVta;
  assign io_uopwriteback_bits_uop_vpu_specVsew = uopwriteback.uop.vpu_specVsew;
  assign io_uopwriteback_bits_uop_vpu_specVlmul = uopwriteback.uop.vpu_specVlmul;
  assign io_uopwriteback_bits_uop_vpu_vm = uopwriteback.uop.vpu_vm;
  assign io_uopwriteback_bits_uop_vpu_vstart = uopwriteback.uop.vpu_vstart;
  assign io_uopwriteback_bits_uop_vpu_frm = uopwriteback.uop.vpu_frm;
  assign io_uopwriteback_bits_uop_vpu_fpu_isFpToVecInst = uopwriteback.uop.vpu_fpu_isFpToVecInst;
  assign io_uopwriteback_bits_uop_vpu_fpu_isFP32Instr = uopwriteback.uop.vpu_fpu_isFP32Instr;
  assign io_uopwriteback_bits_uop_vpu_fpu_isFP64Instr = uopwriteback.uop.vpu_fpu_isFP64Instr;
  assign io_uopwriteback_bits_uop_vpu_fpu_isReduction = uopwriteback.uop.vpu_fpu_isReduction;
  assign io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_2 = uopwriteback.uop.vpu_fpu_isFoldTo1_2;
  assign io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_4 = uopwriteback.uop.vpu_fpu_isFoldTo1_4;
  assign io_uopwriteback_bits_uop_vpu_fpu_isFoldTo1_8 = uopwriteback.uop.vpu_fpu_isFoldTo1_8;
  assign io_uopwriteback_bits_uop_vpu_vxrm = uopwriteback.uop.vpu_vxrm;
  assign io_uopwriteback_bits_uop_vpu_vuopIdx = uopwriteback.uop.vpu_vuopIdx;
  assign io_uopwriteback_bits_uop_vpu_lastUop = uopwriteback.uop.vpu_lastUop;
  assign io_uopwriteback_bits_uop_vpu_vmask = uopwriteback.uop.vpu_vmask;
  assign io_uopwriteback_bits_uop_vpu_vl = uopwriteback.uop.vpu_vl;
  assign io_uopwriteback_bits_uop_vpu_nf = uopwriteback.uop.vpu_nf;
  assign io_uopwriteback_bits_uop_vpu_veew = uopwriteback.uop.vpu_veew;
  assign io_uopwriteback_bits_uop_vpu_isReverse = uopwriteback.uop.vpu_isReverse;
  assign io_uopwriteback_bits_uop_vpu_isExt = uopwriteback.uop.vpu_isExt;
  assign io_uopwriteback_bits_uop_vpu_isNarrow = uopwriteback.uop.vpu_isNarrow;
  assign io_uopwriteback_bits_uop_vpu_isDstMask = uopwriteback.uop.vpu_isDstMask;
  assign io_uopwriteback_bits_uop_vpu_isOpMask = uopwriteback.uop.vpu_isOpMask;
  assign io_uopwriteback_bits_uop_vpu_isMove = uopwriteback.uop.vpu_isMove;
  assign io_uopwriteback_bits_uop_vpu_isDependOldVd = uopwriteback.uop.vpu_isDependOldVd;
  assign io_uopwriteback_bits_uop_vpu_isWritePartVd = uopwriteback.uop.vpu_isWritePartVd;
  assign io_uopwriteback_bits_uop_vpu_isVleff = uopwriteback.uop.vpu_isVleff;
  assign io_uopwriteback_bits_uop_pdest = uopwriteback.uop.pdest;
  assign io_uopwriteback_bits_uop_robIdx_flag = uopwriteback.uop.robIdx_flag;
  assign io_uopwriteback_bits_uop_robIdx_value = uopwriteback.uop.robIdx_value;
  assign io_uopwriteback_bits_uop_debugInfo_eliminatedMove = uopwriteback.uop.debugInfo_eliminatedMove;
  assign io_uopwriteback_bits_uop_debugInfo_renameTime = uopwriteback.uop.debugInfo_renameTime;
  assign io_uopwriteback_bits_uop_debugInfo_dispatchTime = uopwriteback.uop.debugInfo_dispatchTime;
  assign io_uopwriteback_bits_uop_debugInfo_enqRsTime = uopwriteback.uop.debugInfo_enqRsTime;
  assign io_uopwriteback_bits_uop_debugInfo_selectTime = uopwriteback.uop.debugInfo_selectTime;
  assign io_uopwriteback_bits_uop_debugInfo_issueTime = uopwriteback.uop.debugInfo_issueTime;
  assign io_uopwriteback_bits_uop_debugInfo_writebackTime = uopwriteback.uop.debugInfo_writebackTime;
  assign io_uopwriteback_bits_uop_debugInfo_runahead_checkpoint_id = uopwriteback.uop.debugInfo_runahead_checkpoint_id;
  assign io_uopwriteback_bits_uop_debugInfo_tlbFirstReqTime = uopwriteback.uop.debugInfo_tlbFirstReqTime;
  assign io_uopwriteback_bits_uop_debugInfo_tlbRespTime = uopwriteback.uop.debugInfo_tlbRespTime;
  assign io_uopwriteback_bits_uop_debug_seqNum_seqNum = uopwriteback.uop.debug_seqNum_seqNum;
  assign io_uopwriteback_bits_uop_debug_seqNum_uopIdx = uopwriteback.uop.debug_seqNum_uopIdx;
  assign io_uopwriteback_bits_data = uopwriteback.data;
  assign io_uopwriteback_bits_vdIdx = uopwriteback.vdIdx;
  assign io_uopwriteback_bits_vdIdxInField = uopwriteback.vdIdxInField;
  assign io_uopwriteback_bits_debug_isMMIO = uopwriteback.debug_isMMIO;
  assign io_uopwriteback_bits_debug_isNCIO = uopwriteback.debug_isNCIO;
  assign io_uopwriteback_bits_debug_isPerfCnt = uopwriteback.debug_isPerfCnt;
  assign io_uopwriteback_bits_debug_paddr = uopwriteback.debug_paddr;
  assign io_uopwriteback_bits_debug_vaddr = uopwriteback.debug_vaddr;

  seg_dcache_req_t rdcache_req;
  assign io_rdcache_req_bits_vaddr = rdcache_req.vaddr;
  assign io_rdcache_req_bits_vaddr_dup = rdcache_req.vaddr_dup;

  seg_dcache_resp_t rdcache_resp;
  always_comb begin
    rdcache_resp = '0;
    rdcache_resp.data_delayed = io_rdcache_resp_bits_data_delayed;
    rdcache_resp.miss = io_rdcache_resp_bits_miss;
    rdcache_resp.tl_error_delayed_tl_denied = io_rdcache_resp_bits_tl_error_delayed_tl_denied;
    rdcache_resp.tl_error_delayed_tl_corrupt = io_rdcache_resp_bits_tl_error_delayed_tl_corrupt;
  end

  seg_sbuf_t     sbuffer;
  assign io_sbuffer_bits_vaddr = sbuffer.vaddr;
  assign io_sbuffer_bits_data = sbuffer.data;
  assign io_sbuffer_bits_mask = sbuffer.mask;
  assign io_sbuffer_bits_addr = sbuffer.addr;
  assign io_sbuffer_bits_vecValid = sbuffer.vecValid;

  seg_difftest_t vecDifftestInfo;
  assign io_vecDifftestInfo_bits_uop_fuType = vecDifftestInfo.uop.fuType;
  assign io_vecDifftestInfo_bits_uop_fuOpType = vecDifftestInfo.uop.fuOpType;
  assign io_vecDifftestInfo_bits_uop_vpu_nf = vecDifftestInfo.uop.vpu_nf;
  assign io_vecDifftestInfo_bits_uop_vpu_veew = vecDifftestInfo.uop.vpu_veew;
  assign io_vecDifftestInfo_bits_uop_robIdx_value = vecDifftestInfo.uop.robIdx_value;

  seg_tlb_req_t  dtlb_req;
  assign io_dtlb_req_bits_vaddr = dtlb_req.vaddr;
  assign io_dtlb_req_bits_fullva = dtlb_req.fullva;
  assign io_dtlb_req_bits_cmd = dtlb_req.cmd;
  assign io_dtlb_req_bits_debug_robIdx_flag = dtlb_req.debug_robIdx_flag;
  assign io_dtlb_req_bits_debug_robIdx_value = dtlb_req.debug_robIdx_value;

  seg_tlb_resp_t dtlb_resp;
  always_comb begin
    dtlb_resp = '0;
    dtlb_resp.paddr_0 = io_dtlb_resp_bits_paddr_0;
    dtlb_resp.gpaddr_0 = io_dtlb_resp_bits_gpaddr_0;
    dtlb_resp.fullva = io_dtlb_resp_bits_fullva;
    dtlb_resp.pbmt_0 = io_dtlb_resp_bits_pbmt_0;
    dtlb_resp.miss = io_dtlb_resp_bits_miss;
    dtlb_resp.isForVSnonLeafPTE = io_dtlb_resp_bits_isForVSnonLeafPTE;
    dtlb_resp.excp_0_gpf_ld = io_dtlb_resp_bits_excp_0_gpf_ld;
    dtlb_resp.excp_0_gpf_st = io_dtlb_resp_bits_excp_0_gpf_st;
    dtlb_resp.excp_0_pf_ld = io_dtlb_resp_bits_excp_0_pf_ld;
    dtlb_resp.excp_0_pf_st = io_dtlb_resp_bits_excp_0_pf_st;
    dtlb_resp.excp_0_af_ld = io_dtlb_resp_bits_excp_0_af_ld;
    dtlb_resp.excp_0_af_st = io_dtlb_resp_bits_excp_0_af_st;
  end

  seg_feedback_t feedback;
  assign io_feedback_bits_robIdx_flag = feedback.robIdx_flag;
  assign io_feedback_bits_robIdx_value = feedback.robIdx_value;
  assign io_feedback_bits_sqIdx_flag = feedback.sqIdx_flag;
  assign io_feedback_bits_sqIdx_value = feedback.sqIdx_value;
  assign io_feedback_bits_lqIdx_flag = feedback.lqIdx_flag;
  assign io_feedback_bits_lqIdx_value = feedback.lqIdx_value;

  seg_excinfo_t  exceptionInfo;
  assign io_exceptionInfo_bits_vaddr = exceptionInfo.vaddr;
  assign io_exceptionInfo_bits_gpaddr = exceptionInfo.gpaddr;
  assign io_exceptionInfo_bits_isForVSnonLeafPTE = exceptionInfo.isForVSnonLeafPTE;

  // ---- 核与寄存器之间的桥 ----
  logic [7:0]                uopq_we, data_we;
  seg_uop_t [7:0]            uopq_uop;
  logic [7:0][127:0]         data_wdata, data, stride;
  logic                      instMicroOp_load, fofBuffer_we, writebackValid, feedbackValid;
  seg_uop_t                  instMicroOp_uop_q, fofBuffer_wdata, fofBuffer;
  seg_wb_t                   writebackOut, uopwriteback_r;
  seg_feedback_t             feedbackOut, feedback_r;

  // ---- instMicroOp.uop <= in.uop（第一条 uop 到达时锁存；exceptionVec / trigger 在核里改写）：golden 留下的 36 个字段 ----
  logic [8:0]    instMicroOp_uop_fuOpType;
  logic          instMicroOp_uop_vpu_vill;
  logic          instMicroOp_uop_vpu_vma;
  logic          instMicroOp_uop_vpu_vta;
  logic [1:0]    instMicroOp_uop_vpu_vsew;
  logic [2:0]    instMicroOp_uop_vpu_vlmul;
  logic          instMicroOp_uop_vpu_specVill;
  logic          instMicroOp_uop_vpu_specVma;
  logic          instMicroOp_uop_vpu_specVta;
  logic [1:0]    instMicroOp_uop_vpu_specVsew;
  logic [2:0]    instMicroOp_uop_vpu_specVlmul;
  logic          instMicroOp_uop_vpu_vm;
  logic [7:0]    instMicroOp_uop_vpu_vstart;
  logic [2:0]    instMicroOp_uop_vpu_frm;
  logic          instMicroOp_uop_vpu_fpu_isFpToVecInst;
  logic          instMicroOp_uop_vpu_fpu_isFP32Instr;
  logic          instMicroOp_uop_vpu_fpu_isFP64Instr;
  logic          instMicroOp_uop_vpu_fpu_isReduction;
  logic          instMicroOp_uop_vpu_fpu_isFoldTo1_2;
  logic          instMicroOp_uop_vpu_fpu_isFoldTo1_4;
  logic          instMicroOp_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    instMicroOp_uop_vpu_vxrm;
  logic          instMicroOp_uop_vpu_lastUop;
  logic [2:0]    instMicroOp_uop_vpu_nf;
  logic [1:0]    instMicroOp_uop_vpu_veew;
  logic          instMicroOp_uop_vpu_isReverse;
  logic          instMicroOp_uop_vpu_isExt;
  logic          instMicroOp_uop_vpu_isNarrow;
  logic          instMicroOp_uop_vpu_isDstMask;
  logic          instMicroOp_uop_vpu_isOpMask;
  logic          instMicroOp_uop_vpu_isMove;
  logic          instMicroOp_uop_vpu_isDependOldVd;
  logic          instMicroOp_uop_vpu_isWritePartVd;
  logic          instMicroOp_uop_vpu_isVleff;
  logic          instMicroOp_uop_robIdx_flag;
  logic [7:0]    instMicroOp_uop_robIdx_value;
  always_ff @(posedge clock) begin
    if (instMicroOp_load) begin
      instMicroOp_uop_fuOpType <= in.uop.fuOpType;
      instMicroOp_uop_vpu_vill <= in.uop.vpu_vill;
      instMicroOp_uop_vpu_vma <= in.uop.vpu_vma;
      instMicroOp_uop_vpu_vta <= in.uop.vpu_vta;
      instMicroOp_uop_vpu_vsew <= in.uop.vpu_vsew;
      instMicroOp_uop_vpu_vlmul <= in.uop.vpu_vlmul;
      instMicroOp_uop_vpu_specVill <= in.uop.vpu_specVill;
      instMicroOp_uop_vpu_specVma <= in.uop.vpu_specVma;
      instMicroOp_uop_vpu_specVta <= in.uop.vpu_specVta;
      instMicroOp_uop_vpu_specVsew <= in.uop.vpu_specVsew;
      instMicroOp_uop_vpu_specVlmul <= in.uop.vpu_specVlmul;
      instMicroOp_uop_vpu_vm <= in.uop.vpu_vm;
      instMicroOp_uop_vpu_vstart <= in.uop.vpu_vstart;
      instMicroOp_uop_vpu_frm <= in.uop.vpu_frm;
      instMicroOp_uop_vpu_fpu_isFpToVecInst <= in.uop.vpu_fpu_isFpToVecInst;
      instMicroOp_uop_vpu_fpu_isFP32Instr <= in.uop.vpu_fpu_isFP32Instr;
      instMicroOp_uop_vpu_fpu_isFP64Instr <= in.uop.vpu_fpu_isFP64Instr;
      instMicroOp_uop_vpu_fpu_isReduction <= in.uop.vpu_fpu_isReduction;
      instMicroOp_uop_vpu_fpu_isFoldTo1_2 <= in.uop.vpu_fpu_isFoldTo1_2;
      instMicroOp_uop_vpu_fpu_isFoldTo1_4 <= in.uop.vpu_fpu_isFoldTo1_4;
      instMicroOp_uop_vpu_fpu_isFoldTo1_8 <= in.uop.vpu_fpu_isFoldTo1_8;
      instMicroOp_uop_vpu_vxrm <= in.uop.vpu_vxrm;
      instMicroOp_uop_vpu_lastUop <= in.uop.vpu_lastUop;
      instMicroOp_uop_vpu_nf <= in.uop.vpu_nf;
      instMicroOp_uop_vpu_veew <= in.uop.vpu_veew;
      instMicroOp_uop_vpu_isReverse <= in.uop.vpu_isReverse;
      instMicroOp_uop_vpu_isExt <= in.uop.vpu_isExt;
      instMicroOp_uop_vpu_isNarrow <= in.uop.vpu_isNarrow;
      instMicroOp_uop_vpu_isDstMask <= in.uop.vpu_isDstMask;
      instMicroOp_uop_vpu_isOpMask <= in.uop.vpu_isOpMask;
      instMicroOp_uop_vpu_isMove <= in.uop.vpu_isMove;
      instMicroOp_uop_vpu_isDependOldVd <= in.uop.vpu_isDependOldVd;
      instMicroOp_uop_vpu_isWritePartVd <= in.uop.vpu_isWritePartVd;
      instMicroOp_uop_vpu_isVleff <= in.uop.vpu_isVleff;
      instMicroOp_uop_robIdx_flag <= in.uop.robIdx_flag;
      instMicroOp_uop_robIdx_value <= in.uop.robIdx_value;
    end
  end
  always_comb begin
    instMicroOp_uop_q = '0;
    instMicroOp_uop_q.fuOpType = instMicroOp_uop_fuOpType;
    instMicroOp_uop_q.vpu_vill = instMicroOp_uop_vpu_vill;
    instMicroOp_uop_q.vpu_vma = instMicroOp_uop_vpu_vma;
    instMicroOp_uop_q.vpu_vta = instMicroOp_uop_vpu_vta;
    instMicroOp_uop_q.vpu_vsew = instMicroOp_uop_vpu_vsew;
    instMicroOp_uop_q.vpu_vlmul = instMicroOp_uop_vpu_vlmul;
    instMicroOp_uop_q.vpu_specVill = instMicroOp_uop_vpu_specVill;
    instMicroOp_uop_q.vpu_specVma = instMicroOp_uop_vpu_specVma;
    instMicroOp_uop_q.vpu_specVta = instMicroOp_uop_vpu_specVta;
    instMicroOp_uop_q.vpu_specVsew = instMicroOp_uop_vpu_specVsew;
    instMicroOp_uop_q.vpu_specVlmul = instMicroOp_uop_vpu_specVlmul;
    instMicroOp_uop_q.vpu_vm = instMicroOp_uop_vpu_vm;
    instMicroOp_uop_q.vpu_vstart = instMicroOp_uop_vpu_vstart;
    instMicroOp_uop_q.vpu_frm = instMicroOp_uop_vpu_frm;
    instMicroOp_uop_q.vpu_fpu_isFpToVecInst = instMicroOp_uop_vpu_fpu_isFpToVecInst;
    instMicroOp_uop_q.vpu_fpu_isFP32Instr = instMicroOp_uop_vpu_fpu_isFP32Instr;
    instMicroOp_uop_q.vpu_fpu_isFP64Instr = instMicroOp_uop_vpu_fpu_isFP64Instr;
    instMicroOp_uop_q.vpu_fpu_isReduction = instMicroOp_uop_vpu_fpu_isReduction;
    instMicroOp_uop_q.vpu_fpu_isFoldTo1_2 = instMicroOp_uop_vpu_fpu_isFoldTo1_2;
    instMicroOp_uop_q.vpu_fpu_isFoldTo1_4 = instMicroOp_uop_vpu_fpu_isFoldTo1_4;
    instMicroOp_uop_q.vpu_fpu_isFoldTo1_8 = instMicroOp_uop_vpu_fpu_isFoldTo1_8;
    instMicroOp_uop_q.vpu_vxrm = instMicroOp_uop_vpu_vxrm;
    instMicroOp_uop_q.vpu_lastUop = instMicroOp_uop_vpu_lastUop;
    instMicroOp_uop_q.vpu_nf = instMicroOp_uop_vpu_nf;
    instMicroOp_uop_q.vpu_veew = instMicroOp_uop_vpu_veew;
    instMicroOp_uop_q.vpu_isReverse = instMicroOp_uop_vpu_isReverse;
    instMicroOp_uop_q.vpu_isExt = instMicroOp_uop_vpu_isExt;
    instMicroOp_uop_q.vpu_isNarrow = instMicroOp_uop_vpu_isNarrow;
    instMicroOp_uop_q.vpu_isDstMask = instMicroOp_uop_vpu_isDstMask;
    instMicroOp_uop_q.vpu_isOpMask = instMicroOp_uop_vpu_isOpMask;
    instMicroOp_uop_q.vpu_isMove = instMicroOp_uop_vpu_isMove;
    instMicroOp_uop_q.vpu_isDependOldVd = instMicroOp_uop_vpu_isDependOldVd;
    instMicroOp_uop_q.vpu_isWritePartVd = instMicroOp_uop_vpu_isWritePartVd;
    instMicroOp_uop_q.vpu_isVleff = instMicroOp_uop_vpu_isVleff;
    instMicroOp_uop_q.robIdx_flag = instMicroOp_uop_robIdx_flag;
    instMicroOp_uop_q.robIdx_value = instMicroOp_uop_robIdx_value;
  end

  // ---- fofBuffer（fof 的最后一条 uop；RegInit 0，用完清零）：golden 留下的 53 个字段 ----
  logic [8:0]    fofBuffer_fuOpType;
  logic          fofBuffer_vecWen;
  logic          fofBuffer_v0Wen;
  logic          fofBuffer_vlWen;
  logic          fofBuffer_vpu_vill;
  logic          fofBuffer_vpu_vma;
  logic          fofBuffer_vpu_vta;
  logic [1:0]    fofBuffer_vpu_vsew;
  logic [2:0]    fofBuffer_vpu_vlmul;
  logic          fofBuffer_vpu_specVill;
  logic          fofBuffer_vpu_specVma;
  logic          fofBuffer_vpu_specVta;
  logic [1:0]    fofBuffer_vpu_specVsew;
  logic [2:0]    fofBuffer_vpu_specVlmul;
  logic          fofBuffer_vpu_vm;
  logic [7:0]    fofBuffer_vpu_vstart;
  logic [2:0]    fofBuffer_vpu_frm;
  logic          fofBuffer_vpu_fpu_isFpToVecInst;
  logic          fofBuffer_vpu_fpu_isFP32Instr;
  logic          fofBuffer_vpu_fpu_isFP64Instr;
  logic          fofBuffer_vpu_fpu_isReduction;
  logic          fofBuffer_vpu_fpu_isFoldTo1_2;
  logic          fofBuffer_vpu_fpu_isFoldTo1_4;
  logic          fofBuffer_vpu_fpu_isFoldTo1_8;
  logic [1:0]    fofBuffer_vpu_vxrm;
  logic [6:0]    fofBuffer_vpu_vuopIdx;
  logic          fofBuffer_vpu_lastUop;
  logic [2:0]    fofBuffer_vpu_nf;
  logic [1:0]    fofBuffer_vpu_veew;
  logic          fofBuffer_vpu_isReverse;
  logic          fofBuffer_vpu_isExt;
  logic          fofBuffer_vpu_isNarrow;
  logic          fofBuffer_vpu_isDstMask;
  logic          fofBuffer_vpu_isOpMask;
  logic          fofBuffer_vpu_isMove;
  logic          fofBuffer_vpu_isDependOldVd;
  logic          fofBuffer_vpu_isWritePartVd;
  logic          fofBuffer_vpu_isVleff;
  logic [7:0]    fofBuffer_pdest;
  logic          fofBuffer_robIdx_flag;
  logic [7:0]    fofBuffer_robIdx_value;
  logic          fofBuffer_debugInfo_eliminatedMove;
  logic [63:0]   fofBuffer_debugInfo_renameTime;
  logic [63:0]   fofBuffer_debugInfo_dispatchTime;
  logic [63:0]   fofBuffer_debugInfo_enqRsTime;
  logic [63:0]   fofBuffer_debugInfo_selectTime;
  logic [63:0]   fofBuffer_debugInfo_issueTime;
  logic [63:0]   fofBuffer_debugInfo_writebackTime;
  logic [63:0]   fofBuffer_debugInfo_runahead_checkpoint_id;
  logic [63:0]   fofBuffer_debugInfo_tlbFirstReqTime;
  logic [63:0]   fofBuffer_debugInfo_tlbRespTime;
  logic [55:0]   fofBuffer_debug_seqNum_seqNum;
  logic [7:0]    fofBuffer_debug_seqNum_uopIdx;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fofBuffer_fuOpType <= '0;
      fofBuffer_vecWen <= '0;
      fofBuffer_v0Wen <= '0;
      fofBuffer_vlWen <= '0;
      fofBuffer_vpu_vill <= '0;
      fofBuffer_vpu_vma <= '0;
      fofBuffer_vpu_vta <= '0;
      fofBuffer_vpu_vsew <= '0;
      fofBuffer_vpu_vlmul <= '0;
      fofBuffer_vpu_specVill <= '0;
      fofBuffer_vpu_specVma <= '0;
      fofBuffer_vpu_specVta <= '0;
      fofBuffer_vpu_specVsew <= '0;
      fofBuffer_vpu_specVlmul <= '0;
      fofBuffer_vpu_vm <= '0;
      fofBuffer_vpu_vstart <= '0;
      fofBuffer_vpu_frm <= '0;
      fofBuffer_vpu_fpu_isFpToVecInst <= '0;
      fofBuffer_vpu_fpu_isFP32Instr <= '0;
      fofBuffer_vpu_fpu_isFP64Instr <= '0;
      fofBuffer_vpu_fpu_isReduction <= '0;
      fofBuffer_vpu_fpu_isFoldTo1_2 <= '0;
      fofBuffer_vpu_fpu_isFoldTo1_4 <= '0;
      fofBuffer_vpu_fpu_isFoldTo1_8 <= '0;
      fofBuffer_vpu_vxrm <= '0;
      fofBuffer_vpu_vuopIdx <= '0;
      fofBuffer_vpu_lastUop <= '0;
      fofBuffer_vpu_nf <= '0;
      fofBuffer_vpu_veew <= '0;
      fofBuffer_vpu_isReverse <= '0;
      fofBuffer_vpu_isExt <= '0;
      fofBuffer_vpu_isNarrow <= '0;
      fofBuffer_vpu_isDstMask <= '0;
      fofBuffer_vpu_isOpMask <= '0;
      fofBuffer_vpu_isMove <= '0;
      fofBuffer_vpu_isDependOldVd <= '0;
      fofBuffer_vpu_isWritePartVd <= '0;
      fofBuffer_vpu_isVleff <= '0;
      fofBuffer_pdest <= '0;
      fofBuffer_robIdx_flag <= '0;
      fofBuffer_robIdx_value <= '0;
      fofBuffer_debugInfo_eliminatedMove <= '0;
      fofBuffer_debugInfo_renameTime <= '0;
      fofBuffer_debugInfo_dispatchTime <= '0;
      fofBuffer_debugInfo_enqRsTime <= '0;
      fofBuffer_debugInfo_selectTime <= '0;
      fofBuffer_debugInfo_issueTime <= '0;
      fofBuffer_debugInfo_writebackTime <= '0;
      fofBuffer_debugInfo_runahead_checkpoint_id <= '0;
      fofBuffer_debugInfo_tlbFirstReqTime <= '0;
      fofBuffer_debugInfo_tlbRespTime <= '0;
      fofBuffer_debug_seqNum_seqNum <= '0;
      fofBuffer_debug_seqNum_uopIdx <= '0;
    end else if (fofBuffer_we) begin
      fofBuffer_fuOpType <= fofBuffer_wdata.fuOpType;
      fofBuffer_vecWen <= fofBuffer_wdata.vecWen;
      fofBuffer_v0Wen <= fofBuffer_wdata.v0Wen;
      fofBuffer_vlWen <= fofBuffer_wdata.vlWen;
      fofBuffer_vpu_vill <= fofBuffer_wdata.vpu_vill;
      fofBuffer_vpu_vma <= fofBuffer_wdata.vpu_vma;
      fofBuffer_vpu_vta <= fofBuffer_wdata.vpu_vta;
      fofBuffer_vpu_vsew <= fofBuffer_wdata.vpu_vsew;
      fofBuffer_vpu_vlmul <= fofBuffer_wdata.vpu_vlmul;
      fofBuffer_vpu_specVill <= fofBuffer_wdata.vpu_specVill;
      fofBuffer_vpu_specVma <= fofBuffer_wdata.vpu_specVma;
      fofBuffer_vpu_specVta <= fofBuffer_wdata.vpu_specVta;
      fofBuffer_vpu_specVsew <= fofBuffer_wdata.vpu_specVsew;
      fofBuffer_vpu_specVlmul <= fofBuffer_wdata.vpu_specVlmul;
      fofBuffer_vpu_vm <= fofBuffer_wdata.vpu_vm;
      fofBuffer_vpu_vstart <= fofBuffer_wdata.vpu_vstart;
      fofBuffer_vpu_frm <= fofBuffer_wdata.vpu_frm;
      fofBuffer_vpu_fpu_isFpToVecInst <= fofBuffer_wdata.vpu_fpu_isFpToVecInst;
      fofBuffer_vpu_fpu_isFP32Instr <= fofBuffer_wdata.vpu_fpu_isFP32Instr;
      fofBuffer_vpu_fpu_isFP64Instr <= fofBuffer_wdata.vpu_fpu_isFP64Instr;
      fofBuffer_vpu_fpu_isReduction <= fofBuffer_wdata.vpu_fpu_isReduction;
      fofBuffer_vpu_fpu_isFoldTo1_2 <= fofBuffer_wdata.vpu_fpu_isFoldTo1_2;
      fofBuffer_vpu_fpu_isFoldTo1_4 <= fofBuffer_wdata.vpu_fpu_isFoldTo1_4;
      fofBuffer_vpu_fpu_isFoldTo1_8 <= fofBuffer_wdata.vpu_fpu_isFoldTo1_8;
      fofBuffer_vpu_vxrm <= fofBuffer_wdata.vpu_vxrm;
      fofBuffer_vpu_vuopIdx <= fofBuffer_wdata.vpu_vuopIdx;
      fofBuffer_vpu_lastUop <= fofBuffer_wdata.vpu_lastUop;
      fofBuffer_vpu_nf <= fofBuffer_wdata.vpu_nf;
      fofBuffer_vpu_veew <= fofBuffer_wdata.vpu_veew;
      fofBuffer_vpu_isReverse <= fofBuffer_wdata.vpu_isReverse;
      fofBuffer_vpu_isExt <= fofBuffer_wdata.vpu_isExt;
      fofBuffer_vpu_isNarrow <= fofBuffer_wdata.vpu_isNarrow;
      fofBuffer_vpu_isDstMask <= fofBuffer_wdata.vpu_isDstMask;
      fofBuffer_vpu_isOpMask <= fofBuffer_wdata.vpu_isOpMask;
      fofBuffer_vpu_isMove <= fofBuffer_wdata.vpu_isMove;
      fofBuffer_vpu_isDependOldVd <= fofBuffer_wdata.vpu_isDependOldVd;
      fofBuffer_vpu_isWritePartVd <= fofBuffer_wdata.vpu_isWritePartVd;
      fofBuffer_vpu_isVleff <= fofBuffer_wdata.vpu_isVleff;
      fofBuffer_pdest <= fofBuffer_wdata.pdest;
      fofBuffer_robIdx_flag <= fofBuffer_wdata.robIdx_flag;
      fofBuffer_robIdx_value <= fofBuffer_wdata.robIdx_value;
      fofBuffer_debugInfo_eliminatedMove <= fofBuffer_wdata.debugInfo_eliminatedMove;
      fofBuffer_debugInfo_renameTime <= fofBuffer_wdata.debugInfo_renameTime;
      fofBuffer_debugInfo_dispatchTime <= fofBuffer_wdata.debugInfo_dispatchTime;
      fofBuffer_debugInfo_enqRsTime <= fofBuffer_wdata.debugInfo_enqRsTime;
      fofBuffer_debugInfo_selectTime <= fofBuffer_wdata.debugInfo_selectTime;
      fofBuffer_debugInfo_issueTime <= fofBuffer_wdata.debugInfo_issueTime;
      fofBuffer_debugInfo_writebackTime <= fofBuffer_wdata.debugInfo_writebackTime;
      fofBuffer_debugInfo_runahead_checkpoint_id <= fofBuffer_wdata.debugInfo_runahead_checkpoint_id;
      fofBuffer_debugInfo_tlbFirstReqTime <= fofBuffer_wdata.debugInfo_tlbFirstReqTime;
      fofBuffer_debugInfo_tlbRespTime <= fofBuffer_wdata.debugInfo_tlbRespTime;
      fofBuffer_debug_seqNum_seqNum <= fofBuffer_wdata.debug_seqNum_seqNum;
      fofBuffer_debug_seqNum_uopIdx <= fofBuffer_wdata.debug_seqNum_uopIdx;
    end
  end
  always_comb begin
    fofBuffer = '0;
    fofBuffer.fuOpType = fofBuffer_fuOpType;
    fofBuffer.vecWen = fofBuffer_vecWen;
    fofBuffer.v0Wen = fofBuffer_v0Wen;
    fofBuffer.vlWen = fofBuffer_vlWen;
    fofBuffer.vpu_vill = fofBuffer_vpu_vill;
    fofBuffer.vpu_vma = fofBuffer_vpu_vma;
    fofBuffer.vpu_vta = fofBuffer_vpu_vta;
    fofBuffer.vpu_vsew = fofBuffer_vpu_vsew;
    fofBuffer.vpu_vlmul = fofBuffer_vpu_vlmul;
    fofBuffer.vpu_specVill = fofBuffer_vpu_specVill;
    fofBuffer.vpu_specVma = fofBuffer_vpu_specVma;
    fofBuffer.vpu_specVta = fofBuffer_vpu_specVta;
    fofBuffer.vpu_specVsew = fofBuffer_vpu_specVsew;
    fofBuffer.vpu_specVlmul = fofBuffer_vpu_specVlmul;
    fofBuffer.vpu_vm = fofBuffer_vpu_vm;
    fofBuffer.vpu_vstart = fofBuffer_vpu_vstart;
    fofBuffer.vpu_frm = fofBuffer_vpu_frm;
    fofBuffer.vpu_fpu_isFpToVecInst = fofBuffer_vpu_fpu_isFpToVecInst;
    fofBuffer.vpu_fpu_isFP32Instr = fofBuffer_vpu_fpu_isFP32Instr;
    fofBuffer.vpu_fpu_isFP64Instr = fofBuffer_vpu_fpu_isFP64Instr;
    fofBuffer.vpu_fpu_isReduction = fofBuffer_vpu_fpu_isReduction;
    fofBuffer.vpu_fpu_isFoldTo1_2 = fofBuffer_vpu_fpu_isFoldTo1_2;
    fofBuffer.vpu_fpu_isFoldTo1_4 = fofBuffer_vpu_fpu_isFoldTo1_4;
    fofBuffer.vpu_fpu_isFoldTo1_8 = fofBuffer_vpu_fpu_isFoldTo1_8;
    fofBuffer.vpu_vxrm = fofBuffer_vpu_vxrm;
    fofBuffer.vpu_vuopIdx = fofBuffer_vpu_vuopIdx;
    fofBuffer.vpu_lastUop = fofBuffer_vpu_lastUop;
    fofBuffer.vpu_nf = fofBuffer_vpu_nf;
    fofBuffer.vpu_veew = fofBuffer_vpu_veew;
    fofBuffer.vpu_isReverse = fofBuffer_vpu_isReverse;
    fofBuffer.vpu_isExt = fofBuffer_vpu_isExt;
    fofBuffer.vpu_isNarrow = fofBuffer_vpu_isNarrow;
    fofBuffer.vpu_isDstMask = fofBuffer_vpu_isDstMask;
    fofBuffer.vpu_isOpMask = fofBuffer_vpu_isOpMask;
    fofBuffer.vpu_isMove = fofBuffer_vpu_isMove;
    fofBuffer.vpu_isDependOldVd = fofBuffer_vpu_isDependOldVd;
    fofBuffer.vpu_isWritePartVd = fofBuffer_vpu_isWritePartVd;
    fofBuffer.vpu_isVleff = fofBuffer_vpu_isVleff;
    fofBuffer.pdest = fofBuffer_pdest;
    fofBuffer.robIdx_flag = fofBuffer_robIdx_flag;
    fofBuffer.robIdx_value = fofBuffer_robIdx_value;
    fofBuffer.debugInfo_eliminatedMove = fofBuffer_debugInfo_eliminatedMove;
    fofBuffer.debugInfo_renameTime = fofBuffer_debugInfo_renameTime;
    fofBuffer.debugInfo_dispatchTime = fofBuffer_debugInfo_dispatchTime;
    fofBuffer.debugInfo_enqRsTime = fofBuffer_debugInfo_enqRsTime;
    fofBuffer.debugInfo_selectTime = fofBuffer_debugInfo_selectTime;
    fofBuffer.debugInfo_issueTime = fofBuffer_debugInfo_issueTime;
    fofBuffer.debugInfo_writebackTime = fofBuffer_debugInfo_writebackTime;
    fofBuffer.debugInfo_runahead_checkpoint_id = fofBuffer_debugInfo_runahead_checkpoint_id;
    fofBuffer.debugInfo_tlbFirstReqTime = fofBuffer_debugInfo_tlbFirstReqTime;
    fofBuffer.debugInfo_tlbRespTime = fofBuffer_debugInfo_tlbRespTime;
    fofBuffer.debug_seqNum_seqNum = fofBuffer_debug_seqNum_seqNum;
    fofBuffer.debug_seqNum_uopIdx = fofBuffer_debug_seqNum_uopIdx;
  end

  // ---- 写回打拍 RegEnable(writebackOut, writebackValid)（vdIdx / vdIdxInField 在核里：fof 那条不改它们）：golden 留下的 65 个字段 ----
  logic          io_uopwriteback_bits_r_uop_exceptionVec_3;
  logic          io_uopwriteback_bits_r_uop_exceptionVec_5;
  logic          io_uopwriteback_bits_r_uop_exceptionVec_7;
  logic          io_uopwriteback_bits_r_uop_exceptionVec_13;
  logic          io_uopwriteback_bits_r_uop_exceptionVec_15;
  logic          io_uopwriteback_bits_r_uop_exceptionVec_19;
  logic          io_uopwriteback_bits_r_uop_exceptionVec_21;
  logic          io_uopwriteback_bits_r_uop_exceptionVec_23;
  logic [3:0]    io_uopwriteback_bits_r_uop_trigger;
  logic [8:0]    io_uopwriteback_bits_r_uop_fuOpType;
  logic          io_uopwriteback_bits_r_uop_vecWen;
  logic          io_uopwriteback_bits_r_uop_v0Wen;
  logic          io_uopwriteback_bits_r_uop_vlWen;
  logic          io_uopwriteback_bits_r_uop_vpu_vill;
  logic          io_uopwriteback_bits_r_uop_vpu_vma;
  logic          io_uopwriteback_bits_r_uop_vpu_vta;
  logic [1:0]    io_uopwriteback_bits_r_uop_vpu_vsew;
  logic [2:0]    io_uopwriteback_bits_r_uop_vpu_vlmul;
  logic          io_uopwriteback_bits_r_uop_vpu_specVill;
  logic          io_uopwriteback_bits_r_uop_vpu_specVma;
  logic          io_uopwriteback_bits_r_uop_vpu_specVta;
  logic [1:0]    io_uopwriteback_bits_r_uop_vpu_specVsew;
  logic [2:0]    io_uopwriteback_bits_r_uop_vpu_specVlmul;
  logic          io_uopwriteback_bits_r_uop_vpu_vm;
  logic [7:0]    io_uopwriteback_bits_r_uop_vpu_vstart;
  logic [2:0]    io_uopwriteback_bits_r_uop_vpu_frm;
  logic          io_uopwriteback_bits_r_uop_vpu_fpu_isFpToVecInst;
  logic          io_uopwriteback_bits_r_uop_vpu_fpu_isFP32Instr;
  logic          io_uopwriteback_bits_r_uop_vpu_fpu_isFP64Instr;
  logic          io_uopwriteback_bits_r_uop_vpu_fpu_isReduction;
  logic          io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_2;
  logic          io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_4;
  logic          io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    io_uopwriteback_bits_r_uop_vpu_vxrm;
  logic [6:0]    io_uopwriteback_bits_r_uop_vpu_vuopIdx;
  logic          io_uopwriteback_bits_r_uop_vpu_lastUop;
  logic [127:0]  io_uopwriteback_bits_r_uop_vpu_vmask;
  logic [7:0]    io_uopwriteback_bits_r_uop_vpu_vl;
  logic [2:0]    io_uopwriteback_bits_r_uop_vpu_nf;
  logic [1:0]    io_uopwriteback_bits_r_uop_vpu_veew;
  logic          io_uopwriteback_bits_r_uop_vpu_isReverse;
  logic          io_uopwriteback_bits_r_uop_vpu_isExt;
  logic          io_uopwriteback_bits_r_uop_vpu_isNarrow;
  logic          io_uopwriteback_bits_r_uop_vpu_isDstMask;
  logic          io_uopwriteback_bits_r_uop_vpu_isOpMask;
  logic          io_uopwriteback_bits_r_uop_vpu_isMove;
  logic          io_uopwriteback_bits_r_uop_vpu_isDependOldVd;
  logic          io_uopwriteback_bits_r_uop_vpu_isWritePartVd;
  logic          io_uopwriteback_bits_r_uop_vpu_isVleff;
  logic [7:0]    io_uopwriteback_bits_r_uop_pdest;
  logic          io_uopwriteback_bits_r_uop_robIdx_flag;
  logic [7:0]    io_uopwriteback_bits_r_uop_robIdx_value;
  logic          io_uopwriteback_bits_r_uop_debugInfo_eliminatedMove;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_renameTime;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_dispatchTime;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_enqRsTime;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_selectTime;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_issueTime;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_writebackTime;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   io_uopwriteback_bits_r_uop_debugInfo_tlbRespTime;
  logic [55:0]   io_uopwriteback_bits_r_uop_debug_seqNum_seqNum;
  logic [7:0]    io_uopwriteback_bits_r_uop_debug_seqNum_uopIdx;
  logic [127:0]  io_uopwriteback_bits_r_data;
  always_ff @(posedge clock) begin
    if (writebackValid) begin
      io_uopwriteback_bits_r_uop_exceptionVec_3 <= writebackOut.uop.exceptionVec[3];
      io_uopwriteback_bits_r_uop_exceptionVec_5 <= writebackOut.uop.exceptionVec[5];
      io_uopwriteback_bits_r_uop_exceptionVec_7 <= writebackOut.uop.exceptionVec[7];
      io_uopwriteback_bits_r_uop_exceptionVec_13 <= writebackOut.uop.exceptionVec[13];
      io_uopwriteback_bits_r_uop_exceptionVec_15 <= writebackOut.uop.exceptionVec[15];
      io_uopwriteback_bits_r_uop_exceptionVec_19 <= writebackOut.uop.exceptionVec[19];
      io_uopwriteback_bits_r_uop_exceptionVec_21 <= writebackOut.uop.exceptionVec[21];
      io_uopwriteback_bits_r_uop_exceptionVec_23 <= writebackOut.uop.exceptionVec[23];
      io_uopwriteback_bits_r_uop_trigger <= writebackOut.uop.trigger;
      io_uopwriteback_bits_r_uop_fuOpType <= writebackOut.uop.fuOpType;
      io_uopwriteback_bits_r_uop_vecWen <= writebackOut.uop.vecWen;
      io_uopwriteback_bits_r_uop_v0Wen <= writebackOut.uop.v0Wen;
      io_uopwriteback_bits_r_uop_vlWen <= writebackOut.uop.vlWen;
      io_uopwriteback_bits_r_uop_vpu_vill <= writebackOut.uop.vpu_vill;
      io_uopwriteback_bits_r_uop_vpu_vma <= writebackOut.uop.vpu_vma;
      io_uopwriteback_bits_r_uop_vpu_vta <= writebackOut.uop.vpu_vta;
      io_uopwriteback_bits_r_uop_vpu_vsew <= writebackOut.uop.vpu_vsew;
      io_uopwriteback_bits_r_uop_vpu_vlmul <= writebackOut.uop.vpu_vlmul;
      io_uopwriteback_bits_r_uop_vpu_specVill <= writebackOut.uop.vpu_specVill;
      io_uopwriteback_bits_r_uop_vpu_specVma <= writebackOut.uop.vpu_specVma;
      io_uopwriteback_bits_r_uop_vpu_specVta <= writebackOut.uop.vpu_specVta;
      io_uopwriteback_bits_r_uop_vpu_specVsew <= writebackOut.uop.vpu_specVsew;
      io_uopwriteback_bits_r_uop_vpu_specVlmul <= writebackOut.uop.vpu_specVlmul;
      io_uopwriteback_bits_r_uop_vpu_vm <= writebackOut.uop.vpu_vm;
      io_uopwriteback_bits_r_uop_vpu_vstart <= writebackOut.uop.vpu_vstart;
      io_uopwriteback_bits_r_uop_vpu_frm <= writebackOut.uop.vpu_frm;
      io_uopwriteback_bits_r_uop_vpu_fpu_isFpToVecInst <= writebackOut.uop.vpu_fpu_isFpToVecInst;
      io_uopwriteback_bits_r_uop_vpu_fpu_isFP32Instr <= writebackOut.uop.vpu_fpu_isFP32Instr;
      io_uopwriteback_bits_r_uop_vpu_fpu_isFP64Instr <= writebackOut.uop.vpu_fpu_isFP64Instr;
      io_uopwriteback_bits_r_uop_vpu_fpu_isReduction <= writebackOut.uop.vpu_fpu_isReduction;
      io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_2 <= writebackOut.uop.vpu_fpu_isFoldTo1_2;
      io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_4 <= writebackOut.uop.vpu_fpu_isFoldTo1_4;
      io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_8 <= writebackOut.uop.vpu_fpu_isFoldTo1_8;
      io_uopwriteback_bits_r_uop_vpu_vxrm <= writebackOut.uop.vpu_vxrm;
      io_uopwriteback_bits_r_uop_vpu_vuopIdx <= writebackOut.uop.vpu_vuopIdx;
      io_uopwriteback_bits_r_uop_vpu_lastUop <= writebackOut.uop.vpu_lastUop;
      io_uopwriteback_bits_r_uop_vpu_vmask <= writebackOut.uop.vpu_vmask;
      io_uopwriteback_bits_r_uop_vpu_vl <= writebackOut.uop.vpu_vl;
      io_uopwriteback_bits_r_uop_vpu_nf <= writebackOut.uop.vpu_nf;
      io_uopwriteback_bits_r_uop_vpu_veew <= writebackOut.uop.vpu_veew;
      io_uopwriteback_bits_r_uop_vpu_isReverse <= writebackOut.uop.vpu_isReverse;
      io_uopwriteback_bits_r_uop_vpu_isExt <= writebackOut.uop.vpu_isExt;
      io_uopwriteback_bits_r_uop_vpu_isNarrow <= writebackOut.uop.vpu_isNarrow;
      io_uopwriteback_bits_r_uop_vpu_isDstMask <= writebackOut.uop.vpu_isDstMask;
      io_uopwriteback_bits_r_uop_vpu_isOpMask <= writebackOut.uop.vpu_isOpMask;
      io_uopwriteback_bits_r_uop_vpu_isMove <= writebackOut.uop.vpu_isMove;
      io_uopwriteback_bits_r_uop_vpu_isDependOldVd <= writebackOut.uop.vpu_isDependOldVd;
      io_uopwriteback_bits_r_uop_vpu_isWritePartVd <= writebackOut.uop.vpu_isWritePartVd;
      io_uopwriteback_bits_r_uop_vpu_isVleff <= writebackOut.uop.vpu_isVleff;
      io_uopwriteback_bits_r_uop_pdest <= writebackOut.uop.pdest;
      io_uopwriteback_bits_r_uop_robIdx_flag <= writebackOut.uop.robIdx_flag;
      io_uopwriteback_bits_r_uop_robIdx_value <= writebackOut.uop.robIdx_value;
      io_uopwriteback_bits_r_uop_debugInfo_eliminatedMove <= writebackOut.uop.debugInfo_eliminatedMove;
      io_uopwriteback_bits_r_uop_debugInfo_renameTime <= writebackOut.uop.debugInfo_renameTime;
      io_uopwriteback_bits_r_uop_debugInfo_dispatchTime <= writebackOut.uop.debugInfo_dispatchTime;
      io_uopwriteback_bits_r_uop_debugInfo_enqRsTime <= writebackOut.uop.debugInfo_enqRsTime;
      io_uopwriteback_bits_r_uop_debugInfo_selectTime <= writebackOut.uop.debugInfo_selectTime;
      io_uopwriteback_bits_r_uop_debugInfo_issueTime <= writebackOut.uop.debugInfo_issueTime;
      io_uopwriteback_bits_r_uop_debugInfo_writebackTime <= writebackOut.uop.debugInfo_writebackTime;
      io_uopwriteback_bits_r_uop_debugInfo_runahead_checkpoint_id <= writebackOut.uop.debugInfo_runahead_checkpoint_id;
      io_uopwriteback_bits_r_uop_debugInfo_tlbFirstReqTime <= writebackOut.uop.debugInfo_tlbFirstReqTime;
      io_uopwriteback_bits_r_uop_debugInfo_tlbRespTime <= writebackOut.uop.debugInfo_tlbRespTime;
      io_uopwriteback_bits_r_uop_debug_seqNum_seqNum <= writebackOut.uop.debug_seqNum_seqNum;
      io_uopwriteback_bits_r_uop_debug_seqNum_uopIdx <= writebackOut.uop.debug_seqNum_uopIdx;
      io_uopwriteback_bits_r_data <= writebackOut.data;
    end
  end
  always_comb begin
    uopwriteback_r = '0;
    uopwriteback_r.uop.exceptionVec[3] = io_uopwriteback_bits_r_uop_exceptionVec_3;
    uopwriteback_r.uop.exceptionVec[5] = io_uopwriteback_bits_r_uop_exceptionVec_5;
    uopwriteback_r.uop.exceptionVec[7] = io_uopwriteback_bits_r_uop_exceptionVec_7;
    uopwriteback_r.uop.exceptionVec[13] = io_uopwriteback_bits_r_uop_exceptionVec_13;
    uopwriteback_r.uop.exceptionVec[15] = io_uopwriteback_bits_r_uop_exceptionVec_15;
    uopwriteback_r.uop.exceptionVec[19] = io_uopwriteback_bits_r_uop_exceptionVec_19;
    uopwriteback_r.uop.exceptionVec[21] = io_uopwriteback_bits_r_uop_exceptionVec_21;
    uopwriteback_r.uop.exceptionVec[23] = io_uopwriteback_bits_r_uop_exceptionVec_23;
    uopwriteback_r.uop.trigger = io_uopwriteback_bits_r_uop_trigger;
    uopwriteback_r.uop.fuOpType = io_uopwriteback_bits_r_uop_fuOpType;
    uopwriteback_r.uop.vecWen = io_uopwriteback_bits_r_uop_vecWen;
    uopwriteback_r.uop.v0Wen = io_uopwriteback_bits_r_uop_v0Wen;
    uopwriteback_r.uop.vlWen = io_uopwriteback_bits_r_uop_vlWen;
    uopwriteback_r.uop.vpu_vill = io_uopwriteback_bits_r_uop_vpu_vill;
    uopwriteback_r.uop.vpu_vma = io_uopwriteback_bits_r_uop_vpu_vma;
    uopwriteback_r.uop.vpu_vta = io_uopwriteback_bits_r_uop_vpu_vta;
    uopwriteback_r.uop.vpu_vsew = io_uopwriteback_bits_r_uop_vpu_vsew;
    uopwriteback_r.uop.vpu_vlmul = io_uopwriteback_bits_r_uop_vpu_vlmul;
    uopwriteback_r.uop.vpu_specVill = io_uopwriteback_bits_r_uop_vpu_specVill;
    uopwriteback_r.uop.vpu_specVma = io_uopwriteback_bits_r_uop_vpu_specVma;
    uopwriteback_r.uop.vpu_specVta = io_uopwriteback_bits_r_uop_vpu_specVta;
    uopwriteback_r.uop.vpu_specVsew = io_uopwriteback_bits_r_uop_vpu_specVsew;
    uopwriteback_r.uop.vpu_specVlmul = io_uopwriteback_bits_r_uop_vpu_specVlmul;
    uopwriteback_r.uop.vpu_vm = io_uopwriteback_bits_r_uop_vpu_vm;
    uopwriteback_r.uop.vpu_vstart = io_uopwriteback_bits_r_uop_vpu_vstart;
    uopwriteback_r.uop.vpu_frm = io_uopwriteback_bits_r_uop_vpu_frm;
    uopwriteback_r.uop.vpu_fpu_isFpToVecInst = io_uopwriteback_bits_r_uop_vpu_fpu_isFpToVecInst;
    uopwriteback_r.uop.vpu_fpu_isFP32Instr = io_uopwriteback_bits_r_uop_vpu_fpu_isFP32Instr;
    uopwriteback_r.uop.vpu_fpu_isFP64Instr = io_uopwriteback_bits_r_uop_vpu_fpu_isFP64Instr;
    uopwriteback_r.uop.vpu_fpu_isReduction = io_uopwriteback_bits_r_uop_vpu_fpu_isReduction;
    uopwriteback_r.uop.vpu_fpu_isFoldTo1_2 = io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_2;
    uopwriteback_r.uop.vpu_fpu_isFoldTo1_4 = io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_4;
    uopwriteback_r.uop.vpu_fpu_isFoldTo1_8 = io_uopwriteback_bits_r_uop_vpu_fpu_isFoldTo1_8;
    uopwriteback_r.uop.vpu_vxrm = io_uopwriteback_bits_r_uop_vpu_vxrm;
    uopwriteback_r.uop.vpu_vuopIdx = io_uopwriteback_bits_r_uop_vpu_vuopIdx;
    uopwriteback_r.uop.vpu_lastUop = io_uopwriteback_bits_r_uop_vpu_lastUop;
    uopwriteback_r.uop.vpu_vmask = io_uopwriteback_bits_r_uop_vpu_vmask;
    uopwriteback_r.uop.vpu_vl = io_uopwriteback_bits_r_uop_vpu_vl;
    uopwriteback_r.uop.vpu_nf = io_uopwriteback_bits_r_uop_vpu_nf;
    uopwriteback_r.uop.vpu_veew = io_uopwriteback_bits_r_uop_vpu_veew;
    uopwriteback_r.uop.vpu_isReverse = io_uopwriteback_bits_r_uop_vpu_isReverse;
    uopwriteback_r.uop.vpu_isExt = io_uopwriteback_bits_r_uop_vpu_isExt;
    uopwriteback_r.uop.vpu_isNarrow = io_uopwriteback_bits_r_uop_vpu_isNarrow;
    uopwriteback_r.uop.vpu_isDstMask = io_uopwriteback_bits_r_uop_vpu_isDstMask;
    uopwriteback_r.uop.vpu_isOpMask = io_uopwriteback_bits_r_uop_vpu_isOpMask;
    uopwriteback_r.uop.vpu_isMove = io_uopwriteback_bits_r_uop_vpu_isMove;
    uopwriteback_r.uop.vpu_isDependOldVd = io_uopwriteback_bits_r_uop_vpu_isDependOldVd;
    uopwriteback_r.uop.vpu_isWritePartVd = io_uopwriteback_bits_r_uop_vpu_isWritePartVd;
    uopwriteback_r.uop.vpu_isVleff = io_uopwriteback_bits_r_uop_vpu_isVleff;
    uopwriteback_r.uop.pdest = io_uopwriteback_bits_r_uop_pdest;
    uopwriteback_r.uop.robIdx_flag = io_uopwriteback_bits_r_uop_robIdx_flag;
    uopwriteback_r.uop.robIdx_value = io_uopwriteback_bits_r_uop_robIdx_value;
    uopwriteback_r.uop.debugInfo_eliminatedMove = io_uopwriteback_bits_r_uop_debugInfo_eliminatedMove;
    uopwriteback_r.uop.debugInfo_renameTime = io_uopwriteback_bits_r_uop_debugInfo_renameTime;
    uopwriteback_r.uop.debugInfo_dispatchTime = io_uopwriteback_bits_r_uop_debugInfo_dispatchTime;
    uopwriteback_r.uop.debugInfo_enqRsTime = io_uopwriteback_bits_r_uop_debugInfo_enqRsTime;
    uopwriteback_r.uop.debugInfo_selectTime = io_uopwriteback_bits_r_uop_debugInfo_selectTime;
    uopwriteback_r.uop.debugInfo_issueTime = io_uopwriteback_bits_r_uop_debugInfo_issueTime;
    uopwriteback_r.uop.debugInfo_writebackTime = io_uopwriteback_bits_r_uop_debugInfo_writebackTime;
    uopwriteback_r.uop.debugInfo_runahead_checkpoint_id = io_uopwriteback_bits_r_uop_debugInfo_runahead_checkpoint_id;
    uopwriteback_r.uop.debugInfo_tlbFirstReqTime = io_uopwriteback_bits_r_uop_debugInfo_tlbFirstReqTime;
    uopwriteback_r.uop.debugInfo_tlbRespTime = io_uopwriteback_bits_r_uop_debugInfo_tlbRespTime;
    uopwriteback_r.uop.debug_seqNum_seqNum = io_uopwriteback_bits_r_uop_debug_seqNum_seqNum;
    uopwriteback_r.uop.debug_seqNum_uopIdx = io_uopwriteback_bits_r_uop_debug_seqNum_uopIdx;
    uopwriteback_r.data = io_uopwriteback_bits_r_data;
  end

  // ---- 反馈打拍 RegEnable(feedbackOut, feedbackValid)：golden 留下的 6 个字段 ----
  logic          io_feedback_bits_r_robIdx_flag;
  logic [7:0]    io_feedback_bits_r_robIdx_value;
  logic          io_feedback_bits_r_sqIdx_flag;
  logic [5:0]    io_feedback_bits_r_sqIdx_value;
  logic          io_feedback_bits_r_lqIdx_flag;
  logic [6:0]    io_feedback_bits_r_lqIdx_value;
  always_ff @(posedge clock) begin
    if (feedbackValid) begin
      io_feedback_bits_r_robIdx_flag <= feedbackOut.robIdx_flag;
      io_feedback_bits_r_robIdx_value <= feedbackOut.robIdx_value;
      io_feedback_bits_r_sqIdx_flag <= feedbackOut.sqIdx_flag;
      io_feedback_bits_r_sqIdx_value <= feedbackOut.sqIdx_value;
      io_feedback_bits_r_lqIdx_flag <= feedbackOut.lqIdx_flag;
      io_feedback_bits_r_lqIdx_value <= feedbackOut.lqIdx_value;
    end
  end
  always_comb begin
    feedback_r = '0;
    feedback_r.robIdx_flag = io_feedback_bits_r_robIdx_flag;
    feedback_r.robIdx_value = io_feedback_bits_r_robIdx_value;
    feedback_r.sqIdx_flag = io_feedback_bits_r_sqIdx_flag;
    feedback_r.sqIdx_value = io_feedback_bits_r_sqIdx_value;
    feedback_r.lqIdx_flag = io_feedback_bits_r_lqIdx_flag;
    feedback_r.lqIdx_value = io_feedback_bits_r_lqIdx_value;
  end

  // ---- uop 队列第 0 项 <= in.uop（入队时装入，无复位）：golden 留下的 26 个字段 ----
  logic [34:0]   uopq_0_uop_fuType;
  logic [8:0]    uopq_0_uop_fuOpType;
  logic          uopq_0_uop_vecWen;
  logic          uopq_0_uop_v0Wen;
  logic          uopq_0_uop_vlWen;
  logic [6:0]    uopq_0_uop_vpu_vuopIdx;
  logic [2:0]    uopq_0_uop_vpu_nf;
  logic [1:0]    uopq_0_uop_vpu_veew;
  logic [7:0]    uopq_0_uop_pdest;
  logic [7:0]    uopq_0_uop_robIdx_value;
  logic          uopq_0_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_0_uop_debugInfo_renameTime;
  logic [63:0]   uopq_0_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_0_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_0_uop_debugInfo_selectTime;
  logic [63:0]   uopq_0_uop_debugInfo_issueTime;
  logic [63:0]   uopq_0_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_0_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_0_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_0_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_0_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_0_uop_debug_seqNum_uopIdx;
  logic          uopq_0_uop_lqIdx_flag;
  logic [6:0]    uopq_0_uop_lqIdx_value;
  logic          uopq_0_uop_sqIdx_flag;
  logic [5:0]    uopq_0_uop_sqIdx_value;
  always_ff @(posedge clock) begin
    if (uopq_we[0]) begin
      uopq_0_uop_fuType <= in.uop.fuType;
      uopq_0_uop_fuOpType <= in.uop.fuOpType;
      uopq_0_uop_vecWen <= in.uop.vecWen;
      uopq_0_uop_v0Wen <= in.uop.v0Wen;
      uopq_0_uop_vlWen <= in.uop.vlWen;
      uopq_0_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_0_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_0_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_0_uop_pdest <= in.uop.pdest;
      uopq_0_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_0_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_0_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_0_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_0_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_0_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_0_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_0_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_0_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_0_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_0_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_0_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_0_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_0_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_0_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_0_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_0_uop_sqIdx_value <= in.uop.sqIdx_value;
    end
  end
  always_comb begin
    uopq_uop[0] = '0;
    uopq_uop[0].fuType = uopq_0_uop_fuType;
    uopq_uop[0].fuOpType = uopq_0_uop_fuOpType;
    uopq_uop[0].vecWen = uopq_0_uop_vecWen;
    uopq_uop[0].v0Wen = uopq_0_uop_v0Wen;
    uopq_uop[0].vlWen = uopq_0_uop_vlWen;
    uopq_uop[0].vpu_vuopIdx = uopq_0_uop_vpu_vuopIdx;
    uopq_uop[0].vpu_nf = uopq_0_uop_vpu_nf;
    uopq_uop[0].vpu_veew = uopq_0_uop_vpu_veew;
    uopq_uop[0].pdest = uopq_0_uop_pdest;
    uopq_uop[0].robIdx_value = uopq_0_uop_robIdx_value;
    uopq_uop[0].debugInfo_eliminatedMove = uopq_0_uop_debugInfo_eliminatedMove;
    uopq_uop[0].debugInfo_renameTime = uopq_0_uop_debugInfo_renameTime;
    uopq_uop[0].debugInfo_dispatchTime = uopq_0_uop_debugInfo_dispatchTime;
    uopq_uop[0].debugInfo_enqRsTime = uopq_0_uop_debugInfo_enqRsTime;
    uopq_uop[0].debugInfo_selectTime = uopq_0_uop_debugInfo_selectTime;
    uopq_uop[0].debugInfo_issueTime = uopq_0_uop_debugInfo_issueTime;
    uopq_uop[0].debugInfo_writebackTime = uopq_0_uop_debugInfo_writebackTime;
    uopq_uop[0].debugInfo_runahead_checkpoint_id = uopq_0_uop_debugInfo_runahead_checkpoint_id;
    uopq_uop[0].debugInfo_tlbFirstReqTime = uopq_0_uop_debugInfo_tlbFirstReqTime;
    uopq_uop[0].debugInfo_tlbRespTime = uopq_0_uop_debugInfo_tlbRespTime;
    uopq_uop[0].debug_seqNum_seqNum = uopq_0_uop_debug_seqNum_seqNum;
    uopq_uop[0].debug_seqNum_uopIdx = uopq_0_uop_debug_seqNum_uopIdx;
    uopq_uop[0].lqIdx_flag = uopq_0_uop_lqIdx_flag;
    uopq_uop[0].lqIdx_value = uopq_0_uop_lqIdx_value;
    uopq_uop[0].sqIdx_flag = uopq_0_uop_sqIdx_flag;
    uopq_uop[0].sqIdx_value = uopq_0_uop_sqIdx_value;
  end

  // ---- uop 队列第 1 项 <= in.uop（入队时装入，无复位）：golden 留下的 26 个字段 ----
  logic [34:0]   uopq_1_uop_fuType;
  logic [8:0]    uopq_1_uop_fuOpType;
  logic          uopq_1_uop_vecWen;
  logic          uopq_1_uop_v0Wen;
  logic          uopq_1_uop_vlWen;
  logic [6:0]    uopq_1_uop_vpu_vuopIdx;
  logic [2:0]    uopq_1_uop_vpu_nf;
  logic [1:0]    uopq_1_uop_vpu_veew;
  logic [7:0]    uopq_1_uop_pdest;
  logic [7:0]    uopq_1_uop_robIdx_value;
  logic          uopq_1_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_1_uop_debugInfo_renameTime;
  logic [63:0]   uopq_1_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_1_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_1_uop_debugInfo_selectTime;
  logic [63:0]   uopq_1_uop_debugInfo_issueTime;
  logic [63:0]   uopq_1_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_1_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_1_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_1_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_1_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_1_uop_debug_seqNum_uopIdx;
  logic          uopq_1_uop_lqIdx_flag;
  logic [6:0]    uopq_1_uop_lqIdx_value;
  logic          uopq_1_uop_sqIdx_flag;
  logic [5:0]    uopq_1_uop_sqIdx_value;
  always_ff @(posedge clock) begin
    if (uopq_we[1]) begin
      uopq_1_uop_fuType <= in.uop.fuType;
      uopq_1_uop_fuOpType <= in.uop.fuOpType;
      uopq_1_uop_vecWen <= in.uop.vecWen;
      uopq_1_uop_v0Wen <= in.uop.v0Wen;
      uopq_1_uop_vlWen <= in.uop.vlWen;
      uopq_1_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_1_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_1_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_1_uop_pdest <= in.uop.pdest;
      uopq_1_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_1_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_1_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_1_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_1_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_1_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_1_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_1_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_1_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_1_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_1_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_1_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_1_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_1_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_1_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_1_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_1_uop_sqIdx_value <= in.uop.sqIdx_value;
    end
  end
  always_comb begin
    uopq_uop[1] = '0;
    uopq_uop[1].fuType = uopq_1_uop_fuType;
    uopq_uop[1].fuOpType = uopq_1_uop_fuOpType;
    uopq_uop[1].vecWen = uopq_1_uop_vecWen;
    uopq_uop[1].v0Wen = uopq_1_uop_v0Wen;
    uopq_uop[1].vlWen = uopq_1_uop_vlWen;
    uopq_uop[1].vpu_vuopIdx = uopq_1_uop_vpu_vuopIdx;
    uopq_uop[1].vpu_nf = uopq_1_uop_vpu_nf;
    uopq_uop[1].vpu_veew = uopq_1_uop_vpu_veew;
    uopq_uop[1].pdest = uopq_1_uop_pdest;
    uopq_uop[1].robIdx_value = uopq_1_uop_robIdx_value;
    uopq_uop[1].debugInfo_eliminatedMove = uopq_1_uop_debugInfo_eliminatedMove;
    uopq_uop[1].debugInfo_renameTime = uopq_1_uop_debugInfo_renameTime;
    uopq_uop[1].debugInfo_dispatchTime = uopq_1_uop_debugInfo_dispatchTime;
    uopq_uop[1].debugInfo_enqRsTime = uopq_1_uop_debugInfo_enqRsTime;
    uopq_uop[1].debugInfo_selectTime = uopq_1_uop_debugInfo_selectTime;
    uopq_uop[1].debugInfo_issueTime = uopq_1_uop_debugInfo_issueTime;
    uopq_uop[1].debugInfo_writebackTime = uopq_1_uop_debugInfo_writebackTime;
    uopq_uop[1].debugInfo_runahead_checkpoint_id = uopq_1_uop_debugInfo_runahead_checkpoint_id;
    uopq_uop[1].debugInfo_tlbFirstReqTime = uopq_1_uop_debugInfo_tlbFirstReqTime;
    uopq_uop[1].debugInfo_tlbRespTime = uopq_1_uop_debugInfo_tlbRespTime;
    uopq_uop[1].debug_seqNum_seqNum = uopq_1_uop_debug_seqNum_seqNum;
    uopq_uop[1].debug_seqNum_uopIdx = uopq_1_uop_debug_seqNum_uopIdx;
    uopq_uop[1].lqIdx_flag = uopq_1_uop_lqIdx_flag;
    uopq_uop[1].lqIdx_value = uopq_1_uop_lqIdx_value;
    uopq_uop[1].sqIdx_flag = uopq_1_uop_sqIdx_flag;
    uopq_uop[1].sqIdx_value = uopq_1_uop_sqIdx_value;
  end

  // ---- uop 队列第 2 项 <= in.uop（入队时装入，无复位）：golden 留下的 26 个字段 ----
  logic [34:0]   uopq_2_uop_fuType;
  logic [8:0]    uopq_2_uop_fuOpType;
  logic          uopq_2_uop_vecWen;
  logic          uopq_2_uop_v0Wen;
  logic          uopq_2_uop_vlWen;
  logic [6:0]    uopq_2_uop_vpu_vuopIdx;
  logic [2:0]    uopq_2_uop_vpu_nf;
  logic [1:0]    uopq_2_uop_vpu_veew;
  logic [7:0]    uopq_2_uop_pdest;
  logic [7:0]    uopq_2_uop_robIdx_value;
  logic          uopq_2_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_2_uop_debugInfo_renameTime;
  logic [63:0]   uopq_2_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_2_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_2_uop_debugInfo_selectTime;
  logic [63:0]   uopq_2_uop_debugInfo_issueTime;
  logic [63:0]   uopq_2_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_2_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_2_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_2_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_2_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_2_uop_debug_seqNum_uopIdx;
  logic          uopq_2_uop_lqIdx_flag;
  logic [6:0]    uopq_2_uop_lqIdx_value;
  logic          uopq_2_uop_sqIdx_flag;
  logic [5:0]    uopq_2_uop_sqIdx_value;
  always_ff @(posedge clock) begin
    if (uopq_we[2]) begin
      uopq_2_uop_fuType <= in.uop.fuType;
      uopq_2_uop_fuOpType <= in.uop.fuOpType;
      uopq_2_uop_vecWen <= in.uop.vecWen;
      uopq_2_uop_v0Wen <= in.uop.v0Wen;
      uopq_2_uop_vlWen <= in.uop.vlWen;
      uopq_2_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_2_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_2_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_2_uop_pdest <= in.uop.pdest;
      uopq_2_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_2_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_2_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_2_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_2_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_2_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_2_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_2_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_2_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_2_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_2_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_2_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_2_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_2_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_2_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_2_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_2_uop_sqIdx_value <= in.uop.sqIdx_value;
    end
  end
  always_comb begin
    uopq_uop[2] = '0;
    uopq_uop[2].fuType = uopq_2_uop_fuType;
    uopq_uop[2].fuOpType = uopq_2_uop_fuOpType;
    uopq_uop[2].vecWen = uopq_2_uop_vecWen;
    uopq_uop[2].v0Wen = uopq_2_uop_v0Wen;
    uopq_uop[2].vlWen = uopq_2_uop_vlWen;
    uopq_uop[2].vpu_vuopIdx = uopq_2_uop_vpu_vuopIdx;
    uopq_uop[2].vpu_nf = uopq_2_uop_vpu_nf;
    uopq_uop[2].vpu_veew = uopq_2_uop_vpu_veew;
    uopq_uop[2].pdest = uopq_2_uop_pdest;
    uopq_uop[2].robIdx_value = uopq_2_uop_robIdx_value;
    uopq_uop[2].debugInfo_eliminatedMove = uopq_2_uop_debugInfo_eliminatedMove;
    uopq_uop[2].debugInfo_renameTime = uopq_2_uop_debugInfo_renameTime;
    uopq_uop[2].debugInfo_dispatchTime = uopq_2_uop_debugInfo_dispatchTime;
    uopq_uop[2].debugInfo_enqRsTime = uopq_2_uop_debugInfo_enqRsTime;
    uopq_uop[2].debugInfo_selectTime = uopq_2_uop_debugInfo_selectTime;
    uopq_uop[2].debugInfo_issueTime = uopq_2_uop_debugInfo_issueTime;
    uopq_uop[2].debugInfo_writebackTime = uopq_2_uop_debugInfo_writebackTime;
    uopq_uop[2].debugInfo_runahead_checkpoint_id = uopq_2_uop_debugInfo_runahead_checkpoint_id;
    uopq_uop[2].debugInfo_tlbFirstReqTime = uopq_2_uop_debugInfo_tlbFirstReqTime;
    uopq_uop[2].debugInfo_tlbRespTime = uopq_2_uop_debugInfo_tlbRespTime;
    uopq_uop[2].debug_seqNum_seqNum = uopq_2_uop_debug_seqNum_seqNum;
    uopq_uop[2].debug_seqNum_uopIdx = uopq_2_uop_debug_seqNum_uopIdx;
    uopq_uop[2].lqIdx_flag = uopq_2_uop_lqIdx_flag;
    uopq_uop[2].lqIdx_value = uopq_2_uop_lqIdx_value;
    uopq_uop[2].sqIdx_flag = uopq_2_uop_sqIdx_flag;
    uopq_uop[2].sqIdx_value = uopq_2_uop_sqIdx_value;
  end

  // ---- uop 队列第 3 项 <= in.uop（入队时装入，无复位）：golden 留下的 26 个字段 ----
  logic [34:0]   uopq_3_uop_fuType;
  logic [8:0]    uopq_3_uop_fuOpType;
  logic          uopq_3_uop_vecWen;
  logic          uopq_3_uop_v0Wen;
  logic          uopq_3_uop_vlWen;
  logic [6:0]    uopq_3_uop_vpu_vuopIdx;
  logic [2:0]    uopq_3_uop_vpu_nf;
  logic [1:0]    uopq_3_uop_vpu_veew;
  logic [7:0]    uopq_3_uop_pdest;
  logic [7:0]    uopq_3_uop_robIdx_value;
  logic          uopq_3_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_3_uop_debugInfo_renameTime;
  logic [63:0]   uopq_3_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_3_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_3_uop_debugInfo_selectTime;
  logic [63:0]   uopq_3_uop_debugInfo_issueTime;
  logic [63:0]   uopq_3_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_3_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_3_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_3_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_3_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_3_uop_debug_seqNum_uopIdx;
  logic          uopq_3_uop_lqIdx_flag;
  logic [6:0]    uopq_3_uop_lqIdx_value;
  logic          uopq_3_uop_sqIdx_flag;
  logic [5:0]    uopq_3_uop_sqIdx_value;
  always_ff @(posedge clock) begin
    if (uopq_we[3]) begin
      uopq_3_uop_fuType <= in.uop.fuType;
      uopq_3_uop_fuOpType <= in.uop.fuOpType;
      uopq_3_uop_vecWen <= in.uop.vecWen;
      uopq_3_uop_v0Wen <= in.uop.v0Wen;
      uopq_3_uop_vlWen <= in.uop.vlWen;
      uopq_3_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_3_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_3_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_3_uop_pdest <= in.uop.pdest;
      uopq_3_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_3_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_3_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_3_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_3_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_3_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_3_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_3_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_3_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_3_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_3_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_3_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_3_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_3_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_3_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_3_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_3_uop_sqIdx_value <= in.uop.sqIdx_value;
    end
  end
  always_comb begin
    uopq_uop[3] = '0;
    uopq_uop[3].fuType = uopq_3_uop_fuType;
    uopq_uop[3].fuOpType = uopq_3_uop_fuOpType;
    uopq_uop[3].vecWen = uopq_3_uop_vecWen;
    uopq_uop[3].v0Wen = uopq_3_uop_v0Wen;
    uopq_uop[3].vlWen = uopq_3_uop_vlWen;
    uopq_uop[3].vpu_vuopIdx = uopq_3_uop_vpu_vuopIdx;
    uopq_uop[3].vpu_nf = uopq_3_uop_vpu_nf;
    uopq_uop[3].vpu_veew = uopq_3_uop_vpu_veew;
    uopq_uop[3].pdest = uopq_3_uop_pdest;
    uopq_uop[3].robIdx_value = uopq_3_uop_robIdx_value;
    uopq_uop[3].debugInfo_eliminatedMove = uopq_3_uop_debugInfo_eliminatedMove;
    uopq_uop[3].debugInfo_renameTime = uopq_3_uop_debugInfo_renameTime;
    uopq_uop[3].debugInfo_dispatchTime = uopq_3_uop_debugInfo_dispatchTime;
    uopq_uop[3].debugInfo_enqRsTime = uopq_3_uop_debugInfo_enqRsTime;
    uopq_uop[3].debugInfo_selectTime = uopq_3_uop_debugInfo_selectTime;
    uopq_uop[3].debugInfo_issueTime = uopq_3_uop_debugInfo_issueTime;
    uopq_uop[3].debugInfo_writebackTime = uopq_3_uop_debugInfo_writebackTime;
    uopq_uop[3].debugInfo_runahead_checkpoint_id = uopq_3_uop_debugInfo_runahead_checkpoint_id;
    uopq_uop[3].debugInfo_tlbFirstReqTime = uopq_3_uop_debugInfo_tlbFirstReqTime;
    uopq_uop[3].debugInfo_tlbRespTime = uopq_3_uop_debugInfo_tlbRespTime;
    uopq_uop[3].debug_seqNum_seqNum = uopq_3_uop_debug_seqNum_seqNum;
    uopq_uop[3].debug_seqNum_uopIdx = uopq_3_uop_debug_seqNum_uopIdx;
    uopq_uop[3].lqIdx_flag = uopq_3_uop_lqIdx_flag;
    uopq_uop[3].lqIdx_value = uopq_3_uop_lqIdx_value;
    uopq_uop[3].sqIdx_flag = uopq_3_uop_sqIdx_flag;
    uopq_uop[3].sqIdx_value = uopq_3_uop_sqIdx_value;
  end

  // ---- uop 队列第 4 项 <= in.uop（入队时装入，无复位）：golden 留下的 26 个字段 ----
  logic [34:0]   uopq_4_uop_fuType;
  logic [8:0]    uopq_4_uop_fuOpType;
  logic          uopq_4_uop_vecWen;
  logic          uopq_4_uop_v0Wen;
  logic          uopq_4_uop_vlWen;
  logic [6:0]    uopq_4_uop_vpu_vuopIdx;
  logic [2:0]    uopq_4_uop_vpu_nf;
  logic [1:0]    uopq_4_uop_vpu_veew;
  logic [7:0]    uopq_4_uop_pdest;
  logic [7:0]    uopq_4_uop_robIdx_value;
  logic          uopq_4_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_4_uop_debugInfo_renameTime;
  logic [63:0]   uopq_4_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_4_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_4_uop_debugInfo_selectTime;
  logic [63:0]   uopq_4_uop_debugInfo_issueTime;
  logic [63:0]   uopq_4_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_4_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_4_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_4_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_4_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_4_uop_debug_seqNum_uopIdx;
  logic          uopq_4_uop_lqIdx_flag;
  logic [6:0]    uopq_4_uop_lqIdx_value;
  logic          uopq_4_uop_sqIdx_flag;
  logic [5:0]    uopq_4_uop_sqIdx_value;
  always_ff @(posedge clock) begin
    if (uopq_we[4]) begin
      uopq_4_uop_fuType <= in.uop.fuType;
      uopq_4_uop_fuOpType <= in.uop.fuOpType;
      uopq_4_uop_vecWen <= in.uop.vecWen;
      uopq_4_uop_v0Wen <= in.uop.v0Wen;
      uopq_4_uop_vlWen <= in.uop.vlWen;
      uopq_4_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_4_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_4_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_4_uop_pdest <= in.uop.pdest;
      uopq_4_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_4_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_4_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_4_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_4_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_4_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_4_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_4_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_4_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_4_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_4_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_4_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_4_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_4_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_4_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_4_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_4_uop_sqIdx_value <= in.uop.sqIdx_value;
    end
  end
  always_comb begin
    uopq_uop[4] = '0;
    uopq_uop[4].fuType = uopq_4_uop_fuType;
    uopq_uop[4].fuOpType = uopq_4_uop_fuOpType;
    uopq_uop[4].vecWen = uopq_4_uop_vecWen;
    uopq_uop[4].v0Wen = uopq_4_uop_v0Wen;
    uopq_uop[4].vlWen = uopq_4_uop_vlWen;
    uopq_uop[4].vpu_vuopIdx = uopq_4_uop_vpu_vuopIdx;
    uopq_uop[4].vpu_nf = uopq_4_uop_vpu_nf;
    uopq_uop[4].vpu_veew = uopq_4_uop_vpu_veew;
    uopq_uop[4].pdest = uopq_4_uop_pdest;
    uopq_uop[4].robIdx_value = uopq_4_uop_robIdx_value;
    uopq_uop[4].debugInfo_eliminatedMove = uopq_4_uop_debugInfo_eliminatedMove;
    uopq_uop[4].debugInfo_renameTime = uopq_4_uop_debugInfo_renameTime;
    uopq_uop[4].debugInfo_dispatchTime = uopq_4_uop_debugInfo_dispatchTime;
    uopq_uop[4].debugInfo_enqRsTime = uopq_4_uop_debugInfo_enqRsTime;
    uopq_uop[4].debugInfo_selectTime = uopq_4_uop_debugInfo_selectTime;
    uopq_uop[4].debugInfo_issueTime = uopq_4_uop_debugInfo_issueTime;
    uopq_uop[4].debugInfo_writebackTime = uopq_4_uop_debugInfo_writebackTime;
    uopq_uop[4].debugInfo_runahead_checkpoint_id = uopq_4_uop_debugInfo_runahead_checkpoint_id;
    uopq_uop[4].debugInfo_tlbFirstReqTime = uopq_4_uop_debugInfo_tlbFirstReqTime;
    uopq_uop[4].debugInfo_tlbRespTime = uopq_4_uop_debugInfo_tlbRespTime;
    uopq_uop[4].debug_seqNum_seqNum = uopq_4_uop_debug_seqNum_seqNum;
    uopq_uop[4].debug_seqNum_uopIdx = uopq_4_uop_debug_seqNum_uopIdx;
    uopq_uop[4].lqIdx_flag = uopq_4_uop_lqIdx_flag;
    uopq_uop[4].lqIdx_value = uopq_4_uop_lqIdx_value;
    uopq_uop[4].sqIdx_flag = uopq_4_uop_sqIdx_flag;
    uopq_uop[4].sqIdx_value = uopq_4_uop_sqIdx_value;
  end

  // ---- uop 队列第 5 项 <= in.uop（入队时装入，无复位）：golden 留下的 26 个字段 ----
  logic [34:0]   uopq_5_uop_fuType;
  logic [8:0]    uopq_5_uop_fuOpType;
  logic          uopq_5_uop_vecWen;
  logic          uopq_5_uop_v0Wen;
  logic          uopq_5_uop_vlWen;
  logic [6:0]    uopq_5_uop_vpu_vuopIdx;
  logic [2:0]    uopq_5_uop_vpu_nf;
  logic [1:0]    uopq_5_uop_vpu_veew;
  logic [7:0]    uopq_5_uop_pdest;
  logic [7:0]    uopq_5_uop_robIdx_value;
  logic          uopq_5_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_5_uop_debugInfo_renameTime;
  logic [63:0]   uopq_5_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_5_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_5_uop_debugInfo_selectTime;
  logic [63:0]   uopq_5_uop_debugInfo_issueTime;
  logic [63:0]   uopq_5_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_5_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_5_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_5_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_5_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_5_uop_debug_seqNum_uopIdx;
  logic          uopq_5_uop_lqIdx_flag;
  logic [6:0]    uopq_5_uop_lqIdx_value;
  logic          uopq_5_uop_sqIdx_flag;
  logic [5:0]    uopq_5_uop_sqIdx_value;
  always_ff @(posedge clock) begin
    if (uopq_we[5]) begin
      uopq_5_uop_fuType <= in.uop.fuType;
      uopq_5_uop_fuOpType <= in.uop.fuOpType;
      uopq_5_uop_vecWen <= in.uop.vecWen;
      uopq_5_uop_v0Wen <= in.uop.v0Wen;
      uopq_5_uop_vlWen <= in.uop.vlWen;
      uopq_5_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_5_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_5_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_5_uop_pdest <= in.uop.pdest;
      uopq_5_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_5_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_5_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_5_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_5_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_5_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_5_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_5_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_5_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_5_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_5_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_5_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_5_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_5_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_5_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_5_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_5_uop_sqIdx_value <= in.uop.sqIdx_value;
    end
  end
  always_comb begin
    uopq_uop[5] = '0;
    uopq_uop[5].fuType = uopq_5_uop_fuType;
    uopq_uop[5].fuOpType = uopq_5_uop_fuOpType;
    uopq_uop[5].vecWen = uopq_5_uop_vecWen;
    uopq_uop[5].v0Wen = uopq_5_uop_v0Wen;
    uopq_uop[5].vlWen = uopq_5_uop_vlWen;
    uopq_uop[5].vpu_vuopIdx = uopq_5_uop_vpu_vuopIdx;
    uopq_uop[5].vpu_nf = uopq_5_uop_vpu_nf;
    uopq_uop[5].vpu_veew = uopq_5_uop_vpu_veew;
    uopq_uop[5].pdest = uopq_5_uop_pdest;
    uopq_uop[5].robIdx_value = uopq_5_uop_robIdx_value;
    uopq_uop[5].debugInfo_eliminatedMove = uopq_5_uop_debugInfo_eliminatedMove;
    uopq_uop[5].debugInfo_renameTime = uopq_5_uop_debugInfo_renameTime;
    uopq_uop[5].debugInfo_dispatchTime = uopq_5_uop_debugInfo_dispatchTime;
    uopq_uop[5].debugInfo_enqRsTime = uopq_5_uop_debugInfo_enqRsTime;
    uopq_uop[5].debugInfo_selectTime = uopq_5_uop_debugInfo_selectTime;
    uopq_uop[5].debugInfo_issueTime = uopq_5_uop_debugInfo_issueTime;
    uopq_uop[5].debugInfo_writebackTime = uopq_5_uop_debugInfo_writebackTime;
    uopq_uop[5].debugInfo_runahead_checkpoint_id = uopq_5_uop_debugInfo_runahead_checkpoint_id;
    uopq_uop[5].debugInfo_tlbFirstReqTime = uopq_5_uop_debugInfo_tlbFirstReqTime;
    uopq_uop[5].debugInfo_tlbRespTime = uopq_5_uop_debugInfo_tlbRespTime;
    uopq_uop[5].debug_seqNum_seqNum = uopq_5_uop_debug_seqNum_seqNum;
    uopq_uop[5].debug_seqNum_uopIdx = uopq_5_uop_debug_seqNum_uopIdx;
    uopq_uop[5].lqIdx_flag = uopq_5_uop_lqIdx_flag;
    uopq_uop[5].lqIdx_value = uopq_5_uop_lqIdx_value;
    uopq_uop[5].sqIdx_flag = uopq_5_uop_sqIdx_flag;
    uopq_uop[5].sqIdx_value = uopq_5_uop_sqIdx_value;
  end

  // ---- uop 队列第 6 项 <= in.uop（入队时装入，无复位）：golden 留下的 26 个字段 ----
  logic [34:0]   uopq_6_uop_fuType;
  logic [8:0]    uopq_6_uop_fuOpType;
  logic          uopq_6_uop_vecWen;
  logic          uopq_6_uop_v0Wen;
  logic          uopq_6_uop_vlWen;
  logic [6:0]    uopq_6_uop_vpu_vuopIdx;
  logic [2:0]    uopq_6_uop_vpu_nf;
  logic [1:0]    uopq_6_uop_vpu_veew;
  logic [7:0]    uopq_6_uop_pdest;
  logic [7:0]    uopq_6_uop_robIdx_value;
  logic          uopq_6_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_6_uop_debugInfo_renameTime;
  logic [63:0]   uopq_6_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_6_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_6_uop_debugInfo_selectTime;
  logic [63:0]   uopq_6_uop_debugInfo_issueTime;
  logic [63:0]   uopq_6_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_6_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_6_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_6_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_6_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_6_uop_debug_seqNum_uopIdx;
  logic          uopq_6_uop_lqIdx_flag;
  logic [6:0]    uopq_6_uop_lqIdx_value;
  logic          uopq_6_uop_sqIdx_flag;
  logic [5:0]    uopq_6_uop_sqIdx_value;
  always_ff @(posedge clock) begin
    if (uopq_we[6]) begin
      uopq_6_uop_fuType <= in.uop.fuType;
      uopq_6_uop_fuOpType <= in.uop.fuOpType;
      uopq_6_uop_vecWen <= in.uop.vecWen;
      uopq_6_uop_v0Wen <= in.uop.v0Wen;
      uopq_6_uop_vlWen <= in.uop.vlWen;
      uopq_6_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_6_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_6_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_6_uop_pdest <= in.uop.pdest;
      uopq_6_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_6_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_6_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_6_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_6_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_6_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_6_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_6_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_6_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_6_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_6_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_6_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_6_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_6_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_6_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_6_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_6_uop_sqIdx_value <= in.uop.sqIdx_value;
    end
  end
  always_comb begin
    uopq_uop[6] = '0;
    uopq_uop[6].fuType = uopq_6_uop_fuType;
    uopq_uop[6].fuOpType = uopq_6_uop_fuOpType;
    uopq_uop[6].vecWen = uopq_6_uop_vecWen;
    uopq_uop[6].v0Wen = uopq_6_uop_v0Wen;
    uopq_uop[6].vlWen = uopq_6_uop_vlWen;
    uopq_uop[6].vpu_vuopIdx = uopq_6_uop_vpu_vuopIdx;
    uopq_uop[6].vpu_nf = uopq_6_uop_vpu_nf;
    uopq_uop[6].vpu_veew = uopq_6_uop_vpu_veew;
    uopq_uop[6].pdest = uopq_6_uop_pdest;
    uopq_uop[6].robIdx_value = uopq_6_uop_robIdx_value;
    uopq_uop[6].debugInfo_eliminatedMove = uopq_6_uop_debugInfo_eliminatedMove;
    uopq_uop[6].debugInfo_renameTime = uopq_6_uop_debugInfo_renameTime;
    uopq_uop[6].debugInfo_dispatchTime = uopq_6_uop_debugInfo_dispatchTime;
    uopq_uop[6].debugInfo_enqRsTime = uopq_6_uop_debugInfo_enqRsTime;
    uopq_uop[6].debugInfo_selectTime = uopq_6_uop_debugInfo_selectTime;
    uopq_uop[6].debugInfo_issueTime = uopq_6_uop_debugInfo_issueTime;
    uopq_uop[6].debugInfo_writebackTime = uopq_6_uop_debugInfo_writebackTime;
    uopq_uop[6].debugInfo_runahead_checkpoint_id = uopq_6_uop_debugInfo_runahead_checkpoint_id;
    uopq_uop[6].debugInfo_tlbFirstReqTime = uopq_6_uop_debugInfo_tlbFirstReqTime;
    uopq_uop[6].debugInfo_tlbRespTime = uopq_6_uop_debugInfo_tlbRespTime;
    uopq_uop[6].debug_seqNum_seqNum = uopq_6_uop_debug_seqNum_seqNum;
    uopq_uop[6].debug_seqNum_uopIdx = uopq_6_uop_debug_seqNum_uopIdx;
    uopq_uop[6].lqIdx_flag = uopq_6_uop_lqIdx_flag;
    uopq_uop[6].lqIdx_value = uopq_6_uop_lqIdx_value;
    uopq_uop[6].sqIdx_flag = uopq_6_uop_sqIdx_flag;
    uopq_uop[6].sqIdx_value = uopq_6_uop_sqIdx_value;
  end

  // ---- uop 队列第 7 项 <= in.uop（入队时装入，无复位）：golden 留下的 26 个字段 ----
  logic [34:0]   uopq_7_uop_fuType;
  logic [8:0]    uopq_7_uop_fuOpType;
  logic          uopq_7_uop_vecWen;
  logic          uopq_7_uop_v0Wen;
  logic          uopq_7_uop_vlWen;
  logic [6:0]    uopq_7_uop_vpu_vuopIdx;
  logic [2:0]    uopq_7_uop_vpu_nf;
  logic [1:0]    uopq_7_uop_vpu_veew;
  logic [7:0]    uopq_7_uop_pdest;
  logic [7:0]    uopq_7_uop_robIdx_value;
  logic          uopq_7_uop_debugInfo_eliminatedMove;
  logic [63:0]   uopq_7_uop_debugInfo_renameTime;
  logic [63:0]   uopq_7_uop_debugInfo_dispatchTime;
  logic [63:0]   uopq_7_uop_debugInfo_enqRsTime;
  logic [63:0]   uopq_7_uop_debugInfo_selectTime;
  logic [63:0]   uopq_7_uop_debugInfo_issueTime;
  logic [63:0]   uopq_7_uop_debugInfo_writebackTime;
  logic [63:0]   uopq_7_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   uopq_7_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   uopq_7_uop_debugInfo_tlbRespTime;
  logic [55:0]   uopq_7_uop_debug_seqNum_seqNum;
  logic [7:0]    uopq_7_uop_debug_seqNum_uopIdx;
  logic          uopq_7_uop_lqIdx_flag;
  logic [6:0]    uopq_7_uop_lqIdx_value;
  logic          uopq_7_uop_sqIdx_flag;
  logic [5:0]    uopq_7_uop_sqIdx_value;
  always_ff @(posedge clock) begin
    if (uopq_we[7]) begin
      uopq_7_uop_fuType <= in.uop.fuType;
      uopq_7_uop_fuOpType <= in.uop.fuOpType;
      uopq_7_uop_vecWen <= in.uop.vecWen;
      uopq_7_uop_v0Wen <= in.uop.v0Wen;
      uopq_7_uop_vlWen <= in.uop.vlWen;
      uopq_7_uop_vpu_vuopIdx <= in.uop.vpu_vuopIdx;
      uopq_7_uop_vpu_nf <= in.uop.vpu_nf;
      uopq_7_uop_vpu_veew <= in.uop.vpu_veew;
      uopq_7_uop_pdest <= in.uop.pdest;
      uopq_7_uop_robIdx_value <= in.uop.robIdx_value;
      uopq_7_uop_debugInfo_eliminatedMove <= in.uop.debugInfo_eliminatedMove;
      uopq_7_uop_debugInfo_renameTime <= in.uop.debugInfo_renameTime;
      uopq_7_uop_debugInfo_dispatchTime <= in.uop.debugInfo_dispatchTime;
      uopq_7_uop_debugInfo_enqRsTime <= in.uop.debugInfo_enqRsTime;
      uopq_7_uop_debugInfo_selectTime <= in.uop.debugInfo_selectTime;
      uopq_7_uop_debugInfo_issueTime <= in.uop.debugInfo_issueTime;
      uopq_7_uop_debugInfo_writebackTime <= in.uop.debugInfo_writebackTime;
      uopq_7_uop_debugInfo_runahead_checkpoint_id <= in.uop.debugInfo_runahead_checkpoint_id;
      uopq_7_uop_debugInfo_tlbFirstReqTime <= in.uop.debugInfo_tlbFirstReqTime;
      uopq_7_uop_debugInfo_tlbRespTime <= in.uop.debugInfo_tlbRespTime;
      uopq_7_uop_debug_seqNum_seqNum <= in.uop.debug_seqNum_seqNum;
      uopq_7_uop_debug_seqNum_uopIdx <= in.uop.debug_seqNum_uopIdx;
      uopq_7_uop_lqIdx_flag <= in.uop.lqIdx_flag;
      uopq_7_uop_lqIdx_value <= in.uop.lqIdx_value;
      uopq_7_uop_sqIdx_flag <= in.uop.sqIdx_flag;
      uopq_7_uop_sqIdx_value <= in.uop.sqIdx_value;
    end
  end
  always_comb begin
    uopq_uop[7] = '0;
    uopq_uop[7].fuType = uopq_7_uop_fuType;
    uopq_uop[7].fuOpType = uopq_7_uop_fuOpType;
    uopq_uop[7].vecWen = uopq_7_uop_vecWen;
    uopq_uop[7].v0Wen = uopq_7_uop_v0Wen;
    uopq_uop[7].vlWen = uopq_7_uop_vlWen;
    uopq_uop[7].vpu_vuopIdx = uopq_7_uop_vpu_vuopIdx;
    uopq_uop[7].vpu_nf = uopq_7_uop_vpu_nf;
    uopq_uop[7].vpu_veew = uopq_7_uop_vpu_veew;
    uopq_uop[7].pdest = uopq_7_uop_pdest;
    uopq_uop[7].robIdx_value = uopq_7_uop_robIdx_value;
    uopq_uop[7].debugInfo_eliminatedMove = uopq_7_uop_debugInfo_eliminatedMove;
    uopq_uop[7].debugInfo_renameTime = uopq_7_uop_debugInfo_renameTime;
    uopq_uop[7].debugInfo_dispatchTime = uopq_7_uop_debugInfo_dispatchTime;
    uopq_uop[7].debugInfo_enqRsTime = uopq_7_uop_debugInfo_enqRsTime;
    uopq_uop[7].debugInfo_selectTime = uopq_7_uop_debugInfo_selectTime;
    uopq_uop[7].debugInfo_issueTime = uopq_7_uop_debugInfo_issueTime;
    uopq_uop[7].debugInfo_writebackTime = uopq_7_uop_debugInfo_writebackTime;
    uopq_uop[7].debugInfo_runahead_checkpoint_id = uopq_7_uop_debugInfo_runahead_checkpoint_id;
    uopq_uop[7].debugInfo_tlbFirstReqTime = uopq_7_uop_debugInfo_tlbFirstReqTime;
    uopq_uop[7].debugInfo_tlbRespTime = uopq_7_uop_debugInfo_tlbRespTime;
    uopq_uop[7].debug_seqNum_seqNum = uopq_7_uop_debug_seqNum_seqNum;
    uopq_uop[7].debug_seqNum_uopIdx = uopq_7_uop_debug_seqNum_uopIdx;
    uopq_uop[7].lqIdx_flag = uopq_7_uop_lqIdx_flag;
    uopq_uop[7].lqIdx_value = uopq_7_uop_lqIdx_value;
    uopq_uop[7].sqIdx_flag = uopq_7_uop_sqIdx_flag;
    uopq_uop[7].sqIdx_value = uopq_7_uop_sqIdx_value;
  end

  // ---- data[i]：目的寄存器的数据（load 拼接 / store 的 vs3）；stride[i]：stride 或 index 向量 ----
  logic [127:0]  data_0;
  logic [127:0]  data_1;
  logic [127:0]  data_2;
  logic [127:0]  data_3;
  logic [127:0]  data_4;
  logic [127:0]  data_5;
  logic [127:0]  data_6;
  logic [127:0]  data_7;
  always_ff @(posedge clock) begin
    if (data_we[0]) data_0 <= data_wdata[0];
    if (data_we[1]) data_1 <= data_wdata[1];
    if (data_we[2]) data_2 <= data_wdata[2];
    if (data_we[3]) data_3 <= data_wdata[3];
    if (data_we[4]) data_4 <= data_wdata[4];
    if (data_we[5]) data_5 <= data_wdata[5];
    if (data_we[6]) data_6 <= data_wdata[6];
    if (data_we[7]) data_7 <= data_wdata[7];
  end
  assign data = {data_7, data_6, data_5, data_4, data_3, data_2, data_1, data_0};

  logic [127:0]  stride_0;
  logic [127:0]  stride_1;
  logic [127:0]  stride_2;
  logic [127:0]  stride_3;
  logic [127:0]  stride_4;
  logic [127:0]  stride_5;
  logic [127:0]  stride_6;
  logic [127:0]  stride_7;
  always_ff @(posedge clock) begin
    if (uopq_we[0]) stride_0 <= in.src_1;
    if (uopq_we[1]) stride_1 <= in.src_1;
    if (uopq_we[2]) stride_2 <= in.src_1;
    if (uopq_we[3]) stride_3 <= in.src_1;
    if (uopq_we[4]) stride_4 <= in.src_1;
    if (uopq_we[5]) stride_5 <= in.src_1;
    if (uopq_we[6]) stride_6 <= in.src_1;
    if (uopq_we[7]) stride_7 <= in.src_1;
  end
  assign stride = {stride_7, stride_6, stride_5, stride_4, stride_3, stride_2, stride_1, stride_0};

  xs_VSegmentUnit_core u_core (
    .clock                                        (clock),
    .reset                                        (reset),
    .in_valid                                     (io_in_valid),
    .in                                           (in),
    .uopwriteback_valid                           (io_uopwriteback_valid),
    .uopwriteback                                 (uopwriteback),
    .csrCtrl_cache_error_enable                   (io_csrCtrl_cache_error_enable),
    .rdcache_req_ready                            (io_rdcache_req_ready),
    .rdcache_req_valid                            (io_rdcache_req_valid),
    .rdcache_req                                  (rdcache_req),
    .rdcache_resp_valid                           (io_rdcache_resp_valid),
    .rdcache_resp                                 (rdcache_resp),
    .rdcache_is128Req                             (io_rdcache_is128Req),
    .rdcache_s1_paddr_dup_lsu                     (io_rdcache_s1_paddr_dup_lsu),
    .rdcache_s1_paddr_dup_dcache                  (io_rdcache_s1_paddr_dup_dcache),
    .rdcache_s2_bank_conflict                     (io_rdcache_s2_bank_conflict),
    .sbuffer_ready                                (io_sbuffer_ready),
    .sbuffer_valid                                (io_sbuffer_valid),
    .sbuffer                                      (sbuffer),
    .vecDifftestInfo                              (vecDifftestInfo),
    .dtlb_req_valid                               (io_dtlb_req_valid),
    .dtlb_req                                     (dtlb_req),
    .dtlb_resp_valid                              (io_dtlb_resp_valid),
    .dtlb_resp                                    (dtlb_resp),
    .pmpResp_ld                                   (io_pmpResp_ld),
    .pmpResp_st                                   (io_pmpResp_st),
    .pmpResp_instr                                (io_pmpResp_instr),
    .pmpResp_mmio                                 (io_pmpResp_mmio),
    .pmpResp_atomic                               (io_pmpResp_atomic),
    .flush_sbuffer_valid                          (io_flush_sbuffer_valid),
    .flush_sbuffer_empty                          (io_flush_sbuffer_empty),
    .feedback_valid                               (io_feedback_valid),
    .feedback                                     (feedback),
    .exceptionInfo_valid                          (io_exceptionInfo_valid),
    .exceptionInfo                                (exceptionInfo),
    .fromCsrTrigger_tdataVec_0_matchType          (io_fromCsrTrigger_tdataVec_0_matchType),
    .fromCsrTrigger_tdataVec_0_select             (io_fromCsrTrigger_tdataVec_0_select),
    .fromCsrTrigger_tdataVec_0_timing             (io_fromCsrTrigger_tdataVec_0_timing),
    .fromCsrTrigger_tdataVec_0_action             (io_fromCsrTrigger_tdataVec_0_action),
    .fromCsrTrigger_tdataVec_0_chain              (io_fromCsrTrigger_tdataVec_0_chain),
    .fromCsrTrigger_tdataVec_0_store              (io_fromCsrTrigger_tdataVec_0_store),
    .fromCsrTrigger_tdataVec_0_load               (io_fromCsrTrigger_tdataVec_0_load),
    .fromCsrTrigger_tdataVec_0_tdata2             (io_fromCsrTrigger_tdataVec_0_tdata2),
    .fromCsrTrigger_tdataVec_1_matchType          (io_fromCsrTrigger_tdataVec_1_matchType),
    .fromCsrTrigger_tdataVec_1_select             (io_fromCsrTrigger_tdataVec_1_select),
    .fromCsrTrigger_tdataVec_1_timing             (io_fromCsrTrigger_tdataVec_1_timing),
    .fromCsrTrigger_tdataVec_1_action             (io_fromCsrTrigger_tdataVec_1_action),
    .fromCsrTrigger_tdataVec_1_chain              (io_fromCsrTrigger_tdataVec_1_chain),
    .fromCsrTrigger_tdataVec_1_store              (io_fromCsrTrigger_tdataVec_1_store),
    .fromCsrTrigger_tdataVec_1_load               (io_fromCsrTrigger_tdataVec_1_load),
    .fromCsrTrigger_tdataVec_1_tdata2             (io_fromCsrTrigger_tdataVec_1_tdata2),
    .fromCsrTrigger_tdataVec_2_matchType          (io_fromCsrTrigger_tdataVec_2_matchType),
    .fromCsrTrigger_tdataVec_2_select             (io_fromCsrTrigger_tdataVec_2_select),
    .fromCsrTrigger_tdataVec_2_timing             (io_fromCsrTrigger_tdataVec_2_timing),
    .fromCsrTrigger_tdataVec_2_action             (io_fromCsrTrigger_tdataVec_2_action),
    .fromCsrTrigger_tdataVec_2_chain              (io_fromCsrTrigger_tdataVec_2_chain),
    .fromCsrTrigger_tdataVec_2_store              (io_fromCsrTrigger_tdataVec_2_store),
    .fromCsrTrigger_tdataVec_2_load               (io_fromCsrTrigger_tdataVec_2_load),
    .fromCsrTrigger_tdataVec_2_tdata2             (io_fromCsrTrigger_tdataVec_2_tdata2),
    .fromCsrTrigger_tdataVec_3_matchType          (io_fromCsrTrigger_tdataVec_3_matchType),
    .fromCsrTrigger_tdataVec_3_select             (io_fromCsrTrigger_tdataVec_3_select),
    .fromCsrTrigger_tdataVec_3_timing             (io_fromCsrTrigger_tdataVec_3_timing),
    .fromCsrTrigger_tdataVec_3_action             (io_fromCsrTrigger_tdataVec_3_action),
    .fromCsrTrigger_tdataVec_3_chain              (io_fromCsrTrigger_tdataVec_3_chain),
    .fromCsrTrigger_tdataVec_3_store              (io_fromCsrTrigger_tdataVec_3_store),
    .fromCsrTrigger_tdataVec_3_load               (io_fromCsrTrigger_tdataVec_3_load),
    .fromCsrTrigger_tdataVec_3_tdata2             (io_fromCsrTrigger_tdataVec_3_tdata2),
    .fromCsrTrigger_tEnableVec_0                  (io_fromCsrTrigger_tEnableVec_0),
    .fromCsrTrigger_tEnableVec_1                  (io_fromCsrTrigger_tEnableVec_1),
    .fromCsrTrigger_tEnableVec_2                  (io_fromCsrTrigger_tEnableVec_2),
    .fromCsrTrigger_tEnableVec_3                  (io_fromCsrTrigger_tEnableVec_3),
    .fromCsrTrigger_debugMode                     (io_fromCsrTrigger_debugMode),
    .fromCsrTrigger_triggerCanRaiseBpExp          (io_fromCsrTrigger_triggerCanRaiseBpExp),
    .uopq_we                                      (uopq_we),
    .uopq_uop                                     (uopq_uop),
    .data_we                                      (data_we),
    .data_wdata                                   (data_wdata),
    .data                                         (data),
    .stride                                       (stride),
    .instMicroOp_load                             (instMicroOp_load),
    .instMicroOp_uop_q                            (instMicroOp_uop_q),
    .fofBuffer_we                                 (fofBuffer_we),
    .fofBuffer_wdata                              (fofBuffer_wdata),
    .fofBuffer                                    (fofBuffer),
    .writebackValid                               (writebackValid),
    .writebackOut                                 (writebackOut),
    .uopwriteback_r                               (uopwriteback_r),
    .feedbackValid                                (feedbackValid),
    .feedbackOut                                  (feedbackOut),
    .feedback_r                                   (feedback_r)
  );

endmodule
// END GENERATED(wrapper)
