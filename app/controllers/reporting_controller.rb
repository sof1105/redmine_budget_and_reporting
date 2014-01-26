class ReportingController < ApplicationController
  unloadable
  include BudgetCalculating
  
  before_filter :set_project
  before_filter :authorize, :only => [:choose_gan_file, :upload_gan_file]
  
  def index
    # show overview over actual project (depending on date)
    date = Date.today
    salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    version_customfield = VersionCustomField.where(:name => "Abgeschlossen").first
    role = Role.where(:name => "Projektleiter").first
    

    # get the project informations
    @project_information = {}
    typ = @project.custom_field_value(ProjectCustomField.where(:name => "Projekttyp").first.try(:id))
    export = @project.custom_field_value(ProjectCustomField.where(:name => "Wird exportiert").first.try(:id))
    remark = @project.custom_field_value(ProjectCustomField.where(:name => "Bemerkung Projektreporting").first.try(:id))
    @project_information[:typ] = typ
    @project_information[:export] = export
    @project_information[:remark] = remark
    @project_information[:projectleader] = @project.users_by_role[role] || []
    

    # get the informations of all versions of the project
    @version_informations = []
    @project.versions.each do |version|
      temp = []
      closed = nil
      forecast = nil
      forecast = VersiondateForecast.where(:version_id => version.id).latest
      closed = version.custom_field_value(version_customfield.try(:id))
      temp.append(version)
      temp.append(forecast)
      temp.append(closed)
      @version_informations.append(temp)
    end
    @version_informations.sort! {|a,b| a[0].name <=> b[0].name}
    

    # get the budget informations of the project
    @budget = []
    budget_issue = costs_for_all_issues(@project, date, salary_customfield)
    budget_individual = costs_for_individualitems(@project, date)
    
    @budget.append(budget_issue)
    @budget.append(budget_individual)
    @budget.append(PlannedBudget.latest_budget_for(@project.id))
    @budget.append(ProjectbudgetForecast.until(date, @project.id).latest)

  end

  def choose_export
    typ_id = ProjectCustomField.where(:name => "Projekttyp").first.try(:id)
    export_id = ProjectCustomField.where(:name => "Wird exportiert").first.try(:id)
    project_leader = Role.where(:name => "Projektleiter").first
    @project_list = {}
    @special_list = {}

    # all projects who should be exported
    projects = Project.all.select do |p|
      p.custom_field_value(export_id) == "1"
    end
    
    # all projects sorted by typ
    ProjectCustomField.find(typ_id).possible_values.each do |t|
      @project_list[t]=projects.select{|p| p.custom_field_value(typ_id) == t}
    end

    # all projects by current user
    @special_list["own_projects"] = User.current.projects_by_role[project_leader].map{|p| p.id}.join("','")
    
    # all projects which are not closed
    @special_list["open_projects"] = projects.select{|p| p.status == 1}.map{|p| p.id}.join("','")

  end

  def export_excel_variable_projects
    project_ids = params[:export] || {}
    project_ids =project_ids.select{|k,v| v=="1"}.keys
    @projects = Project.where(:id => project_ids)
    @projectleader_role = Role.where(:name => "Projektleiter").first
    @upto = valid_date(params[:upto]) || Date.today

    file = render_to_string :xlsx => "all_projects"#, :filename => 'Projektreporting_'+@upto.to_s+'.xlsx', :disposition => 'attachment'
    send_data file, :filename => "Projektreporting_"+@upto.to_s+".xlsx", :disposition => "attachment"
  end


  ## isnt used anymore -----------------------------------------------------------------------------------
  def export_excel_all_projects
    @projects = Project.all.reject {|p| p.module_enabled?(:reporting).nil? || !p.active? }
    @projectleader_role = Role.where(:name => "Projektleiter").first
    
    render :xlsx => 'all_projects', :filename => "Projektreporting_alle.xlsx", :disposition => "attachment" 
  end
  
  def export_excel_single_project
    @projects = Project.where(:id => @project.id)
    @projectleader_role = Role.where(:name => "Projektleiter").first
    
    render :xlsx => 'all_projects', :filename => "Projektreporting_einzel.xlsx", :disposition => "attachment" 
  end

  def export_excel_own_projects
    @projectleader_role = Role.where(:name => "Projektleiter").first
    @projects = Project.all.select do |p| 
      projectleaders = p.users_by_role[@projectleader_role]
      p.module_enabled?(:reporting) && p.active? && projectleaders.try(:include?, User.current)
    end
    
    render :xlsx => 'all_projects', :filename => "Projektreporting_einzel.xlsx", :disposition => "attachment"
  end
  
  # upload new gan-file ---------------------------------
  def choose_gan_file
    @tracker_ids = @project.trackers
    if @tracker_ids.empty?
      flash[:error] = "Es gibt im aktuellen Projekt keine Tracker."
      return
    end
    @tracker_ids = @tracker_ids.map{|t| [t.name, t.id]}
    if not @project.trackers.where(:name => "Aufgabe").empty?
      @standard_id = @project.trackers.where(:name => "Aufgabe").first.id
    end
  end
  
  def upload_gan_file
    # check for params
    unless params[:gan]
      flash[:error] = "Keine Datei ausgewaehlt"
      redirect_to :controller => 'reporting', :action => 'choose_gan_file'
      return
    end
    
    levels = params[:levels].nil? ? -1 : params[:levels].to_i
    delete_old = params[:delete_old].nil? ? false : true
    tracker = @project.trackers.where(:id => params[:tracker_id]).first || @project.trackers.first
    if tracker.nil?
      flash[:error] = "Es existiert kein Tracker fuer dieses Projekt."
      return
    end    
    
    # init nokogiri xml parser
    doc = Nokogiri::XML(params[:gan]) do |config|
      config.noblanks
    end
    
    if !doc.errors.empty?
      flash[:error] = "Dateiformat stimmt nicht"
      puts doc.errors
      redirect_to :controller => "reporting", :action => "choose_gan_file"
      return
    end
    
    # TODO: maybe validation check? version isn't allowed to be a child
    #       of another version
    
    
    # update all versions of current project
    versions = Version.where(:project_id => @project.id)
    issue_list = []
    versions.each do |version|
      version_xml = doc.xpath("//task[@name='"+version.name+"']")
      if version_xml.first
        version_xml.first.children.each do |issue|
          update_issue_from_xml(issue, version.id, tracker, issue_list, levels)
        end
      end
    end
    
    # delete old issues if corresponding checkbox is true
    new_issue_ids = issue_list.map {|i| i.id}
    
    if delete_old
      Issue.destroy_all(["project_id = ? AND id NOT IN (?)", @project.id, new_issue_ids])
    else
      # if old issues are not destroyed, move them to the version "Alte Aufgaben"
      version_for_old = Version.where(:project_id => @project.id, :name => "Alte Aufgaben").first
      if version_for_old.nil?
        version_for_old = Version.create(:project_id => @project.id, :name => "Alte Aufgaben")
      end
      logger.info("before selection of old issues --------------------------")
      old_issues = Issue.where("project_id = ? AND id NOT IN (?) ", @project.id, new_issue_ids)
      old_issues.each do |issue|
        issue.fixed_version_id = version_for_old.id
        issue.save
      end
    end
    
    # TODO: update Issue Relations
    
    flash[:notice] = "Gan-File wurde hochgeladen"
    if params[:back_url]
        redirect_to params[:back_url]
    end
    redirect_to :controller => 'gantts', :action => 'show'
  end
  
    
  
  # --------------- Helper methods --------------
  def update_issue_from_xml(xml_node, version, tracker, issue_list, levels=0)
    # updates or creates issues which corresponds to xml_nod
    # to a maximum depth of levels (level 0 = only first level issue)
    
    if !xml_node || xml_node.node_name != "task"
      return
    end
    
    # get issues or create a new (could be more than one, subject is not unique)
    corresponding_issues = Issue.where(:project_id => @project.id, 
        :subject => xml_node["name"])
    if corresponding_issues.empty?
      corresponding_issues = [Issue.create({:project_id => @project.id, :subject => xml_node["name"],
          :author_id => User.current.id, :tracker_id => tracker.id})]
    end
    
    # isolate issue from relations
    issues_ids = corresponding_issues.map {|i| i.id}
    relation_ids = IssueRelation.where("issue_from_id IN (?) OR issue_to_id IN (?)",
        issues_ids, issues_ids).map {|r| r.id}
    IssueRelation.destroy(relation_ids)
    
    # find the new parent issue according to xml tree (can be either an issue or version)
    parent = Issue.where(:project_id => @project.id, :subject => xml_node.parent["name"]).first
    # (if parent = nil than its a root issue, because function moves down the xml tree
    # recursively a parent issue should have been created before 
     
    corresponding_issues.each do |issue|
      # isolate issue from children
      issue.children.each do |i|
        i.parent_issue_id = nil
        i.save
      end
      issue.reload # because the children were saved, which changes attributes on the parent and we would get a stale error

      # update issue with new attributs
      start_date = Date.strptime((xml_node["start"] || Date.today.to_s), "%Y-%m-%d")
      due_date = start_date + (xml_node["duration"].to_i || 1)
      
      issue.start_date = start_date
      issue.due_date = due_date
      issue.parent_issue_id = (parent.nil?) ? nil : parent.id
      issue.fixed_version_id = version
      
      unless issue.save
        issue.errors.each do |e|
          logger.info(e.to_s + "=>" + issue.errors[e].to_s)
        end
      end
      journal = issue.init_journal(User.current, "Update mit Gan-File")
      journal.save
      
      # append issue from issue_list
      issue_list.append(issue)
    end

    # update childs recursively (but after all current level childs a created)
    levels = levels -1
    if levels == -1
      return
    end
    xml_node.children.each do |child|
      update_issue_from_xml(child, version, tracker, issue_list, levels)
    end
  end
  
  def valid_date(date_string)
    # uses date string with following format:
    #     "2012-10-25"
    # and returns Date object of nil depending if format is valid
    
    if date_string.blank?
      return nil
    end
    
    if date_string && date_string.split("-").first.length != 4
      return nil
    end
    
    begin
      return date = Date.strptime(date_string, "%Y-%m-%d")
    rescue
      return nil
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
