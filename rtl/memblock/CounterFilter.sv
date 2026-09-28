// =============================================================================
// CounterFilter —— "有用预取"计数去重 FIFO（DCache，FDP 预取统计的前置过滤）
//
// 对应 Chisel：xiangshan.mem.prefetch.CounterFilter（src/main/scala/xiangshan/mem/prefetch/FDP.scala）
//
// 【为什么需要它】
//   LoadPipe 在 s3 发现"这次 load 命中了一条预取进来的行"时，会给"有用预取"计数 +1，
//   并在下一拍把该行的预取标记清掉（写 PrefetchArray）。可 LoadPipe 没有 set 阻塞：
//   若 3 条 load 同时在 s0..s3 访问同一行，它们都会看到"预取命中"，计数被重复加 3 次。
//   解决：load 到 s3 时把它的 (set, way) 记进本 FIFO；每条 load 在判"预取命中"前先来
//   查一下（io.query），FIFO 里已有同一 (set, way) 就说明前面有人算过了，不再重复计数。
//
// 【结构】SIZE = (LduStages 4 + 1) × LduCnt 3 = 15 项循环队列，每项 {idx(set), way} + valid。
//   入队：3 个 load 口（io.ld_in）同拍最多进 3 项，按口序占用连续的 3 个入队指针
//     （第 i 口用 enqPtrExt[前面 valid 口的个数]）；同一项被多口写时口号大的赢。
//     canAlloc = 请求 valid 且 分配指针 >= 出队指针（循环指针比较：flag 不同则反号）。
//   出队：一项入队后恰好停留 4 拍（覆盖 s0..s3 + 预取标记写回那拍）。实现方式是把每拍的
//     入队个数 allocNum 打 4 拍（RegNext×3 再进 last3CycleAlloc），4 拍后按这个数
//     从出队指针处连续清 valid，出队指针同步前进。
//   查询：3 个 query 口各自与 15 项全相联比较 (idx, way)，命中且 query valid → resp=1。
//
// 【指针】CircularQueuePtr(15)：{flag, value[3:0]}，加 n 时 value+n >= 15 则减 15 并翻 flag。
//   golden 里 deqPtrExt[1]/[2] 的 flag 没人读，被 firtool 删了（value 仍在，用于清 valid）；
//   这里同样只保留它们的 value。
//
// 复位：entries/valids/指针/last3CycleAlloc 异步复位（RegInit）；
//   allocNum 的三级 RegNext 不复位，照搬 golden。
// =============================================================================

module CounterFilter(
  input        clock,
  input        reset,
  input        io_ld_in_0_valid,
  input  [7:0] io_ld_in_0_bits_idx,
  input  [1:0] io_ld_in_0_bits_way,
  input        io_ld_in_1_valid,
  input  [7:0] io_ld_in_1_bits_idx,
  input  [1:0] io_ld_in_1_bits_way,
  input        io_ld_in_2_valid,
  input  [7:0] io_ld_in_2_bits_idx,
  input  [1:0] io_ld_in_2_bits_way,
  input        io_query_0_req_valid,
  input  [7:0] io_query_0_req_bits_idx,
  input  [1:0] io_query_0_req_bits_way,
  output       io_query_0_resp,
  input        io_query_1_req_valid,
  input  [7:0] io_query_1_req_bits_idx,
  input  [1:0] io_query_1_req_bits_way,
  output       io_query_1_resp,
  input        io_query_2_req_valid,
  input  [7:0] io_query_2_req_bits_idx,
  input  [1:0] io_query_2_req_bits_way,
  output       io_query_2_resp
);

  localparam int N_PORTS = 3;    // LduCnt：入队口数 = 查询口数 = 出队宽度
  localparam int SIZE    = 15;   // (4 + 1) * 3

  typedef struct packed {
    logic [7:0] idx;   // DCache set 下标
    logic [1:0] way;   // 命中的路
  } filter_entry_t;

  typedef struct packed {
    logic       flag;
    logic [3:0] value;
  } ptr_t;

  // 循环指针加 n（n <= 3）：越过 SIZE 则回绕并翻 flag
  function automatic ptr_t ptr_add(input ptr_t p, input logic [1:0] n);
    logic [4:0] sum;
    sum = {1'b0, p.value} + {3'b0, n};
    if (sum >= 5'(SIZE)) ptr_add = '{flag: ~p.flag, value: 4'(sum - 5'(SIZE))};
    else                 ptr_add = '{flag: p.flag,  value: sum[3:0]};
  endfunction

  // 只要 value 的版本（出队指针 1/2 没有 flag）
  function automatic logic [3:0] ptr_value_add(input logic [3:0] v, input logic [1:0] n);
    logic [4:0] sum;
    sum = {1'b0, v} + {3'b0, n};
    ptr_value_add = (sum >= 5'(SIZE)) ? 4'(sum - 5'(SIZE)) : sum[3:0];
  endfunction

  // 循环指针 a >= b：flag 相同比 value；flag 不同则结论取反
  function automatic logic ptr_ge(input ptr_t a, input ptr_t b);
    ptr_ge = (a.flag ^ b.flag) ^ (a.value >= b.value);
  endfunction

  // ---- 端口打包 ----
  logic          ld_valid [N_PORTS];
  filter_entry_t ld_req   [N_PORTS];
  logic          q_valid  [N_PORTS];
  filter_entry_t q_req    [N_PORTS];
  logic          q_resp   [N_PORTS];
  assign ld_valid = '{io_ld_in_0_valid, io_ld_in_1_valid, io_ld_in_2_valid};
  assign ld_req   = '{'{io_ld_in_0_bits_idx, io_ld_in_0_bits_way},
                      '{io_ld_in_1_bits_idx, io_ld_in_1_bits_way},
                      '{io_ld_in_2_bits_idx, io_ld_in_2_bits_way}};
  assign q_valid  = '{io_query_0_req_valid, io_query_1_req_valid, io_query_2_req_valid};
  assign q_req    = '{'{io_query_0_req_bits_idx, io_query_0_req_bits_way},
                      '{io_query_1_req_bits_idx, io_query_1_req_bits_way},
                      '{io_query_2_req_bits_idx, io_query_2_req_bits_way}};
  assign io_query_0_resp = q_resp[0];
  assign io_query_1_resp = q_resp[1];
  assign io_query_2_resp = q_resp[2];

  // ---- 状态 ----
  filter_entry_t entries [SIZE];
  logic          valids  [SIZE];
  ptr_t          enq_ptr [N_PORTS];
  ptr_t          deq_ptr_0;                 // 出队指针 0（完整 flag+value，用于满判）
  logic [3:0]    deq_ptr_1_value;           // 出队指针 1/2：flag 无人读（golden 已删），只剩 value
  logic [3:0]    deq_ptr_2_value;
  logic [3:0]    deq_ptr_value [N_PORTS];
  assign deq_ptr_value = '{deq_ptr_0.value, deq_ptr_1_value, deq_ptr_2_value};
  logic [1:0]    alloc_num_d1, alloc_num_d2, alloc_num_d3;   // allocNum 的 RegNext 链（不复位）
  logic [1:0]    last3CycleAlloc;           // 4 拍前的入队个数 = 本拍要出队的个数

  // ===========================================================================
  //  §1 入队：第 i 口用第 (前面 valid 口数) 个入队指针
  // ===========================================================================
  logic [1:0] alloc_slot [N_PORTS];   // 该口用的入队指针下标
  ptr_t       alloc_ptr  [N_PORTS];
  logic       can_alloc  [N_PORTS];
  always_comb begin
    alloc_slot[0] = 2'd0;
    alloc_slot[1] = {1'b0, ld_valid[0]};
    alloc_slot[2] = 2'({1'b0, ld_valid[0]} + {1'b0, ld_valid[1]});
    for (int i = 0; i < N_PORTS; i++) begin
      alloc_ptr[i] = enq_ptr[0];
      for (int k = 0; k < N_PORTS; k++)
        if (alloc_slot[i] == 2'(k)) alloc_ptr[i] = enq_ptr[k];
      can_alloc[i] = ld_valid[i] & ptr_ge(alloc_ptr[i], deq_ptr_0);
    end
  end

  wire       any_alloc = can_alloc[0] | can_alloc[1] | can_alloc[2];
  wire [1:0] alloc_num = 2'({1'b0, can_alloc[0]} + {1'b0, can_alloc[1]} + {1'b0, can_alloc[2]});

  // ===========================================================================
  //  §2 出队：4 拍前进了几项，本拍就从出队指针起清掉几项
  // ===========================================================================
  logic deq_clear [N_PORTS];   // 第 i 个出队位置本拍要清
  always_comb
    for (int i = 0; i < N_PORTS; i++)
      deq_clear[i] = 2'(i) < last3CycleAlloc;

  // ===========================================================================
  //  §3 查询：全相联比较
  // ===========================================================================
  always_comb
    for (int i = 0; i < N_PORTS; i++) begin
      q_resp[i] = 1'b0;
      for (int e = 0; e < SIZE; e++)
        if (valids[e] && entries[e] == q_req[i]) q_resp[i] = q_valid[i];
    end

  // ===========================================================================
  //  §4 状态更新
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int e = 0; e < SIZE; e++) begin
        entries[e] <= '0;
        valids[e]  <= 1'b0;
      end
      for (int i = 0; i < N_PORTS; i++)
        enq_ptr[i] <= '{flag: 1'b0, value: 4'(i)};
      deq_ptr_0       <= '0;
      deq_ptr_1_value <= 4'd1;
      deq_ptr_2_value <= 4'd2;
      last3CycleAlloc <= 2'd0;
    end
    else begin
      // 按项扫描（下标是循环变量，见 CONVENTIONS ELAB-147：15 项、4 位指针）
      for (int e = 0; e < SIZE; e++) begin
        // 入队写项：口序从小到大写，口号大的覆盖
        for (int i = 0; i < N_PORTS; i++)
          if (can_alloc[i] && alloc_ptr[i].value == 4'(e)) begin
            valids[e]  <= 1'b1;
            entries[e] <= ld_req[i];
          end
        // 出队清 valid（写在入队之后：同一项同拍又进又出时以清为准）
        for (int i = 0; i < N_PORTS; i++)
          if (deq_clear[i] && deq_ptr_value[i] == 4'(e)) valids[e] <= 1'b0;
      end

      if (any_alloc)
        for (int i = 0; i < N_PORTS; i++)
          enq_ptr[i] <= ptr_add(enq_ptr[i], alloc_num);

      // 出队指针每拍都前进 last3CycleAlloc（0 也算"前进"）
      deq_ptr_0       <= ptr_add(deq_ptr_0, last3CycleAlloc);
      deq_ptr_1_value <= ptr_value_add(deq_ptr_1_value, last3CycleAlloc);
      deq_ptr_2_value <= ptr_value_add(deq_ptr_2_value, last3CycleAlloc);

      last3CycleAlloc <= alloc_num_d3;
    end
  end

  always_ff @(posedge clock) begin
    alloc_num_d1 <= alloc_num;
    alloc_num_d2 <= alloc_num_d1;
    alloc_num_d3 <= alloc_num_d2;
  end

endmodule
