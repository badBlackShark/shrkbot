# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SidebarGroup do
  include_context "component view context"

  subject(:html) do
    described_class.new(**options).render_in(view_context)
  end

  let(:items) do
    [
      {label: "Overview", href: "/servers/1/moderation", active: false, status: nil},
      {label: "Cross-Channel Spam Guard", href: "/servers/1/spam_protection", active: true, status: :enabled},
      {label: "Scam Image Detection", href: "/servers/1/image_scanning", active: false, status: :needs_setup}
    ]
  end

  let(:options) do
    {label: "Server Shield", icon: "shield", open: false, items:, storage_key: "sidebar-group-moderation"}
  end

  it "renders the group parent label" do
    expect(html).to include("Server Shield")
  end

  it "renders a chevron that rotates when the group is open" do
    expect(html).to include("group-open/details:rotate-90")
  end

  it "wires the disclosure controller with the storage key" do
    expect(html).to include('data-controller="disclosure"')
    expect(html).to include('data-disclosure-key-value="sidebar-group-moderation"')
  end

  it "renders sub-items as links with their hrefs" do
    expect(html).to include('href="/servers/1/moderation"')
    expect(html).to include('href="/servers/1/spam_protection"')
    expect(html).to include('href="/servers/1/image_scanning"')
  end

  it "marks the active sub-item with aria-current" do
    expect(html).to include('aria-current="page"')
    expect(html).to include("Cross-Channel Spam Guard")
  end

  it "applies the active wash class to the active sub-item link" do
    expect(html).to include("bg-accent-soft")
  end

  it "renders status dots for items that have a status" do
    expect(html).to include("bg-success")
    expect(html).to include("bg-warning")
  end

  it "does not render a status dot for the Overview item (status nil)" do
    overview_section = html[%r{href="/servers/1/moderation"[^>]*>.*?</a>}m, 0]
    expect(overview_section).not_to include("rounded-full") if overview_section
  end

  context "when open is true (active child)" do
    let(:options) { {label: "Server Shield", icon: "shield", open: true, items:, storage_key: "sidebar-group-moderation"} }

    it "renders the details element as open" do
      expect(html).to include("<details")
      expect(html).to include("open")
    end
  end

  context "when open is false" do
    it "renders the details element without the open attribute" do
      details_tag = html[/<details[^>]*>/, 0]
      expect(details_tag).not_to include(" open")
    end
  end

  describe "parent tile tinting" do
    let(:inactive_items) do
      items.map { |item| item.merge(active: false) }
    end

    context "when the group plugin is enabled" do
      let(:options) do
        {label: "Server Shield", icon: "shield", open: false, items: inactive_items, storage_key: "k", enabled: true}
      end

      it "renders the accent tile" do
        expect(html).to include("bg-accent-fill")
      end
    end

    context "when disabled with no active child" do
      let(:options) do
        {label: "Server Shield", icon: "shield", open: false, items: inactive_items, storage_key: "k"}
      end

      it "renders the muted tile" do
        expect(html).not_to include("bg-accent-fill")
      end
    end

    context "when disabled but a child page is active" do
      it "renders the accent tile" do
        expect(html).to include("bg-accent-fill")
      end
    end
  end
end
