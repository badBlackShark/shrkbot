# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sentry configuration" do
  let(:configuration) { Sentry.configuration }

  describe "what a report may carry" do
    subject(:collected) do
      {
        user_info: collection.user_info,
        cookies: collection.cookies.mode,
        http_bodies: collection.http_bodies,
        url_query_params: collection.url_query_params.mode,
        database_query_data: collection.database_query_data,
        queues: collection.queues,
        stack_frame_variables: collection.stack_frame_variables.mode
      }
    end

    let(:collection) { configuration.data_collection }

    it "leaves out identity, cookies, bodies, query strings, bound query values, job arguments and local variables, as the privacy policy promises" do
      expect(collected).to eq(
        user_info: false,
        cookies: :off,
        http_bodies: [],
        url_query_params: :off,
        database_query_data: false,
        queues: false,
        stack_frame_variables: :off
      )
    end
  end

  describe "request headers" do
    subject(:headers) do
      Sentry::RequestInterface.new(
        env:,
        data_collection: configuration.data_collection,
        rack_env_whitelist: configuration.rack_env_whitelist
      ).headers
    end

    let(:env) { Rack::MockRequest.env_for("/servers", "HTTP_REFERER" => "https://shrkbot.com/servers?guild=1") }

    it "filter the referer, which carries the previous page's query string" do
      expect(headers).to include("Referer" => "[Filtered]")
    end
  end

  describe "breadcrumbs" do
    subject(:loggers) { configuration.breadcrumbs_logger }

    it "skip outgoing requests, because Discord interaction tokens sit in their path" do
      expect(loggers).not_to include(:http_logger)
    end
  end

  describe "sending" do
    subject(:environments) { configuration.enabled_environments }

    it "never happens from the test suite, which loads the same .env as development" do
      expect(environments).not_to include("test")
    end
  end

  describe "cron monitoring" do
    subject(:monitored) { task_keys.reject { |key| excluded.any? { |pattern| pattern === key } } }

    let(:task_keys) { YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production").keys }
    let(:excluded) { configuration.rails.solid_queue_exclude_recurring_tasks }

    it "watches exactly one recurring task, because the plan has one monitor seat" do
      expect(monitored).to eq(["integrations_stranded_event_dispatch"])
    end

    it "checks in from production only, so a stopped development box never alerts" do
      expect(configuration.enabled_patches).not_to include(:solid_queue_recurring)
    end
  end
end
