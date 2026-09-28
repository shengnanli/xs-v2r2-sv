// FastArbiter_2.sv —— L2 RequestBuffer 的 issueArb：4 个缓冲表项里挑一个送进 chosenQ
//
// 实例：RequestBuffer.issueArb（utility.FastArbiter(ReqEntry, 4)）。逻辑全在共享核
// rtl/common/xs_FastArbiter_core.sv（带"挂起记忆"的轮转仲裁，机制讲在那里）。与同族其它变体
// （FastArbiter_3..7 等，scripts/gen_fastarbiter_l2.py 生成）相比，这个单态化有两处不同：
//   * 没有 io_in_<k>_ready 端口（RequestBuffer 不看每路 ready，firtool 删了）；
//   * 多一个 io_chosen 输出 = 赢家下标（OHToUInt(chosenOH)）。
// 核不导出 chosenOH，这里用"载荷里捎带独热标识"取回它：第 k 路的载荷低 N 位喂常量 1<<k，
// 核按 Mux1H（按位或）选载荷，于是输出的低 N 位恰好就是 chosenOH（无人 valid 时全 0）。
// 这样不必为一个变体改动已签核的共享核。
// 载荷字段（143 位，高位在前）：valid rdy task_channel task_set task_tag task_off task_alias task_vaddr task_isKeyword task_opcode task_param task_size task_sourceId task_corrupt task_fromL2pft task_needHint task_reqSource waitMP waitMS

module FastArbiter_2 (
  input  logic clock,
  input  logic reset,
  input  logic io_in_0_valid,
  input  logic io_in_0_bits_valid,
  input  logic io_in_0_bits_rdy,
  input  logic [2:0] io_in_0_bits_task_channel,
  input  logic [8:0] io_in_0_bits_task_set,
  input  logic [30:0] io_in_0_bits_task_tag,
  input  logic [5:0] io_in_0_bits_task_off,
  input  logic [1:0] io_in_0_bits_task_alias,
  input  logic [43:0] io_in_0_bits_task_vaddr,
  input  logic io_in_0_bits_task_isKeyword,
  input  logic [3:0] io_in_0_bits_task_opcode,
  input  logic [2:0] io_in_0_bits_task_param,
  input  logic [2:0] io_in_0_bits_task_size,
  input  logic [6:0] io_in_0_bits_task_sourceId,
  input  logic io_in_0_bits_task_corrupt,
  input  logic io_in_0_bits_task_fromL2pft,
  input  logic io_in_0_bits_task_needHint,
  input  logic [4:0] io_in_0_bits_task_reqSource,
  input  logic [3:0] io_in_0_bits_waitMP,
  input  logic [15:0] io_in_0_bits_waitMS,
  input  logic io_in_1_valid,
  input  logic io_in_1_bits_valid,
  input  logic io_in_1_bits_rdy,
  input  logic [2:0] io_in_1_bits_task_channel,
  input  logic [8:0] io_in_1_bits_task_set,
  input  logic [30:0] io_in_1_bits_task_tag,
  input  logic [5:0] io_in_1_bits_task_off,
  input  logic [1:0] io_in_1_bits_task_alias,
  input  logic [43:0] io_in_1_bits_task_vaddr,
  input  logic io_in_1_bits_task_isKeyword,
  input  logic [3:0] io_in_1_bits_task_opcode,
  input  logic [2:0] io_in_1_bits_task_param,
  input  logic [2:0] io_in_1_bits_task_size,
  input  logic [6:0] io_in_1_bits_task_sourceId,
  input  logic io_in_1_bits_task_corrupt,
  input  logic io_in_1_bits_task_fromL2pft,
  input  logic io_in_1_bits_task_needHint,
  input  logic [4:0] io_in_1_bits_task_reqSource,
  input  logic [3:0] io_in_1_bits_waitMP,
  input  logic [15:0] io_in_1_bits_waitMS,
  input  logic io_in_2_valid,
  input  logic io_in_2_bits_valid,
  input  logic io_in_2_bits_rdy,
  input  logic [2:0] io_in_2_bits_task_channel,
  input  logic [8:0] io_in_2_bits_task_set,
  input  logic [30:0] io_in_2_bits_task_tag,
  input  logic [5:0] io_in_2_bits_task_off,
  input  logic [1:0] io_in_2_bits_task_alias,
  input  logic [43:0] io_in_2_bits_task_vaddr,
  input  logic io_in_2_bits_task_isKeyword,
  input  logic [3:0] io_in_2_bits_task_opcode,
  input  logic [2:0] io_in_2_bits_task_param,
  input  logic [2:0] io_in_2_bits_task_size,
  input  logic [6:0] io_in_2_bits_task_sourceId,
  input  logic io_in_2_bits_task_corrupt,
  input  logic io_in_2_bits_task_fromL2pft,
  input  logic io_in_2_bits_task_needHint,
  input  logic [4:0] io_in_2_bits_task_reqSource,
  input  logic [3:0] io_in_2_bits_waitMP,
  input  logic [15:0] io_in_2_bits_waitMS,
  input  logic io_in_3_valid,
  input  logic io_in_3_bits_valid,
  input  logic io_in_3_bits_rdy,
  input  logic [2:0] io_in_3_bits_task_channel,
  input  logic [8:0] io_in_3_bits_task_set,
  input  logic [30:0] io_in_3_bits_task_tag,
  input  logic [5:0] io_in_3_bits_task_off,
  input  logic [1:0] io_in_3_bits_task_alias,
  input  logic [43:0] io_in_3_bits_task_vaddr,
  input  logic io_in_3_bits_task_isKeyword,
  input  logic [3:0] io_in_3_bits_task_opcode,
  input  logic [2:0] io_in_3_bits_task_param,
  input  logic [2:0] io_in_3_bits_task_size,
  input  logic [6:0] io_in_3_bits_task_sourceId,
  input  logic io_in_3_bits_task_corrupt,
  input  logic io_in_3_bits_task_fromL2pft,
  input  logic io_in_3_bits_task_needHint,
  input  logic [4:0] io_in_3_bits_task_reqSource,
  input  logic [3:0] io_in_3_bits_waitMP,
  input  logic [15:0] io_in_3_bits_waitMS,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic io_out_bits_valid,
  output logic io_out_bits_rdy,
  output logic [2:0] io_out_bits_task_channel,
  output logic [8:0] io_out_bits_task_set,
  output logic [30:0] io_out_bits_task_tag,
  output logic [5:0] io_out_bits_task_off,
  output logic [1:0] io_out_bits_task_alias,
  output logic [43:0] io_out_bits_task_vaddr,
  output logic io_out_bits_task_isKeyword,
  output logic [3:0] io_out_bits_task_opcode,
  output logic [2:0] io_out_bits_task_param,
  output logic [2:0] io_out_bits_task_size,
  output logic [6:0] io_out_bits_task_sourceId,
  output logic io_out_bits_task_corrupt,
  output logic io_out_bits_task_fromL2pft,
  output logic io_out_bits_task_needHint,
  output logic [4:0] io_out_bits_task_reqSource,
  output logic [3:0] io_out_bits_waitMP,
  output logic [15:0] io_out_bits_waitMS,
  output logic [1:0] io_chosen

);

  localparam int unsigned N  = 4;
  localparam int unsigned PW = 143;   // ReqEntry 载荷位宽

  logic [N-1:0]           in_valid;
  logic [N-1:0][PW+N-1:0] in_bits;     // {载荷, 独热标识}
  logic [PW+N-1:0]        out_bits;
  logic [N-1:0]           chosenOH;

  assign in_valid = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign in_bits[0] = {
    io_in_0_bits_valid,
    io_in_0_bits_rdy,
    io_in_0_bits_task_channel,
    io_in_0_bits_task_set,
    io_in_0_bits_task_tag,
    io_in_0_bits_task_off,
    io_in_0_bits_task_alias,
    io_in_0_bits_task_vaddr,
    io_in_0_bits_task_isKeyword,
    io_in_0_bits_task_opcode,
    io_in_0_bits_task_param,
    io_in_0_bits_task_size,
    io_in_0_bits_task_sourceId,
    io_in_0_bits_task_corrupt,
    io_in_0_bits_task_fromL2pft,
    io_in_0_bits_task_needHint,
    io_in_0_bits_task_reqSource,
    io_in_0_bits_waitMP,
    io_in_0_bits_waitMS,
    N'(1)   // 独热标识：第 0 路
  };
  assign in_bits[1] = {
    io_in_1_bits_valid,
    io_in_1_bits_rdy,
    io_in_1_bits_task_channel,
    io_in_1_bits_task_set,
    io_in_1_bits_task_tag,
    io_in_1_bits_task_off,
    io_in_1_bits_task_alias,
    io_in_1_bits_task_vaddr,
    io_in_1_bits_task_isKeyword,
    io_in_1_bits_task_opcode,
    io_in_1_bits_task_param,
    io_in_1_bits_task_size,
    io_in_1_bits_task_sourceId,
    io_in_1_bits_task_corrupt,
    io_in_1_bits_task_fromL2pft,
    io_in_1_bits_task_needHint,
    io_in_1_bits_task_reqSource,
    io_in_1_bits_waitMP,
    io_in_1_bits_waitMS,
    N'(2)   // 独热标识：第 1 路
  };
  assign in_bits[2] = {
    io_in_2_bits_valid,
    io_in_2_bits_rdy,
    io_in_2_bits_task_channel,
    io_in_2_bits_task_set,
    io_in_2_bits_task_tag,
    io_in_2_bits_task_off,
    io_in_2_bits_task_alias,
    io_in_2_bits_task_vaddr,
    io_in_2_bits_task_isKeyword,
    io_in_2_bits_task_opcode,
    io_in_2_bits_task_param,
    io_in_2_bits_task_size,
    io_in_2_bits_task_sourceId,
    io_in_2_bits_task_corrupt,
    io_in_2_bits_task_fromL2pft,
    io_in_2_bits_task_needHint,
    io_in_2_bits_task_reqSource,
    io_in_2_bits_waitMP,
    io_in_2_bits_waitMS,
    N'(4)   // 独热标识：第 2 路
  };
  assign in_bits[3] = {
    io_in_3_bits_valid,
    io_in_3_bits_rdy,
    io_in_3_bits_task_channel,
    io_in_3_bits_task_set,
    io_in_3_bits_task_tag,
    io_in_3_bits_task_off,
    io_in_3_bits_task_alias,
    io_in_3_bits_task_vaddr,
    io_in_3_bits_task_isKeyword,
    io_in_3_bits_task_opcode,
    io_in_3_bits_task_param,
    io_in_3_bits_task_size,
    io_in_3_bits_task_sourceId,
    io_in_3_bits_task_corrupt,
    io_in_3_bits_task_fromL2pft,
    io_in_3_bits_task_needHint,
    io_in_3_bits_task_reqSource,
    io_in_3_bits_waitMP,
    io_in_3_bits_waitMS,
    N'(8)   // 独热标识：第 3 路
  };

  xs_FastArbiter_core #(.N(N), .W(PW + N)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  (in_valid),
    .in_bits   (in_bits),
    .in_ready  (),              // 本变体没有逐路 ready 端口
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_bits)
  );

  assign chosenOH  = out_bits[N-1:0];
  assign io_chosen = {chosenOH[3] | chosenOH[2], chosenOH[3] | chosenOH[1]};   // OHToUInt

  // 载荷拆回各字段
  assign {
    io_out_bits_valid,
    io_out_bits_rdy,
    io_out_bits_task_channel,
    io_out_bits_task_set,
    io_out_bits_task_tag,
    io_out_bits_task_off,
    io_out_bits_task_alias,
    io_out_bits_task_vaddr,
    io_out_bits_task_isKeyword,
    io_out_bits_task_opcode,
    io_out_bits_task_param,
    io_out_bits_task_size,
    io_out_bits_task_sourceId,
    io_out_bits_task_corrupt,
    io_out_bits_task_fromL2pft,
    io_out_bits_task_needHint,
    io_out_bits_task_reqSource,
    io_out_bits_waitMP,
    io_out_bits_waitMS
  } = out_bits[PW+N-1:N];

endmodule
