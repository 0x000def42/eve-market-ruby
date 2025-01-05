desc "calc"
task cacl: :environment do
  ########################################
  # 0) Подготовка: словари названий систем / товаров
  ########################################

  system_names = System.pluck(:id, :name).to_h       # { system_id => "Jita", ... }
  item_names   = ItemType.pluck(:id, :name).to_h     # { type_id   => "Veldspar", ... }
  item_ids   = ItemType.pluck(:id, :eve_id).to_h     # { type_id   => "Veldspar", ... }

  # Чтобы быстро узнать mass:
  item_masses  = ItemType.pluck(:id, :mass).to_h     # { type_id => mass }

  ########################################
  # 1) Собираем статистику по каждому type_id: cnt, avg_price
  ########################################

  item_stats = MarketsOrder
    .select("type_id, COUNT(*) AS cnt, AVG(price) AS avg_price")
    .where(is_buy_order: true)
    .group(:type_id)
    .map do |row|
      {
        type_id:   row.type_id.to_i,
        cnt:       row.cnt.to_i,
        avg_price: row.avg_price.to_f
      }
    end

  ########################################
  # 2) Фильтруем по условию: (1e9 / avg_price)*mass <= 50_000
  ########################################

  feasible_items = item_stats.select do |st|
    mass = item_masses[st[:type_id]] || 0
    avg_price = st[:avg_price]
    next false if avg_price <= 0  # если avg_price=0 => мусор
    # Сколько штук приблизительно купим за 1e9 по ср. цене:
    approximate_qty = 1_000_000_000 / avg_price
    total_mass      = approximate_qty * mass
    total_mass <= 50_000
  end

  ########################################
  # 3) Выбираем топ-10 из feasible по cnt DESC
  ########################################

  feasible_sorted = feasible_items.sort_by { |st| -st[:cnt] }
  top_10_items = feasible_sorted.first(10_000)

  top_type_ids = top_10_items.map { |st| st[:type_id] }

  # puts "Top-10 items (feasible by mass <= 50k at ~1e9 ISK), sorted by popularity:"
  # top_10_items.each_with_index do |it, i|
  #   tname = item_names[it[:type_id]] || "Type##{it[:type_id]}"
  #   puts "#{i+1}) #{tname}, cnt=#{it[:cnt]}, avg_price=#{it[:avg_price].round(2)}"
  # end

  ########################################
  # 4) ФУНКЦИИ «прогрызания»
  ########################################

  # Покупаем у SELL-ордеров (is_buy_order=false, ASC), цель ~1 млрд
  def accumulate_sell_orders_for_purchase(orders, budget_isk = 1_000_000_000)
    total_spent  = 0.0
    total_volume = 0
    orders.each do |ord|
      price = ord.price.to_f
      vol   = ord.volume_remain
      next if price <= 0 || vol <= 0
      isk_left = budget_isk - total_spent
      break if isk_left <= 0
      cost_full = vol * price
      if cost_full <= isk_left
        total_spent  += cost_full
        total_volume += vol
      else
        qty_can_buy = (isk_left / price).floor
        break if qty_can_buy <= 0
        cost_part = qty_can_buy * price
        total_spent  += cost_part
        total_volume += qty_can_buy
        break
      end
    end
    { volume: total_volume, spent: total_spent }
  end

  # Продаём в BUY-ордера (is_buy_order=true, DESC) весь объём
  def accumulate_buy_orders_for_sale(orders, volume_to_sell)
    leftover = volume_to_sell
    total_income = 0.0
    orders.each do |ord|
      break if leftover <= 0
      price = ord.price.to_f
      vol   = ord.volume_remain
      next if price <= 0 || vol <= 0
      can_sell = [ vol, leftover ].min
      total_income += can_sell * price
      leftover     -= can_sell
    end
    sold_qty = volume_to_sell - leftover
    { sold_qty: sold_qty, income: total_income }
  end

  ########################################
  # 5) Для каждого из top_type_ids => «прогрызаем»
  ########################################

  BUDGET      = 1_000_000_000
  MIN_SPENT   = 900_000_000
  routes      = []
  i = 0
  top_type_ids.each do |tid|
    puts i
    i+=1
    # Загружаем SELL (ASC)
    all_sell_orders = MarketsOrder
      .where(is_buy_order: false, type_id: tid)
      .order(:price)
      .to_a

    # Загружаем BUY (DESC)
    all_buy_orders = MarketsOrder
      .where(is_buy_order: true, type_id: tid)
      .order(price: :desc)
      .to_a

    sell_by_system = all_sell_orders.group_by(&:system_id)
    buy_by_system  = all_buy_orders.group_by(&:system_id)

    # Покупаем ~1e9 ISK
    purchase_info = {}
    sell_by_system.each do |sys_id, orders|
      purchase_info[sys_id] = accumulate_sell_orders_for_purchase(orders, BUDGET)
    end

    # Берём только те, где spent >= 900млн
    candidate_buy = purchase_info.select { |_s, dat| dat[:spent] >= MIN_SPENT }

    candidate_buy.each do |sys_sell, dat|
      vol_bought = dat[:volume]
      spent_isk  = dat[:spent]
      next if vol_bought <= 0

      # Продаём в разных системах BUY
      buy_by_system.each do |sys_buy, orders|
        r_sell = accumulate_buy_orders_for_sale(orders, vol_bought)
        sold_qty = r_sell[:sold_qty]
        income   = r_sell[:income]
        next if sold_qty <= 0
        profit     = income - spent_isk
        next if profit <= 0
        margin_pct = (profit / spent_isk) * 100.0
        routes << {
          type_id:     tid,
          buy_system:  sys_sell,
          sell_system: sys_buy,
          volume:      vol_bought,
          spent:       spent_isk,
          sold:        sold_qty,
          income:      income,
          profit:      profit,
          margin_pct:  margin_pct
        }
      end
    end
  end

  ########################################
  # 6) СОРТИРОВКА и ВЫВОД
  ########################################
  routes = routes.inject({}) do |acc, value|
    acc[value[:type_id]] ||= value
    acc[value[:type_id]] = value if acc[value[:type_id]][:margin_pct] < value[:margin_pct]
    acc
  end.values

  routes.sort_by! { |r| -r[:margin_pct] }

  puts "Found #{routes.size} routes among feasible items (spent>=900M)."

  routes.first(50).each_with_index do |r, i|
    type_name  = item_names[r[:type_id]]       || "Type##{r[:type_id]}"
    sys_buy_nm = system_names[r[:buy_system]]  || "Sys##{r[:buy_system]}"
    sys_sel_nm = system_names[r[:sell_system]] || "Sys##{r[:sell_system]}"
    type_id = item_ids[r[:type_id]] || "Type##{r[:type_id]}"

    spent_m  = r[:spent]  / 1_000_000.0
    income_m = r[:income] / 1_000_000.0
    profit_m = r[:profit] / 1_000_000.0

    puts "#{i+1}) Type=#{type_name}, " \
        "BuySys=#{sys_buy_nm} => SellSys=#{sys_sel_nm}, " \
        "Vol=#{r[:volume].round}, " \
        "Spent=#{spent_m.round(2)}M, " \
        "Sold=#{r[:sold].round}, " \
        "Income=#{income_m.round(2)}M, " \
        "Profit=#{profit_m.round(2)}M, " \
        "Margin=#{r[:margin_pct].round(2)}, " \
        "TypeId=#{type_id}"
  end
end
