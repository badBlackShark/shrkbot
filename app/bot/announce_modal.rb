class AnnounceModal < BaseEvent
  on :modal_submit, custom_id: Commands::Announce::MODAL_ID

  def handle
    return reject unless owner?

    result = OwnerBroadcast.call(bots: BotRegistry.all, content: content)
    event.respond(
      content: "📣 Sent to #{result.sent}/#{result.owner_count} unique owner(s) across #{result.server_count} server(s).",
      ephemeral: true
    )
  end

  private

  def content
    event.value(Commands::Announce::INPUT_ID).to_s
  end

  def owner?
    CommandPermissions.permitted?(event: event, required: [], owner_only: true)
  end

  def reject
    event.respond(content: "🚫 You don't have permission to do that.", ephemeral: true)
  end
end
