# IssueQueueAluMulBkuBrhJmp —— 整数发射队列(ALU/Mul/Bku/Brh/Jmp 变体)可读 SV 重写

## 1. 这是什么

香山 V2R2(昆明湖)乱序后端的「调度心脏」之一:整数定点发射队列(IssueQueue),
本变体承载 4 个整数执行单元中的另一组,功能单元含
**ALU / Mul(乘法) / Bku(位操作) / Brh(分支) / Jmp(跳转)**。

它与样板 `IssueQueueAluCsrFenceDiv`(AluCsrFenceDiv 变体,见 `IssueQueueAluCsrFenceDiv.md`)
同骨架:`numEntries=24 / numEnq=2 / numSimp=6 / numComp=16 / numDeq=2 / numRegSrc=2`,
`hasCompAndSimp` 路,7 路 IQ 唤醒 + 4 路 WB 唤醒(纯整数 rfWen),LoadPipelineWidth=3。

发射队列的机理(条目阵列 + 唤醒-选择 + 年龄最老仲裁 + 一拍 deqDelay + 唤醒广播 + 在队
统计)在样板文档里已详述,本文只讲**本变体相对样板的增量**。

## 2. 文件清单

| 文件 | 角色 |
|------|------|
| `rtl/backend/iq_ambb_pkg.sv` | 类型/参数包(struct/enum/维度) |
| `rtl/backend/IqEntryAmbb.sv` | 单条目「唤醒-选择」核(参数化 enq/simp/comp) |
| `rtl/backend/EntriesAluMulBkuBrhJmp.sv` | 条目阵列 + 转移策略 + 年龄选择 核 |
| `rtl/backend/IssueQueueAluMulBkuBrhJmp.sv` | IQ 顶层核 + golden 同名穿透 wrapper |
| `rtl/backend/EntriesAluMulBkuBrhJmp_wrapper.sv` | golden 同名扁平 wrapper(FM 用,gen 生成) |
| `rtl/backend/issuequeue_ambb_{ports,connect}.svh` | IQ 顶层端口/连线(gen 生成) |
| `scripts/gen_iq_ambb.py` | wrapper/svh/tb 生成器(fork 自 gen_iq_acfd.py) |
| `verif/ut/IssueQueueAluMulBkuBrhJmp/` | 双例化 UT(entries_tb / iq_tb)+ Makefile{,.iq} |

## 3. 相对 AluCsrFenceDiv 样板的增量(逐项)

唤醒/取消/RegCache/loadDependency/issued/issueTimer/transEntry/年龄选择/转移策略等
**条目级与阵列级逻辑与样板逐行同构**(同一颗 `UIntCompressor_27_...` exuSources 编码器、
同一组 `og0Cancel` 命中位 `{0,2,4,6}`、同样仅源 0/1 有 is0Lat)。实质差异如下:

### 3.1 功能单元集合 / 端口分工
- FuType one-hot 保留位:样板 `{5 alu,6 csr,8 fence,9 div}` → 本变体 `{0 brh,1 jmp,6 alu,7 mul,10 bku}`。
- 发射端口分工(`deqCanAccept`):
  - **端口0 = {alu,mul,bku} = fuType{6,7,10}**;
  - **端口1 = {brh,jmp} = fuType{0,1}**。
- 影响位置:`IqEntryAmbb` 的 `readFuType`(entry_update / o_fu_type)、`Entries` 不变、
  `IssueQueue` 核的 `port0_fu/port1_fu`、`deqDelay_*_fuType` 重组、`validCntDeqVec`。

### 3.2 payload 字段:分支预测 vs flushPipe
- 本变体携带 `preDecodeInfo.isRVC` / `pred.predTaken`(送端口1 BrhJmp 与 ftq),
  **不携带** `flushPipe`(那是 Fence 专属,本变体无 Fence)。
- `deqDelay` 两端口都带 `immType`(selImm);**端口1 额外带** `preDecode_isRVC` /
  `predictInfo_taken` / `ftqIdx` / `ftqOffset`(分支单元下游需要)。

### 3.3 0 周期唤醒(is0Lat)
- 本变体 ALU/Bku/Brh/Jmp 0 延迟、Mul 多周期。唤醒广播口:
  `io_wakeupToIQ_0.bits.is0Lat = ~(deqFuType[7] | deqFuType[10])`(非 Mul/Bku 才 0 延迟)。
- 唤醒队列 `MultiWakeupQueue` enq 还带 `lat = {Mul|Bku, 0}`,使多周期源延后弹出广播。

### 3.4 WbBusyTable / FuBusyTable 双重忙表筛选(本变体新增)
- 端口0 = `canIssue & ~fuBusyTable & ~intWbBusyTable[0]`,再 & {alu,mul,bku};
- 端口1 = `canIssue & ~intWbBusyTable[1]`,再 & {brh,jmp}。
- `fuBusyTable`(Mul 多周期独占)与 `intWbBusyTable`(整数写回口冲突)的读/写表
  (`FuBusyTableRead{,_2}` / `FuBusyTableWrite`)作 golden 黑盒例化;写表吃
  「本拍发射 deqBeforeDly_0 + og0Resp」的 fuType,读表吐各条目 busy mask。
  `intWbBusyTable` 的读输入 / 写输出还引到 IQ 顶层 io 端口(与上层写回总线对接)。

### 3.5 发射响应 resp 简化
- 样板端口1 有 Div 会回 block,故 Entries 有 `og1Resp_1_bits_resp` 端口;
  本变体**无 Div**,Entries 顶层无该端口,`resp` 纯由 `issueTimer` 决定:
  `timer0→block, timer1→success, 其余→block`(`_GEN='{0,0,3,0}`)。

### 3.6 validCntDeqVec 双端口
- 样板只统计端口0 的 CSR 同类数;本变体两个端口各自统计「在队且本端口可接
  (`deqCanAccept`)」的 uop 数,减去本拍出队消耗 → `validCntDeqVec_{0,1}`。

## 4. X 与位宽纪律(沿用样板)
- 空条目/被冲刷条目的 don't-care 派生输出:golden firtool 寄存器无 reset 上电为 X,
  UT 用 `+vcs+initreg+0`(两侧从 0 上电)+ `!$isunknown` 掩蔽假阳性。
- PopCount 类计数用逻辑非 `!`(单比特)而非 `~`(定宽取反会下溢)。
- Mux1H / 年龄选择 / 转移选择一律「sel ? val : 0」累加(OR),sel=0 不引 X。

## 5. 验证结果

### 5.1 双例化 UT(golden vs 可读核,逐拍比对全部输出)
| 测试 | seed1 | seed7 | seed42 |
|------|-------|-------|--------|
| Entries(条目阵列,242 输出) | 200000 / errors=0 | 200000 / errors=0 | 200000 / errors=0 |
| IssueQueue(顶层,88 输出) | 200000 / errors=0 | 200000 / errors=0 | 200000 / errors=0 |

(`+define+SYNTHESIS`,`+vcs+initreg+random` 编译,`+vcs+initreg+0` 运行)

### 5.2 形式等价(Formality)
| 变体 | 结果 | compare points |
|------|------|----------------|
| EntriesAluMulBkuBrhJmp | SUCCEEDED | 全匹配,0 failing |
| IssueQueueAluMulBkuBrhJmp | SUCCEEDED | 4435 匹配,0 failing |

### 5.3 套壳闸门
4 个手写核(pkg / IqEntry / Entries / IssueQueue)代码区(去注释)
`grep -E "io_[a-z_]+_[0-9]+_[0-9]+|_REG_[0-9]|_GEN_|_T_[0-9]|RANDOMIZE"` = **0**。

## 6. 复跑
```
cd verif/ut/IssueQueueAluMulBkuBrhJmp
source ../../../scripts/env.sh
make compile && make run SEED=1               # Entries UT
make -f Makefile.iq compile && make -f Makefile.iq run SEED=1   # IQ UT
make fm                                         # Entries FM
make -f Makefile.iq fm                          # IQ FM
```
重生成 wrapper/svh/tb:`python3 scripts/gen_iq_ambb.py --entries`。
