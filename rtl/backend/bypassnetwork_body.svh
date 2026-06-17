// 自动生成:scripts/gen_bypassnetwork.py —— 勿手改

// 由 xs_BypassNetwork_core 通过 `include 引入:643 个输出的端口级互联。
// 源操作数调用核内 sel_* 函数;其余 bits 直通、valid 前向、ready 反向;
// toDataPath 接 RegCache 回写;ImmExtractor(立即数扩展)作黑盒实例化。

  // ---- 立即数扩展输出网(ImmExtractor 黑盒输出)----
  logic [63:0] _imm_mod_io_out_imm;
  logic [63:0] _imm_mod_1_io_out_imm;
  logic [63:0] _imm_mod_2_io_out_imm;
  logic [63:0] _imm_mod_3_io_out_imm;
  logic [63:0] _imm_mod_4_io_out_imm;
  logic [63:0] _imm_mod_5_io_out_imm;
  logic [63:0] _imm_mod_6_io_out_imm;
  logic [63:0] _imm_mod_7_io_out_imm;
  logic [63:0] _imm_mod_8_io_out_imm;
  logic [63:0] _imm_mod_9_io_out_imm;
  logic [63:0] _imm_mod_10_io_out_imm;
  logic [63:0] _imm_mod_11_io_out_imm;
  logic [127:0] _imm_mod_12_io_out_imm;
  logic [127:0] _imm_mod_13_io_out_imm;
  logic [127:0] _imm_mod_14_io_out_imm;
  logic [63:0] _imm_mod_15_io_out_imm;
  logic [63:0] _imm_mod_16_io_out_imm;
  logic [127:0] _imm_mod_37_io_out_imm;
  logic [127:0] _imm_mod_38_io_out_imm;
  logic [127:0] _imm_mod_39_io_out_imm;
  logic [127:0] _imm_mod_40_io_out_imm;
  logic [127:0] _imm_mod_41_io_out_imm;
  logic [63:0] _imm_mod_57_io_out_imm;
  logic [63:0] _imm_mod_58_io_out_imm;

  // ---- 立即数扩展(ImmExtractor 黑盒;按 immType 把 imm 扩展到目标位宽)----
  ImmExtractor imm_mod (.io_in_imm (io_fromDataPath_immInfo_0_imm), .io_in_immType (io_fromDataPath_immInfo_0_immType), .io_out_imm (_imm_mod_io_out_imm));
  ImmExtractor imm_mod_1 (.io_in_imm (io_fromDataPath_immInfo_0_imm), .io_in_immType (io_fromDataPath_immInfo_0_immType), .io_out_imm (_imm_mod_1_io_out_imm));
  ImmExtractor_2 imm_mod_2 (.io_in_imm (io_fromDataPath_immInfo_1_imm), .io_in_immType (io_fromDataPath_immInfo_1_immType), .io_out_imm (_imm_mod_2_io_out_imm));
  ImmExtractor_2 imm_mod_3 (.io_in_imm (io_fromDataPath_immInfo_1_imm), .io_in_immType (io_fromDataPath_immInfo_1_immType), .io_out_imm (_imm_mod_3_io_out_imm));
  ImmExtractor_2 imm_mod_4 (.io_in_imm (io_fromDataPath_immInfo_1_imm), .io_in_immType (io_fromDataPath_immInfo_1_immType), .io_out_imm (_imm_mod_4_io_out_imm));
  ImmExtractor imm_mod_5 (.io_in_imm (io_fromDataPath_immInfo_2_imm), .io_in_immType (io_fromDataPath_immInfo_2_immType), .io_out_imm (_imm_mod_5_io_out_imm));
  ImmExtractor imm_mod_6 (.io_in_imm (io_fromDataPath_immInfo_2_imm), .io_in_immType (io_fromDataPath_immInfo_2_immType), .io_out_imm (_imm_mod_6_io_out_imm));
  ImmExtractor_2 imm_mod_7 (.io_in_imm (io_fromDataPath_immInfo_3_imm), .io_in_immType (io_fromDataPath_immInfo_3_immType), .io_out_imm (_imm_mod_7_io_out_imm));
  ImmExtractor_2 imm_mod_8 (.io_in_imm (io_fromDataPath_immInfo_3_imm), .io_in_immType (io_fromDataPath_immInfo_3_immType), .io_out_imm (_imm_mod_8_io_out_imm));
  ImmExtractor_2 imm_mod_9 (.io_in_imm (io_fromDataPath_immInfo_3_imm), .io_in_immType (io_fromDataPath_immInfo_3_immType), .io_out_imm (_imm_mod_9_io_out_imm));
  ImmExtractor imm_mod_10 (.io_in_imm (io_fromDataPath_immInfo_4_imm), .io_in_immType (io_fromDataPath_immInfo_4_immType), .io_out_imm (_imm_mod_10_io_out_imm));
  ImmExtractor imm_mod_11 (.io_in_imm (io_fromDataPath_immInfo_4_imm), .io_in_immType (io_fromDataPath_immInfo_4_immType), .io_out_imm (_imm_mod_11_io_out_imm));
  ImmExtractor_12 imm_mod_12 (.io_in_imm (io_fromDataPath_immInfo_5_imm), .io_in_immType (io_fromDataPath_immInfo_5_immType), .io_out_imm (_imm_mod_12_io_out_imm));
  ImmExtractor_12 imm_mod_13 (.io_in_imm (io_fromDataPath_immInfo_5_imm), .io_in_immType (io_fromDataPath_immInfo_5_immType), .io_out_imm (_imm_mod_13_io_out_imm));
  ImmExtractor_12 imm_mod_14 (.io_in_imm (io_fromDataPath_immInfo_5_imm), .io_in_immType (io_fromDataPath_immInfo_5_immType), .io_out_imm (_imm_mod_14_io_out_imm));
  ImmExtractor imm_mod_15 (.io_in_imm (io_fromDataPath_immInfo_6_imm), .io_in_immType (io_fromDataPath_immInfo_6_immType), .io_out_imm (_imm_mod_15_io_out_imm));
  ImmExtractor imm_mod_16 (.io_in_imm (io_fromDataPath_immInfo_6_imm), .io_in_immType (io_fromDataPath_immInfo_6_immType), .io_out_imm (_imm_mod_16_io_out_imm));
  ImmExtractor_37 imm_mod_37 (.io_in_imm (io_fromDataPath_immInfo_14_imm), .io_in_immType (io_fromDataPath_immInfo_14_immType), .io_out_imm (_imm_mod_37_io_out_imm));
  ImmExtractor_37 imm_mod_38 (.io_in_imm (io_fromDataPath_immInfo_14_imm), .io_in_immType (io_fromDataPath_immInfo_14_immType), .io_out_imm (_imm_mod_38_io_out_imm));
  ImmExtractor_37 imm_mod_39 (.io_in_imm (io_fromDataPath_immInfo_14_imm), .io_in_immType (io_fromDataPath_immInfo_14_immType), .io_out_imm (_imm_mod_39_io_out_imm));
  ImmExtractor_37 imm_mod_40 (.io_in_imm (io_fromDataPath_immInfo_14_imm), .io_in_immType (io_fromDataPath_immInfo_14_immType), .io_out_imm (_imm_mod_40_io_out_imm));
  ImmExtractor_37 imm_mod_41 (.io_in_imm (io_fromDataPath_immInfo_14_imm), .io_in_immType (io_fromDataPath_immInfo_14_immType), .io_out_imm (_imm_mod_41_io_out_imm));
  ImmExtractor_57 imm_mod_57 (.io_in_imm (io_fromDataPath_immInfo_18_imm), .io_in_immType (io_fromDataPath_immInfo_18_immType), .io_out_imm (_imm_mod_57_io_out_imm));
  ImmExtractor_57 imm_mod_58 (.io_in_imm (io_fromDataPath_immInfo_19_imm), .io_in_immType (io_fromDataPath_immInfo_19_immType), .io_out_imm (_imm_mod_58_io_out_imm));

  // ---- 源操作数旁路选择(调用核内 sel_*)----
  always_comb io_toExus_int_3_1_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_int_3_1_bits_dataSources_0_value),
    pick_int(io_fromDataPath_int_3_1_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_int_3_1_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_int_3_1_bits_src_0, io_fromDataPath_rcData_3_1_0, '0);
  always_comb io_toExus_int_3_1_bits_src_1 = sel_int_src(data_source_e'(io_fromDataPath_int_3_1_bits_dataSources_1_value),
    pick_int(io_fromDataPath_int_3_1_bits_exuSources_1_value, int_fwd_bus), pick_int(io_fromDataPath_int_3_1_bits_exuSources_1_value, int_byp_bus),
    io_fromDataPath_int_3_1_bits_src_1, io_fromDataPath_rcData_3_1_1, '0);
  always_comb io_toExus_int_3_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_int_3_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_int_3_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_int_3_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_int_3_0_bits_src_0, io_fromDataPath_rcData_3_0_0, _imm_mod_15_io_out_imm);
  always_comb io_toExus_int_3_0_bits_src_1 = sel_int_src(data_source_e'(io_fromDataPath_int_3_0_bits_dataSources_1_value),
    pick_int(io_fromDataPath_int_3_0_bits_exuSources_1_value, int_fwd_bus), pick_int(io_fromDataPath_int_3_0_bits_exuSources_1_value, int_byp_bus),
    io_fromDataPath_int_3_0_bits_src_1, io_fromDataPath_rcData_3_0_1, _imm_mod_16_io_out_imm);
  always_comb io_toExus_int_2_1_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_int_2_1_bits_dataSources_0_value),
    pick_int(io_fromDataPath_int_2_1_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_int_2_1_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_int_2_1_bits_src_0, io_fromDataPath_rcData_2_1_0, _imm_mod_12_io_out_imm);
  always_comb io_toExus_int_2_1_bits_src_1 = sel_int_src(data_source_e'(io_fromDataPath_int_2_1_bits_dataSources_1_value),
    pick_int(io_fromDataPath_int_2_1_bits_exuSources_1_value, int_fwd_bus), pick_int(io_fromDataPath_int_2_1_bits_exuSources_1_value, int_byp_bus),
    io_fromDataPath_int_2_1_bits_src_1, io_fromDataPath_rcData_2_1_1, _imm_mod_13_io_out_imm);
  always_comb io_toExus_int_2_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_int_2_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_int_2_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_int_2_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_int_2_0_bits_src_0, io_fromDataPath_rcData_2_0_0, _imm_mod_10_io_out_imm);
  always_comb io_toExus_int_2_0_bits_src_1 = sel_int_src(data_source_e'(io_fromDataPath_int_2_0_bits_dataSources_1_value),
    pick_int(io_fromDataPath_int_2_0_bits_exuSources_1_value, int_fwd_bus), pick_int(io_fromDataPath_int_2_0_bits_exuSources_1_value, int_byp_bus),
    io_fromDataPath_int_2_0_bits_src_1, io_fromDataPath_rcData_2_0_1, _imm_mod_11_io_out_imm);
  always_comb io_toExus_int_1_1_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_int_1_1_bits_dataSources_0_value),
    pick_int(io_fromDataPath_int_1_1_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_int_1_1_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_int_1_1_bits_src_0, io_fromDataPath_rcData_1_1_0, _imm_mod_7_io_out_imm);
  always_comb io_toExus_int_1_1_bits_src_1 = sel_int_src(data_source_e'(io_fromDataPath_int_1_1_bits_dataSources_1_value),
    pick_int(io_fromDataPath_int_1_1_bits_exuSources_1_value, int_fwd_bus), pick_int(io_fromDataPath_int_1_1_bits_exuSources_1_value, int_byp_bus),
    io_fromDataPath_int_1_1_bits_src_1, io_fromDataPath_rcData_1_1_1, _imm_mod_8_io_out_imm);
  always_comb io_toExus_int_1_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_int_1_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_int_1_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_int_1_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_int_1_0_bits_src_0, io_fromDataPath_rcData_1_0_0, _imm_mod_5_io_out_imm);
  always_comb io_toExus_int_1_0_bits_src_1 = sel_int_src(data_source_e'(io_fromDataPath_int_1_0_bits_dataSources_1_value),
    pick_int(io_fromDataPath_int_1_0_bits_exuSources_1_value, int_fwd_bus), pick_int(io_fromDataPath_int_1_0_bits_exuSources_1_value, int_byp_bus),
    io_fromDataPath_int_1_0_bits_src_1, io_fromDataPath_rcData_1_0_1, _imm_mod_6_io_out_imm);
  always_comb io_toExus_int_0_1_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_int_0_1_bits_dataSources_0_value),
    pick_int(io_fromDataPath_int_0_1_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_int_0_1_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_int_0_1_bits_src_0, io_fromDataPath_rcData_0_1_0, _imm_mod_2_io_out_imm);
  always_comb io_toExus_int_0_1_bits_src_1 = sel_int_src(data_source_e'(io_fromDataPath_int_0_1_bits_dataSources_1_value),
    pick_int(io_fromDataPath_int_0_1_bits_exuSources_1_value, int_fwd_bus), pick_int(io_fromDataPath_int_0_1_bits_exuSources_1_value, int_byp_bus),
    io_fromDataPath_int_0_1_bits_src_1, io_fromDataPath_rcData_0_1_1, _imm_mod_3_io_out_imm);
  always_comb io_toExus_int_0_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_int_0_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_int_0_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_int_0_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_int_0_0_bits_src_0, io_fromDataPath_rcData_0_0_0, _imm_mod_io_out_imm);
  always_comb io_toExus_int_0_0_bits_src_1 = sel_int_src(data_source_e'(io_fromDataPath_int_0_0_bits_dataSources_1_value),
    pick_int(io_fromDataPath_int_0_0_bits_exuSources_1_value, int_fwd_bus), pick_int(io_fromDataPath_int_0_0_bits_exuSources_1_value, int_byp_bus),
    io_fromDataPath_int_0_0_bits_src_1, io_fromDataPath_rcData_0_0_1, _imm_mod_1_io_out_imm);
  always_comb io_toExus_fp_2_0_bits_src_0 = sel_fp_src(data_source_e'(io_fromDataPath_fp_2_0_bits_dataSources_0_value),
    pick_fp(io_fromDataPath_fp_2_0_bits_exuSources_0_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_2_0_bits_exuSources_0_value, fp_byp_bus),
    io_fromDataPath_fp_2_0_bits_src_0);
  always_comb io_toExus_fp_2_0_bits_src_1 = sel_fp_src(data_source_e'(io_fromDataPath_fp_2_0_bits_dataSources_1_value),
    pick_fp(io_fromDataPath_fp_2_0_bits_exuSources_1_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_2_0_bits_exuSources_1_value, fp_byp_bus),
    io_fromDataPath_fp_2_0_bits_src_1);
  always_comb io_toExus_fp_2_0_bits_src_2 = sel_fp_src(data_source_e'(io_fromDataPath_fp_2_0_bits_dataSources_2_value),
    pick_fp(io_fromDataPath_fp_2_0_bits_exuSources_2_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_2_0_bits_exuSources_2_value, fp_byp_bus),
    io_fromDataPath_fp_2_0_bits_src_2);
  always_comb io_toExus_fp_1_1_bits_src_0 = sel_fp_src(data_source_e'(io_fromDataPath_fp_1_1_bits_dataSources_0_value),
    pick_fp(io_fromDataPath_fp_1_1_bits_exuSources_0_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_1_1_bits_exuSources_0_value, fp_byp_bus),
    io_fromDataPath_fp_1_1_bits_src_0);
  always_comb io_toExus_fp_1_1_bits_src_1 = sel_fp_src(data_source_e'(io_fromDataPath_fp_1_1_bits_dataSources_1_value),
    pick_fp(io_fromDataPath_fp_1_1_bits_exuSources_1_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_1_1_bits_exuSources_1_value, fp_byp_bus),
    io_fromDataPath_fp_1_1_bits_src_1);
  always_comb io_toExus_fp_1_0_bits_src_0 = sel_fp_src(data_source_e'(io_fromDataPath_fp_1_0_bits_dataSources_0_value),
    pick_fp(io_fromDataPath_fp_1_0_bits_exuSources_0_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_1_0_bits_exuSources_0_value, fp_byp_bus),
    io_fromDataPath_fp_1_0_bits_src_0);
  always_comb io_toExus_fp_1_0_bits_src_1 = sel_fp_src(data_source_e'(io_fromDataPath_fp_1_0_bits_dataSources_1_value),
    pick_fp(io_fromDataPath_fp_1_0_bits_exuSources_1_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_1_0_bits_exuSources_1_value, fp_byp_bus),
    io_fromDataPath_fp_1_0_bits_src_1);
  always_comb io_toExus_fp_1_0_bits_src_2 = sel_fp_src(data_source_e'(io_fromDataPath_fp_1_0_bits_dataSources_2_value),
    pick_fp(io_fromDataPath_fp_1_0_bits_exuSources_2_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_1_0_bits_exuSources_2_value, fp_byp_bus),
    io_fromDataPath_fp_1_0_bits_src_2);
  always_comb io_toExus_fp_0_1_bits_src_0 = sel_fp_src(data_source_e'(io_fromDataPath_fp_0_1_bits_dataSources_0_value),
    pick_fp(io_fromDataPath_fp_0_1_bits_exuSources_0_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_0_1_bits_exuSources_0_value, fp_byp_bus),
    io_fromDataPath_fp_0_1_bits_src_0);
  always_comb io_toExus_fp_0_1_bits_src_1 = sel_fp_src(data_source_e'(io_fromDataPath_fp_0_1_bits_dataSources_1_value),
    pick_fp(io_fromDataPath_fp_0_1_bits_exuSources_1_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_0_1_bits_exuSources_1_value, fp_byp_bus),
    io_fromDataPath_fp_0_1_bits_src_1);
  always_comb io_toExus_fp_0_0_bits_src_0 = sel_fp_src(data_source_e'(io_fromDataPath_fp_0_0_bits_dataSources_0_value),
    pick_fp(io_fromDataPath_fp_0_0_bits_exuSources_0_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_0_0_bits_exuSources_0_value, fp_byp_bus),
    io_fromDataPath_fp_0_0_bits_src_0);
  always_comb io_toExus_fp_0_0_bits_src_1 = sel_fp_src(data_source_e'(io_fromDataPath_fp_0_0_bits_dataSources_1_value),
    pick_fp(io_fromDataPath_fp_0_0_bits_exuSources_1_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_0_0_bits_exuSources_1_value, fp_byp_bus),
    io_fromDataPath_fp_0_0_bits_src_1);
  always_comb io_toExus_fp_0_0_bits_src_2 = sel_fp_src(data_source_e'(io_fromDataPath_fp_0_0_bits_dataSources_2_value),
    pick_fp(io_fromDataPath_fp_0_0_bits_exuSources_2_value, fp_fwd_bus), pick_fp(io_fromDataPath_fp_0_0_bits_exuSources_2_value, fp_byp_bus),
    io_fromDataPath_fp_0_0_bits_src_2);
  always_comb io_toExus_vf_2_0_bits_src_0 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_2_0_bits_dataSources_0_value), io_toExus_vf_2_0_bits_src_3, io_fromDataPath_vf_2_0_bits_src_0, '0);
  always_comb io_toExus_vf_2_0_bits_src_1 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_2_0_bits_dataSources_1_value), io_toExus_vf_2_0_bits_src_3, io_fromDataPath_vf_2_0_bits_src_1, '0);
  always_comb io_toExus_vf_2_0_bits_src_2 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_2_0_bits_dataSources_2_value), io_toExus_vf_2_0_bits_src_3, io_fromDataPath_vf_2_0_bits_src_2, '0);
  always_comb io_toExus_vf_2_0_bits_src_3 = sel_vec_src(data_source_e'(io_fromDataPath_vf_2_0_bits_dataSources_3_value), '0, io_fromDataPath_vf_2_0_bits_src_3, '0);
  always_comb io_toExus_vf_2_0_bits_src_4 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_2_0_bits_dataSources_4_value), '0, io_fromDataPath_vf_2_0_bits_src_4, '0);
  always_comb io_toExus_vf_1_1_bits_src_0 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_1_1_bits_dataSources_0_value), io_toExus_vf_1_1_bits_src_3, io_fromDataPath_vf_1_1_bits_src_0, '0);
  always_comb io_toExus_vf_1_1_bits_src_1 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_1_1_bits_dataSources_1_value), io_toExus_vf_1_1_bits_src_3, io_fromDataPath_vf_1_1_bits_src_1, '0);
  always_comb io_toExus_vf_1_1_bits_src_2 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_1_1_bits_dataSources_2_value), io_toExus_vf_1_1_bits_src_3, io_fromDataPath_vf_1_1_bits_src_2, '0);
  always_comb io_toExus_vf_1_1_bits_src_3 = sel_vec_src(data_source_e'(io_fromDataPath_vf_1_1_bits_dataSources_3_value), '0, io_fromDataPath_vf_1_1_bits_src_3, '0);
  always_comb io_toExus_vf_1_1_bits_src_4 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_1_1_bits_dataSources_4_value), '0, io_fromDataPath_vf_1_1_bits_src_4, '0);
  always_comb io_toExus_vf_1_0_bits_src_0 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_1_0_bits_dataSources_0_value), io_toExus_vf_1_0_bits_src_3, io_fromDataPath_vf_1_0_bits_src_0, '0);
  always_comb io_toExus_vf_1_0_bits_src_1 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_1_0_bits_dataSources_1_value), io_toExus_vf_1_0_bits_src_3, io_fromDataPath_vf_1_0_bits_src_1, '0);
  always_comb io_toExus_vf_1_0_bits_src_2 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_1_0_bits_dataSources_2_value), io_toExus_vf_1_0_bits_src_3, io_fromDataPath_vf_1_0_bits_src_2, '0);
  always_comb io_toExus_vf_1_0_bits_src_3 = sel_vec_src(data_source_e'(io_fromDataPath_vf_1_0_bits_dataSources_3_value), '0, io_fromDataPath_vf_1_0_bits_src_3, '0);
  always_comb io_toExus_vf_1_0_bits_src_4 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_1_0_bits_dataSources_4_value), '0, io_fromDataPath_vf_1_0_bits_src_4, '0);
  always_comb io_toExus_vf_0_1_bits_src_0 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_0_1_bits_dataSources_0_value), io_toExus_vf_0_1_bits_src_3, io_fromDataPath_vf_0_1_bits_src_0, _imm_mod_37_io_out_imm);
  always_comb io_toExus_vf_0_1_bits_src_1 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_0_1_bits_dataSources_1_value), io_toExus_vf_0_1_bits_src_3, io_fromDataPath_vf_0_1_bits_src_1, _imm_mod_38_io_out_imm);
  always_comb io_toExus_vf_0_1_bits_src_2 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_0_1_bits_dataSources_2_value), io_toExus_vf_0_1_bits_src_3, io_fromDataPath_vf_0_1_bits_src_2, _imm_mod_39_io_out_imm);
  always_comb io_toExus_vf_0_1_bits_src_3 = sel_vec_src(data_source_e'(io_fromDataPath_vf_0_1_bits_dataSources_3_value), '0, io_fromDataPath_vf_0_1_bits_src_3, _imm_mod_40_io_out_imm);
  always_comb io_toExus_vf_0_1_bits_src_4 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_0_1_bits_dataSources_4_value), '0, io_fromDataPath_vf_0_1_bits_src_4, _imm_mod_41_io_out_imm);
  always_comb io_toExus_vf_0_0_bits_src_0 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_0_0_bits_dataSources_0_value), io_toExus_vf_0_0_bits_src_3, io_fromDataPath_vf_0_0_bits_src_0, '0);
  always_comb io_toExus_vf_0_0_bits_src_1 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_0_0_bits_dataSources_1_value), io_toExus_vf_0_0_bits_src_3, io_fromDataPath_vf_0_0_bits_src_1, '0);
  always_comb io_toExus_vf_0_0_bits_src_2 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_0_0_bits_dataSources_2_value), io_toExus_vf_0_0_bits_src_3, io_fromDataPath_vf_0_0_bits_src_2, '0);
  always_comb io_toExus_vf_0_0_bits_src_3 = sel_vec_src(data_source_e'(io_fromDataPath_vf_0_0_bits_dataSources_3_value), '0, io_fromDataPath_vf_0_0_bits_src_3, '0);
  always_comb io_toExus_vf_0_0_bits_src_4 =
    sel_vec_src(data_source_e'(io_fromDataPath_vf_0_0_bits_dataSources_4_value), '0, io_fromDataPath_vf_0_0_bits_src_4, '0);
  always_comb io_toExus_mem_8_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_mem_8_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_mem_8_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_mem_8_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_mem_8_0_bits_src_0, io_fromDataPath_rcData_18_0_0, '0);
  always_comb io_toExus_mem_7_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_mem_7_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_mem_7_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_mem_7_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_mem_7_0_bits_src_0, io_fromDataPath_rcData_17_0_0, '0);
  always_comb io_toExus_mem_6_0_bits_src_0 =
    sel_vec_src(data_source_e'(io_fromDataPath_mem_6_0_bits_dataSources_0_value), io_toExus_mem_6_0_bits_src_3, io_fromDataPath_mem_6_0_bits_src_0, '0);
  always_comb io_toExus_mem_6_0_bits_src_1 =
    sel_vec_src(data_source_e'(io_fromDataPath_mem_6_0_bits_dataSources_1_value), io_toExus_mem_6_0_bits_src_3, io_fromDataPath_mem_6_0_bits_src_1, '0);
  always_comb io_toExus_mem_6_0_bits_src_2 =
    sel_vec_src(data_source_e'(io_fromDataPath_mem_6_0_bits_dataSources_2_value), io_toExus_mem_6_0_bits_src_3, io_fromDataPath_mem_6_0_bits_src_2, '0);
  always_comb io_toExus_mem_6_0_bits_src_3 = sel_vec_src(data_source_e'(io_fromDataPath_mem_6_0_bits_dataSources_3_value), '0, io_fromDataPath_mem_6_0_bits_src_3, '0);
  always_comb io_toExus_mem_6_0_bits_src_4 =
    sel_vec_src(data_source_e'(io_fromDataPath_mem_6_0_bits_dataSources_4_value), '0, io_fromDataPath_mem_6_0_bits_src_4, '0);
  always_comb io_toExus_mem_5_0_bits_src_0 =
    sel_vec_src(data_source_e'(io_fromDataPath_mem_5_0_bits_dataSources_0_value), io_toExus_mem_5_0_bits_src_3, io_fromDataPath_mem_5_0_bits_src_0, '0);
  always_comb io_toExus_mem_5_0_bits_src_1 =
    sel_vec_src(data_source_e'(io_fromDataPath_mem_5_0_bits_dataSources_1_value), io_toExus_mem_5_0_bits_src_3, io_fromDataPath_mem_5_0_bits_src_1, '0);
  always_comb io_toExus_mem_5_0_bits_src_2 =
    sel_vec_src(data_source_e'(io_fromDataPath_mem_5_0_bits_dataSources_2_value), io_toExus_mem_5_0_bits_src_3, io_fromDataPath_mem_5_0_bits_src_2, '0);
  always_comb io_toExus_mem_5_0_bits_src_3 = sel_vec_src(data_source_e'(io_fromDataPath_mem_5_0_bits_dataSources_3_value), '0, io_fromDataPath_mem_5_0_bits_src_3, '0);
  always_comb io_toExus_mem_5_0_bits_src_4 =
    sel_vec_src(data_source_e'(io_fromDataPath_mem_5_0_bits_dataSources_4_value), '0, io_fromDataPath_mem_5_0_bits_src_4, '0);
  always_comb io_toExus_mem_4_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_mem_4_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_mem_4_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_mem_4_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_mem_4_0_bits_src_0, io_fromDataPath_rcData_14_0_0, load_imm_u(io_fromDataPath_immInfo_22_imm[31:0]));
  always_comb io_toExus_mem_3_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_mem_3_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_mem_3_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_mem_3_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_mem_3_0_bits_src_0, io_fromDataPath_rcData_13_0_0, load_imm_u(io_fromDataPath_immInfo_21_imm[31:0]));
  always_comb io_toExus_mem_2_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_mem_2_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_mem_2_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_mem_2_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_mem_2_0_bits_src_0, io_fromDataPath_rcData_12_0_0, load_imm_u(io_fromDataPath_immInfo_20_imm[31:0]));
  always_comb io_toExus_mem_1_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_mem_1_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_mem_1_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_mem_1_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_mem_1_0_bits_src_0, io_fromDataPath_rcData_11_0_0, _imm_mod_58_io_out_imm);
  always_comb io_toExus_mem_0_0_bits_src_0 = sel_int_src(data_source_e'(io_fromDataPath_mem_0_0_bits_dataSources_0_value),
    pick_int(io_fromDataPath_mem_0_0_bits_exuSources_0_value, int_fwd_bus), pick_int(io_fromDataPath_mem_0_0_bits_exuSources_0_value, int_byp_bus),
    io_fromDataPath_mem_0_0_bits_src_0, io_fromDataPath_rcData_10_0_0, _imm_mod_57_io_out_imm);

  // ---- RegCache 回写(7 路 wen/data,各打一拍)----
  assign io_toDataPath_0_wen  = rc_wen[0];
  assign io_toDataPath_0_data = rc_data[0];
  assign io_toDataPath_1_wen  = rc_wen[1];
  assign io_toDataPath_1_data = rc_data[1];
  assign io_toDataPath_2_wen  = rc_wen[2];
  assign io_toDataPath_2_data = rc_data[2];
  assign io_toDataPath_3_wen  = rc_wen[3];
  assign io_toDataPath_3_data = rc_data[3];
  assign io_toDataPath_4_wen  = rc_wen[4];
  assign io_toDataPath_4_data = rc_data[4];
  assign io_toDataPath_5_wen  = rc_wen[5];
  assign io_toDataPath_5_data = rc_data[5];
  assign io_toDataPath_6_wen  = rc_wen[6];
  assign io_toDataPath_6_data = rc_data[6];


  // ---- 分支单元立即数 / nextPcOffset(int_0_1 / 1_1 / 2_1)----
  assign io_toExus_int_2_1_bits_imm = brh_imm(_imm_mod_14_io_out_imm[63:0], (io_fromDataPath_int_2_1_bits_fuType[0] & io_fromDataPath_int_2_1_bits_fuOpType[0]), io_fromDataPath_int_2_1_bits_ftqOffset);
  assign io_toExus_int_2_1_bits_nextPcOffset = brh_next_pc_off(io_fromDataPath_int_2_1_bits_ftqOffset, io_fromDataPath_int_2_1_bits_preDecode_isRVC);
  assign io_toExus_int_1_1_bits_imm = brh_imm(_imm_mod_9_io_out_imm[63:0], (io_fromDataPath_int_1_1_bits_fuType[0] & io_fromDataPath_int_1_1_bits_fuOpType[0]), io_fromDataPath_int_1_1_bits_ftqOffset);
  assign io_toExus_int_1_1_bits_nextPcOffset = brh_next_pc_off(io_fromDataPath_int_1_1_bits_ftqOffset, io_fromDataPath_int_1_1_bits_preDecode_isRVC);
  assign io_toExus_int_0_1_bits_imm = brh_imm(_imm_mod_4_io_out_imm[63:0], (io_fromDataPath_int_0_1_bits_fuType[0] & io_fromDataPath_int_0_1_bits_fuOpType[0]), io_fromDataPath_int_0_1_bits_ftqOffset);
  assign io_toExus_int_0_1_bits_nextPcOffset = brh_next_pc_off(io_fromDataPath_int_0_1_bits_ftqOffset, io_fromDataPath_int_0_1_bits_preDecode_isRVC);

  // ---- ready 反向 / valid 前向 / 其余 bits 直通 ----
  assign io_fromDataPath_int_3_1_ready = io_toExus_int_3_1_ready;
  assign io_fromDataPath_fp_1_1_ready = io_toExus_fp_1_1_ready;
  assign io_fromDataPath_fp_0_1_ready = io_toExus_fp_0_1_ready;
  assign io_fromDataPath_vf_2_0_ready = io_toExus_vf_2_0_ready;
  assign io_fromDataPath_vf_1_0_ready = io_toExus_vf_1_0_ready;
  assign io_fromDataPath_vf_0_0_ready = io_toExus_vf_0_0_ready;
  assign io_fromDataPath_mem_8_0_ready = io_toExus_mem_8_0_ready;
  assign io_fromDataPath_mem_7_0_ready = io_toExus_mem_7_0_ready;
  assign io_fromDataPath_mem_6_0_ready = io_toExus_mem_6_0_ready;
  assign io_fromDataPath_mem_5_0_ready = io_toExus_mem_5_0_ready;
  assign io_fromDataPath_mem_4_0_ready = io_toExus_mem_4_0_ready;
  assign io_fromDataPath_mem_3_0_ready = io_toExus_mem_3_0_ready;
  assign io_fromDataPath_mem_2_0_ready = io_toExus_mem_2_0_ready;
  assign io_fromDataPath_mem_1_0_ready = io_toExus_mem_1_0_ready;
  assign io_fromDataPath_mem_0_0_ready = io_toExus_mem_0_0_ready;
  assign io_toExus_int_3_1_valid = io_fromDataPath_int_3_1_valid;
  assign io_toExus_int_3_1_bits_fuType = io_fromDataPath_int_3_1_bits_fuType;
  assign io_toExus_int_3_1_bits_fuOpType = io_fromDataPath_int_3_1_bits_fuOpType;
  assign io_toExus_int_3_1_bits_imm = io_fromDataPath_int_3_1_bits_imm;
  assign io_toExus_int_3_1_bits_robIdx_flag = io_fromDataPath_int_3_1_bits_robIdx_flag;
  assign io_toExus_int_3_1_bits_robIdx_value = io_fromDataPath_int_3_1_bits_robIdx_value;
  assign io_toExus_int_3_1_bits_pdest = io_fromDataPath_int_3_1_bits_pdest;
  assign io_toExus_int_3_1_bits_rfWen = io_fromDataPath_int_3_1_bits_rfWen;
  assign io_toExus_int_3_1_bits_flushPipe = io_fromDataPath_int_3_1_bits_flushPipe;
  assign io_toExus_int_3_1_bits_ftqIdx_flag = io_fromDataPath_int_3_1_bits_ftqIdx_flag;
  assign io_toExus_int_3_1_bits_ftqIdx_value = io_fromDataPath_int_3_1_bits_ftqIdx_value;
  assign io_toExus_int_3_1_bits_ftqOffset = io_fromDataPath_int_3_1_bits_ftqOffset;
  assign io_toExus_int_3_1_bits_loadDependency_0 = io_fromDataPath_int_3_1_bits_loadDependency_0;
  assign io_toExus_int_3_1_bits_loadDependency_1 = io_fromDataPath_int_3_1_bits_loadDependency_1;
  assign io_toExus_int_3_1_bits_loadDependency_2 = io_fromDataPath_int_3_1_bits_loadDependency_2;
  assign io_toExus_int_3_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_selectTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_3_1_bits_perfDebugInfo_issueTime = io_fromDataPath_int_3_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_3_0_valid = io_fromDataPath_int_3_0_valid;
  assign io_toExus_int_3_0_bits_fuType = io_fromDataPath_int_3_0_bits_fuType;
  assign io_toExus_int_3_0_bits_fuOpType = io_fromDataPath_int_3_0_bits_fuOpType;
  assign io_toExus_int_3_0_bits_robIdx_flag = io_fromDataPath_int_3_0_bits_robIdx_flag;
  assign io_toExus_int_3_0_bits_robIdx_value = io_fromDataPath_int_3_0_bits_robIdx_value;
  assign io_toExus_int_3_0_bits_pdest = io_fromDataPath_int_3_0_bits_pdest;
  assign io_toExus_int_3_0_bits_rfWen = io_fromDataPath_int_3_0_bits_rfWen;
  assign io_toExus_int_3_0_bits_loadDependency_0 = io_fromDataPath_int_3_0_bits_loadDependency_0;
  assign io_toExus_int_3_0_bits_loadDependency_1 = io_fromDataPath_int_3_0_bits_loadDependency_1;
  assign io_toExus_int_3_0_bits_loadDependency_2 = io_fromDataPath_int_3_0_bits_loadDependency_2;
  assign io_toExus_int_3_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_selectTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_3_0_bits_perfDebugInfo_issueTime = io_fromDataPath_int_3_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_2_1_valid = io_fromDataPath_int_2_1_valid;
  assign io_toExus_int_2_1_bits_fuType = io_fromDataPath_int_2_1_bits_fuType;
  assign io_toExus_int_2_1_bits_fuOpType = io_fromDataPath_int_2_1_bits_fuOpType;
  assign io_toExus_int_2_1_bits_robIdx_flag = io_fromDataPath_int_2_1_bits_robIdx_flag;
  assign io_toExus_int_2_1_bits_robIdx_value = io_fromDataPath_int_2_1_bits_robIdx_value;
  assign io_toExus_int_2_1_bits_pdest = io_fromDataPath_int_2_1_bits_pdest;
  assign io_toExus_int_2_1_bits_rfWen = io_fromDataPath_int_2_1_bits_rfWen;
  assign io_toExus_int_2_1_bits_fpWen = io_fromDataPath_int_2_1_bits_fpWen;
  assign io_toExus_int_2_1_bits_vecWen = io_fromDataPath_int_2_1_bits_vecWen;
  assign io_toExus_int_2_1_bits_v0Wen = io_fromDataPath_int_2_1_bits_v0Wen;
  assign io_toExus_int_2_1_bits_vlWen = io_fromDataPath_int_2_1_bits_vlWen;
  assign io_toExus_int_2_1_bits_fpu_typeTagOut = io_fromDataPath_int_2_1_bits_fpu_typeTagOut;
  assign io_toExus_int_2_1_bits_fpu_wflags = io_fromDataPath_int_2_1_bits_fpu_wflags;
  assign io_toExus_int_2_1_bits_fpu_typ = io_fromDataPath_int_2_1_bits_fpu_typ;
  assign io_toExus_int_2_1_bits_fpu_rm = io_fromDataPath_int_2_1_bits_fpu_rm;
  assign io_toExus_int_2_1_bits_pc = io_fromDataPath_int_2_1_bits_pc;
  assign io_toExus_int_2_1_bits_ftqIdx_flag = io_fromDataPath_int_2_1_bits_ftqIdx_flag;
  assign io_toExus_int_2_1_bits_ftqIdx_value = io_fromDataPath_int_2_1_bits_ftqIdx_value;
  assign io_toExus_int_2_1_bits_ftqOffset = io_fromDataPath_int_2_1_bits_ftqOffset;
  assign io_toExus_int_2_1_bits_predictInfo_target = io_fromDataPath_int_2_1_bits_predictInfo_target;
  assign io_toExus_int_2_1_bits_predictInfo_taken = io_fromDataPath_int_2_1_bits_predictInfo_taken;
  assign io_toExus_int_2_1_bits_loadDependency_0 = io_fromDataPath_int_2_1_bits_loadDependency_0;
  assign io_toExus_int_2_1_bits_loadDependency_1 = io_fromDataPath_int_2_1_bits_loadDependency_1;
  assign io_toExus_int_2_1_bits_loadDependency_2 = io_fromDataPath_int_2_1_bits_loadDependency_2;
  assign io_toExus_int_2_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_selectTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_2_1_bits_perfDebugInfo_issueTime = io_fromDataPath_int_2_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_2_0_valid = io_fromDataPath_int_2_0_valid;
  assign io_toExus_int_2_0_bits_fuType = io_fromDataPath_int_2_0_bits_fuType;
  assign io_toExus_int_2_0_bits_fuOpType = io_fromDataPath_int_2_0_bits_fuOpType;
  assign io_toExus_int_2_0_bits_robIdx_flag = io_fromDataPath_int_2_0_bits_robIdx_flag;
  assign io_toExus_int_2_0_bits_robIdx_value = io_fromDataPath_int_2_0_bits_robIdx_value;
  assign io_toExus_int_2_0_bits_pdest = io_fromDataPath_int_2_0_bits_pdest;
  assign io_toExus_int_2_0_bits_rfWen = io_fromDataPath_int_2_0_bits_rfWen;
  assign io_toExus_int_2_0_bits_loadDependency_0 = io_fromDataPath_int_2_0_bits_loadDependency_0;
  assign io_toExus_int_2_0_bits_loadDependency_1 = io_fromDataPath_int_2_0_bits_loadDependency_1;
  assign io_toExus_int_2_0_bits_loadDependency_2 = io_fromDataPath_int_2_0_bits_loadDependency_2;
  assign io_toExus_int_2_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_selectTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_2_0_bits_perfDebugInfo_issueTime = io_fromDataPath_int_2_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_1_1_valid = io_fromDataPath_int_1_1_valid;
  assign io_toExus_int_1_1_bits_fuType = io_fromDataPath_int_1_1_bits_fuType;
  assign io_toExus_int_1_1_bits_fuOpType = io_fromDataPath_int_1_1_bits_fuOpType;
  assign io_toExus_int_1_1_bits_robIdx_flag = io_fromDataPath_int_1_1_bits_robIdx_flag;
  assign io_toExus_int_1_1_bits_robIdx_value = io_fromDataPath_int_1_1_bits_robIdx_value;
  assign io_toExus_int_1_1_bits_pdest = io_fromDataPath_int_1_1_bits_pdest;
  assign io_toExus_int_1_1_bits_rfWen = io_fromDataPath_int_1_1_bits_rfWen;
  assign io_toExus_int_1_1_bits_pc = io_fromDataPath_int_1_1_bits_pc;
  assign io_toExus_int_1_1_bits_ftqIdx_flag = io_fromDataPath_int_1_1_bits_ftqIdx_flag;
  assign io_toExus_int_1_1_bits_ftqIdx_value = io_fromDataPath_int_1_1_bits_ftqIdx_value;
  assign io_toExus_int_1_1_bits_ftqOffset = io_fromDataPath_int_1_1_bits_ftqOffset;
  assign io_toExus_int_1_1_bits_predictInfo_target = io_fromDataPath_int_1_1_bits_predictInfo_target;
  assign io_toExus_int_1_1_bits_predictInfo_taken = io_fromDataPath_int_1_1_bits_predictInfo_taken;
  assign io_toExus_int_1_1_bits_loadDependency_0 = io_fromDataPath_int_1_1_bits_loadDependency_0;
  assign io_toExus_int_1_1_bits_loadDependency_1 = io_fromDataPath_int_1_1_bits_loadDependency_1;
  assign io_toExus_int_1_1_bits_loadDependency_2 = io_fromDataPath_int_1_1_bits_loadDependency_2;
  assign io_toExus_int_1_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_selectTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_1_1_bits_perfDebugInfo_issueTime = io_fromDataPath_int_1_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_1_0_valid = io_fromDataPath_int_1_0_valid;
  assign io_toExus_int_1_0_bits_fuType = io_fromDataPath_int_1_0_bits_fuType;
  assign io_toExus_int_1_0_bits_fuOpType = io_fromDataPath_int_1_0_bits_fuOpType;
  assign io_toExus_int_1_0_bits_robIdx_flag = io_fromDataPath_int_1_0_bits_robIdx_flag;
  assign io_toExus_int_1_0_bits_robIdx_value = io_fromDataPath_int_1_0_bits_robIdx_value;
  assign io_toExus_int_1_0_bits_pdest = io_fromDataPath_int_1_0_bits_pdest;
  assign io_toExus_int_1_0_bits_rfWen = io_fromDataPath_int_1_0_bits_rfWen;
  assign io_toExus_int_1_0_bits_loadDependency_0 = io_fromDataPath_int_1_0_bits_loadDependency_0;
  assign io_toExus_int_1_0_bits_loadDependency_1 = io_fromDataPath_int_1_0_bits_loadDependency_1;
  assign io_toExus_int_1_0_bits_loadDependency_2 = io_fromDataPath_int_1_0_bits_loadDependency_2;
  assign io_toExus_int_1_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_selectTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_1_0_bits_perfDebugInfo_issueTime = io_fromDataPath_int_1_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_0_1_valid = io_fromDataPath_int_0_1_valid;
  assign io_toExus_int_0_1_bits_fuType = io_fromDataPath_int_0_1_bits_fuType;
  assign io_toExus_int_0_1_bits_fuOpType = io_fromDataPath_int_0_1_bits_fuOpType;
  assign io_toExus_int_0_1_bits_robIdx_flag = io_fromDataPath_int_0_1_bits_robIdx_flag;
  assign io_toExus_int_0_1_bits_robIdx_value = io_fromDataPath_int_0_1_bits_robIdx_value;
  assign io_toExus_int_0_1_bits_pdest = io_fromDataPath_int_0_1_bits_pdest;
  assign io_toExus_int_0_1_bits_rfWen = io_fromDataPath_int_0_1_bits_rfWen;
  assign io_toExus_int_0_1_bits_pc = io_fromDataPath_int_0_1_bits_pc;
  assign io_toExus_int_0_1_bits_ftqIdx_flag = io_fromDataPath_int_0_1_bits_ftqIdx_flag;
  assign io_toExus_int_0_1_bits_ftqIdx_value = io_fromDataPath_int_0_1_bits_ftqIdx_value;
  assign io_toExus_int_0_1_bits_ftqOffset = io_fromDataPath_int_0_1_bits_ftqOffset;
  assign io_toExus_int_0_1_bits_predictInfo_target = io_fromDataPath_int_0_1_bits_predictInfo_target;
  assign io_toExus_int_0_1_bits_predictInfo_taken = io_fromDataPath_int_0_1_bits_predictInfo_taken;
  assign io_toExus_int_0_1_bits_loadDependency_0 = io_fromDataPath_int_0_1_bits_loadDependency_0;
  assign io_toExus_int_0_1_bits_loadDependency_1 = io_fromDataPath_int_0_1_bits_loadDependency_1;
  assign io_toExus_int_0_1_bits_loadDependency_2 = io_fromDataPath_int_0_1_bits_loadDependency_2;
  assign io_toExus_int_0_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_selectTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_0_1_bits_perfDebugInfo_issueTime = io_fromDataPath_int_0_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_int_0_0_valid = io_fromDataPath_int_0_0_valid;
  assign io_toExus_int_0_0_bits_fuType = io_fromDataPath_int_0_0_bits_fuType;
  assign io_toExus_int_0_0_bits_fuOpType = io_fromDataPath_int_0_0_bits_fuOpType;
  assign io_toExus_int_0_0_bits_robIdx_flag = io_fromDataPath_int_0_0_bits_robIdx_flag;
  assign io_toExus_int_0_0_bits_robIdx_value = io_fromDataPath_int_0_0_bits_robIdx_value;
  assign io_toExus_int_0_0_bits_pdest = io_fromDataPath_int_0_0_bits_pdest;
  assign io_toExus_int_0_0_bits_rfWen = io_fromDataPath_int_0_0_bits_rfWen;
  assign io_toExus_int_0_0_bits_loadDependency_0 = io_fromDataPath_int_0_0_bits_loadDependency_0;
  assign io_toExus_int_0_0_bits_loadDependency_1 = io_fromDataPath_int_0_0_bits_loadDependency_1;
  assign io_toExus_int_0_0_bits_loadDependency_2 = io_fromDataPath_int_0_0_bits_loadDependency_2;
  assign io_toExus_int_0_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_selectTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_int_0_0_bits_perfDebugInfo_issueTime = io_fromDataPath_int_0_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_2_0_valid = io_fromDataPath_fp_2_0_valid;
  assign io_toExus_fp_2_0_bits_fuType = io_fromDataPath_fp_2_0_bits_fuType;
  assign io_toExus_fp_2_0_bits_fuOpType = io_fromDataPath_fp_2_0_bits_fuOpType;
  assign io_toExus_fp_2_0_bits_robIdx_flag = io_fromDataPath_fp_2_0_bits_robIdx_flag;
  assign io_toExus_fp_2_0_bits_robIdx_value = io_fromDataPath_fp_2_0_bits_robIdx_value;
  assign io_toExus_fp_2_0_bits_pdest = io_fromDataPath_fp_2_0_bits_pdest;
  assign io_toExus_fp_2_0_bits_rfWen = io_fromDataPath_fp_2_0_bits_rfWen;
  assign io_toExus_fp_2_0_bits_fpWen = io_fromDataPath_fp_2_0_bits_fpWen;
  assign io_toExus_fp_2_0_bits_fpu_wflags = io_fromDataPath_fp_2_0_bits_fpu_wflags;
  assign io_toExus_fp_2_0_bits_fpu_fmt = io_fromDataPath_fp_2_0_bits_fpu_fmt;
  assign io_toExus_fp_2_0_bits_fpu_rm = io_fromDataPath_fp_2_0_bits_fpu_rm;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_2_0_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_2_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_1_1_valid = io_fromDataPath_fp_1_1_valid;
  assign io_toExus_fp_1_1_bits_fuType = io_fromDataPath_fp_1_1_bits_fuType;
  assign io_toExus_fp_1_1_bits_fuOpType = io_fromDataPath_fp_1_1_bits_fuOpType;
  assign io_toExus_fp_1_1_bits_robIdx_flag = io_fromDataPath_fp_1_1_bits_robIdx_flag;
  assign io_toExus_fp_1_1_bits_robIdx_value = io_fromDataPath_fp_1_1_bits_robIdx_value;
  assign io_toExus_fp_1_1_bits_pdest = io_fromDataPath_fp_1_1_bits_pdest;
  assign io_toExus_fp_1_1_bits_fpWen = io_fromDataPath_fp_1_1_bits_fpWen;
  assign io_toExus_fp_1_1_bits_fpu_wflags = io_fromDataPath_fp_1_1_bits_fpu_wflags;
  assign io_toExus_fp_1_1_bits_fpu_fmt = io_fromDataPath_fp_1_1_bits_fpu_fmt;
  assign io_toExus_fp_1_1_bits_fpu_rm = io_fromDataPath_fp_1_1_bits_fpu_rm;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_1_1_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_1_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_1_0_valid = io_fromDataPath_fp_1_0_valid;
  assign io_toExus_fp_1_0_bits_fuType = io_fromDataPath_fp_1_0_bits_fuType;
  assign io_toExus_fp_1_0_bits_fuOpType = io_fromDataPath_fp_1_0_bits_fuOpType;
  assign io_toExus_fp_1_0_bits_robIdx_flag = io_fromDataPath_fp_1_0_bits_robIdx_flag;
  assign io_toExus_fp_1_0_bits_robIdx_value = io_fromDataPath_fp_1_0_bits_robIdx_value;
  assign io_toExus_fp_1_0_bits_pdest = io_fromDataPath_fp_1_0_bits_pdest;
  assign io_toExus_fp_1_0_bits_rfWen = io_fromDataPath_fp_1_0_bits_rfWen;
  assign io_toExus_fp_1_0_bits_fpWen = io_fromDataPath_fp_1_0_bits_fpWen;
  assign io_toExus_fp_1_0_bits_fpu_wflags = io_fromDataPath_fp_1_0_bits_fpu_wflags;
  assign io_toExus_fp_1_0_bits_fpu_fmt = io_fromDataPath_fp_1_0_bits_fpu_fmt;
  assign io_toExus_fp_1_0_bits_fpu_rm = io_fromDataPath_fp_1_0_bits_fpu_rm;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_1_0_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_1_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_0_1_valid = io_fromDataPath_fp_0_1_valid;
  assign io_toExus_fp_0_1_bits_fuType = io_fromDataPath_fp_0_1_bits_fuType;
  assign io_toExus_fp_0_1_bits_fuOpType = io_fromDataPath_fp_0_1_bits_fuOpType;
  assign io_toExus_fp_0_1_bits_robIdx_flag = io_fromDataPath_fp_0_1_bits_robIdx_flag;
  assign io_toExus_fp_0_1_bits_robIdx_value = io_fromDataPath_fp_0_1_bits_robIdx_value;
  assign io_toExus_fp_0_1_bits_pdest = io_fromDataPath_fp_0_1_bits_pdest;
  assign io_toExus_fp_0_1_bits_fpWen = io_fromDataPath_fp_0_1_bits_fpWen;
  assign io_toExus_fp_0_1_bits_fpu_wflags = io_fromDataPath_fp_0_1_bits_fpu_wflags;
  assign io_toExus_fp_0_1_bits_fpu_fmt = io_fromDataPath_fp_0_1_bits_fpu_fmt;
  assign io_toExus_fp_0_1_bits_fpu_rm = io_fromDataPath_fp_0_1_bits_fpu_rm;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_0_1_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_0_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_fp_0_0_valid = io_fromDataPath_fp_0_0_valid;
  assign io_toExus_fp_0_0_bits_fuType = io_fromDataPath_fp_0_0_bits_fuType;
  assign io_toExus_fp_0_0_bits_fuOpType = io_fromDataPath_fp_0_0_bits_fuOpType;
  assign io_toExus_fp_0_0_bits_robIdx_flag = io_fromDataPath_fp_0_0_bits_robIdx_flag;
  assign io_toExus_fp_0_0_bits_robIdx_value = io_fromDataPath_fp_0_0_bits_robIdx_value;
  assign io_toExus_fp_0_0_bits_pdest = io_fromDataPath_fp_0_0_bits_pdest;
  assign io_toExus_fp_0_0_bits_rfWen = io_fromDataPath_fp_0_0_bits_rfWen;
  assign io_toExus_fp_0_0_bits_fpWen = io_fromDataPath_fp_0_0_bits_fpWen;
  assign io_toExus_fp_0_0_bits_vecWen = io_fromDataPath_fp_0_0_bits_vecWen;
  assign io_toExus_fp_0_0_bits_v0Wen = io_fromDataPath_fp_0_0_bits_v0Wen;
  assign io_toExus_fp_0_0_bits_fpu_wflags = io_fromDataPath_fp_0_0_bits_fpu_wflags;
  assign io_toExus_fp_0_0_bits_fpu_fmt = io_fromDataPath_fp_0_0_bits_fpu_fmt;
  assign io_toExus_fp_0_0_bits_fpu_rm = io_fromDataPath_fp_0_0_bits_fpu_rm;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_selectTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_fp_0_0_bits_perfDebugInfo_issueTime = io_fromDataPath_fp_0_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_2_0_valid = io_fromDataPath_vf_2_0_valid;
  assign io_toExus_vf_2_0_bits_fuType = io_fromDataPath_vf_2_0_bits_fuType;
  assign io_toExus_vf_2_0_bits_fuOpType = io_fromDataPath_vf_2_0_bits_fuOpType;
  assign io_toExus_vf_2_0_bits_robIdx_flag = io_fromDataPath_vf_2_0_bits_robIdx_flag;
  assign io_toExus_vf_2_0_bits_robIdx_value = io_fromDataPath_vf_2_0_bits_robIdx_value;
  assign io_toExus_vf_2_0_bits_pdest = io_fromDataPath_vf_2_0_bits_pdest;
  assign io_toExus_vf_2_0_bits_vecWen = io_fromDataPath_vf_2_0_bits_vecWen;
  assign io_toExus_vf_2_0_bits_v0Wen = io_fromDataPath_vf_2_0_bits_v0Wen;
  assign io_toExus_vf_2_0_bits_fpu_wflags = io_fromDataPath_vf_2_0_bits_fpu_wflags;
  assign io_toExus_vf_2_0_bits_vpu_vma = io_fromDataPath_vf_2_0_bits_vpu_vma;
  assign io_toExus_vf_2_0_bits_vpu_vta = io_fromDataPath_vf_2_0_bits_vpu_vta;
  assign io_toExus_vf_2_0_bits_vpu_vsew = io_fromDataPath_vf_2_0_bits_vpu_vsew;
  assign io_toExus_vf_2_0_bits_vpu_vlmul = io_fromDataPath_vf_2_0_bits_vpu_vlmul;
  assign io_toExus_vf_2_0_bits_vpu_vm = io_fromDataPath_vf_2_0_bits_vpu_vm;
  assign io_toExus_vf_2_0_bits_vpu_vstart = io_fromDataPath_vf_2_0_bits_vpu_vstart;
  assign io_toExus_vf_2_0_bits_vpu_vuopIdx = io_fromDataPath_vf_2_0_bits_vpu_vuopIdx;
  assign io_toExus_vf_2_0_bits_vpu_isExt = io_fromDataPath_vf_2_0_bits_vpu_isExt;
  assign io_toExus_vf_2_0_bits_vpu_isNarrow = io_fromDataPath_vf_2_0_bits_vpu_isNarrow;
  assign io_toExus_vf_2_0_bits_vpu_isDstMask = io_fromDataPath_vf_2_0_bits_vpu_isDstMask;
  assign io_toExus_vf_2_0_bits_vpu_isOpMask = io_fromDataPath_vf_2_0_bits_vpu_isOpMask;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_2_0_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_2_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_1_1_valid = io_fromDataPath_vf_1_1_valid;
  assign io_toExus_vf_1_1_bits_fuType = io_fromDataPath_vf_1_1_bits_fuType;
  assign io_toExus_vf_1_1_bits_fuOpType = io_fromDataPath_vf_1_1_bits_fuOpType;
  assign io_toExus_vf_1_1_bits_robIdx_flag = io_fromDataPath_vf_1_1_bits_robIdx_flag;
  assign io_toExus_vf_1_1_bits_robIdx_value = io_fromDataPath_vf_1_1_bits_robIdx_value;
  assign io_toExus_vf_1_1_bits_pdest = io_fromDataPath_vf_1_1_bits_pdest;
  assign io_toExus_vf_1_1_bits_fpWen = io_fromDataPath_vf_1_1_bits_fpWen;
  assign io_toExus_vf_1_1_bits_vecWen = io_fromDataPath_vf_1_1_bits_vecWen;
  assign io_toExus_vf_1_1_bits_v0Wen = io_fromDataPath_vf_1_1_bits_v0Wen;
  assign io_toExus_vf_1_1_bits_fpu_wflags = io_fromDataPath_vf_1_1_bits_fpu_wflags;
  assign io_toExus_vf_1_1_bits_vpu_vma = io_fromDataPath_vf_1_1_bits_vpu_vma;
  assign io_toExus_vf_1_1_bits_vpu_vta = io_fromDataPath_vf_1_1_bits_vpu_vta;
  assign io_toExus_vf_1_1_bits_vpu_vsew = io_fromDataPath_vf_1_1_bits_vpu_vsew;
  assign io_toExus_vf_1_1_bits_vpu_vlmul = io_fromDataPath_vf_1_1_bits_vpu_vlmul;
  assign io_toExus_vf_1_1_bits_vpu_vm = io_fromDataPath_vf_1_1_bits_vpu_vm;
  assign io_toExus_vf_1_1_bits_vpu_vstart = io_fromDataPath_vf_1_1_bits_vpu_vstart;
  assign io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_2 = io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_2;
  assign io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_4 = io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_4;
  assign io_toExus_vf_1_1_bits_vpu_fpu_isFoldTo1_8 = io_fromDataPath_vf_1_1_bits_vpu_fpu_isFoldTo1_8;
  assign io_toExus_vf_1_1_bits_vpu_vuopIdx = io_fromDataPath_vf_1_1_bits_vpu_vuopIdx;
  assign io_toExus_vf_1_1_bits_vpu_lastUop = io_fromDataPath_vf_1_1_bits_vpu_lastUop;
  assign io_toExus_vf_1_1_bits_vpu_isNarrow = io_fromDataPath_vf_1_1_bits_vpu_isNarrow;
  assign io_toExus_vf_1_1_bits_vpu_isDstMask = io_fromDataPath_vf_1_1_bits_vpu_isDstMask;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_1_1_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_1_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_1_0_valid = io_fromDataPath_vf_1_0_valid;
  assign io_toExus_vf_1_0_bits_fuType = io_fromDataPath_vf_1_0_bits_fuType;
  assign io_toExus_vf_1_0_bits_fuOpType = io_fromDataPath_vf_1_0_bits_fuOpType;
  assign io_toExus_vf_1_0_bits_robIdx_flag = io_fromDataPath_vf_1_0_bits_robIdx_flag;
  assign io_toExus_vf_1_0_bits_robIdx_value = io_fromDataPath_vf_1_0_bits_robIdx_value;
  assign io_toExus_vf_1_0_bits_pdest = io_fromDataPath_vf_1_0_bits_pdest;
  assign io_toExus_vf_1_0_bits_vecWen = io_fromDataPath_vf_1_0_bits_vecWen;
  assign io_toExus_vf_1_0_bits_v0Wen = io_fromDataPath_vf_1_0_bits_v0Wen;
  assign io_toExus_vf_1_0_bits_fpu_wflags = io_fromDataPath_vf_1_0_bits_fpu_wflags;
  assign io_toExus_vf_1_0_bits_vpu_vma = io_fromDataPath_vf_1_0_bits_vpu_vma;
  assign io_toExus_vf_1_0_bits_vpu_vta = io_fromDataPath_vf_1_0_bits_vpu_vta;
  assign io_toExus_vf_1_0_bits_vpu_vsew = io_fromDataPath_vf_1_0_bits_vpu_vsew;
  assign io_toExus_vf_1_0_bits_vpu_vlmul = io_fromDataPath_vf_1_0_bits_vpu_vlmul;
  assign io_toExus_vf_1_0_bits_vpu_vm = io_fromDataPath_vf_1_0_bits_vpu_vm;
  assign io_toExus_vf_1_0_bits_vpu_vstart = io_fromDataPath_vf_1_0_bits_vpu_vstart;
  assign io_toExus_vf_1_0_bits_vpu_vuopIdx = io_fromDataPath_vf_1_0_bits_vpu_vuopIdx;
  assign io_toExus_vf_1_0_bits_vpu_isExt = io_fromDataPath_vf_1_0_bits_vpu_isExt;
  assign io_toExus_vf_1_0_bits_vpu_isNarrow = io_fromDataPath_vf_1_0_bits_vpu_isNarrow;
  assign io_toExus_vf_1_0_bits_vpu_isDstMask = io_fromDataPath_vf_1_0_bits_vpu_isDstMask;
  assign io_toExus_vf_1_0_bits_vpu_isOpMask = io_fromDataPath_vf_1_0_bits_vpu_isOpMask;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_1_0_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_1_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_0_1_valid = io_fromDataPath_vf_0_1_valid;
  assign io_toExus_vf_0_1_bits_fuType = io_fromDataPath_vf_0_1_bits_fuType;
  assign io_toExus_vf_0_1_bits_fuOpType = io_fromDataPath_vf_0_1_bits_fuOpType;
  assign io_toExus_vf_0_1_bits_robIdx_flag = io_fromDataPath_vf_0_1_bits_robIdx_flag;
  assign io_toExus_vf_0_1_bits_robIdx_value = io_fromDataPath_vf_0_1_bits_robIdx_value;
  assign io_toExus_vf_0_1_bits_pdest = io_fromDataPath_vf_0_1_bits_pdest;
  assign io_toExus_vf_0_1_bits_rfWen = io_fromDataPath_vf_0_1_bits_rfWen;
  assign io_toExus_vf_0_1_bits_fpWen = io_fromDataPath_vf_0_1_bits_fpWen;
  assign io_toExus_vf_0_1_bits_vecWen = io_fromDataPath_vf_0_1_bits_vecWen;
  assign io_toExus_vf_0_1_bits_v0Wen = io_fromDataPath_vf_0_1_bits_v0Wen;
  assign io_toExus_vf_0_1_bits_vlWen = io_fromDataPath_vf_0_1_bits_vlWen;
  assign io_toExus_vf_0_1_bits_fpu_wflags = io_fromDataPath_vf_0_1_bits_fpu_wflags;
  assign io_toExus_vf_0_1_bits_vpu_vma = io_fromDataPath_vf_0_1_bits_vpu_vma;
  assign io_toExus_vf_0_1_bits_vpu_vta = io_fromDataPath_vf_0_1_bits_vpu_vta;
  assign io_toExus_vf_0_1_bits_vpu_vsew = io_fromDataPath_vf_0_1_bits_vpu_vsew;
  assign io_toExus_vf_0_1_bits_vpu_vlmul = io_fromDataPath_vf_0_1_bits_vpu_vlmul;
  assign io_toExus_vf_0_1_bits_vpu_vm = io_fromDataPath_vf_0_1_bits_vpu_vm;
  assign io_toExus_vf_0_1_bits_vpu_vstart = io_fromDataPath_vf_0_1_bits_vpu_vstart;
  assign io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_2 = io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_2;
  assign io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_4 = io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_4;
  assign io_toExus_vf_0_1_bits_vpu_fpu_isFoldTo1_8 = io_fromDataPath_vf_0_1_bits_vpu_fpu_isFoldTo1_8;
  assign io_toExus_vf_0_1_bits_vpu_vuopIdx = io_fromDataPath_vf_0_1_bits_vpu_vuopIdx;
  assign io_toExus_vf_0_1_bits_vpu_lastUop = io_fromDataPath_vf_0_1_bits_vpu_lastUop;
  assign io_toExus_vf_0_1_bits_vpu_isNarrow = io_fromDataPath_vf_0_1_bits_vpu_isNarrow;
  assign io_toExus_vf_0_1_bits_vpu_isDstMask = io_fromDataPath_vf_0_1_bits_vpu_isDstMask;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_0_1_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_0_1_bits_perfDebugInfo_issueTime;
  assign io_toExus_vf_0_0_valid = io_fromDataPath_vf_0_0_valid;
  assign io_toExus_vf_0_0_bits_fuType = io_fromDataPath_vf_0_0_bits_fuType;
  assign io_toExus_vf_0_0_bits_fuOpType = io_fromDataPath_vf_0_0_bits_fuOpType;
  assign io_toExus_vf_0_0_bits_robIdx_flag = io_fromDataPath_vf_0_0_bits_robIdx_flag;
  assign io_toExus_vf_0_0_bits_robIdx_value = io_fromDataPath_vf_0_0_bits_robIdx_value;
  assign io_toExus_vf_0_0_bits_pdest = io_fromDataPath_vf_0_0_bits_pdest;
  assign io_toExus_vf_0_0_bits_vecWen = io_fromDataPath_vf_0_0_bits_vecWen;
  assign io_toExus_vf_0_0_bits_v0Wen = io_fromDataPath_vf_0_0_bits_v0Wen;
  assign io_toExus_vf_0_0_bits_fpu_wflags = io_fromDataPath_vf_0_0_bits_fpu_wflags;
  assign io_toExus_vf_0_0_bits_vpu_vma = io_fromDataPath_vf_0_0_bits_vpu_vma;
  assign io_toExus_vf_0_0_bits_vpu_vta = io_fromDataPath_vf_0_0_bits_vpu_vta;
  assign io_toExus_vf_0_0_bits_vpu_vsew = io_fromDataPath_vf_0_0_bits_vpu_vsew;
  assign io_toExus_vf_0_0_bits_vpu_vlmul = io_fromDataPath_vf_0_0_bits_vpu_vlmul;
  assign io_toExus_vf_0_0_bits_vpu_vm = io_fromDataPath_vf_0_0_bits_vpu_vm;
  assign io_toExus_vf_0_0_bits_vpu_vstart = io_fromDataPath_vf_0_0_bits_vpu_vstart;
  assign io_toExus_vf_0_0_bits_vpu_vuopIdx = io_fromDataPath_vf_0_0_bits_vpu_vuopIdx;
  assign io_toExus_vf_0_0_bits_vpu_isExt = io_fromDataPath_vf_0_0_bits_vpu_isExt;
  assign io_toExus_vf_0_0_bits_vpu_isNarrow = io_fromDataPath_vf_0_0_bits_vpu_isNarrow;
  assign io_toExus_vf_0_0_bits_vpu_isDstMask = io_fromDataPath_vf_0_0_bits_vpu_isDstMask;
  assign io_toExus_vf_0_0_bits_vpu_isOpMask = io_fromDataPath_vf_0_0_bits_vpu_isOpMask;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_selectTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_vf_0_0_bits_perfDebugInfo_issueTime = io_fromDataPath_vf_0_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_8_0_valid = io_fromDataPath_mem_8_0_valid;
  assign io_toExus_mem_8_0_bits_fuType = io_fromDataPath_mem_8_0_bits_fuType;
  assign io_toExus_mem_8_0_bits_fuOpType = io_fromDataPath_mem_8_0_bits_fuOpType;
  assign io_toExus_mem_8_0_bits_robIdx_flag = io_fromDataPath_mem_8_0_bits_robIdx_flag;
  assign io_toExus_mem_8_0_bits_robIdx_value = io_fromDataPath_mem_8_0_bits_robIdx_value;
  assign io_toExus_mem_8_0_bits_sqIdx_flag = io_fromDataPath_mem_8_0_bits_sqIdx_flag;
  assign io_toExus_mem_8_0_bits_sqIdx_value = io_fromDataPath_mem_8_0_bits_sqIdx_value;
  assign io_toExus_mem_8_0_bits_loadDependency_0 = io_fromDataPath_mem_8_0_bits_loadDependency_0;
  assign io_toExus_mem_8_0_bits_loadDependency_1 = io_fromDataPath_mem_8_0_bits_loadDependency_1;
  assign io_toExus_mem_8_0_bits_loadDependency_2 = io_fromDataPath_mem_8_0_bits_loadDependency_2;
  assign io_toExus_mem_7_0_valid = io_fromDataPath_mem_7_0_valid;
  assign io_toExus_mem_7_0_bits_fuType = io_fromDataPath_mem_7_0_bits_fuType;
  assign io_toExus_mem_7_0_bits_fuOpType = io_fromDataPath_mem_7_0_bits_fuOpType;
  assign io_toExus_mem_7_0_bits_robIdx_flag = io_fromDataPath_mem_7_0_bits_robIdx_flag;
  assign io_toExus_mem_7_0_bits_robIdx_value = io_fromDataPath_mem_7_0_bits_robIdx_value;
  assign io_toExus_mem_7_0_bits_sqIdx_flag = io_fromDataPath_mem_7_0_bits_sqIdx_flag;
  assign io_toExus_mem_7_0_bits_sqIdx_value = io_fromDataPath_mem_7_0_bits_sqIdx_value;
  assign io_toExus_mem_7_0_bits_loadDependency_0 = io_fromDataPath_mem_7_0_bits_loadDependency_0;
  assign io_toExus_mem_7_0_bits_loadDependency_1 = io_fromDataPath_mem_7_0_bits_loadDependency_1;
  assign io_toExus_mem_7_0_bits_loadDependency_2 = io_fromDataPath_mem_7_0_bits_loadDependency_2;
  assign io_toExus_mem_6_0_valid = io_fromDataPath_mem_6_0_valid;
  assign io_toExus_mem_6_0_bits_fuType = io_fromDataPath_mem_6_0_bits_fuType;
  assign io_toExus_mem_6_0_bits_fuOpType = io_fromDataPath_mem_6_0_bits_fuOpType;
  assign io_toExus_mem_6_0_bits_robIdx_flag = io_fromDataPath_mem_6_0_bits_robIdx_flag;
  assign io_toExus_mem_6_0_bits_robIdx_value = io_fromDataPath_mem_6_0_bits_robIdx_value;
  assign io_toExus_mem_6_0_bits_pdest = io_fromDataPath_mem_6_0_bits_pdest;
  assign io_toExus_mem_6_0_bits_vecWen = io_fromDataPath_mem_6_0_bits_vecWen;
  assign io_toExus_mem_6_0_bits_v0Wen = io_fromDataPath_mem_6_0_bits_v0Wen;
  assign io_toExus_mem_6_0_bits_vlWen = io_fromDataPath_mem_6_0_bits_vlWen;
  assign io_toExus_mem_6_0_bits_vpu_vma = io_fromDataPath_mem_6_0_bits_vpu_vma;
  assign io_toExus_mem_6_0_bits_vpu_vta = io_fromDataPath_mem_6_0_bits_vpu_vta;
  assign io_toExus_mem_6_0_bits_vpu_vsew = io_fromDataPath_mem_6_0_bits_vpu_vsew;
  assign io_toExus_mem_6_0_bits_vpu_vlmul = io_fromDataPath_mem_6_0_bits_vpu_vlmul;
  assign io_toExus_mem_6_0_bits_vpu_vm = io_fromDataPath_mem_6_0_bits_vpu_vm;
  assign io_toExus_mem_6_0_bits_vpu_vstart = io_fromDataPath_mem_6_0_bits_vpu_vstart;
  assign io_toExus_mem_6_0_bits_vpu_vuopIdx = io_fromDataPath_mem_6_0_bits_vpu_vuopIdx;
  assign io_toExus_mem_6_0_bits_vpu_lastUop = io_fromDataPath_mem_6_0_bits_vpu_lastUop;
  assign io_toExus_mem_6_0_bits_vpu_vmask = io_fromDataPath_mem_6_0_bits_vpu_vmask;
  assign io_toExus_mem_6_0_bits_vpu_nf = io_fromDataPath_mem_6_0_bits_vpu_nf;
  assign io_toExus_mem_6_0_bits_vpu_veew = io_fromDataPath_mem_6_0_bits_vpu_veew;
  assign io_toExus_mem_6_0_bits_vpu_isVleff = io_fromDataPath_mem_6_0_bits_vpu_isVleff;
  assign io_toExus_mem_6_0_bits_ftqIdx_flag = io_fromDataPath_mem_6_0_bits_ftqIdx_flag;
  assign io_toExus_mem_6_0_bits_ftqIdx_value = io_fromDataPath_mem_6_0_bits_ftqIdx_value;
  assign io_toExus_mem_6_0_bits_ftqOffset = io_fromDataPath_mem_6_0_bits_ftqOffset;
  assign io_toExus_mem_6_0_bits_numLsElem = io_fromDataPath_mem_6_0_bits_numLsElem;
  assign io_toExus_mem_6_0_bits_sqIdx_flag = io_fromDataPath_mem_6_0_bits_sqIdx_flag;
  assign io_toExus_mem_6_0_bits_sqIdx_value = io_fromDataPath_mem_6_0_bits_sqIdx_value;
  assign io_toExus_mem_6_0_bits_lqIdx_flag = io_fromDataPath_mem_6_0_bits_lqIdx_flag;
  assign io_toExus_mem_6_0_bits_lqIdx_value = io_fromDataPath_mem_6_0_bits_lqIdx_value;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_6_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_6_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_5_0_valid = io_fromDataPath_mem_5_0_valid;
  assign io_toExus_mem_5_0_bits_fuType = io_fromDataPath_mem_5_0_bits_fuType;
  assign io_toExus_mem_5_0_bits_fuOpType = io_fromDataPath_mem_5_0_bits_fuOpType;
  assign io_toExus_mem_5_0_bits_robIdx_flag = io_fromDataPath_mem_5_0_bits_robIdx_flag;
  assign io_toExus_mem_5_0_bits_robIdx_value = io_fromDataPath_mem_5_0_bits_robIdx_value;
  assign io_toExus_mem_5_0_bits_pdest = io_fromDataPath_mem_5_0_bits_pdest;
  assign io_toExus_mem_5_0_bits_vecWen = io_fromDataPath_mem_5_0_bits_vecWen;
  assign io_toExus_mem_5_0_bits_v0Wen = io_fromDataPath_mem_5_0_bits_v0Wen;
  assign io_toExus_mem_5_0_bits_vlWen = io_fromDataPath_mem_5_0_bits_vlWen;
  assign io_toExus_mem_5_0_bits_vpu_vma = io_fromDataPath_mem_5_0_bits_vpu_vma;
  assign io_toExus_mem_5_0_bits_vpu_vta = io_fromDataPath_mem_5_0_bits_vpu_vta;
  assign io_toExus_mem_5_0_bits_vpu_vsew = io_fromDataPath_mem_5_0_bits_vpu_vsew;
  assign io_toExus_mem_5_0_bits_vpu_vlmul = io_fromDataPath_mem_5_0_bits_vpu_vlmul;
  assign io_toExus_mem_5_0_bits_vpu_vm = io_fromDataPath_mem_5_0_bits_vpu_vm;
  assign io_toExus_mem_5_0_bits_vpu_vstart = io_fromDataPath_mem_5_0_bits_vpu_vstart;
  assign io_toExus_mem_5_0_bits_vpu_vuopIdx = io_fromDataPath_mem_5_0_bits_vpu_vuopIdx;
  assign io_toExus_mem_5_0_bits_vpu_lastUop = io_fromDataPath_mem_5_0_bits_vpu_lastUop;
  assign io_toExus_mem_5_0_bits_vpu_vmask = io_fromDataPath_mem_5_0_bits_vpu_vmask;
  assign io_toExus_mem_5_0_bits_vpu_nf = io_fromDataPath_mem_5_0_bits_vpu_nf;
  assign io_toExus_mem_5_0_bits_vpu_veew = io_fromDataPath_mem_5_0_bits_vpu_veew;
  assign io_toExus_mem_5_0_bits_vpu_isVleff = io_fromDataPath_mem_5_0_bits_vpu_isVleff;
  assign io_toExus_mem_5_0_bits_ftqIdx_flag = io_fromDataPath_mem_5_0_bits_ftqIdx_flag;
  assign io_toExus_mem_5_0_bits_ftqIdx_value = io_fromDataPath_mem_5_0_bits_ftqIdx_value;
  assign io_toExus_mem_5_0_bits_ftqOffset = io_fromDataPath_mem_5_0_bits_ftqOffset;
  assign io_toExus_mem_5_0_bits_numLsElem = io_fromDataPath_mem_5_0_bits_numLsElem;
  assign io_toExus_mem_5_0_bits_sqIdx_flag = io_fromDataPath_mem_5_0_bits_sqIdx_flag;
  assign io_toExus_mem_5_0_bits_sqIdx_value = io_fromDataPath_mem_5_0_bits_sqIdx_value;
  assign io_toExus_mem_5_0_bits_lqIdx_flag = io_fromDataPath_mem_5_0_bits_lqIdx_flag;
  assign io_toExus_mem_5_0_bits_lqIdx_value = io_fromDataPath_mem_5_0_bits_lqIdx_value;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_5_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_5_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_4_0_valid = io_fromDataPath_mem_4_0_valid;
  assign io_toExus_mem_4_0_bits_fuType = io_fromDataPath_mem_4_0_bits_fuType;
  assign io_toExus_mem_4_0_bits_fuOpType = io_fromDataPath_mem_4_0_bits_fuOpType;
  assign io_toExus_mem_4_0_bits_imm = io_fromDataPath_mem_4_0_bits_imm;
  assign io_toExus_mem_4_0_bits_robIdx_flag = io_fromDataPath_mem_4_0_bits_robIdx_flag;
  assign io_toExus_mem_4_0_bits_robIdx_value = io_fromDataPath_mem_4_0_bits_robIdx_value;
  assign io_toExus_mem_4_0_bits_pdest = io_fromDataPath_mem_4_0_bits_pdest;
  assign io_toExus_mem_4_0_bits_rfWen = io_fromDataPath_mem_4_0_bits_rfWen;
  assign io_toExus_mem_4_0_bits_fpWen = io_fromDataPath_mem_4_0_bits_fpWen;
  assign io_toExus_mem_4_0_bits_pc = io_fromDataPath_mem_4_0_bits_pc;
  assign io_toExus_mem_4_0_bits_preDecode_isRVC = io_fromDataPath_mem_4_0_bits_preDecode_isRVC;
  assign io_toExus_mem_4_0_bits_ftqIdx_flag = io_fromDataPath_mem_4_0_bits_ftqIdx_flag;
  assign io_toExus_mem_4_0_bits_ftqIdx_value = io_fromDataPath_mem_4_0_bits_ftqIdx_value;
  assign io_toExus_mem_4_0_bits_ftqOffset = io_fromDataPath_mem_4_0_bits_ftqOffset;
  assign io_toExus_mem_4_0_bits_loadWaitBit = io_fromDataPath_mem_4_0_bits_loadWaitBit;
  assign io_toExus_mem_4_0_bits_waitForRobIdx_flag = io_fromDataPath_mem_4_0_bits_waitForRobIdx_flag;
  assign io_toExus_mem_4_0_bits_waitForRobIdx_value = io_fromDataPath_mem_4_0_bits_waitForRobIdx_value;
  assign io_toExus_mem_4_0_bits_storeSetHit = io_fromDataPath_mem_4_0_bits_storeSetHit;
  assign io_toExus_mem_4_0_bits_loadWaitStrict = io_fromDataPath_mem_4_0_bits_loadWaitStrict;
  assign io_toExus_mem_4_0_bits_sqIdx_flag = io_fromDataPath_mem_4_0_bits_sqIdx_flag;
  assign io_toExus_mem_4_0_bits_sqIdx_value = io_fromDataPath_mem_4_0_bits_sqIdx_value;
  assign io_toExus_mem_4_0_bits_lqIdx_flag = io_fromDataPath_mem_4_0_bits_lqIdx_flag;
  assign io_toExus_mem_4_0_bits_lqIdx_value = io_fromDataPath_mem_4_0_bits_lqIdx_value;
  assign io_toExus_mem_4_0_bits_loadDependency_0 = io_fromDataPath_mem_4_0_bits_loadDependency_0;
  assign io_toExus_mem_4_0_bits_loadDependency_1 = io_fromDataPath_mem_4_0_bits_loadDependency_1;
  assign io_toExus_mem_4_0_bits_loadDependency_2 = io_fromDataPath_mem_4_0_bits_loadDependency_2;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_4_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_4_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_3_0_valid = io_fromDataPath_mem_3_0_valid;
  assign io_toExus_mem_3_0_bits_fuType = io_fromDataPath_mem_3_0_bits_fuType;
  assign io_toExus_mem_3_0_bits_fuOpType = io_fromDataPath_mem_3_0_bits_fuOpType;
  assign io_toExus_mem_3_0_bits_imm = io_fromDataPath_mem_3_0_bits_imm;
  assign io_toExus_mem_3_0_bits_robIdx_flag = io_fromDataPath_mem_3_0_bits_robIdx_flag;
  assign io_toExus_mem_3_0_bits_robIdx_value = io_fromDataPath_mem_3_0_bits_robIdx_value;
  assign io_toExus_mem_3_0_bits_pdest = io_fromDataPath_mem_3_0_bits_pdest;
  assign io_toExus_mem_3_0_bits_rfWen = io_fromDataPath_mem_3_0_bits_rfWen;
  assign io_toExus_mem_3_0_bits_fpWen = io_fromDataPath_mem_3_0_bits_fpWen;
  assign io_toExus_mem_3_0_bits_pc = io_fromDataPath_mem_3_0_bits_pc;
  assign io_toExus_mem_3_0_bits_preDecode_isRVC = io_fromDataPath_mem_3_0_bits_preDecode_isRVC;
  assign io_toExus_mem_3_0_bits_ftqIdx_flag = io_fromDataPath_mem_3_0_bits_ftqIdx_flag;
  assign io_toExus_mem_3_0_bits_ftqIdx_value = io_fromDataPath_mem_3_0_bits_ftqIdx_value;
  assign io_toExus_mem_3_0_bits_ftqOffset = io_fromDataPath_mem_3_0_bits_ftqOffset;
  assign io_toExus_mem_3_0_bits_loadWaitBit = io_fromDataPath_mem_3_0_bits_loadWaitBit;
  assign io_toExus_mem_3_0_bits_waitForRobIdx_flag = io_fromDataPath_mem_3_0_bits_waitForRobIdx_flag;
  assign io_toExus_mem_3_0_bits_waitForRobIdx_value = io_fromDataPath_mem_3_0_bits_waitForRobIdx_value;
  assign io_toExus_mem_3_0_bits_storeSetHit = io_fromDataPath_mem_3_0_bits_storeSetHit;
  assign io_toExus_mem_3_0_bits_loadWaitStrict = io_fromDataPath_mem_3_0_bits_loadWaitStrict;
  assign io_toExus_mem_3_0_bits_sqIdx_flag = io_fromDataPath_mem_3_0_bits_sqIdx_flag;
  assign io_toExus_mem_3_0_bits_sqIdx_value = io_fromDataPath_mem_3_0_bits_sqIdx_value;
  assign io_toExus_mem_3_0_bits_lqIdx_flag = io_fromDataPath_mem_3_0_bits_lqIdx_flag;
  assign io_toExus_mem_3_0_bits_lqIdx_value = io_fromDataPath_mem_3_0_bits_lqIdx_value;
  assign io_toExus_mem_3_0_bits_loadDependency_0 = io_fromDataPath_mem_3_0_bits_loadDependency_0;
  assign io_toExus_mem_3_0_bits_loadDependency_1 = io_fromDataPath_mem_3_0_bits_loadDependency_1;
  assign io_toExus_mem_3_0_bits_loadDependency_2 = io_fromDataPath_mem_3_0_bits_loadDependency_2;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_3_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_3_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_2_0_valid = io_fromDataPath_mem_2_0_valid;
  assign io_toExus_mem_2_0_bits_fuType = io_fromDataPath_mem_2_0_bits_fuType;
  assign io_toExus_mem_2_0_bits_fuOpType = io_fromDataPath_mem_2_0_bits_fuOpType;
  assign io_toExus_mem_2_0_bits_imm = io_fromDataPath_mem_2_0_bits_imm;
  assign io_toExus_mem_2_0_bits_robIdx_flag = io_fromDataPath_mem_2_0_bits_robIdx_flag;
  assign io_toExus_mem_2_0_bits_robIdx_value = io_fromDataPath_mem_2_0_bits_robIdx_value;
  assign io_toExus_mem_2_0_bits_pdest = io_fromDataPath_mem_2_0_bits_pdest;
  assign io_toExus_mem_2_0_bits_rfWen = io_fromDataPath_mem_2_0_bits_rfWen;
  assign io_toExus_mem_2_0_bits_fpWen = io_fromDataPath_mem_2_0_bits_fpWen;
  assign io_toExus_mem_2_0_bits_pc = io_fromDataPath_mem_2_0_bits_pc;
  assign io_toExus_mem_2_0_bits_preDecode_isRVC = io_fromDataPath_mem_2_0_bits_preDecode_isRVC;
  assign io_toExus_mem_2_0_bits_ftqIdx_flag = io_fromDataPath_mem_2_0_bits_ftqIdx_flag;
  assign io_toExus_mem_2_0_bits_ftqIdx_value = io_fromDataPath_mem_2_0_bits_ftqIdx_value;
  assign io_toExus_mem_2_0_bits_ftqOffset = io_fromDataPath_mem_2_0_bits_ftqOffset;
  assign io_toExus_mem_2_0_bits_loadWaitBit = io_fromDataPath_mem_2_0_bits_loadWaitBit;
  assign io_toExus_mem_2_0_bits_waitForRobIdx_flag = io_fromDataPath_mem_2_0_bits_waitForRobIdx_flag;
  assign io_toExus_mem_2_0_bits_waitForRobIdx_value = io_fromDataPath_mem_2_0_bits_waitForRobIdx_value;
  assign io_toExus_mem_2_0_bits_storeSetHit = io_fromDataPath_mem_2_0_bits_storeSetHit;
  assign io_toExus_mem_2_0_bits_loadWaitStrict = io_fromDataPath_mem_2_0_bits_loadWaitStrict;
  assign io_toExus_mem_2_0_bits_sqIdx_flag = io_fromDataPath_mem_2_0_bits_sqIdx_flag;
  assign io_toExus_mem_2_0_bits_sqIdx_value = io_fromDataPath_mem_2_0_bits_sqIdx_value;
  assign io_toExus_mem_2_0_bits_lqIdx_flag = io_fromDataPath_mem_2_0_bits_lqIdx_flag;
  assign io_toExus_mem_2_0_bits_lqIdx_value = io_fromDataPath_mem_2_0_bits_lqIdx_value;
  assign io_toExus_mem_2_0_bits_loadDependency_0 = io_fromDataPath_mem_2_0_bits_loadDependency_0;
  assign io_toExus_mem_2_0_bits_loadDependency_1 = io_fromDataPath_mem_2_0_bits_loadDependency_1;
  assign io_toExus_mem_2_0_bits_loadDependency_2 = io_fromDataPath_mem_2_0_bits_loadDependency_2;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_2_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_2_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_1_0_valid = io_fromDataPath_mem_1_0_valid;
  assign io_toExus_mem_1_0_bits_fuType = io_fromDataPath_mem_1_0_bits_fuType;
  assign io_toExus_mem_1_0_bits_fuOpType = io_fromDataPath_mem_1_0_bits_fuOpType;
  assign io_toExus_mem_1_0_bits_imm = io_fromDataPath_mem_1_0_bits_imm;
  assign io_toExus_mem_1_0_bits_robIdx_flag = io_fromDataPath_mem_1_0_bits_robIdx_flag;
  assign io_toExus_mem_1_0_bits_robIdx_value = io_fromDataPath_mem_1_0_bits_robIdx_value;
  assign io_toExus_mem_1_0_bits_isFirstIssue = io_fromDataPath_mem_1_0_bits_isFirstIssue;
  assign io_toExus_mem_1_0_bits_pdest = io_fromDataPath_mem_1_0_bits_pdest;
  assign io_toExus_mem_1_0_bits_rfWen = io_fromDataPath_mem_1_0_bits_rfWen;
  assign io_toExus_mem_1_0_bits_ftqIdx_value = io_fromDataPath_mem_1_0_bits_ftqIdx_value;
  assign io_toExus_mem_1_0_bits_ftqOffset = io_fromDataPath_mem_1_0_bits_ftqOffset;
  assign io_toExus_mem_1_0_bits_sqIdx_flag = io_fromDataPath_mem_1_0_bits_sqIdx_flag;
  assign io_toExus_mem_1_0_bits_sqIdx_value = io_fromDataPath_mem_1_0_bits_sqIdx_value;
  assign io_toExus_mem_1_0_bits_loadDependency_0 = io_fromDataPath_mem_1_0_bits_loadDependency_0;
  assign io_toExus_mem_1_0_bits_loadDependency_1 = io_fromDataPath_mem_1_0_bits_loadDependency_1;
  assign io_toExus_mem_1_0_bits_loadDependency_2 = io_fromDataPath_mem_1_0_bits_loadDependency_2;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_1_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_1_0_bits_perfDebugInfo_issueTime;
  assign io_toExus_mem_0_0_valid = io_fromDataPath_mem_0_0_valid;
  assign io_toExus_mem_0_0_bits_fuType = io_fromDataPath_mem_0_0_bits_fuType;
  assign io_toExus_mem_0_0_bits_fuOpType = io_fromDataPath_mem_0_0_bits_fuOpType;
  assign io_toExus_mem_0_0_bits_imm = io_fromDataPath_mem_0_0_bits_imm;
  assign io_toExus_mem_0_0_bits_robIdx_flag = io_fromDataPath_mem_0_0_bits_robIdx_flag;
  assign io_toExus_mem_0_0_bits_robIdx_value = io_fromDataPath_mem_0_0_bits_robIdx_value;
  assign io_toExus_mem_0_0_bits_isFirstIssue = io_fromDataPath_mem_0_0_bits_isFirstIssue;
  assign io_toExus_mem_0_0_bits_pdest = io_fromDataPath_mem_0_0_bits_pdest;
  assign io_toExus_mem_0_0_bits_rfWen = io_fromDataPath_mem_0_0_bits_rfWen;
  assign io_toExus_mem_0_0_bits_ftqIdx_value = io_fromDataPath_mem_0_0_bits_ftqIdx_value;
  assign io_toExus_mem_0_0_bits_ftqOffset = io_fromDataPath_mem_0_0_bits_ftqOffset;
  assign io_toExus_mem_0_0_bits_sqIdx_flag = io_fromDataPath_mem_0_0_bits_sqIdx_flag;
  assign io_toExus_mem_0_0_bits_sqIdx_value = io_fromDataPath_mem_0_0_bits_sqIdx_value;
  assign io_toExus_mem_0_0_bits_loadDependency_0 = io_fromDataPath_mem_0_0_bits_loadDependency_0;
  assign io_toExus_mem_0_0_bits_loadDependency_1 = io_fromDataPath_mem_0_0_bits_loadDependency_1;
  assign io_toExus_mem_0_0_bits_loadDependency_2 = io_fromDataPath_mem_0_0_bits_loadDependency_2;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_enqRsTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_enqRsTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_selectTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_selectTime;
  assign io_toExus_mem_0_0_bits_perfDebugInfo_issueTime = io_fromDataPath_mem_0_0_bits_perfDebugInfo_issueTime;
