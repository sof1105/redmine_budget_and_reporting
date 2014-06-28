module IssueTargethours
	def self.included(base)
		base.class_eval do
		
		end
	end
	
	def target_hours
		if self.assigned_to && self.start_date
			
		else
			return 0
		end
	end
end

unless Issue.included_modules.include? IssueTargethours
	Issue.send(:include, IssueTargethours)
end
