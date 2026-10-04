// CSR（CSR 功能单元外壳）双例化逐拍比对 tb（端口表由 golden 头机械抄出；激励与覆盖闸手写）。
// golden CSR（+ golden 子模块闭包：NewCSR 全树、TrapInstMod、TrapTvalMod、SatpFlushMod、IMSIC_WRAP）
// vs 重写件 CSR_xs（+ 重写子模块 *_xs）。
//
// 时间线：复位 5 拍 -> 预热（不比对：M 态 csrrw 写遍 337 个合法 CSR 地址，每个地址保持 2 拍；
//   拉调试中断进 debug 写 dpc/dscratch0/1 再 dret；打一个 trap、一个 mret）-> 随机 NCYCLES 拍逐拍比对
//   全部 280 个输出端口（6056 位，四态 !==）；每 NCYCLES/10 拍复位一次并重新预热。
// 激励偏置（uop 编码见 rtl/backend/CSR.sv 文件头）：
//   * valid 60%；fuOpType 85% 取 CSR 访问 {9,A,B,D,E,F}、15% 取系统指令 0x10；
//     CSR 地址 4/5 取合法表；系统指令 funct12 3/4 取 {ecall,ebreak,mnret,mret,sret,dret}；
//     rs1/rd 字段 3/4 非零；写源数据同 NewCSR UT 的偏置（dcsr/mnstatus/iselect/satp/tselect/tdata1/委托）。
//   * flush 3%，trap 3%（exceptionVec 单热），外部中断线慢变，NMI/debug 稀，MSI 写 5%，out.ready 70%。
// 覆盖闸（golden 内部信号，下限 = NCYCLES/2000 量级）：trap 进 M/HS/MN、mret/sret、合法写、IMSIC 等待、
//   EX_II、flushPipe、xret 重定向、ecall 异常位、MSI 写入；另报告未翻转的输出端口。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  bit cmp_en;
  longint checks = 0, errors = 0;

  localparam int IW = 2128, OW = 6056, NOUT = 280;
  logic [IW-1:0] in_vec;
  wire  [OW-1:0] g_out, i_out;
  localparam int OFF_io_flush_valid = 2127;
  wire [0:0] io_flush_valid = in_vec[2127 +: 1];
  localparam int OFF_io_flush_bits_robIdx_flag = 2126;
  wire [0:0] io_flush_bits_robIdx_flag = in_vec[2126 +: 1];
  localparam int OFF_io_flush_bits_robIdx_value = 2118;
  wire [7:0] io_flush_bits_robIdx_value = in_vec[2118 +: 8];
  localparam int OFF_io_flush_bits_ftqIdx_flag = 2117;
  wire [0:0] io_flush_bits_ftqIdx_flag = in_vec[2117 +: 1];
  localparam int OFF_io_flush_bits_ftqIdx_value = 2111;
  wire [5:0] io_flush_bits_ftqIdx_value = in_vec[2111 +: 6];
  localparam int OFF_io_flush_bits_ftqOffset = 2107;
  wire [3:0] io_flush_bits_ftqOffset = in_vec[2107 +: 4];
  localparam int OFF_io_flush_bits_level = 2106;
  wire [0:0] io_flush_bits_level = in_vec[2106 +: 1];
  localparam int OFF_io_flush_bits_cfiUpdate_backendIGPF = 2105;
  wire [0:0] io_flush_bits_cfiUpdate_backendIGPF = in_vec[2105 +: 1];
  localparam int OFF_io_flush_bits_cfiUpdate_backendIPF = 2104;
  wire [0:0] io_flush_bits_cfiUpdate_backendIPF = in_vec[2104 +: 1];
  localparam int OFF_io_flush_bits_cfiUpdate_backendIAF = 2103;
  wire [0:0] io_flush_bits_cfiUpdate_backendIAF = in_vec[2103 +: 1];
  localparam int OFF_io_flush_bits_fullTarget = 2039;
  wire [63:0] io_flush_bits_fullTarget = in_vec[2039 +: 64];
  localparam int OFF_io_in_valid = 2038;
  wire [0:0] io_in_valid = in_vec[2038 +: 1];
  localparam int OFF_io_in_bits_ctrl_fuOpType = 2029;
  wire [8:0] io_in_bits_ctrl_fuOpType = in_vec[2029 +: 9];
  localparam int OFF_io_in_bits_ctrl_robIdx_flag = 2028;
  wire [0:0] io_in_bits_ctrl_robIdx_flag = in_vec[2028 +: 1];
  localparam int OFF_io_in_bits_ctrl_robIdx_value = 2020;
  wire [7:0] io_in_bits_ctrl_robIdx_value = in_vec[2020 +: 8];
  localparam int OFF_io_in_bits_ctrl_pdest = 2012;
  wire [7:0] io_in_bits_ctrl_pdest = in_vec[2012 +: 8];
  localparam int OFF_io_in_bits_ctrl_rfWen = 2011;
  wire [0:0] io_in_bits_ctrl_rfWen = in_vec[2011 +: 1];
  localparam int OFF_io_in_bits_ctrl_preDecode_valid = 2010;
  wire [0:0] io_in_bits_ctrl_preDecode_valid = in_vec[2010 +: 1];
  localparam int OFF_io_in_bits_ctrl_preDecode_isRVC = 2009;
  wire [0:0] io_in_bits_ctrl_preDecode_isRVC = in_vec[2009 +: 1];
  localparam int OFF_io_in_bits_ctrl_preDecode_brType = 2007;
  wire [1:0] io_in_bits_ctrl_preDecode_brType = in_vec[2007 +: 2];
  localparam int OFF_io_in_bits_ctrl_preDecode_isCall = 2006;
  wire [0:0] io_in_bits_ctrl_preDecode_isCall = in_vec[2006 +: 1];
  localparam int OFF_io_in_bits_ctrl_preDecode_isRet = 2005;
  wire [0:0] io_in_bits_ctrl_preDecode_isRet = in_vec[2005 +: 1];
  localparam int OFF_io_in_bits_ctrl_ftqIdx_flag = 2004;
  wire [0:0] io_in_bits_ctrl_ftqIdx_flag = in_vec[2004 +: 1];
  localparam int OFF_io_in_bits_ctrl_ftqIdx_value = 1998;
  wire [5:0] io_in_bits_ctrl_ftqIdx_value = in_vec[1998 +: 6];
  localparam int OFF_io_in_bits_ctrl_ftqOffset = 1994;
  wire [3:0] io_in_bits_ctrl_ftqOffset = in_vec[1994 +: 4];
  localparam int OFF_io_in_bits_data_src_0 = 1930;
  wire [63:0] io_in_bits_data_src_0 = in_vec[1930 +: 64];
  localparam int OFF_io_in_bits_data_imm = 1866;
  wire [63:0] io_in_bits_data_imm = in_vec[1866 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_eliminatedMove = 1865;
  wire [0:0] io_in_bits_perfDebugInfo_eliminatedMove = in_vec[1865 +: 1];
  localparam int OFF_io_in_bits_perfDebugInfo_renameTime = 1801;
  wire [63:0] io_in_bits_perfDebugInfo_renameTime = in_vec[1801 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_dispatchTime = 1737;
  wire [63:0] io_in_bits_perfDebugInfo_dispatchTime = in_vec[1737 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_enqRsTime = 1673;
  wire [63:0] io_in_bits_perfDebugInfo_enqRsTime = in_vec[1673 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_selectTime = 1609;
  wire [63:0] io_in_bits_perfDebugInfo_selectTime = in_vec[1609 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_issueTime = 1545;
  wire [63:0] io_in_bits_perfDebugInfo_issueTime = in_vec[1545 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_writebackTime = 1481;
  wire [63:0] io_in_bits_perfDebugInfo_writebackTime = in_vec[1481 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_runahead_checkpoint_id = 1417;
  wire [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id = in_vec[1417 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_tlbFirstReqTime = 1353;
  wire [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime = in_vec[1353 +: 64];
  localparam int OFF_io_in_bits_perfDebugInfo_tlbRespTime = 1289;
  wire [63:0] io_in_bits_perfDebugInfo_tlbRespTime = in_vec[1289 +: 64];
  localparam int OFF_io_in_bits_debug_seqNum_seqNum = 1233;
  wire [55:0] io_in_bits_debug_seqNum_seqNum = in_vec[1233 +: 56];
  localparam int OFF_io_in_bits_debug_seqNum_uopIdx = 1225;
  wire [7:0] io_in_bits_debug_seqNum_uopIdx = in_vec[1225 +: 8];
  localparam int OFF_io_out_ready = 1224;
  wire [0:0] io_out_ready = in_vec[1224 +: 1];
  localparam int OFF_io_csrin_hartId = 1216;
  wire [7:0] io_csrin_hartId = in_vec[1216 +: 8];
  localparam int OFF_io_csrin_msiInfo_valid = 1215;
  wire [0:0] io_csrin_msiInfo_valid = in_vec[1215 +: 1];
  localparam int OFF_io_csrin_msiInfo_bits = 1203;
  wire [11:0] io_csrin_msiInfo_bits = in_vec[1203 +: 12];
  localparam int OFF_io_csrin_criticalErrorState = 1202;
  wire [0:0] io_csrin_criticalErrorState = in_vec[1202 +: 1];
  localparam int OFF_io_csrin_clintTime_valid = 1201;
  wire [0:0] io_csrin_clintTime_valid = in_vec[1201 +: 1];
  localparam int OFF_io_csrin_clintTime_bits = 1137;
  wire [63:0] io_csrin_clintTime_bits = in_vec[1137 +: 64];
  localparam int OFF_io_csrin_l2FlushDone = 1136;
  wire [0:0] io_csrin_l2FlushDone = in_vec[1136 +: 1];
  localparam int OFF_io_csrin_trapInstInfo_valid = 1135;
  wire [0:0] io_csrin_trapInstInfo_valid = in_vec[1135 +: 1];
  localparam int OFF_io_csrin_trapInstInfo_bits_instr = 1103;
  wire [31:0] io_csrin_trapInstInfo_bits_instr = in_vec[1103 +: 32];
  localparam int OFF_io_csrin_trapInstInfo_bits_ftqPtr_flag = 1102;
  wire [0:0] io_csrin_trapInstInfo_bits_ftqPtr_flag = in_vec[1102 +: 1];
  localparam int OFF_io_csrin_trapInstInfo_bits_ftqPtr_value = 1096;
  wire [5:0] io_csrin_trapInstInfo_bits_ftqPtr_value = in_vec[1096 +: 6];
  localparam int OFF_io_csrin_trapInstInfo_bits_ftqOffset = 1092;
  wire [3:0] io_csrin_trapInstInfo_bits_ftqOffset = in_vec[1092 +: 4];
  localparam int OFF_io_csrin_fromVecExcpMod_busy = 1091;
  wire [0:0] io_csrin_fromVecExcpMod_busy = in_vec[1091 +: 1];
  localparam int OFF_io_csrio_perf_perfEventsFrontend_0_value = 1085;
  wire [5:0] io_csrio_perf_perfEventsFrontend_0_value = in_vec[1085 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsFrontend_1_value = 1079;
  wire [5:0] io_csrio_perf_perfEventsFrontend_1_value = in_vec[1079 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsFrontend_2_value = 1073;
  wire [5:0] io_csrio_perf_perfEventsFrontend_2_value = in_vec[1073 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsFrontend_3_value = 1067;
  wire [5:0] io_csrio_perf_perfEventsFrontend_3_value = in_vec[1067 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsFrontend_4_value = 1061;
  wire [5:0] io_csrio_perf_perfEventsFrontend_4_value = in_vec[1061 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsFrontend_5_value = 1055;
  wire [5:0] io_csrio_perf_perfEventsFrontend_5_value = in_vec[1055 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsFrontend_6_value = 1049;
  wire [5:0] io_csrio_perf_perfEventsFrontend_6_value = in_vec[1049 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsFrontend_7_value = 1043;
  wire [5:0] io_csrio_perf_perfEventsFrontend_7_value = in_vec[1043 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsBackend_0_value = 1037;
  wire [5:0] io_csrio_perf_perfEventsBackend_0_value = in_vec[1037 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsBackend_1_value = 1031;
  wire [5:0] io_csrio_perf_perfEventsBackend_1_value = in_vec[1031 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsBackend_2_value = 1025;
  wire [5:0] io_csrio_perf_perfEventsBackend_2_value = in_vec[1025 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsBackend_3_value = 1019;
  wire [5:0] io_csrio_perf_perfEventsBackend_3_value = in_vec[1019 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsBackend_4_value = 1013;
  wire [5:0] io_csrio_perf_perfEventsBackend_4_value = in_vec[1013 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsBackend_5_value = 1007;
  wire [5:0] io_csrio_perf_perfEventsBackend_5_value = in_vec[1007 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsBackend_6_value = 1001;
  wire [5:0] io_csrio_perf_perfEventsBackend_6_value = in_vec[1001 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsBackend_7_value = 995;
  wire [5:0] io_csrio_perf_perfEventsBackend_7_value = in_vec[995 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsLsu_0_value = 989;
  wire [5:0] io_csrio_perf_perfEventsLsu_0_value = in_vec[989 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsLsu_1_value = 983;
  wire [5:0] io_csrio_perf_perfEventsLsu_1_value = in_vec[983 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsLsu_2_value = 977;
  wire [5:0] io_csrio_perf_perfEventsLsu_2_value = in_vec[977 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsLsu_3_value = 971;
  wire [5:0] io_csrio_perf_perfEventsLsu_3_value = in_vec[971 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsLsu_4_value = 965;
  wire [5:0] io_csrio_perf_perfEventsLsu_4_value = in_vec[965 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsLsu_5_value = 959;
  wire [5:0] io_csrio_perf_perfEventsLsu_5_value = in_vec[959 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsLsu_6_value = 953;
  wire [5:0] io_csrio_perf_perfEventsLsu_6_value = in_vec[953 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsLsu_7_value = 947;
  wire [5:0] io_csrio_perf_perfEventsLsu_7_value = in_vec[947 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_0_value = 941;
  wire [5:0] io_csrio_perf_perfEventsHc_0_value = in_vec[941 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_1_value = 935;
  wire [5:0] io_csrio_perf_perfEventsHc_1_value = in_vec[935 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_2_value = 929;
  wire [5:0] io_csrio_perf_perfEventsHc_2_value = in_vec[929 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_3_value = 923;
  wire [5:0] io_csrio_perf_perfEventsHc_3_value = in_vec[923 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_4_value = 917;
  wire [5:0] io_csrio_perf_perfEventsHc_4_value = in_vec[917 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_5_value = 911;
  wire [5:0] io_csrio_perf_perfEventsHc_5_value = in_vec[911 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_6_value = 905;
  wire [5:0] io_csrio_perf_perfEventsHc_6_value = in_vec[905 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_7_value = 899;
  wire [5:0] io_csrio_perf_perfEventsHc_7_value = in_vec[899 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_8_value = 893;
  wire [5:0] io_csrio_perf_perfEventsHc_8_value = in_vec[893 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_9_value = 887;
  wire [5:0] io_csrio_perf_perfEventsHc_9_value = in_vec[887 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_10_value = 881;
  wire [5:0] io_csrio_perf_perfEventsHc_10_value = in_vec[881 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_11_value = 875;
  wire [5:0] io_csrio_perf_perfEventsHc_11_value = in_vec[875 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_12_value = 869;
  wire [5:0] io_csrio_perf_perfEventsHc_12_value = in_vec[869 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_13_value = 863;
  wire [5:0] io_csrio_perf_perfEventsHc_13_value = in_vec[863 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_14_value = 857;
  wire [5:0] io_csrio_perf_perfEventsHc_14_value = in_vec[857 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_15_value = 851;
  wire [5:0] io_csrio_perf_perfEventsHc_15_value = in_vec[851 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_16_value = 845;
  wire [5:0] io_csrio_perf_perfEventsHc_16_value = in_vec[845 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_17_value = 839;
  wire [5:0] io_csrio_perf_perfEventsHc_17_value = in_vec[839 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_18_value = 833;
  wire [5:0] io_csrio_perf_perfEventsHc_18_value = in_vec[833 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_19_value = 827;
  wire [5:0] io_csrio_perf_perfEventsHc_19_value = in_vec[827 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_20_value = 821;
  wire [5:0] io_csrio_perf_perfEventsHc_20_value = in_vec[821 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_21_value = 815;
  wire [5:0] io_csrio_perf_perfEventsHc_21_value = in_vec[815 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_22_value = 809;
  wire [5:0] io_csrio_perf_perfEventsHc_22_value = in_vec[809 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_23_value = 803;
  wire [5:0] io_csrio_perf_perfEventsHc_23_value = in_vec[803 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_24_value = 797;
  wire [5:0] io_csrio_perf_perfEventsHc_24_value = in_vec[797 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_25_value = 791;
  wire [5:0] io_csrio_perf_perfEventsHc_25_value = in_vec[791 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_26_value = 785;
  wire [5:0] io_csrio_perf_perfEventsHc_26_value = in_vec[785 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_27_value = 779;
  wire [5:0] io_csrio_perf_perfEventsHc_27_value = in_vec[779 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_28_value = 773;
  wire [5:0] io_csrio_perf_perfEventsHc_28_value = in_vec[773 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_29_value = 767;
  wire [5:0] io_csrio_perf_perfEventsHc_29_value = in_vec[767 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_30_value = 761;
  wire [5:0] io_csrio_perf_perfEventsHc_30_value = in_vec[761 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_31_value = 755;
  wire [5:0] io_csrio_perf_perfEventsHc_31_value = in_vec[755 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_32_value = 749;
  wire [5:0] io_csrio_perf_perfEventsHc_32_value = in_vec[749 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_33_value = 743;
  wire [5:0] io_csrio_perf_perfEventsHc_33_value = in_vec[743 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_34_value = 737;
  wire [5:0] io_csrio_perf_perfEventsHc_34_value = in_vec[737 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_35_value = 731;
  wire [5:0] io_csrio_perf_perfEventsHc_35_value = in_vec[731 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_36_value = 725;
  wire [5:0] io_csrio_perf_perfEventsHc_36_value = in_vec[725 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_37_value = 719;
  wire [5:0] io_csrio_perf_perfEventsHc_37_value = in_vec[719 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_38_value = 713;
  wire [5:0] io_csrio_perf_perfEventsHc_38_value = in_vec[713 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_39_value = 707;
  wire [5:0] io_csrio_perf_perfEventsHc_39_value = in_vec[707 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_40_value = 701;
  wire [5:0] io_csrio_perf_perfEventsHc_40_value = in_vec[701 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_41_value = 695;
  wire [5:0] io_csrio_perf_perfEventsHc_41_value = in_vec[695 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_42_value = 689;
  wire [5:0] io_csrio_perf_perfEventsHc_42_value = in_vec[689 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_43_value = 683;
  wire [5:0] io_csrio_perf_perfEventsHc_43_value = in_vec[683 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_44_value = 677;
  wire [5:0] io_csrio_perf_perfEventsHc_44_value = in_vec[677 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_45_value = 671;
  wire [5:0] io_csrio_perf_perfEventsHc_45_value = in_vec[671 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_46_value = 665;
  wire [5:0] io_csrio_perf_perfEventsHc_46_value = in_vec[665 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_47_value = 659;
  wire [5:0] io_csrio_perf_perfEventsHc_47_value = in_vec[659 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_48_value = 653;
  wire [5:0] io_csrio_perf_perfEventsHc_48_value = in_vec[653 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_49_value = 647;
  wire [5:0] io_csrio_perf_perfEventsHc_49_value = in_vec[647 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_50_value = 641;
  wire [5:0] io_csrio_perf_perfEventsHc_50_value = in_vec[641 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_51_value = 635;
  wire [5:0] io_csrio_perf_perfEventsHc_51_value = in_vec[635 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_52_value = 629;
  wire [5:0] io_csrio_perf_perfEventsHc_52_value = in_vec[629 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_53_value = 623;
  wire [5:0] io_csrio_perf_perfEventsHc_53_value = in_vec[623 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_54_value = 617;
  wire [5:0] io_csrio_perf_perfEventsHc_54_value = in_vec[617 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_55_value = 611;
  wire [5:0] io_csrio_perf_perfEventsHc_55_value = in_vec[611 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_56_value = 605;
  wire [5:0] io_csrio_perf_perfEventsHc_56_value = in_vec[605 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_57_value = 599;
  wire [5:0] io_csrio_perf_perfEventsHc_57_value = in_vec[599 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_58_value = 593;
  wire [5:0] io_csrio_perf_perfEventsHc_58_value = in_vec[593 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_59_value = 587;
  wire [5:0] io_csrio_perf_perfEventsHc_59_value = in_vec[587 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_60_value = 581;
  wire [5:0] io_csrio_perf_perfEventsHc_60_value = in_vec[581 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_61_value = 575;
  wire [5:0] io_csrio_perf_perfEventsHc_61_value = in_vec[575 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_62_value = 569;
  wire [5:0] io_csrio_perf_perfEventsHc_62_value = in_vec[569 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_63_value = 563;
  wire [5:0] io_csrio_perf_perfEventsHc_63_value = in_vec[563 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_64_value = 557;
  wire [5:0] io_csrio_perf_perfEventsHc_64_value = in_vec[557 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_65_value = 551;
  wire [5:0] io_csrio_perf_perfEventsHc_65_value = in_vec[551 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_66_value = 545;
  wire [5:0] io_csrio_perf_perfEventsHc_66_value = in_vec[545 +: 6];
  localparam int OFF_io_csrio_perf_perfEventsHc_67_value = 539;
  wire [5:0] io_csrio_perf_perfEventsHc_67_value = in_vec[539 +: 6];
  localparam int OFF_io_csrio_perf_retiredInstr = 532;
  wire [6:0] io_csrio_perf_retiredInstr = in_vec[532 +: 7];
  localparam int OFF_io_csrio_fpu_fflags_valid = 531;
  wire [0:0] io_csrio_fpu_fflags_valid = in_vec[531 +: 1];
  localparam int OFF_io_csrio_fpu_fflags_bits = 526;
  wire [4:0] io_csrio_fpu_fflags_bits = in_vec[526 +: 5];
  localparam int OFF_io_csrio_fpu_dirty_fs = 525;
  wire [0:0] io_csrio_fpu_dirty_fs = in_vec[525 +: 1];
  localparam int OFF_io_csrio_vpu_vl = 461;
  wire [63:0] io_csrio_vpu_vl = in_vec[461 +: 64];
  localparam int OFF_io_csrio_vpu_set_vstart_valid = 460;
  wire [0:0] io_csrio_vpu_set_vstart_valid = in_vec[460 +: 1];
  localparam int OFF_io_csrio_vpu_set_vstart_bits = 396;
  wire [63:0] io_csrio_vpu_set_vstart_bits = in_vec[396 +: 64];
  localparam int OFF_io_csrio_vpu_set_vtype_valid = 395;
  wire [0:0] io_csrio_vpu_set_vtype_valid = in_vec[395 +: 1];
  localparam int OFF_io_csrio_vpu_set_vtype_bits = 331;
  wire [63:0] io_csrio_vpu_set_vtype_bits = in_vec[331 +: 64];
  localparam int OFF_io_csrio_vpu_set_vxsat_valid = 330;
  wire [0:0] io_csrio_vpu_set_vxsat_valid = in_vec[330 +: 1];
  localparam int OFF_io_csrio_vpu_set_vxsat_bits = 329;
  wire [0:0] io_csrio_vpu_set_vxsat_bits = in_vec[329 +: 1];
  localparam int OFF_io_csrio_vpu_dirty_vs = 328;
  wire [0:0] io_csrio_vpu_dirty_vs = in_vec[328 +: 1];
  localparam int OFF_io_csrio_exception_valid = 327;
  wire [0:0] io_csrio_exception_valid = in_vec[327 +: 1];
  localparam int OFF_io_csrio_exception_bits_pc = 277;
  wire [49:0] io_csrio_exception_bits_pc = in_vec[277 +: 50];
  localparam int OFF_io_csrio_exception_bits_instr = 245;
  wire [31:0] io_csrio_exception_bits_instr = in_vec[245 +: 32];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_0 = 244;
  wire [0:0] io_csrio_exception_bits_exceptionVec_0 = in_vec[244 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_1 = 243;
  wire [0:0] io_csrio_exception_bits_exceptionVec_1 = in_vec[243 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_2 = 242;
  wire [0:0] io_csrio_exception_bits_exceptionVec_2 = in_vec[242 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_3 = 241;
  wire [0:0] io_csrio_exception_bits_exceptionVec_3 = in_vec[241 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_4 = 240;
  wire [0:0] io_csrio_exception_bits_exceptionVec_4 = in_vec[240 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_5 = 239;
  wire [0:0] io_csrio_exception_bits_exceptionVec_5 = in_vec[239 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_6 = 238;
  wire [0:0] io_csrio_exception_bits_exceptionVec_6 = in_vec[238 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_7 = 237;
  wire [0:0] io_csrio_exception_bits_exceptionVec_7 = in_vec[237 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_8 = 236;
  wire [0:0] io_csrio_exception_bits_exceptionVec_8 = in_vec[236 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_9 = 235;
  wire [0:0] io_csrio_exception_bits_exceptionVec_9 = in_vec[235 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_10 = 234;
  wire [0:0] io_csrio_exception_bits_exceptionVec_10 = in_vec[234 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_11 = 233;
  wire [0:0] io_csrio_exception_bits_exceptionVec_11 = in_vec[233 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_12 = 232;
  wire [0:0] io_csrio_exception_bits_exceptionVec_12 = in_vec[232 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_13 = 231;
  wire [0:0] io_csrio_exception_bits_exceptionVec_13 = in_vec[231 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_14 = 230;
  wire [0:0] io_csrio_exception_bits_exceptionVec_14 = in_vec[230 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_15 = 229;
  wire [0:0] io_csrio_exception_bits_exceptionVec_15 = in_vec[229 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_16 = 228;
  wire [0:0] io_csrio_exception_bits_exceptionVec_16 = in_vec[228 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_17 = 227;
  wire [0:0] io_csrio_exception_bits_exceptionVec_17 = in_vec[227 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_18 = 226;
  wire [0:0] io_csrio_exception_bits_exceptionVec_18 = in_vec[226 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_19 = 225;
  wire [0:0] io_csrio_exception_bits_exceptionVec_19 = in_vec[225 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_20 = 224;
  wire [0:0] io_csrio_exception_bits_exceptionVec_20 = in_vec[224 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_21 = 223;
  wire [0:0] io_csrio_exception_bits_exceptionVec_21 = in_vec[223 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_22 = 222;
  wire [0:0] io_csrio_exception_bits_exceptionVec_22 = in_vec[222 +: 1];
  localparam int OFF_io_csrio_exception_bits_exceptionVec_23 = 221;
  wire [0:0] io_csrio_exception_bits_exceptionVec_23 = in_vec[221 +: 1];
  localparam int OFF_io_csrio_exception_bits_isPcBkpt = 220;
  wire [0:0] io_csrio_exception_bits_isPcBkpt = in_vec[220 +: 1];
  localparam int OFF_io_csrio_exception_bits_isFetchMalAddr = 219;
  wire [0:0] io_csrio_exception_bits_isFetchMalAddr = in_vec[219 +: 1];
  localparam int OFF_io_csrio_exception_bits_satpFlushFirstFetchFault = 218;
  wire [0:0] io_csrio_exception_bits_satpFlushFirstFetchFault = in_vec[218 +: 1];
  localparam int OFF_io_csrio_exception_bits_gpaddr = 154;
  wire [63:0] io_csrio_exception_bits_gpaddr = in_vec[154 +: 64];
  localparam int OFF_io_csrio_exception_bits_singleStep = 153;
  wire [0:0] io_csrio_exception_bits_singleStep = in_vec[153 +: 1];
  localparam int OFF_io_csrio_exception_bits_crossPageIPFFix = 152;
  wire [0:0] io_csrio_exception_bits_crossPageIPFFix = in_vec[152 +: 1];
  localparam int OFF_io_csrio_exception_bits_isInterrupt = 151;
  wire [0:0] io_csrio_exception_bits_isInterrupt = in_vec[151 +: 1];
  localparam int OFF_io_csrio_exception_bits_isHls = 150;
  wire [0:0] io_csrio_exception_bits_isHls = in_vec[150 +: 1];
  localparam int OFF_io_csrio_exception_bits_trigger = 146;
  wire [3:0] io_csrio_exception_bits_trigger = in_vec[146 +: 4];
  localparam int OFF_io_csrio_exception_bits_isForVSnonLeafPTE = 145;
  wire [0:0] io_csrio_exception_bits_isForVSnonLeafPTE = in_vec[145 +: 1];
  localparam int OFF_io_csrio_robDeqPtr_flag = 144;
  wire [0:0] io_csrio_robDeqPtr_flag = in_vec[144 +: 1];
  localparam int OFF_io_csrio_robDeqPtr_value = 136;
  wire [7:0] io_csrio_robDeqPtr_value = in_vec[136 +: 8];
  localparam int OFF_io_csrio_memExceptionVAddr = 72;
  wire [63:0] io_csrio_memExceptionVAddr = in_vec[72 +: 64];
  localparam int OFF_io_csrio_memExceptionGPAddr = 8;
  wire [63:0] io_csrio_memExceptionGPAddr = in_vec[8 +: 64];
  localparam int OFF_io_csrio_memExceptionIsForVSnonLeafPTE = 7;
  wire [0:0] io_csrio_memExceptionIsForVSnonLeafPTE = in_vec[7 +: 1];
  localparam int OFF_io_csrio_externalInterrupt_mtip = 6;
  wire [0:0] io_csrio_externalInterrupt_mtip = in_vec[6 +: 1];
  localparam int OFF_io_csrio_externalInterrupt_msip = 5;
  wire [0:0] io_csrio_externalInterrupt_msip = in_vec[5 +: 1];
  localparam int OFF_io_csrio_externalInterrupt_meip = 4;
  wire [0:0] io_csrio_externalInterrupt_meip = in_vec[4 +: 1];
  localparam int OFF_io_csrio_externalInterrupt_seip = 3;
  wire [0:0] io_csrio_externalInterrupt_seip = in_vec[3 +: 1];
  localparam int OFF_io_csrio_externalInterrupt_debug = 2;
  wire [0:0] io_csrio_externalInterrupt_debug = in_vec[2 +: 1];
  localparam int OFF_io_csrio_externalInterrupt_nmi_nmi_31 = 1;
  wire [0:0] io_csrio_externalInterrupt_nmi_nmi_31 = in_vec[1 +: 1];
  localparam int OFF_io_csrio_externalInterrupt_nmi_nmi_43 = 0;
  wire [0:0] io_csrio_externalInterrupt_nmi_nmi_43 = in_vec[0 +: 1];
  CSR u_g (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_ftqIdx_flag(io_flush_bits_ftqIdx_flag),
    .io_flush_bits_ftqIdx_value(io_flush_bits_ftqIdx_value),
    .io_flush_bits_ftqOffset(io_flush_bits_ftqOffset),
    .io_flush_bits_level(io_flush_bits_level),
    .io_flush_bits_cfiUpdate_backendIGPF(io_flush_bits_cfiUpdate_backendIGPF),
    .io_flush_bits_cfiUpdate_backendIPF(io_flush_bits_cfiUpdate_backendIPF),
    .io_flush_bits_cfiUpdate_backendIAF(io_flush_bits_cfiUpdate_backendIAF),
    .io_flush_bits_fullTarget(io_flush_bits_fullTarget),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen),
    .io_in_bits_ctrl_preDecode_valid(io_in_bits_ctrl_preDecode_valid),
    .io_in_bits_ctrl_preDecode_isRVC(io_in_bits_ctrl_preDecode_isRVC),
    .io_in_bits_ctrl_preDecode_brType(io_in_bits_ctrl_preDecode_brType),
    .io_in_bits_ctrl_preDecode_isCall(io_in_bits_ctrl_preDecode_isCall),
    .io_in_bits_ctrl_preDecode_isRet(io_in_bits_ctrl_preDecode_isRet),
    .io_in_bits_ctrl_ftqIdx_flag(io_in_bits_ctrl_ftqIdx_flag),
    .io_in_bits_ctrl_ftqIdx_value(io_in_bits_ctrl_ftqIdx_value),
    .io_in_bits_ctrl_ftqOffset(io_in_bits_ctrl_ftqOffset),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_csrin_hartId(io_csrin_hartId),
    .io_csrin_msiInfo_valid(io_csrin_msiInfo_valid),
    .io_csrin_msiInfo_bits(io_csrin_msiInfo_bits),
    .io_csrin_criticalErrorState(io_csrin_criticalErrorState),
    .io_csrin_clintTime_valid(io_csrin_clintTime_valid),
    .io_csrin_clintTime_bits(io_csrin_clintTime_bits),
    .io_csrin_l2FlushDone(io_csrin_l2FlushDone),
    .io_csrin_trapInstInfo_valid(io_csrin_trapInstInfo_valid),
    .io_csrin_trapInstInfo_bits_instr(io_csrin_trapInstInfo_bits_instr),
    .io_csrin_trapInstInfo_bits_ftqPtr_flag(io_csrin_trapInstInfo_bits_ftqPtr_flag),
    .io_csrin_trapInstInfo_bits_ftqPtr_value(io_csrin_trapInstInfo_bits_ftqPtr_value),
    .io_csrin_trapInstInfo_bits_ftqOffset(io_csrin_trapInstInfo_bits_ftqOffset),
    .io_csrin_fromVecExcpMod_busy(io_csrin_fromVecExcpMod_busy),
    .io_csrio_perf_perfEventsFrontend_0_value(io_csrio_perf_perfEventsFrontend_0_value),
    .io_csrio_perf_perfEventsFrontend_1_value(io_csrio_perf_perfEventsFrontend_1_value),
    .io_csrio_perf_perfEventsFrontend_2_value(io_csrio_perf_perfEventsFrontend_2_value),
    .io_csrio_perf_perfEventsFrontend_3_value(io_csrio_perf_perfEventsFrontend_3_value),
    .io_csrio_perf_perfEventsFrontend_4_value(io_csrio_perf_perfEventsFrontend_4_value),
    .io_csrio_perf_perfEventsFrontend_5_value(io_csrio_perf_perfEventsFrontend_5_value),
    .io_csrio_perf_perfEventsFrontend_6_value(io_csrio_perf_perfEventsFrontend_6_value),
    .io_csrio_perf_perfEventsFrontend_7_value(io_csrio_perf_perfEventsFrontend_7_value),
    .io_csrio_perf_perfEventsBackend_0_value(io_csrio_perf_perfEventsBackend_0_value),
    .io_csrio_perf_perfEventsBackend_1_value(io_csrio_perf_perfEventsBackend_1_value),
    .io_csrio_perf_perfEventsBackend_2_value(io_csrio_perf_perfEventsBackend_2_value),
    .io_csrio_perf_perfEventsBackend_3_value(io_csrio_perf_perfEventsBackend_3_value),
    .io_csrio_perf_perfEventsBackend_4_value(io_csrio_perf_perfEventsBackend_4_value),
    .io_csrio_perf_perfEventsBackend_5_value(io_csrio_perf_perfEventsBackend_5_value),
    .io_csrio_perf_perfEventsBackend_6_value(io_csrio_perf_perfEventsBackend_6_value),
    .io_csrio_perf_perfEventsBackend_7_value(io_csrio_perf_perfEventsBackend_7_value),
    .io_csrio_perf_perfEventsLsu_0_value(io_csrio_perf_perfEventsLsu_0_value),
    .io_csrio_perf_perfEventsLsu_1_value(io_csrio_perf_perfEventsLsu_1_value),
    .io_csrio_perf_perfEventsLsu_2_value(io_csrio_perf_perfEventsLsu_2_value),
    .io_csrio_perf_perfEventsLsu_3_value(io_csrio_perf_perfEventsLsu_3_value),
    .io_csrio_perf_perfEventsLsu_4_value(io_csrio_perf_perfEventsLsu_4_value),
    .io_csrio_perf_perfEventsLsu_5_value(io_csrio_perf_perfEventsLsu_5_value),
    .io_csrio_perf_perfEventsLsu_6_value(io_csrio_perf_perfEventsLsu_6_value),
    .io_csrio_perf_perfEventsLsu_7_value(io_csrio_perf_perfEventsLsu_7_value),
    .io_csrio_perf_perfEventsHc_0_value(io_csrio_perf_perfEventsHc_0_value),
    .io_csrio_perf_perfEventsHc_1_value(io_csrio_perf_perfEventsHc_1_value),
    .io_csrio_perf_perfEventsHc_2_value(io_csrio_perf_perfEventsHc_2_value),
    .io_csrio_perf_perfEventsHc_3_value(io_csrio_perf_perfEventsHc_3_value),
    .io_csrio_perf_perfEventsHc_4_value(io_csrio_perf_perfEventsHc_4_value),
    .io_csrio_perf_perfEventsHc_5_value(io_csrio_perf_perfEventsHc_5_value),
    .io_csrio_perf_perfEventsHc_6_value(io_csrio_perf_perfEventsHc_6_value),
    .io_csrio_perf_perfEventsHc_7_value(io_csrio_perf_perfEventsHc_7_value),
    .io_csrio_perf_perfEventsHc_8_value(io_csrio_perf_perfEventsHc_8_value),
    .io_csrio_perf_perfEventsHc_9_value(io_csrio_perf_perfEventsHc_9_value),
    .io_csrio_perf_perfEventsHc_10_value(io_csrio_perf_perfEventsHc_10_value),
    .io_csrio_perf_perfEventsHc_11_value(io_csrio_perf_perfEventsHc_11_value),
    .io_csrio_perf_perfEventsHc_12_value(io_csrio_perf_perfEventsHc_12_value),
    .io_csrio_perf_perfEventsHc_13_value(io_csrio_perf_perfEventsHc_13_value),
    .io_csrio_perf_perfEventsHc_14_value(io_csrio_perf_perfEventsHc_14_value),
    .io_csrio_perf_perfEventsHc_15_value(io_csrio_perf_perfEventsHc_15_value),
    .io_csrio_perf_perfEventsHc_16_value(io_csrio_perf_perfEventsHc_16_value),
    .io_csrio_perf_perfEventsHc_17_value(io_csrio_perf_perfEventsHc_17_value),
    .io_csrio_perf_perfEventsHc_18_value(io_csrio_perf_perfEventsHc_18_value),
    .io_csrio_perf_perfEventsHc_19_value(io_csrio_perf_perfEventsHc_19_value),
    .io_csrio_perf_perfEventsHc_20_value(io_csrio_perf_perfEventsHc_20_value),
    .io_csrio_perf_perfEventsHc_21_value(io_csrio_perf_perfEventsHc_21_value),
    .io_csrio_perf_perfEventsHc_22_value(io_csrio_perf_perfEventsHc_22_value),
    .io_csrio_perf_perfEventsHc_23_value(io_csrio_perf_perfEventsHc_23_value),
    .io_csrio_perf_perfEventsHc_24_value(io_csrio_perf_perfEventsHc_24_value),
    .io_csrio_perf_perfEventsHc_25_value(io_csrio_perf_perfEventsHc_25_value),
    .io_csrio_perf_perfEventsHc_26_value(io_csrio_perf_perfEventsHc_26_value),
    .io_csrio_perf_perfEventsHc_27_value(io_csrio_perf_perfEventsHc_27_value),
    .io_csrio_perf_perfEventsHc_28_value(io_csrio_perf_perfEventsHc_28_value),
    .io_csrio_perf_perfEventsHc_29_value(io_csrio_perf_perfEventsHc_29_value),
    .io_csrio_perf_perfEventsHc_30_value(io_csrio_perf_perfEventsHc_30_value),
    .io_csrio_perf_perfEventsHc_31_value(io_csrio_perf_perfEventsHc_31_value),
    .io_csrio_perf_perfEventsHc_32_value(io_csrio_perf_perfEventsHc_32_value),
    .io_csrio_perf_perfEventsHc_33_value(io_csrio_perf_perfEventsHc_33_value),
    .io_csrio_perf_perfEventsHc_34_value(io_csrio_perf_perfEventsHc_34_value),
    .io_csrio_perf_perfEventsHc_35_value(io_csrio_perf_perfEventsHc_35_value),
    .io_csrio_perf_perfEventsHc_36_value(io_csrio_perf_perfEventsHc_36_value),
    .io_csrio_perf_perfEventsHc_37_value(io_csrio_perf_perfEventsHc_37_value),
    .io_csrio_perf_perfEventsHc_38_value(io_csrio_perf_perfEventsHc_38_value),
    .io_csrio_perf_perfEventsHc_39_value(io_csrio_perf_perfEventsHc_39_value),
    .io_csrio_perf_perfEventsHc_40_value(io_csrio_perf_perfEventsHc_40_value),
    .io_csrio_perf_perfEventsHc_41_value(io_csrio_perf_perfEventsHc_41_value),
    .io_csrio_perf_perfEventsHc_42_value(io_csrio_perf_perfEventsHc_42_value),
    .io_csrio_perf_perfEventsHc_43_value(io_csrio_perf_perfEventsHc_43_value),
    .io_csrio_perf_perfEventsHc_44_value(io_csrio_perf_perfEventsHc_44_value),
    .io_csrio_perf_perfEventsHc_45_value(io_csrio_perf_perfEventsHc_45_value),
    .io_csrio_perf_perfEventsHc_46_value(io_csrio_perf_perfEventsHc_46_value),
    .io_csrio_perf_perfEventsHc_47_value(io_csrio_perf_perfEventsHc_47_value),
    .io_csrio_perf_perfEventsHc_48_value(io_csrio_perf_perfEventsHc_48_value),
    .io_csrio_perf_perfEventsHc_49_value(io_csrio_perf_perfEventsHc_49_value),
    .io_csrio_perf_perfEventsHc_50_value(io_csrio_perf_perfEventsHc_50_value),
    .io_csrio_perf_perfEventsHc_51_value(io_csrio_perf_perfEventsHc_51_value),
    .io_csrio_perf_perfEventsHc_52_value(io_csrio_perf_perfEventsHc_52_value),
    .io_csrio_perf_perfEventsHc_53_value(io_csrio_perf_perfEventsHc_53_value),
    .io_csrio_perf_perfEventsHc_54_value(io_csrio_perf_perfEventsHc_54_value),
    .io_csrio_perf_perfEventsHc_55_value(io_csrio_perf_perfEventsHc_55_value),
    .io_csrio_perf_perfEventsHc_56_value(io_csrio_perf_perfEventsHc_56_value),
    .io_csrio_perf_perfEventsHc_57_value(io_csrio_perf_perfEventsHc_57_value),
    .io_csrio_perf_perfEventsHc_58_value(io_csrio_perf_perfEventsHc_58_value),
    .io_csrio_perf_perfEventsHc_59_value(io_csrio_perf_perfEventsHc_59_value),
    .io_csrio_perf_perfEventsHc_60_value(io_csrio_perf_perfEventsHc_60_value),
    .io_csrio_perf_perfEventsHc_61_value(io_csrio_perf_perfEventsHc_61_value),
    .io_csrio_perf_perfEventsHc_62_value(io_csrio_perf_perfEventsHc_62_value),
    .io_csrio_perf_perfEventsHc_63_value(io_csrio_perf_perfEventsHc_63_value),
    .io_csrio_perf_perfEventsHc_64_value(io_csrio_perf_perfEventsHc_64_value),
    .io_csrio_perf_perfEventsHc_65_value(io_csrio_perf_perfEventsHc_65_value),
    .io_csrio_perf_perfEventsHc_66_value(io_csrio_perf_perfEventsHc_66_value),
    .io_csrio_perf_perfEventsHc_67_value(io_csrio_perf_perfEventsHc_67_value),
    .io_csrio_perf_retiredInstr(io_csrio_perf_retiredInstr),
    .io_csrio_fpu_fflags_valid(io_csrio_fpu_fflags_valid),
    .io_csrio_fpu_fflags_bits(io_csrio_fpu_fflags_bits),
    .io_csrio_fpu_dirty_fs(io_csrio_fpu_dirty_fs),
    .io_csrio_vpu_vl(io_csrio_vpu_vl),
    .io_csrio_vpu_set_vstart_valid(io_csrio_vpu_set_vstart_valid),
    .io_csrio_vpu_set_vstart_bits(io_csrio_vpu_set_vstart_bits),
    .io_csrio_vpu_set_vtype_valid(io_csrio_vpu_set_vtype_valid),
    .io_csrio_vpu_set_vtype_bits(io_csrio_vpu_set_vtype_bits),
    .io_csrio_vpu_set_vxsat_valid(io_csrio_vpu_set_vxsat_valid),
    .io_csrio_vpu_set_vxsat_bits(io_csrio_vpu_set_vxsat_bits),
    .io_csrio_vpu_dirty_vs(io_csrio_vpu_dirty_vs),
    .io_csrio_exception_valid(io_csrio_exception_valid),
    .io_csrio_exception_bits_pc(io_csrio_exception_bits_pc),
    .io_csrio_exception_bits_instr(io_csrio_exception_bits_instr),
    .io_csrio_exception_bits_exceptionVec_0(io_csrio_exception_bits_exceptionVec_0),
    .io_csrio_exception_bits_exceptionVec_1(io_csrio_exception_bits_exceptionVec_1),
    .io_csrio_exception_bits_exceptionVec_2(io_csrio_exception_bits_exceptionVec_2),
    .io_csrio_exception_bits_exceptionVec_3(io_csrio_exception_bits_exceptionVec_3),
    .io_csrio_exception_bits_exceptionVec_4(io_csrio_exception_bits_exceptionVec_4),
    .io_csrio_exception_bits_exceptionVec_5(io_csrio_exception_bits_exceptionVec_5),
    .io_csrio_exception_bits_exceptionVec_6(io_csrio_exception_bits_exceptionVec_6),
    .io_csrio_exception_bits_exceptionVec_7(io_csrio_exception_bits_exceptionVec_7),
    .io_csrio_exception_bits_exceptionVec_8(io_csrio_exception_bits_exceptionVec_8),
    .io_csrio_exception_bits_exceptionVec_9(io_csrio_exception_bits_exceptionVec_9),
    .io_csrio_exception_bits_exceptionVec_10(io_csrio_exception_bits_exceptionVec_10),
    .io_csrio_exception_bits_exceptionVec_11(io_csrio_exception_bits_exceptionVec_11),
    .io_csrio_exception_bits_exceptionVec_12(io_csrio_exception_bits_exceptionVec_12),
    .io_csrio_exception_bits_exceptionVec_13(io_csrio_exception_bits_exceptionVec_13),
    .io_csrio_exception_bits_exceptionVec_14(io_csrio_exception_bits_exceptionVec_14),
    .io_csrio_exception_bits_exceptionVec_15(io_csrio_exception_bits_exceptionVec_15),
    .io_csrio_exception_bits_exceptionVec_16(io_csrio_exception_bits_exceptionVec_16),
    .io_csrio_exception_bits_exceptionVec_17(io_csrio_exception_bits_exceptionVec_17),
    .io_csrio_exception_bits_exceptionVec_18(io_csrio_exception_bits_exceptionVec_18),
    .io_csrio_exception_bits_exceptionVec_19(io_csrio_exception_bits_exceptionVec_19),
    .io_csrio_exception_bits_exceptionVec_20(io_csrio_exception_bits_exceptionVec_20),
    .io_csrio_exception_bits_exceptionVec_21(io_csrio_exception_bits_exceptionVec_21),
    .io_csrio_exception_bits_exceptionVec_22(io_csrio_exception_bits_exceptionVec_22),
    .io_csrio_exception_bits_exceptionVec_23(io_csrio_exception_bits_exceptionVec_23),
    .io_csrio_exception_bits_isPcBkpt(io_csrio_exception_bits_isPcBkpt),
    .io_csrio_exception_bits_isFetchMalAddr(io_csrio_exception_bits_isFetchMalAddr),
    .io_csrio_exception_bits_satpFlushFirstFetchFault(io_csrio_exception_bits_satpFlushFirstFetchFault),
    .io_csrio_exception_bits_gpaddr(io_csrio_exception_bits_gpaddr),
    .io_csrio_exception_bits_singleStep(io_csrio_exception_bits_singleStep),
    .io_csrio_exception_bits_crossPageIPFFix(io_csrio_exception_bits_crossPageIPFFix),
    .io_csrio_exception_bits_isInterrupt(io_csrio_exception_bits_isInterrupt),
    .io_csrio_exception_bits_isHls(io_csrio_exception_bits_isHls),
    .io_csrio_exception_bits_trigger(io_csrio_exception_bits_trigger),
    .io_csrio_exception_bits_isForVSnonLeafPTE(io_csrio_exception_bits_isForVSnonLeafPTE),
    .io_csrio_robDeqPtr_flag(io_csrio_robDeqPtr_flag),
    .io_csrio_robDeqPtr_value(io_csrio_robDeqPtr_value),
    .io_csrio_memExceptionVAddr(io_csrio_memExceptionVAddr),
    .io_csrio_memExceptionGPAddr(io_csrio_memExceptionGPAddr),
    .io_csrio_memExceptionIsForVSnonLeafPTE(io_csrio_memExceptionIsForVSnonLeafPTE),
    .io_csrio_externalInterrupt_mtip(io_csrio_externalInterrupt_mtip),
    .io_csrio_externalInterrupt_msip(io_csrio_externalInterrupt_msip),
    .io_csrio_externalInterrupt_meip(io_csrio_externalInterrupt_meip),
    .io_csrio_externalInterrupt_seip(io_csrio_externalInterrupt_seip),
    .io_csrio_externalInterrupt_debug(io_csrio_externalInterrupt_debug),
    .io_csrio_externalInterrupt_nmi_nmi_31(io_csrio_externalInterrupt_nmi_nmi_31),
    .io_csrio_externalInterrupt_nmi_nmi_43(io_csrio_externalInterrupt_nmi_nmi_43),
    .io_in_ready(g_out[6055 +: 1]),
    .io_out_valid(g_out[6054 +: 1]),
    .io_out_bits_ctrl_robIdx_flag(g_out[6053 +: 1]),
    .io_out_bits_ctrl_robIdx_value(g_out[6045 +: 8]),
    .io_out_bits_ctrl_pdest(g_out[6037 +: 8]),
    .io_out_bits_ctrl_rfWen(g_out[6036 +: 1]),
    .io_out_bits_ctrl_exceptionVec_2(g_out[6035 +: 1]),
    .io_out_bits_ctrl_exceptionVec_3(g_out[6034 +: 1]),
    .io_out_bits_ctrl_exceptionVec_8(g_out[6033 +: 1]),
    .io_out_bits_ctrl_exceptionVec_9(g_out[6032 +: 1]),
    .io_out_bits_ctrl_exceptionVec_10(g_out[6031 +: 1]),
    .io_out_bits_ctrl_exceptionVec_11(g_out[6030 +: 1]),
    .io_out_bits_ctrl_exceptionVec_22(g_out[6029 +: 1]),
    .io_out_bits_ctrl_flushPipe(g_out[6028 +: 1]),
    .io_out_bits_ctrl_satpFlushPipe(g_out[6027 +: 1]),
    .io_out_bits_ctrl_preDecode_valid(g_out[6026 +: 1]),
    .io_out_bits_ctrl_preDecode_isRVC(g_out[6025 +: 1]),
    .io_out_bits_ctrl_preDecode_brType(g_out[6023 +: 2]),
    .io_out_bits_ctrl_preDecode_isCall(g_out[6022 +: 1]),
    .io_out_bits_ctrl_preDecode_isRet(g_out[6021 +: 1]),
    .io_out_bits_res_data(g_out[5957 +: 64]),
    .io_out_bits_res_redirect_valid(g_out[5956 +: 1]),
    .io_out_bits_res_redirect_bits_isRVC(g_out[5955 +: 1]),
    .io_out_bits_res_redirect_bits_robIdx_flag(g_out[5954 +: 1]),
    .io_out_bits_res_redirect_bits_robIdx_value(g_out[5946 +: 8]),
    .io_out_bits_res_redirect_bits_ftqIdx_flag(g_out[5945 +: 1]),
    .io_out_bits_res_redirect_bits_ftqIdx_value(g_out[5939 +: 6]),
    .io_out_bits_res_redirect_bits_ftqOffset(g_out[5935 +: 4]),
    .io_out_bits_res_redirect_bits_level(g_out[5934 +: 1]),
    .io_out_bits_res_redirect_bits_interrupt(g_out[5933 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pc(g_out[5883 +: 50]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_valid(g_out[5882 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC(g_out[5881 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_brType(g_out[5879 +: 2]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall(g_out[5878 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet(g_out[5877 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_ssp(g_out[5873 +: 4]),
    .io_out_bits_res_redirect_bits_cfiUpdate_sctr(g_out[5870 +: 3]),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag(g_out[5869 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value(g_out[5864 +: 5]),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag(g_out[5863 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value(g_out[5858 +: 5]),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag(g_out[5857 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_value(g_out[5852 +: 5]),
    .io_out_bits_res_redirect_bits_cfiUpdate_topAddr(g_out[5802 +: 50]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist(g_out[5791 +: 11]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist(g_out[5780 +: 11]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist(g_out[5773 +: 7]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist(g_out[5765 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist(g_out[5756 +: 9]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist(g_out[5752 +: 4]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist(g_out[5744 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist(g_out[5735 +: 9]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist(g_out[5728 +: 7]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist(g_out[5720 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist(g_out[5713 +: 7]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist(g_out[5704 +: 9]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist(g_out[5697 +: 7]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist(g_out[5689 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist(g_out[5681 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist(g_out[5673 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist(g_out[5662 +: 11]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist(g_out[5654 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0(g_out[5653 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1(g_out[5652 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2(g_out[5651 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3(g_out[5650 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0(g_out[5649 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1(g_out[5648 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2(g_out[5647 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3(g_out[5646 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0(g_out[5645 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1(g_out[5644 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2(g_out[5643 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3(g_out[5642 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0(g_out[5641 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1(g_out[5640 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2(g_out[5639 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3(g_out[5638 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0(g_out[5637 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1(g_out[5636 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2(g_out[5635 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3(g_out[5634 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0(g_out[5633 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1(g_out[5632 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2(g_out[5631 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3(g_out[5630 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH(g_out[5627 +: 3]),
    .io_out_bits_res_redirect_bits_cfiUpdate_ghr(g_out[5623 +: 4]),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag(g_out[5622 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value(g_out[5614 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0(g_out[5604 +: 10]),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1(g_out[5594 +: 10]),
    .io_out_bits_res_redirect_bits_cfiUpdate_br_hit(g_out[5593 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_jr_hit(g_out[5592 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_sc_hit(g_out[5591 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_predTaken(g_out[5590 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_target(g_out[5540 +: 50]),
    .io_out_bits_res_redirect_bits_cfiUpdate_taken(g_out[5539 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_isMisPred(g_out[5538 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_shift(g_out[5536 +: 2]),
    .io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist(g_out[5535 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF(g_out[5534 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIPF(g_out[5533 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIAF(g_out[5532 +: 1]),
    .io_out_bits_res_redirect_bits_fullTarget(g_out[5468 +: 64]),
    .io_out_bits_res_redirect_bits_satpFlush(g_out[5467 +: 1]),
    .io_out_bits_res_redirect_bits_isVlsException(g_out[5466 +: 1]),
    .io_out_bits_res_redirect_bits_stFtqIdx_flag(g_out[5465 +: 1]),
    .io_out_bits_res_redirect_bits_stFtqIdx_value(g_out[5459 +: 6]),
    .io_out_bits_res_redirect_bits_stFtqOffset(g_out[5455 +: 4]),
    .io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id(g_out[5391 +: 64]),
    .io_out_bits_res_redirect_bits_debugIsCtrl(g_out[5390 +: 1]),
    .io_out_bits_res_redirect_bits_debugIsMemVio(g_out[5389 +: 1]),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_out[5388 +: 1]),
    .io_out_bits_perfDebugInfo_renameTime(g_out[5324 +: 64]),
    .io_out_bits_perfDebugInfo_dispatchTime(g_out[5260 +: 64]),
    .io_out_bits_perfDebugInfo_enqRsTime(g_out[5196 +: 64]),
    .io_out_bits_perfDebugInfo_selectTime(g_out[5132 +: 64]),
    .io_out_bits_perfDebugInfo_issueTime(g_out[5068 +: 64]),
    .io_out_bits_perfDebugInfo_writebackTime(g_out[5004 +: 64]),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_out[4940 +: 64]),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_out[4876 +: 64]),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_out[4812 +: 64]),
    .io_out_bits_debug_seqNum_seqNum(g_out[4756 +: 56]),
    .io_out_bits_debug_seqNum_uopIdx(g_out[4748 +: 8]),
    .io_csrio_criticalErrorState(g_out[4747 +: 1]),
    .io_csrio_isPerfCnt(g_out[4746 +: 1]),
    .io_csrio_fpu_frm(g_out[4743 +: 3]),
    .io_csrio_vpu_vstart(g_out[4679 +: 64]),
    .io_csrio_vpu_vxrm(g_out[4677 +: 2]),
    .io_csrio_trapTarget_pc(g_out[4613 +: 64]),
    .io_csrio_trapTarget_raiseIPF(g_out[4612 +: 1]),
    .io_csrio_trapTarget_raiseIAF(g_out[4611 +: 1]),
    .io_csrio_trapTarget_raiseIGPF(g_out[4610 +: 1]),
    .io_csrio_interrupt(g_out[4609 +: 1]),
    .io_csrio_wfi_event(g_out[4608 +: 1]),
    .io_csrio_traceCSR_cause(g_out[4544 +: 64]),
    .io_csrio_traceCSR_tval(g_out[4494 +: 50]),
    .io_csrio_traceCSR_mstatus(g_out[4430 +: 64]),
    .io_csrio_traceCSR_lastPriv(g_out[4427 +: 3]),
    .io_csrio_traceCSR_currentPriv(g_out[4424 +: 3]),
    .io_csrio_tlb_satp_mode(g_out[4420 +: 4]),
    .io_csrio_tlb_satp_asid(g_out[4404 +: 16]),
    .io_csrio_tlb_satp_ppn(g_out[4360 +: 44]),
    .io_csrio_tlb_satp_changed(g_out[4359 +: 1]),
    .io_csrio_tlb_vsatp_mode(g_out[4355 +: 4]),
    .io_csrio_tlb_vsatp_asid(g_out[4339 +: 16]),
    .io_csrio_tlb_vsatp_ppn(g_out[4295 +: 44]),
    .io_csrio_tlb_vsatp_changed(g_out[4294 +: 1]),
    .io_csrio_tlb_hgatp_mode(g_out[4290 +: 4]),
    .io_csrio_tlb_hgatp_vmid(g_out[4274 +: 16]),
    .io_csrio_tlb_hgatp_ppn(g_out[4230 +: 44]),
    .io_csrio_tlb_hgatp_changed(g_out[4229 +: 1]),
    .io_csrio_tlb_mbmc_BME(g_out[4228 +: 1]),
    .io_csrio_tlb_mbmc_CMODE(g_out[4227 +: 1]),
    .io_csrio_tlb_mbmc_BCLEAR(g_out[4226 +: 1]),
    .io_csrio_tlb_mbmc_BMA(g_out[4168 +: 58]),
    .io_csrio_tlb_priv_mxr(g_out[4167 +: 1]),
    .io_csrio_tlb_priv_sum(g_out[4166 +: 1]),
    .io_csrio_tlb_priv_vmxr(g_out[4165 +: 1]),
    .io_csrio_tlb_priv_vsum(g_out[4164 +: 1]),
    .io_csrio_tlb_priv_virt(g_out[4163 +: 1]),
    .io_csrio_tlb_priv_virt_changed(g_out[4162 +: 1]),
    .io_csrio_tlb_priv_spvp(g_out[4161 +: 1]),
    .io_csrio_tlb_priv_imode(g_out[4159 +: 2]),
    .io_csrio_tlb_priv_dmode(g_out[4157 +: 2]),
    .io_csrio_tlb_priv_debug(g_out[4156 +: 1]),
    .io_csrio_tlb_mPBMTE(g_out[4155 +: 1]),
    .io_csrio_tlb_hPBMTE(g_out[4154 +: 1]),
    .io_csrio_tlb_pmm_mseccfg(g_out[4152 +: 2]),
    .io_csrio_tlb_pmm_menvcfg(g_out[4150 +: 2]),
    .io_csrio_tlb_pmm_henvcfg(g_out[4148 +: 2]),
    .io_csrio_tlb_pmm_hstatus(g_out[4146 +: 2]),
    .io_csrio_tlb_pmm_senvcfg(g_out[4144 +: 2]),
    .io_csrio_customCtrl_pf_ctrl_l1I_pf_enable(g_out[4143 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_enable(g_out[4142 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable(g_out[4141 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit(g_out[4140 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt(g_out[4139 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht(g_out[4138 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold(g_out[4134 +: 4]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride(g_out[4128 +: 6]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride(g_out[4127 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_store_only(g_out[4126 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable(g_out[4125 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable(g_out[4124 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable(g_out[4123 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_delay_latency(g_out[4113 +: 10]),
    .io_csrio_customCtrl_lvpred_timeout(g_out[4108 +: 5]),
    .io_csrio_customCtrl_bp_ctrl_ubtb_enable(g_out[4107 +: 1]),
    .io_csrio_customCtrl_bp_ctrl_btb_enable(g_out[4106 +: 1]),
    .io_csrio_customCtrl_bp_ctrl_tage_enable(g_out[4105 +: 1]),
    .io_csrio_customCtrl_bp_ctrl_sc_enable(g_out[4104 +: 1]),
    .io_csrio_customCtrl_bp_ctrl_ras_enable(g_out[4103 +: 1]),
    .io_csrio_customCtrl_sbuffer_timeout(g_out[4081 +: 22]),
    .io_csrio_customCtrl_ldld_vio_check_enable(g_out[4080 +: 1]),
    .io_csrio_customCtrl_cache_error_enable(g_out[4079 +: 1]),
    .io_csrio_customCtrl_uncache_write_outstanding_enable(g_out[4078 +: 1]),
    .io_csrio_customCtrl_hd_misalign_st_enable(g_out[4077 +: 1]),
    .io_csrio_customCtrl_hd_misalign_ld_enable(g_out[4076 +: 1]),
    .io_csrio_customCtrl_power_down_enable(g_out[4075 +: 1]),
    .io_csrio_customCtrl_flush_l2_enable(g_out[4074 +: 1]),
    .io_csrio_customCtrl_fusion_enable(g_out[4073 +: 1]),
    .io_csrio_customCtrl_wfi_enable(g_out[4072 +: 1]),
    .io_csrio_customCtrl_distribute_csr_w_valid(g_out[4071 +: 1]),
    .io_csrio_customCtrl_distribute_csr_w_bits_addr(g_out[4059 +: 12]),
    .io_csrio_customCtrl_distribute_csr_w_bits_data(g_out[3995 +: 64]),
    .io_csrio_customCtrl_singlestep(g_out[3994 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_valid(g_out[3993 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr(g_out[3991 +: 2]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType(g_out[3989 +: 2]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select(g_out[3988 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action(g_out[3984 +: 4]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain(g_out[3983 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2(g_out[3919 +: 64]),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_0(g_out[3918 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_1(g_out[3917 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_2(g_out[3916 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_3(g_out[3915 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_debugMode(g_out[3914 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp(g_out[3913 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_valid(g_out[3912 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr(g_out[3910 +: 2]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType(g_out[3908 +: 2]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select(g_out[3907 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action(g_out[3903 +: 4]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain(g_out[3902 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store(g_out[3901 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load(g_out[3900 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2(g_out[3836 +: 64]),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_0(g_out[3835 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_1(g_out[3834 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_2(g_out[3833 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_3(g_out[3832 +: 1]),
    .io_csrio_customCtrl_mem_trigger_debugMode(g_out[3831 +: 1]),
    .io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp(g_out[3830 +: 1]),
    .io_csrio_customCtrl_fsIsOff(g_out[3829 +: 1]),
    .io_csrio_instrAddrTransType_bare(g_out[3828 +: 1]),
    .io_csrio_instrAddrTransType_sv39(g_out[3827 +: 1]),
    .io_csrio_instrAddrTransType_sv39x4(g_out[3826 +: 1]),
    .io_csrio_instrAddrTransType_sv48(g_out[3825 +: 1]),
    .io_csrio_instrAddrTransType_sv48x4(g_out[3824 +: 1]),
    .io_csrio_msiAck(g_out[3823 +: 1]),
    .io_csrToDecode_illegalInst_sfenceVMA(g_out[3822 +: 1]),
    .io_csrToDecode_illegalInst_sfencePart(g_out[3821 +: 1]),
    .io_csrToDecode_illegalInst_hfenceGVMA(g_out[3820 +: 1]),
    .io_csrToDecode_illegalInst_hfenceVVMA(g_out[3819 +: 1]),
    .io_csrToDecode_illegalInst_hlsv(g_out[3818 +: 1]),
    .io_csrToDecode_illegalInst_fsIsOff(g_out[3817 +: 1]),
    .io_csrToDecode_illegalInst_vsIsOff(g_out[3816 +: 1]),
    .io_csrToDecode_illegalInst_wfi(g_out[3815 +: 1]),
    .io_csrToDecode_illegalInst_wrs_nto(g_out[3814 +: 1]),
    .io_csrToDecode_illegalInst_frm(g_out[3813 +: 1]),
    .io_csrToDecode_illegalInst_cboZ(g_out[3812 +: 1]),
    .io_csrToDecode_illegalInst_cboCF(g_out[3811 +: 1]),
    .io_csrToDecode_illegalInst_cboI(g_out[3810 +: 1]),
    .io_csrToDecode_virtualInst_sfenceVMA(g_out[3809 +: 1]),
    .io_csrToDecode_virtualInst_sfencePart(g_out[3808 +: 1]),
    .io_csrToDecode_virtualInst_hfence(g_out[3807 +: 1]),
    .io_csrToDecode_virtualInst_hlsv(g_out[3806 +: 1]),
    .io_csrToDecode_virtualInst_wfi(g_out[3805 +: 1]),
    .io_csrToDecode_virtualInst_wrs_nto(g_out[3804 +: 1]),
    .io_csrToDecode_virtualInst_cboZ(g_out[3803 +: 1]),
    .io_csrToDecode_virtualInst_cboCF(g_out[3802 +: 1]),
    .io_csrToDecode_virtualInst_cboI(g_out[3801 +: 1]),
    .io_csrToDecode_special_cboI2F(g_out[3800 +: 1]),
    .io_error_0(g_out[3799 +: 1]),
    .gatewayIn_packed_29_bore(g_out[3626 +: 173]),
    .gatewayIn_packed_30_bore(g_out[3616 +: 10]),
    .gatewayIn_packed_31_bore(g_out[2456 +: 1160]),
    .gatewayIn_packed_32_bore(g_out[2191 +: 265]),
    .gatewayIn_packed_33_bore(g_out[1991 +: 200]),
    .gatewayIn_packed_34_bore(g_out[1535 +: 456]),
    .gatewayIn_packed_35_bore(g_out[1463 +: 72]),
    .gatewayIn_packed_36_bore(g_out[367 +: 1096]),
    .gatewayIn_packed_37_bore(g_out[348 +: 19]),
    .gatewayIn_packed_38_bore(g_out[275 +: 73]),
    .gatewayIn_packed_39_bore(g_out[10 +: 265]),
    .gatewayIn_packed_40_bore(g_out[0 +: 10])
  );
  CSR_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_ftqIdx_flag(io_flush_bits_ftqIdx_flag),
    .io_flush_bits_ftqIdx_value(io_flush_bits_ftqIdx_value),
    .io_flush_bits_ftqOffset(io_flush_bits_ftqOffset),
    .io_flush_bits_level(io_flush_bits_level),
    .io_flush_bits_cfiUpdate_backendIGPF(io_flush_bits_cfiUpdate_backendIGPF),
    .io_flush_bits_cfiUpdate_backendIPF(io_flush_bits_cfiUpdate_backendIPF),
    .io_flush_bits_cfiUpdate_backendIAF(io_flush_bits_cfiUpdate_backendIAF),
    .io_flush_bits_fullTarget(io_flush_bits_fullTarget),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen),
    .io_in_bits_ctrl_preDecode_valid(io_in_bits_ctrl_preDecode_valid),
    .io_in_bits_ctrl_preDecode_isRVC(io_in_bits_ctrl_preDecode_isRVC),
    .io_in_bits_ctrl_preDecode_brType(io_in_bits_ctrl_preDecode_brType),
    .io_in_bits_ctrl_preDecode_isCall(io_in_bits_ctrl_preDecode_isCall),
    .io_in_bits_ctrl_preDecode_isRet(io_in_bits_ctrl_preDecode_isRet),
    .io_in_bits_ctrl_ftqIdx_flag(io_in_bits_ctrl_ftqIdx_flag),
    .io_in_bits_ctrl_ftqIdx_value(io_in_bits_ctrl_ftqIdx_value),
    .io_in_bits_ctrl_ftqOffset(io_in_bits_ctrl_ftqOffset),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_csrin_hartId(io_csrin_hartId),
    .io_csrin_msiInfo_valid(io_csrin_msiInfo_valid),
    .io_csrin_msiInfo_bits(io_csrin_msiInfo_bits),
    .io_csrin_criticalErrorState(io_csrin_criticalErrorState),
    .io_csrin_clintTime_valid(io_csrin_clintTime_valid),
    .io_csrin_clintTime_bits(io_csrin_clintTime_bits),
    .io_csrin_l2FlushDone(io_csrin_l2FlushDone),
    .io_csrin_trapInstInfo_valid(io_csrin_trapInstInfo_valid),
    .io_csrin_trapInstInfo_bits_instr(io_csrin_trapInstInfo_bits_instr),
    .io_csrin_trapInstInfo_bits_ftqPtr_flag(io_csrin_trapInstInfo_bits_ftqPtr_flag),
    .io_csrin_trapInstInfo_bits_ftqPtr_value(io_csrin_trapInstInfo_bits_ftqPtr_value),
    .io_csrin_trapInstInfo_bits_ftqOffset(io_csrin_trapInstInfo_bits_ftqOffset),
    .io_csrin_fromVecExcpMod_busy(io_csrin_fromVecExcpMod_busy),
    .io_csrio_perf_perfEventsFrontend_0_value(io_csrio_perf_perfEventsFrontend_0_value),
    .io_csrio_perf_perfEventsFrontend_1_value(io_csrio_perf_perfEventsFrontend_1_value),
    .io_csrio_perf_perfEventsFrontend_2_value(io_csrio_perf_perfEventsFrontend_2_value),
    .io_csrio_perf_perfEventsFrontend_3_value(io_csrio_perf_perfEventsFrontend_3_value),
    .io_csrio_perf_perfEventsFrontend_4_value(io_csrio_perf_perfEventsFrontend_4_value),
    .io_csrio_perf_perfEventsFrontend_5_value(io_csrio_perf_perfEventsFrontend_5_value),
    .io_csrio_perf_perfEventsFrontend_6_value(io_csrio_perf_perfEventsFrontend_6_value),
    .io_csrio_perf_perfEventsFrontend_7_value(io_csrio_perf_perfEventsFrontend_7_value),
    .io_csrio_perf_perfEventsBackend_0_value(io_csrio_perf_perfEventsBackend_0_value),
    .io_csrio_perf_perfEventsBackend_1_value(io_csrio_perf_perfEventsBackend_1_value),
    .io_csrio_perf_perfEventsBackend_2_value(io_csrio_perf_perfEventsBackend_2_value),
    .io_csrio_perf_perfEventsBackend_3_value(io_csrio_perf_perfEventsBackend_3_value),
    .io_csrio_perf_perfEventsBackend_4_value(io_csrio_perf_perfEventsBackend_4_value),
    .io_csrio_perf_perfEventsBackend_5_value(io_csrio_perf_perfEventsBackend_5_value),
    .io_csrio_perf_perfEventsBackend_6_value(io_csrio_perf_perfEventsBackend_6_value),
    .io_csrio_perf_perfEventsBackend_7_value(io_csrio_perf_perfEventsBackend_7_value),
    .io_csrio_perf_perfEventsLsu_0_value(io_csrio_perf_perfEventsLsu_0_value),
    .io_csrio_perf_perfEventsLsu_1_value(io_csrio_perf_perfEventsLsu_1_value),
    .io_csrio_perf_perfEventsLsu_2_value(io_csrio_perf_perfEventsLsu_2_value),
    .io_csrio_perf_perfEventsLsu_3_value(io_csrio_perf_perfEventsLsu_3_value),
    .io_csrio_perf_perfEventsLsu_4_value(io_csrio_perf_perfEventsLsu_4_value),
    .io_csrio_perf_perfEventsLsu_5_value(io_csrio_perf_perfEventsLsu_5_value),
    .io_csrio_perf_perfEventsLsu_6_value(io_csrio_perf_perfEventsLsu_6_value),
    .io_csrio_perf_perfEventsLsu_7_value(io_csrio_perf_perfEventsLsu_7_value),
    .io_csrio_perf_perfEventsHc_0_value(io_csrio_perf_perfEventsHc_0_value),
    .io_csrio_perf_perfEventsHc_1_value(io_csrio_perf_perfEventsHc_1_value),
    .io_csrio_perf_perfEventsHc_2_value(io_csrio_perf_perfEventsHc_2_value),
    .io_csrio_perf_perfEventsHc_3_value(io_csrio_perf_perfEventsHc_3_value),
    .io_csrio_perf_perfEventsHc_4_value(io_csrio_perf_perfEventsHc_4_value),
    .io_csrio_perf_perfEventsHc_5_value(io_csrio_perf_perfEventsHc_5_value),
    .io_csrio_perf_perfEventsHc_6_value(io_csrio_perf_perfEventsHc_6_value),
    .io_csrio_perf_perfEventsHc_7_value(io_csrio_perf_perfEventsHc_7_value),
    .io_csrio_perf_perfEventsHc_8_value(io_csrio_perf_perfEventsHc_8_value),
    .io_csrio_perf_perfEventsHc_9_value(io_csrio_perf_perfEventsHc_9_value),
    .io_csrio_perf_perfEventsHc_10_value(io_csrio_perf_perfEventsHc_10_value),
    .io_csrio_perf_perfEventsHc_11_value(io_csrio_perf_perfEventsHc_11_value),
    .io_csrio_perf_perfEventsHc_12_value(io_csrio_perf_perfEventsHc_12_value),
    .io_csrio_perf_perfEventsHc_13_value(io_csrio_perf_perfEventsHc_13_value),
    .io_csrio_perf_perfEventsHc_14_value(io_csrio_perf_perfEventsHc_14_value),
    .io_csrio_perf_perfEventsHc_15_value(io_csrio_perf_perfEventsHc_15_value),
    .io_csrio_perf_perfEventsHc_16_value(io_csrio_perf_perfEventsHc_16_value),
    .io_csrio_perf_perfEventsHc_17_value(io_csrio_perf_perfEventsHc_17_value),
    .io_csrio_perf_perfEventsHc_18_value(io_csrio_perf_perfEventsHc_18_value),
    .io_csrio_perf_perfEventsHc_19_value(io_csrio_perf_perfEventsHc_19_value),
    .io_csrio_perf_perfEventsHc_20_value(io_csrio_perf_perfEventsHc_20_value),
    .io_csrio_perf_perfEventsHc_21_value(io_csrio_perf_perfEventsHc_21_value),
    .io_csrio_perf_perfEventsHc_22_value(io_csrio_perf_perfEventsHc_22_value),
    .io_csrio_perf_perfEventsHc_23_value(io_csrio_perf_perfEventsHc_23_value),
    .io_csrio_perf_perfEventsHc_24_value(io_csrio_perf_perfEventsHc_24_value),
    .io_csrio_perf_perfEventsHc_25_value(io_csrio_perf_perfEventsHc_25_value),
    .io_csrio_perf_perfEventsHc_26_value(io_csrio_perf_perfEventsHc_26_value),
    .io_csrio_perf_perfEventsHc_27_value(io_csrio_perf_perfEventsHc_27_value),
    .io_csrio_perf_perfEventsHc_28_value(io_csrio_perf_perfEventsHc_28_value),
    .io_csrio_perf_perfEventsHc_29_value(io_csrio_perf_perfEventsHc_29_value),
    .io_csrio_perf_perfEventsHc_30_value(io_csrio_perf_perfEventsHc_30_value),
    .io_csrio_perf_perfEventsHc_31_value(io_csrio_perf_perfEventsHc_31_value),
    .io_csrio_perf_perfEventsHc_32_value(io_csrio_perf_perfEventsHc_32_value),
    .io_csrio_perf_perfEventsHc_33_value(io_csrio_perf_perfEventsHc_33_value),
    .io_csrio_perf_perfEventsHc_34_value(io_csrio_perf_perfEventsHc_34_value),
    .io_csrio_perf_perfEventsHc_35_value(io_csrio_perf_perfEventsHc_35_value),
    .io_csrio_perf_perfEventsHc_36_value(io_csrio_perf_perfEventsHc_36_value),
    .io_csrio_perf_perfEventsHc_37_value(io_csrio_perf_perfEventsHc_37_value),
    .io_csrio_perf_perfEventsHc_38_value(io_csrio_perf_perfEventsHc_38_value),
    .io_csrio_perf_perfEventsHc_39_value(io_csrio_perf_perfEventsHc_39_value),
    .io_csrio_perf_perfEventsHc_40_value(io_csrio_perf_perfEventsHc_40_value),
    .io_csrio_perf_perfEventsHc_41_value(io_csrio_perf_perfEventsHc_41_value),
    .io_csrio_perf_perfEventsHc_42_value(io_csrio_perf_perfEventsHc_42_value),
    .io_csrio_perf_perfEventsHc_43_value(io_csrio_perf_perfEventsHc_43_value),
    .io_csrio_perf_perfEventsHc_44_value(io_csrio_perf_perfEventsHc_44_value),
    .io_csrio_perf_perfEventsHc_45_value(io_csrio_perf_perfEventsHc_45_value),
    .io_csrio_perf_perfEventsHc_46_value(io_csrio_perf_perfEventsHc_46_value),
    .io_csrio_perf_perfEventsHc_47_value(io_csrio_perf_perfEventsHc_47_value),
    .io_csrio_perf_perfEventsHc_48_value(io_csrio_perf_perfEventsHc_48_value),
    .io_csrio_perf_perfEventsHc_49_value(io_csrio_perf_perfEventsHc_49_value),
    .io_csrio_perf_perfEventsHc_50_value(io_csrio_perf_perfEventsHc_50_value),
    .io_csrio_perf_perfEventsHc_51_value(io_csrio_perf_perfEventsHc_51_value),
    .io_csrio_perf_perfEventsHc_52_value(io_csrio_perf_perfEventsHc_52_value),
    .io_csrio_perf_perfEventsHc_53_value(io_csrio_perf_perfEventsHc_53_value),
    .io_csrio_perf_perfEventsHc_54_value(io_csrio_perf_perfEventsHc_54_value),
    .io_csrio_perf_perfEventsHc_55_value(io_csrio_perf_perfEventsHc_55_value),
    .io_csrio_perf_perfEventsHc_56_value(io_csrio_perf_perfEventsHc_56_value),
    .io_csrio_perf_perfEventsHc_57_value(io_csrio_perf_perfEventsHc_57_value),
    .io_csrio_perf_perfEventsHc_58_value(io_csrio_perf_perfEventsHc_58_value),
    .io_csrio_perf_perfEventsHc_59_value(io_csrio_perf_perfEventsHc_59_value),
    .io_csrio_perf_perfEventsHc_60_value(io_csrio_perf_perfEventsHc_60_value),
    .io_csrio_perf_perfEventsHc_61_value(io_csrio_perf_perfEventsHc_61_value),
    .io_csrio_perf_perfEventsHc_62_value(io_csrio_perf_perfEventsHc_62_value),
    .io_csrio_perf_perfEventsHc_63_value(io_csrio_perf_perfEventsHc_63_value),
    .io_csrio_perf_perfEventsHc_64_value(io_csrio_perf_perfEventsHc_64_value),
    .io_csrio_perf_perfEventsHc_65_value(io_csrio_perf_perfEventsHc_65_value),
    .io_csrio_perf_perfEventsHc_66_value(io_csrio_perf_perfEventsHc_66_value),
    .io_csrio_perf_perfEventsHc_67_value(io_csrio_perf_perfEventsHc_67_value),
    .io_csrio_perf_retiredInstr(io_csrio_perf_retiredInstr),
    .io_csrio_fpu_fflags_valid(io_csrio_fpu_fflags_valid),
    .io_csrio_fpu_fflags_bits(io_csrio_fpu_fflags_bits),
    .io_csrio_fpu_dirty_fs(io_csrio_fpu_dirty_fs),
    .io_csrio_vpu_vl(io_csrio_vpu_vl),
    .io_csrio_vpu_set_vstart_valid(io_csrio_vpu_set_vstart_valid),
    .io_csrio_vpu_set_vstart_bits(io_csrio_vpu_set_vstart_bits),
    .io_csrio_vpu_set_vtype_valid(io_csrio_vpu_set_vtype_valid),
    .io_csrio_vpu_set_vtype_bits(io_csrio_vpu_set_vtype_bits),
    .io_csrio_vpu_set_vxsat_valid(io_csrio_vpu_set_vxsat_valid),
    .io_csrio_vpu_set_vxsat_bits(io_csrio_vpu_set_vxsat_bits),
    .io_csrio_vpu_dirty_vs(io_csrio_vpu_dirty_vs),
    .io_csrio_exception_valid(io_csrio_exception_valid),
    .io_csrio_exception_bits_pc(io_csrio_exception_bits_pc),
    .io_csrio_exception_bits_instr(io_csrio_exception_bits_instr),
    .io_csrio_exception_bits_exceptionVec_0(io_csrio_exception_bits_exceptionVec_0),
    .io_csrio_exception_bits_exceptionVec_1(io_csrio_exception_bits_exceptionVec_1),
    .io_csrio_exception_bits_exceptionVec_2(io_csrio_exception_bits_exceptionVec_2),
    .io_csrio_exception_bits_exceptionVec_3(io_csrio_exception_bits_exceptionVec_3),
    .io_csrio_exception_bits_exceptionVec_4(io_csrio_exception_bits_exceptionVec_4),
    .io_csrio_exception_bits_exceptionVec_5(io_csrio_exception_bits_exceptionVec_5),
    .io_csrio_exception_bits_exceptionVec_6(io_csrio_exception_bits_exceptionVec_6),
    .io_csrio_exception_bits_exceptionVec_7(io_csrio_exception_bits_exceptionVec_7),
    .io_csrio_exception_bits_exceptionVec_8(io_csrio_exception_bits_exceptionVec_8),
    .io_csrio_exception_bits_exceptionVec_9(io_csrio_exception_bits_exceptionVec_9),
    .io_csrio_exception_bits_exceptionVec_10(io_csrio_exception_bits_exceptionVec_10),
    .io_csrio_exception_bits_exceptionVec_11(io_csrio_exception_bits_exceptionVec_11),
    .io_csrio_exception_bits_exceptionVec_12(io_csrio_exception_bits_exceptionVec_12),
    .io_csrio_exception_bits_exceptionVec_13(io_csrio_exception_bits_exceptionVec_13),
    .io_csrio_exception_bits_exceptionVec_14(io_csrio_exception_bits_exceptionVec_14),
    .io_csrio_exception_bits_exceptionVec_15(io_csrio_exception_bits_exceptionVec_15),
    .io_csrio_exception_bits_exceptionVec_16(io_csrio_exception_bits_exceptionVec_16),
    .io_csrio_exception_bits_exceptionVec_17(io_csrio_exception_bits_exceptionVec_17),
    .io_csrio_exception_bits_exceptionVec_18(io_csrio_exception_bits_exceptionVec_18),
    .io_csrio_exception_bits_exceptionVec_19(io_csrio_exception_bits_exceptionVec_19),
    .io_csrio_exception_bits_exceptionVec_20(io_csrio_exception_bits_exceptionVec_20),
    .io_csrio_exception_bits_exceptionVec_21(io_csrio_exception_bits_exceptionVec_21),
    .io_csrio_exception_bits_exceptionVec_22(io_csrio_exception_bits_exceptionVec_22),
    .io_csrio_exception_bits_exceptionVec_23(io_csrio_exception_bits_exceptionVec_23),
    .io_csrio_exception_bits_isPcBkpt(io_csrio_exception_bits_isPcBkpt),
    .io_csrio_exception_bits_isFetchMalAddr(io_csrio_exception_bits_isFetchMalAddr),
    .io_csrio_exception_bits_satpFlushFirstFetchFault(io_csrio_exception_bits_satpFlushFirstFetchFault),
    .io_csrio_exception_bits_gpaddr(io_csrio_exception_bits_gpaddr),
    .io_csrio_exception_bits_singleStep(io_csrio_exception_bits_singleStep),
    .io_csrio_exception_bits_crossPageIPFFix(io_csrio_exception_bits_crossPageIPFFix),
    .io_csrio_exception_bits_isInterrupt(io_csrio_exception_bits_isInterrupt),
    .io_csrio_exception_bits_isHls(io_csrio_exception_bits_isHls),
    .io_csrio_exception_bits_trigger(io_csrio_exception_bits_trigger),
    .io_csrio_exception_bits_isForVSnonLeafPTE(io_csrio_exception_bits_isForVSnonLeafPTE),
    .io_csrio_robDeqPtr_flag(io_csrio_robDeqPtr_flag),
    .io_csrio_robDeqPtr_value(io_csrio_robDeqPtr_value),
    .io_csrio_memExceptionVAddr(io_csrio_memExceptionVAddr),
    .io_csrio_memExceptionGPAddr(io_csrio_memExceptionGPAddr),
    .io_csrio_memExceptionIsForVSnonLeafPTE(io_csrio_memExceptionIsForVSnonLeafPTE),
    .io_csrio_externalInterrupt_mtip(io_csrio_externalInterrupt_mtip),
    .io_csrio_externalInterrupt_msip(io_csrio_externalInterrupt_msip),
    .io_csrio_externalInterrupt_meip(io_csrio_externalInterrupt_meip),
    .io_csrio_externalInterrupt_seip(io_csrio_externalInterrupt_seip),
    .io_csrio_externalInterrupt_debug(io_csrio_externalInterrupt_debug),
    .io_csrio_externalInterrupt_nmi_nmi_31(io_csrio_externalInterrupt_nmi_nmi_31),
    .io_csrio_externalInterrupt_nmi_nmi_43(io_csrio_externalInterrupt_nmi_nmi_43),
    .io_in_ready(i_out[6055 +: 1]),
    .io_out_valid(i_out[6054 +: 1]),
    .io_out_bits_ctrl_robIdx_flag(i_out[6053 +: 1]),
    .io_out_bits_ctrl_robIdx_value(i_out[6045 +: 8]),
    .io_out_bits_ctrl_pdest(i_out[6037 +: 8]),
    .io_out_bits_ctrl_rfWen(i_out[6036 +: 1]),
    .io_out_bits_ctrl_exceptionVec_2(i_out[6035 +: 1]),
    .io_out_bits_ctrl_exceptionVec_3(i_out[6034 +: 1]),
    .io_out_bits_ctrl_exceptionVec_8(i_out[6033 +: 1]),
    .io_out_bits_ctrl_exceptionVec_9(i_out[6032 +: 1]),
    .io_out_bits_ctrl_exceptionVec_10(i_out[6031 +: 1]),
    .io_out_bits_ctrl_exceptionVec_11(i_out[6030 +: 1]),
    .io_out_bits_ctrl_exceptionVec_22(i_out[6029 +: 1]),
    .io_out_bits_ctrl_flushPipe(i_out[6028 +: 1]),
    .io_out_bits_ctrl_satpFlushPipe(i_out[6027 +: 1]),
    .io_out_bits_ctrl_preDecode_valid(i_out[6026 +: 1]),
    .io_out_bits_ctrl_preDecode_isRVC(i_out[6025 +: 1]),
    .io_out_bits_ctrl_preDecode_brType(i_out[6023 +: 2]),
    .io_out_bits_ctrl_preDecode_isCall(i_out[6022 +: 1]),
    .io_out_bits_ctrl_preDecode_isRet(i_out[6021 +: 1]),
    .io_out_bits_res_data(i_out[5957 +: 64]),
    .io_out_bits_res_redirect_valid(i_out[5956 +: 1]),
    .io_out_bits_res_redirect_bits_isRVC(i_out[5955 +: 1]),
    .io_out_bits_res_redirect_bits_robIdx_flag(i_out[5954 +: 1]),
    .io_out_bits_res_redirect_bits_robIdx_value(i_out[5946 +: 8]),
    .io_out_bits_res_redirect_bits_ftqIdx_flag(i_out[5945 +: 1]),
    .io_out_bits_res_redirect_bits_ftqIdx_value(i_out[5939 +: 6]),
    .io_out_bits_res_redirect_bits_ftqOffset(i_out[5935 +: 4]),
    .io_out_bits_res_redirect_bits_level(i_out[5934 +: 1]),
    .io_out_bits_res_redirect_bits_interrupt(i_out[5933 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pc(i_out[5883 +: 50]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_valid(i_out[5882 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC(i_out[5881 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_brType(i_out[5879 +: 2]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall(i_out[5878 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet(i_out[5877 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_ssp(i_out[5873 +: 4]),
    .io_out_bits_res_redirect_bits_cfiUpdate_sctr(i_out[5870 +: 3]),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag(i_out[5869 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value(i_out[5864 +: 5]),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag(i_out[5863 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value(i_out[5858 +: 5]),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag(i_out[5857 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_value(i_out[5852 +: 5]),
    .io_out_bits_res_redirect_bits_cfiUpdate_topAddr(i_out[5802 +: 50]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist(i_out[5791 +: 11]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist(i_out[5780 +: 11]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist(i_out[5773 +: 7]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist(i_out[5765 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist(i_out[5756 +: 9]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist(i_out[5752 +: 4]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist(i_out[5744 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist(i_out[5735 +: 9]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist(i_out[5728 +: 7]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist(i_out[5720 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist(i_out[5713 +: 7]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist(i_out[5704 +: 9]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist(i_out[5697 +: 7]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist(i_out[5689 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist(i_out[5681 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist(i_out[5673 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist(i_out[5662 +: 11]),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist(i_out[5654 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0(i_out[5653 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1(i_out[5652 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2(i_out[5651 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3(i_out[5650 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0(i_out[5649 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1(i_out[5648 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2(i_out[5647 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3(i_out[5646 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0(i_out[5645 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1(i_out[5644 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2(i_out[5643 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3(i_out[5642 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0(i_out[5641 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1(i_out[5640 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2(i_out[5639 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3(i_out[5638 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0(i_out[5637 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1(i_out[5636 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2(i_out[5635 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3(i_out[5634 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0(i_out[5633 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1(i_out[5632 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2(i_out[5631 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3(i_out[5630 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH(i_out[5627 +: 3]),
    .io_out_bits_res_redirect_bits_cfiUpdate_ghr(i_out[5623 +: 4]),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag(i_out[5622 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value(i_out[5614 +: 8]),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0(i_out[5604 +: 10]),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1(i_out[5594 +: 10]),
    .io_out_bits_res_redirect_bits_cfiUpdate_br_hit(i_out[5593 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_jr_hit(i_out[5592 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_sc_hit(i_out[5591 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_predTaken(i_out[5590 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_target(i_out[5540 +: 50]),
    .io_out_bits_res_redirect_bits_cfiUpdate_taken(i_out[5539 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_isMisPred(i_out[5538 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_shift(i_out[5536 +: 2]),
    .io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist(i_out[5535 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF(i_out[5534 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIPF(i_out[5533 +: 1]),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIAF(i_out[5532 +: 1]),
    .io_out_bits_res_redirect_bits_fullTarget(i_out[5468 +: 64]),
    .io_out_bits_res_redirect_bits_satpFlush(i_out[5467 +: 1]),
    .io_out_bits_res_redirect_bits_isVlsException(i_out[5466 +: 1]),
    .io_out_bits_res_redirect_bits_stFtqIdx_flag(i_out[5465 +: 1]),
    .io_out_bits_res_redirect_bits_stFtqIdx_value(i_out[5459 +: 6]),
    .io_out_bits_res_redirect_bits_stFtqOffset(i_out[5455 +: 4]),
    .io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id(i_out[5391 +: 64]),
    .io_out_bits_res_redirect_bits_debugIsCtrl(i_out[5390 +: 1]),
    .io_out_bits_res_redirect_bits_debugIsMemVio(i_out[5389 +: 1]),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_out[5388 +: 1]),
    .io_out_bits_perfDebugInfo_renameTime(i_out[5324 +: 64]),
    .io_out_bits_perfDebugInfo_dispatchTime(i_out[5260 +: 64]),
    .io_out_bits_perfDebugInfo_enqRsTime(i_out[5196 +: 64]),
    .io_out_bits_perfDebugInfo_selectTime(i_out[5132 +: 64]),
    .io_out_bits_perfDebugInfo_issueTime(i_out[5068 +: 64]),
    .io_out_bits_perfDebugInfo_writebackTime(i_out[5004 +: 64]),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_out[4940 +: 64]),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_out[4876 +: 64]),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_out[4812 +: 64]),
    .io_out_bits_debug_seqNum_seqNum(i_out[4756 +: 56]),
    .io_out_bits_debug_seqNum_uopIdx(i_out[4748 +: 8]),
    .io_csrio_criticalErrorState(i_out[4747 +: 1]),
    .io_csrio_isPerfCnt(i_out[4746 +: 1]),
    .io_csrio_fpu_frm(i_out[4743 +: 3]),
    .io_csrio_vpu_vstart(i_out[4679 +: 64]),
    .io_csrio_vpu_vxrm(i_out[4677 +: 2]),
    .io_csrio_trapTarget_pc(i_out[4613 +: 64]),
    .io_csrio_trapTarget_raiseIPF(i_out[4612 +: 1]),
    .io_csrio_trapTarget_raiseIAF(i_out[4611 +: 1]),
    .io_csrio_trapTarget_raiseIGPF(i_out[4610 +: 1]),
    .io_csrio_interrupt(i_out[4609 +: 1]),
    .io_csrio_wfi_event(i_out[4608 +: 1]),
    .io_csrio_traceCSR_cause(i_out[4544 +: 64]),
    .io_csrio_traceCSR_tval(i_out[4494 +: 50]),
    .io_csrio_traceCSR_mstatus(i_out[4430 +: 64]),
    .io_csrio_traceCSR_lastPriv(i_out[4427 +: 3]),
    .io_csrio_traceCSR_currentPriv(i_out[4424 +: 3]),
    .io_csrio_tlb_satp_mode(i_out[4420 +: 4]),
    .io_csrio_tlb_satp_asid(i_out[4404 +: 16]),
    .io_csrio_tlb_satp_ppn(i_out[4360 +: 44]),
    .io_csrio_tlb_satp_changed(i_out[4359 +: 1]),
    .io_csrio_tlb_vsatp_mode(i_out[4355 +: 4]),
    .io_csrio_tlb_vsatp_asid(i_out[4339 +: 16]),
    .io_csrio_tlb_vsatp_ppn(i_out[4295 +: 44]),
    .io_csrio_tlb_vsatp_changed(i_out[4294 +: 1]),
    .io_csrio_tlb_hgatp_mode(i_out[4290 +: 4]),
    .io_csrio_tlb_hgatp_vmid(i_out[4274 +: 16]),
    .io_csrio_tlb_hgatp_ppn(i_out[4230 +: 44]),
    .io_csrio_tlb_hgatp_changed(i_out[4229 +: 1]),
    .io_csrio_tlb_mbmc_BME(i_out[4228 +: 1]),
    .io_csrio_tlb_mbmc_CMODE(i_out[4227 +: 1]),
    .io_csrio_tlb_mbmc_BCLEAR(i_out[4226 +: 1]),
    .io_csrio_tlb_mbmc_BMA(i_out[4168 +: 58]),
    .io_csrio_tlb_priv_mxr(i_out[4167 +: 1]),
    .io_csrio_tlb_priv_sum(i_out[4166 +: 1]),
    .io_csrio_tlb_priv_vmxr(i_out[4165 +: 1]),
    .io_csrio_tlb_priv_vsum(i_out[4164 +: 1]),
    .io_csrio_tlb_priv_virt(i_out[4163 +: 1]),
    .io_csrio_tlb_priv_virt_changed(i_out[4162 +: 1]),
    .io_csrio_tlb_priv_spvp(i_out[4161 +: 1]),
    .io_csrio_tlb_priv_imode(i_out[4159 +: 2]),
    .io_csrio_tlb_priv_dmode(i_out[4157 +: 2]),
    .io_csrio_tlb_priv_debug(i_out[4156 +: 1]),
    .io_csrio_tlb_mPBMTE(i_out[4155 +: 1]),
    .io_csrio_tlb_hPBMTE(i_out[4154 +: 1]),
    .io_csrio_tlb_pmm_mseccfg(i_out[4152 +: 2]),
    .io_csrio_tlb_pmm_menvcfg(i_out[4150 +: 2]),
    .io_csrio_tlb_pmm_henvcfg(i_out[4148 +: 2]),
    .io_csrio_tlb_pmm_hstatus(i_out[4146 +: 2]),
    .io_csrio_tlb_pmm_senvcfg(i_out[4144 +: 2]),
    .io_csrio_customCtrl_pf_ctrl_l1I_pf_enable(i_out[4143 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_enable(i_out[4142 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable(i_out[4141 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit(i_out[4140 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt(i_out[4139 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht(i_out[4138 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold(i_out[4134 +: 4]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride(i_out[4128 +: 6]),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride(i_out[4127 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_store_only(i_out[4126 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable(i_out[4125 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable(i_out[4124 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable(i_out[4123 +: 1]),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_delay_latency(i_out[4113 +: 10]),
    .io_csrio_customCtrl_lvpred_timeout(i_out[4108 +: 5]),
    .io_csrio_customCtrl_bp_ctrl_ubtb_enable(i_out[4107 +: 1]),
    .io_csrio_customCtrl_bp_ctrl_btb_enable(i_out[4106 +: 1]),
    .io_csrio_customCtrl_bp_ctrl_tage_enable(i_out[4105 +: 1]),
    .io_csrio_customCtrl_bp_ctrl_sc_enable(i_out[4104 +: 1]),
    .io_csrio_customCtrl_bp_ctrl_ras_enable(i_out[4103 +: 1]),
    .io_csrio_customCtrl_sbuffer_timeout(i_out[4081 +: 22]),
    .io_csrio_customCtrl_ldld_vio_check_enable(i_out[4080 +: 1]),
    .io_csrio_customCtrl_cache_error_enable(i_out[4079 +: 1]),
    .io_csrio_customCtrl_uncache_write_outstanding_enable(i_out[4078 +: 1]),
    .io_csrio_customCtrl_hd_misalign_st_enable(i_out[4077 +: 1]),
    .io_csrio_customCtrl_hd_misalign_ld_enable(i_out[4076 +: 1]),
    .io_csrio_customCtrl_power_down_enable(i_out[4075 +: 1]),
    .io_csrio_customCtrl_flush_l2_enable(i_out[4074 +: 1]),
    .io_csrio_customCtrl_fusion_enable(i_out[4073 +: 1]),
    .io_csrio_customCtrl_wfi_enable(i_out[4072 +: 1]),
    .io_csrio_customCtrl_distribute_csr_w_valid(i_out[4071 +: 1]),
    .io_csrio_customCtrl_distribute_csr_w_bits_addr(i_out[4059 +: 12]),
    .io_csrio_customCtrl_distribute_csr_w_bits_data(i_out[3995 +: 64]),
    .io_csrio_customCtrl_singlestep(i_out[3994 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_valid(i_out[3993 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr(i_out[3991 +: 2]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType(i_out[3989 +: 2]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select(i_out[3988 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action(i_out[3984 +: 4]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain(i_out[3983 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2(i_out[3919 +: 64]),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_0(i_out[3918 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_1(i_out[3917 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_2(i_out[3916 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_3(i_out[3915 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_debugMode(i_out[3914 +: 1]),
    .io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp(i_out[3913 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_valid(i_out[3912 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr(i_out[3910 +: 2]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType(i_out[3908 +: 2]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select(i_out[3907 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action(i_out[3903 +: 4]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain(i_out[3902 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store(i_out[3901 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load(i_out[3900 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2(i_out[3836 +: 64]),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_0(i_out[3835 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_1(i_out[3834 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_2(i_out[3833 +: 1]),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_3(i_out[3832 +: 1]),
    .io_csrio_customCtrl_mem_trigger_debugMode(i_out[3831 +: 1]),
    .io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp(i_out[3830 +: 1]),
    .io_csrio_customCtrl_fsIsOff(i_out[3829 +: 1]),
    .io_csrio_instrAddrTransType_bare(i_out[3828 +: 1]),
    .io_csrio_instrAddrTransType_sv39(i_out[3827 +: 1]),
    .io_csrio_instrAddrTransType_sv39x4(i_out[3826 +: 1]),
    .io_csrio_instrAddrTransType_sv48(i_out[3825 +: 1]),
    .io_csrio_instrAddrTransType_sv48x4(i_out[3824 +: 1]),
    .io_csrio_msiAck(i_out[3823 +: 1]),
    .io_csrToDecode_illegalInst_sfenceVMA(i_out[3822 +: 1]),
    .io_csrToDecode_illegalInst_sfencePart(i_out[3821 +: 1]),
    .io_csrToDecode_illegalInst_hfenceGVMA(i_out[3820 +: 1]),
    .io_csrToDecode_illegalInst_hfenceVVMA(i_out[3819 +: 1]),
    .io_csrToDecode_illegalInst_hlsv(i_out[3818 +: 1]),
    .io_csrToDecode_illegalInst_fsIsOff(i_out[3817 +: 1]),
    .io_csrToDecode_illegalInst_vsIsOff(i_out[3816 +: 1]),
    .io_csrToDecode_illegalInst_wfi(i_out[3815 +: 1]),
    .io_csrToDecode_illegalInst_wrs_nto(i_out[3814 +: 1]),
    .io_csrToDecode_illegalInst_frm(i_out[3813 +: 1]),
    .io_csrToDecode_illegalInst_cboZ(i_out[3812 +: 1]),
    .io_csrToDecode_illegalInst_cboCF(i_out[3811 +: 1]),
    .io_csrToDecode_illegalInst_cboI(i_out[3810 +: 1]),
    .io_csrToDecode_virtualInst_sfenceVMA(i_out[3809 +: 1]),
    .io_csrToDecode_virtualInst_sfencePart(i_out[3808 +: 1]),
    .io_csrToDecode_virtualInst_hfence(i_out[3807 +: 1]),
    .io_csrToDecode_virtualInst_hlsv(i_out[3806 +: 1]),
    .io_csrToDecode_virtualInst_wfi(i_out[3805 +: 1]),
    .io_csrToDecode_virtualInst_wrs_nto(i_out[3804 +: 1]),
    .io_csrToDecode_virtualInst_cboZ(i_out[3803 +: 1]),
    .io_csrToDecode_virtualInst_cboCF(i_out[3802 +: 1]),
    .io_csrToDecode_virtualInst_cboI(i_out[3801 +: 1]),
    .io_csrToDecode_special_cboI2F(i_out[3800 +: 1]),
    .io_error_0(i_out[3799 +: 1]),
    .gatewayIn_packed_29_bore(i_out[3626 +: 173]),
    .gatewayIn_packed_30_bore(i_out[3616 +: 10]),
    .gatewayIn_packed_31_bore(i_out[2456 +: 1160]),
    .gatewayIn_packed_32_bore(i_out[2191 +: 265]),
    .gatewayIn_packed_33_bore(i_out[1991 +: 200]),
    .gatewayIn_packed_34_bore(i_out[1535 +: 456]),
    .gatewayIn_packed_35_bore(i_out[1463 +: 72]),
    .gatewayIn_packed_36_bore(i_out[367 +: 1096]),
    .gatewayIn_packed_37_bore(i_out[348 +: 19]),
    .gatewayIn_packed_38_bore(i_out[275 +: 73]),
    .gatewayIn_packed_39_bore(i_out[10 +: 265]),
    .gatewayIn_packed_40_bore(i_out[0 +: 10])
  );
  localparam string ONAME [NOUT] = '{"io_in_ready", "io_out_valid", "io_out_bits_ctrl_robIdx_flag", "io_out_bits_ctrl_robIdx_value", "io_out_bits_ctrl_pdest", "io_out_bits_ctrl_rfWen", "io_out_bits_ctrl_exceptionVec_2", "io_out_bits_ctrl_exceptionVec_3", "io_out_bits_ctrl_exceptionVec_8", "io_out_bits_ctrl_exceptionVec_9", "io_out_bits_ctrl_exceptionVec_10", "io_out_bits_ctrl_exceptionVec_11", "io_out_bits_ctrl_exceptionVec_22", "io_out_bits_ctrl_flushPipe", "io_out_bits_ctrl_satpFlushPipe", "io_out_bits_ctrl_preDecode_valid", "io_out_bits_ctrl_preDecode_isRVC", "io_out_bits_ctrl_preDecode_brType", "io_out_bits_ctrl_preDecode_isCall", "io_out_bits_ctrl_preDecode_isRet", "io_out_bits_res_data", "io_out_bits_res_redirect_valid", "io_out_bits_res_redirect_bits_isRVC", "io_out_bits_res_redirect_bits_robIdx_flag", "io_out_bits_res_redirect_bits_robIdx_value", "io_out_bits_res_redirect_bits_ftqIdx_flag", "io_out_bits_res_redirect_bits_ftqIdx_value", "io_out_bits_res_redirect_bits_ftqOffset", "io_out_bits_res_redirect_bits_level", "io_out_bits_res_redirect_bits_interrupt", "io_out_bits_res_redirect_bits_cfiUpdate_pc", "io_out_bits_res_redirect_bits_cfiUpdate_pd_valid", "io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC", "io_out_bits_res_redirect_bits_cfiUpdate_pd_brType", "io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall", "io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet", "io_out_bits_res_redirect_bits_cfiUpdate_ssp", "io_out_bits_res_redirect_bits_cfiUpdate_sctr", "io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag", "io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value", "io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag", "io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value", "io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag", "io_out_bits_res_redirect_bits_cfiUpdate_NOS_value", "io_out_bits_res_redirect_bits_cfiUpdate_topAddr", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2", "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3", "io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH", "io_out_bits_res_redirect_bits_cfiUpdate_ghr", "io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag", "io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value", "io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0", "io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1", "io_out_bits_res_redirect_bits_cfiUpdate_br_hit", "io_out_bits_res_redirect_bits_cfiUpdate_jr_hit", "io_out_bits_res_redirect_bits_cfiUpdate_sc_hit", "io_out_bits_res_redirect_bits_cfiUpdate_predTaken", "io_out_bits_res_redirect_bits_cfiUpdate_target", "io_out_bits_res_redirect_bits_cfiUpdate_taken", "io_out_bits_res_redirect_bits_cfiUpdate_isMisPred", "io_out_bits_res_redirect_bits_cfiUpdate_shift", "io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist", "io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF", "io_out_bits_res_redirect_bits_cfiUpdate_backendIPF", "io_out_bits_res_redirect_bits_cfiUpdate_backendIAF", "io_out_bits_res_redirect_bits_fullTarget", "io_out_bits_res_redirect_bits_satpFlush", "io_out_bits_res_redirect_bits_isVlsException", "io_out_bits_res_redirect_bits_stFtqIdx_flag", "io_out_bits_res_redirect_bits_stFtqIdx_value", "io_out_bits_res_redirect_bits_stFtqOffset", "io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id", "io_out_bits_res_redirect_bits_debugIsCtrl", "io_out_bits_res_redirect_bits_debugIsMemVio", "io_out_bits_perfDebugInfo_eliminatedMove", "io_out_bits_perfDebugInfo_renameTime", "io_out_bits_perfDebugInfo_dispatchTime", "io_out_bits_perfDebugInfo_enqRsTime", "io_out_bits_perfDebugInfo_selectTime", "io_out_bits_perfDebugInfo_issueTime", "io_out_bits_perfDebugInfo_writebackTime", "io_out_bits_perfDebugInfo_runahead_checkpoint_id", "io_out_bits_perfDebugInfo_tlbFirstReqTime", "io_out_bits_perfDebugInfo_tlbRespTime", "io_out_bits_debug_seqNum_seqNum", "io_out_bits_debug_seqNum_uopIdx", "io_csrio_criticalErrorState", "io_csrio_isPerfCnt", "io_csrio_fpu_frm", "io_csrio_vpu_vstart", "io_csrio_vpu_vxrm", "io_csrio_trapTarget_pc", "io_csrio_trapTarget_raiseIPF", "io_csrio_trapTarget_raiseIAF", "io_csrio_trapTarget_raiseIGPF", "io_csrio_interrupt", "io_csrio_wfi_event", "io_csrio_traceCSR_cause", "io_csrio_traceCSR_tval", "io_csrio_traceCSR_mstatus", "io_csrio_traceCSR_lastPriv", "io_csrio_traceCSR_currentPriv", "io_csrio_tlb_satp_mode", "io_csrio_tlb_satp_asid", "io_csrio_tlb_satp_ppn", "io_csrio_tlb_satp_changed", "io_csrio_tlb_vsatp_mode", "io_csrio_tlb_vsatp_asid", "io_csrio_tlb_vsatp_ppn", "io_csrio_tlb_vsatp_changed", "io_csrio_tlb_hgatp_mode", "io_csrio_tlb_hgatp_vmid", "io_csrio_tlb_hgatp_ppn", "io_csrio_tlb_hgatp_changed", "io_csrio_tlb_mbmc_BME", "io_csrio_tlb_mbmc_CMODE", "io_csrio_tlb_mbmc_BCLEAR", "io_csrio_tlb_mbmc_BMA", "io_csrio_tlb_priv_mxr", "io_csrio_tlb_priv_sum", "io_csrio_tlb_priv_vmxr", "io_csrio_tlb_priv_vsum", "io_csrio_tlb_priv_virt", "io_csrio_tlb_priv_virt_changed", "io_csrio_tlb_priv_spvp", "io_csrio_tlb_priv_imode", "io_csrio_tlb_priv_dmode", "io_csrio_tlb_priv_debug", "io_csrio_tlb_mPBMTE", "io_csrio_tlb_hPBMTE", "io_csrio_tlb_pmm_mseccfg", "io_csrio_tlb_pmm_menvcfg", "io_csrio_tlb_pmm_henvcfg", "io_csrio_tlb_pmm_hstatus", "io_csrio_tlb_pmm_senvcfg", "io_csrio_customCtrl_pf_ctrl_l1I_pf_enable", "io_csrio_customCtrl_pf_ctrl_l2_pf_enable", "io_csrio_customCtrl_pf_ctrl_l1D_pf_enable", "io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit", "io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt", "io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht", "io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold", "io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride", "io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride", "io_csrio_customCtrl_pf_ctrl_l2_pf_store_only", "io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable", "io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable", "io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable", "io_csrio_customCtrl_pf_ctrl_l2_pf_delay_latency", "io_csrio_customCtrl_lvpred_timeout", "io_csrio_customCtrl_bp_ctrl_ubtb_enable", "io_csrio_customCtrl_bp_ctrl_btb_enable", "io_csrio_customCtrl_bp_ctrl_tage_enable", "io_csrio_customCtrl_bp_ctrl_sc_enable", "io_csrio_customCtrl_bp_ctrl_ras_enable", "io_csrio_customCtrl_sbuffer_timeout", "io_csrio_customCtrl_ldld_vio_check_enable", "io_csrio_customCtrl_cache_error_enable", "io_csrio_customCtrl_uncache_write_outstanding_enable", "io_csrio_customCtrl_hd_misalign_st_enable", "io_csrio_customCtrl_hd_misalign_ld_enable", "io_csrio_customCtrl_power_down_enable", "io_csrio_customCtrl_flush_l2_enable", "io_csrio_customCtrl_fusion_enable", "io_csrio_customCtrl_wfi_enable", "io_csrio_customCtrl_distribute_csr_w_valid", "io_csrio_customCtrl_distribute_csr_w_bits_addr", "io_csrio_customCtrl_distribute_csr_w_bits_data", "io_csrio_customCtrl_singlestep", "io_csrio_customCtrl_frontend_trigger_tUpdate_valid", "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr", "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType", "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select", "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action", "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain", "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2", "io_csrio_customCtrl_frontend_trigger_tEnableVec_0", "io_csrio_customCtrl_frontend_trigger_tEnableVec_1", "io_csrio_customCtrl_frontend_trigger_tEnableVec_2", "io_csrio_customCtrl_frontend_trigger_tEnableVec_3", "io_csrio_customCtrl_frontend_trigger_debugMode", "io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp", "io_csrio_customCtrl_mem_trigger_tUpdate_valid", "io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr", "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType", "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select", "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action", "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain", "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store", "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load", "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2", "io_csrio_customCtrl_mem_trigger_tEnableVec_0", "io_csrio_customCtrl_mem_trigger_tEnableVec_1", "io_csrio_customCtrl_mem_trigger_tEnableVec_2", "io_csrio_customCtrl_mem_trigger_tEnableVec_3", "io_csrio_customCtrl_mem_trigger_debugMode", "io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp", "io_csrio_customCtrl_fsIsOff", "io_csrio_instrAddrTransType_bare", "io_csrio_instrAddrTransType_sv39", "io_csrio_instrAddrTransType_sv39x4", "io_csrio_instrAddrTransType_sv48", "io_csrio_instrAddrTransType_sv48x4", "io_csrio_msiAck", "io_csrToDecode_illegalInst_sfenceVMA", "io_csrToDecode_illegalInst_sfencePart", "io_csrToDecode_illegalInst_hfenceGVMA", "io_csrToDecode_illegalInst_hfenceVVMA", "io_csrToDecode_illegalInst_hlsv", "io_csrToDecode_illegalInst_fsIsOff", "io_csrToDecode_illegalInst_vsIsOff", "io_csrToDecode_illegalInst_wfi", "io_csrToDecode_illegalInst_wrs_nto", "io_csrToDecode_illegalInst_frm", "io_csrToDecode_illegalInst_cboZ", "io_csrToDecode_illegalInst_cboCF", "io_csrToDecode_illegalInst_cboI", "io_csrToDecode_virtualInst_sfenceVMA", "io_csrToDecode_virtualInst_sfencePart", "io_csrToDecode_virtualInst_hfence", "io_csrToDecode_virtualInst_hlsv", "io_csrToDecode_virtualInst_wfi", "io_csrToDecode_virtualInst_wrs_nto", "io_csrToDecode_virtualInst_cboZ", "io_csrToDecode_virtualInst_cboCF", "io_csrToDecode_virtualInst_cboI", "io_csrToDecode_special_cboI2F", "io_error_0", "gatewayIn_packed_29_bore", "gatewayIn_packed_30_bore", "gatewayIn_packed_31_bore", "gatewayIn_packed_32_bore", "gatewayIn_packed_33_bore", "gatewayIn_packed_34_bore", "gatewayIn_packed_35_bore", "gatewayIn_packed_36_bore", "gatewayIn_packed_37_bore", "gatewayIn_packed_38_bore", "gatewayIn_packed_39_bore", "gatewayIn_packed_40_bore"};
  localparam int OLSB [NOUT] = '{6055, 6054, 6053, 6045, 6037, 6036, 6035, 6034, 6033, 6032, 6031, 6030, 6029, 6028, 6027, 6026, 6025, 6023, 6022, 6021, 5957, 5956, 5955, 5954, 5946, 5945, 5939, 5935, 5934, 5933, 5883, 5882, 5881, 5879, 5878, 5877, 5873, 5870, 5869, 5864, 5863, 5858, 5857, 5852, 5802, 5791, 5780, 5773, 5765, 5756, 5752, 5744, 5735, 5728, 5720, 5713, 5704, 5697, 5689, 5681, 5673, 5662, 5654, 5653, 5652, 5651, 5650, 5649, 5648, 5647, 5646, 5645, 5644, 5643, 5642, 5641, 5640, 5639, 5638, 5637, 5636, 5635, 5634, 5633, 5632, 5631, 5630, 5627, 5623, 5622, 5614, 5604, 5594, 5593, 5592, 5591, 5590, 5540, 5539, 5538, 5536, 5535, 5534, 5533, 5532, 5468, 5467, 5466, 5465, 5459, 5455, 5391, 5390, 5389, 5388, 5324, 5260, 5196, 5132, 5068, 5004, 4940, 4876, 4812, 4756, 4748, 4747, 4746, 4743, 4679, 4677, 4613, 4612, 4611, 4610, 4609, 4608, 4544, 4494, 4430, 4427, 4424, 4420, 4404, 4360, 4359, 4355, 4339, 4295, 4294, 4290, 4274, 4230, 4229, 4228, 4227, 4226, 4168, 4167, 4166, 4165, 4164, 4163, 4162, 4161, 4159, 4157, 4156, 4155, 4154, 4152, 4150, 4148, 4146, 4144, 4143, 4142, 4141, 4140, 4139, 4138, 4134, 4128, 4127, 4126, 4125, 4124, 4123, 4113, 4108, 4107, 4106, 4105, 4104, 4103, 4081, 4080, 4079, 4078, 4077, 4076, 4075, 4074, 4073, 4072, 4071, 4059, 3995, 3994, 3993, 3991, 3989, 3988, 3984, 3983, 3919, 3918, 3917, 3916, 3915, 3914, 3913, 3912, 3910, 3908, 3907, 3903, 3902, 3901, 3900, 3836, 3835, 3834, 3833, 3832, 3831, 3830, 3829, 3828, 3827, 3826, 3825, 3824, 3823, 3822, 3821, 3820, 3819, 3818, 3817, 3816, 3815, 3814, 3813, 3812, 3811, 3810, 3809, 3808, 3807, 3806, 3805, 3804, 3803, 3802, 3801, 3800, 3799, 3626, 3616, 2456, 2191, 1991, 1535, 1463, 367, 348, 275, 10, 0};
  localparam int OWID [NOUT] = '{1, 1, 1, 8, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 64, 1, 1, 1, 8, 1, 6, 4, 1, 1, 50, 1, 1, 2, 1, 1, 4, 3, 1, 5, 1, 5, 1, 5, 50, 11, 11, 7, 8, 9, 4, 8, 9, 7, 8, 7, 9, 7, 8, 8, 8, 11, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 1, 8, 10, 10, 1, 1, 1, 1, 50, 1, 1, 2, 1, 1, 1, 1, 64, 1, 1, 1, 6, 4, 64, 1, 1, 1, 64, 64, 64, 64, 64, 64, 64, 64, 64, 56, 8, 1, 1, 3, 64, 2, 64, 1, 1, 1, 1, 1, 64, 50, 64, 3, 3, 4, 16, 44, 1, 4, 16, 44, 1, 4, 16, 44, 1, 1, 1, 1, 58, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 4, 6, 1, 1, 1, 1, 1, 10, 5, 1, 1, 1, 1, 1, 22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 12, 64, 1, 1, 2, 2, 1, 4, 1, 64, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 4, 1, 1, 1, 64, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 173, 10, 1160, 265, 200, 456, 72, 1096, 19, 73, 265, 10};
  localparam int NLEGAL = 337;
  localparam logic [11:0] LEGAL [NLEGAL] = '{12'h001, 12'h002, 12'h003, 12'h008, 12'h009, 12'h00A, 12'h00F, 12'h100, 12'h104, 12'h105, 12'h106, 12'h10A, 12'h10C, 12'h10D, 12'h10E, 12'h10F, 12'h140, 12'h141, 12'h142, 12'h143, 12'h144, 12'h14D, 12'h150, 12'h151, 12'h152, 12'h153, 12'h155, 12'h156, 12'h157, 12'h15C, 12'h180, 12'h200, 12'h204, 12'h205, 12'h240, 12'h241, 12'h242, 12'h243, 12'h244, 12'h24D, 12'h250, 12'h251, 12'h252, 12'h253, 12'h255, 12'h256, 12'h257, 12'h25C, 12'h280, 12'h300, 12'h301, 12'h302, 12'h303, 12'h304, 12'h305, 12'h306, 12'h308, 12'h309, 12'h30A, 12'h30C, 12'h30D, 12'h30E, 12'h30F, 12'h320, 12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32A, 12'h32B, 12'h32C, 12'h32D, 12'h32E, 12'h32F, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33A, 12'h33B, 12'h33C, 12'h33D, 12'h33E, 12'h33F, 12'h340, 12'h341, 12'h342, 12'h343, 12'h344, 12'h34A, 12'h34B, 12'h350, 12'h351, 12'h352, 12'h353, 12'h355, 12'h356, 12'h357, 12'h35C, 12'h3A0, 12'h3A2, 12'h3A4, 12'h3A6, 12'h3A8, 12'h3AA, 12'h3AC, 12'h3AE, 12'h3B0, 12'h3B1, 12'h3B2, 12'h3B3, 12'h3B4, 12'h3B5, 12'h3B6, 12'h3B7, 12'h3B8, 12'h3B9, 12'h3BA, 12'h3BB, 12'h3BC, 12'h3BD, 12'h3BE, 12'h3BF, 12'h3C0, 12'h3C1, 12'h3C2, 12'h3C3, 12'h3C4, 12'h3C5, 12'h3C6, 12'h3C7, 12'h3C8, 12'h3C9, 12'h3CA, 12'h3CB, 12'h3CC, 12'h3CD, 12'h3CE, 12'h3CF, 12'h3D0, 12'h3D1, 12'h3D2, 12'h3D3, 12'h3D4, 12'h3D5, 12'h3D6, 12'h3D7, 12'h3D8, 12'h3D9, 12'h3DA, 12'h3DB, 12'h3DC, 12'h3DD, 12'h3DE, 12'h3DF, 12'h3E0, 12'h3E1, 12'h3E2, 12'h3E3, 12'h3E4, 12'h3E5, 12'h3E6, 12'h3E7, 12'h3E8, 12'h3E9, 12'h3EA, 12'h3EB, 12'h3EC, 12'h3ED, 12'h3EE, 12'h3EF, 12'h5A8, 12'h5C0, 12'h5C1, 12'h5C2, 12'h5C3, 12'h5C4, 12'h600, 12'h602, 12'h603, 12'h604, 12'h605, 12'h606, 12'h607, 12'h608, 12'h609, 12'h60A, 12'h60C, 12'h60D, 12'h60E, 12'h60F, 12'h643, 12'h644, 12'h645, 12'h646, 12'h647, 12'h64A, 12'h680, 12'h6A8, 12'h740, 12'h741, 12'h742, 12'h744, 12'h747, 12'h7A0, 12'h7A1, 12'h7A2, 12'h7A4, 12'h7A8, 12'h7B0, 12'h7B1, 12'h7B2, 12'h7B3, 12'h7C0, 12'h7C2, 12'h7C4, 12'h7C6, 12'h7C8, 12'h7C9, 12'h7CA, 12'h7CB, 12'h7CC, 12'h7CD, 12'h7CE, 12'h7CF, 12'h7D0, 12'h7D1, 12'h7D2, 12'h7D3, 12'h7D4, 12'h7D5, 12'h7D6, 12'h7D7, 12'h7D8, 12'h7D9, 12'h7DA, 12'h7DB, 12'h7DC, 12'h7DD, 12'h7DE, 12'h7DF, 12'h7E0, 12'h7E1, 12'h7E2, 12'h7E3, 12'h7E4, 12'h7E5, 12'h7E6, 12'h7E7, 12'hB00, 12'hB02, 12'hB03, 12'hB04, 12'hB05, 12'hB06, 12'hB07, 12'hB08, 12'hB09, 12'hB0A, 12'hB0B, 12'hB0C, 12'hB0D, 12'hB0E, 12'hB0F, 12'hB10, 12'hB11, 12'hB12, 12'hB13, 12'hB14, 12'hB15, 12'hB16, 12'hB17, 12'hB18, 12'hB19, 12'hB1A, 12'hB1B, 12'hB1C, 12'hB1D, 12'hB1E, 12'hB1F, 12'hBC0, 12'hBC1, 12'hBC2, 12'hC00, 12'hC01, 12'hC02, 12'hC03, 12'hC04, 12'hC05, 12'hC06, 12'hC07, 12'hC08, 12'hC09, 12'hC0A, 12'hC0B, 12'hC0C, 12'hC0D, 12'hC0E, 12'hC0F, 12'hC10, 12'hC11, 12'hC12, 12'hC13, 12'hC14, 12'hC15, 12'hC16, 12'hC17, 12'hC18, 12'hC19, 12'hC1A, 12'hC1B, 12'hC1C, 12'hC1D, 12'hC1E, 12'hC1F, 12'hC20, 12'hC21, 12'hC22, 12'hDA0, 12'hDB0, 12'hE12, 12'hEB0, 12'hF11, 12'hF12, 12'hF13, 12'hF14, 12'hF15, 12'hFB0};

  // ---------------- 激励 ----------------
  function automatic bit pct(int p);
    return $urandom_range(9999) < p * 100;
  endfunction
  function automatic logic [63:0] rnd64();
    case ($urandom_range(7))
      0: return 64'h0;
      1: return '1;
      default: return {$urandom, $urandom};
    endcase
  endfunction
  localparam logic [11:0] SYSOP [6] = '{12'h000, 12'h001, 12'h702, 12'h302, 12'h102, 12'h7B2};
  localparam logic [8:0]  CSROP [6] = '{9'h9, 9'hA, 9'hB, 9'hD, 9'hE, 9'hF};
  logic [3:0]  irq_lines;          // mtip msip meip seip：慢变
  logic [63:0] clint_time;
  logic [7:0]  hart_id;

  // 写数据偏置（与 NewCSR UT 相同的几条 WARL 规律）
  function automatic logic [63:0] bias_wdata(input logic [11:0] a, input logic [63:0] d);
    if (a == 12'h7B0 && pct(90)) begin d[17:12] = 6'h0; d[2] = 1'b0; end
    if (a == 12'h744 && pct(90)) d[3] = 1'b1;
    if ((a == 12'h350 || a == 12'h150 || a == 12'h250) && pct(80))
      d = pct(50) ? 64'($urandom_range(8'hFF, 8'h70)) : 64'($urandom_range(8'h3F, 8'h30));
    if ((a == 12'h180 || a == 12'h280 || a == 12'h680) && pct(70))
      d[63:60] = pct(30) ? 4'h0 : (pct(50) ? 4'h8 : 4'h9);
    if (a == 12'h7A1 && pct(70)) d[63:60] = 4'h6;
    if (a == 12'h7A0 && pct(80)) d = 64'($urandom_range(3));
    if ((a == 12'h302 || a == 12'h303 || a == 12'h602 || a == 12'h603) && pct(50)) d = '1;
    return d;
  endfunction

  // 把一条 CSR uop 写进 in_vec
  task automatic set_uop(input logic [8:0] op, input logic [11:0] f12, input logic [4:0] rs1,
                         input logic [4:0] rd, input logic [63:0] src);
    in_vec[OFF_io_in_bits_ctrl_fuOpType +: 9] = op;
    in_vec[OFF_io_in_bits_data_imm +: 12]      = f12;
    in_vec[OFF_io_in_bits_data_imm + 12 +: 5]  = rs1;
    in_vec[OFF_io_in_bits_data_imm + 17 +: 5]  = rd;
    in_vec[OFF_io_in_bits_data_src_0 +: 64]    = src;
  endtask

  task automatic drive_random();
    logic [11:0] a;
    logic [8:0]  op;
    for (int k = 0; k < IW; k += 32) in_vec[k +: 32] = $urandom;
    for (int k = 0; k < 4; k++) if (pct(5)) irq_lines[k] = ~irq_lines[k];
    {in_vec[OFF_io_csrio_externalInterrupt_mtip], in_vec[OFF_io_csrio_externalInterrupt_msip],
     in_vec[OFF_io_csrio_externalInterrupt_meip], in_vec[OFF_io_csrio_externalInterrupt_seip]} = irq_lines;
    in_vec[OFF_io_csrio_externalInterrupt_debug]      = ($urandom_range(1999) == 0);
    in_vec[OFF_io_csrio_externalInterrupt_nmi_nmi_31] = ($urandom_range(1999) == 0);
    in_vec[OFF_io_csrio_externalInterrupt_nmi_nmi_43] = ($urandom_range(1999) == 0);
    in_vec[OFF_io_csrin_hartId +: 8]                  = hart_id;
    clint_time += $urandom_range(3);
    in_vec[OFF_io_csrin_clintTime_bits +: 64]         = clint_time;
    in_vec[OFF_io_csrin_criticalErrorState]           = ($urandom_range(49999) == 0);
    in_vec[OFF_io_csrin_msiInfo_valid]                = pct(5);
    in_vec[OFF_io_in_valid]                           = pct(60);
    if (pct(85)) begin
      op = CSROP[$urandom_range(5)];
      a  = pct(80) ? LEGAL[$urandom_range(NLEGAL-1)] : 12'($urandom);
      // 1/10 访问间接寄存器 mireg/sireg/vsireg，让 IMSIC 异步读路径走得到
      if (pct(10)) a = pct(34) ? 12'h351 : (pct(50) ? 12'h151 : 12'h251);
    end
    else begin
      op = 9'h10;
      a  = pct(75) ? SYSOP[$urandom_range(5)] : 12'($urandom);
    end
    set_uop(op, a, pct(75) ? 5'($urandom_range(31, 1)) : 5'h0, pct(75) ? 5'($urandom_range(31, 1)) : 5'h0,
            bias_wdata(a, rnd64()));
    in_vec[OFF_io_flush_valid]                    = pct(3);
    in_vec[OFF_io_csrio_exception_valid]          = pct(3);
    for (int k = 0; k < 24; k++) in_vec[OFF_io_csrio_exception_bits_exceptionVec_0 - k] = 1'b0;
    if (pct(80)) in_vec[OFF_io_csrio_exception_bits_exceptionVec_0 - $urandom_range(23)] = 1'b1;
    in_vec[OFF_io_csrio_exception_bits_isInterrupt]  = pct(30);
    in_vec[OFF_io_csrio_exception_bits_singleStep]   = pct(1);
    in_vec[OFF_io_csrio_exception_bits_isPcBkpt]     = pct(5);
    in_vec[OFF_io_csrio_exception_bits_satpFlushFirstFetchFault] = pct(5);
    in_vec[OFF_io_csrio_exception_bits_isFetchMalAddr] = pct(5);
    in_vec[OFF_io_csrio_exception_bits_trigger +: 4] = pct(85) ? 4'hF : 4'($urandom);
    in_vec[OFF_io_csrio_fpu_fflags_valid]         = pct(20);
    in_vec[OFF_io_csrio_vpu_set_vxsat_valid]      = pct(20);
    in_vec[OFF_io_csrio_vpu_set_vtype_valid]      = pct(20);
    in_vec[OFF_io_csrio_vpu_set_vstart_valid]     = pct(20);
    in_vec[OFF_io_csrio_fpu_dirty_fs]             = pct(10);
    in_vec[OFF_io_csrio_vpu_dirty_vs]             = pct(10);
    in_vec[OFF_io_csrin_fromVecExcpMod_busy]      = pct(20);
    in_vec[OFF_io_csrin_trapInstInfo_valid]       = pct(20);
    in_vec[OFF_io_out_ready]                      = pct(70);
    // NMIE=0 时的救援（同 NewCSR UT）
    if (!u_g.csrMod._mnstatus_regOut_NMIE && u_g.csrMod.PRVM != 2'h3 && !u_g.csrMod.debugMode && pct(2))
      in_vec[OFF_io_csrio_externalInterrupt_debug] = 1'b1;
    if (!u_g.csrMod._mnstatus_regOut_NMIE && pct(10)) begin
      in_vec[OFF_io_in_valid] = 1'b1;
      set_uop(9'h9, 12'h744, 5'h1, 5'h1, 64'h8);
    end
  endtask

  task automatic quiet_req();
    in_vec[OFF_io_flush_valid] = 1'b0;
    in_vec[OFF_io_csrio_exception_valid] = 1'b0;
    in_vec[OFF_io_out_ready] = 1'b1;
  endtask

  task automatic warmup();
    for (int k = 0; k < NLEGAL; k++) begin
      for (int r = 0; r < 2; r++) begin
        drive_random();
        quiet_req();
        in_vec[OFF_io_in_valid] = 1'b1;
        set_uop(9'h9, LEGAL[k], 5'h1, 5'h1,
                LEGAL[k] == 12'h7B0 ? 64'h0 : (LEGAL[k] == 12'h744 ? 64'h8 : bias_wdata(LEGAL[k], rnd64())));
        @(posedge clock); #1;
      end
    end
    // 4 组触发器的 tdata2 不复位：逐个 tselect 写一遍 tdata2（tdata1 写 0 使其可写）
    for (int t = 0; t < 4; t++) begin
      for (int w = 0; w < 3; w++) begin
        for (int r = 0; r < 2; r++) begin
          drive_random();
          quiet_req();
          in_vec[OFF_io_in_valid] = 1'b1;
          set_uop(9'h9, w == 0 ? 12'h7A0 : (w == 1 ? 12'h7A1 : 12'h7A2), 5'h1, 5'h1,
                  w == 0 ? 64'(t) : (w == 1 ? 64'h0 : {$urandom, $urandom}));
          @(posedge clock); #1;
        end
      end
    end
    // 进 debug（调试中断要几拍才锁进 InterruptFilter，trap 放在第 12 拍）
    for (int r = 0; r < 14; r++) begin
      drive_random();
      quiet_req();
      in_vec[OFF_io_in_valid] = 1'b0;
      in_vec[OFF_io_csrio_externalInterrupt_debug] = 1'b1;
      in_vec[OFF_io_csrio_exception_valid] = (r == 12);
      in_vec[OFF_io_csrio_exception_bits_isInterrupt] = 1'b1;
      @(posedge clock); #1;
    end
    // dcsr 不复位：上电 STEP=1 且 STEPIE=0 时调试中断被屏蔽，改走单步异常进 debug
    for (int r = 0; r < 4 && !u_g.csrMod.debugMode; r++) begin
      drive_random();
      quiet_req();
      in_vec[OFF_io_in_valid] = 1'b0;
      in_vec[OFF_io_csrio_externalInterrupt_debug] = 1'b0;
      in_vec[OFF_io_csrio_exception_valid] = (r == 0);
      in_vec[OFF_io_csrio_exception_bits_isInterrupt] = 1'b0;
      in_vec[OFF_io_csrio_exception_bits_singleStep] = 1'b1;
      @(posedge clock); #1;
    end
    if (!u_g.csrMod.debugMode)
      $display("WARMUP: debug not entered (NMIE=%b dbg=%b crit=%b PRVM=%0d)", u_g.csrMod._mnstatus_regOut_NMIE,
               u_g.csrMod.debug, u_g.csrMod.criticalErrorState, u_g.csrMod.PRVM);
    for (int k = 0; k < 3; k++) begin
      for (int r = 0; r < 2; r++) begin
        drive_random();
        quiet_req();
        in_vec[OFF_io_csrio_externalInterrupt_debug] = 1'b0;
        in_vec[OFF_io_in_valid] = 1'b1;
        set_uop(9'h9, 12'h7B1 + k, 5'h1, 5'h1, rnd64());
        @(posedge clock); #1;
      end
    end
    for (int r = 0; r < 4; r++) begin
      drive_random();
      quiet_req();
      in_vec[OFF_io_csrio_externalInterrupt_debug] = 1'b0;
      in_vec[OFF_io_in_valid] = (r == 0);
      set_uop(9'h10, 12'h7B2, 5'h0, 5'h0, 64'h0);           // dret
      @(posedge clock); #1;
    end
    for (int r = 0; r < 4; r++) begin
      drive_random();
      quiet_req();
      in_vec[OFF_io_in_valid] = 1'b0;
      in_vec[OFF_io_csrio_exception_valid] = (r == 0);
      @(posedge clock); #1;
    end
    for (int r = 0; r < 4; r++) begin
      drive_random();
      quiet_req();
      in_vec[OFF_io_in_valid] = (r == 0);
      set_uop(9'h10, 12'h302, 5'h0, 5'h0, 64'h0);           // mret
      @(posedge clock); #1;
    end
  endtask

  task automatic do_reset();
    reset = 1;
    drive_random();
    repeat (5) @(posedge clock);
    #1 reset = 0;
    warmup();
  endtask

  // ---------------- 比对 ----------------
  bit [NOUT-1:0] port_bad;
  logic [OW-1:0] prev_g, tog;
  always @(negedge clock) if (cmp_en && !reset) begin
    checks++;
    if (g_out !== i_out) begin
      errors++;
      for (int p = 0; p < NOUT; p++) begin
        logic [OW-1:0] d;
        bit bad;
        d = (g_out ^ i_out) >> OLSB[p];
        bad = 0;
        for (int b = 0; b < OWID[p]; b++) bad |= (d[b] !== 1'b0);
        if (bad && !port_bad[p]) begin
          int c0;
          logic [OW-1:0] gs, is;
          port_bad[p] = 1;
          gs = g_out >> OLSB[p];
          is = i_out >> OLSB[p];
          c0 = 0;
          while (c0 + 64 < OWID[p] && gs[c0 +: 64] === is[c0 +: 64]) c0 += 64;
          $display("[%0t] MISMATCH %s bits[%0d +: 64] g=%h i=%h", $time, ONAME[p], c0,
                   gs[c0 +: 64], is[c0 +: 64]);
        end
      end
    end
    tog |= prev_g ^ g_out;
    prev_g = g_out;
  end

  // ---------------- 覆盖（golden 内部信号）----------------
  longint f_trap_m = 0, f_trap_hs = 0, f_trap_vs = 0, f_trap_mn = 0, f_trap_d = 0;
  longint f_mret = 0, f_sret = 0, f_wait = 0, f_wen = 0, f_ex_ii = 0, f_flush = 0;
  longint f_xret_redirect = 0, f_ecall = 0, f_msi = 0, f_redirect_flush = 0;
  always @(posedge clock) if (cmp_en && !reset) begin
    f_trap_m  += u_g.csrMod.trapEntryMEvent.valid;
    f_trap_hs += u_g.csrMod.trapEntryHSEvent.valid;
    f_trap_vs += u_g.csrMod.trapEntryVSEvent.valid;
    f_trap_mn += u_g.csrMod.trapEntryMNEvent.valid;
    f_trap_d  += u_g.csrMod.trapEntryDEvent.valid;
    f_mret    += u_g.csrMod._permitMod_io_out_hasLegalMret;
    f_sret    += u_g.csrMod._permitMod_io_out_hasLegalSret;
    f_wait    += (u_g.csrMod.state == 2'h1);
    f_wen     += u_g.csrMod.wenLegalReg_last_REG;
    f_ex_ii   += u_g.io_out_valid & u_g.io_out_bits_ctrl_exceptionVec_2;
    f_flush   += u_g.csrMod.io_out_bits_flushPipe;
    f_xret_redirect += u_g.io_out_bits_res_redirect_valid;
    f_ecall   += u_g.io_out_valid & (u_g.io_out_bits_ctrl_exceptionVec_8 | u_g.io_out_bits_ctrl_exceptionVec_9
                                     | u_g.io_out_bits_ctrl_exceptionVec_10 | u_g.io_out_bits_ctrl_exceptionVec_11);
    f_msi     += io_csrin_msiInfo_valid;
    f_redirect_flush += u_g.csrMod.io_in_bits_redirectFlush;
  end

  // ---------------- 主流程 ----------------
  initial begin
    longint minf;
    int nport_tog;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    hart_id = $urandom;
    irq_lines = '0;
    clint_time = 0;
    cmp_en = 0;
    port_bad = '0;
    do_reset();
    cmp_en = 1;
    prev_g = g_out; tog = '0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      if (c != 0 && c % (NCYCLES / 10) == 0) begin
        cmp_en = 0;
        do_reset();
        cmp_en = 1;
      end
      drive_random();
      @(posedge clock); #1;
    end
    nport_tog = 0;
    for (int p = 0; p < NOUT; p++) begin
      bit any;
      any = 0;
      for (int b = 0; b < OWID[p]; b++) any |= tog[OLSB[p] + b];
      nport_tog += any;
      if (!any) $display("untoggled output: %s", ONAME[p]);
    end
    minf = NCYCLES / 2000;
    $display("CSR UT: checks=%0d errors=%0d bad_ports=%0d toggled_bits=%0d/%0d toggled_ports=%0d/%0d",
             checks, errors, $countones(port_bad), $countones(tog), OW, nport_tog, NOUT);
    $display("fires: trapM=%0d trapHS=%0d trapVS=%0d trapMN=%0d trapD=%0d mret=%0d sret=%0d wait=%0d wen=%0d EX_II=%0d flush=%0d xret_redirect=%0d ecall=%0d msi=%0d redirectFlush=%0d",
             f_trap_m, f_trap_hs, f_trap_vs, f_trap_mn, f_trap_d, f_mret, f_sret, f_wait, f_wen,
             f_ex_ii, f_flush, f_xret_redirect, f_ecall, f_msi, f_redirect_flush);
    if (checks == 0) begin $display("TEST FAILED (no checks)"); $fatal(1); end
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (f_trap_m < minf || f_trap_hs < minf / 4 || f_trap_mn < 1 || f_mret < minf || f_sret < minf / 4
        || f_wait < minf / 4 || f_wen < minf || f_ex_ii < minf || f_flush < minf / 4
        || f_xret_redirect < minf || f_ecall < minf || f_msi < minf || f_redirect_flush < minf) begin
      $display("TEST FAILED (coverage)"); $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule

