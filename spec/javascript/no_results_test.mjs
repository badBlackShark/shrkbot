import { test } from "node:test"
import assert from "node:assert/strict"

const { noResultsHtml } = await import("lib/no_results")

const escape = (text) => text.replace(/</g, "&lt;")

test("shows the failure text, escaped, when the search failed", () => {
  assert.equal(
    noResultsHtml({ failed: true, failureText: "Twitch <down>", escape }),
    '<div class="no-results">Twitch &lt;down></div>'
  )
})

test("shows Tom Select's own text when the search simply found nothing", () => {
  assert.equal(
    noResultsHtml({ failed: false, failureText: "Twitch down", escape }),
    '<div class="no-results">No results found</div>'
  )
})
