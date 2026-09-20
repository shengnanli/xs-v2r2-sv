# Entries* 剩余 7 个变体：实测结果与预登记逐条对账

配套文件：`docs/lanes/entries-rest-predictions.md`（★预测在跑之前就已提交★）。
本文件只记**实测**，以及实测与预登记的逐条对账。对不上的按 fail 报，不回头改预测。

- 分支 `agent/entries-rest3`
- FM stage-1（vmucp=false）钉在 commit `6161f95bd555d2cfbaafee2230ba9f3e2541e8eb`
- FM stage-2（vmucp=true，最终签核）钉在 commit `9d2783dcbaf4bbcc5cedb391586d846689716b6b`
- golden：`/home/eda/xs-env/G1-canonical/golden-rtl`（CANONICAL_ID `G1-a4ea14f2ddf612bb4…`）

## 1. FM 逐条对账 —— ★7/7 全对，无一例外★

`预登记带` 与 `vmucp 期望` 都是**跑之前**定死的：
带来自 predictions.md，期望来自 stage-1 实测（`vmucp_evidence.py` 打印的 `passing -> passing+unread`）。

| 变体 | 预登记带 | vmucp 期望 | 实测 passing | 带内 | = 期望 | failing | unread | unmatched | bbox | dont_verify | verdict |
|---|---|---|---|---|---|---|---|---|---|---|---|
| EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | 24932–25312 | 25300 | **25300** | OK | OK | 0 | 0 | 0 | 0 | false | SIGNOFF_PASS |
| EntriesAluMulBkuBrhJmp | 24647–25022 | 25010 | **25010** | OK | OK | 0 | 0 | 0 | 0 | false | SIGNOFF_PASS |
| EntriesFaluFcvtF2vFmacFdiv | 16443–16693 | 16619 | **16619** | OK | OK | 0 | 0 | 0 | 0 | false | SIGNOFF_PASS |
| EntriesFaluFmac | 15768–16008 | 15934 | **15934** | OK | OK | 0 | 0 | 0 | 0 | false | SIGNOFF_PASS |
| EntriesFaluFmacFdiv | 16374–16623 | 16549 | **16549** | OK | OK | 0 | 0 | 0 | 0 | false | SIGNOFF_PASS |
| EntriesVfmaVialuFixVfalu | 18225–18503 | 18369 | **18369** | OK | OK | 0 | 0 | 0 | 0 | false | SIGNOFF_PASS |
| EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 18605–18889 | 18755 | **18755** | OK | OK | 0 | 0 | 0 | 0 | false | SIGNOFF_PASS |

七个都是 native `SUCCEEDED`、`elab147=false`、`unmatched_ref/impl` 双 0、黑盒输出 0。

复跑：`scripts/run_proof.sh <变体> <变体>`；对账脚本见本文件末尾。

### stage-1（vmucp=false）—— vmucp 申请的依据

| 变体 | passing | unread(全 matched_nc) | Constant reg |
|---|---|---|---|
| EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | 19184 | 6116 | 12 |
| EntriesAluMulBkuBrhJmp | 18782 | 6228 | 12 |
| EntriesFaluFcvtF2vFmacFdiv | 13491 | 3128 | 74 |
| EntriesFaluFmac | 12794 | 3140 | 74 |
| EntriesFaluFmacFdiv | 13413 | 3136 | 74 |
| EntriesVfmaVialuFixVfalu | 16017 | 2352 | 134 |
| EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 16411 | 2344 | 134 |

七个的 `vmucp_evidence.py` 六条证据全部齐备（每个都打印"申请条件齐备"）：
unmatched unread ref/impl 双 0；双射严格 1:1；配对**全部**是钉点文件的子集、
FM 自行猜配 **0** 对；`^ *Error:` 0 行；unmatched 六项全零；
dont_verify / elab147 / relaxed_appvars 三项全空。

## 2. ★一条比"落在带内"强得多的核对（实测之后才敢说）★

预登记时模型被当作**上界**，判据是"落在 `[0.985×模型, 模型]`"。七个实测回来之后发现
不是"落在一条 1.5% 宽的带里"，是**等式**：

    模型值 − Constant reg = stage-1 的 (passing + unread) = stage-2 的 passing

| 变体 | 模型 | − Constant reg | 实测 |
|---|---|---|---|
| AluBrhJmpI2f… | 25312 | −12 | **25300** |
| AluMulBkuBrhJmp | 25022 | −12 | **25010** |
| FaluFcvtF2vFmacFdiv | 16693 | −74 | **16619** |
| FaluFmac | 16008 | −74 | **15934** |
| FaluFmacFdiv | 16623 | −74 | **16549** |
| VfmaVialuFixVfalu | 18503 | −134 | **18369** |
| VfmaVialuFixVimac… | 18889 | −134 | **18755** |

predictions.md 预登记时写的「差额只能由 Constant reg 解释」**逐个精确对上**。

★但判据仍按预登记的带走，不因为结果好看就事后收紧。★
把带改成等式是**下一轮**的事（要先在新变体上再验一次这条等式），不是这一轮的事 ——
预登记之后改判据，无论改松改紧都是改判据。

## 3. UT 矩阵（3 seed × 2 initreg × 200k 拍）

见本文件同目录的 round 记录与各 `verif/ut/<变体>/sim_*.log`。
判据：每格 `errors=0`、`checks=` 非零、覆盖闸全部非零。

## 4. ★initreg 有效性（codex 0168）★

「两轮都绿」本身证明不了复位域 —— 本家族实测正是"可观测行为对上电初值不敏感"那一类：
`EntriesFaluFmac` 的两轮日志**除命令行外完全相同**。所以另做了一道
`scripts/check_initreg_effective.py`（探针 tb 读上电瞬间的寄存器），
8 个变体（本轮 7 个 + 已签核 2 个中的 AluCsrFenceDiv/VfdivVidiv）全部 rc=0。
依据与"为什么 md5 方案是 fail-open"写在脚本文件头。

## 5. 对账脚本（本文件表 1 的来源）

```bash
python3 - <<'PY'
import json,re,pathlib
L=pathlib.Path('<跑 FM 时的日志目录>')
PRED={'EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v':(24932,25312,19184,6116), ...}
for v,(lo,hi,p1,ur) in PRED.items():
    verd,js=re.findall(r'^(\w+)\t(\{.*\})$',(L/f'fm2_{v}.log').read_text(),re.M)[-1]
    d=json.loads(js); p=d['passing']
    assert lo<=p<=hi and p==p1+ur and d['failing']==0 and not d['unread']
PY
```
