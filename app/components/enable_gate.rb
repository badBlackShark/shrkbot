class Components::EnableGate < Components::Base
  def initialize(enabled:, message:)
    @enabled = enabled
    @message = message
  end

  def view_template(&block)
    div(class: "relative") do
      overlay
      div(
        data: {enable_gate_target: "content"},
        inert: (true unless @enabled),
        class: "transition-opacity #{"opacity-40" unless @enabled}"
      ) { yield }
    end
  end

  private

  def overlay
    div(
      data: {enable_gate_target: "overlay"},
      class: "absolute inset-0 z-10 flex items-center justify-center rounded-lg bg-ink-0/70 #{"hidden" if @enabled}"
    ) do
      span(class: "max-w-xs px-4 text-center text-sm font-medium text-ink-600") { @message }
    end
  end
end
