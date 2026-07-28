// xs_VfofBuffer_core —— 向量 fault-only-first(fof, 如 vleff)缓冲, 单条目
// 手写可读重写, bug-for-bug 对齐 golden VfofBuffer.sv(firtool 生成)。
//
// 功能: fof 类向量 load(isVleff)可能在中途取到异常, 需要把实际提交的 vl 回写。
// 本模块缓存该 fof uop(单条目), 收集其各 flow 的 mergeUopWriteback(异常/vl),
// 取"最老且带异常"的 flow 决定最终 vl 与 hasException, lastUop 到齐后回写。
//
// 端口(io_in_0/1): 两路入队候选, 仅 isVleff 者入队, port0 优先。
// io_mergeUopWriteback_0/1: 两路 flow 回写(按 robIdx 匹配当前条目)。
// io_uopWriteback: 条目 lastUop&isVleff&~flush 时输出最终 uop+vl。
//
// 无子模块, 无 SRAM。所有寄存器复位到 0(异步 reset)。
module xs_VfofBuffer_core
  import xs_vfofbuffer_pkg::*;
(
  input          clock,
  input          reset,
  // redirect
  input          io_redirect_valid,
  input          io_redirect_bits_robIdx_flag,
  input  [7:0]   io_redirect_bits_robIdx_value,
  input          io_redirect_bits_level,
  // 入队 port 0
  input          io_in_0_valid,
  input  [8:0]   io_in_0_bits_uop_fuOpType,
  input          io_in_0_bits_uop_vecWen,
  input          io_in_0_bits_uop_v0Wen,
  input          io_in_0_bits_uop_vlWen,
  input          io_in_0_bits_uop_vpu_vma,
  input          io_in_0_bits_uop_vpu_vta,
  input  [1:0]   io_in_0_bits_uop_vpu_vsew,
  input  [2:0]   io_in_0_bits_uop_vpu_vlmul,
  input          io_in_0_bits_uop_vpu_vm,
  input  [7:0]   io_in_0_bits_uop_vpu_vstart,
  input  [6:0]   io_in_0_bits_uop_vpu_vuopIdx,
  input          io_in_0_bits_uop_vpu_lastUop,
  input  [2:0]   io_in_0_bits_uop_vpu_nf,
  input  [1:0]   io_in_0_bits_uop_vpu_veew,
  input          io_in_0_bits_uop_vpu_isVleff,
  input  [7:0]   io_in_0_bits_uop_pdest,
  input          io_in_0_bits_uop_robIdx_flag,
  input  [7:0]   io_in_0_bits_uop_robIdx_value,
  input  [63:0]  io_in_0_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_0_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_0_bits_uop_debugInfo_issueTime,
  input  [127:0] io_in_0_bits_src_4,
  // 入队 port 1
  input          io_in_1_valid,
  input  [8:0]   io_in_1_bits_uop_fuOpType,
  input          io_in_1_bits_uop_vecWen,
  input          io_in_1_bits_uop_v0Wen,
  input          io_in_1_bits_uop_vlWen,
  input          io_in_1_bits_uop_vpu_vma,
  input          io_in_1_bits_uop_vpu_vta,
  input  [1:0]   io_in_1_bits_uop_vpu_vsew,
  input  [2:0]   io_in_1_bits_uop_vpu_vlmul,
  input          io_in_1_bits_uop_vpu_vm,
  input  [7:0]   io_in_1_bits_uop_vpu_vstart,
  input  [6:0]   io_in_1_bits_uop_vpu_vuopIdx,
  input          io_in_1_bits_uop_vpu_lastUop,
  input  [2:0]   io_in_1_bits_uop_vpu_nf,
  input  [1:0]   io_in_1_bits_uop_vpu_veew,
  input          io_in_1_bits_uop_vpu_isVleff,
  input  [7:0]   io_in_1_bits_uop_pdest,
  input          io_in_1_bits_uop_robIdx_flag,
  input  [7:0]   io_in_1_bits_uop_robIdx_value,
  input  [63:0]  io_in_1_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_1_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_1_bits_uop_debugInfo_issueTime,
  input  [127:0] io_in_1_bits_src_4,
  // flow 回写 0/1
  input          io_mergeUopWriteback_0_valid,
  input          io_mergeUopWriteback_0_bits_uop_exceptionVec_3,
  input          io_mergeUopWriteback_0_bits_uop_exceptionVec_4,
  input          io_mergeUopWriteback_0_bits_uop_exceptionVec_5,
  input          io_mergeUopWriteback_0_bits_uop_exceptionVec_13,
  input          io_mergeUopWriteback_0_bits_uop_exceptionVec_19,
  input          io_mergeUopWriteback_0_bits_uop_exceptionVec_21,
  input  [7:0]   io_mergeUopWriteback_0_bits_uop_vpu_vl,
  input          io_mergeUopWriteback_0_bits_uop_robIdx_flag,
  input  [7:0]   io_mergeUopWriteback_0_bits_uop_robIdx_value,
  input          io_mergeUopWriteback_1_valid,
  input          io_mergeUopWriteback_1_bits_uop_exceptionVec_3,
  input          io_mergeUopWriteback_1_bits_uop_exceptionVec_4,
  input          io_mergeUopWriteback_1_bits_uop_exceptionVec_5,
  input          io_mergeUopWriteback_1_bits_uop_exceptionVec_13,
  input          io_mergeUopWriteback_1_bits_uop_exceptionVec_19,
  input          io_mergeUopWriteback_1_bits_uop_exceptionVec_21,
  input  [7:0]   io_mergeUopWriteback_1_bits_uop_vpu_vl,
  input          io_mergeUopWriteback_1_bits_uop_robIdx_flag,
  input  [7:0]   io_mergeUopWriteback_1_bits_uop_robIdx_value,
  // 输出
  output         io_uopWriteback_valid,
  output [8:0]   io_uopWriteback_bits_uop_fuOpType,
  output         io_uopWriteback_bits_uop_vecWen,
  output         io_uopWriteback_bits_uop_v0Wen,
  output         io_uopWriteback_bits_uop_vlWen,
  output         io_uopWriteback_bits_uop_vpu_vma,
  output         io_uopWriteback_bits_uop_vpu_vta,
  output [1:0]   io_uopWriteback_bits_uop_vpu_vsew,
  output [2:0]   io_uopWriteback_bits_uop_vpu_vlmul,
  output         io_uopWriteback_bits_uop_vpu_vm,
  output [7:0]   io_uopWriteback_bits_uop_vpu_vstart,
  output [6:0]   io_uopWriteback_bits_uop_vpu_vuopIdx,
  output [7:0]   io_uopWriteback_bits_uop_vpu_vl,
  output [2:0]   io_uopWriteback_bits_uop_vpu_nf,
  output [1:0]   io_uopWriteback_bits_uop_vpu_veew,
  output [7:0]   io_uopWriteback_bits_uop_pdest,
  output         io_uopWriteback_bits_uop_robIdx_flag,
  output [7:0]   io_uopWriteback_bits_uop_robIdx_value,
  output [63:0]  io_uopWriteback_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_uopWriteback_bits_uop_debugInfo_selectTime,
  output [63:0]  io_uopWriteback_bits_uop_debugInfo_issueTime,
  output [127:0] io_uopWriteback_bits_data
);

  // ---- 单条目状态寄存器 ----
  reg  [8:0]  ent_fuOpType;
  reg         ent_vecWen;
  reg         ent_v0Wen;
  reg         ent_vlWen;
  reg         ent_vma;
  reg         ent_vta;
  reg  [1:0]  ent_vsew;
  reg  [2:0]  ent_vlmul;
  reg         ent_vm;
  reg  [7:0]  ent_vstart;
  reg  [6:0]  ent_vuopIdx;
  reg         ent_lastUop;
  reg  [2:0]  ent_nf;
  reg  [1:0]  ent_veew;
  reg         ent_isVleff;
  reg  [7:0]  ent_pdest;
  reg         ent_robIdx_flag;
  reg  [7:0]  ent_robIdx_value;
  reg  [63:0] ent_enqRsTime;
  reg  [63:0] ent_selectTime;
  reg  [63:0] ent_issueTime;
  reg  [7:0]  ent_vl;
  reg         ent_hasException;
  reg         valid;

  // ---- 入队选择: 只有 isVleff 才入队, port0 优先 ----
  wire enqIsfof_0 = io_in_0_valid & io_in_0_bits_uop_vpu_isVleff;
  wire enqValid   = enqIsfof_0 | (io_in_1_valid & io_in_1_bits_uop_vpu_isVleff);

  // 入队 uop 字段(port0 优先选择)
  wire [7:0]  enq_robIdx_value = enqIsfof_0 ? io_in_0_bits_uop_robIdx_value : io_in_1_bits_uop_robIdx_value;
  wire        enq_robIdx_flag  = enqIsfof_0 ? io_in_0_bits_uop_robIdx_flag  : io_in_1_bits_uop_robIdx_flag;
  wire        enq_lastUop      = enqIsfof_0 ? io_in_0_bits_uop_vpu_lastUop  : io_in_1_bits_uop_vpu_lastUop;
  wire        enq_isVleff      = enqIsfof_0 ? io_in_0_bits_uop_vpu_isVleff  : io_in_1_bits_uop_vpu_isVleff;

  // ---- 重定向匹配(当前条目) ----
  // {flag,value} 打包用于 flushItself 全等比较
  wire [8:0] ent_robIdx   = {ent_robIdx_flag, ent_robIdx_value};
  wire [8:0] redir_robIdx = {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value};
  // needFlush(robIdx, redirect): level 表示 flushItself(全等)|更老(flag^flag ^ value>redirValue)
  wire needRedirect =
    io_redirect_valid &
    ( (io_redirect_bits_level & (ent_robIdx == redir_robIdx))
      | (ent_robIdx_flag ^ io_redirect_bits_robIdx_flag ^ (ent_robIdx_value > io_redirect_bits_robIdx_value)) );

  // 入队候选是否被本拍重定向冲刷
  wire [8:0] enq_robIdx = {enq_robIdx_flag, enq_robIdx_value};
  wire enqNotFlushed =
    enqValid &
    ~( io_redirect_valid &
       ( (io_redirect_bits_level & (enq_robIdx == redir_robIdx))
         | (enq_robIdx_flag ^ io_redirect_bits_robIdx_flag ^ (enq_robIdx_value > io_redirect_bits_robIdx_value)) ) );

  // ---- flow 回写匹配(按 robIdx 全等) ----
  wire wbIsfof_0 =
    io_mergeUopWriteback_0_valid &
    ({io_mergeUopWriteback_0_bits_uop_robIdx_flag, io_mergeUopWriteback_0_bits_uop_robIdx_value} == ent_robIdx);
  wire wbIsfof_1 =
    io_mergeUopWriteback_1_valid &
    ({io_mergeUopWriteback_1_bits_uop_robIdx_flag, io_mergeUopWriteback_1_bits_uop_robIdx_value} == ent_robIdx);
  wire wbValid = wbIsfof_0 | wbIsfof_1;

  // 两路回写各自的异常向量聚合(6 位, 对应 exceptionVec_3/4/5/13/19/21)
  wire [5:0] wb0_exc =
    {io_mergeUopWriteback_0_bits_uop_exceptionVec_21, io_mergeUopWriteback_0_bits_uop_exceptionVec_19,
     io_mergeUopWriteback_0_bits_uop_exceptionVec_13, io_mergeUopWriteback_0_bits_uop_exceptionVec_5,
     io_mergeUopWriteback_0_bits_uop_exceptionVec_4,  io_mergeUopWriteback_0_bits_uop_exceptionVec_3};
  wire [5:0] wb1_exc =
    {io_mergeUopWriteback_1_bits_uop_exceptionVec_21, io_mergeUopWriteback_1_bits_uop_exceptionVec_19,
     io_mergeUopWriteback_1_bits_uop_exceptionVec_13, io_mergeUopWriteback_1_bits_uop_exceptionVec_5,
     io_mergeUopWriteback_1_bits_uop_exceptionVec_4,  io_mergeUopWriteback_1_bits_uop_exceptionVec_3};

  // pickWb0: 当两路都命中, 选 wb0 当"最老"的条件 =
  //   (wb0.vl > wb1.vl | wb0有异常) & ~wb1有异常; 否则只有 wb0 命中且 wb1 未命中时取 wb0。
  // (fof 语义: 更小 vl 表示更早触发异常, 但 golden 这里用 vl> 与异常存在联合判定)
  wire pickWb0 =
    (wbIsfof_0 & wbIsfof_1)
      ? ( (io_mergeUopWriteback_1_bits_uop_vpu_vl > io_mergeUopWriteback_0_bits_uop_vpu_vl | (|wb0_exc)) & ~(|wb1_exc) )
      : ( wbIsfof_0 & ~wbIsfof_1 );

  // 选中(最老)那路的异常向量与 vl
  wire [5:0] oldest_exc = pickWb0 ? wb0_exc : wb1_exc;
  wire [7:0] oldest_vl  =
    pickWb0 ? io_mergeUopWriteback_0_bits_uop_vpu_vl : io_mergeUopWriteback_1_bits_uop_vpu_vl;

  // ---- 输出 valid: 条目就绪(lastUop&isVleff)且未被重定向 ----
  wire io_uopWriteback_valid_0 = valid & ent_lastUop & ent_isVleff & ~needRedirect;

  // ---- 入队写使能: 候选未冲刷 且 (无有效条目 | 现条目已就绪可被顶替) ----
  wire doEnq = enqNotFlushed & (~valid | (valid & enq_isVleff & enq_lastUop));
  // 入队且当前无有效条目(用于 vl 初值来源: src_4 低 8 位)
  wire doEnqFresh = enqNotFlushed & ~valid;

  // ---- 时序 ----
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      ent_fuOpType     <= 9'h0;
      ent_vecWen       <= 1'h0;
      ent_v0Wen        <= 1'h0;
      ent_vlWen        <= 1'h0;
      ent_vma          <= 1'h0;
      ent_vta          <= 1'h0;
      ent_vsew         <= 2'h0;
      ent_vlmul        <= 3'h0;
      ent_vm           <= 1'h0;
      ent_vstart       <= 8'h0;
      ent_vuopIdx      <= 7'h0;
      ent_lastUop      <= 1'h0;
      ent_nf           <= 3'h0;
      ent_veew         <= 2'h0;
      ent_isVleff      <= 1'h0;
      ent_pdest        <= 8'h0;
      ent_robIdx_flag  <= 1'h0;
      ent_robIdx_value <= 8'h0;
      ent_enqRsTime    <= 64'h0;
      ent_selectTime   <= 64'h0;
      ent_issueTime    <= 64'h0;
      ent_vl           <= 8'h0;
      ent_hasException <= 1'h0;
      valid            <= 1'h0;
    end
    else begin
      // 入队: 装填 uop 字段(port0 优先)
      if (doEnq) begin
        ent_fuOpType     <= enqIsfof_0 ? io_in_0_bits_uop_fuOpType : io_in_1_bits_uop_fuOpType;
        ent_vecWen       <= enqIsfof_0 ? io_in_0_bits_uop_vecWen   : io_in_1_bits_uop_vecWen;
        ent_v0Wen        <= enqIsfof_0 ? io_in_0_bits_uop_v0Wen    : io_in_1_bits_uop_v0Wen;
        ent_vlWen        <= enqIsfof_0 ? io_in_0_bits_uop_vlWen    : io_in_1_bits_uop_vlWen;
        ent_vma          <= enqIsfof_0 ? io_in_0_bits_uop_vpu_vma  : io_in_1_bits_uop_vpu_vma;
        ent_vta          <= enqIsfof_0 ? io_in_0_bits_uop_vpu_vta  : io_in_1_bits_uop_vpu_vta;
        ent_vsew         <= enqIsfof_0 ? io_in_0_bits_uop_vpu_vsew : io_in_1_bits_uop_vpu_vsew;
        ent_vlmul        <= enqIsfof_0 ? io_in_0_bits_uop_vpu_vlmul: io_in_1_bits_uop_vpu_vlmul;
        ent_vm           <= enqIsfof_0 ? io_in_0_bits_uop_vpu_vm   : io_in_1_bits_uop_vpu_vm;
        ent_vstart       <= enqIsfof_0 ? io_in_0_bits_uop_vpu_vstart : io_in_1_bits_uop_vpu_vstart;
        ent_vuopIdx      <= enqIsfof_0 ? io_in_0_bits_uop_vpu_vuopIdx : io_in_1_bits_uop_vpu_vuopIdx;
        ent_lastUop      <= enq_lastUop;
        ent_nf           <= enqIsfof_0 ? io_in_0_bits_uop_vpu_nf   : io_in_1_bits_uop_vpu_nf;
        ent_veew         <= enqIsfof_0 ? io_in_0_bits_uop_vpu_veew : io_in_1_bits_uop_vpu_veew;
        ent_isVleff      <= enq_isVleff;
        ent_pdest        <= enqIsfof_0 ? io_in_0_bits_uop_pdest    : io_in_1_bits_uop_pdest;
        ent_robIdx_flag  <= enq_robIdx_flag;
        ent_robIdx_value <= enq_robIdx_value;
        ent_enqRsTime    <= enqIsfof_0 ? io_in_0_bits_uop_debugInfo_enqRsTime  : io_in_1_bits_uop_debugInfo_enqRsTime;
        ent_selectTime   <= enqIsfof_0 ? io_in_0_bits_uop_debugInfo_selectTime : io_in_1_bits_uop_debugInfo_selectTime;
        ent_issueTime    <= enqIsfof_0 ? io_in_0_bits_uop_debugInfo_issueTime  : io_in_1_bits_uop_debugInfo_issueTime;
      end
      // vl / hasException 更新: 回写命中且(更小 vl 或带异常)且条目有效未冲刷未已异常 → 记录最老 flow 的 vl/异常;
      // 否则若本拍新装填空条目 → vl 取 src_4[7:0], hasException 清 0(除非保留)。
      if (wbValid & ((oldest_vl < ent_vl) | (|oldest_exc)) & valid & ~needRedirect & ~ent_hasException) begin
        ent_vl           <= oldest_vl;
        ent_hasException <= |oldest_exc;
      end
      else begin
        if (doEnqFresh)
          ent_vl <= enqIsfof_0 ? io_in_0_bits_src_4[7:0] : io_in_1_bits_src_4[7:0];
        ent_hasException <= ~doEnqFresh & ent_hasException;
      end
      // valid: 输出或被冲刷则清, 否则入队或保持
      valid <= ~(io_uopWriteback_valid_0 | needRedirect) & (enqNotFlushed | valid);
    end
  end

  // ---- 输出 ----
  assign io_uopWriteback_valid                        = io_uopWriteback_valid_0;
  assign io_uopWriteback_bits_uop_fuOpType            = ent_fuOpType;
  assign io_uopWriteback_bits_uop_vecWen              = ent_vecWen;
  assign io_uopWriteback_bits_uop_v0Wen               = ent_v0Wen;
  assign io_uopWriteback_bits_uop_vlWen               = ent_vlWen;
  assign io_uopWriteback_bits_uop_vpu_vma             = ent_vma;
  assign io_uopWriteback_bits_uop_vpu_vta             = ent_vta;
  assign io_uopWriteback_bits_uop_vpu_vsew            = ent_vsew;
  assign io_uopWriteback_bits_uop_vpu_vlmul           = ent_vlmul;
  assign io_uopWriteback_bits_uop_vpu_vm              = ent_vm;
  assign io_uopWriteback_bits_uop_vpu_vstart          = ent_vstart;
  assign io_uopWriteback_bits_uop_vpu_vuopIdx         = ent_vuopIdx;
  assign io_uopWriteback_bits_uop_vpu_vl              = ent_vl;
  assign io_uopWriteback_bits_uop_vpu_nf              = ent_nf;
  assign io_uopWriteback_bits_uop_vpu_veew            = ent_veew;
  assign io_uopWriteback_bits_uop_pdest               = ent_pdest;
  assign io_uopWriteback_bits_uop_robIdx_flag         = ent_robIdx_flag;
  assign io_uopWriteback_bits_uop_robIdx_value        = ent_robIdx_value;
  assign io_uopWriteback_bits_uop_debugInfo_enqRsTime = ent_enqRsTime;
  assign io_uopWriteback_bits_uop_debugInfo_selectTime= ent_selectTime;
  assign io_uopWriteback_bits_uop_debugInfo_issueTime = ent_issueTime;
  assign io_uopWriteback_bits_data                    = {120'h0, ent_vl};

endmodule
