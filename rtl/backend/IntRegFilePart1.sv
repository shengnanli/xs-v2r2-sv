// IntRegFilePart1.sv —— 整数物理寄存器堆的第 1 片（64 位数据的第 1 个 16 位切片），薄 wrapper
// =============================================================================
// 逻辑全部在共用核 xs_IntRegFilePart_core（同目录 xs_IntRegFilePart_core.sv），本层只做端口展平/改名：
//   golden 的扁平 io_readPorts_<r>_* / io_writePorts_<w>_* / io_debug_all_rdata_<i>
//   <-> 核的按口号成组的数组端口。
// 本变体参数：224 个物理寄存器（x0 恒零）、11 读口（同步读，延迟 1 拍）、8 写口（同址多写按位或）、
//   16 位数据、8 位地址；223 路 debug 全量读出（_1.._223，无 _0）。寄存器 3656 位，全部不复位。
// 与另外三片的差异：★无★。G1 golden 的 IntRegFilePart0..3 逐行相同，只差模块名那一行
//   （生成器逐行核对，差异多一行即失败）；片号只决定上层接哪 16 位。
// reset 在综合视图里没有负载（golden 只在 `ifndef SYNTHESIS 的同址写断言里用它）。
// 端口表逐字抄自 G1 golden 同名模块。自动生成：scripts/gen_intregfile.py —— 勿手改
// =============================================================================

module IntRegFilePart1(
  input         clock,
  input         reset,
  input  [7:0]  io_readPorts_0_addr,
  output [15:0] io_readPorts_0_data,
  input  [7:0]  io_readPorts_1_addr,
  output [15:0] io_readPorts_1_data,
  input  [7:0]  io_readPorts_2_addr,
  output [15:0] io_readPorts_2_data,
  input  [7:0]  io_readPorts_3_addr,
  output [15:0] io_readPorts_3_data,
  input  [7:0]  io_readPorts_4_addr,
  output [15:0] io_readPorts_4_data,
  input  [7:0]  io_readPorts_5_addr,
  output [15:0] io_readPorts_5_data,
  input  [7:0]  io_readPorts_6_addr,
  output [15:0] io_readPorts_6_data,
  input  [7:0]  io_readPorts_7_addr,
  output [15:0] io_readPorts_7_data,
  input  [7:0]  io_readPorts_8_addr,
  output [15:0] io_readPorts_8_data,
  input  [7:0]  io_readPorts_9_addr,
  output [15:0] io_readPorts_9_data,
  input  [7:0]  io_readPorts_10_addr,
  output [15:0] io_readPorts_10_data,
  input         io_writePorts_0_wen,
  input  [7:0]  io_writePorts_0_addr,
  input  [15:0] io_writePorts_0_data,
  input         io_writePorts_1_wen,
  input  [7:0]  io_writePorts_1_addr,
  input  [15:0] io_writePorts_1_data,
  input         io_writePorts_2_wen,
  input  [7:0]  io_writePorts_2_addr,
  input  [15:0] io_writePorts_2_data,
  input         io_writePorts_3_wen,
  input  [7:0]  io_writePorts_3_addr,
  input  [15:0] io_writePorts_3_data,
  input         io_writePorts_4_wen,
  input  [7:0]  io_writePorts_4_addr,
  input  [15:0] io_writePorts_4_data,
  input         io_writePorts_5_wen,
  input  [7:0]  io_writePorts_5_addr,
  input  [15:0] io_writePorts_5_data,
  input         io_writePorts_6_wen,
  input  [7:0]  io_writePorts_6_addr,
  input  [15:0] io_writePorts_6_data,
  input         io_writePorts_7_wen,
  input  [7:0]  io_writePorts_7_addr,
  input  [15:0] io_writePorts_7_data,
  output [15:0] io_debug_all_rdata_1,
  output [15:0] io_debug_all_rdata_2,
  output [15:0] io_debug_all_rdata_3,
  output [15:0] io_debug_all_rdata_4,
  output [15:0] io_debug_all_rdata_5,
  output [15:0] io_debug_all_rdata_6,
  output [15:0] io_debug_all_rdata_7,
  output [15:0] io_debug_all_rdata_8,
  output [15:0] io_debug_all_rdata_9,
  output [15:0] io_debug_all_rdata_10,
  output [15:0] io_debug_all_rdata_11,
  output [15:0] io_debug_all_rdata_12,
  output [15:0] io_debug_all_rdata_13,
  output [15:0] io_debug_all_rdata_14,
  output [15:0] io_debug_all_rdata_15,
  output [15:0] io_debug_all_rdata_16,
  output [15:0] io_debug_all_rdata_17,
  output [15:0] io_debug_all_rdata_18,
  output [15:0] io_debug_all_rdata_19,
  output [15:0] io_debug_all_rdata_20,
  output [15:0] io_debug_all_rdata_21,
  output [15:0] io_debug_all_rdata_22,
  output [15:0] io_debug_all_rdata_23,
  output [15:0] io_debug_all_rdata_24,
  output [15:0] io_debug_all_rdata_25,
  output [15:0] io_debug_all_rdata_26,
  output [15:0] io_debug_all_rdata_27,
  output [15:0] io_debug_all_rdata_28,
  output [15:0] io_debug_all_rdata_29,
  output [15:0] io_debug_all_rdata_30,
  output [15:0] io_debug_all_rdata_31,
  output [15:0] io_debug_all_rdata_32,
  output [15:0] io_debug_all_rdata_33,
  output [15:0] io_debug_all_rdata_34,
  output [15:0] io_debug_all_rdata_35,
  output [15:0] io_debug_all_rdata_36,
  output [15:0] io_debug_all_rdata_37,
  output [15:0] io_debug_all_rdata_38,
  output [15:0] io_debug_all_rdata_39,
  output [15:0] io_debug_all_rdata_40,
  output [15:0] io_debug_all_rdata_41,
  output [15:0] io_debug_all_rdata_42,
  output [15:0] io_debug_all_rdata_43,
  output [15:0] io_debug_all_rdata_44,
  output [15:0] io_debug_all_rdata_45,
  output [15:0] io_debug_all_rdata_46,
  output [15:0] io_debug_all_rdata_47,
  output [15:0] io_debug_all_rdata_48,
  output [15:0] io_debug_all_rdata_49,
  output [15:0] io_debug_all_rdata_50,
  output [15:0] io_debug_all_rdata_51,
  output [15:0] io_debug_all_rdata_52,
  output [15:0] io_debug_all_rdata_53,
  output [15:0] io_debug_all_rdata_54,
  output [15:0] io_debug_all_rdata_55,
  output [15:0] io_debug_all_rdata_56,
  output [15:0] io_debug_all_rdata_57,
  output [15:0] io_debug_all_rdata_58,
  output [15:0] io_debug_all_rdata_59,
  output [15:0] io_debug_all_rdata_60,
  output [15:0] io_debug_all_rdata_61,
  output [15:0] io_debug_all_rdata_62,
  output [15:0] io_debug_all_rdata_63,
  output [15:0] io_debug_all_rdata_64,
  output [15:0] io_debug_all_rdata_65,
  output [15:0] io_debug_all_rdata_66,
  output [15:0] io_debug_all_rdata_67,
  output [15:0] io_debug_all_rdata_68,
  output [15:0] io_debug_all_rdata_69,
  output [15:0] io_debug_all_rdata_70,
  output [15:0] io_debug_all_rdata_71,
  output [15:0] io_debug_all_rdata_72,
  output [15:0] io_debug_all_rdata_73,
  output [15:0] io_debug_all_rdata_74,
  output [15:0] io_debug_all_rdata_75,
  output [15:0] io_debug_all_rdata_76,
  output [15:0] io_debug_all_rdata_77,
  output [15:0] io_debug_all_rdata_78,
  output [15:0] io_debug_all_rdata_79,
  output [15:0] io_debug_all_rdata_80,
  output [15:0] io_debug_all_rdata_81,
  output [15:0] io_debug_all_rdata_82,
  output [15:0] io_debug_all_rdata_83,
  output [15:0] io_debug_all_rdata_84,
  output [15:0] io_debug_all_rdata_85,
  output [15:0] io_debug_all_rdata_86,
  output [15:0] io_debug_all_rdata_87,
  output [15:0] io_debug_all_rdata_88,
  output [15:0] io_debug_all_rdata_89,
  output [15:0] io_debug_all_rdata_90,
  output [15:0] io_debug_all_rdata_91,
  output [15:0] io_debug_all_rdata_92,
  output [15:0] io_debug_all_rdata_93,
  output [15:0] io_debug_all_rdata_94,
  output [15:0] io_debug_all_rdata_95,
  output [15:0] io_debug_all_rdata_96,
  output [15:0] io_debug_all_rdata_97,
  output [15:0] io_debug_all_rdata_98,
  output [15:0] io_debug_all_rdata_99,
  output [15:0] io_debug_all_rdata_100,
  output [15:0] io_debug_all_rdata_101,
  output [15:0] io_debug_all_rdata_102,
  output [15:0] io_debug_all_rdata_103,
  output [15:0] io_debug_all_rdata_104,
  output [15:0] io_debug_all_rdata_105,
  output [15:0] io_debug_all_rdata_106,
  output [15:0] io_debug_all_rdata_107,
  output [15:0] io_debug_all_rdata_108,
  output [15:0] io_debug_all_rdata_109,
  output [15:0] io_debug_all_rdata_110,
  output [15:0] io_debug_all_rdata_111,
  output [15:0] io_debug_all_rdata_112,
  output [15:0] io_debug_all_rdata_113,
  output [15:0] io_debug_all_rdata_114,
  output [15:0] io_debug_all_rdata_115,
  output [15:0] io_debug_all_rdata_116,
  output [15:0] io_debug_all_rdata_117,
  output [15:0] io_debug_all_rdata_118,
  output [15:0] io_debug_all_rdata_119,
  output [15:0] io_debug_all_rdata_120,
  output [15:0] io_debug_all_rdata_121,
  output [15:0] io_debug_all_rdata_122,
  output [15:0] io_debug_all_rdata_123,
  output [15:0] io_debug_all_rdata_124,
  output [15:0] io_debug_all_rdata_125,
  output [15:0] io_debug_all_rdata_126,
  output [15:0] io_debug_all_rdata_127,
  output [15:0] io_debug_all_rdata_128,
  output [15:0] io_debug_all_rdata_129,
  output [15:0] io_debug_all_rdata_130,
  output [15:0] io_debug_all_rdata_131,
  output [15:0] io_debug_all_rdata_132,
  output [15:0] io_debug_all_rdata_133,
  output [15:0] io_debug_all_rdata_134,
  output [15:0] io_debug_all_rdata_135,
  output [15:0] io_debug_all_rdata_136,
  output [15:0] io_debug_all_rdata_137,
  output [15:0] io_debug_all_rdata_138,
  output [15:0] io_debug_all_rdata_139,
  output [15:0] io_debug_all_rdata_140,
  output [15:0] io_debug_all_rdata_141,
  output [15:0] io_debug_all_rdata_142,
  output [15:0] io_debug_all_rdata_143,
  output [15:0] io_debug_all_rdata_144,
  output [15:0] io_debug_all_rdata_145,
  output [15:0] io_debug_all_rdata_146,
  output [15:0] io_debug_all_rdata_147,
  output [15:0] io_debug_all_rdata_148,
  output [15:0] io_debug_all_rdata_149,
  output [15:0] io_debug_all_rdata_150,
  output [15:0] io_debug_all_rdata_151,
  output [15:0] io_debug_all_rdata_152,
  output [15:0] io_debug_all_rdata_153,
  output [15:0] io_debug_all_rdata_154,
  output [15:0] io_debug_all_rdata_155,
  output [15:0] io_debug_all_rdata_156,
  output [15:0] io_debug_all_rdata_157,
  output [15:0] io_debug_all_rdata_158,
  output [15:0] io_debug_all_rdata_159,
  output [15:0] io_debug_all_rdata_160,
  output [15:0] io_debug_all_rdata_161,
  output [15:0] io_debug_all_rdata_162,
  output [15:0] io_debug_all_rdata_163,
  output [15:0] io_debug_all_rdata_164,
  output [15:0] io_debug_all_rdata_165,
  output [15:0] io_debug_all_rdata_166,
  output [15:0] io_debug_all_rdata_167,
  output [15:0] io_debug_all_rdata_168,
  output [15:0] io_debug_all_rdata_169,
  output [15:0] io_debug_all_rdata_170,
  output [15:0] io_debug_all_rdata_171,
  output [15:0] io_debug_all_rdata_172,
  output [15:0] io_debug_all_rdata_173,
  output [15:0] io_debug_all_rdata_174,
  output [15:0] io_debug_all_rdata_175,
  output [15:0] io_debug_all_rdata_176,
  output [15:0] io_debug_all_rdata_177,
  output [15:0] io_debug_all_rdata_178,
  output [15:0] io_debug_all_rdata_179,
  output [15:0] io_debug_all_rdata_180,
  output [15:0] io_debug_all_rdata_181,
  output [15:0] io_debug_all_rdata_182,
  output [15:0] io_debug_all_rdata_183,
  output [15:0] io_debug_all_rdata_184,
  output [15:0] io_debug_all_rdata_185,
  output [15:0] io_debug_all_rdata_186,
  output [15:0] io_debug_all_rdata_187,
  output [15:0] io_debug_all_rdata_188,
  output [15:0] io_debug_all_rdata_189,
  output [15:0] io_debug_all_rdata_190,
  output [15:0] io_debug_all_rdata_191,
  output [15:0] io_debug_all_rdata_192,
  output [15:0] io_debug_all_rdata_193,
  output [15:0] io_debug_all_rdata_194,
  output [15:0] io_debug_all_rdata_195,
  output [15:0] io_debug_all_rdata_196,
  output [15:0] io_debug_all_rdata_197,
  output [15:0] io_debug_all_rdata_198,
  output [15:0] io_debug_all_rdata_199,
  output [15:0] io_debug_all_rdata_200,
  output [15:0] io_debug_all_rdata_201,
  output [15:0] io_debug_all_rdata_202,
  output [15:0] io_debug_all_rdata_203,
  output [15:0] io_debug_all_rdata_204,
  output [15:0] io_debug_all_rdata_205,
  output [15:0] io_debug_all_rdata_206,
  output [15:0] io_debug_all_rdata_207,
  output [15:0] io_debug_all_rdata_208,
  output [15:0] io_debug_all_rdata_209,
  output [15:0] io_debug_all_rdata_210,
  output [15:0] io_debug_all_rdata_211,
  output [15:0] io_debug_all_rdata_212,
  output [15:0] io_debug_all_rdata_213,
  output [15:0] io_debug_all_rdata_214,
  output [15:0] io_debug_all_rdata_215,
  output [15:0] io_debug_all_rdata_216,
  output [15:0] io_debug_all_rdata_217,
  output [15:0] io_debug_all_rdata_218,
  output [15:0] io_debug_all_rdata_219,
  output [15:0] io_debug_all_rdata_220,
  output [15:0] io_debug_all_rdata_221,
  output [15:0] io_debug_all_rdata_222,
  output [15:0] io_debug_all_rdata_223
);

  logic [10:0][7:0] read_addr;
  logic [10:0][15:0] read_data;
  logic [7:0]       write_wen;
  logic [7:0][7:0]  write_addr;
  logic [7:0][15:0] write_data;
  logic [223:0][15:0] debug_all_rdata;

  // ---- 读口 ----
  assign read_addr[0] = io_readPorts_0_addr;
  assign read_addr[1] = io_readPorts_1_addr;
  assign read_addr[2] = io_readPorts_2_addr;
  assign read_addr[3] = io_readPorts_3_addr;
  assign read_addr[4] = io_readPorts_4_addr;
  assign read_addr[5] = io_readPorts_5_addr;
  assign read_addr[6] = io_readPorts_6_addr;
  assign read_addr[7] = io_readPorts_7_addr;
  assign read_addr[8] = io_readPorts_8_addr;
  assign read_addr[9] = io_readPorts_9_addr;
  assign read_addr[10] = io_readPorts_10_addr;
  assign io_readPorts_0_data = read_data[0];
  assign io_readPorts_1_data = read_data[1];
  assign io_readPorts_2_data = read_data[2];
  assign io_readPorts_3_data = read_data[3];
  assign io_readPorts_4_data = read_data[4];
  assign io_readPorts_5_data = read_data[5];
  assign io_readPorts_6_data = read_data[6];
  assign io_readPorts_7_data = read_data[7];
  assign io_readPorts_8_data = read_data[8];
  assign io_readPorts_9_data = read_data[9];
  assign io_readPorts_10_data = read_data[10];

  // ---- 写口 ----
  assign write_wen[0]  = io_writePorts_0_wen;
  assign write_addr[0] = io_writePorts_0_addr;
  assign write_data[0] = io_writePorts_0_data;
  assign write_wen[1]  = io_writePorts_1_wen;
  assign write_addr[1] = io_writePorts_1_addr;
  assign write_data[1] = io_writePorts_1_data;
  assign write_wen[2]  = io_writePorts_2_wen;
  assign write_addr[2] = io_writePorts_2_addr;
  assign write_data[2] = io_writePorts_2_data;
  assign write_wen[3]  = io_writePorts_3_wen;
  assign write_addr[3] = io_writePorts_3_addr;
  assign write_data[3] = io_writePorts_3_data;
  assign write_wen[4]  = io_writePorts_4_wen;
  assign write_addr[4] = io_writePorts_4_addr;
  assign write_data[4] = io_writePorts_4_data;
  assign write_wen[5]  = io_writePorts_5_wen;
  assign write_addr[5] = io_writePorts_5_addr;
  assign write_data[5] = io_writePorts_5_data;
  assign write_wen[6]  = io_writePorts_6_wen;
  assign write_addr[6] = io_writePorts_6_addr;
  assign write_data[6] = io_writePorts_6_data;
  assign write_wen[7]  = io_writePorts_7_wen;
  assign write_addr[7] = io_writePorts_7_addr;
  assign write_data[7] = io_writePorts_7_data;

  xs_IntRegFilePart_core #(
    .NUM_PREGS (224),
    .NUM_READ  (11),
    .NUM_WRITE (8),
    .DATA_W    (16),
    .ADDR_W    (8)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .read_addr       (read_addr),
    .read_data       (read_data),
    .write_wen       (write_wen),
    .write_addr      (write_addr),
    .write_data      (write_data),
    .debug_all_rdata (debug_all_rdata)
  );

  // ---- debug 全量读出（第 0 路 x0 恒零，golden 没有这个端口，不引出） ----
  assign io_debug_all_rdata_1 = debug_all_rdata[1];
  assign io_debug_all_rdata_2 = debug_all_rdata[2];
  assign io_debug_all_rdata_3 = debug_all_rdata[3];
  assign io_debug_all_rdata_4 = debug_all_rdata[4];
  assign io_debug_all_rdata_5 = debug_all_rdata[5];
  assign io_debug_all_rdata_6 = debug_all_rdata[6];
  assign io_debug_all_rdata_7 = debug_all_rdata[7];
  assign io_debug_all_rdata_8 = debug_all_rdata[8];
  assign io_debug_all_rdata_9 = debug_all_rdata[9];
  assign io_debug_all_rdata_10 = debug_all_rdata[10];
  assign io_debug_all_rdata_11 = debug_all_rdata[11];
  assign io_debug_all_rdata_12 = debug_all_rdata[12];
  assign io_debug_all_rdata_13 = debug_all_rdata[13];
  assign io_debug_all_rdata_14 = debug_all_rdata[14];
  assign io_debug_all_rdata_15 = debug_all_rdata[15];
  assign io_debug_all_rdata_16 = debug_all_rdata[16];
  assign io_debug_all_rdata_17 = debug_all_rdata[17];
  assign io_debug_all_rdata_18 = debug_all_rdata[18];
  assign io_debug_all_rdata_19 = debug_all_rdata[19];
  assign io_debug_all_rdata_20 = debug_all_rdata[20];
  assign io_debug_all_rdata_21 = debug_all_rdata[21];
  assign io_debug_all_rdata_22 = debug_all_rdata[22];
  assign io_debug_all_rdata_23 = debug_all_rdata[23];
  assign io_debug_all_rdata_24 = debug_all_rdata[24];
  assign io_debug_all_rdata_25 = debug_all_rdata[25];
  assign io_debug_all_rdata_26 = debug_all_rdata[26];
  assign io_debug_all_rdata_27 = debug_all_rdata[27];
  assign io_debug_all_rdata_28 = debug_all_rdata[28];
  assign io_debug_all_rdata_29 = debug_all_rdata[29];
  assign io_debug_all_rdata_30 = debug_all_rdata[30];
  assign io_debug_all_rdata_31 = debug_all_rdata[31];
  assign io_debug_all_rdata_32 = debug_all_rdata[32];
  assign io_debug_all_rdata_33 = debug_all_rdata[33];
  assign io_debug_all_rdata_34 = debug_all_rdata[34];
  assign io_debug_all_rdata_35 = debug_all_rdata[35];
  assign io_debug_all_rdata_36 = debug_all_rdata[36];
  assign io_debug_all_rdata_37 = debug_all_rdata[37];
  assign io_debug_all_rdata_38 = debug_all_rdata[38];
  assign io_debug_all_rdata_39 = debug_all_rdata[39];
  assign io_debug_all_rdata_40 = debug_all_rdata[40];
  assign io_debug_all_rdata_41 = debug_all_rdata[41];
  assign io_debug_all_rdata_42 = debug_all_rdata[42];
  assign io_debug_all_rdata_43 = debug_all_rdata[43];
  assign io_debug_all_rdata_44 = debug_all_rdata[44];
  assign io_debug_all_rdata_45 = debug_all_rdata[45];
  assign io_debug_all_rdata_46 = debug_all_rdata[46];
  assign io_debug_all_rdata_47 = debug_all_rdata[47];
  assign io_debug_all_rdata_48 = debug_all_rdata[48];
  assign io_debug_all_rdata_49 = debug_all_rdata[49];
  assign io_debug_all_rdata_50 = debug_all_rdata[50];
  assign io_debug_all_rdata_51 = debug_all_rdata[51];
  assign io_debug_all_rdata_52 = debug_all_rdata[52];
  assign io_debug_all_rdata_53 = debug_all_rdata[53];
  assign io_debug_all_rdata_54 = debug_all_rdata[54];
  assign io_debug_all_rdata_55 = debug_all_rdata[55];
  assign io_debug_all_rdata_56 = debug_all_rdata[56];
  assign io_debug_all_rdata_57 = debug_all_rdata[57];
  assign io_debug_all_rdata_58 = debug_all_rdata[58];
  assign io_debug_all_rdata_59 = debug_all_rdata[59];
  assign io_debug_all_rdata_60 = debug_all_rdata[60];
  assign io_debug_all_rdata_61 = debug_all_rdata[61];
  assign io_debug_all_rdata_62 = debug_all_rdata[62];
  assign io_debug_all_rdata_63 = debug_all_rdata[63];
  assign io_debug_all_rdata_64 = debug_all_rdata[64];
  assign io_debug_all_rdata_65 = debug_all_rdata[65];
  assign io_debug_all_rdata_66 = debug_all_rdata[66];
  assign io_debug_all_rdata_67 = debug_all_rdata[67];
  assign io_debug_all_rdata_68 = debug_all_rdata[68];
  assign io_debug_all_rdata_69 = debug_all_rdata[69];
  assign io_debug_all_rdata_70 = debug_all_rdata[70];
  assign io_debug_all_rdata_71 = debug_all_rdata[71];
  assign io_debug_all_rdata_72 = debug_all_rdata[72];
  assign io_debug_all_rdata_73 = debug_all_rdata[73];
  assign io_debug_all_rdata_74 = debug_all_rdata[74];
  assign io_debug_all_rdata_75 = debug_all_rdata[75];
  assign io_debug_all_rdata_76 = debug_all_rdata[76];
  assign io_debug_all_rdata_77 = debug_all_rdata[77];
  assign io_debug_all_rdata_78 = debug_all_rdata[78];
  assign io_debug_all_rdata_79 = debug_all_rdata[79];
  assign io_debug_all_rdata_80 = debug_all_rdata[80];
  assign io_debug_all_rdata_81 = debug_all_rdata[81];
  assign io_debug_all_rdata_82 = debug_all_rdata[82];
  assign io_debug_all_rdata_83 = debug_all_rdata[83];
  assign io_debug_all_rdata_84 = debug_all_rdata[84];
  assign io_debug_all_rdata_85 = debug_all_rdata[85];
  assign io_debug_all_rdata_86 = debug_all_rdata[86];
  assign io_debug_all_rdata_87 = debug_all_rdata[87];
  assign io_debug_all_rdata_88 = debug_all_rdata[88];
  assign io_debug_all_rdata_89 = debug_all_rdata[89];
  assign io_debug_all_rdata_90 = debug_all_rdata[90];
  assign io_debug_all_rdata_91 = debug_all_rdata[91];
  assign io_debug_all_rdata_92 = debug_all_rdata[92];
  assign io_debug_all_rdata_93 = debug_all_rdata[93];
  assign io_debug_all_rdata_94 = debug_all_rdata[94];
  assign io_debug_all_rdata_95 = debug_all_rdata[95];
  assign io_debug_all_rdata_96 = debug_all_rdata[96];
  assign io_debug_all_rdata_97 = debug_all_rdata[97];
  assign io_debug_all_rdata_98 = debug_all_rdata[98];
  assign io_debug_all_rdata_99 = debug_all_rdata[99];
  assign io_debug_all_rdata_100 = debug_all_rdata[100];
  assign io_debug_all_rdata_101 = debug_all_rdata[101];
  assign io_debug_all_rdata_102 = debug_all_rdata[102];
  assign io_debug_all_rdata_103 = debug_all_rdata[103];
  assign io_debug_all_rdata_104 = debug_all_rdata[104];
  assign io_debug_all_rdata_105 = debug_all_rdata[105];
  assign io_debug_all_rdata_106 = debug_all_rdata[106];
  assign io_debug_all_rdata_107 = debug_all_rdata[107];
  assign io_debug_all_rdata_108 = debug_all_rdata[108];
  assign io_debug_all_rdata_109 = debug_all_rdata[109];
  assign io_debug_all_rdata_110 = debug_all_rdata[110];
  assign io_debug_all_rdata_111 = debug_all_rdata[111];
  assign io_debug_all_rdata_112 = debug_all_rdata[112];
  assign io_debug_all_rdata_113 = debug_all_rdata[113];
  assign io_debug_all_rdata_114 = debug_all_rdata[114];
  assign io_debug_all_rdata_115 = debug_all_rdata[115];
  assign io_debug_all_rdata_116 = debug_all_rdata[116];
  assign io_debug_all_rdata_117 = debug_all_rdata[117];
  assign io_debug_all_rdata_118 = debug_all_rdata[118];
  assign io_debug_all_rdata_119 = debug_all_rdata[119];
  assign io_debug_all_rdata_120 = debug_all_rdata[120];
  assign io_debug_all_rdata_121 = debug_all_rdata[121];
  assign io_debug_all_rdata_122 = debug_all_rdata[122];
  assign io_debug_all_rdata_123 = debug_all_rdata[123];
  assign io_debug_all_rdata_124 = debug_all_rdata[124];
  assign io_debug_all_rdata_125 = debug_all_rdata[125];
  assign io_debug_all_rdata_126 = debug_all_rdata[126];
  assign io_debug_all_rdata_127 = debug_all_rdata[127];
  assign io_debug_all_rdata_128 = debug_all_rdata[128];
  assign io_debug_all_rdata_129 = debug_all_rdata[129];
  assign io_debug_all_rdata_130 = debug_all_rdata[130];
  assign io_debug_all_rdata_131 = debug_all_rdata[131];
  assign io_debug_all_rdata_132 = debug_all_rdata[132];
  assign io_debug_all_rdata_133 = debug_all_rdata[133];
  assign io_debug_all_rdata_134 = debug_all_rdata[134];
  assign io_debug_all_rdata_135 = debug_all_rdata[135];
  assign io_debug_all_rdata_136 = debug_all_rdata[136];
  assign io_debug_all_rdata_137 = debug_all_rdata[137];
  assign io_debug_all_rdata_138 = debug_all_rdata[138];
  assign io_debug_all_rdata_139 = debug_all_rdata[139];
  assign io_debug_all_rdata_140 = debug_all_rdata[140];
  assign io_debug_all_rdata_141 = debug_all_rdata[141];
  assign io_debug_all_rdata_142 = debug_all_rdata[142];
  assign io_debug_all_rdata_143 = debug_all_rdata[143];
  assign io_debug_all_rdata_144 = debug_all_rdata[144];
  assign io_debug_all_rdata_145 = debug_all_rdata[145];
  assign io_debug_all_rdata_146 = debug_all_rdata[146];
  assign io_debug_all_rdata_147 = debug_all_rdata[147];
  assign io_debug_all_rdata_148 = debug_all_rdata[148];
  assign io_debug_all_rdata_149 = debug_all_rdata[149];
  assign io_debug_all_rdata_150 = debug_all_rdata[150];
  assign io_debug_all_rdata_151 = debug_all_rdata[151];
  assign io_debug_all_rdata_152 = debug_all_rdata[152];
  assign io_debug_all_rdata_153 = debug_all_rdata[153];
  assign io_debug_all_rdata_154 = debug_all_rdata[154];
  assign io_debug_all_rdata_155 = debug_all_rdata[155];
  assign io_debug_all_rdata_156 = debug_all_rdata[156];
  assign io_debug_all_rdata_157 = debug_all_rdata[157];
  assign io_debug_all_rdata_158 = debug_all_rdata[158];
  assign io_debug_all_rdata_159 = debug_all_rdata[159];
  assign io_debug_all_rdata_160 = debug_all_rdata[160];
  assign io_debug_all_rdata_161 = debug_all_rdata[161];
  assign io_debug_all_rdata_162 = debug_all_rdata[162];
  assign io_debug_all_rdata_163 = debug_all_rdata[163];
  assign io_debug_all_rdata_164 = debug_all_rdata[164];
  assign io_debug_all_rdata_165 = debug_all_rdata[165];
  assign io_debug_all_rdata_166 = debug_all_rdata[166];
  assign io_debug_all_rdata_167 = debug_all_rdata[167];
  assign io_debug_all_rdata_168 = debug_all_rdata[168];
  assign io_debug_all_rdata_169 = debug_all_rdata[169];
  assign io_debug_all_rdata_170 = debug_all_rdata[170];
  assign io_debug_all_rdata_171 = debug_all_rdata[171];
  assign io_debug_all_rdata_172 = debug_all_rdata[172];
  assign io_debug_all_rdata_173 = debug_all_rdata[173];
  assign io_debug_all_rdata_174 = debug_all_rdata[174];
  assign io_debug_all_rdata_175 = debug_all_rdata[175];
  assign io_debug_all_rdata_176 = debug_all_rdata[176];
  assign io_debug_all_rdata_177 = debug_all_rdata[177];
  assign io_debug_all_rdata_178 = debug_all_rdata[178];
  assign io_debug_all_rdata_179 = debug_all_rdata[179];
  assign io_debug_all_rdata_180 = debug_all_rdata[180];
  assign io_debug_all_rdata_181 = debug_all_rdata[181];
  assign io_debug_all_rdata_182 = debug_all_rdata[182];
  assign io_debug_all_rdata_183 = debug_all_rdata[183];
  assign io_debug_all_rdata_184 = debug_all_rdata[184];
  assign io_debug_all_rdata_185 = debug_all_rdata[185];
  assign io_debug_all_rdata_186 = debug_all_rdata[186];
  assign io_debug_all_rdata_187 = debug_all_rdata[187];
  assign io_debug_all_rdata_188 = debug_all_rdata[188];
  assign io_debug_all_rdata_189 = debug_all_rdata[189];
  assign io_debug_all_rdata_190 = debug_all_rdata[190];
  assign io_debug_all_rdata_191 = debug_all_rdata[191];
  assign io_debug_all_rdata_192 = debug_all_rdata[192];
  assign io_debug_all_rdata_193 = debug_all_rdata[193];
  assign io_debug_all_rdata_194 = debug_all_rdata[194];
  assign io_debug_all_rdata_195 = debug_all_rdata[195];
  assign io_debug_all_rdata_196 = debug_all_rdata[196];
  assign io_debug_all_rdata_197 = debug_all_rdata[197];
  assign io_debug_all_rdata_198 = debug_all_rdata[198];
  assign io_debug_all_rdata_199 = debug_all_rdata[199];
  assign io_debug_all_rdata_200 = debug_all_rdata[200];
  assign io_debug_all_rdata_201 = debug_all_rdata[201];
  assign io_debug_all_rdata_202 = debug_all_rdata[202];
  assign io_debug_all_rdata_203 = debug_all_rdata[203];
  assign io_debug_all_rdata_204 = debug_all_rdata[204];
  assign io_debug_all_rdata_205 = debug_all_rdata[205];
  assign io_debug_all_rdata_206 = debug_all_rdata[206];
  assign io_debug_all_rdata_207 = debug_all_rdata[207];
  assign io_debug_all_rdata_208 = debug_all_rdata[208];
  assign io_debug_all_rdata_209 = debug_all_rdata[209];
  assign io_debug_all_rdata_210 = debug_all_rdata[210];
  assign io_debug_all_rdata_211 = debug_all_rdata[211];
  assign io_debug_all_rdata_212 = debug_all_rdata[212];
  assign io_debug_all_rdata_213 = debug_all_rdata[213];
  assign io_debug_all_rdata_214 = debug_all_rdata[214];
  assign io_debug_all_rdata_215 = debug_all_rdata[215];
  assign io_debug_all_rdata_216 = debug_all_rdata[216];
  assign io_debug_all_rdata_217 = debug_all_rdata[217];
  assign io_debug_all_rdata_218 = debug_all_rdata[218];
  assign io_debug_all_rdata_219 = debug_all_rdata[219];
  assign io_debug_all_rdata_220 = debug_all_rdata[220];
  assign io_debug_all_rdata_221 = debug_all_rdata[221];
  assign io_debug_all_rdata_222 = debug_all_rdata[222];
  assign io_debug_all_rdata_223 = debug_all_rdata[223];
endmodule
