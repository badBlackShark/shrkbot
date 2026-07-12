# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::AttachmentDownload do
  subject(:download) { described_class.call("https://cdn/x.png") }

  let(:http) { double("http") }
  let(:response) { double("response", code: "200", body: "bytes") }

  before do
    allow(Net::HTTP).to receive(:start) { |*_args, &block| block.call(http) }
    allow(http).to receive(:get).and_return(response)
  end

  context "when the download succeeds" do
    it "returns the response body" do
      expect(download).to eq("bytes")
    end
  end

  context "when the download returns a non-success status" do
    let(:response) { double("response", code: "404", body: "") }

    it "raises an AttachmentDownload::Error" do
      expect { download }.to raise_error(Moderation::AttachmentDownload::Error, /404/)
    end
  end

  context "when the connection fails" do
    before do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError, "no dns")
    end

    it "raises an AttachmentDownload::Error" do
      expect { download }.to raise_error(Moderation::AttachmentDownload::Error, "no dns")
    end
  end
end
