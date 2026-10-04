# newcsr-close lane（agent/newcsr-close）—— 跑前登记

本文件各节在**对应目标的 FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `e07b563e`（集成者预建 worktree + claim） |
| 工作树 | `/home/eda/xs-env/wt-newcsr-close`，分支 `agent/newcsr-close` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. 第一批：6 个叶 + CSRPermitModule

### 1.1 现状核查（为什么 5 个已有重写件没有有效 receipt）

VSstatusModule / VSiselectModule / VstartModule / VStimecmpModule / VtypeModule /
VirtualLevelPermitModule 的 rtl 来自 `5ccd73c6 newrtl-next200c: checkpoint recovered readable leaf
implementation`（那条 lane 崩溃后恢复的检查点）。仓里**没有任何 UT Makefile 的 FM_VARIANTS 含这 6 个名字**，
`docs/receipt_harvest.tsv` 也没有它们的行 —— 即从未建 UT、从未跑 FM，不是证过又 stale。
本 lane 新建 `verif/ut/NewcsrLeaves6` 补 UT + FM；RTL 只做两处改动：
VirtualLevelPermitModule 按 Scala 规则名重写成"一条规则一个 wire"（可读性，逻辑不变），
另 5 个只在文件头补 Scala 出处。

CSRPermitModule 之前没有重写件（MISSING），本 lane 新写：汇总逻辑手写，6 个子模块例化
（实例名同 golden、端口直连）。子模块两侧白盒：5 个已签（PROVEN_DIRECT）+ VirtualLevelPermitModule
本批签。

### 1.2 UT

- `verif/ut/NewcsrLeaves6`：6 对双例化，417 位输出逐拍比；9 档（seed 1/7/42 × initreg 0/random/<seed>017）
  各 200k 拍 errors=0；19/19 输出端口有翻转；13 类事件计数全部 >= NCYCLES/400。
  变异 10/10 抓到（VSstatus VS 优先级 / SIE 的 DTE 门控 / vstart 非零才置脏；VSiselect IMSIC 窗口边界；
  Vstart 清零条件；Vtype VILL 复位值；VStimecmp 低位；VLP 的 0x154 空洞 / VU 的 hcounteren / stimecmp wen）。
- `verif/ut/CSRPermitModule`：1 对双例化（各带 6 子模块），9 个 1 位输出逐拍比；9 档各 200k 拍 errors=0；
  9 个输出都取过 0 和 1；EX_II/EX_VI 的"直接"与"仅间接"路径、xRet 路径各 >= NCYCLES/1000。
  变异 5/5 抓到（间接结果的 direct 门控 / II 优先于 VI / direct_illegal 漏 VI / csrAccess 漏 ren / hasLegalWen 漏 VI）。

### 1.3 跑前预测（★跑完不许改本节★；登记见 docs/fm_predictions/*.json）

模型 = golden 寄存器位 + 顶层 output 位（`fm_predict.py model`，merge_dup=false）。

| 目标 | passing 预测 | 其余 |
|---|---|---|
| VSstatusModule | 84 (10+74) | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| VSiselectModule | 91 (13+78) | 同上 |
| VstartModule | 78 (7+71) | 同上 |
| VStimecmpModule | 192 (64+128) | 同上 |
| VtypeModule | 73 (9+64) | 同上 |
| VirtualLevelPermitModule | 2 (0+2) | 同上 |
| CSRPermitModule | 9 (0+9) | 同上（6 子模块两侧白盒，纯组合） |

### 1.4 明写可能出错的地方

1. VSstatus：impl 把 SDT 读出写成 `menvcfg_DTE & henvcfg_DTE & sdt_q`（两处），golden 同式；
   若 FM 把 rdata 里的常量位（38'h100 段，含 UXL=2）与 impl 拼接位序配错，会表现为 rdata 某位 failing。
2. Vtype 的 VILL 复位为 1：若 FM 把 impl 侧常量折叠后报 constant_reg，passing 会少 —— 差额按 receipt 指认。
3. 纯组合目标（VLP、CSRPermit）的 passing 只数输出位；子模块里的逻辑不产生额外比较点。
