// xs_vsmergebuffer_pkg —— VSMergeBufferImp(向量 store 16 条目 merge buffer)可读核公共定义
// 手写重写, bug-for-bug 对齐 golden VSMergeBufferImp.sv。
// 子模块 FreeList_1 / NewPipelineConnectPipe_27 两侧 elaborate(不在本 pkg)。
`ifndef XS_VSMERGEBUFFER_PKG_SV
`define XS_VSMERGEBUFFER_PKG_SV
package xs_vsmergebuffer_pkg;

  localparam int VS_SIZE = 16;

  // 每条目 43 个字段(与 golden entries_N_* 一一对应)。
  typedef struct packed {
    logic [15:0]  mask;
    logic [4:0]   flowNum;
    logic         exceptionVec_3;
    logic         exceptionVec_6;
    logic         exceptionVec_7;
    logic         exceptionVec_15;
    logic         exceptionVec_19;
    logic         exceptionVec_23;
    logic [3:0]   uop_trigger;
    logic [8:0]   uop_fuOpType;
    logic         uop_vecWen;
    logic         uop_v0Wen;
    logic         uop_vlWen;
    logic         uop_flushPipe;
    logic         uop_vpu_vma;
    logic         uop_vpu_vta;
    logic [1:0]   uop_vpu_vsew;
    logic [2:0]   uop_vpu_vlmul;
    logic         uop_vpu_vm;
    logic [6:0]   uop_vpu_vuopIdx;
    logic [127:0] uop_vpu_vmask;
    logic [7:0]   uop_vpu_vl;
    logic [2:0]   uop_vpu_nf;
    logic [1:0]   uop_vpu_veew;
    logic [6:0]   uop_uopIdx;
    logic [7:0]   uop_pdest;
    logic         uop_robIdx_flag;
    logic [7:0]   uop_robIdx_value;
    logic [63:0]  uop_debugInfo_enqRsTime;
    logic [63:0]  uop_debugInfo_selectTime;
    logic [63:0]  uop_debugInfo_issueTime;
    logic         uop_lqIdx_flag;
    logic [6:0]   uop_lqIdx_value;
    logic         uop_sqIdx_flag;
    logic [5:0]   uop_sqIdx_value;
    logic         uop_replayInst;
    logic [7:0]   elemIdx;
    logic [7:0]   vstart;
    logic         vaNeedExt;
    logic [63:0]  vaddr;
    logic [49:0]  gpaddr;
    logic         isForVSnonLeafPTE;
    logic [7:0]   vlmax;
  } vsmb_entry_t;

endpackage
`endif
