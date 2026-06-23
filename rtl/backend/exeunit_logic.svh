// 自动生成:scripts/gen_exeunit.py（ExeUnit）—— 勿手改(逻辑为从设计意图的可读重写)

// 执行单元 glue 的真正逻辑(可读重写,无 golden _GEN_/_T_/_REG_ 名)。

  // ==========================================================================
  // §1 inPipe:控制位 + 有效位各打 LAT_MAX 拍,供有延迟 FU 在出结果拍取用。
  //   控制位链每拍纯移位;有效位链每拍移位并做 flush-kill(被冲刷则清 0)。
  // ==========================================================================
  // 进入流水的当拍控制位(取自 io_in)。
  ctrl_t ctrl_in;
  assign ctrl_in = '{robIdx_flag: io_in_bits_robIdx_flag, robIdx_value: io_in_bits_robIdx_value, pdest: io_in_bits_pdest, rfWen: io_in_bits_rfWen};

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
  // FU Mul(latency=2)有效链推进。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fuvld_Mul[2:1] <= '0;
      fuvld_q_Mul        <= 1'b0;
    end else begin
      for (int s = 1; s <= 2; s++) fuvld_Mul[s] <= fuvld_Mul[s-1];
      fuvld_q_Mul <= |fuvld_Mul;
    end
  end
  // clk_en = 链上任一级有效 | 上一拍使能(见 connect 接到 ClockGate.E)。
  wire clk_en_Mul = (|fuvld_Mul) | fuvld_q_Mul;

  // FU Bku(latency=2)有效链推进。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fuvld_Bku[2:1] <= '0;
      fuvld_q_Bku        <= 1'b0;
    end else begin
      for (int s = 1; s <= 2; s++) fuvld_Bku[s] <= fuvld_Bku[s-1];
      fuvld_q_Bku <= |fuvld_Bku;
    end
  end
  // clk_en = 链上任一级有效 | 上一拍使能(见 connect 接到 ClockGate.E)。
  wire clk_en_Bku = (|fuvld_Bku) | fuvld_q_Bku;
