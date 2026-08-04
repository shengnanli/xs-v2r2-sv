// =====================================================================
// rob_lsq_deep_outputs —— Rob 的 9 个 C_DEEP 输出口忠实实现
//   owner: rob-lsq-deep (codex 0090 P2)
//   组: lsq(5) + gpaddr/isForVS(2) + toDecode(1) + error(1)
// ---------------------------------------------------------------------
// 本模块把 golden Rob.sv 里这 9 个数据通路输出口的**状态方程逐字复刻**为
// 可读、可独立测试的一小块; 由 Rob_wrapper 例化并把输入接到:
//   - xs_Rob_core (u_core) 的控制输出 + 本轮新增的组合全存储读导出;
//   - exceptionGen / vtypeBuffer 叶子输出;
//   - deqPtrGenModule.io_out_0 (= u_core 的 deq_ptr_vec[0]);
//   - 顶层输入 io_readGPAMemData_*。
//
// 忠实 bug-for-bug: 寄存器复位/无复位、组合直通、mux 结构均对齐 golden。
//   golden 引用: assign @220567/220573/220808-220812/220829/220871;
//                reg  @181478-181479/181537-181575/181704-181706/203284-203287。
// 无 dont_verify / 无删端口 / 无 fake。
// =====================================================================
module rob_lsq_deep_outputs #(
  parameter int COMMIT_WIDTH = 8,
  parameter int PTR_W        = 8
) (
  input  logic                        clock,
  input  logic                        reset,          // 仅 commitStuckCycle 用异步复位(对齐 golden)

  // ---- 提交决策 (u_core) ----
  input  logic                        io_commits_isCommit_0,      // u_core.o_commits_isCommit
  input  logic [COMMIT_WIDTH-1:0]     io_commits_commitValid_0,   // u_core.o_commits_commitValid[N]

  // ---- rawInfo_N (= robDeqGroup 寄存读, 取自 u_core.o_commit_info[N]) ----
  input  logic [2:0]                  rawInfo_commitType [COMMIT_WIDTH], // o_commit_info[N].commit_type
  input  logic                        rawInfo_0_commit_v,                // o_commit_info[0].commit_v
  input  logic                        rawInfo_0_commit_w,                // o_commit_info[0].commit_w
  input  logic                        rawInfo_0_mmio,                    // o_commit_info[0].mmio (=_GEN_8546 deqGroup读)

  // ---- robEntries[deqPtr_N] 组合全存储读 (u_core 新增导出) ----
  input  logic [COMMIT_WIDTH-1:0]     deq_entry_vls,     // u_core.o_deq_entry_vls  (_GEN_8225)
  input  logic                        deq_entry_valid_0, // u_core.o_deq_entry_valid_0 (_GEN_2611)
  input  logic                        deq_entry_mmio_0,  // u_core.o_deq_entry_mmio_0  (_GEN_2622)

  // ---- 队头指针 (deqPtrGenModule.io_out_0) ----
  input  logic                        deqPtr0_flag,      // _deqPtrGenModule_io_out_0_flag
  input  logic [PTR_W-1:0]            deqPtr0_value,     // _deqPtrGenModule_io_out_0_value

  // ---- 叶子 / 状态 ----
  input  logic                        deqHasFlushed,                 // u_core.o_deqHasFlushed
  input  logic                        exceptionGen_state_isVset,     // _exceptionGen_io_state_bits_isVset
  input  logic                        vtypeBuffer_isResumeVType,     // _vtypeBuffer_io_toDecode_isResumeVType

  // ---- 顶层输入直通 (gpaddr/isForVS) ----
  input  logic [55:0]                 io_readGPAMemData_gpaddr,
  input  logic                        io_readGPAMemData_isForVSnonLeafPTE,

  // ===================================================================
  // 9 个 C_DEEP 输出口 (名字与 golden Rob top 端口逐字一致)
  // ===================================================================
  output logic [3:0]                  io_lsq_scommit,
  output logic                        io_lsq_pendingMMIOld,
  output logic                        io_lsq_pendingst,
  output logic                        io_lsq_pendingPtr_flag,
  output logic [7:0]                  io_lsq_pendingPtr_value,
  output logic [63:0]                 io_exception_bits_gpaddr,
  output logic                        io_exception_bits_isForVSnonLeafPTE,
  output logic                        io_toDecode_isResumeVType,
  output logic                        io_error_0
);

  // -----------------------------------------------------------------
  // commitIsStore_N / commitIsLoad_0 (golden Rob.sv 22141-22142,23432-23444)
  // -----------------------------------------------------------------
  logic [COMMIT_WIDTH-1:0] commitIsStore;
  logic                    commitIsLoad_0;
  always_comb begin
    for (int i = 0; i < COMMIT_WIDTH; i++)
      commitIsStore[i] = (rawInfo_commitType[i] == 3'h3);
    commitIsLoad_0 = (rawInfo_commitType[0] == 3'h2);
  end

  // =================================================================
  // (1) lsq 组 (5 口) —— golden reg @181537-181575, assign @220808-220812
  //     无复位, 在自由跑 always @(posedge clock) 块内 (对齐 golden)。
  // =================================================================
  logic [3:0] io_lsq_scommit_REG;
  logic       io_lsq_pendingMMIOld_REG;
  logic       io_lsq_pendingst_REG;
  logic       io_lsq_pendingPtr_REG_flag;
  logic [7:0] io_lsq_pendingPtr_REG_value;

  // scommit: 本拍退休的「非向量 store」个数 (popcount, 0..8→截 4 位, 同 golden)。
  logic [3:0] scommit_cnt;
  always_comb begin
    logic [3:0] acc;
    acc = '0;
    for (int i = 0; i < COMMIT_WIDTH; i++)
      acc += 4'(io_commits_commitValid_0[i] & commitIsStore[i] & ~deq_entry_vls[i]);
    scommit_cnt = acc;
  end

  always_ff @(posedge clock) begin
    io_lsq_scommit_REG        <= io_commits_isCommit_0 ? scommit_cnt : 4'h0;
    io_lsq_pendingMMIOld_REG  <= io_commits_isCommit_0 & commitIsLoad_0 & rawInfo_0_commit_v & rawInfo_0_mmio;
    io_lsq_pendingst_REG      <= io_commits_isCommit_0 & commitIsStore[0] & rawInfo_0_commit_v;
    io_lsq_pendingPtr_REG_flag  <= deqPtr0_flag;
    io_lsq_pendingPtr_REG_value <= deqPtr0_value;
  end

  assign io_lsq_scommit          = io_lsq_scommit_REG;
  assign io_lsq_pendingMMIOld    = io_lsq_pendingMMIOld_REG;
  assign io_lsq_pendingst        = io_lsq_pendingst_REG;
  assign io_lsq_pendingPtr_flag  = io_lsq_pendingPtr_REG_flag;
  assign io_lsq_pendingPtr_value = io_lsq_pendingPtr_REG_value;

  // =================================================================
  // (2) gpaddr / isForVS (2 口) —— golden assign @220567/220573 (纯组合直通)
  // =================================================================
  assign io_exception_bits_gpaddr           = {8'h0, io_readGPAMemData_gpaddr};
  assign io_exception_bits_isForVSnonLeafPTE = io_readGPAMemData_isForVSnonLeafPTE;

  // =================================================================
  // (3) toDecode.isResumeVType (1 口) —— golden assign @220829, reg @181478
  //     isVsetFlushPipeReg 无复位 (自由跑块)。
  // =================================================================
  logic isVsetFlushPipeReg;
  always_ff @(posedge clock)
    isVsetFlushPipeReg <= rawInfo_0_commit_w & deqHasFlushed & exceptionGen_state_isVset;

  assign io_toDecode_isResumeVType = vtypeBuffer_isResumeVType | isVsetFlushPipeReg;

  // =================================================================
  // (4) error_0 (1 口) —— commit-stuck 看门狗
  //     golden: commitStuck wire @64797; commitStuckCycle @203284 (异步复位块);
  //             REG_8/io_error_0_REG/REG_1 @181704-181706 (自由跑块);
  //             assign io_error_0 @220871。
  // =================================================================
  logic [20:0] commitStuckCycle;
  logic        REG_8;
  logic        io_error_0_REG;
  logic        io_error_0_REG_1;

  // commitStuck = (队头本拍无任何提交) & ~(队头条目 valid&mmio)。
  logic commitStuck;
  always_comb
    commitStuck =
      (~(|io_commits_commitValid_0) | ~io_commits_isCommit_0)
      & ~(deq_entry_valid_0 & deq_entry_mmio_0);

  // commitStuckCycle: 异步复位到 0 (golden always @(posedge clock or posedge reset))。
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      commitStuckCycle <= 21'h0;
    else if (commitStuck)
      commitStuckCycle <= 21'(commitStuckCycle + 21'h1);
    else if (~commitStuck & REG_8)
      commitStuckCycle <= 21'h0;
  end

  // REG_8 / io_error_0_REG / _REG_1: 无复位 (golden 自由跑块)。
  always_ff @(posedge clock) begin
    REG_8            <= commitStuck;
    io_error_0_REG   <= &commitStuckCycle;
    io_error_0_REG_1 <= io_error_0_REG;
  end

  assign io_error_0 = io_error_0_REG_1;

endmodule
