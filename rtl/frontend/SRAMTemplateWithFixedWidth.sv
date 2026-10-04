// SRAMTemplateWithFixedWidth.sv —— ICache 数据阵列的一块"定宽切分"SRAM（家族基础变体）
//
// 位置：ICacheDataArray 里每个 (way, bank) 一块（frontend/icache/ICache.scala:437 例化，
//   类定义在同文件 :835）。它的本职是把一条 dataBits 位的数据按固定宽度 width 切成
//   bankNum = ceil(dataBits/width) 块、每块一个 SRAMTemplate，读回再拼起来，让所有 ICache
//   数据 SRAM 宏都是同一个尺寸。
// 本配置：dataBits = 65（ICacheDataEntryBits：64 位数据 + 1 位校验），width = 66，
//   所以 bankNum = 1 —— 只有一块 66 位宽的 SRAM：写入时高位补 1 个 0，读出时截掉最高位。
//   本层没有寄存器、没有运算，读写握手（ready）因父级不用被 firtool 删掉了。
// 家族：本文件与 _4 / _12 / _28 四个变体逻辑完全相同，唯一差别是内层 SRAMTemplate 的单态化
//   （SRAMTemplate_4 / _8 / _16 / _32），它们之间只差 MBIST bore_array 位宽（3/4/5/6 位，
//   ICache 数据阵列 32 块 SRAM 的 MBIST array 编号越往后越大，firtool 按最小位宽生成）。
//   子模块的模块名不能参数化，所以每个变体自带这一处例化（由生成器从 golden 核对后产出）。
// golden 146 行 / 25 端口；唯一子模块 SRAMTemplate_4（已独立签核）。
// 本文件由 scripts/gen_sram_fixed_width.py 从 golden 机械生成并逐端口核对（勿手改）。

// BEGIN GENERATED(SRAMTemplateWithFixedWidth) —— scripts/gen_sram_fixed_width.py
module SRAMTemplateWithFixedWidth (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_r_req_valid,
  input  logic [7:0]  io_r_req_bits_setIdx,
  output logic [64:0] io_r_resp_data_0,
  input  logic        io_w_req_valid,
  input  logic [7:0]  io_w_req_bits_setIdx,
  input  logic [64:0] io_w_req_bits_data_0,
  input  logic [8:0]  boreChildrenBd_bore_addr,
  input  logic [8:0]  boreChildrenBd_bore_addr_rd,
  input  logic [65:0] boreChildrenBd_bore_wdata,
  input  logic        boreChildrenBd_bore_wmask,
  input  logic        boreChildrenBd_bore_re,
  input  logic        boreChildrenBd_bore_we,
  output logic [65:0] boreChildrenBd_bore_rdata,
  input  logic        boreChildrenBd_bore_ack,
  input  logic        boreChildrenBd_bore_selectedOH,
  input  logic [2:0]  boreChildrenBd_bore_array,
  input  logic        sigFromSrams_bore_ram_hold,
  input  logic        sigFromSrams_bore_ram_bypass,
  input  logic        sigFromSrams_bore_ram_bp_clken,
  input  logic        sigFromSrams_bore_ram_aux_clk,
  input  logic        sigFromSrams_bore_ram_aux_ckbp,
  input  logic        sigFromSrams_bore_ram_mcp_hold,
  input  logic        sigFromSrams_bore_cgen
);

  localparam int unsigned DATA_W = 65;   // ICacheDataEntryBits
  localparam int unsigned SRAM_W = 66;   // ICacheDataSRAMWidth（bankNum = 1）

  logic [SRAM_W-1:0] sram_rdata;

  // 唯一一块 SRAM：写数据零扩展到 SRAM 宽，DFT 广播/bore 口原样透传
  SRAMTemplate_4 srams_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (io_r_req_valid),
    .io_r_req_bits_setIdx           (io_r_req_bits_setIdx),
    .io_r_resp_data_0               (sram_rdata),
    .io_w_req_valid                 (io_w_req_valid),
    .io_w_req_bits_setIdx           (io_w_req_bits_setIdx),
    .io_w_req_bits_data_0           (SRAM_W'(io_w_req_bits_data_0)),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_array),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen)
  );

  // 读回截掉补的最高位
  assign io_r_resp_data_0 = sram_rdata[DATA_W-1:0];

endmodule
// END GENERATED(SRAMTemplateWithFixedWidth)
