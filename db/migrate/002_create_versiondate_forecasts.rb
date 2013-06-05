class CreateVersiondateForecasts < ActiveRecord::Migration
  def change
    create_table :versiondate_forecasts do |t|
      t.integer :version_id
      t.date :forecast_date
      t.date :planned_date
      t.date :created_on
    end
  end
end
