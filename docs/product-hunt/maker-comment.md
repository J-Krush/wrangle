# Product Hunt — Maker Comment (First Post)

This is the comment you post on your own launch in the first 5 minutes. It's the most-read thing on your page — more eyes see this than the tagline or description. Treat it like a blog post in miniature.

Structure matches the anti-marketing voice from `Wrangle/docs/launch-strategy.md`: first-person, opinionated, filters your audience in.

---

## Draft

**Title (bolded at top):** Why I built this

Hey PH —

I've been writing CLAUDE.md files, skill definitions, and system prompts every day for the last several months. Every markdown editor I tried treated those files like plain text. No XML highlighting. No token counts. No understanding that a `<tools>` block means something.

I ended up with four apps open at all times — editor, terminal for Claude, browser for testing what the agent just built, and a separate token counter I'd paste prompts into. It's dumb and I kept losing context.

So I built Wrangle.

It's a native macOS app that combines:

- **Markdown editor** that actually understands XML-in-markdown, collapses `<tools>` / `<instructions>` blocks, highlights CLAUDE.md / SKILL.md / AGENTS.md distinctly, and keeps a token count in the status bar
- **Embedded terminals** for running Claude Code, Gemini, Codex, whatever — with macOS notifications when agents need input or finish a task
- **Embedded WebKit browser** with DevTools (console, network, elements, cookies) — so when your agent ships a change, you can inspect it without alt-tabbing to Safari
- **Projects** that tie locations, terminals, and browsers together, plus a dashboard, canvas view, and project-level todos

Swift and SwiftUI. Apple Silicon. Not Electron. One window. Everything in view.

**How it was built:** Heavy AI assistance — I used Claude Code (and Wrangle itself, once it was usable) as a primary coding partner. Before shipping, every line of Swift got reviewed by a professional Swift developer. A tool for AI-native dev, built the same way. Seemed right.

**Pricing:** $19 one-time, 3-day free trial, 30-day refund if it's not for you.

**Who this isn't for:** If you don't run AI agents daily, or if you write markdown once a month in whatever text editor came with your OS, Wrangle isn't going to change your life. That's cool. It was built for a specific person who lives in this workflow every day.

If you're that person — try it, then tell me what's missing. I ship fast.

Download: [wrangleapp.dev](https://wrangleapp.dev)

— J-Krush

---

## Editing notes

- Read through once before posting — check links render, check the bulleted list formats cleanly (PH uses markdown but some renderers differ)
- The "Who this isn't for" paragraph is the key filter — don't soften it. That's the Passive Rebel energy that makes the right readers feel seen
- If you cut anything for length: keep the pain narrative (first two paragraphs) and the "Who this isn't for" line. Those are load-bearing.
- Consider attaching an inline GIF (1200×760) after the intro paragraphs — demo of the editor + browser side-by-side
- Reply to the first ~20 comments with short, human, specific replies. Don't thank people for upvoting.

## What to avoid

- No "we're excited to announce" — this is solo-dev first-person
- No feature comparison tables (per `launch-strategy.md`)
- No asking for upvotes. Ever. Not in DMs, not in public posts, not in the comment itself
- No "AI-powered" or "revolutionary" language. The app is opinionated; the comment should be too
