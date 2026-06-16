// =============================================================================
// DCacheWrapper —— L1 数据缓存（DCache）顶层包装层（可读重写）
// -----------------------------------------------------------------------------
// 设计意图来源（从 Scala 重实现，非读 golden RTL 改名）：
//   src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala
//     class DCacheWrapper extends LazyModule {
//       val dcache = LazyModule(new DCache())        // 内层真正的 L1 DCache
//       clientNode := dcache.clientNode              // TileLink client 透传(IdentityNode)
//       dcache.cacheCtrlOpt.node := uncacheNode      // cache-ctrl TL-UL 透传(IdentityNode)
//       class DCacheWrapperImp ... {
//         io <> dcache.module.io                     // 整个 DCacheIO 直连内层
//         dcache.module.getPerfEvents                // 收集 perf 计数
//         generatePerfEvent()                        // -> 各 perf value 打 2 级寄存器输出
//       }
//     }
//
// 角色定位（在访存子系统 MemBlock 中）：
//   DCacheWrapper 是 L1 DCache 与外界之间的「薄」包装层，本身不含 cache 算法。
//   它做三件事：
//     1. 端口适配：把上游各客户端（LoadUnit*N、StoreUnit/STA*N、Sbuffer-store、
//        AMO、prefetch、CMO、控制/调试/perf）的请求/响应端口一一直连内层 DCache。
//        load/store 多端口的仲裁、bank 冲突判定、miss 队列等都在内层 DCache 里，
//        本层只是接线，不做仲裁。
//     2. 节点透传：内层 DCache 的 TileLink client 口（向 L2 取数/写回/probe）经
//        diplomacy IdentityNode 原样引出为 auto_client_out_*；cache-controller 的
//        TL-UL 从机口经另一 IdentityNode 引出为 auto_uncache_in_*（内层端口名是
//        auto_cacheCtrlOpt_in_*，此处仅节点改名，信号一一对应）。
//     3. perf 计数 2 级流水：内层 DCache 吐出 32 个 6bit perf event 计数值，
//        本层将每个计数值打两拍寄存器后输出（generatePerfEvent 的标准做法，
//        用于跨层时序收敛 / 与其它单元 perf 对齐）。这是本包装层【唯一】的时序逻辑。
//
// 验证：内层 DCache 是巨型子模块（golden DCache.sv ~1.08MB），UT/FM 两侧均黑盒，
//       本层只验证「互联映射 + perf 2 级流水」等价。
//
// 结构说明：
//   * 端口表（与 golden 顶层逐字段一致，603 端口）见 dcachewrapper_ports.svh（生成）。
//   * 内层 DCache 黑盒的机械互联（569 个非 perf 端口，含 auto_uncache_in_* 改名）
//     见 dcachewrapper_inner_conn.svh（生成）。
//   * perf 2 级流水用 struct packed + enum + function automatic + genvar 表达（本文件）。
//   两个 include 都是「机械接线」，不含设计决策；设计意图集中体现在下方 perf 流水。
// =============================================================================
module xs_DCacheWrapper_core(
`include "dcachewrapper_ports.svh"
);

  // ---------------------------------------------------------------------------
  // perf event 流水参数
  // ---------------------------------------------------------------------------
  // 内层 DCache 汇总了 32 个性能事件（命中/缺失/refill/probe/replace/...），
  // 每个事件本拍计数值宽 PERF_W 位（6 位，足够计 0..63 的逐拍增量）。
  localparam int NUM_PERF_EVENTS = 32; // 与 DCacheIO 的 perf 向量长度一致
  localparam int PERF_W          = 6;  // 单个 perf value 位宽

  // 流水级编号：内层吐出的原值 -> 第 1 拍 -> 第 2 拍输出。
  // 用 enum 表达「2 级打拍」的级序，使下标有意义而非裸 0/1。
  typedef enum int {
    PERF_STAGE_1 = 0, // 第一级寄存器（对应 golden 的 *_REG）
    PERF_STAGE_2 = 1, // 第二级寄存器（golden 里的第二级打拍，即对外输出）
    PERF_NSTAGE  = 2
  } perf_stage_e;

  // 一个 perf 事件的 2 级流水寄存器组。把同一事件的两级聚合成 struct，
  // 而非散落 64 个独立标量 reg，便于按事件成组推进/复位。
  typedef struct packed {
    // 打包 2 级寄存器：stage[0]=第1拍, stage[1]=第2拍(输出)。
    // 用 packed 向量数组（非 unpacked），以满足 struct packed 约束。
    logic [PERF_NSTAGE-1:0][PERF_W-1:0] stage;
  } perf_pipe_t;

  // 纯函数：推进一个事件的 2 级流水（移位寄存器语义）。
  //   新原值进 stage1；stage1 旧值进 stage2（输出）。
  // 用函数表达「流水推进」这一意图，避免在 always 里手写两条赋值、逐事件复制。
  function automatic perf_pipe_t perf_advance(perf_pipe_t cur, logic [PERF_W-1:0] raw);
    perf_pipe_t nxt;
    nxt.stage[PERF_STAGE_2] = cur.stage[PERF_STAGE_1]; // 第1拍旧值 -> 第2拍
    nxt.stage[PERF_STAGE_1] = raw;                     // 内层原值 -> 第1拍
    return nxt;
  endfunction

  // 内层 DCache 吐出的 32 路 perf 原始计数（黑盒输出，未打拍）。
  // 用 packed 2D（[事件][位]）而非 unpacked 数组：unpacked 数组元素到黑盒引脚的
  // 绑定在某些 EDA 工具的位级展平下会与下标产生歧义，packed 向量则逐位确定。
  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_raw;
  // 32 路事件各自的 2 级流水寄存器。
  perf_pipe_t        perf_pipe [NUM_PERF_EVENTS];
  // 各事件第二级寄存器值（对外 perf 输出）。
  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_out;

  // ---------------------------------------------------------------------------
  // 内层 DCache 黑盒例化
  // ---------------------------------------------------------------------------
  // 除 perf 外的全部端口在此机械直连（见 include）。perf 端口在下方 generate 中
  // 单独连到 perf_raw 数组，再经流水寄存器输出。
  DCache dcache (
`include "dcachewrapper_inner_conn.svh"
    // ---- 32 路 perf event 计数值：内层原始输出接入 perf_raw[] ----
    .io_perf_0_value (perf_raw[0]),   .io_perf_1_value (perf_raw[1]),
    .io_perf_2_value (perf_raw[2]),   .io_perf_3_value (perf_raw[3]),
    .io_perf_4_value (perf_raw[4]),   .io_perf_5_value (perf_raw[5]),
    .io_perf_6_value (perf_raw[6]),   .io_perf_7_value (perf_raw[7]),
    .io_perf_8_value (perf_raw[8]),   .io_perf_9_value (perf_raw[9]),
    .io_perf_10_value(perf_raw[10]),  .io_perf_11_value(perf_raw[11]),
    .io_perf_12_value(perf_raw[12]),  .io_perf_13_value(perf_raw[13]),
    .io_perf_14_value(perf_raw[14]),  .io_perf_15_value(perf_raw[15]),
    .io_perf_16_value(perf_raw[16]),  .io_perf_17_value(perf_raw[17]),
    .io_perf_18_value(perf_raw[18]),  .io_perf_19_value(perf_raw[19]),
    .io_perf_20_value(perf_raw[20]),  .io_perf_21_value(perf_raw[21]),
    .io_perf_22_value(perf_raw[22]),  .io_perf_23_value(perf_raw[23]),
    .io_perf_24_value(perf_raw[24]),  .io_perf_25_value(perf_raw[25]),
    .io_perf_26_value(perf_raw[26]),  .io_perf_27_value(perf_raw[27]),
    .io_perf_28_value(perf_raw[28]),  .io_perf_29_value(perf_raw[29]),
    .io_perf_30_value(perf_raw[30]),  .io_perf_31_value(perf_raw[31])
  );

  // ---------------------------------------------------------------------------
  // perf event 2 级流水 + 输出
  // ---------------------------------------------------------------------------
  // 32 路事件结构完全一致，用 generate/for 统一推进，不手工展开 32*2 条赋值。
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

  // perf_out 数组 -> 扁平的 io_perf_<i>_value 输出端口（端口表里是 32 个标量）。
  assign io_perf_0_value  = perf_out[0];   assign io_perf_1_value  = perf_out[1];
  assign io_perf_2_value  = perf_out[2];   assign io_perf_3_value  = perf_out[3];
  assign io_perf_4_value  = perf_out[4];   assign io_perf_5_value  = perf_out[5];
  assign io_perf_6_value  = perf_out[6];   assign io_perf_7_value  = perf_out[7];
  assign io_perf_8_value  = perf_out[8];   assign io_perf_9_value  = perf_out[9];
  assign io_perf_10_value = perf_out[10];  assign io_perf_11_value = perf_out[11];
  assign io_perf_12_value = perf_out[12];  assign io_perf_13_value = perf_out[13];
  assign io_perf_14_value = perf_out[14];  assign io_perf_15_value = perf_out[15];
  assign io_perf_16_value = perf_out[16];  assign io_perf_17_value = perf_out[17];
  assign io_perf_18_value = perf_out[18];  assign io_perf_19_value = perf_out[19];
  assign io_perf_20_value = perf_out[20];  assign io_perf_21_value = perf_out[21];
  assign io_perf_22_value = perf_out[22];  assign io_perf_23_value = perf_out[23];
  assign io_perf_24_value = perf_out[24];  assign io_perf_25_value = perf_out[25];
  assign io_perf_26_value = perf_out[26];  assign io_perf_27_value = perf_out[27];
  assign io_perf_28_value = perf_out[28];  assign io_perf_29_value = perf_out[29];
  assign io_perf_30_value = perf_out[30];  assign io_perf_31_value = perf_out[31];

endmodule
