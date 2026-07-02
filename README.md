# CanadaLogin Signal Check

Every-two-week signal check on CanadaLogin metrics, produced by the EDCP Data and
Research Team.

Reports are self-contained HTML files rendered from Quarto (`.qmd`) sources in
`reports/`, with data queried live from AWS Athena.

## Review and publishing

Each edition is written on its own branch and opened as a pull request for the
team to review. Merging the PR signals that the report is about to be published.

### Creating a new report

1. Branch off `main`, named `signal-check/edition-NN`, where `NN` is the edition
   number, zero-padded (for example `signal-check/edition-02`). One branch per
   edition.
2. Write the report and save it to `reports/` in this repository (named `YYYYMMDD_signal-check.qmd`).
3. Render it and publish a preview via the `canadalogin-signal-check-publishing`
   repository. This will give you a link to share via Slack. Do not put the link in the
   PR.
4. Open the PR into `main` using the template. Opening the PR automatically requests a
   review from the EDCP Data and Research group (@cds-snc/edcp-data-and-research).

### Review and merge

- Reviewers have two hours to comment or suggest changes. Comment on the PR to ask for
  more time if you need it. Reviewers who are on leave will be noted in the PR, and
  their approval is not required.
- Run through the pre-merge checklist to make sure all the fiddly bits are complete.
- The report is published once either everyone available has approved, or the two
  hours pass with no comments.
- After merging, follow the post-merge checklist.

Email [colin.douglas@cds-snc.ca](mailto:colin.douglas@cds-snc.ca) with questions.
