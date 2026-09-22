# SSIT 重验 lane（agent/ssit2）—— 跑前登记

本文件在 **FM 起跑之前**提交。跑完在同一文件末尾追加「对账」一节，
★不修改本节任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `9b6f73cb` (main，完整 hash 见对账节) |
| 工作树 | `/home/eda/xs-env/wt-ssit2`，分支 `agent/ssit2` |
| 目标 | `SSIT`（golden 35,104 行；重写核 `rtl/backend/SSIT.sv`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |

## 1. 失效原因的逐文件指认（这一步先于任何重跑）

`docs/receipt_harvest.tsv` 第 452 行判 SSIT 为 `NEEDS_RERUN`，
选中的权威 receipt 是 `wt-ssit:2382bd685523`，备选 `wt-agedet:82fe3881c4d9`。
逐文件核对 **当前 main 字节**：

### 1.1 `rtl/backend/SSIT.sv` —— ★main 里从来没被动过★

```
当前工作树           d88d85b2163f8c6622a36e1f820b638b30f3d617699005cf1b8f66e86dcc1854
git show e92ef0c4:   d88d85b2163f8c6622a36e1f820b638b30f3d617699005cf1b8f66e86dcc1854   (唯一一次提交)
git log -- rtl/backend/SSIT.sv  ->  只有 e92ef0c4 一条
```

- receipt A（`evidence/82fe3881c4d9/SSIT`，已跟踪进库）记的 impl sha =
  `d88d85b2...`，**与当前字节逐字节相同**。
- receipt B（`wt-ssit` lane worktree 内，run `2382bd685523`，impl_commit
  `2382bd6855237d200ab933e00f73522c21c48501`）记的 impl sha =
  `08e63264cc387cedb55c55f1efa93eeff929debbca1a3f28471c680992c7cddc`。
  这份字节**只存在于 wt-ssit 那条 lane 的工作树里，从未并进 main**。

⇒ 结论：`chk_impl=DIFFER` 的 `why` 里那句「main 里字节已变: rtl/backend/SSIT.sv」
   **是相对被选中的 receipt B 说的，不是 main 有人改了 SSIT.sv**。
   按本 lane 的口径回答「共享件被动了，还是它自己被改了」：
   ★SSIT 自己的实现文件谁也没动★。

### 1.2 `verif/ut/SSIT/fm_pins.tcl` —— ★共享件被别的 lane 动了（真差异）★

```
e92ef0c4  805b68d1ecc4853bfaafada3b0e30c92ffc19088a46a44386ee93b7f889ef074
82fe3881  d2d35662daa142eede7d4aa2af930f35d66b00cc23d636fa6a432fbc38492dba  <- receipt A 记的
（wt-ssit  3dd65e3e5c83492d377eae6b9af0d1338d572275bcf98af932d2f1cbb93c4e88  <- receipt B 记的，lane 内）
cdd922a5  c6e360fdb0d447c451e77e4f39090258821233b3aad6efb912c659869e7d0a71
HEAD      c6e360fdb0d447c451e77e4f39090258821233b3aad6efb912c659869e7d0a71  <- 当前
```

改它的是 **`cdd922a505606fb37d4c840d5059c2253dc72e1f`**
（eda，2026-09-20，「钉点守卫还债 2/2：5 个动态钉点文件补 fail-closed」），
一次性动了 5 个动态钉点文件（NCBTransactionQueue / RenameBuffer / SSIT /
TLBFA / TLBNonBlock）。对 SSIT 的改动是加 4 道 fail-closed 判据
（每次 `set_user_match` 必须返回 1 / miss==0 / ref 侧未匹配未读点总数==期望 /
配对数==字面整数 91），并把 `exit` 换成 `error`。
`docs/pin_guard_dyn_proof.tsv:12` 记该文件 old/new 调用序列
`80b225deb5231f7a` 逐字节 **SAME / GUARD_ONLY**。

⇒ 这一项是**真的共享件变更**，也是 SSIT 这份 receipt 前提失效的唯一实质来源。

### 1.3 其余闭包项

- golden 4 个叶子 + `golden-rtl/SSIT.sv`：5 个 sha256 与 receipt A 记录**全部相同**
  （G1-canonical 现字节已核）。
- `chk_fm_eq`：收录表判 `trace_equal`（`scripts/fm_eq.tcl` 经
  `ac12dddb` 拆成 per-target `verif/fm_target_config/SSIT.tcl`，调用序列等价）。
- `chk_decl` = `none`（SSIT 无 allow/dead_ref 声明），`chk_tool` = `same`。

**一句话**：SSIT 失效 **不是它自己被改**，是它闭包里的共享钉点脚本被
`cdd922a5` 这条还债 lane 改了，外加收录表把一份从未并库的 lane-local
receipt 选成了权威。所以本轮要做的就是**在当前字节上原地重证**。

## 2. 跑前预测（★跑完不许改本节★）

依据 commit：`82fe3881c4d9`（receipt A，impl 字节与今天完全相同）与
`2382bd685523`（receipt B，impl 字节不同但结构相同），两份独立 run **都是
passing 14525 / failing 0**。今天的 impl 字节 == receipt A 的字节；
闭包里唯一变的是钉点脚本，而它被证明是 GUARD_ONLY（调用序列不变）。

| 读数 | 预测 | 依据 |
|---|---|---|
| `passing` | **正好 14525**（主预测）；退让区间 `[14525, 14525]`，落在 `[14400,14650]` 之外记为预测失败 | impl 字节与 receipt A 相同 + 钉点 GUARD_ONLY；14525 的构成在 `verif/ut/SSIT/Makefile` 里已逐项拆过（SSIT 本体 7260 + data_array 6197 + valid_array 1068） |
| `failing` | 0 | 同上 |
| `unverified` / `aborted` | 0 / 0 | 同上 |
| `unread_notcompared` | 0 | vmucp=true 把 14525 个 unread 点全部转成比较点 |
| `unmatched` 六项 | 全 0 | 14434 对自动配 + 91 对钉点 |
| 钉点数 | 正好 91，`SSIT_PIN` 区间 `Error:` 行数 0 | 新守卫会在 !=91 时 `error` 中止 |
| `mode` / `verdict` | `signoff-strict` / `SUCCEEDED` | |
| UT | 3 seed × 200k × 两档 initreg（random / 0），`errors=0` | |

**明写可能出错的地方**（省得事后找补）：
1. 新钉点守卫可能因 FM 版本 / `report_unmatched_points` 输出格式差异直接 `error`
   中止 —— 那会表现为 FM 早退，不是 14525 变小。
2. `fm_eq.tcl` 拆分（`ac12dddb`）后 `verif/fm_target_config/SSIT.tcl` 若丢了
   vmucp 白名单里的 `SSIT`，会退回 `FM-334 no compare points`，passing = 0
   —— 这是**断崖式**的，不会是"小幅偏离"。
3. 若 elaborate 都过不去，按 codex 0170 第 4 条**先修 wrapper/API 一致性再重跑**，
   ★不沿用旧 receipt★。

## 3. 口径约束（自缚）

- `failing == FM_FAILING_LIMIT`（默认 20）时只写「至少 N 个失败，计数被截断」，
  **不把 passing/unverified 当完整规模**。
- 诊断跑（`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`）的日志**不用来出 receipt**。
- 跑证明期间不动被证明的文件；认 `impl_closure[0].sha256`。
