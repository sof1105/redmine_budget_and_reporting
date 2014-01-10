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
    @individual_costs = []
  
    # the overall costs of the project ---------------------------------------------------
    @overall_costs[:planned] = PlannedBudget.latest_budget_for(@project.id)
    @overall_costs[:forecast] = ProjectbudgetForecast.until(date, @project.id).latest
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
    items = IndividualItem.where(:project_id => @project.id)
    @individual_costs =
    {
      "Material" =>{
        402010 => ["Rohstoffe"],
        402012 => ["Halbfabrikat"],
        402013 => ["Fertikprodukte"],
        421010 => ["H.u.B"],
        421020 => ["Arb.platz"]},
      "Fremdleistung" => {
        482200 => ["UL-Zerti"],
        440010 => ["Fremdleistung"],
        482810 => ["sonst. Beratung"],
        440011 => ["sonst. Beratung"]},
      "Verrechnung" =>{
        6167   => ["PMG Verrechnung"],
        6118   => ["Schalt. Verrechnung"]}
    }
    @invdividual_costs_all_other = 0
    type_list = []
    
    @individual_costs.each do |group, list|
      list.each do |type, info|
        @individual_costs[group][type] << items.select{|p| p.cost_type == type}.sum{|p| p.costs}
        type_list << type
      end
    end
    @individual_costs_all_other = items.select{|p| not type_list.include?(p.cost_type.to_i)}.sum{|p| p.costs}
    
    # render page or generate pdf
    if params[:pdf]=="1"
      send_data render_pdf(@project, @overall_costs, @costs_per_issue, @individual_costs, @individual_costs_all_other), 
                          :filename => "Budgetbericht.pdf", :disposition => "attachment"
      return
    end
  end


  def show_individual_costs
    @items = IndividualItem.where(:project_id => @project.id).order("booking_date ASC")
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
    IndividualItem.destroy_all(:project_id => @project.id)
    redirect_to :action => "index"
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
    
    rows = CSV.read(file.path, {:col_sep => ";", :headers => false, :encoding => "ISO-8859-1"})
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
