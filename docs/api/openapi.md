# JSON APIs: OpenAPI, committee, and the docs site

How the APIs we expose to partner sites are validated, documented, and published —
including the committee setting that silently defeats a typed contract.

## Validation is the schema, not the controller

Request validation for a JSON API is an **OpenAPI 3 document enforced by the
`committee` gem's Rack middleware**. Not ActiveModel objects, not controller-level
checks. Established by the Twilight Struggle API; every future endpoint mirrors it.

The shape:

- One schema file per resource under `config/api/<api-name>/<version>/<resource>.yaml`.
- A loader merges the fragments into one document —
  `lib/twilight_struggle_api_schema.rb` is the reference (`.document` / `.driver`;
  its `merge_disjoint!` fails loud on a duplicate key rather than silently
  clobbering).
- **Auth runs as a Rack middleware inserted before committee**
  (`TwilightStruggleApiAuthentication`), so an unauthenticated request 401s without
  the schema ever revealing the contract.
- A `Committee::ValidationError` subclass renders 422s in the app's `{errors: [...]}`
  shape. It is defined in `config/initializers/committee.rb` rather than under
  `app/`, because initializers run before autoloading is available.

## The `coerce_form_params` gotcha

committee's OpenAPI 3 driver defaults **`coerce_form_params` to `true`**, and
despite the name it governs the **entire request body**, not just form encoding —
the gem's own source says so. With the default left alone, a JSON `"7"` is silently
cast to the integer the schema declares and passes validation.

Pass `coerce_form_params: false` to `Committee::Middleware::RequestValidation`, for
every API mounted on committee, or the typed contract is a lie.

This shipped and was only caught by hand-sent bad data. A schema gate that quietly
coerces is worse than no gate, because the specs pass and the docs read correctly —
which is why the "must 422" cases in a smoke script earn their keep.

## The OpenAPI document is the only source of prose

Public API docs are published at
[badblackshark.github.io/shrkbot](https://badblackshark.github.io/shrkbot/) — an
index page listing the APIs, then one Redoc page per API (`/twilight-struggle/v1/`,
with `openapi.json` beside it). Built by the `api_docs` job in
`.github/workflows/ci.yml` and deployed on every push to `main`.

**There is no parallel prose doc, and starting one is a mistake.** A standalone
`docs/twilight-struggle-api.md` existed and was deleted because it duplicated the
schema's field tables. Prose lives inside the schema instead:

- `info.description` and each resource's tag description are markdown files under
  `config/api/twilight-struggle/v1/docs/`;
- every field carries a `description:` in its yaml fragment.

A new field or endpoint documents itself there, or it is undocumented.

Tag order is declared in `TwilightStruggleApiSchema::TAGS` (Tournaments before
Games — the order integrators must send in), and a spec fails if any operation is
untagged.

`docs/site/index.html` is hand-written and self-contained: the Redocly CLI builds
one API at a time and its portal product is gone, so a multi-API index has to be
static. Its palette is copied from `app/assets/tailwind/tokens.css` (light and
dark) and it uses `system-ui` — GitHub Pages sits outside the Rails asset pipeline,
so an on-brand version would need real work.
