# frozen_string_literal: true

RSpec.configure do |config|
  config.before do |example|
    allow(Bot::Discord::OwnerUsername).to receive(:call).and_return(nil) unless example.metadata[:owner_lookup]
  end
end
