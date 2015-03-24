class WorkerBuildJunk
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start empty refs for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    logger.info "production #{prod.inspect}"
    prod.empty_junk!
    logger.info "done production #{production_id}"
  end
end
