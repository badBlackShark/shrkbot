# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Bus do
  let(:handler) { Class.new }
  let(:other_handler) { Class.new }

  context "with an isolated registry" do
    before do
      allow(described_class).to receive(:subscriptions).and_return({})
    end

    describe ".subscribe" do
      subject(:subscribe) { described_class.subscribe(handler, to: [Integrations::Steam::PatchNotesPublished]) }

      it "is idempotent per handler and event class" do
        subscribe
        subscribe

        expect(described_class.subscriptions).to eq(handler => [Integrations::Steam::PatchNotesPublished])
      end

      it "accumulates further event classes for the same handler" do
        subscribe
        described_class.subscribe(handler, to: Integrations::Steam::ArticlePublished)

        expect(described_class.subscriptions[handler]).to eq([Integrations::Steam::PatchNotesPublished, Integrations::Steam::ArticlePublished])
      end
    end

    describe ".handlers_for" do
      subject(:handlers) { described_class.handlers_for(build(:steam_news_event)) }

      before do
        described_class.subscribe(handler, to: [Integrations::Steam::NewsEvent])
        described_class.subscribe(other_handler, to: [Integrations::Steam::ArticlePublished])
      end

      it "matches subscribed superclasses and skips unrelated event classes" do
        expect(handlers).to eq([handler])
      end
    end
  end

  describe "the initializer" do
    it "wires Feeds::AnnounceJob to every Steam news event class" do
      events = [
        Integrations::Steam::PatchNotesPublished,
        Integrations::Steam::AnnouncementPublished,
        Integrations::Steam::ArticlePublished
      ].map(&:new)

      expect(events.map { |event| described_class.handlers_for(event) }).to all(eq([Feeds::AnnounceJob]))
    end
  end
end
