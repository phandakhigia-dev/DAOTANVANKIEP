#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path

BLUEPRINT = Path(__file__).resolve().parent.parent

def main():
    p = BLUEPRINT / "scenes" / "world" / "province_world.gd"
    text = p.read_text(encoding="utf-8")

    old_code = """	if CoopWorldSync:
		CoopWorldSync.remote_player_updated.connect(_on_remote_player_updated)
		CoopWorldSync.remote_player_removed.connect(_on_remote_player_removed)
		if CoopWorldSync.has_signal("entity_harvested_synced"):
			CoopWorldSync.entity_harvested_synced.connect(_on_entity_harvested_synced)"""

    new_code = """	if CoopWorldSync:
		if not CoopWorldSync.remote_player_updated.is_connected(_on_remote_player_updated):
			CoopWorldSync.remote_player_updated.connect(_on_remote_player_updated)
		if not CoopWorldSync.remote_player_removed.is_connected(_on_remote_player_removed):
			CoopWorldSync.remote_player_removed.connect(_on_remote_player_removed)
		if CoopWorldSync.has_signal("entity_harvested_synced") and not CoopWorldSync.entity_harvested_synced.is_connected(_on_entity_harvested_synced):
			CoopWorldSync.entity_harvested_synced.connect(_on_entity_harvested_synced)"""

    if old_code in text:
        text = text.replace(old_code, new_code)
        p.write_text(text, encoding="utf-8")
        print("Guarded CoopWorldSync connections in province_world.gd")
    else:
        print("Pattern not found or already guarded")

if __name__ == "__main__":
    main()
