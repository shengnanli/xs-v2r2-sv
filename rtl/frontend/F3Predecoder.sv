// =============================================================================
// xs_F3Predecoder_core —— F3 阶段分支预译码（纯组合）
//
// 对应 Chisel: xiangshan.frontend.F3Predecoder
// 在 IFU 的 F3 级对 PredictWidth 条已对齐的 32-bit 指令做分支信息译码，只输出
// brType/isCall/isRet（valid/isRVC 在该模块为 DontCare，不引出）。译码逻辑与
// PreDecode 完全相同，复用 xs_predecode_pkg。
// =============================================================================
import xs_predecode_pkg::*;

module xs_F3Predecoder_core #(
  parameter int unsigned PW = 16
)(
  input  logic [PW-1:0][31:0] io_instr,
  output logic [PW-1:0][1:0]  pd_brType,
  output logic [PW-1:0]       pd_isCall,
  output logic [PW-1:0]       pd_isRet
);
  for (genvar i = 0; i < PW; i++) begin : g_dec
    assign pd_brType[i] = xs_br_type(io_instr[i]);
    assign pd_isCall[i] = xs_is_call(io_instr[i]);
    assign pd_isRet[i]  = xs_is_ret(io_instr[i]);
  end
endmodule
