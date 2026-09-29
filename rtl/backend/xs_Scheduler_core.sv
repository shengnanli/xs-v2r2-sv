// xs_Scheduler_core.sv —— 调度器（Scheduler*）自身的少量逻辑（家族共享参数化核）
// =============================================================================
// 对应 Chisel: xiangshan.backend.issue.SchedulerImpBase 及 SchedulerMemImp
//   (src/main/scala/xiangshan/backend/issue/Scheduler.scala)
//
// 位置：后端每类执行单元（整数 / 浮点 / 向量 / 访存）一个调度器，里面是若干个 IssueQueue*。
//   调度器本身几乎全是连线：把 Dispatch 的 uop、各路唤醒、取消、写回忙表等信号分发给
//   各 IQ，再把各 IQ 的出队口汇到 DataPath。那部分由 wrapper（scripts/gen_sched.py 机械生成）
//   负责；本核只写 golden 模块体里真正有逻辑的三件事：
//
//   §1 性能事件（generatePerfEvent）：
//        lastCycleIqEnqFireVec(k) = RegNext(第 k 个 IQ 入队口的 fire = ready && valid)
//        lastCycleIqFullVec(q)    = RegNext(第 q 个 IQ 的 enq(0).ready)
//          ★名字叫 "Full"，采的却是 ready（Chisel 原样如此，bug-for-bug 照抄）★
//        perf(0) = PopCount(lastCycleIqEnqFireVec)，perf(1+q) = lastCycleIqFullVec(q)，
//        每个事件值再打两拍送出（generatePerfEvent 的 RegNext(RegNext(...))）。
//        以上寄存器全部不复位。
//   §2 访存调度器的 sta/std 成对派遣（SchedulerMemImp）：store 指令被拆成地址（sta）与数据
//        （std）两份送进两个 IQ，同一个 Dispatch 口：
//          dispatch.ready = staIQ.enq.ready && stdIQ.enq.ready
//          staIQ.enq.valid = dispatch.valid && !isDropAmocasSta   （amocas 的 sta 半拍被丢弃）
// =============================================================================
module xs_Scheduler_core #(
  parameter int N_ENQ   = 8,    // 全部 IQ 入队口数（= lastCycleIqEnqFireVec 长度）
  parameter int N_IQ    = 4,    // IQ 个数（= lastCycleIqFullVec 长度）
  parameter int PERF0_W = 4,    // perf(0) 的位宽（PopCount 结果）
  parameter int N_STA   = 0,    // sta/std 成对派遣口数（非访存调度器为 0）
  localparam int STA_SLOTS = (N_STA > 0) ? N_STA : 1
) (
  input  logic               clock,
  // §1 性能事件
  input  logic               enq_ready     [N_ENQ],   // 第 k 个 IQ 入队口的 ready
  input  logic               enq_valid     [N_ENQ],   // 第 k 个 IQ 入队口实际收到的 valid
  input  logic               iq_enq0_ready [N_IQ],    // 第 q 个 IQ 的 enq(0).ready
  output logic [PERF0_W-1:0] perf_enq_fire_cnt,       // perf(0)：上一拍入队 fire 的个数（再延两拍）
  output logic               perf_iq_full  [N_IQ],    // perf(1+q)
  // §2 sta/std 成对派遣
  input  logic               sta_dispatch_valid [STA_SLOTS],
  input  logic               sta_drop_amocas    [STA_SLOTS],
  input  logic               sta_iq_ready       [STA_SLOTS],
  input  logic               std_iq_ready       [STA_SLOTS],
  output logic               sta_enq_valid      [STA_SLOTS],
  output logic               dispatch_ready     [STA_SLOTS]
);

  // ===========================================================================
  // §1 性能事件：采样一拍，计数/透传后再打两拍
  // ===========================================================================
  logic               enq_fire_q [N_ENQ];   // lastCycleIqEnqFireVec
  logic               iq_full_q  [N_IQ];    // lastCycleIqFullVec
  logic [PERF0_W-1:0] fire_cnt_q1, fire_cnt_q2;
  logic               full_q1 [N_IQ];
  logic               full_q2 [N_IQ];
  logic [PERF0_W-1:0] fire_cnt;

  always_comb begin
    fire_cnt = '0;
    for (int k = 0; k < N_ENQ; k++)
      fire_cnt += PERF0_W'(enq_fire_q[k]);
  end

  always_ff @(posedge clock) begin
    for (int k = 0; k < N_ENQ; k++)
      enq_fire_q[k] <= enq_ready[k] & enq_valid[k];
    for (int q = 0; q < N_IQ; q++) begin
      iq_full_q[q] <= iq_enq0_ready[q];
      full_q1[q]   <= iq_full_q[q];
      full_q2[q]   <= full_q1[q];
    end
    fire_cnt_q1 <= fire_cnt;
    fire_cnt_q2 <= fire_cnt_q1;
  end

  assign perf_enq_fire_cnt = fire_cnt_q2;
  assign perf_iq_full      = full_q2;

  // ===========================================================================
  // §2 sta/std 成对派遣
  // ===========================================================================
  always_comb
    for (int j = 0; j < STA_SLOTS; j++) begin
      sta_enq_valid[j]  = (N_STA > 0) & sta_dispatch_valid[j] & ~sta_drop_amocas[j];
      dispatch_ready[j] = (N_STA > 0) & sta_iq_ready[j] & std_iq_ready[j];
    end

endmodule
