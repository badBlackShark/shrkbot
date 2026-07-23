# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::PingableRoleCard do
  subject(:html) { described_class.new(data:, context:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:role_options) do
    [
      Components::TomSelect::Option.for(value: 222, label: "Member"),
      Components::TomSelect::Option.for(value: 333, label: "VIP")
    ]
  end
  let(:channels) { [Components::TomSelect::Option.for(value: 111, label: "lfg")] }
  let(:context) { Components::Lfg::PingableRoleFormContext.new(role_options:, channels:) }

  context "when the card has no role picked yet" do
    let(:data) { Components::Lfg::PingableRoleCardData.empty }

    it "shows the unpicked placeholder in the summary" do
      expect(html).to include("Choose a role")
    end
  end

  context "when the card has a role picked" do
    let(:data) do
      Components::Lfg::PingableRoleCardData.new(
        index: 0,
        role_id: 222,
        required_role_ids: [333],
        excluded_role_ids: [],
        allowed_channel_ids: [111],
        min_membership_days: 7,
        open: false
      )
    end

    it "shows the role name in the summary" do
      expect(html).to include(">Member<")
    end

    it "renders the role-to-ping select" do
      expect(html).to include("Role to ping")
    end

    it "renders the additional required and excluded role fields" do
      expect(html).to include("Additional required roles")
      expect(html).to include("Additional excluded roles")
    end

    it "renders the channel override field" do
      expect(html).to include("Channel override")
    end

    it "renders the min-membership override field with its value" do
      expect(html).to include("Minimum membership override")
      expect(html).to include('name="lfg[pingable_roles][0][min_membership_days]"')
      expect(html).to include('value="7"')
    end
  end
end
