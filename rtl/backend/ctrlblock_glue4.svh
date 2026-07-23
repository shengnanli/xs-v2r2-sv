// 手写(从 CtrlBlock.scala 设计意图重写,非 golden 转写)。round6 补:decode/fusion 入口 valid。
// ============================================================================
// 本文件产出两组「子模块输入 valid」具名信号,供 ctrlblock_inst.svh 的
// DecodeStage / FusionDecoder 例化引脚连接(io_in_k_valid)。因为它们引用的
// 决策网(decodeBufValid / _decode_io_out_k_bits_exceptionVec_* / _trigger)分别
// 由 logic.svh(decodeBufValid)与 inst.svh(decode 黑盒输出网)产出,故本文件
// **在 CtrlBlock.sv 中于 ctrlblock_inst.svh 之后 include**(此时两侧信号都已声明)。
// X 铁律:三元 mux / 纯布尔。
// ----------------------------------------------------------------------------

  // ==========================================================================
  // (0) 把 DecodeStage 6 个标量 io_in_k_ready 输出引脚聚成向量 _decode_io_in_ready[5:0]。
  //     ★ 关键修复(round7):decodeBuf FSM(logic.svh 块 2)用 _decode_io_in_ready[gi]
  //       计算 notAccept,但该向量原先只声明(decls.svh)从未被赋值,而 decode 例化
  //       (inst.svh)把 ready 连到的是标量 _decode_io_in_k_ready。两者不通 → FSM 读到
  //       的恒为 0,使 decodeBufNotAccept/AcceptNum 全错(UT 探针在 c2 抓到:decode 内部
  //       io_in_0_ready_0=1 而核 FSM 读到的 _decode_io_in_ready[0]=0)。此处补接。
  //     位序:bit i = io_in_i_ready(与 decls 注释 {in_5..0}.ready 的 LSB=in_0 一致)。
  // --------------------------------------------------------------------------
  assign _decode_io_in_ready = { _decode_io_in_5_ready, _decode_io_in_4_ready,
                                 _decode_io_in_3_ready, _decode_io_in_2_ready,
                                 _decode_io_in_1_ready, _decode_io_in_0_ready };

  // (0b) 同理:perf 输出数组 _<inst>_io_perf_value[] 也只声明(decls)未被赋值,而 inst
  //      把 perf 引脚连到标量 _<inst>_io_perf_k_value。outglue 的 perfSrc 用数组 → 读到 0。
  //      此处把标量 perf 引脚聚成数组(round7 UT 探针在 t=164000 抓到 io_perf_* 全 0)。
  assign _decode_io_perf_value[0] = _decode_io_perf_0_value;
  assign _decode_io_perf_value[1] = _decode_io_perf_1_value;
  assign _decode_io_perf_value[2] = _decode_io_perf_2_value;
  assign _decode_io_perf_value[3] = _decode_io_perf_3_value;
  assign _decode_io_perf_value[4] = _decode_io_perf_4_value;
  assign _decode_io_perf_value[5] = _decode_io_perf_5_value;
  assign _rename_io_perf_value[0]  = _rename_io_perf_0_value;
  assign _rename_io_perf_value[1]  = _rename_io_perf_1_value;
  assign _rename_io_perf_value[2]  = _rename_io_perf_2_value;
  assign _rename_io_perf_value[3]  = _rename_io_perf_3_value;
  assign _rename_io_perf_value[4]  = _rename_io_perf_4_value;
  assign _rename_io_perf_value[5]  = _rename_io_perf_5_value;
  assign _rename_io_perf_value[6]  = _rename_io_perf_6_value;
  assign _rename_io_perf_value[7]  = _rename_io_perf_7_value;
  assign _rename_io_perf_value[8]  = _rename_io_perf_8_value;
  assign _rename_io_perf_value[9]  = _rename_io_perf_9_value;
  assign _rename_io_perf_value[10] = _rename_io_perf_10_value;
  assign _rename_io_perf_value[11] = _rename_io_perf_11_value;
  assign _rename_io_perf_value[12] = _rename_io_perf_12_value;
  assign _rename_io_perf_value[13] = _rename_io_perf_13_value;
  assign _rename_io_perf_value[14] = _rename_io_perf_14_value;
  assign _rename_io_perf_value[15] = _rename_io_perf_15_value;
  assign _rename_io_perf_value[16] = _rename_io_perf_16_value;
  assign _rename_io_perf_value[17] = _rename_io_perf_17_value;
  assign _rename_io_perf_value[18] = _rename_io_perf_18_value;
  assign _rename_io_perf_value[19] = _rename_io_perf_19_value;
  assign _rename_io_perf_value[20] = _rename_io_perf_20_value;
  assign _rename_io_perf_value[21] = _rename_io_perf_21_value;
  assign _rename_io_perf_value[22] = _rename_io_perf_22_value;
  assign _rename_io_perf_value[23] = _rename_io_perf_23_value;
  assign _rename_io_perf_value[24] = _rename_io_perf_24_value;
  assign _rename_io_perf_value[25] = _rename_io_perf_25_value;
  assign _rename_io_perf_value[26] = _rename_io_perf_26_value;
  assign _rename_io_perf_value[27] = _rename_io_perf_27_value;
  assign _rename_io_perf_value[28] = _rename_io_perf_28_value;
  assign _rename_io_perf_value[29] = _rename_io_perf_29_value;
  assign _dispatch_io_perf_value[0] = _dispatch_io_perf_0_value;
  assign _dispatch_io_perf_value[1] = _dispatch_io_perf_1_value;
  assign _dispatch_io_perf_value[2] = _dispatch_io_perf_2_value;
  assign _dispatch_io_perf_value[3] = _dispatch_io_perf_3_value;
  assign _dispatch_io_perf_value[4] = 6'h0;                       // 4 号口未引出
  assign _dispatch_io_perf_value[5] = _dispatch_io_perf_5_value;
  assign _dispatch_io_perf_value[6] = _dispatch_io_perf_6_value;
  assign _dispatch_io_perf_value[7] = _dispatch_io_perf_7_value;
  assign _dispatch_io_perf_value[8] = _dispatch_io_perf_8_value;
  assign _rob_io_perf_value[0]  = _rob_io_perf_0_value;
  assign _rob_io_perf_value[1]  = _rob_io_perf_1_value;
  assign _rob_io_perf_value[2]  = _rob_io_perf_2_value;
  assign _rob_io_perf_value[3]  = _rob_io_perf_3_value;
  assign _rob_io_perf_value[4]  = _rob_io_perf_4_value;
  assign _rob_io_perf_value[5]  = _rob_io_perf_5_value;
  assign _rob_io_perf_value[6]  = _rob_io_perf_6_value;
  assign _rob_io_perf_value[7]  = _rob_io_perf_7_value;
  assign _rob_io_perf_value[8]  = _rob_io_perf_8_value;
  assign _rob_io_perf_value[9]  = _rob_io_perf_9_value;
  assign _rob_io_perf_value[10] = _rob_io_perf_10_value;
  assign _rob_io_perf_value[11] = _rob_io_perf_11_value;
  assign _rob_io_perf_value[12] = _rob_io_perf_12_value;
  assign _rob_io_perf_value[13] = _rob_io_perf_13_value;
  assign _rob_io_perf_value[14] = _rob_io_perf_14_value;
  assign _rob_io_perf_value[15] = _rob_io_perf_15_value;
  assign _rob_io_perf_value[16] = _rob_io_perf_16_value;
  assign _rob_io_perf_value[17] = _rob_io_perf_17_value;

  // ==========================================================================
  // (A) DecodeStage 入口 valid:decodeInValid[k]
  //     decode buffer 头有效(decodeBufValid[0]=1)时,decode 输入取自 buffer 第 k 槽
  //     的 valid;否则取自 frontend cfVec[k].valid。
  //       io_in_k_valid = decodeBufValid[0] ? decodeBufValid[k] : cfVec[k].valid
  // --------------------------------------------------------------------------
  // 注:decodeInValid / fusionDecExcVec / fusionInValid 的「声明」在 ctrlblock_decls.svh
  // (须先于 ctrlblock_inst.svh,否则 inst 引脚引用会触发 VCS 隐式 scalar net 声明而冲突);
  // 本文件只放「驱动逻辑」(引用 inst.svh 的 decode 黑盒输出网)。
  genvar gdv;
  generate
    for (gdv = 0; gdv < ctrlblock_pkg::DecodeWidth; gdv++) begin : g_decode_in_valid
      assign decodeInValid[gdv] =
          decodeBufValid[0] ? decodeBufValid[gdv] : frontend_cfVec_valid[gdv];
    end
  endgenerate

  // ==========================================================================
  // (B) FusionDecoder 入口 valid:fusionInValid[k]
  //     只有「decode 输出 k 有效 且 无异常 且 无 trigger 命中」才送融合译码尝试融合。
  //       fusionInValid[k] = _decode_io_out_k_valid
  //                          & ~((|exceptionVec[23:0]) | (trigger != 4'hF))
  //     注:trigger==4'hF 表示「全 1 = 无 trigger 需处理」,故 !=4'hF 视作有 trigger。
  // --------------------------------------------------------------------------
  assign fusionDecExcVec[0] = {
      _decode_io_out_0_bits_exceptionVec_23, _decode_io_out_0_bits_exceptionVec_22,
      _decode_io_out_0_bits_exceptionVec_21, _decode_io_out_0_bits_exceptionVec_20,
      _decode_io_out_0_bits_exceptionVec_19, _decode_io_out_0_bits_exceptionVec_18,
      _decode_io_out_0_bits_exceptionVec_17, _decode_io_out_0_bits_exceptionVec_16,
      _decode_io_out_0_bits_exceptionVec_15, _decode_io_out_0_bits_exceptionVec_14,
      _decode_io_out_0_bits_exceptionVec_13, _decode_io_out_0_bits_exceptionVec_12,
      _decode_io_out_0_bits_exceptionVec_11, _decode_io_out_0_bits_exceptionVec_10,
      _decode_io_out_0_bits_exceptionVec_9,  _decode_io_out_0_bits_exceptionVec_8,
      _decode_io_out_0_bits_exceptionVec_7,  _decode_io_out_0_bits_exceptionVec_6,
      _decode_io_out_0_bits_exceptionVec_5,  _decode_io_out_0_bits_exceptionVec_4,
      _decode_io_out_0_bits_exceptionVec_3,  _decode_io_out_0_bits_exceptionVec_2,
      _decode_io_out_0_bits_exceptionVec_1,  _decode_io_out_0_bits_exceptionVec_0 };
  assign fusionDecExcVec[1] = {
      _decode_io_out_1_bits_exceptionVec_23, _decode_io_out_1_bits_exceptionVec_22,
      _decode_io_out_1_bits_exceptionVec_21, _decode_io_out_1_bits_exceptionVec_20,
      _decode_io_out_1_bits_exceptionVec_19, _decode_io_out_1_bits_exceptionVec_18,
      _decode_io_out_1_bits_exceptionVec_17, _decode_io_out_1_bits_exceptionVec_16,
      _decode_io_out_1_bits_exceptionVec_15, _decode_io_out_1_bits_exceptionVec_14,
      _decode_io_out_1_bits_exceptionVec_13, _decode_io_out_1_bits_exceptionVec_12,
      _decode_io_out_1_bits_exceptionVec_11, _decode_io_out_1_bits_exceptionVec_10,
      _decode_io_out_1_bits_exceptionVec_9,  _decode_io_out_1_bits_exceptionVec_8,
      _decode_io_out_1_bits_exceptionVec_7,  _decode_io_out_1_bits_exceptionVec_6,
      _decode_io_out_1_bits_exceptionVec_5,  _decode_io_out_1_bits_exceptionVec_4,
      _decode_io_out_1_bits_exceptionVec_3,  _decode_io_out_1_bits_exceptionVec_2,
      _decode_io_out_1_bits_exceptionVec_1,  _decode_io_out_1_bits_exceptionVec_0 };
  assign fusionDecExcVec[2] = {
      _decode_io_out_2_bits_exceptionVec_23, _decode_io_out_2_bits_exceptionVec_22,
      _decode_io_out_2_bits_exceptionVec_21, _decode_io_out_2_bits_exceptionVec_20,
      _decode_io_out_2_bits_exceptionVec_19, _decode_io_out_2_bits_exceptionVec_18,
      _decode_io_out_2_bits_exceptionVec_17, _decode_io_out_2_bits_exceptionVec_16,
      _decode_io_out_2_bits_exceptionVec_15, _decode_io_out_2_bits_exceptionVec_14,
      _decode_io_out_2_bits_exceptionVec_13, _decode_io_out_2_bits_exceptionVec_12,
      _decode_io_out_2_bits_exceptionVec_11, _decode_io_out_2_bits_exceptionVec_10,
      _decode_io_out_2_bits_exceptionVec_9,  _decode_io_out_2_bits_exceptionVec_8,
      _decode_io_out_2_bits_exceptionVec_7,  _decode_io_out_2_bits_exceptionVec_6,
      _decode_io_out_2_bits_exceptionVec_5,  _decode_io_out_2_bits_exceptionVec_4,
      _decode_io_out_2_bits_exceptionVec_3,  _decode_io_out_2_bits_exceptionVec_2,
      _decode_io_out_2_bits_exceptionVec_1,  _decode_io_out_2_bits_exceptionVec_0 };
  assign fusionDecExcVec[3] = {
      _decode_io_out_3_bits_exceptionVec_23, _decode_io_out_3_bits_exceptionVec_22,
      _decode_io_out_3_bits_exceptionVec_21, _decode_io_out_3_bits_exceptionVec_20,
      _decode_io_out_3_bits_exceptionVec_19, _decode_io_out_3_bits_exceptionVec_18,
      _decode_io_out_3_bits_exceptionVec_17, _decode_io_out_3_bits_exceptionVec_16,
      _decode_io_out_3_bits_exceptionVec_15, _decode_io_out_3_bits_exceptionVec_14,
      _decode_io_out_3_bits_exceptionVec_13, _decode_io_out_3_bits_exceptionVec_12,
      _decode_io_out_3_bits_exceptionVec_11, _decode_io_out_3_bits_exceptionVec_10,
      _decode_io_out_3_bits_exceptionVec_9,  _decode_io_out_3_bits_exceptionVec_8,
      _decode_io_out_3_bits_exceptionVec_7,  _decode_io_out_3_bits_exceptionVec_6,
      _decode_io_out_3_bits_exceptionVec_5,  _decode_io_out_3_bits_exceptionVec_4,
      _decode_io_out_3_bits_exceptionVec_3,  _decode_io_out_3_bits_exceptionVec_2,
      _decode_io_out_3_bits_exceptionVec_1,  _decode_io_out_3_bits_exceptionVec_0 };
  assign fusionDecExcVec[4] = {
      _decode_io_out_4_bits_exceptionVec_23, _decode_io_out_4_bits_exceptionVec_22,
      _decode_io_out_4_bits_exceptionVec_21, _decode_io_out_4_bits_exceptionVec_20,
      _decode_io_out_4_bits_exceptionVec_19, _decode_io_out_4_bits_exceptionVec_18,
      _decode_io_out_4_bits_exceptionVec_17, _decode_io_out_4_bits_exceptionVec_16,
      _decode_io_out_4_bits_exceptionVec_15, _decode_io_out_4_bits_exceptionVec_14,
      _decode_io_out_4_bits_exceptionVec_13, _decode_io_out_4_bits_exceptionVec_12,
      _decode_io_out_4_bits_exceptionVec_11, _decode_io_out_4_bits_exceptionVec_10,
      _decode_io_out_4_bits_exceptionVec_9,  _decode_io_out_4_bits_exceptionVec_8,
      _decode_io_out_4_bits_exceptionVec_7,  _decode_io_out_4_bits_exceptionVec_6,
      _decode_io_out_4_bits_exceptionVec_5,  _decode_io_out_4_bits_exceptionVec_4,
      _decode_io_out_4_bits_exceptionVec_3,  _decode_io_out_4_bits_exceptionVec_2,
      _decode_io_out_4_bits_exceptionVec_1,  _decode_io_out_4_bits_exceptionVec_0 };
  assign fusionDecExcVec[5] = {
      _decode_io_out_5_bits_exceptionVec_23, _decode_io_out_5_bits_exceptionVec_22,
      _decode_io_out_5_bits_exceptionVec_21, _decode_io_out_5_bits_exceptionVec_20,
      _decode_io_out_5_bits_exceptionVec_19, _decode_io_out_5_bits_exceptionVec_18,
      _decode_io_out_5_bits_exceptionVec_17, _decode_io_out_5_bits_exceptionVec_16,
      _decode_io_out_5_bits_exceptionVec_15, _decode_io_out_5_bits_exceptionVec_14,
      _decode_io_out_5_bits_exceptionVec_13, _decode_io_out_5_bits_exceptionVec_12,
      _decode_io_out_5_bits_exceptionVec_11, _decode_io_out_5_bits_exceptionVec_10,
      _decode_io_out_5_bits_exceptionVec_9,  _decode_io_out_5_bits_exceptionVec_8,
      _decode_io_out_5_bits_exceptionVec_7,  _decode_io_out_5_bits_exceptionVec_6,
      _decode_io_out_5_bits_exceptionVec_5,  _decode_io_out_5_bits_exceptionVec_4,
      _decode_io_out_5_bits_exceptionVec_3,  _decode_io_out_5_bits_exceptionVec_2,
      _decode_io_out_5_bits_exceptionVec_1,  _decode_io_out_5_bits_exceptionVec_0 };

  assign fusionInValid[0] = _decode_io_out_0_valid
      & ~((|fusionDecExcVec[0]) | (_decode_io_out_0_bits_trigger != 4'hF));
  assign fusionInValid[1] = _decode_io_out_1_valid
      & ~((|fusionDecExcVec[1]) | (_decode_io_out_1_bits_trigger != 4'hF));
  assign fusionInValid[2] = _decode_io_out_2_valid
      & ~((|fusionDecExcVec[2]) | (_decode_io_out_2_bits_trigger != 4'hF));
  assign fusionInValid[3] = _decode_io_out_3_valid
      & ~((|fusionDecExcVec[3]) | (_decode_io_out_3_bits_trigger != 4'hF));
  assign fusionInValid[4] = _decode_io_out_4_valid
      & ~((|fusionDecExcVec[4]) | (_decode_io_out_4_bits_trigger != 4'hF));
  assign fusionInValid[5] = _decode_io_out_5_valid
      & ~((|fusionDecExcVec[5]) | (_decode_io_out_5_bits_trigger != 4'hF));

  // ==========================================================================
  // (C) SnapshotGenerator 输出聚合(★ round8 关键修复:消 X 馈入根因)
  //     SnapshotGenerator_14 的输出引脚是「标量」(io_valids_0..3 /
  //     io_snapshots_N_robIdx_0_{flag,value} / io_snapshots_N_isCFI_0..5),
  //     inst.svh 把它们连到标量网 _snpt_io_valids_M / _snpt_io_snapshots_N_robIdx_0_*
  //     / _snpt_io_snapshots_N_isCFI_M。
  //     但 logic.svh(块 4:useSnpt/snptSelect/flushVec)消费的是「向量/head」命名:
  //       snptValids = _snpt_io_valids[3:0]
  //       snptHeadValue[N] = _snpt_io_snapshots_N_robIdx_head_value
  //       _snpt_io_snapshots_N_isCFI[M]
  //     这些向量/head 网在 decls.svh 声明却从未被驱动 → VCS 当悬空 net = X,
  //     使 snptValids/useSnpt/flushVec 全程 X(UT 探针:reset 期 core snptValids=xxxx
  //     而 golden=0000,t=164000 useSnpt i=x,为整链最早分叉)。此处把标量聚成
  //     logic.svh 消费的向量/head 名,打通驱动。(同 round7 的 _decode_io_in_ready /
  //     perf 数组「声明未驱动」型 bug。)
  // --------------------------------------------------------------------------
  assign _snpt_io_valids = { _snpt_io_valids_3, _snpt_io_valids_2,
                             _snpt_io_valids_1, _snpt_io_valids_0 };

  // 各槽 head(robIdx_0 即 head 项)flag/value
  assign _snpt_io_snapshots_0_robIdx_head_flag  = _snpt_io_snapshots_0_robIdx_0_flag;
  assign _snpt_io_snapshots_0_robIdx_head_value = _snpt_io_snapshots_0_robIdx_0_value;
  assign _snpt_io_snapshots_1_robIdx_head_flag  = _snpt_io_snapshots_1_robIdx_0_flag;
  assign _snpt_io_snapshots_1_robIdx_head_value = _snpt_io_snapshots_1_robIdx_0_value;
  assign _snpt_io_snapshots_2_robIdx_head_flag  = _snpt_io_snapshots_2_robIdx_0_flag;
  assign _snpt_io_snapshots_2_robIdx_head_value = _snpt_io_snapshots_2_robIdx_0_value;
  assign _snpt_io_snapshots_3_robIdx_head_flag  = _snpt_io_snapshots_3_robIdx_0_flag;
  assign _snpt_io_snapshots_3_robIdx_head_value = _snpt_io_snapshots_3_robIdx_0_value;

  // 各槽 isCFI 向量(6 条 RenameWidth)
  assign _snpt_io_snapshots_0_isCFI = {
      _snpt_io_snapshots_0_isCFI_5, _snpt_io_snapshots_0_isCFI_4,
      _snpt_io_snapshots_0_isCFI_3, _snpt_io_snapshots_0_isCFI_2,
      _snpt_io_snapshots_0_isCFI_1, _snpt_io_snapshots_0_isCFI_0 };
  assign _snpt_io_snapshots_1_isCFI = {
      _snpt_io_snapshots_1_isCFI_5, _snpt_io_snapshots_1_isCFI_4,
      _snpt_io_snapshots_1_isCFI_3, _snpt_io_snapshots_1_isCFI_2,
      _snpt_io_snapshots_1_isCFI_1, _snpt_io_snapshots_1_isCFI_0 };
  assign _snpt_io_snapshots_2_isCFI = {
      _snpt_io_snapshots_2_isCFI_5, _snpt_io_snapshots_2_isCFI_4,
      _snpt_io_snapshots_2_isCFI_3, _snpt_io_snapshots_2_isCFI_2,
      _snpt_io_snapshots_2_isCFI_1, _snpt_io_snapshots_2_isCFI_0 };
  assign _snpt_io_snapshots_3_isCFI = {
      _snpt_io_snapshots_3_isCFI_5, _snpt_io_snapshots_3_isCFI_4,
      _snpt_io_snapshots_3_isCFI_3, _snpt_io_snapshots_3_isCFI_2,
      _snpt_io_snapshots_3_isCFI_1, _snpt_io_snapshots_3_isCFI_0 };

  // 各槽 6 条 robIdx 的 flag/value 数组(flushVec 的 should_flush_slot 逐条用 [k]);
  // inst 驱动的是标量 _snpt_io_snapshots_N_robIdx_M_{flag,value}(M=0..5),
  // decls 声明的是 unpacked 数组 [0:5] —— 同「声明未驱动」型 X,此处逐条接通。
  assign _snpt_io_snapshots_0_robIdx_flag[0]  = _snpt_io_snapshots_0_robIdx_0_flag;
  assign _snpt_io_snapshots_0_robIdx_value[0] = _snpt_io_snapshots_0_robIdx_0_value;
  assign _snpt_io_snapshots_0_robIdx_flag[1]  = _snpt_io_snapshots_0_robIdx_1_flag;
  assign _snpt_io_snapshots_0_robIdx_value[1] = _snpt_io_snapshots_0_robIdx_1_value;
  assign _snpt_io_snapshots_0_robIdx_flag[2]  = _snpt_io_snapshots_0_robIdx_2_flag;
  assign _snpt_io_snapshots_0_robIdx_value[2] = _snpt_io_snapshots_0_robIdx_2_value;
  assign _snpt_io_snapshots_0_robIdx_flag[3]  = _snpt_io_snapshots_0_robIdx_3_flag;
  assign _snpt_io_snapshots_0_robIdx_value[3] = _snpt_io_snapshots_0_robIdx_3_value;
  assign _snpt_io_snapshots_0_robIdx_flag[4]  = _snpt_io_snapshots_0_robIdx_4_flag;
  assign _snpt_io_snapshots_0_robIdx_value[4] = _snpt_io_snapshots_0_robIdx_4_value;
  assign _snpt_io_snapshots_0_robIdx_flag[5]  = _snpt_io_snapshots_0_robIdx_5_flag;
  assign _snpt_io_snapshots_0_robIdx_value[5] = _snpt_io_snapshots_0_robIdx_5_value;
  assign _snpt_io_snapshots_1_robIdx_flag[0]  = _snpt_io_snapshots_1_robIdx_0_flag;
  assign _snpt_io_snapshots_1_robIdx_value[0] = _snpt_io_snapshots_1_robIdx_0_value;
  assign _snpt_io_snapshots_1_robIdx_flag[1]  = _snpt_io_snapshots_1_robIdx_1_flag;
  assign _snpt_io_snapshots_1_robIdx_value[1] = _snpt_io_snapshots_1_robIdx_1_value;
  assign _snpt_io_snapshots_1_robIdx_flag[2]  = _snpt_io_snapshots_1_robIdx_2_flag;
  assign _snpt_io_snapshots_1_robIdx_value[2] = _snpt_io_snapshots_1_robIdx_2_value;
  assign _snpt_io_snapshots_1_robIdx_flag[3]  = _snpt_io_snapshots_1_robIdx_3_flag;
  assign _snpt_io_snapshots_1_robIdx_value[3] = _snpt_io_snapshots_1_robIdx_3_value;
  assign _snpt_io_snapshots_1_robIdx_flag[4]  = _snpt_io_snapshots_1_robIdx_4_flag;
  assign _snpt_io_snapshots_1_robIdx_value[4] = _snpt_io_snapshots_1_robIdx_4_value;
  assign _snpt_io_snapshots_1_robIdx_flag[5]  = _snpt_io_snapshots_1_robIdx_5_flag;
  assign _snpt_io_snapshots_1_robIdx_value[5] = _snpt_io_snapshots_1_robIdx_5_value;
  assign _snpt_io_snapshots_2_robIdx_flag[0]  = _snpt_io_snapshots_2_robIdx_0_flag;
  assign _snpt_io_snapshots_2_robIdx_value[0] = _snpt_io_snapshots_2_robIdx_0_value;
  assign _snpt_io_snapshots_2_robIdx_flag[1]  = _snpt_io_snapshots_2_robIdx_1_flag;
  assign _snpt_io_snapshots_2_robIdx_value[1] = _snpt_io_snapshots_2_robIdx_1_value;
  assign _snpt_io_snapshots_2_robIdx_flag[2]  = _snpt_io_snapshots_2_robIdx_2_flag;
  assign _snpt_io_snapshots_2_robIdx_value[2] = _snpt_io_snapshots_2_robIdx_2_value;
  assign _snpt_io_snapshots_2_robIdx_flag[3]  = _snpt_io_snapshots_2_robIdx_3_flag;
  assign _snpt_io_snapshots_2_robIdx_value[3] = _snpt_io_snapshots_2_robIdx_3_value;
  assign _snpt_io_snapshots_2_robIdx_flag[4]  = _snpt_io_snapshots_2_robIdx_4_flag;
  assign _snpt_io_snapshots_2_robIdx_value[4] = _snpt_io_snapshots_2_robIdx_4_value;
  assign _snpt_io_snapshots_2_robIdx_flag[5]  = _snpt_io_snapshots_2_robIdx_5_flag;
  assign _snpt_io_snapshots_2_robIdx_value[5] = _snpt_io_snapshots_2_robIdx_5_value;
  assign _snpt_io_snapshots_3_robIdx_flag[0]  = _snpt_io_snapshots_3_robIdx_0_flag;
  assign _snpt_io_snapshots_3_robIdx_value[0] = _snpt_io_snapshots_3_robIdx_0_value;
  assign _snpt_io_snapshots_3_robIdx_flag[1]  = _snpt_io_snapshots_3_robIdx_1_flag;
  assign _snpt_io_snapshots_3_robIdx_value[1] = _snpt_io_snapshots_3_robIdx_1_value;
  assign _snpt_io_snapshots_3_robIdx_flag[2]  = _snpt_io_snapshots_3_robIdx_2_flag;
  assign _snpt_io_snapshots_3_robIdx_value[2] = _snpt_io_snapshots_3_robIdx_2_value;
  assign _snpt_io_snapshots_3_robIdx_flag[3]  = _snpt_io_snapshots_3_robIdx_3_flag;
  assign _snpt_io_snapshots_3_robIdx_value[3] = _snpt_io_snapshots_3_robIdx_3_value;
  assign _snpt_io_snapshots_3_robIdx_flag[4]  = _snpt_io_snapshots_3_robIdx_4_flag;
  assign _snpt_io_snapshots_3_robIdx_value[4] = _snpt_io_snapshots_3_robIdx_4_value;
  assign _snpt_io_snapshots_3_robIdx_flag[5]  = _snpt_io_snapshots_3_robIdx_5_flag;
  assign _snpt_io_snapshots_3_robIdx_value[5] = _snpt_io_snapshots_3_robIdx_5_value;

  // ==========================================================================
  // (D) Rob commits 输出聚合(★ 关键修复:同 (0)/(C) 的「声明未驱动」型 X/悬空 bug)
  //     Rob 例化(inst.svh)把 commits 输出连到「标量」网:
  //       _rob_io_commits_commitValid_M (M=0..7)
  //       _rob_io_commits_robIdx_M_{flag,value}
  //       _rob_io_commits_info_M_{commitType,ftqIdx_flag,ftqIdx_value,ftqOffset}
  //     但 logic.svh(块4 snpt deq)/ outglue.svh(块⑤ commits->FTQ)消费的是
  //     「向量/数组/别名」命名(decls.svh 声明却从未被驱动):
  //       _rob_io_commits_commitValid[5:0]  _rob_io_commits_robIdx_flag[5:0]
  //       _rob_io_commits_robIdx_value_N     _rob_io_commits_info_*_ ...[0:5]
  //     不接通则这些网悬空 = X/0,使 s1_isCommit / snpt deq / ftqCommit 全错
  //     (FM 表现:io_frontend_toFtq_rob_commits_* bits/valid + snpt/* 全 failing)。
  //     位序/下标:bit/idx N 对应 commit 槽 N(LSB=槽0),与 decls 注释一致。
  // --------------------------------------------------------------------------
  assign _rob_io_commits_commitValid = { _rob_io_commits_commitValid_5,
                                         _rob_io_commits_commitValid_4,
                                         _rob_io_commits_commitValid_3,
                                         _rob_io_commits_commitValid_2,
                                         _rob_io_commits_commitValid_1,
                                         _rob_io_commits_commitValid_0 };
  assign _rob_io_commits_robIdx_flag = { _rob_io_commits_robIdx_5_flag,
                                         _rob_io_commits_robIdx_4_flag,
                                         _rob_io_commits_robIdx_3_flag,
                                         _rob_io_commits_robIdx_2_flag,
                                         _rob_io_commits_robIdx_1_flag,
                                         _rob_io_commits_robIdx_0_flag };
  assign _rob_io_commits_robIdx_value_0 = _rob_io_commits_robIdx_0_value;
  assign _rob_io_commits_robIdx_value_1 = _rob_io_commits_robIdx_1_value;
  assign _rob_io_commits_robIdx_value_2 = _rob_io_commits_robIdx_2_value;
  assign _rob_io_commits_robIdx_value_3 = _rob_io_commits_robIdx_3_value;
  assign _rob_io_commits_robIdx_value_4 = _rob_io_commits_robIdx_4_value;
  assign _rob_io_commits_robIdx_value_5 = _rob_io_commits_robIdx_5_value;
  assign _rob_io_commits_info_flag_commitType[0] = _rob_io_commits_info_0_commitType;
  assign _rob_io_commits_info_flag_commitType[1] = _rob_io_commits_info_1_commitType;
  assign _rob_io_commits_info_flag_commitType[2] = _rob_io_commits_info_2_commitType;
  assign _rob_io_commits_info_flag_commitType[3] = _rob_io_commits_info_3_commitType;
  assign _rob_io_commits_info_flag_commitType[4] = _rob_io_commits_info_4_commitType;
  assign _rob_io_commits_info_flag_commitType[5] = _rob_io_commits_info_5_commitType;
  assign _rob_io_commits_info_ftqIdx_flag[0] = _rob_io_commits_info_0_ftqIdx_flag;
  assign _rob_io_commits_info_ftqIdx_flag[1] = _rob_io_commits_info_1_ftqIdx_flag;
  assign _rob_io_commits_info_ftqIdx_flag[2] = _rob_io_commits_info_2_ftqIdx_flag;
  assign _rob_io_commits_info_ftqIdx_flag[3] = _rob_io_commits_info_3_ftqIdx_flag;
  assign _rob_io_commits_info_ftqIdx_flag[4] = _rob_io_commits_info_4_ftqIdx_flag;
  assign _rob_io_commits_info_ftqIdx_flag[5] = _rob_io_commits_info_5_ftqIdx_flag;
  assign _rob_io_commits_info_ftqIdx_value[0] = _rob_io_commits_info_0_ftqIdx_value;
  assign _rob_io_commits_info_ftqIdx_value[1] = _rob_io_commits_info_1_ftqIdx_value;
  assign _rob_io_commits_info_ftqIdx_value[2] = _rob_io_commits_info_2_ftqIdx_value;
  assign _rob_io_commits_info_ftqIdx_value[3] = _rob_io_commits_info_3_ftqIdx_value;
  assign _rob_io_commits_info_ftqIdx_value[4] = _rob_io_commits_info_4_ftqIdx_value;
  assign _rob_io_commits_info_ftqIdx_value[5] = _rob_io_commits_info_5_ftqIdx_value;
  assign _rob_io_commits_info_ftqOffset[0] = _rob_io_commits_info_0_ftqOffset;
  assign _rob_io_commits_info_ftqOffset[1] = _rob_io_commits_info_1_ftqOffset;
  assign _rob_io_commits_info_ftqOffset[2] = _rob_io_commits_info_2_ftqOffset;
  assign _rob_io_commits_info_ftqOffset[3] = _rob_io_commits_info_3_ftqOffset;
  assign _rob_io_commits_info_ftqOffset[4] = _rob_io_commits_info_4_ftqOffset;
  assign _rob_io_commits_info_ftqOffset[5] = _rob_io_commits_info_5_ftqOffset;

  // commit lane 6/7 别名驱动(供 logic.svh 块4 snpt deq 的 commitMatchHead;golden
  // _snpt_io_deq_T_35 的 head 匹配遍历全 8 lane)。scalar 由 inst.svh(在本文件之前)声明连接。
  assign commitLane6Valid = _rob_io_commits_commitValid_6;
  assign commitLane7Valid = _rob_io_commits_commitValid_7;
  assign commitLane6Flag  = _rob_io_commits_robIdx_6_flag;
  assign commitLane7Flag  = _rob_io_commits_robIdx_7_flag;
  assign commitLane6Value = _rob_io_commits_robIdx_6_value;
  assign commitLane7Value = _rob_io_commits_robIdx_7_value;
