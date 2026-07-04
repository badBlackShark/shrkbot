# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Notifications::MarkRead do
  include ActiveSupport::Testing::TimeHelpers

  let(:config) { create(:server_configuration) }
  let!(:unread) { create(:notification, server_configuration: config) }
  let!(:already_read) { create(:notification, server_configuration: config, read_at: 1.hour.ago) }

  subject(:result) { described_class.call(server_configurations: [config]) }

  it "returns a success result" do
    expect(result).to be_success
  end

  it "sets read_at on unread notifications" do
    travel_to(Time.current) do
      result
      expect(unread.reload.read_at).to eq(Time.current)
    end
  end

  it "does not change already-read notifications" do
    original_read_at = already_read.read_at
    result
    expect(already_read.reload.read_at).to eq(original_read_at)
  end

  context "with notifications from a different server" do
    let(:other_config) { create(:server_configuration) }
    let!(:other_notification) { create(:notification, server_configuration: other_config) }

    it "does not mark notifications from other servers" do
      result
      expect(other_notification.reload.read_at).to be_nil
    end
  end
end
