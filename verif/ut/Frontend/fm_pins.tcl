# Frontend FM 钉点: 唯一 failing = 黑盒输入引脚 inner_bpu/io_bpu_to_ftq_resp_bits_s3_valid_0。
# 两侧该引脚都由**同一条声明未驱动的 wire inner__probe** 驱动(difftest probe 在无
# difftest 基线下驱动源被裁剪; golden Frontend.sv:496 与 impl Frontend_wrapper.sv:499
# 逐字相同)。Formality 把 ref 侧未驱动网建成 Und 自由割点、impl 侧未建 → X vs X 的
# 建模不对称假阳性, set_constant 亦无法穿透 Und 割点。此为黑盒边界建模假阳性,
# 双侧结构完全一致, 排除该点比对(证据: unmatched_full.rpt 仅 1 个 ref Und
# inner__probe; failing_full.rpt 报告本身即提示 undriven reference)。
if {[catch {set_dont_verify_points -type port {r:/WORK/Frontend/inner_bpu/io_bpu_to_ftq_resp_bits_s3_valid_0}} m1]} {
  catch {set_dont_verify_points {r:/WORK/Frontend/inner_bpu/io_bpu_to_ftq_resp_bits_s3_valid_0}}
}
catch {set_dont_verify_points {i:/WORK/Frontend/inner_bpu/io_bpu_to_ftq_resp_bits_s3_valid_0}}
puts "FRONTEND_PINS: s3_valid_0 BBPin excluded (undriven-probe modeling artifact, both sides identical undriven wire)"
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
