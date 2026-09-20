// =============================================================================
// L1ErrorMetaArray.sv —— L1 DCache 错误(TLError)元数据阵列：记录每条 cacheline
//                        上一次访问带回来的 TileLink 错误位(denied/corrupt)
//
// 对应 Chisel: xiangshan/cache/dcache/meta/AsynchronousMetaArray.scala
//                class L1ErrorMetaArray(readPorts, writePorts, enableBypass=true)
// 例化处:     xiangshan/cache/dcache/DCacheWrapper.scala:1021  DCache.errorArray
//               new L1ErrorMetaArray(readPorts = LoadPipelineWidth + 1 = 4,
//                                    writePorts = 1, enableBypass = true)
//
// -----------------------------------------------------------------------------
// 它在 DCache 里干什么
// -----------------------------------------------------------------------------
// TileLink 的 D 通道响应带两个错误标志：denied（请求被拒，地址不可访问）和
// corrupt（数据损坏）。DCache refill 一条 cacheline 时把这两位记下来，挂在
// (set, way) 上；之后凡是命中这条线的 load，都要把这两位跟着数据一起送回 LSU，
// 由 LSU 转成访存异常/硬件错误上报。本阵列就是这张 (set × way) -> {denied,corrupt}
// 的表：3 条 load 流水 + 1 条 main pipe 共 4 个读口，refill/probe 侧 1 个写口。
//
// 它**不做 tag 命中判断**：读只给 idx，一次把该 set 下全部 4 个 way 的错误位都
// 返回，由上层拿 tag 比较结果去选 way。
//
// -----------------------------------------------------------------------------
// 为什么叫"异步"阵列 / 为什么要读旁路
// -----------------------------------------------------------------------------
// 存储用**寄存器堆**而不是 SRAM（256 set × 4 way × 2 bit = 2048 个 DFF），所以
// 读是组合的、不需要 SRAM 的时序约束——Chisel 里这一族叫 AsynchronousMetaArray。
//
// 写却是 2 拍流水：S0 收请求并按 way_en 拆到各 way，S1（打一拍之后）才真正落进
// meta_array。于是一条读请求若 idx 撞上"正在 S0 或 S1 在途的写"，直接读寄存器堆
// 会拿到旧值。故对每个 (读口, way) 独立做在途写转发(bypass)。
//
// 时序（读 1 拍延迟）：
//   S0：采样 io_read[i].idx；同时算出本读口本 way 是否命中在途写(sel)与转发数据。
//   S0->S1 三个锁存，使能各不相同（**必须逐字保持，FM 比的就是这个**）：
//       sel_r        <= sel                 使能 = io_read[i].valid
//       bypass_r     <= bypass_data         使能 = sel            ← 不是 read.valid
//       read_idx_r   <= io_read[i].idx      使能 = io_read[i].valid
//   S1：io_resp[i][way] = sel_r ? bypass_r : meta_array[read_idx_r][way]
//
//   ★与兄弟模块 L1CohMetaArray 的唯一结构差别★：Coh 走 bypassRead=true 分支，
//     非旁路路径锁存的是**数据**（S0 读出寄存器堆再打一拍）；本模块走的是
//     `meta_array(RegEnable(read.bits.idx, read.valid))(way)`，锁存的是**地址**，
//     在 S1 组合读寄存器堆。两者在"meta_array 只在 S1 边沿更新"的前提下功能等价，
//     但寄存器数量与连接不同，不能互抄。
//
// 在途写转发的优先级（复刻 Chisel 的 when 链，后写覆盖先写）：
//   先看 S1 在途写，再看 S0 在途写 —— **S0 优先**（它更新，还没进 S1）。
//   两者都不命中时 bypass_data 在 Chisel 里是 DontCare，但此时 sel=0，
//   锁存使能关闭，该值不会被采样，也不会被选中，故取 '0 不影响等价性。
//
// -----------------------------------------------------------------------------
// 关于 golden 的 14951 行
// -----------------------------------------------------------------------------
// golden 是 firtool 把 1024 个条目**逐条展平**的结果：2048 条 reg 声明、8 条
// 256 位 concat 向量（把寄存器堆重新聚成可下标访问的向量）、一个含 4096 条
// 非阻塞赋值的 always 块（2048 条复位 + 1024 个 `if (wen & addr==常数)` 写译码）、
// 以及 4197 行 `ifdef ENABLE_INITIAL_REG_` 随机初始化。真逻辑是 Chisel 里的 60 行。
// =============================================================================
package xs_l1errmetaarray_pkg;

  // ---------------- 物理参数（KunmingHu V2R2，DCacheParameters）----------------
  localparam int N_SETS   = 256;   // nSets
  localparam int IDX_BITS = 8;     // log2(nSets)，与 golden 的 io_*_bits_idx 位宽一致
  localparam int N_WAYS   = 4;     // nWays

  // TileLink 错误元数据条目（对应 Chisel bundle TLError）
  // 字段顺序与 golden 展平端口顺序一致：先 tl_denied 后 tl_corrupt
  typedef struct packed {
    logic tl_denied;   // TileLink D 通道 denied：请求被目标拒绝（地址不可访问）
    logic tl_corrupt;  // TileLink D 通道 corrupt：返回数据损坏
  } tl_error_t;

endpackage

// =============================================================================
// xs_L1ErrorMetaArray_core —— 可读核（参数化读口/写口数）
// =============================================================================
module xs_L1ErrorMetaArray_core import xs_l1errmetaarray_pkg::*; #(
  parameter int READ_PORTS  = 4,
  parameter int WRITE_PORTS = 1
)(
  input  logic                clock,
  input  logic                reset,

  // 读口：给 idx，下一拍返回该 set 全部 N_WAYS 个 way 的错误位
  input  logic                io_read_valid [READ_PORTS],
  input  logic [IDX_BITS-1:0] io_read_idx   [READ_PORTS],
  output tl_error_t           io_resp       [READ_PORTS][N_WAYS],

  // 写口：way_en 为 one-hot way 选择
  input  logic                io_write_valid  [WRITE_PORTS],
  input  logic [IDX_BITS-1:0] io_write_idx    [WRITE_PORTS],
  input  logic [N_WAYS-1:0]   io_write_way_en [WRITE_PORTS],
  input  tl_error_t           io_write_error  [WRITE_PORTS]
);

  // =========================================================================
  // 架构状态：寄存器堆 N_SETS × N_WAYS 个 TLError 条目
  // =========================================================================
  tl_error_t meta_array [N_SETS][N_WAYS];

  // =========================================================================
  // 写路径：S0 按 way_en 拆请求 -> S1 打一拍 -> 落寄存器堆
  // 下标顺序 [way][wport] 与 Chisel 的 s0_way_wen(way)(wport) 一致
  // =========================================================================
  logic                s0_way_wen   [N_WAYS][WRITE_PORTS];
  logic [IDX_BITS-1:0] s0_way_waddr [N_WAYS][WRITE_PORTS];
  tl_error_t           s0_way_wdata [N_WAYS][WRITE_PORTS];
  logic                s1_way_wen   [N_WAYS][WRITE_PORTS];
  logic [IDX_BITS-1:0] s1_way_waddr [N_WAYS][WRITE_PORTS];
  tl_error_t           s1_way_wdata [N_WAYS][WRITE_PORTS];

  // S0：纯组合拆分。每个 way 看自己那一位 way_en。
  always_comb begin
    for (int wp = 0; wp < WRITE_PORTS; wp++) begin
      for (int w = 0; w < N_WAYS; w++) begin
        s0_way_wen  [w][wp] = io_write_valid[wp] & io_write_way_en[wp][w];
        s0_way_waddr[w][wp] = io_write_idx[wp];
        s0_way_wdata[w][wp] = io_write_error[wp];
      end
    end
  end

  // S1 在途写寄存：wen 用 RegNext（每拍都更新），waddr/wdata 用 RegEnable(s0_wen)
  // 省功耗。这一组寄存器 golden 侧**无复位**（上电 X），照搬不加复位。
  always_ff @(posedge clock) begin
    for (int wp = 0; wp < WRITE_PORTS; wp++) begin
      for (int w = 0; w < N_WAYS; w++) begin
        s1_way_wen[w][wp] <= s0_way_wen[w][wp];
        if (s0_way_wen[w][wp]) begin
          s1_way_waddr[w][wp] <= s0_way_waddr[w][wp];
          s1_way_wdata[w][wp] <= s0_way_wdata[w][wp];
        end
      end
    end
  end

  // 寄存器堆落盘：**异步复位**清 0（golden 是 always @(posedge clock or posedge
  // reset)，对应 DFF 的异步清零引脚，FM 按此比对，必须保持异步语义）。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int s = 0; s < N_SETS; s++)
        for (int w = 0; w < N_WAYS; w++)
          meta_array[s][w] <= '0;
    end
    else begin
      for (int wp = 0; wp < WRITE_PORTS; wp++)
        for (int w = 0; w < N_WAYS; w++)
          if (s1_way_wen[w][wp])
            meta_array[s1_way_waddr[w][wp]][w] <= s1_way_wdata[w][wp];
    end
  end

  // =========================================================================
  // 读路径：每个 (读口, way) 一份在途写转发判定 + S0->S1 锁存 + 输出 mux
  // =========================================================================
  genvar gp, gw;
  generate
    for (gp = 0; gp < READ_PORTS; gp++) begin : g_rport
      for (gw = 0; gw < N_WAYS; gw++) begin : g_way

        // --- S0 组合：本读口本 way 是否命中在途写，命中则给出转发数据 ---
        logic      rd_bypass_sel;
        tl_error_t rd_bypass_data;
        always_comb begin
          rd_bypass_sel  = 1'b0;
          rd_bypass_data = '0;   // 对齐 Chisel 的 DontCare：sel=0 时既不锁存也不选中
          for (int wp = 0; wp < WRITE_PORTS; wp++) begin
            // 复刻 Chisel 的两条 when：先 S1 后 S0，故 S0 命中时覆盖 S1 的数据
            if (s1_way_wen[gw][wp] & (s1_way_waddr[gw][wp] == io_read_idx[gp])) begin
              rd_bypass_sel  = 1'b1;
              rd_bypass_data = s1_way_wdata[gw][wp];
            end
            if (s0_way_wen[gw][wp] & (s0_way_waddr[gw][wp] == io_read_idx[gp])) begin
              rd_bypass_sel  = 1'b1;
              rd_bypass_data = s0_way_wdata[gw][wp];
            end
          end
        end

        // --- S0 -> S1 锁存：三个寄存器，使能各不相同（见文件头时序说明）---
        logic                sel_r;       // RegEnable(sel,        read.valid)
        tl_error_t           bypass_r;    // RegEnable(bypass_data, sel)  ← 使能是 sel
        logic [IDX_BITS-1:0] read_idx_r;  // RegEnable(idx,        read.valid)
        always_ff @(posedge clock) begin
          if (io_read_valid[gp]) begin
            sel_r      <= rd_bypass_sel;
            read_idx_r <= io_read_idx[gp];
          end
          if (rd_bypass_sel)
            bypass_r <= rd_bypass_data;
        end

        // --- S1 输出：命中在途写取转发值，否则用锁存的地址组合读寄存器堆 ---
        assign io_resp[gp][gw] = sel_r ? bypass_r : meta_array[read_idx_r][gw];

      end
    end
  endgenerate

endmodule

// =============================================================================
// golden 同名 wrapper —— 端口与 golden L1ErrorMetaArray 逐位同名同序，
// 把扁平端口打成核的数组端口。
// =============================================================================
module L1ErrorMetaArray import xs_l1errmetaarray_pkg::*; (
  input        clock,
  input        reset,
  input        io_read_0_valid,
  input  [7:0] io_read_0_bits_idx,
  input        io_read_1_valid,
  input  [7:0] io_read_1_bits_idx,
  input        io_read_2_valid,
  input  [7:0] io_read_2_bits_idx,
  input        io_read_3_valid,
  input  [7:0] io_read_3_bits_idx,
  output       io_resp_0_0_tl_denied,
  output       io_resp_0_0_tl_corrupt,
  output       io_resp_0_1_tl_denied,
  output       io_resp_0_1_tl_corrupt,
  output       io_resp_0_2_tl_denied,
  output       io_resp_0_2_tl_corrupt,
  output       io_resp_0_3_tl_denied,
  output       io_resp_0_3_tl_corrupt,
  output       io_resp_1_0_tl_denied,
  output       io_resp_1_0_tl_corrupt,
  output       io_resp_1_1_tl_denied,
  output       io_resp_1_1_tl_corrupt,
  output       io_resp_1_2_tl_denied,
  output       io_resp_1_2_tl_corrupt,
  output       io_resp_1_3_tl_denied,
  output       io_resp_1_3_tl_corrupt,
  output       io_resp_2_0_tl_denied,
  output       io_resp_2_0_tl_corrupt,
  output       io_resp_2_1_tl_denied,
  output       io_resp_2_1_tl_corrupt,
  output       io_resp_2_2_tl_denied,
  output       io_resp_2_2_tl_corrupt,
  output       io_resp_2_3_tl_denied,
  output       io_resp_2_3_tl_corrupt,
  output       io_resp_3_0_tl_denied,
  output       io_resp_3_0_tl_corrupt,
  output       io_resp_3_1_tl_denied,
  output       io_resp_3_1_tl_corrupt,
  output       io_resp_3_2_tl_denied,
  output       io_resp_3_2_tl_corrupt,
  output       io_resp_3_3_tl_denied,
  output       io_resp_3_3_tl_corrupt,
  input        io_write_0_valid,
  input  [7:0] io_write_0_bits_idx,
  input  [3:0] io_write_0_bits_way_en,
  input        io_write_0_bits_error_tl_denied,
  input        io_write_0_bits_error_tl_corrupt
);
  logic                rvalid [4];
  logic [7:0]          ridx   [4];
  tl_error_t           resp   [4][4];
  logic                wvalid [1];
  logic [7:0]          widx   [1];
  logic [3:0]          wen    [1];
  tl_error_t           wdata  [1];

  always_comb begin
    rvalid[0] = io_read_0_valid;
    ridx[0]   = io_read_0_bits_idx;
    rvalid[1] = io_read_1_valid;
    ridx[1]   = io_read_1_bits_idx;
    rvalid[2] = io_read_2_valid;
    ridx[2]   = io_read_2_bits_idx;
    rvalid[3] = io_read_3_valid;
    ridx[3]   = io_read_3_bits_idx;
    wvalid[0] = io_write_0_valid;
    widx[0]   = io_write_0_bits_idx;
    wen[0]    = io_write_0_bits_way_en;
    wdata[0].tl_denied  = io_write_0_bits_error_tl_denied;
    wdata[0].tl_corrupt = io_write_0_bits_error_tl_corrupt;
  end

  xs_L1ErrorMetaArray_core #(.READ_PORTS(4), .WRITE_PORTS(1)) u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(rvalid), .io_read_idx(ridx), .io_resp(resp),
    .io_write_valid(wvalid), .io_write_idx(widx),
    .io_write_way_en(wen), .io_write_error(wdata)
  );

  assign io_resp_0_0_tl_denied  = resp[0][0].tl_denied;
  assign io_resp_0_0_tl_corrupt = resp[0][0].tl_corrupt;
  assign io_resp_0_1_tl_denied  = resp[0][1].tl_denied;
  assign io_resp_0_1_tl_corrupt = resp[0][1].tl_corrupt;
  assign io_resp_0_2_tl_denied  = resp[0][2].tl_denied;
  assign io_resp_0_2_tl_corrupt = resp[0][2].tl_corrupt;
  assign io_resp_0_3_tl_denied  = resp[0][3].tl_denied;
  assign io_resp_0_3_tl_corrupt = resp[0][3].tl_corrupt;
  assign io_resp_1_0_tl_denied  = resp[1][0].tl_denied;
  assign io_resp_1_0_tl_corrupt = resp[1][0].tl_corrupt;
  assign io_resp_1_1_tl_denied  = resp[1][1].tl_denied;
  assign io_resp_1_1_tl_corrupt = resp[1][1].tl_corrupt;
  assign io_resp_1_2_tl_denied  = resp[1][2].tl_denied;
  assign io_resp_1_2_tl_corrupt = resp[1][2].tl_corrupt;
  assign io_resp_1_3_tl_denied  = resp[1][3].tl_denied;
  assign io_resp_1_3_tl_corrupt = resp[1][3].tl_corrupt;
  assign io_resp_2_0_tl_denied  = resp[2][0].tl_denied;
  assign io_resp_2_0_tl_corrupt = resp[2][0].tl_corrupt;
  assign io_resp_2_1_tl_denied  = resp[2][1].tl_denied;
  assign io_resp_2_1_tl_corrupt = resp[2][1].tl_corrupt;
  assign io_resp_2_2_tl_denied  = resp[2][2].tl_denied;
  assign io_resp_2_2_tl_corrupt = resp[2][2].tl_corrupt;
  assign io_resp_2_3_tl_denied  = resp[2][3].tl_denied;
  assign io_resp_2_3_tl_corrupt = resp[2][3].tl_corrupt;
  assign io_resp_3_0_tl_denied  = resp[3][0].tl_denied;
  assign io_resp_3_0_tl_corrupt = resp[3][0].tl_corrupt;
  assign io_resp_3_1_tl_denied  = resp[3][1].tl_denied;
  assign io_resp_3_1_tl_corrupt = resp[3][1].tl_corrupt;
  assign io_resp_3_2_tl_denied  = resp[3][2].tl_denied;
  assign io_resp_3_2_tl_corrupt = resp[3][2].tl_corrupt;
  assign io_resp_3_3_tl_denied  = resp[3][3].tl_denied;
  assign io_resp_3_3_tl_corrupt = resp[3][3].tl_corrupt;
endmodule
