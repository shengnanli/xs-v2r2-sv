// =============================================================================
// SatpFlushMod —— 写 satp / vsatp 那一拍，把"写之前"的特权态与地址翻译模式存一份快照
//
// 在哪一层：后端 CSR 功能单元包装（backend/fu/wrapper/CSR.scala `satpFlushMod = Module(new SatpFlushMod)`），
//   输出给 NewCSR 的 io.oldPrivSate / oldSatpMode / oldVsatpMode。Scala：backend/fu/NewCSR/SatpFlushMod.scala。
// 为什么要它：写 satp/vsatp 会冲刷流水线并从下一条指令重新取指；若这第一条取指就因新的翻译模式出了
//   异常（trapIsSatpFlushFirstFetchFault），异常现场要按"写之前"的特权态与 satp 模式来报，
//   而那时 CSR 里已经是新值了——所以在写的那一拍把旧值存下来。
// 机制：wen = satp.valid || vsatp.valid；wen 那拍锁存 {privState.PRVM, privState.V, satp 模式, vsatp 模式}，
//   其余时间保持。输入来自 NewCSR 的 io.status.satp / vsatp（valid = 本拍写该 CSR，bits = MODE 字段 4 位）与 status.privState。
// 复位：无（golden 四个寄存器都是 Reg、无初值，只有 clock 端口）。
// golden 对照：G1-canonical/golden-rtl/SatpFlushMod.sv（139 行）
// =============================================================================
module SatpFlushMod (
  input  logic       clock,
  input  logic       in_satp_valid,
  input  logic [3:0] in_satp_bits,
  input  logic       in_vsatp_valid,
  input  logic [3:0] in_vsatp_bits,
  input  logic [1:0] in_privState_PRVM,
  input  logic       in_privState_V,
  output logic [1:0] out_oldPrivState_PRVM,
  output logic       out_oldPrivState_V,
  output logic [3:0] out_oldSatpMode,
  output logic [3:0] out_oldVsatpMode
);

  // ---- 写 satp 或 vsatp 的那一拍锁存快照，其余保持 ----
  logic wen;
  assign wen = in_satp_valid | in_vsatp_valid;

  always_ff @(posedge clock) begin
    if (wen) begin
      out_oldPrivState_PRVM <= in_privState_PRVM;
      out_oldPrivState_V    <= in_privState_V;
      out_oldSatpMode       <= in_satp_bits;
      out_oldVsatpMode      <= in_vsatp_bits;
    end
  end
endmodule
