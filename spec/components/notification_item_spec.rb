# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::NotificationItem do
  include_context "component view context"

  let(:config) { create(:server_configuration) }
  let(:notification_data) { {"plugin_key" => "logging", "plugin_name" => "Logging", "channel_name" => "general"} }

  subject(:html) { described_class.new(presenter:, server_id: config.discord_id).render_in(view_context) }

  context "when the notification is unread" do
    let(:notification) { create(:notification, server_configuration: config, read_at: nil, data: notification_data) }
    let(:presenter) { NotificationPresenter.new(notification) }

    it "renders the title with bold styling" do
      expect(html).to include("font-semibold text-text-primary")
    end

    it "renders the message with secondary text styling" do
      expect(html).to include("text-text-secondary")
    end

    it "renders the icon circle with full opacity" do
      expect(html).to include("bg-warning-soft")
      expect(html).not_to include("opacity-60")
    end

    it "renders the notification title text" do
      expect(html).to include("general was deleted")
    end

    it "renders the dismiss button" do
      expect(html).to include("Dismiss")
    end

    it "renders a deep-link href to the logging plugin page" do
      expect(html).to include("/servers/#{config.discord_id}/logging")
    end
  end

  context "when the notification is read" do
    let(:notification) { create(:notification, server_configuration: config, read_at: Time.current, data: notification_data) }
    let(:presenter) { NotificationPresenter.new(notification) }

    it "renders the title with muted styling" do
      expect(html).to include("font-medium text-text-secondary")
    end

    it "renders the message with muted text styling" do
      expect(html).to include("text-text-muted")
    end

    it "renders the icon circle with reduced opacity" do
      expect(html).to include("opacity-60")
    end

    it "renders the notification title text" do
      expect(html).to include("general was deleted")
    end

    it "renders the dismiss button" do
      expect(html).to include("Dismiss")
    end

    it "renders a deep-link href to the logging plugin page" do
      expect(html).to include("/servers/#{config.discord_id}/logging")
    end
  end
end
