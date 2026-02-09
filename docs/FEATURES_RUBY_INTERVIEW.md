# FastQuiz as Ruby Interview Test – Feature Plan

This document outlines features to position FastQuiz as a **Ruby test platform for interview sessions**: one host creates a room, shares a link, and a group of candidates take the same Ruby quiz with timed, scored results.

---

## Current State (Summary)

- **Exam source:** Viblo Learn API (create exam by `exam_id` + language). AI (OpenRouter/Gemini) can fill correct answers.
- **Flow:** Host creates exam → creates room (start time, duration) → shares room link. Candidates join by room code, enter display name, start when room opens. Submissions stored per attempt; results page shows leaderboard.
- **Auth:** Users with role `host` can create exams/rooms; `user` or anonymous can join and take exams.
- **Models:** `ExamSession`, `Question`, `ExamRoom`, `ExamAttempt` (token, display_name, submissions).

---

## Proposed Features (Priority Order)

### 1. Host dashboard (interviewer home)

- **Goal:** Host sees “My rooms” and quick actions instead of only “Create exam” / “Schedule room”.
- **Details:**
  - List rooms created by current user (requires `created_by_id` on `exam_rooms`).
  - For each room: name, exam title, start time, status (upcoming / in progress / ended), link to room page, link to results.
  - Shortcuts: “Create Ruby exam” (pre-fill or default Viblo Ruby exam id), “Schedule room” (current flow).
- **Routes:** e.g. `get "dashboard", to: "dashboard#index"` (host-only).

### 2. Link rooms to creator

- **Goal:** Support “my rooms” and future permission/visibility rules.
- **Schema:** Add `exam_rooms.created_by_id` (optional, FK to `users.id`). On create, set `created_by_id: current_user.id`.
- **Scopes:** `ExamRoom.where(created_by_id: current_user.id)` for dashboard.

### 3. Live room monitoring (for interviewer)

- **Goal:** Host sees who joined and who submitted without refreshing.
- **Details:**
  - On room show page (host view): “Participants: X joined, Y submitted” with optional list of display names.
  - Option A: Polling (e.g. every 10s) for attempt count and submitted count.
  - Option B: Turbo Streams / Action Cable later for real-time.
- **MVP:** Polling endpoint, e.g. `GET rooms/:room_code/participants` returning JSON; room page for host shows counts and list.

### 4. Candidate identifier (for HR)

- **Goal:** Match results to candidates (e.g. email or HR candidate id) for post-interview use.
- **Schema:** Add `exam_attempts.candidate_identifier` (string, optional). Show field on “Start exam” form when joining room (e.g. “Email or candidate ID (optional)”).
- **Results / export:** Show and export this field so HR can match scores to people.

### 5. Shuffle questions and choices per attempt (fairness)

- **Goal:** Same exam content but different order per candidate to reduce copying.
- **Details:**
  - **Question order:** For each attempt, serve questions in a deterministic random order (e.g. seeded by `attempt_token`). Store order in session or compute in controller when building `@questions`.
  - **Choice order:** Per question, shuffle choice order per attempt (again deterministic from attempt_token + question_id). Front-end must submit `external_choice_id`, not position, so scoring still works.
- **Implementation:** In `ExamsController#index` (and wherever we build `@questions` for that attempt), apply shuffle; pass same order to form and to `build_submissions_from_params` so that submitted `question_id`/`answers` still match backend.

### 6. Export results (CSV)

- **Goal:** HR can download room results (name, candidate id, score, submitted at) for offline use.
- **Details:** On room results page, add “Export CSV” button. Endpoint e.g. `GET rooms/:room_code/results.csv`. Columns: display_name, candidate_identifier, score, total, submitted_at, link to detail (optional).
- **Access:** Only host (or creator) or any authenticated host, depending on policy.

### 7. “Start now” (host control)

- **Goal:** Host can start the room immediately when everyone is present instead of waiting for scheduled time.
- **Details:** On room page (when room not yet started), show “Start exam now” for host. PATCH/PUT `rooms/:room_code/start_now` sets `starts_at = Time.current` (and optionally set `duration_minutes` if blank). Then redirect; candidates see “Start exam” and can enter.

### 8. Ruby-focused defaults and branding

- **Goal:** Reduce friction for “Ruby interview test” use case.
- **Details:**
  - Pre-exams: default `exam_id` to a known Viblo Ruby exam (if any), or add a “Ruby” preset in UI.
  - Room name placeholder: e.g. “Ruby Backend – 2026-02-09”.
  - Home/dashboard copy: “Ruby Interview Test” / “Schedule a Ruby quiz for candidates”.
- **Optional:** Tag or category on `ExamSession` (e.g. “ruby”, “rails”) for filtering in dashboard; can be deferred.

### 9. Require display name or candidate ID per room

- **Goal:** Host can enforce that every participant enters a name or ID (for fair leaderboard and export).
- **Schema:** Add `exam_rooms.require_display_name` (boolean, default true) and `exam_rooms.require_candidate_identifier` (boolean, default false). Validation on join: if required, reject “Start exam” until field is filled.
- **UI:** Room show form shows “Required” and validates before redirect to exam.

### 10. Custom instructions on room page

- **Goal:** Host can show interview-specific instructions (e.g. “Cameras on”, “No external help”).
- **Schema:** Add `exam_rooms.instructions` (text, optional). Render above “Start exam” on room show page.

### 11. Manual / custom Ruby quiz (no Viblo)

- **Goal:** Create a Ruby-only quiz without depending on Viblo API (e.g. company’s own question bank).
- **Details:** New flow: “Create custom exam” → form with title, description, then add questions (body, type single/multi, choices, mark correct). Persist as `ExamSession` (with e.g. `external_exam_id = 0` or a “custom” flag) and `Question`/`QuestionChoice`/`QuestionCorrectAnswer`. No API call; no AI answer key needed (correct answers set manually).
- **Larger feature:** New controller, forms, and possibly `ExamTemplate` or similar if we want to reuse question sets. Can be Phase 2.

### 12. Optional: Invite by email

- **Goal:** Send room link to a list of candidate emails (optional integration).
- **Details:** Host pastes emails; app sends a mail (or a single “Copy link” + template) with room URL. Depends on mailer setup; can be Phase 2.

---

## Suggested Implementation Order

| Phase | Features | Notes |
|-------|----------|--------|
| **1** | (2) Link rooms to creator, (1) Host dashboard | Foundation for “my rooms” and host UX. |
| **2** | (4) Candidate identifier, (6) Export CSV | High value for HR with minimal schema. |
| **3** | (5) Shuffle questions/choices | Fairness; needs careful handling of submission mapping. |
| **4** | (3) Live participants (polling) | Better host experience during interview. |
| **5** | (7) Start now, (8) Ruby branding | Small UX improvements. |
| **6** | (9) Require name/ID, (10) Room instructions | Optional polish. |
| **7** | (11) Custom quiz, (12) Invite by email | Larger; can be separate milestones. |

---

## Technical Notes

- **Shuffle:** Use `Random.new(attempt_token.bytes.sum)` or `Digest::SHA256.hexdigest(attempt_token + question_id.to_s)[0..7].to_i(16)` to get deterministic order per attempt so that reload doesn’t change order and submissions still match questions.
- **Export CSV:** Use `respond_to` in `RoomsController#results` or a dedicated `ResultsExportsController`; set `Content-Disposition: attachment`.
- **Authorization:** For “only room creator can see results / export”, add `before_action` that checks `@room.created_by_id == current_user.id` (or allow any host if you prefer).

This plan turns FastQuiz into a focused **Ruby interview test** tool: one host, one room, one link, timed exam, leaderboard, and export for HR.
