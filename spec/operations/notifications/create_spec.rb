# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Notifications::Create do
  let(:server) { create(:server_configuration) }

  describe "with explicit data" do
    subject(:result) do
      described_class.call(
        server_configuration: server,
        kind: "channel_deleted",
        data: {plugin_key: "welcomes", channel_name: "general"}
      )
    end

    it "creates a Notification row" do
      expect { result }.to change(Notification, :count).by(1)
    end

    it "returns the created notification in result.value" do
      expect(result.value).to be_a(Notification)
    end

    it "persists the correct kind" do
      expect(result.value.kind).to eq("channel_deleted")
    end

    it "persists the correct data" do
      expect(result.value.data).to eq("plugin_key" => "welcomes", "channel_name" => "general")
    end
  end

  describe "data defaults to {}" do
    subject(:result) { described_class.call(server_configuration: server, kind: "channel_deleted") }

    it "stores empty data when omitted" do
      expect(result.value.data).to eq({})
    end
  end
end
