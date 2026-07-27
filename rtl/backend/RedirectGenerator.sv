// =============================================================================
// xs_RedirectGenerator —— 后端重定向仲裁与生成(CtrlBlock 内)。
//
// 对应 golden RedirectGenerator。功能:
//   1) 在 oldestExuRedirect / loadReplay 两路重定向请求间选最老(oldest)一路;
//   2) 用 flushAfter 状态 + 3 位倒计时器抑制被更早 flush 覆盖的请求;
//   3) 把选中请求打一拍成 s1_redirect(stage2Redirect 输出);
//   4) 对 store-set 内存依赖预测(memPredUpdate)生成 waddr/ldpc/stpc 折叠哈希。
//
// 忠实复刻 golden 逐位语义(含 XiangShan 的 Verilog 运算符优先级怪癖:
//   `a ^ b ^ c > d` 解析为 `a ^ b ^ (c > d)`)。0 个 _GEN_/_T_ 噪声。
//
// 逻辑核命名 xs_RedirectGenerator_core; golden 同名薄 wrapper 在
// RedirectGenerator_wrapper.sv(FM impl), UT 用 RedirectGenerator_xs(见 variants)。
// =============================================================================
module xs_RedirectGenerator_core(
  input         clock,
  input         reset,
  input         io_oldestExuRedirect_valid,
  input         io_oldestExuRedirect_bits_robIdx_flag,
  input  [7:0]  io_oldestExuRedirect_bits_robIdx_value,
  input         io_oldestExuRedirect_bits_ftqIdx_flag,
  input  [5:0]  io_oldestExuRedirect_bits_ftqIdx_value,
  input  [3:0]  io_oldestExuRedirect_bits_ftqOffset,
  input         io_oldestExuRedirect_bits_level,
  input  [49:0] io_oldestExuRedirect_bits_cfiUpdate_pc,
  input  [49:0] io_oldestExuRedirect_bits_cfiUpdate_target,
  input         io_oldestExuRedirect_bits_cfiUpdate_taken,
  input         io_oldestExuRedirect_bits_cfiUpdate_isMisPred,
  input         io_oldestExuRedirect_bits_cfiUpdate_backendIGPF,
  input         io_oldestExuRedirect_bits_cfiUpdate_backendIPF,
  input         io_oldestExuRedirect_bits_cfiUpdate_backendIAF,
  input  [63:0] io_oldestExuRedirect_bits_fullTarget,
  input         io_oldestExuRedirect_bits_debugIsCtrl,
  input         io_oldestExuRedirectIsCSR,
  input         io_instrAddrTransType_bare,
  input         io_instrAddrTransType_sv39,
  input         io_instrAddrTransType_sv39x4,
  input         io_instrAddrTransType_sv48,
  input         io_instrAddrTransType_sv48x4,
  input         io_loadReplay_valid,
  input         io_loadReplay_bits_robIdx_flag,
  input  [7:0]  io_loadReplay_bits_robIdx_value,
  input         io_loadReplay_bits_ftqIdx_flag,
  input  [5:0]  io_loadReplay_bits_ftqIdx_value,
  input  [3:0]  io_loadReplay_bits_ftqOffset,
  input         io_loadReplay_bits_level,
  input  [49:0] io_loadReplay_bits_cfiUpdate_pc,
  input  [49:0] io_loadReplay_bits_cfiUpdate_target,
  input         io_robFlush_valid,
  input         io_robFlush_bits_robIdx_flag,
  input  [7:0]  io_robFlush_bits_robIdx_value,
  input         io_robFlush_bits_level,
  output        io_stage2Redirect_valid,
  output        io_stage2Redirect_bits_robIdx_flag,
  output [7:0]  io_stage2Redirect_bits_robIdx_value,
  output        io_stage2Redirect_bits_ftqIdx_flag,
  output [5:0]  io_stage2Redirect_bits_ftqIdx_value,
  output [3:0]  io_stage2Redirect_bits_ftqOffset,
  output        io_stage2Redirect_bits_level,
  output [49:0] io_stage2Redirect_bits_cfiUpdate_pc,
  output [49:0] io_stage2Redirect_bits_cfiUpdate_target,
  output        io_stage2Redirect_bits_cfiUpdate_taken,
  output        io_stage2Redirect_bits_cfiUpdate_isMisPred,
  output        io_stage2Redirect_bits_cfiUpdate_backendIGPF,
  output        io_stage2Redirect_bits_cfiUpdate_backendIPF,
  output        io_stage2Redirect_bits_cfiUpdate_backendIAF,
  output [63:0] io_stage2Redirect_bits_fullTarget,
  output        io_stage2Redirect_bits_debugIsCtrl,
  output        io_stage2Redirect_bits_debugIsMemVio,
  output        io_memPredUpdate_valid,
  output [9:0]  io_memPredUpdate_waddr,
  output [9:0]  io_memPredUpdate_ldpc,
  output [9:0]  io_memPredUpdate_stpc,
  input  [49:0] io_memPredPcRead_data,
  output [1:0]  io_stage2oldestOH
);

  // --- oldest 选择: exu vs loadReplay ---------------------------------------
  // exuOlder = exu 比 loadReplay 更老(robIdx 比较: flag^flag^(value>value))。
  // 注意 XiangShan Verilog 优先级怪癖: `f^f^v>v` == `f ^ f ^ (v > v)`。
  wire exuOlderThanLoad =
      io_oldestExuRedirect_bits_robIdx_flag ^ io_loadReplay_bits_robIdx_flag
      ^ (io_oldestExuRedirect_bits_robIdx_value > io_loadReplay_bits_robIdx_value);

  // onehot 选中位: [1]=选 exu, [0]=选 loadReplay(与 golden resultOnehot 对齐)。
  wire selExu  = io_oldestExuRedirect_valid
               & (~io_loadReplay_valid | ~exuOlderThanLoad);
  wire selLoad = (~io_oldestExuRedirect_valid | exuOlderThanLoad)
               & io_loadReplay_valid;

  // --- flushAfter 状态寄存器(被更早 flush 覆盖时抑制) -----------------------
  reg        flushAfter_valid;
  reg        flushAfter_bits_robIdx_flag;
  reg  [7:0] flushAfter_bits_robIdx_value;
  reg        flushAfter_bits_level;

  wire [8:0] flushAfter_robIdx = {flushAfter_bits_robIdx_flag, flushAfter_bits_robIdx_value};

  // 某路请求是否被 flushAfter 覆盖(同 robIdx 且 flushAfter 是 level, 或 flushAfter 更老)。
  // 用显式组合表达式(不用 function 捕获模块信号, 避免 FMR_VLOG-091)。
  wire loadCoveredByFlushAfter =
      flushAfter_valid
      & (flushAfter_bits_level
         & ({io_loadReplay_bits_robIdx_flag, io_loadReplay_bits_robIdx_value}
            == flushAfter_robIdx)
         | (io_loadReplay_bits_robIdx_flag ^ flushAfter_bits_robIdx_flag
            ^ (io_loadReplay_bits_robIdx_value > flushAfter_bits_robIdx_value)))
      | io_robFlush_valid;
  wire exuCoveredByFlushAfter =
      flushAfter_valid
      & (flushAfter_bits_level
         & ({io_oldestExuRedirect_bits_robIdx_flag, io_oldestExuRedirect_bits_robIdx_value}
            == flushAfter_robIdx)
         | (io_oldestExuRedirect_bits_robIdx_flag ^ flushAfter_bits_robIdx_flag
            ^ (io_oldestExuRedirect_bits_robIdx_value > flushAfter_bits_robIdx_value)))
      | io_robFlush_valid;

  // oldestValid: 两路各自有效且未被 flushAfter 覆盖。
  wire loadOldestValid = selLoad & ~loadCoveredByFlushAfter;
  wire exuOldestValid  = selExu  & ~exuCoveredByFlushAfter;
  wire oldestValidAny  = loadOldestValid | exuOldestValid;

  // 选中请求的 robIdx/level(one-hot OR 归约)。
  wire       oldestRedirect_level =
      selExu & io_oldestExuRedirect_bits_level | selLoad & io_loadReplay_bits_level;
  wire [7:0] oldestRedirect_robIdx_value =
      (selExu ? io_oldestExuRedirect_bits_robIdx_value : 8'h0)
      | (selLoad ? io_loadReplay_bits_robIdx_value : 8'h0);
  wire       oldestRedirect_robIdx_flag =
      selExu & io_oldestExuRedirect_bits_robIdx_flag
      | selLoad & io_loadReplay_bits_robIdx_flag;

  wire robFlushOrExuFlushValid = oldestValidAny | io_robFlush_valid;

  // --- s1 redirect payload 寄存器(选中请求打一拍) --------------------------
  reg        s1_robIdx_flag;
  reg  [7:0] s1_robIdx_value;
  reg        s1_ftqIdx_flag;
  reg  [5:0] s1_ftqIdx_value;
  reg  [3:0] s1_ftqOffset;
  reg        s1_level;
  reg  [49:0] s1_cfiUpdate_pc;
  reg  [49:0] s1_cfiUpdate_target;
  reg        s1_cfiUpdate_taken;
  reg        s1_cfiUpdate_isMisPred;
  reg        s1_cfiUpdate_backendIGPF;
  reg        s1_cfiUpdate_backendIPF;
  reg        s1_cfiUpdate_backendIAF;
  reg  [63:0] s1_fullTarget;
  reg        s1_debugIsCtrl;
  reg        s1_debugIsMemVio;
  reg        s1_valid_last;      // s1_redirect_valid_reg_last_REG
  reg        s1_onehot_exu_last; // s1_redirect_onehot_last_REG   (选 exu)
  reg        s1_onehot_load_last;// s1_redirect_onehot_last_REG_1 (选 load)
  reg  [2:0] flushAfterCounter;

  // memPred 更新流水寄存器。
  wire       memPredStpcEn = s1_onehot_load_last & s1_valid_last;
  reg        io_memPredUpdate_valid_last;
  reg  [9:0] memPred_waddr_r;
  reg  [9:0] memPred_ldpc_r;
  reg  [9:0] memPred_stpc_r;

  // backendIPF 用到的 target 高位拼接(sv48 检查)。
  wire [15:0] targetHi_sv48 =
      {io_oldestExuRedirect_bits_fullTarget[63:50],
       io_oldestExuRedirect_bits_cfiUpdate_target[49:48]};

  // --- 时序: 异步复位段 -----------------------------------------------------
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      flushAfter_valid            <= 1'h0;
      flushAfter_bits_robIdx_flag <= 1'h0;
      flushAfter_bits_robIdx_value<= 8'h0;
      flushAfter_bits_level       <= 1'h0;
      s1_valid_last               <= 1'h0;
      s1_onehot_exu_last          <= 1'h0;
      s1_onehot_load_last         <= 1'h0;
      io_memPredUpdate_valid_last <= 1'h0;
    end
    else begin
      flushAfter_valid <=
          robFlushOrExuFlushValid | (flushAfterCounter[0] & flushAfter_valid);
      if (robFlushOrExuFlushValid) begin
        flushAfter_bits_robIdx_flag <=
            io_robFlush_valid ? io_robFlush_bits_robIdx_flag : oldestRedirect_robIdx_flag;
        flushAfter_bits_robIdx_value <=
            io_robFlush_valid ? io_robFlush_bits_robIdx_value : oldestRedirect_robIdx_value;
        flushAfter_bits_level <=
            io_robFlush_valid ? io_robFlush_bits_level : oldestRedirect_level;
      end
      s1_valid_last       <= oldestValidAny;
      s1_onehot_exu_last  <= selExu;
      s1_onehot_load_last <= selLoad;
      io_memPredUpdate_valid_last <= memPredStpcEn & s1_level;
    end
  end

  // --- 时序: 同步段(s1 payload + counter + memPred hash) --------------------
  always @(posedge clock) begin
    if (oldestValidAny) begin
      s1_robIdx_flag  <= oldestRedirect_robIdx_flag;
      s1_robIdx_value <= oldestRedirect_robIdx_value;
      s1_ftqIdx_flag  <=
          selExu & io_oldestExuRedirect_bits_ftqIdx_flag
          | selLoad & io_loadReplay_bits_ftqIdx_flag;
      s1_ftqIdx_value <=
          (selExu ? io_oldestExuRedirect_bits_ftqIdx_value : 6'h0)
          | (selLoad ? io_loadReplay_bits_ftqIdx_value : 6'h0);
      s1_ftqOffset <=
          (selExu ? io_oldestExuRedirect_bits_ftqOffset : 4'h0)
          | (selLoad ? io_loadReplay_bits_ftqOffset : 4'h0);
      s1_level <= oldestRedirect_level;
      s1_cfiUpdate_pc <=
          (selExu ? io_oldestExuRedirect_bits_cfiUpdate_pc : 50'h0)
          | (selLoad ? io_loadReplay_bits_cfiUpdate_pc : 50'h0);
      s1_cfiUpdate_target <=
          (selExu ? io_oldestExuRedirect_bits_cfiUpdate_target : 50'h0)
          | (selLoad ? io_loadReplay_bits_cfiUpdate_target : 50'h0);
      s1_cfiUpdate_taken    <= selExu & io_oldestExuRedirect_bits_cfiUpdate_taken;
      s1_cfiUpdate_isMisPred<= selExu & io_oldestExuRedirect_bits_cfiUpdate_isMisPred;
      s1_cfiUpdate_backendIGPF <=
          selExu
          & (io_oldestExuRedirectIsCSR
               ? io_oldestExuRedirect_bits_cfiUpdate_backendIGPF
               : io_instrAddrTransType_sv39x4
                 & (|{io_oldestExuRedirect_bits_fullTarget[63:50],
                      io_oldestExuRedirect_bits_cfiUpdate_target[49:41]})
                 | io_instrAddrTransType_sv48x4
                 & (|(io_oldestExuRedirect_bits_fullTarget[63:50])));
      s1_cfiUpdate_backendIPF <=
          selExu
          & (io_oldestExuRedirectIsCSR
               ? io_oldestExuRedirect_bits_cfiUpdate_backendIPF
               : io_instrAddrTransType_sv39
                 & ({io_oldestExuRedirect_bits_fullTarget[63:50],
                     io_oldestExuRedirect_bits_cfiUpdate_target[49:39]}
                    != {25{io_oldestExuRedirect_bits_cfiUpdate_target[38]}})
                 | io_instrAddrTransType_sv48
                 & (targetHi_sv48
                    != {16{io_oldestExuRedirect_bits_cfiUpdate_target[47]}}));
      s1_cfiUpdate_backendIAF <=
          selExu
          & (io_oldestExuRedirectIsCSR
               ? io_oldestExuRedirect_bits_cfiUpdate_backendIAF
               : io_instrAddrTransType_bare & (|targetHi_sv48));
      s1_fullTarget <=
          selExu
            ? {io_oldestExuRedirect_bits_fullTarget[63:50],
               io_oldestExuRedirect_bits_cfiUpdate_target}
            : 64'h0;
      s1_debugIsCtrl   <= selExu & io_oldestExuRedirect_bits_debugIsCtrl;
      s1_debugIsMemVio <= selLoad;
    end
    if (robFlushOrExuFlushValid)
      flushAfterCounter <= 3'h7;
    else if (flushAfterCounter[0])
      flushAfterCounter <= {1'h0, flushAfterCounter[2:1]};
    if (memPredStpcEn) begin
      memPred_waddr_r <=
          s1_cfiUpdate_pc[10:1] ^ s1_cfiUpdate_pc[20:11] ^ s1_cfiUpdate_pc[30:21]
          ^ s1_cfiUpdate_pc[40:31] ^ {1'h0, s1_cfiUpdate_pc[49:41]};
      memPred_ldpc_r <=
          s1_cfiUpdate_pc[10:1] ^ s1_cfiUpdate_pc[20:11] ^ s1_cfiUpdate_pc[30:21]
          ^ s1_cfiUpdate_pc[40:31] ^ {1'h0, s1_cfiUpdate_pc[49:41]};
      memPred_stpc_r <=
          io_memPredPcRead_data[10:1] ^ io_memPredPcRead_data[20:11]
          ^ io_memPredPcRead_data[30:21] ^ io_memPredPcRead_data[40:31]
          ^ {1'h0, io_memPredPcRead_data[49:41]};
    end
  end

  // --- 输出 -----------------------------------------------------------------
  assign io_stage2Redirect_valid                     = s1_valid_last & ~io_robFlush_valid;
  assign io_stage2Redirect_bits_robIdx_flag          = s1_robIdx_flag;
  assign io_stage2Redirect_bits_robIdx_value         = s1_robIdx_value;
  assign io_stage2Redirect_bits_ftqIdx_flag          = s1_ftqIdx_flag;
  assign io_stage2Redirect_bits_ftqIdx_value         = s1_ftqIdx_value;
  assign io_stage2Redirect_bits_ftqOffset            = s1_ftqOffset;
  assign io_stage2Redirect_bits_level                = s1_level;
  assign io_stage2Redirect_bits_cfiUpdate_pc         = s1_cfiUpdate_pc;
  assign io_stage2Redirect_bits_cfiUpdate_target     = s1_cfiUpdate_target;
  assign io_stage2Redirect_bits_cfiUpdate_taken      = s1_cfiUpdate_taken;
  assign io_stage2Redirect_bits_cfiUpdate_isMisPred  = s1_cfiUpdate_isMisPred;
  assign io_stage2Redirect_bits_cfiUpdate_backendIGPF= s1_cfiUpdate_backendIGPF;
  assign io_stage2Redirect_bits_cfiUpdate_backendIPF = s1_cfiUpdate_backendIPF;
  assign io_stage2Redirect_bits_cfiUpdate_backendIAF = s1_cfiUpdate_backendIAF;
  assign io_stage2Redirect_bits_fullTarget           = s1_fullTarget;
  assign io_stage2Redirect_bits_debugIsCtrl          = s1_debugIsCtrl;
  assign io_stage2Redirect_bits_debugIsMemVio        = s1_debugIsMemVio;
  assign io_memPredUpdate_valid                      = io_memPredUpdate_valid_last;
  assign io_memPredUpdate_waddr                      = memPred_waddr_r;
  assign io_memPredUpdate_ldpc                       = memPred_ldpc_r;
  assign io_memPredUpdate_stpc                       = memPred_stpc_r;
  assign io_stage2oldestOH                           = {s1_onehot_load_last, s1_onehot_exu_last};

endmodule
