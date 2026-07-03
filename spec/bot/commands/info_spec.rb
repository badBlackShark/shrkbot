# frozen_string_literal: true

require "rails_helper"

RSpec.describe Commands::Info do
  subject(:execute) { described_class.new(event).execute }

  let(:profile) { double("profile", username: "shrkbot") }
  let(:event) { double("event", bot: double("bot", profile:), respond: nil) }

  def texts(args)
    args[:components].first[:components].filter_map { |block| block[:content] }
  end

  it "responds with an ephemeral components-v2 message" do
    expect(event).to receive(:respond) do |args|
      expect(args[:ephemeral]).to be(true)
      expect(args[:has_components]).to be(true)
      expect(args[:components].first).to include(
        type: Discord::Components::CONTAINER,
        accent_color: BotConfig::ACCENT_COLOR
      )
    end

    execute
  end

  it "credits the stack and links the code, invite, and donate command" do
    expect(event).to receive(:respond) do |args|
      body = texts(args).join("\n")
      expect(body).to include("shrkbot")
      expect(body).to include("Ruby")
      expect(body).to include(described_class::INVITE_URL)
      expect(body).to include("discordrb").and include("Ruby on Rails")
      expect(body).to include("/donate")
    end

    execute
  end
end
