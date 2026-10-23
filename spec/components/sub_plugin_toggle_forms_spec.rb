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

  it "posts each form to its sub-plugin path as a patch" do
    expect(forms.map { |form| form["action"] }).to eq(
      [
        PluginPaths.for(config, :spam_protection),
        PluginPaths.for(config, :image_scanning)
      ]
    )
    expect(forms.map { |form| form.at_css("input[name=_method]")["value"] }.uniq).to eq(["patch"])
  end
end
