# Base for every slash command. One command per subclass; the registrar
# (CommandRegistrar) discovers subclasses via .descendants after eager-load.
#
# Subclasses declare metadata with the class macros and implement #execute.
# The #call template owns the cross-cutting concerns in ONE place: connection
# checkout, the runtime permission gate, and uniform error handling.
class BaseCommand
  include WithConnection

  # Plain descriptor the registrar turns into a discordrb registration call.
  # Pure data → testable without a gateway.
  Registration = Struct.new(
    :name, :description, :permissions, :owner_only, :context, :options_block
  ) do
    def global? = context == :global

    # :global commands work in servers AND bot DMs; :guild commands are
    # server-only by Discord's rules (guild commands can't appear in DMs).
    def contexts = global? ? %i[server bot_dm] : nil
  end

  class << self
    # --- declaration macros ---

    def command_name(value = nil)
      @command_name = value if value
      @command_name
    end

    def description(value = nil)
      @description = value if value
      @description
    end

    # Discord permission-flag symbols (e.g. :manage_server). Sets the command's
    # default_member_permissions (Discord hides it) and the runtime gate.
    def requires_permissions(*perms)
      @required_permissions = perms.flatten if perms.any?
      @required_permissions || []
    end

    def owner_only(value = true)
      @owner_only = value
    end

    def owner_only? = @owner_only || false

    # :guild (default) registers per-server; :global registers once, DM-capable.
    def register_in(value = nil)
      @register_in = value if value
      @register_in || :guild
    end

    # Option block passed to discordrb's OptionBuilder at registration time.
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

    # Registrar attaches this as the discordrb handler for the command.
    def dispatch(event)
      new(event).call
    end

    # Concrete commands only (skip abstract bases without a name).
    def registrable = command_name.present?
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
    respond_error
  end

  # Subclasses implement this.
  def execute = raise(NotImplementedError, "#{self.class} must implement #execute")

  private

  def permitted?
    CommandPermissions.permitted?(
      event: event,
      required: self.class.requires_permissions,
      owner_only: self.class.owner_only?,
      owner_id: BotConfig.owner_id
    )
  end

  def reject_unauthorized
    event.respond(content: "🚫 You don't have permission to use this command.", ephemeral: true)
  end

  def respond_error
    event.respond(content: "⚠️ Something went wrong running that command.", ephemeral: true)
  rescue
    nil # already responded / interaction expired — nothing to do
  end
end
