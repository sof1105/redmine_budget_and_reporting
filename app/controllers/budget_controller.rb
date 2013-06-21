#encoding: utf-8

class BudgetController < ApplicationController
  unloadable
  
  include BudgetCalculating
  before_filter :set_project
  before_filter :authorize, :only => [:choose_individual_file, :parse_individual_file]
  
  def index
    
    date = Date.today
    salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    
    # show actual budget for project
    @overall_costs = {}
    @costs_per_issue = {}
    @individual_costs = []
  
    # the overall costs of the project ---------------------------------------------------
    @overall_costs[:planned] = PlannedBudget.latest_budget_for(@project.id)
    @overall_costs[:forecast] = ProjectbudgetForecast.until(date, @project.id).first
    @overall_costs[:individual] = costs_for_individualitems(@project, date)
    @overall_costs[:issues] = costs_for_all_issues(@project, date, salary_customfield)
    
    # costs per issue -------------------------------------------------------------------
    all_issues = Issue.where(:project_id => @project.id).group_by(&:fixed_version)
    all_issues.each do |version, issue_list|
      # add a list for each version and populate according
      # to this schema: [[issue, total_costs][...]...]
      @costs_per_issue[version] = []
      issue_list.each do |issue|
        total_costs = costs_for_issue(issue, date, salary_customfield)
        @costs_per_issue[version].append([issue, total_costs])
      end
    end
    
    # individual costs ---------------------------------------------------------------------
    @individual_costs = IndividualItem.until(Date.today, @project.id).limit(10).reverse
  
  end
  
  def show_individual_costs
    @items = IndividualItem.where(:project_id => @project.id).order("booking_date ASC")
    render :partial => "show_individual_costs"
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
    
    rows = CSV.read(file.path, {:col_sep => ";", :headers => false})
    rows.each do |row|  
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
      individual = IndividualItem.where(:receipt_number => row[0].to_i, :cost_type => row[1].to_i,
                                        :project_id => row[5].id, :label => row[6],
                                        :amount => row[7], :costs => row[8],
                                        :booking_date => row[9], :receipt_date => row[10])
      if individual.empty?
        if not IndividualItem.create(:receipt_number => row[0].to_i, :cost_type => row[1].to_i,
                                      :cost_description => row[2], :project_id => row[5].id,
                                      :label => row[6], :amount => row[7], :costs => row[8],
                                      :booking_date => row[9], :receipt_date => row[10])
          @failure.append([row, "Fehler beim speichern"])
        end
      end
    end
    
    flash[:error] = "Es sind Fehler beim hochladen aufgetreten" if !@failure.empty?
    flash[:notice] = "Datei hochgeladen" if @failure.empty?
    render :choose_individual_file
  end
  
  # ------------ Helper methods --------------------
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

end
