# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::Ocr::Client do
  subject(:client) { described_class.new }

  let(:response) { double(code: "200", body: response_body) }
  let(:response_body) { {"phash" => "0123456789abcdef"}.to_json }
  let(:http) { double }

  before do
    allow(ENV).to receive(:fetch).with("OCR_URL").and_return("http://ocr:8000")
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
    allow(http).to receive(:request).and_return(response)
  end

  describe "#phash" do
    it "returns the hex string from the parsed body" do
      expect(client.phash("bytes")).to eq("0123456789abcdef")
    end
  end

  describe "#scan" do
    let(:response_body) do
      {
        "text" => "hello",
        "mean_conf" => 0.9,
        "n_boxes" => 3,
        "phash" => "0123456789abcdef"
      }.to_json
    end

    it "returns the parsed hash" do
      expect(client.scan("bytes")).to eq(
        "text" => "hello",
        "mean_conf" => 0.9,
        "n_boxes" => 3,
        "phash" => "0123456789abcdef"
      )
    end
  end

  context "when the sidecar responds with a non-2xx status" do
    let(:response) { double(code: "500", body: "boom") }

    it "raises Moderation::ImageScanning::Ocr::Error" do
      expect { client.phash("bytes") }.to raise_error(Moderation::ImageScanning::Ocr::Error, /500/)
    end
  end

  context "when the request times out" do
    before do
      allow(http).to receive(:request).and_raise(Net::ReadTimeout)
    end

    it "raises Moderation::ImageScanning::Ocr::Error" do
      expect { client.phash("bytes") }.to raise_error(Moderation::ImageScanning::Ocr::Error)
    end
  end

  context "when the body is malformed JSON" do
    let(:response) { double(code: "200", body: "not json") }

    it "raises Moderation::ImageScanning::Ocr::Error" do
      expect { client.phash("bytes") }.to raise_error(Moderation::ImageScanning::Ocr::Error)
    end
  end
end
