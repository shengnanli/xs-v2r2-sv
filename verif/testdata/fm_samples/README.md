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
