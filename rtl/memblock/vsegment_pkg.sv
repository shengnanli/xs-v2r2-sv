// =====================================================================
// vsegment_pkg.sv —— 向量 segment 访存单元（VSegmentUnit）的接口 struct（全部由 scripts/gen_vsegmentunit.py 生成）
// ---------------------------------------------------------------------
// 使用者：xs_VSegmentUnit_core 与 VSegmentUnit wrapper（VSegmentUnit.sv）。常量与小函数在 vlsu_pkg.sv。
// 成员 = golden VSegmentUnit 端口表与寄存器表的并集：seg_uop_t 是 DynInst 在本单元各接口 / 各寄存器组
//   留下的字段并集；golden 某个接口 / 寄存器组没有的成员由 wrapper 补 0 或不接。
// 单独成文件的原因：包被核与 wrapper 共用；按 scripts/check_pkg_scope.py 判据 B，包名与文件名相同的
//   独立文件是合法落点。
// =====================================================================

package vsegment_pkg;

  // BEGIN GENERATED(types) —— scripts/gen_vsegmentunit.py 生成，勿手改
  // 微操作信息（DynInst 在本单元各接口与寄存器里留下的字段并集）
  typedef struct packed {
    logic [34:0]   fuType;
    logic [8:0]    fuOpType;
    logic          vecWen;
    logic          v0Wen;
    logic          vlWen;
    logic          vpu_vill;
    logic          vpu_vma;
    logic          vpu_vta;
    logic [1:0]    vpu_vsew;
    logic [2:0]    vpu_vlmul;
    logic          vpu_specVill;
    logic          vpu_specVma;
    logic          vpu_specVta;
    logic [1:0]    vpu_specVsew;
    logic [2:0]    vpu_specVlmul;
    logic          vpu_vm;
    logic [7:0]    vpu_vstart;
    logic [2:0]    vpu_frm;
    logic          vpu_fpu_isFpToVecInst;
    logic          vpu_fpu_isFP32Instr;
    logic          vpu_fpu_isFP64Instr;
    logic          vpu_fpu_isReduction;
    logic          vpu_fpu_isFoldTo1_2;
    logic          vpu_fpu_isFoldTo1_4;
    logic          vpu_fpu_isFoldTo1_8;
    logic [1:0]    vpu_vxrm;
    logic [6:0]    vpu_vuopIdx;
    logic          vpu_lastUop;
    logic [2:0]    vpu_nf;
    logic [1:0]    vpu_veew;
    logic          vpu_isReverse;
    logic          vpu_isExt;
    logic          vpu_isNarrow;
    logic          vpu_isDstMask;
    logic          vpu_isOpMask;
    logic          vpu_isMove;
    logic          vpu_isDependOldVd;
    logic          vpu_isWritePartVd;
    logic          vpu_isVleff;
    logic [7:0]    pdest;
    logic          robIdx_flag;
    logic [7:0]    robIdx_value;
    logic          debugInfo_eliminatedMove;
    logic [63:0]   debugInfo_renameTime;
    logic [63:0]   debugInfo_dispatchTime;
    logic [63:0]   debugInfo_enqRsTime;
    logic [63:0]   debugInfo_selectTime;
    logic [63:0]   debugInfo_issueTime;
    logic [63:0]   debugInfo_writebackTime;
    logic [63:0]   debugInfo_runahead_checkpoint_id;
    logic [63:0]   debugInfo_tlbFirstReqTime;
    logic [63:0]   debugInfo_tlbRespTime;
    logic [55:0]   debug_seqNum_seqNum;
    logic [7:0]    debug_seqNum_uopIdx;
    logic          lqIdx_flag;
    logic [6:0]    lqIdx_value;
    logic          sqIdx_flag;
    logic [5:0]    sqIdx_value;
    logic [23:0]   exceptionVec;
    logic [3:0]    trigger;
    logic [127:0]  vpu_vmask;
    logic [7:0]    vpu_vl;
  } seg_uop_t;

  // 后端发来的 segment 访存 uop（src_0=基址 rs1，src_1=stride / index 向量，src_2=store 数据 vs3，src_3=v0 mask，src_4=vl）
  typedef struct packed {
    seg_uop_t      uop;
    logic [127:0]  src_0;
    logic [127:0]  src_1;
    logic [127:0]  src_2;
    logic [127:0]  src_3;
    logic [127:0]  src_4;
  } seg_in_t;

  // 写回后端（MemExuOutput，带 vdIdx）
  typedef struct packed {
    seg_uop_t      uop;
    logic [127:0]  data;
    logic [2:0]    vdIdx;
    logic [2:0]    vdIdxInField;
    logic          debug_isMMIO;
    logic          debug_isNCIO;
    logic          debug_isPerfCnt;
    logic [47:0]   debug_paddr;
    logic [49:0]   debug_vaddr;
  } seg_wb_t;

  // difftest 用的出队 uop 信息
  typedef struct packed {
    seg_uop_t      uop;
  } seg_difftest_t;

  // DCache 读请求
  typedef struct packed {
    logic [49:0]   vaddr;
    logic [49:0]   vaddr_dup;
  } seg_dcache_req_t;

  // DCache 读应答（数据与错误晚一拍到）
  typedef struct packed {
    logic [127:0]  data_delayed;
    logic          miss;
    logic          tl_error_delayed_tl_denied;
    logic          tl_error_delayed_tl_corrupt;
  } seg_dcache_resp_t;

  // 写 sbuffer 的一笔（DCacheWordReqWithVaddrAndPfFlag）
  typedef struct packed {
    logic [49:0]   vaddr;
    logic [127:0]  data;
    logic [15:0]   mask;
    logic [47:0]   addr;
    logic          vecValid;
  } seg_sbuf_t;

  // DTLB 请求
  typedef struct packed {
    logic [49:0]   vaddr;
    logic [63:0]   fullva;
    logic [2:0]    cmd;
    logic          debug_robIdx_flag;
    logic [7:0]    debug_robIdx_value;
  } seg_tlb_req_t;

  // DTLB 应答
  typedef struct packed {
    logic [47:0]   paddr_0;
    logic [63:0]   gpaddr_0;
    logic [63:0]   fullva;
    logic [1:0]    pbmt_0;
    logic          miss;
    logic          isForVSnonLeafPTE;
    logic          excp_0_gpf_ld;
    logic          excp_0_gpf_st;
    logic          excp_0_pf_ld;
    logic          excp_0_pf_st;
    logic          excp_0_af_ld;
    logic          excp_0_af_st;
  } seg_tlb_resp_t;

  // 给发射队列的反馈
  typedef struct packed {
    logic          robIdx_flag;
    logic [7:0]    robIdx_value;
    logic          sqIdx_flag;
    logic [5:0]    sqIdx_value;
    logic          lqIdx_flag;
    logic [6:0]    lqIdx_value;
  } seg_feedback_t;

  // 异常地址信息
  typedef struct packed {
    logic [63:0]   vaddr;
    logic [63:0]   gpaddr;
    logic          isForVSnonLeafPTE;
  } seg_excinfo_t;
  // END GENERATED(types)

endpackage
