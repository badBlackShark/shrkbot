# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::Plugins::Lock do
  subject(:statements) do
    [].tap do |collected|
      collector = ->(*, payload) { collected << payload[:sql] }
      ActiveSupport::Notifications.subscribed(collector, "sql.active_record") do
        described_class.call(server_configuration:)
      end
    end
  end

  let(:server_configuration) { create(:server_configuration) }

  it "locks only that server's row, in a mode that still admits foreign-key inserts" do
    expect(statements).to include(
      a_string_matching(/FROM "server_configurations" WHERE "server_configurations"."id" = .* FOR NO KEY UPDATE/)
    )
  end
end
