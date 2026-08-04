# Roles self-assignment

Why a single-select role set is one click and a multi-select one is two, and how
the message payload is built.

Each role set posts a public message and assigns roles through component
interactions (`app/plugins/roles/events/`). The flow differs by the set's
`selection_mode`, because a public message renders identically to everyone and so
can't show per-user state:

- **single** (exclusive) — the public message renders the role buttons directly.
  Clicking one assigns it and strips the set's other roles, with an ephemeral
  confirmation. One step; current state doesn't matter for an exclusive overwrite.
- **multi** — the public message carries one "Manage Roles" button. Clicking it opens
  an ephemeral string-select with the user's current roles pre-checked, so they can
  see and toggle what they have. Two steps, because the stateful view is the point.

Selection is always constrained to the set's own roles, so a forged `custom_id` can't
grant an arbitrary server role. The runtime toggle is bot-only (no DB write, no web
caller), so it lives in the handlers, not in an operation; the testable unit is the
pure `Roles::Assignment` diff with `member.modify_roles` as the seam.

Those builders live in [Message rendering](../bot/message-rendering.md).

`Roles::Message` composes those builders into a **Components V2** payload, so
`public_message`/`multi_picker` return `{components:, flags:}` with the `COMPONENTS_V2`
flag and no `content` — senders pass `has_components: true` (or the flag positionally).
Each message is a `Container` carrying the brand accent sidebar, a markdown
`### ` heading (Discord supports only h1–h3), a `Separator`, and then the controls.
Single sets put the role buttons straight in the container; multi sets list the roles
side by side (no markdown tables in Discord — an inline `•`-joined line) and expose the
manage button as a `Section` accessory. Buttons and select options are
**always labelled with the synced role name** (`ServerRole`, looked up by `role_id`),
not a stored label — Discord exposes no way to colour a button by the role's colour, so
the name is the only useful signal. A role missing from the sync falls back to a
placeholder so a component is never empty.
