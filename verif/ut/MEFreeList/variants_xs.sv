// 自动生成：scripts/gen_mefreelist.py —— 勿手改
// golden 同名扁平端口 → 可读核 xs_MEFreeList_core 的机械适配层
module MEFreeList_xs(
  input        clock,
  input        reset,
  input        io_redirect,
  input        io_walk,
  input        io_allocateReq_0,
  input        io_allocateReq_1,
  input        io_allocateReq_2,
  input        io_allocateReq_3,
  input        io_allocateReq_4,
  input        io_allocateReq_5,
  input        io_walkReq_0,
  input        io_walkReq_1,
  input        io_walkReq_2,
  input        io_walkReq_3,
  input        io_walkReq_4,
  input        io_walkReq_5,
  output [7:0] io_allocatePhyReg_0,
  output [7:0] io_allocatePhyReg_1,
  output [7:0] io_allocatePhyReg_2,
  output [7:0] io_allocatePhyReg_3,
  output [7:0] io_allocatePhyReg_4,
  output [7:0] io_allocatePhyReg_5,
  output       io_canAllocate,
  input        io_doAllocate,
  input        io_freeReq_0,
  input        io_freeReq_1,
  input        io_freeReq_2,
  input        io_freeReq_3,
  input        io_freeReq_4,
  input        io_freeReq_5,
  input  [7:0] io_freePhyReg_0,
  input  [7:0] io_freePhyReg_1,
  input  [7:0] io_freePhyReg_2,
  input  [7:0] io_freePhyReg_3,
  input  [7:0] io_freePhyReg_4,
  input  [7:0] io_freePhyReg_5,
  input        io_commit_isCommit,
  input        io_commit_commitValid_0,
  input        io_commit_commitValid_1,
  input        io_commit_commitValid_2,
  input        io_commit_commitValid_3,
  input        io_commit_commitValid_4,
  input        io_commit_commitValid_5,
  input        io_commit_info_0_rfWen,
  input        io_commit_info_0_isMove,
  input        io_commit_info_1_rfWen,
  input        io_commit_info_1_isMove,
  input        io_commit_info_2_rfWen,
  input        io_commit_info_2_isMove,
  input        io_commit_info_3_rfWen,
  input        io_commit_info_3_isMove,
  input        io_commit_info_4_rfWen,
  input        io_commit_info_4_isMove,
  input        io_commit_info_5_rfWen,
  input        io_commit_info_5_isMove,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value
);
  logic [5:0] io_allocateReq;
  logic [5:0] io_walkReq;
  logic [7:0] allocatePhyReg [6];
  logic [5:0] io_freeReq;
  logic [7:0] freePhyReg [6];
  logic [5:0] io_commit_commitValid;
  logic [5:0] io_commit_info_rfWen;
  logic [5:0] io_commit_info_isMove;
  logic [3:0] io_snpt_flushVec;
  logic [5:0] perf_value [4];

  assign io_allocateReq = {io_allocateReq_5, io_allocateReq_4, io_allocateReq_3,
                           io_allocateReq_2, io_allocateReq_1, io_allocateReq_0};
  assign io_walkReq     = {io_walkReq_5, io_walkReq_4, io_walkReq_3,
                           io_walkReq_2, io_walkReq_1, io_walkReq_0};
  assign io_freeReq     = {io_freeReq_5, io_freeReq_4, io_freeReq_3,
                           io_freeReq_2, io_freeReq_1, io_freeReq_0};
  assign freePhyReg     = '{io_freePhyReg_0, io_freePhyReg_1, io_freePhyReg_2,
                            io_freePhyReg_3, io_freePhyReg_4, io_freePhyReg_5};
  assign io_commit_commitValid = {io_commit_commitValid_5, io_commit_commitValid_4,
                                  io_commit_commitValid_3, io_commit_commitValid_2,
                                  io_commit_commitValid_1, io_commit_commitValid_0};
  assign io_commit_info_rfWen  = {io_commit_info_5_rfWen, io_commit_info_4_rfWen,
                                  io_commit_info_3_rfWen, io_commit_info_2_rfWen,
                                  io_commit_info_1_rfWen, io_commit_info_0_rfWen};
  assign io_commit_info_isMove = {io_commit_info_5_isMove, io_commit_info_4_isMove,
                                  io_commit_info_3_isMove, io_commit_info_2_isMove,
                                  io_commit_info_1_isMove, io_commit_info_0_isMove};
  assign io_snpt_flushVec = {io_snpt_flushVec_3, io_snpt_flushVec_2,
                             io_snpt_flushVec_1, io_snpt_flushVec_0};

  assign io_allocatePhyReg_0 = allocatePhyReg[0];
  assign io_allocatePhyReg_1 = allocatePhyReg[1];
  assign io_allocatePhyReg_2 = allocatePhyReg[2];
  assign io_allocatePhyReg_3 = allocatePhyReg[3];
  assign io_allocatePhyReg_4 = allocatePhyReg[4];
  assign io_allocatePhyReg_5 = allocatePhyReg[5];
  assign io_perf_0_value = perf_value[0];
  assign io_perf_1_value = perf_value[1];
  assign io_perf_2_value = perf_value[2];
  assign io_perf_3_value = perf_value[3];

  xs_MEFreeList_core u_core (
    .clock(clock),
    .reset(reset),
    .io_redirect(io_redirect),
    .io_walk(io_walk),
    .io_allocateReq(io_allocateReq),
    .io_walkReq(io_walkReq),
    .io_allocatePhyReg(allocatePhyReg),
    .io_canAllocate(io_canAllocate),
    .io_doAllocate(io_doAllocate),
    .io_freeReq(io_freeReq),
    .io_freePhyReg(freePhyReg),
    .io_commit_isCommit(io_commit_isCommit),
    .io_commit_commitValid(io_commit_commitValid),
    .io_commit_info_rfWen(io_commit_info_rfWen),
    .io_commit_info_isMove(io_commit_info_isMove),
    .io_snpt_snptEnq(io_snpt_snptEnq),
    .io_snpt_snptDeq(io_snpt_snptDeq),
    .io_snpt_useSnpt(io_snpt_useSnpt),
    .io_snpt_snptSelect(io_snpt_snptSelect),
    .io_snpt_flushVec(io_snpt_flushVec),
    .io_perf_value(perf_value)
  );
endmodule
