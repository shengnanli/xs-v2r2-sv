// PBestOffset_children.sv —— PBestOffsetPrefetch 子树可读实现(TL2 shard D, AUX signoff)。
//
// 含四个可读核, 供 PBestOffsetPrefetch 顶层例化:
//   xs_DelayQueue_core          —— 16 深延迟环形队列(每条目倒计时 300 拍后可出队)。
//   xs_OffsetScoreTable_core    —— BestOffset 学习 FSM(37 个 offset 分数计数器 +
//                                   round/ptr 迭代 + bestOffset/bestScore 跟踪)。
//   xs_RecentRequestTable_core  —— 3 级读流水 over SRAM(地址哈希 + tag 比对);
//                                   内部例化 xs_SRAMTemplate_135_core。
//   xs_SRAMTemplate_135_core    —— SRAM 包裹控制(reset 扫描 + MBIST bore mux +
//                                   resp 打拍), 仅厂商宏 sram_array_... 黑盒。
//
// 说明: 唯一黑盒 = 厂商 SRAM 宏 sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt
// (256x13 单口), 两侧 elaborate 均不解析 → hdlin_unresolved_modules=black_box。
// 其余全部可读逻辑, 无 dont_verify/stub。

// ============================================================================
// xs_DelayQueue_core —— 16 深延迟环形队列。
//   入队(io_in_valid & ~full): 在 tail 写 addrNoOffset(=io_in_bits), 计数=300(0x12C),
//       置 valid, tail++。
//   每拍: 所有非零计数递减(倒计时)。
//   出队条件 outValid = ~empty & queue[head].cnt==0 & valids[head]。
//   出队(outValid & io_out_ready): head++, 清 valids[head]。
//   io_out_bits = {addrNoOffset[head], 6'h0}(48b = 42b 地址左移 6)。
// ============================================================================
module xs_DelayQueue_core(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [41:0] io_in_bits,
  input         io_out_ready,
  output        io_out_valid,
  output [47:0] io_out_bits
);

  localparam [8:0] DELAY = 9'h12C; // 300

  reg  [41:0] queue_addr [0:15];
  reg  [8:0]  queue_cnt  [0:15];
  reg  [15:0] valids;
  reg  [3:0]  head;
  reg  [3:0]  tail;

  wire headEqTail = head == tail;
  wire empty      = headEqTail & ~valids[15];
  wire full       = headEqTail &  valids[15];

  wire outValid = ~empty & (queue_cnt[head] == 9'h0) & valids[head];
  wire doEnq    = io_in_valid & ~full;
  wire doDeq    = outValid & io_out_ready;

  integer i;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      for (i = 0; i < 16; i = i + 1) begin
        queue_addr[i] <= 42'h0;
        queue_cnt[i]  <= 9'h0;
      end
      valids <= 16'h0;
      head   <= 4'h0;
      tail   <= 4'h0;
    end
    else begin
      for (i = 0; i < 16; i = i + 1) begin
        // 写地址: 入队且 tail 指向本条目。
        if (doEnq & (tail == i[3:0]))
          queue_addr[i] <= io_in_bits;
        // 倒计时: 非零则减 1; 否则若本拍入队本条目, 重置到 DELAY。
        if (|queue_cnt[i])
          queue_cnt[i] <= 9'(queue_cnt[i] - 9'h1);
        else if (doEnq & (tail == i[3:0]))
          queue_cnt[i] <= DELAY;
        // valid: 出队命中本条目则清; 入队命中本条目或保持已有。
        valids[i] <= ~(doDeq & (head == i[3:0])) & ((doEnq & (tail == i[3:0])) | valids[i]);
      end
      if (doDeq) head <= 4'(head + 4'h1);
      if (doEnq) tail <= 4'(tail + 4'h1);
    end
  end

  assign io_out_valid = outValid;
  assign io_out_bits  = {queue_addr[head], 6'h0};

endmodule

// ============================================================================
// xs_OffsetScoreTable_core —— BestOffset 学习分数表 FSM。
//   参数: 37 个候选 offset(offsetList[0..36]), 分数 5 位, ptr 迭代 0..0x24,
//         round 上限 0x31, SCOREMAX = 全 1(5'h1F)。
//   state=0: 提交相位(1 拍)—— 把 bestOffset/isBad 提交到 prefetchOffset/Disable,
//            清所有分数/ptr/round/bestScore, 然后进入 state=1。
//   state=1: 学习相位 —— 每个训练请求发一个 test req(offsetList[ptr]);
//            命中响应(io_test_resp_valid & hit)时把 st[ptr] 分数 +1, 若刷新最优
//            则更新 bestOffset/bestScore; ptr 走到 0x24 则回 0 且 round++;
//            当某分数打满(全 1)或 round>0x31 时学习结束回 state=0。
//   io_test_req_valid = state & io_req_valid; io_test_req_bits_testOffset = offsetList[ptr]。
//   io_req_ready = state(仅学习相位吃训练请求)。
// ============================================================================
module xs_OffsetScoreTable_core(
  input         clock,
  input         reset,
  output        io_req_ready,
  input         io_req_valid,
  input  [47:0] io_req_bits,
  output [6:0]  io_prefetchOffset,
  output        io_prefetchDisable,
  output        io_test_req_valid,
  output [47:0] io_test_req_bits_addr,
  output [6:0]  io_test_req_bits_testOffset,
  output [5:0]  io_test_req_bits_ptr,
  input         io_test_resp_valid,
  input  [5:0]  io_test_resp_bits_ptr,
  input         io_test_resp_bits_hit
);

  // 候选 offset 列表(offsetList) —— 与 golden 64 项 _GEN/_GEN_40 LUT 逐项一致
  // (SV '{...} 首元素对应最高索引, 故列表首=index63; 此处按 index 升序照抄)。
  // 索引 0..36 有效; 37..63 越界回读 0x60。
  function automatic [6:0] offsetList(input [5:0] idx);
    case (idx)
      6'd0: offsetList = 7'h60;  6'd1: offsetList = 7'h62;  6'd2: offsetList = 7'h65;
      6'd3: offsetList = 7'h67;  6'd4: offsetList = 7'h68;  6'd5: offsetList = 7'h6C;
      6'd6: offsetList = 7'h6E;  6'd7: offsetList = 7'h70;  6'd8: offsetList = 7'h71;
      6'd9: offsetList = 7'h74;  6'd10: offsetList = 7'h76; 6'd11: offsetList = 7'h77;
      6'd12: offsetList = 7'h78; 6'd13: offsetList = 7'h7A; 6'd14: offsetList = 7'h7B;
      6'd15: offsetList = 7'h7C; 6'd16: offsetList = 7'h7D; 6'd17: offsetList = 7'h7E;
      6'd18: offsetList = 7'h7F; 6'd19: offsetList = 7'h1;  6'd20: offsetList = 7'h2;
      6'd21: offsetList = 7'h3;  6'd22: offsetList = 7'h4;  6'd23: offsetList = 7'h5;
      6'd24: offsetList = 7'h6;  6'd25: offsetList = 7'h8;  6'd26: offsetList = 7'h9;
      6'd27: offsetList = 7'hA;  6'd28: offsetList = 7'hC;  6'd29: offsetList = 7'hF;
      6'd30: offsetList = 7'h10; 6'd31: offsetList = 7'h12; 6'd32: offsetList = 7'h14;
      6'd33: offsetList = 7'h18; 6'd34: offsetList = 7'h19; 6'd35: offsetList = 7'h1B;
      6'd36: offsetList = 7'h1E;
      default: offsetList = 7'h60;  // 越界(golden _GEN 表: 37..63 → 0x60)
    endcase
  endfunction

  reg  [6:0] prefetchOffset;
  reg        prefetchDisable;
  reg  [4:0] st [0:36];         // 37 个分数计数器
  reg  [5:0] ptr;
  reg  [5:0] round;
  reg  [6:0] bestOffset;
  reg  [4:0] bestScore;
  reg        state;

  wire isBad          = bestScore == 5'h0;
  wire testReqFire    = state & io_req_valid;
  wire roundOver      = {58'h0, round} > 64'h31;
  wire respHit        = io_test_resp_valid & io_test_resp_bits_hit;

  // 命中条目的当前分数 + 1(越界 ptr 回读 st_0, 同 golden 64 项 _GEN_43 LUT:
  // 索引 0..36 选对应 st, 37..63 回读 st_0)。显式组合 mux 避免动态越界索引。
  reg  [4:0] curScore;
  integer k;
  always @(*) begin
    curScore = st[0];                       // 默认(含 37..63 越界)
    for (k = 0; k < 37; k = k + 1)
      if (io_test_resp_bits_ptr == k[5:0])
        curScore = st[k];
  end
  wire [4:0] newScore = 5'(curScore + 5'h1);
  wire       renewOffset = newScore > bestScore;

  integer j;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      prefetchOffset  <= 7'h2;
      prefetchDisable <= 1'h0;
      for (j = 0; j < 37; j = j + 1) st[j] <= 5'h0;
      ptr        <= 6'h0;
      round      <= 6'h0;
      bestOffset <= 7'h2;
      bestScore  <= 5'h0;
      state      <= 1'h0;
    end
    else begin
      // 提交相位(state=0): 输出最优 offset / disable。
      if (~state) begin
        prefetchOffset  <= bestOffset;
        prefetchDisable <= isBad;
      end

      // 分数更新: 学习相位命中 → +1; 提交相位 → 清 0; 学习相位未命中 → 保持。
      for (j = 0; j < 37; j = j + 1) begin
        if (state & respHit & (io_test_resp_bits_ptr == j[5:0]))
          st[j] <= newScore;
        else if (~state)
          st[j] <= 5'h0;
      end

      // ptr / round 迭代。
      if (state & testReqFire) begin
        if (ptr == 6'h24) begin
          ptr   <= 6'h0;
          round <= 6'(round + 6'h1);
        end
        else
          ptr <= 6'(ptr + 6'h1);
      end
      else if (~state) begin
        ptr   <= 6'h0;
        round <= 6'h0;
      end

      // bestOffset / bestScore 跟踪。
      if (state & respHit & renewOffset)
        bestOffset <= offsetList(io_test_resp_bits_ptr);
      if (state & respHit) begin
        if (renewOffset)
          bestScore <= newScore;
      end
      else if (~state)
        bestScore <= 5'h0;

      // 相位切换: 提交相位一拍后进入学习; 学习结束(分数打满或超轮)回提交。
      state <= ~state | (respHit ? ~((&newScore) | roundOver) : ~roundOver);
    end
  end

  assign io_req_ready                = state;
  assign io_prefetchOffset           = prefetchOffset;
  assign io_prefetchDisable          = prefetchDisable;
  assign io_test_req_valid           = testReqFire;
  assign io_test_req_bits_addr       = io_req_bits;
  assign io_test_req_bits_testOffset = offsetList(ptr);
  assign io_test_req_bits_ptr        = ptr;

endmodule

// ============================================================================
// xs_SRAMTemplate_135_core —— 256x13 单口 SRAM 包裹(仅厂商宏 array 黑盒)。
//   复位扫描: 上电 _resetState=1, 扫 _resetSet 0..255 逐 set 写 0, 扫完清 resetState。
//   MBIST bore 通道: mbistBd_ack 时改走 MBIST 地址/数据(bore 端口), 否则走功能读写。
//   单口时序: rckEn=读使能, finalRamWen=写使能(写含复位与功能写, 受 ram_hold 门控)。
//   读数据打拍: respReg 跟随 rckEn, rdataReg 在 respReg 时锁 array 输出。
//   条目 = {valid(1), tag(12)}; io_r_resp_data_0_valid/tag = rdata 高位/低 12 位。
// ============================================================================
module xs_SRAMTemplate_135_core(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [7:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_valid,
  output [11:0] io_r_resp_data_0_tag,
  output        io_w_req_ready,
  input         io_w_req_valid,
  input  [7:0]  io_w_req_bits_setIdx,
  input  [11:0] io_w_req_bits_data_0_tag,
  input         io_broadcast_ram_hold,
  input         io_broadcast_ram_bypass,
  input         io_broadcast_ram_bp_clken,
  input         io_broadcast_ram_aux_clk,
  input         io_broadcast_ram_aux_ckbp,
  input         io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input         io_broadcast_cgen,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  input  [12:0] boreChildrenBd_bore_wdata,
  input         boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [12:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input         boreChildrenBd_bore_array
);

  wire [12:0] array_rdata;

  reg        resetState;
  reg  [7:0] resetSet;
  reg        respReg;
  reg  [12:0] rdataReg;

  wire rReqReady = ~resetState & ~io_w_req_valid;
  // MBIST bore 有 ack 时走 bore 端口, 否则功能读/写。
  wire rckEn      = boreChildrenBd_bore_ack ? boreChildrenBd_bore_re
                                            : rReqReady & io_r_req_valid;
  wire finalRamWen = (boreChildrenBd_bore_ack ? boreChildrenBd_bore_we
                                              : io_w_req_valid | resetState)
                     & ~io_broadcast_ram_hold;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      resetState <= 1'h1;
      resetSet   <= 8'h0;
      respReg    <= 1'h0;
    end
    else begin
      resetState <= ~(resetState & (&resetSet)) & resetState;
      if (resetState)
        resetSet <= 8'(resetSet + 8'h1);
      respReg <= rckEn;
    end
  end

  always @(posedge clock) begin
    if (respReg)
      rdataReg <= array_rdata;
  end

  // 厂商 SRAM 宏(唯一黑盒), 两侧同名同接线。
  sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt array (
    .mbist_dft_ram_bypass   (io_broadcast_ram_bypass),
    .mbist_dft_ram_bp_clken (io_broadcast_ram_bp_clken),
    .RW0_clk                (clock),
    .RW0_addr
      (boreChildrenBd_bore_ack
         ? boreChildrenBd_bore_addr_rd[7:0]
         : finalRamWen
             ? (resetState ? resetSet : io_w_req_bits_setIdx)
             : io_r_req_bits_setIdx),
    .RW0_en                 (finalRamWen | rckEn),
    .RW0_wmode              (finalRamWen),
    .RW0_wdata
      (boreChildrenBd_bore_ack
         ? boreChildrenBd_bore_wdata
         : resetState ? 13'h0 : {1'h1, io_w_req_bits_data_0_tag}),
    .RW0_rdata              (array_rdata)
  );

  assign io_r_req_ready         = rReqReady;
  assign io_r_resp_data_0_valid = array_rdata[12];
  assign io_r_resp_data_0_tag   = array_rdata[11:0];
  assign io_w_req_ready         = ~resetState;
  assign boreChildrenBd_bore_rdata = rdataReg;

endmodule

// ============================================================================
// xs_RecentRequestTable_core —— 最近请求表(RRTable): 3 级读流水 over SRAM。
//   写: io_w(来自 DelayQueue), 地址哈希 setIdx = addr[13:6] ^ addr[21:14],
//       tag = addr[25:14]; 单口 SRAM, 读优先(io_w_ready = w_req_ready & ~r_req_valid)。
//   读: io_r_req 带 testOffset, 计算候选地址 rAddr = addr[25:0] - (testOffset<<6);
//       setIdx = rAddr[13:6]^rAddr[21:14], tag = rAddr[25:14];
//       3 级流水(s1_valid/s2_valid + ptr/tag 打拍), resp.hit = SRAM 命中且 tag 相等。
//   内部例化 xs_SRAMTemplate_135_core(读回 {valid, tag})。
// ============================================================================
module xs_RecentRequestTable_core(
  input         clock,
  input         reset,
  output        io_w_ready,
  input         io_w_valid,
  input  [47:0] io_w_bits,
  input         io_r_req_valid,
  input  [47:0] io_r_req_bits_addr,
  input  [6:0]  io_r_req_bits_testOffset,
  input  [5:0]  io_r_req_bits_ptr,
  output        io_r_resp_valid,
  output [5:0]  io_r_resp_bits_ptr,
  output        io_r_resp_bits_hit,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  input  [12:0] boreChildrenBd_bore_wdata,
  input         boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [12:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input         boreChildrenBd_bore_array,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen
);

  wire        sram_r_req_ready;
  wire        sram_r_resp_data_0_valid;
  wire [11:0] sram_r_resp_data_0_tag;
  wire        sram_w_req_ready;

  // 读候选地址 = 请求地址低 26 位 - (testOffset 符号扩展 << 6)。
  wire [25:0] rAddr = 26'(io_r_req_bits_addr[25:0]
                          - {{13{io_r_req_bits_testOffset[6]}}, io_r_req_bits_testOffset, 6'h0});

  reg        REG;          // 单口读写冲突检测(仅断言用)
  reg        s1_valid;
  reg  [5:0] s1_ptr;
  reg  [11:0] s1_hit_REG;  // 打拍后的期望 tag(rAddr[25:14])
  reg        s2_valid;
  reg  [5:0] io_r_resp_bits_ptr_r;
  reg        io_r_resp_bits_hit_r;

  wire io_w_ready_int = sram_w_req_ready & ~io_r_req_valid;

  always @(posedge clock) begin
    REG        <= io_w_ready_int & io_w_valid & io_r_req_valid;
    s1_ptr     <= io_r_req_bits_ptr;
    s1_hit_REG <= rAddr[25:14];
    if (s1_valid) begin
      io_r_resp_bits_ptr_r <= s1_ptr;
      io_r_resp_bits_hit_r <= sram_r_resp_data_0_valid & (sram_r_resp_data_0_tag == s1_hit_REG);
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid <= 1'h0;
      s2_valid <= 1'h0;
    end
    else begin
      s1_valid <= sram_r_req_ready & io_r_req_valid;
      s2_valid <= s1_valid;
    end
  end

  xs_SRAMTemplate_135_core rrTable (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_ready                 (sram_r_req_ready),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (rAddr[13:6] ^ rAddr[21:14]),
    .io_r_resp_data_0_valid         (sram_r_resp_data_0_valid),
    .io_r_resp_data_0_tag           (sram_r_resp_data_0_tag),
    .io_w_req_ready                 (sram_w_req_ready),
    .io_w_req_valid                 (io_w_valid & ~io_r_req_valid),
    .io_w_req_bits_setIdx           (io_w_bits[13:6] ^ io_w_bits[21:14]),
    .io_w_req_bits_data_0_tag       (io_w_bits[25:14]),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_array)
  );

  assign io_w_ready         = io_w_ready_int;
  assign io_r_resp_valid    = s2_valid;
  assign io_r_resp_bits_ptr = io_r_resp_bits_ptr_r;
  assign io_r_resp_bits_hit = io_r_resp_bits_hit_r;

endmodule
