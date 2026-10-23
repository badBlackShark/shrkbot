# frozen_string_literal: true

require "rails_helper"

RSpec.describe "config/recurring.yml" do
  let(:environments) { YAML.load_file(Rails.root.join("config/recurring.yml")) }

  it "names a job class that exists for every class-based task in every environment" do
    classes = environments.values.flat_map { |tasks| tasks.values.filter_map { |task| task["class"] } }.uniq

    expect(classes).to include("Integrations::DispatchPollsJob")
    expect(classes.map(&:constantize)).to all(be < ApplicationJob)
  end
end
