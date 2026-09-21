# PtwCache —— FM passing 跑前登记（本文件在证明之前进库，之后不许改）

登记时的 impl 基线：`agent/ptwcache2` @ 9280f5bc3651ae07e8ad9c80b06dc8f64ac4e032
（"§17-§22：响应装配/perf/栅栏失效/bitmap wakeup 全段追清，236 个输出全驱动"）
golden：G1-canonical/golden-rtl/PtwCache.sv（45308 行，单变体）

## 模型给出的数

    python3 scripts/fm_passing_model.py --from-ut PtwCache
      regs 21088 + outs 2714 = 23802

## ★这个数不能当预测用★

两条独立的理由，任何一条单独就足以让它失去点预测的资格：

1. **merge_dup=true**（本目标没有关掉它的理由，fm_eq.tcl 默认打开）。
   模型的等式 `passing = Σ实例寄存器位 + 顶层输出位` 只在
   `verification_merge_duplicated_registers = false` 时成立。打开时 FM 会把重复
   寄存器合并成一个比较点，合并掉多少取决于设计里有多少重复结构 —— 不是能从
   golden 静态算出来的量。fm_predict.py 自己就把本目标标成 `model_applicable=false`。
   而 PtwCache 恰恰是重复结构极多的件：l0BitmapReg 一个阵列就是 64×4×8 = 2048 位
   同形寄存器，l0h/l0vpns/l0asids/l0vmids 四个 64×4 影子阵列同理。
   合并的余地大到"上界"这个词都快没意义。

2. **模型漏算了 SRAM 一路的存储位**。`fm_passing_model.py` 的实例扫描正则要求
   模块名首字母大写（`^  [A-Z]\w* inst (`），而这一路的实例是
   `sram_array_1p4x786m131s1h0l1b_ptw_l1 array (` 与 `array_10 array (` —— 全小写，
   一个都没数到。手工补算：
     · array_10_ext  ×1 ：`reg_RW0_ren`(1) + `reg_RW0_addr`(2) + `ram [3:0]` 786 位 = 3 + 3144
     · array_11_ext  ×16：(1 + 6) + `ram [63:0]` 114 位 = 7 + 7296，共 112 + 116736
   即模型少算了 ~119,880 位存储 + 115 位流水寄存器。FM 对存储阵列怎么建比较点
   （逐位 / 逐字 / 一个 memory 点）本轮没有实测依据，所以连这块补算都只是量级。

    结论：**预测带宽 = 从 ~2.4e4 到 ~1.4e5，带宽远超 30%，近乎无信息。**
    按 fm_predict.py 的规矩，本目标记 MODEL_NA，**不给点预测**。
    谎称"差不多 23802"才是最坏的选项。

## 那么这次跑前到底承诺什么

不承诺 passing 的数值，承诺**可证伪的定性判据**（跑完逐条对账）：

  P1  native 结论 = SUCCEEDED（不是 INCONCLUSIVE，不是 elaborate 失败）
  P2  failing = 0
  P3  unmatched（两侧任一）= 0 —— 结构上每个 golden 比较点都有对位
  P4  unread = 0 且 allowlist 为空（signoff-strict 的 unread 铁律）
  P5  黑盒边界为空（SRAM 一路两侧同源读 golden，见 verif/ut/PtwCache/Makefile）

★P3 是本轮最可能挂的一条★，已知的三处结构风险（都在 impl 侧，已尽力照抄，
但没有独立验证过）：
  · golden 在 stageCheck 级另存了 `ishptw` / `s2x_info` / `pte_index` 三个寄存器，
    与流水载荷 `data_1_*` 同值但是**另外三个寄存器**。impl 目前用 check_* 一份，
    ★这三点预计 unmatched★。
  · bypass 的 `bypassed_N_valid` 四份同值寄存器 —— impl 已照抄成 4 位向量，应对上。
  · wakeup 第二拍 golden 不存 tag/s2xlate —— impl 已照抄"不存"，应对上。

对账要求：跑完把实测 passing/failing/unmatched/unread 抄回本文件下方的
「跑后对账」一节，逐条标 P1..P5 命中与否；**不许回头改上面的任何一行**。

## 跑后对账

（留空，跑完补。）
