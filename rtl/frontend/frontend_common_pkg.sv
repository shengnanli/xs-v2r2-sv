// frontend_common_pkg.sv —— 前端子系统的公共包文件（跨模块共享类型/函数的唯一落点）
//
// 规范依据（CONVENTIONS.md「单文件规范」）：一个 golden 模块 = 一个 .sv 文件，
// 包只在该文件内私有；**跨模块共享**的类型/参数/函数是明确的例外，放
// `rtl/<subsys>/<subsys>_common_pkg.sv`，每个子系统至多一个这样的文件。
// 本文件就是 frontend 子系统的那一个。
//
// 为什么必须有它（2026-09-14 实测，非预防性重构）：`xs_predecode_pkg` 此前在
// `PreDecode.sv` 与 `F3Predecoder.sv` 里各抄了一份**逐字相同**的定义。单目标 UT
// 每次只编其中一个文件，所以一直没人撞到；但 SystemVerilog 的 package 名是**全局**
// 的，两个文件一起进编译单元（整芯片 elaborate 就是这个场景）时 VCS 当场报：
//     Error-[SV-PPD] Package previously declared
//     Identifier 'xs_predecode_pkg' is already declared in file
//     ".../F3Predecoder.sv", line 7.
// 抽到这里之后两个使用者共享同一份定义，重名消失，且"改一处忘另一处"的分叉风险
// 一并消失 —— 而分支译码语义在 PreDecode 与 F3Predecoder 之间必须逐位一致，
// 这正是最不能容忍静默分叉的地方。
//
// 当前收录：
//   xs_predecode_pkg —— 分支预译码共享函数（PreDecode / F3Predecoder 共用）
//   xs_ftb_pkg       —— FTB 条目类型与目标地址编解码（FTBEntryGen / FTBBank 共用）
// 新增共享包时追加到本文件，不要再开第二个 frontend 公共包文件。
//
// xs_ftb_pkg 为什么在 2026-09-14 搬到这里：它原先住在 FTBEntryGen.sv 里，却被
// FTBBank.sv 引用。按路径字母序 FTBBank.sv 排在 FTBEntryGen.sv 之前，整芯片
// elaborate 当场 `Error-[SV-LCM-PND] Package not defined`（再连锁 UTFP/IND/SE）。
// 搬到公共包文件后，两个使用者都只依赖「公共包排在前面」这一条统一规则。
// =============================================================================
// xs_predecode_pkg —— 预解码共享译码函数
//
// 对应 Chisel: xiangshan.frontend.HasPdConst 的 brInfo / isLink / isRVC 等。
// 供 PreDecode、F3Predecoder 等复用，保证分支译码语义单一来源。
// =============================================================================
package xs_predecode_pkg;

  // BrType 编码（与 Chisel object BrType 一致）
  localparam logic [1:0] BR_NOTCFI = 2'b00, BR_BRANCH = 2'b01,
                         BR_JAL = 2'b10, BR_JALR = 2'b11;

  function automatic logic xs_is_rvc(input logic [31:0] inst);
    return (inst[1:0] != 2'b11);
  endfunction

  function automatic logic xs_is_link(input logic [4:0] r);
    return (r == 5'd1) || (r == 5'd5);
  endfunction

  // 分支类型译码（优先级：C.EBREAK→notCFI 高于 C.JALR；其余互斥）
  function automatic logic [1:0] xs_br_type(input logic [31:0] inst);
    logic c_ebreak, c_j, c_jalr, c_branch, i_jal, i_jalr, i_branch;
    c_ebreak = (inst[15:13] == 3'b100) && (inst[11:2] == 10'b0) && (inst[1:0] == 2'b10);
    c_j      = (inst[15:13] == 3'b101) && (inst[1:0] == 2'b01);
    c_jalr   = (inst[15:13] == 3'b100) && (inst[6:2] == 5'b0) && (inst[1:0] == 2'b10);
    c_branch = (inst[15:14] == 2'b11) && (inst[1:0] == 2'b01);
    i_jal    = (inst[6:0] == 7'b1101111);
    i_jalr   = (inst[14:12] == 3'b000) && (inst[6:0] == 7'b1100111);
    i_branch = (inst[6:0] == 7'b1100011);
    if (c_ebreak)                   return BR_NOTCFI;
    else if (c_j || i_jal)          return BR_JAL;
    else if (c_jalr || i_jalr)      return BR_JALR;
    else if (c_branch || i_branch)  return BR_BRANCH;
    else                            return BR_NOTCFI;
  endfunction

  // rd/rs 抽取（RVC 时按 C 编码）
  function automatic logic [4:0] xs_rd(input logic [31:0] inst);
    return xs_is_rvc(inst) ? {4'b0, inst[12]} : inst[11:7];
  endfunction

  function automatic logic [4:0] xs_rs(input logic [31:0] inst);
    logic [1:0] bt = xs_br_type(inst);
    return xs_is_rvc(inst) ? (bt == BR_JAL ? 5'b0 : inst[11:7]) : inst[19:15];
  endfunction

  function automatic logic xs_is_call(input logic [31:0] inst);
    logic [1:0] bt = xs_br_type(inst);
    return ((bt == BR_JAL && !xs_is_rvc(inst)) || bt == BR_JALR) && xs_is_link(xs_rd(inst));
  endfunction

  function automatic logic xs_is_ret(input logic [31:0] inst);
    logic [1:0] bt = xs_br_type(inst);
    return (bt == BR_JALR) && xs_is_link(xs_rs(inst)) && !xs_is_call(inst);
  endfunction

endpackage

// =============================================================================
// xs_ftb_pkg —— FTB（Fetch Target Buffer，取指目标缓冲）共享类型与编解码
//
// 对应 Chisel: xiangshan.frontend.FtbSlot / FTBEntry（FTB.scala）
// 供 FTBEntryGen / FTB / FTBBank / FTQ 复用。
//
// 【FTB 条目的核心思想】
// 一个 FTB 条目描述「一个取指块（fetch block，最多 PredictWidth=16 条指令）里的
// 控制流指令（CFI）及其跳转目标」。一个块最多记录 numBr=2 个分支：
//   - brSlots[0]：第 1 个条件分支（offset 在块内的位置）
//   - tailSlot  ：块尾的跳转/最后一个分支（可被「共享」为第 2 个条件分支）
// 外加：pftAddr/carry（fall-through 地址，即顺序执行落到的下一块起点）、
// isCall/isRet/isJalr、strong_bias（强偏置，预测置信度）等。
//
// 【目标地址的压缩存储】slot 不存完整 50-bit 目标，只存：
//   - lower：目标地址的低 offsetLen 位（br=12b，tail=20b）
//   - tarStat：目标高位相对「当前 PC 高位」的状态（FIT 相等 / OVF 高位+1 / UDF 高位-1）
// 取出时由 getTarget(pc) 用 PC 的高位 ± tarStat 重建完整目标，省存储。
// =============================================================================
package xs_ftb_pkg;

  localparam int unsigned VADDR_BITS    = 50;
  localparam int unsigned INST_OFF_BITS = 1;          // 指令地址对齐位（RVC 2 字节 → 1）
  localparam int unsigned PREDICT_WIDTH = 16;
  localparam int unsigned LOG2_PW       = 4;          // log2(PredictWidth)
  localparam int unsigned CARRY_POS     = LOG2_PW + INST_OFF_BITS;  // =5
  localparam int unsigned BR_OFF_LEN    = 12;         // brSlot 目标低位宽
  localparam int unsigned JMP_OFF_LEN   = 20;         // tailSlot 目标低位宽
  localparam int unsigned OFFSET_W      = LOG2_PW;    // 块内 offset 位宽 =4

  // 目标高位状态（target_higher 相对 pc_higher）
  localparam logic [1:0] TAR_FIT = 2'd0;  // 相等
  localparam logic [1:0] TAR_OVF = 2'd1;  // 高位 +1（目标在更高块）
  localparam logic [1:0] TAR_UDF = 2'd2;  // 高位 -1（目标在更低块）

  // ---- slot：一个 CFI 的位置与（压缩的）目标 ----
  // tailSlot 用最大宽度 JMP_OFF_LEN 存放 lower；brSlot 只需 BR_OFF_LEN(12) 位。
  // golden(firtool) 扁平化条目, brSlot.lower 存储恰为 12 位 → 分开定义两种 slot,
  // 避免 brSlot 存 8 位常量 pad 产生死寄存器(与 golden 存储布局一致)。
  typedef struct packed {
    logic [OFFSET_W-1:0]    offset;   // CFI 在块内的指令 offset
    logic                   sharing;  // tailSlot 是否被「共享」作条件分支
    logic                   valid;
    logic [JMP_OFF_LEN-1:0] lower;    // 目标低位（tail 全宽 JMP_OFF_LEN）
    logic [1:0]             tarStat;  // 目标高位状态
  } ftb_slot_t;

  // brSlot：lower 仅 BR_OFF_LEN 位（其余字段同 ftb_slot_t）
  typedef struct packed {
    logic [OFFSET_W-1:0]    offset;
    logic                   sharing;
    logic                   valid;
    logic [BR_OFF_LEN-1:0]  lower;
    logic [1:0]             tarStat;
  } ftb_br_slot_t;

  typedef struct packed {
    logic                   valid;
    ftb_br_slot_t           brSlot;   // numBrSlot=1：第 1 个条件分支（lower 12 位）
    ftb_slot_t              tailSlot; // 块尾跳转 / 可共享的第 2 分支
    logic [OFFSET_W-1:0]    pftAddr;  // fall-through 地址低位
    logic                   carry;    // fall-through 进位
    logic                   isCall;
    logic                   isRet;
    logic                   isJalr;
    logic                   last_may_be_rvi_call;
    logic [1:0]             strong_bias;  // [0]=br0, [1]=tail
  } ftb_entry_t;

  // 「有效低位宽」：共享 slot 按 br 低位宽，否则按本 slot 低位宽
  function automatic int unsigned eff_len(input bit is_share, input int unsigned off_len);
    return is_share ? BR_OFF_LEN : off_len;
  endfunction

  // 由目标地址反算 tarStat（目标高位相对 PC 高位）
  function automatic logic [1:0] calc_tarstat(
      input logic [VADDR_BITS-1:0] pc, input logic [VADDR_BITS-1:0] target, input int unsigned eff);
    logic [VADDR_BITS-1:0] pc_hi  = pc     >> (eff + 1);
    logic [VADDR_BITS-1:0] tgt_hi = target >> (eff + 1);
    return (tgt_hi > pc_hi) ? TAR_OVF : (tgt_hi < pc_hi) ? TAR_UDF : TAR_FIT;
  endfunction

  // 由目标地址取低位 target[eff:1]，零扩展到 lower 宽
  function automatic logic [JMP_OFF_LEN-1:0] calc_lower(
      input logic [VADDR_BITS-1:0] target, input int unsigned eff);
    return (target >> 1) & ((1 << eff) - 1);
  endfunction

  // 由 (pc, lower, tarStat) 重建完整目标地址；off_len 同上
  function automatic logic [VADDR_BITS-1:0] get_target(
      input logic [VADDR_BITS-1:0] pc,
      input logic [JMP_OFF_LEN-1:0] lower,
      input logic [1:0]            tarStat,
      input int unsigned           off_len
  );
    logic [VADDR_BITS-1:0] h = pc >> (off_len + 1);   // PC 高位
    logic [VADDR_BITS-1:0] higher;
    // 与 Chisel Mux1H 一致：三项 one-hot 选择，tarStat 为非法值(如 2'b11)时全不选 → higher=0
    higher = ({VADDR_BITS{tarStat == TAR_OVF}} & (h + 1))
           | ({VADDR_BITS{tarStat == TAR_UDF}} & (h - 1))
           | ({VADDR_BITS{tarStat == TAR_FIT}} & h);
    // {higher, lower[off_len-1:0], 1'b0}
    return (higher << (off_len + 1)) | ((lower & ((1 << off_len) - 1)) << 1);
  endfunction

endpackage
