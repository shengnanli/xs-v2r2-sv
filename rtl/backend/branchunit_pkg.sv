// =============================================================================
// branchunit_pkg —— 香山 V2R2(昆明湖) 后端 BranchUnit 的类型/参数/纯函数定义
// -----------------------------------------------------------------------------
// 设计源: src/main/scala/xiangshan/backend/fu/wrapper/BranchUnit.scala
//          + src/main/scala/xiangshan/backend/fu/Branch.scala (BranchModule)
//          + fuOpType 编码 src/main/scala/xiangshan/package.scala (object BRUOpType)
//
// BranchUnit 是整数执行簇里负责"条件分支(beq/bne/blt/bge/bltu/bgeu)"的功能单元:
//   1) 对两个源操作数做带符号/无符号比较, 判定本条分支"实际是否跳转(taken)";
//   2) 与前端预测(predictInfo.taken)比较, 得到是否预测错误(mispredict);
//   3) 若预测错误, 计算正确目标地址并生成"后端重定向(redirect)", 冲刷流水。
//
// 它是纯组合逻辑(0 延迟 FU): 当拍 io.in 进, 当拍 io.out 出, 无寄存器。
// =============================================================================
package branchunit_pkg;

  // ---- 基本数据宽度(对应 XSCore 参数) ----
  localparam int XLEN      = 64;  // 通用寄存器/数据通路位宽
  localparam int VAddrBits = 50;  // 虚地址位宽(pc 字段宽度)
  // 分支立即数(B 型)有效位数: immMinWidth=12, AddrAddModule 取 imm[immMinWidth+2:0]=imm[14:0]
  localparam int BrImmWidth = 15;

  // ---------------------------------------------------------------------------
  // 分支类型枚举 —— 取自 fuOpType 的 func[3:1] (BRUOpType.getBranchType)
  // 编码(见 BRUOpType): beq/bne=000_00x, blt/bge=000_10x, bltu/bgeu=001_00x
  //   func[3:1]: EQ=3'b000(相等比较), LT=3'b010(带符号小于), LTU=3'b100(无符号小于)
  //   func[0]  : invert 位, 把 beq→bne / blt→bge / bltu→bgeu (结果取反)
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    BR_EQ  = 3'b000, // beq/bne : 判等(src1 == src2)
    BR_LT  = 3'b010, // blt/bge : 带符号 src1 < src2
    BR_LTU = 3'b100  // bltu/bgeu: 无符号 src1 < src2
  } br_type_e;

  // ---------------------------------------------------------------------------
  // 地址翻译模式 —— io_instrAddrTransType 的 one-hot 描述(来自 CSR satp/vsatp)
  // 用于: ① pc 高位扩展方式(sext/zext); ② 目标地址的访问/缺页/客户缺页检查。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic bare;   // 无翻译(物理寻址): 目标高位非 0 → 访问错误 IAF
    logic sv39;   // Sv39 一阶段
    logic sv39x4; // Sv39 两阶段(G-stage)
    logic sv48;   // Sv48 一阶段
    logic sv48x4; // Sv48 两阶段(G-stage)
  } addr_trans_e;

  // ---------------------------------------------------------------------------
  // 重定向 cfiUpdate 中由本单元真正填充的有效负载(其余字段全 0, 见 wrapper)。
  // 把散落的 backendIxF/target/taken 聚成一个结构, 表达"分支重定向需要回填给前端
  // 的控制流更新信息"。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [VAddrBits-1:0] target;     // 重定向目标低 50 位(写回前端 ftq)
    logic                 taken;      // 实际是否跳转
    logic                 predTaken;  // 前端预测是否跳转
    logic                 isMisPred;  // 是否预测错误
    logic                 backendIAF; // 目标取指访问错误
    logic                 backendIPF; // 目标取指缺页
    logic                 backendIGPF;// 目标取指客户缺页
  } cfi_payload_t;

  // ===========================================================================
  // 纯函数区
  // ===========================================================================

  // --- 65 位无借位减法: {0,src1} + {0,~src2} + 1, 高位[64]为"无借位"标志 ---
  // 对应 Alu.scala 的 SubModule。sub[64]==1 表示 src1>=src2(无符号), 即无借位。
  function automatic logic [XLEN:0] sub65(input logic [XLEN-1:0] src1,
                                          input logic [XLEN-1:0] src2);
    return {1'b0, src1} + {1'b0, ~src2} + 65'd1;
  endfunction

  // --- 条件判定: 给定分支类型与两源, 返回"该比较是否成立"(未含 invert) ---
  // 复用同一个减法器: 无符号小于 sltu = !sub[64]; 带符号小于 slt 由符号位与 sltu 推出。
  function automatic logic branchCmp(input br_type_e            btype,
                                     input logic [XLEN-1:0]     src1,
                                     input logic [XLEN-1:0]     src2);
    logic [XLEN:0] sub;
    logic          sltu, slt, eq;
    sub  = sub65(src1, src2);
    sltu = ~sub[XLEN];                                  // src1 <  src2 (unsigned)
    slt  = src1[XLEN-1] ^ src2[XLEN-1] ^ sltu;          // src1 <  src2 (signed)
    eq   = ((src1 ^ src2) == '0);                       // src1 == src2
    unique case (btype)
      BR_EQ:   return eq;
      BR_LT:   return slt;
      BR_LTU:  return sltu;
      default: return 1'b0;
    endcase
  endfunction

  // --- 分支目标/顺序地址加法 (对应 AddrAddModule) ---
  // taken : 目标 = pcExtend + sext(imm[14:0])  (B 型相对偏移)
  // !taken: 目标 = pcExtend + (nextPcOffset << 1) (顺序下一条 PC, 用于回退到 fallthrough)
  // 入参 pcExtend 为 VAddrBits+1=51 位(带符号位), 结果再 sext 到 XLEN。
  function automatic logic [XLEN-1:0] branchTarget(
      input logic [VAddrBits:0]    pcExtend,    // 51 位
      input logic                  taken,
      input logic [BrImmWidth-1:0] imm,         // imm[14:0]
      input logic [4:0]            nextPcOffset // log2(PredictWidth)+1 = 5 位
  );
    logic [VAddrBits:0] sum; // 51 位
    sum = taken ? (pcExtend + {{(VAddrBits+1-BrImmWidth){imm[BrImmWidth-1]}}, imm})
                : (pcExtend + {{(VAddrBits+1-6){1'b0}}, nextPcOffset, 1'b0});
    return {{(XLEN-(VAddrBits+1)){sum[VAddrBits]}}, sum}; // sext 51→64
  endfunction

endpackage
