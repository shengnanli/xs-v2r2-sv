# xs-v2-sv —— 香山 KunminghuV2 可读 SystemVerilog 重写（第二轮）

把香山 kunminghu-v2 分支（commit b36a1a2a5, 2026-09-09）生成的 firtool RTL
重写成**为学习服务**的可读 SystemVerilog。可读性与正确性是仅有的两个硬指标。

- golden 对照（只读）：`/home/eda/xs-env/G1-canonical/golden-rtl/`
  （SimTop 形态 + difftest，KunminghuV2Config，来源见其 PROVENANCE.md）
- 规范：`CONVENTIONS.md`（单文件规范：一个 golden 模块 = 一个 .sv，
  pkg + xs_<M>_core + golden 同名 wrapper 同文件；禁 svh；验收 = UT 3 种子
  + Formality strict SUCCEEDED）
- 上一轮成果：`/home/eda/xs-env/xs-v2r2-sv/`（对照 G0 基线，306/306 formal
  签核收官）。G1 与 G0 间隔 422 个 commit；逐模块继承前必须 diff 确认未变。

## 目录
- `rtl/<subsys>/` 重写源（frontend/backend/memblock/l2/uncore/xstile…）
- `rtl/common/` 跨子系统共享辅助件（xs_ 前缀、无 wrapper，如 xs_PlruReplacer）
- `verif/ut/<Module>/` 每目标 UT（VCS 双例化）+ FM（`make run SEED=…` / `make fm`）
- `scripts/` 公共 harness：ut_common.mk / derive_ut_impl.py / fm_eq.tcl / fm_verdict.py

## G0↔G1 delta（306 目标分类，`scripts/g0g1_delta.py` → `docs/g0g1_delta.tsv`）
| 类 | 数 | 含义 |
|---|---|---|
| INHERIT | 76 | 自身+例化闭包逐字一致 → 上轮重写整体继承（快车道） |
| GLUE_INHERIT | 4 | 自身一致、子树有变 → 本体继承，先处理变化的子目标 |
| TRIVIAL | 11 | 仅断言 .scala 行号漂移 → 等同继承 |
| REWRITE_S / M / L | 43 / 55 / 101 | diff <50 / <500 / ≥500 行 → 对照 G1 改造或真重写 |
| RESTRUCTURED | 16 | G1 无同名文件；其中 5 个纯重编号（见 `docs/g0g1_renames.tsv`），11 个真变（CLINT 整体消失） |

另有 6 个 REWRITE_L 实为纯重编号（DataModule__16entry_8/12/16 等，见 renames.tsv）。

## 进度台账
| 目标 | UT (seed 1/7/42) | FM (signoff-strict) | 备注 |
|---|---|---|---|
| WrBypass 家族 ×5（base/_32/_33/_41/_43） | 25 万比对 ×3 seed, errors=0 | 5/5 SUCCEEDED (124/158/398/50/54 点, 全零) | 与 G0 逐字一致，继承上轮核，重组为单文件定式 |
| IndexableCAMTemplate（base wrapper 已写） | 随 WrBypass 覆盖 | 待独立 target（变体 _32/_33/_41/_43 wrapper 未写） | |
