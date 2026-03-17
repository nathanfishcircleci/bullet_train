# Claude Rules

## Project
Ruby on Rails 8.0 application built on [Bullet Train](https://bullettrain.co). Ruby 3.4.4.

## Code Style
- All Ruby must pass `standardrb` linting (`.standard.yml` in repo root)
- Run `standardrb --fix` to auto-fix style issues before committing

## Testing
- Tests run on CI (CircleCI) — gems are not installed locally
- Test framework: Minitest
- Run a specific test file: `bin/rails test path/to/test_file.rb`
- The `/docs` route only exists in `development` environment — do not test it in the `test` environment

## Models
- `Team` model is at `app/models/team.rb` — add `has_many` associations at the `# 🚅 add oauth providers above.` comment for OAuth integrations
- Bullet Train gem provides base models (e.g. `Integrations::StripeInstallation`, `Oauth::StripeAccount`) but the app must define its own `has_many` associations on `Team`

## Git
- Commit and push when asked to "merge"
- Do not auto-commit unless explicitly asked
