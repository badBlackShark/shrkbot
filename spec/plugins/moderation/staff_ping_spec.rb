# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::StaffPing do
  subject(:prefix) { described_class.prefix(staff_role_id) }

  context "with a staff role id" do
    let(:staff_role_id) { 123 }

    it "renders a role mention with a colon and trailing space" do
      expect(prefix).to eq("<@&123>: ")
    end
  end
end
