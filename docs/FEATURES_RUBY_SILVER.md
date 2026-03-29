# FastQuiz – Ruby Interview Test

Feature overview and usage flow for FastQuiz: Ruby Silver timed room-based exams.

---

## Overview

- **Exam source:** Local question bank (`exam_ruby_silver/*.json`), 17 topics, ~590 questions. Each exam picks 50 random questions via `CreateExamFromBankService`.
- **Flow:** Host creates exam → creates room (start time, duration) → shares room link. Candidates join room, enter name (and/or candidate ID if configured), start when room opens. Submissions stored per attempt; leaderboard and CSV export available.
- **Auth:** User role `host` creates exams/rooms; `user` or anonymous can join and take exams (login required to submit).
- **Models:** `ExamSession`, `Question`, `QuestionChoice`, `QuestionCorrectAnswer`, `BankQuestion`, `BankQuestionChoice`, `QuestionTopic`, `ExamRoom`, `ExamAttempt`, `User`.

---

## Implemented Features

### 1. Host dashboard
- `GET /dashboard` — Host sees "My rooms".
- List of rooms created by current user: name, exam, start time, status (Upcoming / In progress / Ended).
- Links to Room, Results, Delete for each room.

### 2. Room linked to creator
- `exam_rooms.created_by_id` (FK → users). Set `created_by_id: current_user.id` on create.
- Only creator sees "Start exam now" and "Delete" buttons.

### 3. Live participants (Turbo Streams)
- On room page: "Participants: X joined, Y submitted" updates in real time.
- Uses Action Cable (Solid Cable) + Turbo Streams; `broadcast_update_to` when new attempt or submission.

### 4. Candidate identifier
- `exam_attempts.candidate_identifier` (string, optional).
- "Start exam" form has "Email or candidate ID" field (optional or required per room).
- Results and CSV export include candidate_identifier column.

### 5. Question shuffle
- **Question order:** Shuffled by seed from room (same room → same order) or attempt (when no room).
- **Choice order:** Not shuffled; always A, B, C, D to avoid confusion with "A and C" style answers.
- UI shows A. B. C. D. for each choice.

### 6. Export CSV
- `GET rooms/:room_code/results.csv` — Download leaderboard (Rank, Name, Candidate ID, Score, Total, Submitted at).
- Host (creator) only.

### 7. Start now (host control)
- "Start exam now" button on room page (when not yet started).
- `PATCH rooms/:room_code/start_now` — sets `starts_at = Time.current`.

### 8. Ruby-focused defaults
- Pre-exams: "Ruby 3.1.x Silver Exam", 50 questions, 60 min, pass 40.
- Room name placeholder: "Ruby Backend – YYYY-MM-DD".
- Branding: "Ruby Interview Test", "Schedule a Ruby quiz".

### 9. Require display name / candidate ID
- `exam_rooms.require_display_name` (default true).
- `exam_rooms.require_candidate_identifier` (default false).
- Validated before allowing Start exam.

### 10. Custom instructions
- `exam_rooms.instructions` (text, optional). Shown on room page, above Start exam form.

### 11. Local question bank (no API)
- Questions in `exam_ruby_silver/*.json` (literals, conditionals, exceptions, blocks, ...).
- Seed: `bin/rails db:seed_question_bank`.
- Supports single and multiple choice.

### 12. Delete room
- Host (creator) deletes room → deletes all related exam_attempts (`dependent: :destroy`).
- Delete button on dashboard and room page.

### 13. Exam → room UX flow
- "Exam created" page has CTA "Schedule a room for this exam" → pre-selects exam on room form.
- Clear distinction: Exam link (solo) vs Room link (timed room with leaderboard).

### 14. Detailed results
- Result page: topic badge, per-question correct/incorrect, explanations.
- Multiple choice questions show "(Multiple answers)" label and square icon; single choice uses circle icon.

---

## Main Routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Home |
| GET | `/dashboard` | Host dashboard (my rooms) |
| GET | `/pre_exams` | Create exam form |
| POST | `/pre_exams/create_test` | Create exam (50 random questions) |
| GET | `/pre_exams/created` | Post-create exam page |
| GET | `/exams` | Take exam (needs exam_code, room_code if in room) |
| POST | `/exams` | Submit answers |
| GET | `/exams/:id` | View detailed results |
| GET | `/rooms/new` | Create room form |
| POST | `/rooms` | Create room |
| GET | `/rooms/:room_code` | Room page (countdown, Start exam) |
| DELETE | `/rooms/:room_code` | Delete room (creator only) |
| PATCH | `/rooms/:room_code/start_now` | Start early (host only) |
| GET | `/rooms/:room_code/participants` | JSON participants (count, list) |
| GET | `/rooms/:room_code/results` | Leaderboard (HTML, CSV) |

---

## Stack

- Rails 8.1, Ruby 3.4
- SQLite (development + production)
- Solid Cable (Action Cable, no Redis needed)
- Solid Queue, Solid Cache
- Vite + Tailwind CSS, Stimulus, Turbo
- Kamal deploy

---

## Possible Extensions

- **Invite by email:** Send room link to a list of emails (requires mailer).
- **Custom quiz:** Create exams manually (add questions, pick from bank) instead of random.
- **Tag/category:** Filter exams by tag (ruby, rails) on dashboard.
