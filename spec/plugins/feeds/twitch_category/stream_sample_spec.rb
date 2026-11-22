# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::TwitchCategory::StreamSample do
  subject(:sample) { described_class.call("7") }

  let(:category_streams) { instance_double(Integrations::Twitch::CategoryStreams) }
  let(:stream) do
    Integrations::Twitch::Stream.new(
      id: "s1",
      user_id: "1",
      user_login: "LiveOne",
      user_name: "Live One",
      category_id: "7",
      category_name: "Chess",
      title: "Ranked",
      viewer_count: 12,
      started_at: Time.zone.parse("2026-11-01 09:00:00"),
      language: "de"
    )
  end

  before do
    allow(Integrations::Twitch::CategoryStreams).to receive(:new).and_return(category_streams)
    allow(category_streams).to receive(:current).with("7").and_return([stream])
  end

  it "reduces each stream to viewers, language and a lowercase login" do
    expect(sample).to eq([{viewers: 12, language: "de", login: "liveone"}])
  end

  context "when Twitch fails" do
    before { allow(category_streams).to receive(:current).and_raise(Integrations::Error) }

    it "is nil" do
      expect(sample).to be_nil
    end
  end
end
