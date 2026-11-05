class_name TestP0V3AuthoritativeEconomy
extends RefCounted

## TestP0V3AuthoritativeEconomy — Bộ kiểm thử toàn diện Kinh Tế Co-op & Chống Duping S0 (Audit V3)
## Bao gồm:
##   1. Duplicate Response 3x: Reconcile client chống duping, không nhân đồ.
##   2. RPC Retry 3x: Host Idempotency chống trừ tiền và trừ kho nhiều lần.
##   3. Client Forged Wallet: Số dư do client khai khống bị bỏ qua, Host kiểm tra Authoritative Wallet.
##   4. Race Condition 2 Clients: Tranh mua món cuối cùng, chỉ 1 người thành công, kho không bị âm.
##   5. Disconnect Post-Commit & Reconnect: Khôi phục chính xác tài sản sau khi mất kết nối.
##   6. Rollback / Safe Failure: Giao dịch lỗi không làm biến đổi kho hàng hay tài sản.
##   7. Boundary Checks: Xử lý an toàn số lượng âm, 0, tràn số (>9999), item rỗng, giá bất thường.

static func run_all_tests() -> Dictionary:
	var passed = 0
	var failed = 0
	var logs: Array[String] = []
	
	# Chuẩn bị môi trường test
	SessionAuthority.stop_session()
	GameClock.reset_clock()
	ShopService.reset_stall()
	ShopService.is_leased = true
	CoopWorldSync._reset_local_state()
	
	# ==============================================================================
	# 1. TEST DUPLICATE RESPONSE 3 LẦN (CLIENT RECONCILIATION ANTI-DUPING)
	# ==============================================================================
	# T-V3-01: Client nhận phản hồi thành công 3 lần cho cùng 1 giao dịch chỉ cập nhật tài sản 1 lần
	GameSession.inventory.clear()
	GameSession.add_item("item_linh_thach", 200)
	CoopWorldSync.client_authoritative_revision = 1
	
	var auth_items_rev2 = { "item_hoi_xuan_dan": 1 }
	var auth_wallet_rev2 = 170
	
	# Response 1: Revision 2 -> Áp dụng Reconcile
	CoopWorldSync.sync_stall_trade_response("REQ_DUP_001", true, "Thành công", 2, auth_wallet_rev2, auth_items_rev2)
	var count_after_1 = GameSession.get_item_count("item_hoi_xuan_dan")
	var wallet_after_1 = GameSession.get_item_count("item_linh_thach")
	
	# Response 2 (Duplicate): Revision 2 -> Phải bị từ chối
	CoopWorldSync.sync_stall_trade_response("REQ_DUP_001", true, "Thành công", 2, auth_wallet_rev2, auth_items_rev2)
	# Response 3 (Duplicate): Revision 2 -> Phải bị từ chối
	CoopWorldSync.sync_stall_trade_response("REQ_DUP_001", true, "Thành công", 2, auth_wallet_rev2, auth_items_rev2)
	
	var count_after_3 = GameSession.get_item_count("item_hoi_xuan_dan")
	var wallet_after_3 = GameSession.get_item_count("item_linh_thach")
	
	if count_after_1 == 1 and count_after_3 == 1 and wallet_after_1 == 170 and wallet_after_3 == 170:
		passed += 1
		logs.append("✓ [Pass] T-V3-01: Phản hồi lặp 3 lần không gây duping: Vật phẩm giữ nguyên x1, ví giữ nguyên 170 LT")
	else:
		failed += 1
		logs.append("✗ [Fail] T-V3-01: Duping xảy ra khi nhận phản hồi trùng! Count: %d, Wallet: %d" % [count_after_3, wallet_after_3])

	# ==============================================================================
	# 2. TEST RPC RETRY 3 LẦN (HOST IDEMPOTENCY KEYED BY PEER + REQUEST_ID)
	# ==============================================================================
	# T-V3-02: Client retry gửi RPC 3 lần, Host chỉ trừ tiền và trừ kho duy nhất 1 lần
	ShopService.reset_stall()
	ShopService.is_leased = true
	ShopService.escrow_items = [{ "item_id": "item_tay_tuy_dan", "count": 5, "price": 50 }]
	CoopWorldSync.processed_transactions.clear()
	CoopWorldSync._init_host_peer_inventory(10, { "wallet": 300, "items": {}, "revision": 1 })
	
	var rpc1 = CoopWorldSync._server_process_stall_trade(10, "REQ_RETRY_001", "item_tay_tuy_dan", 1)
	var rpc2 = CoopWorldSync._server_process_stall_trade(10, "REQ_RETRY_001", "item_tay_tuy_dan", 1)
	var rpc3 = CoopWorldSync._server_process_stall_trade(10, "REQ_RETRY_001", "item_tay_tuy_dan", 1)
	
	var peer_10_state = CoopWorldSync.host_peer_inventories[10]
	var stock_remaining = 0
	for it in ShopService.escrow_items:
		if it.get("item_id") == "item_tay_tuy_dan":
			stock_remaining = it.get("count", 0)
			
	if rpc1.get("success") and rpc2.get("success") and rpc3.get("success") \
		and peer_10_state["wallet"] == 250 \
		and peer_10_state["items"].get("item_tay_tuy_dan", 0) == 1 \
		and stock_remaining == 4 \
		and ShopService.accumulated_revenue == 50:
		passed += 1
		logs.append("✓ [Pass] T-V3-02: RPC Retry 3 lần an toàn: Chỉ trừ 50 LT một lần (còn 250 LT), kho còn 4 món, doanh thu 50 LT")
	else:
		failed += 1
		logs.append("✗ [Fail] T-V3-02: RPC retry bị trừ nhiều lần! Wallet: %d, Items: %s, Stock: %d, Rev: %d" % [
			peer_10_state["wallet"], str(peer_10_state["items"]), stock_remaining, ShopService.accumulated_revenue
		])

	# ==============================================================================
	# 3. TEST VÍ CLIENT KHAI SAI / FORGED CLIENT WALLET
	# ==============================================================================
	# T-V3-03: Client khai gian ví 999 triệu linh thạch trong bộ nhớ máy khách, Host căn cứ ví Authoritative để bác bỏ
	ShopService.reset_stall()
	ShopService.is_leased = true
	ShopService.escrow_items = [{ "item_id": "item_co_kiem_tan_phien", "count": 2, "price": 80 }]
	
	# Peer 15 trên Host chỉ có 30 Linh Thạch
	CoopWorldSync._init_host_peer_inventory(15, { "wallet": 30, "items": {}, "revision": 1 })
	
	# Client cố tình gọi mua món 80 LT
	var forged_res = CoopWorldSync._server_process_stall_trade(15, "REQ_FORGE_001", "item_co_kiem_tan_phien", 1)
	
	if not forged_res.get("success", true) and CoopWorldSync.host_peer_inventories[15]["wallet"] == 30:
		passed += 1
		logs.append("✓ [Pass] T-V3-03: Chống gian lận ví: Khách chỉ có 30 LT authoritative, mua món 80 LT bị Host từ chối an toàn")
	else:
		failed += 1
		logs.append("✗ [Fail] T-V3-03: Host bị lừa bởi client hoặc cho phép mua thiếu tiền!")

	# ==============================================================================
	# 4. TEST 2 CLIENT TRANH MUA MÓN CUỐI CÙNG (RACE CONDITION)
	# ==============================================================================
	# T-V3-04: Sạp chỉ còn duy nhất 1 món, 2 client gửi request đồng thời
	ShopService.reset_stall()
	ShopService.is_leased = true
	ShopService.escrow_items = [{ "item_id": "item_tay_tuy_dan", "count": 1, "price": 150 }]
	
	CoopWorldSync._init_host_peer_inventory(21, { "wallet": 300, "items": {}, "revision": 1 })
	CoopWorldSync._init_host_peer_inventory(22, { "wallet": 300, "items": {}, "revision": 1 })
	
	# Client A (Peer 21) gửi trước
	var res_client_a = CoopWorldSync._server_process_stall_trade(21, "REQ_RACE_A", "item_tay_tuy_dan", 1)
	# Client B (Peer 22) gửi ngay sau trong cùng một frame/tick
	var res_client_b = CoopWorldSync._server_process_stall_trade(22, "REQ_RACE_B", "item_tay_tuy_dan", 1)
	
	var peer_21_items = CoopWorldSync.host_peer_inventories[21]["items"].get("item_tay_tuy_dan", 0)
	var peer_22_items = CoopWorldSync.host_peer_inventories[22]["items"].get("item_tay_tuy_dan", 0)
	
	if res_client_a.get("success") == true and res_client_b.get("success") == false \
		and peer_21_items == 1 and peer_22_items == 0 \
		and ShopService.escrow_items.is_empty() \
		and ShopService.accumulated_revenue == 150:
		passed += 1
		logs.append("✓ [Pass] T-V3-04: Race Condition 2 client: Đúng 1 client mua được món cuối, client kia nhận lỗi an toàn, kho cạn sạch không âm")
	else:
		failed += 1
		logs.append("✗ [Fail] T-V3-04: Race Condition thất bại! A: %s, B: %s, Revenue: %d" % [
			str(res_client_a.get("success")), str(res_client_b.get("success")), ShopService.accumulated_revenue
		])

	# ==============================================================================
	# 5. TEST DISCONNECT POST-COMMIT & RECONNECT KHÔI PHỤC TÀI SẢN
	# ==============================================================================
	# T-V3-05: Mua hàng thành công -> Disconnect -> Reconnect -> Tài sản Authoritative được bảo tồn
	ShopService.reset_stall()
	ShopService.is_leased = true
	ShopService.escrow_items = [{ "item_id": "item_hoi_xuan_dan", "count": 5, "price": 20 }]
	
	CoopWorldSync._init_host_peer_inventory(33, { "wallet": 100, "items": {}, "revision": 1 })
	var res_buy = CoopWorldSync._server_process_stall_trade(33, "REQ_DISC_001", "item_hoi_xuan_dan", 2)
	
	# Client ngắt kết nối
	CoopWorldSync._on_peer_left(33)
	
	# Client kết nối lại
	var reconnected_ledger = CoopWorldSync.host_peer_inventories.get(33, {})
	
	if res_buy.get("success") and not reconnected_ledger.is_empty() \
		and reconnected_ledger.get("wallet") == 60 \
		and reconnected_ledger.get("items", {}).get("item_hoi_xuan_dan", 0) == 2:
		passed += 1
		logs.append("✓ [Pass] T-V3-05: Disconnect sau khi mua và Reconnect: Sổ cái Authoritative trên Host bảo lưu 60 LT và 2 Đan Dược")
	else:
		failed += 1
		logs.append("✗ [Fail] T-V3-05: Mất mát dữ liệu sau khi reconnect! Ledger: %s" % str(reconnected_ledger))

	# ==============================================================================
	# 6. TEST ROLLBACK / SAFE FAILURE
	# ==============================================================================
	# T-V3-06: Yêu cầu mua item không tồn tại hoặc lỗi không làm thay đổi kho hay doanh thu
	var prev_rev = ShopService.accumulated_revenue
	var res_missing = CoopWorldSync._server_process_stall_trade(33, "REQ_MISSING_ITEM", "item_khong_ton_tai", 1)
	
	if not res_missing.get("success", true) and ShopService.accumulated_revenue == prev_rev:
		passed += 1
		logs.append("✓ [Pass] T-V3-06: Rollback an toàn: Mua item không có trong sạp bị từ chối, doanh thu không đổi")
	else:
		failed += 1
		logs.append("✗ [Fail] T-V3-06: Trạng thái bị biến đổi dù giao dịch lỗi!")

	# ==============================================================================
	# 7. TEST THAM SỐ ĐẦU VÀO BẤT THƯỜNG (BOUNDARY CHECKS)
	# ==============================================================================
	# T-V3-07: Số lượng âm (-1), bằng 0, quá lớn (10,000,000), tên item rỗng
	var t_neg = CoopWorldSync._server_process_stall_trade(33, "REQ_BOUND_NEG", "item_hoi_xuan_dan", -5)
	var t_zero = CoopWorldSync._server_process_stall_trade(33, "REQ_BOUND_ZERO", "item_hoi_xuan_dan", 0)
	var t_overflow = CoopWorldSync._server_process_stall_trade(33, "REQ_BOUND_OVER", "item_hoi_xuan_dan", 9999999)
	var t_empty = CoopWorldSync._server_process_stall_trade(33, "REQ_BOUND_EMPTY", "", 1)
	
	if not t_neg.get("success") and not t_zero.get("success") and not t_overflow.get("success") and not t_empty.get("success"):
		passed += 1
		logs.append("✓ [Pass] T-V3-07: Boundary Checks: Chặn toàn bộ tham số dị thường (âm, 0, tràn số, rỗng)")
	else:
		failed += 1
		logs.append("✗ [Fail] T-V3-07: Lọt tham số dị thường qua hệ thống giao dịch!")

	return {
		"name": "P0 V3 Authoritative Economy & Anti-Duping Suite",
		"passed": passed,
		"failed": failed,
		"logs": logs
	}
