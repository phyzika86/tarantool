import tarantool

try:
    # Подключение к Tarantool
    conn = tarantool.Connection('localhost', 3301)

    # Тестовый запрос - получение информации о сервере
    result = conn.call('box.info')
    print("Подключение успешно!")
    print(f"Версия Tarantool: {result.data[0]['version']}")

    # минимальная стоимость авиабилета на рейсы
    date_to_check = '2025-01-01'
    result = conn.call('get_min_price_by_date', [date_to_check])
    print(f"Минимальная стоимость: {result} с датой вылета: {date_to_check}")
    coast = 3000
    result = conn.call('get_cheap_flights', [coast])
    print(f"Список рейсов с минимальной стоимостью билетов {coast}:")
    result = result.data[0] if result.data else []
    for rec in result:
        print(rec)

except Exception as e:
    print(f"Ошибка: {e}")
