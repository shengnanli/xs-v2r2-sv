#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'TXDAT'
OUTRDY = "((cyc / 3000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0)"
OPC = "(($urandom % 4) == 0) ? 7'h02 : ((($urandom % 3) == 0) ? 7'h07 : 7'($urandom))"
args = ['--target', T,
        '--narrow', f'{T}:io_out_ready$={OUTRDY}',
        '--narrow', f'{T}:io_in_bits_task_chiOpcode$={OPC}',
        '--narrow', f"{T}:io_in_bits_task_resp$=(($urandom % 2) == 0) ? 3'h0 : 3'($urandom)",
        # 三个队列的 ram 不复位：首沿前把 golden 的 Memory 抄给重写侧（实例路径两侧相同）
        '--sync', f'{T}:queue.ram_ext.Memory=>queue.ram_ext.Memory',
        '--sync', f'{T}:queueData0.ram_data_ext.Memory=>queueData0.ram_data_ext.Memory',
        '--sync', f'{T}:queueData1.ram_data_ext.Memory=>queueData1.ram_data_ext.Memory',
        '--cover', f'{T}:take=u_g_{T}._GEN_0',
        '--cover', f'{T}:beat1=u_g_{T}.io_out_valid && u_g_{T}.io_out_ready && !u_g_{T}.beatValids_0',
        '--cover', f'{T}:deassert=u_g_{T}.io_out_valid && u_g_{T}.io_out_bits_deassertBE',
        '--cover', f'{T}:blkSnp=u_g_{T}.io_toReqArb_blockSinkBReqEntrance',
        '--cover', f'{T}:notBlk=!u_g_{T}.io_toReqArb_blockMSHRReqEntrance',
        # 流水线 4 路同时在飞（PopCount 2 位截断成 0 的那个 bug-for-bug 场景）
        '--cover', f'{T}:pipe4=u_g_{T}._inflightCnt_T_30 == u_g_{T}._queue_io_count && u_g_{T}.io_pipeStatusVec_1_valid && u_g_{T}.io_pipeStatusVec_2_valid && u_g_{T}.io_pipeStatusVec_3_valid && u_g_{T}.io_pipeStatusVec_4_valid && u_g_{T}.io_pipeStatusVec_2_bits_txChannel[2] && u_g_{T}.io_pipeStatusVec_3_bits_txChannel[2] && u_g_{T}.io_pipeStatusVec_4_bits_txChannel[2] && u_g_{T}.io_pipeStatusVec_2_bits_mshrTask && u_g_{T}.io_pipeStatusVec_3_bits_mshrTask && u_g_{T}.io_pipeStatusVec_4_bits_mshrTask',
        '--cover', f'{T}:blkMshrOnly=u_g_{T}.io_toReqArb_blockMSHRReqEntrance && !u_g_{T}.io_toReqArb_blockSinkBReqEntrance']
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
