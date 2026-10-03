// Arbiter1_L2TLBImp_Anon.sv —— L2TLB 给 TLB 的最终应答出口 outArb(i)：单入口仲裁器，退化为直通
//
// L2TLB.scala:142 `outArb = (0 until PtwWidth).map(i => Module(new Arbiter(..., 1)))`，
// 每个请求方（itlb/dtlb）一个；唯一入口接 mergeArb(i) 的出口（经 sector 化转换）。
// 入口数只剩 1，"仲裁"不发生：out = in，in.ready = out.ready（chosen 恒 0，父级不读，被删）。
//
// chisel3 Arbiter(n=1)：没有第二路可选，整个模块就是 valid/ready/载荷的直连。
// 共享核 xs_FixedPriorityArbiter_core 要求 NUM_IN >= 2，所以本文件自足、不例化核
// （同 rtl/memblock/Arbiter1_TagWriteReq.sv 先例）。载荷 58 个字段、270 位。
// golden 271 行 / 120 端口；本文件由 scripts/gen_arbiter_l2tlb_leaves.py 从 golden 端口表生成（勿手改）。

module Arbiter1_L2TLBImp_Anon (
  // --------------------------------------------------------------------------
  // 端口表（与 golden 逐名逐宽相同，120 个）
  // --------------------------------------------------------------------------
  output logic io_in_0_ready,
  input  logic io_in_0_valid,
  input  logic [1:0] io_in_0_bits_s2xlate,
  input  logic [34:0] io_in_0_bits_s1_entry_tag,
  input  logic [15:0] io_in_0_bits_s1_entry_asid,
  input  logic [13:0] io_in_0_bits_s1_entry_vmid,
  input  logic io_in_0_bits_s1_entry_n,
  input  logic [1:0] io_in_0_bits_s1_entry_pbmt,
  input  logic io_in_0_bits_s1_entry_perm_d,
  input  logic io_in_0_bits_s1_entry_perm_a,
  input  logic io_in_0_bits_s1_entry_perm_g,
  input  logic io_in_0_bits_s1_entry_perm_u,
  input  logic io_in_0_bits_s1_entry_perm_x,
  input  logic io_in_0_bits_s1_entry_perm_w,
  input  logic io_in_0_bits_s1_entry_perm_r,
  input  logic [1:0] io_in_0_bits_s1_entry_level,
  input  logic io_in_0_bits_s1_entry_v,
  input  logic [40:0] io_in_0_bits_s1_entry_ppn,
  input  logic [2:0] io_in_0_bits_s1_addr_low,
  input  logic [2:0] io_in_0_bits_s1_ppn_low_0,
  input  logic [2:0] io_in_0_bits_s1_ppn_low_1,
  input  logic [2:0] io_in_0_bits_s1_ppn_low_2,
  input  logic [2:0] io_in_0_bits_s1_ppn_low_3,
  input  logic [2:0] io_in_0_bits_s1_ppn_low_4,
  input  logic [2:0] io_in_0_bits_s1_ppn_low_5,
  input  logic [2:0] io_in_0_bits_s1_ppn_low_6,
  input  logic [2:0] io_in_0_bits_s1_ppn_low_7,
  input  logic io_in_0_bits_s1_valididx_0,
  input  logic io_in_0_bits_s1_valididx_1,
  input  logic io_in_0_bits_s1_valididx_2,
  input  logic io_in_0_bits_s1_valididx_3,
  input  logic io_in_0_bits_s1_valididx_4,
  input  logic io_in_0_bits_s1_valididx_5,
  input  logic io_in_0_bits_s1_valididx_6,
  input  logic io_in_0_bits_s1_valididx_7,
  input  logic io_in_0_bits_s1_pteidx_0,
  input  logic io_in_0_bits_s1_pteidx_1,
  input  logic io_in_0_bits_s1_pteidx_2,
  input  logic io_in_0_bits_s1_pteidx_3,
  input  logic io_in_0_bits_s1_pteidx_4,
  input  logic io_in_0_bits_s1_pteidx_5,
  input  logic io_in_0_bits_s1_pteidx_6,
  input  logic io_in_0_bits_s1_pteidx_7,
  input  logic io_in_0_bits_s1_pf,
  input  logic io_in_0_bits_s1_af,
  input  logic [37:0] io_in_0_bits_s2_entry_tag,
  input  logic [13:0] io_in_0_bits_s2_entry_vmid,
  input  logic io_in_0_bits_s2_entry_n,
  input  logic [1:0] io_in_0_bits_s2_entry_pbmt,
  input  logic [37:0] io_in_0_bits_s2_entry_ppn,
  input  logic io_in_0_bits_s2_entry_perm_d,
  input  logic io_in_0_bits_s2_entry_perm_a,
  input  logic io_in_0_bits_s2_entry_perm_g,
  input  logic io_in_0_bits_s2_entry_perm_u,
  input  logic io_in_0_bits_s2_entry_perm_x,
  input  logic io_in_0_bits_s2_entry_perm_w,
  input  logic io_in_0_bits_s2_entry_perm_r,
  input  logic [1:0] io_in_0_bits_s2_entry_level,
  input  logic io_in_0_bits_s2_gpf,
  input  logic io_in_0_bits_s2_gaf,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [1:0] io_out_bits_s2xlate,
  output logic [34:0] io_out_bits_s1_entry_tag,
  output logic [15:0] io_out_bits_s1_entry_asid,
  output logic [13:0] io_out_bits_s1_entry_vmid,
  output logic io_out_bits_s1_entry_n,
  output logic [1:0] io_out_bits_s1_entry_pbmt,
  output logic io_out_bits_s1_entry_perm_d,
  output logic io_out_bits_s1_entry_perm_a,
  output logic io_out_bits_s1_entry_perm_g,
  output logic io_out_bits_s1_entry_perm_u,
  output logic io_out_bits_s1_entry_perm_x,
  output logic io_out_bits_s1_entry_perm_w,
  output logic io_out_bits_s1_entry_perm_r,
  output logic [1:0] io_out_bits_s1_entry_level,
  output logic io_out_bits_s1_entry_v,
  output logic [40:0] io_out_bits_s1_entry_ppn,
  output logic [2:0] io_out_bits_s1_addr_low,
  output logic [2:0] io_out_bits_s1_ppn_low_0,
  output logic [2:0] io_out_bits_s1_ppn_low_1,
  output logic [2:0] io_out_bits_s1_ppn_low_2,
  output logic [2:0] io_out_bits_s1_ppn_low_3,
  output logic [2:0] io_out_bits_s1_ppn_low_4,
  output logic [2:0] io_out_bits_s1_ppn_low_5,
  output logic [2:0] io_out_bits_s1_ppn_low_6,
  output logic [2:0] io_out_bits_s1_ppn_low_7,
  output logic io_out_bits_s1_valididx_0,
  output logic io_out_bits_s1_valididx_1,
  output logic io_out_bits_s1_valididx_2,
  output logic io_out_bits_s1_valididx_3,
  output logic io_out_bits_s1_valididx_4,
  output logic io_out_bits_s1_valididx_5,
  output logic io_out_bits_s1_valididx_6,
  output logic io_out_bits_s1_valididx_7,
  output logic io_out_bits_s1_pteidx_0,
  output logic io_out_bits_s1_pteidx_1,
  output logic io_out_bits_s1_pteidx_2,
  output logic io_out_bits_s1_pteidx_3,
  output logic io_out_bits_s1_pteidx_4,
  output logic io_out_bits_s1_pteidx_5,
  output logic io_out_bits_s1_pteidx_6,
  output logic io_out_bits_s1_pteidx_7,
  output logic io_out_bits_s1_pf,
  output logic io_out_bits_s1_af,
  output logic [37:0] io_out_bits_s2_entry_tag,
  output logic [13:0] io_out_bits_s2_entry_vmid,
  output logic io_out_bits_s2_entry_n,
  output logic [1:0] io_out_bits_s2_entry_pbmt,
  output logic [37:0] io_out_bits_s2_entry_ppn,
  output logic io_out_bits_s2_entry_perm_d,
  output logic io_out_bits_s2_entry_perm_a,
  output logic io_out_bits_s2_entry_perm_g,
  output logic io_out_bits_s2_entry_perm_u,
  output logic io_out_bits_s2_entry_perm_x,
  output logic io_out_bits_s2_entry_perm_w,
  output logic io_out_bits_s2_entry_perm_r,
  output logic [1:0] io_out_bits_s2_entry_level,
  output logic io_out_bits_s2_gpf,
  output logic io_out_bits_s2_gaf
);

  // --------------------------------------------------------------------------
  // 直通：单入口时"选中的那一路"永远是第 0 路
  // --------------------------------------------------------------------------
  assign io_in_0_ready = io_out_ready;
  assign io_out_valid  = io_in_0_valid;
  assign io_out_bits_s2xlate         = io_in_0_bits_s2xlate;
  assign io_out_bits_s1_entry_tag    = io_in_0_bits_s1_entry_tag;
  assign io_out_bits_s1_entry_asid   = io_in_0_bits_s1_entry_asid;
  assign io_out_bits_s1_entry_vmid   = io_in_0_bits_s1_entry_vmid;
  assign io_out_bits_s1_entry_n      = io_in_0_bits_s1_entry_n;
  assign io_out_bits_s1_entry_pbmt   = io_in_0_bits_s1_entry_pbmt;
  assign io_out_bits_s1_entry_perm_d = io_in_0_bits_s1_entry_perm_d;
  assign io_out_bits_s1_entry_perm_a = io_in_0_bits_s1_entry_perm_a;
  assign io_out_bits_s1_entry_perm_g = io_in_0_bits_s1_entry_perm_g;
  assign io_out_bits_s1_entry_perm_u = io_in_0_bits_s1_entry_perm_u;
  assign io_out_bits_s1_entry_perm_x = io_in_0_bits_s1_entry_perm_x;
  assign io_out_bits_s1_entry_perm_w = io_in_0_bits_s1_entry_perm_w;
  assign io_out_bits_s1_entry_perm_r = io_in_0_bits_s1_entry_perm_r;
  assign io_out_bits_s1_entry_level  = io_in_0_bits_s1_entry_level;
  assign io_out_bits_s1_entry_v      = io_in_0_bits_s1_entry_v;
  assign io_out_bits_s1_entry_ppn    = io_in_0_bits_s1_entry_ppn;
  assign io_out_bits_s1_addr_low     = io_in_0_bits_s1_addr_low;
  assign io_out_bits_s1_ppn_low_0    = io_in_0_bits_s1_ppn_low_0;
  assign io_out_bits_s1_ppn_low_1    = io_in_0_bits_s1_ppn_low_1;
  assign io_out_bits_s1_ppn_low_2    = io_in_0_bits_s1_ppn_low_2;
  assign io_out_bits_s1_ppn_low_3    = io_in_0_bits_s1_ppn_low_3;
  assign io_out_bits_s1_ppn_low_4    = io_in_0_bits_s1_ppn_low_4;
  assign io_out_bits_s1_ppn_low_5    = io_in_0_bits_s1_ppn_low_5;
  assign io_out_bits_s1_ppn_low_6    = io_in_0_bits_s1_ppn_low_6;
  assign io_out_bits_s1_ppn_low_7    = io_in_0_bits_s1_ppn_low_7;
  assign io_out_bits_s1_valididx_0   = io_in_0_bits_s1_valididx_0;
  assign io_out_bits_s1_valididx_1   = io_in_0_bits_s1_valididx_1;
  assign io_out_bits_s1_valididx_2   = io_in_0_bits_s1_valididx_2;
  assign io_out_bits_s1_valididx_3   = io_in_0_bits_s1_valididx_3;
  assign io_out_bits_s1_valididx_4   = io_in_0_bits_s1_valididx_4;
  assign io_out_bits_s1_valididx_5   = io_in_0_bits_s1_valididx_5;
  assign io_out_bits_s1_valididx_6   = io_in_0_bits_s1_valididx_6;
  assign io_out_bits_s1_valididx_7   = io_in_0_bits_s1_valididx_7;
  assign io_out_bits_s1_pteidx_0     = io_in_0_bits_s1_pteidx_0;
  assign io_out_bits_s1_pteidx_1     = io_in_0_bits_s1_pteidx_1;
  assign io_out_bits_s1_pteidx_2     = io_in_0_bits_s1_pteidx_2;
  assign io_out_bits_s1_pteidx_3     = io_in_0_bits_s1_pteidx_3;
  assign io_out_bits_s1_pteidx_4     = io_in_0_bits_s1_pteidx_4;
  assign io_out_bits_s1_pteidx_5     = io_in_0_bits_s1_pteidx_5;
  assign io_out_bits_s1_pteidx_6     = io_in_0_bits_s1_pteidx_6;
  assign io_out_bits_s1_pteidx_7     = io_in_0_bits_s1_pteidx_7;
  assign io_out_bits_s1_pf           = io_in_0_bits_s1_pf;
  assign io_out_bits_s1_af           = io_in_0_bits_s1_af;
  assign io_out_bits_s2_entry_tag    = io_in_0_bits_s2_entry_tag;
  assign io_out_bits_s2_entry_vmid   = io_in_0_bits_s2_entry_vmid;
  assign io_out_bits_s2_entry_n      = io_in_0_bits_s2_entry_n;
  assign io_out_bits_s2_entry_pbmt   = io_in_0_bits_s2_entry_pbmt;
  assign io_out_bits_s2_entry_ppn    = io_in_0_bits_s2_entry_ppn;
  assign io_out_bits_s2_entry_perm_d = io_in_0_bits_s2_entry_perm_d;
  assign io_out_bits_s2_entry_perm_a = io_in_0_bits_s2_entry_perm_a;
  assign io_out_bits_s2_entry_perm_g = io_in_0_bits_s2_entry_perm_g;
  assign io_out_bits_s2_entry_perm_u = io_in_0_bits_s2_entry_perm_u;
  assign io_out_bits_s2_entry_perm_x = io_in_0_bits_s2_entry_perm_x;
  assign io_out_bits_s2_entry_perm_w = io_in_0_bits_s2_entry_perm_w;
  assign io_out_bits_s2_entry_perm_r = io_in_0_bits_s2_entry_perm_r;
  assign io_out_bits_s2_entry_level  = io_in_0_bits_s2_entry_level;
  assign io_out_bits_s2_gpf          = io_in_0_bits_s2_gpf;
  assign io_out_bits_s2_gaf          = io_in_0_bits_s2_gaf;

endmodule
