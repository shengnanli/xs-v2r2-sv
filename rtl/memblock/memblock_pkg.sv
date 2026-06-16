// ============================================================================
// memblock_pkg —— MemBlock（访存子系统总集成）的公共常量与架构参数
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/mem/MemBlock.scala
//   （class MemBlockInlined / MemBlockInlinedImp）
//
// MemBlock 是香山 V2R2（昆明湖）访存子系统的**顶层互联**。它本身不含访存算法，
// 而是把后端发来的 load/store/atomic/向量访存请求路由到各功能单元，并在它们之间
// 做仲裁、互联、异常聚合、CSR/触发器分发与性能汇聚。各功能单元（执行流水、队列、
// 缓存、TLB、PTW、预取器、TileLink 缓冲）都封装在子模块内，对本层是黑盒。
//
// 本包只放**架构维度参数**（各类单元的数目/宽度），供阅读时把握访存子系统的“规模”。
// 巨型互联的实际连线在 memblock_nets.svh / memblock_logic.svh / memblock_inst.svh，
// 由 scripts/gen_memblock.py 从 golden 端口/实例表机械生成（剥离 firtool 样板）。
// ============================================================================
package memblock_pkg;

  // ---- 执行流水单元数目（本配置 KunminghuV2R2）----
  localparam int LDU_CNT   = 3;   // LoadUnit：load 执行流水（查 DTLB/DCache/forward）
  localparam int STA_CNT   = 2;   // StoreUnit：store 地址流水
  localparam int STD_CNT   = 2;   // stdExeUnit(MemExeUnit)：store 数据流水
  localparam int HYU_CNT   = 0;   // HybridUnit：本配置未启用
  localparam int VLDU_CNT  = 2;   // 向量 load 拆分（VLSplitImp）
  localparam int VSTU_CNT  = 2;   // 向量 store 拆分（VSSplitImp）

  // ---- DTLB（数据侧 TLB，非阻塞）----
  //   dtlb_ld（LDU_CNT+HYU_CNT+1 路）/ dtlb_st（STA_CNT 路）/ dtlb_pf（2 路）
  localparam int DTLB_LD_PORTS = LDU_CNT + HYU_CNT + 1; // 4：3 个 load + 1 个原子/misalign
  localparam int DTLB_ST_PORTS = STA_CNT;               // 2
  localparam int DTLB_PF_PORTS = 2;                     // 2：预取
  localparam int DTLB_SIZE     = DTLB_LD_PORTS + DTLB_ST_PORTS + DTLB_PF_PORTS; // 8

  // ---- PMP / PMPChecker ----
  //   1 个 PMP（存 PMP/PMA 表项）+ 每个 DTLB 端口一个 PMPChecker（共 DTLB_SIZE 个）
  localparam int PMP_CHECKER_CNT = DTLB_SIZE; // 8

  // ---- 队列 / 缓冲规模（与子模块一致，仅供阅读参考）----
  localparam int SBUFFER_ENTRIES = 16;  // store 写合并缓冲表项
  localparam int LSQ_ENQ_WIDTH   = 6;   // dispatch 一拍最多入队的访存 uop 数

  // ---- CSR 触发器（debug trigger）数目：tdata 表项 ----
  localparam int TRIGGER_NUM     = 4;   // tdata_0..3（matchType/select/timing/action/...）

  // ---- 顶层性能事件（HPM）----
  localparam int PERF_OUT_NUM    = 8;   // io_perf_0..7
  localparam int PERF_W          = 6;   // 每个计数器位宽

  // 一路 perf 计数（HPerfMonitor 给出的事件计数值）
  typedef logic [PERF_W-1:0] perf_cnt_t;

  // 触发器（debug trigger）匹配类型（CSR tdata1.matchType，2 bit）。用 enum 表达
  // 离散语义，供阅读 CSR/触发器分发逻辑时对照（实际比较在各 LoadUnit/StoreUnit 内）。
  typedef enum logic [1:0] {
    TRIG_MATCH_EQ   = 2'd0,  // 相等匹配
    TRIG_MATCH_GE   = 2'd1,  // 大于等于（NAPOT 下界）
    TRIG_MATCH_LT   = 2'd2,  // 小于（NAPOT 上界）
    TRIG_MATCH_MASK = 2'd3   // 掩码匹配
  } trig_match_e;

  // 一个 debug trigger 表项（CSR tdata1/tdata2 解出的访存断点配置）。MemBlock 顶层
  // 把 CSR 写下的 TRIGGER_NUM(=4) 个 tdata 寄存一份再广播给各 LoadUnit/StoreUnit；
  // 这里用 struct 表达其字段语义（golden 展平成 inner_tdata_<n>_<field> 标量），
  // 字段含义对照 docs/memblock/MemBlock.md §2.1 CSR/触发器分发。
  typedef struct packed {
    trig_match_e       matchType;  // 匹配类型（见 trig_match_e）
    logic              select;     // 0=匹配地址，1=匹配数据
    logic              timing;     // 触发时机（before/after）
    logic [3:0]        action;     // 命中动作（断点/调试等）
    logic              chain;      // 与下一个 trigger 链式与
    logic              store;      // 对 store 生效
    logic              load;       // 对 load 生效
    logic [63:0]       tdata2;     // 比较值 / 掩码
  } trigger_tdata_t;

  // 纯函数：6-bit perf 计数饱和判零（仅作可读示例，表达“该事件本拍是否发生”）。
  function automatic logic perf_active(input perf_cnt_t c);
    return |c;
  endfunction

endpackage
