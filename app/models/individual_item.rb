class IndividualItem < ActiveRecord::Base
  unloadable
  
  def self.until(month, project_id)
    where("project_id = ? AND spend_on <= ?", project_id, month).order("spend_on DESC")
  end
  
  def self.for_month(month, project_id)
    where("project_id = ? AND spend_on BETWEEN ? AND ?", project_id, month.beginning_of_month, month.end_of_month).order("spend_on DESC")
  end
  
end
