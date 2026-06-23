// 自动生成:scripts/gen_scheduler_variants.py —— 勿手改
// =============================================================================
// scheduler_mem_pkg —— 香山 V2R2 Mem Scheduler 可读重写 类型/参数包
// 设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
//        golden:Scheduler_3.sv
// =============================================================================
package scheduler_mem_pkg;

  // ---- 维度参数(本 Mem SchdBlock 的实例化结果)----
  localparam int NUM_IQ        = 9;   // 本调度块内发射队列个数
  localparam int NUM_ENQ_FIRE  = 18;   // 参与 perf 统计的 enq 端口数(各 IQ 2 路)
  localparam int PERF_CNT_W    = 5;   // enq_fire popcount 结果位宽
  localparam int PERF_PORT_W   = 6;   // io_perf_*_value 端口位宽(高位补 0)

  // 9 个发射队列的身份标识(与 golden 例化顺序一致)。
  typedef enum logic [3:0] {
    IQ_STA_MOU_0         = 4'd0,  // 存地址 IQ #0 (perf full bit0)
    IQ_STA_MOU_1         = 4'd1,  // 存地址 IQ #1 (perf full bit1)
    IQ_LDU_0             = 4'd2,  // Load IQ #0 (perf full bit2)
    IQ_LDU_1             = 4'd3,  // Load IQ #1 (perf full bit3)
    IQ_LDU_2             = 4'd4,  // Load IQ #2 (perf full bit4)
    IQ_VLDU_VSTU_SEG     = 4'd5,  // 向量访存(段)IQ (perf full bit5)
    IQ_VLDU_VSTU         = 4'd6,  // 向量 Load/Store IQ (perf full bit6)
    IQ_STD_MOU_0         = 4'd7,  // 存数据 IQ #0 (perf full bit7)
    IQ_STD_MOU_1         = 4'd8  // 存数据 IQ #1 (perf full bit8)
  } iq_id_e;

  // perf 计数两级流水:firtool 把每个 perf 事件用 RegNext 打两拍再输出。
  // s1 = 对采样值打一拍并求和;s2 = 再打一拍,即对外输出值。
  typedef struct packed {
    logic [PERF_CNT_W-1:0] enq_fire_cnt;   // 上拍各 enq 端口 fire 个数之和
    logic [NUM_IQ-1:0]     iq_full;        // 各 IQ 上拍 enq0.ready(可收/满)位向量
  } perf_sample_t;

  // enq_fire 个数的 popcount(18 位 → 5 位结果)。用函数表达计数树,
  // 替代 firtool 展平的 {1'h0,..}+{1'h0,..} 嵌套加法。
  function automatic logic [PERF_CNT_W-1:0] popcount(input logic [NUM_ENQ_FIRE-1:0] v);
    popcount = '0;
    for (int i = 0; i < NUM_ENQ_FIRE; i++) popcount += PERF_CNT_W'(v[i]);
  endfunction

endpackage
