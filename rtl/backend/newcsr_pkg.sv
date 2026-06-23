// ============================================================================
// newcsr_pkg —— NewCSR 控制状态寄存器文件 公共类型/参数/纯函数
// ----------------------------------------------------------------------------
// 设计意图来源（人写 Chisel）：
//   src/main/scala/xiangshan/backend/fu/NewCSR/NewCSR.scala  object CSRConfig / class NewCSR
//   特权级/虚拟态：CSRDefines.PrivMode / VirtMode
//   CSR 地址常量：rocket-chip CSRs + xiangshan CSRConst
//
// 本包定义 xs_NewCSR_core 用到的：
//   * 参数（XLEN / 地址宽 / PMP/PMA/trigger 数目 等）
//   * enum：特权级 priv_mode_e、虚拟态 virt_mode_e、异步访问状态机 csr_fsm_e
//   * struct：CSR 访问请求 csr_req_t、9 个 trap/xret 事件的 valid 集合 trap_event_set_t
//   * function automatic：CSR 地址译码辅助（VS/S 别名重映射、IMSIC 区间判定等）
// 这些取代 golden 展平的成百上千 `_T_`/`_GEN_` glue wire，让译码/路由/仲裁可读。
// ============================================================================
package newcsr_pkg;

  // ----- 基本参数（CSRConfig）-----
  localparam int XLEN        = 64;
  localparam int VLEN        = 128;
  localparam int ADDR_W      = 12;   // CSR 地址宽
  localparam int OP_W        = 2;    // csrrw/csrrs/csrrc 操作码
  localparam int PMP_NUM     = 16;   // PMP 表项数
  localparam int PMA_NUM     = 16;   // PMA 表项数
  localparam int TRIGGER_NUM = 4;    // 调试触发器数
  localparam int PERF_CNT_NUM = 29;  // 性能计数器数（Spec）
  localparam int HART_ID_LEN = 6;

  // ----- 特权级（PrivMode）：U=0, S=1, (reserved=2), M=3 -----
  typedef enum logic [1:0] {
    PRIV_U = 2'b00,
    PRIV_S = 2'b01,
    PRIV_M = 2'b11
  } priv_mode_e;

  // ----- 虚拟态（VirtMode）：Off=0（HS/HU/M），On=1（VS/VU）-----
  typedef enum logic {
    VIRT_OFF = 1'b0,
    VIRT_ON  = 1'b1
  } virt_mode_e;

  // ----- 异步访问状态机（NewCSR.scala s_idle/s_waitIMSIC/s_finish）-----
  // AIA/IMSIC 寄存器异步访问，需等待 IMSIC 返回，故有三态机。
  typedef enum logic [1:0] {
    CSR_IDLE      = 2'h0,  // 空闲，可接收新请求
    CSR_WAITIMSIC = 2'h1,  // 已发出 IMSIC 异步访问，等待 fromAIA.rdata
    CSR_FINISH    = 2'h2   // 已就绪，等待 io.out 被下游消费
  } csr_fsm_e;

  // ----- CSR 访问请求（io.in.bits 的核心字段）-----
  typedef struct packed {
    logic              wen;           // 写使能
    logic              ren;           // 读使能
    logic [OP_W-1:0]   op;            // 操作码
    logic [ADDR_W-1:0] addr;          // CSR 地址
    logic [XLEN-1:0]   src;           // 源操作数
    logic [XLEN-1:0]   wdata;         // 已算好的写数据
    logic              mnret;
    logic              mret;
    logic              sret;
    logic              dret;
    logic              redirectFlush;
  } csr_req_t;

  // ----- 9 个 trap-entry / xret 事件的 valid 集合 -----
  // NewCSR.scala 中按优先级 + NMIE 门 决定哪个事件触发，对应入口特权级切换。
  typedef struct packed {
    logic trap_to_mn;   // 进入 M-NMI
    logic trap_to_m;    // 进入 M
    logic trap_to_hs;   // 进入 HS
    logic trap_to_vs;   // 进入 VS
    logic trap_to_d;    // 进入 Debug
    logic ret_from_mn;  // mnret
    logic ret_from_m;   // mret
    logic ret_from_s;   // sret
    logic ret_from_d;   // dret
  } trap_event_set_t;

  // ----- 上下文状态（ContextStatus）：Off=0 用于 fp/vec status on/off 副作用判定 -----
  localparam logic [1:0] CTX_OFF = 2'b00;

  // ========================================================================
  // 纯函数：CSR 地址译码辅助
  // ========================================================================

  // VS 模式下，软件用 S 地址访问 VS 寄存器（地址重映射）。
  // 这里给出“某访问地址是否命中给定 CSR id”的统一判定：
  //   - 普通 CSR：addr == id
  // VS/S 别名的特殊判定在核内按具体 CSR 处理（见 NewCSR.sv §A/§B 注释）。
  function automatic logic addr_hit(input logic [ADDR_W-1:0] addr,
                                    input logic [ADDR_W-1:0] id);
    return addr == id;
  endfunction

  // 是否落在性能计数器读写地址区间（mcycle..mhpmcounter31 / cycle..hpmcounter31）。
  // 用于 io.out.bits.isPerfCnt。
  function automatic logic in_perf_cnt_range(input logic [ADDR_W-1:0] addr);
    logic m_range, u_range;
    m_range = (addr >= 12'hB00) && (addr <= 12'hB1F); // mcycle..mhpmcounter31
    u_range = (addr >= 12'hC00) && (addr <= 12'hC1F); // cycle..hpmcounter31
    return m_range || u_range;
  endfunction

  // 是否为 topi/topei 类（仅读时计入 perf）。
  function automatic logic is_topi_addr(input logic [ADDR_W-1:0] addr);
    return (addr == 12'hEB0) || (addr == 12'h35C) || // vstopi / vstopei
           (addr == 12'h15B) || (addr == 12'h15C) || // stopi  / stopei (示意)
           (addr == 12'hFB0) || (addr == 12'h35C);    // mtopi  / mtopei (示意)
  endfunction

endpackage : newcsr_pkg
