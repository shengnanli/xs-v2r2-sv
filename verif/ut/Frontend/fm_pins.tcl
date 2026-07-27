# Frontend FM 钉点: 无 dont_verify / 无 waiver / 无 relaxed appvar / 无 constant / 无 tie-off。
#
# 历史残留 golden-only 死点 = wire inner__probe(golden Frontend.sv:496 与
# impl Frontend_wrapper.sv:525 逐字相同): `Predictor inner_bpu` 的输出引脚
# io_bpu_to_ftq_resp_bits_s3_valid_0 连到该 wire, 该 wire 无任何下游读者(零功能扇出)。
# 之前 Predictor 被黑盒时该引脚在 ref 侧是 undriven cut-point(Und), 毒化 matched BBPin
# -> native FAILED(failing=1)。
#
# 结构修复(codex_0072 裁定, 非 policy 吸收): golden Predictor.sv 两侧真实 elaborate
# (见 Makefile FM_REF_DEPS_Frontend / WRAPPER_SRCS), 令 s3_valid_0 由 Predictor 内部
# s3_valid_dup_3 & ~redirect 驱动 -> inner__probe 成 driven-but-unread 内部 net,
# cut-point 消失(fm.log: Cut=0)。vmucp=true 下该 driven-but-unread 点作为对称
# matched-unread compare point 被 FM 实证 passing。**不再** set_dont_verify_points, 亦
# 不再需要 dead-ref 吸收(native SUCCEEDED, failing=0)。
puts "FRONTEND_PINS: no dont_verify; Predictor two-sided elaborated -> inner__probe driven internal net (Cut=0)"
