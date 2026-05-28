# Data Model: AI-Native V-FIT Baseline

## User

Fields: id, email, password hash, full name, avatar, role, active,
onboarding status, goal type, physical metrics, progress, subscription snapshot,
created time, updated time.

Relationships: Owns sessions, tokens, progress snaps, challenge participation,
payments, subscriptions, vouchers, and AI analysis records.

Validation: Email MUST be unique and normalized. Password MUST satisfy policy.
Pending users MUST be blocked from protected routes except onboarding.

## AI Analysis

Fields: user id, flow type, input metadata, raw provider reference, parsed
summary, confidence, fallback flag, created time.

Relationships: Belongs to user and MAY reference exercise, food scan, body scan,
or progress event.

Validation: Output MUST match a typed contract before user display.

## Workout And Exercise

Fields: id, name, muscle group, media, instructions, difficulty, plan metadata,
sets, reps, schedule.

Relationships: Workout programs reference exercises. Personalized plans use goal
metadata and user goal type.

Validation: Catalog ids MUST remain stable for UI routes and AI references.

## Nutrition

Fields: food id, name, normalized name, serving, calories, protein, carbs, fat,
metadata.

Relationships: AI food estimates MAY be compared with searchable food catalog.

Validation: Macro values MUST be numeric and user-facing estimates MUST include
confidence or notes.

## Progress And Gamification

Fields: journey snap id, photo url, note, metrics, badges, challenges,
participation status, rewards, streaks, XP.

Relationships: Progress events MAY trigger gamification reward distribution.

Validation: Progress writes MUST require authenticated active users.

## Payment And Subscription

Fields: payment id, user id, plan, base amount, discount, final amount, voucher,
payment code, QR URL, status, expiry, premium until.

Relationships: Paid transactions unlock user subscription snapshots. Vouchers
belong to users and orders.

Validation: Only one voucher MAY apply per order. VIP renewal MUST respect
renewal window rules.

## App Config

Fields: app name, slogan, support email, terms URL, privacy URL, latest version,
minimum version, maintenance state, maintenance message.

Relationships: Public client configuration and admin management.

Validation: Admin writes MUST validate support email and required text fields.
