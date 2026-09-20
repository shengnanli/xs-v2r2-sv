// =============================================================================
// FuBusyTableWrite.sv —— 发射队列「功能单元忙表」写侧：家族参数化核 + 本变体 wrapper
//
// 在哪一层：后端乱序发射队列（IssueQueue*）内部，与 FuBusyTableRead 成对。
//   一条出射通道上挂着若干功能单元，延迟各不相同。本模块用一个 W 位的移位寄存器
//   fuBusyTable 当「倒计时占用表」：槽 s 为 1 表示「再过 s+1 拍，这条通道上某个
//   延迟为 s 的功能单元要占用写回端口」。读侧（FuBusyTableRead）据此屏蔽条目。
//
// 核心机制（三件事，全部照抄 Chisel）：
//   1. 每拍整表右移一格 —— 槽 s+1 的忙位落到槽 s（倒计时减一）；最高位恒补 0。
//   2. 发射（deqResp）把新的占用**写进**槽 s：s 由这条指令的功能单元延迟决定，
//      即 deqResp.fuType 命中槽 s 的位掩码 SLOT_SEL[s]。
//   3. 取消（og0Resp / og1Resp）把已经登记的占用**清掉**：og0 级的回应对应的表项
//      此刻位于槽 s+1（下一拍才落到槽 s），所以在移位的同时清 s+1 的掩码；
//      og1 级晚一拍，清 s+2，且只在 og1Resp.resp==0 时才算取消。
//   由此得到一条恒等式，家族 15 个变体逐个实测都成立：
//      og0 的位掩码 == 把 deq 的槽掩码整体下移一格；og1 == 下移两格。
//   —— 所以**一个 SLOT_SEL 表就够了**，og0/og1 的掩码不是独立参数。
//
// ★golden 的不对称照抄★（两处，都由实测而非推理确定）：
//   · 最高位槽（第 W-1 位）在 golden 里**恒为 0**：右移补 0、deq 那一项也是常量 0。
//     它是 Chisel 侧 Vec(W) 顶端从不被写的那一格，firtool 保留了这根死线。照抄。
//   · **有没有 og1 端口不能由掩码推出来**：_68/_71/_80 三个变体的「下移两格」掩码
//     非零，却根本没有 og1Resp 端口（Chisel 侧该队列就没接 og1）。所以 HAS_OG1 是
//     独立参数，不是派生量。HAS_OG0 同理（_53/_79 无 og0 端口）。
//
// 家族差异（15 个变体只差 4 个维度）：槽数 NSLOT（1..4，表宽 W=NSLOT+1）、
//   SLOT_SEL 表、HAS_OG0、HAS_OG1。逐变体矩阵见
//   verif/ut/FuBusyTableWriteVariants/README.md；14 个薄 wrapper 由
//   scripts/gen_fubusy_wbarb.py 生成。
//
// 设计源：XiangShan src/main/scala/xiangshan/backend/issue/FuBusyTable.scala
// golden 对照：G1-canonical/golden-rtl/FuBusyTableWrite.sv（本文件的 wrapper 段）
// =============================================================================

// -----------------------------------------------------------------------------
// xs_FuBusyTableWrite_core —— 倒计时占用表（右移 + 按 fuType 置位 + 按级取消）
//
// SLOT_SEL 固定给 8 个槽的位置（家族实测最大 NSLOT=4），例化处只填前 NSLOT 个。
// 复位域：唯一的寄存器 fu_busy_table_q 是**异步高有效**复位到 0，与 golden 的
// `always @(posedge clock or posedge reset)` 逐字对应。
// -----------------------------------------------------------------------------
module xs_FuBusyTableWrite_core #(
  parameter int NSLOT = 2,                              // 真正在用的槽数；表宽 = NSLOT+1
  parameter bit HAS_OG0 = 1,                            // golden 本变体有无 og0Resp 端口
  parameter bit HAS_OG1 = 0,                            // golden 本变体有无 og1Resp 端口
  parameter logic [7:0][34:0] SLOT_SEL = '{default: '0} // 槽 s 认领的 fuType 位掩码
) (
  input  logic        clock,
  input  logic        reset,                 // 异步、高有效
  input  logic        deq_valid,
  input  logic [34:0] deq_fu_type,
  input  logic        og0_valid,
  input  logic [34:0] og0_fu_type,
  input  logic        og1_valid,
  input  logic [1:0]  og1_resp,
  input  logic [34:0] og1_fu_type,
  output logic [NSLOT:0] fu_busy_table
);
  // 槽号越界（s >= NSLOT）一律视作空集合 —— golden 里那些位置就是常量 0。
  function automatic logic slot_hit(input logic [34:0] fu_type, input int slot);
    slot_hit = (slot >= 0 && slot < NSLOT) ? |(fu_type & SLOT_SEL[slot]) : 1'b0;
  endfunction

  logic [NSLOT:0] fu_busy_table_q;
  logic [NSLOT:0] fu_busy_table_d;

  always_comb begin
    fu_busy_table_d = '0;                     // 最高位槽恒 0（见文件头）
    for (int s = 0; s < NSLOT; s++) begin
      logic shifted;                          // 槽 s+1 倒计时一拍后落到槽 s
      logic cancel_og0;                       // og0 级取消：命中的是槽 s+1
      logic cancel_og1;                       // og1 级取消：命中的是槽 s+2
      cancel_og0 = HAS_OG0 && og0_valid && slot_hit(og0_fu_type, s + 1);
      cancel_og1 = HAS_OG1 && og1_valid && (og1_resp == 2'd0)
                                        && slot_hit(og1_fu_type, s + 2);
      shifted = fu_busy_table_q[s + 1] & ~cancel_og0 & ~cancel_og1;
      // 本拍发射的指令按自己的延迟登记到槽 s
      fu_busy_table_d[s] = shifted | (deq_valid & slot_hit(deq_fu_type, s));
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) fu_busy_table_q <= '0;
    else       fu_busy_table_q <= fu_busy_table_d;
  end

  assign fu_busy_table = fu_busy_table_q;
endmodule

// -----------------------------------------------------------------------------
// FuBusyTableWrite —— 家族里最朴素的一个：W=3（NSLOT=2），有 og0、无 og1。
//   槽 1 认领 fuType[7]|fuType[10]（mul / bku，延迟 2 拍）；槽 0 为空。
//   例化者：IssueQueueAluMulBkuBrhJmp.sv
// -----------------------------------------------------------------------------
module FuBusyTableWrite(
  input         clock,
  input         reset,
  input         io_in_deqResp_valid,
  input  [34:0] io_in_deqResp_bits_fuType,
  input         io_in_og0Resp_valid,
  input  [34:0] io_in_og0Resp_bits_fuType,
  output [2:0]  io_out_fuBusyTable
);
  localparam int NSLOT = 2;
  localparam logic [7:0][34:0] SLOT_SEL = '{
    35'h0, 35'h0, 35'h0, 35'h0, 35'h0, 35'h0,   // 槽 7..2：本变体没有
    35'h480,                              // 槽 1：fuType[7] | fuType[10]
    35'h0};                                      // 槽 0：空

  xs_FuBusyTableWrite_core #(
    .NSLOT(NSLOT), .HAS_OG0(1'b1), .HAS_OG1(1'b0), .SLOT_SEL(SLOT_SEL)
  ) u_core (
    .clock         (clock),
    .reset         (reset),
    .deq_valid     (io_in_deqResp_valid),
    .deq_fu_type   (io_in_deqResp_bits_fuType),
    .og0_valid     (io_in_og0Resp_valid),
    .og0_fu_type   (io_in_og0Resp_bits_fuType),
    .og1_valid     (1'b0),                       // golden 本变体无 og1Resp 端口
    .og1_resp      (2'b0),
    .og1_fu_type   (35'b0),
    .fu_busy_table (io_out_fuBusyTable)
  );
endmodule
