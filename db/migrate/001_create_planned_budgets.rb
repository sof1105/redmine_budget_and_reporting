class CreatePlannedBudgets < ActiveRecord::Migration
  def change
    create_table :planned_budgets do |t|
      t.integer :project_id
      t.float :budget
      t.date :created_on
    end
  end
end
