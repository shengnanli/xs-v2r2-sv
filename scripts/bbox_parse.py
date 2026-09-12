#!/usr/bin/env python3
"""bbox_parse.py —— `report_black_boxes` 报告的严格 phase 状态机解析（fail-closed）。

codex 0140 P0-1：上一版用 `if FM249 in text: return []` 开头，等于把三类畸形报告
（184+249+非空块 / 只有 249 没有 184 / 重复 184）全当"没有黑盒"接受——正是 G0 十审
堵过的 fail-open。本版按 accepted 契约（xs-signoff/scripts/sidecar SIDECAR_SCHEMA.md
的 FM-184 状态机）重写为 phase 文法，且**判定权威是 sidecar native_facts.json 的对象集**
（由已验收的 Tcl 状态机产出）；本解析器作为**独立第二实现**用于交叉校验，两者不一致即拒。

phase 文法（任何偏离一律抛 BBoxParseError）：
  PRE     → 只允许 banner / 空行；遇 FM-184 进 HEAD（184 必须唯一且为完整规范文本）
  HEAD    → legend 与空行；遇 FM-249 进 EMPTY_TAIL；遇 section 头进 SEC
  EMPTY_TAIL → 249 之后不得再出现 section / design / 实例块（否则抛）
  SEC     → 每个 section 头声明 side(r/i) 与库类型；section 内必须 ≥1 个 design 块
  BLOCK   → design 行 → `Instances : N [of M]` → 恰好 N 条路径；路径 side 必须与
            section side 一致；(side, path) 全局不得重复
  非空集合与 FM-249 互斥；结尾整数回显之后不得再有内容
"""
import re

FM184 = ('Information: Reporting black boxes for current reference and implementation '
         'designs. (FM-184)')
FM249 = ("Information: No 'black boxes' matched current 'reference and implementation "
         "designs'. (FM-249)")

SEC_RE = re.compile(r'^####\s+(TECH LIBRARY|DESIGN LIBRARY)\s+-\s+([ri]):(\S+)\s*$')
DESIGN_RE = re.compile(r'^([a-zA-Z*][a-zA-Z* ]{0,5}?)\s{2,}(\w+)\s*$')
INST_RE = re.compile(r'^\s+Instances\s*:\s*(\d+)(?:\s+of\s+(\d+))?\s*$')
PATH_RE = re.compile(r'^\s+([ri]):(/\S+)\s*$')
TAIL_RE = re.compile(r'^\d+$')
# 允许忽略的装饰行（banner 星号框、legend 下划线框与 |…| 行、报告头字段、表头与分隔线）。
# 刻意逐类枚举而非通配：任何不在此列的行都会被当作未知内容拒绝。
IGNORE_RE = re.compile(r'^\s*$'
                       r'|^\*+\s*$'
                       r'|^\s*_+\s*$'
                       r'|^\s*\|.*\|\s*$'
                       r'|^\s*-+\s*$'
                       r'|^(Report|Reference|Implementation|Version|Date)\s*:'
                       r'|^Type\s+Design Name\s*$'
                       r'|^-{2,}\s+-{2,}\s*$'
                       r'|^#+\s*$')


class BBoxParseError(Exception):
    pass


def parse(text):
    """返回 [(side, attrs, design, inst_path)]，只含 Instances ≥ 1 的实例化黑盒。"""
    lines = text.splitlines()
    n184 = sum(1 for l in lines if l.strip() == FM184)
    n249 = sum(1 for l in lines if l.strip() == FM249)
    if n184 != 1:
        raise BBoxParseError(f'FM-184 出现 {n184} 次（须恰 1）')
    if n249 > 1:
        raise BBoxParseError(f'FM-249 出现 {n249} 次（至多 1）')

    phase = 'PRE'
    side = None
    design = None          # (attrs, name)
    want = None            # 本 design 块声明的实例数
    got = 0
    sec_blocks = 0
    out = []
    seen = set()

    def close_block():
        nonlocal design, want, got
        if design is not None and want is not None and got != want:
            raise BBoxParseError(f'{design[1]}: 声明 {want} 实例但列出 {got} 条路径')
        design, want, got = None, None, 0

    for raw in lines:
        l = raw.rstrip('\n')
        s = l.strip()

        if s == FM184:
            if phase != 'PRE':
                raise BBoxParseError('FM-184 出现在非 PRE 阶段')
            phase = 'HEAD'
            continue
        if s == FM249:
            if phase not in ('HEAD',):
                raise BBoxParseError('FM-249 只能紧随 FM-184 之后（空终态）')
            if out:
                raise BBoxParseError('FM-249 与非空黑盒集合共存')
            phase = 'EMPTY_TAIL'
            continue

        if phase == 'PRE':
            if IGNORE_RE.match(l):
                continue
            raise BBoxParseError(f'FM-184 之前出现未知内容: {s[:60]}')

        if phase == 'EMPTY_TAIL':
            if IGNORE_RE.match(l) or TAIL_RE.match(s):
                continue
            raise BBoxParseError(f'FM-249 之后出现内容: {s[:60]}')

        m = SEC_RE.match(l)
        if m:
            close_block()
            if phase == 'SEC' and sec_blocks == 0:
                raise BBoxParseError('上一 section 内 0 个 design 块')
            lib, sd = m.group(1), m.group(2)
            if lib == 'TECH LIBRARY' and 'FM_BBOX' not in m.group(3):
                raise BBoxParseError(f'TECH LIBRARY 未配 /FM_BBOX: {m.group(3)}')
            if lib == 'DESIGN LIBRARY' and 'WORK' not in m.group(3):
                raise BBoxParseError(f'DESIGN LIBRARY 未配 /WORK: {m.group(3)}')
            side, phase, sec_blocks = sd, 'SEC', 0
            continue

        if phase == 'HEAD':
            if IGNORE_RE.match(l):
                continue
            raise BBoxParseError(f'FM-184 之后、首个 section 之前出现未知内容: {s[:60]}')

        # phase == 'SEC'
        m = INST_RE.match(l)
        if m:
            if design is None:
                raise BBoxParseError('Instances 行出现在 design 名之前')
            if want is not None:
                raise BBoxParseError(f'{design[1]}: 重复 Instances 行')
            want, got = int(m.group(1)), 0
            continue

        m = PATH_RE.match(l)
        if m:
            if design is None or want is None:
                raise BBoxParseError('实例路径出现在 Instances 声明之前')
            if m.group(1) != side:
                raise BBoxParseError(f'路径 side {m.group(1)} 与 section side {side} 不符')
            key = (side, s)
            if key in seen:
                raise BBoxParseError(f'重复实例路径: {s}')
            seen.add(key)
            got += 1
            if got > want:
                raise BBoxParseError(f'{design[1]}: 路径条数超过声明 {want}')
            out.append((side, design[0].strip(), design[1], s))
            continue

        if TAIL_RE.match(s):
            close_block()
            if sec_blocks == 0:
                raise BBoxParseError('section 内 0 个 design 块')
            phase = 'TAIL'
            continue

        m = DESIGN_RE.match(l)
        if m and not l.startswith(' '):
            close_block()
            design, want, got = (m.group(1), m.group(2)), None, 0
            sec_blocks += 1
            continue

        if IGNORE_RE.match(l):
            continue
        raise BBoxParseError(f'section 内未知行: {s[:60]}')

    if phase == 'TAIL':
        pass
    elif phase == 'SEC':
        close_block()
        if sec_blocks == 0:
            raise BBoxParseError('末个 section 内 0 个 design 块')
    elif phase not in ('EMPTY_TAIL',):
        raise BBoxParseError(f'报告在 {phase} 阶段意外结束')

    if not out and phase != 'EMPTY_TAIL':
        raise BBoxParseError('黑盒集合为空但没有 FM-249 空终态标记')
    return out


def normalize(entries):
    objs, attrs = set(), {}
    for side, a, design, path in entries:
        key = (side, design, path)
        objs.add(key)
        attrs[key] = a
    return objs, attrs


def from_native_facts(facts):
    """判定权威来源：sidecar native_facts.json 的对象集（已验收 Tcl 状态机产出）。
    返回与 normalize 同构的 (objs, attrs)，attrs 为类别记号。"""
    o = facts['objects']
    objs, attrs = set(), {}
    kinds = [('unresolved_blackbox_ref', 'r', 'u'), ('unresolved_blackbox_impl', 'i', 'u'),
             ('interface_only_ref', 'r', 'i'), ('interface_only_impl', 'i', 'i'),
             ('empty_blackbox_ref', 'r', 'e'), ('empty_blackbox_impl', 'i', 'e'),
             ('unlinked_blackbox_ref', 'r', '*'), ('unlinked_blackbox_impl', 'i', '*')]
    for key, side, a in kinds:
        for p in o.get(key, []):
            design = p.rstrip('/').split('/')[-1]
            k = (side, design, p)
            objs.add(k)
            attrs[k] = a
    return objs, attrs


if __name__ == '__main__':
    import sys
    ents = parse(open(sys.argv[1]).read())
    for e in ents:
        print('\t'.join(e))
    print(f'# {len(ents)} 条实例化黑盒', file=sys.stderr)
