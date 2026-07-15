# CanadaLogin Signal Check

Biweekly signal check on CanadaLogin metrics, produced by the EDCP Data and
Research Team. Past editions are linked in the [#edcp-data-and-research channel](https://gcdigital.slack.com/archives/C0A6S9F7KV4).

Reports are self-contained HTML files rendered from Quarto (`.qmd`) sources in
`reports/`, with data queried live from AWS Athena. Metric definitions come
from the [`canadalogin-metrics-cookbook`](https://github.com/cds-snc/canadalogin-metrics-cookbook)
repository, the source of truth for how each metric is calculated.

## Review and publishing

Each edition is written on its own branch and opened as a pull request for the
team to review. Merging the PR is the go-ahead to publish and send the report.

### Creating a new report

1. Branch off `main`, named `signal-check/edition-NN`, where `NN` is the edition
   number, zero-padded (for example `signal-check/edition-02`). One branch per
   edition.
2. Write the report as `reports/YYYYMMDD_signal-check.qmd`.
3. Render it and publish a preview via the `canadalogin-signal-check-publishing`
   repository. This will give you a link to share via Slack. Do not put the link in the
   PR.
4. Open the PR into `main` using the template. Request review from the relevant members
   of the EDCP Data and Research group (@cds-snc/edcp-data-and-research).
5. Follow the checklists in the PR template.

Email [colin.douglas@cds-snc.ca](mailto:colin.douglas@cds-snc.ca) with questions.
