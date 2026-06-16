// =============================================================================
// L2TLBWrapper —— 共享 MMU / L2TLB 顶层包装层（可读重写）
// -----------------------------------------------------------------------------
// 设计意图来源（从 Scala 重实现，非读 golden RTL 改名）：
//   src/main/scala/xiangshan/cache/mmu/L2TLB.scala
//     class L2TLBWrapper()(implicit p) extends LazyModule {
//       val node = TLIdentityNode()                // 向 L2 取页表项的 TL 透传(IdentityNode)
//       val ptw  = LazyModule(new L2TLB())         // 内层真正的 L2TLB（PTW + page cache）
//       node := ptw.node                           // 内层 TL client 口经 IdentityNode 引出
//       class L2TLBWrapperImp ... with HasPerfEvents {
//         val io = IO(new L2TLBIO)
//         io <> ptw.module.io                       // 整个 L2TLBIO 直连内层
//         ptw.module.getPerfEvents                  // 收集内层 perf 计数
//         generatePerfEvent()                       // -> 各 perf value 打 2 级寄存器输出
//       }
//     }
//
// 角色定位（在访存子系统的 MMU 中）：
//   L2TLBWrapper 是 L2TLB（页表遍历器 PTW + page cache + miss queue + prefetcher 等）
//   与外界之间的「薄」包装层，本身不含任何 MMU/PTW 算法。它做三件事：
//     1. 端口适配：把上游各 L1 TLB（itlb / ldtlb 等经 io_tlb_0/1）的 miss 请求（vpn /
//        两阶段地址翻译 s2xlate）与页表项响应（s1/s2 entry、ppn、perm、pf/af/gpf/gaf）
//        以及 sfence 刷新、wfi 握手、CSR（satp/vsatp/hgatp/priv 等）一一直连内层 L2TLB。
//        所有 PTW 仲裁、page cache 命中判定、PTE 解析都在内层，本层只是接线。
//     2. 节点透传：内层 L2TLB 的 TileLink client 口（向 L2/内存取页表项，A/D 通道）经
//        diplomacy IdentityNode 原样引出为 auto_out_*；本配置无任何功能端口改名。
//        另有 SRAM DFT/bore 与 clock-gating 透传信号（boreChildrenBd_* /
//        sigFromSrams_* / cg_bore_cgen）原样穿过到内层各 SRAM。
//     3. perf 计数 2 级流水：内层吐出 19 个 6bit perf event 计数值，本层把每个计数值
//        打两拍寄存器后输出（generatePerfEvent 的标准做法，用于跨层时序收敛 / 与其它
//        单元 perf 对齐）。这是本包装层【唯一】的时序逻辑。
//
// 验证：内层 L2TLB 是巨型子模块（golden L2TLB.sv ~787KB），UT/FM 两侧均黑盒，
//       本层只验证「互联映射 + perf 2 级流水」等价。
//
// 结构说明：
//   * 端口表（与 golden 顶层逐字段一致，292 端口）见 l2tlbwrapper_ports.svh（生成）。
//   * 内层 L2TLB 黑盒的机械互联（273 个非 perf 端口，无改名）
//     见 l2tlbwrapper_inner_conn.svh（生成）。
//   * perf 2 级流水用 struct packed + enum + function automatic + genvar 表达（本文件）。
//   两个 include 都是「机械接线」，不含设计决策；设计意图集中体现在下方 perf 流水。
// =============================================================================
module xs_L2TLBWrapper_core(
`include "l2tlbwrapper_ports.svh"
);

  // ---------------------------------------------------------------------------
  // perf event 流水参数
  // ---------------------------------------------------------------------------
  // 内层 L2TLB 汇总了 19 个性能事件（page cache 命中/缺失、PTW 各级访存、prefetch、
  // miss queue 占用等），每个事件本拍计数值宽 PERF_W 位（6 位，计 0..63 的逐拍增量）。
  localparam int NUM_PERF_EVENTS = 19; // 与 L2TLBIO 的 perf 向量长度一致
  localparam int PERF_W          = 6;  // 单个 perf value 位宽

  // 流水级编号：内层吐出的原值 -> 第 1 拍 -> 第 2 拍输出。
  // 用 enum 表达「2 级打拍」的级序，使下标有意义而非裸 0/1。
  typedef enum int {
    PERF_STAGE_1 = 0, // 第一级寄存器（对应 golden 的 *_REG）
    PERF_STAGE_2 = 1, // 第二级寄存器（golden 的第二级打拍，即对外输出）
    PERF_NSTAGE  = 2
  } perf_stage_e;

  // 一个 perf 事件的 2 级流水寄存器组。把同一事件的两级聚合成 struct，
  // 而非散落独立标量 reg，便于按事件成组推进/复位。
  typedef struct packed {
    // 打包 2 级寄存器：stage[0]=第1拍, stage[1]=第2拍(输出)。
    // 用 packed 向量数组（非 unpacked），以满足 struct packed 约束。
    logic [PERF_NSTAGE-1:0][PERF_W-1:0] stage;
  } perf_pipe_t;

  // 纯函数：推进一个事件的 2 级流水（移位寄存器语义）。
  //   新原值进 stage1；stage1 旧值进 stage2（输出）。
  // 用函数表达「流水推进」这一意图，避免在 always 里逐事件手写两条赋值。
  function automatic perf_pipe_t perf_advance(perf_pipe_t cur, logic [PERF_W-1:0] raw);
    perf_pipe_t nxt;
    nxt.stage[PERF_STAGE_2] = cur.stage[PERF_STAGE_1]; // 第1拍旧值 -> 第2拍
    nxt.stage[PERF_STAGE_1] = raw;                     // 内层原值 -> 第1拍
    return nxt;
  endfunction

  // 内层 L2TLB 吐出的 19 路 perf 原始计数（黑盒输出，未打拍）。
  // 用 packed 2D（[事件][位]）而非 unpacked 数组：unpacked 数组元素到黑盒引脚的
  // 绑定在某些 EDA 工具的位级展平下会与下标产生歧义，packed 向量则逐位确定。
  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_raw;
  // 19 路事件各自的 2 级流水寄存器。
  perf_pipe_t        perf_pipe [NUM_PERF_EVENTS];
  // 各事件第二级寄存器值（对外 perf 输出）。
  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_out;

  // ---------------------------------------------------------------------------
  // 内层 L2TLB 黑盒例化
  // ---------------------------------------------------------------------------
  // 除 perf 外的全部端口在此机械直连（见 include）。perf 端口在下方 generate 中
  // 单独连到 perf_raw 数组，再经流水寄存器输出。
  L2TLB ptw (
`include "l2tlbwrapper_inner_conn.svh"
    // ---- 19 路 perf event 计数值：内层原始输出接入 perf_raw[] ----
    .io_perf_0_value (perf_raw[0]),   .io_perf_1_value (perf_raw[1]),
    .io_perf_2_value (perf_raw[2]),   .io_perf_3_value (perf_raw[3]),
    .io_perf_4_value (perf_raw[4]),   .io_perf_5_value (perf_raw[5]),
    .io_perf_6_value (perf_raw[6]),   .io_perf_7_value (perf_raw[7]),
    .io_perf_8_value (perf_raw[8]),   .io_perf_9_value (perf_raw[9]),
    .io_perf_10_value(perf_raw[10]),  .io_perf_11_value(perf_raw[11]),
    .io_perf_12_value(perf_raw[12]),  .io_perf_13_value(perf_raw[13]),
    .io_perf_14_value(perf_raw[14]),  .io_perf_15_value(perf_raw[15]),
    .io_perf_16_value(perf_raw[16]),  .io_perf_17_value(perf_raw[17]),
    .io_perf_18_value(perf_raw[18])
  );

  // ---------------------------------------------------------------------------
  // perf event 2 级流水 + 输出
  // ---------------------------------------------------------------------------
  // 19 路事件结构完全一致，用 generate/for 统一推进，不手工展开 19*2 条赋值。
  // 复位时清零（与 golden 的随机初始化语义一致：SYNTHESIS 下视为 0）。
  genvar gi;
  generate
    for (gi = 0; gi < NUM_PERF_EVENTS; gi++) begin : g_perf
      always_ff @(posedge clock) begin
        if (reset)
          perf_pipe[gi] <= '0;
        else
          perf_pipe[gi] <= perf_advance(perf_pipe[gi], perf_raw[gi]);
      end
      // 第二级寄存器即对外 perf 输出（golden 中 perf 输出取第二级打拍值）。
      assign perf_out[gi] = perf_pipe[gi].stage[PERF_STAGE_2];
    end
  endgenerate

  // perf_out 数组 -> 扁平的 io_perf_<i>_value 输出端口（端口表里是 19 个标量）。
  assign io_perf_0_value  = perf_out[0];   assign io_perf_1_value  = perf_out[1];
  assign io_perf_2_value  = perf_out[2];   assign io_perf_3_value  = perf_out[3];
  assign io_perf_4_value  = perf_out[4];   assign io_perf_5_value  = perf_out[5];
  assign io_perf_6_value  = perf_out[6];   assign io_perf_7_value  = perf_out[7];
  assign io_perf_8_value  = perf_out[8];   assign io_perf_9_value  = perf_out[9];
  assign io_perf_10_value = perf_out[10];  assign io_perf_11_value = perf_out[11];
  assign io_perf_12_value = perf_out[12];  assign io_perf_13_value = perf_out[13];
  assign io_perf_14_value = perf_out[14];  assign io_perf_15_value = perf_out[15];
  assign io_perf_16_value = perf_out[16];  assign io_perf_17_value = perf_out[17];
  assign io_perf_18_value = perf_out[18];

endmodule
