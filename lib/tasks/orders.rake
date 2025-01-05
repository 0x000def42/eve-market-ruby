namespace :orders do
  desc "Region pages"
  task region_pages: :environment do
    regions = Region.all

    progressbar = ProgressBar.create(
      title: "Region market size progress",
      starting_at: 0,
      total: regions.size,
      throttle_rate: 0.1,
      format: "%c/%C"
    )

    mutex = Mutex.new

    Parallel.map(regions, in_threads: ENV.fetch("RAILS_MAX_THREADS").to_i) do |region|
      EveClient.instance.get("/markets/$1/orders", region.eve_id) do |response|
        region.update(market_pages: response.headers["x-pages"].to_i)
      end

      mutex.synchronize do
        progressbar.increment
      end
    end
  end

  desc "Region orders"
  task region: :environment do
    dataset = Region.all.map do |region|
      [ *(0...region.market_pages) ].map do |page|
        {
          region_eve_id: region.eve_id,
          region_id: region.id,
          page: page+1
        }
      end
    end.flatten

    progressbar = ProgressBar.create(
      title: "Constellation population progress",
      starting_at: 0,
      total: dataset.size,
      throttle_rate: 0.1,
      format: "%c/%C"
    )

    mutex = Mutex.new

    Parallel.each(dataset, in_threads: ENV.fetch("RAILS_MAX_THREADS").to_i) do |item|
      orders = EveClient.instance.get("/markets/$1/orders", item[:region_eve_id], params: { page: item[:page] })

      next if orders.empty?

      ActiveRecord::Base.transaction do
        MarketsOrder.insert_all(orders, unique_by: :order_id)
      end

      mutex.synchronize do
        progressbar.increment
      end
    end
  end
end
