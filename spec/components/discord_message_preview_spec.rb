# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::DiscordMessagePreview do
  include_context "component view context"

  subject(:html) { described_class.new(**options).render_in(view_context) }

  let(:options) do
    {
      label: "Live preview",
      channel: "# welcome",
      messages: [
        {timestamp: "Today", body_data: {welcome_preview_target: "joinOutput", empty_hint: "off"}},
        {body_data: {welcome_preview_target: "leaveOutput", empty_hint: "off"}}
      ]
    }
  end

  it "drives its colours off theme-aware Discord variables, never hardcoded hex" do
    expect(html).to include("bg-[var(--discord-surface)]").and include("text-[color:var(--discord-text)]")
    expect(html).not_to include("#313338")
  end

  it "renders the channel header and one row per message with the bot identity" do
    expect(html).to include("Live preview").and include("· # welcome")
    expect(html.scan("APP").size).to eq(2)
    expect(html).to include("shrkbot")
    expect(html.scan("shrkbot-mascot").size).to eq(2)
  end

  it "passes each message's body data through to its output element" do
    expect(html).to include('data-welcome-preview-target="joinOutput"')
    expect(html).to include('data-welcome-preview-target="leaveOutput"')
    expect(html).to include('data-empty-hint="off"')
  end

  it "shows a timestamp only where one is given" do
    expect(html.scan("Today").size).to eq(1)
  end

  context "with a card on a message" do
    let(:options) do
      {
        label: "Preview",
        messages: [{body_data: {}, card: {title: "Patch 1.4", body: "Fixed things.", button: "Read the full post"}}]
      }
    end

    it "renders the title, body and link button under the message" do
      expect(html).to include("Patch 1.4", "Fixed things.", "Read the full post", "--discord-code-bg")
    end
  end

  context "with an eyebrow and thumbnail on the card" do
    let(:options) do
      {
        label: "Preview",
        messages: [{card: {eyebrow: "Hades II · Patch notes", thumbnail: "https://img/header.jpg", title: "Patch 1.4", body: "Fixed.", button: "Read"}}]
      }
    end

    it "renders the eyebrow above the title and the thumbnail beside them" do
      expect(html.index("Hades II · Patch notes")).to be < html.index("Patch 1.4")
      expect(html).to include('src="https://img/header.jpg"')
    end
  end

  context "without an eyebrow or thumbnail" do
    let(:options) { {label: "Preview", messages: [{card: {title: "Patch 1.4", body: "Fixed.", button: "Read"}}]} }

    it "renders just the title" do
      expect(html).to include("Patch 1.4")
      expect(html).not_to include("<img src=")
    end
  end

  context "without a card" do
    it "renders no card" do
      expect(html).not_to include("--discord-code-bg")
    end
  end

  context "without a channel" do
    let(:options) { {label: "Live preview", messages: []} }

    it "omits the channel suffix" do
      expect(html).not_to include("·")
    end
  end
end
