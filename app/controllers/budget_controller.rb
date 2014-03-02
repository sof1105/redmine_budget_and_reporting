#encoding: utf-8

class BudgetController < ApplicationController
  unloadable
  
  include BudgetCalculating
  include PDFRender
  before_filter :set_project
  before_filter :own_authorize, :only => [:choose_individual_file, :parse_individual_file, :delete_individual_for_project]
  
  def index
    
    date = Date.today
    salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    
    # show actual budget for project
    @overall_costs = {}
    @costs_per_issue = {}
    @individual_costs = {}
  
    # the overall costs of the project ---------------------------------------------------
    @overall_costs[:planned] = PlannedBudget.latest_budget_for(@project.id)
    @overall_costs[:forecast] = ProjectbudgetForecast.until(date, @project.id).latest
    @overall_costs[:individual] = @project.costs_individual_items(date)
    @overall_costs[:issues] = @project.costs_issues(date)
    
    # costs per issue -------------------------------------------------------------------
    @costs_per_issue = @project.costs_issues_list(date)
    
    # individual costs ---------------------------------------------------------------------
    @individual_costs = @project.costs_individual_items_list(date)

    # render page or generate pdf
    if params[:pdf]=="1"
      send_data render_pdf(@project, @overall_costs, @costs_per_issue, @individual_costs[:category], @individual_costs[:other]), 
                          :filename => "Budgetbericht.pdf", :disposition => "attachment"
      return
    end
  end


  def show_individual_costs
    all_projects = @project.self_and_descendants.map{|p| p.id}
    @items = IndividualItem.where(:project_id => all_projects).order("booking_date ASC")
    render :partial => "show_individual_costs"
  end
  
  def delete_individual
    if params[:individual_id] && IndividualItem.exists?(params[:individual_id])
	  i = IndividualItem.find(params[:individual_id])
	  if not i.destroy
	    flash[:error] = "Konnte Eintrag nicht löschen"
	  end
    end
    @items = IndividualItem.where(:project_id => @project.id).order("booking_date ASC")
    render :partial => "show_individual_costs"
  end

  def delete_individual_for_project
    all_projects = @project.self_and_descendants.map{|p| p.id}
    IndividualItem.destroy_all(:project_id => all_projects)
    redirect_to :action => "index"
  end

  def delete_individual_all(redirect = true)
    IndividualItem.destroy_all
    # reset auto increment counter (ugly but neccessary)
    ActiveRecord::Base.connection().execute("ALTER TABLE individual_items AUTO_INCREMENT = 1")
    if redirect
      redirect_to :controller => "reporting", :action => "index"
    end
  end
  
  # process a csv file with individual costs -------------
  def choose_individual_file

  end
  
  
  def parse_individual_file
    if not params[:individual_file]
      flash["error"] = "keine Datei hochgeladen"
      redirect_to :controller => "budget", :action =>"upload_individual_costs"
      return
    end
    
    list = []
    @failure = []
    all_projects = Project.all
    project_list = {}
    all_projects.each {|p| project_list[p.identifier.split('-').first] = p}
    file = params[:individual_file]
    
    # delete first all items
    delete_individual_all(false)

    #rows = CSV.read(file.path, {:col_sep => ";", :headers => false, :encoding => "ISO-8859-1"})
    rows = CSV.read(file.path, {:col_sep => ";", :headers => false}) #for server
    rows.each do |row|
      # convert to utf-8 because server dont like :encoding option :(
      row.each{|r| r.nil? ? nil : r.force_encoding("ISO-8859-1").encode!("UTF-8")}

      if row.length != 11 
        @failure.append([row, "Zeile nicht Vollständig"])
        next
      end
      
      if row[1].to_i == 6590 # dont use IAUF types
        next
      end

      row[5] = project_list[row[5].downcase]
      if row[5].nil?
        next
      end
      
      # parse floatstrings into a string, which can transformed into float
      row[7] = (row[7] || "0").sub('.', '').sub(',','.').to_f
      row[8] = (row[8] || "0").sub('.', '').sub(',','.').to_f
      
      begin
        row[9] = Date.parse(row[9])
        row[10] = Date.parse(row[10])
      rescue
        @failure.append([row, "Falsches Datumsformat. Im Excel sollte deutsches Format eingestellt sein"])
        next
      end
      
      list.append(row)
    end
    
    list.each do |row|
      #individual = IndividualItem.where(:receipt_number => row[0].to_i, :cost_type => row[1].to_i,
      #                                  :material_number => row[3].to_i, :material => row[4],
      #                                  :project_id => row[5].id, :label => row[6],
      #                                  :amount => row[7], :costs => row[8],
      #                                  :booking_date => row[9], :receipt_date => row[10])
      #if individual.empty?
        if not IndividualItem.create(:receipt_number => row[0].to_i, :cost_type => row[1].to_i,
                                      :cost_description => row[2], :material_number => row[3].to_i,
                                      :material => row[4], :project_id => row[5].id,
                                      :label => row[6], :amount => row[7], :costs => row[8],
                                      :booking_date => row[9], :receipt_date => row[10])
          @failure.append([row, "Fehler beim speichern"])
        #end
      end
    end
    
    flash[:error] = "Es sind Fehler beim hochladen aufgetreten" if !@failure.empty?
    flash[:notice] = "Datei hochgeladen" if @failure.empty?
    redirect_to :action => 'choose_individual_file'
  end
  
  # ------------ Helper methods --------------------
  
  def costs_for_TimeEntry(entry, salary_id = nil)
    if salary_id.nil?
      salary_id = UserCustomField.where(:name => "Gehalt").first.id
    end
    return (User.find(entry.user_id).custom_field_value(salary_id) || 50).to_f * entry.hours
  end
  
  
  def set_project
    if params[:project_id]
      begin
        @project = Project.find(params[:project_id])
      rescue
        @project = nil
      end
    end
    
    unless @project  
      flash[:error] = "Projekt nicht gefunden"
      render_404
      return
    end
  end

  def own_authorize
    if User.current.admin?
      return true
    else
      deny_access
    end
  end

end
