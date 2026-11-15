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

  def prerequisites
    return if @context.logging_ready?

    Components::PrerequisiteSteps.new(
      title: t(".prerequisites_title"),
      steps: [::Moderation::SetupSteps.new(@config).logging]
    )
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
        plain t(".logging_subline_change")
        a(href: PluginPaths.for(@config, :logging), class: "underline transition-colors hover:text-text-primary") { t(".logging_subline_link") }
        plain "."
      end
    end
  end
end
