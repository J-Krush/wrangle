# Token Counting Research

## Current Implementation

`wrangle/Editor/TokenCounter.swift` uses a heuristic: `(wordCount × 1.3) + (specialChars / 2)`. This gives ±20-30% accuracy — adequate as a visual indicator but not reliable for precise token limit tracking or cost estimation.

## Why Exact Offline Counting Isn't Possible

Anthropic does not publish Claude's BPE tokenizer vocabulary or merge rules. Unlike OpenAI (which provides tiktoken), there is no official library or data file that would allow offline token counting for Claude models.

## Options Evaluated

### 1. Anthropic Token Count API

**Endpoint:** `POST /v1/messages/count_tokens`

- 100% accurate (same tokenizer used for billing)
- Free to call, separate rate limits from Messages API
- Requires network access and an API key
- ~100-500ms latency per call

```
POST https://api.anthropic.com/v1/messages/count_tokens
Authorization: Bearer {api_key}
Content-Type: application/json

{
  "model": "claude-sonnet-4-20250514",
  "messages": [{"role": "user", "content": "..."}]
}

Response: { "input_tokens": 1234 }
```

### 2. Improved Heuristic (Offline)

Anthropic's own guidance suggests ~1 token per 3.5 characters. This is comparable to the current word-based approach but simpler and equally accurate.

```swift
let estimate = max(text.count / 3.5, 1)
```

Accuracy: ±20-30%. Good enough for "is this file getting big?" but not for limit enforcement.

### 3. OpenAI BPE Libraries (TiktokenSwift, GPTEncoder)

Swift libraries exist for OpenAI's tokenizer:
- [TiktokenSwift](https://github.com/narner/TiktokenSwift) — Rust core via FFI
- [GPTEncoder](https://github.com/alfianlosari/GPTEncoder) — Pure Swift

These use OpenAI's vocabulary, not Claude's. Accuracy for Claude content is ~65-80% — arguably worse than a tuned heuristic because it's confidently wrong. Not recommended.

### 4. Reverse-Engineered Claude Tokenizer

Community efforts to reconstruct Claude's tokenizer:
- [javirandor/anthropic-tokenizer](https://github.com/javirandor/anthropic-tokenizer) (Python)
- [Xenova/claude-tokenizer](https://huggingface.co/Xenova/claude-tokenizer) (HuggingFace)

~75-90% accuracy. Python-based, would need porting to Swift. Breaks whenever Anthropic updates their tokenizer. High maintenance risk.

## Recommended Approach: Hybrid

Two tiers that complement each other:

**Tier 1 — Instant heuristic (every keystroke)**
Keep an offline estimate for immediate UI feedback. Use `characterCount / 3.5` or the current word-based formula. Display with a `~` prefix to signal approximation.

**Tier 2 — Accurate API count (async, on-demand)**
Call Anthropic's `count_tokens` endpoint in the background. Trigger on file save, on explicit user action (e.g. clicking the token count), or after a typing debounce for AI-specific files. Cache results keyed by content hash to avoid redundant calls.

**Offline fallback:** If no API key is configured or network is unavailable, show only the heuristic estimate.

### UX Sketch

| State | Status Bar Display |
|-------|-------------------|
| Typing (heuristic only) | `~1.2K tokens` (dimmed) |
| API result available | `1,187 tokens` (full color) |
| API call in flight | `~1.2K tokens` (spinner) |
| No API key / offline | `~1.2K tokens` (dimmed, permanent) |

### Color Thresholds (current, no change needed)

| Range | Color | Meaning |
|-------|-------|---------|
| < 4,000 | Green | Safe |
| 4,000–8,000 | Yellow | Getting large |
| 8,000–32,000 | Orange | Large |
| 32,000+ | Red | Dangerously large |

## Key Files

- `wrangle/Editor/TokenCounter.swift` — current heuristic implementation
- `wrangle/ContentView.swift` (StatusBarView) — UI integration
