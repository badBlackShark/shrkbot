require 'gruff'

# Standard chart class
class Chart
  attr_reader :chart

  def initialize(chart)
    @chart = chart
    @chart.theme = { background_colors: %w[#95a5a6 #979c9f] }
  end

  # Round to the next reasonable value.
  def calculate_scale(max_value)
    max_value % 100 >= 50 ? max_value.round(-2) / 5 : [max_value.round(-1) / 5, 1].max
  end

  def save(id)
    @chart.write("images/#{id}.png")
  end
end
