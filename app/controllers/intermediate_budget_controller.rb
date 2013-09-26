class IntermediateBudgetController < ApplicationController
  unloadable
  include BudgetCalculating
  
  before_filter :set_project
  before_filter :authorize_global("budget", "choose_individual_file")
  
  def index
	@subtotals = Subtotal.where(:project_id => @project.id)
	@costs = {}
	@subtotals.each do |s|
	  @costs[s.id] = IssueSubtotal.where(:subtotal_id => s.id).sum(:amount)
	end
  end
  
  def new
    @upto = Date.today-1
    @costs = costs_for_all_issues(@project, @upto)  
  end
  
  def new_all_projects
    projects = Project.all
    projects.each do |project|
	  
	  s = Subtotal.find_or_create_by_upto_and_project_id(Date.today-1, project.id)	  
	  if not s.update_attributes({:project_id => project.id, :upto => Date.today-1})
		flash[:error] = "Zwischensumme konnte nicht gespeichert werden"
		redirect_to :action => "index"
		return
	  end
	  
	  issues = Issue.where(:project_id => project.id)
	  issues.each do |i|
		salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
	    costs = costs_for_issue(i, s.upto, salary_customfield)
	    is = IssueSubtotal.find_or_create_by_issue_id_and_subtotal_id(i.id, s.id)
	    if not is.update_attributes({:amount => costs, :upto => s.upto})
	      flash[:error] = "Zwischensumme konnte nicht gespeichert werden"
		  redirect_to :action => "index"
		  return
	    end
	  end
	  
	end
	redirect_to :action => "index"
  end
  
  def create
    s = Subtotal.find_or_create_by_upto_and_project_id(Date.today-1, @project.id)
    if not s.update_attributes({:project_id => @project.id, :upto => Date.today-1,
							    :comment => params[:comment]})
	  flash[:error] = "Zwischensumme konnte nicht gespeichert werden"
	  redirect_to :action => "new"
	  return
	end
	
	issues = Issue.where(:project_id => @project.id)
	  issues.each do |i|
		salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
	    costs = costs_for_issue(i, s.upto, salary_customfield)
	    is = IssueSubtotal.find_or_create_by_issue_id_and_subtotal_id(i.id, s.id)
	    if not is.update_attributes({:amount => costs, :upto => s.upto})
	      flash[:error] = "Zwischensumme konnte nicht gespeichert werden"
		  redirect_to :action => "index"
		  return
	    end
	  end
	
    redirect_to :action => "index"
  end
  
  def edit
    if params[:subtotal_id] && Subtotal.exists?(params[:subtotal_id])
      s = Subtotal.find(params[:subtotal_id])
      s.update_attributes({:comment => params[:comment]})
    else
	  flash[:error] = "Eintrag existiert nicht"
	  render_404
	end
	
	redirect_to :action => "index"
  end
  
  def delete
	if params[:subtotal_id] && Subtotal.exists?(params[:subtotal_id])
	  s = Subtotal.find(params[:subtotal_id])
	  is = IssueSubtotal.where(:subtotal_id => s.id)
	  if not s.destroy
	    flash[:error] = "Konnte Eintrag nicht loeschen"
	    render_404
	  end
	  if not is.destroy_all
	    flash[:error] = "Konnte Eintraege fuer Issues nicht loeschen"
	    render_404
	  end
	  redirect_to :action => "index"
    else
      flash[:error] = "Eintrag exisitiert nicht"
      render_404
    end
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
