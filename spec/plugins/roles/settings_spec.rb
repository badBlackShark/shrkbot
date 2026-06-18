require "rails_helper"

RSpec.describe Roles::Settings do
  describe "destroying the parent server configuration" do
    subject(:destroy_server) { server.destroy }

    let(:server) { create(:server_configuration) }
    let(:settings) { create(:role_setting, server_configuration: server) }
    let(:set) { create(:role_set, role_setting: settings) }

    before do
      create(:assignable_role, role_set: set)
    end

    it "cascades through sets to assignable roles" do
      expect { destroy_server }
        .to change(Roles::AssignableRole, :count).by(-1)
        .and change(Roles::Set, :count).by(-1)
        .and change(Roles::Settings, :count).by(-1)
    end
  end
end
