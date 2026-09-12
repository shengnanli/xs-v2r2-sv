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

## 进度台账（权威口径：`docs/ledger_normalized.tsv` + `docs/g1_universe.tsv`）

> **一切状态均为 `WORKING_*`（功能候选），不是签核结论**。晋升须绑定
> G1 canonical ID + golden closure hash + impl commit + proof config，
> 且 G0 的 receipt/allow/dead-ref/vmucp 一律不继承（codex 0139 §2/§5）。

主 universe = 上轮 306 目标解析到 G1（同名 290 / 人工核对重编号 5 / G1 已消失 7），
与本轮多覆盖的 AUX 变体分栏，机器对账 + 守恒检查见 `scripts/g1_universe.py`。

| 分栏 | 通过 | 分母 | 说明 |
|---|---|---|---|
| MAIN | 112 | 306 | 36.6%；含 5 个 WORKING_PASS_DEAD_REF |
| AUX | 22 | 31 | G1 新增 SRAM 变体，老战役未覆盖 |

MAIN 其余：`NOT_STARTED` 157、`REWRITE_TODO` 32（G1 真改逻辑/依赖链，机械继承已验证不适用）、
`MERGED` 2、`DEFER_*` 2、`SPECIAL` 1。
G1 已消失 7 个需人工定位去向（CLINT / FastArbiter_44 / FastArbiter_47 / L1FlagMetaArray_1 /
PMPChecker_10 / NewPipelineConnectPipe_32 / SRAMTemplate_66），不允许自动改判。

## 证明基础设施（codex 0139 minimal rebase）

- **G1 canonical**：`G1-canonical/MANIFEST.tsv`（2062 文件逐文件 sha256）+ `CANONICAL_ID.txt`
  + `TOOLCHAIN.tsv`（firtool 1.62.1 / chisel 6.7.0 / JDK17 / mill 0.12.3 / 源码 commit + 子模块 gitlink），
  可用 `find|sha256sum` 独立复算。
- **sidecar native facts**：每次 proof 落 `fm_work/<top>/sidecar/native_facts.json`
  （native verdict / stats / unmatched 六元组 / 黑盒对象集 / appvar readback）+ 脚本字节快照。
- **receipt**：`fm_work/<top>/receipt.json` 绑定 canonical ID、golden 逐文件闭包、
  impl commit 与 dirty 状态、proof config（mode / pin hash / 声明 hash / appvar readback）、rc；
  native 事实与 log 判定不一致即拒绝出 receipt。
- **assembly 精确集合**（取代数字配额）：观测黑盒集合须与 `verif/allow/<top>.json`
  逐对象逐路径精确相等；类别三分 `vendor_macro` / `green_child`（须 child 目标在台账确为通过）/
  `golden_logic_reuse`（NO-GO）。对称性按设计名实例条数校验（可读核用 generate 数组，
  实例名本应与 golden 展平副本不同）。负测 7 例全部 fail-closed。
- **PASS_DEAD_REF**：唯一残余是 golden 侧 cone-dead 未读点，且观测集合与
  `verif/dead_ref/<top>.json` 精确相等；负测 4 例全部 fail-closed。
- **三个 canary**（受 receipt 绑定）：WrBypass strict-clean SUCCEEDED 124p；
  SRAMTemplate assembly SUCCEEDED 394p（1 对 vendor 宏黑盒）；
  TageTable PASS_DEAD_REF 797p + 48 条声明死 ref。全部 rc=0、六元组除声明项外全零。

