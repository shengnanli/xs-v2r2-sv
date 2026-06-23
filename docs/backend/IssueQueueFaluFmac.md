# 发射队列 FaluFmac 变体(EntriesFaluFmac)可读重写

设计源:`src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,OthersEntry,IssueQueue}.scala`
golden 对照:`golden/chisel-rtl/EntriesFaluFmac.sv`(叶子 `EnqEntry_12` / `OthersEntry_120`(simp) / `OthersEntry_122`(comp) / `EnqPolicy_8` / `UIntCompressor_27_000000000000001010100000000`)

## 1. 这是什么

发射队列(IssueQueue)是乱序后端的「调度心脏」:在条目阵列里缓存等待发射的 uop,
监听写回(WB)/发射(IQ)两类唤醒总线,把就绪的源置位;当一条 uop 全部源就绪且未发射
时「可发射」,再由年龄检测器(AgeDetector)选出最老者发射。

本变体 **FaluFmac = 浮点 IQ**,功能单元含 FALU(浮点加减/比较)与 FMAC(浮点乘加)。

## 2. 与样板 AluCsrFenceDiv 的差异(为何选它做下一个)

它是 golden 全部 IQ 变体里**结构与样板最接近、增量最小**的一个:沿用完全相同的
enq/simp/comp 三类条目 + EnqPolicy 转移策略 + 三级 oldest-mux 骨架,但**去掉了样板
里最难的所有 load 相关机制**,因此是验证「核可复用 + 换参数 + 换语义」方法学的理想样本。

| 维度 | AluCsrFenceDiv(样板) | FaluFmac(本变体) |
|---|---|---|
| numEntries / Enq / Simp / Comp | 24 / 2 / 6 / 16 | **18 / 2 / 2 / 14** |
| numDeq(发射端口) | 2 | **1** |
| numRegSrc(源寄存器) | 2 | **3**(浮点乘加 rs1/rs2/rs3) |
| numWakeupFromIQ / WB | 7 / 4 | **3 / 6** |
| 唤醒匹配 | rfWen + srcType[0](isXp) | **fpWen + srcType[1](isFp)** |
| loadDependency / load-to-cancel | 有(3 深移位 + ld2Cancel) | **无** |
| RegCache(useRegCache/rcIdx) | 有 | **无** |
| imm 立即数字段 | 有 | **无** |
| enqDelay 级数 | 2(In1/In2) | **1(In1)** |
| og0Cancel 命中位 | {0,2,4,6}(源 0..3) | **仅 [8](IQ 源 0)** |
| exuSources.value 宽度 | 3 bit | **2 bit** |

## 3. 核怎么复用 / 改的

- **单条目核** `rtl/backend/IqEntryFfmac.sv`(`xs_iq_entry_ffmac`):由样板核 `IqEntryAcfd`
  派生。结构同构(IS_ENQ/IS_COMP 参数选 enq/simp/comp),但删去了:
  `load_should_cancel` / `src_ld_cancel` / `src_ld_trans_cancel` / `shift_dep` /
  RegCache 唤醒 / `cancel_bypass` / 全部 `ld_dep` 通路 / 双 deq 端口 / enqDelay 第 2 级。
  - 唤醒匹配函数改用 `srcType[1] & fpWen`(`match_wb/match_iq`)。
  - exuSources 压缩器换成 `UIntCompressor_27_000000000000001010100000000`(io_in 布局
    `{14'h0, IQ2, 1'h0, IQ1, 1'h0, IQ0, 8'h0}` → bit{8,10,12}),输出 2 位编码
    `{|c[2:1], c[2]|c[0]}`。
  - og0Cancel 仅作用于 IQ 唤醒源 0(`og0cancel[8] & wk_iq[0].is0lat`),源 1/2 用 raw 命中。
  - dataSources/srcState 更新与 golden 严格对齐:`wakeupByIQ ? bypass(2)`、原 bypass→reg(8);
    `srcState | (|wbHit) | (|wakeupByIQ)`(无 load 取消门控)。
  - comp 即时前递输出用「本拍唤醒(raw)」:`dataSources=forward(1)`、`exuSources=raw 压缩`。
  - EnqEntry 的 enqDelay 窗口 `srcState = enqdValid & (wbHit | iqHit) | reg.srcState`,
    `dataSources = (enqdValid & iqHit) ? bypass : reg`,`exuSources = enqdValid ? 压缩 : reg`。

- **阵列核** `rtl/backend/EntriesFaluFmac.sv`(`xs_EntriesFaluFmac_core`):由样板阵列派生。
  转移策略(enqCanTrans2Comp/Simp、finalSimp/CompTransSel、simp/comp/compEnqVec Mux1H)
  与样板逐字同构(仍踩样板的 `~`→`!` 定宽下溢坑)。删去了:loadDependency 输出、
  enq 延迟 load 流水寄存器、og0/ld delay 管线、双端口 issueResp/deqSel/oldest-mux。
  issueResp 单端口:`resp = '{0,0,SUCCESS,0}[issueTimer]`(仅 timer1=SUCCESS),
  `valid = {timer0→og0Resp.valid, timer1→og1Resp.valid}`(og*Resp.bits 不消费)。

- **类型包** `rtl/backend/iq_ffmac_pkg.sv`:srcStatus 只剩 `{psrc, srcType, srcState,
  dataSources, exuSources}`;payload `{fuOpType, rfWen, fpWen, fpu_{wflags,fmt,rm}, pdest}`;
  EntryBundle 无 imm。

## 4. 验证

- **生成器** `scripts/gen_iq_ffmac.py`:解析 golden `EntriesFaluFmac` 264 个端口,生成
  `EntriesFaluFmac_wrapper.sv`(flat↔struct glue)+ 双例化 tb + `_xs` 变体。264 端口全映射。
- **UT** `verif/ut/IssueQueueFaluFmac/`:`entries_tb.sv` 双例化(u_g=golden Entries,
  u_i=可读核 wrapper),逐拍比对全部 150 个输出。入队源类型偏置 isFp 以覆盖唤醒路径。
  - **seed 1 / 7 / 42 × 带 flush:200000 拍 errors=0 TEST PASSED**(一次收敛,无真值发散)。
- **FM** `make fm`:**FM_RESULT: Verification SUCCEEDED for EntriesFaluFmac**。
  2861 个 passing compare points(1112 端口 + 1749 DFF),0 failing,0 unmatched。

## 5. 硬性闸门

- `grep -E "io_[a-z_]+_[0-9]+_[0-9]+|_REG_[0-9]|_GEN_|_T_[0-9]|RANDOMIZE"`:核 0、pkg 0、
  阵列 1(唯一一处是注释里引用 golden 信号名 `_GEN_14`,非生成代码);wrapper 的 `_GEN_/_T_` = 0。
- 核 struct 8 / enum 3 / function 3 / genvar 1;阵列 genvar 2。无套壳。中文注释齐全。
