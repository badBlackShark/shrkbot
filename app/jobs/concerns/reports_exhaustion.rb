# frozen_string_literal: true

module ReportsExhaustion
  extend ActiveSupport::Concern

  ATTEMPTS = 5

  included do
    retry_on StandardError, wait: :polynomially_longer, attempts: ATTEMPTS do |job, error|
      ReportExhaustedJob.perform_later("#{job.class.name} #{job.job_id}: #{error.class}: #{error.message}")
      raise error
    end
  end
end
