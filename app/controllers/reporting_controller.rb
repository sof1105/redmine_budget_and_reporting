class ReportingController < ApplicationController
  unloadable
  
  before_filter :set_project
  
  def index
    # show overview over actual project (depending on date)
    
  end
  
  def upload_gan_file
    # upload a new gan file
    
  end
  

  
  
  # --------------- Helper methods --------------
  
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
