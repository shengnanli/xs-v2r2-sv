// =============================================================================
// ExceptionGen.sv —— ROB 的异常收集器：在所有"带异常的指令"里挑出最老的那一条，交给 ROB 提交时处理
//
// 位置：Rob 的子模块。输入两路来源：
//   * enq：重命名后进 ROB 的 6 条指令里，前端 / 译码阶段就已经知道有异常的（取指异常、单步、断点、
//     flushPipe 等）；
//   * wb ：执行单元写回时报的异常，分 5 组：csr（wb0）、load（wb8..10）、store（wb6、wb7）、
//     向量运算（wb1、wb2）、向量访存（wb11、wb12）。wb3..5 在本配置里没有异常来源，端口只剩
//     robIdx 且未被使用（golden 如此）。
//   输出 state：当前记住的最老异常（currentValid + current）。golden 里 Scala 的 io.out 没有负载，
//   已被 firtool 删掉，本文件不实现。
//   Scala：src/main/scala/xiangshan/backend/rob/ExceptionGen.scala，
//          RobExceptionInfo 在 rob/RobBundles.scala。
//
// "最老"：robIdx 是带翻转位的环形指针，a 比 b 年轻（isAfter）= a.flag ^ b.flag ^ (a.value > b.value)。
//   robIdx 相同（同一条指令拆出的多个向量 uop）时再比 vuopIdx，小的更老。
//   被 redirect / flush 冲掉的指令（needFlush）一律不算。
//
// 流水（全部在一拍里完成"比较 + 寄存"）：
//   §1 s0：每个 wb 组内选最老（getOldest），本拍被冲掉的不算有效；结果寄存成 s0_out（组 × 1 份）。
//   §2 s1：5 组的 s0_out 再选最老（选的时候看 s0 的有效位；本拍被冲掉的组不进 s1 的有效位），寄存成
//          s1_out；enq 侧 6 条按优先级（下标小的先）选第一条有异常的，寄存成 enq_s1。
//   §3 current：已有 current 时，被冲掉就换成 s1（或清空）；s1 比 current 老就整条替换，同一条指令就
//          合并（异常向量按 vstart 小的那个，标志位取或）；没有 current 时先收 s1，再收 enq。
//
// 怪癖（照 golden，不"修"）：
//   1. 各 wb 组只带自己会产生的字段（csr 组没有 trigger、向量运算组只有异常位等），寄存器也只按这些
//      字段建（每组的 s0_out 字段集合 = golden 的寄存器表）；但异常向量 24 位每组都建满，没有来源的位
//      恒写 0（Chisel 的 Vec 整体保留）。没有的字段按父模块接的常量处理：trigger 是 None（4'hF），
//      其余都是 0。
//   2. s1_out 不带 vuopIdx：s1 之后不再需要比 uop 序号。
//   3. 组内"选最老"的有效位用的是 in_wb_valids（不看本拍 redirect），而组的 s0 有效位要再去掉被冲掉的；
//      s1 选最老用 s0_out_valid（同样不看本拍冲刷），s1 的有效位才去掉被冲掉的。
//   4. 从 wb 来的异常没有取指信息（ftqPtr / ftqOffset / isFetchMalAddr / isVset / singleStep 等恒 0），
//      s1 整条替换 current 时这些字段被写成 0。
// 本文件导航（共 1520 行；wrapper 端口多，按"一个 golden 模块一个文件"不拆分）：
//   L45    包 exceptiongen_pkg：指针比较、结构体、两两比较函数
//   L199   xs_ExceptionGenWbGroup：一个写回组（组内选最老 + s0 寄存）
//   L404   核 §1 s0：五个写回组
//   L442   核 §2 s1：五组选最老 / enq 选第一条
//   L508   核 §3 current 的更新
//   L581   golden 同名 wrapper（生成区，scripts/gen_exceptiongen.py）
//
// =============================================================================

package exceptiongen_pkg;
  // ROB 指针：翻转位 + 160 项里的下标
  typedef struct packed {
    logic       flag;
    logic [7:0] value;
  } rob_ptr_t;

  // a 比 b 年轻（在 b 之后进的 ROB）
  function automatic logic is_after(input rob_ptr_t a, input rob_ptr_t b);
    return a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

  // 被本拍的 redirect / flush 冲掉：redirect 要冲 ptr 之后的指令，level=1（flushItself）时连 ptr 自己
  function automatic logic need_flush(input rob_ptr_t ptr, input logic redirect_valid,
                                      input rob_ptr_t redirect_ptr, input logic redirect_level,
                                      input logic flush);
    return (redirect_valid & ((redirect_level & (ptr == redirect_ptr)) | is_after(ptr, redirect_ptr))) | flush;
  endfunction

  // 写回侧的异常信息（RobExceptionInfo 里写回会带的字段；vuopIdx 单独走，见怪癖 2）
  typedef struct packed {
    rob_ptr_t    rob_idx;
    logic        has_exception;
    logic [23:0] exception_vec;
    logic        flush_pipe;
    logic        satp_flush_pipe;
    logic        replay_inst;
    logic [3:0]  trigger;
    logic        vstart_en;
    logic [63:0] vstart;
    logic        is_vec_load;
    logic        is_vlm;
    logic        is_strided;
    logic        is_indexed;
    logic        is_whole;
    logic [2:0]  nf;
    logic [1:0]  vsew;
    logic [1:0]  veew;
    logic [2:0]  vlmul;
  } wb_excp_t;

  // enq 侧的异常信息：前端 / 译码阶段能知道的那些。异常向量只有 7 个位会在这里出现
  localparam int unsigned ENQ_EV_NUM = 7;
  localparam int unsigned ENQ_EV_IDX [ENQ_EV_NUM] = '{0, 1, 2, 3, 12, 20, 22};
  typedef struct packed {
    rob_ptr_t                rob_idx;
    logic [5:0]              ftq_ptr;
    logic [3:0]              ftq_offset;
    logic                    has_exception;
    logic [ENQ_EV_NUM-1:0]   exception_vec;     // 第 k 位 = 异常向量第 ENQ_EV_IDX[k] 位
    logic                    is_fetch_mal_addr;
    logic                    satp_flush_first_fetch_fault;
    logic                    flush_pipe;
    logic                    is_vset;
    logic                    single_step;
    logic                    cross_page_ipf_fix;
    logic [3:0]              trigger;
  } enq_excp_t;

  // current（ROB 记住的那条异常）：RobExceptionInfo 除 vuopIdx 以外的全部字段
  typedef struct packed {
    rob_ptr_t    rob_idx;
    logic [5:0]  ftq_ptr;
    logic [3:0]  ftq_offset;
    logic        has_exception;
    logic        is_enq_excp;          // 1 = 来自 enq（取指 / 译码异常），0 = 来自写回
    logic [23:0] exception_vec;
    logic        is_fetch_mal_addr;
    logic        satp_flush_first_fetch_fault;
    logic        flush_pipe;
    logic        satp_flush_pipe;
    logic        is_vset;
    logic        replay_inst;
    logic        single_step;
    logic        cross_page_ipf_fix;
    logic [3:0]  trigger;
    logic        vstart_en;
    logic [63:0] vstart;
    logic        is_vec_load;
    logic        is_vlm;
    logic        is_strided;
    logic        is_indexed;
    logic        is_whole;
    logic [2:0]  nf;
    logic [1:0]  vsew;
    logic [1:0]  veew;
    logic [2:0]  vlmul;
  } excp_state_t;

  // 写回来的异常整条变成 current：取指类字段写 0（怪癖 4）
  function automatic excp_state_t state_from_wb(input wb_excp_t w);
    excp_state_t s;
    s               = '0;
    s.rob_idx       = w.rob_idx;
    s.has_exception = w.has_exception;
    s.exception_vec = w.exception_vec;
    s.flush_pipe    = w.flush_pipe;
    s.satp_flush_pipe = w.satp_flush_pipe;
    s.replay_inst   = w.replay_inst;
    s.trigger       = w.trigger;
    s.vstart_en     = w.vstart_en;
    s.vstart        = w.vstart;
    s.is_vec_load   = w.is_vec_load;
    s.is_vlm        = w.is_vlm;
    s.is_strided    = w.is_strided;
    s.is_indexed    = w.is_indexed;
    s.is_whole      = w.is_whole;
    s.nf            = w.nf;
    s.vsew          = w.vsew;
    s.veew          = w.veew;
    s.vlmul         = w.vlmul;
    return s;
  endfunction

  // enq 来的异常整条变成 current：向量 / 写回类字段写 0
  function automatic excp_state_t state_from_enq(input enq_excp_t e);
    excp_state_t s;
    s                              = '0;
    s.rob_idx                      = e.rob_idx;
    s.ftq_ptr                      = e.ftq_ptr;
    s.ftq_offset                   = e.ftq_offset;
    s.has_exception                = e.has_exception;
    for (int k = 0; k < ENQ_EV_NUM; k++) s.exception_vec[ENQ_EV_IDX[k]] = e.exception_vec[k];
    s.is_fetch_mal_addr            = e.is_fetch_mal_addr;
    s.satp_flush_first_fetch_fault = e.satp_flush_first_fetch_fault;
    s.flush_pipe                   = e.flush_pipe;
    s.is_vset                      = e.is_vset;
    s.single_step                  = e.single_step;
    s.cross_page_ipf_fix           = e.cross_page_ipf_fix;
    s.trigger                      = e.trigger;
    return s;
  endfunction

  // TriggerAction：1 = 断点要进调试模式（isDmode）；15 = 没有断点动作（None）
  localparam logic [3:0] TRIGGER_DMODE = 4'h1;
  localparam logic [3:0] TRIGGER_NONE  = 4'hF;

  // RobExceptionInfo.has_exception：这条指令要走异常 / 冲刷流程
  function automatic logic wb_has_exception(input wb_excp_t e);
    return e.has_exception | e.flush_pipe | e.replay_inst | (e.trigger == TRIGGER_DMODE);
  endfunction
  function automatic logic enq_has_exception(input enq_excp_t e);
    return e.has_exception | e.flush_pipe | e.single_step | (e.trigger == TRIGGER_DMODE);
  endfunction

  // getOldest 的两两比较：留下 0 号的条件 = 1 号无效，或 0 号有效且 1 号更年轻（同指令时 uop 序号更大）
  function automatic logic keep_first(input logic valid0, input rob_ptr_t idx0, input logic [6:0] uop0,
                                      input logic valid1, input rob_ptr_t idx1, input logic [6:0] uop1);
    return ~valid1 | (valid0 & (is_after(idx1, idx0) | ((idx1 == idx0) & (uop1 > uop0))));
  endfunction
endpackage

// -----------------------------------------------------------------------------
// 一个写回组：组内选最老 + s0 寄存。
// 参数指明本组写回会带哪些字段（怪癖 1）；不带的字段不建寄存器、输出恒 0。
// -----------------------------------------------------------------------------
module xs_ExceptionGenWbGroup
  import exceptiongen_pkg::*;
#(
  parameter int unsigned N           = 2,     // 本组写回口数（1 / 2 / 3）
  parameter bit          HAS_FLUSH   = 1'b1,  // flushPipe
  parameter bit          HAS_SATP    = 1'b0,  // satpFlushPipe
  parameter bit          HAS_REPLAY  = 1'b0,  // replayInst
  parameter bit          HAS_TRIGGER = 1'b0,  // trigger
  parameter bit          HAS_VEC     = 1'b0   // 向量访存字段（vstart、访存类型、宽度等）与 vuopIdx
) (
  input  logic                  clock,
  input  logic                  last_cycle_flush,
  input  logic                  redirect_valid,
  input  rob_ptr_t              redirect_ptr,
  input  logic                  redirect_level,
  input  logic                  flush,
  input  logic [N-1:0]          wb_valid,
  input  wb_excp_t [N-1:0]      wb_bits,
  input  logic [N-1:0][6:0]     wb_vuop,
  output logic                  s0_valid,
  output wb_excp_t              s0_bits,
  output logic [6:0]            s0_vuop
);
  // ---- 本拍：哪些口带着异常进来（上一拍有 flush 的不收）；其中哪些没被本拍冲掉 ----
  logic [N-1:0] in_valid;
  logic [N-1:0] alive;
  for (genvar i = 0; i < N; i++) begin : g_in
    assign in_valid[i] = wb_valid[i] & wb_has_exception(wb_bits[i]) & ~last_cycle_flush;
    assign alive[i]    = in_valid[i] & ~need_flush(wb_bits[i].rob_idx, redirect_valid, redirect_ptr,
                                                   redirect_level, flush);
  end

  // ---- 组内选最老（Scala getOldest 的递归形状：3 个时先比后两个，再和第一个比；比较看 in_valid）----
  wb_excp_t   oldest;
  logic [6:0] oldest_vuop;
  if (N == 1) begin : g_one
    assign oldest      = wb_bits[0];
    assign oldest_vuop = wb_vuop[0];
  end else if (N == 2) begin : g_two
    logic keep0;
    assign keep0       = keep_first(in_valid[0], wb_bits[0].rob_idx, wb_vuop[0],
                                    in_valid[1], wb_bits[1].rob_idx, wb_vuop[1]);
    assign oldest      = keep0 ? wb_bits[0] : wb_bits[1];
    assign oldest_vuop = keep0 ? wb_vuop[0] : wb_vuop[1];
  end else begin : g_three
    logic       keep1, keep0, right_valid;
    wb_excp_t   right;
    logic [6:0] right_vuop;
    assign keep1       = keep_first(in_valid[1], wb_bits[1].rob_idx, wb_vuop[1],
                                    in_valid[2], wb_bits[2].rob_idx, wb_vuop[2]);
    assign right_valid = keep1 ? in_valid[1] : in_valid[2];
    assign right       = keep1 ? wb_bits[1] : wb_bits[2];
    assign right_vuop  = keep1 ? wb_vuop[1] : wb_vuop[2];
    assign keep0       = keep_first(in_valid[0], wb_bits[0].rob_idx, wb_vuop[0],
                                    right_valid, right.rob_idx, right_vuop);
    assign oldest      = keep0 ? wb_bits[0] : right;
    assign oldest_vuop = keep0 ? wb_vuop[0] : right_vuop;
  end

  // ---- s0 寄存：有效位每拍打一拍；内容在本组有活的异常时更新（都不复位）----
  logic group_alive;
  assign group_alive = |alive;
  always_ff @(posedge clock) begin
    s0_valid <= group_alive;
  end

  // 每组都有的字段：robIdx、hasException、24 位异常向量
  rob_ptr_t    rob_idx_q;
  logic        has_exception_q;
  logic [23:0] exception_vec_q;
  always_ff @(posedge clock) begin
    if (group_alive) begin
      rob_idx_q       <= oldest.rob_idx;
      has_exception_q <= oldest.has_exception;
      exception_vec_q <= oldest.exception_vec;
    end
  end

  // 按组才有的字段：不带的保持 0、不建寄存器
  logic        flush_pipe, satp_flush_pipe, replay_inst;
  logic [3:0]  trigger;
  if (HAS_FLUSH) begin : g_flush
    logic flush_pipe_q;
    always_ff @(posedge clock) if (group_alive) flush_pipe_q <= oldest.flush_pipe;
    assign flush_pipe = flush_pipe_q;
  end else begin : g_no_flush
    assign flush_pipe = 1'b0;
  end
  if (HAS_SATP) begin : g_satp
    logic satp_flush_pipe_q;
    always_ff @(posedge clock) if (group_alive) satp_flush_pipe_q <= oldest.satp_flush_pipe;
    assign satp_flush_pipe = satp_flush_pipe_q;
  end else begin : g_no_satp
    assign satp_flush_pipe = 1'b0;
  end
  if (HAS_REPLAY) begin : g_replay
    logic replay_inst_q;
    always_ff @(posedge clock) if (group_alive) replay_inst_q <= oldest.replay_inst;
    assign replay_inst = replay_inst_q;
  end else begin : g_no_replay
    assign replay_inst = 1'b0;
  end
  if (HAS_TRIGGER) begin : g_trigger
    logic [3:0] trigger_q;
    always_ff @(posedge clock) if (group_alive) trigger_q <= oldest.trigger;
    assign trigger = trigger_q;
  end else begin : g_no_trigger
    assign trigger = TRIGGER_NONE;      // 不带 trigger 的组：父模块给的是 None（15），不是 0
  end

  logic        vstart_en, is_vec_load, is_vlm, is_strided, is_indexed, is_whole;
  logic [63:0] vstart;
  logic [2:0]  nf, vlmul;
  logic [1:0]  vsew, veew;
  if (HAS_VEC) begin : g_vec
    logic        vstart_en_q, is_vec_load_q, is_vlm_q, is_strided_q, is_indexed_q, is_whole_q;
    logic [63:0] vstart_q;
    logic [2:0]  nf_q, vlmul_q;
    logic [1:0]  vsew_q, veew_q;
    logic [6:0]  vuop_q;
    always_ff @(posedge clock) begin
      if (group_alive) begin
        vstart_en_q   <= oldest.vstart_en;
        vstart_q      <= oldest.vstart;
        is_vec_load_q <= oldest.is_vec_load;
        is_vlm_q      <= oldest.is_vlm;
        is_strided_q  <= oldest.is_strided;
        is_indexed_q  <= oldest.is_indexed;
        is_whole_q    <= oldest.is_whole;
        nf_q          <= oldest.nf;
        vsew_q        <= oldest.vsew;
        veew_q        <= oldest.veew;
        vlmul_q       <= oldest.vlmul;
        vuop_q        <= oldest_vuop;
      end
    end
    assign {vstart_en, vstart, is_vec_load, is_vlm, is_strided, is_indexed, is_whole, nf, vsew, veew, vlmul}
         = {vstart_en_q, vstart_q, is_vec_load_q, is_vlm_q, is_strided_q, is_indexed_q, is_whole_q,
            nf_q, vsew_q, veew_q, vlmul_q};
    assign s0_vuop = vuop_q;
  end else begin : g_no_vec
    assign {vstart_en, vstart, is_vec_load, is_vlm, is_strided, is_indexed, is_whole, nf, vsew, veew, vlmul} = '0;
    assign s0_vuop = 7'h0;
  end

  always_comb begin
    s0_bits                 = '0;
    s0_bits.rob_idx         = rob_idx_q;
    s0_bits.has_exception   = has_exception_q;
    s0_bits.exception_vec   = exception_vec_q;
    s0_bits.flush_pipe      = flush_pipe;
    s0_bits.satp_flush_pipe = satp_flush_pipe;
    s0_bits.replay_inst     = replay_inst;
    s0_bits.trigger         = trigger;
    s0_bits.vstart_en       = vstart_en;
    s0_bits.vstart          = vstart;
    s0_bits.is_vec_load     = is_vec_load;
    s0_bits.is_vlm          = is_vlm;
    s0_bits.is_strided      = is_strided;
    s0_bits.is_indexed      = is_indexed;
    s0_bits.is_whole        = is_whole;
    s0_bits.nf              = nf;
    s0_bits.vsew            = vsew;
    s0_bits.veew            = veew;
    s0_bits.vlmul           = vlmul;
  end
endmodule

module xs_ExceptionGen_core
  import exceptiongen_pkg::*;
(
  input  logic                clock,
  input  logic                reset,
  input  logic                redirect_valid,
  input  rob_ptr_t            redirect_ptr,
  input  logic                redirect_level,
  input  logic                flush,
  input  logic [5:0]          enq_valid,
  input  enq_excp_t [5:0]     enq_bits,
  // 写回五组：csr / load / store / 向量运算 / 向量访存（组号 0..4 = s1 选最老时的顺序）
  input  logic [0:0]          csr_valid,
  input  wb_excp_t [0:0]      csr_bits,
  input  logic [2:0]          load_valid,
  input  wb_excp_t [2:0]      load_bits,
  input  logic [1:0]          store_valid,
  input  wb_excp_t [1:0]      store_bits,
  input  logic [1:0]          varith_valid,
  input  wb_excp_t [1:0]      varith_bits,
  input  logic [1:0]          vls_valid,
  input  wb_excp_t [1:0]      vls_bits,
  input  logic [1:0][6:0]     vls_vuop,
  output logic                state_valid,
  output excp_state_t         state
);
  localparam int unsigned NUM_GROUP = 5;

  logic last_cycle_flush;   // 上一拍有 flush：本拍进来的异常一律不收
  always_ff @(posedge clock) begin
    last_cycle_flush <= flush;
  end

  // ===========================================================================
  // §1 s0：每个写回组内选最老并寄存
  // ===========================================================================
  logic [NUM_GROUP-1:0]            s0_valid;
  wb_excp_t [NUM_GROUP-1:0]        s0_bits;
  logic [NUM_GROUP-1:0][6:0]       s0_vuop;

  xs_ExceptionGenWbGroup #(.N(1), .HAS_FLUSH(1), .HAS_SATP(1)) u_csr (
    .clock (clock), .last_cycle_flush (last_cycle_flush), .redirect_valid (redirect_valid),
    .redirect_ptr (redirect_ptr), .redirect_level (redirect_level), .flush (flush),
    .wb_valid (csr_valid), .wb_bits (csr_bits), .wb_vuop ('0),
    .s0_valid (s0_valid[0]), .s0_bits (s0_bits[0]), .s0_vuop (s0_vuop[0])
  );
  xs_ExceptionGenWbGroup #(.N(3), .HAS_FLUSH(1), .HAS_REPLAY(1), .HAS_TRIGGER(1)) u_load (
    .clock (clock), .last_cycle_flush (last_cycle_flush), .redirect_valid (redirect_valid),
    .redirect_ptr (redirect_ptr), .redirect_level (redirect_level), .flush (flush),
    .wb_valid (load_valid), .wb_bits (load_bits), .wb_vuop ('0),
    .s0_valid (s0_valid[1]), .s0_bits (s0_bits[1]), .s0_vuop (s0_vuop[1])
  );
  xs_ExceptionGenWbGroup #(.N(2), .HAS_FLUSH(1), .HAS_TRIGGER(1)) u_store (
    .clock (clock), .last_cycle_flush (last_cycle_flush), .redirect_valid (redirect_valid),
    .redirect_ptr (redirect_ptr), .redirect_level (redirect_level), .flush (flush),
    .wb_valid (store_valid), .wb_bits (store_bits), .wb_vuop ('0),
    .s0_valid (s0_valid[2]), .s0_bits (s0_bits[2]), .s0_vuop (s0_vuop[2])
  );
  xs_ExceptionGenWbGroup #(.N(2), .HAS_FLUSH(0)) u_varith (
    .clock (clock), .last_cycle_flush (last_cycle_flush), .redirect_valid (redirect_valid),
    .redirect_ptr (redirect_ptr), .redirect_level (redirect_level), .flush (flush),
    .wb_valid (varith_valid), .wb_bits (varith_bits), .wb_vuop ('0),
    .s0_valid (s0_valid[3]), .s0_bits (s0_bits[3]), .s0_vuop (s0_vuop[3])
  );
  xs_ExceptionGenWbGroup #(.N(2), .HAS_FLUSH(1), .HAS_REPLAY(1), .HAS_TRIGGER(1), .HAS_VEC(1)) u_vls (
    .clock (clock), .last_cycle_flush (last_cycle_flush), .redirect_valid (redirect_valid),
    .redirect_ptr (redirect_ptr), .redirect_level (redirect_level), .flush (flush),
    .wb_valid (vls_valid), .wb_bits (vls_bits), .wb_vuop (vls_vuop),
    .s0_valid (s0_valid[4]), .s0_bits (s0_bits[4]), .s0_vuop (s0_vuop[4])
  );

  // ===========================================================================
  // §2 s1：五组再选最老（getOldest 形状：[0,1] 一边，[2,[3,4]] 一边）；enq 按优先级选第一条
  // ===========================================================================
  logic [NUM_GROUP-1:0] s1_alive;   // 本拍没被冲掉的组
  for (genvar g = 0; g < NUM_GROUP; g++) begin : g_s1_alive
    assign s1_alive[g] = s0_valid[g] & ~need_flush(s0_bits[g].rob_idx, redirect_valid, redirect_ptr,
                                                   redirect_level, flush);
  end

  wb_excp_t s1_oldest;
  always_comb begin
    logic       keep, left_valid, right_valid, rr_valid;
    wb_excp_t   left, right, rr;
    logic [6:0] left_vuop, right_vuop, rr_vuop;
    // 左：组 0 vs 组 1
    keep       = keep_first(s0_valid[0], s0_bits[0].rob_idx, s0_vuop[0], s0_valid[1], s0_bits[1].rob_idx, s0_vuop[1]);
    left       = keep ? s0_bits[0] : s0_bits[1];
    left_valid = keep ? s0_valid[0] : s0_valid[1];
    left_vuop  = keep ? s0_vuop[0] : s0_vuop[1];
    // 右的右：组 3 vs 组 4
    keep       = keep_first(s0_valid[3], s0_bits[3].rob_idx, s0_vuop[3], s0_valid[4], s0_bits[4].rob_idx, s0_vuop[4]);
    rr         = keep ? s0_bits[3] : s0_bits[4];
    rr_valid   = keep ? s0_valid[3] : s0_valid[4];
    rr_vuop    = keep ? s0_vuop[3] : s0_vuop[4];
    // 右：组 2 vs 上面
    keep        = keep_first(s0_valid[2], s0_bits[2].rob_idx, s0_vuop[2], rr_valid, rr.rob_idx, rr_vuop);
    right       = keep ? s0_bits[2] : rr;
    right_valid = keep ? s0_valid[2] : rr_valid;
    right_vuop  = keep ? s0_vuop[2] : rr_vuop;
    // 左右再比
    keep      = keep_first(left_valid, left.rob_idx, left_vuop, right_valid, right.rob_idx, right_vuop);
    s1_oldest = keep ? left : right;
  end

  logic     s1_valid;
  wb_excp_t s1_bits;    // 不带 vuopIdx（怪癖 2）
  always_ff @(posedge clock) begin
    s1_valid <= |s1_alive;
    if (|s1_alive) begin
      s1_bits <= s1_oldest;
    end
  end

  // enq：6 条里第一条（下标小者优先）有异常的；enq 的 flushPipe 只在没有真异常时保留
  logic [5:0] enq_has;
  enq_excp_t  enq_first;
  logic       enq_take;
  always_comb begin
    enq_first = enq_bits[5];
    for (int i = 5; i >= 0; i--) begin
      enq_has[i] = enq_valid[i] & enq_has_exception(enq_bits[i]) & ~last_cycle_flush;
      if (enq_has[i]) enq_first = enq_bits[i];
    end
    enq_first.flush_pipe = enq_first.flush_pipe & ~enq_first.has_exception;
  end
  assign enq_take = (|enq_has) & ~redirect_valid & ~flush;

  logic      enq_s1_valid;
  enq_excp_t enq_s1_bits;
  always_ff @(posedge clock) begin
    enq_s1_valid <= enq_take;
    if (enq_take) begin
      enq_s1_bits <= enq_first;
    end
  end

  // ===========================================================================
  // §3 current：ROB 记住的最老异常
  // ===========================================================================
  excp_state_t current;
  logic        current_valid;
  logic        current_flushed, s1_flushed, s1_usable, s1_older, s1_same, vec_update;
  assign current_flushed = need_flush(current.rob_idx, redirect_valid, redirect_ptr, redirect_level, flush);
  assign s1_flushed      = need_flush(s1_bits.rob_idx, redirect_valid, redirect_ptr, redirect_level, flush);
  assign s1_usable       = s1_valid & ~s1_flushed;
  assign s1_older        = is_after(current.rob_idx, s1_bits.rob_idx);
  assign s1_same         = (current.rob_idx == s1_bits.rob_idx);
  // 同一条指令（向量访存的多个 uop）：vstart 更小的那个异常优先，或者 current 还没有 vstart
  assign vec_update      = (s1_bits.vstart < current.vstart) | ~current.vstart_en;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      current_valid <= 1'b0;
    end else if (current_valid) begin
      if (current_flushed) current_valid <= s1_flushed ? 1'b0 : s1_valid;
    end else if (s1_usable | (enq_s1_valid & ~(redirect_valid | flush))) begin
      current_valid <= 1'b1;
    end
  end

  excp_state_t s1_state, merged;
  assign s1_state = state_from_wb(s1_bits);
  always_comb begin
    merged = current;
    if (vec_update) begin
      merged.exception_vec = s1_bits.exception_vec;
      merged.has_exception = s1_bits.has_exception;
      merged.trigger       = s1_bits.trigger;
      merged.vstart        = s1_bits.vstart;
      merged.vstart_en     = s1_bits.vstart_en;
      merged.is_vec_load   = s1_bits.is_vec_load;
      merged.is_vlm        = s1_bits.is_vlm;
      merged.is_strided    = s1_bits.is_strided;
      merged.is_indexed    = s1_bits.is_indexed;
      merged.is_whole      = s1_bits.is_whole;
      merged.nf            = s1_bits.nf;
      merged.vsew          = s1_bits.vsew;
      merged.veew          = s1_bits.veew;
      merged.vlmul         = s1_bits.vlmul;
    end
    merged.flush_pipe      = (s1_bits.flush_pipe | current.flush_pipe) & ~(|s1_bits.exception_vec);
    merged.satp_flush_pipe = s1_bits.satp_flush_pipe | current.satp_flush_pipe;
    merged.replay_inst     = s1_bits.replay_inst | current.replay_inst;
    merged.single_step     = current.single_step;   // 写回不带 singleStep（恒 0），取或等于保持
    merged.is_enq_excp     = 1'b0;
  end

  always_ff @(posedge clock) begin
    if (current_valid) begin
      if (s1_usable) begin
        if (s1_older) begin
          current             <= s1_state;    // 写回的异常更老：整条替换
          current.is_enq_excp <= 1'b0;
        end else if (s1_same) begin
          current             <= merged;      // 同一条指令：合并
        end
      end
    end else if (s1_usable) begin
      current             <= s1_state;
      current.is_enq_excp <= 1'b0;
    end else if (enq_s1_valid & ~(redirect_valid | flush)) begin
      current             <= state_from_enq(enq_s1_bits);
      current.is_enq_excp <= 1'b1;
    end
  end

  assign state_valid = current_valid;
  assign state       = current;
endmodule

// BEGIN GENERATED(exceptiongen_wrapper) —— scripts/gen_exceptiongen.py，勿手改
module ExceptionGen (
  input  clock,
  input  reset,
  input  io_redirect_valid,
  input  io_redirect_bits_robIdx_flag,
  input  [7:0] io_redirect_bits_robIdx_value,
  input  io_redirect_bits_level,
  input  io_flush,
  input  io_enq_0_valid,
  input  io_enq_0_bits_robIdx_flag,
  input  [7:0] io_enq_0_bits_robIdx_value,
  input  [5:0] io_enq_0_bits_ftqPtr_value,
  input  [3:0] io_enq_0_bits_ftqOffset,
  input  io_enq_0_bits_hasException,
  input  io_enq_0_bits_exceptionVec_0,
  input  io_enq_0_bits_exceptionVec_1,
  input  io_enq_0_bits_exceptionVec_2,
  input  io_enq_0_bits_exceptionVec_3,
  input  io_enq_0_bits_exceptionVec_12,
  input  io_enq_0_bits_exceptionVec_20,
  input  io_enq_0_bits_exceptionVec_22,
  input  io_enq_0_bits_isFetchMalAddr,
  input  io_enq_0_bits_satpFlushFirstFetchFault,
  input  io_enq_0_bits_flushPipe,
  input  io_enq_0_bits_isVset,
  input  io_enq_0_bits_singleStep,
  input  io_enq_0_bits_crossPageIPFFix,
  input  [3:0] io_enq_0_bits_trigger,
  input  io_enq_1_valid,
  input  io_enq_1_bits_robIdx_flag,
  input  [7:0] io_enq_1_bits_robIdx_value,
  input  [5:0] io_enq_1_bits_ftqPtr_value,
  input  [3:0] io_enq_1_bits_ftqOffset,
  input  io_enq_1_bits_hasException,
  input  io_enq_1_bits_exceptionVec_0,
  input  io_enq_1_bits_exceptionVec_1,
  input  io_enq_1_bits_exceptionVec_2,
  input  io_enq_1_bits_exceptionVec_3,
  input  io_enq_1_bits_exceptionVec_12,
  input  io_enq_1_bits_exceptionVec_20,
  input  io_enq_1_bits_exceptionVec_22,
  input  io_enq_1_bits_isFetchMalAddr,
  input  io_enq_1_bits_satpFlushFirstFetchFault,
  input  io_enq_1_bits_flushPipe,
  input  io_enq_1_bits_isVset,
  input  io_enq_1_bits_singleStep,
  input  io_enq_1_bits_crossPageIPFFix,
  input  [3:0] io_enq_1_bits_trigger,
  input  io_enq_2_valid,
  input  io_enq_2_bits_robIdx_flag,
  input  [7:0] io_enq_2_bits_robIdx_value,
  input  [5:0] io_enq_2_bits_ftqPtr_value,
  input  [3:0] io_enq_2_bits_ftqOffset,
  input  io_enq_2_bits_hasException,
  input  io_enq_2_bits_exceptionVec_0,
  input  io_enq_2_bits_exceptionVec_1,
  input  io_enq_2_bits_exceptionVec_2,
  input  io_enq_2_bits_exceptionVec_3,
  input  io_enq_2_bits_exceptionVec_12,
  input  io_enq_2_bits_exceptionVec_20,
  input  io_enq_2_bits_exceptionVec_22,
  input  io_enq_2_bits_isFetchMalAddr,
  input  io_enq_2_bits_satpFlushFirstFetchFault,
  input  io_enq_2_bits_flushPipe,
  input  io_enq_2_bits_isVset,
  input  io_enq_2_bits_singleStep,
  input  io_enq_2_bits_crossPageIPFFix,
  input  [3:0] io_enq_2_bits_trigger,
  input  io_enq_3_valid,
  input  io_enq_3_bits_robIdx_flag,
  input  [7:0] io_enq_3_bits_robIdx_value,
  input  [5:0] io_enq_3_bits_ftqPtr_value,
  input  [3:0] io_enq_3_bits_ftqOffset,
  input  io_enq_3_bits_hasException,
  input  io_enq_3_bits_exceptionVec_0,
  input  io_enq_3_bits_exceptionVec_1,
  input  io_enq_3_bits_exceptionVec_2,
  input  io_enq_3_bits_exceptionVec_3,
  input  io_enq_3_bits_exceptionVec_12,
  input  io_enq_3_bits_exceptionVec_20,
  input  io_enq_3_bits_exceptionVec_22,
  input  io_enq_3_bits_isFetchMalAddr,
  input  io_enq_3_bits_satpFlushFirstFetchFault,
  input  io_enq_3_bits_flushPipe,
  input  io_enq_3_bits_isVset,
  input  io_enq_3_bits_singleStep,
  input  io_enq_3_bits_crossPageIPFFix,
  input  [3:0] io_enq_3_bits_trigger,
  input  io_enq_4_valid,
  input  io_enq_4_bits_robIdx_flag,
  input  [7:0] io_enq_4_bits_robIdx_value,
  input  [5:0] io_enq_4_bits_ftqPtr_value,
  input  [3:0] io_enq_4_bits_ftqOffset,
  input  io_enq_4_bits_hasException,
  input  io_enq_4_bits_exceptionVec_0,
  input  io_enq_4_bits_exceptionVec_1,
  input  io_enq_4_bits_exceptionVec_2,
  input  io_enq_4_bits_exceptionVec_3,
  input  io_enq_4_bits_exceptionVec_12,
  input  io_enq_4_bits_exceptionVec_20,
  input  io_enq_4_bits_exceptionVec_22,
  input  io_enq_4_bits_isFetchMalAddr,
  input  io_enq_4_bits_satpFlushFirstFetchFault,
  input  io_enq_4_bits_flushPipe,
  input  io_enq_4_bits_isVset,
  input  io_enq_4_bits_singleStep,
  input  io_enq_4_bits_crossPageIPFFix,
  input  [3:0] io_enq_4_bits_trigger,
  input  io_enq_5_valid,
  input  io_enq_5_bits_robIdx_flag,
  input  [7:0] io_enq_5_bits_robIdx_value,
  input  [5:0] io_enq_5_bits_ftqPtr_value,
  input  [3:0] io_enq_5_bits_ftqOffset,
  input  io_enq_5_bits_hasException,
  input  io_enq_5_bits_exceptionVec_0,
  input  io_enq_5_bits_exceptionVec_1,
  input  io_enq_5_bits_exceptionVec_2,
  input  io_enq_5_bits_exceptionVec_3,
  input  io_enq_5_bits_exceptionVec_12,
  input  io_enq_5_bits_exceptionVec_20,
  input  io_enq_5_bits_exceptionVec_22,
  input  io_enq_5_bits_isFetchMalAddr,
  input  io_enq_5_bits_satpFlushFirstFetchFault,
  input  io_enq_5_bits_flushPipe,
  input  io_enq_5_bits_isVset,
  input  io_enq_5_bits_singleStep,
  input  io_enq_5_bits_crossPageIPFFix,
  input  [3:0] io_enq_5_bits_trigger,
  input  io_wb_0_valid,
  input  io_wb_0_bits_robIdx_flag,
  input  [7:0] io_wb_0_bits_robIdx_value,
  input  io_wb_0_bits_hasException,
  input  io_wb_0_bits_exceptionVec_2,
  input  io_wb_0_bits_exceptionVec_3,
  input  io_wb_0_bits_exceptionVec_8,
  input  io_wb_0_bits_exceptionVec_9,
  input  io_wb_0_bits_exceptionVec_10,
  input  io_wb_0_bits_exceptionVec_11,
  input  io_wb_0_bits_exceptionVec_22,
  input  io_wb_0_bits_flushPipe,
  input  io_wb_0_bits_satpFlushPipe,
  input  io_wb_1_valid,
  input  io_wb_1_bits_robIdx_flag,
  input  [7:0] io_wb_1_bits_robIdx_value,
  input  io_wb_1_bits_hasException,
  input  io_wb_1_bits_exceptionVec_2,
  input  io_wb_2_valid,
  input  io_wb_2_bits_robIdx_flag,
  input  [7:0] io_wb_2_bits_robIdx_value,
  input  io_wb_2_bits_hasException,
  input  io_wb_2_bits_exceptionVec_2,
  input  io_wb_3_bits_robIdx_flag,
  input  [7:0] io_wb_3_bits_robIdx_value,
  input  io_wb_4_bits_robIdx_flag,
  input  [7:0] io_wb_4_bits_robIdx_value,
  input  io_wb_5_bits_robIdx_flag,
  input  [7:0] io_wb_5_bits_robIdx_value,
  input  io_wb_6_valid,
  input  io_wb_6_bits_robIdx_flag,
  input  [7:0] io_wb_6_bits_robIdx_value,
  input  io_wb_6_bits_hasException,
  input  io_wb_6_bits_exceptionVec_0,
  input  io_wb_6_bits_exceptionVec_1,
  input  io_wb_6_bits_exceptionVec_2,
  input  io_wb_6_bits_exceptionVec_3,
  input  io_wb_6_bits_exceptionVec_4,
  input  io_wb_6_bits_exceptionVec_5,
  input  io_wb_6_bits_exceptionVec_6,
  input  io_wb_6_bits_exceptionVec_7,
  input  io_wb_6_bits_exceptionVec_8,
  input  io_wb_6_bits_exceptionVec_9,
  input  io_wb_6_bits_exceptionVec_10,
  input  io_wb_6_bits_exceptionVec_11,
  input  io_wb_6_bits_exceptionVec_12,
  input  io_wb_6_bits_exceptionVec_13,
  input  io_wb_6_bits_exceptionVec_14,
  input  io_wb_6_bits_exceptionVec_15,
  input  io_wb_6_bits_exceptionVec_16,
  input  io_wb_6_bits_exceptionVec_17,
  input  io_wb_6_bits_exceptionVec_18,
  input  io_wb_6_bits_exceptionVec_19,
  input  io_wb_6_bits_exceptionVec_20,
  input  io_wb_6_bits_exceptionVec_21,
  input  io_wb_6_bits_exceptionVec_22,
  input  io_wb_6_bits_exceptionVec_23,
  input  io_wb_6_bits_flushPipe,
  input  [3:0] io_wb_6_bits_trigger,
  input  io_wb_7_valid,
  input  io_wb_7_bits_robIdx_flag,
  input  [7:0] io_wb_7_bits_robIdx_value,
  input  io_wb_7_bits_hasException,
  input  io_wb_7_bits_exceptionVec_0,
  input  io_wb_7_bits_exceptionVec_1,
  input  io_wb_7_bits_exceptionVec_2,
  input  io_wb_7_bits_exceptionVec_3,
  input  io_wb_7_bits_exceptionVec_4,
  input  io_wb_7_bits_exceptionVec_5,
  input  io_wb_7_bits_exceptionVec_6,
  input  io_wb_7_bits_exceptionVec_7,
  input  io_wb_7_bits_exceptionVec_8,
  input  io_wb_7_bits_exceptionVec_9,
  input  io_wb_7_bits_exceptionVec_10,
  input  io_wb_7_bits_exceptionVec_11,
  input  io_wb_7_bits_exceptionVec_12,
  input  io_wb_7_bits_exceptionVec_13,
  input  io_wb_7_bits_exceptionVec_14,
  input  io_wb_7_bits_exceptionVec_15,
  input  io_wb_7_bits_exceptionVec_16,
  input  io_wb_7_bits_exceptionVec_17,
  input  io_wb_7_bits_exceptionVec_18,
  input  io_wb_7_bits_exceptionVec_19,
  input  io_wb_7_bits_exceptionVec_20,
  input  io_wb_7_bits_exceptionVec_21,
  input  io_wb_7_bits_exceptionVec_22,
  input  io_wb_7_bits_exceptionVec_23,
  input  io_wb_7_bits_flushPipe,
  input  [3:0] io_wb_7_bits_trigger,
  input  io_wb_8_valid,
  input  io_wb_8_bits_robIdx_flag,
  input  [7:0] io_wb_8_bits_robIdx_value,
  input  io_wb_8_bits_hasException,
  input  io_wb_8_bits_exceptionVec_0,
  input  io_wb_8_bits_exceptionVec_1,
  input  io_wb_8_bits_exceptionVec_2,
  input  io_wb_8_bits_exceptionVec_3,
  input  io_wb_8_bits_exceptionVec_4,
  input  io_wb_8_bits_exceptionVec_5,
  input  io_wb_8_bits_exceptionVec_6,
  input  io_wb_8_bits_exceptionVec_7,
  input  io_wb_8_bits_exceptionVec_8,
  input  io_wb_8_bits_exceptionVec_9,
  input  io_wb_8_bits_exceptionVec_10,
  input  io_wb_8_bits_exceptionVec_11,
  input  io_wb_8_bits_exceptionVec_12,
  input  io_wb_8_bits_exceptionVec_13,
  input  io_wb_8_bits_exceptionVec_14,
  input  io_wb_8_bits_exceptionVec_15,
  input  io_wb_8_bits_exceptionVec_16,
  input  io_wb_8_bits_exceptionVec_17,
  input  io_wb_8_bits_exceptionVec_18,
  input  io_wb_8_bits_exceptionVec_19,
  input  io_wb_8_bits_exceptionVec_20,
  input  io_wb_8_bits_exceptionVec_21,
  input  io_wb_8_bits_exceptionVec_22,
  input  io_wb_8_bits_exceptionVec_23,
  input  io_wb_8_bits_flushPipe,
  input  io_wb_8_bits_replayInst,
  input  [3:0] io_wb_8_bits_trigger,
  input  io_wb_9_valid,
  input  io_wb_9_bits_robIdx_flag,
  input  [7:0] io_wb_9_bits_robIdx_value,
  input  io_wb_9_bits_hasException,
  input  io_wb_9_bits_exceptionVec_0,
  input  io_wb_9_bits_exceptionVec_1,
  input  io_wb_9_bits_exceptionVec_2,
  input  io_wb_9_bits_exceptionVec_3,
  input  io_wb_9_bits_exceptionVec_4,
  input  io_wb_9_bits_exceptionVec_5,
  input  io_wb_9_bits_exceptionVec_6,
  input  io_wb_9_bits_exceptionVec_7,
  input  io_wb_9_bits_exceptionVec_8,
  input  io_wb_9_bits_exceptionVec_9,
  input  io_wb_9_bits_exceptionVec_10,
  input  io_wb_9_bits_exceptionVec_11,
  input  io_wb_9_bits_exceptionVec_12,
  input  io_wb_9_bits_exceptionVec_13,
  input  io_wb_9_bits_exceptionVec_14,
  input  io_wb_9_bits_exceptionVec_15,
  input  io_wb_9_bits_exceptionVec_16,
  input  io_wb_9_bits_exceptionVec_17,
  input  io_wb_9_bits_exceptionVec_18,
  input  io_wb_9_bits_exceptionVec_19,
  input  io_wb_9_bits_exceptionVec_20,
  input  io_wb_9_bits_exceptionVec_21,
  input  io_wb_9_bits_exceptionVec_22,
  input  io_wb_9_bits_exceptionVec_23,
  input  io_wb_9_bits_flushPipe,
  input  io_wb_9_bits_replayInst,
  input  [3:0] io_wb_9_bits_trigger,
  input  io_wb_10_valid,
  input  io_wb_10_bits_robIdx_flag,
  input  [7:0] io_wb_10_bits_robIdx_value,
  input  io_wb_10_bits_hasException,
  input  io_wb_10_bits_exceptionVec_0,
  input  io_wb_10_bits_exceptionVec_1,
  input  io_wb_10_bits_exceptionVec_2,
  input  io_wb_10_bits_exceptionVec_3,
  input  io_wb_10_bits_exceptionVec_4,
  input  io_wb_10_bits_exceptionVec_5,
  input  io_wb_10_bits_exceptionVec_6,
  input  io_wb_10_bits_exceptionVec_7,
  input  io_wb_10_bits_exceptionVec_8,
  input  io_wb_10_bits_exceptionVec_9,
  input  io_wb_10_bits_exceptionVec_10,
  input  io_wb_10_bits_exceptionVec_11,
  input  io_wb_10_bits_exceptionVec_12,
  input  io_wb_10_bits_exceptionVec_13,
  input  io_wb_10_bits_exceptionVec_14,
  input  io_wb_10_bits_exceptionVec_15,
  input  io_wb_10_bits_exceptionVec_16,
  input  io_wb_10_bits_exceptionVec_17,
  input  io_wb_10_bits_exceptionVec_18,
  input  io_wb_10_bits_exceptionVec_19,
  input  io_wb_10_bits_exceptionVec_20,
  input  io_wb_10_bits_exceptionVec_21,
  input  io_wb_10_bits_exceptionVec_22,
  input  io_wb_10_bits_exceptionVec_23,
  input  io_wb_10_bits_flushPipe,
  input  io_wb_10_bits_replayInst,
  input  [3:0] io_wb_10_bits_trigger,
  input  io_wb_11_valid,
  input  io_wb_11_bits_robIdx_flag,
  input  [7:0] io_wb_11_bits_robIdx_value,
  input  io_wb_11_bits_hasException,
  input  io_wb_11_bits_exceptionVec_0,
  input  io_wb_11_bits_exceptionVec_1,
  input  io_wb_11_bits_exceptionVec_2,
  input  io_wb_11_bits_exceptionVec_3,
  input  io_wb_11_bits_exceptionVec_4,
  input  io_wb_11_bits_exceptionVec_5,
  input  io_wb_11_bits_exceptionVec_6,
  input  io_wb_11_bits_exceptionVec_7,
  input  io_wb_11_bits_exceptionVec_8,
  input  io_wb_11_bits_exceptionVec_9,
  input  io_wb_11_bits_exceptionVec_10,
  input  io_wb_11_bits_exceptionVec_11,
  input  io_wb_11_bits_exceptionVec_12,
  input  io_wb_11_bits_exceptionVec_13,
  input  io_wb_11_bits_exceptionVec_14,
  input  io_wb_11_bits_exceptionVec_15,
  input  io_wb_11_bits_exceptionVec_16,
  input  io_wb_11_bits_exceptionVec_17,
  input  io_wb_11_bits_exceptionVec_18,
  input  io_wb_11_bits_exceptionVec_19,
  input  io_wb_11_bits_exceptionVec_20,
  input  io_wb_11_bits_exceptionVec_21,
  input  io_wb_11_bits_exceptionVec_22,
  input  io_wb_11_bits_exceptionVec_23,
  input  io_wb_11_bits_flushPipe,
  input  io_wb_11_bits_replayInst,
  input  [3:0] io_wb_11_bits_trigger,
  input  io_wb_11_bits_vstartEn,
  input  [63:0] io_wb_11_bits_vstart,
  input  [6:0] io_wb_11_bits_vuopIdx,
  input  io_wb_11_bits_isVecLoad,
  input  io_wb_11_bits_isVlm,
  input  io_wb_11_bits_isStrided,
  input  io_wb_11_bits_isIndexed,
  input  io_wb_11_bits_isWhole,
  input  [2:0] io_wb_11_bits_nf,
  input  [1:0] io_wb_11_bits_vsew,
  input  [1:0] io_wb_11_bits_veew,
  input  [2:0] io_wb_11_bits_vlmul,
  input  io_wb_12_valid,
  input  io_wb_12_bits_robIdx_flag,
  input  [7:0] io_wb_12_bits_robIdx_value,
  input  io_wb_12_bits_hasException,
  input  io_wb_12_bits_exceptionVec_0,
  input  io_wb_12_bits_exceptionVec_1,
  input  io_wb_12_bits_exceptionVec_2,
  input  io_wb_12_bits_exceptionVec_3,
  input  io_wb_12_bits_exceptionVec_4,
  input  io_wb_12_bits_exceptionVec_5,
  input  io_wb_12_bits_exceptionVec_6,
  input  io_wb_12_bits_exceptionVec_7,
  input  io_wb_12_bits_exceptionVec_8,
  input  io_wb_12_bits_exceptionVec_9,
  input  io_wb_12_bits_exceptionVec_10,
  input  io_wb_12_bits_exceptionVec_11,
  input  io_wb_12_bits_exceptionVec_12,
  input  io_wb_12_bits_exceptionVec_13,
  input  io_wb_12_bits_exceptionVec_14,
  input  io_wb_12_bits_exceptionVec_15,
  input  io_wb_12_bits_exceptionVec_16,
  input  io_wb_12_bits_exceptionVec_17,
  input  io_wb_12_bits_exceptionVec_18,
  input  io_wb_12_bits_exceptionVec_19,
  input  io_wb_12_bits_exceptionVec_20,
  input  io_wb_12_bits_exceptionVec_21,
  input  io_wb_12_bits_exceptionVec_22,
  input  io_wb_12_bits_exceptionVec_23,
  input  io_wb_12_bits_flushPipe,
  input  io_wb_12_bits_replayInst,
  input  [3:0] io_wb_12_bits_trigger,
  input  io_wb_12_bits_vstartEn,
  input  [63:0] io_wb_12_bits_vstart,
  input  [6:0] io_wb_12_bits_vuopIdx,
  input  io_wb_12_bits_isVecLoad,
  input  io_wb_12_bits_isVlm,
  input  io_wb_12_bits_isStrided,
  input  io_wb_12_bits_isIndexed,
  input  io_wb_12_bits_isWhole,
  input  [2:0] io_wb_12_bits_nf,
  input  [1:0] io_wb_12_bits_vsew,
  input  [1:0] io_wb_12_bits_veew,
  input  [2:0] io_wb_12_bits_vlmul,
  output io_state_valid,
  output io_state_bits_robIdx_flag,
  output [7:0] io_state_bits_robIdx_value,
  output [5:0] io_state_bits_ftqPtr_value,
  output [3:0] io_state_bits_ftqOffset,
  output io_state_bits_hasException,
  output io_state_bits_isEnqExcp,
  output io_state_bits_exceptionVec_0,
  output io_state_bits_exceptionVec_1,
  output io_state_bits_exceptionVec_2,
  output io_state_bits_exceptionVec_3,
  output io_state_bits_exceptionVec_4,
  output io_state_bits_exceptionVec_5,
  output io_state_bits_exceptionVec_6,
  output io_state_bits_exceptionVec_7,
  output io_state_bits_exceptionVec_8,
  output io_state_bits_exceptionVec_9,
  output io_state_bits_exceptionVec_10,
  output io_state_bits_exceptionVec_11,
  output io_state_bits_exceptionVec_12,
  output io_state_bits_exceptionVec_13,
  output io_state_bits_exceptionVec_14,
  output io_state_bits_exceptionVec_15,
  output io_state_bits_exceptionVec_16,
  output io_state_bits_exceptionVec_17,
  output io_state_bits_exceptionVec_18,
  output io_state_bits_exceptionVec_19,
  output io_state_bits_exceptionVec_20,
  output io_state_bits_exceptionVec_21,
  output io_state_bits_exceptionVec_22,
  output io_state_bits_exceptionVec_23,
  output io_state_bits_isFetchMalAddr,
  output io_state_bits_satpFlushFirstFetchFault,
  output io_state_bits_flushPipe,
  output io_state_bits_satpFlushPipe,
  output io_state_bits_isVset,
  output io_state_bits_replayInst,
  output io_state_bits_singleStep,
  output io_state_bits_crossPageIPFFix,
  output [3:0] io_state_bits_trigger,
  output io_state_bits_vstartEn,
  output [63:0] io_state_bits_vstart,
  output io_state_bits_isVecLoad,
  output io_state_bits_isVlm,
  output io_state_bits_isStrided,
  output io_state_bits_isIndexed,
  output io_state_bits_isWhole,
  output [2:0] io_state_bits_nf,
  output [1:0] io_state_bits_vsew,
  output [1:0] io_state_bits_veew,
  output [2:0] io_state_bits_vlmul
);
  import exceptiongen_pkg::*;

  logic [5:0]      enq_valid;
  enq_excp_t [5:0] enq_bits;
  logic [0:0]      csr_valid;
  wb_excp_t [0:0]  csr_bits;
  logic [2:0]      load_valid;
  wb_excp_t [2:0]  load_bits;
  logic [1:0]      store_valid;
  wb_excp_t [1:0]  store_bits;
  logic [1:0]      varith_valid;
  wb_excp_t [1:0]  varith_bits;
  logic [1:0]      vls_valid;
  wb_excp_t [1:0]  vls_bits;
  logic [1:0][6:0] vls_vuop;
  logic            state_valid;
  excp_state_t     state;

  // 扁平端口 -> 核的结构体（口上没有的字段保持 0）
  always_comb begin
    enq_bits    = '0;
    csr_bits = '0;
    load_bits = '0;
    store_bits = '0;
    varith_bits = '0;
    vls_bits = '0;
    vls_vuop    = '0;
    csr_bits[0].trigger = TRIGGER_NONE;
    varith_bits[0].trigger = TRIGGER_NONE;
    varith_bits[1].trigger = TRIGGER_NONE;
    enq_valid[0] = io_enq_0_valid;
    enq_bits[0].rob_idx.flag = io_enq_0_bits_robIdx_flag;
    enq_bits[0].rob_idx.value = io_enq_0_bits_robIdx_value;
    enq_bits[0].ftq_ptr = io_enq_0_bits_ftqPtr_value;
    enq_bits[0].ftq_offset = io_enq_0_bits_ftqOffset;
    enq_bits[0].has_exception = io_enq_0_bits_hasException;
    enq_bits[0].exception_vec[0] = io_enq_0_bits_exceptionVec_0;
    enq_bits[0].exception_vec[1] = io_enq_0_bits_exceptionVec_1;
    enq_bits[0].exception_vec[2] = io_enq_0_bits_exceptionVec_2;
    enq_bits[0].exception_vec[3] = io_enq_0_bits_exceptionVec_3;
    enq_bits[0].exception_vec[4] = io_enq_0_bits_exceptionVec_12;
    enq_bits[0].exception_vec[5] = io_enq_0_bits_exceptionVec_20;
    enq_bits[0].exception_vec[6] = io_enq_0_bits_exceptionVec_22;
    enq_bits[0].is_fetch_mal_addr = io_enq_0_bits_isFetchMalAddr;
    enq_bits[0].satp_flush_first_fetch_fault = io_enq_0_bits_satpFlushFirstFetchFault;
    enq_bits[0].flush_pipe = io_enq_0_bits_flushPipe;
    enq_bits[0].is_vset = io_enq_0_bits_isVset;
    enq_bits[0].single_step = io_enq_0_bits_singleStep;
    enq_bits[0].cross_page_ipf_fix = io_enq_0_bits_crossPageIPFFix;
    enq_bits[0].trigger = io_enq_0_bits_trigger;
    enq_valid[1] = io_enq_1_valid;
    enq_bits[1].rob_idx.flag = io_enq_1_bits_robIdx_flag;
    enq_bits[1].rob_idx.value = io_enq_1_bits_robIdx_value;
    enq_bits[1].ftq_ptr = io_enq_1_bits_ftqPtr_value;
    enq_bits[1].ftq_offset = io_enq_1_bits_ftqOffset;
    enq_bits[1].has_exception = io_enq_1_bits_hasException;
    enq_bits[1].exception_vec[0] = io_enq_1_bits_exceptionVec_0;
    enq_bits[1].exception_vec[1] = io_enq_1_bits_exceptionVec_1;
    enq_bits[1].exception_vec[2] = io_enq_1_bits_exceptionVec_2;
    enq_bits[1].exception_vec[3] = io_enq_1_bits_exceptionVec_3;
    enq_bits[1].exception_vec[4] = io_enq_1_bits_exceptionVec_12;
    enq_bits[1].exception_vec[5] = io_enq_1_bits_exceptionVec_20;
    enq_bits[1].exception_vec[6] = io_enq_1_bits_exceptionVec_22;
    enq_bits[1].is_fetch_mal_addr = io_enq_1_bits_isFetchMalAddr;
    enq_bits[1].satp_flush_first_fetch_fault = io_enq_1_bits_satpFlushFirstFetchFault;
    enq_bits[1].flush_pipe = io_enq_1_bits_flushPipe;
    enq_bits[1].is_vset = io_enq_1_bits_isVset;
    enq_bits[1].single_step = io_enq_1_bits_singleStep;
    enq_bits[1].cross_page_ipf_fix = io_enq_1_bits_crossPageIPFFix;
    enq_bits[1].trigger = io_enq_1_bits_trigger;
    enq_valid[2] = io_enq_2_valid;
    enq_bits[2].rob_idx.flag = io_enq_2_bits_robIdx_flag;
    enq_bits[2].rob_idx.value = io_enq_2_bits_robIdx_value;
    enq_bits[2].ftq_ptr = io_enq_2_bits_ftqPtr_value;
    enq_bits[2].ftq_offset = io_enq_2_bits_ftqOffset;
    enq_bits[2].has_exception = io_enq_2_bits_hasException;
    enq_bits[2].exception_vec[0] = io_enq_2_bits_exceptionVec_0;
    enq_bits[2].exception_vec[1] = io_enq_2_bits_exceptionVec_1;
    enq_bits[2].exception_vec[2] = io_enq_2_bits_exceptionVec_2;
    enq_bits[2].exception_vec[3] = io_enq_2_bits_exceptionVec_3;
    enq_bits[2].exception_vec[4] = io_enq_2_bits_exceptionVec_12;
    enq_bits[2].exception_vec[5] = io_enq_2_bits_exceptionVec_20;
    enq_bits[2].exception_vec[6] = io_enq_2_bits_exceptionVec_22;
    enq_bits[2].is_fetch_mal_addr = io_enq_2_bits_isFetchMalAddr;
    enq_bits[2].satp_flush_first_fetch_fault = io_enq_2_bits_satpFlushFirstFetchFault;
    enq_bits[2].flush_pipe = io_enq_2_bits_flushPipe;
    enq_bits[2].is_vset = io_enq_2_bits_isVset;
    enq_bits[2].single_step = io_enq_2_bits_singleStep;
    enq_bits[2].cross_page_ipf_fix = io_enq_2_bits_crossPageIPFFix;
    enq_bits[2].trigger = io_enq_2_bits_trigger;
    enq_valid[3] = io_enq_3_valid;
    enq_bits[3].rob_idx.flag = io_enq_3_bits_robIdx_flag;
    enq_bits[3].rob_idx.value = io_enq_3_bits_robIdx_value;
    enq_bits[3].ftq_ptr = io_enq_3_bits_ftqPtr_value;
    enq_bits[3].ftq_offset = io_enq_3_bits_ftqOffset;
    enq_bits[3].has_exception = io_enq_3_bits_hasException;
    enq_bits[3].exception_vec[0] = io_enq_3_bits_exceptionVec_0;
    enq_bits[3].exception_vec[1] = io_enq_3_bits_exceptionVec_1;
    enq_bits[3].exception_vec[2] = io_enq_3_bits_exceptionVec_2;
    enq_bits[3].exception_vec[3] = io_enq_3_bits_exceptionVec_3;
    enq_bits[3].exception_vec[4] = io_enq_3_bits_exceptionVec_12;
    enq_bits[3].exception_vec[5] = io_enq_3_bits_exceptionVec_20;
    enq_bits[3].exception_vec[6] = io_enq_3_bits_exceptionVec_22;
    enq_bits[3].is_fetch_mal_addr = io_enq_3_bits_isFetchMalAddr;
    enq_bits[3].satp_flush_first_fetch_fault = io_enq_3_bits_satpFlushFirstFetchFault;
    enq_bits[3].flush_pipe = io_enq_3_bits_flushPipe;
    enq_bits[3].is_vset = io_enq_3_bits_isVset;
    enq_bits[3].single_step = io_enq_3_bits_singleStep;
    enq_bits[3].cross_page_ipf_fix = io_enq_3_bits_crossPageIPFFix;
    enq_bits[3].trigger = io_enq_3_bits_trigger;
    enq_valid[4] = io_enq_4_valid;
    enq_bits[4].rob_idx.flag = io_enq_4_bits_robIdx_flag;
    enq_bits[4].rob_idx.value = io_enq_4_bits_robIdx_value;
    enq_bits[4].ftq_ptr = io_enq_4_bits_ftqPtr_value;
    enq_bits[4].ftq_offset = io_enq_4_bits_ftqOffset;
    enq_bits[4].has_exception = io_enq_4_bits_hasException;
    enq_bits[4].exception_vec[0] = io_enq_4_bits_exceptionVec_0;
    enq_bits[4].exception_vec[1] = io_enq_4_bits_exceptionVec_1;
    enq_bits[4].exception_vec[2] = io_enq_4_bits_exceptionVec_2;
    enq_bits[4].exception_vec[3] = io_enq_4_bits_exceptionVec_3;
    enq_bits[4].exception_vec[4] = io_enq_4_bits_exceptionVec_12;
    enq_bits[4].exception_vec[5] = io_enq_4_bits_exceptionVec_20;
    enq_bits[4].exception_vec[6] = io_enq_4_bits_exceptionVec_22;
    enq_bits[4].is_fetch_mal_addr = io_enq_4_bits_isFetchMalAddr;
    enq_bits[4].satp_flush_first_fetch_fault = io_enq_4_bits_satpFlushFirstFetchFault;
    enq_bits[4].flush_pipe = io_enq_4_bits_flushPipe;
    enq_bits[4].is_vset = io_enq_4_bits_isVset;
    enq_bits[4].single_step = io_enq_4_bits_singleStep;
    enq_bits[4].cross_page_ipf_fix = io_enq_4_bits_crossPageIPFFix;
    enq_bits[4].trigger = io_enq_4_bits_trigger;
    enq_valid[5] = io_enq_5_valid;
    enq_bits[5].rob_idx.flag = io_enq_5_bits_robIdx_flag;
    enq_bits[5].rob_idx.value = io_enq_5_bits_robIdx_value;
    enq_bits[5].ftq_ptr = io_enq_5_bits_ftqPtr_value;
    enq_bits[5].ftq_offset = io_enq_5_bits_ftqOffset;
    enq_bits[5].has_exception = io_enq_5_bits_hasException;
    enq_bits[5].exception_vec[0] = io_enq_5_bits_exceptionVec_0;
    enq_bits[5].exception_vec[1] = io_enq_5_bits_exceptionVec_1;
    enq_bits[5].exception_vec[2] = io_enq_5_bits_exceptionVec_2;
    enq_bits[5].exception_vec[3] = io_enq_5_bits_exceptionVec_3;
    enq_bits[5].exception_vec[4] = io_enq_5_bits_exceptionVec_12;
    enq_bits[5].exception_vec[5] = io_enq_5_bits_exceptionVec_20;
    enq_bits[5].exception_vec[6] = io_enq_5_bits_exceptionVec_22;
    enq_bits[5].is_fetch_mal_addr = io_enq_5_bits_isFetchMalAddr;
    enq_bits[5].satp_flush_first_fetch_fault = io_enq_5_bits_satpFlushFirstFetchFault;
    enq_bits[5].flush_pipe = io_enq_5_bits_flushPipe;
    enq_bits[5].is_vset = io_enq_5_bits_isVset;
    enq_bits[5].single_step = io_enq_5_bits_singleStep;
    enq_bits[5].cross_page_ipf_fix = io_enq_5_bits_crossPageIPFFix;
    enq_bits[5].trigger = io_enq_5_bits_trigger;
    csr_valid[0] = io_wb_0_valid;
    csr_bits[0].rob_idx.flag = io_wb_0_bits_robIdx_flag;
    csr_bits[0].rob_idx.value = io_wb_0_bits_robIdx_value;
    csr_bits[0].has_exception = io_wb_0_bits_hasException;
    csr_bits[0].exception_vec[2] = io_wb_0_bits_exceptionVec_2;
    csr_bits[0].exception_vec[3] = io_wb_0_bits_exceptionVec_3;
    csr_bits[0].exception_vec[8] = io_wb_0_bits_exceptionVec_8;
    csr_bits[0].exception_vec[9] = io_wb_0_bits_exceptionVec_9;
    csr_bits[0].exception_vec[10] = io_wb_0_bits_exceptionVec_10;
    csr_bits[0].exception_vec[11] = io_wb_0_bits_exceptionVec_11;
    csr_bits[0].exception_vec[22] = io_wb_0_bits_exceptionVec_22;
    csr_bits[0].flush_pipe = io_wb_0_bits_flushPipe;
    csr_bits[0].satp_flush_pipe = io_wb_0_bits_satpFlushPipe;
    varith_valid[0] = io_wb_1_valid;
    varith_bits[0].rob_idx.flag = io_wb_1_bits_robIdx_flag;
    varith_bits[0].rob_idx.value = io_wb_1_bits_robIdx_value;
    varith_bits[0].has_exception = io_wb_1_bits_hasException;
    varith_bits[0].exception_vec[2] = io_wb_1_bits_exceptionVec_2;
    varith_valid[1] = io_wb_2_valid;
    varith_bits[1].rob_idx.flag = io_wb_2_bits_robIdx_flag;
    varith_bits[1].rob_idx.value = io_wb_2_bits_robIdx_value;
    varith_bits[1].has_exception = io_wb_2_bits_hasException;
    varith_bits[1].exception_vec[2] = io_wb_2_bits_exceptionVec_2;
    store_valid[0] = io_wb_6_valid;
    store_bits[0].rob_idx.flag = io_wb_6_bits_robIdx_flag;
    store_bits[0].rob_idx.value = io_wb_6_bits_robIdx_value;
    store_bits[0].has_exception = io_wb_6_bits_hasException;
    store_bits[0].exception_vec[0] = io_wb_6_bits_exceptionVec_0;
    store_bits[0].exception_vec[1] = io_wb_6_bits_exceptionVec_1;
    store_bits[0].exception_vec[2] = io_wb_6_bits_exceptionVec_2;
    store_bits[0].exception_vec[3] = io_wb_6_bits_exceptionVec_3;
    store_bits[0].exception_vec[4] = io_wb_6_bits_exceptionVec_4;
    store_bits[0].exception_vec[5] = io_wb_6_bits_exceptionVec_5;
    store_bits[0].exception_vec[6] = io_wb_6_bits_exceptionVec_6;
    store_bits[0].exception_vec[7] = io_wb_6_bits_exceptionVec_7;
    store_bits[0].exception_vec[8] = io_wb_6_bits_exceptionVec_8;
    store_bits[0].exception_vec[9] = io_wb_6_bits_exceptionVec_9;
    store_bits[0].exception_vec[10] = io_wb_6_bits_exceptionVec_10;
    store_bits[0].exception_vec[11] = io_wb_6_bits_exceptionVec_11;
    store_bits[0].exception_vec[12] = io_wb_6_bits_exceptionVec_12;
    store_bits[0].exception_vec[13] = io_wb_6_bits_exceptionVec_13;
    store_bits[0].exception_vec[14] = io_wb_6_bits_exceptionVec_14;
    store_bits[0].exception_vec[15] = io_wb_6_bits_exceptionVec_15;
    store_bits[0].exception_vec[16] = io_wb_6_bits_exceptionVec_16;
    store_bits[0].exception_vec[17] = io_wb_6_bits_exceptionVec_17;
    store_bits[0].exception_vec[18] = io_wb_6_bits_exceptionVec_18;
    store_bits[0].exception_vec[19] = io_wb_6_bits_exceptionVec_19;
    store_bits[0].exception_vec[20] = io_wb_6_bits_exceptionVec_20;
    store_bits[0].exception_vec[21] = io_wb_6_bits_exceptionVec_21;
    store_bits[0].exception_vec[22] = io_wb_6_bits_exceptionVec_22;
    store_bits[0].exception_vec[23] = io_wb_6_bits_exceptionVec_23;
    store_bits[0].flush_pipe = io_wb_6_bits_flushPipe;
    store_bits[0].trigger = io_wb_6_bits_trigger;
    store_valid[1] = io_wb_7_valid;
    store_bits[1].rob_idx.flag = io_wb_7_bits_robIdx_flag;
    store_bits[1].rob_idx.value = io_wb_7_bits_robIdx_value;
    store_bits[1].has_exception = io_wb_7_bits_hasException;
    store_bits[1].exception_vec[0] = io_wb_7_bits_exceptionVec_0;
    store_bits[1].exception_vec[1] = io_wb_7_bits_exceptionVec_1;
    store_bits[1].exception_vec[2] = io_wb_7_bits_exceptionVec_2;
    store_bits[1].exception_vec[3] = io_wb_7_bits_exceptionVec_3;
    store_bits[1].exception_vec[4] = io_wb_7_bits_exceptionVec_4;
    store_bits[1].exception_vec[5] = io_wb_7_bits_exceptionVec_5;
    store_bits[1].exception_vec[6] = io_wb_7_bits_exceptionVec_6;
    store_bits[1].exception_vec[7] = io_wb_7_bits_exceptionVec_7;
    store_bits[1].exception_vec[8] = io_wb_7_bits_exceptionVec_8;
    store_bits[1].exception_vec[9] = io_wb_7_bits_exceptionVec_9;
    store_bits[1].exception_vec[10] = io_wb_7_bits_exceptionVec_10;
    store_bits[1].exception_vec[11] = io_wb_7_bits_exceptionVec_11;
    store_bits[1].exception_vec[12] = io_wb_7_bits_exceptionVec_12;
    store_bits[1].exception_vec[13] = io_wb_7_bits_exceptionVec_13;
    store_bits[1].exception_vec[14] = io_wb_7_bits_exceptionVec_14;
    store_bits[1].exception_vec[15] = io_wb_7_bits_exceptionVec_15;
    store_bits[1].exception_vec[16] = io_wb_7_bits_exceptionVec_16;
    store_bits[1].exception_vec[17] = io_wb_7_bits_exceptionVec_17;
    store_bits[1].exception_vec[18] = io_wb_7_bits_exceptionVec_18;
    store_bits[1].exception_vec[19] = io_wb_7_bits_exceptionVec_19;
    store_bits[1].exception_vec[20] = io_wb_7_bits_exceptionVec_20;
    store_bits[1].exception_vec[21] = io_wb_7_bits_exceptionVec_21;
    store_bits[1].exception_vec[22] = io_wb_7_bits_exceptionVec_22;
    store_bits[1].exception_vec[23] = io_wb_7_bits_exceptionVec_23;
    store_bits[1].flush_pipe = io_wb_7_bits_flushPipe;
    store_bits[1].trigger = io_wb_7_bits_trigger;
    load_valid[0] = io_wb_8_valid;
    load_bits[0].rob_idx.flag = io_wb_8_bits_robIdx_flag;
    load_bits[0].rob_idx.value = io_wb_8_bits_robIdx_value;
    load_bits[0].has_exception = io_wb_8_bits_hasException;
    load_bits[0].exception_vec[0] = io_wb_8_bits_exceptionVec_0;
    load_bits[0].exception_vec[1] = io_wb_8_bits_exceptionVec_1;
    load_bits[0].exception_vec[2] = io_wb_8_bits_exceptionVec_2;
    load_bits[0].exception_vec[3] = io_wb_8_bits_exceptionVec_3;
    load_bits[0].exception_vec[4] = io_wb_8_bits_exceptionVec_4;
    load_bits[0].exception_vec[5] = io_wb_8_bits_exceptionVec_5;
    load_bits[0].exception_vec[6] = io_wb_8_bits_exceptionVec_6;
    load_bits[0].exception_vec[7] = io_wb_8_bits_exceptionVec_7;
    load_bits[0].exception_vec[8] = io_wb_8_bits_exceptionVec_8;
    load_bits[0].exception_vec[9] = io_wb_8_bits_exceptionVec_9;
    load_bits[0].exception_vec[10] = io_wb_8_bits_exceptionVec_10;
    load_bits[0].exception_vec[11] = io_wb_8_bits_exceptionVec_11;
    load_bits[0].exception_vec[12] = io_wb_8_bits_exceptionVec_12;
    load_bits[0].exception_vec[13] = io_wb_8_bits_exceptionVec_13;
    load_bits[0].exception_vec[14] = io_wb_8_bits_exceptionVec_14;
    load_bits[0].exception_vec[15] = io_wb_8_bits_exceptionVec_15;
    load_bits[0].exception_vec[16] = io_wb_8_bits_exceptionVec_16;
    load_bits[0].exception_vec[17] = io_wb_8_bits_exceptionVec_17;
    load_bits[0].exception_vec[18] = io_wb_8_bits_exceptionVec_18;
    load_bits[0].exception_vec[19] = io_wb_8_bits_exceptionVec_19;
    load_bits[0].exception_vec[20] = io_wb_8_bits_exceptionVec_20;
    load_bits[0].exception_vec[21] = io_wb_8_bits_exceptionVec_21;
    load_bits[0].exception_vec[22] = io_wb_8_bits_exceptionVec_22;
    load_bits[0].exception_vec[23] = io_wb_8_bits_exceptionVec_23;
    load_bits[0].flush_pipe = io_wb_8_bits_flushPipe;
    load_bits[0].replay_inst = io_wb_8_bits_replayInst;
    load_bits[0].trigger = io_wb_8_bits_trigger;
    load_valid[1] = io_wb_9_valid;
    load_bits[1].rob_idx.flag = io_wb_9_bits_robIdx_flag;
    load_bits[1].rob_idx.value = io_wb_9_bits_robIdx_value;
    load_bits[1].has_exception = io_wb_9_bits_hasException;
    load_bits[1].exception_vec[0] = io_wb_9_bits_exceptionVec_0;
    load_bits[1].exception_vec[1] = io_wb_9_bits_exceptionVec_1;
    load_bits[1].exception_vec[2] = io_wb_9_bits_exceptionVec_2;
    load_bits[1].exception_vec[3] = io_wb_9_bits_exceptionVec_3;
    load_bits[1].exception_vec[4] = io_wb_9_bits_exceptionVec_4;
    load_bits[1].exception_vec[5] = io_wb_9_bits_exceptionVec_5;
    load_bits[1].exception_vec[6] = io_wb_9_bits_exceptionVec_6;
    load_bits[1].exception_vec[7] = io_wb_9_bits_exceptionVec_7;
    load_bits[1].exception_vec[8] = io_wb_9_bits_exceptionVec_8;
    load_bits[1].exception_vec[9] = io_wb_9_bits_exceptionVec_9;
    load_bits[1].exception_vec[10] = io_wb_9_bits_exceptionVec_10;
    load_bits[1].exception_vec[11] = io_wb_9_bits_exceptionVec_11;
    load_bits[1].exception_vec[12] = io_wb_9_bits_exceptionVec_12;
    load_bits[1].exception_vec[13] = io_wb_9_bits_exceptionVec_13;
    load_bits[1].exception_vec[14] = io_wb_9_bits_exceptionVec_14;
    load_bits[1].exception_vec[15] = io_wb_9_bits_exceptionVec_15;
    load_bits[1].exception_vec[16] = io_wb_9_bits_exceptionVec_16;
    load_bits[1].exception_vec[17] = io_wb_9_bits_exceptionVec_17;
    load_bits[1].exception_vec[18] = io_wb_9_bits_exceptionVec_18;
    load_bits[1].exception_vec[19] = io_wb_9_bits_exceptionVec_19;
    load_bits[1].exception_vec[20] = io_wb_9_bits_exceptionVec_20;
    load_bits[1].exception_vec[21] = io_wb_9_bits_exceptionVec_21;
    load_bits[1].exception_vec[22] = io_wb_9_bits_exceptionVec_22;
    load_bits[1].exception_vec[23] = io_wb_9_bits_exceptionVec_23;
    load_bits[1].flush_pipe = io_wb_9_bits_flushPipe;
    load_bits[1].replay_inst = io_wb_9_bits_replayInst;
    load_bits[1].trigger = io_wb_9_bits_trigger;
    load_valid[2] = io_wb_10_valid;
    load_bits[2].rob_idx.flag = io_wb_10_bits_robIdx_flag;
    load_bits[2].rob_idx.value = io_wb_10_bits_robIdx_value;
    load_bits[2].has_exception = io_wb_10_bits_hasException;
    load_bits[2].exception_vec[0] = io_wb_10_bits_exceptionVec_0;
    load_bits[2].exception_vec[1] = io_wb_10_bits_exceptionVec_1;
    load_bits[2].exception_vec[2] = io_wb_10_bits_exceptionVec_2;
    load_bits[2].exception_vec[3] = io_wb_10_bits_exceptionVec_3;
    load_bits[2].exception_vec[4] = io_wb_10_bits_exceptionVec_4;
    load_bits[2].exception_vec[5] = io_wb_10_bits_exceptionVec_5;
    load_bits[2].exception_vec[6] = io_wb_10_bits_exceptionVec_6;
    load_bits[2].exception_vec[7] = io_wb_10_bits_exceptionVec_7;
    load_bits[2].exception_vec[8] = io_wb_10_bits_exceptionVec_8;
    load_bits[2].exception_vec[9] = io_wb_10_bits_exceptionVec_9;
    load_bits[2].exception_vec[10] = io_wb_10_bits_exceptionVec_10;
    load_bits[2].exception_vec[11] = io_wb_10_bits_exceptionVec_11;
    load_bits[2].exception_vec[12] = io_wb_10_bits_exceptionVec_12;
    load_bits[2].exception_vec[13] = io_wb_10_bits_exceptionVec_13;
    load_bits[2].exception_vec[14] = io_wb_10_bits_exceptionVec_14;
    load_bits[2].exception_vec[15] = io_wb_10_bits_exceptionVec_15;
    load_bits[2].exception_vec[16] = io_wb_10_bits_exceptionVec_16;
    load_bits[2].exception_vec[17] = io_wb_10_bits_exceptionVec_17;
    load_bits[2].exception_vec[18] = io_wb_10_bits_exceptionVec_18;
    load_bits[2].exception_vec[19] = io_wb_10_bits_exceptionVec_19;
    load_bits[2].exception_vec[20] = io_wb_10_bits_exceptionVec_20;
    load_bits[2].exception_vec[21] = io_wb_10_bits_exceptionVec_21;
    load_bits[2].exception_vec[22] = io_wb_10_bits_exceptionVec_22;
    load_bits[2].exception_vec[23] = io_wb_10_bits_exceptionVec_23;
    load_bits[2].flush_pipe = io_wb_10_bits_flushPipe;
    load_bits[2].replay_inst = io_wb_10_bits_replayInst;
    load_bits[2].trigger = io_wb_10_bits_trigger;
    vls_valid[0] = io_wb_11_valid;
    vls_bits[0].rob_idx.flag = io_wb_11_bits_robIdx_flag;
    vls_bits[0].rob_idx.value = io_wb_11_bits_robIdx_value;
    vls_bits[0].has_exception = io_wb_11_bits_hasException;
    vls_bits[0].exception_vec[0] = io_wb_11_bits_exceptionVec_0;
    vls_bits[0].exception_vec[1] = io_wb_11_bits_exceptionVec_1;
    vls_bits[0].exception_vec[2] = io_wb_11_bits_exceptionVec_2;
    vls_bits[0].exception_vec[3] = io_wb_11_bits_exceptionVec_3;
    vls_bits[0].exception_vec[4] = io_wb_11_bits_exceptionVec_4;
    vls_bits[0].exception_vec[5] = io_wb_11_bits_exceptionVec_5;
    vls_bits[0].exception_vec[6] = io_wb_11_bits_exceptionVec_6;
    vls_bits[0].exception_vec[7] = io_wb_11_bits_exceptionVec_7;
    vls_bits[0].exception_vec[8] = io_wb_11_bits_exceptionVec_8;
    vls_bits[0].exception_vec[9] = io_wb_11_bits_exceptionVec_9;
    vls_bits[0].exception_vec[10] = io_wb_11_bits_exceptionVec_10;
    vls_bits[0].exception_vec[11] = io_wb_11_bits_exceptionVec_11;
    vls_bits[0].exception_vec[12] = io_wb_11_bits_exceptionVec_12;
    vls_bits[0].exception_vec[13] = io_wb_11_bits_exceptionVec_13;
    vls_bits[0].exception_vec[14] = io_wb_11_bits_exceptionVec_14;
    vls_bits[0].exception_vec[15] = io_wb_11_bits_exceptionVec_15;
    vls_bits[0].exception_vec[16] = io_wb_11_bits_exceptionVec_16;
    vls_bits[0].exception_vec[17] = io_wb_11_bits_exceptionVec_17;
    vls_bits[0].exception_vec[18] = io_wb_11_bits_exceptionVec_18;
    vls_bits[0].exception_vec[19] = io_wb_11_bits_exceptionVec_19;
    vls_bits[0].exception_vec[20] = io_wb_11_bits_exceptionVec_20;
    vls_bits[0].exception_vec[21] = io_wb_11_bits_exceptionVec_21;
    vls_bits[0].exception_vec[22] = io_wb_11_bits_exceptionVec_22;
    vls_bits[0].exception_vec[23] = io_wb_11_bits_exceptionVec_23;
    vls_bits[0].flush_pipe = io_wb_11_bits_flushPipe;
    vls_bits[0].replay_inst = io_wb_11_bits_replayInst;
    vls_bits[0].trigger = io_wb_11_bits_trigger;
    vls_bits[0].vstart_en = io_wb_11_bits_vstartEn;
    vls_bits[0].vstart = io_wb_11_bits_vstart;
    vls_vuop[0] = io_wb_11_bits_vuopIdx;
    vls_bits[0].is_vec_load = io_wb_11_bits_isVecLoad;
    vls_bits[0].is_vlm = io_wb_11_bits_isVlm;
    vls_bits[0].is_strided = io_wb_11_bits_isStrided;
    vls_bits[0].is_indexed = io_wb_11_bits_isIndexed;
    vls_bits[0].is_whole = io_wb_11_bits_isWhole;
    vls_bits[0].nf = io_wb_11_bits_nf;
    vls_bits[0].vsew = io_wb_11_bits_vsew;
    vls_bits[0].veew = io_wb_11_bits_veew;
    vls_bits[0].vlmul = io_wb_11_bits_vlmul;
    vls_valid[1] = io_wb_12_valid;
    vls_bits[1].rob_idx.flag = io_wb_12_bits_robIdx_flag;
    vls_bits[1].rob_idx.value = io_wb_12_bits_robIdx_value;
    vls_bits[1].has_exception = io_wb_12_bits_hasException;
    vls_bits[1].exception_vec[0] = io_wb_12_bits_exceptionVec_0;
    vls_bits[1].exception_vec[1] = io_wb_12_bits_exceptionVec_1;
    vls_bits[1].exception_vec[2] = io_wb_12_bits_exceptionVec_2;
    vls_bits[1].exception_vec[3] = io_wb_12_bits_exceptionVec_3;
    vls_bits[1].exception_vec[4] = io_wb_12_bits_exceptionVec_4;
    vls_bits[1].exception_vec[5] = io_wb_12_bits_exceptionVec_5;
    vls_bits[1].exception_vec[6] = io_wb_12_bits_exceptionVec_6;
    vls_bits[1].exception_vec[7] = io_wb_12_bits_exceptionVec_7;
    vls_bits[1].exception_vec[8] = io_wb_12_bits_exceptionVec_8;
    vls_bits[1].exception_vec[9] = io_wb_12_bits_exceptionVec_9;
    vls_bits[1].exception_vec[10] = io_wb_12_bits_exceptionVec_10;
    vls_bits[1].exception_vec[11] = io_wb_12_bits_exceptionVec_11;
    vls_bits[1].exception_vec[12] = io_wb_12_bits_exceptionVec_12;
    vls_bits[1].exception_vec[13] = io_wb_12_bits_exceptionVec_13;
    vls_bits[1].exception_vec[14] = io_wb_12_bits_exceptionVec_14;
    vls_bits[1].exception_vec[15] = io_wb_12_bits_exceptionVec_15;
    vls_bits[1].exception_vec[16] = io_wb_12_bits_exceptionVec_16;
    vls_bits[1].exception_vec[17] = io_wb_12_bits_exceptionVec_17;
    vls_bits[1].exception_vec[18] = io_wb_12_bits_exceptionVec_18;
    vls_bits[1].exception_vec[19] = io_wb_12_bits_exceptionVec_19;
    vls_bits[1].exception_vec[20] = io_wb_12_bits_exceptionVec_20;
    vls_bits[1].exception_vec[21] = io_wb_12_bits_exceptionVec_21;
    vls_bits[1].exception_vec[22] = io_wb_12_bits_exceptionVec_22;
    vls_bits[1].exception_vec[23] = io_wb_12_bits_exceptionVec_23;
    vls_bits[1].flush_pipe = io_wb_12_bits_flushPipe;
    vls_bits[1].replay_inst = io_wb_12_bits_replayInst;
    vls_bits[1].trigger = io_wb_12_bits_trigger;
    vls_bits[1].vstart_en = io_wb_12_bits_vstartEn;
    vls_bits[1].vstart = io_wb_12_bits_vstart;
    vls_vuop[1] = io_wb_12_bits_vuopIdx;
    vls_bits[1].is_vec_load = io_wb_12_bits_isVecLoad;
    vls_bits[1].is_vlm = io_wb_12_bits_isVlm;
    vls_bits[1].is_strided = io_wb_12_bits_isStrided;
    vls_bits[1].is_indexed = io_wb_12_bits_isIndexed;
    vls_bits[1].is_whole = io_wb_12_bits_isWhole;
    vls_bits[1].nf = io_wb_12_bits_nf;
    vls_bits[1].vsew = io_wb_12_bits_vsew;
    vls_bits[1].veew = io_wb_12_bits_veew;
    vls_bits[1].vlmul = io_wb_12_bits_vlmul;
  end

  xs_ExceptionGen_core u_core (
    .clock          (clock),
    .reset          (reset),
    .redirect_valid (io_redirect_valid),
    .redirect_ptr   ({io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value}),
    .redirect_level (io_redirect_bits_level),
    .flush          (io_flush),
    .enq_valid      (enq_valid),
    .enq_bits       (enq_bits),
    .csr_valid      (csr_valid),
    .csr_bits       (csr_bits),
    .load_valid     (load_valid),
    .load_bits      (load_bits),
    .store_valid    (store_valid),
    .store_bits     (store_bits),
    .varith_valid   (varith_valid),
    .varith_bits    (varith_bits),
    .vls_valid      (vls_valid),
    .vls_bits       (vls_bits),
    .vls_vuop       (vls_vuop),
    .state_valid    (state_valid),
    .state          (state)
  );

  assign io_state_valid = state_valid;
  assign io_state_bits_robIdx_flag = state.rob_idx.flag;
  assign io_state_bits_robIdx_value = state.rob_idx.value;
  assign io_state_bits_ftqPtr_value = state.ftq_ptr;
  assign io_state_bits_ftqOffset = state.ftq_offset;
  assign io_state_bits_hasException = state.has_exception;
  assign io_state_bits_isEnqExcp = state.is_enq_excp;
  assign io_state_bits_exceptionVec_0 = state.exception_vec[0];
  assign io_state_bits_exceptionVec_1 = state.exception_vec[1];
  assign io_state_bits_exceptionVec_2 = state.exception_vec[2];
  assign io_state_bits_exceptionVec_3 = state.exception_vec[3];
  assign io_state_bits_exceptionVec_4 = state.exception_vec[4];
  assign io_state_bits_exceptionVec_5 = state.exception_vec[5];
  assign io_state_bits_exceptionVec_6 = state.exception_vec[6];
  assign io_state_bits_exceptionVec_7 = state.exception_vec[7];
  assign io_state_bits_exceptionVec_8 = state.exception_vec[8];
  assign io_state_bits_exceptionVec_9 = state.exception_vec[9];
  assign io_state_bits_exceptionVec_10 = state.exception_vec[10];
  assign io_state_bits_exceptionVec_11 = state.exception_vec[11];
  assign io_state_bits_exceptionVec_12 = state.exception_vec[12];
  assign io_state_bits_exceptionVec_13 = state.exception_vec[13];
  assign io_state_bits_exceptionVec_14 = state.exception_vec[14];
  assign io_state_bits_exceptionVec_15 = state.exception_vec[15];
  assign io_state_bits_exceptionVec_16 = state.exception_vec[16];
  assign io_state_bits_exceptionVec_17 = state.exception_vec[17];
  assign io_state_bits_exceptionVec_18 = state.exception_vec[18];
  assign io_state_bits_exceptionVec_19 = state.exception_vec[19];
  assign io_state_bits_exceptionVec_20 = state.exception_vec[20];
  assign io_state_bits_exceptionVec_21 = state.exception_vec[21];
  assign io_state_bits_exceptionVec_22 = state.exception_vec[22];
  assign io_state_bits_exceptionVec_23 = state.exception_vec[23];
  assign io_state_bits_isFetchMalAddr = state.is_fetch_mal_addr;
  assign io_state_bits_satpFlushFirstFetchFault = state.satp_flush_first_fetch_fault;
  assign io_state_bits_flushPipe = state.flush_pipe;
  assign io_state_bits_satpFlushPipe = state.satp_flush_pipe;
  assign io_state_bits_isVset = state.is_vset;
  assign io_state_bits_replayInst = state.replay_inst;
  assign io_state_bits_singleStep = state.single_step;
  assign io_state_bits_crossPageIPFFix = state.cross_page_ipf_fix;
  assign io_state_bits_trigger = state.trigger;
  assign io_state_bits_vstartEn = state.vstart_en;
  assign io_state_bits_vstart = state.vstart;
  assign io_state_bits_isVecLoad = state.is_vec_load;
  assign io_state_bits_isVlm = state.is_vlm;
  assign io_state_bits_isStrided = state.is_strided;
  assign io_state_bits_isIndexed = state.is_indexed;
  assign io_state_bits_isWhole = state.is_whole;
  assign io_state_bits_nf = state.nf;
  assign io_state_bits_vsew = state.vsew;
  assign io_state_bits_veew = state.veew;
  assign io_state_bits_vlmul = state.vlmul;
endmodule
// END GENERATED
