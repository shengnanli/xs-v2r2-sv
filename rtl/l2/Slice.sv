// 手写核 + 自动生成机械连线(scripts/gen_slice.py 接管 ports/decls/glue/inst/outassign/
// wrapper/stub/UT;glue 由该脚本以「具名可读重写」方式发出)。
// =====================================================================
// xs_Slice_core —— 香山 V2R2 L2 cache slice(Slice)可读装配核。
//
// Slice(CoupledL2 仓库 src/main/scala/coupledL2/Slice.scala)是 L2 cache **一个 bank**
// 的完整流水装配:北侧接 L1/core 集群的 TileLink 五通道(io_in_a/b/c/d/e),南侧接 CHI
// 桥(io_out_tx_*/io_out_rx_*),内部把请求仲裁(RequestArb)、主流水(MainPipe)、目录
// (Directory)、数据阵列(DataStorage)、MSHR 控制(MSHRCtl,含 16 MSHR)、A/C 通道接收
// (SinkA/SinkC)、D 通道发射(GrantBuffer)、CHI 收发六通道(TX/RX REQ·DAT·RSP·SNP)、
// refill/release 缓冲(MSHRBuffer)与 MBIST 自测(L2Slice)拼成一条真正的 cache 流水线,
// 对外吐出 dirResult / prefetch train·resp / l1Hint / perf / error / l2Miss。
//
// 子模块(18 种类型 / 18 个实例,**本层全部 golden 黑盒**,UT/FM 两侧共用):
//   RequestArb reqArb    请求仲裁(A/B/C/replay -> s1/s2/s3,发起目录读)
//   MainPipe_1 mainPipe  主流水(s1~s3 命中判定 / 读改写 / 发 release·refill·grant)
//   Directory  directory 目录(tag/meta SRAM + 替换,本 bank snoop filter)
//   DataStorage dataStorage 数据阵列(ECC data SRAM 读写)
//   MSHRCtl    mshrCtl   MSHR 控制(miss/probe 状态机阵列 + 任务下发,含 16 MSHR)
//   RequestBuffer reqBuf A 通道请求缓冲(阻塞冲突 set/way)
//   SinkA sinkA / SinkC sinkC   A/C 通道接收
//   GrantBuffer grantBuf D 通道发射缓冲(grant/grantData/releaseAck + sink id)
//   TXREQ/TXDAT/TXRSP    CHI 发送三通道       RXSNP/RXDAT/RXRSP  CHI 接收三通道
//   MSHRBuffer refillBuf / MSHRBuffer_1 releaseBuf   refill/release 数据缓冲
//   L2Slice mbistPl      MBIST 自测流水分发(接 boreChildrenBd_bore_*)
//
// 本层逻辑 = 子模块例化 + 互联布线 + 极少量打拍/探针(见 _glue/_inst/_outassign.svh):
//   (1) MBIST bore 改名 wire bd_X = boreChildrenBd_bore_X;(纯连线,喂 mbistPl);
//   (2) error/perf 打拍(本层唯二时序 glue,两个 always:异步复位 2 拍 + 同步 error 1
//       拍 / 11 路 perf 各 2 级 RegNext);
//   (3) dontTouch 探针 assign _probe_<k> = <子模块输出>;(死端,综合丢弃);
//   (4) 顶层 io 输出:24 条 assign + 绝大多数由子模块输出引脚直驱(firtool 风格)。
//
// golden Slice.sv 全文 10019 行,firtool 实测无 `_T_<n>`/`_GEN_<n>` 匿名临时名;唯一触
// 套壳闸门的 perf 第二级 RegNext(io_perf_<N>_value_REG_1)已重写为具名两级流水
// perf_<N>_value_s1 -> perf_<N>_value_s2。套壳闸门(去注释)
// `_T_<n>`/`_GEN_`/`_REG_<n>`/io_*_n_m/RANDOMIZE = 0。
//
// 类型/参数见 slice_pkg.sv;子模块黑盒输出/互联网见 slice_decls.svh;
// 顶层 glue(MBIST 改名 / error·perf 打拍)见 slice_glue.svh;
// 子模块例化 + 引脚连核内具名信号/互联网见 slice_inst.svh;
// 顶层 io 输出 + 探针 + bore 回吐 assign 见 slice_outassign.svh。
// =====================================================================
import slice_pkg::*;

module xs_Slice_core (
  input clock,
  input reset,
`include "slice_ports.svh"
);

  // ===================================================================
  // 子模块黑盒输出/互联网声明(供 glue/inst/outassign 消费)。
  //   _<inst>_io_*  : 子模块输出网;bd_*/childBd_* : MBIST 自测流水互联网;
  //   _probe[_k]    : dontTouch 探针网(死端,综合丢弃)。
  // ===================================================================
`include "slice_decls.svh"

  // ===================================================================
  // 顶层 glue(从 Scala 意图重写,golden 已具名可读):
  //   (1) MBIST bore 改名 wire bd_X = boreChildrenBd_bore_X;
  //   (2) error/perf 打拍流水(本层唯二时序 glue,两个 always)。
  // ===================================================================
`include "slice_glue.svh"

  // ===================================================================
  // 18 子模块黑盒例化 + 引脚连核内具名信号/互联网(纯机械,gen_slice.py 生成)。
  //   北侧 L1/core:io_in_a/c 经 SinkA/SinkC 进 reqArb,grantBuf 经 io_in_b/d 回吐;
  //   主路径:    reqArb -> mainPipe -> directory/dataStorage/mshrCtl(目录命中/分配 MSHR);
  //   南侧 CHI:  mshrCtl/mainPipe 经 TX* 下发,RX* 上送 mshrCtl;mbistPl 旁路自测。
  // ===================================================================
`include "slice_inst.svh"

  // ===================================================================
  // 顶层 io 输出 assign + dontTouch 探针 + MBIST bore 回吐。
  //   io_dirResult_valid 含一处与运算门控(resp_valid & ~replResp_valid),余为直连。
  // ===================================================================
`include "slice_outassign.svh"

endmodule
