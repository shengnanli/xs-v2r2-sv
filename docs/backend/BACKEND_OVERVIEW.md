# 香山 V2R2（昆明湖）后端 Backend —— 学习导读 + 重写计划

> 前端(Frontend)、访存(MemBlock)已全部可读重写+验证完成。本文是乱序执行后端的总览与
> 重写进度索引,作为阅读 `docs/backend/` 下各模块文档的脉络。方法学沿用前端/访存(见 docs/REWRITE_STYLE.md)。

## 1. Backend 在做什么
前端送来取好的指令包, 后端做**乱序执行**:
1. **译码 Decode**: 指令 → 微操作(uop), 识别 fuType/fuOpType/源宿寄存器/立即数。
2. **重命名 Rename**: 消除 WAR/WAW 假相关, 逻辑寄存器→物理寄存器(RAT/FreeList)。
3. **派遣 Dispatch**: uop 分发到各发射队列。
4. **发射 Issue/Scheduler**: 在发射队列里等操作数就绪, 按年龄/优先级唤醒-选择发射。
5. **读寄存器 + 旁路 DataPath/BypassNetwork**: 从物理寄存器堆读操作数, 旁路在飞结果。
6. **执行 ExuBlock/FU**: ALU/Mul/Div/Branch/Jump/Bku/CSR/Fence + 浮点(FAlu/FMA/FDiv) + 向量。
7. **写回 WbDataPath**: 执行结果写回物理寄存器 + 唤醒。
8. **提交 ROB**: 按序提交, 处理异常/重定向/中断, 维护精确状态。

## 2. 顶层结构(golden Backend 34100 行 / 1230 端口, 直接例化)
```
Backend
├─ CtrlBlock            译码/重命名/派遣/ROB/重定向 控制核心
├─ Scheduler ×4         发射队列调度(int / fp / vec / mem 各一)
├─ DataPath             物理寄存器堆读 + 立即数
├─ BypassNetwork (4229) 旁路网络(在飞结果转发, 含 ImmExtractor)
├─ ExuBlock ×3          执行单元簇(各 FU 的容器)
├─ WbDataPath (3002)    写回数据通路
├─ WbFuBusyTable (198)  FU 忙表(写回端口仲裁)
├─ VecExcpDataMergeModule / Og2ForVector  向量异常/操作数
└─ NewPipelineConnectPipe / DelayN / PFEvent / HPerfMonitor  流水连接/性能
```

## 3. 重写顺序(自底向上 + 并行, 沿用既定方法学)
**第 1 层 FU 叶子(纯逻辑/小, 教学价值最高, 可并行)**:
- 整数: Alu(125)、Bku(241)、BranchUnit(340)、JumpUnit(337)、Fence(241)、MulUnit(246)、DivUnit(223)、VsetUnit
- 浮点: FAlu、FMA、FDivSqrt 等(fu/fpu)
- 向量: vector FU(fu/vector)
**第 2 层 中层**:
- decode(DecodeUnit/DecodeStage)、rename(Rename/RenameTable/FreeList)、dispatch
- issue(各 IssueQueue/Entries)、regfile、datapath、BypassNetwork、WbDataPath/WbFuBusyTable
**第 3 层 聚合**:
- CtrlBlock、Scheduler、DataPath、ExuBlock、ROB(220873 行, 含 RenameBuffer 等子模块)
**第 4 层 顶层**:
- Backend(总集成, 1230 端口)

## 4. 方法学(已验证, 见 docs/REWRITE_STYLE.md)
从 Scala 设计意图重写(非 RTL 转写)→ 结构硬闸门(struct/enum/function/genvar>0、0 生成痕迹)→
golden 双例化多种子 UT(seed 1/7/42 全输出逐拍 0 错)→ Formality 等价。子模块当 golden 黑盒;
大互联层用 glue 核 + 机械互联拆 svh 由 gen 脚本生成。
**铁律**: ① `array[可能X索引]` 恒 X → 三元 mux;② priority 仲裁用 `priority case`;
③ **UT 只比端口、会漏覆盖内部状态分叉 → 关键模块必须 tb 内部层次探针逐拍比 golden 内部寄存器**。

## 5. 进度
| 模块 | 层 | 状态 |
|------|----|------|
| [MulUnit](MulUnit.md) | 1 | ✅ UT(seed1/7/42 各 200000 拍 errors=0) + FM SUCCEEDED |
| [DivUnit](DivUnit.md) | 1 | ✅ UT(seed1/7/42 各 200000 拍 errors=0) + FM SUCCEEDED |
| [Bku](Bku.md) | 1 | ✅ UT(seed1/7/42 各 1.8M checks/0 err)；FM 主体配平，funcReg 同值副本失配已用层次探针证伪(mismatch=0) |
| (其余 FU 叶子) | 1 | 🔄 |
| 其余 | 2-4 | ⏳ 待开 |

> 完成的模块标 ✅ 并链接到各自 `docs/backend/<M>.md`。
