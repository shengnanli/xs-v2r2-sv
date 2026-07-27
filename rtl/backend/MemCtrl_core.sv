// xs_MemCtrl —— 可读重写核（访存相关预测表控制/更新流水级）
// ---------------------------------------------------------------------------
// MemCtrl 是 SSIT(Store Set ID Table) 与 WaitTable 的持有者兼「更新路径打拍级」。
// 它把 memPredUpdate / csrCtrl 输入寄存一拍后分发给 SSIT / WaitTable 的更新端口,
// 读端口(mdpFoldPcVec)则直连 SSIT。MemCtrl 本身**无输出端口**——SSIT/WaitTable 的
// 读结果不经 MemCtrl 边界返回(在更外层消费)。故本层唯一逻辑 = 7 个更新流水寄存器。
//
// 与 golden MemCtrl.sv 逐位等价; SSIT / WaitTable 子模块由包装层例化(两侧同 golden 源)。
// ---------------------------------------------------------------------------
module xs_MemCtrl (
  input        clock,
  input        reset,
  input  [4:0] csrCtrl_lvpred_timeout,
  input        memPredUpdate_valid,
  input  [9:0] memPredUpdate_waddr,
  input  [9:0] memPredUpdate_ldpc,
  input  [9:0] memPredUpdate_stpc,
  // 打拍后送给 SSIT 更新端口
  output       ssit_update_valid,
  output [9:0] ssit_update_ldpc,
  output [9:0] ssit_update_stpc,
  output [4:0] ssit_csrCtrl_lvpred_timeout,
  // 打拍后送给 WaitTable 更新端口
  output       waittable_update_valid,
  output [9:0] waittable_update_waddr,
  output [4:0] waittable_csrCtrl_lvpred_timeout
);

  // 更新路径打拍(无复位, 与 golden 一致)
  reg        ssit_update_REG_valid;
  reg  [9:0] ssit_update_REG_ldpc;
  reg  [9:0] ssit_update_REG_stpc;
  reg        waittable_update_REG_valid;
  reg  [9:0] waittable_update_REG_waddr;
  reg  [4:0] ssit_csrCtrl_REG_lvpred_timeout;
  reg  [4:0] waittable_csrCtrl_REG_lvpred_timeout;

  always @(posedge clock) begin
    ssit_update_REG_valid                   <= memPredUpdate_valid;
    ssit_update_REG_ldpc                    <= memPredUpdate_ldpc;
    ssit_update_REG_stpc                    <= memPredUpdate_stpc;
    waittable_update_REG_valid              <= memPredUpdate_valid;
    waittable_update_REG_waddr              <= memPredUpdate_waddr;
    ssit_csrCtrl_REG_lvpred_timeout         <= csrCtrl_lvpred_timeout;
    waittable_csrCtrl_REG_lvpred_timeout    <= csrCtrl_lvpred_timeout;
  end

  assign ssit_update_valid                = ssit_update_REG_valid;
  assign ssit_update_ldpc                 = ssit_update_REG_ldpc;
  assign ssit_update_stpc                 = ssit_update_REG_stpc;
  assign ssit_csrCtrl_lvpred_timeout      = ssit_csrCtrl_REG_lvpred_timeout;
  assign waittable_update_valid           = waittable_update_REG_valid;
  assign waittable_update_waddr           = waittable_update_REG_waddr;
  assign waittable_csrCtrl_lvpred_timeout = waittable_csrCtrl_REG_lvpred_timeout;

endmodule
