# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ServerRole::Destroy do
  subject(:result) { described_class.call(server_role:) }

  let!(:server_role) { create(:server_role) }

  it "removes the row" do
    expect { result }.to change(ServerRole, :count).by(-1)
  end

  it "returns a successful result" do
    expect(result).to be_success
  end
end
