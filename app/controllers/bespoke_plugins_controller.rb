# frozen_string_literal: true

class BespokePluginsController < ApplicationController
  skip_before_action :require_login

  def show
    render Views::BespokePlugins.new(user: current_user)
  end
end
