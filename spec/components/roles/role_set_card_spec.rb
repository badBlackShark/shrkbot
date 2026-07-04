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

    it "renders the resync link with data-turbo-method=post" do
      expect(html).to include('data-turbo-method="post"')
    end

    it "links to the repost path" do
      expect(html).to include('href="/servers/123/role_sets/456/repost"')
    end
  end

  context "when repost_path is nil (default)" do
    subject(:html) { described_class.new(**base_attrs).render_in(view_context) }

    it "omits the resync link" do
      expect(html).not_to include('data-turbo-method="post"')
    end
  end
end
