# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

scope "/projects/:project_id" do
  get "/budget" => "budget#index"
  get "/budget/individual_file" => "budget#choose_individual_file"
  post "/budget/upload" => "budget#parse_individual_file"
  get "/budget/individual/details" => "budget#show_individual_costs"
  
  get "/reporting" => "reporting#index"
  get "/reporting/export/all_projects" => "reporting#export_excel_all_projects"
  get "/reporting/export/single_project" => "reporting#export_excel_single_project"
  get "/reporting/gan_file" => "reporting#choose_gan_file"
  post "/reporting/upload" => "reporting#upload_gan_file"
  
  get "/forecast/version/:version_id/" => "forecast#show_versiondate_forecast"
  get "/forecast/version/:forecast_id/delete" => "forecast#delete_versiondate_forecast"
  post "/forecast/version/:version_id/new" => "forecast#new_versiondate_forecast"
  
  get "/forecast/budget/" => "forecast#show_budget_forecast"
  get "/forecast/budget/:forecast_id/delete" => "forecast#delete_budget_forecast"
  post "/forecast/budget/new" => "forecast#new_budget_forecast"
  
  get "/plan/budget/plan" => "forecast#show_budget_plan"
  get "/plan/budget/:plan_id/delete" => "forecast#delete_budget_plan"
  post "/plan/budget/new" => "forecast#new_budget_plan"
end
