class Shrkbot::Donations
  include Discord::Plugin

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("donate")
    }
  )]
  def donate(payload, ctx)
    message = String.build do |str|
      str << "Thank you for considering to donate to the shrkbot project! For full transparency, "
      str << "these are the costs I have for simply running shrkbot at the moment:\n"
      str << "• Hosting on DigitalOcean: $11.90 / month\n"
      str << "• Subscription to the Yahoo Finance API: $10.00 / month\n\n"
      str << "These prices are after tax. So the total cost of keeping shrkbot running as is is currently $21.90 per month.\n"
      str << "Obviously I would like to keep expanding the project, adding in features as requested and making current ones better. "
      str << "For this to happen, any support is greatly appreciated!\n\n"
      str << "Just to be clear, shrkbot is and always will be fully free and open source! You do not have to feel obligated "
      str << "to donate in any way! Simply using shrkbot is great :) Please also make sure you only donate with money "
      str << "that you absolutely don't need otherwise!\n\n"
      str << "Thank you for using shrkbot! Here's the link to send me some money, if you so choose: https://paypal.me/trueblackshark\n"
      str << "You can also support me via Liberapay, if you prefer that: https://liberapay.com/badBlackShark\n"
      str << "Please do note that all donation are non-refundable. Thank you for the support! <3"
    end

    client.create_message(payload.channel_id, message)
    client.create_reaction(payload.channel_id, payload.id, "❤️")
  end
end
