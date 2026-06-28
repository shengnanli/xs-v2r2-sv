// =============================================================================
//  subdirectory_pkg —— openLLC 目录子块 SubDirectory 的参数与类型
// -----------------------------------------------------------------------------
//  对照 Scala: openLLC/src/main/scala/openLLC/Directory.scala
//    class SubDirectory[T <: Data](sets, ways, tagBits, meta_init_fn,
//                                  meta_valid_fn, invalid_way_sel, replacement)
//  顶层 Directory 例化两个 SubDirectory:
//    - clientDir = SubDirectory[Vec[ClientMetaEntry]] (snoop filter)
//    - selfDir   = SubDirectory[SelfMetaEntry]
//  本文件对应的 golden `SubDirectory`(516 行) 是 clientDir 实例的单态化:
//    sets=1024(setBits=10), ways=10(wayBits=4), tagBits=30,
//    meta = Vec(numRNs=1) of ClientMetaEntry{valid:Bool}  →  仅一个 valid 位/路
//    replacement = "random"  →  用 MaxPeriodFibonacciLFSR 产生替换路, 无 replacer SRAM
//
//  三级流水(见 Scala 注释):
//    stage1: io.read.fire, 发起 Tag/Meta SRAM 读
//    stage2: SRAM 数据回来, 锁存 tagAll_s3 / metaValidVec (用 reqValid_s2 门控)
//    stage3: 算 hit/way, 选出 meta/tag, io.resp.valid=reqValid_s3
//
//  3 个黑盒子模块(在 wrapper 内例化, 核只接其读口/控制口):
//    SRAMTemplate_197  tagArray  (10 路 × 30bit × 1024 set, 单口)
//    SRAMTemplate_198  metaArray (10 路 × 1bit(valid) × 1024 set, 单口)
//    MaxPeriodFibonacciLFSR_3    随机替换的 16 位 Fibonacci LFSR(自由运行, 取低 7 位)
// =============================================================================
package subdirectory_pkg;

  localparam int WAYS     = 10;  // 路数
  localparam int WAY_BITS = 4;   // log2Ceil(10) = 4
  localparam int SETS     = 1024;
  localparam int SET_BITS = 10;
  localparam int TAG_BITS = 30;

  // ClientMetaEntry: 仅含一个 valid 位 (numRNs=1, 故 meta 是 Vec(1))。
  // meta_valid_fn(clients) = Cat(metas.map(_.valid)).orR, 单元素即该 valid。
  typedef struct packed {
    logic valid;
  } client_meta_entry_t;

endpackage
