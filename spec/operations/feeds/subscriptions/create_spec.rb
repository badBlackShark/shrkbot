# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Feeds::Subscriptions::Create do
  subject(:result) do
    described_class.call(
      server_configuration:,
      watcher: "Integrations::Steam::NewsWatcher",
      target:,
      channel_id:,
      role_id:,
      body_length: "full",
      event_types:,
      templates:
    )
  end

  let(:server_configuration) { create(:server_configuration) }
  let(:target) { Integrations::Target.new(external_id: "1145350", name: "Hades II", image_url: "https://shared.akamai.steamstatic.com/hades.jpg") }
  let(:channel_id) { "555" }
  let(:role_id) { "777" }
  let(:event_types) { %w[Integrations::Steam::PatchNotesPublished Integrations::Steam::AnnouncementPublished] }
  let(:templates) { {} }
  let(:watch) { Integrations::Watch.find_by!(external_id: "1145350") }

  it "stores the subscription with its settings" do
    expect(result.value).to have_attributes(
      persisted?: true,
      server_configuration:,
      channel_id: 555,
      role_id: 777,
      body_length: "full"
    )
  end

  it "stores one subscribed event per type, dated now" do
    result

    expect(result.value.subscribed_events.map(&:event_type)).to match_array(event_types)
    expect(result.value.subscribed_events.map(&:subscribed_since)).to all(be_within(1.minute).of(Time.current))
  end

  context "with submitted templates" do
    let(:templates) do
      {
        "Integrations::Steam::PatchNotesPublished" => " Patch day: {title} ",
        "Integrations::Steam::AnnouncementPublished" => "{role} New {game} announcement: {title}"
      }
    end

    it "stores custom text and nothing for the default text" do
      stored = result.value.subscribed_events.to_h { |event| [event.event_type, event.template] }

      expect(stored).to eq(
        "Integrations::Steam::PatchNotesPublished" => "Patch day: {title}",
        "Integrations::Steam::AnnouncementPublished" => nil
      )
    end
  end

  context "with a template that would post nothing" do
    let(:role_id) { "" }
    let(:templates) { {"Integrations::Steam::PatchNotesPublished" => "{role}"} }

    it "fails and writes nothing" do
      expect { result }.not_to change { [Integrations::Watch.count, Feeds::Subscription.count] }

      expect(result).to be_failure
    end
  end

  it "creates the watch with the game's name and image" do
    result

    expect(watch).to have_attributes(
      watcher: "Integrations::Steam::NewsWatcher",
      name: "Hades II",
      image_url: "https://shared.akamai.steamstatic.com/hades.jpg"
    )
  end

  context "without a role" do
    let(:role_id) { "" }

    it "stores no ping" do
      expect(result.value.role_id).to be_nil
    end
  end

  context "when another server already follows the game" do
    let!(:existing_watch) do
      create(:integration_watch, external_id: "1145350", name: "Hades 2 (old)", image_url: "https://old.example/hades.jpg")
    end

    it "reuses the watch and refreshes its name and image" do
      expect { result }.not_to change(Integrations::Watch, :count)

      expect(existing_watch.reload).to have_attributes(name: "Hades II", image_url: "https://shared.akamai.steamstatic.com/hades.jpg")
      expect(result.value.watch).to eq(existing_watch)
    end
  end

  context "when the server already follows the game" do
    before { create(:feed_subscription, server_configuration:, watch: create(:integration_watch, external_id: "1145350")) }

    it "fails naming the game and adds nothing" do
      expect { result }.not_to change(Feeds::Subscription, :count)

      expect(result).to be_failure
      expect(result.errors).to eq(["This server already follows Hades II."])
    end
  end

  context "when the server is at the cap" do
    before do
      create_list(:feed_subscription, Feeds::Subscription::MAX_PER_SERVER, server_configuration:)
    end

    it "fails with the cap and creates no watch" do
      expect { result }.not_to change(Integrations::Watch, :count)

      expect(result).to be_failure
      expect(result.errors).to eq(["This server follows 25 games, the most it can. Stop following one to add another."])
    end
  end

  context "when an event type is unknown" do
    let(:event_types) { %w[Integrations::Steam::PatchNotesPublished Nope] }

    it "fails and creates no watch or subscription" do
      expect { result }.not_to change { [Integrations::Watch.count, Feeds::Subscription.count] }

      expect(result).to be_failure
      expect(result.value).to be_a(Feeds::Subscription)
    end
  end

  context "when the channel is blank" do
    let(:channel_id) { "" }

    it "fails and creates no watch or subscription" do
      expect { result }.not_to change { [Integrations::Watch.count, Feeds::Subscription.count] }

      expect(result.errors).to include("Channel can't be blank")
    end
  end
end
