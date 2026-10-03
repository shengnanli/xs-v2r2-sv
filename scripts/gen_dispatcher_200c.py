#!/usr/bin/env python3
"""Generate readable Dispatcher leaves and their differential UT.

The generator consumes the immutable G1 golden files for three contracts:
acceptance masks, exact ANSI port declarations, and the direct input-to-output
field map.  The generated RTL keeps one shared route core; each wrapper only
adapts the exact flattened ports and supplies its proven masks.
"""
from pathlib import Path
import argparse
import re

REPO = Path(__file__).resolve().parents[1]
GOLDEN = Path('/home/eda/xs-env/G1-canonical/golden-rtl')
TARGETS = ['Dispatcher','Dispatcher_1','Dispatcher_10','Dispatcher_13','Dispatcher_14','Dispatcher_15','Dispatcher_16','Dispatcher_17','Dispatcher_4','Dispatcher_5','Dispatcher_7','Dispatcher_8','Dispatcher_9']
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')
ASSIGN_RE = re.compile(r'assign\s+(\w+)\s*=\s*(.*?);', re.S)
ACCEPT_RE = re.compile(r'wire\s+(?:\[\d+:\d+\]\s+)?(?:acceptVec_(\d+)|data_0_probe)\s*=\s*io_in_bits_fuType\s*==\s*35\'h([0-9a-f]+)')


def parse(module):
    text = (GOLDEN / f'{module}.sv').read_text()
    start = text.index(f'module {module}(')
    end = text.index('\n);', start)
    ports=[]
    for line in text[start:end].splitlines()[1:]:
        m=PORT_RE.match(line)
        if not m:
            raise ValueError(f'{module}: cannot parse port line {line!r}')
        direction,msb,lsb,name=m.groups()
        width=1 if msb is None else int(msb)-int(lsb)+1
        ports.append((direction,width,name))
    body=text[end+3:]
    assigns={name: re.sub(r'\s+',' ',rhs).strip() for name,rhs in ASSIGN_RE.findall(body)}
    accepts=[]
    for m in re.finditer(r'(?:wire\s+)(?:(?:\[\d+:\d+\]\s+))?(?:acceptVec_(\d+)|data_0_probe)\s*=\s*io_in_bits_fuType\s*==\s*35\'h([0-9a-f]+)',body):
        slot = int(m.group(1)) if m.group(1) is not None else 0
        accepts.append((slot,int(m.group(2),16)))
    # One-output Dispatcher variants use data_0_probe and have no acceptVec.
    if not accepts:
        raise ValueError(f'{module}: no acceptance compare')
    accepts.sort()
    output_slots=sorted({int(m.group(1)) for _,_,n in ports if n.startswith('io_out_') for m in [re.match(r'io_out_(\d+)_',n)] if m})
    if output_slots != list(range(len(output_slots))):
        raise ValueError(f'{module}: output slots are not contiguous: {output_slots}')
    nslots=len(output_slots)
    if len(accepts)!=nslots:
        raise ValueError(f'{module}: acceptance compares {accepts}, outputs {nslots}')
    for slot,mask in accepts:
        valid=assigns.get(f'io_out_{slot}_valid')
        if valid is None or 'io_in_valid' not in valid:
            raise ValueError(f'{module}: output {slot} valid not driven from io_in_valid')
        for d,w,name in ports:
            if d=='output' and name.startswith(f'io_out_{slot}_') and not name.endswith('_valid'):
                rhs=assigns.get(name)
                expected=f'io_in_bits_{name[len(f"io_out_{slot}_bits_"):]} '
                if rhs is None:
                    raise ValueError(f'{module}: output {name} has no assignment')
                if not rhs.startswith('io_in_bits_'):
                    raise ValueError(f'{module}: output {name} not direct input: {rhs}')
    ready=assigns.get('io_in_ready')
    if ready is None:
        raise ValueError(f'{module}: no in_ready assignment')
    ready_slots=[int(x) for x in re.findall(r'io_out_(\d+)_ready',ready)]
    if ready_slots != output_slots:
        raise ValueError(f'{module}: ready expression {ready}')
    return dict(module=module,text=text,ports=ports,assigns=assigns,accepts=accepts,nslots=nslots,ready=ready)


def decl(direction,width,name,logic=True):
    packed='' if width==1 else f'[{width-1}:0] '
    return f'  {direction:<6} {"logic " if logic else ""}{packed}{name}'


def core():
    return '''// xs_Dispatcher_core.sv — shared combinational ready/valid dispatcher core.
//
// Each Dispatcher leaf compares the complete 35-bit FuType one-hot word with
// a proven per-output mask.  A match gates valid; payload buses are broadcast
// unchanged and are selected by each output's valid.  Ready is deliberately
// the AND of every output ready, matching the conservative golden contract.
module xs_Dispatcher_core #(
  parameter int unsigned OUTPUTS = 1,
  parameter logic [34:0] ACCEPT_MASK [0:OUTPUTS-1] = '{default: '0}
)(
  input  logic                         clock,
  input  logic                         reset,
  output logic                         in_ready,
  input  logic                         in_valid,
  input  logic [34:0]                  in_fu_type,
  input  logic [OUTPUTS-1:0]           out_ready,
  output logic [OUTPUTS-1:0]           out_valid
);
  logic [OUTPUTS-1:0] accepted;

  genvar slot;
  generate
    for (slot = 0; slot < OUTPUTS; slot = slot + 1) begin : g_route
      assign accepted[slot] = (in_fu_type == ACCEPT_MASK[slot]);
      assign out_valid[slot] = in_valid & accepted[slot];
    end
  endgenerate

  assign in_ready = &out_ready;

`ifndef SYNTHESIS
  // Golden asserts that a valid input is claimed by exactly one or at least
  // one output.  Keep equivalent checks local to the shared route core.
  always @(posedge clock) begin
    if (!reset && in_valid) begin
      if ($countones(accepted) > 1)
        $error("Dispatcher FuType claimed by multiple outputs: %h", in_fu_type);
      if (accepted == '0)
        $error("Dispatcher FuType not claimed by any output: %h", in_fu_type);
    end
  end
`endif
endmodule
'''


def core_inst(info):
    masks=', '.join(f"35'h{mask:x}" for _,mask in info['accepts'])
    return f'''  xs_Dispatcher_core #(
    .OUTPUTS({info['nslots']}),
    .ACCEPT_MASK('{{{masks}}})
  ) route_core (
    .clock(clock), .reset(reset), .in_ready(io_in_ready),
    .in_valid(io_in_valid), .in_fu_type(io_in_bits_fuType),
    .out_ready({{{', '.join(f'io_out_{s}_ready' for s in reversed(range(info['nslots'])) )}}}),
    .out_valid({{{', '.join(f'io_out_{s}_valid' for s in reversed(range(info['nslots'])) )}}})
  );
'''


def wrapper(info):
    mod = info['module']; ports = info['ports']; assigns = info['assigns']
    lines = [f'// {mod}.sv — exact-port Dispatcher wrapper with readable route core.',
             '// Acceptance masks and field maps are checked against G1 by',
             '// scripts/gen_dispatcher_200c.py before this file is written.', '',
             f'module {mod} (']
    lines.extend(decl(d, w, name) + (',' if i < len(ports) - 1 else '')
                 for i, (d, w, name) in enumerate(ports))
    lines += [');', '', core_inst(info)]

    # Pack each output's exact golden field subset once, then unpack by named
    # slices.  This keeps the wrapper readable and avoids a forest of identical
    # field-by-field fanout assigns while preserving every field and bit order.
    for slot in range(info['nslots']):
        fields = []
        for d, w, name in ports:
            if d == 'output' and name.startswith(f'io_out_{slot}_bits_'):
                out_field = name[len(f'io_out_{slot}_bits_'):]
                rhs = assigns[name]
                expected = f'io_in_bits_{out_field}'
                if rhs != expected:
                    raise ValueError(f'{mod}: non-direct payload map {name}={rhs}')
                fields.append((out_field, w))
        packet_w = sum(w for _, w in fields)
        lines.append(f'  // Output {slot} payload order (MSB to LSB): ' +
                     ', '.join(field for field, _ in fields) + '.')
        lines.append(f'  logic [{packet_w - 1}:0] payload_{slot};')
        lines.append(f'  assign payload_{slot} = {{' +
                     ', '.join(f'io_in_bits_{field}' for field, _ in fields) + '};')
        offset = 0
        for field, width in reversed(fields):
            out_name = f'io_out_{slot}_bits_{field}'
            hi = offset + width - 1
            lo = offset
            lines.append(f'  assign {out_name} = payload_{slot}[{hi}:{lo}];')
            offset += width
    lines += ['endmodule', '']
    return '\n'.join(lines)


def rtl_text(infos):
    return core() + '\n' + '\n'.join(wrapper(i) for i in infos)


def tb_text(infos):
    # Build a full random differential bench. Keep payload checks conditional on
    # both valid signals only for explicit clarity; all golden outputs are direct
    # combinational broadcasts and are compared whenever known.
    lines=['// Focused G1 differential regression for all remaining Dispatcher leaves.',
           '// Every target is instantiated once as untouched golden and once as _xs.',
           '`timescale 1ns/1ps','module tb;','  bit clock = 1\'b0;','  logic reset = 1\'b0;',
           '  integer errors = 0, checks = 0;','  integer cycles = 0;','  always #5 clock = ~clock;','']
    def sig(prefix,mod,name): return f'{prefix}_{mod}_{name}'
    for info in infos:
        mod=info['module']; lines.append(f'  // {mod}')
        for d,w,name in info['ports']:
            if name in ('clock','reset'): continue
            for p in ('g','i'):
                lines.append('  '+decl('logic',w,sig(p,mod,name),logic=False)+';')
        lines += ['', f'  {mod} g_{mod} (']
        for j,(_,_,name) in enumerate(info['ports']):
            conn='clock' if name=='clock' else 'reset' if name=='reset' else sig('g',mod,name)
            lines.append(f'    .{name}({conn})'+(',' if j<len(info['ports'])-1 else ''))
        lines += ['  );', f'  {mod}_xs i_{mod} (']
        for j,(_,_,name) in enumerate(info['ports']):
            conn='clock' if name=='clock' else 'reset' if name=='reset' else sig('i',mod,name)
            lines.append(f'    .{name}({conn})'+(',' if j<len(info['ports'])-1 else ''))
        lines += ['  );','']
    lines += ['  task automatic check_outputs;','    begin']
    for info in infos:
        mod=info['module']
        for d,w,name in info['ports']:
            if d!='output': continue
            g=sig('g',mod,name); i=sig('i',mod,name)
            lines += [f'      if (!$isunknown({g}) && !$isunknown({i})) begin',
                      '        checks = checks + 1;',
                      f'        if ({g} !== {i}) begin',
                      '          errors = errors + 1;',
                      f'          if (errors <= 20) $display("MISMATCH {mod}.{name} g=%h i=%h", {g}, {i});',
                      '        end','      end']
    lines += ['    end','  endtask','', '  initial begin', '    #1 reset = 1\'b1;',
              '    repeat (3) @(negedge clock);','    reset = 1\'b0;',
              '    repeat (200000) begin','      @(negedge clock);','      cycles = cycles + 1;']
    for info in infos:
        mod=info['module']
        for d,w,name in info['ports']:
            if d!='input' or name in ('clock','reset'): continue
            lines += [f'      {sig("g",mod,name)} = $urandom;', f'      {sig("i",mod,name)} = {sig("g",mod,name)};']
    lines += ['      @(posedge clock);','      #1 check_outputs();','    end',
              '    $display("cycles=%0d checks=%0d errors=%0d", cycles, checks, errors);',
              '    if (errors != 0 || checks == 0) $fatal(1, "differential test failed");',
              '    $display("TEST PASSED");','    $finish;','  end','endmodule','']
    return '\n'.join(lines)


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--check',action='store_true'); ap.add_argument('--out-dir',default=str(REPO/'rtl/backend')); ap.add_argument('--tb-out',default=str(REPO/'verif/ut/Dispatcher200c/tb.sv')); args=ap.parse_args()
    infos=[parse(m) for m in TARGETS]
    out=Path(args.out_dir); out.mkdir(parents=True,exist_ok=True)
    core_path=out/'xs_Dispatcher_core.sv'; text=core()
    if args.check:
        if not core_path.exists() or core_path.read_text()!=text: raise SystemExit(f'DRIFT: {core_path}')
    else:
        if not core_path.exists() or core_path.read_text()!=text: core_path.write_text(text)
    for info in infos:
        path=out/(info['module']+'.sv'); generated=wrapper(info)
        if args.check:
            if not path.exists() or path.read_text()!=generated: raise SystemExit(f'DRIFT: {path}')
        elif not path.exists() or path.read_text()!=generated: path.write_text(generated)
    tb=Path(args.tb_out); generated_tb=tb_text(infos)
    if args.check:
        if not tb.exists() or tb.read_text()!=generated_tb: raise SystemExit(f'DRIFT: {tb}')
    else:
        tb.parent.mkdir(parents=True,exist_ok=True)
        if not tb.exists() or tb.read_text()!=generated_tb: tb.write_text(generated_tb)
    print(f'generated {core_path} and {len(infos)} wrappers plus {tb}')

if __name__=='__main__': main()
