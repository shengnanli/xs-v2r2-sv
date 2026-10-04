#!/usr/bin/env python3
"""gen_l2top.py —— 生成 rtl/l2/L2Top.sv 的 golden 同名 wrapper 区（手写核 xs_L2Top_core 一个字节都不动）。

L2Top（src/main/scala/xiangshan/L2Top.scala）= 21 个已签核 child + 核 ↔ Tile 之间的打拍。打拍全在手写核里；
本脚本只生成 GENERATED(l2top-wrapper) 区。生成规则（fail-closed）的实现在 scripts/parent_wrapper_lib.py，
与 scripts/gen_tl2chi.py 共用：child 按 golden 实例名 / 顺序例化；每个 child 输入、每个顶层输出必须恰好有一个
来源（golden 的简单连线照接，golden 写了表达式 / 本层寄存器的必须落在下面的核规则里）；核的每个输入都要有来源、
每个输出都要被用到；规则表里每一条都要被用到。

用法：python3 scripts/gen_l2top.py [--check]
  --check：不写文件，只比较生成结果与库里文件是否逐字相同（漂移 → rc=1）。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parent_wrapper_lib as lib  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, 'rtl', 'l2', 'L2Top.sv')
TOP = 'L2Top'
CORE = 'xs_L2Top_core'
TAG = 'l2top-wrapper'
NG = 3            # trace 组数
PARAMS = {'TRACE_GROUPS': NG}

TR_IN = 'io_traceCoreInterface_fromCore_toEncoder_'
TR_OUT = 'io_traceCoreInterface_toTile_toEncoder_'


def per_group(fmt):
    return [('[%d]' % i, fmt.format(i=i)) for i in range(NG)]


# 核的输入来源：核端口 -> 顶层输入 / child 输出（<实例名>.<端口名>）
CORE_GATHER = {
    'clock': 'clock', 'reset': 'reset',
    'msiFromTile_valid': 'io_msiInfo_fromTile_valid',
    'msiFromTile_bits': 'io_msiInfo_fromTile_bits',
    'cpuHaltFromCore': 'io_cpu_halt_fromCore',
    'criticalErrorFromCore': 'io_cpu_critical_error_fromCore',
    'l3MissFromTile': 'io_l3Miss_fromTile',
    'traceIn_priv': TR_IN + 'priv',
    'traceIn_mstatus': TR_IN + 'mstatus',
    'traceIn_trapCause': TR_IN + 'trap_cause',
    'traceIn_trapTval': TR_IN + 'trap_tval',
    'traceIn_valid': per_group(TR_IN + 'groups_{i}_valid'),
    'traceIn_iaddr': per_group(TR_IN + 'groups_{i}_bits_iaddr'),
    'traceIn_itype': per_group(TR_IN + 'groups_{i}_bits_itype'),
    'traceIn_iretire': per_group(TR_IN + 'groups_{i}_bits_iretire'),
    'traceIn_ilastsize': per_group(TR_IN + 'groups_{i}_bits_ilastsize'),
    'encoderIn_enable': 'io_traceCoreInterface_toTile_fromEncoder_enable',
    'encoderIn_stall': 'io_traceCoreInterface_toTile_fromEncoder_stall',
    'resetInFrontend': 'io_hartIsInReset_resetInFrontend',
    'l2ErrorAddr': 'inner_l2cache.io_error_address',
}

# golden 在 child 输入上写了表达式的地方 → 核输出
CORE_DRIVES = {
    ('inner_beu', 'io_errors_l2_ecc_error_bits'): 'beuL2ErrorAddr',
}

# 顶层输出里接本层寄存器的 → 核输出
CORE_TOP_DRIVES = {
    'io_msiInfo_toCore_valid': 'msiToCore_valid',
    'io_msiInfo_toCore_bits': 'msiToCore_bits',
    'io_cpu_halt_toTile': 'cpuHaltToTile',
    'io_cpu_critical_error_toTile': 'criticalErrorToTile',
    'io_l3Miss_toCore': 'l3MissToCore',
    'io_hartIsInReset_toTile': 'hartIsInReset',
    'io_traceCoreInterface_fromCore_fromEncoder_enable': 'encoderOut_enable',
    'io_traceCoreInterface_fromCore_fromEncoder_stall': 'encoderOut_stall',
    TR_OUT + 'priv': 'traceOut_priv',
    TR_OUT + 'mstatus': 'traceOut_mstatus',
    TR_OUT + 'trap_cause': 'traceOut_trapCause',
    TR_OUT + 'trap_tval': 'traceOut_trapTval',
}
for _i in range(NG):
    CORE_TOP_DRIVES[TR_OUT + 'groups_%d_valid' % _i] = 'traceOut_valid[%d]' % _i
    CORE_TOP_DRIVES[TR_OUT + 'groups_%d_bits_iaddr' % _i] = 'traceOut_iaddr[%d]' % _i
    CORE_TOP_DRIVES[TR_OUT + 'groups_%d_bits_itype' % _i] = 'traceOut_itype[%d]' % _i
    CORE_TOP_DRIVES[TR_OUT + 'groups_%d_bits_iretire' % _i] = 'traceOut_iretire[%d]' % _i
    CORE_TOP_DRIVES[TR_OUT + 'groups_%d_bits_ilastsize' % _i] = 'traceOut_ilastsize[%d]' % _i

SPEC = lib.Spec(top=TOP, core=CORE, out=OUT, tag=TAG, params=PARAMS, gather=CORE_GATHER,
                drives=CORE_DRIVES, top_drives=CORE_TOP_DRIVES, name='gen_l2top')

if __name__ == '__main__':
    sys.exit(lib.main(SPEC, sys.argv[1:]))
