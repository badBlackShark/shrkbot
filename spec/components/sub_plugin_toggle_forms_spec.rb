# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SubPluginToggleForms do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }

  subject(:html) { described_class.new(server_configuration: config, parent: :moderation).render_in(view_context) }

  let(:forms) { Nokogiri::HTML.fragment(html).css("form") }

  it "renders one hidden form per sub-plugin" do
    expect(forms.map { |form| form["id"] }).to eq(
      %w[spam_protection-overview-toggle-form image_scanning-overview-toggle-form]
    )
    expect(forms.map { |form| form["class"] }.uniq).to eq(["hidden"])
  end

  it "posts each form to the plugin toggle endpoint as a patch" do
    expect(forms.map { |form| form["action"] }).to eq(
      [
        "/servers/900000001/plugins/spam_protection",
        "/servers/900000001/plugins/image_scanning"
      ]
    )
    expect(forms.map { |form| form.at_css("input[name=_method]")["value"] }.uniq).to eq(["patch"])
  end

  context "when the server configuration is a preview" do
    let(:config) { create(:server_configuration, :preview) }

    it "renders no forms" do
      expect(forms).to be_empty
    end
  end
end
