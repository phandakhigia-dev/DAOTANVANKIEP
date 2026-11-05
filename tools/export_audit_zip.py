#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Export Full Project Audit ZIP for Đạo Tàn: Vạn Kiếp
Creates a pristine, standalone audit ZIP archive and SHA-256 manifest.
"""

import os
import sys
import hashlib
import csv
import zipfile
import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
AUDIT_DIR = PROJECT_ROOT / "audit"
EXPORTS_DIR = PROJECT_ROOT / "audit_exports"
MANIFEST_PATH = AUDIT_DIR / "FILE_MANIFEST.csv"

# Exclusion rules
EXCLUDE_DIRS = {
    ".git",
    ".godot",
    "node_modules",
    "audit_exports",
    "__pycache__",
    ".pytest_cache",
    ".vs",
    ".idea",
    "scratch"
}

EXCLUDE_EXTS = {
    ".zip",
    ".pck",
    ".exe",
    ".tmp",
    ".bak",
    ".log",
    ".env",
    ".swp"
}

EXCLUDE_FILES = {
    ".DS_Store",
    "Thumbs.db",
    "desktop.ini"
}

def compute_sha256(filepath: Path) -> str:
    sha = hashlib.sha256()
    try:
        with open(filepath, "rb") as f:
            while chunk := f.read(65536):
                sha.update(chunk)
        return sha.hexdigest()
    except Exception as e:
        return f"ERROR_{e}"

def is_excluded(rel_path: Path) -> tuple[bool, str]:
    parts = rel_path.parts
    for part in parts[:-1]:
        if part in EXCLUDE_DIRS:
            return True, f"Directory '{part}' in exclusion list"
    
    file_name = parts[-1]
    if file_name in EXCLUDE_FILES:
        return True, f"File '{file_name}' in exclusion list"
        
    ext = rel_path.suffix.lower()
    if ext == ".log" and len(parts) > 1 and parts[0] == "audit":
        return False, "" # Cho phép các file raw log kiểm định trong thư mục audit
    if ext in EXCLUDE_EXTS:
        return True, f"Extension '{ext}' in exclusion list"
        
    return False, ""

def main():
    print("=" * 70)
    print("  ĐẠO TÀN: VẠN KIẾP — EXPORT FULL PROJECT AUDIT ZIP TOOL")
    print(f"  Project Root: {PROJECT_ROOT}")
    print("=" * 70)
    
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    EXPORTS_DIR.mkdir(parents=True, exist_ok=True)
    
    date_str = datetime.date.today().strftime("%Y%m%d")
    custom_name = sys.argv[1] if len(sys.argv) > 1 else f"DAO_TAN_VAN_KIEP_THAP_NHI_TINH_AUDIT_V4_{date_str}.zip"
    zip_filename = custom_name
    zip_filepath = EXPORTS_DIR / zip_filename
    
    print("\n[Step 1/5] Quét toàn bộ cây thư mục dự án...")
    all_files = []
    for root, dirs, files in os.walk(PROJECT_ROOT):
        for f in files:
            full_path = Path(root) / f
            rel_path = full_path.relative_to(PROJECT_ROOT)
            all_files.append((full_path, rel_path))
            
    all_files.sort(key=lambda x: str(x[1]).lower())
    print(f"  -> Tìm thấy tổng cộng {len(all_files)} file trong cây thư mục.")
    
    print("\n[Step 2/5] Phân loại và tính mã băm SHA-256...")
    included_files = []
    manifest_rows = []
    
    for full_path, rel_path in all_files:
        # Tạm thời bỏ qua chính file manifest đang chuẩn bị ghi
        if rel_path == Path("audit/FILE_MANIFEST.csv"):
            continue
            
        excluded, reason = is_excluded(rel_path)
        size_bytes = full_path.stat().st_size
        file_type = rel_path.suffix.lower() or "no_ext"
        
        if excluded:
            manifest_rows.append({
                "RelativePath": str(rel_path).replace("\\", "/"),
                "FileType": file_type,
                "SizeBytes": size_bytes,
                "SHA256": "N/A",
                "PackageStatus": f"EXCLUDED: {reason}"
            })
        else:
            sha = compute_sha256(full_path)
            included_files.append((full_path, rel_path, size_bytes, sha))
            manifest_rows.append({
                "RelativePath": str(rel_path).replace("\\", "/"),
                "FileType": file_type,
                "SizeBytes": size_bytes,
                "SHA256": sha,
                "PackageStatus": "INCLUDED"
            })
            
    print(f"  -> Số file INCLUDED: {len(included_files)}")
    print(f"  -> Số file EXCLUDED: {len(manifest_rows) - len(included_files)}")
    
    print("\n[Step 3/5] Tạo tài liệu audit/FILE_MANIFEST.csv...")
    # Thêm chính file FILE_MANIFEST.csv vào danh sách ghi
    manifest_rows.append({
        "RelativePath": "audit/FILE_MANIFEST.csv",
        "FileType": ".csv",
        "SizeBytes": 0, # Placeholder
        "SHA256": "PENDING_SELF_HASH",
        "PackageStatus": "INCLUDED"
    })
    
    fieldnames = ["RelativePath", "FileType", "SizeBytes", "SHA256", "PackageStatus"]
    with open(MANIFEST_PATH, "w", newline="", encoding="utf-8-sig") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for row in manifest_rows:
            writer.writerow(row)
            
    # Tính hash thực tế cho file manifest vừa ghi
    manifest_size = MANIFEST_PATH.stat().st_size
    manifest_sha = compute_sha256(MANIFEST_PATH)
    
    # Cập nhật lại dòng cuối của file manifest với hash thật
    manifest_rows[-1]["SizeBytes"] = manifest_size
    manifest_rows[-1]["SHA256"] = manifest_sha
    with open(MANIFEST_PATH, "w", newline="", encoding="utf-8-sig") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for row in manifest_rows:
            writer.writerow(row)
            
    manifest_size = MANIFEST_PATH.stat().st_size
    manifest_sha = compute_sha256(MANIFEST_PATH)
    included_files.append((MANIFEST_PATH, Path("audit/FILE_MANIFEST.csv"), manifest_size, manifest_sha))
    print(f"  -> Đã tạo {MANIFEST_PATH} ({manifest_size:,} bytes, SHA-256: {manifest_sha[:12]}...)")
    
    print(f"\n[Step 4/5] Đóng gói ZIP: {zip_filename}...")
    total_uncompressed = 0
    with zipfile.ZipFile(zip_filepath, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zipf:
        for full_path, rel_path, size_bytes, sha in included_files:
            archive_name = str(rel_path).replace("\\", "/")
            zipf.write(full_path, archive_name)
            total_uncompressed += size_bytes
            
    zip_size = zip_filepath.stat().st_size
    ratio = (1.0 - (zip_size / total_uncompressed)) * 100 if total_uncompressed > 0 else 0
    print(f"  -> Tạo file ZIP thành công!")
    print(f"     Đường dẫn: {zip_filepath}")
    print(f"     Dung lượng nén: {zip_size:,} bytes ({zip_size / 1024 / 1024:.2f} MB)")
    print(f"     Dung lượng gốc: {total_uncompressed:,} bytes ({total_uncompressed / 1024 / 1024:.2f} MB)")
    print(f"     Tỷ lệ nén: {ratio:.1f}%")
    
    print("\n[Step 5/5] Kiểm tra tính toàn vẹn (Integrity Verification)...")
    with zipfile.ZipFile(zip_filepath, "r") as zipf:
        bad_file = zipf.testzip()
        if bad_file:
            print(f"  [FAIL] Phát hiện file hỏng trong ZIP: {bad_file}")
            sys.exit(1)
        else:
            print("  ✓ [Pass] zipfile.testzip() hoàn tất: Không có lỗi CRC hoặc dữ liệu hỏng.")
            
        namelist = zipf.namelist()
        print(f"  ✓ [Pass] Tổng số file trong archive: {len(namelist)}")
        
        # Kiểm tra sự hiện diện của các file và thư mục cốt lõi
        critical_items = [
            "project.godot",
            "AGENTS.md",
            "PROJECT_AUDIT_INFO.md",
            "FEATURE_STATUS.md",
            "audit/KNOWN_ISSUES.md",
            "audit/PHASE4_ASSET_STATUS.md",
            "audit/MULTIPLAYER_TIME_AUDIT.md",
            "audit/TEST_RESULTS.md",
            "audit/TEST_RESULTS.json",
            "audit/REGRESSION_LOG_RAW.txt",
            "audit/FIX_IMPLEMENTATION.md",
            "audit/FILES_CHANGED.md",
            "audit/REMAINING_ISSUES.md",
            "audit/FILE_MANIFEST.csv",
            "tests/unit/test_s0_stability_regression.gd",
            "scripts/core/game_session.gd",
            "scripts/core/game_clock.gd",
            "scenes/bootstrap/bootstrap.tscn",
            "scenes/world/world_map.tscn",
            "scenes/towns/town_map_real.tscn",
            "data/items/items.json",
            "data/skills/skills.json",
            "data/sects/sects.json",
            "data/npcs/npcs.json",
            "data/balance.json"
        ]
        
        for item in critical_items:
            if item in namelist:
                print(f"  ✓ [Pass] Tìm thấy tệp cốt lõi: {item}")
            else:
                print(f"  [FAIL] Thiếu tệp cốt lõi: {item}")
                sys.exit(1)
                
    zip_sha = compute_sha256(zip_filepath)
    print("\n" + "=" * 70)
    print("  KẾT QUẢ ĐÓNG GÓI HOÀN TẤT THÀNH CÔNG (100% VERIFIED)")
    print(f"  File ZIP:     {zip_filepath}")
    print(f"  Dung lượng:   {zip_size / 1024 / 1024:.2f} MB ({zip_size:,} bytes)")
    print(f"  Số file nén:  {len(included_files)} files")
    print(f"  SHA-256 ZIP:  {zip_sha}")
    print("=" * 70)

if __name__ == "__main__":
    main()
