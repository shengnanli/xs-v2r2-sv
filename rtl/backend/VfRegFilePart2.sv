// VfRegFilePart2.sv —— VfRegFile 物理寄存器堆的一片：xs_Regfile_core 的薄 wrapper（参数 + 端口展平）
// =============================================================================
// 参数（golden 实测，由 scripts/gen_datapath_rf.py 解析并断言）：128 项 × 32 位，
//   12 个同步读口、6 个写口、地址 7 位（读视图 128 行，越界读 0 号项）；
//   debug 组合读口 0 个；debug 全量读出 有；0 号项不复位。
//   VfRegFilePart0..N 在 golden 里逐字相同（仅模块名不同），片号只决定上层接哪几位数据。
// 机制（Mux1H 按位或写、地址打一拍的同步读、越界填 0 号项）见核体 rtl/backend/xs_Regfile_core.sv。
// golden 对照：G1-canonical/golden-rtl/VfRegFilePart2.sv。本文件由 scripts/gen_datapath_rf.py 生成，勿手改。
// =============================================================================
module VfRegFilePart2(
  input          clock,
  input          reset,
  input  [6:0]   io_readPorts_0_addr,
  output [31:0]  io_readPorts_0_data,
  input  [6:0]   io_readPorts_1_addr,
  output [31:0]  io_readPorts_1_data,
  input  [6:0]   io_readPorts_2_addr,
  output [31:0]  io_readPorts_2_data,
  input  [6:0]   io_readPorts_3_addr,
  output [31:0]  io_readPorts_3_data,
  input  [6:0]   io_readPorts_4_addr,
  output [31:0]  io_readPorts_4_data,
  input  [6:0]   io_readPorts_5_addr,
  output [31:0]  io_readPorts_5_data,
  input  [6:0]   io_readPorts_6_addr,
  output [31:0]  io_readPorts_6_data,
  input  [6:0]   io_readPorts_7_addr,
  output [31:0]  io_readPorts_7_data,
  input  [6:0]   io_readPorts_8_addr,
  output [31:0]  io_readPorts_8_data,
  input  [6:0]   io_readPorts_9_addr,
  output [31:0]  io_readPorts_9_data,
  input  [6:0]   io_readPorts_10_addr,
  output [31:0]  io_readPorts_10_data,
  input  [6:0]   io_readPorts_11_addr,
  output [31:0]  io_readPorts_11_data,
  input          io_writePorts_0_wen,
  input  [6:0]   io_writePorts_0_addr,
  input  [31:0]  io_writePorts_0_data,
  input          io_writePorts_1_wen,
  input  [6:0]   io_writePorts_1_addr,
  input  [31:0]  io_writePorts_1_data,
  input          io_writePorts_2_wen,
  input  [6:0]   io_writePorts_2_addr,
  input  [31:0]  io_writePorts_2_data,
  input          io_writePorts_3_wen,
  input  [6:0]   io_writePorts_3_addr,
  input  [31:0]  io_writePorts_3_data,
  input          io_writePorts_4_wen,
  input  [6:0]   io_writePorts_4_addr,
  input  [31:0]  io_writePorts_4_data,
  input          io_writePorts_5_wen,
  input  [6:0]   io_writePorts_5_addr,
  input  [31:0]  io_writePorts_5_data,
  output [31:0]  io_debug_all_rdata_0,
  output [31:0]  io_debug_all_rdata_1,
  output [31:0]  io_debug_all_rdata_2,
  output [31:0]  io_debug_all_rdata_3,
  output [31:0]  io_debug_all_rdata_4,
  output [31:0]  io_debug_all_rdata_5,
  output [31:0]  io_debug_all_rdata_6,
  output [31:0]  io_debug_all_rdata_7,
  output [31:0]  io_debug_all_rdata_8,
  output [31:0]  io_debug_all_rdata_9,
  output [31:0]  io_debug_all_rdata_10,
  output [31:0]  io_debug_all_rdata_11,
  output [31:0]  io_debug_all_rdata_12,
  output [31:0]  io_debug_all_rdata_13,
  output [31:0]  io_debug_all_rdata_14,
  output [31:0]  io_debug_all_rdata_15,
  output [31:0]  io_debug_all_rdata_16,
  output [31:0]  io_debug_all_rdata_17,
  output [31:0]  io_debug_all_rdata_18,
  output [31:0]  io_debug_all_rdata_19,
  output [31:0]  io_debug_all_rdata_20,
  output [31:0]  io_debug_all_rdata_21,
  output [31:0]  io_debug_all_rdata_22,
  output [31:0]  io_debug_all_rdata_23,
  output [31:0]  io_debug_all_rdata_24,
  output [31:0]  io_debug_all_rdata_25,
  output [31:0]  io_debug_all_rdata_26,
  output [31:0]  io_debug_all_rdata_27,
  output [31:0]  io_debug_all_rdata_28,
  output [31:0]  io_debug_all_rdata_29,
  output [31:0]  io_debug_all_rdata_30,
  output [31:0]  io_debug_all_rdata_31,
  output [31:0]  io_debug_all_rdata_32,
  output [31:0]  io_debug_all_rdata_33,
  output [31:0]  io_debug_all_rdata_34,
  output [31:0]  io_debug_all_rdata_35,
  output [31:0]  io_debug_all_rdata_36,
  output [31:0]  io_debug_all_rdata_37,
  output [31:0]  io_debug_all_rdata_38,
  output [31:0]  io_debug_all_rdata_39,
  output [31:0]  io_debug_all_rdata_40,
  output [31:0]  io_debug_all_rdata_41,
  output [31:0]  io_debug_all_rdata_42,
  output [31:0]  io_debug_all_rdata_43,
  output [31:0]  io_debug_all_rdata_44,
  output [31:0]  io_debug_all_rdata_45,
  output [31:0]  io_debug_all_rdata_46,
  output [31:0]  io_debug_all_rdata_47,
  output [31:0]  io_debug_all_rdata_48,
  output [31:0]  io_debug_all_rdata_49,
  output [31:0]  io_debug_all_rdata_50,
  output [31:0]  io_debug_all_rdata_51,
  output [31:0]  io_debug_all_rdata_52,
  output [31:0]  io_debug_all_rdata_53,
  output [31:0]  io_debug_all_rdata_54,
  output [31:0]  io_debug_all_rdata_55,
  output [31:0]  io_debug_all_rdata_56,
  output [31:0]  io_debug_all_rdata_57,
  output [31:0]  io_debug_all_rdata_58,
  output [31:0]  io_debug_all_rdata_59,
  output [31:0]  io_debug_all_rdata_60,
  output [31:0]  io_debug_all_rdata_61,
  output [31:0]  io_debug_all_rdata_62,
  output [31:0]  io_debug_all_rdata_63,
  output [31:0]  io_debug_all_rdata_64,
  output [31:0]  io_debug_all_rdata_65,
  output [31:0]  io_debug_all_rdata_66,
  output [31:0]  io_debug_all_rdata_67,
  output [31:0]  io_debug_all_rdata_68,
  output [31:0]  io_debug_all_rdata_69,
  output [31:0]  io_debug_all_rdata_70,
  output [31:0]  io_debug_all_rdata_71,
  output [31:0]  io_debug_all_rdata_72,
  output [31:0]  io_debug_all_rdata_73,
  output [31:0]  io_debug_all_rdata_74,
  output [31:0]  io_debug_all_rdata_75,
  output [31:0]  io_debug_all_rdata_76,
  output [31:0]  io_debug_all_rdata_77,
  output [31:0]  io_debug_all_rdata_78,
  output [31:0]  io_debug_all_rdata_79,
  output [31:0]  io_debug_all_rdata_80,
  output [31:0]  io_debug_all_rdata_81,
  output [31:0]  io_debug_all_rdata_82,
  output [31:0]  io_debug_all_rdata_83,
  output [31:0]  io_debug_all_rdata_84,
  output [31:0]  io_debug_all_rdata_85,
  output [31:0]  io_debug_all_rdata_86,
  output [31:0]  io_debug_all_rdata_87,
  output [31:0]  io_debug_all_rdata_88,
  output [31:0]  io_debug_all_rdata_89,
  output [31:0]  io_debug_all_rdata_90,
  output [31:0]  io_debug_all_rdata_91,
  output [31:0]  io_debug_all_rdata_92,
  output [31:0]  io_debug_all_rdata_93,
  output [31:0]  io_debug_all_rdata_94,
  output [31:0]  io_debug_all_rdata_95,
  output [31:0]  io_debug_all_rdata_96,
  output [31:0]  io_debug_all_rdata_97,
  output [31:0]  io_debug_all_rdata_98,
  output [31:0]  io_debug_all_rdata_99,
  output [31:0]  io_debug_all_rdata_100,
  output [31:0]  io_debug_all_rdata_101,
  output [31:0]  io_debug_all_rdata_102,
  output [31:0]  io_debug_all_rdata_103,
  output [31:0]  io_debug_all_rdata_104,
  output [31:0]  io_debug_all_rdata_105,
  output [31:0]  io_debug_all_rdata_106,
  output [31:0]  io_debug_all_rdata_107,
  output [31:0]  io_debug_all_rdata_108,
  output [31:0]  io_debug_all_rdata_109,
  output [31:0]  io_debug_all_rdata_110,
  output [31:0]  io_debug_all_rdata_111,
  output [31:0]  io_debug_all_rdata_112,
  output [31:0]  io_debug_all_rdata_113,
  output [31:0]  io_debug_all_rdata_114,
  output [31:0]  io_debug_all_rdata_115,
  output [31:0]  io_debug_all_rdata_116,
  output [31:0]  io_debug_all_rdata_117,
  output [31:0]  io_debug_all_rdata_118,
  output [31:0]  io_debug_all_rdata_119,
  output [31:0]  io_debug_all_rdata_120,
  output [31:0]  io_debug_all_rdata_121,
  output [31:0]  io_debug_all_rdata_122,
  output [31:0]  io_debug_all_rdata_123,
  output [31:0]  io_debug_all_rdata_124,
  output [31:0]  io_debug_all_rdata_125,
  output [31:0]  io_debug_all_rdata_126,
  output [31:0]  io_debug_all_rdata_127
);
  localparam int unsigned NUM_PREGS = 128;
  localparam int unsigned NUM_READ  = 12;
  localparam int unsigned NUM_WRITE = 6;
  localparam int unsigned DATA_W    = 32;
  localparam int unsigned ADDR_W    = 7;

  logic [NUM_READ-1:0][ADDR_W-1:0]  read_addr;
  logic [NUM_READ-1:0][DATA_W-1:0]  read_data;
  logic [NUM_WRITE-1:0]             write_wen;
  logic [NUM_WRITE-1:0][ADDR_W-1:0] write_addr;
  logic [NUM_WRITE-1:0][DATA_W-1:0] write_data;
  logic [0:0][ADDR_W-1:0]         debug_read_addr;
  logic [0:0][DATA_W-1:0]         debug_read_data;
  logic [NUM_PREGS-1:0][DATA_W-1:0] debug_all_rdata;

  xs_Regfile_core #(
    .NUM_PREGS      (NUM_PREGS),
    .NUM_READ       (NUM_READ),
    .NUM_WRITE      (NUM_WRITE),
    .DATA_W         (DATA_W),
    .ADDR_W         (ADDR_W),
    .NUM_DEBUG_READ (0),
    .MEM0_RESET     (1'b0)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .read_addr       (read_addr),
    .read_data       (read_data),
    .write_wen       (write_wen),
    .write_addr      (write_addr),
    .write_data      (write_data),
    .debug_read_addr (debug_read_addr),
    .debug_read_data (debug_read_data),
    .debug_all_rdata (debug_all_rdata)
  );

  // 读口
  assign read_addr[0] = io_readPorts_0_addr;
  assign io_readPorts_0_data = read_data[0];
  assign read_addr[1] = io_readPorts_1_addr;
  assign io_readPorts_1_data = read_data[1];
  assign read_addr[2] = io_readPorts_2_addr;
  assign io_readPorts_2_data = read_data[2];
  assign read_addr[3] = io_readPorts_3_addr;
  assign io_readPorts_3_data = read_data[3];
  assign read_addr[4] = io_readPorts_4_addr;
  assign io_readPorts_4_data = read_data[4];
  assign read_addr[5] = io_readPorts_5_addr;
  assign io_readPorts_5_data = read_data[5];
  assign read_addr[6] = io_readPorts_6_addr;
  assign io_readPorts_6_data = read_data[6];
  assign read_addr[7] = io_readPorts_7_addr;
  assign io_readPorts_7_data = read_data[7];
  assign read_addr[8] = io_readPorts_8_addr;
  assign io_readPorts_8_data = read_data[8];
  assign read_addr[9] = io_readPorts_9_addr;
  assign io_readPorts_9_data = read_data[9];
  assign read_addr[10] = io_readPorts_10_addr;
  assign io_readPorts_10_data = read_data[10];
  assign read_addr[11] = io_readPorts_11_addr;
  assign io_readPorts_11_data = read_data[11];
  // 写口
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
  // debug
  assign debug_read_addr = '0;  // 本变体没有 debug 组合读口
  assign io_debug_all_rdata_0 = debug_all_rdata[0];
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
endmodule
