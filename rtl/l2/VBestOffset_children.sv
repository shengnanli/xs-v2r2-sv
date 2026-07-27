// VBestOffset_children.sv —— VBestOffsetPrefetch 子树可读实现(TL2 shard D, AUX signoff)。
//
// 含三个可读核(与 PBestOffset 同构, 仅位宽/表长不同, virtual-address 版):
//   xs_DelayQueue_1_core         —— 16 深延迟环形队列(addr 44 位, out 50 位)。
//   xs_OffsetScoreTable_1_core   —— BestOffset 学习 FSM(109 offset 分数计数器, 10 位 offset,
//                                   ptr 7 位 0..0x6C, 128 项 LUT)。
//   xs_RecentRequestTable_1_core —— 3 级读流水 over SRAM(与 P 版逻辑一致, testOffset 10 位)。
//                                   内部复用 xs_SRAMTemplate_135_core(见 PBestOffset_children.sv)。
// 说明: 唯一黑盒仍为厂商 SRAM 宏 sram_array_...(在 xs_SRAMTemplate_135_core 中)。

// ============================================================================
// xs_DelayQueue_1_core —— 16 深延迟环形队列(virtual, 44b 地址)。
//   语义与 xs_DelayQueue_core 完全相同, 仅 addrNoOffset 位宽 44、out 位宽 50。
// ============================================================================
module xs_DelayQueue_1_core(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [43:0] io_in_bits,
  input         io_out_ready,
  output        io_out_valid,
  output [49:0] io_out_bits
);

  localparam [8:0] DELAY = 9'h12C; // 300

  reg  [43:0] queue_addr [0:15];
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
        queue_addr[i] <= 44'h0;
        queue_cnt[i]  <= 9'h0;
      end
      valids <= 16'h0;
      head   <= 4'h0;
      tail   <= 4'h0;
    end
    else begin
      for (i = 0; i < 16; i = i + 1) begin
        if (doEnq & (tail == i[3:0]))
          queue_addr[i] <= io_in_bits;
        if (|queue_cnt[i])
          queue_cnt[i] <= 9'(queue_cnt[i] - 9'h1);
        else if (doEnq & (tail == i[3:0]))
          queue_cnt[i] <= DELAY;
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
// xs_OffsetScoreTable_1_core —— BestOffset 学习分数表 FSM(virtual, 10 位 offset)。
//   109 个候选 offset(offsetList_1[0..108]), 分数 5 位, ptr 迭代 0..0x6C(108),
//   round 上限 0x31, SCOREMAX = 全 1。FSM 结构与 P 版一致。
//   128 项 LUT: index 0..108 有效, 109..127 越界回读 offsetList_1(0)=0x38B。
// ============================================================================
module xs_OffsetScoreTable_1_core(
  input         clock,
  input         reset,
  output        io_req_ready,
  input         io_req_valid,
  input  [49:0] io_req_bits,
  output [9:0]  io_prefetchOffset,
  output        io_prefetchDisable,
  output        io_test_req_valid,
  output [49:0] io_test_req_bits_addr,
  output [9:0]  io_test_req_bits_testOffset,
  output [6:0]  io_test_req_bits_ptr,
  input         io_test_resp_valid,
  input  [6:0]  io_test_resp_bits_ptr,
  input         io_test_resp_bits_hit
);

  // 候选 offset 列表 —— 与 golden 128 项 _GEN/_GEN_112 LUT 逐项一致(index 升序)。
  function automatic [9:0] offsetList(input [6:0] idx);
    case (idx)
      7'd0: offsetList = 10'h38B;   7'd1: offsetList = 10'h36D;   7'd2: offsetList = 10'h3A5;   7'd3: offsetList = 10'h75;    7'd4: offsetList = 10'h93;
      7'd5: offsetList = 10'h5B;    7'd6: offsetList = 10'h300;   7'd7: offsetList = 10'h306;   7'd8: offsetList = 10'h30D;   7'd9: offsetList = 10'h310;
      7'd10: offsetList = 10'h31F;  7'd11: offsetList = 10'h328;  7'd12: offsetList = 10'h338;  7'd13: offsetList = 10'h340;  7'd14: offsetList = 10'h34C;
      7'd15: offsetList = 10'h35E;  7'd16: offsetList = 10'h360;  7'd17: offsetList = 10'h36A;  7'd18: offsetList = 10'h370;  7'd19: offsetList = 10'h379;
      7'd20: offsetList = 10'h380;  7'd21: offsetList = 10'h383;  7'd22: offsetList = 10'h388;  7'd23: offsetList = 10'h394;  7'd24: offsetList = 10'h39C;
      7'd25: offsetList = 10'h3A0;  7'd26: offsetList = 10'h3A6;  7'd27: offsetList = 10'h3AF;  7'd28: offsetList = 10'h3B0;  7'd29: offsetList = 10'h3B5;
      7'd30: offsetList = 10'h3B8;  7'd31: offsetList = 10'h3C0;  7'd32: offsetList = 10'h3C4;  7'd33: offsetList = 10'h3CA;  7'd34: offsetList = 10'h3CE;
      7'd35: offsetList = 10'h3D0;  7'd36: offsetList = 10'h3D3;  7'd37: offsetList = 10'h3D8;  7'd38: offsetList = 10'h3DC;  7'd39: offsetList = 10'h3E0;
      7'd40: offsetList = 10'h3E2;  7'd41: offsetList = 10'h3E5;  7'd42: offsetList = 10'h3E7;  7'd43: offsetList = 10'h3E8;  7'd44: offsetList = 10'h3EC;
      7'd45: offsetList = 10'h3EE;  7'd46: offsetList = 10'h3F0;  7'd47: offsetList = 10'h3F1;  7'd48: offsetList = 10'h3F4;  7'd49: offsetList = 10'h3F6;
      7'd50: offsetList = 10'h3F7;  7'd51: offsetList = 10'h3F8;  7'd52: offsetList = 10'h3FA;  7'd53: offsetList = 10'h3FB;  7'd54: offsetList = 10'h3FC;
      7'd55: offsetList = 10'h3FD;  7'd56: offsetList = 10'h3FE;  7'd57: offsetList = 10'h3FF;  7'd58: offsetList = 10'h1;    7'd59: offsetList = 10'h2;
      7'd60: offsetList = 10'h3;    7'd61: offsetList = 10'h4;    7'd62: offsetList = 10'h5;    7'd63: offsetList = 10'h6;    7'd64: offsetList = 10'h8;
      7'd65: offsetList = 10'h9;    7'd66: offsetList = 10'hA;    7'd67: offsetList = 10'hC;    7'd68: offsetList = 10'hF;    7'd69: offsetList = 10'h10;
      7'd70: offsetList = 10'h12;   7'd71: offsetList = 10'h14;   7'd72: offsetList = 10'h18;   7'd73: offsetList = 10'h19;   7'd74: offsetList = 10'h1B;
      7'd75: offsetList = 10'h1E;   7'd76: offsetList = 10'h20;   7'd77: offsetList = 10'h24;   7'd78: offsetList = 10'h28;   7'd79: offsetList = 10'h2D;
      7'd80: offsetList = 10'h30;   7'd81: offsetList = 10'h32;   7'd82: offsetList = 10'h36;   7'd83: offsetList = 10'h3C;   7'd84: offsetList = 10'h40;
      7'd85: offsetList = 10'h48;   7'd86: offsetList = 10'h4B;   7'd87: offsetList = 10'h50;   7'd88: offsetList = 10'h51;   7'd89: offsetList = 10'h5A;
      7'd90: offsetList = 10'h60;   7'd91: offsetList = 10'h64;   7'd92: offsetList = 10'h6C;   7'd93: offsetList = 10'h78;   7'd94: offsetList = 10'h7D;
      7'd95: offsetList = 10'h80;   7'd96: offsetList = 10'h87;   7'd97: offsetList = 10'h90;   7'd98: offsetList = 10'h96;   7'd99: offsetList = 10'hA0;
      7'd100: offsetList = 10'hA2;  7'd101: offsetList = 10'hB4;  7'd102: offsetList = 10'hC0;  7'd103: offsetList = 10'hC8;  7'd104: offsetList = 10'hD8;
      7'd105: offsetList = 10'hE1;  7'd106: offsetList = 10'hF0;  7'd107: offsetList = 10'hF3;  7'd108: offsetList = 10'hFA;
      default: offsetList = 10'h38B;  // 越界(golden _GEN: 109..127 → offsetList(0)=0x38B)
    endcase
  endfunction

  reg  [9:0] prefetchOffset;
  reg        prefetchDisable;
  reg  [4:0] st [0:108];        // 109 个分数计数器
  reg  [6:0] ptr;
  reg  [5:0] round;
  reg  [9:0] bestOffset;
  reg  [4:0] bestScore;
  reg        state;

  localparam [6:0] PTR_MAX = 7'h6C; // 108

  wire isBad       = bestScore < 5'h2;  // V 版: bestScore∈{0,1} 即 bad(golden isBad=bestScore<2)
  wire testReqFire = state & io_req_valid;
  wire roundOver   = {58'h0, round} > 64'h31;
  wire respHit     = io_test_resp_valid & io_test_resp_bits_hit;

  // 命中条目当前分数(越界回读 st_0, 同 golden LUT), 显式组合 mux 避免动态越界索引。
  reg  [4:0] curScore;
  integer k;
  always @(*) begin
    curScore = st[0];
    for (k = 0; k < 109; k = k + 1)
      if (io_test_resp_bits_ptr == k[6:0])
        curScore = st[k];
  end
  wire [4:0] newScore = 5'(curScore + 5'h1);
  wire       renewOffset = newScore > bestScore;

  integer j;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      prefetchOffset  <= 10'h2;
      prefetchDisable <= 1'h0;
      for (j = 0; j < 109; j = j + 1) st[j] <= 5'h0;
      ptr        <= 7'h0;
      round      <= 6'h0;
      bestOffset <= 10'h2;
      bestScore  <= 5'h0;
      state      <= 1'h0;
    end
    else begin
      if (~state) begin
        prefetchOffset  <= bestOffset;
        prefetchDisable <= isBad;
      end

      for (j = 0; j < 109; j = j + 1) begin
        if (state & respHit & (io_test_resp_bits_ptr == j[6:0]))
          st[j] <= newScore;
        else if (~state)
          st[j] <= 5'h0;
      end

      if (state & testReqFire) begin
        if (ptr == PTR_MAX) begin
          ptr   <= 7'h0;
          round <= 6'(round + 6'h1);
        end
        else
          ptr <= 7'(ptr + 7'h1);
      end
      else if (~state) begin
        ptr   <= 7'h0;
        round <= 6'h0;
      end

      if (state & respHit & renewOffset)
        bestOffset <= offsetList(io_test_resp_bits_ptr);
      if (state & respHit) begin
        if (renewOffset)
          bestScore <= newScore;
      end
      else if (~state)
        bestScore <= 5'h0;

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
// xs_RecentRequestTable_1_core —— 最近请求表(virtual, testOffset 10 位, ptr 7 位)。
//   逻辑与 xs_RecentRequestTable_core 完全一致(复用 xs_SRAMTemplate_135_core),
//   仅 rAddr 减法用 10 位 testOffset 符号扩展, addr 输入 50 位(低 26 位使用)。
// ============================================================================
module xs_RecentRequestTable_1_core(
  input         clock,
  input         reset,
  output        io_w_ready,
  input         io_w_valid,
  input  [49:0] io_w_bits,
  input         io_r_req_valid,
  input  [49:0] io_r_req_bits_addr,
  input  [9:0]  io_r_req_bits_testOffset,
  input  [6:0]  io_r_req_bits_ptr,
  output        io_r_resp_valid,
  output [6:0]  io_r_resp_bits_ptr,
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

  wire [25:0] rAddr = 26'(io_r_req_bits_addr[25:0]
                          - {{10{io_r_req_bits_testOffset[9]}}, io_r_req_bits_testOffset, 6'h0});

  reg        REG;
  reg        s1_valid;
  reg  [6:0] s1_ptr;
  reg  [11:0] s1_hit_REG;
  reg        s2_valid;
  reg  [6:0] io_r_resp_bits_ptr_r;
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
