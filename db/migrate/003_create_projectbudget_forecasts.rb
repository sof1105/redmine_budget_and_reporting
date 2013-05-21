class CreateProjectbudgetForecasts < ActiveRecord::Migration
  def change
    create_table :projectbudget_forecasts do |t|
      t.integer :project_id
      t.float :budget
      t.date :planned_date
      t.date :created_on
    end
  end
end
