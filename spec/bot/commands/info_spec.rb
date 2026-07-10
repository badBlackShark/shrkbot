# frozen_string_literal: true

require "rails_helper"

RSpec.describe Commands::Info do
  subject(:execute) { described_class.new(event).execute }

  let(:profile) { double("profile", username: "shrkbot") }
  let(:event) { double("event", bot: double("bot", profile:), respond: nil, server_id: nil) }

  def blocks(args)
    args[:components].first[:components].flat_map do |block|
      block[:components] || [block]
    end
  end

  def texts(args)
    blocks(args).filter_map { |block| block[:content] }
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

  it "shows the attached mascot as a thumbnail on the header section" do
    expect(event).to receive(:respond) do |args|
      section = args[:components].first[:components].find { |block| block[:type] == Discord::Components::SECTION }
      expect(section[:accessory]).to eq(
        type: Discord::Components::THUMBNAIL,
        media: {url: "attachment://shrkbot-mascot.png"}
      )
      expect(args[:attachments].sole.path).to end_with("app/assets/images/shrkbot-mascot.png")
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

  context "when the caller can manage the server in a guild" do
    let(:user) { double("member", id: 7, permission?: true) }
    let(:event) do
      double(
        "event",
        bot: double("bot", profile:),
        respond: nil,
        user:,
        server_id: 123
      )
    end

    before do
      allow(BotConfig).to receive(:owner_id).and_return(nil)
      allow(BotConfig).to receive(:web_base_url).and_return("https://shrk.test/")
    end

    context "when the caller can manage the server" do
      let(:member) { double("member", permission?: true) }

      it "includes a link to the server's configuration page" do
        expect(event).to receive(:respond) do |args|
          body = texts(args).join("\n")
          expect(body).to include("https://shrk.test/servers/123")
        end

        execute
      end
    end

    context "when the caller cannot manage the server" do
      let(:member) { double("member", permission?: false) }

      it "omits the configuration link" do
        expect(event).to receive(:respond) do |args|
          expect(texts(args).join("\n")).not_to include("/servers/")
        end

        execute
      end
    end
  end
end
