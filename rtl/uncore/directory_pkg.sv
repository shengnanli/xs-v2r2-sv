// =============================================================================
//  directory_pkg —— coupledL2 (tl2chi) L2 缓存目录 Directory 的参数与类型
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/src/main/scala/coupledL2/Directory.scala
//  单态化参数 (firtool Directory.sv):
//    ways=8, sets=512, wayBits=3, setBits=9, tagBits=31
//    mshrsAll=16 (io_msInfo 16 路)
//    enableTagECC=true  → tagArray 每路 38 bit = 31 数据 + 6 Hamming 校验 + 1 总奇偶 (SECDED)
//    replacement="drrip" → 2-bit RRPV/路, replacer SRAM = 16 bit/set; 含 set-dueling PSEL
// =============================================================================
package directory_pkg;

  localparam int WAYS     = 8;
  localparam int WAY_BITS = 3;
  localparam int SETS     = 512;
  localparam int SET_BITS = 9;
  localparam int TAG_BITS = 31;
  localparam int ENC_TAG  = 38;   // ECC 编码后位宽
  localparam int MSHRS    = 16;

  // L2 目录元数据 (MetaEntry)。字段顺序与 golden 一致。
  typedef struct packed {
    logic        dirty;
    logic [1:0]  state;       // MetaData: INVALID=0, BRANCH=1, TRUNK=2, TIP=3
    logic        clients;     // 上层 client 是否持有该块 (valid-bit)
    logic [1:0]  alias_bits;  // client 的 alias 位
    logic        prefetch;    // 该块是否由预取带入
    logic [2:0]  prefetchSrc; // 预取来源
    logic        accessed;
    logic        tagErr;
    logic        dataErr;
  } meta_entry_t;

endpackage
