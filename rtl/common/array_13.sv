// array_13.sv —— L2 预取 RecentRequestTable 存储（256 项 × 13 位，单口读写）的宏包装层
//
// 结构位置：RecentRequestTable → SRAMTemplate_146 → sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt
//           → **array_13** → array_13_ext（SRAM 编译器行为叶子，verif/vendor_boundary.tsv 已审定）
//
// 本层没有任何逻辑：端口逐位直连厂商叶子 array_13_ext。它存在只是因为 firtool 给每个 SRAM
// 宏生成一层"array_N"命名壳；保留同名同端口，是为了让 FM 两侧在同一位置看到同一个 vendor
// 边界（两侧都只把精确的 array_13_ext 当黑盒，本层两侧都白盒受验）。
//
// codex 0219 §2：final RTL 不再依赖 golden 的这层包装文件，impl 侧读本文件，ref 侧仍读 G1。
// 端口名、方向、位宽与 golden array_13 完全一致。

module array_13 (
  input  logic [7:0]  RW0_addr,    // 行地址（256 项）
  input  logic        RW0_en,      // 本拍访问使能
  input  logic        RW0_clk,     // 存储时钟
  input  logic        RW0_wmode,   // 1 = 写，0 = 读（上一层已与 RW0_en 相与）
  input  logic [12:0] RW0_wdata,   // 写数据
  output logic [12:0] RW0_rdata    // 读数据（时序由叶子决定）
);

  array_13_ext array_13_ext (
    .RW0_addr  (RW0_addr),
    .RW0_en    (RW0_en),
    .RW0_clk   (RW0_clk),
    .RW0_wmode (RW0_wmode),
    .RW0_wdata (RW0_wdata),
    .RW0_rdata (RW0_rdata)
  );

endmodule
