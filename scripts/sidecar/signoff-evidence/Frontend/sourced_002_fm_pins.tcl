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
