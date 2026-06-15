# Plugin catalog (the 3 toggleable plugins). Idempotent.
[
  {key: "logging", name: "Logging", description: "Writes moderation actions to a log channel.", default_enabled: true},
  {key: "roles", name: "Roles", description: "Self-assignable roles via a button menu.", default_enabled: false},
  {key: "welcomes", name: "Welcomes", description: "Join and leave messages.", default_enabled: false}
].each do |attrs|
  Plugin.find_or_create_by!(key: attrs[:key]) { |p| p.assign_attributes(attrs) }
end
