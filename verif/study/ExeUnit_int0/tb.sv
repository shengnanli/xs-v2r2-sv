// =============================================================================
// ExeUnit_int0 学习用 testbench —— 对着波形理解香山整数执行口
//
// 被测：G1 golden 的 ExeUnit（整数 0 号口，内含 Alu + Bku + MulUnit + Dispatcher）
// 目的不是验证（那是 verif/ut 的事），而是把执行块的几个关键机制**演示**出来，
// 让人在 Verdi 里逐拍看明白：
//
//   阶段 1  ALU 单周期        —— 组合路径，in_valid 当拍出结果
//   阶段 2  MUL 三级流水      —— 看 validVecThisFu 逐级移位、3 拍后出结果
//   阶段 3  BKU 三级流水      —— 同为 3 级，但走另一条 FU
//   阶段 4  连发不同 FU       —— 看 Dispatcher 按 fuType 路由、输出或归约
//   阶段 5  ★flush 打掉在飞指令★ —— 看 validPipe 被掐断、而 validVecThisFu 照常移位
//   阶段 6  flush level=1     —— 只打自己那条，不动其它
//
// 波形看点（Verdi 里建议加这几组信号）：
//   tb.phase                        当前阶段号（整数，方便定位）
//   u_exe.io_in_valid / io_in_bits_fuType / io_in_bits_robIdx_value
//   u_exe.in1ToN 的 io_out_*_valid  Dispatcher 的路由结果（谁被选中）
//   u_exe.inPipe_2_1 / inPipe_2_2   ★存活链（validPipe），flush 在这里生效
//   u_exe.Alu.* / u_exe.Mul.validVecThisFu_1/_2 / u_exe.Bku.validVecThisFu_1/_2
//                                   ★占用链，只表示"这一级有数据"，不管 flush
//   u_exe.io_out_valid / io_out_bits_data_0 / io_out_bits_robIdx_value
//   u_exe.io_flush_valid / io_flush_bits_robIdx_value / io_flush_bits_level
// =============================================================================
`timescale 1ns/1ps

module tb;

  // ---- FuType 独热编码（src/main/scala/xiangshan/backend/fu/FuType.scala 顺序）----
  localparam [34:0] FU_ALU = 35'h40;    // 1<<6
  localparam [34:0] FU_MUL = 35'h80;    // 1<<7
  localparam [34:0] FU_BKU = 35'h400;   // 1<<10

  // ---- 几条具体 opcode（src/main/scala/xiangshan/package.scala）----
  localparam [8:0] OP_ADD   = 9'b0_010_0001;  // ALUOpType.add
  localparam [8:0] OP_SUB   = 9'b0_011_0000;  // ALUOpType.sub
  localparam [8:0] OP_MUL   = 9'b0_0000_0000; // MDUOpType.mul
  localparam [8:0] OP_CLMUL = 9'b0_0000_0000; // BKUOpType.clmul
  localparam [8:0] OP_CLZ   = 9'b0_0000_1000; // BKUOpType.clz

  bit clk = 0, rst = 1;
  int phase = 0;            // ← 波形里用它定位阶段
  string phase_name = "";

  always #5 clk = ~clk;

  // ---- DUT 输入 ----
  logic        in_valid, in_rfWen, in_robIdx_flag;
  logic [34:0] in_fuType;
  logic [8:0]  in_fuOpType;
  logic [63:0] in_src0, in_src1;
  logic [7:0]  in_robIdx_value, in_pdest;
  logic        flush_valid, flush_robIdx_flag, flush_level;
  logic [7:0]  flush_robIdx_value;

  wire         out_valid, in_ready, out_intWen, out_robIdx_flag;
  wire [63:0]  out_data0, out_data1;
  wire [7:0]   out_pdest, out_robIdx_value;

  ExeUnit u_exe (
    .clock (clk), .reset (rst),
    .io_flush_valid           (flush_valid),
    .io_flush_bits_robIdx_flag (flush_robIdx_flag),
    .io_flush_bits_robIdx_value(flush_robIdx_value),
    .io_flush_bits_level      (flush_level),
    .io_in_ready              (in_ready),
    .io_in_valid              (in_valid),
    .io_in_bits_fuType        (in_fuType),
    .io_in_bits_fuOpType      (in_fuOpType),
    .io_in_bits_src_0         (in_src0),
    .io_in_bits_src_1         (in_src1),
    .io_in_bits_robIdx_flag   (in_robIdx_flag),
    .io_in_bits_robIdx_value  (in_robIdx_value),
    .io_in_bits_pdest         (in_pdest),
    .io_in_bits_rfWen         (in_rfWen),
    // perfDebugInfo / seqNum：学习用途不关心，喂可识别的常量便于在波形里追踪
    .io_in_bits_perfDebugInfo_eliminatedMove        (1'b0),
    .io_in_bits_perfDebugInfo_renameTime            (64'hA1),
    .io_in_bits_perfDebugInfo_dispatchTime          (64'hA2),
    .io_in_bits_perfDebugInfo_enqRsTime             (64'hA3),
    .io_in_bits_perfDebugInfo_selectTime            (64'hA4),
    .io_in_bits_perfDebugInfo_issueTime             (64'hA5),
    .io_in_bits_perfDebugInfo_writebackTime         (64'hA6),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(64'hA7),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime       (64'hA8),
    .io_in_bits_perfDebugInfo_tlbRespTime           (64'hA9),
    .io_in_bits_debug_seqNum_seqNum                 ({48'h0, in_robIdx_value}),
    .io_in_bits_debug_seqNum_uopIdx                 (8'h0),
    .io_out_ready             (1'b1),   // 与 ExuBlock 里整数口一致：硬接 1，永不反压
    .io_out_valid             (out_valid),
    .io_out_bits_data_0       (out_data0),
    .io_out_bits_data_1       (out_data1),
    .io_out_bits_pdest        (out_pdest),
    .io_out_bits_robIdx_flag  (out_robIdx_flag),
    .io_out_bits_robIdx_value (out_robIdx_value),
    .io_out_bits_intWen       (out_intWen),
    .io_out_bits_debugInfo_eliminatedMove        (),
    .io_out_bits_debugInfo_renameTime            (),
    .io_out_bits_debugInfo_dispatchTime          (),
    .io_out_bits_debugInfo_enqRsTime             (),
    .io_out_bits_debugInfo_selectTime            (),
    .io_out_bits_debugInfo_issueTime             (),
    .io_out_bits_debugInfo_writebackTime         (),
    .io_out_bits_debugInfo_runahead_checkpoint_id(),
    .io_out_bits_debugInfo_tlbFirstReqTime       (),
    .io_out_bits_debugInfo_tlbRespTime           (),
    .io_out_bits_debug_seqNum_seqNum             (),
    .io_out_bits_debug_seqNum_uopIdx             (),
    .cg_bore_cgen   (1'b1),   // 时钟门控使能：学习时全开，免得波形里停钟看不到东西
    .cg_bore_1_cgen (1'b1)
  );

  // ---------------------------------------------------------------------------
  // 发一条指令（占一拍）；robIdx 递增，便于在波形里区分是哪一条
  // ---------------------------------------------------------------------------
  task automatic issue(input [34:0] fuType, input [8:0] op,
                       input [63:0] s0, input [63:0] s1, input [7:0] robIdx);
    @(negedge clk);
    in_valid        <= 1'b1;
    in_fuType       <= fuType;
    in_fuOpType     <= op;
    in_src0         <= s0;
    in_src1         <= s1;
    in_robIdx_flag  <= 1'b0;
    in_robIdx_value <= robIdx;
    in_pdest        <= robIdx;          // 让 pdest 跟 robIdx 一样，波形里好认
    in_rfWen        <= 1'b1;
    @(negedge clk);
    in_valid        <= 1'b0;
  endtask

  task automatic idle(input int n);
    @(negedge clk);
    in_valid <= 1'b0;
    repeat (n) @(negedge clk);
  endtask

  // 打一拍 flush：level=0 打比 robIdx 年轻的；level=1 只打 robIdx 自己
  task automatic do_flush(input [7:0] robIdx, input bit level);
    @(negedge clk);
    flush_valid        <= 1'b1;
    flush_robIdx_flag  <= 1'b0;
    flush_robIdx_value <= robIdx;
    flush_level        <= level;
    @(negedge clk);
    flush_valid        <= 1'b0;
  endtask


  // 发一条指令，并在其后 delay 拍打 flush —— 用来演示**flush 窗口**：
  // flush 只在 io_in_valid（第0级）或 inPipe_2_1（第1级）为高的那拍生效；
  // 晚到一拍指令已进第2级，ExeUnit 里没有 inPipe_2_3 可掐，就掐不掉了。
  task automatic issue_then_flush(input [34:0] fuType, input [8:0] op,
                                  input [63:0] s0, input [63:0] s1,
                                  input [7:0] robIdx,
                                  input [7:0] flushIdx, input bit level,
                                  input int delay);
    fork
      issue(fuType, op, s0, s1, robIdx);
      begin
        repeat (delay) @(negedge clk);
        do_flush(flushIdx, level);
      end
    join
  endtask

  task automatic set_phase(input int n, input string nm);
    phase = n; phase_name = nm;
    $display("\n===== 阶段 %0d @%0t : %s =====", n, $time, nm);
  endtask

  // 结果监视：出结果就打一行，波形对照用
  always @(posedge clk) if (!rst && out_valid)
    $display("  [%0t] OUT  robIdx=%0d pdest=%0d data=0x%016h intWen=%b",
             $time, out_robIdx_value, out_pdest, out_data0, out_intWen);

  initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb, "+all");

    in_valid = 0; flush_valid = 0; flush_level = 0;
    in_fuType = 0; in_fuOpType = 0; in_src0 = 0; in_src1 = 0;
    in_robIdx_value = 0; in_pdest = 0; in_rfWen = 0;
    in_robIdx_flag = 0; flush_robIdx_flag = 0; flush_robIdx_value = 0;

    repeat (6) @(posedge clk);
    rst = 0;
    repeat (2) @(posedge clk);

    // ---- 阶段 1：ALU 单周期 ----------------------------------------------
    // 看点：in_valid 拉高那拍，io_out_valid 同拍就起来（纯组合），data = 3+4
    set_phase(1, "ALU add 单周期：组合出结果，无流水级");
    issue(FU_ALU, OP_ADD, 64'd3, 64'd4, 8'd10);
    idle(4);

    // ---- 阶段 2：MUL 三级流水 --------------------------------------------
    // 看点：u_exe.Mul.validVecThisFu_1 / _2 逐拍移位，第 3 拍 out_valid
    set_phase(2, "MUL 三级流水：validVecThisFu 逐级移位，3 拍后出结果");
    issue(FU_MUL, OP_MUL, 64'd6, 64'd7, 8'd11);
    idle(6);

    // ---- 阶段 3：BKU 三级流水 --------------------------------------------
    // 看点：同为 3 级，但占用链在 u_exe.Bku 里；Dispatcher 只给 Bku 拉 valid
    set_phase(3, "BKU clz 三级流水：走另一条 FU，Dispatcher 路由可见");
    issue(FU_BKU, OP_CLZ, 64'h0000_0000_0000_00FF, 64'd0, 8'd12);
    idle(6);

    // ---- 阶段 4：连发三种 FU --------------------------------------------
    // 看点：三条指令在不同 FU 里并行推进；输出是 |{Alu,Mul,Bku} 或归约，
    //       因为延迟不同(1/3/3)，它们不会撞在同一拍
    set_phase(4, "连发 ALU/MUL/BKU：Dispatcher 路由 + 输出或归约");
    issue(FU_ALU, OP_SUB, 64'd100, 64'd58, 8'd20);
    issue(FU_MUL, OP_MUL, 64'd9,   64'd9,  8'd21);
    issue(FU_BKU, OP_CLMUL, 64'h3, 64'h5,  8'd22);
    idle(8);

    // ---- 阶段 5：★flush 窗口★ 三种到达时机 --------------------------------
    // 第一版 tb 我把 flush 打晚了一拍，指令照样写回——那不是 bug，是**flush 窗口**：
    // ExeUnit 只有 inPipe_2_1 / inPipe_2_2 两个 flush 判定点（没有 inPipe_2_3），
    // 所以 flush 必须在「第0级(io_in_valid) 或 第1级(inPipe_2_1)」为高那拍到达。
    // 更晚到达时结果仍会写回，由下游 ROB 按 robIdx 丢弃——分层过滤，不是漏洞。
    //
    // 波形看点：三个子阶段对比 inPipe_2_1/_2 与 Mul.validVecThisFu_1/_2 的走势，
    //           以及 io_out_valid 是否出现。
    set_phase(51, "flush 与发射同拍：第0级判定掐断，validPipe 从不置起");
    issue_then_flush(FU_MUL, OP_MUL, 64'd12, 64'd12, 8'd30, 8'd29, 1'b0, 0);
    idle(8);

    set_phase(52, "flush 晚 1 拍：指令在第1级，inPipe_2_2 被掐断，不写回");
    issue_then_flush(FU_MUL, OP_MUL, 64'd13, 64'd13, 8'd31, 8'd29, 1'b0, 1);
    idle(8);

    set_phase(53, "flush 晚 2 拍：已过判定窗口 → 照常写回(0x100=13x13 不出现,应为 14x14=0xC4)");
    issue_then_flush(FU_MUL, OP_MUL, 64'd14, 64'd14, 8'd32, 8'd29, 1'b0, 2);
    idle(8);

    // ---- 阶段 6：flush level=1 只打自己 ---------------------------------
    // 看点：先发 robIdx=40，再发 41；flush(level=1, robIdx=40) 只打掉 40，
    //       41 应当活着并正常写回
    set_phase(6, "flush level=1 只打 robIdx=40 自己，41 存活");
    issue(FU_MUL, OP_MUL, 64'd5, 64'd5, 8'd40);
    issue(FU_ALU, OP_ADD, 64'd1, 64'd1, 8'd41);
    do_flush(8'd40, 1'b1);
    idle(10);

    set_phase(99, "结束");
    repeat (4) @(posedge clk);
    $display("\n波形已写入 novas.fsdb —— 用 make verdi 打开");
    $finish;
  end

endmodule
