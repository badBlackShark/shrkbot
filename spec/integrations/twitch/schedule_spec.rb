# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Schedule do
  subject(:segments) { schedule.segments("229729353", start_time: Time.utc(2026, 10, 30, 12, 0, 0), first: 5) }

  let(:schedule) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/schedule_criticalrole.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks for the segments from the given time" do
    segments

    expect(client).to have_received(:get_json).with(
      "/schedule",
      params: {broadcaster_id: "229729353", start_time: "2026-10-30T12:00:00Z", first: 5}
    )
  end

  it "maps the first segment" do
    expect(segments.first).to eq(
      Integrations::Twitch::Segment.new(
        id: "eyJzZWdtZW50SUQiOiJiMTM1NmNmZC1hYmJhLTRhN2YtYjcyMi05ZGE5Yzk3YWNlYTkiLCJpc29ZZWFyIjoyMDI2LCJpc29XZWVrIjo0NX0=",
        start_time: Time.utc(2026, 11, 6, 3, 0, 0),
        end_time: Time.utc(2026, 11, 6, 7, 0, 0),
        title: "Critical Role: Campaign 4",
        category_id: "509577",
        category_name: "Dungeons & Dragons",
        canceled_until: nil,
        recurring: true
      )
    )
  end

  it "returns every segment" do
    expect(segments.size).to eq(3)
  end

  context "when a segment has no category, no end time and no title" do
    let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/schedule_lirik.json").read) }

    it "maps them to nil, keeping the empty title" do
      expect(segments.first).to have_attributes(
        category_id: nil,
        category_name: nil,
        end_time: nil,
        title: ""
      )
    end
  end

  context "when a segment is canceled" do
    let(:response) do
      super().tap { |body| body.fetch("data").fetch("segments").first["canceled_until"] = "2026-11-07T03:00:00Z" }
    end

    it "carries the time it is canceled until" do
      expect(segments.first.canceled_until).to eq(Time.utc(2026, 11, 7, 3, 0, 0))
    end
  end

  context "when the segments are null" do
    let(:response) { {"data" => {"segments" => nil, "vacation" => nil}} }

    it "returns nothing" do
      expect(segments).to eq([])
    end
  end

  context "when the channel has no schedule and Twitch answers 404" do
    before do
      allow(client).to receive(:get_json).and_raise(Integrations::NotFound)
    end

    it "returns nothing" do
      expect(segments).to eq([])
    end
  end
end
