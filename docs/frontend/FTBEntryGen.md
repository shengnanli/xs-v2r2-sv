# FTBEntryGen —— FTB 条目生成（纯组合）

| | |
|---|---|
| 手写 SV | `rtl/frontend/FTBEntryGen.sv`（`xs_FTBEntryGen_core`）+ `rtl/frontend/FTBEntryGen_wrapper.sv` |
| Scala 来源 | `src/main/scala/xiangshan/frontend/FTB.scala`（class FTBEntryGen） |
| 生成器 | `scripts/gen_ftbentrygen.py` |
| 验证状态 | UT ✅（20 万随机向量 0 错）/ FM ✅（SUCCEEDED） |

## 功能

FTQ 写回路径上，根据实际执行结果（分支命中/跳转/目标）由旧 FTB 条目生成新条目。
纯组合。处理：cfi/jmp 类型判定、init 路径（无旧条目时新建）、hit 路径插入新分支、
jalr 目标重算、strong_bias 修正、各输出字段（brSlots/tailSlot/pftAddr/carry 等）。

## 关键实现点

- 按 Scala 语义分段重构：cfi/jmp 类型、init、hit 新分支插入、jalr target、strong_bias。
- `old_target` 重建中 tarStat 高位选择用 onehot（`stat==FIT/OVF/UDF` 三项或），
  当 `tarStat==3`（非法值）时三项全 0 → 高位为 0。**这是个易错点**：若误把非法值
  归入 FIT 取 start 高位会出错——随机 UT 200000 向量恰好没采到该组合，FM 形式化抓到
  并修正（影响 is_jalr_target_modified / is_old_entry / strong_bias / tailSlot_tarStat）。
  体现 FM 对 UT 覆盖盲区的兜底价值。

参数：VAddrBits=50, PredictWidth=16, numBr=2, BR_OFFSET_LEN=12, JMP_OFFSET_LEN=20,
carryPos=5, TAR_STAT FIT/OVF/UDF=0/1/2。

## 验证

- **UT**：golden vs `FTBEntryGen_xs`，20 万随机向量比对全部 31 个输出端口，0 错。
- **FM**：SUCCEEDED（0 unmatched）。

> 本模块由并行子 agent 重写，主线已独立复跑 UT+FM 核验通过。
