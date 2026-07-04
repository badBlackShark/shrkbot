# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Roles::RoleSetCard do
  let(:view_context) { ApplicationController.new.view_context }

  let(:base_attrs) do
    {
      index: 0,
      channels: [],
      role_options: [],
      channels_by_id: {},
      default_channel_id: nil,
      any_unassignable: false
    }
  end

  context "when repost_path is given" do
    subject(:html) { described_class.new(**base_attrs, repost_path: "/servers/123/role_sets/456/repost").render_in(view_context) }

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
    subject(:html) { described_class.new(**base_attrs).render_in(view_context) }

    it "omits the repost button" do
      expect(html).not_to include('data-action="role-sets#repost"')
    end
  end
end
