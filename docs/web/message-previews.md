# Message previews

How the web config UI shows "what this will look like in Discord" for a
message an admin is editing. Not to be confused with
[preview.md](preview.md), which is about demoing the whole web app against a
canned guild — that page is unrelated to this one.

## Where it renders

`Components::DiscordMessagePreview` draws the little Discord-style message
card: bot avatar, name, timestamp, message body. `Components::Welcomes::ConfigForm` and
`Components::TwilightStruggle::TemplateCard` both render it, one per template field they
let an admin edit. The component itself only lays out chrome — it renders an
empty `div` per message body and leaves the content to whichever Stimulus
controller owns that field, identified by a `data-*-preview-target` attribute
on the div.

## The split

Two library modules and the controllers divide the work along one seam: text
in, DOM out.

`lib/discord_markdown.js` parses raw template text into a block/inline AST —
paragraphs, headings, quotes, lists, code, and the inline styles nested inside
them. It knows nothing about the DOM and nothing about tokens; it is pure text
in, tree out, and is unit-tested directly against that tree under
`spec/javascript/`.

`lib/discord_markdown_dom.js` walks that tree and builds real DOM nodes —
`render(template, resolveText)` returns the array of block-level nodes ready
to append to a preview `div`. It builds every node with `createElement` and
`textContent`, never `innerHTML`: the text being rendered is admin-entered and
viewed by other admins, so the renderer has to be XSS-safe by construction,
not by sanitizing after the fact.

Both modules are unit-tested under `spec/javascript/` with Node's own test
runner and no test dependencies at all. The parser is pure, so it is asserted
directly against the tree it returns. The renderer needs a `document`, so
`support/fake_dom.mjs` supplies a minimal stand-in and serializes the result
back to a string the tests can compare; `support/register_hooks.mjs` teaches
Node to resolve the `lib/…` specifiers importmap serves in the browser, which
is why the suite runs as `node --import ./spec/javascript/support/register_hooks.mjs --test spec/javascript/`.

The Stimulus controllers (`welcome_preview_controller.js`,
`twilight_struggle_preview_controller.js`) own neither parsing nor DOM
construction. Each owns only its plugin's sample data — the fake member name,
the fake match result — and passes `render` a `resolveText` closure that
turns a raw string into token-substituted nodes, reusing `lib/token_preview.js`'s
existing `nodes`/`text`/`pill`/`hint` helpers to do it.

## Why substitution happens at the text leaves

`discord_markdown_dom.js` never sees a `{token}` itself — it hands every
`text` leaf of the AST to the controller's `resolveText` closure and appends
whatever nodes come back. That is what lets a token sit inside bold, inside a
list item, inside a quote: the AST already nested the text node correctly, so
substitution just has to happen wherever a text node appears, once.

Inline code and code blocks are the exception. Discord code spans aren't
supposed to have live content inside them, but the bot still substitutes
tokens there before sending — a `` `{username}` `` in a real message becomes
`` `newmember` ``, not literal token syntax. The preview has to match that,
but it can't insert a `<span class="discord-mention">` pill inside a `<code>`
without lying about what Discord actually renders. So code content resolves
through the same `resolveText` closure and then flattens back to plain text
(`resolveText(value).map(node => node.textContent).join("")`) before being
set as `textContent`.

## Why in-house, not a library

Every CommonMark-family gem or JS library gets Discord's dialect wrong in
ways that would silently misrender real messages: `__underline__` is bold in
CommonMark, and `||spoiler||` and `-# subtext` don't exist as CommonMark
syntax at all. The JS libraries that do target Discord's actual dialect
render by emitting HTML strings, which would force `innerHTML` onto
admin-entered text — the one thing this renderer exists to avoid. And
importmap has no build step to run a converter against, so pulling in any of
them would mean vendoring an already-converted blob and hand-maintaining it.
Writing the small parser and renderer ourselves keeps the whole path
`createElement`/`textContent` and keeps the dialect exactly Discord's.

## Supported syntax and known ceilings

Bold, italic, underline, strikethrough, spoiler, inline code, code blocks,
headings, subtext, block quotes, and ordered/unordered lists all render.
Three things deliberately don't, and won't without server-side data the
preview doesn't have:

- `<@user>`, `<@&role>`, and `<#channel>` mentions, custom emoji, and
  `<t:…>` timestamps render as their literal source text. Resolving them to a
  name requires data (guild members, roles, channels, emoji) that only exists
  server-side — the web preview has no live Discord connection to fetch it.
- Ambiguous nesting like `**a*b**` resolves permissively rather than to
  CommonMark's precedence rules. Discord's own client is lenient here too, so
  matching it exactly matters less than not crashing on it.
- Code blocks carry a `language` but render with no syntax highlighting —
  adding a highlighter is a heavier dependency than the rest of this feature
  justifies.

## Adding markdown rendering to a new preview surface

Call `render(template, resolveText)` from `lib/discord_markdown_dom`, where
`resolveText` is `(rawString) => Node[]`. If the surface has no tokens to
substitute, `resolveText` can just wrap the string in a single text node; if
it does, mirror the existing controllers and reuse `lib/token_preview.js`'s
`nodes` helper to interleave token pills with plain text before handing the
result back to `render`.
