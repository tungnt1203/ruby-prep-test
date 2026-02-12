# FastQuiz

**Ruby Silver quiz:** 50 random questions from exam_ruby_silver question bank, timed rooms, real-time leaderboard, CSV export. Rails 8 app for Ruby group tests.

Create exams from the local question bank (17 topics, ~590 questions). Host schedules a room and shares the link. Candidates sign in, take 50 random questions (shuffled per attempt), and view results by topic.

## Features

- **50 random questions** — Each exam draws 50 questions from the full Ruby Silver bank.
- **Clear topic labels** — Each question has a topic (blocks, literals, conditionals, …); badge shown during exam and on results.
- **Timed rooms** — Set start time and duration; countdown, everyone starts together.
- **Host dashboard** — List rooms, link to results, quick actions.
- **Login required** — Candidates must sign in to take exams.
- **Real-time participants** — Turbo Streams + Action Cable.
- **Shuffle per attempt** — Question and choice order shuffled per attempt.
- **Export results** — CSV leaderboard.

## Stack

- **Rails 8.1**, Ruby 3.4
- **SQLite** (development/production)
- **Vite** + Tailwind CSS, Stimulus, Turbo
- **Action Cable** (Turbo Streams)

## Requirements

- Ruby 3.4 (see [.ruby-version](.ruby-version))
- Node.js 18+ and Yarn (for assets)

## Setup

```bash
git clone <repo>
cd fast_quiz
bundle install
yarn install
bin/rails db:prepare
bin/rails db:seed_question_bank   # Load question bank from exam_ruby_silver/*.json
bin/rails db:seed                 # Create host user (dev)
```

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

**Roles:** *Host* (create exams, schedule rooms, see results) and *User* (take exams).

1. **Host: Create exam** — Go to *Create exam* (`/pre_exams`). Submit → app creates an exam with 50 random questions from the Ruby Silver bank.

2. **Host: Schedule room** — Go to *Schedule a room* (`/rooms/new`). Select an exam from the dropdown (or paste exam code), enter room name, optional instructions, start date/time, duration. Optionally require display name and/or candidate ID. Create → you get a room link.

3. **Host: Share link** — Send the room URL to candidates. On the room page they see a countdown (or "Started!"). Host can click *Start exam now* to begin early, or wait for the timer.

4. **Candidate: Join** — Open the room link (or *Join a room* and enter room code). Enter name and optional email/candidate ID if required. Click *Start exam* — if not signed in, you’ll be redirected to login and then back to the exam.

5. **Candidate: Take exam** — Answer questions (order and choice order are shuffled per attempt). Submit; view score and per-question result with explanations.

6. **Results** — Room *View leaderboard* shows rankings; *Export CSV* downloads name, candidate ID, score, submitted at. Per-attempt *View* opens the detailed result page with topic labels.

## Deployment (Kamal)

1. Set `servers.web` in [config/deploy.yml](config/deploy.yml).
2. Configure SSH and secrets (see [.kamal/secrets](.kamal/secrets)): `RAILS_MASTER_KEY`, `KAMAL_REGISTRY_PASSWORD`.
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
