A tournament is the unit servers subscribe to, and the thing a game result hangs
off. `external_id` is your own id for it — whatever you use as the primary key on
your side.

Tournaments nest. `parent_external_id` groups a sub-event under a larger
tournament. A server that subscribes to a parent receives the results of every
tournament below it, and configuration (channel, message templates) is inherited
down the chain unless a level overrides it.

### Organisers

An organiser whose Discord ID we hold can reach the Twilight Struggle plugin on
any server where a shrkbot operator has granted the plugin, a server admin has
switched it on, and the organiser is a member — they do not need a server admin
to subscribe for them. Which tournaments they may subscribe and configure there
is a separate question, governed by the tournament chain: the ones they are named
on, plus that tournament's descendants. They can do everything a server admin can
on those tournaments except one thing — they cannot switch the plugin itself off,
since that would lock every organiser on the server out at once.

Sending `admins` replaces the whole set we hold for that tournament. Omitting the
key (or sending `null`) leaves our rows untouched — deliberate, so a partial
payload cannot silently revoke every organiser. Send `[]` to clear.

It is opt-in. An organiser with no Discord ID on your side simply has no record
with us, and the server's own admins configure the tournament for them. We never
infer an organiser's Discord ID from anywhere else — in particular never from the
player `discord_id`s in a game payload.

If that person deletes their shrkbot dashboard account, we delete the ID; a later
`PUT` that still includes it will store it again.
