# frozen_string_literal: true

require "rails_helper"

RSpec.describe Roles::Manage do
  subject(:handle) { described_class.new(event).handle }

  let(:user) { double("user", id: 42) }
  let(:member) { double("member", roles: [double("role", id: 200)]) }
  let(:server) { double("server") }
  let(:event) { double("event", custom_id: Roles::CustomId.manage(set), server:, user:) }

  before do
    allow(server).to receive(:member).with(42).and_return(member)
  end

  context "for a multi-selection set" do
    let(:set) { create(:role_set, selection_mode: "multi") }

    before do
      create(:assignable_role, role_set: set, role_id: 200, position: 0)
    end

    it "responds with an ephemeral, components-v2 string-select picker" do
      expect(event).to receive(:respond) do |args|
        expect(args[:ephemeral]).to be(true)
        expect(args[:has_components]).to be(true)
        container = args[:components].first
        select = container[:components].find { |block| block[:type] == Roles::Message::ACTION_ROW }[:components].first
        expect(select[:type]).to eq(Roles::Message::STRING_SELECT)
      end
      handle
    end
  end

  context "when the set no longer exists" do
    let(:event) { double("event", custom_id: "roles:manage:rst_gone", server:, user:) }
    let(:set) { nil }

    it "does nothing" do
      expect(event).not_to receive(:respond)
      handle
    end
  end
end
