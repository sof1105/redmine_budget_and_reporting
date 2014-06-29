module IssueTargethours
	
	def self.included(base)
		base.class_eval do
			has_many :weekeffort, :dependent => :destroy
		end
	end
	
	def target_hours(date = Date.today)
		# return the target hours, which the issue should have been worked on, up to the provided date
		if
			
		else
			return 0
		end
	end
	
	def effort(date)
		# return the planned effort for this week
		
	end
	
end


module UserTargethours

	def weekly_hours(date = Date.today)
		#return the weekly hours a user is suppost to work on
		issues = Issue.where("assigned_to_id = ? AND start_date <= ? AND due_date >= ?", self.id, date.end_of_week, date.beginning_of_week)
		total = 0
		issues.each do |i|
			total += i.effort(date)
		end
		return total
	end

end

unless Issue.included_modules.include? IssueTargethours
	Issue.send(:include, IssueTargethours)
end

unless User.included_modules.include? UserTargethours
	User.send(:include, UserTargethours)
end

