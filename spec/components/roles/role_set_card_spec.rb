# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Roles::RoleSetCard do
  let(:view_context) { ApplicationController.new.view_context }

  let(:context) do
    Components::Roles::RoleFormContext.new(
      channels: [],
      role_options: [],
      channels_by_id: {},
      default_channel_id: nil,
      any_unassignable: false
    )
  end

  context "when repost_path is given" do
    let(:card_data) do
      Components::Roles::RoleSetCardData.new(
        index: 0,
        set_id: nil,
        name: "",
        selection_mode: "single",
        channel_override: nil,
        selected_role_ids: [],
        open: false,
        repost_path: "/servers/123/role_sets/456/repost"
      )
    end

    subject(:html) { described_class.new(data: card_data, context:).render_in(view_context) }

    it "renders a button with data-action role-sets#repost" do
      expect(html).to include('data-action="role-sets#repost"')
    end

    it "sets data-repost-url to the given path" do
      expect(html).to include('data-repost-url="/servers/123/role_sets/456/repost"')
    end

    it "wraps the button in a tooltip" do
      expect(html).to include('role="tooltip"')
    end

    it "does not render a title attribute on the repost button" do
      expect(html).not_to include("title=")
    end

    it "does not render a turbo-method link" do
      expect(html).not_to include("data-turbo-method")
    end
  end

  context "when repost_path is nil (default)" do
    let(:card_data) { Components::Roles::RoleSetCardData.empty }

    subject(:html) { described_class.new(data: card_data, context:).render_in(view_context) }

    it "omits the repost button" do
      expect(html).not_to include('data-action="role-sets#repost"')
    end
  end
end
