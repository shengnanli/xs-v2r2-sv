#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'RequestBuffer'
# 每 4000 拍里 1000 拍"拥挤相"：MSHR 约 7/16 有效、全是同一个 set 0 的 A 请求 —— 平均 7 个，正好卡在 8 路门槛边上，
# 让 noFreeWay 在"MSHR 数 + s2 + s3"的各种组合下翻转（s2/s3 那两项因此真的起作用）
CROWD = "((cyc / 1000) % 4 == 0)"
S4 = f"{CROWD} ? 9'h0 : 9'($urandom_range(0, 3))"
TAG4 = "31'($urandom_range(0, 3))"
# 78 个出口字段在 A 请求路径上结构性恒 0（SinkA 不带这些字段；chosenQ 里存的也是 0），只在 chosenQ 整字寄存器
# 上电初值非 0 时翻一次 —— 翻转门限按实测 33 个真会动的输出设
args = ['--target', T, '--min-toggled', f'{T}:33',
        '--narrow', f'{T}:_bits_set$={S4}',
        '--narrow', f'{T}:_bits_(tag|reqTag|metaTag)$={TAG4}',
        '--narrow', f"{T}:io_in_bits_opcode$=(($urandom % 2) == 0) ? 4'($urandom_range(5, 7)) : 4'($urandom)",
        '--narrow', f"{T}:io_mshrInfo_\\d+_valid$={CROWD} ? (($urandom % 16) < 7) : (($urandom % 4) == 0)",
        '--narrow', f"{T}:io_mshrInfo_\\d+_bits_channel$={CROWD} ? 3'h1 : 3'($urandom)",
        '--narrow', f"{T}:io_mainPipeBlock_\\d$=(($urandom % 8) == 0)",
        '--narrow', f"{T}:io_s1Entrance_valid$=(($urandom % 4) == 0)",
        # 不复位寄存器：各调用点的 sameSet_s3、上一拍地址、perf 采样、chosenQ 的整字寄存器
        '--sync', f'{T}:chosenQ.ram=chosenQ.u_core.ram',
        '--sync', f'{T}:io_hasHitPfInMSHR_valid_REG_set=u_core.hitPfPrev_set',
        '--sync', f'{T}:io_hasHitPfInMSHR_valid_REG_tag=u_core.hitPfPrev_tag',
        '--sync', f'{T}:io_hasMergeA_REG_set=u_core.mergeAPrev_set',
        '--sync', f'{T}:io_hasMergeA_REG_tag=u_core.mergeAPrev_tag',
        '--cover', f'{T}:flow=u_g_{T}.io_in_valid && u_g_{T}.doFlow',
        '--cover', f'{T}:alloc=u_g_{T}.alloc_probe',
        '--cover', f'{T}:dup=u_g_{T}._io_hasPfLateInMSHR_valid_T_probe',
        '--cover', f'{T}:mergeA=u_g_{T}.io_aMergeTask_valid',
        '--cover', f'{T}:full=u_g_{T}.full_probe',
        '--cover', f'{T}:cancel=u_g_{T}._GEN_5',
        '--cover', f'{T}:issue=u_g_{T}._GEN_16',
        '--cover', f"{T}:noFreeWay=u_g_{T}.canFlow_sameSetCnt[4:3] != 2'h0"]
sites = ['canFlow_sameSet_s3', 'buffer_rdy_sameSet_s3'] + [f'buffer_{k}_rdy_sameSet_s3' for k in range(4)]
for s, n in enumerate(sites):
    args += ['--sync', f'{T}:{n}_REG=u_core.sameSetS3Valid[{s}]', '--sync', f'{T}:{n}_r=u_core.sameSetS3Set[{s}]']
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
