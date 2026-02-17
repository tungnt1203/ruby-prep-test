# Ruby Prep Test (FastQuiz)

Ruby Silver quiz platform with timed rooms: host creates a room and shares a link; candidates take the exam, view the leaderboard, and export results as CSV.

## Repo structure

| Directory   | Description                    |
|-------------|--------------------------------|
| **`src/`**  | Rails app (run from here)      |
| `notebooks/`| PRD, C4 architecture docs      |
| `openspec/` | OpenSpec workflow config       |

## Quick start

```bash
cd src
bundle install && yarn install
bin/rails db:prepare
bin/rails db:seed_question_bank
bin/rails db:seed
bin/dev
```

Open [http://localhost:3000](http://localhost:3000). Default host user (dev): `host@example.com` / `hostpassword`.

## More

- **Stack:** Rails 8.1, Ruby 3.4, SQLite, Vite, Tailwind, Stimulus, Turbo, Action Cable  
- Full setup, features, and deployment: see **[src/README.md](src/README.md)**.
