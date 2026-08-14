# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PreviewBanner do
  include_context "component view context"

  subject(:html) { described_class.new.render_in(view_context) }

  it "states that this is a preview and nothing is saved" do
    expect(html).to include(CGI.escapeHTML(I18n.t("components.preview_banner.message")))
  end

  it "offers the bot-invite call to action" do
    expect(html).to include(Bot::Config.invite_url).and include(I18n.t("components.preview_banner.invite"))
  end

  it "offers a way out that hits DELETE /preview" do
    expect(html).to include('action="/preview"')
    expect(html).to include('value="delete"')
    expect(html).to include(I18n.t("components.preview_banner.leave"))
  end
end
