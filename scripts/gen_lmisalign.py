#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_lmisalign.py —— LoadMisalignBuffer 的机械派生区生成器。

产出（幂等）：
  rtl/memblock/LoadMisalignBuffer.sv 里的 GENERATED 段（其余手写区原样保留）：
    GENERATED(nav)      本文件导航（行号由锚点机械定位）
    GENERATED(types)    uop_t / redirect_t / enq_req_t / split_req_t / split_resp_t / wb_t / vec_wb_t
                        —— 每个接口 struct 的字段 = golden 该组端口的字段表（uop_t = 各组 uop 字段并集）
    GENERATED(regs)     整包寄存器 req（无复位）/ splitLoadReqs_0/1（异步复位）：逐字段声明 + 装载 + 读回成 struct
                        —— 留哪些字段由 golden 的 reg 声明决定（firtool DCE 的结果，不能从 Chisel 推）
    GENERATED(wrapper)  golden 同名 wrapper：端口表逐位照抄 golden，扁平端口 <-> 核的 struct 拆装
  verif/ut/LoadMisalignBuffer/tb.sv  golden vs LoadMisalignBuffer_xs 双例化逐拍比全部输出

fail-closed 核对（任何一项不符拒绝生成）：
  1. 每个 golden 端口恰好归属一个接口组或一个标量口；三个 enq 口字段表完全一致；
  2. 整包寄存器组里每个 golden 寄存器都能映射到对应 struct 的同宽成员；
  3. golden 寄存器全集 == 生成的整包寄存器 ∪ 核手写区声明的同名寄存器（逐名、逐位宽）。

引擎在 scripts/misalign_gen_lib.py（与 gen_smisalign.py 共用），本文件只是 LoadMisalignBuffer 的配置。

用法：
  python3 scripts/gen_lmisalign.py            # 生成
  python3 scripts/gen_lmisalign.py --check    # 产物与生成器不一致则 rc=1
"""
import collections
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from misalign_gen_lib import REPO, Target  # noqa: E402

CFG = dict(
    module='LoadMisalignBuffer',
    pkg='loadmisalignbuffer_pkg',
    core='xs_LoadMisalignBuffer_core',
    tag='scripts/gen_lmisalign.py',
    rtl=REPO / 'rtl' / 'memblock' / 'LoadMisalignBuffer.sv',
    tb=REPO / 'verif' / 'ut' / 'LoadMisalignBuffer' / 'tb.sv',
    # golden 展平成 <name>_<i> 的向量字段，struct 里收成一个打包向量 <name>[N-1:0]
    arrays={'exceptionVec': 24, 'rep_info_cause': 11},
    # 接口组：(golden 端口前缀, struct 类型, 核端信号名, 方向, 说明, 个数表达式, 个数)
    groups=[
        ('io_redirect_bits_', 'redirect_t', 'redirect', 'input',
         'Redirect（后端重定向）：本模块只用 robIdx 与 level', None, 1),
        ('io_enq_%d_req_bits_', 'enq_req_t', 'enq_bits[%d]', 'input',
         'MisalignBufferEnqIO.req：LoadUnit s3 送进来的非对齐 load（LqWriteBundle 的子集），也是条目本体 req 的类型',
         'NUM_ENQ', 3),
        ('io_splitLoadReq_bits_', 'split_req_t', 'split_req', 'output',
         'LsPipelineBundle：发回 LoadUnit s0 的对齐子访问（两个子访问寄存器 splitLoadReqs 也是这个类型）', None, 1),
        ('io_splitLoadResp_bits_', 'split_resp_t', 'split_resp', 'input',
         'LqWriteBundle：子访问从 LoadUnit s3 回来的结果', None, 1),
        ('io_writeBack_bits_', 'wb_t', 'wb', 'output',
         'MemExuOutput：标量写回（写 ROB / 唤醒）', None, 1),
        ('io_vecWriteBack_bits_', 'vec_wb_t', 'vec_wb', 'output',
         'VecPipelineFeedbackIO：向量元素写回（送向量合并缓冲）', None, 1),
    ],
    # 标量口：golden 名 -> 核端口名
    scalars=collections.OrderedDict([
        ('clock', 'clock'), ('reset', 'reset'),
        ('io_redirect_valid', 'redirect_valid'),
        ('io_enq_0_req_valid', 'enq_valid[0]'), ('io_enq_1_req_valid', 'enq_valid[1]'),
        ('io_enq_2_req_valid', 'enq_valid[2]'),
        ('io_enq_0_req_ready', 'enq_ready[0]'), ('io_enq_1_req_ready', 'enq_ready[1]'),
        ('io_enq_2_req_ready', 'enq_ready[2]'),
        ('io_splitLoadReq_ready', 'split_req_ready'), ('io_splitLoadReq_valid', 'split_req_valid'),
        ('io_splitLoadResp_valid', 'split_resp_valid'),
        ('io_writeBack_ready', 'wb_ready'), ('io_writeBack_valid', 'wb_valid'),
        ('io_vecWriteBack_valid', 'vec_wb_valid'),
        ('io_loadOutValid', 'load_out_valid'), ('io_loadVecOutValid', 'load_vec_out_valid'),
    ]),
    vec_counts={'enq_valid': 'NUM_ENQ', 'enq_ready': 'NUM_ENQ'},
    # uop_t 字段顺序：以 splitLoadReq 组（字段最全）为主，其余组补充
    uop_order=[2, 1, 3, 4, 5, 0],
    reg_structs=[],
    # 整包寄存器：(golden 前缀, struct 类型, 读回变量, 次态表达式, 复位, 使能, 说明)
    pack_regs=[
        ('req_', 'enq_req_t', 'req', 'req_nxt', False, None,
         'req：入队时整包锁存，子访问异常时改写地址字段（无复位；次态 req_nxt 见 §5）'),
        ('splitLoadReqs_0_', 'split_req_t', 'split_reqs[0]', 'split_new[0]', True, 'split_now',
         'splitLoadReqs(0)：低地址那一半子访问（异步复位为 0；s_split 且跨 16B 时写入，见 §3）'),
        ('splitLoadReqs_1_', 'split_req_t', 'split_reqs[1]', 'split_new[1]', True, 'split_now',
         'splitLoadReqs(1)：高地址那一半子访问（同上）'),
    ],
    # 前缀撞上但不属于整包的寄存器（核里手写）
    pack_exclude={'req_valid'},
    nav=[
        ('loadmisalignbuffer_pkg：常量、状态编码、接口 struct、拆分方案表与小工具函数',
         r'^  // ---------------- 常量 ----------------'),
        ('xs_LoadMisalignBuffer_core —— 可读核：全部状态', r'^// xs_LoadMisalignBuffer_core —— 可读核'),
        ('§1 入队', r'^  // §1 入队'),
        ('§2 状态机', r'^  // §2 状态机'),
        ('§3 拆分成两个对齐子访问', r'^  // §3 拆分'),
        ('§4 发请求', r'^  // §4 发请求'),
        ('§5 收响应：异常 / uncache / replay', r'^  // §5 收响应'),
        ('§6 结果拼接', r'^  // §6 结果拼接'),
        ('§7 写回', r'^  // §7 写回'),
        ('§8 整包寄存器（生成）', r'^  // §8 整包寄存器'),
        ('golden 同名 wrapper（生成）', r'^// golden 同名 wrapper —— 端口逐位照抄'),
    ],
)

if __name__ == '__main__':
    sys.exit(Target(CFG).main(sys.argv[1:]))
