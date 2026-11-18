# frozen_string_literal: true

class Components::SaveErrorCallout < Components::Base
  def initialize(key:, message: nil)
    @key = key
    @message = message
  end

  def view_template
    div(id: "#{@key}-save-error", class: "empty:hidden") do
      render Components::Callout.new(variant: :danger, role: "alert") { @message } if @message.present?
    end
  end
end
