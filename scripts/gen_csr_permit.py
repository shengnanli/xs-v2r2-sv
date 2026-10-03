#!/usr/bin/env python3
"""Generate the readable IndirectCSRPermitModule and check its golden contract."""

import argparse
import hashlib
import re
from pathlib import Path
from typing import List, Tuple

ROOT = Path(__file__).resolve().parents[1]
RTL_PATH = ROOT / "rtl/backend/IndirectCSRPermitModule.sv"
GOLDEN_PATH = Path("/home/eda/xs-env/G1-canonical/golden-rtl/IndirectCSRPermitModule.sv")
GOLDEN_SHA256 = "80344565cbdd3fce1abf9e7c4c3c052c61f17a624b95f64a69d69d2963a347a5"

EXPECTED_PORTS = [
    ("input", "[11:0]", "io_in_csrAccess_addr"),
    ("input", "[1:0]", "io_in_privState_PRVM"),
    ("input", "", "io_in_privState_V"),
    ("input", "[63:0]", "io_in_aia_miselect"),
    ("input", "[63:0]", "io_in_aia_siselect"),
    ("input", "[63:0]", "io_in_aia_vsiselect"),
    ("input", "", "io_in_aia_mvienSEIE"),
    ("input", "", "io_in_xstateen_mstateen0_AIA"),
    ("input", "", "io_in_xstateen_mstateen0_IMSIC"),
    ("input", "", "io_in_xstateen_hstateen0_IMSIC"),
    ("output", "", "io_out_indirectCSR_EX_II"),
    ("output", "", "io_out_indirectCSR_EX_VI"),
]


def golden_contract_check() -> List[str]:
    errors: list[str] = []
    if not GOLDEN_PATH.is_file():
        return [f"missing golden file: {GOLDEN_PATH}"]
    digest = hashlib.sha256(GOLDEN_PATH.read_bytes()).hexdigest()
    if digest != GOLDEN_SHA256:
        errors.append(f"golden sha256 changed: expected {GOLDEN_SHA256}, got {digest}")
    text = GOLDEN_PATH.read_text()
    module = re.search(r"module\s+IndirectCSRPermitModule\s*\((.*?)\);", text, re.S)
    if not module:
        return errors + ["golden module declaration not found"]
    ports = []
    for raw in module.group(1).split(","):
        line = " ".join(raw.split())
        match = re.match(r"(input|output)\s+(?:logic\s+)?(\[[^]]+\])?\s*(\w+)$", line)
        if not match:
            errors.append(f"unparsed golden port: {line!r}")
            continue
        ports.append((match.group(1), match.group(2) or "", match.group(3)))
    if ports != EXPECTED_PORTS:
        errors.append(f"golden ports changed: expected {EXPECTED_PORTS!r}, got {ports!r}")
    for needle in (
        "io_in_aia_miselect > 64'h2F",
        "io_in_aia_miselect < 64'h40",
        "io_in_aia_siselect > 64'h6F",
        "io_in_aia_vsiselect < 64'h100",
        "io_in_csrAccess_addr == 12'h351",
        "io_in_csrAccess_addr == 12'h151",
        "io_in_csrAccess_addr == 12'h251",
        "io_in_xstateen_hstateen0_IMSIC",
    ):
        if needle not in text:
            errors.append(f"golden structural condition missing: {needle}")
    return errors


def generated_contract_check() -> List[str]:
    errors: list[str] = []
    if not RTL_PATH.is_file():
        return [f"missing generated RTL: {RTL_PATH}"]
    text = RTL_PATH.read_text()
    if "module xs_IndirectCSRPermitModule_core" not in text:
        errors.append("readable core missing")
    if "module IndirectCSRPermitModule" not in text:
        errors.append("flattened wrapper missing")
    if re.search(r"_GEN_|_T\d", text):
        errors.append("generated temporary identifier remains")
    for port_name in (port[2] for port in EXPECTED_PORTS):
        if port_name not in text:
            errors.append(f"wrapper port missing: {port_name}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="check source and golden contract")
    args = parser.parse_args()
    errors = golden_contract_check() + generated_contract_check()
    if errors:
        for error in errors:
            print(f"gen_csr_permit: ERROR: {error}")
        return 1
    if args.check:
        print("gen_csr_permit --check: OK (IndirectCSRPermitModule + golden contract)")
        return 0
    print(f"gen_csr_permit: {RTL_PATH} is already the canonical generated output")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
