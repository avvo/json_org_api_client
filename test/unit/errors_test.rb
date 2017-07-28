require 'test_helper'

class ErrorsTest < MiniTest::Test

  def test_connection_errors
    stub_request(:get, "http://example.com/users")
      .to_raise(Errno::ECONNREFUSED)

    assert_raises JsonOrgApiClient::Errors::ConnectionError do
      User.all
    end
  end

  def test_timeout_errors
    stub_request(:get, "http://example.com/users")
      .to_timeout

    assert_raises JsonOrgApiClient::Errors::ConnectionError do
      User.all
    end
  end

  def test_500_errors
    stub_request(:get, "http://example.com/users")
      .to_return(headers: {content_type: "text/plain"}, status: 500, body: "something went wrong")

    assert_raises JsonOrgApiClient::Errors::ServerError do
      User.all
    end
  end

  def test_not_found
    stub_request(:get, "http://example.com/users")
      .to_return(status: 404, body: "something irrelevant")

    assert_raises JsonOrgApiClient::Errors::NotFound do
      User.all
    end
  end

  def test_conflict
    stub_request(:get, "http://example.com/users")
      .to_return(status: 409, body: "something irrelevant")

    assert_raises JsonOrgApiClient::Errors::Conflict do
      User.all
    end
  end

  def test_access_denied
    stub_request(:get, "http://example.com/users")
      .to_return(headers: {content_type: "text/plain"}, status: 403, body: "access denied")

    assert_raises JsonOrgApiClient::Errors::AccessDenied do
      User.all
    end
  end

  def test_not_authorized
    stub_request(:get, "http://example.com/users")
      .to_return(headers: {content_type: "text/plain"}, status: 401, body: "not authorized")

    assert_raises JsonOrgApiClient::Errors::NotAuthorized do
      User.all
    end
  end

  def test_errors_are_rescuable_by_default_rescue
    begin
      raise JsonOrgApiClient::Errors::ApiError, "Something bad happened"
    rescue => e
      assert e.is_a?(JsonOrgApiClient::Errors::ApiError)
    end
  end

  def test_unknown_response_code
    stub_request(:get, "http://example.com/users")
      .to_return(headers: {content_type: "text/plain"}, status: 699, body: "lol wut")

    assert_raises JsonOrgApiClient::Errors::UnexpectedStatus do
      User.all
    end

  end

end
