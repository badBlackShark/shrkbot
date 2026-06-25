# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :require_login

  def home
    return redirect_to servers_path if current_user

    render Views::Home.new
  end
end
