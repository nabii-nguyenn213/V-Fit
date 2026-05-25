# V-FIT Premium Payment with VietQR and SePay

## Environment

Configure these values outside source control:

```env
SEPAY_WEBHOOK_SECRET=replace_with_sepay_webhook_secret
SEPAY_BANK_CODE=BIDV
SEPAY_ACCOUNT_NUMBER=123456789
SEPAY_ACCOUNT_NAME=TRAN DUY TRUNG
VIETQR_BASE_URL=https://img.vietqr.io/image
PAYMENT_EXPIRY_MINUTES=15
```

## SePay Dashboard

Set the webhook URL to:

```text
https://san-enclosed-forecasts-ash.trycloudflare.com/api/payments/sepay/webhook
```

Set the signing secret to the same value as `SEPAY_WEBHOOK_SECRET`.

The backend expects the signature in `X-SePay-Signature`. Both plain hex and `sha256=<hex>` are accepted.

## Flutter API

Create a premium payment:

```http
POST /api/payments/create
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "plan": "MONTHLY",
  "voucherCode": "MONTH30"
}
```

Response:

```json
{
  "success": true,
  "message": "Created",
  "data": {
    "paymentId": "6650...",
    "plan": "MONTHLY",
    "baseAmount": 150000,
    "discountAmount": 30000,
    "finalAmount": 120000,
    "bankCode": "BIDV",
    "accountNumber": "123456789",
    "accountName": "TRAN DUY TRUNG",
    "paymentCode": "VFIT20260525123456123",
    "voucherCode": "MONTH30",
    "vietQrUrl": "https://img.vietqr.io/image/BIDV-123456789-compact2.png?amount=120000&addInfo=VFIT20260525123456123&accountName=TRAN+DUY+TRUNG",
    "expiredAt": "2026-05-25T13:15:00Z"
  }
}
```

Supported premium plans:

| Plan | Amount | Duration |
| --- | ---: | ---: |
| `MONTHLY` | 150,000 VND | 30 days |
| `YEARLY` | 1,000,000 VND | 365 days |

Voucher is optional and never supplies an amount from Flutter:

```http
POST /api/payments/create
Authorization: Bearer <jwt>
Content-Type: application/json

{
  "plan": "MONTHLY",
  "voucherCode": "MONTH30"
}
```

The backend resolves `MONTHLY_30K_OFF` from the `vouchers` collection, calculates `150000 - 30000 = 120000`, and generates VietQR with `amount=120000`. `HALF_MONTH_10K_OFF` exists in code but is rejected for `MONTHLY` and `YEARLY` until a half-month plan exists.

Example Mongo voucher for local testing:

```javascript
db.vouchers.updateOne(
  { code: "MONTH30" },
  {
    $setOnInsert: {
      code: "MONTH30",
      type: "MONTHLY_30K_OFF",
      discountAmount: NumberDecimal("30000"),
      applicablePlan: "MONTHLY",
      is_public: true,
      status: "ACTIVE",
      createdAt: new Date(),
      expiredAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    }
  },
  { upsert: true }
)
```

Poll payment status every 3 seconds:

```http
GET /api/payments/{paymentId}/status
Authorization: Bearer <jwt>
```

## Local Test with Cloudflare Tunnel

Run the backend on port `8080`, then expose it:

```powershell
.\CloudFlare\cloudflared.exe tunnel --url http://localhost:8080
```

Use the generated URL in SePay Dashboard:

```text
https://<generated>.trycloudflare.com/api/payments/sepay/webhook
```

For manual webhook testing, sign the exact raw JSON body with HMAC-SHA256 using `SEPAY_WEBHOOK_SECRET`, then send the body and `X-SePay-Signature` header.

Example transfer content:

```text
VFIT20260525123456123
```
