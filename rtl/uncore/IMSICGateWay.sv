// =============================================================================
//  IMSIC 类型/常量包 (imsic_pkg)
// -----------------------------------------------------------------------------
//  IMSIC (Incoming MSI Controller) 是 RISC-V AIA 架构里接收 MSI(消息中断)的
//  核内中断文件控制器。本包目前服务于 IMSICGateWay —— IMSIC 的 MSI 入口握手块。
//
//  IMSICGateWay 语义 (源自 ChiselAIA src/main/scala/IMSIC.scala, class IMSICGateWay)：
//    上游 (AXIRegIMSIC) 通过 msiio 总线投递一条 MSI：
//      msiio_vld_req       : 请求有效 (异步，先经 3 级同步器打入本时钟域)
//      msiio_data[11:0]    : MSI 信息 = {目标中断文件号[11:8], 中断源号[7:0]}
//      msiio_vld_ack       : 回给上游的握手应答 (= 同步后请求打一拍)
//    本块在"同步后请求"的上升沿 (req & ~ack) 锁存：
//      msi_data_catch      : 锁存中断源号 msiio_data[7:0]
//      msi_intf_valids     : 把目标文件号 one-hot 展开 (1<<msiio_data[11:8])，
//                            取低 intFilesNum(=9) 位，作为各中断文件的写选通脉冲
//    非上升沿拍 msi_intf_valids 清 0 (单拍脉冲)。
//
//  ---------------------------------------------------------------------------
//  ★ 本实例参数的来龙去脉 (G0 -> G1 这一轮改的就是它) ★
//  参数链条 (ChiselAIA src/main/scala/IMSIC.scala:146/159/160)：
//      intFilesNum      = 2 + geilen                       // m, s, vs0..vs<geilen-1>
//      INTP_FILE_WIDTH  = log2Ceil(intFilesNum)
//      MSI_INFO_WIDTH   = imsicIntSrcWidth + INTP_FILE_WIDTH
//  geilen 来自 XiangShan src/main/scala/system/SoC.scala 的 IMSICParams：
//      G0 (旧基线)  geilen = 5 → intFilesNum = 7 → INTP_FILE_WIDTH = 3 → MSI_INFO = 11
//      G1 (本基线)  geilen = 7 → intFilesNum = 9 → INTP_FILE_WIDTH = 4 → MSI_INFO = 12
//  改动落在 XiangShan commit 10746d6aa "feat(SoC): update imsic default parameter
//  (#5258)"。所以 G0->G1 的位宽变化**不是简单加宽**，是 geilen 这个源头参数变了，
//  一路推出三个端口宽度 (msiio_data 11→12、msi_valid_o 7→9、one-hot 移位 8→16 位)。
//
//  另一处 G0->G1 差异：msiio_vld_ack 这个输出。Chisel 里它一直存在
//  (IMSIC.scala:191 `msiio.vld_ack := msi_vld_ack_cpu`)，但 G0 里整条链上没有任何
//  消费者，firtool DCE 把端口一路删到顶层，于是 G0 golden 里看不到它；G1 里它被
//  接到 CSR 的 io_csrio_msiAck (golden CSR.sv:1612)，端口就活下来了。
//  ⇒ 这是**端口回归**，不是新功能：逻辑一行没变，只是不再被 DCE 掉。
//
//  本实例参数 (对照 golden IMSICGateWay.sv 端口，逐个可机器核对)：
//    imsicIntSrcWidth = 8   (msi_data_o 位宽 / 中断源号，msiio_data[7:0])
//    intFilesNum      = 9   (msi_valid_o 位宽 = 中断文件数 m/s/vs0..vs6)
//    INTP_FILE_WIDTH  = 4   (文件号位宽，msiio_data[11:8])
//    MSI_INFO_WIDTH   = 12  (msiio_data 总位宽 = 8 + 4)
//    one-hot 移位宽度 = 16  (golden 的 `wire [15:0] _msi_intf_valids_T_1`)
//
//  子模块：MSI 请求经一条 3 级异步复位同步链 (AsyncResetSynchronizerShiftReg_
//  w1_d3_i0) 进入本时钟域，本核按名例化该链。该链不是厂商宏也不是独立签核目标，
//  UT 与 FM 两侧都编入 G1 golden 的同一份定义（非黑盒），链内 3 级 DFF 白盒受验。
// =============================================================================
package imsic_pkg;
  // ---- 源头参数：XiangShan SoC.scala IMSICParams (G1 值) ----
  localparam int IMSIC_GEILEN         = 7;   // guest external interrupt 数 (G0 是 5)
  localparam int IMSIC_INT_SRC_WIDTH  = 8;   // imsicIntSrcWidth: 中断源号位宽

  // ---- 由源头参数机械推出 (ChiselAIA IMSIC.scala:146/159/160) ----
  localparam int IMSIC_INT_FILES_NUM  = 2 + IMSIC_GEILEN;             // = 9
  localparam int IMSIC_INTP_FILE_WIDTH = $clog2(IMSIC_INT_FILES_NUM); // = 4
  localparam int IMSIC_MSI_INFO_WIDTH =
      IMSIC_INT_SRC_WIDTH + IMSIC_INTP_FILE_WIDTH;                    // = 12

  // ---- 文件号在 msiio_data 里的位置 ----
  localparam int IMSIC_FILE_SEL_LSB   = IMSIC_INT_SRC_WIDTH;          // = 8
  localparam int IMSIC_FILE_SEL_MSB   = IMSIC_MSI_INFO_WIDTH - 1;     // = 11

  // ---------------------------------------------------------------------------
  //  ★ 下面三个是**从 G1 golden 现读的机器可查常量**（不是从上面推出来的）★
  //  它们是核里宽度等式自检的右手边：把"参数写回 G0 旧值"这类静默错误钉成
  //  elaborate 期 $fatal，而不是等 FM 才炸。改这三个必须回 golden 重新量。
  //    golden IMSICGateWay.sv:91  `input  [11:0] msiio_data`         → 12
  //    golden IMSICGateWay.sv:94  `output [8:0]  msi_valid_o`        → 9
  //    golden IMSICGateWay.sv:102 `wire [15:0] _msi_intf_valids_T_1` → 16
  //  第三个是 Chisel `1.U << shamt` 的结果宽度 = 2**shamt_w，等价于"文件号字段
  //  有几位"的独立佐证：INTP_FILE_WIDTH 少写一位就同时违反它和 MSI_INFO 等式。
  // ---------------------------------------------------------------------------
  localparam int IMSIC_GOLDEN_MSI_INFO_W  = 12;
  localparam int IMSIC_GOLDEN_INT_FILES_N = 9;
  localparam int IMSIC_ONEHOT_SHIFT_W     = 16;
endpackage

// =============================================================================
//  IMSICGateWay —— IMSIC 的 MSI 入口握手块 (可读重写核 xs_IMSICGateWay_core)
// -----------------------------------------------------------------------------
//  功能 (源自 ChiselAIA src/main/scala/IMSIC.scala，class IMSICGateWay)：
//    接收上游投递的一条 MSI(消息中断)，在请求上升沿锁存中断源号、并把目标中断
//    文件号 one-hot 展开成单拍写选通；同时回一个 vld_ack 给上游。详见 imsic_pkg。
//
//  数据通路：
//    1) 请求 msiio_vld_req 异步进入，先过 3 级异步复位同步链 → req_synced；
//    2) msi_vld_ack_cpu 寄存器跟随 req_synced(打一拍)，既是回给上游的 vld_ack，
//       也与 req_synced 相与求上升沿：vld_rise = req_synced & ~msi_vld_ack_cpu；
//    3) 上升沿拍：msi_data_catch <= msiio_data[7:0]（锁存源号）；
//                 msi_intf_valids <= (1<<msiio_data[11:8]) 的低 9 位（one-hot 选通）；
//       非上升沿拍：msi_intf_valids <= 0（单拍脉冲，源号保持）。
//    文件号 >= intFilesNum(9) 时 one-hot 落在 16 位移位结果的高 7 位上，被低 9 位
//    截断成全 0 —— 即"非法文件号 ⇒ 没有任何中断文件被选通"，与 golden 逐位一致。
//
//  与 golden 对照：msi_vld_ack_cpu/msi_data_catch/msi_intf_valids 三个寄存器
//  语义、复位值、时序逐一对应；one-hot 展开取 16 位左移结果的低 9 位。
//  3 级同步链按名例化 golden 子模块 AsyncResetSynchronizerShiftReg_w1_d3_i0
//  (UT 与 FM 两侧同源编入 golden 定义，非黑盒)。
// =============================================================================

module xs_IMSICGateWay_core
  import imsic_pkg::*;
#(
  // ---- 源头参数 (默认 = imsic_pkg 的 G1 值)；参数化只为让负测能传错值进来 ----
  parameter int GEILEN          = IMSIC_GEILEN,          // guest external interrupt 数
  parameter int INT_SRC_WIDTH   = IMSIC_INT_SRC_WIDTH,   // 中断源号位宽
  // ---- golden 现读常量 (自检等式右手边)；负测靠只改上面源头参数、不改这三个 ----
  parameter int ONEHOT_SHIFT_W   = IMSIC_ONEHOT_SHIFT_W,   // golden 侧 [15:0] 移位临时线
  parameter int GOLDEN_MSI_INFO_W  = IMSIC_GOLDEN_MSI_INFO_W,  // golden msiio_data 宽
  parameter int GOLDEN_INT_FILES_N = IMSIC_GOLDEN_INT_FILES_N, // golden msi_valid_o 宽

  // ---- 由源头参数机械推出 (ChiselAIA IMSIC.scala:146/159/160) ----
  localparam int INT_FILES_NUM   = 2 + GEILEN,
  localparam int INTP_FILE_WIDTH = $clog2(INT_FILES_NUM),
  localparam int MSI_INFO_WIDTH  = INT_SRC_WIDTH + INTP_FILE_WIDTH,
  localparam int FILE_SEL_LSB    = INT_SRC_WIDTH,
  localparam int FILE_SEL_MSB    = MSI_INFO_WIDTH - 1
)(
  input  logic                      clock,
  input  logic                      reset,

  // 上游 MSI 投递总线
  input  logic                      msiio_vld_req,  // 请求有效 (异步)
  input  logic [MSI_INFO_WIDTH-1:0] msiio_data,     // {文件号[11:8], 源号[7:0]}
  output logic                      msiio_vld_ack,  // 握手应答 (同步后请求打一拍)

  // 输出
  output logic [INT_SRC_WIDTH-1:0]  msi_data_o,     // 锁存的中断源号
  output logic [INT_FILES_NUM-1:0]  msi_valid_o     // 各中断文件单拍写选通
);

  // ===========================================================================
  //  宽度等式自检 —— 把"位宽写错但逻辑全对"变成 elaborate 期硬失败
  // ---------------------------------------------------------------------------
  //  本轮 G0->G1 的实质改动只有 geilen 5→7，逻辑一行都不会错，随机激励也未必打得
  //  到 msiio_data[11] / msi_valid_o[8]（UT 照样 errors=0），只有 FM 才炸。下面三条
  //  等式的右手边全是**从 golden 现读的机器可查常量**，参数写回旧值立刻 $fatal：
  //    · msiio_data 端口宽度  12  ⇒ MSI_INFO_WIDTH == SRC_W + INTP_FILE_W
  //    · msi_valid_o 端口宽度  9  ⇒ INT_FILES_NUM == 2 + geilen 且 == 端口宽度
  //    · golden `wire [15:0] _msi_intf_valids_T_1` ⇒ ONEHOT_SHIFT_W == 2**INTP_FILE_W
  //  第三条最关键：它把"文件号字段有几位"和"移位结果有多宽"钉死成一个等式，
  //  INTP_FILE_WIDTH 少写一位就同时违反第一条和第三条。
  //  负测见 verif/ut/IMSICGateWay/negtest_width.sv（故意传错参数，必须 $fatal）。
  // ===========================================================================
  initial begin
    if (ONEHOT_SHIFT_W != (1 << INTP_FILE_WIDTH))
      $fatal(1, "xs_IMSICGateWay_core: golden one-hot 移位宽度 %0d != 2**INTP_FILE_WIDTH(%0d) —— geilen 写错了",
             ONEHOT_SHIFT_W, 1 << INTP_FILE_WIDTH);
    if (MSI_INFO_WIDTH != GOLDEN_MSI_INFO_W)
      $fatal(1, "xs_IMSICGateWay_core: SRC(%0d)+FILE_SEL(%0d)=%0d != golden msiio_data 宽度 %0d",
             INT_SRC_WIDTH, INTP_FILE_WIDTH, MSI_INFO_WIDTH, GOLDEN_MSI_INFO_W);
    if (INT_FILES_NUM != GOLDEN_INT_FILES_N)
      $fatal(1, "xs_IMSICGateWay_core: 2+geilen(%0d)=%0d != golden msi_valid_o 宽度 %0d",
             GEILEN, INT_FILES_NUM, GOLDEN_INT_FILES_N);
    if (INT_FILES_NUM > ONEHOT_SHIFT_W)
      $fatal(1, "xs_IMSICGateWay_core: INT_FILES_NUM=%0d 超出 one-hot 移位结果 %0d 位",
             INT_FILES_NUM, ONEHOT_SHIFT_W);
  end

  // ===========================================================================
  //  3 级异步复位同步链 (跨时钟域)：按名例化 golden 子模块 (两侧同源 elaborate,
  //  非黑盒 —— 见 verif/ut/IMSICGateWay/Makefile 的消黑盒说明)
  // ===========================================================================
  logic req_synced;  // golden: _msi_vld_req_cpu_chain_io_q
  AsyncResetSynchronizerShiftReg_w1_d3_i0 msi_vld_req_cpu_chain (
    .clock (clock),
    .reset (reset),
    .io_d  (msiio_vld_req),
    .io_q  (req_synced)
  );

  // ===========================================================================
  //  状态寄存器
  // ===========================================================================
  logic                            msi_vld_ack_cpu;  // 同步后请求打一拍 (沿检测 + 回 ack)
  logic [INT_SRC_WIDTH-1:0]  msi_data_catch;   // 锁存的中断源号
  logic [INT_FILES_NUM-1:0]  msi_intf_valids;  // one-hot 写选通脉冲

  // 同步后请求的上升沿：本拍高、上一拍 ack 低
  wire vld_rise = req_synced & ~msi_vld_ack_cpu;

  // 目标文件号 one-hot 展开：1 左移 msiio_data[11:8]，结果按 Chisel 语义占
  // 2**INTP_FILE_WIDTH = 16 位 (golden 的 _msi_intf_valids_T_1)，再取低 9 位。
  wire [ONEHOT_SHIFT_W-1:0] onehot_full =
    ONEHOT_SHIFT_W'(1'b1) << msiio_data[FILE_SEL_MSB:FILE_SEL_LSB];

  // ===========================================================================
  //  时序 (异步复位，与 golden posedge reset 一致)
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      msi_vld_ack_cpu <= 1'b0;
      msi_data_catch  <= '0;
      msi_intf_valids <= '0;
    end else begin
      msi_vld_ack_cpu <= req_synced;                  // 跟随同步后请求
      if (vld_rise)
        msi_data_catch <= msiio_data[INT_SRC_WIDTH-1:0];
      // 上升沿拍输出 one-hot 选通，否则清 0 (单拍脉冲)
      msi_intf_valids <= vld_rise ? onehot_full[INT_FILES_NUM-1:0]
                                  : {INT_FILES_NUM{1'b0}};
    end
  end

  // ===========================================================================
  //  输出
  // ===========================================================================
  assign msiio_vld_ack = msi_vld_ack_cpu;
  assign msi_data_o    = msi_data_catch;
  assign msi_valid_o   = msi_intf_valids;

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper —— 端口名/方向/位宽/顺序与 G1 golden IMSICGateWay 逐位一致
// ---------------------------------------------------------------------------

module IMSICGateWay(
  input clock,
  input reset,
  input msiio_vld_req,
  input [11:0] msiio_data,
  output msiio_vld_ack,
  output [7:0] msi_data_o,
  output [8:0] msi_valid_o
);
  xs_IMSICGateWay_core u_core (
    .clock(clock),
    .reset(reset),
    .msiio_vld_req(msiio_vld_req),
    .msiio_data(msiio_data),
    .msiio_vld_ack(msiio_vld_ack),
    .msi_data_o(msi_data_o),
    .msi_valid_o(msi_valid_o)
  );
endmodule
