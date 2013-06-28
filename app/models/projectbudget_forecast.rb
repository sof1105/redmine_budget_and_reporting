class ProjectbudgetForecast < ActiveRecord::Base
  unloadable

  before_save :set_created_on_date
  validates_presence_of :planned_date
  validates_presence_of :budget

  def self.until(date, project_id)
    where("project_id = ? and planned_date <= ?", project_id, date)
  end
  
  def self.delta(number_of_months, project_id)
    actual_forecast = ProjectbudgetForecast.where(:project_id => project_id).latest
    months_ago = Date.today.months_ago number_of_months
    months_ago = months_ago.end_of_month
    old_forecast = ProjectbudgetForecast.until(months_ago, project_id).latest
    
    if actual_forecast && old_forecast
      return actual_forecast - old_forecast
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
