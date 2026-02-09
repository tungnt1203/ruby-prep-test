# FastQuiz

**Ruby interview quiz:** timed rooms, AI scoring (Viblo Learn + OpenRouter/Gemini), real-time leaderboard, CSV export. Rails 8 app for running group tests in interview sessions.

Create exams from [Viblo Learn](https://learn.viblo.asia), schedule a room, share the link. Candidates sign in, join the room, and take the same Ruby (or other) quiz with shuffled questions. Results update in real time; hosts can export CSV for HR.

## Features

- **Timed rooms** — Set start time and duration; everyone sees countdown, then starts together.
- **Host dashboard** — List your rooms, link to results, quick actions (Create exam, Schedule room).
- **Login required to take exam** — Candidates must sign in; after login they are sent back to the exam URL.
- **Real-time participants** — Turbo Streams + Action Cable: join/submit events update the room page without refresh.
- **Start now** — Room creator can start the exam early when everyone is ready.
- **Room options** — Optional instructions, require display name and/or candidate ID (email) for HR.
- **Shuffle per attempt** — Questions and choices order vary by candidate (deterministic from attempt token).
- **AI answer key** — OpenRouter or Gemini fills correct answers and explanations; optional refresh per exam.
- **Export results** — Download room leaderboard as CSV (name, candidate ID, score, submitted at).

## Stack

- **Rails 8.1**, Ruby 3.4
- **SQLite** (development/production)
- **Vite** + Tailwind CSS, Stimulus, Turbo
- **Action Cable** (Turbo Streams for real-time updates)
- **Solid Queue** (in-process with Puma), **Thruster** (production web)
- **OpenRouter** (preferred) or **Google Gemini** for answer key + explanations

## Requirements

- Ruby 3.4 (see [.ruby-version](.ruby-version))
- Node.js 18+ and Yarn (for assets)
- [Viblo](https://viblo.asia) account (session cookies for the exam API)

## Setup

```bash
git clone <repo>
cd fast_quiz
bundle install
yarn install
bin/rails db:prepare
```

### Credentials

Edit with:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Add (or use ENV fallbacks where noted):

| Key | Purpose | ENV fallback |
|-----|---------|--------------|
| `open_router_api_key` | OpenRouter API key for answer key | `OPENROUTER_API_KEY` |
| `gemini_api_key` | Google Gemini API key (if not using OpenRouter) | `GEMINI_API_KEY` |
| `viblo_session_nonce` | Viblo session cookie (from browser when logged in) | — |
| `viblo_learning_auth` | Viblo learning auth cookie | — |

Viblo cookies are required to create exams from Viblo. OpenRouter or Gemini is required to fetch and store correct answers per question.

## Running

- **Development**

  ```bash
  bin/dev
  ```

  Open [http://localhost:3000](http://localhost:3000).

- **Production (Docker)**

  ```bash
  docker build -t fast_quiz .
  docker run -d -p 80:80 -e RAILS_MASTER_KEY="$(cat config/master.key)" --name fast_quiz fast_quiz
  ```

## Usage

**Roles:** *Host* (create exams, schedule rooms, see results) and *User* (take exams). Sign up and set role in DB or via seeds.

1. **Host: Create exam** — Go to *Create exam* (or `/pre_exams`). Default exam ID 76 = Ruby; change for other topics. Submit → app calls Viblo API, stores questions, then (if configured) fetches AI answer key in the background.

2. **Host: Schedule room** — *Schedule a room* → enter exam code (from “Exam created” page), room name, optional instructions, start date/time, duration. Optionally require display name and/or candidate ID. Create → you get a room link.

3. **Host: Share link** — Send the room URL to candidates. On the room page they see countdown (or “Started!”). Host can click *Start exam now* to begin early, or wait for the timer.

4. **Candidate: Join** — Open the room link (or *Join a room* and enter room code). Enter name and optional email/candidate ID if required. Click *Start exam* — if not signed in, you’ll be redirected to login and then back to the exam.

5. **Candidate: Take exam** — Answer questions (order and choice order are shuffled per attempt). Submit; view score and per-question result vs the stored answer key.

6. **Results** — Room *View leaderboard* shows rankings; *Export CSV* downloads name, candidate ID, score, submitted at. Per-attempt *View* opens the detailed result page.

## Deployment (Kamal)

1. Set `servers.web` in [config/deploy.yml](config/deploy.yml).
2. Configure SSH and secrets (see [.kamal/secrets](.kamal/secrets)): `RAILS_MASTER_KEY`, `KAMAL_REGISTRY_PASSWORD`, and optionally ENV for OpenRouter/Gemini.
3. Run:

   ```bash
   bin/kamal deploy
   ```

Do not commit `config/master.key` or `.pem` files.

## Tests

```bash
bin/rails test
```

Controller tests cover exam access (login required, `return_to` redirect) and session redirect after login.

## License

This project is released under the [MIT License](LICENSE).

See also:

* [Code of Conduct](CODE_OF_CONDUCT.md)
* [Contributing](CONTRIBUTING.md)
* [Security Policy](SECURITY.md)
