// =============================================================================
// Bku.sv —— Bit-manipulation & Krypto Unit（RISC-V Zb* 位操作 + Zk* 密码扩展）
//
// 在流水线里的位置：后端 ExuBlock 的一个整数执行单元，与 Alu / MulUnit 并列挂在
//   整数发射端口上。它接的是"需要专用数据通路、塞进普通 ALU 不划算"的那批指令；
//   普通 Zbb/Zbs 的 andn/orn/min/max/bset 之类仍然在 Alu 里，不在这里。
//
// 它算什么：四个子块并联，同一拍全部开算，末尾按 fuOpType(=func) 选一个结果。
//   func 的编码见 xiangshan/package.scala 的 object BKUOpType（本文件用到它的
//   bit5/bit3/bit2 做四选一，各子块内部再用低位细分）：
//     · CountModule  计数类     clz/clzw、ctz/ctzw、cpop/cpopw   (Zbb)  func=001xxx
//     · ClmulModule  无进位乘   clmul / clmulh / clmulr          (Zbc)  func=0000xx
//     · MiscModule   杂项位操作 xperm.n / xperm.b（半字节/字节查表置换）
//                                                               (Zbkx) func=0001xx
//     · CryptoModule 密码       分组密码（aes64es/esm/ds/dsm/im/ks1i/ks2、
//                               sm4ed*/sm4ks*，实现在 BlockCipherModule）+
//                               哈希（sha256/sha512 的 Σ/σ、sm3 的 P0/P1，
//                               实现在 HashModule）              (Zkn/Zks) func=1xxxxx
//   本轮重写的只是 Bku 这一层流水壳与四选一：四个子块的 RTL 与 G0 逐字相同，
//   因此仍然例化 golden 的 CountModule/ClmulModule/MiscModule/CryptoModule。
//
// 流水级数与握手：latency=2 的定长流水（Chisel FuncUnit + HasPipelineReg，
//   见 src/main/scala/xiangshan/backend/fu/FuncUnit.scala:166 与 Bku.scala:321）。
//     s0 收指令并拍下 func → s1 子块内部寄存器出结果、顶层四选一 → s2 输出寄存器。
//   G1 起对外有真握手：新增 io_in_ready / io_out_ready，反压链 rdy_s1→rdy_s0
//   从末级往前推（见核内"反压链"一节）。
//
// G1 相对 G0 的改动（运算部分一个字没动，全是流水壳的接口增量）：
//   + 新增 io_in_ready / io_out_ready 与 rdyVec 反压链；
//   + func / perf / seqNum / 输出数据寄存器一律改成 fire = valid & ready 门控
//     （G0 没有 ready 端口 ⇒ ready 恒 1 ⇒ 当时不写门控也是对的，不是 bug）；
//   + perfDebugInfo 从 3 个字段（enqRs/select/issue）扩到 10 个，
//     另加 debug.seqNum{seqNum[55:0], uopIdx[7:0]}。
// =============================================================================

package bku_pkg;

  // 目的数据位宽（RV64 → 64）
  localparam int XLEN = 64;

  // ---------------------------------------------------------------------------
  // 四选一用到的 func 位。BKUOpType 的编码空间保证这三位互不重叠：
  //   bit5=1 → 密码类(1xxxxx)；否则 bit3=1 → 计数类(001xxx)；
  //   否则 bit2=1 → xperm(0001xx)；否则 → clmul(0000xx)。
  // ---------------------------------------------------------------------------
  localparam int FUNC_CRYPTO_BIT = 5;
  localparam int FUNC_COUNT_BIT  = 3;
  localparam int FUNC_MISC_BIT   = 2;

  // ---------------------------------------------------------------------------
  // 随指令走的控制信息。注意这一份是**上游数据通路已经替本 FU 打好拍**的第 2 级
  // （io.in.bits.ctrlPipe(2)），本 FU 直接透传到输出，自己不再打拍。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic       robIdx_flag;
    logic [7:0] robIdx_value;
    logic [7:0] pdest;
    logic       rfWen;
  } bku_ctrl_t;

  // ---------------------------------------------------------------------------
  // perf 调试计时信息：不参与运算，只是随流水搬运，最后随写回一起交给性能计数。
  // G1 有 10 个字段（G0 只有 enqRs/select/issue 三个）——用 struct 打包的好处正在
  // 这里：golden 那边是 2×10 个扁平寄存器各自写一条门控赋值，本文件只有两处。
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic        eliminatedMove;          // 该 uop 是否被 rename 阶段消除的 move
    logic [63:0] renameTime;
    logic [63:0] dispatchTime;
    logic [63:0] enqRsTime;
    logic [63:0] selectTime;
    logic [63:0] issueTime;
    logic [63:0] writebackTime;
    logic [63:0] runahead_checkpoint_id;
    logic [63:0] tlbFirstReqTime;
    logic [63:0] tlbRespTime;
  } bku_perf_t;

  // 指令序号追踪（difftest / 波形定位用）
  typedef struct packed {
    logic [55:0] seqNum;
    logic [7:0]  uopIdx;
  } bku_seqnum_t;

endpackage


// =============================================================================
// xs_Bku_core —— 可读核：2 级定长流水壳 + 四个子块并联 + 四选一
// =============================================================================
module xs_Bku_core
  import bku_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  // ---- 输入侧（io.in）----
  input  logic        in_valid,
  output logic        in_ready,
  input  logic [8:0]  in_fuOpType,          // = func，四选一与各子块共用
  input  logic [63:0] in_src0,              // rs1
  input  logic [63:0] in_src1,              // rs2
  // 上游数据通路预先打好的逐级 valid / 第 2 级控制（本 FU 只消费，不产生）
  input  logic        in_validPipe0,
  input  logic        in_validPipe1,
  input  logic        in_validPipe2,
  input  bku_ctrl_t   in_ctrlPipe2,
  input  bku_perf_t   in_perf,
  input  bku_seqnum_t in_seqNum,

  // ---- 输出侧（io.out）----
  input  logic        out_ready,
  output logic        out_valid,
  output bku_ctrl_t   out_ctrl,
  output logic [XLEN-1:0] out_res_data,
  output bku_perf_t   out_perf,
  output bku_seqnum_t out_seqNum
);

  // ===========================================================================
  // 1. 本 FU 自己的 valid 移位链 validVecThisFu(1)/(2)
  // ---------------------------------------------------------------------------
  // 唯一带复位的寄存器（异步复位，与 golden 的 always @(posedge clock or posedge
  // reset) 一致）。
  //
  // ★ 这里有一处**看起来不自洽**的地方，照 golden 原样保留，读者务必注意：
  //   下面的 valid 链是**无条件**每拍左移的，没有 ready 门控；而同一条流水上的
  //   func / perf / 输出数据寄存器（第 3、4、5 节）都加了 ready 门控。
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
  //   rdy_s1 = 第 2 级能不能接新东西 = 第 2 级空着，或者下游这拍收走
  //   rdy_s0 = 第 1 级能不能接新东西 = 第 1 级空着，或者第 2 级这拍能接
  //   in_ready = rdy_s0
  // 即 Chisel 的 `rdyVec(i) := !validVec(i+1) || rdyVec(i+1)`，最末一项接
  // io.out.ready。注意判据用的是本 FU 自己的 valid 链（不含上游 validPipe）。
  // ===========================================================================
  logic rdy_s0, rdy_s1;
  assign rdy_s1   = ~valid_thisfu_2 | out_ready;
  assign rdy_s0   = ~valid_thisfu_1 | rdy_s1;
  assign in_ready = rdy_s0;

  // ===========================================================================
  // 3. 三种流水使能：同一条流水上有三个略有差别的 fire，不要混用
  // ---------------------------------------------------------------------------
  //   fire_s0   = in_valid & rdy_s0                        —— io.in.fire
  //               用于 func / perf(1) / seqNum(1)：这些属于"FU 自带流水寄存器"，
  //               判据只看本 FU 的握手，不看上游 validPipe。
  //   reg_en_s1 = validPipe0 & in_valid       & rdy_s0      —— regEnable(1)
  //               用于四个子块内部的中间寄存器：真正搬运数据，要求上游那一级
  //               也确实有效（validVec(i) = validPipe(i) & validVecThisFu(i)）。
  //   reg_en_s2 = validPipe1 & valid_thisfu_1 & rdy_s1      —— regEnable(2)
  //               用于顶层输出数据寄存器。
  //   perf_en_s2 = valid_thisfu_1 & rdy_s1                  —— perf/seqNum 第 2 级
  //               同样只看本 FU 的 valid 链（与 reg_en_s2 差一个 validPipe1）。
  // 这套差别来自 Chisel：perf/seqNum 走 pipelineReg() 内部的 validVec（本 FU 的），
  // 而 regEnable(i) 用的是外层 `validVec = validPipe zip validVecThisFu` 的与。
  // ===========================================================================
  logic fire_s0, reg_en_s1, reg_en_s2, perf_en_s2;
  assign fire_s0    = in_valid & rdy_s0;
  assign reg_en_s1  = in_validPipe0 & in_valid       & rdy_s0;
  assign reg_en_s2  = in_validPipe1 & valid_thisfu_1 & rdy_s1;
  assign perf_en_s2 =                 valid_thisfu_1 & rdy_s1;

  // ===========================================================================
  // 4. 四个子块并联（全部是 1 拍内部延迟，内部中间寄存器用 reg_en_s1 拍入）
  // ---------------------------------------------------------------------------
  // 四块同时开算，功耗上不划算但时序上最省：结果在 s1 就绪，选择只是一个 4 选 1。
  // 这四个模块与 G0 逐字相同、不是本轮重写目标，故直接例化 golden 实现。
  // ===========================================================================
  logic [XLEN-1:0] count_out, clmul_out, misc_out, crypto_out;

  CountModule countModule (
    .clock        (clock),
    .io_src       (in_src0),               // 计数类是单源指令，只用 rs1
    .io_func      (in_fuOpType),
    .io_regEnable (reg_en_s1),
    .io_out       (count_out)
  );

  ClmulModule clmulModule (
    .clock        (clock),
    .io_src_0     (in_src0),
    .io_src_1     (in_src1),
    .io_func      (in_fuOpType),
    .io_regEnable (reg_en_s1),
    .io_out       (clmul_out)
  );

  MiscModule miscModule (
    .clock        (clock),
    .io_src_0     (in_src0),
    .io_src_1     (in_src1),
    .io_func      (in_fuOpType),
    .io_regEnable (reg_en_s1),
    .io_out       (misc_out)
  );

  CryptoModule cryptoModule (
    .clock        (clock),
    .io_src_0     (in_src0),
    .io_src_1     (in_src1),
    .io_func      (in_fuOpType),
    .io_regEnable (reg_en_s1),
    .io_out       (crypto_out)
  );

  // ===========================================================================
  // 5. 四选一 + 输出数据寄存器
  // ---------------------------------------------------------------------------
  // func 在 s0 随 in.fire 拍入 func_s1，s1 用它选出本拍该取哪个子块的结果；
  // 选中的结果在 s2 拍入输出寄存器。
  // 写成条件表达式链（而不是 always_comb 的 if/else）是刻意的：仿真里 func_s1
  // 复位后首次写入之前是 X，if 遇到 X 会走 else 分支给出一个确定值，条件表达式
  // 则按位合并两臂、把 X 传下去——与 golden 的 Mux 链逐位一致。
  // ===========================================================================
  logic [8:0] func_s1;
  always_ff @(posedge clock) begin
    if (fire_s0) func_s1 <= in_fuOpType;
  end

  logic [XLEN-1:0] result_s1;
  assign result_s1 = func_s1[FUNC_CRYPTO_BIT] ? crypto_out
                   : func_s1[FUNC_COUNT_BIT]  ? count_out
                   : func_s1[FUNC_MISC_BIT]   ? misc_out
                   :                            clmul_out;

  logic [XLEN-1:0] res_data_s2;
  always_ff @(posedge clock) begin
    if (reg_en_s2) res_data_s2 <= result_s1;
  end

  // ===========================================================================
  // 6. perf / seqNum 随流水打两拍（不参与运算，纯搬运）
  // ---------------------------------------------------------------------------
  // 第 1 级使能 = in.fire；第 2 级使能 = 本 FU valid 链第 1 级 & rdy_s1。
  // 无复位（与 golden 一致：这些字段只在搬运时被覆盖，复位值无意义）。
  // ===========================================================================
  bku_perf_t   perf_s1, perf_s2;
  bku_seqnum_t seq_s1,  seq_s2;
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
  // 7. 输出组装
  // ---------------------------------------------------------------------------
  // out_valid = 上游第 2 级 valid & 本 FU 第 2 级 valid（validVec.last）。
  // 控制位直接取上游已打好拍的 ctrlPipe(2)，本 FU 不重复打拍。
  // ===========================================================================
  assign out_valid    = in_validPipe2 & valid_thisfu_2;
  assign out_ctrl     = in_ctrlPipe2;
  assign out_res_data = res_data_s2;
  assign out_perf     = perf_s2;
  assign out_seqNum   = seq_s2;

endmodule


// =============================================================================
// Bku —— golden 同名壳：把扁平端口打包成 struct 交给可读核，本身不含逻辑
// =============================================================================
module Bku(
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

  // 打包：结构体字段顺序即 bku_pkg 里的声明顺序
  bku_pkg::bku_ctrl_t   in_ctrl_pipe2;
  bku_pkg::bku_perf_t   in_perf;
  bku_pkg::bku_seqnum_t in_seq_num;
  bku_pkg::bku_ctrl_t   out_ctrl;
  bku_pkg::bku_perf_t   out_perf;
  bku_pkg::bku_seqnum_t out_seq_num;

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

  xs_Bku_core u_core (
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
