class ProjectbudgetForecast < ActiveRecord::Base
  unloadable

  before_save :set_created_on_date

  def self.until(month, project_id)
    where("project_id = ? and planned_date <= ?", project_id, month.end_of_month).order("planned_date DESC")
  end
  
  def differenz(number_of_months)
    actual_forecast = ProjectbudgetForecast.where(:project_id => self.project_id)
    months_ago = Date.today.months_ago number_of_months
    old_forecast = ProjectbudgetForecast.until(months_ago, self.project_id)
    
    return actual_forecast.first.budget - old_forecast.first.budget
  end
  
  def set_created_on_date
    self.created_on = Date.today
  end

end
