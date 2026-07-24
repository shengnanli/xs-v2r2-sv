// 自动生成:scripts/gen_exeunit.py（ExeUnit_8）—— 勿手改(逻辑为从设计意图的可读重写)

// 核内信号声明(先于 logic/connect include)。

  // ---- FU / ClockGate / Dispatcher 子模块输出网 ----
  wire _ClockGate_1_Q;
  wire _ClockGate_2_Q;
  wire _ClockGate_Q;
  wire _Falu_io_out_bits_ctrl_fpWen;
  wire _Falu_io_out_bits_ctrl_fpu_wflags;
  wire [7:0] _Falu_io_out_bits_ctrl_pdest;
  wire _Falu_io_out_bits_ctrl_rfWen;
  wire _Falu_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] _Falu_io_out_bits_ctrl_robIdx_value;
  wire [63:0] _Falu_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _Falu_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] _Falu_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] _Falu_io_out_bits_res_data;
  wire [4:0] _Falu_io_out_bits_res_fflags;
  wire _Falu_io_out_valid;
  wire _Fcvt_io_out_bits_ctrl_fpWen;
  wire _Fcvt_io_out_bits_ctrl_fpu_wflags;
  wire [7:0] _Fcvt_io_out_bits_ctrl_pdest;
  wire _Fcvt_io_out_bits_ctrl_rfWen;
  wire _Fcvt_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] _Fcvt_io_out_bits_ctrl_robIdx_value;
  wire [63:0] _Fcvt_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _Fcvt_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] _Fcvt_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] _Fcvt_io_out_bits_res_data;
  wire [4:0] _Fcvt_io_out_bits_res_fflags;
  wire _Fcvt_io_out_valid;
  wire _Fmac_io_out_bits_ctrl_fpWen;
  wire _Fmac_io_out_bits_ctrl_fpu_wflags;
  wire [7:0] _Fmac_io_out_bits_ctrl_pdest;
  wire _Fmac_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] _Fmac_io_out_bits_ctrl_robIdx_value;
  wire [63:0] _Fmac_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _Fmac_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] _Fmac_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] _Fmac_io_out_bits_res_data;
  wire [4:0] _Fmac_io_out_bits_res_fflags;
  wire _Fmac_io_out_valid;
  wire _f2v_io_out_bits_ctrl_fpWen;
  wire [7:0] _f2v_io_out_bits_ctrl_pdest;
  wire _f2v_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] _f2v_io_out_bits_ctrl_robIdx_value;
  wire _f2v_io_out_bits_ctrl_v0Wen;
  wire _f2v_io_out_bits_ctrl_vecWen;
  wire [63:0] _f2v_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _f2v_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] _f2v_io_out_bits_perfDebugInfo_selectTime;
  wire [127:0] _f2v_io_out_bits_res_data;
  wire _f2v_io_out_valid;
  wire [1:0] _in1ToN_io_out_0_bits_fpu_fmt;
  wire [2:0] _in1ToN_io_out_0_bits_fpu_rm;
  wire [8:0] _in1ToN_io_out_0_bits_fuOpType;
  wire [63:0] _in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _in1ToN_io_out_0_bits_perfDebugInfo_issueTime;
  wire [63:0] _in1ToN_io_out_0_bits_perfDebugInfo_selectTime;
  wire _in1ToN_io_out_0_valid;
  wire [1:0] _in1ToN_io_out_1_bits_fpu_fmt;
  wire [2:0] _in1ToN_io_out_1_bits_fpu_rm;
  wire [8:0] _in1ToN_io_out_1_bits_fuOpType;
  wire [63:0] _in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _in1ToN_io_out_1_bits_perfDebugInfo_issueTime;
  wire [63:0] _in1ToN_io_out_1_bits_perfDebugInfo_selectTime;
  wire _in1ToN_io_out_1_valid;
  wire _in1ToN_io_out_2_bits_fpWen;
  wire [8:0] _in1ToN_io_out_2_bits_fuOpType;
  wire [7:0] _in1ToN_io_out_2_bits_pdest;
  wire [63:0] _in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _in1ToN_io_out_2_bits_perfDebugInfo_issueTime;
  wire [63:0] _in1ToN_io_out_2_bits_perfDebugInfo_selectTime;
  wire _in1ToN_io_out_2_bits_robIdx_flag;
  wire [7:0] _in1ToN_io_out_2_bits_robIdx_value;
  wire _in1ToN_io_out_2_bits_v0Wen;
  wire _in1ToN_io_out_2_bits_vecWen;
  wire _in1ToN_io_out_2_valid;
  wire [1:0] _in1ToN_io_out_3_bits_fpu_fmt;
  wire [2:0] _in1ToN_io_out_3_bits_fpu_rm;
  wire [8:0] _in1ToN_io_out_3_bits_fuOpType;
  wire [63:0] _in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime;
  wire [63:0] _in1ToN_io_out_3_bits_perfDebugInfo_issueTime;
  wire [63:0] _in1ToN_io_out_3_bits_perfDebugInfo_selectTime;
  wire _in1ToN_io_out_3_valid;

  // ---- §1 inPipe 流水状态:控制位链(深度 LAT_MAX)+ 有效位链 ----
  //   ctrl_pipe[k] = 进入后第 (k+1) 拍的控制位;valid_pipe[k] 同步的有效位(带 flush-kill)。
  ctrl_t ctrl_pipe [LAT_MAX];
  logic  valid_pipe[LAT_MAX];

  // ---- fuOpType / rfWen 专用浅链(只到各自最深消费级)----
  //   fuOpType 最深消费者 = Fcvt(第1级)⇒ 存 [0],[1];镜像 golden inPipe_1_1/1_2_fuOpType。
  //   rfWen    最深消费者 = Fcvt(第1级)⇒ 存 [0],[1];镜像 golden inPipe_1_1/1_2_rfWen。
  //   最深级(Fmac=第2级)不存这两字段(golden inPipe_1_3 亦无)⇒ 无死位。
  logic [8:0] op_pipe [2];
  logic       rf_pipe [2];

  // ---- §2 时钟门控使能链:每个有延迟 FU 一条有效移位链 + 一拍延迟寄存 ----
  logic [1:0] fuvld_Falu;   // [0]=入口有效, [1..1]=在飞各级
  logic           fuvld_q_Falu;  // clk_en 的一拍寄存
  logic [2:0] fuvld_Fcvt;   // [0]=入口有效, [1..2]=在飞各级
  logic           fuvld_q_Fcvt;  // clk_en 的一拍寄存
  logic [3:0] fuvld_Fmac;   // [0]=入口有效, [1..3]=在飞各级
  logic           fuvld_q_Fmac;  // clk_en 的一拍寄存
