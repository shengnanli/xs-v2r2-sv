// 自动生成:scripts/gen_exeunit.py（ExeUnit）—— 勿手改(逻辑为从设计意图的可读重写)

// 核内信号声明(先于 logic/connect include)。

  // ---- FU / ClockGate / Dispatcher 子模块输出网 ----
  wire [7:0] _Alu_io_out_bits_ctrl_pdest;
  wire _Alu_io_out_bits_ctrl_rfWen;
  wire _Alu_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] _Alu_io_out_bits_ctrl_robIdx_value;
  wire [63:0] _Alu_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _Alu_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] _Alu_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] _Alu_io_out_bits_res_data;
  wire _Alu_io_out_valid;
  wire [7:0] _Bku_io_out_bits_ctrl_pdest;
  wire _Bku_io_out_bits_ctrl_rfWen;
  wire _Bku_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] _Bku_io_out_bits_ctrl_robIdx_value;
  wire [63:0] _Bku_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _Bku_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] _Bku_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] _Bku_io_out_bits_res_data;
  wire _Bku_io_out_valid;
  wire _ClockGate_1_Q;
  wire _ClockGate_Q;
  wire [7:0] _Mul_io_out_bits_ctrl_pdest;
  wire _Mul_io_out_bits_ctrl_rfWen;
  wire _Mul_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] _Mul_io_out_bits_ctrl_robIdx_value;
  wire [63:0] _Mul_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _Mul_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] _Mul_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] _Mul_io_out_bits_res_data;
  wire _Mul_io_out_valid;
  wire [8:0] _in1ToN_io_out_0_bits_fuOpType;
  wire [63:0] _in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _in1ToN_io_out_0_bits_perfDebugInfo_issueTime;
  wire [63:0] _in1ToN_io_out_0_bits_perfDebugInfo_selectTime;
  wire _in1ToN_io_out_0_valid;
  wire [8:0] _in1ToN_io_out_1_bits_fuOpType;
  wire [63:0] _in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _in1ToN_io_out_1_bits_perfDebugInfo_issueTime;
  wire [63:0] _in1ToN_io_out_1_bits_perfDebugInfo_selectTime;
  wire _in1ToN_io_out_1_valid;
  wire [8:0] _in1ToN_io_out_2_bits_fuOpType;
  wire [63:0] _in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _in1ToN_io_out_2_bits_perfDebugInfo_issueTime;
  wire [63:0] _in1ToN_io_out_2_bits_perfDebugInfo_selectTime;
  wire _in1ToN_io_out_2_valid;

  // ---- §1 inPipe 流水状态:控制位链(深度 LAT_MAX)+ 有效位链 ----
  //   ctrl_pipe[k] = 进入后第 (k+1) 拍的控制位;valid_pipe[k] 同步的有效位(带 flush-kill)。
  ctrl_t ctrl_pipe [LAT_MAX];
  logic  valid_pipe[LAT_MAX];

  // ---- §2 时钟门控使能链:每个有延迟 FU 一条有效移位链 + 一拍延迟寄存 ----
  logic [2:0] fuvld_Mul;   // [0]=入口有效, [1..2]=在飞各级
  logic           fuvld_q_Mul;  // clk_en 的一拍寄存
  logic [2:0] fuvld_Bku;   // [0]=入口有效, [1..2]=在飞各级
  logic           fuvld_q_Bku;  // clk_en 的一拍寄存
