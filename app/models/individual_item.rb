class IndividualItem < ActiveRecord::Base
  unloadable
  
  def self.until(month, project_id)
    where("project_id = ? AND booking_date <= ?", project_id, month).order("booking_date DESC")
  end
  
  def self.for_month(month, project_id)
    where("project_id = ? AND booking_date BETWEEN ? AND ?", project_id, month.beginning_of_month, month.end_of_month).order("booking_date DESC")
  end
  
end
