# OthersEntry* 18 变体 UT 回归结果（★两档初值都跑，108/108 全绿★）

- 分支 `agent/othersentry2`（`agent/othersentry` 这个名字已被一条已合入 main 的 IBuffer lane 占用）
- 被测 commit：`09163b177a8624c9b55c68c4965ab51b6a5d469b`
- 规模：18 变体 × 3 seed（1 / 7 / 42）× 200000 cycle × **2 档初值** = **108 次，errors 全为 0**
- 两档：
  - `random`   = `make run SEED=<s> NCYCLES=200000`（Makefile 里 `SIM_ARGS += +vcs+initreg+random`，日志 `sim_<s>.log`）
  - `initreg0` = `make run-initreg0 SEED=<s> NCYCLES=200000`（日志 `sim_ir0_<s>.log`）
  ★两档都跑★ —— `agent/entfam` 那条 lane 自曝只跑了 random 一档并把它记成欠账，本 lane 不再欠。
- ★为什么两档都必须跑★：golden 的条目寄存器 `entryReg_*` **不复位**（只有 `validReg` 带复位），
  可读核照抄这个复位域。不开 initreg 时 golden 侧未初始化寄存器是 X，被 tb 的 `$isunknown` 跳过 ——
  「复位域抄对了没有」那件事根本不会被验到。所以编译期开 `+vcs+initreg+random` 打开能力，
  运行期用 `+vcs+initreg+<0|random>` 选初值，两种初值都要过。
- 表里 `checks` / `errors` 由各 UT 目录的 sim 日志里 `checks=<n>, errors=<n>` 那一行**机械读出**，非手抄。
  复算：`python3 docs/lanes/othersentry_ut_extract.py`（非零退出 = 有不合格项）。
- 同一 seed 下 `random` 与 `initreg0` 两行的 `checks` 相同、`errors` 同为 0：
  比对次数与初值无关（tb 的比对条件不看初值），初值只影响未复位寄存器的初态。

| 变体 | 档 | seed1 checks/errors | seed7 checks/errors | seed42 checks/errors |
|---|---|---|---|---|
| `OthersEntry` | random | 58400000 / **0** | 58400000 / **0** | 58400000 / **0** |
| `OthersEntry` | initreg0 | 58400000 / **0** | 58400000 / **0** | 58400000 / **0** |
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
| `OthersEntry_66` | initreg0 | 58198545 / **0** | 58199127 / **0** | 58200000 / **0** |
| `OthersEntry_72` | random | 15399230 / **0** | 15399692 / **0** | 15400000 / **0** |
| `OthersEntry_72` | initreg0 | 15399230 / **0** | 15399692 / **0** | 15400000 / **0** |
| `OthersEntry_88` | random | 56598585 / **0** | 56599151 / **0** | 56599717 / **0** |
| `OthersEntry_88` | initreg0 | 56598585 / **0** | 56599151 / **0** | 56599717 / **0** |
| `OthersEntry_90` | random | 12999935 / **0** | 12999935 / **0** | 12999870 / **0** |
| `OthersEntry_90` | initreg0 | 12999935 / **0** | 12999935 / **0** | 12999870 / **0** |

不合格项：0
