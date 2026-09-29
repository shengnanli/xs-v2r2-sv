#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T, Q = 'GrantBuffer', 'Queue10_GrantBuffer_Anon'
# 分相：每 2000 拍在"D 通道出得快"与"出得慢"间切换，让 grantQueue 既能排空也能灌到反压门槛
PH = "((cyc / 2000) % 2)"
DREADY = f"{PH} ? (($urandom % 4) != 0) : (($urandom % 4) == 0)"
# opcode：Grant/GrantData 为主（占 inflight 项），夹杂 HintAck（进预取队列）、AccessAck[Data]、ReleaseAck
OPC = "4'($urandom_range(0, 7) < 3 ? 4 : ($urandom_range(0, 7) < 2 ? 5 : ($urandom_range(0, 3) == 0 ? 2 : $urandom_range(0, 6))))"
SMALL9, SMALL31 = "9'($urandom_range(0, 3))", "31'($urandom_range(0, 3))"
args = ['--target', T,
        '--narrow', f'{T}:io_d_task_valid$=(($urandom % 3) == 0)',
        '--narrow', f'{T}:io_d_task_bits_task_opcode$={OPC}',
        '--narrow', f'{T}:io_d_task_bits_task_mergeA$=(($urandom % 8) == 0)',
        '--narrow', f'{T}:io_d_task_bits_task_fromL2pft$=(($urandom % 2) == 0)',
        '--narrow', f'{T}:io_d_task_bits_task_set$={SMALL9}',
        '--narrow', f'{T}:io_d_task_bits_task_tag$={SMALL31}',
        '--narrow', f'{T}:io_fromReqArb_status_s1_sets_1$={SMALL9}',
        '--narrow', f'{T}:io_fromReqArb_status_s1_tags_1$={SMALL31}',
        '--narrow', f'{T}:io_d_ready$={DREADY}',
        # 预取响应出口慢相几乎不收（1/32），让 10 项 pftRespQueue 灌到 9 项门槛（blockMSHR 的预取分支）
        '--narrow', f'{T}:io_prefetchResp_ready$={PH} ? (($urandom % 4) != 0) : (($urandom % 32) == 0)',
        # GrantAck：sink 多半落在 0..15（只看低 4 位），偶尔越界（golden 只断言、照样按低 4 位清）
        '--narrow', f"{T}:io_e_valid$={PH} ? (($urandom % 3) == 0) : (($urandom % 8) == 0)",
        '--narrow', f"{T}:io_e_bits_sink$=(($urandom % 16) == 0) ? 8'($urandom) : 8'($urandom_range(0, 15))",
        # 不复位寄存器（perf RegNext）与三个 child 队列的行为级存储
        '--sync', f'{T}:grantQueue.ram_ext.Memory=>grantQueue.ram_ext.Memory',
        '--sync', f'{T}:grantQueueData0.ram_data_data_ext.Memory=>grantQueueData0.ram_data_data_ext.Memory',
        '--sync', f'{T}:grantQueueData1.ram_data_data_ext.Memory=>grantQueueData1.ram_data_data_ext.Memory',
        '--sync', f'{T}:pftRespQueue.ram_ext.Memory=>pftRespQueue.ram_ext.Memory',
        '--cover', f'{T}:secondBeat=u_g_{T}.grantBufValid',
        '--cover', f'{T}:blockA=u_g_{T}.io_toReqArb_blockSinkReqEntrance_blockA_s1',
        '--cover', f'{T}:blockB=u_g_{T}.io_toReqArb_blockSinkReqEntrance_blockB_s1',
        '--cover', f'{T}:blockC=u_g_{T}.io_toReqArb_blockSinkReqEntrance_blockC_s1',
        '--cover', f'{T}:blockMSHR=u_g_{T}.io_toReqArb_blockMSHRReqEntrance',
        '--cover', f'{T}:pftBlock=u_g_{T}.noSpaceForMSHRPft_probe',
        '--cover', f'{T}:inflightFull=(&{{' + ', '.join(f'u_g_{T}.inflightGrant_{i}_valid' for i in range(16)) + '})',
        '--cover', f'{T}:keyword=u_g_{T}._grantQueue_io_deq_valid && u_g_{T}._grantQueue_io_deq_bits_task_isKeyword',
        '--cover', f'{T}:timerClear=u_g_{T}.REG && !u_g_{T}.inflightGrant_0_valid',
        '--target', Q,
        '--narrow', f'{Q}:io_deq_ready$={DREADY}',
        '--narrow', f'{Q}:io_enq_valid$=(($urandom % 2) == 0)',
        '--sync', f'{Q}:ram_ext.Memory=>ram_ext.Memory',
        '--cover', f'{Q}:full=!u_g_{Q}.io_enq_ready',
        '--cover', f'{Q}:bypass=u_g_{Q}.empty && {Q}__io_enq_valid && {Q}__io_deq_ready']
for i in range(16):
    sfx = '' if i == 0 else f'_{i}'
    args += ['--sync', f'{T}:REG{sfx}=u_core.validPrev[{i}]', '--sync', f'{T}:enable_REG{sfx}=u_core.histValidPrev[{i}]']
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
