class VersiondateForecast < ActiveRecord::Base
  unloadable
  
  before_save :set_created_on_date
  validates_presence_of :planned_date
  validates_presence_of :forecast_date
  validates_presence_of :version_id

  def self.until(date, version_id)
    where("version_id = ? AND planned_date <= ?", version_id, date)
  end

  def self.until_date(date)
    where("planned_date <= ?", date)
  end
  
  def self.delta(number_of_months, version_id)
    actual_forecast = VersiondateForecast.where(:version_id => version_id).latest
    months_ago = Date.today.months_ago number_of_months
    months_ago = months_ago.end_of_month
    old_forecast = VersiondateForecast.until(months_ago, version_id).latest
    
    if actual_forecast.try(:forecast_date) && old_forecast.try(:forecast_date)
      return actual_forecast.forecast_date - old_forecast.forecast_date
    else
      return 0
    end
  end
  
  def self.latest
    order("planned_date DESC").first
  end
  
  def set_created_on_date
    self.created_on = Date.today
  end
  
end
