#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'SinkC'
# 地址：tag 取 0..1、set 取 0..1（让与 MSHR 的同地址比较能命中），其余位随机
ADDR = "{30'h0, 1'($urandom), 8'h0, 1'($urandom), 8'($urandom)}"
# 翻转门限按 initreg 0 档实测 29 设：io_task_bits_* 里 82 个字段在 Release 路径上结构性恒 0（SinkC 只填
# channel/opcode/param/size/sourceId/set/tag/off/bufIdx 等少数字段，其余 WireInit(0)），只有 taskBuf 表项上电初值非 0
# 时才会翻一次（initreg random 档偶尔凑满 111）。FM 的 Constant reg 1232 就是这批位。
args = ['--target', T, '--min-toggled', f'{T}:29',
        # opcode 偏向 4..7（ProbeAck/ProbeAckData/Release/ReleaseData），size 偏向 6（整块两拍）
        '--narrow', f"{T}:io_c_bits_opcode$=(($urandom % 8) != 0) ? 3'($urandom_range(4, 7)) : 3'($urandom)",
        '--narrow', f"{T}:io_c_bits_size$=(($urandom % 4) != 0) ? 3'h6 : 3'($urandom)",
        '--narrow', f'{T}:io_c_bits_address$={ADDR}',
        '--narrow', f"{T}:io_msInfo_\\d+_bits_set$=9'($urandom_range(0, 1))",
        '--narrow', f"{T}:io_msInfo_\\d+_bits_reqTag$=31'($urandom_range(0, 1))",
        '--narrow', f"{T}:io_msInfo_\\d+_valid$=(($urandom % 4) == 0)",
        # 不复位寄存器（golden 名 -> 重写名）
        '--sync', f'{T}:r_0=u_core.bufRespStage[0]', '--sync', f'{T}:r_1=u_core.bufRespStage[1]',
        '--sync', f'{T}:REG_0=u_core.bufRespOut[0]', '--sync', f'{T}:REG_1=u_core.bufRespOut[1]',
        '--sync', f'{T}:io_refillBufWrite_bits_id_REG=u_core.refillIdReg',
        '--sync', f'{T}:io_refillBufWrite_bits_data_data_REG=u_core.refillBufIdxReg',
        '--sync', f'{T}:REG_1_0=u_core.taskFirePrev', '--sync', f'{T}:REG_2=u_core.taskBufIdxPrev',
        '--cover', f'{T}:full=u_g_{T}.full_probe',
        '--cover', f'{T}:stall=u_g_{T}.stall_probe',
        '--cover', f'{T}:task=u_g_{T}.io_task_valid && u_g_{T}.io_task_ready',
        '--cover', f'{T}:refill=u_g_{T}.io_refillBufWrite_valid',
        '--cover', f'{T}:pAckData=u_g_{T}.io_releaseBufWrite_valid',
        '--cover', f'{T}:twoBeat=u_g_{T}.r_counter']
GEN = os.path.join(HERE, '../../../scripts/gen_l2slice_ut.py')
TB = os.path.join(HERE, 'tb.sv')
if '--check' in sys.argv[1:]:
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, 'tb.sv')
        rc = subprocess.call([sys.executable, GEN, '--out', out] + args, stdout=subprocess.DEVNULL)
        ok = rc == 0 and os.path.exists(TB) and filecmp.cmp(out, TB, shallow=False)
    print(('OK: ' if ok else 'DRIFT: ') + TB)
    sys.exit(0 if ok else 1)
sys.exit(subprocess.call([sys.executable, GEN, '--out', TB] + args))
