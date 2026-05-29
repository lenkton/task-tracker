module RequestAuth
  TEST_AUTH_TOKEN = "test-auth-token"

  def auth_headers(user = nil)
    user ||= User.find_by!(auth_token: TEST_AUTH_TOKEN)
    { "Authorization" => "Bearer #{user.auth_token}" }
  end

  %i[get post patch put delete head].each do |http_method|
    define_method(http_method) do |path, **args|
      args[:headers] = auth_headers.merge(args.fetch(:headers, {}))
      super(path, **args)
    end
  end
end

RSpec.configure do |config|
  config.include RequestAuth, type: :request
end
