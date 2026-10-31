# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Steam::Client do
  subject(:get_json) do
    client.get_json(host, path, params:, status_errors:) { |body| body.fetch("answer") }
  end

  let(:client) { described_class.new }
  let(:host) { :api }
  let(:path) { "/ISteamNews/GetNewsForApp/v2/" }
  let(:params) { {appid: 440} }
  let(:status_errors) { {403 => Integrations::NotFound} }

  before do
    allow(Integrations::Http).to receive(:get_json) { |*_args, **_kwargs, &block| block.call({"answer" => 42}) }
  end

  context "with the api host" do
    it "requests the path on api.steampowered.com, passing params and status_errors through" do
      get_json

      expect(Integrations::Http).to have_received(:get_json).with(
        "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/",
        params: {appid: 440},
        status_errors: {403 => Integrations::NotFound}
      )
    end

    it "hands the caller's block to Http and returns its value" do
      expect(get_json).to eq(42)
    end
  end

  context "with a host Steam does not have" do
    let(:host) { :store }

    it "raises KeyError without requesting anything" do
      expect { get_json }.to raise_error(KeyError)
      expect(Integrations::Http).not_to have_received(:get_json)
    end
  end

  describe "#get_bytes" do
    subject(:bytes) { client.get_bytes("https://cdn.test/hero.jpg") }

    before do
      allow(Integrations::Http).to receive(:get_bytes).with("https://cdn.test/hero.jpg").and_return("jpeg")
    end

    it "downloads the URL through Http" do
      expect(bytes).to eq("jpeg")
    end
  end
end
