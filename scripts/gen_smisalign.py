#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_smisalign.py —— StoreMisalignBuffer 的机械派生区生成器。

产出（幂等）：
  rtl/memblock/StoreMisalignBuffer.sv 里的 GENERATED 段（其余手写区原样保留）：
    GENERATED(nav)      本文件导航
    GENERATED(types)    uop_t 与各接口 struct（字段 = golden 该组端口的字段表），entry_t（= golden req_* 寄存器的字段表）
    GENERATED(regs)     整包寄存器 req（无复位）/ splitStoreReqs_0/1（异步复位）：逐字段同名声明 + 装载 + 读回
    GENERATED(wrapper)  golden 同名 wrapper：端口表逐位照抄，扁平端口 <-> 核的 struct 拆装
  verif/ut/StoreMisalignBuffer/tb.sv  golden vs StoreMisalignBuffer_xs 双例化逐拍比全部输出

引擎与 fail-closed 核对见 scripts/misalign_gen_lib.py（与 gen_lmisalign.py 共用），本文件只是配置。

用法：
  python3 scripts/gen_smisalign.py            # 生成
  python3 scripts/gen_smisalign.py --check    # 产物与生成器不一致则 rc=1
"""
import collections
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from misalign_gen_lib import REPO, Target  # noqa: E402

CFG = dict(
    module='StoreMisalignBuffer',
    pkg='storemisalignbuffer_pkg',
    core='xs_StoreMisalignBuffer_core',
    tag='scripts/gen_smisalign.py',
    rtl=REPO / 'rtl' / 'memblock' / 'StoreMisalignBuffer.sv',
    tb=REPO / 'verif' / 'ut' / 'StoreMisalignBuffer' / 'tb.sv',
    arrays={'exceptionVec': 24},
    groups=[
        ('io_redirect_bits_', 'redirect_t', 'redirect', 'input',
         'Redirect（后端重定向）：本模块只用 robIdx 与 level', None, 1),
        ('io_enq_%d_req_bits_', 'enq_req_t', 'enq_bits[%d]', 'input',
         'MisalignBufferEnqIO.req：StoreUnit 送进来的非对齐 store（LsPipelineBundle 的子集）', 'NUM_ENQ', 2),
        ('io_rob_', 'rob_t', 'rob', 'input',
         'RobLsqIO 里本模块用到的：ROB 头是否是一条等执行的 store（pendingst）及其 robIdx', None, 1),
        ('io_splitStoreReq_bits_', 'split_req_t', 'split_req', 'output',
         'LsPipelineBundle：发回 StoreUnit 的对齐子访问（两个子访问寄存器 splitStoreReqs 也是这个类型）', None, 1),
        ('io_splitStoreResp_bits_', 'split_resp_t', 'split_resp', 'input',
         'SqWriteBundle：子访问的地址结果', None, 1),
        ('io_writeBack_bits_', 'wb_t', 'wb', 'output',
         'MemExuOutput：标量写回（写 ROB）', None, 1),
        ('io_vecWriteBack_%d_bits_', 'vec_wb_t', 'vec_wb[%d]', 'output',
         'VecPipelineFeedbackIO：向量元素写回（按入队口号选口）', 'NUM_VEC_WB', 2),
        ('io_sqControl_toStoreMisalignBuffer_', 'sq_to_mab_t', 'sq_in', 'input',
         'StoreQueue → 本缓冲：出队许可 doDeq、当前出队指针、它正在处理的 uop', None, 1),
        ('io_sqControl_toStoreQueue_', 'sq_to_sq_t', 'sq_out', 'output',
         '本缓冲 → StoreQueue：跨页条目的出队配合', None, 1),
    ],
    scalars=collections.OrderedDict([
        ('clock', 'clock'), ('reset', 'reset'),
        ('io_redirect_valid', 'redirect_valid'),
        ('io_enq_0_req_valid', 'enq_valid[0]'), ('io_enq_1_req_valid', 'enq_valid[1]'),
        ('io_enq_0_req_ready', 'enq_ready[0]'), ('io_enq_1_req_ready', 'enq_ready[1]'),
        ('io_enq_0_revoke', 'enq_revoke[0]'), ('io_enq_1_revoke', 'enq_revoke[1]'),
        ('io_splitStoreReq_ready', 'split_req_ready'), ('io_splitStoreReq_valid', 'split_req_valid'),
        ('io_splitStoreResp_valid', 'split_resp_valid'),
        ('io_writeBack_ready', 'wb_ready'), ('io_writeBack_valid', 'wb_valid'),
        ('io_vecWriteBack_0_valid', 'vec_wb_valid[0]'), ('io_vecWriteBack_1_valid', 'vec_wb_valid[1]'),
        ('io_storeOutValid', 'store_out_valid'), ('io_storeVecOutValid', 'store_vec_out_valid'),
        ('io_toVecSplit_empty', 'to_vec_split_empty'),
    ]),
    vec_counts={'enq_valid': 'NUM_ENQ', 'enq_ready': 'NUM_ENQ', 'enq_revoke': 'NUM_ENQ',
                'vec_wb_valid': 'NUM_VEC_WB'},
    uop_order=[3, 1, 4, 5, 7, 0, 2, 6, 8],
    reg_structs=[
        ('entry_t', 'req_',
         '条目本体 req（StoreMisalignBufferEntry = LsPipelineBundle + portIndex）：字段 = golden 留下的 req_* 寄存器'),
    ],
    pack_regs=[
        ('req_', 'entry_t', 'req', 'req_nxt', False, None,
         'req：入队 / 顶替时整包锁存，子访问异常时改写地址字段（无复位；次态 req_nxt 见 §5）'),
        ('splitStoreReqs_0_', 'split_req_t', 'split_reqs[0]', 'split_new[0]', True, 'split_now',
         'splitStoreReqs(0)：低地址那一半子访问（异步复位为 0；s_split 且跨 16B 时写入，见 §3）'),
        ('splitStoreReqs_1_', 'split_req_t', 'split_reqs[1]', 'split_new[1]', True, 'split_now',
         'splitStoreReqs(1)：高地址那一半子访问（同上）'),
    ],
    pack_exclude={'req_valid'},
    nav=[
        ('storemisalignbuffer_pkg：常量、状态编码、接口 struct、拆分方案表与小工具函数',
         r'^  // ---------------- 常量 ----------------'),
        ('xs_StoreMisalignBuffer_core —— 可读核：全部状态', r'^// xs_StoreMisalignBuffer_core —— 可读核'),
        ('§1 入队（两口选最老 / revoke / 跨页顶替）', r'^  // §1 入队'),
        ('§2 状态机', r'^  // §2 状态机'),
        ('§3 拆分成两个对齐子访问', r'^  // §3 拆分'),
        ('§4 发请求', r'^  // §4 发请求'),
        ('§5 收响应：异常 / uncache / replay', r'^  // §5 收响应'),
        ('§6 写回与 StoreQueue 控制', r'^  // §6 写回'),
        ('§7 整包寄存器（生成）', r'^  // §7 整包寄存器'),
        ('golden 同名 wrapper（生成）', r'^// golden 同名 wrapper —— 端口逐位照抄'),
    ],
)

if __name__ == '__main__':
    sys.exit(Target(CFG).main(sys.argv[1:]))
