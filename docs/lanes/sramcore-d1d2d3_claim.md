# 认领（agent/sramcore-d1d2d3，2026-10-03，Claude 集成者预建；执行 codex 0206 D1/D2/D3）

本 lane 独占：

- `rtl/common/xs_SRAMTemplate_core.sv`（共享核，单 owner）
- `DCache`、`Slice`、`Slice_1`、`Slice_2`、`Slice_3`（并入 agent/dcachebody、agent/slice）
- `scripts/fm_verdict.py` 中 disabled_empty_module 类别与 ram_10x89 父级扩展
