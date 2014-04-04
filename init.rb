Redmine::Plugin.register :redmine_budget_and_reporting do
  name 'Redmine Budget And Reporting plugin'
  author 'Moritz Hamann'
  description 'Reports and Costs statistics'
  version '0.0.3'  

    # only create field if CustumField table already exists
    if ActiveRecord::Base.connection.table_exists? 'custom_fields'   
        
        # make sure UserCustomField for salary exists
        if UserCustomField.where(:name => "Stundenlohn").empty?
          UserCustomField.create({:type => "UserCustomField", :name => "Stundenlohn", :field_format => "float",
                                    :default_value => "50", :is_required => true, :editable => false, :visible => false})
        end

        # add date field for finished projects
        if VersionCustomField.where(:name => "Abgeschlossen").empty?
          VersionCustomField.create({:type => "VersionCustomField", :name => "Abgeschlossen", :field_format =>"date",
			             :is_required => false, :is_filter => true, :editable => true, :visible => true})
	end

        # add Projectcategory list
        if ProjectCustomField.where(:name => "Projekttyp").empty?
          ProjectCustomField.create({:name => "Projekttyp", :field_format => "list", :possible_values => ["Allgemeines", "Drives", "Batterie"],
                                     :is_required => true, :is_filter => true, :searchable => true, :default_value => "Allgemeines",
                                     :editable => true, :visible => true, :multiple => false})
        end

        # add checkbox if Project should be exported
        if ProjectCustomField.where(:name => "Wird exportiert").empty?
          ProjectCustomField.create({:name => "Wird exportiert", :field_format => "bool", :is_required => true, :is_filter => true,
                                     :editable => true, :visible => true, :default_value => "1"})
        end

        # make sure ProjectCustomField for comment exists
        if ProjectCustomField.where(:name => "Bemerkung Projektreporting").empty?
          ProjectCustomField.create({:type => "ProjectCustomField", :name => "Bemerkung Projektreporting", :field_format => "text",
                                     :visible => true, :editable => true})
        end
    end
  
  project_module :reporting do
    permission :reporting, {:reporting => :index}, :public => true
    permission :edit_forecasts, {:forecast => [:new_versiondate_forecast, :delete_versiondate_forecast,
                                               :new_budget_forecast, :delete_budget_forecast,
                                               :new_budget_plan, :delete_budget_plan ],
                                 :reporting => [:choose_gan_file, :upload_gan_file]}
  end
  
  menu :project_menu, :reporting, {:controller => 'reporting', :action => 'index'},
       :caption => 'Reporting', :param => :project_id
  
  require_dependency 'gantchart_spenthours/hooks'
  require_dependency 'sidebar/hooks'
  
  require 'nokogiri'
  require 'axlsx_rails'
  require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
  require 'prawn'
  require 'prawn/measurement_extensions'
  
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
