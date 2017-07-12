module JsonOrgApiClient
  module Middleware
    autoload :JsonRequest, 'json_org_api_client/middleware/json_request'
    autoload :ParseJson, 'json_org_api_client/middleware/parse_json'
    autoload :Status, 'json_org_api_client/middleware/status'
  end
end