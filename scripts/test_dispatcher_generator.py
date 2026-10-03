#!/usr/bin/env python3
"""Focused contract tests for the Dispatcher 200c generator.

The parser is intentionally fail-closed: changing a golden acceptance mask,
removing a routed field, or changing a ready fan-in must make generation fail.
"""
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import gen_dispatcher_200c as gen


class DispatcherGeneratorTest(unittest.TestCase):
    def test_every_target_has_distinct_proven_acceptance_contract(self):
        infos = [gen.parse(name) for name in gen.TARGETS]
        self.assertEqual(len(infos), 13)
        self.assertEqual([i['module'] for i in infos], gen.TARGETS)
        expected = {
            'Dispatcher': [0x40, 0x80, 0x400],
            'Dispatcher_1': [0x2, 0x1],
            'Dispatcher_10': [0x800, 0x1000],
            'Dispatcher_13': [0x2000000, 0x80000, 0x200000, 0x100000],
            'Dispatcher_14': [0x1000000, 0x8000000, 0x40000, 0x40000000],
            'Dispatcher_15': [0x2000000, 0x80000],
            'Dispatcher_16': [0x1000000],
            'Dispatcher_17': [0x4000000, 0x400000],
            'Dispatcher_4': [0x40],
            'Dispatcher_5': [0x2, 0x1, 0x4, 0x10000000, 0x20000000, 0x8],
            'Dispatcher_7': [0x20, 0x200, 0x100],
            'Dispatcher_8': [0x800, 0x2000, 0x10, 0x1000],
            'Dispatcher_9': [0x4000],
        }
        for info in infos:
            self.assertEqual([mask for _, mask in info['accepts']], expected[info['module']])
            self.assertEqual(info['nslots'], len(expected[info['module']]))

    def test_non_direct_route_is_rejected(self):
        original = gen.GOLDEN
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source = original / 'Dispatcher_4.sv'
            mutated = root / source.name
            text = source.read_text().replace(
                'assign io_out_0_bits_fuOpType = io_in_bits_fuOpType;',
                'assign io_out_0_bits_fuOpType = 9\'h0;', 1)
            mutated.write_text(text)
            with mock.patch.object(gen, 'GOLDEN', root):
                with self.assertRaises(ValueError):
                    gen.parse('Dispatcher_4')

    def test_ready_fan_in_is_checked(self):
        original = gen.GOLDEN
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source = original / 'Dispatcher.sv'
            mutated = root / source.name
            text = source.read_text().replace(
                'assign io_in_ready = &{io_out_0_ready, io_out_1_ready, io_out_2_ready};',
                'assign io_in_ready = io_out_0_ready;', 1)
            mutated.write_text(text)
            with mock.patch.object(gen, 'GOLDEN', root):
                with self.assertRaises(ValueError):
                    gen.parse('Dispatcher')


if __name__ == '__main__':
    unittest.main()
