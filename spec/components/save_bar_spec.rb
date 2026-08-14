# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::SaveBar do
  include_context "component view context"

  subject(:html) { described_class.new(preview:).render_in(view_context) }

  let(:preview) { false }

  context "when not previewing" do
    it "shows the unsaved-changes message" do
      expect(html).to include(I18n.t("components.save_bar.unsaved"))
    end

    it "leaves the save button enabled" do
      expect(html).not_to include("disabled")
    end
  end

  context "when previewing" do
    let(:preview) { true }

    it "shows the preview explanation instead of the unsaved-changes message" do
      expect(html).to include(CGI.escapeHTML(I18n.t("components.save_bar.preview_message")))
      expect(html).not_to include(I18n.t("components.save_bar.unsaved"))
    end

    it "disables the save button" do
      expect(html).to include("disabled")
    end

    it "keeps the discard button wired up" do
      expect(html).to include(%(data-action="save-bar#discard"))
    end
  end
end
