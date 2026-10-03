// xs_Regfile_core.sv —— 后端物理寄存器堆（一片）的参数化核：Fp/Vf/V0/Vl 四类共 11 个 golden 变体共用
// =============================================================================
// 在哪一层：DataPath 里的物理寄存器堆（Chisel `class Regfile`，xiangshan/backend/regfile/Regfile.scala）。
//   og0 拍读口仲裁器（*RFReadArbiter）把读地址送进来，og1 拍拿到读数据；写回级（WbDataPath）
//   经写口把结果写进来。宽数据的堆按数据位"竖切"成几片（Part0..N），各片同地址、同读写口并行工作，
//   上层把各片读数拼回原宽度 —— 所以一个 golden 变体只看得见自己那一片的位宽。
//
// 本核覆盖的变体（参数全部从 golden 端口表/寄存器表实测，见各 wrapper 文件头）：
//   FpRegFilePart0..3  192 项 × 16 位，11 读 6 写，地址 8 位（读视图 256 行）
//   VfRegFilePart0..3  128 项 × 32 位，12 读 6 写，地址 7 位
//   V0RegFilePart0..1   22 项 × 64 位， 4 读 6 写，地址 5 位（读视图 32 行）
//   VlRegFile           32 项 ×  8 位， 4 读 4 写，地址 5 位，另有 1 个 debug 读口；0 号项异步复位为 0
//   （整数堆 IntRegFilePart0..3 有恒零的 x0，由 intrf lane 的 xs_IntRegFilePart_core 负责，不走本核。）
//   四个 Part 变体在 golden 里逐字相同（diff 只差模块名），片号只决定上层接哪几位，本核看不见。
//
// 机制（每条都与 golden bug-for-bug 一致）：
//   §1 写：每一行对各写口做 one-hot 命中（wen && addr == 行号），命中口的数据**按位或**进来
//      （Chisel Mux1H）——★不是优先级选择★：两个写口同拍写同一地址时存进去的是两份数据的按位或。
//      Chisel 用 assert 声明"不会发生"（仅仿真视图，本核不复刻），综合后的电路就是或。
//      写越界地址（地址 >= 项数，如 Fp 的 192..255）没有任何行命中，写被丢弃。
//   §2 读：同步读，延迟 1 拍。本拍把读地址打进寄存器 read_addr_q（golden 名 io_readPorts_<r>_data_REG，
//      存的是地址不是数据），下一拍用它组合地查读视图。★没有显式旁路★，但因为"先打地址、后查阵列"：
//        T 拍发起读 A，同一拍 T 有写口写 A ⇒ T+1 读出**新值**（写入与地址寄存在同一个沿生效）。
//   §3 读视图：2^ADDR_W 行，[0..NUM_PREGS-1] = 寄存器本体，★越界行 = 0 号项★（不是 0）——
//      firtool 把 Chisel Vec 越界读展开成"填第 0 项"（golden 的 _GEN 查找表里越界位置全是 mem_0）。
//   §4 debug：debug_all_rdata[i] = 第 i 项现值（0 拍延迟，不经地址寄存）；
//      debug 读口（仅 Vl 有 1 个）= 用**不打拍**的地址组合查读视图。
//
// 复位：只有 Vl 的 0 号项有复位（Chisel `if (isVlRegfile) RegInit(0.U)`，firtool 给的是异步高有效）；
//   其余全部寄存器（含各变体 0 号项与 read_addr_q）不复位。
// =============================================================================

module xs_Regfile_core #(
  parameter int unsigned NUM_PREGS       = 32,  // 物理寄存器项数
  parameter int unsigned NUM_READ        = 4,   // 同步读口数
  parameter int unsigned NUM_WRITE       = 4,   // 写口数
  parameter int unsigned DATA_W          = 8,   // 本片数据位宽
  parameter int unsigned ADDR_W          = 5,   // 物理寄存器号位宽（读视图 2^ADDR_W 行）
  parameter int unsigned NUM_DEBUG_READ  = 0,   // 组合 debug 读口数（0 或 1）
  parameter bit          MEM0_RESET      = 1'b0 // 1：0 号项异步复位为 0（仅 VlRegFile）
) (
  input  logic                                clock,
  input  logic                                reset,

  // ---- 读口：本拍给地址，下一拍出数据 ----
  input  logic [NUM_READ-1:0][ADDR_W-1:0]     read_addr,
  output logic [NUM_READ-1:0][DATA_W-1:0]     read_data,

  // ---- 写口：本拍给 wen/addr/data，下一个沿写入 ----
  input  logic [NUM_WRITE-1:0]                write_wen,
  input  logic [NUM_WRITE-1:0][ADDR_W-1:0]    write_addr,
  input  logic [NUM_WRITE-1:0][DATA_W-1:0]    write_data,

  // ---- debug：组合读口（地址不打拍）与全量读出 ----
  input  logic [(NUM_DEBUG_READ > 0 ? NUM_DEBUG_READ : 1)-1:0][ADDR_W-1:0] debug_read_addr,
  output logic [(NUM_DEBUG_READ > 0 ? NUM_DEBUG_READ : 1)-1:0][DATA_W-1:0] debug_read_data,
  output logic [NUM_PREGS-1:0][DATA_W-1:0]    debug_all_rdata
);

  localparam int unsigned NUM_ROWS = 1 << ADDR_W;  // 读视图行数（含越界补齐部分）

  // 寄存器本体：golden 的 mem_0 .. mem_<NUM_PREGS-1>
  logic [DATA_W-1:0] mem [NUM_PREGS];

  // ---------------------------------------------------------------------------
  // §1 写：每一行各自看全部写口有没有打中自己，打中的数据按位或（Mux1H）后写入
  // ---------------------------------------------------------------------------
  for (genvar row = 0; row < NUM_PREGS; row++) begin : g_row
    logic [NUM_WRITE-1:0] hit;    // hit[w]：写口 w 本拍写的正是这一行
    logic [DATA_W-1:0]    wdata;  // 命中各口数据的按位或（同址多写时就是或的结果）

    always_comb begin
      wdata = '0;
      for (int w = 0; w < NUM_WRITE; w++) begin
        hit[w] = write_wen[w] && (write_addr[w] == ADDR_W'(row));
        if (hit[w]) wdata |= write_data[w];
      end
    end

    if (row == 0 && MEM0_RESET) begin : g_reset
      always_ff @(posedge clock or posedge reset) begin
        if (reset)     mem[row] <= '0;
        else if (|hit) mem[row] <= wdata;
      end
    end else begin : g_noreset
      always_ff @(posedge clock) begin
        if (|hit) mem[row] <= wdata;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §3 读视图：2^ADDR_W 行；越界行读到的是 0 号项（firtool 的 Vec 越界语义）
  // ---------------------------------------------------------------------------
  logic [DATA_W-1:0] read_view [NUM_ROWS];
  always_comb begin
    for (int row = 0; row < NUM_ROWS; row++)
      read_view[row] = (row < NUM_PREGS) ? mem[row] : mem[0];
  end

  // ---------------------------------------------------------------------------
  // §2 读：地址先打一拍，下一拍查读视图
  // ---------------------------------------------------------------------------
  logic [NUM_READ-1:0][ADDR_W-1:0] read_addr_q;  // 不复位
  always_ff @(posedge clock) begin
    read_addr_q <= read_addr;
  end

  always_comb begin
    for (int r = 0; r < NUM_READ; r++)
      read_data[r] = read_view[read_addr_q[r]];
  end

  // ---------------------------------------------------------------------------
  // §4 debug：组合读口 + 全量读出
  // ---------------------------------------------------------------------------
  always_comb begin
    debug_read_data = '0;
    for (int d = 0; d < NUM_DEBUG_READ; d++)
      debug_read_data[d] = read_view[debug_read_addr[d]];
    for (int i = 0; i < NUM_PREGS; i++)
      debug_all_rdata[i] = mem[i];
  end

endmodule
