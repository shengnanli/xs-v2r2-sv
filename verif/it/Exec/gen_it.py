#!/usr/bin/env python3
# =============================================================================
# gen_it.py —— 后端 Exec(执行)簇 IT 装配生成器（勿手改产物，改此脚本后复跑）
# -----------------------------------------------------------------------------
# 选取的 golden 变体: ExeUnit（整数执行单元容器 = Alu + Mul + Bku）。
#   理由: 这 3 个 FU 算法叶子(Alu/Bku/MulUnit)全部已重写，且 ExeUnit glue 核
#   (xs_ExeUnit_core)也已重写 —— 是「执行单元容器 → FU」重写链路最全、无非重写
#   算法 FU 的变体（对比 ExeUnit_8 浮点含未重写的 IntFPToVec）。
#
# IT 的「重写↔重写」首次直连：
#   xs_ExeUnit_core_it  （执行单元 glue：分发/inPipe 打拍/时钟门控使能/§3 one-hot 仲裁）
#     ├─ Alu_xs      → xs_Alu_core      （lat0 整数 ALU，纯重写，无子叶）
#     ├─ MulUnit_xs  → xs_MulUnit_core  （lat2 乘法 wrapper，+ golden 乘法阵列叶子）
#     └─ Bku_xs      → xs_Bku_core      （lat2 位操作/加密，纯重写，无子叶）
#
# golden 黑盒例化在 xs_ExeUnit_core 的 exeunit_connect.svh 里以「golden 同名模块」
# 例化 FU（Alu/MulUnit/Bku）。UT 里这些是 golden FU；IT 把它们换成各模块 UT 现成的
# _xs 适配器（端口逐字 = golden FU 在 ExeUnit 内的实例端口子集，已 grep 核对 drop-in）。
# 实现：复制 exeunit_connect.svh → exeunit_connect_it.svh，仅把 3 个 FU 例化的
# 「模块名」Alu/MulUnit/Bku → Alu_xs/MulUnit_xs/Bku_xs（整词替换，不动 net 名 _Alu_*）。
#
# 共享 golden 结构/存储原语（两侧共用，非算法，IT 规则保留 golden）：
#   · Dispatcher (in1ToN)       —— 按 fuType 路由的分发实体（纯结构）
#   · ClockGate                 —— 时钟门控锁存器（结构原语）
#   · ArrayMulDataModule + C22/C32/C53/CSA3_2 —— MulUnit 的乘法阵列（存储/运算阵列
#                                   原语，xs_MulUnit_core 仍例化它，两侧共用同一份）
#
# 顶层端口 = golden ExeUnit 端口（逐字相同），便于 tb 双例化逐拍比对。
#   golden module ExeUnit → ExeUnit_it；core module xs_ExeUnit_core → xs_ExeUnit_core_it，
#   include exeunit_connect_it.svh（FU 例化模块名换 _xs 适配器）。
# =============================================================================
import re, os

HERE = os.path.dirname(os.path.abspath(__file__))
RTL  = os.path.abspath(os.path.join(HERE, "../../../rtl/backend"))
UT   = os.path.abspath(os.path.join(HERE, "../../ut"))

# ---------------------------------------------------------------------------
# 1) exeunit_connect_it.svh : FU 模块名 → _xs 适配器（整词替换，不误伤 net 名）
#    Alu     -> Alu_xs        （word boundary，避免动到 `_Alu_io_...`）
#    MulUnit -> MulUnit_xs
#    Bku     -> Bku_xs
#    Dispatcher / ClockGate 保持 golden 不变。
# ---------------------------------------------------------------------------
FU_RENAME = [("MulUnit", "MulUnit_xs"), ("Alu", "Alu_xs"), ("Bku", "Bku_xs")]

with open(os.path.join(RTL, "exeunit_connect.svh")) as f:
    conn = f.read()

# 只替换「模块名」出现处：行首两空格 + 模块名 + 空格 + 实例名 + " ("。
# 形如:  "  Alu Alu (" / "  MulUnit Mul (" / "  Bku Bku ("。
for gold, xs in FU_RENAME:
    conn = re.sub(r'(?m)^(  )' + gold + r'( +\w+ \()', r'\1' + xs + r'\2', conn)

conn = ("// 由 verif/it/Exec/gen_it.py 生成 —— 勿手改。\n"
        "// = rtl/backend/exeunit_connect.svh，仅把 3 个 FU 例化的模块名换成 _xs 适配器:\n"
        "//   Alu->Alu_xs / MulUnit->MulUnit_xs / Bku->Bku_xs（Dispatcher/ClockGate 仍 golden）。\n"
        + conn)
with open(os.path.join(HERE, "exeunit_connect_it.svh"), "w") as f:
    f.write(conn)
print("wrote exeunit_connect_it.svh")

# ---------------------------------------------------------------------------
# 2) ExeUnit_it.sv : core(改名 + include _it 连接) + golden 同名 wrapper(改名)
#    把 rtl/backend/ExeUnit.sv 的 module xs_ExeUnit_core → xs_ExeUnit_core_it，
#    include "exeunit_connect.svh" → "exeunit_connect_it.svh"。
#    再附 wrapper：module ExeUnit → ExeUnit_it，内部例化 xs_ExeUnit_core_it。
# ---------------------------------------------------------------------------
with open(os.path.join(RTL, "ExeUnit.sv")) as f:
    core = f.read()
core = core.replace("module xs_ExeUnit_core", "module xs_ExeUnit_core_it")
core = core.replace('`include "exeunit_connect.svh"', '`include "exeunit_connect_it.svh"')

with open(os.path.join(RTL, "ExeUnit_wrapper.sv")) as f:
    wrap = f.read()
wrap = wrap.replace("module ExeUnit(", "module ExeUnit_it(")
wrap = wrap.replace("xs_ExeUnit_core u_core", "xs_ExeUnit_core_it u_core")

out = ("// 后端 Exec 簇 IT 装配（ExeUnit = Alu+Mul+Bku）—— 由 gen_it.py 生成，勿手改。\n"
       "// 顶层 ExeUnit_it 端口 = golden ExeUnit 端口（逐字相同）。\n"
       "// 内部例化 xs_ExeUnit_core_it（include exeunit_connect_it.svh，FU 换 _xs 适配器）。\n\n"
       + core + "\n\n"
       + "// ---- golden 同名扁平 wrapper(改名 ExeUnit_it)：tb u_i 例化此模块 ----\n"
       + wrap + "\n")
with open(os.path.join(HERE, "ExeUnit_it.sv"), "w") as f:
    f.write(out)
print("wrote ExeUnit_it.sv (xs_ExeUnit_core_it + ExeUnit_it wrapper)")

# ---------------------------------------------------------------------------
# 3) golden_alu.sv : 真 golden module Alu（u_g 用）的本地只读副本。
#    本仓 golden/chisel-rtl/Alu.sv 当前是「打包」版（含 alu_pkg + xs_Alu_core +
#    module Alu→包 xs 核），并非纯 golden，且与重写侧同名冲突。改用项目内保留的真
#    golden 备份 Alu.sv.golden（module Alu → 例化 golden AluDataModule 算法叶子），
#    复制到本目录为 .sv 供 VCS 识别。不修改任何共享 golden 文件。
# ---------------------------------------------------------------------------
GOLDEN_DIR = os.path.abspath(os.path.join(HERE, "../../../golden/chisel-rtl"))
with open(os.path.join(GOLDEN_DIR, "Alu.sv.golden")) as f:
    galu = f.read()
galu = ("// 真 golden module Alu（u_g 用）—— 由 gen_it.py 从 golden/chisel-rtl/Alu.sv.golden\n"
        "// 复制（本仓 golden/chisel-rtl/Alu.sv 当前是打包版含 xs 核，与重写侧冲突，不可用）。\n"
        "// module Alu 例化 golden AluDataModule 算法叶子，无 xs 核 / 无 pkg。勿手改。\n\n"
        + galu)
with open(os.path.join(HERE, "golden_alu.sv"), "w") as f:
    f.write(galu)
print("wrote golden_alu.sv (true golden module Alu for u_g)")

# ---------------------------------------------------------------------------
# 4) tb.sv : 以 ExeUnit UT tb 为骨架，只把 u_i 的 ExeUnit_xs → ExeUnit_it。
#    双例化 golden ExeUnit(u_g) vs ExeUnit_it(u_i)，喂相同随机激励逐拍比对全部输出。
# ---------------------------------------------------------------------------
with open(os.path.join(UT, "ExeUnit/tb.sv")) as f:
    tb = f.read()
tb = tb.replace("ExeUnit_xs u_i", "ExeUnit_it u_i")

# --- 关键修正：给 golden u_g 接 io_out_ready=1（恒就绪），匹配重写无背压设计 ---
# 【IT 发现 / 真因】golden ExeUnit 有 io_out_ready 输入端口，驱动其 FU 有效链的
# 背压/失速逻辑（fuVldVec / fuRdyVec = ~fuVldVec_2 | io_out_ready）。而重写 ExeUnit
# (xs_ExeUnit_core + wrapper)**根本没有 io_out_ready 端口** —— 是「下游恒接收」的
# 无背压设计（valid 链无条件移位）。继承自 ExeUnit UT 的原 tb 从不驱动 io_out_ready，
# 它在 +vcs+initreg+0 下浮空为 0 → golden 进入「失速/背压」模式，与重写「恒就绪」假设
# 不一致：一旦真激活 lat2 FU(Mul/Bku)数据通路，golden 的 FU 门控时钟/流水寄存器
# 按背压停拍，重写按恒就绪推进，两者结果逐拍偏移 → 24k+ errors（全在 Mul/Bku，
# io_out_valid 仍逐拍一致，差异在 data/perfDebugInfo 的流水相位）。
# 原 ExeUnit UT 因激励从不命中合法 fuType、FU 通路恒不活化（io_out_valid 恒 0），
# 这条背压差异被「两侧输出恒 0」平凡掩盖，从未暴露。
# 正确比对 = 让 golden 也恒就绪（io_out_ready=1，本设计实际工况：IQ/写回总接收 ExeUnit
# 输出），消除 golden 一侧的背压伪差，得到与重写设计一致的 apples-to-apples 对比。
# u_i(ExeUnit_it/重写)无此端口、无需接。
tb = tb.replace(
    "    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),\n"
    "    .io_out_valid(g_io_out_valid),",
    "    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),\n"
    "    .io_out_ready(1'b1),  // [IT 修正] golden 恒就绪，匹配重写无背压设计（见说明）\n"
    "    .io_out_valid(g_io_out_valid),", 1)

# --- 关键加强：fuType 加权激励，真正激活 FU 数据通路 ---
# 【IT 发现】Dispatcher(in1ToN) 仅当 fuType ∈ {35'h40(Alu),35'h80(Mul),35'h400(Bku)}
# 才路由到对应 FU；ExeUnit UT 原 tb 喂全随机 35bit fuType，命中概率 ~3/2^35≈0，
# 200000 拍内 io_out_valid 恒 0 —— FU(Alu/Mul/Bku)数据通路从未被激活，errors=0 是
# 「两侧输出恒 0」的平凡通过，并未真比对重写 FU 的运算结果。
# IT 必须让重写 FU 核真跑：把 fuType 加权到这 3 个合法值（大概率命中）+ 少量随机
# （覆盖非命中/边界），fuOpType/src 保持随机（两侧同源，任意值都是有效逐拍比对）。
old_futype = "    io_in_bits_fuType <= 35'({$urandom(), $urandom()});"
new_futype = (
"    // [IT 加强] fuType 加权：~90% 命中 3 个合法 FU 类型，激活 Alu/Mul/Bku 数据通路；\n"
"    //          ~10% 随机（覆盖非命中/Dispatcher reject 路径）。详见本文件顶部说明。\n"
"    begin\n"
"      int unsigned _ftsel; _ftsel = $urandom_range(0,9);\n"
"      case (_ftsel)\n"
"        0,1,2:  io_in_bits_fuType <= 35'h40;   // Alu (lat0)\n"
"        3,4,5:  io_in_bits_fuType <= 35'h80;   // Mul (lat2)\n"
"        6,7,8:  io_in_bits_fuType <= 35'h400;  // Bku (lat2)\n"
"        default: io_in_bits_fuType <= 35'({$urandom(), $urandom()});\n"
"      endcase\n"
"    end")
assert old_futype in tb, "fuType stimulus line not found for IT enhancement"
tb = tb.replace(old_futype, new_futype)

# --- 活化计数器：证明 FU 数据通路真被激活（非平凡 0 通过）---
# act_valid    : golden 输出 valid 的拍数（FU 真出结果）。
# act_data_nz  : 输出 data 非 0 且非 X 的拍数（真有运算结果在被逐拍比对）。
tb = tb.replace("  int errors = 0, checks = 0;",
                "  int errors = 0, checks = 0;\n"
                "  int act_valid = 0, act_data_nz = 0;  // [IT] FU 数据通路活化计数")
tb = tb.replace("    #4; checks++;",
                "    #4; checks++;\n"
                "    if (g_io_out_valid === 1'b1) act_valid++;\n"
                "    if (g_io_out_valid === 1'b1 && !$isunknown(g_io_out_bits_data_0)\n"
                "        && g_io_out_bits_data_0 !== 64'h0) act_data_nz++;", 1)
tb = tb.replace('$display("checks=%0d errors=%0d", checks, errors);',
                '$display("checks=%0d errors=%0d act_valid=%0d act_data_nz=%0d",\n'
                '             checks, errors, act_valid, act_data_nz);')
# PASS 判据加上「FU 真被激活」：act_valid>1000 才算有效集成测试。
tb = tb.replace(
    'if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");',
    'if (errors == 0 && checks > 1000 && act_valid > 1000) $display("TEST PASSED");\n'
    '    else $display("TEST FAILED");')

# io_in_valid 偏置：原 0/1 各半。FU 有效再叠加 valid，命中率 ~45%，足够密集激活。
# 保持原 $urandom_range(0,1) 即可（无需改）。

tb = ("// 后端 Exec 簇 IT tb —— 由 gen_it.py 生成（= ExeUnit UT tb，u_i 换 ExeUnit_it，\n"
      "// 并加强 fuType 激励以真正激活 Alu/Mul/Bku 重写 FU 数据通路，见下方说明）。\n"
      + tb)
with open(os.path.join(HERE, "tb.sv"), "w") as f:
    f.write(tb)
print("wrote tb.sv (golden ExeUnit u_g vs ExeUnit_it u_i, fuType-weighted to活化 FU)")
