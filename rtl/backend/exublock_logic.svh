// 自动生成:scripts/gen_exublock.py（ExuBlock）—— 勿手改(逻辑为从设计意图的可读重写)

// 容器层真正的时序逻辑(可读重写,无 golden _GEN_/_T_/_REG_ 名)。
// 状态变量在 decls.svh 声明;ExeUnit 输出网由 connect.svh 例化驱动。

  // ==========================================================================
  // §1 frm(浮点动态舍入模式)打拍。
  //   Chisel: exu.io.frm := RegNext(io.frm)。每个 needSrcFrm 的 vf-exu 各打一拍,
  //   消除 CSR→exu 的 frm 长组合路径。本核用数组 + genvar 表达 1 路同构打拍,
  //   connect.svh 再把 frm_q[k] 接到第 k 个吃 frm 的 exu。
  // ==========================================================================
  for (genvar k = 0; k < NUM_FRM_PIPE; k++) begin : g_frm_pipe
    always_ff @(posedge clock) frm_pipe[k] <= frm_step(io_frm);
    assign frm_q[k] = frm_pipe[k].rm;
  end

  // ==========================================================================
  // §2 critical-error 聚合流水。
  //   Chisel: HasCriticalErrors.generateCriticalErrors() 把含 CSR 的 exu 报出的
  //   critical error 经 ERR_PIPE_DEPTH 拍寄存(消除跨模块长路径)后,作为 io_error_0
  //   送顶层。本核用移位寄存器 struct(err_pipe_t)逐拍推进,而非散落的 *_REG/_REG_1。
  // ==========================================================================
  always_ff @(posedge clock)
    err_pipe <= err_pipe_step(err_pipe, _exus_7_io_error_0);
  assign io_error_0 = err_pipe_out(err_pipe);
