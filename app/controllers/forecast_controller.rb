# encoding: utf-8

class ForecastController < ApplicationController
  unloadable
  
  before_filter :set_project
  before_filter :authorize, :only => [:new_versiondate_forecast, :delete_versiondate_forecast,
                                      :new_budget_forecast, :delete_budget_forecast,
                                      :new_budget_plan, :delete_budget_plan]

  def show_versiondate_forecast
    date = Date.today
    @forecasts = []
    begin
      @version = Version.find(params[:version_id])
      if @version.project.id != @project.id
        @errors = "Meilenstein gehört nicht zum aktuellen Projekt"
      end
      @forecasts = VersiondateForecast.where(:version_id => @version.id).order("planned_date ASC")
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
      @forecasts = VersiondateForecast.where(:version_id => @version.id).order("planned_date ASC")
    else
      @errors = "Prognose existiert nicht"
    end
    render :partial => "show_version_forecast"
  end
  
  def new_versiondate_forecast
    if params[:version_id] && Version.exists?(params[:version_id])
      @version = Version.find(params[:version_id])
      if params[:forecast_date] && params[:planned_date]
        
        english_format_error = false
        # try special english format, which ruby does not parse wrong with respect to jquery datepicker...

        begin 
            forecast_date = params[:forecast_date].split("/")
            planned_date = params[:planned_date].split("/")
            if forecast_date.length == 3
              forecast_date = Date.new(forecast_date[2].to_i, forecast_date[0].to_i, forecast_date[1].to_i)
            else
              english_format_error = true
            end
            
            if planned_date.length == 3
              planned_date = Date.new(planned_date[2].to_i, planned_date[0].to_i, planned_date[1].to_i)
            else
              english_format_error = true
            end
          rescue
            english_format_error = true
          end
        
        if english_format_error
          begin
            forecast_date = Date.parse(params[:forecast_date])
            planned_date = Date.parse(params[:planned_date])
          rescue
            @errors = "Falsches Datumsformat"
          end
        end
        
        if not @errors
          forecast = VersiondateForecast.find_or_initialize_by_planned_date_and_version_id(planned_date, @version.id)
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
      
      @forecasts = VersiondateForecast.where(:version_id => @version.id).order("planned_date ASC")
    else
      @errors = "Version nicht gefunden"
    end
    
    render :partial => "show_version_forecast"
  end
  
  def show_budget_plan
    date = Date.today
    
    @plan = PlannedBudget.latest_budget_for(@project.id)
    render :partial => "show_budget_plan"
  end
  
  def new_budget_plan
    if params[:budget]
      begin
        budget = Float(params[:budget])
      rescue
        @errors = "Budget nicht numerisch"
      end
      
      if not @errors
        plan = PlannedBudget.find_or_initialize_by_project_id(@project.id)
        plan.update_attributes({
          :project_id => @project.id,
          :budget => budget,
        })
        if not plan.save
          @errors = "Konnte Planung nicht speichern"
        end
      end
    else
      @errors = "Budget Planung nicht angegeben"
    end
    
    @plan = PlannedBudget.latest_budget_for(@project.id)
    render :partial => "show_budget_plan"
  end
  
  def delete_budget_plan
    if params[:plan_id] && PlannedBudget.exists?(params[:plan_id])
      if not PlannedBudget.find(params[:plan_id]).destroy
        @errors = "Konnte Planung nicht löschen"
      end
    else
      @errors = "Planung existiert nicht"
    end
    
    @plan = PlannedBudget.latest_budget_for(@project.id)
    render :partial => "show_budget_plan"
  end
  
  def show_budget_forecast
    date = Date.today
    @forecasts = ProjectbudgetForecast.until(date, @project.id).order("planned_date ASC")
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
        
    @forecasts = ProjectbudgetForecast.until(date,@project.id).order("planned_date ASC")
    render :partial => "show_budget_forecast"
  end
  
  def new_budget_forecast
    date = Date.today
    if params[:budget] && params[:planned_date]
    
      english_format_error = false
      begin 
        planned_date = params[:planned_date].split("/")
        
        if planned_date.length == 3
          planned_date = Date.new(planned_date[2].to_i, planned_date[0].to_i, planned_date[1].to_i)
        else
          english_format_error = true
        end
      rescue
        english_format_error = true
      end
        
      if english_format_error
        begin
          planned_date = Date.parse(params[:planned_date])
        rescue
          @errors = "Falsches Datumsformat"
        end
      end
      
      begin
        budget = Float(params[:budget])
      rescue
        @errors = "Falsches Budget Eingabeformat"
      end
      
      if not @errors
        forecast = ProjectbudgetForecast.find_or_initialize_by_planned_date_and_project_id(planned_date, @project.id)
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
    @forecasts = ProjectbudgetForecast.until(date,@project.id).order("planned_date ASC")
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
