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

  // 内层 L2TLB 吐出的 19 路 perf 原始计数（黑盒输出，未打拍）。
  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_raw;

  // 2 级打拍寄存器组（每事件两级）：
  //   stage1 = golden 的 io_perf_<i>_value_REG   (取内层原值)
  //   stage2 = golden 的 io_perf_<i>_value_REG_1 (取 stage1，对外输出)
  //   用两个扁平数组而非 2 级 packed struct：后者展平成 perf_pipe_reg[i]\[stage][s][b]，
  //   与 golden 的 io_perf_<i>_value_REG[_1]_reg[b] 名字/签名对不上→ FM 留 114 个未匹配
  //   比较点→假 FAILED。扁平的“每事件每级一个 6bit 寄存器”与 golden 一一对应，
  //   auto_match_flattened_arrays 按签名即可配对。
  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_stage1;  // 第 1 拍
  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_stage2;  // 第 2 拍（输出）

  // ---------------------------------------------------------------------------
  // 内层 L2TLB 黑盒例化
  // ---------------------------------------------------------------------------
  // 除 perf 外的全部端口在此机械直连（见 include）。perf 端口单独连到 perf_raw 数组。
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
  // 与 golden 逐字一致：无复位的纯时钟打拍（golden 是 `always @(posedge clock)`，
  //   仅靠 _RANDOM 初始化，综合视为 0；这里也【不加 reset】以对齐寄存器锥）。
  genvar gi;
  generate
    for (gi = 0; gi < NUM_PERF_EVENTS; gi++) begin : g_perf
      always_ff @(posedge clock) begin
        perf_stage1[gi] <= perf_raw[gi];     // 内层原值 -> 第 1 拍
        perf_stage2[gi] <= perf_stage1[gi];  // 第 1 拍   -> 第 2 拍（输出）
      end
    end
  endgenerate

  // perf 第二级寄存器 -> 扁平的 io_perf_<i>_value 输出端口。
  assign io_perf_0_value  = perf_stage2[0];   assign io_perf_1_value  = perf_stage2[1];
  assign io_perf_2_value  = perf_stage2[2];   assign io_perf_3_value  = perf_stage2[3];
  assign io_perf_4_value  = perf_stage2[4];   assign io_perf_5_value  = perf_stage2[5];
  assign io_perf_6_value  = perf_stage2[6];   assign io_perf_7_value  = perf_stage2[7];
  assign io_perf_8_value  = perf_stage2[8];   assign io_perf_9_value  = perf_stage2[9];
  assign io_perf_10_value = perf_stage2[10];  assign io_perf_11_value = perf_stage2[11];
  assign io_perf_12_value = perf_stage2[12];  assign io_perf_13_value = perf_stage2[13];
  assign io_perf_14_value = perf_stage2[14];  assign io_perf_15_value = perf_stage2[15];
  assign io_perf_16_value = perf_stage2[16];  assign io_perf_17_value = perf_stage2[17];
  assign io_perf_18_value = perf_stage2[18];

endmodule
