Redmine::Plugin.register :redmine_budget_and_reporting do
  name 'Redmine Budget And Reporting plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  
  
  # TODO: add permission and menu bar
  permission :budget_permission, {:budget => [:index]}, :public => true
  permission :reporting_permission, {:reporting => [:index]}, :public => true
  menu :project_menu, :budget, {:controller => 'budget', :action => 'index'},
    :caption => 'Budget', :param => :project_id
  
  #require_dependency 'gantchart_spenthours/hooks'
  require_dependency 'sidebar/hooks'
  
  require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
   
	if Rails::VERSION::MAJOR >= 3
		ActionDispatch::Callbacks.to_prepare do
			# use require_dependency if you plan to utilize development mode
			require 'patches/GanttchartPatch'
		end
	else
		Dispatcher.to_prepare BW_AssetHelpers::PLUGIN_NAME do
			# use require_dependency if you plan to utilize development mode
			require 'patches/GanttchartPatch'
		end
	end
  
end
