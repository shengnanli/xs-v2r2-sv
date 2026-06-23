// 自动生成:scripts/gen_scheduler_variants.py —— 勿手改
// =============================================================================
// scheduler_vf_pkg —— 香山 V2R2 Vf Scheduler 可读重写 类型/参数包
// 设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
//        golden:Scheduler_2.sv
// =============================================================================
package scheduler_vf_pkg;

  // ---- 维度参数(本 Vf SchdBlock 的实例化结果)----
  localparam int NUM_IQ        = 3;   // 本调度块内发射队列个数
  localparam int NUM_ENQ_FIRE  = 6;   // 参与 perf 统计的 enq 端口数(各 IQ 2 路)
  localparam int PERF_CNT_W    = 3;   // enq_fire popcount 结果位宽
  localparam int PERF_PORT_W   = 6;   // io_perf_*_value 端口位宽(高位补 0)

  // 3 个发射队列的身份标识(与 golden 例化顺序一致)。
  typedef enum logic [1:0] {
    IQ_VF_COMBO          = 2'd0,  // 综合 VF IQ (enq 0/1, perf full bit0)
    IQ_VFMA_VFALU        = 2'd1,  // VFMA/VIALU/VFALU IQ (enq 2/3, perf full bit1)
    IQ_VF_DIV            = 2'd2  // 向量除法 IQ (enq 4/5, perf full bit2)
  } iq_id_e;

  // perf 计数两级流水:firtool 把每个 perf 事件用 RegNext 打两拍再输出。
  // s1 = 对采样值打一拍并求和;s2 = 再打一拍,即对外输出值。
  typedef struct packed {
    logic [PERF_CNT_W-1:0] enq_fire_cnt;   // 上拍各 enq 端口 fire 个数之和
    logic [NUM_IQ-1:0]     iq_full;        // 各 IQ 上拍 enq0.ready(可收/满)位向量
  } perf_sample_t;

  // enq_fire 个数的 popcount(6 位 → 3 位结果)。用函数表达计数树,
  // 替代 firtool 展平的 {1'h0,..}+{1'h0,..} 嵌套加法。
  function automatic logic [PERF_CNT_W-1:0] popcount(input logic [NUM_ENQ_FIRE-1:0] v);
    popcount = '0;
    for (int i = 0; i < NUM_ENQ_FIRE; i++) popcount += PERF_CNT_W'(v[i]);
  endfunction

endpackage
