Sequel.migration do
  change do
    rename_column :sitemap_sessions, :generation_time, :created_at
  end
end

