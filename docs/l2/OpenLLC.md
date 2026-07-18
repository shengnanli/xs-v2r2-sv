# OpenLLC —— 外挂 L3 缓存(CHI home node)装配层

> ⚠ **FM 分类 = ASSEMBLY_EQ(装配层,仅证 glue)**。依据台账
> [`verif/freeze/FM_STATUS.md`](../../verif/freeze/FM_STATUS.md):本层把 `Slice_4` 及
> `RXRSP_4/RXDAT_4` 等子模块黑盒(`FM_INTERFACE_ONLY`),**只证明本层互联布线 + l3Miss 打拍
> glue 等价**,不等于整个 L3 功能等价(须叠加子模块各自证明)。下文 FM 结果为
> **FAILED/部分验证未收敛**(见"验证"节),本层等价性以 UT 为权威。

> 设计源:`openLLC/src/main/scala/openLLC/OpenLLC.scala`(`class OpenLLC`)
> 可读核:`rtl/l2/OpenLLC.sv`(`xs_OpenLLC_core`)+ `rtl/l2/openllc_pkg.sv`
> 11 个子模块实例(8 种类型)全部作 golden 黑盒(UT/FM 两侧共用)。
> 生成器:`scripts/gen_openllc.py`(派生自 `gen_l2top.py`)

OpenLLC 是香山外挂的**独立 L3 缓存 IP**——一个 CHI 协议的 home node(归属节点)。它把若干
LLC slice(cache 流水 + 目录 + 数据 + snoop filter)与一圈 CHI 互联/链路器件(xbar /
linkMonitor / mmioDiverger / mmioMerger)拼起来:
- **北侧(RN,Request Node)**:接 core 集群,经 CHI 收发请求/响应/数据/snoop。
- **南侧(SN,Subordinate Node)**:接内存(NoSnp 端口),把 miss 的访存请求发往内存。

本层**不重写任何功能块的内部逻辑**,只把子模块例化、互联,外加一处顶层 glue(l3Miss 打拍)。

golden `OpenLLC.sv` 全文 4252 行,实测**无 `_T_<n>` / `_GEN_<n>` / `_REG_<编号>` 匿名临时名**
(reg 仅 1 个 `io_l3Miss_REG`,具名),**带运算的引脚 rhs = 0**(1983 个引脚全是 `io_*` 端口 /
`_<inst>_io_*` 互联网 / `clock` / `reset` 直连,无任何拼接/位选/常量/悬空),**带运算的 assign
= 0**(3 条 assign 全是纯连线)。故本层逻辑 = 互联布线 + 1 拍 l3Miss 汇聚寄存。

## 子模块构成(8 种类型 / 11 个实例,全 golden 黑盒)

| 类型 | 实例 | 作用 |
|------|------|------|
| `Slice_4` | `slices_0..3` ×4 | **LLC slice**:cache 流水(RequestArb/MainPipe/Directory/DataStorage/MSHR/snoop filter),banks=4 每 bank 一个(3976 行) |
| `RNXbar` | `rnXbar` ×1 | RN 侧 CHI 交叉开关:各 RN 的 cacheable 请求按地址(bank)路由到对应 slice;回收 slice 的 snpMask |
| `SNXbar` | `snXbar` ×1 | SN 侧 CHI 交叉开关:各 slice 的访存请求汇聚到内存侧 |
| `MMIODiverger` | `mmioDiverger` ×1 | 按地址把每个 RN 的流量分流为 cacheable(进 rnXbar/slice)与 uncacheable(MMIO,绕过缓存) |
| `MMIOMerger` | `mmioMerger` ×1 | 把 cacheable(snXbar 出)与 uncacheable(MMIO)两路合并送 SN |
| `RNLinkMonitor` | `rnLinkMonitor` ×1 | RN 侧 CHI 链路层监视(linkactive 握手 / lcredit 信用流控 / flit 收发);numRNs=1 |
| `SNLinkMonitor` | `snLinkMonitor` ×1 | SN 侧 CHI 链路层监视 |
| `TopDownMonitor_1` | `topDown` ×1 | 性能/调试监视:读各 slice 的 msStatus,产生 `debugTopDown.addrMatch` |

## 连接拓扑(Scala `class OpenLLC`,本层在 SV 里 = 11 个例化 + 引脚互联)

```
io.rn(i) <-> rnLinkMonitor <-> mmioDiverger.in(i)
mmioDiverger.out.cache(i) -> rnXbar.in(i);   rnXbar.out(i) <-> slices(i).in
slices(i).snpMask -> rnXbar.snpMasks(i);      slices(i).out -> snXbar.in(i)
snXbar.out -> mmioMerger.in.cache;   mmioDiverger.out.uncache -> mmioMerger.in.uncache
mmioMerger.out -> snLinkMonitor.in <-> io.sn
topDown 读 slices.msStatus -> io.debugTopDown.addrMatch
```

## 顶层 glue(从 Scala 意图重写,golden 已具名可读)

本层只有一处真正的「顶层逻辑」,落在 `openllc_glue.svh`:

- **l3Miss 汇聚打拍**(`io.l3Miss := RegNext(Cat(slices.map(_.io.l3Miss)).orR)`):4 个 slice 的
  `l3Miss` 按位或后打一拍寄存(具名寄存器 `io_l3Miss_REG`),作为 L3 整体 miss 指示。这是本层
  **唯一的时序 glue**(一个 `always @(posedge clock)`)。

`openllc_outassign.svh` 另有 3 条纯连线 assign:`_probe`(difftest/dontTouch 探针,镜像
topDown.addrMatch)、`io_debugTopDown_addrMatch_0`(topDown 输出直通)、`io_l3Miss`(打拍后输出)。

`nodeID` / `entranceID`(RN/SN 的节点 ID)在此配置下为零宽(numRNs=1),被 firtool 优化掉,
故顶层端口与子模块引脚中均不出现。

## 核结构指标(实测)

| 指标 | 值 |
|------|----|
| 顶层功能端口 | 60(含 clock/reset;31 input / 29 output) |
| 子模块实例 / 类型 | 11 / 8 |
| 子模块输出/互联网声明(decls) | 1180(含 `_probe`) |
| glue:时序行(1 个 always:l3Miss RegNext) | 7(含 1 个具名寄存器) |
| io 输出 + probe assign | 3 |
| 子模块引脚总数 | 1983(全 `io_*`/`_<inst>_io_*`/clock/reset 直连) |
| **套壳闸门**(`_T_<n>`/`_GEN_`/`_REG_<编号>`/`RANDOMIZE`/`io_*_n_m`,去注释) | **0**(全 7 个源文件) |
| 生成器 leaks(decls/glue/inst/outassign) | 0 / 0 / 0 / 0 |
| 生成器 unused(悬空)引脚 | 0 |

## 产物

- 可读核:`rtl/l2/OpenLLC.sv`(`xs_OpenLLC_core`)+ `rtl/l2/openllc_pkg.sv`
- 机械 svh:`openllc_ports.svh` / `openllc_decls.svh` / `openllc_glue.svh` / `openllc_inst.svh` / `openllc_outassign.svh`
- FM/ST:`OpenLLC_wrapper.sv`(golden 同名扁平 wrapper,例化可读核)
- 黑盒 stub:`openllc_blackbox_stubs.sv`(8 类型空体,仅备快速 elaborate)
- UT:`verif/ut/OpenLLC/`(`tb.sv` / `variants_xs.sv` / `Makefile` / `golden_filelist.f`)
- 生成器:`scripts/gen_openllc.py`(派生自 `gen_l2top.py`)

## 验证

**UT(权威):双例化逐拍比对 golden 全部 29 个输出**(`!$isunknown` 门控,`+define+SYNTHESIS`,
`+vcs+initreg+0`,golden 叶子传递闭包 `-f golden_filelist.f` = 70 模块/70 文件)。

| seed | NCYCLES | checks | errors | 结果 |
|------|---------|--------|--------|------|
| 1  | 100000 | 100000 | 0 | TEST PASSED(distinct_diverging_ports=0/29) |
| 7  | 100000 | 100000 | 0 | TEST PASSED(0/29) |
| 42 | 100000 | 100000 | 0 | TEST PASSED(0/29) |

**FM(best-effort,巨型 UT 权威)**:`make fm-OpenLLC` 结果 **FAILED**——**106173 passing /
20 failing / 0 aborted / 176 unverified**。failing=20 恰为 Formality 默认
`verification_failing_point_limit=20`,verify 触限提前中止,另有 176 个 compare point 未验证。
**前 20 个 failing compare point 均在 `slices_N/rxrspUp/io_out_bits_dbID[*]`
内部**(4 slice × 5 bit;rxrspUp 是 Slice_4 内部 LCredit 转换器),**OpenLLC 顶层 glue 与全部
互联端口在前 20 中 0 failing**(都在 106173 passing 里)——「全在 slices 内部」的论证只覆盖
这前 20 个。根因:FM 只给两侧读了 8 个子模块顶,其内部叶子
(Directory_4/DataStorage_4/MainPipe_5/RequestArb_4/…)被自动黑盒,黑盒边界处 `dbID` 的扇入含
undriven 信号无法配对(FM ATTENTION: "20 failing compare points have unmatched undriven signals
in their reference fan-in")。两侧用的是**同一份 golden `Slice_4.sv`**,故实际等价(UT 逐拍证明),
仅 FM 结构分析在部分层次黑盒边界处保守判负。同 L2Top/XSCore 的固有现象——**结论口径:
以 100k×3 UT 为权威;FM 为部分验证、未收敛**。

## -f 闭包 filelist 机制

同 L2Top/XSTile:`gen_openllc.py` 从 `OpenLLC` 顶起做 golden 模块传递闭包(`golden_closure`),
每文件列一次到 `golden_filelist.f`,VCS 用 `-f` 显式编译——**不用 `-y`**,因 golden 叶子多为
自包含 `package`+`module` 文件,`-y` 会重复解析触发 `Package previously declared`。OpenLLC 闭包
= 70 模块/70 文件(比 L2Top 的 214 轻得多,因 OpenLLC 是独立 IP、不含 core 集群与 L2 桥)。
编译 ~4s,单 seed 100k 仿真 ~18s。
