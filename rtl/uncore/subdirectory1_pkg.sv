// =============================================================================
//  subdirectory1_pkg —— openLLC 目录子块 SubDirectory_1(selfDir 实例)参数/类型
// -----------------------------------------------------------------------------
//  对照 Scala openLLC/src/main/scala/openLLC/Directory.scala 的 selfDir:
//    SubDirectory[SelfMetaEntry], replacement = cacheParams.replacement = "plru"
//  firtool 单态化 golden/chisel-rtl/SubDirectory_1.sv:
//    sets=4096(setBits=12), ways=16(wayBits=4), tagBits=28,
//    meta = SelfMetaEntry{valid, dirty}  →  每路 2 位
//    replacement = "plru"  →  15 位二叉树状态(replacer_sram), 含命中/refill 时更新
//
//  三级流水(同 SubDirectory):
//    stage1: io.read.fire, 发起 Tag/Meta/Replacer SRAM 读
//    stage2: SRAM 数据回来, 锁存 tagAll_s3/metaAll_s3/repl_state_s3 (reqValid_s2 门控)
//    stage3: 算 hit/way, PLRU 选替换路, 命中/refill 时回写 replacer_sram
//
//  3 个黑盒子模块(在 wrapper 内例化):
//    SRAMTemplate_199  tagArray            (16 路 × 28bit × 4096 set, 单口)
//    SRAMTemplate_200  metaArray           (16 路 × {valid,dirty} × 4096 set, 单口)
//    SRAMTemplate_201  replacer_sram_opt   (1 × 15bit × 4096 set, 单口, shouldReset)
// =============================================================================
package subdirectory1_pkg;

  localparam int WAYS     = 16;
  localparam int WAY_BITS = 4;
  localparam int SETS     = 4096;
  localparam int SET_BITS = 12;
  localparam int TAG_BITS = 28;
  localparam int PLRU_BITS = 15;   // 16 路二叉 PLRU = 15 个节点

  // SelfMetaEntry: valid + dirty。字段顺序与下游 io_resp_bits_meta_* 一致。
  typedef struct packed {
    logic valid;
    logic dirty;
  } self_meta_entry_t;

  // CHI 命中时更新 PLRU 的 opcode(只读独占/读非脏共享)
  localparam logic [6:0] OPC_READ_UNIQUE          = 7'h07;
  localparam logic [6:0] OPC_READ_NOT_SHARED_DIRTY = 7'h26;

endpackage
