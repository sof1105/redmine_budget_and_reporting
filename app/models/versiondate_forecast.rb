class VersiondateForecast < ActiveRecord::Base
  unloadable
  
  before_save :set_created_on_date

  def self.until(month, project_id)
    where("project_id = ? AND planned_date <= ? ORDER BY planned_date DESC", project_id, month.end_of_month)
  end
  
  def differenz(number_of_months)
    actual_forecast = VersionForecast.where(:project_id => self.project_id)
    months_ago = Date.today.months_ago number_of_months
    old_forecast = VersionForecast.until(months_ago, self.project_id)
    
    return actual_forecast.first.forecast_date - old_forecast.first.forecast_date
  end
  
  def set_created_on_date
    self.created_on = Date.today
  end
  
end
