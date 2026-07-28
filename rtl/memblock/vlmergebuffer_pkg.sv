// xs_vlmergebuffer_pkg —— VLMergeBufferImp(向量 load 16 条目 merge buffer)可读核公共定义
// 手写重写, bug-for-bug 对齐 golden VLMergeBufferImp.sv。
// 子模块 FreeList / NewPipelineConnectPipe_27×2 两侧 elaborate(不在本 pkg)。
`ifndef XS_VLMERGEBUFFER_PKG_SV
`define XS_VLMERGEBUFFER_PKG_SV
package xs_vlmergebuffer_pkg;

  localparam int VL_SIZE = 16;

  // 每条目 40 个字段(与 golden entries_N_* 一一对应, 顺序同 golden reg 声明)。
  typedef struct packed {
    logic [127:0] data;
    logic [15:0]  mask;
    logic [4:0]   flowNum;
    logic         exceptionVec_3;
    logic         exceptionVec_4;
    logic         exceptionVec_5;
    logic         exceptionVec_13;
    logic         exceptionVec_19;
    logic         exceptionVec_21;
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
    logic [2:0]   uop_vpu_nf;
    logic [1:0]   uop_vpu_veew;
    logic [6:0]   uop_uopIdx;
    logic [7:0]   uop_pdest;
    logic         uop_robIdx_flag;
    logic [7:0]   uop_robIdx_value;
    logic [63:0]  uop_debugInfo_enqRsTime;
    logic [63:0]  uop_debugInfo_selectTime;
    logic [63:0]  uop_debugInfo_issueTime;
    logic         uop_replayInst;
    logic [2:0]   vdIdx;
    logic [7:0]   elemIdx;
    logic [7:0]   vstart;
    logic [7:0]   vl;
    logic         vaNeedExt;
    logic [63:0]  vaddr;
    logic [49:0]  gpaddr;
    logic         fof;
    logic [7:0]   vlmax;
  } vlmb_entry_t;

endpackage
`endif
