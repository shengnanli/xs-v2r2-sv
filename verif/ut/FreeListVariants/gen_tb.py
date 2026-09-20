#!/usr/bin/env python3
"""FreeListVariants UT 的 tb 生成器。

为什么生成而不是手写四份：四个变体只在 (SIZE, ALLOC_WIDTH, FREE_WIDTH,
ENABLE_PRE_ALLOC, 有没有 canAllocate/validCount 端口) 这 6 个维度上不同，
激励与比对逻辑逐字相同。手抄四份必然出现"改了三份忘了第四份"。

变体参数**逐个量自 golden**（不是从 Chisel 推的，理由见 Makefile 头注释）：
  · SIZE          = io_free 位宽
  · ALLOC_WIDTH   = golden 里 io_doAllocate_* 端口个数
  · FREE_WIDTH    = golden 里 freeReq_next_nextVec_<b>_r 寄存器个数
  · PRE_ALLOC     = io_allocateSlot_0 是否由 io_allocateSlot_0_r 驱动
  · HAS_CAN/HAS_VC= 端口表里有没有 io_canAllocate_* / io_validCount

用法: python3 gen_tb.py  （就地重写 tb.sv）
      python3 gen_tb.py --check  （只检查 tb.sv 是否与生成结果一致，CI 用）
"""
import sys, os

# name, SIZE, ALLOC, FREE, PRE, HAS_CAN, HAS_VC
VARIANTS = [
    ("FreeList_1", 16, 1, 1, 0, 0, 1),
    ("FreeList_3", 72, 3, 4, 0, 1, 1),
    ("FreeList_4", 32, 3, 4, 1, 1, 1),
    ("FreeList_6", 16, 3, 4, 1, 1, 1),
]


def idxw(size):
    n, w = 1, 0
    while n < size:
        n <<= 1
        w += 1
    return w


def cntw(size):
    return idxw(size + 1)


def emit(v):
    name, SIZE, AW, FW, PRE, HAS_CAN, HAS_VC = v
    p = name.lower()                      # 信号前缀，如 freelist_3
    IW, CW = idxw(SIZE), cntw(SIZE)
    L = []
    a = L.append
    a(f"  // {'='*75}")
    a(f"  // {name}: SIZE={SIZE} ALLOC={AW} FREE={FW} preAlloc={PRE}"
      f"  canAllocate={'有' if HAS_CAN else '无（golden 裁掉）'}"
      f"  validCount={'有' if HAS_VC else '无'}")
    a(f"  // {'='*75}")
    a(f"  localparam int {p.upper()}_SIZE = {SIZE};")
    a(f"  logic [{AW-1}:0]  {p}_do;")
    a(f"  logic [{SIZE-1}:0] {p}_free;")
    for side in ("g", "i"):
        a(f"  logic [{IW-1}:0] {p}_{side}_slot [{AW}];")
        if HAS_CAN:
            a(f"  logic [{AW-1}:0] {p}_{side}_can;")
        if HAS_VC:
            a(f"  logic [{CW-1}:0] {p}_{side}_vc;")
        a(f"  logic        {p}_{side}_empty;")

    for side, mod in (("g", name), ("i", name + "_xs")):
        a(f"  {mod} {p}_{side}_u (")
        a(f"    .clock(clk), .reset(rst),")
        for i in range(AW):
            a(f"    .io_allocateSlot_{i}({p}_{side}_slot[{i}]),")
        if HAS_CAN:
            for i in range(AW):
                a(f"    .io_canAllocate_{i}({p}_{side}_can[{i}]),")
        for i in range(AW):
            a(f"    .io_doAllocate_{i}({p}_do[{i}]),")
        a(f"    .io_free({p}_free),")
        if HAS_VC:
            a(f"    .io_validCount({p}_{side}_vc),")
        a(f"    .io_empty({p}_{side}_empty));")

    # ---- 记账：已取走未释放的槽位 ----
    a(f"  bit [{SIZE-1}:0] {p}_outstanding;")
    a(f"  bit [{SIZE-1}:0] {p}_freeing;")
    a(f"  int {p}_phase, {p}_phaseCnt, {p}_nAlloc;")
    a(f"  int {p}_cov_empty, {p}_cov_full, {p}_cov_hwrap, {p}_cov_twrap,"
      f" {p}_cov_allbank, {p}_cov_maxfree, {p}_cov_dupalloc;")
    a(f"  bit {p}_prev_hflag, {p}_prev_tflag;")
    a("")
    a(f"  always @(posedge clk) begin")
    a(f"    if (rst) {p}_outstanding <= '0;")
    a(f"    else begin")
    for i in range(AW):
        a(f"      if ({p}_do[{i}]) begin")
        a(f"        if ({p}_outstanding[{p}_g_slot[{i}]]) {p}_cov_dupalloc <= {p}_cov_dupalloc + 1;")
        a(f"        {p}_outstanding[{p}_g_slot[{i}]] <= 1'b1;")
        a(f"      end")
    a(f"      for (int k = 0; k < {SIZE}; k++)")
    a(f"        if ({p}_free[k]) {p}_outstanding[k] <= 1'b0;")
    a(f"    end")
    a(f"  end")
    a("")
    # ---- 激励 ----
    if HAS_CAN:
        gate = " || ".join(f"({p}_nAlloc == {i} && {p}_g_can[{i}])" for i in range(AW))
        gate_expr = f"({gate})"
    else:
        # golden 未导出 canAllocate（VStore MergeBuffer 不看它），改用 golden 内部
        # freeSlotCnt 判"池里还有没有"。它与 canAllocate 同源（都来自
        # tailPtr/headPtr 的距离），只是精度差一个"当拍才刚变"的边界。
        gate_expr = f"({p}_g_u.freeSlotCnt > {CW}'({p}_nAlloc))"
    a(f"  always @(negedge clk) begin")
    a(f"    if (rst) begin")
    a(f"      {p}_free = '0; {p}_do = '0;")
    a(f"      {p}_phase <= 0; {p}_phaseCnt <= 0;")
    a(f"    end else begin")
    a(f"      {p}_phaseCnt <= {p}_phaseCnt + 1;")
    a(f"      if ({p}_phaseCnt >= {max(SIZE*2, 60)}) begin")
    a(f"        {p}_phaseCnt <= 0; {p}_phase <= ({p}_phase + 1) % 4;")
    a(f"      end")
    a(f"      {p}_nAlloc = 0;")
    a(f"      while ({p}_nAlloc < {AW} && {gate_expr}) {p}_nAlloc = {p}_nAlloc + 1;")
    a(f"      {p}_freeing = '0;")
    a(f"      case ({p}_phase)")
    a(f"        // 相位 0：只分配不释放 —— 抽到空，逼 headPtr 绕圈")
    a(f"        0: ;")
    a(f"        // 相位 1：一次性全释放 —— io_free 打满，{FW} 个 bank 满负荷")
    a(f"        1: begin {p}_nAlloc = 0; {p}_freeing = {p}_outstanding; end")
    a(f"        // 相位 2：贴边界来回 —— 分配到满，一满就整批放掉一半")
    a(f"        2: begin")
    a(f"          {p}_nAlloc = ({p}_nAlloc > 0) ? $urandom_range(0, {p}_nAlloc) : 0;")
    a(f"          if ({p}_g_u.freeSlotCnt < {CW}'d2)")
    a(f"            for (int k = 0; k < {SIZE}; k += 2)")
    a(f"              if ({p}_outstanding[k]) {p}_freeing[k] = 1'b1;")
    a(f"        end")
    a(f"        // 相位 3：常规随机混合")
    a(f"        default: begin")
    a(f"          {p}_nAlloc = ({p}_nAlloc > 0) ? $urandom_range(0, {p}_nAlloc) : 0;")
    a(f"          for (int k = 0; k < {SIZE}; k++)")
    a(f"            if ({p}_outstanding[k] && ($urandom_range(0,99) < 20))"
      f" {p}_freeing[k] = 1'b1;")
    a(f"        end")
    a(f"      endcase")
    a(f"      // doAllocate 必须是**前缀掩码**：硬件契约是 headPtr 前进 PopCount(doAllocate)")
    a(f"      // 而第 i 口拿的是 freeList[headPtr+i]，跳着占口会让槽位被重复发出。")
    for i in range(AW):
        a(f"      {p}_do[{i}] = ({p}_nAlloc > {i});")
    a(f"      {p}_free = {p}_freeing;")
    a(f"    end")
    a(f"  end")
    a("")
    # ---- 覆盖 ----
    bank_sum = " + ".join(f"{p}_g_u.freeReq_next_nextVec_{b}_r" for b in range(FW))
    a(f"  always @(posedge clk) if (!rst) begin")
    a(f"    int nf, nb;")
    a(f"    if ({p}_g_empty) {p}_cov_empty++;")
    a(f"    if ({p}_g_u.freeSlotCnt == {CW}'d{SIZE}) {p}_cov_full++;")
    a(f"    if ({p}_g_u.headPtr_flag !== {p}_prev_hflag) {p}_cov_hwrap++;")
    a(f"    if ({p}_g_u.tailPtr_flag !== {p}_prev_tflag) {p}_cov_twrap++;")
    a(f"    {p}_prev_hflag <= {p}_g_u.headPtr_flag;")
    a(f"    {p}_prev_tflag <= {p}_g_u.tailPtr_flag;")
    a(f"    nb = {bank_sum};")
    a(f"    if (nb == {FW}) {p}_cov_allbank++;")
    a(f"    nf = $countones({p}_free);")
    a(f"    if (nf > {p}_cov_maxfree) {p}_cov_maxfree <= nf;")
    a(f"  end")
    a("")
    # ---- 比对 ----
    a(f"  always @(negedge clk) if (!rst) begin")
    a(f"    #4; checks++;")
    for i in range(AW):
        a(f"    `CHK(\"{name}.allocateSlot_{i}\", {p}_g_slot[{i}], {p}_i_slot[{i}])")
    if HAS_CAN:
        for i in range(AW):
            a(f"    `CHK(\"{name}.canAllocate_{i}\", {p}_g_can[{i}], {p}_i_can[{i}])")
    if HAS_VC:
        a(f"    `CHK(\"{name}.validCount\", {p}_g_vc, {p}_i_vc)")
    a(f"    `CHK(\"{name}.empty\", {p}_g_empty, {p}_i_empty)")
    a(f"    if (!$isunknown({p}_g_u.headPtr_flag)) begin")
    a(f"      `CHK(\"{name}.headPtr.flag\",  {p}_g_u.headPtr_flag,  {p}_i_u.u_core.headPtr.flag)")
    a(f"      `CHK(\"{name}.headPtr.value\", {p}_g_u.headPtr_value, {p}_i_u.u_core.headPtr.value)")
    a(f"      `CHK(\"{name}.tailPtr.flag\",  {p}_g_u.tailPtr_flag,  {p}_i_u.u_core.tailPtr.flag)")
    a(f"      `CHK(\"{name}.tailPtr.value\", {p}_g_u.tailPtr_value, {p}_i_u.u_core.tailPtr.value)")
    a(f"      `CHK(\"{name}.freeMask\",      {p}_g_u.freeMask,      {p}_i_u.u_core.freeMask)")
    a(f"      `CHK(\"{name}.freeSlotCnt\",   {p}_g_u.freeSlotCnt,   {p}_i_u.u_core.freeSlotCnt)")
    for b in range(FW):
        a(f"      `CHK(\"{name}.freeReq_{b}\", {p}_g_u.freeReq_next_nextVec_{b}_r,"
          f" {p}_i_u.u_core.freeReqReg[{b}])")
        a(f"      `CHK(\"{name}.freeSlotOH_{b}\", {p}_g_u.freeSlotOH_next_nextVec_{b}_r,"
          f" {p}_i_u.u_core.freeSlotOHReg[{b}])")
    for e in (0, SIZE // 2, SIZE - 1):
        a(f"      `CHK(\"{name}.freeList[{e}]\", {p}_g_u.freeList_{e},"
          f" {p}_i_u.u_core.freeList[{e}])")
    a(f"    end")
    a(f"  end")
    a("")
    return "\n".join(L)


def cov_report(v):
    name, SIZE, AW, FW, PRE, HAS_CAN, HAS_VC = v
    p = name.lower()
    return (f'    $display("COV {name}: empty=%0d full=%0d head_wrap=%0d tail_wrap=%0d '
            f'all{FW}banks=%0d max_free_bits=%0d dup_alloc=%0d",\n'
            f'             {p}_cov_empty, {p}_cov_full, {p}_cov_hwrap, {p}_cov_twrap,\n'
            f'             {p}_cov_allbank, {p}_cov_maxfree, {p}_cov_dupalloc);')


def build():
    head = '''// FreeListVariants UT —— FreeList 家族剩余 4 个变体的 golden/重写件双例化逐拍比对
//
// 本目录证的是 FreeList_1 / FreeList_3 / FreeList_4 / FreeList_6 四个单态化变体。
// 基础 FreeList 与 FreeList_5 已各自有 UT 目录（verif/ut/FreeList、verif/ut/FreeList_5）
// 并已出过 receipt —— 一个 golden 顶层只由一个 UT 出 receipt，故此处不重复覆盖它们。
//
// 四个变体共用 rtl/memblock/FreeList.sv 里的同一个参数化核 xs_FreeList_core，
// 差异维度只有 (SIZE, ALLOC_WIDTH, FREE_WIDTH, ENABLE_PRE_ALLOC) 四个参数
// 加两个"golden 裁没裁端口"的事实。tb 由 gen_tb.py 按同一模板生成，
// **改请改生成器**（手改会被下一次跑生成器静默覆盖）。
//
// 激励设计（沿用 verif/ut/FreeList_5/tb.sv 的相位轮转，理由同）：
//   均匀随机会把占用率钉在中段，打不到"满/空"边界，也打不满释放 bank。
//   所以按相位轮转：抽干 -> 一次性全释放 -> 贴边界来回 -> 随机混合。
//   ★doAllocate 必须是前缀掩码★，否则池里会出现重复槽位号、边界覆盖从此丢失。
//   tb 自带 dup_alloc 计数器把这件事变成可观测量：它非 0 就说明激励破了不变式。
//
// ★本文件由 gen_tb.py 生成，勿手改★
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  `define CHK(nm, g, i) \\
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \\
      if (errors <= 80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end

'''
    body = "\n".join(emit(v) for v in VARIANTS)
    tail = '''  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
''' + "\n".join(cov_report(v) for v in VARIANTS) + '''
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
'''
    return head + body + tail


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "tb.sv")
    txt = build()
    if "--check" in sys.argv:
        cur = open(out, encoding="utf-8").read() if os.path.exists(out) else ""
        if cur != txt:
            print("ERROR: tb.sv 与 gen_tb.py 的生成结果不一致（有人手改了 tb.sv？）")
            sys.exit(1)
        print("OK: tb.sv 与生成器一致")
    else:
        open(out, "w", encoding="utf-8").write(txt)
        print("wrote", out)
