class PlannedBudget < ActiveRecord::Base
  unloadable
  
  before_save :set_created_on_date
  
  def self.latest_budget_for(project_id)
    where(:project_id => project_id).order("created_on DESC").first
  end
  
  def set_created_on_date
    self.created_on = Date.today
  end
  
end
