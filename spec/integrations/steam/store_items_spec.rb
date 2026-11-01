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

  describe "#find_all" do
    subject(:items) { store_items.find_all(app_ids) }

    let(:app_ids) { %w[1145360 440 999999999] }
    let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/steam/getitems_1145360_440_unknown.json").read) }

    it "asks for every id in one call" do
      items

      expect(client).to have_received(:get_json).once.with(
        :api,
        "/IStoreBrowseService/GetItems/v1/",
        params: {input_json: {ids: [{appid: 1145360}, {appid: 440}, {appid: 999999999}], context: {language: "english", country_code: "US"}, data_request: {include_assets: true}}.to_json}
      )
    end

    it "maps the apps Steam knows and drops the unknown one" do
      expect(items).to eq(
        [
          Integrations::Steam::StoreItem.new(
            app_id: "1145360",
            name: "Hades",
            header_image_url: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1145360/header.jpg?t=1758127023"
          ),
          Integrations::Steam::StoreItem.new(
            app_id: "440",
            name: "Team Fortress 2",
            header_image_url: "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/440/header.jpg?t=1757348372"
          )
        ]
      )
    end

    context "with more ids than one call takes" do
      let(:app_ids) { (1..101).map(&:to_s) }
      let(:requested) { [] }

      before do
        allow(client).to receive(:get_json) do |_host, _path, params:, &block|
          requested << JSON.parse(params.fetch(:input_json)).fetch("ids").map { |id| id.fetch("appid") }
          block.call(response)
        end
      end

      it "splits them into a call of 100 and a call of 1" do
        items

        expect(requested).to eq([(1..100).to_a, [101]])
      end
    end

    context "with no ids" do
      let(:app_ids) { [] }

      it "makes no request and returns nothing" do
        expect(items).to eq([])
        expect(client).not_to have_received(:get_json)
      end
    end

    context "when an item has no header" do
      let(:response) do
        {"response" => {"store_items" => [{"success" => 1, "appid" => 440, "name" => "Team Fortress 2", "assets" => {"asset_url_format" => "steam/apps/440/${FILENAME}?t=1"}}]}}
      end

      it "has a nil header url" do
        expect(items.map(&:header_image_url)).to eq([nil])
      end
    end
  end
end
