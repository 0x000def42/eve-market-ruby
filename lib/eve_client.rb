class EveClient
  def initialize
    @conn = Faraday::Connection.new(
        url: "https://esi.evetech.net",
        params: {
          datasource: "tranquility",
          language: "en"
        }
      ) do |builder|
        builder.request :json
        builder.response :json
      end
  end

  def self.instance
    @instance ||= self.new
  end

  def get(path, opt = nil)
    path = path.gsub("$1", opt.to_s) if opt
    @conn.get("/latest" + path).body
  end
end
