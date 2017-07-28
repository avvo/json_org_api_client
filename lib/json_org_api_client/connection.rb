require "net/http/persistent"
require "json"
require_relative "errors"

module JsonOrgApiClient
  class Connection

    DEFAULT_HEADERS = {"Accept" => "application/vnd.api+json"}
    Response = Struct.new(:env, :raw_body, :body)

    attr_reader :site, :http
    private :http

    def initialize(options = {})
      @site = URI(options[:site])
      @http = Net::HTTP::Persistent.new(name: "JsonOrgApiClient")
      #TODO other options
      yield(self) if block_given?
    end

    def run(request_method, path, params = {}, headers = {})
      uri = site.merge(path)
      request = make_request(request_method, uri, params, headers)
      response = http.request(uri, request)
      handle_status(response.code.to_i, response)
      handle_response(response)
    rescue Net::HTTP::Persistent::Error, SocketError
      raise Errors::ConnectionError, request
    end

    private

    def make_request(request_method, uri, params, headers)
      klass = Net::HTTP.const_get(request_method.capitalize)
      if klass::REQUEST_HAS_BODY
        request = klass.new(uri)
        request["Content-Type"], request.body = make_body(params)
      else
        uri.query = params.to_query if params && params.any?
        request = klass.new(uri)
      end
      DEFAULT_HEADERS.merge(headers).each {|k, v| request[k] = v}
      request
    end

    def make_body(params)
      ["application/vnd.api+json", params.to_json]
    end

    def parse(body)
      JSON.parse(body) unless body.nil? || body.strip.empty?
    end

    def response_type(response)
      type = response['Content-Type'].to_s
      type = type.split(';', 2).first if type.index(';')
      type
    end

    def process_response_type?(type)
      !!type.match(/\bjson$/)
    end

    def handle_status(code, response)
      case code
      when 200..399
      when 401
        raise Errors::NotAuthorized, response
      when 403
        raise Errors::AccessDenied, response
      when 404
        raise Errors::NotFound, response.uri.to_s
      when 409
        raise Errors::Conflict, response
      when 400..499
        # some other error
      when 500..599
        raise Errors::ServerError, response
      else
        raise Errors::UnexpectedStatus.new(code, response.uri.to_s)
      end
    end

    def handle_response(response)
      if process_response_type?(response_type(response))
        parsed_body = parse(response.body)
        if parsed_body.is_a?(Hash)
          code = parsed_body.fetch("meta", {}).fetch("status", 200).to_i
          handle_status(code, response)
        end
        Response.new({url: response.uri.to_s}, response.body, parsed_body)
      else
        Response.new({url: response.uri.to_s}, nil, response.body)
      end
    end

  end
end
