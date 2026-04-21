# Product Hunt Launch Assets

Everything needed to submit a Product Hunt listing for Wrangle v1.2.0.

## Status

| Asset | File | Status |
|---|---|---|
| Tagline (3 variants) | `tagline.md` | Drafted — pick one before launch |
| Description (3 variants) | `description.md` | Drafted — pick one before launch |
| Maker first comment | `maker-comment.md` | Drafted — review tone before launch |
| Gallery images (3–8 × 1200×760) | `images/` | **Not started** — needs v1.2.0 build to capture |
| Demo video / GIF | `demo/` | **Not started** — decide reuse vs re-cut |
| Cover image | `images/cover.png` | **Not started** — usually first gallery image |

## Launch-day checklist

1. Pick tagline from `tagline.md` (recommendation: Option 2)
2. Pick description from `description.md` (recommendation: Option 1)
3. Capture 5–7 gallery images from the v1.2.0 build — see suggested shot list below
4. Cut or reuse a 20–30s demo video; export a GIF version for the first comment
5. Post at 12:01am PT
6. Post maker comment (`maker-comment.md`) within 5 minutes
7. Reply to comments for the first 12 hours

## Suggested gallery shot list

6 shots, each 1200×760. First shot is the cover — it does the heaviest lifting on the listing thumbnail and above the fold.

1. **Cover / hero** — editor + terminal + browser in one window. Project rail visible in sidebar. Real CLAUDE.md rendered. Dark mode.
2. **XML-in-markdown** — editor close-up showing `<tools>` / `<instructions>` blocks highlighted, one collapsed. Token counter visible in status bar.
3. **Browser with DevTools** — browser tab showing a real-looking page + console or network panel open. HTTPS padlock visible.
4. **Bookmarks + history** — bookmarks popover with nested folders *or* the grouped history view. Pick the tighter visual.
5. **Project dashboard** — overview stats + project-level todos + canvas view. Tells the "workspace, not just editor" story.
6. **Private mode or Downloads** — incognito browser tab with the private-mode indicator, or the downloads popover with an in-progress item. Private mode is likely the stronger differentiator vs competitors.

### Consistency rules

- Same window chrome, same dark theme, same macOS wallpaper across every shot.
- Fake content must be plausible: real project names, real-looking CLAUDE.md content, real URLs in browser shots. No Lorem Ipsum.
- Browser shots should use a real-looking domain, not `localhost:3000`.
- Status bar visible in editor shots (token count is a differentiator — don't crop it out).
- Export at exactly 1200×760 (PH crops anything else).

### Optional extras (keep in reserve, not in the main 6)

- **Notifications overlay** — native macOS notification ("Claude needs your attention"). Strong for the first-comment GIF, weaker as a static gallery image.
- **Unified Add menu** — shows the "one shared creation flow" story. Only compelling if readers already grok the pain.
- **Token counter close-up** — status bar detail showing linked CLAUDE.md, active skills, MCP servers. Great for the blog post, too niche for PH gallery.

## Voice reference

All copy (tagline, description, maker comment) matches the anti-marketing voice documented in `../launch-strategy.md`. Key principles:

- First-person. Solo dev built it.
- Opinionated. Polarizing is good.
- Filters in the right ~10k people. Filters out everyone else.
- No "we" language. No "AI-powered" buzzwords. No feature comparison tables.
