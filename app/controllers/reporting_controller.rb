class ReportingController < ApplicationController
  unloadable
  
  before_filter :set_project
  
  def index
    # show overview over actual project (depending on date)
    
  end
  
  
  
  
  
  # upload new gan-file ---------------------------------
  def choose_gan_file
  
  end
  
  def upload_gan_file
    
    unless params[:gan]
      flash[:error] = "Keine Datei ausgewaehlt"
      redirect_to :controller => 'reporting', :action => 'choose_gan_file'
      return
    end
    
    levels = params[:first_level_only].nil? ? -1 : 1
    delete_old = params[:delete_old].nil? ? false : true
    
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
    
      
    versions = Version.where(:project_id => @project.id)
    issue_list = []
    versions.each do |version|
      version_xml = doc.xpath("//task[@name='"+version.name+"']")
      version_xml.first.children.each do |issue|
        update_issue_from_xml(issue, version.id, issue_list, levels)
      end
    end
    
    # delete old issues if checkbox is true
    if delete_old
      new_issue_ids = issue_list.map {|i| i.id}
      Issues.where("project_id = ? AND id NOT IN (?)", @project.id, new_issue_ids)
    end
    
    # TODO: update Issue Relations
    
    redirect_to :controller => 'reporting', :action => 'choose_gan_file'
  end
  
  
  
  
  # --------------- Helper methods --------------
  
  def update_issue_from_xml(xml_node, version, issue_list, levels=1)
    # updates or creates issues which corresponds to xml_nod
    # to a maximum depth of levels
    
    if !xml_node || xml_node.node_name != "task" ||  levels == 0
      return
    end
    
    tracker_id = @project.trackers.first.id
    
          
    # get issues or create a new (could be more than one, subject is not unique)
    corresponding_issues = Issue.where(:project_id => @project.id, 
        :subject => xml_node["name"])
    if corresponding_issues.empty?
      corresponding_issues = [Issue.new({:project_id => @project.id, :subject => xml_node["name"],
          :author_id => User.current.id, :tracker_id => tracker_id})]
    end
    
    # isolate issue from relations
    issues_ids = corresponding_issues.map {|i| i.id}
    relation_ids = IssueRelation.where("issue_from_id IN (?) OR issue_to_id IN (?)",
        issues_ids, issues_ids).map {|r| r.id}
    IssueRelation.destroy(relation_ids)
    
    # find the new parent issue according to xml tree (either issue or version)
    parent = Issue.where(:project_id => @project.id, :subject => xml_node.parent["name"]).first
    # (if parent = nil than its a root issue, because function moves down the xml tree
    # recursively a parent issue should have been created before 
     
    corresponding_issues.each do |issue|
      # isolate issue from children
      issue.children.each do |i|
        i.parent_issue_id = nil
        i.save
      end
      
      # update issue with new attributs
      start_date = Date.strptime((xml_node["start"]||Date.today.to_s), "%Y-%m-%d")
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

    
    # update childs recursively (but after all childs a created)
    xml_node.children.each do |child|
      update_issue_from_xml(child, version, issue_list, levels-1)
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
