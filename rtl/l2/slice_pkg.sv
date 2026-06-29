// ============================================================================
// slice_pkg —— 香山 V2R2 L2 cache slice(Slice)边界类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源:CoupledL2 仓库 src/main/scala/coupledL2/Slice.scala
//
// Slice 是「L2 cache 一个 bank」的完整流水装配:北侧接 L1/core 集群的 TileLink 五通道
// (io_in_a/b/c/d/e),南侧接 CHI 桥(io_out_tx_*/io_out_rx_*),内部把请求仲裁、主流水、
// 目录、数据阵列、MSHR 控制、各通道 sink/source/tx/rx 队列、MBIST 自测拼成一条真正的
// cache 流水线,对外吐出 dirResult / prefetch train·resp / l1Hint / perf / error。
//
// 子模块(18 种类型 / 18 个实例,本层 golden 黑盒,UT/FM 两侧共用):
//   RequestArb reqArb    请求仲裁:A/B/C/replay 任务排队进 s1/s2/s3 流水,发起目录读。
//   MainPipe_1 mainPipe  主流水:s1~s3 命中判定 / 读改写 / 发 release·refill·grant。
//   Directory  directory 目录:tag/meta SRAM + 替换算法(本 bank 的 snoop filter)。
//   DataStorage dataStorage 数据阵列:ECC data SRAM 读写。
//   MSHRCtl    mshrCtl   MSHR 控制:miss/probe 状态机阵列 + 任务下发(含 16 个 MSHR)。
//   RequestBuffer reqBuf A 通道请求缓冲:阻塞冲突 set/way 的 acquire。
//   SinkA  sinkA / SinkC sinkC   A/C 通道接收(acquire·get·pf / release·probeAck)。
//   GrantBuffer grantBuf D 通道发射缓冲:grant/grantData/releaseAck + sink id 管理。
//   TXREQ/TXDAT/TXRSP    CHI 发送三通道(req/dat/rsp flit 组装下发)。
//   RXSNP/RXDAT/RXRSP    CHI 接收三通道(snoop/dat/rsp flit 拆解上送)。
//   MSHRBuffer refillBuf / MSHRBuffer_1 releaseBuf  refill/release 数据缓冲。
//   L2Slice mbistPl      MBIST 自测流水分发(SRAM 内建自测,接 boreChildrenBd_bore_*)。
//
// 本层真正属于「顶层 glue」的部分(Scala 里多为 `<>`/`:=` 连线 + 少量 RegNext):
//   (1) MBIST bore 改名:wire bd_X = boreChildrenBd_bore_X;(9 条,纯连线,喂 mbistPl);
//   (2) error/perf 打拍(本层唯二时序 glue,两个 always):
//         · 异步复位块:releaseBufResp_s3_valid / io_error_valid 各打一拍;
//         · 同步块:    io_error_bits 打一拍 + 11 路 perf 事件各 2 级 RegNext(s1->s2)。
//   (3) dontTouch 探针:assign _probe_<k> = <子模块输出>;(4 条,死端,综合丢弃);
//   (4) 顶层 io 输出 assign:24 条(dirResult/error/perf 打拍 / bore 回吐),绝大多数 io
//       输出则由子模块输出引脚直驱(firtool 风格,见 slice_inst.svh)。
//
// golden Slice.sv 全文 10019 行,firtool 实测**无 `_T_<n>`/`_GEN_<n>` 匿名临时名**;
// 唯一触套壳闸门的是 perf 第二级 RegNext 名 io_perf_<N>_value_REG_1(_REG_<数字>),本
// 工程重写为具名两级 perf_<N>_value_s1 -> perf_<N>_value_s2(见 slice_glue.svh)。
// 故本包仅放 slice 边界宽度常量(其余全是子模块直通/打拍,落在 *_ports/_decls/_glue/
// _inst/_outassign.svh)。
//
// 注:Slice_1/2/3 与本模块仅差 sliceId(0/1/2/3)+ 子模块变体名(Directory_1 等);
// Slice_4 是 OpenLLC home-node slice(完全不同模块)。本包对应基准 Slice(sliceId=0)。
// ============================================================================
package slice_pkg;

  // ----- slice 北侧 TileLink(L1/core 集群)边界宽度 -----
  localparam int TLSourceW   = 7;    // io_in_*_bits_source(client source id)
  localparam int TLAddrW     = 48;   // io_in_*_bits_address(物理地址)
  localparam int TLDataW     = 256;  // io_in_b/c/d_bits_data(一个 beat)
  localparam int TLSinkW     = 8;    // io_in_d/e_bits_sink(grant sink id)
  localparam int VAddrW      = 44;   // user_vaddr / prefetch vaddr

  // ----- slice 南侧 CHI(home node)边界宽度 -----
  localparam int ChiTxnIDW   = 12;   // io_out_tx_*_bits_txnID
  localparam int ChiNIDW     = 11;   // returnNID / tgtID / srcID
  localparam int ChiReqOpW   = 7;    // io_out_tx_req_bits_opcode

  // ----- slice 内部规模 -----
  localparam int NrMSHR      = 16;   // MSHR 条目数(mshr_alloc_ptr 8b one-hot 风格)
  localparam int SetBits     = 9;    // io_*_set(cache set 索引)
  localparam int TagBits     = 33;   // prefetch tag

  // ----- perf 事件 -----
  localparam int NrPerf      = 11;   // 对外 io_perf_<N>_value(N=0,1,3..11,跳过 2)
  localparam int PerfW       = 6;    // 每个 perf 计数位宽

endpackage
