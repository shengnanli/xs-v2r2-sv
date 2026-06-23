# 发射队列 FaluFmacFdiv 变体(EntriesFaluFmacFdiv)可读重写

设计源:`src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,OthersEntry,IssueQueue}.scala`
golden 对照:`golden/chisel-rtl/EntriesFaluFmacFdiv.sv`(叶子 `EnqEntry_10` / `OthersEntry_104`(simp) / `OthersEntry_106`(comp) / `EnqPolicy_8` / `UIntCompressor_27_000000000000001010100000000`)

## 1. 这是什么

发射队列(IssueQueue)是乱序后端的「调度心脏」:在条目阵列里缓存等待发射的 uop,
监听写回(WB)/发射(IQ)两类唤醒总线把就绪的源置位;当一条 uop 全部源就绪且未发射
时「可发射」,再由年龄检测器(AgeDetector)选出最老者发射。

本变体 **FaluFmacFdiv = 浮点 IQ**,功能单元含 FALU(浮点加减/比较)、FMAC(浮点乘加)、
**FDIV/FSQRT(浮点除/开方)**。它是 FaluFmac 的「近邻」:多了一个 Fdiv 功能单元,因而
**多出一个发射端口(numDeq=2)**——Fdiv 多周期,与 Falu/Fmac 不抢同一条发射通路。

## 2. 与 FaluFmac 样板的差异(本次只改四处)

唤醒匹配、exuSources 压缩、dataSources、canIssue、enqDelay、转移策略(EnqPolicy /
finalSimp/CompTransSel / simp→comp 提级)与 FaluFmac **逐字相同**(直接 fork)。
真正重写只发生在以下四处:

| 维度 | FaluFmac(样板) | FaluFmacFdiv(本变体) |
|---|---|---|
| numEntries / Enq / Simp / Comp | 18 / 2 / 2 / 14 | 18 / 2 / 2 / 14(同) |
| numDeq(发射端口) | 1 | **2**(Falu/Fmac 口 + Fdiv 口) |
| numRegSrc / WakeupFromIQ / WB | 3 / 3 / 6 | 3 / 3 / 6(同) |
| 唤醒匹配 | fpWen + srcType[1] | fpWen + srcType[1](同) |
| FuType 保留位 | {11,12} | **{11,12,14}**(加 Fdiv 位 FU_FDIV=14) |
| status 字段 | (无 deqPortIdx) | **+ deqPortIdx(1 bit)** |
| issueResp resp 来源 | timer1 硬编码 SUCCESS | **端口 0 硬编码 / 端口 1 取 og1Resp_1_bits_resp(动态)** |

### 2.1 numDeq = 2(双发射端口)

golden 端口由单口变成成对:`deqSelOH_{0,1}` / `og0Resp_{0,1}` / `og1Resp_{0,1}` /
`enq|simp|compEntryOldestSel_{0,1}` / `deqEntry_{0,1}`。

- **deqSel[e]**:任一端口选中本条目即发射:
  `deqSel[e] = (deqSelOH_0.valid & deqSelOH_0.bits[e]) | (deqSelOH_1.valid & deqSelOH_1.bits[e])`。
- **deqEntry_{0,1}**:各自用 `oldestSel_{0,1}` 做三级 oldest-mux(comp > simp > enq)。
  (golden 把 deqEntry_1 的部分 payload 端口裁掉——端口 1 / Fdiv 的下游消费字段更少;
   但内部条目仍携带全字段,只是输出端口集不同,wrapper 据 golden 端口逐一引出。)

### 2.2 status.deqPortIdx(1 bit)+ 按端口选 issueResp

这是本变体的核心新机制。每条目记一个 **deqPortIdx**:它将在哪个发射端口出队。

写入(对齐 golden `entryUpdate_status_deqPortIdx`):

```
deqPortIdxWrite[e] = deqSelOH_1.valid & deqSelOH_1.bits[e];     // 被端口 1 选中
entryUpdate.deqPortIdx = deqSel ? deqPortIdxWrite : (issued & deqPortIdx);
```

- 被端口 1 选中 → deqPortIdx=1;被端口 0 选中 → 0;空闲(未 issued)清 0。
- EnqEntry:与 issued 一样,在 enqDelay 窗口被强清 0(入队拍 `enq_load.deqPortIdx=0`)。
- OthersEntry:入队拍取自 `enq.bits.status.deqPortIdx`(随 transEntry 透传)。

读回的 deqPortIdx 用来为该条目选择**对应端口**的发射响应(golden `_GEN/_14/_15/_16`):

```
timer0:  valid = port1 ? og0Resp_1.valid : og0Resp_0.valid;   resp = BLOCK
timer1:  valid = port1 ? og1Resp_1.valid : og1Resp_0.valid;
         resp  = port1 ? og1Resp_1.bits.resp : SUCCESS         // ★ 关键差异 ★
timer2/3: valid=0, resp=BLOCK
```

即:**端口 0(Falu/Fmac)的 resp 硬编码——timer1 即 SUCCESS**(同 FaluFmac);
**端口 1(Fdiv)的 resp 取自 `og1Resp_1_bits_resp`**——因为 Fdiv 多周期,可能返回
BLOCK / UNCERTAIN / SUCCESS,须把这条已发射 uop 退回(BLOCK)或保留(UNCERTAIN)。

### 2.3 fuType 多保留 Fdiv 位

enq / entry_update / fuType 输出三处都加 `fuType[FU_FDIV(=14)]` 一位。FuType 总位宽
仍 35。`IQFuType.readFuType` 只保留 {11,12,14},其余清零。

## 3. 实现结构

| 文件 | 角色 |
|---|---|
| `rtl/backend/iq_ffmacfdiv_pkg.sv` | 维度参数 + struct/enum(status 加 deq_port_idx;FU_FDIV) |
| `rtl/backend/IqEntryFfmacFdiv.sv` | 单条目核(EnqEntry/OthersEntry simp/comp 三态由参数选);唤醒-选择-发射-deqPortIdx |
| `rtl/backend/EntriesFaluFmacFdiv.sv` | 条目阵列(18 条)+ 转移策略 + 双端口 issueResp/oldest-mux |
| `rtl/backend/EntriesFaluFmacFdiv_wrapper.sv` | golden 同名扁平 wrapper(gen 脚本产,纯 glue,无逻辑) |
| `scripts/gen_iq_ffmacfdiv.py` | 端口解析 → wrapper + 双例化 tb + _xs 变体 |

单条目核三态(对应 golden 三个 leaf):
- **IS_ENQ=1**:入队条目(EnqEntry_10),带 1 拍 enqDelay 唤醒。
- **IS_ENQ=0,IS_COMP=0**:简单条目(OthersEntry_104),无 canIssueBypass。
- **IS_ENQ=0,IS_COMP=1**:复杂条目(OthersEntry_106),有 canIssueBypass + 即时前递输出。

EnqPolicy_8 / UIntCompressor 作 golden 黑盒例化(拓扑与配置绑定,与 FaluFmac 同款)。

## 4. 验证

### UT(双例化逐拍比对全部 166 个输出端口)

`verif/ut/IssueQueueFaluFmacFdiv/`:`u_g`=golden `EntriesFaluFmacFdiv`,
`u_i`=可读核 wrapper(重命名 `_xs`)。两侧共享 golden 黑盒 + golden 单条目。
入队 srcType 偏置 isFp 以保证唤醒命中覆盖;`+vcs+initreg+0` 消 golden 上电 X 假象。

| seed | checks | errors |
|---|---|---|
| 1  | 200000 | **0** |
| 7  | 200000 | **0** |
| 42 | 200000 | **0** |

### FM(Formality 形式等价)

`make fm`:golden `EntriesFaluFmacFdiv` vs 可读核 wrapper(黑盒+golden leaf 两侧共享)。

```
FM_RESULT: Verification SUCCEEDED for EntriesFaluFmacFdiv
2958 Passing compare points (1173 Port + 1785 DFF), 0 Failing, 0 Unmatched
```

1785 个 DFF 比较点全部 equivalent——证明每条目状态寄存器(含新增 deqPortIdx)逐位等价,
非黑盒糊弄。

## 5. 硬性闸门(实测)

- 核 `iq_ffmacfdiv_pkg`:8 struct + 3 enum;`IqEntryFfmacFdiv`:3 function + 1 genvar;
  `EntriesFaluFmacFdiv`:1 genvar。
- 代码区(去注释)`grep -E "io_[a-z_]+_[0-9]+_[0-9]+|_REG_[0-9]|_GEN_|_T_[0-9]|RANDOMIZE"`
  三个核文件 **全 0**;wrapper(glue)亦 0。无套壳。
- 坑规避:`!ety_valid[i]` 用逻辑非(避免 `~` 在 32 位加法上下文下溢);oldest/Mux1H 用
  `sel ? entry : 0` 累加(sel=0 不引 X);issueResp/deqPortIdx 全 always_comb。
