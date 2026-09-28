# DCache MainPipe lane（agent/dmainpipe）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `975b64e6`（main，`git worktree add /home/eda/xs-env/wt-dmainpipe -b agent/dmainpipe 975b64e6`） |
| 工作树 | `/home/eda/xs-env/wt-dmainpipe`，分支 `agent/dmainpipe` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `Arbiter4_MainPipeReq`（先做）/ `MainPipe`（DCache 主流水；不是 L2 的 MainPipe_1/_5） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

## 1. Arbiter4_MainPipeReq（golden 218 行 / 60 端口，纯组合）

### 1.1 核与 golden 差异点

- 重写件 `rtl/memblock/Arbiter4_MainPipeReq.sv` = 薄文件，设参例化本仓已签核的共享核
  `rtl/frontend/xs_FixedPriorityArbiter_core.sv`（**未改动共享核**，Arbiter2/5/ICacheMainPipe
  等既有证据不受影响）。WIDTH=982，NUM_IN=4。
- 每路载荷用本地 packed struct `main_pipe_req_t` 按字段填：有端口用端口，无端口填 golden 输出
  三元链里读出来的常量（probe 路 probe=1；refill 路 miss=1；store 路 source=1/cmd=1；
  atomic 路 source=2/id=0；其余清零）。
- golden 无 `io_in_2_ready`（store 路 ready 在 MainPipe 里另算，被 DCE）；核的 in_ready[1] 悬空。
  核的端口数恒等式以 `60 + 1(DCE)` 传入。

### 1.2 UT（verif/ut/Arbiter4_MainPipeReq，gen.py 生成 tb；两档 × 3 seed × 200k）

seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`} 6/6 `checks=200000 errors=0 cov_fail=0` TEST PASSED。
覆盖（seed 1）：probe 胜 50108 / refill 胜 34220 / store 胜 25680 / atomic 胜 20925 /
无人请求 69067 / out_ready=0 99796；每个输出位见过 0 与 1。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/Arbiter4_MainPipeReq.json）

| 项 | 预测 |
|---|---|
| passing | **正好 986**（模型 = 0 寄存器 + 986 输出位 = 982 载荷 + out_valid + 3 根 in_ready） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0 |
| 黑盒 | 无 |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / false（无寄存器，无 unread） |

可能出错：无寄存器、纯组合，唯一风险是某路常量抄错 —— 那会是 failing 而不是计数偏差
（UT 已在 4 路各 2 万次以上胜出上逐位比过全部输出）。

## 2. MainPipe（DCache 主流水，golden 3,317 行 / 451 端口；★非 L2 的 MainPipe_1/_5★）

### 2.1 核与 golden 差异点

- `rtl/memblock/MainPipe.sv`（2,801 行，`_GEN_`/`_T_` 0）：mainpipe_pkg（常量、ClientMetadata 三张表、
  tag SECDED 译码、级间 struct）+ xs_MainPipe_core（§0 恒定握手 / §1 s0 / §2 s1 / §3 s2 / §4 s3 /
  §5 旁路信息 / §6 24 份 status_dup / §7 perf / §8 仿真检查寄存器）+ wrapper。
  io 类型 / 核端口表 / wrapper 由 `verif/ut/MainPipe/gen_mainpipe.py` 从 G1 端口表生成
  （三道机械核对：名字集合相等、方向位宽逐个相等、一对一），`--check` 幂等。
- 子模块白盒：`Arbiter4_MainPipeReq`（本 lane §1）、`AMOALU`（已签核）；FM ref 侧用 golden 的这两个文件。
- 本配置常量折叠照 golden：meta/data/tag 写 ready 恒 1、refill miss_dirty 恒 0、StoreWaitThreshold=0
  （storeWaitCycles 计数器整删）、无 replace 源（s0 replace 恒 0，但 s1/s2/s3 的 replace 寄存器与
  24 份 dup 的 replace 寄存器照留）。golden 的寄存器字段集合逐级照抄（s2 无 occupy_way/evict_btot、
  s3 无 store_data/mask）；5 份 RegNext(s0_fire) 各自一份；死寄存器（断言打拍 5 个、debug SC 两个、
  replace_way.set.valid 打拍、extra_meta 保持里的 prefetch/access、错误地址低 6 位）全部保留。
- lane 内 diagnostic-full 试跑（dirty，未出 receipt）两次：
  1. 无钉点/无 vmucp：native SUCCEEDED passing 8955 / failing 0 / unmatched compare 0(0) / unread 65 matched_nc
     + `16(16) Unmatched unread`（名字不同的同一批死寄存器）/ Constant reg 1 / 无黑盒。
  2. 加 `fm_pins_pre.tcl`（16 对逐项写死，`MP_PREPIN_END n=16`）+ vmucp（`verif/fm_target_config/MainPipe.tcl`）：
     passing **9036** / failing 0 / unmatched 全 0 / unread 0 / Constant reg 1。

### 2.2 UT（verif/ut/MainPipe；两档 × 3 seed × 200k，seed 串行）

seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`} 6/6 `checks=200000 errors=0 cov_fail=0` TEST PASSED。
比较全部 363 个输出端口；+random 下两侧未复位寄存器初值确实不同（探针：impl lrsc_addr=4340fc1ae2f8 /
golden bd16cb285296），由 tb 的确定性暖机（refill LR + refill AMOADD）+ 400 拍随机暖机写定后才开比较窗口。
tb 分辨力自测（变异后 20k 拍）：lrsc_valid `>`→`>=` errors=32；dup[5] s3 valid 强置 errors=4874；
CAS.Q 高半选择改成 CAS.D —— 初版激励 errors=0（CAS 从不成功），加"读出数据三成拍全 0"后抓到。
覆盖（seed 1 / initreg 0，全部 ≥ COV_MIN=100）：s0 fire probe 9166 / refill 9901 / store 3316 / atomic 1227；
store set 冲突 17167；store hit 应答 17678 / replay 4021；miss_req store 13192 / amo 2695 / BtoT 6756 / cancel 509；
atomic 完成 8093 / replay 872 / ack_miss_queue 3505；LR 置保留集 1676；SC 发射 213；CAS 发射 215；AMOALU 类 498；
refill 写 tag 9411 / refill 回 MQ 5126 / 替换被挡 272；wb Release 2515 / ProbeAck 10974 / 带数据 6344；
meta 写 21007；data 写 25882（AMO 部分写 1916）；ECC 上报 3314；error 标志写 9686；bloom set 1366 / clr 7186；
SMS evict 11476；错误注入 tag 51815 / data 22439；access 标志写 28597；替换更新 29986。
replace 请求源：本配置 MainPipe 没有 replace 输入（仲裁器无此路），不可覆盖（N/A）。

### 2.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/MainPipe.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **9037**（golden 寄存器 4860 + 输出 4177）；实测预计 **9036**，差 1 由 receipt `constant_reg`=1 指认 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`MP_PREPIN_END MainPipe n=16 expect=16`） |
| 黑盒 | 无（Arbiter4_MainPipeReq / AMOALU 两侧白盒） |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |

可能出错：run_proof 在 detached worktree 里跑，若钉点叶名格式与试跑不同，钉点脚本会 `error` 早退
（表现为 FM 早退，不是数字小偏离）。

---

# 对账（跑完追加；上文各节未改一字）

## A. Arbiter4_MainPipeReq

| 项 | 值 |
|---|---|
| proof commit | `5c140d96a3fb`（`git rev-parse 5c140d96`；预测登记在同一 commit，早于证明） |
| 证据 | `evidence/5c140d96a3fb/Arbiter4_MainPipeReq/receipt.json` sha256 `f4b728be7ce323960e6e6d8e6fc2e33955f3b2327d2a254a596d97865508ec5c` |
| impl_closure | `rtl/memblock/Arbiter4_MainPipeReq.sv` `8a3c7ce1ce7d418bf72fb7402ef166672a76d5a4dd1a2cc549617acf72a85d88`；`rtl/frontend/xs_FixedPriorityArbiter_core.sv` `e7c8526c…a5618`（未改） |
| 结果 | native SUCCEEDED，passing **986** / failing 0 / unverified 0 / aborted 0 / unread_notcompared 0 / unmatched 六项 0 / 无黑盒 / signoff-strict / dirty false / fm.log 行首 `Error:` 0 |
| `fm_predict.py check` | 预期 986，实测 986，差 0，「全部对上」 |

复跑：`cd /home/eda/xs-env/wt-dmainpipe && PROOF_COMMIT=5c140d96 bash scripts/run_proof.sh Arbiter4_MainPipeReq Arbiter4_MainPipeReq < /dev/null`
