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
    if params[:version_id] && Version.exists?(params[:version_id])
      @version = Version.find(params[:version_id])
      if params[:forecast_date] && params[:planned_date]
        
        begin
          forecast_date = Date.parse(params[:forecast_date])
          planned_date = Date.parse(params[:planned_date])
        rescue
          @errors = "Falsches Datumsformat"
        end
        
        if not @errors
          forecast =VersiondateForecast.find_or_initialize_by_planned_date(planned_date)
          forecast.update_attributes({
            :forecast_date => forecast_date,
            :planned_date => planned_date,
            :version_id => @version.id
          })
          
          if not forecast.save
            @errors = "Fehler beim speichern"
          end
        end
        
      else
          @errors = "Kein Datum angegeben"
      end
      
      @forecasts = VersiondateForecast.until(Date.today, @version.id)
    else
      @errors = "Version nicht gefunden"
    end
    
    render :partial => "show_version_forecast"
  end
  
  def show_budget_plan
   
  end
  
  def show_budget_forecast
    date = Date.today
    @forecasts = ProjectbudgetForecast.until(date, @project.id).reverse
    render :partial => "show_budget_forecast"
  end
  
  def delete_budget_forecast
    date = Date.today
    if params[:forecast_id] && ProjectbudgetForecast.exists?(params[:forecast_id])
      if not ProjectbudgetForecast.find(params[:forecast_id]).destroy
        @errors = "Prognose konnte nicht gelöscht werden"
      end
    else
      @errors = "Prognose wurde nicht gefunden"
    end
        
    @forecasts = ProjectbudgetForecast.until(date,@project.id).reverse
    render :partial => "show_budget_forecast"
  end
  
  def new_budget_forecast
    date = Date.today
    if params[:budget] && params[:planned_date]
      
      begin
        planned_date = Date.parse(params[:planned_date])
        budget = Float(params[:budget])
      rescue
        @errors = "Falsches Eingabeformat"
      end
      
      if not @errors
        forecast = ProjectbudgetForecast.find_or_initialize_by_planned_date(planned_date)
        forecast.update_attributes({
          :budget => budget,
          :planned_date => planned_date,
          :project_id => @project.id
        })
        
        if not forecast.save
          @errors = "Prognose konnte nicht gespeichert werden"
        end
      end
      
    else
      @errors = "Kein Datum angegeben"
    end
    @forecasts = ProjectbudgetForecast.until(date,@project.id).reverse
    render :partial => "show_budget_forecast"
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
