# FastQuiz

Rails app to create exams from [Viblo Learn](https://learn.viblo.asia) and run them with an AI-generated answer key (OpenRouter/Gemini). Supports single- and multi-choice questions, scoring against the stored key, and deployment with [Kamal](https://kamal-deploy.org).

## Stack

- **Rails 8.1**, Ruby 3.4
- **SQLite** (development/production)
- **Vite** + Tailwind CSS, Stimulus, Turbo
- **Solid Queue** (in-process with Puma), **Thruster** (production web)
- **OpenRouter** (preferred) or **Google Gemini** for answer key + explanations

## Requirements

- Ruby 3.4 (see [.ruby-version](.ruby-version))
- Node.js 18+ and Yarn (for assets)
- [Viblo](https://viblo.asia) account (to obtain session cookies for the exam API)

## Setup

```bash
git clone <repo>
cd fast_quiz
bundle install
yarn install
bin/rails db:prepare
```

### Credentials

The app uses Rails credentials for secrets. Edit with:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Add (or rely on ENV fallbacks where noted):

| Key | Purpose | ENV fallback |
|-----|---------|--------------|
| `open_router_api_key` | OpenRouter API key for answer key | `OPENROUTER_API_KEY` |
| `gemini_api_key` | Google Gemini API key (if not using OpenRouter) | `GEMINI_API_KEY` |
| `viblo_session_nonce` | Viblo session cookie (from browser when logged in) | — |
| `viblo_learning_auth` | Viblo learning auth cookie | — |

Viblo cookies are required to call the exam API. OpenRouter or Gemini is required to fetch and store the correct answers per question.

## Running

- **Development**

  ```bash
  bin/dev
  ```

  Root: [http://localhost:3000](http://localhost:3000) → Create exam → then take exam via the link/code shown.

- **Production (Docker)**

  ```bash
  docker build -t fast_quiz .
  docker run -d -p 80:80 -e RAILS_MASTER_KEY="$(cat config/master.key)" --name fast_quiz fast_quiz
  ```

## Usage

1. **Create exam** (`/` or `/pre_exams`)  
   - Optionally set Exam ID (Viblo) and language.  
   - Submit → app calls Viblo API, stores session and questions, then (if configured) fetches AI answer key for each question.

2. **Take exam**  
   - Use the exam code/link from the “Exam created” page (e.g. `?exam_code=...`).  
   - Answer questions, submit.  
   - On the result page you see score and per-question result vs the stored answer key and explanation.

3. **Refresh answer key**  
   - From the exam page sidebar, use “Refresh AI answer key” to re-call the AI and update correct answers and explanations.

## Deployment (Kamal)

1. Set `servers.web` in [config/deploy.yml](config/deploy.yml) to your EC2 (or other) host(s).
2. Ensure SSH access (e.g. `~/.ssh/config` with `IdentityFile` for your `.pem`).
3. Set secrets (see [.kamal/secrets](.kamal/secrets)): `RAILS_MASTER_KEY`, `KAMAL_REGISTRY_PASSWORD`, and optionally ENV for OpenRouter/Gemini if not using credentials.
4. Deploy:

   ```bash
   bin/kamal deploy
   ```

For EC2, use the correct SSH user (`ubuntu` or `ec2-user`) and do not commit `.pem` or `config/master.key`.

## Tests

```bash
bin/rails test
```

## License

Private / unlicensed unless stated otherwise.
