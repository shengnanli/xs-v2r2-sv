# FM 签核证明契约(2026-07)

> 回应 2026-07-18 二审(P0 假绿灯)。定义**唯一 fail-closed 判定**与**证明模式隔离**,
> 使"SUCCEEDED"具备工程签核意义。配套 `fm_targets.tsv`(306 项权威底账)、
> `fm_verdict.py`(fail-closed 解析器)、`test_fm_verdict.py`(负向测试)。

## 背景:为什么需要契约

旧 sweep 用未锚定 `grep "Verification SUCCEEDED"`——Formality **回显整个 Tcl 脚本**(含未执行分支的
`puts "...SUCCEEDED..."`),真 FAILED 也被判绿。实证 ≥9 个假绿(Backend/DCache/NewCSR/…),
`fm_sweep.tsv`/`fm_ledger.tsv` 已作废(`.INVALID`)。

## 一、签核规模(权威底账)

`fm_targets.tsv` 由 `fm_enumerate.sh` 用 **make 变量展开**(注入 `__pv` 打印目标)枚举,
而非按目录 glob(那样漏 SRAM/Pipeline/SyncDataModule 的 49 个多变体 → 错误的 228)。
**306 项** = 302 variant + 3 fmbb + 1 custom。每项 = (UT 目录, Makefile, variant, kind)。

## 二、证明模式隔离(诊断能力**永不**进签核)

| 模式 | 允许 | verdict 上限 |
|------|------|--------------|
| **signoff-strict** | 无 ELAB 降级、无全局 unresolved 黑盒、无未声明 dont-verify/unread/unmatched | 可 SUCCEEDED(须全部数字闸门=0) |
| **assembly** | 仅 manifest 显式列出的**对称黑盒**(interface-only 子模块);本层证 glue | 可 SUCCEEDED(failing=0),但语义是"仅 glue 等价",须叠加子模块各自 REPLACEMENT |
| **diagnostic-full** | 放宽 failing 上限、ELAB-147 降级、诊断钉点 | **永不** SUCCEEDED/signoff——只产 failing 全貌供修复 |
| **shadow** | 可读核不驱动输出 | **只能** SHADOW_CHECK |

> `fm_eq_full.tcl`(ELAB 降级 + 放宽上限)= **diagnostic-full 专用**,其结果绝不作签核。

## 三、fail-closed 判定(`fm_verdict.py`)

SUCCEEDED 的**全部**必要条件(缺一即非 SUCCEEDED):
1. `make rc == 0`;
2. fresh 日志里**恰好一个**行首锚定 `^FM_RESULT: Verification ...`(多个=拼接历史/多variant=ERROR;缺失=被杀/link失败=ERROR/UNRUN);
3. 该 marker 为 SUCCEEDED(WAIVED 单独归类,**绝不**升级为 SUCCEEDED);
4. `failing == 0`(有 SUCCEEDED marker 但 failing>0 = 假绿 → 打回 FAILED;无统计表 = 无法确认 → ERROR);
5. **signoff-strict**: `unverified==0 且 unmatched(两侧max)==0 且 aborted==0`,否则 → PARTIAL;
6. 只读**传入的单个 fresh 日志**,禁搜历史日志、禁看别的 variant。

verdict ∈ {SUCCEEDED, FAILED, WAIVED, PARTIAL, UNRUN, ERROR}。

## 四、三轴台账(替代单一互斥分类)

最终台账每项三轴(而非"一个类别"):
- **verdict**: SUCCEEDED / FAILED / WAIVED / PARTIAL / UNRUN / ERROR
- **proof_mode**: replacement / assembly / shadow / diagnostic
- **qualifications**: blackbox / dont-verify / unmatched / unread / ELAB-warning(逐对象+经批准数量+理由)

只有 `verdict=SUCCEEDED ∧ proof_mode=replacement ∧ qualifications=∅` 才是**无条件可替换等价**。

## 五、负向测试(签核前必须先绿)

`test_fm_verdict.py` 14 例,覆盖二审要求的全部陷阱:回显未执行 SUCCEEDED、SUCCEEDED但failing>0、
WAIVED、非零 rc、多/缺 marker、fresh FAILED、unverified/unmatched strict 拒绝、NOT RUN、无统计表、
assembly 放行。**当前 14/14 通过。** 真日志交叉验证:Backend→FAILED(旧脚本此处假绿)、
XSCore→PARTIAL(抓到 impl 31196 unmatched)、Bku→SUCCEEDED。

## 六、待办(后续步骤,尚未闭环)

- 补齐 golden 可复现:真实子模块 SHA(manifest 3 个错)、精确 patch、52 个 .v hash、Composer stub 提交、软链提交。
- 唯一权威入口:合并 pin/interface-only 进标准 `fm_eq.tcl`(标准入口目前不读 FM_INTERFACE_ONLY),按模式分流。
- clean clone 重建 golden + 代表性 smoke test。
- 全 306 项在冻结基线用新入口重跑(**禁用**历史 fm_full.log),出三轴台账。
