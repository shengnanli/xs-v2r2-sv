# bbox 样本报告（测试夹具，非证据）

`scripts/test_ext_registry_negative.py` 的 D 段需要一份**真实的** Formality 黑盒报告，
且必须含已批准的 `array_2_ext`，用来验证 `declare_allow.py` 对表内/表外 `_ext` 的判别。

## 为什么放这里而不是 evidence/

`evidence/` 在 `.gitignore` 第 21 行。该目录下只有 12 个文件被 force-add 跟踪
（全部是 `14e6b7798157/WrBypass/`）。测试原本硬编码
`evidence/2c433ec3ef07/FoldedSRAMTemplate/black_boxes.rpt` —— 那是**未跟踪的工作树残留**，
于是测试在作者机器上通过、在 clean clone 里 7/8 失败。与"证明输入未跟踪 =
clean clone 不可复现"是同一个病。

不能拿已跟踪的 WrBypass 报告顶替：它里面 `grep -o '[A-Za-z_0-9]*_ext'` 一个都没有，
而 D 段正需要一份含 `array_2_ext` 的报告。也不宜手搓：`bbox_parse.py` 校验很严
（`FM-184` 须恰好出现 1 次，且其后到首个 section 之前不得有未知内容）。

来源：`evidence/2c433ec3ef07/FoldedSRAMTemplate/black_boxes.rpt`，原文照搬未改。
