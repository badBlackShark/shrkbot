# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ImageScanning::Signals do
  subject(:signals) { described_class.call(author:, content:, server_id:) }

  let(:server_id) { 100 }
  let(:everyone_role) { double(id: 100) }
  let(:extra_role) { double(id: 200) }
  let(:roles) { [everyone_role] }
  let(:discord_id) { fresh_snowflake }
  let(:content) { "no links here" }
  let(:author) { double(id: discord_id, roles:) }

  def fresh_snowflake
    ((Time.current.to_f * 1000 - described_class::DISCORD_EPOCH_MS).to_i << 22)
  end

  describe "account_age_days" do
    context "with a freshly created account" do
      it "is approximately zero days old" do
        expect(signals[:account_age_days]).to be_within(0.01).of(0.0)
      end
    end

    context "with a very old snowflake" do
      let(:discord_id) { 4_194_304 }

      it "is a large positive number of days" do
        expect(signals[:account_age_days]).to be > 2000
      end
    end
  end

  describe "has_link" do
    context "with a link in the content" do
      let(:content) { "check https://x.com" }

      it "is true" do
        expect(signals[:has_link]).to be(true)
      end
    end

    context "without a link" do
      let(:content) { "no links here" }

      it "is false" do
        expect(signals[:has_link]).to be(false)
      end
    end
  end

  describe "has_role" do
    context "with only the @everyone role" do
      let(:roles) { [everyone_role] }

      it "is false" do
        expect(signals[:has_role]).to be(false)
      end
    end

    context "with an extra role" do
      let(:roles) { [everyone_role, extra_role] }

      it "is true" do
        expect(signals[:has_role]).to be(true)
      end
    end
  end
end
