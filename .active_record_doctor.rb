# frozen_string_literal: true

ActiveRecordDoctor.configure do
  global :ignore_tables, [
    "schema_migrations",
    "ar_internal_metadata",
    /^solid_queue_/,
    /^solid_cache_/
  ]
  global :ignore_models, [
    /^SolidQueue::/,
    /^SolidCache::/
  ]

  # Discord snowflakes look like foreign keys but reference Discord, not our tables,
  # and are never queried on (lookups go through server_configuration_id).
  detector :unindexed_foreign_keys,
    ignore_columns: [
      "reminders.channel_id",
      "reminders.server_id",
      "logging_settings.channel_id",
      "role_settings.channel_id",
      "role_sets.message_id",
      "welcome_settings.channel_id",
      "assignable_roles.role_id",
      "server_channels.discord_id",
      "server_channels.parent_id",
      "server_roles.discord_id",
      "channel_overwrites.target_id",
      "moderation_settings.staff_role_id",
      "moderation_verdicts.log_channel_id",
      "moderation_verdicts.log_message_id",
      "lfg_pingable_roles.role_id",
      "lfg_messages.channel_id",
      "lfg_messages.notify_reply_id",
      "lfg_messages.start_ping_id",
      "twilight_struggle_destinations.discord_channel_id",
      "twilight_struggle_posted_messages.discord_channel_id",
      "twilight_struggle_posted_messages.discord_message_id"
    ]

  # The unique index on external_id is partial (WHERE external_id IS NOT NULL) because
  # the synthetic "friendly" tournament has none; the detector doesn't recognise partial
  # indexes as satisfying the uniqueness validation.
  detector :missing_unique_indexes,
    ignore_columns: ["TwilightStruggle::Tournament(external_id)"]

  # These are NOT NULL with a DB default, so they're never nil — presence is wrong
  # for booleans (it rejects false) and the default already guarantees integrity.
  detector :missing_presence_validation,
    ignore_columns_with_default: true,
    ignore_attributes: [
      "PluginActivation.enabled",
      "Moderation::SpamProtection::Settings.match_symbol_only_messages",
      "Reminders::Reminder.deliver_via_dm",
      "ServerConfiguration.force_dm_reminders",
      "ServerRole.managed",
      "Moderation::Phash.global_scam",
      "Welcomes::Settings.suppress_removal_messages"
    ]
end
