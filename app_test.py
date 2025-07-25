import tarantool

try:
    # Подключение к Tarantool
    conn = tarantool.Connection('localhost', 3301)

    # Тестовый запрос - получение информации о сервере
    result = conn.call('box.info')
    print("Подключение успешно!")
    print(f"Версия Tarantool: {result.data[0]['version']}")

    # Проверка пользовательской функции
    flights = conn.call('get_all_flights')
    print(f"Найдено рейсов: {len(flights.data[0])}")

except Exception as e:
    print(f"Ошибка подключения: {e}")
