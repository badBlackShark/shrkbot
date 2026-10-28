# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::LanguageCard do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(subscription:, plugin_key: :steam).render_in(view_context)) }

  let(:subscription) { build(:feed_subscription, languages: %w[de ru]) }

  it "marks the subscription's languages as selected" do
    selected = document.css("select[name='subscription[languages][]'] option[selected]").map { |option| option["value"] }

    expect(selected).to match_array(%w[de ru])
  end

  it "labels the options with language names" do
    expect(document.at_css("option[value='de']").text).to eq("German")
  end

  it "submits a blank value so every language can be cleared" do
    expect(document.at_css("input[type=hidden][name='subscription[languages][]']")["value"]).to eq("")
  end
end
