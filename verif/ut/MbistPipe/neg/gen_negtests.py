#!/usr/bin/env python3
"""必失败负测：证明 xs_mbist_pipe_core 的 elaborate 期不变量真的会拦下错参数。

判据不是自证的：每个用例的"正确值"都是**现场从 G1 golden 读出来的**
（scripts/gen_mbist_pipe_family.parse_golden），负例只是在这个真值上做一处扰动。
先跑一个未扰动的正对照，证明失败不是因为"什么都编不过"。
"""
import os, sys, subprocess, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'scripts'))
import gen_mbist_pipe_family as F   # noqa: E402

CORE = os.path.join(REPO, 'rtl', 'dft', 'xs_mbist_pipe_core.sv')
WORK = os.path.join(HERE, 'work')

# 取一个真实变体作为基准：MbistPipeIttage_3（2 个 child，id 0x50/0x51，ARRAY_W=7）
BASE = 'MbistPipeIttage_3'


def params_from_golden(mod):
    R = F.parse_golden(mod)
    F.check_invariants(R)
    return dict(
        IS_NODE=0 if R['kind'] == 'leaf' else 1,
        N_CHILD=R['nchild'],
        ARRAY_W=R['ARRAY_W'], BE_W=R['BE_W'], ADDR_W=R['ADDR_W'], DATA_W=R['DATA_W'],
        ID_LO=[c['ids'][0] for c in R['child']],
        ID_CNT=[len(c['ids']) for c in R['child']],
        MAX_IDS=max(len(c['ids']) for c in R['child']),
    )


def emit(p, name):
    return '''// 自动生成的负测用例：{name}
module {name}_top;
  logic clock = 0, reset = 1;
  logic [{aw}:0] a; logic [{bw}:0] be; logic [{ad}:0] ad; logic [{dw}:0] di;
  logic ack; logic [{dw}:0] od;
  logic [{aw}:0] ch_array [{n}]; logic ch_all [{n}]; logic ch_reqpulse [{n}];
  logic ch_writeen [{n}]; logic [{bw}:0] ch_wmask [{n}]; logic [{ad}:0] ch_addr [{n}];
  logic [{dw}:0] ch_wdata [{n}]; logic ch_readen [{n}]; logic [{ad}:0] ch_addr_rd [{n}];
  logic [{oh}:0] ch_selectedOH [{n}]; logic [{dw}:0] ch_rdata [{n}]; logic ch_ack [{n}];
  xs_mbist_pipe_core #(
    .IS_NODE (1'b{is_node}), .N_CHILD ({n}), .ARRAY_W ({ARRAY_W}), .BE_W ({BE_W}),
    .ADDR_W ({ADDR_W}), .DATA_W ({DATA_W}),
    .ID_LO ('{{{id_lo}}}), .ID_CNT ('{{{id_cnt}}}), .MAX_IDS ({MAX_IDS})
  ) u (
    .clock(clock), .reset(reset), .mbist_array(a), .mbist_all(1'b0), .mbist_req(1'b0),
    .mbist_ack(ack), .mbist_writeen(1'b0), .mbist_be(be), .mbist_addr(ad),
    .mbist_indata(di), .mbist_readen(1'b0), .mbist_addr_rd(ad), .mbist_outdata(od),
    .ch_array(ch_array), .ch_all(ch_all), .ch_reqpulse(ch_reqpulse),
    .ch_writeen(ch_writeen), .ch_wmask(ch_wmask), .ch_addr(ch_addr),
    .ch_wdata(ch_wdata), .ch_readen(ch_readen), .ch_addr_rd(ch_addr_rd),
    .ch_selectedOH(ch_selectedOH), .ch_rdata(ch_rdata), .ch_ack(ch_ack)
  );
  initial begin $display("ELAB_OK"); $finish; end
endmodule
'''.format(name=name, n=p['N_CHILD'], aw=p['ARRAY_W'] - 1, bw=p['BE_W'] - 1,
           ad=p['ADDR_W'] - 1, dw=p['DATA_W'] - 1, oh=p['MAX_IDS'] - 1,
           is_node=p['IS_NODE'],
           id_lo=', '.join(str(x) for x in p['ID_LO']),
           id_cnt=', '.join(str(x) for x in p['ID_CNT']),
           **{k: p[k] for k in ('ARRAY_W', 'BE_W', 'ADDR_W', 'DATA_W', 'MAX_IDS')})


def run(name, p):
    os.makedirs(WORK, exist_ok=True)
    simv = os.path.join(WORK, name + '.simv')
    if os.path.exists(simv):
        shutil.rmtree(simv, ignore_errors=True) if os.path.isdir(simv) else os.remove(simv)
    src = os.path.join(WORK, name + '.sv')
    open(src, 'w').write(emit(p, name))
    env = dict(os.environ, VCS_ARCH_OVERRIDE='linux')
    r = subprocess.run(['vcs', '-full64', '-sverilog', CORE, src, '-top', name + '_top',
                        '-o', os.path.join(WORK, name + '.simv'),
                        '-l', os.path.join(WORK, name + '.log')],
                       cwd=WORK, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # ★VCS 在 elaborate 期消息里会把 UTF-8 的 0xAE 字节吞掉，日志因此不是合法
    # UTF-8（认/宽/算/定/实/家/容/据/目/宏/段 这些字都中招）。用 replace 读，
    # 真正的修法是不在 elaborate 期 $fatal 文本里用这些字，见 check_fatal_bytes。
    log = open(os.path.join(WORK, name + '.log'), errors='replace').read()
    return r.returncode, log


def main():
    good = params_from_golden(BASE)
    print('基准参数（现场从 G1 golden %s 读出）：%s' % (BASE, good))
    fails = 0

    rc, log = run('neg_control', good)
    if ('Error-[FEST]' in log) or (not os.path.exists(os.path.join(WORK, 'neg_control.simv'))):
        print('!! 正对照编不过 —— 负测无意义'); print(log[-2000:]); return 1
    print('[POS ] neg_control            : 未扰动参数 elaborate 通过（正对照成立，simv 产出了）')

    cases = []
    p = dict(good); p['ARRAY_W'] = good['ARRAY_W'] - 1
    cases.append(('neg_array_w', p, 'ARRAY_W=%d' % p['ARRAY_W'], '由最大 id 求得'))
    p = dict(good); p['ID_LO'] = [good['ID_LO'][0], good['ID_LO'][1] + 1]
    cases.append(('neg_id_gap', p, 'ID_LO 第二个 child +1 造出空洞', '首尾相接'))
    p = dict(good); p['ID_CNT'] = [good['ID_CNT'][0], 0]
    cases.append(('neg_id_zero', p, 'ID_CNT 有 0', '至少要负责一个'))
    p = dict(good); p['MAX_IDS'] = good['MAX_IDS'] + 1
    cases.append(('neg_max_ids', p, 'MAX_IDS=%d（真值 %d）' % (good['MAX_IDS'] + 1, good['MAX_IDS']), 'selectedOH 位数'))

    for name, p, what, expect in cases:
        rc, log = run(name, p)
        # ★判据不能用 rc★：VCS 对 elaborate 期 $fatal 的退出码并不稳定（另一位
        # owner 实测拿到过 0），按 rc 判会报出假的"负测没牙齿"。按日志内容判：
        # 必须出现 Error-[FEST]（elaborate 期系统任务），且必须**没有**产出 simv，
        # 且消息文本要命中本条不变量的关键字。
        fest = 'Error-[FEST]' in log
        nosimv = not os.path.exists(os.path.join(WORK, name + '.simv'))
        hit = expect in log
        ok = fest and nosimv and hit
        if not ok:
            fails += 1
        line = [l for l in log.splitlines() if 'xs_mbist_pipe_core:' in l]
        print('[%s] %-22s: 扰动=%s' % ('PASS' if ok else 'FAIL', name, what))
        print('        Error-[FEST]=%s  simv 未产出=%s  关键字命中=%s  (rc=%d, 仅供参考)'
              % (fest, nosimv, hit, rc))
        for l in line[:2]:
            print('        $fatal 原文: %s' % l.strip())
        if not hit:
            print('        !! 日志里没有期待的关键字 %r' % expect)
    print('负测结果：%d/%d 通过' % (len(cases) - fails, len(cases)))
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
