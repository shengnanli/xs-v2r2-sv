// NewCSR 双例化逐拍比对 tb（端口表由 golden 头机械抄出；激励与覆盖闸手写）。
// golden NewCSR（+ golden 子模块闭包） vs 重写件 NewCSR_xs（+ 重写子模块 *_xs，derive_ut_impl.py 派生）。
//
// 时间线：
//   1. 复位 5 拍；
//   2. 预热（不比对）：M 态下把 337 个合法 CSR 地址各写一次随机值（每个地址保持 2 拍，配合
//      "写使能晚一拍、地址取当拍"的时序），再打一个 trap、一个 mret —— 让两侧所有不复位的
//      寄存器（输出保持、difftest 打拍、子模块里的不复位字段）都被写成确定值。
//      +vcs+initreg+random 给两个实例各摇各的初值，不预热会把"初态不同"误报成失配。
//   3. 随机 NCYCLES 拍，每拍下降沿比对全部 174 个输出端口（4849 位，四态 !==）。
//      每 NCYCLES/10 拍插一次复位（复位后重新预热）—— critical error 等粘性状态靠复位清。
// 激励偏置：
//   * 访问请求：valid 60%，wen 40%，ren 50%；地址 4/5 取合法 CSR 地址表、1/5 全随机；
//     写数据 1/8 全 0、1/8 全 1、其余随机；xRET 各 2%；redirectFlush 3%；out.ready 70%。
//   * trap：3%，trapVec 4/5 单热，isInterrupt 30%，singleStep/isFetchBkpt/satpFlush 各 5%。
//   * 中断线：平台中断线每拍 5% 概率翻转；NMI 各 1%；AIA 回数 15%（其中 illegal 20%）。
//   * criticalErrorState 输入每拍 1/50000（一旦置位粘住，所以要很稀）。
// 覆盖闸（golden 内部信号计数，下限 = NCYCLES/2000，事件稀的另设）：trap 进入 M/HS/VS/MN、
//   mret/sret 合法、进 debug、IMSIC 等待态、合法写、EX_II/EX_VI、flushPipe、targetPcUpdate；
//   另报告访问过的 (PRVM,V) 组合与被合法写过的 CSR 地址数。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  bit cmp_en;
  longint checks = 0, errors = 0;

  localparam int IW = 1421, OW = 4849, NOUT = 174;
  logic [IW-1:0] in_vec;
  wire  [OW-1:0] g_out, i_out;
  localparam int OFF_platformIRP_MEIP = 1420;
  wire [0:0] platformIRP_MEIP = in_vec[1420 +: 1];
  localparam int OFF_platformIRP_MTIP = 1419;
  wire [0:0] platformIRP_MTIP = in_vec[1419 +: 1];
  localparam int OFF_platformIRP_MSIP = 1418;
  wire [0:0] platformIRP_MSIP = in_vec[1418 +: 1];
  localparam int OFF_platformIRP_SEIP = 1417;
  wire [0:0] platformIRP_SEIP = in_vec[1417 +: 1];
  localparam int OFF_platformIRP_debugIP = 1416;
  wire [0:0] platformIRP_debugIP = in_vec[1416 +: 1];
  localparam int OFF_nonMaskableIRP_NMI_43 = 1415;
  wire [0:0] nonMaskableIRP_NMI_43 = in_vec[1415 +: 1];
  localparam int OFF_nonMaskableIRP_NMI_31 = 1414;
  wire [0:0] nonMaskableIRP_NMI_31 = in_vec[1414 +: 1];
  localparam int OFF_io_fromTop_hartId = 1408;
  wire [5:0] io_fromTop_hartId = in_vec[1408 +: 6];
  localparam int OFF_io_fromTop_clintTime_valid = 1407;
  wire [0:0] io_fromTop_clintTime_valid = in_vec[1407 +: 1];
  localparam int OFF_io_fromTop_clintTime_bits = 1343;
  wire [63:0] io_fromTop_clintTime_bits = in_vec[1343 +: 64];
  localparam int OFF_io_fromTop_l2FlushDone = 1342;
  wire [0:0] io_fromTop_l2FlushDone = in_vec[1342 +: 1];
  localparam int OFF_io_fromTop_criticalErrorState = 1341;
  wire [0:0] io_fromTop_criticalErrorState = in_vec[1341 +: 1];
  localparam int OFF_io_in_valid = 1340;
  wire [0:0] io_in_valid = in_vec[1340 +: 1];
  localparam int OFF_io_in_bits_wen = 1339;
  wire [0:0] io_in_bits_wen = in_vec[1339 +: 1];
  localparam int OFF_io_in_bits_ren = 1338;
  wire [0:0] io_in_bits_ren = in_vec[1338 +: 1];
  localparam int OFF_io_in_bits_op = 1336;
  wire [1:0] io_in_bits_op = in_vec[1336 +: 2];
  localparam int OFF_io_in_bits_addr = 1324;
  wire [11:0] io_in_bits_addr = in_vec[1324 +: 12];
  localparam int OFF_io_in_bits_src = 1260;
  wire [63:0] io_in_bits_src = in_vec[1260 +: 64];
  localparam int OFF_io_in_bits_wdata = 1196;
  wire [63:0] io_in_bits_wdata = in_vec[1196 +: 64];
  localparam int OFF_io_in_bits_mnret = 1195;
  wire [0:0] io_in_bits_mnret = in_vec[1195 +: 1];
  localparam int OFF_io_in_bits_mret = 1194;
  wire [0:0] io_in_bits_mret = in_vec[1194 +: 1];
  localparam int OFF_io_in_bits_sret = 1193;
  wire [0:0] io_in_bits_sret = in_vec[1193 +: 1];
  localparam int OFF_io_in_bits_dret = 1192;
  wire [0:0] io_in_bits_dret = in_vec[1192 +: 1];
  localparam int OFF_io_in_bits_redirectFlush = 1191;
  wire [0:0] io_in_bits_redirectFlush = in_vec[1191 +: 1];
  localparam int OFF_io_trapInst_valid = 1190;
  wire [0:0] io_trapInst_valid = in_vec[1190 +: 1];
  localparam int OFF_io_trapInst_bits = 1158;
  wire [31:0] io_trapInst_bits = in_vec[1158 +: 32];
  localparam int OFF_io_fromMem_excpVA = 1094;
  wire [63:0] io_fromMem_excpVA = in_vec[1094 +: 64];
  localparam int OFF_io_fromMem_excpGPA = 1030;
  wire [63:0] io_fromMem_excpGPA = in_vec[1030 +: 64];
  localparam int OFF_io_fromMem_excpIsForVSnonLeafPTE = 1029;
  wire [0:0] io_fromMem_excpIsForVSnonLeafPTE = in_vec[1029 +: 1];
  localparam int OFF_io_fromRob_trap_valid = 1028;
  wire [0:0] io_fromRob_trap_valid = in_vec[1028 +: 1];
  localparam int OFF_io_fromRob_trap_bits_pc = 978;
  wire [49:0] io_fromRob_trap_bits_pc = in_vec[978 +: 50];
  localparam int OFF_io_fromRob_trap_bits_pcGPA = 922;
  wire [55:0] io_fromRob_trap_bits_pcGPA = in_vec[922 +: 56];
  localparam int OFF_io_fromRob_trap_bits_instr = 890;
  wire [31:0] io_fromRob_trap_bits_instr = in_vec[890 +: 32];
  localparam int OFF_io_fromRob_trap_bits_trapVec = 826;
  wire [63:0] io_fromRob_trap_bits_trapVec = in_vec[826 +: 64];
  localparam int OFF_io_fromRob_trap_bits_isFetchBkpt = 825;
  wire [0:0] io_fromRob_trap_bits_isFetchBkpt = in_vec[825 +: 1];
  localparam int OFF_io_fromRob_trap_bits_singleStep = 824;
  wire [0:0] io_fromRob_trap_bits_singleStep = in_vec[824 +: 1];
  localparam int OFF_io_fromRob_trap_bits_trigger = 820;
  wire [3:0] io_fromRob_trap_bits_trigger = in_vec[820 +: 4];
  localparam int OFF_io_fromRob_trap_bits_crossPageIPFFix = 819;
  wire [0:0] io_fromRob_trap_bits_crossPageIPFFix = in_vec[819 +: 1];
  localparam int OFF_io_fromRob_trap_bits_isInterrupt = 818;
  wire [0:0] io_fromRob_trap_bits_isInterrupt = in_vec[818 +: 1];
  localparam int OFF_io_fromRob_trap_bits_isHls = 817;
  wire [0:0] io_fromRob_trap_bits_isHls = in_vec[817 +: 1];
  localparam int OFF_io_fromRob_trap_bits_isFetchMalAddr = 816;
  wire [0:0] io_fromRob_trap_bits_isFetchMalAddr = in_vec[816 +: 1];
  localparam int OFF_io_fromRob_trap_bits_isForVSnonLeafPTE = 815;
  wire [0:0] io_fromRob_trap_bits_isForVSnonLeafPTE = in_vec[815 +: 1];
  localparam int OFF_io_fromRob_trap_bits_satpFlushFirstFetchFault = 814;
  wire [0:0] io_fromRob_trap_bits_satpFlushFirstFetchFault = in_vec[814 +: 1];
  localparam int OFF_io_fromRob_commit_instNum_bits = 807;
  wire [6:0] io_fromRob_commit_instNum_bits = in_vec[807 +: 7];
  localparam int OFF_io_fromRob_commit_fflags_valid = 806;
  wire [0:0] io_fromRob_commit_fflags_valid = in_vec[806 +: 1];
  localparam int OFF_io_fromRob_commit_fflags_bits = 801;
  wire [4:0] io_fromRob_commit_fflags_bits = in_vec[801 +: 5];
  localparam int OFF_io_fromRob_commit_fsDirty = 800;
  wire [0:0] io_fromRob_commit_fsDirty = in_vec[800 +: 1];
  localparam int OFF_io_fromRob_commit_vxsat_valid = 799;
  wire [0:0] io_fromRob_commit_vxsat_valid = in_vec[799 +: 1];
  localparam int OFF_io_fromRob_commit_vxsat_bits = 798;
  wire [0:0] io_fromRob_commit_vxsat_bits = in_vec[798 +: 1];
  localparam int OFF_io_fromRob_commit_vsDirty = 797;
  wire [0:0] io_fromRob_commit_vsDirty = in_vec[797 +: 1];
  localparam int OFF_io_fromRob_commit_vtype_valid = 796;
  wire [0:0] io_fromRob_commit_vtype_valid = in_vec[796 +: 1];
  localparam int OFF_io_fromRob_commit_vtype_bits_VILL = 795;
  wire [0:0] io_fromRob_commit_vtype_bits_VILL = in_vec[795 +: 1];
  localparam int OFF_io_fromRob_commit_vtype_bits_VMA = 794;
  wire [0:0] io_fromRob_commit_vtype_bits_VMA = in_vec[794 +: 1];
  localparam int OFF_io_fromRob_commit_vtype_bits_VTA = 793;
  wire [0:0] io_fromRob_commit_vtype_bits_VTA = in_vec[793 +: 1];
  localparam int OFF_io_fromRob_commit_vtype_bits_VSEW = 790;
  wire [2:0] io_fromRob_commit_vtype_bits_VSEW = in_vec[790 +: 3];
  localparam int OFF_io_fromRob_commit_vtype_bits_VLMUL = 787;
  wire [2:0] io_fromRob_commit_vtype_bits_VLMUL = in_vec[787 +: 3];
  localparam int OFF_io_fromRob_commit_vl = 779;
  wire [7:0] io_fromRob_commit_vl = in_vec[779 +: 8];
  localparam int OFF_io_fromRob_commit_vstart_valid = 778;
  wire [0:0] io_fromRob_commit_vstart_valid = in_vec[778 +: 1];
  localparam int OFF_io_fromRob_commit_vstart_bits = 771;
  wire [6:0] io_fromRob_commit_vstart_bits = in_vec[771 +: 7];
  localparam int OFF_io_fromVecExcpMod_busy = 770;
  wire [0:0] io_fromVecExcpMod_busy = in_vec[770 +: 1];
  localparam int OFF_io_perf_perfEventsFrontend_0_value = 764;
  wire [5:0] io_perf_perfEventsFrontend_0_value = in_vec[764 +: 6];
  localparam int OFF_io_perf_perfEventsFrontend_1_value = 758;
  wire [5:0] io_perf_perfEventsFrontend_1_value = in_vec[758 +: 6];
  localparam int OFF_io_perf_perfEventsFrontend_2_value = 752;
  wire [5:0] io_perf_perfEventsFrontend_2_value = in_vec[752 +: 6];
  localparam int OFF_io_perf_perfEventsFrontend_3_value = 746;
  wire [5:0] io_perf_perfEventsFrontend_3_value = in_vec[746 +: 6];
  localparam int OFF_io_perf_perfEventsFrontend_4_value = 740;
  wire [5:0] io_perf_perfEventsFrontend_4_value = in_vec[740 +: 6];
  localparam int OFF_io_perf_perfEventsFrontend_5_value = 734;
  wire [5:0] io_perf_perfEventsFrontend_5_value = in_vec[734 +: 6];
  localparam int OFF_io_perf_perfEventsFrontend_6_value = 728;
  wire [5:0] io_perf_perfEventsFrontend_6_value = in_vec[728 +: 6];
  localparam int OFF_io_perf_perfEventsFrontend_7_value = 722;
  wire [5:0] io_perf_perfEventsFrontend_7_value = in_vec[722 +: 6];
  localparam int OFF_io_perf_perfEventsBackend_0_value = 716;
  wire [5:0] io_perf_perfEventsBackend_0_value = in_vec[716 +: 6];
  localparam int OFF_io_perf_perfEventsBackend_1_value = 710;
  wire [5:0] io_perf_perfEventsBackend_1_value = in_vec[710 +: 6];
  localparam int OFF_io_perf_perfEventsBackend_2_value = 704;
  wire [5:0] io_perf_perfEventsBackend_2_value = in_vec[704 +: 6];
  localparam int OFF_io_perf_perfEventsBackend_3_value = 698;
  wire [5:0] io_perf_perfEventsBackend_3_value = in_vec[698 +: 6];
  localparam int OFF_io_perf_perfEventsBackend_4_value = 692;
  wire [5:0] io_perf_perfEventsBackend_4_value = in_vec[692 +: 6];
  localparam int OFF_io_perf_perfEventsBackend_5_value = 686;
  wire [5:0] io_perf_perfEventsBackend_5_value = in_vec[686 +: 6];
  localparam int OFF_io_perf_perfEventsBackend_6_value = 680;
  wire [5:0] io_perf_perfEventsBackend_6_value = in_vec[680 +: 6];
  localparam int OFF_io_perf_perfEventsBackend_7_value = 674;
  wire [5:0] io_perf_perfEventsBackend_7_value = in_vec[674 +: 6];
  localparam int OFF_io_perf_perfEventsLsu_0_value = 668;
  wire [5:0] io_perf_perfEventsLsu_0_value = in_vec[668 +: 6];
  localparam int OFF_io_perf_perfEventsLsu_1_value = 662;
  wire [5:0] io_perf_perfEventsLsu_1_value = in_vec[662 +: 6];
  localparam int OFF_io_perf_perfEventsLsu_2_value = 656;
  wire [5:0] io_perf_perfEventsLsu_2_value = in_vec[656 +: 6];
  localparam int OFF_io_perf_perfEventsLsu_3_value = 650;
  wire [5:0] io_perf_perfEventsLsu_3_value = in_vec[650 +: 6];
  localparam int OFF_io_perf_perfEventsLsu_4_value = 644;
  wire [5:0] io_perf_perfEventsLsu_4_value = in_vec[644 +: 6];
  localparam int OFF_io_perf_perfEventsLsu_5_value = 638;
  wire [5:0] io_perf_perfEventsLsu_5_value = in_vec[638 +: 6];
  localparam int OFF_io_perf_perfEventsLsu_6_value = 632;
  wire [5:0] io_perf_perfEventsLsu_6_value = in_vec[632 +: 6];
  localparam int OFF_io_perf_perfEventsLsu_7_value = 626;
  wire [5:0] io_perf_perfEventsLsu_7_value = in_vec[626 +: 6];
  localparam int OFF_io_perf_perfEventsHc_0_value = 620;
  wire [5:0] io_perf_perfEventsHc_0_value = in_vec[620 +: 6];
  localparam int OFF_io_perf_perfEventsHc_1_value = 614;
  wire [5:0] io_perf_perfEventsHc_1_value = in_vec[614 +: 6];
  localparam int OFF_io_perf_perfEventsHc_2_value = 608;
  wire [5:0] io_perf_perfEventsHc_2_value = in_vec[608 +: 6];
  localparam int OFF_io_perf_perfEventsHc_3_value = 602;
  wire [5:0] io_perf_perfEventsHc_3_value = in_vec[602 +: 6];
  localparam int OFF_io_perf_perfEventsHc_4_value = 596;
  wire [5:0] io_perf_perfEventsHc_4_value = in_vec[596 +: 6];
  localparam int OFF_io_perf_perfEventsHc_5_value = 590;
  wire [5:0] io_perf_perfEventsHc_5_value = in_vec[590 +: 6];
  localparam int OFF_io_perf_perfEventsHc_6_value = 584;
  wire [5:0] io_perf_perfEventsHc_6_value = in_vec[584 +: 6];
  localparam int OFF_io_perf_perfEventsHc_7_value = 578;
  wire [5:0] io_perf_perfEventsHc_7_value = in_vec[578 +: 6];
  localparam int OFF_io_perf_perfEventsHc_8_value = 572;
  wire [5:0] io_perf_perfEventsHc_8_value = in_vec[572 +: 6];
  localparam int OFF_io_perf_perfEventsHc_9_value = 566;
  wire [5:0] io_perf_perfEventsHc_9_value = in_vec[566 +: 6];
  localparam int OFF_io_perf_perfEventsHc_10_value = 560;
  wire [5:0] io_perf_perfEventsHc_10_value = in_vec[560 +: 6];
  localparam int OFF_io_perf_perfEventsHc_11_value = 554;
  wire [5:0] io_perf_perfEventsHc_11_value = in_vec[554 +: 6];
  localparam int OFF_io_perf_perfEventsHc_12_value = 548;
  wire [5:0] io_perf_perfEventsHc_12_value = in_vec[548 +: 6];
  localparam int OFF_io_perf_perfEventsHc_13_value = 542;
  wire [5:0] io_perf_perfEventsHc_13_value = in_vec[542 +: 6];
  localparam int OFF_io_perf_perfEventsHc_14_value = 536;
  wire [5:0] io_perf_perfEventsHc_14_value = in_vec[536 +: 6];
  localparam int OFF_io_perf_perfEventsHc_15_value = 530;
  wire [5:0] io_perf_perfEventsHc_15_value = in_vec[530 +: 6];
  localparam int OFF_io_perf_perfEventsHc_16_value = 524;
  wire [5:0] io_perf_perfEventsHc_16_value = in_vec[524 +: 6];
  localparam int OFF_io_perf_perfEventsHc_17_value = 518;
  wire [5:0] io_perf_perfEventsHc_17_value = in_vec[518 +: 6];
  localparam int OFF_io_perf_perfEventsHc_18_value = 512;
  wire [5:0] io_perf_perfEventsHc_18_value = in_vec[512 +: 6];
  localparam int OFF_io_perf_perfEventsHc_19_value = 506;
  wire [5:0] io_perf_perfEventsHc_19_value = in_vec[506 +: 6];
  localparam int OFF_io_perf_perfEventsHc_20_value = 500;
  wire [5:0] io_perf_perfEventsHc_20_value = in_vec[500 +: 6];
  localparam int OFF_io_perf_perfEventsHc_21_value = 494;
  wire [5:0] io_perf_perfEventsHc_21_value = in_vec[494 +: 6];
  localparam int OFF_io_perf_perfEventsHc_22_value = 488;
  wire [5:0] io_perf_perfEventsHc_22_value = in_vec[488 +: 6];
  localparam int OFF_io_perf_perfEventsHc_23_value = 482;
  wire [5:0] io_perf_perfEventsHc_23_value = in_vec[482 +: 6];
  localparam int OFF_io_perf_perfEventsHc_24_value = 476;
  wire [5:0] io_perf_perfEventsHc_24_value = in_vec[476 +: 6];
  localparam int OFF_io_perf_perfEventsHc_25_value = 470;
  wire [5:0] io_perf_perfEventsHc_25_value = in_vec[470 +: 6];
  localparam int OFF_io_perf_perfEventsHc_26_value = 464;
  wire [5:0] io_perf_perfEventsHc_26_value = in_vec[464 +: 6];
  localparam int OFF_io_perf_perfEventsHc_27_value = 458;
  wire [5:0] io_perf_perfEventsHc_27_value = in_vec[458 +: 6];
  localparam int OFF_io_perf_perfEventsHc_28_value = 452;
  wire [5:0] io_perf_perfEventsHc_28_value = in_vec[452 +: 6];
  localparam int OFF_io_perf_perfEventsHc_29_value = 446;
  wire [5:0] io_perf_perfEventsHc_29_value = in_vec[446 +: 6];
  localparam int OFF_io_perf_perfEventsHc_30_value = 440;
  wire [5:0] io_perf_perfEventsHc_30_value = in_vec[440 +: 6];
  localparam int OFF_io_perf_perfEventsHc_31_value = 434;
  wire [5:0] io_perf_perfEventsHc_31_value = in_vec[434 +: 6];
  localparam int OFF_io_perf_perfEventsHc_32_value = 428;
  wire [5:0] io_perf_perfEventsHc_32_value = in_vec[428 +: 6];
  localparam int OFF_io_perf_perfEventsHc_33_value = 422;
  wire [5:0] io_perf_perfEventsHc_33_value = in_vec[422 +: 6];
  localparam int OFF_io_perf_perfEventsHc_34_value = 416;
  wire [5:0] io_perf_perfEventsHc_34_value = in_vec[416 +: 6];
  localparam int OFF_io_perf_perfEventsHc_35_value = 410;
  wire [5:0] io_perf_perfEventsHc_35_value = in_vec[410 +: 6];
  localparam int OFF_io_perf_perfEventsHc_36_value = 404;
  wire [5:0] io_perf_perfEventsHc_36_value = in_vec[404 +: 6];
  localparam int OFF_io_perf_perfEventsHc_37_value = 398;
  wire [5:0] io_perf_perfEventsHc_37_value = in_vec[398 +: 6];
  localparam int OFF_io_perf_perfEventsHc_38_value = 392;
  wire [5:0] io_perf_perfEventsHc_38_value = in_vec[392 +: 6];
  localparam int OFF_io_perf_perfEventsHc_39_value = 386;
  wire [5:0] io_perf_perfEventsHc_39_value = in_vec[386 +: 6];
  localparam int OFF_io_perf_perfEventsHc_40_value = 380;
  wire [5:0] io_perf_perfEventsHc_40_value = in_vec[380 +: 6];
  localparam int OFF_io_perf_perfEventsHc_41_value = 374;
  wire [5:0] io_perf_perfEventsHc_41_value = in_vec[374 +: 6];
  localparam int OFF_io_perf_perfEventsHc_42_value = 368;
  wire [5:0] io_perf_perfEventsHc_42_value = in_vec[368 +: 6];
  localparam int OFF_io_perf_perfEventsHc_43_value = 362;
  wire [5:0] io_perf_perfEventsHc_43_value = in_vec[362 +: 6];
  localparam int OFF_io_perf_perfEventsHc_44_value = 356;
  wire [5:0] io_perf_perfEventsHc_44_value = in_vec[356 +: 6];
  localparam int OFF_io_perf_perfEventsHc_45_value = 350;
  wire [5:0] io_perf_perfEventsHc_45_value = in_vec[350 +: 6];
  localparam int OFF_io_perf_perfEventsHc_46_value = 344;
  wire [5:0] io_perf_perfEventsHc_46_value = in_vec[344 +: 6];
  localparam int OFF_io_perf_perfEventsHc_47_value = 338;
  wire [5:0] io_perf_perfEventsHc_47_value = in_vec[338 +: 6];
  localparam int OFF_io_perf_perfEventsHc_48_value = 332;
  wire [5:0] io_perf_perfEventsHc_48_value = in_vec[332 +: 6];
  localparam int OFF_io_perf_perfEventsHc_49_value = 326;
  wire [5:0] io_perf_perfEventsHc_49_value = in_vec[326 +: 6];
  localparam int OFF_io_perf_perfEventsHc_50_value = 320;
  wire [5:0] io_perf_perfEventsHc_50_value = in_vec[320 +: 6];
  localparam int OFF_io_perf_perfEventsHc_51_value = 314;
  wire [5:0] io_perf_perfEventsHc_51_value = in_vec[314 +: 6];
  localparam int OFF_io_perf_perfEventsHc_52_value = 308;
  wire [5:0] io_perf_perfEventsHc_52_value = in_vec[308 +: 6];
  localparam int OFF_io_perf_perfEventsHc_53_value = 302;
  wire [5:0] io_perf_perfEventsHc_53_value = in_vec[302 +: 6];
  localparam int OFF_io_perf_perfEventsHc_54_value = 296;
  wire [5:0] io_perf_perfEventsHc_54_value = in_vec[296 +: 6];
  localparam int OFF_io_perf_perfEventsHc_55_value = 290;
  wire [5:0] io_perf_perfEventsHc_55_value = in_vec[290 +: 6];
  localparam int OFF_io_perf_perfEventsHc_56_value = 284;
  wire [5:0] io_perf_perfEventsHc_56_value = in_vec[284 +: 6];
  localparam int OFF_io_perf_perfEventsHc_57_value = 278;
  wire [5:0] io_perf_perfEventsHc_57_value = in_vec[278 +: 6];
  localparam int OFF_io_perf_perfEventsHc_58_value = 272;
  wire [5:0] io_perf_perfEventsHc_58_value = in_vec[272 +: 6];
  localparam int OFF_io_perf_perfEventsHc_59_value = 266;
  wire [5:0] io_perf_perfEventsHc_59_value = in_vec[266 +: 6];
  localparam int OFF_io_perf_perfEventsHc_60_value = 260;
  wire [5:0] io_perf_perfEventsHc_60_value = in_vec[260 +: 6];
  localparam int OFF_io_perf_perfEventsHc_61_value = 254;
  wire [5:0] io_perf_perfEventsHc_61_value = in_vec[254 +: 6];
  localparam int OFF_io_perf_perfEventsHc_62_value = 248;
  wire [5:0] io_perf_perfEventsHc_62_value = in_vec[248 +: 6];
  localparam int OFF_io_perf_perfEventsHc_63_value = 242;
  wire [5:0] io_perf_perfEventsHc_63_value = in_vec[242 +: 6];
  localparam int OFF_io_perf_perfEventsHc_64_value = 236;
  wire [5:0] io_perf_perfEventsHc_64_value = in_vec[236 +: 6];
  localparam int OFF_io_perf_perfEventsHc_65_value = 230;
  wire [5:0] io_perf_perfEventsHc_65_value = in_vec[230 +: 6];
  localparam int OFF_io_perf_perfEventsHc_66_value = 224;
  wire [5:0] io_perf_perfEventsHc_66_value = in_vec[224 +: 6];
  localparam int OFF_io_perf_perfEventsHc_67_value = 218;
  wire [5:0] io_perf_perfEventsHc_67_value = in_vec[218 +: 6];
  localparam int OFF_io_out_ready = 217;
  wire [0:0] io_out_ready = in_vec[217 +: 1];
  localparam int OFF_io_fetchMalTval = 153;
  wire [63:0] io_fetchMalTval = in_vec[153 +: 64];
  localparam int OFF_io_oldPrivSate_PRVM = 151;
  wire [1:0] io_oldPrivSate_PRVM = in_vec[151 +: 2];
  localparam int OFF_io_oldPrivSate_V = 150;
  wire [0:0] io_oldPrivSate_V = in_vec[150 +: 1];
  localparam int OFF_io_oldSatpMode = 146;
  wire [3:0] io_oldSatpMode = in_vec[146 +: 4];
  localparam int OFF_io_oldVsatpMode = 142;
  wire [3:0] io_oldVsatpMode = in_vec[142 +: 4];
  localparam int OFF_fromAIA_rdata_valid = 141;
  wire [0:0] fromAIA_rdata_valid = in_vec[141 +: 1];
  localparam int OFF_fromAIA_rdata_bits_data = 77;
  wire [63:0] fromAIA_rdata_bits_data = in_vec[77 +: 64];
  localparam int OFF_fromAIA_rdata_bits_illegal = 76;
  wire [0:0] fromAIA_rdata_bits_illegal = in_vec[76 +: 1];
  localparam int OFF_fromAIA_meip = 75;
  wire [0:0] fromAIA_meip = in_vec[75 +: 1];
  localparam int OFF_fromAIA_seip = 74;
  wire [0:0] fromAIA_seip = in_vec[74 +: 1];
  localparam int OFF_fromAIA_notice_pending = 73;
  wire [0:0] fromAIA_notice_pending = in_vec[73 +: 1];
  localparam int OFF_fromAIA_vseip = 66;
  wire [6:0] fromAIA_vseip = in_vec[66 +: 7];
  localparam int OFF_fromAIA_mtopei_IID = 55;
  wire [10:0] fromAIA_mtopei_IID = in_vec[55 +: 11];
  localparam int OFF_fromAIA_mtopei_IPRIO = 44;
  wire [10:0] fromAIA_mtopei_IPRIO = in_vec[44 +: 11];
  localparam int OFF_fromAIA_stopei_IID = 33;
  wire [10:0] fromAIA_stopei_IID = in_vec[33 +: 11];
  localparam int OFF_fromAIA_stopei_IPRIO = 22;
  wire [10:0] fromAIA_stopei_IPRIO = in_vec[22 +: 11];
  localparam int OFF_fromAIA_vstopei_IID = 11;
  wire [10:0] fromAIA_vstopei_IID = in_vec[11 +: 11];
  localparam int OFF_fromAIA_vstopei_IPRIO = 0;
  wire [10:0] fromAIA_vstopei_IPRIO = in_vec[0 +: 11];
  NewCSR u_g (
    .clock(clock),
    .reset(reset),
    .platformIRP_MEIP(platformIRP_MEIP),
    .platformIRP_MTIP(platformIRP_MTIP),
    .platformIRP_MSIP(platformIRP_MSIP),
    .platformIRP_SEIP(platformIRP_SEIP),
    .platformIRP_debugIP(platformIRP_debugIP),
    .nonMaskableIRP_NMI_43(nonMaskableIRP_NMI_43),
    .nonMaskableIRP_NMI_31(nonMaskableIRP_NMI_31),
    .io_fromTop_hartId(io_fromTop_hartId),
    .io_fromTop_clintTime_valid(io_fromTop_clintTime_valid),
    .io_fromTop_clintTime_bits(io_fromTop_clintTime_bits),
    .io_fromTop_l2FlushDone(io_fromTop_l2FlushDone),
    .io_fromTop_criticalErrorState(io_fromTop_criticalErrorState),
    .io_in_valid(io_in_valid),
    .io_in_bits_wen(io_in_bits_wen),
    .io_in_bits_ren(io_in_bits_ren),
    .io_in_bits_op(io_in_bits_op),
    .io_in_bits_addr(io_in_bits_addr),
    .io_in_bits_src(io_in_bits_src),
    .io_in_bits_wdata(io_in_bits_wdata),
    .io_in_bits_mnret(io_in_bits_mnret),
    .io_in_bits_mret(io_in_bits_mret),
    .io_in_bits_sret(io_in_bits_sret),
    .io_in_bits_dret(io_in_bits_dret),
    .io_in_bits_redirectFlush(io_in_bits_redirectFlush),
    .io_trapInst_valid(io_trapInst_valid),
    .io_trapInst_bits(io_trapInst_bits),
    .io_fromMem_excpVA(io_fromMem_excpVA),
    .io_fromMem_excpGPA(io_fromMem_excpGPA),
    .io_fromMem_excpIsForVSnonLeafPTE(io_fromMem_excpIsForVSnonLeafPTE),
    .io_fromRob_trap_valid(io_fromRob_trap_valid),
    .io_fromRob_trap_bits_pc(io_fromRob_trap_bits_pc),
    .io_fromRob_trap_bits_pcGPA(io_fromRob_trap_bits_pcGPA),
    .io_fromRob_trap_bits_instr(io_fromRob_trap_bits_instr),
    .io_fromRob_trap_bits_trapVec(io_fromRob_trap_bits_trapVec),
    .io_fromRob_trap_bits_isFetchBkpt(io_fromRob_trap_bits_isFetchBkpt),
    .io_fromRob_trap_bits_singleStep(io_fromRob_trap_bits_singleStep),
    .io_fromRob_trap_bits_trigger(io_fromRob_trap_bits_trigger),
    .io_fromRob_trap_bits_crossPageIPFFix(io_fromRob_trap_bits_crossPageIPFFix),
    .io_fromRob_trap_bits_isInterrupt(io_fromRob_trap_bits_isInterrupt),
    .io_fromRob_trap_bits_isHls(io_fromRob_trap_bits_isHls),
    .io_fromRob_trap_bits_isFetchMalAddr(io_fromRob_trap_bits_isFetchMalAddr),
    .io_fromRob_trap_bits_isForVSnonLeafPTE(io_fromRob_trap_bits_isForVSnonLeafPTE),
    .io_fromRob_trap_bits_satpFlushFirstFetchFault(io_fromRob_trap_bits_satpFlushFirstFetchFault),
    .io_fromRob_commit_instNum_bits(io_fromRob_commit_instNum_bits),
    .io_fromRob_commit_fflags_valid(io_fromRob_commit_fflags_valid),
    .io_fromRob_commit_fflags_bits(io_fromRob_commit_fflags_bits),
    .io_fromRob_commit_fsDirty(io_fromRob_commit_fsDirty),
    .io_fromRob_commit_vxsat_valid(io_fromRob_commit_vxsat_valid),
    .io_fromRob_commit_vxsat_bits(io_fromRob_commit_vxsat_bits),
    .io_fromRob_commit_vsDirty(io_fromRob_commit_vsDirty),
    .io_fromRob_commit_vtype_valid(io_fromRob_commit_vtype_valid),
    .io_fromRob_commit_vtype_bits_VILL(io_fromRob_commit_vtype_bits_VILL),
    .io_fromRob_commit_vtype_bits_VMA(io_fromRob_commit_vtype_bits_VMA),
    .io_fromRob_commit_vtype_bits_VTA(io_fromRob_commit_vtype_bits_VTA),
    .io_fromRob_commit_vtype_bits_VSEW(io_fromRob_commit_vtype_bits_VSEW),
    .io_fromRob_commit_vtype_bits_VLMUL(io_fromRob_commit_vtype_bits_VLMUL),
    .io_fromRob_commit_vl(io_fromRob_commit_vl),
    .io_fromRob_commit_vstart_valid(io_fromRob_commit_vstart_valid),
    .io_fromRob_commit_vstart_bits(io_fromRob_commit_vstart_bits),
    .io_fromVecExcpMod_busy(io_fromVecExcpMod_busy),
    .io_perf_perfEventsFrontend_0_value(io_perf_perfEventsFrontend_0_value),
    .io_perf_perfEventsFrontend_1_value(io_perf_perfEventsFrontend_1_value),
    .io_perf_perfEventsFrontend_2_value(io_perf_perfEventsFrontend_2_value),
    .io_perf_perfEventsFrontend_3_value(io_perf_perfEventsFrontend_3_value),
    .io_perf_perfEventsFrontend_4_value(io_perf_perfEventsFrontend_4_value),
    .io_perf_perfEventsFrontend_5_value(io_perf_perfEventsFrontend_5_value),
    .io_perf_perfEventsFrontend_6_value(io_perf_perfEventsFrontend_6_value),
    .io_perf_perfEventsFrontend_7_value(io_perf_perfEventsFrontend_7_value),
    .io_perf_perfEventsBackend_0_value(io_perf_perfEventsBackend_0_value),
    .io_perf_perfEventsBackend_1_value(io_perf_perfEventsBackend_1_value),
    .io_perf_perfEventsBackend_2_value(io_perf_perfEventsBackend_2_value),
    .io_perf_perfEventsBackend_3_value(io_perf_perfEventsBackend_3_value),
    .io_perf_perfEventsBackend_4_value(io_perf_perfEventsBackend_4_value),
    .io_perf_perfEventsBackend_5_value(io_perf_perfEventsBackend_5_value),
    .io_perf_perfEventsBackend_6_value(io_perf_perfEventsBackend_6_value),
    .io_perf_perfEventsBackend_7_value(io_perf_perfEventsBackend_7_value),
    .io_perf_perfEventsLsu_0_value(io_perf_perfEventsLsu_0_value),
    .io_perf_perfEventsLsu_1_value(io_perf_perfEventsLsu_1_value),
    .io_perf_perfEventsLsu_2_value(io_perf_perfEventsLsu_2_value),
    .io_perf_perfEventsLsu_3_value(io_perf_perfEventsLsu_3_value),
    .io_perf_perfEventsLsu_4_value(io_perf_perfEventsLsu_4_value),
    .io_perf_perfEventsLsu_5_value(io_perf_perfEventsLsu_5_value),
    .io_perf_perfEventsLsu_6_value(io_perf_perfEventsLsu_6_value),
    .io_perf_perfEventsLsu_7_value(io_perf_perfEventsLsu_7_value),
    .io_perf_perfEventsHc_0_value(io_perf_perfEventsHc_0_value),
    .io_perf_perfEventsHc_1_value(io_perf_perfEventsHc_1_value),
    .io_perf_perfEventsHc_2_value(io_perf_perfEventsHc_2_value),
    .io_perf_perfEventsHc_3_value(io_perf_perfEventsHc_3_value),
    .io_perf_perfEventsHc_4_value(io_perf_perfEventsHc_4_value),
    .io_perf_perfEventsHc_5_value(io_perf_perfEventsHc_5_value),
    .io_perf_perfEventsHc_6_value(io_perf_perfEventsHc_6_value),
    .io_perf_perfEventsHc_7_value(io_perf_perfEventsHc_7_value),
    .io_perf_perfEventsHc_8_value(io_perf_perfEventsHc_8_value),
    .io_perf_perfEventsHc_9_value(io_perf_perfEventsHc_9_value),
    .io_perf_perfEventsHc_10_value(io_perf_perfEventsHc_10_value),
    .io_perf_perfEventsHc_11_value(io_perf_perfEventsHc_11_value),
    .io_perf_perfEventsHc_12_value(io_perf_perfEventsHc_12_value),
    .io_perf_perfEventsHc_13_value(io_perf_perfEventsHc_13_value),
    .io_perf_perfEventsHc_14_value(io_perf_perfEventsHc_14_value),
    .io_perf_perfEventsHc_15_value(io_perf_perfEventsHc_15_value),
    .io_perf_perfEventsHc_16_value(io_perf_perfEventsHc_16_value),
    .io_perf_perfEventsHc_17_value(io_perf_perfEventsHc_17_value),
    .io_perf_perfEventsHc_18_value(io_perf_perfEventsHc_18_value),
    .io_perf_perfEventsHc_19_value(io_perf_perfEventsHc_19_value),
    .io_perf_perfEventsHc_20_value(io_perf_perfEventsHc_20_value),
    .io_perf_perfEventsHc_21_value(io_perf_perfEventsHc_21_value),
    .io_perf_perfEventsHc_22_value(io_perf_perfEventsHc_22_value),
    .io_perf_perfEventsHc_23_value(io_perf_perfEventsHc_23_value),
    .io_perf_perfEventsHc_24_value(io_perf_perfEventsHc_24_value),
    .io_perf_perfEventsHc_25_value(io_perf_perfEventsHc_25_value),
    .io_perf_perfEventsHc_26_value(io_perf_perfEventsHc_26_value),
    .io_perf_perfEventsHc_27_value(io_perf_perfEventsHc_27_value),
    .io_perf_perfEventsHc_28_value(io_perf_perfEventsHc_28_value),
    .io_perf_perfEventsHc_29_value(io_perf_perfEventsHc_29_value),
    .io_perf_perfEventsHc_30_value(io_perf_perfEventsHc_30_value),
    .io_perf_perfEventsHc_31_value(io_perf_perfEventsHc_31_value),
    .io_perf_perfEventsHc_32_value(io_perf_perfEventsHc_32_value),
    .io_perf_perfEventsHc_33_value(io_perf_perfEventsHc_33_value),
    .io_perf_perfEventsHc_34_value(io_perf_perfEventsHc_34_value),
    .io_perf_perfEventsHc_35_value(io_perf_perfEventsHc_35_value),
    .io_perf_perfEventsHc_36_value(io_perf_perfEventsHc_36_value),
    .io_perf_perfEventsHc_37_value(io_perf_perfEventsHc_37_value),
    .io_perf_perfEventsHc_38_value(io_perf_perfEventsHc_38_value),
    .io_perf_perfEventsHc_39_value(io_perf_perfEventsHc_39_value),
    .io_perf_perfEventsHc_40_value(io_perf_perfEventsHc_40_value),
    .io_perf_perfEventsHc_41_value(io_perf_perfEventsHc_41_value),
    .io_perf_perfEventsHc_42_value(io_perf_perfEventsHc_42_value),
    .io_perf_perfEventsHc_43_value(io_perf_perfEventsHc_43_value),
    .io_perf_perfEventsHc_44_value(io_perf_perfEventsHc_44_value),
    .io_perf_perfEventsHc_45_value(io_perf_perfEventsHc_45_value),
    .io_perf_perfEventsHc_46_value(io_perf_perfEventsHc_46_value),
    .io_perf_perfEventsHc_47_value(io_perf_perfEventsHc_47_value),
    .io_perf_perfEventsHc_48_value(io_perf_perfEventsHc_48_value),
    .io_perf_perfEventsHc_49_value(io_perf_perfEventsHc_49_value),
    .io_perf_perfEventsHc_50_value(io_perf_perfEventsHc_50_value),
    .io_perf_perfEventsHc_51_value(io_perf_perfEventsHc_51_value),
    .io_perf_perfEventsHc_52_value(io_perf_perfEventsHc_52_value),
    .io_perf_perfEventsHc_53_value(io_perf_perfEventsHc_53_value),
    .io_perf_perfEventsHc_54_value(io_perf_perfEventsHc_54_value),
    .io_perf_perfEventsHc_55_value(io_perf_perfEventsHc_55_value),
    .io_perf_perfEventsHc_56_value(io_perf_perfEventsHc_56_value),
    .io_perf_perfEventsHc_57_value(io_perf_perfEventsHc_57_value),
    .io_perf_perfEventsHc_58_value(io_perf_perfEventsHc_58_value),
    .io_perf_perfEventsHc_59_value(io_perf_perfEventsHc_59_value),
    .io_perf_perfEventsHc_60_value(io_perf_perfEventsHc_60_value),
    .io_perf_perfEventsHc_61_value(io_perf_perfEventsHc_61_value),
    .io_perf_perfEventsHc_62_value(io_perf_perfEventsHc_62_value),
    .io_perf_perfEventsHc_63_value(io_perf_perfEventsHc_63_value),
    .io_perf_perfEventsHc_64_value(io_perf_perfEventsHc_64_value),
    .io_perf_perfEventsHc_65_value(io_perf_perfEventsHc_65_value),
    .io_perf_perfEventsHc_66_value(io_perf_perfEventsHc_66_value),
    .io_perf_perfEventsHc_67_value(io_perf_perfEventsHc_67_value),
    .io_out_ready(io_out_ready),
    .io_fetchMalTval(io_fetchMalTval),
    .io_oldPrivSate_PRVM(io_oldPrivSate_PRVM),
    .io_oldPrivSate_V(io_oldPrivSate_V),
    .io_oldSatpMode(io_oldSatpMode),
    .io_oldVsatpMode(io_oldVsatpMode),
    .fromAIA_rdata_valid(fromAIA_rdata_valid),
    .fromAIA_rdata_bits_data(fromAIA_rdata_bits_data),
    .fromAIA_rdata_bits_illegal(fromAIA_rdata_bits_illegal),
    .fromAIA_meip(fromAIA_meip),
    .fromAIA_seip(fromAIA_seip),
    .fromAIA_notice_pending(fromAIA_notice_pending),
    .fromAIA_vseip(fromAIA_vseip),
    .fromAIA_mtopei_IID(fromAIA_mtopei_IID),
    .fromAIA_mtopei_IPRIO(fromAIA_mtopei_IPRIO),
    .fromAIA_stopei_IID(fromAIA_stopei_IID),
    .fromAIA_stopei_IPRIO(fromAIA_stopei_IPRIO),
    .fromAIA_vstopei_IID(fromAIA_vstopei_IID),
    .fromAIA_vstopei_IPRIO(fromAIA_vstopei_IPRIO),
    .io_in_ready(g_out[4848 +: 1]),
    .io_out_valid(g_out[4847 +: 1]),
    .io_out_bits_EX_II(g_out[4846 +: 1]),
    .io_out_bits_EX_VI(g_out[4845 +: 1]),
    .io_out_bits_flushPipe(g_out[4844 +: 1]),
    .io_out_bits_rData(g_out[4780 +: 64]),
    .io_out_bits_targetPcUpdate(g_out[4779 +: 1]),
    .io_out_bits_targetPc_pc(g_out[4715 +: 64]),
    .io_out_bits_targetPc_raiseIPF(g_out[4714 +: 1]),
    .io_out_bits_targetPc_raiseIAF(g_out[4713 +: 1]),
    .io_out_bits_targetPc_raiseIGPF(g_out[4712 +: 1]),
    .io_out_bits_regOut(g_out[4648 +: 64]),
    .io_out_bits_isPerfCnt(g_out[4647 +: 1]),
    .io_status_privState_PRVM(g_out[4645 +: 2]),
    .io_status_privState_V(g_out[4644 +: 1]),
    .io_status_interrupt(g_out[4643 +: 1]),
    .io_status_wfiEvent(g_out[4642 +: 1]),
    .io_status_satp_valid(g_out[4641 +: 1]),
    .io_status_satp_bits(g_out[4637 +: 4]),
    .io_status_vsatp_valid(g_out[4636 +: 1]),
    .io_status_vsatp_bits(g_out[4632 +: 4]),
    .io_status_fpState_frm(g_out[4629 +: 3]),
    .io_status_vecState_vstart(g_out[4622 +: 7]),
    .io_status_vecState_vxrm(g_out[4620 +: 2]),
    .io_status_singleStepFlag(g_out[4619 +: 1]),
    .io_status_frontendTrigger_tUpdate_valid(g_out[4618 +: 1]),
    .io_status_frontendTrigger_tUpdate_bits_addr(g_out[4616 +: 2]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_matchType(g_out[4614 +: 2]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_select(g_out[4613 +: 1]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_action(g_out[4609 +: 4]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_chain(g_out[4608 +: 1]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_tdata2(g_out[4544 +: 64]),
    .io_status_frontendTrigger_tEnableVec_0(g_out[4543 +: 1]),
    .io_status_frontendTrigger_tEnableVec_1(g_out[4542 +: 1]),
    .io_status_frontendTrigger_tEnableVec_2(g_out[4541 +: 1]),
    .io_status_frontendTrigger_tEnableVec_3(g_out[4540 +: 1]),
    .io_status_frontendTrigger_debugMode(g_out[4539 +: 1]),
    .io_status_frontendTrigger_triggerCanRaiseBpExp(g_out[4538 +: 1]),
    .io_status_memTrigger_tUpdate_valid(g_out[4537 +: 1]),
    .io_status_memTrigger_tUpdate_bits_addr(g_out[4535 +: 2]),
    .io_status_memTrigger_tUpdate_bits_tdata_matchType(g_out[4533 +: 2]),
    .io_status_memTrigger_tUpdate_bits_tdata_select(g_out[4532 +: 1]),
    .io_status_memTrigger_tUpdate_bits_tdata_action(g_out[4528 +: 4]),
    .io_status_memTrigger_tUpdate_bits_tdata_chain(g_out[4527 +: 1]),
    .io_status_memTrigger_tUpdate_bits_tdata_store(g_out[4526 +: 1]),
    .io_status_memTrigger_tUpdate_bits_tdata_load(g_out[4525 +: 1]),
    .io_status_memTrigger_tUpdate_bits_tdata_tdata2(g_out[4461 +: 64]),
    .io_status_memTrigger_tEnableVec_0(g_out[4460 +: 1]),
    .io_status_memTrigger_tEnableVec_1(g_out[4459 +: 1]),
    .io_status_memTrigger_tEnableVec_2(g_out[4458 +: 1]),
    .io_status_memTrigger_tEnableVec_3(g_out[4457 +: 1]),
    .io_status_memTrigger_debugMode(g_out[4456 +: 1]),
    .io_status_memTrigger_triggerCanRaiseBpExp(g_out[4455 +: 1]),
    .io_status_instrAddrTransType_bare(g_out[4454 +: 1]),
    .io_status_instrAddrTransType_sv39(g_out[4453 +: 1]),
    .io_status_instrAddrTransType_sv39x4(g_out[4452 +: 1]),
    .io_status_instrAddrTransType_sv48(g_out[4451 +: 1]),
    .io_status_instrAddrTransType_sv48x4(g_out[4450 +: 1]),
    .io_status_traceCSR_cause(g_out[4386 +: 64]),
    .io_status_traceCSR_tval(g_out[4336 +: 50]),
    .io_status_traceCSR_mstatus(g_out[4272 +: 64]),
    .io_status_traceCSR_lastPriv(g_out[4269 +: 3]),
    .io_status_traceCSR_currentPriv(g_out[4266 +: 3]),
    .io_status_custom_pf_ctrl_l1I_pf_enable(g_out[4265 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_enable(g_out[4264 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_enable(g_out[4263 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_train_on_hit(g_out[4262 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_enable_agt(g_out[4261 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_enable_pht(g_out[4260 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_active_threshold(g_out[4256 +: 4]),
    .io_status_custom_pf_ctrl_l1D_pf_active_stride(g_out[4250 +: 6]),
    .io_status_custom_pf_ctrl_l1D_pf_enable_stride(g_out[4249 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_store_only(g_out[4248 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_recv_enable(g_out[4247 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_pbop_enable(g_out[4246 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_vbop_enable(g_out[4245 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_delay_latency(g_out[4235 +: 10]),
    .io_status_custom_lvpred_timeout(g_out[4230 +: 5]),
    .io_status_custom_bp_ctrl_ubtb_enable(g_out[4229 +: 1]),
    .io_status_custom_bp_ctrl_btb_enable(g_out[4228 +: 1]),
    .io_status_custom_bp_ctrl_tage_enable(g_out[4227 +: 1]),
    .io_status_custom_bp_ctrl_sc_enable(g_out[4226 +: 1]),
    .io_status_custom_bp_ctrl_ras_enable(g_out[4225 +: 1]),
    .io_status_custom_sbuffer_timeout(g_out[4203 +: 22]),
    .io_status_custom_ldld_vio_check_enable(g_out[4202 +: 1]),
    .io_status_custom_cache_error_enable(g_out[4201 +: 1]),
    .io_status_custom_uncache_write_outstanding_enable(g_out[4200 +: 1]),
    .io_status_custom_hd_misalign_st_enable(g_out[4199 +: 1]),
    .io_status_custom_hd_misalign_ld_enable(g_out[4198 +: 1]),
    .io_status_custom_power_down_enable(g_out[4197 +: 1]),
    .io_status_custom_flush_l2_enable(g_out[4196 +: 1]),
    .io_status_custom_fusion_enable(g_out[4195 +: 1]),
    .io_status_custom_wfi_enable(g_out[4194 +: 1]),
    .io_status_criticalErrorState(g_out[4193 +: 1]),
    .io_tlb_satpASIDChanged(g_out[4192 +: 1]),
    .io_tlb_vsatpASIDChanged(g_out[4191 +: 1]),
    .io_tlb_hgatpVMIDChanged(g_out[4190 +: 1]),
    .io_tlb_satp_MODE(g_out[4186 +: 4]),
    .io_tlb_satp_ASID(g_out[4170 +: 16]),
    .io_tlb_satp_PPN(g_out[4126 +: 44]),
    .io_tlb_vsatp_MODE(g_out[4122 +: 4]),
    .io_tlb_vsatp_ASID(g_out[4106 +: 16]),
    .io_tlb_vsatp_PPN(g_out[4062 +: 44]),
    .io_tlb_hgatp_MODE(g_out[4058 +: 4]),
    .io_tlb_hgatp_VMID(g_out[4044 +: 14]),
    .io_tlb_hgatp_PPN(g_out[4000 +: 44]),
    .io_tlb_mbmc_BMA(g_out[3942 +: 58]),
    .io_tlb_mbmc_BME(g_out[3941 +: 1]),
    .io_tlb_mbmc_BCLEAR(g_out[3940 +: 1]),
    .io_tlb_mbmc_CMODE(g_out[3939 +: 1]),
    .io_tlb_mxr(g_out[3938 +: 1]),
    .io_tlb_sum(g_out[3937 +: 1]),
    .io_tlb_vmxr(g_out[3936 +: 1]),
    .io_tlb_vsum(g_out[3935 +: 1]),
    .io_tlb_spvp(g_out[3934 +: 1]),
    .io_tlb_imode(g_out[3932 +: 2]),
    .io_tlb_dmode(g_out[3930 +: 2]),
    .io_tlb_debug(g_out[3929 +: 1]),
    .io_tlb_dvirt(g_out[3928 +: 1]),
    .io_tlb_mPBMTE(g_out[3927 +: 1]),
    .io_tlb_hPBMTE(g_out[3926 +: 1]),
    .io_tlb_pmm_mseccfg(g_out[3924 +: 2]),
    .io_tlb_pmm_menvcfg(g_out[3922 +: 2]),
    .io_tlb_pmm_henvcfg(g_out[3920 +: 2]),
    .io_tlb_pmm_hstatus(g_out[3918 +: 2]),
    .io_tlb_pmm_senvcfg(g_out[3916 +: 2]),
    .io_toDecode_illegalInst_sfenceVMA(g_out[3915 +: 1]),
    .io_toDecode_illegalInst_sfencePart(g_out[3914 +: 1]),
    .io_toDecode_illegalInst_hfenceGVMA(g_out[3913 +: 1]),
    .io_toDecode_illegalInst_hfenceVVMA(g_out[3912 +: 1]),
    .io_toDecode_illegalInst_hlsv(g_out[3911 +: 1]),
    .io_toDecode_illegalInst_fsIsOff(g_out[3910 +: 1]),
    .io_toDecode_illegalInst_vsIsOff(g_out[3909 +: 1]),
    .io_toDecode_illegalInst_wfi(g_out[3908 +: 1]),
    .io_toDecode_illegalInst_wrs_nto(g_out[3907 +: 1]),
    .io_toDecode_illegalInst_frm(g_out[3906 +: 1]),
    .io_toDecode_illegalInst_cboZ(g_out[3905 +: 1]),
    .io_toDecode_illegalInst_cboCF(g_out[3904 +: 1]),
    .io_toDecode_illegalInst_cboI(g_out[3903 +: 1]),
    .io_toDecode_virtualInst_sfenceVMA(g_out[3902 +: 1]),
    .io_toDecode_virtualInst_sfencePart(g_out[3901 +: 1]),
    .io_toDecode_virtualInst_hfence(g_out[3900 +: 1]),
    .io_toDecode_virtualInst_hlsv(g_out[3899 +: 1]),
    .io_toDecode_virtualInst_wfi(g_out[3898 +: 1]),
    .io_toDecode_virtualInst_wrs_nto(g_out[3897 +: 1]),
    .io_toDecode_virtualInst_cboZ(g_out[3896 +: 1]),
    .io_toDecode_virtualInst_cboCF(g_out[3895 +: 1]),
    .io_toDecode_virtualInst_cboI(g_out[3894 +: 1]),
    .io_toDecode_special_cboI2F(g_out[3893 +: 1]),
    .io_distributedWenLegal(g_out[3892 +: 1]),
    .toAIA_addr_valid(g_out[3891 +: 1]),
    .toAIA_addr_bits_addr(g_out[3879 +: 12]),
    .toAIA_addr_bits_v(g_out[3878 +: 1]),
    .toAIA_addr_bits_prvm(g_out[3876 +: 2]),
    .toAIA_vgein(g_out[3870 +: 6]),
    .toAIA_wdata_valid(g_out[3869 +: 1]),
    .toAIA_wdata_bits_op(g_out[3867 +: 2]),
    .toAIA_wdata_bits_data(g_out[3803 +: 64]),
    .toAIA_mClaim(g_out[3802 +: 1]),
    .toAIA_sClaim(g_out[3801 +: 1]),
    .toAIA_vsClaim(g_out[3800 +: 1]),
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
  NewCSR_xs u_i (
    .clock(clock),
    .reset(reset),
    .platformIRP_MEIP(platformIRP_MEIP),
    .platformIRP_MTIP(platformIRP_MTIP),
    .platformIRP_MSIP(platformIRP_MSIP),
    .platformIRP_SEIP(platformIRP_SEIP),
    .platformIRP_debugIP(platformIRP_debugIP),
    .nonMaskableIRP_NMI_43(nonMaskableIRP_NMI_43),
    .nonMaskableIRP_NMI_31(nonMaskableIRP_NMI_31),
    .io_fromTop_hartId(io_fromTop_hartId),
    .io_fromTop_clintTime_valid(io_fromTop_clintTime_valid),
    .io_fromTop_clintTime_bits(io_fromTop_clintTime_bits),
    .io_fromTop_l2FlushDone(io_fromTop_l2FlushDone),
    .io_fromTop_criticalErrorState(io_fromTop_criticalErrorState),
    .io_in_valid(io_in_valid),
    .io_in_bits_wen(io_in_bits_wen),
    .io_in_bits_ren(io_in_bits_ren),
    .io_in_bits_op(io_in_bits_op),
    .io_in_bits_addr(io_in_bits_addr),
    .io_in_bits_src(io_in_bits_src),
    .io_in_bits_wdata(io_in_bits_wdata),
    .io_in_bits_mnret(io_in_bits_mnret),
    .io_in_bits_mret(io_in_bits_mret),
    .io_in_bits_sret(io_in_bits_sret),
    .io_in_bits_dret(io_in_bits_dret),
    .io_in_bits_redirectFlush(io_in_bits_redirectFlush),
    .io_trapInst_valid(io_trapInst_valid),
    .io_trapInst_bits(io_trapInst_bits),
    .io_fromMem_excpVA(io_fromMem_excpVA),
    .io_fromMem_excpGPA(io_fromMem_excpGPA),
    .io_fromMem_excpIsForVSnonLeafPTE(io_fromMem_excpIsForVSnonLeafPTE),
    .io_fromRob_trap_valid(io_fromRob_trap_valid),
    .io_fromRob_trap_bits_pc(io_fromRob_trap_bits_pc),
    .io_fromRob_trap_bits_pcGPA(io_fromRob_trap_bits_pcGPA),
    .io_fromRob_trap_bits_instr(io_fromRob_trap_bits_instr),
    .io_fromRob_trap_bits_trapVec(io_fromRob_trap_bits_trapVec),
    .io_fromRob_trap_bits_isFetchBkpt(io_fromRob_trap_bits_isFetchBkpt),
    .io_fromRob_trap_bits_singleStep(io_fromRob_trap_bits_singleStep),
    .io_fromRob_trap_bits_trigger(io_fromRob_trap_bits_trigger),
    .io_fromRob_trap_bits_crossPageIPFFix(io_fromRob_trap_bits_crossPageIPFFix),
    .io_fromRob_trap_bits_isInterrupt(io_fromRob_trap_bits_isInterrupt),
    .io_fromRob_trap_bits_isHls(io_fromRob_trap_bits_isHls),
    .io_fromRob_trap_bits_isFetchMalAddr(io_fromRob_trap_bits_isFetchMalAddr),
    .io_fromRob_trap_bits_isForVSnonLeafPTE(io_fromRob_trap_bits_isForVSnonLeafPTE),
    .io_fromRob_trap_bits_satpFlushFirstFetchFault(io_fromRob_trap_bits_satpFlushFirstFetchFault),
    .io_fromRob_commit_instNum_bits(io_fromRob_commit_instNum_bits),
    .io_fromRob_commit_fflags_valid(io_fromRob_commit_fflags_valid),
    .io_fromRob_commit_fflags_bits(io_fromRob_commit_fflags_bits),
    .io_fromRob_commit_fsDirty(io_fromRob_commit_fsDirty),
    .io_fromRob_commit_vxsat_valid(io_fromRob_commit_vxsat_valid),
    .io_fromRob_commit_vxsat_bits(io_fromRob_commit_vxsat_bits),
    .io_fromRob_commit_vsDirty(io_fromRob_commit_vsDirty),
    .io_fromRob_commit_vtype_valid(io_fromRob_commit_vtype_valid),
    .io_fromRob_commit_vtype_bits_VILL(io_fromRob_commit_vtype_bits_VILL),
    .io_fromRob_commit_vtype_bits_VMA(io_fromRob_commit_vtype_bits_VMA),
    .io_fromRob_commit_vtype_bits_VTA(io_fromRob_commit_vtype_bits_VTA),
    .io_fromRob_commit_vtype_bits_VSEW(io_fromRob_commit_vtype_bits_VSEW),
    .io_fromRob_commit_vtype_bits_VLMUL(io_fromRob_commit_vtype_bits_VLMUL),
    .io_fromRob_commit_vl(io_fromRob_commit_vl),
    .io_fromRob_commit_vstart_valid(io_fromRob_commit_vstart_valid),
    .io_fromRob_commit_vstart_bits(io_fromRob_commit_vstart_bits),
    .io_fromVecExcpMod_busy(io_fromVecExcpMod_busy),
    .io_perf_perfEventsFrontend_0_value(io_perf_perfEventsFrontend_0_value),
    .io_perf_perfEventsFrontend_1_value(io_perf_perfEventsFrontend_1_value),
    .io_perf_perfEventsFrontend_2_value(io_perf_perfEventsFrontend_2_value),
    .io_perf_perfEventsFrontend_3_value(io_perf_perfEventsFrontend_3_value),
    .io_perf_perfEventsFrontend_4_value(io_perf_perfEventsFrontend_4_value),
    .io_perf_perfEventsFrontend_5_value(io_perf_perfEventsFrontend_5_value),
    .io_perf_perfEventsFrontend_6_value(io_perf_perfEventsFrontend_6_value),
    .io_perf_perfEventsFrontend_7_value(io_perf_perfEventsFrontend_7_value),
    .io_perf_perfEventsBackend_0_value(io_perf_perfEventsBackend_0_value),
    .io_perf_perfEventsBackend_1_value(io_perf_perfEventsBackend_1_value),
    .io_perf_perfEventsBackend_2_value(io_perf_perfEventsBackend_2_value),
    .io_perf_perfEventsBackend_3_value(io_perf_perfEventsBackend_3_value),
    .io_perf_perfEventsBackend_4_value(io_perf_perfEventsBackend_4_value),
    .io_perf_perfEventsBackend_5_value(io_perf_perfEventsBackend_5_value),
    .io_perf_perfEventsBackend_6_value(io_perf_perfEventsBackend_6_value),
    .io_perf_perfEventsBackend_7_value(io_perf_perfEventsBackend_7_value),
    .io_perf_perfEventsLsu_0_value(io_perf_perfEventsLsu_0_value),
    .io_perf_perfEventsLsu_1_value(io_perf_perfEventsLsu_1_value),
    .io_perf_perfEventsLsu_2_value(io_perf_perfEventsLsu_2_value),
    .io_perf_perfEventsLsu_3_value(io_perf_perfEventsLsu_3_value),
    .io_perf_perfEventsLsu_4_value(io_perf_perfEventsLsu_4_value),
    .io_perf_perfEventsLsu_5_value(io_perf_perfEventsLsu_5_value),
    .io_perf_perfEventsLsu_6_value(io_perf_perfEventsLsu_6_value),
    .io_perf_perfEventsLsu_7_value(io_perf_perfEventsLsu_7_value),
    .io_perf_perfEventsHc_0_value(io_perf_perfEventsHc_0_value),
    .io_perf_perfEventsHc_1_value(io_perf_perfEventsHc_1_value),
    .io_perf_perfEventsHc_2_value(io_perf_perfEventsHc_2_value),
    .io_perf_perfEventsHc_3_value(io_perf_perfEventsHc_3_value),
    .io_perf_perfEventsHc_4_value(io_perf_perfEventsHc_4_value),
    .io_perf_perfEventsHc_5_value(io_perf_perfEventsHc_5_value),
    .io_perf_perfEventsHc_6_value(io_perf_perfEventsHc_6_value),
    .io_perf_perfEventsHc_7_value(io_perf_perfEventsHc_7_value),
    .io_perf_perfEventsHc_8_value(io_perf_perfEventsHc_8_value),
    .io_perf_perfEventsHc_9_value(io_perf_perfEventsHc_9_value),
    .io_perf_perfEventsHc_10_value(io_perf_perfEventsHc_10_value),
    .io_perf_perfEventsHc_11_value(io_perf_perfEventsHc_11_value),
    .io_perf_perfEventsHc_12_value(io_perf_perfEventsHc_12_value),
    .io_perf_perfEventsHc_13_value(io_perf_perfEventsHc_13_value),
    .io_perf_perfEventsHc_14_value(io_perf_perfEventsHc_14_value),
    .io_perf_perfEventsHc_15_value(io_perf_perfEventsHc_15_value),
    .io_perf_perfEventsHc_16_value(io_perf_perfEventsHc_16_value),
    .io_perf_perfEventsHc_17_value(io_perf_perfEventsHc_17_value),
    .io_perf_perfEventsHc_18_value(io_perf_perfEventsHc_18_value),
    .io_perf_perfEventsHc_19_value(io_perf_perfEventsHc_19_value),
    .io_perf_perfEventsHc_20_value(io_perf_perfEventsHc_20_value),
    .io_perf_perfEventsHc_21_value(io_perf_perfEventsHc_21_value),
    .io_perf_perfEventsHc_22_value(io_perf_perfEventsHc_22_value),
    .io_perf_perfEventsHc_23_value(io_perf_perfEventsHc_23_value),
    .io_perf_perfEventsHc_24_value(io_perf_perfEventsHc_24_value),
    .io_perf_perfEventsHc_25_value(io_perf_perfEventsHc_25_value),
    .io_perf_perfEventsHc_26_value(io_perf_perfEventsHc_26_value),
    .io_perf_perfEventsHc_27_value(io_perf_perfEventsHc_27_value),
    .io_perf_perfEventsHc_28_value(io_perf_perfEventsHc_28_value),
    .io_perf_perfEventsHc_29_value(io_perf_perfEventsHc_29_value),
    .io_perf_perfEventsHc_30_value(io_perf_perfEventsHc_30_value),
    .io_perf_perfEventsHc_31_value(io_perf_perfEventsHc_31_value),
    .io_perf_perfEventsHc_32_value(io_perf_perfEventsHc_32_value),
    .io_perf_perfEventsHc_33_value(io_perf_perfEventsHc_33_value),
    .io_perf_perfEventsHc_34_value(io_perf_perfEventsHc_34_value),
    .io_perf_perfEventsHc_35_value(io_perf_perfEventsHc_35_value),
    .io_perf_perfEventsHc_36_value(io_perf_perfEventsHc_36_value),
    .io_perf_perfEventsHc_37_value(io_perf_perfEventsHc_37_value),
    .io_perf_perfEventsHc_38_value(io_perf_perfEventsHc_38_value),
    .io_perf_perfEventsHc_39_value(io_perf_perfEventsHc_39_value),
    .io_perf_perfEventsHc_40_value(io_perf_perfEventsHc_40_value),
    .io_perf_perfEventsHc_41_value(io_perf_perfEventsHc_41_value),
    .io_perf_perfEventsHc_42_value(io_perf_perfEventsHc_42_value),
    .io_perf_perfEventsHc_43_value(io_perf_perfEventsHc_43_value),
    .io_perf_perfEventsHc_44_value(io_perf_perfEventsHc_44_value),
    .io_perf_perfEventsHc_45_value(io_perf_perfEventsHc_45_value),
    .io_perf_perfEventsHc_46_value(io_perf_perfEventsHc_46_value),
    .io_perf_perfEventsHc_47_value(io_perf_perfEventsHc_47_value),
    .io_perf_perfEventsHc_48_value(io_perf_perfEventsHc_48_value),
    .io_perf_perfEventsHc_49_value(io_perf_perfEventsHc_49_value),
    .io_perf_perfEventsHc_50_value(io_perf_perfEventsHc_50_value),
    .io_perf_perfEventsHc_51_value(io_perf_perfEventsHc_51_value),
    .io_perf_perfEventsHc_52_value(io_perf_perfEventsHc_52_value),
    .io_perf_perfEventsHc_53_value(io_perf_perfEventsHc_53_value),
    .io_perf_perfEventsHc_54_value(io_perf_perfEventsHc_54_value),
    .io_perf_perfEventsHc_55_value(io_perf_perfEventsHc_55_value),
    .io_perf_perfEventsHc_56_value(io_perf_perfEventsHc_56_value),
    .io_perf_perfEventsHc_57_value(io_perf_perfEventsHc_57_value),
    .io_perf_perfEventsHc_58_value(io_perf_perfEventsHc_58_value),
    .io_perf_perfEventsHc_59_value(io_perf_perfEventsHc_59_value),
    .io_perf_perfEventsHc_60_value(io_perf_perfEventsHc_60_value),
    .io_perf_perfEventsHc_61_value(io_perf_perfEventsHc_61_value),
    .io_perf_perfEventsHc_62_value(io_perf_perfEventsHc_62_value),
    .io_perf_perfEventsHc_63_value(io_perf_perfEventsHc_63_value),
    .io_perf_perfEventsHc_64_value(io_perf_perfEventsHc_64_value),
    .io_perf_perfEventsHc_65_value(io_perf_perfEventsHc_65_value),
    .io_perf_perfEventsHc_66_value(io_perf_perfEventsHc_66_value),
    .io_perf_perfEventsHc_67_value(io_perf_perfEventsHc_67_value),
    .io_out_ready(io_out_ready),
    .io_fetchMalTval(io_fetchMalTval),
    .io_oldPrivSate_PRVM(io_oldPrivSate_PRVM),
    .io_oldPrivSate_V(io_oldPrivSate_V),
    .io_oldSatpMode(io_oldSatpMode),
    .io_oldVsatpMode(io_oldVsatpMode),
    .fromAIA_rdata_valid(fromAIA_rdata_valid),
    .fromAIA_rdata_bits_data(fromAIA_rdata_bits_data),
    .fromAIA_rdata_bits_illegal(fromAIA_rdata_bits_illegal),
    .fromAIA_meip(fromAIA_meip),
    .fromAIA_seip(fromAIA_seip),
    .fromAIA_notice_pending(fromAIA_notice_pending),
    .fromAIA_vseip(fromAIA_vseip),
    .fromAIA_mtopei_IID(fromAIA_mtopei_IID),
    .fromAIA_mtopei_IPRIO(fromAIA_mtopei_IPRIO),
    .fromAIA_stopei_IID(fromAIA_stopei_IID),
    .fromAIA_stopei_IPRIO(fromAIA_stopei_IPRIO),
    .fromAIA_vstopei_IID(fromAIA_vstopei_IID),
    .fromAIA_vstopei_IPRIO(fromAIA_vstopei_IPRIO),
    .io_in_ready(i_out[4848 +: 1]),
    .io_out_valid(i_out[4847 +: 1]),
    .io_out_bits_EX_II(i_out[4846 +: 1]),
    .io_out_bits_EX_VI(i_out[4845 +: 1]),
    .io_out_bits_flushPipe(i_out[4844 +: 1]),
    .io_out_bits_rData(i_out[4780 +: 64]),
    .io_out_bits_targetPcUpdate(i_out[4779 +: 1]),
    .io_out_bits_targetPc_pc(i_out[4715 +: 64]),
    .io_out_bits_targetPc_raiseIPF(i_out[4714 +: 1]),
    .io_out_bits_targetPc_raiseIAF(i_out[4713 +: 1]),
    .io_out_bits_targetPc_raiseIGPF(i_out[4712 +: 1]),
    .io_out_bits_regOut(i_out[4648 +: 64]),
    .io_out_bits_isPerfCnt(i_out[4647 +: 1]),
    .io_status_privState_PRVM(i_out[4645 +: 2]),
    .io_status_privState_V(i_out[4644 +: 1]),
    .io_status_interrupt(i_out[4643 +: 1]),
    .io_status_wfiEvent(i_out[4642 +: 1]),
    .io_status_satp_valid(i_out[4641 +: 1]),
    .io_status_satp_bits(i_out[4637 +: 4]),
    .io_status_vsatp_valid(i_out[4636 +: 1]),
    .io_status_vsatp_bits(i_out[4632 +: 4]),
    .io_status_fpState_frm(i_out[4629 +: 3]),
    .io_status_vecState_vstart(i_out[4622 +: 7]),
    .io_status_vecState_vxrm(i_out[4620 +: 2]),
    .io_status_singleStepFlag(i_out[4619 +: 1]),
    .io_status_frontendTrigger_tUpdate_valid(i_out[4618 +: 1]),
    .io_status_frontendTrigger_tUpdate_bits_addr(i_out[4616 +: 2]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_matchType(i_out[4614 +: 2]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_select(i_out[4613 +: 1]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_action(i_out[4609 +: 4]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_chain(i_out[4608 +: 1]),
    .io_status_frontendTrigger_tUpdate_bits_tdata_tdata2(i_out[4544 +: 64]),
    .io_status_frontendTrigger_tEnableVec_0(i_out[4543 +: 1]),
    .io_status_frontendTrigger_tEnableVec_1(i_out[4542 +: 1]),
    .io_status_frontendTrigger_tEnableVec_2(i_out[4541 +: 1]),
    .io_status_frontendTrigger_tEnableVec_3(i_out[4540 +: 1]),
    .io_status_frontendTrigger_debugMode(i_out[4539 +: 1]),
    .io_status_frontendTrigger_triggerCanRaiseBpExp(i_out[4538 +: 1]),
    .io_status_memTrigger_tUpdate_valid(i_out[4537 +: 1]),
    .io_status_memTrigger_tUpdate_bits_addr(i_out[4535 +: 2]),
    .io_status_memTrigger_tUpdate_bits_tdata_matchType(i_out[4533 +: 2]),
    .io_status_memTrigger_tUpdate_bits_tdata_select(i_out[4532 +: 1]),
    .io_status_memTrigger_tUpdate_bits_tdata_action(i_out[4528 +: 4]),
    .io_status_memTrigger_tUpdate_bits_tdata_chain(i_out[4527 +: 1]),
    .io_status_memTrigger_tUpdate_bits_tdata_store(i_out[4526 +: 1]),
    .io_status_memTrigger_tUpdate_bits_tdata_load(i_out[4525 +: 1]),
    .io_status_memTrigger_tUpdate_bits_tdata_tdata2(i_out[4461 +: 64]),
    .io_status_memTrigger_tEnableVec_0(i_out[4460 +: 1]),
    .io_status_memTrigger_tEnableVec_1(i_out[4459 +: 1]),
    .io_status_memTrigger_tEnableVec_2(i_out[4458 +: 1]),
    .io_status_memTrigger_tEnableVec_3(i_out[4457 +: 1]),
    .io_status_memTrigger_debugMode(i_out[4456 +: 1]),
    .io_status_memTrigger_triggerCanRaiseBpExp(i_out[4455 +: 1]),
    .io_status_instrAddrTransType_bare(i_out[4454 +: 1]),
    .io_status_instrAddrTransType_sv39(i_out[4453 +: 1]),
    .io_status_instrAddrTransType_sv39x4(i_out[4452 +: 1]),
    .io_status_instrAddrTransType_sv48(i_out[4451 +: 1]),
    .io_status_instrAddrTransType_sv48x4(i_out[4450 +: 1]),
    .io_status_traceCSR_cause(i_out[4386 +: 64]),
    .io_status_traceCSR_tval(i_out[4336 +: 50]),
    .io_status_traceCSR_mstatus(i_out[4272 +: 64]),
    .io_status_traceCSR_lastPriv(i_out[4269 +: 3]),
    .io_status_traceCSR_currentPriv(i_out[4266 +: 3]),
    .io_status_custom_pf_ctrl_l1I_pf_enable(i_out[4265 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_enable(i_out[4264 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_enable(i_out[4263 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_train_on_hit(i_out[4262 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_enable_agt(i_out[4261 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_enable_pht(i_out[4260 +: 1]),
    .io_status_custom_pf_ctrl_l1D_pf_active_threshold(i_out[4256 +: 4]),
    .io_status_custom_pf_ctrl_l1D_pf_active_stride(i_out[4250 +: 6]),
    .io_status_custom_pf_ctrl_l1D_pf_enable_stride(i_out[4249 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_store_only(i_out[4248 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_recv_enable(i_out[4247 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_pbop_enable(i_out[4246 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_vbop_enable(i_out[4245 +: 1]),
    .io_status_custom_pf_ctrl_l2_pf_delay_latency(i_out[4235 +: 10]),
    .io_status_custom_lvpred_timeout(i_out[4230 +: 5]),
    .io_status_custom_bp_ctrl_ubtb_enable(i_out[4229 +: 1]),
    .io_status_custom_bp_ctrl_btb_enable(i_out[4228 +: 1]),
    .io_status_custom_bp_ctrl_tage_enable(i_out[4227 +: 1]),
    .io_status_custom_bp_ctrl_sc_enable(i_out[4226 +: 1]),
    .io_status_custom_bp_ctrl_ras_enable(i_out[4225 +: 1]),
    .io_status_custom_sbuffer_timeout(i_out[4203 +: 22]),
    .io_status_custom_ldld_vio_check_enable(i_out[4202 +: 1]),
    .io_status_custom_cache_error_enable(i_out[4201 +: 1]),
    .io_status_custom_uncache_write_outstanding_enable(i_out[4200 +: 1]),
    .io_status_custom_hd_misalign_st_enable(i_out[4199 +: 1]),
    .io_status_custom_hd_misalign_ld_enable(i_out[4198 +: 1]),
    .io_status_custom_power_down_enable(i_out[4197 +: 1]),
    .io_status_custom_flush_l2_enable(i_out[4196 +: 1]),
    .io_status_custom_fusion_enable(i_out[4195 +: 1]),
    .io_status_custom_wfi_enable(i_out[4194 +: 1]),
    .io_status_criticalErrorState(i_out[4193 +: 1]),
    .io_tlb_satpASIDChanged(i_out[4192 +: 1]),
    .io_tlb_vsatpASIDChanged(i_out[4191 +: 1]),
    .io_tlb_hgatpVMIDChanged(i_out[4190 +: 1]),
    .io_tlb_satp_MODE(i_out[4186 +: 4]),
    .io_tlb_satp_ASID(i_out[4170 +: 16]),
    .io_tlb_satp_PPN(i_out[4126 +: 44]),
    .io_tlb_vsatp_MODE(i_out[4122 +: 4]),
    .io_tlb_vsatp_ASID(i_out[4106 +: 16]),
    .io_tlb_vsatp_PPN(i_out[4062 +: 44]),
    .io_tlb_hgatp_MODE(i_out[4058 +: 4]),
    .io_tlb_hgatp_VMID(i_out[4044 +: 14]),
    .io_tlb_hgatp_PPN(i_out[4000 +: 44]),
    .io_tlb_mbmc_BMA(i_out[3942 +: 58]),
    .io_tlb_mbmc_BME(i_out[3941 +: 1]),
    .io_tlb_mbmc_BCLEAR(i_out[3940 +: 1]),
    .io_tlb_mbmc_CMODE(i_out[3939 +: 1]),
    .io_tlb_mxr(i_out[3938 +: 1]),
    .io_tlb_sum(i_out[3937 +: 1]),
    .io_tlb_vmxr(i_out[3936 +: 1]),
    .io_tlb_vsum(i_out[3935 +: 1]),
    .io_tlb_spvp(i_out[3934 +: 1]),
    .io_tlb_imode(i_out[3932 +: 2]),
    .io_tlb_dmode(i_out[3930 +: 2]),
    .io_tlb_debug(i_out[3929 +: 1]),
    .io_tlb_dvirt(i_out[3928 +: 1]),
    .io_tlb_mPBMTE(i_out[3927 +: 1]),
    .io_tlb_hPBMTE(i_out[3926 +: 1]),
    .io_tlb_pmm_mseccfg(i_out[3924 +: 2]),
    .io_tlb_pmm_menvcfg(i_out[3922 +: 2]),
    .io_tlb_pmm_henvcfg(i_out[3920 +: 2]),
    .io_tlb_pmm_hstatus(i_out[3918 +: 2]),
    .io_tlb_pmm_senvcfg(i_out[3916 +: 2]),
    .io_toDecode_illegalInst_sfenceVMA(i_out[3915 +: 1]),
    .io_toDecode_illegalInst_sfencePart(i_out[3914 +: 1]),
    .io_toDecode_illegalInst_hfenceGVMA(i_out[3913 +: 1]),
    .io_toDecode_illegalInst_hfenceVVMA(i_out[3912 +: 1]),
    .io_toDecode_illegalInst_hlsv(i_out[3911 +: 1]),
    .io_toDecode_illegalInst_fsIsOff(i_out[3910 +: 1]),
    .io_toDecode_illegalInst_vsIsOff(i_out[3909 +: 1]),
    .io_toDecode_illegalInst_wfi(i_out[3908 +: 1]),
    .io_toDecode_illegalInst_wrs_nto(i_out[3907 +: 1]),
    .io_toDecode_illegalInst_frm(i_out[3906 +: 1]),
    .io_toDecode_illegalInst_cboZ(i_out[3905 +: 1]),
    .io_toDecode_illegalInst_cboCF(i_out[3904 +: 1]),
    .io_toDecode_illegalInst_cboI(i_out[3903 +: 1]),
    .io_toDecode_virtualInst_sfenceVMA(i_out[3902 +: 1]),
    .io_toDecode_virtualInst_sfencePart(i_out[3901 +: 1]),
    .io_toDecode_virtualInst_hfence(i_out[3900 +: 1]),
    .io_toDecode_virtualInst_hlsv(i_out[3899 +: 1]),
    .io_toDecode_virtualInst_wfi(i_out[3898 +: 1]),
    .io_toDecode_virtualInst_wrs_nto(i_out[3897 +: 1]),
    .io_toDecode_virtualInst_cboZ(i_out[3896 +: 1]),
    .io_toDecode_virtualInst_cboCF(i_out[3895 +: 1]),
    .io_toDecode_virtualInst_cboI(i_out[3894 +: 1]),
    .io_toDecode_special_cboI2F(i_out[3893 +: 1]),
    .io_distributedWenLegal(i_out[3892 +: 1]),
    .toAIA_addr_valid(i_out[3891 +: 1]),
    .toAIA_addr_bits_addr(i_out[3879 +: 12]),
    .toAIA_addr_bits_v(i_out[3878 +: 1]),
    .toAIA_addr_bits_prvm(i_out[3876 +: 2]),
    .toAIA_vgein(i_out[3870 +: 6]),
    .toAIA_wdata_valid(i_out[3869 +: 1]),
    .toAIA_wdata_bits_op(i_out[3867 +: 2]),
    .toAIA_wdata_bits_data(i_out[3803 +: 64]),
    .toAIA_mClaim(i_out[3802 +: 1]),
    .toAIA_sClaim(i_out[3801 +: 1]),
    .toAIA_vsClaim(i_out[3800 +: 1]),
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
  localparam string ONAME [NOUT] = '{"io_in_ready", "io_out_valid", "io_out_bits_EX_II", "io_out_bits_EX_VI", "io_out_bits_flushPipe", "io_out_bits_rData", "io_out_bits_targetPcUpdate", "io_out_bits_targetPc_pc", "io_out_bits_targetPc_raiseIPF", "io_out_bits_targetPc_raiseIAF", "io_out_bits_targetPc_raiseIGPF", "io_out_bits_regOut", "io_out_bits_isPerfCnt", "io_status_privState_PRVM", "io_status_privState_V", "io_status_interrupt", "io_status_wfiEvent", "io_status_satp_valid", "io_status_satp_bits", "io_status_vsatp_valid", "io_status_vsatp_bits", "io_status_fpState_frm", "io_status_vecState_vstart", "io_status_vecState_vxrm", "io_status_singleStepFlag", "io_status_frontendTrigger_tUpdate_valid", "io_status_frontendTrigger_tUpdate_bits_addr", "io_status_frontendTrigger_tUpdate_bits_tdata_matchType", "io_status_frontendTrigger_tUpdate_bits_tdata_select", "io_status_frontendTrigger_tUpdate_bits_tdata_action", "io_status_frontendTrigger_tUpdate_bits_tdata_chain", "io_status_frontendTrigger_tUpdate_bits_tdata_tdata2", "io_status_frontendTrigger_tEnableVec_0", "io_status_frontendTrigger_tEnableVec_1", "io_status_frontendTrigger_tEnableVec_2", "io_status_frontendTrigger_tEnableVec_3", "io_status_frontendTrigger_debugMode", "io_status_frontendTrigger_triggerCanRaiseBpExp", "io_status_memTrigger_tUpdate_valid", "io_status_memTrigger_tUpdate_bits_addr", "io_status_memTrigger_tUpdate_bits_tdata_matchType", "io_status_memTrigger_tUpdate_bits_tdata_select", "io_status_memTrigger_tUpdate_bits_tdata_action", "io_status_memTrigger_tUpdate_bits_tdata_chain", "io_status_memTrigger_tUpdate_bits_tdata_store", "io_status_memTrigger_tUpdate_bits_tdata_load", "io_status_memTrigger_tUpdate_bits_tdata_tdata2", "io_status_memTrigger_tEnableVec_0", "io_status_memTrigger_tEnableVec_1", "io_status_memTrigger_tEnableVec_2", "io_status_memTrigger_tEnableVec_3", "io_status_memTrigger_debugMode", "io_status_memTrigger_triggerCanRaiseBpExp", "io_status_instrAddrTransType_bare", "io_status_instrAddrTransType_sv39", "io_status_instrAddrTransType_sv39x4", "io_status_instrAddrTransType_sv48", "io_status_instrAddrTransType_sv48x4", "io_status_traceCSR_cause", "io_status_traceCSR_tval", "io_status_traceCSR_mstatus", "io_status_traceCSR_lastPriv", "io_status_traceCSR_currentPriv", "io_status_custom_pf_ctrl_l1I_pf_enable", "io_status_custom_pf_ctrl_l2_pf_enable", "io_status_custom_pf_ctrl_l1D_pf_enable", "io_status_custom_pf_ctrl_l1D_pf_train_on_hit", "io_status_custom_pf_ctrl_l1D_pf_enable_agt", "io_status_custom_pf_ctrl_l1D_pf_enable_pht", "io_status_custom_pf_ctrl_l1D_pf_active_threshold", "io_status_custom_pf_ctrl_l1D_pf_active_stride", "io_status_custom_pf_ctrl_l1D_pf_enable_stride", "io_status_custom_pf_ctrl_l2_pf_store_only", "io_status_custom_pf_ctrl_l2_pf_recv_enable", "io_status_custom_pf_ctrl_l2_pf_pbop_enable", "io_status_custom_pf_ctrl_l2_pf_vbop_enable", "io_status_custom_pf_ctrl_l2_pf_delay_latency", "io_status_custom_lvpred_timeout", "io_status_custom_bp_ctrl_ubtb_enable", "io_status_custom_bp_ctrl_btb_enable", "io_status_custom_bp_ctrl_tage_enable", "io_status_custom_bp_ctrl_sc_enable", "io_status_custom_bp_ctrl_ras_enable", "io_status_custom_sbuffer_timeout", "io_status_custom_ldld_vio_check_enable", "io_status_custom_cache_error_enable", "io_status_custom_uncache_write_outstanding_enable", "io_status_custom_hd_misalign_st_enable", "io_status_custom_hd_misalign_ld_enable", "io_status_custom_power_down_enable", "io_status_custom_flush_l2_enable", "io_status_custom_fusion_enable", "io_status_custom_wfi_enable", "io_status_criticalErrorState", "io_tlb_satpASIDChanged", "io_tlb_vsatpASIDChanged", "io_tlb_hgatpVMIDChanged", "io_tlb_satp_MODE", "io_tlb_satp_ASID", "io_tlb_satp_PPN", "io_tlb_vsatp_MODE", "io_tlb_vsatp_ASID", "io_tlb_vsatp_PPN", "io_tlb_hgatp_MODE", "io_tlb_hgatp_VMID", "io_tlb_hgatp_PPN", "io_tlb_mbmc_BMA", "io_tlb_mbmc_BME", "io_tlb_mbmc_BCLEAR", "io_tlb_mbmc_CMODE", "io_tlb_mxr", "io_tlb_sum", "io_tlb_vmxr", "io_tlb_vsum", "io_tlb_spvp", "io_tlb_imode", "io_tlb_dmode", "io_tlb_debug", "io_tlb_dvirt", "io_tlb_mPBMTE", "io_tlb_hPBMTE", "io_tlb_pmm_mseccfg", "io_tlb_pmm_menvcfg", "io_tlb_pmm_henvcfg", "io_tlb_pmm_hstatus", "io_tlb_pmm_senvcfg", "io_toDecode_illegalInst_sfenceVMA", "io_toDecode_illegalInst_sfencePart", "io_toDecode_illegalInst_hfenceGVMA", "io_toDecode_illegalInst_hfenceVVMA", "io_toDecode_illegalInst_hlsv", "io_toDecode_illegalInst_fsIsOff", "io_toDecode_illegalInst_vsIsOff", "io_toDecode_illegalInst_wfi", "io_toDecode_illegalInst_wrs_nto", "io_toDecode_illegalInst_frm", "io_toDecode_illegalInst_cboZ", "io_toDecode_illegalInst_cboCF", "io_toDecode_illegalInst_cboI", "io_toDecode_virtualInst_sfenceVMA", "io_toDecode_virtualInst_sfencePart", "io_toDecode_virtualInst_hfence", "io_toDecode_virtualInst_hlsv", "io_toDecode_virtualInst_wfi", "io_toDecode_virtualInst_wrs_nto", "io_toDecode_virtualInst_cboZ", "io_toDecode_virtualInst_cboCF", "io_toDecode_virtualInst_cboI", "io_toDecode_special_cboI2F", "io_distributedWenLegal", "toAIA_addr_valid", "toAIA_addr_bits_addr", "toAIA_addr_bits_v", "toAIA_addr_bits_prvm", "toAIA_vgein", "toAIA_wdata_valid", "toAIA_wdata_bits_op", "toAIA_wdata_bits_data", "toAIA_mClaim", "toAIA_sClaim", "toAIA_vsClaim", "io_error_0", "gatewayIn_packed_29_bore", "gatewayIn_packed_30_bore", "gatewayIn_packed_31_bore", "gatewayIn_packed_32_bore", "gatewayIn_packed_33_bore", "gatewayIn_packed_34_bore", "gatewayIn_packed_35_bore", "gatewayIn_packed_36_bore", "gatewayIn_packed_37_bore", "gatewayIn_packed_38_bore", "gatewayIn_packed_39_bore", "gatewayIn_packed_40_bore"};
  localparam int OLSB [NOUT] = '{4848, 4847, 4846, 4845, 4844, 4780, 4779, 4715, 4714, 4713, 4712, 4648, 4647, 4645, 4644, 4643, 4642, 4641, 4637, 4636, 4632, 4629, 4622, 4620, 4619, 4618, 4616, 4614, 4613, 4609, 4608, 4544, 4543, 4542, 4541, 4540, 4539, 4538, 4537, 4535, 4533, 4532, 4528, 4527, 4526, 4525, 4461, 4460, 4459, 4458, 4457, 4456, 4455, 4454, 4453, 4452, 4451, 4450, 4386, 4336, 4272, 4269, 4266, 4265, 4264, 4263, 4262, 4261, 4260, 4256, 4250, 4249, 4248, 4247, 4246, 4245, 4235, 4230, 4229, 4228, 4227, 4226, 4225, 4203, 4202, 4201, 4200, 4199, 4198, 4197, 4196, 4195, 4194, 4193, 4192, 4191, 4190, 4186, 4170, 4126, 4122, 4106, 4062, 4058, 4044, 4000, 3942, 3941, 3940, 3939, 3938, 3937, 3936, 3935, 3934, 3932, 3930, 3929, 3928, 3927, 3926, 3924, 3922, 3920, 3918, 3916, 3915, 3914, 3913, 3912, 3911, 3910, 3909, 3908, 3907, 3906, 3905, 3904, 3903, 3902, 3901, 3900, 3899, 3898, 3897, 3896, 3895, 3894, 3893, 3892, 3891, 3879, 3878, 3876, 3870, 3869, 3867, 3803, 3802, 3801, 3800, 3799, 3626, 3616, 2456, 2191, 1991, 1535, 1463, 367, 348, 275, 10, 0};
  localparam int OWID [NOUT] = '{1, 1, 1, 1, 1, 64, 1, 64, 1, 1, 1, 64, 1, 2, 1, 1, 1, 1, 4, 1, 4, 3, 7, 2, 1, 1, 2, 2, 1, 4, 1, 64, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 4, 1, 1, 1, 64, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 64, 50, 64, 3, 3, 1, 1, 1, 1, 1, 1, 4, 6, 1, 1, 1, 1, 1, 10, 5, 1, 1, 1, 1, 1, 22, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 16, 44, 4, 16, 44, 4, 14, 44, 58, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 12, 1, 2, 6, 1, 2, 64, 1, 1, 1, 1, 173, 10, 1160, 265, 200, 456, 72, 1096, 19, 73, 265, 10};
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
  logic [3:0] irq_lines;           // MEIP MTIP MSIP SEIP：慢变
  logic [63:0] clint_time;
  logic [5:0] hart_id;

  // 全部输入先整体随机，再按名覆盖关键字段
  task automatic drive_random();
    logic [11:0] a;
    for (int k = 0; k < IW; k += 32) in_vec[k +: 32] = $urandom;
    for (int k = 0; k < 4; k++) if (pct(5)) irq_lines[k] = ~irq_lines[k];
    {in_vec[OFF_platformIRP_MEIP], in_vec[OFF_platformIRP_MTIP],
     in_vec[OFF_platformIRP_MSIP], in_vec[OFF_platformIRP_SEIP]} = irq_lines;
    in_vec[OFF_platformIRP_debugIP]        = ($urandom_range(1999) == 0);
    // NMI 稀一些：进 MN 后 NMIE=0，这时再来 trap 就是双重 trap -> critical error（粘住到复位）
    in_vec[OFF_nonMaskableIRP_NMI_43]      = ($urandom_range(1999) == 0);
    in_vec[OFF_nonMaskableIRP_NMI_31]      = ($urandom_range(1999) == 0);
    in_vec[OFF_io_fromTop_hartId +: 6]     = hart_id;
    clint_time += $urandom_range(3);
    in_vec[OFF_io_fromTop_clintTime_bits +: 64] = clint_time;
    in_vec[OFF_io_fromTop_criticalErrorState] = ($urandom_range(49999) == 0);
    in_vec[OFF_io_in_valid]                = pct(60);
    in_vec[OFF_io_in_bits_wen]             = pct(40);
    in_vec[OFF_io_in_bits_ren]             = pct(50);
    a = pct(80) ? LEGAL[$urandom_range(NLEGAL-1)] : 12'($urandom);
    in_vec[OFF_io_in_bits_addr +: 12]      = a;
    in_vec[OFF_io_in_bits_wdata +: 64]     = rnd64();
    // dcsr：ebreak*/step 位多数时候清掉，否则几乎每个 trap 都进 debug、普通 trap 路径测不到
    if (a == 12'h7B0 && pct(90)) begin
      in_vec[OFF_io_in_bits_wdata + 12 +: 6] = 6'h0;   // EBREAKU/S/(14)/M/VU/VS
      in_vec[OFF_io_in_bits_wdata + 2] = 1'b0;         // STEP
    end
    // satp/vsatp/hgatp：MODE 只接受 Bare/Sv39/Sv48（hgatp 为 x4），随机值几乎总被 WARL 丢掉
    if ((a == 12'h180 || a == 12'h280 || a == 12'h680) && pct(70))
      in_vec[OFF_io_in_bits_wdata + 60 +: 4] = pct(30) ? 4'h0 : (pct(50) ? 4'h8 : 4'h9);
    // tdata1：TYPE=6（mcontrol6）才是合法触发器，否则触发器永远不更新
    if (a == 12'h7A1 && pct(70))
      in_vec[OFF_io_in_bits_wdata + 60 +: 4] = 4'h6;
    // tselect：只接受 0..3（超范围写被丢弃），随机 64 位几乎永远超范围
    if (a == 12'h7A0 && pct(80))
      in_vec[OFF_io_in_bits_wdata +: 64] = 64'($urandom_range(3));
    // 委托寄存器 m/h-edeleg/ideleg 一半写全 1：trap 才进得了 HS/VS
    if ((a == 12'h302 || a == 12'h303 || a == 12'h602 || a == 12'h603) && pct(50))
      in_vec[OFF_io_in_bits_wdata +: 64] = '1;
    // mnstatus：NMIE（bit 3）多数时候保持 1，否则 trap 全被挡住（NMIE=0 时 trap 不进任何态）
    if (a == 12'h744 && pct(90)) in_vec[OFF_io_in_bits_wdata + 3] = 1'b1;
    // *iselect：一半写进 IMSIC 窗口 [0x70,0xFF]，一半写 iprio 窗口 [0x30,0x3F]，让间接访问走得到
    if ((a == 12'h350 || a == 12'h150 || a == 12'h250) && pct(80))
      in_vec[OFF_io_in_bits_wdata +: 64] = pct(50) ? 64'($urandom_range(8'hFF, 8'h70))
                                                   : 64'($urandom_range(8'h3F, 8'h30));
    in_vec[OFF_io_in_bits_mnret]           = pct(2);
    in_vec[OFF_io_in_bits_mret]            = pct(2);
    in_vec[OFF_io_in_bits_sret]            = pct(2);
    in_vec[OFF_io_in_bits_dret]            = pct(2);
    in_vec[OFF_io_in_bits_redirectFlush]   = pct(3);
    in_vec[OFF_io_fromRob_trap_valid]      = pct(3);
    in_vec[OFF_io_fromRob_trap_bits_trapVec +: 64] =
      pct(80) ? (64'h1 << $urandom_range(63)) : (pct(50) ? 64'h0 : {$urandom, $urandom});
    in_vec[OFF_io_fromRob_trap_bits_isInterrupt]  = pct(30);
    in_vec[OFF_io_fromRob_trap_bits_singleStep]   = pct(1);
    in_vec[OFF_io_fromRob_trap_bits_isFetchBkpt]  = pct(5);
    in_vec[OFF_io_fromRob_trap_bits_satpFlushFirstFetchFault] = pct(5);
    in_vec[OFF_io_fromRob_trap_bits_trigger +: 4] = pct(85) ? 4'hF : 4'($urandom);
    in_vec[OFF_io_fromRob_commit_fflags_valid]    = pct(20);
    in_vec[OFF_io_fromRob_commit_vxsat_valid]     = pct(20);
    in_vec[OFF_io_fromRob_commit_vtype_valid]     = pct(20);
    in_vec[OFF_io_fromRob_commit_vstart_valid]    = pct(20);
    in_vec[OFF_io_fromRob_commit_fsDirty]         = pct(10);
    in_vec[OFF_io_fromRob_commit_vsDirty]         = pct(10);
    in_vec[OFF_io_fromVecExcpMod_busy]            = pct(20);
    in_vec[OFF_io_out_ready]                      = pct(70);
    in_vec[OFF_fromAIA_rdata_valid]               = pct(15);
    in_vec[OFF_fromAIA_rdata_bits_illegal]        = pct(20);
    // NMIE=0（复位值，或刚进 MN）时较快地把它写回 1：mnstatus 写 0 无效、写 1 置位。
    // 否则大部分时间 trap 都成了"双重 trap"，critical error 粘住后只剩进 debug 一条路。
    // NMIE=0 且不在 M 态时任何 trap 都进不去（只剩 debug），偶尔拉一下调试中断把它救回 M
    if (!u_g._mnstatus_regOut_NMIE && u_g.PRVM != 2'h3 && !u_g.debugMode && pct(2))
      in_vec[OFF_platformIRP_debugIP] = 1'b1;
    if (!u_g._mnstatus_regOut_NMIE && pct(10)) begin
      in_vec[OFF_io_in_valid] = 1'b1;
      in_vec[OFF_io_in_bits_wen] = 1'b1;
      in_vec[OFF_io_in_bits_addr +: 12] = 12'h744;
      in_vec[OFF_io_in_bits_wdata + 3] = 1'b1;
    end
  endtask

  // 预热：M 态逐个写合法 CSR（每个地址 2 拍），再一个 trap + 一个 mret
  task automatic warmup();
    for (int k = 0; k < NLEGAL; k++) begin
      for (int r = 0; r < 2; r++) begin
        drive_random();
        in_vec[OFF_io_in_valid] = 1'b1;
        in_vec[OFF_io_in_bits_wen] = 1'b1;
        in_vec[OFF_io_in_bits_ren] = 1'b1;
        in_vec[OFF_io_in_bits_addr +: 12] = LEGAL[k];
        if (LEGAL[k] == 12'h7B0) in_vec[OFF_io_in_bits_wdata +: 64] = 64'h0;   // 预热不进 debug
        if (LEGAL[k] == 12'h744) in_vec[OFF_io_in_bits_wdata + 3] = 1'b1;      // mnstatus.NMIE=1
        {in_vec[OFF_io_in_bits_mnret], in_vec[OFF_io_in_bits_mret],
         in_vec[OFF_io_in_bits_sret], in_vec[OFF_io_in_bits_dret]} = 4'h0;
        in_vec[OFF_io_in_bits_redirectFlush] = 1'b0;
        in_vec[OFF_io_fromRob_trap_valid] = 1'b0;
        in_vec[OFF_io_out_ready] = 1'b1;
        @(posedge clock); #1;
      end
    end
    // debug CSR（dpc/dscratch0/dscratch1）只有 debug 模式能写：拉调试中断进 debug，写完 dret
    // （调试中断经 InterruptFilter 要好几拍才锁进 debug，trap 放在第 12 拍）
    for (int r = 0; r < 14; r++) begin
      drive_random();
      in_vec[OFF_io_in_valid] = 1'b0;
      in_vec[OFF_platformIRP_debugIP] = 1'b1;
      in_vec[OFF_io_fromRob_trap_valid] = (r == 12);
      in_vec[OFF_io_fromRob_trap_bits_isInterrupt] = 1'b1;
      @(posedge clock); #1;
    end
    if (!u_g.debugMode) $display("WARMUP: did not enter debug (intrVec=%h debug=%b ivv=%b dbgIE=%b NMIE=%b crit=%b)",
      u_g.intrVec, u_g.debug, u_g._intrMod_io_out_interruptVec_valid, u_g.debugIntrEnable, u_g._mnstatus_regOut_NMIE, u_g.criticalErrorState);
    for (int k = 0; k < 3; k++) begin
      for (int r = 0; r < 2; r++) begin
        drive_random();
        in_vec[OFF_platformIRP_debugIP] = 1'b0;
        in_vec[OFF_io_in_valid] = 1'b1;
        in_vec[OFF_io_in_bits_wen] = 1'b1;
        in_vec[OFF_io_in_bits_addr +: 12] = 12'h7B1 + k;
        {in_vec[OFF_io_in_bits_mnret], in_vec[OFF_io_in_bits_mret],
         in_vec[OFF_io_in_bits_sret], in_vec[OFF_io_in_bits_dret]} = 4'h0;
        in_vec[OFF_io_in_bits_redirectFlush] = 1'b0;
        in_vec[OFF_io_fromRob_trap_valid] = 1'b0;
        in_vec[OFF_io_out_ready] = 1'b1;
        @(posedge clock); #1;
      end
    end
    for (int r = 0; r < 4; r++) begin
      drive_random();
      in_vec[OFF_platformIRP_debugIP] = 1'b0;
      in_vec[OFF_io_in_valid] = 1'b1;
      {in_vec[OFF_io_in_bits_mnret], in_vec[OFF_io_in_bits_mret],
       in_vec[OFF_io_in_bits_sret], in_vec[OFF_io_in_bits_dret]} = {3'h0, r == 0};
      in_vec[OFF_io_fromRob_trap_valid] = 1'b0;
      @(posedge clock); #1;
    end
    for (int r = 0; r < 4; r++) begin
      drive_random();
      in_vec[OFF_io_in_valid] = 1'b0;
      in_vec[OFF_io_fromRob_trap_valid] = (r == 0);
      @(posedge clock); #1;
    end
    for (int r = 0; r < 4; r++) begin
      drive_random();
      in_vec[OFF_io_in_valid] = 1'b1;
      in_vec[OFF_io_in_bits_mret] = (r == 0);
      in_vec[OFF_io_fromRob_trap_valid] = 1'b0;
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
          port_bad[p] = 1;
          begin
            // 打印第一个出错的 64 位块（宽口如 gatewayIn_packed_* 有上千位）
            int c0;
            logic [OW-1:0] gs, is;
            gs = g_out >> OLSB[p];
            is = i_out >> OLSB[p];
            c0 = 0;
            while (c0 + 64 < OWID[p] && gs[c0 +: 64] === is[c0 +: 64]) c0 += 64;
            $display("[%0t] MISMATCH %s bits[%0d +: 64] g=%h i=%h", $time, ONAME[p], c0,
                     gs[c0 +: 64], is[c0 +: 64]);
          end
        end
      end
    end
    tog |= prev_g ^ g_out;
    prev_g = g_out;
  end

  // ---------------- 覆盖（golden 内部信号）----------------
  wire io_out_valid_g = u_g.io_out_valid;
  wire g_ex_ii  = u_g.io_out_bits_EX_II;
  wire g_ex_vi  = u_g.io_out_bits_EX_VI;
  wire g_flush  = u_g.io_out_bits_flushPipe;
  wire g_target = u_g.io_out_bits_targetPcUpdate;
  longint f_trap_m = 0, f_trap_hs = 0, f_trap_vs = 0, f_trap_mn = 0, f_trap_d = 0;
  longint f_mret = 0, f_sret = 0, f_mnret = 0, f_dret = 0, f_wait = 0, f_wen = 0;
  longint f_ex_ii = 0, f_ex_vi = 0, f_flush = 0, f_target = 0;
  longint d_intr = 0, d_step = 0, d_trig = 0, d_ebreak = 0, d_crit = 0, dbg_cycles = 0, nmie0 = 0;
  bit [7:0] priv_seen;
  bit [4095:0] csr_written, legal_mask;
  always @(posedge clock) if (cmp_en && !reset) begin
    f_trap_m  += u_g.trapEntryMEvent.valid;
    f_trap_hs += u_g.trapEntryHSEvent.valid;
    f_trap_vs += u_g.trapEntryVSEvent.valid;
    f_trap_mn += u_g.trapEntryMNEvent.valid;
    f_trap_d  += u_g.trapEntryDEvent.valid;
    f_mret    += u_g._permitMod_io_out_hasLegalMret;
    f_sret    += u_g._permitMod_io_out_hasLegalSret;
    f_mnret   += u_g._permitMod_io_out_hasLegalMNret;
    f_dret    += u_g._permitMod_io_out_hasLegalDret;
    f_wait    += (u_g.state == 2'h1);
    f_wen     += u_g.wenLegalReg_last_REG;
    f_ex_ii   += io_out_valid_g & g_ex_ii;
    f_ex_vi   += io_out_valid_g & g_ex_vi;
    f_flush   += g_flush;
    f_target  += g_target;
    priv_seen[{u_g.V, u_g.PRVM}] = 1'b1;
    if (u_g.trapEntryDEvent.valid) begin
      d_intr   += u_g._debugMod_io_out_hasDebugIntr;
      d_step   += u_g._debugMod_io_out_hasSingleStep;
      d_trig   += u_g._debugMod_io_out_triggerEnterDebugMode;
      d_ebreak += u_g._debugMod_io_out_hasDebugEbreakException;
      d_crit   += u_g._debugMod_io_out_criticalErrorStateEnterDebug;
    end
    dbg_cycles += u_g.debugMode;
    nmie0 += !u_g._mnstatus_regOut_NMIE;
    if (u_g.wenLegalReg_last_REG) csr_written[u_g.io_in_bits_addr] = 1'b1;
  end

  // ---------------- 主流程 ----------------
  initial begin
    longint minf;
    int ntog, nport_tog;
    void'($value$plusargs("ncycles=%d", NCYCLES));
    legal_mask = '0;
    for (int k = 0; k < NLEGAL; k++) legal_mask[LEGAL[k]] = 1'b1;
    hart_id = $urandom;
    irq_lines = '0;
    clint_time = 0;
    cmp_en = 0;
    port_bad = '0;
    do_reset();
    cmp_en = 1;
    prev_g = g_out; tog = '0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      if (c != 0 && c % (NCYCLES / 10) == 0) begin   // 每 1/10 插一次复位（复位后重新预热）
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
    $display("NewCSR UT: checks=%0d errors=%0d bad_ports=%0d toggled_bits=%0d/%0d toggled_ports=%0d/%0d",
             checks, errors, $countones(port_bad), $countones(tog), OW, nport_tog, NOUT);
    $display("fires: trapM=%0d trapHS=%0d trapVS=%0d trapMN=%0d trapD=%0d mret=%0d sret=%0d mnret=%0d dret=%0d wait=%0d wen=%0d EX_II=%0d EX_VI=%0d flush=%0d target=%0d",
             f_trap_m, f_trap_hs, f_trap_vs, f_trap_mn, f_trap_d, f_mret, f_sret, f_mnret, f_dret,
             f_wait, f_wen, f_ex_ii, f_ex_vi, f_flush, f_target);
    $display("debug entry causes: intr=%0d step=%0d trigger=%0d ebreak=%0d critical=%0d; cycles in debug=%0d, NMIE=0 cycles=%0d",
             d_intr, d_step, d_trig, d_ebreak, d_crit, dbg_cycles, nmie0);
    $display("priv_seen(V,PRVM)=%b legal CSR addresses written=%0d/%0d", priv_seen,
             $countones(csr_written & legal_mask), NLEGAL);
    if (checks == 0) begin $display("TEST FAILED (no checks)"); $fatal(1); end
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (f_trap_m < minf || f_trap_hs < minf / 4 || f_trap_vs < minf / 8 || f_trap_mn < 1
        || f_mret < minf || f_sret < minf / 4 || f_wait < minf || f_wen < minf
        || f_ex_ii < minf || f_ex_vi < minf / 8 || f_flush < minf || f_target < minf) begin
      $display("TEST FAILED (coverage)"); $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end
endmodule

