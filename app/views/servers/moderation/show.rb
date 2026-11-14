# frozen_string_literal: true

class Views::Servers::Moderation::Show < Views::Servers::GroupShow
  def initialize(server_configuration:, user:, context:)
    super(server_configuration:, user:)
    @context = context
  end

  private

  def plugin_key
    :moderation
  end

  def body
    logging_subline
    render Components::Moderation::OverviewForm.new(
      server_configuration: @config,
      context: @context
    )
  end

  def logging_subline
    return unless @context.logging_ready? && @context.logging_channel_name

    p(class: "mb-6 flex items-center gap-1.5 pl-16 text-xs text-text-muted") do
      render Components::Icon.new("scroll", class: "size-4")
      span do
        plain t(".logging_subline_prefix")
        code(class: "font-mono") { "##{@context.logging_channel_name}" }
        plain " "
        plain t(".logging_subline_suffix")
      end
    end
  end
end
