class Subtotal < ActiveRecord::Base
  unloadable
  
  belongs_to :project
  
  def self.latest(project)
	where(:project_id => project.id).order("upto DESC").first
  end
  
end
