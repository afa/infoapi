class WorkerBuildReferences
  include Sidekiq::Worker
  def perform(production_id)
    logger.info "start build refs for prduction #{production_id}"
    prod = SimpleApi::Sitemap::Production[production_id]
    return true unless prod
    logger.info "production #{prod.inspect}"
    prod.build_references!
    logger.info "done production #{production_id}"
  end
end
