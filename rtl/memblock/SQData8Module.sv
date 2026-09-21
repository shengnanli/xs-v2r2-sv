// =============================================================================
// SQData8Module.sv —— StoreQueue 数据阵列的「一个字节切片」
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/mem/lsqueue/StoreQueueData.scala
//        class SQData8Module(numEntries, numRead, numWrite, numForward)
// golden 对照:G1 golden-rtl/SQData8Module.sv(3529 行 / 32 端口 / 546 寄存器)
//
// 【它是干什么的】
// StoreQueue 的 store 数据按**字节**切成 16 片,每片一个本模块实例(父模块
// SQDataModule 例化 16 个)。每片存 56 条 store 在这一个字节位置上的
// { valid(这字节有效), data[8] }。
//
// 三条通路:
//   写:两级流水(S0 译 bank → S1 写阵列),数据与 valid 各有独立的两个写口
//   读:同步读(读地址打一拍),2 个读口
//   前递:3 个口。上层 SQAddrModule 先算出"哪些条目地址命中",按 needForward
//         送进来;本模块在这些候选里挑**下标最大**(最年轻)的那条,把它这一字节
//         的数据送出去。这就是 store-to-load forwarding 的数据选择级。
//
// 【★ 写路径是分 bank 的两拍流水,不是直写 ★】
// 56 条目 = 8 个 bank × 7 行。写地址低 3 位选 bank,高 3 位当行号:
//   S0(组合):按写地址低 3 位译出 8 位 one-hot bank 使能 s0_wenVec
//   S1(寄存):s1_wenVec = bank 使能打一拍;s1_wdata/s1_waddr = 用 s0 使能做 RegEnable
//   写阵列:  条目 e(bank=e%8, row=e/8)在 s1_wen[bank] 且 s1_waddr[bank]==row 时更新
// 这样每拍只有命中的那个 bank 的 7 个条目需要译码,省掉 56 路全比较的功耗。
// ★ 后果:写数据要 2 拍才可见,同拍读写同址读到的是旧值。★
//
// 【★ 复位域:32 个异步复位 + 514 个完全不复位,零交集 ★】
//   异步复位(32):s1_wenVec —— 4 组(数据口0/1、掩码口0/1)× 8 bank
//                 只有它必须复位:它是"S1 要不要写"的控制位,上电乱值会污染阵列。
//   不复位(514):阵列 data/valid(112)、s1_wdata/s1_waddr(64)、
//                 读地址寄存器(2)、needCheckReg(336)
//   把这 514 个写成复位是真 bug:elaborate / lint 都不报,只有 FM 抓得到。
//
// 【★ 与 Chisel 冲突的两处,一律以 golden 为准 ★】
//
//  1) ★读地址寄存器:Chisel 写 GatedRegNext,golden 是**朴素 RegNext**★
//     StoreQueueData.scala:205 写的是 `data(GatedRegNext(io.raddr(i)))`,与同文件
//     line 61(SQAddrModule)一模一样。但两份 golden 的渲染结果不同:
//         SQAddrModule.sv   : io_rdata_0_next_r,带门控 `if(~(a==r))`,**异步复位到 0**
//         SQData8Module.sv  : io_rdata_0_REG,  **无门控、无复位**
//                             (golden L2049: `io_rdata_0_REG <= io_raddr_0;`)
//     `_next_r` 是 GatedRegNext 的命名,`_REG` 是朴素 RegNext 的命名 —— 说明生成
//     G1 的那份 Scala 在本模块用的是 RegNext。本核按 **golden** 实现:无门控、无复位。
//
//  2) ★越界读落到条目 0,不是落到 0★
//     raddr 6 bit(64 种编码)而条目只有 56 个。golden 把 Vec 读展成 64 深 mux,
//     56..63 这 8 个槽填的是 **data[0]**(golden L363-370 / L428-435),不是常数 0。
//     按"没查到就是 0"写是真 bug。见 §2.6。
//
// 【★ DCE 掉的端口:forwardValidFast 不存在,不要生成 ★】
//   Chisel 的 io.forwardValidFast(当拍组合出的命中位)在 golden 端口表里没有
//   (父模块不接)。如果照 Chisel 生成它,就多出一堆没人读的逻辑 → FM 判 unread
//   → PARTIAL。本核只做 forwardValid(打一拍的)与 forwardData。
//
// 【更新优先级】同一条目同拍被两个写口写:**写口 1 胜过写口 0**(数据、掩码各自独立)。
//   golden 形状 if(口1) / else if(口0)。模块带断言禁止同址双写(§2.8),所以这条
//   优先级在合法激励下不可观测 —— 但 FM 要逐位证,必须与 golden 一致。
// =============================================================================

// -----------------------------------------------------------------------------
// §1 尺寸常量(全部从 G1 golden 机械量得)
// -----------------------------------------------------------------------------
package sq_data8_module_pkg;

  localparam int NUM_ENTRIES = 56;  // StoreQueueSize
  localparam int ADDR_W      = 6;   // log2Up(56) —— 2**6=64 > 56,见 §2.6
  localparam int NUM_READ    = 2;
  localparam int NUM_WRITE   = 2;
  localparam int NUM_FWD     = 3;
  localparam int DATA_W      = 8;   // XLEN/8 —— 本模块只管一个字节

  // 写路径分 bank(StoreQueueNWriteBanks)。条目 e 落在 bank = e % N_BANKS,
  // 行号 row = e / N_BANKS。golden 用写地址的低 3 位选 bank、高 3 位当行号。
  localparam int N_BANKS = 8;
  localparam int BANK_W  = 3;                          // log2(N_BANKS)
  localparam int N_ROWS  = NUM_ENTRIES / N_BANKS;      // 7
  localparam int ROW_W   = ADDR_W - BANK_W;            // 3(golden 的 waddr[5:3])

  // 前递归约的叶子数:两个"需要检查"位向量(needForward 的 0/1 两半)各覆盖 56 条目。
  // 半 0 = 与 deqPtr 同 flag 的区间,半 1 = 跨环绕的区间,详见 §2.7。
  localparam int NUM_FWD_LEAVES = 2 * NUM_ENTRIES;     // 112

  typedef struct packed {
    logic              valid;  // 这一字节是否被这条 store 写过
    logic [DATA_W-1:0] data;
  } entry_t;

endpackage

// -----------------------------------------------------------------------------
// §2 xs_SQData8Module_core —— 可读核
// -----------------------------------------------------------------------------
module xs_SQData8Module_core
  import sq_data8_module_pkg::*;
(
  input  logic                   clock,
  input  logic                   reset,

  // 同步读口
  input  logic [ADDR_W-1:0]      raddr [NUM_READ],
  output entry_t                 rdata [NUM_READ],

  // 数据写口(写 entry.data)
  input  logic                   data_wen   [NUM_WRITE],
  input  logic [ADDR_W-1:0]      data_waddr [NUM_WRITE],
  input  logic [DATA_W-1:0]      data_wdata [NUM_WRITE],

  // 掩码写口(写 entry.valid)—— 与数据写口**完全独立**:地址、使能都各走各的,
  // 上层可以先落 valid 再落 data,或反过来。
  input  logic                   mask_wen   [NUM_WRITE],
  input  logic [ADDR_W-1:0]      mask_waddr [NUM_WRITE],
  input  logic                   mask_wdata [NUM_WRITE],

  // 前递:needForward[i][h] 是 56 位候选掩码,h=0/1 两半见 §2.7
  input  logic [NUM_ENTRIES-1:0] needForward  [NUM_FWD][2],
  output logic                   forwardValid [NUM_FWD],
  output logic [DATA_W-1:0]      forwardData  [NUM_FWD]
);

  // ---------------------------------------------------------------------------
  // §2.1 阵列状态(★不复位★)
  // ---------------------------------------------------------------------------
  entry_t entries [NUM_ENTRIES];

  // 条目 ↔ (bank,row) 的对应。golden 里是 56 段展开的常数比较,这里用函数表达。
  function automatic int unsigned bank_of(input int unsigned e); bank_of = e % N_BANKS; endfunction
  function automatic int unsigned row_of (input int unsigned e); row_of  = e / N_BANKS; endfunction

  // ---------------------------------------------------------------------------
  // §2.2 写 S0:按写地址低 3 位译出 one-hot bank 使能(纯组合)
  // ---------------------------------------------------------------------------
  // ★ 按写口存成 packed 的 8 位 one-hot bank 向量 ★（不是 [NUM_WRITE][N_BANKS]
  //   的二维非压缩数组）——下面 §2.3 的门控要整条向量比一次，packed 才能直接比，
  //   不必在时钟块里开临时量拼装。见 §2.3 里那条踩过的坑。
  logic [N_BANKS-1:0] s0_data_wen [NUM_WRITE];
  logic [N_BANKS-1:0] s0_mask_wen [NUM_WRITE];
  always_comb begin
    for (int w = 0; w < NUM_WRITE; w++) begin
      for (int b = 0; b < N_BANKS; b++) begin
        s0_data_wen[w][b] = data_wen[w] & (data_waddr[w][BANK_W-1:0] == BANK_W'(b));
        s0_mask_wen[w][b] = mask_wen[w] & (mask_waddr[w][BANK_W-1:0] == BANK_W'(b));
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §2.3 写 S1 的控制位(★本模块唯一的异步复位寄存器★)
  // ---------------------------------------------------------------------------
  // golden 的 `if (~(s0_vec == s1_vec)) s1_vec <= s0_vec` 是 GatedValidRegNext
  // 的降级形式:★门控条件比的是**整个 8 位 bank 向量**,不是逐 bank 比★
  // (golden L2422-2447 把 8 位拼起来做一次 == 比较)。值上与无条件打拍等价,
  // 这里照抄 golden 的形状。
  logic [N_BANKS-1:0] s1_data_wen [NUM_WRITE];
  logic [N_BANKS-1:0] s1_mask_wen [NUM_WRITE];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int w = 0; w < NUM_WRITE; w++) begin
        s1_data_wen[w] <= '0;
        s1_mask_wen[w] <= '0;
      end
    end else begin
      // ★ 这里一个临时量都不许声明 ★
      //   在 always_ff 里 declare 的变量会被前端推断成**寄存器**，哪怕它只在本拍
      //   组合使用。实测踩过一次：为了拼 8 位向量开了 4 个 automatic 变量，
      //   Formality 推出 4 组 × 2 写口 = 64 个没人读的寄存器（s0_d_reg/s0_m_reg…），
      //   native SUCCEEDED 但 unread=64 → 判 PARTIAL。
      //   修法是把 bank 使能本来就存成 packed 向量（见上面的声明），整条直接比。
      for (int w = 0; w < NUM_WRITE; w++) begin
        if (s0_data_wen[w] != s1_data_wen[w]) s1_data_wen[w] <= s0_data_wen[w];
        if (s0_mask_wen[w] != s1_mask_wen[w]) s1_mask_wen[w] <= s0_mask_wen[w];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §2.4 写 S1 的数据/行号(★不复位★,RegEnable 由 S0 使能开)
  // ---------------------------------------------------------------------------
  // 数据侧与掩码侧结构完全相同,只是负载宽度不同(8 位 vs 1 位)。golden 里它们
  // 就是两组宽度不同的寄存器,所以这里也不合并 —— 合并成 8 位再只用第 0 位,
  // 会多出 7 个没人读的位 → FM 判 unread。
  logic [DATA_W-1:0] s1_data_wdata [NUM_WRITE][N_BANKS];
  logic [ROW_W-1:0]  s1_data_waddr [NUM_WRITE][N_BANKS];
  logic              s1_mask_wdata [NUM_WRITE][N_BANKS];
  logic [ROW_W-1:0]  s1_mask_waddr [NUM_WRITE][N_BANKS];

  always_ff @(posedge clock) begin
    for (int w = 0; w < NUM_WRITE; w++) begin
      for (int b = 0; b < N_BANKS; b++) begin
        if (s0_data_wen[w][b]) begin
          s1_data_wdata[w][b] <= data_wdata[w];
          s1_data_waddr[w][b] <= data_waddr[w][ADDR_W-1:BANK_W];
        end
        if (s0_mask_wen[w][b]) begin
          s1_mask_wdata[w][b] <= mask_wdata[w];
          s1_mask_waddr[w][b] <= mask_waddr[w][ADDR_W-1:BANK_W];
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §2.5 写阵列(★不复位;写口 1 胜过写口 0★)
  // ---------------------------------------------------------------------------
  // for 内阻塞语义 = 后写者胜 = golden 的 if(口1)/else if(口0) 同形。
  // data 与 valid 各判各的:一个条目可能这拍只更新 valid、不更新 data。
  always_ff @(posedge clock) begin
    for (int e = 0; e < NUM_ENTRIES; e++) begin
      for (int w = 0; w < NUM_WRITE; w++) begin
        if (s1_mask_wen[w][bank_of(e)] &&
            s1_mask_waddr[w][bank_of(e)] == ROW_W'(row_of(e)))
          entries[e].valid <= s1_mask_wdata[w][bank_of(e)];
        if (s1_data_wen[w][bank_of(e)] &&
            s1_data_waddr[w][bank_of(e)] == ROW_W'(row_of(e)))
          entries[e].data <= s1_data_wdata[w][bank_of(e)];
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §2.6 同步读(★读地址寄存器无门控、无复位;越界落到条目 0★)
  // ---------------------------------------------------------------------------
  // 见文件头冲突 1 与 2。
  logic [ADDR_W-1:0] rdata_addr_r [NUM_READ];

  always_ff @(posedge clock) begin
    for (int i = 0; i < NUM_READ; i++) rdata_addr_r[i] <= raddr[i];
  end

  // ★ 不要写成 entries[idx < NUM_ENTRIES ? idx : 0] ★
  //   那样值是对的,但 Formality 的静态分析不做边界传播,会判 FMR_ELAB-147
  //   (索引可能越界)→ 拒绝 link(FM-262)→ set_top 失败(FM-156)。实测踩过一次。
  //   正确修法是**把表补齐到 2**ADDR_W 项**(下面两个 for 都在界内,地址位宽与
  //   表深度精确相等,按构造不可能越界),不是去抑制那条消息。
  //   附带好处:这个形状本来就更贴近 golden 的 _GEN / _GEN_0。
  localparam int READ_SLOTS = 1 << ADDR_W;   // 64

  entry_t entries_rtbl [READ_SLOTS];
  always_comb begin
    for (int k = 0;           k < NUM_ENTRIES; k++) entries_rtbl[k] = entries[k];
    for (int k = NUM_ENTRIES; k < READ_SLOTS;  k++) entries_rtbl[k] = entries[0];  // 越界槽
  end

  always_comb
    for (int i = 0; i < NUM_READ; i++) rdata[i] = entries_rtbl[rdata_addr_r[i]];

  // ---------------------------------------------------------------------------
  // §2.7 前递数据选择
  // ---------------------------------------------------------------------------
  // needForward[i][h] 由上层 StoreQueue 算好:把 [deqPtr, load.sqIdx) 这个"比本
  // load 老的 store"区间摊成两半 —— h=0 是与 deqPtr 同 flag 的那段,h=1 是环绕
  // 到队列头部的那段。两半合起来就是候选集合。
  //
  // 候选位要打一拍才和阵列对齐(阵列读是同步的),所以存 needCheckReg。★不复位★。
  logic needCheckReg [NUM_FWD][2][NUM_ENTRIES];

  always_ff @(posedge clock) begin
    for (int i = 0; i < NUM_FWD; i++)
      for (int h = 0; h < 2; h++)
        for (int j = 0; j < NUM_ENTRIES; j++)
          needCheckReg[i][h][j] <= needForward[i][h][j];
  end

  // 叶子编号 k = h*56 + j(与 golden 的 matchResultVec 下标一致)。
  //
  // ★ golden 用 ParallelOperation 建了一棵归约树 ★:
  //     res.valid = l.valid | r.valid
  //     res.data  = Mux(r.valid, r.data, l.data)      —— 右(下标大)优先
  //   树形由 `xs take size/2` / `xs drop size/2` 递归决定,112 片叶子的左脊
  //   分块是 1,2,4,7,14,28,56(golden 的 io_forwardValid_0 正是这 7 项 OR:
  //   res_{0,4,11,25,53,109} 再加叶子 0 —— 与此完全吻合)。
  //   把这棵树整体展开,结果恰好是:
  //       valid = 任一叶子命中
  //       data  = **下标最大**的命中叶子的数据;一个都不命中时 = 叶子 0 的数据
  //   (归纳:右子树有命中就取右子树,右无则取左;全无则取本区间最左叶子。)
  //   下面直接写这个等价的优先选择,可读得多,FM 一步就能合到一起。
  //
  // 语义上"下标最大优先" = **最年轻的 store 优先**,这正是前递要的语义:
  //   同一字节被多条老 store 写过时,load 应该拿最后写的那份。
  //   h=1(环绕段)整体比 h=0 下标大,也就整体更年轻。
  // ★写成「或归约 + 三目链」，不要写成 if (hit) { valid=1; data=... }★
  //   两者在二值下完全等价（FM 证过），但 X 行为不同：golden 的树是
  //   `valid = l.valid | r.valid` 与 `data = Mux(r.valid, r.data, l.data)`，
  //   命中位带 X 时 valid 会被 1 吸收、data 会传出 X；而 `if (hit)` 把 X 当假，
  //   凭空给出一个确定值。在 StoreQueue 的双例化 UT 里这条直接表现为
  //   forwardMask/forwardData 的 6 个字节道 × 3 个口共 36 根各失配 1 拍
  //   （golden=X，重写=确定值）。X 会出现是因为 sta 从 misalign buffer 回灌时
  //   addrvalid 置起但地址阵列没写，vaddr CAM 的命中位就是 X。
  always_comb begin
    for (int i = 0; i < NUM_FWD; i++) begin
      forwardValid[i] = 1'b0;
      forwardData[i]  = entries[0].data;     // 叶子 0 的数据 —— 全不命中时的缺省
      for (int h = 0; h < 2; h++) begin
        for (int j = 0; j < NUM_ENTRIES; j++) begin
          automatic logic hit = needCheckReg[i][h][j] & entries[j].valid;
          forwardValid[i] = forwardValid[i] | hit;
          forwardData[i]  = hit ? entries[j].data : forwardData[i];  // 下标最大者胜
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // §2.8 接口契约断言(StoreQueueData.scala:211 / :216)
  // ---------------------------------------------------------------------------
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (~reset) begin
      for (int i = 0; i < NUM_WRITE; i++)
        for (int j = i + 1; j < NUM_WRITE; j++) begin
          assert (!(data_wen[i] && data_wen[j] && data_waddr[i] == data_waddr[j]))
            else $fatal(1, "SQData8Module: data write ports %0d/%0d collide", i, j);
          assert (!(mask_wen[i] && mask_wen[j] && mask_waddr[i] == mask_waddr[j]))
            else $fatal(1, "SQData8Module: mask write ports %0d/%0d collide", i, j);
        end
    end
  end
`endif

endmodule

// -----------------------------------------------------------------------------
// §3 SQData8Module —— golden 同名薄 wrapper
// -----------------------------------------------------------------------------
// 端口名/顺序/位宽逐位对齐 G1 golden。
// ★ golden 没有 forwardValidFast 端口 ★(见文件头),这里也不引出。
module SQData8Module(
  input         clock,
  input         reset,
  input  [5:0]  io_raddr_0,
  input  [5:0]  io_raddr_1,
  output        io_rdata_0_valid,
  output [7:0]  io_rdata_0_data,
  output        io_rdata_1_valid,
  output [7:0]  io_rdata_1_data,
  input         io_data_wen_0,
  input         io_data_wen_1,
  input  [5:0]  io_data_waddr_0,
  input  [5:0]  io_data_waddr_1,
  input  [7:0]  io_data_wdata_0,
  input  [7:0]  io_data_wdata_1,
  input         io_mask_wen_0,
  input         io_mask_wen_1,
  input  [5:0]  io_mask_waddr_0,
  input  [5:0]  io_mask_waddr_1,
  input         io_mask_wdata_0,
  input         io_mask_wdata_1,
  input  [55:0] io_needForward_0_0,
  input  [55:0] io_needForward_0_1,
  input  [55:0] io_needForward_1_0,
  input  [55:0] io_needForward_1_1,
  input  [55:0] io_needForward_2_0,
  input  [55:0] io_needForward_2_1,
  output        io_forwardValid_0,
  output        io_forwardValid_1,
  output        io_forwardValid_2,
  output [7:0]  io_forwardData_0,
  output [7:0]  io_forwardData_1,
  output [7:0]  io_forwardData_2
);

  logic [5:0]  raddr      [2];
  logic        data_wen   [2];
  logic [5:0]  data_waddr [2];
  logic [7:0]  data_wdata [2];
  logic        mask_wen   [2];
  logic [5:0]  mask_waddr [2];
  logic        mask_wdata [2];
  logic [55:0] needForward [3][2];

  sq_data8_module_pkg::entry_t rdata [2];
  logic       forwardValid [3];
  logic [7:0] forwardData  [3];

  always_comb begin
    raddr[0]      = io_raddr_0;       raddr[1]      = io_raddr_1;
    data_wen[0]   = io_data_wen_0;    data_wen[1]   = io_data_wen_1;
    data_waddr[0] = io_data_waddr_0;  data_waddr[1] = io_data_waddr_1;
    data_wdata[0] = io_data_wdata_0;  data_wdata[1] = io_data_wdata_1;
    mask_wen[0]   = io_mask_wen_0;    mask_wen[1]   = io_mask_wen_1;
    mask_waddr[0] = io_mask_waddr_0;  mask_waddr[1] = io_mask_waddr_1;
    mask_wdata[0] = io_mask_wdata_0;  mask_wdata[1] = io_mask_wdata_1;

    needForward[0][0] = io_needForward_0_0;  needForward[0][1] = io_needForward_0_1;
    needForward[1][0] = io_needForward_1_0;  needForward[1][1] = io_needForward_1_1;
    needForward[2][0] = io_needForward_2_0;  needForward[2][1] = io_needForward_2_1;
  end

  xs_SQData8Module_core u_core (
    .clock        (clock),
    .reset        (reset),
    .raddr        (raddr),
    .rdata        (rdata),
    .data_wen     (data_wen),
    .data_waddr   (data_waddr),
    .data_wdata   (data_wdata),
    .mask_wen     (mask_wen),
    .mask_waddr   (mask_waddr),
    .mask_wdata   (mask_wdata),
    .needForward  (needForward),
    .forwardValid (forwardValid),
    .forwardData  (forwardData)
  );

  assign io_rdata_0_valid  = rdata[0].valid;
  assign io_rdata_0_data   = rdata[0].data;
  assign io_rdata_1_valid  = rdata[1].valid;
  assign io_rdata_1_data   = rdata[1].data;

  assign io_forwardValid_0 = forwardValid[0];
  assign io_forwardValid_1 = forwardValid[1];
  assign io_forwardValid_2 = forwardValid[2];
  assign io_forwardData_0  = forwardData[0];
  assign io_forwardData_1  = forwardData[1];
  assign io_forwardData_2  = forwardData[2];

endmodule
