# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::MemberActionLog do
  subject(:handle) { klass.new(event).handle }

  let(:klass) do
    Class.new(described_class) do
      event_key :member_banned
    end
  end
  let(:server) { double("server", id: 111) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, bot:) }
  let(:server_configuration) { double("server_configuration") }

  before do
    allow(ServerConfiguration).to receive(:find_by).with(discord_id: 111).and_return(server_configuration)
    allow(ActivityLog).to receive(:enabled?).and_return(true)
    allow(ActivityLog).to receive(:post)
  end

  it "requires subclasses to implement loggable?" do
    expect { handle }.to raise_error(AbstractMethodError, /must implement #loggable\?/)
  end

  context "when loggable? is implemented but entry is not" do
    let(:klass) do
      Class.new(described_class) do
        event_key :member_banned

        private

        def loggable?
          true
        end
      end
    end

    it "requires subclasses to implement entry" do
      expect { handle }.to raise_error(AbstractMethodError, /must implement #entry/)
    end
  end

  context "when the event has no server" do
    let(:event) { double("event", server: nil, bot:) }

    before do
      allow(ServerConfiguration).to receive(:find_by).with(discord_id: nil).and_return(nil)
    end

    it "does not post" do
      handle
      expect(ActivityLog).not_to have_received(:post)
    end
  end
end
