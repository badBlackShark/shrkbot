# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SiteFooter do
  include_context "component view context"

  subject(:html) { described_class.new.render_in(view_context) }

  it "links to the source repository" do
    expect(html).to include("href=\"#{ReleaseInfo::REPO_URL}\"")
    expect(html).to include("free and open source")
  end

  it "states where shrkbot is developed and hosted" do
    expect(html).to include("Germany 🇩🇪")
    expect(html).to include("hosted in Finland 🇫🇮")
  end

  it "renders the legal links" do
    expect(html).to include("Privacy policy")
    expect(html).to include("Imprint")
  end
end
