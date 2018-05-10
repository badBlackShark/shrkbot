# Chart of games being played on a server
class GameChart < Chart
  def initialize(games, server_name)
    super(Gruff::SideStackedBar.new('1300x1000'))

    generate_data(games)
    settings(games, server_name)
  end

  def generate_data(games)
    games.sort.each_with_index do |(game, count), i|
      count_array = Array.new(i, 0)
      count_array.push(count)
      game = game.length > 30 ? game[0, game.rindex(/\s/, 30)].rstrip << '...' : game
      @chart.data(game.to_sym, count_array, '#06AAF5')
      @chart.labels[i] = game unless @chart.labels.include?(game)
    end
  end

  def save(id)
    @chart.write("images/#{id}.png")
  end

  private

  # Standard settings for a game chart.
  def settings(games, server_name)
    @chart.title = "Games currently being played on #{server_name}."
    @chart.title_font_size = 20
    @chart.x_axis_label = '# of Members Currently Playing'
    @chart.label_font_size = [[@chart.rows / games.keys.length / 5, 12].max, 24].min
    @chart.hide_legend = true
  end
end
