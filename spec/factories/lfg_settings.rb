# frozen_string_literal: true

FactoryBot.define do
  factory :lfg_settings, class: "Lfg::Settings" do
    association :server_configuration
  end
end
