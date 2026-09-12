// =============================================================================
// MulUnit.sv —— 整数乘法功能单元（RV64 M 扩展的乘法半边）
//
// 在流水线里的位置：后端 ExuBlock 的一个整数执行单元，与 Alu / Bku 并列。只管乘
//   （mul / mulh / mulhsu / mulhu / mulw / mulw7），除法与取余在 DivUnit 里。
//   编码见 xiangshan/package.scala 的 object MDUOpType（bit4=0 才是乘法）。
//
// 它算什么：本层**不含乘法阵列**，阵列是 ArrayMulDataModule（Wallace 树 + 进位
//   传播加法，2 级流水，与 G0 逐字相同故直接例化 golden 实现）。本层做四件事：
//     1) 译码 + 符号处理：按 op={func[3],func[1:0]} 把两个 64bit 源扩到 65bit
//        （mulh 双带符号、mulhsu 一半带符号、mul/mulhu 全无符号、mulw7 只取
//        src0 低 7bit），65bit 是为了用一个带符号阵列同时干无符号乘；
//     2) 把 {isW,isHi} 两位控制随阵列时延打两拍，使末级用的是当初那条指令的控制；
//     3) 按末级 isHi 从 130bit 乘积里选高 64 / 低 64 位；
//     4) 按末级 isW 把 32bit 结果符号扩展回 64bit（mulw/mulw7）。
//
// 流水级数与握手：latency=2 的定长流水（Chisel FuncUnit + HasPipelineReg，
//   见 src/main/scala/xiangshan/backend/fu/FuncUnit.scala:166 与
//   backend/fu/wrapper/MulUnit.scala）。s0 收指令送阵列 → s1 阵列中间级 →
//   s2 阵列出积、组合选高低半后直接送写回（本层末级**没有**输出数据寄存器，
//   与 Bku 不同）。G1 起对外有真握手：io_in_ready / io_out_ready。
//
// G1 相对 G0 的改动（乘法与译码一个字没动，全是流水壳的接口增量）：
//   + 新增 io_in_ready / io_out_ready 与 rdyVec 反压链；
//   + 控制/perf/seqNum 流水寄存器与阵列的 regEnables 一律改成 fire = valid & ready
//     门控（G0 没有 ready 端口 ⇒ ready 恒 1 ⇒ 当时不写门控也是对的，不是 bug）；
//   + perfDebugInfo 从 3 个字段（enqRs/select/issue）扩到 10 个，
//     另加 debug.seqNum{seqNum[55:0], uopIdx[7:0]}。
// =============================================================================

package mulunit_pkg;

  // ---- 位宽 ----
  // 阵列输入加 1 位做"统一带符号"的扩展位，故 65；乘积 2×65=130
  // （只有低 128 位有意义，高 2 位是扩展位相乘的产物，从不被选用）。
  localparam int XLEN    = 64;
  localparam int MUL_LEN = XLEN + 1;      // 65
  localparam int RES_LEN = 2 * MUL_LEN;   // 130

  // ---------------------------------------------------------------------------
  // 乘法子操作。MDUOpType 的 5 位编码是 | type(2) | isWord(1) | opcode(2) |，
  // 本层只需要 op = {func[3], func[1:0]}（MDUOpType.getMulOp 加上 type 低位）：
  //     mul    = 0_0_000 → op=000        mulw   = 0_0_100 → op=000（与 mul 同扩展，
  //     mulh   = 0_0_001 → op=001                            只是 isW=1 结果取低 32）
  //     mulhsu = 0_0_010 → op=010        mulw7  = 0_1_100 → op=100
  //     mulhu  = 0_0_011 → op=011
  // mulw7 是**指令融合**的产物：前端把 `andi rX,rY,127` + `mulw` 两条并成一条
  // （backend/decode/FusionDecoder.scala 的 FusedMulw7），所以它的 src0 天然只有
  // 低 7bit 有效——这里直接截 7bit，把那条 andi 省掉；isW=1，结果仍按 32bit 符号扩展。
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    MUL_MUL    = 3'b000,   // 低 64 位乘积；两源无符号扩展即可（低半与符号无关）
    MUL_MULH   = 3'b001,   // 高 64 位；signed × signed
    MUL_MULHSU = 3'b010,   // 高 64 位；signed(src0) × unsigned(src1)
    MUL_MULHU  = 3'b011,   // 高 64 位；unsigned × unsigned
    MUL_MULW7  = 3'b100    // src0 只取低 7bit（无符号），src1 无符号
  } mul_op_e;

  function automatic mul_op_e get_mul_op(input logic [8:0] func);
    return mul_op_e'({func[3], func[1:0]});
  endfunction

  // ---- 65bit 扩展 ----
  function automatic logic [MUL_LEN-1:0] sext65(input logic [XLEN-1:0] x);
    return {x[XLEN-1], x};
  endfunction

  function automatic logic [MUL_LEN-1:0] zext65(input logic [XLEN-1:0] x);
    return {1'b0, x};
  endfunction

  // a 端（src0）扩展。default 给 0 而不是透传：golden 那边是 LookupTree 展开成
  // "各 op 掩码后按位或"，未列出的 op（101/110/111，编码空间里没有的乘法）结果
  // 就是全 0；这里必须照抄这个语义，否则 FM 会在非法编码上判不等价。
  function automatic logic [MUL_LEN-1:0] cvt_mul_a(input mul_op_e op,
                                                   input logic [XLEN-1:0] src0);
    case (op)
      MUL_MUL, MUL_MULHU   : cvt_mul_a = zext65(src0);
      MUL_MULH, MUL_MULHSU : cvt_mul_a = sext65(src0);
      MUL_MULW7            : cvt_mul_a = {{(MUL_LEN-7){1'b0}}, src0[6:0]};
      default              : cvt_mul_a = '0;
    endcase
  endfunction

  // b 端（src1）扩展：只有 mulh 需要带符号，其余一律零扩展（同样 default=0）。
  function automatic logic [MUL_LEN-1:0] cvt_mul_b(input mul_op_e op,
                                                   input logic [XLEN-1:0] src1);
    case (op)
      MUL_MULH                                  : cvt_mul_b = sext65(src1);
      MUL_MUL, MUL_MULHSU, MUL_MULHU, MUL_MULW7 : cvt_mul_b = zext65(src1);
      default                                   : cvt_mul_b = '0;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // 随阵列时延打拍的控制位（Chisel MulDivCtrl 里本 FU 用得到的两位）：
  //   isHi = func[1:0] 非零 → 结果取高半（mulh/mulhsu/mulhu）
  //   isW  = func[2]        → 字操作，结果按 32→64 符号扩展（mulw/mulw7）
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic isW;
    logic isHi;
  } mul_ctrl_t;

  function automatic mul_ctrl_t decode_mul_ctrl(input logic [8:0] func);
    mul_ctrl_t c;
    c.isW  = func[2];
    c.isHi = |func[1:0];
    return c;
  endfunction

  // ---- 结果选择 ----
  function automatic logic [XLEN-1:0] sel_mul_hilo(input logic isHi,
                                                   input logic [RES_LEN-1:0] product);
    sel_mul_hilo = isHi ? product[2*XLEN-1 : XLEN] : product[XLEN-1 : 0];
  endfunction

  function automatic logic [XLEN-1:0] final_mul_res(input logic isW,
                                                    input logic [XLEN-1:0] res);
    final_mul_res = isW ? {{(XLEN-32){res[31]}}, res[31:0]} : res;
  endfunction

  // ---------------------------------------------------------------------------
  // 随指令走的控制信息：上游数据通路已替本 FU 打好拍的第 2 级
  // （io.in.bits.ctrlPipe(2)），本 FU 直接透传到输出。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic [7:0] pdest;
    logic       rfWen;
  } mul_pipe_ctrl_t;

  // ---------------------------------------------------------------------------
  // perf 调试计时信息：不参与运算，只随流水搬运。G1 有 10 个字段
  // （G0 只有 enqRs/select/issue 三个）——golden 那边是 2×10 个扁平寄存器各写一条
  // 门控赋值，用 struct 打包后本文件只剩两处。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic        eliminatedMove;
    logic [63:0] renameTime;
    logic [63:0] dispatchTime;
    logic [63:0] enqRsTime;
    logic [63:0] selectTime;
    logic [63:0] issueTime;
    logic [63:0] writebackTime;
    logic [63:0] runahead_checkpoint_id;
    logic [63:0] tlbFirstReqTime;
    logic [63:0] tlbRespTime;
  } mul_perf_t;

  // 指令序号追踪（difftest / 波形定位用）
  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } mul_seqnum_t;

endpackage


// =============================================================================
// xs_MulUnit_core —— 可读核：2 级定长流水壳 + 译码/符号扩展 + 结果选择
// =============================================================================
module xs_MulUnit_core
  import mulunit_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  // ---- 输入侧（io.in）----
  input  logic            in_valid,
  output logic            in_ready,
  input  logic [8:0]      in_fuOpType,
  input  logic [XLEN-1:0] in_src0,          // rs1（被乘数）
  input  logic [XLEN-1:0] in_src1,          // rs2（乘数）
  // 上游数据通路预先打好的逐级 valid / 第 2 级控制（本 FU 只消费，不产生）
  input  logic            in_validPipe0,
  input  logic            in_validPipe1,
  input  logic            in_validPipe2,
  input  mul_pipe_ctrl_t  in_ctrlPipe2,
  input  mul_perf_t       in_perf,
  input  mul_seqnum_t     in_seqNum,

  // ---- 输出侧（io.out）----
  input  logic            out_ready,
  output logic            out_valid,
  output mul_pipe_ctrl_t  out_ctrl,
  output logic [XLEN-1:0] out_res_data,
  output mul_perf_t       out_perf,
  output mul_seqnum_t     out_seqNum
);

  // ===========================================================================
  // 1. 本 FU 自己的 valid 移位链 validVecThisFu(1)/(2)
  // ---------------------------------------------------------------------------
  // 本模块唯一带复位的寄存器（异步复位，与 golden 一致）。
  //
  // ★ 这里有一处**看起来不自洽**的地方，照 golden 原样保留，读者务必注意：
  //   下面的 valid 链是**无条件**每拍左移的，没有 ready 门控；而同一条流水上的
  //   控制 / perf / 阵列内部寄存器都加了 ready 门控（第 3 节）。
  //   这不是 firtool 的产物——Chisel 源码 FuncUnit.scala 的 pipelineReg() 里，
  //   `validVec(i) := validVec(i-1)` 写在 `when(rdyVec(i-1) && validVec(i-1))`
  //   **之外**，只有 ctrl/data/perf/seqNum 在 when 里面。
  //   后果：若下游真的拉低 ready，valid 会继续往前走而数据停在原地，
  //   即"valid 与 payload 脱节"。为什么现在是安全的：整数域 ExuBlock 把除
  //   exus_7 之外所有执行口的 io_out_ready 硬接 1'b1，于是 rdy_s1/rdy_s0 恒 1，
  //   两种写法完全等价，这条路径不可达。
  //   本工程要求与 golden bug-for-bug 一致，故**不加门控**；只在这里记下来。
  // ===========================================================================
  logic valid_thisfu_1, valid_thisfu_2;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_thisfu_1 <= 1'b0;
      valid_thisfu_2 <= 1'b0;
    end else begin
      valid_thisfu_1 <= in_valid;          // 无 ready 门控：见上面说明
      valid_thisfu_2 <= valid_thisfu_1;
    end
  end

  // ===========================================================================
  // 2. 反压链（G1 新增）：从末级往前推的纯组合链
  // ---------------------------------------------------------------------------
  //   rdy_s1 = 第 2 级空着，或者下游这拍收走
  //   rdy_s0 = 第 1 级空着，或者第 2 级这拍能接
  //   in_ready = rdy_s0
  // 即 Chisel 的 `rdyVec(i) := !validVec(i+1) || rdyVec(i+1)`，末项接 io.out.ready。
  // 判据用的是本 FU 自己的 valid 链（不含上游 validPipe）。
  // ===========================================================================
  logic rdy_s0, rdy_s1;
  assign rdy_s1   = ~valid_thisfu_2 | out_ready;
  assign rdy_s0   = ~valid_thisfu_1 | rdy_s1;
  assign in_ready = rdy_s0;

  // ===========================================================================
  // 3. 三种流水使能：同一条流水上有三个略有差别的 fire，不要混用
  // ---------------------------------------------------------------------------
  //   fire_s0    = in_valid & rdy_s0                     —— io.in.fire
  //                用于 perf(1) / seqNum(1)：FU 自带流水寄存器，只看本 FU 握手。
  //   reg_en_s1  = validPipe0 & in_valid       & rdy_s0  —— regEnable(1)
  //                用于阵列第 1 级与控制 {isW,isHi} 第 1 拍：真正搬运数据，
  //                要求上游那一级也确实有效
  //                （validVec(i) = validPipe(i) & validVecThisFu(i)）。
  //   reg_en_s2  = validPipe1 & valid_thisfu_1 & rdy_s1  —— regEnable(2)
  //                用于阵列第 2 级与控制第 2 拍。
  //   perf_en_s2 = valid_thisfu_1 & rdy_s1               —— perf/seqNum 第 2 级
  //                （与 reg_en_s2 差一个 validPipe1）。
  // ===========================================================================
  logic fire_s0, reg_en_s1, reg_en_s2, perf_en_s2;
  assign fire_s0    = in_valid & rdy_s0;
  assign reg_en_s1  = in_validPipe0 & in_valid       & rdy_s0;
  assign reg_en_s2  = in_validPipe1 & valid_thisfu_1 & rdy_s1;
  assign perf_en_s2 =                 valid_thisfu_1 & rdy_s1;

  // ===========================================================================
  // 4. s0：译码 + 65bit 符号处理，送乘法阵列
  // ---------------------------------------------------------------------------
  // 阵列是纯数据通路（除两级 regEnable 外无控制），它不知道自己在算哪条指令，
  // 全靠这里把源扩成"当作带符号乘也对"的 65bit 形式。
  // ===========================================================================
  mul_op_e            op;
  logic [MUL_LEN-1:0] mul_a, mul_b;
  assign op    = get_mul_op(in_fuOpType);
  assign mul_a = cvt_mul_a(op, in_src0);
  assign mul_b = cvt_mul_b(op, in_src1);

  logic [RES_LEN-1:0] product;
  ArrayMulDataModule mulDataModule (
    .clock           (clock),
    .io_a            (mul_a),
    .io_b            (mul_b),
    .io_regEnables_0 (reg_en_s1),
    .io_regEnables_1 (reg_en_s2),
    .io_result       (product)
  );

  // ===========================================================================
  // 5. 控制 {isW,isHi} 跟着阵列走两拍
  // ---------------------------------------------------------------------------
  // 使能与阵列各级完全同一根线，所以末级 ctrl_s2 一定对应 product 里那条指令。
  // 无复位（与 golden 一致）。
  // ===========================================================================
  mul_ctrl_t ctrl_s0, ctrl_s1, ctrl_s2;
  assign ctrl_s0 = decode_mul_ctrl(in_fuOpType);
  always_ff @(posedge clock) begin
    if (reg_en_s1) ctrl_s1 <= ctrl_s0;
    if (reg_en_s2) ctrl_s2 <= ctrl_s1;
  end

  // ===========================================================================
  // 6. s2：选高低半 + W 符号扩展（纯组合，本层没有输出数据寄存器）
  // ===========================================================================
  assign out_res_data = final_mul_res(ctrl_s2.isW, sel_mul_hilo(ctrl_s2.isHi, product));

  // ===========================================================================
  // 7. perf / seqNum 随流水打两拍（不参与运算，纯搬运；无复位）
  // ===========================================================================
  mul_perf_t   perf_s1, perf_s2;
  mul_seqnum_t seq_s1,  seq_s2;
  always_ff @(posedge clock) begin
    if (fire_s0) begin
      perf_s1 <= in_perf;
      seq_s1  <= in_seqNum;
    end
    if (perf_en_s2) begin
      perf_s2 <= perf_s1;
      seq_s2  <= seq_s1;
    end
  end

  // ===========================================================================
  // 8. 输出组装
  // ---------------------------------------------------------------------------
  // out_valid = 上游第 2 级 valid & 本 FU 第 2 级 valid（validVec.last）；
  // 控制位直接取上游已打好拍的 ctrlPipe(2)。
  // ===========================================================================
  assign out_valid  = in_validPipe2 & valid_thisfu_2;
  assign out_ctrl   = in_ctrlPipe2;
  assign out_perf   = perf_s2;
  assign out_seqNum = seq_s2;

endmodule


// =============================================================================
// MulUnit —— golden 同名壳：把扁平端口打包成 struct 交给可读核，本身不含逻辑
// =============================================================================
module MulUnit(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input         io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_2_pdest,
  input         io_in_bits_ctrlPipe_2_rfWen,
  input         io_in_bits_validPipe_0,
  input         io_in_bits_validPipe_1,
  input         io_in_bits_validPipe_2,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input         io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0] io_in_bits_debug_seqNum_seqNum,
  input  [7:0]  io_in_bits_debug_seqNum_uopIdx,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_ctrl_robIdx_flag,
  output [7:0]  io_out_bits_ctrl_robIdx_value,
  output [7:0]  io_out_bits_ctrl_pdest,
  output        io_out_bits_ctrl_rfWen,
  output [63:0] io_out_bits_res_data,
  output        io_out_bits_perfDebugInfo_eliminatedMove,
  output [63:0] io_out_bits_perfDebugInfo_renameTime,
  output [63:0] io_out_bits_perfDebugInfo_dispatchTime,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  output [63:0] io_out_bits_perfDebugInfo_writebackTime,
  output [63:0] io_out_bits_perfDebugInfo_runahead_checkpoint_id,
  output [63:0] io_out_bits_perfDebugInfo_tlbFirstReqTime,
  output [63:0] io_out_bits_perfDebugInfo_tlbRespTime,
  output [55:0] io_out_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_bits_debug_seqNum_uopIdx
);

  mulunit_pkg::mul_pipe_ctrl_t in_ctrl_pipe2;
  mulunit_pkg::mul_perf_t      in_perf;
  mulunit_pkg::mul_seqnum_t    in_seq_num;
  mulunit_pkg::mul_pipe_ctrl_t out_ctrl;
  mulunit_pkg::mul_perf_t      out_perf;
  mulunit_pkg::mul_seqnum_t    out_seq_num;

  assign in_ctrl_pipe2 = '{
    robIdx_flag: io_in_bits_ctrlPipe_2_robIdx_flag,
    robIdx_value: io_in_bits_ctrlPipe_2_robIdx_value,
    pdest: io_in_bits_ctrlPipe_2_pdest,
    rfWen: io_in_bits_ctrlPipe_2_rfWen
  };

  assign in_perf = '{
    eliminatedMove: io_in_bits_perfDebugInfo_eliminatedMove,
    renameTime: io_in_bits_perfDebugInfo_renameTime,
    dispatchTime: io_in_bits_perfDebugInfo_dispatchTime,
    enqRsTime: io_in_bits_perfDebugInfo_enqRsTime,
    selectTime: io_in_bits_perfDebugInfo_selectTime,
    issueTime: io_in_bits_perfDebugInfo_issueTime,
    writebackTime: io_in_bits_perfDebugInfo_writebackTime,
    runahead_checkpoint_id: io_in_bits_perfDebugInfo_runahead_checkpoint_id,
    tlbFirstReqTime: io_in_bits_perfDebugInfo_tlbFirstReqTime,
    tlbRespTime: io_in_bits_perfDebugInfo_tlbRespTime
  };

  assign in_seq_num = '{
    seqNum: io_in_bits_debug_seqNum_seqNum,
    uopIdx: io_in_bits_debug_seqNum_uopIdx
  };

  xs_MulUnit_core u_core (
    .clock         (clock),
    .reset         (reset),
    .in_valid      (io_in_valid),
    .in_ready      (io_in_ready),
    .in_fuOpType   (io_in_bits_ctrl_fuOpType),
    .in_src0       (io_in_bits_data_src_0),
    .in_src1       (io_in_bits_data_src_1),
    .in_validPipe0 (io_in_bits_validPipe_0),
    .in_validPipe1 (io_in_bits_validPipe_1),
    .in_validPipe2 (io_in_bits_validPipe_2),
    .in_ctrlPipe2  (in_ctrl_pipe2),
    .in_perf       (in_perf),
    .in_seqNum     (in_seq_num),
    .out_ready     (io_out_ready),
    .out_valid     (io_out_valid),
    .out_ctrl      (out_ctrl),
    .out_res_data  (io_out_bits_res_data),
    .out_perf      (out_perf),
    .out_seqNum    (out_seq_num)
  );

  // 展平回 golden 端口
  assign io_out_bits_ctrl_robIdx_flag  = out_ctrl.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = out_ctrl.robIdx_value;
  assign io_out_bits_ctrl_pdest        = out_ctrl.pdest;
  assign io_out_bits_ctrl_rfWen        = out_ctrl.rfWen;

  assign io_out_bits_perfDebugInfo_eliminatedMove         = out_perf.eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = out_perf.renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = out_perf.dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = out_perf.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = out_perf.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = out_perf.issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = out_perf.writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = out_perf.runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = out_perf.tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = out_perf.tlbRespTime;

  assign io_out_bits_debug_seqNum_seqNum = out_seq_num.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx = out_seq_num.uopIdx;

endmodule
