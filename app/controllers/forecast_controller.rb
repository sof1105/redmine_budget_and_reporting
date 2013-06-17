class ForecastController < ApplicationController
  unloadable
  
  before_filter :set_project

  def show_versiondate_forecast
    date = Date.today
    version_id = params[:version_id]
    @forecasts = VersiondateForecast.until(date, version_id)
    render :partial => "show_version_forecast"
  end
  
  
  
  
  #---------------------------------------------------------
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
