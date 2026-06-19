require "rails_helper"

RSpec.describe Ops::Welcomes::Settings::Update do
  subject(:result) do
    described_class.call(server_configuration: server, channel_id:, join_message:, leave_message:)
  end

  let(:server) { create(:server_configuration, discord_id: 1) }
  let!(:setting) { server.create_welcome_settings! }
  let(:channel_id) { 99 }
  let(:join_message) { "hi" }
  let(:leave_message) { "bye" }

  it "sets the channel and messages" do
    expect(result.success?).to be(true)
    setting.reload
    expect(setting.channel_id).to eq(99)
    expect(setting.join_message).to eq("hi")
    expect(setting.leave_message).to eq("bye")
  end

  context "updating existing values" do
    before do
      setting.update!(channel_id: 1, join_message: "old")
    end

    let(:channel_id) { 2 }
    let(:join_message) { "new" }
    let(:leave_message) { nil }

    it "overwrites them" do
      result
      setting.reload
      expect(setting.channel_id).to eq(2)
      expect(setting.join_message).to eq("new")
      expect(setting.leave_message).to be_nil
    end
  end

  context "without a channel" do
    let(:channel_id) { nil }
    let(:leave_message) { nil }

    it "still saves (a channel is required only to enable)" do
      expect(result.success?).to be(true)
      expect(setting.reload.channel_id).to be_nil
    end
  end
end
