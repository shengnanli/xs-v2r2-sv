# Scheduler_2(Vf 变体)—— 向量浮点/定点发射调度顶层

> 设计源:`src/main/scala/xiangshan/backend/issue/Scheduler.scala`
> (`class Scheduler` / `SchedulerImpBase` / `SchedulerArithImp`)
> golden:`golden/chisel-rtl/Scheduler_2.sv`(约 1977 行,578 端口,Vf 变体)
> 可读核:`rtl/backend/Scheduler_2.sv` + `scheduler_vf_pkg.sv` + `scheduler_vf_iq_connect.svh`
> 生成器:`scripts/gen_scheduler_variants.py vf`

## 1. 架构定位

同 Int/Fp:互联顶层,逻辑全在 IssueQueue 黑盒里。Vf 变体内含 **3 个向量发射队列**:

| 编号 | IssueQueue 类型 | 承担的功能单元 | enq 端口 | perf full 位 |
|------|----------------|---------------|---------|-------------|
| IQ0  | `IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf` | 向量乘加/定点 ALU/乘累加/排列/浮点 ALU/转换/IPU/vset | uops 0,1 | bit0 |
| IQ1  | `IssueQueueVfmaVialuFixVfalu` | 向量乘加/定点 ALU/浮点 ALU | uops 2,3 | bit1 |
| IQ2  | `IssueQueueVfdivVidiv`        | 向量浮点/整数除法 | uops 4,5 | bit2 |

## 2. Scheduler 做的四件事(可读核四节)

### A) 例化 3 个 IssueQueue 并互联(`scheduler_vf_iq_connect.svh`)
纯连线。**Vf 专属:32 条向量写回唤醒的「pdest 零扩展」组合线**——
`wakeupFrom{Vf,V0,Vl}WB[Delayed]_*_bits_pdest = {高位0, io_*WriteBack*_addr}`,
把向量写回的寄存器号补齐成 8bit 物理目的号 pdest 后喂给各 IQ 的唤醒端口。
这些是纯位拼接,就近声明在 svh 的 IQ 例化之前(可读、无 `_GEN_/_T_`)。

### B) dispatch-ready 透传
每个 IQ 的 `enq0.ready` 回送给 `fromDispatch.uops.ready`(3 条:端口 0/2/4)。

### C) deqDelay 输出扇出
第 3 个 IQ(`IssueQueueVfdivVidiv`)的 `deqDelay_0_valid` 扇出到
`io_toDataPathAfterDelay_2_0_valid`;前两个 IQ 直连输出端口。

### D) 发射 perf 统计
同 Fp:`enq_fire[6]` + `iq_full[3]`,三级 RegNext 流水,`popcount` 用 `for` 循环。

## 3. 验证结果

### 结构闸门
| 项 | 结果 |
|----|------|
| `typedef struct packed` | 1(`perf_sample_t`) |
| `typedef enum` | 1(`iq_id_e`) |
| `function automatic` | 1(`popcount`) |
| `for` 循环 | 1 |
| 核+pkg 生成痕迹 | **0** |
| svh `_GEN_/_T_` 密度 | **0**(32 条 pdest 扩展为纯位拼接,不计 `_GEN_/_T_`) |

### UT(双例化逐拍比对全部 183 输出)
u_g=golden `Scheduler_2`,u_i=`Scheduler_2_xs`;共享 golden IQ 黑盒(37 模块闭包)。

| seed | checks | errors |
|------|--------|--------|
| 1  | 200000 | 0 |
| 7  | 200000 | 0 |
| 42 | 200000 | 0 |

### Formality 等价
`FM_RESULT: Verification SUCCEEDED`。

## 4. 复跑
```bash
cd verif/ut/Scheduler_2
source ../../../scripts/env.sh
make compile
make run SEED=1   # 或 SEED=7 / SEED=42
make fm
```
