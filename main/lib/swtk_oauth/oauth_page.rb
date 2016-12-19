module SwtkOauth
  module Page # page begin
    module_function

    API = {
      :get_access_token => {
        :method => "POST",
        :path => "/api/v1/oauth_page/get_access_token"
      },
      :verify_access_token => {
        :method => "POST",
        :path => "/api/v1/oauth_page/verify_access_token"
      }
    }

    

  end # page end
end