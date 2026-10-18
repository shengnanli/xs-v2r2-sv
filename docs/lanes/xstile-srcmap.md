# Lane: xstile-srcmap（codex 0238 主线 1）

## 交付
- `scripts/xstile_srcmap.py` → `docs/xstile_srcmap.tsv`：XSTile 例化闭包内每个模块的实际源。
  选源规则与 `scripts/full_elab_filelist.py` 一致（rtl/ 有定义即用 rtl/）。golden 源只许是
  `verif/vendor_boundary.tsv` / `verif/mc_memory_registry.tsv` 登记的存储模型，文件名与 sha256
  逐字对登记值；任何 golden 逻辑模块 → FATAL（exit 2）。
- `scripts/xstile_rtl_elab.sh`：用该源表生成清单，VCS（+define+SYNTHESIS）真 elaborate，不给 -top，
  要求 XSTile 为顶层且其余顶层都不在闭包内（= 闭包里每个模块都被实际例化）。
- `scripts/test_xstile_srcmap.py`：正例 + 4 条反例（删 rtl Rob / 去登记 / 改 sha / 改文件名），均须判死。
- gate_all：`XSTile 源表幂等`（`xstile_srcmap.py --check`）。VCS elaborate ~10 分钟，不进 gate。

## 结果（base main dabf1cda0）
- 闭包 2136 模块：RTL 2039 / MEMORY_MODEL 97 / golden 逻辑 0。
- elaborate：rtl 1517 文件 + 纯 package 12 + 存储模型 97；vcs rc=0、0 error。
- 顶层：XSTile + 11 个同文件闲置模块（不在闭包、未例化）：
  C22 C53 CSA3_2 F3Predecoder FrontendTrigger IndexableCAMTemplate PreDecode PredChecker
  RVCExpander RegCacheTagModule xs_StorePipe_core。

## 踩到的
- `rtl/backend/Rename.sv` 用宏 `` `STD_FL(StdFreeList_2, v0FreeList, ...) `` 例化 4 个 free list，
  例化式看不见 → 第一次 elaborate 报 4 条 Error-[URMI]。已加「宏实参里的已知模块名算子模块」。
  这正是 VCS 兜底的意义：srcmap 漏认漏不过 elaborate。
- 不锚定的例化正则在 Python 3.6 上要 140 秒，改为锚在语句开头（34~40 秒）。
- 已知边界：若某闭包模块只被一个闲置顶层例化，VCS 不会把它列为顶层，本判据看不出来。
