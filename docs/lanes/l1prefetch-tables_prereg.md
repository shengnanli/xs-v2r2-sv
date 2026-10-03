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

## 4. StrideMetaArray / StridePF / PrefetchQueue / PrefetchReqBuffer（各自单文件：核 + golden 同名 wrapper）

- **StrideMetaArray**（rtl/memblock/，L1 stride 预取器 PC 步长表）：10 项 {pre_vaddr, stride, conf, hash_pc}，
  s0 pc 哈希 CAM + 10 路（非 2 的幂）树形 PLRU（核内 plru10_* 两个函数，编码照 rocket-chip），
  s1 分配/更新（stride_valid / 饱和置信度 / conf<=1 才改 stride），s2 算地址（ratio 2/5），s3/s4 发 L1/L2 预取。
  io.flush 恒 0 留下 10 个 RegNext（有复位、恒 0）。无子模块。golden 1403 行 / impl 318 行 / `_GEN_`=0。
  UT 9 档 200k errors=0；覆盖（seed 1 +0）hit 77283 / alloc 36740 / pf 1543 / notready 19602 / conf3 3538 / stride_invalid 15123。
  变异（seed 7 +0 20k）：M1 PLRU 根方向反 CAUGHT(1038)、M2 stride_valid 排除块号 1→2 CAUGHT(492)、
  M3 去掉 conf<=1 门控 CAUGHT(309)；M4 L2 ratio 5→4、M5 ready 恒 1 见对账。
- **StridePF**（rtl/memblock/，SMS 的 PC 步长检测器）：本配置 stride_en=0、s2_gen_req 未接 → golden 被 DCE 到
  **没有输出端口**，只剩去抖 + 16 项 pc CAM + s1 命中/分配打拍 + 16 路 PLRU（复用 rtl/common/xs_PlruReplacer，
  已在 WrBypass 签核中证过）。golden 705 行 / impl 141 行。UT 逐拍比两侧全部 53 个寄存器（层次引用，不复位的
  三组只在写过之后比）：seed 7 +0 200k errors=0（矩阵跑中）；覆盖 hit 54839 / alloc 26282 / dedup 24969 / s1drop 27180。
- **PrefetchQueue**（rtl/l2/，L2 预取出口"只留最新"队列）：32 项、永远 ready、空则直通、满则丢最老；载荷 99 位
  对队列透明（核按一根总线处理，wrapper 拼拆）。全复位。golden 1651 行 / impl 123 行。
  UT seed 7 +0 200k errors=0（矩阵跑中）；覆盖 full_drop 32750 / flow 8563 / deq 58853 / wrap 1579。
- **PrefetchReqBuffer**（rtl/l2/，VBOP 虚地址预取请求缓冲）：16 项；s0 三重丢弃（同块/全等/无空位）+ 最低位优先
  找空位打一拍写入；TLB 口按 s1/s2/s3 三级 one-hot 记账，回答打一拍后与 PMP 回答一起判 fired / 首 miss 重放
  （replayCnt=10）/ 再 miss 作废 / 异常作废；PF 口仲裁发出即作废。子模块 RRArbiterInit_14（TLB）/ _15（PF）
  均 PROVEN_DIRECT → 两侧白盒（ref golden、impl rtl/common 重写件），无黑盒。golden 1713 行 / impl 394 行。
  UT 带 1 拍 TLB 响应模型；seed 7 +0 200k errors=0（覆盖门槛 match 671<1000 调激励后矩阵重跑中）。
- 预测（docs/fm_predictions/*.json）：

| 目标 | passing | 其余 |
|---|---|---|
| StrideMetaArray   | **993**（827 + 166）  | 10 个 RegNext(flush=0)（golden `last_REG*` ↔ impl `flush_q[i]`，有复位恒 0）可能被折成 constant_reg → 实测预计 983 + constant_reg 10；failing 0 / unmatched 全 0 / 无黑盒 / SUCCEEDED |
| StridePF          | **220**（220 + 0）    | 无输出端口，全部是寄存器比较点；failing 0 / unmatched 全 0 / SUCCEEDED |
| PrefetchQueue     | **3310**（3210 + 100）| failing 0 / unmatched 全 0 / SUCCEEDED |
| PrefetchReqBuffer | **2938**（2786 + 152）| 含两侧白盒仲裁器的寄存器；failing 0 / unmatched 全 0 / 黑盒 0 / SUCCEEDED |

- 可能出错：StrideMetaArray 的 s1_index 越界读第 0 项用循环选择器；PrefetchReqBuffer 的 TLB 发出寄存器是
  RegEnable(常量)（isPrefetch 粘住 / kill、no_translate 在 valid 时清 0），已照 golden 写；PrefetchQueue 的
  载荷寄存器 golden 按字段分、impl 一根 99 位总线，靠签名匹配。本节无 FM 试跑。

## 5. TrainFilter 第二轮（第一轮 FM 抓到真差异）

第一轮（c8313ce2）TrainFilter FAILED：failing 5 = train_req.valid 端口 + deqPtr 4 位。根因：深 6 的 deqPtr.value
是 3 位，越界值 6/7 时 golden 的 `when(deqPtr === i.U)` 没有一项命中 → valid=0，而核写成"越界读第 0 项的 valid"。
UT 不可达（指针永不越界）。修法：核里 deq 选择器 valid 默认 0（9bf5ad8c）。TrainFilter_1（深 4，2 位指针无越界）
与 SMSTrainFilter（深 8）不受影响，但共用核字节变了，三者一起重证。预测不变（1678 / 818 / 2751，各减 constant_reg 1 /1 /0）。

## 6. SMSTrainFilter 第二轮（vmucp）

第一轮（058ddde1，在 9bf5ad8c 修复之后）：native SUCCEEDED passing 2743 / failing 0 / unmatched 0，
validator PARTIAL：unread 8 = ref enqPtrExt_3/4 的 flag+value 8 位 ↔ impl enq_flag/enq_value[3..4] 8 位，
两侧对称死位（分配下标 PopCount ≤ 2，3/4 号指针永不被读）。按 vmucp standing rule 六条加
verif/fm_target_config/SMSTrainFilter.tcl + Makefile 开 FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS。
预测：passing **2751**（= 2743 + 8 = 模型 2751），unread 0，其余全零，SUCCEEDED。

## 7. StrideMetaArray / StridePF 第二轮（vmucp；StridePF 加钉点）

- StrideMetaArray 首跑（c30ff018）：native SUCCEEDED passing 981 / constant_reg 10 / unread 2（s2_vaddr[1:0] 两侧按名
  配上的对称死位：加数 stride<<2 低 2 位恒 0）。加 verif/fm_target_config/StrideMetaArray.tcl。
  预测：passing **983**（= 981 + 2 = 模型 993 − constant_reg 10），unread 0，其余全零，SUCCEEDED。
- StridePF 首跑（c30ff018）：**0 比较点**（golden 无输出端口），220 位寄存器全 unread（10 按名配上 + 210 未配），
  sidecar 拒出 receipt（nonfinal_verification_status）。修法：新生成器 scripts/gen_stridepf_pins.py（带 --check）
  产出 verif/ut/StridePF/fm_pins_pre.tcl（210 位，fail-closed）+ verif/fm_target_config/StridePF.tcl 开 vmucp，
  让 FM 比较全部 220 个寄存器的次态函数。预测：passing **220**（= 模型 220），unread 0，其余全零，SUCCEEDED。
  可能出错：钉点路径格式（`u_core/ent_pc_reg[i][b]`、`u_core/u_plru/state_reg_reg[b]`）若与 FM 实际名不同会
  `error` 早退（FM 早退而非数字偏离）。

## 8. SMSTrainFilter 第三轮 / PrefetchQueue 第二轮（钉点 + vmucp）

- SMSTrainFilter 第二轮（8dd734c6）：vmucp 已开但 unread 仍 8 —— 这 8 位是 **Unmatched unread**（FM 配不上），
  vmucp 只比较已配对的 unread 点，空转。§6 里"FM 按签名自动配上"的说法错误，已在 config 里更正。
  修法：scripts/gen_stridepf_pins.py 泛化为 scripts/gen_l1pf_pins.py（三目标，带 --check），生成
  verif/ut/SMSTrainFilter/fm_pins_pre.tcl（8 位）。预测不变：passing **2751**，unread 0，SUCCEEDED。
- PrefetchQueue 首跑（8dd734c6）：native SUCCEEDED passing 3279 / unread 31（valids_0..30 ↔ queue_valid[0..30]，
  Unmatched unread；empty/full 只读 valids_31）。加钉点（31 位）+ verif/fm_target_config/PrefetchQueue.tcl。
  预测：passing **3310**（= 3279 + 31 = 模型 3310），unread 0，SUCCEEDED。
- StridePF：生成器改名后 fm_pins_pre.tcl 只改了注释头与 tcl 过程名（钉点表 210 位逐行不变）；
  0a9f5511 上在跑的那轮作诊断用，签核以本节 commit 上的重跑为准，预测仍为 220。
