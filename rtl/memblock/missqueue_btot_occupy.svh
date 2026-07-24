// =============================================================================
//  missqueue_btot_occupy.svh —— BtoT 占用集合检查（被 xs_MissQueue_core 内联）
// -----------------------------------------------------------------------------
//  BtoT（权限升级到 Trunk）请求会「占住」某 set 的某 way。MainPipe 替换前查询某 set 已被
//  多少 way 占住：
//    · btot_ways_for_set：对 io_evict_set，把所有「isBtoT & req_vaddr.valid & set==evict_set」
//      的 entry（外加 pipereg）的 occupy_way 按 OR 合并 → 该 set 被 BtoT 占的 way 位图。
//    · occupy_fail[k]（3 路 load）：对 io_occupy_set_k 同样算 occupy_ways，若占用 way 数
//      > nWays-2(=2) 则 fail（该 set 没有足够空闲 way 给 BtoT，需阻塞）。
//  set = vaddr[13:6]（addr_to_dcache_set）。
//  ⚠ 坑：「读模块级数组的纯函数」放在连续赋值里，只在其显式实参变化时才重算（VCS 不把函数
//  体内读的模块信号纳入敏感表）。故这里用 always_comb（自动敏感于体内所有读），不用 function。
// =============================================================================

// popcount(4bit)：占用 way 数
function automatic logic [2:0] pcnt4(input logic [3:0] v);
  return 3'(v[0]) + 3'(v[1]) + 3'(v[2]) + 3'(v[3]);
endfunction

// 对 4 个查询 set（evict + occupy0/1/2）各算占用 way 位图（entry + pipereg OR 合并）。
// pipereg 的 set（vaddr[13:6]）无条件求值（不放进 if 分支——否则 FM 前端把只在分支内赋值的
// 局部量 ps 推成一个只写不读的组合临时寄存器 ps_reg[7:0]，成为 impl-only 死位）。
wire [7:0]  pr_set = mqpr.vaddr[13:6];
wire        pr_occ_en = mqpr_reg_valid & mqpr.isBtoT;
logic [3:0] occ_ways_evict, occ_ways_0, occ_ways_1, occ_ways_2;
always_comb begin
  occ_ways_evict = '0; occ_ways_0 = '0; occ_ways_1 = '0; occ_ways_2 = '0;
  for (int i = 0; i < N_ENTRY; i++) begin
    automatic logic en = e_req_isBtoT[i] & e_req_vaddr_valid[i];
    automatic logic [7:0] s = e_req_vaddr[i][13:6];
    if (en & (s == io_evict_set))    occ_ways_evict |= e_occupy_way[i];
    if (en & (s == io_occupy_set_0)) occ_ways_0     |= e_occupy_way[i];
    if (en & (s == io_occupy_set_1)) occ_ways_1     |= e_occupy_way[i];
    if (en & (s == io_occupy_set_2)) occ_ways_2     |= e_occupy_way[i];
  end
  // pipereg 贡献：evict_set_match = reg_valid & isBtoT & set==qset
  if (pr_occ_en & (pr_set == io_evict_set))    occ_ways_evict |= mqpr.occupy_way;
  if (pr_occ_en & (pr_set == io_occupy_set_0)) occ_ways_0     |= mqpr.occupy_way;
  if (pr_occ_en & (pr_set == io_occupy_set_1)) occ_ways_1     |= mqpr.occupy_way;
  if (pr_occ_en & (pr_set == io_occupy_set_2)) occ_ways_2     |= mqpr.occupy_way;
end

assign io_btot_ways_for_set = occ_ways_evict;
assign io_occupy_fail_0 = pcnt4(occ_ways_0) > 3'h2;
assign io_occupy_fail_1 = pcnt4(occ_ways_1) > 3'h2;
assign io_occupy_fail_2 = pcnt4(occ_ways_2) > 3'h2;
