# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationPresenter do
  let(:notification) do
    build(
      :notification,
      kind: "channel_deleted",
      data: {"plugin_name" => "Logging", "channel_name" => "mod-log", "plugin_key" => "logging"}
    )
  end

  subject(:presenter) { described_class.new(notification) }

  describe "#title" do
    it "interpolates the channel name" do
      expect(presenter.title).to eq("mod-log was deleted")
    end

    context "when channel_name is nil" do
      before { notification.data = {"plugin_name" => "Logging", "plugin_key" => "logging"} }

      it "falls back to the title_unknown key" do
        expect(presenter.title).to eq("A channel was deleted")
      end
    end
  end

  describe "#message" do
    it "returns the localised message" do
      expect(presenter.message).to eq("Logging was affected — choose a new channel")
    end
  end

  describe "#icon" do
    it "returns warning for channel_deleted" do
      expect(presenter.icon).to eq("warning")
    end

    context "with an unknown kind" do
      before { notification.kind = "unknown_kind" }

      it "falls back to bell" do
        expect(presenter.icon).to eq("bell")
      end
    end
  end

  describe "#unread?" do
    it "returns true when read_at is nil" do
      notification.read_at = nil
      expect(presenter.unread?).to be(true)
    end

    it "returns false when read_at is set" do
      notification.read_at = Time.current
      expect(presenter.unread?).to be(false)
    end
  end
end
