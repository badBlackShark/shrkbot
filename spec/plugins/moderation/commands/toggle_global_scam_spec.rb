# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ToggleGlobalScam do
  subject(:execute) { described_class.new(event).execute }

  let(:guild_id) { 111 }
  let!(:config) { create(:server_configuration, discord_id: guild_id) }

  let(:image_attachment) { double("att", content_type: "image/png", url: "https://cdn/x.png") }
  let(:attachments) { [image_attachment] }
  let(:target) { double("message", attachments:) }
  let(:server) { double("server", id: guild_id) }
  let(:event) do
    double(
      "event",
      target:,
      server:,
      defer: nil,
      edit_response: nil,
      respond: nil
    )
  end

  let(:client) { double("client") }

  before do
    allow(Moderation::ImageScanning::Ocr::Client).to receive(:new).and_return(client)
    allow(client).to receive(:phash).and_return("deadbeefdeadbeef")
    allow(Moderation::ImageScanning::ImageDownload).to receive(:call).and_return("bytes")
    allow(Ops::Moderation::Phashes::SetGlobalScam).to receive(:call)
  end

  context "when there is no target message" do
    let(:target) { nil }

    it "responds with the none message and never defers" do
      execute

      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
      expect(event).not_to have_received(:defer)
      expect(Ops::Moderation::Phashes::SetGlobalScam).not_to have_received(:call)
    end
  end

  context "when the message has no image attachments" do
    let(:attachments) { [] }

    it "responds with the none message and never defers" do
      execute

      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
      expect(event).not_to have_received(:defer)
      expect(Ops::Moderation::Phashes::SetGlobalScam).not_to have_received(:call)
    end
  end

  context "when the image has no phash record yet" do
    it "treats it as new and marks it global" do
      execute

      expect(Ops::Moderation::Phashes::SetGlobalScam).to have_received(:call).with(
        phash_hex: "deadbeefdeadbeef",
        global: true
      )
      expect(event).to have_received(:edit_response).with(
        content: I18n.t("moderation.image_scanning.global_scam.added", count: 1)
      )
    end
  end

  context "when the image is not yet marked global" do
    before do
      create(:phash, phash: "deadbeefdeadbeef", global_scam: false)
    end

    it "defers, marks as global, and reports the added copy" do
      execute

      expect(event).to have_received(:defer).with(ephemeral: true)
      expect(Ops::Moderation::Phashes::SetGlobalScam).to have_received(:call).with(
        phash_hex: "deadbeefdeadbeef",
        global: true
      )
      expect(event).to have_received(:edit_response).with(
        content: I18n.t("moderation.image_scanning.global_scam.added", count: 1)
      )
    end
  end

  context "when the image is already marked global" do
    before do
      create(:phash, phash: "deadbeefdeadbeef", global_scam: true)
    end

    it "defers, unmarks global, and reports the removed copy" do
      execute

      expect(event).to have_received(:defer).with(ephemeral: true)
      expect(Ops::Moderation::Phashes::SetGlobalScam).to have_received(:call).with(
        phash_hex: "deadbeefdeadbeef",
        global: false
      )
      expect(event).to have_received(:edit_response).with(
        content: I18n.t("moderation.image_scanning.global_scam.removed", count: 1)
      )
    end
  end

  context "when an attachment fails to phash" do
    before do
      allow(Moderation::ImageScanning::ImageDownload).to receive(:call).and_raise(Moderation::ImageScanning::Ocr::Error, "boom")
    end

    it "does not raise and skips the failed attachment" do
      expect { execute }.not_to raise_error

      expect(Ops::Moderation::Phashes::SetGlobalScam).not_to have_received(:call)
    end

    it "reports that nothing could be processed" do
      execute

      expect(event).to have_received(:edit_response).with(
        content: I18n.t("moderation.image_scanning.global_scam.failed")
      )
    end
  end
end
