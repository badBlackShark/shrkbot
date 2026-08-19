# Finders (the read seam)

`Finders::` holds **query objects**: classes whose whole job is to ask the database
(or a cached remote) a question and hand back records or ids. They are the read-side
counterpart to `Ops::` — where operations own every write, finders own the
non-trivial reads that would otherwise fatten a controller or a presenter.

`app/finders/` is pushed with `namespace: Finders`, exactly like `app/operations/`
is for `Ops`, so the directory and the constant agree:

    app/finders/visible_servers.rb                        -> Finders::VisibleServers
    app/finders/twilight_struggle/organiser_servers.rb     -> Finders::TwilightStruggle::OrganiserServers

Sub-directories group by plugin or integration, the same way the rest of the app does.

## What belongs here, and what doesn't

A finder **returns records, ids, or a relation**, and nothing else. If a class also
shapes data for display — building select options, formatting labels, deciding what a
page shows — it is a presenter and stays in `app/presenters/`.

That line is why some querying classes are deliberately NOT finders:

- **`app/presenters/*_options.rb`** (`ChannelOptions`, `ServerRoleOptions`, …) query,
  but exist to build `TomSelect::Option`s. Presentation.
- **`CachedDashboard`, `ServerDashboard`** query, but their job is assembling one
  page's view model.
- **`TwilightStruggle::EffectiveConfig`** queries the destination chain, but its job
  is resolving inherited values with i18n fallbacks. Domain logic, and it stays in
  `app/models/`.

Value objects, static catalogs and utility modules (`Duration`, `TemplateText`,
`PluginCatalog`, `LoggableEventCatalog`, `PreviewData`) also stay in `app/models/`.
`app/models/` holding more than ActiveRecord classes is accepted; holding query
objects is what this layer fixed.

## The shadowing trap

`Finders::TwilightStruggle` shadows the top-level `::TwilightStruggle`, the same way
`Ops::ServerConfiguration` shadows the model. Inside a namespaced finder, reference
real models with a leading `::`:

```ruby
module Finders
  module TwilightStruggle
    class AdministeredTournaments
      # ::TwilightStruggle::Tournament — a bare Tournament would resolve to
      # Finders::TwilightStruggle::Tournament and raise NameError
    end
  end
end
```

This bites one level deeper every time the namespace deepens. See also
[operations-layer.md](operations-layer.md), which has the same trap.
