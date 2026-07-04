# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::NotificationPanel do
  include_context "component view context"

  let(:manageable_ids) { [] }
  let(:authorized) { AuthorizedNotifications.new(manageable_ids:) }

  subject(:html) { described_class.new(authorized:).render_in(view_context) }

  it "renders the panel title" do
    expect(html).to include("Notifications")
  end

  context "when there are no notifications" do
    it "renders the empty state" do
      expect(html).to include("You&#39;re all caught up").or include("You're all caught up")
    end

    it "renders the empty subtitle" do
      expect(html).to include("Alerts about your servers will show up here")
    end

    it "does not render the mark-all-read button" do
      expect(html).not_to include("Mark all read")
    end
  end

  context "when there are notifications" do
    let(:config) { create(:server_configuration, name: "Dev Server") }
    let(:manageable_ids) { [config.discord_id] }
    let!(:notification) { create(:notification, server_configuration: config, data: {"plugin_key" => "logging", "plugin_name" => "Logging", "channel_name" => "general"}) }

    it "renders the mark-all-read button" do
      expect(html).to include("Mark all read")
    end

    it "renders the notification title" do
      expect(html).to include("general was deleted")
    end
  end

  context "when rendered in all-servers scope (server_id: nil) with grouped notifications" do
    let(:config_a) { create(:server_configuration, name: "Alpha Server") }
    let(:config_b) { create(:server_configuration, name: "Beta Server", icon_hash: "abc123hash") }
    let(:manageable_ids) { [config_a.discord_id, config_b.discord_id] }
    let(:notification_data) { {"plugin_key" => "logging", "plugin_name" => "Logging", "channel_name" => "general"} }
    let!(:notification_a) { create(:notification, server_configuration: config_a, data: notification_data) }
    let!(:notification_b) { create(:notification, server_configuration: config_b, data: notification_data) }

    subject(:html) { described_class.new(authorized:).render_in(view_context) }

    it "renders grouped notifications for all servers" do
      expect(html).to include("general was deleted")
    end

    it "renders the mark-all-read button when items exist" do
      expect(html).to include("Mark all read")
    end

    it "renders server group headers" do
      expect(html).to include("Alpha Server")
      expect(html).to include("Beta Server")
    end

    it "renders an img tag for a server with an icon_hash" do
      expect(html).to include("<img")
      expect(html).to include("abc123hash")
    end

    it "renders initials fallback for a server without an icon_hash" do
      # config_a has no icon_hash — falls back to initials span
      expect(html).to include("bg-accent-soft")
    end
  end
end
