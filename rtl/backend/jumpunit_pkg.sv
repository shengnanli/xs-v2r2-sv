// =============================================================================
// jumpunit_pkg —— 香山 V2R2(昆明湖) 后端 JumpUnit 的类型/参数/纯函数定义
// -----------------------------------------------------------------------------
// 设计源: src/main/scala/xiangshan/backend/fu/wrapper/JumpUnit.scala
//          + src/main/scala/xiangshan/backend/fu/Jump.scala (JumpDataModule)
//          + fuOpType 编码 src/main/scala/xiangshan/package.scala (object JumpOpType)
//
// JumpUnit 负责无条件跳转 jal/jalr 与 auipc:
//   - jal : 目标 = pc + sext(imm)            返回地址(写回 rd) = pc + (下一条偏移)
//   - jalr: 目标 = rs1 + sext(imm), 末位清零  返回地址同上
//   - auipc: rd = pc + sext(imm), 不跳转(不产生重定向)
//
// fuOpType 编码(JumpOpType): jal=00, jalr=01, auipc=10
//   func[0] = isJalr  (目标用 rs1 还是 pc 作为基址)
//   func[1] = isAuipc (是否 auipc; auipc 把"目标"作为写回结果, 且不重定向)
//
// 与 BranchUnit 不同: jal/jalr 在前端只是"预测", 后端总要校验目标是否与预测一致,
// 故除 auipc 外恒产生重定向(redirect.valid = in.valid & !isAuipc), 由 isMisPred
// 标记是否真的预测错误(目标不符或前端没预测 taken)。
// =============================================================================
package jumpunit_pkg;

  localparam int XLEN      = 64;
  localparam int VAddrBits = 50;
  localparam int ImmWidth  = 33;  // imm-U 需 32 位 + 1 符号位

  // ---------------------------------------------------------------------------
  // 跳转类型枚举 (由 fuOpType[1:0] 解出, 这里用语义名表达)
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    JMP_JAL   = 2'b00, // jal  : pc 相对跳转, 写返回地址
    JMP_JALR  = 2'b01, // jalr : 寄存器间接跳转(末位清零), 写返回地址
    JMP_AUIPC = 2'b10  // auipc: pc + imm 写 rd, 不跳转
  } jmp_type_e;

  // 地址翻译模式(同 BranchUnit, 用于 pc 扩展方式与目标合法性检查)
  typedef struct packed {
    logic bare;
    logic sv39;
    logic sv39x4;
    logic sv48;
    logic sv48x4;
  } addr_trans_e;

  // JumpDataModule 的计算结果打包
  typedef struct packed {
    logic [XLEN-1:0] result; // 写回 rd 的值(auipc:目标; jal/jalr:返回地址 snpc)
    logic [XLEN-1:0] target; // 跳转目标(末位已清零)
    logic            isAuipc;
  } jump_calc_t;

  // ===========================================================================
  // 纯函数区
  // ===========================================================================

  // --- jalr 是否(func[0]) / auipc 是否(func[1]) ---
  function automatic logic jumpIsJalr (input logic [8:0] func); return func[0]; endfunction
  function automatic logic jumpIsAuipc(input logic [8:0] func); return func[1]; endfunction

  // --- 核心计算 (对应 JumpDataModule) ---
  //   offset = sext(imm, 64)
  //   target = (isJalr ? src1 : pc) + offset, 然后末位清零(jalr 规范要求)
  //   snpc   = pc + (nextPcOffset << 1)         顺序下一条 PC = 返回地址
  //   result = isAuipc ? target : snpc
  function automatic jump_calc_t jumpCalc(
      input logic [XLEN-1:0] src1,
      input logic [XLEN-1:0] pc,          // 已 sext/zext 到 64 位
      input logic [ImmWidth-1:0] imm,     // 33 位
      input logic [4:0]      nextPcOffset,
      input logic [8:0]      func
  );
    jump_calc_t r;
    logic [XLEN-1:0] offset, base, target, snpc;
    offset    = {{(XLEN-ImmWidth){imm[ImmWidth-1]}}, imm};       // sext 33→64
    base      = jumpIsJalr(func) ? src1 : pc;
    target    = base + offset;
    snpc      = pc + {{(XLEN-6){1'b0}}, nextPcOffset, 1'b0};     // pc + offset*2
    r.isAuipc = jumpIsAuipc(func);
    r.target  = {target[XLEN-1:1], 1'b0};                        // 末位清零
    r.result  = jumpIsAuipc(func) ? target : snpc;
    return r;
  endfunction

endpackage
