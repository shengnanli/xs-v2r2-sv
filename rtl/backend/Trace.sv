// =============================================================================
// xs_Trace_core —— RISC-V 指令 trace 顶层 glue(CtrlBlock 内 Trace)。
//
// 对应 golden Trace。功能(真时序 glue, 非纯连线):
//   s1 级: 8 路 fromRob block 各自 RegEnable 打一拍(payload 门控 blockN_valid,
//          valid 位门控 ~blockCommit=TraceBuffer 反馈的背压), 异步复位;
//   TraceBuffer: 存储/分组子模块(golden 逻辑, 两侧同源 elaborate 非黑盒);
//   s3 级: 3 路 group RegNext(TraceBuffer 输出直接打一拍);
//   输出: toPcMem = TraceBuffer 组输出直连; toEncoder = s3 寄存器; blockRobCommit。
//
// iretire 位宽变化: fromRob 输入 [3:0] → s1 存 [3:0] → 喂 TraceBuffer 零扩展 {3'h0,·}
//   → TraceBuffer 输出 [6:0] → s3 存 [6:0]。
// genvar 折叠 8 s1 块; 0 个 _GEN_/_T_ 噪声。
// =============================================================================
module xs_Trace_core(
  input        clock,
  input        reset,
  input        io_in_fromEncoder_enable,
  input        io_in_fromEncoder_stall,
  input        io_in_fromRob_blocks_0_valid,
  input  [5:0] io_in_fromRob_blocks_0_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_0_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_0_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_0_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_0_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_1_valid,
  input  [5:0] io_in_fromRob_blocks_1_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_1_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_1_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_1_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_1_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_2_valid,
  input  [5:0] io_in_fromRob_blocks_2_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_2_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_2_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_2_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_2_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_3_valid,
  input  [5:0] io_in_fromRob_blocks_3_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_3_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_3_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_3_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_3_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_4_valid,
  input  [5:0] io_in_fromRob_blocks_4_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_4_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_4_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_4_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_4_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_5_valid,
  input  [5:0] io_in_fromRob_blocks_5_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_5_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_5_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_5_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_5_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_6_valid,
  input  [5:0] io_in_fromRob_blocks_6_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_6_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_6_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_6_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_6_bits_tracePipe_ilastsize,
  input        io_in_fromRob_blocks_7_valid,
  input  [5:0] io_in_fromRob_blocks_7_bits_ftqIdx_value,
  input  [3:0] io_in_fromRob_blocks_7_bits_ftqOffset,
  input  [3:0] io_in_fromRob_blocks_7_bits_tracePipe_itype,
  input  [3:0] io_in_fromRob_blocks_7_bits_tracePipe_iretire,
  input        io_in_fromRob_blocks_7_bits_tracePipe_ilastsize,
  output       io_out_toPcMem_blocks_0_valid,
  output [5:0] io_out_toPcMem_blocks_0_bits_ftqIdx_value,
  output       io_out_toPcMem_blocks_1_valid,
  output [5:0] io_out_toPcMem_blocks_1_bits_ftqIdx_value,
  output       io_out_toPcMem_blocks_2_valid,
  output [5:0] io_out_toPcMem_blocks_2_bits_ftqIdx_value,
  output       io_out_toEncoder_blocks_0_valid,
  output [3:0] io_out_toEncoder_blocks_0_bits_ftqOffset,
  output [3:0] io_out_toEncoder_blocks_0_bits_tracePipe_itype,
  output [6:0] io_out_toEncoder_blocks_0_bits_tracePipe_iretire,
  output       io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize,
  output       io_out_toEncoder_blocks_1_valid,
  output [3:0] io_out_toEncoder_blocks_1_bits_ftqOffset,
  output [3:0] io_out_toEncoder_blocks_1_bits_tracePipe_itype,
  output [6:0] io_out_toEncoder_blocks_1_bits_tracePipe_iretire,
  output       io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize,
  output       io_out_toEncoder_blocks_2_valid,
  output [3:0] io_out_toEncoder_blocks_2_bits_ftqOffset,
  output [3:0] io_out_toEncoder_blocks_2_bits_tracePipe_itype,
  output [6:0] io_out_toEncoder_blocks_2_bits_tracePipe_iretire,
  output       io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize,
  output       io_out_blockRobCommit
);

  // --- fromRob 输入按 block 打包成数组便于 genvar 折叠 ------------------------
  wire        in_valid    [8];
  wire [5:0]  in_ftqIdxV  [8];
  wire [3:0]  in_ftqOff   [8];
  wire [3:0]  in_itype    [8];
  wire [3:0]  in_iretire  [8];
  wire        in_ilastsize[8];

  assign in_valid[0]=io_in_fromRob_blocks_0_valid; assign in_ftqIdxV[0]=io_in_fromRob_blocks_0_bits_ftqIdx_value;
  assign in_ftqOff[0]=io_in_fromRob_blocks_0_bits_ftqOffset; assign in_itype[0]=io_in_fromRob_blocks_0_bits_tracePipe_itype;
  assign in_iretire[0]=io_in_fromRob_blocks_0_bits_tracePipe_iretire; assign in_ilastsize[0]=io_in_fromRob_blocks_0_bits_tracePipe_ilastsize;
  assign in_valid[1]=io_in_fromRob_blocks_1_valid; assign in_ftqIdxV[1]=io_in_fromRob_blocks_1_bits_ftqIdx_value;
  assign in_ftqOff[1]=io_in_fromRob_blocks_1_bits_ftqOffset; assign in_itype[1]=io_in_fromRob_blocks_1_bits_tracePipe_itype;
  assign in_iretire[1]=io_in_fromRob_blocks_1_bits_tracePipe_iretire; assign in_ilastsize[1]=io_in_fromRob_blocks_1_bits_tracePipe_ilastsize;
  assign in_valid[2]=io_in_fromRob_blocks_2_valid; assign in_ftqIdxV[2]=io_in_fromRob_blocks_2_bits_ftqIdx_value;
  assign in_ftqOff[2]=io_in_fromRob_blocks_2_bits_ftqOffset; assign in_itype[2]=io_in_fromRob_blocks_2_bits_tracePipe_itype;
  assign in_iretire[2]=io_in_fromRob_blocks_2_bits_tracePipe_iretire; assign in_ilastsize[2]=io_in_fromRob_blocks_2_bits_tracePipe_ilastsize;
  assign in_valid[3]=io_in_fromRob_blocks_3_valid; assign in_ftqIdxV[3]=io_in_fromRob_blocks_3_bits_ftqIdx_value;
  assign in_ftqOff[3]=io_in_fromRob_blocks_3_bits_ftqOffset; assign in_itype[3]=io_in_fromRob_blocks_3_bits_tracePipe_itype;
  assign in_iretire[3]=io_in_fromRob_blocks_3_bits_tracePipe_iretire; assign in_ilastsize[3]=io_in_fromRob_blocks_3_bits_tracePipe_ilastsize;
  assign in_valid[4]=io_in_fromRob_blocks_4_valid; assign in_ftqIdxV[4]=io_in_fromRob_blocks_4_bits_ftqIdx_value;
  assign in_ftqOff[4]=io_in_fromRob_blocks_4_bits_ftqOffset; assign in_itype[4]=io_in_fromRob_blocks_4_bits_tracePipe_itype;
  assign in_iretire[4]=io_in_fromRob_blocks_4_bits_tracePipe_iretire; assign in_ilastsize[4]=io_in_fromRob_blocks_4_bits_tracePipe_ilastsize;
  assign in_valid[5]=io_in_fromRob_blocks_5_valid; assign in_ftqIdxV[5]=io_in_fromRob_blocks_5_bits_ftqIdx_value;
  assign in_ftqOff[5]=io_in_fromRob_blocks_5_bits_ftqOffset; assign in_itype[5]=io_in_fromRob_blocks_5_bits_tracePipe_itype;
  assign in_iretire[5]=io_in_fromRob_blocks_5_bits_tracePipe_iretire; assign in_ilastsize[5]=io_in_fromRob_blocks_5_bits_tracePipe_ilastsize;
  assign in_valid[6]=io_in_fromRob_blocks_6_valid; assign in_ftqIdxV[6]=io_in_fromRob_blocks_6_bits_ftqIdx_value;
  assign in_ftqOff[6]=io_in_fromRob_blocks_6_bits_ftqOffset; assign in_itype[6]=io_in_fromRob_blocks_6_bits_tracePipe_itype;
  assign in_iretire[6]=io_in_fromRob_blocks_6_bits_tracePipe_iretire; assign in_ilastsize[6]=io_in_fromRob_blocks_6_bits_tracePipe_ilastsize;
  assign in_valid[7]=io_in_fromRob_blocks_7_valid; assign in_ftqIdxV[7]=io_in_fromRob_blocks_7_bits_ftqIdx_value;
  assign in_ftqOff[7]=io_in_fromRob_blocks_7_bits_ftqOffset; assign in_itype[7]=io_in_fromRob_blocks_7_bits_tracePipe_itype;
  assign in_iretire[7]=io_in_fromRob_blocks_7_bits_tracePipe_iretire; assign in_ilastsize[7]=io_in_fromRob_blocks_7_bits_tracePipe_ilastsize;

  // --- s1 级寄存器(8 块) ----------------------------------------------------
  reg        s1_valid    [8];
  reg [5:0]  s1_ftqIdxV  [8];
  reg [3:0]  s1_ftqOff   [8];
  reg [3:0]  s1_itype    [8];
  reg [3:0]  s1_iretire  [8];
  reg        s1_ilastsize[8];

  wire blockCommit;  // TraceBuffer 反馈: 高则背压 s1 valid 不更新。

  genvar gi;
  generate
    for (gi = 0; gi < 8; gi++) begin : g_s1
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          s1_valid[gi]     <= 1'b0;
          s1_ftqIdxV[gi]   <= 6'h0;
          s1_ftqOff[gi]    <= 4'h0;
          s1_itype[gi]     <= 4'h0;
          s1_iretire[gi]   <= 4'h0;
          s1_ilastsize[gi] <= 1'b0;
        end
        else begin
          // valid 位: blockCommit 时保持(背压), 否则跟随输入 valid。
          if (~blockCommit)
            s1_valid[gi] <= in_valid[gi];
          // payload: 输入 valid 拍 RegEnable。
          if (in_valid[gi]) begin
            s1_ftqIdxV[gi]   <= in_ftqIdxV[gi];
            s1_ftqOff[gi]    <= in_ftqOff[gi];
            s1_itype[gi]     <= in_itype[gi];
            s1_iretire[gi]   <= in_iretire[gi];
            s1_ilastsize[gi] <= in_ilastsize[gi];
          end
        end
      end
    end
  endgenerate

  // --- TraceBuffer 输出线 ----------------------------------------------------
  wire        tb_valid    [3];
  wire [3:0]  tb_ftqOff   [3];
  wire [3:0]  tb_itype    [3];
  wire [6:0]  tb_iretire  [3];
  wire        tb_ilastsize[3];
  // ftqIdx_value 直接连到顶层 toPcMem 输出(golden 亦直连)。

  TraceBuffer traceBuffer (
    .clock                            (clock),
    .reset                            (reset),
    .io_in_fromEncoder_enable         (io_in_fromEncoder_enable),
    .io_in_fromEncoder_stall          (io_in_fromEncoder_stall),
    .io_in_fromRob_blocks_0_valid                    (s1_valid[0]),
    .io_in_fromRob_blocks_0_bits_ftqIdx_value        (s1_ftqIdxV[0]),
    .io_in_fromRob_blocks_0_bits_ftqOffset           (s1_ftqOff[0]),
    .io_in_fromRob_blocks_0_bits_tracePipe_itype     (s1_itype[0]),
    .io_in_fromRob_blocks_0_bits_tracePipe_iretire   ({3'h0, s1_iretire[0]}),
    .io_in_fromRob_blocks_0_bits_tracePipe_ilastsize (s1_ilastsize[0]),
    .io_in_fromRob_blocks_1_valid                    (s1_valid[1]),
    .io_in_fromRob_blocks_1_bits_ftqIdx_value        (s1_ftqIdxV[1]),
    .io_in_fromRob_blocks_1_bits_ftqOffset           (s1_ftqOff[1]),
    .io_in_fromRob_blocks_1_bits_tracePipe_itype     (s1_itype[1]),
    .io_in_fromRob_blocks_1_bits_tracePipe_iretire   ({3'h0, s1_iretire[1]}),
    .io_in_fromRob_blocks_1_bits_tracePipe_ilastsize (s1_ilastsize[1]),
    .io_in_fromRob_blocks_2_valid                    (s1_valid[2]),
    .io_in_fromRob_blocks_2_bits_ftqIdx_value        (s1_ftqIdxV[2]),
    .io_in_fromRob_blocks_2_bits_ftqOffset           (s1_ftqOff[2]),
    .io_in_fromRob_blocks_2_bits_tracePipe_itype     (s1_itype[2]),
    .io_in_fromRob_blocks_2_bits_tracePipe_iretire   ({3'h0, s1_iretire[2]}),
    .io_in_fromRob_blocks_2_bits_tracePipe_ilastsize (s1_ilastsize[2]),
    .io_in_fromRob_blocks_3_valid                    (s1_valid[3]),
    .io_in_fromRob_blocks_3_bits_ftqIdx_value        (s1_ftqIdxV[3]),
    .io_in_fromRob_blocks_3_bits_ftqOffset           (s1_ftqOff[3]),
    .io_in_fromRob_blocks_3_bits_tracePipe_itype     (s1_itype[3]),
    .io_in_fromRob_blocks_3_bits_tracePipe_iretire   ({3'h0, s1_iretire[3]}),
    .io_in_fromRob_blocks_3_bits_tracePipe_ilastsize (s1_ilastsize[3]),
    .io_in_fromRob_blocks_4_valid                    (s1_valid[4]),
    .io_in_fromRob_blocks_4_bits_ftqIdx_value        (s1_ftqIdxV[4]),
    .io_in_fromRob_blocks_4_bits_ftqOffset           (s1_ftqOff[4]),
    .io_in_fromRob_blocks_4_bits_tracePipe_itype     (s1_itype[4]),
    .io_in_fromRob_blocks_4_bits_tracePipe_iretire   ({3'h0, s1_iretire[4]}),
    .io_in_fromRob_blocks_4_bits_tracePipe_ilastsize (s1_ilastsize[4]),
    .io_in_fromRob_blocks_5_valid                    (s1_valid[5]),
    .io_in_fromRob_blocks_5_bits_ftqIdx_value        (s1_ftqIdxV[5]),
    .io_in_fromRob_blocks_5_bits_ftqOffset           (s1_ftqOff[5]),
    .io_in_fromRob_blocks_5_bits_tracePipe_itype     (s1_itype[5]),
    .io_in_fromRob_blocks_5_bits_tracePipe_iretire   ({3'h0, s1_iretire[5]}),
    .io_in_fromRob_blocks_5_bits_tracePipe_ilastsize (s1_ilastsize[5]),
    .io_in_fromRob_blocks_6_valid                    (s1_valid[6]),
    .io_in_fromRob_blocks_6_bits_ftqIdx_value        (s1_ftqIdxV[6]),
    .io_in_fromRob_blocks_6_bits_ftqOffset           (s1_ftqOff[6]),
    .io_in_fromRob_blocks_6_bits_tracePipe_itype     (s1_itype[6]),
    .io_in_fromRob_blocks_6_bits_tracePipe_iretire   ({3'h0, s1_iretire[6]}),
    .io_in_fromRob_blocks_6_bits_tracePipe_ilastsize (s1_ilastsize[6]),
    .io_in_fromRob_blocks_7_valid                    (s1_valid[7]),
    .io_in_fromRob_blocks_7_bits_ftqIdx_value        (s1_ftqIdxV[7]),
    .io_in_fromRob_blocks_7_bits_ftqOffset           (s1_ftqOff[7]),
    .io_in_fromRob_blocks_7_bits_tracePipe_itype     (s1_itype[7]),
    .io_in_fromRob_blocks_7_bits_tracePipe_iretire   ({3'h0, s1_iretire[7]}),
    .io_in_fromRob_blocks_7_bits_tracePipe_ilastsize (s1_ilastsize[7]),
    .io_out_blockCommit                              (blockCommit),
    .io_out_groups_blocks_0_valid                    (tb_valid[0]),
    .io_out_groups_blocks_0_bits_ftqIdx_value        (io_out_toPcMem_blocks_0_bits_ftqIdx_value),
    .io_out_groups_blocks_0_bits_ftqOffset           (tb_ftqOff[0]),
    .io_out_groups_blocks_0_bits_tracePipe_itype     (tb_itype[0]),
    .io_out_groups_blocks_0_bits_tracePipe_iretire   (tb_iretire[0]),
    .io_out_groups_blocks_0_bits_tracePipe_ilastsize (tb_ilastsize[0]),
    .io_out_groups_blocks_1_valid                    (tb_valid[1]),
    .io_out_groups_blocks_1_bits_ftqIdx_value        (io_out_toPcMem_blocks_1_bits_ftqIdx_value),
    .io_out_groups_blocks_1_bits_ftqOffset           (tb_ftqOff[1]),
    .io_out_groups_blocks_1_bits_tracePipe_itype     (tb_itype[1]),
    .io_out_groups_blocks_1_bits_tracePipe_iretire   (tb_iretire[1]),
    .io_out_groups_blocks_1_bits_tracePipe_ilastsize (tb_ilastsize[1]),
    .io_out_groups_blocks_2_valid                    (tb_valid[2]),
    .io_out_groups_blocks_2_bits_ftqIdx_value        (io_out_toPcMem_blocks_2_bits_ftqIdx_value),
    .io_out_groups_blocks_2_bits_ftqOffset           (tb_ftqOff[2]),
    .io_out_groups_blocks_2_bits_tracePipe_itype     (tb_itype[2]),
    .io_out_groups_blocks_2_bits_tracePipe_iretire   (tb_iretire[2]),
    .io_out_groups_blocks_2_bits_tracePipe_ilastsize (tb_ilastsize[2])
  );

  // --- s3 级寄存器(3 组, RegNext of TraceBuffer 输出) ----------------------
  reg        s3_valid    [3];
  reg [3:0]  s3_ftqOff   [3];
  reg [3:0]  s3_itype    [3];
  reg [6:0]  s3_iretire  [3];
  reg        s3_ilastsize[3];

  generate
    for (gi = 0; gi < 3; gi++) begin : g_s3
      always_ff @(posedge clock) begin
        s3_valid[gi]     <= tb_valid[gi];
        s3_ftqOff[gi]    <= tb_ftqOff[gi];
        s3_itype[gi]     <= tb_itype[gi];
        s3_iretire[gi]   <= tb_iretire[gi];
        s3_ilastsize[gi] <= tb_ilastsize[gi];
      end
    end
  endgenerate

  // --- 输出 -----------------------------------------------------------------
  // toPcMem: valid 来自 TraceBuffer 组输出直连(ftqIdx_value 已在 TraceBuffer 端口直连)。
  assign io_out_toPcMem_blocks_0_valid = tb_valid[0];
  assign io_out_toPcMem_blocks_1_valid = tb_valid[1];
  assign io_out_toPcMem_blocks_2_valid = tb_valid[2];
  // toEncoder: s3 寄存器。
  assign io_out_toEncoder_blocks_0_valid              = s3_valid[0];
  assign io_out_toEncoder_blocks_0_bits_ftqOffset     = s3_ftqOff[0];
  assign io_out_toEncoder_blocks_0_bits_tracePipe_itype    = s3_itype[0];
  assign io_out_toEncoder_blocks_0_bits_tracePipe_iretire  = s3_iretire[0];
  assign io_out_toEncoder_blocks_0_bits_tracePipe_ilastsize= s3_ilastsize[0];
  assign io_out_toEncoder_blocks_1_valid              = s3_valid[1];
  assign io_out_toEncoder_blocks_1_bits_ftqOffset     = s3_ftqOff[1];
  assign io_out_toEncoder_blocks_1_bits_tracePipe_itype    = s3_itype[1];
  assign io_out_toEncoder_blocks_1_bits_tracePipe_iretire  = s3_iretire[1];
  assign io_out_toEncoder_blocks_1_bits_tracePipe_ilastsize= s3_ilastsize[1];
  assign io_out_toEncoder_blocks_2_valid              = s3_valid[2];
  assign io_out_toEncoder_blocks_2_bits_ftqOffset     = s3_ftqOff[2];
  assign io_out_toEncoder_blocks_2_bits_tracePipe_itype    = s3_itype[2];
  assign io_out_toEncoder_blocks_2_bits_tracePipe_iretire  = s3_iretire[2];
  assign io_out_toEncoder_blocks_2_bits_tracePipe_ilastsize= s3_ilastsize[2];
  assign io_out_blockRobCommit = blockCommit;

endmodule
