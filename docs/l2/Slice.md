# Slice —— L2 cache slice 主体装配(一个 bank 的完整 cache 流水)

> 设计源:CoupledL2 仓库 `src/main/scala/coupledL2/Slice.scala`
> 可读核:`rtl/l2/Slice.sv`(`xs_Slice_core`)+ `rtl/l2/slice_pkg.sv`
> 18 个子模块实例(18 种类型)全部作 golden 黑盒(UT/FM 两侧共用)。
> 生成器:`scripts/gen_slice.py`(派生自 `gen_l2top.py`,新增 perf 二级流水具名重写)

Slice 是「L2 cache 一个 bank」的完整流水装配:北侧接 L1/core 集群的 TileLink 五通道
(`io_in_a/b/c/d/e`),南侧接 CHI 桥(`io_out_tx_*` / `io_out_rx_*`),内部把请求仲裁、主
流水、目录、数据阵列、MSHR 控制、A/C 通道接收、D 通道发射、CHI 收发六通道、refill/release
缓冲与 MBIST 自测拼成一条真正的 cache 流水线,对外吐出 `dirResult` / `prefetch train·resp`
/ `l1Hint` / `perf` / `error` / `l2Miss`。它本身**不重写任何功能块的内部逻辑**,只把子模块
例化、互联,外加一小撮顶层 glue。

golden `Slice.sv` 全文 10019 行,firtool 实测**无 `_T_<n>` / `_GEN_<n>` 匿名临时名**;唯一触
套壳闸门的是 perf 第二级 RegNext 名 `io_perf_<N>_value_REG_1`(`_REG_<数字>`),本工程已重写
为具名两级流水。故本层逻辑 = 子模块例化 + 互联布线 + 极少量打拍/探针。

## 子模块构成(18 种类型 / 18 个实例,全 golden 黑盒)

| 类型 | 实例 | 作用 |
|------|------|------|
| `RequestArb` | `reqArb` | 请求仲裁:A/B/C/replay 任务排队进 s1/s2/s3 流水,发起目录读 |
| `MainPipe_1` | `mainPipe` | 主流水:s1~s3 命中判定 / 读改写 / 发 release·refill·grant |
| `Directory` | `directory` | 目录:tag/meta SRAM + 替换算法(本 bank 的 snoop filter) |
| `DataStorage` | `dataStorage` | 数据阵列:ECC data SRAM 读写 |
| `MSHRCtl` | `mshrCtl` | MSHR 控制:miss/probe 状态机阵列 + 任务下发(含 16 个 MSHR) |
| `RequestBuffer` | `reqBuf` | A 通道请求缓冲:阻塞冲突 set/way 的 acquire |
| `SinkA` / `SinkC` | `sinkA` / `sinkC` | A/C 通道接收(acquire·get·pf / release·probeAck) |
| `GrantBuffer` | `grantBuf` | D 通道发射缓冲:grant/grantData/releaseAck + sink id 管理 |
| `TXREQ` / `TXDAT` / `TXRSP` | `txreq` / `txdat` / `txrsp` | CHI 发送三通道(req/dat/rsp flit 组装下发) |
| `RXSNP` / `RXDAT` / `RXRSP` | `rxsnp` / `rxdat` / `rxrsp` | CHI 接收三通道(snoop/dat/rsp flit 拆解上送) |
| `MSHRBuffer` / `MSHRBuffer_1` | `refillBuf` / `releaseBuf` | refill / release 数据缓冲 |
| `L2Slice` | `mbistPl` | MBIST 自测流水分发(SRAM 内建自测,接 `boreChildrenBd_bore_*`) |

> `Slice_1/2/3` 与本模块仅差 `sliceId`(0/1/2/3)+ 子模块变体名
> (`Directory_1` / `DataStorage_1` / `L2Slice_1` 等),装配结构与 glue 完全一致(diff 仅 12 行);
> `Slice_4` 是 OpenLLC home-node slice(`MemUnit`/`RefillUnit`/`ResponseUnit`/`SnoopUnit`,完全
> 不同模块)。本核对应基准 `Slice`(sliceId=0)。

## 顶层 glue(从 Scala 意图重写,golden 已具名可读)

本层共四块顶层逻辑,落在 `slice_glue.svh`(1·2)与 `slice_outassign.svh`(3·4):

- **(1) MBIST bore 改名** —— 9 条 `wire bd_X = boreChildrenBd_bore_X;`(`array`/`all`/`req`/
  `writeen`/`be`/`addr`/`indata`/`readen`/`addr_rd`),把对外 MBIST 端口改名喂 `mbistPl`,纯连线。
- **(2) error/perf 打拍流水** —— **本层唯二的时序 glue**(两个 `always`):
  - **异步复位块**(`always @(posedge clock or posedge reset)`):`mainPipe` 的
    `releaseBufResp_s3_valid` 由 `reqArb.releaseBufRead_s2_valid` 打一拍;`io_error_valid` 由
    `mainPipe.error_valid` 打一拍。
  - **同步块**(`always @(posedge clock)`):`io_error_bits`(valid/address)打一拍;**11 路 perf
    事件各 2 级 `RegNext`**(`perf_<N>_value_s1` → `perf_<N>_value_s2`,N=0,1,3..11,跳过 2;
    源:`mshrCtl` 提供 0/1/3,`mainPipe` 提供 4..11)。golden 把第二级命名为
    `io_perf_<N>_value_REG_1`(`_REG_<数字>`,触套壳闸门),本工程**具名重写为两级流水**
    `perf_<N>_value_s1` / `perf_<N>_value_s2`(这两级只喂 `io_perf` 输出 assign,不被任何子模块
    引脚引用,改名安全)。
- **(3) dontTouch 探针** —— 4 条 `assign _probe_<k> = <子模块输出>;`(`sinkC.refillBufWrite_valid`
  / `directory.resp_bits_way` / `mainPipe.mshr_alloc_s3_valid` / `mshrCtl.mshr_alloc_ptr`),死端,
  综合丢弃。另有 `wire _probe = reqBuf.io_hasMergeA`(亦 dontTouch 死端)。
- **(4) 顶层 io 输出** —— 24 条 `assign`(`dirResult` 4 条 / `error` 3 条 / `perf` 11 条 / bore 回吐
  2 条 / probe 4 条)+ **绝大多数 io 输出由子模块输出引脚直驱**(firtool 风格,见 `slice_inst.svh`,
  329 处 io 名出现为引脚 rhs)。`io_dirResult_valid` 是唯一带运算的 assign:
  `_directory_io_resp_valid & ~_directory_io_replResp_valid`(与运算门控)。

## 核结构指标(实测)

| 指标 | 值 |
|------|----|
| 顶层功能端口 | 465(含 clock/reset;203 input / 260 output) |
| 子模块实例 / 类型 | 18 / 18 |
| 子模块输出/互联网声明(decls) | 1552 |
| glue:MBIST bore 改名 | 9 |
| glue:reg 声明 | 26(error 4 + perf 22) |
| glue:时序行(2 个 always:异步复位 + 同步打拍) | 10 + 26 |
| io 输出 + 探针 + bore 回吐 assign | 24 |
| 例化悬空端口(`.pin ()`) | 98(忠实复刻 golden dontTouch 输出) |
| **套壳闸门**(`_T_<n>`/`_GEN_`/`_REG_<编号>`/`io_*_n_m`/`RANDOMIZE`,去注释) | **0**(全 7 个源文件) |

## 产物

- 可读核:`rtl/l2/Slice.sv`(`xs_Slice_core`)+ `rtl/l2/slice_pkg.sv`
- 机械 svh:`slice_ports.svh` / `slice_decls.svh` / `slice_glue.svh` / `slice_inst.svh` / `slice_outassign.svh`
- FM/ST:`Slice_wrapper.sv`(golden 同名扁平 wrapper,例化可读核)
- 黑盒 stub:`slice_blackbox_stubs.sv`(18 类型空体,仅备快速 elaborate)
- UT:`verif/ut/Slice/`(`tb.sv` / `variants_xs.sv` / `Makefile` / `golden_filelist.f`)
- 生成器:`scripts/gen_slice.py`

## 验证

**UT(权威):双例化逐拍比对 golden 全部 260 个输出**(`!$isunknown` 门控,`+define+SYNTHESIS`,
`+vcs+initreg+0`,golden 叶子传递闭包 `-f golden_filelist.f` = 82 模块/82 文件)。

| seed | NCYCLES | checks | errors | 结果 |
|------|---------|--------|--------|------|
| 1  | 120000 | 120000 | 0 | TEST PASSED(distinct_diverging_ports=0/260) |
| 7  | 120000 | 120000 | 0 | TEST PASSED(0/260) |
| 42 | 120000 | 120000 | 0 | TEST PASSED(0/260) |

**FM(子模块两侧黑盒,纯比对装配层 glue)**:`ref = golden Slice.sv` 单文件、`impl = slice_pkg
+ Slice 核 + wrapper`,两侧 18 个直接子模块全部 `hdlin_unresolved_modules black_box`。结果
**35733 / 35734 compare point Passing**,**唯一 1 个 Failing 是 BBPin `reqBuf/io_hasMergeA`**——它
驱动 golden 的 dontTouch 死网 `_probe`(`Slice.sv:557 wire _probe;`,仅被 `reqBuf.io_hasMergeA` 驱动、
之后从不读取),在 ref 侧是 undriven cut-point,FM 无法对这一个黑盒悬空管脚证明等价。这是
**dontTouch 探针固有 FM 伪差**(任务已预告 Slice 带 `_probe` bore、不可 ST 替换),与装配层 glue
等价性无关——**顶层 glue(perf/error 打拍、MBIST 改名、全部互联)0 failing**。以 120k×3 UT 为权威
等价证明。

## -f 闭包 filelist 机制

同 L2Top/XSCore:`gen_slice.py` 从 `Slice` 顶起做 golden 模块传递闭包(`golden_closure`),每文件
列一次到 `golden_filelist.f`,VCS 用 `-f` 显式编译——**不用 `-y`**,因 golden 叶子多为自包含
`package`+`module` 文件,`-y` 会重复解析触发 `Package previously declared`。Slice 闭包 = 82 模块/82
文件(3.2 MB,含 Directory→SubDirectory→SRAM、MainPipe、MSHRCtl→MSHR 等全部叶子),编译 ~4s。
