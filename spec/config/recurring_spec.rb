# frozen_string_literal: true

require "rails_helper"

RSpec.describe "config/recurring.yml" do
  let(:tasks) { YAML.load_file(Rails.root.join("config/recurring.yml")).values.flat_map(&:values) }

  it "names a job class that exists for every class-based task" do
    classes = tasks.filter_map { |task| task["class"] }

    expect(classes.map(&:constantize)).to all(be < ApplicationJob)
  end

  it "starts every command with a constant that exists" do
    receivers = tasks.filter_map { |task| task["command"]&.slice(/\A[A-Z][\w:]*/) }

    expect(receivers.map(&:safe_constantize)).to all(be_present)
  end
end
