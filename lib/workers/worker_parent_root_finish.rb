class WorkerParentRootFinish
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].finish!
  end
end

