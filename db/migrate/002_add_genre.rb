Sequel.migration do

  change do
    alter_table(:rules) do
      add_column :genres, String
    end
  end

end

