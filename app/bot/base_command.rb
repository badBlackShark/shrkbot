class BaseCommand
  include WithConnection

  Registration = Struct.new(:name, :description, :permissions, :owner_only, :context, :options_block) do
    def global?
      context == :global
    end

    def contexts
      global? ? %i[server bot_dm] : nil
    end
  end

  class << self
    def command_name(value = nil)
      @command_name = value if value
      @command_name
    end

    def description(value = nil)
      @description = value if value
      @description
    end

    def requires_permissions(*perms)
      @required_permissions = perms.flatten if perms.any?
      @required_permissions || []
    end

    def owner_only(value = true)
      @owner_only = value
    end

    def owner_only?
      @owner_only || false
    end

    def register_in(value = nil)
      @register_in = value if value
      @register_in || :guild
    end

    def options(&block)
      @options_block = block if block
      @options_block
    end

    def registration
      Registration.new(
        name: command_name,
        description: description,
        permissions: requires_permissions,
        owner_only: owner_only?,
        context: register_in,
        options_block: options
      )
    end

    def dispatch(event)
      new(event).call
    end

    def autocomplete?
      method_defined?(:autocomplete)
    end

    def dispatch_autocomplete(event)
      new(event).run_autocomplete
    end

    def registrable
      command_name.present?
    end
  end

  def initialize(event)
    @event = event
  end

  attr_reader :event

  def call
    with_connection do
      return reject_unauthorized unless permitted?

      execute
    end
  rescue => e
    Rails.logger.error("[#{self.class.command_name}] #{e.class}: #{e.message}")
    OwnerNotifier.report(bot: event.bot, error: e, source: "command /#{self.class.command_name}")
    respond_error
  end

  def execute
    raise AbstractMethodError, "#{self.class} must implement #execute"
  end

  def run_autocomplete
    with_connection { autocomplete }
  rescue => e
    Rails.logger.error("[#{self.class.command_name}] autocomplete #{e.class}: #{e.message}")
    begin
      event.respond(choices: [])
    rescue
      nil
    end
  end

  private

  def permitted?
    CommandPermissions.permitted?(
      event: event,
      required: self.class.requires_permissions,
      owner_only: self.class.owner_only?
    )
  end

  def reject_unauthorized
    event.respond(content: "🚫 You don't have permission to use this command.", ephemeral: true)
  end

  def respond_error
    event.respond(content: "⚠️ Something went wrong running that command.", ephemeral: true)
  rescue
    nil
  end
end
