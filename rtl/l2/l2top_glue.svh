// 自动生成:scripts/gen_l2top.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// ===== 顶层 glue(从 Scala 意图重写,golden 已具名可读,原样保留)=====
// (A) 输入 fanin 改名 + 组合直通(hartId / cpu_halt / cpu_critical_error)。
//     纯连线改名,无任何运算。

  wire [63:0]  inner_io_hartId_fromTile = io_hartId_fromTile;
  wire         inner_io_cpu_halt_fromCore = io_cpu_halt_fromCore;
  wire         inner_io_cpu_critical_error_fromCore = io_cpu_critical_error_fromCore;
  wire         inner_io_chi_rxsactive = io_chi_rxsactive;
  wire         inner_io_chi_syscoack = io_chi_syscoack;
  wire         inner_io_chi_tx_linkactiveack = io_chi_tx_linkactiveack;
  wire         inner_io_chi_tx_req_lcrdv = io_chi_tx_req_lcrdv;
  wire         inner_io_chi_tx_rsp_lcrdv = io_chi_tx_rsp_lcrdv;
  wire         inner_io_chi_tx_dat_lcrdv = io_chi_tx_dat_lcrdv;
  wire         inner_io_chi_rx_linkactivereq = io_chi_rx_linkactivereq;
  wire         inner_io_chi_rx_rsp_flitpend = io_chi_rx_rsp_flitpend;
  wire         inner_io_chi_rx_rsp_flitv = io_chi_rx_rsp_flitv;
  wire [72:0]  inner_io_chi_rx_rsp_flit = io_chi_rx_rsp_flit;
  wire         inner_io_chi_rx_dat_flitpend = io_chi_rx_dat_flitpend;
  wire         inner_io_chi_rx_dat_flitv = io_chi_rx_dat_flitv;
  wire [421:0] inner_io_chi_rx_dat_flit = io_chi_rx_dat_flit;
  wire         inner_io_chi_rx_snp_flitpend = io_chi_rx_snp_flitpend;
  wire         inner_io_chi_rx_snp_flitv = io_chi_rx_snp_flitv;
  wire [114:0] inner_io_chi_rx_snp_flit = io_chi_rx_snp_flit;
  wire [63:0]  inner_io_hartId_toCore = inner_io_hartId_fromTile;
  wire         inner_io_cpu_halt_toTile = inner_io_cpu_halt_fromCore;
  wire         inner_io_cpu_critical_error_toTile = inner_io_cpu_critical_error_fromCore;

  // (B) trace 接口打拍流水级(本层唯一时序 glue):core 来的
  //     traceCoreInterface(toEncoder groups/trap/priv)打一拍寄存,
  //     部分受 group_valid / itype(异常)门控;fromEncoder 的
  //     enable/stall 也打一拍回灌。hartIsInReset:resetInFrontend|reset
  //     经异步置位寄存器输出。
  reg          inner_io_traceCoreInterface_fromCore_fromEncoder_REG_enable;
  reg          inner_io_traceCoreInterface_fromCore_fromEncoder_REG_stall;
  reg  [63:0]  inner_io_traceCoreInterface_toTile_toEncoder_trap_r_cause;
  reg  [49:0]  inner_io_traceCoreInterface_toTile_toEncoder_trap_r_tval;
  reg  [2:0]   inner_io_traceCoreInterface_toTile_toEncoder_priv_r;
  reg  [6:0]   inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire_REG;
  reg  [3:0]   inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype_REG;
  reg          inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize_r;
  reg  [49:0]  inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr_r;
  reg  [6:0]   inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire_REG;
  reg  [3:0]   inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype_REG;
  reg          inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize_r;
  reg  [49:0]  inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr_r;
  reg  [6:0]   inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire_REG;
  reg  [3:0]   inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype_REG;
  reg          inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize_r;
  reg  [49:0]  inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr_r;
  reg          inner_hartIsInReset;
  always @(posedge clock) begin
    inner_io_traceCoreInterface_fromCore_fromEncoder_REG_enable <=
      io_traceCoreInterface_toTile_fromEncoder_enable;
    inner_io_traceCoreInterface_fromCore_fromEncoder_REG_stall <=
      io_traceCoreInterface_toTile_fromEncoder_stall;
    if (io_traceCoreInterface_fromCore_toEncoder_groups_0_valid
        & (io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype == 4'h1
           | io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype == 4'h2)) begin
      inner_io_traceCoreInterface_toTile_toEncoder_trap_r_cause <=
        io_traceCoreInterface_fromCore_toEncoder_trap_cause;
      inner_io_traceCoreInterface_toTile_toEncoder_trap_r_tval <=
        io_traceCoreInterface_fromCore_toEncoder_trap_tval;
    end
    if (io_traceCoreInterface_fromCore_toEncoder_groups_0_valid) begin
      inner_io_traceCoreInterface_toTile_toEncoder_priv_r <=
        io_traceCoreInterface_fromCore_toEncoder_priv;
      inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_ilastsize_r <=
        io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_ilastsize;
      inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iaddr_r <=
        io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iaddr;
    end
    inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_iretire_REG <=
      io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_iretire;
    inner_io_traceCoreInterface_toTile_toEncoder_groups_0_bits_itype_REG <=
      io_traceCoreInterface_fromCore_toEncoder_groups_0_bits_itype;
    inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iretire_REG <=
      io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iretire;
    inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_itype_REG <=
      io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_itype;
    if (io_traceCoreInterface_fromCore_toEncoder_groups_1_valid) begin
      inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_ilastsize_r <=
        io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_ilastsize;
      inner_io_traceCoreInterface_toTile_toEncoder_groups_1_bits_iaddr_r <=
        io_traceCoreInterface_fromCore_toEncoder_groups_1_bits_iaddr;
    end
    inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iretire_REG <=
      io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iretire;
    inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_itype_REG <=
      io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_itype;
    if (io_traceCoreInterface_fromCore_toEncoder_groups_2_valid) begin
      inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_ilastsize_r <=
        io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_ilastsize;
      inner_io_traceCoreInterface_toTile_toEncoder_groups_2_bits_iaddr_r <=
        io_traceCoreInterface_fromCore_toEncoder_groups_2_bits_iaddr;
    end
  end // always @(posedge)
  always @(posedge clock or posedge reset) begin
    if (reset)
      inner_hartIsInReset <= 1'h1;
    else
      inner_hartIsInReset <= io_hartIsInReset_resetInFrontend | reset;
  end // always @(posedge, posedge)
