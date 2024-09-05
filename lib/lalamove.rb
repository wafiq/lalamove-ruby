require "faraday"
require "json"
require "openssl"

module Lalamove
  class Client
    BASE_URLS = {
      sandbox: "https://rest.sandbox.lalamove.com",
      production: "https://rest.lalamove.com"
    }

    DRIVER_CHANGE_REASONS = %w[
      DRIVER_LATE
      DRIVER_ASKED_CHANGE
      DRIVER_UNRESPONSIVE
      DRIVER_RUDE
    ]

    def initialize(api_key, api_secret, market = "MY", environment = :production)
      @api_key = api_key
      @api_secret = api_secret
      @market = market
      @environment = environment
    end

    def cities
      endpoint = "/v3/cities"
      response = request(:get, endpoint)
      response = JSON.parse(response.body)
      response["data"]
    end

    def get_quotation(quotation_details)
      endpoint = "/v3/quotations"
      body = {
        data: quotation_details
      }.to_json
      response = request(:post, endpoint, body)
      response = JSON.parse(response.body)
      response["data"]
    end

    def create_order(order_details)
      endpoint = "/v3/orders"
      body = {
        data: order_details
      }.to_json
      response = request(:post, endpoint, body)
      response = JSON.parse(response.body)
      response["data"]
    end

    def get_order(order_id)
      endpoint = "/v3/orders/#{order_id}"
      response = request(:get, endpoint)
      response = JSON.parse(response.body)
      response["data"]
    end

    def get_driver_details(order_id, driver_id)
      endpoint = "/v3/orders/#{order_id}/drivers/#{driver_id}"
      response = request(:get, endpoint)
      response = JSON.parse(response.body)
      response["data"]
    end

    def add_priority_fee(order_id, priority_fee)
      endpoint = "/v3/orders/#{order_id}/priority-fee"
      body = {
        data: {
          priorityFee: priority_fee.to_s
        }
      }.to_json
      response = request(:post, endpoint, body)
      response = JSON.parse(response.body)
      response["data"]
    end

    def cancel_order(order_id)
      endpoint = "/v3/orders/#{order_id}"
      request(:delete, endpoint)
    end

    private

    def request(method, endpoint, body = nil)
      timestamp = current_timestamp.to_s
      signature = generate_signature(method, endpoint, body, timestamp)

      headers = {
        "Authorization" => "hmac #{@api_key}:#{timestamp}:#{signature}",
        "Content-Type" => "application/json",
        "Request-ID" => SecureRandom.uuid,
        "Market" => @market.upcase
      }

      connection = Faraday.new(url: base_url)
      response = connection.public_send(method, endpoint, body, headers)

      puts "Sending #{method.upcase} request to #{endpoint}"
      puts "Request headers: #{headers}"
      puts "Request body: #{body}" if body

      handle_response(response)
    end

    def handle_response(response)
      case response.status
      when 200..299
        puts "Response body: #{response.body}"

        response
      when 400..499
        raise ClientError.new(response.status, response.body)
      when 500..599
        raise ServerError.new(response.status, response.body)
      else
        raise UnexpectedError.new(response.status, response.body)
      end
    end

    def base_url
      BASE_URLS[@environment]
    end

    def current_timestamp
      (Time.now.to_f * 1000).to_i
    end

    def generate_signature(method, endpoint, body, timestamp)
      raw_signature = "#{timestamp}\r\n#{method.upcase}\r\n#{endpoint}\r\n\r\n#{body}"
      OpenSSL::HMAC.hexdigest("SHA256", @api_secret, raw_signature)
    end
  end

  class ClientError < StandardError
    def initialize(status, body)
      super("Client Error: #{status} - #{body}")
    end
  end

  class ServerError < StandardError
    def initialize(status, body)
      super("Server Error: #{status} - #{body}")
    end
  end

  class UnexpectedError < StandardError
    def initialize(status, body)
      super("Unexpected Error: #{status} - #{body}")
    end
  end
end
