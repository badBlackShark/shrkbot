# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::TargetCaption do
  subject(:caption) { described_class.call(plugin_key, "1145350") }

  context "with a source that names its ids" do
    let(:plugin_key) { :steam }

    it "captions the target with its id" do
      expect(caption).to eq("Steam app 1145350")
    end
  end

  context "with a source whose ids mean nothing to users" do
    let(:plugin_key) { :twitch }

    it "has no caption" do
      expect(caption).to be_nil
    end
  end
end
