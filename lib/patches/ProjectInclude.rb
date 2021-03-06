module ProjectIncludeBudgetReporting

  def self.included(base)
    base.class_eval do
      has_many :IndividualItem, :dependent => :destroy
      has_many :PlannedBudget, :dependent => :destroy
      has_many :ProjectbudgetForecast, :dependent => :destroy
    end
  end

  def costs_issues(upto = Date.today)
    total = 0
    children.each do |c|
      total += c.costs_issues(upto)
    end

    salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    issues.each do |i|
      total += i.costs(upto, salary_customfield)
    end

    return total
  end

  def costs_individual_items(upto=Date.today)
    total = 0
    children.each do |c|
      total += c.costs_individual_items
    end

    total += IndividualItem.until(upto, self.id).sum(:costs)
    return total
  end

  def costs_issues_list(upto=Date.today)
    list = {}
    salary_customfield = UserCustomField.where(:name => "Stundenlohn").first

    all_issues = Issue.where(:project_id => self.id).group_by(&:fixed_version)
    all_issues.each do |version, issue_list|
      # populate list according
      # to this schema: {version => [[issue, total_costs],[...],...]}
      list[version] = []
      issue_list.each do |issue|
        total_costs = issue.costs(upto, salary_customfield)
        list[version].append([issue, total_costs])
      end
    end

    return list
  end

  def costs_individual_items_list(upto = Date.today)
    items = IndividualItem.until(upto, self.id)
    list = {}
    list[:category] =
      {
      "Material" =>{
        402010 => ["Rohstoffe"],
        402012 => ["Halbfabrikat"],
        402013 => ["Fertikprodukte"],
        421010 => ["H.u.B"],
        421020 => ["Arb.platz"]},
      "Fremdleistung" => {
        482200 => ["UL-Zerti"],
        440010 => ["Fremdleistung"],
        482810 => ["sonst. Beratung"],
        440011 => ["sonst. Beratung"]},
      "Verrechnung" =>{
        6167   => ["PMG Verrechnung"],
        6118   => ["Schalt. Verrechnung"]}
    }
    list[:other] = 0
    type_list = []

    list[:category].each do |group, subgroup|
      subgroup.each do |type, info|
        list[:category][group][type] << items.select{|p| p.cost_type == type}.sum{|p| p.costs}
        type_list << type
      end
    end
    list[:other] = items.select{|p| not type_list.include?(p.cost_type.to_i)}.sum{|p| p.costs}

    return list
  end

end

module IssueIncludeCosts

  def costs(upto = Date.today, salary_customfield = nil, costs_field = nil)
    total = 0
    if salary_customfield.nil?
      salary_customfield = UserCustomField.where(:name => "Stundenlohn").first
    end
    if costs_field.nil?
      costs_field = TimeEntryCustomField.where(:name => "Kosten/Stunde").first
    end

    # subtotal not needed anymore
    #subtotal = IssueSubtotal.where("issue_id = ? AND upto <= ?", self.id, upto).order("upto DESC").first
    #if subtotal
    #  entries = TimeEntry.where("issue_id = ? AND spent_on <= ? AND spent_on > ?", self.id, upto, subtotal.upto)
    #  total += subtotal.amount
    #else
    #  entries = TimeEntry.where("issue_id = ? AND spent_on <= ?", self.id, upto)
    #end

    entries = TimeEntry.where("issue_id = ? AND spent_on <= ?", self.id, upto)

    entries.each do |e|
      costs = 0
      if not costs_field.nil?
        costs_field_value = e.custom_field_value(costs_field.id)
        costs = ((costs_field_value.blank? ? nil : costs_field_value) || User.find(e.user_id).custom_field_value(salary_customfield.id) || 0.0).to_f * e.hours
      else
        costs = (User.find(e.user_id).custom_field_value(salary_customfield.id) || 0.0).to_f * entry.hours
      end
      total += costs
    end

    return total
  end
end

module VersionIncludeForecastDate

  def self.included(base)
    base.class_eval do
      has_many :VersiondateForecast, :dependent => :destroy
    end
  end

end

module VersionIncludeCustomProgress
  def self.included(base)
    base.class_eval do
      alias_method_chain :completed_percent, :custom_progress
    end
  end

  def done_ratio
    sum = 0
    amount = 0
    fixed_issues.each do |i|
      if i.root_id == i.id
        sum += i.done_ratio
        amount += 1
      end
    end
    return amount > 0 ? (sum/amount).round() : 0
  end

  def completed_percent_with_custom_progress
    if issues_count == 0
      0
    elsif open_issues_count == 0
      100
    else
      if estimated_hours == 0
        0
      else
        ((spent_hours/estimated_hours)*100).round()
      end
    end
  end
end

unless Project.included_modules.include? ProjectIncludeBudgetReporting
  Project.send(:include, ProjectIncludeBudgetReporting)
end

unless Version.included_modules.include? VersionIncludeForecastDate
  Version.send(:include, VersionIncludeForecastDate)
end

unless Version.included_modules.include? VersionIncludeCustomProgress
  Version.send(:include, VersionIncludeCustomProgress)
end

unless Issue.included_modules.include? IssueIncludeCosts
  Issue.send(:include, IssueIncludeCosts)
end
