# frozen_string_literal: true

class Views::Home < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(user:)
    @user = user
  end

  def view_template
    h1 { "shrkbot" }

    if @user
      p { "Signed in as #{@user.username}." }
      button_to("Sign out", logout_path, method: :delete)
    else
      p { "Sign in to configure shrkbot for your servers." }
      button_to("Sign in with Discord", "/auth/discord", method: :post, data: {turbo: false})
    end
  end
end
