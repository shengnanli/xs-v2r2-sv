# 认领（agent/ctrlblock-memcert，2026-10-14，Claude 集成者预建；codex 0230 问题 1）

本 lane 独占（集成者授权的**唯一一次**公共核改动，期间其他 lane 不得改这些文件）：
- `scripts/audit_ram_memory_model.py`（M1 模板扩 nRmW）
- `verif/vendor_boundary.tsv`（仅新增 dt_pcTransType_160x2 一行）
- `scripts/proof_certificate.py`（hdlin_interface_only 回读集合 = green_child ∪ 已登记 APPROVED_MEMORY_MACRO_MODEL）
- 上述三者的正负测（scripts/test_*）
不碰 CtrlBlock / Backend 的 RTL、UT、allow、证据——那些在 agent/backend-asm。
