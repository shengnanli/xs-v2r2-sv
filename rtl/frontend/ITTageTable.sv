// =============================================================================
// xs_ITTageTable_core —— ITTAGE 间接跳转目标预测器的「单条几何历史长度标签表」核
//
// 对应 Chisel: xiangshan.frontend.ITTageTable（ITTage.scala，class ITTageTable）
//
// 【它在前端 BPU 的位置：ITTAGE = "间接跳转版的 TAGE"】
//   普通 TAGE 预测条件分支的「方向(taken/not-taken)」；ITTAGE 则预测**间接跳转的目标
//   地址**（如 jalr、虚函数派发、switch 跳转表），这类跳转同一条指令在不同上下文会跳到
//   不同目标，必须用全局历史区分。ITTAGE 结构与 TAGE 同构：
//     1 个基预测器(ITTageBTable) + N 张带 tag 的标签表(本模块)。N 张表用「几何递增」的
//   全局历史长度各自索引，命中且历史最长的表作 provider 给出目标；都不命中回退基表。
//   本工程 N=5（本核 5 个参数化实例，历史长度 4/8/13/16/32 量级递增，见变体表）。
//
//        s0(req): pc + 折叠历史 ──hash──▶ idx/tag ──▶ 读 SRAM ──┐
//                                                              ▼ s1
//                       tag 比对 → 命中? → 输出 {target_offset, ctr(置信), u(有用位)}
//        commit(update): pc + 原始历史 ──hash──▶ idx/tag ──▶ 改写 目标/ctr/u/tag/valid
//
// 【一条目存什么 / 与方向版 TAGE 的关键区别】
//   每个条目 = {valid, tag(9 位), ctr(2 位置信计数), useful(1 位), target_offset}。
//     - target_offset：本表预测的**跳转目标的压缩编码**（不是绝对地址），三段：
//         offset(20 位) + pointer(4 位) + usePCRegion(1 位)。香山用「区域基址表
//         (region table)+ 区内偏移」压缩 50 位 VAddr：pointer 指向某个区域基址、offset
//         给区内偏移、usePCRegion=1 表示区域基址取当前 PC 所在区。本表只负责**存取**这
//         一编码，解码在 ITTAGE 顶层做。这正是 ITTAGE 与方向版 TAGE 的根本不同：条目存
//         的是「目标」而非「方向位」。
//     - ctr：2 位**置信/替换**计数器（不是方向）。预测正确→朝 3 饱和增、错→朝 0 减；
//         分配新条目置 2(弱)；ctr 越高说明该目标越稳定，外层据此决定信不信本表、以及
//         替换时优先淘汰谁。
//     - useful(u)：有用位，含义同方向版 TAGE——本表作 provider 命中且确实纠正了基表/更
//         短表的错误时置 1；周期性老化清零(reset_u 扫描)防止表被永久占满，给新分配腾位。
//
// 【为什么 ctr=0(oldSatNotTaken) 时连目标一起换：write_new_target】
//   更新时若 (alloc) 或 (ctr 已饱和到 0，即旧目标屡屡预测错)，则把条目里的 target_offset
//   换成本次 commit 的新目标(io_update_target_offset_*)；否则保留旧目标
//   (io_update_old_target_offset_*)。即「置信度已耗尽的旧目标才允许被新目标顶替」，
//   避免一次偶发 misprediction 就冲掉一个总体准确的目标。
//
// 【折叠历史索引/tag（FoldedHistory）——与方向版 TAGE 同一技巧】
//   用「最长 N 拍全局历史」索引一张行数有限的表，直接取低位会丢信息。折叠历史把 HIST_LEN
//   位历史按目标宽度 L 切成 ceil(HIST_LEN/L) 个 chunk 逐块异或，压成 L 位，既保留全部历史
//   影响又恰好填满索引/tag 宽度。本核需三份折叠历史：
//     - idx 折叠历史(宽 IDX_W)：与 pc[IDX_W:1] 异或得到行索引 idx。
//     - tag 折叠历史(宽 TAG_W=9)：参与 tag。
//     - alt 折叠历史(宽 ALT_W)：左移 1 位再参与 tag（让 tag 更分散，降低别名）。
//   读路径(req) 直接吃外层算好的折叠历史端口（io_req_idx_fh / tag_fh / alt_fh）；
//   更新路径(update) 只拿到「原始全局历史 io_update_ghist」，需在本核内用 fold_hist() 现折。
//   两者算法一致（外层有 GHistDiff 断言保证读路径折叠历史与现折结果相等）。
//     idx = pc[IDX_W:1] ^ idx_fh
//     tag = pc[TAG_W+9-1 : 10 或对应位] ^ tag_fh ^ (alt_fh << 1)     （pc 取位随 IDX_W 变）
//
// 【单口 SRAM / useful 老化扫描 / 上电复位】
//   条目存一张单口 FoldedSRAMTemplate（读写同口），故：
//     - 读使能 = (~powerOnReset & io_req_valid)；上电后 SRAM 首次 ready 前拉低 io_req_ready
//       挡住 BPU 流水（单口 SRAM 的 r_ready := !wen，不能直接当 req_ready，需单独锁存）。
//     - useful 老化：needReset 置位后，在「没有读、也没有正常更新」的空闲拍逐行把 useful
//       清 0（resetSet 计数器扫全表）；扫完(resetSet 全 1)自动清 needReset。
//     - 读写同拍冲突(read_write_conflict)：req 与 update 同拍命中同口，则该次读出作废
//       (s1_read_write_conflict 打一拍后清 io_resp_valid)。
//
// 【写旁路 WrBypass：消除连续更新同行的写后读冒险】
//   ctr 存在单口 SRAM 里，写后要下一拍才能读回。连续 commit 同一行时若每次都用
//   io_update_oldCtr（更早预测快照）会丢掉刚写进去的增量。故配一个 WrBypass 小缓存暂存最近
//   写过的 ctr，更新取 old_ctr 时优先用命中值，未命中才退回 io_update_oldCtr。
//
// 【分层：核 vs wrapper —— 为什么 SRAM/WrBypass/MBIST 在 wrapper 例化】
//   5 个变体不仅参数不同，所用 SRAM(FoldedSRAMTemplate_21/_23)、WrBypass(_41/_43)、
//   MBIST(MbistPipeIttage/_1.._4) 的**模块名也不同**（firtool 单态化命名）。SystemVerilog
//   无法按参数选模块名，故本核把这三类子模块的端口**全部引出**，由 golden 同名 wrapper
//   按变体例化正确命名的黑盒并对接。核因此只含「纯功能逻辑」，最易读；wrapper 是机械适配层。
//
// 【参数化 5 变体】见文件末与 docs/frontend/ITTageTable.md 变体表。核参数化
//   IDX_W / 三份折叠历史宽度 / 三段历史长度（更新现折用），其余完全相同。
// =============================================================================
module xs_ITTageTable_core #(
  parameter int unsigned IDX_W        = 8,   // SRAM 行地址位宽（var0/1=8→256 行, var2-4=9→512 行）
  parameter int unsigned TAG_W        = 9,   // tag 位宽（所有变体均为 9）
  parameter int unsigned CTR_W        = 2,   // 置信计数器位宽
  parameter int unsigned PC_W         = 50,  // 取指 PC 位宽 (VAddrBits)
  parameter int unsigned GHIST_W      = 256, // 原始全局历史位宽（更新现折用）
  // 读侧折叠历史输入位宽（由外层折叠几何决定，见变体表）
  parameter int unsigned IDX_FH_W     = 4,   // idx 折叠历史宽（= min(IDX_HIST_LEN, IDX_W)）
  parameter int unsigned TAG_FH_W     = 4,   // tag 折叠历史宽（= min(TAG_HIST_LEN, TAG_W)）
  parameter int unsigned ALT_FH_W     = 4,   // alt 折叠历史宽（= min(ALT_HIST_LEN, TAG_W-1)）
  // 更新路径现折用的三段历史长度（与读侧折叠几何一致）
  parameter int unsigned IDX_HIST_LEN = 4,
  parameter int unsigned TAG_HIST_LEN = 4,
  parameter int unsigned ALT_HIST_LEN = 4,
  // 目标编码各段宽度
  parameter int unsigned OFF_W        = 20,  // target_offset.offset
  parameter int unsigned PTR_W        = 4,   // target_offset.pointer
  // 派生
  parameter int unsigned ALT_TGT_W    = TAG_W - 1  // alt 折叠历史参与 tag 前的有效宽
)(
  input  logic                clock,
  input  logic                reset,

  // ---- 预测请求 (s0) ----
  output logic                io_req_ready,
  input  logic                io_req_valid,
  input  logic [PC_W-1:0]     io_req_bits_pc,
  input  logic [IDX_FH_W-1:0] io_req_idx_fh,   // idx 折叠历史
  input  logic [TAG_FH_W-1:0] io_req_tag_fh,   // tag 折叠历史
  input  logic [ALT_FH_W-1:0] io_req_alt_fh,   // alt tag 折叠历史

  // ---- 预测响应 (s1) ----
  output logic                io_resp_valid,
  output logic [CTR_W-1:0]    io_resp_bits_ctr,
  output logic                io_resp_bits_u,
  output logic [OFF_W-1:0]    io_resp_bits_target_offset_offset,
  output logic [PTR_W-1:0]    io_resp_bits_target_offset_pointer,
  output logic                io_resp_bits_target_offset_usePCRegion,

  // ---- 更新 (commit) ----
  input  logic [PC_W-1:0]     io_update_pc,
  input  logic [GHIST_W-1:0]  io_update_ghist,
  input  logic                io_update_valid,
  input  logic                io_update_correct,    // 本次 commit：旧目标是否猜对
  input  logic                io_update_alloc,      // 是否分配新条目
  input  logic [CTR_W-1:0]    io_update_oldCtr,     // 预测时快照的旧 ctr（WrBypass 未命中时用）
  input  logic                io_update_uValid,     // 本次是否更新 useful 位
  input  logic                io_update_u,          // 新的 useful 值
  input  logic                io_update_reset_u,    // 请求启动 useful 老化扫描
  input  logic [OFF_W-1:0]    io_update_target_offset_offset,       // 本次 commit 的新目标
  input  logic [PTR_W-1:0]    io_update_target_offset_pointer,
  input  logic                io_update_target_offset_usePCRegion,
  input  logic [OFF_W-1:0]    io_update_old_target_offset_offset,   // 条目里的旧目标（保留用）
  input  logic [PTR_W-1:0]    io_update_old_target_offset_pointer,
  input  logic                io_update_old_target_offset_usePCRegion,

  // ===========================================================================
  // 与 wrapper 内变体专属子模块对接的端口（核不直接例化 SRAM/WrBypass/MBIST）
  // ===========================================================================
  // ---- 条目 SRAM (FoldedSRAMTemplate_21/_23 黑盒) 读口 ----
  output logic                sram_r_req_valid,
  output logic [IDX_W-1:0]    sram_r_req_setIdx,
  input  logic                sram_r_req_ready,
  input  logic                sram_r_resp_valid,
  input  logic [TAG_W-1:0]    sram_r_resp_tag,
  input  logic [CTR_W-1:0]    sram_r_resp_ctr,
  input  logic [OFF_W-1:0]    sram_r_resp_target_offset_offset,
  input  logic [PTR_W-1:0]    sram_r_resp_target_offset_pointer,
  input  logic                sram_r_resp_target_offset_usePCRegion,
  input  logic                sram_r_resp_useful,
  // ---- 条目 SRAM 写口 ----
  output logic                sram_w_req_valid,
  output logic [IDX_W-1:0]    sram_w_req_setIdx,
  output logic [TAG_W-1:0]    sram_w_req_tag,
  output logic [CTR_W-1:0]    sram_w_req_ctr,
  output logic [OFF_W-1:0]    sram_w_req_target_offset_offset,
  output logic [PTR_W-1:0]    sram_w_req_target_offset_pointer,
  output logic                sram_w_req_target_offset_usePCRegion,
  output logic                sram_w_req_useful,
  output logic [37:0]         sram_w_req_bitmask,   // 38 位列写掩码（见 build_bitmask）

  // ---- WrBypass (WrBypass_41/_43 黑盒) ----
  output logic                wrbp_wen,
  output logic [IDX_W-1:0]    wrbp_write_idx,
  output logic [CTR_W-1:0]    wrbp_write_data,
  input  logic                wrbp_hit,
  input  logic [CTR_W-1:0]    wrbp_hit_data
);

  // ===========================================================================
  // 上电复位：所有 SRAM 首次 ready 前拉低 io_req_ready，挡住 BPU 流水
  // ===========================================================================
  logic power_on_reset;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      power_on_reset <= 1'b1;
    else
      // 单口 SRAM ready 拉高后清除上电态（与 golden powerOnResetState 同语义）
      power_on_reset <= ~sram_r_req_ready & power_on_reset;
  end
  assign io_req_ready = ~power_on_reset;

  // 读使能：上电完成且本拍有请求
  wire read_fire = ~power_on_reset & io_req_valid;

  // ===========================================================================
  // S0：读请求 hash —— 由 pc + 折叠历史算出行索引 idx / 校验 tag
  //   idx = pc[IDX_W:1] ^ idx_fh（idx_fh 只覆盖低 IDX_FH_W 位）
  //   tag = pc[TAG_W+? : ?] ^ tag_fh ^ (alt_fh<<1)，pc 取位与 IDX_W 对齐
  //   注：pc 用于 idx 的位段是 [IDX_W:1]，用于 tag 的位段紧接 idx 之上 [IDX_W+TAG_W:IDX_W+1]。
  // ===========================================================================
  wire [IDX_W-1:0] req_pc_idx = io_req_bits_pc[IDX_W:1];
  wire [TAG_W-1:0] req_pc_tag = io_req_bits_pc[IDX_W+TAG_W : IDX_W+1];

  wire [IDX_W-1:0] read_idx =
      req_pc_idx ^ {{(IDX_W-IDX_FH_W){1'b0}}, io_req_idx_fh};

  // tag = pc_tag ^ tag_fh ^ (alt_fh<<1)（各折叠历史零扩展到 TAG_W）
  wire [TAG_W-1:0] read_tag =
      req_pc_tag
    ^ {{(TAG_W-TAG_FH_W){1'b0}}, io_req_tag_fh}
    ^ ({{(TAG_W-ALT_FH_W){1'b0}}, io_req_alt_fh} << 1);

  assign sram_r_req_valid = read_fire;
  assign sram_r_req_setIdx = read_idx;

  // ===========================================================================
  // 折叠历史现折（更新路径用）：把 GHIST 按目标宽度 L 分块异或压成 IDX_W 位载体
  //   nChunks = ceil(HIST_LEN / L)，第 i 块 = ghist[min((i+1)L,HIST_LEN)-1 : i*L]。
  //   读路径折叠历史由外层提供（io_req_*_fh），二者算法一致。
  // ===========================================================================
  // 折叠累加器位宽：取 idx/tag 较大者（var0/1 IDX_W=8 < TAG_W=9，tag 折叠需 9 位载体）
  localparam int unsigned FOLD_W = (IDX_W > TAG_W) ? IDX_W : TAG_W;

  function automatic logic [FOLD_W-1:0] fold_hist(
      input logic [GHIST_W-1:0] gh, input int unsigned hist_len, input int unsigned L);
    logic [FOLD_W-1:0] acc;
    int unsigned hi;
    acc = '0;
    for (int unsigned i = 0; i*L < hist_len; i++) begin
      logic [FOLD_W-1:0] chunk;
      chunk = '0;
      hi = ((i+1)*L < hist_len) ? ((i+1)*L) : hist_len;   // 本块上界(不含)
      for (int unsigned b = i*L; b < hi; b++)
        chunk[b - i*L] = gh[b];
      acc = acc ^ chunk;
    end
    return acc;
  endfunction

  // ===========================================================================
  // Update 路径 hash —— 更新拿原始 ghist，需现折
  // ===========================================================================
  wire [IDX_W-1:0] upd_pc_idx = io_update_pc[IDX_W:1];
  wire [TAG_W-1:0] upd_pc_tag = io_update_pc[IDX_W+TAG_W : IDX_W+1];

  wire [FOLD_W-1:0] upd_idx_fh = fold_hist(io_update_ghist, IDX_HIST_LEN, IDX_W);
  wire [FOLD_W-1:0] upd_tag_fh = fold_hist(io_update_ghist, TAG_HIST_LEN, TAG_W);
  wire [FOLD_W-1:0] upd_alt_fh = fold_hist(io_update_ghist, ALT_HIST_LEN, ALT_TGT_W);

  wire [IDX_W-1:0] update_idx = upd_pc_idx ^ upd_idx_fh[IDX_W-1:0];
  wire [TAG_W-1:0] update_tag =
      upd_pc_tag
    ^ upd_tag_fh[TAG_W-1:0]
    ^ (upd_alt_fh[ALT_TGT_W-1:0] << 1);

  // ===========================================================================
  // 置信计数器 ctr 更新（2 位）。注意 ITTAGE 的 ctr 是「置信/替换」计数：
  //   alloc → 置弱态 2；旧值已饱和到 3 且本次又对 → 保持 3；旧值已到 0 且本次又错 → 保持 0；
  //   否则 对→+1 / 错→-1。这与方向版的「方向饱和」形式相同，但语义是置信度。
  // ===========================================================================
  // 旧 ctr：优先 WrBypass 命中值，未命中退回 io_update_oldCtr
  wire [CTR_W-1:0] old_ctr = wrbp_hit ? wrbp_hit_data : io_update_oldCtr;
  wire old_sat_not_taken = (old_ctr == '0);   // 旧 ctr 已饱和到 0（旧目标屡错）

  function automatic logic [CTR_W-1:0] ctr_update(
      input logic [CTR_W-1:0] c, input logic alloc, input logic correct);
    logic sat0;
    sat0 = (c == '0);
    if (alloc)                  ctr_update = CTR_W'(1 << (CTR_W-1)); // 弱态 = 10b = 2
    else if ((&c) & correct)    ctr_update = '1;                    // 已满且对 → 保持 3
    else if (sat0 & ~correct)   ctr_update = '0;                    // 已空且错 → 保持 0
    else if (correct)           ctr_update = c + 1'b1;
    else                        ctr_update = c - 1'b1;
  endfunction

  wire [CTR_W-1:0] update_wdata_ctr = ctr_update(old_ctr, io_update_alloc, io_update_correct);

  // 目标是否换新：分配，或旧目标置信已耗尽(ctr=0)；否则保留旧目标
  wire write_new_target = io_update_alloc | old_sat_not_taken;

  // ===========================================================================
  // useful 位老化扫描（reset_u）
  //   needReset 置位后，在「无读请求 且 无正常更新」的空闲拍逐行扫描清 useful。
  //   resetSet 是扫描行计数器；扫满(全 1)时本拍清掉 needReset。
  // ===========================================================================
  logic               needReset;
  logic [IDX_W-1:0]   resetSet;
  wire useful_can_reset = ~(read_fire | io_update_valid) & needReset;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      needReset <= 1'b0;
      resetSet  <= '0;
    end else begin
      // 收到 reset_u 请求则置位；扫满后自动清；其余保持
      needReset <= io_update_reset_u | (~(useful_can_reset & (&resetSet)) & needReset);
      if (useful_can_reset)
        resetSet <= resetSet + 1'b1;
    end
  end

  // ===========================================================================
  // SRAM 写：正常 commit 写一行 或 老化扫描清一行
  //   - setIdx：扫描时用 resetSet，否则用 update_idx
  //   - 写数据：tag/ctr/目标按上面算；useful = 扫描时强制 0，否则 io_update_u
  //   - bitmask(38 位)：FoldedSRAMTemplate 的列写掩码（条目按列展开）。三种场景：
  //       同时写 useful：全 1 (0x3FFFFFFFFF)
  //       仅写条目主体不动 useful：低位清 0 (0x3FFFFFFFFE)
  //       老化扫描：只写 useful 那一列 ({37'h0, useful_can_reset})
  // ===========================================================================
  assign sram_w_req_valid  = io_update_valid | useful_can_reset;
  assign sram_w_req_setIdx = useful_can_reset ? resetSet : update_idx;
  assign sram_w_req_tag    = update_tag;
  assign sram_w_req_ctr    = update_wdata_ctr;
  assign sram_w_req_useful = ~useful_can_reset & io_update_u;

  assign sram_w_req_target_offset_offset =
      write_new_target ? io_update_target_offset_offset
                       : io_update_old_target_offset_offset;
  assign sram_w_req_target_offset_pointer =
      write_new_target ? io_update_target_offset_pointer
                       : io_update_old_target_offset_pointer;
  assign sram_w_req_target_offset_usePCRegion =
      write_new_target ? io_update_target_offset_usePCRegion
                       : io_update_old_target_offset_usePCRegion;

  // 列写掩码（与 golden 三态等价）
  always_comb begin
    if (io_update_uValid & io_update_valid)
      sram_w_req_bitmask = 38'h3FFFFFFFFF;       // 写全部列（含 useful 列）
    else if (io_update_valid)
      sram_w_req_bitmask = 38'h3FFFFFFFFE;       // 写条目主体，保留 useful 列
    else
      sram_w_req_bitmask = {37'h0, useful_can_reset}; // 仅 useful 列（老化扫描）
  end

  // ===========================================================================
  // WrBypass：缓存最近写过该行的新 ctr。io_wen 用 io_update_valid（与 golden 一致，
  //   不依赖会随上电态变 X 的信号，避免 X 经写使能传播污染）。
  // ===========================================================================
  assign wrbp_wen        = io_update_valid;
  assign wrbp_write_idx  = update_idx;
  assign wrbp_write_data = update_wdata_ctr;

  // ===========================================================================
  // S1 流水寄存：tag、valid、读写冲突标志随请求推进一拍
  //   read_write_conflict：req 与 update 同拍（命中同口）→ s1 读出作废。
  // ===========================================================================
  logic [TAG_W-1:0] s1_tag;
  logic             s1_valid;
  logic             s1_read_write_conflict;
  wire read_write_conflict_probe = io_update_valid & io_req_valid;

  always_ff @(posedge clock) begin
    if (read_fire)
      s1_tag <= read_tag;
    s1_valid <= io_req_valid;
    if (io_req_valid)
      s1_read_write_conflict <= read_write_conflict_probe;
  end

  // ===========================================================================
  // S1 响应合成：命中 = SRAM 读出 valid & tag 匹配 & 未发生读写冲突 & 本拍确有请求
  //   目标/ctr/u 直通 SRAM 读出（命中时外层才采信）。
  // ===========================================================================
  assign io_resp_valid =
      sram_r_resp_valid
    & (sram_r_resp_tag == s1_tag)
    & ~s1_read_write_conflict
    & s1_valid;

  assign io_resp_bits_ctr                       = sram_r_resp_ctr;
  assign io_resp_bits_u                         = sram_r_resp_useful;
  assign io_resp_bits_target_offset_offset      = sram_r_resp_target_offset_offset;
  assign io_resp_bits_target_offset_pointer     = sram_r_resp_target_offset_pointer;
  assign io_resp_bits_target_offset_usePCRegion = sram_r_resp_target_offset_usePCRegion;

endmodule


// =============================================================================
// xs_MbistPipeIttage_core —— ITTageTable 的 MBIST 流水寄存器（DFT 链路）
//
//   对应 golden MbistPipeIttage / _1 / _2 / _3 / _4。纯 DFT 基础设施，与分支预测功能
//   无关：测试模式下把 BPU 顶层广播的 mbist 总线一拍寄存后转发给本表 SRAM 的 bore 口，
//   并把 SRAM 读回数据送回 mbist 总线。只在被本表 array ID 选中或 "all" 广播时(doSpread)
//   才真正驱动 SRAM；否则 SRAM 侧地址/读写使能保持 0，避免误触发。
//
//   两类拓扑（参数 N_SRAM）：
//     - N_SRAM=1（var0/1，SRAM=FoldedSRAMTemplate_21 单 bore 口）：一个 array ID(ARRAY_ID0)。
//     - N_SRAM=2（var2/3/4，SRAM=FoldedSRAMTemplate_23 双 bore 口）：两个相邻 array ID
//       (ARRAY_ID0, ARRAY_ID0+1)，各自独立 selected/doSpread；mbist_outdata = 两口或合。
//   array ID：var0=0x46 var1=0x47 var2=0x48/49 var3=0x4A/4B var4=0x4C/4D。
// =============================================================================
module xs_MbistPipeIttage_core #(
  parameter int unsigned N_SRAM    = 1,
  parameter logic [6:0]  ARRAY_ID0 = 7'h46,
  parameter int unsigned ADDR_W    = 8,
  parameter int unsigned DATA_W    = 76
)(
  input  logic              clock,
  input  logic              reset,
  // ---- 上游 mbist 总线 ----
  input  logic [6:0]        mbist_array,
  input  logic              mbist_all,
  input  logic              mbist_req,
  output logic              mbist_ack,
  input  logic              mbist_writeen,
  input  logic [DATA_W-1:0] mbist_be,
  input  logic [ADDR_W-1:0] mbist_addr,
  input  logic [DATA_W-1:0] mbist_indata,
  input  logic              mbist_readen,
  input  logic [ADDR_W-1:0] mbist_addr_rd,
  output logic [DATA_W-1:0] mbist_outdata,
  // ---- 下游到各 SRAM bore 口（N_SRAM 个，打平为数组）----
  output logic [ADDR_W-1:0] toSRAM_addr        [N_SRAM],
  output logic [ADDR_W-1:0] toSRAM_addr_rd     [N_SRAM],
  output logic [DATA_W-1:0] toSRAM_wdata       [N_SRAM],
  output logic [DATA_W-1:0] toSRAM_wmask       [N_SRAM],
  output logic              toSRAM_re          [N_SRAM],
  output logic              toSRAM_we          [N_SRAM],
  input  logic [DATA_W-1:0] toSRAM_rdata       [N_SRAM],
  output logic              toSRAM_ack         [N_SRAM],
  output logic              toSRAM_selectedOH  [N_SRAM],
  output logic [6:0]        toSRAM_array       [N_SRAM]
);
  // 一拍寄存的 mbist 控制/数据
  logic [6:0]        array_q;
  logic              req_q, all_q, wen_q, ren_q;
  logic [DATA_W-1:0] be_q, data_in_q;
  logic [ADDR_W-1:0] addr_q, addr_rd_q;

  // 各 SRAM 口对应的 array ID = ARRAY_ID0 + 口序号
  function automatic logic [6:0] array_id(input int unsigned k); return ARRAY_ID0 + 7'(k); endfunction

  // 本拍是否激活（命中本 pipe 管辖的任一 array ID 或全局广播）→ 决定是否锁存上游总线
  logic activated;
  always_comb begin
    activated = mbist_all;
    for (int unsigned k = 0; k < N_SRAM; k++)
      activated |= (mbist_req & (mbist_array == array_id(k)));
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      array_q   <= 7'h0;
      req_q     <= 1'b0;
      all_q     <= 1'b0;
      wen_q     <= 1'b0;
      ren_q     <= 1'b0;
      be_q      <= '0;
      addr_q    <= '0;
      data_in_q <= '0;
      addr_rd_q <= '0;
    end else begin
      if (activated) begin
        array_q <= mbist_array;
        all_q   <= mbist_all;
        wen_q   <= mbist_writeen;
        ren_q   <= mbist_readen;
      end
      req_q <= mbist_req;
      if (activated & (mbist_readen | mbist_writeen)) begin
        be_q      <= mbist_be;
        addr_q    <= mbist_addr;
        data_in_q <= mbist_indata;
        addr_rd_q <= mbist_addr_rd;
      end
    end
  end

  assign mbist_ack = req_q;

  // 每口：selected = 寄存的 array 命中该口 ID；doSpread = selected | all
  logic [DATA_W-1:0] sram_data_out [N_SRAM];
  always_comb begin
    for (int unsigned k = 0; k < N_SRAM; k++) begin
      logic selected, do_spread;
      selected  = (array_q == array_id(k));
      do_spread = selected | all_q;
      sram_data_out[k]     = selected ? toSRAM_rdata[k] : '0;
      toSRAM_addr[k]       = do_spread ? addr_q    : '0;
      toSRAM_addr_rd[k]    = do_spread ? addr_rd_q : '0;
      toSRAM_wdata[k]      = data_in_q;
      toSRAM_wmask[k]      = be_q;
      toSRAM_re[k]         = do_spread & ren_q;
      toSRAM_we[k]         = do_spread & wen_q;
      toSRAM_ack[k]        = req_q;
      toSRAM_selectedOH[k] = all_q | ~req_q | selected;
      toSRAM_array[k]      = array_q;
    end
  end

  // mbist_outdata = 各口选中数据的或合（同时最多一口 selected）
  always_comb begin
    mbist_outdata = '0;
    for (int unsigned k = 0; k < N_SRAM; k++)
      mbist_outdata |= sram_data_out[k];
  end
endmodule
