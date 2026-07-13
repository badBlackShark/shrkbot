# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#social_meta_tags" do
    subject(:tags) { helper.social_meta_tags }

    it "emits Open Graph and Twitter card tags" do
      expect(tags).to include('property="og:type" content="website"')
      expect(tags).to include('property="og:site_name" content="shrkbot"')
      expect(tags).to include('name="twitter:card" content="summary_large_image"')
    end

    it "includes the request URL as og:url" do
      expect(tags).to include(%(property="og:url" content="#{helper.request.original_url}"))
    end

    context "without a page title or description" do
      it "falls back to the localized defaults" do
        expect(tags).to include(%(property="og:title" content="#{I18n.t("meta.default_title")}"))
        expect(tags).to include(%(property="og:description" content="#{I18n.t("meta.default_description")}"))
      end
    end

    context "with a page title and description set" do
      before do
        helper.content_for(:title, "Roles")
        helper.content_for(:page_description, "Manage self-assignable roles.")
      end

      it "uses them over the defaults" do
        expect(tags).to include('property="og:title" content="Roles"')
        expect(tags).to include('property="og:description" content="Manage self-assignable roles."')
      end
    end
  end
end
