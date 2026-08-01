// =====================================================================
// xs_RobEnqPtrWrapper_core —— ROB 入队指针生成(enqPtr) 可读重写
// ---------------------------------------------------------------------
// 角色: 香山 V2R2 ROB 的「入队头」指针生成器。golden 名 RobEnqPtrWrapper,
//   在 Rob.sv 里例化为 enqPtrGenModule。
//
// 维护 RenameWidth(=6) 个连续的 RobPtr(CircularQueuePtr{flag, value}):
//   enqPtrVec[0..5], 满足 enqPtrVec[k] = enqPtrVec[0] + k (环形, 模 RobSize=160)。
//   仅 enqPtrVec[0] 存 flag(其余槽的 flag 从不被读, golden 也只留 enqPtrVec_0_flag);
//   6 个槽都存 8 位 value。
//
// RobPtr 语义(RobSize=160, PTR_W=8):
//   value ∈ [0,160); flag 翻转区分绕回一圈的新旧。
//   ptr + n: 若 value+n >= 160 则 wrap: value = value+n-160, flag ^= 1; 否则不变。
//   (golden 的加量 n ≤ 6, 故一次最多绕一圈; 用单次减 160 判定即可。)
//
// 三种更新来源(优先级 reset > redirect > 正常入队):
//   reset      : enqPtrVec[k] = {flag=0, value=k}   (0,1,2,3,4,5)。
//   redirect   : 以 redirect.robIdx 为基:
//                 level=1(flush 本条, robIdx 及之后全冲掉) → base = robIdx;
//                 level=0(仅冲 robIdx 之后)               → base = robIdx + 1;
//                enqPtrVec[k] = base + k。
//   正常入队    : numEnq = (allowEnqueue & ~hasBlockBackward) ? popcount(enq[0..5]) : 0;
//                enqPtrVec[k] = enqPtrVec[k] + numEnq。
//
// 与 golden 逐位等价(bug-for-bug): 见 docs 或 golden RobEnqPtrWrapper.sv。
// =====================================================================
module xs_RobEnqPtrWrapper_core #(
  parameter int unsigned ROB_SIZE = 160,
  parameter int unsigned PTR_W    = 8,     // log2up(160)
  parameter int unsigned ENQ_NUM  = 6      // RenameWidth
) (
  input  logic             clock,
  input  logic             reset,
  input  logic             io_redirect_valid,
  input  logic             io_redirect_bits_robIdx_flag,
  input  logic [PTR_W-1:0] io_redirect_bits_robIdx_value,
  input  logic             io_redirect_bits_level,
  input  logic             io_allowEnqueue,
  input  logic             io_hasBlockBackward,
  input  logic             io_enq_0,
  input  logic             io_enq_1,
  input  logic             io_enq_2,
  input  logic             io_enq_3,
  input  logic             io_enq_4,
  input  logic             io_enq_5,
  output logic             io_out_0_flag,
  output logic [PTR_W-1:0] io_out_0_value,
  output logic [PTR_W-1:0] io_out_1_value,
  output logic [PTR_W-1:0] io_out_2_value,
  output logic [PTR_W-1:0] io_out_3_value,
  output logic [PTR_W-1:0] io_out_4_value,
  output logic [PTR_W-1:0] io_out_5_value
);

  // ------------------------------------------------------------------
  // 状态: enqPtrVec[0] 的 flag + 6 个槽的 value。
  // ------------------------------------------------------------------
  logic             enqPtr0_flag;
  logic [PTR_W-1:0] enqPtrVec_value [ENQ_NUM];

  // ------------------------------------------------------------------
  // RobPtr 加法(单次绕圈): 给定基址 value(PTR_W 位) 与加量 add(≤6),
  //   sum = value + add(用 PTR_W+1 位无符号相加, 上限 159+6=165 < 256);
  //   若 sum >= ROB_SIZE 则 wrap: new_value = sum - ROB_SIZE, wrapped=1;
  //   否则 new_value = sum[PTR_W-1:0], wrapped=0。
  // golden 用 (x - 160) 的符号位判定 >= 160: $signed(10'(x-160)) > -1 ⇔ x >= 160。
  // ------------------------------------------------------------------
  localparam int unsigned SUMW = PTR_W + 2;  // 与 golden 的 9/10 位中间量对齐余量

  function automatic logic ptr_add_wrapped(input logic [PTR_W-1:0] base,
                                           input logic [3:0]       add);
    logic [SUMW-1:0] sum;
    sum = {{(SUMW-PTR_W){1'b0}}, base} + {{(SUMW-4){1'b0}}, add};
    return (sum >= SUMW'(ROB_SIZE));
  endfunction

  function automatic logic [PTR_W-1:0] ptr_add_value(input logic [PTR_W-1:0] base,
                                                     input logic [3:0]       add);
    logic [SUMW-1:0] sum;
    logic [SUMW-1:0] diff;
    sum  = {{(SUMW-PTR_W){1'b0}}, base} + {{(SUMW-4){1'b0}}, add};
    diff = sum - SUMW'(ROB_SIZE);
    return (sum >= SUMW'(ROB_SIZE)) ? diff[PTR_W-1:0] : sum[PTR_W-1:0];
  endfunction

  // ------------------------------------------------------------------
  // redirect 分支的基址: level=1 → robIdx; level=0 → robIdx + 1。
  //   每个槽 k 的目标 = redirectBase + k, flag 按是否绕圈从 robIdx.flag 翻转。
  //   注意: 只有槽 0 的 flag 被输出/存储。
  // ------------------------------------------------------------------
  logic [PTR_W-1:0] redir_add;   // level=1 时槽 0 加 0; level=0 时槽 0 加 1
  assign redir_add = io_redirect_bits_level ? '0 : PTR_W'(1);

  // ------------------------------------------------------------------
  // 正常入队: dispatch 个数(popcount of enq[0..5]), 由 allow & ~block 门控。
  // ------------------------------------------------------------------
  logic [3:0] enqNum;
  always_comb begin
    logic [3:0] cnt;
    cnt = 4'd0;
    cnt += {3'd0, io_enq_0};
    cnt += {3'd0, io_enq_1};
    cnt += {3'd0, io_enq_2};
    cnt += {3'd0, io_enq_3};
    cnt += {3'd0, io_enq_4};
    cnt += {3'd0, io_enq_5};
    enqNum = (io_allowEnqueue & ~io_hasBlockBackward) ? cnt : 4'd0;
  end

  // ------------------------------------------------------------------
  // 时序更新: 异步 reset(与 golden 一致 posedge reset)。
  // ------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      enqPtr0_flag <= 1'b0;
      for (int k = 0; k < ENQ_NUM; k++) begin
        enqPtrVec_value[k] <= PTR_W'(k);
      end
    end
    else if (io_redirect_valid) begin
      // 槽 0 的 flag: 从 redirect.robIdx.flag 出发, 若 (robIdx + redir_add + 0) 绕圈则翻转。
      enqPtr0_flag <=
        ptr_add_wrapped(io_redirect_bits_robIdx_value, redir_add[3:0])
          ^ io_redirect_bits_robIdx_flag;
      for (int k = 0; k < ENQ_NUM; k++) begin
        // 目标 = robIdx + redir_add + k。
        enqPtrVec_value[k] <=
          ptr_add_value(io_redirect_bits_robIdx_value, redir_add[3:0] + 4'(k));
      end
    end
    else begin
      // 正常推进: enqPtrVec[k] += enqNum。槽 0 flag 若绕圈则翻转。
      enqPtr0_flag <=
        ptr_add_wrapped(enqPtrVec_value[0], enqNum) ^ enqPtr0_flag;
      for (int k = 0; k < ENQ_NUM; k++) begin
        enqPtrVec_value[k] <= ptr_add_value(enqPtrVec_value[k], enqNum);
      end
    end
  end

  // ------------------------------------------------------------------
  // 输出。
  // ------------------------------------------------------------------
  assign io_out_0_flag  = enqPtr0_flag;
  assign io_out_0_value = enqPtrVec_value[0];
  assign io_out_1_value = enqPtrVec_value[1];
  assign io_out_2_value = enqPtrVec_value[2];
  assign io_out_3_value = enqPtrVec_value[3];
  assign io_out_4_value = enqPtrVec_value[4];
  assign io_out_5_value = enqPtrVec_value[5];

endmodule
