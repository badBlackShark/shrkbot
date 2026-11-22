# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::TitleHistory do
  let(:started_at) { Time.utc(2026, 11, 6, 18, 0, 0) }
  let(:ended_at) { started_at + 3.hours }
  let(:first) { build(:twitch_stream_started_event, title: "Opening", category_name: "Hades II", started_at: started_at.iso8601, occurred_at: started_at) }
  let(:changes) { [first, *later_changes] }
  let(:later_changes) { [] }

  def update(minutes, **attributes)
    build(:twitch_stream_updated_event, occurred_at: started_at + minutes.minutes, **attributes)
  end

  describe "#entries" do
    subject(:entries) { described_class.new(changes, ended_at:).entries }

    context "with three changes" do
      let(:later_changes) do
        [
          update(60, title: "Boss rush", category_name: "Hades II"),
          update(150, title: "Chatting", category_name: "Just Chatting")
        ]
      end

      it "lists them in order with the time each was up" do
        expect(entries).to eq([
          described_class::Entry.new(title: "Opening", category: "Hades II", seconds: 3600),
          described_class::Entry.new(title: "Boss rush", category: "Hades II", seconds: 5400),
          described_class::Entry.new(title: "Chatting", category: "Just Chatting", seconds: 1800)
        ])
      end
    end

    context "with a title change after the stream went offline" do
      let(:later_changes) do
        [
          update(120, title: "Boss rush", category_name: "Hades II"),
          update(182, title: "Next stream: Tuesday", category_name: "Just Chatting")
        ]
      end

      it "ignores it and ends the last entry at the end of the stream" do
        expect(entries).to eq([
          described_class::Entry.new(title: "Opening", category: "Hades II", seconds: 7200),
          described_class::Entry.new(title: "Boss rush", category: "Hades II", seconds: 3600)
        ])
      end
    end

    context "with a title that was up for 2 minutes" do
      let(:later_changes) do
        [
          update(60, title: "Opnening typo", category_name: "Hades II"),
          update(62, title: "Boss rush", category_name: "Hades II")
        ]
      end

      it "drops the typo" do
        expect(entries.map(&:title)).to eq(["Opening", "Boss rush"])
      end
    end

    context "with consecutive entries of the same title and category" do
      let(:later_changes) do
        [
          update(60, title: "Opening", category_name: "Hades II"),
          update(120, title: "Boss rush", category_name: "Hades II")
        ]
      end

      it "merges them and sums the time" do
        expect(entries.map(&:deconstruct)).to eq([["Opening", "Hades II", 7200], ["Boss rush", "Hades II", 3600]])
      end
    end

    context "with the same title in a different category" do
      let(:later_changes) { [update(60, title: "Opening", category_name: "Just Chatting")] }

      it "keeps them apart" do
        expect(entries.map(&:category)).to eq(["Hades II", "Just Chatting"])
      end
    end
  end

  describe ".for" do
    subject(:entries) { described_class.for(ended) }

    let!(:started) { create(:twitch_stream_started_event, title: "Opening", started_at: started_at.iso8601, occurred_at: started_at) }
    let!(:updated) do
      create(:twitch_stream_updated_event, watch: started.watch, session: started.session, title: "Boss rush", occurred_at: started_at + 1.hour)
    end
    let(:ended) do
      create(:twitch_stream_ended_event, watch: started.watch, session: started.session, occurred_at: ended_at, ended_at: ended_at.iso8601)
    end

    before do
      create(:twitch_stream_updated_event, watch: started.watch, session: "other", story_key: "stream:other", title: "Elsewhere", occurred_at: started_at + 30.minutes)
    end

    it "reads the events of the ended story only" do
      expect(entries.map(&:title)).to eq(["Opening", "Boss rush"])
    end
  end
end
