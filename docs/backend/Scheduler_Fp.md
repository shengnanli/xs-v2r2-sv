# Scheduler_1(Fp 变体)—— 浮点发射调度顶层

> 设计源:`src/main/scala/xiangshan/backend/issue/Scheduler.scala`
> (`class Scheduler` / `SchedulerImpBase` / `SchedulerArithImp`)
> golden:`golden/chisel-rtl/Scheduler_1.sv`(1197 行,331 端口,Fp 变体)
> 可读核:`rtl/backend/Scheduler_1.sv` + `scheduler_fp_pkg.sv` + `scheduler_fp_iq_connect.svh`
> 生成器:`scripts/gen_scheduler_variants.py fp`

## 1. 架构定位

与 Int Scheduler 完全同源:Scheduler 是「发射调度顶层」,把若干 **IssueQueue
(发射队列)** 例化在一起做互联。**Scheduler 本身几乎不含算法逻辑**——乱序调度
(条目阵列/年龄仲裁/唤醒队列/FU busy 表)全部封装在 IssueQueue 黑盒里。

Fp 变体内含 **3 个浮点发射队列**:

| 编号 | IssueQueue 类型 | 承担的功能单元 | enq 端口 | perf full 位 |
|------|----------------|---------------|---------|-------------|
| IQ0  | `IssueQueueFaluFcvtF2vFmacFdiv` | 浮点 ALU/转换/F2V/乘加/除法 | uops 0,1 | bit0 |
| IQ1  | `IssueQueueFaluFmacFdiv`        | 浮点 ALU/乘加/除法 | uops 2,3 | bit1 |
| IQ2  | `IssueQueueFaluFmac`            | 浮点 ALU/乘加 | uops 4,5 | bit2 |

## 2. Scheduler 做的四件事(可读核四节)

### A) 例化 3 个 IssueQueue 并互联(`scheduler_fp_iq_connect.svh`)
纯连线:每个 IQ 的端口直接连到顶层对应端口(唤醒网络/og0/og1 resp/cancel)。
无任何组合/时序逻辑、无 `_GEN_/_T_`。

### B) dispatch-ready 透传
每个 IQ 的 `enq0.ready` 回送给对应的 `fromDispatch.uops.ready`(3 条 assign:端口 0/2/4)。

### C) deqDelay 输出扇出
第 3 个 IQ(`IssueQueueFaluFmac`)的 `deqDelay_0_valid` 经内部线扇出到
`io_toDataPathAfterDelay_2_0_valid`(golden 里这条多了一份「dead probe」扇出,
属可裁剪冗余,本核只保留对外端口扇出)。前两个 IQ 的 deqDelay 直连输出端口。

### D) 发射 perf 统计(唯一的真实逻辑)
- `enq_fire[6]` = 每 IQ 每路 `enq.ready & uop.valid`;
- `iq_full[3]` = 每 IQ 的 `enq0.ready`;
- 三级 RegNext 流水(与 firtool 一致):先把 `enq_fire/iq_full` 各打一拍
  (`last_cycle_*`),再对已寄存的 `enq_fire` 求 `popcount`(故计数比 fire 晚一拍),
  最后再打一拍输出。`perf_sample_t` struct 表达两级流水,`popcount()` 用
  `for` 循环替代 firtool 的嵌套加法树。`io_perf_0` 计数 3bit(最大 6),其余 full 位 1bit,
  端口统一 6bit 高位补 0。

## 3. 验证结果

### 结构闸门
| 项 | 结果 |
|----|------|
| `typedef struct packed` | 1(`perf_sample_t`,pkg) |
| `typedef enum` | 1(`iq_id_e`,pkg) |
| `function automatic` | 1(`popcount`,pkg) |
| `for` 循环 | 1(popcount 计数) |
| 核+pkg 生成痕迹(`io_*_N_N`/`_REG_N`/`_GEN_`/`_T_N`/`RANDOMIZE`) | **0** |
| svh `_GEN_/_T_` 密度 | **0**(纯例化+连线) |

### UT(双例化逐拍比对全部 124 输出)
u_g=golden `Scheduler_1`,u_i=可读核 `Scheduler_1_xs`;两侧共享 golden IQ 黑盒(39 模块闭包)。

| seed | checks | errors |
|------|--------|--------|
| 1  | 200000 | 0 |
| 7  | 200000 | 0 |
| 42 | 200000 | 0 |

### Formality 等价
`FM_RESULT: Verification SUCCEEDED`(详见复跑)。

## 4. 复跑
```bash
cd verif/ut/Scheduler_1
source ../../../scripts/env.sh
make compile
make run SEED=1   # 或 SEED=7 / SEED=42
make fm
```
