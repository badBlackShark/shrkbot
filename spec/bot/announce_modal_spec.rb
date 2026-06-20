require "rails_helper"

RSpec.describe AnnounceModal do
  subject(:handle) { described_class.new(event).handle }

  let(:event) { double("event", bot: double("bot"), respond: nil, defer: nil, edit_response: nil) }

  before do
    allow(event).to receive(:value).with(Commands::Announce::INPUT_ID).and_return("the announcement")
    allow(BotRegistry).to receive(:all).and_return([event.bot])
  end

  context "when the bot owner submits" do
    before do
      allow(CommandPermissions).to receive(:permitted?).and_return(true)
    end

    it "defers, broadcasts the submitted text, and reports a summary" do
      expect(event).to receive(:defer).with(ephemeral: true)
      expect(OwnerBroadcast).to receive(:call)
        .with(bots: [event.bot], content: "the announcement")
        .and_return(OwnerBroadcast::Result.new(owner_count: 3, sent: 3, server_count: 5))
      expect(event).to receive(:edit_response).with(hash_including(content: a_string_including("3/3")))

      handle
    end
  end

  context "when someone other than the bot owner submits" do
    before do
      allow(CommandPermissions).to receive(:permitted?).and_return(false)
    end

    it "rejects without broadcasting" do
      expect(OwnerBroadcast).not_to receive(:call)
      expect(event).to receive(:respond).with(hash_including(content: a_string_including("permission"), ephemeral: true))

      handle
    end
  end
end
