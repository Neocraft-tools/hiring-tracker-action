# Company Hiring Tracker GitHub Action: new job alerts from company career pages

[![GitHub release](https://img.shields.io/github/v/release/Neocraft-tools/hiring-tracker-action)](https://github.com/Neocraft-tools/hiring-tracker-action/releases)
[![Apify Actor](https://img.shields.io/badge/Apify-company--hiring--tracker-blue)](https://apify.com/neocraft/company-hiring-tracker)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Track the open jobs of any list of companies from their public job boards (Greenhouse, Lever, Ashby, Workable, Recruitee, SmartRecruiters, Teamtailor, Personio, Workday and more) on a schedule. In `changes` mode each run returns only the jobs that are **new, changed, reopened or closed** since the previous run, plus a one-line hiring summary per company (open jobs, net change over 7/30/90 days, departments, countries). Useful for sales signals, competitive intelligence and job hunting.

This action is a thin, dependency-free wrapper (bash + curl + jq) around the Apify Actor
[neocraft/company-hiring-tracker](https://apify.com/neocraft/company-hiring-tracker). It starts a run in **your own Apify account**, waits for it, saves the results as JSON,
writes a readable job summary and exposes the key values as step outputs.

## Quick start

1. Create a free Apify account at <https://apify.com> and copy your API token (**Console → Settings → API & Integrations**).
2. In your GitHub repository: **Settings → Secrets and variables → Actions → New repository secret**, name `APIFY_TOKEN`.
3. Add a step to a workflow:

```yaml
    steps:
      - uses: Neocraft-tools/hiring-tracker-action@v1
        with:
          apify-token: ${{ secrets.APIFY_TOKEN }}
          companies: Stripe, Doctolib, https://boards.greenhouse.io/airbnb
          mode: changes
          title-include: engineer, data
```

A complete workflow is in [`examples/weekly-new-jobs.yml`](examples/weekly-new-jobs.yml).

## Pricing (pay per event, billed by Apify to your account)

**$0.004 per covered company** + **$0.001 per returned job**; optional 90-day history $0.02 per company. Companies that are not covered are free. In `changes` mode the first run returns every open job (e.g. 150 jobs = $0.15) and later runs only the differences, so they are much cheaper. Use `max-jobs-per-company` and the default $0.25 spend cap to stay in control.

Prices are those of the [Apify Store page](https://apify.com/neocraft/company-hiring-tracker) when this README was written; the Store page is the reference.
Platform usage is included in these prices. Apify's free plan includes a monthly credit that covers light use.
Every run is started with a hard spend cap (`max-total-charge-usd`): the Actor stops charging when the cap is reached.
This GitHub Action itself is free and open source; nothing is billed by Neocraft outside Apify.

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `apify-token` | yes |  | Your Apify API token (store it as a secret). Runs are billed to this Apify account. |
| `companies` | yes |  | Companies to track, separated by commas or new lines: name (Stripe), domain (doctolib.fr) or job-board URL. |
| `mode` | no | `changes` | changes = only new/changed/reopened/closed jobs since the previous run (first run returns all open jobs); snapshot = all open jobs every time. |
| `state-key` | no |  | Baseline name for changes mode (stored in your Apify account). Defaults to the repository name. |
| `title-include` | no |  | Keep only job titles containing one of these words (comma separated), e.g. 'engineer, data'. |
| `title-exclude` | no |  | Drop job titles containing one of these words (comma separated), e.g. 'intern'. |
| `countries` | no |  | Keep only jobs in these countries (ISO codes, comma separated), e.g. 'FR, DE'. |
| `remote-only` | no | `false` | Keep only remote jobs. |
| `max-jobs-per-company` | no | `0` | Maximum jobs returned per company (0 = no limit). Each returned job costs $0.001. |
| `fail-on-new-jobs` | no | `false` | Fail the step when new or reopened jobs are found (use GitHub's failure e-mail as the alert). |
| `extra-input` | no |  | Optional JSON object merged into the Actor input (fields of neocraft/company-hiring-tracker, e.g. {\"history90d\": true}). |
| `max-total-charge-usd` | no | `0.25` | Hard spend cap for the run in USD. |
| `timeout-secs` | no | `900` | Maximum run time of the Actor in seconds. |
| `output-file` | no | `hiring.json` | Where to save the full JSON results. |

## Outputs

| Name | Description |
|---|---|
| `job-count` | Number of job rows returned. |
| `new-count` | New or reopened jobs (changes mode). |
| `closed-count` | Closed jobs (changes mode). |
| `jobs` | Compact JSON array of jobs (company, title, changeType, department, country, remote, url). |
| `results-file` | Path of the full JSON results. |
| `run-url` | Apify Console URL of the run. |

Every run also sets `run-id`, `run-status` and `item-count`.

## Notes

* The baseline for `changes` mode is stored in **your** Apify account under `state-key` (default: the repository name). Use one key per watchlist.
* Companies can be given as names, domains or job-board URLs; unknown companies are looked up live (up to 25 per run).
* Outputs: `new-count`, `closed-count`, `jobs` (JSON) and the full results (job rows, company summaries, coverage rows).
* The step needs `curl` and `jq`, which are preinstalled on GitHub-hosted Ubuntu and macOS runners.
* Your token is only sent to `api.apify.com`. Keep it in a secret; never paste it in a workflow file.

## Related

* Apify Actor: [company-hiring-tracker](https://apify.com/neocraft/company-hiring-tracker) (also usable from the Apify Console, API, Python/Node clients, Make, Zapier, MCP/AI agents).
* More examples (Python, Node.js, curl, AI agents): [Neocraft-tools/apify-examples](https://github.com/Neocraft-tools/apify-examples).
* Other Neocraft actions: [website-audit-action](https://github.com/Neocraft-tools/website-audit-action), [page-change-monitor-action](https://github.com/Neocraft-tools/page-change-monitor-action), [website-screenshot-action](https://github.com/Neocraft-tools/website-screenshot-action), [company-profile-action](https://github.com/Neocraft-tools/company-profile-action).

## Self-test (maintainers)

[`examples/self-test.yml`](examples/self-test.yml) runs this action on cheap inputs (a few cents at most). To enable it,
copy it to `.github/workflows/self-test.yml`, add an `APIFY_TOKEN` secret, and start it from the **Actions** tab
(it only runs on `workflow_dispatch`).

## Support

Open an issue in this repository. Maintained by Xiaoli, an AI assistant, for Neocraft.

## License

[MIT](LICENSE)
