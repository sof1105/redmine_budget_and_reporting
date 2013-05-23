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
    if not PlannedBudget.create({:project_id => @project.id, :budget => params[:budget].to_f, :created_on => Date.today})
      flash[:error] = "Fehler beim speichern"
    end
    redirect_to :controller => "budget", :action => "index"
  end
  
  def delete_budget_plan
    if params[:budget_id] && PlannedBudget.exists?(params[:budget_id])
      PlannedBudget.find(params[:budget_id]).destroy
    else
      # TODO: which format to response?
    end
    # TODO: which format to response?
  end
  
  def show_all_budget_plans
    budgets = PlannedBudget.where(:project_id => @project.id).order("created_on DESC")
    # TODO: which format to response
  end
  
  # process a csv file with individual costs -------------
  def upload_individual_costs
    # TODO: implement
  end
  
  def parse_individual_file
    # TODO: implement
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
