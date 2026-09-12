// =============================================================================
// tb —— VSetRiWi UT:golden VSetRiWi (u_g) vs 可读核 VSetRiWi_xs (u_i) 逐拍比对。
// 纯组合单周期:每拍随机驱动 src0/src1/fuOpType,下一拍沿比较所有输出。
// 激励策略:
//   - fuOpType 多数取自合法 vset 变体表(覆盖 vsetivli/vsetvli/vsetvl 各分支),
//     少数取完全随机 9 位码(覆盖未定义码,golden 非 X 时仍须等价)。
//   - src1 混合「合法 vtype 字段」与全随机:重点扫 vsew∈[0,7]、vlmul∈[0,7]
//     的全组合(含保留/非法编码),以及 reserved/vill 位,逼出 illegal 路径。
//   - avl(src0 或立即数)混合 0 / 边界 / 跨 vlmax 值,覆盖 min(avl,vlmax) 截断。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // 合法 vset fuOpType(VSetRiWi 走的是 uvsetrd_* 系列,destTypeBit=0)。
  localparam int NOP = 7;
  logic [8:0] OPS [NOP] = '{
    9'h000, // uvsetrd_ii      vsetivli 普通
    9'h080, // uvsetrd_xi      vsetvli  普通(avl=rs1)
    9'h081, // uvsetrd_vlmax_i vsetvli  rs1==x0 取 vlmax
    9'h100, // uvsetrd_xx      vsetvl   普通
    9'h101, // uvsetrd_vlmax_x vsetvl   rs1==x0 取 vlmax
    9'h001, // uvsetrd_ii|vlmax(立即数 + setVlmax 组合,覆盖 func[0])
    9'h016  // csrrvl(VSetRiWi 不专门处理,但仍须与 golden 一致)
  };

  logic        io_in_valid;
  logic [8:0]  io_in_bits_ctrl_fuOpType;
  logic        io_in_bits_ctrl_robIdx_flag;
  logic [7:0]  io_in_bits_ctrl_robIdx_value;
  logic [7:0]  io_in_bits_ctrl_pdest;
  logic        io_in_bits_ctrl_rfWen;
  logic [63:0] io_in_bits_data_src_1;
  logic [63:0] io_in_bits_data_src_0;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;

  logic        g_valid, g_flag, g_rfWen;
  logic [7:0]  g_robv, g_pdest;
  logic [63:0] g_res, g_enq, g_sel, g_iss;
  logic        i_valid, i_flag, i_rfWen;
  logic [7:0]  i_robv, i_pdest;
  logic [63:0] i_res, i_enq, i_sel, i_iss;

  VSetRiWi u_g (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(g_valid),
    .io_out_bits_ctrl_robIdx_flag(g_flag),
    .io_out_bits_ctrl_robIdx_value(g_robv),
    .io_out_bits_ctrl_pdest(g_pdest),
    .io_out_bits_ctrl_rfWen(g_rfWen),
    .io_out_bits_res_data(g_res),
    .io_out_bits_perfDebugInfo_enqRsTime(g_enq),
    .io_out_bits_perfDebugInfo_selectTime(g_sel),
    .io_out_bits_perfDebugInfo_issueTime(g_iss)
  );

  VSetRiWi_xs u_i (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(i_valid),
    .io_out_bits_ctrl_robIdx_flag(i_flag),
    .io_out_bits_ctrl_robIdx_value(i_robv),
    .io_out_bits_ctrl_pdest(i_pdest),
    .io_out_bits_ctrl_rfWen(i_rfWen),
    .io_out_bits_res_data(i_res),
    .io_out_bits_perfDebugInfo_enqRsTime(i_enq),
    .io_out_bits_perfDebugInfo_selectTime(i_sel),
    .io_out_bits_perfDebugInfo_issueTime(i_iss)
  );

  // 组装一个「带可控 vtype 字段」的 src1:大概率注入合法/全枚举的 vsew/vlmul,
  // 小概率全随机(覆盖 reserved/vill/高位)。
  function automatic logic [63:0] rand_src1();
    int unsigned sel = $urandom_range(0, 9);
    logic [2:0] vsew, vlmul;
    logic vma, vta;
    if (sel < 7) begin
      vsew  = $urandom_range(0, 7);   // 含保留编码 4..7
      vlmul = $urandom_range(0, 7);   // 含保留编码 100
      vma   = $urandom; vta = $urandom;
      // 低 14 位放 vtype + 立即 avl(src1[14:10]);其余位随机以扫 reserved/vill。
      return {$urandom, $urandom} & 64'hFFFF_FFFF_FFFF_0000
             | {49'h0, $urandom_range(0,31), vma, vta, vsew, vlmul} & 64'h0000_0000_0000_FFFF;
    end else begin
      return {$urandom, $urandom};
    end
  endfunction

  function automatic logic [63:0] rand_avl();
    int unsigned sel = $urandom_range(0, 5);
    case (sel)
      0: return 64'h0;
      1: return 64'h1;
      2: return $urandom_range(0, 20);  // 跨 vlmax 边界附近
      3: return '1;
      default: return {$urandom, $urandom};
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
    io_in_bits_data_src_1        = rand_src1();
    io_in_bits_data_src_0        = rand_avl();
    io_in_bits_perfDebugInfo_enqRsTime  = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_selectTime = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_issueTime  = {$urandom,$urandom};
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] %s g=%h i=%h (func=%h s0=%h s1=%h)", $time, nm, g, i, \
        io_in_bits_ctrl_fuOpType, io_in_bits_data_src_0, io_in_bits_data_src_1); end \
    checks++;

  task automatic check_outputs();
    `CK(g_res,   i_res,   "res_data")
    `CK(g_valid, i_valid, "out_valid")
    `CK(g_flag,  i_flag,  "robIdx_flag")
    `CK(g_robv,  i_robv,  "robIdx_value")
    `CK(g_pdest, i_pdest, "pdest")
    `CK(g_rfWen, i_rfWen, "rfWen")
    `CK(g_enq,   i_enq,   "enqRsTime")
    `CK(g_sel,   i_sel,   "selectTime")
    `CK(g_iss,   i_iss,   "issueTime")
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
