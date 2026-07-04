# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Notifications::Read do
  subject(:result) { described_class.call(notification:) }

  context "when the notification is unread" do
    let(:notification) { create(:notification, read_at: nil) }

    it "marks it read" do
      expect { result }.to change { notification.reload.read_at }.from(nil)
    end

    it "returns the notification" do
      expect(result.value).to eq(notification)
    end
  end

  context "when the notification is already read" do
    let(:notification) { create(:notification, read_at: 1.day.ago) }

    it "leaves the timestamp untouched" do
      expect { result }.not_to change { notification.reload.read_at }
    end
  end
end
