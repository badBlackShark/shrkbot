class PagesController < ApplicationController
  def home
    render Views::Home.new(user: current_user)
  end
end
