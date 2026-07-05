# frozen_string_literal: true

class TermsOfServicesController < ApplicationController
  skip_before_action :require_login

  def show
    render Views::TermsOfService.new
  end
end
