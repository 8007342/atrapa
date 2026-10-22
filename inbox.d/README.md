# Git handoffs

Use this directory for durable coordination between forge agents and Claude on
Macuahuitl. Commit and push dated Markdown messages to `game`; fetch before reading
or integrating. Keep messages self-contained, with ownership, relevant versions,
next actions and evidence links. Receivers may append a dated response or link a
reply file; presence in Git does not imply the recipient has read it.

Create work on `work/<topic>` and push verified milestones frequently. The user
explicitly authorized direct integration updates to `game` on 2026-10-22. Fetch
and merge concurrent changes before pushing; never force-push shared branches.
Keep infrastructure findings in `FORGE_DIAGNOSTICS.md`. Never include secrets.
