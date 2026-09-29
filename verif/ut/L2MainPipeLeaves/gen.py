#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
DEQ = "((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 4) == 0)"
args = []
for a in ('Arbiter3_CHIREQ', 'Arbiter3_TaskBundle', 'Arbiter3_TaskWithData'):
    args += ['--target', a,
             # 各路 valid 1/2：三路同时请求、只有低优先级在请求、都不请求（出口给末路载荷）都常见
             '--narrow', f'{a}:io_in_\\d_valid$=(($urandom % 2) == 0)',
             '--cover', f'{a}:only2=!{a}__io_in_0_valid && !{a}__io_in_1_valid && {a}__io_in_2_valid',
             '--cover', f'{a}:all={a}__io_in_0_valid && {a}__io_in_1_valid && {a}__io_in_2_valid']
for q, r in (('Queue16_HintQueueEntry', 'ram_ext'), ('Queue4_HintQueueEntry', 'ram_ext')):
    args += ['--target', q, '--narrow', f'{q}:io_deq_ready$={DEQ}',
             '--sync', f'{q}:{r}.Memory=>{r}.Memory',
             '--cover', f'{q}:full=!u_g_{q}.io_enq_ready',
             '--cover', f'{q}:deq=u_g_{q}.do_deq']
args += ['--cover', 'Queue4_HintQueueEntry:bypass=u_g_Queue4_HintQueueEntry.empty && '
         'Queue4_HintQueueEntry__io_enq_valid && Queue4_HintQueueEntry__io_deq_ready']
C = 'CustomL1Hint'
# opcode 偏向 Grant/GrantData/Release/ReleaseData；channel 取 A(1)/C(4) 为主；出口 ready 分相让 hintQueue 能灌满
OPC4 = "4'($urandom_range(0, 3) == 0 ? $urandom_range(0, 15) : $urandom_range(4, 7))"
CHN = "3'($urandom_range(0, 3) == 0 ? $urandom_range(0, 7) : (($urandom % 2) ? 1 : 4))"
args += ['--target', C,
         '--narrow', f'{C}:io_s1_bits_opcode$={OPC4}',
         '--narrow', f'{C}:io_s3_task_bits_opcode$={OPC4}',
         '--narrow', f"{C}:io_s1_bits_aMergeTask_opcode$=3'($urandom_range(3, 6))",
         '--narrow', f'{C}:io_s1_bits_channel$={CHN}',
         '--narrow', f'{C}:io_s3_task_bits_channel$={CHN}',
         # 慢相几乎不收（1/32），让 16 项 hintQueue 灌满、进而把 4 项 hint_s1Queue 也顶满（golden 只断言、不反压）
         '--narrow', f'{C}:io_l1Hint_ready$=((cyc / 2000) % 2) ? (($urandom % 4) != 0) : (($urandom % 32) == 0)',
         '--sync', f'{C}:hintQueue.ram_ext.Memory=>hintQueue.ram_ext.Memory',
         '--sync', f'{C}:hint_s1Queue.ram_ext.Memory=>hint_s1Queue.ram_ext.Memory',
         '--cover', f'{C}:hint=u_g_{C}.io_l1Hint_valid',
         '--cover', f'{C}:s3wins=u_g_{C}.enqValid_s3 && u_g_{C}._hint_s1Queue_io_deq_valid',
         '--cover', f'{C}:s1full=!u_g_{C}._hint_s1Queue_io_enq_ready',
         '--cover', f'{C}:hqfull=!u_g_{C}._hintQueue_io_enq_ready',
         '--cover', f'{C}:mergeGrant=u_g_{C}.mshr_Grant_s1 && u_g_{C}.io_s1_bits_mergeA']
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
