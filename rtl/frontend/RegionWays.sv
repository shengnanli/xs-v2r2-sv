// =============================================================================
// RegionWays —— ITTage 的"高位区域"压缩表（16 项全相联，PLRU 替换）
//
// 在 BPU 里的位置：ITTage 预测的是间接跳转的完整目标地址。目标的高位（region，
// 30 位）在程序里重复度极高，于是 ITTage 不在每个表项里存完整 target，而是把
// 高位集中存在这张 16 项小表里，表项只存 4 位"指针"（pointer）+ 低位偏移。
// （Chisel：src/main/scala/xiangshan/frontend/ITTAGE.scala class RegionWays）
//
// 三组口：
//   · 读口 ×5（每张 ITTageTable 一个）：按指针直接读出该项的 valid 与 region。
//   · 更新查找口 ×2：给一个 region，全相联比较，回答"表里有没有"与"在第几项"；
//     若它恰好等于本拍正在写入的 region（write_valid），视为命中，指针取写指针（旁路）。
//   · 写口 ×1：给一个 region，先全相联找：命中就写回那一项（指针不变）；
//     不命中时，表未满取最小下标的空项，表满按 16 路树形 PLRU 选替换项。
//     每次写都把写指针 touch 一次 PLRU。
//
// 复位：16 项 valid/region 与 PLRU 状态都是异步复位清零（RegInit）。
// valid 一旦置位就不再清（只有复位能清），与 golden 一致。
// golden 的 XSError（多重命中）断言在 SYNTHESIS 下不存在，本文件不写。
// =============================================================================
module xs_RegionWays_core #(
  parameter int unsigned NUM_ENTRIES = 16,
  parameter int unsigned REGION_W    = 30,
  parameter int unsigned NUM_READ    = 5,     // = ITTageNTables
  parameter int unsigned NUM_UPDATE  = 2,     // = RegionPorts
  localparam int unsigned PTR_W      = $clog2(NUM_ENTRIES)
)(
  input  logic                clock,
  input  logic                reset,
  input  logic [PTR_W-1:0]    req_pointer    [NUM_READ],
  output logic                resp_hit       [NUM_READ],
  output logic [REGION_W-1:0] resp_region    [NUM_READ],
  input  logic [REGION_W-1:0] update_region  [NUM_UPDATE],
  output logic                update_hit     [NUM_UPDATE],
  output logic [PTR_W-1:0]    update_pointer [NUM_UPDATE],
  input  logic                write_valid,
  input  logic [REGION_W-1:0] write_region,
  output logic [PTR_W-1:0]    write_pointer
);

  typedef struct packed {
    logic                valid;
    logic [REGION_W-1:0] region;
  } region_entry_t;

  region_entry_t regions [NUM_ENTRIES];

  // 独热 -> 下标（OHToUInt：各置位下标按位或；输入保证至多一位为 1）
  function automatic logic [PTR_W-1:0] oh_to_index(input logic [NUM_ENTRIES-1:0] oh);
    logic [PTR_W-1:0] idx;
    idx = '0;
    for (int unsigned i = 0; i < NUM_ENTRIES; i++)
      if (oh[i]) idx |= PTR_W'(i);
    return idx;
  endfunction

  // 全相联比较：哪些有效项的 region 等于 key。
  // ★表内容作为参数显式传入★：函数若直接读模块级的 regions，连续赋值只对实参敏感，
  // 复位清表而 key 不变时仿真不会重算（实测 UT 抓到过一次）。
  function automatic logic [NUM_ENTRIES-1:0] match_vec(input region_entry_t tbl [NUM_ENTRIES],
                                                       input logic [REGION_W-1:0] key);
    logic [NUM_ENTRIES-1:0] m;
    for (int unsigned i = 0; i < NUM_ENTRIES; i++)
      m[i] = tbl[i].valid && (tbl[i].region == key);
    return m;
  endfunction

  // ---------------------------------------------------------------------------
  // §1 写口选项：命中 -> 那一项；未满 -> 最小下标空项；已满 -> PLRU 替换项
  // ---------------------------------------------------------------------------
  logic [NUM_ENTRIES-1:0] valids;
  logic                   all_valid;
  logic [NUM_ENTRIES-1:0] w_hits;
  logic                   w_hit;
  logic [PTR_W-1:0]       first_free;
  logic [PTR_W-1:0]       plru_way;

  always_comb begin
    for (int unsigned i = 0; i < NUM_ENTRIES; i++) valids[i] = regions[i].valid;
  end
  assign all_valid = &valids;
  assign w_hits    = match_vec(regions, write_region);
  assign w_hit     = |w_hits;

  // PriorityEncoder(~valids)：最小下标的空项（表满时此值不被使用）
  always_comb begin
    first_free = PTR_W'(NUM_ENTRIES - 1);
    for (int i = NUM_ENTRIES - 1; i >= 0; i--)
      if (!valids[i]) first_free = PTR_W'(i);
  end

  assign write_pointer = w_hit      ? oh_to_index(w_hits)
                       : !all_valid ? first_free
                       :              plru_way;

  xs_PlruReplacer #(
    .NUM_WAYS (NUM_ENTRIES)
  ) u_replacer (
    .clock       (clock),
    .reset       (reset),
    .touch_valid (write_valid),
    .touch_way   (write_pointer),
    .replace_way (plru_way)
  );

  // ---------------------------------------------------------------------------
  // §2 读口：按指针直读
  // ---------------------------------------------------------------------------
  for (genvar r = 0; r < NUM_READ; r++) begin : g_read
    assign resp_hit[r]    = regions[req_pointer[r]].valid;
    assign resp_region[r] = regions[req_pointer[r]].region;
  end

  // ---------------------------------------------------------------------------
  // §3 更新查找口：全相联命中，或与本拍写入的 region 相同（旁路，指针取写指针）
  // ---------------------------------------------------------------------------
  for (genvar u = 0; u < NUM_UPDATE; u++) begin : g_update
    logic [NUM_ENTRIES-1:0] u_hits;
    logic                   u_bypass;
    assign u_hits            = match_vec(regions, update_region[u]);
    assign u_bypass          = write_valid && (update_region[u] == write_region);
    assign update_hit[u]     = (|u_hits) || u_bypass;
    assign update_pointer[u] = u_bypass ? write_pointer : oh_to_index(u_hits);
  end

  // ---------------------------------------------------------------------------
  // §4 写：写指针那一项置 valid（已有效则保持）并写入 region
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int unsigned i = 0; i < NUM_ENTRIES; i++) regions[i] <= '0;
    end else if (write_valid) begin
      regions[write_pointer].valid  <= 1'b1;
      regions[write_pointer].region <= write_region;
    end
  end

endmodule

module RegionWays(
  input         clock,
  input         reset,
  input  [3:0]  io_req_pointer_0,
  input  [3:0]  io_req_pointer_1,
  input  [3:0]  io_req_pointer_2,
  input  [3:0]  io_req_pointer_3,
  input  [3:0]  io_req_pointer_4,
  output        io_resp_hit_0,
  output        io_resp_hit_1,
  output        io_resp_hit_2,
  output        io_resp_hit_3,
  output        io_resp_hit_4,
  output [29:0] io_resp_region_0,
  output [29:0] io_resp_region_1,
  output [29:0] io_resp_region_2,
  output [29:0] io_resp_region_3,
  output [29:0] io_resp_region_4,
  input  [29:0] io_update_region_0,
  input  [29:0] io_update_region_1,
  output        io_update_hit_0,
  output        io_update_hit_1,
  output [3:0]  io_update_pointer_0,
  output [3:0]  io_update_pointer_1,
  input         io_write_valid,
  input  [29:0] io_write_region,
  output [3:0]  io_write_pointer
);

  logic [3:0]  req_pointer   [5];
  logic        resp_hit      [5];
  logic [29:0] resp_region   [5];
  logic [29:0] update_region [2];
  logic        update_hit    [2];
  logic [3:0]  update_pointer[2];

  assign req_pointer = '{io_req_pointer_0, io_req_pointer_1, io_req_pointer_2,
                         io_req_pointer_3, io_req_pointer_4};
  assign update_region = '{io_update_region_0, io_update_region_1};

  xs_RegionWays_core u_core (
    .clock          (clock),
    .reset          (reset),
    .req_pointer    (req_pointer),
    .resp_hit       (resp_hit),
    .resp_region    (resp_region),
    .update_region  (update_region),
    .update_hit     (update_hit),
    .update_pointer (update_pointer),
    .write_valid    (io_write_valid),
    .write_region   (io_write_region),
    .write_pointer  (io_write_pointer)
  );

  assign {io_resp_hit_0, io_resp_hit_1, io_resp_hit_2, io_resp_hit_3, io_resp_hit_4} =
         {resp_hit[0], resp_hit[1], resp_hit[2], resp_hit[3], resp_hit[4]};
  assign io_resp_region_0    = resp_region[0];
  assign io_resp_region_1    = resp_region[1];
  assign io_resp_region_2    = resp_region[2];
  assign io_resp_region_3    = resp_region[3];
  assign io_resp_region_4    = resp_region[4];
  assign io_update_hit_0     = update_hit[0];
  assign io_update_hit_1     = update_hit[1];
  assign io_update_pointer_0 = update_pointer[0];
  assign io_update_pointer_1 = update_pointer[1];

endmodule
