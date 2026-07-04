# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ServerAvatar do
  include_context "component view context"

  let(:server_with_icon) { double("server", name: "Alpha Server", icon_url: "https://cdn.example.com/abc.png") }
  let(:server_no_icon) { double("server", name: "Beta Server", icon_url: nil) }

  subject(:html) { described_class.new(server: server_with_icon, size: :md).render_in(view_context) }

  context "when the server has an icon_url" do
    it "renders an img tag with the icon src" do
      expect(html).to include("<img")
      expect(html).to include("https://cdn.example.com/abc.png")
    end

    it "applies the correct size and radius classes for :md" do
      expect(html).to include("size-8")
      expect(html).to include("rounded-md")
    end

    it "does not render an initials span" do
      expect(html).not_to include("<span")
    end
  end

  context "when the server has no icon_url" do
    subject(:html) { described_class.new(server: server_no_icon, size: :md).render_in(view_context) }

    it "renders an initials span" do
      expect(html).to include("<span")
      expect(html).to include("BS")
    end

    it "does not render an img tag" do
      expect(html).not_to include("<img")
    end
  end

  context "size variants" do
    it "applies xs size classes" do
      html = described_class.new(server: server_with_icon, size: :xs).render_in(view_context)
      expect(html).to include("size-5")
      expect(html).to include("rounded-[5px]")
    end

    it "applies sm size classes" do
      html = described_class.new(server: server_with_icon, size: :sm).render_in(view_context)
      expect(html).to include("size-7")
      expect(html).to include("rounded-md")
    end

    it "applies lg size classes for no-icon fallback" do
      html = described_class.new(server: server_no_icon, size: :lg).render_in(view_context)
      expect(html).to include("size-12")
      expect(html).to include("rounded-lg")
    end

    it "applies xl size classes for no-icon fallback" do
      html = described_class.new(server: server_no_icon, size: :xl).render_in(view_context)
      expect(html).to include("size-14")
      expect(html).to include("rounded-xl")
      expect(html).to include("text-xl")
    end
  end

  context "tone variants" do
    it "uses accent tone classes by default" do
      html = described_class.new(server: server_no_icon, size: :md).render_in(view_context)
      expect(html).to include("bg-accent-soft")
      expect(html).to include("text-accent-soft-fg")
      expect(html).to include("font-bold")
    end

    it "uses sunken tone classes when tone: :sunken" do
      html = described_class.new(server: server_no_icon, size: :md, tone: :sunken).render_in(view_context)
      expect(html).to include("bg-surface-sunken")
      expect(html).to include("text-text-secondary")
      expect(html).to include("font-semibold")
    end
  end

  context "dim: true" do
    it "adds opacity-60 to img when dim" do
      html = described_class.new(server: server_with_icon, size: :md, dim: true).render_in(view_context)
      expect(html).to include("opacity-60")
    end

    it "adds opacity-60 to initials span when dim" do
      html = described_class.new(server: server_no_icon, size: :md, dim: true).render_in(view_context)
      expect(html).to include("opacity-60")
    end

    it "does not add opacity-60 when dim is false" do
      html = described_class.new(server: server_with_icon, size: :md, dim: false).render_in(view_context)
      expect(html).not_to include("opacity-60")
    end
  end
end
