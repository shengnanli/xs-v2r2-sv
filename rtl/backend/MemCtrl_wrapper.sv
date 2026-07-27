// MemCtrl 包装层: golden 同名扁平端口。可读核 xs_MemCtrl 提供 7 个更新流水寄存器,
// SSIT / WaitTable 子模块在此例化(FM 两侧读同一份 golden 源 => 对称子树)。
module MemCtrl(
  input       clock,
  input       reset,
  input [4:0] io_csrCtrl_lvpred_timeout,
  input       io_memPredUpdate_valid,
  input [9:0] io_memPredUpdate_waddr,
  input [9:0] io_memPredUpdate_ldpc,
  input [9:0] io_memPredUpdate_stpc,
  input       io_mdpFoldPcVecVld_0,
  input       io_mdpFoldPcVecVld_1,
  input [9:0] io_mdpFlodPcVec_0,
  input [9:0] io_mdpFlodPcVec_1
);

  wire       ssit_update_valid, waittable_update_valid;
  wire [9:0] ssit_update_ldpc, ssit_update_stpc, waittable_update_waddr;
  wire [4:0] ssit_csrCtrl_lvpred_timeout, waittable_csrCtrl_lvpred_timeout;

  xs_MemCtrl u_core (
    .clock                            (clock),
    .reset                            (reset),
    .csrCtrl_lvpred_timeout           (io_csrCtrl_lvpred_timeout),
    .memPredUpdate_valid              (io_memPredUpdate_valid),
    .memPredUpdate_waddr              (io_memPredUpdate_waddr),
    .memPredUpdate_ldpc               (io_memPredUpdate_ldpc),
    .memPredUpdate_stpc               (io_memPredUpdate_stpc),
    .ssit_update_valid                (ssit_update_valid),
    .ssit_update_ldpc                 (ssit_update_ldpc),
    .ssit_update_stpc                 (ssit_update_stpc),
    .ssit_csrCtrl_lvpred_timeout      (ssit_csrCtrl_lvpred_timeout),
    .waittable_update_valid           (waittable_update_valid),
    .waittable_update_waddr           (waittable_update_waddr),
    .waittable_csrCtrl_lvpred_timeout (waittable_csrCtrl_lvpred_timeout)
  );

  SSIT ssit (
    .clock                     (clock),
    .reset                     (reset),
    .io_ren_0                  (io_mdpFoldPcVecVld_0),
    .io_ren_1                  (io_mdpFoldPcVecVld_1),
    .io_raddr_0                (io_mdpFlodPcVec_0),
    .io_raddr_1                (io_mdpFlodPcVec_1),
    .io_update_valid           (ssit_update_valid),
    .io_update_ldpc            (ssit_update_ldpc),
    .io_update_stpc            (ssit_update_stpc),
    .io_csrCtrl_lvpred_timeout (ssit_csrCtrl_lvpred_timeout)
  );

  WaitTable waittable (
    .clock                     (clock),
    .reset                     (reset),
    .io_update_valid           (waittable_update_valid),
    .io_update_waddr           (waittable_update_waddr),
    .io_csrCtrl_lvpred_timeout (waittable_csrCtrl_lvpred_timeout)
  );

endmodule
