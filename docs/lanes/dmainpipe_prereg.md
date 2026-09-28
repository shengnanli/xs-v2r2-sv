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
