# Golden 冻结清单 (GOLDEN MANIFEST)

> 目的:让 clean clone **可追溯、可复现**地重建与本仓库验证所用**完全一致**的 golden RTL。
> 任何 FM/UT 结果只有在 golden 字节 hash 与 `golden.sha256` 一致时才可复核。

## 1. 生成来源 (frozen)

| 项 | 值 |
|----|----|
| 主仓 (XiangShan) commit | `c8bbd5c6acf879d0df9dcc3974562b54187254db` |
| git describe | `v3.2.2-alpha-812-gc8bbd5c6a` |
| 分支 | kunminghu-v2r2 (V2R2 昆明湖) |
| 生成配置 | `CONFIG=KunminghuV2Config` |
| difftest 开关 | **OFF**(非 difftest 基线;`make sim-verilog` 但 Makefile 内 `--enable-difftest` 已注释) |
| 生成命令 | `make sim-verilog CONFIG=KunminghuV2Config`(经下方 flow patch) |
| golden .sv 文件数 | 1802 |
| golden 组合 hash | `5054bbd50f79f0b8329a2580707933c37624b64503698dc02d84bb1b0aaf9c61`(= `sha256sum golden.sha256`) |

## 2. 子模块 SHA (frozen)

| 子模块 | SHA |
|--------|-----|
| rocket-chip | `bcf2051a45fcd6c4b84a62a679888c2dae75cce4` |
| difftest | `75aae957909975a31605d9f50e65ec26b7ee2a97` |
| huancun | `7c9d4cbb2a6d315c701e81c2acf0a5ab9d9af5e4` |
| coupledL2 | `9c1d363b1899f4314b5a2b6be00fff8e109df06b` |
| openLLC | `e41f5393d30f169ee2f142c429843a0c59062ef6` |
| utility | `8ef84f12393af527dfd1dc073549fa336332eff1` |
| fudian | `e1bd4695ca7beb36a5ce7357e9527ad9e95b9ec1` |
| yunsuan | `cadd3c2f43096e253d61296b33ac697be8354e29` |
| ChiselAIA | `458f94be4c46b62e3c3be034bb18781d2271c129` |
| ready-to-run | `eca506ac0752506269c1540ebe779387df8e8d1e` |

## 3. 工具链 (frozen)

| 工具 | 版本 |
|------|------|
| JDK | Temurin 17.0.13+11 (`/home/eda/xs-env/toolchain/jdk-17.0.13+11`) |
| firtool | 随 mill 依赖拉取(与上述 commit 锁定) |
| VCS / Verdi (UT) | W-2024.09-SP1 |
| Formality (FM) | V-2023.12-SP3 |
| license | 27080@localhost |

## 4. flow patch(生成 golden 时对主仓的必要改动)

golden 在独立 worktree `/home/eda/xs-env/xs-clean`(检出上述 commit)中生成,施加了以下**仅影响生成、不影响设计**的补丁:
- `Makefile`:注释 `DEBUG_ARGS += --enable-difftest`(得到非 difftest 基线,使 Bku 25 端口/LsqWrapper 1609 端口/Rob 无 difftest 观测口,与重写核对标一致)。
- `build.sc`:VcsVersion 容错(避免 worktree 下 `git describe` 失败中止 elaborate)。
- `tools/kunminghu_v2r2_flow.sh`:flow 辅助脚本(patch 目标)。

> 注:当前 `golden/chisel-rtl` 软链指向 `xs-clean/build/rtl`。该 worktree 携带上述 patch(git status 显示 dirty 属预期)。**权威追溯锚是 `golden.sha256` 的字节 hash**,而非 worktree 的 git 干净度。

## 5. 复现步骤

```bash
# 1. 检出主仓到冻结 commit(含子模块 SHA)
git checkout c8bbd5c6acf879d0df9dcc3974562b54187254db
git submodule update --init --recursive   # SHA 见 §2

# 2. 施加 flow patch(§4)后生成非 difftest 基线
export JAVA_HOME=/home/eda/xs-env/toolchain/jdk-17.0.13+11
make sim-verilog CONFIG=KunminghuV2Config

# 3. 字节级核对(必须完全一致才可复核 FM/UT 结果)
cd build/rtl && sha256sum *.sv | sort -k2 | diff - <repo>/verif/freeze/golden.sha256
```

## 6. 证明输入(已入库,保证 FM 结果可复现)

- `scripts/fm_eq.tcl`:标准 FM 等价脚本。
- `scripts/fm_eq_full.tcl`:全貌版(failing 上限调大 + ELAB-147 降级,**降级仅诊断用,签核需逐点核实**)。
- `scripts/fm_rerun_full.sh`:全貌批量驱动。
- `verif/ut/*/fm_pins*.tcl`:各模块 set_user_match 钉点(**均不约束 ref/golden 侧**)。
- `verif/ut/*/fm_eq_bb*.tcl`:黑盒边界 FM(waiver 分支只输出 WAIVED,绝不 SUCCEEDED)。

## 7. 待办(签核前必须闭环,见 fm-signoff-gaps)

golden.sha256 与本 manifest 是"冻结地基"的第一块。仍需:证明分类落地(REPLACEMENT/ASSEMBLY/SHADOW/PARTIAL)、逐对象 blackbox/dont-verify allowlist、同一冻结基线全量(232 目标)重跑 + 机器可读摘要。
