// =============================================================================
// dtagarray_pkg —— DuplicatedTagArray（DCache 多副本 Tag 阵列）公共定义
// -----------------------------------------------------------------------------
// 对应 Chisel: xiangshan.cache.TagArray.scala 里的
//   class DuplicatedTagArray / class TagArray / class TagSRAMBank。
//
// 本包仅提供 DuplicatedTagArray 顶层自身要用到的「Tag ECC 编码」纯函数与位宽常量。
// 真正的存储体（TagSRAMBank → SRAMTemplate → 厂商宏）与 Mbist 流水当 golden 黑盒，
// 由 wrapper 例化；可读核只负责「副本管理 + 读写路由 + 写入时算 Tag ECC」。
//
// 关于 Tag ECC（SECDED 单纠错双检错，rocket-chip SECDEDCode）：
//   · 物理 tag 宽 TAG_W=36（DCacheTagOffset..PAddrBits 的物理标签）。
//   · 校验码宽 ECC_W=7，合起来 encTag = {ecc[6:0], tag} 共 43bit 存进 SRAM。
//   · 写入路径在 DuplicatedTagArray 顶层算好 7bit ecc，再扇出给 4 个 TagArray 副本，
//     这样 4 份副本存的内容完全一致（多副本只是为多读口分流，存的是同一张 tag 表）。
//   · 读出路径直接把 SRAM 里的 43bit encTag 透传给上层（命中判定/纠错在 MetaArray 顶）。
// =============================================================================
package dtagarray_pkg;

  // ---- 位宽常量（本配置：DCacheWays=4, nSets=256, DCacheWayDiv=2）----
  localparam int READ_PORTS = 4;   // 读端口/副本数（DuplicatedTagArray(readPorts=4)）
  localparam int N_WAYS     = 4;   // 路数（way_en 4bit）
  localparam int IDX_W      = 8;   // 组索引位宽（256 组）
  localparam int TAG_W      = 36;  // 物理 tag 位宽
  localparam int ECC_W      = 7;   // SECDED 校验码位宽
  localparam int ENC_TAG_W  = TAG_W + ECC_W;  // = 43，SRAM 字宽

  // ---------------------------------------------------------------------------
  // SECDED(43,36) 校验码生成（与 rocket-chip SECDEDCode.encode 一致）
  //   ecc[5:0]：6 个奇偶校验位，每位是 tag 在某固定生成掩码上的 XOR 归约。
  //   ecc[6]  ：整体奇偶位 = 对 {ecc[5:0], tag} 全体再做一次 XOR（保证总奇偶，
  //            使其具备「双比特错检出」能力）。
  //   掩码取值与 golden 完全一致（这些是码字的生成矩阵常量，属设计常量非生成临时名）。
  // ---------------------------------------------------------------------------
  function automatic logic [ECC_W-1:0] tag_ecc_encode(input logic [TAG_W-1:0] tag);
    logic [5:0] p;        // 6 个奇偶校验位
    logic       overall;  // 整体奇偶位
    p[0] = ^(tag & 36'h556AAAD5B);
    p[1] = ^(tag & 36'h99B33366D);
    p[2] = ^(tag & 36'h1E3C3C78E);
    p[3] = ^(tag & 36'hE03FC07F0);
    p[4] = ^(tag & 36'h003FFF800);
    p[5] = ^(tag & 36'hFFC000000);
    overall = ^{p, tag};
    tag_ecc_encode = {overall, p};
  endfunction

endpackage
