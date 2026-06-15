// =============================================================================
// xs_Frontend_core —— 香山 V2R2（昆明湖）前端总顶层的可读 glue 核（手写）
//
// 对应 Chisel: xiangshan.frontend.Frontend / FrontendImp（Frontend.scala）
//
// 【它在 SoC 里的位置】
//   Frontend 是整个取指前端的**总顶层**：把五大子系统接到一起，并经 ITLB/PMP 完成
//   取指地址翻译、把后端的 redirect/commit/flush 路由进来、把取回的指令送给后端：
//
//        ┌──────────────────────── Frontend 顶层 ────────────────────────┐
//   后端 ─redirect/commit─▶│ Ftq ◀──预测块── Predictor(BPU)                 │
//                          │  │ 取指请求(PC)                                │
//                          │  ▼                                            │
//                          │ NewIFU ◀──取指/命中──▶ ICache ◀──ITLB翻译──┐  │
//                          │  │ 预解码后的指令          │                │  │
//                          │  ▼                        │ 取指 PC ───────┘  │
//   后端 ◀──指令(cfVec)────│ IBuffer ◀─────────────────┘  TLB(ITLB)+PMP    │
//                          │                              PFEvent(性能)    │
//                          └────────────────────────────────────────────┘
//
//   子系统（均已各自可读重写 + 验证，本核只把它们接起来，**不重写**）：
//     · Predictor —— BPU 顶层（多级覆盖式分支预测）
//     · Ftq       —— 取指目标队列（连接 BPU 与 IFU，承载 redirect/commit/update）
//     · NewIFU    —— 取指主控（发请求、收数据、预解码、送 IBuffer）
//     · ICache    —— L1 指令缓存（MainPipe/MissUnit/Prefetch/…）
//     · IBuffer   —— 指令缓冲（解耦 IFU 与后端取指节奏）
//   取指辅助单元（本核也当 golden 黑盒）：
//     · TLB(ITLB) + PTWFilter/PTWRepeater —— 取指虚实地址翻译
//     · PMP/PMPChecker                    —— 取指物理地址权限检查
//     · PFEvent/HPerfMonitor              —— 性能事件计数
//     · InstrUncache                      —— MMIO（非缓存）取指
//
// 【顶层真正承担的逻辑（本核重写的对象）——绝大多数端口是接线/sideband，真逻辑只有两类】
//   A. 几条 **跨级打拍的流水寄存** glue（驱动真实对外/对内信号）：
//      1) backend redirect → 打 1 拍 → IBuffer 冲刷（needFlush/控制流/访存违例三标志）；
//      2) sfence → 打 2 拍 → ITLB/PMP（TLB flush 与取指流水对齐，避免在途请求踩翻译）；
//      3) fencei / icache 预取使能 → 打 1 拍 → ICache；
//      4) ICache ECC/总线错误 → 打 2 拍 → io_error（上报 BEU）；
//      5) 性能事件 → 打 2 拍 → io_perf（时序对齐）。
//   B. **跨取指块 PC 连续性一致性检查器**（checkPcMem + prevTaken/prevNotTaken）：
//      这是前端唯一一段非平凡组合+时序逻辑。它在指令离开 IBuffer 送往后端时，验证
//      "相邻指令 / 相邻取指块之间的 PC 是否连续、是否与预测一致"，不一致则触发断言。
//      纯校验性质（不驱动任何对外功能输出），但最能体现前端取指语义，故完整重写+注释，
//      并作为 UT 影子探针的主要比对目标（见 docs/frontend/Frontend.md）。
//
// 【为什么用"校验伴随"而非 1:1 透传核】
//   golden Frontend 9749 行、382 端口，其中 ~95% 是 25 个子模块互联 + MBIST/SRAM/PTW
//   等物理 sideband 的机械扇出（firtool 展平的 _GEN/childBd 名）。这些必须与 golden 逐字
//   一致 FM 才能把两侧黑盒引脚对齐。故 golden 同名 wrapper **照搬 golden body**作为
//   FM/UT 等价基线；本可读核作为**纯增量校验伴随**被 wrapper 例化，吃 wrapper 内同名
//   源信号、独立可读再实现上面 A/B 两类逻辑，吐影子输出经 _xs 变体的 xs_dbg_* 引出，
//   tb 里与 golden 对应寄存器逐拍比对，证明可读核功能等价。学习者读本核 + 文档即掌握
//   前端顶层 glue 的全部"真逻辑"。
// =============================================================================

package xs_frontend_pkg;
  // ---- 取指带宽 / 队列容量参数（KunminghuV2 Frontend）----
  localparam int unsigned DECODE_WIDTH = 6;   // IBuffer 一拍最多出 6 条指令（io_out_0..5）
  localparam int unsigned FTQ_SIZE     = 64;  // FTQ 表项数 → ftqPtr 6 位、checkPcMem 64 项
  localparam int unsigned FTQ_PTR_W    = 6;   // ftqPtr.value 宽
  localparam int unsigned VADDR_W      = 50;  // VAddrBits（startAddr/pc/target 宽）
  localparam int unsigned PADDR_W      = 48;  // PAddrBits（io_error paddr 宽）
  localparam int unsigned PERF_W       = 6;   // 性能事件计数值宽
  localparam int unsigned N_PERF       = 8;   // 前端性能事件个数（io_perf_0..7）

  // 预解码分支类型编码（PreDecode：BrType）。检查器只关心"是否为条件分支(=1)"。
  localparam logic [1:0] BR_TYPE_COND = 2'h1; // 条件分支（br）

  // 一条从 IBuffer 出口送往后端的指令所携带的、检查器需要的字段。
  // golden 展平为 io_out_<i>_valid / _bits_pc / _bits_ftqPtr_* / _bits_pd_* …，这里聚合。
  typedef struct packed {
    logic                  fire;        // = backend ready & ibuffer valid（本拍真出队）
    logic [VADDR_W-1:0]    pc;          // 该指令 PC
    logic                  ftq_flag;    // 所属 FTQ 项指针 flag（绕回位）
    logic [FTQ_PTR_W-1:0]  ftq_value;   // 所属 FTQ 项指针 value
    logic [1:0]            br_type;     // 预解码分支类型
    logic                  pred_taken;  // 预测是否 taken
    logic                  is_rvc;      // 是否压缩指令（决定 PC 步进 2 还是 4 字节）
  } ib_lane_t;
endpackage

module xs_Frontend_core
  import xs_frontend_pkg::*;
(
  input  logic clock,
  input  logic reset,

  // ======================================================================
  // A 类 glue 的输入（来自顶层端口 / 子模块输出）
  // ======================================================================
  // --- 1) 后端 redirect（路由给 IBuffer 冲刷）---
  input  logic                   redirect_valid,        // io_backend_toFtq_redirect_valid
  input  logic                   redirect_is_ctrl,      // …_bits_debugIsCtrl（控制流类）
  input  logic                   redirect_is_memvio,    // …_bits_debugIsMemVio（访存违例类）
  // --- 2) sfence（路由给 ITLB/PMP，打 2 拍）---
  input  logic                   sfence_valid,
  input  logic                   sfence_rs1,
  input  logic                   sfence_rs2,
  input  logic [VADDR_W-1:0]     sfence_addr,
  input  logic [15:0]            sfence_id,
  input  logic                   sfence_flushPipe,
  input  logic                   sfence_hv,
  input  logic                   sfence_hg,
  // --- 3) fencei / icache 预取使能（打 1 拍给 ICache）---
  input  logic                   fencei,                // io_fencei
  input  logic                   csr_pf_enable,         // csrCtrl 经 DelayN 后的 l1I 预取使能
  // --- 4) ICache 错误（打 2 拍上报 BEU）---
  input  logic                   icache_err_valid,
  input  logic [PADDR_W-1:0]     icache_err_paddr,
  input  logic                   icache_err_to_beu,
  // --- 5) 性能事件（打 2 拍）---
  input  logic [PERF_W-1:0]      perf_in [N_PERF],

  // ======================================================================
  // A 类 glue 的输出（送顶层端口 / 子模块输入）
  // ======================================================================
  output logic                   flush,                 // → IBuffer.io_flush
  output logic                   flush_ctrl_redirect,   // → IBuffer.io_ControlRedirect
  output logic                   flush_memvio_redirect, // → IBuffer.io_MemVioRedirect
  output logic                   sfence_q_valid,        // → ITLB/PMP（打 2 拍后）
  output logic                   sfence_q_rs1,
  output logic                   sfence_q_rs2,
  output logic [VADDR_W-1:0]     sfence_q_addr,
  output logic [15:0]            sfence_q_id,
  output logic                   sfence_q_flushPipe,
  output logic                   sfence_q_hv,
  output logic                   sfence_q_hg,
  output logic                   icache_fencei_q,       // → ICache.io_fencei（打 1 拍后）
  output logic                   icache_pf_enable_q,    // → ICache.io_csr_pf_enable（打 1 拍后）
  output logic                   error_valid_q,         // → io_error_valid（打 2 拍后）
  output logic [PADDR_W-1:0]     error_paddr_q,
  output logic                   error_to_beu_q,
  output logic [PERF_W-1:0]      perf_q [N_PERF],       // → io_perf_*_value（打 2 拍后）

  // ======================================================================
  // B 类：跨取指块 PC 连续性检查器
  // ======================================================================
  // --- IBuffer 6 条出口 lane（检查器输入）---
  input  ib_lane_t               ib_lane [DECODE_WIDTH],
  // --- FTQ → 后端的 PC mem 写口（写入 checkPcMem 镜像）---
  input  logic                   ftq_pcmem_wen,
  input  logic [FTQ_PTR_W-1:0]   ftq_pcmem_waddr,
  input  logic [VADDR_W-1:0]     ftq_pcmem_wdata,
  // --- FTQ 最新表项目标（检查器读 fall-through 目标时的旁路源）---
  input  logic [FTQ_PTR_W-1:0]   ftq_newest_ptr_value,
  input  logic [VADDR_W-1:0]     ftq_newest_target,
  // --- 检查器输出：本拍是否检出 PC 不连续（任一违例）---
  output logic                   pc_continuity_violation
);

  // =========================================================================
  // A 类 glue：跨级打拍流水寄存
  //   香山把这些控制/状态信号在 Frontend 顶层多打几拍，目的是 **时序对齐 + 高扇出隔离**：
  //   sfence/fencei 要在取指流水的特定拍才作用到 ITLB/ICache；error/perf 打拍便于布线。
  // =========================================================================

  // --- 1) backend redirect → 打 1 拍 → IBuffer 冲刷 ---
  // 后端发现误预测/异常时拉高 redirect。IBuffer 据此丢弃在途指令（区分控制流 / 访存违例
  // 以便正确回收 RAS/统计），打 1 拍是为与 IBuffer 内部冲刷时序对齐。
  always_ff @(posedge clock) begin
    flush                 <= redirect_valid;
    flush_ctrl_redirect   <= redirect_is_ctrl;
    flush_memvio_redirect <= redirect_is_memvio;
  end

  // --- 2) sfence → 打 2 拍 → ITLB/PMP ---
  // sfence.vma 要冲刷 ITLB。前端把 sfence 打 2 拍才送 ITLB：第一拍对齐 CSR 广播，第二拍
  // 确保取指流水里已发出的在途翻译请求先退出，避免用旧映射的请求与新 flush 撞车。
  ib_lane_t unused; // (占位，避免空 typedef 告警；不参与逻辑)
  logic                   sfence_s1_valid, sfence_s1_rs1, sfence_s1_rs2;
  logic [VADDR_W-1:0]     sfence_s1_addr;
  logic [15:0]            sfence_s1_id;
  logic                   sfence_s1_flushPipe, sfence_s1_hv, sfence_s1_hg;
  always_ff @(posedge clock) begin
    // 第 1 级
    sfence_s1_valid     <= sfence_valid;
    sfence_s1_rs1       <= sfence_rs1;
    sfence_s1_rs2       <= sfence_rs2;
    sfence_s1_addr      <= sfence_addr;
    sfence_s1_id        <= sfence_id;
    sfence_s1_flushPipe <= sfence_flushPipe;
    sfence_s1_hv        <= sfence_hv;
    sfence_s1_hg        <= sfence_hg;
    // 第 2 级（→ ITLB/PMP）
    sfence_q_valid      <= sfence_s1_valid;
    sfence_q_rs1        <= sfence_s1_rs1;
    sfence_q_rs2        <= sfence_s1_rs2;
    sfence_q_addr       <= sfence_s1_addr;
    sfence_q_id         <= sfence_s1_id;
    sfence_q_flushPipe  <= sfence_s1_flushPipe;
    sfence_q_hv         <= sfence_s1_hv;
    sfence_q_hg         <= sfence_s1_hg;
  end

  // --- 3) fencei / 预取使能 → 打 1 拍 → ICache ---
  // fence.i 要使 ICache 全部失效；预取使能来自 CSR。打 1 拍隔离扇出。
  always_ff @(posedge clock) begin
    icache_fencei_q    <= fencei;
    icache_pf_enable_q <= csr_pf_enable;
  end

  // --- 4) ICache 错误 → 打 2 拍 → BEU ---
  // ICache 检出 ECC / 总线错误，前端打 2 拍后经 io_error 上报总线错误单元（BEU）。
  logic                   err_s1_valid, err_s1_to_beu;
  logic [PADDR_W-1:0]     err_s1_paddr;
  always_ff @(posedge clock) begin
    err_s1_valid  <= icache_err_valid;
    err_s1_paddr  <= icache_err_paddr;
    err_s1_to_beu <= icache_err_to_beu;
    error_valid_q <= err_s1_valid;
    error_paddr_q <= err_s1_paddr;
    error_to_beu_q<= err_s1_to_beu;
  end

  // --- 5) 性能事件 → 打 2 拍 ---
  logic [PERF_W-1:0] perf_s1 [N_PERF];
  always_ff @(posedge clock) begin
    for (int p = 0; p < N_PERF; p++) begin
      perf_s1[p] <= perf_in[p];
      perf_q[p]  <= perf_s1[p];
    end
  end

  // =========================================================================
  // B 类：跨取指块 PC 连续性一致性检查器
  //
  // 【它在检查什么】
  //   指令离开 IBuffer 送往后端时（每拍最多 6 条，lane0..5 顺序排列），前端验证取指
  //   语义自洽——下一条指令的 PC 必须等于"上一条按其类型/预测推出的应有 PC"：
  //     · 上一条是 **taken 的条件分支** → 下一条 PC 应 = 该分支的预测目标
  //       （目标存在 FTQ 的 pc_mem：用 checkPcMem 镜像或 newest_entry 旁路读出）；
  //     · 上一条是 **not-taken**（顺序执行） → 下一条 PC 应 = 上一条 PC + (RVC?2:4)；
  //     · 同一取指块内相邻 lane 还要求 ftqPtr 连续（同块或 +1 块）。
  //   任一不符 → 触发断言（golden 里是 $error/$fatal），说明 BPU/IFU/FTQ 链路出了 bug。
  //
  // 【为什么需要跨块状态 prevTaken/prevNotTaken】
  //   一个取指块的最后一条指令，其"下一条"在**下一拍**才从 IBuffer 出来。所以要把
  //   "上一拍块尾那条是 taken / not-taken、它的 ftqPtr / PC / 是否 RVC"latch 住，等下一拍
  //   第一条（lane0）出来时再比。香山为时序把它复制成两份（_1 后缀），逻辑等价。
  //
  // 【checkPcMem】
  //   是 FTQ pc_mem（每个 FTQ 项的 startAddr）的一份 64 项镜像，随 FTQ 写口同步写入。
  //   检查 taken 目标时，按"目标块的 ftqPtr+1"索引读出其 startAddr 作为应有的下一 PC。
  //   读最新项时优先用 newest_entry 旁路（pc_mem 写后读冒险规避）。
  // =========================================================================

  // ---- checkPcMem：FTQ startAddr 的 64 项镜像（同步写口）----
  logic [VADDR_W-1:0] checkPcMem [FTQ_SIZE];
  always_ff @(posedge clock) begin
    if (ftq_pcmem_wen)
      checkPcMem[ftq_pcmem_waddr] <= ftq_pcmem_wdata;
  end

  // 读"某 ftqPtr 所指块的 startAddr"：最新项走 newest_entry 旁路，否则读镜像。
  // （用 function 纯传参，不读非局部信号，规避 VCS-091）
  function automatic logic [VADDR_W-1:0] read_block_start(
      input logic [FTQ_PTR_W-1:0] ptr,
      input logic [FTQ_PTR_W-1:0] newest_ptr,
      input logic [VADDR_W-1:0]   newest_tgt,
      input logic [VADDR_W-1:0]   mem [FTQ_SIZE]);
    read_block_start = (newest_ptr == ptr) ? newest_tgt : mem[ptr];
  endfunction

  // ---- 跨块 latch（块尾那条指令的信息，留到下一拍比对 lane0）----
  // taken 分支：记 ftqPtr（用于 ftqPtr 连续性检查）
  logic                  prevTakenValid;
  logic                  prevTakenFtqPtr_flag;
  logic [FTQ_PTR_W-1:0]  prevTakenFtqPtr_value;
  // taken 分支：记 ftqPtr（第二份，用于"目标 PC = 下一条 PC"检查，对应 golden 的 _1 复制）
  logic                  prevTakenValid_1;
  logic                  prevTakenFtqPtr_1_flag;
  logic [FTQ_PTR_W-1:0]  prevTakenFtqPtr_1_value;
  // not-taken（顺序）：记块尾 PC + 是否 RVC，用于 PC+步进 检查
  logic                  prevNotTakenValid;
  logic [VADDR_W-1:0]    prevNotTakenPC;
  logic                  prevIsRVC;

  // ---- 逐 lane 派生信号（仿 golden 的 inner__N 链，但用具名数组表达）----
  // fire[i]      : lane i 本拍真出队
  // isCondBr[i]  : lane i 是条件分支
  // takenBr[i]   : lane i 是 taken 的条件分支（块在此处"跳走"）
  // ntCondBr[i]  : lane i 是 not-taken 的条件分支（顺序往下）
  // anyTaken[i]  : lane i 是任意类型的 taken 跳转（含间接/直接 jump，brType!=0 & taken）
  logic [DECODE_WIDTH-1:0] isCondBr, takenBr, ntCondBr, anyTaken;
  always_comb begin
    for (int i = 0; i < DECODE_WIDTH; i++) begin
      isCondBr[i] = ib_lane[i].fire & (ib_lane[i].br_type == BR_TYPE_COND);
      takenBr[i]  = isCondBr[i] & ib_lane[i].pred_taken;
      ntCondBr[i] = isCondBr[i] & ~ib_lane[i].pred_taken;
      anyTaken[i] = ib_lane[i].fire & (|ib_lane[i].br_type) & ib_lane[i].pred_taken;
    end
  end

  // 块尾"taken 跳走"的判定沿 lane 自高位向低位取第一个 taken（块在此截断，后面 lane 无效）。
  // 这等价于 golden 里 prevTaken 写使能那串嵌套优先级 if。下面用纯组合扫描算出：
  //   blockEndsTaken : 本拍有某 lane 是块尾 taken 分支（块在该 lane 跳走）
  //   endTakenIdx    : 该 lane 下标（用于取其 ftqPtr / PC）
  // 注意：lane5 是最高优先（最后一条），与 golden 的 if(inner__16) 在最外层一致。
  //   endTaken_*     : 直接选出该 lane 的 ftqPtr 字段（mux 覆盖，避免动态索引越界）
  logic                  blockEndsTaken;
  logic                  endTaken_flag;
  logic [FTQ_PTR_W-1:0]  endTaken_value;
  always_comb begin
    blockEndsTaken = 1'b0;
    endTaken_flag  = 1'b0;
    endTaken_value = '0;
    for (int i = DECODE_WIDTH-1; i >= 0; i--) begin
      if (takenBr[i]) begin
        blockEndsTaken = 1'b1;
        endTaken_flag  = ib_lane[i].ftq_flag;
        endTaken_value = ib_lane[i].ftq_value;
      end
    end
  end

  // 同理：块尾"not-taken"（顺序结束这一拍）信息（PC + 是否 RVC，直接选出）
  logic                  blockEndsNotTaken;
  logic [VADDR_W-1:0]    endNt_pc;
  logic                  endNt_rvc;
  always_comb begin
    blockEndsNotTaken = 1'b0;
    endNt_pc          = '0;
    endNt_rvc         = 1'b0;
    for (int i = DECODE_WIDTH-1; i >= 0; i--) begin
      if (ntCondBr[i]) begin
        blockEndsNotTaken = 1'b1;
        endNt_pc          = ib_lane[i].pc;
        endNt_rvc         = ib_lane[i].is_rvc;
      end
    end
  end

  // 跨块 latch 更新：把本拍块尾信息留到下一拍。
  // valid 的存活条件 = ~(本拍冲刷 | 本拍 lane0 已消费掉上一拍的 latch)。
  // lane0 消费 = (prevValid & lane0.fire)：上一拍留了块尾，本拍 lane0 出来即完成比对并清。
  logic lane0_fire;
  assign lane0_fire = ib_lane[0].fire;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      prevTakenValid    <= 1'b0;
      prevTakenValid_1  <= 1'b0;
      prevNotTakenValid <= 1'b0;
    end else begin
      // taken（份 0）：本拍若块尾 taken 则置位；否则保持到被 lane0 消费。
      prevTakenValid <= ~(flush | (prevTakenValid & lane0_fire))
                        & (blockEndsTaken | prevTakenValid);
      prevTakenValid_1 <= ~(flush | (prevTakenValid_1 & lane0_fire))
                        & (blockEndsTaken | prevTakenValid_1);
      prevNotTakenValid <= ~(flush | (prevNotTakenValid & lane0_fire))
                        & (blockEndsNotTaken | prevNotTakenValid);
    end
  end

  always_ff @(posedge clock) begin
    if (blockEndsTaken) begin
      prevTakenFtqPtr_flag    <= endTaken_flag;
      prevTakenFtqPtr_value   <= endTaken_value;
      prevTakenFtqPtr_1_flag  <= endTaken_flag;
      prevTakenFtqPtr_1_value <= endTaken_value;
    end
    if (blockEndsNotTaken) begin
      prevNotTakenPC <= endNt_pc;
      prevIsRVC      <= endNt_rvc;
    end
  end

  // ---- 一致性比对（任一条违例则置 pc_continuity_violation）----
  // 用具名中间表达，逐条对应 golden 的 inner__probe_N：
  //   (a) 同块相邻 lane：taken 分支 → 下一 lane 的 ftqPtr 应 = 本 lane ftqPtr+1
  //   (b) 同块相邻 lane：taken（任意跳转）→ 下一 lane PC 应 = 跳转目标（读 block start）
  //   (c) 同块相邻 lane：not-taken → 下一 lane PC 应 = 本 lane PC + (RVC?2:4)
  //   (d) 跨块（lane0 对上一拍块尾 latch）：上述三类的跨拍版本
  // 注：本检查器为纯校验（断言用），不驱动任何对外功能输出；pc_continuity_violation
  //     是把所有 probe 或在一起的影子结果，供 UT 与 golden 的 assertion 触发条件比对。
  logic [DECODE_WIDTH-1:0] vio_intra_ftqptr; // (a) 块内 ftqPtr 不连续
  logic [DECODE_WIDTH-1:0] vio_intra_target; // (b) 块内 taken 目标错
  logic [DECODE_WIDTH-1:0] vio_intra_seq;    // (c) 块内顺序 PC 错
  always_comb begin
    vio_intra_ftqptr = '0;
    vio_intra_target = '0;
    vio_intra_seq    = '0;
    for (int i = 0; i < DECODE_WIDTH-1; i++) begin
      // (a) 本 lane taken 条件分支 且 下一 lane fire：ftqPtr 须 +1 连续
      if (takenBr[i] & ib_lane[i+1].fire)
        vio_intra_ftqptr[i] =
          (FTQ_PTR_W'(ib_lane[i].ftq_value + 1'b1) != ib_lane[i+1].ftq_value);
      // (b) 本 lane 任意 taken 跳转 且 下一 lane fire：目标 PC 须 = 下一 lane PC
      if (anyTaken[i] & ib_lane[i+1].fire) begin
        logic [VADDR_W-1:0] tgt;
        tgt = read_block_start(FTQ_PTR_W'(ib_lane[i].ftq_value + 1'b1),
                               ftq_newest_ptr_value, ftq_newest_target, checkPcMem);
        // 最新项旁路：若本 lane 自己就是最新项，则目标直接用 newest_target
        if (ftq_newest_ptr_value == ib_lane[i].ftq_value)
          tgt = ftq_newest_target;
        vio_intra_target[i] = (tgt != ib_lane[i+1].pc);
      end
      // (c) 本 lane not-taken 条件分支 且 下一 lane fire：PC 须 = 本 PC + 步进
      if (ntCondBr[i] & ib_lane[i+1].fire)
        vio_intra_seq[i] =
          (VADDR_W'(ib_lane[i].pc + (ib_lane[i].is_rvc ? VADDR_W'(2) : VADDR_W'(4)))
           != ib_lane[i+1].pc);
    end
  end

  // (d) 跨块：上一拍块尾 latch 对本拍 lane0
  logic vio_cross_ftqptr, vio_cross_target, vio_cross_seq;
  always_comb begin
    // 上一拍 taken：本拍 lane0 的 ftqPtr 应 = latch ftqPtr+1
    vio_cross_ftqptr = (prevTakenValid & lane0_fire)
      & (FTQ_PTR_W'(prevTakenFtqPtr_value + 1'b1) != ib_lane[0].ftq_value);
    // 上一拍 taken（份_1）：本拍 lane0 PC 应 = checkPcMem[latch ftqPtr+1]
    vio_cross_target = (prevTakenValid_1 & lane0_fire)
      & (checkPcMem[FTQ_PTR_W'(prevTakenFtqPtr_1_value + 1'b1)] != ib_lane[0].pc);
    // 上一拍 not-taken：本拍 lane0 PC 应 = latch PC + 步进
    vio_cross_seq = (prevNotTakenValid & lane0_fire)
      & (VADDR_W'(prevNotTakenPC + (prevIsRVC ? VADDR_W'(2) : VADDR_W'(4))) != ib_lane[0].pc);
  end

  assign pc_continuity_violation =
       (|vio_intra_ftqptr) | (|vio_intra_target) | (|vio_intra_seq)
     | vio_cross_ftqptr | vio_cross_target | vio_cross_seq;

  // 占位赋值（消除 unused 告警，不参与功能）
  always_comb unused = '0;

endmodule
