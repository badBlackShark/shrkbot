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

    expect(response.body).to include("Bespoke plugins</h1>")
    expect(response.body).to include("I can build it as a plugin that only your server gets.")
  end

  it "says custom work may carry a fee" do
    bespoke_plugins

    expect(response.body).to include("For bigger custom work I charge a small fee.")
  end

  it "links the example's site where the sentence names it" do
    bespoke_plugins

    expect(response.body).to match(%r{Posts game results from <a href="https://twilight-struggle.com"[^>]*>twilight-struggle.com</a> to Discord})
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
