# Scheduler_3(Mem 变体)—— 访存发射调度顶层

> 设计源:`src/main/scala/xiangshan/backend/issue/Scheduler.scala`
> (`class Scheduler` / `SchedulerImpBase` / `SchedulerMemImp`)
> golden:`golden/chisel-rtl/Scheduler_3.sv`(约 5005 行,1225 端口,Mem 变体)
> 可读核:`rtl/backend/Scheduler_3.sv` + `scheduler_mem_pkg.sv` + `scheduler_mem_iq_connect.svh`
> 生成器:`scripts/gen_scheduler_variants.py mem`

## 1. 架构定位

同其余变体:互联顶层,逻辑全在 IssueQueue 黑盒里。Mem 是规模最大的变体,
内含 **9 个访存发射队列**:

| 编号 | 实例 | IssueQueue 类型 | 功能 | perf full 位 |
|------|------|----------------|------|-------------|
| IQ0 | `IssueQueueStaMou`     | `IssueQueueStaMou` | 存地址/AMO #0 | bit0 |
| IQ1 | `IssueQueueStaMou_1`   | `IssueQueueStaMou` | 存地址/AMO #1 | bit1 |
| IQ2 | `IssueQueueLdu`        | `IssueQueueLdu`    | Load #0 | bit2 |
| IQ3 | `IssueQueueLdu_1`      | `IssueQueueLdu`    | Load #1 | bit3 |
| IQ4 | `IssueQueueLdu_2`      | `IssueQueueLdu`    | Load #2 | bit4 |
| IQ5 | `IssueQueueVlduVstuVseglduVsegstu` | 同名 | 向量访存(含段) | bit5 |
| IQ6 | `IssueQueueVlduVstu`   | `IssueQueueVlduVstu` | 向量 Load/Store | bit6 |
| IQ7 | `IssueQueueStdMoud`    | `IssueQueueStdMoud` | 存数据/AMO #0 | bit7 |
| IQ8 | `IssueQueueStdMoud_1`  | `IssueQueueStdMoud` | 存数据/AMO #1 | bit8 |

## 2. Scheduler 做的四件事 + Mem 专属 glue

### A) 例化 9 个 IssueQueue 并互联(`scheduler_mem_iq_connect.svh`)
纯连线。访存反馈端口 `io_fromMem_staFeedback_* / vstuFeedback_* / wakeup_* /
lqDeqPtr / sqDeqPtr / ldCancel_*` 等**本身无顶层逻辑**,直接连进对应 IQ 黑盒
(在实例连线表里透传)。同 Vf 的 32 条向量写回 pdest 零扩展线也在此就近声明。

### B) dispatch-ready 透传(Mem 专属:Sta/Std 共享端口)
存指令在 dispatch 同一拍同时进「存地址队列(Sta)」与「存数据队列(Std)」,
二者**共享 dispatch 端口 0..3**。故:
- `io_fromDispatch_uops_0_ready = StaMou.enq0.ready & StdMoud.enq0.ready`
- `io_fromDispatch_uops_2_ready = StaMou_1.enq0.ready & StdMoud_1.enq0.ready`
  (两个队列都能收,这条 store uop 才算被接收)
- Ldu/Vldu 各自独立:端口 4/6/8/10/12 直接取各自 IQ 的 enq0.ready。

**Sta enq.valid 的 AMO-CAS 门控**:存地址侧的入队 valid 不是原始 dispatch valid,
而是 `valid & ~isDropAmocasSta`(AMO-CAS 指令丢弃存地址微指令)。golden 用临时名
`_IssueQueueStaMou_io_enq_X_valid_T_Y` 表达,本核改成语义名 `sta_enq_valid_uop0..3`
(就近声明在 svh,去掉 firtool 临时 `_T_`)。Std 侧用原始 dispatch valid。

### C) deqDelay 输出扇出
9 个 IQ 的 `deqDelay_0_valid` 全部经内部线扇出到对应的
`io_toDataPathAfterDelay_0..8_0_valid`(golden 里另各有一份 dead probe 扇出,已裁剪)。

### D) 发射 perf 统计
- `enq_fire[18]` = 9 个 IQ × 2 路 enq 的 `ready & valid`;其中 Sta 两路用
  `sta_enq_valid_uop*`(已门控),Std 两路用原始 `io_fromDispatch_uops_{0..3}_valid`,
  Ldu/Vldu 用各自 `io_fromDispatch_uops_{4..13}_valid`。
- `iq_full[9]` = 每 IQ 的 `enq0.ready`。
- 三级 RegNext 流水;`popcount` 对 18 位求和(结果 5bit,最大 18);`io_perf_0` 端口 6bit
  高位补 1'h0,其余 full 端口 6bit 高位补 5'h0。

## 3. 验证结果

### 结构闸门
| 项 | 结果 |
|----|------|
| `typedef struct packed` | 1(`perf_sample_t`) |
| `typedef enum` | 1(`iq_id_e`,9 个 IQ 标识) |
| `function automatic` | 1(`popcount` 18→5bit) |
| `for` 循环 | 1 |
| 核+pkg 生成痕迹(`io_*_N_N`/`_REG_N`/`_GEN_`/`_T_N`/`RANDOMIZE`) | **0**(Sta 门控 `_T_` 已改语义名) |
| svh `_GEN_/_T_` 密度 | **0** |

### UT(双例化逐拍比对全部 312 输出)
u_g=golden `Scheduler_3`,u_i=`Scheduler_3_xs`;共享 golden IQ 黑盒(32 模块闭包)。

| seed | checks | errors |
|------|--------|--------|
| 1  | 200000 | 0 |
| 7  | 200000 | 0 |
| 42 | 200000 | 0 |

### Formality 等价
`FM_RESULT: Verification SUCCEEDED`(26017 passing,0 failing,0 unmatched)。

> 注:Mem 的 Makefile 设了 **`FM_MERGE_DUP = false`**。开 merge-dup 时,Ldu 黑盒内的
> load-dependency 寄存器(loadWaitStrict/storeSetHit/waitForRobIdx)在「ref 顶层标量
> vs impl u_core 内」两侧被不对称地常量传播,误判 Constant0 vs Constrained0X,曾导致
> 180 unmatched + 20 failing。关掉寄存器合并后干净比对(同 fm_eq.tcl 注释里的 LoadUnit
> 场景)。Fp/Vf 无此类寄存器,默认开启 merge-dup 即可 SUCCEEDED。

## 4. 复跑
```bash
cd verif/ut/Scheduler_3
source ../../../scripts/env.sh
make compile
make run SEED=1   # 或 SEED=7 / SEED=42
make fm
```
