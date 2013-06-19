class VersiondateForecast < ActiveRecord::Base
  unloadable
  
  before_save :set_created_on_date
  validates_presence_of :planned_date
  validates_presence_of :forecast_date
  validates_presence_of :version_id

  def self.until(month, version_id)
    where("version_id = ? AND planned_date <= ?", version_id, month.end_of_month).order("planned_date DESC")
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
