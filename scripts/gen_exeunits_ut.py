#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_exeunits_ut.py —— exeunits lane 的双例化 UT testbench 生成器。

## 生成什么

`verif/ut/<UT>/tb.sv`：golden `<Top>` 与重写 `<Top>_xs`（derive_ut_impl.py 改名后的 wrapper）
双例化，**每拍比较全部输出口**（`!==`，X 也算失配）。端口表从 G1 golden 顶层机械解析，
不手抄；每个目标只手写三样东西（本文件 TARGETS 里）：

  * stim  —— 激励约束：先把所有输入随机一遍，再按目标语义覆盖（合法 fuType / opType 池、
             valid/ready/flush 的概率、暖机期的特殊驱动等）；
  * cov   —— 覆盖计数：在每拍比较之后按 golden 侧观测累计；
  * req   —— PASS 判据里的覆盖门槛（任一不满足即 TEST FAILED）。

## 时序约定（所有目标一致）

  negedge：给新激励 → #4：比较全部输出（下一个 posedge 之前）→ 计覆盖。
  前 5 拍拉复位，之后每拍以 1/RESET_ODDS 的概率偶发复位。前 WARM 拍不比较（暖机：
  两侧不复位的寄存器在第一次被写之前读出来本就各是各的随机初值，那不是 RTL 差异）。

## 用法

  python3 scripts/gen_exeunits_ut.py            # 写全部 tb.sv
  python3 scripts/gen_exeunits_ut.py --check    # 只比对不写；有漂移 rc=1（gate 自动扫描）
"""
import argparse
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')

PORT_RE = re.compile(r'^\s*(input|output)\s+(\[[^\]]+\])?\s*(\w+)\s*,?\s*$')


def parse_ports(top):
    """解析 golden 顶层端口表 -> [(dir, width, name)]；fail-closed：解析不到任何端口即退出。"""
    text = (GOLDEN / f'{top}.sv').read_text()
    m = re.search(r'^module\s+' + re.escape(top) + r'\s*\((.*?)\);', text, re.S | re.M)
    if not m:
        sys.exit(f'ERROR: golden {top}.sv 里找不到 module {top}')
    ports = []
    for ln in m.group(1).splitlines():
        if not ln.strip():
            continue
        pm = PORT_RE.match(ln)
        if not pm:
            sys.exit(f'ERROR: {top} 端口行无法解析: {ln!r}')
        ports.append((pm.group(1), pm.group(2) or '', pm.group(3)))
    if not ports:
        sys.exit(f'ERROR: {top} 无端口')
    return ports


def rand_expr(width):
    """给定 '[hi:0]' 生成随机值表达式。"""
    if not width:
        return "1'($urandom)"
    hi = int(re.match(r'\[(\d+):0\]', width).group(1))
    n = hi + 1
    words = (n + 31) // 32
    if words == 1:
        return f"{n}'($urandom)"
    return f"{n}'({{" + ', '.join(['$urandom()'] * words) + "})"


# =============================================================================
#  每个目标的激励 / 覆盖 / 判据
# =============================================================================
# 共用片段：从一个值池里按概率抽，否则全随机
VSET_POOL = "'{9'h0A0, 9'h0A1, 9'h060, 9'h061, 9'h020, 9'h062, 9'h0A2, 9'h072}"

TARGETS = {}

TARGETS['VSetRiWvf'] = dict(
    ut='VSetRiWvf', top='VSetRiWvf', warm=2,
    decl="""
  // 覆盖计数
  longint c_vl0 = 0, c_vlmax = 0, c_vtype_wr = 0, c_illegal = 0, c_legal = 0, c_avl_mid = 0;
  logic [8:0] vset_pool [8] = """ + VSET_POOL + """;
""",
    stim="""
    // fuOpType：85% 取本 FU 真会收到的 vset uop 编码（含两个不归它管的 keep 码），15% 全随机
    if ($urandom_range(0, 99) < 85) io_in_bits_ctrl_fuOpType = vset_pool[$urandom_range(0, 7)];
    // src1 低 11 位是 vtype 立即数 / VtypeStruct：70% 给合法 vsew(0..3) 与 vlmul(!=4)、reserved=0
    if ($urandom_range(0, 99) < 70) begin
      io_in_bits_data_src_1[5:3] = 3'($urandom_range(0, 3));
      io_in_bits_data_src_1[2:0] = 3'($urandom_range(0, 7));
      if (io_in_bits_data_src_1[2:0] == 3'b100) io_in_bits_data_src_1[2:0] = 3'b000;
      io_in_bits_data_src_1[63:8] = {41'h0, 5'($urandom), 10'h0};   // 只留 uimm5 [14:10]
      if ($urandom_range(0, 9) == 0) io_in_bits_data_src_1[63] = 1'b1; // vill
    end
    // AVL（src0）：60% 落在 0..40（覆盖 vl<VLMAX / =VLMAX / >VLMAX 三种）
    if ($urandom_range(0, 99) < 60) io_in_bits_data_src_0 = 64'($urandom_range(0, 40));
""",
    cov="""
    if (io_in_valid) begin
      if (g_io_vlIsZero) c_vl0++;
      if (g_io_vlIsVlmax) c_vlmax++;
      if (g_io_vtype_valid) c_vtype_wr++;
      if (g_io_vtype_bits_illegal) c_illegal++; else c_legal++;
      if (!g_io_vlIsZero && !g_io_vlIsVlmax) c_avl_mid++;
    end
""",
    report='"cov vl0=%0d vlmax=%0d vtype_wr=%0d illegal=%0d legal=%0d avl_mid=%0d", '
           'c_vl0, c_vlmax, c_vtype_wr, c_illegal, c_legal, c_avl_mid',
    req=['c_vl0 > 1000', 'c_vlmax > 1000', 'c_vtype_wr > 1000', 'c_illegal > 1000',
         'c_legal > 1000', 'c_avl_mid > 1000'],
)

TARGETS['IntFPToVec'] = dict(
    ut='IntFPToVec', top='IntFPToVec', warm=2,
    decl="""
  longint c_fli_h = 0, c_fli_s = 0, c_fli_d = 0, c_dup_nan = 0, c_dup_ok = 0, c_fmv = 0, c_imm = 0, c_plain = 0;
""",
    stim="""
    // opType：40% fli（[7]=1，[6:5] 取 h/s/d 三种合法码 + 偶尔非法 11），60% 非 fli（[7:5]=0，
    //   [4:2] 走 IF2VectorType 的 6 个码，[1:0]=vsew 全取）；另 10% 全随机已由默认随机覆盖
    if ($urandom_range(0, 9) != 0) begin
      if ($urandom_range(0, 99) < 40) begin
        io_in_bits_ctrl_fuOpType[8:5] = {2'b01, 2'($urandom_range(0, 3))};
        if (io_in_bits_ctrl_fuOpType[6:5] == 2'b11 && $urandom_range(0, 3) != 0)
          io_in_bits_ctrl_fuOpType[6:5] = 2'b00;
      end else begin
        io_in_bits_ctrl_fuOpType[8:5] = 4'b0000;
        io_in_bits_ctrl_fuOpType[4:2] = 3'($urandom_range(0, 5)) + ((io_in_bits_ctrl_fuOpType[4] ? 3'd1 : 3'd0));
      end
    end
    // 浮点源：50% 给某一宽度的合法 NaN-box（高位全 1），其余随机（触发规范 NaN 替换）
    case ($urandom_range(0, 5))
      0: io_in_bits_data_src_0[63:8]  = '1;
      1: io_in_bits_data_src_0[63:16] = '1;
      2: io_in_bits_data_src_0[63:32] = '1;
      default: ;
    endcase
""",
    cov="""
    begin
      logic [8:0] op;
      bit fli;
      op = io_in_bits_ctrl_fuOpType;
      fli = op[7] && op[6:5] != 2'b11;
      if (op[7] && op[6:5] == 2'b10) c_fli_h++;
      if (op[7] && op[6:5] == 2'b00) c_fli_s++;
      if (op[7] && op[6:5] == 2'b01) c_fli_d++;
      if (!fli && op[4] && op[2]) begin
        if (g_io_out_bits_res_data[7:0] == 8'h78 || g_io_out_bits_res_data[15:0] == 16'h7E00
            || g_io_out_bits_res_data[31:0] == 32'h7FC00000) c_dup_nan++; else c_dup_ok++;
      end
      if (!fli && !op[4] && op[2]) c_fmv++;
      if (!fli && op[3]) c_imm++;
      if (!fli && !op[4] && !op[2]) c_plain++;
    end
""",
    report='"cov fli h/s/d=%0d/%0d/%0d dup_nan=%0d dup_ok=%0d fmv=%0d imm=%0d plain=%0d", '
           'c_fli_h, c_fli_s, c_fli_d, c_dup_nan, c_dup_ok, c_fmv, c_imm, c_plain',
    req=['c_fli_h > 1000', 'c_fli_s > 1000', 'c_fli_d > 1000', 'c_dup_nan > 1000', 'c_dup_ok > 1000',
         'c_fmv > 1000', 'c_imm > 1000', 'c_plain > 1000'],
)

# FPCVT 的宽度译码（{opType[4:3], sew} -> input1H / output1H），由 golden FPCVT.sv 的 PLA 逐项求值得到
CVT_W1H_FN = """
  function automatic logic [7:0] fpcvt_w1h(logic [1:0] w, logic [1:0] sew);   // {in1H, out1H}
    case ({w, sew})
      4'b00_01: return 8'b0010_0010;  4'b00_10: return 8'b0100_0100;  4'b00_11: return 8'b1000_1000;
      4'b01_00: return 8'b0001_0010;  4'b01_01: return 8'b0010_0100;  4'b01_10: return 8'b0100_1000;
      4'b10_00: return 8'b0010_0001;  4'b10_01: return 8'b0100_0010;  4'b10_10: return 8'b1000_0100;
      4'b11_01: return 8'b0010_1000;  4'b11_11: return 8'b1000_0010;
      default:  return 8'b0000_0000;
    endcase
  endfunction
  // 浮点源定向值池（按宽度放在低位）：0 / ±inf / qNaN / sNaN / 最小非规格化 / 1.0 / 最大有限
  function automatic logic [63:0] fp_pick(int w);
    logic [63:0] v;
    int k;
    k = $urandom_range(0, 9);
    v = {$urandom(), $urandom()};
    case (w)
      16: case (k) 0: v[15:0] = 16'h0000; 1: v[15:0] = 16'h7C00; 2: v[15:0] = 16'hFC00; 3: v[15:0] = 16'h7E00;
                   4: v[15:0] = 16'h7D00; 5: v[15:0] = 16'h0001; 6: v[15:0] = 16'h3C00; 7: v[15:0] = 16'h7BFF;
                   default: ; endcase
      32: case (k) 0: v[31:0] = 32'h0; 1: v[31:0] = 32'h7F800000; 2: v[31:0] = 32'hFF800000;
                   3: v[31:0] = 32'h7FC00000; 4: v[31:0] = 32'h7FA00000; 5: v[31:0] = 32'h1;
                   6: v[31:0] = 32'h3F800000; 7: v[31:0] = 32'h7F7FFFFF; default: ; endcase
      default: case (k) 0: v = 64'h0; 1: v = 64'h7FF0000000000000; 2: v = 64'hFFF0000000000000;
                   3: v = 64'h7FF8000000000000; 4: v = 64'h7FF4000000000000; 5: v = 64'h1;
                   6: v = 64'h3FF0000000000000; 7: v = 64'h7FEFFFFFFFFFFFFF; default: ; endcase
    endcase
    return v;
  endfunction
"""

TARGETS['CVT64'] = dict(
    ut='CVT64', top='CVT64', warm=10,
    decl=CVT_W1H_FN + """
  // 标量 FCVT 会送进来的 opType（fcvt_pkg 注释里的编码）：f2i / i2f / f2f / fround / fcvtmod
  logic [7:0] cvt_pool [26] = '{8'h80, 8'h81, 8'h86, 8'h87, 8'h88, 8'h89, 8'h8E, 8'h8F, 8'h90, 8'h91,
                                8'h98, 8'h99, 8'h42, 8'h43, 8'h4A, 8'h4B, 8'h52, 8'h53, 8'hC8, 8'hD0,
                                8'hD4, 8'hD8, 8'hC0, 8'hC4, 8'h96, 8'h97};
  longint c_cnan_i = 0, c_cnan_f = 0, c_cnan_fround = 0, c_f2i = 0, c_i2f = 0, c_f2f = 0, c_fround = 0, c_fcvtmod = 0;
""",
    stim="""
    if ($urandom_range(0, 99) < 90) begin
      logic [1:0] sew;
      logic [7:0] w1h;
      int iw;
      io_opType = cvt_pool[$urandom_range(0, 25)];
      sew = 2'($urandom_range(0, 3));
      w1h = fpcvt_w1h(io_opType[4:3], sew);
      if ($urandom_range(0, 99) < 90) {io_input1H, io_output1H} = w1h;
      io_isFround  = (io_opType == 8'hC0) ? 2'b01 : (io_opType == 8'hC4) ? 2'b10 : 2'b00;
      io_isFcvtmod = (io_opType == 8'h91) && $urandom_range(0, 1);
      if ($urandom_range(0, 19) == 0) io_isFround = 2'($urandom);
      if ($urandom_range(0, 3) != 0) io_rm = 3'($urandom_range(0, 4));
      iw = io_input1H[1] ? 16 : io_input1H[2] ? 32 : 64;
      if (io_opType[7]) begin
        io_src = fp_pick(iw);
        // 一半给合法 NaN-box（高位全 1），一半留随机高位（触发规范 NaN 通路）
        if ($urandom_range(0, 1)) begin
          if (iw == 16) io_src[63:16] = '1;
          if (iw == 32) io_src[63:32] = '1;
        end
      end
    end
    // 暖机：复位撤销后连发有效请求，把两级不复位的寄存器写成确定值再开始比
    io_fire = ($urandom_range(0, 9) < 7) || (cyc < WARM);
""",
    cov="""
    if (io_fire) begin
      bit cnan;
      cnan = io_opType[7] && ((io_input1H[1] && io_src[63:16] != '1) || (io_input1H[2] && io_src[63:32] != '1));
      if (cnan && !io_opType[6]) c_cnan_i++;
      if (cnan &&  io_opType[6]) c_cnan_f++;
      if (cnan && |io_isFround) c_cnan_fround++;
      if (io_opType[7] && !io_opType[6]) c_f2i++;
      if (!io_opType[7]) c_i2f++;
      if (io_opType[7] && io_opType[6]) c_f2f++;
      if (|io_isFround) c_fround++;
      if (io_isFcvtmod) c_fcvtmod++;
    end
""",
    report='"cov cnan int/fp/fround=%0d/%0d/%0d f2i=%0d i2f=%0d f2f=%0d fround=%0d fcvtmod=%0d", '
           'c_cnan_i, c_cnan_f, c_cnan_fround, c_f2i, c_i2f, c_f2f, c_fround, c_fcvtmod',
    req=['c_cnan_i > 1000', 'c_cnan_f > 1000', 'c_cnan_fround > 500', 'c_f2i > 1000', 'c_i2f > 1000',
         'c_f2f > 1000', 'c_fround > 1000', 'c_fcvtmod > 500'],
)

TARGETS['IntToFP_3'] = dict(
    ut='IntToFP_3', top='IntToFP_3', warm=12,
    decl="""
  longint c_fire = 0, c_out = 0, c_stall = 0, c_cvt = 0, c_fmv = 0, c_f16 = 0, c_f32 = 0, c_f64 = 0, c_dyn = 0;
""",
    stim="""
    io_in_valid  = ($urandom_range(0, 9) < 7);
    io_out_ready = ($urandom_range(0, 9) != 0);           // 10% 反压
    io_in_bits_validPipe_0 = ($urandom_range(0, 9) != 0);
    io_in_bits_validPipe_1 = ($urandom_range(0, 9) != 0);
    io_in_bits_validPipe_2 = ($urandom_range(0, 9) != 0);
    if ($urandom_range(0, 9) != 0) io_in_bits_ctrl_fpu_typeTagOut = 2'($urandom_range(0, 2));
    io_in_bits_ctrl_fpu_rm = ($urandom_range(0, 4) == 0) ? 3'b111 : 3'($urandom_range(0, 4));
    io_frm = 3'($urandom_range(0, 4));
    // 整数源：小值 / 边界值 / 全随机
    case ($urandom_range(0, 5))
      0: io_in_bits_data_src_0 = 64'($urandom_range(0, 255));
      1: io_in_bits_data_src_0 = 64'h8000_0000_0000_0000;
      2: io_in_bits_data_src_0 = {32'($urandom), 32'h8000_0000};
      3: io_in_bits_data_src_0 = -64'($urandom_range(1, 255));
      default: ;
    endcase
    // 暖机：复位撤销后连发有效请求、不反压，把不复位的 payload / 数据寄存器写成确定值
    if (cyc < WARM) begin
      io_in_valid = 1; io_out_ready = 1;
      io_in_bits_validPipe_0 = 1; io_in_bits_validPipe_1 = 1; io_in_bits_validPipe_2 = 1;
    end
""",
    cov="""
    if (io_in_valid && g_io_in_ready) begin
      c_fire++;
      if (io_in_bits_ctrl_fpu_wflags) c_cvt++; else c_fmv++;
      if (io_in_bits_ctrl_fpu_typeTagOut == 2) c_f16++;
      if (io_in_bits_ctrl_fpu_typeTagOut == 0) c_f32++;
      if (io_in_bits_ctrl_fpu_typeTagOut == 1) c_f64++;
      if (io_in_bits_ctrl_fpu_rm == 3'b111) c_dyn++;
    end
    if (g_io_out_valid) c_out++;
    if (!g_io_in_ready) c_stall++;
""",
    report='"cov fire=%0d out=%0d stall=%0d cvt=%0d fmv=%0d f16/f32/f64=%0d/%0d/%0d dyn=%0d", '
           'c_fire, c_out, c_stall, c_cvt, c_fmv, c_f16, c_f32, c_f64, c_dyn',
    req=['c_fire > 10000', 'c_out > 10000', 'c_stall > 1000', 'c_cvt > 1000', 'c_fmv > 1000',
         'c_f16 > 1000', 'c_f32 > 1000', 'c_f64 > 1000', 'c_dyn > 1000'],
)


# =============================================================================
#  ExeUnit 家族：激励 / 覆盖由 golden 结构自动推出（FU 名单、fuType 编码、门控、inPipe、busy）
# =============================================================================
def exeunit_cfg(top):
    sys.path.insert(0, str(REPO / 'scripts'))
    import gen_exeunit
    v = gen_exeunit.Variant(top)
    g = v.g
    disp_txt = (GOLDEN / f'{v.disp[0]}.sv').read_text()
    codes = []
    for k in range(len(v.fus)):
        m = re.search(r'wire\s+(?:acceptVec_%d|data_0_probe) = io_in_bits_fuType == 35\'h([0-9A-F]+);' % k, disp_txt)
        if not m:
            sys.exit(f'ERROR: {top}: 找不到 Dispatcher 出口 {k} 的 fuType 编码')
        codes.append(m.group(1))
    n = len(v.fus)
    has_flush = 'io_flush_valid' in g.port_w
    decl = [
        f"  localparam int NFU = {n};",
        "  logic [34:0] fu_code [NFU] = '{" + ', '.join(f"35'h{c}" for c in codes) + "};",
        "  longint c_in [NFU];",
        "  longint c_out [NFU];",
        "  longint c_stall = 0, c_flush = 0, c_nofu = 0, c_cg_on = 0, c_cg_off = 0, c_busy = 0;",
    ]
    stim = [
        "    // fuType：85% 取本外壳某个 FU 的编码（与 Dispatcher 的 acceptVec 一致），其余全随机",
        "    //   （多数不命中任何 FU：Dispatcher 不派发，指令被吞 —— 这条路两侧也必须一致）",
        "    if ($urandom_range(0, 99) < 85) io_in_bits_fuType = fu_code[$urandom_range(0, NFU - 1)];",
        "    io_in_valid  = ($urandom_range(0, 9) < 6);",
        "    io_out_ready = ($urandom_range(0, 9) != 0);           // 10% 反压",
    ]
    if 'io_in_bits_robIdx_value' in g.port_w:
        stim.append("    io_in_bits_robIdx_value = 8'($urandom_range(0, 15));  // 窄范围：冲刷比较两种结果都常见")
    if has_flush:
        stim += [
            "    io_flush_valid = ($urandom_range(0, 9) == 0);",
            "    io_flush_bits_robIdx_value = 8'($urandom_range(0, 15));",
        ]
    for _, w, nm in g.ports:
        if re.fullmatch(r'cg_bore(_\d+)?_cgen', nm):
            stim.append(f"    {nm} = ($urandom_range(0, 19) == 0);   // DFT 强开时钟，偶发")
    stim += [
        "    // 暖机：复位撤销后轮流给每个 FU 发有效指令、不反压不冲刷，把各级不复位的寄存器写成确定值",
        "    if (cyc < WARM) begin",
        "      io_in_valid = 1; io_out_ready = 1;",
        "      io_in_bits_fuType = fu_code[cyc % NFU];",
    ]
    if has_flush:
        stim.append("      io_flush_valid = 0;")
    stim.append("    end")
    cov = []
    for k, (t, nm, _) in enumerate(v.fus):
        cov.append(f"    if (u_g._in1ToN_io_out_{k}_valid && u_g._{nm}_io_in_ready) c_in[{k}]++;")
        cov.append(f"    if (u_g._{nm}_io_out_valid) c_out[{k}]++;")
    cov.append("    if (io_in_valid && !(io_in_bits_fuType inside {" + ', '.join(f"35'h{c}" for c in codes) + "})) c_nofu++;")
    cov.append("    if (g_io_out_valid && !io_out_ready) c_stall++;")
    if v.lat_max:
        cov.append("    if (io_flush_valid && (u_g.inPipe_2_1 || io_in_valid)) c_flush++;")
    elif has_flush:
        cov.append("    if (io_flush_valid && io_in_valid) c_flush++;")
    for cg in v.cgs:
        cov.append(f"    if (u_g.{cg[1]}.E) c_cg_on++; else c_cg_off++;")
    if v.has_busy:
        cov.append("    if (u_g.busy) c_busy++;")
    rep = ('"cov in=%p out=%p stall=%0d flush=%0d nofu=%0d cg_on=%0d cg_off=%0d busy=%0d", '
           'c_in, c_out, c_stall, c_flush, c_nofu, c_cg_on, c_cg_off, c_busy')
    req = []
    for k in range(n):
        req += [f'c_in[{k}] > 1000', f'c_out[{k}] > 1000']
    req += ['c_stall > 1000', 'c_nofu > 1000']
    if has_flush:
        req.append('c_flush > 1000')
    if v.cgs:
        req += ['c_cg_on > 1000', 'c_cg_off > 1000']
    if v.has_busy:
        req.append('c_busy > 1000')
    return dict(ut=top, top=top, warm=5 + 8 * n, decl='\n'.join(decl) + '\n',
                stim='\n'.join(stim) + '\n', cov='\n'.join(cov) + '\n', report=rep, req=req,
                init="    foreach (c_in[k]) begin c_in[k] = 0; c_out[k] = 0; end")


for _t in ['ExeUnit', 'ExeUnit_1', 'ExeUnit_4', 'ExeUnit_5', 'ExeUnit_8', 'ExeUnit_9', 'ExeUnit_10',
           'ExeUnit_13', 'ExeUnit_14', 'ExeUnit_15', 'ExeUnit_16', 'ExeUnit_17']:
    TARGETS[_t] = ('lazy', _t)


# =============================================================================
#  生成
# =============================================================================
def gen_tb(name, cfg):
    top = cfg['top']
    ports = parse_ports(top)
    ins = [(w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ports if d == 'output']
    has_clock = any(n == 'clock' for _, _, n in ports)
    has_reset = any(n == 'reset' for _, _, n in ports)

    L = []
    L.append('// =============================================================================')
    L.append(f'// tb —— {top} 双例化 UT（由 scripts/gen_exeunits_ut.py 生成，勿手改）')
    L.append(f'//   golden {top} vs 重写 {top}_xs；每拍比较全部 {len(outs)} 个输出口（!==）。')
    L.append('//   激励 / 覆盖 / 判据见生成器 TARGETS 里本目标一节。')
    L.append('// =============================================================================')
    L.append('`timescale 1ns/1ps')
    L.append('module tb;')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append(f"  localparam int WARM = {cfg['warm']};")
    L.append(f"  localparam int RESET_ODDS = {cfg.get('reset_odds', 20000)};")
    L.append('  longint errors = 0, checks = 0;')
    L.append('  int cyc;')
    L.append('  bit clock = 0;')
    L.append('  always #5 clock = ~clock;')
    L.append('  logic reset;')
    L.append('')
    for w, n in ins:
        L.append(f'  logic {w + " " if w else ""}{n};')
    for w, n in outs:
        L.append(f'  wire  {w + " " if w else ""}g_{n}, i_{n};')
    L.append(cfg.get('decl', ''))

    def inst(mod, iname, pfx):
        conns = []
        if has_clock:
            conns.append('.clock(clock)')
        if has_reset:
            conns.append('.reset(reset)')
        conns += [f'.{n}({n})' for _, n in ins]
        conns += [f'.{n}({pfx}{n})' for _, n in outs]
        body = ',\n    '.join(conns)
        return f'  {mod} {iname} (\n    {body}\n  );'
    L.append(inst(top, 'u_g', 'g_'))
    L.append(inst(top + '_xs', 'u_i', 'i_'))
    L.append('')
    L.append('  // 每拍激励：先全随机，再按目标语义覆盖')
    L.append('  task automatic drive();')
    for w, n in ins:
        L.append(f'    {n} = {rand_expr(w)};')
    L.append(cfg.get('stim', ''))
    L.append('  endtask')
    L.append('')
    L.append('  task automatic compare();')
    for w, n in outs:
        L.append(f'    checks++; if (g_{n} !== i_{n}) begin errors++; if (errors <= 30) '
                 f'$display("[%0d] MISMATCH {n} g=%h i=%h", cyc, g_{n}, i_{n}); end')
    L.append('  endtask')
    L.append('')
    L.append('  task automatic sample_cov();')
    L.append(cfg.get('cov', ''))
    L.append('  endtask')
    L.append('')
    L.append('  initial begin')
    L.append('    bit ok;')
    L.append('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    if cfg.get('init'):
        L.append(cfg['init'])
    L.append('    reset = 1;')
    L.append('    drive();')
    L.append('    for (cyc = 0; cyc < NCYCLES; cyc++) begin')
    L.append('      @(negedge clock);')
    L.append('      reset = (cyc < 5) || ($urandom_range(0, RESET_ODDS - 1) == 0);')
    L.append('      drive();')
    L.append('      #4;')
    L.append('      if (cyc >= WARM) compare();')
    L.append('      if (!reset) sample_cov();')
    L.append('    end')
    if cfg.get('report'):
        L.append(f"    $display({cfg['report']});")
    L.append('    ok = (errors == 0) && (checks > 1000);')
    for r in cfg.get('req', []):
        L.append(f'    if (!({r})) begin ok = 0; $display("cov LOW: {r}"); end')
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (ok) $display("TEST PASSED");')
    L.append('    else $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    ap.add_argument('targets', nargs='*')
    a = ap.parse_args()
    names = a.targets or list(TARGETS)
    drift = 0
    for name in names:
        cfg = TARGETS[name]
        if isinstance(cfg, tuple):
            cfg = exeunit_cfg(cfg[1])
        out = REPO / 'verif' / 'ut' / cfg['ut'] / 'tb.sv'
        text = gen_tb(name, cfg)
        cur = out.read_text() if out.exists() else None
        if a.check:
            if cur != text:
                print(f'DRIFT {out.relative_to(REPO)}')
                drift = 1
        elif cur != text:
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(text)
            print(f'wrote {out.relative_to(REPO)}')
    if a.check and not drift:
        print(f'gen_exeunits_ut: {len(names)} 个 tb 与生成结果一致')
    return drift


if __name__ == '__main__':
    sys.exit(main())
