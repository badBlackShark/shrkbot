require "http/client"
require "http/headers"
require "uri/params"
require "json"

class YahooFinance::Api
  API_HOST = "apidojo-yahoo-finance-v1.p.rapidapi.com"
  BASE_URL = "https://apidojo-yahoo-finance-v1.p.rapidapi.com"

  def initialize(@token : String)
  end

  def get_chart(symbol : String, interval : String = "5m", range : String = "1d")
    response = request("/stock/v2/get-chart?interval=#{interval}&symbol=#{symbol}&range=#{range}&region=US")
    return JSON.parse(response.body)
  end

  private def request(endpoint : String)
    headers = HTTP::Headers.new
    headers.add("x-rapidapi-key", @token)
    headers.add("x-rapidapi-host", API_HOST)
    return HTTP::Client.get(BASE_URL + endpoint, headers)
  end
end
