extends Node

## EventBus — Bộ truyền tin Signal trung tâm của Đạo Tàn: Vạn Kiếp
## Tách biệt Presentation và Domain/Systems.

signal day_advanced(day: int, month: int, year: int)
signal month_advanced(month: int, year: int)
signal game_saved(slot: int, file_path: String)
signal game_loaded(slot: int, success: bool)
signal player_hp_changed(current_hp: int, max_hp: int)
signal player_mp_changed(current_mp: int, max_mp: int)
signal player_realm_changed(new_realm_id: String)
signal player_moved(new_position: Vector2)
signal world_loaded(seed_value: int)
signal notification_requested(message: String, type: String)

# Phase 1 Signals:
signal inventory_changed
signal quest_updated(quest_id: String, step_index: int, state: String)
signal npc_affinity_changed(npc_id: String, new_affinity: int)

# Phase 2 Signals:
signal time_ticked(hour: int, minute: int)
signal hour_advanced(hour: int, day: int)
signal canh_gio_changed(canh_gio_name: String, is_night: bool)
signal time_scale_changed(new_scale: float)
signal monthly_simulation_completed(month: int, year: int, summary: Dictionary)
signal memory_event_logged(event_data: Dictionary)
signal open_monthly_summary_requested(summary_data: Dictionary)
signal open_social_panel_requested
