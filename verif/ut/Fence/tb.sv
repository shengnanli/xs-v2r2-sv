`timescale 1ns/1ps
// =============================================================================
// Fence UT —— golden `Fence` 与重写 `Fence_xs` 双例化，同激励逐拍比对全部 29 个输出。
//
// 端口表由 G1-canonical/golden-rtl/Fence.sv 机械提取（含 G1 新增的 10 个
// perfDebugInfo 字段与 debug_seqNum），比对用 `CHK 宏逐端口展开，避免手抄漏项。
//
// 激励两段：
//   A 定向段：把 6 个合法 fuOpType 逐个跑完整状态机（含 sbuffer 不空时的等待），
//     src1 刻意在 bit[15:14] 放非零值 —— 这正是 G1 逻辑改动的可观测点：
//     hfence.gvma(0x14) 的 id 必须把这两位补零（VMID 14 位），
//     而 sfence(0x11)/hfence.vvma(0x13) 的 id 要原样保留（ASID 16 位）。
//   B 随机段：随机握手 + 加权随机 op（含非法编码）+ 随机 src/imm/sbIsEmpty/out_ready。
//
// ★golden 行为坑（两侧一致，bug-for-bug 保留）★：非法 fuOpType 一旦被锁存，
// s_wait 的四个分流条件全不成立，状态机永远停在 s_wait —— in.ready=0 收不了新请求、
// out.valid=0 也不写回，只有 reset 能救。所以随机段必须检测这个死锁并打 reset，
// 否则第一条非法 op 之后整个 run 都卡在 s_wait，覆盖为零却照样 errors=0 报绿
// （本 tb 第一版正是这样：200k 拍里只 fire 了 1 条随机 op）。
//
// 末尾除 errors 外还打印功能覆盖计数，并要求关键覆盖项非零（否则判 FAIL）——
// 防止"随机没打到改动点却报绿"。
// =============================================================================
`define CHK(P)                                                               \
  begin                                                                      \
    checks++;                                                                \
    if (g_``P !== i_``P) begin                                               \
      errors++;                                                              \
      if (errors <= 20)                                                      \
        $display("[ERR] t=%0t %s: golden=%h impl=%h", $time, `"P`",          \
                 g_``P, i_``P);                                              \
    end                                                                      \
  end

module tb;

  // fuOpType 合法编码（xiangshan/package.scala: object FenceOpType）
  localparam logic [8:0] OP_NOFENCE  = 9'h00;
  localparam logic [8:0] OP_FENCE    = 9'h10;
  localparam logic [8:0] OP_SFENCE   = 9'h11;
  localparam logic [8:0] OP_FENCEI   = 9'h12;
  localparam logic [8:0] OP_HFENCE_V = 9'h13;
  localparam logic [8:0] OP_HFENCE_G = 9'h14;

  int unsigned NCYCLES = 200000;
  bit clk = 0;
  bit rst = 1;
  int errors = 0;
  int checks = 0;

  // 功能覆盖计数（各 op 实际 fire 次数 + 改动点专项）
  int cov_fire[6];                 // 按上面 6 个合法编码计数
  int cov_illegal_fire = 0;        // 非法编码 fire 次数
  int cov_hg_high_bits = 0;        // hfence.gvma fire 且 src1[15:14]!=0（必须补零）
  int cov_asid_high_bits = 0;      // sfence/hfence.vvma fire 且 src1[15:14]!=0（必须保留）
  int cov_sfence_valid = 0;        // 观测到 sfence.valid 拉高
  int cov_fencei = 0;              // 观测到 fencei 拉高
  int cov_wait_stall = 0;          // 观测到 s_wait 期间 sbuffer 未空（真的等过）
  int cov_deadlock_rst = 0;        // 非法 op 卡死 s_wait 后打 reset 解救的次数

  // s_wait 连续拉高的拍数；超过 STUCK_LIMIT 认定卡死（合法 op 只会等到 sbIsEmpty）
  localparam int STUCK_LIMIT = 8;
  int stuck_cnt = 0;

  always #5 clk = ~clk;

  // ---- 共享输入（25 个 input，去掉 clock/reset）----
  logic           io_in_valid;
  logic [8:0]     io_in_bits_ctrl_fuOpType;
  logic           io_in_bits_ctrl_robIdx_flag;
  logic [7:0]     io_in_bits_ctrl_robIdx_value;
  logic [7:0]     io_in_bits_ctrl_pdest;
  logic           io_in_bits_ctrl_flushPipe;
  logic [63:0]    io_in_bits_data_src_1;
  logic [63:0]    io_in_bits_data_src_0;
  logic [63:0]    io_in_bits_data_imm;
  logic           io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0]    io_in_bits_perfDebugInfo_renameTime;
  logic [63:0]    io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0]    io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0]    io_in_bits_perfDebugInfo_selectTime;
  logic [63:0]    io_in_bits_perfDebugInfo_issueTime;
  logic [63:0]    io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0]    io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0]    io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0]    io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0]    io_in_bits_debug_seqNum_seqNum;
  logic [7:0]     io_in_bits_debug_seqNum_uopIdx;
  logic           io_out_ready;
  logic           io_fenceio_sbuffer_sbIsEmpty;

  // ---- 两侧输出（29 个 output，各一份）----
  wire           g_io_in_ready, i_io_in_ready;
  wire           g_io_out_valid, i_io_out_valid;
  wire           g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag;
  wire [7:0]     g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value;
  wire [7:0]     g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest;
  wire           g_io_out_bits_ctrl_flushPipe, i_io_out_bits_ctrl_flushPipe;
  wire [63:0]    g_io_out_bits_res_data, i_io_out_bits_res_data;
  wire           g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0]    g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0]    g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0]    g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0]    g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0]    g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0]    g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0]    g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0]    g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0]    g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0]    g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum;
  wire [7:0]     g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx;
  wire           g_io_fenceio_sfence_valid, i_io_fenceio_sfence_valid;
  wire           g_io_fenceio_sfence_bits_rs1, i_io_fenceio_sfence_bits_rs1;
  wire           g_io_fenceio_sfence_bits_rs2, i_io_fenceio_sfence_bits_rs2;
  wire [49:0]    g_io_fenceio_sfence_bits_addr, i_io_fenceio_sfence_bits_addr;
  wire [15:0]    g_io_fenceio_sfence_bits_id, i_io_fenceio_sfence_bits_id;
  wire           g_io_fenceio_sfence_bits_flushPipe, i_io_fenceio_sfence_bits_flushPipe;
  wire           g_io_fenceio_sfence_bits_hv, i_io_fenceio_sfence_bits_hv;
  wire           g_io_fenceio_sfence_bits_hg, i_io_fenceio_sfence_bits_hg;
  wire           g_io_fenceio_fencei, i_io_fenceio_fencei;
  wire           g_io_fenceio_sbuffer_flushSb, i_io_fenceio_sbuffer_flushSb;

  Fence u_g (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_flushPipe(io_in_bits_ctrl_flushPipe),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_fenceio_sbuffer_sbIsEmpty(io_fenceio_sbuffer_sbIsEmpty),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_flushPipe(g_io_out_bits_ctrl_flushPipe),
    .io_out_bits_res_data(g_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx),
    .io_fenceio_sfence_valid(g_io_fenceio_sfence_valid),
    .io_fenceio_sfence_bits_rs1(g_io_fenceio_sfence_bits_rs1),
    .io_fenceio_sfence_bits_rs2(g_io_fenceio_sfence_bits_rs2),
    .io_fenceio_sfence_bits_addr(g_io_fenceio_sfence_bits_addr),
    .io_fenceio_sfence_bits_id(g_io_fenceio_sfence_bits_id),
    .io_fenceio_sfence_bits_flushPipe(g_io_fenceio_sfence_bits_flushPipe),
    .io_fenceio_sfence_bits_hv(g_io_fenceio_sfence_bits_hv),
    .io_fenceio_sfence_bits_hg(g_io_fenceio_sfence_bits_hg),
    .io_fenceio_fencei(g_io_fenceio_fencei),
    .io_fenceio_sbuffer_flushSb(g_io_fenceio_sbuffer_flushSb)
  );

  Fence_xs u_i (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_flushPipe(io_in_bits_ctrl_flushPipe),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_fenceio_sbuffer_sbIsEmpty(io_fenceio_sbuffer_sbIsEmpty),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_flushPipe(i_io_out_bits_ctrl_flushPipe),
    .io_out_bits_res_data(i_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx),
    .io_fenceio_sfence_valid(i_io_fenceio_sfence_valid),
    .io_fenceio_sfence_bits_rs1(i_io_fenceio_sfence_bits_rs1),
    .io_fenceio_sfence_bits_rs2(i_io_fenceio_sfence_bits_rs2),
    .io_fenceio_sfence_bits_addr(i_io_fenceio_sfence_bits_addr),
    .io_fenceio_sfence_bits_id(i_io_fenceio_sfence_bits_id),
    .io_fenceio_sfence_bits_flushPipe(i_io_fenceio_sfence_bits_flushPipe),
    .io_fenceio_sfence_bits_hv(i_io_fenceio_sfence_bits_hv),
    .io_fenceio_sfence_bits_hg(i_io_fenceio_sfence_bits_hg),
    .io_fenceio_fencei(i_io_fenceio_fencei),
    .io_fenceio_sbuffer_flushSb(i_io_fenceio_sbuffer_flushSb)
  );

  // ---------------------------------------------------------------------------
  // 逐拍比对 + 覆盖统计
  // ---------------------------------------------------------------------------
  task automatic compare_all();
    `CHK(io_in_ready)
    `CHK(io_out_valid)
    `CHK(io_out_bits_ctrl_robIdx_flag)
    `CHK(io_out_bits_ctrl_robIdx_value)
    `CHK(io_out_bits_ctrl_pdest)
    `CHK(io_out_bits_ctrl_flushPipe)
    `CHK(io_out_bits_res_data)
    `CHK(io_out_bits_perfDebugInfo_eliminatedMove)
    `CHK(io_out_bits_perfDebugInfo_renameTime)
    `CHK(io_out_bits_perfDebugInfo_dispatchTime)
    `CHK(io_out_bits_perfDebugInfo_enqRsTime)
    `CHK(io_out_bits_perfDebugInfo_selectTime)
    `CHK(io_out_bits_perfDebugInfo_issueTime)
    `CHK(io_out_bits_perfDebugInfo_writebackTime)
    `CHK(io_out_bits_perfDebugInfo_runahead_checkpoint_id)
    `CHK(io_out_bits_perfDebugInfo_tlbFirstReqTime)
    `CHK(io_out_bits_perfDebugInfo_tlbRespTime)
    `CHK(io_out_bits_debug_seqNum_seqNum)
    `CHK(io_out_bits_debug_seqNum_uopIdx)
    `CHK(io_fenceio_sfence_valid)
    `CHK(io_fenceio_sfence_bits_rs1)
    `CHK(io_fenceio_sfence_bits_rs2)
    `CHK(io_fenceio_sfence_bits_addr)
    `CHK(io_fenceio_sfence_bits_id)
    `CHK(io_fenceio_sfence_bits_flushPipe)
    `CHK(io_fenceio_sfence_bits_hv)
    `CHK(io_fenceio_sfence_bits_hg)
    `CHK(io_fenceio_fencei)
    `CHK(io_fenceio_sbuffer_flushSb)
  endtask

  // 覆盖统计：以 golden 的 in_ready 判定 fire（两侧已逐拍比对，用哪侧都一样）
  task automatic sample_cov();
    if (g_io_in_ready === 1'b1 && io_in_valid === 1'b1) begin
      case (io_in_bits_ctrl_fuOpType)
        OP_NOFENCE : cov_fire[0]++;
        OP_FENCE   : cov_fire[1]++;
        OP_SFENCE  : cov_fire[2]++;
        OP_FENCEI  : cov_fire[3]++;
        OP_HFENCE_V: cov_fire[4]++;
        OP_HFENCE_G: cov_fire[5]++;
        default    : cov_illegal_fire++;
      endcase
      // ★G1 改动点专项：src1[15:14] 非零时 hfence.gvma 与 sfence/hfence.vvma
      //   对 id 的处理才会分道扬镳（前者补零、后者保留）
      if (io_in_bits_data_src_1[15:14] != 2'b00) begin
        if (io_in_bits_ctrl_fuOpType == OP_HFENCE_G) cov_hg_high_bits++;
        if (io_in_bits_ctrl_fuOpType == OP_SFENCE ||
            io_in_bits_ctrl_fuOpType == OP_HFENCE_V) cov_asid_high_bits++;
      end
    end
    if (g_io_fenceio_sfence_valid === 1'b1) cov_sfence_valid++;
    if (g_io_fenceio_fencei      === 1'b1) cov_fencei++;
    if (g_io_fenceio_sbuffer_flushSb === 1'b1 &&
        io_fenceio_sbuffer_sbIsEmpty === 1'b0) cov_wait_stall++;
  endtask

  // 一拍：激励须在调用前摆好；先过 posedge（DUT 采样），再在 negedge 比对组合输出
  task automatic cycle();
    @(posedge clk);
    sample_cov();
    @(negedge clk);
    compare_all();
  endtask

  // ---------------------------------------------------------------------------
  // 定向激励：把一条 fence 从发射跑到写回
  //   stall_cycles: 进 s_wait 后故意让 sbIsEmpty=0 若干拍，验证"等排空"路径
  // ---------------------------------------------------------------------------
  task automatic run_one(input logic [8:0] op,
                         input logic [63:0] src0,
                         input logic [63:0] src1,
                         input logic [63:0] imm,
                         input int          stall_cycles);
    io_in_bits_ctrl_fuOpType     = op;
    io_in_bits_data_src_0        = src0;
    io_in_bits_data_src_1        = src1;
    io_in_bits_data_imm          = imm;
    io_in_bits_ctrl_robIdx_flag  = 1'($urandom);
    io_in_bits_ctrl_robIdx_value = 8'($urandom);
    io_in_bits_ctrl_pdest        = 8'($urandom);
    io_in_bits_ctrl_flushPipe    = 1'($urandom);
    io_out_ready                 = 1'b1;
    io_fenceio_sbuffer_sbIsEmpty = 1'b0;
    io_in_valid                  = 1'b1;
    cycle();                              // s_idle → s_wait（in.fire）
    io_in_valid                  = 1'b0;
    repeat (stall_cycles) cycle();        // s_wait 等 sbuffer 排空
    io_fenceio_sbuffer_sbIsEmpty = 1'b1;
    cycle();                              // s_wait → 对应"干活态"
    cycle();                              // 干活态一拍（out.valid=1）→ s_idle
    cycle();                              // 回到 s_idle
  endtask

  task automatic directed_phase();
    logic [8:0] ops[6];
    logic [63:0] id_pats[4];
    ops = '{OP_NOFENCE, OP_FENCE, OP_SFENCE, OP_FENCEI, OP_HFENCE_V, OP_HFENCE_G};
    // src1 的低 16 位模式：刻意让 bit[15:14] 取遍 00/01/10/11
    id_pats = '{64'hDEAD_BEEF_1234_0000,   // [15:14]=00：ASID 与 VMID 同值
                64'hDEAD_BEEF_1234_4321,   // [15:14]=01
                64'hFFFF_FFFF_FFFF_8765,   // [15:14]=10
                64'hDEAD_BEEF_1234_FFFF};  // [15:14]=11：VMID 必须被截成 0x3FFF
    foreach (ops[oi]) begin
      foreach (id_pats[pi]) begin
        // imm 低 10 位取遍 rs1/rs2 是否为 x0 的四种组合
        run_one(ops[oi], 64'h0000_1234_5678_9ABC, id_pats[pi], 64'h0,   0);
        run_one(ops[oi], 64'h3FFF_FFFF_FFFF_FFFF, id_pats[pi], 64'h1F,  1);
        run_one(ops[oi], 64'hFFFF_FFFF_FFFF_FFFF, id_pats[pi], 64'h3E0, 3);
        run_one(ops[oi], 64'h0,                   id_pats[pi], 64'h3FF, 0);
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // 随机激励
  // ---------------------------------------------------------------------------
  // 加权随机 op：偏向 6 个合法编码，留一成给非法编码测健壮性
  function automatic logic [8:0] rand_op();
    int unsigned r = $urandom_range(0, 99);
    case (1'b1)
      (r < 15): return OP_NOFENCE;
      (r < 30): return OP_FENCE;
      (r < 46): return OP_SFENCE;
      (r < 61): return OP_FENCEI;
      (r < 76): return OP_HFENCE_V;
      (r < 91): return OP_HFENCE_G;
      default : return 9'($urandom_range(0, 511));
    endcase
  endfunction

  // 打一发 reset 把卡在 s_wait 的状态机救回 s_idle（非法 op 的唯一出路）
  task automatic reset_pulse();
    io_in_valid = 1'b0;
    rst         = 1'b1;
    cycle();
    cycle();
    rst         = 1'b0;
    stuck_cnt   = 0;
    cov_deadlock_rst++;
  endtask

  task automatic random_phase(input int unsigned n);
    repeat (n) begin
      // 卡死检测：s_wait 连续拉高超过阈值 ⇒ 锁存的是非法 op，只能 reset
      if (g_io_fenceio_sbuffer_flushSb === 1'b1) stuck_cnt++;
      else                                       stuck_cnt = 0;
      if (stuck_cnt > STUCK_LIMIT) begin
        reset_pulse();
        continue;
      end
      io_in_valid                  = ($urandom_range(0, 99) < 55);
      io_in_bits_ctrl_fuOpType     = rand_op();
      io_in_bits_ctrl_robIdx_flag  = 1'($urandom);
      io_in_bits_ctrl_robIdx_value = 8'($urandom);
      io_in_bits_ctrl_pdest        = 8'($urandom);
      io_in_bits_ctrl_flushPipe    = 1'($urandom);
      io_in_bits_data_src_1        = {$urandom, $urandom};
      io_in_bits_data_src_0        = {$urandom, $urandom};
      io_in_bits_data_imm          = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_eliminatedMove         = 1'($urandom);
      io_in_bits_perfDebugInfo_renameTime             = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_dispatchTime           = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_enqRsTime              = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_selectTime             = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_issueTime              = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_writebackTime          = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_runahead_checkpoint_id = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_tlbFirstReqTime        = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_tlbRespTime            = {$urandom, $urandom};
      io_in_bits_debug_seqNum_seqNum                  = 56'({$urandom, $urandom});
      io_in_bits_debug_seqNum_uopIdx                  = 8'($urandom);
      io_out_ready                 = ($urandom_range(0, 99) < 90);
      // sbIsEmpty 偏向常拉高保证状态机推进，又时常拉低制造 s_wait 等待
      io_fenceio_sbuffer_sbIsEmpty = ($urandom_range(0, 99) < 70);
      cycle();
    end
  endtask

  // ---------------------------------------------------------------------------
  initial begin
    void'($value$plusargs("NCYCLES=%d", NCYCLES));

    io_in_valid                  = 1'b0;
    io_in_bits_ctrl_fuOpType     = '0;
    io_in_bits_ctrl_robIdx_flag  = '0;
    io_in_bits_ctrl_robIdx_value = '0;
    io_in_bits_ctrl_pdest        = '0;
    io_in_bits_ctrl_flushPipe    = '0;
    io_in_bits_data_src_1        = '0;
    io_in_bits_data_src_0        = '0;
    io_in_bits_data_imm          = '0;
    io_in_bits_perfDebugInfo_eliminatedMove         = '0;
    io_in_bits_perfDebugInfo_renameTime             = '0;
    io_in_bits_perfDebugInfo_dispatchTime           = '0;
    io_in_bits_perfDebugInfo_enqRsTime              = '0;
    io_in_bits_perfDebugInfo_selectTime             = '0;
    io_in_bits_perfDebugInfo_issueTime              = '0;
    io_in_bits_perfDebugInfo_writebackTime          = '0;
    io_in_bits_perfDebugInfo_runahead_checkpoint_id = '0;
    io_in_bits_perfDebugInfo_tlbFirstReqTime        = '0;
    io_in_bits_perfDebugInfo_tlbRespTime            = '0;
    io_in_bits_debug_seqNum_seqNum                  = '0;
    io_in_bits_debug_seqNum_uopIdx                  = '0;
    io_out_ready                 = 1'b1;
    io_fenceio_sbuffer_sbIsEmpty = 1'b0;
    foreach (cov_fire[k]) cov_fire[k] = 0;

    rst = 1'b1;
    repeat (5) @(posedge clk);
    @(negedge clk);
    rst = 1'b0;

    directed_phase();
    random_phase(NCYCLES);

    $display("---- 功能覆盖（fire 次数）----");
    $display("  nofence=%0d fence=%0d sfence=%0d fencei=%0d hfence_v=%0d hfence_g=%0d illegal=%0d",
             cov_fire[0], cov_fire[1], cov_fire[2], cov_fire[3],
             cov_fire[4], cov_fire[5], cov_illegal_fire);
    $display("  src1[15:14]!=0 时: hfence_g fire=%0d (须补零)  sfence/hfence_v fire=%0d (须保留)",
             cov_hg_high_bits, cov_asid_high_bits);
    $display("  sfence.valid 拍数=%0d  fencei 拍数=%0d  s_wait 等排空拍数=%0d",
             cov_sfence_valid, cov_fencei, cov_wait_stall);
    $display("  非法 op 卡死 s_wait 后 reset 解救次数=%0d", cov_deadlock_rst);
    $display("checks=%0d errors=%0d", checks, errors);

    if (errors != 0) begin
      $display("TEST FAILED");
      $fatal(1);
    end
    // 覆盖闸：关键路径没打到就不许报绿
    if (checks < 100000 || cov_hg_high_bits == 0 || cov_asid_high_bits == 0 ||
        cov_sfence_valid == 0 || cov_fencei == 0 || cov_wait_stall == 0 ||
        cov_illegal_fire == 0 || cov_deadlock_rst == 0 ||
        cov_fire[0] == 0 || cov_fire[1] == 0 || cov_fire[2] == 0 ||
        cov_fire[3] == 0 || cov_fire[4] == 0 || cov_fire[5] == 0) begin
      $display("TEST FAILED (覆盖不足)");
      $fatal(1);
    end
    $display("TEST PASSED");
    $finish;
  end

endmodule
