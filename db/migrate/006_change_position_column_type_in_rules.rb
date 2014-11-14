Sequel.migration do
  up do
    alter_table(:rules) do
      drop_column :position
      add_column :position, Integer
    end
  end

  down do
    alter_table(:rules) do
      drop_column :position
      add_column :position, Integer, unique: true
    end
  end
end
