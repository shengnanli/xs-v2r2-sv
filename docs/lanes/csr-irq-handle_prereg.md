# csr-irq-handle lane（agent/csr-irq-handle）—— 跑前登记

本文件在 **FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `7f680ae2`（集成者预建 worktree + claim） |
| 工作树 | `/home/eda/xs-env/wt-csr-irq-handle`，分支 `agent/csr-irq-handle` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | SieModule / SipModule / VSieModule / VSipModule / MvipModule / HvipModule / MvienModule / HvienModule / MStatusModule / TrapHandleModule / PMPEntryHandleModule / PMAEntryHandleModule |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒（12 个 golden 全是 0 子模块叶） |
| UT | `verif/ut/CsrIrqHandle12`（12 对双例化，tb 由 gen.py 生成） |

## 1. 结构

- 中断族 8 个：核按**中断号**操作 64 位向量（`csr_irq_pkg`），wrapper 由
  `scripts/gen_csr_irq_handle.py` 把 golden 逐中断标量端口收拢/展开；golden 没端口的位用
  firtool 折叠掉的常数 tie（mideleg 的 VS/SGEI 位恒 1，其余向量 0）。
  flop 只在 golden 真有寄存器的位上生成（generate 条件掩码），避免 impl 多出常量寄存器。
- MvienModule/HvienModule 共享 `xs_CsrVien_core`；PMP/PMA 共享 `xs_PmEntryHandle_core`。
- MStatusModule / TrapHandleModule 核与 wrapper 手写。

## 2. 跑前预测（★跑完不许改本节★；登记见 docs/fm_predictions/*.json）

模型 = golden 寄存器位 + 顶层 output 位（`fm_predict.py model`，merge_dup=false 适用）。

| 目标 | passing 预测 | 其余 |
|---|---|---|
| SieModule | 178 (52+126) | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| SipModule | 226 (0+226) | 同上 |
| VSieModule | 284 (50+234) | 同上 |
| VSipModule | 223 (0+223) | 同上 |
| MvipModule | 175 (53+122) | 同上 |
| HvipModule | 171 (53+118) | 同上 |
| MvienModule | 168 (52+116) | 同上 |
| HvienModule | 164 (50+114) | 同上 |
| MStatusModule | 181 (21+160) | 同上 |
| TrapHandleModule | 133 (0+133) | 同上 |
| PMPEntryHandleModule | 3584 (1472+2112) | 同上 |
| PMAEntryHandleModule | 3584 (1472+2112) | 同上 |

无 vmucp、无 fm_pins、无 allow/dead_ref 声明。

## 3. 明写可能出错的地方

1. golden 平铺寄存器名（`reg_LC14IE`、`pmpAddr_0_ADDRESS`）vs 重写 generate 内 `g_bit[14].g_flop.q` /
   `g_entry[0].addr_q`：名字配不上，靠签名分析（每个 flop 各自驱动唯一的 output）。
   若出现 unmatched，补 `fm_pins_pre.tcl` 再证，不动 RTL。
2. 常数输出（VSie 的 toSie_*、Sip 的 toMvip_LCOFIP_*、Hvip 的 regOut_LCOFIP、各 rdata 硬零位）
   两侧都应折成常数比较点，计入 passing；若 FM 把 impl 侧某些常量 flop（不该有，核里已按掩码
   不生成）报 constant_reg，差额按 receipt 的 constant_reg 指认。
3. MStatusModule 的 SDT/SIE 规则（DTE=0 时 sstatus 写 SDT 保持且用当前 SDT 判清 SIE）
   是最容易写错的一处；UT 已有 sdt_alias_dte0/dte1 覆盖项。
