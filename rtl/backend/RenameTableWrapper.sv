// =============================================================================
// RenameTableWrapper.sv —— 五张重命名表（int/fp/vec/v0/vl）的装配壳 + difftest 快照
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/rename/RenameTable.scala（class RenameTableWrapper）
// golden 对照: G1-canonical/golden-rtl/RenameTableWrapper.sv（2,249 行 / 455 端口）
// 层次位置: SimTop…backend.inner.ctrlBlock.rename.renameTableWrapper
//
// ★ 它是什么 ★
// 把 Rename 的读/写请求分发给五张 RenameTable（已签核可读件：RenameTable=int、_1=fp、
// _2=vec、_3=v0 与 vl 共用），并给每张表生成两组写口：
//   arch（架构表）：RAB 提交（isCommit & commitValid[i] & 该类 xxWen），addr=ldest，data=pdest
//   spec（推测表）：rename 写口优先（wen 时用 rename 的 addr/data），否则 RAB walk
//                  （isWalk & walkValid[i] & xxWen）回滚 ldest/pdest
// 另把五张表的架构基线送进 DiffRatStateBuffer 做提交序快照，快照结果打包成三条 difftest
// bore（DiffArchIntRenameTable / Fp / Vec）：
//   int/fp：32 项 × 8 位 + coreid(hartId)；
//   vec：v0Rat[0] 与 vecRat[i]+V0PhyRegs(22) 共 32 项，每项拆成 (r<<1, (r<<1)+1) 两个 9 位值
//        （128 位向量寄存器按 64 位一半各一个号）+ coreid。
//
// ★ golden 事实 ★
//   - 本层无寄存器；除 XSError 断言（SYNTHESIS 下不存在）外全是组合连线。
//   - int 读口地址输入 32 位、fp 34 位、vec 47 位，但表只用低 5/6/6 位（其余位无消费者）。
//   - v0/vl 表只有 1 个逻辑寄存器：读/写地址端口不存在。
//   - debug 输出只剩 int（debug_int_rat[32]）与 diff_vl_rat（来自 DiffRatStateBuffer）；
//     fp/vec 的 debug_rdata、fp/vec/vl 的 need_free 无消费者，不接。
// =============================================================================
// 本文件导航（共 2088 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L35    renametablewrapper_pkg —— 参数与 rab_info_t / rat_write_t
//   L69    xs_RenameTableWrapper_core —— 端口表（数组化的读/写口）
//   L147   每张表的两组写口（arch 提交 / spec rename 优先否则 walk）
//   L187   生成区：五张 RenameTable + DiffRatStateBuffer 例化（scripts/gen_renametablewrapper.py）
//   L1066  difftest bore 打包（int/fp 32 项、vec 拆 64 个 9 位值）
//   L1083  生成区：golden 同名 wrapper（455 端口逐字来自 golden）

package renametablewrapper_pkg;
  localparam int unsigned RENAME_W   = 6;    // RenameWidth = RabCommitWidth = DecodeWidth
  localparam int unsigned PREG_W     = 8;
  localparam int unsigned LDEST_W    = 6;
  localparam int unsigned INT_ADDR_W = 5;    // log2(IntLogicRegs=32)
  localparam int unsigned FP_ADDR_W  = 6;    // log2(FpLogicRegs=34)
  localparam int unsigned VEC_ADDR_W = 6;    // log2(VecLogicRegs=47)
  localparam int unsigned INT_RD_W   = 32;   // RatReadPort(IntLogicRegs).addr 端口位宽
  localparam int unsigned FP_RD_W    = 34;
  localparam int unsigned VEC_RD_W   = 47;
  localparam int unsigned INT_RD_N   = 2;    // 每条 rename 通道的读口数
  localparam int unsigned FP_RD_N    = 3;
  localparam int unsigned VEC_RD_N   = 3;
  localparam int unsigned INT_N      = 32;   // difftest 快照项数
  localparam int unsigned FP_N       = 32;
  localparam int unsigned VEC_N      = 31;
  localparam int unsigned V0_PHY_N   = 22;   // V0PhyRegs：vec 物理号在 difftest 里的偏移
  localparam int unsigned SNPT_N     = 4;

  // RAB 提交/回滚信息里本模块用到的字段
  typedef struct packed {
    logic [LDEST_W-1:0] ldest;
    logic [PREG_W-1:0]  pdest;
    logic rfWen, fpWen, vecWen, v0Wen, vlWen;
  } rab_info_t;

  // 一张表的一组写口（arch 或 spec）
  typedef struct packed {
    logic               wen;
    logic [LDEST_W-1:0] addr;   // 各表按自己的地址位宽截取
    logic [PREG_W-1:0]  data;
  } rat_write_t;
endpackage

module xs_RenameTableWrapper_core
  import renametablewrapper_pkg::*;
(
  input  logic                     clock,
  input  logic                     reset,
  input  logic [7:0]               hartId,
  input  logic                     redirect,
  // RAB 提交/回滚
  input  logic                     rab_isCommit,
  input  logic                     rab_isWalk,
  input  logic [RENAME_W-1:0]      rab_commitValid,
  input  logic [RENAME_W-1:0]      rab_walkValid,
  input  rab_info_t [RENAME_W-1:0] rab_info,
  // difftest 快照的 rename 更新（直通 DiffRatStateBuffer）
  input  logic [RENAME_W-1:0]              renameUpdates_valid,
  input  logic [RENAME_W-1:0]              renameUpdates_robIdx_flag,
  input  logic [RENAME_W-1:0][PREG_W-1:0]  renameUpdates_robIdx_value,
  input  logic [RENAME_W-1:0]              renameUpdates_lastUop,
  input  logic [RENAME_W-1:0][LDEST_W-1:0] renameUpdates_ldest,
  input  logic [RENAME_W-1:0][PREG_W-1:0]  renameUpdates_pdest,
  input  logic [RENAME_W-1:0]              renameUpdates_rfWen,
  input  logic [RENAME_W-1:0]              renameUpdates_fpWen,
  input  logic [RENAME_W-1:0]              renameUpdates_vecWen,
  input  logic [RENAME_W-1:0]              renameUpdates_v0Wen,
  input  logic [RENAME_W-1:0]              renameUpdates_vlWen,
  input  logic                     diffRatCommitRobIdx_valid,
  input  logic                     diffRatCommitRobIdx_flag,
  input  logic [PREG_W-1:0]        diffRatCommitRobIdx_value,
  // 快照端口（五张表共用）
  input  logic                     snpt_snptEnq,
  input  logic                     snpt_snptDeq,
  input  logic                     snpt_useSnpt,
  input  logic [1:0]               snpt_snptSelect,
  input  logic [SNPT_N-1:0]        snpt_flushVec,
  // 读口
  input  logic [RENAME_W-1:0][INT_RD_N-1:0][INT_RD_W-1:0] int_rd_addr,
  input  logic [RENAME_W-1:0][INT_RD_N-1:0]               int_rd_hold,
  output logic [RENAME_W-1:0][INT_RD_N-1:0][PREG_W-1:0]   int_rd_data,
  input  logic [RENAME_W-1:0][FP_RD_N-1:0][FP_RD_W-1:0]   fp_rd_addr,
  input  logic [RENAME_W-1:0][FP_RD_N-1:0]                fp_rd_hold,
  output logic [RENAME_W-1:0][FP_RD_N-1:0][PREG_W-1:0]    fp_rd_data,
  input  logic [RENAME_W-1:0][VEC_RD_N-1:0][VEC_RD_W-1:0] vec_rd_addr,
  input  logic [RENAME_W-1:0][VEC_RD_N-1:0]               vec_rd_hold,
  output logic [RENAME_W-1:0][VEC_RD_N-1:0][PREG_W-1:0]   vec_rd_data,
  input  logic [RENAME_W-1:0]                             v0_rd_hold,
  output logic [RENAME_W-1:0][PREG_W-1:0]                 v0_rd_data,
  input  logic [RENAME_W-1:0]                             vl_rd_hold,
  output logic [RENAME_W-1:0][PREG_W-1:0]                 vl_rd_data,
  // rename 写口（推测表）
  input  logic [RENAME_W-1:0]                 int_rn_wen,
  input  logic [RENAME_W-1:0][INT_RD_W-1:0]   int_rn_addr,
  input  logic [RENAME_W-1:0][PREG_W-1:0]     int_rn_data,
  input  logic [RENAME_W-1:0]                 fp_rn_wen,
  input  logic [RENAME_W-1:0][FP_RD_W-1:0]    fp_rn_addr,
  input  logic [RENAME_W-1:0][PREG_W-1:0]     fp_rn_data,
  input  logic [RENAME_W-1:0]                 vec_rn_wen,
  input  logic [RENAME_W-1:0][VEC_RD_W-1:0]   vec_rn_addr,
  input  logic [RENAME_W-1:0][PREG_W-1:0]     vec_rn_data,
  input  logic [RENAME_W-1:0]                 v0_rn_wen,
  input  logic [RENAME_W-1:0][PREG_W-1:0]     v0_rn_data,
  input  logic [RENAME_W-1:0]                 vl_rn_wen,
  input  logic [RENAME_W-1:0][PREG_W-1:0]     vl_rn_data,
  // 旧物理号 / 释放
  output logic [RENAME_W-1:0][PREG_W-1:0]     int_old_pdest,
  output logic [RENAME_W-1:0][PREG_W-1:0]     fp_old_pdest,
  output logic [RENAME_W-1:0][PREG_W-1:0]     vec_old_pdest,
  output logic [RENAME_W-1:0][PREG_W-1:0]     v0_old_pdest,
  output logic [RENAME_W-1:0][PREG_W-1:0]     vl_old_pdest,
  output logic [RENAME_W-1:0]                 int_need_free,
  // debug / difftest
  output logic [INT_N-1:0][PREG_W-1:0]        debug_int_rat,
  output logic [PREG_W-1:0]                   diff_vl_rat,
  output logic [INT_N*PREG_W+8-1:0]           difftest_rat_xrf,   // gatewayIn_packed_23_bore
  output logic [FP_N*PREG_W+8-1:0]            difftest_rat_frf,   // gatewayIn_packed_24_bore
  output logic [2*(1+VEC_N)*9+8-1:0]          difftest_rat_vrf    // gatewayIn_packed_25_bore
);

  // ---------------------------------------------------------------------------
  // 每张表的两组写口
  // ---------------------------------------------------------------------------
  rat_write_t [RENAME_W-1:0] int_arch, int_spec, fp_arch, fp_spec, vec_arch, vec_spec,
                             v0_arch, v0_spec, vl_arch, vl_spec;

  function automatic rat_write_t arch_port(input logic commit_hit, input rab_info_t info);
    arch_port = '{wen: commit_hit, addr: info.ldest, data: info.pdest};
  endfunction
  // rename 写口优先；否则 walk 回滚
  function automatic rat_write_t spec_port(input logic walk_hit, input rab_info_t info,
                                           input logic rn_wen, input logic [LDEST_W-1:0] rn_addr,
                                           input logic [PREG_W-1:0] rn_data);
    spec_port = '{wen:  rn_wen | walk_hit,
                  addr: rn_wen ? rn_addr : info.ldest,
                  data: rn_wen ? rn_data : info.pdest};
  endfunction

  always_comb
    for (int i = 0; i < RENAME_W; i++) begin
      logic commit_i, walk_i;
      commit_i = rab_isCommit & rab_commitValid[i];
      walk_i   = rab_isWalk   & rab_walkValid[i];
      int_arch[i] = arch_port(commit_i & rab_info[i].rfWen,  rab_info[i]);
      fp_arch[i]  = arch_port(commit_i & rab_info[i].fpWen,  rab_info[i]);
      vec_arch[i] = arch_port(commit_i & rab_info[i].vecWen, rab_info[i]);
      v0_arch[i]  = arch_port(commit_i & rab_info[i].v0Wen,  rab_info[i]);
      vl_arch[i]  = arch_port(commit_i & rab_info[i].vlWen,  rab_info[i]);
      int_spec[i] = spec_port(walk_i & rab_info[i].rfWen,  rab_info[i], int_rn_wen[i], int_rn_addr[i][LDEST_W-1:0], int_rn_data[i]);
      fp_spec[i]  = spec_port(walk_i & rab_info[i].fpWen,  rab_info[i], fp_rn_wen[i],  fp_rn_addr[i][LDEST_W-1:0],  fp_rn_data[i]);
      vec_spec[i] = spec_port(walk_i & rab_info[i].vecWen, rab_info[i], vec_rn_wen[i], vec_rn_addr[i][LDEST_W-1:0], vec_rn_data[i]);
      v0_spec[i]  = spec_port(walk_i & rab_info[i].v0Wen,  rab_info[i], v0_rn_wen[i],  '0, v0_rn_data[i]);
      vl_spec[i]  = spec_port(walk_i & rab_info[i].vlWen,  rab_info[i], vl_rn_wen[i],  '0, vl_rn_data[i]);
    end

  // 五张表的架构基线（送 difftest 快照）与快照读回
  logic [INT_N-1:0][PREG_W-1:0] int_diffRatBase, diffRat_int;
  logic [FP_N-1:0][PREG_W-1:0]  fp_diffRatBase,  diffRat_fp;
  logic [VEC_N-1:0][PREG_W-1:0] vec_diffRatBase, diffRat_vec;
  logic [PREG_W-1:0]            v0_diffRatBase,  diffRat_v0, vl_diffRatBase;

  // BEGIN GENERATED(rtw_instances) —— 由 scripts/gen_renametablewrapper.py 从 golden 端口表产出
  // 五张重命名表（已签核可读件，golden 同名变体）与 difftest 快照缓冲
  RenameTable intRat (
    .clock                     (clock),
    .reset                     (reset),
    .io_redirect               (redirect),
    .io_readPorts_0_hold       (int_rd_hold[0][0]),
    .io_readPorts_0_addr       (int_rd_addr[0][0][4:0]),
    .io_readPorts_0_data       (int_rd_data[0][0]),
    .io_readPorts_1_hold       (int_rd_hold[0][1]),
    .io_readPorts_1_addr       (int_rd_addr[0][1][4:0]),
    .io_readPorts_1_data       (int_rd_data[0][1]),
    .io_readPorts_2_hold       (int_rd_hold[1][0]),
    .io_readPorts_2_addr       (int_rd_addr[1][0][4:0]),
    .io_readPorts_2_data       (int_rd_data[1][0]),
    .io_readPorts_3_hold       (int_rd_hold[1][1]),
    .io_readPorts_3_addr       (int_rd_addr[1][1][4:0]),
    .io_readPorts_3_data       (int_rd_data[1][1]),
    .io_readPorts_4_hold       (int_rd_hold[2][0]),
    .io_readPorts_4_addr       (int_rd_addr[2][0][4:0]),
    .io_readPorts_4_data       (int_rd_data[2][0]),
    .io_readPorts_5_hold       (int_rd_hold[2][1]),
    .io_readPorts_5_addr       (int_rd_addr[2][1][4:0]),
    .io_readPorts_5_data       (int_rd_data[2][1]),
    .io_readPorts_6_hold       (int_rd_hold[3][0]),
    .io_readPorts_6_addr       (int_rd_addr[3][0][4:0]),
    .io_readPorts_6_data       (int_rd_data[3][0]),
    .io_readPorts_7_hold       (int_rd_hold[3][1]),
    .io_readPorts_7_addr       (int_rd_addr[3][1][4:0]),
    .io_readPorts_7_data       (int_rd_data[3][1]),
    .io_readPorts_8_hold       (int_rd_hold[4][0]),
    .io_readPorts_8_addr       (int_rd_addr[4][0][4:0]),
    .io_readPorts_8_data       (int_rd_data[4][0]),
    .io_readPorts_9_hold       (int_rd_hold[4][1]),
    .io_readPorts_9_addr       (int_rd_addr[4][1][4:0]),
    .io_readPorts_9_data       (int_rd_data[4][1]),
    .io_readPorts_10_hold      (int_rd_hold[5][0]),
    .io_readPorts_10_addr      (int_rd_addr[5][0][4:0]),
    .io_readPorts_10_data      (int_rd_data[5][0]),
    .io_readPorts_11_hold      (int_rd_hold[5][1]),
    .io_readPorts_11_addr      (int_rd_addr[5][1][4:0]),
    .io_readPorts_11_data      (int_rd_data[5][1]),
    .io_specWritePorts_0_wen   (int_spec[0].wen),
    .io_specWritePorts_0_addr  (int_spec[0].addr[4:0]),
    .io_specWritePorts_0_data  (int_spec[0].data),
    .io_specWritePorts_1_wen   (int_spec[1].wen),
    .io_specWritePorts_1_addr  (int_spec[1].addr[4:0]),
    .io_specWritePorts_1_data  (int_spec[1].data),
    .io_specWritePorts_2_wen   (int_spec[2].wen),
    .io_specWritePorts_2_addr  (int_spec[2].addr[4:0]),
    .io_specWritePorts_2_data  (int_spec[2].data),
    .io_specWritePorts_3_wen   (int_spec[3].wen),
    .io_specWritePorts_3_addr  (int_spec[3].addr[4:0]),
    .io_specWritePorts_3_data  (int_spec[3].data),
    .io_specWritePorts_4_wen   (int_spec[4].wen),
    .io_specWritePorts_4_addr  (int_spec[4].addr[4:0]),
    .io_specWritePorts_4_data  (int_spec[4].data),
    .io_specWritePorts_5_wen   (int_spec[5].wen),
    .io_specWritePorts_5_addr  (int_spec[5].addr[4:0]),
    .io_specWritePorts_5_data  (int_spec[5].data),
    .io_archWritePorts_0_wen   (int_arch[0].wen),
    .io_archWritePorts_0_addr  (int_arch[0].addr[4:0]),
    .io_archWritePorts_0_data  (int_arch[0].data),
    .io_archWritePorts_1_wen   (int_arch[1].wen),
    .io_archWritePorts_1_addr  (int_arch[1].addr[4:0]),
    .io_archWritePorts_1_data  (int_arch[1].data),
    .io_archWritePorts_2_wen   (int_arch[2].wen),
    .io_archWritePorts_2_addr  (int_arch[2].addr[4:0]),
    .io_archWritePorts_2_data  (int_arch[2].data),
    .io_archWritePorts_3_wen   (int_arch[3].wen),
    .io_archWritePorts_3_addr  (int_arch[3].addr[4:0]),
    .io_archWritePorts_3_data  (int_arch[3].data),
    .io_archWritePorts_4_wen   (int_arch[4].wen),
    .io_archWritePorts_4_addr  (int_arch[4].addr[4:0]),
    .io_archWritePorts_4_data  (int_arch[4].data),
    .io_archWritePorts_5_wen   (int_arch[5].wen),
    .io_archWritePorts_5_addr  (int_arch[5].addr[4:0]),
    .io_archWritePorts_5_data  (int_arch[5].data),
    .io_old_pdest_0            (int_old_pdest[0]),
    .io_old_pdest_1            (int_old_pdest[1]),
    .io_old_pdest_2            (int_old_pdest[2]),
    .io_old_pdest_3            (int_old_pdest[3]),
    .io_old_pdest_4            (int_old_pdest[4]),
    .io_old_pdest_5            (int_old_pdest[5]),
    .io_need_free_0            (int_need_free[0]),
    .io_need_free_1            (int_need_free[1]),
    .io_need_free_2            (int_need_free[2]),
    .io_need_free_3            (int_need_free[3]),
    .io_need_free_4            (int_need_free[4]),
    .io_need_free_5            (int_need_free[5]),
    .io_snpt_snptEnq           (snpt_snptEnq),
    .io_snpt_snptDeq           (snpt_snptDeq),
    .io_snpt_useSnpt           (snpt_useSnpt),
    .io_snpt_snptSelect        (snpt_snptSelect),
    .io_snpt_flushVec_0        (snpt_flushVec[0]),
    .io_snpt_flushVec_1        (snpt_flushVec[1]),
    .io_snpt_flushVec_2        (snpt_flushVec[2]),
    .io_snpt_flushVec_3        (snpt_flushVec[3]),
    .io_diffRatBase_0          (int_diffRatBase[0]),
    .io_diffRatBase_1          (int_diffRatBase[1]),
    .io_diffRatBase_2          (int_diffRatBase[2]),
    .io_diffRatBase_3          (int_diffRatBase[3]),
    .io_diffRatBase_4          (int_diffRatBase[4]),
    .io_diffRatBase_5          (int_diffRatBase[5]),
    .io_diffRatBase_6          (int_diffRatBase[6]),
    .io_diffRatBase_7          (int_diffRatBase[7]),
    .io_diffRatBase_8          (int_diffRatBase[8]),
    .io_diffRatBase_9          (int_diffRatBase[9]),
    .io_diffRatBase_10         (int_diffRatBase[10]),
    .io_diffRatBase_11         (int_diffRatBase[11]),
    .io_diffRatBase_12         (int_diffRatBase[12]),
    .io_diffRatBase_13         (int_diffRatBase[13]),
    .io_diffRatBase_14         (int_diffRatBase[14]),
    .io_diffRatBase_15         (int_diffRatBase[15]),
    .io_diffRatBase_16         (int_diffRatBase[16]),
    .io_diffRatBase_17         (int_diffRatBase[17]),
    .io_diffRatBase_18         (int_diffRatBase[18]),
    .io_diffRatBase_19         (int_diffRatBase[19]),
    .io_diffRatBase_20         (int_diffRatBase[20]),
    .io_diffRatBase_21         (int_diffRatBase[21]),
    .io_diffRatBase_22         (int_diffRatBase[22]),
    .io_diffRatBase_23         (int_diffRatBase[23]),
    .io_diffRatBase_24         (int_diffRatBase[24]),
    .io_diffRatBase_25         (int_diffRatBase[25]),
    .io_diffRatBase_26         (int_diffRatBase[26]),
    .io_diffRatBase_27         (int_diffRatBase[27]),
    .io_diffRatBase_28         (int_diffRatBase[28]),
    .io_diffRatBase_29         (int_diffRatBase[29]),
    .io_diffRatBase_30         (int_diffRatBase[30]),
    .io_diffRatBase_31         (int_diffRatBase[31]),
    .io_debug_rdata_0          (debug_int_rat[0]),
    .io_debug_rdata_1          (debug_int_rat[1]),
    .io_debug_rdata_2          (debug_int_rat[2]),
    .io_debug_rdata_3          (debug_int_rat[3]),
    .io_debug_rdata_4          (debug_int_rat[4]),
    .io_debug_rdata_5          (debug_int_rat[5]),
    .io_debug_rdata_6          (debug_int_rat[6]),
    .io_debug_rdata_7          (debug_int_rat[7]),
    .io_debug_rdata_8          (debug_int_rat[8]),
    .io_debug_rdata_9          (debug_int_rat[9]),
    .io_debug_rdata_10         (debug_int_rat[10]),
    .io_debug_rdata_11         (debug_int_rat[11]),
    .io_debug_rdata_12         (debug_int_rat[12]),
    .io_debug_rdata_13         (debug_int_rat[13]),
    .io_debug_rdata_14         (debug_int_rat[14]),
    .io_debug_rdata_15         (debug_int_rat[15]),
    .io_debug_rdata_16         (debug_int_rat[16]),
    .io_debug_rdata_17         (debug_int_rat[17]),
    .io_debug_rdata_18         (debug_int_rat[18]),
    .io_debug_rdata_19         (debug_int_rat[19]),
    .io_debug_rdata_20         (debug_int_rat[20]),
    .io_debug_rdata_21         (debug_int_rat[21]),
    .io_debug_rdata_22         (debug_int_rat[22]),
    .io_debug_rdata_23         (debug_int_rat[23]),
    .io_debug_rdata_24         (debug_int_rat[24]),
    .io_debug_rdata_25         (debug_int_rat[25]),
    .io_debug_rdata_26         (debug_int_rat[26]),
    .io_debug_rdata_27         (debug_int_rat[27]),
    .io_debug_rdata_28         (debug_int_rat[28]),
    .io_debug_rdata_29         (debug_int_rat[29]),
    .io_debug_rdata_30         (debug_int_rat[30]),
    .io_debug_rdata_31         (debug_int_rat[31])
  );
  RenameTable_1 fpRat (
    .clock                     (clock),
    .reset                     (reset),
    .io_redirect               (redirect),
    .io_readPorts_0_hold       (fp_rd_hold[0][0]),
    .io_readPorts_0_addr       (fp_rd_addr[0][0][5:0]),
    .io_readPorts_0_data       (fp_rd_data[0][0]),
    .io_readPorts_1_hold       (fp_rd_hold[0][1]),
    .io_readPorts_1_addr       (fp_rd_addr[0][1][5:0]),
    .io_readPorts_1_data       (fp_rd_data[0][1]),
    .io_readPorts_2_hold       (fp_rd_hold[0][2]),
    .io_readPorts_2_addr       (fp_rd_addr[0][2][5:0]),
    .io_readPorts_2_data       (fp_rd_data[0][2]),
    .io_readPorts_3_hold       (fp_rd_hold[1][0]),
    .io_readPorts_3_addr       (fp_rd_addr[1][0][5:0]),
    .io_readPorts_3_data       (fp_rd_data[1][0]),
    .io_readPorts_4_hold       (fp_rd_hold[1][1]),
    .io_readPorts_4_addr       (fp_rd_addr[1][1][5:0]),
    .io_readPorts_4_data       (fp_rd_data[1][1]),
    .io_readPorts_5_hold       (fp_rd_hold[1][2]),
    .io_readPorts_5_addr       (fp_rd_addr[1][2][5:0]),
    .io_readPorts_5_data       (fp_rd_data[1][2]),
    .io_readPorts_6_hold       (fp_rd_hold[2][0]),
    .io_readPorts_6_addr       (fp_rd_addr[2][0][5:0]),
    .io_readPorts_6_data       (fp_rd_data[2][0]),
    .io_readPorts_7_hold       (fp_rd_hold[2][1]),
    .io_readPorts_7_addr       (fp_rd_addr[2][1][5:0]),
    .io_readPorts_7_data       (fp_rd_data[2][1]),
    .io_readPorts_8_hold       (fp_rd_hold[2][2]),
    .io_readPorts_8_addr       (fp_rd_addr[2][2][5:0]),
    .io_readPorts_8_data       (fp_rd_data[2][2]),
    .io_readPorts_9_hold       (fp_rd_hold[3][0]),
    .io_readPorts_9_addr       (fp_rd_addr[3][0][5:0]),
    .io_readPorts_9_data       (fp_rd_data[3][0]),
    .io_readPorts_10_hold      (fp_rd_hold[3][1]),
    .io_readPorts_10_addr      (fp_rd_addr[3][1][5:0]),
    .io_readPorts_10_data      (fp_rd_data[3][1]),
    .io_readPorts_11_hold      (fp_rd_hold[3][2]),
    .io_readPorts_11_addr      (fp_rd_addr[3][2][5:0]),
    .io_readPorts_11_data      (fp_rd_data[3][2]),
    .io_readPorts_12_hold      (fp_rd_hold[4][0]),
    .io_readPorts_12_addr      (fp_rd_addr[4][0][5:0]),
    .io_readPorts_12_data      (fp_rd_data[4][0]),
    .io_readPorts_13_hold      (fp_rd_hold[4][1]),
    .io_readPorts_13_addr      (fp_rd_addr[4][1][5:0]),
    .io_readPorts_13_data      (fp_rd_data[4][1]),
    .io_readPorts_14_hold      (fp_rd_hold[4][2]),
    .io_readPorts_14_addr      (fp_rd_addr[4][2][5:0]),
    .io_readPorts_14_data      (fp_rd_data[4][2]),
    .io_readPorts_15_hold      (fp_rd_hold[5][0]),
    .io_readPorts_15_addr      (fp_rd_addr[5][0][5:0]),
    .io_readPorts_15_data      (fp_rd_data[5][0]),
    .io_readPorts_16_hold      (fp_rd_hold[5][1]),
    .io_readPorts_16_addr      (fp_rd_addr[5][1][5:0]),
    .io_readPorts_16_data      (fp_rd_data[5][1]),
    .io_readPorts_17_hold      (fp_rd_hold[5][2]),
    .io_readPorts_17_addr      (fp_rd_addr[5][2][5:0]),
    .io_readPorts_17_data      (fp_rd_data[5][2]),
    .io_specWritePorts_0_wen   (fp_spec[0].wen),
    .io_specWritePorts_0_addr  (fp_spec[0].addr[5:0]),
    .io_specWritePorts_0_data  (fp_spec[0].data),
    .io_specWritePorts_1_wen   (fp_spec[1].wen),
    .io_specWritePorts_1_addr  (fp_spec[1].addr[5:0]),
    .io_specWritePorts_1_data  (fp_spec[1].data),
    .io_specWritePorts_2_wen   (fp_spec[2].wen),
    .io_specWritePorts_2_addr  (fp_spec[2].addr[5:0]),
    .io_specWritePorts_2_data  (fp_spec[2].data),
    .io_specWritePorts_3_wen   (fp_spec[3].wen),
    .io_specWritePorts_3_addr  (fp_spec[3].addr[5:0]),
    .io_specWritePorts_3_data  (fp_spec[3].data),
    .io_specWritePorts_4_wen   (fp_spec[4].wen),
    .io_specWritePorts_4_addr  (fp_spec[4].addr[5:0]),
    .io_specWritePorts_4_data  (fp_spec[4].data),
    .io_specWritePorts_5_wen   (fp_spec[5].wen),
    .io_specWritePorts_5_addr  (fp_spec[5].addr[5:0]),
    .io_specWritePorts_5_data  (fp_spec[5].data),
    .io_archWritePorts_0_wen   (fp_arch[0].wen),
    .io_archWritePorts_0_addr  (fp_arch[0].addr[5:0]),
    .io_archWritePorts_0_data  (fp_arch[0].data),
    .io_archWritePorts_1_wen   (fp_arch[1].wen),
    .io_archWritePorts_1_addr  (fp_arch[1].addr[5:0]),
    .io_archWritePorts_1_data  (fp_arch[1].data),
    .io_archWritePorts_2_wen   (fp_arch[2].wen),
    .io_archWritePorts_2_addr  (fp_arch[2].addr[5:0]),
    .io_archWritePorts_2_data  (fp_arch[2].data),
    .io_archWritePorts_3_wen   (fp_arch[3].wen),
    .io_archWritePorts_3_addr  (fp_arch[3].addr[5:0]),
    .io_archWritePorts_3_data  (fp_arch[3].data),
    .io_archWritePorts_4_wen   (fp_arch[4].wen),
    .io_archWritePorts_4_addr  (fp_arch[4].addr[5:0]),
    .io_archWritePorts_4_data  (fp_arch[4].data),
    .io_archWritePorts_5_wen   (fp_arch[5].wen),
    .io_archWritePorts_5_addr  (fp_arch[5].addr[5:0]),
    .io_archWritePorts_5_data  (fp_arch[5].data),
    .io_old_pdest_0            (fp_old_pdest[0]),
    .io_old_pdest_1            (fp_old_pdest[1]),
    .io_old_pdest_2            (fp_old_pdest[2]),
    .io_old_pdest_3            (fp_old_pdest[3]),
    .io_old_pdest_4            (fp_old_pdest[4]),
    .io_old_pdest_5            (fp_old_pdest[5]),
    .io_snpt_snptEnq           (snpt_snptEnq),
    .io_snpt_snptDeq           (snpt_snptDeq),
    .io_snpt_useSnpt           (snpt_useSnpt),
    .io_snpt_snptSelect        (snpt_snptSelect),
    .io_snpt_flushVec_0        (snpt_flushVec[0]),
    .io_snpt_flushVec_1        (snpt_flushVec[1]),
    .io_snpt_flushVec_2        (snpt_flushVec[2]),
    .io_snpt_flushVec_3        (snpt_flushVec[3]),
    .io_diffRatBase_0          (fp_diffRatBase[0]),
    .io_diffRatBase_1          (fp_diffRatBase[1]),
    .io_diffRatBase_2          (fp_diffRatBase[2]),
    .io_diffRatBase_3          (fp_diffRatBase[3]),
    .io_diffRatBase_4          (fp_diffRatBase[4]),
    .io_diffRatBase_5          (fp_diffRatBase[5]),
    .io_diffRatBase_6          (fp_diffRatBase[6]),
    .io_diffRatBase_7          (fp_diffRatBase[7]),
    .io_diffRatBase_8          (fp_diffRatBase[8]),
    .io_diffRatBase_9          (fp_diffRatBase[9]),
    .io_diffRatBase_10         (fp_diffRatBase[10]),
    .io_diffRatBase_11         (fp_diffRatBase[11]),
    .io_diffRatBase_12         (fp_diffRatBase[12]),
    .io_diffRatBase_13         (fp_diffRatBase[13]),
    .io_diffRatBase_14         (fp_diffRatBase[14]),
    .io_diffRatBase_15         (fp_diffRatBase[15]),
    .io_diffRatBase_16         (fp_diffRatBase[16]),
    .io_diffRatBase_17         (fp_diffRatBase[17]),
    .io_diffRatBase_18         (fp_diffRatBase[18]),
    .io_diffRatBase_19         (fp_diffRatBase[19]),
    .io_diffRatBase_20         (fp_diffRatBase[20]),
    .io_diffRatBase_21         (fp_diffRatBase[21]),
    .io_diffRatBase_22         (fp_diffRatBase[22]),
    .io_diffRatBase_23         (fp_diffRatBase[23]),
    .io_diffRatBase_24         (fp_diffRatBase[24]),
    .io_diffRatBase_25         (fp_diffRatBase[25]),
    .io_diffRatBase_26         (fp_diffRatBase[26]),
    .io_diffRatBase_27         (fp_diffRatBase[27]),
    .io_diffRatBase_28         (fp_diffRatBase[28]),
    .io_diffRatBase_29         (fp_diffRatBase[29]),
    .io_diffRatBase_30         (fp_diffRatBase[30]),
    .io_diffRatBase_31         (fp_diffRatBase[31])
  );
  RenameTable_2 vecRat (
    .clock                     (clock),
    .reset                     (reset),
    .io_redirect               (redirect),
    .io_readPorts_0_hold       (vec_rd_hold[0][0]),
    .io_readPorts_0_addr       (vec_rd_addr[0][0][5:0]),
    .io_readPorts_0_data       (vec_rd_data[0][0]),
    .io_readPorts_1_hold       (vec_rd_hold[0][1]),
    .io_readPorts_1_addr       (vec_rd_addr[0][1][5:0]),
    .io_readPorts_1_data       (vec_rd_data[0][1]),
    .io_readPorts_2_hold       (vec_rd_hold[0][2]),
    .io_readPorts_2_addr       (vec_rd_addr[0][2][5:0]),
    .io_readPorts_2_data       (vec_rd_data[0][2]),
    .io_readPorts_3_hold       (vec_rd_hold[1][0]),
    .io_readPorts_3_addr       (vec_rd_addr[1][0][5:0]),
    .io_readPorts_3_data       (vec_rd_data[1][0]),
    .io_readPorts_4_hold       (vec_rd_hold[1][1]),
    .io_readPorts_4_addr       (vec_rd_addr[1][1][5:0]),
    .io_readPorts_4_data       (vec_rd_data[1][1]),
    .io_readPorts_5_hold       (vec_rd_hold[1][2]),
    .io_readPorts_5_addr       (vec_rd_addr[1][2][5:0]),
    .io_readPorts_5_data       (vec_rd_data[1][2]),
    .io_readPorts_6_hold       (vec_rd_hold[2][0]),
    .io_readPorts_6_addr       (vec_rd_addr[2][0][5:0]),
    .io_readPorts_6_data       (vec_rd_data[2][0]),
    .io_readPorts_7_hold       (vec_rd_hold[2][1]),
    .io_readPorts_7_addr       (vec_rd_addr[2][1][5:0]),
    .io_readPorts_7_data       (vec_rd_data[2][1]),
    .io_readPorts_8_hold       (vec_rd_hold[2][2]),
    .io_readPorts_8_addr       (vec_rd_addr[2][2][5:0]),
    .io_readPorts_8_data       (vec_rd_data[2][2]),
    .io_readPorts_9_hold       (vec_rd_hold[3][0]),
    .io_readPorts_9_addr       (vec_rd_addr[3][0][5:0]),
    .io_readPorts_9_data       (vec_rd_data[3][0]),
    .io_readPorts_10_hold      (vec_rd_hold[3][1]),
    .io_readPorts_10_addr      (vec_rd_addr[3][1][5:0]),
    .io_readPorts_10_data      (vec_rd_data[3][1]),
    .io_readPorts_11_hold      (vec_rd_hold[3][2]),
    .io_readPorts_11_addr      (vec_rd_addr[3][2][5:0]),
    .io_readPorts_11_data      (vec_rd_data[3][2]),
    .io_readPorts_12_hold      (vec_rd_hold[4][0]),
    .io_readPorts_12_addr      (vec_rd_addr[4][0][5:0]),
    .io_readPorts_12_data      (vec_rd_data[4][0]),
    .io_readPorts_13_hold      (vec_rd_hold[4][1]),
    .io_readPorts_13_addr      (vec_rd_addr[4][1][5:0]),
    .io_readPorts_13_data      (vec_rd_data[4][1]),
    .io_readPorts_14_hold      (vec_rd_hold[4][2]),
    .io_readPorts_14_addr      (vec_rd_addr[4][2][5:0]),
    .io_readPorts_14_data      (vec_rd_data[4][2]),
    .io_readPorts_15_hold      (vec_rd_hold[5][0]),
    .io_readPorts_15_addr      (vec_rd_addr[5][0][5:0]),
    .io_readPorts_15_data      (vec_rd_data[5][0]),
    .io_readPorts_16_hold      (vec_rd_hold[5][1]),
    .io_readPorts_16_addr      (vec_rd_addr[5][1][5:0]),
    .io_readPorts_16_data      (vec_rd_data[5][1]),
    .io_readPorts_17_hold      (vec_rd_hold[5][2]),
    .io_readPorts_17_addr      (vec_rd_addr[5][2][5:0]),
    .io_readPorts_17_data      (vec_rd_data[5][2]),
    .io_specWritePorts_0_wen   (vec_spec[0].wen),
    .io_specWritePorts_0_addr  (vec_spec[0].addr[5:0]),
    .io_specWritePorts_0_data  (vec_spec[0].data),
    .io_specWritePorts_1_wen   (vec_spec[1].wen),
    .io_specWritePorts_1_addr  (vec_spec[1].addr[5:0]),
    .io_specWritePorts_1_data  (vec_spec[1].data),
    .io_specWritePorts_2_wen   (vec_spec[2].wen),
    .io_specWritePorts_2_addr  (vec_spec[2].addr[5:0]),
    .io_specWritePorts_2_data  (vec_spec[2].data),
    .io_specWritePorts_3_wen   (vec_spec[3].wen),
    .io_specWritePorts_3_addr  (vec_spec[3].addr[5:0]),
    .io_specWritePorts_3_data  (vec_spec[3].data),
    .io_specWritePorts_4_wen   (vec_spec[4].wen),
    .io_specWritePorts_4_addr  (vec_spec[4].addr[5:0]),
    .io_specWritePorts_4_data  (vec_spec[4].data),
    .io_specWritePorts_5_wen   (vec_spec[5].wen),
    .io_specWritePorts_5_addr  (vec_spec[5].addr[5:0]),
    .io_specWritePorts_5_data  (vec_spec[5].data),
    .io_archWritePorts_0_wen   (vec_arch[0].wen),
    .io_archWritePorts_0_addr  (vec_arch[0].addr[5:0]),
    .io_archWritePorts_0_data  (vec_arch[0].data),
    .io_archWritePorts_1_wen   (vec_arch[1].wen),
    .io_archWritePorts_1_addr  (vec_arch[1].addr[5:0]),
    .io_archWritePorts_1_data  (vec_arch[1].data),
    .io_archWritePorts_2_wen   (vec_arch[2].wen),
    .io_archWritePorts_2_addr  (vec_arch[2].addr[5:0]),
    .io_archWritePorts_2_data  (vec_arch[2].data),
    .io_archWritePorts_3_wen   (vec_arch[3].wen),
    .io_archWritePorts_3_addr  (vec_arch[3].addr[5:0]),
    .io_archWritePorts_3_data  (vec_arch[3].data),
    .io_archWritePorts_4_wen   (vec_arch[4].wen),
    .io_archWritePorts_4_addr  (vec_arch[4].addr[5:0]),
    .io_archWritePorts_4_data  (vec_arch[4].data),
    .io_archWritePorts_5_wen   (vec_arch[5].wen),
    .io_archWritePorts_5_addr  (vec_arch[5].addr[5:0]),
    .io_archWritePorts_5_data  (vec_arch[5].data),
    .io_old_pdest_0            (vec_old_pdest[0]),
    .io_old_pdest_1            (vec_old_pdest[1]),
    .io_old_pdest_2            (vec_old_pdest[2]),
    .io_old_pdest_3            (vec_old_pdest[3]),
    .io_old_pdest_4            (vec_old_pdest[4]),
    .io_old_pdest_5            (vec_old_pdest[5]),
    .io_need_free_0            (),
    .io_need_free_1            (),
    .io_need_free_2            (),
    .io_need_free_3            (),
    .io_need_free_4            (),
    .io_need_free_5            (),
    .io_snpt_snptEnq           (snpt_snptEnq),
    .io_snpt_snptDeq           (snpt_snptDeq),
    .io_snpt_useSnpt           (snpt_useSnpt),
    .io_snpt_snptSelect        (snpt_snptSelect),
    .io_snpt_flushVec_0        (snpt_flushVec[0]),
    .io_snpt_flushVec_1        (snpt_flushVec[1]),
    .io_snpt_flushVec_2        (snpt_flushVec[2]),
    .io_snpt_flushVec_3        (snpt_flushVec[3]),
    .io_diffRatBase_0          (vec_diffRatBase[0]),
    .io_diffRatBase_1          (vec_diffRatBase[1]),
    .io_diffRatBase_2          (vec_diffRatBase[2]),
    .io_diffRatBase_3          (vec_diffRatBase[3]),
    .io_diffRatBase_4          (vec_diffRatBase[4]),
    .io_diffRatBase_5          (vec_diffRatBase[5]),
    .io_diffRatBase_6          (vec_diffRatBase[6]),
    .io_diffRatBase_7          (vec_diffRatBase[7]),
    .io_diffRatBase_8          (vec_diffRatBase[8]),
    .io_diffRatBase_9          (vec_diffRatBase[9]),
    .io_diffRatBase_10         (vec_diffRatBase[10]),
    .io_diffRatBase_11         (vec_diffRatBase[11]),
    .io_diffRatBase_12         (vec_diffRatBase[12]),
    .io_diffRatBase_13         (vec_diffRatBase[13]),
    .io_diffRatBase_14         (vec_diffRatBase[14]),
    .io_diffRatBase_15         (vec_diffRatBase[15]),
    .io_diffRatBase_16         (vec_diffRatBase[16]),
    .io_diffRatBase_17         (vec_diffRatBase[17]),
    .io_diffRatBase_18         (vec_diffRatBase[18]),
    .io_diffRatBase_19         (vec_diffRatBase[19]),
    .io_diffRatBase_20         (vec_diffRatBase[20]),
    .io_diffRatBase_21         (vec_diffRatBase[21]),
    .io_diffRatBase_22         (vec_diffRatBase[22]),
    .io_diffRatBase_23         (vec_diffRatBase[23]),
    .io_diffRatBase_24         (vec_diffRatBase[24]),
    .io_diffRatBase_25         (vec_diffRatBase[25]),
    .io_diffRatBase_26         (vec_diffRatBase[26]),
    .io_diffRatBase_27         (vec_diffRatBase[27]),
    .io_diffRatBase_28         (vec_diffRatBase[28]),
    .io_diffRatBase_29         (vec_diffRatBase[29]),
    .io_diffRatBase_30         (vec_diffRatBase[30]),
    .io_debug_rdata_0          (),
    .io_debug_rdata_1          (),
    .io_debug_rdata_2          (),
    .io_debug_rdata_3          (),
    .io_debug_rdata_4          (),
    .io_debug_rdata_5          (),
    .io_debug_rdata_6          (),
    .io_debug_rdata_7          (),
    .io_debug_rdata_8          (),
    .io_debug_rdata_9          (),
    .io_debug_rdata_10         (),
    .io_debug_rdata_11         (),
    .io_debug_rdata_12         (),
    .io_debug_rdata_13         (),
    .io_debug_rdata_14         (),
    .io_debug_rdata_15         (),
    .io_debug_rdata_16         (),
    .io_debug_rdata_17         (),
    .io_debug_rdata_18         (),
    .io_debug_rdata_19         (),
    .io_debug_rdata_20         (),
    .io_debug_rdata_21         (),
    .io_debug_rdata_22         (),
    .io_debug_rdata_23         (),
    .io_debug_rdata_24         (),
    .io_debug_rdata_25         (),
    .io_debug_rdata_26         (),
    .io_debug_rdata_27         (),
    .io_debug_rdata_28         (),
    .io_debug_rdata_29         (),
    .io_debug_rdata_30         ()
  );
  RenameTable_3 v0Rat (
    .clock                     (clock),
    .reset                     (reset),
    .io_redirect               (redirect),
    .io_readPorts_0_hold       (v0_rd_hold[0]),
    .io_readPorts_0_data       (v0_rd_data[0]),
    .io_readPorts_1_hold       (v0_rd_hold[1]),
    .io_readPorts_1_data       (v0_rd_data[1]),
    .io_readPorts_2_hold       (v0_rd_hold[2]),
    .io_readPorts_2_data       (v0_rd_data[2]),
    .io_readPorts_3_hold       (v0_rd_hold[3]),
    .io_readPorts_3_data       (v0_rd_data[3]),
    .io_readPorts_4_hold       (v0_rd_hold[4]),
    .io_readPorts_4_data       (v0_rd_data[4]),
    .io_readPorts_5_hold       (v0_rd_hold[5]),
    .io_readPorts_5_data       (v0_rd_data[5]),
    .io_specWritePorts_0_wen   (v0_spec[0].wen),
    .io_specWritePorts_0_data  (v0_spec[0].data),
    .io_specWritePorts_1_wen   (v0_spec[1].wen),
    .io_specWritePorts_1_data  (v0_spec[1].data),
    .io_specWritePorts_2_wen   (v0_spec[2].wen),
    .io_specWritePorts_2_data  (v0_spec[2].data),
    .io_specWritePorts_3_wen   (v0_spec[3].wen),
    .io_specWritePorts_3_data  (v0_spec[3].data),
    .io_specWritePorts_4_wen   (v0_spec[4].wen),
    .io_specWritePorts_4_data  (v0_spec[4].data),
    .io_specWritePorts_5_wen   (v0_spec[5].wen),
    .io_specWritePorts_5_data  (v0_spec[5].data),
    .io_archWritePorts_0_wen   (v0_arch[0].wen),
    .io_archWritePorts_0_data  (v0_arch[0].data),
    .io_archWritePorts_1_wen   (v0_arch[1].wen),
    .io_archWritePorts_1_data  (v0_arch[1].data),
    .io_archWritePorts_2_wen   (v0_arch[2].wen),
    .io_archWritePorts_2_data  (v0_arch[2].data),
    .io_archWritePorts_3_wen   (v0_arch[3].wen),
    .io_archWritePorts_3_data  (v0_arch[3].data),
    .io_archWritePorts_4_wen   (v0_arch[4].wen),
    .io_archWritePorts_4_data  (v0_arch[4].data),
    .io_archWritePorts_5_wen   (v0_arch[5].wen),
    .io_archWritePorts_5_data  (v0_arch[5].data),
    .io_old_pdest_0            (v0_old_pdest[0]),
    .io_old_pdest_1            (v0_old_pdest[1]),
    .io_old_pdest_2            (v0_old_pdest[2]),
    .io_old_pdest_3            (v0_old_pdest[3]),
    .io_old_pdest_4            (v0_old_pdest[4]),
    .io_old_pdest_5            (v0_old_pdest[5]),
    .io_need_free_0            (),
    .io_need_free_1            (),
    .io_need_free_2            (),
    .io_need_free_3            (),
    .io_need_free_4            (),
    .io_need_free_5            (),
    .io_snpt_snptEnq           (snpt_snptEnq),
    .io_snpt_snptDeq           (snpt_snptDeq),
    .io_snpt_useSnpt           (snpt_useSnpt),
    .io_snpt_snptSelect        (snpt_snptSelect),
    .io_snpt_flushVec_0        (snpt_flushVec[0]),
    .io_snpt_flushVec_1        (snpt_flushVec[1]),
    .io_snpt_flushVec_2        (snpt_flushVec[2]),
    .io_snpt_flushVec_3        (snpt_flushVec[3]),
    .io_diffRatBase_0          (v0_diffRatBase),
    .io_debug_rdata_0          (),
    .io_debug_v0               ()
  );
  RenameTable_3 vlRat (
    .clock                     (clock),
    .reset                     (reset),
    .io_redirect               (redirect),
    .io_readPorts_0_hold       (vl_rd_hold[0]),
    .io_readPorts_0_data       (vl_rd_data[0]),
    .io_readPorts_1_hold       (vl_rd_hold[1]),
    .io_readPorts_1_data       (vl_rd_data[1]),
    .io_readPorts_2_hold       (vl_rd_hold[2]),
    .io_readPorts_2_data       (vl_rd_data[2]),
    .io_readPorts_3_hold       (vl_rd_hold[3]),
    .io_readPorts_3_data       (vl_rd_data[3]),
    .io_readPorts_4_hold       (vl_rd_hold[4]),
    .io_readPorts_4_data       (vl_rd_data[4]),
    .io_readPorts_5_hold       (vl_rd_hold[5]),
    .io_readPorts_5_data       (vl_rd_data[5]),
    .io_specWritePorts_0_wen   (vl_spec[0].wen),
    .io_specWritePorts_0_data  (vl_spec[0].data),
    .io_specWritePorts_1_wen   (vl_spec[1].wen),
    .io_specWritePorts_1_data  (vl_spec[1].data),
    .io_specWritePorts_2_wen   (vl_spec[2].wen),
    .io_specWritePorts_2_data  (vl_spec[2].data),
    .io_specWritePorts_3_wen   (vl_spec[3].wen),
    .io_specWritePorts_3_data  (vl_spec[3].data),
    .io_specWritePorts_4_wen   (vl_spec[4].wen),
    .io_specWritePorts_4_data  (vl_spec[4].data),
    .io_specWritePorts_5_wen   (vl_spec[5].wen),
    .io_specWritePorts_5_data  (vl_spec[5].data),
    .io_archWritePorts_0_wen   (vl_arch[0].wen),
    .io_archWritePorts_0_data  (vl_arch[0].data),
    .io_archWritePorts_1_wen   (vl_arch[1].wen),
    .io_archWritePorts_1_data  (vl_arch[1].data),
    .io_archWritePorts_2_wen   (vl_arch[2].wen),
    .io_archWritePorts_2_data  (vl_arch[2].data),
    .io_archWritePorts_3_wen   (vl_arch[3].wen),
    .io_archWritePorts_3_data  (vl_arch[3].data),
    .io_archWritePorts_4_wen   (vl_arch[4].wen),
    .io_archWritePorts_4_data  (vl_arch[4].data),
    .io_archWritePorts_5_wen   (vl_arch[5].wen),
    .io_archWritePorts_5_data  (vl_arch[5].data),
    .io_old_pdest_0            (vl_old_pdest[0]),
    .io_old_pdest_1            (vl_old_pdest[1]),
    .io_old_pdest_2            (vl_old_pdest[2]),
    .io_old_pdest_3            (vl_old_pdest[3]),
    .io_old_pdest_4            (vl_old_pdest[4]),
    .io_old_pdest_5            (vl_old_pdest[5]),
    .io_need_free_0            (),
    .io_need_free_1            (),
    .io_need_free_2            (),
    .io_need_free_3            (),
    .io_need_free_4            (),
    .io_need_free_5            (),
    .io_snpt_snptEnq           (snpt_snptEnq),
    .io_snpt_snptDeq           (snpt_snptDeq),
    .io_snpt_useSnpt           (snpt_useSnpt),
    .io_snpt_snptSelect        (snpt_snptSelect),
    .io_snpt_flushVec_0        (snpt_flushVec[0]),
    .io_snpt_flushVec_1        (snpt_flushVec[1]),
    .io_snpt_flushVec_2        (snpt_flushVec[2]),
    .io_snpt_flushVec_3        (snpt_flushVec[3]),
    .io_diffRatBase_0          (vl_diffRatBase),
    .io_debug_rdata_0          (),
    .io_debug_v0               ()
  );
  DiffRatStateBuffer diffRatBuffer (
    .clock                             (clock),
    .reset                             (reset),
    .io_diffRatBase_intRat_0           (int_diffRatBase[0]),
    .io_diffRatBase_intRat_1           (int_diffRatBase[1]),
    .io_diffRatBase_intRat_2           (int_diffRatBase[2]),
    .io_diffRatBase_intRat_3           (int_diffRatBase[3]),
    .io_diffRatBase_intRat_4           (int_diffRatBase[4]),
    .io_diffRatBase_intRat_5           (int_diffRatBase[5]),
    .io_diffRatBase_intRat_6           (int_diffRatBase[6]),
    .io_diffRatBase_intRat_7           (int_diffRatBase[7]),
    .io_diffRatBase_intRat_8           (int_diffRatBase[8]),
    .io_diffRatBase_intRat_9           (int_diffRatBase[9]),
    .io_diffRatBase_intRat_10          (int_diffRatBase[10]),
    .io_diffRatBase_intRat_11          (int_diffRatBase[11]),
    .io_diffRatBase_intRat_12          (int_diffRatBase[12]),
    .io_diffRatBase_intRat_13          (int_diffRatBase[13]),
    .io_diffRatBase_intRat_14          (int_diffRatBase[14]),
    .io_diffRatBase_intRat_15          (int_diffRatBase[15]),
    .io_diffRatBase_intRat_16          (int_diffRatBase[16]),
    .io_diffRatBase_intRat_17          (int_diffRatBase[17]),
    .io_diffRatBase_intRat_18          (int_diffRatBase[18]),
    .io_diffRatBase_intRat_19          (int_diffRatBase[19]),
    .io_diffRatBase_intRat_20          (int_diffRatBase[20]),
    .io_diffRatBase_intRat_21          (int_diffRatBase[21]),
    .io_diffRatBase_intRat_22          (int_diffRatBase[22]),
    .io_diffRatBase_intRat_23          (int_diffRatBase[23]),
    .io_diffRatBase_intRat_24          (int_diffRatBase[24]),
    .io_diffRatBase_intRat_25          (int_diffRatBase[25]),
    .io_diffRatBase_intRat_26          (int_diffRatBase[26]),
    .io_diffRatBase_intRat_27          (int_diffRatBase[27]),
    .io_diffRatBase_intRat_28          (int_diffRatBase[28]),
    .io_diffRatBase_intRat_29          (int_diffRatBase[29]),
    .io_diffRatBase_intRat_30          (int_diffRatBase[30]),
    .io_diffRatBase_intRat_31          (int_diffRatBase[31]),
    .io_diffRatBase_fpRat_0            (fp_diffRatBase[0]),
    .io_diffRatBase_fpRat_1            (fp_diffRatBase[1]),
    .io_diffRatBase_fpRat_2            (fp_diffRatBase[2]),
    .io_diffRatBase_fpRat_3            (fp_diffRatBase[3]),
    .io_diffRatBase_fpRat_4            (fp_diffRatBase[4]),
    .io_diffRatBase_fpRat_5            (fp_diffRatBase[5]),
    .io_diffRatBase_fpRat_6            (fp_diffRatBase[6]),
    .io_diffRatBase_fpRat_7            (fp_diffRatBase[7]),
    .io_diffRatBase_fpRat_8            (fp_diffRatBase[8]),
    .io_diffRatBase_fpRat_9            (fp_diffRatBase[9]),
    .io_diffRatBase_fpRat_10           (fp_diffRatBase[10]),
    .io_diffRatBase_fpRat_11           (fp_diffRatBase[11]),
    .io_diffRatBase_fpRat_12           (fp_diffRatBase[12]),
    .io_diffRatBase_fpRat_13           (fp_diffRatBase[13]),
    .io_diffRatBase_fpRat_14           (fp_diffRatBase[14]),
    .io_diffRatBase_fpRat_15           (fp_diffRatBase[15]),
    .io_diffRatBase_fpRat_16           (fp_diffRatBase[16]),
    .io_diffRatBase_fpRat_17           (fp_diffRatBase[17]),
    .io_diffRatBase_fpRat_18           (fp_diffRatBase[18]),
    .io_diffRatBase_fpRat_19           (fp_diffRatBase[19]),
    .io_diffRatBase_fpRat_20           (fp_diffRatBase[20]),
    .io_diffRatBase_fpRat_21           (fp_diffRatBase[21]),
    .io_diffRatBase_fpRat_22           (fp_diffRatBase[22]),
    .io_diffRatBase_fpRat_23           (fp_diffRatBase[23]),
    .io_diffRatBase_fpRat_24           (fp_diffRatBase[24]),
    .io_diffRatBase_fpRat_25           (fp_diffRatBase[25]),
    .io_diffRatBase_fpRat_26           (fp_diffRatBase[26]),
    .io_diffRatBase_fpRat_27           (fp_diffRatBase[27]),
    .io_diffRatBase_fpRat_28           (fp_diffRatBase[28]),
    .io_diffRatBase_fpRat_29           (fp_diffRatBase[29]),
    .io_diffRatBase_fpRat_30           (fp_diffRatBase[30]),
    .io_diffRatBase_fpRat_31           (fp_diffRatBase[31]),
    .io_diffRatBase_vecRat_0           (vec_diffRatBase[0]),
    .io_diffRatBase_vecRat_1           (vec_diffRatBase[1]),
    .io_diffRatBase_vecRat_2           (vec_diffRatBase[2]),
    .io_diffRatBase_vecRat_3           (vec_diffRatBase[3]),
    .io_diffRatBase_vecRat_4           (vec_diffRatBase[4]),
    .io_diffRatBase_vecRat_5           (vec_diffRatBase[5]),
    .io_diffRatBase_vecRat_6           (vec_diffRatBase[6]),
    .io_diffRatBase_vecRat_7           (vec_diffRatBase[7]),
    .io_diffRatBase_vecRat_8           (vec_diffRatBase[8]),
    .io_diffRatBase_vecRat_9           (vec_diffRatBase[9]),
    .io_diffRatBase_vecRat_10          (vec_diffRatBase[10]),
    .io_diffRatBase_vecRat_11          (vec_diffRatBase[11]),
    .io_diffRatBase_vecRat_12          (vec_diffRatBase[12]),
    .io_diffRatBase_vecRat_13          (vec_diffRatBase[13]),
    .io_diffRatBase_vecRat_14          (vec_diffRatBase[14]),
    .io_diffRatBase_vecRat_15          (vec_diffRatBase[15]),
    .io_diffRatBase_vecRat_16          (vec_diffRatBase[16]),
    .io_diffRatBase_vecRat_17          (vec_diffRatBase[17]),
    .io_diffRatBase_vecRat_18          (vec_diffRatBase[18]),
    .io_diffRatBase_vecRat_19          (vec_diffRatBase[19]),
    .io_diffRatBase_vecRat_20          (vec_diffRatBase[20]),
    .io_diffRatBase_vecRat_21          (vec_diffRatBase[21]),
    .io_diffRatBase_vecRat_22          (vec_diffRatBase[22]),
    .io_diffRatBase_vecRat_23          (vec_diffRatBase[23]),
    .io_diffRatBase_vecRat_24          (vec_diffRatBase[24]),
    .io_diffRatBase_vecRat_25          (vec_diffRatBase[25]),
    .io_diffRatBase_vecRat_26          (vec_diffRatBase[26]),
    .io_diffRatBase_vecRat_27          (vec_diffRatBase[27]),
    .io_diffRatBase_vecRat_28          (vec_diffRatBase[28]),
    .io_diffRatBase_vecRat_29          (vec_diffRatBase[29]),
    .io_diffRatBase_vecRat_30          (vec_diffRatBase[30]),
    .io_diffRatBase_v0Rat_0            (v0_diffRatBase),
    .io_diffRatBase_vlRat_0            (vl_diffRatBase),
    .io_renameUpdates_0_valid          (renameUpdates_valid[0]),
    .io_renameUpdates_0_bits_robIdx_flag(renameUpdates_robIdx_flag[0]),
    .io_renameUpdates_0_bits_robIdx_value(renameUpdates_robIdx_value[0]),
    .io_renameUpdates_0_bits_lastUop   (renameUpdates_lastUop[0]),
    .io_renameUpdates_0_bits_ldest     (renameUpdates_ldest[0]),
    .io_renameUpdates_0_bits_pdest     (renameUpdates_pdest[0]),
    .io_renameUpdates_0_bits_rfWen     (renameUpdates_rfWen[0]),
    .io_renameUpdates_0_bits_fpWen     (renameUpdates_fpWen[0]),
    .io_renameUpdates_0_bits_vecWen    (renameUpdates_vecWen[0]),
    .io_renameUpdates_0_bits_v0Wen     (renameUpdates_v0Wen[0]),
    .io_renameUpdates_0_bits_vlWen     (renameUpdates_vlWen[0]),
    .io_renameUpdates_1_valid          (renameUpdates_valid[1]),
    .io_renameUpdates_1_bits_robIdx_flag(renameUpdates_robIdx_flag[1]),
    .io_renameUpdates_1_bits_robIdx_value(renameUpdates_robIdx_value[1]),
    .io_renameUpdates_1_bits_lastUop   (renameUpdates_lastUop[1]),
    .io_renameUpdates_1_bits_ldest     (renameUpdates_ldest[1]),
    .io_renameUpdates_1_bits_pdest     (renameUpdates_pdest[1]),
    .io_renameUpdates_1_bits_rfWen     (renameUpdates_rfWen[1]),
    .io_renameUpdates_1_bits_fpWen     (renameUpdates_fpWen[1]),
    .io_renameUpdates_1_bits_vecWen    (renameUpdates_vecWen[1]),
    .io_renameUpdates_1_bits_v0Wen     (renameUpdates_v0Wen[1]),
    .io_renameUpdates_1_bits_vlWen     (renameUpdates_vlWen[1]),
    .io_renameUpdates_2_valid          (renameUpdates_valid[2]),
    .io_renameUpdates_2_bits_robIdx_flag(renameUpdates_robIdx_flag[2]),
    .io_renameUpdates_2_bits_robIdx_value(renameUpdates_robIdx_value[2]),
    .io_renameUpdates_2_bits_lastUop   (renameUpdates_lastUop[2]),
    .io_renameUpdates_2_bits_ldest     (renameUpdates_ldest[2]),
    .io_renameUpdates_2_bits_pdest     (renameUpdates_pdest[2]),
    .io_renameUpdates_2_bits_rfWen     (renameUpdates_rfWen[2]),
    .io_renameUpdates_2_bits_fpWen     (renameUpdates_fpWen[2]),
    .io_renameUpdates_2_bits_vecWen    (renameUpdates_vecWen[2]),
    .io_renameUpdates_2_bits_v0Wen     (renameUpdates_v0Wen[2]),
    .io_renameUpdates_2_bits_vlWen     (renameUpdates_vlWen[2]),
    .io_renameUpdates_3_valid          (renameUpdates_valid[3]),
    .io_renameUpdates_3_bits_robIdx_flag(renameUpdates_robIdx_flag[3]),
    .io_renameUpdates_3_bits_robIdx_value(renameUpdates_robIdx_value[3]),
    .io_renameUpdates_3_bits_lastUop   (renameUpdates_lastUop[3]),
    .io_renameUpdates_3_bits_ldest     (renameUpdates_ldest[3]),
    .io_renameUpdates_3_bits_pdest     (renameUpdates_pdest[3]),
    .io_renameUpdates_3_bits_rfWen     (renameUpdates_rfWen[3]),
    .io_renameUpdates_3_bits_fpWen     (renameUpdates_fpWen[3]),
    .io_renameUpdates_3_bits_vecWen    (renameUpdates_vecWen[3]),
    .io_renameUpdates_3_bits_v0Wen     (renameUpdates_v0Wen[3]),
    .io_renameUpdates_3_bits_vlWen     (renameUpdates_vlWen[3]),
    .io_renameUpdates_4_valid          (renameUpdates_valid[4]),
    .io_renameUpdates_4_bits_robIdx_flag(renameUpdates_robIdx_flag[4]),
    .io_renameUpdates_4_bits_robIdx_value(renameUpdates_robIdx_value[4]),
    .io_renameUpdates_4_bits_lastUop   (renameUpdates_lastUop[4]),
    .io_renameUpdates_4_bits_ldest     (renameUpdates_ldest[4]),
    .io_renameUpdates_4_bits_pdest     (renameUpdates_pdest[4]),
    .io_renameUpdates_4_bits_rfWen     (renameUpdates_rfWen[4]),
    .io_renameUpdates_4_bits_fpWen     (renameUpdates_fpWen[4]),
    .io_renameUpdates_4_bits_vecWen    (renameUpdates_vecWen[4]),
    .io_renameUpdates_4_bits_v0Wen     (renameUpdates_v0Wen[4]),
    .io_renameUpdates_4_bits_vlWen     (renameUpdates_vlWen[4]),
    .io_renameUpdates_5_valid          (renameUpdates_valid[5]),
    .io_renameUpdates_5_bits_robIdx_flag(renameUpdates_robIdx_flag[5]),
    .io_renameUpdates_5_bits_robIdx_value(renameUpdates_robIdx_value[5]),
    .io_renameUpdates_5_bits_lastUop   (renameUpdates_lastUop[5]),
    .io_renameUpdates_5_bits_ldest     (renameUpdates_ldest[5]),
    .io_renameUpdates_5_bits_pdest     (renameUpdates_pdest[5]),
    .io_renameUpdates_5_bits_rfWen     (renameUpdates_rfWen[5]),
    .io_renameUpdates_5_bits_fpWen     (renameUpdates_fpWen[5]),
    .io_renameUpdates_5_bits_vecWen    (renameUpdates_vecWen[5]),
    .io_renameUpdates_5_bits_v0Wen     (renameUpdates_v0Wen[5]),
    .io_renameUpdates_5_bits_vlWen     (renameUpdates_vlWen[5]),
    .io_commitRobIdx_valid             (diffRatCommitRobIdx_valid),
    .io_commitRobIdx_bits_flag         (diffRatCommitRobIdx_flag),
    .io_commitRobIdx_bits_value        (diffRatCommitRobIdx_value),
    .io_diffRat_intRat_0               (diffRat_int[0]),
    .io_diffRat_intRat_1               (diffRat_int[1]),
    .io_diffRat_intRat_2               (diffRat_int[2]),
    .io_diffRat_intRat_3               (diffRat_int[3]),
    .io_diffRat_intRat_4               (diffRat_int[4]),
    .io_diffRat_intRat_5               (diffRat_int[5]),
    .io_diffRat_intRat_6               (diffRat_int[6]),
    .io_diffRat_intRat_7               (diffRat_int[7]),
    .io_diffRat_intRat_8               (diffRat_int[8]),
    .io_diffRat_intRat_9               (diffRat_int[9]),
    .io_diffRat_intRat_10              (diffRat_int[10]),
    .io_diffRat_intRat_11              (diffRat_int[11]),
    .io_diffRat_intRat_12              (diffRat_int[12]),
    .io_diffRat_intRat_13              (diffRat_int[13]),
    .io_diffRat_intRat_14              (diffRat_int[14]),
    .io_diffRat_intRat_15              (diffRat_int[15]),
    .io_diffRat_intRat_16              (diffRat_int[16]),
    .io_diffRat_intRat_17              (diffRat_int[17]),
    .io_diffRat_intRat_18              (diffRat_int[18]),
    .io_diffRat_intRat_19              (diffRat_int[19]),
    .io_diffRat_intRat_20              (diffRat_int[20]),
    .io_diffRat_intRat_21              (diffRat_int[21]),
    .io_diffRat_intRat_22              (diffRat_int[22]),
    .io_diffRat_intRat_23              (diffRat_int[23]),
    .io_diffRat_intRat_24              (diffRat_int[24]),
    .io_diffRat_intRat_25              (diffRat_int[25]),
    .io_diffRat_intRat_26              (diffRat_int[26]),
    .io_diffRat_intRat_27              (diffRat_int[27]),
    .io_diffRat_intRat_28              (diffRat_int[28]),
    .io_diffRat_intRat_29              (diffRat_int[29]),
    .io_diffRat_intRat_30              (diffRat_int[30]),
    .io_diffRat_intRat_31              (diffRat_int[31]),
    .io_diffRat_fpRat_0                (diffRat_fp[0]),
    .io_diffRat_fpRat_1                (diffRat_fp[1]),
    .io_diffRat_fpRat_2                (diffRat_fp[2]),
    .io_diffRat_fpRat_3                (diffRat_fp[3]),
    .io_diffRat_fpRat_4                (diffRat_fp[4]),
    .io_diffRat_fpRat_5                (diffRat_fp[5]),
    .io_diffRat_fpRat_6                (diffRat_fp[6]),
    .io_diffRat_fpRat_7                (diffRat_fp[7]),
    .io_diffRat_fpRat_8                (diffRat_fp[8]),
    .io_diffRat_fpRat_9                (diffRat_fp[9]),
    .io_diffRat_fpRat_10               (diffRat_fp[10]),
    .io_diffRat_fpRat_11               (diffRat_fp[11]),
    .io_diffRat_fpRat_12               (diffRat_fp[12]),
    .io_diffRat_fpRat_13               (diffRat_fp[13]),
    .io_diffRat_fpRat_14               (diffRat_fp[14]),
    .io_diffRat_fpRat_15               (diffRat_fp[15]),
    .io_diffRat_fpRat_16               (diffRat_fp[16]),
    .io_diffRat_fpRat_17               (diffRat_fp[17]),
    .io_diffRat_fpRat_18               (diffRat_fp[18]),
    .io_diffRat_fpRat_19               (diffRat_fp[19]),
    .io_diffRat_fpRat_20               (diffRat_fp[20]),
    .io_diffRat_fpRat_21               (diffRat_fp[21]),
    .io_diffRat_fpRat_22               (diffRat_fp[22]),
    .io_diffRat_fpRat_23               (diffRat_fp[23]),
    .io_diffRat_fpRat_24               (diffRat_fp[24]),
    .io_diffRat_fpRat_25               (diffRat_fp[25]),
    .io_diffRat_fpRat_26               (diffRat_fp[26]),
    .io_diffRat_fpRat_27               (diffRat_fp[27]),
    .io_diffRat_fpRat_28               (diffRat_fp[28]),
    .io_diffRat_fpRat_29               (diffRat_fp[29]),
    .io_diffRat_fpRat_30               (diffRat_fp[30]),
    .io_diffRat_fpRat_31               (diffRat_fp[31]),
    .io_diffRat_vecRat_0               (diffRat_vec[0]),
    .io_diffRat_vecRat_1               (diffRat_vec[1]),
    .io_diffRat_vecRat_2               (diffRat_vec[2]),
    .io_diffRat_vecRat_3               (diffRat_vec[3]),
    .io_diffRat_vecRat_4               (diffRat_vec[4]),
    .io_diffRat_vecRat_5               (diffRat_vec[5]),
    .io_diffRat_vecRat_6               (diffRat_vec[6]),
    .io_diffRat_vecRat_7               (diffRat_vec[7]),
    .io_diffRat_vecRat_8               (diffRat_vec[8]),
    .io_diffRat_vecRat_9               (diffRat_vec[9]),
    .io_diffRat_vecRat_10              (diffRat_vec[10]),
    .io_diffRat_vecRat_11              (diffRat_vec[11]),
    .io_diffRat_vecRat_12              (diffRat_vec[12]),
    .io_diffRat_vecRat_13              (diffRat_vec[13]),
    .io_diffRat_vecRat_14              (diffRat_vec[14]),
    .io_diffRat_vecRat_15              (diffRat_vec[15]),
    .io_diffRat_vecRat_16              (diffRat_vec[16]),
    .io_diffRat_vecRat_17              (diffRat_vec[17]),
    .io_diffRat_vecRat_18              (diffRat_vec[18]),
    .io_diffRat_vecRat_19              (diffRat_vec[19]),
    .io_diffRat_vecRat_20              (diffRat_vec[20]),
    .io_diffRat_vecRat_21              (diffRat_vec[21]),
    .io_diffRat_vecRat_22              (diffRat_vec[22]),
    .io_diffRat_vecRat_23              (diffRat_vec[23]),
    .io_diffRat_vecRat_24              (diffRat_vec[24]),
    .io_diffRat_vecRat_25              (diffRat_vec[25]),
    .io_diffRat_vecRat_26              (diffRat_vec[26]),
    .io_diffRat_vecRat_27              (diffRat_vec[27]),
    .io_diffRat_vecRat_28              (diffRat_vec[28]),
    .io_diffRat_vecRat_29              (diffRat_vec[29]),
    .io_diffRat_vecRat_30              (diffRat_vec[30]),
    .io_diffRat_v0Rat_0                (diffRat_v0),
    .io_diffRat_vlRat_0                (diff_vl_rat)
  );
  // END GENERATED

  // ---------------------------------------------------------------------------
  // difftest bore 打包：{value[N-1], …, value[0], coreid}
  // ---------------------------------------------------------------------------
  logic [2*(1+VEC_N)-1:0][8:0] vrf_value;
  always_comb begin
    logic [PREG_W-1:0] r;
    for (int i = 0; i < 1 + VEC_N; i++) begin
      r = (i == 0) ? diffRat_v0 : PREG_W'(diffRat_vec[i-1] + PREG_W'(V0_PHY_N));
      vrf_value[2*i]   = {r, 1'b0};
      vrf_value[2*i+1] = 9'({r, 1'b0} + 9'h1);
    end
  end
  assign difftest_rat_xrf = {diffRat_int, hartId};
  assign difftest_rat_frf = {diffRat_fp,  hartId};
  assign difftest_rat_vrf = {vrf_value,   hartId};

endmodule : xs_RenameTableWrapper_core

// BEGIN GENERATED(rtw_wrapper) —— 由 scripts/gen_renametablewrapper.py 从 golden 端口表产出
module RenameTableWrapper(
  input  clock,
  input  reset,
  input  [7:0] io_hartId,
  input  io_redirect,
  input  io_rabCommits_isCommit,
  input  io_rabCommits_commitValid_0,
  input  io_rabCommits_commitValid_1,
  input  io_rabCommits_commitValid_2,
  input  io_rabCommits_commitValid_3,
  input  io_rabCommits_commitValid_4,
  input  io_rabCommits_commitValid_5,
  input  io_rabCommits_isWalk,
  input  io_rabCommits_walkValid_0,
  input  io_rabCommits_walkValid_1,
  input  io_rabCommits_walkValid_2,
  input  io_rabCommits_walkValid_3,
  input  io_rabCommits_walkValid_4,
  input  io_rabCommits_walkValid_5,
  input  [5:0] io_rabCommits_info_0_ldest,
  input  [7:0] io_rabCommits_info_0_pdest,
  input  io_rabCommits_info_0_rfWen,
  input  io_rabCommits_info_0_fpWen,
  input  io_rabCommits_info_0_vecWen,
  input  io_rabCommits_info_0_v0Wen,
  input  io_rabCommits_info_0_vlWen,
  input  [5:0] io_rabCommits_info_1_ldest,
  input  [7:0] io_rabCommits_info_1_pdest,
  input  io_rabCommits_info_1_rfWen,
  input  io_rabCommits_info_1_fpWen,
  input  io_rabCommits_info_1_vecWen,
  input  io_rabCommits_info_1_v0Wen,
  input  io_rabCommits_info_1_vlWen,
  input  [5:0] io_rabCommits_info_2_ldest,
  input  [7:0] io_rabCommits_info_2_pdest,
  input  io_rabCommits_info_2_rfWen,
  input  io_rabCommits_info_2_fpWen,
  input  io_rabCommits_info_2_vecWen,
  input  io_rabCommits_info_2_v0Wen,
  input  io_rabCommits_info_2_vlWen,
  input  [5:0] io_rabCommits_info_3_ldest,
  input  [7:0] io_rabCommits_info_3_pdest,
  input  io_rabCommits_info_3_rfWen,
  input  io_rabCommits_info_3_fpWen,
  input  io_rabCommits_info_3_vecWen,
  input  io_rabCommits_info_3_v0Wen,
  input  io_rabCommits_info_3_vlWen,
  input  [5:0] io_rabCommits_info_4_ldest,
  input  [7:0] io_rabCommits_info_4_pdest,
  input  io_rabCommits_info_4_rfWen,
  input  io_rabCommits_info_4_fpWen,
  input  io_rabCommits_info_4_vecWen,
  input  io_rabCommits_info_4_v0Wen,
  input  io_rabCommits_info_4_vlWen,
  input  [5:0] io_rabCommits_info_5_ldest,
  input  [7:0] io_rabCommits_info_5_pdest,
  input  io_rabCommits_info_5_rfWen,
  input  io_rabCommits_info_5_fpWen,
  input  io_rabCommits_info_5_vecWen,
  input  io_rabCommits_info_5_v0Wen,
  input  io_rabCommits_info_5_vlWen,
  input  io_renameUpdates_0_valid,
  input  io_renameUpdates_0_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_0_bits_robIdx_value,
  input  io_renameUpdates_0_bits_lastUop,
  input  [5:0] io_renameUpdates_0_bits_ldest,
  input  [7:0] io_renameUpdates_0_bits_pdest,
  input  io_renameUpdates_0_bits_rfWen,
  input  io_renameUpdates_0_bits_fpWen,
  input  io_renameUpdates_0_bits_vecWen,
  input  io_renameUpdates_0_bits_v0Wen,
  input  io_renameUpdates_0_bits_vlWen,
  input  io_renameUpdates_1_valid,
  input  io_renameUpdates_1_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_1_bits_robIdx_value,
  input  io_renameUpdates_1_bits_lastUop,
  input  [5:0] io_renameUpdates_1_bits_ldest,
  input  [7:0] io_renameUpdates_1_bits_pdest,
  input  io_renameUpdates_1_bits_rfWen,
  input  io_renameUpdates_1_bits_fpWen,
  input  io_renameUpdates_1_bits_vecWen,
  input  io_renameUpdates_1_bits_v0Wen,
  input  io_renameUpdates_1_bits_vlWen,
  input  io_renameUpdates_2_valid,
  input  io_renameUpdates_2_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_2_bits_robIdx_value,
  input  io_renameUpdates_2_bits_lastUop,
  input  [5:0] io_renameUpdates_2_bits_ldest,
  input  [7:0] io_renameUpdates_2_bits_pdest,
  input  io_renameUpdates_2_bits_rfWen,
  input  io_renameUpdates_2_bits_fpWen,
  input  io_renameUpdates_2_bits_vecWen,
  input  io_renameUpdates_2_bits_v0Wen,
  input  io_renameUpdates_2_bits_vlWen,
  input  io_renameUpdates_3_valid,
  input  io_renameUpdates_3_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_3_bits_robIdx_value,
  input  io_renameUpdates_3_bits_lastUop,
  input  [5:0] io_renameUpdates_3_bits_ldest,
  input  [7:0] io_renameUpdates_3_bits_pdest,
  input  io_renameUpdates_3_bits_rfWen,
  input  io_renameUpdates_3_bits_fpWen,
  input  io_renameUpdates_3_bits_vecWen,
  input  io_renameUpdates_3_bits_v0Wen,
  input  io_renameUpdates_3_bits_vlWen,
  input  io_renameUpdates_4_valid,
  input  io_renameUpdates_4_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_4_bits_robIdx_value,
  input  io_renameUpdates_4_bits_lastUop,
  input  [5:0] io_renameUpdates_4_bits_ldest,
  input  [7:0] io_renameUpdates_4_bits_pdest,
  input  io_renameUpdates_4_bits_rfWen,
  input  io_renameUpdates_4_bits_fpWen,
  input  io_renameUpdates_4_bits_vecWen,
  input  io_renameUpdates_4_bits_v0Wen,
  input  io_renameUpdates_4_bits_vlWen,
  input  io_renameUpdates_5_valid,
  input  io_renameUpdates_5_bits_robIdx_flag,
  input  [7:0] io_renameUpdates_5_bits_robIdx_value,
  input  io_renameUpdates_5_bits_lastUop,
  input  [5:0] io_renameUpdates_5_bits_ldest,
  input  [7:0] io_renameUpdates_5_bits_pdest,
  input  io_renameUpdates_5_bits_rfWen,
  input  io_renameUpdates_5_bits_fpWen,
  input  io_renameUpdates_5_bits_vecWen,
  input  io_renameUpdates_5_bits_v0Wen,
  input  io_renameUpdates_5_bits_vlWen,
  input  io_diffRatCommitRobIdx_valid,
  input  io_diffRatCommitRobIdx_bits_flag,
  input  [7:0] io_diffRatCommitRobIdx_bits_value,
  input  io_intReadPorts_0_0_hold,
  input  [31:0] io_intReadPorts_0_0_addr,
  output [7:0] io_intReadPorts_0_0_data,
  input  io_intReadPorts_0_1_hold,
  input  [31:0] io_intReadPorts_0_1_addr,
  output [7:0] io_intReadPorts_0_1_data,
  input  io_intReadPorts_1_0_hold,
  input  [31:0] io_intReadPorts_1_0_addr,
  output [7:0] io_intReadPorts_1_0_data,
  input  io_intReadPorts_1_1_hold,
  input  [31:0] io_intReadPorts_1_1_addr,
  output [7:0] io_intReadPorts_1_1_data,
  input  io_intReadPorts_2_0_hold,
  input  [31:0] io_intReadPorts_2_0_addr,
  output [7:0] io_intReadPorts_2_0_data,
  input  io_intReadPorts_2_1_hold,
  input  [31:0] io_intReadPorts_2_1_addr,
  output [7:0] io_intReadPorts_2_1_data,
  input  io_intReadPorts_3_0_hold,
  input  [31:0] io_intReadPorts_3_0_addr,
  output [7:0] io_intReadPorts_3_0_data,
  input  io_intReadPorts_3_1_hold,
  input  [31:0] io_intReadPorts_3_1_addr,
  output [7:0] io_intReadPorts_3_1_data,
  input  io_intReadPorts_4_0_hold,
  input  [31:0] io_intReadPorts_4_0_addr,
  output [7:0] io_intReadPorts_4_0_data,
  input  io_intReadPorts_4_1_hold,
  input  [31:0] io_intReadPorts_4_1_addr,
  output [7:0] io_intReadPorts_4_1_data,
  input  io_intReadPorts_5_0_hold,
  input  [31:0] io_intReadPorts_5_0_addr,
  output [7:0] io_intReadPorts_5_0_data,
  input  io_intReadPorts_5_1_hold,
  input  [31:0] io_intReadPorts_5_1_addr,
  output [7:0] io_intReadPorts_5_1_data,
  input  io_intRenamePorts_0_wen,
  input  [31:0] io_intRenamePorts_0_addr,
  input  [7:0] io_intRenamePorts_0_data,
  input  io_intRenamePorts_1_wen,
  input  [31:0] io_intRenamePorts_1_addr,
  input  [7:0] io_intRenamePorts_1_data,
  input  io_intRenamePorts_2_wen,
  input  [31:0] io_intRenamePorts_2_addr,
  input  [7:0] io_intRenamePorts_2_data,
  input  io_intRenamePorts_3_wen,
  input  [31:0] io_intRenamePorts_3_addr,
  input  [7:0] io_intRenamePorts_3_data,
  input  io_intRenamePorts_4_wen,
  input  [31:0] io_intRenamePorts_4_addr,
  input  [7:0] io_intRenamePorts_4_data,
  input  io_intRenamePorts_5_wen,
  input  [31:0] io_intRenamePorts_5_addr,
  input  [7:0] io_intRenamePorts_5_data,
  input  io_fpReadPorts_0_0_hold,
  input  [33:0] io_fpReadPorts_0_0_addr,
  output [7:0] io_fpReadPorts_0_0_data,
  input  io_fpReadPorts_0_1_hold,
  input  [33:0] io_fpReadPorts_0_1_addr,
  output [7:0] io_fpReadPorts_0_1_data,
  input  io_fpReadPorts_0_2_hold,
  input  [33:0] io_fpReadPorts_0_2_addr,
  output [7:0] io_fpReadPorts_0_2_data,
  input  io_fpReadPorts_1_0_hold,
  input  [33:0] io_fpReadPorts_1_0_addr,
  output [7:0] io_fpReadPorts_1_0_data,
  input  io_fpReadPorts_1_1_hold,
  input  [33:0] io_fpReadPorts_1_1_addr,
  output [7:0] io_fpReadPorts_1_1_data,
  input  io_fpReadPorts_1_2_hold,
  input  [33:0] io_fpReadPorts_1_2_addr,
  output [7:0] io_fpReadPorts_1_2_data,
  input  io_fpReadPorts_2_0_hold,
  input  [33:0] io_fpReadPorts_2_0_addr,
  output [7:0] io_fpReadPorts_2_0_data,
  input  io_fpReadPorts_2_1_hold,
  input  [33:0] io_fpReadPorts_2_1_addr,
  output [7:0] io_fpReadPorts_2_1_data,
  input  io_fpReadPorts_2_2_hold,
  input  [33:0] io_fpReadPorts_2_2_addr,
  output [7:0] io_fpReadPorts_2_2_data,
  input  io_fpReadPorts_3_0_hold,
  input  [33:0] io_fpReadPorts_3_0_addr,
  output [7:0] io_fpReadPorts_3_0_data,
  input  io_fpReadPorts_3_1_hold,
  input  [33:0] io_fpReadPorts_3_1_addr,
  output [7:0] io_fpReadPorts_3_1_data,
  input  io_fpReadPorts_3_2_hold,
  input  [33:0] io_fpReadPorts_3_2_addr,
  output [7:0] io_fpReadPorts_3_2_data,
  input  io_fpReadPorts_4_0_hold,
  input  [33:0] io_fpReadPorts_4_0_addr,
  output [7:0] io_fpReadPorts_4_0_data,
  input  io_fpReadPorts_4_1_hold,
  input  [33:0] io_fpReadPorts_4_1_addr,
  output [7:0] io_fpReadPorts_4_1_data,
  input  io_fpReadPorts_4_2_hold,
  input  [33:0] io_fpReadPorts_4_2_addr,
  output [7:0] io_fpReadPorts_4_2_data,
  input  io_fpReadPorts_5_0_hold,
  input  [33:0] io_fpReadPorts_5_0_addr,
  output [7:0] io_fpReadPorts_5_0_data,
  input  io_fpReadPorts_5_1_hold,
  input  [33:0] io_fpReadPorts_5_1_addr,
  output [7:0] io_fpReadPorts_5_1_data,
  input  io_fpReadPorts_5_2_hold,
  input  [33:0] io_fpReadPorts_5_2_addr,
  output [7:0] io_fpReadPorts_5_2_data,
  input  io_fpRenamePorts_0_wen,
  input  [33:0] io_fpRenamePorts_0_addr,
  input  [7:0] io_fpRenamePorts_0_data,
  input  io_fpRenamePorts_1_wen,
  input  [33:0] io_fpRenamePorts_1_addr,
  input  [7:0] io_fpRenamePorts_1_data,
  input  io_fpRenamePorts_2_wen,
  input  [33:0] io_fpRenamePorts_2_addr,
  input  [7:0] io_fpRenamePorts_2_data,
  input  io_fpRenamePorts_3_wen,
  input  [33:0] io_fpRenamePorts_3_addr,
  input  [7:0] io_fpRenamePorts_3_data,
  input  io_fpRenamePorts_4_wen,
  input  [33:0] io_fpRenamePorts_4_addr,
  input  [7:0] io_fpRenamePorts_4_data,
  input  io_fpRenamePorts_5_wen,
  input  [33:0] io_fpRenamePorts_5_addr,
  input  [7:0] io_fpRenamePorts_5_data,
  input  io_vecReadPorts_0_0_hold,
  input  [46:0] io_vecReadPorts_0_0_addr,
  output [7:0] io_vecReadPorts_0_0_data,
  input  io_vecReadPorts_0_1_hold,
  input  [46:0] io_vecReadPorts_0_1_addr,
  output [7:0] io_vecReadPorts_0_1_data,
  input  io_vecReadPorts_0_2_hold,
  input  [46:0] io_vecReadPorts_0_2_addr,
  output [7:0] io_vecReadPorts_0_2_data,
  input  io_vecReadPorts_1_0_hold,
  input  [46:0] io_vecReadPorts_1_0_addr,
  output [7:0] io_vecReadPorts_1_0_data,
  input  io_vecReadPorts_1_1_hold,
  input  [46:0] io_vecReadPorts_1_1_addr,
  output [7:0] io_vecReadPorts_1_1_data,
  input  io_vecReadPorts_1_2_hold,
  input  [46:0] io_vecReadPorts_1_2_addr,
  output [7:0] io_vecReadPorts_1_2_data,
  input  io_vecReadPorts_2_0_hold,
  input  [46:0] io_vecReadPorts_2_0_addr,
  output [7:0] io_vecReadPorts_2_0_data,
  input  io_vecReadPorts_2_1_hold,
  input  [46:0] io_vecReadPorts_2_1_addr,
  output [7:0] io_vecReadPorts_2_1_data,
  input  io_vecReadPorts_2_2_hold,
  input  [46:0] io_vecReadPorts_2_2_addr,
  output [7:0] io_vecReadPorts_2_2_data,
  input  io_vecReadPorts_3_0_hold,
  input  [46:0] io_vecReadPorts_3_0_addr,
  output [7:0] io_vecReadPorts_3_0_data,
  input  io_vecReadPorts_3_1_hold,
  input  [46:0] io_vecReadPorts_3_1_addr,
  output [7:0] io_vecReadPorts_3_1_data,
  input  io_vecReadPorts_3_2_hold,
  input  [46:0] io_vecReadPorts_3_2_addr,
  output [7:0] io_vecReadPorts_3_2_data,
  input  io_vecReadPorts_4_0_hold,
  input  [46:0] io_vecReadPorts_4_0_addr,
  output [7:0] io_vecReadPorts_4_0_data,
  input  io_vecReadPorts_4_1_hold,
  input  [46:0] io_vecReadPorts_4_1_addr,
  output [7:0] io_vecReadPorts_4_1_data,
  input  io_vecReadPorts_4_2_hold,
  input  [46:0] io_vecReadPorts_4_2_addr,
  output [7:0] io_vecReadPorts_4_2_data,
  input  io_vecReadPorts_5_0_hold,
  input  [46:0] io_vecReadPorts_5_0_addr,
  output [7:0] io_vecReadPorts_5_0_data,
  input  io_vecReadPorts_5_1_hold,
  input  [46:0] io_vecReadPorts_5_1_addr,
  output [7:0] io_vecReadPorts_5_1_data,
  input  io_vecReadPorts_5_2_hold,
  input  [46:0] io_vecReadPorts_5_2_addr,
  output [7:0] io_vecReadPorts_5_2_data,
  input  io_vecRenamePorts_0_wen,
  input  [46:0] io_vecRenamePorts_0_addr,
  input  [7:0] io_vecRenamePorts_0_data,
  input  io_vecRenamePorts_1_wen,
  input  [46:0] io_vecRenamePorts_1_addr,
  input  [7:0] io_vecRenamePorts_1_data,
  input  io_vecRenamePorts_2_wen,
  input  [46:0] io_vecRenamePorts_2_addr,
  input  [7:0] io_vecRenamePorts_2_data,
  input  io_vecRenamePorts_3_wen,
  input  [46:0] io_vecRenamePorts_3_addr,
  input  [7:0] io_vecRenamePorts_3_data,
  input  io_vecRenamePorts_4_wen,
  input  [46:0] io_vecRenamePorts_4_addr,
  input  [7:0] io_vecRenamePorts_4_data,
  input  io_vecRenamePorts_5_wen,
  input  [46:0] io_vecRenamePorts_5_addr,
  input  [7:0] io_vecRenamePorts_5_data,
  input  io_v0ReadPorts_0_hold,
  output [7:0] io_v0ReadPorts_0_data,
  input  io_v0ReadPorts_1_hold,
  output [7:0] io_v0ReadPorts_1_data,
  input  io_v0ReadPorts_2_hold,
  output [7:0] io_v0ReadPorts_2_data,
  input  io_v0ReadPorts_3_hold,
  output [7:0] io_v0ReadPorts_3_data,
  input  io_v0ReadPorts_4_hold,
  output [7:0] io_v0ReadPorts_4_data,
  input  io_v0ReadPorts_5_hold,
  output [7:0] io_v0ReadPorts_5_data,
  input  io_v0RenamePorts_0_wen,
  input  [7:0] io_v0RenamePorts_0_data,
  input  io_v0RenamePorts_1_wen,
  input  [7:0] io_v0RenamePorts_1_data,
  input  io_v0RenamePorts_2_wen,
  input  [7:0] io_v0RenamePorts_2_data,
  input  io_v0RenamePorts_3_wen,
  input  [7:0] io_v0RenamePorts_3_data,
  input  io_v0RenamePorts_4_wen,
  input  [7:0] io_v0RenamePorts_4_data,
  input  io_v0RenamePorts_5_wen,
  input  [7:0] io_v0RenamePorts_5_data,
  input  io_vlReadPorts_0_hold,
  output [7:0] io_vlReadPorts_0_data,
  input  io_vlReadPorts_1_hold,
  output [7:0] io_vlReadPorts_1_data,
  input  io_vlReadPorts_2_hold,
  output [7:0] io_vlReadPorts_2_data,
  input  io_vlReadPorts_3_hold,
  output [7:0] io_vlReadPorts_3_data,
  input  io_vlReadPorts_4_hold,
  output [7:0] io_vlReadPorts_4_data,
  input  io_vlReadPorts_5_hold,
  output [7:0] io_vlReadPorts_5_data,
  input  io_vlRenamePorts_0_wen,
  input  [7:0] io_vlRenamePorts_0_data,
  input  io_vlRenamePorts_1_wen,
  input  [7:0] io_vlRenamePorts_1_data,
  input  io_vlRenamePorts_2_wen,
  input  [7:0] io_vlRenamePorts_2_data,
  input  io_vlRenamePorts_3_wen,
  input  [7:0] io_vlRenamePorts_3_data,
  input  io_vlRenamePorts_4_wen,
  input  [7:0] io_vlRenamePorts_4_data,
  input  io_vlRenamePorts_5_wen,
  input  [7:0] io_vlRenamePorts_5_data,
  output [7:0] io_int_old_pdest_0,
  output [7:0] io_int_old_pdest_1,
  output [7:0] io_int_old_pdest_2,
  output [7:0] io_int_old_pdest_3,
  output [7:0] io_int_old_pdest_4,
  output [7:0] io_int_old_pdest_5,
  output [7:0] io_fp_old_pdest_0,
  output [7:0] io_fp_old_pdest_1,
  output [7:0] io_fp_old_pdest_2,
  output [7:0] io_fp_old_pdest_3,
  output [7:0] io_fp_old_pdest_4,
  output [7:0] io_fp_old_pdest_5,
  output [7:0] io_vec_old_pdest_0,
  output [7:0] io_vec_old_pdest_1,
  output [7:0] io_vec_old_pdest_2,
  output [7:0] io_vec_old_pdest_3,
  output [7:0] io_vec_old_pdest_4,
  output [7:0] io_vec_old_pdest_5,
  output [7:0] io_v0_old_pdest_0,
  output [7:0] io_v0_old_pdest_1,
  output [7:0] io_v0_old_pdest_2,
  output [7:0] io_v0_old_pdest_3,
  output [7:0] io_v0_old_pdest_4,
  output [7:0] io_v0_old_pdest_5,
  output [7:0] io_vl_old_pdest_0,
  output [7:0] io_vl_old_pdest_1,
  output [7:0] io_vl_old_pdest_2,
  output [7:0] io_vl_old_pdest_3,
  output [7:0] io_vl_old_pdest_4,
  output [7:0] io_vl_old_pdest_5,
  output io_int_need_free_0,
  output io_int_need_free_1,
  output io_int_need_free_2,
  output io_int_need_free_3,
  output io_int_need_free_4,
  output io_int_need_free_5,
  input  io_snpt_snptEnq,
  input  io_snpt_snptDeq,
  input  io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input  io_snpt_flushVec_0,
  input  io_snpt_flushVec_1,
  input  io_snpt_flushVec_2,
  input  io_snpt_flushVec_3,
  output [7:0] io_debug_int_rat_0,
  output [7:0] io_debug_int_rat_1,
  output [7:0] io_debug_int_rat_2,
  output [7:0] io_debug_int_rat_3,
  output [7:0] io_debug_int_rat_4,
  output [7:0] io_debug_int_rat_5,
  output [7:0] io_debug_int_rat_6,
  output [7:0] io_debug_int_rat_7,
  output [7:0] io_debug_int_rat_8,
  output [7:0] io_debug_int_rat_9,
  output [7:0] io_debug_int_rat_10,
  output [7:0] io_debug_int_rat_11,
  output [7:0] io_debug_int_rat_12,
  output [7:0] io_debug_int_rat_13,
  output [7:0] io_debug_int_rat_14,
  output [7:0] io_debug_int_rat_15,
  output [7:0] io_debug_int_rat_16,
  output [7:0] io_debug_int_rat_17,
  output [7:0] io_debug_int_rat_18,
  output [7:0] io_debug_int_rat_19,
  output [7:0] io_debug_int_rat_20,
  output [7:0] io_debug_int_rat_21,
  output [7:0] io_debug_int_rat_22,
  output [7:0] io_debug_int_rat_23,
  output [7:0] io_debug_int_rat_24,
  output [7:0] io_debug_int_rat_25,
  output [7:0] io_debug_int_rat_26,
  output [7:0] io_debug_int_rat_27,
  output [7:0] io_debug_int_rat_28,
  output [7:0] io_debug_int_rat_29,
  output [7:0] io_debug_int_rat_30,
  output [7:0] io_debug_int_rat_31,
  output [7:0] io_diff_vl_rat_0,
  output [263:0] gatewayIn_packed_23_bore,
  output [263:0] gatewayIn_packed_24_bore,
  output [583:0] gatewayIn_packed_25_bore
);
  import renametablewrapper_pkg::*;
  logic [7:0] hartId; logic redirect, rab_isCommit, rab_isWalk;
  logic [RENAME_W-1:0] rab_commitValid, rab_walkValid;
  rab_info_t [RENAME_W-1:0] rab_info;
  logic [RENAME_W-1:0] renameUpdates_valid, renameUpdates_robIdx_flag, renameUpdates_lastUop,
        renameUpdates_rfWen, renameUpdates_fpWen, renameUpdates_vecWen, renameUpdates_v0Wen, renameUpdates_vlWen;
  logic [RENAME_W-1:0][PREG_W-1:0]  renameUpdates_robIdx_value, renameUpdates_pdest;
  logic [RENAME_W-1:0][LDEST_W-1:0] renameUpdates_ldest;
  logic diffRatCommitRobIdx_valid, diffRatCommitRobIdx_flag; logic [PREG_W-1:0] diffRatCommitRobIdx_value;
  logic snpt_snptEnq, snpt_snptDeq, snpt_useSnpt; logic [1:0] snpt_snptSelect; logic [SNPT_N-1:0] snpt_flushVec;
  logic [RENAME_W-1:0][INT_RD_N-1:0][INT_RD_W-1:0] int_rd_addr; logic [RENAME_W-1:0][INT_RD_N-1:0] int_rd_hold;
  logic [RENAME_W-1:0][INT_RD_N-1:0][PREG_W-1:0]   int_rd_data;
  logic [RENAME_W-1:0][FP_RD_N-1:0][FP_RD_W-1:0]   fp_rd_addr;  logic [RENAME_W-1:0][FP_RD_N-1:0]  fp_rd_hold;
  logic [RENAME_W-1:0][FP_RD_N-1:0][PREG_W-1:0]    fp_rd_data;
  logic [RENAME_W-1:0][VEC_RD_N-1:0][VEC_RD_W-1:0] vec_rd_addr; logic [RENAME_W-1:0][VEC_RD_N-1:0] vec_rd_hold;
  logic [RENAME_W-1:0][VEC_RD_N-1:0][PREG_W-1:0]   vec_rd_data;
  logic [RENAME_W-1:0] v0_rd_hold, vl_rd_hold; logic [RENAME_W-1:0][PREG_W-1:0] v0_rd_data, vl_rd_data;
  logic [RENAME_W-1:0] int_rn_wen, fp_rn_wen, vec_rn_wen, v0_rn_wen, vl_rn_wen;
  logic [RENAME_W-1:0][INT_RD_W-1:0] int_rn_addr; logic [RENAME_W-1:0][FP_RD_W-1:0] fp_rn_addr; logic [RENAME_W-1:0][VEC_RD_W-1:0] vec_rn_addr;
  logic [RENAME_W-1:0][PREG_W-1:0] int_rn_data, fp_rn_data, vec_rn_data, v0_rn_data, vl_rn_data;
  logic [RENAME_W-1:0][PREG_W-1:0] int_old_pdest, fp_old_pdest, vec_old_pdest, v0_old_pdest, vl_old_pdest;
  logic [RENAME_W-1:0] int_need_free; logic [INT_N-1:0][PREG_W-1:0] debug_int_rat; logic [PREG_W-1:0] diff_vl_rat;
  logic [INT_N*PREG_W+8-1:0] difftest_rat_xrf; logic [FP_N*PREG_W+8-1:0] difftest_rat_frf; logic [2*(1+VEC_N)*9+8-1:0] difftest_rat_vrf;
  always_comb begin
    hartId = io_hartId;
    redirect = io_redirect;
    rab_isCommit = io_rabCommits_isCommit;
    rab_commitValid[0] = io_rabCommits_commitValid_0;
    rab_commitValid[1] = io_rabCommits_commitValid_1;
    rab_commitValid[2] = io_rabCommits_commitValid_2;
    rab_commitValid[3] = io_rabCommits_commitValid_3;
    rab_commitValid[4] = io_rabCommits_commitValid_4;
    rab_commitValid[5] = io_rabCommits_commitValid_5;
    rab_isWalk = io_rabCommits_isWalk;
    rab_walkValid[0] = io_rabCommits_walkValid_0;
    rab_walkValid[1] = io_rabCommits_walkValid_1;
    rab_walkValid[2] = io_rabCommits_walkValid_2;
    rab_walkValid[3] = io_rabCommits_walkValid_3;
    rab_walkValid[4] = io_rabCommits_walkValid_4;
    rab_walkValid[5] = io_rabCommits_walkValid_5;
    rab_info[0].ldest = io_rabCommits_info_0_ldest;
    rab_info[0].pdest = io_rabCommits_info_0_pdest;
    rab_info[0].rfWen = io_rabCommits_info_0_rfWen;
    rab_info[0].fpWen = io_rabCommits_info_0_fpWen;
    rab_info[0].vecWen = io_rabCommits_info_0_vecWen;
    rab_info[0].v0Wen = io_rabCommits_info_0_v0Wen;
    rab_info[0].vlWen = io_rabCommits_info_0_vlWen;
    rab_info[1].ldest = io_rabCommits_info_1_ldest;
    rab_info[1].pdest = io_rabCommits_info_1_pdest;
    rab_info[1].rfWen = io_rabCommits_info_1_rfWen;
    rab_info[1].fpWen = io_rabCommits_info_1_fpWen;
    rab_info[1].vecWen = io_rabCommits_info_1_vecWen;
    rab_info[1].v0Wen = io_rabCommits_info_1_v0Wen;
    rab_info[1].vlWen = io_rabCommits_info_1_vlWen;
    rab_info[2].ldest = io_rabCommits_info_2_ldest;
    rab_info[2].pdest = io_rabCommits_info_2_pdest;
    rab_info[2].rfWen = io_rabCommits_info_2_rfWen;
    rab_info[2].fpWen = io_rabCommits_info_2_fpWen;
    rab_info[2].vecWen = io_rabCommits_info_2_vecWen;
    rab_info[2].v0Wen = io_rabCommits_info_2_v0Wen;
    rab_info[2].vlWen = io_rabCommits_info_2_vlWen;
    rab_info[3].ldest = io_rabCommits_info_3_ldest;
    rab_info[3].pdest = io_rabCommits_info_3_pdest;
    rab_info[3].rfWen = io_rabCommits_info_3_rfWen;
    rab_info[3].fpWen = io_rabCommits_info_3_fpWen;
    rab_info[3].vecWen = io_rabCommits_info_3_vecWen;
    rab_info[3].v0Wen = io_rabCommits_info_3_v0Wen;
    rab_info[3].vlWen = io_rabCommits_info_3_vlWen;
    rab_info[4].ldest = io_rabCommits_info_4_ldest;
    rab_info[4].pdest = io_rabCommits_info_4_pdest;
    rab_info[4].rfWen = io_rabCommits_info_4_rfWen;
    rab_info[4].fpWen = io_rabCommits_info_4_fpWen;
    rab_info[4].vecWen = io_rabCommits_info_4_vecWen;
    rab_info[4].v0Wen = io_rabCommits_info_4_v0Wen;
    rab_info[4].vlWen = io_rabCommits_info_4_vlWen;
    rab_info[5].ldest = io_rabCommits_info_5_ldest;
    rab_info[5].pdest = io_rabCommits_info_5_pdest;
    rab_info[5].rfWen = io_rabCommits_info_5_rfWen;
    rab_info[5].fpWen = io_rabCommits_info_5_fpWen;
    rab_info[5].vecWen = io_rabCommits_info_5_vecWen;
    rab_info[5].v0Wen = io_rabCommits_info_5_v0Wen;
    rab_info[5].vlWen = io_rabCommits_info_5_vlWen;
    renameUpdates_valid[0] = io_renameUpdates_0_valid;
    renameUpdates_robIdx_flag[0] = io_renameUpdates_0_bits_robIdx_flag;
    renameUpdates_robIdx_value[0] = io_renameUpdates_0_bits_robIdx_value;
    renameUpdates_lastUop[0] = io_renameUpdates_0_bits_lastUop;
    renameUpdates_ldest[0] = io_renameUpdates_0_bits_ldest;
    renameUpdates_pdest[0] = io_renameUpdates_0_bits_pdest;
    renameUpdates_rfWen[0] = io_renameUpdates_0_bits_rfWen;
    renameUpdates_fpWen[0] = io_renameUpdates_0_bits_fpWen;
    renameUpdates_vecWen[0] = io_renameUpdates_0_bits_vecWen;
    renameUpdates_v0Wen[0] = io_renameUpdates_0_bits_v0Wen;
    renameUpdates_vlWen[0] = io_renameUpdates_0_bits_vlWen;
    renameUpdates_valid[1] = io_renameUpdates_1_valid;
    renameUpdates_robIdx_flag[1] = io_renameUpdates_1_bits_robIdx_flag;
    renameUpdates_robIdx_value[1] = io_renameUpdates_1_bits_robIdx_value;
    renameUpdates_lastUop[1] = io_renameUpdates_1_bits_lastUop;
    renameUpdates_ldest[1] = io_renameUpdates_1_bits_ldest;
    renameUpdates_pdest[1] = io_renameUpdates_1_bits_pdest;
    renameUpdates_rfWen[1] = io_renameUpdates_1_bits_rfWen;
    renameUpdates_fpWen[1] = io_renameUpdates_1_bits_fpWen;
    renameUpdates_vecWen[1] = io_renameUpdates_1_bits_vecWen;
    renameUpdates_v0Wen[1] = io_renameUpdates_1_bits_v0Wen;
    renameUpdates_vlWen[1] = io_renameUpdates_1_bits_vlWen;
    renameUpdates_valid[2] = io_renameUpdates_2_valid;
    renameUpdates_robIdx_flag[2] = io_renameUpdates_2_bits_robIdx_flag;
    renameUpdates_robIdx_value[2] = io_renameUpdates_2_bits_robIdx_value;
    renameUpdates_lastUop[2] = io_renameUpdates_2_bits_lastUop;
    renameUpdates_ldest[2] = io_renameUpdates_2_bits_ldest;
    renameUpdates_pdest[2] = io_renameUpdates_2_bits_pdest;
    renameUpdates_rfWen[2] = io_renameUpdates_2_bits_rfWen;
    renameUpdates_fpWen[2] = io_renameUpdates_2_bits_fpWen;
    renameUpdates_vecWen[2] = io_renameUpdates_2_bits_vecWen;
    renameUpdates_v0Wen[2] = io_renameUpdates_2_bits_v0Wen;
    renameUpdates_vlWen[2] = io_renameUpdates_2_bits_vlWen;
    renameUpdates_valid[3] = io_renameUpdates_3_valid;
    renameUpdates_robIdx_flag[3] = io_renameUpdates_3_bits_robIdx_flag;
    renameUpdates_robIdx_value[3] = io_renameUpdates_3_bits_robIdx_value;
    renameUpdates_lastUop[3] = io_renameUpdates_3_bits_lastUop;
    renameUpdates_ldest[3] = io_renameUpdates_3_bits_ldest;
    renameUpdates_pdest[3] = io_renameUpdates_3_bits_pdest;
    renameUpdates_rfWen[3] = io_renameUpdates_3_bits_rfWen;
    renameUpdates_fpWen[3] = io_renameUpdates_3_bits_fpWen;
    renameUpdates_vecWen[3] = io_renameUpdates_3_bits_vecWen;
    renameUpdates_v0Wen[3] = io_renameUpdates_3_bits_v0Wen;
    renameUpdates_vlWen[3] = io_renameUpdates_3_bits_vlWen;
    renameUpdates_valid[4] = io_renameUpdates_4_valid;
    renameUpdates_robIdx_flag[4] = io_renameUpdates_4_bits_robIdx_flag;
    renameUpdates_robIdx_value[4] = io_renameUpdates_4_bits_robIdx_value;
    renameUpdates_lastUop[4] = io_renameUpdates_4_bits_lastUop;
    renameUpdates_ldest[4] = io_renameUpdates_4_bits_ldest;
    renameUpdates_pdest[4] = io_renameUpdates_4_bits_pdest;
    renameUpdates_rfWen[4] = io_renameUpdates_4_bits_rfWen;
    renameUpdates_fpWen[4] = io_renameUpdates_4_bits_fpWen;
    renameUpdates_vecWen[4] = io_renameUpdates_4_bits_vecWen;
    renameUpdates_v0Wen[4] = io_renameUpdates_4_bits_v0Wen;
    renameUpdates_vlWen[4] = io_renameUpdates_4_bits_vlWen;
    renameUpdates_valid[5] = io_renameUpdates_5_valid;
    renameUpdates_robIdx_flag[5] = io_renameUpdates_5_bits_robIdx_flag;
    renameUpdates_robIdx_value[5] = io_renameUpdates_5_bits_robIdx_value;
    renameUpdates_lastUop[5] = io_renameUpdates_5_bits_lastUop;
    renameUpdates_ldest[5] = io_renameUpdates_5_bits_ldest;
    renameUpdates_pdest[5] = io_renameUpdates_5_bits_pdest;
    renameUpdates_rfWen[5] = io_renameUpdates_5_bits_rfWen;
    renameUpdates_fpWen[5] = io_renameUpdates_5_bits_fpWen;
    renameUpdates_vecWen[5] = io_renameUpdates_5_bits_vecWen;
    renameUpdates_v0Wen[5] = io_renameUpdates_5_bits_v0Wen;
    renameUpdates_vlWen[5] = io_renameUpdates_5_bits_vlWen;
    diffRatCommitRobIdx_valid = io_diffRatCommitRobIdx_valid;
    diffRatCommitRobIdx_flag = io_diffRatCommitRobIdx_bits_flag;
    diffRatCommitRobIdx_value = io_diffRatCommitRobIdx_bits_value;
    int_rd_hold[0][0] = io_intReadPorts_0_0_hold;
    int_rd_addr[0][0] = io_intReadPorts_0_0_addr;
    int_rd_hold[0][1] = io_intReadPorts_0_1_hold;
    int_rd_addr[0][1] = io_intReadPorts_0_1_addr;
    int_rd_hold[1][0] = io_intReadPorts_1_0_hold;
    int_rd_addr[1][0] = io_intReadPorts_1_0_addr;
    int_rd_hold[1][1] = io_intReadPorts_1_1_hold;
    int_rd_addr[1][1] = io_intReadPorts_1_1_addr;
    int_rd_hold[2][0] = io_intReadPorts_2_0_hold;
    int_rd_addr[2][0] = io_intReadPorts_2_0_addr;
    int_rd_hold[2][1] = io_intReadPorts_2_1_hold;
    int_rd_addr[2][1] = io_intReadPorts_2_1_addr;
    int_rd_hold[3][0] = io_intReadPorts_3_0_hold;
    int_rd_addr[3][0] = io_intReadPorts_3_0_addr;
    int_rd_hold[3][1] = io_intReadPorts_3_1_hold;
    int_rd_addr[3][1] = io_intReadPorts_3_1_addr;
    int_rd_hold[4][0] = io_intReadPorts_4_0_hold;
    int_rd_addr[4][0] = io_intReadPorts_4_0_addr;
    int_rd_hold[4][1] = io_intReadPorts_4_1_hold;
    int_rd_addr[4][1] = io_intReadPorts_4_1_addr;
    int_rd_hold[5][0] = io_intReadPorts_5_0_hold;
    int_rd_addr[5][0] = io_intReadPorts_5_0_addr;
    int_rd_hold[5][1] = io_intReadPorts_5_1_hold;
    int_rd_addr[5][1] = io_intReadPorts_5_1_addr;
    int_rn_wen[0] = io_intRenamePorts_0_wen;
    int_rn_addr[0] = io_intRenamePorts_0_addr;
    int_rn_data[0] = io_intRenamePorts_0_data;
    int_rn_wen[1] = io_intRenamePorts_1_wen;
    int_rn_addr[1] = io_intRenamePorts_1_addr;
    int_rn_data[1] = io_intRenamePorts_1_data;
    int_rn_wen[2] = io_intRenamePorts_2_wen;
    int_rn_addr[2] = io_intRenamePorts_2_addr;
    int_rn_data[2] = io_intRenamePorts_2_data;
    int_rn_wen[3] = io_intRenamePorts_3_wen;
    int_rn_addr[3] = io_intRenamePorts_3_addr;
    int_rn_data[3] = io_intRenamePorts_3_data;
    int_rn_wen[4] = io_intRenamePorts_4_wen;
    int_rn_addr[4] = io_intRenamePorts_4_addr;
    int_rn_data[4] = io_intRenamePorts_4_data;
    int_rn_wen[5] = io_intRenamePorts_5_wen;
    int_rn_addr[5] = io_intRenamePorts_5_addr;
    int_rn_data[5] = io_intRenamePorts_5_data;
    fp_rd_hold[0][0] = io_fpReadPorts_0_0_hold;
    fp_rd_addr[0][0] = io_fpReadPorts_0_0_addr;
    fp_rd_hold[0][1] = io_fpReadPorts_0_1_hold;
    fp_rd_addr[0][1] = io_fpReadPorts_0_1_addr;
    fp_rd_hold[0][2] = io_fpReadPorts_0_2_hold;
    fp_rd_addr[0][2] = io_fpReadPorts_0_2_addr;
    fp_rd_hold[1][0] = io_fpReadPorts_1_0_hold;
    fp_rd_addr[1][0] = io_fpReadPorts_1_0_addr;
    fp_rd_hold[1][1] = io_fpReadPorts_1_1_hold;
    fp_rd_addr[1][1] = io_fpReadPorts_1_1_addr;
    fp_rd_hold[1][2] = io_fpReadPorts_1_2_hold;
    fp_rd_addr[1][2] = io_fpReadPorts_1_2_addr;
    fp_rd_hold[2][0] = io_fpReadPorts_2_0_hold;
    fp_rd_addr[2][0] = io_fpReadPorts_2_0_addr;
    fp_rd_hold[2][1] = io_fpReadPorts_2_1_hold;
    fp_rd_addr[2][1] = io_fpReadPorts_2_1_addr;
    fp_rd_hold[2][2] = io_fpReadPorts_2_2_hold;
    fp_rd_addr[2][2] = io_fpReadPorts_2_2_addr;
    fp_rd_hold[3][0] = io_fpReadPorts_3_0_hold;
    fp_rd_addr[3][0] = io_fpReadPorts_3_0_addr;
    fp_rd_hold[3][1] = io_fpReadPorts_3_1_hold;
    fp_rd_addr[3][1] = io_fpReadPorts_3_1_addr;
    fp_rd_hold[3][2] = io_fpReadPorts_3_2_hold;
    fp_rd_addr[3][2] = io_fpReadPorts_3_2_addr;
    fp_rd_hold[4][0] = io_fpReadPorts_4_0_hold;
    fp_rd_addr[4][0] = io_fpReadPorts_4_0_addr;
    fp_rd_hold[4][1] = io_fpReadPorts_4_1_hold;
    fp_rd_addr[4][1] = io_fpReadPorts_4_1_addr;
    fp_rd_hold[4][2] = io_fpReadPorts_4_2_hold;
    fp_rd_addr[4][2] = io_fpReadPorts_4_2_addr;
    fp_rd_hold[5][0] = io_fpReadPorts_5_0_hold;
    fp_rd_addr[5][0] = io_fpReadPorts_5_0_addr;
    fp_rd_hold[5][1] = io_fpReadPorts_5_1_hold;
    fp_rd_addr[5][1] = io_fpReadPorts_5_1_addr;
    fp_rd_hold[5][2] = io_fpReadPorts_5_2_hold;
    fp_rd_addr[5][2] = io_fpReadPorts_5_2_addr;
    fp_rn_wen[0] = io_fpRenamePorts_0_wen;
    fp_rn_addr[0] = io_fpRenamePorts_0_addr;
    fp_rn_data[0] = io_fpRenamePorts_0_data;
    fp_rn_wen[1] = io_fpRenamePorts_1_wen;
    fp_rn_addr[1] = io_fpRenamePorts_1_addr;
    fp_rn_data[1] = io_fpRenamePorts_1_data;
    fp_rn_wen[2] = io_fpRenamePorts_2_wen;
    fp_rn_addr[2] = io_fpRenamePorts_2_addr;
    fp_rn_data[2] = io_fpRenamePorts_2_data;
    fp_rn_wen[3] = io_fpRenamePorts_3_wen;
    fp_rn_addr[3] = io_fpRenamePorts_3_addr;
    fp_rn_data[3] = io_fpRenamePorts_3_data;
    fp_rn_wen[4] = io_fpRenamePorts_4_wen;
    fp_rn_addr[4] = io_fpRenamePorts_4_addr;
    fp_rn_data[4] = io_fpRenamePorts_4_data;
    fp_rn_wen[5] = io_fpRenamePorts_5_wen;
    fp_rn_addr[5] = io_fpRenamePorts_5_addr;
    fp_rn_data[5] = io_fpRenamePorts_5_data;
    vec_rd_hold[0][0] = io_vecReadPorts_0_0_hold;
    vec_rd_addr[0][0] = io_vecReadPorts_0_0_addr;
    vec_rd_hold[0][1] = io_vecReadPorts_0_1_hold;
    vec_rd_addr[0][1] = io_vecReadPorts_0_1_addr;
    vec_rd_hold[0][2] = io_vecReadPorts_0_2_hold;
    vec_rd_addr[0][2] = io_vecReadPorts_0_2_addr;
    vec_rd_hold[1][0] = io_vecReadPorts_1_0_hold;
    vec_rd_addr[1][0] = io_vecReadPorts_1_0_addr;
    vec_rd_hold[1][1] = io_vecReadPorts_1_1_hold;
    vec_rd_addr[1][1] = io_vecReadPorts_1_1_addr;
    vec_rd_hold[1][2] = io_vecReadPorts_1_2_hold;
    vec_rd_addr[1][2] = io_vecReadPorts_1_2_addr;
    vec_rd_hold[2][0] = io_vecReadPorts_2_0_hold;
    vec_rd_addr[2][0] = io_vecReadPorts_2_0_addr;
    vec_rd_hold[2][1] = io_vecReadPorts_2_1_hold;
    vec_rd_addr[2][1] = io_vecReadPorts_2_1_addr;
    vec_rd_hold[2][2] = io_vecReadPorts_2_2_hold;
    vec_rd_addr[2][2] = io_vecReadPorts_2_2_addr;
    vec_rd_hold[3][0] = io_vecReadPorts_3_0_hold;
    vec_rd_addr[3][0] = io_vecReadPorts_3_0_addr;
    vec_rd_hold[3][1] = io_vecReadPorts_3_1_hold;
    vec_rd_addr[3][1] = io_vecReadPorts_3_1_addr;
    vec_rd_hold[3][2] = io_vecReadPorts_3_2_hold;
    vec_rd_addr[3][2] = io_vecReadPorts_3_2_addr;
    vec_rd_hold[4][0] = io_vecReadPorts_4_0_hold;
    vec_rd_addr[4][0] = io_vecReadPorts_4_0_addr;
    vec_rd_hold[4][1] = io_vecReadPorts_4_1_hold;
    vec_rd_addr[4][1] = io_vecReadPorts_4_1_addr;
    vec_rd_hold[4][2] = io_vecReadPorts_4_2_hold;
    vec_rd_addr[4][2] = io_vecReadPorts_4_2_addr;
    vec_rd_hold[5][0] = io_vecReadPorts_5_0_hold;
    vec_rd_addr[5][0] = io_vecReadPorts_5_0_addr;
    vec_rd_hold[5][1] = io_vecReadPorts_5_1_hold;
    vec_rd_addr[5][1] = io_vecReadPorts_5_1_addr;
    vec_rd_hold[5][2] = io_vecReadPorts_5_2_hold;
    vec_rd_addr[5][2] = io_vecReadPorts_5_2_addr;
    vec_rn_wen[0] = io_vecRenamePorts_0_wen;
    vec_rn_addr[0] = io_vecRenamePorts_0_addr;
    vec_rn_data[0] = io_vecRenamePorts_0_data;
    vec_rn_wen[1] = io_vecRenamePorts_1_wen;
    vec_rn_addr[1] = io_vecRenamePorts_1_addr;
    vec_rn_data[1] = io_vecRenamePorts_1_data;
    vec_rn_wen[2] = io_vecRenamePorts_2_wen;
    vec_rn_addr[2] = io_vecRenamePorts_2_addr;
    vec_rn_data[2] = io_vecRenamePorts_2_data;
    vec_rn_wen[3] = io_vecRenamePorts_3_wen;
    vec_rn_addr[3] = io_vecRenamePorts_3_addr;
    vec_rn_data[3] = io_vecRenamePorts_3_data;
    vec_rn_wen[4] = io_vecRenamePorts_4_wen;
    vec_rn_addr[4] = io_vecRenamePorts_4_addr;
    vec_rn_data[4] = io_vecRenamePorts_4_data;
    vec_rn_wen[5] = io_vecRenamePorts_5_wen;
    vec_rn_addr[5] = io_vecRenamePorts_5_addr;
    vec_rn_data[5] = io_vecRenamePorts_5_data;
    v0_rd_hold[0] = io_v0ReadPorts_0_hold;
    v0_rd_hold[1] = io_v0ReadPorts_1_hold;
    v0_rd_hold[2] = io_v0ReadPorts_2_hold;
    v0_rd_hold[3] = io_v0ReadPorts_3_hold;
    v0_rd_hold[4] = io_v0ReadPorts_4_hold;
    v0_rd_hold[5] = io_v0ReadPorts_5_hold;
    v0_rn_wen[0] = io_v0RenamePorts_0_wen;
    v0_rn_data[0] = io_v0RenamePorts_0_data;
    v0_rn_wen[1] = io_v0RenamePorts_1_wen;
    v0_rn_data[1] = io_v0RenamePorts_1_data;
    v0_rn_wen[2] = io_v0RenamePorts_2_wen;
    v0_rn_data[2] = io_v0RenamePorts_2_data;
    v0_rn_wen[3] = io_v0RenamePorts_3_wen;
    v0_rn_data[3] = io_v0RenamePorts_3_data;
    v0_rn_wen[4] = io_v0RenamePorts_4_wen;
    v0_rn_data[4] = io_v0RenamePorts_4_data;
    v0_rn_wen[5] = io_v0RenamePorts_5_wen;
    v0_rn_data[5] = io_v0RenamePorts_5_data;
    vl_rd_hold[0] = io_vlReadPorts_0_hold;
    vl_rd_hold[1] = io_vlReadPorts_1_hold;
    vl_rd_hold[2] = io_vlReadPorts_2_hold;
    vl_rd_hold[3] = io_vlReadPorts_3_hold;
    vl_rd_hold[4] = io_vlReadPorts_4_hold;
    vl_rd_hold[5] = io_vlReadPorts_5_hold;
    vl_rn_wen[0] = io_vlRenamePorts_0_wen;
    vl_rn_data[0] = io_vlRenamePorts_0_data;
    vl_rn_wen[1] = io_vlRenamePorts_1_wen;
    vl_rn_data[1] = io_vlRenamePorts_1_data;
    vl_rn_wen[2] = io_vlRenamePorts_2_wen;
    vl_rn_data[2] = io_vlRenamePorts_2_data;
    vl_rn_wen[3] = io_vlRenamePorts_3_wen;
    vl_rn_data[3] = io_vlRenamePorts_3_data;
    vl_rn_wen[4] = io_vlRenamePorts_4_wen;
    vl_rn_data[4] = io_vlRenamePorts_4_data;
    vl_rn_wen[5] = io_vlRenamePorts_5_wen;
    vl_rn_data[5] = io_vlRenamePorts_5_data;
    snpt_snptEnq = io_snpt_snptEnq;
    snpt_snptDeq = io_snpt_snptDeq;
    snpt_useSnpt = io_snpt_useSnpt;
    snpt_snptSelect = io_snpt_snptSelect;
    snpt_flushVec[0] = io_snpt_flushVec_0;
    snpt_flushVec[1] = io_snpt_flushVec_1;
    snpt_flushVec[2] = io_snpt_flushVec_2;
    snpt_flushVec[3] = io_snpt_flushVec_3;
  end
  assign io_intReadPorts_0_0_data = int_rd_data[0][0];
  assign io_intReadPorts_0_1_data = int_rd_data[0][1];
  assign io_intReadPorts_1_0_data = int_rd_data[1][0];
  assign io_intReadPorts_1_1_data = int_rd_data[1][1];
  assign io_intReadPorts_2_0_data = int_rd_data[2][0];
  assign io_intReadPorts_2_1_data = int_rd_data[2][1];
  assign io_intReadPorts_3_0_data = int_rd_data[3][0];
  assign io_intReadPorts_3_1_data = int_rd_data[3][1];
  assign io_intReadPorts_4_0_data = int_rd_data[4][0];
  assign io_intReadPorts_4_1_data = int_rd_data[4][1];
  assign io_intReadPorts_5_0_data = int_rd_data[5][0];
  assign io_intReadPorts_5_1_data = int_rd_data[5][1];
  assign io_fpReadPorts_0_0_data = fp_rd_data[0][0];
  assign io_fpReadPorts_0_1_data = fp_rd_data[0][1];
  assign io_fpReadPorts_0_2_data = fp_rd_data[0][2];
  assign io_fpReadPorts_1_0_data = fp_rd_data[1][0];
  assign io_fpReadPorts_1_1_data = fp_rd_data[1][1];
  assign io_fpReadPorts_1_2_data = fp_rd_data[1][2];
  assign io_fpReadPorts_2_0_data = fp_rd_data[2][0];
  assign io_fpReadPorts_2_1_data = fp_rd_data[2][1];
  assign io_fpReadPorts_2_2_data = fp_rd_data[2][2];
  assign io_fpReadPorts_3_0_data = fp_rd_data[3][0];
  assign io_fpReadPorts_3_1_data = fp_rd_data[3][1];
  assign io_fpReadPorts_3_2_data = fp_rd_data[3][2];
  assign io_fpReadPorts_4_0_data = fp_rd_data[4][0];
  assign io_fpReadPorts_4_1_data = fp_rd_data[4][1];
  assign io_fpReadPorts_4_2_data = fp_rd_data[4][2];
  assign io_fpReadPorts_5_0_data = fp_rd_data[5][0];
  assign io_fpReadPorts_5_1_data = fp_rd_data[5][1];
  assign io_fpReadPorts_5_2_data = fp_rd_data[5][2];
  assign io_vecReadPorts_0_0_data = vec_rd_data[0][0];
  assign io_vecReadPorts_0_1_data = vec_rd_data[0][1];
  assign io_vecReadPorts_0_2_data = vec_rd_data[0][2];
  assign io_vecReadPorts_1_0_data = vec_rd_data[1][0];
  assign io_vecReadPorts_1_1_data = vec_rd_data[1][1];
  assign io_vecReadPorts_1_2_data = vec_rd_data[1][2];
  assign io_vecReadPorts_2_0_data = vec_rd_data[2][0];
  assign io_vecReadPorts_2_1_data = vec_rd_data[2][1];
  assign io_vecReadPorts_2_2_data = vec_rd_data[2][2];
  assign io_vecReadPorts_3_0_data = vec_rd_data[3][0];
  assign io_vecReadPorts_3_1_data = vec_rd_data[3][1];
  assign io_vecReadPorts_3_2_data = vec_rd_data[3][2];
  assign io_vecReadPorts_4_0_data = vec_rd_data[4][0];
  assign io_vecReadPorts_4_1_data = vec_rd_data[4][1];
  assign io_vecReadPorts_4_2_data = vec_rd_data[4][2];
  assign io_vecReadPorts_5_0_data = vec_rd_data[5][0];
  assign io_vecReadPorts_5_1_data = vec_rd_data[5][1];
  assign io_vecReadPorts_5_2_data = vec_rd_data[5][2];
  assign io_v0ReadPorts_0_data = v0_rd_data[0];
  assign io_v0ReadPorts_1_data = v0_rd_data[1];
  assign io_v0ReadPorts_2_data = v0_rd_data[2];
  assign io_v0ReadPorts_3_data = v0_rd_data[3];
  assign io_v0ReadPorts_4_data = v0_rd_data[4];
  assign io_v0ReadPorts_5_data = v0_rd_data[5];
  assign io_vlReadPorts_0_data = vl_rd_data[0];
  assign io_vlReadPorts_1_data = vl_rd_data[1];
  assign io_vlReadPorts_2_data = vl_rd_data[2];
  assign io_vlReadPorts_3_data = vl_rd_data[3];
  assign io_vlReadPorts_4_data = vl_rd_data[4];
  assign io_vlReadPorts_5_data = vl_rd_data[5];
  assign io_int_old_pdest_0 = int_old_pdest[0];
  assign io_int_old_pdest_1 = int_old_pdest[1];
  assign io_int_old_pdest_2 = int_old_pdest[2];
  assign io_int_old_pdest_3 = int_old_pdest[3];
  assign io_int_old_pdest_4 = int_old_pdest[4];
  assign io_int_old_pdest_5 = int_old_pdest[5];
  assign io_fp_old_pdest_0 = fp_old_pdest[0];
  assign io_fp_old_pdest_1 = fp_old_pdest[1];
  assign io_fp_old_pdest_2 = fp_old_pdest[2];
  assign io_fp_old_pdest_3 = fp_old_pdest[3];
  assign io_fp_old_pdest_4 = fp_old_pdest[4];
  assign io_fp_old_pdest_5 = fp_old_pdest[5];
  assign io_vec_old_pdest_0 = vec_old_pdest[0];
  assign io_vec_old_pdest_1 = vec_old_pdest[1];
  assign io_vec_old_pdest_2 = vec_old_pdest[2];
  assign io_vec_old_pdest_3 = vec_old_pdest[3];
  assign io_vec_old_pdest_4 = vec_old_pdest[4];
  assign io_vec_old_pdest_5 = vec_old_pdest[5];
  assign io_v0_old_pdest_0 = v0_old_pdest[0];
  assign io_v0_old_pdest_1 = v0_old_pdest[1];
  assign io_v0_old_pdest_2 = v0_old_pdest[2];
  assign io_v0_old_pdest_3 = v0_old_pdest[3];
  assign io_v0_old_pdest_4 = v0_old_pdest[4];
  assign io_v0_old_pdest_5 = v0_old_pdest[5];
  assign io_vl_old_pdest_0 = vl_old_pdest[0];
  assign io_vl_old_pdest_1 = vl_old_pdest[1];
  assign io_vl_old_pdest_2 = vl_old_pdest[2];
  assign io_vl_old_pdest_3 = vl_old_pdest[3];
  assign io_vl_old_pdest_4 = vl_old_pdest[4];
  assign io_vl_old_pdest_5 = vl_old_pdest[5];
  assign io_int_need_free_0 = int_need_free[0];
  assign io_int_need_free_1 = int_need_free[1];
  assign io_int_need_free_2 = int_need_free[2];
  assign io_int_need_free_3 = int_need_free[3];
  assign io_int_need_free_4 = int_need_free[4];
  assign io_int_need_free_5 = int_need_free[5];
  assign io_debug_int_rat_0 = debug_int_rat[0];
  assign io_debug_int_rat_1 = debug_int_rat[1];
  assign io_debug_int_rat_2 = debug_int_rat[2];
  assign io_debug_int_rat_3 = debug_int_rat[3];
  assign io_debug_int_rat_4 = debug_int_rat[4];
  assign io_debug_int_rat_5 = debug_int_rat[5];
  assign io_debug_int_rat_6 = debug_int_rat[6];
  assign io_debug_int_rat_7 = debug_int_rat[7];
  assign io_debug_int_rat_8 = debug_int_rat[8];
  assign io_debug_int_rat_9 = debug_int_rat[9];
  assign io_debug_int_rat_10 = debug_int_rat[10];
  assign io_debug_int_rat_11 = debug_int_rat[11];
  assign io_debug_int_rat_12 = debug_int_rat[12];
  assign io_debug_int_rat_13 = debug_int_rat[13];
  assign io_debug_int_rat_14 = debug_int_rat[14];
  assign io_debug_int_rat_15 = debug_int_rat[15];
  assign io_debug_int_rat_16 = debug_int_rat[16];
  assign io_debug_int_rat_17 = debug_int_rat[17];
  assign io_debug_int_rat_18 = debug_int_rat[18];
  assign io_debug_int_rat_19 = debug_int_rat[19];
  assign io_debug_int_rat_20 = debug_int_rat[20];
  assign io_debug_int_rat_21 = debug_int_rat[21];
  assign io_debug_int_rat_22 = debug_int_rat[22];
  assign io_debug_int_rat_23 = debug_int_rat[23];
  assign io_debug_int_rat_24 = debug_int_rat[24];
  assign io_debug_int_rat_25 = debug_int_rat[25];
  assign io_debug_int_rat_26 = debug_int_rat[26];
  assign io_debug_int_rat_27 = debug_int_rat[27];
  assign io_debug_int_rat_28 = debug_int_rat[28];
  assign io_debug_int_rat_29 = debug_int_rat[29];
  assign io_debug_int_rat_30 = debug_int_rat[30];
  assign io_debug_int_rat_31 = debug_int_rat[31];
  assign io_diff_vl_rat_0 = diff_vl_rat;
  assign gatewayIn_packed_23_bore = difftest_rat_xrf;
  assign gatewayIn_packed_24_bore = difftest_rat_frf;
  assign gatewayIn_packed_25_bore = difftest_rat_vrf;
  xs_RenameTableWrapper_core u_core (
    .clock(clock),
    .reset(reset),
    .hartId(hartId),
    .redirect(redirect),
    .rab_isCommit(rab_isCommit),
    .rab_isWalk(rab_isWalk),
    .rab_commitValid(rab_commitValid),
    .rab_walkValid(rab_walkValid),
    .rab_info(rab_info),
    .renameUpdates_valid(renameUpdates_valid),
    .renameUpdates_robIdx_flag(renameUpdates_robIdx_flag),
    .renameUpdates_robIdx_value(renameUpdates_robIdx_value),
    .renameUpdates_lastUop(renameUpdates_lastUop),
    .renameUpdates_ldest(renameUpdates_ldest),
    .renameUpdates_pdest(renameUpdates_pdest),
    .renameUpdates_rfWen(renameUpdates_rfWen),
    .renameUpdates_fpWen(renameUpdates_fpWen),
    .renameUpdates_vecWen(renameUpdates_vecWen),
    .renameUpdates_v0Wen(renameUpdates_v0Wen),
    .renameUpdates_vlWen(renameUpdates_vlWen),
    .diffRatCommitRobIdx_valid(diffRatCommitRobIdx_valid),
    .diffRatCommitRobIdx_flag(diffRatCommitRobIdx_flag),
    .diffRatCommitRobIdx_value(diffRatCommitRobIdx_value),
    .snpt_snptEnq(snpt_snptEnq),
    .snpt_snptDeq(snpt_snptDeq),
    .snpt_useSnpt(snpt_useSnpt),
    .snpt_snptSelect(snpt_snptSelect),
    .snpt_flushVec(snpt_flushVec),
    .int_rd_addr(int_rd_addr),
    .int_rd_hold(int_rd_hold),
    .int_rd_data(int_rd_data),
    .fp_rd_addr(fp_rd_addr),
    .fp_rd_hold(fp_rd_hold),
    .fp_rd_data(fp_rd_data),
    .vec_rd_addr(vec_rd_addr),
    .vec_rd_hold(vec_rd_hold),
    .vec_rd_data(vec_rd_data),
    .v0_rd_hold(v0_rd_hold),
    .v0_rd_data(v0_rd_data),
    .vl_rd_hold(vl_rd_hold),
    .vl_rd_data(vl_rd_data),
    .int_rn_wen(int_rn_wen),
    .int_rn_addr(int_rn_addr),
    .int_rn_data(int_rn_data),
    .fp_rn_wen(fp_rn_wen),
    .fp_rn_addr(fp_rn_addr),
    .fp_rn_data(fp_rn_data),
    .vec_rn_wen(vec_rn_wen),
    .vec_rn_addr(vec_rn_addr),
    .vec_rn_data(vec_rn_data),
    .v0_rn_wen(v0_rn_wen),
    .v0_rn_data(v0_rn_data),
    .vl_rn_wen(vl_rn_wen),
    .vl_rn_data(vl_rn_data),
    .int_old_pdest(int_old_pdest),
    .fp_old_pdest(fp_old_pdest),
    .vec_old_pdest(vec_old_pdest),
    .v0_old_pdest(v0_old_pdest),
    .vl_old_pdest(vl_old_pdest),
    .int_need_free(int_need_free),
    .debug_int_rat(debug_int_rat),
    .diff_vl_rat(diff_vl_rat),
    .difftest_rat_xrf(difftest_rat_xrf),
    .difftest_rat_frf(difftest_rat_frf),
    .difftest_rat_vrf(difftest_rat_vrf)
  );
endmodule
// END GENERATED
