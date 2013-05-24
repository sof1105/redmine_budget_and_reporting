class BudgetController < ApplicationController
  unloadable
  
  before_filter :set_project
  
  def index
    # show actual budget for project
    @overall_costs = {}
    @costs_per_issue = {}
    @individual_costs = []
  
    # the overall costs of the project ---------------------------------------------------
    @overall_costs[:planned] = PlannedBudget.latest_budget_for(@project.id)
    @overall_costs[:forecast] = ProjectbudgetForecast.where(:project_id => @project.id).order("planned_date DESC").first
    @overall_costs[:individual] = IndividualItem.until(Date.today, @project.id).sum(:costs)
    @overall_costs[:issues] = 0
    
    salary_custom_id = UserCustomField.where(:name => "Gehalt").first.id
    
    all_timelogs = TimeEntry.where(:project_id => @project.id)
    all_timelogs.each do |entry|
      @overall_costs[:issues] += costs_for_TimeEntry(entry, salary_custom_id)
    end
    
    
    
    # costs per issue -------------------------------------------------------------------
    all_issues = Issue.where(:project_id => @project.id).group_by(&:fixed_version)
    all_issues.each do |version, issue_list|
      # add a list for each version and populate according
      # to this schema: [[issue, total_costs][...]...]
      @costs_per_issue[version] = []
      issue_list.each do |issue|
        all_TimeEntries = TimeEntry.where(:issue_id => issue.id)
        total_costs = 0
        all_TimeEntries.each do |entry|
          total_costs += costs_for_TimeEntry(entry, salary_custom_id)
        end
        @costs_per_issue[version].append([issue, total_costs])
      end
    end
    
    
    # individual costs ---------------------------------------------------------------------
    @indiviual_costs = IndividualItem.for_month(Date.today, @project.id)
  
  end
  
  def show_individual_costs
    # TODO: per month or all for project? and which format to respond?
  end
  
  
  def new_budget_plan
    if not PlannedBudget.create({:project_id => @project.id, :budget => params[:budget].to_f})
      flash[:error] = "Fehler beim speichern"
    end
    redirect_to :controller => "budget", :action => "index"
  end
  
  def delete_budget_plan
    if params[:budget_id] && PlannedBudget.exists?(params[:budget_id])
      unless PlannedBudget.find(params[:budget_id]).destroy
        flash[:error]= "Konnte geplanntes Budget nicht loeschen"
      end
    else
      flash[:error] = "Keine id angegeben"
    end
    @budgets = PlannedBudget.where(:project_id => @project.id).order("created_on DESC")
    redirect_to :controller => "budget", :action => "index"
  end
  
  def show_all_budget_plans
    @budgets = PlannedBudget.where(:project_id => @project.id).order("created_on DESC")
    render :partial => "show_budget_plan"
  end
  
  # process a csv file with individual costs -------------
  def choose_individual_file
    # TODO: template file
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
    
    CSV.parse(params[:individual_file].read, {:col_sep => ";", :headers => false}) do |row|
      if row.length != 11
        @failure.append(row)
        next
      end
      
      if row[1].to_i != 6590 # dont use IAUF types
        next
      end
      
      row[5] = project_list[row[5].downcase]
      begin
        row[9] = Date.strptime(row[9], "%d.%m.%Y")
      rescue
        next
      end
      
      list.append(row)
    end
    
    list.each do |row|
      if not IndividualItem.create(:project_id => row[5].id, :label =>row[6],
                                    :spend_on => row[9], :costs => row[8].to_f)
        @failure.append(row)
      end
    end
    
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

end
