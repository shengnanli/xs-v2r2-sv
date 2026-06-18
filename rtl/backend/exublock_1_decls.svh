// 自动生成:scripts/gen_exublock.py（ExuBlock_1）—— 勿手改(逻辑为从设计意图的可读重写)

// 核内信号声明(先于 logic/connect include):ExeUnit 输出网 + 流水寄存器状态。

  // ---- ExeUnit 子模块输出网(in_ready / csrio.instrAddrTransType / error 等)----
  wire _exus_1_io_in_ready;
  wire _exus_3_io_in_ready;

  // ---- §1 frm 打拍状态 / §2 error 打拍状态 ----
  frm_pipe_t  frm_pipe [NUM_FRM_PIPE];
  logic [2:0] frm_q    [NUM_FRM_PIPE];  // 供 connect.svh 接到各 vf-exu 的 io_frm
