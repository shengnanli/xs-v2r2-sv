// 自动生成:scripts/gen_exeunit.py（ExeUnit_8）—— 勿手改(逻辑为从设计意图的可读重写)

// 执行单元 glue 的真正逻辑(可读重写,无 golden _GEN_/_T_/_REG_ 名)。

  // ==========================================================================
  // §1 inPipe:控制位 + 有效位各打 LAT_MAX 拍,供有延迟 FU 在出结果拍取用。
  //   控制位链每拍纯移位;有效位链每拍移位并做 flush-kill(被冲刷则清 0)。
  // ==========================================================================
  // 进入流水的当拍控制位(取自 io_in)。fuOpType/rfWen 走各自专用浅链(见下)。
  ctrl_t ctrl_in;
  assign ctrl_in = '{robIdx_flag: io_in_bits_robIdx_flag, robIdx_value: io_in_bits_robIdx_value, pdest: io_in_bits_pdest, fpWen: io_in_bits_fpWen, fpu_wflags: io_in_bits_fpu_wflags};

  // fuOpType / rfWen 专用 2 级浅链:纯移位打拍(无 flush-kill,随控制位链同步)。
  //   op_pipe[0]/rf_pipe[0] = 入流水后第 1 拍,op_pipe[1]/rf_pipe[1] = 第 2 拍。
  always_ff @(posedge clock) begin
    op_pipe[0] <= io_in_bits_fuOpType;
    op_pipe[1] <= op_pipe[0];
    rf_pipe[0] <= io_in_bits_rfWen;
    rf_pipe[1] <= rf_pipe[0];
  end

  // 一级有效推进:上级有效 v、本级 robIdx,以及 flush 信号(全部显式入参,
  //   纯函数不捕获外部信号,避免 FM 的 sim/synth 不一致告警)。被冲刷则清 0。
  function automatic logic stage_alive(
      logic v, logic rflag, logic [7:0] rval,
      logic fl_valid, logic fl_level, logic fl_flag, logic [7:0] fl_value);
    stage_alive = v & ~need_flush(fl_valid, fl_level, fl_flag, fl_value, rflag, rval);
  endfunction

  for (genvar k = 0; k < LAT_MAX; k++) begin : g_inpipe
    always_ff @(posedge clock) begin
      if (k == 0) ctrl_pipe[0] <= ctrl_in;
      else        ctrl_pipe[k] <= ctrl_pipe[k-1];
    end
  end

  // 有效位链:复位清 0;每拍由上一级(或 io_in)推进并 flush-kill。
  //   注意上一级的 robIdx 来自上一级的控制位链(ctrl_pipe),与 golden 一致。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int k = 0; k < LAT_MAX; k++) valid_pipe[k] <= 1'b0;
    end else begin
      valid_pipe[0] <= stage_alive(io_in_valid,
                         io_in_bits_robIdx_flag, io_in_bits_robIdx_value,
                         io_flush_valid, io_flush_bits_level,
                         io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value);
      for (int k = 1; k < LAT_MAX; k++)
        valid_pipe[k] <= stage_alive(valid_pipe[k-1],
                           ctrl_pipe[k-1].robIdx_flag, ctrl_pipe[k-1].robIdx_value,
                           io_flush_valid, io_flush_bits_level,
                           io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value);
    end
  end

  // ==========================================================================
  // §2 时钟门控使能:每个有延迟 FU 维护一条有效移位链 fuvld。
  //   链上任一级有效 ⇒ 该 FU 流水里还有在飞 uop ⇒ 时钟需保持;clk_en 再打一拍
  //   合并(fuvld_q),喂给该 FU 的 ClockGate.E(见 connect.svh)。
  //   链入口 fuvld[0] = 该 FU 被分发选中(_in1ToN 该路 valid),由 connect 驱动。
  // ==========================================================================
  // FU Falu(latency=1)有效链推进。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fuvld_Falu[1:1] <= '0;
      fuvld_q_Falu        <= 1'b0;
    end else begin
      for (int s = 1; s <= 1; s++) fuvld_Falu[s] <= fuvld_Falu[s-1];
      fuvld_q_Falu <= |fuvld_Falu;
    end
  end
  // clk_en = 链上任一级有效 | 上一拍使能(见 connect 接到 ClockGate.E)。
  wire clk_en_Falu = (|fuvld_Falu) | fuvld_q_Falu;

  // FU Fcvt(latency=2)有效链推进。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fuvld_Fcvt[2:1] <= '0;
      fuvld_q_Fcvt        <= 1'b0;
    end else begin
      for (int s = 1; s <= 2; s++) fuvld_Fcvt[s] <= fuvld_Fcvt[s-1];
      fuvld_q_Fcvt <= |fuvld_Fcvt;
    end
  end
  // clk_en = 链上任一级有效 | 上一拍使能(见 connect 接到 ClockGate.E)。
  wire clk_en_Fcvt = (|fuvld_Fcvt) | fuvld_q_Fcvt;

  // FU Fmac(latency=3)有效链推进。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fuvld_Fmac[3:1] <= '0;
      fuvld_q_Fmac        <= 1'b0;
    end else begin
      for (int s = 1; s <= 3; s++) fuvld_Fmac[s] <= fuvld_Fmac[s-1];
      fuvld_q_Fmac <= |fuvld_Fmac;
    end
  end
  // clk_en = 链上任一级有效 | 上一拍使能(见 connect 接到 ClockGate.E)。
  wire clk_en_Fmac = (|fuvld_Fmac) | fuvld_q_Fmac;
