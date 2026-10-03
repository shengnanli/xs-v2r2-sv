// xs_IntRegFilePart_core.sv —— 整数物理寄存器堆的一片（16 位数据切片），IntRegFilePart0..3 共用核
// =============================================================================
// 在哪一层：后端 DataPath 里的整数物理寄存器堆（Chisel `class Regfile`，
//   xiangshan/backend/regfile/Regfile.scala）。64 位整数寄存器按数据位"竖切"成 4 片，
//   每片 16 位，四片同地址、同读写口并行工作，上层把四片读出再拼回 64 位。
//   IntRegFilePart0..3 就是这四片；它们在 G1 golden 里**逐字相同**（四个 7012 行文件
//   diff 只差第 87 行的模块名），片号只决定上层把哪 16 位接进来，本模块内部看不见。
//
// 规模（KunminghuV2Config，从 golden 端口表/寄存器表现数）：
//   224 个物理寄存器（地址 8 位，可寻址 256 项）、11 个读口、8 个写口、16 位数据；
//   223 路 debug 全量读出（debug_all_rdata_1..223，没有 _0：x0 那一路被 firtool 连端口一起消掉了）。
//   寄存器共 223×16 + 11×8 = 3656 位，全部**不复位**；reset 在综合视图里没有负载
//   （golden 只在 `ifndef SYNTHESIS 的同址写断言里用它）。
//
// 三件事一目了然（每件都与 golden bug-for-bug 一致）：
//   §1 写：N=8 个写口 × 223 行。每行对各写口做 one-hot 命中（wen && addr==行号），命中口的
//      数据**按位或**进来（Chisel Mux1H）——★不是优先级选择★：两个写口同拍写同一地址时，
//      存进去的是两份数据的按位或。Chisel 用 assert 声明"不会发生"，但综合后的电路就是或。
//      写 x0（地址 0）与写越界地址（224..255）都没有任何行命中，写被丢弃。
//   §2 读：M=11 个读口，**同步读，延迟 1 拍**。本拍把读地址打进寄存器 raddr_q，下一拍用它
//      组合地查 256 项读视图。★没有显式旁路★，但由于是"先打地址、后查阵列"：
//        本拍 T 发起读 A，同一拍 T 有写口写 A  ⇒ T+1 读出的是**新值**（写和地址寄存在同一个沿生效）；
//        T+1 拍再写 A                          ⇒ 不影响 T+1 的读出（阵列是寄存器，要到下一个沿才变）。
//   §3 读视图（256 项查找表）：[0]=0（x0 恒零，根本没有寄存器）、[1..223]=寄存器本体、
//      [224..255]=0（越界读得 0，firtool 用常零补齐到 2^8 项）。
//   另有 §4 debug 全量读出：第 i 路就是第 i 个寄存器的现值（0 拍延迟，不经过读地址寄存）。
//
// 边界/怪癖：
//   * 寄存器阵列声明为 mem[1:NUM_PREGS-1]：golden 只有 mem_1..mem_223，没有 mem_0。
//     多开一个 mem[0] 会成为 golden 没有的比较点（FM strict 判 unmatched），所以不开。
//   * 读地址寄存器 raddr_q 对应 golden 的 io_readPorts_<r>_data_REG（8 位，存的是地址不是数据）。
//   * 同址多写的断言（Regfile.scala:116）只存在于仿真视图，本核不复刻；按位或的行为已在 §1 写明。
// =============================================================================

module xs_IntRegFilePart_core #(
  parameter int unsigned NUM_PREGS = 224,  // 物理寄存器数（含恒零的 x0）
  parameter int unsigned NUM_READ  = 11,   // 同步读口数
  parameter int unsigned NUM_WRITE = 8,    // 写口数
  parameter int unsigned DATA_W    = 16,   // 本片数据位宽（64 位切 4 片）
  parameter int unsigned ADDR_W    = 8     // 物理寄存器号位宽
) (
  input  logic                               clock,
  input  logic                               reset,            // 综合视图无负载（见文件头）

  // ---- 读口：本拍给地址，下一拍出数据 ----
  input  logic [NUM_READ-1:0][ADDR_W-1:0]    read_addr,
  output logic [NUM_READ-1:0][DATA_W-1:0]    read_data,

  // ---- 写口：本拍给 wen/addr/data，下一个沿写入 ----
  input  logic [NUM_WRITE-1:0]               write_wen,
  input  logic [NUM_WRITE-1:0][ADDR_W-1:0]   write_addr,
  input  logic [NUM_WRITE-1:0][DATA_W-1:0]   write_data,

  // ---- debug 全量读出：下标 = 物理寄存器号；[0] 恒 0（wrapper 不引出） ----
  output logic [NUM_PREGS-1:0][DATA_W-1:0]   debug_all_rdata
);

  // 读视图的项数：地址 ADDR_W 位能寻址的全部 2^ADDR_W 项（含越界补零部分）。
  localparam int unsigned NUM_ROWS = 1 << ADDR_W;

  // 寄存器本体：1..NUM_PREGS-1，没有 0 号（x0 恒零，不占寄存器）。
  logic [DATA_W-1:0] mem [1:NUM_PREGS-1];

  // ---------------------------------------------------------------------------
  // §1 写：每一行各自看 8 个写口有没有打中自己，打中的数据按位或（Mux1H）后写入
  // ---------------------------------------------------------------------------
  for (genvar row = 1; row < NUM_PREGS; row++) begin : g_row
    logic [NUM_WRITE-1:0] hit;      // hit[w]：写口 w 本拍写的正是这一行
    logic [DATA_W-1:0]    wdata;    // 命中各口数据的按位或（同址多写时就是或的结果）

    always_comb begin
      wdata = '0;
      for (int w = 0; w < NUM_WRITE; w++) begin
        hit[w] = write_wen[w] && (write_addr[w] == ADDR_W'(row));
        if (hit[w]) wdata |= write_data[w];
      end
    end

    always_ff @(posedge clock) begin
      if (|hit) mem[row] <= wdata;
    end
  end

  // ---------------------------------------------------------------------------
  // §3 读视图：256 项查找表 = {x0 常零, 寄存器本体, 越界常零}
  //   （先于 §2 给出，因为读口查的就是它）
  // ---------------------------------------------------------------------------
  logic [NUM_ROWS-1:0][DATA_W-1:0] mem_for_read;

  for (genvar i = 0; i < NUM_ROWS; i++) begin : g_view
    if (i >= 1 && i < NUM_PREGS) begin : g_reg
      assign mem_for_read[i] = mem[i];
    end else begin : g_zero
      assign mem_for_read[i] = '0;   // i==0：x0；i>=NUM_PREGS：越界
    end
  end

  // ---------------------------------------------------------------------------
  // §2 读：地址打一拍（raddr_q），下一拍用打过拍的地址组合查读视图
  // ---------------------------------------------------------------------------
  logic [NUM_READ-1:0][ADDR_W-1:0] raddr_q;

  always_ff @(posedge clock) begin
    raddr_q <= read_addr;
  end

  always_comb begin
    for (int r = 0; r < NUM_READ; r++) begin
      read_data[r] = mem_for_read[raddr_q[r]];
    end
  end

  // ---------------------------------------------------------------------------
  // §4 debug 全量读出：寄存器现值直出（x0 那一路恒 0）
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < NUM_PREGS; i++) begin
      debug_all_rdata[i] = mem_for_read[i];
    end
  end

endmodule
