// Pure helpers for Zen affirmations taken from forum posts.
// No Ember/Discourse imports, so this stays unit-testable in plain Node.

export const MIN_LENGTH = 30;
export const MAX_LENGTH = 140;

// Elements in cooked post HTML that never contain usable prose.
export const SKIP_SELECTOR = [
  "aside",
  "blockquote",
  "pre",
  "code",
  "table",
  "img",
  ".onebox",
  ".lightbox-wrapper",
  ".spoiler",
  ".spoiled",
  ".mention",
  ".hashtag-cooked",
  ".poll",
  "details",
].join(",");

// Turns cooked post HTML into plain text. `parser` is a DOMParser (injected).
export function cookedToText(cooked, parser) {
  const doc = parser.parseFromString(String(cooked ?? ""), "text/html");
  doc.body.querySelectorAll(SKIP_SELECTOR).forEach((el) => el.remove());
  // Block elements end a sentence even without punctuation.
  doc.body
    .querySelectorAll("p, li, h1, h2, h3, h4, h5, h6, br, div")
    .forEach((el) => el.append(doc.createTextNode("\n")));
  return doc.body.textContent;
}

// True if a sentence reads well on its own as a calm one-liner.
export function isUsable(sentence) {
  const s = sentence.trim();
  if (s.length < MIN_LENGTH || s.length > MAX_LENGTH) {
    return false;
  }
  // No links, mentions, hashtags, markup leftovers or file paths.
  if (/https?:|www\.|[@#<>{}[\]|\\/]/i.test(s)) {
    return false;
  }
  // Questions and lead-ins don't stand on their own.
  if (/[?:,;\-–]$/.test(s)) {
    return false;
  }
  if (s.split(/\s+/).length < 4) {
    return false;
  }
  // Mostly letters (no number lists, dates or emoji soup).
  const letters = (s.match(/\p{L}/gu) || []).length;
  return letters / s.length > 0.7;
}

// Splits plain text into usable sentences, each ending with punctuation.
export function extractSentences(text) {
  return String(text ?? "")
    .split(/\n+/)
    .flatMap((line) => line.match(/[^.!?…]+[.!?…]*/g) || [])
    .map((s) => s.replace(/\s+/g, " ").trim())
    .filter(isUsable)
    .map((s) => (/[.!?…]$/.test(s) ? s : `${s}.`));
}

// Random item whose text differs from `lastText` (when there is a choice).
export function pickDifferent(items, lastText, random = Math.random) {
  if (!items.length) {
    return undefined;
  }
  const others = items.filter((i) => i.text !== lastText);
  const pool = others.length ? others : items;
  return pool[Math.floor(random() * pool.length)];
}

// Removes duplicate sentences (same text), keeping the first.
export function uniqueByText(items) {
  const seen = new Set();
  return items.filter((i) => !seen.has(i.text) && seen.add(i.text));
}

// Parses the `zen_affirmation_categories` setting ("12|34") into ids.
export function parseCategoryIds(value) {
  return String(value ?? "")
    .split("|")
    .map((v) => parseInt(v, 10))
    .filter((n) => Number.isInteger(n) && n > 0);
}
