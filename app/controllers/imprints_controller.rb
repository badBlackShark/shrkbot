# frozen_string_literal: true

class ImprintsController < ApplicationController
  skip_before_action :require_login

  def show
    render Views::Imprint.new(user: current_user)
  end
end
