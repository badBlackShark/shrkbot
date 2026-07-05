# frozen_string_literal: true

class PrivacyPoliciesController < ApplicationController
  skip_before_action :require_login

  def show
    render Views::PrivacyPolicy.new(user: current_user)
  end
end
