Sequel.migration do
  up do
    alter_table(:rules) do
      add_column :position, Integer, unique: true
    end

    SimpleApi::Rule.set_dataset :rules
    SimpleApi::Rule.order(:id).each_with_index do |rule, index|
      rule.update position: index + 1
    end

    alter_table(:rules) do
      set_column_type :position, Integer, unique: true, null: false
    end
  end

  down do
    alter_table(:rules) do
      drop_column :position
    end
  end
end
