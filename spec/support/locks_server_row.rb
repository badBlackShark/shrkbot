# frozen_string_literal: true

RSpec.shared_examples "an operation that locks the server row first" do |guarded_statement|
  it "takes the row lock before #{guarded_statement.inspect} runs, so concurrent changes to one server queue up" do
    statements = []
    collector = ->(*, payload) { statements << payload[:sql] }
    ActiveSupport::Notifications.subscribed(collector, "sql.active_record") { result }

    lock = statements.index { |sql| sql.match?(/FROM "server_configurations".*FOR NO KEY UPDATE/m) }
    guarded = statements.index { |sql| sql.match?(guarded_statement) }

    expect(lock).to be < guarded
  end
end
