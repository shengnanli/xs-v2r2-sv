# L2Top —— L2 顶层装配(CoupledL2 主体 + TileLink 互联壳)

> 设计源:`src/main/scala/xiangshan/L2Top.scala`(`class L2TopImp`)
> 可读核:`rtl/l2/L2Top.sv`(`xs_L2Top_core`)+ `rtl/l2/l2top_pkg.sv`
> 19 个子模块实例(15 种类型)全部作 golden 黑盒(UT/FM 两侧共用)。
> 生成器:`scripts/gen_l2top.py`

L2Top 是 L2 cache 子系统的顶层装配壳:把 CoupledL2 主体(`TL2CHICoupledL2`,L2 阵列 +
TileLink↔CHI 桥)与一圈 TileLink 互联器件(xbar / buffer / logger)、BEU(总线错误单元)、
BusPerfMonitor 拼起来,并把 L2 边界(core 侧 TL client 节点 / CHI 总线 / 中断 / PTW
(`l2_tlb_req`)/ trace / hartId / reset_vector / l2_hint)拉直对外。它本身**不重写任何
功能块的内部逻辑**,只把子模块例化、互联,外加一小撮顶层 glue。

golden `L2Top.sv` 全文 3620 行,实测**无 `_T_<n>` / `_GEN_<n>` / `_REG_<编号>` 匿名临时名**
(只有后缀 `_REG` / `_r` 的**具名** trace 寄存器),**带运算的引脚 rhs = 0**,**带运算的
assign 仅 1 处**(`io_l2_hint_bits_sourceId` 取低 4 位)。故本层逻辑 = 互联布线 + trace 打拍 +
中断/控制量直通转发。

## 子模块构成(15 种类型 / 19 个实例,全 golden 黑盒)

| 类型 | 实例 | 作用 |
|------|------|------|
| `TL2CHICoupledL2` | `inner_l2cache` ×1 | **L2 cache 主体**:L2 阵列(目录/数据/MSHR/预取)+ TileLink↔CHI 桥(6469 行) |
| `TLXbar_5` / `TLXbar_6` | `inner_xbar` / `inner_xbar_1` | TileLink 交叉开关:core 多 master 汇聚到 L2 入口 |
| `TLBuffer_13` | `inner_buffer` | TileLink 寄存缓冲(主路打拍) |
| `TLBuffer_6` | `inner_ptw_to_l2_buffer` | PTW→L2 通道缓冲 |
| `TLBuffer_15` ×3 | `inner_i_mmio_buffer` / `inner_buffers` / `inner_buffers_1` | icache/MMIO 等通道缓冲 |
| `TLBuffer_8` ×2 | `inner_buffers_2` / `inner_buffers_3` | client 通道缓冲(另一打拍配置) |
| `TLBuffer_20` ×2 | `inner_buffers_4` / `inner_buffers_5` | client 通道缓冲 |
| `TLBuffer_22` | `inner_buffer_1` | mem 侧出口缓冲 |
| `TLLogger` / `_1` / `_2` | `inner_logger*` ×3 | TileLink 事务日志(difftest/perf,综合时纯透传) |
| `BusErrorUnit` | `inner_beu` ×1 | 总线错误单元:汇聚 L2 ECC error 地址,上报本地中断给 PLIC |
| `BusPerfMonitor` | `inner_busPMU` ×1 | 总线性能监视(非综合统计) |
| `DelayN_334` | `inner_resetDelayN` ×1 | `reset_vector` 延迟链:fromTile → 延迟 N 拍 → toCore |

## 顶层 glue(从 Scala 意图重写,golden 已具名可读)

本层共五类顶层逻辑,落在 `l2top_glue.svh`(A/B/D)与 `l2top_outassign.svh`(C/E):

- **(A) 输入 fanin 改名** —— 19 条 `wire inner_io_X = io_X;`,纯连线改名(CHI rx/tx 输入、
  hartId、cpu_halt/critical_error 进入内部网)。
- **(B) 组合直通改名** —— 3 条 `wire inner_io_X_to = inner_io_X_from;`:`hartId` / `cpu_halt` /
  `cpu_critical_error` 从 fromTile/fromCore 直通到 toCore/toTile,纯连线。
- **(C) 中断端口直通** —— 7 条 `assign auto_inner_*_int_out = auto_inner_*_int_in;`:
  nmi/plic/debug/clint 中断 in→out 直穿(L2Top 仅作 diplomacy 中转,中断本身不在此层产生)。
- **(D) trace 打拍 + hartIsInReset** —— **本层唯一的时序 glue**(两个 `always`):
  - **trace 流水级**:core 来的 `traceCoreInterface`(toEncoder 的 groups/trap/priv)打一拍寄存
    再送 toTile;部分字段受 `groups_*_valid` / `itype`(异常 itype∈{1,2})门控;`fromEncoder` 的
    `enable`/`stall` 也打一拍回灌 fromCore。golden 命名极可读(`inner_io_traceCoreInterface_*_REG`
    / `_r`),原样保留。
  - **hartIsInReset**:`resetInFrontend | reset` 经**异步置位**寄存器(`always @(posedge clock or
    posedge reset)`)输出 `hartIsInReset_toTile`。
- **(E) 顶层 io 输出 assign** —— 50 条(含 C 的 7 条中断直通)。绝大多数子模块输出网 /
  `inner_io_*` 直连 io;**唯一带运算**:`io_l2_hint_bits_sourceId = _inner_l2cache_io_l2_hint_bits_sourceId[3:0]`(取低 4 位)。
  另 `io_errors_l2_ecc_error_bits = {2'h0, _inner_l2cache_io_error_address}`(零扩展)作为
  `inner_beu` 的输入引脚出现在 `l2top_inst.svh`。

## 核结构指标(实测)

| 指标 | 值 |
|------|----|
| 顶层功能端口 | 351(含 clock/reset) |
| 子模块实例 / 类型 | 19 / 15 |
| 子模块输出/互联网声明(decls) | 807 |
| glue:wire 改名/直通 | 22 |
| glue:时序行(2 个 always:trace + hartIsInReset) | 70(含 18 个具名寄存器) |
| io 输出 + 中断直通 assign | 50 |
| **套壳闸门**(`_T_<n>`/`_GEN_`/`_REG_<编号>`/`RANDOMIZE`/`io_*_n_m`,去注释) | **0**(全 7 个源文件) |
| 生成器 leaks(decls/glue/inst/outassign) | 0 / 0 / 0 / 0 |

## 产物

- 可读核:`rtl/l2/L2Top.sv`(`xs_L2Top_core`)+ `rtl/l2/l2top_pkg.sv`
- 机械 svh:`l2top_ports.svh` / `l2top_decls.svh` / `l2top_glue.svh` / `l2top_inst.svh` / `l2top_outassign.svh`
- FM/ST:`L2Top_wrapper.sv`(golden 同名扁平 wrapper,例化可读核)
- 黑盒 stub:`l2top_blackbox_stubs.sv`(15 类型空体,仅备快速 elaborate)
- UT:`verif/ut/L2Top/`(`tb.sv` / `variants_xs.sv` / `Makefile` / `golden_filelist.f`)
- 生成器:`scripts/gen_l2top.py`(派生自 `gen_xstile.py`,新增 glue 段提取)

## 验证

**UT(权威):双例化逐拍比对 golden 全部 182 个输出**(`!$isunknown` 门控,`+define+SYNTHESIS`,
`+vcs+initreg+0`,golden 叶子传递闭包 `-f golden_filelist.f` = 214 模块/214 文件)。

| seed | NCYCLES | checks | errors | 结果 |
|------|---------|--------|--------|------|
| 1  | 120000 | 120000 | 0 | TEST PASSED(distinct_diverging_ports=0/182) |
| 7  | 120000 | 120000 | 0 | TEST PASSED(0/182) |
| 42 | 120000 | 120000 | 0 | TEST PASSED(0/182) |

**FM(best-effort,巨型 UT 权威)**:`make fm-L2Top` 未 SUCCEEDED。**全部 20 个 failing
compare point 均在 `inner_l2cache/`(TL2CHICoupledL2)内部**(perf 寄存器、slices 的
error_bits_address、txreq_arb 等),**L2Top 顶层 glue 0 failing**。根因同 XSCore:FM 把
6469 行的 `TL2CHICoupledL2` 完整读入两侧(而非黑盒),其内部 undriven 输入的扇入无法配对
(FM ATTENTION: "19 failing compare points have unmatched undriven signals in their reference
fan-in")。这是巨型子模块做互联壳 FM 的固有现象,与本层 glue 等价性无关——以 120k×3 UT
为权威等价证明。

## -f 闭包 filelist 机制

同 XSCore/XSTile:`gen_l2top.py` 从 `L2Top` 顶起做 golden 模块传递闭包(`golden_closure`),
每文件列一次到 `golden_filelist.f`,VCS 用 `-f` 显式编译——**不用 `-y`**,因 golden 叶子多为
自包含 `package`+`module` 文件,`-y` 会重复解析触发 `Package previously declared`。L2Top 闭包
= 214 模块/214 文件(比 XSTile 的 1623 轻,因不含 XSCore)。
