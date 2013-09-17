class IntermediateBudgetController < ApplicationController
  unloadable
  include BudgetCalculating
  
  before_filter :set_project
  
  def index
	@subtotals = Subtotal.where(:project_id => @project.id)
  end
  
  def new
    projects = Project.all
    projects.each do |project|
	  total_costs = costs_for_all_issues(project, Date.today)
	  s = Subtotal.find_or_create_by_upto_and_project_id(Date.today, project.id)
	  s.update_attributes({:project_id => project.id, :upto => Date.today, :amount => total_costs})
	  if !s.save
		flash[:error] = "Zwischensumme konnte nicht gespeichert werden"
		redirect_to :action => "index"
		return
	  end
	end
	redirect_to :action => "index"
  end
  
  def create
  
  end
  
  def edit
    if params[:subtotal_id] && Subtotal.exists?(params[:subtotal_id])
      s = Subtotal.find(params[:subtotal_id])
      begin
		amount = Float(params[:amount])
      rescue
		flash[:error] = "Kosten nicht numerisch"
		redirect_to :action => "index"
		return
      end
      
      s.update_attributes({:amount => amount, :comment => params[:comment]})
      
    else
	  flash[:error] = "Eintrag existiert nicht"
	  render_404
	end
	
	redirect_to :action => "index"
  end
  
  def delete
	if params[:subtotal_id] && Subtotal.exists?(params[:subtotal_id])
	  s = Subtotal.find(params[:subtotal_id])
	  if not s.destory
	    flash[:error] = "Konnte Eintrag nicht loeschen"
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
