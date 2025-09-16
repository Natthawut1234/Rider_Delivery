<!-- http://localhost:4000/rider/topup-history -->

### 2. ดูประวัติการเติมเงิน
```
GET /api/rider/topup-history
Authorization: Bearer <JWT_TOKEN>
```

**หมายเหตุ:** แสดงเฉพาะประวัติของไรเดอร์ที่เป็นเจ้าของ token

**Response:**
```json
{
    "success": true,
    "data": {
        "topup_history": [
            {
                "topup_id": 8,
                "user_id": 33,
                "rider_id": 8,
                "amount": "2000.00",
                "slip_url": "https://res.cloudinary.com/djqdn2zru/image/upload/v1757985138/rider-topup-slips/fvvqdvp3n1kfncrgnr8w.png",
                "status": "pending",
                "rejection_reason": null,
                "created_at": "2025-09-16T01:12:19.393Z",
                "approved_at": null,
                "updated_at": "2025-09-16T01:12:19.393Z"
            },
        ],
        "statistics": {
            "total_topups": "8",
            "pending_topups": "2",
            "approved_topups": "4",
            "rejected_topups": "2",
            "total_approved_amount": "470.00"
        }
    }
}

### 3. ดูสถานะการเติมเงินรายการเดียว
```
GET /api/rider/topup/{topup_id}/status
Authorization: Bearer <JWT_TOKEN>
```
**หมายเหตุ:** แสดงเฉพาะประวัติของไรเดอร์ที่เป็นเจ้าของ token

**Response:**
{
    "success": true,
    "data": {
        "topup_id": 2,
        "user_id": 33,
        "rider_id": 8,
        "amount": "200.00",
        "slip_url": "https://example.com/slip2.png",
        "status": "approved",
        "rejection_reason": null,
        "created_at": "2025-09-15T13:54:03.134Z",
        "approved_at": null,
        "updated_at": "2025-09-15T13:54:03.134Z"
    }
}