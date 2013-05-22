class ReportingController < ApplicationController
  unloadable
  
  before_filter :set_project
  
  def index
    # show overview over actual project (depending on date)
    
  end
  
  def choose_gan_file
  
  end
  
  def upload_gan_file
    # upload a new gan file
    
    unless params[:gan]
      flash[:error] = "Keine Datei ausgewählt"
      redirect_to :controller => 'reporting', :action => 'choose_gan_file'
      return
    end
    
    doc = Nokogiri::XML(params[:gan])
    
    
    
    
    versions = Version.where(:project_id => @project.id)
    versions.each do |version|
      version_xml = doc.xpath("//task[@name='"+version.name+"']")
      update_node_from_xml(version_xml, [])
    end
    
  end
  

  
  
  # --------------- Helper methods --------------
  
  def update_node_from_xml(xml_node, issue_list, levels=1)
    # updates or creates issues from an
    
    if xml_node.empty? || xml_node.children.empty? || levels == 0
      return
    end
    
    
    xml_node.children.each do |child|
      
      # get issues or create a new (could be more than one, subject is not unique)
      corresponding_issues = Issue.where(:project_id => @project.id, 
          :subject => child["name"])
      
      if corresponding_issues.empty?
        corresponding_issues = [Issues.new({:subject => child["name"]})]
      end
      
      # isolate issue from relations
      issues_ids = corresponding_issues.map {|i| i.id}
      relation_ids = IssueRelation.where("issue_from_id IN (?) OR issue_to_id IN (?)",
          issues_id, issues_id).map {|r| r.id}
      IssueRelation.destroy(relation_ids)
      
      corresponding_issues.each do |issue|
        # isolate issue from children
        issue.children.each do |i|
          i.parent_issue_id = nil
          i.save
        end
        
        # update issue with new attributs
        start_date = Date.strptime(child["date"], "%Y-%m-%d")
        due_date = startdate + child["duration"].to_i
        issue.start_date = start_date
        issue.due_date = due_date
        journal = issue.init_journal(User.current, "Update mit Gan-File")
        issue.save
        journal.save
        
        # append issue from issue_list
        issue_list.apppend(issue)
        
      end
      
      # update childs recursively
      update_node_from_xml(child, issue_list, levels-1)
      
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
