class PagesController < ApplicationController
  def home
    return redirect_to servers_path if current_user

    render Views::Home.new
  end
end
