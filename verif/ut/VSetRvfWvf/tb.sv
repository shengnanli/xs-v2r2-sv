// =============================================================================
// tb —— VSetRvfWvf UT:golden VSetRvfWvf (u_g) vs 可读核 VSetRvfWvf_xs (u_i)。
// 纯组合:每拍随机驱动 valid/func/src4(oldVL)/src1(vtype),下一拍比对全部输出
// (含 vtype 字段、vlIsZero、vlIsVlmax)。
// 激励:fuOpType 重点取 vv/keep_v/csrrvl,并随机扫 vsew/vlmul/oldVL,逼出
//   illegal、vl==0、vl==vlmax 各分支,以及 csrrvl 透传旧 vl。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // VSetRvfWvf 处理的 uop:vv / keep_v / csrrvl;另加几个邻近码做覆盖。
  localparam int NOP = 5;
  logic [8:0] OPS [NOP] = '{
    9'h072, // uvsetvcfg_vv     vsetvl,保持 vl,vtype 来自 rs2
    9'h0A2, // uvsetvcfg_keep_v vsetvli,保持 vl,vtype 来自立即数
    9'h016, // csrrvl           读 vl(透传旧 vl)
    9'h070, // uvsetvcfg_xx     vsetvl(覆盖 func[6] vtype_valid 路径)
    9'h020  // uvsetvcfg_ii     vsetivli 立即数路径
  };

  logic          io_in_valid;
  logic [8:0]    io_in_bits_ctrl_fuOpType;
  logic          io_in_bits_ctrl_robIdx_flag;
  logic [7:0]    io_in_bits_ctrl_robIdx_value;
  logic [7:0]    io_in_bits_ctrl_pdest;
  logic          io_in_bits_ctrl_rfWen;
  logic          io_in_bits_ctrl_vlWen;
  logic [7:0]    io_in_bits_data_src_4;
  logic [127:0]  io_in_bits_data_src_1;
  logic [63:0]   io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0]   io_in_bits_perfDebugInfo_selectTime;
  logic [63:0]   io_in_bits_perfDebugInfo_issueTime;

  logic        g_valid,g_flag,g_rfWen,g_vlWen,g_vtv,g_vill,g_vma,g_vta,g_vz,g_vmx;
  logic [7:0]  g_robv,g_pdest; logic [1:0] g_vsew; logic [2:0] g_vlmul;
  logic [63:0] g_res,g_enq,g_sel,g_iss;
  logic        i_valid,i_flag,i_rfWen,i_vlWen,i_vtv,i_vill,i_vma,i_vta,i_vz,i_vmx;
  logic [7:0]  i_robv,i_pdest; logic [1:0] i_vsew; logic [2:0] i_vlmul;
  logic [63:0] i_res,i_enq,i_sel,i_iss;

  VSetRvfWvf u_g (
    .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen),
    .io_in_bits_ctrl_vlWen(io_in_bits_ctrl_vlWen),
    .io_in_bits_data_src_4(io_in_bits_data_src_4),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(g_valid), .io_out_bits_ctrl_robIdx_flag(g_flag),
    .io_out_bits_ctrl_robIdx_value(g_robv), .io_out_bits_ctrl_pdest(g_pdest),
    .io_out_bits_ctrl_rfWen(g_rfWen), .io_out_bits_ctrl_vlWen(g_vlWen),
    .io_out_bits_res_data(g_res),
    .io_out_bits_perfDebugInfo_enqRsTime(g_enq),
    .io_out_bits_perfDebugInfo_selectTime(g_sel),
    .io_out_bits_perfDebugInfo_issueTime(g_iss),
    .io_vtype_valid(g_vtv), .io_vtype_bits_illegal(g_vill),
    .io_vtype_bits_vma(g_vma), .io_vtype_bits_vta(g_vta),
    .io_vtype_bits_vsew(g_vsew), .io_vtype_bits_vlmul(g_vlmul),
    .io_vlIsZero(g_vz), .io_vlIsVlmax(g_vmx)
  );

  VSetRvfWvf_xs u_i (
    .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen),
    .io_in_bits_ctrl_vlWen(io_in_bits_ctrl_vlWen),
    .io_in_bits_data_src_4(io_in_bits_data_src_4),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(i_valid), .io_out_bits_ctrl_robIdx_flag(i_flag),
    .io_out_bits_ctrl_robIdx_value(i_robv), .io_out_bits_ctrl_pdest(i_pdest),
    .io_out_bits_ctrl_rfWen(i_rfWen), .io_out_bits_ctrl_vlWen(i_vlWen),
    .io_out_bits_res_data(i_res),
    .io_out_bits_perfDebugInfo_enqRsTime(i_enq),
    .io_out_bits_perfDebugInfo_selectTime(i_sel),
    .io_out_bits_perfDebugInfo_issueTime(i_iss),
    .io_vtype_valid(i_vtv), .io_vtype_bits_illegal(i_vill),
    .io_vtype_bits_vma(i_vma), .io_vtype_bits_vta(i_vta),
    .io_vtype_bits_vsew(i_vsew), .io_vtype_bits_vlmul(i_vlmul),
    .io_vlIsZero(i_vz), .io_vlIsVlmax(i_vmx)
  );

  // src1 低位放可控 vtype(扫 vsew/vlmul 全枚举),高位/reserved 随机。
  function automatic logic [127:0] rand_src1();
    int unsigned sel = $urandom_range(0, 9);
    logic [2:0] vsew, vlmul; logic vma, vta;
    if (sel < 7) begin
      vsew = $urandom_range(0,7); vlmul = $urandom_range(0,7);
      vma = $urandom; vta = $urandom;
      return {{$urandom,$urandom,$urandom} & 96'hFFFFFFFF_FFFFFFFF_FFFF0000,
              {$urandom_range(0,255)} } // 高 96 位随机(含 reserved/vill 位段)
             | {112'h0, vma, vta, vsew, vlmul};
    end else begin
      return {$urandom,$urandom,$urandom,$urandom};
    end
  endfunction

  function automatic logic [7:0] rand_oldvl();
    int unsigned sel = $urandom_range(0, 4);
    case (sel)
      0: return 8'h0;
      1: return $urandom_range(0, 18); // 跨 vlmax 边界
      2: return '1;
      default: return $urandom;
    endcase
  endfunction

  task automatic drive_inputs();
    int unsigned pick = $urandom_range(0, 99);
    if (pick < 92) io_in_bits_ctrl_fuOpType = OPS[$urandom_range(0, NOP-1)];
    else           io_in_bits_ctrl_fuOpType = $urandom_range(0, 511);
    io_in_valid                  = $urandom;
    io_in_bits_ctrl_robIdx_flag  = $urandom;
    io_in_bits_ctrl_robIdx_value = $urandom;
    io_in_bits_ctrl_pdest        = $urandom;
    io_in_bits_ctrl_rfWen        = $urandom;
    io_in_bits_ctrl_vlWen        = $urandom;
    io_in_bits_data_src_4        = rand_oldvl();
    io_in_bits_data_src_1        = rand_src1();
    io_in_bits_perfDebugInfo_enqRsTime  = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_selectTime = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_issueTime  = {$urandom,$urandom};
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] %s g=%h i=%h (func=%h s4=%h s1=%h vld=%b)", $time, nm, g, i, \
        io_in_bits_ctrl_fuOpType, io_in_bits_data_src_4, io_in_bits_data_src_1, io_in_valid); end \
    checks++;

  task automatic check_outputs();
    `CK(g_res,   i_res,   "res_data")
    `CK(g_valid, i_valid, "out_valid")
    `CK(g_flag,  i_flag,  "robIdx_flag")
    `CK(g_robv,  i_robv,  "robIdx_value")
    `CK(g_pdest, i_pdest, "pdest")
    `CK(g_rfWen, i_rfWen, "rfWen")
    `CK(g_vlWen, i_vlWen, "vlWen")
    `CK(g_enq,   i_enq,   "enqRsTime")
    `CK(g_sel,   i_sel,   "selectTime")
    `CK(g_iss,   i_iss,   "issueTime")
    `CK(g_vtv,   i_vtv,   "vtype_valid")
    `CK(g_vill,  i_vill,  "vtype_illegal")
    `CK(g_vma,   i_vma,   "vtype_vma")
    `CK(g_vta,   i_vta,   "vtype_vta")
    `CK(g_vsew,  i_vsew,  "vtype_vsew")
    `CK(g_vlmul, i_vlmul, "vtype_vlmul")
    `CK(g_vz,    i_vz,    "vlIsZero")
    `CK(g_vmx,   i_vmx,   "vlIsVlmax")
  endtask

  initial begin
    drive_inputs();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check_outputs();
      drive_inputs();
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
