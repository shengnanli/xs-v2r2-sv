// 自动生成: verif/bt/MemBlock/gen_difftest_stub.py —— 勿手改
// 访存子系统 golden 子模块例化的 difftest DPI 探针(DummyDPICWrapper_*)均为 input-only,
// 对设计无任何反向驱动。BT 双例化里(u_g/u_i)用同一份空壳替代其 DiffExt*Event DPI 实现,
// 与 MemBlock UT 里 VCS 静默自建空 cell 等价(UT errors=0)。DelayReg_* 含输出, 用 golden 真定义。
module DummyDPICWrapper(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_addr,
  input [63:0] io_bits_data_0,
  input [63:0] io_bits_data_1,
  input [63:0] io_bits_data_2,
  input [63:0] io_bits_data_3,
  input [63:0] io_bits_data_4,
  input [63:0] io_bits_data_5,
  input [63:0] io_bits_data_6,
  input [63:0] io_bits_data_7,
  input [7:0]  io_bits_coreid,
  input [7:0]  io_bits_index
);
endmodule

module DummyDPICWrapper_71(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_addr,
  input [7:0]  io_bits_data_0,
  input [7:0]  io_bits_data_1,
  input [7:0]  io_bits_data_2,
  input [7:0]  io_bits_data_3,
  input [7:0]  io_bits_data_4,
  input [7:0]  io_bits_data_5,
  input [7:0]  io_bits_data_6,
  input [7:0]  io_bits_data_7,
  input [7:0]  io_bits_mask,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_73(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input        io_bits_valididx_0,
  input        io_bits_valididx_1,
  input        io_bits_valididx_2,
  input        io_bits_valididx_3,
  input        io_bits_valididx_4,
  input        io_bits_valididx_5,
  input        io_bits_valididx_6,
  input        io_bits_valididx_7,
  input [63:0] io_bits_satp,
  input [63:0] io_bits_vpn,
  input [1:0]  io_bits_pbmt,
  input [1:0]  io_bits_g_pbmt,
  input [63:0] io_bits_ppn_0,
  input [63:0] io_bits_ppn_1,
  input [63:0] io_bits_ppn_2,
  input [63:0] io_bits_ppn_3,
  input [63:0] io_bits_ppn_4,
  input [63:0] io_bits_ppn_5,
  input [63:0] io_bits_ppn_6,
  input [63:0] io_bits_ppn_7,
  input [7:0]  io_bits_perm,
  input [7:0]  io_bits_level,
  input        io_bits_pf,
  input        io_bits_pteidx_0,
  input        io_bits_pteidx_1,
  input        io_bits_pteidx_2,
  input        io_bits_pteidx_3,
  input        io_bits_pteidx_4,
  input        io_bits_pteidx_5,
  input        io_bits_pteidx_6,
  input        io_bits_pteidx_7,
  input [63:0] io_bits_vsatp,
  input [63:0] io_bits_hgatp,
  input [63:0] io_bits_gvpn,
  input [7:0]  io_bits_g_perm,
  input [7:0]  io_bits_g_level,
  input [63:0] io_bits_s2ppn,
  input        io_bits_gpf,
  input [1:0]  io_bits_s2xlate,
  input [7:0]  io_bits_coreid,
  input [7:0]  io_bits_index
);
endmodule

module DummyDPICWrapper_75(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_addr,
  input [63:0] io_bits_data_0,
  input [63:0] io_bits_data_1,
  input [15:0] io_bits_mask,
  input [63:0] io_bits_cmp_0,
  input [63:0] io_bits_cmp_1,
  input [7:0]  io_bits_fuop,
  input [63:0] io_bits_out_0,
  input [63:0] io_bits_out_1,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_76(

  input       clock,
  input       io_valid,
  input       io_bits_valid,
  input       io_bits_success,
  input [7:0] io_bits_coreid
);
endmodule

module DummyDPICWrapper_77(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_addr,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_78(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_addr,
  input [7:0]  io_bits_data_0,
  input [7:0]  io_bits_data_1,
  input [7:0]  io_bits_data_2,
  input [7:0]  io_bits_data_3,
  input [7:0]  io_bits_data_4,
  input [7:0]  io_bits_data_5,
  input [7:0]  io_bits_data_6,
  input [7:0]  io_bits_data_7,
  input [7:0]  io_bits_data_8,
  input [7:0]  io_bits_data_9,
  input [7:0]  io_bits_data_10,
  input [7:0]  io_bits_data_11,
  input [7:0]  io_bits_data_12,
  input [7:0]  io_bits_data_13,
  input [7:0]  io_bits_data_14,
  input [7:0]  io_bits_data_15,
  input [7:0]  io_bits_data_16,
  input [7:0]  io_bits_data_17,
  input [7:0]  io_bits_data_18,
  input [7:0]  io_bits_data_19,
  input [7:0]  io_bits_data_20,
  input [7:0]  io_bits_data_21,
  input [7:0]  io_bits_data_22,
  input [7:0]  io_bits_data_23,
  input [7:0]  io_bits_data_24,
  input [7:0]  io_bits_data_25,
  input [7:0]  io_bits_data_26,
  input [7:0]  io_bits_data_27,
  input [7:0]  io_bits_data_28,
  input [7:0]  io_bits_data_29,
  input [7:0]  io_bits_data_30,
  input [7:0]  io_bits_data_31,
  input [7:0]  io_bits_data_32,
  input [7:0]  io_bits_data_33,
  input [7:0]  io_bits_data_34,
  input [7:0]  io_bits_data_35,
  input [7:0]  io_bits_data_36,
  input [7:0]  io_bits_data_37,
  input [7:0]  io_bits_data_38,
  input [7:0]  io_bits_data_39,
  input [7:0]  io_bits_data_40,
  input [7:0]  io_bits_data_41,
  input [7:0]  io_bits_data_42,
  input [7:0]  io_bits_data_43,
  input [7:0]  io_bits_data_44,
  input [7:0]  io_bits_data_45,
  input [7:0]  io_bits_data_46,
  input [7:0]  io_bits_data_47,
  input [7:0]  io_bits_data_48,
  input [7:0]  io_bits_data_49,
  input [7:0]  io_bits_data_50,
  input [7:0]  io_bits_data_51,
  input [7:0]  io_bits_data_52,
  input [7:0]  io_bits_data_53,
  input [7:0]  io_bits_data_54,
  input [7:0]  io_bits_data_55,
  input [7:0]  io_bits_data_56,
  input [7:0]  io_bits_data_57,
  input [7:0]  io_bits_data_58,
  input [7:0]  io_bits_data_59,
  input [7:0]  io_bits_data_60,
  input [7:0]  io_bits_data_61,
  input [7:0]  io_bits_data_62,
  input [7:0]  io_bits_data_63,
  input [63:0] io_bits_mask,
  input [7:0]  io_bits_coreid
);
endmodule

module DummyDPICWrapper_79(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_addr,
  input [63:0] io_bits_data,
  input [7:0]  io_bits_mask,
  input [63:0] io_bits_pc,
  input [9:0]  io_bits_robidx,
  input [7:0]  io_bits_coreid,
  input [7:0]  io_bits_index
);
endmodule

module DummyDPICWrapper_9(

  input        clock,
  input        io_valid,
  input        io_bits_valid,
  input [63:0] io_bits_satp,
  input [63:0] io_bits_vpn,
  input [63:0] io_bits_ppn,
  input [63:0] io_bits_vsatp,
  input [63:0] io_bits_hgatp,
  input [1:0]  io_bits_s2xlate,
  input [7:0]  io_bits_coreid,
  input [7:0]  io_bits_index
);
endmodule

