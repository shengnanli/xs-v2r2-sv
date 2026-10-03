#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'RequestArb'
CHIOP = "(($urandom % 2) == 0) ? 7'($urandom) : (($urandom % 4) == 0 ? 7'h1B : ($urandom % 3) == 0 ? 7'h15 : ($urandom % 2) ? 7'h42 : 7'h0D)"
args = ['--target', T,
        # 各类挡请求信号 1/8 概率拉高，让任务能流动
        '--narrow', f"{T}:io_from\\w+_block\\w+$=(($urandom % 8) == 0)",
        '--narrow', f"{T}:io_\\w+_bits_chiOpcode$={CHIOP}",
        # 让 MSHR 回填类 opcode（AccessAckData/HintAck/Grant/GrantData = 1/2/4/5）常出现
        '--narrow', f"{T}:io_\\w+_bits_opcode$=(($urandom % 2) == 0) ? 4'($urandom_range(1, 5)) : 4'($urandom)",
        '--narrow', f"{T}:io_\\w+_bits_set$=9'($urandom_range(0, 3))",
        # 唯一不复位寄存器：DS 两拍一访问的 stall 位
        '--sync', f'{T}:ds_mcp2_stall=u_core.ds_mcp2_stall',
        '--cover', f'{T}:s0=u_g_{T}.s0_fire_probe',
        '--cover', f'{T}:s1=u_g_{T}.s1_fire',
        '--cover', f'{T}:replRead=u_g_{T}.s1_needs_replRead',
        '--cover', f'{T}:selC=u_g_{T}.io_sinkC_ready && u_g_{T}.io_sinkC_valid',
        '--cover', f'{T}:selB=u_g_{T}.io_sinkB_ready && u_g_{T}.io_sinkB_valid',
        '--cover', f'{T}:selA=u_g_{T}.io_sinkA_ready && u_g_{T}.io_sinkA_valid',
        '--cover', f'{T}:refillBuf=u_g_{T}.io_refillBufRead_s2_valid',
        '--cover', f'{T}:releaseBuf=u_g_{T}.io_releaseBufRead_s2_valid',
        '--cover', f'{T}:initDone=u_g_{T}.resetFinish']
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
