#!/usr/bin/env python3
"""Generate the aggregate differential testbench for the 26 childless leaves."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
GOLDEN = Path('/home/eda/xs-env/G1-canonical/golden-rtl')
NAMES = [
    'Mgtu', 'MidelegModule', 'MipModule', 'MiselectModule', 'MnstatusModule',
    'MretEventModule', 'MseccfgModule', 'Mstateen0Module', 'Mstateen1Module',
    'Mstateen2Module', 'Mstateen3Module', 'MtinstModule', 'SatpModule',
    'SbpctlModule', 'ScounterenModule', 'SenvcfgModule', 'SiselectModule',
    'SlvpredctlModule', 'SmblockctlModule', 'SpfctlModule', 'SretEventModule',
    'SrnctlModule', 'Sstateen0Module', 'StimecmpModule', 'TrapInstMod',
    'TrapTvalMod',
]


def parse_ports(name):
    text = (GOLDEN / (name + '.sv')).read_text()
    text = text[text.index('module ' + name):]
    header = text[:text.index(');') + 2]
    ports = []
    for line in header.splitlines()[1:]:
        line = line.strip().rstrip(',')
        if not line or line == ');':
            continue
        m = re.match(r'(input|output)\s+(?:logic\s+)?(\[[^]]+\]\s+)?([A-Za-z_]\w*)$', line)
        if not m:
            raise RuntimeError('%s: cannot parse port %r' % (name, line))
        direction, width, port = m.groups()
        ports.append((direction, width or '', port))
    return ports


def sv_decl(width, name):
    return '  logic %s%s;' % (width, name)


def main():
    out = Path(__file__).with_name('tb.sv')
    lines = [
        '// Aggregate differential UT: G1 golden versus generated childless wrappers.',
        '`timescale 1ns/1ps',
        'module tb;',
        '  logic clock = 1\'b0;',
        '  logic reset = 1\'b1;',
        '  integer errors = 0;',
        '  integer cycle = 0;',
        '  integer ncycles = 200000;',
        '  always #1 clock = ~clock;',
        '  initial void\'($value$plusargs("ncycles=%d", ncycles));',
    ]
    all_inputs = []
    comparisons = []
    for name in NAMES:
        ports = parse_ports(name)
        lines.append('')
        lines.append('  // %s' % name)
        for direction, width, port in ports:
            if port in ('clock', 'reset'):
                continue
            lines.append(sv_decl(width, '%s_%s' % (name, port)))
        # Golden and implementation output nets are separate; inputs are shared.
        for direction, width, port in ports:
            if direction == 'output':
                lines.append(sv_decl(width, '%s_g_%s' % (name, port)))
                lines.append(sv_decl(width, '%s_i_%s' % (name, port)))
            elif port not in ('clock', 'reset'):
                all_inputs.append('%s_%s' % (name, port))
        def inst(mod, suffix):
            conns = []
            for direction, width, port in ports:
                if port in ('clock', 'reset'):
                    signal = port
                elif direction == 'input':
                    signal = '%s_%s' % (name, port)
                else:
                    signal = '%s_%s' % (suffix, port)
                conns.append('    .%s(%s)' % (port, signal))
            return ['  %s u_%s (' % (mod, suffix)] + [x + (',' if i + 1 < len(conns) else '') for i, x in enumerate(conns)] + ['  );']
        lines += inst(name, name + '_g')
        lines += inst(name + '_xs', name + '_i')
        outputs = [port for direction, width, port in ports if direction == 'output']
        for port in outputs:
            comparisons.append('    if (%s_g_%s !== %s_i_%s) begin' % (name, port, name, port))
            comparisons.append('      $display("MISMATCH %s.%s cycle=%%0d g=%%h i=%%h", cycle, %s_g_%s, %s_i_%s);' % (name, port, name, port, name, port))
            comparisons.append('      errors = errors + 1;')
            comparisons.append('    end')
    lines += [
        '',
        '  initial begin',
        '    repeat (3) @(posedge clock);',
        '    reset <= 1\'b0;',
        '    for (cycle = 0; cycle < ncycles; cycle = cycle + 1) begin',
    ]
    for sig in all_inputs:
        lines.append('      %s <= {$urandom, $urandom};' % sig)
    lines += [
        '      @(negedge clock);',
        '      if (!reset) begin',
    ] + comparisons + [
        '      end',
        '      if (errors > 20) $fatal(1, "too many mismatches");',
        '    end',
        '    if (errors == 0) $display("TEST PASSED cycles=%0d", ncycles);',
        '    else $fatal(1, "TEST FAILED errors=%0d", errors);',
        '    $finish;',
        '  end',
        'endmodule',
    ]
    out.write_text('\n'.join(lines) + '\n')
    print('wrote', out)


if __name__ == '__main__':
    main()
