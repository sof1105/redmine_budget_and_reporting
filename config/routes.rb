# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

scope "/projects/:project_id" do
  get "/budget" => "budget#index"
  get "/reporting" => "reporting#index"
end
