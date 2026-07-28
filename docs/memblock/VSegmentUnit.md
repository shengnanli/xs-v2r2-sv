# VSegmentUnit —— 向量分段访存单元(segment load/store)可读核重写

## 概述
`VSegmentUnit`(golden 2419 行,firtool-1.62.1)是 MemBlock 里处理**向量分段访存**
(vector segment load / store,`vlseg`/`vsseg` 及其 indexed/strided 变体)的状态机单元。
每条向量指令按 `segment × field` 展开,逐个 flow(元素)串行地发 dtlb 请求、dcache 读
(load)或 sbuffer 写(store),支持 fault-only-first(fof)、跨 16 字节非对齐拆分、
CSR trigger 断点比较、异常聚合与 vl 修正。

MemBlock 组 B 装配曾遗漏此 child;本轮补齐可读核重写 + standalone AUX FM 证明。

## 文件
- `rtl/memblock/vsegmentunit_pkg.sv` —— 状态编码 package(S_IDLE..S_FOF,golden 裸 4'hN → 可读名)。
- `rtl/memblock/VSegmentUnit.sv` —— 可读核 `xs_VSegmentUnit_core`(1099 行,`_GEN_/_T_` 密度=0,
  仅注释交叉引用 golden 名)。
- `rtl/memblock/VSegmentUnit_wrapper.sv` —— 扁平端口 FM impl 顶层(例化核 + 2 golden 子模块)。
- `verif/ut/VSegmentUnit/{variants_xs.sv,tb.sv,Makefile}` —— UT 双例化 + AUX FM gate。
- `scripts/gen_vsegment.py` —— 从 golden 端口列表机械派生 wrapper/variants/tb/Makefile。

## 可读核做法
- **状态机**(golden `_GEN_17[state]` 16 路扁平译码):重写为可读 `case(state)`,逐 state 注明
  对应 golden `_GEN_17[N]`。★踩过坑:golden `_GEN_17` 数组是 `{[15]..[0]}` 高→低索引,
  S_LD_FINISH(idx 9)与 S_TLB_REQ(idx 3)的转移逻辑极易看反(本轮先看反导致状态卡死)。
- **8 深 uopq/data/stride 队列**:`generate` 不必,直接用 unpacked 数组 `data[0:7]` + `for` 写逻辑
  (`splitPtr_value==i` / `enqPtr_value==i` 下标匹配),组合 glue 全用 `always_comb`(禁 generate 内
  函数读信号=X 铁律)。
- **数据/掩码排列**(eew=8/16/32/64):`splitData`/`flowData`/`mergedData`/`maskDataVec` 用
  `always_comb` + `for` 或 `case(alignedType)`,忠实复刻 golden 的按元素 mux。
- **index 偏移**(indexed 访存):golden 显式枚举 `issueIndexIdx` 有效范围(veew=0:0..15 等),
  越界给 0。★踩过坑:不能用变量 part-select `strideSel[8*issueIndexIdx +: 8]`——issueIndexIdx
  8 位可超界 → OOB 读 X。改用 `for` + 相等比较 bounded 选择。
- **子模块 glue**:核暴露 `seg_trig_*`(→ VSegmentTrigger)与 `pc_*`(→ PipelineConnect)端口,
  由 wrapper 连线;`io_sbuffer_bits_*` 由 pipe `io_out_*` 直连(不经核)。

## 子模块边界(两侧同 elaborate,非黑盒)
两个子模块都是**纯逻辑小模块**(非厂商 SRAM 宏、非独立签核 target):
- `VSegmentTrigger`(224 行,纯组合 trigger 命中/fire 比较)。
- `NewPipelineConnectPipe_31`(170 行,sbuffer 单级打拍)。
按方法学:逻辑 child 禁黑盒 → **两侧 elaborate**(golden 同时进 `FM_REF_DEPS` 与 `WRAPPER_SRCS`,
UT 双例化两侧共用同一份 golden 定义)。无任何逻辑黑盒、无 vendor 宏。

## 真核 bug(FM 暴露、UT 掩盖)
**非对齐 load `cacheData` 抽取不是简单 `resp >> (latchVaddr[3:0]*8)`。**
golden `_cacheData_T_56`/`_GEN_87..92`/`_pickData_T_8` 是一个**饱和桶形移位**:低 64 位窗口来自
`resp[63:0] >> latchVaddr*8`(latchVaddr≥8 移空),高 64 位来自 `resp[127:64] >> (latchVaddr-8)*8`
(latchVaddr<8 不贡献)。二者 OR。★关键差异:latchVaddr∈{1..7} 时高字节须为 0——若用整体
128 位 `resp >> N` 取低 64 位,高字节会漏进 resp[127:64] 的低位(非 0),与 golden 不符。
起初我用 `shiftData[63:0]` 简化,UT 随机激励 200k 拍全过(可达状态里恰好等价),但 FM 判
`data_0_reg[99:127]` 20 位失配(error candidate = `srl_587` 移位器)。修正为 `cacheData_lo |
cacheData_hi` 双半独立移位后 FM 转绿。教训:桶形移位的边界饱和行为必须逐 latchVaddr 核对,
不能想当然等价于单次移位。

## 验证结果
- **UT**:seed 1/7/42 各 200000 拍,`checks=199997 errors=0`(双例化 golden `VSegmentUnit` vs
  `VSegmentUnit_xs` 逐拍比 163 端口全部输出)。
- **FM(AUX,signoff-strict + vmucp)**:native **Verification SUCCEEDED**,
  **passing 6962(1237 Port + 5725 DFF)/ failing 0 / aborted 0 / unverified 0 /
  unmatched 0(0) / unread 0**;仅 1 个 Constant reg Not-Compared(reset 常数 DFF,无害)。
  `fm_verdict.py` = SUCCEEDED,无 dont_verify、无黑盒、无 relaxed appvar。

### vmucp 白名单(需 main 动作)
strict baseline 为 PARTIAL(native SUCCEEDED 但 22 对称 matched-unread → `strict_unread!=0`)。
22 个 unread 全是**对称 matched-unread**(golden↔impl 同名同宽 cone-dead 寄存器,如
`instMicroOp_exceptionGpaddr[63:50]` 只被 `io_exceptionInfo_bits_gpaddr[49:0]` 读的高 14 位等)。
设 `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`(vmucp)让 FM **实际比较**这些点:全部
verified passing(6940→6962),证明真等价(非 waiver、非 not-compared)。

main 须在两处白名单加入 `VSegmentUnit`(与 VSMergeBufferImp/SnoopUnit 等既有 vmucp target 同):
1. `scripts/fm_eq.tcl` 的 `$top ni {...}` matched-unread 白名单集(末尾追加 `VSegmentUnit`)。
2. `scripts/run_signoff_target.sh` 的对应 case 白名单。

证据:`/tmp/vsegment-evidence/VSegmentUnit/`(fm_vmucp_SUCCEEDED.log + baseline PARTIAL +
sim{1,7,42}.log + fm_eq.tcl.WHITELIST_PATCHED 即待提 main 的 1 行 diff)。
