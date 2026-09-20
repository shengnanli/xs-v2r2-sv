// =============================================================================
// xs_indexedLSUopTable_core.sv —— 索引访存「第 N 个 uop 该碰哪个寄存器」查找表
//                                （indexedLSUopTable_1 … _7 共享的参数化核）
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/backend/decode/DecodeUnitComp.scala
//        class indexedLSUopTable(uopIdx:Int) —— 一个 Chisel `decoder(QMCMinimizer…)`
// golden 对照:G1-canonical/golden-rtl/indexedLSUopTable_1.sv … _7.sv
//        （各 103~108 行,0 子模块,0 寄存器;里面是 QMC 最小化后的与或阵列,
//          形如 `|{&{src[0], src[1]}, …}` —— 读不出任何意图,所以这里按**真值表的
//          来源算法**重写,再由 UT 把 16 种输入全部穷举比对。）
//
// ★ 它是什么 ★
// 向量索引访存(vluxei/vloxei/vsuxei/vsoxei)要拆成多个 uop。拆几个、每个 uop 读
// vs2(下标寄存器组)的第几个、写/读 vd(数据寄存器组)的第几个,取决于两个倍数:
//   EMUL —— 下标元素的寄存器组倍数(由下标 EEW 定)
//   LMUL —— 数据元素的寄存器组倍数(由 SEW 定)
// 二者不等时,uop 数 = max(EMUL, LMUL) 个,少的那一侧被多个 uop 共享。
// 本表输入 src = {EMUL[1:0], LMUL[1:0]}(各取 0..3,即倍数 1/2/4/8),
// 输出第 UOP_IDX 个 uop 的 (vs2 偏移, vd 偏移)。
//
// ★ 算法(与 Chisel genCsBundle_VEC_INDEXED_LDST 逐字对应)★
//   若 LMUL < EMUL: uop 数由 EMUL 定 = 1<<EMUL,每 (1<<(EMUL-LMUL)) 个 uop 共享
//                   同一个 vd 寄存器 → (vs2, vd) = (i, i / offset)
//   否则:           uop 数由 LMUL 定 = 1<<LMUL,每 (1<<(LMUL-EMUL)) 个 uop 共享
//                   同一个 vs2 寄存器 → (vs2, vd) = (i / offset, i)
//   若 UOP_IDX 超过该组合的 uop 数,两个偏移都是 0（Chisel 的 for 循环走完不命中,
//   落到函数末尾的 `return (0, 0)`）。
//
// ★ 为什么 uopIdx=0 的那一个变体在 golden 里不存在 ★
// UOP_IDX=0 时所有 16 种组合的输出都是 (0,0) —— firtool 把该实例的输出折成常数后
// 连模块一起删掉了。DecodeUnitComp 里因此只有 7 个实例(_1 … _7),第 0 个 uop 的
// 偏移在父模块里是常数 0。
//
// ★ 实现手法 ★
// 表的内容全是**详细描述期常量**:用 generate-for + localparam 把 16 项算出来,
// 再用 src 做一次数组索引。索引位宽(4)与表项数(16)精确相等 —— 不留任何越界项,
// FM 不做范围传播,`arr[cond ? idx : 0]` 这类写法会让它直接失败。
// =============================================================================

module xs_indexedLSUopTable_core #(
  // 本变体是拆出来的第几个 uop（1..7；0 号见文件头说明）。
  parameter int UOP_IDX = 1
) (
  input  logic [3:0] src,            // {EMUL[1:0], LMUL[1:0]}
  output logic [2:0] out_offset_vs2, // 本 uop 读 vs2 组里的第几个寄存器
  output logic [2:0] out_offset_vd   // 本 uop 写/读 vd 组里的第几个寄存器
);

  // 16 项真值表，全部在详细描述期算好（下面每个 localparam 都只依赖 genvar 与
  // UOP_IDX，没有任何运行期运算 —— 尤其没有运行期除法）。
  logic [2:0] offset_vs2_tab [16];
  logic [2:0] offset_vd_tab  [16];

  generate
    for (genvar s = 0; s < 16; s++) begin : g_entry
      localparam int EMUL = s >> 2;              // src[3:2]
      localparam int LMUL = s & 2'b11;           // src[1:0]
      // 共享倍数：少的那一侧每隔 OFFSET 个 uop 才换一个寄存器。
      localparam int OFFSET  = (LMUL < EMUL) ? (1 << (EMUL - LMUL))
                                             : (1 << (LMUL - EMUL));
      // 本组合一共拆出几个 uop。
      localparam int NUM_UOP = (LMUL < EMUL) ? (1 << EMUL) : (1 << LMUL);
      localparam int OFF_VS2 = (UOP_IDX >= NUM_UOP) ? 0
                             : (LMUL < EMUL) ? UOP_IDX : (UOP_IDX / OFFSET);
      localparam int OFF_VD  = (UOP_IDX >= NUM_UOP) ? 0
                             : (LMUL < EMUL) ? (UOP_IDX / OFFSET) : UOP_IDX;
      assign offset_vs2_tab[s] = 3'(OFF_VS2);
      assign offset_vd_tab[s]  = 3'(OFF_VD);
    end
  endgenerate

  assign out_offset_vs2 = offset_vs2_tab[src];
  assign out_offset_vd  = offset_vd_tab[src];

endmodule : xs_indexedLSUopTable_core
