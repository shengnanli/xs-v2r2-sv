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

## 2. OffsetScoreTable / OffsetScoreTable_1（共用核 xs_OffsetScoreTable_core，rtl/l2/）

- BOP 偏移评分表：候选偏移各配 5 位得分；学习态逐个候选向 RR 表查询 X-d，命中加分；得分到 31 或轮数到 50
  结束，idle 一拍发布最高分偏移并清场。两变体差：PBOP 37 候选/7 位/BAD_SCORE=1/地址 48；VBOP 109 候选/10 位/
  BAD_SCORE=2/地址 50。候选表作为 wrapper 的 localparam 传入核；下标越界读第 0 项用循环选择器（非 2 的幂，防 ELAB-147）。
  无子模块、无黑盒。golden 809 / 1793 行；impl 核 185 行 + wrapper 66 / 75 行；`_GEN_`/`_T_`=0。
- UT（verif/ut/OffsetScoreTable，两对同测）：9 档各 200k errors=0；覆盖（seed 1 +0）idle 189/138、
  score_full 102/108、rounds_done 84/27、disable 31/14、oob_hit 5877/409、中途复位 3。
  变异（scratch，seed 7 +0 20k）：M1 轮数比较 >=→> CAUGHT(3350)、M3 越界默认项 0→1 CAUGHT(755)、
  M4 到顶判 newScore→oldScore CAUGHT(17662)、M5 idle 不清 bestScore CAUGHT(8189)；M2 BAD_SCORE 比较 <→<=
  20k 未抓到（需 bestScore 恰好 == BAD_SCORE 的阶段），200k 复跑见对账。
- 预测（登记 docs/fm_predictions/OffsetScoreTable*.json）：

| 目标 | passing | 其余 |
|---|---|---|
| OffsetScoreTable   | **289**（218 + 71） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED |
| OffsetScoreTable_1 | **665**（585 + 80） | 同上 |

- 可能出错：golden `st_<i>_score` ↔ impl `u_core/score[i]`、`state` 是 enum；靠签名匹配；无 FM 试跑。

## 3. TrainFilter / TrainFilter_1 / SMSTrainFilter（共用核 xs_TrainFilter_core，rtl/memblock/）

- 训练过滤器：3 路 load 训练记录经三级不复位重排序流水（按 robIdx 排程序序）→ 按块哈希去重 → 带翻转位
  环形指针的小 FIFO。三变体：TrainFilter（载荷 pc，深 6，有 enable/ready/flush 打拍）、TrainFilter_1
  （载荷 {miss, meta_prefetch} 入队折成 {miss, pfHitStream}，深 4）、SMSTrainFilter（载荷 {paddr, pc}，深 8，
  条目复位，无 enable/ready/flush，5 个入队指针其中 3/4 号只跟着走）。无子模块、无黑盒。
  golden 808 / 754 / 1126 行；impl 核 355 行 + wrapper 55 / 67 / 68 行；`_GEN_`/`_T_`=0。
- UT：verif/ut/TrainFilter（两对同测）与 verif/ut/SMSTrainFilter，各 9 档 200k errors=0。
  覆盖（seed 1 +0）TF：three_valid 35085 / swap 61649 / dedup_entry 37188 / dedup_prev 23824 / full 24221 /
  fire 114348 / disable 2041 / wrap 19056 / stream 81383；SMS：三路有效 61202 / swap 69489 / dedup 11364+8277 /
  判满 70990 / fire 160529 / wrap 20064。tb 先在复位期间送 valid=0 把不复位的三级流水冲成 0，
  条目内容只在 train_req.valid=1 时比（TF/TF_1）。变异结果见对账（跑中）。
- 预测（登记 docs/fm_predictions/TrainFilter*.json、SMSTrainFilter.json）：

| 目标 | passing | 其余 |
|---|---|---|
| TrainFilter    | **1678**（1577 + 101） | failing 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED；golden `REG`（RegNext(flush=0)，不复位恒 0）↔ impl `flush_q`，若 FM 把两侧都折成常数会在 constant_reg 里各记 1 |
| TrainFilter_1  | **818**（765 + 53）    | 同上 |
| SMSTrainFilter | **2751**（2602 + 149） | 同上；无 flush 寄存器；3/4 号入队指针两侧都存在 |

- 可能出错：(1) 载荷打包——golden 的 miss/meta_prefetch（TF_1）、paddr/pc（SMS）是分开的寄存器，impl 是一根
  payload 向量的切片，位级一一对应但名字对不上，靠签名匹配；(2) 三级流水寄存器 golden 名 `ld_in_reordered_res_0_1_<k>_*`
  ↔ impl `a_*[k]` 等；(3) 本节无 FM 试跑。
