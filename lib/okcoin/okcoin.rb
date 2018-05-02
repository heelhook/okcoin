require 'rest-client'
require 'json'
require 'base64'
require 'byebug'

module Okcoin
  class API
    attr_reader :key,
                :secret,
                :url

    def initialize(key:, secret:, url: 'https://www.okcoin.com/api/v1')
      @key = key
      @secret = secret
      @url = url
    end

    def user_info
      post('/userinfo.do')
    end

    def order(id, pair)
      post('/order_info.do', {
        symbol: pair,
        order_id: id,
      })
    end

    def create_order(side:, size:, price:, pair:)
      opts = {
        symbol: pair,
        type: side,
        price: price,
        amount: size,
      }
      order = post('/trade.do', opts)

      order
    rescue => e
      raise Okcoin::CreateOrderException.new(e.message)
    end

    def cancel_order(id, pair)
      status = post('/cancel_order.do', {
        symbol: pair,
        order_id: id
      })

      status
    rescue => e
      raise Okcoin::CancelOrderException.new(e.message)
    end

    def order_fee(id, pair)
      post('/order_fee.do', {
        order_id: id,
        symbol: pair,
      })
    end

    def withdrawal_info
      post('/withdraw_info.do')
    end

    private

    def signature(params)
      params_string = params.sort.collect{|k, v| "#{k}=#{v}"} * '&'
      params_string = params_string + "&secret_key=#{@secret}"
      Digest::MD5.hexdigest(params_string).upcase
    end

    def get(path, opts = {})
      uri = URI.parse("#{@url}#{path}")
      uri.query = URI.encode_www_form(opts[:params]) if opts[:params]

      response = RestClient.get(uri.to_s, headers)

      if !opts[:skip_json]
        JSON.parse(response.body)
      else
        response.body
      end
    end

    def post(path, opts = {})
      opts[:api_key] = @key
      opts[:sign] = signature(opts)
      response = RestClient.post("#{@url}#{path}", opts, headers)
      res = JSON.parse(response.body)

      if res['error_code']
        message = case res['error_code'].to_i
        when 1002 then 'The transaction amount is greater than the balance'
        when 1003 then 'The transaction amount is less than the minimum transaction value'
        when 1004 then 'The transaction amount is less than 0'
        when 1007 then 'No trading market information'
        when 1027 then 'Invalid parameter may exceed limit'
        else
          "Unknown error #{res['error_code']}"
        end

        raise Okcoin::Exception, message
      end

      res
    end

    def headers
      {
        'Content-Type' => 'application/x-www-form-urlencoded',
      }
    end
  end
end
