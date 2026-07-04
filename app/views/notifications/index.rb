# frozen_string_literal: true

class Views::Notifications::Index < Views::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(authorized:, server_id: nil)
    @authorized = authorized
    @server_id = server_id
  end

  def view_template
    turbo_frame_tag("notifications") do
      render Components::NotificationBell.new(authorized: @authorized, server_id: @server_id)
    end
  end
end
