# Auth Social Login Contract

## Social Login

Endpoint: `POST /api/auth/social-login`

Also available under versioned routing: `POST /api/v1/auth/social-login`

Input JSON:

```json
{
  "provider": "GOOGLE",
  "providerToken": "provider-issued-token",
  "nonce": "optional-client-nonce",
  "platform": "android"
}
```

Provider values:

- `GOOGLE`
- `FACEBOOK`

Output: existing API envelope containing `AuthResponse`.

```json
{
  "success": true,
  "message": "OK",
  "data": {
    "user": {
      "id": "user-id",
      "email": "user@example.com",
      "fullName": "User Name",
      "role": "USER",
      "active": true,
      "onboardingCompleted": false
    },
    "tokens": {
      "accessToken": "vfit-jwt",
      "refreshToken": "vfit-refresh-token",
      "expiresInMs": 3600000
    }
  }
}
```

Rules:

- Backend MUST verify provider token before any user state change.
- Backend MUST issue V-FIT JWTs only after verification succeeds.
- Backend MUST NOT return raw provider tokens.
- Provider plus provider subject MUST resolve to at most one V-FIT user.
- Existing email/password users MAY be linked by verified email when no
  conflicting provider link exists.
- Disabled users MUST be rejected even when provider verification succeeds.

Error cases:

- Invalid provider token: explicit auth error, no user mutation.
- Missing verified email: explicit auth error, no user mutation.
- Provider subject already linked to another user: conflict error.
- Existing V-FIT user disabled: disabled-account error.
- Provider verification service unavailable: explicit temporary auth error.
