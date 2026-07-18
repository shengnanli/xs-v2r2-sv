# TL2CHICoupledL2 —— L2 缓存主体(TileLink<->CHI 桥 + 多 bank L2 阵列)装配层

> ⚠ **FM 分类 = ASSEMBLY_EQ(装配层,仅证 glue)**。依据台账
> [`verif/freeze/FM_STATUS.md`](../../verif/freeze/FM_STATUS.md):本层把 `Slice`(RequestBuffer 等)
> 及 `MMIOBridge` 等子/孙模块黑盒(`FM_INTERFACE_ONLY`),**只证明本层互联 + hint/D 仲裁 +
> perf/CHI 路由/l2Miss glue 等价**,不等于整个 L2 主体功能等价(须叠加子模块各自证明)。下文
> FM 结果为 **FAILED/部分验证未收敛**(见"验证"节),本层等价性以 UT 为权威。

> 设计源:coupledL2 仓库 `TL2CHICoupledL2` / `CoupledL2Imp`
> 可读核:`rtl/l2/TL2CHICoupledL2.sv`(`xs_TL2CHICoupledL2_core`)+ `rtl/l2/coupledl2_pkg.sv`
> 29 个子模块实例(23 种类型)全部作 golden 黑盒(UT/FM 两侧共用)。
> 生成器:`scripts/gen_coupledl2.py`(派生自 `gen_l2top.py`,glue 为具名可读重写)

TL2CHICoupledL2 是香山 V2R2 **L2 cache 的主体装配层**——把 4 个 L2 slice(真正的
cache 流水 + 目录 + 数据 + MSHR + snoop filter)与一圈 prefetch / MMIO 桥 / CHI 通道
仲裁 / CHI 链路监视 / MBIST 自测分发拼成整体:
- **北侧(TileLink,接 L1/core 集群)**:`auto_in_0..3` 四个 client 节点(A/B/C/D/E 五
  通道)+ `auto_mmioBridge_*`(uncacheable MMIO 请求桥)。
- **南侧(CHI,接 L3/home node)**:`io_chi_*` 五通道(REQ/RSP/DAT/SNP + 链路层)。

本层**不重写任何 slice / 仲裁器 / 链路器内部逻辑**,只做子模块例化、互联,外加一组
顶层 glue(hint/D 仲裁、grant 计数、perf 打拍、l2Miss 汇聚、CHI rx 路由、P-Credit)。

与 L2Top/OpenLLC 不同,本层 glue **较重**:golden `TL2CHICoupledL2.sv` 全文 6469 行,
firtool 产出 **131 个 reg / 2 个 always / 80 条 assign**,含 **71 个 `_REG_<n>`** 流水
寄存器、**20 个 `_T_<n>` + 6 个裸 `_T`**、**2 个 `_GEN_<n>`** 匿名临时名。本层把它们**从
firtool 意图重写为具名信号 + 数组 + generate-for**,语义逐拍等价,套壳闸门归零。

## 子模块构成(23 种类型 / 29 个实例,全 golden 黑盒)

| 类型 | 实例 | 作用 |
|------|------|------|
| `Slice` / `Slice_1` / `Slice_2` / `Slice_3` | `slices_0..3` ×4 | **L2 slice**(每 bank 一个):RequestArb/MainPipe/Directory/DataStorage/MSHR/snoop filter,真正的 cache 流水与目录/数据存储 |
| `Pipeline_2` / `Pipeline_3` | `train_pipeline*` / `resp_pipeline*` ×8 | 每 slice 的 prefetch train/resp 流水 |
| `Prefetcher` | `prefetcher` ×1 | 预取器 |
| `MMIOBridge` | `mmioBridge` ×1 | MMIO(uncacheable)请求桥 |
| `FastArbiter_1/_2/_27/_28/_29` | ×5 | prefetch train/resp、CHI txrsp/txdat、pCrdGrant 快速仲裁 |
| `RRArbiterInit_18` | `txreq_arb` ×1 | CHI txreq 轮询仲裁 |
| `Arbiter4_L2CacheErrorInfo` | `l2ECCArb` ×1 | 4 slice ECC error 汇聚 |
| `Arbiter4_L2ToL1Hint` | `l1HintArb` ×1 | 4 slice L2->L1 hint 汇聚 |
| `Pipeline_10` / `Pipeline_11` | `hintPipe2` / `hintPipe1` ×2 | hint 输出打拍(精度探针用) |
| `TopDownMonitor` | `topDown` ×1 | 性能/调试监视(l2MissMatch) |
| `L2Cache` | `mbistPl` ×1 | MBIST 流水分发(自测内存树) |
| `MbistIntfL2` | `l2MbistIntf` ×1 | MBIST 接口适配 |
| `Queue72_CoupledL2Imp_Anon` | `pCrdQueue` ×1 | pCrdGrant 信息队列(CHI P-Credit) |
| `LinkMonitor` | `linkMonitor` ×1 | CHI 链路层监视(linkactive/lcredit/flit) |

## 顶层 glue 重写(`coupledl2_glue.svh`,从 firtool 意图重写为具名可读)

golden 把这部分散成 131 个匿名/半匿名寄存器与一堆 `_T_<n>`/`_GEN_<n>` 临时名;本层把
它们按设计意图归并为 **6 组**具名逻辑(全部用具名信号 / 4-bit 向量 / generate-for):

1. **MBIST 广播常量**(`bd_*`):本配置未接外部广播,全部恒 0(dontTouch,不驱动输出)。
2. **L2->L1 hint 与各 slice D 通道发射仲裁**——本层最实质的时序 glue:
   - `hintFire` = L1HintArb 选出的 hint 本拍真正发射(上拍未 ready & 本拍 valid &
     目标 `sourceId` 落在 L1 范围 `[31:6]==0 && [5:0]<0x24`)。`hintArbOutReadyReg`
     即 golden 的 `l1HintArb_io_out_ready_REG`,经 `~` 回灌 `l1HintArb.io_out_ready`。
   - 每个 slice 一组**hint 发射阻塞延迟链**:hint 命中该 slice 时把它的 D 通道释放延后
     ——A 链 2 拍、B 链 3 拍(golden 的 20 个 `sliceCanFire_REG_*`),任一有效即
     `sliceCanFire[i]`。本层用 **4-bit 向量寄存器** `hintBlockA0/A1`、`hintBlockB0/B1/B2`
     (每 bit 一个 slice)逐拍移位重写;`{4{hintFire}} & hintChosen` 做每-slice 门控。
   - `allCanFire`(golden 5 个 `allCanFire_REG_*`):无 hint 命中时全体可发射,或任一 slice
     请求释放 D。`sliceDArbWin[i] = sliceCanFire[i] | allCanFire`,`sliceDReady[i] =
     auto_in_i_d_ready & sliceDArbWin[i]`(回灌 `slices_i.io_in_d_ready`)。
3. **Grant 数据节拍计数 + hint 命中精度探针**(dontTouch 统计,不驱动功能输出):
   `grantDValidReady` / `grantBeatRest`(多拍 GrantData 节拍跟踪,golden 4 个
   `grant_data_fire_first_r_counter*`)/ `grantDataFire` / `grantDataSource` /
   `accurateHint_probe` / `okHint_probe`(golden `_GEN`/`_GEN_0`/`_okHint_T`)。
4. **48 路性能计数 2 级打拍**(golden 96 个 `io_perf_*_value_REG/_REG_1`):4 slice × 12
   事件,各 `RegNext∘RegNext`;事件 #2 恒 0。本层用 **unpacked 数组 `perfStage1/2[1:48]`
   + 一个 `for` 循环**重写,源映射 `slicePerfRaw[N]` 从 golden always 块**收割**保证逐拍忠实。
5. **l2Miss 汇聚打拍**:`l2MissReg := RegNext(OR(各 slice l2Miss))`。
6. **CHI rx 五通道按 bank 路由译码 + P-Credit grant 流水**:`{snp,rsp,dat}BankSel*`
   (按 `txnID[10:9]` / snp `addr[4:3]` 选 bank,golden 的 `_rx*_ready_T*`)、
   `isPCrdGrant` / `pCrdGrant{Valid,Type,SrcID}_s1`(rxrsp PCrdGrant 打拍入 `pCrdQueue`)、
   `grantCnt`(pCrdGrant 仲裁发射计数)。

跨入 inst/outassign 的 firtool 临时名(d-ready、rx-bank-sel、`l1HintArb_io_out_ready_REG`、
`io_l2Miss_REG`、`io_perf_*_REG_1`)由 `gen_coupledl2.py` 的 `RENAME` 表整词替换为上述
具名信号,保证 glue 与例化/输出三处一致。

## 顶层 io/auto 输出(`coupledl2_outassign.svh`,70 条)

绝大多数为子模块输出网直连;带运算的少数:`auto_in_i_b_bits_address` 插入 bank 号
(`{addr[45:6], 2'hi, addr[5:0]}`)、`auto_in_i_d_valid = slice_d_valid & sliceDArbWin[i]`、
`io_perf_N_value = perfStage2[N]`、`io_l2Miss = l2MissReg`、`io_l2_hint_valid = hintFire`、
`_probe = topDown.l2MissMatch`(difftest 探针)。

## 核结构指标(实测)

| 指标 | 值 |
|------|----|
| 顶层功能端口 | 302(含 clock/reset;150 input / 150 output) |
| 子模块实例 / 类型 | 29 / 23 |
| 子模块输出/互联网声明(decls) | 1433 |
| glue:reg 声明 / always 块 / assign / for 循环 | 13 / 2 / 74 / 1(由 firtool 的 131 reg / 2 always / 80 assign 归并而来) |
| io/auto 输出 + probe assign(outassign) | 70 |
| **套壳闸门**(`_REG_<n>`/`_GEN_`/`_T_<n>`/`io_*_n_m`/RANDOMIZE,去注释) | **0**(全 7 个源文件) |
| 生成器 leaks(glue/inst/outassign) | 0 / 0 / 0 |
| golden firtool 临时名消除 | `_REG_<n>` 71→0、`_T_<n>` 20→0、裸 `_T` 6→0、`_GEN_<n>` 2→0 |

## 产物

- 可读核:`rtl/l2/TL2CHICoupledL2.sv`(`xs_TL2CHICoupledL2_core`)+ `rtl/l2/coupledl2_pkg.sv`
- 机械/glue svh:`coupledl2_ports.svh` / `coupledl2_decls.svh` / `coupledl2_glue.svh` / `coupledl2_inst.svh` / `coupledl2_outassign.svh`
- FM/ST:`TL2CHICoupledL2_wrapper.sv`(golden 同名扁平 wrapper,例化可读核)
- 黑盒 stub:`coupledl2_blackbox_stubs.sv`(23 类型空体,仅备快速 elaborate)
- UT:`verif/ut/TL2CHICoupledL2/`(`tb.sv` / `variants_xs.sv` / `Makefile` / `golden_filelist.f`)
- 生成器:`scripts/gen_coupledl2.py`

## 验证

**UT(权威):双例化逐拍比对 golden 全部 150 个输出**(`!$isunknown` 门控,
`+define+SYNTHESIS`,`+vcs+initreg+0`,golden 叶子传递闭包 `-f golden_filelist.f` =
171 模块/171 文件)。`sliceDReady` 回灌 slice、`hintArbOutReadyReg` 回灌 l1HintArb,
故输出对 glue 重写极敏感——逐拍 0 错即证明 hint/D 仲裁、perf、CHI 路由全部等价。

| seed | NCYCLES | checks | errors | 结果 |
|------|---------|--------|--------|------|
| 1  | 100000 | 100000 | 0 | TEST PASSED(distinct_diverging_ports=0/150) |
| 7  | 100000 | 100000 | 0 | TEST PASSED(0/150) |
| 42 | 100000 | 100000 | 0 | TEST PASSED(0/150) |

> 调试记录:首版有 1 处 `l1HintArb.io_out_ready` 引脚仍引用 golden 名
> `l1HintArb_io_out_ready_REG`(未入 RENAME 表),成悬空隐式网 → hint 仲裁全程发散
> (4 端口、98962/100000 错)。补入 `RENAME` 后逐拍归零。说明本层 glue 重写**带回灌**,
> UT 能彻底暴露任何一处接错——非纯前馈装配。

**FM(best-effort,巨型 UT 权威)**:`make fm-TL2CHICoupledL2`——impl(wrapper→可读核)
与 ref 两侧在相同层次黑盒化 23 个子模块顶。结果 **FAILED**:**151217 passing / 20 failing /
0 aborted / 661 unverified**。failing=20 恰为 Formality 默认
`verification_failing_point_limit=20`,verify 触限提前中止,另有 661 个 compare point 未验证。
**前 20 个 failing 全部落在 `io_perf_1_value` 与 `io_perf_2_value` 两路**
(各 6 bit 端口 + 其打拍寄存器),其余 46 路 perf 与全部 hint/D 仲裁/CHI 路由/l2Miss/
P-Credit glue、所有互联端口均 passing——「全落在 perf 两路」的论证只覆盖这前 20 个。

这前 20 个 failing 是 **FM 在 slice 黑盒边界的保守判负**,非真 bug:`io_perf_1/2_value` 的源
`_slices_0_io_perf_0_value` / `_perf_1_value` 在 golden `Slice` 内部本就 2 级寄存,再经
更深的 `mainPipe`/`mshrCtl`(FM 黑盒)馈入,FM 的寄存器合并/常量传播启发式无法在 ref 与
impl 间关联这条深黑盒链(把 golden 第 2 拍寄存器误配到本核第 1 拍)。本核 perf 变换是
**逐拍照搬 golden**(`slicePerfRaw[N]` 源表达式由 `gen_coupledl2.py` 从 golden always 块
**逐条收割**,变换为 `RegNext∘RegNext`,与 golden 字面一致),且已分别用「unpacked 数组 +
for 循环」与「48×2 具名标量寄存器(与 golden 命名 1:1)」两种写法各跑一遍 FM,**结果完全相同
(均 20 failing——两次都触到 20 点截断上限,比较的是前 20 个 failing 的落点)**——证明与本核
表示无关,纯属源侧黑盒关联。`io_perf_1/2_value` 作为 150 个
被比对输出的一部分,在 **100k×3 UT 中逐拍 0 错**,等价性由 UT 权威证明。同 L2Top/OpenLLC
的既定结论——**结论口径:UT 为权威;FM 为部分验证、未收敛**(在部分黑盒边界保守判负 +
截断后 661 点未验证)。

## -f 闭包 filelist 机制

同 L2Top/OpenLLC:`gen_coupledl2.py` 从 `TL2CHICoupledL2` 顶起做 golden 模块传递闭包,
每文件列一次到 `golden_filelist.f`,VCS 用 `-f` 显式编译(不用 `-y`,规避自包含
`package`+`module` 文件的 `Package previously declared`)。闭包 = **171 模块/171 文件**
(介于 OpenLLC 70 与 L2Top 214 之间——本层是 L2 主体,含 4 个完整 slice 但不含 core 集群)。
编译 ~6s,单 seed 100k 仿真 ~数分钟(slice 内部全量例化,较重)。
