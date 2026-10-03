// xs_Pmpcfg_core.sv —— PMP 配置条目（pmpcfg 寄存器的一个字节）的可读核
// ---------------------------------------------------------------------------
// 位置：父模块 NewCSR 的 pmpcfgs 条目序列（Chisel 源 CSRPMP.scala 的 pmpcfgs），
//   每条目管理一个 PMP 表项的 R/W/X/A/L 五个权限位。Pmp0cfg..Pmp4cfg 五个 wrapper
//   共用本核：5 个 golden 变体去模块名后逐字节相同，条目索引只体现在父模块的
//   地址译码与模块名上，故本核无参数。
// 输入：wr_en / wr_data 是 CSR 写通路的写使能与 64 位写数据（本条目只用低 8 位）。
// 输出：rd_data 是 CSR 读视图 {L, 2'b0, A, X, W, R}；cfg_* 把各字段裸送父模块。
// 机制：5 个字段各一个异步复位（清 0）寄存器，wr_en 时从写数据装载；两条 WARL 规则——
//   1) A（地址匹配模式）写 2（NA4，本实现不支持）落为 3（NAPOT），其余编码原样落；
//   2) 写数据里 R=0 且 W=1 是保留组合：该拍 W 保持不更新（R/X/A/L 照常更新）。
//   L（lock）位只作普通字段读写，不在本层回读门控后续写（golden 即如此；锁定对
//   addr/权限的约束在 PMPEntryHandleModule 层实现，不在本模块）。
// ---------------------------------------------------------------------------
// SLOT is the architectural PMP entry number; it is not a local parent-array index.
module xs_Pmpcfg_core #(
  parameter int unsigned SLOT = 0
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        wr_en,
  input  logic [63:0] wr_data,
  output logic [7:0]  rd_data,
  output logic        cfg_r,
  output logic        cfg_w,
  output logic        cfg_x,
  output logic [1:0]  cfg_a,
  output logic        cfg_l
);
  // pmpcfg 字节内的字段位号（RISC-V 特权架构约定）：bit6:5 读出恒 0，不占寄存器
  localparam int unsigned BIT_R    = 0;
  localparam int unsigned BIT_W    = 1;
  localparam int unsigned BIT_X    = 2;
  localparam int unsigned BIT_A_LO = 3;
  localparam int unsigned BIT_A_HI = 4;
  localparam int unsigned BIT_L    = 7;

  logic       r_q;
  logic       w_q;
  logic       x_q;
  logic [1:0] a_q;
  logic       l_q;

  // WARL 规则 2：写数据 R=0 且 W=1 是保留组合，该拍抑制 W 的更新
  logic wr_w_legal;
  assign wr_w_legal = ~(~wr_data[BIT_R] & wr_data[BIT_W]);
  // WARL 规则 1：A 写 2（NA4 未实现）落为 3（NAPOT），其余编码原样落
  logic [1:0] a_warl;
  assign a_warl = (wr_data[BIT_A_HI:BIT_A_LO] == 2'd2) ? 2'd3
                                                       : wr_data[BIT_A_HI:BIT_A_LO];

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      r_q <= 1'b0;
      w_q <= 1'b0;
      x_q <= 1'b0;
      a_q <= 2'b00;
      l_q <= 1'b0;
    end else begin
      if (wr_en) begin
        r_q <= wr_data[BIT_R];
        x_q <= wr_data[BIT_X];
        a_q <= a_warl;
        l_q <= wr_data[BIT_L];
      end
      if (wr_en && wr_w_legal) begin
        w_q <= wr_data[BIT_W];
      end
    end
  end

  assign rd_data = {l_q, 2'b00, a_q, x_q, w_q, r_q};
  assign cfg_r = r_q;
  assign cfg_w = w_q;
  assign cfg_x = x_q;
  assign cfg_a = a_q;
  assign cfg_l = l_q;
endmodule
