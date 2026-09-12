// FCVT.sv —— 标量浮点「格式转换」功能单元（FpPipedFuncUnit, latency=2）
// -----------------------------------------------------------------------------
// 在后端的位置：浮点执行簇 ExeUnit_8(exus) 里的一个 FU（与 FAlu / FMA / IntFPToVec
//   共享写回端口）。覆盖 f2i(fcvt.w/l.*) / i2f(fcvt.*.w/l) / f2f 变宽变窄 /
//   fround / froundnx / fcvtmod.w.d / fmv.x.w|d 这一整族「换表示法」的指令。
// 真正的转换在 FPCVT（内部 2 拍流水，本文件按黑盒例化）。三个浮点 FU 里，FCVT 是
//   唯一在本层真的**译 fuOpType 并加工结果**的：
//     1) 舍入模式：f2i 类指令的舍入由 opType 直接指定（RTZ / ROD），不看 rm/frm；
//     2) 输出宽度 one-hot：由 {widen=opType[4:3], sew} 查真值表得 8/16/32/64bit，
//        并随 FPCVT 打 2 拍对齐到写回级（末级要用它决定怎么包装结果）；
//     3) fmv 旁路：fmv.x.w / fmv.x.d 只是「把浮点位型当整数搬走」，完全不进 FPCVT，
//        本层自己按 sew 符号扩展后打 2 拍旁路到写回级，并把 fflags 清零；
//     4) 结果包装：窄浮点结果要 NaN-box（高位补全 1），32bit 整数结果要符号扩展。
//
// 流水与握手（LAT=2）：
//   G1 相对 G0 的接口变更 —— 新增 io_in_ready(输出) / io_out_ready(输入) 与反压链
//   rdy[]；G0 这三个浮点 FU 一个 ready 端口都没有（定长流水恒可收），payload 寄存器
//   直接用 `if (io_in_valid)` 使能，G1 改成 fire = valid && ready。G0 那样写在当时是
//   正确的（无 ready ⇒ ready 恒 1），属接口变更的配套改动，不是补 bug。
//   G1 还把 perfDebugInfo 从 3 个字段扩到 10 个，并新增 debug.seqNum{seqNum,uopIdx}。
//   ★ 本模块里有三种不同的寄存器使能，全部照搬 golden，原因见 §1 / §4 / §5 的注释。
// =============================================================================
package fcvt_pkg;

  localparam int unsigned XLEN = 64;

  // 本 FU 的流水级数（FpPipedFuncUnit latency=2）：io.in 这拍进，2 拍后写回。
  localparam int unsigned LAT = 2;

  // ---------------------------------------------------------------------------
  // 元素宽度 sew（= 浮点格式 fp_fmt，香山复用 VSew 编码）
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    SEW_E8  = 2'b00,   // 8bit
    SEW_E16 = 2'b01,   // f16 / 16bit
    SEW_E32 = 2'b10,   // f32 / 32bit
    SEW_E64 = 2'b11    // f64 / 64bit
  } sew_e;

  // 输出宽度 one-hot 的位序（output1H）
  localparam int unsigned OW_8  = 0;
  localparam int unsigned OW_16 = 1;
  localparam int unsigned OW_32 = 2;
  localparam int unsigned OW_64 = 3;

  // ---------------------------------------------------------------------------
  // opType 编码（yunsuan.VfcvtType）：位段含义是 [7]=输入是浮点, [6]=输出是浮点,
  //                                   [5:3]=变宽档位(widen 占 [4:3]), [2:0]=舍入/有无符号
  // ---------------------------------------------------------------------------
  //   10_000000 vfcvt.xu.f.v      10_000001 vfcvt.x.f.v       （f2i，按 rm 舍入）
  //   01_000010 vfcvt.f.xu.v      01_000011 vfcvt.f.x.v       （i2f）
  //   10_000110 vfcvt.rtz.xu.f.v  10_000111 vfcvt.rtz.x.f.v   （f2i，[2:1]=11 ⇒ RTZ）
  //   10_001xxx vfwcvt.*          10_010xxx vfncvt.*          （变宽 / 变窄）
  //   11_001100 vfwcvt.f.f.v      11_010100 vfncvt.f.f.w      （f2f）
  //   11_010101 vfncvt.rod.f.f.w                              （[2:0]=101 ⇒ ROD）
  //   11_001000 fcvt.s.h  11_010000 fcvt.h.s  11_011000 fcvt.h.d / fcvt.d.h
  //   10_001000 fcvt.wu.h 10_001001 fcvt.w.h  10_011000 fcvt.lu.h 10_011001 fcvt.l.h
  // 下面四个是本层要单独识别的特例：
  localparam logic [8:0] OP_FROUND   = 9'h0C0;  // fround      : 取整，不置 NX
  localparam logic [8:0] OP_FROUNDNX = 9'h0C4;  // froundnx    : 取整，不精确时置 NX
  localparam logic [8:0] OP_FCVTMOD  = 9'h191;  // fcvtmod.w.d : 取模转换，强制 RTZ
  localparam logic [8:0] OP_FMVXF    = 9'h180;  // fmv.x.w / fmv.x.d : 纯位搬移
  // 另外 fuOpType==9'hFF 是「FU 不该收到这条指令」的哨兵值，golden 在非 SYNTHESIS 下
  // 对它有一条 `assert(false)`；SYNTHESIS 下该断言块被裁掉，所以本核里没有对应逻辑。

  // FPCVT 内部的舍入模式编码（与 fcsr.frm 同码，外加一个 ROD）
  localparam logic [2:0] RM_RTZ = 3'd1;   // 向零截断
  localparam logic [2:0] RM_ROD = 3'd6;   // round to odd（就近奇，两步转换防双舍入）

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

  // 写回端口上的控制信息（io.out.bits.ctrl），原样从 ctrlPipe 转发。
  typedef struct packed {
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic [7:0] pdest;
    logic       rfWen;          // f2i / fmv / fclass 这些结果是整数，写整数 RF
    logic       fpWen;          // i2f / f2f 结果是浮点，写浮点 RF
    logic       fpu_wflags;     // 是否更新 fcsr.fflags
  } wb_ctrl_t;

  // 发射级已按各 FU 的固定延迟预打好 ctrlPipe[0..LAT]，本 FU 取第 LAT 级那份。
  // FCVT 的这一份比写回端口多带一个 fuOpType：末级要靠它判 fmv 与「输出是浮点还是
  // 整数」（见核里的 §6），但 fuOpType 自己不往写回端口送。
  typedef struct packed {
    logic [8:0] fuOpType;
    wb_ctrl_t   wb;
  } ctrl_pipe_t;

  // ---------------------------------------------------------------------------
  // 舍入模式
  // ---------------------------------------------------------------------------
  // rm==7 是「动态舍入」，改用 fcsr.frm。
  function automatic logic [2:0] selRoundMode(input logic [2:0] inst_rm,
                                              input logic [2:0] csr_frm);
    selRoundMode = (inst_rm != 3'b111) ? inst_rm : csr_frm;
  endfunction

  // ---------------------------------------------------------------------------
  // 输出宽度 one-hot 真值表
  // ---------------------------------------------------------------------------
  // 输入 {widen, sew}，widen = fuOpType[4:3]：
  //   00 = single（同宽转换）/ 01 = widen（变宽一档）/ 10 = narrow（变窄一档）
  //   11 = f16 与 f64 直接互转的特例（跨两档）
  // 输出 4bit one-hot：bit0=8bit / bit1=16bit / bit2=32bit / bit3=64bit。
  // 未列组合在指令集里不存在，返回全 0（golden 的 decoder TruthTable 默认值同为 0）。
  // golden 把这张表展平成了一坨 AND/OR（output1H_invInputs …），逐项核对过 16 种
  // {widen,sew} 组合与本表完全一致。
  function automatic logic [3:0] decodeOutputWidth(input logic [1:0] widen,
                                                   input logic [1:0] sew);
    case ({widen, sew})
      4'b00_01: decodeOutputWidth = 4'b0010; // single : 16bit（vfcvt.*，sew=e16）
      4'b00_10: decodeOutputWidth = 4'b0100; // single : 32bit（vfcvt.*，sew=e32）
      4'b00_11: decodeOutputWidth = 4'b1000; // single : 64bit（vfcvt.*，sew=e64）
      4'b01_00: decodeOutputWidth = 4'b0010; // widen  :  8 -> 16（vfwcvt.*）
      4'b01_01: decodeOutputWidth = 4'b0100; // widen  : 16 -> 32（vfwcvt.*, fcvt.s.h）
      4'b01_10: decodeOutputWidth = 4'b1000; // widen  : 32 -> 64（vfwcvt.*）
      4'b10_00: decodeOutputWidth = 4'b0001; // narrow : 16 ->  8（vfncvt.*）
      4'b10_01: decodeOutputWidth = 4'b0010; // narrow : 32 -> 16（vfncvt.*, fcvt.h.s）
      4'b10_10: decodeOutputWidth = 4'b0100; // narrow : 64 -> 32（vfncvt.*）
      4'b11_01: decodeOutputWidth = 4'b1000; // 跨两档: f16 -> 64bit（fcvt.d.h/l.h/lu.h）
      4'b11_11: decodeOutputWidth = 4'b0010; // 跨两档: f64 -> 16bit（fcvt.h.d）
      default:  decodeOutputWidth = 4'b0000;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // fmv 的整数化：把源按 sew 取低段并符号扩展到 64bit
  // ---------------------------------------------------------------------------
  // fmv.x.w / fmv.x.d 不做任何数值运算，只是把 FPR 里的位型当整数读出；
  // RV 规定 fmv.x.w 的 32bit 结果要符号扩展进 64bit 整数寄存器。
  // golden 把这个 4 选 1 写成了「四个掩码相 OR」的 Mux1H 形式，与本 case 等价
  //（sew 只有 4 种取值，恰有一路命中）。
  function automatic logic [XLEN-1:0] fmvSignExtend(input logic [1:0]      sew,
                                                    input logic [XLEN-1:0] src);
    case (sew)
      SEW_E8:  fmvSignExtend = {{56{src[7]}},  src[7:0]};
      SEW_E16: fmvSignExtend = {{48{src[15]}}, src[15:0]};
      SEW_E32: fmvSignExtend = {{32{src[31]}}, src[31:0]};
      default: fmvSignExtend = src;                          // SEW_E64
    endcase
  endfunction

endpackage

// =============================================================================
//  可读核
// =============================================================================
module xs_FCVT_core
  import fcvt_pkg::*;
(
  input  logic            clock,
  input  logic            reset,

  // ---- io.in --------------------------------------------------------------
  output logic            io_in_ready,
  input  logic            io_in_valid,
  input  logic [8:0]      io_in_bits_ctrl_fuOpType,
  input  logic [1:0]      io_in_bits_ctrl_fpu_fmt,   // = sew
  input  logic [2:0]      io_in_bits_ctrl_fpu_rm,
  input  ctrl_pipe_t      io_in_bits_ctrlPipe,       // = golden ctrlPipe_2
  input  logic            io_in_bits_validPipe,      // = golden validPipe_2
  input  logic [XLEN-1:0] io_in_bits_data_src_0,     // 单源
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
  // vldThisFu[s] = 「s 拍前接了一个请求」。写回有效还要与外部 validPipe 相与。
  //
  // ★ 这条移位链没有 ready 门控（golden: `validVecThisFu_1 <= io_in_valid;`），而
  //   §4 的 payload 寄存器有。若 io_out_ready 真会拉低，valid 往前挪、payload 被冻住，
  //   两者就错相——看起来不自洽。为什么当前连接下安全：ExuBlock_1 里装 FCVT 的那个口
  //   exus(ExeUnit_8) 的 io_out_ready 硬接 1'h1（只有装 FDivSqrt 的 exus_1/exus_3
  //   是真信号），于是 rdy[] 全链恒 1，两种写法等价，不一致观测不到。
  //   本工程要求 bug-for-bug 一致，照抄不加门控。
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
  //  §2 opType 译码：舍入模式 / 输出宽度 / 特例指令
  // ===========================================================================
  wire isFround   = (io_in_bits_ctrl_fuOpType == OP_FROUND);
  wire isFroundnx = (io_in_bits_ctrl_fuOpType == OP_FROUNDNX);
  wire isFcvtmod  = (io_in_bits_ctrl_fuOpType == OP_FCVTMOD);

  // f2i 家族把舍入方式编进了 opType 低 3 位，不走 rm/frm：
  //   isRtz —— fcvt.w/l.* 按 RISC-V 规定一律向零截断；fcvtmod 也是 RTZ。
  //   isRod —— round to odd，用于「宽→窄两步转换」的中间步，避免双重舍入误差。
  // 两者互斥（isFcvtmod 的 opType[2]=0，所以不会同时命中 isRod）。
  wire isRtz = (io_in_bits_ctrl_fuOpType[2] &  io_in_bits_ctrl_fuOpType[1]) | isFcvtmod;
  wire isRod =  io_in_bits_ctrl_fuOpType[2] & ~io_in_bits_ctrl_fuOpType[1]
                                            &  io_in_bits_ctrl_fuOpType[0];

  // golden 把三路写成「掩码相 OR」的 Mux1H；因三者互斥，与这条优先级链等价。
  wire [2:0] cvt_rm = isRtz ? RM_RTZ
                    : isRod ? RM_ROD
                            : selRoundMode(io_in_bits_ctrl_fpu_rm, io_frm);

  // 输出宽度 one-hot（widen = opType[4:3]）
  wire [3:0] output1H = decodeOutputWidth(io_in_bits_ctrl_fuOpType[4:3],
                                          io_in_bits_ctrl_fpu_fmt);

  // ===========================================================================
  //  §3 FPCVT（黑盒，fudian 库）：内部 2 级流水
  // ===========================================================================
  // FPCVT 本体只是把 {opType[4:3], sew} 译成输入/输出宽度 one-hot，真正的转换在它
  // 例化的 CVT64 里（CLZ_6 前导零计数归一化 + ShiftRightJam 对阶右移带粘滞位 +
  // RoundingUnit_3/4 舍入 + FP_INCVT 整数侧通路），两级寄存器分别由 io_fire 与
  // fireReg_last_r 使能，结果在 io_fire 后第 2 拍稳定——对上本 FU 的 LAT=2。
  // IEEE-754 的特殊情形都在它内部：
  //   · 源是 NaN/Inf 时 f2i 要钉到整数极值并置 NV（不是溢出 OF）；
  //   · 非规格化源要先前导零归一化再转换；
  //   · f2f 变窄可能下溢成非规格化或零，置 UF|NX；
  //   · fround 只取整不置 NX，froundnx 不精确时置 NX。
  // 本层只负责把控制位算对，不重复它的判定。
  //
  // ★ 一个容易迷惑读者的重复：FPCVT 内部自己也算了一份与 §2 的 output1H 逐位相同的
  //   输出宽度 one-hot。这里还要再算一次，是因为 FPCVT 不把这个信息送出来，而本层
  //   末级（§6）需要用「输出是 16bit 还是 32bit」来决定结果怎么包装，所以得自己留一份
  //   并随流水打 2 拍对齐过去。
  logic [XLEN-1:0] cvt_result;
  logic [4:0]      cvt_fflags;
  FPCVT fcvt (
    .clock        (clock),
    .reset        (reset),
    .io_fire      (io_in_valid),
    .io_src       (io_in_bits_data_src_0),
    .io_opType    (io_in_bits_ctrl_fuOpType[7:0]),
    .io_sew       (io_in_bits_ctrl_fpu_fmt),
    .io_rm        (cvt_rm),
    .io_isFround  ({isFroundnx, isFround}),
    .io_isFcvtmod (isFcvtmod),
    .io_result    (cvt_result),
    .io_fflags    (cvt_fflags)
  );

  // ===========================================================================
  //  §4 payload 搬运（perfDebugInfo + debug.seqNum），LAT=2
  // ===========================================================================
  // 使能 = fire = valid && ready（第 1 级取模块输入，第 2 级取第 1 级）。
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
  //  §5 与 FPCVT 同步的两条本地流水
  // ===========================================================================
  // (a) 输出宽度标志：只有 16bit / 32bit 这两位会被末级用到，打 2 拍对齐到写回级。
  //     ★ 它们**完全没有使能**（golden 的 RegNext 无 enable），每拍无条件搬运。
  //       合理性：这两位只在「本拍确实有结果要写回」时才被 result 选择器用到，
  //       无效拍搬进来的垃圾不会被采信。同样照搬 golden。
  logic outIs16bits_s1, outIs16bits;
  logic outIs32bits_s1, outIs32bits;

  // (b) fmv 旁路：fmv.x.* 不进 FPCVT，本层自己符号扩展后打 2 拍送到写回级。
  //     ★ 这两级的使能是第三种写法：第 1 级用裸 io_in_valid（不带 ready），
  //       第 2 级用 fireReg_last_r（io_in_valid 的延迟版）。同样在 ready 恒 1 时
  //       与 fire 门控等价，照搬 golden。
  logic [XLEN-1:0] mvResult_s1, mvResult_s2;

  // fireReg_last_r：Chisel GatedValidRegNext —— 只在「本拍 fire 或上拍还是 1」时更新。
  // 效果等于 RegNext(io_in_valid)（本就是 0 时无需再写 0），这样写是为了让综合
  // 工具能给它挂时钟门控。X 行为与 RegNext 不同（保持 X 而非清 0），故照搬门控形式。
  logic fireReg_last;

  always @(posedge clock or posedge reset) begin
    if (reset)
      fireReg_last <= 1'b0;
    else if (io_in_valid | fireReg_last)
      fireReg_last <= io_in_valid;
  end

  always @(posedge clock) begin
    outIs16bits_s1 <= output1H[OW_16];
    outIs16bits    <= outIs16bits_s1;
    outIs32bits_s1 <= output1H[OW_32];
    outIs32bits    <= outIs32bits_s1;

    if (io_in_valid)
      mvResult_s1 <= fmvSignExtend(io_in_bits_ctrl_fpu_fmt, io_in_bits_data_src_0);
    if (fireReg_last)
      mvResult_s2 <= mvResult_s1;
  end

  // ===========================================================================
  //  §6 写回级结果包装
  // ===========================================================================
  // outIsFp：ctrlPipe[LAT].fuOpType[6] 表示「这条指令的结果是浮点」（i2f / f2f）；
  //          为 0 就是整数结果（f2i / fmv / fclass）。
  wire outIsFp     = io_in_bits_ctrlPipe.fuOpType[6];
  wire outIsMvInst = (io_in_bits_ctrlPipe.fuOpType == OP_FMVXF);

  // 第一步：选结果本体。
  //   · fmv        → 取旁路的整数化结果；
  //   · 32bit 浮点 → NaN-box：高 32 位补全 1（否则读回时会被当成非法 box）；
  //   · 16bit 浮点 → NaN-box：高 48 位补全 1；
  //   · 其余（64bit 浮点 / 各宽度整数）→ FPCVT 原始结果。
  // ★ 这里必须用条件表达式 ?: 而不是 always_comb 的 if/else：outIs32bits /
  //   outIs16bits 是无复位寄存器，复位后头两拍是 X。?: 对 X 选择做位级合并
  //   （两分支相同的位保留、不同的位出 X），if/else 则会径直走 else 分支——
  //   两者在 X 上不等价，逐拍比对会立刻打出差异。
  wire [XLEN-1:0] result = outIsMvInst                ? mvResult_s2
                         : (outIs32bits & outIsFp)    ? {32'hFFFF_FFFF,       cvt_result[31:0]}
                         : (outIs16bits & outIsFp)    ? {48'hFFFF_FFFF_FFFF,  cvt_result[15:0]}
                                                      : cvt_result;

  // 第二步：32bit **整数**结果要符号扩展回 64bit（fcvt.w.* / fcvtmod.w.d）。
  assign io_out_bits_res_data = (outIs32bits & ~outIsFp)
                                  ? {{32{result[31]}}, result[31:0]}
                                  : result;

  // fmv 只是搬位，不产生任何 IEEE-754 异常，fflags 清零。
  assign io_out_bits_res_fflags = outIsMvInst ? 5'h0 : cvt_fflags;

  // ===========================================================================
  //  §7 写回控制
  // ===========================================================================
  assign io_out_valid              = io_in_bits_validPipe & vldThisFu[LAT];
  assign io_out_bits_ctrl          = io_in_bits_ctrlPipe.wb;
  assign io_out_bits_perfDebugInfo = perfVec[LAT];
  assign io_out_bits_debug_seqNum  = seqNumVec[LAT];

endmodule

// =============================================================================
//  golden 同名层：端口与 firtool 输出逐位同名，例化可读核并把 struct 展平
// =============================================================================
module FCVT(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [8:0]  io_in_bits_ctrl_fuOpType,
  input  [1:0]  io_in_bits_ctrl_fpu_fmt,
  input  [2:0]  io_in_bits_ctrl_fpu_rm,
  input  [8:0]  io_in_bits_ctrlPipe_2_fuOpType,
  input         io_in_bits_ctrlPipe_2_robIdx_flag,
  input  [7:0]  io_in_bits_ctrlPipe_2_robIdx_value,
  input  [7:0]  io_in_bits_ctrlPipe_2_pdest,
  input         io_in_bits_ctrlPipe_2_rfWen,
  input         io_in_bits_ctrlPipe_2_fpWen,
  input         io_in_bits_ctrlPipe_2_fpu_wflags,
  input         io_in_bits_validPipe_2,
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

  fcvt_pkg::ctrl_pipe_t ctrl_in;
  fcvt_pkg::wb_ctrl_t   ctrl_out;
  fcvt_pkg::perf_dbg_t  perf_in, perf_out;
  fcvt_pkg::seq_num_t   seq_in,  seq_out;

  always_comb begin
    ctrl_in.fuOpType        = io_in_bits_ctrlPipe_2_fuOpType;
    ctrl_in.wb.robIdx_flag  = io_in_bits_ctrlPipe_2_robIdx_flag;
    ctrl_in.wb.robIdx_value = io_in_bits_ctrlPipe_2_robIdx_value;
    ctrl_in.wb.pdest        = io_in_bits_ctrlPipe_2_pdest;
    ctrl_in.wb.rfWen        = io_in_bits_ctrlPipe_2_rfWen;
    ctrl_in.wb.fpWen        = io_in_bits_ctrlPipe_2_fpWen;
    ctrl_in.wb.fpu_wflags   = io_in_bits_ctrlPipe_2_fpu_wflags;

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

  xs_FCVT_core u_core (
    .clock                     (clock),
    .reset                     (reset),
    .io_in_ready               (io_in_ready),
    .io_in_valid               (io_in_valid),
    .io_in_bits_ctrl_fuOpType  (io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_fpu_fmt   (io_in_bits_ctrl_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm    (io_in_bits_ctrl_fpu_rm),
    .io_in_bits_ctrlPipe       (ctrl_in),
    .io_in_bits_validPipe      (io_in_bits_validPipe_2),
    .io_in_bits_data_src_0     (io_in_bits_data_src_0),
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
