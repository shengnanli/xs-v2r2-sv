# FM 日志样本（跟踪进版本库，供复核）

这些不是「跑出来就留着」的产物，是**被引用来支撑结论的证据**。放进版本库是因为
`evidence/` 被 gitignore，干净 clone 里拿不到，而 D62 要求「影响裁定的数字必须
附可复跑命令 + 输入路径/commit + 输出 artifact hash」——hash 指向一个取不到的
文件等于没给。

| 文件 | 来自 | 支撑的结论 |
|---|---|---|
| `Predictor_82503e5_mergedup_off_fm.log` | `82503e5`，`FM_MERGE_DUP=false`，`scripts/run_proof.sh Predictor Predictor` | Matching 阶段不终止（见 `docs/predictor_fm_scaling_wall.md`） |
| `Predictor_82503e5_matching_progress.txt` | 同上，从该 log 抽出的三个进度采样 | 速率 146.5 → 0.950 → 0.021 点/秒 |
| `Predictor_914ab81_mergedup_on_fm.log` | `914ab81`，merge_dup 默认 true | 合并阶段会跑完，慢约 7 倍（见 `verif/ut/Predictor/Makefile` 注释） |
| `Predictor_da93a13_ghvpins_fm.log` | `da93a13`（= `021f2e3` + GHV 钉点），`FM_MERGE_DUP=false`，同一条 runner 命令 | GHV 钉点 canary：钉满 256/256 后**仍然不收敛**（见 `docs/predictor_fm_scaling_wall.md` 的 canary 一节） |
| `Predictor_da93a13_ghvpins_matching_progress.txt` | 同上，从该 log 抽出的三个进度采样 | 速率 0.0079 / 0.0716 点/秒，窗口整体 0.0423 点/秒 |
| `Predictor_bfd1afc_unread0_fm.log` | `bfd1afc`，`scripts/run_proof.sh Predictor Predictor`（run_id `Predictor-20260918T105307Z-bfd1afc`） | 685 个 unread 点收口后的**终局**：`Verification SUCCEEDED`、Matching Results 里 `Unmatched ... unread points` 那一行整行消失、`0(0) Unmatched ... compare points`、`PREDICTOR_PINS: 2711 / 2711 pinned`（见 `verif/ut/Predictor/Makefile` 的判据对账） |
| `Predictor_bfd1afc_unread0_receipt.json` | 同上 | 官方 verdict `SUCCEEDED`（上一轮是 `PARTIAL`/`strict_unread!=0`）；native_facts: passing 528967 / failing 0 / unread_notcompared 0，unmatched 六项全 0；dirty False |
| `Predictor_bfd1afc_unread0_unmatched.rpt` | 同上 | 全文只有一行 `No unmatched points.` |

★2026-09-15 更正★：上面那句「支撑的结论」原写的是「Matching 阶段不终止」，**那是错的**，
成因是把 Formality 的匹配进度条（`NNNM/NNN (49% Matched)`）当成线性进度 —— 它的分母
约是配对数的两倍，**按构造到不了 100%**，配完时正好停在 49% 附近。详见
`docs/predictor_fm_scaling_wall.md`。

实际情况：`Predictor_da93a13_ghvpins_fm.log` **完成了匹配**并打出 Matching Results
（520,500 点配上 / 134(6) 未配比较点 / 1113(1826) 未配 unread 点），随后进入
`Status: Verifying...` 才被按 PID 停掉。另两份是在 Matching 中途被停的快照 ——
那是**我们提前杀早了**，不是「跑不完」。

判断匹配走没走完，只看 `**** Matching Results ****` 段头在不在，不要看进度条。

抽进度采样：
```
tr '\r' '\n' < <fm.log> | grep -E "Matched\)"
```


## bfd1afc 那一轮的 sha256（完整 64 位，对着上表的文件核）

```
35d4c44f407e209c9b37460893da6a4da6dd2894f48e3017ae5c91c430b0596c  Predictor_bfd1afc_unread0_fm.log
abb3e3b4332bccf5fbff65a59de1d50aa835cafa6a8eefbf4afb44afb4a97702  Predictor_bfd1afc_unread0_receipt.json
8d3a8aafa355be82a8c3c4d69314700f1b7c26007986126b8be20939a911f24d  Predictor_bfd1afc_unread0_unmatched.rpt
```

同一轮还有一个 **0 字节**的 `unread_points.txt`（sha256
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`，即空文件的
sha256）。它没跟踪进来 —— 一个空文件带不进任何信息，而"unread 归零"这件事在上面
两份里各有一条独立记录：fm.log 里那行 `Unmatched ... unread points` 整行不存在，
receipt.json 的 native_facts 里 `unread_ref` / `unread_impl` / `unread_notcompared`
都是 0。

★读 fm.log 时的坑★：fm_shell 会把入口 Tcl **逐行回显**进 fm.log，
`scripts/fm_eq.tcl` 里有一行源码就是 `puts "FM_RESULT: Verification SUCCEEDED ..."`。
所以 `grep "Verification SUCCEEDED"` 在 verify 刚开始时就会命中。判据要行首锚定：
`grep -E "^FM_RESULT:"` 或 `grep -E "^Verification "`。
