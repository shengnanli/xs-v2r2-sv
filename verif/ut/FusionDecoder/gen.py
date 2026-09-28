#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— FusionDecoder UT 的 tb.sv 生成器（RTL 本身是手写的，不在这里生成）。

为什么用生成器：tb 要逐拍比对 84 根输出线、并从 golden 内部 140 个展平寄存器
（fusionVec_k / fusionVec_i_k）里统计「每对 × 每种模式」的命中，这两块是纯机械
展开，手抄注定漏。激励部分（28 种模式的定向构造）也在这里，但它是按模式表写的，
表本身就是文档。

用法：
    python3 gen.py            # 生成 tb.sv（幂等）
    python3 gen.py --check    # 与库里的 tb.sv 不一致则非零退出
"""
import pathlib, sys

HERE = pathlib.Path(__file__).resolve().parent
N_IN, N_PAIR, N_CASE = 6, 5, 28

# (名字, 第一条模板, 第二条模板)。模板里的字段在 tb 里按 (rd, rs1b, rs2b) 现填：
#   第一条只需要 rd（其 rs1 随机）；第二条的 rd 与 rs1/rs2 按「同 rd / rd->rs1 / rd->rs2」策略填。
# 每条写成 (opcode 位模板函数名, 参数) —— 这里直接给 32 位常量骨架 + 说明，字段由 tb 的 mk_* 函数填。
CASES = [
 ("ADDUW",      "slli", 32, "srli", 32),
 ("ZEXTH",      "slli", 48, "srli", 48),
 ("ZEXTH1",     "slliw",16, "srliw",16),
 ("SEXTH",      "slliw",16, "sraiw",16),
 ("SH1ADD",     "slli", 1,  "add",  0),
 ("SH2ADD",     "slli", 2,  "add",  0),
 ("SH3ADD",     "slli", 3,  "add",  0),
 ("SZEWL1",     "slli", 32, "srli", 31),
 ("SZEWL2",     "slli", 32, "srli", 30),
 ("SZEWL3",     "slli", 32, "srli", 29),
 ("BYTE2",      "srli", 8,  "andi", 255),
 ("SH4ADD",     "slli", 4,  "add",  0),
 ("SR29ADD",    "srli", 29, "add",  0),
 ("SR30ADD",    "srli", 30, "add",  0),
 ("SR31ADD",    "srli", 31, "add",  0),
 ("SR32ADD",    "srli", 32, "add",  0),
 ("ODDADD",     "andi", 1,  "add",  0),
 ("ODDADDW",    "andi", 1,  "addw", 0),
 ("ORH48",      "andi", 0xF00, "or", 0),
 ("MULW7",      "andi", 127, "mulw", 0),
 ("ADDWBYTE",   "addw_or_addiw", 0, "andi", 255),
 ("ADDWBIT",    "addw_or_addiw", 0, "andi", 1),
 ("ADDWZEXTH",  "addw_or_addiw", 0, "zexth", 0),
 ("ADDWSEXTH",  "addw_or_addiw", 0, "sexth", 0),
 ("LOGICLSB",   "logic", 0, "andi", 1),
 ("LOGICZEXTH", "logic", 0, "zexth", 0),
 ("LUI32",      "lui",  0,  "addi", 0),
 ("LUI32W",     "lui",  0,  "addiw",0),
]
assert len(CASES) == N_CASE

OUT_FIELDS = [("valid",1),("bits_fuType_valid",1),("bits_fuOpType_valid",1),("bits_fuOpType_bits",9),
              ("bits_lsrc2_valid",1),("bits_lsrc2_bits",6),("bits_src2Type_valid",1),
              ("bits_selImm_valid",1),("bits_selImm_bits",4)]
INFO_FIELDS = ["rs2FromRs1","rs2FromRs2","rs2FromZero"]

def gold_fv(i, k):
    return f"u_gold.fusionVec_{k}" if i == 0 else f"u_gold.fusionVec_{i}_{k}"

def gen():
    L = []
    A = L.append
    A("// =============================================================================")
    A("// FusionDecoder UT —— golden FusionDecoder 对重写 FusionDecoder_xs 双例化，同激励逐拍比对")
    A("// 全部 84 根输出线（5 对 × 9 个替换字段 + 5 × 3 个 info + 5 个 clear）。")
    A("// 本文件由 gen.py 生成，不要手改（改 gen.py 再重跑）。")
    A("//")
    A("// ★判别力在「模式 × 寄存器关系 × 相邻对位置」★")
    A("//   28 种模式每种都要在 5 个对位置上各命中；每种模式还要打到 rd 关系的各种分支：")
    A("//   同 rd / rd->rs1(b) / rd->rs2(b) / rs1(b)==rs2(b)（R 型不融合）/ rd=0（HINT 不融合）/")
    A("//   近似模式（移位量差 1、opcode 差一位）。覆盖统计从 golden 内部 fusionVec 寄存器取。")
    A("// ★无复位寄存器★ fusionVec/notHint/enabled/... 都无复位；+vcs+initreg+random 下两例化初值")
    A("//   不同，所以暖机 WARMUP 拍里全 valid、全 ready 让 5 对都 fire 一次把它们写定，之后开比。")
    A("// =============================================================================")
    A("`timescale 1ns/1ps")
    A("module tb;")
    A("  int unsigned NCYCLES = 200000;")
    A("  localparam int WARMUP = 32;")
    A("  localparam int N_IN = 6, N_PAIR = 5;")
    A("  bit clk = 0; logic rst; int errors = 0; longint checks = 0;")
    A("  always #5 clk = ~clk;")
    A("")
    A("  logic        io_disableFusion;")
    for i in range(N_IN):
        A(f"  logic        io_in_{i}_valid;")
        A(f"  logic [31:0] io_in_{i}_bits;")
    for i in range(N_PAIR):
        A(f"  logic        io_inReady_{i};")
        A(f"  logic [8:0]  io_dec_{i}_fuOpType;")
    for side in ("g","x"):
        for i in range(N_PAIR):
            for f,w in OUT_FIELDS:
                A(f"  logic [{w-1}:0] {side}_out_{i}_{f};")
            for f in INFO_FIELDS:
                A(f"  logic {side}_info_{i}_{f};")
        for i in range(1,N_IN):
            A(f"  logic {side}_clear_{i};")
    A("")
    for side, mod, inst in (("g","FusionDecoder","u_gold"),("x","FusionDecoder_xs","u_xs")):
        A(f"  {mod} {inst} (")
        A("    .clock(clk), .reset(rst), .io_disableFusion(io_disableFusion),")
        for i in range(N_IN):
            A(f"    .io_in_{i}_valid(io_in_{i}_valid), .io_in_{i}_bits(io_in_{i}_bits),")
        for i in range(N_PAIR):
            A(f"    .io_inReady_{i}(io_inReady_{i}), .io_dec_{i}_fuOpType(io_dec_{i}_fuOpType),")
        for i in range(N_PAIR):
            A("    " + " ".join(f".io_out_{i}_{f}({side}_out_{i}_{f})," for f,w in OUT_FIELDS))
        for i in range(N_PAIR):
            A("    " + " ".join(f".io_info_{i}_{f}({side}_info_{i}_{f})," for f in INFO_FIELDS))
        A("    " + ", ".join(f".io_clear_{i}({side}_clear_{i})" for i in range(1,N_IN)))
        A("  );")
        A("")
    # ---- instruction builders ----
    A("  // ---- 指令构造（RV64I/M/Zba/Zbb 编码）----")
    A("  function automatic logic [31:0] mk_i(input logic [11:0] imm, input logic [4:0] rs1, input logic [2:0] f3, input logic [4:0] rd, input logic [6:0] op);")
    A("    return {imm, rs1, f3, rd, op};")
    A("  endfunction")
    A("  function automatic logic [31:0] mk_r(input logic [6:0] f7, input logic [4:0] rs2, input logic [4:0] rs1, input logic [2:0] f3, input logic [4:0] rd, input logic [6:0] op);")
    A("    return {f7, rs2, rs1, f3, rd, op};")
    A("  endfunction")
    A("  // 第一条：kind 按 CASES 表；rd 给定，rs1 随机")
    A("  function automatic logic [31:0] mk_first(input int kind, input int imm, input logic [4:0] rd);")
    A("    logic [4:0] rs1 = 5'($urandom);")
    A("    logic [2:0] pick = 3'($urandom_range(0, 6));")
    A("    case (kind)")
    A("      0: return mk_i({6'b000000, 6'(imm)}, rs1, 3'b001, rd, 7'h13);           // slli")
    A("      1: return mk_i({6'b000000, 6'(imm)}, rs1, 3'b101, rd, 7'h13);           // srli")
    A("      2: return mk_i({7'b0000000, 5'(imm)}, rs1, 3'b001, rd, 7'h1B);          // slliw")
    A("      3: return mk_i(12'(imm), rs1, 3'b111, rd, 7'h13);                       // andi")
    A("      4: return $urandom_range(0,1) ? mk_i(12'($urandom), rs1, 3'b000, rd, 7'h1B)   // addiw")
    A("                                    : mk_r(7'b0, 5'($urandom), rs1, 3'b000, rd, 7'h3B); // addw")
    A("      5: case (pick)                                                          // logic 7 选 1")
    A("           0: return mk_i(12'($urandom), rs1, 3'b111, rd, 7'h13);            // andi")
    A("           1: return mk_r(7'b0, 5'($urandom), rs1, 3'b111, rd, 7'h33);       // and")
    A("           2: return mk_i(12'($urandom), rs1, 3'b110, rd, 7'h13);            // ori")
    A("           3: return mk_r(7'b0, 5'($urandom), rs1, 3'b110, rd, 7'h33);       // or")
    A("           4: return mk_i(12'($urandom), rs1, 3'b100, rd, 7'h13);            // xori")
    A("           5: return mk_r(7'b0, 5'($urandom), rs1, 3'b100, rd, 7'h33);       // xor")
    A("           default: return mk_i(12'h287, rs1, 3'b101, rd, 7'h13);            // orc.b")
    A("         endcase")
    A("      default: return {20'($urandom), rd, 7'h37};                            // lui")
    A("    endcase")
    A("  endfunction")
    A("  // 第二条：kind 按 CASES 表；rd/rs1/rs2 给定")
    A("  function automatic logic [31:0] mk_second(input int kind, input int imm, input logic [4:0] rd, input logic [4:0] rs1, input logic [4:0] rs2);")
    A("    case (kind)")
    A("      0: return mk_i({6'b000000, 6'(imm)}, rs1, 3'b101, rd, 7'h13);           // srli")
    A("      1: return mk_i({7'b0000000, 5'(imm)}, rs1, 3'b101, rd, 7'h1B);          // srliw")
    A("      2: return mk_i({7'b0100000, 5'(imm)}, rs1, 3'b101, rd, 7'h1B);          // sraiw")
    A("      3: return mk_r(7'b0, rs2, rs1, 3'b000, rd, 7'h33);                      // add")
    A("      4: return mk_r(7'b0, rs2, rs1, 3'b000, rd, 7'h3B);                      // addw")
    A("      5: return mk_r(7'b0, rs2, rs1, 3'b110, rd, 7'h33);                      // or")
    A("      6: return mk_r(7'b0000001, rs2, rs1, 3'b000, rd, 7'h3B);                // mulw")
    A("      7: return mk_i(12'(imm), rs1, 3'b111, rd, 7'h13);                       // andi")
    A("      8: return mk_i(12'h080, rs1, 3'b100, rd, 7'h3B);                        // zext.h")
    A("      9: return mk_i(12'h605, rs1, 3'b001, rd, 7'h13);                        // sext.h")
    A("      10: return mk_i(12'($urandom), rs1, 3'b000, rd, 7'h13);                 // addi")
    A("      default: return mk_i(12'($urandom), rs1, 3'b000, rd, 7'h1B);            // addiw")
    A("    endcase")
    A("  endfunction")
    # kind maps
    K1 = {"slli":0,"srli":1,"slliw":2,"andi":3,"addw_or_addiw":4,"logic":5,"lui":6}
    K2 = {"srli":0,"srliw":1,"sraiw":2,"add":3,"addw":4,"or":5,"mulw":6,"andi":7,"zexth":8,"sexth":9,"addi":10,"addiw":11}
    A("  // CASES 表：第一条 kind/imm，第二条 kind/imm")
    A(f"  localparam int NCASE = {N_CASE};")
    A("  int k1[NCASE], im1[NCASE], k2[NCASE], im2[NCASE];")
    A("  string cname[NCASE];")
    A("  initial begin")
    for idx,(nm,a,ia,b,ib) in enumerate(CASES):
        A(f"    k1[{idx}] = {K1[a]}; im1[{idx}] = {ia}; k2[{idx}] = {K2[b]}; im2[{idx}] = {ib}; cname[{idx}] = \"{nm}\";")
    A("  end")
    A("")
    A("  // 构造一对：mode 决定 rd 关系；返回两条指令")
    A("  task automatic mk_pair(input int c, output logic [31:0] a, output logic [31:0] b);")
    A("    logic [4:0] rd, rs1, rs2; int rel;")
    A("    rd  = ($urandom_range(0, 9) == 0) ? 5'h0 : 5'($urandom);   // 10% rd=0（HINT）")
    A("    rel = $urandom_range(0, 9);")
    A("    // 0-3: rd->rs1(b)  4-6: rd->rs2(b)  7: rs1==rs2==rd  8: 两个都不是 rd  9: 第二条 rd 不同")
    A("    case (rel)")
    A("      0,1,2,3: begin rs1 = rd; rs2 = 5'($urandom); if (rs2 == rd) rs2 = rd + 5'd1; end")
    A("      4,5,6:   begin rs2 = rd; rs1 = 5'($urandom); if (rs1 == rd) rs1 = rd + 5'd1; end")
    A("      7:       begin rs1 = rd; rs2 = rd; end")
    A("      default: begin rs1 = 5'($urandom); rs2 = 5'($urandom); end")
    A("    endcase")
    A("    a = mk_first(k1[c], im1[c], rd);")
    A("    b = mk_second(k2[c], im2[c], (rel == 9) ? rd ^ 5'h1 : rd, rs1, rs2);")
    A("    // 近似模式：15% 把某一位翻掉（移位量/funct/opcode），验证「差一点就不融合」")
    A("    if ($urandom_range(0, 99) < 15) begin")
    A("      if ($urandom_range(0, 1)) a[$urandom_range(12, 31)] ^= 1'b1; else b[$urandom_range(12, 31)] ^= 1'b1;")
    A("    end")
    A("  endtask")
    A("")
    A("  logic [31:0] instr [N_IN];")
    A("  longint cov_case[5][NCASE]; longint cov_out_valid[5]; longint cov_clear_chain = 0; longint cov_disabled_fire = 0;")
    A("  longint cov_rel_rs1 = 0, cov_rel_rs2 = 0, cov_rel_zero = 0;")
    A("")
    A("  task automatic drive_inputs(input bit warm);")
    A("    int c, pos; logic [31:0] a, b;")
    A("    for (int i = 0; i < N_IN; i++) instr[i] = $urandom;")
    A("    // 每拍最多放两对定向模式（相邻/重叠时正好测 clear 链）")
    A("    repeat ($urandom_range(0, 2)) begin")
    A("      c = $urandom_range(0, NCASE - 1); pos = $urandom_range(0, N_PAIR - 1);")
    A("      mk_pair(c, a, b); instr[pos] = a; instr[pos + 1] = b;")
    A("    end")
    for i in range(N_IN):
        A(f"    io_in_{i}_bits  = instr[{i}];")
        A(f"    io_in_{i}_valid = warm ? 1'b1 : ($urandom_range(0, 9) < 8);")
    for i in range(N_PAIR):
        A(f"    io_inReady_{i}    = warm ? 1'b1 : ($urandom_range(0, 9) < 7);")
        A(f"    io_dec_{i}_fuOpType = 9'($urandom);")
    A("    io_disableFusion = warm ? 1'b0 : ($urandom_range(0, 19) == 0);")
    A("  endtask")
    A("")
    A("  task automatic compare_outputs();")
    A("    checks++;")
    for i in range(N_PAIR):
        for f,w in OUT_FIELDS:
            A(f"    if (g_out_{i}_{f} !== x_out_{i}_{f}) begin errors++; if (errors < 20) $display(\"MISMATCH @%0t out_{i}_{f} g=%h x=%h\", $time, g_out_{i}_{f}, x_out_{i}_{f}); end")
        for f in INFO_FIELDS:
            A(f"    if (g_info_{i}_{f} !== x_info_{i}_{f}) begin errors++; if (errors < 20) $display(\"MISMATCH @%0t info_{i}_{f} g=%b x=%b\", $time, g_info_{i}_{f}, x_info_{i}_{f}); end")
    for i in range(1,N_IN):
        A(f"    if (g_clear_{i} !== x_clear_{i}) begin errors++; if (errors < 20) $display(\"MISMATCH @%0t clear_{i} g=%b x=%b\", $time, g_clear_{i}, x_clear_{i}); end")
    A("  endtask")
    A("")
    A("  // 覆盖：从 golden 内部展平寄存器取（独立于被测件）")
    A("  task automatic collect_cov();")
    for i in range(N_PAIR):
        for k in range(N_CASE):
            A(f"    if ({gold_fv(i,k)} === 1'b1) cov_case[{i}][{k}]++;")
        A(f"    if (g_out_{i}_valid === 1'b1) cov_out_valid[{i}]++;")
        A(f"    if (g_info_{i}_rs2FromRs1 === 1'b1) cov_rel_rs1++;")
        A(f"    if (g_info_{i}_rs2FromRs2 === 1'b1) cov_rel_rs2++;")
        A(f"    if (g_info_{i}_rs2FromZero === 1'b1) cov_rel_zero++;")
    A("    // clear 链真正生效：上一对 clear 拉高、本对本来也匹配（golden 的 conflict_fusion 事件）")
    for i in range(1,N_PAIR):
        ors = " | ".join(gold_fv(i,k) for k in range(N_CASE))
        A(f"    if (g_clear_{i} === 1'b1 && u_gold.instrPairValid_{i} === 1'b1 && (({ors}) === 1'b1)) cov_clear_chain++;")
    A("    if (io_disableFusion === 1'b1 && (io_in_0_valid & io_inReady_0)) cov_disabled_fire++;")
    A("  endtask")
    A("")
    A("  initial begin")
    A("    if (!$value$plusargs(\"ncycles=%d\", NCYCLES)) NCYCLES = 200000;")
    A("    for (int i = 0; i < N_PAIR; i++) begin cov_out_valid[i] = 0; for (int k = 0; k < NCASE; k++) cov_case[i][k] = 0; end")
    A("    rst = 1'b1; drive_inputs(1'b1);")
    A("    repeat (4) @(negedge clk);")
    A("    rst = 1'b0;")
    A("    for (longint c = 0; c < NCYCLES; c++) begin")
    A("      // 运行中多次异步复位（每 ~8000 拍 2 拍），复位期间照常打激励并比对")
    A("      rst = ((c % 8192) < 2) && (c > WARMUP);")
    A("      drive_inputs(c < WARMUP);")
    A("      #1;")
    A("      if (c >= WARMUP) begin compare_outputs(); collect_cov(); end")
    A("      @(negedge clk);")
    A("    end")
    A("    $display(\"=== COVERAGE (FusionDecoder) ===\");")
    A("    $display(\"  checks=%0d  rs2FromRs1=%0d rs2FromRs2=%0d rs2FromZero=%0d clear_chain=%0d disabled_fire=%0d\", checks, cov_rel_rs1, cov_rel_rs2, cov_rel_zero, cov_clear_chain, cov_disabled_fire);")
    A("    begin")
    A("      int zero = 0; longint minhit = -1;")
    A("      for (int i = 0; i < N_PAIR; i++) begin")
    A("        $display(\"  pair %0d: out_valid=%0d\", i, cov_out_valid[i]);")
    A("        for (int k = 0; k < NCASE; k++) begin")
    A("          if (cov_case[i][k] == 0) begin zero++; $display(\"  ZERO-HIT pair %0d case %s\", i, cname[k]); end")
    A("          if (minhit < 0 || cov_case[i][k] < minhit) minhit = cov_case[i][k];")
    A("        end")
    A("      end")
    A("      $display(\"  5x28 (pair,case) 未命中 %0d 个，最少命中 %0d\", zero, minhit);")
    A("      if (zero != 0) begin $display(\"COVERAGE INSUFFICIENT\"); errors++; end")
    A("      if (cov_rel_rs1 == 0 || cov_rel_rs2 == 0 || cov_rel_zero == 0 || cov_clear_chain == 0 || cov_disabled_fire == 0) begin")
    A("        $display(\"COVERAGE INSUFFICIENT: rs1/rs2/zero/clear链/disableFusion 有一项没打到\"); errors++;")
    A("      end")
    A("    end")
    A("    if (errors == 0) $display(\"TEST PASSED (checks=%0d)\", checks);")
    A("    else             $display(\"TEST FAILED errors=%0d (checks=%0d)\", errors, checks);")
    A("    $finish;")
    A("  end")
    A("endmodule")
    return "\n".join(L) + "\n"

def main():
    txt = gen()
    dst = HERE / "tb.sv"
    if "--check" in sys.argv:
        if not dst.exists() or dst.read_text() != txt:
            print("DRIFT: tb.sv 与 gen.py 现在会生成的不一致"); return 1
        print("OK: tb.sv 幂等"); return 0
    if not dst.exists() or dst.read_text() != txt:
        dst.write_text(txt); print("wrote", dst)
    else:
        print("unchanged", dst)
    return 0

if __name__ == "__main__":
    sys.exit(main())
