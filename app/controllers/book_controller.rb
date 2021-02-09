class BookController < ApplicationController

  def index
    Benchmark.realtime do
      @books = Rails.cache.fetch("jump-comics") do
        Book.order(release: :desc, volume: :desc).all.to_a
      end
    end.tap do |time|
      logger.info "#{time} seconds"
    end
  end

end
