// FMA.sv —— 标量浮点「融合乘加」功能单元（FpPipedFuncUnit, latency=3）
// -----------------------------------------------------------------------------
// 在后端的位置：浮点执行簇 ExeUnit_8(exus) / ExeUnit_10(exus_2, exus_4) 里的一个 FU，
//   与 FAlu / FCVT / IntFPToVec 共享写回端口。覆盖 fmadd / fmsub / fnmadd / fnmsub
//   （a*b±c，单次舍入的 fused multiply-add）以及纯乘 fmul。
// 真正的乘加阵列在 FloatFMA（Booth 编码 + CSA 压缩树 + 3 拍内部流水，本文件按黑盒
//   例化；它的 3 级正好对上本 FU 的 LAT=3）。本层只做四件事：
//     1) 舍入模式选择：指令 rm==3'b111 是「动态舍入」，改用 CSR fcsr.frm；
//     2) 三个源各自的 NaN-boxing 校验 —— 其中 c 源的校验要额外与「非纯乘」相与：
//        fmul 根本不读 c，若还去校验 c 的 box，一个垃圾 c 就会污染 fmul 的结果；
//     3) op_code = fuOpType[3:0] 原样送进阵列（VfmaType 在里面译码乘加的符号组合）；
//     4) 3 级 valid / perfDebugInfo / debug.seqNum 打拍，输出控制取外部预打好的 ctrlPipe[3]。
// 注意 io.out.bits.ctrl **没有 rfWen**：乘加的结果一定是浮点，只会写浮点寄存器堆。
//
// 流水与握手（LAT=3）：
//   G1 相对 G0 的接口变更 —— 新增 io_in_ready(输出) / io_out_ready(输入) 与反压链
//   rdy[]；G0 这三个浮点 FU 端口表里一个 ready 都没有（定长流水恒可收），payload
//   寄存器直接用 `if (io_in_valid)` 使能，G1 改成 fire = valid && ready。G0 那样写
//   在当时是正确的（无 ready ⇒ ready 恒 1），属接口变更的配套改动，不是补 bug。
//   G1 还把 perfDebugInfo 从 3 个字段扩到 10 个，并新增 debug.seqNum{seqNum,uopIdx}。
// =============================================================================
package fma_pkg;

  localparam int unsigned XLEN = 64;

  // 本 FU 的流水级数（FpPipedFuncUnit latency=3）。FAlu=1、FCVT=2 是同一套模型。
  localparam int unsigned LAT = 3;

  // ---------------------------------------------------------------------------
  // 浮点格式 fp_fmt（香山复用 VSew 编码）
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    FMT_E8  = 2'b00,   // 8bit（标量浮点用不到，仅为编码完整）
    FMT_E16 = 2'b01,   // f16  半精度
    FMT_E32 = 2'b10,   // f32  单精度
    FMT_E64 = 2'b11    // f64  双精度
  } fp_fmt_e;

  // ---------------------------------------------------------------------------
  // op_code = fuOpType[3:0]，即 yunsuan.VfmaOpCode（本层只透传，译码在 FloatFMA 内）
  // ---------------------------------------------------------------------------
  //   0 vfmul    a*b（纯乘，不读 c）
  //   1 vfmacc   +(a*b)+c        2 vfnmacc  -(a*b)-c
  //   3 vfmsac   +(a*b)-c        4 vfnmsac  -(a*b)+c
  //   5 vfmadd   +(a*c)+b        6 vfnmadd  -(a*c)-b
  //   7 vfmsub   +(a*c)-b        8 vfnmsub  -(a*c)+b
  //   F dummy（该 FU 未实现的操作）
  // 只有 0 不读 c —— 这就是下面 OP_VFMUL 要被单独拎出来的原因。
  // 另外 fuOpType==9'hFF 是「FU 不该收到这条指令」的哨兵值，golden 在非 SYNTHESIS 下
  // 对它有一条 `assert(false)`；SYNTHESIS 下该断言块被裁掉，所以本核里没有对应逻辑。
  localparam logic [3:0] OP_VFMUL = 4'b0000;

  // ---------------------------------------------------------------------------
  // 随流水搬运的调试/性能采样信息（G1 扩到 10 个字段）
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
  } perf_dbg_t;

  // 指令序号追踪（G1 新增）
  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } seq_num_t;

  // 写回控制：发射级已按 FU 延迟预打好 ctrlPipe[0..LAT]，本 FU 取第 LAT 级那份。
  // 与 FAlu / FCVT 不同，这里没有 rfWen —— 乘加结果恒为浮点。
  typedef struct packed {
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic [7:0] pdest;
    logic       fpWen;          // 写浮点寄存器堆
    logic       fpu_wflags;     // 是否更新 fcsr.fflags
  } wb_ctrl_t;

  // ---------------------------------------------------------------------------
  // 舍入模式选择
  // ---------------------------------------------------------------------------
  // rm==7(0b111) 表示「动态舍入」——用 fcsr.frm 的当前值。
  // 其余是静态舍入：0=RNE 1=RTZ 2=RDN 3=RUP 4=RMM。
  // FMA 的舍入只在最后做一次（fused）：a*b 的全精度中间积不舍入，直接与 c 对阶相加，
  // 这正是 fmadd 与「先 fmul 再 fadd」结果可能不同的原因。
  function automatic logic [2:0] selRoundMode(input logic [2:0] inst_rm,
                                              input logic [2:0] csr_frm);
    selRoundMode = (inst_rm != 3'b111) ? inst_rm : csr_frm;
  endfunction

  // ---------------------------------------------------------------------------
  // NaN-boxing 校验（规范 NaN 判定）
  // ---------------------------------------------------------------------------
  // RISC-V F/D：窄浮点存进宽 FPR 时高位必须全 1。读出时高位不全 1 ⇒ 这不是一个
  // 合法 box 过的窄浮点，按规范 NaN（canonical qNaN）参与运算。
  //   · f32：高 32 位必须是 32'hFFFFFFFF
  //   · f16：高 48 位必须是 48'hFFFFFFFFFFFF
  //   · f64：占满 64 位，无需校验（恒返回 0）
  function automatic logic isFpCanonicalNAN(input logic [1:0]      fmt,
                                            input logic [XLEN-1:0] src);
    logic f32_unboxed, f16_unboxed;
    f32_unboxed = (fmt == FMT_E32) & (src[63:32] != 32'hFFFFFFFF);
    f16_unboxed = (fmt == FMT_E16) & (src[63:16] != 48'hFFFFFFFFFFFF);
    isFpCanonicalNAN = f32_unboxed | f16_unboxed;
  endfunction

endpackage

// =============================================================================
//  可读核
// =============================================================================
module xs_FMA_core
  import fma_pkg::*;
(
  input  logic            clock,
  input  logic            reset,

  // ---- io.in --------------------------------------------------------------
  output logic            io_in_ready,
  input  logic            io_in_valid,
  input  logic [8:0]      io_in_bits_ctrl_fuOpType,
  input  logic [1:0]      io_in_bits_ctrl_fpu_fmt,
  input  logic [2:0]      io_in_bits_ctrl_fpu_rm,
  input  wb_ctrl_t        io_in_bits_ctrlPipe,       // = golden ctrlPipe_3
  input  logic            io_in_bits_validPipe,      // = golden validPipe_3
  input  logic [XLEN-1:0] io_in_bits_data_src_0,     // a（乘数）
  input  logic [XLEN-1:0] io_in_bits_data_src_1,     // b（乘数）
  input  logic [XLEN-1:0] io_in_bits_data_src_2,     // c（加数；纯乘 fmul 不读它）
  input  perf_dbg_t       io_in_bits_perfDebugInfo,
  input  seq_num_t        io_in_bits_debug_seqNum,

  // ---- io.out -------------------------------------------------------------
  input  logic            io_out_ready,
  output logic            io_out_valid,
  output wb_ctrl_t        io_out_bits_ctrl,
  output logic [XLEN-1:0] io_out_bits_res_data,
  output logic [4:0]      io_out_bits_res_fflags,    // {NV,DZ,OF,UF,NX}
  output perf_dbg_t       io_out_bits_perfDebugInfo,
  output seq_num_t        io_out_bits_debug_seqNum,

  // ---- CSR ----------------------------------------------------------------
  input  logic [2:0]      io_frm
);

  // ===========================================================================
  //  §1 本 FU 的 valid 移位寄存器 + 反压链
  // ===========================================================================
  // vldThisFu[s] = 「s 拍前接了一个请求」。写回有效还要与外部 validPipe 相与
  //（发射级可能在这 3 拍里把这条 uop 冲刷掉）。
  //
  // ★ 这条移位链没有 ready 门控（golden: `validVecThisFu_1 <= io_in_valid;` 等），
  //   而 §2 的 payload 寄存器有。若 io_out_ready 真会拉低，valid 照常往前挪、
  //   payload 被冻住，两者就错相——看起来不自洽。为什么当前连接下安全：
  //   ExuBlock_1 里装 FMA 的三个口 exus(ExeUnit_8) / exus_2 / exus_4(ExeUnit_10)
  //   的 io_out_ready 都硬接 1'h1（只有装 FDivSqrt 的 exus_1/exus_3 是真信号），
  //   于是 rdy[] 全链恒 1，两种写法完全等价，这个不一致观测不到。
  //   本工程要求 bug-for-bug 一致，所以照抄不加门控。
  logic [LAT:1] vldThisFu;

  // rdy[s] = 第 s 级能否接新活；rdy[0] 就是对外的 io_in_ready，rdy[LAT] 是写回端口的 ready。
  logic [LAT:0] rdy;
  always_comb begin
    rdy[LAT] = io_out_ready;
    // 「本级能接新活」= 下一级这拍空着，或者下一级自己能腾空
    for (int s = LAT-1; s >= 0; s--) rdy[s] = ~vldThisFu[s+1] | rdy[s+1];
  end
  assign io_in_ready = rdy[0];

  always @(posedge clock or posedge reset) begin
    if (reset)
      vldThisFu <= '0;
    else begin
      vldThisFu[1] <= io_in_valid;                                    // 第 1 级从模块输入进
      for (int s = 2; s <= LAT; s++) vldThisFu[s] <= vldThisFu[s-1];  // 其余级逐级前移
    end
  end

  // ===========================================================================
  //  §2 payload 搬运（perfDebugInfo + debug.seqNum），LAT=3
  // ===========================================================================
  // 使能 = fire = valid && ready：第 1 级取模块输入，第 s 级取第 s-1 级。
  // 无复位——纯调试 payload，复位后头几拍是 X，第一次 fire 之后才有意义。
  perf_dbg_t perfVec   [1:LAT];
  seq_num_t  seqNumVec [1:LAT];
  always @(posedge clock) begin
    if (rdy[0] & io_in_valid) begin
      perfVec[1]   <= io_in_bits_perfDebugInfo;
      seqNumVec[1] <= io_in_bits_debug_seqNum;
    end
    for (int s = 2; s <= LAT; s++) begin
      if (rdy[s-1] & vldThisFu[s-1]) begin
        perfVec[s]   <= perfVec[s-1];
        seqNumVec[s] <= seqNumVec[s-1];
      end
    end
  end

  // ===========================================================================
  //  §3 送进乘加阵列的 IEEE-754 控制位
  // ===========================================================================
  wire [3:0] op_code = io_in_bits_ctrl_fuOpType[3:0];

  // 纯乘 fmul 不读 c。golden 用 `|op_code` 表达「不是 vfmul」，等价于 op_code != 0。
  wire       reads_c = (op_code != OP_VFMUL);

  wire [2:0] round_mode   = selRoundMode(io_in_bits_ctrl_fpu_rm, io_frm);
  wire       fp_a_is_cnan = isFpCanonicalNAN(io_in_bits_ctrl_fpu_fmt, io_in_bits_data_src_0);
  wire       fp_b_is_cnan = isFpCanonicalNAN(io_in_bits_ctrl_fpu_fmt, io_in_bits_data_src_1);
  // c 源：只有真的要读 c 时才让它的 box 违规变成规范 NaN。
  wire       fp_c_is_cnan = reads_c
                          & isFpCanonicalNAN(io_in_bits_ctrl_fpu_fmt, io_in_bits_data_src_2);

  // FloatFMA（黑盒，fudian 库）：Booth 编码（BoothEncoderF64F32F16）+ CSA 压缩树
  //（CSA_Nto2With3to2MainPipeline / CSA4to2 / CSA3to2）+ 3 级内部流水。
  // 三级的使能依次是 io_fire、fire_reg0_last_r、fire_reg1_last_r（后两个是 io_fire
  // 的逐级延迟），所以结果在 io_fire 后第 3 拍稳定——正好对上本 FU 的 LAT=3。
  // IEEE-754 的特殊情形都在它内部：
  //   · fused：a*b 的积不先舍入，直接与对阶后的 c 相加，最后只舍入一次
  //     （这正是 fmadd 与「先 fmul 再 fadd」结果可能不同的原因）；
  //   · NaN 传播：任一源是 NaN（含 box 违规判出的规范 NaN）→ 结果为规范 qNaN，
  //     源里有 sNaN 还要置 NV；0*Inf 这种无效组合同样置 NV；
  //   · 非规格化源先归一化再参与运算，结果下溢成非规格化时置 UF|NX。
  FloatFMA fma (
    .clock                   (clock),
    .reset                   (reset),
    .io_fire                 (io_in_valid),
    .io_fp_a                 (io_in_bits_data_src_0),
    .io_fp_b                 (io_in_bits_data_src_1),
    .io_fp_c                 (io_in_bits_data_src_2),
    .io_round_mode           (round_mode),
    .io_fp_format            (io_in_bits_ctrl_fpu_fmt),
    .io_op_code              (op_code),
    .io_fp_result            (io_out_bits_res_data),
    .io_fflags               (io_out_bits_res_fflags),
    .io_fp_aIsFpCanonicalNAN (fp_a_is_cnan),
    .io_fp_bIsFpCanonicalNAN (fp_b_is_cnan),
    .io_fp_cIsFpCanonicalNAN (fp_c_is_cnan)
  );

  // ===========================================================================
  //  §4 写回
  // ===========================================================================
  assign io_out_valid              = io_in_bits_validPipe & vldThisFu[LAT];
  assign io_out_bits_ctrl          = io_in_bits_ctrlPipe;
  assign io_out_bits_perfDebugInfo = perfVec[LAT];
  assign io_out_bits_debug_seqNum  = seqNumVec[LAT];

endmodule

// =============================================================================
//  golden 同名层：端口与 firtool 输出逐位同名，例化可读核并把 struct 展平
// =============================================================================
module FMA(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input  [1:0]  io_in_bits_ctrl_fpu_fmt,
  input  [2:0]  io_in_bits_ctrl_fpu_rm,
  input         io_in_bits_ctrlPipe_3_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_3_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_3_pdest,
  input         io_in_bits_ctrlPipe_3_fpWen,
  input         io_in_bits_ctrlPipe_3_fpu_wflags,
  input         io_in_bits_validPipe_3,
  input  [63:0] io_in_bits_data_src_2,
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
  output        io_out_bits_ctrl_fpWen,
  output        io_out_bits_ctrl_fpu_wflags,
  output [63:0] io_out_bits_res_data,
  output [4:0]  io_out_bits_res_fflags,
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
  output [7:0]  io_out_bits_debug_seqNum_uopIdx,
  input  [2:0]  io_frm
);

  fma_pkg::wb_ctrl_t  ctrl_in, ctrl_out;
  fma_pkg::perf_dbg_t perf_in, perf_out;
  fma_pkg::seq_num_t  seq_in,  seq_out;

  always_comb begin
    ctrl_in.robIdx_flag  = io_in_bits_ctrlPipe_3_robIdx_flag;
    ctrl_in.robIdx_value = io_in_bits_ctrlPipe_3_robIdx_value;
    ctrl_in.pdest        = io_in_bits_ctrlPipe_3_pdest;
    ctrl_in.fpWen        = io_in_bits_ctrlPipe_3_fpWen;
    ctrl_in.fpu_wflags   = io_in_bits_ctrlPipe_3_fpu_wflags;

    perf_in.eliminatedMove         = io_in_bits_perfDebugInfo_eliminatedMove;
    perf_in.renameTime             = io_in_bits_perfDebugInfo_renameTime;
    perf_in.dispatchTime           = io_in_bits_perfDebugInfo_dispatchTime;
    perf_in.enqRsTime              = io_in_bits_perfDebugInfo_enqRsTime;
    perf_in.selectTime             = io_in_bits_perfDebugInfo_selectTime;
    perf_in.issueTime              = io_in_bits_perfDebugInfo_issueTime;
    perf_in.writebackTime          = io_in_bits_perfDebugInfo_writebackTime;
    perf_in.runahead_checkpoint_id = io_in_bits_perfDebugInfo_runahead_checkpoint_id;
    perf_in.tlbFirstReqTime        = io_in_bits_perfDebugInfo_tlbFirstReqTime;
    perf_in.tlbRespTime            = io_in_bits_perfDebugInfo_tlbRespTime;

    seq_in.seqNum = io_in_bits_debug_seqNum_seqNum;
    seq_in.uopIdx = io_in_bits_debug_seqNum_uopIdx;
  end

  assign io_out_bits_ctrl_robIdx_flag  = ctrl_out.robIdx_flag;
  assign io_out_bits_ctrl_robIdx_value = ctrl_out.robIdx_value;
  assign io_out_bits_ctrl_pdest        = ctrl_out.pdest;
  assign io_out_bits_ctrl_fpWen        = ctrl_out.fpWen;
  assign io_out_bits_ctrl_fpu_wflags   = ctrl_out.fpu_wflags;

  assign io_out_bits_perfDebugInfo_eliminatedMove         = perf_out.eliminatedMove;
  assign io_out_bits_perfDebugInfo_renameTime             = perf_out.renameTime;
  assign io_out_bits_perfDebugInfo_dispatchTime           = perf_out.dispatchTime;
  assign io_out_bits_perfDebugInfo_enqRsTime              = perf_out.enqRsTime;
  assign io_out_bits_perfDebugInfo_selectTime             = perf_out.selectTime;
  assign io_out_bits_perfDebugInfo_issueTime              = perf_out.issueTime;
  assign io_out_bits_perfDebugInfo_writebackTime          = perf_out.writebackTime;
  assign io_out_bits_perfDebugInfo_runahead_checkpoint_id = perf_out.runahead_checkpoint_id;
  assign io_out_bits_perfDebugInfo_tlbFirstReqTime        = perf_out.tlbFirstReqTime;
  assign io_out_bits_perfDebugInfo_tlbRespTime            = perf_out.tlbRespTime;

  assign io_out_bits_debug_seqNum_seqNum = seq_out.seqNum;
  assign io_out_bits_debug_seqNum_uopIdx = seq_out.uopIdx;

  xs_FMA_core u_core (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_ready               (io_in_ready),
    .io_in_valid               (io_in_valid),
    .io_in_bits_ctrl_fuOpType  (io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_fpu_fmt   (io_in_bits_ctrl_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm    (io_in_bits_ctrl_fpu_rm),
    .io_in_bits_ctrlPipe       (ctrl_in),
    .io_in_bits_validPipe      (io_in_bits_validPipe_3),
    .io_in_bits_data_src_0     (io_in_bits_data_src_0),
    .io_in_bits_data_src_1     (io_in_bits_data_src_1),
    .io_in_bits_data_src_2     (io_in_bits_data_src_2),
    .io_in_bits_perfDebugInfo  (perf_in),
    .io_in_bits_debug_seqNum   (seq_in),
    .io_out_ready              (io_out_ready),
    .io_out_valid              (io_out_valid),
    .io_out_bits_ctrl          (ctrl_out),
    .io_out_bits_res_data      (io_out_bits_res_data),
    .io_out_bits_res_fflags    (io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo (perf_out),
    .io_out_bits_debug_seqNum  (seq_out),
    .io_frm                    (io_frm)
  );

endmodule
