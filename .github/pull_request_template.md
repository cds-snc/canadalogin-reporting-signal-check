# CanadaLogin Signal Check #NN

For the two-week period of (month DD - month DD).

DO NOT POST THE LINK TO THE REPORT IN THE PR.
Link it on Slack instead, tagging the reviewers.

## Pre-merge checklist

- [ ] Preflight safety checks pass and data is up-to-date
- [ ] `fig-alt` set on every graph chunk
- [ ] Footer is present and all links work
- [ ] Watermark shows the correct edition number and creation date
- [ ] Subtitle states the correct reporting period
- [ ] `lintr` clean
- [ ] Preview rendered
- [ ] Link shared with reviewers via Slack

## Merge criteria

Do not merge before **(at least two hours in the future, fill this in)**
(two hours after this PR was opened). Merge once either:

- everyone in @cds-snc/edcp-data-and-research who is not on leave has approved, or
- the two-hour window above has passed with no comment asking to hold.

## Note to Reviewers

- If you need more time, comment and ask for it!
- If the report looks good, approve the PR to move it along
- Communicate changes here, as comments, or comment directly on the code

## Squash commit message

Merge with "Squash and merge" and replace the prefilled message with a
conventional commit naming the edition. Don't use octothorpes (#) to denote edition
number as they confuse Github.

```text
feat: add signal check edition N
```

## Post-merge checklist

- [ ] Re-render from `main`
- [ ] Publish via `cds-snc/canadalogin-signal-check-publishing`
- [ ] Upload to Google Drive
- [ ] Upload to SharePoint
- [ ] Send the email to readers
- [ ] Post in EDCP Teams channel
- [ ] Post in #edcp-data-and-research
- [ ] Crosspost link to #canadalogin
- [ ] Add message text to publishing repository
