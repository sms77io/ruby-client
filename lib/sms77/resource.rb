# frozen_string_literal: true

require 'cgi'
require 'json'
require 'faraday'
require 'sms77/endpoint'

module Sms77
  class Resource
    attr_reader :api_key, :endpoint, :sent_with, :http_methods, :request_methods, :builder, :conn

    BASE_PATH = '/api/'

    def initialize(api_key, sent_with = 'ruby')
      raise 'missing api_key in config' if api_key.to_s.empty?
      raise 'missing sent_with in config' if sent_with.to_s.empty?

      @api_key = api_key
      @sent_with = sent_with
      @endpoint = self.class.get_endpoint
      @http_methods = self.class.get_http_methods
      @conn = Faraday.new("https://gateway.sms77.io#{BASE_PATH}")
    end

    protected

    def request(payload = {}, query = {})
      path = @endpoint
      http_method = @http_methods[caller_locations.first.label.to_sym]

      if :get == http_method
        query = payload

        payload = {}
      end

      query.each do |key, val|
        query.store(key, Sms77::Util::to_numbered_bool(val))
      end

      payload.each do |key, val|
        payload.store(key, Sms77::Util::to_numbered_bool(val))
      end

      unless query.empty?
        path = "#{path}?#{URI.encode_www_form(query)}"
      end

      headers = Hash[
        Faraday::Request::Authorization::KEY, "Bearer #{@api_key}",
        'sentWith', @sent_with
      ]

      res = @conn.run_request(http_method, path, payload, headers)

      puts JSON.pretty_generate(res.to_hash.merge({
                                                    :method => http_method,
                                                    :path => path,
                                                    :payload => payload,
                                                    :req_headers => headers,
                                                    :query => query,
                                                  }).compact) if ENV['SMS77_DEBUG']

      raise "Error requesting (#{self.class.name}) with code #{res.status}" unless 200 == res.status

      raise 'Unexpected response' unless res.is_a?(Faraday::Response)

      body = res.body

      if body.is_a?(String)
        begin
          body = JSON.parse(body, :symbolize_names => true)
        rescue StandardError
          # Ignored
        end
      end

      body.map! { |hash| hash.transform_keys(&:to_sym) } if body.is_a?(Array)

      body
    end

    class << self
      def get_http_methods
        @http_methods
      end

      def get_endpoint
        @endpoint
      end
    end
  end
end
