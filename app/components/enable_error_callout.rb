# frozen_string_literal: true

class Components::EnableErrorCallout < Components::Base
  def initialize(key:, message: nil)
    @key = key
    @message = message
  end

  def view_template
    div(id: "#{@key}-enable-error", class: "empty:hidden") do
      render Components::Callout.new(variant: :danger) { @message } if @message.present?
    end
  end
end
