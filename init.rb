Redmine::Plugin.register :redmine_budget_and_reporting do
  name 'Redmine Budget And Reporting plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  

    # only create field if CustumField table already exists
    if ActiveRecord::Base.connection.table_exists? 'custom_fields'   
        # make sure UserCustomField for salary exists
        if UserCustomField.where(:name => "Stundenlohn").empty?
            UserCustomField.create({:type => "UserCustomField", :name => "Stundenlohn", :field_format => "float",
        :default_value => "50", :is_required => true, :editable => true, :visible => false})
        end

        # make sure ProjectCustomField for comment exists
        if ProjectCustomField.where(:name => "Bemerkung Projektreporting").empty?
            ProjectCustomField.create({:type => "ProjectCustomField", :name => "Bemerkung Projektreporting", :field_format => "text",
                                   :visible => true, :editable => true})
        end

	if VersionCustomField.where(:name => "Abgeschlossen").empty?
		VersionCustomField.create({:type => "VersionCustomField", :name => "Abgeschlossen", :field_format =>"date",
			:is_required => false, :is_filter => true, :editable => true, :visible => true})
	end
    end
  
  project_module :reporting do
    permission :reporting, {:reporting => :index}, :public => true
    permission :edit_forecasts, {:forecast => [:new_versiondate_forecast, :delete_versiondate_forecast,
                                               :new_budget_forecast, :delete_budget_forecast,
                                               :new_budget_plan, :delete_budget_plan ],
                                 :reporting => [:choose_gan_file, :upload_gan_file]}
    permission :upload_cost_file, {:budget => [:choose_individual_file, :parse_individual_file]}
  end
  
  menu :project_menu, :reporting, {:controller => 'reporting', :action => 'index'},
    :caption => 'Reporting', :param => :project_id
  
  require_dependency 'gantchart_spenthours/hooks'
  require_dependency 'sidebar/hooks'
  
  require 'nokogiri'
  require 'axlsx_rails'
  require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
  
	if Rails::VERSION::MAJOR >= 3
		ActionDispatch::Callbacks.to_prepare do
			# use require_dependency if you plan to utilize development mode
			require 'patches/GanttchartPatch'
            require 'patches/ProjectInclude'
		end
	else
		Dispatcher.to_prepare BW_AssetHelpers::PLUGIN_NAME do
			# use require_dependency if you plan to utilize development mode
			require 'patches/GanttchartPatch'
      		require 'patches/ProjectInclude'
		end
	end
  
end
