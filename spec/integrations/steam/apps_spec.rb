# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Steam::Apps do
  subject(:app) { apps.find(app_id) }

  let(:apps) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Steam::Client) }
  let(:app_id) { 1145360 }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/steam/appdetails_1145360.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks the store host for the app's basic details" do
    app

    expect(client).to have_received(:get_json).with(
      :store,
      "/api/appdetails",
      params: {appids: 1145360, filters: "basic"},
      status_errors: anything
    )
  end

  it "treats a 403 from the keyless store as Unavailable, not a credentials failure" do
    app

    expect(client).to have_received(:get_json).with(
      anything,
      anything,
      params: anything,
      status_errors: {403 => Integrations::Unavailable}
    )
  end

  it "returns the app" do
    expect(app).to eq(
      Integrations::Steam::App.new(
        id: 1145360,
        name: "Hades",
        type: "game",
        header_image_url: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1145360/header.jpg?t=1758127023"
      )
    )
  end

  context "when Steam answers success: false" do
    let(:app_id) { 999999999 }
    let(:response) { {"999999999" => {"success" => false}} }

    it "raises NotFound naming the app" do
      expect { app }.to raise_error(Integrations::NotFound, /999999999/)
    end
  end
end
