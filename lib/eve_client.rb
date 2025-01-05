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

  def get(path, opt = nil, params: {})
    path = path.gsub("$1", opt.to_s) if opt
    paged_path = if params[:page]
       path + "?page=" + params[:page].to_s
    else
      path
    end
    response = @conn.get("/latest" + paged_path)
    if block_given?
      yield response
    end
    response.body
  rescue Faraday::ConnectionFailed
    retry
  end
end
