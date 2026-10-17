#!/usr/bin/env python3
"""test_proof_certificate_memory.py —— hdlin_interface_only 回读集合 = green_child ∪ 已登记 memory 的正负测
（codex 0230 问题 1 第 4/5 条；进 gate_all）。

夹具复用 test_proof_certificate_nested.Tree（T → M → {LA, LB}）：在 M 的 allow 里再声明一个两侧对称、
interface-only（attrs='i'）的 APPROVED_MEMORY_MACRO_MODEL 存储叶子 dt_pcTransType_160x2，回读 = "LA LB <mem>"。
G1 夹具里放入 dt_pcTransType_160x2.sv 的真实 G1 字节（进 MANIFEST）；vendor_boundary.tsv 用**冻结夹具**：只含从
本仓表里取出的 dt_pcTransType_160x2 那一行（负例所需的「未登记」样本是夹具里根本没有的名字，不依赖本仓表
「恰好没登记」什么）。判据本体 = proof_certificate.validate_certificate_current（递归）。

正例：P0 GC + memory 并集；P1 回读乱序；P2 既有 'u' 形态（两侧未解析黑盒）的 memory 不进回读集合，回读只有 GC。
负例：
  M1 回读漏 memory                        M2 回读多一个未声明 design
  M3 未登记 RAM（G1 里有、夹具表里无）      M4 G1 字节与登记 hash 不同（错 hash）
  M5 登记行 kind 不是 APPROVED_MEMORY_MACRO_MODEL（错 class，表侧）
  M6 allow 里该 design 一侧写成 vendor_macro（错 class，声明侧）
  M7 单侧路径（只有 r 侧对象）              M8 两侧路径不同名
  M9 普通逻辑伪装 memory：登记行伪造成指向一个逻辑模块（sha 与 G1 一致），M1 模板拦下
  M10 同一 design 既是 green_child 又是 memory      M11 同一 design 'i' 与 'u' 混用
  M12 登记行 body_rule 缺 symmetric_both_sides_only  M13 回读重复 memory
impl 闭包挂 golden memory 的并列分支（codex 0233/0234）：
  I1/I1s 正例（树 / standalone）  I2 未入 memory 集合  I3 ref 缺文件  I4 ref sha 不同  I5 'u' 声明却在 impl 读入
  I6 class 不对  I7 两侧同一非登记 hash  I8 父层获准子层无声明  I9 standalone 回读缺  I10 命中后失败不降落
用法：python3 scripts/test_proof_certificate_memory.py
"""
import hashlib
import pathlib
import shutil
import sys

HERE = pathlib.Path(__file__).resolve().parent
HOME = HERE.parent
sys.path.insert(0, str(HERE))
import test_proof_certificate_nested as N    # noqa: E402

MEM = 'dt_pcTransType_160x2'
MEM_BYTES = (N.G1REAL / f'{MEM}.sv').read_bytes()
FAMILY = (N.G1REAL / 'ram_40x47.sv').read_bytes()      # M1 宏定义头的家族参照件
HDR = '\n'.join(ln for ln in (HOME / 'verif/vendor_boundary.tsv').read_text().splitlines()
                if ln.startswith('# design_pattern')) + '\n'
ROW = [ln for ln in (HOME / 'verif/vendor_boundary.tsv').read_text().splitlines()
       if ln.split('\t')[0] == MEM]
assert len(ROW) == 1, f'本仓 vendor_boundary.tsv 里 {MEM} 应恰好一行'
ROW = ROW[0].split('\t')
LOGIC = b'module FakeLogic(input a, output b);\n  assign b = ~a;\nendmodule\n'


def vb(rows):
    return HDR + ''.join('\t'.join(r) + '\n' for r in rows)


def row(**kw):
    r = list(ROW)
    for k, v in kw.items():
        r[{'design': 0, 'kind': 1, 'leaf_file': 3, 'sha': 4, 'body_rule': 9}[k]] = v
    return r


def mem_objs(design=MEM, sides=('r', 'i'), cls='APPROVED_MEMORY_MACRO_MODEL', attrs='i', path='rob/mem_ext',
             ipath=None):
    out = []
    for sd in sides:
        p = (ipath if (sd == 'i' and ipath) else path)
        out.append({'side': sd, 'design': design, 'path': f'{sd}:/WORK/M/{p}', 'attrs': attrs,
                    'class': cls if not isinstance(cls, dict) else cls[sd]})
    return out


def tree(objs=None, readback=None, rows=None, g1_override=None, extra_gold=None):
    objs = mem_objs() if objs is None else objs

    def add(allow, tr):
        allow['objects'].extend(objs)
    gold = {f'{MEM}.sv': MEM_BYTES, 'ram_40x47.sv': FAMILY}
    gold.update(extra_gold or {})
    return N.Tree(allow_mut={'M': add}, readback={'M': readback if readback is not None else f'LA LB {MEM}'},
                  extra_gold=gold, extra_files={'verif/vendor_boundary.tsv': vb(rows if rows is not None else [ROW])},
                  g1_override=g1_override or {}).judge()


def main():
    if shutil.which('git') is None:
        print('SKIP: 无 git')
        return 2
    chk = N.chk
    chk('P0 GC + memory 并集', tree(), True)
    chk('P1 回读乱序', tree(readback=f'{MEM} LB LA'), True)
    chk("P2 'u' 形态 memory 不进回读", tree(objs=mem_objs(attrs='u'), readback='LA LB'), True)
    chk('M1 回读漏 memory', tree(readback='LA LB'), 'interface_only_not_declared_set')
    chk('M2 回读多一个未声明 design', tree(readback=f'LA LB {MEM} Foo'), 'interface_only_not_declared_set')
    ram_fake = b'// fixture: unregistered RAM\n' + MEM_BYTES.replace(MEM.encode(), b'ram_fake_160x2')
    chk('M3 未登记 RAM', tree(objs=mem_objs() + mem_objs(design='ram_fake_160x2', path='rob/fake_ext'),
                             readback=f'LA LB {MEM} ram_fake_160x2', extra_gold={'ram_fake_160x2.sv': ram_fake}),
        'memory_interface_only_unregistered:ram_fake_160x2')
    chk('M4 G1 字节与登记 hash 不同', tree(g1_override={f'{MEM}.sv': MEM_BYTES + b'\n'}),
        'memory_interface_only_g1_hash_mismatch')
    chk('M5 登记行 kind 错', tree(rows=[row(kind='vendor_sram_leaf')]), 'memory_interface_only_wrong_registry_kind')
    chk('M6 allow 一侧写成 vendor_macro',
        tree(objs=mem_objs(cls={'r': 'APPROVED_MEMORY_MACRO_MODEL', 'i': 'vendor_macro'})),
        'memory_interface_only_mixed_declaration')
    chk('M7 单侧路径', tree(objs=mem_objs(sides=('r',))), 'memory_interface_only_asymmetric')
    chk('M8 两侧路径不同名', tree(objs=mem_objs(ipath='rob/other_ext')), 'memory_interface_only_asymmetric')
    logic_sha = hashlib.sha256(LOGIC).hexdigest()
    chk('M9 普通逻辑伪装 memory',
        tree(objs=mem_objs(design='FakeLogic', path='rob/fake'), readback='LA LB FakeLogic',
             rows=[ROW, row(design='FakeLogic', leaf_file='FakeLogic.sv', sha=logic_sha)],
             extra_gold={'FakeLogic.sv': LOGIC}),
        'memory_interface_only_not_memory_template:FakeLogic')

    def gc_and_mem(allow, tr):
        allow['objects'].extend(mem_objs(design='LA', path='u_LA'))
    chk('M10 同一 design 既是 GC 又是 memory',
        N.Tree(allow_mut={'M': gc_and_mem}, extra_gold={'ram_40x47.sv': FAMILY},
               extra_files={'verif/vendor_boundary.tsv': vb([ROW])}).judge(),
        'memory_interface_only_mixed_declaration:LA')
    chk("M11 同一 design 'i' 与 'u' 混用",
        tree(objs=[mem_objs()[0], dict(mem_objs()[1], attrs='u')]), 'memory_interface_only_mixed_declaration')
    chk('M12 登记行 body_rule 缺对称约束', tree(rows=[row(body_rule='pin_by=leaf_sha256')]),
        'memory_interface_only_registry_body_rule')
    chk('M13 回读重复 memory', tree(readback=f'LA LB {MEM} {MEM}'), 'interface_only_duplicate')
    impl_golden_cases(chk)
    for p in N.TMP:
        shutil.rmtree(p, ignore_errors=True)
    print('test_proof_certificate_memory: %d 条，%s' % (N.RUN[0], '全过' if not N.FAILS else '★未过 %s' % N.FAILS))
    return 1 if N.FAILS else 0


# ---------------------------------------------------------------------------
# codex 0233/0234：impl 闭包挂 golden memory 的并列分支（validate_impl_golden_certified）
# ---------------------------------------------------------------------------
MEM_SHA = hashlib.sha256(MEM_BYTES).hexdigest()


def gent(name=f'{MEM}.sv', sha=MEM_SHA):
    return {'path': f'golden-rtl/{name}', 'kind': 'golden', 'sha256': sha}


def with_golden(impl=(), ref=()):
    """cert_mut：往证书 impl / ref 闭包里加 golden 条目并重算闭包摘要。"""
    def mut(doc):
        ic = doc['input_closure']
        ic['impl'] = ic['impl'] + [dict(x) for x in impl]
        ic['golden'] = ic['golden'] + [dict(x) for x in ref]
        ic['impl_sha256'] = N.PC.closure_digest(ic['impl'])
        ic['golden_sha256'] = N.PC.closure_digest(ic['golden'])
        return doc
    return mut


def itree(objs=None, readback=None, rows=None, impl=(gent(),), ref=(gent(),), on='M', extra_gold=None):
    objs = mem_objs() if objs is None else objs

    def add(allow, tr):
        allow['objects'].extend(objs)
    gold = {f'{MEM}.sv': MEM_BYTES, 'ram_40x47.sv': FAMILY}
    gold.update(extra_gold or {})
    return N.Tree(allow_mut={'M': add}, readback={'M': readback if readback is not None else f'LA LB {MEM}'},
                  cert_mut={on: with_golden(impl, ref)}, extra_gold=gold,
                  extra_files={'verif/vendor_boundary.tsv': vb(rows if rows is not None else [ROW])})


def standalone(tr, target='M'):
    """直接调 validate_impl_golden_certified（不经 validate_certificate_current 的前置判据）。"""
    pol, _ = N.PC.load_policy(tr.repo, tr.parent)
    tmap, unres = N.FTU.targets_at(str(tr.repo_dir), tr.parent)
    doc, _b, _e = N.PC.load_certificate(tr.repo, tr.parent, target)
    return N.PC.validate_impl_golden_certified(tr.repo, tr.parent, target, doc, policy=pol, fm_targets=tmap,
                                              fm_targets_unresolved=unres, g1_root=str(tr.g1))


def impl_golden_cases(chk):
    fake = b'// fixture: unregistered RAM\n' + MEM_BYTES.replace(MEM.encode(), b'ram_fake_160x2')
    fsha = hashlib.sha256(fake).hexdigest()
    chk('I1 impl/ref 同挂已批准 memory（树）', itree().judge(), True)
    chk('I1s 同上（standalone）', standalone(itree()), True)
    chk('I2 未入 memory 集合的 golden', itree(impl=(gent(), gent('ram_fake_160x2.sv', fsha)),
                                         ref=(gent(), gent('ram_fake_160x2.sv', fsha)),
                                         extra_gold={'ram_fake_160x2.sv': fake}).judge(),
        'impl_golden_not_fm_target:M:ram_fake_160x2')
    chk('I3 ref 闭包缺该文件', itree(ref=()).judge(), 'impl_golden_memory_not_shared:M:')
    chk('I4 ref 条目 sha 不同（standalone）', standalone(itree(ref=(gent(sha='0' * 64),))),
        'impl_golden_memory_ref_mismatch')
    chk("I5 声明为两侧不读（'u'）却在 impl 读入", itree(objs=mem_objs(attrs='u'), readback='LA LB').judge(),
        'impl_golden_memory_not_interface_only')
    chk('I6 class 不是 APPROVED_MEMORY_MACRO_MODEL（standalone）',
        standalone(itree(objs=mem_objs(cls='vendor_macro'))), 'impl_golden_not_fm_target:M:dt_pcTransType_160x2')
    other = 'ab' * 32
    chk('I7 (0234-a) 两侧同一 hash 但非 registry 登记值（standalone）',
        standalone(itree(impl=(gent(sha=other),), ref=(gent(sha=other),))), 'impl_golden_memory_sha_not_registered')
    chk('I8 (0234-b) 父层获准、子层（LA）无自己的批准声明', itree(impl=(gent(),), ref=(gent(),), on='LA').judge(),
        'impl_golden_not_fm_target:LA:dt_pcTransType_160x2')
    chk('I9 standalone 回读缺该 memory', standalone(itree(readback='LA LB')), 'impl_golden_memory_readback_missing')
    chk('I10 命中后失败不降落（登记 kind 错，standalone）', standalone(itree(rows=[row(kind='vendor_sram_leaf')])),
        'impl_golden_memory_invalid')


if __name__ == '__main__':
    sys.exit(main())
