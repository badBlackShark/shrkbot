# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Previews do
  describe "#url_for" do
    subject(:url) { described_class.new.url_for("shrkbot_dev") }

    let(:preview) { "https://static-cdn.jtvnw.net/previews-ttv/live_user_shrkbot_dev-1280x720.jpg" }

    before do
      allow(Integrations::Http).to receive(:head)
    end

    it "is the preview URL, checked with a HEAD that treats a redirect as not found" do
      expect(url).to eq(preview)
      expect(Integrations::Http).to have_received(:head).with(preview, status_errors: {302 => Integrations::NotFound})
    end

    context "when the preview redirects to the placeholder" do
      before do
        allow(Integrations::Http).to receive(:head).and_raise(Integrations::NotFound)
      end

      it "is nil" do
        expect(url).to be_nil
      end
    end

    context "when Twitch is unavailable" do
      before do
        allow(Integrations::Http).to receive(:head).and_raise(Integrations::Unavailable)
      end

      it "raises" do
        expect { url }.to raise_error(Integrations::Unavailable)
      end
    end
  end
end
