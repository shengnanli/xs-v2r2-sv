#!/usr/bin/env python3
"""生成本目录的 tb.sv —— golden Predictor 与重写 Predictor_xs 双例化逐拍对照台。

Predictor 有 633 个端口（508 输入 / 125 输出），手写 tb 不现实：端口表直接从
G1 golden 的 module Predictor(...) 解析。端口一变重跑本脚本即可。

═══════════════════════════════════════════════════════════════════════════════
★ 第二版激励：两个结论 ★
═══════════════════════════════════════════════════════════════════════════════
第一版用「约束随机」打 633 个端口，跑 200k 拍报 errors≈0.78%。这一版把两件事分开
查清了，**两个结论都和第一版留下的判断不一样**：

  结论 A：那些失配**一个都不是逻辑差异**，100% 是未初始化 SRAM 造成的 X 悲观。
  结论 B：第一版的 UT **没有判别力**——FTB 从来没被训练出命中，S3 级间覆盖
          (s3_hasRedirect) 一次都没发生过，它比的只是「两边都不跳」。

── 实测台账（全部 seed=1、200k 拍，golden = G1-canonical，impl = 021f2e3 的
   rtl/frontend/Predictor.sv，**三档之间 RTL 一字未改**）─────────────────────

  ① 第一版 tb（021f2e3 原样）
       checks=23,718,648  errors=185,370 (0.78%)
       cov_s2_override=49   cov_s3_override=0        ← 覆盖闸不过
       复跑: git checkout 021f2e3 -- verif/ut/Predictor/tb.sv && make run SEED=1

  ② 第一版 tb + **只加** SRAM 零初始化（激励一个字没动）
       checks=24,941,558  errors=0                   ← ★失配全没了★
       cov_s2_override=62   cov_s3_override=0        ← 覆盖闸照样不过
       ⇒ 结论 A 成立：185,370 个失配全是 X 悲影，不是 bug。
         probe.sv 里原先那句「实测把比较窗口推迟到 6000 拍后，errors 仍有 4.9%，
         所以确有尚未定位的真逻辑差异」是**错的**——推迟窗口治不了 X，
         因为 SRAM 的绝大多数 set 从头到尾就没被写过。
       ⇒ 同时证明：光把 X 治掉**不够**，覆盖仍是 0，UT 依然没有判别力。

  ③ 本版 tb（影子 FTQ 回灌 + 取指区间收敛 + 固定复位向量 + SRAM 零初始化）
       checks=24,940,608  errors=0
       cov_s1_hit=121,287  cov_s2_hit=93,162  cov_s2_override=33,390
       cov_s3_override=14,005  cov_ovr_b2b=2,017 … 34 个覆盖点全部非零

── 让覆盖打起来的那一处改动 ────────────────────────────────────────────────

  ★update 的 pc 是随机数★ —— 这是唯一的成因 —— FTB 的索引/标签是
          FTBBank.sv:1962-1963   req_tag = pc[29:10];  req_idx = pc[9:1] ^ pc[12:4]
      查询 pc 由 BPU 自己产生（s0_pc 自环），update pc 却是 50 位随机数，
      两者 pc[29:1] 撞上的概率 ~2^-29 ⇒ 写进去的条目永远查不到。
      本版改成**影子 FTQ**：把 BPU 自己吐出来的末级预测包
      (s3_pc + last_stage_ftb_entry + last_stage_meta + last_stage_spec_info)
      压进一个 FIFO，过若干拍再当 update 喂回去 —— 这正是真 Ftq 的行为，
      于是 update pc ≡ 某个真实查询过的 pc，FTB 必然能被训练出命中。

  ── ★被实测推翻的一条假设，记下来别再犯★ ────────────────────────────────
  我原先判定「435 根 MBIST 输入被随机打」也是成因之一：其中 11 组
  boreChildrenBd_bore_*（req/writeen/readen/indata/be/array/all/addr/addr_rd）
  确实是真的 MBIST 读写命令，会经 MbistPipe* 直接驱动 SRAM 写口
  （SRAMTemplate_76.sv:135  wckEn = mbistBd_ack ? mbistBd_we : ...），
  req 每拍 50% 随机看上去必然把 FTB 刷掉。于是我一度把 MBIST 分相（功能相置 0）。
  ★A/B 实测否掉了这条★：同一份 tb，MBIST 每拍随机 vs 分相置 0，
      每拍随机: cov_s1_hit=11563 cov_s2_override=3372 cov_s3_override=1104，32 个覆盖点全非零
      分相置 0: cov_s1_hit=17346 cov_s2_override=2268 cov_s3_override=1190，32 个覆盖点全非零
  两边 errors 都是 0。MBIST 只让命中率低一截，**并不妨碍 FTB 被训练出来**。
  所以本版**不分相**，MBIST 照第一版每拍随机打 —— 不关任何一根输入，
  激励强度对每个旋钮都不低于第一版。

  另外两处第一版的硬伤，一并修掉：
  (3) io_reset_vector 每拍随机 —— 它只在 modified_reset 那拍装进 s0_pc_reg
      （golden Predictor.sv:25553-25560），但随机值会让取指流第一拍就落在
      一个随机地址上。本版钉成常量 REGION_BASE。
  (4) 取指流无界漂移 —— 不命中时按 fallThrough 一路往前走，训练过的块再也走
      不回来。本版把 redirect 的 cfiUpdate_target 钉在 NBLK 个块对齐地址上，
      并让合成的 FTB 表项把跳转目标也指回这些块，取指流因此收敛在一个
      NBLK×32B 的小区间里，FTB 的 set 很快被写满。

═══════════════════════════════════════════════════════════════════════════════
★ SRAM 零初始化（bind）——为什么这是加强而不是放宽 ★
═══════════════════════════════════════════════════════════════════════════════
golden 的 SRAM 行为模型（array_*_ext.v / data_mem_*.sv）在 +define+SYNTHESIS 下
**不做任何初始化**，未写过的 ram[] 读出来是 X。两侧各有一份，X 是对称的，但
golden 被 firtool 常量折叠过（s2_ready/s3_ready 已折成常量等），X 传播范围比
未折叠的可读核小 —— 于是出现大量「g=0 i=x」的**纯 X 悲观失配**，它们不是逻辑差异
（FM 是二值的，根本看不见这类差异）。

本 tb 用 `bind` 给每种 SRAM 行为模型挂一个把存储阵列清零的初始化件。理由：
  · 它**对称**地作用在 dut_g 和 dut_i 的同名模块上，不可能只帮一边；
  · 它只**增加** checks（$isunknown(g) 的跳过变少），不可能掩盖任何失配；
  · 全零 = 所有 tag 无效 = 真实 SRAM 上电后靠 tag 不匹配保证的同一语义。
所以这是把一个纯仿真伪影拿掉，不是放宽判据。上面台账 ①→② 那一行就是它的量：
只加这一件事，errors 从 185,370 掉到 0，而 checks 反而从 23,718,648 涨到
24,941,558（多比了 122 万个点）——**只增不减**，符合上面第二条理由。

═══════════════════════════════════════════════════════════════════════════════
★ 负对照：这个 tb 真的会报错吗 ★
═══════════════════════════════════════════════════════════════════════════════
「errors=0」只有在「UT 本来就抓得到错」的前提下才有意义。往可读核里各注入一个
单点 bug（RTL 不进库，只在 ut_gen 副本上改），用本 tb 跑 20k 拍 seed=1：

  mutA  s3_redirect 少一项 multi_hit（OVR_ 节，覆盖判定的一条独立成因）
        → errors=290,798 / checks=2,440,555，其中 errors_val=290,798（无一是 X）
  mutB  SEL_ 里 s0_pc 的 s2/s3 优先级对调（s3 本该压过 s2）
        → errors=237,578 / checks=2,440,555，errors_val=237,578

  两个都当场红，且失配集中在 s1_pc_3 / s1_full_pred_3_*（取指流被带偏）。
  ★同样这两个 mutant，用第一版 tb 是分辨不出来的★：第一版本底噪就有 18 万个
  X 失配，注入前后都是「一大堆 errors」，没有判别力可言。

每一档都不比第一版弱：反压 20%、重定向 4%、IFU 重定向 3%、预测器使能各 3% 关、
shift=3 越界压力、435 根 MBIST 每拍随机——全部照抄第一版的比例，一个旋钮没松。

用法:  python3 gen_tb.py tb.sv
"""
import re, sys

G1 = '/home/eda/xs-env/G1-canonical/golden-rtl/Predictor.sv'
OUT = sys.argv[1] if len(sys.argv) > 1 else 'tb.sv'

src = open(G1).read()
m = re.search(r'^module Predictor\(\s*(.*?)^\);', src, re.S | re.M)
ins, outs = [], []
for l in m.group(1).split('\n'):
    l = l.strip().rstrip(',')
    if not l:
        continue
    mm = re.match(r'(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)$', l)
    assert mm, l
    (ins if mm.group(1) == 'input' else outs).append((mm.group(3), mm.group(2) or ''))
ins = [(n, w) for n, w in ins if n not in ('clock', 'reset')]
assert len(ins) + len(outs) == 631, (len(ins), len(outs))

# MBIST/DFT 线与功能线的分界：只看名字前缀就够，golden 里
# 这两族的命名是严格分开的（功能线一律 io_ 前缀，DFT 线一律没有）。
MBIST_ACKS = ['boreChildrenBd_bore_ack'] + \
             [f'boreChildrenBd_bore_{i}_ack' for i in range(1, 11)]


def is_mbist(n):
    return n.startswith('sigFromSrams_') or n.startswith('boreChildrenBd_')

MBIST = [(n, w) for n, w in ins if is_mbist(n)]
FUNC  = [(n, w) for n, w in ins if not is_mbist(n)]
assert len(MBIST) + len(FUNC) == len(ins)
# 功能线现在**全部手工驱动**（第一版只手驱 24 根，其余随机）。
FUNC_NAMES = set(n for n, _ in FUNC)


def wid(w):
    if not w:
        return 1
    a, b = w.strip('[]').split(':')
    return int(a) - int(b) + 1


def rnd_expr(n, w):
    k = wid(w)
    if k == 1:
        return "$urandom_range(0,1)"
    if k <= 32:
        return f"{k}'($urandom())"
    chunks = (k + 31) // 32
    return f"{k}'({{{', '.join(['$urandom()'] * chunks)}}})"


# ---------------------------------------------------------------------------
# SRAM 行为模型清单（模块名, 阵列变量名, 深度, 位宽, unpacked 范围是否降序）
# 取自 G1 golden：array_*_ext.v 用 `reg [W-1:0] ram [DEPTH-1:0]`（降序），
# data_mem_*.sv 用 `reg [W-1:0] Memory[0:DEPTH-1]`（升序）。范围方向必须和
# 目标声明一致，否则 ref 端口类型对不上。
SRAMS = [
    ('array_1_ext',    'ram',    512, 40, True),
    ('array_2_ext',    'ram',    256, 16, True),
    ('array_3_ext',    'ram',    512, 24, True),
    ('array_4_ext',    'ram',    256,  8, True),
    ('array_5_ext',    'ram',    128, 24, True),
    ('array_6_ext',    'ram',    128, 76, True),
    ('data_mem_0_4x2', 'Memory',   4,  2, False),
    ('data_mem_0_8x3', 'Memory',   8,  3, False),
    ('data_mem_16x12', 'Memory',  16, 12, False),
    ('data_mem_8x4',   'Memory',   8,  4, False),
]

# ---------------------------------------------------------------------------
# 覆盖点（全部测**golden 侧**；任何一个为 0 则本 UT 判失败）
#
# ★为什么覆盖点必须挂在 golden 上★：挂在 impl 上的覆盖点，impl 自己算错也能把它
# 打满；只有 golden 侧的计数才说明「这条路真的被激励走到了」。
COV = [
    # ---- 流水与握手 ----
    ('cov_s0_fire',        'g_io_bpu_to_ftq_resp_valid === 1\'b1',
     '预测包送 FTQ'),
    ('cov_s2_valid',       'g_io_bpu_to_ftq_resp_bits_s2_valid_3 === 1\'b1', 'S2 级有效'),
    ('cov_s3_valid',       'g_io_bpu_to_ftq_resp_bits_s3_valid_3 === 1\'b1', 'S3 级有效'),
    ('cov_ftq_stall',      'io_bpu_to_ftq_resp_ready === 1\'b0',             'FTQ 反压'),
    # ---- ★FTB 被训练出命中★（第一版这几条全是 0 —— 它是其余一切的前置）----
    ('cov_s1_hit',         'g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit === 1\'b1',
     'S1(uFTB) 命中'),
    ('cov_s2_hit',         'g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit === 1\'b1',
     'S2(FTB) 命中'),
    ('cov_s3_hit',         'g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit === 1\'b1',
     'S3 命中'),
    ('cov_s1_taken',       '(g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 | '
                           'g_io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1) === 1\'b1',
     'S1 预测跳转'),
    ('cov_s3_taken',       '(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 | '
                           'g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1) === 1\'b1',
     'S3 预测跳转'),
    # ---- ★级间覆盖：本模块真正要验的东西★ ----
    ('cov_s2_override',    'g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 === 1\'b1',
     'S2 覆盖 S1'),
    ('cov_s3_override',    'g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 === 1\'b1',
     'S3 覆盖 S2'),
    ('cov_s2_ovr_allen',   'g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 === 1\'b1 && all_pred_en',
     'S2 覆盖(五个预测器全开) —— 排除「靠关预测器凑出来的覆盖」'),
    ('cov_s3_ovr_allen',   'g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 === 1\'b1 && all_pred_en',
     'S3 覆盖(五个预测器全开)'),
    ('cov_ovr_b2b',        'g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 === 1\'b1 && '
                           'g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 === 1\'b1',
     'S2/S3 同拍一起覆盖'),
    ('cov_ftherr',         '(g_io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr | '
                           'g_io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr) === 1\'b1',
     'fallThrough 越界(S3 覆盖的一条独立成因)'),
    # ---- FTQ 真重定向与历史回滚 ----
    ('cov_redirect',       'io_ftq_to_bpu_redirect_valid === 1\'b1',        'FTQ 真重定向'),
    ('cov_redir_hist',     'io_ftq_to_bpu_redirect_valid && '
                           'io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist',
     '重定向且要改历史(走 GHV 回滚慢路)'),
    ('cov_shift1',         'io_ftq_to_bpu_redirect_valid && '
                           'io_ftq_to_bpu_redirect_bits_cfiUpdate_shift == 2\'d1', '回滚 shift=1'),
    ('cov_shift2',         'io_ftq_to_bpu_redirect_valid && '
                           'io_ftq_to_bpu_redirect_bits_cfiUpdate_shift == 2\'d2', '回滚 shift=2'),
    ('cov_ctrl_bubble',    'io_ftq_to_bpu_redirect_valid && '
                           'io_ftq_to_bpu_redirect_bits_debugIsCtrl',       '控制流气泡归因'),
    ('cov_memvio_bubble',  'io_ftq_to_bpu_redirect_valid && '
                           'io_ftq_to_bpu_redirect_bits_debugIsMemVio',     '访存违例气泡归因'),
    ('cov_ifu_redir',      'io_ftq_to_bpu_redirctFromIFU === 1\'b1',        'IFU 重定向'),
    ('cov_topdown_set',    '|{g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1, '
                           'g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2, '
                           'g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9}',
     'topdown 归因置位'),
    # ---- update 通道（影子 FTQ 回灌）----
    ('cov_update',         'io_ftq_to_bpu_update_valid === 1\'b1',          'update 有效'),
    ('cov_upd_write',      'io_ftq_to_bpu_update_valid && '
                           '!io_ftq_to_bpu_update_bits_old_entry',          'update 真写 FTB'),
    ('cov_upd_brtaken',    'io_ftq_to_bpu_update_valid && '
                           'io_ftq_to_bpu_update_bits_br_taken_mask_0',     'update 报第一条分支跳'),
    ('cov_upd_mispred',    'io_ftq_to_bpu_update_valid && '
                           '|{io_ftq_to_bpu_update_bits_mispred_mask_0, '
                           'io_ftq_to_bpu_update_bits_mispred_mask_1}',     'update 报预测错(TAGE 分配)'),
    ('cov_upd_jalr',       'io_ftq_to_bpu_update_valid && '
                           'io_ftq_to_bpu_update_bits_ftb_entry_isJalr',    'update 带间接跳转(ITTAGE)'),
    ('cov_upd_ret',        'io_ftq_to_bpu_update_valid && '
                           'io_ftq_to_bpu_update_bits_ftb_entry_isRet',     'update 带返回(RAS pop)'),
    ('cov_upd_call',       'io_ftq_to_bpu_update_valid && '
                           'io_ftq_to_bpu_update_bits_ftb_entry_isCall',    'update 带调用(RAS push)'),
    # ---- 真重定向冲掉在飞的流水 ----
    #
    # ★这里原本放的是「do_redirect 与 s2/s3_redirect 同拍撞上」，实测恒 0，而且
    #   查清了是**设计上不可达**，不是激励不够★：redirect 在第 T 拍直接进
    #   s3_flush/s2_flush/s1_flush，三级 valid 在 T→T+1 边沿全被清 0；而
    #   do_redirect 是 redirect 锁存一拍、在 T+1 才参与 S0 选择，那一拍
    #   s2_fire/s3_fire 必然为 0 ⇒ s2/s3_redirect 必然为 0。
    #   也就是说 SEL_ 那条优先级链里「redirect 压过 s3 压过 s2」这一段的仲裁
    #   **在真实时序下永远不会被考到**（golden 同构，见 Predictor.sv:24099-24131 的
    #   s1/s2/s3_valid 次态式子，三条都带 ~redirect / ~s2_flush 的全局清零项）。
    #   把一个不可达事件放进覆盖闸是错的闸，换成真正可达、也真正有意义的这条：
    #   重定向到来时流水里确实有在飞的预测包（冲刷路径被走到），而不是空转。
    #   换第二次：s2_valid_3 / s3_valid_3 这两个**输出**本身也被 redirect 组合门掉了
    #   （golden Predictor.sv:44814/44848: s2_valid_dup_3 & ~s2_flush_dup_3、
    #     s3_valid_dup_3 & ~redirect），所以「redirect 且 s2/s3_valid」同样恒 0。
    #   resp_valid 才是没被 redirect 门过的那根（44xxx: s1_valid_dup_3 | …），
    #   用它才能真的抓到「重定向撞上在飞的预测包」。
    ('cov_redir_vs_resp',  'io_ftq_to_bpu_redirect_valid && '
                           'g_io_bpu_to_ftq_resp_valid === 1\'b1',
     '重定向撞上在飞的预测包（冲刷路径真的被走到）'),
    ('cov_hp_wrap',        'g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag === 1\'b1',
     '历史指针绕过 256 位(flag 翻起来)'),
    # ---- 预测器使能与 DFT ----
    ('cov_pred_dis',       '!all_pred_en',                                   '至少一个预测器被关'),
    ('cov_mbist_ack',      '|{' + ', '.join('g_' + a for a in MBIST_ACKS) + '}',
     'MBIST 命令被 SRAM 应答(证明 DFT 链真的通)'),
]

L = []
A = L.append

# ---------------------------------------------------------------------------
A('// tb.sv —— Predictor UT：golden `Predictor` 与重写 `Predictor_xs` 双例化，')
A('//          同激励逐拍比全部 %d 个输出。本文件由 gen_tb.py 生成，别手改。' % len(outs))
A('//')
A('// 两侧共用同一份 golden Composer（及其 5 个预测器闭包）——本 UT 只验 Predictor')
A('// 这一层的流水控制与全局历史管理，预测器本身另有各自的签核。因此：**只要两侧')
A('// Predictor 逻辑一致，两份 Composer 吃到的输入就逐位一致，输出也必然一致**，')
A('// 任何失配都落在本模块自己身上。')
A('//')
A('// 激励设计与实测依据见 gen_tb.py 头注释（影子 FTQ 回灌 / 取指区间收敛 /')
A('// 固定复位向量；以及被实测否掉的 MBIST 分相假设）。★覆盖闸：golden 侧任何一个覆盖点为 0 即判 TEST FAILED —— ')
A('// 覆盖点全 0 的 UT 报 errors=0 是没有意义的。★')
A('`timescale 1ns/1ps')
A('')
A('// ---------------------------------------------------------------------------')
A('// SRAM 行为模型零初始化（理由见 gen_tb.py 头注释「为什么这是加强而不是放宽」）')
A('// ---------------------------------------------------------------------------')
A('// +no_sram_zero 关掉本初始化 —— 只用来复现「不清零时那一档 X 悲观失配数」这条')
A('// 对照证据（见 gen_tb.py 头注释里的 A/B 表），正常跑不要加。')
A('module xs_ram_zero_dn #(parameter int DEPTH = 1, parameter int W = 1)')
A('                      (ref reg [W-1:0] ram [DEPTH-1:0]);')
A('  initial if (!$test$plusargs("no_sram_zero"))')
A('    for (int i = 0; i < DEPTH; i++) ram[i] = \'0;')
A('endmodule')
A('')
A('module xs_ram_zero_up #(parameter int DEPTH = 1, parameter int W = 1)')
A('                      (ref reg [W-1:0] Memory [0:DEPTH-1]);')
A('  initial if (!$test$plusargs("no_sram_zero"))')
A('    for (int i = 0; i < DEPTH; i++) Memory[i] = \'0;')
A('endmodule')
A('')
for mod, var, depth, w, desc in SRAMS:
    z = 'xs_ram_zero_dn' if desc else 'xs_ram_zero_up'
    A(f'bind {mod} {z} #(.DEPTH({depth}), .W({w})) u_xs_zero (.{var}({var}));')
A('')
A('module tb;')
A('  int unsigned NCYCLES = 200000;')
A('  bit clk = 0, rst;')
A('  longint errors = 0, checks = 0;')
A('  // 失配分两类只为**定位**，判据仍然是 errors 总数：')
A('  //   errors_x   = golden 已定值而 impl 是 X（X 悲观差异）')
A('  //   errors_val = 两侧都是定值但不相等（真逻辑差异）')
A('  longint errors_x = 0, errors_val = 0;')
A('  longint cyc = 0;')
A('  always #5 clk = ~clk;')
A('')
A('  // ---- 输入信号（两侧共用） ----')
for n, w in ins:
    A(f'  logic {w} {n};')
A('')
A('  // ---- 每个输出两根线：g_<port> / i_<port> ----')
for n, w in outs:
    A(f'  wire {w} g_{n};')
    A(f'  wire {w} i_{n};')
A('')
for dut, pref in (('Predictor dut_g', 'g_'), ('Predictor_xs dut_i', 'i_')):
    A(f'  {dut} (')
    A('    .clock(clk), .reset(rst),')
    for n, _ in ins:
        A(f'    .{n}({n}),')
    for k, (n, _) in enumerate(outs):
        comma = '' if k == len(outs) - 1 else ','
        A(f'    .{n}({pref}{n}){comma}')
    A('  );')
    A('')

# ---------------------------------------------------------------------------
A('  function automatic bit chance(int unsigned pct);')
A('    return ($urandom_range(0, 99) < pct);')
A('  endfunction')
A('')
A('  // =========================================================================')
A('  // 取指区间：把取指流收敛到 NBLK 个 32 字节块上')
A('  //')
A('  // FTB 的索引/标签只看 pc[29:1]（FTBBank.sv:1962-1963），所以「训练过的 pc」')
A('  // 和「以后会查的 pc」必须逐位相同才可能命中。取指流由 BPU 自环产生，唯一能从')
A('  // 外部把它钉住的两个把手是 ① 复位向量 ② redirect 的 cfiUpdate_target。')
A('  // 二者都钉在 REGION_BASE + j*32 (j<NBLK) 上；合成 FTB 表项的跳转目标也指回')
A('  // 这些块（见 syn_lower），于是稳态下取指流就在这 NBLK 个块里绕。')
A('  //')
A('  // REGION_BASE 取 8 KiB 对齐：FTB 表项里 brSlot 只存 target[12:1]（12 位），')
A('  // tarStat=0(TAR_FIT) 表示高位照抄 pc —— 8 KiB 对齐保证目标不会跨出本页。')
A('  // =========================================================================')
A('  localparam logic [49:0] REGION_BASE = 50\'h00_8000_0000;  // 2 GiB，8 KiB 对齐')
A('  localparam int          NBLK        = 16;                 // 训练用取指块数')
A('  localparam int          BLK_BYTES   = 32;                 // 一个取指块 = 16 条 × 2 B')
A('')
A('  function automatic logic [49:0] blk_pc(input int j);')
A('    return REGION_BASE + 50\'(j % NBLK) * BLK_BYTES;')
A('  endfunction')
A('  // 取指块序号：REGION_BASE 是 8 KiB 对齐，块大小 32 B ⇒ 序号就在 pc[8:5]。')
A('  function automatic int blk_of(input logic [49:0] pc);')
A('    return int\'(pc[8:5]);')
A('  endfunction')
A('  // 合成表项的跳转目标块：7 与 16 互质 ⇒ j→(7j+3) 是 16 个块上的一个完整轮换，')
A('  // 取指流因此会走遍全部 NBLK 个块，而不是卡在两三个块上。')
A('  function automatic int tgt_blk(input int j);')
A('    return (j * 7 + 3) % NBLK;')
A('  endfunction')
A('')
A('  // =========================================================================')
A('  // 影子 FTQ —— 把 BPU 自己吐出的末级预测包过若干拍当 update 喂回去')
A('  //')
A('  // 真 Ftq 就是这么做的：s3 那拍把 (pc, meta, ftb_entry, spec_info) 存进队列，')
A('  // 等后端把这条取指块执行完再带着「实际怎么跳的」回灌 BPU。本 tb 只保留其中')
A('  // 与 BPU 训练有关的部分，「实际怎么跳的」用一个**按 pc 可复现**的模式生成')
A('  // （bpat/phs），这样 TAGE 才学得会、SC 才可能与之分歧 —— 那正是 S3 覆盖的来源。')
A('  // =========================================================================')
A('  localparam int FQD = 32;   // 队列深度（真 FtqSize=64，这里只要够产生时延）')
A('  localparam int FQ_LAG = 8; // 至少积压这么多条才开始回灌，制造真实的 update 时延')
A('')
A('  typedef struct packed {')
A('    logic        isCall, isRet, isJalr, ent_valid;')
A('    logic [3:0]  br0_off;   logic br0_sharing, br0_valid;')
A('    logic [11:0] br0_lower; logic [1:0] br0_tarStat;')
A('    logic [3:0]  tl_off;    logic tl_sharing, tl_valid;')
A('    logic [19:0] tl_lower;  logic [1:0] tl_tarStat;')
A('    logic [3:0]  pftAddr;   logic carry, rvi_call, sb0, sb1;')
A('  } ftbe_t;')
A('')
A('  logic [49:0]  fq_pc   [0:FQD-1];')
A('  logic [515:0] fq_meta [0:FQD-1];')
A('  ftbe_t        fq_ent  [0:FQD-1];')
A('  logic [7:0]   fq_hp   [0:FQD-1];')
A('  logic         fq_hpf  [0:FQD-1];')
A('  int           fq_wr = 0, fq_rd = 0, fq_cnt = 0;')
A('')
A('  // 每块一个 8 位方向模式 + 一个 3 位相位 ⇒ 每个 pc 上是周期 8 的可学模式。')
A('  // 随机种子决定模式内容，所以三个 seed 走的是三套不同的分支行为。')
A('  logic [7:0] bpat [0:NBLK-1];')
A('  logic [2:0] phs  [0:NBLK-1];')
A('')
A('  // 末级历史指针的影子：重定向要带「当时的历史指针」，跟着 BPU 自己吐的走才有意义。')
A('  logic [7:0] hp_shadow;')
A('  logic       hpf_shadow;')
A('')
A('  // 五个预测器是否全开 —— 用来把「靠关预测器凑出来的覆盖」和真覆盖分开统计。')
A('  wire all_pred_en = io_ctrl_ubtb_enable & io_ctrl_btb_enable & io_ctrl_tage_enable')
A('                   & io_ctrl_sc_enable  & io_ctrl_ras_enable;')
A('')
A('  // ---- 采样：s3 有效那拍把整包压进影子 FTQ ----')
A('  always @(posedge clk) begin')
A('    if (rst) begin')
A('      fq_wr = 0; fq_rd = 0; fq_cnt = 0;')
A('      hp_shadow = 8\'h0; hpf_shadow = 1\'b0;')
A('    end else begin')
A('      if (g_io_bpu_to_ftq_resp_bits_s3_valid_0 === 1\'b1')
A('          && !$isunknown(g_io_bpu_to_ftq_resp_bits_s3_pc_0)) begin')
A('        hp_shadow  = g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;')
A('        hpf_shadow = g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;')
A('        if (fq_cnt < FQD) begin')
A('          fq_pc  [fq_wr] = g_io_bpu_to_ftq_resp_bits_s3_pc_0;')
A('          fq_meta[fq_wr] = g_io_bpu_to_ftq_resp_bits_last_stage_meta;')
A('          fq_hp  [fq_wr] = g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;')
A('          fq_hpf [fq_wr] = g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;')
A('          fq_ent [fq_wr] = \'{')
A('            isCall     : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall,')
A('            isRet      : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet,')
A('            isJalr     : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr,')
A('            ent_valid  : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid,')
A('            br0_off    : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset,')
A('            br0_sharing: g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing,')
A('            br0_valid  : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid,')
A('            br0_lower  : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower,')
A('            br0_tarStat: g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat,')
A('            tl_off     : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset,')
A('            tl_sharing : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing,')
A('            tl_valid   : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid,')
A('            tl_lower   : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower,')
A('            tl_tarStat : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat,')
A('            pftAddr    : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr,')
A('            carry      : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry,')
A('            rvi_call   : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call,')
A('            sb0        : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0,')
A('            sb1        : g_io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1 };')
A('          fq_wr  = (fq_wr + 1) % FQD;')
A('          fq_cnt = fq_cnt + 1;')
A('        end')
A('      end')
A('    end')
A('  end')
A('')
A('  // ---- MBIST/DFT 线：每拍随机（与第一版相同，理由见 gen_tb.py 头注释的 A/B）----')
A('  task automatic drive_mbist();')
for n, w in MBIST:
    k = wid(w)
    A(f"    {n} = {rnd_expr(n, w)};")
A('  endtask')
A('')
A('  // ---- update 通道：从影子 FTQ 回灌一条 ----')
A('  //')
A('  // 表项内容是 pc 的**确定函数**（syn_* 系列），所以同一个 pc 反复被 update 时')
A('  // 写进 FTB 的是同一条 —— 表项能稳下来，命中才能稳定发生。')
A('  task automatic drive_update();')
A('    int j, t;')
A('    logic [49:0] upc, utgt;')
A('    logic [3:0]  br_off, tl_off;')
A('    logic        shr, brtk0, brtk1, jtk;')
A('    ftbe_t       cap;')
A('    if (fq_cnt > FQ_LAG) begin')
A('      upc  = fq_pc[fq_rd];')
A('      cap  = fq_ent[fq_rd];')
A('      j    = blk_of(upc);')
A('      t    = tgt_blk(j);')
A('      utgt = blk_pc(t);')
A('      // 合成表项：第一条槽放条件分支，尾槽按 j%4 轮流放')
A('      //   0 → 第二条条件分支(sharing) 1 → jalr(练 ITTAGE)')
A('      //   2 → ret (练 RAS 弹栈)      3 → call(练 RAS 压栈)')
A('      shr    = (j % 4 == 0);')
A('      br_off = 4\'(j % 12);')
A('      tl_off = 4\'(12 + (j % 4));')
A('      brtk0  = bpat[j][phs[j]];')
A('      brtk1  = shr & bpat[j][(phs[j] + 3) % 8];')
A('      jtk    = ~shr & chance(70);')
A('      phs[j] = phs[j] + 3\'d1;')
A('')
A('      io_ftq_to_bpu_update_valid                          = 1\'b1;')
A('      io_ftq_to_bpu_update_bits_pc                        = upc;')
A('      io_ftq_to_bpu_update_bits_meta                      = fq_meta[fq_rd];')
A('      io_ftq_to_bpu_update_bits_spec_info_histPtr_value   = fq_hp[fq_rd];')
A('      io_ftq_to_bpu_update_bits_ftb_entry_valid           = 1\'b1;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid  = 1\'b1;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset = br_off;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing= 1\'b0;')
A('      // brSlot 只存 target[12:1]；目标块 t 的地址是 REGION_BASE + t*32 ⇒ 低位 = t*16')
A('      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower  = 12\'(t) << 4;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat= 2\'d0;   // TAR_FIT：高位照抄 pc')
A('      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid   = 1\'b1;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset  = tl_off;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing = shr;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower   = 20\'(t) << 4;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat = 2\'d0;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_isJalr           = (j % 4 == 1) | (j % 4 == 2);')
A('      io_ftq_to_bpu_update_bits_ftb_entry_isRet            = (j % 4 == 2);')
A('      io_ftq_to_bpu_update_bits_ftb_entry_isCall           = (j % 4 == 3);')
A('      // pftAddr=0 且 carry=1 ⇒ fallThrough 正好是下一个 32 B 块，取指流保持块对齐')
A('      io_ftq_to_bpu_update_bits_ftb_entry_pftAddr          = 4\'d0;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_carry            = 1\'b1;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call = 1\'b0;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0    = 1\'b0;')
A('      io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1    = 1\'b0;')
A('      io_ftq_to_bpu_update_bits_br_taken_mask_0            = brtk0;')
A('      io_ftq_to_bpu_update_bits_br_taken_mask_1            = brtk1;')
A('      io_ftq_to_bpu_update_bits_jmp_taken                  = jtk;')
A('      io_ftq_to_bpu_update_bits_cfi_idx_valid              = brtk0 | brtk1 | jtk;')
A('      io_ftq_to_bpu_update_bits_cfi_idx_bits               = brtk0 ? br_off : tl_off;')
A('      // mispred 是 TAGE 分配新表项的触发条件，必须真的会置起来')
A('      io_ftq_to_bpu_update_bits_mispred_mask_0             = chance(22);')
A('      io_ftq_to_bpu_update_bits_mispred_mask_1             = chance(15);')
A('      io_ftq_to_bpu_update_bits_mispred_mask_2             = chance(10);')
A('      io_ftq_to_bpu_update_bits_false_hit                  = chance(4);')
A('      // old_entry=1 时 FTB 不写（FTB.sv:1332 u_valid = update_valid & ~old_entry）。')
A('      // 已经有表项的块大多不重写，让 FTB 稳下来；没表项的块一定写。')
A('      io_ftq_to_bpu_update_bits_old_entry                  = cap.ent_valid & chance(65);')
A('      io_ftq_to_bpu_update_bits_full_target                = utgt;')
A('      fq_rd  = (fq_rd + 1) % FQD;')
A('      fq_cnt = fq_cnt - 1;')
A('    end else begin')
A('      io_ftq_to_bpu_update_valid = 1\'b0;')
A('    end')
A('  endtask')
A('')
A('  // ---- FTQ 真重定向 ----')
A('  task automatic drive_redirect();')
A('    int rb;')
A('    io_ftq_to_bpu_redirect_valid = chance(4);')
A('    rb = $urandom_range(0, NBLK - 1);')
A('    // 重定向目标钉在块对齐地址上：它是把取指流拉回训练区间的唯一外部把手')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_target = blk_pc(rb);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_pc =')
A('        blk_pc($urandom_range(0, NBLK - 1)) + 50\'($urandom_range(0, 15)) * 2;')
A('    io_ftq_to_bpu_redirect_bits_level             = $urandom_range(0, 1);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid  = chance(80);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC  = chance(40);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall = chance(15);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet  = chance(15);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp       = 4\'($urandom());')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr      = 3\'($urandom());')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag = $urandom_range(0, 1);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value= 5\'($urandom());')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag = $urandom_range(0, 1);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value= 5\'($urandom());')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag  = $urandom_range(0, 1);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value = 5\'($urandom());')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit    = chance(60);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit    = chance(30);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit    = chance(30);')
A('    io_ftq_to_bpu_redirect_bits_BTBMissBubble       = chance(20);')
A('    // 历史指针跟着 BPU 自己吐出来的末级指针走：回滚点落在真实走过的历史上，')
A('    // 折叠历史重算才有比对价值（随机指针会把回滚打到一个从没到过的点上）。')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value =')
A('        chance(80) ? hp_shadow : 8\'($urandom());')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag  =')
A('        chance(80) ? hpf_shadow : $urandom_range(0, 1);')
A('    // shift 只有 0/1/2 合法(numBr=2)；偶尔打 3 压一下越界行为(golden 也有确定语义)')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_shift       =')
A('        chance(95) ? 2\'($urandom_range(0, 2)) : 2\'d3;')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist = chance(70);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_taken       = chance(50);')
A('    io_ftq_to_bpu_redirect_bits_debugIsCtrl           = chance(45);')
A('    io_ftq_to_bpu_redirect_bits_debugIsMemVio         = chance(20);')
A('  endtask')
A('')
A('  always @(negedge clk) begin')
A('    drive_mbist();')
A('    drive_redirect();')
A('    drive_update();')
A('    io_bpu_to_ftq_resp_ready = chance(80);')
A('    io_ftq_to_bpu_redirctFromIFU = chance(3);')
A('    io_ftq_to_bpu_enq_ptr_flag  = $urandom_range(0, 1);')
A('    io_ftq_to_bpu_enq_ptr_value = 6\'($urandom());')
A('    // 复位向量必须是常量：它只在 modified_reset 那拍装进 s0_pc_reg，')
A('    // 随机值会让取指流第一拍就落在一个随机地址上（第一版的 bug）。')
A('    io_reset_vector = 48\'(REGION_BASE);')
A('    // 五个使能绝大多数时间全开；留 2% 关一个，覆盖「预测器被关」这条路。')
A('    io_ctrl_ubtb_enable = chance(97); io_ctrl_btb_enable = chance(97);')
A('    io_ctrl_tage_enable = chance(97); io_ctrl_sc_enable  = chance(97);')
A('    io_ctrl_ras_enable  = chance(97);')
A('  end')
A('')
A('  // ---- 覆盖计数（关键事件；任一为 0 即判失败）----')
for nm, _, _ in COV:
    A(f'  longint {nm} = 0;')
A('')
A('  // ---- 逐端口失配直方图：定位用，判据仍是 errors 总数 ----')
A(f'  localparam int NOUT = {len(outs)};')
A('  longint eh   [0:NOUT-1];')
A('  string  onm  [0:NOUT-1];')
A('  initial begin')
A('    for (int k = 0; k < NOUT; k++) eh[k] = 0;')
for k, (n, _) in enumerate(outs):
    A(f'    onm[{k}] = "{n}";')
A('  end')
A('')
A('  // ---- 逐拍比对全部 %d 个输出 ----' % len(outs))
A('  always @(posedge clk) if (!rst) begin')
A('    cyc++;')
for k, (n, _) in enumerate(outs):
    A(f'    if (!$isunknown(g_{n})) begin checks++;')
    A(f'      if (g_{n} !== i_{n}) begin')
    A(f'        errors++; eh[{k}]++;')
    A(f'        if ($isunknown(i_{n})) errors_x++; else errors_val++;')
    A(f'        if (errors<=60) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n});')
    A('      end end')
for nm, cond, _ in COV:
    A(f'    if ({cond}) {nm}++;')
A('  end')
A('')
A('  initial begin')
A('    void\'($value$plusargs("ncycles=%d", NCYCLES));')
A('    // 复位前先把全部功能输入清零：update 各字段只在 update_valid 那拍被驱动，')
A('    // 不清零的话复位期间它们是 X，会平白把 X 灌进 Composer。')
for n, w in FUNC:
    A(f'    {n} = \'0;')
A('    for (int j = 0; j < NBLK; j++) begin bpat[j] = 8\'($urandom()); phs[j] = 3\'d0; end')
A('    rst = 1; repeat (20) @(posedge clk); rst = 0;')
A('    repeat (NCYCLES) @(posedge clk);')
A('    $display("checks=%0d errors=%0d (errors_x=%0d errors_val=%0d)",')
A('             checks, errors, errors_x, errors_val);')
A('    $display("--- coverage (golden 侧) ---");')
for nm, _, desc in COV:
    A(f'    $display("  {nm:<20s} = %-10d  {desc}", {nm});')
A('    if (errors != 0) begin')
A('      $display("--- 失配直方图（按端口） ---");')
A('      for (int k = 0; k < NOUT; k++)')
A('        if (eh[k] != 0) $display("  %-58s %0d", onm[k], eh[k]);')
A('    end')
A('    begin')
A('      int unsigned zero_cov = 0;')
for nm, _, _ in COV:
    A(f'      if ({nm} == 0) begin zero_cov++; $display("  [COVERAGE FAIL] {nm} 从未发生"); end')
A('      if (errors == 0 && checks > 1000000 && zero_cov == 0) $display("TEST PASSED");')
A('      else begin')
A('        if (zero_cov != 0) $display("=== 覆盖闸不过：%0d 个关键事件计数为 0 ===", zero_cov);')
A('        if (checks <= 1000000) $display("=== checks=%0d 过少，激励没打进去 ===", checks);')
A('        $display("TEST FAILED");')
A('      end')
A('    end')
A('    $finish;')
A('  end')
A('endmodule')
txt = '\n'.join(L) + '\n'
# ★完备性校验★：每根功能输入都必须在 tb 里出现在某条赋值的左边。
# 上一轮踩过「生成器静默漏连整根信号、elaborate 却 0 error 0 warning」的坑
# （commit c408d94），所以这里按构造把它堵死。
missing = [n for n, _ in FUNC if not re.search(r'^\s*' + re.escape(n) + r'\s*=', txt, re.M)]
assert not missing, '未被驱动的功能输入: ' + ', '.join(missing)
missing_m = [n for n, _ in MBIST if not re.search(r'^\s*' + re.escape(n) + r'\s*=', txt, re.M)]
assert not missing_m, '未被驱动的 MBIST 输入: ' + ', '.join(missing_m)
open(OUT, 'w').write(txt)
print(f'{OUT}: {len(ins)} inputs ({len(FUNC)} func + {len(MBIST)} mbist), '
      f'{len(outs)} outputs, {len(COV)} coverage points, {len(L)} lines')
