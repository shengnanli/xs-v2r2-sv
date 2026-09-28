// xs_MultiWakeupQueue_core.sv —— 发射队列的"推测唤醒"延迟队列：多条定长流水汇合 + 末级寄存
// =============================================================================
// 对应 Chisel: xiangshan.backend.issue.MultiWakeupQueue
//   (src/main/scala/xiangshan/backend/issue/MultiWakeupQueue.scala)，
//   flushFunc / modificationFunc / lastConnectFunc 定义在 IssueQueue.scala（IssueQueueImp）。
//
// 位置：IssueQueue* 里，每个"会向别的 IQ 发推测唤醒、且不是 load"的执行单元一个。
//   指令从本 IQ 发射时，把它的目的寄存器（pdest / 写使能 / loadDependency）按该指令
//   功能单元的**唤醒延迟** lat 送进对应的一条 PipeWithFlush 流水（lat=0 的那条是纯组合
//   直通，lat=k 的那条有 k 级寄存器）。lat 拍后从流水出来的，就是"现在可以唤醒消费者了"。
//   各流水出口汇合成一路，再打一拍（lastConnect）送出 io_deq —— 这就是 wakeupToIQ。
//
// 本核只做 golden 模块体里"流水之外"的那部分：
//   §1 出口冲刷：lat>0 的流水出口再判一次冲刷（Chisel 的 flushFunc(deq.bits, flush, lat)）：
//        redirect 冲刷：robIdx.needFlush(redirect)
//                     = valid & (level & robIdx==redirect.robIdx | isAfter(robIdx, redirect.robIdx))
//        load 取消    ：OR_k (ld2Cancel[k] & loadDependency[k][1])
//        OG 失败      ：lat==1 → og0Fail；lat==2 → og1Fail；其余 lat 无
//      lat==0 的流水直通，不判冲刷（Chisel 的 `case (deq, 0) => deq.valid`）。
//      ★load 取消只剩 ld2Cancel 一项★：LoadShouldCancel 原式还有 ld1Cancel & dep[0]，
//        但 PipeWithFlush 每前进一级把 loadDependency 左移一位，lat≥1 的出口 dep[0] 恒 0，
//        firtool 跨模块常量传播把那一项连同 ld1Cancel 端口一起删了 —— golden 只有 ld2Cancel。
//   §2 出口改写：lat>0 的出口 loadDependency 每路再左移一位（modificationFunc），
//        位宽不变、高位丢掉（golden：{dep[0], 1'b0}）。
//   §3 汇合：Mux1H(pipesValidVec, pipesBitsVec)。golden 展平成按位或
//        `(v0 ? b0 : 0) | (v1 ? b1 : 0) | ...` —— **不是**优先级选择；合法情形下至多
//        一路有效（Chisel 有 PopCount<=1 断言，golden 在 `ifndef SYNTHESIS 里，签核
//        口径不含它），非法时多路按位或。
//        ★单流水特例★：Chisel 的 Mux1H 只有一个输入时直接返回该输入、**不看 valid**，
//        所以 N_PIPES==1 时载荷不被 valid 清零（MultiWakeupQueue_2 的 golden 就是
//        `lastConnect_bits_pdest <= _pipes_0_io_deq_bits_pdest`）。
//        写使能位（WEN_MASK 标出的 rfWen/fpWen/vecWen/v0Wen）另由 Chisel 显式重算为
//        OR_i(valid_i && wen_i)，无论几条流水都被 valid 门控。
//   §4 末级寄存 lastConnect：valid + 载荷，**不复位**（Chisel `Reg(Valid(...))`）。
//        lastConnectFunc 另把 pdest / 写使能 / loadDependency 复制 COPY_NUM 份
//        （pdestCopy / rfWenCopy / loadDependencyCopy，给多个消费 IQ 各一份扇出），
//        每份都是独立寄存器 —— 照 golden 一份不少。
//
// 载荷布局（wrapper 拼包、核不关心字段语义，只认两块区域）：
//   deq_bits[W-1:0]，低位起：loadDependency 第 0..LD_CNT-1 路（每路 LD_W 位，
//   第 k 路在 [k*LD_W +: LD_W]），再往上是其余字段；复制件 = 载荷最低 COPY_W 位。
//
// 家族（参数由各 wrapper 从 G1 golden 量出；PIPE_LAT 按 golden 实例 pipes_0.. 顺序）：
//   模块               流水 lat     W    LD_CNT  COPY_NUM×COPY_W   载荷字段（高→低）
//   MultiWakeupQueue    {0,2}      50     3       6 × 15          fuType,pdest,rfWen,ld×3
//   MultiWakeupQueue_2  {0}        15     3       6 × 15          pdest,rfWen,ld×3
//   MultiWakeupQueue_4  {1,2,0,3}  46     0       0               fuType,pdest,fpWen,vecWen,v0Wen
//   MultiWakeupQueue_5  {1,3}       9     0       0               pdest,fpWen
// =============================================================================
module xs_MultiWakeupQueue_core #(
  parameter int N_PIPES              = 2,
  parameter int PIPE_LAT [N_PIPES]   = '{0, 2},  // 第 i 条流水的唤醒延迟（= golden pipes_i）
  parameter int W                    = 50,       // 汇合后载荷位宽（= golden lastConnect 非复制字段）
  parameter int LD_CNT               = 3,        // loadDependency 路数（0 = 无）
  parameter int LD_W                 = 2,        // 每路位宽
  parameter int COPY_NUM             = 6,        // 复制份数（0 = 无）
  parameter int COPY_W               = 15,       // 每份位宽 = 载荷最低 COPY_W 位
  parameter logic [W-1:0] WEN_MASK   = '0,       // 载荷里哪些位是写使能（恒被 valid 门控）
  // 零长度数组在 SV 里不合法：数量为 0 时数组留 1 个占位元素，永不被读
  localparam int LD_SLOTS   = (LD_CNT   > 0) ? LD_CNT   : 1,
  localparam int COPY_SLOTS = (COPY_NUM > 0) ? COPY_NUM : 1
) (
  input  logic                clock,
  // flush（WakeupQueueFlush）
  input  logic                flush_redirect_valid,
  input  logic                flush_redirect_level,    // 1 = 冲刷含自身（flushItself）
  input  logic [8:0]          flush_redirect_robidx,   // {flag, value}
  input  logic [LD_SLOTS-1:0] flush_ld2cancel,
  input  logic                flush_og0fail,
  input  logic                flush_og1fail,
  // 各流水出口（lat=0 的流水没有 robIdx 出口，接 0 即可，本核不读）
  input  logic                pipe_valid  [N_PIPES],
  input  logic [8:0]          pipe_robidx [N_PIPES],
  input  logic [W-1:0]        pipe_bits   [N_PIPES],
  // 末级输出
  output logic                deq_valid,
  output logic [W-1:0]        deq_bits,
  output logic [COPY_W-1:0]   deq_copy [COPY_SLOTS]
);

  // ---------------------------------------------------------------------------
  // §1 出口冲刷 → pipesValidVec
  // ---------------------------------------------------------------------------
  // robIdx 是 {flag, value} 环形指针：flag 不同表示绕了一圈，isAfter 按 flag^flag'^(v>v') 判。
  function automatic logic rob_need_flush(input logic [8:0] rob, input logic valid,
                                          input logic level, input logic [8:0] redirect_rob);
    logic flush_itself, is_after;
    flush_itself = level & (rob == redirect_rob);
    is_after     = rob[8] ^ redirect_rob[8] ^ (rob[7:0] > redirect_rob[7:0]);
    return valid & (flush_itself | is_after);
  endfunction

  logic pipes_valid_vec [N_PIPES];

  always_comb
    for (int i = 0; i < N_PIPES; i++) begin
      logic redirect_flush, ld_flush, og_flush;
      redirect_flush = rob_need_flush(pipe_robidx[i], flush_redirect_valid,
                                      flush_redirect_level, flush_redirect_robidx);
      ld_flush = 1'b0;
      for (int k = 0; k < LD_CNT; k++)
        ld_flush |= flush_ld2cancel[k] & pipe_bits[i][k*LD_W + 1];
      og_flush = (PIPE_LAT[i] == 1) ? flush_og0fail :
                 (PIPE_LAT[i] == 2) ? flush_og1fail : 1'b0;

      if (PIPE_LAT[i] == 0) pipes_valid_vec[i] = pipe_valid[i];
      else                  pipes_valid_vec[i] = pipe_valid[i] & ~(redirect_flush | ld_flush | og_flush);
    end

  // ---------------------------------------------------------------------------
  // §2 出口改写 → pipesBitsVec：lat>0 的出口 loadDependency 每路左移一位
  // ---------------------------------------------------------------------------
  logic [W-1:0] pipes_bits_vec [N_PIPES];

  always_comb
    for (int i = 0; i < N_PIPES; i++) begin
      pipes_bits_vec[i] = pipe_bits[i];
      if (PIPE_LAT[i] != 0)
        for (int k = 0; k < LD_CNT; k++)
          pipes_bits_vec[i][k*LD_W +: LD_W] = pipe_bits[i][k*LD_W +: LD_W] << 1;
    end

  // ---------------------------------------------------------------------------
  // §3 汇合：Mux1H = 按位或（非优先级）
  // ---------------------------------------------------------------------------
  logic         pipes_out_valid;
  logic [W-1:0] pipes_out_bits;

  logic [W-1:0] mux1h_bits;   // Mux1H(pipesValidVec, pipesBitsVec)
  logic [W-1:0] wen_bits;     // 写使能位：OR_i(valid_i && wen_i)

  always_comb begin
    pipes_out_valid = 1'b0;
    mux1h_bits      = '0;
    wen_bits        = '0;
    for (int i = 0; i < N_PIPES; i++) begin
      pipes_out_valid |= pipes_valid_vec[i];
      mux1h_bits      |= pipes_valid_vec[i] ? pipes_bits_vec[i] : '0;
      wen_bits        |= pipes_valid_vec[i] ? (pipes_bits_vec[i] & WEN_MASK) : '0;
    end
    if (N_PIPES == 1)
      mux1h_bits = pipes_bits_vec[0];   // 单输入 Mux1H 直通，不看 valid
    pipes_out_bits = (mux1h_bits & ~WEN_MASK) | wen_bits;
  end

  // ---------------------------------------------------------------------------
  // §4 末级寄存 lastConnect（不复位）+ 复制件
  // ---------------------------------------------------------------------------
  logic              last_valid;
  logic [W-1:0]      last_bits;
  logic [COPY_W-1:0] last_copy [COPY_SLOTS];

  always_ff @(posedge clock) begin
    last_valid <= pipes_out_valid;
    last_bits  <= pipes_out_bits;
  end

  if (COPY_NUM > 0) begin : g_copy
    for (genvar c = 0; c < COPY_NUM; c++) begin : g_c
      always_ff @(posedge clock)
        last_copy[c] <= pipes_out_bits[COPY_W-1:0];
    end
  end else begin : g_no_copy
    assign last_copy[0] = '0;   // 占位，wrapper 不接
  end

  assign deq_valid = last_valid;
  assign deq_bits  = last_bits;
  assign deq_copy  = last_copy;

endmodule
