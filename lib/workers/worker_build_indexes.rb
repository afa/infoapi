class WorkerBuildIndexes
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start build indexes for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    logger.info "production #{prod.inspect}"
    prod.build_indexes!
    logger.info "done production #{production_id}"
  end
end


