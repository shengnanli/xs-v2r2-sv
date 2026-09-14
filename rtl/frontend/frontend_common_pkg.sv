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
// 新增共享包时追加到本文件，不要再开第二个 frontend 公共包文件。
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
