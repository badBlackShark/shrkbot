# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bespoke plugins page", type: :request do
  subject(:bespoke_plugins) { get bespoke_plugins_path }

  it "responds ok while signed out" do
    bespoke_plugins

    expect(response).to have_http_status(:ok)
  end

  it "leads with the bespoke-plugin pitch" do
    bespoke_plugins

    expect(response.body).to include("Some things only make sense for one server.")
  end

  it "names the fee up front" do
    bespoke_plugins

    expect(response.body).to include("name a small fee before anything gets written")
  end

  it "offers both contact routes" do
    bespoke_plugins

    expect(response.body).to include("mailto:info@shrkbot.com")
    expect(response.body).to include("https://discord.gg/3gwFMTY")
  end

  it "links the page from the public top bar" do
    get root_path

    expect(response.body).to include('href="/bespoke-plugins"')
  end
end
