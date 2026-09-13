# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Bot::Discord::ApplicationEmoji do
  let(:application) { {"id" => "900"}.to_json }
  let(:listing) { {"items" => [{"name" => "catalonia", "id" => "42"}, {"name" => "galicia", "id" => "43"}]}.to_json }

  before do
    described_class.reset!
    allow(Bot::Config).to receive(:token).and_return("tok")
    stub_const("Discordrb::API", class_double("Discordrb::API", api_base: "https://discord.test/api/v10"))
    allow(Discordrb::API).to receive(:request) do |_key, _major, _verb, url, *|
      url.end_with?("/applications/@me") ? application : listing
    end
  end

  after { described_class.reset! }

  describe ".mention" do
    it "renders the emoji Discord syntax for a name the application carries" do
      expect(described_class.mention("catalonia")).to eq("<:catalonia:42>")
    end

    it "renders nothing for a name the application does not carry" do
      expect(described_class.mention("brittany")).to be_nil
    end

    it "lists the application's emoji once, however many names are asked for" do
      3.times { described_class.mention("catalonia") }

      expect(Discordrb::API).to have_received(:request).twice
    end

    it "renders nothing rather than raising when Discord cannot be reached" do
      allow(Discordrb::API).to receive(:request).and_raise(StandardError, "connection reset")
      allow(Rails.logger).to receive(:error)

      expect(described_class.mention("catalonia")).to be_nil
    end
  end

  describe ".upload" do
    subject(:upload) { described_class.upload("brittany", image_path) }

    let(:image_path) { Rails.root.join("config/country_flag_images/brittany.png") }

    it "posts the image to the application as a data URI" do
      upload

      expect(Discordrb::API).to have_received(:request).with(
        :applications_aid_emojis,
        nil,
        :post,
        "https://discord.test/api/v10/applications/900/emojis",
        a_string_including('"name":"brittany"', '"image":"data:image/png;base64,'),
        hash_including(content_type: :json)
      )
    end
  end
end
