# Role distribution chart
class RoleChart < Chart
  def initialize(roles, server_name)
    chart_width = [[roles.keys.length * 100, 500].max, 1500].min
    super(Gruff::StackedBar.new("#{chart_width}x#{chart_width * 1.3}"))

    generate_data(roles)
    settings(roles, server_name)
  end

  def generate_data(roles)
    return if roles.keys.length.zero?

    roles.each_with_index do |(role, count), i|
      count_array = Array.new(i, 0)
      count_array.push(count)
      @chart.data(role.name.to_sym, count_array, "##{role.colour.hex.rjust(6, '0')}")
    end
  end

  private

  # Standard settings for a role chart.
  def settings(roles, server_name)
    @chart.title = "Role distribution for #{server_name}."
    @chart.title_font_size = 26
    @chart.legend_font_size = [[@chart.columns / roles.keys.length / 5, 12].max, 20].min
    @chart.y_axis_label = '# of Members with Role'
    @chart.y_axis_increment = calculate_scale(roles.values.max)
  end
end
