class BudgetController < ApplicationController
  unloadable
  
  before_filter :set_project
  
  def index
    # show actual budget for project
    @overall_costs = {}
    @costs_per_issue = {}
    @individual_costs = {}
  
    # the overall costs of the project ---------------------------------------------------
    @overall_costs[:planned] = PlannedBudget.where(:project_id => @project.id).order("created_on DESC").first
    @overall_costs[:personal] = 0
    
    begin
      salary_custom_id = UserCustomField.where(:name => "Gehalt").first.id
    rescue
      salary_custom_id = nil
    end
    
    all_timelogs = TimeEntry.where(:project_id => @project.id)
    all_timelogs.each do |entry|
      salary = salary_custom_id ? User.find(entry.user_id).custom_field_value(salary) || 50 : 50
      @overall_costs[:personal] += entry.hours * salary
    end
    #TODO: add individual items cost
    
    # costs per issue -------------------------------------------------------------------
    
    
    
    # individuel costs ---------------------------------------------------------------------
  
  end
  
  def show_individual_costs
    # per month
  end
  
  def show_issue_costs
    
  end
  
  def upload_individual_costs
  
  end
  
  def parse_individual_file
  
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
