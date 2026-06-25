# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::DiscordMessagePreview do
  subject(:html) { described_class.new(**options).call }

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
    expect(html.scan("BOT").size).to eq(2)
    expect(html).to include("shrkbot")
  end

  it "passes each message's body data through to its output paragraph" do
    expect(html).to include('data-welcome-preview-target="joinOutput"')
    expect(html).to include('data-welcome-preview-target="leaveOutput"')
    expect(html).to include('data-empty-hint="off"')
  end

  it "shows a timestamp only where one is given" do
    expect(html.scan("Today").size).to eq(1)
  end

  context "without a channel" do
    let(:options) { {label: "Live preview", messages: []} }

    it "omits the channel suffix" do
      expect(html).not_to include("·")
    end
  end
end
