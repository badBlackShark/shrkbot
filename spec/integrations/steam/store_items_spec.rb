# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Steam::StoreItems do
  subject(:url) { store_items.hero_capsule_url("238960") }

  let(:store_items) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Steam::Client) }
  let(:assets) do
    {
      "asset_url_format" => "steam/apps/238960/${FILENAME}?t=1784681738",
      "header" => "177c9/header.jpg",
      "hero_capsule" => "f1dd19dcc3ae1110abcd5695678893cfba80aa28/hero_capsule.jpg"
    }
  end
  let(:store_item) { {"item_type" => 0, "id" => 238960, "success" => 1, "assets" => assets} }
  let(:response) { {"response" => {"store_items" => [store_item]}} }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks the API host for the app's assets" do
    url

    expect(client).to have_received(:get_json).with(
      :api,
      "/IStoreBrowseService/GetItems/v1/",
      params: {input_json: {ids: [{appid: 238960}], context: {language: "english", country_code: "US"}, data_request: {include_assets: true}}.to_json}
    )
  end

  it "builds the hero capsule url on the asset host" do
    expect(url).to eq("https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/238960/f1dd19dcc3ae1110abcd5695678893cfba80aa28/hero_capsule.jpg?t=1784681738")
  end

  context "when the item has no hero capsule" do
    let(:assets) { super().except("hero_capsule") }

    it "is nil" do
      expect(url).to be_nil
    end
  end

  context "when the item has no assets" do
    let(:store_item) { super().except("assets") }

    it "is nil" do
      expect(url).to be_nil
    end
  end

  context "when Steam returns no store items" do
    let(:response) { {"response" => {"store_items" => []}} }

    it "is nil" do
      expect(url).to be_nil
    end
  end
end
