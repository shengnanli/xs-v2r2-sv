// FAlu.sv —— 标量浮点「加/减/比较/符号注入/分类/选最值」功能单元（FpPipedFuncUnit, latency=1）
// -----------------------------------------------------------------------------
// 在后端的位置：浮点执行簇 ExeUnit_8(exus) / ExeUnit_10(exus_2, exus_4) 里的一个 FU，
//   与 FMA / FCVT / IntFPToVec 共享同一个写回端口，由 Dispatcher 按 fuType 一发一。
// 这一层不做浮点运算：真正的加法器是 FloatAdder（内部 F64 与 F32/F16 两条 1 拍流水，
//   本文件按黑盒例化）。本层负责「把 IEEE-754 语义相关的控制位算对，再把 payload 按
//   FU 延迟搬运到写回级」，具体四件事：
//     1) 舍入模式选择：指令 rm==3'b111 是「动态舍入」，此时改用 CSR fcsr.frm；
//     2) NaN-boxing 校验：窄浮点装进 64bit 寄存器时高位必须全 1，不合规就当规范 NaN；
//     3) op_code = fuOpType[4:0] 原样送进加法器（feq/flt/fle/fmin/fmax/fsgnj*/fclass… 在里面译码）；
//     4) 1 级 valid / perfDebugInfo / debug.seqNum 打拍，输出控制取外部预打拍的 ctrlPipe[1]。
//
// 流水与握手（本文件 LAT=1，即 io.in 这拍进、下一拍写回）：
//   G1 相对 G0 的接口变更 —— 新增 `io_in_ready`(输出) 与 `io_out_ready`(输入)，
//   并建了一条自后向前的「本级空 或 下级能收」反压链（本文件只有一节，见 §1）。G0 这三个浮点 FU
//   端口表里一个 ready 都没有（定长流水、恒可收），所以 G0 的 payload 寄存器直接用
//   `if (io_in_valid)` 使能；G1 改成 `if (rdy_0 & io_in_valid)`（fire = valid && ready）。
//   G0 的写法在当时是正确的（无 ready 端口 ⇒ ready 恒 1），这是接口变更的配套改动，不是补 bug。
//   同时 G1 把 perfDebugInfo 从 3 个字段扩到 10 个，并新增 debug.seqNum{seqNum,uopIdx}。
// =============================================================================
package falu_pkg;

  localparam int unsigned XLEN = 64;

  // ---------------------------------------------------------------------------
  // 浮点格式 fp_fmt —— 香山把向量元素宽度编码 VSew 复用为标量浮点格式
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    FMT_E8  = 2'b00,   // 8bit（标量浮点用不到，仅为编码完整）
    FMT_E16 = 2'b01,   // f16  半精度
    FMT_E32 = 2'b10,   // f32  单精度
    FMT_E64 = 2'b11    // f64  双精度
  } fp_fmt_e;

  // ---------------------------------------------------------------------------
  // op_code = fuOpType[4:0]，即 yunsuan.VfaddOpCode（本层只透传，译码在 FloatAdder 内）
  // ---------------------------------------------------------------------------
  //   00 fadd     01 fsub     02 fmin     03 fmax     04 fmerge   05 fmove
  //   06 fsgnj    07 fsgnjn   08 fsgnjx   09 feq      0A fne      0B flt
  //   0C fle      0D fgt      0E fge      0F fclass   11 fmv_f_s  12 fmv_s_f
  //   13 fmaxm    14 fmin_re  15 fmax_re  16 fsum_ore 1A fsum_ure
  //   1B fltq     1C fleq     1E fminm    1F dummy（该 FU 未实现的操作）
  // 两类结果要分清，因为它们决定写哪个寄存器堆（wb_ctrl_t.rfWen / fpWen），也决定
  // 窄结果要不要 NaN-box：
  //   · 浮点结果：fadd/fsub/fmin/fmax/fsgnj*/fmaxm/fminm —— FloatAdder 内部会给窄结果补 box；
  //   · 整数结果：feq/fne/flt/fle/fgt/fge/fclass/fltq/fleq —— 不 box，直接写整数 RF。
  // 另外 fuOpType==9'hFF 是「FU 不该收到这条指令」的哨兵值，golden 在非 SYNTHESIS 下
  // 对它有一条 `assert(false)`；SYNTHESIS 下该断言块被裁掉，所以本核里没有对应逻辑。

  // ---------------------------------------------------------------------------
  // 随流水搬运的调试/性能采样信息（不参与运算，只是 payload）
  // ---------------------------------------------------------------------------
  // G1 新增了 eliminatedMove / renameTime / dispatchTime / writebackTime /
  // runahead_checkpoint_id / tlbFirstReqTime / tlbRespTime；G0 只有 enqRs/select/issue 三个。
  typedef struct packed {
    logic        eliminatedMove;            // 该 uop 是否被 rename 阶段的 move elimination 吃掉
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

  // 指令序号追踪（G1 新增）：seqNum 是全局单调 uop 序号，uopIdx 是同一条指令内的拆分序号。
  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } seq_num_t;

  // 写回控制信息。注意它**不是本 FU 打拍出来的**：发射级已经按各 FU 的固定延迟
  // 预先打好了 ctrlPipe[0..1]，本 FU 只取第 1 级那份直接转发。
  typedef struct packed {
    logic       robIdx_flag;    // ROB 指针的回绕标志
    logic [7:0] robIdx_value;
    logic [7:0] pdest;          // 物理目的寄存器
    logic       rfWen;          // 写整数寄存器堆（fclass/比较类的结果是整数）
    logic       fpWen;          // 写浮点寄存器堆
    logic       fpu_wflags;     // 该指令是否要更新 fcsr.fflags
  } wb_ctrl_t;

  // ---------------------------------------------------------------------------
  // 舍入模式选择
  // ---------------------------------------------------------------------------
  // RISC-V 浮点指令的 rm 字段取 7(0b111) 表示「动态舍入」——用 fcsr.frm 的当前值。
  // 其余取值就是静态舍入：0=RNE 1=RTZ 2=RDN 3=RUP 4=RMM。
  function automatic logic [2:0] selRoundMode(input logic [2:0] inst_rm,
                                              input logic [2:0] csr_frm);
    selRoundMode = (inst_rm != 3'b111) ? inst_rm : csr_frm;
  endfunction

  // ---------------------------------------------------------------------------
  // NaN-boxing 校验（规范 NaN 判定）
  // ---------------------------------------------------------------------------
  // RISC-V F/D 规定：把窄浮点存进宽 FPR 时，未用到的高位必须全 1（NaN-boxing）。
  // 读出时若高位不是全 1，说明这个寄存器里装的不是一个合法 box 过的窄浮点，
  // 按规范 NaN（canonical qNaN）参与运算。FloatAdder 拿到这个标志就直接走 NaN 通路。
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
//  可读核：结构化端口（struct 打包 payload）+ 1 级搬运 + 反压
// =============================================================================
module xs_FAlu_core
  import falu_pkg::*;
(
  input  logic            clock,
  input  logic            reset,

  // ---- io.in：发射级送来的一拍请求 ----------------------------------------
  output logic            io_in_ready,      // 本 FU 能否接新请求（= rdy_0）
  input  logic            io_in_valid,
  input  logic [8:0]      io_in_bits_ctrl_fuOpType,
  input  logic [1:0]      io_in_bits_ctrl_fpu_fmt,
  input  logic [2:0]      io_in_bits_ctrl_fpu_rm,
  input  wb_ctrl_t        io_in_bits_ctrlPipe,     // = golden ctrlPipe_1（外部已打到第 1 级）
  input  logic            io_in_bits_validPipe,    // = golden validPipe_1
  input  logic [XLEN-1:0] io_in_bits_data_src_0,   // 被加数 a
  input  logic [XLEN-1:0] io_in_bits_data_src_1,   // 加数   b
  input  perf_dbg_t       io_in_bits_perfDebugInfo,
  input  seq_num_t        io_in_bits_debug_seqNum,

  // ---- io.out：写回级 ------------------------------------------------------
  input  logic            io_out_ready,     // 写回端口能否收（KunminghuV2Config 下恒 1，见 §1）
  output logic            io_out_valid,
  output wb_ctrl_t        io_out_bits_ctrl,
  output logic [XLEN-1:0] io_out_bits_res_data,
  output logic [4:0]      io_out_bits_res_fflags,  // {NV,DZ,OF,UF,NX}
  output perf_dbg_t       io_out_bits_perfDebugInfo,
  output seq_num_t        io_out_bits_debug_seqNum,

  // ---- CSR ----------------------------------------------------------------
  input  logic [2:0]      io_frm            // fcsr.frm，动态舍入时使用
);

  // ===========================================================================
  //  §1 本 FU 的 valid 流水 + 反压链
  // ===========================================================================
  // vldThisFu_1 = 「上一拍接了一个请求」，即本 FU 内部第 1 级的占位。真正的写回
  // 有效还要与外部 validPipe 相与（发射级可能在这期间冲刷掉这条 uop）。
  //
  // 反压链的通用形式是 rdy[LAT] = io_out_ready、rdy[s] = ~vldThisFu[s+1] | rdy[s+1]
  //（「本级能接新活」= 下一级这拍空着，或者下一级自己能腾空）。LAT=1 时链只有一节，
  // rdy[1] 就是 io_out_ready，所以这里直接写开，不搞数组——FCVT(LAT=2) 与 FMA(LAT=3)
  // 里那条同样的递推才需要数组写法。golden 也是这么塌缩的：
  //   rdyVec_0 = ~validVecThisFu_1 | io_out_ready
  // 与另两个 FU 的 rdyVec_0 = ~validVecThisFu_1 | rdyVec_1 是同一条递推，不是另一种形状。
  //
  // ★ 注意：valid 流水**没有 ready 门控**（golden: `validVecThisFu_1 <= io_in_valid;`），
  //   而 §2 的 payload 寄存器有。看起来不自洽——若 io_out_ready 真的拉低，valid 会
  //   照常往前挪、payload 却被冻住，两者就错相了。为什么在当前连接下安全：
  //   ExuBlock_1 里装 FAlu 的三个口 exus(ExeUnit_8) / exus_2 / exus_4(ExeUnit_10)
  //   的 io_out_ready 都硬接 1'h1（只有装 FDivSqrt 的 exus_1/exus_3 是真信号），
  //   于是 rdy 恒 1，两种写法完全等价，这个不一致观测不到。
  //   本工程要求与 golden bug-for-bug 一致，所以照抄不加门控。
  logic vldThisFu_1;
  wire  rdy_0 = ~vldThisFu_1 | io_out_ready;

  assign io_in_ready = rdy_0;

  always @(posedge clock or posedge reset) begin
    if (reset)
      vldThisFu_1 <= 1'b0;
    else
      vldThisFu_1 <= io_in_valid;
  end

  // ===========================================================================
  //  §2 payload 搬运（perfDebugInfo + debug.seqNum），LAT=1 只有一级
  // ===========================================================================
  // 使能 = fire = valid && ready。这些寄存器**无复位**（纯调试 payload，复位后头几拍
  // 是 X，等第一次 fire 才有意义），与 golden 一致。
  perf_dbg_t perfVec;
  seq_num_t  seqNumVec;
  always @(posedge clock) begin
    if (rdy_0 & io_in_valid) begin
      perfVec   <= io_in_bits_perfDebugInfo;
      seqNumVec <= io_in_bits_debug_seqNum;
    end
  end

  // ===========================================================================
  //  §3 送进浮点加法器的 IEEE-754 控制位
  // ===========================================================================
  wire [2:0] round_mode   = selRoundMode(io_in_bits_ctrl_fpu_rm, io_frm);
  wire       fp_a_is_cnan = isFpCanonicalNAN(io_in_bits_ctrl_fpu_fmt, io_in_bits_data_src_0);
  wire       fp_b_is_cnan = isFpCanonicalNAN(io_in_bits_ctrl_fpu_fmt, io_in_bits_data_src_1);

  // FloatAdder（黑盒，fudian 库）：F64 与 F32/F16 混合两条流水**并行**跑，1 拍后按
  // fp_format 选一条的结果出来，连同 5 位异常标志 fflags{NV,DZ,OF,UF,NX}。
  //   · NaN 传播 / 非规格化处理 / 各舍入模式 / 比较类指令遇 sNaN 置 NV，全在它内部；
  //   · 窄结果的 NaN-box 也在它内部完成：它有一个 resultNeedBox 寄存器，对
  //     op_code ∈ {0,1,2,3,6,7,8,13h,1Eh}（即 fadd/fsub/fmin/fmax/fsgnj*/fmaxm/fminm，
  //     恰是结果为浮点的那几种）置 1，窄结果高位按它补全 1。所以本层不必像 FCVT
  //     那样自己包装结果——FAlu 的 io_out_bits_res_data 是加法器输出直连；
  //   · 它**不带 reset** —— 内部流水寄存器无复位，由 io_fire 门控，无效拍的垃圾不会被采信。
  FloatAdder falu (
    .clock                   (clock),
    .io_fire                 (io_in_valid),
    .io_fp_a                 (io_in_bits_data_src_0),
    .io_fp_b                 (io_in_bits_data_src_1),
    .io_round_mode           (round_mode),
    .io_fp_format            (io_in_bits_ctrl_fpu_fmt),
    .io_op_code              (io_in_bits_ctrl_fuOpType[4:0]),
    .io_fp_aIsFpCanonicalNAN (fp_a_is_cnan),
    .io_fp_bIsFpCanonicalNAN (fp_b_is_cnan),
    .io_fp_result            (io_out_bits_res_data),
    .io_fflags               (io_out_bits_res_fflags)
  );

  // ===========================================================================
  //  §4 写回
  // ===========================================================================
  // 写回有效 = 外部预打拍的 validPipe[1]（含冲刷）与本 FU 占位同时成立。
  assign io_out_valid              = io_in_bits_validPipe & vldThisFu_1;
  assign io_out_bits_ctrl          = io_in_bits_ctrlPipe;
  assign io_out_bits_perfDebugInfo = perfVec;
  assign io_out_bits_debug_seqNum  = seqNumVec;

endmodule

// =============================================================================
//  golden 同名层：端口与 firtool 输出逐位同名，例化可读核并把 struct 展平
// =============================================================================
module FAlu(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input  [1:0]  io_in_bits_ctrl_fpu_fmt,
  input  [2:0]  io_in_bits_ctrl_fpu_rm,
  input         io_in_bits_ctrlPipe_1_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_1_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_1_pdest,
  input         io_in_bits_ctrlPipe_1_rfWen,
  input         io_in_bits_ctrlPipe_1_fpWen,
  input         io_in_bits_ctrlPipe_1_fpu_wflags,
  input         io_in_bits_validPipe_1,
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

  falu_pkg::wb_ctrl_t   ctrl_in, ctrl_out;
  falu_pkg::perf_dbg_t  perf_in, perf_out;
  falu_pkg::seq_num_t   seq_in,  seq_out;

  always_comb begin
    ctrl_in.robIdx_flag  = io_in_bits_ctrlPipe_1_robIdx_flag;
    ctrl_in.robIdx_value = io_in_bits_ctrlPipe_1_robIdx_value;
    ctrl_in.pdest        = io_in_bits_ctrlPipe_1_pdest;
    ctrl_in.rfWen        = io_in_bits_ctrlPipe_1_rfWen;
    ctrl_in.fpWen        = io_in_bits_ctrlPipe_1_fpWen;
    ctrl_in.fpu_wflags   = io_in_bits_ctrlPipe_1_fpu_wflags;

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
  assign io_out_bits_ctrl_rfWen        = ctrl_out.rfWen;
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

  xs_FAlu_core u_core (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_ready               (io_in_ready),
    .io_in_valid               (io_in_valid),
    .io_in_bits_ctrl_fuOpType  (io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_fpu_fmt   (io_in_bits_ctrl_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm    (io_in_bits_ctrl_fpu_rm),
    .io_in_bits_ctrlPipe       (ctrl_in),
    .io_in_bits_validPipe      (io_in_bits_validPipe_1),
    .io_in_bits_data_src_0     (io_in_bits_data_src_0),
    .io_in_bits_data_src_1     (io_in_bits_data_src_1),
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
