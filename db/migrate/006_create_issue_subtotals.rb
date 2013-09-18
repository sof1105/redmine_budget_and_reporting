class CreateIssueSubtotals < ActiveRecord::Migration
  def change
    create_table :issue_subtotals do |t|
	  t.integer :issue_id
	  t.date :upto
	  t.float :amount
	  t.integer :subtotal_id
    end
  end
end
