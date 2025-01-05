namespace :populate do
  desc "Populate regions"
  task regions: :environment do
    ids = EveClient.instance.get("/universe/regions/")
    existed_ids = Region.where(eve_id: ids).pluck(:eve_id)
    populate_ids = ids - existed_ids

    progressbar = ProgressBar.create(
      title: "Region population progress",
      starting_at: 0,
      total: populate_ids.size,
      throttle_rate: 0.1,
      format: "%c/%C"
    )

    populate_ids.each do |id|
      result = EveClient.instance.get("/universe/regions/$1", id)
      Region.create!(
        eve_id: id,
        name: result["name"]
      )
      progressbar.increment
    end
  end

  desc "Populate constellations"
  task constellations: :environment do
    ids = EveClient.instance.get("/universe/constellations/")
    existed_ids = Constellation.where(eve_id: ids).pluck(:eve_id)
    populate_ids = ids - existed_ids

    progressbar = ProgressBar.create(
      title: "Constellation population progress",
      starting_at: 0,
      total: populate_ids.size,
      throttle_rate: 0.1,
      format: "%c/%C"
    )

    mutex = Mutex.new

    Parallel.each(populate_ids, in_threads: ENV.fetch("RAILS_MAX_THREADS").to_i) do |id|
      result = EveClient.instance.get("/universe/constellations/$1", id)
      Constellation.create!(
        eve_id: id,
        name: result["name"],
        region: Region.find_by(eve_id: result["region_id"]),

      )
      mutex.synchronize do
        progressbar.increment
      end
    end
  end

  desc "Populate systems"
  task systems: :environment do
    ids = EveClient.instance.get("/universe/systems/")
    existed_ids = System.where(eve_id: ids).pluck(:eve_id)
    populate_ids = ids - existed_ids

    progressbar = ProgressBar.create(
      title: "System population progress",
      starting_at: 0,
      total: populate_ids.size,
      throttle_rate: 0.1,
      format: "%c/%C"
    )

    mutex = Mutex.new

    Parallel.each(populate_ids, in_threads: ENV.fetch("RAILS_MAX_THREADS").to_i) do |id|
      result = EveClient.instance.get("/universe/systems/$1", id)
      constellation = Constellation.find_by(eve_id: result["constellation_id"])
      unless constellation
        puts "System for constellation skipped #{result["constellation_id"]}"
        next
      end
      ActiveRecord::Base.transaction do
        system = System.create!(
          eve_id: id,
          name: result["name"],
          constellation:,
          security_class: result["security_class"],
          security_status: result["security_status"]
        )
        result["stations"]&.each do |station_id|
          station_result = EveClient.instance.get("/universe/stations/$1", station_id)
          Station.create(
            system:,
            eve_id: station_id,
            name: station_result["name"]
          )
        end
      end
      mutex.synchronize do
        progressbar.increment
      end
    end
  end

  desc "Populate structures"
  task structures: :environment do
    ids = EveClient.instance.get("/universe/structures/")
    existed_ids = Structure.where(eve_id: ids).pluck(:eve_id)
    populate_ids = ids - existed_ids

    progressbar = ProgressBar.create(
      title: "Structure population progress",
      starting_at: 0,
      total: populate_ids.size,
      throttle_rate: 0.1,
      format: "%c/%C"
    )

    mutex = Mutex.new

    Parallel.each(populate_ids, in_threads: ENV.fetch("RAILS_MAX_THREADS").to_i) do |id|
      result = EveClient.instance.get("/universe/structures/$1", id)
      structure = System.find_by(eve_id: result["solar_system_id"])
      unless structure
        puts "Structure for system skipped #{result["solar_system_id"]}"
        next
      end
      ActiveRecord::Base.transaction do
        Structure.create!(
          eve_id: id,
          name: result["name"],
          system_id: structure.id,
          owner_id: result["owner_id"],
          type_id: result["type_id"],
        )
      end
      mutex.synchronize do
        progressbar.increment
      end
    end
  end
end
