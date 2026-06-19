// 自动生成:scripts/gen_scheduler_int.py —— 勿手改
// =============================================================================
// scheduler_int_pkg —— 香山 V2R2 Int Scheduler 可读重写 类型/参数包
// 设计源:src/main/scala/xiangshan/backend/issue/Scheduler.scala
// =============================================================================
package scheduler_int_pkg;

  // ---- 维度参数(本 Int SchdBlock 的实例化结果)----
  localparam int NUM_IQ      = 4;  // 本调度块内的发射队列个数
  localparam int NUM_ENQ     = 8;  // dispatch 派发入端口数(每 IQ 2 路 * 4 IQ)
  localparam int NUM_WK_SRC  = 7;  // fromSchedulers 跨 IQ 唤醒源个数(exuIdx 0..6)
  localparam int NUM_PDEST_COPY = 2;  // 每个唤醒源的 pdest 拷贝份数

  // 4 个发射队列的身份标识(与 golden 例化顺序一致)。
  // 唤醒网络要按 IQ 的物理位置选择 pdest 拷贝下标,故给每个 IQ 命名。
  typedef enum logic [1:0] {
    IQ_ALU_MUL_BKU_BRH_JMP_0 = 2'd0,  // AluMulBkuBrhJmp     (enq 0/1, perf full bit0)
    IQ_ALU_MUL_BKU_BRH_JMP_1 = 2'd1,  // AluMulBkuBrhJmp #2  (enq 2/3, perf full bit1)
    IQ_ALU_BRH_JMP_I2F_VSET  = 2'd2,  // AluBrhJmpI2f...     (enq 4/5, perf full bit2)
    IQ_ALU_CSR_FENCE_DIV     = 2'd3   // AluCsrFenceDiv      (enq 6/7, perf full bit3)
  } iq_id_e;

  // 唤醒拷贝下标选择:为缩短唤醒目的寄存器号(pdest)的扇出时序,每个唤醒源
  // 给出多份 pdest 拷贝;每个 IQ 取属于自己那一份。本 Int 变体的物理映射为
  // 前两个 IQ 用 copy0,后两个 IQ 用 copy1(由 backend 的 isCopyPdest 决定)。
  function automatic int copy_idx_of_iq(input iq_id_e iq);
    case (iq)
      IQ_ALU_MUL_BKU_BRH_JMP_0, IQ_ALU_MUL_BKU_BRH_JMP_1: copy_idx_of_iq = 0;
      default:                                            copy_idx_of_iq = 1;
    endcase
  endfunction

  // perf 计数两级流水:firtool 把每个 perf 事件用 RegNext 打两拍再输出。
  // s1 = 本拍采样值;s2 = 上一拍的 s1(即对外输出值)。
  typedef struct packed {
    logic [3:0] enq_fire_cnt;   // 8 个 enq 端口上拍 fire 个数(0..8 → 4bit)
    logic [3:0] iq_full;        // 4 个 IQ 上拍 enq0.ready(可收/满)位向量
  } perf_sample_t;

  // enq_fire 个数的 popcount(8 位 → 4 位结果)。用函数表达计数树,
  // 替代 firtool 展平的 {1'h0,..}+{1'h0,..} 嵌套加法。
  function automatic logic [3:0] popcount8(input logic [7:0] v);
    popcount8 = 4'(v[0]) + 4'(v[1]) + 4'(v[2]) + 4'(v[3])
              + 4'(v[4]) + 4'(v[5]) + 4'(v[6]) + 4'(v[7]);
  endfunction

endpackage
