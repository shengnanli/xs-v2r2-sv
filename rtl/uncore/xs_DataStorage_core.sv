// xs_DataStorage_core.sv —— L2 数据阵列的读写前端：SECDED 编码 / 校验 + 请求路由（DataStorage* 共用核）
//
// 对照 coupledL2/src/main/scala/coupledL2/DataStorage.scala（配置 KunminghuV2Config：dataECC=secded，
// dataBankSplit=4，blockBits=512，extraHold/MCP2 SRAM）。DataStorage / DataStorage_1..3 是四个 slice
// 的单态化，逻辑完全相同，只差数据阵列与 MBIST 节点是哪个单态化（由各自薄 wrapper 例化）。
//
// 数据通路（一次访问一个 512 位 cache 块）：
//   * 块按 128 位切成 4 个 bank 数据；每个 bank 数据做 SECDED(128) 编码成 137 位：
//       {整体奇偶位, 8 位 Hamming 校验, 128 位数据}（rocket/utility 的 SECDEDCode = Parity(SEC(x))）
//     4 个 137 位码字拼成 548 位写进 GatedSplittedSRAM。★拼接顺序★：Chisel `Cat(Vec)` 把第 0 个元素
//     放在最高位，所以 wdata[127:0] 的码字在阵列字的 [547:411]，wdata[511:384] 的在 [136:0]。
//   * 读回时每个码字取低 128 位数据，按同样的"第 0 片在最高位"拼回，于是 rdata 与 wdata 位序一致。
//   * io.error：4 个码字任一"可纠或不可纠"即报错 —— 即 整体奇偶错 | Hamming 伴随式非 0 ——
//     再与"两拍前是读请求"相与（读数据 MCP2：s3 发读、s5 才用到）。
//   * 读写共用一个请求口：valid&wen 写、valid&!wen 读，地址 = {way, set}（12 位，4096 块）。
//
// 断言影子寄存器：Scala 里三条 MCP2 保持性 assert 用到 RegNext(io.en) 等 5 个寄存器；assert 本身在
// golden 的 `ifndef SYNTHESIS 里，但**寄存器在综合网表里仍然存在**（只是没人读）。照 CONVENTIONS
// 「debug 寄存器照写」保留，名字与 golden 对应（mcpEnPrev = REG ...），FM 里是两侧对称的未读点。

module xs_DataStorage_core #(
  parameter int unsigned BANKS     = 4,     // dataBankSplit
  parameter int unsigned BANK_BITS = 128,   // 每 bank 数据位
  parameter int unsigned ENC_BITS  = 137,   // SECDED(128) 码字位宽
  parameter int unsigned IDX_W     = 12     // {way(3), set(9)}
)(
  input  logic                        clock,
  input  logic                        reset,

  // ---- 来自 MainPipe 的请求 ----
  input  logic                        en,          // 本拍真的读/写（给 SRAM 时钟门控用）
  input  logic                        req_valid,
  input  logic [2:0]                  req_way,
  input  logic [8:0]                  req_set,
  input  logic                        req_wen,
  input  logic [BANKS*BANK_BITS-1:0]  wdata,
  output logic [BANKS*BANK_BITS-1:0]  rdata,
  output logic                        error,

  // ---- 到数据阵列（GatedSplittedSRAM）----
  output logic                        arr_r_valid,
  output logic                        arr_w_valid,
  output logic [IDX_W-1:0]            arr_setIdx,
  output logic [BANKS*ENC_BITS-1:0]   arr_wdata,
  input  logic [BANKS*ENC_BITS-1:0]   arr_rdata
);

  localparam int unsigned SEC_BITS = ENC_BITS - 1;            // 136：Hamming 码字（不含整体奇偶位）
  localparam int unsigned CHK_BITS = SEC_BITS - BANK_BITS;    // 8：Hamming 校验位数

  // ===========================================================================
  // §1 SECDED 的 Hamming 校验矩阵（elaborate 期由 SECCode 的定义算出，不手抄常数）
  //   Hamming 下标 h = 1..SEC_BITS：2 的幂位置放校验位，其余放数据。
  //   系统码布局：数据在低 BANK_BITS 位，第 j 个校验位在 BANK_BITS + j。
  //   hamm2sys(h) = 2 的幂 ? BANK_BITS + log2(h) : h - 1 - ceil(log2(h))
  //   校验位 j 覆盖所有 Hamming 下标第 j 位为 1 的系统位 s：SYN_MASK[j][s] = sys2hamm(s)[j]
  // ===========================================================================
  function automatic int unsigned clog2_int(input int unsigned v);
    int unsigned r;
    r = 0;
    while ((1 << r) < v) r++;
    return r;
  endfunction

  function automatic logic [SEC_BITS-1:0] syndrome_mask(input int unsigned j);
    logic [SEC_BITS-1:0] mask;
    int unsigned sys;
    mask = '0;
    for (int unsigned h = 1; h <= SEC_BITS; h++) begin
      if ((h & (h - 1)) == 0) sys = BANK_BITS + clog2_int(h);   // 校验位
      else                    sys = h - 1 - clog2_int(h);       // 数据位
      if ((h >> j) & 1) mask[sys] = 1'b1;
    end
    return mask;
  endfunction

  // 编码：x(128) -> {^secWord, secWord}，secWord = {syndrome(8), x}
  function automatic logic [ENC_BITS-1:0] secded_encode(input logic [BANK_BITS-1:0] x);
    logic [CHK_BITS-1:0] chk;
    logic [SEC_BITS-1:0] secWord;
    for (int unsigned j = 0; j < CHK_BITS; j++)
      chk[j] = ^(syndrome_mask(j) & {{CHK_BITS{1'b0}}, x});
    secWord = {chk, x};
    return {^secWord, secWord};
  endfunction

  // 校验：整体奇偶错（可纠的单比特错）或 Hamming 伴随式非 0（不可纠的双比特错）都算 error
  function automatic logic secded_error(input logic [ENC_BITS-1:0] y);
    logic                parityErr;
    logic [CHK_BITS-1:0] syn;
    parityErr = ^y;
    for (int unsigned j = 0; j < CHK_BITS; j++)
      syn[j] = ^(syndrome_mask(j) & y[SEC_BITS-1:0]);
    return parityErr | (~parityErr & (|syn));
  endfunction

  // ===========================================================================
  // §2 请求路由与写编码
  // ===========================================================================
  assign arr_setIdx  = {req_way, req_set};
  assign arr_w_valid = req_valid &  req_wen;
  assign arr_r_valid = req_valid & ~req_wen;

  // 第 i 片数据（wdata 的第 i 个 128 位）的码字放在阵列字的第 (BANKS-1-i) 个 137 位槽
  for (genvar i = 0; i < int'(BANKS); i++) begin : g_enc
    assign arr_wdata[(BANKS-1-i)*ENC_BITS +: ENC_BITS] = secded_encode(wdata[i*BANK_BITS +: BANK_BITS]);
  end

  // ===========================================================================
  // §3 读数据与 ECC 错误
  // ===========================================================================
  // 阵列第 s 个 137 位槽的数据低 128 位，放到 rdata 的第 (BANKS-1-s) 个 128 位（与写对称）
  logic [BANKS-1:0] bankError;
  for (genvar s = 0; s < int'(BANKS); s++) begin : g_dec
    assign rdata[(BANKS-1-s)*BANK_BITS +: BANK_BITS] = arr_rdata[s*ENC_BITS +: BANK_BITS];
    assign bankError[s] = secded_error(arr_rdata[s*ENC_BITS +: ENC_BITS]);
  end

  // 读请求打两拍，与 MCP2 读数据对齐（不复位，golden RegNext(RegNext(...))）
  logic error_REG, error_REG_1;
  always_ff @(posedge clock) begin
    error_REG   <= req_valid & ~req_wen;
    error_REG_1 <= error_REG;
  end
  assign error = (|bankError) & error_REG_1;

  // ===========================================================================
  // §4 断言影子寄存器（只被 `ifndef SYNTHESIS 的 assert 读；照 golden 保留，见文件头）
  //   mcpEnPrev   = RegNext(io.en, false.B)            golden REG（异步复位）
  //   enPrev      = RegNext(io.en)                     golden REG_1
  //   reqPrev     = RegNext(io.req.asUInt)             golden REG_2 = {valid, way, set, wen}
  //   wrEnPrev    = RegNext(io.en && io.req.bits.wen)  golden REG_3
  //   wdataPrev   = RegNext(io.wdata.asUInt)           golden REG_4
  // ===========================================================================
  logic                       mcpEnPrev;
  logic                       enPrev;
  logic [13:0]                reqPrev;
  logic                       wrEnPrev;
  logic [BANKS*BANK_BITS-1:0] wdataPrev;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) mcpEnPrev <= 1'b0;
    else       mcpEnPrev <= en;
  end
  always_ff @(posedge clock) begin
    enPrev    <= en;
    reqPrev   <= {req_valid, req_way, req_set, req_wen};
    wrEnPrev  <= en & req_wen;
    wdataPrev <= wdata;
  end

endmodule
