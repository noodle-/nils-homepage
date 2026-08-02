# nils-homepage

Single-page CV built with Hugo + PaperMod, deployed to GitHub Pages.

**To change the CV, edit one file: `data\cv.yaml`.** Nothing else.

## Editing the timeline

```yaml
pxPerYear: 150      # vertical scale — bigger = taller timeline
minHeight: 90       # px floor so short roles stay readable

entries:
  - title: "Software Test Engineer"
    org: "Company D"          # <- put the real employer here when ready
    start: "2024-01"          # YYYY-MM
    end: "present"            # YYYY-MM, or "present"
    side: left                # left = work, right = education
    accent: 1                 # 1..5, teal shades (1 darkest)
    summary: "One short line."
```

Positions and card heights are calculated from the dates — height is proportional
to how long the role lasted, exactly like the reference design. Add or remove
entries freely; the axis and year markers redraw themselves.

Dates are validated at build time: a malformed `start`/`end`, or an entry that
ends before it starts, fails the build with the offending job title in the error
rather than quietly producing a mangled layout.

## Other things you may want to edit

- `hugo.toml` — `title`, `tagline`, `cvIntro`, and the GitHub/email links.
- `assets\css\extended\custom.css` — the palette. One theme, no light/dark
  toggle. The colour variables at the top carry their contrast ratios in
  comments; keep body text at 4.5:1 or better if you change them.
- `static\` — favicons. Regenerate rather than hand-edit if you change the mark.

## Preview locally

```powershell
hugo server
```

## Publish

Commit and push in GitHub Desktop. GitHub Actions rebuilds and deploys.
Pull requests build but do not deploy, so a broken template shows up as a failed
check instead of a failed deploy.

## Notes

- The old pages (posts, uses, now, search, tags) were removed, and the nav menu
  with them. It is a true one-pager now. Taxonomies and RSS are switched off in
  `hugo.toml`, which is what keeps `/tags/` and `/categories/` out of the
  sitemap and an empty feed out of `<head>`.
- `layouts\baseof.html` and `layouts\_partials\templates\opengraph.html` are
  copies of PaperMod files carrying one-line fixes for methods removed in Hugo
  0.158. Both say so at the top, with the `diff` command to check them against
  the theme. Delete them once upstream carries the fix.
- `layouts\_partials\templates\schema_json.html` replaces PaperMod's
  Organization markup with a schema.org `Person`, built from `data\cv.yaml` so
  it cannot drift from the timeline.
- CI builds with `--panicOnWarning`, so the "zero warnings" claim is enforced
  rather than asserted. A theme bump that reintroduces a deprecation fails the
  build.
- The timeline measures "present" against the build date, so the workflow also
  runs monthly on a schedule to keep the current role's bar honest.
