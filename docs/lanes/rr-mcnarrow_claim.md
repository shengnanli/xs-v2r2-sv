# Lane claim: rr-mcnarrow

Integrator: claude (main session). Claimed 2026-10-20. Base: main 22cf76370。承 rr-special §3.1（agent/rr-special@9e3da4a35）。

Scope: 46 个 impl_golden_mc_not_shared 存储叶子（SRAMTemplate 26 / SRAMTemplateNewForm 9 / UncoreChiQueues 4 / FrontendBridgeBuffers 3 /
SplittedSRAMTemplate 2 / SplittedSRAM 2）：把「每个 variant 的 impl MC = 它自己的 FM_REF_DEPS」做成生成器默认行为并补手写 Makefile，
然后官方重证；Queue16_CHIREQ / Queue16_CHIRSP / Queue4_CHISNP、SplittedSRAMTemplate/_1、SRAMTemplate/_2 等被 impl_golden 挂靠者出证书（新增文件）。
Owned paths: scripts/gen_sram_wrappers.py、verif/ut/SRAMTemplateNewForm/gen.py、verif/ut/{SRAMTemplate,SRAMTemplateNewForm,UncoreChiQueues,
FrontendBridgeBuffers,SplittedSRAMTemplate,SplittedSRAM}/ 下的 Makefile 及生成物、这 46 个目标的 evidence/receipt/fm_predictions、新增证书、docs/lanes/rr-mcnarrow*.md。
Not touched: 判据（proof_certificate/make_receipt/fm_verdict/fm_eq.tcl）、已有证书与 allow、派生表、rtl/、登记表、G0/G1；rr-small / rr-big 名单内目标。
