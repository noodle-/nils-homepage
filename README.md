# nils-homepage

Single-page CV built with Hugo + PaperMod, deployed to GitHub Pages.

**To change the CV, edit one file: `data\cv.yaml`.** Nothing else.

## Editing the timeline

```yaml
pxPerYear: 150      # vertical scale — bigger = taller timeline
minHeight: 54       # px floor so short roles stay readable

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

## Other things you may want to edit

- `hugo.toml` — `title`, `tagline`, `cvIntro`, and the GitHub/email links.
- `assets\css\extended\custom.css` — the `--a1`..`--a5` teal shades.

## Preview locally

```powershell
cd "D:\My Documents\GitHub\nils-homepage"
hugo server -D
```

## Publish

Commit and push in GitHub Desktop. GitHub Actions rebuilds and deploys.

## Notes

- The old pages (posts, uses, now, search, tags) were removed, and the nav menu
  with them. It is a true one-pager now.
- `layouts\` contains three PaperMod overrides that fix Hugo 0.158 deprecations,
  plus `index.html`, which renders the timeline.
- Builds clean with zero warnings on Hugo 0.164.
