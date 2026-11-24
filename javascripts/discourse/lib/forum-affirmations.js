// Loads Zen affirmation candidates from posts in the admin-selected
// categories. Uses Discourse's ajax, so only content the viewer may read is
// fetched. Results are cached in sessionStorage for an hour.
import { ajax } from "discourse/lib/ajax";
import {
  cookedToText,
  extractSentences,
  parseCategoryIds,
  uniqueByText,
} from "./affirmations";

const CACHE_KEY = "complexity-modes:zen-forum";
const CACHE_MS = 60 * 60 * 1000;
const TOPICS_PER_LOAD = 4;
const POSTS_PER_TOPIC = 20;
const REGULAR_POST = 1;

let pending;

export function configuredCategoryIds() {
  return parseCategoryIds(settings.zen_affirmation_categories);
}

function readCache(ids) {
  try {
    const cached = JSON.parse(window.sessionStorage.getItem(CACHE_KEY));
    if (
      cached &&
      cached.ids === ids.join("|") &&
      Date.now() - cached.at < CACHE_MS &&
      cached.items?.length
    ) {
      return cached.items;
    }
  } catch {
    // no or broken cache
  }
}

function writeCache(ids, items) {
  try {
    window.sessionStorage.setItem(
      CACHE_KEY,
      JSON.stringify({ ids: ids.join("|"), at: Date.now(), items })
    );
  } catch {
    // storage unavailable or full
  }
}

function shuffle(list) {
  const a = [...list];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

async function topicsIn(categoryId) {
  const data = await ajax(`/c/${categoryId}/l/latest.json`);
  return (data?.topic_list?.topics || []).filter(
    (t) => !t.closed && !t.archived && t.visible !== false
  );
}

async function sentencesFrom(topic, parser) {
  const data = await ajax(`/t/${topic.id}.json`);
  const posts = (data?.post_stream?.posts || [])
    .filter((p) => p.post_type === REGULAR_POST && !p.hidden && !p.deleted_at)
    .slice(0, POSTS_PER_TOPIC);

  return posts.flatMap((post) =>
    extractSentences(cookedToText(post.cooked, parser)).map((text) => ({
      text,
      title: data.title,
      url: `/t/${data.slug}/${data.id}/${post.post_number}`,
    }))
  );
}

// Returns [{ text, title, url }], or [] when nothing is configured, nothing
// usable was found or a request failed.
export function loadForumAffirmations() {
  const ids = configuredCategoryIds();
  if (!ids.length) {
    return Promise.resolve([]);
  }

  const cached = readCache(ids);
  if (cached) {
    return Promise.resolve(cached);
  }

  pending ??= (async () => {
    try {
      const lists = await Promise.allSettled(ids.map(topicsIn));
      const topics = shuffle(
        lists.flatMap((r) => (r.status === "fulfilled" ? r.value : []))
      ).slice(0, TOPICS_PER_LOAD);

      const parser = new DOMParser();
      const results = await Promise.allSettled(
        topics.map((t) => sentencesFrom(t, parser))
      );
      const items = uniqueByText(
        results.flatMap((r) => (r.status === "fulfilled" ? r.value : []))
      );

      if (items.length) {
        writeCache(ids, items);
      }
      return items;
    } catch {
      return [];
    } finally {
      pending = undefined;
    }
  })();

  return pending;
}
