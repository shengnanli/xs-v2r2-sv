// =============================================================================
// ICacheDataArray —— 指令缓存数据阵列（可读重写核 xs_ICacheDataArray）
// -----------------------------------------------------------------------------
// 角色：香山 V2R2 前端 ICache 的“数据体”。它只存指令字节本身（不含 tag/valid），
//       与 ICacheMetaArray（存 tag/ECC、负责命中判定）配对工作：
//         · MainPipe 先查 Meta 得到命中 way（one-hot waymask）；
//         · 同一/下一拍把 waymask + 取指偏移送进本数据阵列，读出对应 way 的指令数据。
//
// 组织（组相联 + bank 化）：
//   · 路数  NUM_WAYS  = 4   ：4 路组相联，命中 way 由 waymask one-hot 指出。
//   · bank  NUM_BANKS = 8   ：一条 64B cacheline 横向切成 8 个 bank，每 bank 8B。
//   · 组数  256（setIdx 8bit）。
//   · 每个 (way, bank) 各一块单口 SRAM，深 256、宽 65bit = 64bit 数据 + 1bit 校验码。
//   合计 4×8 = 32 块 SRAM，覆盖 “4 路 × 8 bank” 的二维阵列。
//
// 为什么 bank 化、为什么要“跨行读取”：
//   取指请求给出 cacheline 内字节偏移 blkOffset。前端一次取指窗口固定访问
//   ICacheBankVisitNum 个连续 bank，且窗口可能从某条 cacheline 中间开始、一直延伸到
//   “下一条”cacheline（跨越行边界）。因此：
//     · 同一次读，靠后的若干 bank 仍属“当前行(line0)”，靠前的若干 bank 已“翻篇”属
//       “下一行(line1)”——这正是 lineSel 表达的。
//     · 上层为两条行各给一个组索引 vSetIdx[0]/vSetIdx[1] 和各自命中掩码
//       waymask[0]/waymask[1]。
//   bank 化让 8 个 bank 并行、各用不同行地址独立访问，一拍读出横跨两行的指令流。
//
// 读时序（SRAM 同步读，holdRead=true）：
//   第 0 拍：组合算出 masks（哪一 (way,bank) 本拍真正要读）使能各 bank SRAM 读，
//            同时把 masks 打一拍存进 masksReg。
//   第 1 拍：各 bank SRAM 吐出 65bit；按 masksReg（命中 way 的 one-hot）做 Mux1H，
//            从 4 路选出该 bank 数据，拆出 64bit 数据 + 1bit code 输出。
//
// 写时序（refill）：
//   写口一次写入一整条 cacheline（512bit）。按 bank 切 8 段，每段补 1bit 校验码组成
//   65bit。waymask 选中要写的那一路；8 个 bank 用同一 setIdx=virIdx 同拍写入。
//
// ECC（这里是奇偶校验，code 宽 1bit）：
//   写入时 code = (^data) ^ poison（数据按位异或，再叠加 poison 人为注错）。
//   读出时本模块把 {data, code} 原样吐给下游；真正“拿 code 重算判错”在 MainPipe。
//
// SRAM / Mbist 黑盒：实际厂商存储宏与 Mbist 流水沿用 golden 同名模块，在 wrapper 层
//   例化并完成 DFT 互联。本核只产出/接收各 (way,bank) SRAM 的读写端口信号（见末尾的
//   sram_* 数组端口），不含存储体与 DFT 细节，从而聚焦数据阵列本身的可读逻辑。
// =============================================================================
module xs_ICacheDataArray #(
    parameter int NUM_WAYS  = 4,    // 路数
    parameter int NUM_BANKS = 8,    // 每行 bank 数
    parameter int SET_IDX_W = 8,    // 组索引位宽（256 组）
    parameter int DATA_W    = 64,   // 每 bank 数据位宽
    parameter int CODE_W    = 1,    // 校验码位宽（奇偶校验）
    parameter int BLK_OFF_W = 6     // cacheline 内字节偏移位宽（64B）
) (
    input  logic clock,
    input  logic reset,

    // ---- 写口（refill）：一次写入一整条 cacheline ----
    input  logic                          write_valid,
    input  logic [SET_IDX_W-1:0]          write_virIdx,    // 写入组索引
    input  logic [NUM_BANKS*DATA_W-1:0]   write_data,      // 512bit 整行数据
    input  logic [NUM_WAYS-1:0]           write_waymask,   // 选中写哪一路
    input  logic                          write_poison,    // ECC 毒化（注错）

    // ---- 读口：4 个读端口（控制扇出的副本），关键信息全部取自 read[0] ----
    input  logic                          read_valid   [NUM_BANKS-1:0],   // 仅 read[0..3] 实际使用
    input  logic [SET_IDX_W-1:0]          read_vSetIdx [NUM_BANKS-1:0][1:0], // [port][line]
    input  logic [NUM_WAYS-1:0]           read_waymask [1:0],             // [line][way]
    input  logic [BLK_OFF_W-1:0]          read_blkOffset,
    output logic                          read_ready,                     // = ~write_valid

    // ---- 读结果：每 bank 一组 {数据, 校验码} ----
    output logic [DATA_W-1:0]             resp_datas [NUM_BANKS-1:0],
    output logic                          resp_codes [NUM_BANKS-1:0],

    // ---- 与各 (way,bank) SRAM 黑盒的接口（wrapper 例化 SRAM 后回连）----
    output logic                          sram_r_valid  [NUM_WAYS-1:0][NUM_BANKS-1:0],
    output logic [SET_IDX_W-1:0]          sram_r_setIdx [NUM_WAYS-1:0][NUM_BANKS-1:0],
    input  logic [DATA_W+CODE_W-1:0]      sram_r_data   [NUM_WAYS-1:0][NUM_BANKS-1:0],
    output logic                          sram_w_valid  [NUM_WAYS-1:0][NUM_BANKS-1:0],
    output logic [SET_IDX_W-1:0]          sram_w_setIdx [NUM_WAYS-1:0][NUM_BANKS-1:0],
    output logic [DATA_W+CODE_W-1:0]      sram_w_data   [NUM_WAYS-1:0][NUM_BANKS-1:0]
);

  // ---------------------------------------------------------------------------
  // 0) 派生常量
  // ---------------------------------------------------------------------------
  localparam int ENTRY_W      = DATA_W + CODE_W;           // 单 bank SRAM 字宽 = 65
  localparam int BANK_IDX_W   = $clog2(NUM_BANKS);         // bank 索引位宽 = 3
  localparam int WINDOW_BANKS = 32 / (DATA_W / 8);         // 取指窗口跨度 = 4 个 bank

  // ---------------------------------------------------------------------------
  // 1) 写数据切 bank + 计算校验码
  //    每 bank 取 write_data 对应 64bit 段，code = (^data) ^ poison。
  // ---------------------------------------------------------------------------
  // 纯函数：对 64bit 数据算 1bit 奇偶校验码（叠加 poison 注错）
  function automatic logic encode_parity(input logic [DATA_W-1:0] data,
                                         input logic              poison);
    return (^data) ^ poison;
  endfunction

  logic [ENTRY_W-1:0] write_entries [NUM_BANKS-1:0];   // {data, code} per bank
  for (genvar b = 0; b < NUM_BANKS; b++) begin : g_write_entry
    wire [DATA_W-1:0] bank_data = write_data[b*DATA_W +: DATA_W];
    assign write_entries[b] = {bank_data, encode_parity(bank_data, write_poison)};
  end

  // ---------------------------------------------------------------------------
  // 2) 读地址译码：bankSel / lineSel / masks
  //    bankIdxLow  = blkOffset[5:3]                （取指起始 bank，0..7）
  //    bankIdxHigh = bankIdxLow + WINDOW_BANKS      （窗口末端 bank，可跨入下一行）
  //    bankSel[i]  = (i>=low) && (i<=high)，i=0..2*NUM_BANKS-1，窗口选择向量。
  //      低半段 bankSel[0..7]   归当前行(line0)，高半段 bankSel[8..15] 归下一行(line1)。
  //    lineSel[b]  = (b < bankIdxLow)：物理 bank b 已“翻篇”取下一行。
  // ---------------------------------------------------------------------------
  wire [BANK_IDX_W-1:0]   bankIdxLow  = read_blkOffset[BLK_OFF_W-1 -: BANK_IDX_W];
  // bankIdxHigh 取值 0..(NUM_BANKS+WINDOW-1)，需比 bankIdxLow 多 1bit
  wire [BANK_IDX_W:0]     bankIdxHigh = {1'b0, bankIdxLow} + BANK_IDX_W'(WINDOW_BANKS);

  logic bankSel [2*NUM_BANKS-1:0];   // 窗口选择向量
  logic lineSel [NUM_BANKS-1:0];     // 各物理 bank 取“下一行”还是“当前行”
  always_comb begin
    for (int i = 0; i < 2*NUM_BANKS; i++) begin
      logic [BANK_IDX_W+1:0] idx;
      idx        = (BANK_IDX_W+2)'(i);
      bankSel[i] = (idx >= {2'b0, bankIdxLow}) && (idx <= {1'b0, bankIdxHigh});
    end
    for (int b = 0; b < NUM_BANKS; b++) begin
      logic [BANK_IDX_W:0] bidx;
      bidx       = (BANK_IDX_W+1)'(b);
      lineSel[b] = (bidx < {1'b0, bankIdxLow});
    end
  end

  // masks[way][bank]：本拍 (way,bank) 是否真正发起读。
  //   翻篇 bank 用下一行掩码 waymask[1] + 高半段 bankSel[NUM_BANKS+bank]；
  //   未翻篇 bank 用当前行掩码 waymask[0] + 低半段 bankSel[bank]。
  logic masks [NUM_WAYS-1:0][NUM_BANKS-1:0];
  always_comb begin
    for (int w = 0; w < NUM_WAYS; w++) begin
      for (int b = 0; b < NUM_BANKS; b++) begin
        masks[w][b] = lineSel[b] ? (read_waymask[1][w] & bankSel[NUM_BANKS + b])
                                 : (read_waymask[0][w] & bankSel[b]);
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 3) masks 打一拍：第 1 拍据此对各 bank 做 Mux1H 选路
  //    （read_valid[0] 作为整体读使能门控寄存器更新）
  // ---------------------------------------------------------------------------
  logic masksReg [NUM_WAYS-1:0][NUM_BANKS-1:0];
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int w = 0; w < NUM_WAYS; w++)
        for (int b = 0; b < NUM_BANKS; b++)
          masksReg[w][b] <= 1'b0;
    end
    else if (read_valid[0]) begin
      for (int w = 0; w < NUM_WAYS; w++)
        for (int b = 0; b < NUM_BANKS; b++)
          masksReg[w][b] <= masks[w][b];
    end
  end

  // ---------------------------------------------------------------------------
  // 4) 驱动各 (way,bank) SRAM 读/写端口
  //    读地址：bank b 用读端口 (b % 4)，行号按 lineSel 在两条行索引间选择
  //            （bank 7 因 lineSel 恒 0，固定用 vSetIdx[0]）。
  //    读使能：read_valid[b%4] & masks[way][bank]。
  //    写：    write_valid & write_waymask[way]，同 setIdx=virIdx，数据为本 bank 字。
  // ---------------------------------------------------------------------------
  for (genvar w = 0; w < NUM_WAYS; w++) begin : g_way
    for (genvar b = 0; b < NUM_BANKS; b++) begin : g_bank
      localparam int RP = b % 4;   // 该 bank 使用的读端口
      // 读行地址：翻篇取下一行，否则取当前行
      assign sram_r_setIdx[w][b] = lineSel[b] ? read_vSetIdx[RP][1] : read_vSetIdx[RP][0];
      assign sram_r_valid [w][b] = read_valid[RP] & masks[w][b];
      assign sram_w_valid [w][b] = write_valid & write_waymask[w];
      assign sram_w_setIdx[w][b] = write_virIdx;
      assign sram_w_data  [w][b] = write_entries[b];
    end
  end

  // ---------------------------------------------------------------------------
  // 5) 读数据选路（Mux1H）+ 拆 {数据, 校验码}
  //    每 bank 在 4 路里按 masksReg 选出命中那一路的 65bit；高 64 为数据，低 1 为 code。
  // ---------------------------------------------------------------------------
  logic [ENTRY_W-1:0] read_entry [NUM_BANKS-1:0];
  always_comb begin
    for (int b = 0; b < NUM_BANKS; b++) begin
      read_entry[b] = '0;
      for (int w = 0; w < NUM_WAYS; w++) begin
        read_entry[b] |= masksReg[w][b] ? sram_r_data[w][b] : '0;
      end
    end
  end

  for (genvar b = 0; b < NUM_BANKS; b++) begin : g_resp
    assign resp_datas[b] = read_entry[b][ENTRY_W-1 -: DATA_W];  // 高 64bit = 数据
    assign resp_codes[b] = read_entry[b][0];                    // 低 1bit  = 校验码
  end

  // ---------------------------------------------------------------------------
  // 6) 读 ready：写优先，有写请求时读不被接受
  // ---------------------------------------------------------------------------
  assign read_ready = ~write_valid;

endmodule
