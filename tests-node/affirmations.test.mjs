// Unit tests for turning forum posts into Zen affirmations.
import assert from "node:assert/strict";
import { test } from "node:test";
import {
  extractSentences,
  isUsable,
  parseCategoryIds,
  pickDifferent,
  uniqueByText,
} from "../javascripts/discourse/lib/affirmations.js";

test("extractSentences keeps calm standalone sentences", () => {
  const text =
    "Heute war ein guter Tag im Garten mit allen.\nWer kommt morgen?\nSiehe https://example.org/foo für mehr.";
  assert.deepEqual(extractSentences(text), [
    "Heute war ein guter Tag im Garten mit allen.",
  ]);
});

test("extractSentences splits on punctuation and line breaks", () => {
  const text =
    "Wir haben gemeinsam viel geschafft in diesem Jahr! Danke an alle, die mitgemacht haben.\nGemeinsam sind wir stärker als allein";
  assert.deepEqual(extractSentences(text), [
    "Wir haben gemeinsam viel geschafft in diesem Jahr!",
    "Danke an alle, die mitgemacht haben.",
    "Gemeinsam sind wir stärker als allein.",
  ]);
});

test("isUsable rejects questions, mentions, short and long text", () => {
  assert.equal(false, isUsable("Kommt ihr alle zum Treffen am Freitag?"));
  assert.equal(false, isUsable("Danke @robert für die schnelle Hilfe hier."));
  assert.equal(false, isUsable("Kurz und gut."));
  assert.equal(false, isUsable("Ein sehr langer Satz ".repeat(10)));
  assert.equal(false, isUsable("Termine: 12.03. 14.03. 18.03. 20.03. 22.03."));
  assert.equal(false, isUsable("Hier ist die Liste der offenen Punkte:"));
  assert.equal(true, isUsable("Es tut gut, Teil dieser Gemeinschaft zu sein."));
});

test("pickDifferent avoids the last text when possible", () => {
  const items = [{ text: "a" }, { text: "b" }];
  assert.equal(pickDifferent(items, "a", () => 0).text, "b");
  assert.equal(pickDifferent([{ text: "a" }], "a").text, "a");
  assert.equal(pickDifferent([], "a"), undefined);
});

test("uniqueByText drops duplicates", () => {
  assert.deepEqual(uniqueByText([{ text: "a" }, { text: "a" }, { text: "b" }]), [
    { text: "a" },
    { text: "b" },
  ]);
});

test("parseCategoryIds reads the category list setting", () => {
  assert.deepEqual(parseCategoryIds("12|34|x|"), [12, 34]);
  assert.deepEqual(parseCategoryIds(""), []);
  assert.deepEqual(parseCategoryIds(undefined), []);
});
