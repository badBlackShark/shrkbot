# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::LookupTextField do
  include_context "component view context"

  subject(:input) { Nokogiri::HTML.fragment(described_class.new(name: :app, value: "1145", error_id:, server_configuration: nil).render_in(view_context)).at_css("input") }

  let(:error_id) { nil }

  it "is a text input named for the source's lookup param, holding the typed value" do
    expect(input.attributes.transform_values(&:value)).to include("type" => "text", "name" => "app", "value" => "1145", "aria-invalid" => "false")
    expect(input["aria-describedby"]).to be_nil
  end

  context "with a problem to describe" do
    let(:error_id) { "feed-lookup-error" }

    it "marks itself invalid and points at the message" do
      expect(input["aria-invalid"]).to eq("true")
      expect(input["aria-describedby"]).to eq("feed-lookup-error")
    end
  end
end
