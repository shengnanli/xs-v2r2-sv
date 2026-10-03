# fe-mem-misc / RAS 子任务 —— 跑前登记

本文件在 RAS 正式 FM（`run_proof.sh`）起跑之前提交；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。（与 `fe-mem-misc_prereg.md` 分文件，避免与主 agent 同时编辑。）

## 0. 输入

| 项 | 值 |
|---|---|
| 工作树 / 分支 | `/home/eda/xs-env/wt-fe-mem-misc`，`agent/fe-mem-misc` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/RAS.sv`（1341 行，402 端口，顶层寄存器 833 位，含 RASStack 的闭包寄存器共 3775 位） |
| 重写件 | `rtl/frontend/RAS.sv`：package `ras_pred_pkg` + 手写核 `xs_RAS_core` + golden 同名 wrapper（`scripts/gen_ras.py` 生成，`--check`） |
| UT 目录 | `verif/ut/RASTop`（`verif/ut/RAS` 已被子模块 RASStack 的 UT 占用，不动） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），vmucp 关，无 dead_ref，allowlist 0，无 dont_verify |

## 1. 结构与子模块处置

- 核按功能分节：§1 PC 流水（s1/s2/s3 四份复制，s2/s3 为分段地址寄存器）/ §2 s2 投机 push/pop 与 ret 目标改写 /
  §3 s2→s3 锁存 / §4 s3 再判、cancel、missed push/pop / §5 redirect 回滚（RegNextWithEnable）/ §6 update 提交。
- 唯一子模块 RASStack（`PROVEN_DIRECT`，`verif/ut/RAS`）两侧白盒：ref 读 golden `RASStack.sv`，impl 读重写件
  `rtl/frontend/RASStack.sv`；按 golden 同层同实例名（`RASStack`）例化在 wrapper 里。无黑盒。
- 钉点 `verif/ut/RASTop/fm_pins_pre.tcl`（gen_ras.py 生成，fail-closed 计数）：RAS 顶层 833 位逐位
  （s1/s2/s3 PC 流水 600 + modified_reset 1 + s3 锁存 127 + redirect 81 + update 24；结构体寄存器按 FM 的字段展开名 `x_reg\[字段]\[子字段][位]`）。
  RASStack 内部不钉（它单独签核时也没用钉点，两侧同实例名、同寄存器名）。

## 2. 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/RAS.json）

模型：expected = **6592**（golden 闭包寄存器位 3775 + 顶层 output 位 2817），`FM_MERGE_DUP=false` 模型适用。

lane 内非正式试跑（`make fm-RAS`，工作树 dirty 故拒出 receipt；RTL 字节 = commit 57dd59cc9）：
- 第一次：钉点 56 条被拒（结构体寄存器我按扁平位偏移写了名字，FM 实际按字段展开命名）—— 钉点文件 fail-closed 报错停跑，
  未进入比较。修生成器的命名规则后（只改 `scripts/gen_ras.py` 与生成的钉点文件，RTL 未动）：
- 第二次：native SUCCEEDED，passing 6592 / failing 0 / unmatched 0，unread 0，钉点 833/833 全接受。

| 项 | 预测（正式 run_proof） |
|---|---|
| passing | **6592**（= 模型，差 0） |
| failing / unverified / aborted / unread | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 0 |
| 黑盒 | 无 |
| verdict | SUCCEEDED（signoff-strict） |

## 3. 明写可能出错的地方

1. 分段地址寄存器"段不变就不写"与"每次 fire 都写"在功能上等价（写入值等于原值），重写照 Chisel 的设计意图
   保留了"只在变了时写"（低段照 golden 每次写）；FM 证的是次态函数，两种写法都应等价。
2. RAS 输出里 `last_stage_meta` 516 位只有低 10 位有内容（RASMeta = {ssp, TOSW}），高 506 位恒 0 —— 仍是比较点，
   计在 passing 里（模型已含）。
3. UT 读数在跑完后写进 §对账，本节不写数字。
