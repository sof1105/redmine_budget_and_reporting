# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

scope "/projects/:project_id" do
  get "/budget" => "budget#index"
  get "/budget/individual_file" => "budget#choose_individual_file"
  post "/budget/upload" => "budget#parse_individual_file"
  get "/budget/individual/details" => "budget#show_individual_costs"
  
  get "/reporting" => "reporting#index"
  get "/reporting/gan_file" => "reporting#choose_gan_file"
  post "/reporting/upload" => "reporting#upload_gan_file"
  
  get "/forecast/version/:version_id/" => "forecast#show_versiondate_forecast"
end
