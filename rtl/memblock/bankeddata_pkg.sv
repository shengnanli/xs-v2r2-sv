// =============================================================================
// bankeddata_pkg —— BankedDataArray（DCache 分体数据阵列）公共定义
// -----------------------------------------------------------------------------
// 对应 Chisel: xiangshan.cache.BankedDataArray.scala  class BankedDataArray
//   （“最小访问单位 = bank”的实现；另有 SramedDataArray 是“最小单位 = sram”的变体，
//     本配置例化的是 BankedDataArray，golden 顶层名即 BankedDataArray）。
//
// 阵列组织（本配置）：
//   DCacheSetDiv = 1     —— 不再细分 set（div 维退化为 1）。
//   DCacheBanks  = 8     —— 一条 64B cacheline 横向切 8 个 bank，每 bank 8B(64bit)。
//   DCacheWays   = 4     —— 4 路组相联。
//   nSets        = 256   —— set 索引 8bit（addr[13:6]）。
//   每个 bank 是一个 DataSRAMBank（内含 4 路 SRAM，深 256、宽 72bit = 64 数据 + 8 ECC）。
//   合计 8 个 DataSRAMBank（× 4 路 = 32 块单口 SRAM）。
//
// 地址切分（addr 物理地址，本配置 PAddrBits=48，端口 48bit）：
//   bank 偏移 = addr[5:3]（DCacheBankOffset=3 .. DCacheSetOffset=6）。
//   set  索引 = addr[13:6]（DCacheSetOffset=6 .. DCacheAboveIndexOffset=14）。
//   div       = 恒 0（DCacheSetDiv=1）。
//
// 本包提供：读结果 struct、数据 ECC（SECDED(72,64)）的编码/解码纯函数、位宽常量。
// 存储体 DataSRAMBank（→ SRAMTemplate → 厂商宏）与 MbistPipeDCacheData 当 golden 黑盒。
// =============================================================================
package bankeddata_pkg;

  localparam int LOAD_PIPES = 3;   // LoadPipelineWidth（3 个 load 读端口）
  localparam int N_BANKS    = 8;   // DCacheBanks
  localparam int N_WAYS     = 4;   // DCacheWays
  localparam int SET_DIV    = 1;   // DCacheSetDiv
  localparam int ROW_BITS   = 64;  // DCacheSRAMRowBits（每 bank 数据位宽）
  localparam int ECC_BITS   = 8;   // dataECCBits（SECDED 校验位）
  localparam int ENC_BITS   = ROW_BITS + ECC_BITS;  // = 72，SRAM 字宽
  localparam int IDX_W      = 8;   // set 索引位宽（256 组）
  localparam int BANK_W     = 3;   // bank 索引位宽（8 bank）
  localparam int WAY_W      = 2;   // way 索引位宽（4 路）
  localparam int ADDR_W     = 48;  // 物理地址位宽
  localparam int N_LINES    = 2;   // VLEN/DCacheSRAMRowBits = 128/64 = 2（每读口跨 2 行）

  // 一拍读结果（每 bank/way 一份）：原始数据 + ECC + 延迟一拍的 error 标志
  typedef struct packed {
    logic [ECC_BITS-1:0] ecc;
    logic [ROW_BITS-1:0] raw_data;
    logic                error_delayed;
  } read_result_t;

  // ---- 地址切分 ----
  function automatic logic [BANK_W-1:0] addr_to_bank(input logic [ADDR_W-1:0] a);
    addr_to_bank = a[5:3];
  endfunction
  function automatic logic [IDX_W-1:0] addr_to_set(input logic [ADDR_W-1:0] a);
    addr_to_set = a[13:6];
  endfunction

  // ---------------------------------------------------------------------------
  // 数据 ECC：SECDED(72,64)（与 rocket-chip SECDEDCode + golden 完全一致）
  // ---------------------------------------------------------------------------
  // 编码：对 64bit 数据算 8bit 校验码。
  //   ecc[6:0]：7 个奇偶位，第 k 位 = data 在固定生成掩码上的 XOR 归约。
  //   ecc[7]  ：整体奇偶位 = 对 {ecc[6:0], data} 全体再 XOR。
  function automatic logic [ECC_BITS-1:0] data_ecc_encode(input logic [ROW_BITS-1:0] data);
    logic [6:0] p;
    logic       overall;
    p[0] = ^(data & 64'hAB55555556AAAD5B);
    p[1] = ^(data & 64'hCD9999999B33366D);
    p[2] = ^(data & 64'hF1E1E1E1E3C3C78E);
    p[3] = ^(data & 64'h01FE01FE03FC07F0);
    p[4] = ^(data & 64'h01FFFE0003FFF800);
    p[5] = ^(data & 64'h01FFFFFFFC000000);
    p[6] = ^(data & 64'hFE00000000000000);
    overall = ^{p, data};
    data_ecc_encode = {overall, p};
  endfunction

  // 解码错误标志：对存好的 72bit encData（{ecc,data}）算综合错误位。
  //   error = 整体奇偶为 1（奇数个翻转，可能是单错可纠）
  //         | （整体奇偶为 0 且 syndrome 非零 → 偶数个翻转，双错不可纠）。
  //   syndrome 的 7 位由各级掩码对 encData 高位窗口做 XOR 得到（掩码即 H 矩阵行）。
  function automatic logic data_ecc_error(input logic [ENC_BITS-1:0] enc);
    logic       overall;       // 整体奇偶
    logic [6:0] syndrome;
    overall    = ^enc;
    syndrome[0] = ^({enc[70:57] & 14'h207F,            57'h0});
    syndrome[1] = ^({enc[69:26] & 44'h8007FFFFFFF,     26'h0});
    syndrome[2] = ^({enc[68:11] & 58'h2003FFFC0007FFF, 11'h0});
    syndrome[3] = ^({enc[67:4]  & 64'h801FE01FE03FC07F, 4'h0});
    syndrome[4] = ^({enc[66:1]  & 66'h278F0F0F0F1E1E3C7, 1'h0});
    syndrome[5] = ^( enc[65:0]  & 66'h2CD9999999B33366D);
    syndrome[6] = ^( enc[64:0]  & 65'h1AB55555556AAAD5B);
    data_ecc_error = overall | (~overall & (|syndrome));
  endfunction

  // OHToUInt：4bit one-hot way_en → 2bit way 索引（与 golden OHToUInt 同义）
  function automatic logic [WAY_W-1:0] oh_to_way(input logic [N_WAYS-1:0] oh);
    oh_to_way = {oh[3] | oh[2], oh[3] | oh[1]};
  endfunction

endpackage
