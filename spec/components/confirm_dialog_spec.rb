# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ConfirmDialog do
  include_context "component view context"

  subject(:html) { described_class.new.render_in(view_context) }

  let(:fragment) { Nokogiri::HTML5.fragment(html) }

  it "renders a native dialog with the id the script looks up" do
    expect(fragment.at_css("dialog#confirm-dialog")).not_to be_nil
  end

  it "wires the dialog to its title and body for screen readers" do
    dialog = fragment.at_css("dialog")

    expect(dialog["aria-labelledby"]).to eq("confirm-dialog-title")
    expect(dialog["aria-describedby"]).to eq("confirm-dialog-body")
    expect(fragment.at_css("#confirm-dialog-title")).not_to be_nil
    expect(fragment.at_css("#confirm-dialog-body")).not_to be_nil
  end

  it "carries the default copy for the script to fall back on" do
    dialog = fragment.at_css("dialog")

    expect(dialog["data-default-title"]).to eq("Confirm")
    expect(dialog["data-default-button"]).to eq("Confirm")
  end

  it "closes through a dialog form with cancel and confirm values" do
    expect(fragment.at_css("form[method=dialog]")).not_to be_nil
    expect(fragment.at_css("button[value=cancel][autofocus]").text).to eq("Cancel")
    expect(fragment.at_css("button#confirm-dialog-button[value=confirm]").text).to eq("Confirm")
  end
end
