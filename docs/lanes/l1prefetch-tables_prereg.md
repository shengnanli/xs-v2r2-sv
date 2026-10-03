# l1prefetch-tables lane（agent/l1prefetch-tables）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `11fe690f`（集成者预建 worktree + claim） |
| 工作树 | `/home/eda/xs-env/wt-l1prefetch-tables`，分支 `agent/l1prefetch-tables` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | DelayQueue/_1、OffsetScoreTable/_1、PrefetchReqBuffer、PrefetchQueue、StrideMetaArray、StridePF、SMSTrainFilter、TrainFilter/_1 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. DelayQueue / DelayQueue_1（共用核 xs_DelayQueue_core，rtl/l2/）

- BOP 延迟队列：16 项环形 FIFO {addr, cnt}，cnt 每拍自减，队头 cnt==0 才出队；满则丢弃。
  两变体只差地址宽（42 / 44）。无子模块、无黑盒。golden 536 行；impl 核 110 行 + wrapper 各 38 行；`_GEN_`/`_T_`=0。
- UT（verif/ut/DelayQueue，两对同测）：3 seed × {initreg 0 / random / `<seed>017`} 各 200k 拍 errors=0，
  覆盖（seed 1）enq=25749 / drop_full=79602 / deq=25698 / stall=49821 / default_lat=126 / 中途异步复位 3 次。
  变异（scratchpad，seed 7 +0 20k）：M3 默认时延 300→299 CAUGHT(788)、M4 地址载荷去复位 CAUGHT(352)；
  M1 空判看 valid[0] 而非 valid[15]、M2 cnt 自减/装入优先级互换 —— 两者 UT 不可达（指针相等时各 valid 恒同；
  被入队的槽 cnt 必已为 0），寄存器次态函数不同，由 FM 兜底（见对账）。
- 预测（模型 = golden 寄存器位 + 顶层 output 位；登记 docs/fm_predictions/DelayQueue*.json）：

| 目标 | passing | 其余 |
|---|---|---|
| DelayQueue   | **905**（856 + 49） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED |
| DelayQueue_1 | **939**（888 + 51） | 同上 |

- 可能出错：两侧寄存器名不同（`queue_3_cnt` ↔ `u_core/queue_cnt[3]`，`valids_3` ↔ `queue_valid[3]`），
  靠签名匹配；本节无任何 FM 试跑。
