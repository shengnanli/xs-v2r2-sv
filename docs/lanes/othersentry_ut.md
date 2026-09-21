# OthersEntry* 18 变体 UT 回归结果（★两档初值都跑★）

- 分支 `agent/othersentry2`（`agent/othersentry` 这个名字已被一条已合入 main 的 IBuffer lane 占用）
- 被测 commit：`09163b177a8624c9b55c68c4965ab51b6a5d469b`
- 规模：18 变体 × 3 seed（1 / 7 / 42）× 200000 cycle × **2 档初值** = 108 次
- 两档：
  - `random`   = `make run SEED=<s> NCYCLES=200000`（Makefile 里 `SIM_ARGS += +vcs+initreg+random`，日志 `sim_<s>.log`）
  - `initreg0` = `make run-initreg0 SEED=<s> NCYCLES=200000`（日志 `sim_ir0_<s>.log`）
  ★两档都跑★ —— `agent/entfam` 那条 lane 自曝只跑了 random 一档并把它记成欠账，本 lane 不再欠。
- 表里的 `checks` / `errors` 由 `verif/ut/OthersEntry_common/../..`
  下的 sim 日志里 `checks=<n>, errors=<n>` 那一行**机械读出**，非手抄；
  复算：`python3 docs/lanes/othersentry_ut_extract.py`（见同目录）。
- `MISSING` = 该次还没跑到（本文件是**分批提交**的中间结果，跑完会刷新）。

| 变体 | 档 | seed1 checks/errors | seed7 checks/errors | seed42 checks/errors |
|---|---|---|---|---|
| `OthersEntry` | random | MISSING | MISSING | MISSING |
| `OthersEntry` | initreg0 | MISSING | MISSING | MISSING |
| `OthersEntry_104` | random | 55399723 / **0** | 55398615 / **0** | 55399723 / **0** |
| `OthersEntry_104` | initreg0 | 55399723 / **0** | 55398615 / **0** | 55399723 / **0** |
| `OthersEntry_106` | random | 12199817 / **0** | 12199878 / **0** | 12199939 / **0** |
| `OthersEntry_106` | initreg0 | 12199817 / **0** | 12199878 / **0** | 12199939 / **0** |
| `OthersEntry_120` | random | 54799726 / **0** | 54800000 / **0** | 54799452 / **0** |
| `OthersEntry_120` | initreg0 | 54799726 / **0** | 54800000 / **0** | 54799452 / **0** |
| `OthersEntry_122` | random | 11799941 / **0** | 11799764 / **0** | 11799941 / **0** |
| `OthersEntry_122` | initreg0 | 11799941 / **0** | 11799764 / **0** | 11799941 / **0** |
| `OthersEntry_136` | random | 66400000 / **0** | 66400000 / **0** | 66400000 / **0** |
| `OthersEntry_136` | initreg0 | 66400000 / **0** | 66400000 / **0** | 66400000 / **0** |
| `OthersEntry_138` | random | 19800000 / **0** | 19799901 / **0** | 19799703 / **0** |
| `OthersEntry_138` | initreg0 | 19800000 / **0** | 19799901 / **0** | 19799703 / **0** |
| `OthersEntry_150` | random | 63600000 / **0** | 63600000 / **0** | 63599682 / **0** |
| `OthersEntry_150` | initreg0 | 63600000 / **0** | 63600000 / **0** | 63599682 / **0** |
| `OthersEntry_152` | random | 18199818 / **0** | 18199909 / **0** | 18199818 / **0** |
| `OthersEntry_152` | initreg0 | 18199818 / **0** | 18199909 / **0** | 18199818 / **0** |
| `OthersEntry_164` | random | 62799372 / **0** | 62800000 / **0** | 62799058 / **0** |
| `OthersEntry_164` | initreg0 | 62799372 / **0** | 62800000 / **0** | 62799058 / **0** |
| `OthersEntry_166` | random | 17599912 / **0** | 17600000 / **0** | 17599736 / **0** |
| `OthersEntry_166` | initreg0 | 17599912 / **0** | 17600000 / **0** | 17599736 / **0** |
| `OthersEntry_44` | random | 61000000 / **0** | 61000000 / **0** | 60999695 / **0** |
| `OthersEntry_44` | initreg0 | 61000000 / **0** | 61000000 / **0** | 60999695 / **0** |
| `OthersEntry_50` | random | 17599560 / **0** | 17599912 / **0** | 17600000 / **0** |
| `OthersEntry_50` | initreg0 | 17599560 / **0** | 17599912 / **0** | 17600000 / **0** |
| `OthersEntry_6` | random | 15399846 / **0** | 15399769 / **0** | 15400000 / **0** |
| `OthersEntry_6` | initreg0 | 15399846 / **0** | 15399769 / **0** | 15400000 / **0** |
| `OthersEntry_66` | random | 58198545 / **0** | 58199127 / **0** | 58200000 / **0** |
| `OthersEntry_66` | initreg0 | 58198545 / **0** | NO-PASS | MISSING |
| `OthersEntry_72` | random | 15399230 / **0** | 15399692 / **0** | 15400000 / **0** |
| `OthersEntry_72` | initreg0 | 15399230 / **0** | 15399692 / **0** | 15400000 / **0** |
| `OthersEntry_88` | random | MISSING | MISSING | MISSING |
| `OthersEntry_88` | initreg0 | MISSING | MISSING | MISSING |
| `OthersEntry_90` | random | MISSING | MISSING | MISSING |
| `OthersEntry_90` | initreg0 | MISSING | MISSING | MISSING |

不合格项：20
