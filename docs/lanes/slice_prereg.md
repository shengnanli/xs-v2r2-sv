# Slice lane（agent/slice）—— 跑前登记

本文件在目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `d5564588`（main，`git worktree add /home/eda/xs-env/wt-slice -b agent/slice main`） |
| 工作树 | `/home/eda/xs-env/wt-slice`，分支 `agent/slice` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| Scala | `/home/eda/xs-env/XiangShan/coupledL2/src/main/scala/coupledL2/tl2chi/Slice.scala`（232 行） |
| 目标 | `Slice` / `Slice_1` / `Slice_2` / `Slice_3`（golden 各 10,261 行 / 511 端口） |
| 口径 | `assembly`（黑盒只有厂商 SRAM 叶子 array_14..18_ext 与 codex 0202 审定的 ram_10x89，两侧对称）、`FM_MERGE_DUP=false`（理由见 verif/ut/Slice/Makefile 与 §3）、vmucp 开（verif/fm_target_config/Slice*.tcl）、无 dont_verify |
| codex / kimi 冲突 | 第 0 步已查：outbox 至 codex_0205（rounding/arbiter/result-control 叶子）、codex/* 分支与 kimi k3next30 清单均不含 Slice 及其 child |

## 1. 结构

- 可读核 `rtl/uncore/Slice.sv`（xs_Slice_core，参数 SLICE_ID）：手写区只有 §1 releaseBuf 读响应打一拍 / §2 错误报告打一拍 /
  §3 TopDown·预取统计输出 / §4 性能事件打两拍；15 个 child 的互连（4,386 行）由 `scripts/gen_l2_slice.py` 从 golden 端口表与
  实例连线机械生成（GENERATED 区；每条连线 fail-closed 归类：顶层端口 / child 输出线 / 常量 / 悬空 / MBIST 线 / 手写信号）。
- 四个变体：golden 只差 TXREQ 的 sliceId 常量、Directory_N / DataStorage_N / L2Slice_N 三个 child 的单态化、MBIST bore 数组位宽
  （生成器把四份 golden 规整掉这几维后要求逐字相同，否则不出文件）。所以目录 / 数据阵列 / MBIST 分发放在各变体 wrapper 里
  （Slice 在同文件；Slice_1/2/3.sv 为生成的薄文件，各 2,960 行），核与它们之间走 dir_* / ds_* 接口。
- 代码区 `_GEN_`/`_T_` = 0；`scripts/readability_audit.py` rc=0。
- child 全部**两侧白盒**（docs/coverage_three_axis.tsv：18 类 child 全 PROVEN_DIRECT，TXREQ/TXRSP 里的 Queue16_CHIREQ/CHIRSP 为
  PROVEN_IN_CONE 的 golden 复用件，两侧共读）；黑盒只有 array_14..18_ext（verif/vendor_boundary.tsv 审定）与 ram_10x89
  （codex 0202 单条审定，GrantBuffer/Queue10_GrantBuffer_Anon 闭包内两侧对称），每变体各 6+1 对。

## 2. UT（verif/ut/Slice，四对同测；tb 由 gen_tb.py 生成）

逐拍 4 态比四个变体全部 334 个输出。未复位寄存器 / 存储阵列的初值同步表从各 child 的 UT tb 机械收割（gen_tb.py 文件头）。
两次 tb 修正（都是激励缺陷，不是电路差异）：
1. 厂商 SRAM 叶子存储体不初始化 → tag/数据读出全 X、流水在 X 上停摆、比对 X===X 空过：编译加 `+define+RANDOMIZE_MEM_INIT`
   （只影响 array_*_ext 的 initial 块）。
2. tb 随机翻 DFT 备用时钟 aux_clk / aux_ckbp：ClockMux 是普通 mux，门控时钟为高时切 sel 造出一个与数据同一时刻的时钟沿，
   两侧对 wmode 的采样顺序不同（seed 1 initreg 0 第 19687 拍，宏在 +1ns 收到 ckbp 翻转产生的沿）→ bore_outdata 失配 16 次。
   改为恒 0（同 DataStorage / Directory UT）。
激励要点：地址 tag 0..15 × set 0..3；RXDAT/RXRSP 只发给处在对应等待状态的 MSHR（否则 MSHR 被推进不可能状态永不释放、整个
slice 停摆——首版激励 15k 拍后 16 个 MSHR 全卡死）；P-Credit 只在 MSHR 查询时给；每 4000 拍三个阶段（常速 / 下游慢逼 MSHR 全占 /
MBIST 窗口）。覆盖 23 项（A/C/D/B/E 握手、三个 TX、RXSNP、MSHR 分配与全占、目录命中/缺失、两个缓冲写、数据阵列写、hint、预取
train/resp/sent、L2 miss、dirResult、MBIST ack），任一为 0 判 FAILED。

UT 读数（commit 39234527 的字节；之后的提交只动 FM 钉点 / Makefile FM 变量 / 生成器的钉点收割，不动 RTL 与 tb）：

| seed | initreg+0 | initreg+random | initreg+<seed>017 |
|---|---|---|---|
| 1  | checks=267200000 errors=0 cover_zero=0 | errors=0（= 全 1 档，见 CONVENTIONS） | errors=0 |
| 7  | errors=0 | errors=0 | errors=0 |
| 42 | errors=0 | errors=0 | errors=0 |

覆盖（seed 1 initreg 0，200k 拍）：A 收下 1747 / C 11985 / D 6040 / B(Probe) 271 / E 39740 / TXREQ 2048 / TXRSP 1799 /
TXDAT 244 / RXSNP 490 / MSHR 分配 1886 / 目录命中 1505 / 缺失 7275 / MSHR 全占 8478 拍 / releaseBuf 写 717 / refillBuf 写 3259 /
数据阵列写 1380 / L1 hint 789 / 预取 train 597 / resp 11 / sent 782 / L2 miss 38184 / dirResult 7334 / MBIST ack 49953。
复跑：`cd verif/ut/Slice && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

变异自检（scratchpad，不进库，seed 7 random 20k 拍）：M1 dirResult.valid 不排除 replResp ⇒ errors=469；
M2 perf 只打一拍 ⇒ errors=1078；M4 refillBuf 两写口 valid 对调 ⇒ errors=148824；M5 Slice_1 的 sliceId 改 0 ⇒
errors=20000（pair1 tx_req addr）；M6 error 地址最低位清零 ⇒ errors=4447（均 CAUGHT）。
**UT 看不见的**：M3 releaseBufResp_s3_valid_REG 复位值 0→1 ⇒ errors=0 —— 复位后一拍 MainPipe s3 没有任务，
这个 valid 无人消费；复位值归 FM（寄存器复位态是比较点的一部分）。

## 3. FM 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/Slice*.json，merge_dup=false，模型适用）

诊断跑（不出 receipt）沿革：
- diag1（commit 0411ee89，merge 默认，只钉 child 自带 810 位）：Matching 1.6h 到 63% 后每 30 分钟 < 900 点，按规范停。
- diag2（39234527，merge 默认，钉 25262 位）：2.1h 跑完，FAILED failing 15470 / unmatched 1776(2970)。
- diag3（39234527，merge=false）：native SUCCEEDED passing 60373 / failing 0 / unmatched compare 0；unread matched_nc 7796 +
  两侧未配 148/155 —— 收割漏了 child matched.rpt 里 Func/User 方式的配对。
- 7ddbee0f 补全收割（29388 位）后：diag4（Slice，merge=false，vmucp）FAILED failing 432 = Directory 7 块 SRAM 的 rdataReg，
  根因是收割到的 respReg↔rdata_last_REG（Directory 自己 merge=true 时 FM 的配法），impl respReg 被晾成 unmatched；
  diag5（Slice_1，merge=true，vmucp）FAILED failing 1242 / unread 未配 20+20（golden 同方程重复寄存器两侧合法不同）。
  本提交起收割丢弃 rdata_last_REG 那 7 对，口径定为 merge=false。

| 目标 | expected（模型） | passing 预测 | constant_reg 预测 | 其余 |
|---|---|---|---|---|
| Slice   | 69845 | **68305** | 1540 | failing 0 / unverified 0 / aborted 0 / unmatched compare 0(0) |
| Slice_1 | 69848 | = expected − constant_reg | 与 Slice 同量级 | 同上 |
| Slice_2 | 69850 | = expected − constant_reg | 同上 | 同上 |
| Slice_3 | 69851 | = expected − constant_reg | 同上 | 同上 |

（Slice 的 68305 = diag4 passing 67873 + 那 432 个 failing 点；diag4 的 constant_reg = 1540，69845 − 1540 = 68305。）

**预测判定：PARTIAL，不是 SIGNOFF_PASS。** 唯一残差 = 每变体 7 个 impl-only unread（Directory 下 metaArray /
origin_bit_opt / replacer_sram_opt / tagArray×4 的 `u_core/g_nomcp.rdata_last_REG_reg`）：共享核 xs_SRAMTemplate_core 的
非 MCP 形态比 golden 多一个与 respReg 同方程的寄存器，Directory 自己签核时靠 merge=true 合掉；本目标闭包里 merge=true 会在
GrantBuffer / RequestBuffer / CustomL1Hint 处制造两侧不对称（diag5 实测），故不能开。消掉它要改 41 个已签变体共用的核，不在本 lane。
黑盒每变体 = array_14_ext×4 + array_15/16/17_ext + array_18_ext×4 + ram_10x89（两侧对称，verif/allow/Slice*.json）。
