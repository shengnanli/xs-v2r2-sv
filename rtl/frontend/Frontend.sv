// Frontend.sv —— 香山前端顶层装配：分支预测 BPU → 取指目标队列 FTQ → 取指单元 IFU（+ICache / MMIO 取指）→ 指令缓冲 IBuffer → 后端
// =============================================================================
// 在哪一层：XSCore 的前半部分，Chisel 源 xiangshan/frontend/Frontend.scala（FrontendImp 外壳 +
//   FrontendInlinedImp 本体，后者 shouldBeInlined，所以 golden 里本体的一切都带 inner_ 前缀）。
//   golden G1-canonical/golden-rtl/Frontend.sv（10,940 行 / 441 端口 / 23 个子模块实例）。
//
// 一条取指流的视角（解耦前端，"预测在前、取指在后"）：
//   BPU（Predictor）每拍给出一个"取指块"（起始 PC、块内第一条跳转、目标）→ 写进 FTQ 的一项；
//   FTQ 按顺序把取指请求同时发给 IFU 和 ICache（两边都 ready 才算发出，见 §3）；
//   ICache 回指令数据给 IFU，IFU 预译码、校验预测（误预测则回告 FTQ 重定向 BPU），把指令塞进 IBuffer；
//   IBuffer 每拍向后端译码送最多 6 条（cfVec）。后端提交/重定向回到 FTQ，FTQ 再去更新 / 重定向 BPU。
//   旁路：取不可缓存（MMIO）指令走 InstrUncache；虚实地址翻译走 ITLB（经 PTWFilter / PTWRepeaterNB
//   到 L2TLB）；物理地址权限查 PMP（5 个检查口：ICache 4 口 + IFU 1 口）。
//
// 本文件的分工：
//   * xs_Frontend_core（可读核，手写）—— 顶层自己的那点逻辑：
//       §1 后端重定向打一拍后分发给 IBuffer（冲刷 + 两个调试标志）
//       §2 sfence 打两拍、ICache 的预取开关 / fence.i 各打一拍
//       §3 FTQ→IFU/ICache 取指请求的联合握手
//       §4 wfi：ICache 与 InstrUncache 都安全才算安全
//       §5 ICache ECC 错误上报（打两拍）
//       §6 性能事件输出（HPerfMonitor 结果打两拍）
//       §7 送往后端的指令流自检（三组 XSError：ftqPtr 连续性 / 跳转目标 / 顺序 PC）
//   * Frontend（golden 同名 wrapper，scripts/gen_frontend.py 从 golden 例化表机械生成）——
//       端口表、23 个子模块例化（实例名与 golden 一致），按"谁连谁"分组注释；子模块之间的线一律
//       按"<驱动实例>_<端口>"命名。
//
// 边界与怪癖（golden 实测）：
//   * §7 的自检只喂断言（golden 里 `ifndef SYNTHESIS 的 XSError），综合视角下没有任何观察者，
//     但 golden 保留了全部状态（64 项 checkPcMem 等，约 3.3k 位）。这里照写一份、一位不少
//     （CONVENTIONS「golden 的 debug 寄存器阵列必须照写」），两侧都是无读者寄存器，FM 用 vmucp 真比。
//     Chisel 里 checkNotTakenConsecutive 被注释掉了，golden 没有它，这里也没有。
//   * sfence / 重定向标志 / 错误 / 性能寄存器都**不复位**（RegNext），只有自检里三个 valid 是
//     RegInit(false)，golden 是**异步**复位（always @(posedge clock or posedge reset)），照抄。
//   * io_resetInFrontend 直接就是 reset（Chisel `reset.asBool`）。
//   * BPU 的 io_bpu_to_ftq_resp_bits_s3_valid_0 在 golden 里只接到一根探针线（无读者），这里不接。
//
// 本文件导航（按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   xs_Frontend_core §1 重定向分发 §2 CSR/sfence 延迟 §3 取指请求握手 §4 wfi §5 ECC 错误上报
//                    §6 性能事件 §7 指令流自检（checkPcMem / taken-ptr / taken-target / not-taken-pc）
//   Frontend —— golden 同名 wrapper（生成区）：端口表、子模块之间的连线、23 个子模块例化
// =============================================================================

module xs_Frontend_core (
  input  logic        clock,
  input  logic        reset,

  // ---- §1 后端重定向 ----
  input  logic        io_backend_toFtq_redirect_valid,
  input  logic        io_backend_toFtq_redirect_bits_debugIsCtrl,
  input  logic        io_backend_toFtq_redirect_bits_debugIsMemVio,
  output logic        redirect_flush,
  output logic        redirect_from_ctrl,
  output logic        redirect_from_memvio,

  // ---- §2 CSR / sfence ----
  input  logic        io_sfence_valid,
  input  logic        io_sfence_bits_rs1,
  input  logic        io_sfence_bits_rs2,
  input  logic [49:0] io_sfence_bits_addr,
  input  logic [15:0] io_sfence_bits_id,
  input  logic        io_sfence_bits_flushPipe,
  input  logic        io_sfence_bits_hv,
  input  logic        io_sfence_bits_hg,
  output logic        sfence_dly_valid,
  output logic        sfence_dly_bits_rs1,
  output logic        sfence_dly_bits_rs2,
  output logic [49:0] sfence_dly_bits_addr,
  output logic [15:0] sfence_dly_bits_id,
  output logic        sfence_dly_bits_flushPipe,
  output logic        sfence_dly_bits_hv,
  output logic        sfence_dly_bits_hg,
  input  logic        csrCtrlDelay_out_pf_ctrl_l1I_pf_enable,
  input  logic        io_fencei,
  output logic        icache_pf_enable,
  output logic        icache_fencei,

  // ---- §3 取指请求握手 ----
  input  logic        ifu_ftqInter_fromFtq_req_ready,
  input  logic        icache_fetch_req_ready,
  output logic        fetch_req_ready,

  // ---- §4 wfi ----
  input  logic        wfiReqDelay_out,
  input  logic        icache_wfi_wfiSafe,
  input  logic        instrUncache_wfi_wfiSafe,
  output logic        wfi_safe_now,

  // ---- §5 ECC 错误上报 ----
  input  logic        icache_error_valid,
  input  logic [47:0] icache_error_bits_paddr,
  input  logic        icache_error_bits_report_to_beu,
  output logic        io_error_ecc_error_valid,
  output logic [47:0] io_error_ecc_error_bits,

  // ---- §6 性能事件 ----
  input  logic [5:0]  perfHpm_perf_0_value,
  input  logic [5:0]  perfHpm_perf_1_value,
  input  logic [5:0]  perfHpm_perf_2_value,
  input  logic [5:0]  perfHpm_perf_3_value,
  input  logic [5:0]  perfHpm_perf_4_value,
  input  logic [5:0]  perfHpm_perf_5_value,
  input  logic [5:0]  perfHpm_perf_6_value,
  input  logic [5:0]  perfHpm_perf_7_value,
  output logic [5:0]  io_perf_0_value,
  output logic [5:0]  io_perf_1_value,
  output logic [5:0]  io_perf_2_value,
  output logic [5:0]  io_perf_3_value,
  output logic [5:0]  io_perf_4_value,
  output logic [5:0]  io_perf_5_value,
  output logic [5:0]  io_perf_6_value,
  output logic [5:0]  io_perf_7_value,

  // ---- §7 指令流自检：后端握手 + IBuffer 出口 + FTQ 的 PC 存储写口 ----
  input  logic        io_backend_cfVec_0_ready,
  input  logic        io_backend_cfVec_1_ready,
  input  logic        io_backend_cfVec_2_ready,
  input  logic        io_backend_cfVec_3_ready,
  input  logic        io_backend_cfVec_4_ready,
  input  logic        io_backend_cfVec_5_ready,
  input  logic        ibuffer_out_0_valid,
  input  logic [49:0] ibuffer_out_0_bits_pc,
  input  logic        ibuffer_out_0_bits_pd_isRVC,
  input  logic [1:0]  ibuffer_out_0_bits_pd_brType,
  input  logic        ibuffer_out_0_bits_pred_taken,
  input  logic        ibuffer_out_0_bits_ftqPtr_flag,
  input  logic [5:0]  ibuffer_out_0_bits_ftqPtr_value,
  input  logic        ibuffer_out_1_valid,
  input  logic [49:0] ibuffer_out_1_bits_pc,
  input  logic        ibuffer_out_1_bits_pd_isRVC,
  input  logic [1:0]  ibuffer_out_1_bits_pd_brType,
  input  logic        ibuffer_out_1_bits_pred_taken,
  input  logic        ibuffer_out_1_bits_ftqPtr_flag,
  input  logic [5:0]  ibuffer_out_1_bits_ftqPtr_value,
  input  logic        ibuffer_out_2_valid,
  input  logic [49:0] ibuffer_out_2_bits_pc,
  input  logic        ibuffer_out_2_bits_pd_isRVC,
  input  logic [1:0]  ibuffer_out_2_bits_pd_brType,
  input  logic        ibuffer_out_2_bits_pred_taken,
  input  logic        ibuffer_out_2_bits_ftqPtr_flag,
  input  logic [5:0]  ibuffer_out_2_bits_ftqPtr_value,
  input  logic        ibuffer_out_3_valid,
  input  logic [49:0] ibuffer_out_3_bits_pc,
  input  logic        ibuffer_out_3_bits_pd_isRVC,
  input  logic [1:0]  ibuffer_out_3_bits_pd_brType,
  input  logic        ibuffer_out_3_bits_pred_taken,
  input  logic        ibuffer_out_3_bits_ftqPtr_flag,
  input  logic [5:0]  ibuffer_out_3_bits_ftqPtr_value,
  input  logic        ibuffer_out_4_valid,
  input  logic [49:0] ibuffer_out_4_bits_pc,
  input  logic        ibuffer_out_4_bits_pd_isRVC,
  input  logic [1:0]  ibuffer_out_4_bits_pd_brType,
  input  logic        ibuffer_out_4_bits_pred_taken,
  input  logic        ibuffer_out_4_bits_ftqPtr_flag,
  input  logic [5:0]  ibuffer_out_4_bits_ftqPtr_value,
  input  logic        ibuffer_out_5_valid,
  input  logic [49:0] ibuffer_out_5_bits_pc,
  input  logic        ibuffer_out_5_bits_pd_isRVC,
  input  logic [1:0]  ibuffer_out_5_bits_pd_brType,
  input  logic        ibuffer_out_5_bits_pred_taken,
  input  logic        ibuffer_out_5_bits_ftqPtr_flag,
  input  logic [5:0]  ibuffer_out_5_bits_ftqPtr_value,
  input  logic        ftq_toBackend_pc_mem_wen,
  input  logic [5:0]  ftq_toBackend_pc_mem_waddr,
  input  logic [49:0] ftq_toBackend_pc_mem_wdata_startAddr,
  input  logic [49:0] ftq_toBackend_newest_entry_target,
  input  logic [5:0]  ftq_toBackend_newest_entry_ptr_value
);

  localparam int unsigned DECODE_WIDTH = 6;    // IBuffer → 译码每拍最多 6 条
  localparam int unsigned FTQ_SIZE     = 64;   // FTQ 项数；ftqPtr.value 6 位
  localparam int unsigned VADDR_W      = 50;
  localparam logic [1:0]  BR_TYPE_BR   = 2'h1; // PreDecode brType：0 非跳转 / 1 条件分支 / 2 jal / 3 jalr

  // ===========================================================================
  // §1 后端重定向 → IBuffer
  //   后端（Rob/重定向生成）的重定向在 FTQ 内部自己处理；IBuffer 只需要"冲掉缓冲里的指令"，
  //   所以顶层把 redirect.valid 打一拍作为 IBuffer.flush（Chisel needFlush = RegNext(...)）。
  //   debugIsCtrl / debugIsMemVio 同拍打一拍，只给 IBuffer 做 TopDown 停顿原因归类。
  // ===========================================================================
  always_ff @(posedge clock) begin
    redirect_flush       <= io_backend_toFtq_redirect_valid;
    redirect_from_ctrl   <= io_backend_toFtq_redirect_bits_debugIsCtrl;
    redirect_from_memvio <= io_backend_toFtq_redirect_bits_debugIsMemVio;
  end

  // ===========================================================================
  // §2 CSR / sfence 的时序隔离
  //   sfence.vma 广播到 ITLB 与两个 PTW 中继前打两拍（RegNext(RegNext(io.sfence))，不复位）。
  //   tlbCsr / csrCtrl 的两拍延迟是两个 DelayN 子模块（例化在 wrapper 里）；ICache 的 L1I
  //   预取开关取自延迟后的 csrCtrl 再打一拍，fence.i 直接打一拍。
  // ===========================================================================
  logic        sfence_s1_valid;
  logic        sfence_s1_rs1;
  logic        sfence_s1_rs2;
  logic [49:0] sfence_s1_addr;
  logic [15:0] sfence_s1_id;
  logic        sfence_s1_flushPipe;
  logic        sfence_s1_hv;
  logic        sfence_s1_hg;

  always_ff @(posedge clock) begin
    sfence_s1_valid           <= io_sfence_valid;
    sfence_s1_rs1             <= io_sfence_bits_rs1;
    sfence_s1_rs2             <= io_sfence_bits_rs2;
    sfence_s1_addr            <= io_sfence_bits_addr;
    sfence_s1_id              <= io_sfence_bits_id;
    sfence_s1_flushPipe       <= io_sfence_bits_flushPipe;
    sfence_s1_hv              <= io_sfence_bits_hv;
    sfence_s1_hg              <= io_sfence_bits_hg;
    sfence_dly_valid          <= sfence_s1_valid;
    sfence_dly_bits_rs1       <= sfence_s1_rs1;
    sfence_dly_bits_rs2       <= sfence_s1_rs2;
    sfence_dly_bits_addr      <= sfence_s1_addr;
    sfence_dly_bits_id        <= sfence_s1_id;
    sfence_dly_bits_flushPipe <= sfence_s1_flushPipe;
    sfence_dly_bits_hv        <= sfence_s1_hv;
    sfence_dly_bits_hg        <= sfence_s1_hg;
    icache_pf_enable          <= csrCtrlDelay_out_pf_ctrl_l1I_pf_enable;
    icache_fencei             <= io_fencei;
  end

  // ===========================================================================
  // §3 FTQ → IFU / ICache 取指请求
  //   同一个取指请求同时发给 IFU（要预译码的那份）与 ICache（读数据的那份），两边都能收才算发出：
  //   FTQ 看到的 ready = IFU.ready & ICache.ready（Chisel 对 toIfu / toICache 两个 ready 写同一个式子，
  //   golden 里两者折成 FTQ 的一个 io_toIfu_req_ready）。
  // ===========================================================================
  assign fetch_req_ready = ifu_ftqInter_fromFtq_req_ready & icache_fetch_req_ready;

  // ===========================================================================
  // §4 wfi（等待中断）握手
  //   后端的 wfiReq 先经一拍 DelayN 再同时送给 ICache 与 InstrUncache；两者都报"无在途访问"时才安全，
  //   且只在有 wfiReq 时才回 safe（safe := wfiReq & icacheSafe & uncacheSafe），再经一拍 DelayN 回后端。
  // ===========================================================================
  assign wfi_safe_now = wfiReqDelay_out & icache_wfi_wfiSafe & instrUncache_wfi_wfiSafe;

  // ===========================================================================
  // §5 ICache ECC 错误上报（给总线错误单元 BEU）
  //   errorReg = RegNext(icache.io.error)；io.error = RegNext(toL1BusErrorUnitInfo(errorReg.valid))：
  //   只有标了 report_to_beu 的错误才上报，地址原样带出。两拍都不复位。
  // ===========================================================================
  logic        err_valid_q;
  logic [47:0] err_paddr_q;
  logic        err_report_q;

  always_ff @(posedge clock) begin
    err_valid_q              <= icache_error_valid;
    err_paddr_q              <= icache_error_bits_paddr;
    err_report_q             <= icache_error_bits_report_to_beu;
    io_error_ecc_error_valid <= err_valid_q & err_report_q;
    io_error_ecc_error_bits  <= err_paddr_q;
  end

  // ===========================================================================
  // §6 性能事件
  //   IFU / IBuffer / ICache / FTQ / BPU / ITLB 的事件经 HPerfMonitor 按 CSR 选择汇成 8 路计数增量，
  //   generatePerfEvent 再打两拍送出（不复位）。
  // ===========================================================================
  localparam int unsigned NUM_PERF = 8;
  logic [5:0] perf_in [NUM_PERF];
  logic [5:0] perf_s1 [NUM_PERF];
  logic [5:0] perf_s2 [NUM_PERF];

  assign perf_in[0] = perfHpm_perf_0_value;
  assign perf_in[1] = perfHpm_perf_1_value;
  assign perf_in[2] = perfHpm_perf_2_value;
  assign perf_in[3] = perfHpm_perf_3_value;
  assign perf_in[4] = perfHpm_perf_4_value;
  assign perf_in[5] = perfHpm_perf_5_value;
  assign perf_in[6] = perfHpm_perf_6_value;
  assign perf_in[7] = perfHpm_perf_7_value;

  always_ff @(posedge clock) begin
    for (int unsigned k = 0; k < NUM_PERF; k++) begin
      perf_s1[k] <= perf_in[k];
      perf_s2[k] <= perf_s1[k];
    end
  end

  assign io_perf_0_value = perf_s2[0];
  assign io_perf_1_value = perf_s2[1];
  assign io_perf_2_value = perf_s2[2];
  assign io_perf_3_value = perf_s2[3];
  assign io_perf_4_value = perf_s2[4];
  assign io_perf_5_value = perf_s2[5];
  assign io_perf_6_value = perf_s2[6];
  assign io_perf_7_value = perf_s2[7];

  // ===========================================================================
  // §7 送往后端的指令流自检（Chisel checkTakenNotConsecutive / checkTakenPC / checkNotTakenPC）
  //   观察对象：IBuffer 每拍交给译码的 6 条（out(i).fire = 后端 ready & IBuffer valid）。三条规则：
  //   (a) taken 的条件分支之后，下一条指令必须属于"下一个" FTQ 项（ftqPtr.value + 1）；
  //   (b) 任何 taken 的跳转（brType != 0）之后，下一条指令的 PC 必须等于预测目标——目标取自 FTQ
  //       写给后端的 PC 存储的镜像 checkPcMem[下一项].startAddr（若下一项就是 FTQ 最新项，目标还没
  //       写进 PC 存储，用 newest_entry_target）；
  //   (c) not-taken 的条件分支之后，下一条 PC 必须是顺序 PC（+2 压缩 / +4）。
  //   一拍里第 i 条满足条件、第 i+1 条也 fire ⇒ 当拍就查；第 i+1 条没 fire（它是本拍最后一条）⇒
  //   把要查的东西记进 prev_* 寄存器，等下一拍第 0 条 fire 时再查。下一拍第 0 条 fire 或重定向冲刷
  //   就清掉记录。违例只触发断言（`ifndef SYNTHESIS），综合视角下整节没有观察者（见文件头）。
  // ===========================================================================
  logic                 out_ready      [DECODE_WIDTH];
  logic                 out_valid      [DECODE_WIDTH];
  logic [VADDR_W-1:0]   out_pc         [DECODE_WIDTH];
  logic                 out_is_rvc     [DECODE_WIDTH];
  logic [1:0]           out_br_type    [DECODE_WIDTH];
  logic                 out_pred_taken [DECODE_WIDTH];
  logic                 out_ptr_flag   [DECODE_WIDTH];
  logic [5:0]           out_ptr_value  [DECODE_WIDTH];

  assign out_ready[0] = io_backend_cfVec_0_ready;
  assign out_ready[1] = io_backend_cfVec_1_ready;
  assign out_ready[2] = io_backend_cfVec_2_ready;
  assign out_ready[3] = io_backend_cfVec_3_ready;
  assign out_ready[4] = io_backend_cfVec_4_ready;
  assign out_ready[5] = io_backend_cfVec_5_ready;
  assign out_valid[0] = ibuffer_out_0_valid;
  assign out_valid[1] = ibuffer_out_1_valid;
  assign out_valid[2] = ibuffer_out_2_valid;
  assign out_valid[3] = ibuffer_out_3_valid;
  assign out_valid[4] = ibuffer_out_4_valid;
  assign out_valid[5] = ibuffer_out_5_valid;
  assign out_pc[0] = ibuffer_out_0_bits_pc;
  assign out_pc[1] = ibuffer_out_1_bits_pc;
  assign out_pc[2] = ibuffer_out_2_bits_pc;
  assign out_pc[3] = ibuffer_out_3_bits_pc;
  assign out_pc[4] = ibuffer_out_4_bits_pc;
  assign out_pc[5] = ibuffer_out_5_bits_pc;
  assign out_is_rvc[0] = ibuffer_out_0_bits_pd_isRVC;
  assign out_is_rvc[1] = ibuffer_out_1_bits_pd_isRVC;
  assign out_is_rvc[2] = ibuffer_out_2_bits_pd_isRVC;
  assign out_is_rvc[3] = ibuffer_out_3_bits_pd_isRVC;
  assign out_is_rvc[4] = ibuffer_out_4_bits_pd_isRVC;
  assign out_is_rvc[5] = ibuffer_out_5_bits_pd_isRVC;
  assign out_br_type[0] = ibuffer_out_0_bits_pd_brType;
  assign out_br_type[1] = ibuffer_out_1_bits_pd_brType;
  assign out_br_type[2] = ibuffer_out_2_bits_pd_brType;
  assign out_br_type[3] = ibuffer_out_3_bits_pd_brType;
  assign out_br_type[4] = ibuffer_out_4_bits_pd_brType;
  assign out_br_type[5] = ibuffer_out_5_bits_pd_brType;
  assign out_pred_taken[0] = ibuffer_out_0_bits_pred_taken;
  assign out_pred_taken[1] = ibuffer_out_1_bits_pred_taken;
  assign out_pred_taken[2] = ibuffer_out_2_bits_pred_taken;
  assign out_pred_taken[3] = ibuffer_out_3_bits_pred_taken;
  assign out_pred_taken[4] = ibuffer_out_4_bits_pred_taken;
  assign out_pred_taken[5] = ibuffer_out_5_bits_pred_taken;
  assign out_ptr_flag[0] = ibuffer_out_0_bits_ftqPtr_flag;
  assign out_ptr_flag[1] = ibuffer_out_1_bits_ftqPtr_flag;
  assign out_ptr_flag[2] = ibuffer_out_2_bits_ftqPtr_flag;
  assign out_ptr_flag[3] = ibuffer_out_3_bits_ftqPtr_flag;
  assign out_ptr_flag[4] = ibuffer_out_4_bits_ftqPtr_flag;
  assign out_ptr_flag[5] = ibuffer_out_5_bits_ftqPtr_flag;
  assign out_ptr_value[0] = ibuffer_out_0_bits_ftqPtr_value;
  assign out_ptr_value[1] = ibuffer_out_1_bits_ftqPtr_value;
  assign out_ptr_value[2] = ibuffer_out_2_bits_ftqPtr_value;
  assign out_ptr_value[3] = ibuffer_out_3_bits_ftqPtr_value;
  assign out_ptr_value[4] = ibuffer_out_4_bits_ftqPtr_value;
  assign out_ptr_value[5] = ibuffer_out_5_bits_ftqPtr_value;

  // ---- checkPcMem：FTQ 写给后端的 PC 存储的镜像（只存 startAddr），无复位 ----
  logic [VADDR_W-1:0] check_pc_mem [FTQ_SIZE];

  always_ff @(posedge clock) begin
    if (ftq_toBackend_pc_mem_wen)
      check_pc_mem[ftq_toBackend_pc_mem_waddr] <= ftq_toBackend_pc_mem_wdata_startAddr;
  end

  // ---- 每条指令的分类与"预测目标" ----
  logic               fire              [DECODE_WIDTH];
  logic               taken_br          [DECODE_WIDTH];   // (a) taken 的条件分支
  logic               taken_cfi         [DECODE_WIDTH];   // (b) taken 的任意跳转
  logic               not_taken_br      [DECODE_WIDTH];   // (c) not-taken 的条件分支
  logic [5:0]         next_ptr_value    [DECODE_WIDTH];   // (ftqPtr + 1).value
  logic [VADDR_W-1:0] predicted_target  [DECODE_WIDTH];   // (b) 应跳到的 PC
  logic [VADDR_W-1:0] sequential_pc     [DECODE_WIDTH];   // (c) 顺序下一条 PC

  always_comb begin
    for (int unsigned i = 0; i < DECODE_WIDTH; i++) begin
      fire[i]           = out_ready[i] & out_valid[i];
      taken_br[i]       = fire[i] & (out_br_type[i] == BR_TYPE_BR) & out_pred_taken[i];
      taken_cfi[i]      = fire[i] & (out_br_type[i] != 2'h0) & out_pred_taken[i];
      not_taken_br[i]   = fire[i] & (out_br_type[i] == BR_TYPE_BR) & ~out_pred_taken[i];
      next_ptr_value[i] = out_ptr_value[i] + 6'h1;
      predicted_target[i] = (ftq_toBackend_newest_entry_ptr_value == out_ptr_value[i])
                            ? ftq_toBackend_newest_entry_target
                            : check_pc_mem[next_ptr_value[i]];
      sequential_pc[i]  = out_pc[i] + (out_is_rvc[i] ? VADDR_W'(2) : VADDR_W'(4));
    end
  end

  // ---- 跨拍记录：本拍最后一条 fire 的指令若命中规则，记下来等下一拍第 0 条 ----
  //   Chisel 的 when 链"后写覆盖先写"：i 从 0 到 5 依次判断，第 i 条（i<5）只在第 i+1 条没 fire 时记录，
  //   第 5 条无条件记录；同一拍多条满足时以下标最大的为准。记录后，下一拍第 0 条 fire 或冲刷即清除。
  logic       taken_ptr_valid_q;      // (a) prevTakenValid
  logic       taken_ptr_flag_q;       //     prevTakenFtqPtr
  logic [5:0] taken_ptr_value_q;
  logic       taken_tgt_valid_q;      // (b) prevTakenValid（checkTakenPC 那份）
  logic       taken_tgt_ptr_flag_q;   //     prevTakenFtqPtr（checkTakenPC 那份）
  logic [5:0] taken_tgt_ptr_value_q;
  logic       not_taken_valid_q;      // (c) prevNotTakenValid
  logic [VADDR_W-1:0] not_taken_pc_q; //     prevNotTakenPC
  logic       not_taken_is_rvc_q;     //     prevIsRVC

  logic       record_taken_br     [DECODE_WIDTH];
  logic       record_taken_cfi    [DECODE_WIDTH];
  logic       record_not_taken_br [DECODE_WIDTH];

  always_comb begin
    for (int unsigned i = 0; i < DECODE_WIDTH; i++) begin
      if (i + 1 < DECODE_WIDTH) begin
        record_taken_br[i]     = taken_br[i]     & ~fire[i + 1];
        record_taken_cfi[i]    = taken_cfi[i]    & ~fire[i + 1];
        record_not_taken_br[i] = not_taken_br[i] & ~fire[i + 1];
      end else begin
        record_taken_br[i]     = taken_br[i];
        record_taken_cfi[i]    = taken_cfi[i];
        record_not_taken_br[i] = not_taken_br[i];
      end
    end
  end

  // 记录内容（不复位）：下标最大的命中者覆盖
  always_ff @(posedge clock) begin
    for (int unsigned i = 0; i < DECODE_WIDTH; i++) begin
      if (record_taken_br[i]) begin
        taken_ptr_flag_q  <= out_ptr_flag[i];
        taken_ptr_value_q <= out_ptr_value[i];
      end
      if (record_taken_cfi[i]) begin
        taken_tgt_ptr_flag_q  <= out_ptr_flag[i];
        taken_tgt_ptr_value_q <= out_ptr_value[i];
      end
      if (record_not_taken_br[i]) begin
        not_taken_pc_q     <= out_pc[i];
        not_taken_is_rvc_q <= out_is_rvc[i];
      end
    end
  end

  // 记录有效位（异步复位为 0）：有新记录则置 1；下一拍第 0 条 fire 或冲刷则清 0（清优先）
  logic any_record_taken_br;
  logic any_record_taken_cfi;
  logic any_record_not_taken_br;

  always_comb begin
    any_record_taken_br     = 1'b0;
    any_record_taken_cfi    = 1'b0;
    any_record_not_taken_br = 1'b0;
    for (int unsigned i = 0; i < DECODE_WIDTH; i++) begin
      any_record_taken_br     |= record_taken_br[i];
      any_record_taken_cfi    |= record_taken_cfi[i];
      any_record_not_taken_br |= record_not_taken_br[i];
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      taken_ptr_valid_q <= 1'b0;
      taken_tgt_valid_q <= 1'b0;
      not_taken_valid_q <= 1'b0;
    end else begin
      taken_ptr_valid_q <= ~(redirect_flush | (taken_ptr_valid_q & fire[0]))
                           & (any_record_taken_br | taken_ptr_valid_q);
      taken_tgt_valid_q <= ~(redirect_flush | (taken_tgt_valid_q & fire[0]))
                           & (any_record_taken_cfi | taken_tgt_valid_q);
      not_taken_valid_q <= ~(redirect_flush | (not_taken_valid_q & fire[0]))
                           & (any_record_not_taken_br | not_taken_valid_q);
    end
  end

  // ---- 违例条件（只给断言用）----
  logic err_taken_ptr     [DECODE_WIDTH];   // (a)
  logic err_taken_target  [DECODE_WIDTH];   // (b)
  logic err_not_taken_pc  [DECODE_WIDTH];   // (c)
  logic [5:0] prev_taken_next_ptr_value;

  assign prev_taken_next_ptr_value = taken_tgt_ptr_value_q + 6'h1;

  always_comb begin
    // 第 0 条：和上一拍的记录比
    err_taken_ptr[0]    = taken_ptr_valid_q & fire[0] & ((taken_ptr_value_q + 6'h1) != out_ptr_value[0]);
    err_taken_target[0] = taken_tgt_valid_q & fire[0]
                          & (check_pc_mem[prev_taken_next_ptr_value] != out_pc[0]);
    err_not_taken_pc[0] = not_taken_valid_q & fire[0]
                          & ((not_taken_pc_q + (not_taken_is_rvc_q ? VADDR_W'(2) : VADDR_W'(4))) != out_pc[0]);
    // 第 i 条（i>=1）：和本拍第 i-1 条比
    for (int unsigned i = 1; i < DECODE_WIDTH; i++) begin
      err_taken_ptr[i]    = taken_br[i - 1] & fire[i] & (next_ptr_value[i - 1] != out_ptr_value[i]);
      err_taken_target[i] = taken_cfi[i - 1] & fire[i] & (predicted_target[i - 1] != out_pc[i]);
      err_not_taken_pc[i] = not_taken_br[i - 1] & fire[i] & (sequential_pc[i - 1] != out_pc[i]);
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clock) begin
    if (~reset) begin
      for (int unsigned i = 0; i < DECODE_WIDTH; i++) begin
        if (err_taken_ptr[i])
          $error("Frontend: taken br should have consecutive ftqPtr (slot %0d)", i);
        if (err_taken_target[i])
          $error("Frontend: taken instr should follow target pc (slot %0d)", i);
        if (err_not_taken_pc[i])
          $error("Frontend: not-taken br should have consecutive pc (slot %0d)", i);
      end
    end
  end
`endif

endmodule

// BEGIN GENERATED(fe_wrapper) —— 由 scripts/gen_frontend.py 从 golden 端口表与例化表产出，勿手改
// golden 同名 wrapper：端口与 golden 逐位同名同序；子模块实例名与 golden 一致；
// 子模块之间的线一律命名为"<驱动实例别名>_<端口名去掉 io_>"。
module Frontend (
  input  logic clock,
  input  logic reset,
  output logic auto_inner_icache_ctrlUnitOpt_in_a_ready,
  input  logic auto_inner_icache_ctrlUnitOpt_in_a_valid,
  input  logic [3:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_opcode,
  input  logic [1:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_size,
  input  logic [4:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_source,
  input  logic [29:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_address,
  input  logic [7:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_mask,
  input  logic [63:0] auto_inner_icache_ctrlUnitOpt_in_a_bits_data,
  input  logic auto_inner_icache_ctrlUnitOpt_in_d_ready,
  output logic auto_inner_icache_ctrlUnitOpt_in_d_valid,
  output logic [3:0] auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode,
  output logic [1:0] auto_inner_icache_ctrlUnitOpt_in_d_bits_size,
  output logic [4:0] auto_inner_icache_ctrlUnitOpt_in_d_bits_source,
  output logic [63:0] auto_inner_icache_ctrlUnitOpt_in_d_bits_data,
  input  logic auto_inner_icache_client_out_a_ready,
  output logic auto_inner_icache_client_out_a_valid,
  output logic [3:0] auto_inner_icache_client_out_a_bits_source,
  output logic [47:0] auto_inner_icache_client_out_a_bits_address,
  input  logic auto_inner_icache_client_out_d_valid,
  input  logic [3:0] auto_inner_icache_client_out_d_bits_opcode,
  input  logic [2:0] auto_inner_icache_client_out_d_bits_size,
  input  logic [3:0] auto_inner_icache_client_out_d_bits_source,
  input  logic [255:0] auto_inner_icache_client_out_d_bits_data,
  input  logic auto_inner_icache_client_out_d_bits_corrupt,
  input  logic auto_inner_instrUncache_client_out_a_ready,
  output logic auto_inner_instrUncache_client_out_a_valid,
  output logic [47:0] auto_inner_instrUncache_client_out_a_bits_address,
  output logic auto_inner_instrUncache_client_out_a_bits_user_memPageType_NC,
  output logic auto_inner_instrUncache_client_out_a_bits_user_memBackType_MM,
  input  logic auto_inner_instrUncache_client_out_d_valid,
  input  logic auto_inner_instrUncache_client_out_d_bits_source,
  input  logic [63:0] auto_inner_instrUncache_client_out_d_bits_data,
  input  logic auto_inner_instrUncache_client_out_d_bits_corrupt,
  input  logic [5:0] io_hartId,
  input  logic [47:0] io_reset_vector,
  input  logic io_fencei,
  input  logic io_ptw_req_0_ready,
  output logic io_ptw_req_0_valid,
  output logic [37:0] io_ptw_req_0_bits_vpn,
  output logic [1:0] io_ptw_req_0_bits_s2xlate,
  output logic io_ptw_resp_ready,
  input  logic io_ptw_resp_valid,
  input  logic [1:0] io_ptw_resp_bits_s2xlate,
  input  logic [34:0] io_ptw_resp_bits_s1_entry_tag,
  input  logic [15:0] io_ptw_resp_bits_s1_entry_asid,
  input  logic [13:0] io_ptw_resp_bits_s1_entry_vmid,
  input  logic io_ptw_resp_bits_s1_entry_n,
  input  logic [1:0] io_ptw_resp_bits_s1_entry_pbmt,
  input  logic io_ptw_resp_bits_s1_entry_perm_d,
  input  logic io_ptw_resp_bits_s1_entry_perm_a,
  input  logic io_ptw_resp_bits_s1_entry_perm_g,
  input  logic io_ptw_resp_bits_s1_entry_perm_u,
  input  logic io_ptw_resp_bits_s1_entry_perm_x,
  input  logic io_ptw_resp_bits_s1_entry_perm_w,
  input  logic io_ptw_resp_bits_s1_entry_perm_r,
  input  logic [1:0] io_ptw_resp_bits_s1_entry_level,
  input  logic io_ptw_resp_bits_s1_entry_v,
  input  logic [40:0] io_ptw_resp_bits_s1_entry_ppn,
  input  logic [2:0] io_ptw_resp_bits_s1_addr_low,
  input  logic [2:0] io_ptw_resp_bits_s1_ppn_low_0,
  input  logic [2:0] io_ptw_resp_bits_s1_ppn_low_1,
  input  logic [2:0] io_ptw_resp_bits_s1_ppn_low_2,
  input  logic [2:0] io_ptw_resp_bits_s1_ppn_low_3,
  input  logic [2:0] io_ptw_resp_bits_s1_ppn_low_4,
  input  logic [2:0] io_ptw_resp_bits_s1_ppn_low_5,
  input  logic [2:0] io_ptw_resp_bits_s1_ppn_low_6,
  input  logic [2:0] io_ptw_resp_bits_s1_ppn_low_7,
  input  logic io_ptw_resp_bits_s1_valididx_0,
  input  logic io_ptw_resp_bits_s1_valididx_1,
  input  logic io_ptw_resp_bits_s1_valididx_2,
  input  logic io_ptw_resp_bits_s1_valididx_3,
  input  logic io_ptw_resp_bits_s1_valididx_4,
  input  logic io_ptw_resp_bits_s1_valididx_5,
  input  logic io_ptw_resp_bits_s1_valididx_6,
  input  logic io_ptw_resp_bits_s1_valididx_7,
  input  logic io_ptw_resp_bits_s1_pteidx_0,
  input  logic io_ptw_resp_bits_s1_pteidx_1,
  input  logic io_ptw_resp_bits_s1_pteidx_2,
  input  logic io_ptw_resp_bits_s1_pteidx_3,
  input  logic io_ptw_resp_bits_s1_pteidx_4,
  input  logic io_ptw_resp_bits_s1_pteidx_5,
  input  logic io_ptw_resp_bits_s1_pteidx_6,
  input  logic io_ptw_resp_bits_s1_pteidx_7,
  input  logic io_ptw_resp_bits_s1_pf,
  input  logic io_ptw_resp_bits_s1_af,
  input  logic [37:0] io_ptw_resp_bits_s2_entry_tag,
  input  logic [13:0] io_ptw_resp_bits_s2_entry_vmid,
  input  logic io_ptw_resp_bits_s2_entry_n,
  input  logic [1:0] io_ptw_resp_bits_s2_entry_pbmt,
  input  logic [37:0] io_ptw_resp_bits_s2_entry_ppn,
  input  logic io_ptw_resp_bits_s2_entry_perm_d,
  input  logic io_ptw_resp_bits_s2_entry_perm_a,
  input  logic io_ptw_resp_bits_s2_entry_perm_g,
  input  logic io_ptw_resp_bits_s2_entry_perm_u,
  input  logic io_ptw_resp_bits_s2_entry_perm_x,
  input  logic io_ptw_resp_bits_s2_entry_perm_w,
  input  logic io_ptw_resp_bits_s2_entry_perm_r,
  input  logic [1:0] io_ptw_resp_bits_s2_entry_level,
  input  logic io_ptw_resp_bits_s2_gpf,
  input  logic io_ptw_resp_bits_s2_gaf,
  input  logic io_backend_cfVec_0_ready,
  output logic io_backend_cfVec_0_valid,
  output logic [31:0] io_backend_cfVec_0_bits_instr,
  output logic [49:0] io_backend_cfVec_0_bits_pc,
  output logic [9:0] io_backend_cfVec_0_bits_foldpc,
  output logic io_backend_cfVec_0_bits_exceptionVec_1,
  output logic io_backend_cfVec_0_bits_exceptionVec_2,
  output logic io_backend_cfVec_0_bits_exceptionVec_12,
  output logic io_backend_cfVec_0_bits_exceptionVec_20,
  output logic io_backend_cfVec_0_bits_backendException,
  output logic io_backend_cfVec_0_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_backend_cfVec_0_bits_trigger,
  output logic io_backend_cfVec_0_bits_pd_valid,
  output logic io_backend_cfVec_0_bits_pd_isRVC,
  output logic [1:0] io_backend_cfVec_0_bits_pd_brType,
  output logic io_backend_cfVec_0_bits_pd_isCall,
  output logic io_backend_cfVec_0_bits_pd_isRet,
  output logic io_backend_cfVec_0_bits_pred_taken,
  output logic io_backend_cfVec_0_bits_crossPageIPFFix,
  output logic io_backend_cfVec_0_bits_ftqPtr_flag,
  output logic [5:0] io_backend_cfVec_0_bits_ftqPtr_value,
  output logic [3:0] io_backend_cfVec_0_bits_ftqOffset,
  output logic io_backend_cfVec_0_bits_isLastInFtqEntry,
  output logic [55:0] io_backend_cfVec_0_bits_debug_seqNum_seqNum,
  output logic [7:0] io_backend_cfVec_0_bits_debug_seqNum_uopIdx,
  input  logic io_backend_cfVec_1_ready,
  output logic io_backend_cfVec_1_valid,
  output logic [31:0] io_backend_cfVec_1_bits_instr,
  output logic [49:0] io_backend_cfVec_1_bits_pc,
  output logic [9:0] io_backend_cfVec_1_bits_foldpc,
  output logic io_backend_cfVec_1_bits_exceptionVec_1,
  output logic io_backend_cfVec_1_bits_exceptionVec_2,
  output logic io_backend_cfVec_1_bits_exceptionVec_12,
  output logic io_backend_cfVec_1_bits_exceptionVec_20,
  output logic io_backend_cfVec_1_bits_backendException,
  output logic io_backend_cfVec_1_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_backend_cfVec_1_bits_trigger,
  output logic io_backend_cfVec_1_bits_pd_valid,
  output logic io_backend_cfVec_1_bits_pd_isRVC,
  output logic [1:0] io_backend_cfVec_1_bits_pd_brType,
  output logic io_backend_cfVec_1_bits_pd_isCall,
  output logic io_backend_cfVec_1_bits_pd_isRet,
  output logic io_backend_cfVec_1_bits_pred_taken,
  output logic io_backend_cfVec_1_bits_crossPageIPFFix,
  output logic io_backend_cfVec_1_bits_ftqPtr_flag,
  output logic [5:0] io_backend_cfVec_1_bits_ftqPtr_value,
  output logic [3:0] io_backend_cfVec_1_bits_ftqOffset,
  output logic io_backend_cfVec_1_bits_isLastInFtqEntry,
  output logic [55:0] io_backend_cfVec_1_bits_debug_seqNum_seqNum,
  output logic [7:0] io_backend_cfVec_1_bits_debug_seqNum_uopIdx,
  input  logic io_backend_cfVec_2_ready,
  output logic io_backend_cfVec_2_valid,
  output logic [31:0] io_backend_cfVec_2_bits_instr,
  output logic [49:0] io_backend_cfVec_2_bits_pc,
  output logic [9:0] io_backend_cfVec_2_bits_foldpc,
  output logic io_backend_cfVec_2_bits_exceptionVec_1,
  output logic io_backend_cfVec_2_bits_exceptionVec_2,
  output logic io_backend_cfVec_2_bits_exceptionVec_12,
  output logic io_backend_cfVec_2_bits_exceptionVec_20,
  output logic io_backend_cfVec_2_bits_backendException,
  output logic io_backend_cfVec_2_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_backend_cfVec_2_bits_trigger,
  output logic io_backend_cfVec_2_bits_pd_valid,
  output logic io_backend_cfVec_2_bits_pd_isRVC,
  output logic [1:0] io_backend_cfVec_2_bits_pd_brType,
  output logic io_backend_cfVec_2_bits_pd_isCall,
  output logic io_backend_cfVec_2_bits_pd_isRet,
  output logic io_backend_cfVec_2_bits_pred_taken,
  output logic io_backend_cfVec_2_bits_crossPageIPFFix,
  output logic io_backend_cfVec_2_bits_ftqPtr_flag,
  output logic [5:0] io_backend_cfVec_2_bits_ftqPtr_value,
  output logic [3:0] io_backend_cfVec_2_bits_ftqOffset,
  output logic io_backend_cfVec_2_bits_isLastInFtqEntry,
  output logic [55:0] io_backend_cfVec_2_bits_debug_seqNum_seqNum,
  output logic [7:0] io_backend_cfVec_2_bits_debug_seqNum_uopIdx,
  input  logic io_backend_cfVec_3_ready,
  output logic io_backend_cfVec_3_valid,
  output logic [31:0] io_backend_cfVec_3_bits_instr,
  output logic [49:0] io_backend_cfVec_3_bits_pc,
  output logic [9:0] io_backend_cfVec_3_bits_foldpc,
  output logic io_backend_cfVec_3_bits_exceptionVec_1,
  output logic io_backend_cfVec_3_bits_exceptionVec_2,
  output logic io_backend_cfVec_3_bits_exceptionVec_12,
  output logic io_backend_cfVec_3_bits_exceptionVec_20,
  output logic io_backend_cfVec_3_bits_backendException,
  output logic io_backend_cfVec_3_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_backend_cfVec_3_bits_trigger,
  output logic io_backend_cfVec_3_bits_pd_valid,
  output logic io_backend_cfVec_3_bits_pd_isRVC,
  output logic [1:0] io_backend_cfVec_3_bits_pd_brType,
  output logic io_backend_cfVec_3_bits_pd_isCall,
  output logic io_backend_cfVec_3_bits_pd_isRet,
  output logic io_backend_cfVec_3_bits_pred_taken,
  output logic io_backend_cfVec_3_bits_crossPageIPFFix,
  output logic io_backend_cfVec_3_bits_ftqPtr_flag,
  output logic [5:0] io_backend_cfVec_3_bits_ftqPtr_value,
  output logic [3:0] io_backend_cfVec_3_bits_ftqOffset,
  output logic io_backend_cfVec_3_bits_isLastInFtqEntry,
  output logic [55:0] io_backend_cfVec_3_bits_debug_seqNum_seqNum,
  output logic [7:0] io_backend_cfVec_3_bits_debug_seqNum_uopIdx,
  input  logic io_backend_cfVec_4_ready,
  output logic io_backend_cfVec_4_valid,
  output logic [31:0] io_backend_cfVec_4_bits_instr,
  output logic [49:0] io_backend_cfVec_4_bits_pc,
  output logic [9:0] io_backend_cfVec_4_bits_foldpc,
  output logic io_backend_cfVec_4_bits_exceptionVec_1,
  output logic io_backend_cfVec_4_bits_exceptionVec_2,
  output logic io_backend_cfVec_4_bits_exceptionVec_12,
  output logic io_backend_cfVec_4_bits_exceptionVec_20,
  output logic io_backend_cfVec_4_bits_backendException,
  output logic io_backend_cfVec_4_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_backend_cfVec_4_bits_trigger,
  output logic io_backend_cfVec_4_bits_pd_valid,
  output logic io_backend_cfVec_4_bits_pd_isRVC,
  output logic [1:0] io_backend_cfVec_4_bits_pd_brType,
  output logic io_backend_cfVec_4_bits_pd_isCall,
  output logic io_backend_cfVec_4_bits_pd_isRet,
  output logic io_backend_cfVec_4_bits_pred_taken,
  output logic io_backend_cfVec_4_bits_crossPageIPFFix,
  output logic io_backend_cfVec_4_bits_ftqPtr_flag,
  output logic [5:0] io_backend_cfVec_4_bits_ftqPtr_value,
  output logic [3:0] io_backend_cfVec_4_bits_ftqOffset,
  output logic io_backend_cfVec_4_bits_isLastInFtqEntry,
  output logic [55:0] io_backend_cfVec_4_bits_debug_seqNum_seqNum,
  output logic [7:0] io_backend_cfVec_4_bits_debug_seqNum_uopIdx,
  input  logic io_backend_cfVec_5_ready,
  output logic io_backend_cfVec_5_valid,
  output logic [31:0] io_backend_cfVec_5_bits_instr,
  output logic [49:0] io_backend_cfVec_5_bits_pc,
  output logic [9:0] io_backend_cfVec_5_bits_foldpc,
  output logic io_backend_cfVec_5_bits_exceptionVec_1,
  output logic io_backend_cfVec_5_bits_exceptionVec_2,
  output logic io_backend_cfVec_5_bits_exceptionVec_12,
  output logic io_backend_cfVec_5_bits_exceptionVec_20,
  output logic io_backend_cfVec_5_bits_backendException,
  output logic io_backend_cfVec_5_bits_satpFlushFirstFetchFault,
  output logic [3:0] io_backend_cfVec_5_bits_trigger,
  output logic io_backend_cfVec_5_bits_pd_valid,
  output logic io_backend_cfVec_5_bits_pd_isRVC,
  output logic [1:0] io_backend_cfVec_5_bits_pd_brType,
  output logic io_backend_cfVec_5_bits_pd_isCall,
  output logic io_backend_cfVec_5_bits_pd_isRet,
  output logic io_backend_cfVec_5_bits_pred_taken,
  output logic io_backend_cfVec_5_bits_crossPageIPFFix,
  output logic io_backend_cfVec_5_bits_ftqPtr_flag,
  output logic [5:0] io_backend_cfVec_5_bits_ftqPtr_value,
  output logic [3:0] io_backend_cfVec_5_bits_ftqOffset,
  output logic io_backend_cfVec_5_bits_isLastInFtqEntry,
  output logic [55:0] io_backend_cfVec_5_bits_debug_seqNum_seqNum,
  output logic [7:0] io_backend_cfVec_5_bits_debug_seqNum_uopIdx,
  output logic [5:0] io_backend_stallReason_reason_0,
  output logic [5:0] io_backend_stallReason_reason_1,
  output logic [5:0] io_backend_stallReason_reason_2,
  output logic [5:0] io_backend_stallReason_reason_3,
  output logic [5:0] io_backend_stallReason_reason_4,
  output logic [5:0] io_backend_stallReason_reason_5,
  input  logic io_backend_stallReason_backReason_valid,
  input  logic [5:0] io_backend_stallReason_backReason_bits,
  output logic io_backend_fromFtq_pc_mem_wen,
  output logic [5:0] io_backend_fromFtq_pc_mem_waddr,
  output logic [49:0] io_backend_fromFtq_pc_mem_wdata_startAddr,
  output logic io_backend_fromFtq_newest_entry_en,
  output logic [49:0] io_backend_fromFtq_newest_entry_target,
  output logic [5:0] io_backend_fromFtq_newest_entry_ptr_value,
  output logic io_backend_fromIfu_gpaddrMem_wen,
  output logic [5:0] io_backend_fromIfu_gpaddrMem_waddr,
  output logic [55:0] io_backend_fromIfu_gpaddrMem_wdata_gpaddr,
  output logic io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE,
  input  logic io_backend_toFtq_rob_commits_0_valid,
  input  logic [2:0] io_backend_toFtq_rob_commits_0_bits_commitType,
  input  logic io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_rob_commits_0_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_rob_commits_0_bits_ftqOffset,
  input  logic io_backend_toFtq_rob_commits_1_valid,
  input  logic [2:0] io_backend_toFtq_rob_commits_1_bits_commitType,
  input  logic io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_rob_commits_1_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_rob_commits_1_bits_ftqOffset,
  input  logic io_backend_toFtq_rob_commits_2_valid,
  input  logic [2:0] io_backend_toFtq_rob_commits_2_bits_commitType,
  input  logic io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_rob_commits_2_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_rob_commits_2_bits_ftqOffset,
  input  logic io_backend_toFtq_rob_commits_3_valid,
  input  logic [2:0] io_backend_toFtq_rob_commits_3_bits_commitType,
  input  logic io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_rob_commits_3_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_rob_commits_3_bits_ftqOffset,
  input  logic io_backend_toFtq_rob_commits_4_valid,
  input  logic [2:0] io_backend_toFtq_rob_commits_4_bits_commitType,
  input  logic io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_rob_commits_4_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_rob_commits_4_bits_ftqOffset,
  input  logic io_backend_toFtq_rob_commits_5_valid,
  input  logic [2:0] io_backend_toFtq_rob_commits_5_bits_commitType,
  input  logic io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_rob_commits_5_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_rob_commits_5_bits_ftqOffset,
  input  logic io_backend_toFtq_rob_commits_6_valid,
  input  logic [2:0] io_backend_toFtq_rob_commits_6_bits_commitType,
  input  logic io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_rob_commits_6_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_rob_commits_6_bits_ftqOffset,
  input  logic io_backend_toFtq_rob_commits_7_valid,
  input  logic [2:0] io_backend_toFtq_rob_commits_7_bits_commitType,
  input  logic io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_rob_commits_7_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_rob_commits_7_bits_ftqOffset,
  input  logic io_backend_toFtq_redirect_valid,
  input  logic io_backend_toFtq_redirect_bits_ftqIdx_flag,
  input  logic [5:0] io_backend_toFtq_redirect_bits_ftqIdx_value,
  input  logic [3:0] io_backend_toFtq_redirect_bits_ftqOffset,
  input  logic io_backend_toFtq_redirect_bits_level,
  input  logic [49:0] io_backend_toFtq_redirect_bits_cfiUpdate_pc,
  input  logic [49:0] io_backend_toFtq_redirect_bits_cfiUpdate_target,
  input  logic io_backend_toFtq_redirect_bits_cfiUpdate_taken,
  input  logic io_backend_toFtq_redirect_bits_cfiUpdate_isMisPred,
  input  logic io_backend_toFtq_redirect_bits_cfiUpdate_backendIGPF,
  input  logic io_backend_toFtq_redirect_bits_cfiUpdate_backendIPF,
  input  logic io_backend_toFtq_redirect_bits_cfiUpdate_backendIAF,
  input  logic io_backend_toFtq_redirect_bits_satpFlush,
  input  logic io_backend_toFtq_redirect_bits_debugIsCtrl,
  input  logic io_backend_toFtq_redirect_bits_debugIsMemVio,
  input  logic io_backend_toFtq_ftqIdxAhead_0_valid,
  input  logic [5:0] io_backend_toFtq_ftqIdxAhead_0_bits_value,
  input  logic [2:0] io_backend_toFtq_ftqIdxSelOH_bits,
  input  logic io_backend_canAccept,
  input  logic io_backend_wfi_wfiReq,
  output logic io_backend_wfi_wfiSafe,
  input  logic io_softPrefetch_0_valid,
  input  logic [49:0] io_softPrefetch_0_bits_vaddr,
  input  logic io_softPrefetch_1_valid,
  input  logic [49:0] io_softPrefetch_1_bits_vaddr,
  input  logic io_softPrefetch_2_valid,
  input  logic [49:0] io_softPrefetch_2_bits_vaddr,
  input  logic io_sfence_valid,
  input  logic io_sfence_bits_rs1,
  input  logic io_sfence_bits_rs2,
  input  logic [49:0] io_sfence_bits_addr,
  input  logic [15:0] io_sfence_bits_id,
  input  logic io_sfence_bits_flushPipe,
  input  logic io_sfence_bits_hv,
  input  logic io_sfence_bits_hg,
  input  logic [3:0] io_tlbCsr_satp_mode,
  input  logic [15:0] io_tlbCsr_satp_asid,
  input  logic [43:0] io_tlbCsr_satp_ppn,
  input  logic io_tlbCsr_satp_changed,
  input  logic [3:0] io_tlbCsr_vsatp_mode,
  input  logic [15:0] io_tlbCsr_vsatp_asid,
  input  logic [43:0] io_tlbCsr_vsatp_ppn,
  input  logic io_tlbCsr_vsatp_changed,
  input  logic [3:0] io_tlbCsr_hgatp_mode,
  input  logic [15:0] io_tlbCsr_hgatp_vmid,
  input  logic [43:0] io_tlbCsr_hgatp_ppn,
  input  logic io_tlbCsr_hgatp_changed,
  input  logic io_tlbCsr_mbmc_BME,
  input  logic io_tlbCsr_mbmc_CMODE,
  input  logic io_tlbCsr_priv_mxr,
  input  logic io_tlbCsr_priv_sum,
  input  logic io_tlbCsr_priv_vmxr,
  input  logic io_tlbCsr_priv_vsum,
  input  logic io_tlbCsr_priv_virt,
  input  logic io_tlbCsr_priv_virt_changed,
  input  logic io_tlbCsr_priv_spvp,
  input  logic [1:0] io_tlbCsr_priv_imode,
  input  logic [1:0] io_tlbCsr_priv_dmode,
  input  logic io_tlbCsr_priv_debug,
  input  logic [1:0] io_tlbCsr_pmm_mseccfg,
  input  logic [1:0] io_tlbCsr_pmm_menvcfg,
  input  logic [1:0] io_tlbCsr_pmm_henvcfg,
  input  logic [1:0] io_tlbCsr_pmm_hstatus,
  input  logic [1:0] io_tlbCsr_pmm_senvcfg,
  input  logic io_csrCtrl_pf_ctrl_l1I_pf_enable,
  input  logic io_csrCtrl_bp_ctrl_ubtb_enable,
  input  logic io_csrCtrl_bp_ctrl_btb_enable,
  input  logic io_csrCtrl_bp_ctrl_tage_enable,
  input  logic io_csrCtrl_bp_ctrl_sc_enable,
  input  logic io_csrCtrl_bp_ctrl_ras_enable,
  input  logic [21:0] io_csrCtrl_sbuffer_timeout,
  input  logic io_csrCtrl_ldld_vio_check_enable,
  input  logic io_csrCtrl_cache_error_enable,
  input  logic io_csrCtrl_hd_misalign_st_enable,
  input  logic io_csrCtrl_hd_misalign_ld_enable,
  input  logic io_csrCtrl_distribute_csr_w_valid,
  input  logic [11:0] io_csrCtrl_distribute_csr_w_bits_addr,
  input  logic [63:0] io_csrCtrl_distribute_csr_w_bits_data,
  input  logic io_csrCtrl_frontend_trigger_tUpdate_valid,
  input  logic [1:0] io_csrCtrl_frontend_trigger_tUpdate_bits_addr,
  input  logic [1:0] io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_matchType,
  input  logic io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_select,
  input  logic [3:0] io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_action,
  input  logic io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_chain,
  input  logic [63:0] io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2,
  input  logic io_csrCtrl_frontend_trigger_tEnableVec_0,
  input  logic io_csrCtrl_frontend_trigger_tEnableVec_1,
  input  logic io_csrCtrl_frontend_trigger_tEnableVec_2,
  input  logic io_csrCtrl_frontend_trigger_tEnableVec_3,
  input  logic io_csrCtrl_frontend_trigger_debugMode,
  input  logic io_csrCtrl_frontend_trigger_triggerCanRaiseBpExp,
  input  logic io_csrCtrl_mem_trigger_tUpdate_valid,
  input  logic [1:0] io_csrCtrl_mem_trigger_tUpdate_bits_addr,
  input  logic [1:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType,
  input  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select,
  input  logic [3:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action,
  input  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain,
  input  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store,
  input  logic io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load,
  input  logic [63:0] io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2,
  input  logic io_csrCtrl_mem_trigger_tEnableVec_0,
  input  logic io_csrCtrl_mem_trigger_tEnableVec_1,
  input  logic io_csrCtrl_mem_trigger_tEnableVec_2,
  input  logic io_csrCtrl_mem_trigger_tEnableVec_3,
  input  logic io_csrCtrl_mem_trigger_debugMode,
  input  logic io_csrCtrl_mem_trigger_triggerCanRaiseBpExp,
  input  logic io_csrCtrl_fsIsOff,
  output logic io_error_ecc_error_valid,
  output logic [47:0] io_error_ecc_error_bits,
  output logic io_resetInFrontend,
  input  logic io_dft_ram_hold,
  input  logic io_dft_ram_bypass,
  input  logic io_dft_ram_bp_clken,
  input  logic io_dft_ram_aux_clk,
  input  logic io_dft_ram_aux_ckbp,
  input  logic io_dft_ram_mcp_hold,
  input  logic io_dft_cgen,
  output logic [5:0] io_perf_0_value,
  output logic [5:0] io_perf_1_value,
  output logic [5:0] io_perf_2_value,
  output logic [5:0] io_perf_3_value,
  output logic [5:0] io_perf_4_value,
  output logic [5:0] io_perf_5_value,
  output logic [5:0] io_perf_6_value,
  output logic [5:0] io_perf_7_value,
  output logic [600:0] gatewayIn_packed_0_bore,
  output logic [600:0] gatewayIn_packed_1_bore,
  output logic [600:0] gatewayIn_packed_2_bore,
  output logic [338:0] gatewayIn_packed_3_bore,
  output logic [338:0] gatewayIn_packed_4_bore,
  output logic [338:0] gatewayIn_packed_5_bore
);

  // ===========================================================================
  // 子模块输出线（按驱动实例分组；只声明有读者的那些——直接接顶层输出的口不经线）
  // ===========================================================================
  // ---- bpu（inner_bpu）----
  logic bpu_bpu_to_ftq_resp_valid;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s1_pc_3;
  logic [63:0] bpu_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle;
  logic bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0;
  logic bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1;
  logic bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0;
  logic bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr;
  logic bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr;
  logic bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing;
  logic bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_hit;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s2_pc_3;
  logic bpu_bpu_to_ftq_resp_bits_s2_valid_3;
  logic bpu_bpu_to_ftq_resp_bits_s2_hasRedirect_3;
  logic bpu_bpu_to_ftq_resp_bits_s2_ftq_idx_flag;
  logic [5:0] bpu_bpu_to_ftq_resp_bits_s2_ftq_idx_value;
  logic [63:0] bpu_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle;
  logic bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0;
  logic bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1;
  logic bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0;
  logic bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr;
  logic bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr;
  logic bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing;
  logic bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_hit;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s3_pc_0;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s3_pc_3;
  logic bpu_bpu_to_ftq_resp_bits_s3_valid_3;
  logic bpu_bpu_to_ftq_resp_bits_s3_hasRedirect_3;
  logic bpu_bpu_to_ftq_resp_bits_s3_ftq_idx_flag;
  logic [5:0] bpu_bpu_to_ftq_resp_bits_s3_ftq_idx_value;
  logic [63:0] bpu_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle;
  logic bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0;
  logic bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1;
  logic bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0;
  logic bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr;
  logic bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr;
  logic bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing;
  logic bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_hit;
  logic [515:0] bpu_bpu_to_ftq_resp_bits_last_stage_meta;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;
  logic [7:0] bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp;
  logic [2:0] bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag;
  logic [4:0] bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag;
  logic [4:0] bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag;
  logic [4:0] bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value;
  logic [49:0] bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid;
  logic [11:0] bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower;
  logic [1:0] bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid;
  logic [19:0] bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower;
  logic [1:0] bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat;
  logic [3:0] bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0;
  logic bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_1;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_2;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_3;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_4;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_5;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_6;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_7;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_8;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_9;
  logic bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_12;
  logic [5:0] bpu_perf_0_value;
  logic [5:0] bpu_perf_1_value;
  logic [5:0] bpu_perf_2_value;
  logic [5:0] bpu_perf_3_value;
  logic [5:0] bpu_perf_4_value;
  logic [5:0] bpu_perf_5_value;
  logic [5:0] bpu_perf_6_value;
  logic mbistBd5_ack;
  logic [39:0] mbistBd5_outdata;
  logic mbistBd6_ack;
  logic [23:0] mbistBd6_outdata;
  logic mbistBd7_ack;
  logic [23:0] mbistBd7_outdata;
  logic mbistBd8_ack;
  logic [23:0] mbistBd8_outdata;
  logic mbistBd9_ack;
  logic [23:0] mbistBd9_outdata;
  logic mbistBd10_ack;
  logic [23:0] mbistBd10_outdata;
  logic mbistBd11_ack;
  logic [75:0] mbistBd11_outdata;
  logic mbistBd12_ack;
  logic [75:0] mbistBd12_outdata;
  logic mbistBd13_ack;
  logic [75:0] mbistBd13_outdata;
  logic mbistBd14_ack;
  logic [75:0] mbistBd14_outdata;
  logic mbistBd15_ack;
  logic [75:0] mbistBd15_outdata;
  // ---- ftq（inner_ftq）----
  logic ftq_fromBpu_resp_ready;
  logic ftq_toBpu_redirect_valid;
  logic ftq_toBpu_redirect_bits_level;
  logic [49:0] ftq_toBpu_redirect_bits_cfiUpdate_pc;
  logic ftq_toBpu_redirect_bits_cfiUpdate_pd_valid;
  logic ftq_toBpu_redirect_bits_cfiUpdate_pd_isRVC;
  logic ftq_toBpu_redirect_bits_cfiUpdate_pd_isCall;
  logic ftq_toBpu_redirect_bits_cfiUpdate_pd_isRet;
  logic [3:0] ftq_toBpu_redirect_bits_cfiUpdate_ssp;
  logic [2:0] ftq_toBpu_redirect_bits_cfiUpdate_sctr;
  logic ftq_toBpu_redirect_bits_cfiUpdate_TOSW_flag;
  logic [4:0] ftq_toBpu_redirect_bits_cfiUpdate_TOSW_value;
  logic ftq_toBpu_redirect_bits_cfiUpdate_TOSR_flag;
  logic [4:0] ftq_toBpu_redirect_bits_cfiUpdate_TOSR_value;
  logic ftq_toBpu_redirect_bits_cfiUpdate_NOS_flag;
  logic [4:0] ftq_toBpu_redirect_bits_cfiUpdate_NOS_value;
  logic ftq_toBpu_redirect_bits_cfiUpdate_histPtr_flag;
  logic [7:0] ftq_toBpu_redirect_bits_cfiUpdate_histPtr_value;
  logic ftq_toBpu_redirect_bits_cfiUpdate_br_hit;
  logic ftq_toBpu_redirect_bits_cfiUpdate_jr_hit;
  logic ftq_toBpu_redirect_bits_cfiUpdate_sc_hit;
  logic [49:0] ftq_toBpu_redirect_bits_cfiUpdate_target;
  logic ftq_toBpu_redirect_bits_cfiUpdate_taken;
  logic [1:0] ftq_toBpu_redirect_bits_cfiUpdate_shift;
  logic ftq_toBpu_redirect_bits_cfiUpdate_addIntoHist;
  logic ftq_toBpu_redirect_bits_debugIsCtrl;
  logic ftq_toBpu_redirect_bits_debugIsMemVio;
  logic ftq_toBpu_redirect_bits_BTBMissBubble;
  logic ftq_toBpu_update_valid;
  logic [49:0] ftq_toBpu_update_bits_pc;
  logic [7:0] ftq_toBpu_update_bits_spec_info_histPtr_value;
  logic ftq_toBpu_update_bits_ftb_entry_isCall;
  logic ftq_toBpu_update_bits_ftb_entry_isRet;
  logic ftq_toBpu_update_bits_ftb_entry_isJalr;
  logic ftq_toBpu_update_bits_ftb_entry_valid;
  logic [3:0] ftq_toBpu_update_bits_ftb_entry_brSlots_0_offset;
  logic ftq_toBpu_update_bits_ftb_entry_brSlots_0_sharing;
  logic ftq_toBpu_update_bits_ftb_entry_brSlots_0_valid;
  logic [11:0] ftq_toBpu_update_bits_ftb_entry_brSlots_0_lower;
  logic [1:0] ftq_toBpu_update_bits_ftb_entry_brSlots_0_tarStat;
  logic [3:0] ftq_toBpu_update_bits_ftb_entry_tailSlot_offset;
  logic ftq_toBpu_update_bits_ftb_entry_tailSlot_sharing;
  logic ftq_toBpu_update_bits_ftb_entry_tailSlot_valid;
  logic [19:0] ftq_toBpu_update_bits_ftb_entry_tailSlot_lower;
  logic [1:0] ftq_toBpu_update_bits_ftb_entry_tailSlot_tarStat;
  logic [3:0] ftq_toBpu_update_bits_ftb_entry_pftAddr;
  logic ftq_toBpu_update_bits_ftb_entry_carry;
  logic ftq_toBpu_update_bits_ftb_entry_last_may_be_rvi_call;
  logic ftq_toBpu_update_bits_ftb_entry_strong_bias_0;
  logic ftq_toBpu_update_bits_ftb_entry_strong_bias_1;
  logic ftq_toBpu_update_bits_cfi_idx_valid;
  logic [3:0] ftq_toBpu_update_bits_cfi_idx_bits;
  logic ftq_toBpu_update_bits_br_taken_mask_0;
  logic ftq_toBpu_update_bits_br_taken_mask_1;
  logic ftq_toBpu_update_bits_jmp_taken;
  logic ftq_toBpu_update_bits_mispred_mask_0;
  logic ftq_toBpu_update_bits_mispred_mask_1;
  logic ftq_toBpu_update_bits_mispred_mask_2;
  logic ftq_toBpu_update_bits_false_hit;
  logic ftq_toBpu_update_bits_old_entry;
  logic [515:0] ftq_toBpu_update_bits_meta;
  logic [49:0] ftq_toBpu_update_bits_full_target;
  logic ftq_toBpu_enq_ptr_flag;
  logic [5:0] ftq_toBpu_enq_ptr_value;
  logic ftq_toBpu_redirctFromIFU;
  logic ftq_toIfu_req_valid;
  logic [49:0] ftq_toIfu_req_bits_startAddr;
  logic [49:0] ftq_toIfu_req_bits_nextlineStart;
  logic [49:0] ftq_toIfu_req_bits_nextStartAddr;
  logic ftq_toIfu_req_bits_ftqIdx_flag;
  logic [5:0] ftq_toIfu_req_bits_ftqIdx_value;
  logic ftq_toIfu_req_bits_ftqOffset_valid;
  logic [3:0] ftq_toIfu_req_bits_ftqOffset_bits;
  logic ftq_toIfu_req_bits_topdown_info_reasons_0;
  logic ftq_toIfu_req_bits_topdown_info_reasons_1;
  logic ftq_toIfu_req_bits_topdown_info_reasons_2;
  logic ftq_toIfu_req_bits_topdown_info_reasons_3;
  logic ftq_toIfu_req_bits_topdown_info_reasons_4;
  logic ftq_toIfu_req_bits_topdown_info_reasons_5;
  logic ftq_toIfu_req_bits_topdown_info_reasons_6;
  logic ftq_toIfu_req_bits_topdown_info_reasons_7;
  logic ftq_toIfu_req_bits_topdown_info_reasons_8;
  logic ftq_toIfu_req_bits_topdown_info_reasons_9;
  logic ftq_toIfu_req_bits_topdown_info_reasons_10;
  logic ftq_toIfu_req_bits_topdown_info_reasons_11;
  logic ftq_toIfu_req_bits_topdown_info_reasons_12;
  logic ftq_toIfu_req_bits_topdown_info_reasons_13;
  logic ftq_toIfu_req_bits_topdown_info_reasons_14;
  logic ftq_toIfu_req_bits_topdown_info_reasons_15;
  logic ftq_toIfu_req_bits_topdown_info_reasons_16;
  logic ftq_toIfu_req_bits_topdown_info_reasons_17;
  logic ftq_toIfu_req_bits_topdown_info_reasons_18;
  logic ftq_toIfu_req_bits_topdown_info_reasons_19;
  logic ftq_toIfu_req_bits_topdown_info_reasons_20;
  logic ftq_toIfu_req_bits_topdown_info_reasons_21;
  logic ftq_toIfu_req_bits_topdown_info_reasons_22;
  logic ftq_toIfu_req_bits_topdown_info_reasons_23;
  logic ftq_toIfu_req_bits_topdown_info_reasons_24;
  logic ftq_toIfu_req_bits_topdown_info_reasons_25;
  logic ftq_toIfu_req_bits_topdown_info_reasons_26;
  logic ftq_toIfu_req_bits_topdown_info_reasons_27;
  logic ftq_toIfu_req_bits_topdown_info_reasons_28;
  logic ftq_toIfu_req_bits_topdown_info_reasons_29;
  logic ftq_toIfu_req_bits_topdown_info_reasons_30;
  logic ftq_toIfu_req_bits_topdown_info_reasons_31;
  logic ftq_toIfu_req_bits_topdown_info_reasons_32;
  logic ftq_toIfu_req_bits_topdown_info_reasons_33;
  logic ftq_toIfu_req_bits_topdown_info_reasons_34;
  logic ftq_toIfu_req_bits_topdown_info_reasons_35;
  logic ftq_toIfu_req_bits_topdown_info_reasons_36;
  logic ftq_toIfu_req_bits_topdown_info_reasons_37;
  logic ftq_toIfu_redirect_valid;
  logic ftq_toIfu_redirect_bits_ftqIdx_flag;
  logic [5:0] ftq_toIfu_redirect_bits_ftqIdx_value;
  logic [3:0] ftq_toIfu_redirect_bits_ftqOffset;
  logic ftq_toIfu_redirect_bits_level;
  logic ftq_toIfu_topdown_redirect_valid;
  logic ftq_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet;
  logic ftq_toIfu_topdown_redirect_bits_cfiUpdate_br_hit;
  logic ftq_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit;
  logic ftq_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit;
  logic ftq_toIfu_topdown_redirect_bits_debugIsCtrl;
  logic ftq_toIfu_topdown_redirect_bits_debugIsMemVio;
  logic ftq_toIfu_flushFromBpu_s2_valid;
  logic ftq_toIfu_flushFromBpu_s2_bits_flag;
  logic [5:0] ftq_toIfu_flushFromBpu_s2_bits_value;
  logic ftq_toIfu_flushFromBpu_s3_valid;
  logic ftq_toIfu_flushFromBpu_s3_bits_flag;
  logic [5:0] ftq_toIfu_flushFromBpu_s3_bits_value;
  logic ftq_toICache_req_valid;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_0_startAddr;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_0_nextlineStart;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_1_startAddr;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_1_nextlineStart;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_2_startAddr;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_2_nextlineStart;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_3_startAddr;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_3_nextlineStart;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_4_startAddr;
  logic [49:0] ftq_toICache_req_bits_pcMemRead_4_nextlineStart;
  logic ftq_toICache_req_bits_readValid_0;
  logic ftq_toICache_req_bits_readValid_1;
  logic ftq_toICache_req_bits_readValid_2;
  logic ftq_toICache_req_bits_readValid_3;
  logic ftq_toICache_req_bits_readValid_4;
  logic ftq_toICache_req_bits_backendException;
  logic ftq_toICache_req_bits_hasSatpFlush;
  logic ftq_toBackend_pc_mem_wen;
  logic [5:0] ftq_toBackend_pc_mem_waddr;
  logic [49:0] ftq_toBackend_pc_mem_wdata_startAddr;
  logic [49:0] ftq_toBackend_newest_entry_target;
  logic [5:0] ftq_toBackend_newest_entry_ptr_value;
  logic ftq_toPrefetch_req_valid;
  logic [49:0] ftq_toPrefetch_req_bits_startAddr;
  logic [49:0] ftq_toPrefetch_req_bits_nextlineStart;
  logic ftq_toPrefetch_req_bits_ftqIdx_flag;
  logic [5:0] ftq_toPrefetch_req_bits_ftqIdx_value;
  logic ftq_toPrefetch_flushFromBpu_s2_valid;
  logic ftq_toPrefetch_flushFromBpu_s2_bits_flag;
  logic [5:0] ftq_toPrefetch_flushFromBpu_s2_bits_value;
  logic ftq_toPrefetch_flushFromBpu_s3_valid;
  logic ftq_toPrefetch_flushFromBpu_s3_bits_flag;
  logic [5:0] ftq_toPrefetch_flushFromBpu_s3_bits_value;
  logic [1:0] ftq_toPrefetch_backendException;
  logic ftq_icacheFlush;
  logic ftq_mmioCommitRead_mmioLastCommit;
  logic ftq_ControlBTBMissBubble;
  logic ftq_TAGEMissBubble;
  logic ftq_SCMissBubble;
  logic ftq_ITTAGEMissBubble;
  logic ftq_RASMissBubble;
  logic [5:0] ftq_perf_0_value;
  logic [5:0] ftq_perf_1_value;
  logic [5:0] ftq_perf_2_value;
  logic [5:0] ftq_perf_3_value;
  logic [5:0] ftq_perf_4_value;
  logic [5:0] ftq_perf_5_value;
  logic [5:0] ftq_perf_6_value;
  logic [5:0] ftq_perf_7_value;
  logic [5:0] ftq_perf_8_value;
  logic [5:0] ftq_perf_9_value;
  logic [5:0] ftq_perf_10_value;
  logic [5:0] ftq_perf_11_value;
  logic [5:0] ftq_perf_12_value;
  logic [5:0] ftq_perf_13_value;
  logic [5:0] ftq_perf_14_value;
  logic [5:0] ftq_perf_15_value;
  logic [5:0] ftq_perf_16_value;
  logic [5:0] ftq_perf_17_value;
  logic [5:0] ftq_perf_18_value;
  logic [5:0] ftq_perf_19_value;
  logic [5:0] ftq_perf_20_value;
  logic [5:0] ftq_perf_21_value;
  logic [5:0] ftq_perf_22_value;
  logic [5:0] ftq_perf_23_value;
  // ---- icache（inner_icache）----
  logic icache_fetch_req_ready;
  logic icache_fetch_resp_valid;
  logic icache_fetch_resp_bits_doubleline;
  logic [49:0] icache_fetch_resp_bits_vaddr_0;
  logic [49:0] icache_fetch_resp_bits_vaddr_1;
  logic [511:0] icache_fetch_resp_bits_data;
  logic [47:0] icache_fetch_resp_bits_paddr_0;
  logic [1:0] icache_fetch_resp_bits_exception_0;
  logic [1:0] icache_fetch_resp_bits_exception_1;
  logic icache_fetch_resp_bits_pmp_mmio_0;
  logic icache_fetch_resp_bits_pmp_mmio_1;
  logic [1:0] icache_fetch_resp_bits_itlb_pbmt_0;
  logic [1:0] icache_fetch_resp_bits_itlb_pbmt_1;
  logic icache_fetch_resp_bits_backendException;
  logic icache_fetch_resp_bits_hasSatpFlush;
  logic [55:0] icache_fetch_resp_bits_gpaddr;
  logic icache_fetch_resp_bits_isForVSnonLeafPTE;
  logic icache_fetch_topdownIcacheMiss;
  logic icache_fetch_topdownItlbMiss;
  logic icache_ftqPrefetch_req_ready;
  logic icache_toIFU;
  logic icache_pmp_0_req_valid;
  logic [47:0] icache_pmp_0_req_bits_addr;
  logic icache_pmp_1_req_valid;
  logic [47:0] icache_pmp_1_req_bits_addr;
  logic icache_pmp_2_req_valid;
  logic [47:0] icache_pmp_2_req_bits_addr;
  logic icache_pmp_3_req_valid;
  logic [47:0] icache_pmp_3_req_bits_addr;
  logic icache_itlb_0_req_valid;
  logic [49:0] icache_itlb_0_req_bits_vaddr;
  logic icache_itlb_1_req_valid;
  logic [49:0] icache_itlb_1_req_bits_vaddr;
  logic icache_itlbFlushPipe;
  logic icache_error_valid;
  logic [47:0] icache_error_bits_paddr;
  logic icache_error_bits_report_to_beu;
  logic icache_wfi_wfiSafe;
  logic icache_perfInfo_only_0_hit;
  logic icache_perfInfo_only_0_miss;
  logic icache_perfInfo_hit_0_hit_1;
  logic icache_perfInfo_hit_0_miss_1;
  logic icache_perfInfo_miss_0_hit_1;
  logic icache_perfInfo_miss_0_miss_1;
  logic icache_perfInfo_hit_0_except_1;
  logic icache_perfInfo_miss_0_except_1;
  logic icache_perfInfo_except_0;
  logic icache_perfInfo_bank_hit_0;
  logic icache_perfInfo_bank_hit_1;
  logic icache_perfInfo_hit;
  logic [5:0] icache_perf_0_value;
  logic mbistBd0_ack;
  logic [73:0] mbistBd0_outdata;
  logic mbistBd1_ack;
  logic [65:0] mbistBd1_outdata;
  logic mbistBd2_ack;
  logic [65:0] mbistBd2_outdata;
  logic mbistBd3_ack;
  logic [65:0] mbistBd3_outdata;
  logic mbistBd4_ack;
  logic [65:0] mbistBd4_outdata;
  // ---- ifu（inner_ifu）----
  logic ifu_ftqInter_fromFtq_req_ready;
  logic ifu_ftqInter_toFtq_pdWb_valid;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_0;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_1;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_2;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_3;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_4;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_5;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_6;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_7;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_8;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_9;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_10;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_11;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_12;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_13;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_14;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_pc_15;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_0_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_0_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_0_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_0_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_0_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_1_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_1_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_1_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_1_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_1_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_2_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_2_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_2_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_2_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_2_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_3_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_3_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_3_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_3_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_3_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_4_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_4_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_4_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_4_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_4_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_5_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_5_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_5_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_5_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_5_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_6_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_6_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_6_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_6_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_6_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_7_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_7_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_7_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_7_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_7_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_8_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_8_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_8_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_8_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_8_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_9_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_9_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_9_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_9_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_9_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_10_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_10_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_10_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_10_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_10_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_11_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_11_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_11_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_11_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_11_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_12_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_12_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_12_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_12_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_12_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_13_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_13_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_13_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_13_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_13_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_14_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_14_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_14_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_14_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_14_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_15_valid;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_15_isRVC;
  logic [1:0] ifu_ftqInter_toFtq_pdWb_bits_pd_15_brType;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_15_isCall;
  logic ifu_ftqInter_toFtq_pdWb_bits_pd_15_isRet;
  logic ifu_ftqInter_toFtq_pdWb_bits_ftqIdx_flag;
  logic [5:0] ifu_ftqInter_toFtq_pdWb_bits_ftqIdx_value;
  logic ifu_ftqInter_toFtq_pdWb_bits_misOffset_valid;
  logic [3:0] ifu_ftqInter_toFtq_pdWb_bits_misOffset_bits;
  logic ifu_ftqInter_toFtq_pdWb_bits_cfiOffset_valid;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_target;
  logic [49:0] ifu_ftqInter_toFtq_pdWb_bits_jalTarget;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_0;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_1;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_2;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_3;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_4;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_5;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_6;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_7;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_8;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_9;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_10;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_11;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_12;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_13;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_14;
  logic ifu_ftqInter_toFtq_pdWb_bits_instrRange_15;
  logic ifu_icacheStop;
  logic ifu_toIbuffer_valid;
  logic [31:0] ifu_toIbuffer_bits_instrs_0;
  logic [31:0] ifu_toIbuffer_bits_instrs_1;
  logic [31:0] ifu_toIbuffer_bits_instrs_2;
  logic [31:0] ifu_toIbuffer_bits_instrs_3;
  logic [31:0] ifu_toIbuffer_bits_instrs_4;
  logic [31:0] ifu_toIbuffer_bits_instrs_5;
  logic [31:0] ifu_toIbuffer_bits_instrs_6;
  logic [31:0] ifu_toIbuffer_bits_instrs_7;
  logic [31:0] ifu_toIbuffer_bits_instrs_8;
  logic [31:0] ifu_toIbuffer_bits_instrs_9;
  logic [31:0] ifu_toIbuffer_bits_instrs_10;
  logic [31:0] ifu_toIbuffer_bits_instrs_11;
  logic [31:0] ifu_toIbuffer_bits_instrs_12;
  logic [31:0] ifu_toIbuffer_bits_instrs_13;
  logic [31:0] ifu_toIbuffer_bits_instrs_14;
  logic [31:0] ifu_toIbuffer_bits_instrs_15;
  logic [15:0] ifu_toIbuffer_bits_valid;
  logic [15:0] ifu_toIbuffer_bits_enqEnable;
  logic ifu_toIbuffer_bits_pd_0_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_0_brType;
  logic ifu_toIbuffer_bits_pd_0_isCall;
  logic ifu_toIbuffer_bits_pd_0_isRet;
  logic ifu_toIbuffer_bits_pd_1_valid;
  logic ifu_toIbuffer_bits_pd_1_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_1_brType;
  logic ifu_toIbuffer_bits_pd_1_isCall;
  logic ifu_toIbuffer_bits_pd_1_isRet;
  logic ifu_toIbuffer_bits_pd_2_valid;
  logic ifu_toIbuffer_bits_pd_2_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_2_brType;
  logic ifu_toIbuffer_bits_pd_2_isCall;
  logic ifu_toIbuffer_bits_pd_2_isRet;
  logic ifu_toIbuffer_bits_pd_3_valid;
  logic ifu_toIbuffer_bits_pd_3_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_3_brType;
  logic ifu_toIbuffer_bits_pd_3_isCall;
  logic ifu_toIbuffer_bits_pd_3_isRet;
  logic ifu_toIbuffer_bits_pd_4_valid;
  logic ifu_toIbuffer_bits_pd_4_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_4_brType;
  logic ifu_toIbuffer_bits_pd_4_isCall;
  logic ifu_toIbuffer_bits_pd_4_isRet;
  logic ifu_toIbuffer_bits_pd_5_valid;
  logic ifu_toIbuffer_bits_pd_5_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_5_brType;
  logic ifu_toIbuffer_bits_pd_5_isCall;
  logic ifu_toIbuffer_bits_pd_5_isRet;
  logic ifu_toIbuffer_bits_pd_6_valid;
  logic ifu_toIbuffer_bits_pd_6_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_6_brType;
  logic ifu_toIbuffer_bits_pd_6_isCall;
  logic ifu_toIbuffer_bits_pd_6_isRet;
  logic ifu_toIbuffer_bits_pd_7_valid;
  logic ifu_toIbuffer_bits_pd_7_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_7_brType;
  logic ifu_toIbuffer_bits_pd_7_isCall;
  logic ifu_toIbuffer_bits_pd_7_isRet;
  logic ifu_toIbuffer_bits_pd_8_valid;
  logic ifu_toIbuffer_bits_pd_8_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_8_brType;
  logic ifu_toIbuffer_bits_pd_8_isCall;
  logic ifu_toIbuffer_bits_pd_8_isRet;
  logic ifu_toIbuffer_bits_pd_9_valid;
  logic ifu_toIbuffer_bits_pd_9_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_9_brType;
  logic ifu_toIbuffer_bits_pd_9_isCall;
  logic ifu_toIbuffer_bits_pd_9_isRet;
  logic ifu_toIbuffer_bits_pd_10_valid;
  logic ifu_toIbuffer_bits_pd_10_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_10_brType;
  logic ifu_toIbuffer_bits_pd_10_isCall;
  logic ifu_toIbuffer_bits_pd_10_isRet;
  logic ifu_toIbuffer_bits_pd_11_valid;
  logic ifu_toIbuffer_bits_pd_11_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_11_brType;
  logic ifu_toIbuffer_bits_pd_11_isCall;
  logic ifu_toIbuffer_bits_pd_11_isRet;
  logic ifu_toIbuffer_bits_pd_12_valid;
  logic ifu_toIbuffer_bits_pd_12_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_12_brType;
  logic ifu_toIbuffer_bits_pd_12_isCall;
  logic ifu_toIbuffer_bits_pd_12_isRet;
  logic ifu_toIbuffer_bits_pd_13_valid;
  logic ifu_toIbuffer_bits_pd_13_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_13_brType;
  logic ifu_toIbuffer_bits_pd_13_isCall;
  logic ifu_toIbuffer_bits_pd_13_isRet;
  logic ifu_toIbuffer_bits_pd_14_valid;
  logic ifu_toIbuffer_bits_pd_14_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_14_brType;
  logic ifu_toIbuffer_bits_pd_14_isCall;
  logic ifu_toIbuffer_bits_pd_14_isRet;
  logic ifu_toIbuffer_bits_pd_15_valid;
  logic ifu_toIbuffer_bits_pd_15_isRVC;
  logic [1:0] ifu_toIbuffer_bits_pd_15_brType;
  logic ifu_toIbuffer_bits_pd_15_isCall;
  logic ifu_toIbuffer_bits_pd_15_isRet;
  logic [9:0] ifu_toIbuffer_bits_foldpc_0;
  logic [9:0] ifu_toIbuffer_bits_foldpc_1;
  logic [9:0] ifu_toIbuffer_bits_foldpc_2;
  logic [9:0] ifu_toIbuffer_bits_foldpc_3;
  logic [9:0] ifu_toIbuffer_bits_foldpc_4;
  logic [9:0] ifu_toIbuffer_bits_foldpc_5;
  logic [9:0] ifu_toIbuffer_bits_foldpc_6;
  logic [9:0] ifu_toIbuffer_bits_foldpc_7;
  logic [9:0] ifu_toIbuffer_bits_foldpc_8;
  logic [9:0] ifu_toIbuffer_bits_foldpc_9;
  logic [9:0] ifu_toIbuffer_bits_foldpc_10;
  logic [9:0] ifu_toIbuffer_bits_foldpc_11;
  logic [9:0] ifu_toIbuffer_bits_foldpc_12;
  logic [9:0] ifu_toIbuffer_bits_foldpc_13;
  logic [9:0] ifu_toIbuffer_bits_foldpc_14;
  logic [9:0] ifu_toIbuffer_bits_foldpc_15;
  logic ifu_toIbuffer_bits_ftqOffset_0_valid;
  logic ifu_toIbuffer_bits_ftqOffset_1_valid;
  logic ifu_toIbuffer_bits_ftqOffset_2_valid;
  logic ifu_toIbuffer_bits_ftqOffset_3_valid;
  logic ifu_toIbuffer_bits_ftqOffset_4_valid;
  logic ifu_toIbuffer_bits_ftqOffset_5_valid;
  logic ifu_toIbuffer_bits_ftqOffset_6_valid;
  logic ifu_toIbuffer_bits_ftqOffset_7_valid;
  logic ifu_toIbuffer_bits_ftqOffset_8_valid;
  logic ifu_toIbuffer_bits_ftqOffset_9_valid;
  logic ifu_toIbuffer_bits_ftqOffset_10_valid;
  logic ifu_toIbuffer_bits_ftqOffset_11_valid;
  logic ifu_toIbuffer_bits_ftqOffset_12_valid;
  logic ifu_toIbuffer_bits_ftqOffset_13_valid;
  logic ifu_toIbuffer_bits_ftqOffset_14_valid;
  logic ifu_toIbuffer_bits_ftqOffset_15_valid;
  logic ifu_toIbuffer_bits_backendException_0;
  logic ifu_toIbuffer_bits_satpFlushFirstFetchFault_0;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_0;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_1;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_2;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_3;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_4;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_5;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_6;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_7;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_8;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_9;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_10;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_11;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_12;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_13;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_14;
  logic [1:0] ifu_toIbuffer_bits_exceptionType_15;
  logic ifu_toIbuffer_bits_crossPageIPFFix_0;
  logic ifu_toIbuffer_bits_crossPageIPFFix_1;
  logic ifu_toIbuffer_bits_crossPageIPFFix_2;
  logic ifu_toIbuffer_bits_crossPageIPFFix_3;
  logic ifu_toIbuffer_bits_crossPageIPFFix_4;
  logic ifu_toIbuffer_bits_crossPageIPFFix_5;
  logic ifu_toIbuffer_bits_crossPageIPFFix_6;
  logic ifu_toIbuffer_bits_crossPageIPFFix_7;
  logic ifu_toIbuffer_bits_crossPageIPFFix_8;
  logic ifu_toIbuffer_bits_crossPageIPFFix_9;
  logic ifu_toIbuffer_bits_crossPageIPFFix_10;
  logic ifu_toIbuffer_bits_crossPageIPFFix_11;
  logic ifu_toIbuffer_bits_crossPageIPFFix_12;
  logic ifu_toIbuffer_bits_crossPageIPFFix_13;
  logic ifu_toIbuffer_bits_crossPageIPFFix_14;
  logic ifu_toIbuffer_bits_crossPageIPFFix_15;
  logic ifu_toIbuffer_bits_illegalInstr_0;
  logic ifu_toIbuffer_bits_illegalInstr_1;
  logic ifu_toIbuffer_bits_illegalInstr_2;
  logic ifu_toIbuffer_bits_illegalInstr_3;
  logic ifu_toIbuffer_bits_illegalInstr_4;
  logic ifu_toIbuffer_bits_illegalInstr_5;
  logic ifu_toIbuffer_bits_illegalInstr_6;
  logic ifu_toIbuffer_bits_illegalInstr_7;
  logic ifu_toIbuffer_bits_illegalInstr_8;
  logic ifu_toIbuffer_bits_illegalInstr_9;
  logic ifu_toIbuffer_bits_illegalInstr_10;
  logic ifu_toIbuffer_bits_illegalInstr_11;
  logic ifu_toIbuffer_bits_illegalInstr_12;
  logic ifu_toIbuffer_bits_illegalInstr_13;
  logic ifu_toIbuffer_bits_illegalInstr_14;
  logic ifu_toIbuffer_bits_illegalInstr_15;
  logic [3:0] ifu_toIbuffer_bits_triggered_0;
  logic [3:0] ifu_toIbuffer_bits_triggered_1;
  logic [3:0] ifu_toIbuffer_bits_triggered_2;
  logic [3:0] ifu_toIbuffer_bits_triggered_3;
  logic [3:0] ifu_toIbuffer_bits_triggered_4;
  logic [3:0] ifu_toIbuffer_bits_triggered_5;
  logic [3:0] ifu_toIbuffer_bits_triggered_6;
  logic [3:0] ifu_toIbuffer_bits_triggered_7;
  logic [3:0] ifu_toIbuffer_bits_triggered_8;
  logic [3:0] ifu_toIbuffer_bits_triggered_9;
  logic [3:0] ifu_toIbuffer_bits_triggered_10;
  logic [3:0] ifu_toIbuffer_bits_triggered_11;
  logic [3:0] ifu_toIbuffer_bits_triggered_12;
  logic [3:0] ifu_toIbuffer_bits_triggered_13;
  logic [3:0] ifu_toIbuffer_bits_triggered_14;
  logic [3:0] ifu_toIbuffer_bits_triggered_15;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_0;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_1;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_2;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_3;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_4;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_5;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_6;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_7;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_8;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_9;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_10;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_11;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_12;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_13;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_14;
  logic ifu_toIbuffer_bits_isLastInFtqEntry_15;
  logic [49:0] ifu_toIbuffer_bits_pc_0;
  logic [49:0] ifu_toIbuffer_bits_pc_1;
  logic [49:0] ifu_toIbuffer_bits_pc_2;
  logic [49:0] ifu_toIbuffer_bits_pc_3;
  logic [49:0] ifu_toIbuffer_bits_pc_4;
  logic [49:0] ifu_toIbuffer_bits_pc_5;
  logic [49:0] ifu_toIbuffer_bits_pc_6;
  logic [49:0] ifu_toIbuffer_bits_pc_7;
  logic [49:0] ifu_toIbuffer_bits_pc_8;
  logic [49:0] ifu_toIbuffer_bits_pc_9;
  logic [49:0] ifu_toIbuffer_bits_pc_10;
  logic [49:0] ifu_toIbuffer_bits_pc_11;
  logic [49:0] ifu_toIbuffer_bits_pc_12;
  logic [49:0] ifu_toIbuffer_bits_pc_13;
  logic [49:0] ifu_toIbuffer_bits_pc_14;
  logic [49:0] ifu_toIbuffer_bits_pc_15;
  logic ifu_toIbuffer_bits_ftqPtr_flag;
  logic [5:0] ifu_toIbuffer_bits_ftqPtr_value;
  logic ifu_toIbuffer_bits_topdown_info_reasons_0;
  logic ifu_toIbuffer_bits_topdown_info_reasons_1;
  logic ifu_toIbuffer_bits_topdown_info_reasons_2;
  logic ifu_toIbuffer_bits_topdown_info_reasons_3;
  logic ifu_toIbuffer_bits_topdown_info_reasons_4;
  logic ifu_toIbuffer_bits_topdown_info_reasons_5;
  logic ifu_toIbuffer_bits_topdown_info_reasons_6;
  logic ifu_toIbuffer_bits_topdown_info_reasons_7;
  logic ifu_toIbuffer_bits_topdown_info_reasons_8;
  logic ifu_toIbuffer_bits_topdown_info_reasons_9;
  logic ifu_toIbuffer_bits_topdown_info_reasons_10;
  logic ifu_toIbuffer_bits_topdown_info_reasons_11;
  logic ifu_toIbuffer_bits_topdown_info_reasons_12;
  logic ifu_toIbuffer_bits_topdown_info_reasons_13;
  logic ifu_toIbuffer_bits_topdown_info_reasons_14;
  logic ifu_toIbuffer_bits_topdown_info_reasons_15;
  logic ifu_toIbuffer_bits_topdown_info_reasons_16;
  logic ifu_toIbuffer_bits_topdown_info_reasons_17;
  logic ifu_toIbuffer_bits_topdown_info_reasons_18;
  logic ifu_toIbuffer_bits_topdown_info_reasons_19;
  logic ifu_toIbuffer_bits_topdown_info_reasons_20;
  logic ifu_toIbuffer_bits_topdown_info_reasons_21;
  logic ifu_toIbuffer_bits_topdown_info_reasons_22;
  logic ifu_toIbuffer_bits_topdown_info_reasons_23;
  logic ifu_toIbuffer_bits_topdown_info_reasons_24;
  logic ifu_toIbuffer_bits_topdown_info_reasons_25;
  logic ifu_toIbuffer_bits_topdown_info_reasons_26;
  logic ifu_toIbuffer_bits_topdown_info_reasons_27;
  logic ifu_toIbuffer_bits_topdown_info_reasons_28;
  logic ifu_toIbuffer_bits_topdown_info_reasons_29;
  logic ifu_toIbuffer_bits_topdown_info_reasons_30;
  logic ifu_toIbuffer_bits_topdown_info_reasons_31;
  logic ifu_toIbuffer_bits_topdown_info_reasons_32;
  logic ifu_toIbuffer_bits_topdown_info_reasons_33;
  logic ifu_toIbuffer_bits_topdown_info_reasons_34;
  logic ifu_toIbuffer_bits_topdown_info_reasons_35;
  logic ifu_toIbuffer_bits_topdown_info_reasons_36;
  logic ifu_toIbuffer_bits_topdown_info_reasons_37;
  logic ifu_uncacheInter_toUncache_valid;
  logic [47:0] ifu_uncacheInter_toUncache_bits_addr;
  logic ifu_uncacheInter_toUncache_bits_memBackTypeMM;
  logic ifu_uncacheInter_toUncache_bits_memPageTypeNC;
  logic ifu_uncacheInter_toUncache_bits_flush;
  logic ifu_iTLBInter_req_valid;
  logic [49:0] ifu_iTLBInter_req_bits_vaddr;
  logic ifu_iTLBInter_resp_ready;
  logic ifu_pmp_req_valid;
  logic [47:0] ifu_pmp_req_bits_addr;
  logic ifu_mmioCommitRead_valid;
  logic ifu_mmioCommitRead_mmioFtqPtr_flag;
  logic [5:0] ifu_mmioCommitRead_mmioFtqPtr_value;
  logic [5:0] ifu_perf_0_value;
  logic [5:0] ifu_perf_1_value;
  logic [5:0] ifu_perf_2_value;
  logic [5:0] ifu_perf_3_value;
  logic [5:0] ifu_perf_4_value;
  logic [5:0] ifu_perf_5_value;
  logic [5:0] ifu_perf_6_value;
  logic [5:0] ifu_perf_7_value;
  logic [5:0] ifu_perf_8_value;
  logic [5:0] ifu_perf_9_value;
  logic [5:0] ifu_perf_10_value;
  logic [5:0] ifu_perf_11_value;
  logic [5:0] ifu_perf_12_value;
  // ---- ibuffer（inner_ibuffer）----
  logic ibuffer_in_ready;
  logic ibuffer_out_0_valid;
  logic [49:0] ibuffer_out_0_bits_pc;
  logic ibuffer_out_0_bits_pd_isRVC;
  logic [1:0] ibuffer_out_0_bits_pd_brType;
  logic ibuffer_out_0_bits_pred_taken;
  logic ibuffer_out_0_bits_ftqPtr_flag;
  logic [5:0] ibuffer_out_0_bits_ftqPtr_value;
  logic ibuffer_out_1_valid;
  logic [49:0] ibuffer_out_1_bits_pc;
  logic ibuffer_out_1_bits_pd_isRVC;
  logic [1:0] ibuffer_out_1_bits_pd_brType;
  logic ibuffer_out_1_bits_pred_taken;
  logic ibuffer_out_1_bits_ftqPtr_flag;
  logic [5:0] ibuffer_out_1_bits_ftqPtr_value;
  logic ibuffer_out_2_valid;
  logic [49:0] ibuffer_out_2_bits_pc;
  logic ibuffer_out_2_bits_pd_isRVC;
  logic [1:0] ibuffer_out_2_bits_pd_brType;
  logic ibuffer_out_2_bits_pred_taken;
  logic ibuffer_out_2_bits_ftqPtr_flag;
  logic [5:0] ibuffer_out_2_bits_ftqPtr_value;
  logic ibuffer_out_3_valid;
  logic [49:0] ibuffer_out_3_bits_pc;
  logic ibuffer_out_3_bits_pd_isRVC;
  logic [1:0] ibuffer_out_3_bits_pd_brType;
  logic ibuffer_out_3_bits_pred_taken;
  logic ibuffer_out_3_bits_ftqPtr_flag;
  logic [5:0] ibuffer_out_3_bits_ftqPtr_value;
  logic ibuffer_out_4_valid;
  logic [49:0] ibuffer_out_4_bits_pc;
  logic ibuffer_out_4_bits_pd_isRVC;
  logic [1:0] ibuffer_out_4_bits_pd_brType;
  logic ibuffer_out_4_bits_pred_taken;
  logic ibuffer_out_4_bits_ftqPtr_flag;
  logic [5:0] ibuffer_out_4_bits_ftqPtr_value;
  logic ibuffer_out_5_valid;
  logic [49:0] ibuffer_out_5_bits_pc;
  logic ibuffer_out_5_bits_pd_isRVC;
  logic [1:0] ibuffer_out_5_bits_pd_brType;
  logic ibuffer_out_5_bits_pred_taken;
  logic ibuffer_out_5_bits_ftqPtr_flag;
  logic [5:0] ibuffer_out_5_bits_ftqPtr_value;
  logic [5:0] ibuffer_perf_0_value;
  logic [5:0] ibuffer_perf_1_value;
  logic [5:0] ibuffer_perf_2_value;
  logic [5:0] ibuffer_perf_3_value;
  logic [5:0] ibuffer_perf_4_value;
  logic [5:0] ibuffer_perf_5_value;
  logic [5:0] ibuffer_perf_6_value;
  logic [5:0] ibuffer_perf_7_value;
  logic [5:0] ibuffer_perf_8_value;
  // ---- instrUncache（inner_instrUncache）----
  logic instrUncache_req_ready;
  logic instrUncache_resp_valid;
  logic [31:0] instrUncache_resp_bits_data;
  logic instrUncache_resp_bits_corrupt;
  logic instrUncache_wfi_wfiSafe;
  // ---- itlb（inner_itlb）----
  logic [47:0] itlb_requestor_0_resp_bits_paddr_0;
  logic [63:0] itlb_requestor_0_resp_bits_gpaddr_0;
  logic [1:0] itlb_requestor_0_resp_bits_pbmt_0;
  logic itlb_requestor_0_resp_bits_miss;
  logic itlb_requestor_0_resp_bits_isForVSnonLeafPTE;
  logic itlb_requestor_0_resp_bits_excp_0_gpf_instr;
  logic itlb_requestor_0_resp_bits_excp_0_pf_instr;
  logic itlb_requestor_0_resp_bits_excp_0_af_instr;
  logic [47:0] itlb_requestor_1_resp_bits_paddr_0;
  logic [63:0] itlb_requestor_1_resp_bits_gpaddr_0;
  logic [1:0] itlb_requestor_1_resp_bits_pbmt_0;
  logic itlb_requestor_1_resp_bits_miss;
  logic itlb_requestor_1_resp_bits_isForVSnonLeafPTE;
  logic itlb_requestor_1_resp_bits_excp_0_gpf_instr;
  logic itlb_requestor_1_resp_bits_excp_0_pf_instr;
  logic itlb_requestor_1_resp_bits_excp_0_af_instr;
  logic itlb_requestor_2_req_ready;
  logic itlb_requestor_2_resp_valid;
  logic [47:0] itlb_requestor_2_resp_bits_paddr_0;
  logic [63:0] itlb_requestor_2_resp_bits_gpaddr_0;
  logic [1:0] itlb_requestor_2_resp_bits_pbmt_0;
  logic itlb_requestor_2_resp_bits_miss;
  logic itlb_requestor_2_resp_bits_isForVSnonLeafPTE;
  logic itlb_requestor_2_resp_bits_excp_0_gpf_instr;
  logic itlb_requestor_2_resp_bits_excp_0_pf_instr;
  logic itlb_requestor_2_resp_bits_excp_0_af_instr;
  logic itlb_ptw_req_0_valid;
  logic [37:0] itlb_ptw_req_0_bits_vpn;
  logic [1:0] itlb_ptw_req_0_bits_s2xlate;
  logic itlb_ptw_req_0_bits_getGpa;
  logic itlb_ptw_req_1_valid;
  logic [37:0] itlb_ptw_req_1_bits_vpn;
  logic [1:0] itlb_ptw_req_1_bits_s2xlate;
  logic itlb_ptw_req_1_bits_getGpa;
  logic itlb_ptw_req_2_valid;
  logic [37:0] itlb_ptw_req_2_bits_vpn;
  logic [1:0] itlb_ptw_req_2_bits_s2xlate;
  logic itlb_ptw_req_2_bits_getGpa;
  logic [5:0] itlb_perf_0_value;
  logic [5:0] itlb_perf_1_value;
  // ---- itlbRepeater1（inner_itlbRepeater1）----
  logic itlbRepeater1_tlb_req_0_ready;
  logic itlbRepeater1_tlb_req_1_ready;
  logic itlbRepeater1_tlb_req_2_ready;
  logic itlbRepeater1_tlb_resp_valid;
  logic [1:0] itlbRepeater1_tlb_resp_bits_data_s2xlate;
  logic [34:0] itlbRepeater1_tlb_resp_bits_data_s1_entry_tag;
  logic [15:0] itlbRepeater1_tlb_resp_bits_data_s1_entry_asid;
  logic [13:0] itlbRepeater1_tlb_resp_bits_data_s1_entry_vmid;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_n;
  logic [1:0] itlbRepeater1_tlb_resp_bits_data_s1_entry_pbmt;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_d;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_a;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_g;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_u;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_x;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_w;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_r;
  logic [1:0] itlbRepeater1_tlb_resp_bits_data_s1_entry_level;
  logic itlbRepeater1_tlb_resp_bits_data_s1_entry_v;
  logic [40:0] itlbRepeater1_tlb_resp_bits_data_s1_entry_ppn;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_addr_low;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_0;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_1;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_2;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_3;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_4;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_5;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_6;
  logic [2:0] itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_7;
  logic itlbRepeater1_tlb_resp_bits_data_s1_valididx_0;
  logic itlbRepeater1_tlb_resp_bits_data_s1_valididx_1;
  logic itlbRepeater1_tlb_resp_bits_data_s1_valididx_2;
  logic itlbRepeater1_tlb_resp_bits_data_s1_valididx_3;
  logic itlbRepeater1_tlb_resp_bits_data_s1_valididx_4;
  logic itlbRepeater1_tlb_resp_bits_data_s1_valididx_5;
  logic itlbRepeater1_tlb_resp_bits_data_s1_valididx_6;
  logic itlbRepeater1_tlb_resp_bits_data_s1_valididx_7;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pteidx_0;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pteidx_1;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pteidx_2;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pteidx_3;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pteidx_4;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pteidx_5;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pteidx_6;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pteidx_7;
  logic itlbRepeater1_tlb_resp_bits_data_s1_pf;
  logic itlbRepeater1_tlb_resp_bits_data_s1_af;
  logic [37:0] itlbRepeater1_tlb_resp_bits_data_s2_entry_tag;
  logic [13:0] itlbRepeater1_tlb_resp_bits_data_s2_entry_vmid;
  logic itlbRepeater1_tlb_resp_bits_data_s2_entry_n;
  logic [1:0] itlbRepeater1_tlb_resp_bits_data_s2_entry_pbmt;
  logic [37:0] itlbRepeater1_tlb_resp_bits_data_s2_entry_ppn;
  logic itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_d;
  logic itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_a;
  logic itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_g;
  logic itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_u;
  logic itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_x;
  logic itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_w;
  logic itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_r;
  logic [1:0] itlbRepeater1_tlb_resp_bits_data_s2_entry_level;
  logic itlbRepeater1_tlb_resp_bits_data_s2_gpf;
  logic itlbRepeater1_tlb_resp_bits_data_s2_gaf;
  logic itlbRepeater1_tlb_resp_bits_data_getGpa;
  logic itlbRepeater1_ptw_req_0_valid;
  logic [37:0] itlbRepeater1_ptw_req_0_bits_vpn;
  logic [1:0] itlbRepeater1_ptw_req_0_bits_s2xlate;
  // ---- itlbRepeater2（inner_itlbRepeater2）----
  logic itlbRepeater2_tlb_req_0_ready;
  logic itlbRepeater2_tlb_resp_valid;
  logic [1:0] itlbRepeater2_tlb_resp_bits_s2xlate;
  logic [34:0] itlbRepeater2_tlb_resp_bits_s1_entry_tag;
  logic [15:0] itlbRepeater2_tlb_resp_bits_s1_entry_asid;
  logic [13:0] itlbRepeater2_tlb_resp_bits_s1_entry_vmid;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_n;
  logic [1:0] itlbRepeater2_tlb_resp_bits_s1_entry_pbmt;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_perm_d;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_perm_a;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_perm_g;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_perm_u;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_perm_x;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_perm_w;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_perm_r;
  logic [1:0] itlbRepeater2_tlb_resp_bits_s1_entry_level;
  logic itlbRepeater2_tlb_resp_bits_s1_entry_v;
  logic [40:0] itlbRepeater2_tlb_resp_bits_s1_entry_ppn;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_addr_low;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_ppn_low_0;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_ppn_low_1;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_ppn_low_2;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_ppn_low_3;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_ppn_low_4;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_ppn_low_5;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_ppn_low_6;
  logic [2:0] itlbRepeater2_tlb_resp_bits_s1_ppn_low_7;
  logic itlbRepeater2_tlb_resp_bits_s1_valididx_0;
  logic itlbRepeater2_tlb_resp_bits_s1_valididx_1;
  logic itlbRepeater2_tlb_resp_bits_s1_valididx_2;
  logic itlbRepeater2_tlb_resp_bits_s1_valididx_3;
  logic itlbRepeater2_tlb_resp_bits_s1_valididx_4;
  logic itlbRepeater2_tlb_resp_bits_s1_valididx_5;
  logic itlbRepeater2_tlb_resp_bits_s1_valididx_6;
  logic itlbRepeater2_tlb_resp_bits_s1_valididx_7;
  logic itlbRepeater2_tlb_resp_bits_s1_pteidx_0;
  logic itlbRepeater2_tlb_resp_bits_s1_pteidx_1;
  logic itlbRepeater2_tlb_resp_bits_s1_pteidx_2;
  logic itlbRepeater2_tlb_resp_bits_s1_pteidx_3;
  logic itlbRepeater2_tlb_resp_bits_s1_pteidx_4;
  logic itlbRepeater2_tlb_resp_bits_s1_pteidx_5;
  logic itlbRepeater2_tlb_resp_bits_s1_pteidx_6;
  logic itlbRepeater2_tlb_resp_bits_s1_pteidx_7;
  logic itlbRepeater2_tlb_resp_bits_s1_pf;
  logic itlbRepeater2_tlb_resp_bits_s1_af;
  logic [37:0] itlbRepeater2_tlb_resp_bits_s2_entry_tag;
  logic [13:0] itlbRepeater2_tlb_resp_bits_s2_entry_vmid;
  logic itlbRepeater2_tlb_resp_bits_s2_entry_n;
  logic [1:0] itlbRepeater2_tlb_resp_bits_s2_entry_pbmt;
  logic [37:0] itlbRepeater2_tlb_resp_bits_s2_entry_ppn;
  logic itlbRepeater2_tlb_resp_bits_s2_entry_perm_d;
  logic itlbRepeater2_tlb_resp_bits_s2_entry_perm_a;
  logic itlbRepeater2_tlb_resp_bits_s2_entry_perm_g;
  logic itlbRepeater2_tlb_resp_bits_s2_entry_perm_u;
  logic itlbRepeater2_tlb_resp_bits_s2_entry_perm_x;
  logic itlbRepeater2_tlb_resp_bits_s2_entry_perm_w;
  logic itlbRepeater2_tlb_resp_bits_s2_entry_perm_r;
  logic [1:0] itlbRepeater2_tlb_resp_bits_s2_entry_level;
  logic itlbRepeater2_tlb_resp_bits_s2_gpf;
  logic itlbRepeater2_tlb_resp_bits_s2_gaf;
  // ---- pmp（inner_pmp）----
  logic pmp_pmp_0_cfg_l;
  logic [1:0] pmp_pmp_0_cfg_a;
  logic pmp_pmp_0_cfg_x;
  logic [45:0] pmp_pmp_0_addr;
  logic [47:0] pmp_pmp_0_mask;
  logic pmp_pmp_1_cfg_l;
  logic [1:0] pmp_pmp_1_cfg_a;
  logic pmp_pmp_1_cfg_x;
  logic [45:0] pmp_pmp_1_addr;
  logic [47:0] pmp_pmp_1_mask;
  logic pmp_pmp_2_cfg_l;
  logic [1:0] pmp_pmp_2_cfg_a;
  logic pmp_pmp_2_cfg_x;
  logic [45:0] pmp_pmp_2_addr;
  logic [47:0] pmp_pmp_2_mask;
  logic pmp_pmp_3_cfg_l;
  logic [1:0] pmp_pmp_3_cfg_a;
  logic pmp_pmp_3_cfg_x;
  logic [45:0] pmp_pmp_3_addr;
  logic [47:0] pmp_pmp_3_mask;
  logic pmp_pmp_4_cfg_l;
  logic [1:0] pmp_pmp_4_cfg_a;
  logic pmp_pmp_4_cfg_x;
  logic [45:0] pmp_pmp_4_addr;
  logic [47:0] pmp_pmp_4_mask;
  logic pmp_pmp_5_cfg_l;
  logic [1:0] pmp_pmp_5_cfg_a;
  logic pmp_pmp_5_cfg_x;
  logic [45:0] pmp_pmp_5_addr;
  logic [47:0] pmp_pmp_5_mask;
  logic pmp_pmp_6_cfg_l;
  logic [1:0] pmp_pmp_6_cfg_a;
  logic pmp_pmp_6_cfg_x;
  logic [45:0] pmp_pmp_6_addr;
  logic [47:0] pmp_pmp_6_mask;
  logic pmp_pmp_7_cfg_l;
  logic [1:0] pmp_pmp_7_cfg_a;
  logic pmp_pmp_7_cfg_x;
  logic [45:0] pmp_pmp_7_addr;
  logic [47:0] pmp_pmp_7_mask;
  logic pmp_pmp_8_cfg_l;
  logic [1:0] pmp_pmp_8_cfg_a;
  logic pmp_pmp_8_cfg_x;
  logic [45:0] pmp_pmp_8_addr;
  logic [47:0] pmp_pmp_8_mask;
  logic pmp_pmp_9_cfg_l;
  logic [1:0] pmp_pmp_9_cfg_a;
  logic pmp_pmp_9_cfg_x;
  logic [45:0] pmp_pmp_9_addr;
  logic [47:0] pmp_pmp_9_mask;
  logic pmp_pmp_10_cfg_l;
  logic [1:0] pmp_pmp_10_cfg_a;
  logic pmp_pmp_10_cfg_x;
  logic [45:0] pmp_pmp_10_addr;
  logic [47:0] pmp_pmp_10_mask;
  logic pmp_pmp_11_cfg_l;
  logic [1:0] pmp_pmp_11_cfg_a;
  logic pmp_pmp_11_cfg_x;
  logic [45:0] pmp_pmp_11_addr;
  logic [47:0] pmp_pmp_11_mask;
  logic pmp_pmp_12_cfg_l;
  logic [1:0] pmp_pmp_12_cfg_a;
  logic pmp_pmp_12_cfg_x;
  logic [45:0] pmp_pmp_12_addr;
  logic [47:0] pmp_pmp_12_mask;
  logic pmp_pmp_13_cfg_l;
  logic [1:0] pmp_pmp_13_cfg_a;
  logic pmp_pmp_13_cfg_x;
  logic [45:0] pmp_pmp_13_addr;
  logic [47:0] pmp_pmp_13_mask;
  logic pmp_pmp_14_cfg_l;
  logic [1:0] pmp_pmp_14_cfg_a;
  logic pmp_pmp_14_cfg_x;
  logic [45:0] pmp_pmp_14_addr;
  logic [47:0] pmp_pmp_14_mask;
  logic pmp_pmp_15_cfg_l;
  logic [1:0] pmp_pmp_15_cfg_a;
  logic pmp_pmp_15_cfg_x;
  logic [45:0] pmp_pmp_15_addr;
  logic [47:0] pmp_pmp_15_mask;
  logic pmp_pmp_16_cfg_l;
  logic [1:0] pmp_pmp_16_cfg_a;
  logic pmp_pmp_16_cfg_x;
  logic [45:0] pmp_pmp_16_addr;
  logic [47:0] pmp_pmp_16_mask;
  logic pmp_pmp_17_cfg_l;
  logic [1:0] pmp_pmp_17_cfg_a;
  logic pmp_pmp_17_cfg_x;
  logic [45:0] pmp_pmp_17_addr;
  logic [47:0] pmp_pmp_17_mask;
  logic pmp_pmp_18_cfg_l;
  logic [1:0] pmp_pmp_18_cfg_a;
  logic pmp_pmp_18_cfg_x;
  logic [45:0] pmp_pmp_18_addr;
  logic [47:0] pmp_pmp_18_mask;
  logic pmp_pmp_19_cfg_l;
  logic [1:0] pmp_pmp_19_cfg_a;
  logic pmp_pmp_19_cfg_x;
  logic [45:0] pmp_pmp_19_addr;
  logic [47:0] pmp_pmp_19_mask;
  logic pmp_pmp_20_cfg_l;
  logic [1:0] pmp_pmp_20_cfg_a;
  logic pmp_pmp_20_cfg_x;
  logic [45:0] pmp_pmp_20_addr;
  logic [47:0] pmp_pmp_20_mask;
  logic pmp_pmp_21_cfg_l;
  logic [1:0] pmp_pmp_21_cfg_a;
  logic pmp_pmp_21_cfg_x;
  logic [45:0] pmp_pmp_21_addr;
  logic [47:0] pmp_pmp_21_mask;
  logic pmp_pmp_22_cfg_l;
  logic [1:0] pmp_pmp_22_cfg_a;
  logic pmp_pmp_22_cfg_x;
  logic [45:0] pmp_pmp_22_addr;
  logic [47:0] pmp_pmp_22_mask;
  logic pmp_pmp_23_cfg_l;
  logic [1:0] pmp_pmp_23_cfg_a;
  logic pmp_pmp_23_cfg_x;
  logic [45:0] pmp_pmp_23_addr;
  logic [47:0] pmp_pmp_23_mask;
  logic pmp_pmp_24_cfg_l;
  logic [1:0] pmp_pmp_24_cfg_a;
  logic pmp_pmp_24_cfg_x;
  logic [45:0] pmp_pmp_24_addr;
  logic [47:0] pmp_pmp_24_mask;
  logic pmp_pmp_25_cfg_l;
  logic [1:0] pmp_pmp_25_cfg_a;
  logic pmp_pmp_25_cfg_x;
  logic [45:0] pmp_pmp_25_addr;
  logic [47:0] pmp_pmp_25_mask;
  logic pmp_pmp_26_cfg_l;
  logic [1:0] pmp_pmp_26_cfg_a;
  logic pmp_pmp_26_cfg_x;
  logic [45:0] pmp_pmp_26_addr;
  logic [47:0] pmp_pmp_26_mask;
  logic pmp_pmp_27_cfg_l;
  logic [1:0] pmp_pmp_27_cfg_a;
  logic pmp_pmp_27_cfg_x;
  logic [45:0] pmp_pmp_27_addr;
  logic [47:0] pmp_pmp_27_mask;
  logic pmp_pmp_28_cfg_l;
  logic [1:0] pmp_pmp_28_cfg_a;
  logic pmp_pmp_28_cfg_x;
  logic [45:0] pmp_pmp_28_addr;
  logic [47:0] pmp_pmp_28_mask;
  logic pmp_pmp_29_cfg_l;
  logic [1:0] pmp_pmp_29_cfg_a;
  logic pmp_pmp_29_cfg_x;
  logic [45:0] pmp_pmp_29_addr;
  logic [47:0] pmp_pmp_29_mask;
  logic pmp_pmp_30_cfg_l;
  logic [1:0] pmp_pmp_30_cfg_a;
  logic pmp_pmp_30_cfg_x;
  logic [45:0] pmp_pmp_30_addr;
  logic [47:0] pmp_pmp_30_mask;
  logic pmp_pmp_31_cfg_l;
  logic [1:0] pmp_pmp_31_cfg_a;
  logic pmp_pmp_31_cfg_x;
  logic [45:0] pmp_pmp_31_addr;
  logic [47:0] pmp_pmp_31_mask;
  logic pmp_pma_0_cfg_c;
  logic [1:0] pmp_pma_0_cfg_a;
  logic pmp_pma_0_cfg_x;
  logic [45:0] pmp_pma_0_addr;
  logic [47:0] pmp_pma_0_mask;
  logic pmp_pma_1_cfg_c;
  logic [1:0] pmp_pma_1_cfg_a;
  logic pmp_pma_1_cfg_x;
  logic [45:0] pmp_pma_1_addr;
  logic [47:0] pmp_pma_1_mask;
  logic pmp_pma_2_cfg_c;
  logic [1:0] pmp_pma_2_cfg_a;
  logic pmp_pma_2_cfg_x;
  logic [45:0] pmp_pma_2_addr;
  logic [47:0] pmp_pma_2_mask;
  logic pmp_pma_3_cfg_c;
  logic [1:0] pmp_pma_3_cfg_a;
  logic pmp_pma_3_cfg_x;
  logic [45:0] pmp_pma_3_addr;
  logic [47:0] pmp_pma_3_mask;
  logic pmp_pma_4_cfg_c;
  logic [1:0] pmp_pma_4_cfg_a;
  logic pmp_pma_4_cfg_x;
  logic [45:0] pmp_pma_4_addr;
  logic [47:0] pmp_pma_4_mask;
  logic pmp_pma_5_cfg_c;
  logic [1:0] pmp_pma_5_cfg_a;
  logic pmp_pma_5_cfg_x;
  logic [45:0] pmp_pma_5_addr;
  logic [47:0] pmp_pma_5_mask;
  logic pmp_pma_6_cfg_c;
  logic [1:0] pmp_pma_6_cfg_a;
  logic pmp_pma_6_cfg_x;
  logic [45:0] pmp_pma_6_addr;
  logic [47:0] pmp_pma_6_mask;
  logic pmp_pma_7_cfg_c;
  logic [1:0] pmp_pma_7_cfg_a;
  logic pmp_pma_7_cfg_x;
  logic [45:0] pmp_pma_7_addr;
  logic [47:0] pmp_pma_7_mask;
  logic pmp_pma_8_cfg_c;
  logic [1:0] pmp_pma_8_cfg_a;
  logic pmp_pma_8_cfg_x;
  logic [45:0] pmp_pma_8_addr;
  logic [47:0] pmp_pma_8_mask;
  logic pmp_pma_9_cfg_c;
  logic [1:0] pmp_pma_9_cfg_a;
  logic pmp_pma_9_cfg_x;
  logic [45:0] pmp_pma_9_addr;
  logic [47:0] pmp_pma_9_mask;
  logic pmp_pma_10_cfg_c;
  logic [1:0] pmp_pma_10_cfg_a;
  logic pmp_pma_10_cfg_x;
  logic [45:0] pmp_pma_10_addr;
  logic [47:0] pmp_pma_10_mask;
  logic pmp_pma_11_cfg_c;
  logic [1:0] pmp_pma_11_cfg_a;
  logic pmp_pma_11_cfg_x;
  logic [45:0] pmp_pma_11_addr;
  logic [47:0] pmp_pma_11_mask;
  logic pmp_pma_12_cfg_c;
  logic [1:0] pmp_pma_12_cfg_a;
  logic pmp_pma_12_cfg_x;
  logic [45:0] pmp_pma_12_addr;
  logic [47:0] pmp_pma_12_mask;
  logic pmp_pma_13_cfg_c;
  logic [1:0] pmp_pma_13_cfg_a;
  logic pmp_pma_13_cfg_x;
  logic [45:0] pmp_pma_13_addr;
  logic [47:0] pmp_pma_13_mask;
  logic pmp_pma_14_cfg_c;
  logic [1:0] pmp_pma_14_cfg_a;
  logic pmp_pma_14_cfg_x;
  logic [45:0] pmp_pma_14_addr;
  logic [47:0] pmp_pma_14_mask;
  logic pmp_pma_15_cfg_c;
  logic [1:0] pmp_pma_15_cfg_a;
  logic pmp_pma_15_cfg_x;
  logic [45:0] pmp_pma_15_addr;
  logic [47:0] pmp_pma_15_mask;
  logic pmp_pma_16_cfg_c;
  logic [1:0] pmp_pma_16_cfg_a;
  logic pmp_pma_16_cfg_x;
  logic [45:0] pmp_pma_16_addr;
  logic [47:0] pmp_pma_16_mask;
  logic pmp_pma_17_cfg_c;
  logic [1:0] pmp_pma_17_cfg_a;
  logic pmp_pma_17_cfg_x;
  logic [45:0] pmp_pma_17_addr;
  logic [47:0] pmp_pma_17_mask;
  logic pmp_pma_18_cfg_c;
  logic [1:0] pmp_pma_18_cfg_a;
  logic pmp_pma_18_cfg_x;
  logic [45:0] pmp_pma_18_addr;
  logic [47:0] pmp_pma_18_mask;
  logic pmp_pma_19_cfg_c;
  logic [1:0] pmp_pma_19_cfg_a;
  logic pmp_pma_19_cfg_x;
  logic [45:0] pmp_pma_19_addr;
  logic [47:0] pmp_pma_19_mask;
  logic pmp_pma_20_cfg_c;
  logic [1:0] pmp_pma_20_cfg_a;
  logic pmp_pma_20_cfg_x;
  logic [45:0] pmp_pma_20_addr;
  logic [47:0] pmp_pma_20_mask;
  logic pmp_pma_21_cfg_c;
  logic [1:0] pmp_pma_21_cfg_a;
  logic pmp_pma_21_cfg_x;
  logic [45:0] pmp_pma_21_addr;
  logic [47:0] pmp_pma_21_mask;
  logic pmp_pma_22_cfg_c;
  logic [1:0] pmp_pma_22_cfg_a;
  logic pmp_pma_22_cfg_x;
  logic [45:0] pmp_pma_22_addr;
  logic [47:0] pmp_pma_22_mask;
  logic pmp_pma_23_cfg_c;
  logic [1:0] pmp_pma_23_cfg_a;
  logic pmp_pma_23_cfg_x;
  logic [45:0] pmp_pma_23_addr;
  logic [47:0] pmp_pma_23_mask;
  logic pmp_pma_24_cfg_c;
  logic [1:0] pmp_pma_24_cfg_a;
  logic pmp_pma_24_cfg_x;
  logic [45:0] pmp_pma_24_addr;
  logic [47:0] pmp_pma_24_mask;
  logic pmp_pma_25_cfg_c;
  logic [1:0] pmp_pma_25_cfg_a;
  logic pmp_pma_25_cfg_x;
  logic [45:0] pmp_pma_25_addr;
  logic [47:0] pmp_pma_25_mask;
  logic pmp_pma_26_cfg_c;
  logic [1:0] pmp_pma_26_cfg_a;
  logic pmp_pma_26_cfg_x;
  logic [45:0] pmp_pma_26_addr;
  logic [47:0] pmp_pma_26_mask;
  logic pmp_pma_27_cfg_c;
  logic [1:0] pmp_pma_27_cfg_a;
  logic pmp_pma_27_cfg_x;
  logic [45:0] pmp_pma_27_addr;
  logic [47:0] pmp_pma_27_mask;
  logic pmp_pma_28_cfg_c;
  logic [1:0] pmp_pma_28_cfg_a;
  logic pmp_pma_28_cfg_x;
  logic [45:0] pmp_pma_28_addr;
  logic [47:0] pmp_pma_28_mask;
  logic pmp_pma_29_cfg_c;
  logic [1:0] pmp_pma_29_cfg_a;
  logic pmp_pma_29_cfg_x;
  logic [45:0] pmp_pma_29_addr;
  logic [47:0] pmp_pma_29_mask;
  logic pmp_pma_30_cfg_c;
  logic [1:0] pmp_pma_30_cfg_a;
  logic pmp_pma_30_cfg_x;
  logic [45:0] pmp_pma_30_addr;
  logic [47:0] pmp_pma_30_mask;
  logic pmp_pma_31_cfg_c;
  logic [1:0] pmp_pma_31_cfg_a;
  logic pmp_pma_31_cfg_x;
  logic [45:0] pmp_pma_31_addr;
  logic [47:0] pmp_pma_31_mask;
  // ---- pmpCheck0（inner_PMPChecker）----
  logic pmpCheck0_resp_instr;
  logic pmpCheck0_resp_mmio;
  // ---- pmpCheck1（inner_PMPChecker_1）----
  logic pmpCheck1_resp_instr;
  logic pmpCheck1_resp_mmio;
  // ---- pmpCheck2（inner_PMPChecker_2）----
  logic pmpCheck2_resp_instr;
  logic pmpCheck2_resp_mmio;
  // ---- pmpCheck3（inner_PMPChecker_3）----
  logic pmpCheck3_resp_instr;
  logic pmpCheck3_resp_mmio;
  // ---- pmpCheck4（inner_PMPChecker_4）----
  logic pmpCheck4_resp_instr;
  logic pmpCheck4_resp_mmio;
  // ---- tlbCsrDelay（inner_tlbCsr_delay）----
  logic [3:0] tlbCsrDelay_out_satp_mode;
  logic [15:0] tlbCsrDelay_out_satp_asid;
  logic [43:0] tlbCsrDelay_out_satp_ppn;
  logic tlbCsrDelay_out_satp_changed;
  logic [3:0] tlbCsrDelay_out_vsatp_mode;
  logic [15:0] tlbCsrDelay_out_vsatp_asid;
  logic [43:0] tlbCsrDelay_out_vsatp_ppn;
  logic tlbCsrDelay_out_vsatp_changed;
  logic [3:0] tlbCsrDelay_out_hgatp_mode;
  logic [15:0] tlbCsrDelay_out_hgatp_vmid;
  logic [43:0] tlbCsrDelay_out_hgatp_ppn;
  logic tlbCsrDelay_out_hgatp_changed;
  logic tlbCsrDelay_out_mbmc_BME;
  logic tlbCsrDelay_out_mbmc_CMODE;
  logic tlbCsrDelay_out_priv_mxr;
  logic tlbCsrDelay_out_priv_sum;
  logic tlbCsrDelay_out_priv_vmxr;
  logic tlbCsrDelay_out_priv_vsum;
  logic tlbCsrDelay_out_priv_virt;
  logic tlbCsrDelay_out_priv_virt_changed;
  logic tlbCsrDelay_out_priv_spvp;
  logic [1:0] tlbCsrDelay_out_priv_imode;
  logic [1:0] tlbCsrDelay_out_priv_dmode;
  logic tlbCsrDelay_out_priv_debug;
  logic [1:0] tlbCsrDelay_out_pmm_mseccfg;
  logic [1:0] tlbCsrDelay_out_pmm_menvcfg;
  logic [1:0] tlbCsrDelay_out_pmm_henvcfg;
  logic [1:0] tlbCsrDelay_out_pmm_hstatus;
  logic [1:0] tlbCsrDelay_out_pmm_senvcfg;
  // ---- csrCtrlDelay（inner_csrCtrl_delay）----
  logic csrCtrlDelay_out_pf_ctrl_l1I_pf_enable;
  logic csrCtrlDelay_out_bp_ctrl_ubtb_enable;
  logic csrCtrlDelay_out_bp_ctrl_btb_enable;
  logic csrCtrlDelay_out_bp_ctrl_tage_enable;
  logic csrCtrlDelay_out_bp_ctrl_sc_enable;
  logic csrCtrlDelay_out_bp_ctrl_ras_enable;
  logic csrCtrlDelay_out_distribute_csr_w_valid;
  logic [11:0] csrCtrlDelay_out_distribute_csr_w_bits_addr;
  logic [63:0] csrCtrlDelay_out_distribute_csr_w_bits_data;
  logic csrCtrlDelay_out_frontend_trigger_tUpdate_valid;
  logic [1:0] csrCtrlDelay_out_frontend_trigger_tUpdate_bits_addr;
  logic [1:0] csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_matchType;
  logic csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_select;
  logic [3:0] csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_action;
  logic csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_chain;
  logic [63:0] csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_tdata2;
  logic csrCtrlDelay_out_frontend_trigger_tEnableVec_0;
  logic csrCtrlDelay_out_frontend_trigger_tEnableVec_1;
  logic csrCtrlDelay_out_frontend_trigger_tEnableVec_2;
  logic csrCtrlDelay_out_frontend_trigger_tEnableVec_3;
  logic csrCtrlDelay_out_frontend_trigger_debugMode;
  logic csrCtrlDelay_out_frontend_trigger_triggerCanRaiseBpExp;
  logic csrCtrlDelay_out_fsIsOff;
  // ---- wfiReqDelay（inner_wfiReq_delay）----
  logic wfiReqDelay_out;
  // ---- pfevent（inner_pfevent）----
  logic [63:0] pfevent_hpmevent_0;
  logic [63:0] pfevent_hpmevent_1;
  logic [63:0] pfevent_hpmevent_2;
  logic [63:0] pfevent_hpmevent_3;
  logic [63:0] pfevent_hpmevent_4;
  logic [63:0] pfevent_hpmevent_5;
  logic [63:0] pfevent_hpmevent_6;
  logic [63:0] pfevent_hpmevent_7;
  // ---- perfHpm（inner_perfEvents_hpm）----
  logic [5:0] perfHpm_perf_0_value;
  logic [5:0] perfHpm_perf_1_value;
  logic [5:0] perfHpm_perf_2_value;
  logic [5:0] perfHpm_perf_3_value;
  logic [5:0] perfHpm_perf_4_value;
  logic [5:0] perfHpm_perf_5_value;
  logic [5:0] perfHpm_perf_6_value;
  logic [5:0] perfHpm_perf_7_value;
  // ---- mbistIntf（inner_mbistIntf）----
  logic [6:0] mbistIntf_toPipeline_0_array;
  logic mbistIntf_toPipeline_0_all;
  logic mbistIntf_toPipeline_0_req;
  logic mbistIntf_toPipeline_0_writeen;
  logic [75:0] mbistIntf_toPipeline_0_be;
  logic [9:0] mbistIntf_toPipeline_0_addr;
  logic [75:0] mbistIntf_toPipeline_0_indata;
  logic mbistIntf_toPipeline_0_readen;
  logic [9:0] mbistIntf_toPipeline_0_addr_rd;
  // ---- mbistPl（inner_mbistPl）----
  logic mbistPl_mbist_ack;
  logic [75:0] mbistPl_mbist_outdata;
  logic [1:0] mbistBd0_array;
  logic mbistBd0_all;
  logic mbistBd0_req;
  logic mbistBd0_writeen;
  logic [1:0] mbistBd0_be;
  logic [7:0] mbistBd0_addr;
  logic [73:0] mbistBd0_indata;
  logic mbistBd0_readen;
  logic [7:0] mbistBd0_addr_rd;
  logic [3:0] mbistBd1_array;
  logic mbistBd1_all;
  logic mbistBd1_req;
  logic mbistBd1_writeen;
  logic mbistBd1_be;
  logic [8:0] mbistBd1_addr;
  logic [65:0] mbistBd1_indata;
  logic mbistBd1_readen;
  logic [8:0] mbistBd1_addr_rd;
  logic [4:0] mbistBd2_array;
  logic mbistBd2_all;
  logic mbistBd2_req;
  logic mbistBd2_writeen;
  logic mbistBd2_be;
  logic [8:0] mbistBd2_addr;
  logic [65:0] mbistBd2_indata;
  logic mbistBd2_readen;
  logic [8:0] mbistBd2_addr_rd;
  logic [4:0] mbistBd3_array;
  logic mbistBd3_all;
  logic mbistBd3_req;
  logic mbistBd3_writeen;
  logic mbistBd3_be;
  logic [8:0] mbistBd3_addr;
  logic [65:0] mbistBd3_indata;
  logic mbistBd3_readen;
  logic [8:0] mbistBd3_addr_rd;
  logic [5:0] mbistBd4_array;
  logic mbistBd4_all;
  logic mbistBd4_req;
  logic mbistBd4_writeen;
  logic mbistBd4_be;
  logic [8:0] mbistBd4_addr;
  logic [65:0] mbistBd4_indata;
  logic mbistBd4_readen;
  logic [8:0] mbistBd4_addr_rd;
  logic [5:0] mbistBd5_array;
  logic mbistBd5_all;
  logic mbistBd5_req;
  logic mbistBd5_writeen;
  logic [3:0] mbistBd5_be;
  logic [9:0] mbistBd5_addr;
  logic [39:0] mbistBd5_indata;
  logic mbistBd5_readen;
  logic [9:0] mbistBd5_addr_rd;
  logic [6:0] mbistBd6_array;
  logic mbistBd6_all;
  logic mbistBd6_req;
  logic mbistBd6_writeen;
  logic [15:0] mbistBd6_be;
  logic [9:0] mbistBd6_addr;
  logic [23:0] mbistBd6_indata;
  logic mbistBd6_readen;
  logic [9:0] mbistBd6_addr_rd;
  logic [6:0] mbistBd7_array;
  logic mbistBd7_all;
  logic mbistBd7_req;
  logic mbistBd7_writeen;
  logic [3:0] mbistBd7_be;
  logic [7:0] mbistBd7_addr;
  logic [23:0] mbistBd7_indata;
  logic mbistBd7_readen;
  logic [7:0] mbistBd7_addr_rd;
  logic [6:0] mbistBd8_array;
  logic mbistBd8_all;
  logic mbistBd8_req;
  logic mbistBd8_writeen;
  logic [3:0] mbistBd8_be;
  logic [7:0] mbistBd8_addr;
  logic [23:0] mbistBd8_indata;
  logic mbistBd8_readen;
  logic [7:0] mbistBd8_addr_rd;
  logic [6:0] mbistBd9_array;
  logic mbistBd9_all;
  logic mbistBd9_req;
  logic mbistBd9_writeen;
  logic [3:0] mbistBd9_be;
  logic [7:0] mbistBd9_addr;
  logic [23:0] mbistBd9_indata;
  logic mbistBd9_readen;
  logic [7:0] mbistBd9_addr_rd;
  logic [6:0] mbistBd10_array;
  logic mbistBd10_all;
  logic mbistBd10_req;
  logic mbistBd10_writeen;
  logic [3:0] mbistBd10_be;
  logic [7:0] mbistBd10_addr;
  logic [23:0] mbistBd10_indata;
  logic mbistBd10_readen;
  logic [7:0] mbistBd10_addr_rd;
  logic [6:0] mbistBd11_array;
  logic mbistBd11_all;
  logic mbistBd11_req;
  logic mbistBd11_writeen;
  logic [75:0] mbistBd11_be;
  logic [7:0] mbistBd11_addr;
  logic [75:0] mbistBd11_indata;
  logic mbistBd11_readen;
  logic [7:0] mbistBd11_addr_rd;
  logic [6:0] mbistBd12_array;
  logic mbistBd12_all;
  logic mbistBd12_req;
  logic mbistBd12_writeen;
  logic [75:0] mbistBd12_be;
  logic [7:0] mbistBd12_addr;
  logic [75:0] mbistBd12_indata;
  logic mbistBd12_readen;
  logic [7:0] mbistBd12_addr_rd;
  logic [6:0] mbistBd13_array;
  logic mbistBd13_all;
  logic mbistBd13_req;
  logic mbistBd13_writeen;
  logic [75:0] mbistBd13_be;
  logic [7:0] mbistBd13_addr;
  logic [75:0] mbistBd13_indata;
  logic mbistBd13_readen;
  logic [7:0] mbistBd13_addr_rd;
  logic [6:0] mbistBd14_array;
  logic mbistBd14_all;
  logic mbistBd14_req;
  logic mbistBd14_writeen;
  logic [75:0] mbistBd14_be;
  logic [7:0] mbistBd14_addr;
  logic [75:0] mbistBd14_indata;
  logic mbistBd14_readen;
  logic [7:0] mbistBd14_addr_rd;
  logic [6:0] mbistBd15_array;
  logic mbistBd15_all;
  logic mbistBd15_req;
  logic mbistBd15_writeen;
  logic [75:0] mbistBd15_be;
  logic [7:0] mbistBd15_addr;
  logic [75:0] mbistBd15_indata;
  logic mbistBd15_readen;
  logic [7:0] mbistBd15_addr_rd;
  // ---- 可读核产生、送进子模块的信号 ----
  logic redirect_flush;
  logic redirect_from_ctrl;
  logic redirect_from_memvio;
  logic sfence_dly_valid;
  logic sfence_dly_bits_rs1;
  logic sfence_dly_bits_rs2;
  logic [49:0] sfence_dly_bits_addr;
  logic [15:0] sfence_dly_bits_id;
  logic sfence_dly_bits_flushPipe;
  logic sfence_dly_bits_hv;
  logic sfence_dly_bits_hg;
  logic icache_pf_enable;
  logic icache_fencei;
  logic fetch_req_ready;
  logic wfi_safe_now;

  // ===========================================================================
  // 可读核：重定向分发 / CSR 与 sfence 打拍 / 取指握手 / wfi / 错误上报 / 性能 / 自检
  // ===========================================================================
  xs_Frontend_core u_core (
    .clock (clock),
    .reset (reset),
    .io_backend_toFtq_redirect_valid (io_backend_toFtq_redirect_valid),
    .io_backend_toFtq_redirect_bits_debugIsCtrl (io_backend_toFtq_redirect_bits_debugIsCtrl),
    .io_backend_toFtq_redirect_bits_debugIsMemVio (io_backend_toFtq_redirect_bits_debugIsMemVio),
    .redirect_flush (redirect_flush),
    .redirect_from_ctrl (redirect_from_ctrl),
    .redirect_from_memvio (redirect_from_memvio),
    .io_sfence_valid (io_sfence_valid),
    .io_sfence_bits_rs1 (io_sfence_bits_rs1),
    .io_sfence_bits_rs2 (io_sfence_bits_rs2),
    .io_sfence_bits_addr (io_sfence_bits_addr),
    .io_sfence_bits_id (io_sfence_bits_id),
    .io_sfence_bits_flushPipe (io_sfence_bits_flushPipe),
    .io_sfence_bits_hv (io_sfence_bits_hv),
    .io_sfence_bits_hg (io_sfence_bits_hg),
    .sfence_dly_valid (sfence_dly_valid),
    .sfence_dly_bits_rs1 (sfence_dly_bits_rs1),
    .sfence_dly_bits_rs2 (sfence_dly_bits_rs2),
    .sfence_dly_bits_addr (sfence_dly_bits_addr),
    .sfence_dly_bits_id (sfence_dly_bits_id),
    .sfence_dly_bits_flushPipe (sfence_dly_bits_flushPipe),
    .sfence_dly_bits_hv (sfence_dly_bits_hv),
    .sfence_dly_bits_hg (sfence_dly_bits_hg),
    .csrCtrlDelay_out_pf_ctrl_l1I_pf_enable (csrCtrlDelay_out_pf_ctrl_l1I_pf_enable),
    .io_fencei (io_fencei),
    .icache_pf_enable (icache_pf_enable),
    .icache_fencei (icache_fencei),
    .ifu_ftqInter_fromFtq_req_ready (ifu_ftqInter_fromFtq_req_ready),
    .icache_fetch_req_ready (icache_fetch_req_ready),
    .fetch_req_ready (fetch_req_ready),
    .wfiReqDelay_out (wfiReqDelay_out),
    .icache_wfi_wfiSafe (icache_wfi_wfiSafe),
    .instrUncache_wfi_wfiSafe (instrUncache_wfi_wfiSafe),
    .wfi_safe_now (wfi_safe_now),
    .icache_error_valid (icache_error_valid),
    .icache_error_bits_paddr (icache_error_bits_paddr),
    .icache_error_bits_report_to_beu (icache_error_bits_report_to_beu),
    .io_error_ecc_error_valid (io_error_ecc_error_valid),
    .io_error_ecc_error_bits (io_error_ecc_error_bits),
    .perfHpm_perf_0_value (perfHpm_perf_0_value),
    .perfHpm_perf_1_value (perfHpm_perf_1_value),
    .perfHpm_perf_2_value (perfHpm_perf_2_value),
    .perfHpm_perf_3_value (perfHpm_perf_3_value),
    .perfHpm_perf_4_value (perfHpm_perf_4_value),
    .perfHpm_perf_5_value (perfHpm_perf_5_value),
    .perfHpm_perf_6_value (perfHpm_perf_6_value),
    .perfHpm_perf_7_value (perfHpm_perf_7_value),
    .io_perf_0_value (io_perf_0_value),
    .io_perf_1_value (io_perf_1_value),
    .io_perf_2_value (io_perf_2_value),
    .io_perf_3_value (io_perf_3_value),
    .io_perf_4_value (io_perf_4_value),
    .io_perf_5_value (io_perf_5_value),
    .io_perf_6_value (io_perf_6_value),
    .io_perf_7_value (io_perf_7_value),
    .io_backend_cfVec_0_ready (io_backend_cfVec_0_ready),
    .io_backend_cfVec_1_ready (io_backend_cfVec_1_ready),
    .io_backend_cfVec_2_ready (io_backend_cfVec_2_ready),
    .io_backend_cfVec_3_ready (io_backend_cfVec_3_ready),
    .io_backend_cfVec_4_ready (io_backend_cfVec_4_ready),
    .io_backend_cfVec_5_ready (io_backend_cfVec_5_ready),
    .ibuffer_out_0_valid (ibuffer_out_0_valid),
    .ibuffer_out_0_bits_pc (ibuffer_out_0_bits_pc),
    .ibuffer_out_0_bits_pd_isRVC (ibuffer_out_0_bits_pd_isRVC),
    .ibuffer_out_0_bits_pd_brType (ibuffer_out_0_bits_pd_brType),
    .ibuffer_out_0_bits_pred_taken (ibuffer_out_0_bits_pred_taken),
    .ibuffer_out_0_bits_ftqPtr_flag (ibuffer_out_0_bits_ftqPtr_flag),
    .ibuffer_out_0_bits_ftqPtr_value (ibuffer_out_0_bits_ftqPtr_value),
    .ibuffer_out_1_valid (ibuffer_out_1_valid),
    .ibuffer_out_1_bits_pc (ibuffer_out_1_bits_pc),
    .ibuffer_out_1_bits_pd_isRVC (ibuffer_out_1_bits_pd_isRVC),
    .ibuffer_out_1_bits_pd_brType (ibuffer_out_1_bits_pd_brType),
    .ibuffer_out_1_bits_pred_taken (ibuffer_out_1_bits_pred_taken),
    .ibuffer_out_1_bits_ftqPtr_flag (ibuffer_out_1_bits_ftqPtr_flag),
    .ibuffer_out_1_bits_ftqPtr_value (ibuffer_out_1_bits_ftqPtr_value),
    .ibuffer_out_2_valid (ibuffer_out_2_valid),
    .ibuffer_out_2_bits_pc (ibuffer_out_2_bits_pc),
    .ibuffer_out_2_bits_pd_isRVC (ibuffer_out_2_bits_pd_isRVC),
    .ibuffer_out_2_bits_pd_brType (ibuffer_out_2_bits_pd_brType),
    .ibuffer_out_2_bits_pred_taken (ibuffer_out_2_bits_pred_taken),
    .ibuffer_out_2_bits_ftqPtr_flag (ibuffer_out_2_bits_ftqPtr_flag),
    .ibuffer_out_2_bits_ftqPtr_value (ibuffer_out_2_bits_ftqPtr_value),
    .ibuffer_out_3_valid (ibuffer_out_3_valid),
    .ibuffer_out_3_bits_pc (ibuffer_out_3_bits_pc),
    .ibuffer_out_3_bits_pd_isRVC (ibuffer_out_3_bits_pd_isRVC),
    .ibuffer_out_3_bits_pd_brType (ibuffer_out_3_bits_pd_brType),
    .ibuffer_out_3_bits_pred_taken (ibuffer_out_3_bits_pred_taken),
    .ibuffer_out_3_bits_ftqPtr_flag (ibuffer_out_3_bits_ftqPtr_flag),
    .ibuffer_out_3_bits_ftqPtr_value (ibuffer_out_3_bits_ftqPtr_value),
    .ibuffer_out_4_valid (ibuffer_out_4_valid),
    .ibuffer_out_4_bits_pc (ibuffer_out_4_bits_pc),
    .ibuffer_out_4_bits_pd_isRVC (ibuffer_out_4_bits_pd_isRVC),
    .ibuffer_out_4_bits_pd_brType (ibuffer_out_4_bits_pd_brType),
    .ibuffer_out_4_bits_pred_taken (ibuffer_out_4_bits_pred_taken),
    .ibuffer_out_4_bits_ftqPtr_flag (ibuffer_out_4_bits_ftqPtr_flag),
    .ibuffer_out_4_bits_ftqPtr_value (ibuffer_out_4_bits_ftqPtr_value),
    .ibuffer_out_5_valid (ibuffer_out_5_valid),
    .ibuffer_out_5_bits_pc (ibuffer_out_5_bits_pc),
    .ibuffer_out_5_bits_pd_isRVC (ibuffer_out_5_bits_pd_isRVC),
    .ibuffer_out_5_bits_pd_brType (ibuffer_out_5_bits_pd_brType),
    .ibuffer_out_5_bits_pred_taken (ibuffer_out_5_bits_pred_taken),
    .ibuffer_out_5_bits_ftqPtr_flag (ibuffer_out_5_bits_ftqPtr_flag),
    .ibuffer_out_5_bits_ftqPtr_value (ibuffer_out_5_bits_ftqPtr_value),
    .ftq_toBackend_pc_mem_wen (ftq_toBackend_pc_mem_wen),
    .ftq_toBackend_pc_mem_waddr (ftq_toBackend_pc_mem_waddr),
    .ftq_toBackend_pc_mem_wdata_startAddr (ftq_toBackend_pc_mem_wdata_startAddr),
    .ftq_toBackend_newest_entry_target (ftq_toBackend_newest_entry_target),
    .ftq_toBackend_newest_entry_ptr_value (ftq_toBackend_newest_entry_ptr_value)
  );

  // ===========================================================================
  // §A 预测与取指主干：BPU → FTQ → ICache / IFU → IBuffer，外加 MMIO 取指
  // ===========================================================================
  Predictor inner_bpu (
    // ---- 时钟 / 复位 ----
    .clock                                                             (clock),
    .reset                                                             (reset),
    // ---- ← ftq：BPU 的 s1/s2/s3 预测结果写入 FTQ；FTQ 回送重定向（误预测恢复）与提交后的更新 ----
    .io_bpu_to_ftq_resp_ready                                          (ftq_fromBpu_resp_ready),
    .io_ftq_to_bpu_redirect_valid                                      (ftq_toBpu_redirect_valid),
    .io_ftq_to_bpu_redirect_bits_level                                 (ftq_toBpu_redirect_bits_level),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pc                          (ftq_toBpu_redirect_bits_cfiUpdate_pc),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid                    (ftq_toBpu_redirect_bits_cfiUpdate_pd_valid),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC                    (ftq_toBpu_redirect_bits_cfiUpdate_pd_isRVC),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall                   (ftq_toBpu_redirect_bits_cfiUpdate_pd_isCall),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet                    (ftq_toBpu_redirect_bits_cfiUpdate_pd_isRet),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp                         (ftq_toBpu_redirect_bits_cfiUpdate_ssp),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr                        (ftq_toBpu_redirect_bits_cfiUpdate_sctr),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag                   (ftq_toBpu_redirect_bits_cfiUpdate_TOSW_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value                  (ftq_toBpu_redirect_bits_cfiUpdate_TOSW_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag                   (ftq_toBpu_redirect_bits_cfiUpdate_TOSR_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value                  (ftq_toBpu_redirect_bits_cfiUpdate_TOSR_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag                    (ftq_toBpu_redirect_bits_cfiUpdate_NOS_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value                   (ftq_toBpu_redirect_bits_cfiUpdate_NOS_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag                (ftq_toBpu_redirect_bits_cfiUpdate_histPtr_flag),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value               (ftq_toBpu_redirect_bits_cfiUpdate_histPtr_value),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit                      (ftq_toBpu_redirect_bits_cfiUpdate_br_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit                      (ftq_toBpu_redirect_bits_cfiUpdate_jr_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit                      (ftq_toBpu_redirect_bits_cfiUpdate_sc_hit),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_target                      (ftq_toBpu_redirect_bits_cfiUpdate_target),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_taken                       (ftq_toBpu_redirect_bits_cfiUpdate_taken),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_shift                       (ftq_toBpu_redirect_bits_cfiUpdate_shift),
    .io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist                 (ftq_toBpu_redirect_bits_cfiUpdate_addIntoHist),
    .io_ftq_to_bpu_redirect_bits_debugIsCtrl                           (ftq_toBpu_redirect_bits_debugIsCtrl),
    .io_ftq_to_bpu_redirect_bits_debugIsMemVio                         (ftq_toBpu_redirect_bits_debugIsMemVio),
    .io_ftq_to_bpu_redirect_bits_BTBMissBubble                         (ftq_toBpu_redirect_bits_BTBMissBubble),
    .io_ftq_to_bpu_update_valid                                        (ftq_toBpu_update_valid),
    .io_ftq_to_bpu_update_bits_pc                                      (ftq_toBpu_update_bits_pc),
    .io_ftq_to_bpu_update_bits_spec_info_histPtr_value                 (ftq_toBpu_update_bits_spec_info_histPtr_value),
    .io_ftq_to_bpu_update_bits_ftb_entry_isCall                        (ftq_toBpu_update_bits_ftb_entry_isCall),
    .io_ftq_to_bpu_update_bits_ftb_entry_isRet                         (ftq_toBpu_update_bits_ftb_entry_isRet),
    .io_ftq_to_bpu_update_bits_ftb_entry_isJalr                        (ftq_toBpu_update_bits_ftb_entry_isJalr),
    .io_ftq_to_bpu_update_bits_ftb_entry_valid                         (ftq_toBpu_update_bits_ftb_entry_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset              (ftq_toBpu_update_bits_ftb_entry_brSlots_0_offset),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing             (ftq_toBpu_update_bits_ftb_entry_brSlots_0_sharing),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid               (ftq_toBpu_update_bits_ftb_entry_brSlots_0_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower               (ftq_toBpu_update_bits_ftb_entry_brSlots_0_lower),
    .io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat             (ftq_toBpu_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset               (ftq_toBpu_update_bits_ftb_entry_tailSlot_offset),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing              (ftq_toBpu_update_bits_ftb_entry_tailSlot_sharing),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid                (ftq_toBpu_update_bits_ftb_entry_tailSlot_valid),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower                (ftq_toBpu_update_bits_ftb_entry_tailSlot_lower),
    .io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat              (ftq_toBpu_update_bits_ftb_entry_tailSlot_tarStat),
    .io_ftq_to_bpu_update_bits_ftb_entry_pftAddr                       (ftq_toBpu_update_bits_ftb_entry_pftAddr),
    .io_ftq_to_bpu_update_bits_ftb_entry_carry                         (ftq_toBpu_update_bits_ftb_entry_carry),
    .io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call          (ftq_toBpu_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0                 (ftq_toBpu_update_bits_ftb_entry_strong_bias_0),
    .io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1                 (ftq_toBpu_update_bits_ftb_entry_strong_bias_1),
    .io_ftq_to_bpu_update_bits_cfi_idx_valid                           (ftq_toBpu_update_bits_cfi_idx_valid),
    .io_ftq_to_bpu_update_bits_cfi_idx_bits                            (ftq_toBpu_update_bits_cfi_idx_bits),
    .io_ftq_to_bpu_update_bits_br_taken_mask_0                         (ftq_toBpu_update_bits_br_taken_mask_0),
    .io_ftq_to_bpu_update_bits_br_taken_mask_1                         (ftq_toBpu_update_bits_br_taken_mask_1),
    .io_ftq_to_bpu_update_bits_jmp_taken                               (ftq_toBpu_update_bits_jmp_taken),
    .io_ftq_to_bpu_update_bits_mispred_mask_0                          (ftq_toBpu_update_bits_mispred_mask_0),
    .io_ftq_to_bpu_update_bits_mispred_mask_1                          (ftq_toBpu_update_bits_mispred_mask_1),
    .io_ftq_to_bpu_update_bits_mispred_mask_2                          (ftq_toBpu_update_bits_mispred_mask_2),
    .io_ftq_to_bpu_update_bits_false_hit                               (ftq_toBpu_update_bits_false_hit),
    .io_ftq_to_bpu_update_bits_old_entry                               (ftq_toBpu_update_bits_old_entry),
    .io_ftq_to_bpu_update_bits_meta                                    (ftq_toBpu_update_bits_meta),
    .io_ftq_to_bpu_update_bits_full_target                             (ftq_toBpu_update_bits_full_target),
    .io_ftq_to_bpu_enq_ptr_flag                                        (ftq_toBpu_enq_ptr_flag),
    .io_ftq_to_bpu_enq_ptr_value                                       (ftq_toBpu_enq_ptr_value),
    .io_ftq_to_bpu_redirctFromIFU                                      (ftq_toBpu_redirctFromIFU),
    // ---- → ftq（BPU 的 s1/s2/s3 预测结果写入 FTQ；FTQ 回送重定向（误预测恢复）与提交后的更新） ----
    .io_bpu_to_ftq_resp_valid                                          (bpu_bpu_to_ftq_resp_valid),
    .io_bpu_to_ftq_resp_bits_s1_pc_3                                   (bpu_bpu_to_ftq_resp_bits_s1_pc_3),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0            (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1            (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0              (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1              (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr            (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr             (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing              (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit                        (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_s2_pc_3                                   (bpu_bpu_to_ftq_resp_bits_s2_pc_3),
    .io_bpu_to_ftq_resp_bits_s2_valid_3                                (bpu_bpu_to_ftq_resp_bits_s2_valid_3),
    .io_bpu_to_ftq_resp_bits_s2_hasRedirect_3                          (bpu_bpu_to_ftq_resp_bits_s2_hasRedirect_3),
    .io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag                           (bpu_bpu_to_ftq_resp_bits_s2_ftq_idx_flag),
    .io_bpu_to_ftq_resp_bits_s2_ftq_idx_value                          (bpu_bpu_to_ftq_resp_bits_s2_ftq_idx_value),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0            (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1            (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0              (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1              (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr            (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr             (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing              (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit                        (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_s3_pc_0                                   (bpu_bpu_to_ftq_resp_bits_s3_pc_0),
    .io_bpu_to_ftq_resp_bits_s3_pc_3                                   (bpu_bpu_to_ftq_resp_bits_s3_pc_3),
    .io_bpu_to_ftq_resp_bits_s3_valid_3                                (bpu_bpu_to_ftq_resp_bits_s3_valid_3),
    .io_bpu_to_ftq_resp_bits_s3_hasRedirect_3                          (bpu_bpu_to_ftq_resp_bits_s3_hasRedirect_3),
    .io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag                           (bpu_bpu_to_ftq_resp_bits_s3_ftq_idx_flag),
    .io_bpu_to_ftq_resp_bits_s3_ftq_idx_value                          (bpu_bpu_to_ftq_resp_bits_s3_ftq_idx_value),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0            (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1            (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0              (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1              (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr            (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr             (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing              (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing),
    .io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit                        (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_hit),
    .io_bpu_to_ftq_resp_bits_last_stage_meta                           (bpu_bpu_to_ftq_resp_bits_last_stage_meta),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag         (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value        (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp                  (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr                 (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag            (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value           (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag            (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value           (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag             (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value            (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr              (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0        (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0),
    .io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1        (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall               (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet                (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr               (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid                (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset     (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing    (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid      (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower      (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat    (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset      (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing     (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid       (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower       (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat     (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr              (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry                (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0        (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0),
    .io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1        (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_1                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_1),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_2                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_2),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_3                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_3),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_4                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_4),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_5                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_5),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_6                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_6),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_7                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_7),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_8                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_8),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_9                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_9),
    .io_bpu_to_ftq_resp_bits_topdown_info_reasons_12                   (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_12),
    // ---- 无读者的输出（golden 同样悬空） ----
    .io_bpu_to_ftq_resp_bits_s3_valid_0                                (),
    // ---- ← csrCtrlDelay：分支预测器各部件开关（bp_ctrl，CSR 打两拍后） ----
    .io_ctrl_ubtb_enable                                               (csrCtrlDelay_out_bp_ctrl_ubtb_enable),
    .io_ctrl_btb_enable                                                (csrCtrlDelay_out_bp_ctrl_btb_enable),
    .io_ctrl_tage_enable                                               (csrCtrlDelay_out_bp_ctrl_tage_enable),
    .io_ctrl_sc_enable                                                 (csrCtrlDelay_out_bp_ctrl_sc_enable),
    .io_ctrl_ras_enable                                                (csrCtrlDelay_out_bp_ctrl_ras_enable),
    // ---- 顶层 io_reset_vector* —— 复位向量 ----
    .io_reset_vector                                                   (io_reset_vector),
    // ---- → perfHpm（BPU 性能事件） ----
    .io_perf_0_value                                                   (bpu_perf_0_value),
    .io_perf_1_value                                                   (bpu_perf_1_value),
    .io_perf_2_value                                                   (bpu_perf_2_value),
    .io_perf_3_value                                                   (bpu_perf_3_value),
    .io_perf_4_value                                                   (bpu_perf_4_value),
    .io_perf_5_value                                                   (bpu_perf_5_value),
    .io_perf_6_value                                                   (bpu_perf_6_value),
    // ---- ← mbistPl：BPU 内各预测表 SRAM 的 MBIST 穿线 ----
    .boreChildrenBd_bore_array                                         (mbistBd5_array),
    .boreChildrenBd_bore_all                                           (mbistBd5_all),
    .boreChildrenBd_bore_req                                           (mbistBd5_req),
    .boreChildrenBd_bore_writeen                                       (mbistBd5_writeen),
    .boreChildrenBd_bore_be                                            (mbistBd5_be),
    .boreChildrenBd_bore_addr                                          (mbistBd5_addr),
    .boreChildrenBd_bore_indata                                        (mbistBd5_indata),
    .boreChildrenBd_bore_readen                                        (mbistBd5_readen),
    .boreChildrenBd_bore_addr_rd                                       (mbistBd5_addr_rd),
    .boreChildrenBd_bore_1_array                                       (mbistBd6_array),
    .boreChildrenBd_bore_1_all                                         (mbistBd6_all),
    .boreChildrenBd_bore_1_req                                         (mbistBd6_req),
    .boreChildrenBd_bore_1_writeen                                     (mbistBd6_writeen),
    .boreChildrenBd_bore_1_be                                          (mbistBd6_be),
    .boreChildrenBd_bore_1_addr                                        (mbistBd6_addr),
    .boreChildrenBd_bore_1_indata                                      (mbistBd6_indata),
    .boreChildrenBd_bore_1_readen                                      (mbistBd6_readen),
    .boreChildrenBd_bore_1_addr_rd                                     (mbistBd6_addr_rd),
    .boreChildrenBd_bore_2_array                                       (mbistBd7_array),
    .boreChildrenBd_bore_2_all                                         (mbistBd7_all),
    .boreChildrenBd_bore_2_req                                         (mbistBd7_req),
    .boreChildrenBd_bore_2_writeen                                     (mbistBd7_writeen),
    .boreChildrenBd_bore_2_be                                          (mbistBd7_be),
    .boreChildrenBd_bore_2_addr                                        (mbistBd7_addr),
    .boreChildrenBd_bore_2_indata                                      (mbistBd7_indata),
    .boreChildrenBd_bore_2_readen                                      (mbistBd7_readen),
    .boreChildrenBd_bore_2_addr_rd                                     (mbistBd7_addr_rd),
    .boreChildrenBd_bore_3_array                                       (mbistBd8_array),
    .boreChildrenBd_bore_3_all                                         (mbistBd8_all),
    .boreChildrenBd_bore_3_req                                         (mbistBd8_req),
    .boreChildrenBd_bore_3_writeen                                     (mbistBd8_writeen),
    .boreChildrenBd_bore_3_be                                          (mbistBd8_be),
    .boreChildrenBd_bore_3_addr                                        (mbistBd8_addr),
    .boreChildrenBd_bore_3_indata                                      (mbistBd8_indata),
    .boreChildrenBd_bore_3_readen                                      (mbistBd8_readen),
    .boreChildrenBd_bore_3_addr_rd                                     (mbistBd8_addr_rd),
    .boreChildrenBd_bore_4_array                                       (mbistBd9_array),
    .boreChildrenBd_bore_4_all                                         (mbistBd9_all),
    .boreChildrenBd_bore_4_req                                         (mbistBd9_req),
    .boreChildrenBd_bore_4_writeen                                     (mbistBd9_writeen),
    .boreChildrenBd_bore_4_be                                          (mbistBd9_be),
    .boreChildrenBd_bore_4_addr                                        (mbistBd9_addr),
    .boreChildrenBd_bore_4_indata                                      (mbistBd9_indata),
    .boreChildrenBd_bore_4_readen                                      (mbistBd9_readen),
    .boreChildrenBd_bore_4_addr_rd                                     (mbistBd9_addr_rd),
    .boreChildrenBd_bore_5_array                                       (mbistBd10_array),
    .boreChildrenBd_bore_5_all                                         (mbistBd10_all),
    .boreChildrenBd_bore_5_req                                         (mbistBd10_req),
    .boreChildrenBd_bore_5_writeen                                     (mbistBd10_writeen),
    .boreChildrenBd_bore_5_be                                          (mbistBd10_be),
    .boreChildrenBd_bore_5_addr                                        (mbistBd10_addr),
    .boreChildrenBd_bore_5_indata                                      (mbistBd10_indata),
    .boreChildrenBd_bore_5_readen                                      (mbistBd10_readen),
    .boreChildrenBd_bore_5_addr_rd                                     (mbistBd10_addr_rd),
    .boreChildrenBd_bore_6_array                                       (mbistBd11_array),
    .boreChildrenBd_bore_6_all                                         (mbistBd11_all),
    .boreChildrenBd_bore_6_req                                         (mbistBd11_req),
    .boreChildrenBd_bore_6_writeen                                     (mbistBd11_writeen),
    .boreChildrenBd_bore_6_be                                          (mbistBd11_be),
    .boreChildrenBd_bore_6_addr                                        (mbistBd11_addr),
    .boreChildrenBd_bore_6_indata                                      (mbistBd11_indata),
    .boreChildrenBd_bore_6_readen                                      (mbistBd11_readen),
    .boreChildrenBd_bore_6_addr_rd                                     (mbistBd11_addr_rd),
    .boreChildrenBd_bore_7_array                                       (mbistBd12_array),
    .boreChildrenBd_bore_7_all                                         (mbistBd12_all),
    .boreChildrenBd_bore_7_req                                         (mbistBd12_req),
    .boreChildrenBd_bore_7_writeen                                     (mbistBd12_writeen),
    .boreChildrenBd_bore_7_be                                          (mbistBd12_be),
    .boreChildrenBd_bore_7_addr                                        (mbistBd12_addr),
    .boreChildrenBd_bore_7_indata                                      (mbistBd12_indata),
    .boreChildrenBd_bore_7_readen                                      (mbistBd12_readen),
    .boreChildrenBd_bore_7_addr_rd                                     (mbistBd12_addr_rd),
    .boreChildrenBd_bore_8_array                                       (mbistBd13_array),
    .boreChildrenBd_bore_8_all                                         (mbistBd13_all),
    .boreChildrenBd_bore_8_req                                         (mbistBd13_req),
    .boreChildrenBd_bore_8_writeen                                     (mbistBd13_writeen),
    .boreChildrenBd_bore_8_be                                          (mbistBd13_be),
    .boreChildrenBd_bore_8_addr                                        (mbistBd13_addr),
    .boreChildrenBd_bore_8_indata                                      (mbistBd13_indata),
    .boreChildrenBd_bore_8_readen                                      (mbistBd13_readen),
    .boreChildrenBd_bore_8_addr_rd                                     (mbistBd13_addr_rd),
    .boreChildrenBd_bore_9_array                                       (mbistBd14_array),
    .boreChildrenBd_bore_9_all                                         (mbistBd14_all),
    .boreChildrenBd_bore_9_req                                         (mbistBd14_req),
    .boreChildrenBd_bore_9_writeen                                     (mbistBd14_writeen),
    .boreChildrenBd_bore_9_be                                          (mbistBd14_be),
    .boreChildrenBd_bore_9_addr                                        (mbistBd14_addr),
    .boreChildrenBd_bore_9_indata                                      (mbistBd14_indata),
    .boreChildrenBd_bore_9_readen                                      (mbistBd14_readen),
    .boreChildrenBd_bore_9_addr_rd                                     (mbistBd14_addr_rd),
    .boreChildrenBd_bore_10_array                                      (mbistBd15_array),
    .boreChildrenBd_bore_10_all                                        (mbistBd15_all),
    .boreChildrenBd_bore_10_req                                        (mbistBd15_req),
    .boreChildrenBd_bore_10_writeen                                    (mbistBd15_writeen),
    .boreChildrenBd_bore_10_be                                         (mbistBd15_be),
    .boreChildrenBd_bore_10_addr                                       (mbistBd15_addr),
    .boreChildrenBd_bore_10_indata                                     (mbistBd15_indata),
    .boreChildrenBd_bore_10_readen                                     (mbistBd15_readen),
    .boreChildrenBd_bore_10_addr_rd                                    (mbistBd15_addr_rd),
    // ---- → mbistPl（BPU 内各预测表 SRAM 的 MBIST 穿线） ----
    .boreChildrenBd_bore_ack                                           (mbistBd5_ack),
    .boreChildrenBd_bore_outdata                                       (mbistBd5_outdata),
    .boreChildrenBd_bore_1_ack                                         (mbistBd6_ack),
    .boreChildrenBd_bore_1_outdata                                     (mbistBd6_outdata),
    .boreChildrenBd_bore_2_ack                                         (mbistBd7_ack),
    .boreChildrenBd_bore_2_outdata                                     (mbistBd7_outdata),
    .boreChildrenBd_bore_3_ack                                         (mbistBd8_ack),
    .boreChildrenBd_bore_3_outdata                                     (mbistBd8_outdata),
    .boreChildrenBd_bore_4_ack                                         (mbistBd9_ack),
    .boreChildrenBd_bore_4_outdata                                     (mbistBd9_outdata),
    .boreChildrenBd_bore_5_ack                                         (mbistBd10_ack),
    .boreChildrenBd_bore_5_outdata                                     (mbistBd10_outdata),
    .boreChildrenBd_bore_6_ack                                         (mbistBd11_ack),
    .boreChildrenBd_bore_6_outdata                                     (mbistBd11_outdata),
    .boreChildrenBd_bore_7_ack                                         (mbistBd12_ack),
    .boreChildrenBd_bore_7_outdata                                     (mbistBd12_outdata),
    .boreChildrenBd_bore_8_ack                                         (mbistBd13_ack),
    .boreChildrenBd_bore_8_outdata                                     (mbistBd13_outdata),
    .boreChildrenBd_bore_9_ack                                         (mbistBd14_ack),
    .boreChildrenBd_bore_9_outdata                                     (mbistBd14_outdata),
    .boreChildrenBd_bore_10_ack                                        (mbistBd15_ack),
    .boreChildrenBd_bore_10_outdata                                    (mbistBd15_outdata),
    // ---- 顶层 io_dft* —— DFT 广播（SRAM 测试控制） ----
    .sigFromSrams_bore_ram_hold                                        (io_dft_ram_hold),
    .sigFromSrams_bore_ram_bypass                                      (io_dft_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken                                    (io_dft_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk                                     (io_dft_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp                                    (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold                                    (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_cgen                                            (io_dft_cgen),
    .sigFromSrams_bore_1_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_1_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_2_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_2_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_3_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_3_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_4_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_4_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_5_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_5_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_6_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_6_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_7_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_7_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_8_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_8_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_9_ram_hold                                      (io_dft_ram_hold),
    .sigFromSrams_bore_9_ram_bypass                                    (io_dft_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken                                  (io_dft_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk                                   (io_dft_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp                                  (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold                                  (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                                          (io_dft_cgen),
    .sigFromSrams_bore_10_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_10_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_11_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_11_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_12_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_12_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_13_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_13_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_14_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_14_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_15_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_15_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_16_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_16_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_17_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_17_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_18_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_18_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_19_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_19_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_20_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_20_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_21_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_21_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_22_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_22_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_23_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_23_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_24_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_24_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_25_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_25_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_26_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_26_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_27_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_27_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_28_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_28_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_29_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_29_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_30_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_30_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_31_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_31_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_32_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_32_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_33_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_33_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_34_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_34_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_35_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_35_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_36_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_36_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_36_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_36_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_36_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_36_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_36_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_37_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_37_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_37_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_37_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_37_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_37_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_37_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_38_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_38_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_38_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_38_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_38_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_38_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_38_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_39_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_39_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_39_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_39_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_39_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_39_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_39_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_40_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_40_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_40_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_40_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_40_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_40_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_40_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_41_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_41_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_41_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_41_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_41_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_41_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_41_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_42_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_42_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_42_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_42_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_42_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_42_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_42_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_43_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_43_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_43_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_43_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_43_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_43_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_43_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_44_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_44_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_44_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_44_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_44_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_44_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_44_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_45_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_45_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_45_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_45_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_45_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_45_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_45_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_46_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_46_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_46_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_46_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_46_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_46_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_46_cgen                                         (io_dft_cgen),
    .sigFromSrams_bore_47_ram_hold                                     (io_dft_ram_hold),
    .sigFromSrams_bore_47_ram_bypass                                   (io_dft_ram_bypass),
    .sigFromSrams_bore_47_ram_bp_clken                                 (io_dft_ram_bp_clken),
    .sigFromSrams_bore_47_ram_aux_clk                                  (io_dft_ram_aux_clk),
    .sigFromSrams_bore_47_ram_aux_ckbp                                 (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_47_ram_mcp_hold                                 (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_47_cgen                                         (io_dft_cgen)
  );
  Ftq inner_ftq (
    // ---- 时钟 / 复位 ----
    .clock                                                          (clock),
    .reset                                                          (reset),
    // ---- → bpu（BPU 的 s1/s2/s3 预测结果写入 FTQ；FTQ 回送重定向（误预测恢复）与提交后的更新） ----
    .io_fromBpu_resp_ready                                          (ftq_fromBpu_resp_ready),
    .io_toBpu_redirect_valid                                        (ftq_toBpu_redirect_valid),
    .io_toBpu_redirect_bits_level                                   (ftq_toBpu_redirect_bits_level),
    .io_toBpu_redirect_bits_cfiUpdate_pc                            (ftq_toBpu_redirect_bits_cfiUpdate_pc),
    .io_toBpu_redirect_bits_cfiUpdate_pd_valid                      (ftq_toBpu_redirect_bits_cfiUpdate_pd_valid),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isRVC                      (ftq_toBpu_redirect_bits_cfiUpdate_pd_isRVC),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isCall                     (ftq_toBpu_redirect_bits_cfiUpdate_pd_isCall),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isRet                      (ftq_toBpu_redirect_bits_cfiUpdate_pd_isRet),
    .io_toBpu_redirect_bits_cfiUpdate_ssp                           (ftq_toBpu_redirect_bits_cfiUpdate_ssp),
    .io_toBpu_redirect_bits_cfiUpdate_sctr                          (ftq_toBpu_redirect_bits_cfiUpdate_sctr),
    .io_toBpu_redirect_bits_cfiUpdate_TOSW_flag                     (ftq_toBpu_redirect_bits_cfiUpdate_TOSW_flag),
    .io_toBpu_redirect_bits_cfiUpdate_TOSW_value                    (ftq_toBpu_redirect_bits_cfiUpdate_TOSW_value),
    .io_toBpu_redirect_bits_cfiUpdate_TOSR_flag                     (ftq_toBpu_redirect_bits_cfiUpdate_TOSR_flag),
    .io_toBpu_redirect_bits_cfiUpdate_TOSR_value                    (ftq_toBpu_redirect_bits_cfiUpdate_TOSR_value),
    .io_toBpu_redirect_bits_cfiUpdate_NOS_flag                      (ftq_toBpu_redirect_bits_cfiUpdate_NOS_flag),
    .io_toBpu_redirect_bits_cfiUpdate_NOS_value                     (ftq_toBpu_redirect_bits_cfiUpdate_NOS_value),
    .io_toBpu_redirect_bits_cfiUpdate_histPtr_flag                  (ftq_toBpu_redirect_bits_cfiUpdate_histPtr_flag),
    .io_toBpu_redirect_bits_cfiUpdate_histPtr_value                 (ftq_toBpu_redirect_bits_cfiUpdate_histPtr_value),
    .io_toBpu_redirect_bits_cfiUpdate_br_hit                        (ftq_toBpu_redirect_bits_cfiUpdate_br_hit),
    .io_toBpu_redirect_bits_cfiUpdate_jr_hit                        (ftq_toBpu_redirect_bits_cfiUpdate_jr_hit),
    .io_toBpu_redirect_bits_cfiUpdate_sc_hit                        (ftq_toBpu_redirect_bits_cfiUpdate_sc_hit),
    .io_toBpu_redirect_bits_cfiUpdate_target                        (ftq_toBpu_redirect_bits_cfiUpdate_target),
    .io_toBpu_redirect_bits_cfiUpdate_taken                         (ftq_toBpu_redirect_bits_cfiUpdate_taken),
    .io_toBpu_redirect_bits_cfiUpdate_shift                         (ftq_toBpu_redirect_bits_cfiUpdate_shift),
    .io_toBpu_redirect_bits_cfiUpdate_addIntoHist                   (ftq_toBpu_redirect_bits_cfiUpdate_addIntoHist),
    .io_toBpu_redirect_bits_debugIsCtrl                             (ftq_toBpu_redirect_bits_debugIsCtrl),
    .io_toBpu_redirect_bits_debugIsMemVio                           (ftq_toBpu_redirect_bits_debugIsMemVio),
    .io_toBpu_redirect_bits_BTBMissBubble                           (ftq_toBpu_redirect_bits_BTBMissBubble),
    .io_toBpu_update_valid                                          (ftq_toBpu_update_valid),
    .io_toBpu_update_bits_pc                                        (ftq_toBpu_update_bits_pc),
    .io_toBpu_update_bits_spec_info_histPtr_value                   (ftq_toBpu_update_bits_spec_info_histPtr_value),
    .io_toBpu_update_bits_ftb_entry_isCall                          (ftq_toBpu_update_bits_ftb_entry_isCall),
    .io_toBpu_update_bits_ftb_entry_isRet                           (ftq_toBpu_update_bits_ftb_entry_isRet),
    .io_toBpu_update_bits_ftb_entry_isJalr                          (ftq_toBpu_update_bits_ftb_entry_isJalr),
    .io_toBpu_update_bits_ftb_entry_valid                           (ftq_toBpu_update_bits_ftb_entry_valid),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_offset                (ftq_toBpu_update_bits_ftb_entry_brSlots_0_offset),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_sharing               (ftq_toBpu_update_bits_ftb_entry_brSlots_0_sharing),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_valid                 (ftq_toBpu_update_bits_ftb_entry_brSlots_0_valid),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_lower                 (ftq_toBpu_update_bits_ftb_entry_brSlots_0_lower),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat               (ftq_toBpu_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_toBpu_update_bits_ftb_entry_tailSlot_offset                 (ftq_toBpu_update_bits_ftb_entry_tailSlot_offset),
    .io_toBpu_update_bits_ftb_entry_tailSlot_sharing                (ftq_toBpu_update_bits_ftb_entry_tailSlot_sharing),
    .io_toBpu_update_bits_ftb_entry_tailSlot_valid                  (ftq_toBpu_update_bits_ftb_entry_tailSlot_valid),
    .io_toBpu_update_bits_ftb_entry_tailSlot_lower                  (ftq_toBpu_update_bits_ftb_entry_tailSlot_lower),
    .io_toBpu_update_bits_ftb_entry_tailSlot_tarStat                (ftq_toBpu_update_bits_ftb_entry_tailSlot_tarStat),
    .io_toBpu_update_bits_ftb_entry_pftAddr                         (ftq_toBpu_update_bits_ftb_entry_pftAddr),
    .io_toBpu_update_bits_ftb_entry_carry                           (ftq_toBpu_update_bits_ftb_entry_carry),
    .io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call            (ftq_toBpu_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_toBpu_update_bits_ftb_entry_strong_bias_0                   (ftq_toBpu_update_bits_ftb_entry_strong_bias_0),
    .io_toBpu_update_bits_ftb_entry_strong_bias_1                   (ftq_toBpu_update_bits_ftb_entry_strong_bias_1),
    .io_toBpu_update_bits_cfi_idx_valid                             (ftq_toBpu_update_bits_cfi_idx_valid),
    .io_toBpu_update_bits_cfi_idx_bits                              (ftq_toBpu_update_bits_cfi_idx_bits),
    .io_toBpu_update_bits_br_taken_mask_0                           (ftq_toBpu_update_bits_br_taken_mask_0),
    .io_toBpu_update_bits_br_taken_mask_1                           (ftq_toBpu_update_bits_br_taken_mask_1),
    .io_toBpu_update_bits_jmp_taken                                 (ftq_toBpu_update_bits_jmp_taken),
    .io_toBpu_update_bits_mispred_mask_0                            (ftq_toBpu_update_bits_mispred_mask_0),
    .io_toBpu_update_bits_mispred_mask_1                            (ftq_toBpu_update_bits_mispred_mask_1),
    .io_toBpu_update_bits_mispred_mask_2                            (ftq_toBpu_update_bits_mispred_mask_2),
    .io_toBpu_update_bits_false_hit                                 (ftq_toBpu_update_bits_false_hit),
    .io_toBpu_update_bits_old_entry                                 (ftq_toBpu_update_bits_old_entry),
    .io_toBpu_update_bits_meta                                      (ftq_toBpu_update_bits_meta),
    .io_toBpu_update_bits_full_target                               (ftq_toBpu_update_bits_full_target),
    .io_toBpu_enq_ptr_flag                                          (ftq_toBpu_enq_ptr_flag),
    .io_toBpu_enq_ptr_value                                         (ftq_toBpu_enq_ptr_value),
    .io_toBpu_redirctFromIFU                                        (ftq_toBpu_redirctFromIFU),
    // ---- ← bpu：BPU 的 s1/s2/s3 预测结果写入 FTQ；FTQ 回送重定向（误预测恢复）与提交后的更新 ----
    .io_fromBpu_resp_valid                                          (bpu_bpu_to_ftq_resp_valid),
    .io_fromBpu_resp_bits_s1_pc_3                                   (bpu_bpu_to_ftq_resp_bits_s1_pc_3),
    .io_fromBpu_resp_bits_s1_full_pred_0_predCycle                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0            (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1            (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0              (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1              (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_targets_0                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_targets_1                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_offsets_0                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_offsets_1                  (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr            (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr             (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing              (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s1_full_pred_3_hit                        (bpu_bpu_to_ftq_resp_bits_s1_full_pred_3_hit),
    .io_fromBpu_resp_bits_s2_pc_3                                   (bpu_bpu_to_ftq_resp_bits_s2_pc_3),
    .io_fromBpu_resp_bits_s2_valid_3                                (bpu_bpu_to_ftq_resp_bits_s2_valid_3),
    .io_fromBpu_resp_bits_s2_hasRedirect_3                          (bpu_bpu_to_ftq_resp_bits_s2_hasRedirect_3),
    .io_fromBpu_resp_bits_s2_ftq_idx_flag                           (bpu_bpu_to_ftq_resp_bits_s2_ftq_idx_flag),
    .io_fromBpu_resp_bits_s2_ftq_idx_value                          (bpu_bpu_to_ftq_resp_bits_s2_ftq_idx_value),
    .io_fromBpu_resp_bits_s2_full_pred_0_predCycle                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0            (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1            (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0              (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1              (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_targets_0                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_targets_1                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_offsets_0                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_offsets_1                  (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr            (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr             (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing              (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s2_full_pred_3_hit                        (bpu_bpu_to_ftq_resp_bits_s2_full_pred_3_hit),
    .io_fromBpu_resp_bits_s3_pc_0                                   (bpu_bpu_to_ftq_resp_bits_s3_pc_0),
    .io_fromBpu_resp_bits_s3_pc_3                                   (bpu_bpu_to_ftq_resp_bits_s3_pc_3),
    .io_fromBpu_resp_bits_s3_valid_3                                (bpu_bpu_to_ftq_resp_bits_s3_valid_3),
    .io_fromBpu_resp_bits_s3_hasRedirect_3                          (bpu_bpu_to_ftq_resp_bits_s3_hasRedirect_3),
    .io_fromBpu_resp_bits_s3_ftq_idx_flag                           (bpu_bpu_to_ftq_resp_bits_s3_ftq_idx_flag),
    .io_fromBpu_resp_bits_s3_ftq_idx_value                          (bpu_bpu_to_ftq_resp_bits_s3_ftq_idx_value),
    .io_fromBpu_resp_bits_s3_full_pred_0_predCycle                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0            (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1            (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0              (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1              (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_targets_0                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_targets_1                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_offsets_0                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_offsets_1                  (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr            (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr             (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing              (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s3_full_pred_3_hit                        (bpu_bpu_to_ftq_resp_bits_s3_full_pred_3_hit),
    .io_fromBpu_resp_bits_last_stage_meta                           (bpu_bpu_to_ftq_resp_bits_last_stage_meta),
    .io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag         (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value        (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_ssp                  (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp),
    .io_fromBpu_resp_bits_last_stage_spec_info_sctr                 (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag            (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value           (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag            (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value           (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag             (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_NOS_value            (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_topAddr              (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr),
    .io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0        (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0),
    .io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1        (bpu_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isCall               (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isRet                (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr               (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_valid                (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset     (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing    (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid      (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower      (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat    (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset      (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing     (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid       (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower       (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat     (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr              (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_carry                (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0        (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1        (bpu_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1),
    .io_fromBpu_resp_bits_topdown_info_reasons_1                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_1),
    .io_fromBpu_resp_bits_topdown_info_reasons_2                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_2),
    .io_fromBpu_resp_bits_topdown_info_reasons_3                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_3),
    .io_fromBpu_resp_bits_topdown_info_reasons_4                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_4),
    .io_fromBpu_resp_bits_topdown_info_reasons_5                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_5),
    .io_fromBpu_resp_bits_topdown_info_reasons_6                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_6),
    .io_fromBpu_resp_bits_topdown_info_reasons_7                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_7),
    .io_fromBpu_resp_bits_topdown_info_reasons_8                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_8),
    .io_fromBpu_resp_bits_topdown_info_reasons_9                    (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_9),
    .io_fromBpu_resp_bits_topdown_info_reasons_12                   (bpu_bpu_to_ftq_resp_bits_topdown_info_reasons_12),
    // ---- ← ifu：FTQ 发取指请求给 IFU；IFU 回写预译码 / 误预测检查结果；MMIO 指令提交读 FTQ ----
    .io_fromIfu_pdWb_valid                                          (ifu_ftqInter_toFtq_pdWb_valid),
    .io_fromIfu_pdWb_bits_pc_0                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_0),
    .io_fromIfu_pdWb_bits_pc_1                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_1),
    .io_fromIfu_pdWb_bits_pc_2                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_2),
    .io_fromIfu_pdWb_bits_pc_3                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_3),
    .io_fromIfu_pdWb_bits_pc_4                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_4),
    .io_fromIfu_pdWb_bits_pc_5                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_5),
    .io_fromIfu_pdWb_bits_pc_6                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_6),
    .io_fromIfu_pdWb_bits_pc_7                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_7),
    .io_fromIfu_pdWb_bits_pc_8                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_8),
    .io_fromIfu_pdWb_bits_pc_9                                      (ifu_ftqInter_toFtq_pdWb_bits_pc_9),
    .io_fromIfu_pdWb_bits_pc_10                                     (ifu_ftqInter_toFtq_pdWb_bits_pc_10),
    .io_fromIfu_pdWb_bits_pc_11                                     (ifu_ftqInter_toFtq_pdWb_bits_pc_11),
    .io_fromIfu_pdWb_bits_pc_12                                     (ifu_ftqInter_toFtq_pdWb_bits_pc_12),
    .io_fromIfu_pdWb_bits_pc_13                                     (ifu_ftqInter_toFtq_pdWb_bits_pc_13),
    .io_fromIfu_pdWb_bits_pc_14                                     (ifu_ftqInter_toFtq_pdWb_bits_pc_14),
    .io_fromIfu_pdWb_bits_pc_15                                     (ifu_ftqInter_toFtq_pdWb_bits_pc_15),
    .io_fromIfu_pdWb_bits_pd_0_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_0_valid),
    .io_fromIfu_pdWb_bits_pd_0_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_0_isRVC),
    .io_fromIfu_pdWb_bits_pd_0_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_0_brType),
    .io_fromIfu_pdWb_bits_pd_0_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_0_isCall),
    .io_fromIfu_pdWb_bits_pd_0_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_0_isRet),
    .io_fromIfu_pdWb_bits_pd_1_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_1_valid),
    .io_fromIfu_pdWb_bits_pd_1_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_1_isRVC),
    .io_fromIfu_pdWb_bits_pd_1_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_1_brType),
    .io_fromIfu_pdWb_bits_pd_1_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_1_isCall),
    .io_fromIfu_pdWb_bits_pd_1_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_1_isRet),
    .io_fromIfu_pdWb_bits_pd_2_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_2_valid),
    .io_fromIfu_pdWb_bits_pd_2_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_2_isRVC),
    .io_fromIfu_pdWb_bits_pd_2_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_2_brType),
    .io_fromIfu_pdWb_bits_pd_2_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_2_isCall),
    .io_fromIfu_pdWb_bits_pd_2_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_2_isRet),
    .io_fromIfu_pdWb_bits_pd_3_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_3_valid),
    .io_fromIfu_pdWb_bits_pd_3_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_3_isRVC),
    .io_fromIfu_pdWb_bits_pd_3_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_3_brType),
    .io_fromIfu_pdWb_bits_pd_3_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_3_isCall),
    .io_fromIfu_pdWb_bits_pd_3_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_3_isRet),
    .io_fromIfu_pdWb_bits_pd_4_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_4_valid),
    .io_fromIfu_pdWb_bits_pd_4_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_4_isRVC),
    .io_fromIfu_pdWb_bits_pd_4_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_4_brType),
    .io_fromIfu_pdWb_bits_pd_4_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_4_isCall),
    .io_fromIfu_pdWb_bits_pd_4_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_4_isRet),
    .io_fromIfu_pdWb_bits_pd_5_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_5_valid),
    .io_fromIfu_pdWb_bits_pd_5_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_5_isRVC),
    .io_fromIfu_pdWb_bits_pd_5_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_5_brType),
    .io_fromIfu_pdWb_bits_pd_5_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_5_isCall),
    .io_fromIfu_pdWb_bits_pd_5_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_5_isRet),
    .io_fromIfu_pdWb_bits_pd_6_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_6_valid),
    .io_fromIfu_pdWb_bits_pd_6_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_6_isRVC),
    .io_fromIfu_pdWb_bits_pd_6_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_6_brType),
    .io_fromIfu_pdWb_bits_pd_6_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_6_isCall),
    .io_fromIfu_pdWb_bits_pd_6_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_6_isRet),
    .io_fromIfu_pdWb_bits_pd_7_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_7_valid),
    .io_fromIfu_pdWb_bits_pd_7_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_7_isRVC),
    .io_fromIfu_pdWb_bits_pd_7_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_7_brType),
    .io_fromIfu_pdWb_bits_pd_7_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_7_isCall),
    .io_fromIfu_pdWb_bits_pd_7_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_7_isRet),
    .io_fromIfu_pdWb_bits_pd_8_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_8_valid),
    .io_fromIfu_pdWb_bits_pd_8_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_8_isRVC),
    .io_fromIfu_pdWb_bits_pd_8_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_8_brType),
    .io_fromIfu_pdWb_bits_pd_8_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_8_isCall),
    .io_fromIfu_pdWb_bits_pd_8_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_8_isRet),
    .io_fromIfu_pdWb_bits_pd_9_valid                                (ifu_ftqInter_toFtq_pdWb_bits_pd_9_valid),
    .io_fromIfu_pdWb_bits_pd_9_isRVC                                (ifu_ftqInter_toFtq_pdWb_bits_pd_9_isRVC),
    .io_fromIfu_pdWb_bits_pd_9_brType                               (ifu_ftqInter_toFtq_pdWb_bits_pd_9_brType),
    .io_fromIfu_pdWb_bits_pd_9_isCall                               (ifu_ftqInter_toFtq_pdWb_bits_pd_9_isCall),
    .io_fromIfu_pdWb_bits_pd_9_isRet                                (ifu_ftqInter_toFtq_pdWb_bits_pd_9_isRet),
    .io_fromIfu_pdWb_bits_pd_10_valid                               (ifu_ftqInter_toFtq_pdWb_bits_pd_10_valid),
    .io_fromIfu_pdWb_bits_pd_10_isRVC                               (ifu_ftqInter_toFtq_pdWb_bits_pd_10_isRVC),
    .io_fromIfu_pdWb_bits_pd_10_brType                              (ifu_ftqInter_toFtq_pdWb_bits_pd_10_brType),
    .io_fromIfu_pdWb_bits_pd_10_isCall                              (ifu_ftqInter_toFtq_pdWb_bits_pd_10_isCall),
    .io_fromIfu_pdWb_bits_pd_10_isRet                               (ifu_ftqInter_toFtq_pdWb_bits_pd_10_isRet),
    .io_fromIfu_pdWb_bits_pd_11_valid                               (ifu_ftqInter_toFtq_pdWb_bits_pd_11_valid),
    .io_fromIfu_pdWb_bits_pd_11_isRVC                               (ifu_ftqInter_toFtq_pdWb_bits_pd_11_isRVC),
    .io_fromIfu_pdWb_bits_pd_11_brType                              (ifu_ftqInter_toFtq_pdWb_bits_pd_11_brType),
    .io_fromIfu_pdWb_bits_pd_11_isCall                              (ifu_ftqInter_toFtq_pdWb_bits_pd_11_isCall),
    .io_fromIfu_pdWb_bits_pd_11_isRet                               (ifu_ftqInter_toFtq_pdWb_bits_pd_11_isRet),
    .io_fromIfu_pdWb_bits_pd_12_valid                               (ifu_ftqInter_toFtq_pdWb_bits_pd_12_valid),
    .io_fromIfu_pdWb_bits_pd_12_isRVC                               (ifu_ftqInter_toFtq_pdWb_bits_pd_12_isRVC),
    .io_fromIfu_pdWb_bits_pd_12_brType                              (ifu_ftqInter_toFtq_pdWb_bits_pd_12_brType),
    .io_fromIfu_pdWb_bits_pd_12_isCall                              (ifu_ftqInter_toFtq_pdWb_bits_pd_12_isCall),
    .io_fromIfu_pdWb_bits_pd_12_isRet                               (ifu_ftqInter_toFtq_pdWb_bits_pd_12_isRet),
    .io_fromIfu_pdWb_bits_pd_13_valid                               (ifu_ftqInter_toFtq_pdWb_bits_pd_13_valid),
    .io_fromIfu_pdWb_bits_pd_13_isRVC                               (ifu_ftqInter_toFtq_pdWb_bits_pd_13_isRVC),
    .io_fromIfu_pdWb_bits_pd_13_brType                              (ifu_ftqInter_toFtq_pdWb_bits_pd_13_brType),
    .io_fromIfu_pdWb_bits_pd_13_isCall                              (ifu_ftqInter_toFtq_pdWb_bits_pd_13_isCall),
    .io_fromIfu_pdWb_bits_pd_13_isRet                               (ifu_ftqInter_toFtq_pdWb_bits_pd_13_isRet),
    .io_fromIfu_pdWb_bits_pd_14_valid                               (ifu_ftqInter_toFtq_pdWb_bits_pd_14_valid),
    .io_fromIfu_pdWb_bits_pd_14_isRVC                               (ifu_ftqInter_toFtq_pdWb_bits_pd_14_isRVC),
    .io_fromIfu_pdWb_bits_pd_14_brType                              (ifu_ftqInter_toFtq_pdWb_bits_pd_14_brType),
    .io_fromIfu_pdWb_bits_pd_14_isCall                              (ifu_ftqInter_toFtq_pdWb_bits_pd_14_isCall),
    .io_fromIfu_pdWb_bits_pd_14_isRet                               (ifu_ftqInter_toFtq_pdWb_bits_pd_14_isRet),
    .io_fromIfu_pdWb_bits_pd_15_valid                               (ifu_ftqInter_toFtq_pdWb_bits_pd_15_valid),
    .io_fromIfu_pdWb_bits_pd_15_isRVC                               (ifu_ftqInter_toFtq_pdWb_bits_pd_15_isRVC),
    .io_fromIfu_pdWb_bits_pd_15_brType                              (ifu_ftqInter_toFtq_pdWb_bits_pd_15_brType),
    .io_fromIfu_pdWb_bits_pd_15_isCall                              (ifu_ftqInter_toFtq_pdWb_bits_pd_15_isCall),
    .io_fromIfu_pdWb_bits_pd_15_isRet                               (ifu_ftqInter_toFtq_pdWb_bits_pd_15_isRet),
    .io_fromIfu_pdWb_bits_ftqIdx_flag                               (ifu_ftqInter_toFtq_pdWb_bits_ftqIdx_flag),
    .io_fromIfu_pdWb_bits_ftqIdx_value                              (ifu_ftqInter_toFtq_pdWb_bits_ftqIdx_value),
    .io_fromIfu_pdWb_bits_misOffset_valid                           (ifu_ftqInter_toFtq_pdWb_bits_misOffset_valid),
    .io_fromIfu_pdWb_bits_misOffset_bits                            (ifu_ftqInter_toFtq_pdWb_bits_misOffset_bits),
    .io_fromIfu_pdWb_bits_cfiOffset_valid                           (ifu_ftqInter_toFtq_pdWb_bits_cfiOffset_valid),
    .io_fromIfu_pdWb_bits_target                                    (ifu_ftqInter_toFtq_pdWb_bits_target),
    .io_fromIfu_pdWb_bits_jalTarget                                 (ifu_ftqInter_toFtq_pdWb_bits_jalTarget),
    .io_fromIfu_pdWb_bits_instrRange_0                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_0),
    .io_fromIfu_pdWb_bits_instrRange_1                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_1),
    .io_fromIfu_pdWb_bits_instrRange_2                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_2),
    .io_fromIfu_pdWb_bits_instrRange_3                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_3),
    .io_fromIfu_pdWb_bits_instrRange_4                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_4),
    .io_fromIfu_pdWb_bits_instrRange_5                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_5),
    .io_fromIfu_pdWb_bits_instrRange_6                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_6),
    .io_fromIfu_pdWb_bits_instrRange_7                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_7),
    .io_fromIfu_pdWb_bits_instrRange_8                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_8),
    .io_fromIfu_pdWb_bits_instrRange_9                              (ifu_ftqInter_toFtq_pdWb_bits_instrRange_9),
    .io_fromIfu_pdWb_bits_instrRange_10                             (ifu_ftqInter_toFtq_pdWb_bits_instrRange_10),
    .io_fromIfu_pdWb_bits_instrRange_11                             (ifu_ftqInter_toFtq_pdWb_bits_instrRange_11),
    .io_fromIfu_pdWb_bits_instrRange_12                             (ifu_ftqInter_toFtq_pdWb_bits_instrRange_12),
    .io_fromIfu_pdWb_bits_instrRange_13                             (ifu_ftqInter_toFtq_pdWb_bits_instrRange_13),
    .io_fromIfu_pdWb_bits_instrRange_14                             (ifu_ftqInter_toFtq_pdWb_bits_instrRange_14),
    .io_fromIfu_pdWb_bits_instrRange_15                             (ifu_ftqInter_toFtq_pdWb_bits_instrRange_15),
    .io_mmioCommitRead_valid                                        (ifu_mmioCommitRead_valid),
    .io_mmioCommitRead_mmioFtqPtr_flag                              (ifu_mmioCommitRead_mmioFtqPtr_flag),
    .io_mmioCommitRead_mmioFtqPtr_value                             (ifu_mmioCommitRead_mmioFtqPtr_value),
    // ---- 顶层 io_backend_toFtq* —— 后端提交 / 重定向回送 FTQ ----
    .io_fromBackend_rob_commits_0_valid                             (io_backend_toFtq_rob_commits_0_valid),
    .io_fromBackend_rob_commits_0_bits_commitType                   (io_backend_toFtq_rob_commits_0_bits_commitType),
    .io_fromBackend_rob_commits_0_bits_ftqIdx_flag                  (io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_0_bits_ftqIdx_value                 (io_backend_toFtq_rob_commits_0_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_0_bits_ftqOffset                    (io_backend_toFtq_rob_commits_0_bits_ftqOffset),
    .io_fromBackend_rob_commits_1_valid                             (io_backend_toFtq_rob_commits_1_valid),
    .io_fromBackend_rob_commits_1_bits_commitType                   (io_backend_toFtq_rob_commits_1_bits_commitType),
    .io_fromBackend_rob_commits_1_bits_ftqIdx_flag                  (io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_1_bits_ftqIdx_value                 (io_backend_toFtq_rob_commits_1_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_1_bits_ftqOffset                    (io_backend_toFtq_rob_commits_1_bits_ftqOffset),
    .io_fromBackend_rob_commits_2_valid                             (io_backend_toFtq_rob_commits_2_valid),
    .io_fromBackend_rob_commits_2_bits_commitType                   (io_backend_toFtq_rob_commits_2_bits_commitType),
    .io_fromBackend_rob_commits_2_bits_ftqIdx_flag                  (io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_2_bits_ftqIdx_value                 (io_backend_toFtq_rob_commits_2_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_2_bits_ftqOffset                    (io_backend_toFtq_rob_commits_2_bits_ftqOffset),
    .io_fromBackend_rob_commits_3_valid                             (io_backend_toFtq_rob_commits_3_valid),
    .io_fromBackend_rob_commits_3_bits_commitType                   (io_backend_toFtq_rob_commits_3_bits_commitType),
    .io_fromBackend_rob_commits_3_bits_ftqIdx_flag                  (io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_3_bits_ftqIdx_value                 (io_backend_toFtq_rob_commits_3_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_3_bits_ftqOffset                    (io_backend_toFtq_rob_commits_3_bits_ftqOffset),
    .io_fromBackend_rob_commits_4_valid                             (io_backend_toFtq_rob_commits_4_valid),
    .io_fromBackend_rob_commits_4_bits_commitType                   (io_backend_toFtq_rob_commits_4_bits_commitType),
    .io_fromBackend_rob_commits_4_bits_ftqIdx_flag                  (io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_4_bits_ftqIdx_value                 (io_backend_toFtq_rob_commits_4_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_4_bits_ftqOffset                    (io_backend_toFtq_rob_commits_4_bits_ftqOffset),
    .io_fromBackend_rob_commits_5_valid                             (io_backend_toFtq_rob_commits_5_valid),
    .io_fromBackend_rob_commits_5_bits_commitType                   (io_backend_toFtq_rob_commits_5_bits_commitType),
    .io_fromBackend_rob_commits_5_bits_ftqIdx_flag                  (io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_5_bits_ftqIdx_value                 (io_backend_toFtq_rob_commits_5_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_5_bits_ftqOffset                    (io_backend_toFtq_rob_commits_5_bits_ftqOffset),
    .io_fromBackend_rob_commits_6_valid                             (io_backend_toFtq_rob_commits_6_valid),
    .io_fromBackend_rob_commits_6_bits_commitType                   (io_backend_toFtq_rob_commits_6_bits_commitType),
    .io_fromBackend_rob_commits_6_bits_ftqIdx_flag                  (io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_6_bits_ftqIdx_value                 (io_backend_toFtq_rob_commits_6_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_6_bits_ftqOffset                    (io_backend_toFtq_rob_commits_6_bits_ftqOffset),
    .io_fromBackend_rob_commits_7_valid                             (io_backend_toFtq_rob_commits_7_valid),
    .io_fromBackend_rob_commits_7_bits_commitType                   (io_backend_toFtq_rob_commits_7_bits_commitType),
    .io_fromBackend_rob_commits_7_bits_ftqIdx_flag                  (io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_7_bits_ftqIdx_value                 (io_backend_toFtq_rob_commits_7_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_7_bits_ftqOffset                    (io_backend_toFtq_rob_commits_7_bits_ftqOffset),
    .io_fromBackend_redirect_valid                                  (io_backend_toFtq_redirect_valid),
    .io_fromBackend_redirect_bits_ftqIdx_flag                       (io_backend_toFtq_redirect_bits_ftqIdx_flag),
    .io_fromBackend_redirect_bits_ftqIdx_value                      (io_backend_toFtq_redirect_bits_ftqIdx_value),
    .io_fromBackend_redirect_bits_ftqOffset                         (io_backend_toFtq_redirect_bits_ftqOffset),
    .io_fromBackend_redirect_bits_level                             (io_backend_toFtq_redirect_bits_level),
    .io_fromBackend_redirect_bits_cfiUpdate_pc                      (io_backend_toFtq_redirect_bits_cfiUpdate_pc),
    .io_fromBackend_redirect_bits_cfiUpdate_target                  (io_backend_toFtq_redirect_bits_cfiUpdate_target),
    .io_fromBackend_redirect_bits_cfiUpdate_taken                   (io_backend_toFtq_redirect_bits_cfiUpdate_taken),
    .io_fromBackend_redirect_bits_cfiUpdate_isMisPred               (io_backend_toFtq_redirect_bits_cfiUpdate_isMisPred),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIGPF             (io_backend_toFtq_redirect_bits_cfiUpdate_backendIGPF),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIPF              (io_backend_toFtq_redirect_bits_cfiUpdate_backendIPF),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIAF              (io_backend_toFtq_redirect_bits_cfiUpdate_backendIAF),
    .io_fromBackend_redirect_bits_satpFlush                         (io_backend_toFtq_redirect_bits_satpFlush),
    .io_fromBackend_redirect_bits_debugIsCtrl                       (io_backend_toFtq_redirect_bits_debugIsCtrl),
    .io_fromBackend_redirect_bits_debugIsMemVio                     (io_backend_toFtq_redirect_bits_debugIsMemVio),
    .io_fromBackend_ftqIdxAhead_0_valid                             (io_backend_toFtq_ftqIdxAhead_0_valid),
    .io_fromBackend_ftqIdxAhead_0_bits_value                        (io_backend_toFtq_ftqIdxAhead_0_bits_value),
    .io_fromBackend_ftqIdxSelOH_bits                                (io_backend_toFtq_ftqIdxSelOH_bits),
    // ---- ← u_core：FTQ 的取指请求握手（IFU 与 ICache 都 ready）；PC 存储写口供自检镜像 ----
    .io_toIfu_req_ready                                             (fetch_req_ready),
    // ---- → ifu（FTQ 发取指请求给 IFU；IFU 回写预译码 / 误预测检查结果；MMIO 指令提交读 FTQ） ----
    .io_toIfu_req_valid                                             (ftq_toIfu_req_valid),
    .io_toIfu_req_bits_startAddr                                    (ftq_toIfu_req_bits_startAddr),
    .io_toIfu_req_bits_nextlineStart                                (ftq_toIfu_req_bits_nextlineStart),
    .io_toIfu_req_bits_nextStartAddr                                (ftq_toIfu_req_bits_nextStartAddr),
    .io_toIfu_req_bits_ftqIdx_flag                                  (ftq_toIfu_req_bits_ftqIdx_flag),
    .io_toIfu_req_bits_ftqIdx_value                                 (ftq_toIfu_req_bits_ftqIdx_value),
    .io_toIfu_req_bits_ftqOffset_valid                              (ftq_toIfu_req_bits_ftqOffset_valid),
    .io_toIfu_req_bits_ftqOffset_bits                               (ftq_toIfu_req_bits_ftqOffset_bits),
    .io_toIfu_req_bits_topdown_info_reasons_0                       (ftq_toIfu_req_bits_topdown_info_reasons_0),
    .io_toIfu_req_bits_topdown_info_reasons_1                       (ftq_toIfu_req_bits_topdown_info_reasons_1),
    .io_toIfu_req_bits_topdown_info_reasons_2                       (ftq_toIfu_req_bits_topdown_info_reasons_2),
    .io_toIfu_req_bits_topdown_info_reasons_3                       (ftq_toIfu_req_bits_topdown_info_reasons_3),
    .io_toIfu_req_bits_topdown_info_reasons_4                       (ftq_toIfu_req_bits_topdown_info_reasons_4),
    .io_toIfu_req_bits_topdown_info_reasons_5                       (ftq_toIfu_req_bits_topdown_info_reasons_5),
    .io_toIfu_req_bits_topdown_info_reasons_6                       (ftq_toIfu_req_bits_topdown_info_reasons_6),
    .io_toIfu_req_bits_topdown_info_reasons_7                       (ftq_toIfu_req_bits_topdown_info_reasons_7),
    .io_toIfu_req_bits_topdown_info_reasons_8                       (ftq_toIfu_req_bits_topdown_info_reasons_8),
    .io_toIfu_req_bits_topdown_info_reasons_9                       (ftq_toIfu_req_bits_topdown_info_reasons_9),
    .io_toIfu_req_bits_topdown_info_reasons_10                      (ftq_toIfu_req_bits_topdown_info_reasons_10),
    .io_toIfu_req_bits_topdown_info_reasons_11                      (ftq_toIfu_req_bits_topdown_info_reasons_11),
    .io_toIfu_req_bits_topdown_info_reasons_12                      (ftq_toIfu_req_bits_topdown_info_reasons_12),
    .io_toIfu_req_bits_topdown_info_reasons_13                      (ftq_toIfu_req_bits_topdown_info_reasons_13),
    .io_toIfu_req_bits_topdown_info_reasons_14                      (ftq_toIfu_req_bits_topdown_info_reasons_14),
    .io_toIfu_req_bits_topdown_info_reasons_15                      (ftq_toIfu_req_bits_topdown_info_reasons_15),
    .io_toIfu_req_bits_topdown_info_reasons_16                      (ftq_toIfu_req_bits_topdown_info_reasons_16),
    .io_toIfu_req_bits_topdown_info_reasons_17                      (ftq_toIfu_req_bits_topdown_info_reasons_17),
    .io_toIfu_req_bits_topdown_info_reasons_18                      (ftq_toIfu_req_bits_topdown_info_reasons_18),
    .io_toIfu_req_bits_topdown_info_reasons_19                      (ftq_toIfu_req_bits_topdown_info_reasons_19),
    .io_toIfu_req_bits_topdown_info_reasons_20                      (ftq_toIfu_req_bits_topdown_info_reasons_20),
    .io_toIfu_req_bits_topdown_info_reasons_21                      (ftq_toIfu_req_bits_topdown_info_reasons_21),
    .io_toIfu_req_bits_topdown_info_reasons_22                      (ftq_toIfu_req_bits_topdown_info_reasons_22),
    .io_toIfu_req_bits_topdown_info_reasons_23                      (ftq_toIfu_req_bits_topdown_info_reasons_23),
    .io_toIfu_req_bits_topdown_info_reasons_24                      (ftq_toIfu_req_bits_topdown_info_reasons_24),
    .io_toIfu_req_bits_topdown_info_reasons_25                      (ftq_toIfu_req_bits_topdown_info_reasons_25),
    .io_toIfu_req_bits_topdown_info_reasons_26                      (ftq_toIfu_req_bits_topdown_info_reasons_26),
    .io_toIfu_req_bits_topdown_info_reasons_27                      (ftq_toIfu_req_bits_topdown_info_reasons_27),
    .io_toIfu_req_bits_topdown_info_reasons_28                      (ftq_toIfu_req_bits_topdown_info_reasons_28),
    .io_toIfu_req_bits_topdown_info_reasons_29                      (ftq_toIfu_req_bits_topdown_info_reasons_29),
    .io_toIfu_req_bits_topdown_info_reasons_30                      (ftq_toIfu_req_bits_topdown_info_reasons_30),
    .io_toIfu_req_bits_topdown_info_reasons_31                      (ftq_toIfu_req_bits_topdown_info_reasons_31),
    .io_toIfu_req_bits_topdown_info_reasons_32                      (ftq_toIfu_req_bits_topdown_info_reasons_32),
    .io_toIfu_req_bits_topdown_info_reasons_33                      (ftq_toIfu_req_bits_topdown_info_reasons_33),
    .io_toIfu_req_bits_topdown_info_reasons_34                      (ftq_toIfu_req_bits_topdown_info_reasons_34),
    .io_toIfu_req_bits_topdown_info_reasons_35                      (ftq_toIfu_req_bits_topdown_info_reasons_35),
    .io_toIfu_req_bits_topdown_info_reasons_36                      (ftq_toIfu_req_bits_topdown_info_reasons_36),
    .io_toIfu_req_bits_topdown_info_reasons_37                      (ftq_toIfu_req_bits_topdown_info_reasons_37),
    .io_toIfu_redirect_valid                                        (ftq_toIfu_redirect_valid),
    .io_toIfu_redirect_bits_ftqIdx_flag                             (ftq_toIfu_redirect_bits_ftqIdx_flag),
    .io_toIfu_redirect_bits_ftqIdx_value                            (ftq_toIfu_redirect_bits_ftqIdx_value),
    .io_toIfu_redirect_bits_ftqOffset                               (ftq_toIfu_redirect_bits_ftqOffset),
    .io_toIfu_redirect_bits_level                                   (ftq_toIfu_redirect_bits_level),
    .io_toIfu_topdown_redirect_valid                                (ftq_toIfu_topdown_redirect_valid),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet              (ftq_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit                (ftq_toIfu_topdown_redirect_bits_cfiUpdate_br_hit),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit                (ftq_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit                (ftq_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit),
    .io_toIfu_topdown_redirect_bits_debugIsCtrl                     (ftq_toIfu_topdown_redirect_bits_debugIsCtrl),
    .io_toIfu_topdown_redirect_bits_debugIsMemVio                   (ftq_toIfu_topdown_redirect_bits_debugIsMemVio),
    .io_toIfu_flushFromBpu_s2_valid                                 (ftq_toIfu_flushFromBpu_s2_valid),
    .io_toIfu_flushFromBpu_s2_bits_flag                             (ftq_toIfu_flushFromBpu_s2_bits_flag),
    .io_toIfu_flushFromBpu_s2_bits_value                            (ftq_toIfu_flushFromBpu_s2_bits_value),
    .io_toIfu_flushFromBpu_s3_valid                                 (ftq_toIfu_flushFromBpu_s3_valid),
    .io_toIfu_flushFromBpu_s3_bits_flag                             (ftq_toIfu_flushFromBpu_s3_bits_flag),
    .io_toIfu_flushFromBpu_s3_bits_value                            (ftq_toIfu_flushFromBpu_s3_bits_value),
    .io_mmioCommitRead_mmioLastCommit                               (ftq_mmioCommitRead_mmioLastCommit),
    // ---- → icache（FTQ 发取指请求 / 预取请求给 ICache，以及 ICache 冲刷） ----
    .io_toICache_req_valid                                          (ftq_toICache_req_valid),
    .io_toICache_req_bits_pcMemRead_0_startAddr                     (ftq_toICache_req_bits_pcMemRead_0_startAddr),
    .io_toICache_req_bits_pcMemRead_0_nextlineStart                 (ftq_toICache_req_bits_pcMemRead_0_nextlineStart),
    .io_toICache_req_bits_pcMemRead_1_startAddr                     (ftq_toICache_req_bits_pcMemRead_1_startAddr),
    .io_toICache_req_bits_pcMemRead_1_nextlineStart                 (ftq_toICache_req_bits_pcMemRead_1_nextlineStart),
    .io_toICache_req_bits_pcMemRead_2_startAddr                     (ftq_toICache_req_bits_pcMemRead_2_startAddr),
    .io_toICache_req_bits_pcMemRead_2_nextlineStart                 (ftq_toICache_req_bits_pcMemRead_2_nextlineStart),
    .io_toICache_req_bits_pcMemRead_3_startAddr                     (ftq_toICache_req_bits_pcMemRead_3_startAddr),
    .io_toICache_req_bits_pcMemRead_3_nextlineStart                 (ftq_toICache_req_bits_pcMemRead_3_nextlineStart),
    .io_toICache_req_bits_pcMemRead_4_startAddr                     (ftq_toICache_req_bits_pcMemRead_4_startAddr),
    .io_toICache_req_bits_pcMemRead_4_nextlineStart                 (ftq_toICache_req_bits_pcMemRead_4_nextlineStart),
    .io_toICache_req_bits_readValid_0                               (ftq_toICache_req_bits_readValid_0),
    .io_toICache_req_bits_readValid_1                               (ftq_toICache_req_bits_readValid_1),
    .io_toICache_req_bits_readValid_2                               (ftq_toICache_req_bits_readValid_2),
    .io_toICache_req_bits_readValid_3                               (ftq_toICache_req_bits_readValid_3),
    .io_toICache_req_bits_readValid_4                               (ftq_toICache_req_bits_readValid_4),
    .io_toICache_req_bits_backendException                          (ftq_toICache_req_bits_backendException),
    .io_toICache_req_bits_hasSatpFlush                              (ftq_toICache_req_bits_hasSatpFlush),
    .io_toPrefetch_req_valid                                        (ftq_toPrefetch_req_valid),
    .io_toPrefetch_req_bits_startAddr                               (ftq_toPrefetch_req_bits_startAddr),
    .io_toPrefetch_req_bits_nextlineStart                           (ftq_toPrefetch_req_bits_nextlineStart),
    .io_toPrefetch_req_bits_ftqIdx_flag                             (ftq_toPrefetch_req_bits_ftqIdx_flag),
    .io_toPrefetch_req_bits_ftqIdx_value                            (ftq_toPrefetch_req_bits_ftqIdx_value),
    .io_toPrefetch_flushFromBpu_s2_valid                            (ftq_toPrefetch_flushFromBpu_s2_valid),
    .io_toPrefetch_flushFromBpu_s2_bits_flag                        (ftq_toPrefetch_flushFromBpu_s2_bits_flag),
    .io_toPrefetch_flushFromBpu_s2_bits_value                       (ftq_toPrefetch_flushFromBpu_s2_bits_value),
    .io_toPrefetch_flushFromBpu_s3_valid                            (ftq_toPrefetch_flushFromBpu_s3_valid),
    .io_toPrefetch_flushFromBpu_s3_bits_flag                        (ftq_toPrefetch_flushFromBpu_s3_bits_flag),
    .io_toPrefetch_flushFromBpu_s3_bits_value                       (ftq_toPrefetch_flushFromBpu_s3_bits_value),
    .io_toPrefetch_backendException                                 (ftq_toPrefetch_backendException),
    .io_icacheFlush                                                 (ftq_icacheFlush),
    // ---- → 顶层输出；core（FTQ 的取指请求握手（IFU 与 ICache 都 ready）；PC 存储写口供自检镜像） ----
    .io_toBackend_pc_mem_wen                                        (ftq_toBackend_pc_mem_wen),
    .io_toBackend_pc_mem_waddr                                      (ftq_toBackend_pc_mem_waddr),
    .io_toBackend_pc_mem_wdata_startAddr                            (ftq_toBackend_pc_mem_wdata_startAddr),
    .io_toBackend_newest_entry_target                               (ftq_toBackend_newest_entry_target),
    .io_toBackend_newest_entry_ptr_value                            (ftq_toBackend_newest_entry_ptr_value),
    // ---- 顶层 io_backend_fromFtq* —— FTQ 写给后端的 PC 存储 ----
    .io_toBackend_newest_entry_en                                   (io_backend_fromFtq_newest_entry_en),
    // ---- ← icache：FTQ 发取指请求 / 预取请求给 ICache，以及 ICache 冲刷 ----
    .io_toPrefetch_req_ready                                        (icache_ftqPrefetch_req_ready),
    // ---- → ibuffer（FTQ 统计的各类重定向气泡（TopDown 用）给 IBuffer） ----
    .io_ControlBTBMissBubble                                        (ftq_ControlBTBMissBubble),
    .io_TAGEMissBubble                                              (ftq_TAGEMissBubble),
    .io_SCMissBubble                                                (ftq_SCMissBubble),
    .io_ITTAGEMissBubble                                            (ftq_ITTAGEMissBubble),
    .io_RASMissBubble                                               (ftq_RASMissBubble),
    // ---- → perfHpm（FTQ 性能事件） ----
    .io_perf_0_value                                                (ftq_perf_0_value),
    .io_perf_1_value                                                (ftq_perf_1_value),
    .io_perf_2_value                                                (ftq_perf_2_value),
    .io_perf_3_value                                                (ftq_perf_3_value),
    .io_perf_4_value                                                (ftq_perf_4_value),
    .io_perf_5_value                                                (ftq_perf_5_value),
    .io_perf_6_value                                                (ftq_perf_6_value),
    .io_perf_7_value                                                (ftq_perf_7_value),
    .io_perf_8_value                                                (ftq_perf_8_value),
    .io_perf_9_value                                                (ftq_perf_9_value),
    .io_perf_10_value                                               (ftq_perf_10_value),
    .io_perf_11_value                                               (ftq_perf_11_value),
    .io_perf_12_value                                               (ftq_perf_12_value),
    .io_perf_13_value                                               (ftq_perf_13_value),
    .io_perf_14_value                                               (ftq_perf_14_value),
    .io_perf_15_value                                               (ftq_perf_15_value),
    .io_perf_16_value                                               (ftq_perf_16_value),
    .io_perf_17_value                                               (ftq_perf_17_value),
    .io_perf_18_value                                               (ftq_perf_18_value),
    .io_perf_19_value                                               (ftq_perf_19_value),
    .io_perf_20_value                                               (ftq_perf_20_value),
    .io_perf_21_value                                               (ftq_perf_21_value),
    .io_perf_22_value                                               (ftq_perf_22_value),
    .io_perf_23_value                                               (ftq_perf_23_value)
  );
  ICache inner_icache (
    // ---- 时钟 / 复位 ----
    .clock                                       (clock),
    .reset                                       (reset),
    // ---- 顶层 auto_inner_icache_ctrlUnitOpt_in* —— ICache 控制寄存器 TL-UL 从口（总线经 MemBlock.FrontendBridge.icachectrl 进来） ----
    .auto_ctrlUnitOpt_in_a_ready                 (auto_inner_icache_ctrlUnitOpt_in_a_ready),
    .auto_ctrlUnitOpt_in_a_valid                 (auto_inner_icache_ctrlUnitOpt_in_a_valid),
    .auto_ctrlUnitOpt_in_a_bits_opcode           (auto_inner_icache_ctrlUnitOpt_in_a_bits_opcode),
    .auto_ctrlUnitOpt_in_a_bits_size             (auto_inner_icache_ctrlUnitOpt_in_a_bits_size),
    .auto_ctrlUnitOpt_in_a_bits_source           (auto_inner_icache_ctrlUnitOpt_in_a_bits_source),
    .auto_ctrlUnitOpt_in_a_bits_address          (auto_inner_icache_ctrlUnitOpt_in_a_bits_address),
    .auto_ctrlUnitOpt_in_a_bits_mask             (auto_inner_icache_ctrlUnitOpt_in_a_bits_mask),
    .auto_ctrlUnitOpt_in_a_bits_data             (auto_inner_icache_ctrlUnitOpt_in_a_bits_data),
    .auto_ctrlUnitOpt_in_d_ready                 (auto_inner_icache_ctrlUnitOpt_in_d_ready),
    .auto_ctrlUnitOpt_in_d_valid                 (auto_inner_icache_ctrlUnitOpt_in_d_valid),
    .auto_ctrlUnitOpt_in_d_bits_opcode           (auto_inner_icache_ctrlUnitOpt_in_d_bits_opcode),
    .auto_ctrlUnitOpt_in_d_bits_size             (auto_inner_icache_ctrlUnitOpt_in_d_bits_size),
    .auto_ctrlUnitOpt_in_d_bits_source           (auto_inner_icache_ctrlUnitOpt_in_d_bits_source),
    .auto_ctrlUnitOpt_in_d_bits_data             (auto_inner_icache_ctrlUnitOpt_in_d_bits_data),
    // ---- 顶层 auto_inner_icache_client_out* —— ICache 取指 TL-UL 主口（经 MemBlock.FrontendBridge.icache 去 L2） ----
    .auto_client_out_a_ready                     (auto_inner_icache_client_out_a_ready),
    .auto_client_out_a_valid                     (auto_inner_icache_client_out_a_valid),
    .auto_client_out_a_bits_source               (auto_inner_icache_client_out_a_bits_source),
    .auto_client_out_a_bits_address              (auto_inner_icache_client_out_a_bits_address),
    .auto_client_out_d_valid                     (auto_inner_icache_client_out_d_valid),
    .auto_client_out_d_bits_opcode               (auto_inner_icache_client_out_d_bits_opcode),
    .auto_client_out_d_bits_size                 (auto_inner_icache_client_out_d_bits_size),
    .auto_client_out_d_bits_source               (auto_inner_icache_client_out_d_bits_source),
    .auto_client_out_d_bits_data                 (auto_inner_icache_client_out_d_bits_data),
    .auto_client_out_d_bits_corrupt              (auto_inner_icache_client_out_d_bits_corrupt),
    // ---- 顶层 io_hartId* —— 核号 ----
    .io_hartId                                   (io_hartId),
    // ---- → core（L1I 预取开关 / fence.i（各打一拍）；ECC 错误；wfi 安全） ----
    .io_fetch_req_ready                          (icache_fetch_req_ready),
    .io_error_valid                              (icache_error_valid),
    .io_error_bits_paddr                         (icache_error_bits_paddr),
    .io_error_bits_report_to_beu                 (icache_error_bits_report_to_beu),
    .io_wfi_wfiSafe                              (icache_wfi_wfiSafe),
    // ---- ← ftq：FTQ 发取指请求 / 预取请求给 ICache，以及 ICache 冲刷 ----
    .io_fetch_req_valid                          (ftq_toICache_req_valid),
    .io_fetch_req_bits_pcMemRead_0_startAddr     (ftq_toICache_req_bits_pcMemRead_0_startAddr),
    .io_fetch_req_bits_pcMemRead_0_nextlineStart (ftq_toICache_req_bits_pcMemRead_0_nextlineStart),
    .io_fetch_req_bits_pcMemRead_1_startAddr     (ftq_toICache_req_bits_pcMemRead_1_startAddr),
    .io_fetch_req_bits_pcMemRead_1_nextlineStart (ftq_toICache_req_bits_pcMemRead_1_nextlineStart),
    .io_fetch_req_bits_pcMemRead_2_startAddr     (ftq_toICache_req_bits_pcMemRead_2_startAddr),
    .io_fetch_req_bits_pcMemRead_2_nextlineStart (ftq_toICache_req_bits_pcMemRead_2_nextlineStart),
    .io_fetch_req_bits_pcMemRead_3_startAddr     (ftq_toICache_req_bits_pcMemRead_3_startAddr),
    .io_fetch_req_bits_pcMemRead_3_nextlineStart (ftq_toICache_req_bits_pcMemRead_3_nextlineStart),
    .io_fetch_req_bits_pcMemRead_4_startAddr     (ftq_toICache_req_bits_pcMemRead_4_startAddr),
    .io_fetch_req_bits_pcMemRead_4_nextlineStart (ftq_toICache_req_bits_pcMemRead_4_nextlineStart),
    .io_fetch_req_bits_readValid_0               (ftq_toICache_req_bits_readValid_0),
    .io_fetch_req_bits_readValid_1               (ftq_toICache_req_bits_readValid_1),
    .io_fetch_req_bits_readValid_2               (ftq_toICache_req_bits_readValid_2),
    .io_fetch_req_bits_readValid_3               (ftq_toICache_req_bits_readValid_3),
    .io_fetch_req_bits_readValid_4               (ftq_toICache_req_bits_readValid_4),
    .io_fetch_req_bits_backendException          (ftq_toICache_req_bits_backendException),
    .io_fetch_req_bits_hasSatpFlush              (ftq_toICache_req_bits_hasSatpFlush),
    .io_ftqPrefetch_req_valid                    (ftq_toPrefetch_req_valid),
    .io_ftqPrefetch_req_bits_startAddr           (ftq_toPrefetch_req_bits_startAddr),
    .io_ftqPrefetch_req_bits_nextlineStart       (ftq_toPrefetch_req_bits_nextlineStart),
    .io_ftqPrefetch_req_bits_ftqIdx_flag         (ftq_toPrefetch_req_bits_ftqIdx_flag),
    .io_ftqPrefetch_req_bits_ftqIdx_value        (ftq_toPrefetch_req_bits_ftqIdx_value),
    .io_ftqPrefetch_flushFromBpu_s2_valid        (ftq_toPrefetch_flushFromBpu_s2_valid),
    .io_ftqPrefetch_flushFromBpu_s2_bits_flag    (ftq_toPrefetch_flushFromBpu_s2_bits_flag),
    .io_ftqPrefetch_flushFromBpu_s2_bits_value   (ftq_toPrefetch_flushFromBpu_s2_bits_value),
    .io_ftqPrefetch_flushFromBpu_s3_valid        (ftq_toPrefetch_flushFromBpu_s3_valid),
    .io_ftqPrefetch_flushFromBpu_s3_bits_flag    (ftq_toPrefetch_flushFromBpu_s3_bits_flag),
    .io_ftqPrefetch_flushFromBpu_s3_bits_value   (ftq_toPrefetch_flushFromBpu_s3_bits_value),
    .io_ftqPrefetch_backendException             (ftq_toPrefetch_backendException),
    .io_flush                                    (ftq_icacheFlush),
    // ---- → ifu（ICache 回指令数据与 topdown 信息给 IFU；IFU 让 ICache 停（stop）；ICache 命中统计给 IFU） ----
    .io_fetch_resp_valid                         (icache_fetch_resp_valid),
    .io_fetch_resp_bits_doubleline               (icache_fetch_resp_bits_doubleline),
    .io_fetch_resp_bits_vaddr_0                  (icache_fetch_resp_bits_vaddr_0),
    .io_fetch_resp_bits_vaddr_1                  (icache_fetch_resp_bits_vaddr_1),
    .io_fetch_resp_bits_data                     (icache_fetch_resp_bits_data),
    .io_fetch_resp_bits_paddr_0                  (icache_fetch_resp_bits_paddr_0),
    .io_fetch_resp_bits_exception_0              (icache_fetch_resp_bits_exception_0),
    .io_fetch_resp_bits_exception_1              (icache_fetch_resp_bits_exception_1),
    .io_fetch_resp_bits_pmp_mmio_0               (icache_fetch_resp_bits_pmp_mmio_0),
    .io_fetch_resp_bits_pmp_mmio_1               (icache_fetch_resp_bits_pmp_mmio_1),
    .io_fetch_resp_bits_itlb_pbmt_0              (icache_fetch_resp_bits_itlb_pbmt_0),
    .io_fetch_resp_bits_itlb_pbmt_1              (icache_fetch_resp_bits_itlb_pbmt_1),
    .io_fetch_resp_bits_backendException         (icache_fetch_resp_bits_backendException),
    .io_fetch_resp_bits_hasSatpFlush             (icache_fetch_resp_bits_hasSatpFlush),
    .io_fetch_resp_bits_gpaddr                   (icache_fetch_resp_bits_gpaddr),
    .io_fetch_resp_bits_isForVSnonLeafPTE        (icache_fetch_resp_bits_isForVSnonLeafPTE),
    .io_fetch_topdownIcacheMiss                  (icache_fetch_topdownIcacheMiss),
    .io_fetch_topdownItlbMiss                    (icache_fetch_topdownItlbMiss),
    .io_toIFU                                    (icache_toIFU),
    .io_perfInfo_only_0_hit                      (icache_perfInfo_only_0_hit),
    .io_perfInfo_only_0_miss                     (icache_perfInfo_only_0_miss),
    .io_perfInfo_hit_0_hit_1                     (icache_perfInfo_hit_0_hit_1),
    .io_perfInfo_hit_0_miss_1                    (icache_perfInfo_hit_0_miss_1),
    .io_perfInfo_miss_0_hit_1                    (icache_perfInfo_miss_0_hit_1),
    .io_perfInfo_miss_0_miss_1                   (icache_perfInfo_miss_0_miss_1),
    .io_perfInfo_hit_0_except_1                  (icache_perfInfo_hit_0_except_1),
    .io_perfInfo_miss_0_except_1                 (icache_perfInfo_miss_0_except_1),
    .io_perfInfo_except_0                        (icache_perfInfo_except_0),
    .io_perfInfo_bank_hit_0                      (icache_perfInfo_bank_hit_0),
    .io_perfInfo_bank_hit_1                      (icache_perfInfo_bank_hit_1),
    .io_perfInfo_hit                             (icache_perfInfo_hit),
    // ---- → ftq（FTQ 发取指请求 / 预取请求给 ICache，以及 ICache 冲刷） ----
    .io_ftqPrefetch_req_ready                    (icache_ftqPrefetch_req_ready),
    // ---- 顶层 io_softPrefetch* —— 后端软件预取（prefetch.i）请求 ----
    .io_softPrefetch_0_valid                     (io_softPrefetch_0_valid),
    .io_softPrefetch_0_bits_vaddr                (io_softPrefetch_0_bits_vaddr),
    .io_softPrefetch_1_valid                     (io_softPrefetch_1_valid),
    .io_softPrefetch_1_bits_vaddr                (io_softPrefetch_1_bits_vaddr),
    .io_softPrefetch_2_valid                     (io_softPrefetch_2_valid),
    .io_softPrefetch_2_bits_vaddr                (io_softPrefetch_2_bits_vaddr),
    // ---- ← ifu：ICache 回指令数据与 topdown 信息给 IFU；IFU 让 ICache 停（stop）；ICache 命中统计给 IFU ----
    .io_stop                                     (ifu_icacheStop),
    // ---- → pmpCheck0（ICache 物理地址权限检查口 0） ----
    .io_pmp_0_req_valid                          (icache_pmp_0_req_valid),
    .io_pmp_0_req_bits_addr                      (icache_pmp_0_req_bits_addr),
    // ---- ← pmpCheck0：ICache 物理地址权限检查口 0 ----
    .io_pmp_0_resp_instr                         (pmpCheck0_resp_instr),
    .io_pmp_0_resp_mmio                          (pmpCheck0_resp_mmio),
    // ---- → pmpCheck1（ICache 物理地址权限检查口 1） ----
    .io_pmp_1_req_valid                          (icache_pmp_1_req_valid),
    .io_pmp_1_req_bits_addr                      (icache_pmp_1_req_bits_addr),
    // ---- ← pmpCheck1：ICache 物理地址权限检查口 1 ----
    .io_pmp_1_resp_instr                         (pmpCheck1_resp_instr),
    .io_pmp_1_resp_mmio                          (pmpCheck1_resp_mmio),
    // ---- → pmpCheck2（ICache 物理地址权限检查口 2） ----
    .io_pmp_2_req_valid                          (icache_pmp_2_req_valid),
    .io_pmp_2_req_bits_addr                      (icache_pmp_2_req_bits_addr),
    // ---- ← pmpCheck2：ICache 物理地址权限检查口 2 ----
    .io_pmp_2_resp_instr                         (pmpCheck2_resp_instr),
    .io_pmp_2_resp_mmio                          (pmpCheck2_resp_mmio),
    // ---- → pmpCheck3（ICache 物理地址权限检查口 3） ----
    .io_pmp_3_req_valid                          (icache_pmp_3_req_valid),
    .io_pmp_3_req_bits_addr                      (icache_pmp_3_req_bits_addr),
    // ---- ← pmpCheck3：ICache 物理地址权限检查口 3 ----
    .io_pmp_3_resp_instr                         (pmpCheck3_resp_instr),
    .io_pmp_3_resp_mmio                          (pmpCheck3_resp_mmio),
    // ---- → itlb（ICache 预取流水的 2 个 ITLB 请求口 / 回应） ----
    .io_itlb_0_req_valid                         (icache_itlb_0_req_valid),
    .io_itlb_0_req_bits_vaddr                    (icache_itlb_0_req_bits_vaddr),
    .io_itlb_1_req_valid                         (icache_itlb_1_req_valid),
    .io_itlb_1_req_bits_vaddr                    (icache_itlb_1_req_bits_vaddr),
    .io_itlbFlushPipe                            (icache_itlbFlushPipe),
    // ---- ← itlb：ICache 预取流水的 2 个 ITLB 请求口 / 回应 ----
    .io_itlb_0_resp_bits_paddr_0                 (itlb_requestor_0_resp_bits_paddr_0),
    .io_itlb_0_resp_bits_gpaddr_0                (itlb_requestor_0_resp_bits_gpaddr_0),
    .io_itlb_0_resp_bits_pbmt_0                  (itlb_requestor_0_resp_bits_pbmt_0),
    .io_itlb_0_resp_bits_miss                    (itlb_requestor_0_resp_bits_miss),
    .io_itlb_0_resp_bits_isForVSnonLeafPTE       (itlb_requestor_0_resp_bits_isForVSnonLeafPTE),
    .io_itlb_0_resp_bits_excp_0_gpf_instr        (itlb_requestor_0_resp_bits_excp_0_gpf_instr),
    .io_itlb_0_resp_bits_excp_0_pf_instr         (itlb_requestor_0_resp_bits_excp_0_pf_instr),
    .io_itlb_0_resp_bits_excp_0_af_instr         (itlb_requestor_0_resp_bits_excp_0_af_instr),
    .io_itlb_1_resp_bits_paddr_0                 (itlb_requestor_1_resp_bits_paddr_0),
    .io_itlb_1_resp_bits_gpaddr_0                (itlb_requestor_1_resp_bits_gpaddr_0),
    .io_itlb_1_resp_bits_pbmt_0                  (itlb_requestor_1_resp_bits_pbmt_0),
    .io_itlb_1_resp_bits_miss                    (itlb_requestor_1_resp_bits_miss),
    .io_itlb_1_resp_bits_isForVSnonLeafPTE       (itlb_requestor_1_resp_bits_isForVSnonLeafPTE),
    .io_itlb_1_resp_bits_excp_0_gpf_instr        (itlb_requestor_1_resp_bits_excp_0_gpf_instr),
    .io_itlb_1_resp_bits_excp_0_pf_instr         (itlb_requestor_1_resp_bits_excp_0_pf_instr),
    .io_itlb_1_resp_bits_excp_0_af_instr         (itlb_requestor_1_resp_bits_excp_0_af_instr),
    // ---- ← u_core：L1I 预取开关 / fence.i（各打一拍）；ECC 错误；wfi 安全 ----
    .io_csr_pf_enable                            (icache_pf_enable),
    .io_fencei                                   (icache_fencei),
    // ---- ← wfiReqDelay：wfi 请求（打一拍后） ----
    .io_wfi_wfiReq                               (wfiReqDelay_out),
    // ---- → perfHpm（ICache 性能事件） ----
    .io_perf_0_value                             (icache_perf_0_value),
    // ---- ← mbistPl：ICache tag / data SRAM 的 MBIST 穿线 ----
    .boreChildrenBd_bore_array                   (mbistBd0_array),
    .boreChildrenBd_bore_all                     (mbistBd0_all),
    .boreChildrenBd_bore_req                     (mbistBd0_req),
    .boreChildrenBd_bore_writeen                 (mbistBd0_writeen),
    .boreChildrenBd_bore_be                      (mbistBd0_be),
    .boreChildrenBd_bore_addr                    (mbistBd0_addr),
    .boreChildrenBd_bore_indata                  (mbistBd0_indata),
    .boreChildrenBd_bore_readen                  (mbistBd0_readen),
    .boreChildrenBd_bore_addr_rd                 (mbistBd0_addr_rd),
    .boreChildrenBd_bore_1_array                 (mbistBd1_array),
    .boreChildrenBd_bore_1_all                   (mbistBd1_all),
    .boreChildrenBd_bore_1_req                   (mbistBd1_req),
    .boreChildrenBd_bore_1_writeen               (mbistBd1_writeen),
    .boreChildrenBd_bore_1_be                    (mbistBd1_be),
    .boreChildrenBd_bore_1_addr                  (mbistBd1_addr),
    .boreChildrenBd_bore_1_indata                (mbistBd1_indata),
    .boreChildrenBd_bore_1_readen                (mbistBd1_readen),
    .boreChildrenBd_bore_1_addr_rd               (mbistBd1_addr_rd),
    .boreChildrenBd_bore_2_array                 (mbistBd2_array),
    .boreChildrenBd_bore_2_all                   (mbistBd2_all),
    .boreChildrenBd_bore_2_req                   (mbistBd2_req),
    .boreChildrenBd_bore_2_writeen               (mbistBd2_writeen),
    .boreChildrenBd_bore_2_be                    (mbistBd2_be),
    .boreChildrenBd_bore_2_addr                  (mbistBd2_addr),
    .boreChildrenBd_bore_2_indata                (mbistBd2_indata),
    .boreChildrenBd_bore_2_readen                (mbistBd2_readen),
    .boreChildrenBd_bore_2_addr_rd               (mbistBd2_addr_rd),
    .boreChildrenBd_bore_3_array                 (mbistBd3_array),
    .boreChildrenBd_bore_3_all                   (mbistBd3_all),
    .boreChildrenBd_bore_3_req                   (mbistBd3_req),
    .boreChildrenBd_bore_3_writeen               (mbistBd3_writeen),
    .boreChildrenBd_bore_3_be                    (mbistBd3_be),
    .boreChildrenBd_bore_3_addr                  (mbistBd3_addr),
    .boreChildrenBd_bore_3_indata                (mbistBd3_indata),
    .boreChildrenBd_bore_3_readen                (mbistBd3_readen),
    .boreChildrenBd_bore_3_addr_rd               (mbistBd3_addr_rd),
    .boreChildrenBd_bore_4_array                 (mbistBd4_array),
    .boreChildrenBd_bore_4_all                   (mbistBd4_all),
    .boreChildrenBd_bore_4_req                   (mbistBd4_req),
    .boreChildrenBd_bore_4_writeen               (mbistBd4_writeen),
    .boreChildrenBd_bore_4_be                    (mbistBd4_be),
    .boreChildrenBd_bore_4_addr                  (mbistBd4_addr),
    .boreChildrenBd_bore_4_indata                (mbistBd4_indata),
    .boreChildrenBd_bore_4_readen                (mbistBd4_readen),
    .boreChildrenBd_bore_4_addr_rd               (mbistBd4_addr_rd),
    // ---- → mbistPl（ICache tag / data SRAM 的 MBIST 穿线） ----
    .boreChildrenBd_bore_ack                     (mbistBd0_ack),
    .boreChildrenBd_bore_outdata                 (mbistBd0_outdata),
    .boreChildrenBd_bore_1_ack                   (mbistBd1_ack),
    .boreChildrenBd_bore_1_outdata               (mbistBd1_outdata),
    .boreChildrenBd_bore_2_ack                   (mbistBd2_ack),
    .boreChildrenBd_bore_2_outdata               (mbistBd2_outdata),
    .boreChildrenBd_bore_3_ack                   (mbistBd3_ack),
    .boreChildrenBd_bore_3_outdata               (mbistBd3_outdata),
    .boreChildrenBd_bore_4_ack                   (mbistBd4_ack),
    .boreChildrenBd_bore_4_outdata               (mbistBd4_outdata),
    // ---- 顶层 io_dft* —— DFT 广播（SRAM 测试控制） ----
    .sigFromSrams_bore_ram_hold                  (io_dft_ram_hold),
    .sigFromSrams_bore_ram_bypass                (io_dft_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken              (io_dft_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk               (io_dft_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp              (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold              (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_cgen                      (io_dft_cgen),
    .sigFromSrams_bore_1_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_1_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_2_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_2_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_3_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_3_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_4_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_4_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_5_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_5_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_6_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_6_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_7_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_7_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_8_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_8_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_9_ram_hold                (io_dft_ram_hold),
    .sigFromSrams_bore_9_ram_bypass              (io_dft_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken            (io_dft_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk             (io_dft_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp            (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold            (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                    (io_dft_cgen),
    .sigFromSrams_bore_10_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_10_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_11_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_11_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_12_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_12_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_13_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_13_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_14_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_14_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_15_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_15_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_16_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_16_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_17_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_17_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_18_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_18_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_19_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_19_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_20_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_20_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_21_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_21_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_22_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_22_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_23_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_23_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_24_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_24_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_25_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_25_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_26_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_26_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_27_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_27_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_28_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_28_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_29_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_29_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_30_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_30_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_31_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_31_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_32_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_32_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_33_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_33_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_34_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_34_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen                   (io_dft_cgen),
    .sigFromSrams_bore_35_ram_hold               (io_dft_ram_hold),
    .sigFromSrams_bore_35_ram_bypass             (io_dft_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken           (io_dft_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk            (io_dft_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp           (io_dft_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold           (io_dft_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen                   (io_dft_cgen),
    // ---- 顶层 gatewayIn_packed* —— MBIST 网关穿线 ----
    .gatewayIn_packed_0_bore                     (gatewayIn_packed_0_bore),
    .gatewayIn_packed_1_bore                     (gatewayIn_packed_1_bore),
    .gatewayIn_packed_2_bore                     (gatewayIn_packed_2_bore)
  );
  NewIFU inner_ifu (
    // ---- 时钟 / 复位 ----
    .clock                                                        (clock),
    .reset                                                        (reset),
    // ---- → core（IFU 对取指请求的 ready（与 ICache 的 ready 相与后给 FTQ）） ----
    .io_ftqInter_fromFtq_req_ready                                (ifu_ftqInter_fromFtq_req_ready),
    // ---- ← ftq：FTQ 发取指请求给 IFU；IFU 回写预译码 / 误预测检查结果；MMIO 指令提交读 FTQ ----
    .io_ftqInter_fromFtq_req_valid                                (ftq_toIfu_req_valid),
    .io_ftqInter_fromFtq_req_bits_startAddr                       (ftq_toIfu_req_bits_startAddr),
    .io_ftqInter_fromFtq_req_bits_nextlineStart                   (ftq_toIfu_req_bits_nextlineStart),
    .io_ftqInter_fromFtq_req_bits_nextStartAddr                   (ftq_toIfu_req_bits_nextStartAddr),
    .io_ftqInter_fromFtq_req_bits_ftqIdx_flag                     (ftq_toIfu_req_bits_ftqIdx_flag),
    .io_ftqInter_fromFtq_req_bits_ftqIdx_value                    (ftq_toIfu_req_bits_ftqIdx_value),
    .io_ftqInter_fromFtq_req_bits_ftqOffset_valid                 (ftq_toIfu_req_bits_ftqOffset_valid),
    .io_ftqInter_fromFtq_req_bits_ftqOffset_bits                  (ftq_toIfu_req_bits_ftqOffset_bits),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_0          (ftq_toIfu_req_bits_topdown_info_reasons_0),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_1          (ftq_toIfu_req_bits_topdown_info_reasons_1),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_2          (ftq_toIfu_req_bits_topdown_info_reasons_2),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_3          (ftq_toIfu_req_bits_topdown_info_reasons_3),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_4          (ftq_toIfu_req_bits_topdown_info_reasons_4),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_5          (ftq_toIfu_req_bits_topdown_info_reasons_5),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_6          (ftq_toIfu_req_bits_topdown_info_reasons_6),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_7          (ftq_toIfu_req_bits_topdown_info_reasons_7),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_8          (ftq_toIfu_req_bits_topdown_info_reasons_8),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_9          (ftq_toIfu_req_bits_topdown_info_reasons_9),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_10         (ftq_toIfu_req_bits_topdown_info_reasons_10),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_11         (ftq_toIfu_req_bits_topdown_info_reasons_11),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_12         (ftq_toIfu_req_bits_topdown_info_reasons_12),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_13         (ftq_toIfu_req_bits_topdown_info_reasons_13),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_14         (ftq_toIfu_req_bits_topdown_info_reasons_14),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_15         (ftq_toIfu_req_bits_topdown_info_reasons_15),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_16         (ftq_toIfu_req_bits_topdown_info_reasons_16),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_17         (ftq_toIfu_req_bits_topdown_info_reasons_17),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_18         (ftq_toIfu_req_bits_topdown_info_reasons_18),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_19         (ftq_toIfu_req_bits_topdown_info_reasons_19),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_20         (ftq_toIfu_req_bits_topdown_info_reasons_20),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_21         (ftq_toIfu_req_bits_topdown_info_reasons_21),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_22         (ftq_toIfu_req_bits_topdown_info_reasons_22),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_23         (ftq_toIfu_req_bits_topdown_info_reasons_23),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_24         (ftq_toIfu_req_bits_topdown_info_reasons_24),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_25         (ftq_toIfu_req_bits_topdown_info_reasons_25),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_26         (ftq_toIfu_req_bits_topdown_info_reasons_26),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_27         (ftq_toIfu_req_bits_topdown_info_reasons_27),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_28         (ftq_toIfu_req_bits_topdown_info_reasons_28),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_29         (ftq_toIfu_req_bits_topdown_info_reasons_29),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_30         (ftq_toIfu_req_bits_topdown_info_reasons_30),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_31         (ftq_toIfu_req_bits_topdown_info_reasons_31),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_32         (ftq_toIfu_req_bits_topdown_info_reasons_32),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_33         (ftq_toIfu_req_bits_topdown_info_reasons_33),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_34         (ftq_toIfu_req_bits_topdown_info_reasons_34),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_35         (ftq_toIfu_req_bits_topdown_info_reasons_35),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_36         (ftq_toIfu_req_bits_topdown_info_reasons_36),
    .io_ftqInter_fromFtq_req_bits_topdown_info_reasons_37         (ftq_toIfu_req_bits_topdown_info_reasons_37),
    .io_ftqInter_fromFtq_redirect_valid                           (ftq_toIfu_redirect_valid),
    .io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag                (ftq_toIfu_redirect_bits_ftqIdx_flag),
    .io_ftqInter_fromFtq_redirect_bits_ftqIdx_value               (ftq_toIfu_redirect_bits_ftqIdx_value),
    .io_ftqInter_fromFtq_redirect_bits_ftqOffset                  (ftq_toIfu_redirect_bits_ftqOffset),
    .io_ftqInter_fromFtq_redirect_bits_level                      (ftq_toIfu_redirect_bits_level),
    .io_ftqInter_fromFtq_topdown_redirect_valid                   (ftq_toIfu_topdown_redirect_valid),
    .io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_pd_isRet (ftq_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet),
    .io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_br_hit   (ftq_toIfu_topdown_redirect_bits_cfiUpdate_br_hit),
    .io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_jr_hit   (ftq_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit),
    .io_ftqInter_fromFtq_topdown_redirect_bits_cfiUpdate_sc_hit   (ftq_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit),
    .io_ftqInter_fromFtq_topdown_redirect_bits_debugIsCtrl        (ftq_toIfu_topdown_redirect_bits_debugIsCtrl),
    .io_ftqInter_fromFtq_topdown_redirect_bits_debugIsMemVio      (ftq_toIfu_topdown_redirect_bits_debugIsMemVio),
    .io_ftqInter_fromFtq_flushFromBpu_s2_valid                    (ftq_toIfu_flushFromBpu_s2_valid),
    .io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag                (ftq_toIfu_flushFromBpu_s2_bits_flag),
    .io_ftqInter_fromFtq_flushFromBpu_s2_bits_value               (ftq_toIfu_flushFromBpu_s2_bits_value),
    .io_ftqInter_fromFtq_flushFromBpu_s3_valid                    (ftq_toIfu_flushFromBpu_s3_valid),
    .io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag                (ftq_toIfu_flushFromBpu_s3_bits_flag),
    .io_ftqInter_fromFtq_flushFromBpu_s3_bits_value               (ftq_toIfu_flushFromBpu_s3_bits_value),
    .io_mmioCommitRead_mmioLastCommit                             (ftq_mmioCommitRead_mmioLastCommit),
    // ---- → ftq（FTQ 发取指请求给 IFU；IFU 回写预译码 / 误预测检查结果；MMIO 指令提交读 FTQ） ----
    .io_ftqInter_toFtq_pdWb_valid                                 (ifu_ftqInter_toFtq_pdWb_valid),
    .io_ftqInter_toFtq_pdWb_bits_pc_0                             (ifu_ftqInter_toFtq_pdWb_bits_pc_0),
    .io_ftqInter_toFtq_pdWb_bits_pc_1                             (ifu_ftqInter_toFtq_pdWb_bits_pc_1),
    .io_ftqInter_toFtq_pdWb_bits_pc_2                             (ifu_ftqInter_toFtq_pdWb_bits_pc_2),
    .io_ftqInter_toFtq_pdWb_bits_pc_3                             (ifu_ftqInter_toFtq_pdWb_bits_pc_3),
    .io_ftqInter_toFtq_pdWb_bits_pc_4                             (ifu_ftqInter_toFtq_pdWb_bits_pc_4),
    .io_ftqInter_toFtq_pdWb_bits_pc_5                             (ifu_ftqInter_toFtq_pdWb_bits_pc_5),
    .io_ftqInter_toFtq_pdWb_bits_pc_6                             (ifu_ftqInter_toFtq_pdWb_bits_pc_6),
    .io_ftqInter_toFtq_pdWb_bits_pc_7                             (ifu_ftqInter_toFtq_pdWb_bits_pc_7),
    .io_ftqInter_toFtq_pdWb_bits_pc_8                             (ifu_ftqInter_toFtq_pdWb_bits_pc_8),
    .io_ftqInter_toFtq_pdWb_bits_pc_9                             (ifu_ftqInter_toFtq_pdWb_bits_pc_9),
    .io_ftqInter_toFtq_pdWb_bits_pc_10                            (ifu_ftqInter_toFtq_pdWb_bits_pc_10),
    .io_ftqInter_toFtq_pdWb_bits_pc_11                            (ifu_ftqInter_toFtq_pdWb_bits_pc_11),
    .io_ftqInter_toFtq_pdWb_bits_pc_12                            (ifu_ftqInter_toFtq_pdWb_bits_pc_12),
    .io_ftqInter_toFtq_pdWb_bits_pc_13                            (ifu_ftqInter_toFtq_pdWb_bits_pc_13),
    .io_ftqInter_toFtq_pdWb_bits_pc_14                            (ifu_ftqInter_toFtq_pdWb_bits_pc_14),
    .io_ftqInter_toFtq_pdWb_bits_pc_15                            (ifu_ftqInter_toFtq_pdWb_bits_pc_15),
    .io_ftqInter_toFtq_pdWb_bits_pd_0_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_0_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_0_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_0_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_0_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_0_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_0_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_0_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_0_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_0_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_1_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_1_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_1_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_1_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_1_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_1_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_1_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_1_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_1_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_1_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_2_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_2_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_2_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_2_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_2_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_2_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_2_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_2_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_2_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_2_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_3_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_3_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_3_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_3_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_3_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_3_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_3_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_3_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_3_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_3_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_4_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_4_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_4_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_4_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_4_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_4_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_4_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_4_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_4_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_4_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_5_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_5_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_5_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_5_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_5_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_5_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_5_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_5_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_5_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_5_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_6_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_6_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_6_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_6_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_6_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_6_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_6_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_6_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_6_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_6_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_7_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_7_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_7_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_7_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_7_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_7_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_7_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_7_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_7_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_7_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_8_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_8_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_8_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_8_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_8_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_8_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_8_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_8_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_8_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_8_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_9_valid                       (ifu_ftqInter_toFtq_pdWb_bits_pd_9_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_9_isRVC                       (ifu_ftqInter_toFtq_pdWb_bits_pd_9_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_9_brType                      (ifu_ftqInter_toFtq_pdWb_bits_pd_9_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_9_isCall                      (ifu_ftqInter_toFtq_pdWb_bits_pd_9_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_9_isRet                       (ifu_ftqInter_toFtq_pdWb_bits_pd_9_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_10_valid                      (ifu_ftqInter_toFtq_pdWb_bits_pd_10_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_10_isRVC                      (ifu_ftqInter_toFtq_pdWb_bits_pd_10_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_10_brType                     (ifu_ftqInter_toFtq_pdWb_bits_pd_10_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_10_isCall                     (ifu_ftqInter_toFtq_pdWb_bits_pd_10_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_10_isRet                      (ifu_ftqInter_toFtq_pdWb_bits_pd_10_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_11_valid                      (ifu_ftqInter_toFtq_pdWb_bits_pd_11_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_11_isRVC                      (ifu_ftqInter_toFtq_pdWb_bits_pd_11_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_11_brType                     (ifu_ftqInter_toFtq_pdWb_bits_pd_11_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_11_isCall                     (ifu_ftqInter_toFtq_pdWb_bits_pd_11_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_11_isRet                      (ifu_ftqInter_toFtq_pdWb_bits_pd_11_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_12_valid                      (ifu_ftqInter_toFtq_pdWb_bits_pd_12_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_12_isRVC                      (ifu_ftqInter_toFtq_pdWb_bits_pd_12_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_12_brType                     (ifu_ftqInter_toFtq_pdWb_bits_pd_12_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_12_isCall                     (ifu_ftqInter_toFtq_pdWb_bits_pd_12_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_12_isRet                      (ifu_ftqInter_toFtq_pdWb_bits_pd_12_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_13_valid                      (ifu_ftqInter_toFtq_pdWb_bits_pd_13_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_13_isRVC                      (ifu_ftqInter_toFtq_pdWb_bits_pd_13_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_13_brType                     (ifu_ftqInter_toFtq_pdWb_bits_pd_13_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_13_isCall                     (ifu_ftqInter_toFtq_pdWb_bits_pd_13_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_13_isRet                      (ifu_ftqInter_toFtq_pdWb_bits_pd_13_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_14_valid                      (ifu_ftqInter_toFtq_pdWb_bits_pd_14_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_14_isRVC                      (ifu_ftqInter_toFtq_pdWb_bits_pd_14_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_14_brType                     (ifu_ftqInter_toFtq_pdWb_bits_pd_14_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_14_isCall                     (ifu_ftqInter_toFtq_pdWb_bits_pd_14_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_14_isRet                      (ifu_ftqInter_toFtq_pdWb_bits_pd_14_isRet),
    .io_ftqInter_toFtq_pdWb_bits_pd_15_valid                      (ifu_ftqInter_toFtq_pdWb_bits_pd_15_valid),
    .io_ftqInter_toFtq_pdWb_bits_pd_15_isRVC                      (ifu_ftqInter_toFtq_pdWb_bits_pd_15_isRVC),
    .io_ftqInter_toFtq_pdWb_bits_pd_15_brType                     (ifu_ftqInter_toFtq_pdWb_bits_pd_15_brType),
    .io_ftqInter_toFtq_pdWb_bits_pd_15_isCall                     (ifu_ftqInter_toFtq_pdWb_bits_pd_15_isCall),
    .io_ftqInter_toFtq_pdWb_bits_pd_15_isRet                      (ifu_ftqInter_toFtq_pdWb_bits_pd_15_isRet),
    .io_ftqInter_toFtq_pdWb_bits_ftqIdx_flag                      (ifu_ftqInter_toFtq_pdWb_bits_ftqIdx_flag),
    .io_ftqInter_toFtq_pdWb_bits_ftqIdx_value                     (ifu_ftqInter_toFtq_pdWb_bits_ftqIdx_value),
    .io_ftqInter_toFtq_pdWb_bits_misOffset_valid                  (ifu_ftqInter_toFtq_pdWb_bits_misOffset_valid),
    .io_ftqInter_toFtq_pdWb_bits_misOffset_bits                   (ifu_ftqInter_toFtq_pdWb_bits_misOffset_bits),
    .io_ftqInter_toFtq_pdWb_bits_cfiOffset_valid                  (ifu_ftqInter_toFtq_pdWb_bits_cfiOffset_valid),
    .io_ftqInter_toFtq_pdWb_bits_target                           (ifu_ftqInter_toFtq_pdWb_bits_target),
    .io_ftqInter_toFtq_pdWb_bits_jalTarget                        (ifu_ftqInter_toFtq_pdWb_bits_jalTarget),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_0                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_0),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_1                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_1),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_2                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_2),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_3                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_3),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_4                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_4),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_5                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_5),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_6                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_6),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_7                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_7),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_8                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_8),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_9                     (ifu_ftqInter_toFtq_pdWb_bits_instrRange_9),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_10                    (ifu_ftqInter_toFtq_pdWb_bits_instrRange_10),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_11                    (ifu_ftqInter_toFtq_pdWb_bits_instrRange_11),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_12                    (ifu_ftqInter_toFtq_pdWb_bits_instrRange_12),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_13                    (ifu_ftqInter_toFtq_pdWb_bits_instrRange_13),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_14                    (ifu_ftqInter_toFtq_pdWb_bits_instrRange_14),
    .io_ftqInter_toFtq_pdWb_bits_instrRange_15                    (ifu_ftqInter_toFtq_pdWb_bits_instrRange_15),
    .io_mmioCommitRead_valid                                      (ifu_mmioCommitRead_valid),
    .io_mmioCommitRead_mmioFtqPtr_flag                            (ifu_mmioCommitRead_mmioFtqPtr_flag),
    .io_mmioCommitRead_mmioFtqPtr_value                           (ifu_mmioCommitRead_mmioFtqPtr_value),
    // ---- ← icache：ICache 回指令数据与 topdown 信息给 IFU；IFU 让 ICache 停（stop）；ICache 命中统计给 IFU ----
    .io_icacheInter_icacheReady                                   (icache_toIFU),
    .io_icacheInter_resp_valid                                    (icache_fetch_resp_valid),
    .io_icacheInter_resp_bits_doubleline                          (icache_fetch_resp_bits_doubleline),
    .io_icacheInter_resp_bits_vaddr_0                             (icache_fetch_resp_bits_vaddr_0),
    .io_icacheInter_resp_bits_vaddr_1                             (icache_fetch_resp_bits_vaddr_1),
    .io_icacheInter_resp_bits_data                                (icache_fetch_resp_bits_data),
    .io_icacheInter_resp_bits_paddr_0                             (icache_fetch_resp_bits_paddr_0),
    .io_icacheInter_resp_bits_exception_0                         (icache_fetch_resp_bits_exception_0),
    .io_icacheInter_resp_bits_exception_1                         (icache_fetch_resp_bits_exception_1),
    .io_icacheInter_resp_bits_pmp_mmio_0                          (icache_fetch_resp_bits_pmp_mmio_0),
    .io_icacheInter_resp_bits_pmp_mmio_1                          (icache_fetch_resp_bits_pmp_mmio_1),
    .io_icacheInter_resp_bits_itlb_pbmt_0                         (icache_fetch_resp_bits_itlb_pbmt_0),
    .io_icacheInter_resp_bits_itlb_pbmt_1                         (icache_fetch_resp_bits_itlb_pbmt_1),
    .io_icacheInter_resp_bits_backendException                    (icache_fetch_resp_bits_backendException),
    .io_icacheInter_resp_bits_hasSatpFlush                        (icache_fetch_resp_bits_hasSatpFlush),
    .io_icacheInter_resp_bits_gpaddr                              (icache_fetch_resp_bits_gpaddr),
    .io_icacheInter_resp_bits_isForVSnonLeafPTE                   (icache_fetch_resp_bits_isForVSnonLeafPTE),
    .io_icacheInter_topdownIcacheMiss                             (icache_fetch_topdownIcacheMiss),
    .io_icacheInter_topdownItlbMiss                               (icache_fetch_topdownItlbMiss),
    .io_icachePerfInfo_only_0_hit                                 (icache_perfInfo_only_0_hit),
    .io_icachePerfInfo_only_0_miss                                (icache_perfInfo_only_0_miss),
    .io_icachePerfInfo_hit_0_hit_1                                (icache_perfInfo_hit_0_hit_1),
    .io_icachePerfInfo_hit_0_miss_1                               (icache_perfInfo_hit_0_miss_1),
    .io_icachePerfInfo_miss_0_hit_1                               (icache_perfInfo_miss_0_hit_1),
    .io_icachePerfInfo_miss_0_miss_1                              (icache_perfInfo_miss_0_miss_1),
    .io_icachePerfInfo_hit_0_except_1                             (icache_perfInfo_hit_0_except_1),
    .io_icachePerfInfo_miss_0_except_1                            (icache_perfInfo_miss_0_except_1),
    .io_icachePerfInfo_except_0                                   (icache_perfInfo_except_0),
    .io_icachePerfInfo_bank_hit_0                                 (icache_perfInfo_bank_hit_0),
    .io_icachePerfInfo_bank_hit_1                                 (icache_perfInfo_bank_hit_1),
    .io_icachePerfInfo_hit                                        (icache_perfInfo_hit),
    // ---- → icache（ICache 回指令数据与 topdown 信息给 IFU；IFU 让 ICache 停（stop）；ICache 命中统计给 IFU） ----
    .io_icacheStop                                                (ifu_icacheStop),
    // ---- ← ibuffer：IFU 把预译码后的取指块写进 IBuffer ----
    .io_toIbuffer_ready                                           (ibuffer_in_ready),
    // ---- → ibuffer（IFU 把预译码后的取指块写进 IBuffer） ----
    .io_toIbuffer_valid                                           (ifu_toIbuffer_valid),
    .io_toIbuffer_bits_instrs_0                                   (ifu_toIbuffer_bits_instrs_0),
    .io_toIbuffer_bits_instrs_1                                   (ifu_toIbuffer_bits_instrs_1),
    .io_toIbuffer_bits_instrs_2                                   (ifu_toIbuffer_bits_instrs_2),
    .io_toIbuffer_bits_instrs_3                                   (ifu_toIbuffer_bits_instrs_3),
    .io_toIbuffer_bits_instrs_4                                   (ifu_toIbuffer_bits_instrs_4),
    .io_toIbuffer_bits_instrs_5                                   (ifu_toIbuffer_bits_instrs_5),
    .io_toIbuffer_bits_instrs_6                                   (ifu_toIbuffer_bits_instrs_6),
    .io_toIbuffer_bits_instrs_7                                   (ifu_toIbuffer_bits_instrs_7),
    .io_toIbuffer_bits_instrs_8                                   (ifu_toIbuffer_bits_instrs_8),
    .io_toIbuffer_bits_instrs_9                                   (ifu_toIbuffer_bits_instrs_9),
    .io_toIbuffer_bits_instrs_10                                  (ifu_toIbuffer_bits_instrs_10),
    .io_toIbuffer_bits_instrs_11                                  (ifu_toIbuffer_bits_instrs_11),
    .io_toIbuffer_bits_instrs_12                                  (ifu_toIbuffer_bits_instrs_12),
    .io_toIbuffer_bits_instrs_13                                  (ifu_toIbuffer_bits_instrs_13),
    .io_toIbuffer_bits_instrs_14                                  (ifu_toIbuffer_bits_instrs_14),
    .io_toIbuffer_bits_instrs_15                                  (ifu_toIbuffer_bits_instrs_15),
    .io_toIbuffer_bits_valid                                      (ifu_toIbuffer_bits_valid),
    .io_toIbuffer_bits_enqEnable                                  (ifu_toIbuffer_bits_enqEnable),
    .io_toIbuffer_bits_pd_0_isRVC                                 (ifu_toIbuffer_bits_pd_0_isRVC),
    .io_toIbuffer_bits_pd_0_brType                                (ifu_toIbuffer_bits_pd_0_brType),
    .io_toIbuffer_bits_pd_0_isCall                                (ifu_toIbuffer_bits_pd_0_isCall),
    .io_toIbuffer_bits_pd_0_isRet                                 (ifu_toIbuffer_bits_pd_0_isRet),
    .io_toIbuffer_bits_pd_1_valid                                 (ifu_toIbuffer_bits_pd_1_valid),
    .io_toIbuffer_bits_pd_1_isRVC                                 (ifu_toIbuffer_bits_pd_1_isRVC),
    .io_toIbuffer_bits_pd_1_brType                                (ifu_toIbuffer_bits_pd_1_brType),
    .io_toIbuffer_bits_pd_1_isCall                                (ifu_toIbuffer_bits_pd_1_isCall),
    .io_toIbuffer_bits_pd_1_isRet                                 (ifu_toIbuffer_bits_pd_1_isRet),
    .io_toIbuffer_bits_pd_2_valid                                 (ifu_toIbuffer_bits_pd_2_valid),
    .io_toIbuffer_bits_pd_2_isRVC                                 (ifu_toIbuffer_bits_pd_2_isRVC),
    .io_toIbuffer_bits_pd_2_brType                                (ifu_toIbuffer_bits_pd_2_brType),
    .io_toIbuffer_bits_pd_2_isCall                                (ifu_toIbuffer_bits_pd_2_isCall),
    .io_toIbuffer_bits_pd_2_isRet                                 (ifu_toIbuffer_bits_pd_2_isRet),
    .io_toIbuffer_bits_pd_3_valid                                 (ifu_toIbuffer_bits_pd_3_valid),
    .io_toIbuffer_bits_pd_3_isRVC                                 (ifu_toIbuffer_bits_pd_3_isRVC),
    .io_toIbuffer_bits_pd_3_brType                                (ifu_toIbuffer_bits_pd_3_brType),
    .io_toIbuffer_bits_pd_3_isCall                                (ifu_toIbuffer_bits_pd_3_isCall),
    .io_toIbuffer_bits_pd_3_isRet                                 (ifu_toIbuffer_bits_pd_3_isRet),
    .io_toIbuffer_bits_pd_4_valid                                 (ifu_toIbuffer_bits_pd_4_valid),
    .io_toIbuffer_bits_pd_4_isRVC                                 (ifu_toIbuffer_bits_pd_4_isRVC),
    .io_toIbuffer_bits_pd_4_brType                                (ifu_toIbuffer_bits_pd_4_brType),
    .io_toIbuffer_bits_pd_4_isCall                                (ifu_toIbuffer_bits_pd_4_isCall),
    .io_toIbuffer_bits_pd_4_isRet                                 (ifu_toIbuffer_bits_pd_4_isRet),
    .io_toIbuffer_bits_pd_5_valid                                 (ifu_toIbuffer_bits_pd_5_valid),
    .io_toIbuffer_bits_pd_5_isRVC                                 (ifu_toIbuffer_bits_pd_5_isRVC),
    .io_toIbuffer_bits_pd_5_brType                                (ifu_toIbuffer_bits_pd_5_brType),
    .io_toIbuffer_bits_pd_5_isCall                                (ifu_toIbuffer_bits_pd_5_isCall),
    .io_toIbuffer_bits_pd_5_isRet                                 (ifu_toIbuffer_bits_pd_5_isRet),
    .io_toIbuffer_bits_pd_6_valid                                 (ifu_toIbuffer_bits_pd_6_valid),
    .io_toIbuffer_bits_pd_6_isRVC                                 (ifu_toIbuffer_bits_pd_6_isRVC),
    .io_toIbuffer_bits_pd_6_brType                                (ifu_toIbuffer_bits_pd_6_brType),
    .io_toIbuffer_bits_pd_6_isCall                                (ifu_toIbuffer_bits_pd_6_isCall),
    .io_toIbuffer_bits_pd_6_isRet                                 (ifu_toIbuffer_bits_pd_6_isRet),
    .io_toIbuffer_bits_pd_7_valid                                 (ifu_toIbuffer_bits_pd_7_valid),
    .io_toIbuffer_bits_pd_7_isRVC                                 (ifu_toIbuffer_bits_pd_7_isRVC),
    .io_toIbuffer_bits_pd_7_brType                                (ifu_toIbuffer_bits_pd_7_brType),
    .io_toIbuffer_bits_pd_7_isCall                                (ifu_toIbuffer_bits_pd_7_isCall),
    .io_toIbuffer_bits_pd_7_isRet                                 (ifu_toIbuffer_bits_pd_7_isRet),
    .io_toIbuffer_bits_pd_8_valid                                 (ifu_toIbuffer_bits_pd_8_valid),
    .io_toIbuffer_bits_pd_8_isRVC                                 (ifu_toIbuffer_bits_pd_8_isRVC),
    .io_toIbuffer_bits_pd_8_brType                                (ifu_toIbuffer_bits_pd_8_brType),
    .io_toIbuffer_bits_pd_8_isCall                                (ifu_toIbuffer_bits_pd_8_isCall),
    .io_toIbuffer_bits_pd_8_isRet                                 (ifu_toIbuffer_bits_pd_8_isRet),
    .io_toIbuffer_bits_pd_9_valid                                 (ifu_toIbuffer_bits_pd_9_valid),
    .io_toIbuffer_bits_pd_9_isRVC                                 (ifu_toIbuffer_bits_pd_9_isRVC),
    .io_toIbuffer_bits_pd_9_brType                                (ifu_toIbuffer_bits_pd_9_brType),
    .io_toIbuffer_bits_pd_9_isCall                                (ifu_toIbuffer_bits_pd_9_isCall),
    .io_toIbuffer_bits_pd_9_isRet                                 (ifu_toIbuffer_bits_pd_9_isRet),
    .io_toIbuffer_bits_pd_10_valid                                (ifu_toIbuffer_bits_pd_10_valid),
    .io_toIbuffer_bits_pd_10_isRVC                                (ifu_toIbuffer_bits_pd_10_isRVC),
    .io_toIbuffer_bits_pd_10_brType                               (ifu_toIbuffer_bits_pd_10_brType),
    .io_toIbuffer_bits_pd_10_isCall                               (ifu_toIbuffer_bits_pd_10_isCall),
    .io_toIbuffer_bits_pd_10_isRet                                (ifu_toIbuffer_bits_pd_10_isRet),
    .io_toIbuffer_bits_pd_11_valid                                (ifu_toIbuffer_bits_pd_11_valid),
    .io_toIbuffer_bits_pd_11_isRVC                                (ifu_toIbuffer_bits_pd_11_isRVC),
    .io_toIbuffer_bits_pd_11_brType                               (ifu_toIbuffer_bits_pd_11_brType),
    .io_toIbuffer_bits_pd_11_isCall                               (ifu_toIbuffer_bits_pd_11_isCall),
    .io_toIbuffer_bits_pd_11_isRet                                (ifu_toIbuffer_bits_pd_11_isRet),
    .io_toIbuffer_bits_pd_12_valid                                (ifu_toIbuffer_bits_pd_12_valid),
    .io_toIbuffer_bits_pd_12_isRVC                                (ifu_toIbuffer_bits_pd_12_isRVC),
    .io_toIbuffer_bits_pd_12_brType                               (ifu_toIbuffer_bits_pd_12_brType),
    .io_toIbuffer_bits_pd_12_isCall                               (ifu_toIbuffer_bits_pd_12_isCall),
    .io_toIbuffer_bits_pd_12_isRet                                (ifu_toIbuffer_bits_pd_12_isRet),
    .io_toIbuffer_bits_pd_13_valid                                (ifu_toIbuffer_bits_pd_13_valid),
    .io_toIbuffer_bits_pd_13_isRVC                                (ifu_toIbuffer_bits_pd_13_isRVC),
    .io_toIbuffer_bits_pd_13_brType                               (ifu_toIbuffer_bits_pd_13_brType),
    .io_toIbuffer_bits_pd_13_isCall                               (ifu_toIbuffer_bits_pd_13_isCall),
    .io_toIbuffer_bits_pd_13_isRet                                (ifu_toIbuffer_bits_pd_13_isRet),
    .io_toIbuffer_bits_pd_14_valid                                (ifu_toIbuffer_bits_pd_14_valid),
    .io_toIbuffer_bits_pd_14_isRVC                                (ifu_toIbuffer_bits_pd_14_isRVC),
    .io_toIbuffer_bits_pd_14_brType                               (ifu_toIbuffer_bits_pd_14_brType),
    .io_toIbuffer_bits_pd_14_isCall                               (ifu_toIbuffer_bits_pd_14_isCall),
    .io_toIbuffer_bits_pd_14_isRet                                (ifu_toIbuffer_bits_pd_14_isRet),
    .io_toIbuffer_bits_pd_15_valid                                (ifu_toIbuffer_bits_pd_15_valid),
    .io_toIbuffer_bits_pd_15_isRVC                                (ifu_toIbuffer_bits_pd_15_isRVC),
    .io_toIbuffer_bits_pd_15_brType                               (ifu_toIbuffer_bits_pd_15_brType),
    .io_toIbuffer_bits_pd_15_isCall                               (ifu_toIbuffer_bits_pd_15_isCall),
    .io_toIbuffer_bits_pd_15_isRet                                (ifu_toIbuffer_bits_pd_15_isRet),
    .io_toIbuffer_bits_foldpc_0                                   (ifu_toIbuffer_bits_foldpc_0),
    .io_toIbuffer_bits_foldpc_1                                   (ifu_toIbuffer_bits_foldpc_1),
    .io_toIbuffer_bits_foldpc_2                                   (ifu_toIbuffer_bits_foldpc_2),
    .io_toIbuffer_bits_foldpc_3                                   (ifu_toIbuffer_bits_foldpc_3),
    .io_toIbuffer_bits_foldpc_4                                   (ifu_toIbuffer_bits_foldpc_4),
    .io_toIbuffer_bits_foldpc_5                                   (ifu_toIbuffer_bits_foldpc_5),
    .io_toIbuffer_bits_foldpc_6                                   (ifu_toIbuffer_bits_foldpc_6),
    .io_toIbuffer_bits_foldpc_7                                   (ifu_toIbuffer_bits_foldpc_7),
    .io_toIbuffer_bits_foldpc_8                                   (ifu_toIbuffer_bits_foldpc_8),
    .io_toIbuffer_bits_foldpc_9                                   (ifu_toIbuffer_bits_foldpc_9),
    .io_toIbuffer_bits_foldpc_10                                  (ifu_toIbuffer_bits_foldpc_10),
    .io_toIbuffer_bits_foldpc_11                                  (ifu_toIbuffer_bits_foldpc_11),
    .io_toIbuffer_bits_foldpc_12                                  (ifu_toIbuffer_bits_foldpc_12),
    .io_toIbuffer_bits_foldpc_13                                  (ifu_toIbuffer_bits_foldpc_13),
    .io_toIbuffer_bits_foldpc_14                                  (ifu_toIbuffer_bits_foldpc_14),
    .io_toIbuffer_bits_foldpc_15                                  (ifu_toIbuffer_bits_foldpc_15),
    .io_toIbuffer_bits_ftqOffset_0_valid                          (ifu_toIbuffer_bits_ftqOffset_0_valid),
    .io_toIbuffer_bits_ftqOffset_1_valid                          (ifu_toIbuffer_bits_ftqOffset_1_valid),
    .io_toIbuffer_bits_ftqOffset_2_valid                          (ifu_toIbuffer_bits_ftqOffset_2_valid),
    .io_toIbuffer_bits_ftqOffset_3_valid                          (ifu_toIbuffer_bits_ftqOffset_3_valid),
    .io_toIbuffer_bits_ftqOffset_4_valid                          (ifu_toIbuffer_bits_ftqOffset_4_valid),
    .io_toIbuffer_bits_ftqOffset_5_valid                          (ifu_toIbuffer_bits_ftqOffset_5_valid),
    .io_toIbuffer_bits_ftqOffset_6_valid                          (ifu_toIbuffer_bits_ftqOffset_6_valid),
    .io_toIbuffer_bits_ftqOffset_7_valid                          (ifu_toIbuffer_bits_ftqOffset_7_valid),
    .io_toIbuffer_bits_ftqOffset_8_valid                          (ifu_toIbuffer_bits_ftqOffset_8_valid),
    .io_toIbuffer_bits_ftqOffset_9_valid                          (ifu_toIbuffer_bits_ftqOffset_9_valid),
    .io_toIbuffer_bits_ftqOffset_10_valid                         (ifu_toIbuffer_bits_ftqOffset_10_valid),
    .io_toIbuffer_bits_ftqOffset_11_valid                         (ifu_toIbuffer_bits_ftqOffset_11_valid),
    .io_toIbuffer_bits_ftqOffset_12_valid                         (ifu_toIbuffer_bits_ftqOffset_12_valid),
    .io_toIbuffer_bits_ftqOffset_13_valid                         (ifu_toIbuffer_bits_ftqOffset_13_valid),
    .io_toIbuffer_bits_ftqOffset_14_valid                         (ifu_toIbuffer_bits_ftqOffset_14_valid),
    .io_toIbuffer_bits_ftqOffset_15_valid                         (ifu_toIbuffer_bits_ftqOffset_15_valid),
    .io_toIbuffer_bits_backendException_0                         (ifu_toIbuffer_bits_backendException_0),
    .io_toIbuffer_bits_satpFlushFirstFetchFault_0                 (ifu_toIbuffer_bits_satpFlushFirstFetchFault_0),
    .io_toIbuffer_bits_exceptionType_0                            (ifu_toIbuffer_bits_exceptionType_0),
    .io_toIbuffer_bits_exceptionType_1                            (ifu_toIbuffer_bits_exceptionType_1),
    .io_toIbuffer_bits_exceptionType_2                            (ifu_toIbuffer_bits_exceptionType_2),
    .io_toIbuffer_bits_exceptionType_3                            (ifu_toIbuffer_bits_exceptionType_3),
    .io_toIbuffer_bits_exceptionType_4                            (ifu_toIbuffer_bits_exceptionType_4),
    .io_toIbuffer_bits_exceptionType_5                            (ifu_toIbuffer_bits_exceptionType_5),
    .io_toIbuffer_bits_exceptionType_6                            (ifu_toIbuffer_bits_exceptionType_6),
    .io_toIbuffer_bits_exceptionType_7                            (ifu_toIbuffer_bits_exceptionType_7),
    .io_toIbuffer_bits_exceptionType_8                            (ifu_toIbuffer_bits_exceptionType_8),
    .io_toIbuffer_bits_exceptionType_9                            (ifu_toIbuffer_bits_exceptionType_9),
    .io_toIbuffer_bits_exceptionType_10                           (ifu_toIbuffer_bits_exceptionType_10),
    .io_toIbuffer_bits_exceptionType_11                           (ifu_toIbuffer_bits_exceptionType_11),
    .io_toIbuffer_bits_exceptionType_12                           (ifu_toIbuffer_bits_exceptionType_12),
    .io_toIbuffer_bits_exceptionType_13                           (ifu_toIbuffer_bits_exceptionType_13),
    .io_toIbuffer_bits_exceptionType_14                           (ifu_toIbuffer_bits_exceptionType_14),
    .io_toIbuffer_bits_exceptionType_15                           (ifu_toIbuffer_bits_exceptionType_15),
    .io_toIbuffer_bits_crossPageIPFFix_0                          (ifu_toIbuffer_bits_crossPageIPFFix_0),
    .io_toIbuffer_bits_crossPageIPFFix_1                          (ifu_toIbuffer_bits_crossPageIPFFix_1),
    .io_toIbuffer_bits_crossPageIPFFix_2                          (ifu_toIbuffer_bits_crossPageIPFFix_2),
    .io_toIbuffer_bits_crossPageIPFFix_3                          (ifu_toIbuffer_bits_crossPageIPFFix_3),
    .io_toIbuffer_bits_crossPageIPFFix_4                          (ifu_toIbuffer_bits_crossPageIPFFix_4),
    .io_toIbuffer_bits_crossPageIPFFix_5                          (ifu_toIbuffer_bits_crossPageIPFFix_5),
    .io_toIbuffer_bits_crossPageIPFFix_6                          (ifu_toIbuffer_bits_crossPageIPFFix_6),
    .io_toIbuffer_bits_crossPageIPFFix_7                          (ifu_toIbuffer_bits_crossPageIPFFix_7),
    .io_toIbuffer_bits_crossPageIPFFix_8                          (ifu_toIbuffer_bits_crossPageIPFFix_8),
    .io_toIbuffer_bits_crossPageIPFFix_9                          (ifu_toIbuffer_bits_crossPageIPFFix_9),
    .io_toIbuffer_bits_crossPageIPFFix_10                         (ifu_toIbuffer_bits_crossPageIPFFix_10),
    .io_toIbuffer_bits_crossPageIPFFix_11                         (ifu_toIbuffer_bits_crossPageIPFFix_11),
    .io_toIbuffer_bits_crossPageIPFFix_12                         (ifu_toIbuffer_bits_crossPageIPFFix_12),
    .io_toIbuffer_bits_crossPageIPFFix_13                         (ifu_toIbuffer_bits_crossPageIPFFix_13),
    .io_toIbuffer_bits_crossPageIPFFix_14                         (ifu_toIbuffer_bits_crossPageIPFFix_14),
    .io_toIbuffer_bits_crossPageIPFFix_15                         (ifu_toIbuffer_bits_crossPageIPFFix_15),
    .io_toIbuffer_bits_illegalInstr_0                             (ifu_toIbuffer_bits_illegalInstr_0),
    .io_toIbuffer_bits_illegalInstr_1                             (ifu_toIbuffer_bits_illegalInstr_1),
    .io_toIbuffer_bits_illegalInstr_2                             (ifu_toIbuffer_bits_illegalInstr_2),
    .io_toIbuffer_bits_illegalInstr_3                             (ifu_toIbuffer_bits_illegalInstr_3),
    .io_toIbuffer_bits_illegalInstr_4                             (ifu_toIbuffer_bits_illegalInstr_4),
    .io_toIbuffer_bits_illegalInstr_5                             (ifu_toIbuffer_bits_illegalInstr_5),
    .io_toIbuffer_bits_illegalInstr_6                             (ifu_toIbuffer_bits_illegalInstr_6),
    .io_toIbuffer_bits_illegalInstr_7                             (ifu_toIbuffer_bits_illegalInstr_7),
    .io_toIbuffer_bits_illegalInstr_8                             (ifu_toIbuffer_bits_illegalInstr_8),
    .io_toIbuffer_bits_illegalInstr_9                             (ifu_toIbuffer_bits_illegalInstr_9),
    .io_toIbuffer_bits_illegalInstr_10                            (ifu_toIbuffer_bits_illegalInstr_10),
    .io_toIbuffer_bits_illegalInstr_11                            (ifu_toIbuffer_bits_illegalInstr_11),
    .io_toIbuffer_bits_illegalInstr_12                            (ifu_toIbuffer_bits_illegalInstr_12),
    .io_toIbuffer_bits_illegalInstr_13                            (ifu_toIbuffer_bits_illegalInstr_13),
    .io_toIbuffer_bits_illegalInstr_14                            (ifu_toIbuffer_bits_illegalInstr_14),
    .io_toIbuffer_bits_illegalInstr_15                            (ifu_toIbuffer_bits_illegalInstr_15),
    .io_toIbuffer_bits_triggered_0                                (ifu_toIbuffer_bits_triggered_0),
    .io_toIbuffer_bits_triggered_1                                (ifu_toIbuffer_bits_triggered_1),
    .io_toIbuffer_bits_triggered_2                                (ifu_toIbuffer_bits_triggered_2),
    .io_toIbuffer_bits_triggered_3                                (ifu_toIbuffer_bits_triggered_3),
    .io_toIbuffer_bits_triggered_4                                (ifu_toIbuffer_bits_triggered_4),
    .io_toIbuffer_bits_triggered_5                                (ifu_toIbuffer_bits_triggered_5),
    .io_toIbuffer_bits_triggered_6                                (ifu_toIbuffer_bits_triggered_6),
    .io_toIbuffer_bits_triggered_7                                (ifu_toIbuffer_bits_triggered_7),
    .io_toIbuffer_bits_triggered_8                                (ifu_toIbuffer_bits_triggered_8),
    .io_toIbuffer_bits_triggered_9                                (ifu_toIbuffer_bits_triggered_9),
    .io_toIbuffer_bits_triggered_10                               (ifu_toIbuffer_bits_triggered_10),
    .io_toIbuffer_bits_triggered_11                               (ifu_toIbuffer_bits_triggered_11),
    .io_toIbuffer_bits_triggered_12                               (ifu_toIbuffer_bits_triggered_12),
    .io_toIbuffer_bits_triggered_13                               (ifu_toIbuffer_bits_triggered_13),
    .io_toIbuffer_bits_triggered_14                               (ifu_toIbuffer_bits_triggered_14),
    .io_toIbuffer_bits_triggered_15                               (ifu_toIbuffer_bits_triggered_15),
    .io_toIbuffer_bits_isLastInFtqEntry_0                         (ifu_toIbuffer_bits_isLastInFtqEntry_0),
    .io_toIbuffer_bits_isLastInFtqEntry_1                         (ifu_toIbuffer_bits_isLastInFtqEntry_1),
    .io_toIbuffer_bits_isLastInFtqEntry_2                         (ifu_toIbuffer_bits_isLastInFtqEntry_2),
    .io_toIbuffer_bits_isLastInFtqEntry_3                         (ifu_toIbuffer_bits_isLastInFtqEntry_3),
    .io_toIbuffer_bits_isLastInFtqEntry_4                         (ifu_toIbuffer_bits_isLastInFtqEntry_4),
    .io_toIbuffer_bits_isLastInFtqEntry_5                         (ifu_toIbuffer_bits_isLastInFtqEntry_5),
    .io_toIbuffer_bits_isLastInFtqEntry_6                         (ifu_toIbuffer_bits_isLastInFtqEntry_6),
    .io_toIbuffer_bits_isLastInFtqEntry_7                         (ifu_toIbuffer_bits_isLastInFtqEntry_7),
    .io_toIbuffer_bits_isLastInFtqEntry_8                         (ifu_toIbuffer_bits_isLastInFtqEntry_8),
    .io_toIbuffer_bits_isLastInFtqEntry_9                         (ifu_toIbuffer_bits_isLastInFtqEntry_9),
    .io_toIbuffer_bits_isLastInFtqEntry_10                        (ifu_toIbuffer_bits_isLastInFtqEntry_10),
    .io_toIbuffer_bits_isLastInFtqEntry_11                        (ifu_toIbuffer_bits_isLastInFtqEntry_11),
    .io_toIbuffer_bits_isLastInFtqEntry_12                        (ifu_toIbuffer_bits_isLastInFtqEntry_12),
    .io_toIbuffer_bits_isLastInFtqEntry_13                        (ifu_toIbuffer_bits_isLastInFtqEntry_13),
    .io_toIbuffer_bits_isLastInFtqEntry_14                        (ifu_toIbuffer_bits_isLastInFtqEntry_14),
    .io_toIbuffer_bits_isLastInFtqEntry_15                        (ifu_toIbuffer_bits_isLastInFtqEntry_15),
    .io_toIbuffer_bits_pc_0                                       (ifu_toIbuffer_bits_pc_0),
    .io_toIbuffer_bits_pc_1                                       (ifu_toIbuffer_bits_pc_1),
    .io_toIbuffer_bits_pc_2                                       (ifu_toIbuffer_bits_pc_2),
    .io_toIbuffer_bits_pc_3                                       (ifu_toIbuffer_bits_pc_3),
    .io_toIbuffer_bits_pc_4                                       (ifu_toIbuffer_bits_pc_4),
    .io_toIbuffer_bits_pc_5                                       (ifu_toIbuffer_bits_pc_5),
    .io_toIbuffer_bits_pc_6                                       (ifu_toIbuffer_bits_pc_6),
    .io_toIbuffer_bits_pc_7                                       (ifu_toIbuffer_bits_pc_7),
    .io_toIbuffer_bits_pc_8                                       (ifu_toIbuffer_bits_pc_8),
    .io_toIbuffer_bits_pc_9                                       (ifu_toIbuffer_bits_pc_9),
    .io_toIbuffer_bits_pc_10                                      (ifu_toIbuffer_bits_pc_10),
    .io_toIbuffer_bits_pc_11                                      (ifu_toIbuffer_bits_pc_11),
    .io_toIbuffer_bits_pc_12                                      (ifu_toIbuffer_bits_pc_12),
    .io_toIbuffer_bits_pc_13                                      (ifu_toIbuffer_bits_pc_13),
    .io_toIbuffer_bits_pc_14                                      (ifu_toIbuffer_bits_pc_14),
    .io_toIbuffer_bits_pc_15                                      (ifu_toIbuffer_bits_pc_15),
    .io_toIbuffer_bits_ftqPtr_flag                                (ifu_toIbuffer_bits_ftqPtr_flag),
    .io_toIbuffer_bits_ftqPtr_value                               (ifu_toIbuffer_bits_ftqPtr_value),
    .io_toIbuffer_bits_topdown_info_reasons_0                     (ifu_toIbuffer_bits_topdown_info_reasons_0),
    .io_toIbuffer_bits_topdown_info_reasons_1                     (ifu_toIbuffer_bits_topdown_info_reasons_1),
    .io_toIbuffer_bits_topdown_info_reasons_2                     (ifu_toIbuffer_bits_topdown_info_reasons_2),
    .io_toIbuffer_bits_topdown_info_reasons_3                     (ifu_toIbuffer_bits_topdown_info_reasons_3),
    .io_toIbuffer_bits_topdown_info_reasons_4                     (ifu_toIbuffer_bits_topdown_info_reasons_4),
    .io_toIbuffer_bits_topdown_info_reasons_5                     (ifu_toIbuffer_bits_topdown_info_reasons_5),
    .io_toIbuffer_bits_topdown_info_reasons_6                     (ifu_toIbuffer_bits_topdown_info_reasons_6),
    .io_toIbuffer_bits_topdown_info_reasons_7                     (ifu_toIbuffer_bits_topdown_info_reasons_7),
    .io_toIbuffer_bits_topdown_info_reasons_8                     (ifu_toIbuffer_bits_topdown_info_reasons_8),
    .io_toIbuffer_bits_topdown_info_reasons_9                     (ifu_toIbuffer_bits_topdown_info_reasons_9),
    .io_toIbuffer_bits_topdown_info_reasons_10                    (ifu_toIbuffer_bits_topdown_info_reasons_10),
    .io_toIbuffer_bits_topdown_info_reasons_11                    (ifu_toIbuffer_bits_topdown_info_reasons_11),
    .io_toIbuffer_bits_topdown_info_reasons_12                    (ifu_toIbuffer_bits_topdown_info_reasons_12),
    .io_toIbuffer_bits_topdown_info_reasons_13                    (ifu_toIbuffer_bits_topdown_info_reasons_13),
    .io_toIbuffer_bits_topdown_info_reasons_14                    (ifu_toIbuffer_bits_topdown_info_reasons_14),
    .io_toIbuffer_bits_topdown_info_reasons_15                    (ifu_toIbuffer_bits_topdown_info_reasons_15),
    .io_toIbuffer_bits_topdown_info_reasons_16                    (ifu_toIbuffer_bits_topdown_info_reasons_16),
    .io_toIbuffer_bits_topdown_info_reasons_17                    (ifu_toIbuffer_bits_topdown_info_reasons_17),
    .io_toIbuffer_bits_topdown_info_reasons_18                    (ifu_toIbuffer_bits_topdown_info_reasons_18),
    .io_toIbuffer_bits_topdown_info_reasons_19                    (ifu_toIbuffer_bits_topdown_info_reasons_19),
    .io_toIbuffer_bits_topdown_info_reasons_20                    (ifu_toIbuffer_bits_topdown_info_reasons_20),
    .io_toIbuffer_bits_topdown_info_reasons_21                    (ifu_toIbuffer_bits_topdown_info_reasons_21),
    .io_toIbuffer_bits_topdown_info_reasons_22                    (ifu_toIbuffer_bits_topdown_info_reasons_22),
    .io_toIbuffer_bits_topdown_info_reasons_23                    (ifu_toIbuffer_bits_topdown_info_reasons_23),
    .io_toIbuffer_bits_topdown_info_reasons_24                    (ifu_toIbuffer_bits_topdown_info_reasons_24),
    .io_toIbuffer_bits_topdown_info_reasons_25                    (ifu_toIbuffer_bits_topdown_info_reasons_25),
    .io_toIbuffer_bits_topdown_info_reasons_26                    (ifu_toIbuffer_bits_topdown_info_reasons_26),
    .io_toIbuffer_bits_topdown_info_reasons_27                    (ifu_toIbuffer_bits_topdown_info_reasons_27),
    .io_toIbuffer_bits_topdown_info_reasons_28                    (ifu_toIbuffer_bits_topdown_info_reasons_28),
    .io_toIbuffer_bits_topdown_info_reasons_29                    (ifu_toIbuffer_bits_topdown_info_reasons_29),
    .io_toIbuffer_bits_topdown_info_reasons_30                    (ifu_toIbuffer_bits_topdown_info_reasons_30),
    .io_toIbuffer_bits_topdown_info_reasons_31                    (ifu_toIbuffer_bits_topdown_info_reasons_31),
    .io_toIbuffer_bits_topdown_info_reasons_32                    (ifu_toIbuffer_bits_topdown_info_reasons_32),
    .io_toIbuffer_bits_topdown_info_reasons_33                    (ifu_toIbuffer_bits_topdown_info_reasons_33),
    .io_toIbuffer_bits_topdown_info_reasons_34                    (ifu_toIbuffer_bits_topdown_info_reasons_34),
    .io_toIbuffer_bits_topdown_info_reasons_35                    (ifu_toIbuffer_bits_topdown_info_reasons_35),
    .io_toIbuffer_bits_topdown_info_reasons_36                    (ifu_toIbuffer_bits_topdown_info_reasons_36),
    .io_toIbuffer_bits_topdown_info_reasons_37                    (ifu_toIbuffer_bits_topdown_info_reasons_37),
    // ---- 顶层 io_backend_fromIfu* —— IFU 写给后端的 gpaddr 存储 ----
    .io_toBackend_gpaddrMem_wen                                   (io_backend_fromIfu_gpaddrMem_wen),
    .io_toBackend_gpaddrMem_waddr                                 (io_backend_fromIfu_gpaddrMem_waddr),
    .io_toBackend_gpaddrMem_wdata_gpaddr                          (io_backend_fromIfu_gpaddrMem_wdata_gpaddr),
    .io_toBackend_gpaddrMem_wdata_isForVSnonLeafPTE               (io_backend_fromIfu_gpaddrMem_wdata_isForVSnonLeafPTE),
    // ---- ← instrUncache：IFU 的 MMIO 取指请求 / 回应 ----
    .io_uncacheInter_fromUncache_valid                            (instrUncache_resp_valid),
    .io_uncacheInter_fromUncache_bits_data                        (instrUncache_resp_bits_data),
    .io_uncacheInter_fromUncache_bits_corrupt                     (instrUncache_resp_bits_corrupt),
    .io_uncacheInter_toUncache_ready                              (instrUncache_req_ready),
    // ---- → instrUncache（IFU 的 MMIO 取指请求 / 回应） ----
    .io_uncacheInter_toUncache_valid                              (ifu_uncacheInter_toUncache_valid),
    .io_uncacheInter_toUncache_bits_addr                          (ifu_uncacheInter_toUncache_bits_addr),
    .io_uncacheInter_toUncache_bits_memBackTypeMM                 (ifu_uncacheInter_toUncache_bits_memBackTypeMM),
    .io_uncacheInter_toUncache_bits_memPageTypeNC                 (ifu_uncacheInter_toUncache_bits_memPageTypeNC),
    .io_uncacheInter_toUncache_bits_flush                         (ifu_uncacheInter_toUncache_bits_flush),
    // ---- ← csrCtrlDelay：前端断点触发器配置与 fsIsOff（CSR 打两拍后） ----
    .io_frontendTrigger_tUpdate_valid                             (csrCtrlDelay_out_frontend_trigger_tUpdate_valid),
    .io_frontendTrigger_tUpdate_bits_addr                         (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_addr),
    .io_frontendTrigger_tUpdate_bits_tdata_matchType              (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_matchType),
    .io_frontendTrigger_tUpdate_bits_tdata_select                 (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_select),
    .io_frontendTrigger_tUpdate_bits_tdata_action                 (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_action),
    .io_frontendTrigger_tUpdate_bits_tdata_chain                  (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_chain),
    .io_frontendTrigger_tUpdate_bits_tdata_tdata2                 (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_tdata2),
    .io_frontendTrigger_tEnableVec_0                              (csrCtrlDelay_out_frontend_trigger_tEnableVec_0),
    .io_frontendTrigger_tEnableVec_1                              (csrCtrlDelay_out_frontend_trigger_tEnableVec_1),
    .io_frontendTrigger_tEnableVec_2                              (csrCtrlDelay_out_frontend_trigger_tEnableVec_2),
    .io_frontendTrigger_tEnableVec_3                              (csrCtrlDelay_out_frontend_trigger_tEnableVec_3),
    .io_frontendTrigger_debugMode                                 (csrCtrlDelay_out_frontend_trigger_debugMode),
    .io_frontendTrigger_triggerCanRaiseBpExp                      (csrCtrlDelay_out_frontend_trigger_triggerCanRaiseBpExp),
    .io_csr_fsIsOff                                               (csrCtrlDelay_out_fsIsOff),
    // ---- 顶层 io_backend_toFtq* —— 后端提交 / 重定向回送 FTQ ----
    .io_rob_commits_0_valid                                       (io_backend_toFtq_rob_commits_0_valid),
    .io_rob_commits_0_bits_ftqIdx_flag                            (io_backend_toFtq_rob_commits_0_bits_ftqIdx_flag),
    .io_rob_commits_0_bits_ftqIdx_value                           (io_backend_toFtq_rob_commits_0_bits_ftqIdx_value),
    .io_rob_commits_0_bits_ftqOffset                              (io_backend_toFtq_rob_commits_0_bits_ftqOffset),
    .io_rob_commits_1_valid                                       (io_backend_toFtq_rob_commits_1_valid),
    .io_rob_commits_1_bits_ftqIdx_flag                            (io_backend_toFtq_rob_commits_1_bits_ftqIdx_flag),
    .io_rob_commits_1_bits_ftqIdx_value                           (io_backend_toFtq_rob_commits_1_bits_ftqIdx_value),
    .io_rob_commits_1_bits_ftqOffset                              (io_backend_toFtq_rob_commits_1_bits_ftqOffset),
    .io_rob_commits_2_valid                                       (io_backend_toFtq_rob_commits_2_valid),
    .io_rob_commits_2_bits_ftqIdx_flag                            (io_backend_toFtq_rob_commits_2_bits_ftqIdx_flag),
    .io_rob_commits_2_bits_ftqIdx_value                           (io_backend_toFtq_rob_commits_2_bits_ftqIdx_value),
    .io_rob_commits_2_bits_ftqOffset                              (io_backend_toFtq_rob_commits_2_bits_ftqOffset),
    .io_rob_commits_3_valid                                       (io_backend_toFtq_rob_commits_3_valid),
    .io_rob_commits_3_bits_ftqIdx_flag                            (io_backend_toFtq_rob_commits_3_bits_ftqIdx_flag),
    .io_rob_commits_3_bits_ftqIdx_value                           (io_backend_toFtq_rob_commits_3_bits_ftqIdx_value),
    .io_rob_commits_3_bits_ftqOffset                              (io_backend_toFtq_rob_commits_3_bits_ftqOffset),
    .io_rob_commits_4_valid                                       (io_backend_toFtq_rob_commits_4_valid),
    .io_rob_commits_4_bits_ftqIdx_flag                            (io_backend_toFtq_rob_commits_4_bits_ftqIdx_flag),
    .io_rob_commits_4_bits_ftqIdx_value                           (io_backend_toFtq_rob_commits_4_bits_ftqIdx_value),
    .io_rob_commits_4_bits_ftqOffset                              (io_backend_toFtq_rob_commits_4_bits_ftqOffset),
    .io_rob_commits_5_valid                                       (io_backend_toFtq_rob_commits_5_valid),
    .io_rob_commits_5_bits_ftqIdx_flag                            (io_backend_toFtq_rob_commits_5_bits_ftqIdx_flag),
    .io_rob_commits_5_bits_ftqIdx_value                           (io_backend_toFtq_rob_commits_5_bits_ftqIdx_value),
    .io_rob_commits_5_bits_ftqOffset                              (io_backend_toFtq_rob_commits_5_bits_ftqOffset),
    .io_rob_commits_6_valid                                       (io_backend_toFtq_rob_commits_6_valid),
    .io_rob_commits_6_bits_ftqIdx_flag                            (io_backend_toFtq_rob_commits_6_bits_ftqIdx_flag),
    .io_rob_commits_6_bits_ftqIdx_value                           (io_backend_toFtq_rob_commits_6_bits_ftqIdx_value),
    .io_rob_commits_6_bits_ftqOffset                              (io_backend_toFtq_rob_commits_6_bits_ftqOffset),
    .io_rob_commits_7_valid                                       (io_backend_toFtq_rob_commits_7_valid),
    .io_rob_commits_7_bits_ftqIdx_flag                            (io_backend_toFtq_rob_commits_7_bits_ftqIdx_flag),
    .io_rob_commits_7_bits_ftqIdx_value                           (io_backend_toFtq_rob_commits_7_bits_ftqIdx_value),
    .io_rob_commits_7_bits_ftqOffset                              (io_backend_toFtq_rob_commits_7_bits_ftqOffset),
    // ---- ← itlb：IFU 的 MMIO 取指重新翻译口（ITLB 第 3 口，阻塞式） ----
    .io_iTLBInter_req_ready                                       (itlb_requestor_2_req_ready),
    .io_iTLBInter_resp_valid                                      (itlb_requestor_2_resp_valid),
    .io_iTLBInter_resp_bits_paddr_0                               (itlb_requestor_2_resp_bits_paddr_0),
    .io_iTLBInter_resp_bits_gpaddr_0                              (itlb_requestor_2_resp_bits_gpaddr_0),
    .io_iTLBInter_resp_bits_pbmt_0                                (itlb_requestor_2_resp_bits_pbmt_0),
    .io_iTLBInter_resp_bits_miss                                  (itlb_requestor_2_resp_bits_miss),
    .io_iTLBInter_resp_bits_isForVSnonLeafPTE                     (itlb_requestor_2_resp_bits_isForVSnonLeafPTE),
    .io_iTLBInter_resp_bits_excp_0_gpf_instr                      (itlb_requestor_2_resp_bits_excp_0_gpf_instr),
    .io_iTLBInter_resp_bits_excp_0_pf_instr                       (itlb_requestor_2_resp_bits_excp_0_pf_instr),
    .io_iTLBInter_resp_bits_excp_0_af_instr                       (itlb_requestor_2_resp_bits_excp_0_af_instr),
    // ---- → itlb（IFU 的 MMIO 取指重新翻译口（ITLB 第 3 口，阻塞式）） ----
    .io_iTLBInter_req_valid                                       (ifu_iTLBInter_req_valid),
    .io_iTLBInter_req_bits_vaddr                                  (ifu_iTLBInter_req_bits_vaddr),
    .io_iTLBInter_resp_ready                                      (ifu_iTLBInter_resp_ready),
    // ---- → pmpCheck4（IFU（MMIO 取指）的物理地址权限检查口） ----
    .io_pmp_req_valid                                             (ifu_pmp_req_valid),
    .io_pmp_req_bits_addr                                         (ifu_pmp_req_bits_addr),
    // ---- ← pmpCheck4：IFU（MMIO 取指）的物理地址权限检查口 ----
    .io_pmp_resp_instr                                            (pmpCheck4_resp_instr),
    .io_pmp_resp_mmio                                             (pmpCheck4_resp_mmio),
    // ---- → perfHpm（IFU 性能事件） ----
    .io_perf_0_value                                              (ifu_perf_0_value),
    .io_perf_1_value                                              (ifu_perf_1_value),
    .io_perf_2_value                                              (ifu_perf_2_value),
    .io_perf_3_value                                              (ifu_perf_3_value),
    .io_perf_4_value                                              (ifu_perf_4_value),
    .io_perf_5_value                                              (ifu_perf_5_value),
    .io_perf_6_value                                              (ifu_perf_6_value),
    .io_perf_7_value                                              (ifu_perf_7_value),
    .io_perf_8_value                                              (ifu_perf_8_value),
    .io_perf_9_value                                              (ifu_perf_9_value),
    .io_perf_10_value                                             (ifu_perf_10_value),
    .io_perf_11_value                                             (ifu_perf_11_value),
    .io_perf_12_value                                             (ifu_perf_12_value)
  );
  IBuffer inner_ibuffer (
    // ---- 时钟 / 复位 ----
    .clock                                  (clock),
    .reset                                  (reset),
    // ---- ← u_core：后端重定向冲刷与原因标志（打一拍）；出口 6 条指令供自检 ----
    .io_flush                               (redirect_flush),
    .io_ControlRedirect                     (redirect_from_ctrl),
    .io_MemVioRedirect                      (redirect_from_memvio),
    // ---- ← ftq：FTQ 统计的各类重定向气泡（TopDown 用）给 IBuffer ----
    .io_ControlBTBMissBubble                (ftq_ControlBTBMissBubble),
    .io_TAGEMissBubble                      (ftq_TAGEMissBubble),
    .io_SCMissBubble                        (ftq_SCMissBubble),
    .io_ITTAGEMissBubble                    (ftq_ITTAGEMissBubble),
    .io_RASMissBubble                       (ftq_RASMissBubble),
    // ---- → ifu（IFU 把预译码后的取指块写进 IBuffer） ----
    .io_in_ready                            (ibuffer_in_ready),
    // ---- ← ifu：IFU 把预译码后的取指块写进 IBuffer ----
    .io_in_valid                            (ifu_toIbuffer_valid),
    .io_in_bits_instrs_0                    (ifu_toIbuffer_bits_instrs_0),
    .io_in_bits_instrs_1                    (ifu_toIbuffer_bits_instrs_1),
    .io_in_bits_instrs_2                    (ifu_toIbuffer_bits_instrs_2),
    .io_in_bits_instrs_3                    (ifu_toIbuffer_bits_instrs_3),
    .io_in_bits_instrs_4                    (ifu_toIbuffer_bits_instrs_4),
    .io_in_bits_instrs_5                    (ifu_toIbuffer_bits_instrs_5),
    .io_in_bits_instrs_6                    (ifu_toIbuffer_bits_instrs_6),
    .io_in_bits_instrs_7                    (ifu_toIbuffer_bits_instrs_7),
    .io_in_bits_instrs_8                    (ifu_toIbuffer_bits_instrs_8),
    .io_in_bits_instrs_9                    (ifu_toIbuffer_bits_instrs_9),
    .io_in_bits_instrs_10                   (ifu_toIbuffer_bits_instrs_10),
    .io_in_bits_instrs_11                   (ifu_toIbuffer_bits_instrs_11),
    .io_in_bits_instrs_12                   (ifu_toIbuffer_bits_instrs_12),
    .io_in_bits_instrs_13                   (ifu_toIbuffer_bits_instrs_13),
    .io_in_bits_instrs_14                   (ifu_toIbuffer_bits_instrs_14),
    .io_in_bits_instrs_15                   (ifu_toIbuffer_bits_instrs_15),
    .io_in_bits_valid                       (ifu_toIbuffer_bits_valid),
    .io_in_bits_enqEnable                   (ifu_toIbuffer_bits_enqEnable),
    .io_in_bits_pd_0_isRVC                  (ifu_toIbuffer_bits_pd_0_isRVC),
    .io_in_bits_pd_0_brType                 (ifu_toIbuffer_bits_pd_0_brType),
    .io_in_bits_pd_0_isCall                 (ifu_toIbuffer_bits_pd_0_isCall),
    .io_in_bits_pd_0_isRet                  (ifu_toIbuffer_bits_pd_0_isRet),
    .io_in_bits_pd_1_valid                  (ifu_toIbuffer_bits_pd_1_valid),
    .io_in_bits_pd_1_isRVC                  (ifu_toIbuffer_bits_pd_1_isRVC),
    .io_in_bits_pd_1_brType                 (ifu_toIbuffer_bits_pd_1_brType),
    .io_in_bits_pd_1_isCall                 (ifu_toIbuffer_bits_pd_1_isCall),
    .io_in_bits_pd_1_isRet                  (ifu_toIbuffer_bits_pd_1_isRet),
    .io_in_bits_pd_2_valid                  (ifu_toIbuffer_bits_pd_2_valid),
    .io_in_bits_pd_2_isRVC                  (ifu_toIbuffer_bits_pd_2_isRVC),
    .io_in_bits_pd_2_brType                 (ifu_toIbuffer_bits_pd_2_brType),
    .io_in_bits_pd_2_isCall                 (ifu_toIbuffer_bits_pd_2_isCall),
    .io_in_bits_pd_2_isRet                  (ifu_toIbuffer_bits_pd_2_isRet),
    .io_in_bits_pd_3_valid                  (ifu_toIbuffer_bits_pd_3_valid),
    .io_in_bits_pd_3_isRVC                  (ifu_toIbuffer_bits_pd_3_isRVC),
    .io_in_bits_pd_3_brType                 (ifu_toIbuffer_bits_pd_3_brType),
    .io_in_bits_pd_3_isCall                 (ifu_toIbuffer_bits_pd_3_isCall),
    .io_in_bits_pd_3_isRet                  (ifu_toIbuffer_bits_pd_3_isRet),
    .io_in_bits_pd_4_valid                  (ifu_toIbuffer_bits_pd_4_valid),
    .io_in_bits_pd_4_isRVC                  (ifu_toIbuffer_bits_pd_4_isRVC),
    .io_in_bits_pd_4_brType                 (ifu_toIbuffer_bits_pd_4_brType),
    .io_in_bits_pd_4_isCall                 (ifu_toIbuffer_bits_pd_4_isCall),
    .io_in_bits_pd_4_isRet                  (ifu_toIbuffer_bits_pd_4_isRet),
    .io_in_bits_pd_5_valid                  (ifu_toIbuffer_bits_pd_5_valid),
    .io_in_bits_pd_5_isRVC                  (ifu_toIbuffer_bits_pd_5_isRVC),
    .io_in_bits_pd_5_brType                 (ifu_toIbuffer_bits_pd_5_brType),
    .io_in_bits_pd_5_isCall                 (ifu_toIbuffer_bits_pd_5_isCall),
    .io_in_bits_pd_5_isRet                  (ifu_toIbuffer_bits_pd_5_isRet),
    .io_in_bits_pd_6_valid                  (ifu_toIbuffer_bits_pd_6_valid),
    .io_in_bits_pd_6_isRVC                  (ifu_toIbuffer_bits_pd_6_isRVC),
    .io_in_bits_pd_6_brType                 (ifu_toIbuffer_bits_pd_6_brType),
    .io_in_bits_pd_6_isCall                 (ifu_toIbuffer_bits_pd_6_isCall),
    .io_in_bits_pd_6_isRet                  (ifu_toIbuffer_bits_pd_6_isRet),
    .io_in_bits_pd_7_valid                  (ifu_toIbuffer_bits_pd_7_valid),
    .io_in_bits_pd_7_isRVC                  (ifu_toIbuffer_bits_pd_7_isRVC),
    .io_in_bits_pd_7_brType                 (ifu_toIbuffer_bits_pd_7_brType),
    .io_in_bits_pd_7_isCall                 (ifu_toIbuffer_bits_pd_7_isCall),
    .io_in_bits_pd_7_isRet                  (ifu_toIbuffer_bits_pd_7_isRet),
    .io_in_bits_pd_8_valid                  (ifu_toIbuffer_bits_pd_8_valid),
    .io_in_bits_pd_8_isRVC                  (ifu_toIbuffer_bits_pd_8_isRVC),
    .io_in_bits_pd_8_brType                 (ifu_toIbuffer_bits_pd_8_brType),
    .io_in_bits_pd_8_isCall                 (ifu_toIbuffer_bits_pd_8_isCall),
    .io_in_bits_pd_8_isRet                  (ifu_toIbuffer_bits_pd_8_isRet),
    .io_in_bits_pd_9_valid                  (ifu_toIbuffer_bits_pd_9_valid),
    .io_in_bits_pd_9_isRVC                  (ifu_toIbuffer_bits_pd_9_isRVC),
    .io_in_bits_pd_9_brType                 (ifu_toIbuffer_bits_pd_9_brType),
    .io_in_bits_pd_9_isCall                 (ifu_toIbuffer_bits_pd_9_isCall),
    .io_in_bits_pd_9_isRet                  (ifu_toIbuffer_bits_pd_9_isRet),
    .io_in_bits_pd_10_valid                 (ifu_toIbuffer_bits_pd_10_valid),
    .io_in_bits_pd_10_isRVC                 (ifu_toIbuffer_bits_pd_10_isRVC),
    .io_in_bits_pd_10_brType                (ifu_toIbuffer_bits_pd_10_brType),
    .io_in_bits_pd_10_isCall                (ifu_toIbuffer_bits_pd_10_isCall),
    .io_in_bits_pd_10_isRet                 (ifu_toIbuffer_bits_pd_10_isRet),
    .io_in_bits_pd_11_valid                 (ifu_toIbuffer_bits_pd_11_valid),
    .io_in_bits_pd_11_isRVC                 (ifu_toIbuffer_bits_pd_11_isRVC),
    .io_in_bits_pd_11_brType                (ifu_toIbuffer_bits_pd_11_brType),
    .io_in_bits_pd_11_isCall                (ifu_toIbuffer_bits_pd_11_isCall),
    .io_in_bits_pd_11_isRet                 (ifu_toIbuffer_bits_pd_11_isRet),
    .io_in_bits_pd_12_valid                 (ifu_toIbuffer_bits_pd_12_valid),
    .io_in_bits_pd_12_isRVC                 (ifu_toIbuffer_bits_pd_12_isRVC),
    .io_in_bits_pd_12_brType                (ifu_toIbuffer_bits_pd_12_brType),
    .io_in_bits_pd_12_isCall                (ifu_toIbuffer_bits_pd_12_isCall),
    .io_in_bits_pd_12_isRet                 (ifu_toIbuffer_bits_pd_12_isRet),
    .io_in_bits_pd_13_valid                 (ifu_toIbuffer_bits_pd_13_valid),
    .io_in_bits_pd_13_isRVC                 (ifu_toIbuffer_bits_pd_13_isRVC),
    .io_in_bits_pd_13_brType                (ifu_toIbuffer_bits_pd_13_brType),
    .io_in_bits_pd_13_isCall                (ifu_toIbuffer_bits_pd_13_isCall),
    .io_in_bits_pd_13_isRet                 (ifu_toIbuffer_bits_pd_13_isRet),
    .io_in_bits_pd_14_valid                 (ifu_toIbuffer_bits_pd_14_valid),
    .io_in_bits_pd_14_isRVC                 (ifu_toIbuffer_bits_pd_14_isRVC),
    .io_in_bits_pd_14_brType                (ifu_toIbuffer_bits_pd_14_brType),
    .io_in_bits_pd_14_isCall                (ifu_toIbuffer_bits_pd_14_isCall),
    .io_in_bits_pd_14_isRet                 (ifu_toIbuffer_bits_pd_14_isRet),
    .io_in_bits_pd_15_valid                 (ifu_toIbuffer_bits_pd_15_valid),
    .io_in_bits_pd_15_isRVC                 (ifu_toIbuffer_bits_pd_15_isRVC),
    .io_in_bits_pd_15_brType                (ifu_toIbuffer_bits_pd_15_brType),
    .io_in_bits_pd_15_isCall                (ifu_toIbuffer_bits_pd_15_isCall),
    .io_in_bits_pd_15_isRet                 (ifu_toIbuffer_bits_pd_15_isRet),
    .io_in_bits_foldpc_0                    (ifu_toIbuffer_bits_foldpc_0),
    .io_in_bits_foldpc_1                    (ifu_toIbuffer_bits_foldpc_1),
    .io_in_bits_foldpc_2                    (ifu_toIbuffer_bits_foldpc_2),
    .io_in_bits_foldpc_3                    (ifu_toIbuffer_bits_foldpc_3),
    .io_in_bits_foldpc_4                    (ifu_toIbuffer_bits_foldpc_4),
    .io_in_bits_foldpc_5                    (ifu_toIbuffer_bits_foldpc_5),
    .io_in_bits_foldpc_6                    (ifu_toIbuffer_bits_foldpc_6),
    .io_in_bits_foldpc_7                    (ifu_toIbuffer_bits_foldpc_7),
    .io_in_bits_foldpc_8                    (ifu_toIbuffer_bits_foldpc_8),
    .io_in_bits_foldpc_9                    (ifu_toIbuffer_bits_foldpc_9),
    .io_in_bits_foldpc_10                   (ifu_toIbuffer_bits_foldpc_10),
    .io_in_bits_foldpc_11                   (ifu_toIbuffer_bits_foldpc_11),
    .io_in_bits_foldpc_12                   (ifu_toIbuffer_bits_foldpc_12),
    .io_in_bits_foldpc_13                   (ifu_toIbuffer_bits_foldpc_13),
    .io_in_bits_foldpc_14                   (ifu_toIbuffer_bits_foldpc_14),
    .io_in_bits_foldpc_15                   (ifu_toIbuffer_bits_foldpc_15),
    .io_in_bits_ftqOffset_0_valid           (ifu_toIbuffer_bits_ftqOffset_0_valid),
    .io_in_bits_ftqOffset_1_valid           (ifu_toIbuffer_bits_ftqOffset_1_valid),
    .io_in_bits_ftqOffset_2_valid           (ifu_toIbuffer_bits_ftqOffset_2_valid),
    .io_in_bits_ftqOffset_3_valid           (ifu_toIbuffer_bits_ftqOffset_3_valid),
    .io_in_bits_ftqOffset_4_valid           (ifu_toIbuffer_bits_ftqOffset_4_valid),
    .io_in_bits_ftqOffset_5_valid           (ifu_toIbuffer_bits_ftqOffset_5_valid),
    .io_in_bits_ftqOffset_6_valid           (ifu_toIbuffer_bits_ftqOffset_6_valid),
    .io_in_bits_ftqOffset_7_valid           (ifu_toIbuffer_bits_ftqOffset_7_valid),
    .io_in_bits_ftqOffset_8_valid           (ifu_toIbuffer_bits_ftqOffset_8_valid),
    .io_in_bits_ftqOffset_9_valid           (ifu_toIbuffer_bits_ftqOffset_9_valid),
    .io_in_bits_ftqOffset_10_valid          (ifu_toIbuffer_bits_ftqOffset_10_valid),
    .io_in_bits_ftqOffset_11_valid          (ifu_toIbuffer_bits_ftqOffset_11_valid),
    .io_in_bits_ftqOffset_12_valid          (ifu_toIbuffer_bits_ftqOffset_12_valid),
    .io_in_bits_ftqOffset_13_valid          (ifu_toIbuffer_bits_ftqOffset_13_valid),
    .io_in_bits_ftqOffset_14_valid          (ifu_toIbuffer_bits_ftqOffset_14_valid),
    .io_in_bits_ftqOffset_15_valid          (ifu_toIbuffer_bits_ftqOffset_15_valid),
    .io_in_bits_backendException_0          (ifu_toIbuffer_bits_backendException_0),
    .io_in_bits_satpFlushFirstFetchFault_0  (ifu_toIbuffer_bits_satpFlushFirstFetchFault_0),
    .io_in_bits_exceptionType_0             (ifu_toIbuffer_bits_exceptionType_0),
    .io_in_bits_exceptionType_1             (ifu_toIbuffer_bits_exceptionType_1),
    .io_in_bits_exceptionType_2             (ifu_toIbuffer_bits_exceptionType_2),
    .io_in_bits_exceptionType_3             (ifu_toIbuffer_bits_exceptionType_3),
    .io_in_bits_exceptionType_4             (ifu_toIbuffer_bits_exceptionType_4),
    .io_in_bits_exceptionType_5             (ifu_toIbuffer_bits_exceptionType_5),
    .io_in_bits_exceptionType_6             (ifu_toIbuffer_bits_exceptionType_6),
    .io_in_bits_exceptionType_7             (ifu_toIbuffer_bits_exceptionType_7),
    .io_in_bits_exceptionType_8             (ifu_toIbuffer_bits_exceptionType_8),
    .io_in_bits_exceptionType_9             (ifu_toIbuffer_bits_exceptionType_9),
    .io_in_bits_exceptionType_10            (ifu_toIbuffer_bits_exceptionType_10),
    .io_in_bits_exceptionType_11            (ifu_toIbuffer_bits_exceptionType_11),
    .io_in_bits_exceptionType_12            (ifu_toIbuffer_bits_exceptionType_12),
    .io_in_bits_exceptionType_13            (ifu_toIbuffer_bits_exceptionType_13),
    .io_in_bits_exceptionType_14            (ifu_toIbuffer_bits_exceptionType_14),
    .io_in_bits_exceptionType_15            (ifu_toIbuffer_bits_exceptionType_15),
    .io_in_bits_crossPageIPFFix_0           (ifu_toIbuffer_bits_crossPageIPFFix_0),
    .io_in_bits_crossPageIPFFix_1           (ifu_toIbuffer_bits_crossPageIPFFix_1),
    .io_in_bits_crossPageIPFFix_2           (ifu_toIbuffer_bits_crossPageIPFFix_2),
    .io_in_bits_crossPageIPFFix_3           (ifu_toIbuffer_bits_crossPageIPFFix_3),
    .io_in_bits_crossPageIPFFix_4           (ifu_toIbuffer_bits_crossPageIPFFix_4),
    .io_in_bits_crossPageIPFFix_5           (ifu_toIbuffer_bits_crossPageIPFFix_5),
    .io_in_bits_crossPageIPFFix_6           (ifu_toIbuffer_bits_crossPageIPFFix_6),
    .io_in_bits_crossPageIPFFix_7           (ifu_toIbuffer_bits_crossPageIPFFix_7),
    .io_in_bits_crossPageIPFFix_8           (ifu_toIbuffer_bits_crossPageIPFFix_8),
    .io_in_bits_crossPageIPFFix_9           (ifu_toIbuffer_bits_crossPageIPFFix_9),
    .io_in_bits_crossPageIPFFix_10          (ifu_toIbuffer_bits_crossPageIPFFix_10),
    .io_in_bits_crossPageIPFFix_11          (ifu_toIbuffer_bits_crossPageIPFFix_11),
    .io_in_bits_crossPageIPFFix_12          (ifu_toIbuffer_bits_crossPageIPFFix_12),
    .io_in_bits_crossPageIPFFix_13          (ifu_toIbuffer_bits_crossPageIPFFix_13),
    .io_in_bits_crossPageIPFFix_14          (ifu_toIbuffer_bits_crossPageIPFFix_14),
    .io_in_bits_crossPageIPFFix_15          (ifu_toIbuffer_bits_crossPageIPFFix_15),
    .io_in_bits_illegalInstr_0              (ifu_toIbuffer_bits_illegalInstr_0),
    .io_in_bits_illegalInstr_1              (ifu_toIbuffer_bits_illegalInstr_1),
    .io_in_bits_illegalInstr_2              (ifu_toIbuffer_bits_illegalInstr_2),
    .io_in_bits_illegalInstr_3              (ifu_toIbuffer_bits_illegalInstr_3),
    .io_in_bits_illegalInstr_4              (ifu_toIbuffer_bits_illegalInstr_4),
    .io_in_bits_illegalInstr_5              (ifu_toIbuffer_bits_illegalInstr_5),
    .io_in_bits_illegalInstr_6              (ifu_toIbuffer_bits_illegalInstr_6),
    .io_in_bits_illegalInstr_7              (ifu_toIbuffer_bits_illegalInstr_7),
    .io_in_bits_illegalInstr_8              (ifu_toIbuffer_bits_illegalInstr_8),
    .io_in_bits_illegalInstr_9              (ifu_toIbuffer_bits_illegalInstr_9),
    .io_in_bits_illegalInstr_10             (ifu_toIbuffer_bits_illegalInstr_10),
    .io_in_bits_illegalInstr_11             (ifu_toIbuffer_bits_illegalInstr_11),
    .io_in_bits_illegalInstr_12             (ifu_toIbuffer_bits_illegalInstr_12),
    .io_in_bits_illegalInstr_13             (ifu_toIbuffer_bits_illegalInstr_13),
    .io_in_bits_illegalInstr_14             (ifu_toIbuffer_bits_illegalInstr_14),
    .io_in_bits_illegalInstr_15             (ifu_toIbuffer_bits_illegalInstr_15),
    .io_in_bits_triggered_0                 (ifu_toIbuffer_bits_triggered_0),
    .io_in_bits_triggered_1                 (ifu_toIbuffer_bits_triggered_1),
    .io_in_bits_triggered_2                 (ifu_toIbuffer_bits_triggered_2),
    .io_in_bits_triggered_3                 (ifu_toIbuffer_bits_triggered_3),
    .io_in_bits_triggered_4                 (ifu_toIbuffer_bits_triggered_4),
    .io_in_bits_triggered_5                 (ifu_toIbuffer_bits_triggered_5),
    .io_in_bits_triggered_6                 (ifu_toIbuffer_bits_triggered_6),
    .io_in_bits_triggered_7                 (ifu_toIbuffer_bits_triggered_7),
    .io_in_bits_triggered_8                 (ifu_toIbuffer_bits_triggered_8),
    .io_in_bits_triggered_9                 (ifu_toIbuffer_bits_triggered_9),
    .io_in_bits_triggered_10                (ifu_toIbuffer_bits_triggered_10),
    .io_in_bits_triggered_11                (ifu_toIbuffer_bits_triggered_11),
    .io_in_bits_triggered_12                (ifu_toIbuffer_bits_triggered_12),
    .io_in_bits_triggered_13                (ifu_toIbuffer_bits_triggered_13),
    .io_in_bits_triggered_14                (ifu_toIbuffer_bits_triggered_14),
    .io_in_bits_triggered_15                (ifu_toIbuffer_bits_triggered_15),
    .io_in_bits_isLastInFtqEntry_0          (ifu_toIbuffer_bits_isLastInFtqEntry_0),
    .io_in_bits_isLastInFtqEntry_1          (ifu_toIbuffer_bits_isLastInFtqEntry_1),
    .io_in_bits_isLastInFtqEntry_2          (ifu_toIbuffer_bits_isLastInFtqEntry_2),
    .io_in_bits_isLastInFtqEntry_3          (ifu_toIbuffer_bits_isLastInFtqEntry_3),
    .io_in_bits_isLastInFtqEntry_4          (ifu_toIbuffer_bits_isLastInFtqEntry_4),
    .io_in_bits_isLastInFtqEntry_5          (ifu_toIbuffer_bits_isLastInFtqEntry_5),
    .io_in_bits_isLastInFtqEntry_6          (ifu_toIbuffer_bits_isLastInFtqEntry_6),
    .io_in_bits_isLastInFtqEntry_7          (ifu_toIbuffer_bits_isLastInFtqEntry_7),
    .io_in_bits_isLastInFtqEntry_8          (ifu_toIbuffer_bits_isLastInFtqEntry_8),
    .io_in_bits_isLastInFtqEntry_9          (ifu_toIbuffer_bits_isLastInFtqEntry_9),
    .io_in_bits_isLastInFtqEntry_10         (ifu_toIbuffer_bits_isLastInFtqEntry_10),
    .io_in_bits_isLastInFtqEntry_11         (ifu_toIbuffer_bits_isLastInFtqEntry_11),
    .io_in_bits_isLastInFtqEntry_12         (ifu_toIbuffer_bits_isLastInFtqEntry_12),
    .io_in_bits_isLastInFtqEntry_13         (ifu_toIbuffer_bits_isLastInFtqEntry_13),
    .io_in_bits_isLastInFtqEntry_14         (ifu_toIbuffer_bits_isLastInFtqEntry_14),
    .io_in_bits_isLastInFtqEntry_15         (ifu_toIbuffer_bits_isLastInFtqEntry_15),
    .io_in_bits_pc_0                        (ifu_toIbuffer_bits_pc_0),
    .io_in_bits_pc_1                        (ifu_toIbuffer_bits_pc_1),
    .io_in_bits_pc_2                        (ifu_toIbuffer_bits_pc_2),
    .io_in_bits_pc_3                        (ifu_toIbuffer_bits_pc_3),
    .io_in_bits_pc_4                        (ifu_toIbuffer_bits_pc_4),
    .io_in_bits_pc_5                        (ifu_toIbuffer_bits_pc_5),
    .io_in_bits_pc_6                        (ifu_toIbuffer_bits_pc_6),
    .io_in_bits_pc_7                        (ifu_toIbuffer_bits_pc_7),
    .io_in_bits_pc_8                        (ifu_toIbuffer_bits_pc_8),
    .io_in_bits_pc_9                        (ifu_toIbuffer_bits_pc_9),
    .io_in_bits_pc_10                       (ifu_toIbuffer_bits_pc_10),
    .io_in_bits_pc_11                       (ifu_toIbuffer_bits_pc_11),
    .io_in_bits_pc_12                       (ifu_toIbuffer_bits_pc_12),
    .io_in_bits_pc_13                       (ifu_toIbuffer_bits_pc_13),
    .io_in_bits_pc_14                       (ifu_toIbuffer_bits_pc_14),
    .io_in_bits_pc_15                       (ifu_toIbuffer_bits_pc_15),
    .io_in_bits_ftqPtr_flag                 (ifu_toIbuffer_bits_ftqPtr_flag),
    .io_in_bits_ftqPtr_value                (ifu_toIbuffer_bits_ftqPtr_value),
    .io_in_bits_topdown_info_reasons_0      (ifu_toIbuffer_bits_topdown_info_reasons_0),
    .io_in_bits_topdown_info_reasons_1      (ifu_toIbuffer_bits_topdown_info_reasons_1),
    .io_in_bits_topdown_info_reasons_2      (ifu_toIbuffer_bits_topdown_info_reasons_2),
    .io_in_bits_topdown_info_reasons_3      (ifu_toIbuffer_bits_topdown_info_reasons_3),
    .io_in_bits_topdown_info_reasons_4      (ifu_toIbuffer_bits_topdown_info_reasons_4),
    .io_in_bits_topdown_info_reasons_5      (ifu_toIbuffer_bits_topdown_info_reasons_5),
    .io_in_bits_topdown_info_reasons_6      (ifu_toIbuffer_bits_topdown_info_reasons_6),
    .io_in_bits_topdown_info_reasons_7      (ifu_toIbuffer_bits_topdown_info_reasons_7),
    .io_in_bits_topdown_info_reasons_8      (ifu_toIbuffer_bits_topdown_info_reasons_8),
    .io_in_bits_topdown_info_reasons_9      (ifu_toIbuffer_bits_topdown_info_reasons_9),
    .io_in_bits_topdown_info_reasons_10     (ifu_toIbuffer_bits_topdown_info_reasons_10),
    .io_in_bits_topdown_info_reasons_11     (ifu_toIbuffer_bits_topdown_info_reasons_11),
    .io_in_bits_topdown_info_reasons_12     (ifu_toIbuffer_bits_topdown_info_reasons_12),
    .io_in_bits_topdown_info_reasons_13     (ifu_toIbuffer_bits_topdown_info_reasons_13),
    .io_in_bits_topdown_info_reasons_14     (ifu_toIbuffer_bits_topdown_info_reasons_14),
    .io_in_bits_topdown_info_reasons_15     (ifu_toIbuffer_bits_topdown_info_reasons_15),
    .io_in_bits_topdown_info_reasons_16     (ifu_toIbuffer_bits_topdown_info_reasons_16),
    .io_in_bits_topdown_info_reasons_17     (ifu_toIbuffer_bits_topdown_info_reasons_17),
    .io_in_bits_topdown_info_reasons_18     (ifu_toIbuffer_bits_topdown_info_reasons_18),
    .io_in_bits_topdown_info_reasons_19     (ifu_toIbuffer_bits_topdown_info_reasons_19),
    .io_in_bits_topdown_info_reasons_20     (ifu_toIbuffer_bits_topdown_info_reasons_20),
    .io_in_bits_topdown_info_reasons_21     (ifu_toIbuffer_bits_topdown_info_reasons_21),
    .io_in_bits_topdown_info_reasons_22     (ifu_toIbuffer_bits_topdown_info_reasons_22),
    .io_in_bits_topdown_info_reasons_23     (ifu_toIbuffer_bits_topdown_info_reasons_23),
    .io_in_bits_topdown_info_reasons_24     (ifu_toIbuffer_bits_topdown_info_reasons_24),
    .io_in_bits_topdown_info_reasons_25     (ifu_toIbuffer_bits_topdown_info_reasons_25),
    .io_in_bits_topdown_info_reasons_26     (ifu_toIbuffer_bits_topdown_info_reasons_26),
    .io_in_bits_topdown_info_reasons_27     (ifu_toIbuffer_bits_topdown_info_reasons_27),
    .io_in_bits_topdown_info_reasons_28     (ifu_toIbuffer_bits_topdown_info_reasons_28),
    .io_in_bits_topdown_info_reasons_29     (ifu_toIbuffer_bits_topdown_info_reasons_29),
    .io_in_bits_topdown_info_reasons_30     (ifu_toIbuffer_bits_topdown_info_reasons_30),
    .io_in_bits_topdown_info_reasons_31     (ifu_toIbuffer_bits_topdown_info_reasons_31),
    .io_in_bits_topdown_info_reasons_32     (ifu_toIbuffer_bits_topdown_info_reasons_32),
    .io_in_bits_topdown_info_reasons_33     (ifu_toIbuffer_bits_topdown_info_reasons_33),
    .io_in_bits_topdown_info_reasons_34     (ifu_toIbuffer_bits_topdown_info_reasons_34),
    .io_in_bits_topdown_info_reasons_35     (ifu_toIbuffer_bits_topdown_info_reasons_35),
    .io_in_bits_topdown_info_reasons_36     (ifu_toIbuffer_bits_topdown_info_reasons_36),
    .io_in_bits_topdown_info_reasons_37     (ifu_toIbuffer_bits_topdown_info_reasons_37),
    // ---- → 顶层输出；core（后端重定向冲刷与原因标志（打一拍）；出口 6 条指令供自检） ----
    .io_out_0_valid                         (ibuffer_out_0_valid),
    .io_out_0_bits_pc                       (ibuffer_out_0_bits_pc),
    .io_out_0_bits_pd_isRVC                 (ibuffer_out_0_bits_pd_isRVC),
    .io_out_0_bits_pd_brType                (ibuffer_out_0_bits_pd_brType),
    .io_out_0_bits_pred_taken               (ibuffer_out_0_bits_pred_taken),
    .io_out_0_bits_ftqPtr_flag              (ibuffer_out_0_bits_ftqPtr_flag),
    .io_out_0_bits_ftqPtr_value             (ibuffer_out_0_bits_ftqPtr_value),
    .io_out_1_valid                         (ibuffer_out_1_valid),
    .io_out_1_bits_pc                       (ibuffer_out_1_bits_pc),
    .io_out_1_bits_pd_isRVC                 (ibuffer_out_1_bits_pd_isRVC),
    .io_out_1_bits_pd_brType                (ibuffer_out_1_bits_pd_brType),
    .io_out_1_bits_pred_taken               (ibuffer_out_1_bits_pred_taken),
    .io_out_1_bits_ftqPtr_flag              (ibuffer_out_1_bits_ftqPtr_flag),
    .io_out_1_bits_ftqPtr_value             (ibuffer_out_1_bits_ftqPtr_value),
    .io_out_2_valid                         (ibuffer_out_2_valid),
    .io_out_2_bits_pc                       (ibuffer_out_2_bits_pc),
    .io_out_2_bits_pd_isRVC                 (ibuffer_out_2_bits_pd_isRVC),
    .io_out_2_bits_pd_brType                (ibuffer_out_2_bits_pd_brType),
    .io_out_2_bits_pred_taken               (ibuffer_out_2_bits_pred_taken),
    .io_out_2_bits_ftqPtr_flag              (ibuffer_out_2_bits_ftqPtr_flag),
    .io_out_2_bits_ftqPtr_value             (ibuffer_out_2_bits_ftqPtr_value),
    .io_out_3_valid                         (ibuffer_out_3_valid),
    .io_out_3_bits_pc                       (ibuffer_out_3_bits_pc),
    .io_out_3_bits_pd_isRVC                 (ibuffer_out_3_bits_pd_isRVC),
    .io_out_3_bits_pd_brType                (ibuffer_out_3_bits_pd_brType),
    .io_out_3_bits_pred_taken               (ibuffer_out_3_bits_pred_taken),
    .io_out_3_bits_ftqPtr_flag              (ibuffer_out_3_bits_ftqPtr_flag),
    .io_out_3_bits_ftqPtr_value             (ibuffer_out_3_bits_ftqPtr_value),
    .io_out_4_valid                         (ibuffer_out_4_valid),
    .io_out_4_bits_pc                       (ibuffer_out_4_bits_pc),
    .io_out_4_bits_pd_isRVC                 (ibuffer_out_4_bits_pd_isRVC),
    .io_out_4_bits_pd_brType                (ibuffer_out_4_bits_pd_brType),
    .io_out_4_bits_pred_taken               (ibuffer_out_4_bits_pred_taken),
    .io_out_4_bits_ftqPtr_flag              (ibuffer_out_4_bits_ftqPtr_flag),
    .io_out_4_bits_ftqPtr_value             (ibuffer_out_4_bits_ftqPtr_value),
    .io_out_5_valid                         (ibuffer_out_5_valid),
    .io_out_5_bits_pc                       (ibuffer_out_5_bits_pc),
    .io_out_5_bits_pd_isRVC                 (ibuffer_out_5_bits_pd_isRVC),
    .io_out_5_bits_pd_brType                (ibuffer_out_5_bits_pd_brType),
    .io_out_5_bits_pred_taken               (ibuffer_out_5_bits_pred_taken),
    .io_out_5_bits_ftqPtr_flag              (ibuffer_out_5_bits_ftqPtr_flag),
    .io_out_5_bits_ftqPtr_value             (ibuffer_out_5_bits_ftqPtr_value),
    // ---- 顶层 io_backend_cfVec* —— 送往后端译码的指令（每拍 6 条） ----
    .io_out_0_bits_instr                    (io_backend_cfVec_0_bits_instr),
    .io_out_0_bits_foldpc                   (io_backend_cfVec_0_bits_foldpc),
    .io_out_0_bits_exceptionVec_1           (io_backend_cfVec_0_bits_exceptionVec_1),
    .io_out_0_bits_exceptionVec_2           (io_backend_cfVec_0_bits_exceptionVec_2),
    .io_out_0_bits_exceptionVec_12          (io_backend_cfVec_0_bits_exceptionVec_12),
    .io_out_0_bits_exceptionVec_20          (io_backend_cfVec_0_bits_exceptionVec_20),
    .io_out_0_bits_backendException         (io_backend_cfVec_0_bits_backendException),
    .io_out_0_bits_satpFlushFirstFetchFault (io_backend_cfVec_0_bits_satpFlushFirstFetchFault),
    .io_out_0_bits_trigger                  (io_backend_cfVec_0_bits_trigger),
    .io_out_0_bits_pd_valid                 (io_backend_cfVec_0_bits_pd_valid),
    .io_out_0_bits_pd_isCall                (io_backend_cfVec_0_bits_pd_isCall),
    .io_out_0_bits_pd_isRet                 (io_backend_cfVec_0_bits_pd_isRet),
    .io_out_0_bits_crossPageIPFFix          (io_backend_cfVec_0_bits_crossPageIPFFix),
    .io_out_0_bits_ftqOffset                (io_backend_cfVec_0_bits_ftqOffset),
    .io_out_0_bits_isLastInFtqEntry         (io_backend_cfVec_0_bits_isLastInFtqEntry),
    .io_out_0_bits_debug_seqNum_seqNum      (io_backend_cfVec_0_bits_debug_seqNum_seqNum),
    .io_out_0_bits_debug_seqNum_uopIdx      (io_backend_cfVec_0_bits_debug_seqNum_uopIdx),
    .io_out_1_bits_instr                    (io_backend_cfVec_1_bits_instr),
    .io_out_1_bits_foldpc                   (io_backend_cfVec_1_bits_foldpc),
    .io_out_1_bits_exceptionVec_1           (io_backend_cfVec_1_bits_exceptionVec_1),
    .io_out_1_bits_exceptionVec_2           (io_backend_cfVec_1_bits_exceptionVec_2),
    .io_out_1_bits_exceptionVec_12          (io_backend_cfVec_1_bits_exceptionVec_12),
    .io_out_1_bits_exceptionVec_20          (io_backend_cfVec_1_bits_exceptionVec_20),
    .io_out_1_bits_backendException         (io_backend_cfVec_1_bits_backendException),
    .io_out_1_bits_satpFlushFirstFetchFault (io_backend_cfVec_1_bits_satpFlushFirstFetchFault),
    .io_out_1_bits_trigger                  (io_backend_cfVec_1_bits_trigger),
    .io_out_1_bits_pd_valid                 (io_backend_cfVec_1_bits_pd_valid),
    .io_out_1_bits_pd_isCall                (io_backend_cfVec_1_bits_pd_isCall),
    .io_out_1_bits_pd_isRet                 (io_backend_cfVec_1_bits_pd_isRet),
    .io_out_1_bits_crossPageIPFFix          (io_backend_cfVec_1_bits_crossPageIPFFix),
    .io_out_1_bits_ftqOffset                (io_backend_cfVec_1_bits_ftqOffset),
    .io_out_1_bits_isLastInFtqEntry         (io_backend_cfVec_1_bits_isLastInFtqEntry),
    .io_out_1_bits_debug_seqNum_seqNum      (io_backend_cfVec_1_bits_debug_seqNum_seqNum),
    .io_out_1_bits_debug_seqNum_uopIdx      (io_backend_cfVec_1_bits_debug_seqNum_uopIdx),
    .io_out_2_bits_instr                    (io_backend_cfVec_2_bits_instr),
    .io_out_2_bits_foldpc                   (io_backend_cfVec_2_bits_foldpc),
    .io_out_2_bits_exceptionVec_1           (io_backend_cfVec_2_bits_exceptionVec_1),
    .io_out_2_bits_exceptionVec_2           (io_backend_cfVec_2_bits_exceptionVec_2),
    .io_out_2_bits_exceptionVec_12          (io_backend_cfVec_2_bits_exceptionVec_12),
    .io_out_2_bits_exceptionVec_20          (io_backend_cfVec_2_bits_exceptionVec_20),
    .io_out_2_bits_backendException         (io_backend_cfVec_2_bits_backendException),
    .io_out_2_bits_satpFlushFirstFetchFault (io_backend_cfVec_2_bits_satpFlushFirstFetchFault),
    .io_out_2_bits_trigger                  (io_backend_cfVec_2_bits_trigger),
    .io_out_2_bits_pd_valid                 (io_backend_cfVec_2_bits_pd_valid),
    .io_out_2_bits_pd_isCall                (io_backend_cfVec_2_bits_pd_isCall),
    .io_out_2_bits_pd_isRet                 (io_backend_cfVec_2_bits_pd_isRet),
    .io_out_2_bits_crossPageIPFFix          (io_backend_cfVec_2_bits_crossPageIPFFix),
    .io_out_2_bits_ftqOffset                (io_backend_cfVec_2_bits_ftqOffset),
    .io_out_2_bits_isLastInFtqEntry         (io_backend_cfVec_2_bits_isLastInFtqEntry),
    .io_out_2_bits_debug_seqNum_seqNum      (io_backend_cfVec_2_bits_debug_seqNum_seqNum),
    .io_out_2_bits_debug_seqNum_uopIdx      (io_backend_cfVec_2_bits_debug_seqNum_uopIdx),
    .io_out_3_bits_instr                    (io_backend_cfVec_3_bits_instr),
    .io_out_3_bits_foldpc                   (io_backend_cfVec_3_bits_foldpc),
    .io_out_3_bits_exceptionVec_1           (io_backend_cfVec_3_bits_exceptionVec_1),
    .io_out_3_bits_exceptionVec_2           (io_backend_cfVec_3_bits_exceptionVec_2),
    .io_out_3_bits_exceptionVec_12          (io_backend_cfVec_3_bits_exceptionVec_12),
    .io_out_3_bits_exceptionVec_20          (io_backend_cfVec_3_bits_exceptionVec_20),
    .io_out_3_bits_backendException         (io_backend_cfVec_3_bits_backendException),
    .io_out_3_bits_satpFlushFirstFetchFault (io_backend_cfVec_3_bits_satpFlushFirstFetchFault),
    .io_out_3_bits_trigger                  (io_backend_cfVec_3_bits_trigger),
    .io_out_3_bits_pd_valid                 (io_backend_cfVec_3_bits_pd_valid),
    .io_out_3_bits_pd_isCall                (io_backend_cfVec_3_bits_pd_isCall),
    .io_out_3_bits_pd_isRet                 (io_backend_cfVec_3_bits_pd_isRet),
    .io_out_3_bits_crossPageIPFFix          (io_backend_cfVec_3_bits_crossPageIPFFix),
    .io_out_3_bits_ftqOffset                (io_backend_cfVec_3_bits_ftqOffset),
    .io_out_3_bits_isLastInFtqEntry         (io_backend_cfVec_3_bits_isLastInFtqEntry),
    .io_out_3_bits_debug_seqNum_seqNum      (io_backend_cfVec_3_bits_debug_seqNum_seqNum),
    .io_out_3_bits_debug_seqNum_uopIdx      (io_backend_cfVec_3_bits_debug_seqNum_uopIdx),
    .io_out_4_bits_instr                    (io_backend_cfVec_4_bits_instr),
    .io_out_4_bits_foldpc                   (io_backend_cfVec_4_bits_foldpc),
    .io_out_4_bits_exceptionVec_1           (io_backend_cfVec_4_bits_exceptionVec_1),
    .io_out_4_bits_exceptionVec_2           (io_backend_cfVec_4_bits_exceptionVec_2),
    .io_out_4_bits_exceptionVec_12          (io_backend_cfVec_4_bits_exceptionVec_12),
    .io_out_4_bits_exceptionVec_20          (io_backend_cfVec_4_bits_exceptionVec_20),
    .io_out_4_bits_backendException         (io_backend_cfVec_4_bits_backendException),
    .io_out_4_bits_satpFlushFirstFetchFault (io_backend_cfVec_4_bits_satpFlushFirstFetchFault),
    .io_out_4_bits_trigger                  (io_backend_cfVec_4_bits_trigger),
    .io_out_4_bits_pd_valid                 (io_backend_cfVec_4_bits_pd_valid),
    .io_out_4_bits_pd_isCall                (io_backend_cfVec_4_bits_pd_isCall),
    .io_out_4_bits_pd_isRet                 (io_backend_cfVec_4_bits_pd_isRet),
    .io_out_4_bits_crossPageIPFFix          (io_backend_cfVec_4_bits_crossPageIPFFix),
    .io_out_4_bits_ftqOffset                (io_backend_cfVec_4_bits_ftqOffset),
    .io_out_4_bits_isLastInFtqEntry         (io_backend_cfVec_4_bits_isLastInFtqEntry),
    .io_out_4_bits_debug_seqNum_seqNum      (io_backend_cfVec_4_bits_debug_seqNum_seqNum),
    .io_out_4_bits_debug_seqNum_uopIdx      (io_backend_cfVec_4_bits_debug_seqNum_uopIdx),
    .io_out_5_bits_instr                    (io_backend_cfVec_5_bits_instr),
    .io_out_5_bits_foldpc                   (io_backend_cfVec_5_bits_foldpc),
    .io_out_5_bits_exceptionVec_1           (io_backend_cfVec_5_bits_exceptionVec_1),
    .io_out_5_bits_exceptionVec_2           (io_backend_cfVec_5_bits_exceptionVec_2),
    .io_out_5_bits_exceptionVec_12          (io_backend_cfVec_5_bits_exceptionVec_12),
    .io_out_5_bits_exceptionVec_20          (io_backend_cfVec_5_bits_exceptionVec_20),
    .io_out_5_bits_backendException         (io_backend_cfVec_5_bits_backendException),
    .io_out_5_bits_satpFlushFirstFetchFault (io_backend_cfVec_5_bits_satpFlushFirstFetchFault),
    .io_out_5_bits_trigger                  (io_backend_cfVec_5_bits_trigger),
    .io_out_5_bits_pd_valid                 (io_backend_cfVec_5_bits_pd_valid),
    .io_out_5_bits_pd_isCall                (io_backend_cfVec_5_bits_pd_isCall),
    .io_out_5_bits_pd_isRet                 (io_backend_cfVec_5_bits_pd_isRet),
    .io_out_5_bits_crossPageIPFFix          (io_backend_cfVec_5_bits_crossPageIPFFix),
    .io_out_5_bits_ftqOffset                (io_backend_cfVec_5_bits_ftqOffset),
    .io_out_5_bits_isLastInFtqEntry         (io_backend_cfVec_5_bits_isLastInFtqEntry),
    .io_out_5_bits_debug_seqNum_seqNum      (io_backend_cfVec_5_bits_debug_seqNum_seqNum),
    .io_out_5_bits_debug_seqNum_uopIdx      (io_backend_cfVec_5_bits_debug_seqNum_uopIdx),
    // ---- 顶层 io_backend_canAccept* —— 后端译码能否接收 ----
    .io_decodeCanAccept                     (io_backend_canAccept),
    // ---- 顶层 io_backend_stallReason* —— TopDown 停顿原因 ----
    .io_stallReason_reason_0                (io_backend_stallReason_reason_0),
    .io_stallReason_reason_1                (io_backend_stallReason_reason_1),
    .io_stallReason_reason_2                (io_backend_stallReason_reason_2),
    .io_stallReason_reason_3                (io_backend_stallReason_reason_3),
    .io_stallReason_reason_4                (io_backend_stallReason_reason_4),
    .io_stallReason_reason_5                (io_backend_stallReason_reason_5),
    .io_stallReason_backReason_valid        (io_backend_stallReason_backReason_valid),
    .io_stallReason_backReason_bits         (io_backend_stallReason_backReason_bits),
    // ---- → perfHpm（IBuffer 性能事件） ----
    .io_perf_0_value                        (ibuffer_perf_0_value),
    .io_perf_1_value                        (ibuffer_perf_1_value),
    .io_perf_2_value                        (ibuffer_perf_2_value),
    .io_perf_3_value                        (ibuffer_perf_3_value),
    .io_perf_4_value                        (ibuffer_perf_4_value),
    .io_perf_5_value                        (ibuffer_perf_5_value),
    .io_perf_6_value                        (ibuffer_perf_6_value),
    .io_perf_7_value                        (ibuffer_perf_7_value),
    .io_perf_8_value                        (ibuffer_perf_8_value)
  );
  InstrUncache inner_instrUncache (
    // ---- 时钟 / 复位 ----
    .clock                                      (clock),
    .reset                                      (reset),
    // ---- 顶层 auto_inner_instrUncache_client_out* —— MMIO 取指 TL-UL 主口（经 MemBlock.FrontendBridge.instr_uncache） ----
    .auto_client_out_a_ready                    (auto_inner_instrUncache_client_out_a_ready),
    .auto_client_out_a_valid                    (auto_inner_instrUncache_client_out_a_valid),
    .auto_client_out_a_bits_address             (auto_inner_instrUncache_client_out_a_bits_address),
    .auto_client_out_a_bits_user_memPageType_NC (auto_inner_instrUncache_client_out_a_bits_user_memPageType_NC),
    .auto_client_out_a_bits_user_memBackType_MM (auto_inner_instrUncache_client_out_a_bits_user_memBackType_MM),
    .auto_client_out_d_valid                    (auto_inner_instrUncache_client_out_d_valid),
    .auto_client_out_d_bits_source              (auto_inner_instrUncache_client_out_d_bits_source),
    .auto_client_out_d_bits_data                (auto_inner_instrUncache_client_out_d_bits_data),
    .auto_client_out_d_bits_corrupt             (auto_inner_instrUncache_client_out_d_bits_corrupt),
    // ---- → ifu（IFU 的 MMIO 取指请求 / 回应） ----
    .io_req_ready                               (instrUncache_req_ready),
    .io_resp_valid                              (instrUncache_resp_valid),
    .io_resp_bits_data                          (instrUncache_resp_bits_data),
    .io_resp_bits_corrupt                       (instrUncache_resp_bits_corrupt),
    // ---- ← ifu：IFU 的 MMIO 取指请求 / 回应 ----
    .io_req_valid                               (ifu_uncacheInter_toUncache_valid),
    .io_req_bits_addr                           (ifu_uncacheInter_toUncache_bits_addr),
    .io_req_bits_memBackTypeMM                  (ifu_uncacheInter_toUncache_bits_memBackTypeMM),
    .io_req_bits_memPageTypeNC                  (ifu_uncacheInter_toUncache_bits_memPageTypeNC),
    .io_req_bits_flush                          (ifu_uncacheInter_toUncache_bits_flush),
    // ---- ← wfiReqDelay：wfi 请求（打一拍后） ----
    .io_wfi_wfiReq                              (wfiReqDelay_out),
    // ---- → core（MMIO 取指的 wfi 安全） ----
    .io_wfi_wfiSafe                             (instrUncache_wfi_wfiSafe)
  );

  // ===========================================================================
  // §B 地址翻译与访问权限：ITLB → PTWFilter → PTWRepeaterNB → L2TLB；PMP + 5 个检查口
  // ===========================================================================
  TLB inner_itlb (
    // ---- 时钟 / 复位 ----
    .clock                                      (clock),
    .reset                                      (reset),
    // ---- ← u_core：sfence.vma（打两拍后） ----
    .io_sfence_valid                            (sfence_dly_valid),
    .io_sfence_bits_rs1                         (sfence_dly_bits_rs1),
    .io_sfence_bits_rs2                         (sfence_dly_bits_rs2),
    .io_sfence_bits_addr                        (sfence_dly_bits_addr),
    .io_sfence_bits_id                          (sfence_dly_bits_id),
    .io_sfence_bits_flushPipe                   (sfence_dly_bits_flushPipe),
    .io_sfence_bits_hv                          (sfence_dly_bits_hv),
    .io_sfence_bits_hg                          (sfence_dly_bits_hg),
    // ---- ← tlbCsrDelay：satp/vsatp/hgatp/特权级等 TLB CSR（打两拍后） ----
    .io_csr_satp_mode                           (tlbCsrDelay_out_satp_mode),
    .io_csr_satp_asid                           (tlbCsrDelay_out_satp_asid),
    .io_csr_satp_ppn                            (tlbCsrDelay_out_satp_ppn),
    .io_csr_satp_changed                        (tlbCsrDelay_out_satp_changed),
    .io_csr_vsatp_mode                          (tlbCsrDelay_out_vsatp_mode),
    .io_csr_vsatp_asid                          (tlbCsrDelay_out_vsatp_asid),
    .io_csr_vsatp_ppn                           (tlbCsrDelay_out_vsatp_ppn),
    .io_csr_vsatp_changed                       (tlbCsrDelay_out_vsatp_changed),
    .io_csr_hgatp_mode                          (tlbCsrDelay_out_hgatp_mode),
    .io_csr_hgatp_vmid                          (tlbCsrDelay_out_hgatp_vmid),
    .io_csr_hgatp_ppn                           (tlbCsrDelay_out_hgatp_ppn),
    .io_csr_hgatp_changed                       (tlbCsrDelay_out_hgatp_changed),
    .io_csr_mbmc_BME                            (tlbCsrDelay_out_mbmc_BME),
    .io_csr_mbmc_CMODE                          (tlbCsrDelay_out_mbmc_CMODE),
    .io_csr_priv_mxr                            (tlbCsrDelay_out_priv_mxr),
    .io_csr_priv_sum                            (tlbCsrDelay_out_priv_sum),
    .io_csr_priv_vmxr                           (tlbCsrDelay_out_priv_vmxr),
    .io_csr_priv_vsum                           (tlbCsrDelay_out_priv_vsum),
    .io_csr_priv_virt                           (tlbCsrDelay_out_priv_virt),
    .io_csr_priv_virt_changed                   (tlbCsrDelay_out_priv_virt_changed),
    .io_csr_priv_spvp                           (tlbCsrDelay_out_priv_spvp),
    .io_csr_priv_imode                          (tlbCsrDelay_out_priv_imode),
    .io_csr_priv_dmode                          (tlbCsrDelay_out_priv_dmode),
    .io_csr_priv_debug                          (tlbCsrDelay_out_priv_debug),
    .io_csr_pmm_mseccfg                         (tlbCsrDelay_out_pmm_mseccfg),
    .io_csr_pmm_menvcfg                         (tlbCsrDelay_out_pmm_menvcfg),
    .io_csr_pmm_henvcfg                         (tlbCsrDelay_out_pmm_henvcfg),
    .io_csr_pmm_hstatus                         (tlbCsrDelay_out_pmm_hstatus),
    .io_csr_pmm_senvcfg                         (tlbCsrDelay_out_pmm_senvcfg),
    // ---- 顶层 io_hartId* —— 核号 ----
    .io_hartId                                  (io_hartId),
    // ---- ← icache：ICache 预取流水的 2 个 ITLB 请求口 / 回应 ----
    .io_requestor_0_req_valid                   (icache_itlb_0_req_valid),
    .io_requestor_0_req_bits_vaddr              (icache_itlb_0_req_bits_vaddr),
    .io_requestor_1_req_valid                   (icache_itlb_1_req_valid),
    .io_requestor_1_req_bits_vaddr              (icache_itlb_1_req_bits_vaddr),
    .io_flushPipe_0                             (icache_itlbFlushPipe),
    .io_flushPipe_1                             (icache_itlbFlushPipe),
    .io_flushPipe_2                             (icache_itlbFlushPipe),
    // ---- → icache（ICache 预取流水的 2 个 ITLB 请求口 / 回应） ----
    .io_requestor_0_resp_bits_paddr_0           (itlb_requestor_0_resp_bits_paddr_0),
    .io_requestor_0_resp_bits_gpaddr_0          (itlb_requestor_0_resp_bits_gpaddr_0),
    .io_requestor_0_resp_bits_pbmt_0            (itlb_requestor_0_resp_bits_pbmt_0),
    .io_requestor_0_resp_bits_miss              (itlb_requestor_0_resp_bits_miss),
    .io_requestor_0_resp_bits_isForVSnonLeafPTE (itlb_requestor_0_resp_bits_isForVSnonLeafPTE),
    .io_requestor_0_resp_bits_excp_0_gpf_instr  (itlb_requestor_0_resp_bits_excp_0_gpf_instr),
    .io_requestor_0_resp_bits_excp_0_pf_instr   (itlb_requestor_0_resp_bits_excp_0_pf_instr),
    .io_requestor_0_resp_bits_excp_0_af_instr   (itlb_requestor_0_resp_bits_excp_0_af_instr),
    .io_requestor_1_resp_bits_paddr_0           (itlb_requestor_1_resp_bits_paddr_0),
    .io_requestor_1_resp_bits_gpaddr_0          (itlb_requestor_1_resp_bits_gpaddr_0),
    .io_requestor_1_resp_bits_pbmt_0            (itlb_requestor_1_resp_bits_pbmt_0),
    .io_requestor_1_resp_bits_miss              (itlb_requestor_1_resp_bits_miss),
    .io_requestor_1_resp_bits_isForVSnonLeafPTE (itlb_requestor_1_resp_bits_isForVSnonLeafPTE),
    .io_requestor_1_resp_bits_excp_0_gpf_instr  (itlb_requestor_1_resp_bits_excp_0_gpf_instr),
    .io_requestor_1_resp_bits_excp_0_pf_instr   (itlb_requestor_1_resp_bits_excp_0_pf_instr),
    .io_requestor_1_resp_bits_excp_0_af_instr   (itlb_requestor_1_resp_bits_excp_0_af_instr),
    // ---- → ifu（IFU 的 MMIO 取指重新翻译口（ITLB 第 3 口，阻塞式）） ----
    .io_requestor_2_req_ready                   (itlb_requestor_2_req_ready),
    .io_requestor_2_resp_valid                  (itlb_requestor_2_resp_valid),
    .io_requestor_2_resp_bits_paddr_0           (itlb_requestor_2_resp_bits_paddr_0),
    .io_requestor_2_resp_bits_gpaddr_0          (itlb_requestor_2_resp_bits_gpaddr_0),
    .io_requestor_2_resp_bits_pbmt_0            (itlb_requestor_2_resp_bits_pbmt_0),
    .io_requestor_2_resp_bits_miss              (itlb_requestor_2_resp_bits_miss),
    .io_requestor_2_resp_bits_isForVSnonLeafPTE (itlb_requestor_2_resp_bits_isForVSnonLeafPTE),
    .io_requestor_2_resp_bits_excp_0_gpf_instr  (itlb_requestor_2_resp_bits_excp_0_gpf_instr),
    .io_requestor_2_resp_bits_excp_0_pf_instr   (itlb_requestor_2_resp_bits_excp_0_pf_instr),
    .io_requestor_2_resp_bits_excp_0_af_instr   (itlb_requestor_2_resp_bits_excp_0_af_instr),
    // ---- ← ifu：IFU 的 MMIO 取指重新翻译口（ITLB 第 3 口，阻塞式） ----
    .io_requestor_2_req_valid                   (ifu_iTLBInter_req_valid),
    .io_requestor_2_req_bits_vaddr              (ifu_iTLBInter_req_bits_vaddr),
    .io_requestor_2_resp_ready                  (ifu_iTLBInter_resp_ready),
    // ---- ← itlbRepeater1：ITLB 未命中 → PTWFilter（去重、排队）；回填结果回到 ITLB ----
    .io_ptw_req_0_ready                         (itlbRepeater1_tlb_req_0_ready),
    .io_ptw_req_1_ready                         (itlbRepeater1_tlb_req_1_ready),
    .io_ptw_req_2_ready                         (itlbRepeater1_tlb_req_2_ready),
    .io_ptw_resp_valid                          (itlbRepeater1_tlb_resp_valid),
    .io_ptw_resp_bits_s2xlate                   (itlbRepeater1_tlb_resp_bits_data_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag              (itlbRepeater1_tlb_resp_bits_data_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid             (itlbRepeater1_tlb_resp_bits_data_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid             (itlbRepeater1_tlb_resp_bits_data_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n                (itlbRepeater1_tlb_resp_bits_data_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt             (itlbRepeater1_tlb_resp_bits_data_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d           (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a           (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g           (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u           (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x           (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w           (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r           (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level            (itlbRepeater1_tlb_resp_bits_data_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v                (itlbRepeater1_tlb_resp_bits_data_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn              (itlbRepeater1_tlb_resp_bits_data_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low               (itlbRepeater1_tlb_resp_bits_data_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0              (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1              (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2              (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3              (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4              (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5              (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6              (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7              (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0             (itlbRepeater1_tlb_resp_bits_data_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1             (itlbRepeater1_tlb_resp_bits_data_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2             (itlbRepeater1_tlb_resp_bits_data_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3             (itlbRepeater1_tlb_resp_bits_data_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4             (itlbRepeater1_tlb_resp_bits_data_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5             (itlbRepeater1_tlb_resp_bits_data_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6             (itlbRepeater1_tlb_resp_bits_data_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7             (itlbRepeater1_tlb_resp_bits_data_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0               (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1               (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2               (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3               (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4               (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5               (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6               (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7               (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf                     (itlbRepeater1_tlb_resp_bits_data_s1_pf),
    .io_ptw_resp_bits_s1_af                     (itlbRepeater1_tlb_resp_bits_data_s1_af),
    .io_ptw_resp_bits_s2_entry_tag              (itlbRepeater1_tlb_resp_bits_data_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid             (itlbRepeater1_tlb_resp_bits_data_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n                (itlbRepeater1_tlb_resp_bits_data_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt             (itlbRepeater1_tlb_resp_bits_data_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn              (itlbRepeater1_tlb_resp_bits_data_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d           (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a           (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g           (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u           (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x           (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w           (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r           (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level            (itlbRepeater1_tlb_resp_bits_data_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf                    (itlbRepeater1_tlb_resp_bits_data_s2_gpf),
    .io_ptw_resp_bits_s2_gaf                    (itlbRepeater1_tlb_resp_bits_data_s2_gaf),
    .io_ptw_resp_bits_getGpa                    (itlbRepeater1_tlb_resp_bits_data_getGpa),
    // ---- → itlbRepeater1（ITLB 未命中 → PTWFilter（去重、排队）；回填结果回到 ITLB） ----
    .io_ptw_req_0_valid                         (itlb_ptw_req_0_valid),
    .io_ptw_req_0_bits_vpn                      (itlb_ptw_req_0_bits_vpn),
    .io_ptw_req_0_bits_s2xlate                  (itlb_ptw_req_0_bits_s2xlate),
    .io_ptw_req_0_bits_getGpa                   (itlb_ptw_req_0_bits_getGpa),
    .io_ptw_req_1_valid                         (itlb_ptw_req_1_valid),
    .io_ptw_req_1_bits_vpn                      (itlb_ptw_req_1_bits_vpn),
    .io_ptw_req_1_bits_s2xlate                  (itlb_ptw_req_1_bits_s2xlate),
    .io_ptw_req_1_bits_getGpa                   (itlb_ptw_req_1_bits_getGpa),
    .io_ptw_req_2_valid                         (itlb_ptw_req_2_valid),
    .io_ptw_req_2_bits_vpn                      (itlb_ptw_req_2_bits_vpn),
    .io_ptw_req_2_bits_s2xlate                  (itlb_ptw_req_2_bits_s2xlate),
    .io_ptw_req_2_bits_getGpa                   (itlb_ptw_req_2_bits_getGpa),
    // ---- → perfHpm（ITLB 性能事件） ----
    .io_perf_0_value                            (itlb_perf_0_value),
    .io_perf_1_value                            (itlb_perf_1_value),
    // ---- 顶层 gatewayIn_packed* —— MBIST 网关穿线 ----
    .gatewayIn_packed_3_bore                    (gatewayIn_packed_3_bore),
    .gatewayIn_packed_4_bore                    (gatewayIn_packed_4_bore),
    .gatewayIn_packed_5_bore                    (gatewayIn_packed_5_bore)
  );
  PTWFilter inner_itlbRepeater1 (
    // ---- 时钟 / 复位 ----
    .clock                                 (clock),
    .reset                                 (reset),
    // ---- ← u_core：sfence.vma（打两拍后） ----
    .io_sfence_valid                       (sfence_dly_valid),
    // ---- ← tlbCsrDelay：TLB CSR（打两拍后） ----
    .io_csr_satp_asid                      (tlbCsrDelay_out_satp_asid),
    .io_csr_satp_changed                   (tlbCsrDelay_out_satp_changed),
    .io_csr_vsatp_asid                     (tlbCsrDelay_out_vsatp_asid),
    .io_csr_vsatp_changed                  (tlbCsrDelay_out_vsatp_changed),
    .io_csr_hgatp_vmid                     (tlbCsrDelay_out_hgatp_vmid),
    .io_csr_hgatp_changed                  (tlbCsrDelay_out_hgatp_changed),
    .io_csr_priv_virt_changed              (tlbCsrDelay_out_priv_virt_changed),
    // ---- → itlb（ITLB 未命中 → PTWFilter（去重、排队）；回填结果回到 ITLB） ----
    .io_tlb_req_0_ready                    (itlbRepeater1_tlb_req_0_ready),
    .io_tlb_req_1_ready                    (itlbRepeater1_tlb_req_1_ready),
    .io_tlb_req_2_ready                    (itlbRepeater1_tlb_req_2_ready),
    .io_tlb_resp_valid                     (itlbRepeater1_tlb_resp_valid),
    .io_tlb_resp_bits_data_s2xlate         (itlbRepeater1_tlb_resp_bits_data_s2xlate),
    .io_tlb_resp_bits_data_s1_entry_tag    (itlbRepeater1_tlb_resp_bits_data_s1_entry_tag),
    .io_tlb_resp_bits_data_s1_entry_asid   (itlbRepeater1_tlb_resp_bits_data_s1_entry_asid),
    .io_tlb_resp_bits_data_s1_entry_vmid   (itlbRepeater1_tlb_resp_bits_data_s1_entry_vmid),
    .io_tlb_resp_bits_data_s1_entry_n      (itlbRepeater1_tlb_resp_bits_data_s1_entry_n),
    .io_tlb_resp_bits_data_s1_entry_pbmt   (itlbRepeater1_tlb_resp_bits_data_s1_entry_pbmt),
    .io_tlb_resp_bits_data_s1_entry_perm_d (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_d),
    .io_tlb_resp_bits_data_s1_entry_perm_a (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_a),
    .io_tlb_resp_bits_data_s1_entry_perm_g (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_g),
    .io_tlb_resp_bits_data_s1_entry_perm_u (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_u),
    .io_tlb_resp_bits_data_s1_entry_perm_x (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_x),
    .io_tlb_resp_bits_data_s1_entry_perm_w (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_w),
    .io_tlb_resp_bits_data_s1_entry_perm_r (itlbRepeater1_tlb_resp_bits_data_s1_entry_perm_r),
    .io_tlb_resp_bits_data_s1_entry_level  (itlbRepeater1_tlb_resp_bits_data_s1_entry_level),
    .io_tlb_resp_bits_data_s1_entry_v      (itlbRepeater1_tlb_resp_bits_data_s1_entry_v),
    .io_tlb_resp_bits_data_s1_entry_ppn    (itlbRepeater1_tlb_resp_bits_data_s1_entry_ppn),
    .io_tlb_resp_bits_data_s1_addr_low     (itlbRepeater1_tlb_resp_bits_data_s1_addr_low),
    .io_tlb_resp_bits_data_s1_ppn_low_0    (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_0),
    .io_tlb_resp_bits_data_s1_ppn_low_1    (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_1),
    .io_tlb_resp_bits_data_s1_ppn_low_2    (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_2),
    .io_tlb_resp_bits_data_s1_ppn_low_3    (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_3),
    .io_tlb_resp_bits_data_s1_ppn_low_4    (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_4),
    .io_tlb_resp_bits_data_s1_ppn_low_5    (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_5),
    .io_tlb_resp_bits_data_s1_ppn_low_6    (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_6),
    .io_tlb_resp_bits_data_s1_ppn_low_7    (itlbRepeater1_tlb_resp_bits_data_s1_ppn_low_7),
    .io_tlb_resp_bits_data_s1_valididx_0   (itlbRepeater1_tlb_resp_bits_data_s1_valididx_0),
    .io_tlb_resp_bits_data_s1_valididx_1   (itlbRepeater1_tlb_resp_bits_data_s1_valididx_1),
    .io_tlb_resp_bits_data_s1_valididx_2   (itlbRepeater1_tlb_resp_bits_data_s1_valididx_2),
    .io_tlb_resp_bits_data_s1_valididx_3   (itlbRepeater1_tlb_resp_bits_data_s1_valididx_3),
    .io_tlb_resp_bits_data_s1_valididx_4   (itlbRepeater1_tlb_resp_bits_data_s1_valididx_4),
    .io_tlb_resp_bits_data_s1_valididx_5   (itlbRepeater1_tlb_resp_bits_data_s1_valididx_5),
    .io_tlb_resp_bits_data_s1_valididx_6   (itlbRepeater1_tlb_resp_bits_data_s1_valididx_6),
    .io_tlb_resp_bits_data_s1_valididx_7   (itlbRepeater1_tlb_resp_bits_data_s1_valididx_7),
    .io_tlb_resp_bits_data_s1_pteidx_0     (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_0),
    .io_tlb_resp_bits_data_s1_pteidx_1     (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_1),
    .io_tlb_resp_bits_data_s1_pteidx_2     (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_2),
    .io_tlb_resp_bits_data_s1_pteidx_3     (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_3),
    .io_tlb_resp_bits_data_s1_pteidx_4     (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_4),
    .io_tlb_resp_bits_data_s1_pteidx_5     (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_5),
    .io_tlb_resp_bits_data_s1_pteidx_6     (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_6),
    .io_tlb_resp_bits_data_s1_pteidx_7     (itlbRepeater1_tlb_resp_bits_data_s1_pteidx_7),
    .io_tlb_resp_bits_data_s1_pf           (itlbRepeater1_tlb_resp_bits_data_s1_pf),
    .io_tlb_resp_bits_data_s1_af           (itlbRepeater1_tlb_resp_bits_data_s1_af),
    .io_tlb_resp_bits_data_s2_entry_tag    (itlbRepeater1_tlb_resp_bits_data_s2_entry_tag),
    .io_tlb_resp_bits_data_s2_entry_vmid   (itlbRepeater1_tlb_resp_bits_data_s2_entry_vmid),
    .io_tlb_resp_bits_data_s2_entry_n      (itlbRepeater1_tlb_resp_bits_data_s2_entry_n),
    .io_tlb_resp_bits_data_s2_entry_pbmt   (itlbRepeater1_tlb_resp_bits_data_s2_entry_pbmt),
    .io_tlb_resp_bits_data_s2_entry_ppn    (itlbRepeater1_tlb_resp_bits_data_s2_entry_ppn),
    .io_tlb_resp_bits_data_s2_entry_perm_d (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_d),
    .io_tlb_resp_bits_data_s2_entry_perm_a (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_a),
    .io_tlb_resp_bits_data_s2_entry_perm_g (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_g),
    .io_tlb_resp_bits_data_s2_entry_perm_u (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_u),
    .io_tlb_resp_bits_data_s2_entry_perm_x (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_x),
    .io_tlb_resp_bits_data_s2_entry_perm_w (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_w),
    .io_tlb_resp_bits_data_s2_entry_perm_r (itlbRepeater1_tlb_resp_bits_data_s2_entry_perm_r),
    .io_tlb_resp_bits_data_s2_entry_level  (itlbRepeater1_tlb_resp_bits_data_s2_entry_level),
    .io_tlb_resp_bits_data_s2_gpf          (itlbRepeater1_tlb_resp_bits_data_s2_gpf),
    .io_tlb_resp_bits_data_s2_gaf          (itlbRepeater1_tlb_resp_bits_data_s2_gaf),
    .io_tlb_resp_bits_data_getGpa          (itlbRepeater1_tlb_resp_bits_data_getGpa),
    // ---- ← itlb：ITLB 未命中 → PTWFilter（去重、排队）；回填结果回到 ITLB ----
    .io_tlb_req_0_valid                    (itlb_ptw_req_0_valid),
    .io_tlb_req_0_bits_vpn                 (itlb_ptw_req_0_bits_vpn),
    .io_tlb_req_0_bits_s2xlate             (itlb_ptw_req_0_bits_s2xlate),
    .io_tlb_req_0_bits_getGpa              (itlb_ptw_req_0_bits_getGpa),
    .io_tlb_req_1_valid                    (itlb_ptw_req_1_valid),
    .io_tlb_req_1_bits_vpn                 (itlb_ptw_req_1_bits_vpn),
    .io_tlb_req_1_bits_s2xlate             (itlb_ptw_req_1_bits_s2xlate),
    .io_tlb_req_1_bits_getGpa              (itlb_ptw_req_1_bits_getGpa),
    .io_tlb_req_2_valid                    (itlb_ptw_req_2_valid),
    .io_tlb_req_2_bits_vpn                 (itlb_ptw_req_2_bits_vpn),
    .io_tlb_req_2_bits_s2xlate             (itlb_ptw_req_2_bits_s2xlate),
    .io_tlb_req_2_bits_getGpa              (itlb_ptw_req_2_bits_getGpa),
    // ---- ← itlbRepeater2：PTWFilter → PTWRepeaterNB（再打拍）→ L2TLB ----
    .io_ptw_req_0_ready                    (itlbRepeater2_tlb_req_0_ready),
    .io_ptw_resp_valid                     (itlbRepeater2_tlb_resp_valid),
    .io_ptw_resp_bits_s2xlate              (itlbRepeater2_tlb_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag         (itlbRepeater2_tlb_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid        (itlbRepeater2_tlb_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid        (itlbRepeater2_tlb_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n           (itlbRepeater2_tlb_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt        (itlbRepeater2_tlb_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d      (itlbRepeater2_tlb_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a      (itlbRepeater2_tlb_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g      (itlbRepeater2_tlb_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u      (itlbRepeater2_tlb_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x      (itlbRepeater2_tlb_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w      (itlbRepeater2_tlb_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r      (itlbRepeater2_tlb_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level       (itlbRepeater2_tlb_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v           (itlbRepeater2_tlb_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn         (itlbRepeater2_tlb_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low          (itlbRepeater2_tlb_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0         (itlbRepeater2_tlb_resp_bits_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1         (itlbRepeater2_tlb_resp_bits_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2         (itlbRepeater2_tlb_resp_bits_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3         (itlbRepeater2_tlb_resp_bits_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4         (itlbRepeater2_tlb_resp_bits_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5         (itlbRepeater2_tlb_resp_bits_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6         (itlbRepeater2_tlb_resp_bits_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7         (itlbRepeater2_tlb_resp_bits_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0        (itlbRepeater2_tlb_resp_bits_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1        (itlbRepeater2_tlb_resp_bits_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2        (itlbRepeater2_tlb_resp_bits_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3        (itlbRepeater2_tlb_resp_bits_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4        (itlbRepeater2_tlb_resp_bits_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5        (itlbRepeater2_tlb_resp_bits_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6        (itlbRepeater2_tlb_resp_bits_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7        (itlbRepeater2_tlb_resp_bits_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0          (itlbRepeater2_tlb_resp_bits_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1          (itlbRepeater2_tlb_resp_bits_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2          (itlbRepeater2_tlb_resp_bits_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3          (itlbRepeater2_tlb_resp_bits_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4          (itlbRepeater2_tlb_resp_bits_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5          (itlbRepeater2_tlb_resp_bits_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6          (itlbRepeater2_tlb_resp_bits_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7          (itlbRepeater2_tlb_resp_bits_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf                (itlbRepeater2_tlb_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af                (itlbRepeater2_tlb_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag         (itlbRepeater2_tlb_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid        (itlbRepeater2_tlb_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n           (itlbRepeater2_tlb_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt        (itlbRepeater2_tlb_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn         (itlbRepeater2_tlb_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d      (itlbRepeater2_tlb_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a      (itlbRepeater2_tlb_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g      (itlbRepeater2_tlb_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u      (itlbRepeater2_tlb_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x      (itlbRepeater2_tlb_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w      (itlbRepeater2_tlb_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r      (itlbRepeater2_tlb_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level       (itlbRepeater2_tlb_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf               (itlbRepeater2_tlb_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf               (itlbRepeater2_tlb_resp_bits_s2_gaf),
    // ---- → itlbRepeater2（PTWFilter → PTWRepeaterNB（再打拍）→ L2TLB） ----
    .io_ptw_req_0_valid                    (itlbRepeater1_ptw_req_0_valid),
    .io_ptw_req_0_bits_vpn                 (itlbRepeater1_ptw_req_0_bits_vpn),
    .io_ptw_req_0_bits_s2xlate             (itlbRepeater1_ptw_req_0_bits_s2xlate)
  );
  PTWRepeaterNB inner_itlbRepeater2 (
    // ---- 时钟 / 复位 ----
    .clock                            (clock),
    .reset                            (reset),
    // ---- ← u_core：sfence.vma（打两拍后） ----
    .io_sfence_valid                  (sfence_dly_valid),
    // ---- ← tlbCsrDelay：TLB CSR（打两拍后） ----
    .io_csr_satp_changed              (tlbCsrDelay_out_satp_changed),
    .io_csr_vsatp_changed             (tlbCsrDelay_out_vsatp_changed),
    .io_csr_hgatp_changed             (tlbCsrDelay_out_hgatp_changed),
    .io_csr_priv_virt_changed         (tlbCsrDelay_out_priv_virt_changed),
    // ---- → itlbRepeater1（PTWFilter → PTWRepeaterNB（再打拍）→ L2TLB） ----
    .io_tlb_req_0_ready               (itlbRepeater2_tlb_req_0_ready),
    .io_tlb_resp_valid                (itlbRepeater2_tlb_resp_valid),
    .io_tlb_resp_bits_s2xlate         (itlbRepeater2_tlb_resp_bits_s2xlate),
    .io_tlb_resp_bits_s1_entry_tag    (itlbRepeater2_tlb_resp_bits_s1_entry_tag),
    .io_tlb_resp_bits_s1_entry_asid   (itlbRepeater2_tlb_resp_bits_s1_entry_asid),
    .io_tlb_resp_bits_s1_entry_vmid   (itlbRepeater2_tlb_resp_bits_s1_entry_vmid),
    .io_tlb_resp_bits_s1_entry_n      (itlbRepeater2_tlb_resp_bits_s1_entry_n),
    .io_tlb_resp_bits_s1_entry_pbmt   (itlbRepeater2_tlb_resp_bits_s1_entry_pbmt),
    .io_tlb_resp_bits_s1_entry_perm_d (itlbRepeater2_tlb_resp_bits_s1_entry_perm_d),
    .io_tlb_resp_bits_s1_entry_perm_a (itlbRepeater2_tlb_resp_bits_s1_entry_perm_a),
    .io_tlb_resp_bits_s1_entry_perm_g (itlbRepeater2_tlb_resp_bits_s1_entry_perm_g),
    .io_tlb_resp_bits_s1_entry_perm_u (itlbRepeater2_tlb_resp_bits_s1_entry_perm_u),
    .io_tlb_resp_bits_s1_entry_perm_x (itlbRepeater2_tlb_resp_bits_s1_entry_perm_x),
    .io_tlb_resp_bits_s1_entry_perm_w (itlbRepeater2_tlb_resp_bits_s1_entry_perm_w),
    .io_tlb_resp_bits_s1_entry_perm_r (itlbRepeater2_tlb_resp_bits_s1_entry_perm_r),
    .io_tlb_resp_bits_s1_entry_level  (itlbRepeater2_tlb_resp_bits_s1_entry_level),
    .io_tlb_resp_bits_s1_entry_v      (itlbRepeater2_tlb_resp_bits_s1_entry_v),
    .io_tlb_resp_bits_s1_entry_ppn    (itlbRepeater2_tlb_resp_bits_s1_entry_ppn),
    .io_tlb_resp_bits_s1_addr_low     (itlbRepeater2_tlb_resp_bits_s1_addr_low),
    .io_tlb_resp_bits_s1_ppn_low_0    (itlbRepeater2_tlb_resp_bits_s1_ppn_low_0),
    .io_tlb_resp_bits_s1_ppn_low_1    (itlbRepeater2_tlb_resp_bits_s1_ppn_low_1),
    .io_tlb_resp_bits_s1_ppn_low_2    (itlbRepeater2_tlb_resp_bits_s1_ppn_low_2),
    .io_tlb_resp_bits_s1_ppn_low_3    (itlbRepeater2_tlb_resp_bits_s1_ppn_low_3),
    .io_tlb_resp_bits_s1_ppn_low_4    (itlbRepeater2_tlb_resp_bits_s1_ppn_low_4),
    .io_tlb_resp_bits_s1_ppn_low_5    (itlbRepeater2_tlb_resp_bits_s1_ppn_low_5),
    .io_tlb_resp_bits_s1_ppn_low_6    (itlbRepeater2_tlb_resp_bits_s1_ppn_low_6),
    .io_tlb_resp_bits_s1_ppn_low_7    (itlbRepeater2_tlb_resp_bits_s1_ppn_low_7),
    .io_tlb_resp_bits_s1_valididx_0   (itlbRepeater2_tlb_resp_bits_s1_valididx_0),
    .io_tlb_resp_bits_s1_valididx_1   (itlbRepeater2_tlb_resp_bits_s1_valididx_1),
    .io_tlb_resp_bits_s1_valididx_2   (itlbRepeater2_tlb_resp_bits_s1_valididx_2),
    .io_tlb_resp_bits_s1_valididx_3   (itlbRepeater2_tlb_resp_bits_s1_valididx_3),
    .io_tlb_resp_bits_s1_valididx_4   (itlbRepeater2_tlb_resp_bits_s1_valididx_4),
    .io_tlb_resp_bits_s1_valididx_5   (itlbRepeater2_tlb_resp_bits_s1_valididx_5),
    .io_tlb_resp_bits_s1_valididx_6   (itlbRepeater2_tlb_resp_bits_s1_valididx_6),
    .io_tlb_resp_bits_s1_valididx_7   (itlbRepeater2_tlb_resp_bits_s1_valididx_7),
    .io_tlb_resp_bits_s1_pteidx_0     (itlbRepeater2_tlb_resp_bits_s1_pteidx_0),
    .io_tlb_resp_bits_s1_pteidx_1     (itlbRepeater2_tlb_resp_bits_s1_pteidx_1),
    .io_tlb_resp_bits_s1_pteidx_2     (itlbRepeater2_tlb_resp_bits_s1_pteidx_2),
    .io_tlb_resp_bits_s1_pteidx_3     (itlbRepeater2_tlb_resp_bits_s1_pteidx_3),
    .io_tlb_resp_bits_s1_pteidx_4     (itlbRepeater2_tlb_resp_bits_s1_pteidx_4),
    .io_tlb_resp_bits_s1_pteidx_5     (itlbRepeater2_tlb_resp_bits_s1_pteidx_5),
    .io_tlb_resp_bits_s1_pteidx_6     (itlbRepeater2_tlb_resp_bits_s1_pteidx_6),
    .io_tlb_resp_bits_s1_pteidx_7     (itlbRepeater2_tlb_resp_bits_s1_pteidx_7),
    .io_tlb_resp_bits_s1_pf           (itlbRepeater2_tlb_resp_bits_s1_pf),
    .io_tlb_resp_bits_s1_af           (itlbRepeater2_tlb_resp_bits_s1_af),
    .io_tlb_resp_bits_s2_entry_tag    (itlbRepeater2_tlb_resp_bits_s2_entry_tag),
    .io_tlb_resp_bits_s2_entry_vmid   (itlbRepeater2_tlb_resp_bits_s2_entry_vmid),
    .io_tlb_resp_bits_s2_entry_n      (itlbRepeater2_tlb_resp_bits_s2_entry_n),
    .io_tlb_resp_bits_s2_entry_pbmt   (itlbRepeater2_tlb_resp_bits_s2_entry_pbmt),
    .io_tlb_resp_bits_s2_entry_ppn    (itlbRepeater2_tlb_resp_bits_s2_entry_ppn),
    .io_tlb_resp_bits_s2_entry_perm_d (itlbRepeater2_tlb_resp_bits_s2_entry_perm_d),
    .io_tlb_resp_bits_s2_entry_perm_a (itlbRepeater2_tlb_resp_bits_s2_entry_perm_a),
    .io_tlb_resp_bits_s2_entry_perm_g (itlbRepeater2_tlb_resp_bits_s2_entry_perm_g),
    .io_tlb_resp_bits_s2_entry_perm_u (itlbRepeater2_tlb_resp_bits_s2_entry_perm_u),
    .io_tlb_resp_bits_s2_entry_perm_x (itlbRepeater2_tlb_resp_bits_s2_entry_perm_x),
    .io_tlb_resp_bits_s2_entry_perm_w (itlbRepeater2_tlb_resp_bits_s2_entry_perm_w),
    .io_tlb_resp_bits_s2_entry_perm_r (itlbRepeater2_tlb_resp_bits_s2_entry_perm_r),
    .io_tlb_resp_bits_s2_entry_level  (itlbRepeater2_tlb_resp_bits_s2_entry_level),
    .io_tlb_resp_bits_s2_gpf          (itlbRepeater2_tlb_resp_bits_s2_gpf),
    .io_tlb_resp_bits_s2_gaf          (itlbRepeater2_tlb_resp_bits_s2_gaf),
    // ---- ← itlbRepeater1：PTWFilter → PTWRepeaterNB（再打拍）→ L2TLB ----
    .io_tlb_req_0_valid               (itlbRepeater1_ptw_req_0_valid),
    .io_tlb_req_0_bits_vpn            (itlbRepeater1_ptw_req_0_bits_vpn),
    .io_tlb_req_0_bits_s2xlate        (itlbRepeater1_ptw_req_0_bits_s2xlate),
    // ---- 常量（golden 在本配置下钉死的输入） ----
    .io_tlb_resp_ready                (1'h1),
    // ---- 顶层 io_ptw* —— 与 L2TLB 的页表遍历请求 / 回应 ----
    .io_ptw_req_0_ready               (io_ptw_req_0_ready),
    .io_ptw_req_0_valid               (io_ptw_req_0_valid),
    .io_ptw_req_0_bits_vpn            (io_ptw_req_0_bits_vpn),
    .io_ptw_req_0_bits_s2xlate        (io_ptw_req_0_bits_s2xlate),
    .io_ptw_resp_ready                (io_ptw_resp_ready),
    .io_ptw_resp_valid                (io_ptw_resp_valid),
    .io_ptw_resp_bits_s2xlate         (io_ptw_resp_bits_s2xlate),
    .io_ptw_resp_bits_s1_entry_tag    (io_ptw_resp_bits_s1_entry_tag),
    .io_ptw_resp_bits_s1_entry_asid   (io_ptw_resp_bits_s1_entry_asid),
    .io_ptw_resp_bits_s1_entry_vmid   (io_ptw_resp_bits_s1_entry_vmid),
    .io_ptw_resp_bits_s1_entry_n      (io_ptw_resp_bits_s1_entry_n),
    .io_ptw_resp_bits_s1_entry_pbmt   (io_ptw_resp_bits_s1_entry_pbmt),
    .io_ptw_resp_bits_s1_entry_perm_d (io_ptw_resp_bits_s1_entry_perm_d),
    .io_ptw_resp_bits_s1_entry_perm_a (io_ptw_resp_bits_s1_entry_perm_a),
    .io_ptw_resp_bits_s1_entry_perm_g (io_ptw_resp_bits_s1_entry_perm_g),
    .io_ptw_resp_bits_s1_entry_perm_u (io_ptw_resp_bits_s1_entry_perm_u),
    .io_ptw_resp_bits_s1_entry_perm_x (io_ptw_resp_bits_s1_entry_perm_x),
    .io_ptw_resp_bits_s1_entry_perm_w (io_ptw_resp_bits_s1_entry_perm_w),
    .io_ptw_resp_bits_s1_entry_perm_r (io_ptw_resp_bits_s1_entry_perm_r),
    .io_ptw_resp_bits_s1_entry_level  (io_ptw_resp_bits_s1_entry_level),
    .io_ptw_resp_bits_s1_entry_v      (io_ptw_resp_bits_s1_entry_v),
    .io_ptw_resp_bits_s1_entry_ppn    (io_ptw_resp_bits_s1_entry_ppn),
    .io_ptw_resp_bits_s1_addr_low     (io_ptw_resp_bits_s1_addr_low),
    .io_ptw_resp_bits_s1_ppn_low_0    (io_ptw_resp_bits_s1_ppn_low_0),
    .io_ptw_resp_bits_s1_ppn_low_1    (io_ptw_resp_bits_s1_ppn_low_1),
    .io_ptw_resp_bits_s1_ppn_low_2    (io_ptw_resp_bits_s1_ppn_low_2),
    .io_ptw_resp_bits_s1_ppn_low_3    (io_ptw_resp_bits_s1_ppn_low_3),
    .io_ptw_resp_bits_s1_ppn_low_4    (io_ptw_resp_bits_s1_ppn_low_4),
    .io_ptw_resp_bits_s1_ppn_low_5    (io_ptw_resp_bits_s1_ppn_low_5),
    .io_ptw_resp_bits_s1_ppn_low_6    (io_ptw_resp_bits_s1_ppn_low_6),
    .io_ptw_resp_bits_s1_ppn_low_7    (io_ptw_resp_bits_s1_ppn_low_7),
    .io_ptw_resp_bits_s1_valididx_0   (io_ptw_resp_bits_s1_valididx_0),
    .io_ptw_resp_bits_s1_valididx_1   (io_ptw_resp_bits_s1_valididx_1),
    .io_ptw_resp_bits_s1_valididx_2   (io_ptw_resp_bits_s1_valididx_2),
    .io_ptw_resp_bits_s1_valididx_3   (io_ptw_resp_bits_s1_valididx_3),
    .io_ptw_resp_bits_s1_valididx_4   (io_ptw_resp_bits_s1_valididx_4),
    .io_ptw_resp_bits_s1_valididx_5   (io_ptw_resp_bits_s1_valididx_5),
    .io_ptw_resp_bits_s1_valididx_6   (io_ptw_resp_bits_s1_valididx_6),
    .io_ptw_resp_bits_s1_valididx_7   (io_ptw_resp_bits_s1_valididx_7),
    .io_ptw_resp_bits_s1_pteidx_0     (io_ptw_resp_bits_s1_pteidx_0),
    .io_ptw_resp_bits_s1_pteidx_1     (io_ptw_resp_bits_s1_pteidx_1),
    .io_ptw_resp_bits_s1_pteidx_2     (io_ptw_resp_bits_s1_pteidx_2),
    .io_ptw_resp_bits_s1_pteidx_3     (io_ptw_resp_bits_s1_pteidx_3),
    .io_ptw_resp_bits_s1_pteidx_4     (io_ptw_resp_bits_s1_pteidx_4),
    .io_ptw_resp_bits_s1_pteidx_5     (io_ptw_resp_bits_s1_pteidx_5),
    .io_ptw_resp_bits_s1_pteidx_6     (io_ptw_resp_bits_s1_pteidx_6),
    .io_ptw_resp_bits_s1_pteidx_7     (io_ptw_resp_bits_s1_pteidx_7),
    .io_ptw_resp_bits_s1_pf           (io_ptw_resp_bits_s1_pf),
    .io_ptw_resp_bits_s1_af           (io_ptw_resp_bits_s1_af),
    .io_ptw_resp_bits_s2_entry_tag    (io_ptw_resp_bits_s2_entry_tag),
    .io_ptw_resp_bits_s2_entry_vmid   (io_ptw_resp_bits_s2_entry_vmid),
    .io_ptw_resp_bits_s2_entry_n      (io_ptw_resp_bits_s2_entry_n),
    .io_ptw_resp_bits_s2_entry_pbmt   (io_ptw_resp_bits_s2_entry_pbmt),
    .io_ptw_resp_bits_s2_entry_ppn    (io_ptw_resp_bits_s2_entry_ppn),
    .io_ptw_resp_bits_s2_entry_perm_d (io_ptw_resp_bits_s2_entry_perm_d),
    .io_ptw_resp_bits_s2_entry_perm_a (io_ptw_resp_bits_s2_entry_perm_a),
    .io_ptw_resp_bits_s2_entry_perm_g (io_ptw_resp_bits_s2_entry_perm_g),
    .io_ptw_resp_bits_s2_entry_perm_u (io_ptw_resp_bits_s2_entry_perm_u),
    .io_ptw_resp_bits_s2_entry_perm_x (io_ptw_resp_bits_s2_entry_perm_x),
    .io_ptw_resp_bits_s2_entry_perm_w (io_ptw_resp_bits_s2_entry_perm_w),
    .io_ptw_resp_bits_s2_entry_perm_r (io_ptw_resp_bits_s2_entry_perm_r),
    .io_ptw_resp_bits_s2_entry_level  (io_ptw_resp_bits_s2_entry_level),
    .io_ptw_resp_bits_s2_gpf          (io_ptw_resp_bits_s2_gpf),
    .io_ptw_resp_bits_s2_gaf          (io_ptw_resp_bits_s2_gaf)
  );
  PMP inner_pmp (
    // ---- 时钟 / 复位 ----
    .clock                         (clock),
    .reset                         (reset),
    // ---- ← csrCtrlDelay：pmpcfg/pmpaddr 等 CSR 写广播（打两拍后） ----
    .io_distribute_csr_w_valid     (csrCtrlDelay_out_distribute_csr_w_valid),
    .io_distribute_csr_w_bits_addr (csrCtrlDelay_out_distribute_csr_w_bits_addr),
    .io_distribute_csr_w_bits_data (csrCtrlDelay_out_distribute_csr_w_bits_data),
    // ---- → pmpCheck0（PMP/PMA 表项给检查口 0）；pmpCheck1（PMP/PMA 表项给检查口 1）；pmpCheck2（PMP/PMA 表项给检查口 2）；pmpCheck3（PMP/PMA 表项给检查口 3）；pmpCheck4（PMP/PMA 表项给检查口 4） ----
    .io_pmp_0_cfg_l                (pmp_pmp_0_cfg_l),
    .io_pmp_0_cfg_a                (pmp_pmp_0_cfg_a),
    .io_pmp_0_cfg_x                (pmp_pmp_0_cfg_x),
    .io_pmp_0_addr                 (pmp_pmp_0_addr),
    .io_pmp_0_mask                 (pmp_pmp_0_mask),
    .io_pmp_1_cfg_l                (pmp_pmp_1_cfg_l),
    .io_pmp_1_cfg_a                (pmp_pmp_1_cfg_a),
    .io_pmp_1_cfg_x                (pmp_pmp_1_cfg_x),
    .io_pmp_1_addr                 (pmp_pmp_1_addr),
    .io_pmp_1_mask                 (pmp_pmp_1_mask),
    .io_pmp_2_cfg_l                (pmp_pmp_2_cfg_l),
    .io_pmp_2_cfg_a                (pmp_pmp_2_cfg_a),
    .io_pmp_2_cfg_x                (pmp_pmp_2_cfg_x),
    .io_pmp_2_addr                 (pmp_pmp_2_addr),
    .io_pmp_2_mask                 (pmp_pmp_2_mask),
    .io_pmp_3_cfg_l                (pmp_pmp_3_cfg_l),
    .io_pmp_3_cfg_a                (pmp_pmp_3_cfg_a),
    .io_pmp_3_cfg_x                (pmp_pmp_3_cfg_x),
    .io_pmp_3_addr                 (pmp_pmp_3_addr),
    .io_pmp_3_mask                 (pmp_pmp_3_mask),
    .io_pmp_4_cfg_l                (pmp_pmp_4_cfg_l),
    .io_pmp_4_cfg_a                (pmp_pmp_4_cfg_a),
    .io_pmp_4_cfg_x                (pmp_pmp_4_cfg_x),
    .io_pmp_4_addr                 (pmp_pmp_4_addr),
    .io_pmp_4_mask                 (pmp_pmp_4_mask),
    .io_pmp_5_cfg_l                (pmp_pmp_5_cfg_l),
    .io_pmp_5_cfg_a                (pmp_pmp_5_cfg_a),
    .io_pmp_5_cfg_x                (pmp_pmp_5_cfg_x),
    .io_pmp_5_addr                 (pmp_pmp_5_addr),
    .io_pmp_5_mask                 (pmp_pmp_5_mask),
    .io_pmp_6_cfg_l                (pmp_pmp_6_cfg_l),
    .io_pmp_6_cfg_a                (pmp_pmp_6_cfg_a),
    .io_pmp_6_cfg_x                (pmp_pmp_6_cfg_x),
    .io_pmp_6_addr                 (pmp_pmp_6_addr),
    .io_pmp_6_mask                 (pmp_pmp_6_mask),
    .io_pmp_7_cfg_l                (pmp_pmp_7_cfg_l),
    .io_pmp_7_cfg_a                (pmp_pmp_7_cfg_a),
    .io_pmp_7_cfg_x                (pmp_pmp_7_cfg_x),
    .io_pmp_7_addr                 (pmp_pmp_7_addr),
    .io_pmp_7_mask                 (pmp_pmp_7_mask),
    .io_pmp_8_cfg_l                (pmp_pmp_8_cfg_l),
    .io_pmp_8_cfg_a                (pmp_pmp_8_cfg_a),
    .io_pmp_8_cfg_x                (pmp_pmp_8_cfg_x),
    .io_pmp_8_addr                 (pmp_pmp_8_addr),
    .io_pmp_8_mask                 (pmp_pmp_8_mask),
    .io_pmp_9_cfg_l                (pmp_pmp_9_cfg_l),
    .io_pmp_9_cfg_a                (pmp_pmp_9_cfg_a),
    .io_pmp_9_cfg_x                (pmp_pmp_9_cfg_x),
    .io_pmp_9_addr                 (pmp_pmp_9_addr),
    .io_pmp_9_mask                 (pmp_pmp_9_mask),
    .io_pmp_10_cfg_l               (pmp_pmp_10_cfg_l),
    .io_pmp_10_cfg_a               (pmp_pmp_10_cfg_a),
    .io_pmp_10_cfg_x               (pmp_pmp_10_cfg_x),
    .io_pmp_10_addr                (pmp_pmp_10_addr),
    .io_pmp_10_mask                (pmp_pmp_10_mask),
    .io_pmp_11_cfg_l               (pmp_pmp_11_cfg_l),
    .io_pmp_11_cfg_a               (pmp_pmp_11_cfg_a),
    .io_pmp_11_cfg_x               (pmp_pmp_11_cfg_x),
    .io_pmp_11_addr                (pmp_pmp_11_addr),
    .io_pmp_11_mask                (pmp_pmp_11_mask),
    .io_pmp_12_cfg_l               (pmp_pmp_12_cfg_l),
    .io_pmp_12_cfg_a               (pmp_pmp_12_cfg_a),
    .io_pmp_12_cfg_x               (pmp_pmp_12_cfg_x),
    .io_pmp_12_addr                (pmp_pmp_12_addr),
    .io_pmp_12_mask                (pmp_pmp_12_mask),
    .io_pmp_13_cfg_l               (pmp_pmp_13_cfg_l),
    .io_pmp_13_cfg_a               (pmp_pmp_13_cfg_a),
    .io_pmp_13_cfg_x               (pmp_pmp_13_cfg_x),
    .io_pmp_13_addr                (pmp_pmp_13_addr),
    .io_pmp_13_mask                (pmp_pmp_13_mask),
    .io_pmp_14_cfg_l               (pmp_pmp_14_cfg_l),
    .io_pmp_14_cfg_a               (pmp_pmp_14_cfg_a),
    .io_pmp_14_cfg_x               (pmp_pmp_14_cfg_x),
    .io_pmp_14_addr                (pmp_pmp_14_addr),
    .io_pmp_14_mask                (pmp_pmp_14_mask),
    .io_pmp_15_cfg_l               (pmp_pmp_15_cfg_l),
    .io_pmp_15_cfg_a               (pmp_pmp_15_cfg_a),
    .io_pmp_15_cfg_x               (pmp_pmp_15_cfg_x),
    .io_pmp_15_addr                (pmp_pmp_15_addr),
    .io_pmp_15_mask                (pmp_pmp_15_mask),
    .io_pmp_16_cfg_l               (pmp_pmp_16_cfg_l),
    .io_pmp_16_cfg_a               (pmp_pmp_16_cfg_a),
    .io_pmp_16_cfg_x               (pmp_pmp_16_cfg_x),
    .io_pmp_16_addr                (pmp_pmp_16_addr),
    .io_pmp_16_mask                (pmp_pmp_16_mask),
    .io_pmp_17_cfg_l               (pmp_pmp_17_cfg_l),
    .io_pmp_17_cfg_a               (pmp_pmp_17_cfg_a),
    .io_pmp_17_cfg_x               (pmp_pmp_17_cfg_x),
    .io_pmp_17_addr                (pmp_pmp_17_addr),
    .io_pmp_17_mask                (pmp_pmp_17_mask),
    .io_pmp_18_cfg_l               (pmp_pmp_18_cfg_l),
    .io_pmp_18_cfg_a               (pmp_pmp_18_cfg_a),
    .io_pmp_18_cfg_x               (pmp_pmp_18_cfg_x),
    .io_pmp_18_addr                (pmp_pmp_18_addr),
    .io_pmp_18_mask                (pmp_pmp_18_mask),
    .io_pmp_19_cfg_l               (pmp_pmp_19_cfg_l),
    .io_pmp_19_cfg_a               (pmp_pmp_19_cfg_a),
    .io_pmp_19_cfg_x               (pmp_pmp_19_cfg_x),
    .io_pmp_19_addr                (pmp_pmp_19_addr),
    .io_pmp_19_mask                (pmp_pmp_19_mask),
    .io_pmp_20_cfg_l               (pmp_pmp_20_cfg_l),
    .io_pmp_20_cfg_a               (pmp_pmp_20_cfg_a),
    .io_pmp_20_cfg_x               (pmp_pmp_20_cfg_x),
    .io_pmp_20_addr                (pmp_pmp_20_addr),
    .io_pmp_20_mask                (pmp_pmp_20_mask),
    .io_pmp_21_cfg_l               (pmp_pmp_21_cfg_l),
    .io_pmp_21_cfg_a               (pmp_pmp_21_cfg_a),
    .io_pmp_21_cfg_x               (pmp_pmp_21_cfg_x),
    .io_pmp_21_addr                (pmp_pmp_21_addr),
    .io_pmp_21_mask                (pmp_pmp_21_mask),
    .io_pmp_22_cfg_l               (pmp_pmp_22_cfg_l),
    .io_pmp_22_cfg_a               (pmp_pmp_22_cfg_a),
    .io_pmp_22_cfg_x               (pmp_pmp_22_cfg_x),
    .io_pmp_22_addr                (pmp_pmp_22_addr),
    .io_pmp_22_mask                (pmp_pmp_22_mask),
    .io_pmp_23_cfg_l               (pmp_pmp_23_cfg_l),
    .io_pmp_23_cfg_a               (pmp_pmp_23_cfg_a),
    .io_pmp_23_cfg_x               (pmp_pmp_23_cfg_x),
    .io_pmp_23_addr                (pmp_pmp_23_addr),
    .io_pmp_23_mask                (pmp_pmp_23_mask),
    .io_pmp_24_cfg_l               (pmp_pmp_24_cfg_l),
    .io_pmp_24_cfg_a               (pmp_pmp_24_cfg_a),
    .io_pmp_24_cfg_x               (pmp_pmp_24_cfg_x),
    .io_pmp_24_addr                (pmp_pmp_24_addr),
    .io_pmp_24_mask                (pmp_pmp_24_mask),
    .io_pmp_25_cfg_l               (pmp_pmp_25_cfg_l),
    .io_pmp_25_cfg_a               (pmp_pmp_25_cfg_a),
    .io_pmp_25_cfg_x               (pmp_pmp_25_cfg_x),
    .io_pmp_25_addr                (pmp_pmp_25_addr),
    .io_pmp_25_mask                (pmp_pmp_25_mask),
    .io_pmp_26_cfg_l               (pmp_pmp_26_cfg_l),
    .io_pmp_26_cfg_a               (pmp_pmp_26_cfg_a),
    .io_pmp_26_cfg_x               (pmp_pmp_26_cfg_x),
    .io_pmp_26_addr                (pmp_pmp_26_addr),
    .io_pmp_26_mask                (pmp_pmp_26_mask),
    .io_pmp_27_cfg_l               (pmp_pmp_27_cfg_l),
    .io_pmp_27_cfg_a               (pmp_pmp_27_cfg_a),
    .io_pmp_27_cfg_x               (pmp_pmp_27_cfg_x),
    .io_pmp_27_addr                (pmp_pmp_27_addr),
    .io_pmp_27_mask                (pmp_pmp_27_mask),
    .io_pmp_28_cfg_l               (pmp_pmp_28_cfg_l),
    .io_pmp_28_cfg_a               (pmp_pmp_28_cfg_a),
    .io_pmp_28_cfg_x               (pmp_pmp_28_cfg_x),
    .io_pmp_28_addr                (pmp_pmp_28_addr),
    .io_pmp_28_mask                (pmp_pmp_28_mask),
    .io_pmp_29_cfg_l               (pmp_pmp_29_cfg_l),
    .io_pmp_29_cfg_a               (pmp_pmp_29_cfg_a),
    .io_pmp_29_cfg_x               (pmp_pmp_29_cfg_x),
    .io_pmp_29_addr                (pmp_pmp_29_addr),
    .io_pmp_29_mask                (pmp_pmp_29_mask),
    .io_pmp_30_cfg_l               (pmp_pmp_30_cfg_l),
    .io_pmp_30_cfg_a               (pmp_pmp_30_cfg_a),
    .io_pmp_30_cfg_x               (pmp_pmp_30_cfg_x),
    .io_pmp_30_addr                (pmp_pmp_30_addr),
    .io_pmp_30_mask                (pmp_pmp_30_mask),
    .io_pmp_31_cfg_l               (pmp_pmp_31_cfg_l),
    .io_pmp_31_cfg_a               (pmp_pmp_31_cfg_a),
    .io_pmp_31_cfg_x               (pmp_pmp_31_cfg_x),
    .io_pmp_31_addr                (pmp_pmp_31_addr),
    .io_pmp_31_mask                (pmp_pmp_31_mask),
    .io_pma_0_cfg_c                (pmp_pma_0_cfg_c),
    .io_pma_0_cfg_a                (pmp_pma_0_cfg_a),
    .io_pma_0_cfg_x                (pmp_pma_0_cfg_x),
    .io_pma_0_addr                 (pmp_pma_0_addr),
    .io_pma_0_mask                 (pmp_pma_0_mask),
    .io_pma_1_cfg_c                (pmp_pma_1_cfg_c),
    .io_pma_1_cfg_a                (pmp_pma_1_cfg_a),
    .io_pma_1_cfg_x                (pmp_pma_1_cfg_x),
    .io_pma_1_addr                 (pmp_pma_1_addr),
    .io_pma_1_mask                 (pmp_pma_1_mask),
    .io_pma_2_cfg_c                (pmp_pma_2_cfg_c),
    .io_pma_2_cfg_a                (pmp_pma_2_cfg_a),
    .io_pma_2_cfg_x                (pmp_pma_2_cfg_x),
    .io_pma_2_addr                 (pmp_pma_2_addr),
    .io_pma_2_mask                 (pmp_pma_2_mask),
    .io_pma_3_cfg_c                (pmp_pma_3_cfg_c),
    .io_pma_3_cfg_a                (pmp_pma_3_cfg_a),
    .io_pma_3_cfg_x                (pmp_pma_3_cfg_x),
    .io_pma_3_addr                 (pmp_pma_3_addr),
    .io_pma_3_mask                 (pmp_pma_3_mask),
    .io_pma_4_cfg_c                (pmp_pma_4_cfg_c),
    .io_pma_4_cfg_a                (pmp_pma_4_cfg_a),
    .io_pma_4_cfg_x                (pmp_pma_4_cfg_x),
    .io_pma_4_addr                 (pmp_pma_4_addr),
    .io_pma_4_mask                 (pmp_pma_4_mask),
    .io_pma_5_cfg_c                (pmp_pma_5_cfg_c),
    .io_pma_5_cfg_a                (pmp_pma_5_cfg_a),
    .io_pma_5_cfg_x                (pmp_pma_5_cfg_x),
    .io_pma_5_addr                 (pmp_pma_5_addr),
    .io_pma_5_mask                 (pmp_pma_5_mask),
    .io_pma_6_cfg_c                (pmp_pma_6_cfg_c),
    .io_pma_6_cfg_a                (pmp_pma_6_cfg_a),
    .io_pma_6_cfg_x                (pmp_pma_6_cfg_x),
    .io_pma_6_addr                 (pmp_pma_6_addr),
    .io_pma_6_mask                 (pmp_pma_6_mask),
    .io_pma_7_cfg_c                (pmp_pma_7_cfg_c),
    .io_pma_7_cfg_a                (pmp_pma_7_cfg_a),
    .io_pma_7_cfg_x                (pmp_pma_7_cfg_x),
    .io_pma_7_addr                 (pmp_pma_7_addr),
    .io_pma_7_mask                 (pmp_pma_7_mask),
    .io_pma_8_cfg_c                (pmp_pma_8_cfg_c),
    .io_pma_8_cfg_a                (pmp_pma_8_cfg_a),
    .io_pma_8_cfg_x                (pmp_pma_8_cfg_x),
    .io_pma_8_addr                 (pmp_pma_8_addr),
    .io_pma_8_mask                 (pmp_pma_8_mask),
    .io_pma_9_cfg_c                (pmp_pma_9_cfg_c),
    .io_pma_9_cfg_a                (pmp_pma_9_cfg_a),
    .io_pma_9_cfg_x                (pmp_pma_9_cfg_x),
    .io_pma_9_addr                 (pmp_pma_9_addr),
    .io_pma_9_mask                 (pmp_pma_9_mask),
    .io_pma_10_cfg_c               (pmp_pma_10_cfg_c),
    .io_pma_10_cfg_a               (pmp_pma_10_cfg_a),
    .io_pma_10_cfg_x               (pmp_pma_10_cfg_x),
    .io_pma_10_addr                (pmp_pma_10_addr),
    .io_pma_10_mask                (pmp_pma_10_mask),
    .io_pma_11_cfg_c               (pmp_pma_11_cfg_c),
    .io_pma_11_cfg_a               (pmp_pma_11_cfg_a),
    .io_pma_11_cfg_x               (pmp_pma_11_cfg_x),
    .io_pma_11_addr                (pmp_pma_11_addr),
    .io_pma_11_mask                (pmp_pma_11_mask),
    .io_pma_12_cfg_c               (pmp_pma_12_cfg_c),
    .io_pma_12_cfg_a               (pmp_pma_12_cfg_a),
    .io_pma_12_cfg_x               (pmp_pma_12_cfg_x),
    .io_pma_12_addr                (pmp_pma_12_addr),
    .io_pma_12_mask                (pmp_pma_12_mask),
    .io_pma_13_cfg_c               (pmp_pma_13_cfg_c),
    .io_pma_13_cfg_a               (pmp_pma_13_cfg_a),
    .io_pma_13_cfg_x               (pmp_pma_13_cfg_x),
    .io_pma_13_addr                (pmp_pma_13_addr),
    .io_pma_13_mask                (pmp_pma_13_mask),
    .io_pma_14_cfg_c               (pmp_pma_14_cfg_c),
    .io_pma_14_cfg_a               (pmp_pma_14_cfg_a),
    .io_pma_14_cfg_x               (pmp_pma_14_cfg_x),
    .io_pma_14_addr                (pmp_pma_14_addr),
    .io_pma_14_mask                (pmp_pma_14_mask),
    .io_pma_15_cfg_c               (pmp_pma_15_cfg_c),
    .io_pma_15_cfg_a               (pmp_pma_15_cfg_a),
    .io_pma_15_cfg_x               (pmp_pma_15_cfg_x),
    .io_pma_15_addr                (pmp_pma_15_addr),
    .io_pma_15_mask                (pmp_pma_15_mask),
    .io_pma_16_cfg_c               (pmp_pma_16_cfg_c),
    .io_pma_16_cfg_a               (pmp_pma_16_cfg_a),
    .io_pma_16_cfg_x               (pmp_pma_16_cfg_x),
    .io_pma_16_addr                (pmp_pma_16_addr),
    .io_pma_16_mask                (pmp_pma_16_mask),
    .io_pma_17_cfg_c               (pmp_pma_17_cfg_c),
    .io_pma_17_cfg_a               (pmp_pma_17_cfg_a),
    .io_pma_17_cfg_x               (pmp_pma_17_cfg_x),
    .io_pma_17_addr                (pmp_pma_17_addr),
    .io_pma_17_mask                (pmp_pma_17_mask),
    .io_pma_18_cfg_c               (pmp_pma_18_cfg_c),
    .io_pma_18_cfg_a               (pmp_pma_18_cfg_a),
    .io_pma_18_cfg_x               (pmp_pma_18_cfg_x),
    .io_pma_18_addr                (pmp_pma_18_addr),
    .io_pma_18_mask                (pmp_pma_18_mask),
    .io_pma_19_cfg_c               (pmp_pma_19_cfg_c),
    .io_pma_19_cfg_a               (pmp_pma_19_cfg_a),
    .io_pma_19_cfg_x               (pmp_pma_19_cfg_x),
    .io_pma_19_addr                (pmp_pma_19_addr),
    .io_pma_19_mask                (pmp_pma_19_mask),
    .io_pma_20_cfg_c               (pmp_pma_20_cfg_c),
    .io_pma_20_cfg_a               (pmp_pma_20_cfg_a),
    .io_pma_20_cfg_x               (pmp_pma_20_cfg_x),
    .io_pma_20_addr                (pmp_pma_20_addr),
    .io_pma_20_mask                (pmp_pma_20_mask),
    .io_pma_21_cfg_c               (pmp_pma_21_cfg_c),
    .io_pma_21_cfg_a               (pmp_pma_21_cfg_a),
    .io_pma_21_cfg_x               (pmp_pma_21_cfg_x),
    .io_pma_21_addr                (pmp_pma_21_addr),
    .io_pma_21_mask                (pmp_pma_21_mask),
    .io_pma_22_cfg_c               (pmp_pma_22_cfg_c),
    .io_pma_22_cfg_a               (pmp_pma_22_cfg_a),
    .io_pma_22_cfg_x               (pmp_pma_22_cfg_x),
    .io_pma_22_addr                (pmp_pma_22_addr),
    .io_pma_22_mask                (pmp_pma_22_mask),
    .io_pma_23_cfg_c               (pmp_pma_23_cfg_c),
    .io_pma_23_cfg_a               (pmp_pma_23_cfg_a),
    .io_pma_23_cfg_x               (pmp_pma_23_cfg_x),
    .io_pma_23_addr                (pmp_pma_23_addr),
    .io_pma_23_mask                (pmp_pma_23_mask),
    .io_pma_24_cfg_c               (pmp_pma_24_cfg_c),
    .io_pma_24_cfg_a               (pmp_pma_24_cfg_a),
    .io_pma_24_cfg_x               (pmp_pma_24_cfg_x),
    .io_pma_24_addr                (pmp_pma_24_addr),
    .io_pma_24_mask                (pmp_pma_24_mask),
    .io_pma_25_cfg_c               (pmp_pma_25_cfg_c),
    .io_pma_25_cfg_a               (pmp_pma_25_cfg_a),
    .io_pma_25_cfg_x               (pmp_pma_25_cfg_x),
    .io_pma_25_addr                (pmp_pma_25_addr),
    .io_pma_25_mask                (pmp_pma_25_mask),
    .io_pma_26_cfg_c               (pmp_pma_26_cfg_c),
    .io_pma_26_cfg_a               (pmp_pma_26_cfg_a),
    .io_pma_26_cfg_x               (pmp_pma_26_cfg_x),
    .io_pma_26_addr                (pmp_pma_26_addr),
    .io_pma_26_mask                (pmp_pma_26_mask),
    .io_pma_27_cfg_c               (pmp_pma_27_cfg_c),
    .io_pma_27_cfg_a               (pmp_pma_27_cfg_a),
    .io_pma_27_cfg_x               (pmp_pma_27_cfg_x),
    .io_pma_27_addr                (pmp_pma_27_addr),
    .io_pma_27_mask                (pmp_pma_27_mask),
    .io_pma_28_cfg_c               (pmp_pma_28_cfg_c),
    .io_pma_28_cfg_a               (pmp_pma_28_cfg_a),
    .io_pma_28_cfg_x               (pmp_pma_28_cfg_x),
    .io_pma_28_addr                (pmp_pma_28_addr),
    .io_pma_28_mask                (pmp_pma_28_mask),
    .io_pma_29_cfg_c               (pmp_pma_29_cfg_c),
    .io_pma_29_cfg_a               (pmp_pma_29_cfg_a),
    .io_pma_29_cfg_x               (pmp_pma_29_cfg_x),
    .io_pma_29_addr                (pmp_pma_29_addr),
    .io_pma_29_mask                (pmp_pma_29_mask),
    .io_pma_30_cfg_c               (pmp_pma_30_cfg_c),
    .io_pma_30_cfg_a               (pmp_pma_30_cfg_a),
    .io_pma_30_cfg_x               (pmp_pma_30_cfg_x),
    .io_pma_30_addr                (pmp_pma_30_addr),
    .io_pma_30_mask                (pmp_pma_30_mask),
    .io_pma_31_cfg_c               (pmp_pma_31_cfg_c),
    .io_pma_31_cfg_a               (pmp_pma_31_cfg_a),
    .io_pma_31_cfg_x               (pmp_pma_31_cfg_x),
    .io_pma_31_addr                (pmp_pma_31_addr),
    .io_pma_31_mask                (pmp_pma_31_mask),
    // ---- 无读者的输出（golden 同样悬空） ----
    .io_pmp_0_cfg_w                (),
    .io_pmp_0_cfg_r                (),
    .io_pmp_1_cfg_w                (),
    .io_pmp_1_cfg_r                (),
    .io_pmp_2_cfg_w                (),
    .io_pmp_2_cfg_r                (),
    .io_pmp_3_cfg_w                (),
    .io_pmp_3_cfg_r                (),
    .io_pmp_4_cfg_w                (),
    .io_pmp_4_cfg_r                (),
    .io_pmp_5_cfg_w                (),
    .io_pmp_5_cfg_r                (),
    .io_pmp_6_cfg_w                (),
    .io_pmp_6_cfg_r                (),
    .io_pmp_7_cfg_w                (),
    .io_pmp_7_cfg_r                (),
    .io_pmp_8_cfg_w                (),
    .io_pmp_8_cfg_r                (),
    .io_pmp_9_cfg_w                (),
    .io_pmp_9_cfg_r                (),
    .io_pmp_10_cfg_w               (),
    .io_pmp_10_cfg_r               (),
    .io_pmp_11_cfg_w               (),
    .io_pmp_11_cfg_r               (),
    .io_pmp_12_cfg_w               (),
    .io_pmp_12_cfg_r               (),
    .io_pmp_13_cfg_w               (),
    .io_pmp_13_cfg_r               (),
    .io_pmp_14_cfg_w               (),
    .io_pmp_14_cfg_r               (),
    .io_pmp_15_cfg_w               (),
    .io_pmp_15_cfg_r               (),
    .io_pmp_16_cfg_w               (),
    .io_pmp_16_cfg_r               (),
    .io_pmp_17_cfg_w               (),
    .io_pmp_17_cfg_r               (),
    .io_pmp_18_cfg_w               (),
    .io_pmp_18_cfg_r               (),
    .io_pmp_19_cfg_w               (),
    .io_pmp_19_cfg_r               (),
    .io_pmp_20_cfg_w               (),
    .io_pmp_20_cfg_r               (),
    .io_pmp_21_cfg_w               (),
    .io_pmp_21_cfg_r               (),
    .io_pmp_22_cfg_w               (),
    .io_pmp_22_cfg_r               (),
    .io_pmp_23_cfg_w               (),
    .io_pmp_23_cfg_r               (),
    .io_pmp_24_cfg_w               (),
    .io_pmp_24_cfg_r               (),
    .io_pmp_25_cfg_w               (),
    .io_pmp_25_cfg_r               (),
    .io_pmp_26_cfg_w               (),
    .io_pmp_26_cfg_r               (),
    .io_pmp_27_cfg_w               (),
    .io_pmp_27_cfg_r               (),
    .io_pmp_28_cfg_w               (),
    .io_pmp_28_cfg_r               (),
    .io_pmp_29_cfg_w               (),
    .io_pmp_29_cfg_r               (),
    .io_pmp_30_cfg_w               (),
    .io_pmp_30_cfg_r               (),
    .io_pmp_31_cfg_w               (),
    .io_pmp_31_cfg_r               (),
    .io_pma_0_cfg_atomic           (),
    .io_pma_0_cfg_w                (),
    .io_pma_0_cfg_r                (),
    .io_pma_1_cfg_atomic           (),
    .io_pma_1_cfg_w                (),
    .io_pma_1_cfg_r                (),
    .io_pma_2_cfg_atomic           (),
    .io_pma_2_cfg_w                (),
    .io_pma_2_cfg_r                (),
    .io_pma_3_cfg_atomic           (),
    .io_pma_3_cfg_w                (),
    .io_pma_3_cfg_r                (),
    .io_pma_4_cfg_atomic           (),
    .io_pma_4_cfg_w                (),
    .io_pma_4_cfg_r                (),
    .io_pma_5_cfg_atomic           (),
    .io_pma_5_cfg_w                (),
    .io_pma_5_cfg_r                (),
    .io_pma_6_cfg_atomic           (),
    .io_pma_6_cfg_w                (),
    .io_pma_6_cfg_r                (),
    .io_pma_7_cfg_atomic           (),
    .io_pma_7_cfg_w                (),
    .io_pma_7_cfg_r                (),
    .io_pma_8_cfg_atomic           (),
    .io_pma_8_cfg_w                (),
    .io_pma_8_cfg_r                (),
    .io_pma_9_cfg_atomic           (),
    .io_pma_9_cfg_w                (),
    .io_pma_9_cfg_r                (),
    .io_pma_10_cfg_atomic          (),
    .io_pma_10_cfg_w               (),
    .io_pma_10_cfg_r               (),
    .io_pma_11_cfg_atomic          (),
    .io_pma_11_cfg_w               (),
    .io_pma_11_cfg_r               (),
    .io_pma_12_cfg_atomic          (),
    .io_pma_12_cfg_w               (),
    .io_pma_12_cfg_r               (),
    .io_pma_13_cfg_atomic          (),
    .io_pma_13_cfg_w               (),
    .io_pma_13_cfg_r               (),
    .io_pma_14_cfg_atomic          (),
    .io_pma_14_cfg_w               (),
    .io_pma_14_cfg_r               (),
    .io_pma_15_cfg_atomic          (),
    .io_pma_15_cfg_w               (),
    .io_pma_15_cfg_r               (),
    .io_pma_16_cfg_atomic          (),
    .io_pma_16_cfg_w               (),
    .io_pma_16_cfg_r               (),
    .io_pma_17_cfg_atomic          (),
    .io_pma_17_cfg_w               (),
    .io_pma_17_cfg_r               (),
    .io_pma_18_cfg_atomic          (),
    .io_pma_18_cfg_w               (),
    .io_pma_18_cfg_r               (),
    .io_pma_19_cfg_atomic          (),
    .io_pma_19_cfg_w               (),
    .io_pma_19_cfg_r               (),
    .io_pma_20_cfg_atomic          (),
    .io_pma_20_cfg_w               (),
    .io_pma_20_cfg_r               (),
    .io_pma_21_cfg_atomic          (),
    .io_pma_21_cfg_w               (),
    .io_pma_21_cfg_r               (),
    .io_pma_22_cfg_atomic          (),
    .io_pma_22_cfg_w               (),
    .io_pma_22_cfg_r               (),
    .io_pma_23_cfg_atomic          (),
    .io_pma_23_cfg_w               (),
    .io_pma_23_cfg_r               (),
    .io_pma_24_cfg_atomic          (),
    .io_pma_24_cfg_w               (),
    .io_pma_24_cfg_r               (),
    .io_pma_25_cfg_atomic          (),
    .io_pma_25_cfg_w               (),
    .io_pma_25_cfg_r               (),
    .io_pma_26_cfg_atomic          (),
    .io_pma_26_cfg_w               (),
    .io_pma_26_cfg_r               (),
    .io_pma_27_cfg_atomic          (),
    .io_pma_27_cfg_w               (),
    .io_pma_27_cfg_r               (),
    .io_pma_28_cfg_atomic          (),
    .io_pma_28_cfg_w               (),
    .io_pma_28_cfg_r               (),
    .io_pma_29_cfg_atomic          (),
    .io_pma_29_cfg_w               (),
    .io_pma_29_cfg_r               (),
    .io_pma_30_cfg_atomic          (),
    .io_pma_30_cfg_w               (),
    .io_pma_30_cfg_r               (),
    .io_pma_31_cfg_atomic          (),
    .io_pma_31_cfg_w               (),
    .io_pma_31_cfg_r               ()
  );
  PMPChecker_2 inner_PMPChecker (
    // ---- 时钟 / 复位 ----
    .clock                     (clock),
    // ---- ← tlbCsrDelay：当前特权级 / debug（打两拍后） ----
    .io_check_env_mode         (tlbCsrDelay_out_priv_imode),
    .io_check_env_debug        (tlbCsrDelay_out_priv_debug),
    // ---- ← pmp：PMP/PMA 表项给检查口 0 ----
    .io_check_env_pmp_0_cfg_l  (pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a  (pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_x  (pmp_pmp_0_cfg_x),
    .io_check_env_pmp_0_addr   (pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask   (pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l  (pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a  (pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_x  (pmp_pmp_1_cfg_x),
    .io_check_env_pmp_1_addr   (pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask   (pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l  (pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a  (pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_x  (pmp_pmp_2_cfg_x),
    .io_check_env_pmp_2_addr   (pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask   (pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l  (pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a  (pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_x  (pmp_pmp_3_cfg_x),
    .io_check_env_pmp_3_addr   (pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask   (pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l  (pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a  (pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_x  (pmp_pmp_4_cfg_x),
    .io_check_env_pmp_4_addr   (pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask   (pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l  (pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a  (pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_x  (pmp_pmp_5_cfg_x),
    .io_check_env_pmp_5_addr   (pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask   (pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l  (pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a  (pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_x  (pmp_pmp_6_cfg_x),
    .io_check_env_pmp_6_addr   (pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask   (pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l  (pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a  (pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_x  (pmp_pmp_7_cfg_x),
    .io_check_env_pmp_7_addr   (pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask   (pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l  (pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a  (pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_x  (pmp_pmp_8_cfg_x),
    .io_check_env_pmp_8_addr   (pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask   (pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l  (pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a  (pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_x  (pmp_pmp_9_cfg_x),
    .io_check_env_pmp_9_addr   (pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask   (pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l (pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a (pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_x (pmp_pmp_10_cfg_x),
    .io_check_env_pmp_10_addr  (pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask  (pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l (pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a (pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_x (pmp_pmp_11_cfg_x),
    .io_check_env_pmp_11_addr  (pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask  (pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l (pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a (pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_x (pmp_pmp_12_cfg_x),
    .io_check_env_pmp_12_addr  (pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask  (pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l (pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a (pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_x (pmp_pmp_13_cfg_x),
    .io_check_env_pmp_13_addr  (pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask  (pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l (pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a (pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_x (pmp_pmp_14_cfg_x),
    .io_check_env_pmp_14_addr  (pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask  (pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l (pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a (pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_x (pmp_pmp_15_cfg_x),
    .io_check_env_pmp_15_addr  (pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask  (pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l (pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a (pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_x (pmp_pmp_16_cfg_x),
    .io_check_env_pmp_16_addr  (pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask  (pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l (pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a (pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_x (pmp_pmp_17_cfg_x),
    .io_check_env_pmp_17_addr  (pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask  (pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l (pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a (pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_x (pmp_pmp_18_cfg_x),
    .io_check_env_pmp_18_addr  (pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask  (pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l (pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a (pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_x (pmp_pmp_19_cfg_x),
    .io_check_env_pmp_19_addr  (pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask  (pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l (pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a (pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_x (pmp_pmp_20_cfg_x),
    .io_check_env_pmp_20_addr  (pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask  (pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l (pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a (pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_x (pmp_pmp_21_cfg_x),
    .io_check_env_pmp_21_addr  (pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask  (pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l (pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a (pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_x (pmp_pmp_22_cfg_x),
    .io_check_env_pmp_22_addr  (pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask  (pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l (pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a (pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_x (pmp_pmp_23_cfg_x),
    .io_check_env_pmp_23_addr  (pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask  (pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l (pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a (pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_x (pmp_pmp_24_cfg_x),
    .io_check_env_pmp_24_addr  (pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask  (pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l (pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a (pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_x (pmp_pmp_25_cfg_x),
    .io_check_env_pmp_25_addr  (pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask  (pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l (pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a (pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_x (pmp_pmp_26_cfg_x),
    .io_check_env_pmp_26_addr  (pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask  (pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l (pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a (pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_x (pmp_pmp_27_cfg_x),
    .io_check_env_pmp_27_addr  (pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask  (pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l (pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a (pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_x (pmp_pmp_28_cfg_x),
    .io_check_env_pmp_28_addr  (pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask  (pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l (pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a (pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_x (pmp_pmp_29_cfg_x),
    .io_check_env_pmp_29_addr  (pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask  (pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l (pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a (pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_x (pmp_pmp_30_cfg_x),
    .io_check_env_pmp_30_addr  (pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask  (pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l (pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a (pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_x (pmp_pmp_31_cfg_x),
    .io_check_env_pmp_31_addr  (pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask  (pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c  (pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_a  (pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_x  (pmp_pma_0_cfg_x),
    .io_check_env_pma_0_addr   (pmp_pma_0_addr),
    .io_check_env_pma_0_mask   (pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c  (pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_a  (pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_x  (pmp_pma_1_cfg_x),
    .io_check_env_pma_1_addr   (pmp_pma_1_addr),
    .io_check_env_pma_1_mask   (pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c  (pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_a  (pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_x  (pmp_pma_2_cfg_x),
    .io_check_env_pma_2_addr   (pmp_pma_2_addr),
    .io_check_env_pma_2_mask   (pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c  (pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_a  (pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_x  (pmp_pma_3_cfg_x),
    .io_check_env_pma_3_addr   (pmp_pma_3_addr),
    .io_check_env_pma_3_mask   (pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c  (pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_a  (pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_x  (pmp_pma_4_cfg_x),
    .io_check_env_pma_4_addr   (pmp_pma_4_addr),
    .io_check_env_pma_4_mask   (pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c  (pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_a  (pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_x  (pmp_pma_5_cfg_x),
    .io_check_env_pma_5_addr   (pmp_pma_5_addr),
    .io_check_env_pma_5_mask   (pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c  (pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_a  (pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_x  (pmp_pma_6_cfg_x),
    .io_check_env_pma_6_addr   (pmp_pma_6_addr),
    .io_check_env_pma_6_mask   (pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c  (pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_a  (pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_x  (pmp_pma_7_cfg_x),
    .io_check_env_pma_7_addr   (pmp_pma_7_addr),
    .io_check_env_pma_7_mask   (pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c  (pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_a  (pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_x  (pmp_pma_8_cfg_x),
    .io_check_env_pma_8_addr   (pmp_pma_8_addr),
    .io_check_env_pma_8_mask   (pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c  (pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_a  (pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_x  (pmp_pma_9_cfg_x),
    .io_check_env_pma_9_addr   (pmp_pma_9_addr),
    .io_check_env_pma_9_mask   (pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c (pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_a (pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_x (pmp_pma_10_cfg_x),
    .io_check_env_pma_10_addr  (pmp_pma_10_addr),
    .io_check_env_pma_10_mask  (pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c (pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_a (pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_x (pmp_pma_11_cfg_x),
    .io_check_env_pma_11_addr  (pmp_pma_11_addr),
    .io_check_env_pma_11_mask  (pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c (pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_a (pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_x (pmp_pma_12_cfg_x),
    .io_check_env_pma_12_addr  (pmp_pma_12_addr),
    .io_check_env_pma_12_mask  (pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c (pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_a (pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_x (pmp_pma_13_cfg_x),
    .io_check_env_pma_13_addr  (pmp_pma_13_addr),
    .io_check_env_pma_13_mask  (pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c (pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_a (pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_x (pmp_pma_14_cfg_x),
    .io_check_env_pma_14_addr  (pmp_pma_14_addr),
    .io_check_env_pma_14_mask  (pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c (pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_a (pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_x (pmp_pma_15_cfg_x),
    .io_check_env_pma_15_addr  (pmp_pma_15_addr),
    .io_check_env_pma_15_mask  (pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c (pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_a (pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_x (pmp_pma_16_cfg_x),
    .io_check_env_pma_16_addr  (pmp_pma_16_addr),
    .io_check_env_pma_16_mask  (pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c (pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_a (pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_x (pmp_pma_17_cfg_x),
    .io_check_env_pma_17_addr  (pmp_pma_17_addr),
    .io_check_env_pma_17_mask  (pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c (pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_a (pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_x (pmp_pma_18_cfg_x),
    .io_check_env_pma_18_addr  (pmp_pma_18_addr),
    .io_check_env_pma_18_mask  (pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c (pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_a (pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_x (pmp_pma_19_cfg_x),
    .io_check_env_pma_19_addr  (pmp_pma_19_addr),
    .io_check_env_pma_19_mask  (pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c (pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_a (pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_x (pmp_pma_20_cfg_x),
    .io_check_env_pma_20_addr  (pmp_pma_20_addr),
    .io_check_env_pma_20_mask  (pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c (pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_a (pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_x (pmp_pma_21_cfg_x),
    .io_check_env_pma_21_addr  (pmp_pma_21_addr),
    .io_check_env_pma_21_mask  (pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c (pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_a (pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_x (pmp_pma_22_cfg_x),
    .io_check_env_pma_22_addr  (pmp_pma_22_addr),
    .io_check_env_pma_22_mask  (pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c (pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_a (pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_x (pmp_pma_23_cfg_x),
    .io_check_env_pma_23_addr  (pmp_pma_23_addr),
    .io_check_env_pma_23_mask  (pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c (pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_a (pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_x (pmp_pma_24_cfg_x),
    .io_check_env_pma_24_addr  (pmp_pma_24_addr),
    .io_check_env_pma_24_mask  (pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c (pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_a (pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_x (pmp_pma_25_cfg_x),
    .io_check_env_pma_25_addr  (pmp_pma_25_addr),
    .io_check_env_pma_25_mask  (pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c (pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_a (pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_x (pmp_pma_26_cfg_x),
    .io_check_env_pma_26_addr  (pmp_pma_26_addr),
    .io_check_env_pma_26_mask  (pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c (pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_a (pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_x (pmp_pma_27_cfg_x),
    .io_check_env_pma_27_addr  (pmp_pma_27_addr),
    .io_check_env_pma_27_mask  (pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c (pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_a (pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_x (pmp_pma_28_cfg_x),
    .io_check_env_pma_28_addr  (pmp_pma_28_addr),
    .io_check_env_pma_28_mask  (pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c (pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_a (pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_x (pmp_pma_29_cfg_x),
    .io_check_env_pma_29_addr  (pmp_pma_29_addr),
    .io_check_env_pma_29_mask  (pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c (pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_a (pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_x (pmp_pma_30_cfg_x),
    .io_check_env_pma_30_addr  (pmp_pma_30_addr),
    .io_check_env_pma_30_mask  (pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c (pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_a (pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_x (pmp_pma_31_cfg_x),
    .io_check_env_pma_31_addr  (pmp_pma_31_addr),
    .io_check_env_pma_31_mask  (pmp_pma_31_mask),
    // ---- ← icache：ICache 物理地址权限检查口 0 ----
    .io_req_valid              (icache_pmp_0_req_valid),
    .io_req_bits_addr          (icache_pmp_0_req_bits_addr),
    // ---- → icache（ICache 物理地址权限检查口 0） ----
    .io_resp_instr             (pmpCheck0_resp_instr),
    .io_resp_mmio              (pmpCheck0_resp_mmio)
  );
  PMPChecker_2 inner_PMPChecker_1 (
    // ---- 时钟 / 复位 ----
    .clock                     (clock),
    // ---- ← tlbCsrDelay：当前特权级 / debug（打两拍后） ----
    .io_check_env_mode         (tlbCsrDelay_out_priv_imode),
    .io_check_env_debug        (tlbCsrDelay_out_priv_debug),
    // ---- ← pmp：PMP/PMA 表项给检查口 1 ----
    .io_check_env_pmp_0_cfg_l  (pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a  (pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_x  (pmp_pmp_0_cfg_x),
    .io_check_env_pmp_0_addr   (pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask   (pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l  (pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a  (pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_x  (pmp_pmp_1_cfg_x),
    .io_check_env_pmp_1_addr   (pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask   (pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l  (pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a  (pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_x  (pmp_pmp_2_cfg_x),
    .io_check_env_pmp_2_addr   (pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask   (pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l  (pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a  (pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_x  (pmp_pmp_3_cfg_x),
    .io_check_env_pmp_3_addr   (pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask   (pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l  (pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a  (pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_x  (pmp_pmp_4_cfg_x),
    .io_check_env_pmp_4_addr   (pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask   (pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l  (pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a  (pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_x  (pmp_pmp_5_cfg_x),
    .io_check_env_pmp_5_addr   (pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask   (pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l  (pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a  (pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_x  (pmp_pmp_6_cfg_x),
    .io_check_env_pmp_6_addr   (pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask   (pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l  (pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a  (pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_x  (pmp_pmp_7_cfg_x),
    .io_check_env_pmp_7_addr   (pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask   (pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l  (pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a  (pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_x  (pmp_pmp_8_cfg_x),
    .io_check_env_pmp_8_addr   (pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask   (pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l  (pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a  (pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_x  (pmp_pmp_9_cfg_x),
    .io_check_env_pmp_9_addr   (pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask   (pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l (pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a (pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_x (pmp_pmp_10_cfg_x),
    .io_check_env_pmp_10_addr  (pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask  (pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l (pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a (pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_x (pmp_pmp_11_cfg_x),
    .io_check_env_pmp_11_addr  (pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask  (pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l (pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a (pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_x (pmp_pmp_12_cfg_x),
    .io_check_env_pmp_12_addr  (pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask  (pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l (pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a (pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_x (pmp_pmp_13_cfg_x),
    .io_check_env_pmp_13_addr  (pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask  (pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l (pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a (pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_x (pmp_pmp_14_cfg_x),
    .io_check_env_pmp_14_addr  (pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask  (pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l (pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a (pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_x (pmp_pmp_15_cfg_x),
    .io_check_env_pmp_15_addr  (pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask  (pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l (pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a (pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_x (pmp_pmp_16_cfg_x),
    .io_check_env_pmp_16_addr  (pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask  (pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l (pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a (pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_x (pmp_pmp_17_cfg_x),
    .io_check_env_pmp_17_addr  (pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask  (pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l (pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a (pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_x (pmp_pmp_18_cfg_x),
    .io_check_env_pmp_18_addr  (pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask  (pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l (pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a (pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_x (pmp_pmp_19_cfg_x),
    .io_check_env_pmp_19_addr  (pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask  (pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l (pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a (pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_x (pmp_pmp_20_cfg_x),
    .io_check_env_pmp_20_addr  (pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask  (pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l (pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a (pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_x (pmp_pmp_21_cfg_x),
    .io_check_env_pmp_21_addr  (pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask  (pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l (pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a (pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_x (pmp_pmp_22_cfg_x),
    .io_check_env_pmp_22_addr  (pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask  (pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l (pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a (pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_x (pmp_pmp_23_cfg_x),
    .io_check_env_pmp_23_addr  (pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask  (pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l (pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a (pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_x (pmp_pmp_24_cfg_x),
    .io_check_env_pmp_24_addr  (pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask  (pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l (pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a (pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_x (pmp_pmp_25_cfg_x),
    .io_check_env_pmp_25_addr  (pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask  (pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l (pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a (pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_x (pmp_pmp_26_cfg_x),
    .io_check_env_pmp_26_addr  (pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask  (pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l (pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a (pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_x (pmp_pmp_27_cfg_x),
    .io_check_env_pmp_27_addr  (pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask  (pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l (pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a (pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_x (pmp_pmp_28_cfg_x),
    .io_check_env_pmp_28_addr  (pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask  (pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l (pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a (pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_x (pmp_pmp_29_cfg_x),
    .io_check_env_pmp_29_addr  (pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask  (pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l (pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a (pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_x (pmp_pmp_30_cfg_x),
    .io_check_env_pmp_30_addr  (pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask  (pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l (pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a (pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_x (pmp_pmp_31_cfg_x),
    .io_check_env_pmp_31_addr  (pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask  (pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c  (pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_a  (pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_x  (pmp_pma_0_cfg_x),
    .io_check_env_pma_0_addr   (pmp_pma_0_addr),
    .io_check_env_pma_0_mask   (pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c  (pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_a  (pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_x  (pmp_pma_1_cfg_x),
    .io_check_env_pma_1_addr   (pmp_pma_1_addr),
    .io_check_env_pma_1_mask   (pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c  (pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_a  (pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_x  (pmp_pma_2_cfg_x),
    .io_check_env_pma_2_addr   (pmp_pma_2_addr),
    .io_check_env_pma_2_mask   (pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c  (pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_a  (pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_x  (pmp_pma_3_cfg_x),
    .io_check_env_pma_3_addr   (pmp_pma_3_addr),
    .io_check_env_pma_3_mask   (pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c  (pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_a  (pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_x  (pmp_pma_4_cfg_x),
    .io_check_env_pma_4_addr   (pmp_pma_4_addr),
    .io_check_env_pma_4_mask   (pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c  (pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_a  (pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_x  (pmp_pma_5_cfg_x),
    .io_check_env_pma_5_addr   (pmp_pma_5_addr),
    .io_check_env_pma_5_mask   (pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c  (pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_a  (pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_x  (pmp_pma_6_cfg_x),
    .io_check_env_pma_6_addr   (pmp_pma_6_addr),
    .io_check_env_pma_6_mask   (pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c  (pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_a  (pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_x  (pmp_pma_7_cfg_x),
    .io_check_env_pma_7_addr   (pmp_pma_7_addr),
    .io_check_env_pma_7_mask   (pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c  (pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_a  (pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_x  (pmp_pma_8_cfg_x),
    .io_check_env_pma_8_addr   (pmp_pma_8_addr),
    .io_check_env_pma_8_mask   (pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c  (pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_a  (pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_x  (pmp_pma_9_cfg_x),
    .io_check_env_pma_9_addr   (pmp_pma_9_addr),
    .io_check_env_pma_9_mask   (pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c (pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_a (pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_x (pmp_pma_10_cfg_x),
    .io_check_env_pma_10_addr  (pmp_pma_10_addr),
    .io_check_env_pma_10_mask  (pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c (pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_a (pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_x (pmp_pma_11_cfg_x),
    .io_check_env_pma_11_addr  (pmp_pma_11_addr),
    .io_check_env_pma_11_mask  (pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c (pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_a (pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_x (pmp_pma_12_cfg_x),
    .io_check_env_pma_12_addr  (pmp_pma_12_addr),
    .io_check_env_pma_12_mask  (pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c (pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_a (pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_x (pmp_pma_13_cfg_x),
    .io_check_env_pma_13_addr  (pmp_pma_13_addr),
    .io_check_env_pma_13_mask  (pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c (pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_a (pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_x (pmp_pma_14_cfg_x),
    .io_check_env_pma_14_addr  (pmp_pma_14_addr),
    .io_check_env_pma_14_mask  (pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c (pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_a (pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_x (pmp_pma_15_cfg_x),
    .io_check_env_pma_15_addr  (pmp_pma_15_addr),
    .io_check_env_pma_15_mask  (pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c (pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_a (pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_x (pmp_pma_16_cfg_x),
    .io_check_env_pma_16_addr  (pmp_pma_16_addr),
    .io_check_env_pma_16_mask  (pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c (pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_a (pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_x (pmp_pma_17_cfg_x),
    .io_check_env_pma_17_addr  (pmp_pma_17_addr),
    .io_check_env_pma_17_mask  (pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c (pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_a (pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_x (pmp_pma_18_cfg_x),
    .io_check_env_pma_18_addr  (pmp_pma_18_addr),
    .io_check_env_pma_18_mask  (pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c (pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_a (pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_x (pmp_pma_19_cfg_x),
    .io_check_env_pma_19_addr  (pmp_pma_19_addr),
    .io_check_env_pma_19_mask  (pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c (pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_a (pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_x (pmp_pma_20_cfg_x),
    .io_check_env_pma_20_addr  (pmp_pma_20_addr),
    .io_check_env_pma_20_mask  (pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c (pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_a (pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_x (pmp_pma_21_cfg_x),
    .io_check_env_pma_21_addr  (pmp_pma_21_addr),
    .io_check_env_pma_21_mask  (pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c (pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_a (pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_x (pmp_pma_22_cfg_x),
    .io_check_env_pma_22_addr  (pmp_pma_22_addr),
    .io_check_env_pma_22_mask  (pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c (pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_a (pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_x (pmp_pma_23_cfg_x),
    .io_check_env_pma_23_addr  (pmp_pma_23_addr),
    .io_check_env_pma_23_mask  (pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c (pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_a (pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_x (pmp_pma_24_cfg_x),
    .io_check_env_pma_24_addr  (pmp_pma_24_addr),
    .io_check_env_pma_24_mask  (pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c (pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_a (pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_x (pmp_pma_25_cfg_x),
    .io_check_env_pma_25_addr  (pmp_pma_25_addr),
    .io_check_env_pma_25_mask  (pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c (pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_a (pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_x (pmp_pma_26_cfg_x),
    .io_check_env_pma_26_addr  (pmp_pma_26_addr),
    .io_check_env_pma_26_mask  (pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c (pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_a (pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_x (pmp_pma_27_cfg_x),
    .io_check_env_pma_27_addr  (pmp_pma_27_addr),
    .io_check_env_pma_27_mask  (pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c (pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_a (pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_x (pmp_pma_28_cfg_x),
    .io_check_env_pma_28_addr  (pmp_pma_28_addr),
    .io_check_env_pma_28_mask  (pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c (pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_a (pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_x (pmp_pma_29_cfg_x),
    .io_check_env_pma_29_addr  (pmp_pma_29_addr),
    .io_check_env_pma_29_mask  (pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c (pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_a (pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_x (pmp_pma_30_cfg_x),
    .io_check_env_pma_30_addr  (pmp_pma_30_addr),
    .io_check_env_pma_30_mask  (pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c (pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_a (pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_x (pmp_pma_31_cfg_x),
    .io_check_env_pma_31_addr  (pmp_pma_31_addr),
    .io_check_env_pma_31_mask  (pmp_pma_31_mask),
    // ---- ← icache：ICache 物理地址权限检查口 1 ----
    .io_req_valid              (icache_pmp_1_req_valid),
    .io_req_bits_addr          (icache_pmp_1_req_bits_addr),
    // ---- → icache（ICache 物理地址权限检查口 1） ----
    .io_resp_instr             (pmpCheck1_resp_instr),
    .io_resp_mmio              (pmpCheck1_resp_mmio)
  );
  PMPChecker_2 inner_PMPChecker_2 (
    // ---- 时钟 / 复位 ----
    .clock                     (clock),
    // ---- ← tlbCsrDelay：当前特权级 / debug（打两拍后） ----
    .io_check_env_mode         (tlbCsrDelay_out_priv_imode),
    .io_check_env_debug        (tlbCsrDelay_out_priv_debug),
    // ---- ← pmp：PMP/PMA 表项给检查口 2 ----
    .io_check_env_pmp_0_cfg_l  (pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a  (pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_x  (pmp_pmp_0_cfg_x),
    .io_check_env_pmp_0_addr   (pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask   (pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l  (pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a  (pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_x  (pmp_pmp_1_cfg_x),
    .io_check_env_pmp_1_addr   (pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask   (pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l  (pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a  (pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_x  (pmp_pmp_2_cfg_x),
    .io_check_env_pmp_2_addr   (pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask   (pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l  (pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a  (pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_x  (pmp_pmp_3_cfg_x),
    .io_check_env_pmp_3_addr   (pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask   (pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l  (pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a  (pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_x  (pmp_pmp_4_cfg_x),
    .io_check_env_pmp_4_addr   (pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask   (pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l  (pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a  (pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_x  (pmp_pmp_5_cfg_x),
    .io_check_env_pmp_5_addr   (pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask   (pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l  (pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a  (pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_x  (pmp_pmp_6_cfg_x),
    .io_check_env_pmp_6_addr   (pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask   (pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l  (pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a  (pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_x  (pmp_pmp_7_cfg_x),
    .io_check_env_pmp_7_addr   (pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask   (pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l  (pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a  (pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_x  (pmp_pmp_8_cfg_x),
    .io_check_env_pmp_8_addr   (pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask   (pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l  (pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a  (pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_x  (pmp_pmp_9_cfg_x),
    .io_check_env_pmp_9_addr   (pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask   (pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l (pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a (pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_x (pmp_pmp_10_cfg_x),
    .io_check_env_pmp_10_addr  (pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask  (pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l (pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a (pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_x (pmp_pmp_11_cfg_x),
    .io_check_env_pmp_11_addr  (pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask  (pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l (pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a (pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_x (pmp_pmp_12_cfg_x),
    .io_check_env_pmp_12_addr  (pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask  (pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l (pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a (pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_x (pmp_pmp_13_cfg_x),
    .io_check_env_pmp_13_addr  (pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask  (pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l (pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a (pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_x (pmp_pmp_14_cfg_x),
    .io_check_env_pmp_14_addr  (pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask  (pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l (pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a (pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_x (pmp_pmp_15_cfg_x),
    .io_check_env_pmp_15_addr  (pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask  (pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l (pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a (pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_x (pmp_pmp_16_cfg_x),
    .io_check_env_pmp_16_addr  (pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask  (pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l (pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a (pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_x (pmp_pmp_17_cfg_x),
    .io_check_env_pmp_17_addr  (pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask  (pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l (pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a (pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_x (pmp_pmp_18_cfg_x),
    .io_check_env_pmp_18_addr  (pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask  (pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l (pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a (pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_x (pmp_pmp_19_cfg_x),
    .io_check_env_pmp_19_addr  (pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask  (pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l (pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a (pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_x (pmp_pmp_20_cfg_x),
    .io_check_env_pmp_20_addr  (pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask  (pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l (pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a (pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_x (pmp_pmp_21_cfg_x),
    .io_check_env_pmp_21_addr  (pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask  (pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l (pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a (pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_x (pmp_pmp_22_cfg_x),
    .io_check_env_pmp_22_addr  (pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask  (pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l (pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a (pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_x (pmp_pmp_23_cfg_x),
    .io_check_env_pmp_23_addr  (pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask  (pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l (pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a (pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_x (pmp_pmp_24_cfg_x),
    .io_check_env_pmp_24_addr  (pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask  (pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l (pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a (pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_x (pmp_pmp_25_cfg_x),
    .io_check_env_pmp_25_addr  (pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask  (pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l (pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a (pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_x (pmp_pmp_26_cfg_x),
    .io_check_env_pmp_26_addr  (pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask  (pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l (pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a (pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_x (pmp_pmp_27_cfg_x),
    .io_check_env_pmp_27_addr  (pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask  (pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l (pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a (pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_x (pmp_pmp_28_cfg_x),
    .io_check_env_pmp_28_addr  (pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask  (pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l (pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a (pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_x (pmp_pmp_29_cfg_x),
    .io_check_env_pmp_29_addr  (pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask  (pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l (pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a (pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_x (pmp_pmp_30_cfg_x),
    .io_check_env_pmp_30_addr  (pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask  (pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l (pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a (pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_x (pmp_pmp_31_cfg_x),
    .io_check_env_pmp_31_addr  (pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask  (pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c  (pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_a  (pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_x  (pmp_pma_0_cfg_x),
    .io_check_env_pma_0_addr   (pmp_pma_0_addr),
    .io_check_env_pma_0_mask   (pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c  (pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_a  (pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_x  (pmp_pma_1_cfg_x),
    .io_check_env_pma_1_addr   (pmp_pma_1_addr),
    .io_check_env_pma_1_mask   (pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c  (pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_a  (pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_x  (pmp_pma_2_cfg_x),
    .io_check_env_pma_2_addr   (pmp_pma_2_addr),
    .io_check_env_pma_2_mask   (pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c  (pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_a  (pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_x  (pmp_pma_3_cfg_x),
    .io_check_env_pma_3_addr   (pmp_pma_3_addr),
    .io_check_env_pma_3_mask   (pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c  (pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_a  (pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_x  (pmp_pma_4_cfg_x),
    .io_check_env_pma_4_addr   (pmp_pma_4_addr),
    .io_check_env_pma_4_mask   (pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c  (pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_a  (pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_x  (pmp_pma_5_cfg_x),
    .io_check_env_pma_5_addr   (pmp_pma_5_addr),
    .io_check_env_pma_5_mask   (pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c  (pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_a  (pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_x  (pmp_pma_6_cfg_x),
    .io_check_env_pma_6_addr   (pmp_pma_6_addr),
    .io_check_env_pma_6_mask   (pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c  (pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_a  (pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_x  (pmp_pma_7_cfg_x),
    .io_check_env_pma_7_addr   (pmp_pma_7_addr),
    .io_check_env_pma_7_mask   (pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c  (pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_a  (pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_x  (pmp_pma_8_cfg_x),
    .io_check_env_pma_8_addr   (pmp_pma_8_addr),
    .io_check_env_pma_8_mask   (pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c  (pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_a  (pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_x  (pmp_pma_9_cfg_x),
    .io_check_env_pma_9_addr   (pmp_pma_9_addr),
    .io_check_env_pma_9_mask   (pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c (pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_a (pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_x (pmp_pma_10_cfg_x),
    .io_check_env_pma_10_addr  (pmp_pma_10_addr),
    .io_check_env_pma_10_mask  (pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c (pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_a (pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_x (pmp_pma_11_cfg_x),
    .io_check_env_pma_11_addr  (pmp_pma_11_addr),
    .io_check_env_pma_11_mask  (pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c (pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_a (pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_x (pmp_pma_12_cfg_x),
    .io_check_env_pma_12_addr  (pmp_pma_12_addr),
    .io_check_env_pma_12_mask  (pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c (pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_a (pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_x (pmp_pma_13_cfg_x),
    .io_check_env_pma_13_addr  (pmp_pma_13_addr),
    .io_check_env_pma_13_mask  (pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c (pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_a (pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_x (pmp_pma_14_cfg_x),
    .io_check_env_pma_14_addr  (pmp_pma_14_addr),
    .io_check_env_pma_14_mask  (pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c (pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_a (pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_x (pmp_pma_15_cfg_x),
    .io_check_env_pma_15_addr  (pmp_pma_15_addr),
    .io_check_env_pma_15_mask  (pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c (pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_a (pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_x (pmp_pma_16_cfg_x),
    .io_check_env_pma_16_addr  (pmp_pma_16_addr),
    .io_check_env_pma_16_mask  (pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c (pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_a (pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_x (pmp_pma_17_cfg_x),
    .io_check_env_pma_17_addr  (pmp_pma_17_addr),
    .io_check_env_pma_17_mask  (pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c (pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_a (pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_x (pmp_pma_18_cfg_x),
    .io_check_env_pma_18_addr  (pmp_pma_18_addr),
    .io_check_env_pma_18_mask  (pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c (pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_a (pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_x (pmp_pma_19_cfg_x),
    .io_check_env_pma_19_addr  (pmp_pma_19_addr),
    .io_check_env_pma_19_mask  (pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c (pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_a (pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_x (pmp_pma_20_cfg_x),
    .io_check_env_pma_20_addr  (pmp_pma_20_addr),
    .io_check_env_pma_20_mask  (pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c (pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_a (pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_x (pmp_pma_21_cfg_x),
    .io_check_env_pma_21_addr  (pmp_pma_21_addr),
    .io_check_env_pma_21_mask  (pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c (pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_a (pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_x (pmp_pma_22_cfg_x),
    .io_check_env_pma_22_addr  (pmp_pma_22_addr),
    .io_check_env_pma_22_mask  (pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c (pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_a (pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_x (pmp_pma_23_cfg_x),
    .io_check_env_pma_23_addr  (pmp_pma_23_addr),
    .io_check_env_pma_23_mask  (pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c (pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_a (pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_x (pmp_pma_24_cfg_x),
    .io_check_env_pma_24_addr  (pmp_pma_24_addr),
    .io_check_env_pma_24_mask  (pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c (pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_a (pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_x (pmp_pma_25_cfg_x),
    .io_check_env_pma_25_addr  (pmp_pma_25_addr),
    .io_check_env_pma_25_mask  (pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c (pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_a (pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_x (pmp_pma_26_cfg_x),
    .io_check_env_pma_26_addr  (pmp_pma_26_addr),
    .io_check_env_pma_26_mask  (pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c (pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_a (pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_x (pmp_pma_27_cfg_x),
    .io_check_env_pma_27_addr  (pmp_pma_27_addr),
    .io_check_env_pma_27_mask  (pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c (pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_a (pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_x (pmp_pma_28_cfg_x),
    .io_check_env_pma_28_addr  (pmp_pma_28_addr),
    .io_check_env_pma_28_mask  (pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c (pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_a (pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_x (pmp_pma_29_cfg_x),
    .io_check_env_pma_29_addr  (pmp_pma_29_addr),
    .io_check_env_pma_29_mask  (pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c (pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_a (pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_x (pmp_pma_30_cfg_x),
    .io_check_env_pma_30_addr  (pmp_pma_30_addr),
    .io_check_env_pma_30_mask  (pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c (pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_a (pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_x (pmp_pma_31_cfg_x),
    .io_check_env_pma_31_addr  (pmp_pma_31_addr),
    .io_check_env_pma_31_mask  (pmp_pma_31_mask),
    // ---- ← icache：ICache 物理地址权限检查口 2 ----
    .io_req_valid              (icache_pmp_2_req_valid),
    .io_req_bits_addr          (icache_pmp_2_req_bits_addr),
    // ---- → icache（ICache 物理地址权限检查口 2） ----
    .io_resp_instr             (pmpCheck2_resp_instr),
    .io_resp_mmio              (pmpCheck2_resp_mmio)
  );
  PMPChecker_2 inner_PMPChecker_3 (
    // ---- 时钟 / 复位 ----
    .clock                     (clock),
    // ---- ← tlbCsrDelay：当前特权级 / debug（打两拍后） ----
    .io_check_env_mode         (tlbCsrDelay_out_priv_imode),
    .io_check_env_debug        (tlbCsrDelay_out_priv_debug),
    // ---- ← pmp：PMP/PMA 表项给检查口 3 ----
    .io_check_env_pmp_0_cfg_l  (pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a  (pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_x  (pmp_pmp_0_cfg_x),
    .io_check_env_pmp_0_addr   (pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask   (pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l  (pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a  (pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_x  (pmp_pmp_1_cfg_x),
    .io_check_env_pmp_1_addr   (pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask   (pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l  (pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a  (pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_x  (pmp_pmp_2_cfg_x),
    .io_check_env_pmp_2_addr   (pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask   (pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l  (pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a  (pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_x  (pmp_pmp_3_cfg_x),
    .io_check_env_pmp_3_addr   (pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask   (pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l  (pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a  (pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_x  (pmp_pmp_4_cfg_x),
    .io_check_env_pmp_4_addr   (pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask   (pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l  (pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a  (pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_x  (pmp_pmp_5_cfg_x),
    .io_check_env_pmp_5_addr   (pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask   (pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l  (pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a  (pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_x  (pmp_pmp_6_cfg_x),
    .io_check_env_pmp_6_addr   (pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask   (pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l  (pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a  (pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_x  (pmp_pmp_7_cfg_x),
    .io_check_env_pmp_7_addr   (pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask   (pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l  (pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a  (pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_x  (pmp_pmp_8_cfg_x),
    .io_check_env_pmp_8_addr   (pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask   (pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l  (pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a  (pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_x  (pmp_pmp_9_cfg_x),
    .io_check_env_pmp_9_addr   (pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask   (pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l (pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a (pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_x (pmp_pmp_10_cfg_x),
    .io_check_env_pmp_10_addr  (pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask  (pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l (pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a (pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_x (pmp_pmp_11_cfg_x),
    .io_check_env_pmp_11_addr  (pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask  (pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l (pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a (pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_x (pmp_pmp_12_cfg_x),
    .io_check_env_pmp_12_addr  (pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask  (pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l (pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a (pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_x (pmp_pmp_13_cfg_x),
    .io_check_env_pmp_13_addr  (pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask  (pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l (pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a (pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_x (pmp_pmp_14_cfg_x),
    .io_check_env_pmp_14_addr  (pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask  (pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l (pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a (pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_x (pmp_pmp_15_cfg_x),
    .io_check_env_pmp_15_addr  (pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask  (pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l (pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a (pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_x (pmp_pmp_16_cfg_x),
    .io_check_env_pmp_16_addr  (pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask  (pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l (pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a (pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_x (pmp_pmp_17_cfg_x),
    .io_check_env_pmp_17_addr  (pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask  (pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l (pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a (pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_x (pmp_pmp_18_cfg_x),
    .io_check_env_pmp_18_addr  (pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask  (pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l (pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a (pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_x (pmp_pmp_19_cfg_x),
    .io_check_env_pmp_19_addr  (pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask  (pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l (pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a (pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_x (pmp_pmp_20_cfg_x),
    .io_check_env_pmp_20_addr  (pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask  (pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l (pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a (pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_x (pmp_pmp_21_cfg_x),
    .io_check_env_pmp_21_addr  (pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask  (pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l (pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a (pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_x (pmp_pmp_22_cfg_x),
    .io_check_env_pmp_22_addr  (pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask  (pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l (pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a (pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_x (pmp_pmp_23_cfg_x),
    .io_check_env_pmp_23_addr  (pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask  (pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l (pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a (pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_x (pmp_pmp_24_cfg_x),
    .io_check_env_pmp_24_addr  (pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask  (pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l (pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a (pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_x (pmp_pmp_25_cfg_x),
    .io_check_env_pmp_25_addr  (pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask  (pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l (pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a (pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_x (pmp_pmp_26_cfg_x),
    .io_check_env_pmp_26_addr  (pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask  (pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l (pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a (pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_x (pmp_pmp_27_cfg_x),
    .io_check_env_pmp_27_addr  (pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask  (pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l (pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a (pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_x (pmp_pmp_28_cfg_x),
    .io_check_env_pmp_28_addr  (pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask  (pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l (pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a (pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_x (pmp_pmp_29_cfg_x),
    .io_check_env_pmp_29_addr  (pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask  (pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l (pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a (pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_x (pmp_pmp_30_cfg_x),
    .io_check_env_pmp_30_addr  (pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask  (pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l (pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a (pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_x (pmp_pmp_31_cfg_x),
    .io_check_env_pmp_31_addr  (pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask  (pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c  (pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_a  (pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_x  (pmp_pma_0_cfg_x),
    .io_check_env_pma_0_addr   (pmp_pma_0_addr),
    .io_check_env_pma_0_mask   (pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c  (pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_a  (pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_x  (pmp_pma_1_cfg_x),
    .io_check_env_pma_1_addr   (pmp_pma_1_addr),
    .io_check_env_pma_1_mask   (pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c  (pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_a  (pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_x  (pmp_pma_2_cfg_x),
    .io_check_env_pma_2_addr   (pmp_pma_2_addr),
    .io_check_env_pma_2_mask   (pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c  (pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_a  (pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_x  (pmp_pma_3_cfg_x),
    .io_check_env_pma_3_addr   (pmp_pma_3_addr),
    .io_check_env_pma_3_mask   (pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c  (pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_a  (pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_x  (pmp_pma_4_cfg_x),
    .io_check_env_pma_4_addr   (pmp_pma_4_addr),
    .io_check_env_pma_4_mask   (pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c  (pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_a  (pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_x  (pmp_pma_5_cfg_x),
    .io_check_env_pma_5_addr   (pmp_pma_5_addr),
    .io_check_env_pma_5_mask   (pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c  (pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_a  (pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_x  (pmp_pma_6_cfg_x),
    .io_check_env_pma_6_addr   (pmp_pma_6_addr),
    .io_check_env_pma_6_mask   (pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c  (pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_a  (pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_x  (pmp_pma_7_cfg_x),
    .io_check_env_pma_7_addr   (pmp_pma_7_addr),
    .io_check_env_pma_7_mask   (pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c  (pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_a  (pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_x  (pmp_pma_8_cfg_x),
    .io_check_env_pma_8_addr   (pmp_pma_8_addr),
    .io_check_env_pma_8_mask   (pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c  (pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_a  (pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_x  (pmp_pma_9_cfg_x),
    .io_check_env_pma_9_addr   (pmp_pma_9_addr),
    .io_check_env_pma_9_mask   (pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c (pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_a (pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_x (pmp_pma_10_cfg_x),
    .io_check_env_pma_10_addr  (pmp_pma_10_addr),
    .io_check_env_pma_10_mask  (pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c (pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_a (pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_x (pmp_pma_11_cfg_x),
    .io_check_env_pma_11_addr  (pmp_pma_11_addr),
    .io_check_env_pma_11_mask  (pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c (pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_a (pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_x (pmp_pma_12_cfg_x),
    .io_check_env_pma_12_addr  (pmp_pma_12_addr),
    .io_check_env_pma_12_mask  (pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c (pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_a (pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_x (pmp_pma_13_cfg_x),
    .io_check_env_pma_13_addr  (pmp_pma_13_addr),
    .io_check_env_pma_13_mask  (pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c (pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_a (pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_x (pmp_pma_14_cfg_x),
    .io_check_env_pma_14_addr  (pmp_pma_14_addr),
    .io_check_env_pma_14_mask  (pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c (pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_a (pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_x (pmp_pma_15_cfg_x),
    .io_check_env_pma_15_addr  (pmp_pma_15_addr),
    .io_check_env_pma_15_mask  (pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c (pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_a (pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_x (pmp_pma_16_cfg_x),
    .io_check_env_pma_16_addr  (pmp_pma_16_addr),
    .io_check_env_pma_16_mask  (pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c (pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_a (pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_x (pmp_pma_17_cfg_x),
    .io_check_env_pma_17_addr  (pmp_pma_17_addr),
    .io_check_env_pma_17_mask  (pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c (pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_a (pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_x (pmp_pma_18_cfg_x),
    .io_check_env_pma_18_addr  (pmp_pma_18_addr),
    .io_check_env_pma_18_mask  (pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c (pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_a (pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_x (pmp_pma_19_cfg_x),
    .io_check_env_pma_19_addr  (pmp_pma_19_addr),
    .io_check_env_pma_19_mask  (pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c (pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_a (pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_x (pmp_pma_20_cfg_x),
    .io_check_env_pma_20_addr  (pmp_pma_20_addr),
    .io_check_env_pma_20_mask  (pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c (pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_a (pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_x (pmp_pma_21_cfg_x),
    .io_check_env_pma_21_addr  (pmp_pma_21_addr),
    .io_check_env_pma_21_mask  (pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c (pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_a (pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_x (pmp_pma_22_cfg_x),
    .io_check_env_pma_22_addr  (pmp_pma_22_addr),
    .io_check_env_pma_22_mask  (pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c (pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_a (pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_x (pmp_pma_23_cfg_x),
    .io_check_env_pma_23_addr  (pmp_pma_23_addr),
    .io_check_env_pma_23_mask  (pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c (pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_a (pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_x (pmp_pma_24_cfg_x),
    .io_check_env_pma_24_addr  (pmp_pma_24_addr),
    .io_check_env_pma_24_mask  (pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c (pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_a (pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_x (pmp_pma_25_cfg_x),
    .io_check_env_pma_25_addr  (pmp_pma_25_addr),
    .io_check_env_pma_25_mask  (pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c (pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_a (pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_x (pmp_pma_26_cfg_x),
    .io_check_env_pma_26_addr  (pmp_pma_26_addr),
    .io_check_env_pma_26_mask  (pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c (pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_a (pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_x (pmp_pma_27_cfg_x),
    .io_check_env_pma_27_addr  (pmp_pma_27_addr),
    .io_check_env_pma_27_mask  (pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c (pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_a (pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_x (pmp_pma_28_cfg_x),
    .io_check_env_pma_28_addr  (pmp_pma_28_addr),
    .io_check_env_pma_28_mask  (pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c (pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_a (pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_x (pmp_pma_29_cfg_x),
    .io_check_env_pma_29_addr  (pmp_pma_29_addr),
    .io_check_env_pma_29_mask  (pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c (pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_a (pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_x (pmp_pma_30_cfg_x),
    .io_check_env_pma_30_addr  (pmp_pma_30_addr),
    .io_check_env_pma_30_mask  (pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c (pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_a (pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_x (pmp_pma_31_cfg_x),
    .io_check_env_pma_31_addr  (pmp_pma_31_addr),
    .io_check_env_pma_31_mask  (pmp_pma_31_mask),
    // ---- ← icache：ICache 物理地址权限检查口 3 ----
    .io_req_valid              (icache_pmp_3_req_valid),
    .io_req_bits_addr          (icache_pmp_3_req_bits_addr),
    // ---- → icache（ICache 物理地址权限检查口 3） ----
    .io_resp_instr             (pmpCheck3_resp_instr),
    .io_resp_mmio              (pmpCheck3_resp_mmio)
  );
  PMPChecker_2 inner_PMPChecker_4 (
    // ---- 时钟 / 复位 ----
    .clock                     (clock),
    // ---- ← tlbCsrDelay：当前特权级 / debug（打两拍后） ----
    .io_check_env_mode         (tlbCsrDelay_out_priv_imode),
    .io_check_env_debug        (tlbCsrDelay_out_priv_debug),
    // ---- ← pmp：PMP/PMA 表项给检查口 4 ----
    .io_check_env_pmp_0_cfg_l  (pmp_pmp_0_cfg_l),
    .io_check_env_pmp_0_cfg_a  (pmp_pmp_0_cfg_a),
    .io_check_env_pmp_0_cfg_x  (pmp_pmp_0_cfg_x),
    .io_check_env_pmp_0_addr   (pmp_pmp_0_addr),
    .io_check_env_pmp_0_mask   (pmp_pmp_0_mask),
    .io_check_env_pmp_1_cfg_l  (pmp_pmp_1_cfg_l),
    .io_check_env_pmp_1_cfg_a  (pmp_pmp_1_cfg_a),
    .io_check_env_pmp_1_cfg_x  (pmp_pmp_1_cfg_x),
    .io_check_env_pmp_1_addr   (pmp_pmp_1_addr),
    .io_check_env_pmp_1_mask   (pmp_pmp_1_mask),
    .io_check_env_pmp_2_cfg_l  (pmp_pmp_2_cfg_l),
    .io_check_env_pmp_2_cfg_a  (pmp_pmp_2_cfg_a),
    .io_check_env_pmp_2_cfg_x  (pmp_pmp_2_cfg_x),
    .io_check_env_pmp_2_addr   (pmp_pmp_2_addr),
    .io_check_env_pmp_2_mask   (pmp_pmp_2_mask),
    .io_check_env_pmp_3_cfg_l  (pmp_pmp_3_cfg_l),
    .io_check_env_pmp_3_cfg_a  (pmp_pmp_3_cfg_a),
    .io_check_env_pmp_3_cfg_x  (pmp_pmp_3_cfg_x),
    .io_check_env_pmp_3_addr   (pmp_pmp_3_addr),
    .io_check_env_pmp_3_mask   (pmp_pmp_3_mask),
    .io_check_env_pmp_4_cfg_l  (pmp_pmp_4_cfg_l),
    .io_check_env_pmp_4_cfg_a  (pmp_pmp_4_cfg_a),
    .io_check_env_pmp_4_cfg_x  (pmp_pmp_4_cfg_x),
    .io_check_env_pmp_4_addr   (pmp_pmp_4_addr),
    .io_check_env_pmp_4_mask   (pmp_pmp_4_mask),
    .io_check_env_pmp_5_cfg_l  (pmp_pmp_5_cfg_l),
    .io_check_env_pmp_5_cfg_a  (pmp_pmp_5_cfg_a),
    .io_check_env_pmp_5_cfg_x  (pmp_pmp_5_cfg_x),
    .io_check_env_pmp_5_addr   (pmp_pmp_5_addr),
    .io_check_env_pmp_5_mask   (pmp_pmp_5_mask),
    .io_check_env_pmp_6_cfg_l  (pmp_pmp_6_cfg_l),
    .io_check_env_pmp_6_cfg_a  (pmp_pmp_6_cfg_a),
    .io_check_env_pmp_6_cfg_x  (pmp_pmp_6_cfg_x),
    .io_check_env_pmp_6_addr   (pmp_pmp_6_addr),
    .io_check_env_pmp_6_mask   (pmp_pmp_6_mask),
    .io_check_env_pmp_7_cfg_l  (pmp_pmp_7_cfg_l),
    .io_check_env_pmp_7_cfg_a  (pmp_pmp_7_cfg_a),
    .io_check_env_pmp_7_cfg_x  (pmp_pmp_7_cfg_x),
    .io_check_env_pmp_7_addr   (pmp_pmp_7_addr),
    .io_check_env_pmp_7_mask   (pmp_pmp_7_mask),
    .io_check_env_pmp_8_cfg_l  (pmp_pmp_8_cfg_l),
    .io_check_env_pmp_8_cfg_a  (pmp_pmp_8_cfg_a),
    .io_check_env_pmp_8_cfg_x  (pmp_pmp_8_cfg_x),
    .io_check_env_pmp_8_addr   (pmp_pmp_8_addr),
    .io_check_env_pmp_8_mask   (pmp_pmp_8_mask),
    .io_check_env_pmp_9_cfg_l  (pmp_pmp_9_cfg_l),
    .io_check_env_pmp_9_cfg_a  (pmp_pmp_9_cfg_a),
    .io_check_env_pmp_9_cfg_x  (pmp_pmp_9_cfg_x),
    .io_check_env_pmp_9_addr   (pmp_pmp_9_addr),
    .io_check_env_pmp_9_mask   (pmp_pmp_9_mask),
    .io_check_env_pmp_10_cfg_l (pmp_pmp_10_cfg_l),
    .io_check_env_pmp_10_cfg_a (pmp_pmp_10_cfg_a),
    .io_check_env_pmp_10_cfg_x (pmp_pmp_10_cfg_x),
    .io_check_env_pmp_10_addr  (pmp_pmp_10_addr),
    .io_check_env_pmp_10_mask  (pmp_pmp_10_mask),
    .io_check_env_pmp_11_cfg_l (pmp_pmp_11_cfg_l),
    .io_check_env_pmp_11_cfg_a (pmp_pmp_11_cfg_a),
    .io_check_env_pmp_11_cfg_x (pmp_pmp_11_cfg_x),
    .io_check_env_pmp_11_addr  (pmp_pmp_11_addr),
    .io_check_env_pmp_11_mask  (pmp_pmp_11_mask),
    .io_check_env_pmp_12_cfg_l (pmp_pmp_12_cfg_l),
    .io_check_env_pmp_12_cfg_a (pmp_pmp_12_cfg_a),
    .io_check_env_pmp_12_cfg_x (pmp_pmp_12_cfg_x),
    .io_check_env_pmp_12_addr  (pmp_pmp_12_addr),
    .io_check_env_pmp_12_mask  (pmp_pmp_12_mask),
    .io_check_env_pmp_13_cfg_l (pmp_pmp_13_cfg_l),
    .io_check_env_pmp_13_cfg_a (pmp_pmp_13_cfg_a),
    .io_check_env_pmp_13_cfg_x (pmp_pmp_13_cfg_x),
    .io_check_env_pmp_13_addr  (pmp_pmp_13_addr),
    .io_check_env_pmp_13_mask  (pmp_pmp_13_mask),
    .io_check_env_pmp_14_cfg_l (pmp_pmp_14_cfg_l),
    .io_check_env_pmp_14_cfg_a (pmp_pmp_14_cfg_a),
    .io_check_env_pmp_14_cfg_x (pmp_pmp_14_cfg_x),
    .io_check_env_pmp_14_addr  (pmp_pmp_14_addr),
    .io_check_env_pmp_14_mask  (pmp_pmp_14_mask),
    .io_check_env_pmp_15_cfg_l (pmp_pmp_15_cfg_l),
    .io_check_env_pmp_15_cfg_a (pmp_pmp_15_cfg_a),
    .io_check_env_pmp_15_cfg_x (pmp_pmp_15_cfg_x),
    .io_check_env_pmp_15_addr  (pmp_pmp_15_addr),
    .io_check_env_pmp_15_mask  (pmp_pmp_15_mask),
    .io_check_env_pmp_16_cfg_l (pmp_pmp_16_cfg_l),
    .io_check_env_pmp_16_cfg_a (pmp_pmp_16_cfg_a),
    .io_check_env_pmp_16_cfg_x (pmp_pmp_16_cfg_x),
    .io_check_env_pmp_16_addr  (pmp_pmp_16_addr),
    .io_check_env_pmp_16_mask  (pmp_pmp_16_mask),
    .io_check_env_pmp_17_cfg_l (pmp_pmp_17_cfg_l),
    .io_check_env_pmp_17_cfg_a (pmp_pmp_17_cfg_a),
    .io_check_env_pmp_17_cfg_x (pmp_pmp_17_cfg_x),
    .io_check_env_pmp_17_addr  (pmp_pmp_17_addr),
    .io_check_env_pmp_17_mask  (pmp_pmp_17_mask),
    .io_check_env_pmp_18_cfg_l (pmp_pmp_18_cfg_l),
    .io_check_env_pmp_18_cfg_a (pmp_pmp_18_cfg_a),
    .io_check_env_pmp_18_cfg_x (pmp_pmp_18_cfg_x),
    .io_check_env_pmp_18_addr  (pmp_pmp_18_addr),
    .io_check_env_pmp_18_mask  (pmp_pmp_18_mask),
    .io_check_env_pmp_19_cfg_l (pmp_pmp_19_cfg_l),
    .io_check_env_pmp_19_cfg_a (pmp_pmp_19_cfg_a),
    .io_check_env_pmp_19_cfg_x (pmp_pmp_19_cfg_x),
    .io_check_env_pmp_19_addr  (pmp_pmp_19_addr),
    .io_check_env_pmp_19_mask  (pmp_pmp_19_mask),
    .io_check_env_pmp_20_cfg_l (pmp_pmp_20_cfg_l),
    .io_check_env_pmp_20_cfg_a (pmp_pmp_20_cfg_a),
    .io_check_env_pmp_20_cfg_x (pmp_pmp_20_cfg_x),
    .io_check_env_pmp_20_addr  (pmp_pmp_20_addr),
    .io_check_env_pmp_20_mask  (pmp_pmp_20_mask),
    .io_check_env_pmp_21_cfg_l (pmp_pmp_21_cfg_l),
    .io_check_env_pmp_21_cfg_a (pmp_pmp_21_cfg_a),
    .io_check_env_pmp_21_cfg_x (pmp_pmp_21_cfg_x),
    .io_check_env_pmp_21_addr  (pmp_pmp_21_addr),
    .io_check_env_pmp_21_mask  (pmp_pmp_21_mask),
    .io_check_env_pmp_22_cfg_l (pmp_pmp_22_cfg_l),
    .io_check_env_pmp_22_cfg_a (pmp_pmp_22_cfg_a),
    .io_check_env_pmp_22_cfg_x (pmp_pmp_22_cfg_x),
    .io_check_env_pmp_22_addr  (pmp_pmp_22_addr),
    .io_check_env_pmp_22_mask  (pmp_pmp_22_mask),
    .io_check_env_pmp_23_cfg_l (pmp_pmp_23_cfg_l),
    .io_check_env_pmp_23_cfg_a (pmp_pmp_23_cfg_a),
    .io_check_env_pmp_23_cfg_x (pmp_pmp_23_cfg_x),
    .io_check_env_pmp_23_addr  (pmp_pmp_23_addr),
    .io_check_env_pmp_23_mask  (pmp_pmp_23_mask),
    .io_check_env_pmp_24_cfg_l (pmp_pmp_24_cfg_l),
    .io_check_env_pmp_24_cfg_a (pmp_pmp_24_cfg_a),
    .io_check_env_pmp_24_cfg_x (pmp_pmp_24_cfg_x),
    .io_check_env_pmp_24_addr  (pmp_pmp_24_addr),
    .io_check_env_pmp_24_mask  (pmp_pmp_24_mask),
    .io_check_env_pmp_25_cfg_l (pmp_pmp_25_cfg_l),
    .io_check_env_pmp_25_cfg_a (pmp_pmp_25_cfg_a),
    .io_check_env_pmp_25_cfg_x (pmp_pmp_25_cfg_x),
    .io_check_env_pmp_25_addr  (pmp_pmp_25_addr),
    .io_check_env_pmp_25_mask  (pmp_pmp_25_mask),
    .io_check_env_pmp_26_cfg_l (pmp_pmp_26_cfg_l),
    .io_check_env_pmp_26_cfg_a (pmp_pmp_26_cfg_a),
    .io_check_env_pmp_26_cfg_x (pmp_pmp_26_cfg_x),
    .io_check_env_pmp_26_addr  (pmp_pmp_26_addr),
    .io_check_env_pmp_26_mask  (pmp_pmp_26_mask),
    .io_check_env_pmp_27_cfg_l (pmp_pmp_27_cfg_l),
    .io_check_env_pmp_27_cfg_a (pmp_pmp_27_cfg_a),
    .io_check_env_pmp_27_cfg_x (pmp_pmp_27_cfg_x),
    .io_check_env_pmp_27_addr  (pmp_pmp_27_addr),
    .io_check_env_pmp_27_mask  (pmp_pmp_27_mask),
    .io_check_env_pmp_28_cfg_l (pmp_pmp_28_cfg_l),
    .io_check_env_pmp_28_cfg_a (pmp_pmp_28_cfg_a),
    .io_check_env_pmp_28_cfg_x (pmp_pmp_28_cfg_x),
    .io_check_env_pmp_28_addr  (pmp_pmp_28_addr),
    .io_check_env_pmp_28_mask  (pmp_pmp_28_mask),
    .io_check_env_pmp_29_cfg_l (pmp_pmp_29_cfg_l),
    .io_check_env_pmp_29_cfg_a (pmp_pmp_29_cfg_a),
    .io_check_env_pmp_29_cfg_x (pmp_pmp_29_cfg_x),
    .io_check_env_pmp_29_addr  (pmp_pmp_29_addr),
    .io_check_env_pmp_29_mask  (pmp_pmp_29_mask),
    .io_check_env_pmp_30_cfg_l (pmp_pmp_30_cfg_l),
    .io_check_env_pmp_30_cfg_a (pmp_pmp_30_cfg_a),
    .io_check_env_pmp_30_cfg_x (pmp_pmp_30_cfg_x),
    .io_check_env_pmp_30_addr  (pmp_pmp_30_addr),
    .io_check_env_pmp_30_mask  (pmp_pmp_30_mask),
    .io_check_env_pmp_31_cfg_l (pmp_pmp_31_cfg_l),
    .io_check_env_pmp_31_cfg_a (pmp_pmp_31_cfg_a),
    .io_check_env_pmp_31_cfg_x (pmp_pmp_31_cfg_x),
    .io_check_env_pmp_31_addr  (pmp_pmp_31_addr),
    .io_check_env_pmp_31_mask  (pmp_pmp_31_mask),
    .io_check_env_pma_0_cfg_c  (pmp_pma_0_cfg_c),
    .io_check_env_pma_0_cfg_a  (pmp_pma_0_cfg_a),
    .io_check_env_pma_0_cfg_x  (pmp_pma_0_cfg_x),
    .io_check_env_pma_0_addr   (pmp_pma_0_addr),
    .io_check_env_pma_0_mask   (pmp_pma_0_mask),
    .io_check_env_pma_1_cfg_c  (pmp_pma_1_cfg_c),
    .io_check_env_pma_1_cfg_a  (pmp_pma_1_cfg_a),
    .io_check_env_pma_1_cfg_x  (pmp_pma_1_cfg_x),
    .io_check_env_pma_1_addr   (pmp_pma_1_addr),
    .io_check_env_pma_1_mask   (pmp_pma_1_mask),
    .io_check_env_pma_2_cfg_c  (pmp_pma_2_cfg_c),
    .io_check_env_pma_2_cfg_a  (pmp_pma_2_cfg_a),
    .io_check_env_pma_2_cfg_x  (pmp_pma_2_cfg_x),
    .io_check_env_pma_2_addr   (pmp_pma_2_addr),
    .io_check_env_pma_2_mask   (pmp_pma_2_mask),
    .io_check_env_pma_3_cfg_c  (pmp_pma_3_cfg_c),
    .io_check_env_pma_3_cfg_a  (pmp_pma_3_cfg_a),
    .io_check_env_pma_3_cfg_x  (pmp_pma_3_cfg_x),
    .io_check_env_pma_3_addr   (pmp_pma_3_addr),
    .io_check_env_pma_3_mask   (pmp_pma_3_mask),
    .io_check_env_pma_4_cfg_c  (pmp_pma_4_cfg_c),
    .io_check_env_pma_4_cfg_a  (pmp_pma_4_cfg_a),
    .io_check_env_pma_4_cfg_x  (pmp_pma_4_cfg_x),
    .io_check_env_pma_4_addr   (pmp_pma_4_addr),
    .io_check_env_pma_4_mask   (pmp_pma_4_mask),
    .io_check_env_pma_5_cfg_c  (pmp_pma_5_cfg_c),
    .io_check_env_pma_5_cfg_a  (pmp_pma_5_cfg_a),
    .io_check_env_pma_5_cfg_x  (pmp_pma_5_cfg_x),
    .io_check_env_pma_5_addr   (pmp_pma_5_addr),
    .io_check_env_pma_5_mask   (pmp_pma_5_mask),
    .io_check_env_pma_6_cfg_c  (pmp_pma_6_cfg_c),
    .io_check_env_pma_6_cfg_a  (pmp_pma_6_cfg_a),
    .io_check_env_pma_6_cfg_x  (pmp_pma_6_cfg_x),
    .io_check_env_pma_6_addr   (pmp_pma_6_addr),
    .io_check_env_pma_6_mask   (pmp_pma_6_mask),
    .io_check_env_pma_7_cfg_c  (pmp_pma_7_cfg_c),
    .io_check_env_pma_7_cfg_a  (pmp_pma_7_cfg_a),
    .io_check_env_pma_7_cfg_x  (pmp_pma_7_cfg_x),
    .io_check_env_pma_7_addr   (pmp_pma_7_addr),
    .io_check_env_pma_7_mask   (pmp_pma_7_mask),
    .io_check_env_pma_8_cfg_c  (pmp_pma_8_cfg_c),
    .io_check_env_pma_8_cfg_a  (pmp_pma_8_cfg_a),
    .io_check_env_pma_8_cfg_x  (pmp_pma_8_cfg_x),
    .io_check_env_pma_8_addr   (pmp_pma_8_addr),
    .io_check_env_pma_8_mask   (pmp_pma_8_mask),
    .io_check_env_pma_9_cfg_c  (pmp_pma_9_cfg_c),
    .io_check_env_pma_9_cfg_a  (pmp_pma_9_cfg_a),
    .io_check_env_pma_9_cfg_x  (pmp_pma_9_cfg_x),
    .io_check_env_pma_9_addr   (pmp_pma_9_addr),
    .io_check_env_pma_9_mask   (pmp_pma_9_mask),
    .io_check_env_pma_10_cfg_c (pmp_pma_10_cfg_c),
    .io_check_env_pma_10_cfg_a (pmp_pma_10_cfg_a),
    .io_check_env_pma_10_cfg_x (pmp_pma_10_cfg_x),
    .io_check_env_pma_10_addr  (pmp_pma_10_addr),
    .io_check_env_pma_10_mask  (pmp_pma_10_mask),
    .io_check_env_pma_11_cfg_c (pmp_pma_11_cfg_c),
    .io_check_env_pma_11_cfg_a (pmp_pma_11_cfg_a),
    .io_check_env_pma_11_cfg_x (pmp_pma_11_cfg_x),
    .io_check_env_pma_11_addr  (pmp_pma_11_addr),
    .io_check_env_pma_11_mask  (pmp_pma_11_mask),
    .io_check_env_pma_12_cfg_c (pmp_pma_12_cfg_c),
    .io_check_env_pma_12_cfg_a (pmp_pma_12_cfg_a),
    .io_check_env_pma_12_cfg_x (pmp_pma_12_cfg_x),
    .io_check_env_pma_12_addr  (pmp_pma_12_addr),
    .io_check_env_pma_12_mask  (pmp_pma_12_mask),
    .io_check_env_pma_13_cfg_c (pmp_pma_13_cfg_c),
    .io_check_env_pma_13_cfg_a (pmp_pma_13_cfg_a),
    .io_check_env_pma_13_cfg_x (pmp_pma_13_cfg_x),
    .io_check_env_pma_13_addr  (pmp_pma_13_addr),
    .io_check_env_pma_13_mask  (pmp_pma_13_mask),
    .io_check_env_pma_14_cfg_c (pmp_pma_14_cfg_c),
    .io_check_env_pma_14_cfg_a (pmp_pma_14_cfg_a),
    .io_check_env_pma_14_cfg_x (pmp_pma_14_cfg_x),
    .io_check_env_pma_14_addr  (pmp_pma_14_addr),
    .io_check_env_pma_14_mask  (pmp_pma_14_mask),
    .io_check_env_pma_15_cfg_c (pmp_pma_15_cfg_c),
    .io_check_env_pma_15_cfg_a (pmp_pma_15_cfg_a),
    .io_check_env_pma_15_cfg_x (pmp_pma_15_cfg_x),
    .io_check_env_pma_15_addr  (pmp_pma_15_addr),
    .io_check_env_pma_15_mask  (pmp_pma_15_mask),
    .io_check_env_pma_16_cfg_c (pmp_pma_16_cfg_c),
    .io_check_env_pma_16_cfg_a (pmp_pma_16_cfg_a),
    .io_check_env_pma_16_cfg_x (pmp_pma_16_cfg_x),
    .io_check_env_pma_16_addr  (pmp_pma_16_addr),
    .io_check_env_pma_16_mask  (pmp_pma_16_mask),
    .io_check_env_pma_17_cfg_c (pmp_pma_17_cfg_c),
    .io_check_env_pma_17_cfg_a (pmp_pma_17_cfg_a),
    .io_check_env_pma_17_cfg_x (pmp_pma_17_cfg_x),
    .io_check_env_pma_17_addr  (pmp_pma_17_addr),
    .io_check_env_pma_17_mask  (pmp_pma_17_mask),
    .io_check_env_pma_18_cfg_c (pmp_pma_18_cfg_c),
    .io_check_env_pma_18_cfg_a (pmp_pma_18_cfg_a),
    .io_check_env_pma_18_cfg_x (pmp_pma_18_cfg_x),
    .io_check_env_pma_18_addr  (pmp_pma_18_addr),
    .io_check_env_pma_18_mask  (pmp_pma_18_mask),
    .io_check_env_pma_19_cfg_c (pmp_pma_19_cfg_c),
    .io_check_env_pma_19_cfg_a (pmp_pma_19_cfg_a),
    .io_check_env_pma_19_cfg_x (pmp_pma_19_cfg_x),
    .io_check_env_pma_19_addr  (pmp_pma_19_addr),
    .io_check_env_pma_19_mask  (pmp_pma_19_mask),
    .io_check_env_pma_20_cfg_c (pmp_pma_20_cfg_c),
    .io_check_env_pma_20_cfg_a (pmp_pma_20_cfg_a),
    .io_check_env_pma_20_cfg_x (pmp_pma_20_cfg_x),
    .io_check_env_pma_20_addr  (pmp_pma_20_addr),
    .io_check_env_pma_20_mask  (pmp_pma_20_mask),
    .io_check_env_pma_21_cfg_c (pmp_pma_21_cfg_c),
    .io_check_env_pma_21_cfg_a (pmp_pma_21_cfg_a),
    .io_check_env_pma_21_cfg_x (pmp_pma_21_cfg_x),
    .io_check_env_pma_21_addr  (pmp_pma_21_addr),
    .io_check_env_pma_21_mask  (pmp_pma_21_mask),
    .io_check_env_pma_22_cfg_c (pmp_pma_22_cfg_c),
    .io_check_env_pma_22_cfg_a (pmp_pma_22_cfg_a),
    .io_check_env_pma_22_cfg_x (pmp_pma_22_cfg_x),
    .io_check_env_pma_22_addr  (pmp_pma_22_addr),
    .io_check_env_pma_22_mask  (pmp_pma_22_mask),
    .io_check_env_pma_23_cfg_c (pmp_pma_23_cfg_c),
    .io_check_env_pma_23_cfg_a (pmp_pma_23_cfg_a),
    .io_check_env_pma_23_cfg_x (pmp_pma_23_cfg_x),
    .io_check_env_pma_23_addr  (pmp_pma_23_addr),
    .io_check_env_pma_23_mask  (pmp_pma_23_mask),
    .io_check_env_pma_24_cfg_c (pmp_pma_24_cfg_c),
    .io_check_env_pma_24_cfg_a (pmp_pma_24_cfg_a),
    .io_check_env_pma_24_cfg_x (pmp_pma_24_cfg_x),
    .io_check_env_pma_24_addr  (pmp_pma_24_addr),
    .io_check_env_pma_24_mask  (pmp_pma_24_mask),
    .io_check_env_pma_25_cfg_c (pmp_pma_25_cfg_c),
    .io_check_env_pma_25_cfg_a (pmp_pma_25_cfg_a),
    .io_check_env_pma_25_cfg_x (pmp_pma_25_cfg_x),
    .io_check_env_pma_25_addr  (pmp_pma_25_addr),
    .io_check_env_pma_25_mask  (pmp_pma_25_mask),
    .io_check_env_pma_26_cfg_c (pmp_pma_26_cfg_c),
    .io_check_env_pma_26_cfg_a (pmp_pma_26_cfg_a),
    .io_check_env_pma_26_cfg_x (pmp_pma_26_cfg_x),
    .io_check_env_pma_26_addr  (pmp_pma_26_addr),
    .io_check_env_pma_26_mask  (pmp_pma_26_mask),
    .io_check_env_pma_27_cfg_c (pmp_pma_27_cfg_c),
    .io_check_env_pma_27_cfg_a (pmp_pma_27_cfg_a),
    .io_check_env_pma_27_cfg_x (pmp_pma_27_cfg_x),
    .io_check_env_pma_27_addr  (pmp_pma_27_addr),
    .io_check_env_pma_27_mask  (pmp_pma_27_mask),
    .io_check_env_pma_28_cfg_c (pmp_pma_28_cfg_c),
    .io_check_env_pma_28_cfg_a (pmp_pma_28_cfg_a),
    .io_check_env_pma_28_cfg_x (pmp_pma_28_cfg_x),
    .io_check_env_pma_28_addr  (pmp_pma_28_addr),
    .io_check_env_pma_28_mask  (pmp_pma_28_mask),
    .io_check_env_pma_29_cfg_c (pmp_pma_29_cfg_c),
    .io_check_env_pma_29_cfg_a (pmp_pma_29_cfg_a),
    .io_check_env_pma_29_cfg_x (pmp_pma_29_cfg_x),
    .io_check_env_pma_29_addr  (pmp_pma_29_addr),
    .io_check_env_pma_29_mask  (pmp_pma_29_mask),
    .io_check_env_pma_30_cfg_c (pmp_pma_30_cfg_c),
    .io_check_env_pma_30_cfg_a (pmp_pma_30_cfg_a),
    .io_check_env_pma_30_cfg_x (pmp_pma_30_cfg_x),
    .io_check_env_pma_30_addr  (pmp_pma_30_addr),
    .io_check_env_pma_30_mask  (pmp_pma_30_mask),
    .io_check_env_pma_31_cfg_c (pmp_pma_31_cfg_c),
    .io_check_env_pma_31_cfg_a (pmp_pma_31_cfg_a),
    .io_check_env_pma_31_cfg_x (pmp_pma_31_cfg_x),
    .io_check_env_pma_31_addr  (pmp_pma_31_addr),
    .io_check_env_pma_31_mask  (pmp_pma_31_mask),
    // ---- ← ifu：IFU（MMIO 取指）的物理地址权限检查口 ----
    .io_req_valid              (ifu_pmp_req_valid),
    .io_req_bits_addr          (ifu_pmp_req_bits_addr),
    // ---- → ifu（IFU（MMIO 取指）的物理地址权限检查口） ----
    .io_resp_instr             (pmpCheck4_resp_instr),
    .io_resp_mmio              (pmpCheck4_resp_mmio)
  );

  // ===========================================================================
  // §C CSR 打拍与 wfi 握手的延迟线
  // ===========================================================================
  DelayN_7 inner_tlbCsr_delay (
    // ---- 时钟 / 复位 ----
    .clock                    (clock),
    // ---- 顶层 io_tlbCsr* —— TLB 相关 CSR ----
    .io_in_satp_mode          (io_tlbCsr_satp_mode),
    .io_in_satp_asid          (io_tlbCsr_satp_asid),
    .io_in_satp_ppn           (io_tlbCsr_satp_ppn),
    .io_in_satp_changed       (io_tlbCsr_satp_changed),
    .io_in_vsatp_mode         (io_tlbCsr_vsatp_mode),
    .io_in_vsatp_asid         (io_tlbCsr_vsatp_asid),
    .io_in_vsatp_ppn          (io_tlbCsr_vsatp_ppn),
    .io_in_vsatp_changed      (io_tlbCsr_vsatp_changed),
    .io_in_hgatp_mode         (io_tlbCsr_hgatp_mode),
    .io_in_hgatp_vmid         (io_tlbCsr_hgatp_vmid),
    .io_in_hgatp_ppn          (io_tlbCsr_hgatp_ppn),
    .io_in_hgatp_changed      (io_tlbCsr_hgatp_changed),
    .io_in_mbmc_BME           (io_tlbCsr_mbmc_BME),
    .io_in_mbmc_CMODE         (io_tlbCsr_mbmc_CMODE),
    .io_in_priv_mxr           (io_tlbCsr_priv_mxr),
    .io_in_priv_sum           (io_tlbCsr_priv_sum),
    .io_in_priv_vmxr          (io_tlbCsr_priv_vmxr),
    .io_in_priv_vsum          (io_tlbCsr_priv_vsum),
    .io_in_priv_virt          (io_tlbCsr_priv_virt),
    .io_in_priv_virt_changed  (io_tlbCsr_priv_virt_changed),
    .io_in_priv_spvp          (io_tlbCsr_priv_spvp),
    .io_in_priv_imode         (io_tlbCsr_priv_imode),
    .io_in_priv_dmode         (io_tlbCsr_priv_dmode),
    .io_in_priv_debug         (io_tlbCsr_priv_debug),
    .io_in_pmm_mseccfg        (io_tlbCsr_pmm_mseccfg),
    .io_in_pmm_menvcfg        (io_tlbCsr_pmm_menvcfg),
    .io_in_pmm_henvcfg        (io_tlbCsr_pmm_henvcfg),
    .io_in_pmm_hstatus        (io_tlbCsr_pmm_hstatus),
    .io_in_pmm_senvcfg        (io_tlbCsr_pmm_senvcfg),
    // ---- → itlb（satp/vsatp/hgatp/特权级等 TLB CSR（打两拍后）） ----
    .io_out_satp_mode         (tlbCsrDelay_out_satp_mode),
    .io_out_satp_ppn          (tlbCsrDelay_out_satp_ppn),
    .io_out_vsatp_mode        (tlbCsrDelay_out_vsatp_mode),
    .io_out_vsatp_ppn         (tlbCsrDelay_out_vsatp_ppn),
    .io_out_hgatp_mode        (tlbCsrDelay_out_hgatp_mode),
    .io_out_hgatp_ppn         (tlbCsrDelay_out_hgatp_ppn),
    .io_out_mbmc_BME          (tlbCsrDelay_out_mbmc_BME),
    .io_out_mbmc_CMODE        (tlbCsrDelay_out_mbmc_CMODE),
    .io_out_priv_mxr          (tlbCsrDelay_out_priv_mxr),
    .io_out_priv_sum          (tlbCsrDelay_out_priv_sum),
    .io_out_priv_vmxr         (tlbCsrDelay_out_priv_vmxr),
    .io_out_priv_vsum         (tlbCsrDelay_out_priv_vsum),
    .io_out_priv_virt         (tlbCsrDelay_out_priv_virt),
    .io_out_priv_spvp         (tlbCsrDelay_out_priv_spvp),
    .io_out_priv_dmode        (tlbCsrDelay_out_priv_dmode),
    .io_out_pmm_mseccfg       (tlbCsrDelay_out_pmm_mseccfg),
    .io_out_pmm_menvcfg       (tlbCsrDelay_out_pmm_menvcfg),
    .io_out_pmm_henvcfg       (tlbCsrDelay_out_pmm_henvcfg),
    .io_out_pmm_hstatus       (tlbCsrDelay_out_pmm_hstatus),
    .io_out_pmm_senvcfg       (tlbCsrDelay_out_pmm_senvcfg),
    // ---- → itlb（satp/vsatp/hgatp/特权级等 TLB CSR（打两拍后））；itlbRepeater1（TLB CSR（打两拍后）） ----
    .io_out_satp_asid         (tlbCsrDelay_out_satp_asid),
    .io_out_vsatp_asid        (tlbCsrDelay_out_vsatp_asid),
    .io_out_hgatp_vmid        (tlbCsrDelay_out_hgatp_vmid),
    // ---- → itlb（satp/vsatp/hgatp/特权级等 TLB CSR（打两拍后））；itlbRepeater1（TLB CSR（打两拍后））；itlbRepeater2（TLB CSR（打两拍后）） ----
    .io_out_satp_changed      (tlbCsrDelay_out_satp_changed),
    .io_out_vsatp_changed     (tlbCsrDelay_out_vsatp_changed),
    .io_out_hgatp_changed     (tlbCsrDelay_out_hgatp_changed),
    .io_out_priv_virt_changed (tlbCsrDelay_out_priv_virt_changed),
    // ---- → pmpCheck0（当前特权级 / debug（打两拍后））；pmpCheck1（当前特权级 / debug（打两拍后））；pmpCheck2（当前特权级 / debug（打两拍后））；pmpCheck3（当前特权级 / debug（打两拍后））；pmpCheck4（当前特权级 / debug（打两拍后））；itlb（satp/vsatp/hgatp/特权级等 TLB CSR（打两拍后）） ----
    .io_out_priv_imode        (tlbCsrDelay_out_priv_imode),
    .io_out_priv_debug        (tlbCsrDelay_out_priv_debug)
  );
  DelayN_8 inner_csrCtrl_delay (
    // ---- 时钟 / 复位 ----
    .clock                                                (clock),
    // ---- 顶层 io_csrCtrl* —— 自定义 CSR 控制 ----
    .io_in_pf_ctrl_l1I_pf_enable                          (io_csrCtrl_pf_ctrl_l1I_pf_enable),
    .io_in_bp_ctrl_ubtb_enable                            (io_csrCtrl_bp_ctrl_ubtb_enable),
    .io_in_bp_ctrl_btb_enable                             (io_csrCtrl_bp_ctrl_btb_enable),
    .io_in_bp_ctrl_tage_enable                            (io_csrCtrl_bp_ctrl_tage_enable),
    .io_in_bp_ctrl_sc_enable                              (io_csrCtrl_bp_ctrl_sc_enable),
    .io_in_bp_ctrl_ras_enable                             (io_csrCtrl_bp_ctrl_ras_enable),
    .io_in_sbuffer_timeout                                (io_csrCtrl_sbuffer_timeout),
    .io_in_ldld_vio_check_enable                          (io_csrCtrl_ldld_vio_check_enable),
    .io_in_cache_error_enable                             (io_csrCtrl_cache_error_enable),
    .io_in_hd_misalign_st_enable                          (io_csrCtrl_hd_misalign_st_enable),
    .io_in_hd_misalign_ld_enable                          (io_csrCtrl_hd_misalign_ld_enable),
    .io_in_distribute_csr_w_valid                         (io_csrCtrl_distribute_csr_w_valid),
    .io_in_distribute_csr_w_bits_addr                     (io_csrCtrl_distribute_csr_w_bits_addr),
    .io_in_distribute_csr_w_bits_data                     (io_csrCtrl_distribute_csr_w_bits_data),
    .io_in_frontend_trigger_tUpdate_valid                 (io_csrCtrl_frontend_trigger_tUpdate_valid),
    .io_in_frontend_trigger_tUpdate_bits_addr             (io_csrCtrl_frontend_trigger_tUpdate_bits_addr),
    .io_in_frontend_trigger_tUpdate_bits_tdata_matchType  (io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_matchType),
    .io_in_frontend_trigger_tUpdate_bits_tdata_select     (io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_select),
    .io_in_frontend_trigger_tUpdate_bits_tdata_action     (io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_action),
    .io_in_frontend_trigger_tUpdate_bits_tdata_chain      (io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_chain),
    .io_in_frontend_trigger_tUpdate_bits_tdata_tdata2     (io_csrCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2),
    .io_in_frontend_trigger_tEnableVec_0                  (io_csrCtrl_frontend_trigger_tEnableVec_0),
    .io_in_frontend_trigger_tEnableVec_1                  (io_csrCtrl_frontend_trigger_tEnableVec_1),
    .io_in_frontend_trigger_tEnableVec_2                  (io_csrCtrl_frontend_trigger_tEnableVec_2),
    .io_in_frontend_trigger_tEnableVec_3                  (io_csrCtrl_frontend_trigger_tEnableVec_3),
    .io_in_frontend_trigger_debugMode                     (io_csrCtrl_frontend_trigger_debugMode),
    .io_in_frontend_trigger_triggerCanRaiseBpExp          (io_csrCtrl_frontend_trigger_triggerCanRaiseBpExp),
    .io_in_mem_trigger_tUpdate_valid                      (io_csrCtrl_mem_trigger_tUpdate_valid),
    .io_in_mem_trigger_tUpdate_bits_addr                  (io_csrCtrl_mem_trigger_tUpdate_bits_addr),
    .io_in_mem_trigger_tUpdate_bits_tdata_matchType       (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_matchType),
    .io_in_mem_trigger_tUpdate_bits_tdata_select          (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_select),
    .io_in_mem_trigger_tUpdate_bits_tdata_action          (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_action),
    .io_in_mem_trigger_tUpdate_bits_tdata_chain           (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_chain),
    .io_in_mem_trigger_tUpdate_bits_tdata_store           (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_store),
    .io_in_mem_trigger_tUpdate_bits_tdata_load            (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_load),
    .io_in_mem_trigger_tUpdate_bits_tdata_tdata2          (io_csrCtrl_mem_trigger_tUpdate_bits_tdata_tdata2),
    .io_in_mem_trigger_tEnableVec_0                       (io_csrCtrl_mem_trigger_tEnableVec_0),
    .io_in_mem_trigger_tEnableVec_1                       (io_csrCtrl_mem_trigger_tEnableVec_1),
    .io_in_mem_trigger_tEnableVec_2                       (io_csrCtrl_mem_trigger_tEnableVec_2),
    .io_in_mem_trigger_tEnableVec_3                       (io_csrCtrl_mem_trigger_tEnableVec_3),
    .io_in_mem_trigger_debugMode                          (io_csrCtrl_mem_trigger_debugMode),
    .io_in_mem_trigger_triggerCanRaiseBpExp               (io_csrCtrl_mem_trigger_triggerCanRaiseBpExp),
    .io_in_fsIsOff                                        (io_csrCtrl_fsIsOff),
    // ---- → core（L1I 预取开关（延迟后的 csrCtrl 再打一拍给 ICache）） ----
    .io_out_pf_ctrl_l1I_pf_enable                         (csrCtrlDelay_out_pf_ctrl_l1I_pf_enable),
    // ---- → bpu（分支预测器各部件开关（bp_ctrl，CSR 打两拍后）） ----
    .io_out_bp_ctrl_ubtb_enable                           (csrCtrlDelay_out_bp_ctrl_ubtb_enable),
    .io_out_bp_ctrl_btb_enable                            (csrCtrlDelay_out_bp_ctrl_btb_enable),
    .io_out_bp_ctrl_tage_enable                           (csrCtrlDelay_out_bp_ctrl_tage_enable),
    .io_out_bp_ctrl_sc_enable                             (csrCtrlDelay_out_bp_ctrl_sc_enable),
    .io_out_bp_ctrl_ras_enable                            (csrCtrlDelay_out_bp_ctrl_ras_enable),
    // ---- 无读者的输出（golden 同样悬空） ----
    .io_out_sbuffer_timeout                               (),
    .io_out_ldld_vio_check_enable                         (),
    .io_out_cache_error_enable                            (),
    .io_out_hd_misalign_st_enable                         (),
    .io_out_hd_misalign_ld_enable                         (),
    .io_out_mem_trigger_tUpdate_valid                     (),
    .io_out_mem_trigger_tUpdate_bits_addr                 (),
    .io_out_mem_trigger_tUpdate_bits_tdata_matchType      (),
    .io_out_mem_trigger_tUpdate_bits_tdata_select         (),
    .io_out_mem_trigger_tUpdate_bits_tdata_action         (),
    .io_out_mem_trigger_tUpdate_bits_tdata_chain          (),
    .io_out_mem_trigger_tUpdate_bits_tdata_store          (),
    .io_out_mem_trigger_tUpdate_bits_tdata_load           (),
    .io_out_mem_trigger_tUpdate_bits_tdata_tdata2         (),
    .io_out_mem_trigger_tEnableVec_0                      (),
    .io_out_mem_trigger_tEnableVec_1                      (),
    .io_out_mem_trigger_tEnableVec_2                      (),
    .io_out_mem_trigger_tEnableVec_3                      (),
    .io_out_mem_trigger_debugMode                         (),
    .io_out_mem_trigger_triggerCanRaiseBpExp              (),
    // ---- → pmp（pmpcfg/pmpaddr 等 CSR 写广播（打两拍后）） ----
    .io_out_distribute_csr_w_valid                        (csrCtrlDelay_out_distribute_csr_w_valid),
    .io_out_distribute_csr_w_bits_addr                    (csrCtrlDelay_out_distribute_csr_w_bits_addr),
    .io_out_distribute_csr_w_bits_data                    (csrCtrlDelay_out_distribute_csr_w_bits_data),
    // ---- → ifu（前端断点触发器配置与 fsIsOff（CSR 打两拍后）） ----
    .io_out_frontend_trigger_tUpdate_valid                (csrCtrlDelay_out_frontend_trigger_tUpdate_valid),
    .io_out_frontend_trigger_tUpdate_bits_addr            (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_addr),
    .io_out_frontend_trigger_tUpdate_bits_tdata_matchType (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_matchType),
    .io_out_frontend_trigger_tUpdate_bits_tdata_select    (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_select),
    .io_out_frontend_trigger_tUpdate_bits_tdata_action    (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_action),
    .io_out_frontend_trigger_tUpdate_bits_tdata_chain     (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_chain),
    .io_out_frontend_trigger_tUpdate_bits_tdata_tdata2    (csrCtrlDelay_out_frontend_trigger_tUpdate_bits_tdata_tdata2),
    .io_out_frontend_trigger_tEnableVec_0                 (csrCtrlDelay_out_frontend_trigger_tEnableVec_0),
    .io_out_frontend_trigger_tEnableVec_1                 (csrCtrlDelay_out_frontend_trigger_tEnableVec_1),
    .io_out_frontend_trigger_tEnableVec_2                 (csrCtrlDelay_out_frontend_trigger_tEnableVec_2),
    .io_out_frontend_trigger_tEnableVec_3                 (csrCtrlDelay_out_frontend_trigger_tEnableVec_3),
    .io_out_frontend_trigger_debugMode                    (csrCtrlDelay_out_frontend_trigger_debugMode),
    .io_out_frontend_trigger_triggerCanRaiseBpExp         (csrCtrlDelay_out_frontend_trigger_triggerCanRaiseBpExp),
    .io_out_fsIsOff                                       (csrCtrlDelay_out_fsIsOff)
  );
  DelayN_13 inner_wfiReq_delay (
    // ---- 时钟 / 复位 ----
    .clock  (clock),
    // ---- 顶层 io_backend_wfi* —— wfi 握手 ----
    .io_in  (io_backend_wfi_wfiReq),
    // ---- → instrUncache（wfi 请求（打一拍后））；icache（wfi 请求（打一拍后））；core（wfi 请求（打一拍后）参与 safe 判定） ----
    .io_out (wfiReqDelay_out)
  );
  DelayN_13 inner_io_backend_wfi_wfiSafe_delay (
    // ---- 时钟 / 复位 ----
    .clock  (clock),
    // ---- ← u_core：wfi safe（三者相与）再打一拍回后端 ----
    .io_in  (wfi_safe_now),
    // ---- 顶层 io_backend_wfi* —— wfi 握手 ----
    .io_out (io_backend_wfi_wfiSafe)
  );

  // ===========================================================================
  // §D 性能事件：PFEvent（CSR 选择）+ HPerfMonitor（汇成 8 路）
  // ===========================================================================
  PFEvent inner_pfevent (
    // ---- 时钟 / 复位 ----
    .clock                         (clock),
    .reset                         (reset),
    // ---- 顶层 io_csrCtrl* —— 自定义 CSR 控制 ----
    .io_distribute_csr_w_valid     (io_csrCtrl_distribute_csr_w_valid),
    .io_distribute_csr_w_bits_addr (io_csrCtrl_distribute_csr_w_bits_addr),
    .io_distribute_csr_w_bits_data (io_csrCtrl_distribute_csr_w_bits_data),
    // ---- → perfHpm（CSR 选出的 8 个性能事件编码） ----
    .io_hpmevent_0                 (pfevent_hpmevent_0),
    .io_hpmevent_1                 (pfevent_hpmevent_1),
    .io_hpmevent_2                 (pfevent_hpmevent_2),
    .io_hpmevent_3                 (pfevent_hpmevent_3),
    .io_hpmevent_4                 (pfevent_hpmevent_4),
    .io_hpmevent_5                 (pfevent_hpmevent_5),
    .io_hpmevent_6                 (pfevent_hpmevent_6),
    .io_hpmevent_7                 (pfevent_hpmevent_7),
    // ---- 无读者的输出（golden 同样悬空） ----
    .io_hpmevent_8                 (),
    .io_hpmevent_9                 (),
    .io_hpmevent_10                (),
    .io_hpmevent_11                (),
    .io_hpmevent_12                (),
    .io_hpmevent_13                (),
    .io_hpmevent_14                (),
    .io_hpmevent_15                (),
    .io_hpmevent_16                (),
    .io_hpmevent_17                (),
    .io_hpmevent_18                (),
    .io_hpmevent_19                (),
    .io_hpmevent_20                (),
    .io_hpmevent_21                (),
    .io_hpmevent_22                (),
    .io_hpmevent_23                ()
  );
  HPerfMonitor inner_perfEvents_hpm (
    // ---- 时钟 / 复位 ----
    .clock                   (clock),
    // ---- ← pfevent：CSR 选出的 8 个性能事件编码 ----
    .io_hpm_event_0          (pfevent_hpmevent_0),
    .io_hpm_event_1          (pfevent_hpmevent_1),
    .io_hpm_event_2          (pfevent_hpmevent_2),
    .io_hpm_event_3          (pfevent_hpmevent_3),
    .io_hpm_event_4          (pfevent_hpmevent_4),
    .io_hpm_event_5          (pfevent_hpmevent_5),
    .io_hpm_event_6          (pfevent_hpmevent_6),
    .io_hpm_event_7          (pfevent_hpmevent_7),
    // ---- ← ifu：IFU 性能事件 ----
    .io_events_sets_1_value  (ifu_perf_0_value),
    .io_events_sets_2_value  (ifu_perf_1_value),
    .io_events_sets_3_value  (ifu_perf_2_value),
    .io_events_sets_4_value  (ifu_perf_3_value),
    .io_events_sets_5_value  (ifu_perf_4_value),
    .io_events_sets_6_value  (ifu_perf_5_value),
    .io_events_sets_7_value  (ifu_perf_6_value),
    .io_events_sets_8_value  (ifu_perf_7_value),
    .io_events_sets_9_value  (ifu_perf_8_value),
    .io_events_sets_10_value (ifu_perf_9_value),
    .io_events_sets_11_value (ifu_perf_10_value),
    .io_events_sets_12_value (ifu_perf_11_value),
    .io_events_sets_13_value (ifu_perf_12_value),
    // ---- ← ibuffer：IBuffer 性能事件 ----
    .io_events_sets_14_value (ibuffer_perf_0_value),
    .io_events_sets_15_value (ibuffer_perf_1_value),
    .io_events_sets_16_value (ibuffer_perf_2_value),
    .io_events_sets_17_value (ibuffer_perf_3_value),
    .io_events_sets_18_value (ibuffer_perf_4_value),
    .io_events_sets_19_value (ibuffer_perf_5_value),
    .io_events_sets_20_value (ibuffer_perf_6_value),
    .io_events_sets_21_value (ibuffer_perf_7_value),
    .io_events_sets_22_value (ibuffer_perf_8_value),
    // ---- ← icache：ICache 性能事件 ----
    .io_events_sets_23_value (icache_perf_0_value),
    // ---- ← ftq：FTQ 性能事件 ----
    .io_events_sets_25_value (ftq_perf_0_value),
    .io_events_sets_26_value (ftq_perf_1_value),
    .io_events_sets_27_value (ftq_perf_2_value),
    .io_events_sets_28_value (ftq_perf_3_value),
    .io_events_sets_29_value (ftq_perf_4_value),
    .io_events_sets_30_value (ftq_perf_5_value),
    .io_events_sets_31_value (ftq_perf_6_value),
    .io_events_sets_32_value (ftq_perf_7_value),
    .io_events_sets_33_value (ftq_perf_8_value),
    .io_events_sets_34_value (ftq_perf_9_value),
    .io_events_sets_35_value (ftq_perf_10_value),
    .io_events_sets_36_value (ftq_perf_11_value),
    .io_events_sets_37_value (ftq_perf_12_value),
    .io_events_sets_38_value (ftq_perf_13_value),
    .io_events_sets_39_value (ftq_perf_14_value),
    .io_events_sets_40_value (ftq_perf_15_value),
    .io_events_sets_41_value (ftq_perf_16_value),
    .io_events_sets_42_value (ftq_perf_17_value),
    .io_events_sets_43_value (ftq_perf_18_value),
    .io_events_sets_44_value (ftq_perf_19_value),
    .io_events_sets_45_value (ftq_perf_20_value),
    .io_events_sets_46_value (ftq_perf_21_value),
    .io_events_sets_47_value (ftq_perf_22_value),
    .io_events_sets_48_value (ftq_perf_23_value),
    // ---- ← bpu：BPU 性能事件 ----
    .io_events_sets_49_value (bpu_perf_0_value),
    .io_events_sets_50_value (bpu_perf_1_value),
    .io_events_sets_51_value (bpu_perf_2_value),
    .io_events_sets_52_value (bpu_perf_3_value),
    .io_events_sets_53_value (bpu_perf_4_value),
    .io_events_sets_54_value (bpu_perf_5_value),
    .io_events_sets_55_value (bpu_perf_6_value),
    // ---- ← itlb：ITLB 性能事件 ----
    .io_events_sets_56_value (itlb_perf_0_value),
    .io_events_sets_57_value (itlb_perf_1_value),
    // ---- → core（8 路性能计数增量（再打两拍送出）） ----
    .io_perf_0_value         (perfHpm_perf_0_value),
    .io_perf_1_value         (perfHpm_perf_1_value),
    .io_perf_2_value         (perfHpm_perf_2_value),
    .io_perf_3_value         (perfHpm_perf_3_value),
    .io_perf_4_value         (perfHpm_perf_4_value),
    .io_perf_5_value         (perfHpm_perf_5_value),
    .io_perf_6_value         (perfHpm_perf_6_value),
    .io_perf_7_value         (perfHpm_perf_7_value)
  );

  // ===========================================================================
  // §E MBIST（存储器内建自测）分发树：接口 → 流水 → 各 SRAM 子树
  // ===========================================================================
  MbistIntfFrontend inner_mbistIntf (
    // ---- → mbistPl（MBIST 接口 ↔ 分发流水） ----
    .toPipeline_0_array   (mbistIntf_toPipeline_0_array),
    .toPipeline_0_all     (mbistIntf_toPipeline_0_all),
    .toPipeline_0_req     (mbistIntf_toPipeline_0_req),
    .toPipeline_0_writeen (mbistIntf_toPipeline_0_writeen),
    .toPipeline_0_be      (mbistIntf_toPipeline_0_be),
    .toPipeline_0_addr    (mbistIntf_toPipeline_0_addr),
    .toPipeline_0_indata  (mbistIntf_toPipeline_0_indata),
    .toPipeline_0_readen  (mbistIntf_toPipeline_0_readen),
    .toPipeline_0_addr_rd (mbistIntf_toPipeline_0_addr_rd),
    // ---- ← mbistPl：MBIST 接口 ↔ 分发流水 ----
    .toPipeline_0_ack     (mbistPl_mbist_ack),
    .toPipeline_0_outdata (mbistPl_mbist_outdata),
    // ---- 常量（golden 在本配置下钉死的输入） ----
    .mbist_array          (7'h0),
    .mbist_all            (1'h0),
    .mbist_req            (1'h0),
    .mbist_writeen        (1'h0),
    .mbist_be             (76'h0),
    .mbist_addr           (10'h0),
    .mbist_indata         (76'h0),
    .mbist_readen         (1'h0),
    .mbist_addr_rd        (10'h0),
    // ---- 无读者的输出（golden 同样悬空） ----
    .mbist_ack            (),
    .mbist_outdata        ()
  );
  MbistPipeFrontend inner_mbistPl (
    // ---- 时钟 / 复位 ----
    .clock                     (clock),
    .reset                     (reset),
    // ---- ← mbistIntf：MBIST 接口 ↔ 分发流水 ----
    .mbist_array               (mbistIntf_toPipeline_0_array),
    .mbist_all                 (mbistIntf_toPipeline_0_all),
    .mbist_req                 (mbistIntf_toPipeline_0_req),
    .mbist_writeen             (mbistIntf_toPipeline_0_writeen),
    .mbist_be                  (mbistIntf_toPipeline_0_be),
    .mbist_addr                (mbistIntf_toPipeline_0_addr),
    .mbist_indata              (mbistIntf_toPipeline_0_indata),
    .mbist_readen              (mbistIntf_toPipeline_0_readen),
    .mbist_addr_rd             (mbistIntf_toPipeline_0_addr_rd),
    // ---- → mbistIntf（MBIST 接口 ↔ 分发流水） ----
    .mbist_ack                 (mbistPl_mbist_ack),
    .mbist_outdata             (mbistPl_mbist_outdata),
    // ---- → icache（ICache tag / data SRAM 的 MBIST 穿线） ----
    .toNextPipeline_0_array    (mbistBd0_array),
    .toNextPipeline_0_all      (mbistBd0_all),
    .toNextPipeline_0_req      (mbistBd0_req),
    .toNextPipeline_0_writeen  (mbistBd0_writeen),
    .toNextPipeline_0_be       (mbistBd0_be),
    .toNextPipeline_0_addr     (mbistBd0_addr),
    .toNextPipeline_0_indata   (mbistBd0_indata),
    .toNextPipeline_0_readen   (mbistBd0_readen),
    .toNextPipeline_0_addr_rd  (mbistBd0_addr_rd),
    .toNextPipeline_1_array    (mbistBd1_array),
    .toNextPipeline_1_all      (mbistBd1_all),
    .toNextPipeline_1_req      (mbistBd1_req),
    .toNextPipeline_1_writeen  (mbistBd1_writeen),
    .toNextPipeline_1_be       (mbistBd1_be),
    .toNextPipeline_1_addr     (mbistBd1_addr),
    .toNextPipeline_1_indata   (mbistBd1_indata),
    .toNextPipeline_1_readen   (mbistBd1_readen),
    .toNextPipeline_1_addr_rd  (mbistBd1_addr_rd),
    .toNextPipeline_2_array    (mbistBd2_array),
    .toNextPipeline_2_all      (mbistBd2_all),
    .toNextPipeline_2_req      (mbistBd2_req),
    .toNextPipeline_2_writeen  (mbistBd2_writeen),
    .toNextPipeline_2_be       (mbistBd2_be),
    .toNextPipeline_2_addr     (mbistBd2_addr),
    .toNextPipeline_2_indata   (mbistBd2_indata),
    .toNextPipeline_2_readen   (mbistBd2_readen),
    .toNextPipeline_2_addr_rd  (mbistBd2_addr_rd),
    .toNextPipeline_3_array    (mbistBd3_array),
    .toNextPipeline_3_all      (mbistBd3_all),
    .toNextPipeline_3_req      (mbistBd3_req),
    .toNextPipeline_3_writeen  (mbistBd3_writeen),
    .toNextPipeline_3_be       (mbistBd3_be),
    .toNextPipeline_3_addr     (mbistBd3_addr),
    .toNextPipeline_3_indata   (mbistBd3_indata),
    .toNextPipeline_3_readen   (mbistBd3_readen),
    .toNextPipeline_3_addr_rd  (mbistBd3_addr_rd),
    .toNextPipeline_4_array    (mbistBd4_array),
    .toNextPipeline_4_all      (mbistBd4_all),
    .toNextPipeline_4_req      (mbistBd4_req),
    .toNextPipeline_4_writeen  (mbistBd4_writeen),
    .toNextPipeline_4_be       (mbistBd4_be),
    .toNextPipeline_4_addr     (mbistBd4_addr),
    .toNextPipeline_4_indata   (mbistBd4_indata),
    .toNextPipeline_4_readen   (mbistBd4_readen),
    .toNextPipeline_4_addr_rd  (mbistBd4_addr_rd),
    // ---- ← icache：ICache tag / data SRAM 的 MBIST 穿线 ----
    .toNextPipeline_0_ack      (mbistBd0_ack),
    .toNextPipeline_0_outdata  (mbistBd0_outdata),
    .toNextPipeline_1_ack      (mbistBd1_ack),
    .toNextPipeline_1_outdata  (mbistBd1_outdata),
    .toNextPipeline_2_ack      (mbistBd2_ack),
    .toNextPipeline_2_outdata  (mbistBd2_outdata),
    .toNextPipeline_3_ack      (mbistBd3_ack),
    .toNextPipeline_3_outdata  (mbistBd3_outdata),
    .toNextPipeline_4_ack      (mbistBd4_ack),
    .toNextPipeline_4_outdata  (mbistBd4_outdata),
    // ---- → bpu（BPU 内各预测表 SRAM 的 MBIST 穿线） ----
    .toNextPipeline_5_array    (mbistBd5_array),
    .toNextPipeline_5_all      (mbistBd5_all),
    .toNextPipeline_5_req      (mbistBd5_req),
    .toNextPipeline_5_writeen  (mbistBd5_writeen),
    .toNextPipeline_5_be       (mbistBd5_be),
    .toNextPipeline_5_addr     (mbistBd5_addr),
    .toNextPipeline_5_indata   (mbistBd5_indata),
    .toNextPipeline_5_readen   (mbistBd5_readen),
    .toNextPipeline_5_addr_rd  (mbistBd5_addr_rd),
    .toNextPipeline_6_array    (mbistBd6_array),
    .toNextPipeline_6_all      (mbistBd6_all),
    .toNextPipeline_6_req      (mbistBd6_req),
    .toNextPipeline_6_writeen  (mbistBd6_writeen),
    .toNextPipeline_6_be       (mbistBd6_be),
    .toNextPipeline_6_addr     (mbistBd6_addr),
    .toNextPipeline_6_indata   (mbistBd6_indata),
    .toNextPipeline_6_readen   (mbistBd6_readen),
    .toNextPipeline_6_addr_rd  (mbistBd6_addr_rd),
    .toNextPipeline_7_array    (mbistBd7_array),
    .toNextPipeline_7_all      (mbistBd7_all),
    .toNextPipeline_7_req      (mbistBd7_req),
    .toNextPipeline_7_writeen  (mbistBd7_writeen),
    .toNextPipeline_7_be       (mbistBd7_be),
    .toNextPipeline_7_addr     (mbistBd7_addr),
    .toNextPipeline_7_indata   (mbistBd7_indata),
    .toNextPipeline_7_readen   (mbistBd7_readen),
    .toNextPipeline_7_addr_rd  (mbistBd7_addr_rd),
    .toNextPipeline_8_array    (mbistBd8_array),
    .toNextPipeline_8_all      (mbistBd8_all),
    .toNextPipeline_8_req      (mbistBd8_req),
    .toNextPipeline_8_writeen  (mbistBd8_writeen),
    .toNextPipeline_8_be       (mbistBd8_be),
    .toNextPipeline_8_addr     (mbistBd8_addr),
    .toNextPipeline_8_indata   (mbistBd8_indata),
    .toNextPipeline_8_readen   (mbistBd8_readen),
    .toNextPipeline_8_addr_rd  (mbistBd8_addr_rd),
    .toNextPipeline_9_array    (mbistBd9_array),
    .toNextPipeline_9_all      (mbistBd9_all),
    .toNextPipeline_9_req      (mbistBd9_req),
    .toNextPipeline_9_writeen  (mbistBd9_writeen),
    .toNextPipeline_9_be       (mbistBd9_be),
    .toNextPipeline_9_addr     (mbistBd9_addr),
    .toNextPipeline_9_indata   (mbistBd9_indata),
    .toNextPipeline_9_readen   (mbistBd9_readen),
    .toNextPipeline_9_addr_rd  (mbistBd9_addr_rd),
    .toNextPipeline_10_array   (mbistBd10_array),
    .toNextPipeline_10_all     (mbistBd10_all),
    .toNextPipeline_10_req     (mbistBd10_req),
    .toNextPipeline_10_writeen (mbistBd10_writeen),
    .toNextPipeline_10_be      (mbistBd10_be),
    .toNextPipeline_10_addr    (mbistBd10_addr),
    .toNextPipeline_10_indata  (mbistBd10_indata),
    .toNextPipeline_10_readen  (mbistBd10_readen),
    .toNextPipeline_10_addr_rd (mbistBd10_addr_rd),
    .toNextPipeline_11_array   (mbistBd11_array),
    .toNextPipeline_11_all     (mbistBd11_all),
    .toNextPipeline_11_req     (mbistBd11_req),
    .toNextPipeline_11_writeen (mbistBd11_writeen),
    .toNextPipeline_11_be      (mbistBd11_be),
    .toNextPipeline_11_addr    (mbistBd11_addr),
    .toNextPipeline_11_indata  (mbistBd11_indata),
    .toNextPipeline_11_readen  (mbistBd11_readen),
    .toNextPipeline_11_addr_rd (mbistBd11_addr_rd),
    .toNextPipeline_12_array   (mbistBd12_array),
    .toNextPipeline_12_all     (mbistBd12_all),
    .toNextPipeline_12_req     (mbistBd12_req),
    .toNextPipeline_12_writeen (mbistBd12_writeen),
    .toNextPipeline_12_be      (mbistBd12_be),
    .toNextPipeline_12_addr    (mbistBd12_addr),
    .toNextPipeline_12_indata  (mbistBd12_indata),
    .toNextPipeline_12_readen  (mbistBd12_readen),
    .toNextPipeline_12_addr_rd (mbistBd12_addr_rd),
    .toNextPipeline_13_array   (mbistBd13_array),
    .toNextPipeline_13_all     (mbistBd13_all),
    .toNextPipeline_13_req     (mbistBd13_req),
    .toNextPipeline_13_writeen (mbistBd13_writeen),
    .toNextPipeline_13_be      (mbistBd13_be),
    .toNextPipeline_13_addr    (mbistBd13_addr),
    .toNextPipeline_13_indata  (mbistBd13_indata),
    .toNextPipeline_13_readen  (mbistBd13_readen),
    .toNextPipeline_13_addr_rd (mbistBd13_addr_rd),
    .toNextPipeline_14_array   (mbistBd14_array),
    .toNextPipeline_14_all     (mbistBd14_all),
    .toNextPipeline_14_req     (mbistBd14_req),
    .toNextPipeline_14_writeen (mbistBd14_writeen),
    .toNextPipeline_14_be      (mbistBd14_be),
    .toNextPipeline_14_addr    (mbistBd14_addr),
    .toNextPipeline_14_indata  (mbistBd14_indata),
    .toNextPipeline_14_readen  (mbistBd14_readen),
    .toNextPipeline_14_addr_rd (mbistBd14_addr_rd),
    .toNextPipeline_15_array   (mbistBd15_array),
    .toNextPipeline_15_all     (mbistBd15_all),
    .toNextPipeline_15_req     (mbistBd15_req),
    .toNextPipeline_15_writeen (mbistBd15_writeen),
    .toNextPipeline_15_be      (mbistBd15_be),
    .toNextPipeline_15_addr    (mbistBd15_addr),
    .toNextPipeline_15_indata  (mbistBd15_indata),
    .toNextPipeline_15_readen  (mbistBd15_readen),
    .toNextPipeline_15_addr_rd (mbistBd15_addr_rd),
    // ---- ← bpu：BPU 内各预测表 SRAM 的 MBIST 穿线 ----
    .toNextPipeline_5_ack      (mbistBd5_ack),
    .toNextPipeline_5_outdata  (mbistBd5_outdata),
    .toNextPipeline_6_ack      (mbistBd6_ack),
    .toNextPipeline_6_outdata  (mbistBd6_outdata),
    .toNextPipeline_7_ack      (mbistBd7_ack),
    .toNextPipeline_7_outdata  (mbistBd7_outdata),
    .toNextPipeline_8_ack      (mbistBd8_ack),
    .toNextPipeline_8_outdata  (mbistBd8_outdata),
    .toNextPipeline_9_ack      (mbistBd9_ack),
    .toNextPipeline_9_outdata  (mbistBd9_outdata),
    .toNextPipeline_10_ack     (mbistBd10_ack),
    .toNextPipeline_10_outdata (mbistBd10_outdata),
    .toNextPipeline_11_ack     (mbistBd11_ack),
    .toNextPipeline_11_outdata (mbistBd11_outdata),
    .toNextPipeline_12_ack     (mbistBd12_ack),
    .toNextPipeline_12_outdata (mbistBd12_outdata),
    .toNextPipeline_13_ack     (mbistBd13_ack),
    .toNextPipeline_13_outdata (mbistBd13_outdata),
    .toNextPipeline_14_ack     (mbistBd14_ack),
    .toNextPipeline_14_outdata (mbistBd14_outdata),
    .toNextPipeline_15_ack     (mbistBd15_ack),
    .toNextPipeline_15_outdata (mbistBd15_outdata)
  );

  // ===========================================================================
  // 直通输出：子模块结果原样送出（io_error / io_perf 由 u_core 直接驱动）
  // ===========================================================================
  assign io_backend_cfVec_0_valid = ibuffer_out_0_valid;
  assign io_backend_cfVec_0_bits_pc = ibuffer_out_0_bits_pc;
  assign io_backend_cfVec_0_bits_pd_isRVC = ibuffer_out_0_bits_pd_isRVC;
  assign io_backend_cfVec_0_bits_pd_brType = ibuffer_out_0_bits_pd_brType;
  assign io_backend_cfVec_0_bits_pred_taken = ibuffer_out_0_bits_pred_taken;
  assign io_backend_cfVec_0_bits_ftqPtr_flag = ibuffer_out_0_bits_ftqPtr_flag;
  assign io_backend_cfVec_0_bits_ftqPtr_value = ibuffer_out_0_bits_ftqPtr_value;
  assign io_backend_cfVec_1_valid = ibuffer_out_1_valid;
  assign io_backend_cfVec_1_bits_pc = ibuffer_out_1_bits_pc;
  assign io_backend_cfVec_1_bits_pd_isRVC = ibuffer_out_1_bits_pd_isRVC;
  assign io_backend_cfVec_1_bits_pd_brType = ibuffer_out_1_bits_pd_brType;
  assign io_backend_cfVec_1_bits_pred_taken = ibuffer_out_1_bits_pred_taken;
  assign io_backend_cfVec_1_bits_ftqPtr_flag = ibuffer_out_1_bits_ftqPtr_flag;
  assign io_backend_cfVec_1_bits_ftqPtr_value = ibuffer_out_1_bits_ftqPtr_value;
  assign io_backend_cfVec_2_valid = ibuffer_out_2_valid;
  assign io_backend_cfVec_2_bits_pc = ibuffer_out_2_bits_pc;
  assign io_backend_cfVec_2_bits_pd_isRVC = ibuffer_out_2_bits_pd_isRVC;
  assign io_backend_cfVec_2_bits_pd_brType = ibuffer_out_2_bits_pd_brType;
  assign io_backend_cfVec_2_bits_pred_taken = ibuffer_out_2_bits_pred_taken;
  assign io_backend_cfVec_2_bits_ftqPtr_flag = ibuffer_out_2_bits_ftqPtr_flag;
  assign io_backend_cfVec_2_bits_ftqPtr_value = ibuffer_out_2_bits_ftqPtr_value;
  assign io_backend_cfVec_3_valid = ibuffer_out_3_valid;
  assign io_backend_cfVec_3_bits_pc = ibuffer_out_3_bits_pc;
  assign io_backend_cfVec_3_bits_pd_isRVC = ibuffer_out_3_bits_pd_isRVC;
  assign io_backend_cfVec_3_bits_pd_brType = ibuffer_out_3_bits_pd_brType;
  assign io_backend_cfVec_3_bits_pred_taken = ibuffer_out_3_bits_pred_taken;
  assign io_backend_cfVec_3_bits_ftqPtr_flag = ibuffer_out_3_bits_ftqPtr_flag;
  assign io_backend_cfVec_3_bits_ftqPtr_value = ibuffer_out_3_bits_ftqPtr_value;
  assign io_backend_cfVec_4_valid = ibuffer_out_4_valid;
  assign io_backend_cfVec_4_bits_pc = ibuffer_out_4_bits_pc;
  assign io_backend_cfVec_4_bits_pd_isRVC = ibuffer_out_4_bits_pd_isRVC;
  assign io_backend_cfVec_4_bits_pd_brType = ibuffer_out_4_bits_pd_brType;
  assign io_backend_cfVec_4_bits_pred_taken = ibuffer_out_4_bits_pred_taken;
  assign io_backend_cfVec_4_bits_ftqPtr_flag = ibuffer_out_4_bits_ftqPtr_flag;
  assign io_backend_cfVec_4_bits_ftqPtr_value = ibuffer_out_4_bits_ftqPtr_value;
  assign io_backend_cfVec_5_valid = ibuffer_out_5_valid;
  assign io_backend_cfVec_5_bits_pc = ibuffer_out_5_bits_pc;
  assign io_backend_cfVec_5_bits_pd_isRVC = ibuffer_out_5_bits_pd_isRVC;
  assign io_backend_cfVec_5_bits_pd_brType = ibuffer_out_5_bits_pd_brType;
  assign io_backend_cfVec_5_bits_pred_taken = ibuffer_out_5_bits_pred_taken;
  assign io_backend_cfVec_5_bits_ftqPtr_flag = ibuffer_out_5_bits_ftqPtr_flag;
  assign io_backend_cfVec_5_bits_ftqPtr_value = ibuffer_out_5_bits_ftqPtr_value;
  assign io_backend_fromFtq_pc_mem_wen = ftq_toBackend_pc_mem_wen;
  assign io_backend_fromFtq_pc_mem_waddr = ftq_toBackend_pc_mem_waddr;
  assign io_backend_fromFtq_pc_mem_wdata_startAddr = ftq_toBackend_pc_mem_wdata_startAddr;
  assign io_backend_fromFtq_newest_entry_target = ftq_toBackend_newest_entry_target;
  assign io_backend_fromFtq_newest_entry_ptr_value = ftq_toBackend_newest_entry_ptr_value;
  assign io_resetInFrontend = reset;

endmodule
// END GENERATED
