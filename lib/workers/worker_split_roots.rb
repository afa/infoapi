class WorkerSplitRoots
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].split_roots!
  end
end


