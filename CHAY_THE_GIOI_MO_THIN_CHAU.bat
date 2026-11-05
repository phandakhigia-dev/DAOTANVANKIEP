@echo off
title Đạo Tàn: Vạn Kiếp — Thế Giới Mở Thìn Châu
cd /d "%~dp0"
echo ========================================================
echo   ĐẠO TÀN: VẠN KIẾP — KHỞI ĐỘNG THẾ GIỚI MỞ THÌN CHÂU
echo   Đang mở Godot 4.7.2 Engine...
echo ========================================================
start "" "%~dp0tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0DAO_TAN_VAN_KIEP_ANTIGRAVITY_BLUEPRINT" "res://scenes/world/province_world.tscn"
