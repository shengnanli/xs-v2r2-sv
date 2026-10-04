# fe-mem-misc / FTB 子任务 —— 跑前登记

本文件在 FTB 正式 FM（`run_proof.sh`）起跑之前提交；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。（与 `fe-mem-misc_prereg.md` 分文件，避免与主 agent 同时编辑。）

## 0. 输入

| 项 | 值 |
|---|---|
| 工作树 / 分支 | `/home/eda/xs-env/wt-fe-mem-misc`，`agent/fe-mem-misc` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/FTB.sv`（3378 行，323 端口，顶层寄存器 3094 位） |
| 重写件 | `rtl/frontend/FTB.sv`：package `ftb_pred_pkg` + 手写核 `xs_FTB_core` + golden 同名 wrapper（`scripts/gen_ftb.py` 生成，`--check`） |
| 口径 | `signoff-strict`，merge_dup = FM 默认（true），vmucp 开，dead_ref 声明 `verif/dead_ref/FTB.json`，allowlist 0，无 dont_verify |

## 1. 结构与子模块处置

- 核按流水分节：§0 BPU 公共外壳（s1/s2/s3 各级 PC，SegmentedAddrNext 分段打拍）/ §1 S0-S1（关闭开关、发 SRAM 读）/
  §2 S1→S2 锁存 / §3 S2 选条目与展开、multi-hit、一致性计数 / §4 S2→S3 锁存与 S3 输出 / §5 更新 / §6 perf。
- 寄存器字段集合逐字照 golden：副本 1..3 的 S2/S3 条目寄存器没有 valid 与 brSlot.sharing（firtool 按读者删），
  重写用去掉这两个字段的 `ftb_entry_lite_t`；死寄存器（update_meta_r 516 位只读 [66:64]、REG/REG_1）照搬。
- 子模块 4 个全部 `PROVEN_DIRECT`，两侧白盒：ref 读 golden，impl 读本仓重写件
  `rtl/frontend/FTBBank.sv`（+ `frontend_common_pkg.sv`）、`rtl/common/DelayN_1.sv` / `DelayNWithValid.sv` /
  `DelayNWithValid_1.sv`（+ `xs_DelayN_core` / `xs_DelayNWithValid_core`）。FTBBank 之下的 SRAM/MBIST 链照
  FTBBank 自己签核时的口径两侧同读 golden；唯一黑盒 = 厂商 SRAM 叶子 `array_1_ext` × 8（两侧对称，vendor_sram_leaf）。
- 子模块在 wrapper 里按 golden 同层同实例名例化（ftbBank / delay2_pc_pipMod / delay2_entry_pipMod / write_valid_delay）。
- 钉点 `verif/ut/FTB/fm_pins_pre.tcl`（gen_ftb.py 生成，fail-closed 计数）：FTB 顶层 3094 位逐位 + delay2_pc_pipMod
  两级 PC 100 位，共 3194 条。

### 为什么 merge_dup 不关（与 lane 规范默认不同，如实记）

lane 内第一次诊断跑（merge_dup=false）native FAILED，failing 恰 3 =
`ftbBank_io_update_write_{way[1:0],alloc}_REG`。根因：已签核的 FTBBank 重写件把 golden 的 4 份恒等寄存器
`u_total_hits_REG{,_1,_2,_3}` 合成了一个 `u_access_d1`；merge_dup=false 时其余 3 份在 ref 侧是未配对的自由变量。
FTBBank 自己签核时就是 merge_dup 默认（true），FTB 沿用同一口径；不改已签核子模块。
后果：`fm_predict` 模型按 merge 带（BOUNDED）判，不是逐位等式；带宽 regs=6178。

## 2. UT（verif/ut/FTB；tb 由 gen.py 生成；9 档 × 200k 拍，commit 26691dff 的 RTL 字节）

双例化 golden FTB vs FTB_xs，逐拍比全部 174 个输出端口（含 MBIST outdata/ack），复位后 1200 拍暖机（盖住 SRAM 上电清零 512 拍）。
激励：64 个 PC 的池（同 4KB 区）；四份 dup 的 fire 多数拍同值、1/16 各自独立；s0_fire[0] 只在 golden s1_ready=1 时给；
uFTB 输入分"一致期"（= golden ftbBank 当拍读出条目/命中，驱动一致性计数涨过 499 触发关闭）与"随机期"；
update 随机 pc/条目/meta，1/8 old_entry，1/64 false_hit；IFU 重定向 1/1024。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=34591200 errors=0 | checks=34591200 errors=0（★seed1×random = 全 1 档★） | checks=34591200 errors=0（1017） |
| 7  | checks=34591200 errors=0 | checks=34591200 errors=0 | checks=34591200 errors=0（7017） |
| 42 | checks=34591200 errors=0 | checks=34591200 errors=0 | checks=34591200 errors=0（42017） |

覆盖（seed 1，200k 拍）：s2_hit 146749、s3_hit 196819、multi_hit_enable 113968、S2 处于关闭态且 fire 28234、
重开 173、update_now 17823、update_need_read 17851、写 bank 31668、S2 fall-through 非法 155960、
一致性计数 > 499 的拍 37822（峰值 511）。

变异自证（scratchpad 副本，seed 1，30k 拍）：

| 变异 | errors |
|---|---|
| M1 关闭阈值 499→498 | 645725 |
| M2 S2 fall-through 进位用 S2 条目而非 stashed carry | **0** |
| M3 S3 命中不看 multi-hit | 2042 |
| M4 副本 d 的 fall-through 合法性用副本 0 的 PC | 4316 |
| M5 meta.writeWay 取 [65:64] | 2031784 |
| M6 s1_ready 不看上一拍读 tag | 1808 |
| M7 br 目标中位进位不换 higher | 70489 |
| M8 重开只看 IFU 重定向 | 910501 |
| M9 S1 读出条目不看关闭 | 159 |
| M10 old_entry 也写 meta | 956 |

**UT 看不见 M2**：stashed carry 与 S2 条目的 carry 只在"副本 d 的 s1_fire 与副本 0 的不同拍、且其间 close 翻转、
且 fall-through 合法"时才不同，tb 的激励几乎造不出来；归 FM 兜底（FM 逐点比 `io_out_s2_full_pred_*_fallThroughAddr`）。

复跑：`cd verif/ut/FTB && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

## 3. 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/FTB.json）

模型 expected = 8825（golden 闭包寄存器位 6178 + 顶层 output 位 2199 + 黑盒输入 pin 448），merge_dup=true ⇒ 带判。

lane 内非正式诊断跑（`make fm-FTB FM_MODE=diagnostic-full`，RTL 同 commit 26691dff 字节，不出 receipt）：

| 跑 | native | passing | failing | unmatched | matched_nc | ref-only unread |
|---|---|---|---|---|---|---|
| vmucp 关 | SUCCEEDED | 8038 | 0 | 0(0) | 567 | 50 |
| vmucp 开 | SUCCEEDED | 8605 | 0 | 0(0) | 0 | 50 |

8605 − 8038 = 567，正好等于 vmucp 关时的 matched_nc 数（standing rule 第 3 条）。567 的构成（两侧逐位一一配对，钉点给出）：
`update_meta_r` 513（516 位只读 [66:64]）+ `delay2_pc_pipMod` 两级 PC 各 21（写 FTB 只用 pc[29:1]）+
`ftbBank/mbistPl` addrReg 10 + addrRdReg 1 + `REG_1`/`s0_fire_hit_perf_r` 1（perf 探针）。

模型差 8825 − 8605 = 220，全部可指认（逐实例对 matched.rpt 数出来）：
- ftbBank 内 203 = dead_ref `req_pc_reg_1` 50 + 与它恒等被合并的 `req_pc_reg{,_2,_3}` 150 + 恒等被合并的 `u_total_hits_REG{,_1,_2}` 3；
- FTB 顶层 17 = `REG`（与 REG_1 恒等被合并）1 + 8 组 `last_stage_pc_{higher,middle}_plus_one[0]`（x+1 与 x−1 的最低位恒等，被并入 minus_one[0]）16。

| 项 | 预测（正式 run_proof） |
|---|---|
| verdict | **PASS_DEAD_REF**（signoff-strict；唯一残余 = golden-only 的 `ftbBank/req_pc_reg_1_reg[0..49]`，与声明精确相等） |
| passing | **8605** |
| failing / unverified / aborted | 0 / 0 / 0 |
| unmatched compare points | 0(0) |
| unread | ref 50 / impl 0 / matched_nc 0 |
| 黑盒 | `array_1_ext` × 8 两侧对称（厂商 SRAM 叶子） |
| dont_verify / elab147 / relaxed appvar | 无 |
| fm_predict check | BOUNDED（220 ≤ unread 50 + regs 6178） |

### 明写可能出错的地方
1. 钉点里 `REG`/`REG_1` 交叉配对依赖 FM merge 选哪一份当代表（诊断跑实测），若正式跑选法变了会出 "Ignoring user match"、
   留一对 unmatched unread（判 PARTIAL，不会假绿）。
2. strict 模式下有对称厂商黑盒：若 verdict 因黑盒判 PARTIAL，按 FTBBank 的先例改 assembly + allow 声明，另行登记，不改本节数字。

## 对账（跑后追加；上面各节数字未改）

正式证明：`PROOF_COMMIT=d37248da1 bash scripts/run_proof.sh FTB FTB < /dev/null`
→ `evidence/d37248da1db4/FTB/`（receipt.json sha256 `4ce1723e948f75cfb9a68632b4f61c80c3ab415cda246dfebff4f2870e91a1cc`）。

| 项 | 预测 | 实测 | 差 |
|---|---|---|---|
| verdict | PASS_DEAD_REF | PASS_DEAD_REF（native SUCCEEDED，signoff-strict） | — |
| passing | 8605 | 8605 | 0 |
| failing / unverified / aborted | 0/0/0 | 0/null/null | 0 |
| unmatched compare points | 0(0) | 0(0) | 0 |
| unread | ref 50 / impl 0 | 50(0)，dead_ref_points=50 精确相等 | 0 |
| 钉点 | 3194 ok / 0 bad | `FTB_PIN_END FTB ok=3194 bad=0`，"Ignoring user match" 0 条 | 0 |
| 黑盒 | array_1_ext ×8 对称 | blackbox_out=0（未配对黑盒输出 0） | — |
| dont_verify / elab147 | 无 | false / false | — |

`python3 scripts/fm_predict.py check FTB` rc=0（BOUNDED：差 220 ≤ unread 50 + regs 6178；
220 的逐项指认见 §3，诊断跑与正式跑 passing 相同）。`scripts/check_lane_receipts.py` rc=0。
