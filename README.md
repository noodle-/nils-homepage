# nils-homepage

Personal website built with [Hugo](https://gohugo.io/) (Extended) and the
[PaperMod](https://github.com/adityatelange/hugo-PaperMod) theme, deployed to
GitHub Pages via GitHub Actions.

You author locally on Windows. GitHub Actions does the actual build and publishes
the result — nothing needs to run on your machine for the live site to stay up.

---

## 0. One-time install (PowerShell)

```powershell
winget install Git.Git
winget install Hugo.Hugo.Extended
winget install Microsoft.VisualStudioCode
winget install GitHub.cli
```

Close and reopen PowerShell so PATH updates, then confirm:

```powershell
hugo version   # must say "extended", or PaperMod's SCSS build will fail
```

Set line endings once (avoids "every line changed" diffs):

```powershell
git config --global core.autocrlf true
```

> Don't put this folder inside a file-sync folder (Dropbox, OneDrive, etc.).
> Syncing a live `.git` directory can corrupt the repo. Keep it somewhere like
> `D:\My Documents\GitHub\nils-homepage`. GitHub is your sync mechanism here.

---

## 1. Put this folder in place & add the theme

Extract this folder to `D:\My Documents\GitHub\nils-homepage`. The theme is NOT included (it's added
as a git submodule so it stays updatable). From inside the folder:

```powershell
cd D:\My Documents\GitHub\nils-homepage
git init
git submodule add https://github.com/adityatelange/hugo-PaperMod themes/PaperMod
```

## 2. Preview locally

```powershell
hugo server -D
```

Open http://localhost:1313 — live-reloads as you edit. (`-D` also shows drafts.)

## 3. Edit before publishing

- `content/about.md` — your CV. Drop a `cv.pdf` in `static/` to link a download.
- `content/uses.md`, `content/now.md` — quick to personalise.
- `static/images/avatar.jpg` — optional square profile photo (already referenced
  in `hugo.toml`; add the file or the profile shows no image).
- In `hugo.toml`, set your email in the `email` social block or delete that block.
- The two starter posts in `content/posts/` — rewrite or delete them.

New post:

```powershell
hugo new posts/my-post-title.md
```

## 4. Create the GitHub repo & push

Your username is `noodle-`, so this creates `github.com/noodle-/nils-homepage`:

```powershell
gh auth login          # pick the browser flow
git add .
git commit -m "Initial site"
gh repo create nils-homepage --public --source=. --remote=origin --push
```

## 5. Turn on GitHub Pages

1. On GitHub: **Settings → Pages → Build and deployment → Source → GitHub Actions**.
2. The workflow in `.github/workflows/hugo.yml` builds and deploys on every push
   to `main`.
3. Your site will be live at **https://noodle-.github.io/nils-homepage/** — already
   set as `baseURL` in `hugo.toml`.

## 6. (Optional) Custom domain

- Buy a domain (Domeneshop for `.no`, or Cloudflare Registrar for at-cost `.com`).
- GitHub **Settings → Pages → Custom domain**, add it — this creates a `CNAME`
  file in the repo. Point DNS at GitHub Pages per their docs.
- Update `baseURL` in `hugo.toml` to `https://yourdomain/`.

---

## Everyday workflow

```powershell
hugo server -D                 # write & preview
git add . && git commit -m "New post: ..."
git push                       # Actions rebuilds & deploys in ~1 min
```

## Changing the accent colour

The teal accent lives in `assets/css/extended/custom.css`. Edit the `--accent`
values there; PaperMod bundles that file automatically.

## Updating the theme later

```powershell
git submodule update --remote --merge themes/PaperMod
git commit -am "Update PaperMod"
```
