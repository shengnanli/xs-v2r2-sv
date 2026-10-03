# 认领（agent/next200c-takeover，2026-10-03，Claude 集成者接管 newrtl-next200c——原 agent 额度用尽，用户指示接手）

已合入 agent/newrtl-next200c@5094100f（187 个目标证书在合并后仍有效）。本 lane 独占剩余：

- 20 个有 RTL 无 receipt：`Arbiter16_TLBundleD` `Arbiter3_PfGenReq` `Arbiter4_L2ToL1Hint` `Arbiter4_PrefetchReq` `CSA4to2_15` `FastArbiter_27` `FliDTable` `FliHTable` `FliSTable` `IntBuffer_1` `IntBuffer_2` `MbistIntfFrontend` `MbistIntfMemBlk` `NfMappedElemIdx` `OverrideableQueue` `OverrideableQueue_1` `PipelineRegModule_6` `Rec7Table` `Rsqrt7Table` `SatpFlushMod`
- 因 `rtl/backend/xs_Pmacfg_core.sv` 改动而 STALE 的 `Pma0cfgModule`..`Pma15cfgModule`（16 个）重证
