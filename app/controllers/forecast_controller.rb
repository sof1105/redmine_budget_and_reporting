# encoding: utf-8

class ForecastController < ApplicationController
  unloadable
  
  before_filter :set_project

  def show_versiondate_forecast
    date = Date.today
    @forecasts = []
    begin
      @version = Version.find(params[:version_id])
      if @version.project.id != @project.id
        @errors = "Meilenstein gehört nicht zum aktuellen Projekt"
      end
      @forecasts = VersiondateForecast.until(date, @version.id).reverse
    rescue
      @errors = "Meilenstein wurde nicht gefunden"
    end
    render :partial => "show_version_forecast"
  end
  
  def delete_versiondate_forecast
    if params[:forecast_id] && VersiondateForecast.exists?(params[:forecast_id])
      forecast = VersiondateForecast.find(params[:forecast_id])
      @version = Version.find(forecast.version_id)
      if not forecast.destroy
        @errors = "Prognose konnte nicht gelöscht werden"
      end
      @forecasts = VersiondateForecast.until(Date.today, @version.id).reverse
    else
      @errors = "Prognose existiert nicht"
    end
    render :partial => "show_version_forecast"
  end
  
  def new_versiondate_forecast
  
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
