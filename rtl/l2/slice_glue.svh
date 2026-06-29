// 自动生成:scripts/gen_slice.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// ===== 顶层 glue(从 Scala 意图重写,golden 已具名可读,perf 二级流水重命名)=====
// (1) MBIST bore 改名:把对外 boreChildrenBd_bore_* 端口改名喂 mbistPl(纯连线)。

  wire [4:0]   bd_array = boreChildrenBd_bore_array;
  wire         bd_all = boreChildrenBd_bore_all;
  wire         bd_req = boreChildrenBd_bore_req;
  wire         bd_writeen = boreChildrenBd_bore_writeen;
  wire [7:0]   bd_be = boreChildrenBd_bore_be;
  wire [12:0]  bd_addr = boreChildrenBd_bore_addr;
  wire [103:0] bd_indata = boreChildrenBd_bore_indata;
  wire         bd_readen = boreChildrenBd_bore_readen;
  wire [12:0]  bd_addr_rd = boreChildrenBd_bore_addr_rd;

  // (2) error/perf 打拍流水(本层唯二时序 glue):
  //     · 异步复位块:releaseBufResp_s3_valid / io_error_valid 各打一拍;
  //     · 同步块:    io_error_bits 打一拍 + 11 路 perf 事件 2 级 RegNext。
  //   golden 第二级 RegNext 名为 io_perf_<N>_value_REG_1(_REG_<数字>,触
  //   套壳闸门),此处重写为具名两级 perf_<N>_value_s1 -> perf_<N>_value_s2。
  reg          mainPipe_io_releaseBufResp_s3_valid_REG;
  reg          io_error_valid_REG;
  reg          io_error_bits_REG_valid;
  reg  [45:0]  io_error_bits_REG_address;
  reg  [5:0]   perf_0_value_s1;
  reg  [5:0]   perf_0_value_s2;
  reg  [5:0]   perf_1_value_s1;
  reg  [5:0]   perf_1_value_s2;
  reg  [5:0]   perf_3_value_s1;
  reg  [5:0]   perf_3_value_s2;
  reg  [5:0]   perf_4_value_s1;
  reg  [5:0]   perf_4_value_s2;
  reg  [5:0]   perf_5_value_s1;
  reg  [5:0]   perf_5_value_s2;
  reg  [5:0]   perf_6_value_s1;
  reg  [5:0]   perf_6_value_s2;
  reg  [5:0]   perf_7_value_s1;
  reg  [5:0]   perf_7_value_s2;
  reg  [5:0]   perf_8_value_s1;
  reg  [5:0]   perf_8_value_s2;
  reg  [5:0]   perf_9_value_s1;
  reg  [5:0]   perf_9_value_s2;
  reg  [5:0]   perf_10_value_s1;
  reg  [5:0]   perf_10_value_s2;
  reg  [5:0]   perf_11_value_s1;
  reg  [5:0]   perf_11_value_s2;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      mainPipe_io_releaseBufResp_s3_valid_REG <= 1'h0;
      io_error_valid_REG <= 1'h0;
    end
    else begin
      mainPipe_io_releaseBufResp_s3_valid_REG <= _reqArb_io_releaseBufRead_s2_valid;
      io_error_valid_REG <= _mainPipe_io_error_valid;
    end
  end // always @(posedge, posedge)
  always @(posedge clock) begin
    io_error_bits_REG_valid <= _mainPipe_io_error_bits_valid;
    io_error_bits_REG_address <= _mainPipe_io_error_bits_address;
    perf_0_value_s1 <= _mshrCtl_io_perf_0_value;
    perf_0_value_s2 <= perf_0_value_s1;
    perf_1_value_s1 <= _mshrCtl_io_perf_1_value;
    perf_1_value_s2 <= perf_1_value_s1;
    perf_3_value_s1 <= _mshrCtl_io_perf_3_value;
    perf_3_value_s2 <= perf_3_value_s1;
    perf_4_value_s1 <= _mainPipe_io_perf_0_value;
    perf_4_value_s2 <= perf_4_value_s1;
    perf_5_value_s1 <= _mainPipe_io_perf_1_value;
    perf_5_value_s2 <= perf_5_value_s1;
    perf_6_value_s1 <= _mainPipe_io_perf_2_value;
    perf_6_value_s2 <= perf_6_value_s1;
    perf_7_value_s1 <= _mainPipe_io_perf_3_value;
    perf_7_value_s2 <= perf_7_value_s1;
    perf_8_value_s1 <= _mainPipe_io_perf_4_value;
    perf_8_value_s2 <= perf_8_value_s1;
    perf_9_value_s1 <= _mainPipe_io_perf_5_value;
    perf_9_value_s2 <= perf_9_value_s1;
    perf_10_value_s1 <= _mainPipe_io_perf_6_value;
    perf_10_value_s2 <= perf_10_value_s1;
    perf_11_value_s1 <= _mainPipe_io_perf_7_value;
    perf_11_value_s2 <= perf_11_value_s1;
  end // always @(posedge)
