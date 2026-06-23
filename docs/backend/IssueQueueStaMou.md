# IssueQueueStaMou —— 访存地址发射队列(StaMou 变体)可读 SV 重写

## 1. 这是什么

香山 V2R2(昆明湖)乱序后端的「调度心脏」之一:**访存类**发射队列。本变体
**StaMou = Store-Address(STA, store 地址生成)+ Memory-Ordering(MOU, 原子/fence
地址)**。它把等待的访存地址 uop 缓存在条目阵列里,唤醒就绪后按年龄最老仲裁发射到
单条 STA/MOU 流水。

设计源:`src/main/scala/xiangshan/backend/issue/IssueQueue.scala`,其中访存地址 IQ
的派生类是 **`class IssueQueueMemAddrImp`(IssueQueue.scala:1094)**。

与整数样板 `IssueQueueAluCsrFenceDiv`(见 `IssueQueueAluCsrFenceDiv.md`)同骨架(条目
阵列 + 唤醒-选择 + 年龄最老仲裁 + 一拍 deqDelay + 在队统计),但维度更小、且带**访存
特有的 mem feedback 回灌通路**:

```
numEntries=16 / numEnq=2 / numSimp=2 / numComp=12 / numDeq=1 / numRegSrc=1
numWakeupFromIQ=7 / numWakeupFromWB=4 / LoadPipelineWidth=3 / LoadDependencyWidth=2
```

发射队列的通用机理在样板文档已详述,本文只讲**本变体相对样板的增量**(尤其 mem feedback)。

## 2. 选型说明:为什么挑 StaMou

访存类 golden 变体有 `IssueQueueLdu / StaMou / StdMoud / VlduVstu` 等。逐一对比后:

- `StdMoud`(store-data IQ,golden 最小)**没有任何访存特征**(无 feedback / 无 stIssue /
  无 sqIdx 透传到 deqEntry),本质是个被裁瘦的整数 IQ——做透它无法体现「访存类」要点。
- `Ldu`(load IQ)IO 最多(223 端口),且 load 还有 `loadWakeUp` 唤醒输出、`lqDeqPtr` 等
  额外通路,增量过大。
- **`StaMou`** 是**带真实 mem feedback 的最小访存变体**:1627 行 golden IQ,只有
  `memIO.feedbackIO_0.feedbackSlow` 一路慢响应、单源、单发射端口。它恰好满足「访存类
  里增量最小、但确实有 mem feedback」的选型目标,故选它做透。

## 3. 文件清单

| 文件 | 角色 |
|------|------|
| `rtl/backend/iq_stamou_pkg.sv` | 类型/参数包(struct/enum/维度,含 mem feedback bundle) |
| `rtl/backend/IssueQueueStaMou.sv` | IQ 顶层核 `xs_IssueQueueStaMou_core` + golden 同名穿透 wrapper |
| `rtl/backend/issuequeue_stamou_{ports,connect}.svh` | IQ 顶层端口/连线(gen 生成) |
| `scripts/gen_iq_stamou.py` | svh/tb/variant 生成器(fork 自 gen_iq_acfd.py 的 IQ 部分) |
| `verif/ut/IssueQueueStaMou/{iq_tb.sv,iq_variant_xs.sv,Makefile.iq}` | 双例化 UT + FM Makefile |

条目阵列 `EntriesStaMou`(及其 16 个单条目 `EnqEntry_20/OthersEntry_172/174`、
`EnqPolicy_14` 转移策略、`UIntCompressor` exuSources 编码器)与 3 个年龄检测器
(`NewAgeDetector_6 / AgeDetector_12 / AgeDetector_21`)均作 **golden 黑盒**直接例化,
由可读核连线。重写的是 **IQ 核的 enq/仲裁/deq/统计胶合逻辑 + 访存胶合**。

## 4. 相对 AluCsrFenceDiv 样板的增量(逐项)

enq 折算(srcState/dataSources 初值)、年龄三段仲裁(comp>simp>enq 优先级)、转移策略
(simp→comp)、deqDelay 一拍寄存、`validCntDeqVec` 在队统计等骨架逻辑与样板**逐行同构**,
只是维度从 24/2源/2端口缩到 16/1源/1端口。实质差异如下(代码里以 `[A]`..`[G]` 标注)。

### 4.1 [A] mem feedback(本变体关键访存特征)

执行端把 STA 发射后的地址翻译 / store-set 冲突检查结果,通过
`memIO.feedbackIO(0).feedbackSlow` **慢回灌**进发射队列。IQ 核把它折算成条目阵列认识的
`entries.io_fromMem_slowResp_0`(对照 IssueQueue.scala:1107):

```
slowResp.valid = feedbackSlow.valid
slowResp.resp  = feedbackSlow.hit ? RESP_SUCCESS(2'b11) : RESP_BLOCK(2'b00)
slowResp.sqIdx = feedbackSlow.sqIdx          // flag + value
```

- `hit=1` → `SUCCESS`:该 store 放行,条目确认发射成功(可清空);
- `hit=0` → `BLOCK`:该 store 需阻塞重发,条目阵列据 sqIdx 匹配把对应 `issued` 条目
  打回未发射。

golden 把 `resp` 写成 `{2{hit}}`(把 1 bit 的 hit 复制成 2 bit),恰好等于
`hit?2'b11:2'b00`,与本包 `RESP_SUCCESS/RESP_BLOCK` 编码对齐。可读核用显式三元
`hit ? RESP_SUCCESS : RESP_BLOCK` 表达**意图**(放行/阻塞),而非位复制技巧。
这是本变体唯一一处从 Scala 访存意图真重写的逻辑(其余皆骨架同构)。

> `feedbackFast` 在 STA 变体不存在(golden IQ 顶层没引出 fast 端口),条目阵列的
> `fastResp` 由 golden Entries 内部裁成常量,无需 IQ 核连。

### 4.2 [C] sqIdx 透传 / [D] isFirstIssue

访存指令携带 StoreQueue 指针 `sqIdx`:
- enq 输入 `io_enq_*_bits_sqIdx_{flag,value}` → 条目 `payload.sqIdx`;
- deqEntry 读出 `payload.sqIdx` → deqDelay 输出 `io_deqDelay_0_bits_common_sqIdx_*`。

`isFirstIssue`:deqDelay 多一路输出 `io_deqDelay_0_bits_common_isFirstIssue`,取条目阵列
`io_isFirstIssue_0`(条目 `firstIssue` 状态:是否首次发射)。执行端据此区分首发与重发,
影响 store-set 训练。样板整数 IQ 无此字段。

### 4.3 [B] 单源 / 单发射端口

`numRegSrc=1`(store 地址只需基址 1 个源寄存器)、`numDeq=1`(单 STA/MOU 流水)。
故 `dataSources / exuSources / loadDependency` 的 16-way Mux1H 只对「源 0」「端口 0」
归约一次,无样板的双源双端口展开。enq.bits 也只折算源 0。

### 4.4 [E] 无 FuBusyTable / [F] 无 wakeupToIQ

- 访存地址 IQ **不过功能单元忙表**:`deqCanIssue = canIssue & deqCanAccept`,直接进
  年龄仲裁,无样板的 `FuBusyTableRead` 黑盒与 busy mask 相与。
- STA **不产生寄存器写回唤醒**(`loadWakeUp` 仅 load 单元有),故本变体**不例化
  MultiWakeupQueue,也无 `wakeupToIQ` 输出端口**。

### 4.5 [G] 端口承担功能单元

`deqCanAccept = fuType[STA=16] | fuType[MOU=17]`(单端口同时收 STA 与 MOU)。
enq 也只保留 `fuType[16]/fuType[17]`,deqDelay 输出的 35 位 fuType 由这两位拼回。
样板整数 IQ 是 `{5 alu,6 csr,8 fence,9 div}` 按端口分工。

## 5. X 与位宽纪律(沿用样板)

- 发射 one-hot 选择全部用三元 mux / 按位与归约(`{N{sel}} & data` 后 OR),X 安全;
  feedback 折算用三元 `hit ? ... : ...`,无优先级歧义。
- 队列空(`~|e_valid`)时 deqDelay 的 bits 寄存器保持(golden 同款门控),valid 仍每拍更新。
- `validCntDeqVec` 减出队消耗用 `cnt - {pad, fire}`,无 `~` 位宽下溢风险;计数用
  `always_comb` 循环(而非读模块级信号的 function),规避 FM 的 function 敏感性告警。

## 6. 验证结果

### 6.1 双例化 UT(golden vs 可读核,逐拍比对全部 24 路输出)

`iq_tb.sv` 同时例化 golden `IssueQueueStaMou`(`u_g`)与可读核顶层
`IssueQueueStaMou_xs`(`u_i`),每拍随机激励全部 155 路输入(含 mem feedback、ldCancel、
flush、背压),`#1` 后比对全部输出(`!$isunknown(g) && g!==i`)。`+define+SYNTHESIS`、
`+vcs+initreg+0` 让两侧寄存器从 0 上电。

| seed | checks | errors |
|------|--------|--------|
| 1  | 200000 | **0** |
| 7  | 200000 | **0** |
| 42 | 200000 | **0** |

三种子各 200000 拍 errors=0,且为**最终 simv 二进制复跑**确认。

### 6.2 形式等价(Formality)

`make -f Makefile.iq fm`:ref = golden `IssueQueueStaMou` + 全部黑盒依赖,
impl = 可读核(顶层 wrapper)+ 同一批 golden 黑盒。

```
FM_RESULT: Verification SUCCEEDED for IssueQueueStaMou
Passing (equivalent)  Port=182  DFF=1715  TOTAL=1897
Failing (not equivalent)  0
Unmatched reference(implementation) compare points  0(0)
```

1897 个比对点(182 端口 + 1715 触发器)全 passing,两侧 0 unmatched、0 failing——
真实全等价,非降级通过。

### 6.3 套壳闸门

`IssueQueueStaMou.sv / iq_stamou_pkg.sv / *.svh` 代码区(去 `//` 注释)对
`_GEN_ / _T_[0-9] / _REG_[0-9] / RANDOMIZE` 实测**全 0**。核里用了 struct
(`deq_common_t / entry_t / src_status_t / mem_feedback_slow_t`)、enum
(`resp_type_e / data_source_e / src_state_e`)、function(`enq_data_src / enq_src_state`)、
genvar(`g_portfu / g_trans`)与 `always_comb` Mux1H 表达意图,非把 golden 模块体抽进套壳。

## 7. 复跑

```
cd verif/ut/IssueQueueStaMou
make -f Makefile.iq compile
make -f Makefile.iq run SEED=1      # 同理 SEED=7 / 42
make -f Makefile.iq fm
```

许可证 DOWN 时先 `lmstat -a` 检查,必要时 `lmgrd` 起 license server。
