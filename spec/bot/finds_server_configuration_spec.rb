# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::FindsServerConfiguration do
  subject(:lookups) { Array.new(3) { finder.send(:server_configuration) } }

  let(:server) { double("server", id: 1) }
  let(:event) { double("event", server:) }
  let(:finder) do
    Class.new do
      include Bot::FindsServerConfiguration

      def initialize(event)
        @event = event
      end

      attr_reader :event
    end.new(event)
  end

  context "for a configured server" do
    let!(:config) { create(:server_configuration, discord_id: 1) }

    it "resolves the guild's configuration" do
      expect(lookups).to all(eq(config))
    end

    it "queries once however often a handler asks for it" do
      expect(ServerConfiguration).to receive(:find_by).once.and_return(config)
      lookups
    end
  end

  context "for an event with no server" do
    let(:server) { nil }

    it "resolves to nothing without querying at all" do
      expect(ServerConfiguration).not_to receive(:find_by)
      expect(lookups).to all(be_nil)
    end
  end

  context "for a server with no configuration" do
    it "caches the miss rather than re-querying for it" do
      expect(ServerConfiguration).to receive(:find_by).once.and_return(nil)
      expect(lookups).to all(be_nil)
    end
  end
end
