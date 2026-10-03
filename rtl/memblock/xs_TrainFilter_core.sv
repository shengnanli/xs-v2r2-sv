// =============================================================================
// xs_TrainFilter_core —— L1 预取器训练输入的"去重排序过滤器"参数化核
//
// 位置：L1Prefetcher（stream/stride）与 SMS 的训练入口。3 条 load 流水线每拍各可能
//   送来一条训练记录（ld_in[0..2]），本模块把它们按 robIdx 排成程序序、剔除同一
//   cache 块的重复项，塞进一个 6 项的小 FIFO，再一条一条交给预取器（train_req）。
//
// 流水（三级重排序寄存器，照 Chisel reorder() 对 3 路的递归展开，全部不复位）：
//   A 级 res_0_1：[0],[1] = sort(in0, in1)；[2] = in2
//   B 级 res_1_2：[0] = A[0]；[1],[2] = sort(A[1], A[2])
//   C 级 reordered：[0],[1] = sort(B[0], B[1])；[2] = B[2]
//   每次 sort 只在两路都有效时比较 robIdx（isBefore），后一路更老则交换。
//   firtool 把下游不再使用的字段裁掉了：robIdx 只保留到 B 级的 [0],[1]，C 级没有。
//
// 入队（C 级 → FIFO）：
//   needAlloc[i] = 有效 且 与 FIFO 里任何有效项的块哈希都不同 且 与本拍更早的路也不同；
//   第 i 路的分配指针 = enqPtr[本拍它前面有几路 needAlloc]；
//   canAlloc[i]  = needAlloc[i] 且 分配指针 >= deqPtr（FIFO 未满）且 enable。
//   注意：needAlloc 不看 FIFO 是否有空位，所以"第 0 路因满进不去、第 1 路也进不去"
//   这种情形各路独立判断；三路都 canAlloc 时指针一次前进 3。
// 出队：队头有效且 enable 即 train_req.valid；fire 后清有效位、deqPtr+1。
//
// 块哈希 block_hash_tag(vaddr) = {vaddr[20:16]^vaddr[25:21]^vaddr[30:26], vaddr[15:6]}（15 位）。
//
// 怪癖（照 golden，bug-for-bug）：
//   1. 指针是带翻转位的环形指针（CircularQueuePtr，深 6 不是 2 的幂）：value 加 n 超过 5
//      就减 6 并翻 flag；"分配指针 >= deqPtr" = flagA ^ flagD ^ (valueA >= valueD)。
//   2. 分配指针下标是 2 位（0..2 可达，3 不可达），Chisel Vec 越界读第 0 项；
//      deqPtr.value 是 3 位（深 6 时 6、7 不可达），越界时 train_req.bits 读第 0 项，
//      但 train_req.valid 为 0（逐项 `when(deqPtr === i)` 没有一项命中）。
//      ★FM 实测抓到：第一版写成"valid 也读第 0 项"，signoff 报 5 个 failing（valid 端口 + deqPtr 4 位）★
//   3. io.flush 在本配置下被上层接 0，golden 仍保留 RegNext(flush) 寄存器（恒 0，不复位）
//      及它驱动的清空逻辑：清全部 valid、指针归位。核里原样保留（flush_q）。
//   4. 同一槽同拍被多路写时，路 2 > 路 1 > 路 0（Chisel 后连接者赢）；可达状态下不会发生。
//   5. FIFO 条目与三级重排序寄存器都不复位；valid/指针异步复位。
//
// 载荷参数化：三个变体除 vaddr/robIdx 外各带不同的随行字段 ——
//   TrainFilter   ：pc（50 位）原样进 FIFO，深 6；
//   TrainFilter_1 ：{miss, meta_prefetch[2:0]} 走流水，入 FIFO 时折成 {miss, pfHitStream}
//                   （pfHitStream = meta_prefetch == L1_HW_PREFETCH_STREAM(3)），深 4；
//   SMSTrainFilter：{paddr, pc}（98 位），深 8；没有 enable / train_ready / flush（wrapper 接常量 1/1，
//                   HAS_FLUSH_REG=0 不生成 flush_q）；FIFO 条目异步复位清零（ENTRY_RESET=1）；
//                   Chisel 里 enqLen = 3 load + 2 store = 5 个入队指针，但 store 训练口被上层接 0、
//                   被 firtool 整个裁掉 —— 第 3/4 号指针寄存器仍在、随 allocNum 一起走（ENQ_PTRS=5）。
//   用 PL_IN_W / PL_ENT_W / ENTRY_FOLD_STREAM / ENTRIES / ENQ_PTRS / ENTRY_RESET / HAS_FLUSH_REG 描述。
// =============================================================================

module xs_TrainFilter_core #(
  parameter int unsigned VADDR_W           = 50,
  parameter int unsigned ROB_W             = 8,
  parameter int unsigned ENTRIES           = 6,
  parameter int unsigned PL_IN_W           = 50,   // 流水随行载荷宽度
  parameter int unsigned PL_ENT_W          = 50,   // FIFO 条目载荷宽度
  parameter bit          ENTRY_FOLD_STREAM = 1'b0, // 1：载荷 {miss, meta_prefetch} 折成 {miss, pfHitStream}
  parameter logic [2:0]  STREAM_CODE       = 3'd3, // L1_HW_PREFETCH_STREAM
  parameter int unsigned ENQ_PTRS          = 3,    // 入队指针个数（>= 3；多出的只跟着走）
  parameter bit          ENTRY_RESET       = 1'b0, // 1：FIFO 条目异步复位清零
  parameter bit          HAS_FLUSH_REG     = 1'b1  // 1：生成 RegNext(flush) 寄存器（怪癖 3）
) (
  input  logic                clock,
  input  logic                reset,
  input  logic                enable,
  // 3 路训练输入
  input  logic                in_valid     [3],
  input  logic [VADDR_W-1:0]  in_vaddr     [3],
  input  logic                in_rob_flag  [3],
  input  logic [ROB_W-1:0]    in_rob_value [3],
  input  logic [PL_IN_W-1:0]  in_payload   [3],
  // 过滤后的训练请求
  input  logic                train_ready,
  output logic                train_valid,
  output logic [VADDR_W-1:0]  train_vaddr,
  output logic [PL_ENT_W-1:0] train_payload
);

  localparam int unsigned PTR_W  = $clog2(ENTRIES);
  localparam int unsigned HASH_W = 15;

  function automatic logic [HASH_W-1:0] block_hash_tag(input logic [VADDR_W-1:0] v);
    return {v[20:16] ^ v[25:21] ^ v[30:26], v[15:6]};
  endfunction

  // 两路按 robIdx 排序：两路都有效且路 1 更老时交换
  function automatic logic later_is_older(input logic v0, input logic f0, input logic [ROB_W-1:0] r0,
                                          input logic v1, input logic f1, input logic [ROB_W-1:0] r1);
    return v0 & v1 & (f1 ^ f0 ^ (r1 < r0));
  endfunction

  // ---------------------------------------------------------------------------
  // §1 三级重排序流水（不复位）
  // ---------------------------------------------------------------------------
  logic               a_valid     [3];
  logic [VADDR_W-1:0] a_vaddr     [3];
  logic               a_rob_flag  [3];
  logic [ROB_W-1:0]   a_rob_value [3];
  logic [PL_IN_W-1:0] a_payload   [3];

  logic               b_valid     [3];
  logic [VADDR_W-1:0] b_vaddr     [3];
  logic               b_rob_flag  [2];   // golden 只保留 [0],[1]（[2] 的 robIdx 无人再用）
  logic [ROB_W-1:0]   b_rob_value [2];
  logic [PL_IN_W-1:0] b_payload   [3];

  logic               c_valid     [3];
  logic [VADDR_W-1:0] c_vaddr     [3];
  logic [PL_IN_W-1:0] c_payload   [3];

  logic swap_in;   // in1 比 in0 老
  logic swap_a;    // A[2] 比 A[1] 老
  logic swap_b;    // B[1] 比 B[0] 老

  assign swap_in = later_is_older(in_valid[0], in_rob_flag[0], in_rob_value[0],
                                  in_valid[1], in_rob_flag[1], in_rob_value[1]);
  assign swap_a  = later_is_older(a_valid[1], a_rob_flag[1], a_rob_value[1],
                                  a_valid[2], a_rob_flag[2], a_rob_value[2]);
  assign swap_b  = later_is_older(b_valid[0], b_rob_flag[0], b_rob_value[0],
                                  b_valid[1], b_rob_flag[1], b_rob_value[1]);

  always_ff @(posedge clock) begin
    // A 级
    a_valid[0]     <= swap_in ? in_valid[1]     : in_valid[0];
    a_vaddr[0]     <= swap_in ? in_vaddr[1]     : in_vaddr[0];
    a_rob_flag[0]  <= swap_in ? in_rob_flag[1]  : in_rob_flag[0];
    a_rob_value[0] <= swap_in ? in_rob_value[1] : in_rob_value[0];
    a_payload[0]   <= swap_in ? in_payload[1]   : in_payload[0];
    a_valid[1]     <= swap_in ? in_valid[0]     : in_valid[1];
    a_vaddr[1]     <= swap_in ? in_vaddr[0]     : in_vaddr[1];
    a_rob_flag[1]  <= swap_in ? in_rob_flag[0]  : in_rob_flag[1];
    a_rob_value[1] <= swap_in ? in_rob_value[0] : in_rob_value[1];
    a_payload[1]   <= swap_in ? in_payload[0]   : in_payload[1];
    a_valid[2]     <= in_valid[2];
    a_vaddr[2]     <= in_vaddr[2];
    a_rob_flag[2]  <= in_rob_flag[2];
    a_rob_value[2] <= in_rob_value[2];
    a_payload[2]   <= in_payload[2];
    // B 级
    b_valid[0]     <= a_valid[0];
    b_vaddr[0]     <= a_vaddr[0];
    b_rob_flag[0]  <= a_rob_flag[0];
    b_rob_value[0] <= a_rob_value[0];
    b_payload[0]   <= a_payload[0];
    b_valid[1]     <= swap_a ? a_valid[2]     : a_valid[1];
    b_vaddr[1]     <= swap_a ? a_vaddr[2]     : a_vaddr[1];
    b_rob_flag[1]  <= swap_a ? a_rob_flag[2]  : a_rob_flag[1];
    b_rob_value[1] <= swap_a ? a_rob_value[2] : a_rob_value[1];
    b_payload[1]   <= swap_a ? a_payload[2]   : a_payload[1];
    b_valid[2]     <= swap_a ? a_valid[1]     : a_valid[2];
    b_vaddr[2]     <= swap_a ? a_vaddr[1]     : a_vaddr[2];
    b_payload[2]   <= swap_a ? a_payload[1]   : a_payload[2];
    // C 级
    c_valid[0]     <= swap_b ? b_valid[1]   : b_valid[0];
    c_vaddr[0]     <= swap_b ? b_vaddr[1]   : b_vaddr[0];
    c_payload[0]   <= swap_b ? b_payload[1] : b_payload[0];
    c_valid[1]     <= swap_b ? b_valid[0]   : b_valid[1];
    c_vaddr[1]     <= swap_b ? b_vaddr[0]   : b_vaddr[1];
    c_payload[1]   <= swap_b ? b_payload[0] : b_payload[1];
    c_valid[2]     <= b_valid[2];
    c_vaddr[2]     <= b_vaddr[2];
    c_payload[2]   <= b_payload[2];
  end

  // FIFO 条目载荷（变体 1 在此折叠 pfHitStream）
  logic [PL_ENT_W-1:0] c_ent_payload [3];
  for (genvar i = 0; i < 3; i++) begin : g_fold
    if (ENTRY_FOLD_STREAM) begin : g_stream
      assign c_ent_payload[i] = {c_payload[i][3], c_payload[i][2:0] == STREAM_CODE};
    end else begin : g_plain
      assign c_ent_payload[i] = c_payload[i];
    end
  end

  // ---------------------------------------------------------------------------
  // §2 FIFO 状态
  // ---------------------------------------------------------------------------
  logic [VADDR_W-1:0]  ent_vaddr   [ENTRIES];   // 不复位
  logic [PL_ENT_W-1:0] ent_payload [ENTRIES];   // 不复位
  logic                ent_valid   [ENTRIES];
  logic                enq_flag    [ENQ_PTRS];
  logic [PTR_W-1:0]    enq_value   [ENQ_PTRS];
  logic                deq_flag;
  logic [PTR_W-1:0]    deq_value;
  logic                flush_q;                 // RegNext(io.flush)，flush 恒 0（怪癖 3）

  // ---------------------------------------------------------------------------
  // §3 入队判定
  // ---------------------------------------------------------------------------
  logic [HASH_W-1:0] c_hash   [3];
  logic [HASH_W-1:0] ent_hash [ENTRIES];
  logic              hit_entry [3];   // 与 FIFO 里某有效项同块
  logic              hit_prev  [3];   // 与本拍更早的路同块
  logic              need_alloc [3];
  logic              can_alloc  [3];
  logic [1:0]        alloc_idx  [3];  // 本路前面有几路 needAlloc
  logic              alloc_flag  [3];
  logic [PTR_W-1:0]  alloc_value [3];
  logic [1:0]        alloc_num;
  logic              any_alloc;

  for (genvar i = 0; i < 3; i++) begin : g_hash_c
    assign c_hash[i] = block_hash_tag(c_vaddr[i]);
  end
  for (genvar e = 0; e < ENTRIES; e++) begin : g_hash_e
    assign ent_hash[e] = block_hash_tag(ent_vaddr[e]);
  end

  always_comb begin
    for (int i = 0; i < 3; i++) begin
      hit_entry[i] = 1'b0;
      for (int e = 0; e < ENTRIES; e++)
        if (ent_valid[e] && ent_hash[e] == c_hash[i]) hit_entry[i] = 1'b1;
      hit_prev[i] = 1'b0;
      for (int j = 0; j < i; j++)
        if (c_valid[j] && c_hash[j] == c_hash[i]) hit_prev[i] = 1'b1;
      need_alloc[i] = c_valid[i] & ~hit_entry[i] & ~hit_prev[i];
    end
    alloc_idx[0] = 2'd0;
    alloc_idx[1] = 2'(need_alloc[0]);
    alloc_idx[2] = 2'(need_alloc[0]) + 2'(need_alloc[1]);
    for (int i = 0; i < 3; i++) begin
      // 下标 2 位：3 个指针时下标 3 越界读第 0 项（怪癖 2）；5 个指针时 3 号指针真实存在
      alloc_flag[i]  = enq_flag[0];
      alloc_value[i] = enq_value[0];
      for (int k = 1; k < (ENQ_PTRS < 4 ? ENQ_PTRS : 4); k++)
        if (alloc_idx[i] == 2'(k)) begin
          alloc_flag[i]  = enq_flag[k];
          alloc_value[i] = enq_value[k];
        end
      can_alloc[i] = need_alloc[i] & (alloc_flag[i] ^ deq_flag ^ (alloc_value[i] >= deq_value)) & enable;
    end
    alloc_num = 2'(can_alloc[0]) + 2'(can_alloc[1]) + 2'(can_alloc[2]);
    any_alloc = can_alloc[0] | can_alloc[1] | can_alloc[2];
  end

  // ---------------------------------------------------------------------------
  // §4 出队
  // ---------------------------------------------------------------------------
  logic                deq_valid_sel;
  logic [VADDR_W-1:0]  deq_vaddr_sel;
  logic [PL_ENT_W-1:0] deq_payload_sel;
  logic                deq_fire;

  always_comb begin
    // deqPtr.value 越界（深 6 时的 6、7）：bits 读第 0 项（Vec 越界语义），但 valid 为 0 ——
    // Chisel 的 `when(deqPtr === i.U)` 对每个 i 都是真比较，没有一项等于越界值（怪癖 2）
    deq_valid_sel   = 1'b0;
    deq_vaddr_sel   = ent_vaddr[0];
    deq_payload_sel = ent_payload[0];
    for (int e = 0; e < ENTRIES; e++)
      if (deq_value == PTR_W'(e)) begin
        deq_valid_sel   = ent_valid[e];
        deq_vaddr_sel   = ent_vaddr[e];
        deq_payload_sel = ent_payload[e];
      end
  end

  assign train_valid   = deq_valid_sel & enable;
  assign train_vaddr   = deq_vaddr_sel;
  assign train_payload = deq_payload_sel;
  assign deq_fire      = train_ready & train_valid;

  // ---------------------------------------------------------------------------
  // §5 条目写入与有效位
  // ---------------------------------------------------------------------------
  for (genvar e = 0; e < ENTRIES; e++) begin : g_entry
    logic wr [3];
    for (genvar i = 0; i < 3; i++) begin : g_wr
      assign wr[i] = can_alloc[i] & (alloc_value[i] == PTR_W'(e));
    end
    // 路 2 > 路 1 > 路 0（怪癖 4）
    if (ENTRY_RESET) begin : g_ent_rst
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          ent_vaddr[e]   <= '0;
          ent_payload[e] <= '0;
        end else if (wr[2]) begin
          ent_vaddr[e]   <= c_vaddr[2];
          ent_payload[e] <= c_ent_payload[2];
        end else if (wr[1]) begin
          ent_vaddr[e]   <= c_vaddr[1];
          ent_payload[e] <= c_ent_payload[1];
        end else if (wr[0]) begin
          ent_vaddr[e]   <= c_vaddr[0];
          ent_payload[e] <= c_ent_payload[0];
        end
      end
    end else begin : g_ent_norst
      always_ff @(posedge clock) begin
        if (wr[2]) begin
          ent_vaddr[e]   <= c_vaddr[2];
          ent_payload[e] <= c_ent_payload[2];
        end else if (wr[1]) begin
          ent_vaddr[e]   <= c_vaddr[1];
          ent_payload[e] <= c_ent_payload[1];
        end else if (wr[0]) begin
          ent_vaddr[e]   <= c_vaddr[0];
          ent_payload[e] <= c_ent_payload[0];
        end
      end
    end
    always_ff @(posedge clock or posedge reset) begin
      if (reset) ent_valid[e] <= 1'b0;
      else       ent_valid[e] <= ~(flush_q | (deq_fire & (deq_value == PTR_W'(e))))
                                 & (wr[2] | wr[1] | wr[0] | ent_valid[e]);
    end
  end

  // ---------------------------------------------------------------------------
  // §6 环形指针（深 6：加法后 >= 6 则减 6 并翻 flag）
  // ---------------------------------------------------------------------------
  function automatic logic [PTR_W:0] ptr_add(input logic [PTR_W-1:0] v, input logic [1:0] n);
    logic [PTR_W:0] sum;
    sum = (PTR_W+1)'(v) + (PTR_W+1)'(n);
    return sum;
  endfunction

  if (HAS_FLUSH_REG) begin : g_flush
    always_ff @(posedge clock) flush_q <= 1'b0;
  end else begin : g_noflush
    assign flush_q = 1'b0;
  end

  for (genvar i = 0; i < ENQ_PTRS; i++) begin : g_enqptr
    logic [PTR_W:0] sum;
    logic           wrap;
    assign sum  = ptr_add(enq_value[i], alloc_num);
    assign wrap = (sum >= (PTR_W+1)'(ENTRIES));
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        enq_flag[i]  <= 1'b0;
        enq_value[i] <= PTR_W'(i);
      end else if (flush_q) begin
        enq_flag[i]  <= 1'b0;
        enq_value[i] <= PTR_W'(i);
      end else if (any_alloc) begin
        enq_flag[i]  <= enq_flag[i] ^ wrap;
        enq_value[i] <= wrap ? PTR_W'(sum - (PTR_W+1)'(ENTRIES)) : PTR_W'(sum);
      end
    end
  end

  logic [PTR_W:0] deq_sum;
  logic           deq_wrap;
  assign deq_sum  = ptr_add(deq_value, 2'd1);
  assign deq_wrap = (deq_sum >= (PTR_W+1)'(ENTRIES));
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      deq_flag  <= 1'b0;
      deq_value <= '0;
    end else if (flush_q) begin
      deq_flag  <= 1'b0;
      deq_value <= '0;
    end else if (deq_fire) begin
      deq_flag  <= deq_flag ^ deq_wrap;
      deq_value <= deq_wrap ? PTR_W'(deq_sum - (PTR_W+1)'(ENTRIES)) : PTR_W'(deq_sum);
    end
  end

endmodule
