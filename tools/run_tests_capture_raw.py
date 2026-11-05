#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Run Godot Test Runner and capture RAW stdout/stderr to audit/REGRESSION_LOG_RAW.txt
and generate audit/TEST_RESULTS.json.
"""

import subprocess
import json
import re
import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
GODOT_BIN = r"G:\Game tự làm\tools\godot\godot.cmd"
RAW_LOG_PATH = PROJECT_ROOT / "audit" / "REGRESSION_LOG_RAW.txt"
JSON_RESULTS_PATH = PROJECT_ROOT / "audit" / "TEST_RESULTS.json"

def main():
    print("Running Godot test runner...")
    cmd = [
        GODOT_BIN,
        "--headless",
        "--path", str(PROJECT_ROOT),
        "--scene", "res://tests/test_runner.tscn"
    ]
    
    start_time = datetime.datetime.now()
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
    end_time = datetime.datetime.now()
    raw_output = proc.stdout
    
    # Save raw log as pure UTF-8
    RAW_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(RAW_LOG_PATH, "w", encoding="utf-8") as f:
        f.write(raw_output)
        
    print(f"Saved RAW log to {RAW_LOG_PATH} ({len(raw_output)} chars)")
    
    # Parse structured JSON results
    suite_pattern = re.compile(r"--- Bộ test:\s*(.+?)\s*---")
    pass_pattern = re.compile(r"✓\s*\[(?:Pass|T-\d+)\]\s*(.+)")
    fail_pattern = re.compile(r"✗\s*\[(?:Fail|T-\d+)\]\s*(.+)")
    summary_pattern = re.compile(r"TỔNG KẾT:\s*(\d+)\s*ĐẠT.*?\|\s*(\d+)\s*THẤT BẠI")
    
    suites = []
    current_suite = None
    
    for line in raw_output.splitlines():
        line_s = line.strip()
        suite_m = suite_pattern.match(line_s)
        if suite_m:
            if current_suite:
                suites.append(current_suite)
            current_suite = {
                "suite_name": suite_m.group(1),
                "tests_passed": 0,
                "tests_failed": 0,
                "test_cases": []
            }
            continue
            
        pass_m = pass_pattern.search(line_s)
        if pass_m and current_suite:
            current_suite["tests_passed"] += 1
            current_suite["test_cases"].append({
                "status": "PASS",
                "description": pass_m.group(1).strip()
            })
            continue
            
        fail_m = fail_pattern.search(line_s)
        if fail_m and current_suite:
            current_suite["tests_failed"] += 1
            current_suite["test_cases"].append({
                "status": "FAIL",
                "description": fail_m.group(1).strip()
            })
            continue
            
    if current_suite:
        suites.append(current_suite)
        
    summary_m = summary_pattern.search(raw_output)
    total_passed = int(summary_m.group(1)) if summary_m else sum(s["tests_passed"] for s in suites)
    total_failed = int(summary_m.group(2)) if summary_m else sum(s["tests_failed"] for s in suites)
    
    result_data = {
        "project": "ĐẠO TÀN: VẠN KIẾP",
        "engine": "Godot Engine v4.7.2.stable.official.ed1daf0bf",
        "execution_date": datetime.datetime.now().isoformat(),
        "duration_seconds": (end_time - start_time).total_seconds(),
        "exit_code": proc.returncode,
        "total_suites": len(suites),
        "total_tests": total_passed + total_failed,
        "total_passed": total_passed,
        "total_failed": total_failed,
        "pass_rate_percent": round((total_passed / max(1, total_passed + total_failed)) * 100, 2),
        "suites": suites
    }
    
    with open(JSON_RESULTS_PATH, "w", encoding="utf-8") as jf:
        json.dump(result_data, jf, indent=2, ensure_ascii=False)
        
    print(f"Generated {JSON_RESULTS_PATH} ({total_passed} PASS, {total_failed} FAIL across {len(suites)} suites)")

if __name__ == "__main__":
    main()
