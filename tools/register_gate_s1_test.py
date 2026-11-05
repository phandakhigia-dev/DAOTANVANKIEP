#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path

BLUEPRINT = Path(__file__).resolve().parent.parent

def main():
    p = BLUEPRINT / "tests" / "test_runner.gd"
    text = p.read_text(encoding="utf-8")

    if 'test_gate_s1' not in text:
        text = text.replace(
            'var test_gate_s0 = load("res://tests/unit/test_gate_s0_stability.gd")',
            'var test_gate_s0 = load("res://tests/unit/test_gate_s0_stability.gd")\n\tvar test_gate_s1 = load("res://tests/unit/test_gate_s1_movement_and_content.gd")'
        )
        text = text.replace(
            'test_gate_s0.run_all_tests()',
            'test_gate_s0.run_all_tests(),\n\t\ttest_gate_s1.run_all_tests()'
        )
        p.write_text(text, encoding="utf-8")
        print("Registered test_gate_s1 in test_runner.gd")
    else:
        print("test_gate_s1 already registered")

if __name__ == "__main__":
    main()
