# C4 Code-Level Documentation: app-controllers

## 1. Overview Section

| Attribute | Value |
|-----------|-------|
| **Name** | app-controllers |
| **Description** | HTTP request handlers for a Ruby on Rails 8 exam prep application. Manage authentication, exam creation, exam rooms, live exams, and results. |
| **Location** | `src/app/controllers` |
| **Language** | Ruby |
| **Purpose** | Handle web requests for user signup/login, host dashboard, exam creation from a question bank, exam room scheduling and management, exam taking, and result viewing. |

---

## 2. Code Elements Section

### 2.1 ApplicationController

**Location:** `src/app/controllers/application_controller.rb`  
**Description:** Base controller with shared auth helpers and before_action filters.

**Parent:** `ActionController::Base`

**Helper methods (exposed to views):**

| Method | Signature | Description |
|--------|------------|-------------|
| `current_user` | `current_user` → `User?` | Returns the logged-in user from `session[:user_id]`, or `nil` |
| `logged_in?` | `logged_in?` → `Boolean` | Returns whether a user is logged in |
| `room_created_by_current_user?` | `room_created_by_current_user?(room)` → `Boolean` | Returns whether the current user is host and creator of the room |

**Private methods:**

| Method | Signature | Description |
|--------|------------|-------------|
| `require_login` | `require_login` → `void` | Redirects to `login_path` if not logged in; stores ` request.fullpath` in `session[:return_to]` for non-mutating requests |
| `require_host` | `require_host` → `void` | Calls `require_login`, then redirects to `root_path` if the user is not a host |

**Dependencies:** `User` model, `session`, `request`

---

### 2.2 HomeController

**Location:** `src/app/controllers/home_controller.rb`  
**Description:** Handles landing page and join-by-room-code flow.

**Parent:** `ApplicationController`

**Actions:**

| Action | HTTP | Params | Description |
|--------|------|--------|-------------|
| `index` | GET | (none) | Renders home page; hosts see Dashboard/Create exam; others see Join/Sign in |
| `join` | GET | `room_code` (String) | Redirects to `room_path(room_code)` when `room_code` is present |

**Views:** `app/views/home/index.html.erb`, `app/views/home/join.html.erb`

---

### 2.3 SessionsController

**Location:** `src/app/controllers/sessions_controller.rb`  
**Description:** Handles sign-in and sign-out.

**Parent:** `ApplicationController`

**Actions:**

| Action | HTTP | Params | Description |
|--------|------|--------|-------------|
| `new` | GET | (none) | Renders login form; sets `@user = User.new` |
| `create` | POST | `email` (String), `password` (String) | Authenticates user; stores `user.id` in `session[:user_id]`; redirects to `return_to` or `root_path` |
| `destroy` | DELETE | (none) | Clears `session[:user_id]`; redirects to `root_path` |

**Private methods:**

| Method | Signature | Description |
|--------|------------|-------------|
| `validate_exam_return_to` | `validate_exam_return_to(path)` → `String?` | Returns `path` if valid; for `/exams?...` paths, checks `exam_code` against `ExamSession`; returns `nil` if exam does not exist |

**Dependencies:** `User`, `ExamSession`, `session`

---

### 2.4 UsersController

**Location:** `src/app/controllers/users_controller.rb`  
**Description:** Handles user registration.

**Parent:** `ApplicationController`

**Actions:**

| Action | HTTP | Params | Description |
|--------|------|--------|-------------|
| `new` | GET | (none) | Renders signup form; sets `@user = User.new` |
| `create` | POST | `user[email]`, `user[password]`, `user[password_confirmation]` | Creates user with role `"user"`; on success sets `session[:user_id]` and redirects to `root_path` |

**Private methods:**

| Method | Signature | Description |
|--------|------------|-------------|
| `user_params` | `user_params` → `ActionController::Parameters` | Permits `:email`, `:password`, `:password_confirmation` |

**Dependencies:** `User`, `session`

---

### 2.5 DashboardController

**Location:** `src/app/controllers/dashboard_controller.rb`  
**Description:** Host dashboard listing created exam rooms.

**Parent:** `ApplicationController`  
**Before action:** `require_host`

**Actions:**

| Action | HTTP | Params | Description |
|--------|------|--------|-------------|
| `index` | GET | (none) | Loads `@rooms` = last 50 rooms created by current user, ordered by `starts_at` desc, with `exam_session` preloaded |

**Dependencies:** `User`, `ExamRoom`, `ExamSession`

---

### 2.6 PreExamsController

**Location:** `src/app/controllers/pre_exams_controller.rb`  
**Description:** Exam creation from question bank.

**Parent:** `ApplicationController`  
**Before action:** `require_host`

**Actions:**

| Action | HTTP | Params | Description |
|--------|------|--------|-------------|
| `index` | GET | (none) | Renders pre-exam creation form |
| `create_test` | POST | (none) | Calls `CreateExamFromBankService`; redirects to `created_pre_exams_path(exam_code: hash_id)` on success |
| `created` | GET | `exam_code` (String) | Renders success page with exam code; redirects to `pre_exams_path` if `exam_code` is blank |

**Dependencies:** `CreateExamFromBankService`, `Rails.logger`

---

### 2.7 RoomsController

**Location:** `src/app/controllers/rooms_controller.rb`  
**Description:** Room creation, viewing, starting, managing participants, and results.

**Parent:** `ApplicationController`  
**Before actions:**  
- `require_host` for `:new`, `:create`, `:destroy`  
- `set_room` for `:show`, `:results`, `:participants`, `:start_now`, `:destroy`

**Actions:**

| Action | HTTP | Params | Description |
|--------|------|--------|-------------|
| `new` | GET | `exam_hash_id` (optional) | Sets `@exam_sessions` (last 20), `@preselected_exam_hash_id` |
| `create` | POST | `exam_hash_id`, `exam_hash_id_manual`, `starts_at_date`, `starts_at_time`, `duration_minutes`, `room_name`, `instructions`, `require_display_name`, `require_candidate_identifier` | Creates `ExamRoom`; redirects to `room_path(room_code)` |
| `show` | GET | `room_code` | Displays room; redirects to results if expired; sets `@exam_session`, `@participants_count`, `@submitted_count`, `@participants` |
| `start_now` | PATCH | `room_code` | Allows host creator to start exam immediately; updates `starts_at` to `Time.current` |
| `destroy` | DELETE | `room_code` | Allows host creator to delete room; redirects to `dashboard_path` |
| `participants` | GET | `room_code` | Returns JSON: `participants_count`, `submitted_count`, `participants` |
| `results` | GET | `room_code` | Computes leaderboard; responds with HTML or CSV download |

**Private methods:**

| Method | Signature | Description |
|--------|------------|-------------|
| `set_room` | `set_room` → `void` | Loads `@room` from `params[:room_code]`; redirects if not found |
| `parse_starts_at` | `parse_starts_at(date_str, time_str)` → `Time?` | Parses date/time with `Time.zone`; returns `nil` on invalid input |
| `build_results_csv` | `build_results_csv(leaderboard)` → `String` | Builds CSV with Rank, Name, Candidate ID, Score, Total, Submitted at |

**Dependencies:** `ExamRoom`, `ExamSession`, `ExamAttempt`, `User`, `CSV`, `ApplicationController.render` (partial `rooms/participants`)

---

### 2.8 ExamsController

**Location:** `src/app/controllers/exams_controller.rb`  
**Description:** Exam taking, submission, and result viewing.

**Parent:** `ApplicationController`  
**Before action:** `require_login` for `:index`, `:create`, `:show`

**Actions:**

| Action | HTTP | Params | Description |
|--------|------|--------|-------------|
| `index` | GET | `exam_code`, `room_code`, `display_name`, `candidate_identifier` | Loads or creates exam attempt; validates room and display name; builds `@exam`, `@questions`, `@room_ends_at` |
| `create` | POST | `answers` (Hash), `attempt_id` | Persists answers to `ExamAttempt`; redirects to `exam_path` with `attempt_id` |
| `show` | GET | `id` (exam hash_id), `attempt_id` | Displays result: score, question details, pass/fail |

**Private methods:**

| Method | Signature | Description |
|--------|------------|-------------|
| `build_exam_hash` | `build_exam_hash(exam_session)` → `Hash` | Returns `{ title, time, totalQuestions, numberPass }` |
| `build_questions_array` | `build_questions_array(exam_session, attempt=nil, exam_room=nil)` → `Array<Hash>` | Shuffles questions by room/attempt seed; returns question array with choices |
| `questions_seed_for` | `questions_seed_for(exam_room, attempt)` → `Integer?` | Returns seed for shuffling (room id or attempt token bytes sum) |
| `find_or_create_attempt` | `find_or_create_attempt` → `ExamAttempt` | Finds or creates attempt; stores `attempt_token` in session |
| `find_attempt_for_result` | `find_attempt_for_result` → `ExamAttempt?` | Finds attempt by `attempt_id` or session |
| `build_submissions_from_params` | `build_submissions_from_params(answers_params)` → `Array<Hash>` | Maps params to `{ question_id, answers }` format |

**Dependencies:** `ExamSession`, `ExamRoom`, `ExamAttempt`, `Question`, `QuestionChoice`

---

## 3. Dependencies Section

### 3.1 Internal Dependencies

| Dependency | Path | Used By |
|------------|------|---------|
| `User` | `src/app/models/user.rb` | ApplicationController, SessionsController, UsersController, DashboardController, RoomsController |
| `ExamRoom` | `src/app/models/exam_room.rb` | RoomsController, ExamsController |
| `ExamSession` | `src/app/models/exam_session.rb` | RoomsController, ExamsController, SessionsController |
| `ExamAttempt` | `src/app/models/exam_attempt.rb` | RoomsController, ExamsController |
| `Question` | `src/app/models/question.rb` | ExamsController (via ExamSession) |
| `QuestionChoice` | `src/app/models/question_choice.rb` | ExamsController (via Question) |
| `CreateExamFromBankService` | `src/app/services/create_exam_from_bank_service.rb` | PreExamsController |
| `rooms/participants` partial | `src/app/views/rooms/_participants.html.erb` | RoomsController (via `ApplicationController.render`) |

### 3.2 External Dependencies

| Dependency | Purpose |
|------------|---------|
| **Rails 8** (`ActionController::Base`) | Base controller, routing, params, redirects |
| **ActionController** | Session, params, `redirect_to`, `render`, `respond_to` |
| **Rails.logger** | Error logging in PreExamsController |
| **CSV** (stdlib) | CSV export in RoomsController |
| **SecureRandom** | Used indirectly via models (room_code, attempt_token) |
| **URI** | URL parsing in `validate_exam_return_to` |
| **Time.zone** | Datetime parsing in RoomsController |
| **Turbo::StreamsChannel** | Used by ExamAttempt to broadcast participants (indirect) |

---

## 4. Relationships Section

### 4.1 Route-to-Controller Mapping

| Route | Controller#Action |
|-------|-------------------|
| `GET /` | HomeController#index |
| `GET /join` | HomeController#join |
| `GET /dashboard` | DashboardController#index |
| `GET /login` | SessionsController#new |
| `POST /login` | SessionsController#create |
| `DELETE /logout` | SessionsController#destroy |
| `GET /signup` | UsersController#new |
| `POST /signup` | UsersController#create |
| `GET /pre_exams` | PreExamsController#index |
| `GET /pre_exams/created` | PreExamsController#created |
| `POST /pre_exams/create_test` | PreExamsController#create_test |
| `GET /exams` | ExamsController#index |
| `POST /exams` | ExamsController#create |
| `GET /exams/:id` | ExamsController#show |
| `GET /rooms/new` | RoomsController#new |
| `POST /rooms` | RoomsController#create |
| `GET /rooms/:room_code` | RoomsController#show |
| `DELETE /rooms/:room_code` | RoomsController#destroy |
| `PATCH /rooms/:room_code/start_now` | RoomsController#start_now |
| `GET /rooms/:room_code/participants` | RoomsController#participants |
| `GET /rooms/:room_code/results` | RoomsController#results |

### 4.2 Controller Inheritance and Flow

```mermaid
flowchart TB
    subgraph Inheritance
        AC[ApplicationController]
        HC[HomeController]
        SC[SessionsController]
        UC[UsersController]
        DC[DashboardController]
        PEC[PreExamsController]
        RC[RoomsController]
        EC[ExamsController]
        
        AC --> HC
        AC --> SC
        AC --> UC
        AC --> DC
        AC --> PEC
        AC --> RC
        AC --> EC
    end
    
    subgraph Auth Flow
        SC --> |session[:user_id]| AC
        UC --> |session[:user_id]| AC
        AC --> |require_host| DC
        AC --> |require_host| PEC
        AC --> |require_host| RC
        AC --> |require_login| EC
    end
    
    subgraph Data Flow
        RC --> ExamRoom
        RC --> ExamSession
        RC --> ExamAttempt
        EC --> ExamSession
        EC --> ExamAttempt
        EC --> ExamRoom
        PEC --> CreateExamFromBankService
    end
```
