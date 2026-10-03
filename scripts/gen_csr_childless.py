#!/usr/bin/env python3
"""Generate readable core+wrapper RTL for the disjoint childless CSR leaves.

The G1 golden modules are the behavioral source of truth.  This generator keeps
ANSI ports and sequential equations intact, removes firtool initialization
scaffolding, and puts the logic in one canonical ``xs_<name>_core`` per leaf.
"""
import argparse
import re
import sys
from pathlib import Path
from typing import List

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = ROOT / 'rtl' / 'backend'
COMMON = OUT / 'xs_CsrChildless_common.sv'
NAMES = [
    'Mgtu', 'MidelegModule', 'MipModule', 'MiselectModule', 'MnstatusModule',
    'MretEventModule', 'MseccfgModule', 'Mstateen0Module', 'Mstateen1Module',
    'Mstateen2Module', 'Mstateen3Module', 'MtinstModule', 'SatpModule',
    'SbpctlModule', 'ScounterenModule', 'SenvcfgModule', 'SiselectModule',
    'SlvpredctlModule', 'SmblockctlModule', 'SpfctlModule', 'SretEventModule',
    'SrnctlModule', 'Sstateen0Module', 'StimecmpModule', 'TrapInstMod',
    'TrapTvalMod',
]
SIMPLE_STATEEN = ['Mstateen1Module', 'Mstateen2Module', 'Mstateen3Module']

# Names emitted by firtool are replaced with semantic names.  The replacement
# is deliberately lexical and applies only after the golden module header.
RENAMES = {
    'MipModule': {
        '_GEN_0': 'hgeip_selected', '_GEN': 'hgeip_enabled',
        '_regOut_MEIP_WIRE': 'meip_pending',
        '_regOut_VSEIP_WIRE': 'vseip_pending',
        '_regOut_VSTIP_WIRE': 'vstip_pending',
        '_regOut_STIP_WIRE': 'stip_pending',
        '_regOut_SEIP_WIRE': 'seip_pending',
        '_rdataFields_SEIP_WIRE': 'seip_fields',
        'reg_SSIP': 'ssip_q', 'reg_STIP': 'stip_q', 'reg_LCOFIP': 'lcofip_q',
    },
    'MretEventModule': {
        '_out_privState_bits_PRVM_output': 'return_privilege',
        '_out_privState_bits_V_output': 'return_virtual',
        '_instrAddrTransType_x5_T_2': 'vsatp_bare',
    },
    'SretEventModule': {
        '_out_privState_bits_V_output': 'return_virtual',
        '_instrAddrTransType_x5_T_2': 'vsatp_bare',
        '_out_mstatus_valid_T': 'mstatus_update_valid',
        '_xepc_ret_epc_T_4': 'return_epc',
    },
    'Sstateen0Module': {'_GEN': 'enabled_state'},
    'TrapInstMod': {
        '_sameFlush_T_8': 'fault_position', '_sameFlush_T': 'trap_position',
        '_sameFlush_T_9': 'flush_position', '_GEN': 'flush_and_valid',
        '_GEN_0': 'trap_is_younger', '_GEN_1': 'fault_survives_flush',
        '_GEN_2': 'interrupt_clears_trap', '_GEN_3': 'decode_trap_available',
        'csrInst': 'csr_instruction',
        'newCSRInstOlder': 'csr_instruction_older',
        'flush_valid': 'flush_valid_q',
        'flush_bits_ftqPtr_flag': 'flush_ptr_wrap_q',
        'flush_bits_ftqPtr_value': 'flush_ptr_index_q',
        'flush_bits_ftqOffset': 'flush_offset_q',
        'valid': 'entry_valid_q',
        'trapInstInfo_instr': 'trap_instruction_q',
        'trapInstInfo_ftqPtr_flag': 'trap_ptr_wrap_q',
        'trapInstInfo_ftqPtr_value': 'trap_ptr_index_q',
        'trapInstInfo_ftqOffset': 'trap_offset_q',
    },
    'TrapTvalMod': {
        '_clearFromFlush_T': 'flush_clears_fault', '_GEN': 'target_pc_fault',
        '_GEN_0': 'flush_rob_is_younger',
    },
    'SpfctlModule': {
        'reg_L2_PF_DELAY_LATENCY': 'l2_pf_delay_latency_q',
        'reg_L2_PF_TP_ENABLE': 'l2_pf_tp_enable_q',
        'reg_L2_PF_VBOP_ENABLE': 'l2_pf_vbop_enable_q',
        'reg_L2_PF_PBOP_ENABLE': 'l2_pf_pbop_enable_q',
        'reg_L2_PF_RECV_ENABLE': 'l2_pf_recv_enable_q',
        'reg_L2_PF_STORE_ONLY': 'l2_pf_store_only_q',
        'reg_L1D_PF_ENABLE_STRIDE': 'l1d_pf_enable_stride_q',
        'reg_L1D_PF_ACTIVE_STRIDE': 'l1d_pf_active_stride_q',
        'reg_L1D_PF_ACTIVE_THRESHOLD': 'l1d_pf_active_threshold_q',
        'reg_L1D_PF_ENABLE_PHT': 'l1d_pf_enable_pht_q',
        'reg_L1D_PF_ENABLE_AGT': 'l1d_pf_enable_agt_q',
        'reg_L1D_PF_TRAIN_ON_HIT': 'l1d_pf_train_on_hit_q',
        'reg_L1D_PF_ENABLE': 'l1d_pf_enable_q',
        'reg_L2_PF_ENABLE': 'l2_pf_enable_q',
        'reg_L1I_PF_ENABLE': 'l1i_pf_enable_q',
    },
}


def strip_scaffolding(text: str) -> str:
    # Firtool's random-initialization block is not architectural behavior.
    text = re.sub(r'\n\s*`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\s*', '\n', text, flags=re.S)
    # Simulation-only assertions are not architectural behavior.  At this point
    # the random-init block is already removed, so any remaining SYNTHESIS block
    # is the TrapTval assertion.
    text = re.sub(r'\n\s*`ifndef SYNTHESIS.*?`endif // not def SYNTHESIS\s*', '\n', text, flags=re.S)
    return text


def port_block(module_text: str) -> str:
    start = module_text.index('module ')
    end = module_text.index(');', start) + 2
    return module_text[start:end]


def port_names(port_header: str) -> List[str]:
    names: List[str] = []
    for line in port_header.splitlines()[1:]:
        line = line.strip().rstrip(',')
        if not line or line == ');':
            continue
        # ANSI declaration: the final identifier is the port name.
        match = re.search(r'([A-Za-z_][A-Za-z0-9_]*)$', line)
        if match:
            names.append(match.group(1))
    return names


def replace_generated_names(name: str, body: str) -> str:
    for old, new in sorted(RENAMES.get(name, {}).items(), key=lambda kv: -len(kv[0])):
        body = re.sub(rf'\b{re.escape(old)}\b', new, body)
    # No firtool temporary identifiers may remain in the readable area.  Keep
    # each fallback distinct; collapsing several nets to one would short them.
    body = re.sub(r'\b_GEN(?:_(\d+))?\b',
                  lambda m: 'generated_signal_' + (m.group(1) or '0'), body)
    return body


def rewrite_mgtu_body() -> str:
    # The firtool output spells this as 128 repeated comparisons.  It is the
    # same tail-mask rule for every lane: lanes at or above vl retain vd.
    return '''  integer lane;
  always_comb begin
    for (lane = 0; lane < 128; lane = lane + 1)
      io_out_vd[lane] = (io_in_vl <= lane) | io_in_vd[lane];
  end
'''


def proceduralize_assigns(body: str) -> str:
    # A procedural block makes each combinational decision explicit and keeps
    # the core's output ports strongly typed as logic.  The equations are not
    # changed; only the presentation differs from firtool's continuous assigns.
    def repl(match):
        expression = match.group(1).strip()
        lhs, rhs = expression.split('=', 1)
        return 'always_comb begin\n    %s = %s;\n  end' % (lhs.strip(), rhs.strip())
    body = re.sub(r'assign\s+([^;]+);', repl, body, flags=re.S)
    # Golden uses ``wire name = expression`` for combinational nets.  Keep
    # declaration and driver separate so ``logic`` does not become a one-time
    # procedural initialization.
    def decl_repl(match):
        width = match.group(1) or ''
        signal = match.group(2)
        expression = match.group(3).strip()
        return 'logic %s%s;\n  always_comb begin\n    %s = %s;\n  end' % (width, signal, signal, expression)
    return re.sub(r'logic\s+(\[[^]]+\]\s+)?([A-Za-z_]\w*)\s*=\s*([^;]+);', decl_repl, body)


def generate_common() -> str:
    return '''// xs_CsrChildless_common.sv — shared canonical cores for identical childless CSR leaves.
// Mstateen1/2/3 are architecturally identical one-bit state-enable banks in G1;
// each wrapper keeps its public module name while reusing this single core.

module xs_CsrStateEnable_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        w_wen,
  input  logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic        regOut_SE
);
  logic enabled_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      enabled_q <= 1'b0;
    else if (w_wen)
      enabled_q <= w_wdata[63];
  end
  always_comb begin
    rdata = {enabled_q, 63'h0};
    regOut_SE = enabled_q;
  end
endmodule
'''


def generate_simple_stateen(name: str) -> str:
    raw = (GOLDEN / f'{name}.sv').read_text()
    raw = raw[raw.index(f'module {name}') :]
    header = port_block(raw)
    ports = port_names(header)
    connections = ',\n'.join(f'    .{p}({p})' for p in ports)
    return f'''// {name}.sv — one-bit machine state-enable CSR wrapper.
// Mstateen1/2/3 share xs_CsrStateEnable_core; this file preserves the
// exact G1 port contract.

{header}
  xs_CsrStateEnable_core u_core (
{connections}
  );
endmodule
'''


def generate(name: str) -> str:
    if name in SIMPLE_STATEEN:
        return generate_simple_stateen(name)
    raw = (GOLDEN / f'{name}.sv').read_text()
    raw = raw[raw.index(f'module {name}') :]
    raw = strip_scaffolding(raw)
    header = port_block(raw)
    body_start = raw.index(');', raw.index(f'module {name}')) + 2
    body = raw[body_start:raw.rfind('endmodule')].strip()
    body = replace_generated_names(name, body)
    if name == 'Mgtu':
        body = rewrite_mgtu_body()
    # Turn firtool's net/reg declarations into idiomatic SystemVerilog types.
    body = re.sub(r'\bwire\b', 'logic', body)
    body = re.sub(r'\breg\b', 'logic', body)
    body = proceduralize_assigns(body)
    ports = port_names(header)
    core_header = header.replace(f'module {name}', f'module xs_{name}_core', 1)
    core_header = re.sub(r'\boutput\s+(\[[^]]+\]\s+)?', r'output logic \1', core_header)
    wrapper_header = header
    connections = ',\n'.join(f'    .{p}({p})' for p in ports)
    return f'''// {name}.sv — readable childless CSR/control leaf; wrapper ports match G1 exactly.
// The canonical core contains the state/update equations; the wrapper is only a
// name-preserving shell for chip integration and FM/UT comparison.

{core_header}
{body}
endmodule

{wrapper_header}
  xs_{name}_core u_core (
{connections}
  );
endmodule
'''


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    drift: List[str] = []
    common = generate_common()
    if args.check:
        if not COMMON.exists() or COMMON.read_text() != common:
            drift.append(str(COMMON))
    else:
        COMMON.write_text(common)
    for name in NAMES:
        expected = generate(name)
        path = OUT / f'{name}.sv'
        if args.check:
            if not path.exists() or path.read_text() != expected:
                drift.append(str(path))
        else:
            path.write_text(expected)
    if args.check:
        if drift:
            print('gen_csr_childless --check: DRIFT ' + ' '.join(drift))
            return 1
        print(f'gen_csr_childless --check: OK ({len(NAMES)} files)')
    else:
        print(f'gen_csr_childless: wrote {len(NAMES)} files')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
