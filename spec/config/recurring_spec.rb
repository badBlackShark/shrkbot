# frozen_string_literal: true

require "rails_helper"

RSpec.describe "config/recurring.yml" do
  subject(:tasks) { YAML.load_file(Rails.root.join("config/recurring.yml")).values.flat_map(&:values) }

  let(:job_classes) { tasks.filter_map { |task| task["class"] }.map(&:constantize) }
  let(:command_receivers) { tasks.filter_map { |task| task["command"]&.slice(/\A[A-Z][\w:]*/) }.map(&:safe_constantize) }

  it "names a job class that exists for every class-based task" do
    expect(job_classes).to all(be < ApplicationJob)
  end

  it "starts every command with a constant that exists" do
    expect(command_receivers).to all(be_present)
  end
end
