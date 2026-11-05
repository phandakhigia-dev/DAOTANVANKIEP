import os
import sys
import zipfile
import shutil
from pathlib import Path

PROJECT_ROOT = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT")
EXPORTS_DIR = PROJECT_ROOT / "audit_exports"
EXPORTS_DIR.mkdir(parents=True, exist_ok=True)

TARGET_ZIP = EXPORTS_DIR / "DAO_TAN_VAN_KIEP_FOR_CHATGPT.zip"
CONVENIENCE_ZIP = Path("G:/Game tự làm/DAO_TAN_VAN_KIEP_FOR_CHATGPT.zip")

EXCLUDE_DIRS = {
    ".git",
    ".godot",
    "audit_exports",
    "node_modules",
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
    ".swp"
}

EXCLUDE_FILES = {
    ".DS_Store",
    "Thumbs.db",
    "desktop.ini"
}

def is_excluded(rel_path: Path):
    parts = rel_path.parts
    for p in parts[:-1]:
        if p in EXCLUDE_DIRS:
            return True
    if parts[-1] in EXCLUDE_FILES:
        return True
    if rel_path.suffix.lower() in EXCLUDE_EXTS:
        return True
    return False

print("=" * 65)
print("  ĐẠO TÀN: VẠN KIẾP — EXPORT PACKAGE FOR CHATGPT")
print("=" * 65)

included_files = []
total_raw_size = 0

for root, dirs, files in os.walk(PROJECT_ROOT):
    for f in files:
        full_path = Path(root) / f
        rel_path = full_path.relative_to(PROJECT_ROOT)
        if not is_excluded(rel_path):
            size = full_path.stat().st_size
            included_files.append((full_path, rel_path, size))
            total_raw_size += size

included_files.sort(key=lambda x: str(x[1]).lower())
print(f"Tổng số file đóng gói: {len(included_files)}")
print(f"Tổng dung lượng gốc: {total_raw_size:,} bytes ({total_raw_size / 1024 / 1024:.2f} MB)")

print(f"\nĐang nén file zip chất lượng cao: {TARGET_ZIP}...")
with zipfile.ZipFile(TARGET_ZIP, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
    for full_path, rel_path, size in included_files:
        archive_path = str(rel_path).replace("\\", "/")
        zf.write(full_path, archive_path)

zip_size = TARGET_ZIP.stat().st_size
ratio = (1.0 - (zip_size / total_raw_size)) * 100 if total_raw_size > 0 else 0

print(f"-> Nén thành công!")
print(f"   Dung lượng ZIP: {zip_size:,} bytes ({zip_size / 1024 / 1024:.2f} MB)")
print(f"   Tỷ lệ nén: {ratio:.1f}%")

# Integrity test
with zipfile.ZipFile(TARGET_ZIP, "r") as zf:
    bad = zf.testzip()
    if bad:
        print(f"Lỗi kiểm tra tính toàn vẹn: {bad}")
        sys.exit(1)
    print("✓ [Pass] File ZIP toàn vẹn 100%, không có lỗi dữ liệu.")

# Copy to convenience path in root
shutil.copy2(TARGET_ZIP, CONVENIENCE_ZIP)
print(f"✓ Đã sao chép bản thuận tiện tới: {CONVENIENCE_ZIP}")
print("=" * 65)
