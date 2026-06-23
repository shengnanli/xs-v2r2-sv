# IssueQueueLdu —— load 地址发射队列(Ldu 变体)可读 SV 重写

## 1. 这是什么

香山 V2R2(昆明湖)乱序后端「调度心脏」之一:**load 地址**发射队列。本变体
**Ldu = Load-Address**(LDU, FuType bit15)。它把等待的 load 地址 uop 缓存在条目阵列
里,唤醒就绪后按年龄最老仲裁发射到单条 LDU 流水。

设计源:`src/main/scala/xiangshan/backend/issue/IssueQueue.scala`,其中访存 IQ 的派生类
是 **`class IssueQueueMemAddrImp`(IssueQueue.scala:1094)**,本变体走其 `isLdAddrIQ` 分支。

Ldu 是访存类发射队列里 **IO 最多(223 端口)** 的变体,与访存样板 `IssueQueueStaMou`
(store 地址,见 `IssueQueueStaMou.md`)同骨架(条目阵列 + 唤醒-选择 + 年龄最老仲裁 +
一拍 deqDelay + 在队统计),但增量比 StaMou 大。发射队列通用机理在样板文档已详述,本文
只讲 **Ldu 相对 StaMou 的 load 增量**。

```
numEntries=16 / numEnq=2 / numSimp=2 / numComp=12 / numDeq=1 / numRegSrc=1
numWakeupFromIQ=7 / numWakeupFromWB=4 / LoadPipelineWidth=3 / LoadDependencyWidth=2
imm 全宽 32 位 / lqIdx 7 位 / sqIdx 6 位 / pdestCopy・rfWenCopy 各 6 路
```

## 2. 文件清单

| 文件 | 角色 |
|------|------|
| `rtl/backend/iq_ldu_pkg.sv` | 类型/参数包(struct/enum/维度,含 load 反馈/唤醒 bundle) |
| `rtl/backend/IssueQueueLdu.sv` | IQ 顶层核 `xs_IssueQueueLdu_core` + golden 同名穿透 wrapper |
| `rtl/backend/issuequeue_ldu_{ports,connect}.svh` | IQ 顶层端口/连线(gen 生成) |
| `scripts/gen_iq_ldu.py` | svh/tb/variant 生成器(fork 自 gen_iq_stamou.py) |
| `verif/ut/IssueQueueLdu/{iq_tb.sv,iq_variant_xs.sv,Makefile.iq}` | 双例化 UT + FM Makefile |

条目阵列 `EntriesLdu`(及其 16 个单条目 `EnqEntry_24/OthersEntry_200/202`、`EnqPolicy_14`
转移策略、`UIntCompressor` exuSources 编码器)、功能单元忙表 `FuBusyTableWrite_105`/
`FuBusyTableRead_105`、3 个年龄检测器(`NewAgeDetector_6 / AgeDetector_12 / AgeDetector_21`)
均作 **golden 黑盒**直接例化,由可读核连线。重写的是 **IQ 核的 enq/仲裁/deq/统计胶合逻辑
+ load 胶合**。

## 3. 相对 StaMou 样板的增量(逐项,代码里以 `[L1]`..`[L7]` + `[B]` 标注)

enq 折算(srcState/dataSources 初值)、年龄三段仲裁(comp>simp>enq 优先级)、转移策略
(simp→comp)、deqDelay 一拍寄存、`validCntDeqVec` 在队统计、单源/单端口 Mux1H 等骨架
逻辑与 StaMou **逐行同构**。实质 load 差异如下。

### 3.1 [L1] load 唤醒输出(loadWakeUp → wakeupToIQ)(本变体最关键的 load 特征)

执行端 load 单元命中后,通过 `io_memIO_loadWakeUp` 把「load 写回结果就绪」**提前一拍**
广播。IQ 把它寄存一拍后从 `io_wakeupToIQ` 引出,供其它 IQ 提前唤醒等待该 load 结果的 uop。

```
wakeupToIQ.valid  = reg(loadWakeUp.valid)                       // 复位清 0
wakeupToIQ.rfWen  = reg(loadWakeUp.rfWen & loadWakeUp.valid)    // 复位清 0
wakeupToIQ.fpWen  = reg(loadWakeUp.fpWen & loadWakeUp.valid)    // 复位清 0
wakeupToIQ.pdest  = reg(loadWakeUp.pdest)  [仅 valid 时锁存, 无 reset]
wakeupToIQ.rcDest = io_replaceRCIdx_0      [组合直出, RegCache 回填索引]
wakeupToIQ.pdestCopy_0..5 = pdest 扇出 6 份  [物理上给 6 个读端口分别布线]
wakeupToIQ.rfWenCopy_0..5 = rfWen 扇出 6 份
```

关键细节(对照 golden):`pdest/pdestCopy` 寄存器 **仅在 `loadWakeUp.valid` 时更新**
(无 reset 分支,上电 X 由 initreg 归零);而 `valid/rfWen/fpWen/rfWenCopy` 复位清 0、
每拍随 `loadWakeUp` 更新。可读核用两个 `always`(一个 `posedge clock` 仅 valid 锁存
pdest,一个 `posedge clock or posedge reset` 处理带 reset 的 valid/rfWen 族),并用
`for` 循环把 6 路 copy 显式展开,而非 6 行复制。
—— **StaMou(store-addr)不写回寄存器,故无此通路,也无 MultiWakeupQueue。**

### 3.2 [L2] FuBusyTable(功能单元忙表)

load 要过功能单元忙表(避免在功能单元忙窗口内发射)。canIssue 需先与忙表 mask 相与
再与 `fuType[LDU=15]` 相与才进年龄仲裁:

```
canIssueMergeAllBusy = entries.canIssue & ~fuBusyTableMask
deqCanIssue          = canIssueMergeAllBusy & fuType[15]
```

忙表由两个 golden 黑盒实现:`FuBusyTableWrite_105`(由 deq/og0/og1 三路响应写,均带
35 位 fuType)产出 4 位忙表内容,`FuBusyTableRead_105`(各条目 fuType 查表)读出 16 位
mask。可读核负责把 write→read 的 4 位忙表内容对接,并把 deq/og 响应连进写黑盒。
—— **StaMou 不过忙表,canIssue 直接进仲裁。**

### 3.3 [L3] fromLoad 反馈(按 lqIdx 匹配)

load 发射后执行端给 **两路** 反馈:`finalIssueResp`(最终发射响应)/ `memAddrIssueResp`
(访存地址发射响应),各带 LqPtr(LoadQueue 指针,flag+7 位 value)。条目阵列据 lqIdx
匹配把对应 issued 条目打回重发(load replay)或确认。

可读核把这两路 **直通**连进条目阵列 `io_fromLoad_*`(无任何折算)。
—— **对比 StaMou**:StaMou 是 **单路** `feedbackSlow` 按 **sqIdx** 匹配,且 IQ 核要把
1 位 `hit` 折算成 2 位 `resp`(`hit?SUCCESS:BLOCK`);Ldu 这两路 IQ 核「直通」,hit→resp
折算逻辑被搬进了条目阵列内部,IQ 核无折算。

### 3.4 [L4] og0Resp/og1Resp 携带 fuType

写忙表需要 fuType,故 og0/og1 响应多带 35 位 `fuType`(StaMou 的 og 响应只有 valid/resp)。
注意:**fuType 只喂给忙表写黑盒**;条目阵列仍只收 og 的 `valid`/`resp`(与 StaMou 同)。

### 3.5 [L5] load 专属 payload 透传

enq 带入 load 字段 → 条目 payload → deqEntry 读出 → deqDelay 输出:
- `lqIdx`(LqPtr,flag+7 位)、`preDecodeInfo.isRVC`、`ftqPtr.flag`、`fpWen`。

另有 4 个字段 `loadWaitBit/storeSetHit/waitForRobIdx/loadWaitStrict` **不是 enq 输入**,
而是由条目阵列内部从 `imm`/`fuOpType` 派生(store-set 依赖训练用),仅 deqEntry 输出,
IQ 核 **透传** 到 deqDelay。可读核不参与其派生(在黑盒内)。
—— 无 StaMou 的 `isFirstIssue` 输出。

### 3.6 [L6] imm 全宽 32 位

load 的 imm 全宽 32 位透传(`deqDelay.imm = {32'h0, imm}`);**无 immType/selImm 输出**。
—— StaMou 的 imm 截到 12 位、且有 immType/selImm。

### 3.7 [L7] fuType 仅用 LDU 位(bit15)

`deqCanAccept = fuType[15]`;enq 只保留 `fuType[15]`;deqDelay 输出的 35 位 fuType 由这
一位拼回(`{19'h0, fuType15, 15'h0}`),写忙表也用它。
—— StaMou 是 `fuType[16] | fuType[17]`(STA/MOU 双功能单元同端口)。

### 3.8 [B] 单源 / 单发射端口

`numRegSrc=1`(load 地址只需基址 1 个源寄存器)、`numDeq=1`(单 LDU 流水)。故
`dataSources/exuSources/loadDependency` 的 16-way Mux1H 只对「源 0」「端口 0」归约一次
(与 StaMou 同),用 `always_comb` 显式按位与 OR 展开,X 安全。

## 4. X 与位宽纪律(沿用样板)

- 发射 one-hot 选择全部用三元 mux / 按位与归约(`{N{sel}} & data` 后 OR),X 安全。
- 队列空(`~|e_valid`)时 deqDelay 的 bits 寄存器保持(golden 同款门控),valid 仍每拍更新。
- loadWakeUp 的 `pdest/pdestCopy` 寄存器无 reset、仅 valid 时锁存——与 golden 同款;
  上电 X 由 `+vcs+initreg+0` 归零。
- `validCntDeqVec` 减出队消耗用 `cnt - {pad, fire}`,无 `~` 位宽下溢风险;计数用
  `always_comb` 循环(而非读模块级信号的 function),规避 FM 的 function 敏感性告警。

## 5. 验证结果

### 5.1 双例化 UT(golden vs 可读核,逐拍比对全部 49 路输出)

`iq_tb.sv` 同时例化 golden `IssueQueueLdu`(`u_g`)与可读核顶层 `IssueQueueLdu_xs`
(`u_i`),每拍随机激励全部 172 路输入(含 loadWakeUp、fromLoad 双反馈、og0/og1 响应、
ldCancel、flush、背压、replaceRCIdx),`#1` 后比对全部 49 路输出
(`!$isunknown(g) && g!==i`)。`+define+SYNTHESIS`、`+vcs+initreg+0` 让两侧寄存器从 0
上电。

| seed | checks | errors |
|------|--------|--------|
| 1  | 200000 | **0** |
| 7  | 200000 | **0** |
| 42 | 200000 | **0** |

三种子各 200000 拍 errors=0,且为 **最终 simv 二进制复跑** 确认。

### 5.2 形式等价(Formality)

`make -f Makefile.iq fm`:ref = golden `IssueQueueLdu` + 全部黑盒依赖,impl = 可读核
(顶层 wrapper)+ 同一批 golden 黑盒。

```
FM_RESULT: Verification SUCCEEDED for IssueQueueLdu
Passing compare points  2727
Failing compare points  0
Unmatched reference(implementation) compare points  0(0)
Matched primary inputs, black-box outputs  615
```

2727 个比对点全 passing,0 unmatched、0 failing——真实全等价,非降级通过。

**FM 注意**:EntriesLdu 内含 load 专属的「常量 0」死寄存器
(`entryReg_payload_{storeSetHit,waitForRobIdx,loadWaitStrict}`——自递减衰减到 0、无
外部输入,仅透传到 deqEntry)。FM 默认的「合并重复寄存器」pass 会在 wrapper/u_core 层次
边界两侧做不对称常量传播,把这些同值常量寄存器误判 `DFF0X vs DFFX` 而 fail(初次跑出
11 failing + 66 unmatched)。Makefile 里设 `FM_MERGE_DUP = false` 关掉合并即干净全 pass
(UT 已 600k 拍 errors=0 证明功能等价)。此机制 fm_eq.tcl 已为 LoadUnit 类模块预留。

### 5.3 套壳闸门

`IssueQueueLdu.sv / iq_ldu_pkg.sv / *.svh` 代码区(去 `//` 注释)对
`_GEN_ / _T_[0-9] / _REG_[0-9] / RANDOMIZE` 实测 **全 0**。核里用了 struct
(`deq_common_t / entry_t / src_status_t / payload_t / from_load_resp_t / load_wakeup_t`)、
enum(`resp_type_e / data_source_e / src_state_e`)、function(`enq_data_src / enq_src_state`)、
genvar(`g_portfu / g_trans`)、`always_comb` Mux1H 与 `for` 循环展开 loadWakeUp 6 路 copy
表达意图,非把 golden 模块体抽进套壳。

## 6. 复跑

```
cd verif/ut/IssueQueueLdu
make -f Makefile.iq compile
make -f Makefile.iq run SEED=1      # 同理 SEED=7 / 42
make -f Makefile.iq fm
```

许可证 DOWN 时先 `lmstat -a` 检查,必要时 `lmgrd` 起 license server。
