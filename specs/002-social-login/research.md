# Research: Google And Facebook Login

## Decision: Verify Provider Tokens In Backend

Rationale: Flutter should not be the trust boundary. The backend must verify
Google and Facebook credentials before creating users, linking accounts, or
issuing V-FIT JWTs.

Alternatives considered: Trust provider profile returned by Flutter. Rejected
because it bypasses the server-side identity boundary and can create account
spoofing risk.

## Decision: Return Existing AuthResponse

Rationale: `AuthResponse` already contains user and V-FIT token data consumed by
`AuthRepository` and `AuthController`. Reusing it keeps routing and token
storage compatible.

Alternatives considered: Create provider-specific response payloads. Rejected
because the client should treat all successful login methods the same after
backend verification.

## Decision: Use One Social Login Endpoint

Rationale: `POST /api/auth/social-login` with provider type and token keeps the
contract compact while allowing provider-specific verification behind the auth
service.

Alternatives considered: Separate `/google-login` and `/facebook-login`
endpoints. Rejected because they would duplicate response handling and token
issuance code.

## Decision: Scope V1 To Android And Web

Rationale: The requested v1 platform scope is Android and web. Keeping iOS out
of scope avoids provider SDK and OAuth configuration work that is not required
for the first implementation.

Alternatives considered: Support Android, iOS, and web in v1. Rejected because
the user explicitly selected Android and web for v1.

## Decision: Store Provider Link Metadata Without Raw Tokens

Rationale: The system only needs provider, provider subject, verified email,
display name/avatar metadata, and timestamps. Raw provider tokens are sensitive
and short-lived.

Alternatives considered: Store raw tokens for debugging. Rejected because it
creates avoidable credential retention risk.

## Decision: Link By Provider Subject First, Then Verified Email

Rationale: Provider subject is the stable identity key. Verified email is useful
for linking a first social login to an existing email/password account, but it
must not override an already-linked subject.

Alternatives considered: Always create a new user for social login. Rejected
because it would duplicate accounts and break existing profile/subscription
state.
