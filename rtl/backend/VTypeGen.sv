// =============================================================================
// VTypeGen.sv —— 译码级的推测 vtype 生成器：vsetvli/vsetivli 一到译码级就算出新 vtype
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/backend/decode/VTypeGen.scala
//        （子模块 VsetModule 在 backend/fu/Vsetu.scala，本文件把它的 vtype 合法性判定
//          以 vset_pkg 的纯函数形式内联，与 VSetRiWi/VSetRvfWvf 重写共用同一份实现）
// golden 对照:G1-canonical/golden-rtl/VTypeGen.sv（312 行 / 39 端口 / 16 位寄存器）
//             + VsetModule.sv（125 行，纯组合，本核只用它的 vtype 输出）
//
// ★ 它在流水线里的位置 ★
// DecodeStage 里例化 1 份。向量指令的译码依赖 vtype（vsew/vlmul 决定 uop 数、emul、
// 合法性），而 vtype 由 vsetvli/vsetivli 改写——如果等它们执行完再译后面的向量指令，
// 译码级要停很久。本模块在**译码级就推测性地**算出 vsetvli/vsetivli 的新 vtype：
//   · vtypeSpec（推测 vtype）：送给 6 个 DecodeUnit 用；
//   · vtypeArch（架构 vtype）：跟着提交走，用来在冲刷后恢复推测值。
// vsetvl（vtype 来自寄存器）在译码级算不出来，它会冲刷流水，由 CSR 那边送来的 vsetvlVType
// 在提交时一次写入两份。
//
// ★ 核心机制 ★
//   1. 本拍 6 条指令里找**第一条** vsetvli/vsetivli（OPCODE=1010111、WIDTH=111、
//      bit31=0 或 bit31:30=11；vsetvl 是 bit31:30=10，不在此列），取它的 zimm 字段
//      （vsetvli 用 instr[30:20] 共 11 位，vsetivli 用 instr[29:20] 共 10 位）拼成 vtype 输入；
//   2. 交给 VsetModule 判合法性：vlmul=100 保留、vsew[2]=1 保留、SEW 超过 ELEN*LMUL、
//      zimm 的保留位非 0 都算非法；非法时 vill=1 且其余字段清零；
//   3. 两个寄存器的更新优先级（Chisel when 链，先到先得）：
//        vtypeArch: hasVsetvl(提交了 vsetvl) > commitVType.valid(提交了 vsetvli/ivli)
//        vtypeSpec: hasVsetvl > walkVType.valid(回滚中逐条恢复) > walkToArchVType(回到架构值)
//                   > 本拍有 vset 且 canUpdateVType(译码级允许更新)
//      注意 hasVsetvl 同时写两份（vsetvl 冲刷了流水，推测值直接归一）。
//
// ★ golden 与 Chisel 字面不一致处（一律以 golden 为准）★
//   (a) VsetModule 的 avl 输入恒 0、func 恒 uvsetvcfg_xi、vtype.illegal 恒 0，它的 vl/vlmax
//       输出在本模块无读者——golden 里那两根输出悬空、内部 vlmax 逻辑是 cone-dead，本核不写。
//   (b) firstVsetOH 的 PriorityEncoderOH 在 6 路都不是 vset 时选第 5 路（golden 的默认分支），
//       此时 vtypeSpec 不更新（inHasVset=0），这条默认值没有可观测后果，但 VsetModule 输入
//       仍照抄以保持结构一致。
//
// ★ 复位域 ★
//   vtypeArch / vtypeSpec 各 8 位（illegal/vma/vta/vsew[1:0]/vlmul[2:0]），异步高有效复位，
//   复位值 = VType.initVtype()：**illegal=1**，其余 0（上电 vtype 非法，直到第一条 vset）。
// =============================================================================

// -----------------------------------------------------------------------------
// §1 vtypegen_pkg —— 本模块私有类型
// -----------------------------------------------------------------------------
package vtypegen_pkg;

  localparam int DECODE_WIDTH = 6;

  // vtype 寄存器（VType）：与 golden 的 io_*_illegal/vma/vta/vsew/vlmul 逐字段对应
  typedef struct packed {
    logic       illegal;
    logic       vma;
    logic       vta;
    logic [1:0] vsew;
    logic [2:0] vlmul;
  } vtype_t;

  // 上电值：illegal=1，其余 0（VType.initVtype）
  localparam vtype_t VTYPE_INIT = '{illegal: 1'b1, vma: 1'b0, vta: 1'b0, vsew: 2'b00, vlmul: 3'b000};

  localparam logic [6:0] OPCODE_OP_V   = 7'b1010111;
  localparam logic [2:0] WIDTH_VSET    = 3'b111;
  localparam logic [8:0] FUNC_VSETVLI  = 9'h0A0;   // VSETOpType.uvsetvcfg_xi：VsetModule 的 func 输入（恒定）

endpackage

// -----------------------------------------------------------------------------
// §2 xs_VTypeGen_core —— 可读核
// -----------------------------------------------------------------------------
module xs_VTypeGen_core
  import vtypegen_pkg::*;
  import vset_pkg::calc_log2_sew, vset_pkg::calc_illegal;
(
  input  logic                clock,
  input  logic                reset,
  input  logic [DECODE_WIDTH-1:0]        insts_valid,      // 本拍 6 条指令
  input  logic [DECODE_WIDTH-1:0][31:0]  insts_bits,
  input  logic                walkToArchVType,             // 回滚结束：推测值回到架构值
  input  logic                walkVType_valid,             // 回滚中：逐条恢复推测值
  input  vtype_t              walkVType_bits,
  input  logic                canUpdateVType,              // 译码级此刻允许用本拍的 vset 更新
  input  vtype_t              vsetvlVType,                 // 提交 vsetvl 时 CSR 算好的新 vtype
  input  logic                commitVType_valid,           // 提交了 vsetvli/vsetivli
  input  vtype_t              commitVType_bits,
  input  logic                commitVType_hasVsetvl,       // 提交了 vsetvl（冲刷流水）
  output vtype_t              vtype                        // 推测 vtype，送 DecodeUnit
);

  // ---------------------------------------------------------------------------
  // §2.1 找本拍第一条 vsetvli / vsetivli
  // ---------------------------------------------------------------------------
  logic [DECODE_WIDTH-1:0] isVsetVec;
  logic [31:0]             firstVsetInst;
  logic                    inHasVset;
  logic                    isVsetvli;      // 第一条 vset 是 vsetvli（否则 vsetivli）

  always_comb begin
    for (int i = 0; i < DECODE_WIDTH; i++) begin
      isVsetVec[i] = insts_valid[i]
                  && insts_bits[i][6:0] == OPCODE_OP_V
                  && insts_bits[i][14:12] == WIDTH_VSET
                  && (insts_bits[i][31] == 1'b0 || insts_bits[i][31:30] == 2'b11);   // vsetvli | vsetivli（排除 vsetvl=10）
    end
    // PriorityMux：低路优先；6 路都不是 vset 时取第 5 路（无读者，照 golden）
    firstVsetInst = insts_bits[DECODE_WIDTH-1];
    for (int i = DECODE_WIDTH - 2; i >= 0; i--) begin
      if (isVsetVec[i]) firstVsetInst = insts_bits[i];
    end
  end
  assign inHasVset = |isVsetVec;
  assign isVsetvli = firstVsetInst[6:0] == OPCODE_OP_V && firstVsetInst[14:12] == WIDTH_VSET && firstVsetInst[31] == 1'b0;

  // ---------------------------------------------------------------------------
  // §2.2 zimm -> VsetVType -> VsetModule 的 vtype 合法性判定（只要 vtype 那一半）
  //   InstVType 布局（低位起）：vlmul[2:0] vsew[2:0] vta vma reserved[…]
  //   vsetvli  取 instr[30:20]（11 位，reserved 3 位 = instr[30:28]）
  //   vsetivli 取 instr[29:20]（10 位，reserved 2 位 = instr[29:28]，高位补 0）
  // ---------------------------------------------------------------------------
  logic [2:0]  in_vlmul;
  logic [2:0]  in_vsew;        // 3 位：vsew[2]=1 是保留编码
  logic        in_vta, in_vma;
  logic [54:0] in_reserved;
  assign in_vlmul    = firstVsetInst[22:20];
  assign in_vsew     = firstVsetInst[25:23];
  assign in_vta      = firstVsetInst[26];
  assign in_vma      = firstVsetInst[27];
  assign in_reserved = {52'b0, isVsetvli ? firstVsetInst[30:28] : {1'b0, firstVsetInst[29:28]}};

  logic       new_illegal;
  vtype_t     vtypeNew;
  assign new_illegal = calc_illegal(in_vlmul, in_vsew, calc_log2_sew(in_vsew), in_reserved, 1'b0);
  // VsetModule：非法则 vill=1、其余清零；合法则透传（vsew 收窄成 2 位）
  assign vtypeNew.illegal = new_illegal;
  assign vtypeNew.vma     = ~new_illegal & in_vma;
  assign vtypeNew.vta     = ~new_illegal & in_vta;
  assign vtypeNew.vsew    = new_illegal ? 2'b00 : in_vsew[1:0];
  assign vtypeNew.vlmul   = new_illegal ? 3'b000 : in_vlmul;

  // ---------------------------------------------------------------------------
  // §2.3 两个 vtype 寄存器（异步复位，复位值 illegal=1）
  // ---------------------------------------------------------------------------
  vtype_t vtypeArch, vtypeSpec;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      vtypeArch <= VTYPE_INIT;
      vtypeSpec <= VTYPE_INIT;
    end else if (commitVType_hasVsetvl) begin
      // 提交了 vsetvl：流水已冲刷，架构值与推测值一起改写
      vtypeArch <= vsetvlVType;
      vtypeSpec <= vsetvlVType;
    end else begin
      if (commitVType_valid)          vtypeArch <= commitVType_bits;
      if (walkVType_valid)            vtypeSpec <= walkVType_bits;      // 回滚中逐条恢复
      else if (walkToArchVType)       vtypeSpec <= vtypeArch;           // 回滚结束回到架构值
      else if (inHasVset && canUpdateVType) vtypeSpec <= vtypeNew;      // 译码级推测更新
    end
  end

  assign vtype = vtypeSpec;

endmodule

// -----------------------------------------------------------------------------
// §3 VTypeGen —— golden 同名 wrapper
// -----------------------------------------------------------------------------
module VTypeGen
  import vtypegen_pkg::*;
(
  input         clock,
  input         reset,
  input         io_insts_0_valid,
  input  [31:0] io_insts_0_bits,
  input         io_insts_1_valid,
  input  [31:0] io_insts_1_bits,
  input         io_insts_2_valid,
  input  [31:0] io_insts_2_bits,
  input         io_insts_3_valid,
  input  [31:0] io_insts_3_bits,
  input         io_insts_4_valid,
  input  [31:0] io_insts_4_bits,
  input         io_insts_5_valid,
  input  [31:0] io_insts_5_bits,
  input         io_walkToArchVType,
  input         io_walkVType_valid,
  input         io_walkVType_bits_illegal,
  input         io_walkVType_bits_vma,
  input         io_walkVType_bits_vta,
  input  [1:0]  io_walkVType_bits_vsew,
  input  [2:0]  io_walkVType_bits_vlmul,
  input         io_canUpdateVType,
  output        io_vtype_illegal,
  output        io_vtype_vma,
  output        io_vtype_vta,
  output [1:0]  io_vtype_vsew,
  output [2:0]  io_vtype_vlmul,
  input         io_vsetvlVType_illegal,
  input         io_vsetvlVType_vma,
  input         io_vsetvlVType_vta,
  input  [1:0]  io_vsetvlVType_vsew,
  input  [2:0]  io_vsetvlVType_vlmul,
  input         io_commitVType_vtype_valid,
  input         io_commitVType_vtype_bits_illegal,
  input         io_commitVType_vtype_bits_vma,
  input         io_commitVType_vtype_bits_vta,
  input  [1:0]  io_commitVType_vtype_bits_vsew,
  input  [2:0]  io_commitVType_vtype_bits_vlmul,
  input         io_commitVType_hasVsetvl
);

  vtype_t walk_bits, vsetvl_bits, commit_bits, vtype_out;
  assign walk_bits   = '{illegal: io_walkVType_bits_illegal, vma: io_walkVType_bits_vma, vta: io_walkVType_bits_vta,
                         vsew: io_walkVType_bits_vsew, vlmul: io_walkVType_bits_vlmul};
  assign vsetvl_bits = '{illegal: io_vsetvlVType_illegal, vma: io_vsetvlVType_vma, vta: io_vsetvlVType_vta,
                         vsew: io_vsetvlVType_vsew, vlmul: io_vsetvlVType_vlmul};
  assign commit_bits = '{illegal: io_commitVType_vtype_bits_illegal, vma: io_commitVType_vtype_bits_vma,
                         vta: io_commitVType_vtype_bits_vta, vsew: io_commitVType_vtype_bits_vsew,
                         vlmul: io_commitVType_vtype_bits_vlmul};

  xs_VTypeGen_core u_core (
    .clock                 (clock),
    .reset                 (reset),
    .insts_valid           ({io_insts_5_valid, io_insts_4_valid, io_insts_3_valid,
                             io_insts_2_valid, io_insts_1_valid, io_insts_0_valid}),
    .insts_bits            ({io_insts_5_bits, io_insts_4_bits, io_insts_3_bits,
                             io_insts_2_bits, io_insts_1_bits, io_insts_0_bits}),
    .walkToArchVType       (io_walkToArchVType),
    .walkVType_valid       (io_walkVType_valid),
    .walkVType_bits        (walk_bits),
    .canUpdateVType        (io_canUpdateVType),
    .vsetvlVType           (vsetvl_bits),
    .commitVType_valid     (io_commitVType_vtype_valid),
    .commitVType_bits      (commit_bits),
    .commitVType_hasVsetvl (io_commitVType_hasVsetvl),
    .vtype                 (vtype_out)
  );

  assign io_vtype_illegal = vtype_out.illegal;
  assign io_vtype_vma     = vtype_out.vma;
  assign io_vtype_vta     = vtype_out.vta;
  assign io_vtype_vsew    = vtype_out.vsew;
  assign io_vtype_vlmul   = vtype_out.vlmul;

endmodule
