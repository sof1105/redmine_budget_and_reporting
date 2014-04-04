# ====================================
# ====== Not needed anymore ==========
# ====== now in Project include ======
# ====================================

module BudgetCalculating

  def costs_for_TimeEntry(entry, salary_customfield = nil, costs_field = nil)
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    if costs_field.nil?
      costs_field = TimeEntryCustomField.where(:name => "Kosten/Stunde").first
    end

    # TODO: calculate costs depending on kosten/stunde or salary field
    
    costs = 0
    # we can't be sure that costs_field exists
    if not costs_field.nil?
      costs = (entry.custom_field_value(costs_field.id) || costs_field.default_value || 0.0).to_f * entry.hours
    else
      costs = (User.find(entry.user_id).custom_field_value(salary_customfield.id) || salary_customfield.default_value || 0.0).to_f * entry.hours
    end
    
    return costs
    #return (User.find(entry.user_id).custom_field_value(salary_customfield.id) || salary_customfield.default_value || 0.0).to_f * entry.hours
  end
  
  def costs_for_issue(issue, upto = Date.today, salary_customfield = nil, costs_field = nil)
    return 0 if issue == nil
    
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    if costs_field.nil?
      costs_field = TimeEntryCustomField.where(:name => "Kosten/Stunde").first
    end
    
    total_costs = 0
    # subtotal not needed anymore
    #is = IssueSubtotal.where("issue_id = ? AND upto <= ?",issue.id, upto).order("upto DESC").first
    #if is
    #  entries = TimeEntry.where("issue_id = ? AND spent_on <= ? AND spent_on > ?", issue.id, upto, is.upto)
    #  total_costs += is.amount
    #else
    #  entries = TimeEntry.where("issue_id = ? AND spent_on <= ?", issue.id, upto)
    #end

    entries = TimeEntry.where("issue_id = ? AND spent_on <= ?", issue.id, upto)

    entries.each do |entry|
      total_costs += costs_for_TimeEntry(entry, salary_customfield, costs_field)
    end
    return total_costs
  end
  
  def costs_for_individualitems(project, upto = Date.today )
    all_projects = project.self_and_descendants.map{|p| p.id}
    return IndividualItem.until(upto, all_projects).sum(:costs)
  end
  
  def costs_for_all_issues(project, upto = Date.today, salary_customfield = nil, costs_field = nil)
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    if costs_field.nil?
      costs_field = TimeEntryCustomField.where(:name => "Kosten/Stunde").first
    end
    
    total_costs = 0
    issues = Issue.where(:project_id => project.id)
    issues.each do |i|
      total_costs += costs_for_issue(i, upto, salary_customfield, costs_field)
    end
  	
    return total_costs
  end
end
