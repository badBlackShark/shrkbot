# CSP and OAuth redirects

Why the Content Security Policy has to name Discord in `form-action`, and the
browser divergence that makes getting it wrong look like a device-specific bug.

Sign-in is a `button_to` POST to `/auth/discord`. OmniAuth answers it with a 302 to
`https://discord.com/api/oauth2/authorize`. Whether `form-action` applies across a
redirect is **undefined in the CSP spec** (w3c/webappsec-csp#8), and browsers
diverge on it:

- **Chrome and Safari enforce `form-action` on every hop of the redirect chain.**
- **Firefox does not apply it to redirects at all.**

So with `form-action 'self'` the sign-in button is silently dead in Chrome and
Safari and works fine in Firefox. The block is console-only — there is no
user-visible error, no failed request in the network tab, nothing. It presented as
a "mobile-only bug" (Firefox on desktop, Safari on iPhone) and cost a hunt through
CSS and JavaScript before anyone looked at CSP.

The policy therefore reads:

```ruby
policy.form_action :self, "https://discord.com"
```

**Rule:** any form that submits somewhere which redirects off-origin needs that
host listed in `form-action`. When a click "does nothing" in one browser but works
in another, check CSP before anything else, and reproduce in Chrome or Safari —
Firefox will not show it.

The policy is pinned by `spec/requests/content_security_policy_spec.rb`.
