#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'MainPipe_1'
S2 = f'{T}:io_taskFromArb_s2_bits_'
# 通道 / TX 通道多半是独热（A=1 B=2 C=4），偶尔乱码
ONEHOT = "3'($urandom_range(0, 7) == 0 ? $urandom_range(0, 7) : (1 << $urandom_range(0, 2)))"
# CHI opcode：snoop 0x01..0x17 / DAT 0x01..0x06 / REQ 写回类 0x0D/0x15/0x17/0x1B/0x42
CHIOP = ("7'($urandom_range(0, 7) == 0 ? ($urandom_range(0, 4) == 0 ? 7'h0D : ($urandom_range(0, 3) == 0 ? 7'h15 : "
         "($urandom_range(0, 2) == 0 ? 7'h1B : ($urandom_range(0, 1) == 0 ? 7'h42 : 7'h17)))) : $urandom_range(0, 23))")
SMALL9, SMALL31 = "9'($urandom_range(0, 3))", "31'($urandom_range(0, 3))"
args = ['--target', T,
        '--narrow', f'{S2}channel$={ONEHOT}',
        '--narrow', f'{S2}txChannel$={ONEHOT}',
        '--narrow', f'{S2}chiOpcode$={CHIOP}',
        '--narrow', f'{S2}set$={SMALL9}',
        '--narrow', f'{S2}tag$={SMALL31}',
        '--narrow', f'{S2}(snpHitRelease|mergeA)$=(($urandom % 4) == 0)',
        '--narrow', f'{T}:io_fromReqArb_status_s1_sets_\\d$={SMALL9}',
        '--narrow', f'{T}:io_fromReqArb_status_s1_tags_1$={SMALL31}',
        '--narrow', f'{T}:io_dirResp_s3_bits_(set)$={SMALL9}',
        '--narrow', f'{T}:io_dirResp_s3_bits_error$=(($urandom % 8) == 0)',
        '--narrow', f'{T}:io_dirResp_s3_bits_meta_(tagErr|dataErr)$=(($urandom % 8) == 0)',
        '--narrow', f'{T}:io_replResp_bits_retry$=(($urandom % 4) == 0)',
        '--narrow', f'{T}:io_toDS_error_s5$=(($urandom % 8) == 0)',
        # 不复位寄存器：两级数据寄存器、"s3 丢弃"打拍、reqDropped 打拍、13 个 perf 两级打拍；CustomL1Hint 两个队列的存储
        '--sync', f'{T}:data_s4=u_core.data_s4',
        '--sync', f'{T}:data_s5=u_core.data_s5',
        '--sync', f'{T}:REG=u_core.s3DropValid_d1',
        '--sync', f'{T}:reqDropped_s5_REG=u_core.reqDrop_s3_d1',
        '--sync', f'{T}:reqDropped_s5_REG_1=u_core.reqDrop_s3_d2',
        '--sync', f'{T}:reqDropped_s5_REG_2=u_core.reqDrop_s4_d1',
        '--sync', f'{T}:customL1Hint.hintQueue.ram_ext.Memory=>customL1Hint.hintQueue.ram_ext.Memory',
        '--sync', f'{T}:customL1Hint.hint_s1Queue.ram_ext.Memory=>customL1Hint.hint_s1Queue.ram_ext.Memory',
        '--cover', f'{T}:alloc=u_g_{T}.io_toMSHRCtl_mshr_alloc_s3_valid',
        '--cover', f'{T}:sinkRespB=u_g_{T}.sink_resp_s3_valid && u_g_{T}.task_s3_bits_channel == 3\'h2',
        '--cover', f'{T}:doRespData=u_g_{T}.task_s3_valid && u_g_{T}.doRespData',
        '--cover', f'{T}:doFwd=u_g_{T}.task_s3_valid && u_g_{T}.doFwd',
        '--cover', f'{T}:d_s3=u_g_{T}.d_s3_valid',
        '--cover', f'{T}:d_s4=u_g_{T}.d_s4_valid',
        '--cover', f'{T}:d_s5=u_g_{T}.d_s5_valid',
        '--cover', f'{T}:txdat_s5=u_g_{T}.txdat_s5_valid',
        '--cover', f'{T}:txreq_s3=u_g_{T}.txreq_s3_valid',
        # txrsp / txreq 在 s4/s5 发是结构性不可达：它们只会在 s3 输掉仲裁时顺延，而 s3 只会输给 s4/s5 上同一出口的
        # 请求 —— 鸡生蛋；需要写 releaseBuf 而留到 s4 的，又被 RegNext(chnl_fire_s3) 屏蔽。这里只覆盖 s3 的 txrsp。
        '--cover', f'{T}:txrsp_s3=u_g_{T}.txrsp_s3_valid',
        '--cover', f'{T}:releaseBuf=u_g_{T}.io_releaseBufWrite_valid',
        '--cover', f'{T}:retry=u_g_{T}._req_drop_s3_T_5_probe && u_g_{T}.task_s3_valid',
        '--cover', f'{T}:errDropped=u_g_{T}.reqDropped_s5',
        '--cover', f'{T}:metaWb=u_g_{T}.task_s3_valid && u_g_{T}.metaW_valid_s3_b',
        '--cover', f'{T}:metaWc=u_g_{T}.task_s3_valid && u_g_{T}.metaW_valid_s3_c',
        '--cover', f'{T}:blockB=u_g_{T}.io_toReqArb_blockB_s1',
        '--cover', f'{T}:hint=u_g_{T}.io_l1Hint_valid']
for k in range(13):
    args += ['--sync', f'{T}:io_perf_{k}_value_REG=u_core.perf_d1[{k}]',
             '--sync', f'{T}:io_perf_{k}_value_REG_1=u_core.perf[{k}]']
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
