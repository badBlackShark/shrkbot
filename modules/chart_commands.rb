require_relative '../lib/charts/role_chart'
require_relative '../lib/charts/game_chart'

# Allows users to create charts with up-to-date data about the server the commands are called in.
module ChartCommands
  extend Discordrb::Commands::CommandContainer

  attrs = {
    description: 'Generates a chart showing the distribution of roles on the server.',
    usage: '.roleChart <min_members> || Selects 10 roles max, if <min_members> isn\'t specified.'
  }
  command :roleChart, attrs do |event, min_members|
    event.send_temporary_message('Creating and uploading your chart. Hold on...', 10)

    data = {}
    auto_calculate = min_members ? false : true
    min_members ||= 0

    event.server.roles.sort_by(&:position).each do |role|
      data[role] = role.members.count if role.members.count >= min_members.to_i
    end

    while data.keys.length > 10 && auto_calculate
      min_members += 1
      data = data.select { |_role, count| count >= min_members }
    end
    chart = RoleChart.new(data, event.server.name)
    send_chart(chart, event)
  end

  attrs = {
    description: 'Generates a chart of the games currently being played on the server.',
    usage: '.gameChart'
  }
  command :gameChart, attrs do |event|
    event.send_temporary_message('Creating and uploading your chart. Hold on...', 10)

    data = Hash.new(0)
    event.server.members.each do |member|
      data[member.game] += 1 if member.game
    end

    chart = GameChart.new(data, event.server.name)
    send_chart(chart, event)
  end

  private_class_method def self.send_chart(chart, event)
    chart.save(event.message.id)

    event.channel.send_file(File.open("images/#{event.message.id}.png"))
    File.delete("images/#{event.message.id}.png")
    nil
  end
end
