// 自动生成：scripts/gen_renametablewrapper.py —— 勿手改（make gencheck 校验）
// RenameTableWrapper UT：golden（含 golden DiffRatStateBuffer 与两个存储叶子）vs RenameTableWrapper_xs
// （含 DiffRatStateBuffer_xs 与叶子 _xs），五张 RenameTable 两侧都例化本仓已签核的可读件。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cyc = 0;
  int cov_commit = 0, cov_walk = 0, cov_rn = 0, cov_diffrd = 0, cov_snpt = 0;
  always #5 clk = ~clk;
  always @(negedge clk) if (!rst) cyc <= cyc + 1;
  // ★暖机窗口★：RenameTable 的 4 个快照槽 payload 无复位（见 verif/ut/StdFreeList/tb.sv 的同一条定式），
  // 复位一撤先 snptEnq 连续 8 拍把槽写满、useSnpt 恒 0，之后才允许随机读快照。
  localparam int WARM = 8;
  logic [7:0] io_hartId;
  logic io_redirect;
  logic io_rabCommits_isCommit;
  logic io_rabCommits_commitValid_0;
  logic io_rabCommits_commitValid_1;
  logic io_rabCommits_commitValid_2;
  logic io_rabCommits_commitValid_3;
  logic io_rabCommits_commitValid_4;
  logic io_rabCommits_commitValid_5;
  logic io_rabCommits_isWalk;
  logic io_rabCommits_walkValid_0;
  logic io_rabCommits_walkValid_1;
  logic io_rabCommits_walkValid_2;
  logic io_rabCommits_walkValid_3;
  logic io_rabCommits_walkValid_4;
  logic io_rabCommits_walkValid_5;
  logic [5:0] io_rabCommits_info_0_ldest;
  logic [7:0] io_rabCommits_info_0_pdest;
  logic io_rabCommits_info_0_rfWen;
  logic io_rabCommits_info_0_fpWen;
  logic io_rabCommits_info_0_vecWen;
  logic io_rabCommits_info_0_v0Wen;
  logic io_rabCommits_info_0_vlWen;
  logic [5:0] io_rabCommits_info_1_ldest;
  logic [7:0] io_rabCommits_info_1_pdest;
  logic io_rabCommits_info_1_rfWen;
  logic io_rabCommits_info_1_fpWen;
  logic io_rabCommits_info_1_vecWen;
  logic io_rabCommits_info_1_v0Wen;
  logic io_rabCommits_info_1_vlWen;
  logic [5:0] io_rabCommits_info_2_ldest;
  logic [7:0] io_rabCommits_info_2_pdest;
  logic io_rabCommits_info_2_rfWen;
  logic io_rabCommits_info_2_fpWen;
  logic io_rabCommits_info_2_vecWen;
  logic io_rabCommits_info_2_v0Wen;
  logic io_rabCommits_info_2_vlWen;
  logic [5:0] io_rabCommits_info_3_ldest;
  logic [7:0] io_rabCommits_info_3_pdest;
  logic io_rabCommits_info_3_rfWen;
  logic io_rabCommits_info_3_fpWen;
  logic io_rabCommits_info_3_vecWen;
  logic io_rabCommits_info_3_v0Wen;
  logic io_rabCommits_info_3_vlWen;
  logic [5:0] io_rabCommits_info_4_ldest;
  logic [7:0] io_rabCommits_info_4_pdest;
  logic io_rabCommits_info_4_rfWen;
  logic io_rabCommits_info_4_fpWen;
  logic io_rabCommits_info_4_vecWen;
  logic io_rabCommits_info_4_v0Wen;
  logic io_rabCommits_info_4_vlWen;
  logic [5:0] io_rabCommits_info_5_ldest;
  logic [7:0] io_rabCommits_info_5_pdest;
  logic io_rabCommits_info_5_rfWen;
  logic io_rabCommits_info_5_fpWen;
  logic io_rabCommits_info_5_vecWen;
  logic io_rabCommits_info_5_v0Wen;
  logic io_rabCommits_info_5_vlWen;
  logic io_renameUpdates_0_valid;
  logic io_renameUpdates_0_bits_robIdx_flag;
  logic [7:0] io_renameUpdates_0_bits_robIdx_value;
  logic io_renameUpdates_0_bits_lastUop;
  logic [5:0] io_renameUpdates_0_bits_ldest;
  logic [7:0] io_renameUpdates_0_bits_pdest;
  logic io_renameUpdates_0_bits_rfWen;
  logic io_renameUpdates_0_bits_fpWen;
  logic io_renameUpdates_0_bits_vecWen;
  logic io_renameUpdates_0_bits_v0Wen;
  logic io_renameUpdates_0_bits_vlWen;
  logic io_renameUpdates_1_valid;
  logic io_renameUpdates_1_bits_robIdx_flag;
  logic [7:0] io_renameUpdates_1_bits_robIdx_value;
  logic io_renameUpdates_1_bits_lastUop;
  logic [5:0] io_renameUpdates_1_bits_ldest;
  logic [7:0] io_renameUpdates_1_bits_pdest;
  logic io_renameUpdates_1_bits_rfWen;
  logic io_renameUpdates_1_bits_fpWen;
  logic io_renameUpdates_1_bits_vecWen;
  logic io_renameUpdates_1_bits_v0Wen;
  logic io_renameUpdates_1_bits_vlWen;
  logic io_renameUpdates_2_valid;
  logic io_renameUpdates_2_bits_robIdx_flag;
  logic [7:0] io_renameUpdates_2_bits_robIdx_value;
  logic io_renameUpdates_2_bits_lastUop;
  logic [5:0] io_renameUpdates_2_bits_ldest;
  logic [7:0] io_renameUpdates_2_bits_pdest;
  logic io_renameUpdates_2_bits_rfWen;
  logic io_renameUpdates_2_bits_fpWen;
  logic io_renameUpdates_2_bits_vecWen;
  logic io_renameUpdates_2_bits_v0Wen;
  logic io_renameUpdates_2_bits_vlWen;
  logic io_renameUpdates_3_valid;
  logic io_renameUpdates_3_bits_robIdx_flag;
  logic [7:0] io_renameUpdates_3_bits_robIdx_value;
  logic io_renameUpdates_3_bits_lastUop;
  logic [5:0] io_renameUpdates_3_bits_ldest;
  logic [7:0] io_renameUpdates_3_bits_pdest;
  logic io_renameUpdates_3_bits_rfWen;
  logic io_renameUpdates_3_bits_fpWen;
  logic io_renameUpdates_3_bits_vecWen;
  logic io_renameUpdates_3_bits_v0Wen;
  logic io_renameUpdates_3_bits_vlWen;
  logic io_renameUpdates_4_valid;
  logic io_renameUpdates_4_bits_robIdx_flag;
  logic [7:0] io_renameUpdates_4_bits_robIdx_value;
  logic io_renameUpdates_4_bits_lastUop;
  logic [5:0] io_renameUpdates_4_bits_ldest;
  logic [7:0] io_renameUpdates_4_bits_pdest;
  logic io_renameUpdates_4_bits_rfWen;
  logic io_renameUpdates_4_bits_fpWen;
  logic io_renameUpdates_4_bits_vecWen;
  logic io_renameUpdates_4_bits_v0Wen;
  logic io_renameUpdates_4_bits_vlWen;
  logic io_renameUpdates_5_valid;
  logic io_renameUpdates_5_bits_robIdx_flag;
  logic [7:0] io_renameUpdates_5_bits_robIdx_value;
  logic io_renameUpdates_5_bits_lastUop;
  logic [5:0] io_renameUpdates_5_bits_ldest;
  logic [7:0] io_renameUpdates_5_bits_pdest;
  logic io_renameUpdates_5_bits_rfWen;
  logic io_renameUpdates_5_bits_fpWen;
  logic io_renameUpdates_5_bits_vecWen;
  logic io_renameUpdates_5_bits_v0Wen;
  logic io_renameUpdates_5_bits_vlWen;
  logic io_diffRatCommitRobIdx_valid;
  logic io_diffRatCommitRobIdx_bits_flag;
  logic [7:0] io_diffRatCommitRobIdx_bits_value;
  logic io_intReadPorts_0_0_hold;
  logic [31:0] io_intReadPorts_0_0_addr;
  logic io_intReadPorts_0_1_hold;
  logic [31:0] io_intReadPorts_0_1_addr;
  logic io_intReadPorts_1_0_hold;
  logic [31:0] io_intReadPorts_1_0_addr;
  logic io_intReadPorts_1_1_hold;
  logic [31:0] io_intReadPorts_1_1_addr;
  logic io_intReadPorts_2_0_hold;
  logic [31:0] io_intReadPorts_2_0_addr;
  logic io_intReadPorts_2_1_hold;
  logic [31:0] io_intReadPorts_2_1_addr;
  logic io_intReadPorts_3_0_hold;
  logic [31:0] io_intReadPorts_3_0_addr;
  logic io_intReadPorts_3_1_hold;
  logic [31:0] io_intReadPorts_3_1_addr;
  logic io_intReadPorts_4_0_hold;
  logic [31:0] io_intReadPorts_4_0_addr;
  logic io_intReadPorts_4_1_hold;
  logic [31:0] io_intReadPorts_4_1_addr;
  logic io_intReadPorts_5_0_hold;
  logic [31:0] io_intReadPorts_5_0_addr;
  logic io_intReadPorts_5_1_hold;
  logic [31:0] io_intReadPorts_5_1_addr;
  logic io_intRenamePorts_0_wen;
  logic [31:0] io_intRenamePorts_0_addr;
  logic [7:0] io_intRenamePorts_0_data;
  logic io_intRenamePorts_1_wen;
  logic [31:0] io_intRenamePorts_1_addr;
  logic [7:0] io_intRenamePorts_1_data;
  logic io_intRenamePorts_2_wen;
  logic [31:0] io_intRenamePorts_2_addr;
  logic [7:0] io_intRenamePorts_2_data;
  logic io_intRenamePorts_3_wen;
  logic [31:0] io_intRenamePorts_3_addr;
  logic [7:0] io_intRenamePorts_3_data;
  logic io_intRenamePorts_4_wen;
  logic [31:0] io_intRenamePorts_4_addr;
  logic [7:0] io_intRenamePorts_4_data;
  logic io_intRenamePorts_5_wen;
  logic [31:0] io_intRenamePorts_5_addr;
  logic [7:0] io_intRenamePorts_5_data;
  logic io_fpReadPorts_0_0_hold;
  logic [33:0] io_fpReadPorts_0_0_addr;
  logic io_fpReadPorts_0_1_hold;
  logic [33:0] io_fpReadPorts_0_1_addr;
  logic io_fpReadPorts_0_2_hold;
  logic [33:0] io_fpReadPorts_0_2_addr;
  logic io_fpReadPorts_1_0_hold;
  logic [33:0] io_fpReadPorts_1_0_addr;
  logic io_fpReadPorts_1_1_hold;
  logic [33:0] io_fpReadPorts_1_1_addr;
  logic io_fpReadPorts_1_2_hold;
  logic [33:0] io_fpReadPorts_1_2_addr;
  logic io_fpReadPorts_2_0_hold;
  logic [33:0] io_fpReadPorts_2_0_addr;
  logic io_fpReadPorts_2_1_hold;
  logic [33:0] io_fpReadPorts_2_1_addr;
  logic io_fpReadPorts_2_2_hold;
  logic [33:0] io_fpReadPorts_2_2_addr;
  logic io_fpReadPorts_3_0_hold;
  logic [33:0] io_fpReadPorts_3_0_addr;
  logic io_fpReadPorts_3_1_hold;
  logic [33:0] io_fpReadPorts_3_1_addr;
  logic io_fpReadPorts_3_2_hold;
  logic [33:0] io_fpReadPorts_3_2_addr;
  logic io_fpReadPorts_4_0_hold;
  logic [33:0] io_fpReadPorts_4_0_addr;
  logic io_fpReadPorts_4_1_hold;
  logic [33:0] io_fpReadPorts_4_1_addr;
  logic io_fpReadPorts_4_2_hold;
  logic [33:0] io_fpReadPorts_4_2_addr;
  logic io_fpReadPorts_5_0_hold;
  logic [33:0] io_fpReadPorts_5_0_addr;
  logic io_fpReadPorts_5_1_hold;
  logic [33:0] io_fpReadPorts_5_1_addr;
  logic io_fpReadPorts_5_2_hold;
  logic [33:0] io_fpReadPorts_5_2_addr;
  logic io_fpRenamePorts_0_wen;
  logic [33:0] io_fpRenamePorts_0_addr;
  logic [7:0] io_fpRenamePorts_0_data;
  logic io_fpRenamePorts_1_wen;
  logic [33:0] io_fpRenamePorts_1_addr;
  logic [7:0] io_fpRenamePorts_1_data;
  logic io_fpRenamePorts_2_wen;
  logic [33:0] io_fpRenamePorts_2_addr;
  logic [7:0] io_fpRenamePorts_2_data;
  logic io_fpRenamePorts_3_wen;
  logic [33:0] io_fpRenamePorts_3_addr;
  logic [7:0] io_fpRenamePorts_3_data;
  logic io_fpRenamePorts_4_wen;
  logic [33:0] io_fpRenamePorts_4_addr;
  logic [7:0] io_fpRenamePorts_4_data;
  logic io_fpRenamePorts_5_wen;
  logic [33:0] io_fpRenamePorts_5_addr;
  logic [7:0] io_fpRenamePorts_5_data;
  logic io_vecReadPorts_0_0_hold;
  logic [46:0] io_vecReadPorts_0_0_addr;
  logic io_vecReadPorts_0_1_hold;
  logic [46:0] io_vecReadPorts_0_1_addr;
  logic io_vecReadPorts_0_2_hold;
  logic [46:0] io_vecReadPorts_0_2_addr;
  logic io_vecReadPorts_1_0_hold;
  logic [46:0] io_vecReadPorts_1_0_addr;
  logic io_vecReadPorts_1_1_hold;
  logic [46:0] io_vecReadPorts_1_1_addr;
  logic io_vecReadPorts_1_2_hold;
  logic [46:0] io_vecReadPorts_1_2_addr;
  logic io_vecReadPorts_2_0_hold;
  logic [46:0] io_vecReadPorts_2_0_addr;
  logic io_vecReadPorts_2_1_hold;
  logic [46:0] io_vecReadPorts_2_1_addr;
  logic io_vecReadPorts_2_2_hold;
  logic [46:0] io_vecReadPorts_2_2_addr;
  logic io_vecReadPorts_3_0_hold;
  logic [46:0] io_vecReadPorts_3_0_addr;
  logic io_vecReadPorts_3_1_hold;
  logic [46:0] io_vecReadPorts_3_1_addr;
  logic io_vecReadPorts_3_2_hold;
  logic [46:0] io_vecReadPorts_3_2_addr;
  logic io_vecReadPorts_4_0_hold;
  logic [46:0] io_vecReadPorts_4_0_addr;
  logic io_vecReadPorts_4_1_hold;
  logic [46:0] io_vecReadPorts_4_1_addr;
  logic io_vecReadPorts_4_2_hold;
  logic [46:0] io_vecReadPorts_4_2_addr;
  logic io_vecReadPorts_5_0_hold;
  logic [46:0] io_vecReadPorts_5_0_addr;
  logic io_vecReadPorts_5_1_hold;
  logic [46:0] io_vecReadPorts_5_1_addr;
  logic io_vecReadPorts_5_2_hold;
  logic [46:0] io_vecReadPorts_5_2_addr;
  logic io_vecRenamePorts_0_wen;
  logic [46:0] io_vecRenamePorts_0_addr;
  logic [7:0] io_vecRenamePorts_0_data;
  logic io_vecRenamePorts_1_wen;
  logic [46:0] io_vecRenamePorts_1_addr;
  logic [7:0] io_vecRenamePorts_1_data;
  logic io_vecRenamePorts_2_wen;
  logic [46:0] io_vecRenamePorts_2_addr;
  logic [7:0] io_vecRenamePorts_2_data;
  logic io_vecRenamePorts_3_wen;
  logic [46:0] io_vecRenamePorts_3_addr;
  logic [7:0] io_vecRenamePorts_3_data;
  logic io_vecRenamePorts_4_wen;
  logic [46:0] io_vecRenamePorts_4_addr;
  logic [7:0] io_vecRenamePorts_4_data;
  logic io_vecRenamePorts_5_wen;
  logic [46:0] io_vecRenamePorts_5_addr;
  logic [7:0] io_vecRenamePorts_5_data;
  logic io_v0ReadPorts_0_hold;
  logic io_v0ReadPorts_1_hold;
  logic io_v0ReadPorts_2_hold;
  logic io_v0ReadPorts_3_hold;
  logic io_v0ReadPorts_4_hold;
  logic io_v0ReadPorts_5_hold;
  logic io_v0RenamePorts_0_wen;
  logic [7:0] io_v0RenamePorts_0_data;
  logic io_v0RenamePorts_1_wen;
  logic [7:0] io_v0RenamePorts_1_data;
  logic io_v0RenamePorts_2_wen;
  logic [7:0] io_v0RenamePorts_2_data;
  logic io_v0RenamePorts_3_wen;
  logic [7:0] io_v0RenamePorts_3_data;
  logic io_v0RenamePorts_4_wen;
  logic [7:0] io_v0RenamePorts_4_data;
  logic io_v0RenamePorts_5_wen;
  logic [7:0] io_v0RenamePorts_5_data;
  logic io_vlReadPorts_0_hold;
  logic io_vlReadPorts_1_hold;
  logic io_vlReadPorts_2_hold;
  logic io_vlReadPorts_3_hold;
  logic io_vlReadPorts_4_hold;
  logic io_vlReadPorts_5_hold;
  logic io_vlRenamePorts_0_wen;
  logic [7:0] io_vlRenamePorts_0_data;
  logic io_vlRenamePorts_1_wen;
  logic [7:0] io_vlRenamePorts_1_data;
  logic io_vlRenamePorts_2_wen;
  logic [7:0] io_vlRenamePorts_2_data;
  logic io_vlRenamePorts_3_wen;
  logic [7:0] io_vlRenamePorts_3_data;
  logic io_vlRenamePorts_4_wen;
  logic [7:0] io_vlRenamePorts_4_data;
  logic io_vlRenamePorts_5_wen;
  logic [7:0] io_vlRenamePorts_5_data;
  logic io_snpt_snptEnq;
  logic io_snpt_snptDeq;
  logic io_snpt_useSnpt;
  logic [1:0] io_snpt_snptSelect;
  logic io_snpt_flushVec_0;
  logic io_snpt_flushVec_1;
  logic io_snpt_flushVec_2;
  logic io_snpt_flushVec_3;
  logic [7:0] g_io_intReadPorts_0_0_data, i_io_intReadPorts_0_0_data;
  logic [7:0] g_io_intReadPorts_0_1_data, i_io_intReadPorts_0_1_data;
  logic [7:0] g_io_intReadPorts_1_0_data, i_io_intReadPorts_1_0_data;
  logic [7:0] g_io_intReadPorts_1_1_data, i_io_intReadPorts_1_1_data;
  logic [7:0] g_io_intReadPorts_2_0_data, i_io_intReadPorts_2_0_data;
  logic [7:0] g_io_intReadPorts_2_1_data, i_io_intReadPorts_2_1_data;
  logic [7:0] g_io_intReadPorts_3_0_data, i_io_intReadPorts_3_0_data;
  logic [7:0] g_io_intReadPorts_3_1_data, i_io_intReadPorts_3_1_data;
  logic [7:0] g_io_intReadPorts_4_0_data, i_io_intReadPorts_4_0_data;
  logic [7:0] g_io_intReadPorts_4_1_data, i_io_intReadPorts_4_1_data;
  logic [7:0] g_io_intReadPorts_5_0_data, i_io_intReadPorts_5_0_data;
  logic [7:0] g_io_intReadPorts_5_1_data, i_io_intReadPorts_5_1_data;
  logic [7:0] g_io_fpReadPorts_0_0_data, i_io_fpReadPorts_0_0_data;
  logic [7:0] g_io_fpReadPorts_0_1_data, i_io_fpReadPorts_0_1_data;
  logic [7:0] g_io_fpReadPorts_0_2_data, i_io_fpReadPorts_0_2_data;
  logic [7:0] g_io_fpReadPorts_1_0_data, i_io_fpReadPorts_1_0_data;
  logic [7:0] g_io_fpReadPorts_1_1_data, i_io_fpReadPorts_1_1_data;
  logic [7:0] g_io_fpReadPorts_1_2_data, i_io_fpReadPorts_1_2_data;
  logic [7:0] g_io_fpReadPorts_2_0_data, i_io_fpReadPorts_2_0_data;
  logic [7:0] g_io_fpReadPorts_2_1_data, i_io_fpReadPorts_2_1_data;
  logic [7:0] g_io_fpReadPorts_2_2_data, i_io_fpReadPorts_2_2_data;
  logic [7:0] g_io_fpReadPorts_3_0_data, i_io_fpReadPorts_3_0_data;
  logic [7:0] g_io_fpReadPorts_3_1_data, i_io_fpReadPorts_3_1_data;
  logic [7:0] g_io_fpReadPorts_3_2_data, i_io_fpReadPorts_3_2_data;
  logic [7:0] g_io_fpReadPorts_4_0_data, i_io_fpReadPorts_4_0_data;
  logic [7:0] g_io_fpReadPorts_4_1_data, i_io_fpReadPorts_4_1_data;
  logic [7:0] g_io_fpReadPorts_4_2_data, i_io_fpReadPorts_4_2_data;
  logic [7:0] g_io_fpReadPorts_5_0_data, i_io_fpReadPorts_5_0_data;
  logic [7:0] g_io_fpReadPorts_5_1_data, i_io_fpReadPorts_5_1_data;
  logic [7:0] g_io_fpReadPorts_5_2_data, i_io_fpReadPorts_5_2_data;
  logic [7:0] g_io_vecReadPorts_0_0_data, i_io_vecReadPorts_0_0_data;
  logic [7:0] g_io_vecReadPorts_0_1_data, i_io_vecReadPorts_0_1_data;
  logic [7:0] g_io_vecReadPorts_0_2_data, i_io_vecReadPorts_0_2_data;
  logic [7:0] g_io_vecReadPorts_1_0_data, i_io_vecReadPorts_1_0_data;
  logic [7:0] g_io_vecReadPorts_1_1_data, i_io_vecReadPorts_1_1_data;
  logic [7:0] g_io_vecReadPorts_1_2_data, i_io_vecReadPorts_1_2_data;
  logic [7:0] g_io_vecReadPorts_2_0_data, i_io_vecReadPorts_2_0_data;
  logic [7:0] g_io_vecReadPorts_2_1_data, i_io_vecReadPorts_2_1_data;
  logic [7:0] g_io_vecReadPorts_2_2_data, i_io_vecReadPorts_2_2_data;
  logic [7:0] g_io_vecReadPorts_3_0_data, i_io_vecReadPorts_3_0_data;
  logic [7:0] g_io_vecReadPorts_3_1_data, i_io_vecReadPorts_3_1_data;
  logic [7:0] g_io_vecReadPorts_3_2_data, i_io_vecReadPorts_3_2_data;
  logic [7:0] g_io_vecReadPorts_4_0_data, i_io_vecReadPorts_4_0_data;
  logic [7:0] g_io_vecReadPorts_4_1_data, i_io_vecReadPorts_4_1_data;
  logic [7:0] g_io_vecReadPorts_4_2_data, i_io_vecReadPorts_4_2_data;
  logic [7:0] g_io_vecReadPorts_5_0_data, i_io_vecReadPorts_5_0_data;
  logic [7:0] g_io_vecReadPorts_5_1_data, i_io_vecReadPorts_5_1_data;
  logic [7:0] g_io_vecReadPorts_5_2_data, i_io_vecReadPorts_5_2_data;
  logic [7:0] g_io_v0ReadPorts_0_data, i_io_v0ReadPorts_0_data;
  logic [7:0] g_io_v0ReadPorts_1_data, i_io_v0ReadPorts_1_data;
  logic [7:0] g_io_v0ReadPorts_2_data, i_io_v0ReadPorts_2_data;
  logic [7:0] g_io_v0ReadPorts_3_data, i_io_v0ReadPorts_3_data;
  logic [7:0] g_io_v0ReadPorts_4_data, i_io_v0ReadPorts_4_data;
  logic [7:0] g_io_v0ReadPorts_5_data, i_io_v0ReadPorts_5_data;
  logic [7:0] g_io_vlReadPorts_0_data, i_io_vlReadPorts_0_data;
  logic [7:0] g_io_vlReadPorts_1_data, i_io_vlReadPorts_1_data;
  logic [7:0] g_io_vlReadPorts_2_data, i_io_vlReadPorts_2_data;
  logic [7:0] g_io_vlReadPorts_3_data, i_io_vlReadPorts_3_data;
  logic [7:0] g_io_vlReadPorts_4_data, i_io_vlReadPorts_4_data;
  logic [7:0] g_io_vlReadPorts_5_data, i_io_vlReadPorts_5_data;
  logic [7:0] g_io_int_old_pdest_0, i_io_int_old_pdest_0;
  logic [7:0] g_io_int_old_pdest_1, i_io_int_old_pdest_1;
  logic [7:0] g_io_int_old_pdest_2, i_io_int_old_pdest_2;
  logic [7:0] g_io_int_old_pdest_3, i_io_int_old_pdest_3;
  logic [7:0] g_io_int_old_pdest_4, i_io_int_old_pdest_4;
  logic [7:0] g_io_int_old_pdest_5, i_io_int_old_pdest_5;
  logic [7:0] g_io_fp_old_pdest_0, i_io_fp_old_pdest_0;
  logic [7:0] g_io_fp_old_pdest_1, i_io_fp_old_pdest_1;
  logic [7:0] g_io_fp_old_pdest_2, i_io_fp_old_pdest_2;
  logic [7:0] g_io_fp_old_pdest_3, i_io_fp_old_pdest_3;
  logic [7:0] g_io_fp_old_pdest_4, i_io_fp_old_pdest_4;
  logic [7:0] g_io_fp_old_pdest_5, i_io_fp_old_pdest_5;
  logic [7:0] g_io_vec_old_pdest_0, i_io_vec_old_pdest_0;
  logic [7:0] g_io_vec_old_pdest_1, i_io_vec_old_pdest_1;
  logic [7:0] g_io_vec_old_pdest_2, i_io_vec_old_pdest_2;
  logic [7:0] g_io_vec_old_pdest_3, i_io_vec_old_pdest_3;
  logic [7:0] g_io_vec_old_pdest_4, i_io_vec_old_pdest_4;
  logic [7:0] g_io_vec_old_pdest_5, i_io_vec_old_pdest_5;
  logic [7:0] g_io_v0_old_pdest_0, i_io_v0_old_pdest_0;
  logic [7:0] g_io_v0_old_pdest_1, i_io_v0_old_pdest_1;
  logic [7:0] g_io_v0_old_pdest_2, i_io_v0_old_pdest_2;
  logic [7:0] g_io_v0_old_pdest_3, i_io_v0_old_pdest_3;
  logic [7:0] g_io_v0_old_pdest_4, i_io_v0_old_pdest_4;
  logic [7:0] g_io_v0_old_pdest_5, i_io_v0_old_pdest_5;
  logic [7:0] g_io_vl_old_pdest_0, i_io_vl_old_pdest_0;
  logic [7:0] g_io_vl_old_pdest_1, i_io_vl_old_pdest_1;
  logic [7:0] g_io_vl_old_pdest_2, i_io_vl_old_pdest_2;
  logic [7:0] g_io_vl_old_pdest_3, i_io_vl_old_pdest_3;
  logic [7:0] g_io_vl_old_pdest_4, i_io_vl_old_pdest_4;
  logic [7:0] g_io_vl_old_pdest_5, i_io_vl_old_pdest_5;
  logic g_io_int_need_free_0, i_io_int_need_free_0;
  logic g_io_int_need_free_1, i_io_int_need_free_1;
  logic g_io_int_need_free_2, i_io_int_need_free_2;
  logic g_io_int_need_free_3, i_io_int_need_free_3;
  logic g_io_int_need_free_4, i_io_int_need_free_4;
  logic g_io_int_need_free_5, i_io_int_need_free_5;
  logic [7:0] g_io_debug_int_rat_0, i_io_debug_int_rat_0;
  logic [7:0] g_io_debug_int_rat_1, i_io_debug_int_rat_1;
  logic [7:0] g_io_debug_int_rat_2, i_io_debug_int_rat_2;
  logic [7:0] g_io_debug_int_rat_3, i_io_debug_int_rat_3;
  logic [7:0] g_io_debug_int_rat_4, i_io_debug_int_rat_4;
  logic [7:0] g_io_debug_int_rat_5, i_io_debug_int_rat_5;
  logic [7:0] g_io_debug_int_rat_6, i_io_debug_int_rat_6;
  logic [7:0] g_io_debug_int_rat_7, i_io_debug_int_rat_7;
  logic [7:0] g_io_debug_int_rat_8, i_io_debug_int_rat_8;
  logic [7:0] g_io_debug_int_rat_9, i_io_debug_int_rat_9;
  logic [7:0] g_io_debug_int_rat_10, i_io_debug_int_rat_10;
  logic [7:0] g_io_debug_int_rat_11, i_io_debug_int_rat_11;
  logic [7:0] g_io_debug_int_rat_12, i_io_debug_int_rat_12;
  logic [7:0] g_io_debug_int_rat_13, i_io_debug_int_rat_13;
  logic [7:0] g_io_debug_int_rat_14, i_io_debug_int_rat_14;
  logic [7:0] g_io_debug_int_rat_15, i_io_debug_int_rat_15;
  logic [7:0] g_io_debug_int_rat_16, i_io_debug_int_rat_16;
  logic [7:0] g_io_debug_int_rat_17, i_io_debug_int_rat_17;
  logic [7:0] g_io_debug_int_rat_18, i_io_debug_int_rat_18;
  logic [7:0] g_io_debug_int_rat_19, i_io_debug_int_rat_19;
  logic [7:0] g_io_debug_int_rat_20, i_io_debug_int_rat_20;
  logic [7:0] g_io_debug_int_rat_21, i_io_debug_int_rat_21;
  logic [7:0] g_io_debug_int_rat_22, i_io_debug_int_rat_22;
  logic [7:0] g_io_debug_int_rat_23, i_io_debug_int_rat_23;
  logic [7:0] g_io_debug_int_rat_24, i_io_debug_int_rat_24;
  logic [7:0] g_io_debug_int_rat_25, i_io_debug_int_rat_25;
  logic [7:0] g_io_debug_int_rat_26, i_io_debug_int_rat_26;
  logic [7:0] g_io_debug_int_rat_27, i_io_debug_int_rat_27;
  logic [7:0] g_io_debug_int_rat_28, i_io_debug_int_rat_28;
  logic [7:0] g_io_debug_int_rat_29, i_io_debug_int_rat_29;
  logic [7:0] g_io_debug_int_rat_30, i_io_debug_int_rat_30;
  logic [7:0] g_io_debug_int_rat_31, i_io_debug_int_rat_31;
  logic [7:0] g_io_diff_vl_rat_0, i_io_diff_vl_rat_0;
  logic [263:0] g_gatewayIn_packed_23_bore, i_gatewayIn_packed_23_bore;
  logic [263:0] g_gatewayIn_packed_24_bore, i_gatewayIn_packed_24_bore;
  logic [583:0] g_gatewayIn_packed_25_bore, i_gatewayIn_packed_25_bore;
  RenameTableWrapper g_u (.clock(clk), .reset(rst), .io_hartId(io_hartId), .io_redirect(io_redirect), .io_rabCommits_isCommit(io_rabCommits_isCommit), .io_rabCommits_commitValid_0(io_rabCommits_commitValid_0), .io_rabCommits_commitValid_1(io_rabCommits_commitValid_1), .io_rabCommits_commitValid_2(io_rabCommits_commitValid_2), .io_rabCommits_commitValid_3(io_rabCommits_commitValid_3), .io_rabCommits_commitValid_4(io_rabCommits_commitValid_4), .io_rabCommits_commitValid_5(io_rabCommits_commitValid_5), .io_rabCommits_isWalk(io_rabCommits_isWalk), .io_rabCommits_walkValid_0(io_rabCommits_walkValid_0), .io_rabCommits_walkValid_1(io_rabCommits_walkValid_1), .io_rabCommits_walkValid_2(io_rabCommits_walkValid_2), .io_rabCommits_walkValid_3(io_rabCommits_walkValid_3), .io_rabCommits_walkValid_4(io_rabCommits_walkValid_4), .io_rabCommits_walkValid_5(io_rabCommits_walkValid_5), .io_rabCommits_info_0_ldest(io_rabCommits_info_0_ldest), .io_rabCommits_info_0_pdest(io_rabCommits_info_0_pdest), .io_rabCommits_info_0_rfWen(io_rabCommits_info_0_rfWen), .io_rabCommits_info_0_fpWen(io_rabCommits_info_0_fpWen), .io_rabCommits_info_0_vecWen(io_rabCommits_info_0_vecWen), .io_rabCommits_info_0_v0Wen(io_rabCommits_info_0_v0Wen), .io_rabCommits_info_0_vlWen(io_rabCommits_info_0_vlWen), .io_rabCommits_info_1_ldest(io_rabCommits_info_1_ldest), .io_rabCommits_info_1_pdest(io_rabCommits_info_1_pdest), .io_rabCommits_info_1_rfWen(io_rabCommits_info_1_rfWen), .io_rabCommits_info_1_fpWen(io_rabCommits_info_1_fpWen), .io_rabCommits_info_1_vecWen(io_rabCommits_info_1_vecWen), .io_rabCommits_info_1_v0Wen(io_rabCommits_info_1_v0Wen), .io_rabCommits_info_1_vlWen(io_rabCommits_info_1_vlWen), .io_rabCommits_info_2_ldest(io_rabCommits_info_2_ldest), .io_rabCommits_info_2_pdest(io_rabCommits_info_2_pdest), .io_rabCommits_info_2_rfWen(io_rabCommits_info_2_rfWen), .io_rabCommits_info_2_fpWen(io_rabCommits_info_2_fpWen), .io_rabCommits_info_2_vecWen(io_rabCommits_info_2_vecWen), .io_rabCommits_info_2_v0Wen(io_rabCommits_info_2_v0Wen), .io_rabCommits_info_2_vlWen(io_rabCommits_info_2_vlWen), .io_rabCommits_info_3_ldest(io_rabCommits_info_3_ldest), .io_rabCommits_info_3_pdest(io_rabCommits_info_3_pdest), .io_rabCommits_info_3_rfWen(io_rabCommits_info_3_rfWen), .io_rabCommits_info_3_fpWen(io_rabCommits_info_3_fpWen), .io_rabCommits_info_3_vecWen(io_rabCommits_info_3_vecWen), .io_rabCommits_info_3_v0Wen(io_rabCommits_info_3_v0Wen), .io_rabCommits_info_3_vlWen(io_rabCommits_info_3_vlWen), .io_rabCommits_info_4_ldest(io_rabCommits_info_4_ldest), .io_rabCommits_info_4_pdest(io_rabCommits_info_4_pdest), .io_rabCommits_info_4_rfWen(io_rabCommits_info_4_rfWen), .io_rabCommits_info_4_fpWen(io_rabCommits_info_4_fpWen), .io_rabCommits_info_4_vecWen(io_rabCommits_info_4_vecWen), .io_rabCommits_info_4_v0Wen(io_rabCommits_info_4_v0Wen), .io_rabCommits_info_4_vlWen(io_rabCommits_info_4_vlWen), .io_rabCommits_info_5_ldest(io_rabCommits_info_5_ldest), .io_rabCommits_info_5_pdest(io_rabCommits_info_5_pdest), .io_rabCommits_info_5_rfWen(io_rabCommits_info_5_rfWen), .io_rabCommits_info_5_fpWen(io_rabCommits_info_5_fpWen), .io_rabCommits_info_5_vecWen(io_rabCommits_info_5_vecWen), .io_rabCommits_info_5_v0Wen(io_rabCommits_info_5_v0Wen), .io_rabCommits_info_5_vlWen(io_rabCommits_info_5_vlWen), .io_renameUpdates_0_valid(io_renameUpdates_0_valid), .io_renameUpdates_0_bits_robIdx_flag(io_renameUpdates_0_bits_robIdx_flag), .io_renameUpdates_0_bits_robIdx_value(io_renameUpdates_0_bits_robIdx_value), .io_renameUpdates_0_bits_lastUop(io_renameUpdates_0_bits_lastUop), .io_renameUpdates_0_bits_ldest(io_renameUpdates_0_bits_ldest), .io_renameUpdates_0_bits_pdest(io_renameUpdates_0_bits_pdest), .io_renameUpdates_0_bits_rfWen(io_renameUpdates_0_bits_rfWen), .io_renameUpdates_0_bits_fpWen(io_renameUpdates_0_bits_fpWen), .io_renameUpdates_0_bits_vecWen(io_renameUpdates_0_bits_vecWen), .io_renameUpdates_0_bits_v0Wen(io_renameUpdates_0_bits_v0Wen), .io_renameUpdates_0_bits_vlWen(io_renameUpdates_0_bits_vlWen), .io_renameUpdates_1_valid(io_renameUpdates_1_valid), .io_renameUpdates_1_bits_robIdx_flag(io_renameUpdates_1_bits_robIdx_flag), .io_renameUpdates_1_bits_robIdx_value(io_renameUpdates_1_bits_robIdx_value), .io_renameUpdates_1_bits_lastUop(io_renameUpdates_1_bits_lastUop), .io_renameUpdates_1_bits_ldest(io_renameUpdates_1_bits_ldest), .io_renameUpdates_1_bits_pdest(io_renameUpdates_1_bits_pdest), .io_renameUpdates_1_bits_rfWen(io_renameUpdates_1_bits_rfWen), .io_renameUpdates_1_bits_fpWen(io_renameUpdates_1_bits_fpWen), .io_renameUpdates_1_bits_vecWen(io_renameUpdates_1_bits_vecWen), .io_renameUpdates_1_bits_v0Wen(io_renameUpdates_1_bits_v0Wen), .io_renameUpdates_1_bits_vlWen(io_renameUpdates_1_bits_vlWen), .io_renameUpdates_2_valid(io_renameUpdates_2_valid), .io_renameUpdates_2_bits_robIdx_flag(io_renameUpdates_2_bits_robIdx_flag), .io_renameUpdates_2_bits_robIdx_value(io_renameUpdates_2_bits_robIdx_value), .io_renameUpdates_2_bits_lastUop(io_renameUpdates_2_bits_lastUop), .io_renameUpdates_2_bits_ldest(io_renameUpdates_2_bits_ldest), .io_renameUpdates_2_bits_pdest(io_renameUpdates_2_bits_pdest), .io_renameUpdates_2_bits_rfWen(io_renameUpdates_2_bits_rfWen), .io_renameUpdates_2_bits_fpWen(io_renameUpdates_2_bits_fpWen), .io_renameUpdates_2_bits_vecWen(io_renameUpdates_2_bits_vecWen), .io_renameUpdates_2_bits_v0Wen(io_renameUpdates_2_bits_v0Wen), .io_renameUpdates_2_bits_vlWen(io_renameUpdates_2_bits_vlWen), .io_renameUpdates_3_valid(io_renameUpdates_3_valid), .io_renameUpdates_3_bits_robIdx_flag(io_renameUpdates_3_bits_robIdx_flag), .io_renameUpdates_3_bits_robIdx_value(io_renameUpdates_3_bits_robIdx_value), .io_renameUpdates_3_bits_lastUop(io_renameUpdates_3_bits_lastUop), .io_renameUpdates_3_bits_ldest(io_renameUpdates_3_bits_ldest), .io_renameUpdates_3_bits_pdest(io_renameUpdates_3_bits_pdest), .io_renameUpdates_3_bits_rfWen(io_renameUpdates_3_bits_rfWen), .io_renameUpdates_3_bits_fpWen(io_renameUpdates_3_bits_fpWen), .io_renameUpdates_3_bits_vecWen(io_renameUpdates_3_bits_vecWen), .io_renameUpdates_3_bits_v0Wen(io_renameUpdates_3_bits_v0Wen), .io_renameUpdates_3_bits_vlWen(io_renameUpdates_3_bits_vlWen), .io_renameUpdates_4_valid(io_renameUpdates_4_valid), .io_renameUpdates_4_bits_robIdx_flag(io_renameUpdates_4_bits_robIdx_flag), .io_renameUpdates_4_bits_robIdx_value(io_renameUpdates_4_bits_robIdx_value), .io_renameUpdates_4_bits_lastUop(io_renameUpdates_4_bits_lastUop), .io_renameUpdates_4_bits_ldest(io_renameUpdates_4_bits_ldest), .io_renameUpdates_4_bits_pdest(io_renameUpdates_4_bits_pdest), .io_renameUpdates_4_bits_rfWen(io_renameUpdates_4_bits_rfWen), .io_renameUpdates_4_bits_fpWen(io_renameUpdates_4_bits_fpWen), .io_renameUpdates_4_bits_vecWen(io_renameUpdates_4_bits_vecWen), .io_renameUpdates_4_bits_v0Wen(io_renameUpdates_4_bits_v0Wen), .io_renameUpdates_4_bits_vlWen(io_renameUpdates_4_bits_vlWen), .io_renameUpdates_5_valid(io_renameUpdates_5_valid), .io_renameUpdates_5_bits_robIdx_flag(io_renameUpdates_5_bits_robIdx_flag), .io_renameUpdates_5_bits_robIdx_value(io_renameUpdates_5_bits_robIdx_value), .io_renameUpdates_5_bits_lastUop(io_renameUpdates_5_bits_lastUop), .io_renameUpdates_5_bits_ldest(io_renameUpdates_5_bits_ldest), .io_renameUpdates_5_bits_pdest(io_renameUpdates_5_bits_pdest), .io_renameUpdates_5_bits_rfWen(io_renameUpdates_5_bits_rfWen), .io_renameUpdates_5_bits_fpWen(io_renameUpdates_5_bits_fpWen), .io_renameUpdates_5_bits_vecWen(io_renameUpdates_5_bits_vecWen), .io_renameUpdates_5_bits_v0Wen(io_renameUpdates_5_bits_v0Wen), .io_renameUpdates_5_bits_vlWen(io_renameUpdates_5_bits_vlWen), .io_diffRatCommitRobIdx_valid(io_diffRatCommitRobIdx_valid), .io_diffRatCommitRobIdx_bits_flag(io_diffRatCommitRobIdx_bits_flag), .io_diffRatCommitRobIdx_bits_value(io_diffRatCommitRobIdx_bits_value), .io_intReadPorts_0_0_hold(io_intReadPorts_0_0_hold), .io_intReadPorts_0_0_addr(io_intReadPorts_0_0_addr), .io_intReadPorts_0_1_hold(io_intReadPorts_0_1_hold), .io_intReadPorts_0_1_addr(io_intReadPorts_0_1_addr), .io_intReadPorts_1_0_hold(io_intReadPorts_1_0_hold), .io_intReadPorts_1_0_addr(io_intReadPorts_1_0_addr), .io_intReadPorts_1_1_hold(io_intReadPorts_1_1_hold), .io_intReadPorts_1_1_addr(io_intReadPorts_1_1_addr), .io_intReadPorts_2_0_hold(io_intReadPorts_2_0_hold), .io_intReadPorts_2_0_addr(io_intReadPorts_2_0_addr), .io_intReadPorts_2_1_hold(io_intReadPorts_2_1_hold), .io_intReadPorts_2_1_addr(io_intReadPorts_2_1_addr), .io_intReadPorts_3_0_hold(io_intReadPorts_3_0_hold), .io_intReadPorts_3_0_addr(io_intReadPorts_3_0_addr), .io_intReadPorts_3_1_hold(io_intReadPorts_3_1_hold), .io_intReadPorts_3_1_addr(io_intReadPorts_3_1_addr), .io_intReadPorts_4_0_hold(io_intReadPorts_4_0_hold), .io_intReadPorts_4_0_addr(io_intReadPorts_4_0_addr), .io_intReadPorts_4_1_hold(io_intReadPorts_4_1_hold), .io_intReadPorts_4_1_addr(io_intReadPorts_4_1_addr), .io_intReadPorts_5_0_hold(io_intReadPorts_5_0_hold), .io_intReadPorts_5_0_addr(io_intReadPorts_5_0_addr), .io_intReadPorts_5_1_hold(io_intReadPorts_5_1_hold), .io_intReadPorts_5_1_addr(io_intReadPorts_5_1_addr), .io_intRenamePorts_0_wen(io_intRenamePorts_0_wen), .io_intRenamePorts_0_addr(io_intRenamePorts_0_addr), .io_intRenamePorts_0_data(io_intRenamePorts_0_data), .io_intRenamePorts_1_wen(io_intRenamePorts_1_wen), .io_intRenamePorts_1_addr(io_intRenamePorts_1_addr), .io_intRenamePorts_1_data(io_intRenamePorts_1_data), .io_intRenamePorts_2_wen(io_intRenamePorts_2_wen), .io_intRenamePorts_2_addr(io_intRenamePorts_2_addr), .io_intRenamePorts_2_data(io_intRenamePorts_2_data), .io_intRenamePorts_3_wen(io_intRenamePorts_3_wen), .io_intRenamePorts_3_addr(io_intRenamePorts_3_addr), .io_intRenamePorts_3_data(io_intRenamePorts_3_data), .io_intRenamePorts_4_wen(io_intRenamePorts_4_wen), .io_intRenamePorts_4_addr(io_intRenamePorts_4_addr), .io_intRenamePorts_4_data(io_intRenamePorts_4_data), .io_intRenamePorts_5_wen(io_intRenamePorts_5_wen), .io_intRenamePorts_5_addr(io_intRenamePorts_5_addr), .io_intRenamePorts_5_data(io_intRenamePorts_5_data), .io_fpReadPorts_0_0_hold(io_fpReadPorts_0_0_hold), .io_fpReadPorts_0_0_addr(io_fpReadPorts_0_0_addr), .io_fpReadPorts_0_1_hold(io_fpReadPorts_0_1_hold), .io_fpReadPorts_0_1_addr(io_fpReadPorts_0_1_addr), .io_fpReadPorts_0_2_hold(io_fpReadPorts_0_2_hold), .io_fpReadPorts_0_2_addr(io_fpReadPorts_0_2_addr), .io_fpReadPorts_1_0_hold(io_fpReadPorts_1_0_hold), .io_fpReadPorts_1_0_addr(io_fpReadPorts_1_0_addr), .io_fpReadPorts_1_1_hold(io_fpReadPorts_1_1_hold), .io_fpReadPorts_1_1_addr(io_fpReadPorts_1_1_addr), .io_fpReadPorts_1_2_hold(io_fpReadPorts_1_2_hold), .io_fpReadPorts_1_2_addr(io_fpReadPorts_1_2_addr), .io_fpReadPorts_2_0_hold(io_fpReadPorts_2_0_hold), .io_fpReadPorts_2_0_addr(io_fpReadPorts_2_0_addr), .io_fpReadPorts_2_1_hold(io_fpReadPorts_2_1_hold), .io_fpReadPorts_2_1_addr(io_fpReadPorts_2_1_addr), .io_fpReadPorts_2_2_hold(io_fpReadPorts_2_2_hold), .io_fpReadPorts_2_2_addr(io_fpReadPorts_2_2_addr), .io_fpReadPorts_3_0_hold(io_fpReadPorts_3_0_hold), .io_fpReadPorts_3_0_addr(io_fpReadPorts_3_0_addr), .io_fpReadPorts_3_1_hold(io_fpReadPorts_3_1_hold), .io_fpReadPorts_3_1_addr(io_fpReadPorts_3_1_addr), .io_fpReadPorts_3_2_hold(io_fpReadPorts_3_2_hold), .io_fpReadPorts_3_2_addr(io_fpReadPorts_3_2_addr), .io_fpReadPorts_4_0_hold(io_fpReadPorts_4_0_hold), .io_fpReadPorts_4_0_addr(io_fpReadPorts_4_0_addr), .io_fpReadPorts_4_1_hold(io_fpReadPorts_4_1_hold), .io_fpReadPorts_4_1_addr(io_fpReadPorts_4_1_addr), .io_fpReadPorts_4_2_hold(io_fpReadPorts_4_2_hold), .io_fpReadPorts_4_2_addr(io_fpReadPorts_4_2_addr), .io_fpReadPorts_5_0_hold(io_fpReadPorts_5_0_hold), .io_fpReadPorts_5_0_addr(io_fpReadPorts_5_0_addr), .io_fpReadPorts_5_1_hold(io_fpReadPorts_5_1_hold), .io_fpReadPorts_5_1_addr(io_fpReadPorts_5_1_addr), .io_fpReadPorts_5_2_hold(io_fpReadPorts_5_2_hold), .io_fpReadPorts_5_2_addr(io_fpReadPorts_5_2_addr), .io_fpRenamePorts_0_wen(io_fpRenamePorts_0_wen), .io_fpRenamePorts_0_addr(io_fpRenamePorts_0_addr), .io_fpRenamePorts_0_data(io_fpRenamePorts_0_data), .io_fpRenamePorts_1_wen(io_fpRenamePorts_1_wen), .io_fpRenamePorts_1_addr(io_fpRenamePorts_1_addr), .io_fpRenamePorts_1_data(io_fpRenamePorts_1_data), .io_fpRenamePorts_2_wen(io_fpRenamePorts_2_wen), .io_fpRenamePorts_2_addr(io_fpRenamePorts_2_addr), .io_fpRenamePorts_2_data(io_fpRenamePorts_2_data), .io_fpRenamePorts_3_wen(io_fpRenamePorts_3_wen), .io_fpRenamePorts_3_addr(io_fpRenamePorts_3_addr), .io_fpRenamePorts_3_data(io_fpRenamePorts_3_data), .io_fpRenamePorts_4_wen(io_fpRenamePorts_4_wen), .io_fpRenamePorts_4_addr(io_fpRenamePorts_4_addr), .io_fpRenamePorts_4_data(io_fpRenamePorts_4_data), .io_fpRenamePorts_5_wen(io_fpRenamePorts_5_wen), .io_fpRenamePorts_5_addr(io_fpRenamePorts_5_addr), .io_fpRenamePorts_5_data(io_fpRenamePorts_5_data), .io_vecReadPorts_0_0_hold(io_vecReadPorts_0_0_hold), .io_vecReadPorts_0_0_addr(io_vecReadPorts_0_0_addr), .io_vecReadPorts_0_1_hold(io_vecReadPorts_0_1_hold), .io_vecReadPorts_0_1_addr(io_vecReadPorts_0_1_addr), .io_vecReadPorts_0_2_hold(io_vecReadPorts_0_2_hold), .io_vecReadPorts_0_2_addr(io_vecReadPorts_0_2_addr), .io_vecReadPorts_1_0_hold(io_vecReadPorts_1_0_hold), .io_vecReadPorts_1_0_addr(io_vecReadPorts_1_0_addr), .io_vecReadPorts_1_1_hold(io_vecReadPorts_1_1_hold), .io_vecReadPorts_1_1_addr(io_vecReadPorts_1_1_addr), .io_vecReadPorts_1_2_hold(io_vecReadPorts_1_2_hold), .io_vecReadPorts_1_2_addr(io_vecReadPorts_1_2_addr), .io_vecReadPorts_2_0_hold(io_vecReadPorts_2_0_hold), .io_vecReadPorts_2_0_addr(io_vecReadPorts_2_0_addr), .io_vecReadPorts_2_1_hold(io_vecReadPorts_2_1_hold), .io_vecReadPorts_2_1_addr(io_vecReadPorts_2_1_addr), .io_vecReadPorts_2_2_hold(io_vecReadPorts_2_2_hold), .io_vecReadPorts_2_2_addr(io_vecReadPorts_2_2_addr), .io_vecReadPorts_3_0_hold(io_vecReadPorts_3_0_hold), .io_vecReadPorts_3_0_addr(io_vecReadPorts_3_0_addr), .io_vecReadPorts_3_1_hold(io_vecReadPorts_3_1_hold), .io_vecReadPorts_3_1_addr(io_vecReadPorts_3_1_addr), .io_vecReadPorts_3_2_hold(io_vecReadPorts_3_2_hold), .io_vecReadPorts_3_2_addr(io_vecReadPorts_3_2_addr), .io_vecReadPorts_4_0_hold(io_vecReadPorts_4_0_hold), .io_vecReadPorts_4_0_addr(io_vecReadPorts_4_0_addr), .io_vecReadPorts_4_1_hold(io_vecReadPorts_4_1_hold), .io_vecReadPorts_4_1_addr(io_vecReadPorts_4_1_addr), .io_vecReadPorts_4_2_hold(io_vecReadPorts_4_2_hold), .io_vecReadPorts_4_2_addr(io_vecReadPorts_4_2_addr), .io_vecReadPorts_5_0_hold(io_vecReadPorts_5_0_hold), .io_vecReadPorts_5_0_addr(io_vecReadPorts_5_0_addr), .io_vecReadPorts_5_1_hold(io_vecReadPorts_5_1_hold), .io_vecReadPorts_5_1_addr(io_vecReadPorts_5_1_addr), .io_vecReadPorts_5_2_hold(io_vecReadPorts_5_2_hold), .io_vecReadPorts_5_2_addr(io_vecReadPorts_5_2_addr), .io_vecRenamePorts_0_wen(io_vecRenamePorts_0_wen), .io_vecRenamePorts_0_addr(io_vecRenamePorts_0_addr), .io_vecRenamePorts_0_data(io_vecRenamePorts_0_data), .io_vecRenamePorts_1_wen(io_vecRenamePorts_1_wen), .io_vecRenamePorts_1_addr(io_vecRenamePorts_1_addr), .io_vecRenamePorts_1_data(io_vecRenamePorts_1_data), .io_vecRenamePorts_2_wen(io_vecRenamePorts_2_wen), .io_vecRenamePorts_2_addr(io_vecRenamePorts_2_addr), .io_vecRenamePorts_2_data(io_vecRenamePorts_2_data), .io_vecRenamePorts_3_wen(io_vecRenamePorts_3_wen), .io_vecRenamePorts_3_addr(io_vecRenamePorts_3_addr), .io_vecRenamePorts_3_data(io_vecRenamePorts_3_data), .io_vecRenamePorts_4_wen(io_vecRenamePorts_4_wen), .io_vecRenamePorts_4_addr(io_vecRenamePorts_4_addr), .io_vecRenamePorts_4_data(io_vecRenamePorts_4_data), .io_vecRenamePorts_5_wen(io_vecRenamePorts_5_wen), .io_vecRenamePorts_5_addr(io_vecRenamePorts_5_addr), .io_vecRenamePorts_5_data(io_vecRenamePorts_5_data), .io_v0ReadPorts_0_hold(io_v0ReadPorts_0_hold), .io_v0ReadPorts_1_hold(io_v0ReadPorts_1_hold), .io_v0ReadPorts_2_hold(io_v0ReadPorts_2_hold), .io_v0ReadPorts_3_hold(io_v0ReadPorts_3_hold), .io_v0ReadPorts_4_hold(io_v0ReadPorts_4_hold), .io_v0ReadPorts_5_hold(io_v0ReadPorts_5_hold), .io_v0RenamePorts_0_wen(io_v0RenamePorts_0_wen), .io_v0RenamePorts_0_data(io_v0RenamePorts_0_data), .io_v0RenamePorts_1_wen(io_v0RenamePorts_1_wen), .io_v0RenamePorts_1_data(io_v0RenamePorts_1_data), .io_v0RenamePorts_2_wen(io_v0RenamePorts_2_wen), .io_v0RenamePorts_2_data(io_v0RenamePorts_2_data), .io_v0RenamePorts_3_wen(io_v0RenamePorts_3_wen), .io_v0RenamePorts_3_data(io_v0RenamePorts_3_data), .io_v0RenamePorts_4_wen(io_v0RenamePorts_4_wen), .io_v0RenamePorts_4_data(io_v0RenamePorts_4_data), .io_v0RenamePorts_5_wen(io_v0RenamePorts_5_wen), .io_v0RenamePorts_5_data(io_v0RenamePorts_5_data), .io_vlReadPorts_0_hold(io_vlReadPorts_0_hold), .io_vlReadPorts_1_hold(io_vlReadPorts_1_hold), .io_vlReadPorts_2_hold(io_vlReadPorts_2_hold), .io_vlReadPorts_3_hold(io_vlReadPorts_3_hold), .io_vlReadPorts_4_hold(io_vlReadPorts_4_hold), .io_vlReadPorts_5_hold(io_vlReadPorts_5_hold), .io_vlRenamePorts_0_wen(io_vlRenamePorts_0_wen), .io_vlRenamePorts_0_data(io_vlRenamePorts_0_data), .io_vlRenamePorts_1_wen(io_vlRenamePorts_1_wen), .io_vlRenamePorts_1_data(io_vlRenamePorts_1_data), .io_vlRenamePorts_2_wen(io_vlRenamePorts_2_wen), .io_vlRenamePorts_2_data(io_vlRenamePorts_2_data), .io_vlRenamePorts_3_wen(io_vlRenamePorts_3_wen), .io_vlRenamePorts_3_data(io_vlRenamePorts_3_data), .io_vlRenamePorts_4_wen(io_vlRenamePorts_4_wen), .io_vlRenamePorts_4_data(io_vlRenamePorts_4_data), .io_vlRenamePorts_5_wen(io_vlRenamePorts_5_wen), .io_vlRenamePorts_5_data(io_vlRenamePorts_5_data), .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec_0(io_snpt_flushVec_0), .io_snpt_flushVec_1(io_snpt_flushVec_1), .io_snpt_flushVec_2(io_snpt_flushVec_2), .io_snpt_flushVec_3(io_snpt_flushVec_3), .io_intReadPorts_0_0_data(g_io_intReadPorts_0_0_data), .io_intReadPorts_0_1_data(g_io_intReadPorts_0_1_data), .io_intReadPorts_1_0_data(g_io_intReadPorts_1_0_data), .io_intReadPorts_1_1_data(g_io_intReadPorts_1_1_data), .io_intReadPorts_2_0_data(g_io_intReadPorts_2_0_data), .io_intReadPorts_2_1_data(g_io_intReadPorts_2_1_data), .io_intReadPorts_3_0_data(g_io_intReadPorts_3_0_data), .io_intReadPorts_3_1_data(g_io_intReadPorts_3_1_data), .io_intReadPorts_4_0_data(g_io_intReadPorts_4_0_data), .io_intReadPorts_4_1_data(g_io_intReadPorts_4_1_data), .io_intReadPorts_5_0_data(g_io_intReadPorts_5_0_data), .io_intReadPorts_5_1_data(g_io_intReadPorts_5_1_data), .io_fpReadPorts_0_0_data(g_io_fpReadPorts_0_0_data), .io_fpReadPorts_0_1_data(g_io_fpReadPorts_0_1_data), .io_fpReadPorts_0_2_data(g_io_fpReadPorts_0_2_data), .io_fpReadPorts_1_0_data(g_io_fpReadPorts_1_0_data), .io_fpReadPorts_1_1_data(g_io_fpReadPorts_1_1_data), .io_fpReadPorts_1_2_data(g_io_fpReadPorts_1_2_data), .io_fpReadPorts_2_0_data(g_io_fpReadPorts_2_0_data), .io_fpReadPorts_2_1_data(g_io_fpReadPorts_2_1_data), .io_fpReadPorts_2_2_data(g_io_fpReadPorts_2_2_data), .io_fpReadPorts_3_0_data(g_io_fpReadPorts_3_0_data), .io_fpReadPorts_3_1_data(g_io_fpReadPorts_3_1_data), .io_fpReadPorts_3_2_data(g_io_fpReadPorts_3_2_data), .io_fpReadPorts_4_0_data(g_io_fpReadPorts_4_0_data), .io_fpReadPorts_4_1_data(g_io_fpReadPorts_4_1_data), .io_fpReadPorts_4_2_data(g_io_fpReadPorts_4_2_data), .io_fpReadPorts_5_0_data(g_io_fpReadPorts_5_0_data), .io_fpReadPorts_5_1_data(g_io_fpReadPorts_5_1_data), .io_fpReadPorts_5_2_data(g_io_fpReadPorts_5_2_data), .io_vecReadPorts_0_0_data(g_io_vecReadPorts_0_0_data), .io_vecReadPorts_0_1_data(g_io_vecReadPorts_0_1_data), .io_vecReadPorts_0_2_data(g_io_vecReadPorts_0_2_data), .io_vecReadPorts_1_0_data(g_io_vecReadPorts_1_0_data), .io_vecReadPorts_1_1_data(g_io_vecReadPorts_1_1_data), .io_vecReadPorts_1_2_data(g_io_vecReadPorts_1_2_data), .io_vecReadPorts_2_0_data(g_io_vecReadPorts_2_0_data), .io_vecReadPorts_2_1_data(g_io_vecReadPorts_2_1_data), .io_vecReadPorts_2_2_data(g_io_vecReadPorts_2_2_data), .io_vecReadPorts_3_0_data(g_io_vecReadPorts_3_0_data), .io_vecReadPorts_3_1_data(g_io_vecReadPorts_3_1_data), .io_vecReadPorts_3_2_data(g_io_vecReadPorts_3_2_data), .io_vecReadPorts_4_0_data(g_io_vecReadPorts_4_0_data), .io_vecReadPorts_4_1_data(g_io_vecReadPorts_4_1_data), .io_vecReadPorts_4_2_data(g_io_vecReadPorts_4_2_data), .io_vecReadPorts_5_0_data(g_io_vecReadPorts_5_0_data), .io_vecReadPorts_5_1_data(g_io_vecReadPorts_5_1_data), .io_vecReadPorts_5_2_data(g_io_vecReadPorts_5_2_data), .io_v0ReadPorts_0_data(g_io_v0ReadPorts_0_data), .io_v0ReadPorts_1_data(g_io_v0ReadPorts_1_data), .io_v0ReadPorts_2_data(g_io_v0ReadPorts_2_data), .io_v0ReadPorts_3_data(g_io_v0ReadPorts_3_data), .io_v0ReadPorts_4_data(g_io_v0ReadPorts_4_data), .io_v0ReadPorts_5_data(g_io_v0ReadPorts_5_data), .io_vlReadPorts_0_data(g_io_vlReadPorts_0_data), .io_vlReadPorts_1_data(g_io_vlReadPorts_1_data), .io_vlReadPorts_2_data(g_io_vlReadPorts_2_data), .io_vlReadPorts_3_data(g_io_vlReadPorts_3_data), .io_vlReadPorts_4_data(g_io_vlReadPorts_4_data), .io_vlReadPorts_5_data(g_io_vlReadPorts_5_data), .io_int_old_pdest_0(g_io_int_old_pdest_0), .io_int_old_pdest_1(g_io_int_old_pdest_1), .io_int_old_pdest_2(g_io_int_old_pdest_2), .io_int_old_pdest_3(g_io_int_old_pdest_3), .io_int_old_pdest_4(g_io_int_old_pdest_4), .io_int_old_pdest_5(g_io_int_old_pdest_5), .io_fp_old_pdest_0(g_io_fp_old_pdest_0), .io_fp_old_pdest_1(g_io_fp_old_pdest_1), .io_fp_old_pdest_2(g_io_fp_old_pdest_2), .io_fp_old_pdest_3(g_io_fp_old_pdest_3), .io_fp_old_pdest_4(g_io_fp_old_pdest_4), .io_fp_old_pdest_5(g_io_fp_old_pdest_5), .io_vec_old_pdest_0(g_io_vec_old_pdest_0), .io_vec_old_pdest_1(g_io_vec_old_pdest_1), .io_vec_old_pdest_2(g_io_vec_old_pdest_2), .io_vec_old_pdest_3(g_io_vec_old_pdest_3), .io_vec_old_pdest_4(g_io_vec_old_pdest_4), .io_vec_old_pdest_5(g_io_vec_old_pdest_5), .io_v0_old_pdest_0(g_io_v0_old_pdest_0), .io_v0_old_pdest_1(g_io_v0_old_pdest_1), .io_v0_old_pdest_2(g_io_v0_old_pdest_2), .io_v0_old_pdest_3(g_io_v0_old_pdest_3), .io_v0_old_pdest_4(g_io_v0_old_pdest_4), .io_v0_old_pdest_5(g_io_v0_old_pdest_5), .io_vl_old_pdest_0(g_io_vl_old_pdest_0), .io_vl_old_pdest_1(g_io_vl_old_pdest_1), .io_vl_old_pdest_2(g_io_vl_old_pdest_2), .io_vl_old_pdest_3(g_io_vl_old_pdest_3), .io_vl_old_pdest_4(g_io_vl_old_pdest_4), .io_vl_old_pdest_5(g_io_vl_old_pdest_5), .io_int_need_free_0(g_io_int_need_free_0), .io_int_need_free_1(g_io_int_need_free_1), .io_int_need_free_2(g_io_int_need_free_2), .io_int_need_free_3(g_io_int_need_free_3), .io_int_need_free_4(g_io_int_need_free_4), .io_int_need_free_5(g_io_int_need_free_5), .io_debug_int_rat_0(g_io_debug_int_rat_0), .io_debug_int_rat_1(g_io_debug_int_rat_1), .io_debug_int_rat_2(g_io_debug_int_rat_2), .io_debug_int_rat_3(g_io_debug_int_rat_3), .io_debug_int_rat_4(g_io_debug_int_rat_4), .io_debug_int_rat_5(g_io_debug_int_rat_5), .io_debug_int_rat_6(g_io_debug_int_rat_6), .io_debug_int_rat_7(g_io_debug_int_rat_7), .io_debug_int_rat_8(g_io_debug_int_rat_8), .io_debug_int_rat_9(g_io_debug_int_rat_9), .io_debug_int_rat_10(g_io_debug_int_rat_10), .io_debug_int_rat_11(g_io_debug_int_rat_11), .io_debug_int_rat_12(g_io_debug_int_rat_12), .io_debug_int_rat_13(g_io_debug_int_rat_13), .io_debug_int_rat_14(g_io_debug_int_rat_14), .io_debug_int_rat_15(g_io_debug_int_rat_15), .io_debug_int_rat_16(g_io_debug_int_rat_16), .io_debug_int_rat_17(g_io_debug_int_rat_17), .io_debug_int_rat_18(g_io_debug_int_rat_18), .io_debug_int_rat_19(g_io_debug_int_rat_19), .io_debug_int_rat_20(g_io_debug_int_rat_20), .io_debug_int_rat_21(g_io_debug_int_rat_21), .io_debug_int_rat_22(g_io_debug_int_rat_22), .io_debug_int_rat_23(g_io_debug_int_rat_23), .io_debug_int_rat_24(g_io_debug_int_rat_24), .io_debug_int_rat_25(g_io_debug_int_rat_25), .io_debug_int_rat_26(g_io_debug_int_rat_26), .io_debug_int_rat_27(g_io_debug_int_rat_27), .io_debug_int_rat_28(g_io_debug_int_rat_28), .io_debug_int_rat_29(g_io_debug_int_rat_29), .io_debug_int_rat_30(g_io_debug_int_rat_30), .io_debug_int_rat_31(g_io_debug_int_rat_31), .io_diff_vl_rat_0(g_io_diff_vl_rat_0), .gatewayIn_packed_23_bore(g_gatewayIn_packed_23_bore), .gatewayIn_packed_24_bore(g_gatewayIn_packed_24_bore), .gatewayIn_packed_25_bore(g_gatewayIn_packed_25_bore));
  RenameTableWrapper_xs i_u (.clock(clk), .reset(rst), .io_hartId(io_hartId), .io_redirect(io_redirect), .io_rabCommits_isCommit(io_rabCommits_isCommit), .io_rabCommits_commitValid_0(io_rabCommits_commitValid_0), .io_rabCommits_commitValid_1(io_rabCommits_commitValid_1), .io_rabCommits_commitValid_2(io_rabCommits_commitValid_2), .io_rabCommits_commitValid_3(io_rabCommits_commitValid_3), .io_rabCommits_commitValid_4(io_rabCommits_commitValid_4), .io_rabCommits_commitValid_5(io_rabCommits_commitValid_5), .io_rabCommits_isWalk(io_rabCommits_isWalk), .io_rabCommits_walkValid_0(io_rabCommits_walkValid_0), .io_rabCommits_walkValid_1(io_rabCommits_walkValid_1), .io_rabCommits_walkValid_2(io_rabCommits_walkValid_2), .io_rabCommits_walkValid_3(io_rabCommits_walkValid_3), .io_rabCommits_walkValid_4(io_rabCommits_walkValid_4), .io_rabCommits_walkValid_5(io_rabCommits_walkValid_5), .io_rabCommits_info_0_ldest(io_rabCommits_info_0_ldest), .io_rabCommits_info_0_pdest(io_rabCommits_info_0_pdest), .io_rabCommits_info_0_rfWen(io_rabCommits_info_0_rfWen), .io_rabCommits_info_0_fpWen(io_rabCommits_info_0_fpWen), .io_rabCommits_info_0_vecWen(io_rabCommits_info_0_vecWen), .io_rabCommits_info_0_v0Wen(io_rabCommits_info_0_v0Wen), .io_rabCommits_info_0_vlWen(io_rabCommits_info_0_vlWen), .io_rabCommits_info_1_ldest(io_rabCommits_info_1_ldest), .io_rabCommits_info_1_pdest(io_rabCommits_info_1_pdest), .io_rabCommits_info_1_rfWen(io_rabCommits_info_1_rfWen), .io_rabCommits_info_1_fpWen(io_rabCommits_info_1_fpWen), .io_rabCommits_info_1_vecWen(io_rabCommits_info_1_vecWen), .io_rabCommits_info_1_v0Wen(io_rabCommits_info_1_v0Wen), .io_rabCommits_info_1_vlWen(io_rabCommits_info_1_vlWen), .io_rabCommits_info_2_ldest(io_rabCommits_info_2_ldest), .io_rabCommits_info_2_pdest(io_rabCommits_info_2_pdest), .io_rabCommits_info_2_rfWen(io_rabCommits_info_2_rfWen), .io_rabCommits_info_2_fpWen(io_rabCommits_info_2_fpWen), .io_rabCommits_info_2_vecWen(io_rabCommits_info_2_vecWen), .io_rabCommits_info_2_v0Wen(io_rabCommits_info_2_v0Wen), .io_rabCommits_info_2_vlWen(io_rabCommits_info_2_vlWen), .io_rabCommits_info_3_ldest(io_rabCommits_info_3_ldest), .io_rabCommits_info_3_pdest(io_rabCommits_info_3_pdest), .io_rabCommits_info_3_rfWen(io_rabCommits_info_3_rfWen), .io_rabCommits_info_3_fpWen(io_rabCommits_info_3_fpWen), .io_rabCommits_info_3_vecWen(io_rabCommits_info_3_vecWen), .io_rabCommits_info_3_v0Wen(io_rabCommits_info_3_v0Wen), .io_rabCommits_info_3_vlWen(io_rabCommits_info_3_vlWen), .io_rabCommits_info_4_ldest(io_rabCommits_info_4_ldest), .io_rabCommits_info_4_pdest(io_rabCommits_info_4_pdest), .io_rabCommits_info_4_rfWen(io_rabCommits_info_4_rfWen), .io_rabCommits_info_4_fpWen(io_rabCommits_info_4_fpWen), .io_rabCommits_info_4_vecWen(io_rabCommits_info_4_vecWen), .io_rabCommits_info_4_v0Wen(io_rabCommits_info_4_v0Wen), .io_rabCommits_info_4_vlWen(io_rabCommits_info_4_vlWen), .io_rabCommits_info_5_ldest(io_rabCommits_info_5_ldest), .io_rabCommits_info_5_pdest(io_rabCommits_info_5_pdest), .io_rabCommits_info_5_rfWen(io_rabCommits_info_5_rfWen), .io_rabCommits_info_5_fpWen(io_rabCommits_info_5_fpWen), .io_rabCommits_info_5_vecWen(io_rabCommits_info_5_vecWen), .io_rabCommits_info_5_v0Wen(io_rabCommits_info_5_v0Wen), .io_rabCommits_info_5_vlWen(io_rabCommits_info_5_vlWen), .io_renameUpdates_0_valid(io_renameUpdates_0_valid), .io_renameUpdates_0_bits_robIdx_flag(io_renameUpdates_0_bits_robIdx_flag), .io_renameUpdates_0_bits_robIdx_value(io_renameUpdates_0_bits_robIdx_value), .io_renameUpdates_0_bits_lastUop(io_renameUpdates_0_bits_lastUop), .io_renameUpdates_0_bits_ldest(io_renameUpdates_0_bits_ldest), .io_renameUpdates_0_bits_pdest(io_renameUpdates_0_bits_pdest), .io_renameUpdates_0_bits_rfWen(io_renameUpdates_0_bits_rfWen), .io_renameUpdates_0_bits_fpWen(io_renameUpdates_0_bits_fpWen), .io_renameUpdates_0_bits_vecWen(io_renameUpdates_0_bits_vecWen), .io_renameUpdates_0_bits_v0Wen(io_renameUpdates_0_bits_v0Wen), .io_renameUpdates_0_bits_vlWen(io_renameUpdates_0_bits_vlWen), .io_renameUpdates_1_valid(io_renameUpdates_1_valid), .io_renameUpdates_1_bits_robIdx_flag(io_renameUpdates_1_bits_robIdx_flag), .io_renameUpdates_1_bits_robIdx_value(io_renameUpdates_1_bits_robIdx_value), .io_renameUpdates_1_bits_lastUop(io_renameUpdates_1_bits_lastUop), .io_renameUpdates_1_bits_ldest(io_renameUpdates_1_bits_ldest), .io_renameUpdates_1_bits_pdest(io_renameUpdates_1_bits_pdest), .io_renameUpdates_1_bits_rfWen(io_renameUpdates_1_bits_rfWen), .io_renameUpdates_1_bits_fpWen(io_renameUpdates_1_bits_fpWen), .io_renameUpdates_1_bits_vecWen(io_renameUpdates_1_bits_vecWen), .io_renameUpdates_1_bits_v0Wen(io_renameUpdates_1_bits_v0Wen), .io_renameUpdates_1_bits_vlWen(io_renameUpdates_1_bits_vlWen), .io_renameUpdates_2_valid(io_renameUpdates_2_valid), .io_renameUpdates_2_bits_robIdx_flag(io_renameUpdates_2_bits_robIdx_flag), .io_renameUpdates_2_bits_robIdx_value(io_renameUpdates_2_bits_robIdx_value), .io_renameUpdates_2_bits_lastUop(io_renameUpdates_2_bits_lastUop), .io_renameUpdates_2_bits_ldest(io_renameUpdates_2_bits_ldest), .io_renameUpdates_2_bits_pdest(io_renameUpdates_2_bits_pdest), .io_renameUpdates_2_bits_rfWen(io_renameUpdates_2_bits_rfWen), .io_renameUpdates_2_bits_fpWen(io_renameUpdates_2_bits_fpWen), .io_renameUpdates_2_bits_vecWen(io_renameUpdates_2_bits_vecWen), .io_renameUpdates_2_bits_v0Wen(io_renameUpdates_2_bits_v0Wen), .io_renameUpdates_2_bits_vlWen(io_renameUpdates_2_bits_vlWen), .io_renameUpdates_3_valid(io_renameUpdates_3_valid), .io_renameUpdates_3_bits_robIdx_flag(io_renameUpdates_3_bits_robIdx_flag), .io_renameUpdates_3_bits_robIdx_value(io_renameUpdates_3_bits_robIdx_value), .io_renameUpdates_3_bits_lastUop(io_renameUpdates_3_bits_lastUop), .io_renameUpdates_3_bits_ldest(io_renameUpdates_3_bits_ldest), .io_renameUpdates_3_bits_pdest(io_renameUpdates_3_bits_pdest), .io_renameUpdates_3_bits_rfWen(io_renameUpdates_3_bits_rfWen), .io_renameUpdates_3_bits_fpWen(io_renameUpdates_3_bits_fpWen), .io_renameUpdates_3_bits_vecWen(io_renameUpdates_3_bits_vecWen), .io_renameUpdates_3_bits_v0Wen(io_renameUpdates_3_bits_v0Wen), .io_renameUpdates_3_bits_vlWen(io_renameUpdates_3_bits_vlWen), .io_renameUpdates_4_valid(io_renameUpdates_4_valid), .io_renameUpdates_4_bits_robIdx_flag(io_renameUpdates_4_bits_robIdx_flag), .io_renameUpdates_4_bits_robIdx_value(io_renameUpdates_4_bits_robIdx_value), .io_renameUpdates_4_bits_lastUop(io_renameUpdates_4_bits_lastUop), .io_renameUpdates_4_bits_ldest(io_renameUpdates_4_bits_ldest), .io_renameUpdates_4_bits_pdest(io_renameUpdates_4_bits_pdest), .io_renameUpdates_4_bits_rfWen(io_renameUpdates_4_bits_rfWen), .io_renameUpdates_4_bits_fpWen(io_renameUpdates_4_bits_fpWen), .io_renameUpdates_4_bits_vecWen(io_renameUpdates_4_bits_vecWen), .io_renameUpdates_4_bits_v0Wen(io_renameUpdates_4_bits_v0Wen), .io_renameUpdates_4_bits_vlWen(io_renameUpdates_4_bits_vlWen), .io_renameUpdates_5_valid(io_renameUpdates_5_valid), .io_renameUpdates_5_bits_robIdx_flag(io_renameUpdates_5_bits_robIdx_flag), .io_renameUpdates_5_bits_robIdx_value(io_renameUpdates_5_bits_robIdx_value), .io_renameUpdates_5_bits_lastUop(io_renameUpdates_5_bits_lastUop), .io_renameUpdates_5_bits_ldest(io_renameUpdates_5_bits_ldest), .io_renameUpdates_5_bits_pdest(io_renameUpdates_5_bits_pdest), .io_renameUpdates_5_bits_rfWen(io_renameUpdates_5_bits_rfWen), .io_renameUpdates_5_bits_fpWen(io_renameUpdates_5_bits_fpWen), .io_renameUpdates_5_bits_vecWen(io_renameUpdates_5_bits_vecWen), .io_renameUpdates_5_bits_v0Wen(io_renameUpdates_5_bits_v0Wen), .io_renameUpdates_5_bits_vlWen(io_renameUpdates_5_bits_vlWen), .io_diffRatCommitRobIdx_valid(io_diffRatCommitRobIdx_valid), .io_diffRatCommitRobIdx_bits_flag(io_diffRatCommitRobIdx_bits_flag), .io_diffRatCommitRobIdx_bits_value(io_diffRatCommitRobIdx_bits_value), .io_intReadPorts_0_0_hold(io_intReadPorts_0_0_hold), .io_intReadPorts_0_0_addr(io_intReadPorts_0_0_addr), .io_intReadPorts_0_1_hold(io_intReadPorts_0_1_hold), .io_intReadPorts_0_1_addr(io_intReadPorts_0_1_addr), .io_intReadPorts_1_0_hold(io_intReadPorts_1_0_hold), .io_intReadPorts_1_0_addr(io_intReadPorts_1_0_addr), .io_intReadPorts_1_1_hold(io_intReadPorts_1_1_hold), .io_intReadPorts_1_1_addr(io_intReadPorts_1_1_addr), .io_intReadPorts_2_0_hold(io_intReadPorts_2_0_hold), .io_intReadPorts_2_0_addr(io_intReadPorts_2_0_addr), .io_intReadPorts_2_1_hold(io_intReadPorts_2_1_hold), .io_intReadPorts_2_1_addr(io_intReadPorts_2_1_addr), .io_intReadPorts_3_0_hold(io_intReadPorts_3_0_hold), .io_intReadPorts_3_0_addr(io_intReadPorts_3_0_addr), .io_intReadPorts_3_1_hold(io_intReadPorts_3_1_hold), .io_intReadPorts_3_1_addr(io_intReadPorts_3_1_addr), .io_intReadPorts_4_0_hold(io_intReadPorts_4_0_hold), .io_intReadPorts_4_0_addr(io_intReadPorts_4_0_addr), .io_intReadPorts_4_1_hold(io_intReadPorts_4_1_hold), .io_intReadPorts_4_1_addr(io_intReadPorts_4_1_addr), .io_intReadPorts_5_0_hold(io_intReadPorts_5_0_hold), .io_intReadPorts_5_0_addr(io_intReadPorts_5_0_addr), .io_intReadPorts_5_1_hold(io_intReadPorts_5_1_hold), .io_intReadPorts_5_1_addr(io_intReadPorts_5_1_addr), .io_intRenamePorts_0_wen(io_intRenamePorts_0_wen), .io_intRenamePorts_0_addr(io_intRenamePorts_0_addr), .io_intRenamePorts_0_data(io_intRenamePorts_0_data), .io_intRenamePorts_1_wen(io_intRenamePorts_1_wen), .io_intRenamePorts_1_addr(io_intRenamePorts_1_addr), .io_intRenamePorts_1_data(io_intRenamePorts_1_data), .io_intRenamePorts_2_wen(io_intRenamePorts_2_wen), .io_intRenamePorts_2_addr(io_intRenamePorts_2_addr), .io_intRenamePorts_2_data(io_intRenamePorts_2_data), .io_intRenamePorts_3_wen(io_intRenamePorts_3_wen), .io_intRenamePorts_3_addr(io_intRenamePorts_3_addr), .io_intRenamePorts_3_data(io_intRenamePorts_3_data), .io_intRenamePorts_4_wen(io_intRenamePorts_4_wen), .io_intRenamePorts_4_addr(io_intRenamePorts_4_addr), .io_intRenamePorts_4_data(io_intRenamePorts_4_data), .io_intRenamePorts_5_wen(io_intRenamePorts_5_wen), .io_intRenamePorts_5_addr(io_intRenamePorts_5_addr), .io_intRenamePorts_5_data(io_intRenamePorts_5_data), .io_fpReadPorts_0_0_hold(io_fpReadPorts_0_0_hold), .io_fpReadPorts_0_0_addr(io_fpReadPorts_0_0_addr), .io_fpReadPorts_0_1_hold(io_fpReadPorts_0_1_hold), .io_fpReadPorts_0_1_addr(io_fpReadPorts_0_1_addr), .io_fpReadPorts_0_2_hold(io_fpReadPorts_0_2_hold), .io_fpReadPorts_0_2_addr(io_fpReadPorts_0_2_addr), .io_fpReadPorts_1_0_hold(io_fpReadPorts_1_0_hold), .io_fpReadPorts_1_0_addr(io_fpReadPorts_1_0_addr), .io_fpReadPorts_1_1_hold(io_fpReadPorts_1_1_hold), .io_fpReadPorts_1_1_addr(io_fpReadPorts_1_1_addr), .io_fpReadPorts_1_2_hold(io_fpReadPorts_1_2_hold), .io_fpReadPorts_1_2_addr(io_fpReadPorts_1_2_addr), .io_fpReadPorts_2_0_hold(io_fpReadPorts_2_0_hold), .io_fpReadPorts_2_0_addr(io_fpReadPorts_2_0_addr), .io_fpReadPorts_2_1_hold(io_fpReadPorts_2_1_hold), .io_fpReadPorts_2_1_addr(io_fpReadPorts_2_1_addr), .io_fpReadPorts_2_2_hold(io_fpReadPorts_2_2_hold), .io_fpReadPorts_2_2_addr(io_fpReadPorts_2_2_addr), .io_fpReadPorts_3_0_hold(io_fpReadPorts_3_0_hold), .io_fpReadPorts_3_0_addr(io_fpReadPorts_3_0_addr), .io_fpReadPorts_3_1_hold(io_fpReadPorts_3_1_hold), .io_fpReadPorts_3_1_addr(io_fpReadPorts_3_1_addr), .io_fpReadPorts_3_2_hold(io_fpReadPorts_3_2_hold), .io_fpReadPorts_3_2_addr(io_fpReadPorts_3_2_addr), .io_fpReadPorts_4_0_hold(io_fpReadPorts_4_0_hold), .io_fpReadPorts_4_0_addr(io_fpReadPorts_4_0_addr), .io_fpReadPorts_4_1_hold(io_fpReadPorts_4_1_hold), .io_fpReadPorts_4_1_addr(io_fpReadPorts_4_1_addr), .io_fpReadPorts_4_2_hold(io_fpReadPorts_4_2_hold), .io_fpReadPorts_4_2_addr(io_fpReadPorts_4_2_addr), .io_fpReadPorts_5_0_hold(io_fpReadPorts_5_0_hold), .io_fpReadPorts_5_0_addr(io_fpReadPorts_5_0_addr), .io_fpReadPorts_5_1_hold(io_fpReadPorts_5_1_hold), .io_fpReadPorts_5_1_addr(io_fpReadPorts_5_1_addr), .io_fpReadPorts_5_2_hold(io_fpReadPorts_5_2_hold), .io_fpReadPorts_5_2_addr(io_fpReadPorts_5_2_addr), .io_fpRenamePorts_0_wen(io_fpRenamePorts_0_wen), .io_fpRenamePorts_0_addr(io_fpRenamePorts_0_addr), .io_fpRenamePorts_0_data(io_fpRenamePorts_0_data), .io_fpRenamePorts_1_wen(io_fpRenamePorts_1_wen), .io_fpRenamePorts_1_addr(io_fpRenamePorts_1_addr), .io_fpRenamePorts_1_data(io_fpRenamePorts_1_data), .io_fpRenamePorts_2_wen(io_fpRenamePorts_2_wen), .io_fpRenamePorts_2_addr(io_fpRenamePorts_2_addr), .io_fpRenamePorts_2_data(io_fpRenamePorts_2_data), .io_fpRenamePorts_3_wen(io_fpRenamePorts_3_wen), .io_fpRenamePorts_3_addr(io_fpRenamePorts_3_addr), .io_fpRenamePorts_3_data(io_fpRenamePorts_3_data), .io_fpRenamePorts_4_wen(io_fpRenamePorts_4_wen), .io_fpRenamePorts_4_addr(io_fpRenamePorts_4_addr), .io_fpRenamePorts_4_data(io_fpRenamePorts_4_data), .io_fpRenamePorts_5_wen(io_fpRenamePorts_5_wen), .io_fpRenamePorts_5_addr(io_fpRenamePorts_5_addr), .io_fpRenamePorts_5_data(io_fpRenamePorts_5_data), .io_vecReadPorts_0_0_hold(io_vecReadPorts_0_0_hold), .io_vecReadPorts_0_0_addr(io_vecReadPorts_0_0_addr), .io_vecReadPorts_0_1_hold(io_vecReadPorts_0_1_hold), .io_vecReadPorts_0_1_addr(io_vecReadPorts_0_1_addr), .io_vecReadPorts_0_2_hold(io_vecReadPorts_0_2_hold), .io_vecReadPorts_0_2_addr(io_vecReadPorts_0_2_addr), .io_vecReadPorts_1_0_hold(io_vecReadPorts_1_0_hold), .io_vecReadPorts_1_0_addr(io_vecReadPorts_1_0_addr), .io_vecReadPorts_1_1_hold(io_vecReadPorts_1_1_hold), .io_vecReadPorts_1_1_addr(io_vecReadPorts_1_1_addr), .io_vecReadPorts_1_2_hold(io_vecReadPorts_1_2_hold), .io_vecReadPorts_1_2_addr(io_vecReadPorts_1_2_addr), .io_vecReadPorts_2_0_hold(io_vecReadPorts_2_0_hold), .io_vecReadPorts_2_0_addr(io_vecReadPorts_2_0_addr), .io_vecReadPorts_2_1_hold(io_vecReadPorts_2_1_hold), .io_vecReadPorts_2_1_addr(io_vecReadPorts_2_1_addr), .io_vecReadPorts_2_2_hold(io_vecReadPorts_2_2_hold), .io_vecReadPorts_2_2_addr(io_vecReadPorts_2_2_addr), .io_vecReadPorts_3_0_hold(io_vecReadPorts_3_0_hold), .io_vecReadPorts_3_0_addr(io_vecReadPorts_3_0_addr), .io_vecReadPorts_3_1_hold(io_vecReadPorts_3_1_hold), .io_vecReadPorts_3_1_addr(io_vecReadPorts_3_1_addr), .io_vecReadPorts_3_2_hold(io_vecReadPorts_3_2_hold), .io_vecReadPorts_3_2_addr(io_vecReadPorts_3_2_addr), .io_vecReadPorts_4_0_hold(io_vecReadPorts_4_0_hold), .io_vecReadPorts_4_0_addr(io_vecReadPorts_4_0_addr), .io_vecReadPorts_4_1_hold(io_vecReadPorts_4_1_hold), .io_vecReadPorts_4_1_addr(io_vecReadPorts_4_1_addr), .io_vecReadPorts_4_2_hold(io_vecReadPorts_4_2_hold), .io_vecReadPorts_4_2_addr(io_vecReadPorts_4_2_addr), .io_vecReadPorts_5_0_hold(io_vecReadPorts_5_0_hold), .io_vecReadPorts_5_0_addr(io_vecReadPorts_5_0_addr), .io_vecReadPorts_5_1_hold(io_vecReadPorts_5_1_hold), .io_vecReadPorts_5_1_addr(io_vecReadPorts_5_1_addr), .io_vecReadPorts_5_2_hold(io_vecReadPorts_5_2_hold), .io_vecReadPorts_5_2_addr(io_vecReadPorts_5_2_addr), .io_vecRenamePorts_0_wen(io_vecRenamePorts_0_wen), .io_vecRenamePorts_0_addr(io_vecRenamePorts_0_addr), .io_vecRenamePorts_0_data(io_vecRenamePorts_0_data), .io_vecRenamePorts_1_wen(io_vecRenamePorts_1_wen), .io_vecRenamePorts_1_addr(io_vecRenamePorts_1_addr), .io_vecRenamePorts_1_data(io_vecRenamePorts_1_data), .io_vecRenamePorts_2_wen(io_vecRenamePorts_2_wen), .io_vecRenamePorts_2_addr(io_vecRenamePorts_2_addr), .io_vecRenamePorts_2_data(io_vecRenamePorts_2_data), .io_vecRenamePorts_3_wen(io_vecRenamePorts_3_wen), .io_vecRenamePorts_3_addr(io_vecRenamePorts_3_addr), .io_vecRenamePorts_3_data(io_vecRenamePorts_3_data), .io_vecRenamePorts_4_wen(io_vecRenamePorts_4_wen), .io_vecRenamePorts_4_addr(io_vecRenamePorts_4_addr), .io_vecRenamePorts_4_data(io_vecRenamePorts_4_data), .io_vecRenamePorts_5_wen(io_vecRenamePorts_5_wen), .io_vecRenamePorts_5_addr(io_vecRenamePorts_5_addr), .io_vecRenamePorts_5_data(io_vecRenamePorts_5_data), .io_v0ReadPorts_0_hold(io_v0ReadPorts_0_hold), .io_v0ReadPorts_1_hold(io_v0ReadPorts_1_hold), .io_v0ReadPorts_2_hold(io_v0ReadPorts_2_hold), .io_v0ReadPorts_3_hold(io_v0ReadPorts_3_hold), .io_v0ReadPorts_4_hold(io_v0ReadPorts_4_hold), .io_v0ReadPorts_5_hold(io_v0ReadPorts_5_hold), .io_v0RenamePorts_0_wen(io_v0RenamePorts_0_wen), .io_v0RenamePorts_0_data(io_v0RenamePorts_0_data), .io_v0RenamePorts_1_wen(io_v0RenamePorts_1_wen), .io_v0RenamePorts_1_data(io_v0RenamePorts_1_data), .io_v0RenamePorts_2_wen(io_v0RenamePorts_2_wen), .io_v0RenamePorts_2_data(io_v0RenamePorts_2_data), .io_v0RenamePorts_3_wen(io_v0RenamePorts_3_wen), .io_v0RenamePorts_3_data(io_v0RenamePorts_3_data), .io_v0RenamePorts_4_wen(io_v0RenamePorts_4_wen), .io_v0RenamePorts_4_data(io_v0RenamePorts_4_data), .io_v0RenamePorts_5_wen(io_v0RenamePorts_5_wen), .io_v0RenamePorts_5_data(io_v0RenamePorts_5_data), .io_vlReadPorts_0_hold(io_vlReadPorts_0_hold), .io_vlReadPorts_1_hold(io_vlReadPorts_1_hold), .io_vlReadPorts_2_hold(io_vlReadPorts_2_hold), .io_vlReadPorts_3_hold(io_vlReadPorts_3_hold), .io_vlReadPorts_4_hold(io_vlReadPorts_4_hold), .io_vlReadPorts_5_hold(io_vlReadPorts_5_hold), .io_vlRenamePorts_0_wen(io_vlRenamePorts_0_wen), .io_vlRenamePorts_0_data(io_vlRenamePorts_0_data), .io_vlRenamePorts_1_wen(io_vlRenamePorts_1_wen), .io_vlRenamePorts_1_data(io_vlRenamePorts_1_data), .io_vlRenamePorts_2_wen(io_vlRenamePorts_2_wen), .io_vlRenamePorts_2_data(io_vlRenamePorts_2_data), .io_vlRenamePorts_3_wen(io_vlRenamePorts_3_wen), .io_vlRenamePorts_3_data(io_vlRenamePorts_3_data), .io_vlRenamePorts_4_wen(io_vlRenamePorts_4_wen), .io_vlRenamePorts_4_data(io_vlRenamePorts_4_data), .io_vlRenamePorts_5_wen(io_vlRenamePorts_5_wen), .io_vlRenamePorts_5_data(io_vlRenamePorts_5_data), .io_snpt_snptEnq(io_snpt_snptEnq), .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt), .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec_0(io_snpt_flushVec_0), .io_snpt_flushVec_1(io_snpt_flushVec_1), .io_snpt_flushVec_2(io_snpt_flushVec_2), .io_snpt_flushVec_3(io_snpt_flushVec_3), .io_intReadPorts_0_0_data(i_io_intReadPorts_0_0_data), .io_intReadPorts_0_1_data(i_io_intReadPorts_0_1_data), .io_intReadPorts_1_0_data(i_io_intReadPorts_1_0_data), .io_intReadPorts_1_1_data(i_io_intReadPorts_1_1_data), .io_intReadPorts_2_0_data(i_io_intReadPorts_2_0_data), .io_intReadPorts_2_1_data(i_io_intReadPorts_2_1_data), .io_intReadPorts_3_0_data(i_io_intReadPorts_3_0_data), .io_intReadPorts_3_1_data(i_io_intReadPorts_3_1_data), .io_intReadPorts_4_0_data(i_io_intReadPorts_4_0_data), .io_intReadPorts_4_1_data(i_io_intReadPorts_4_1_data), .io_intReadPorts_5_0_data(i_io_intReadPorts_5_0_data), .io_intReadPorts_5_1_data(i_io_intReadPorts_5_1_data), .io_fpReadPorts_0_0_data(i_io_fpReadPorts_0_0_data), .io_fpReadPorts_0_1_data(i_io_fpReadPorts_0_1_data), .io_fpReadPorts_0_2_data(i_io_fpReadPorts_0_2_data), .io_fpReadPorts_1_0_data(i_io_fpReadPorts_1_0_data), .io_fpReadPorts_1_1_data(i_io_fpReadPorts_1_1_data), .io_fpReadPorts_1_2_data(i_io_fpReadPorts_1_2_data), .io_fpReadPorts_2_0_data(i_io_fpReadPorts_2_0_data), .io_fpReadPorts_2_1_data(i_io_fpReadPorts_2_1_data), .io_fpReadPorts_2_2_data(i_io_fpReadPorts_2_2_data), .io_fpReadPorts_3_0_data(i_io_fpReadPorts_3_0_data), .io_fpReadPorts_3_1_data(i_io_fpReadPorts_3_1_data), .io_fpReadPorts_3_2_data(i_io_fpReadPorts_3_2_data), .io_fpReadPorts_4_0_data(i_io_fpReadPorts_4_0_data), .io_fpReadPorts_4_1_data(i_io_fpReadPorts_4_1_data), .io_fpReadPorts_4_2_data(i_io_fpReadPorts_4_2_data), .io_fpReadPorts_5_0_data(i_io_fpReadPorts_5_0_data), .io_fpReadPorts_5_1_data(i_io_fpReadPorts_5_1_data), .io_fpReadPorts_5_2_data(i_io_fpReadPorts_5_2_data), .io_vecReadPorts_0_0_data(i_io_vecReadPorts_0_0_data), .io_vecReadPorts_0_1_data(i_io_vecReadPorts_0_1_data), .io_vecReadPorts_0_2_data(i_io_vecReadPorts_0_2_data), .io_vecReadPorts_1_0_data(i_io_vecReadPorts_1_0_data), .io_vecReadPorts_1_1_data(i_io_vecReadPorts_1_1_data), .io_vecReadPorts_1_2_data(i_io_vecReadPorts_1_2_data), .io_vecReadPorts_2_0_data(i_io_vecReadPorts_2_0_data), .io_vecReadPorts_2_1_data(i_io_vecReadPorts_2_1_data), .io_vecReadPorts_2_2_data(i_io_vecReadPorts_2_2_data), .io_vecReadPorts_3_0_data(i_io_vecReadPorts_3_0_data), .io_vecReadPorts_3_1_data(i_io_vecReadPorts_3_1_data), .io_vecReadPorts_3_2_data(i_io_vecReadPorts_3_2_data), .io_vecReadPorts_4_0_data(i_io_vecReadPorts_4_0_data), .io_vecReadPorts_4_1_data(i_io_vecReadPorts_4_1_data), .io_vecReadPorts_4_2_data(i_io_vecReadPorts_4_2_data), .io_vecReadPorts_5_0_data(i_io_vecReadPorts_5_0_data), .io_vecReadPorts_5_1_data(i_io_vecReadPorts_5_1_data), .io_vecReadPorts_5_2_data(i_io_vecReadPorts_5_2_data), .io_v0ReadPorts_0_data(i_io_v0ReadPorts_0_data), .io_v0ReadPorts_1_data(i_io_v0ReadPorts_1_data), .io_v0ReadPorts_2_data(i_io_v0ReadPorts_2_data), .io_v0ReadPorts_3_data(i_io_v0ReadPorts_3_data), .io_v0ReadPorts_4_data(i_io_v0ReadPorts_4_data), .io_v0ReadPorts_5_data(i_io_v0ReadPorts_5_data), .io_vlReadPorts_0_data(i_io_vlReadPorts_0_data), .io_vlReadPorts_1_data(i_io_vlReadPorts_1_data), .io_vlReadPorts_2_data(i_io_vlReadPorts_2_data), .io_vlReadPorts_3_data(i_io_vlReadPorts_3_data), .io_vlReadPorts_4_data(i_io_vlReadPorts_4_data), .io_vlReadPorts_5_data(i_io_vlReadPorts_5_data), .io_int_old_pdest_0(i_io_int_old_pdest_0), .io_int_old_pdest_1(i_io_int_old_pdest_1), .io_int_old_pdest_2(i_io_int_old_pdest_2), .io_int_old_pdest_3(i_io_int_old_pdest_3), .io_int_old_pdest_4(i_io_int_old_pdest_4), .io_int_old_pdest_5(i_io_int_old_pdest_5), .io_fp_old_pdest_0(i_io_fp_old_pdest_0), .io_fp_old_pdest_1(i_io_fp_old_pdest_1), .io_fp_old_pdest_2(i_io_fp_old_pdest_2), .io_fp_old_pdest_3(i_io_fp_old_pdest_3), .io_fp_old_pdest_4(i_io_fp_old_pdest_4), .io_fp_old_pdest_5(i_io_fp_old_pdest_5), .io_vec_old_pdest_0(i_io_vec_old_pdest_0), .io_vec_old_pdest_1(i_io_vec_old_pdest_1), .io_vec_old_pdest_2(i_io_vec_old_pdest_2), .io_vec_old_pdest_3(i_io_vec_old_pdest_3), .io_vec_old_pdest_4(i_io_vec_old_pdest_4), .io_vec_old_pdest_5(i_io_vec_old_pdest_5), .io_v0_old_pdest_0(i_io_v0_old_pdest_0), .io_v0_old_pdest_1(i_io_v0_old_pdest_1), .io_v0_old_pdest_2(i_io_v0_old_pdest_2), .io_v0_old_pdest_3(i_io_v0_old_pdest_3), .io_v0_old_pdest_4(i_io_v0_old_pdest_4), .io_v0_old_pdest_5(i_io_v0_old_pdest_5), .io_vl_old_pdest_0(i_io_vl_old_pdest_0), .io_vl_old_pdest_1(i_io_vl_old_pdest_1), .io_vl_old_pdest_2(i_io_vl_old_pdest_2), .io_vl_old_pdest_3(i_io_vl_old_pdest_3), .io_vl_old_pdest_4(i_io_vl_old_pdest_4), .io_vl_old_pdest_5(i_io_vl_old_pdest_5), .io_int_need_free_0(i_io_int_need_free_0), .io_int_need_free_1(i_io_int_need_free_1), .io_int_need_free_2(i_io_int_need_free_2), .io_int_need_free_3(i_io_int_need_free_3), .io_int_need_free_4(i_io_int_need_free_4), .io_int_need_free_5(i_io_int_need_free_5), .io_debug_int_rat_0(i_io_debug_int_rat_0), .io_debug_int_rat_1(i_io_debug_int_rat_1), .io_debug_int_rat_2(i_io_debug_int_rat_2), .io_debug_int_rat_3(i_io_debug_int_rat_3), .io_debug_int_rat_4(i_io_debug_int_rat_4), .io_debug_int_rat_5(i_io_debug_int_rat_5), .io_debug_int_rat_6(i_io_debug_int_rat_6), .io_debug_int_rat_7(i_io_debug_int_rat_7), .io_debug_int_rat_8(i_io_debug_int_rat_8), .io_debug_int_rat_9(i_io_debug_int_rat_9), .io_debug_int_rat_10(i_io_debug_int_rat_10), .io_debug_int_rat_11(i_io_debug_int_rat_11), .io_debug_int_rat_12(i_io_debug_int_rat_12), .io_debug_int_rat_13(i_io_debug_int_rat_13), .io_debug_int_rat_14(i_io_debug_int_rat_14), .io_debug_int_rat_15(i_io_debug_int_rat_15), .io_debug_int_rat_16(i_io_debug_int_rat_16), .io_debug_int_rat_17(i_io_debug_int_rat_17), .io_debug_int_rat_18(i_io_debug_int_rat_18), .io_debug_int_rat_19(i_io_debug_int_rat_19), .io_debug_int_rat_20(i_io_debug_int_rat_20), .io_debug_int_rat_21(i_io_debug_int_rat_21), .io_debug_int_rat_22(i_io_debug_int_rat_22), .io_debug_int_rat_23(i_io_debug_int_rat_23), .io_debug_int_rat_24(i_io_debug_int_rat_24), .io_debug_int_rat_25(i_io_debug_int_rat_25), .io_debug_int_rat_26(i_io_debug_int_rat_26), .io_debug_int_rat_27(i_io_debug_int_rat_27), .io_debug_int_rat_28(i_io_debug_int_rat_28), .io_debug_int_rat_29(i_io_debug_int_rat_29), .io_debug_int_rat_30(i_io_debug_int_rat_30), .io_debug_int_rat_31(i_io_debug_int_rat_31), .io_diff_vl_rat_0(i_io_diff_vl_rat_0), .gatewayIn_packed_23_bore(i_gatewayIn_packed_23_bore), .gatewayIn_packed_24_bore(i_gatewayIn_packed_24_bore), .gatewayIn_packed_25_bore(i_gatewayIn_packed_25_bore));

  // robIdx 取小池子（0..15）：写快照与提交读命中同一批槽，且落在合法范围内（< RobSize=160）
  function automatic logic [7:0] rnd_rob(); return 8'($urandom_range(0, 15)); endfunction
  task automatic drive_random();
    io_hartId = 8'($urandom);
    io_redirect = (cyc < WARM) ? 1'b0 : ($urandom_range(0, 99) < 3);
    io_rabCommits_isCommit = ($urandom_range(0, 99) < 45);
    io_rabCommits_commitValid_0 = ($urandom_range(0, 99) < 40);
    io_rabCommits_commitValid_1 = ($urandom_range(0, 99) < 40);
    io_rabCommits_commitValid_2 = ($urandom_range(0, 99) < 40);
    io_rabCommits_commitValid_3 = ($urandom_range(0, 99) < 40);
    io_rabCommits_commitValid_4 = ($urandom_range(0, 99) < 40);
    io_rabCommits_commitValid_5 = ($urandom_range(0, 99) < 40);
    io_rabCommits_isWalk = ($urandom_range(0, 99) < 25);
    io_rabCommits_walkValid_0 = ($urandom_range(0, 99) < 40);
    io_rabCommits_walkValid_1 = ($urandom_range(0, 99) < 40);
    io_rabCommits_walkValid_2 = ($urandom_range(0, 99) < 40);
    io_rabCommits_walkValid_3 = ($urandom_range(0, 99) < 40);
    io_rabCommits_walkValid_4 = ($urandom_range(0, 99) < 40);
    io_rabCommits_walkValid_5 = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_0_ldest = 6'($urandom);
    io_rabCommits_info_0_pdest = 8'($urandom);
    io_rabCommits_info_0_rfWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_0_fpWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_0_vecWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_0_v0Wen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_0_vlWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_1_ldest = 6'($urandom);
    io_rabCommits_info_1_pdest = 8'($urandom);
    io_rabCommits_info_1_rfWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_1_fpWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_1_vecWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_1_v0Wen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_1_vlWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_2_ldest = 6'($urandom);
    io_rabCommits_info_2_pdest = 8'($urandom);
    io_rabCommits_info_2_rfWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_2_fpWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_2_vecWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_2_v0Wen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_2_vlWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_3_ldest = 6'($urandom);
    io_rabCommits_info_3_pdest = 8'($urandom);
    io_rabCommits_info_3_rfWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_3_fpWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_3_vecWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_3_v0Wen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_3_vlWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_4_ldest = 6'($urandom);
    io_rabCommits_info_4_pdest = 8'($urandom);
    io_rabCommits_info_4_rfWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_4_fpWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_4_vecWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_4_v0Wen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_4_vlWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_5_ldest = 6'($urandom);
    io_rabCommits_info_5_pdest = 8'($urandom);
    io_rabCommits_info_5_rfWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_5_fpWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_5_vecWen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_5_v0Wen = ($urandom_range(0, 99) < 40);
    io_rabCommits_info_5_vlWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_0_valid = ($urandom_range(0, 99) < 40);
    io_renameUpdates_0_bits_robIdx_flag = ($urandom_range(0, 99) < 10);
    io_renameUpdates_0_bits_robIdx_value = rnd_rob();
    io_renameUpdates_0_bits_lastUop = ($urandom_range(0, 99) < 40);
    io_renameUpdates_0_bits_ldest = 6'($urandom);
    io_renameUpdates_0_bits_pdest = 8'($urandom);
    io_renameUpdates_0_bits_rfWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_0_bits_fpWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_0_bits_vecWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_0_bits_v0Wen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_0_bits_vlWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_1_valid = ($urandom_range(0, 99) < 40);
    io_renameUpdates_1_bits_robIdx_flag = ($urandom_range(0, 99) < 10);
    io_renameUpdates_1_bits_robIdx_value = rnd_rob();
    io_renameUpdates_1_bits_lastUop = ($urandom_range(0, 99) < 40);
    io_renameUpdates_1_bits_ldest = 6'($urandom);
    io_renameUpdates_1_bits_pdest = 8'($urandom);
    io_renameUpdates_1_bits_rfWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_1_bits_fpWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_1_bits_vecWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_1_bits_v0Wen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_1_bits_vlWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_2_valid = ($urandom_range(0, 99) < 40);
    io_renameUpdates_2_bits_robIdx_flag = ($urandom_range(0, 99) < 10);
    io_renameUpdates_2_bits_robIdx_value = rnd_rob();
    io_renameUpdates_2_bits_lastUop = ($urandom_range(0, 99) < 40);
    io_renameUpdates_2_bits_ldest = 6'($urandom);
    io_renameUpdates_2_bits_pdest = 8'($urandom);
    io_renameUpdates_2_bits_rfWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_2_bits_fpWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_2_bits_vecWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_2_bits_v0Wen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_2_bits_vlWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_3_valid = ($urandom_range(0, 99) < 40);
    io_renameUpdates_3_bits_robIdx_flag = ($urandom_range(0, 99) < 10);
    io_renameUpdates_3_bits_robIdx_value = rnd_rob();
    io_renameUpdates_3_bits_lastUop = ($urandom_range(0, 99) < 40);
    io_renameUpdates_3_bits_ldest = 6'($urandom);
    io_renameUpdates_3_bits_pdest = 8'($urandom);
    io_renameUpdates_3_bits_rfWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_3_bits_fpWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_3_bits_vecWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_3_bits_v0Wen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_3_bits_vlWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_4_valid = ($urandom_range(0, 99) < 40);
    io_renameUpdates_4_bits_robIdx_flag = ($urandom_range(0, 99) < 10);
    io_renameUpdates_4_bits_robIdx_value = rnd_rob();
    io_renameUpdates_4_bits_lastUop = ($urandom_range(0, 99) < 40);
    io_renameUpdates_4_bits_ldest = 6'($urandom);
    io_renameUpdates_4_bits_pdest = 8'($urandom);
    io_renameUpdates_4_bits_rfWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_4_bits_fpWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_4_bits_vecWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_4_bits_v0Wen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_4_bits_vlWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_5_valid = ($urandom_range(0, 99) < 40);
    io_renameUpdates_5_bits_robIdx_flag = ($urandom_range(0, 99) < 10);
    io_renameUpdates_5_bits_robIdx_value = rnd_rob();
    io_renameUpdates_5_bits_lastUop = ($urandom_range(0, 99) < 40);
    io_renameUpdates_5_bits_ldest = 6'($urandom);
    io_renameUpdates_5_bits_pdest = 8'($urandom);
    io_renameUpdates_5_bits_rfWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_5_bits_fpWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_5_bits_vecWen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_5_bits_v0Wen = ($urandom_range(0, 99) < 40);
    io_renameUpdates_5_bits_vlWen = ($urandom_range(0, 99) < 40);
    io_diffRatCommitRobIdx_valid = ($urandom_range(0, 99) < 30);
    io_diffRatCommitRobIdx_bits_flag = ($urandom_range(0, 99) < 10);
    io_diffRatCommitRobIdx_bits_value = 8'($urandom);
    io_intReadPorts_0_0_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_0_0_addr = 32'($urandom);
    io_intReadPorts_0_1_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_0_1_addr = 32'($urandom);
    io_intReadPorts_1_0_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_1_0_addr = 32'($urandom);
    io_intReadPorts_1_1_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_1_1_addr = 32'($urandom);
    io_intReadPorts_2_0_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_2_0_addr = 32'($urandom);
    io_intReadPorts_2_1_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_2_1_addr = 32'($urandom);
    io_intReadPorts_3_0_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_3_0_addr = 32'($urandom);
    io_intReadPorts_3_1_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_3_1_addr = 32'($urandom);
    io_intReadPorts_4_0_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_4_0_addr = 32'($urandom);
    io_intReadPorts_4_1_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_4_1_addr = 32'($urandom);
    io_intReadPorts_5_0_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_5_0_addr = 32'($urandom);
    io_intReadPorts_5_1_hold = ($urandom_range(0, 99) < 40);
    io_intReadPorts_5_1_addr = 32'($urandom);
    io_intRenamePorts_0_wen = ($urandom_range(0, 99) < 40);
    io_intRenamePorts_0_addr = 32'($urandom);
    io_intRenamePorts_0_data = 8'($urandom);
    io_intRenamePorts_1_wen = ($urandom_range(0, 99) < 40);
    io_intRenamePorts_1_addr = 32'($urandom);
    io_intRenamePorts_1_data = 8'($urandom);
    io_intRenamePorts_2_wen = ($urandom_range(0, 99) < 40);
    io_intRenamePorts_2_addr = 32'($urandom);
    io_intRenamePorts_2_data = 8'($urandom);
    io_intRenamePorts_3_wen = ($urandom_range(0, 99) < 40);
    io_intRenamePorts_3_addr = 32'($urandom);
    io_intRenamePorts_3_data = 8'($urandom);
    io_intRenamePorts_4_wen = ($urandom_range(0, 99) < 40);
    io_intRenamePorts_4_addr = 32'($urandom);
    io_intRenamePorts_4_data = 8'($urandom);
    io_intRenamePorts_5_wen = ($urandom_range(0, 99) < 40);
    io_intRenamePorts_5_addr = 32'($urandom);
    io_intRenamePorts_5_data = 8'($urandom);
    io_fpReadPorts_0_0_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_0_0_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_0_1_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_0_1_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_0_2_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_0_2_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_1_0_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_1_0_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_1_1_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_1_1_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_1_2_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_1_2_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_2_0_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_2_0_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_2_1_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_2_1_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_2_2_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_2_2_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_3_0_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_3_0_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_3_1_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_3_1_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_3_2_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_3_2_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_4_0_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_4_0_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_4_1_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_4_1_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_4_2_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_4_2_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_5_0_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_5_0_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_5_1_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_5_1_addr = 34'({$urandom(), $urandom()});
    io_fpReadPorts_5_2_hold = ($urandom_range(0, 99) < 40);
    io_fpReadPorts_5_2_addr = 34'({$urandom(), $urandom()});
    io_fpRenamePorts_0_wen = ($urandom_range(0, 99) < 40);
    io_fpRenamePorts_0_addr = 34'({$urandom(), $urandom()});
    io_fpRenamePorts_0_data = 8'($urandom);
    io_fpRenamePorts_1_wen = ($urandom_range(0, 99) < 40);
    io_fpRenamePorts_1_addr = 34'({$urandom(), $urandom()});
    io_fpRenamePorts_1_data = 8'($urandom);
    io_fpRenamePorts_2_wen = ($urandom_range(0, 99) < 40);
    io_fpRenamePorts_2_addr = 34'({$urandom(), $urandom()});
    io_fpRenamePorts_2_data = 8'($urandom);
    io_fpRenamePorts_3_wen = ($urandom_range(0, 99) < 40);
    io_fpRenamePorts_3_addr = 34'({$urandom(), $urandom()});
    io_fpRenamePorts_3_data = 8'($urandom);
    io_fpRenamePorts_4_wen = ($urandom_range(0, 99) < 40);
    io_fpRenamePorts_4_addr = 34'({$urandom(), $urandom()});
    io_fpRenamePorts_4_data = 8'($urandom);
    io_fpRenamePorts_5_wen = ($urandom_range(0, 99) < 40);
    io_fpRenamePorts_5_addr = 34'({$urandom(), $urandom()});
    io_fpRenamePorts_5_data = 8'($urandom);
    io_vecReadPorts_0_0_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_0_0_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_0_1_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_0_1_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_0_2_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_0_2_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_1_0_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_1_0_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_1_1_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_1_1_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_1_2_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_1_2_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_2_0_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_2_0_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_2_1_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_2_1_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_2_2_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_2_2_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_3_0_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_3_0_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_3_1_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_3_1_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_3_2_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_3_2_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_4_0_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_4_0_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_4_1_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_4_1_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_4_2_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_4_2_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_5_0_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_5_0_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_5_1_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_5_1_addr = 47'({$urandom(), $urandom()});
    io_vecReadPorts_5_2_hold = ($urandom_range(0, 99) < 40);
    io_vecReadPorts_5_2_addr = 47'({$urandom(), $urandom()});
    io_vecRenamePorts_0_wen = ($urandom_range(0, 99) < 40);
    io_vecRenamePorts_0_addr = 47'({$urandom(), $urandom()});
    io_vecRenamePorts_0_data = 8'($urandom);
    io_vecRenamePorts_1_wen = ($urandom_range(0, 99) < 40);
    io_vecRenamePorts_1_addr = 47'({$urandom(), $urandom()});
    io_vecRenamePorts_1_data = 8'($urandom);
    io_vecRenamePorts_2_wen = ($urandom_range(0, 99) < 40);
    io_vecRenamePorts_2_addr = 47'({$urandom(), $urandom()});
    io_vecRenamePorts_2_data = 8'($urandom);
    io_vecRenamePorts_3_wen = ($urandom_range(0, 99) < 40);
    io_vecRenamePorts_3_addr = 47'({$urandom(), $urandom()});
    io_vecRenamePorts_3_data = 8'($urandom);
    io_vecRenamePorts_4_wen = ($urandom_range(0, 99) < 40);
    io_vecRenamePorts_4_addr = 47'({$urandom(), $urandom()});
    io_vecRenamePorts_4_data = 8'($urandom);
    io_vecRenamePorts_5_wen = ($urandom_range(0, 99) < 40);
    io_vecRenamePorts_5_addr = 47'({$urandom(), $urandom()});
    io_vecRenamePorts_5_data = 8'($urandom);
    io_v0ReadPorts_0_hold = ($urandom_range(0, 99) < 40);
    io_v0ReadPorts_1_hold = ($urandom_range(0, 99) < 40);
    io_v0ReadPorts_2_hold = ($urandom_range(0, 99) < 40);
    io_v0ReadPorts_3_hold = ($urandom_range(0, 99) < 40);
    io_v0ReadPorts_4_hold = ($urandom_range(0, 99) < 40);
    io_v0ReadPorts_5_hold = ($urandom_range(0, 99) < 40);
    io_v0RenamePorts_0_wen = ($urandom_range(0, 99) < 40);
    io_v0RenamePorts_0_data = 8'($urandom);
    io_v0RenamePorts_1_wen = ($urandom_range(0, 99) < 40);
    io_v0RenamePorts_1_data = 8'($urandom);
    io_v0RenamePorts_2_wen = ($urandom_range(0, 99) < 40);
    io_v0RenamePorts_2_data = 8'($urandom);
    io_v0RenamePorts_3_wen = ($urandom_range(0, 99) < 40);
    io_v0RenamePorts_3_data = 8'($urandom);
    io_v0RenamePorts_4_wen = ($urandom_range(0, 99) < 40);
    io_v0RenamePorts_4_data = 8'($urandom);
    io_v0RenamePorts_5_wen = ($urandom_range(0, 99) < 40);
    io_v0RenamePorts_5_data = 8'($urandom);
    io_vlReadPorts_0_hold = ($urandom_range(0, 99) < 40);
    io_vlReadPorts_1_hold = ($urandom_range(0, 99) < 40);
    io_vlReadPorts_2_hold = ($urandom_range(0, 99) < 40);
    io_vlReadPorts_3_hold = ($urandom_range(0, 99) < 40);
    io_vlReadPorts_4_hold = ($urandom_range(0, 99) < 40);
    io_vlReadPorts_5_hold = ($urandom_range(0, 99) < 40);
    io_vlRenamePorts_0_wen = ($urandom_range(0, 99) < 40);
    io_vlRenamePorts_0_data = 8'($urandom);
    io_vlRenamePorts_1_wen = ($urandom_range(0, 99) < 40);
    io_vlRenamePorts_1_data = 8'($urandom);
    io_vlRenamePorts_2_wen = ($urandom_range(0, 99) < 40);
    io_vlRenamePorts_2_data = 8'($urandom);
    io_vlRenamePorts_3_wen = ($urandom_range(0, 99) < 40);
    io_vlRenamePorts_3_data = 8'($urandom);
    io_vlRenamePorts_4_wen = ($urandom_range(0, 99) < 40);
    io_vlRenamePorts_4_data = 8'($urandom);
    io_vlRenamePorts_5_wen = ($urandom_range(0, 99) < 40);
    io_vlRenamePorts_5_data = 8'($urandom);
    io_snpt_snptEnq = (cyc < WARM) ? 1'b1 : ($urandom_range(0, 99) < 15);
    io_snpt_snptDeq = (cyc < WARM) ? 1'b0 : ($urandom_range(0, 99) < 15);
    io_snpt_useSnpt = (cyc < WARM) ? 1'b0 : ($urandom_range(0, 99) < 20);
    io_snpt_snptSelect = 2'($urandom);
    io_snpt_flushVec_0 = ($urandom_range(0, 99) < 40);
    io_snpt_flushVec_1 = ($urandom_range(0, 99) < 40);
    io_snpt_flushVec_2 = ($urandom_range(0, 99) < 40);
    io_snpt_flushVec_3 = ($urandom_range(0, 99) < 40);
  endtask

  always @(negedge clk) if (!rst && cyc > WARM + 4) begin
    #4; checks++;
    if (g_io_intReadPorts_0_0_data !== i_io_intReadPorts_0_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_0_0_data g=%h i=%h", $time, g_io_intReadPorts_0_0_data, i_io_intReadPorts_0_0_data); end
    if (g_io_intReadPorts_0_1_data !== i_io_intReadPorts_0_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_0_1_data g=%h i=%h", $time, g_io_intReadPorts_0_1_data, i_io_intReadPorts_0_1_data); end
    if (g_io_intReadPorts_1_0_data !== i_io_intReadPorts_1_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_1_0_data g=%h i=%h", $time, g_io_intReadPorts_1_0_data, i_io_intReadPorts_1_0_data); end
    if (g_io_intReadPorts_1_1_data !== i_io_intReadPorts_1_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_1_1_data g=%h i=%h", $time, g_io_intReadPorts_1_1_data, i_io_intReadPorts_1_1_data); end
    if (g_io_intReadPorts_2_0_data !== i_io_intReadPorts_2_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_2_0_data g=%h i=%h", $time, g_io_intReadPorts_2_0_data, i_io_intReadPorts_2_0_data); end
    if (g_io_intReadPorts_2_1_data !== i_io_intReadPorts_2_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_2_1_data g=%h i=%h", $time, g_io_intReadPorts_2_1_data, i_io_intReadPorts_2_1_data); end
    if (g_io_intReadPorts_3_0_data !== i_io_intReadPorts_3_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_3_0_data g=%h i=%h", $time, g_io_intReadPorts_3_0_data, i_io_intReadPorts_3_0_data); end
    if (g_io_intReadPorts_3_1_data !== i_io_intReadPorts_3_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_3_1_data g=%h i=%h", $time, g_io_intReadPorts_3_1_data, i_io_intReadPorts_3_1_data); end
    if (g_io_intReadPorts_4_0_data !== i_io_intReadPorts_4_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_4_0_data g=%h i=%h", $time, g_io_intReadPorts_4_0_data, i_io_intReadPorts_4_0_data); end
    if (g_io_intReadPorts_4_1_data !== i_io_intReadPorts_4_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_4_1_data g=%h i=%h", $time, g_io_intReadPorts_4_1_data, i_io_intReadPorts_4_1_data); end
    if (g_io_intReadPorts_5_0_data !== i_io_intReadPorts_5_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_5_0_data g=%h i=%h", $time, g_io_intReadPorts_5_0_data, i_io_intReadPorts_5_0_data); end
    if (g_io_intReadPorts_5_1_data !== i_io_intReadPorts_5_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_intReadPorts_5_1_data g=%h i=%h", $time, g_io_intReadPorts_5_1_data, i_io_intReadPorts_5_1_data); end
    if (g_io_fpReadPorts_0_0_data !== i_io_fpReadPorts_0_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_0_0_data g=%h i=%h", $time, g_io_fpReadPorts_0_0_data, i_io_fpReadPorts_0_0_data); end
    if (g_io_fpReadPorts_0_1_data !== i_io_fpReadPorts_0_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_0_1_data g=%h i=%h", $time, g_io_fpReadPorts_0_1_data, i_io_fpReadPorts_0_1_data); end
    if (g_io_fpReadPorts_0_2_data !== i_io_fpReadPorts_0_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_0_2_data g=%h i=%h", $time, g_io_fpReadPorts_0_2_data, i_io_fpReadPorts_0_2_data); end
    if (g_io_fpReadPorts_1_0_data !== i_io_fpReadPorts_1_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_1_0_data g=%h i=%h", $time, g_io_fpReadPorts_1_0_data, i_io_fpReadPorts_1_0_data); end
    if (g_io_fpReadPorts_1_1_data !== i_io_fpReadPorts_1_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_1_1_data g=%h i=%h", $time, g_io_fpReadPorts_1_1_data, i_io_fpReadPorts_1_1_data); end
    if (g_io_fpReadPorts_1_2_data !== i_io_fpReadPorts_1_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_1_2_data g=%h i=%h", $time, g_io_fpReadPorts_1_2_data, i_io_fpReadPorts_1_2_data); end
    if (g_io_fpReadPorts_2_0_data !== i_io_fpReadPorts_2_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_2_0_data g=%h i=%h", $time, g_io_fpReadPorts_2_0_data, i_io_fpReadPorts_2_0_data); end
    if (g_io_fpReadPorts_2_1_data !== i_io_fpReadPorts_2_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_2_1_data g=%h i=%h", $time, g_io_fpReadPorts_2_1_data, i_io_fpReadPorts_2_1_data); end
    if (g_io_fpReadPorts_2_2_data !== i_io_fpReadPorts_2_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_2_2_data g=%h i=%h", $time, g_io_fpReadPorts_2_2_data, i_io_fpReadPorts_2_2_data); end
    if (g_io_fpReadPorts_3_0_data !== i_io_fpReadPorts_3_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_3_0_data g=%h i=%h", $time, g_io_fpReadPorts_3_0_data, i_io_fpReadPorts_3_0_data); end
    if (g_io_fpReadPorts_3_1_data !== i_io_fpReadPorts_3_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_3_1_data g=%h i=%h", $time, g_io_fpReadPorts_3_1_data, i_io_fpReadPorts_3_1_data); end
    if (g_io_fpReadPorts_3_2_data !== i_io_fpReadPorts_3_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_3_2_data g=%h i=%h", $time, g_io_fpReadPorts_3_2_data, i_io_fpReadPorts_3_2_data); end
    if (g_io_fpReadPorts_4_0_data !== i_io_fpReadPorts_4_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_4_0_data g=%h i=%h", $time, g_io_fpReadPorts_4_0_data, i_io_fpReadPorts_4_0_data); end
    if (g_io_fpReadPorts_4_1_data !== i_io_fpReadPorts_4_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_4_1_data g=%h i=%h", $time, g_io_fpReadPorts_4_1_data, i_io_fpReadPorts_4_1_data); end
    if (g_io_fpReadPorts_4_2_data !== i_io_fpReadPorts_4_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_4_2_data g=%h i=%h", $time, g_io_fpReadPorts_4_2_data, i_io_fpReadPorts_4_2_data); end
    if (g_io_fpReadPorts_5_0_data !== i_io_fpReadPorts_5_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_5_0_data g=%h i=%h", $time, g_io_fpReadPorts_5_0_data, i_io_fpReadPorts_5_0_data); end
    if (g_io_fpReadPorts_5_1_data !== i_io_fpReadPorts_5_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_5_1_data g=%h i=%h", $time, g_io_fpReadPorts_5_1_data, i_io_fpReadPorts_5_1_data); end
    if (g_io_fpReadPorts_5_2_data !== i_io_fpReadPorts_5_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_fpReadPorts_5_2_data g=%h i=%h", $time, g_io_fpReadPorts_5_2_data, i_io_fpReadPorts_5_2_data); end
    if (g_io_vecReadPorts_0_0_data !== i_io_vecReadPorts_0_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_0_0_data g=%h i=%h", $time, g_io_vecReadPorts_0_0_data, i_io_vecReadPorts_0_0_data); end
    if (g_io_vecReadPorts_0_1_data !== i_io_vecReadPorts_0_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_0_1_data g=%h i=%h", $time, g_io_vecReadPorts_0_1_data, i_io_vecReadPorts_0_1_data); end
    if (g_io_vecReadPorts_0_2_data !== i_io_vecReadPorts_0_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_0_2_data g=%h i=%h", $time, g_io_vecReadPorts_0_2_data, i_io_vecReadPorts_0_2_data); end
    if (g_io_vecReadPorts_1_0_data !== i_io_vecReadPorts_1_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_1_0_data g=%h i=%h", $time, g_io_vecReadPorts_1_0_data, i_io_vecReadPorts_1_0_data); end
    if (g_io_vecReadPorts_1_1_data !== i_io_vecReadPorts_1_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_1_1_data g=%h i=%h", $time, g_io_vecReadPorts_1_1_data, i_io_vecReadPorts_1_1_data); end
    if (g_io_vecReadPorts_1_2_data !== i_io_vecReadPorts_1_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_1_2_data g=%h i=%h", $time, g_io_vecReadPorts_1_2_data, i_io_vecReadPorts_1_2_data); end
    if (g_io_vecReadPorts_2_0_data !== i_io_vecReadPorts_2_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_2_0_data g=%h i=%h", $time, g_io_vecReadPorts_2_0_data, i_io_vecReadPorts_2_0_data); end
    if (g_io_vecReadPorts_2_1_data !== i_io_vecReadPorts_2_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_2_1_data g=%h i=%h", $time, g_io_vecReadPorts_2_1_data, i_io_vecReadPorts_2_1_data); end
    if (g_io_vecReadPorts_2_2_data !== i_io_vecReadPorts_2_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_2_2_data g=%h i=%h", $time, g_io_vecReadPorts_2_2_data, i_io_vecReadPorts_2_2_data); end
    if (g_io_vecReadPorts_3_0_data !== i_io_vecReadPorts_3_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_3_0_data g=%h i=%h", $time, g_io_vecReadPorts_3_0_data, i_io_vecReadPorts_3_0_data); end
    if (g_io_vecReadPorts_3_1_data !== i_io_vecReadPorts_3_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_3_1_data g=%h i=%h", $time, g_io_vecReadPorts_3_1_data, i_io_vecReadPorts_3_1_data); end
    if (g_io_vecReadPorts_3_2_data !== i_io_vecReadPorts_3_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_3_2_data g=%h i=%h", $time, g_io_vecReadPorts_3_2_data, i_io_vecReadPorts_3_2_data); end
    if (g_io_vecReadPorts_4_0_data !== i_io_vecReadPorts_4_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_4_0_data g=%h i=%h", $time, g_io_vecReadPorts_4_0_data, i_io_vecReadPorts_4_0_data); end
    if (g_io_vecReadPorts_4_1_data !== i_io_vecReadPorts_4_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_4_1_data g=%h i=%h", $time, g_io_vecReadPorts_4_1_data, i_io_vecReadPorts_4_1_data); end
    if (g_io_vecReadPorts_4_2_data !== i_io_vecReadPorts_4_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_4_2_data g=%h i=%h", $time, g_io_vecReadPorts_4_2_data, i_io_vecReadPorts_4_2_data); end
    if (g_io_vecReadPorts_5_0_data !== i_io_vecReadPorts_5_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_5_0_data g=%h i=%h", $time, g_io_vecReadPorts_5_0_data, i_io_vecReadPorts_5_0_data); end
    if (g_io_vecReadPorts_5_1_data !== i_io_vecReadPorts_5_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_5_1_data g=%h i=%h", $time, g_io_vecReadPorts_5_1_data, i_io_vecReadPorts_5_1_data); end
    if (g_io_vecReadPorts_5_2_data !== i_io_vecReadPorts_5_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_vecReadPorts_5_2_data g=%h i=%h", $time, g_io_vecReadPorts_5_2_data, i_io_vecReadPorts_5_2_data); end
    if (g_io_v0ReadPorts_0_data !== i_io_v0ReadPorts_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_v0ReadPorts_0_data g=%h i=%h", $time, g_io_v0ReadPorts_0_data, i_io_v0ReadPorts_0_data); end
    if (g_io_v0ReadPorts_1_data !== i_io_v0ReadPorts_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_v0ReadPorts_1_data g=%h i=%h", $time, g_io_v0ReadPorts_1_data, i_io_v0ReadPorts_1_data); end
    if (g_io_v0ReadPorts_2_data !== i_io_v0ReadPorts_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_v0ReadPorts_2_data g=%h i=%h", $time, g_io_v0ReadPorts_2_data, i_io_v0ReadPorts_2_data); end
    if (g_io_v0ReadPorts_3_data !== i_io_v0ReadPorts_3_data) begin errors++; if (errors <= 40) $display("[%0t] io_v0ReadPorts_3_data g=%h i=%h", $time, g_io_v0ReadPorts_3_data, i_io_v0ReadPorts_3_data); end
    if (g_io_v0ReadPorts_4_data !== i_io_v0ReadPorts_4_data) begin errors++; if (errors <= 40) $display("[%0t] io_v0ReadPorts_4_data g=%h i=%h", $time, g_io_v0ReadPorts_4_data, i_io_v0ReadPorts_4_data); end
    if (g_io_v0ReadPorts_5_data !== i_io_v0ReadPorts_5_data) begin errors++; if (errors <= 40) $display("[%0t] io_v0ReadPorts_5_data g=%h i=%h", $time, g_io_v0ReadPorts_5_data, i_io_v0ReadPorts_5_data); end
    if (g_io_vlReadPorts_0_data !== i_io_vlReadPorts_0_data) begin errors++; if (errors <= 40) $display("[%0t] io_vlReadPorts_0_data g=%h i=%h", $time, g_io_vlReadPorts_0_data, i_io_vlReadPorts_0_data); end
    if (g_io_vlReadPorts_1_data !== i_io_vlReadPorts_1_data) begin errors++; if (errors <= 40) $display("[%0t] io_vlReadPorts_1_data g=%h i=%h", $time, g_io_vlReadPorts_1_data, i_io_vlReadPorts_1_data); end
    if (g_io_vlReadPorts_2_data !== i_io_vlReadPorts_2_data) begin errors++; if (errors <= 40) $display("[%0t] io_vlReadPorts_2_data g=%h i=%h", $time, g_io_vlReadPorts_2_data, i_io_vlReadPorts_2_data); end
    if (g_io_vlReadPorts_3_data !== i_io_vlReadPorts_3_data) begin errors++; if (errors <= 40) $display("[%0t] io_vlReadPorts_3_data g=%h i=%h", $time, g_io_vlReadPorts_3_data, i_io_vlReadPorts_3_data); end
    if (g_io_vlReadPorts_4_data !== i_io_vlReadPorts_4_data) begin errors++; if (errors <= 40) $display("[%0t] io_vlReadPorts_4_data g=%h i=%h", $time, g_io_vlReadPorts_4_data, i_io_vlReadPorts_4_data); end
    if (g_io_vlReadPorts_5_data !== i_io_vlReadPorts_5_data) begin errors++; if (errors <= 40) $display("[%0t] io_vlReadPorts_5_data g=%h i=%h", $time, g_io_vlReadPorts_5_data, i_io_vlReadPorts_5_data); end
    if (g_io_int_old_pdest_0 !== i_io_int_old_pdest_0) begin errors++; if (errors <= 40) $display("[%0t] io_int_old_pdest_0 g=%h i=%h", $time, g_io_int_old_pdest_0, i_io_int_old_pdest_0); end
    if (g_io_int_old_pdest_1 !== i_io_int_old_pdest_1) begin errors++; if (errors <= 40) $display("[%0t] io_int_old_pdest_1 g=%h i=%h", $time, g_io_int_old_pdest_1, i_io_int_old_pdest_1); end
    if (g_io_int_old_pdest_2 !== i_io_int_old_pdest_2) begin errors++; if (errors <= 40) $display("[%0t] io_int_old_pdest_2 g=%h i=%h", $time, g_io_int_old_pdest_2, i_io_int_old_pdest_2); end
    if (g_io_int_old_pdest_3 !== i_io_int_old_pdest_3) begin errors++; if (errors <= 40) $display("[%0t] io_int_old_pdest_3 g=%h i=%h", $time, g_io_int_old_pdest_3, i_io_int_old_pdest_3); end
    if (g_io_int_old_pdest_4 !== i_io_int_old_pdest_4) begin errors++; if (errors <= 40) $display("[%0t] io_int_old_pdest_4 g=%h i=%h", $time, g_io_int_old_pdest_4, i_io_int_old_pdest_4); end
    if (g_io_int_old_pdest_5 !== i_io_int_old_pdest_5) begin errors++; if (errors <= 40) $display("[%0t] io_int_old_pdest_5 g=%h i=%h", $time, g_io_int_old_pdest_5, i_io_int_old_pdest_5); end
    if (g_io_fp_old_pdest_0 !== i_io_fp_old_pdest_0) begin errors++; if (errors <= 40) $display("[%0t] io_fp_old_pdest_0 g=%h i=%h", $time, g_io_fp_old_pdest_0, i_io_fp_old_pdest_0); end
    if (g_io_fp_old_pdest_1 !== i_io_fp_old_pdest_1) begin errors++; if (errors <= 40) $display("[%0t] io_fp_old_pdest_1 g=%h i=%h", $time, g_io_fp_old_pdest_1, i_io_fp_old_pdest_1); end
    if (g_io_fp_old_pdest_2 !== i_io_fp_old_pdest_2) begin errors++; if (errors <= 40) $display("[%0t] io_fp_old_pdest_2 g=%h i=%h", $time, g_io_fp_old_pdest_2, i_io_fp_old_pdest_2); end
    if (g_io_fp_old_pdest_3 !== i_io_fp_old_pdest_3) begin errors++; if (errors <= 40) $display("[%0t] io_fp_old_pdest_3 g=%h i=%h", $time, g_io_fp_old_pdest_3, i_io_fp_old_pdest_3); end
    if (g_io_fp_old_pdest_4 !== i_io_fp_old_pdest_4) begin errors++; if (errors <= 40) $display("[%0t] io_fp_old_pdest_4 g=%h i=%h", $time, g_io_fp_old_pdest_4, i_io_fp_old_pdest_4); end
    if (g_io_fp_old_pdest_5 !== i_io_fp_old_pdest_5) begin errors++; if (errors <= 40) $display("[%0t] io_fp_old_pdest_5 g=%h i=%h", $time, g_io_fp_old_pdest_5, i_io_fp_old_pdest_5); end
    if (g_io_vec_old_pdest_0 !== i_io_vec_old_pdest_0) begin errors++; if (errors <= 40) $display("[%0t] io_vec_old_pdest_0 g=%h i=%h", $time, g_io_vec_old_pdest_0, i_io_vec_old_pdest_0); end
    if (g_io_vec_old_pdest_1 !== i_io_vec_old_pdest_1) begin errors++; if (errors <= 40) $display("[%0t] io_vec_old_pdest_1 g=%h i=%h", $time, g_io_vec_old_pdest_1, i_io_vec_old_pdest_1); end
    if (g_io_vec_old_pdest_2 !== i_io_vec_old_pdest_2) begin errors++; if (errors <= 40) $display("[%0t] io_vec_old_pdest_2 g=%h i=%h", $time, g_io_vec_old_pdest_2, i_io_vec_old_pdest_2); end
    if (g_io_vec_old_pdest_3 !== i_io_vec_old_pdest_3) begin errors++; if (errors <= 40) $display("[%0t] io_vec_old_pdest_3 g=%h i=%h", $time, g_io_vec_old_pdest_3, i_io_vec_old_pdest_3); end
    if (g_io_vec_old_pdest_4 !== i_io_vec_old_pdest_4) begin errors++; if (errors <= 40) $display("[%0t] io_vec_old_pdest_4 g=%h i=%h", $time, g_io_vec_old_pdest_4, i_io_vec_old_pdest_4); end
    if (g_io_vec_old_pdest_5 !== i_io_vec_old_pdest_5) begin errors++; if (errors <= 40) $display("[%0t] io_vec_old_pdest_5 g=%h i=%h", $time, g_io_vec_old_pdest_5, i_io_vec_old_pdest_5); end
    if (g_io_v0_old_pdest_0 !== i_io_v0_old_pdest_0) begin errors++; if (errors <= 40) $display("[%0t] io_v0_old_pdest_0 g=%h i=%h", $time, g_io_v0_old_pdest_0, i_io_v0_old_pdest_0); end
    if (g_io_v0_old_pdest_1 !== i_io_v0_old_pdest_1) begin errors++; if (errors <= 40) $display("[%0t] io_v0_old_pdest_1 g=%h i=%h", $time, g_io_v0_old_pdest_1, i_io_v0_old_pdest_1); end
    if (g_io_v0_old_pdest_2 !== i_io_v0_old_pdest_2) begin errors++; if (errors <= 40) $display("[%0t] io_v0_old_pdest_2 g=%h i=%h", $time, g_io_v0_old_pdest_2, i_io_v0_old_pdest_2); end
    if (g_io_v0_old_pdest_3 !== i_io_v0_old_pdest_3) begin errors++; if (errors <= 40) $display("[%0t] io_v0_old_pdest_3 g=%h i=%h", $time, g_io_v0_old_pdest_3, i_io_v0_old_pdest_3); end
    if (g_io_v0_old_pdest_4 !== i_io_v0_old_pdest_4) begin errors++; if (errors <= 40) $display("[%0t] io_v0_old_pdest_4 g=%h i=%h", $time, g_io_v0_old_pdest_4, i_io_v0_old_pdest_4); end
    if (g_io_v0_old_pdest_5 !== i_io_v0_old_pdest_5) begin errors++; if (errors <= 40) $display("[%0t] io_v0_old_pdest_5 g=%h i=%h", $time, g_io_v0_old_pdest_5, i_io_v0_old_pdest_5); end
    if (g_io_vl_old_pdest_0 !== i_io_vl_old_pdest_0) begin errors++; if (errors <= 40) $display("[%0t] io_vl_old_pdest_0 g=%h i=%h", $time, g_io_vl_old_pdest_0, i_io_vl_old_pdest_0); end
    if (g_io_vl_old_pdest_1 !== i_io_vl_old_pdest_1) begin errors++; if (errors <= 40) $display("[%0t] io_vl_old_pdest_1 g=%h i=%h", $time, g_io_vl_old_pdest_1, i_io_vl_old_pdest_1); end
    if (g_io_vl_old_pdest_2 !== i_io_vl_old_pdest_2) begin errors++; if (errors <= 40) $display("[%0t] io_vl_old_pdest_2 g=%h i=%h", $time, g_io_vl_old_pdest_2, i_io_vl_old_pdest_2); end
    if (g_io_vl_old_pdest_3 !== i_io_vl_old_pdest_3) begin errors++; if (errors <= 40) $display("[%0t] io_vl_old_pdest_3 g=%h i=%h", $time, g_io_vl_old_pdest_3, i_io_vl_old_pdest_3); end
    if (g_io_vl_old_pdest_4 !== i_io_vl_old_pdest_4) begin errors++; if (errors <= 40) $display("[%0t] io_vl_old_pdest_4 g=%h i=%h", $time, g_io_vl_old_pdest_4, i_io_vl_old_pdest_4); end
    if (g_io_vl_old_pdest_5 !== i_io_vl_old_pdest_5) begin errors++; if (errors <= 40) $display("[%0t] io_vl_old_pdest_5 g=%h i=%h", $time, g_io_vl_old_pdest_5, i_io_vl_old_pdest_5); end
    if (g_io_int_need_free_0 !== i_io_int_need_free_0) begin errors++; if (errors <= 40) $display("[%0t] io_int_need_free_0 g=%h i=%h", $time, g_io_int_need_free_0, i_io_int_need_free_0); end
    if (g_io_int_need_free_1 !== i_io_int_need_free_1) begin errors++; if (errors <= 40) $display("[%0t] io_int_need_free_1 g=%h i=%h", $time, g_io_int_need_free_1, i_io_int_need_free_1); end
    if (g_io_int_need_free_2 !== i_io_int_need_free_2) begin errors++; if (errors <= 40) $display("[%0t] io_int_need_free_2 g=%h i=%h", $time, g_io_int_need_free_2, i_io_int_need_free_2); end
    if (g_io_int_need_free_3 !== i_io_int_need_free_3) begin errors++; if (errors <= 40) $display("[%0t] io_int_need_free_3 g=%h i=%h", $time, g_io_int_need_free_3, i_io_int_need_free_3); end
    if (g_io_int_need_free_4 !== i_io_int_need_free_4) begin errors++; if (errors <= 40) $display("[%0t] io_int_need_free_4 g=%h i=%h", $time, g_io_int_need_free_4, i_io_int_need_free_4); end
    if (g_io_int_need_free_5 !== i_io_int_need_free_5) begin errors++; if (errors <= 40) $display("[%0t] io_int_need_free_5 g=%h i=%h", $time, g_io_int_need_free_5, i_io_int_need_free_5); end
    if (g_io_debug_int_rat_0 !== i_io_debug_int_rat_0) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_0 g=%h i=%h", $time, g_io_debug_int_rat_0, i_io_debug_int_rat_0); end
    if (g_io_debug_int_rat_1 !== i_io_debug_int_rat_1) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_1 g=%h i=%h", $time, g_io_debug_int_rat_1, i_io_debug_int_rat_1); end
    if (g_io_debug_int_rat_2 !== i_io_debug_int_rat_2) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_2 g=%h i=%h", $time, g_io_debug_int_rat_2, i_io_debug_int_rat_2); end
    if (g_io_debug_int_rat_3 !== i_io_debug_int_rat_3) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_3 g=%h i=%h", $time, g_io_debug_int_rat_3, i_io_debug_int_rat_3); end
    if (g_io_debug_int_rat_4 !== i_io_debug_int_rat_4) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_4 g=%h i=%h", $time, g_io_debug_int_rat_4, i_io_debug_int_rat_4); end
    if (g_io_debug_int_rat_5 !== i_io_debug_int_rat_5) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_5 g=%h i=%h", $time, g_io_debug_int_rat_5, i_io_debug_int_rat_5); end
    if (g_io_debug_int_rat_6 !== i_io_debug_int_rat_6) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_6 g=%h i=%h", $time, g_io_debug_int_rat_6, i_io_debug_int_rat_6); end
    if (g_io_debug_int_rat_7 !== i_io_debug_int_rat_7) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_7 g=%h i=%h", $time, g_io_debug_int_rat_7, i_io_debug_int_rat_7); end
    if (g_io_debug_int_rat_8 !== i_io_debug_int_rat_8) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_8 g=%h i=%h", $time, g_io_debug_int_rat_8, i_io_debug_int_rat_8); end
    if (g_io_debug_int_rat_9 !== i_io_debug_int_rat_9) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_9 g=%h i=%h", $time, g_io_debug_int_rat_9, i_io_debug_int_rat_9); end
    if (g_io_debug_int_rat_10 !== i_io_debug_int_rat_10) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_10 g=%h i=%h", $time, g_io_debug_int_rat_10, i_io_debug_int_rat_10); end
    if (g_io_debug_int_rat_11 !== i_io_debug_int_rat_11) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_11 g=%h i=%h", $time, g_io_debug_int_rat_11, i_io_debug_int_rat_11); end
    if (g_io_debug_int_rat_12 !== i_io_debug_int_rat_12) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_12 g=%h i=%h", $time, g_io_debug_int_rat_12, i_io_debug_int_rat_12); end
    if (g_io_debug_int_rat_13 !== i_io_debug_int_rat_13) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_13 g=%h i=%h", $time, g_io_debug_int_rat_13, i_io_debug_int_rat_13); end
    if (g_io_debug_int_rat_14 !== i_io_debug_int_rat_14) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_14 g=%h i=%h", $time, g_io_debug_int_rat_14, i_io_debug_int_rat_14); end
    if (g_io_debug_int_rat_15 !== i_io_debug_int_rat_15) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_15 g=%h i=%h", $time, g_io_debug_int_rat_15, i_io_debug_int_rat_15); end
    if (g_io_debug_int_rat_16 !== i_io_debug_int_rat_16) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_16 g=%h i=%h", $time, g_io_debug_int_rat_16, i_io_debug_int_rat_16); end
    if (g_io_debug_int_rat_17 !== i_io_debug_int_rat_17) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_17 g=%h i=%h", $time, g_io_debug_int_rat_17, i_io_debug_int_rat_17); end
    if (g_io_debug_int_rat_18 !== i_io_debug_int_rat_18) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_18 g=%h i=%h", $time, g_io_debug_int_rat_18, i_io_debug_int_rat_18); end
    if (g_io_debug_int_rat_19 !== i_io_debug_int_rat_19) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_19 g=%h i=%h", $time, g_io_debug_int_rat_19, i_io_debug_int_rat_19); end
    if (g_io_debug_int_rat_20 !== i_io_debug_int_rat_20) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_20 g=%h i=%h", $time, g_io_debug_int_rat_20, i_io_debug_int_rat_20); end
    if (g_io_debug_int_rat_21 !== i_io_debug_int_rat_21) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_21 g=%h i=%h", $time, g_io_debug_int_rat_21, i_io_debug_int_rat_21); end
    if (g_io_debug_int_rat_22 !== i_io_debug_int_rat_22) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_22 g=%h i=%h", $time, g_io_debug_int_rat_22, i_io_debug_int_rat_22); end
    if (g_io_debug_int_rat_23 !== i_io_debug_int_rat_23) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_23 g=%h i=%h", $time, g_io_debug_int_rat_23, i_io_debug_int_rat_23); end
    if (g_io_debug_int_rat_24 !== i_io_debug_int_rat_24) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_24 g=%h i=%h", $time, g_io_debug_int_rat_24, i_io_debug_int_rat_24); end
    if (g_io_debug_int_rat_25 !== i_io_debug_int_rat_25) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_25 g=%h i=%h", $time, g_io_debug_int_rat_25, i_io_debug_int_rat_25); end
    if (g_io_debug_int_rat_26 !== i_io_debug_int_rat_26) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_26 g=%h i=%h", $time, g_io_debug_int_rat_26, i_io_debug_int_rat_26); end
    if (g_io_debug_int_rat_27 !== i_io_debug_int_rat_27) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_27 g=%h i=%h", $time, g_io_debug_int_rat_27, i_io_debug_int_rat_27); end
    if (g_io_debug_int_rat_28 !== i_io_debug_int_rat_28) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_28 g=%h i=%h", $time, g_io_debug_int_rat_28, i_io_debug_int_rat_28); end
    if (g_io_debug_int_rat_29 !== i_io_debug_int_rat_29) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_29 g=%h i=%h", $time, g_io_debug_int_rat_29, i_io_debug_int_rat_29); end
    if (g_io_debug_int_rat_30 !== i_io_debug_int_rat_30) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_30 g=%h i=%h", $time, g_io_debug_int_rat_30, i_io_debug_int_rat_30); end
    if (g_io_debug_int_rat_31 !== i_io_debug_int_rat_31) begin errors++; if (errors <= 40) $display("[%0t] io_debug_int_rat_31 g=%h i=%h", $time, g_io_debug_int_rat_31, i_io_debug_int_rat_31); end
    if (g_io_diff_vl_rat_0 !== i_io_diff_vl_rat_0) begin errors++; if (errors <= 40) $display("[%0t] io_diff_vl_rat_0 g=%h i=%h", $time, g_io_diff_vl_rat_0, i_io_diff_vl_rat_0); end
    if (g_gatewayIn_packed_23_bore !== i_gatewayIn_packed_23_bore) begin errors++; if (errors <= 40) $display("[%0t] gatewayIn_packed_23_bore g=%h i=%h", $time, g_gatewayIn_packed_23_bore, i_gatewayIn_packed_23_bore); end
    if (g_gatewayIn_packed_24_bore !== i_gatewayIn_packed_24_bore) begin errors++; if (errors <= 40) $display("[%0t] gatewayIn_packed_24_bore g=%h i=%h", $time, g_gatewayIn_packed_24_bore, i_gatewayIn_packed_24_bore); end
    if (g_gatewayIn_packed_25_bore !== i_gatewayIn_packed_25_bore) begin errors++; if (errors <= 40) $display("[%0t] gatewayIn_packed_25_bore g=%h i=%h", $time, g_gatewayIn_packed_25_bore, i_gatewayIn_packed_25_bore); end
    if (io_rabCommits_isCommit && io_rabCommits_commitValid_0 && io_rabCommits_info_0_rfWen) cov_commit++;
    if (io_rabCommits_isWalk && io_rabCommits_walkValid_0 && !io_intRenamePorts_0_wen) cov_walk++;
    if (io_intRenamePorts_0_wen) cov_rn++;
    if (g_u.diffRatBuffer.readValid) cov_diffrd++;
    if (io_snpt_useSnpt) cov_snpt++;
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    drive_random();
    rst = 1; repeat (4) @(posedge clk); @(negedge clk) rst = 0;
    for (int unsigned n = 0; n < NCYCLES; n++) begin drive_random(); @(negedge clk); end
    $display("--- COVERAGE (每项必须 > 0) ---");
    $display("  int 架构表提交写      : %0d", cov_commit);
    $display("  walk 回滚写(无 rename): %0d", cov_walk);
    $display("  rename 写口           : %0d", cov_rn);
    $display("  difftest 快照读回     : %0d", cov_diffrd);
    $display("  useSnpt               : %0d", cov_snpt);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_commit > 0 && cov_walk > 0 && cov_rn > 0 && cov_diffrd > 0 && cov_snpt > 0)
      $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
