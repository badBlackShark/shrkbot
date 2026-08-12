# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::CopyableTokens do
  subject(:html) { described_class.new.render_in(view_context) { "chips" } }

  let(:view_context) { ApplicationController.new.view_context }

  it "mounts the clipboard controller and yields the block" do
    expect(html).to include('data-controller="clipboard"').and include("chips")
  end

  it "hands the confirmation labels to the controller" do
    expect(html).to include('data-clipboard-copied-label-value="Copied!"')
    expect(html).to include('data-clipboard-failed-label-value="Copy failed"')
  end

  it "carries a live region so the copy is announced to screen readers" do
    expect(html).to include('role="status"').and include('data-clipboard-target="announcer"')
  end
end
