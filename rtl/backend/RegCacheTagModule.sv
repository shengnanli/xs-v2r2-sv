// =============================================================================
// RegCacheTagModule —— 寄存器缓存(RegCache)的 tag 表半区
//
// 对应 Chisel: xiangshan.backend.regcache.RegCacheTagModule
// 位置：Backend / NewDispatch 之下，RegCacheTagTable 里例化两份（Int 半区一份、
//       Mem 半区一份）。RegCache 本体（rtl/backend/RegCache.sv）存的是**数据**，
//       本模块存的是「哪个物理寄存器号(pdest)现在住在 RegCache 的哪一条目里」，
//       供 Dispatch 阶段判断源操作数能不能走 RegCache 而不占 PRF 读口。
//
// 三件事：
//   查(read)  ：12 个读口，各拿一个 pdest 当 tag 全相联比对；命中给出条目下标。
//               比对是 one-hot，下标由 OHToUInt（按位 OR 归约）编出来 —— 多条命中
//               时得到的是各下标的按位或，golden 靠一条 assert 保证不会发生。
//   写(write) ：唤醒总线把「pdest→RegCache 条目」映射写进来。同一拍多个写口写到
//               同一条目时 golden 是**按位 OR**（不是优先级），同样由 assert 兜底。
//   老化/作废 ：每条目带一份 loadDependency（3 组 × 2 位，表示"依赖第 k 个 load、
//               还剩几拍出结果"）。没被写、没被作废、且还有非零依赖时，每拍左移
//               一位（{dep[0],1'b0}）当作倒计时；上层用 dep[1] 配 ldCancel 决定
//               要不要把整条作废。cancel 拍只清 v，不动 dep（golden 如此）。
//
// 复位域（★逐项照抄 golden，别整齐划一★）：
//   v[*]            ：always @(posedge clock or posedge reset)，**异步复位**清 0；
//   tag[*] / dep[*] ：**完全不复位**，只在被写/老化时更新。上电是 X，靠 v=0 屏蔽。
//
// 本文件 = 参数化可读核 + golden 同名 wrapper（Int 半区：16 条目 / 4 写口）。
// 家族另一个单态化变体在 rtl/backend/RegCacheTagModule_1.sv（Mem 半区：12 条目 /
// 3 写口，且写口 w 的第 w 组依赖被 firtool 折成常数 —— 详见该文件）。
//
// golden 里还有一段 `ifndef SYNTHESIS` 的 assert（读口命中数 ≤1、写口不撞条目）。
// 本核不复刻：UT 两侧都带 +define+SYNTHESIS 编译，那段在 golden 侧也不存在；
// 复刻它只会在随机激励下单边报警，反而遮住真失配。
// =============================================================================

module xs_RegCacheTagModule_core #(
  parameter  int unsigned NUM_ENTRIES = 16,  // 本半区条目数（Int 16 / Mem 12）
  parameter  int unsigned NUM_WRITE   = 4,   // 写口数（Int 4 / Mem 3）
  parameter  int unsigned NUM_READ    = 12,  // 读口数（两个变体都是 12）
  parameter  int unsigned TAG_WIDTH   = 8,   // tag = pdest 位宽
  parameter  int unsigned NUM_LDEP    = 3,   // loadDependency 组数 = load unit 数
  parameter  int unsigned LDEP_WIDTH  = 2,   // 每组位宽 = load 唤醒到可取消的拍数
  // ★地址位宽在两个变体里**都是 4**★：Mem 半区只有 12 条目，但 golden 的
  // io_readPorts_*_addr / io_writePorts_*_addr 仍是 [3:0]（RegCacheIdx 的低 4 位
  // 是按 Int 半区定宽的）。按 $clog2(12)=4 算恰好也是 4，这里显式写死免得误会。
  parameter  int unsigned ADDR_WIDTH  = 4,
  // ★Mem 半区专用★：Mem 侧第 w 个写口就是第 w 个 load 流水自己，它写进条目的
  // "对第 w 个 load 的依赖"恒为「刚发射」= 2'h1，不取 io_write_loadDependency[w][w]。
  // golden 里这体现为 RegCacheTagModule_1 **没有** io_writePorts_w_loadDependency_w
  // 这个输入端口（firtool 把它折成常数，写作 `{1'h0, wenOH}`）。规则放在核里，
  // 使用者（RegCacheTagModule_1 的 wrapper 与 RegCacheTagTable 的 Mem 实例）
  // 只要置位这个参数，不必各自复制一遍常数。
  parameter  bit          SELF_DEP_DIAG = 1'b0
)(
  input  logic clock,
  input  logic reset,                                   // 异步复位，只作用于 v

  // ---- 读口：ren 只门控 valid，不门控比对 ----
  input  logic [NUM_READ-1:0]                              io_read_ren,
  input  logic [NUM_READ-1:0][TAG_WIDTH-1:0]               io_read_tag,
  output logic [NUM_READ-1:0]                              io_read_valid,
  output logic [NUM_READ-1:0][ADDR_WIDTH-1:0]              io_read_addr,

  // ---- 写口：addr 由上层的替换逻辑给出（rcDest），不是本模块选的 ----
  input  logic [NUM_WRITE-1:0]                             io_write_wen,
  input  logic [NUM_WRITE-1:0][ADDR_WIDTH-1:0]             io_write_addr,
  input  logic [NUM_WRITE-1:0][TAG_WIDTH-1:0]              io_write_tag,
  input  logic [NUM_WRITE-1:0][NUM_LDEP-1:0][LDEP_WIDTH-1:0] io_write_loadDependency,

  // ---- 作废 / 全表快照（作废条件由上层 RegCacheTagTable 用快照算出来）----
  input  logic [NUM_ENTRIES-1:0]                           io_cancelVec,
  output logic [NUM_ENTRIES-1:0]                           io_validVec,
  output logic [NUM_ENTRIES-1:0][TAG_WIDTH-1:0]            io_tagVec,
  output logic [NUM_ENTRIES-1:0][NUM_LDEP-1:0][LDEP_WIDTH-1:0] io_loadDependencyVec
);

  // ---------------------------------------------------------------------------
  // 状态
  // ---------------------------------------------------------------------------
  logic [NUM_ENTRIES-1:0]                                    v;
  logic [NUM_ENTRIES-1:0][TAG_WIDTH-1:0]                     tag;
  logic [NUM_ENTRIES-1:0][NUM_LDEP-1:0][LDEP_WIDTH-1:0]      loadDependency;

  // ---------------------------------------------------------------------------
  // 写译码：wenOH[e][w] = 写口 w 这一拍要写条目 e
  // ---------------------------------------------------------------------------
  logic [NUM_ENTRIES-1:0][NUM_WRITE-1:0] wenOH;
  logic [NUM_ENTRIES-1:0]                wrHit;   // 该条目本拍被至少一个写口写

  always_comb begin
    for (int e = 0; e < int'(NUM_ENTRIES); e++) begin
      for (int w = 0; w < int'(NUM_WRITE); w++)
        wenOH[e][w] = io_write_wen[w] & (io_write_addr[w] == ADDR_WIDTH'(e));
      wrHit[e] = |wenOH[e];
    end
  end

  // 写数据合成：golden 是 OR 归约而不是优先级选择。撞写由 golden 的 assert 排除，
  // 真撞上时两边都得到"按位或"——这里必须照抄，改成优先级会在撞写拍失配。
  logic [NUM_ENTRIES-1:0][TAG_WIDTH-1:0]                wrTag;
  logic [NUM_ENTRIES-1:0][NUM_LDEP-1:0][LDEP_WIDTH-1:0] wrLdep;

  always_comb begin
    wrTag  = '0;
    wrLdep = '0;
    for (int e = 0; e < int'(NUM_ENTRIES); e++)
      for (int w = 0; w < int'(NUM_WRITE); w++)
        if (wenOH[e][w]) begin
          wrTag[e] |= io_write_tag[w];
          for (int d = 0; d < int'(NUM_LDEP); d++)
            wrLdep[e][d] |= (SELF_DEP_DIAG && d == w) ? LDEP_WIDTH'(1)
                                                      : io_write_loadDependency[w][d];
        end
  end

  // ---------------------------------------------------------------------------
  // 有效位：唯一带复位的状态，且**写优先于作废**（同拍写+作废 → 保持有效）
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      v <= '0;
    else
      for (int e = 0; e < int'(NUM_ENTRIES); e++)
        v[e] <= wrHit[e] | (~io_cancelVec[e] & v[e]);
  end

  // ---------------------------------------------------------------------------
  // tag / loadDependency：**无复位**。三种拍互斥，优先级照 golden 的 if/else 链：
  //   1) 被写        → 整条换成新 tag + 新依赖；
  //   2) 被作废，或依赖已全零 → 保持不动（作废只体现在 v 上，dep 不清）；
  //   3) 其余        → 依赖各组左移一位，相当于"离出结果又近了一拍"。
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    for (int e = 0; e < int'(NUM_ENTRIES); e++) begin
      if (wrHit[e]) begin
        tag[e]            <= wrTag[e];
        loadDependency[e] <= wrLdep[e];
      end
      else if (!io_cancelVec[e] && (|loadDependency[e])) begin
        for (int d = 0; d < int'(NUM_LDEP); d++)
          loadDependency[e][d] <= {loadDependency[e][d][LDEP_WIDTH-2:0], 1'b0};
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 读口：全相联 tag 比对 + one-hot 转二进制
  // ---------------------------------------------------------------------------
  logic [NUM_READ-1:0][NUM_ENTRIES-1:0] matchOH;

  always_comb begin
    for (int r = 0; r < int'(NUM_READ); r++)
      for (int e = 0; e < int'(NUM_ENTRIES); e++)
        matchOH[r][e] = v[e] & (tag[e] == io_read_tag[r]);
  end

  always_comb begin
    for (int r = 0; r < int'(NUM_READ); r++) begin
      io_read_valid[r] = io_read_ren[r] & (|matchOH[r]);
      // OHToUInt：第 b 位 = 所有"下标第 b 位为 1"的命中位的或。非 one-hot 输入时
      // 得到各下标的按位或 —— 与 golden 的展开式同义。
      for (int b = 0; b < int'(ADDR_WIDTH); b++) begin
        io_read_addr[r][b] = 1'b0;
        for (int e = 0; e < int'(NUM_ENTRIES); e++)
          if (e[b]) io_read_addr[r][b] = io_read_addr[r][b] | matchOH[r][e];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 全表快照直出：上层要拿它算 cancelVec（见 RegCacheTagTable）
  // ---------------------------------------------------------------------------
  assign io_validVec          = v;
  assign io_tagVec            = tag;
  assign io_loadDependencyVec = loadDependency;

endmodule

// BEGIN GENERATED(wrapper)
module RegCacheTagModule(
  input        clock,
  input        reset,
  input        io_readPorts_0_ren,
  input  [7:0] io_readPorts_0_tag,
  output       io_readPorts_0_valid,
  output [3:0] io_readPorts_0_addr,
  input        io_readPorts_1_ren,
  input  [7:0] io_readPorts_1_tag,
  output       io_readPorts_1_valid,
  output [3:0] io_readPorts_1_addr,
  input        io_readPorts_2_ren,
  input  [7:0] io_readPorts_2_tag,
  output       io_readPorts_2_valid,
  output [3:0] io_readPorts_2_addr,
  input        io_readPorts_3_ren,
  input  [7:0] io_readPorts_3_tag,
  output       io_readPorts_3_valid,
  output [3:0] io_readPorts_3_addr,
  input        io_readPorts_4_ren,
  input  [7:0] io_readPorts_4_tag,
  output       io_readPorts_4_valid,
  output [3:0] io_readPorts_4_addr,
  input        io_readPorts_5_ren,
  input  [7:0] io_readPorts_5_tag,
  output       io_readPorts_5_valid,
  output [3:0] io_readPorts_5_addr,
  input        io_readPorts_6_ren,
  input  [7:0] io_readPorts_6_tag,
  output       io_readPorts_6_valid,
  output [3:0] io_readPorts_6_addr,
  input        io_readPorts_7_ren,
  input  [7:0] io_readPorts_7_tag,
  output       io_readPorts_7_valid,
  output [3:0] io_readPorts_7_addr,
  input        io_readPorts_8_ren,
  input  [7:0] io_readPorts_8_tag,
  output       io_readPorts_8_valid,
  output [3:0] io_readPorts_8_addr,
  input        io_readPorts_9_ren,
  input  [7:0] io_readPorts_9_tag,
  output       io_readPorts_9_valid,
  output [3:0] io_readPorts_9_addr,
  input        io_readPorts_10_ren,
  input  [7:0] io_readPorts_10_tag,
  output       io_readPorts_10_valid,
  output [3:0] io_readPorts_10_addr,
  input        io_readPorts_11_ren,
  input  [7:0] io_readPorts_11_tag,
  output       io_readPorts_11_valid,
  output [3:0] io_readPorts_11_addr,
  input        io_writePorts_0_wen,
  input  [3:0] io_writePorts_0_addr,
  input  [7:0] io_writePorts_0_tag,
  input  [1:0] io_writePorts_0_loadDependency_0,
  input  [1:0] io_writePorts_0_loadDependency_1,
  input  [1:0] io_writePorts_0_loadDependency_2,
  input        io_writePorts_1_wen,
  input  [3:0] io_writePorts_1_addr,
  input  [7:0] io_writePorts_1_tag,
  input  [1:0] io_writePorts_1_loadDependency_0,
  input  [1:0] io_writePorts_1_loadDependency_1,
  input  [1:0] io_writePorts_1_loadDependency_2,
  input        io_writePorts_2_wen,
  input  [3:0] io_writePorts_2_addr,
  input  [7:0] io_writePorts_2_tag,
  input  [1:0] io_writePorts_2_loadDependency_0,
  input  [1:0] io_writePorts_2_loadDependency_1,
  input  [1:0] io_writePorts_2_loadDependency_2,
  input        io_writePorts_3_wen,
  input  [3:0] io_writePorts_3_addr,
  input  [7:0] io_writePorts_3_tag,
  input  [1:0] io_writePorts_3_loadDependency_0,
  input  [1:0] io_writePorts_3_loadDependency_1,
  input  [1:0] io_writePorts_3_loadDependency_2,
  input        io_cancelVec_0,
  input        io_cancelVec_1,
  input        io_cancelVec_2,
  input        io_cancelVec_3,
  input        io_cancelVec_4,
  input        io_cancelVec_5,
  input        io_cancelVec_6,
  input        io_cancelVec_7,
  input        io_cancelVec_8,
  input        io_cancelVec_9,
  input        io_cancelVec_10,
  input        io_cancelVec_11,
  input        io_cancelVec_12,
  input        io_cancelVec_13,
  input        io_cancelVec_14,
  input        io_cancelVec_15,
  output       io_validVec_0,
  output       io_validVec_1,
  output       io_validVec_2,
  output       io_validVec_3,
  output       io_validVec_4,
  output       io_validVec_5,
  output       io_validVec_6,
  output       io_validVec_7,
  output       io_validVec_8,
  output       io_validVec_9,
  output       io_validVec_10,
  output       io_validVec_11,
  output       io_validVec_12,
  output       io_validVec_13,
  output       io_validVec_14,
  output       io_validVec_15,
  output [7:0] io_tagVec_0,
  output [7:0] io_tagVec_1,
  output [7:0] io_tagVec_2,
  output [7:0] io_tagVec_3,
  output [7:0] io_tagVec_4,
  output [7:0] io_tagVec_5,
  output [7:0] io_tagVec_6,
  output [7:0] io_tagVec_7,
  output [7:0] io_tagVec_8,
  output [7:0] io_tagVec_9,
  output [7:0] io_tagVec_10,
  output [7:0] io_tagVec_11,
  output [7:0] io_tagVec_12,
  output [7:0] io_tagVec_13,
  output [7:0] io_tagVec_14,
  output [7:0] io_tagVec_15,
  output [1:0] io_loadDependencyVec_0_0,
  output [1:0] io_loadDependencyVec_0_1,
  output [1:0] io_loadDependencyVec_0_2,
  output [1:0] io_loadDependencyVec_1_0,
  output [1:0] io_loadDependencyVec_1_1,
  output [1:0] io_loadDependencyVec_1_2,
  output [1:0] io_loadDependencyVec_2_0,
  output [1:0] io_loadDependencyVec_2_1,
  output [1:0] io_loadDependencyVec_2_2,
  output [1:0] io_loadDependencyVec_3_0,
  output [1:0] io_loadDependencyVec_3_1,
  output [1:0] io_loadDependencyVec_3_2,
  output [1:0] io_loadDependencyVec_4_0,
  output [1:0] io_loadDependencyVec_4_1,
  output [1:0] io_loadDependencyVec_4_2,
  output [1:0] io_loadDependencyVec_5_0,
  output [1:0] io_loadDependencyVec_5_1,
  output [1:0] io_loadDependencyVec_5_2,
  output [1:0] io_loadDependencyVec_6_0,
  output [1:0] io_loadDependencyVec_6_1,
  output [1:0] io_loadDependencyVec_6_2,
  output [1:0] io_loadDependencyVec_7_0,
  output [1:0] io_loadDependencyVec_7_1,
  output [1:0] io_loadDependencyVec_7_2,
  output [1:0] io_loadDependencyVec_8_0,
  output [1:0] io_loadDependencyVec_8_1,
  output [1:0] io_loadDependencyVec_8_2,
  output [1:0] io_loadDependencyVec_9_0,
  output [1:0] io_loadDependencyVec_9_1,
  output [1:0] io_loadDependencyVec_9_2,
  output [1:0] io_loadDependencyVec_10_0,
  output [1:0] io_loadDependencyVec_10_1,
  output [1:0] io_loadDependencyVec_10_2,
  output [1:0] io_loadDependencyVec_11_0,
  output [1:0] io_loadDependencyVec_11_1,
  output [1:0] io_loadDependencyVec_11_2,
  output [1:0] io_loadDependencyVec_12_0,
  output [1:0] io_loadDependencyVec_12_1,
  output [1:0] io_loadDependencyVec_12_2,
  output [1:0] io_loadDependencyVec_13_0,
  output [1:0] io_loadDependencyVec_13_1,
  output [1:0] io_loadDependencyVec_13_2,
  output [1:0] io_loadDependencyVec_14_0,
  output [1:0] io_loadDependencyVec_14_1,
  output [1:0] io_loadDependencyVec_14_2,
  output [1:0] io_loadDependencyVec_15_0,
  output [1:0] io_loadDependencyVec_15_1,
  output [1:0] io_loadDependencyVec_15_2
);

  xs_RegCacheTagModule_core #(
    .NUM_ENTRIES(16), .NUM_WRITE(4), .NUM_READ(12),
    .SELF_DEP_DIAG(1'b0)
  ) u_core (
    .clock                 (clock),
    .reset                 (reset),
    .io_read_ren ({
      io_readPorts_11_ren, io_readPorts_10_ren, io_readPorts_9_ren, io_readPorts_8_ren,
      io_readPorts_7_ren, io_readPorts_6_ren, io_readPorts_5_ren, io_readPorts_4_ren,
      io_readPorts_3_ren, io_readPorts_2_ren, io_readPorts_1_ren, io_readPorts_0_ren
    }),
    .io_read_tag ({
      io_readPorts_11_tag, io_readPorts_10_tag, io_readPorts_9_tag, io_readPorts_8_tag,
      io_readPorts_7_tag, io_readPorts_6_tag, io_readPorts_5_tag, io_readPorts_4_tag,
      io_readPorts_3_tag, io_readPorts_2_tag, io_readPorts_1_tag, io_readPorts_0_tag
    }),
    .io_read_valid ({
      io_readPorts_11_valid, io_readPorts_10_valid, io_readPorts_9_valid, io_readPorts_8_valid,
      io_readPorts_7_valid, io_readPorts_6_valid, io_readPorts_5_valid, io_readPorts_4_valid,
      io_readPorts_3_valid, io_readPorts_2_valid, io_readPorts_1_valid, io_readPorts_0_valid
    }),
    .io_read_addr ({
      io_readPorts_11_addr, io_readPorts_10_addr, io_readPorts_9_addr, io_readPorts_8_addr,
      io_readPorts_7_addr, io_readPorts_6_addr, io_readPorts_5_addr, io_readPorts_4_addr,
      io_readPorts_3_addr, io_readPorts_2_addr, io_readPorts_1_addr, io_readPorts_0_addr
    }),
    .io_write_wen ({
      io_writePorts_3_wen, io_writePorts_2_wen, io_writePorts_1_wen, io_writePorts_0_wen
    }),
    .io_write_addr ({
      io_writePorts_3_addr, io_writePorts_2_addr, io_writePorts_1_addr, io_writePorts_0_addr
    }),
    .io_write_tag ({
      io_writePorts_3_tag, io_writePorts_2_tag, io_writePorts_1_tag, io_writePorts_0_tag
    }),
    .io_write_loadDependency ({
      {io_writePorts_3_loadDependency_2, io_writePorts_3_loadDependency_1,
      io_writePorts_3_loadDependency_0}, {io_writePorts_2_loadDependency_2,
      io_writePorts_2_loadDependency_1, io_writePorts_2_loadDependency_0},
      {io_writePorts_1_loadDependency_2, io_writePorts_1_loadDependency_1,
      io_writePorts_1_loadDependency_0}, {io_writePorts_0_loadDependency_2,
      io_writePorts_0_loadDependency_1, io_writePorts_0_loadDependency_0}
    }),
    .io_cancelVec ({
      io_cancelVec_15, io_cancelVec_14, io_cancelVec_13, io_cancelVec_12, io_cancelVec_11,
      io_cancelVec_10, io_cancelVec_9, io_cancelVec_8, io_cancelVec_7, io_cancelVec_6,
      io_cancelVec_5, io_cancelVec_4, io_cancelVec_3, io_cancelVec_2, io_cancelVec_1,
      io_cancelVec_0
    }),
    .io_validVec ({
      io_validVec_15, io_validVec_14, io_validVec_13, io_validVec_12, io_validVec_11,
      io_validVec_10, io_validVec_9, io_validVec_8, io_validVec_7, io_validVec_6, io_validVec_5,
      io_validVec_4, io_validVec_3, io_validVec_2, io_validVec_1, io_validVec_0
    }),
    .io_tagVec ({
      io_tagVec_15, io_tagVec_14, io_tagVec_13, io_tagVec_12, io_tagVec_11, io_tagVec_10,
      io_tagVec_9, io_tagVec_8, io_tagVec_7, io_tagVec_6, io_tagVec_5, io_tagVec_4, io_tagVec_3,
      io_tagVec_2, io_tagVec_1, io_tagVec_0
    }),
    .io_loadDependencyVec ({
      {io_loadDependencyVec_15_2, io_loadDependencyVec_15_1, io_loadDependencyVec_15_0},
      {io_loadDependencyVec_14_2, io_loadDependencyVec_14_1, io_loadDependencyVec_14_0},
      {io_loadDependencyVec_13_2, io_loadDependencyVec_13_1, io_loadDependencyVec_13_0},
      {io_loadDependencyVec_12_2, io_loadDependencyVec_12_1, io_loadDependencyVec_12_0},
      {io_loadDependencyVec_11_2, io_loadDependencyVec_11_1, io_loadDependencyVec_11_0},
      {io_loadDependencyVec_10_2, io_loadDependencyVec_10_1, io_loadDependencyVec_10_0},
      {io_loadDependencyVec_9_2, io_loadDependencyVec_9_1, io_loadDependencyVec_9_0},
      {io_loadDependencyVec_8_2, io_loadDependencyVec_8_1, io_loadDependencyVec_8_0},
      {io_loadDependencyVec_7_2, io_loadDependencyVec_7_1, io_loadDependencyVec_7_0},
      {io_loadDependencyVec_6_2, io_loadDependencyVec_6_1, io_loadDependencyVec_6_0},
      {io_loadDependencyVec_5_2, io_loadDependencyVec_5_1, io_loadDependencyVec_5_0},
      {io_loadDependencyVec_4_2, io_loadDependencyVec_4_1, io_loadDependencyVec_4_0},
      {io_loadDependencyVec_3_2, io_loadDependencyVec_3_1, io_loadDependencyVec_3_0},
      {io_loadDependencyVec_2_2, io_loadDependencyVec_2_1, io_loadDependencyVec_2_0},
      {io_loadDependencyVec_1_2, io_loadDependencyVec_1_1, io_loadDependencyVec_1_0},
      {io_loadDependencyVec_0_2, io_loadDependencyVec_0_1, io_loadDependencyVec_0_0}
    })
  );

endmodule
// END GENERATED
