# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Welcomes::ConfigForm do
  subject(:html) do
    described_class.new(server_configuration: config).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:config) { create(:server_configuration) }

  let(:settings_attributes) { {} }
  let(:default_join) { I18n.t("welcomes.default_message.join") }
  let(:default_leave) { I18n.t("welcomes.default_message.leave") }

  before do
    config.create_welcome_settings!(**settings_attributes)
  end

  it "renders the channel card with the required marker" do
    expect(html).to include("This setting is required to enable the plugin")
  end

  it "shows the none-message when no channels have synced" do
    expect(html).to include("No channels have synced yet")
  end

  it "nests the ping-on-join toggle in the join message card" do
    expect(card_containing("welcomes[join_message]")).to include('name="welcomes[ping_on_join]"')
  end

  it "nests the suppress-removal-messages toggle in the leave message card" do
    expect(card_containing("welcomes[leave_message]")).to include('name="welcomes[suppress_removal_messages]"')
  end

  it "renders every placeholder as a copy button" do
    described_class::PLACEHOLDERS.each do |name|
      expect(html).to include(%(data-clipboard-text-param="{#{name}}"))
    end
  end

  it "mounts the placeholder run on the clipboard controller with an announcer" do
    expect(html).to include('data-controller="clipboard"').and include('data-clipboard-target="announcer"')
  end

  it "heads the placeholders with the copy hint" do
    expect(html).to include("Placeholders (click to copy)")
  end

  describe "the messages" do
    let(:page) { Nokogiri::HTML5.fragment(html) }

    def textarea(kind)
      page.at_css("textarea[name='welcomes[#{kind}_message]']")
    end

    def reset(kind)
      page.at_css("[data-welcome-preview-target=#{kind}Reset]")
    end

    it "fills each box with its default text" do
      expect([textarea("join").text, textarea("leave").text]).to eq([default_join, default_leave])
    end

    it "hides both resets" do
      expect([reset("join").key?("hidden"), reset("leave").key?("hidden")]).to eq([true, true])
    end

    it "gives each reset its kind" do
      button = reset("join").at_css("button")

      expect(button["data-action"]).to eq("welcome-preview#reset")
      expect(button["data-welcome-preview-kind-param"]).to eq("join")
    end

    context "when the join message differs from its default" do
      let(:settings_attributes) { {join_message: "Hi {user}"} }

      it "shows the join reset only" do
        expect([reset("join").key?("hidden"), reset("leave").key?("hidden")]).to eq([false, true])
      end
    end

    context "when a message is empty" do
      let(:settings_attributes) { {join_message: nil} }

      it "says nothing will be sent in the box and the preview" do
        expect(textarea("join")["placeholder"]).to eq("Nothing will be sent.")
        expect(page.at_css("[data-welcome-preview-target=joinOutput]")["data-empty-hint"]).to eq("Nothing will be sent.")
      end

      it "shows the join reset" do
        expect(reset("join").key?("hidden")).to be(false)
      end
    end
  end

  def card_containing(field)
    Nokogiri::HTML.fragment(html)
      .css("div.rounded-card")
      .find { |card| card.css("[name]").any? { |node| node["name"] == field } }
      .to_html
  end
end
