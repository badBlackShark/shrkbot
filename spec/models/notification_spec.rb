# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification do
  describe "primary key" do
    subject(:id) { create(:notification).id }

    it "generates a prefixed-uuid" do
      expect(id).to match(/\Antf_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
    end
  end

  describe "validations" do
    subject(:notification) { build(:notification, kind: nil) }

    it "is invalid without kind" do
      expect(notification).not_to be_valid
    end
  end

  describe "associations" do
    subject(:notification) { build(:notification) }

    it "belongs to server_configuration" do
      expect(notification.server_configuration).to be_a(ServerConfiguration)
    end
  end

  describe ".active" do
    subject(:active) { described_class.active }

    let!(:live) { create(:notification) }
    let!(:dismissed) { create(:notification, dismissed_at: 1.hour.ago) }

    it "excludes dismissed notifications" do
      expect(active).to include(live)
      expect(active).not_to include(dismissed)
    end
  end

  describe ".unread" do
    subject(:unread) { described_class.unread }

    let!(:fresh) { create(:notification) }
    let!(:read) { create(:notification, read_at: 1.hour.ago) }
    let!(:dismissed) { create(:notification, dismissed_at: 1.hour.ago) }

    it "excludes read notifications" do
      expect(unread).not_to include(read)
    end

    it "excludes dismissed notifications" do
      expect(unread).not_to include(dismissed)
    end

    it "includes unread, undismissed notifications" do
      expect(unread).to include(fresh)
    end
  end
end
