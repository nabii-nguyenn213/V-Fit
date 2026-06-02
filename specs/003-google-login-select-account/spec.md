# Feature Specification: Google Login Force Account Selection

**Feature Branch**: `003-google-login-select-account`

**Created**: 2026-06-02

**Status**: Draft

**Input**: User description: "t muốn khi đăng nhập gg vaãn phải cso chọn tk nhỡ t có nhiều tài khoản mà cứ đăng nhập vào luôn như thế thì sao mà chọn tkhoan đc"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Force Google Account Selection (Priority: P1)

When a user triggers Google Sign-In, the application must always display the Google account selection screen (picker) to let them choose which Google account to log in with, even if they have previously signed in or have a cached session.

**Why this priority**: Essential for users with multiple Google accounts (e.g., personal, work, or school accounts) to switch between them. Automatically logging in using a cached session prevents multi-account users from selecting their preferred account.

**Independent Test**: Trigger Google Sign-In multiple times. Verify that the Google account chooser modal always displays on each sign-in click, rather than automatically signing in with the previous user session.

**Acceptance Scenarios**:

1. **Given** a user with multiple Google accounts on the device, **When** they tap the "Sign in with Google" button, **Then** the Google account picker MUST be shown.
2. **Given** a user who has previously signed in with a Google account and logged out, **When** they tap "Sign in with Google" again, **Then** the Google account picker MUST be shown to allow choosing the same or a different account (rather than automatically signing in with the cached account).
3. **Given** the Google account picker is displayed, **When** the user selects an account, **Then** the sign-in flow MUST proceed with the chosen account credentials.
4. **Given** the Google account picker is displayed, **When** the user cancels or dismisses the picker, **Then** the sign-in flow MUST abort gracefully, resetting the loading state and keeping the user on the login screen.

---

### Edge Cases

- **No Google accounts on device**: If no Google account is signed in on the device, the system should prompt the user to add a Google account.
- **Network failure**: If a network failure occurs during account choosing or token exchange, the system must show a user-friendly error message and reset the login screen state.
- **User cancels picker**: If the user dismisses the Google account selection dialog, the application must not hang or remain in a loading/blocked state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The application MUST display the Google account picker every time the user taps the Google Sign-In button.
- **FR-002**: The application client MUST explicitly sign out or clear any cached Google Sign-In session prior to invoking the Google sign-in dialog.
- **FR-003**: The application MUST handle user cancellation of the Google account picker gracefully, returning the user to the login screen and resetting any loading indicators.
- **FR-004**: Force account selection MUST be supported on both Android and Web platforms.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The Google account picker dialog is presented in 100% of tested "Sign in with Google" button clicks.
- **SC-002**: Users can select a different Google account from the picker and successfully log in with that account.
- **SC-003**: Cancelling the account chooser terminates the flow within 1 second and returns control to the login screen.

## Assumptions

- Google sign-in is implemented using the `google_sign_in` package for Flutter.
- Signing out of Google Sign-in locally via the client SDK before calling the sign-in method is sufficient to force the native OS or web account chooser.
- No V-FIT backend changes are required since the backend only verifies the received token.
