// =============================================================================
// xs_RegFilePart_core —— 物理寄存器堆分片(可读重写,参数化覆盖 8 个 PartN)
// -----------------------------------------------------------------------------
// 对应 Scala: xiangshan.backend.regfile.Regfile(由 IntRegFileSplit/FpRegFileSplit
// 按数据位竖切例化出 IntRegFilePart0..3 / FpRegFilePart0..3)。
//
// 本核用 parameter 抽象掉 Int/Fp 与各 Part 的差异,一份代码覆盖全部 8 个分片:
//   NUM_PREGS   : 物理寄存器数(Int=224, Fp=192)
//   NUM_READ    : 同步读口数(=11)
//   NUM_WRITE   : 写口数(Int=8, Fp=6)
//   NUM_DEBUG   : 异步 debug 读口数(=32)
//   DATA_WIDTH  : 本分片每个寄存器的位宽(=16,即全宽 64 切 4)
//   ADDR_WIDTH  : 地址位宽(=8)
//   HAS_ZERO    : 是否寄存器 0 恒为 0(Int=1 实现 x0; Fp=0)
//
// 三类端口的时序:
//   读口 readPorts   —— 同步读:地址打 1 拍(rd_addr_reg) → 查 memForRead → 数据(延迟1拍)
//   写口 writePorts  —— 同步写:one-hot 命中 + Mux1H 写数据,无写读旁路
//   debug 读口        —— 异步读:当拍地址直查 memForRead(延迟0拍),仅供调试
//
// 微架构注释见 regfile_pkg.sv 顶部。
// =============================================================================
module xs_RegFilePart_core #(
  parameter int unsigned NUM_PREGS  = 224,
  parameter int unsigned NUM_READ   = 11,
  parameter int unsigned NUM_WRITE  = 8,
  parameter int unsigned NUM_DEBUG  = 32,
  parameter int unsigned DATA_WIDTH = 16,
  parameter int unsigned ADDR_WIDTH = 8,
  parameter bit          HAS_ZERO   = 1'b1
) (
  input  logic                                  clock,
  input  logic                                  reset,

  // ---- 同步读口(读延迟 1 拍)----
  input  logic [NUM_READ-1:0][ADDR_WIDTH-1:0]   read_addr,
  output logic [NUM_READ-1:0][DATA_WIDTH-1:0]   read_data,

  // ---- 写口(同步写,无旁路)----
  input  logic [NUM_WRITE-1:0]                  write_wen,
  input  logic [NUM_WRITE-1:0][ADDR_WIDTH-1:0]  write_addr,
  input  logic [NUM_WRITE-1:0][DATA_WIDTH-1:0]  write_data,

  // ---- debug 异步读口(读延迟 0 拍)----
  input  logic [NUM_DEBUG-1:0][ADDR_WIDTH-1:0]  debug_addr,
  output logic [NUM_DEBUG-1:0][DATA_WIDTH-1:0]  debug_data
);

  // 地址空间总项数:地址 ADDR_WIDTH-bit 可寻址 2^ADDR_WIDTH 项。
  localparam int unsigned NUM_ROWS = (1 << ADDR_WIDTH);

  // ---------------------------------------------------------------------------
  // 寄存器本体(物理寄存器阵列)
  //   - HAS_ZERO 时(Int:x0 恒 0),索引 0 **不存在寄存器**:写被丢弃,读恒 0。
  //     golden(firtool)对 Int 只声明 mem_1..mem_223(无 mem_0),因此本核也
  //     完全跳过 row 0——既不声明也不驱动 mem[0],避免产生「写 0 却永不被读」
  //     的 impl-only cone-dead 寄存器(FM signoff-strict 会判 unread_impl→PARTIAL)。
  //   - HAS_ZERO=0 时(Fp/Vf/V0):索引 0 是普通可写寄存器,golden 有 mem_0,保留。
  // mem_for_read[0] 在读视图里对 HAS_ZERO 直接接常数 '0,故省略 mem[0] 无功能影响。
  // ---------------------------------------------------------------------------
  logic [NUM_PREGS-1:0][DATA_WIDTH-1:0] mem;

  // ---------------------------------------------------------------------------
  // 写逻辑:对每个物理寄存器,各写口做 one-hot 命中(wen && addr 命中本行),
  //         用 Mux1H 选出写入数据。Scala 保证多写口不会同拍写同地址(assert),
  //         故 one-hot 至多一位为 1,这里用按位或/带优先的 mux 都等价。
  // ---------------------------------------------------------------------------
  for (genvar row = 0; row < NUM_PREGS; row++) begin : g_write
    if (HAS_ZERO && row == 0) begin : g_zero_reg
      // x0:此处**不生成任何寄存器**(与 golden 一致:Int 无 mem_0)。
      // 写入 addr==0 天然被丢弃(下面 g_norm_reg 的命中比较从 row=1 起),
      // 读 mem_for_read[0] 直接接 '0。故 row 0 无状态、无命中逻辑。
    end else begin : g_norm_reg
      // 本行被哪些写口命中
      logic [NUM_WRITE-1:0] hit;
      logic [DATA_WIDTH-1:0] wdata;

      always_comb begin
        hit   = '0;
        wdata = '0;
        for (int unsigned w = 0; w < NUM_WRITE; w++) begin
          hit[w] = write_wen[w] && (write_addr[w] == ADDR_WIDTH'(row));
          // Mux1H:命中口的数据按位或进来(非命中口贡献 0)
          wdata |= hit[w] ? write_data[w] : '0;
        end
      end

      // 普通物理寄存器:有命中才更新(写使能合并自所有口的 one-hot)。
      always_ff @(posedge clock) begin
        if (|hit) begin
          mem[row] <= wdata;
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // memForRead:供读口/ debug 口查表的 256 项视图。
  //   - 索引 0:HAS_ZERO 时恒 0(x0),否则为 mem[0]。
  //   - 索引 1..NUM_PREGS-1:对应寄存器本体。
  //   - 索引 NUM_PREGS..255:padding(超出物理寄存器范围,正常不会被寻址)。
  //     与 golden 对齐:Int 填 0,Fp 填 mem[0]。
  // ---------------------------------------------------------------------------
  logic [NUM_ROWS-1:0][DATA_WIDTH-1:0] mem_for_read;
  for (genvar i = 0; i < NUM_ROWS; i++) begin : g_memview
    if (i == 0) begin : g_v0
      assign mem_for_read[0] = (HAS_ZERO) ? '0 : mem[0];
    end else if (i < NUM_PREGS) begin : g_vreg
      assign mem_for_read[i] = mem[i];
    end else begin : g_vpad
      // padding:Int(HAS_ZERO)填 0;Fp 填 mem[0](与 firtool golden 一致)。
      assign mem_for_read[i] = (HAS_ZERO) ? '0 : mem[0];
    end
  end

  // ---------------------------------------------------------------------------
  // 同步读口:第 1 拍寄存读地址,第 2 拍用寄存地址查表 → 读延迟 1 拍。
  // ---------------------------------------------------------------------------
  logic [NUM_READ-1:0][ADDR_WIDTH-1:0] rd_addr_reg;
  for (genvar r = 0; r < NUM_READ; r++) begin : g_read
    always_ff @(posedge clock) begin
      rd_addr_reg[r] <= read_addr[r];
    end
    assign read_data[r] = mem_for_read[rd_addr_reg[r]];
  end

  // ---------------------------------------------------------------------------
  // debug 异步读口:当拍地址直接查表(延迟 0 拍),供 difftest/调试观测寄存器现态。
  // ---------------------------------------------------------------------------
  for (genvar d = 0; d < NUM_DEBUG; d++) begin : g_debug
    assign debug_data[d] = mem_for_read[debug_addr[d]];
  end

endmodule : xs_RegFilePart_core
