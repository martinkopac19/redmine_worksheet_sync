require 'net/http'
require 'json'
require 'uri'

module WorksheetSync
  # Tenký klient na Worksheet API (ws.previo.cz).
  # GDPR: mzdové polia sa okamžite zahadzujú, ďalej sa s nimi vôbec nepracuje.
  class Client
    API = 'https://ws.previo.cz/api'.freeze
    SALARY_KEYS = %w[salaryPrice salaryCurrency totalPrice].freeze

    def initialize(api_key)
      @api_key = api_key.to_s
    end

    def employees
      get('/employees').map { |e| { 'id' => e['id'], 'name' => e['name'] } }
    end

    def worksheets(employee_id, from, to)
      path = "/worksheets?employeeId=#{employee_id}&from=#{from}&to=#{to}"
      get(path).map { |r| r.reject { |k, _| SALARY_KEYS.include?(k) } }
    end

    private

    def get(path)
      uri = URI("#{API}#{path}")
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                            open_timeout: 10, read_timeout: 30) do |http|
        req = Net::HTTP::Get.new(uri)
        req['Authorization'] = "Bearer #{@api_key}"
        http.request(req)
      end
      unless res.is_a?(Net::HTTPSuccess)
        raise "Worksheet API #{path} -> HTTP #{res.code}"
      end
      JSON.parse(res.body)
    end
  end
end
