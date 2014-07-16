module IssueTargethours
	
	def self.included(base)
		base.class_eval do
			has_many :weekeffort, :dependent => :destroy
		end
	end
	
	def target_hours(date = Date.today)
		# return the target hours, which the issue should have been worked on, up to the provided date
		total = 0
		
		if date.is_a? Fixnum
			date = Date.commercial(Date.today.cwyear, Date.today.cweek+date)
		end
		
		if self.start_date <= date
			# add fractional, if start_date is not monday
			total += self.effort(start_date)/5 * [4-((date.wday+6)%7)+1, 0].max
			
			# TODO: one query for each week. this could may be optimized
			((self.start_date.cweek+1)...date.cweek).each do |w|
				total += self.effort(Date.commercial(self.start_date.cwyear, w))
			end
			# add fractional for the last days
			total += self.effort(date)/5 * [((date.wday+6)%7)+1, 5].min
		end
		return total
	end
	
	def effort(date = Date.today)
	
		if date.is_a? Fixnum
			date = Date.commercial(Date.today.cwyear, Date.today.cweek+date)
		end
		
		# return the planned effort for this week
		e = Weekeffort.where(:issue_id => self.id, :cweek => date.cweek, :cyear => date.cwyear).first
		return e.nil? ? 0 : e.hours
	end
	
end


module UserTargethours

	def weekly_hours(date = Date.today)
	
		if date.is_a? Fixnum
			date = Date.commercial(Date.today.cwyear, Date.today.cweek+date)
		end
		
		#return the hours a user is assigend to this week
		issues = Issue.where("assigned_to_id = ? AND (start_date <= ? OR due_date >= ?)", self.id, date.end_of_week, date.beginning_of_week)
		total = 0
		issues.each do |i|
			total += i.effort(date)
		end
		return total
	end
	
	def week_workhours
                # return the hours a user has to work in a week as defined in his contract
		c = UserCustomField.where(:name => "Wochenstunden").first.try(:id)
		return c.nil? ? 0 : self.custom_field_value(c) || 0
	end

end

unless Issue.included_modules.include? IssueTargethours
	Issue.send(:include, IssueTargethours)
end

unless User.included_modules.include? UserTargethours
	User.send(:include, UserTargethours)
end

